---
name: project-skill
description: "Use when advising on project architecture, experiment history, codebase navigation, or research findings. Auto-maintained by /update-project-skill."
user-invocable: false
---

# LabMate — Project Knowledge

> Last updated: 2026-03-19

## Project overview

LabMate (formerly cc-native-research-template) is a Claude Code Plugin for research project lifecycle. Renamed on 2026-03-19.

- **Repo:** https://github.com/freemty/labmate
- **Tagline:** Research Harness for Claude Code. Keep your agent grounded in context, not lost in vibe coding.
- **Version:** 0.4.0
- **License:** MIT

## Architecture (plugin structure)

```
labmate/
├── .claude-plugin/plugin.json    # Manifest (name, agents, skills, hooks)
├── agents/ (7)                   # CC auto-loads
├── skills/ (7)                   # CC auto-loads (namespace: labmate:)
├── hooks/                        # hooks.json + 6 extensionless scripts
│   ├── hooks.json                # SessionStart + PreCompact + Stop + PostToolUse + PreToolUse
│   ├── run-hook.cmd              # Cross-platform wrapper
│   └── session-start             # Context injection based on .pipeline-state.json
├── references/                   # Used by init-project (not auto-loaded)
│   ├── claude-md-template.md     # 9 sections with placeholders
│   ├── project-skill-template.md
│   ├── gitignore-rules.md
│   └── scripts + viewer files
├── docs/
│   ├── tutorial.md               # First experiment walkthrough
│   ├── specs/                    # Design specs
│   └── papers/                   # Literature (instance data, dev only)
```

## Key design decisions

1. Plugin over Template — `claude plugin install`, not "Use this template"
2. Agent override — project `.claude/agents/x.md` overrides plugin (priority 2 > 4)
3. Skill namespace — `/labmate:skill-name` for plugin, `/skill-name` for local
4. rules/ not supported by plugins — research principles in CLAUDE.md via init-project
5. SessionStart hook — auto-detect init state, inject context
6. Hooks use run-hook.cmd — extensionless scripts, cross-platform
7. main = plugin release, dev = working instance

## Literature landscape

12+ entries in docs/papers/landscape.md:
- trq212 trilogy: Prompt Caching → Tool Design → Skills Design
- HiTw93: CC 六层架构 + MCP 预算量化
- OpenAI Harness Engineering, Anthropic Evals + Long-Running Agents
- Manus Context Engineering, learn-claude-code, superpowers growth
- 2 zhihu: multi-CC parallel + AReaL vibe coding

## Key pitfalls

1. `cp -r` creates nested duplicates — always verify after bulk copy
2. CC plugins cannot distribute rules/ — upstream limitation
3. Plugin skills always namespaced `/plugin:skill`
4. Agent override works; skill override uses namespace isolation instead
5. SessionStart matcher: use `""` for non-tool events
6. Hook scripts must be extensionless for Windows compat
7. `git rm` on main needs `--cached` + manual rm for working dir cleanup

## Quick reference

| Command | Purpose |
|---------|---------|
| `/labmate:init-project` | Init research skeleton in target project |
| `/labmate:new-experiment` | Scaffold new experiment |
| `/labmate:analyze-experiment` | Analyze results |
| `claude --plugin-dir .` | Test plugin locally |
