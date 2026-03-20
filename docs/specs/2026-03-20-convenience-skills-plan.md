# Convenience Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `/visualize`, `/monitor`, `/ask-project` as convenience entry points to viz-frontend, exp-manager, project-advisor agents.

**Architecture:** Three new SKILL.md files, one CLAUDE.md update. No agent changes.

**Tech Stack:** Pure Markdown skills.

**Spec:** `docs/specs/2026-03-20-convenience-skills-design.md`

---

### Task 1: Create `/visualize` skill

**Files:**
- Create: `skills/visualize/SKILL.md`

- [ ] **Step 1: Create directory and write SKILL.md**

```bash
mkdir -p skills/visualize
```

Write `skills/visualize/SKILL.md`:

```markdown
---
name: visualize
description: "Build or update a results dashboard for experiment data. Use when user wants to see experiment results visually."
disable-model-invocation: true
---

# Visualize

Build a Flask + HTML dashboard for experiment results via @viz-frontend.

## Instructions

When this skill is invoked with optional `<argument>`:

### Step 1: Determine target

- If argument is `compare` → comparison mode (cross-experiment)
- If argument is an exp ID (e.g., `exp01a`) → that experiment
- If no argument → read `.pipeline-state.json` for `current_exp`
- If `current_exp` is null and no argument → ask user which experiment

### Step 2: Gather data

For single experiment:
- Read `exp/{exp_id}/results/summary.md` for quantitative results
- Read `exp/{exp_id}/README.md` for experiment context
- Check if `viewer/app.py` already exists (update vs create)

For compare mode:
- Read `exp/summary.md` for cross-experiment overview

### Step 3: Delegate to @viz-frontend

For single experiment:
> Build a results dashboard for experiment {exp_id}.
> Results data: {summary.md content}
> Experiment context: {README.md content}
> Viewer directory: `viewer/`
> If `viewer/app.py` exists, add/update the view for this experiment. Otherwise create from scratch.

For compare mode:
> Build a cross-experiment comparison dashboard.
> Summary data: {exp/summary.md content}
> Viewer directory: `viewer/`

### Step 4: Report

Tell user: "Dashboard ready. Run `python viewer/app.py` and open http://localhost:5001"
```

- [ ] **Step 2: Commit**

```bash
git add skills/visualize/SKILL.md
git commit -m "feat: add /visualize skill — dashboard entry point for viz-frontend"
```

---

### Task 2: Create `/monitor` skill

**Files:**
- Create: `skills/monitor/SKILL.md`

- [ ] **Step 1: Create directory and write SKILL.md**

```bash
mkdir -p skills/monitor
```

Write `skills/monitor/SKILL.md`:

```markdown
---
name: monitor
description: "Check experiment status and diagnose failures via exp-manager. Use when user wants to check on a running experiment."
disable-model-invocation: true
---

# Monitor

One-command experiment status check via @exp-manager.

## Instructions

When this skill is invoked with optional `<exp_id>`:

### Step 1: Determine target experiment

- If argument provided → use as exp_id
- If no argument → read `.pipeline-state.json` for `current_exp`
- If `current_exp` is null and no argument → ask user which experiment

### Step 2: Verify experiment exists

- Check `exp/{exp_id}/` directory exists
- Check `exp/{exp_id}/results/runs.log` exists
- If not → tell user: "Experiment {exp_id} not found. Run `/new-experiment` first."

### Step 3: Delegate to @exp-manager

> Check experiment {exp_id} status.
> Read `exp/{exp_id}/results/runs.log` and `.pipeline-state.json`.
> Diagnose any failures, auto-retry if appropriate, report status.

### Step 4: Suggest continuous monitoring

After the check completes, tell user:

> For continuous monitoring, run: `/loop 5m /monitor {exp_id}`
```

- [ ] **Step 2: Commit**

```bash
git add skills/monitor/SKILL.md
git commit -m "feat: add /monitor skill — experiment status check via exp-manager"
```

---

### Task 3: Create `/ask-project` skill

**Files:**
- Create: `skills/ask-project/SKILL.md`

- [ ] **Step 1: Create directory and write SKILL.md**

```bash
mkdir -p skills/ask-project
```

Write `skills/ask-project/SKILL.md`:

```markdown
---
name: ask-project
description: "Query project history, experiment findings, and architecture via project-advisor. Use when user asks about past experiments, project progress, or research findings."
disable-model-invocation: true
---

# Ask Project

Natural language query interface to @project-advisor.

## Instructions

When this skill is invoked with `<question>`:

### Step 1: Delegate to @project-advisor

> User question: {question}
>
> Answer based on the project's actual data. Read `exp/summary.md`, `docs/papers/landscape.md`, and `.pipeline-state.json` as needed. Cite specific experiments and papers by name.

Note: project-advisor has `skills: project-skill` preloaded and reads project files on its own. Only pass the user's question.
```

- [ ] **Step 2: Commit**

```bash
git add skills/ask-project/SKILL.md
git commit -m "feat: add /ask-project skill — query project history via project-advisor"
```

---

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update 4 locations**

1. **Quick commands table** — after `/survey-literature` row, add:
   ```
   | `/visualize` | Build results dashboard for experiment |
   | `/monitor` | Check experiment status via exp-manager |
   | `/ask-project` | Query project history and findings |
   ```

2. **Plugin architecture table** — change `Skills (9)` to `Skills (12)`

3. **Skills table** — after `survey-literature` row, add:
   ```
   | visualize | Build results dashboard |
   | monitor | Check experiment status |
   | ask-project | Query project history |
   ```

4. **Specs section** — add:
   ```
   - `docs/specs/2026-03-20-convenience-skills-design.md` — /visualize + /monitor + /ask-project design
   ```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add /visualize, /monitor, /ask-project to CLAUDE.md"
```
