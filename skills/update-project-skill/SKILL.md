---
name: update-project-skill
description: Use when durable project architecture, experiment findings, pitfalls, or active interfaces have materially changed. Triggers on "refresh project knowledge", "更新项目知识", project-skill drift, or after major findings.
disable-model-invocation: true
---

# Update Project Skill

Keep project-skill as a compact map of stable facts and gotchas, not a session
diary or repository duplicate.

1. Resolve `<plugin-root>` and collect bounded facts:

   ```bash
   python3 <plugin-root>/scripts/project_snapshot.py
   ```

2. A bounded read-only scan may use a suitable subagent for high-reasoning
   analysis when available; otherwise scan directly. Read only files needed to validate architecture, findings, active versions,
   and durable pitfalls.
3. Propose a focused diff. Preserve append-only lessons unless evidence shows
   they are false.
4. Apply the requested knowledge update within the user's authorization. Ask
   only when conflicting evidence or a new scope choice would change the result.
5. Keep `.agents/` and `.claude/` mirrors identical when both exist, run the
   parity checker, append the changelog, and update `skill_updated_at`.

Do not copy file trees, skill catalogs, command tutorials, or transient tasks
into project-skill.
