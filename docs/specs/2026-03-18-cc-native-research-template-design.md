# cc-native-research-template Design Spec

**Date:** 2026-03-18
**Status:** Approved
**Author:** sum_young + Claude Opus 4.6

## Problem

Three high-intensity research projects (fars-reviewer, fars-autotrain/PostTrainBench, hle-solver) share highly repetitive structure and workflows: experiment folder conventions, prompt versioning, domain paper management, result analysis pipelines, monitoring loops, and CC infrastructure (skills, agents, hooks). Each project reinvents these patterns from scratch, and project-specific skills/agents are stored globally in `~/.claude/skills/` when they should be repo-local.

## Solution

A GitHub template repo (`cc-native-research-template`) that provides:
1. **Standardized directory structure** for CC-native research projects
2. **Meta-agents** that automatically generate and maintain repo-local skills/agents
3. **Hook-driven workflow enforcement** with a "remind, don't block" philosophy
4. **Experiment lifecycle skills** from scaffold to analysis to archival
5. **Six purpose-built agents** with least-privilege boundaries

The template produces infrastructure, not content. Content is the project's responsibility.

## Architecture Decision: Pure Convention Template (Option B)

**Chosen:** Single GitHub template repo. `Use this template` creates a new project repo. All files are project-owned from day one.

**Rejected alternatives (archived in docs/archive/alternative-approaches.md):**
- **Option A (Scaffold + Submodule):** `init.sh` generator + shared submodule. Clean separation but two repos to maintain, and structural drift over time.
- **Option C (Meta-Agent Package):** npm/pip installable plugin. Best update story, but requires packaging infrastructure — overkill when the primary user is a small research team.

**Rationale for B:**
- Tutorial repo needs a concrete, self-contained submodule to showcase
- Zero dependency management overhead
- Researchers can fork and customize freely
- Template updates via `git remote add template <url> && git fetch template` cherry-pick
- All CC-native infrastructure lives in one place

---

## 1. Project Structure

```
cc-native-research-template/
├── CLAUDE.md                        # Thin route hub (< 80 lines)
├── CHANGELOG.md                     # Project-level changelog
├── bootstrap.sh                     # First-run personalization
├── pyproject.toml                   # Python dependencies (Flask, matplotlib, etc.)
├── .gitignore
│
├── .claude/                         # CC-Native Infrastructure
│   ├── settings.local.json          # Permission allowlists (see below)
│   ├── agents/                      # Agent definitions (6 agents)
│   │   ├── project-advisor.md
│   │   ├── cc-advisor.md
│   │   ├── domain-expert.md
│   │   ├── exp-manager.md
│   │   ├── slides-maker.md
│   │   ├── viz-frontend.md
│   │   └── CHANGELOG.md
│   ├── skills/                      # Repo-local skills
│   │   ├── project-skill/
│   │   │   ├── SKILL.md             # Auto-maintained project knowledge
│   │   │   └── CHANGELOG.md
│   │   ├── update-project-skill/
│   │   │   └── SKILL.md
│   │   ├── new-experiment/
│   │   │   └── SKILL.md
│   │   └── analyze-experiment/
│   │       └── SKILL.md
│   └── hooks/                       # Hook scripts
│       ├── pre-compact-remind.sh
│       ├── stop-check-workflow.sh
│       └── post-commit-changelog.sh
│
├── docs/
│   ├── papers/                      # Domain papers (PDF + notes)
│   ├── specs/                       # Design specs
│   ├── plans/                       # Implementation plans
│   ├── weekly/                      # Weekly progress
│   └── archive/                     # Discarded approaches
│       └── alternative-approaches.md
│
├── exp/                             # Experiments root
│   ├── lib/                         # Shared analysis utilities
│   │   ├── analyze_common.py
│   │   └── plot_utils.py
│   ├── exp00a/                      # Example experiment (template)
│   │   ├── README.md
│   │   ├── config.yaml
│   │   ├── run.py
│   │   ├── analyze.py
│   │   └── results/
│   │       ├── runs.log             # Append-only job tracking
│   │       └── summary.md
│   └── summary.md                   # Cross-experiment flight recorder
│
├── prompts/                         # Versioned prompt templates
│   ├── {component}/
│   │   ├── _v00.md
│   │   └── CHANGELOG.md
│   └── __init__.py                  # load_prompt(name, version) helper
│
├── scripts/
│   ├── launch_exp.py                # Experiment orchestrator
│   ├── monitor_exp.sh               # Status monitoring (for /loop)
│   └── download_results.sh          # Remote result fetching
│
├── viewer/                          # Analysis frontend skeleton
│   ├── app.py                       # Flask server
│   └── static/
│       └── index.html
│
├── slides/                          # Generated analysis slides
│   └── .gitkeep
│
└── .pipeline-state.json             # Workflow state machine
```

### Key structural decisions:
- `.claude/` is the single source for all CC infrastructure — no `~/.claude/skills/` dependency
- `prompts/` is top-level (not inside exp/) because prompts evolve across experiments
- `exp/lib/` provides shared analysis utilities; each experiment imports from here
- `viewer/` is a skeleton — domain-specific views built by viz-frontend agent
- `pyproject.toml` assumed at root (Python-based research projects); provides dependency management for viewer/ (Flask), exp/lib/ (matplotlib etc.), and prompts/ helper
- **Language assumption:** This template assumes Python. The `prompts/__init__.py` helper, `exp/lib/`, and `viewer/` all use Python. Non-Python projects would replace these with equivalent tooling.

### `.claude/settings.local.json` content

Bootstrap generates this based on compute environment choice:

```json
{
  "permissions": {
    "allow": [
      "Bash(python3:*)",
      "Bash(uv run:*)",
      "Bash(tail:*)",
      "Bash(grep:*)",
      "Bash(find:*)",
      "Bash(ps:*)",
      "Bash(kill:*)"
    ]
  }
}
```

**Remote GPU variant** adds: `"Bash(ssh {server}:*)"`, `"Bash(rsync:*)"`, `"Bash(scp:*)"`.

Permissions are intentionally minimal — exp-manager needs Bash for log tailing, process inspection, and retry commands. Users add project-specific permissions as needed.

---

## 2. Meta-Agent System (Project Skill Auto-Generation)

The template's core innovation: an agent that automatically generates and maintains the project's own skill file.

### Trigger chain (Option C: mixed — hooks remind, user confirms)

| Trigger | Hook Type | Message |
|---------|-----------|---------|
| Context nearly full | PreCompact | "Project skill is Nh stale. Run /update-project-skill" |
| Session ending | Stop | "Last skill update was N sessions ago. Consider /update-project-skill" |
| User explicit | — | `/update-project-skill` |

### Execution context constraint

`/update-project-skill` is a **skill** (lives in `.claude/skills/`), meaning it is loaded into the main context when the user invokes it. The skill's instructions then direct Claude to use the **Agent tool** with `model: "opus"` to spawn a read-only subagent. This is the standard Claude Code subagent mechanism — the skill text provides the prompt, the Agent tool provides the isolation. No separate agent definition file is needed for this subagent; it is an ad-hoc Agent tool call with a detailed prompt embedded in the skill.

### Generation mechanism

1. Skill instructs Claude to spawn an **Opus subagent** via the Agent tool (read-only, context-protected) that scans:
   - Code structure (key files, modules, entry points)
   - `exp/` (all experiments, status, key findings)
   - `docs/papers/` (domain knowledge inventory)
   - `prompts/` (current versions, evolution history)
   - Previous SKILL.md + CHANGELOG.md
   - Recent git log (changes since last update)

2. Subagent generates updated SKILL.md with standard sections:
   - Project overview & current state
   - Architecture (code structure, data flow)
   - Experiment history table (exp → result → insight)
   - Key pitfalls & lessons learned (append-only)
   - Active prompt versions & trade-offs
   - Quick reference (commands, paths, env vars)

3. Diffs against previous version → appends CHANGELOG.md entry

4. Shows diff to user for approval before writing

5. Prompts: "Also run /commit-changelog? (Y/n)"

### Safety constraints
- Pitfall entries are **append-only** (lessons are permanent)
- Experiment status never downgraded ("Done" stays "Done")
- Diff shown to user before every write
- User-added custom sections preserved (only auto-generated sections updated)

### Bootstrap flow

`bootstrap.sh` asks 4 questions:
1. **Project name** (kebab-case) — SKILL.md name, CLAUDE.md header
2. **One-line description** — CLAUDE.md, SKILL.md overview
3. **Research domain** — seeds domain-expert agent system prompt
4. **Compute environment** — local / remote GPU (SSH) / cloud → configures scripts and exp-manager

Generates: CLAUDE.md, skeleton SKILL.md, personalized agents, hooks, .pipeline-state.json, .gitignore. Creates initial commit.

Bootstrap produces **infrastructure only** — no experiments, no prompts, no viewer customization, no skill content.

**Idempotency:** If `bootstrap.sh` detects an existing `.pipeline-state.json`, it enters **update mode**: prompts for which fields to change (project name, domain, compute env), updates only the affected files, and does NOT overwrite user-modified content (CLAUDE.md custom sections, agent definitions with manual edits). First run creates an initial commit; subsequent runs create an "update bootstrap config" commit.

---

## 3. Hooks & Workflow Enforcement

### Three-layer hook system

**Layer 1 — Context lifecycle (protect knowledge):**
- `PreCompact` → remind `/update-project-skill` if stale. Staleness is computed by comparing `skill_updated_at` (Unix timestamp in `.pipeline-state.json`) against current time. Threshold: >24 hours. The hook script reads the JSON field and runs `$(( ($(date +%s) - skill_updated_at) / 3600 ))` to compute hours elapsed. No session counter needed — time-based staleness is simpler and sufficient.
- `Stop` → remind pending pipeline actions, check CHANGELOG compliance

**Layer 2 — Workflow discipline (enforce CC-native patterns):**
- `PreToolUse` → "big idea" without prior brainstorming → suggest superpowers:brainstorming
- `PreToolUse` → destructive git ops → suggest git worktree
- `PostToolUse` → after skill completion → advance pipeline state
- `PostToolUse` → after analyze-experiment → remind exp/summary.md update

**Layer 3 — Quality assurance (catch common mistakes):**
- `PreToolUse` → slides-guard: block direct /frontend-slides → suggest /analyze-experiment
- `PostToolUse` → write to prompts/ without CHANGELOG → warn
- `Stop` → CHANGELOG audit: prompts/ or skills/ changed without CHANGELOG entry

### Pipeline state machine

```
dev → skill-update → experiment → monitoring → analysis → commit → dev
```

**This is a single-experiment serial model.** Real research often has non-linear transitions:
- `monitoring` → experiment fails → back to `experiment` (retry)
- `analysis` → results wrong → back to `dev` (fix code)
- Multiple experiments may overlap

The pipeline handles this pragmatically:
- **Stage can be set to any value** via `.pipeline-state.json` — hooks suggest but don't enforce linear progression
- **Parallel experiments:** `current_exp` tracks the *primary* experiment. Secondary experiments run without pipeline tracking. When the user switches focus, they update `current_exp` (or `/new-experiment` does it automatically)
- **Backward transitions are allowed:** exp-manager can set stage back to `experiment` on retry; user can manually reset to `dev`

Tracked in `.pipeline-state.json`:
```json
{
  "stage": "dev",
  "current_exp": "exp01a",
  "skill_updated_at": 1773815263,
  "last_commit": "abc123"
}
```

Stop hook reads state and reminds next action per stage. The pipeline is a **guideline, not a constraint** — consistent with the "remind, don't block" principle.

### Design principle: Remind, Don't Block

All hooks **suggest** the right action but never hard-block, except:
- **slides-guard** — serves two purposes: (1) prevents context pollution from loading heavy skill output (~60KB HTML) into main context, and (2) enforces the analysis-first workflow (run analyze.py before generating slides). Both goals are served by blocking direct `/frontend-slides` and suggesting `/analyze-experiment` instead.
- **destructive git ops** — requires confirmation (existing CC default behavior)

---

## 4. Experiment Lifecycle

### Phase 1: Scaffold — `/new-experiment` skill

**Inputs:** parent experiment, variant letter (auto-suggested), one-line motivation, config base

**Generates:**
```
exp/{exp_id}/
├── README.md       # Pre-filled: Motivation, Relation to Previous, Settings, Pitfalls (empty)
├── config.yaml     # From parent or blank template
├── run.py          # Skeleton with --dry-run, --resume RUNID
├── analyze.py      # Skeleton importing exp/lib/analyze_common.py
└── results/
    ├── .gitkeep
    └── runs.log    # Empty, format documented in header comment
```

**Auto-actions:** Updates .pipeline-state.json, appends row to exp/summary.md, reminds about prompt version bump if needed.

### Phase 2: Execute & Monitor

**Execution patterns:**
- Local single: `python exp/exp01a/run.py --config exp/exp01a/config.yaml`
- Local parallel: `python scripts/launch_exp.py --exp exp01a --stagger 10`
- Remote GPU: SSH + nohup, results downloaded via `scripts/download_results.sh`

**runs.log format (append-only):**
```
# {timestamp} {label} {task_id} {result_path}
```
Cleared only at experiment init, never in main(). Safe for multi-job append.

**Monitoring:** `/loop 5m check {exp_id}` invokes exp-manager agent each cycle.

**exp-manager decision table:**

| Signal | Action |
|--------|--------|
| KeyError/Exception | Diagnose source, fix, retry failed jobs only |
| Rate limit / 429 | Observe — auto-retry handles it |
| Only cheap model succeeds | Check eval parser regex coverage first |
| 10min no new output | Check for hang, consider kill + restart |
| All jobs done | Output summary, stop loop, advance pipeline |

**Stagger strategy:** `delay = job_idx * stagger_interval` prevents rate limit bursts and ID collision.

### Phase 3: Analyze — `/analyze-experiment` skill

**Execution context constraint:** This skill MUST run in the main context (user invokes `/analyze-experiment` directly). It cannot be delegated to a subagent, because it spawns its own subagents (Agent tool calls), and subagents cannot spawn further subagents in Claude Code.

1. Run `analyze.py` → generate `results/summary.md`
2. Spawn **domain-expert subagent** via Agent tool (`model: "opus"`, read-only) → reads docs/papers/ + experiment summary → returns domain interpretation (~500 words with paper citations)
3. Merge interpretation into `exp/{id}/README.md` Findings section
4. Update `exp/summary.md` cross-experiment table
5. Spawn **slides-maker subagent** via Agent tool (`model: "sonnet"`, write slides/) → invokes /frontend-slides with consistent style → writes `slides/{exp_id}-analysis.html`
6. Advance pipeline → "analysis" stage

Steps 2 and 5 are sequential (domain interpretation feeds into slides content). Both use ad-hoc Agent tool calls with prompts embedded in the skill — no separate agent definition files needed for these. The `.claude/agents/domain-expert.md` and `.claude/agents/slides-maker.md` files serve as reference documentation and system prompt templates that the skill copies into the Agent tool prompt.

### Phase 4: Archive

`/commit-changelog` commits changes with structured message. Stop hook reminds `/update-project-skill` to persist new knowledge.

### Versioning convention

| Artifact | Versioning | CHANGELOG Location |
|----------|-----------|-------------------|
| Experiments | `exp{NN}{x}` (NN=major, x=variant) | `exp/summary.md` + `exp/*/README.md` |
| Prompts | `_v{NN}.md` files per component | `prompts/{component}/CHANGELOG.md` |
| Project Skill | Single file, incremental updates | `.claude/skills/project-skill/CHANGELOG.md` |
| Agents | Single file per agent | `.claude/agents/CHANGELOG.md` |
| Slides | `slides/{exp_id}-analysis.html` | Tied to experiment |

**Universal rule:** All iterating artifacts MUST have CHANGELOG entries documenting what changed, when, and why.

**CHANGELOG consolidation:** To avoid maintenance overhead, the template uses 3 CHANGELOG tiers (not per-directory):
1. **Project-level** `CHANGELOG.md` — major milestones, experiment completions, architecture changes
2. **Experiment-level** `exp/summary.md` + each `exp/*/README.md` — experiment-specific evolution
3. **Prompt-level** `prompts/{component}/CHANGELOG.md` — prompt version changes with rationale

The `.claude/agents/CHANGELOG.md` and `.claude/skills/project-skill/CHANGELOG.md` exist but are auto-maintained by `/update-project-skill` — no manual upkeep required. The `.claude/skills/CHANGELOG.md` (top-level skills directory) is removed — individual skill changes are tracked in the project CHANGELOG.

---

## 5. Agent Ecosystem

Six agents with clear boundaries. Least privilege + context protection.

### Agent definitions

| Agent | Model | Tools | Invocation | Write Access |
|-------|-------|-------|-----------|-------------|
| **project-advisor** | Opus | Read, Grep, Glob | User query (routed via CLAUDE.md) | None |
| **cc-advisor** | Sonnet | Read, Grep, Glob, Bash (read-only) | User asks workflow Q | None |
| **domain-expert** | Opus | Read, Grep, Glob | Subagent (via /analyze-experiment) | None |
| **slides-maker** | Sonnet | Read, Write, Glob, Grep | Subagent (via /analyze-experiment) | slides/ only |
| **exp-manager** | Sonnet | Read, Bash, Glob | Loop companion | Bash (retry cmds) |
| **viz-frontend** | Sonnet | Read, Write, Bash, Glob | User request (subagent) | viewer/ only |

### Agent roles

**project-advisor** — The project skill's "voice". Dispatched when user asks about project architecture, experiment history, or codebase navigation. CLAUDE.md routes these queries to this agent via description matching (e.g., "Use project-advisor when user asks about project structure, experiment history, or codebase navigation"). Reads `.claude/skills/project-skill/SKILL.md` as primary source.

**cc-advisor** — Claude Code workflow best practice advisor. Repo-local copy customized with project-specific workflow knowledge. Recommends skills, agents, and workflow patterns.

**domain-expert** — Reads papers in `docs/papers/`, provides domain-informed interpretation of experiment results. Spawned by `/analyze-experiment`, never directly. System prompt seeded with research domain from bootstrap.

**slides-maker** — Generates analysis slides from experiment results. Wraps `/frontend-slides` with project style. Guard hook blocks direct invocation. Reads existing `slides/` for style consistency. Main context never sees HTML output.

**exp-manager** — Monitors running experiments via `/loop`. Reads runs.log, error logs, system metrics. Diagnoses failures using decision table (from agent-exp-orchestration patterns). Retries failed jobs. Detects completion and advances pipeline.

**viz-frontend** — Builds/updates the `viewer/` analysis frontend (Flask + single-file HTML). Invoked as subagent when user requests trajectory visualization, result dashboards, or comparison views. Uses `/frontend-design` skill for UI quality.

### Skill vs Agent boundary

**Skills** (`.claude/skills/`) are composite operations invoked by the user in the main context. They orchestrate multi-step workflows: reading files, spawning subagents, writing results, advancing pipeline state. Skills are the "verbs" of the template.

**Agents** (`.claude/agents/`) are role definitions dispatched into independent contexts. They have a focused identity, constrained tools, and return results to the caller. Agents are the "nouns" — specialists that skills delegate to.

| In `.claude/skills/` | Why skill, not agent |
|----------------------|---------------------|
| update-project-skill | Orchestrates: spawn subagent → diff → write → prompt commit |
| new-experiment | Orchestrates: prompt inputs → scaffold files → update summary → advance pipeline |
| analyze-experiment | Orchestrates: run script → spawn domain-expert → merge → spawn slides-maker → advance |

| In `.claude/agents/` | Why agent, not skill |
|---------------------|---------------------|
| project-advisor | Pure knowledge retrieval in isolated context |
| domain-expert | Reads papers and returns interpretation — no orchestration |
| exp-manager | Reactive monitor role, invoked by /loop, not by user skill |

### Design principles
- **4/6 agents are read-only** — knowledge in, recommendations out
- **2 write agents have scoped directories** — slides-maker → slides/, viz-frontend → viewer/
- **No agent touches exp/ results or .claude/ config** — only user (main context) modifies these
- **Subagent pattern for heavy output** — HTML generation in disposable context, main context sees only file path
- **All agents versioned** — `.claude/agents/CHANGELOG.md`

---

## 6. CLAUDE.md Design

### Thin route hub (< 80 lines)

Sections:
1. **Project name + one-line description**
2. **Quick Commands** — run experiment, analyze, start viewer
3. **Project Knowledge** — pointers to project skill, exp/summary.md, docs/papers/
4. **Agents table** — name, role, how to invoke
5. **Skills table** — name, purpose
6. **Workflow** — 3-line summary of the full cycle
7. **Conventions** — exp naming, prompt versioning, CHANGELOG rule, worktree rule
8. **Current State** — active experiment, pipeline stage, last skill update (only mutable section)

### Maintenance
- "Current State" is the only mutable section, updated by skills and hooks
- Everything above is static after bootstrap
- Manual edits only when project fundamentally changes (new agents, new skills)

---

## 7. Tutorial Integration

The template repo is a git submodule of `ai-research-claude-code-best-practice/`. Each tutorial slide topic maps to a template demo:

| Slide Topic | Template Demo |
|-------------|--------------|
| Hook system | `.claude/hooks/` — pipeline state machine, CHANGELOG audit |
| Skills | Live demo `/new-experiment` → scaffold in seconds |
| Subagent delegation | `/analyze-experiment` dispatching domain-expert + slides-maker |
| Loop monitoring | `/loop 5m` with exp-manager checking status |
| Context management | PreCompact → /update-project-skill → /commit-changelog chain |
| Harness engineering | CLAUDE.md route hub + bootstrap.sh personalization |

---

## Appendix: Discarded Approaches

### Option A: Scaffold + Submodule
- `init.sh` generator + shared conventions as git submodule
- Shared infra (meta-agents, hooks, scripts) in submodule, project-specific files generated
- **Rejected:** Two repos to maintain, init script is one-time (structural drift), submodule can't inject into parent's `.claude/`

### Option C: Meta-Agent Package
- npm/pip installable plugin providing meta-agents + hooks
- `npx cc-research-init` scaffolds project + installs plugin
- Seamless updates via package manager
- **Rejected:** Requires packaging infrastructure, overkill for current team size, adds dependency management overhead
