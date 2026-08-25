---
name: monitor
description: Use when checking a running experiment, diagnosing a stalled job, or reviewing failures in an `expNNx` run. Triggers on "check status", "看看实验", "how's the run", "any failures", "is it done", "monitor experiment", "experiment status".
disable-model-invocation: true
---

# Monitor

Perform one status cycle per invocation. Recurrence belongs to the host's
scheduler.

1. Resolve the experiment from the argument or `.pipeline-state.json`.
2. Run `scripts/monitor_exp.sh <exp_id>` when available and inspect the relevant
   log tail and process state.
3. Follow `../../references/agent-routing.md` for the `exp-manager` role when
   diagnosis is needed.
4. Report status, evidence, uncertainty, and the next safe action.

Do not kill, retry, or relaunch work without clear authorization and an exact
target. For repeated checks, offer the current host's native scheduler when it
has one; otherwise suggest another invocation.
