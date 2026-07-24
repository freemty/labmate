---
name: init-project
description: >
  Use when setting up a new project (general or research) or when
  .pipeline-state.json is missing. Triggers on "init project", "初始化项目",
  "set up labmate", "first time setup", "initialize".
disable-model-invocation: true
---

# Init Project

Initialize a project skeleton in the user's existing project. Supports two types: `general` (lightweight — knowhow, project-skill, changelog) and `research` (full — adds experiments, scripts, papers, slides). **Idempotent**: safe to run multiple times — existing files/directories are skipped, never overwritten or deleted.

**Language**: Default to English for all output. If user responds in Chinese, switch to Chinese for the rest of the session.

---

## 执行流程

### Step 1: 检测现有结构

1. 运行 `git status --porcelain` 检查 git 仓库状态：
   - 若输出非空（有未提交更改），**警告用户**并询问是否继续：
     > "检测到 git 工作区有未提交更改。继续将在此基础上写入文件。确认继续？(Y/n)"
   - 若用户回答 n，立即停止。

2. 检测 agent platform target，记录结果（用于后续 skip 判断）：
   - Codex / Antigravity workspace target: `AGENTS.md` + `.agents/skills/project-skill/SKILL.md`
   - Claude Code target: `CLAUDE.md` + `.claude/skills/project-skill/SKILL.md`
   - 若当前运行环境是 Codex，优先 Codex target；若是 Claude Code，优先 Claude target。
   - 若项目中两套 instruction file 已同时存在，则后续 Step 4 同步更新两者缺失 section。
   - 若项目中两套 instruction file 已同时存在，则 project-skill 也必须保持 `.claude/` 与 `.agents/` 镜像一致。

3. 检查以下路径是否存在，记录结果（用于后续 skip 判断）：
   - `CLAUDE.md`
   - `AGENTS.md`
   - `.claude/skills/project-skill/SKILL.md`
   - `.agents/skills/project-skill/SKILL.md`
   - `scripts/check_agent_parity.sh`
   - `exp/`
   - `docs/`
   - `.pipeline-state.json`
   - `.gitignore`

4. 输出检测摘要（中文），例如：
   > 检测结果：target=codex | AGENTS.md 不存在 | .agents/skills/project-skill 不存在 | exp/ 已存在 | docs/ 不存在 | .pipeline-state.json 不存在 | .gitignore 已存在

---

### Step 2: 收集项目信息

**全部自动推断，用户只需确认或修改。**

1. 运行 `basename "$(pwd)"` 获取 `{project-name}`
2. 将 `{compute_env}` 默认设为 `local`
3. 浏览项目现有文件（README、代码、目录名等），推断出：
   - `{description}` — 一句话描述（从 README 或目录结构推断）
   - `{domain}` — 研究领域（从代码、依赖、README 关键词推断）
4. 一次性展示给用户确认：

   > 自动检测到以下信息：
   > - 项目名称：`fars-autotrain`
   > - 描述：`Auto post-training benchmark agent`
   > - 领域：`NLP / Post-training`
   > - 计算环境：`local`
   >
   > 需要修改哪项？（直接回车 = 全部确认）

5. 用户可以直接回车确认，或输入要改的内容（如 "描述改为 xxx"）

6. 自动推断项目类型：
   - 若项目已有 `exp/` 目录，或 README 中包含 experiment/benchmark/training 关键词 → 默认 `research`
   - 否则默认 `general`
   - 在确认信息中增加一行：
     > - 项目类型：`general`（可选：research / general）

---

### Step 3: 创建目录结构

**原则：只创建不存在的文件/目录。已存在则跳过并记录。**

**插件路径**：通过 `SKILL.md` 所在目录推导插件根目录。
- 此 SKILL.md 位于 `<plugin_root>/skills/init-project/SKILL.md`
- 因此 `<plugin_root>` = SKILL.md 向上两级目录
- 所有 references 文件读取自 `<plugin_root>/references/`

按下列清单逐项处理：

---

#### 通用部分（general + research 均执行）

#### 3.1 Knowhow 目录

以下目录若不存在则创建并写入 `.gitkeep`：
- `docs/knowhow/infrastructure/`
- `docs/knowhow/toolchain/`
- `docs/knowhow/debug-solutions/`
- `docs/knowhow/runbooks/`

#### 3.2 文档目录（通用）

- `docs/specs/.gitkeep` — 若 `docs/specs/` 不存在则创建

#### 3.3 pipeline 状态文件

若 `.pipeline-state.json` 不存在，写入：

```json
{
  "type": "{type}",
  "project_name": "{project-name}",
  "description": "{description}",
  "domain": "{domain}",
  "compute_env": "{compute_env}",
  "current_exp": null,
  "stage": "dev",
  "skill_updated_at": null
}
```

将占位符替换为 Step 2 收集的值。`{type}` 为 `general` 或 `research`。

#### 3.4 project-skill 空模板

根据 Step 1 检测到的 platform target 确定 project skill 路径：

| Target | Project skill path | Changelog path |
|--------|--------------------|----------------|
| Codex / Antigravity workspace | `.agents/skills/project-skill/SKILL.md` | `.agents/skills/project-skill/CHANGELOG.md` |
| Claude Code | `.claude/skills/project-skill/SKILL.md` | `.claude/skills/project-skill/CHANGELOG.md` |

若项目中两套 instruction file 已同时存在，则两套 project-skill 路径都检查并补齐；若只存在当前 runtime 目标，则只创建当前目标。

镜像规则：
- 若一侧 project-skill 已存在、另一侧缺失，优先复制已存在侧的整个 `project-skill/` 目录到缺失侧，保留已积累知识。
- 只有当目标侧和可复制的 counterpart 都不存在时，才创建下面的空模板。

若目标路径的 `SKILL.md` 不存在，创建：

```markdown
---
name: project-skill
description: "Use when advising on project architecture, experiment history, codebase navigation, or research findings."
---

# {project-name} — Project Knowledge

> {description}

## Project overview
(use LabMate's `update-project-skill` skill to populate)

## Experiment history
(none yet)

## Key findings
(none yet)
```

将 `{project-name}` 和 `{description}` 替换为 Step 2 的值。确保目标 `project-skill/` 目录存在。

若目标 `project-skill/CHANGELOG.md` 不存在，创建：

```markdown
# project-skill CHANGELOG

## {date} — v0

Initial skeleton created by LabMate.
```

若两套 project-skill 都存在或本步骤创建了两套，确保两边 `SKILL.md` 和 `CHANGELOG.md` 内容一致。

#### 3.5 CHANGELOG.md

若 `CHANGELOG.md` 不存在，写入：

```markdown
# Changelog

## Unreleased

- Project initialized with LabMate
```

---

#### Research 专属部分（仅当 type=research 时执行，type=general 则跳过以下全部）

#### 3.6 实验目录

- `exp/.gitkeep` — 若 `exp/` 不存在则创建目录并写入空文件
- `exp/summary.md` — 若不存在则写入以下内容：

```markdown
# Experiment Summary

Cross-experiment flight recorder. One row per experiment.

| Exp ID | Motivation | Status | Key Finding |
|--------|-----------|--------|-------------|
```

#### 3.7 文档目录（research）

以下目录若不存在则创建并写入 `.gitkeep`：
- `docs/papers/`
- `docs/weekly/`
- `docs/archive/`

- `docs/papers/landscape.md` — 若不存在则写入以下占位内容：

```markdown
# Domain Literature Landscape

> Research domain: {domain}

## Key Papers

(待填写 — 使用 LabMate 的 domain expert role 协助整理文献)

## Research Gaps

(待填写)
```

将 `{domain}` 替换为 Step 2 收集的研究领域。

#### 3.8 脚本文件

逐一处理（若目标文件已存在则跳过）：

| 目标路径 | 来源（相对插件根） |
|---------|----------------|
| `scripts/launch_exp.py` | `references/launch_exp.py` |
| `scripts/monitor_exp.sh` | `references/monitor_exp.sh` |
| `scripts/download_results.sh` | `references/download_results.sh` |
| `viewer/app.py` | `references/viewer-app.py` |
| `viewer/static/index.html` | `references/viewer-static/index.html` |

操作步骤：
1. 读取插件 references 中的源文件内容
2. 若目标文件不存在，写入该文件
3. 确保父目录存在（必要时运行 `mkdir -p` 创建）

#### 3.9 Slides

- `slides/.gitkeep` — 若 `slides/` 不存在则创建

---

### Step 4: 生成 agent instruction file

**从插件读取模板：**

1. 根据项目类型选择模板：
   - `general` → 读取 `<plugin_root>/references/instruction-template-general.md`
   - `research` → 读取 `<plugin_root>/references/instruction-template-research.md`
2. 替换以下占位符：
   - `{project-name}` → Step 2 的项目名称
   - `{description}` → Step 2 的一句话描述
   - `{date}` → 今天日期，格式 `YYYY-MM-DD`
   - `{project-skill-path}` → 当前 target 的 project skill 路径，例如 `.agents/skills/project-skill/SKILL.md`

**写入规则：**

- 目标 instruction file：
  - Codex / Antigravity workspace → `AGENTS.md`
  - Claude Code → `CLAUDE.md`
  - 若两者已同时存在，则对两者执行同样的缺失 section 追加逻辑。

- **若目标文件不存在**：直接写入替换后的完整模板。

- **若目标文件已存在**：
  1. 读取现有文件内容
  2. 解析现有的 `## ` 二级标题列表（h2 sections）
  3. 解析模板的 `## ` 二级标题列表
  4. 找出模板中**存在但现有文件中缺失**的 section
  5. 仅将缺失的 section（含其内容，直到下一个 `## ` 或文件末尾）**追加**到现有文件末尾
  6. **绝对不删除、不修改**现有 section
  7. 若所有 section 均已存在，输出"{target file} 已包含所有模板 section，跳过"

---

### Step 4.5: Agent parity guard

若项目中同时存在 `CLAUDE.md` 和 `AGENTS.md`，或同时存在 `.claude/skills/project-skill/` 与 `.agents/skills/project-skill/`：

1. 确保 `scripts/` 目录存在。
2. 若 `scripts/check_agent_parity.sh` 不存在，读取 `<plugin_root>/references/check_agent_parity.sh` 并写入该路径。
3. 运行 `chmod +x scripts/check_agent_parity.sh`。
4. 运行 `bash scripts/check_agent_parity.sh`。若失败，报告具体失败原因，不要忽略。

若只初始化单一平台目标，则跳过运行，但在摘要中提示：以后同时使用 Claude Code 和 Codex 时，应创建另一侧入口和 project-skill 镜像，并启用 parity guard。

---

### Step 5: 追加 .gitignore 规则

1. 若 `.gitignore` 不存在，先创建空文件（内容为空字符串）

2. 读取现有 `.gitignore` 内容，将所有行存入集合 `existing_lines`

3. **根据项目类型确定待追加规则：**

   **若类型为 `general`：**
   仅追加以下规则（不读取 references/gitignore-rules.md）：

   ```
   # labmate rules
   .pipeline-state.json
   .labmate-hook-state.json
   ```

   **若类型为 `research`：**
   读取 `<plugin_root>/references/gitignore-rules.md`，按以下逻辑处理全部行。

4. 逐行处理待追加规则的每一行：
   - **空行**：追加空行（用于格式间隔）
   - **注释行**（以 `#` 开头）：**始终追加**（作为 section 标记）
   - **规则行**（其他）：
     - strip 首尾空白
     - 若该行**不在** `existing_lines` 中，则追加
     - 若已存在，跳过

5. 将所有待追加内容一次性写入 `.gitignore` 末尾

---

### Step 6: 输出摘要

以中文输出结构化摘要，格式如下：

```
=== LabMate init-project 完成 ===

项目类型：{type}

已创建：
  （根据实际操作列出已创建的文件/目录）

已跳过（已存在）：
  （根据实际操作列出已跳过的文件/目录）

已更新：
  （根据实际操作列出已更新的文件）

=== 建议后续步骤 ===

1. 检查变更：
   git diff

2. 确认无误后提交：
   git add -A && git commit -m "chore: init project skeleton"

3. 若生成了 parity guard，验证：
   bash scripts/check_agent_parity.sh

4. （若 type=research）开始第一个实验：
   使用 LabMate 的 new-experiment skill
   （若 type=general）刷新项目知识：
   使用 LabMate 的 update-project-skill skill
```

根据实际操作结果填写"已创建"、"已跳过"、"已更新"列表。

---

## 错误处理

- 读取插件 references 文件失败：输出错误信息，说明 `<plugin_root>/references/` 中缺少对应文件，跳过该文件继续执行其余步骤
- 写入文件失败（权限等）：输出错误，跳过该文件，最终摘要中标记为 `! 写入失败`
- 任何步骤失败不中断整体流程，继续执行后续步骤，最终汇总所有错误

---

## 幂等性保证

- 已存在的文件：**只读，不覆盖**
- `.gitignore` 规则：**逐行去重，不重复追加**
- agent instruction file section：**仅追加缺失 section**
- 目录：已存在则跳过 `mkdir`
- `.pipeline-state.json`：已存在则完整跳过（不更新字段）
