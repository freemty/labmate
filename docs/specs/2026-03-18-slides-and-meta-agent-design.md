# Slides System Upgrade + Template-Meta Agent Design Spec

**Date:** 2026-03-18
**Status:** Draft
**Author:** sum_young + Claude Opus 4.6
**Depends on:** `2026-03-18-cc-native-research-template-design.md`

## Problem

1. **slides-maker agent 职责过窄** — 只能做实验分析 slides，无法做项目概览、架构介绍等通用演示。
2. **slides 视觉规范依赖全局 skill** — `frontend-slides` 和 `agent-slides` 在 `~/.claude/skills/`，模板无法自包含。
3. **slides-dispatch 调度逻辑分散** — 全局 `slides-dispatch` skill（在 `~/.claude/skills/`）的调度模式应该内化到模板的 analyze-experiment skill 和 slides-maker agent 中，消除对全局 skill 的依赖。
4. **模板自身没有 meta agent** — 6 个 agent 全部服务"使用模板的研究项目"，模板自身的介绍/展示/文档生成没有专门角色。

## Solution

### A) 升级 slides-maker agent — 双模式 + 内化视觉规范

将 `frontend-slides` 和 `agent-slides` 的核心内容复制进 repo，slides-maker 直接读取。支持两种模式：

- **analysis 模式**（现有）— 由 `/analyze-experiment` 派发，读实验数据生成分析 slides
- **presentation 模式**（新增）— 由用户或 template-presenter 派发，读项目文档生成概览/教学 slides

### B) 新增 template-presenter agent — 模板元任务

专门服务于模板自身的"元"需求：项目概览 slides、架构文档、tutorial demo 内容、onboarding 材料。

---

## 1. Slides Reference Files

### 位置

```
slides/
├── references/
│   ├── frontend-slides.md    # 视觉规范（从 ~/.claude/skills/frontend-slides/ 提取）
│   └── agent-slides.md       # 实验分析 slide 模板（从 ~/.claude/skills/agent-slides/ 提取）
├── .gitkeep
└── (generated slides)
```

### 提取内容

**`slides/references/frontend-slides.md`** — 从全局 `frontend-slides/SKILL.md` 提取：
- Core Philosophy（5 条原则）
- Viewport Fitting Requirements（Golden Rule + CSS 架构）
- Content Density Limits 表
- Required CSS Architecture（mandatory base styles）
- 字体规范（Inter + JetBrains Mono）
- clamp() 响应式尺寸规则
- 动画/过渡规范
- Style Presets（从 `STYLE_PRESETS.md` 合并）

**不提取：** steam-steel demo 资产、PPT 转换逻辑、style exploration workflow（这些是交互式设计流程，agent 不需要）。

**`slides/references/agent-slides.md`** — 从全局 `agent-slides/SKILL.md` 提取：
- Slide 结构模板（15 页标准结构）
- 内容来源规则表
- 可视化选型表
- 视觉风格规范（GitHub Dark CSS 变量）
- Template A/B/C 选择指南

### 维护

这些是**快照文件**。当全局 skill 更新时，用户手动同步（或 bootstrap.sh 提供 `--update-references` flag）。不会频繁变动 — 视觉规范相对稳定。

---

## 2. slides-maker Agent 升级

### 现有 → 新 agent prompt 对比

| 维度 | 现有 | 新版 |
|------|------|------|
| 模式 | 仅实验分析 | analysis + presentation |
| 视觉规范来源 | 无（自由发挥） | `slides/references/frontend-slides.md` |
| 结构模板来源 | 无 | `slides/references/agent-slides.md` |
| 调用方式 | 仅由 /analyze-experiment 派发 | /analyze-experiment（analysis）或直接用户请求（presentation） |
| 写入范围 | slides/ only | slides/ only（不变） |

### 新 agent prompt 结构

```yaml
---
model: sonnet
description: "Generate HTML presentations — experiment analysis or project overview slides"
tools:
  - Read
  - Write
  - Glob
  - Grep
---
```

**System prompt 关键段落：**

你是 slides 生成专家。你有两种工作模式：

**模式 1: Analysis（实验分析）**
当调用时包含 `mode: analysis` 和 `exp_id`：
1. 读取 `slides/references/agent-slides.md` 获取分析 slide 模板结构
2. 读取 `slides/references/frontend-slides.md` 获取视觉规范
3. 读取 `exp/{exp_id}/results/summary.md` 获取数据
4. 读取 `exp/{exp_id}/README.md` 获取上下文和 domain interpretation
5. 读取 `slides/` 现有文件匹配风格一致性
6. 生成 `slides/{exp_id}-analysis.html`

**模式 2: Presentation（通用演示）**
当调用时包含 `mode: presentation` 和 `topic`：
1. 读取 `slides/references/frontend-slides.md` 获取视觉规范
2. 读取调用者提供的数据源文件
3. 读取 `slides/` 现有文件匹配风格一致性
4. 生成 `slides/{topic}.html`

**通用规则：**
- 只写入 `slides/` 目录
- 单文件 HTML（inline CSS/JS，零依赖）
- 严格遵循 viewport fitting（每页 = 100vh，不可滚动）
- 使用 clamp() 实现响应式字号
- GitHub Dark 主题（CSS 变量来自 frontend-slides.md）
- 文件名: `slides/{identifier}.html`

### slides-guard 调整

当前 slides-guard 挂在 `PreToolUse(Bash)` 上检测 `frontend-slides` 字样。升级后：

**删除 slides-guard.sh**，原因：
- `frontend-slides` 不再是可调用 skill，而是 `slides/references/` 下的参考文件，context 污染风险消除
- slides-maker 是唯一写入 `slides/` 的 agent，已通过 agent 权限边界隔离

**analysis-first 工作流保护替代方案：**
原 slides-guard 的第二个目的（强制先分析再出 slides）通过以下方式保持：
- `/analyze-experiment` skill 内置了分析 → slides 的完整流程，用户自然走正确路径
- slides-maker agent 在 analysis 模式下要求 `exp/{exp_id}/results/summary.md` 存在才能工作，如果没跑过 analyze.py 会自然失败
- 这是 "remind, don't block" 哲学的延续 — 通过流程设计引导而非 hook 强制

---

## 3. analyze-experiment Skill 更新

合并 slides-dispatch 的调度逻辑。现有 step 6 从：

```
6. Spawn slides-maker subagent (Agent tool, model: sonnet, write slides/)
   Prompt: "Generate analysis slides for {current_exp}..."
```

改为：

```
6. Spawn slides-maker subagent (Agent tool, model: sonnet, write slides/)
   Prompt:
   > mode: analysis
   > exp_id: {current_exp}
   >
   > Read slides/references/agent-slides.md for structure template.
   > Read slides/references/frontend-slides.md for visual spec.
   > Read exp/{current_exp}/results/summary.md for data.
   > Read exp/{current_exp}/README.md for context + domain interpretation.
   > Check slides/ for existing style reference.
   >
   > Generate: slides/{current_exp}-analysis.html
   > Follow viewport fitting rules strictly. Single self-contained HTML file.
```

---

## 4. template-presenter Agent（新增）

### 定位

服务于模板自身的"元任务" — 模板不只是骨架，它本身也是一个需要展示和文档化的产品。

### Agent 定义

```yaml
---
model: sonnet
description: "Template meta-presenter — generate project overview slides, architecture docs, and onboarding materials"
tools:
  - Read
  - Grep
  - Glob
---
```

**注意：只读。** template-presenter 不直接写文件。它的输出通过两种方式落地：
1. **Slides** → 派发 slides-maker agent（presentation 模式）
2. **文档** → 返回内容给主 context，由用户决定写入位置

### System prompt

你是 cc-native-research-template 的元任务专家。你的职责是理解和展示模板本身的架构、工作流、和设计决策。

**你会被调用来做以下事情：**

1. **项目概览 slides** — 读取 `docs/specs/`、`CLAUDE.md`、`.claude/agents/`、`.claude/skills/`、`.claude/hooks/`，生成一个 presentation prompt 交给 slides-maker agent（presentation 模式）

2. **架构文档** — 读取全部 `.claude/` 基础设施，生成或更新架构文档

3. **Onboarding 材料** — 为新用户生成"5 分钟上手指南"，覆盖 bootstrap、第一个实验、常用命令

4. **Tutorial demo 脚本** — 为 live demo 生成步骤脚本（演示 /new-experiment → 跑实验 → /analyze-experiment 全流程）

**数据源：**
- `docs/specs/*.md` — 设计规范
- `CLAUDE.md` — route hub（agents、skills、workflow 概览）
- `.claude/agents/*.md` — agent 定义细节
- `.claude/skills/*/SKILL.md` — skill 逻辑细节
- `.claude/hooks/*.sh` — hook 实现
- `exp/summary.md` — 实验历史
- `.pipeline-state.json` — 当前状态

**输出约束：**
- 你是只读 agent — 不写文件
- Slides 内容以 structured prompt 形式输出，由调用者派发给 slides-maker
- 文档内容以 markdown 形式输出，由调用者决定写入位置

### 调用模式

**场景 1: 用户要项目概览 slides**
```
用户: "做一个项目概览 slides"
主 context:
  1. 派发 template-presenter agent（只读）
     → 读取项目文档，返回 slides 内容大纲 + 具体数据
  2. 派发 slides-maker agent（presentation 模式）
     → 接收大纲 + 数据，生成 slides/project-overview.html
```

**场景 2: 用户要 onboarding 文档**
```
用户: "生成新用户 onboarding 指南"
主 context:
  1. 派发 template-presenter agent（只读）
     → 读取项目文档，返回 onboarding markdown
  2. 主 context 写入 docs/onboarding.md
```

### 与 project-advisor 的边界

两个 agent 读取相似的文件，但职责明确不同：

| 维度 | project-advisor | template-presenter |
|------|----------------|-------------------|
| 服务对象 | 使用模板的研究项目 | 模板本身作为产品 |
| 核心数据 | `.claude/skills/project-skill/SKILL.md`（实验知识） | `docs/specs/`、`.claude/agents/`（基础设施设计） |
| 输出形式 | 文字回答（Q&A） | 结构化大纲 / markdown 文档 |
| 典型问题 | "exp01a 的结果怎么样？" | "帮我做一个模板架构介绍 slides" |
| CC 路由 | 用户问研究项目相关问题 | 用户要求生成展示/文档/onboarding 材料 |

project-advisor 的 description 应收窄为："Project knowledge — **experiment** history, **research** findings, codebase navigation"，强调研究内容而非基础设施。

### 编排 skill: `/present-template`

template-presenter → slides-maker 的两步 pipeline 需要一个编排 skill 来串联：

```
.claude/skills/present-template/SKILL.md
```

```markdown
---
description: "Generate template overview slides or documentation"
---

# Present Template

Generates presentations or documentation about the template itself.

## Instructions

1. Ask user what to generate:
   - "project-overview" → slides 介绍模板架构
   - "onboarding" → 5 分钟上手指南文档
   - "demo-script" → live demo 步骤脚本
   - 或自定义主题

2. **Spawn template-presenter** subagent (Agent tool, model: sonnet, read-only):
   > Read the project infrastructure and generate a detailed content outline for: {topic}
   > Include specific data, file paths, agent names, and workflow steps.
   > Return: structured outline with slide titles and bullet points (for slides)
   > or complete markdown (for docs).

3. **If slides requested:** spawn slides-maker subagent (Agent tool, model: sonnet, write slides/):
   > mode: presentation
   > topic: {topic}
   > Content outline: {template-presenter output}
   > Read slides/references/frontend-slides.md for visual spec.
   > Generate: slides/{topic}.html

4. **If docs requested:** write markdown to user-specified path (or default `docs/`).
```

### 为什么 agent + skill 而不是单独一个 skill？

- **template-presenter agent 是只读扫描器** — 扫描全部 .claude/ 文件可能消耗大量 context，放在 subagent 里保护主 context
- **present-template skill 是编排器** — 串联两个 subagent，决定输出类型
- **可复用** — template-presenter 可以被其他流程调用（不只是 slides）

---

## 5. Agent 生态更新总览

### 变更前 → 变更后

| Agent | 变更 |
|-------|------|
| project-advisor | 不变 |
| cc-advisor | 不变 |
| domain-expert | 不变 |
| **slides-maker** | **升级**: 双模式（analysis + presentation），内化视觉规范引用 |
| exp-manager | 不变 |
| viz-frontend | 不变 |
| **template-presenter** | **新增**: 模板元任务（概览 slides、架构文档、onboarding） |

### 新 CLAUDE.md Agents 表

注：模型值以各 agent `.md` 文件的 frontmatter 为准，此表同步更新。

| Agent | Model | Purpose |
|-------|-------|---------|
| project-advisor | opus | Experiment history, research findings, codebase navigation |
| cc-advisor | sonnet | Claude Code workflow best practices and tooling guidance |
| domain-expert | opus | Domain research — reads papers, interprets experiment results |
| slides-maker | sonnet | Generate HTML slides — experiment analysis or project presentations |
| exp-manager | sonnet | Experiment monitor — diagnose, retry, detect completion |
| viz-frontend | sonnet | Build analysis dashboards (writes to viewer/) |
| template-presenter | sonnet | Template meta — project overview, architecture docs, onboarding |

---

## 6. Hook 系统变更

| Hook | 变更 |
|------|------|
| slides-guard.sh | **删除** — frontend-slides 不再是可调用 skill，无需拦截 |
| settings.local.json | 移除 slides-guard 相关的 PreToolUse 条目 |
| 其他 5 个 hook | 不变 |

---

## 7. 文件变更清单

### 新增
```
slides/references/frontend-slides.md        # 视觉规范提取
slides/references/agent-slides.md           # 分析模板提取
.claude/agents/template-presenter.md        # 新 agent
.claude/skills/present-template/SKILL.md    # 编排 skill（template-presenter → slides-maker）
```

### 修改
```
.claude/agents/slides-maker.md              # 双模式 + 引用 references
.claude/agents/project-advisor.md           # description 收窄（强调实验/研究，非基础设施）
.claude/skills/analyze-experiment/SKILL.md  # 更新 step 6 的 subagent prompt
.claude/settings.local.json                 # 移除 slides-guard hook 条目
CLAUDE.md                                   # Agents 表加 template-presenter，Skills 表加 present-template
.claude/CHANGELOG-agents.md                 # 记录变更（注：此文件已从 .claude/agents/ 移至 .claude/）
```

### 删除
```
.claude/hooks/slides-guard.sh               # 不再需要
```
