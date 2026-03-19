# LabMate

Claude Code 的研究工作台。让你的 agent 扎根在实验上下文里，别在 vibe coding 里迷路。

[English](README.md)

## 问题

你用 Claude 开始一个研究项目。三小时后你在 debug 一个 CUDA kernel，完全忘了自己在验证什么假设。

与此同时，你的 agent 不知道你上周试过什么，看不了你的参考论文，每次开会话都像第一天上班。

LabMate 两边都管。你的 agent 拿到持久化的实验上下文、领域论文知识、7 个各司其职的专用 agent。你拿到一套研究生命周期，假设、baseline、发现始终在视野里，不会写着写着代码就忘了自己在做研究。

## 安装

```bash
claude plugin install freemty/labmate
```

## 快速开始

1. 在你的项目里跑 `/init-project`
2. 回答 4 个问题（名称、描述、领域、计算环境）
3. 开始研究。你的 agent 已经知道工作流了。

完整教程见 [Tutorial: your first experiment](docs/tutorial.md)（英文）。

## 里面有什么

7 个 agent，各管一块：

- `@domain-expert` 读论文、解读结果、把发现和文献连起来
- `@project-advisor` 知道你的实验历史，引导下一步
- `@exp-manager` 监控跑着的实验，诊断失败，检测完成
- `@slides-maker` 把分析变成可演示的 HTML 幻灯片
- 另外还有 `@cc-advisor`、`@viz-frontend`、`@template-presenter`

7 个 skill，以斜杠命令触发：

- `/new-experiment` 搭建实验骨架（config、README、运行脚本、分析脚本）
- `/analyze-experiment` 领域解读 + 跨实验对比 + 幻灯片
- `/update-project-skill` 把发现压缩进持久化的项目记忆
- 另外还有 `/init-project`、`/present-template`、`/weekly-progress`、`/commit-changelog`

6 个 hook，自动运行：

- SessionStart 检测项目状态并注入上下文
- PreCompact 在上下文压缩前提醒保存进度
- Stop 在会话结束时检查工作流状态

## 工作流

```
/init-project → /new-experiment → 跑实验 → /analyze-experiment
  → 提交发现 → /update-project-skill → 重复
```

Pipeline 状态记在 `.pipeline-state.json` 里。你的 agent 从上次断点继续。

## 定制

在项目本地创建同名文件就能 override：

```bash
# 例：给 domain-expert 定制你的领域
mkdir -p .claude/agents
# 本地版本自动覆盖 plugin 版本
```

Agent、skill、hook 都可以 override。详见 [design spec](docs/specs/2026-03-18-inject-template-design.md)。

## 路线图

下一步：Auto Research Agent 模式。让你的 agent 自主跑完从假设到分析的完整循环。

## 致谢

- [superpowers](https://github.com/obra/superpowers) — skills 框架、subagent-driven development、SessionStart hook 模式
- [frontend-slides](https://github.com/zarazhangrui/frontend-slides) — slides-maker agent 的幻灯片生成能力
- [Agent-Reach](https://github.com/Panniantong/Agent-Reach) — domain-expert agent 的多平台内容抓取能力

## License

MIT
