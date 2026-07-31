---
name: commit-changelog
description: Use when preparing a focused git commit, updating a changelog, or committing nested repositories and their parent gitlinks.
disable-model-invocation: true
---

# Commit and Changelog

Turn the reviewed diff into the smallest coherent commit. Match the repository's
existing style rather than imposing a universal template.

1. Inspect status, diff, recent commits, and repository boundaries.
2. Separate unrelated user changes. Never stage them for convenience.
3. Update the changelog only when this repository treats it as part of the
   change contract.
4. Verify changed behavior, stage explicit paths, and review the staged diff.
5. Commit nested repositories first. Commit the parent only after the inner
   commit exists and the gitlink points to it.
6. Push only when the user requested publishing.

Keep commit bodies about motivation, impact, and verification. Do not add a
generic AI co-author trailer unless the project requires one. For weekly
reporting, use the repository's `weekly-report` skill.
