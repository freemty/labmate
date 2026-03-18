# Changelog

## [0.1.0] - 2026-03-18

### Added
- 6 agent definitions with least-privilege boundaries (project-advisor, cc-advisor, domain-expert, exp-manager, slides-maker, viz-frontend)
- 4 repo-local skills (project-skill skeleton, update-project-skill, new-experiment, analyze-experiment)
- 6 hook scripts in 3 layers (pre-compact-remind, stop-check-workflow, post-commit-changelog, slides-guard, brainstorm-remind, worktree-suggest)
- exp/lib/ shared analysis utilities (analyze_common, plot_utils) with 5 tests
- exp/exp00a/ example experiment with full structure (README, config, run.py, analyze.py)
- prompts/ versioned prompt loader with example component and 4 tests
- scripts/ experiment lifecycle (launch_exp.py, monitor_exp.sh, download_results.sh)
- viewer/ Flask analysis frontend skeleton with 2 tests
- bootstrap.sh interactive first-run personalization (4 questions, idempotent)
- CLAUDE.md thin route hub (<80 lines)
- Pipeline state machine with .pipeline-state.json
- Design spec and implementation plan in docs/specs/
