# {project-name}

> {description}

## Quick commands

| LabMate skill | Purpose |
|---------------|---------|
| `new-experiment` | Scaffold new experiment |
| `analyze-experiment` | Analyze results |
| `update-project-skill` | Refresh project knowledge |
| `commit-changelog` | Commit with CHANGELOG |
| `update-knowhow` | Archive environment knowledge |
| python scripts/launch_exp.py --exp <id> | Launch experiment |

Invoke skills through the current host's skill selector or ask for them by
name. Claude Code uses `/labmate:<skill>`; Codex uses `$labmate:<skill>` or
`/skills`.

## Session startup

| What to do | Read first |
|-----------|-----------|
| Catch up on progress | {project-skill-path} |
| Check domain literature | docs/papers/landscape.md |
| Run current experiment | exp/{current_exp}/README.md |

## Project knowledge

- **Skill hub:** {project-skill-path}
- **Experiment log:** exp/summary.md
- **Domain papers:** docs/papers/

## Agent parity

- Claude Code entrypoint: `CLAUDE.md`
- Codex / Antigravity entrypoint: `AGENTS.md`
- Claude project memory: `.claude/skills/project-skill/`
- Codex / Antigravity project memory: `.agents/skills/project-skill/`
- If both entrypoints exist, keep project-skill content mirrored and run `bash scripts/check_agent_parity.sh` after changing project memory or instruction files.

## Knowhow

- `docs/knowhow/infrastructure/` — Servers, networking, disk, GPU issues
- `docs/knowhow/toolchain/` — CLI tools, docker, conda/pip, framework tips
- `docs/knowhow/debug-solutions/` — Error investigation paths and fixes
- `docs/knowhow/runbooks/` — Step-by-step operational procedures

## LabMate roles

| Role | Purpose |
|------|---------|
| project advisor | Experiment history, findings, codebase navigation |
| domain expert | Papers, domain knowledge, design advice |
| experiment manager | Monitor experiments and diagnose failures |
| slides maker | Generate HTML slides from analysis |
| visualization frontend | Build analysis dashboards |

## Skills

| Skill | Trigger |
|-------|---------|
| `new-experiment` | Starting a new experiment |
| `analyze-experiment` | After experiment completes |
| `update-project-skill` | After major findings or when stale |
| `commit-changelog` | Commit with CHANGELOG |
| `update-knowhow` | Archive environment knowledge |
| `visualize` | Results dashboard or project overview |
| `monitor` | Check experiment status |

## Workflow

```
new-experiment → run → analyze-experiment
  → commit findings → update-project-skill → repeat
```

Pipeline state tracked in .pipeline-state.json.

## Research principles

1. **Measure first** — attack the actual bottleneck, not your intuition
2. **Baselines are sacred** — every claim needs a reproducible baseline comparison
3. **Statistical rigor** — single-run results are anecdotal, track variance
4. **Ablation-driven** — multi-factor changes require per-factor isolation
5. **Respect negative results** — don't retry failed directions without new evidence
6. **Predict first** — record expected numbers before running, calibrate after

## Conventions

- **Exp naming:** exp{NN}{x} — number=major direction, letter=variant
- **Prompt versioning:** prompts/{component}/_v{NN}.md — never overwrite, always increment
- **CHANGELOG rule:** all iterating artifacts (prompts, skills, agents) must have CHANGELOG entries
- **Worktree rule:** destructive or exploratory changes use git worktree

## Current state

- **current_exp:** null
- **stage:** dev
- **skill_updated_at:** {date}
