# Literature Skills Design: `/read-paper` + `/survey-literature`

**Date:** 2026-03-20
**Status:** Reviewed
**Context:** labmate growth playbook identifies "paper deep reading" as the #1 feature priority and key differentiator

---

## Architecture Overview

Three-layer literature system, sharing state through `docs/papers/` + `landscape.md`:

| Layer | Skill | Input | Output | Agent |
|-------|-------|-------|--------|-------|
| Depth | `/read-paper` | PDF / arXiv URL / URL / pasted text | Interactive Q&A + archivable deep-dive notes | domain-expert (Mode 4) |
| Breadth | `/survey-literature` | Research question / topic | Literature survey report in `docs/papers/` | domain-expert (Mode 5) |
| Consumption | (existing) | `docs/papers/*` | Experiment analysis, design advice | domain-expert (Modes 0-3) |

Zero coupling between layers. All communication via filesystem (`docs/papers/`).

---

## Skill 1: `/read-paper`

### Purpose

Deep-dive a single paper. Help the user understand methodology, identify assumptions/limitations, and bridge insights to their own research.

### Input Handling

```
/read-paper <input>
```

| Input type | Detection | Processing |
|-----------|-----------|------------|
| Local PDF | Path ends with `.pdf` | Read tool (Claude native PDF support, use `pages` param for >20 pages) |
| arXiv PDF URL | Matches `arxiv.org/pdf/` | Redirect to abstract page, then Jina Reader for HTML version (richer than raw PDF) |
| arXiv URL | Matches `arxiv.org` (non-PDF) | Jina Reader: `curl -s "https://r.jina.ai/{url}" -H "Accept: text/markdown"` |
| Other URL | Starts with `http(s)://` | WebFetch or Jina Reader fallback |
| Pasted text | None of the above | Pass directly as paper content |

After input extraction, the skill:
1. Reads `docs/papers/landscape.md` and `exp/summary.md` for user's research context
2. If PDF exceeds 20 pages, use Read tool's `pages` parameter to read in chunks (e.g., pages 1-20 first), or prompt user to specify sections of interest
3. Invokes domain-expert in Mode 4: Paper Deep-Dive
3. Passes paper content + research context

### domain-expert Mode 4: Paper Deep-Dive

**Structured summary output (3 sections):**

**1. Methodology Skeleton**
- One-sentence problem statement
- Core optimization objective / loss function breakdown
- Key equations explained: not restated, but "what is this doing and why"
- Algorithm flow as pseudocode or step list

**2. Assumptions & Limitations**
- Each theorem/proposition's preconditions, listed individually
- Marked as "standard" (everyone assumes this) or "restrictive" (this is a strong assumption)
- Flagged when user's setting (from `exp/summary.md`) may violate an assumption

**3. Bridge Analysis**
- Position in user's literature landscape (from `landscape.md`)
- Specific components/insights transferable to user's current experiments
- "Borrowable points" vs "careful about these differences"

**Footer (always):**
> Continue asking about any details. Reply "save" or "save as {short-name}" to archive deep-dive notes.

### Archive Flow

When user says "save" / "archive" / "store" / equivalent:
1. If user provided a short-name (e.g., "save as rope-sink"), use it; otherwise auto-generate from paper title
2. Write `docs/papers/{short-name}-deep-dive.md` with the full deep-dive content (richer than standard Mode 1 archival)
3. Update `landscape.md` via existing Mode 1 flow
4. domain-expert saves summary to its own memory directory for cross-session recall (consistent with Mode 1 behavior)

---

## Skill 2: `/survey-literature`

### Purpose

Given a research question or topic, systematically search and synthesize relevant literature. Output a structured survey directly into `docs/papers/`.

### Input

```
/survey-literature <research question or topic>
```

Examples:
- `/survey-literature attention sink mechanisms in Diffusion Transformers`
- `/survey-literature alternatives to KV-cache compression for long-context LLMs`

### Pipeline

1. **Scope** - Parse the research question, identify 3-5 search axes (key terms, synonyms, related concepts)
2. **Search** - Parallel web searches across:
   - arXiv (via Jina Reader on arxiv search URL)
   - Semantic Scholar API (if available via Bash curl)
   - General web search for blog posts, talks, recent results
3. **Filter** - For each result: title, authors, year, venue, relevance score (high/medium/low)
4. **Synthesize** - Group papers by sub-topic, identify:
   - Dominant approaches and their trade-offs
   - Gaps in the literature
   - How findings relate to user's research (read `landscape.md` + `exp/summary.md`)
5. **Output** - Write to `docs/papers/{topic}-survey.md`:
   ```markdown
   # Literature Survey: {topic}

   **Date:** {date}
   **Query:** {original question}

   ## Overview
   {2-3 paragraph synthesis}

   ## Papers by Sub-topic

   ### {Sub-topic 1}
   | Paper | Year | Venue | Key Finding | Relevance |
   |-------|------|-------|-------------|-----------|
   | ... | ... | ... | ... | High/Med/Low |

   **Summary:** ...

   ### {Sub-topic 2}
   ...

   ## Gaps & Opportunities
   - ...

   ## Relevance to Our Research
   - Connections to current experiments
   - Suggested follow-ups

   ## Sources
   - [1] ... (with URLs)
   ```
6. **Update landscape.md** - Append newly discovered papers to the appropriate sections

### Fallback Strategy

When external searches fail or return insufficient results:
1. Try alternative search axes from Step 1
2. Fall back to general web search if arXiv/Semantic Scholar are unavailable
3. If fewer than target papers found, output what was found with an explicit "coverage limitation" note
4. Never fabricate papers to meet the target

### Quality Standards

- Target 8+ papers per survey; if fewer found, explicitly note the search coverage limitation
- Each paper must have a verifiable URL
- Clearly separate "found via search" vs "inferred from citations"
- Flag when a claim comes from a blog/tweet vs a peer-reviewed venue

### Agent

domain-expert Mode 5: Literature Survey. Reuses Mode 0's URL fetching + Jina fallback logic for individual paper retrieval. Tools: WebFetch, Bash (for curl), Read, Write, Edit, Grep, Glob.

---

## domain-expert Changes

### New Modes

Add to `agents/domain-expert.md`:

**Mode 4: Paper Deep-Dive** (triggered by `/read-paper` skill)
- Receives: paper full text + user research context
- Outputs: 3-section structured summary + interactive Q&A
- Archive on user request

**Mode 5: Literature Survey** (triggered by `/survey-literature` skill)
- Receives: research question + user research context
- Executes: search → filter → synthesize pipeline (reuses Mode 0's URL fetching logic)
- Outputs: survey document to `docs/papers/`

### No changes to existing Modes 0-3

Mode 0 (URL fetch), Mode 1 (archival), Mode 2 (experiment analysis), Mode 3 (design advisor) remain unchanged.

---

## File System Contract

All three layers write to the same locations:

```
docs/papers/
  landscape.md              # Living literature map (all modes update this)
  {short-name}.md           # Standard paper notes (Mode 1)
  {short-name}-deep-dive.md # Deep-dive notes (Mode 4 / /read-paper)
  {topic}-survey.md         # Literature surveys (Mode 5 / /survey-literature)
```

domain-expert reads all `docs/papers/*.md` files regardless of origin.

---

## Implementation Scope

### New files to create
- `skills/read-paper/SKILL.md` - Input handling + Mode 4 dispatch
- `skills/survey-literature/SKILL.md` - Topic parsing + Mode 5 dispatch

Both skills need frontmatter fields consistent with existing skills:
```yaml
---
name: read-paper
description: "Deep-dive a single paper — methodology, assumptions, bridge to your research"
user-invocable: true
---
```

### Files to modify
- `agents/domain-expert.md` - Add Mode 4 and Mode 5
- `CLAUDE.md` - Add to quick commands table:
  ```
  | `/read-paper` | Deep-dive a single paper |
  | `/survey-literature` | Systematic literature survey |
  ```

### No changes needed
- `plugin.json` - Skills are auto-discovered via `"./skills/"` directory convention
- Existing Modes 0-3 — unchanged

### Not in scope
- No new agents
- No external dependencies
- No hooks
