---
name: read-paper
description: >
  Deep-dive a single paper — methodology, assumptions, implications. Triggers on
  "read this paper", "读论文", "explain this PDF", "arxiv.org/abs/", paper URLs,
  "what does this paper say", "paper deep-dive".
disable-model-invocation: true
---

# Read Paper

Deep-dive a single paper with interactive Q&A. Outputs a structured analysis, then lets the user ask follow-up questions.

## Agent Routing

Read `<plugin-root>/references/agent-routing.md` before delegating. Resolve
`<plugin-root>` by going up two directories from this `SKILL.md`. The main
thread always owns follow-up questions and archival.

## Instructions

When this skill is invoked with `<input>`:

### Step 1: Parse input and fetch paper content

Determine input type and fetch accordingly:

| Input type | Detection | Action |
|-----------|-----------|--------|
| Local PDF | `<input>` ends with `.pdf` and is a file path | Use the host's native PDF/document capability. If unavailable, run `pdftotext "<input>" -` and read the extracted text. If neither works, ask for pasted text or a URL. |
| arXiv PDF URL | `<input>` matches `arxiv.org/pdf/` | Convert to abstract URL (replace `/pdf/` with `/abs/`, remove `.pdf` suffix), then fetch with Jina Reader: `curl -s "https://r.jina.ai/{abstract_url}" -H "Accept: text/markdown"` |
| arXiv URL | `<input>` matches `arxiv.org` (non-PDF) | Fetch with Jina Reader: `curl -s "https://r.jina.ai/{url}" -H "Accept: text/markdown"` |
| Other URL | `<input>` starts with `http://` or `https://` | Use the host's native web-reading capability first. If unavailable or insufficient, use Jina Reader: `curl -s "https://r.jina.ai/{url}" -H "Accept: text/markdown"` |
| Pasted text | None of the above | Use `<input>` directly as paper content |

If fetching fails entirely, tell the user and suggest an alternative input method.

### Step 2: Gather research context

Read the following files if they exist (skip silently if not found):
- `docs/papers/landscape.md` — user's literature map
- `exp/summary.md` — user's experiment history

### Step 3: Run the `domain-expert` role

Follow the portable routing contract with
`<plugin-root>/agents/domain-expert.md`, using this task:

> **Mode 4: Paper Deep-Dive**
>
> Paper content:
> {fetched paper content}
>
> Research context:
> - Literature landscape: {landscape.md content or "not available"}
> - Experiment history: {exp/summary.md content or "not available"}
>
> Return a structured deep-dive analysis with Methodology Skeleton,
> Assumptions & Limitations, and Bridge Analysis. Return the analysis to the
> main thread; do not take over the user conversation.

### Step 4: Continue Q&A in the main thread

Present the analysis and append:

> 可以继续追问任何细节。回复「存档」/「保存」/「save」或
> 「save as {short-name}」保存精读笔记。

Answer every follow-up in the main thread, using the fetched paper, research
context, and delegated analysis. Track unresolved questions for archival.

### Step 5: Archive on request

When the user says "save", "archive", "store", "存档", or "保存":

1. Use the user-provided short name, or generate a lowercase hyphenated name
   from the paper title with at most 40 characters.
2. Write `docs/papers/{short-name}-deep-dive.md` containing paper metadata,
   Methodology Skeleton, Assumptions & Limitations, Bridge Analysis, and Open
   Questions from the main-thread Q&A.
3. Update `docs/papers/landscape.md`, adding the paper to the best-fitting
   section without duplicating an existing entry.
4. Report both updated paths. Do not claim a separate agent memory was updated;
   durable recall comes from the project files.
