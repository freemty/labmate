# LabMate

> Research Harness for Claude Code. Keep your agent grounded in context, not lost in vibe coding.

## Quick commands

| Command | Purpose |
|---------|---------|
| `/labmate:init-project` | Initialize research skeleton in target project |
| `/labmate:new-experiment` | Scaffold a new experiment directory |
| `/labmate:analyze-experiment` | Analyze results from current experiment |
| `/labmate:update-project-skill` | Refresh project knowledge base |
| `/labmate:read-paper` | Verified full-text deep-dive or literature-hub triage |
| `/labmate:survey-literature` | Systematic literature survey |
| `/labmate:visualize` | Build results dashboard for experiment |
| `/labmate:monitor` | Check experiment status |
| `/labmate:update-knowhow` | Alias to update-docs knowhow branch |
| `/labmate:todo` | Lightweight task tracking with auto-index |
| `/labmate:update-docs` | Unified archival for knowhow and human docs |

## Plugin architecture

| Component | Location | Auto-loaded |
|-----------|----------|-------------|
| Claude named agents (5) | agents/ | Yes (`.claude-plugin/plugin.json`) |
| Skills (12) | skills/ | Yes (plugin.json) |
| Hook handlers (13 / 5 events) | hooks/ | Yes (hooks.json) |
| References | references/ | No (used by init-project) |

## Agents

The Markdown body of each agent is portable. Codex does not load these named
agents from its plugin manifest; agent-backed skills instead use a normal
subagent or main-thread fallback.

| Agent | Model | Purpose |
|-------|-------|---------|
| project-advisor | opus | Experiment history, findings, codebase navigation |
| domain-expert | opus | Reads papers, deep-dives methodology, surveys literature, interprets results |
| exp-manager | sonnet | Monitors experiments, diagnoses failures |
| slides-maker | sonnet | Generates HTML slides — analysis, presentations, project overview |
| viz-frontend | sonnet | Builds analysis dashboards |

## Skills

| Skill | Trigger |
|-------|---------|
| init-project | One-command project initialization |
| new-experiment | Starting a new experiment |
| analyze-experiment | After experiment completes |
| update-project-skill | After major findings or when stale |
| commit-changelog | Commit with CHANGELOG + weekly progress |
| read-paper | Verified paper deep-dive or hub triage with Q&A |
| survey-literature | Systematic literature survey |
| visualize | Results dashboard, comparison, or project overview |
| monitor | Check experiment status |
| update-knowhow | Alias → update-docs (knowhow branch auto-selected) |
| todo | Lightweight task tracking — add/done/list/clean |
| update-docs | Unified archival: knowhow (Branch A) + docs (Branch B), auto-routes |

## How to test

1. Install locally in Claude Code or from the parent Codex marketplace
2. Create a test project: `mkdir /tmp/test-project && cd /tmp/test-project && git init`
3. Run `/labmate:init-project` and verify skeleton creation
4. Run `/labmate:init-project` again to verify idempotency
5. Test agent override: create `.claude/agents/domain-expert.md` in test project
6. Verify SessionStart hook injects context on new session
7. Run `bash tests/test-hooks.sh` and `bash tests/test-platform-compat.sh`

## Branch strategy

- **main** = Plugin release (clean, only plugin infrastructure)
- **dev** = Development + self-use (may have override files, experiment data)

## Experiment rules

1. **Cleanup and running experiments must be isolated** — NEVER run disk cleanup, `umount`, environment reset, or deployment operations while experiments are active on the same machine. Always confirm no active jobs before any cleanup.
2. **Smoke test the full pipeline before multi-machine deploy** — Before deploying N jobs x M servers, run the complete end-to-end flow on 1 machine first. Single-machine success does not guarantee distributed success (SSH, quoting, filesystem, process management all introduce new failure modes).
3. **Experiments must have built-in resume** — Large-scale experiments will always partially fail (API rate limits, network errors, disk issues, process crashes). The framework must support checking completion rate and re-running only failed items.

## Knowhow
- `docs/knowhow/infrastructure/` — Servers, networking, disk, GPU issues
- `docs/knowhow/toolchain/` — CLI tools, docker, conda/pip, framework tips
- `docs/knowhow/debug-solutions/` — Error investigation paths and fixes
- `docs/knowhow/runbooks/` — Step-by-step operational procedures

## Guides
- `docs/guides/releasing.md` — Developer guide: release script, version bump, marketplace sync
- `docs/guides/installing.md` — User guide: install, update, verify, troubleshooting

## Specs

- `docs/specs/2026-03-18-inject-template-design.md` — plugin architecture
- `docs/specs/2026-03-19-labmate-rename.md` — rename rationale
- `docs/specs/2026-03-20-literature-skills-design.md` — /read-paper + /survey-literature design
- `docs/specs/2026-03-20-convenience-skills-design.md` — /visualize + /monitor + /ask-project design
- `docs/specs/2026-03-30-update-knowhow-design.md` — /update-knowhow environment knowledge archival
- `docs/specs/2026-04-21-todo-and-update-docs-design.md` — /todo + /update-docs 带自动索引的文档维护
