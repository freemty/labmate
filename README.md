# LabMate

Research Harness for Claude Code. Keep your agent grounded in context, not lost in vibe coding.

[中文](README_ZH.md)

## The problem

You start a research project with Claude. Three hours later you're debugging a CUDA kernel and have completely forgotten what hypothesis you were testing.

Meanwhile your agent has no idea what you tried last week, can't read your reference papers, and treats every session like day one.

LabMate fixes both sides. Your agent gets persistent experiment context, domain paper knowledge, and 7 specialized agents that each know their role. You get a research lifecycle that keeps hypotheses, baselines, and findings visible, even when you're deep in implementation.

## Install

```bash
claude plugin install freemty/labmate
```

## Quick start

1. Run `/init-project` in your existing project
2. Answer 4 questions (name, description, domain, compute)
3. Start researching. Your agent now knows the workflow.

See [Tutorial: your first experiment](docs/tutorial.md) for a full walkthrough.

## What's inside

7 agents, each with a specific research role:

- `@domain-expert` reads your papers, interprets results, connects findings to literature
- `@project-advisor` knows your experiment history and guides next steps
- `@exp-manager` monitors running experiments, diagnoses failures, detects completion
- `@slides-maker` turns analysis into presentation-ready HTML slides
- plus `@cc-advisor`, `@viz-frontend`, `@template-presenter`

7 skills as slash commands:

- `/new-experiment` scaffolds with config, README, run script, analysis script
- `/analyze-experiment` does domain interpretation, cross-experiment comparison, slides
- `/update-project-skill` compresses findings into persistent project memory
- plus `/init-project`, `/present-template`, `/weekly-progress`, `/commit-changelog`

6 hooks that run automatically:

- SessionStart detects project state and injects context
- PreCompact reminds to save progress before context compression
- Stop checks workflow state at session end

## Workflow

```
/init-project → /new-experiment → run → /analyze-experiment
  → commit findings → /update-project-skill → repeat
```

Pipeline state lives in `.pipeline-state.json`. Your agent picks up where you left off.

## Customization

Override anything by creating a local copy:

```bash
# Example: customize domain-expert for your field
mkdir -p .claude/agents
# your local version automatically overrides the plugin
```

Agents, skills, and hooks are all overridable. See the [design spec](docs/specs/2026-03-18-inject-template-design.md) for details.

## Roadmap

Next up: Auto Research Agent mode. Let your agent run the full hypothesis-to-analysis loop with minimal supervision.

## Acknowledgments

- [superpowers](https://github.com/obra/superpowers) — skills framework, subagent-driven development, SessionStart hook pattern
- [frontend-slides](https://github.com/zarazhangrui/frontend-slides) — slide generation for the slides-maker agent
- [Agent-Reach](https://github.com/Panniantong/Agent-Reach) — multi-platform content fetching for the domain-expert agent

## License

MIT
