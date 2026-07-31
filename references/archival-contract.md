# Archival Contract

Use this reference only while writing durable project documentation.

## Kinds

| Kind | Default location | Required content |
| --- | --- | --- |
| Infrastructure | `docs/knowhow/infrastructure/` | environment, observed failure, verified resolution |
| Toolchain | `docs/knowhow/toolchain/` | tool/version, exact command or config, caveats |
| Debug solution | `docs/knowhow/debug-solutions/` | symptom, root cause, evidence, fix, verification |
| Runbook | `docs/knowhow/runbooks/` | prerequisites, ordered actions, verification, rollback |
| Design/spec | `docs/specs/` or `docs/design/` | context, decision, alternatives, trade-offs |
| Guide | `docs/guides/` | audience, prerequisites, steps, troubleshooting |

## Invariants

- Archive verified facts, not unresolved guesses.
- Search for an existing destination before creating a new file.
- Preserve provenance: source URLs, commands, versions, dates, and material
  exclusions.
- Update an instruction-file index only when the index already exists or the
  new document is a durable project entrypoint. Do not turn AGENTS.md or
  CLAUDE.md into a catalog.
- Report the paths changed and the evidence used.
