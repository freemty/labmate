# Contributing to LabMate

Thanks for your interest in contributing! LabMate is a pure-Markdown research harness for AI coding agents — no build step, no dependencies.

## Quick start

1. Fork and clone the repo
2. Add the plugin to your Claude Code settings:
   ```json
   {
     "plugins": ["/path/to/your/labmate"]
   }
   ```
3. Create a branch: `git checkout -b feat/your-feature`
4. Make changes
5. Commit using conventional commits (see below)
6. Open a PR

## What you can contribute

**Agents** (`agents/*.md`):
- One Markdown file per agent
- Frontmatter: name, description, model (haiku/sonnet/opus)
- Keep under 400 lines

**Skills** (`skills/<name>/SKILL.md`):
- One directory per skill, with a `SKILL.md` file
- Frontmatter: name, description
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
- Test changes by installing the plugin locally and running the relevant skill/agent. For project-memory changes, verify both Claude Code (`CLAUDE.md` / `.claude/`) and Codex or Antigravity (`AGENTS.md` / `.agents/`) behavior when both surfaces are present.

## Finding work

Check issues labeled [`good first issue`](https://github.com/freemty/labmate/labels/good%20first%20issue) for starter tasks.

## Questions?

Open an issue — there are no dumb questions.
