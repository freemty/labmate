---
name: monitor
description: >
  Check experiment status and diagnose failures. Triggers on
  "check status", "看看实验", "how's the run", "any failures", "is it done",
  "monitor experiment", "experiment status".
disable-model-invocation: true
---

# Monitor

One-command experiment status check using the `exp-manager` role.

## Agent Routing

Read `<plugin-root>/references/agent-routing.md` before delegating. Resolve
`<plugin-root>` by going up two directories from this `SKILL.md`.

## Instructions

When this skill is invoked with optional `<exp_id>`:

### Step 1: Determine target experiment

- If argument provided → use as exp_id
- If no argument → read `.pipeline-state.json` for `current_exp`
- If `current_exp` is null and no argument → ask user which experiment

### Step 2: Verify experiment exists

- Check `exp/{exp_id}/` directory exists
- Check `exp/{exp_id}/results/runs.log` exists
- If not → tell the user the experiment was not found and suggest using
  LabMate's `new-experiment` skill first.

### Step 3: Run the `exp-manager` role

Follow the portable routing contract with
`<plugin-root>/agents/exp-manager.md`, using this task:

> Check experiment {exp_id} status.
> Read `exp/{exp_id}/results/runs.log` and `.pipeline-state.json`.
> Diagnose any failures, auto-retry if appropriate, report status.

### Step 4: Offer continuous monitoring

After the check completes, tell user:

- In the Codex app, offer to create a scheduled task that runs the LabMate
  `monitor` skill every five minutes.
- On other hosts, suggest invoking `monitor` again when another check is
  needed.
- Use a host-specific loop command only when that host explicitly provides one.
