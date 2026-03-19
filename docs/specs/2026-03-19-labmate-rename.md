# LabMate Rename Spec

**Date:** 2026-03-19
**Status:** Approved

## Brand

- Repo name: `labmate`
- GitHub description: "Research Harness for Claude Code. Keep your agent grounded in context, not lost in vibe coding."
- Topics: claude-code, plugin, research, experiment, harness, agents, skills, ai-research
- Code/paths: `labmate` (lowercase)
- Docs/titles: `LabMate` (camel case)

## Changes

1. Rename all internal references from `cc-native-research-template` to `labmate`
2. Swap README languages: English becomes README.md, Chinese becomes README_ZH.md
3. Rewrite both READMEs with new copy (pain-point first, humanized)
4. Update plugin.json, package.json, CLAUDE.md, hooks, skills, gitignore-rules
5. Add CHANGELOG entry
6. GitHub repo rename done last (after all code changes pushed)

## Files not changed

- docs/specs/*.md — keep historical references as-is
- agents/*.md — no project name references inside
- skills other than init-project — no project name references
