---
name: update-project-skill
description: Use when durable project architecture, experiment findings, pitfalls, or active interfaces have materially changed.
disable-model-invocation: true
---

# Update Project Skill

Keep project-skill as a compact map of stable facts and gotchas, not a session
diary or repository duplicate.

1. Resolve `<plugin-root>` and collect bounded facts:

   ```bash
   python3 <plugin-root>/scripts/project_snapshot.py
   ```

2. Read only files needed to validate architecture, findings, active versions,
   and durable pitfalls.
3. Propose a focused diff. Preserve append-only lessons unless evidence shows
   they are false.
4. Apply after approval when semantic. Mechanical mirror synchronization may
   proceed without another prompt.
5. Keep `.agents/` and `.claude/` mirrors identical when both exist, run the
   parity checker, append the changelog, and update `skill_updated_at`.

Do not copy file trees, skill catalogs, command tutorials, or transient tasks
into project-skill.
