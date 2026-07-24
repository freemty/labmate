# Contributing to LabMate

Thanks for your interest in contributing! LabMate is a pure-Markdown research harness for AI coding agents — no build step, no dependencies.

## Quick start

1. Fork and clone the repo
2. Install the local plugin in the host you want to test:

   Claude Code:
   ```json
   {
     "plugins": ["/path/to/your/labmate"]
   }
   ```

   Codex, from the parent `yuanbo-skills` checkout:
   ```bash
   codex plugin marketplace add /path/to/yuanbo-skills
   codex plugin add labmate@yuanbo-skills
   ```
3. Create a branch: `git checkout -b feat/your-feature`
4. Make changes
5. Commit using conventional commits (see below)
6. Open a PR

## What you can contribute

**Claude Code named agents** (`agents/*.md`):
- One Markdown file per agent
- Frontmatter: name, description, model (haiku/sonnet/opus)
- Keep the Markdown body portable because Codex fallback subagents also read it
- Keep under 400 lines

**Skills** (`skills/<name>/SKILL.md`):
- One directory per skill, with a `SKILL.md` file
- Frontmatter: name, description
- Explicit-only skills also require `agents/openai.yaml` for Codex
- Follow the existing skill structure

**Hooks** (`hooks/`):
- Shell scripts (extensionless) in hooks/
- Register in `hooks/hooks.json`

## Commit format

```
<type>: <description>

Types: feat, fix, refactor, docs, test, chore
```

## Code conventions

- Pure Markdown — no runtime dependencies
- Files under 400 lines
- Run `bash tests/test-hooks.sh` and `bash tests/test-platform-compat.sh`.
- Test the relevant workflow without named agents, then verify the Claude named
  agent path still works.
- For project-memory changes, verify both Claude Code (`CLAUDE.md` / `.claude/`)
  and Codex or Antigravity (`AGENTS.md` / `.agents/`) behavior.

## Finding work

Check issues labeled [`good first issue`](https://github.com/freemty/labmate/labels/good%20first%20issue) for starter tasks.

## Questions?

Open an issue — there are no dumb questions.
