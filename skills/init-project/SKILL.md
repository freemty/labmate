---
name: init-project
description: Use when LabMate is being added to an existing project or `.pipeline-state.json` is missing.
disable-model-invocation: true
---

# Init Project

Create an idempotent LabMate skeleton through the bundled interface. The model
infers project metadata; the script owns filesystem layout and parity.

## Workflow

1. Inspect the repository and infer project name, description, domain,
   `general` or `research`, compute environment, and host target.
2. Show the inferred values once. Ask only about a value that would materially
   change the generated project.
3. Resolve `<plugin-root>` from this file and preview:

   ```bash
   python3 <plugin-root>/scripts/init_project.py plan \
     --type <general|research> --target <codex|claude|both> \
     --project-name <name> --description <description> --domain <domain>
   ```

4. If the plan would overwrite or semantically conflict with existing project
   instructions, stop and explain. Otherwise rerun with `apply`, then `check`.
5. Report created, updated, skipped, and missing paths from the JSON results.

## Contract

- Existing project files are never replaced. Missing instruction sections may
  be appended; existing sections remain authoritative.
- When both hosts are selected, project-skill mirrors must match.
- A dirty worktree is not an automatic blocker. Preserve unrelated changes and
  call out overlapping target files before applying.
- Do not initialize LabMate merely because a session hook mentions it.
