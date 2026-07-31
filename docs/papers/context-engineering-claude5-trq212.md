# Context Engineering for Claude 5 Generation Models

- **Author:** Thariq Shihipar, Anthropic
- **Published:** 2026-07-24
- **Source:** https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
- **Status:** Primary source

## Core claims

Anthropic reports removing more than 80% of Claude Code's system prompt for
newer models without a measurable coding-evaluation loss. The durable lesson is
not a universal deletion target; it is to place each constraint in the layer
that can express and verify it best.

| Old pattern | Preferred pattern |
| --- | --- |
| Context-free rules | Model judgment grounded in surrounding code and user intent |
| Prompt examples for mechanical behavior | Typed tool, script, and file interfaces |
| All guidance loaded up front | Progressive disclosure through skills and references |
| Instructions repeated across layers | One authoritative tool or workflow contract |
| Session memory copied into instruction files | Dedicated durable memory/state |
| Simple prose specs | Code, tests, artifacts, and verifier rubrics |

## LabMate implications

- Keep AGENTS.md, CLAUDE.md, SessionStart, and SKILL.md entrypoints small.
- Move deterministic scaffolding and CRUD into scripts with plan/apply/check or
  typed operations.
- Keep domain taste, evidence standards, and safety boundaries in role prompts
  or rich references.
- Load paper, experiment, slide, and archival references only for the workflow
  that needs them.
- Validate simplification per host/model; older models may still need narrower
  guardrails.
