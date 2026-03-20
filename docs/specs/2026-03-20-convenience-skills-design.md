# Convenience Skills Design: `/visualize` + `/monitor` + `/ask-project`

**Date:** 2026-03-20
**Status:** Reviewed
**Context:** Agent trigger gap audit — viz-frontend, exp-manager, project-advisor lack convenient skill entry points

---

## Overview

Three lightweight skills that serve as convenience entry points to existing agents. No new agents, no agent modifications, no new capabilities — just reducing friction.

| Skill | Agent | Problem solved |
|-------|-------|---------------|
| `/visualize` | viz-frontend | No natural path from "analysis done" to "see dashboard" |
| `/monitor` | exp-manager | `/loop 5m use @exp-manager to check exp01a` is too verbose |
| `/ask-project` | project-advisor | Must remember agent name to ask project questions |

---

## Skill 1: `/visualize`

### Purpose

Build or update a Flask + HTML dashboard for experiment results via viz-frontend.

### Usage

```
/visualize              # Current experiment results dashboard
/visualize exp01a       # Specific experiment
/visualize compare      # Cross-experiment comparison view
```

### Instructions

1. **Determine target:**
   - If argument is `compare` → comparison mode
   - If argument is an exp ID → that experiment
   - If no argument → read `.pipeline-state.json` for `current_exp`
   - If `current_exp` is null and no argument → ask user which experiment

2. **Gather data context:**
   - Read `exp/{exp_id}/results/summary.md` (or `exp/summary.md` for compare mode)
   - Read `exp/{exp_id}/README.md` for experiment context
   - Check if `viewer/app.py` exists (update vs create)

3. **Delegate to `@viz-frontend`:**

   For single experiment:
   > Build a results dashboard for experiment {exp_id}.
   > Results data: {summary.md content}
   > Experiment context: {README.md content}
   > Viewer directory: `viewer/`
   > If `viewer/app.py` exists, add/update the view. Otherwise create from scratch.

   For compare mode:
   > Build a cross-experiment comparison dashboard.
   > Summary data: {exp/summary.md content}
   > Viewer directory: `viewer/`

4. **Report:** Tell user how to access: `python viewer/app.py` then open `http://localhost:5001`

---

## Skill 2: `/monitor`

### Purpose

One-command experiment status check and monitoring setup via exp-manager.

### Usage

```
/monitor                # Check current_exp status once
/monitor exp02a         # Check specific experiment once
```

### Instructions

1. **Determine target experiment:**
   - If argument provided → use as exp_id
   - If no argument → read `.pipeline-state.json` for `current_exp`
   - If `current_exp` is null and no argument → ask user which experiment

2. **Verify experiment exists:**
   - Check `exp/{exp_id}/` directory exists
   - Check `exp/{exp_id}/results/runs.log` exists
   - If not → tell user to run `/new-experiment` first

3. **Delegate to `@exp-manager`:**
   > Check experiment {exp_id} status.
   > Read `exp/{exp_id}/results/runs.log` and `.pipeline-state.json`.
   > Diagnose any failures, auto-retry if appropriate, report status.

4. **After check, suggest continuous monitoring:**
   > Status check complete. For continuous monitoring, run:
   > `/loop 5m /monitor {exp_id}`

Note: `/monitor` itself always runs a single check. Continuous monitoring is achieved by wrapping it with `/loop`, which is a built-in Claude Code command the user invokes directly.

---

## Skill 3: `/ask-project`

### Purpose

Natural language query interface to project-advisor. Ask questions about experiment history, findings, and project architecture.

### Usage

```
/ask-project What experiments have we run on attention sink?
/ask-project Project progress overview
/ask-project How does exp02a relate to exp01b?
```

### Instructions

1. **Delegate to `@project-advisor`:**
   > User question: {the user's question}
   >
   > Answer based on the project's actual data. Read `exp/summary.md`, `docs/papers/landscape.md`, and `.pipeline-state.json` as needed. Cite specific experiments and papers by name.

   Note: project-advisor has `skills: project-skill` preloaded and reads files on its own. The skill only passes the user's question — no need to pre-fetch context.

---

## Implementation Scope

### New files to create
- `skills/visualize/SKILL.md`
- `skills/monitor/SKILL.md`
- `skills/ask-project/SKILL.md`

All skills use standard frontmatter:
```yaml
---
name: {skill-name}
description: "..."
disable-model-invocation: true
---
```

### Files to modify
- `CLAUDE.md` — update in 4 places:
  1. Quick commands table: add `/visualize`, `/monitor`, `/ask-project`
  2. Plugin architecture table: change `Skills (9)` to `Skills (12)`
  3. Skills table: add `visualize`, `monitor`, `ask-project`
  4. Specs section: add reference to this design doc

### No changes needed
- No agent modifications (all 3 agents already have the needed capabilities)
- `plugin.json` — auto-discovers via `"./skills/"` directory convention

### Not in scope
- No new agents
- No external dependencies
- No hooks
- No changes to existing skills
