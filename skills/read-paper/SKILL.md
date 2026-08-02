---
name: read-paper
description: >
  Use when the user explicitly requests a deep read of one paper or technical
  report, or invokes read-paper on a literature hub that needs candidate triage.
disable-model-invocation: true
---

# Read Paper

Turn paper-like input into an auditable artifact before analysis. Never treat an
abstract, landing page, or repository index as a paper's full text.

## Routing contract

Read `<plugin-root>/references/agent-routing.md`, resolving `<plugin-root>` by
going up two directories from this file. The main thread owns user Q&A and any
archive writes. Delegated roles return analysis only.

## 1. Acquire and validate

Read [references/paper-acquisition.md](references/paper-acquisition.md). Create
a temporary paper packet plus a page/section-preserving text artifact, then run:

```bash
python3 "{skill_root}/scripts/validate-paper-packet.py" packet.json \
  --mode deep-dive --require-anchor equation:7
```

Use `--mode hub-triage` for a hub; omit `--require-anchor` when none was requested.

Choose the route from the packet, not from the URL suffix:

- `single_paper` + `full_text` → `deep-dive`.
- `single_paper` + partial/`abstract_only` → stop the deep-dive. State the
  coverage limit; offer an explicitly scoped abstract-level reading or request
  the PDF/full text. Do not update the landscape as if the paper was read.
- `literature_hub` + `hub_index` → `hub-triage`. A repository, Awesome list,
  proceedings page, or reading list is not a single paper.

If validation fails, report the failed invariant and repair acquisition before
analysis. Never silently replace an arXiv PDF with its `/abs/` page.
Translate each user-requested equation, figure, table, page, or section into a
repeatable `--require-anchor TYPE:ID`; missing anchors limit or block the answer.

## 2. Gather context by path

Pass only relevant existing paths, such as `project-skill/SKILL.md`,
`docs/papers/landscape.md`, `exp/summary.md`, and a directly related experiment
README/result. Do not inline whole files or preload every experiment.

## 3. Delegate analysis

Use `<plugin-root>/agents/domain-expert.md` through the portable routing
contract. For a paper, request Mode 4; for a hub, request Mode 5 seed-hub
triage. The task must contain:

```text
Paper packet path: {packet_path}
Research context paths:
- {relevant_path_or_none}
User focus: {question_or_none}
Read the artifacts directly. Return analysis to the main thread.
```

Do not paste the fetched paper into the delegation prompt.

## 4. Continue and archive

Present the result with its coverage/provenance and invite follow-up questions.
Answer in the main thread, preserving unresolved questions.
For hub triage, begin with `input_kind=literature_hub` so the boundary is visible.

Only on explicit “save/archive/store/存档/保存”:

1. Freeze packet and exact text under `docs/papers/artifacts/{short-name}/`,
   rewrite only its relative `text_path`, then revalidate the archived packet.
   Copy an accessible source PDF when privacy/licensing permit and record its
   hash; otherwise retain the locator and explain why raw bytes are absent.
2. Write `{short-name}-deep-dive.md` with links/hashes, Evidence Ledger,
   Methodology, assumptions, Bridge Analysis, and Open Questions. A hub instead
   gets `{short-name}-hub-triage.md`; linked papers remain unread.
3. Update the landscape only with artifact-supported claims; report all paths.
