# LabMate

Research harness for AI coding agents: 12 portable skills, five Claude named
agents, shared references/scripts, and four default hook handlers across four lifecycle events.

## Non-obvious boundaries

- Claude Code registers the five named agents from
  `.claude-plugin/plugin.json`. Their Markdown bodies must still work as
  portable role references for Codex fallback.
- Deterministic project mutation belongs in `scripts/`; SKILL.md files remain
  thin discovery and judgment guides.
- Claude explicit-invocation policy lives in skill frontmatter. Codex policy
  lives in `skills/*/agents/openai.yaml`.
- Package and both plugin manifests share one version. A changed plugin must
  receive a new version so installed caches cannot alias different source.

## Research safety

- Do not clean storage, reset environments, or interrupt processes while an
  experiment is active without resolving exact targets and authorization.
- Preserve successful units during recovery and use the experiment's own
  success predicate.
- Treat single-machine smoke tests and mock runs as plumbing evidence only.

## Verification

```bash
bash tests/test-hooks.sh
bash tests/test-platform-compat.sh
bash tests/test-context-contract.sh
bash tests/test-scripts.sh
```

Preserve unrelated worktree changes. Commit this nested repository before its
parent gitlink.
