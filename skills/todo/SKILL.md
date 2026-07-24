---
name: todo
description: >
  Lightweight task tracking with auto-index. Add/complete/list TODO items stored
  in docs/TODO.md. Use when user says "todo", "记一下", "待办", "回头要",
  "add a todo", or wants to track action items during work.
disable-model-invocation: true
---

# Todo

Lightweight TODO tracking — one line per item, auto-indexed in the project instruction file (`AGENTS.md` for Codex/Antigravity, `CLAUDE.md` for Claude Code).

## Usage

| Input | Operation |
|-------|-----------|
| `<description>` | Add a new item (default) |
| `done <N>` | Mark item N as complete |
| `list` | Show all pending items |
| `clean` | Remove all completed items |

## Step 1: Determine Operation

Parse user input:
- No args or just a description → `add`
- Starts with "done" + number → `done`
- Starts with "list" → `list`
- Starts with "clean" → `clean`

## Step 2: Ensure File Exists

Check if `docs/TODO.md` exists in the project root. If not:
1. Create it with header `# TODO`
2. Add index entry to the active instruction file: `- \`docs/TODO.md\` — Project action items and task backlog`
3. If both `AGENTS.md` and `CLAUDE.md` exist, add the same index entry to both.

If file already exists, skip this step entirely.

## Step 3: Execute Operation

### Add

Append a new line to `docs/TODO.md`:

```markdown
- [ ] <description> — <YYYY-MM-DD>
```

Rules:
- Always add the current date
- One item per line, no sub-tasks
- If the description is vague, ask the user to clarify before adding

Report: "Added: <description>"

### Done

Read `docs/TODO.md`, find the Nth pending item (counting only `- [ ]` lines, 1-indexed), change it to:

```markdown
- [x] ~~<description>~~ — <original-date> (done <YYYY-MM-DD>)
```

Report: "Completed: <description>"

### List

Read `docs/TODO.md`, output only pending items (`- [ ]` lines) with their index numbers:

```
1. <description> — <date>
2. <description> — <date>
```

If none: "No pending TODOs."

### Clean

Remove all lines matching `- [x]` from `docs/TODO.md`.

Report: "Removed N completed items."

## Common Mistakes

| Mistake | Correct |
|---------|---------|
| Adding vague items like "fix that thing" | Ask for specifics |
| Forgetting the date | Always append `— YYYY-MM-DD` |
| Creating docs/TODO.md without indexing | Always check `AGENTS.md` and `CLAUDE.md` when both exist |
| Numbering completed items in `list` | Only number pending `- [ ]` items |
