# cc-native-research-template

> Claude Code research project lifecycle plugin — experiment scaffolding, result analysis, domain expertise, workflow enforcement.

[中文](README.md)

## Installation

```bash
claude plugin install freemty/cc-native-research-template
```

## Quick Start

1. Run `/init-project` in your project
2. Enter project name, description, and domain when prompted
3. Scaffold is created automatically — start researching

## What's Included

### 7 Agents

| Agent | Purpose |
|-------|---------|
| @project-advisor | Research project advisor — experiment history, findings, codebase navigation |
| @cc-advisor | Claude Code best practices |
| @domain-expert | Domain research — read papers, interpret experiment results |
| @exp-manager | Experiment monitoring — diagnose, retry, detect completion |
| @slides-maker | Generate HTML slides |
| @viz-frontend | Build analysis dashboards |
| @template-presenter | Template introduction and onboarding |

### 7 Skills

| Skill | Purpose |
|-------|---------|
| /init-project | One-command project scaffold initialization |
| /new-experiment | Set up a new experiment |
| /analyze-experiment | Analyze after experiment completes |
| /update-project-skill | Update project knowledge base |
| /present-template | Generate template overview slides |
| /weekly-progress | Weekly progress summary |
| /commit-changelog | Commit + CHANGELOG |

### 5 Hooks

- PreCompact — remind to save progress before context compaction
- Stop — check workflow state at session end
- PostToolUse(Bash) — update CHANGELOG after commits
- PreToolUse(Write) — remind to brainstorm before writing files
- PreToolUse(Bash) — suggest using worktree for risky changes

## Workflow

```
/init-project → /new-experiment → run experiments → /analyze-experiment
  → commit findings → /update-project-skill → repeat
```

## Customization

The plugin provides generic defaults. Create a same-named file locally to override:

```bash
# Example: customize domain-expert for your field
mkdir -p .claude/agents
cp your-custom-version .claude/agents/domain-expert.md
# Local project version automatically overrides the plugin version
```

## Uninstall

Remove from settings.json. Project directory structure and local files are unaffected.

## Acknowledgments

- [superpowers](https://github.com/obra/superpowers) — Skills framework design, subagent-driven-development workflow, SessionStart hook pattern
- [frontend-slides](https://github.com/zarazhangrui/frontend-slides) — Slide generation capabilities for the slides-maker agent
- [Agent-Reach](https://github.com/Panniantong/Agent-Reach) — Multi-platform content fetching for the domain-expert agent (Twitter/X, GitHub, YouTube, etc.)

## License

MIT
