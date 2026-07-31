# 和 AI Agent 干活的正确姿势

这是我用 Claude Code 跑了几个月研究实验后攒下来的经验。不是理论，全是踩坑。

适用于 Claude Code、Codex CLI、Gemini CLI 这类 agentic coding 工具。

---

## Agent 的根本问题

用久了你会发现，agent 干活很猛，但有几个怎么都绕不过去的毛病：

**新开 session 一切清零。** 你花半小时在对话里纠正它对 repo 的理解，关掉窗口全忘了。它不会"学习"，没有跨 session 的记忆。

**塞太多 context 会变笨。** 让它同时看仿真结果、写代码、做 review，四件事挤在一个 context 里，每件都做得稀烂。

**它只是个 workflow 执行者。** 不是 PM，不会"不达目的不罢休"。卡住了就卡住了，不会自己想办法绕过去。

下面所有技巧都是在跟这几个毛病搏斗。

---

## 对话不落盘 = 白聊

这是我觉得最重要的一条。

Agent 没有记忆，所以你得帮它建记忆。做法很简单：对话中产出的任何理解、决策、约定，写进文档，然后在项目 instruction file 里加索引：Claude Code 用 `CLAUDE.md`，Codex / Antigravity 用 `AGENTS.md`。没被索引的文档等于不存在，未来 session 很可能不会读到。

但 `CLAUDE.md` / `AGENTS.md` 本身不适合放细节。它会被加载到每个 session 开头，写太长就把 context 吃掉了。正确的分层：

```
CLAUDE.md / AGENTS.md                         ← 项目 overview + 文档索引（短，几十行）
.claude/skills 或 .agents/skills/project-skill ← 架构、实验结论、工程教训
specific docs                                 ← 某个 topic 的深度文档
```

决策层和操作层分开。`CLAUDE.md` / `AGENTS.md` 告诉 agent "去哪里找信息"，project-skill 告诉它"信息是什么"。如果你同时用 Claude Code 和 Codex，`.claude/skills/project-skill/` 与 `.agents/skills/project-skill/` 必须镜像，并用 `scripts/check_agent_parity.sh` 防漂移。

还有一个问题：context 压缩会丢掉未落盘的细节。LabMate 只在压缩前给一次简短归档提示；真正的持久化由 `update-docs` 完成，机械写入交给脚本。不要靠一串交叉推荐 hook 反复占用 context。

---

## Context 多了会变笨，拆开干

我之前让 agent 在一个 session 里又开仿真、又看结果、又写代码、又 review。四件事共享一个 context，结果每件都做得很差。

解法是把 context 拆开。在 Labmate 里我们用的架构：

```
你触发一个 Skill（发现入口与判断契约）
    ├── 机械操作 → 调用确定性脚本
    ├── 深度推理 → 可用时委派给隔离 context 的角色
    └── 主线程汇总结果，决定是否写回文档
```

**Skill 是 workflow，subagent 是有独立 context 的独立能力。** 这个区分很关键。

对用户来说，只需调用 skill，不必知道宿主有没有 named agent。LabMate 的角色路由是：Claude Code 有对应 named agent 时直接用；否则使用普通 subagent 加载同一角色说明；再不可用时由主线程按同一判断契约完成。`read-paper` 可以委派分析，但追问、保存和归档始终回到主线程。

---

## Agent 不会自驱，你得当监工

Agent 按 workflow 执行完就停了。它不会像人一样遇到问题绕路走，更不会主动去检查之前做的对不对。

几个应对办法：

**用宿主原生调度重复检查。** Codex App 建议为 LabMate `monitor` 创建 Scheduled Task；其他宿主手动重复调用。只有宿主明确提供 loop 能力时，才把 `monitor` 放进该机制。`monitor` 本身保持一次调用、一次快照，不伪装成常驻进程。

**commit-changelog 建时间线。** Agent 最大的问题之一是不知道自己之前犯过什么错。如果你用 changelog 记录每次变更和原因，后面 debug 的时候至少有迹可循。

**找第二意见。** 让另一个隔离 context 做只读 review。关键不是命令名或模型品牌，而是它没有共享原任务的推理惯性。

**以天为单位 review 代码。** Agent 就是会写冗余代码，这个改不了。接受它，然后定期清理。

---

## 环境：让 repo 自己管自己

Agent 找不到 conda 环境是个经典问题。conda 的 env 散落在系统各处，agent 根本不知道该 activate 哪个。

根本解法：**用 uv 替代 conda。** uv 的环境就在项目 `.venv/` 下，`uv sync` 一行搞定。Repo 的环境应该是 self-contained 的，别让 agent 去 repo 之外找东西。

```bash
# conda: agent 找不到
conda activate my-env  # 哪个 env？在哪？

# uv: 就在项目里
uv sync  # .venv/ 下，不用找
```

第一次跑的时候告诉 agent 环境怎么配，然后让它自己写进文档。以后的 session 读文档就行。

---

## 理解复杂 repo

在对话中通过多轮纠正可以让 agent 理解一个复杂 repo。问题是这个理解没法 reuse。

还是那句话：一切对话落盘。但对于复杂 repo，光落盘不够，还需要系统化的 workflow：

1. 先写简短 spec，明确目标、边界和验收条件。
2. 把可机械验证的部分写成脚本或测试，把判断标准写成 rubric。
3. 只有任务真正独立时才拆隔离 context，并由主线程负责汇总。
4. 完成后用未参与实现的 context 做只读 review。

关于 Claude Code 本身怎么配、怎么用这类问题，其实可以直接问它自己。但要给它足够的参考文档，不然它也是瞎猜。

---

## 远程服务器

Claude Code App 有 SSH mode，不需要在 server 上装 CC。对于不太细节的任务，直接让 agent 自己 SSH 上去看、跑命令、拿结果回来就行。

终端推荐 [Ghostty](https://ghostty.org/) + [cmux](https://cmux.com/zh-CN)（终端编排，可以分屏跑多个 CC 实例）。

---

## 视觉任务：还是需要人

这是现阶段的硬限制。

看图有局限。比如 LiDAR projection 这种需要抓视觉细节的任务，agent 会忽略关键信息直接略过。更别说理解 streaming video 里的细节和常识推理了，做不到 close-loop。

结论：视觉密集的任务，人来判断，agent 来执行。你告诉它看什么、怎么判断，它负责跑。

---

## 怎么想这件事

画个图可能更清楚：

```
你（研究者）
  决策、判断、视觉、创造性的部分
        │
        │ 触发 skill
        ▼
Skill（workflow）
  编排步骤，决定哪步自己做、哪步丢给 subagent
        │
        │ 委派
        ▼
角色执行（可选隔离 context）
  named agent / 普通 subagent / 主线程 fallback
  共享同一角色判断与输出契约
        │
        │ 写回
        ▼
持久化文档
  CLAUDE.md / AGENTS.md → project-skill → 各种 specific docs
  跨 session 活着，对抗遗忘
```

记住几件事就行：

1. 对话中得出的结论，写进文档并索引。不写等于没聊。
2. 一个 context 只干一件事。多件事拆 subagent。
3. Agent 不会主动追进度。用宿主原生调度、一次性 `monitor` 快照和定期 review 盯着它。
