# LabMate

> Research harness for AI coding agents.

## Codex skill invocation

Use `/skills` or type `$` and select `labmate:<skill>`. Core workflows include:

| Skill | Purpose |
|-------|---------|
| `init-project` | Initialize a project skeleton |
| `new-experiment` | Scaffold an experiment |
| `monitor` | Check experiment status |
| `analyze-experiment` | Analyze results |
| `read-paper` | Deep-dive a paper |
| `survey-literature` | Survey a topic |
| `visualize` | Build dashboards or overview artifacts |
| `update-project-skill` | Refresh project knowledge |
| `commit-changelog` | Commit with CHANGELOG updates |

## Architecture

- `skills/`: twelve portable Agent Skills.
- `agents/`: five Claude Code named-agent definitions. Codex skills use the
  same role bodies through portable subagent fallback.
- `hooks/`: thirteen handlers across five lifecycle events.
- `references/`: templates and reusable project assets.

Codex does not load `agents/*.md` from the plugin manifest. Agent-backed skills
must follow `references/agent-routing.md` and remain executable without named
agents or background execution.

## Project knowledge

Read `.agents/skills/project-skill/SKILL.md` for accumulated architecture,
experiment history, and lessons. Keep it mirrored with
`.claude/skills/project-skill/SKILL.md`.

## Verification

```bash
bash tests/test-hooks.sh
bash tests/test-platform-compat.sh
```

When installer behavior changes, also run the outer repository installer tests.
Preserve unrelated dirty worktree state and commit the LabMate submodule before
updating the parent repository pointer.
