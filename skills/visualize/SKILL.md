---
name: visualize
description: >
  Build a results dashboard, comparison view, or project overview. Triggers on
  "visualize", "可视化", "show results", "dashboard", "compare experiments",
  "chart my results", "project overview".
disable-model-invocation: true
---

# Visualize

Build a Flask + HTML dashboard for experiment results.

## Agent Routing

Read `<plugin-root>/references/agent-routing.md` before delegating. Resolve
`<plugin-root>` by going up two directories from this `SKILL.md`.

## Instructions

When this skill is invoked with optional `<argument>`:

### Step 1: Determine target

- If argument is `overview` → project overview mode using the `slides-maker`
  role in Mode 3
- If argument is `compare` → comparison mode (cross-experiment)
- If argument is an exp ID (e.g., `exp01a`) → that experiment
- If no argument → read `.pipeline-state.json` for `current_exp`
- If `current_exp` is null and no argument → ask user which experiment or overview

### Step 2: Gather data

For single experiment:
- Read `exp/{exp_id}/results/summary.md` for quantitative results
- Read `exp/{exp_id}/README.md` for experiment context
- Check if `viewer/app.py` already exists (update vs create)

For compare mode:
- Read `exp/summary.md` for cross-experiment overview

### Step 3: Run the visualization role

For single-experiment and comparison modes, follow the portable routing
contract with `<plugin-root>/agents/viz-frontend.md`.

For single experiment:
> Build a results dashboard for experiment {exp_id}.
> Results data: {summary.md content}
> Experiment context: {README.md content}
> Viewer directory: `viewer/`
> If `viewer/app.py` exists, add/update the view for this experiment. Otherwise create from scratch.

For compare mode:
> Build a cross-experiment comparison dashboard.
> Summary data: {exp/summary.md content}
> Viewer directory: `viewer/`

For overview mode:
- Ask user what type: "slides" (default), "onboarding", or "demo-script"
- Follow the portable routing contract with
  `<plugin-root>/agents/slides-maker.md`:
  > mode: overview
  > content_type: {user's choice}

### Step 4: Report

Tell user: "Dashboard ready. Run `python viewer/app.py` and open http://localhost:5001"
