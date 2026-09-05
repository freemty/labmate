# Archival Contract

Use while writing durable project documentation, not as a trigger to archive.

## Destination and authority

Honor the requested destination and the repository's conventions. The defaults
below are suggestions for projects without a suitable existing document.
A selfOS wiki is a separate evidence store: use its schema and selected workflow
only when wiki storage is requested. Do not initialize a wiki, duplicate every
project record into it, or require an installed wiki skill for ordinary docs.

| Kind | Default location | Useful content |
| --- | --- | --- |
| Infrastructure | `docs/knowhow/infrastructure/` | environment, observed state/failure, resolution status |
| Toolchain | `docs/knowhow/toolchain/` | relevant version, actual command/config, caveats |
| Debug investigation/solution | `docs/knowhow/debug-solutions/` | symptom, candidate/verified cause, attempted fix, verification |
| Runbook | `docs/knowhow/runbooks/` | prerequisites, actions, success checks, rollback where relevant |
| Design/spec | `docs/specs/` or `docs/design/` | context, proposed/accepted decision, alternatives, trade-offs |
| Guide | `docs/guides/` | audience, prerequisites, usage, relevant troubleshooting |

## Evidence distinctions

- **Observed fact:** tie it to the file, output, source passage or inspected
  artifact. Record material versions/dates and limits.
- **User statement:** preserve supplied wording when capture was requested;
  attribute beliefs, questions and preferences to the user, not to external reality.
- **Decision:** distinguish proposed, accepted and implemented. Acceptance does
  not prove implementation or a successful outcome.
- **Analysis/hypothesis:** label it and keep it separate from observations.
  It can be archived when requested, but never promoted to a verified cause.
- **Resolution:** record the actual successful check and its scope. An error
  disappearing from a log, an attempted command or a tool exit alone may not
  establish the requested outcome.

For external sources, retain URL/identity, source and retrieval dates when known,
and page/section/line or media time locators. Say whether evidence is full text,
an excerpt, transcript-only, sampled frames, or an observed continuous interval.
Metadata is not full content; a transcript does not establish visible behavior.
Reuse trustworthy existing artifacts; retrieve only missing evidence needed for
the claim. Never invent a source date, quote, screenshot or test result.

## Consistent writes and completion

Search existing destinations before creating a new file. Preserve raw artifacts
and exact source text; revisions should not silently rewrite provenance.
Update links/indexes that actually exist and matter to discovery. Keep AGENTS.md
and CLAUDE.md compact; do not add catalogs of every session or skill.

Finish authorized related writes coherently. Verify paths, changed links and
applicable schemas; use runtime checks only when the change's risk warrants them.
A documentation request does not authorize executing destructive runbook steps,
changing external state, committing or publishing. Report saved paths, evidence,
what remains unverified, and any incomplete writes without claiming success.
