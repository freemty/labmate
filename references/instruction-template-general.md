# {project-name}

> {description}

## Quick commands

| LabMate skill | Purpose |
|---------------|---------|
| `update-project-skill` | Refresh project knowledge |
| `commit-changelog` | Commit with CHANGELOG |
| `update-knowhow` | Archive environment knowledge |

Invoke skills through the current host's skill selector or ask for them by
name. Claude Code uses `/labmate:<skill>`; Codex uses `$labmate:<skill>` or
`/skills`.

## Session startup

| What to do | Read first |
|-----------|-----------|
| Catch up on progress | {project-skill-path} |

## Project knowledge

- **Skill hub:** {project-skill-path}

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
| project advisor | Project history and codebase navigation |
| domain expert | Domain knowledge and design advice |

## Skills

| Skill | Trigger |
|-------|---------|
| `update-project-skill` | After major findings or when stale |
| `commit-changelog` | Commit with CHANGELOG |
| `update-knowhow` | Archive environment knowledge |

## Conventions

- **CHANGELOG rule:** all significant changes must have CHANGELOG entries
- **Worktree rule:** destructive or exploratory changes use git worktree
