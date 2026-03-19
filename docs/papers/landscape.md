# Literature Landscape

> Living literature map — maintained by @domain-expert agent.
> Each paper has detailed notes in `docs/papers/{short-name}.md`.

## Agent Harness & Workflow Engineering

| Source | Date | Key Contribution | Relevance to Template | Notes |
|--------|------|------------------|-----------------------|-------|
| [Designing Tools for AI Agents (Harness Theory)](https://x.com/i/article/2027446899310313472) — @trq212 (Anthropic) | 2026-02-27 | Seeing like an agent、Tool minimalism（从1个工具开始按需扩展）、Progressive disclosure = Layer 3（SKILL.md ~100行 + 文件按需发现）、Harness = "nice boss" 环境设计 | Agent 工具设计哲学；progressive disclosure 模式直接指导 references/ 嵌套结构 | [notes](agent-tool-design-trq212.md) · [tweet](https://x.com/trq212/status/2027463795355095314) (10.6k likes, 27.5k bookmarks) |
| [Lessons from Building Claude Code: How We Use Skills](https://x.com/trq212/article/2033772621536591872) — @trq212 (Anthropic) | 2026-03-17 | Skills 9 大分类 + 文件夹化设计 + Gotchas 最高信号密度；社区回复：last-used date 双周审计 trick | Skills 架构直接参考；Skills 健康审计机制 | [notes](skills-design-trq212.md) · [tweet](https://x.com/trq212/status/2033949937936085378) (13.9k likes, 38.9k bookmarks) |
| [Prompt Caching First: Designing Agents Around the Cache](https://x.com/i/article/2024543492064882688) — @trq212 (Anthropic) | 2026-02-19 | Cache-First 架构原则：工具集固定（动态工具 = cache miss）、CLAUDE.md 写入 msg[0] 每轮（session 中途修改 = 全失效）、System Reminders in user messages、defer_loading tool stubs、Compaction 代价（全价计费）、cache 对用户透明 | Agent 架构的核心约束；直接影响 CLAUDE.md 稳定性设计、tool schema 固化策略 | [notes](prompt-caching-first-trq212.md) · [tweet](https://x.com/trq212/status/2024574133011673516) (5.3k likes, 13.8k bookmarks, 2.1M views) |
| [10 Tips for Using Claude Code](https://x.com/bcherny/status/2017742741636321619) — @bcherny (Claude Code 创始人) | 2026-01 | 并行 worktrees、Plan Mode、CLAUDE.md 迭代、Subagents | 工作流最佳实践 | [notes](cc-tips-bcherny.md) |
| [你不知道的 Claude Code](https://x.com/HiTw93/article/2032079318256664586) — @HiTw93 | 2026-03-12 | 六层架构模型、上下文预算量化（MCP 隐形消耗 12%+）、HANDOFF.md 跨 session 交接模式、CLAUDE.md 精简原则 | 上下文治理 + session 交接 | [notes](cc-architecture-tw93.md) · [tweet](https://x.com/HiTw93/status/2032091246588518683) (7.4k likes, 15.4k bookmarks, 2.4M views) |
| [Harness Engineering: Leveraging Codex in an Agent-First World](https://openai.com/index/harness-engineering/) — OpenAI (Ryan Lopopolo) | 2026-02-11 | 0行手写代码产出100万行；3人团队5个月1500 PR（3.5 PR/人/天）；AGENTS.md = ~100行目录而非百科；repo 即 agent 知识边界（Slack/Docs 不可见 = 不存在）；Progressive Disclosure 分层 docs/；Linter 错误消息即 remediation 指令；每 worktree 独立观测栈（LogQL/PromQL/TraceQL）；Golden Principles + 后台垃圾回收任务；"Discipline in scaffolding, not code" | AGENTS.md 目录模式直接对应 CLAUDE.md 精简设计；docs/references/ 格式对标 references/ 嵌套；exec-plans 对应 pipeline-state.json；Linter 约束对应 Hooks 系统 | [notes](harness-eng-openai.md) |
| [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) — Mikaela Grace et al. (Anthropic) | 2026-01-09 | pass@k vs pass^k、三类 Grader（代码/模型/人类）、五要素框架（Task/Trial/Grader/Transcript/Outcome）、Eval-Driven Development | 实验评估框架设计；pass@k=峰值能力，pass^k=稳定性，直接指导 runs.log 分析维度 | [notes](evals-anthropic.md) |
| [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — Justin Young (Anthropic) | 2025-11-26 | Initializer/Coding Agent 双层架构、Feature list 外部状态机（JSON）、`claude-progress.txt` 跨 session 持久化、Puppeteer MCP 端到端测试 | 长实验 session 管理；pipeline-state.json + exp-manager agent 的理论基础 | [notes](long-running-anthropic.md) |
| [Context Engineering for AI Agents: Lessons from Building Manus](https://manus.im/zh-cn/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) — Yichao 'Peak' Ji (Manus) | 2025-07-18 | 五原则：KV 缓存设计、Mask 不 Remove 工具、文件系统作外部上下文、重述操控注意力、保留错误信息；~50 工具调用/任务，输入输出比 100:1 | 上下文工程实战案例；与 Cache-First 架构形成实践互证；错误保留原则指导 runs.log 设计 | [notes](context-engineering-manus.md) |
| [obra/superpowers](https://github.com/obra/superpowers) — Jesse Vincent | 2025-10 | 94.8K star 的 agentic skills framework；mandatory workflow；两阶段 review | Skills 框架对标 | [notes](superpowers-repo.md) |
| [learn-claude-code](https://github.com/shareAI-lab/learn-claude-code) — shareAI-lab | 2025-06 (持续更新至 2026-03) | 32.3K star；"Bash is all you need"；12 个渐进 session 逆向拆解 Claude Code harness 架构；核心论点：Agent = Model，工程师工作 = 构建 harness（Tools + Knowledge + Observation + Action + Permissions）；覆盖 Skills 按需加载(s05)、Subagent 隔离(s04)、Context Compact(s06)、file-based task graph(s07)、worktree isolation(s12) | Harness 原理底层文档；s05/s04/s06/s07/s12 与 LabMate 一一对应；可作为理解模板设计决策的理论基础 | [notes](learn-claude-code-shareai.md) |
| [如何有效地给 10 个 Claude Code 打工](https://zhuanlan.zhihu.com/p/2007147036185744607) — 郑重（Meshy AI CEO） | 2026 年初 | 10 步提升多 CC 吞吐量：`--dangerously-skip-permissions` + EC2 容器、Ralph loop 任务队列、Git worktree 并行（5 CC × 5min = 1 commit/min）、CLAUDE.md + PROGRESS.md 长记性、stream-json CC Manager（成功率 20%→95%）、语音输入、Plan Mode 批量 review；核心原则："Context not Control"，禁止微管理代码 | 多 session 并行工程化；PROGRESS.md 经验沉淀对应 SKILL.md 设计；CC Manager 架构对应 exp-manager；stream-json 输出对应 runs.log 结构化 | [notes](zhihu-2007147036185744607.md) |
| [Vibe Coding AReaL：零手打代码开发分布式 RL 训练框架](https://zhuanlan.zhihu.com/p/2003269671630165191) — AReaL/Starcat 团队 | 2026 年初 | 32 天/21,000 条消息/72 万行净增；两大核心：(1) 规划优先（AI 是规划放大器，Read 25K > Edit 14K，功能规划 74 次 vs 零写代码 9 次）；(2) Evidence 驱动（先设计验证再写代码，最小 demo 调试，测试=合同）；四层信息架构（rules/agents/skills/commands）= 跨 session 记忆；多 session 两种价值（multitasking + pass@k 采样）；74% session 部分完成 → 拆小任务是必要前提 | 四层信息架构与模板 agents/skills/commands/rules 直接对应；Evidence 驱动对应 Research Principles（Measure first + Baseline）；专业 agent 分工对应七类 agent 设计；pass@k 对应并行 Task 执行策略 | [notes](zhihu-2003269671630165191.md) |

## Cross-Cutting Themes

1. **Skills 是首要杠杆** — 文件夹化、Gotchas 积累、mandatory 触发（trq212 + bcherny + superpowers）；Skills 需要 last-used date 审计防止腐化（社区 @heyNaitik 实践）
2. **上下文工程 > Prompt 工程** — MCP 隐形消耗量化、分层加载策略（HiTw93 + OpenAI）；Progressive disclosure = Layer 3 模式：SKILL.md 精简 + 文件按需发现（trq212 agent-tool-design）
3. **外部状态 > 模型记忆** — progress file + git log + feature list + HANDOFF.md（Anthropic long-running + HiTw93）
4. **结构性约束 > 运行时监管** — linter 编码规则、feature list 防误判（OpenAI + Anthropic eval）
5. **并行化是最大乘数** — worktrees + subagents + 多 session（bcherny + superpowers）
6. **Eval-Driven Development** — 先定义 success criteria，pass@k/pass^k 区分一致性（Anthropic eval）
7. **Tool Minimalism + Seeing Like an Agent** — 从 agent 的 context 视角设计工具，从最小工具集开始按需扩展，"nice boss" harness 优化模型工作环境（trq212 agent-tool-design）
8. **Cache-First Architecture** — 工具集固定（动态工具切换每次 cache miss）、context 前缀稳定（CLAUDE.md 不在 session 中途修改）、defer_loading tool stubs、System Reminders in user messages（trq212 prompt-caching-first）
9. **Agent = Model，Harness = 环境** — 工程师职责是构建 harness（工具/知识/权限），而非试图"编程出智能"；prompt-chain 框架是现代 GOFAI；Skills 按需注入而非前置系统提示（learn-claude-code）
10. **上下文工程 vs Prompt 工程** — Mask 不 Remove 工具（防 cache 失效）、重述操控注意力（防 goal drift）、保留错误信息（隐式信念更新）；~50 工具调用/任务时上下文管理是首要成本杠杆（Manus context-engineering）
11. **Eval-Driven Development** — pass@k（峰值能力）vs pass^k（稳定性）区分是生产部署决策的核心依据；从 20-50 真实场景起步，逐步演进评估体系（Anthropic evals）
12. **多 Session 并行是最大吞吐杠杆** — Git worktree 物理隔离 + Ralph loop 任务队列 + CC Manager（stream-json 自纠错）可将 commit 节奏提升 5-10 倍；两个正交价值：multitasking（提升 RPS）+ pass@k 采样（探索多方案）；并行失效信号：所有 session 共享同一错误假设（郑重 + AReaL）
13. **Evidence 驱动 > 人工 Review** — AI 生成速度远超阅读速度，人工逐行 review 必然退化；测试 = AI 与人之间的"合同条款"；最小可复现 demo 是最被低估的调试实践；先设计验证方案再写代码（AReaL）
14. **规划放大器原则** — AI 核心价值在"想"不在"写"（Read 25K > Edit 14K；功能规划 74 次 vs 零写代码 9 次）；给 AI 全局上下文 > 零散小任务；嵌套式计划 + 分批读写保持 context 精简（AReaL）
15. **Context not Control** — 禁止微管理 AI 代码；精力集中在更清晰的需求描述、闭环环境设计、框架与权限铺路；PROGRESS.md/SKILL.md 沉淀经验教训是知识积累而非控制手段（郑重 + AReaL）
