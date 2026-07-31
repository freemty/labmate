---
name: analyze-experiment
description: Use when an experiment has completed and its results need interpretation, comparison, or durable findings.
disable-model-invocation: true
---

# Analyze Experiment

Separate measurement from interpretation. Preserve raw outputs; write claims
only at the level supported by the experiment contract.

1. Read pipeline state, the experiment README/config, result files, and any
   existing summary.
2. Run the experiment's analysis script when present. Treat output as
   measurement, not explanation.
3. Follow `../../references/agent-routing.md` for the `domain-expert` role.
   Provide hypothesis, baseline, metrics, seeds, exclusions, and results.
   Require labels for evidence, inference, and unresolved questions.
4. Merge reviewed interpretation into the experiment README and
   `exp/summary.md`; update pipeline state to `analysis`.
5. Report the quantitative result, causal interpretation, limitations, and
   next discriminating experiment.

Generate slides only when requested. Route research talks through
`research-slides` so its default Speculative Decoding reference profile and
rendered QA apply.
