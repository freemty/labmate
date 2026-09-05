---
name: update-knowhow
description: Use when the user explicitly asks to archive environment, toolchain, debugging, or operational knowledge. Triggers on "记下来", "归档", "save this".
disable-model-invocation: true
---

# Update Knowhow

Use [the archival contract](../../references/archival-contract.md) with an
existing knowhow destination. This alias can complete the task directly; it
does not depend on being able to invoke another skill.

Preserve exact observed commands/configuration, relevant versions, provenance
and verification. Separate symptoms, candidate causes, attempted fixes and
verified resolution. An unresolved investigation may be saved as unresolved;
a failed command does not prove a fix or justify changing the environment.

Update an existing entry when it covers the same problem. Carry forward the
task's archival authorization, check the changed slice, and report paths and
remaining uncertainty. Do not duplicate the record into a personal wiki or
commit/publish it unless that destination/action was also requested.
