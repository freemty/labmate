# LabMate

![version](https://img.shields.io/badge/version-0.11.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
<!-- TODO: 30s demo GIF — record with VHS or asciinema -->

你的 AI 实验室伙伴——从读论文到跑实验到写论文，贯穿整个研究生命周期。

[English](README.md)

## 问题

你用 AI coding agent 开始一个研究项目。三小时后你在 debug 一个 CUDA kernel，完全忘了自己在验证什么假设。

你的 agent 也好不到哪去——不知道你上周试过什么，看不了你的参考论文，每次开会话都像第一天上班。

LabMate 管两头。给 agent 装上实验记忆和论文知识。给你一套能看见假设和 baseline 的研究流程——写代码写到一半，抬头还能想起来自己在做什么研究。

## 安装

### Claude Code

```bash
# 从 Anthropic 插件市场安装
/plugin marketplace add freemty/labmate-marketplace
/plugin install labmate@labmate-marketplace
```

### OpenAI Codex

在本地 `yuanbo-skills` marketplace checkout 中：

```bash
codex plugin marketplace add /path/to/yuanbo-skills
codex plugin add labmate@yuanbo-skills
```

打开新任务后，用 `/hooks` 检查并信任 LabMate hook。然后初始化项目：

| 宿主 | 调用方式 |
|------|----------|
| Claude Code | `/labmate:init-project` |
| Codex | 输入 `$labmate:init-project`，或从 `/skills` 选择 |
| 其他 Agent Skills 宿主 | 用自然语言要求使用 LabMate 的 `init-project` skill |

### 教程

第一次用 agentic coding 做研究？从这里开始：**[CC Research Playbook](https://freemty.github.io/cc-research-playbook.html)** — 讲解 context engineering、skills、hooks、sub-agent，以及 LabMate 如何把这些串起来。LabMate 会把项目记忆分流到 Claude Code 的 `CLAUDE.md` / `.claude/`，以及 Codex / Antigravity 的 `AGENTS.md` / `.agents/`。

Codex 用户在安装或更新后还需要通过 `/hooks` 检查并信任 LabMate
lifecycle hooks。Skill 能正常显示并不代表尚未信任的 plugin hooks 已经运行。

### 推荐搭配

LabMate 独立可用，但装上这些效果更好。以下是 Claude Code 命令：

```bash
# 开发工作流（TDD、计划模式、代码审查、头脑风暴）
/plugin install superpowers

# 更好的幻灯片质量（slides 生成的视觉规范）
/plugin install frontend-slides

# 抓取 Twitter/X、小红书、B 站内容，辅助论文发现
/plugin install agent-reach
```

强烈推荐装 superpowers——它提供的结构化开发工作流能防止研究项目跑偏。

## 能做什么？

### 读论文

丢一个链接或 PDF，LabMate 帮你拆解方法论、标出假设、连接到你的研究。

Claude Code：`/labmate:read-paper https://arxiv.org/abs/2401.04088`

Codex：`$labmate:read-paper https://arxiv.org/abs/2401.04088`

精读完可以继续追问。说"存档"就自动保存到你的文献库。

想看更全的图景？综述一整个方向：

Claude Code：`/labmate:survey-literature attention sink mechanisms in Diffusion Transformers`

Codex：`$labmate:survey-literature attention sink mechanisms in Diffusion Transformers`

### 跑实验

描述你想测什么。LabMate 搭建实验目录、config、运行脚本、分析脚本。

Claude Code：`/labmate:new-experiment`

Codex：`$labmate:new-experiment`

跑起来之后，随时查状态：

Claude Code：`/labmate:monitor`

Codex：`$labmate:monitor`

LabMate 会诊断失败并提出最小安全恢复动作；重试或中断进程仍需明确授权。

### 分析结果

一个命令完成领域解读和文献对比：

Claude Code：`/labmate:analyze-experiment`

Codex：`$labmate:analyze-experiment`

需要幻灯片时单独使用 `research-slides`；需要结果界面时：

Claude Code：`/labmate:visualize`

Codex：`$labmate:visualize`

### 保持有序

LabMate 把实验历史、论文笔记和关键发现保存在项目文件中。SessionStart
只注入当前阶段和项目知识入口，深层上下文由相关 skill 按需加载。

提交代码自动更新 CHANGELOG：

Claude Code：`/labmate:commit-changelog`

Codex：`$labmate:commit-changelog`

## 安静的上下文

LabMate 不会在每次工具调用后注入流程目录或交叉推荐。Skill description
负责发现，typed scripts 负责机械状态修改，项目文件负责持久知识。

四个默认 handler 分别负责：启动时显示已有项目状态、成功代码提交后静默记录
待维护项、压缩前按 session 汇总一次，以及 Git 操作辅助提示。普通目录不强制
初始化，失败命令和纯文档提交不产生无关维护推荐。

## 完整研究生命周期

```
init-project → new-experiment → monitor → analyze-experiment
  → visualize → commit-changelog → 重复
  随时读论文：read-paper, survey-literature
```

Pipeline 状态记在 `.pipeline-state.json`。下次开 session，agent 从断点继续。

## 横向对比

| 能力 | labmate | [K-Dense](https://github.com/K-Dense-AI/claude-scientific-skills) | [Orchestra](https://github.com/Orchestra-Research/AI-Research-SKILLs) | [ARIS](https://github.com/conglu1997/ARIS) |
|------|---------|---------|-----------|------|
| 论文深度阅读 | Yes | No | No | No |
| 文献综述 | Yes | No | No | No |
| 实验设计 | Yes | No | Partial | No |
| 研究记忆 | Yes | No | No | No |
| 实验监控 | Yes | No | No | Yes |
| 结果 Dashboard | Yes | No | No | No |
| 跨学科支持 | Yes | 生物/化学 | 仅 ML/AI | 仅 ML |

## 定制

Claude Code 可以在项目本地覆盖 named agent：

```bash
mkdir -p .claude/agents
# 你的 .claude/agents/domain-expert.md 自动覆盖 plugin 版本
```

Codex 不会加载 plugin 中的 Markdown named agents。依赖专业角色的 LabMate
skills 会自动回退到普通 subagent 或主线程。`.codex/agents/*.toml` 是可选的，
LabMate 不会自动创建。

如果同时使用 Claude Code 和 Codex / Antigravity，保持
`.claude/skills/project-skill/` 与 `.agents/skills/project-skill/` 镜像一致。

## 技术架构

LabMate 包含 12 个跨平台 skills，以及分布在 4 类生命周期事件中的 4 个
focused hook handlers。Claude Code 额外获得 5 个 named agents；Codex
通过 skill fallback 使用同一套精简角色说明。

## 致谢

- [superpowers](https://github.com/obra/superpowers) — skills 框架和开发工作流
- [frontend-slides](https://github.com/zarazhangrui/frontend-slides) — 幻灯片生成引擎
- [Agent-Reach](https://github.com/Panniantong/Agent-Reach) — 多平台内容抓取能力

## 引用

```bibtex
@software{labmate2026,
  title   = {LabMate: Research Harness for AI Coding Agents},
  author  = {freemty},
  year    = {2026},
  version = {0.11.0},
  url     = {https://github.com/freemty/labmate}
}
```

## License

MIT
