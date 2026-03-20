# Literature Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `/read-paper` (single-paper deep-dive) and `/survey-literature` (systematic literature survey) skills to labmate, powered by two new modes in domain-expert agent.

**Architecture:** Two new SKILL.md files handle input parsing and dispatch; domain-expert.md gains Mode 4 (Paper Deep-Dive) and Mode 5 (Literature Survey). All output goes to `docs/papers/`. No new agents, no external dependencies.

**Tech Stack:** Pure Markdown skills (Claude Code plugin convention). No code files.

**Spec:** `docs/specs/2026-03-20-literature-skills-design.md`

---

### Task 1: Add Mode 4 (Paper Deep-Dive) to domain-expert

**Files:**
- Modify: `agents/domain-expert.md:13` (section header "Four Modes" becomes "Six Modes")
- Modify: `agents/domain-expert.md:119` (insert Mode 4 after Mode 3 ends, before "## Analysis Principles")

- [ ] **Step 1: Update section header**

In `agents/domain-expert.md`, change:
```
## Four Modes of Operation
```
to:
```
## Six Modes of Operation
```

- [ ] **Step 2: Insert Mode 4 before "## Analysis Principles"**

Insert the following block after the end of Mode 3 (after line 118, before `## Analysis Principles`):

```markdown
### Mode 4: Paper Deep-Dive (论文精读)

Triggered by `/read-paper` skill. Receives paper full text + user research context.

#### Output Structure

**1. Methodology Skeleton (方法论骨架)**
- One-sentence problem statement: what is this paper trying to solve?
- Core optimization objective / loss function breakdown
- Key equations explained — not restated, but "what is this doing and why is it designed this way"
- Algorithm flow as pseudocode or numbered step list

**2. Assumptions & Limitations (假设与局限)**
- Each theorem/proposition's preconditions, listed individually
- Mark each as **standard** (commonly assumed in the field) or **restrictive** (strong assumption, may not hold generally)
- Cross-reference with `exp/summary.md`: flag assumptions that may not hold in the user's specific setting
- If no theorems exist, analyze implicit assumptions in the method design

**3. Bridge Analysis (桥接分析)**
- Read `docs/papers/landscape.md`: where does this paper sit in the user's literature map?
- Read `exp/summary.md`: which components or insights from this paper can transfer to current experiments?
- Output concrete "borrowable points" and "differences to be careful about"
- If landscape.md or exp/summary.md don't exist, note the limitation and provide general bridge analysis

**Footer (always append):**
> 可以继续追问任何细节。回复「存档」/「保存」/「save」或「save as {short-name}」保存精读笔记。

#### Archive Sub-flow

When user says "save" / "archive" / "store" / "存档" / "保存" (or "save as {name}"):
1. Determine short-name: use user-provided name, or auto-generate from paper title (lowercase, hyphenated, max 40 chars)
2. Write `docs/papers/{short-name}-deep-dive.md` with full deep-dive content, using this template:

```markdown
# {Paper Title} — Deep Dive

- **Authors:** ...
- **Year:** ...
- **Link:** {URL if available}
- **Tags:** {relevant keywords}
- **Read date:** {today}

## Methodology Skeleton
{from analysis above}

## Assumptions & Limitations
{from analysis above}

## Bridge Analysis
{from analysis above}

## Open Questions
{any unresolved questions from the Q&A session}
```

3. Update `docs/papers/landscape.md` — append entry to best-fitting section (same as Mode 1)
4. Save paper summary to memory directory for cross-session recall
```

- [ ] **Step 3: Verify no broken references**

Read the full modified `agents/domain-expert.md` to confirm:
- Mode numbering is consistent (0, 1, 2, 3, 4). Note: Mode 5 will be added in Task 2.
- "Analysis Principles" section still intact after Mode 4
- No duplicate headers

- [ ] **Step 4: Commit**

```bash
git add agents/domain-expert.md
git commit -m "feat: add Mode 4 (Paper Deep-Dive) to domain-expert"
```

---

### Task 2: Add Mode 5 (Literature Survey) to domain-expert

**Files:**
- Modify: `agents/domain-expert.md` (insert Mode 5 after Mode 4, before "## Analysis Principles")

- [ ] **Step 1: Insert Mode 5 after Mode 4**

Insert the following block after Mode 4, before `## Analysis Principles`:

```markdown
### Mode 5: Literature Survey (文献综述)

Triggered by `/survey-literature` skill. Receives a research question + user research context.

#### Pipeline

**Step 1: Scope (确定搜索轴)**
- Parse the research question into 3-5 search axes (key terms, synonyms, related concepts)
- Example: "attention sink in DiT" → axes: "attention sink", "Diffusion Transformer attention", "token concentration DiT", "attention pattern generative models"

**Step 2: Search (并行搜索)**
Use Mode 0's URL fetching logic (Jina Reader + fallbacks) for each source:
- arXiv search: `curl -s "https://r.jina.ai/https://arxiv.org/search/?query={encoded_query}&searchtype=all" -H "Accept: text/markdown"`
- Semantic Scholar: `curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query={encoded_query}&limit=10&fields=title,authors,year,venue,abstract,url"`
- General web: WebFetch for blog posts, talks, recent announcements
- Run searches for multiple axes in parallel when possible

**Step 3: Filter (筛选)**
For each result: extract title, authors, year, venue, relevance (high/medium/low).
Discard results with relevance "low" unless total count is under target.

**Step 4: Synthesize (综合)**
- Group papers by sub-topic
- Identify dominant approaches and trade-offs
- Identify gaps in the literature
- Read `docs/papers/landscape.md` + `exp/summary.md` for user context
- Connect findings to user's current research

**Step 5: Output (输出)**
Write to `docs/papers/{topic}-survey.md`:

```markdown
# Literature Survey: {topic}

**Date:** {today}
**Query:** {original question}

## Overview
{2-3 paragraph synthesis of the field}

## Papers by Sub-topic

### {Sub-topic 1}
| Paper | Year | Venue | Key Finding | Relevance |
|-------|------|-------|-------------|-----------|
| [Title](url) | YYYY | Venue | One-line finding | High/Med |

**Summary:** {paragraph synthesizing this sub-topic}

### {Sub-topic 2}
...

## Gaps & Opportunities
- {identified gaps that could be research directions}

## Relevance to Our Research
- {connections to current experiments from exp/summary.md}
- {suggested follow-up experiments or papers to read}

## Sources
- [1] Full citation with URL
- [2] ...
```

**Step 6: Update landscape.md**
Append newly discovered high-relevance papers to the appropriate sections in `docs/papers/landscape.md`.

#### Fallback Strategy

- If a search source fails, try remaining sources — do not abort
- If initial searches return few results, try alternative search axes from Step 1 (synonyms, broader terms)
- If arXiv/Semantic Scholar are both unavailable, fall back to general web search only
- If fewer than 8 papers found after exhausting axes, output what was found with a "Coverage Limitation" note at the top of the survey
- **Never fabricate papers** to meet the target count

#### Quality Standards

- Target 8+ papers per survey (soft target, not hard requirement)
- Each paper must have a verifiable URL
- Clearly mark source type: "peer-reviewed" vs "preprint" vs "blog/talk"
- Separate "found via search" from "inferred from citations in other papers"
```

- [ ] **Step 2: Verify structure**

Read the full `agents/domain-expert.md` to confirm:
- All 6 modes (0-5) are present and properly numbered
- "Analysis Principles" section follows after Mode 5
- No broken markdown nesting

- [ ] **Step 3: Commit**

```bash
git add agents/domain-expert.md
git commit -m "feat: add Mode 5 (Literature Survey) to domain-expert"
```

---

### Task 3: Create `/read-paper` skill

**Files:**
- Create: `skills/read-paper/SKILL.md`

- [ ] **Step 1: Create skill directory**

```bash
mkdir -p skills/read-paper
```

- [ ] **Step 2: Write SKILL.md**

Create `skills/read-paper/SKILL.md` with the following content:

```markdown
---
name: read-paper
description: "Deep-dive a single paper — methodology, assumptions, bridge to your research. Use when user wants to deeply understand a specific paper."
disable-model-invocation: true
---

# Read Paper

Deep-dive a single paper with interactive Q&A. Outputs a structured analysis, then lets the user ask follow-up questions.

## Instructions

When this skill is invoked with `<input>`:

### Step 1: Parse input and fetch paper content

Determine input type and fetch accordingly:

| Input type | Detection | Action |
|-----------|-----------|--------|
| Local PDF | `<input>` ends with `.pdf` and is a file path | Use Read tool. If PDF exceeds 20 pages, read pages 1-20 first, then ask user which sections to focus on. |
| arXiv PDF URL | `<input>` matches `arxiv.org/pdf/` | Convert to abstract URL (replace `/pdf/` with `/abs/`, remove `.pdf` suffix), then fetch with Jina Reader: `curl -s "https://r.jina.ai/{abstract_url}" -H "Accept: text/markdown"` |
| arXiv URL | `<input>` matches `arxiv.org` (non-PDF) | Fetch with Jina Reader: `curl -s "https://r.jina.ai/{url}" -H "Accept: text/markdown"` |
| Other URL | `<input>` starts with `http://` or `https://` | Try WebFetch first. If it fails or returns insufficient content, fall back to Jina Reader: `curl -s "https://r.jina.ai/{url}" -H "Accept: text/markdown"` |
| Pasted text | None of the above | Use `<input>` directly as paper content |

If fetching fails entirely, tell the user and suggest an alternative input method.

### Step 2: Gather research context

Read the following files if they exist (skip silently if not found):
- `docs/papers/landscape.md` — user's literature map
- `exp/summary.md` — user's experiment history

### Step 3: Delegate to @domain-expert

Invoke `@domain-expert` with this prompt:

> **Mode 4: Paper Deep-Dive**
>
> Paper content:
> {fetched paper content}
>
> Research context:
> - Literature landscape: {landscape.md content or "not available"}
> - Experiment history: {exp/summary.md content or "not available"}
>
> Provide your structured deep-dive analysis (Methodology Skeleton, Assumptions & Limitations, Bridge Analysis), then enter interactive Q&A mode.

The user will then interact directly with domain-expert for follow-up questions. When the user says "save" / "archive" / "store" / "存档" / "保存" (with optional "as {name}"), domain-expert handles archival via its Mode 4 archive sub-flow.
```

- [ ] **Step 3: Verify skill file matches convention**

Compare frontmatter with existing skills (`analyze-experiment`, `new-experiment`). Confirm:
- `name` field present
- `description` field present
- `disable-model-invocation: true` present (matches existing skill convention)
- Markdown structure follows `# Title` → `## Instructions` pattern

- [ ] **Step 4: Commit**

```bash
git add skills/read-paper/SKILL.md
git commit -m "feat: add /read-paper skill — single-paper deep-dive"
```

---

### Task 4: Create `/survey-literature` skill

**Files:**
- Create: `skills/survey-literature/SKILL.md`

- [ ] **Step 1: Create skill directory**

```bash
mkdir -p skills/survey-literature
```

- [ ] **Step 2: Write SKILL.md**

Create `skills/survey-literature/SKILL.md` with the following content:

```markdown
---
name: survey-literature
description: "Systematic literature survey — searches arXiv, Semantic Scholar, and web for a research topic, outputs structured survey to docs/papers/."
disable-model-invocation: true
---

# Survey Literature

Systematically search and synthesize relevant literature for a research question. Outputs a structured survey document.

## Instructions

When this skill is invoked with `<topic>`:

### Step 1: Gather research context

Read the following files if they exist (skip silently if not found):
- `docs/papers/landscape.md` — user's existing literature map
- `exp/summary.md` — user's experiment history

### Step 2: Delegate to @domain-expert

Invoke `@domain-expert` with this prompt:

> **Mode 5: Literature Survey**
>
> Research question: {topic}
>
> Research context:
> - Literature landscape: {landscape.md content or "not available"}
> - Experiment history: {exp/summary.md content or "not available"}
>
> Execute your full survey pipeline: Scope → Search → Filter → Synthesize → Output → Update landscape.md.
> Write the survey to `docs/papers/{slugified-topic}-survey.md`.

### Step 3: Report results

After domain-expert completes, tell the user:
- Path to the generated survey file
- Number of papers found
- Any coverage limitations encountered
- Suggest: "Use `/read-paper` to deep-dive any paper from this survey."
```

- [ ] **Step 3: Verify skill file matches convention**

Same checks as Task 3: frontmatter fields, markdown structure.

- [ ] **Step 4: Commit**

```bash
git add skills/survey-literature/SKILL.md
git commit -m "feat: add /survey-literature skill — systematic literature survey"
```

---

### Task 5: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md:6-13` (Quick commands table)
- Modify: `CLAUDE.md:19` (Plugin architecture counts)
- Modify: `CLAUDE.md:38-45` (Skills table)

- [ ] **Step 1: Add to Quick commands table**

In `CLAUDE.md`, after the `/update-project-skill` row in the Quick commands table, add:

```
| `/read-paper` | Deep-dive a single paper |
| `/survey-literature` | Systematic literature survey |
```

- [ ] **Step 2: Update plugin architecture counts**

Change:
```
| Skills (7) | skills/ | Yes (plugin.json) |
```
to:
```
| Skills (9) | skills/ | Yes (plugin.json) |
```

- [ ] **Step 3: Add to Skills table**

After the `commit-changelog` row in the Skills table, add:

```
| read-paper | Deep-dive a single paper with Q&A |
| survey-literature | Systematic literature survey |
```

- [ ] **Step 4: Add spec reference**

At the bottom of the `## Specs` section, add:

```
- `docs/specs/2026-03-20-literature-skills-design.md` — /read-paper + /survey-literature design
```

- [ ] **Step 5: Verify CLAUDE.md**

Read the full `CLAUDE.md` and confirm all tables are properly aligned and counts are correct.

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add /read-paper and /survey-literature to CLAUDE.md"
```

---

### Task 6: Manual smoke test

**Setup:**
```bash
cd /tmp && mkdir test-lit-skills && cd test-lit-skills && git init
```

- [ ] **Step 1: Run /init-project**

Run `/init-project` in the test directory to create the project skeleton (docs/papers/, exp/summary.md, etc.).

- [ ] **Step 2: Test /read-paper with arXiv URL**

Run:
```
/read-paper https://arxiv.org/abs/2401.04088
```

Verify:
- Paper content is fetched via Jina Reader
- domain-expert outputs 3-section analysis (Methodology Skeleton, Assumptions & Limitations, Bridge Analysis)
- Footer prompt appears
- Respond "save as test-paper" and verify `docs/papers/test-paper-deep-dive.md` is created
- Verify `docs/papers/landscape.md` is updated

- [ ] **Step 3: Test /read-paper with pasted text**

Run `/read-paper` followed by a pasted abstract. Verify it enters deep-dive mode without fetching.

- [ ] **Step 4: Test /survey-literature**

Run:
```
/survey-literature attention mechanisms in vision transformers
```

Verify:
- domain-expert executes search pipeline
- Survey file created in `docs/papers/`
- landscape.md updated with new entries
- Coverage summary printed

- [ ] **Step 5: Clean up test directory**

```bash
rm -rf /tmp/test-lit-skills
```

---

### Task 7: Final commit

- [ ] **Step 1: Verify all changes**

```bash
git diff --stat main...HEAD
```

Expected changed/new files:
- `agents/domain-expert.md` (modified — Modes 4+5 added)
- `skills/read-paper/SKILL.md` (new)
- `skills/survey-literature/SKILL.md` (new)
- `CLAUDE.md` (modified — tables updated)

- [ ] **Step 2: Verify no untracked files left behind**

```bash
git status
```
