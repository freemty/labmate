---
name: read-paper
description: Use when the user wants a deep methodological reading of one paper, including assumptions, evidence, limitations, or project implications.
disable-model-invocation: true
---

# Read Paper

1. Resolve the paper from a PDF, URL, arXiv ID, title, or local path. Prefer
   host-native PDF/web capabilities; fall back to `pdftotext` for local PDFs and
   Jina Reader for inaccessible pages.
2. Read project context only when it changes the analysis.
3. Follow `../../references/agent-routing.md` for the `domain-expert` role.
   Require the problem, method, training/evaluation contract, evidence,
   assumptions, privileged information, failure modes, and project implications.
4. Return analysis to the main thread. It owns follow-up questions.
5. Archive only on request. Write
   `docs/papers/<short-name>-deep-dive.md`, update the landscape, and report both
   paths.

Do not force a deep-dive merely because a prompt contains an arXiv link. Match
the requested depth.
