---
name: update-docs
description: Use when verified knowledge, a design decision, a runbook, or human-facing documentation should be made durable.
---

# Update Docs

Archive only information worth carrying into a future session. Read
`../../references/archival-contract.md` before writing.

1. Infer document kind and destination. Ask only when two destinations imply
   materially different readers.
2. Search for an existing document covering the topic.
3. Extract evidence, decision, commands, provenance, and unresolved gaps.
4. Update the existing file or create the smallest durable document satisfying
   the archival contract.
5. Report changed paths and what was verified.

Use knowhow categories for environment and debugging knowledge. Use
spec/design/guide/README/changelog destinations for human-facing documents.
Do not archive an error hypothesis as a resolved cause, and do not auto-write
documentation merely because a generic hook suggested it.
