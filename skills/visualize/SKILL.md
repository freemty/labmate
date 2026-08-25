---
name: visualize
description: Use when experiment results or project state need a dashboard, comparison view, or visual explanation. Triggers on "visualize", "可视化", "show results", "dashboard", "compare experiments", "chart my results", "project overview".
disable-model-invocation: true
---

# Visualize

Choose the artifact from the reader's question, not from a fixed framework.

1. Establish the decision or comparison the visual must support.
2. Inspect result schemas and existing artifacts. Define a small data contract.
3. Follow `../../references/agent-routing.md` for the `viz-frontend` role when a
   custom viewer is justified. Otherwise use the host's native visualization.
4. Validate numbers against source files and inspect the rendered result.
5. Report artifact path, source data, validation, and known gaps.

For a research talk, use `research-slides`; for quick status, prefer a small
native table/chart over a new web application.
