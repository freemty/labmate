---
name: todo
description: Use when adding, completing, listing, or cleaning project tasks in `docs/TODO.md`.
disable-model-invocation: true
---

# Todo

Resolve `<plugin-root>` and use the typed CRUD interface:

```bash
python3 <plugin-root>/scripts/todo.py add "<task>" --priority P1
python3 <plugin-root>/scripts/todo.py done "<unique text>"
python3 <plugin-root>/scripts/todo.py list
python3 <plugin-root>/scripts/todo.py clean
```

Default new tasks to `P1` unless urgency is explicit. If `done` reports multiple
matches, present them and ask the user to disambiguate. Report the JSON result;
do not manually reformat the file behind the script.
