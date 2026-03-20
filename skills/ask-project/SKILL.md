---
name: ask-project
description: "Query project history, experiment findings, and architecture via project-advisor. Use when user asks about past experiments, project progress, or research findings."
disable-model-invocation: true
---

# Ask Project

Natural language query interface to @project-advisor.

## Instructions

When this skill is invoked with `<question>`:

### Step 1: Delegate to @project-advisor

> User question: {question}
>
> Answer based on the project's actual data. Read `exp/summary.md`, `docs/papers/landscape.md`, and `.pipeline-state.json` as needed. Cite specific experiments and papers by name.

Note: project-advisor has `skills: project-skill` preloaded and reads project files on its own. Only pass the user's question.
