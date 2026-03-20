# LabMate

> Research Harness for Claude Code. Keep your agent grounded in context, not lost in vibe coding.

## Quick commands

| Command | Purpose |
|---------|---------|
| `/init-project` | Initialize research skeleton in target project |
| `/new-experiment` | Scaffold a new experiment directory |
| `/analyze-experiment` | Analyze results from current experiment |
| `/update-project-skill` | Refresh project knowledge base |
| `/read-paper` | Deep-dive a single paper |
| `/survey-literature` | Systematic literature survey |

## Plugin architecture

| Component | Location | Auto-loaded |
|-----------|----------|-------------|
| Agents (7) | agents/ | Yes (plugin.json) |
| Skills (9) | skills/ | Yes (plugin.json) |
| Hooks (6) | hooks/ | Yes (hooks.json) |
| References | references/ | No (used by init-project) |

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| project-advisor | opus | Experiment history, findings, codebase navigation |
| cc-advisor | sonnet | Claude Code workflow best practices |
| domain-expert | opus | Reads papers, interprets experiment results |
| exp-manager | sonnet | Monitors experiments, diagnoses failures |
| slides-maker | sonnet | Generates HTML slides from analysis |
| viz-frontend | sonnet | Builds analysis dashboards |
| template-presenter | sonnet | Project overview and onboarding |

## Skills

| Skill | Trigger |
|-------|---------|
| init-project | One-command project initialization |
| new-experiment | Starting a new experiment |
| analyze-experiment | After experiment completes |
| update-project-skill | After major findings or when stale |
| present-template | Generate overview slides |
| weekly-progress | Summarize week's progress |
| commit-changelog | Commit with CHANGELOG |
| read-paper | Deep-dive a single paper with Q&A |
| survey-literature | Systematic literature survey |

## How to test

1. Install locally: add plugin path to settings.json
2. Create a test project: `mkdir /tmp/test-project && cd /tmp/test-project && git init`
3. Run `/init-project` and verify skeleton creation
4. Run `/init-project` again to verify idempotency
5. Test agent override: create `.claude/agents/domain-expert.md` in test project
6. Verify SessionStart hook injects context on new session

## Branch strategy

- **main** = Plugin release (clean, only plugin infrastructure)
- **dev** = Development + self-use (may have override files, experiment data)

## Specs

- `docs/specs/2026-03-18-inject-template-design.md` — plugin architecture
- `docs/specs/2026-03-19-labmate-rename.md` — rename rationale
- `docs/specs/2026-03-20-literature-skills-design.md` — /read-paper + /survey-literature design
