# cc-native-research-template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full cc-native-research-template from the approved design spec, turning the current skeleton into a usable GitHub template repo.

**Architecture:** Pure convention template — all CC infrastructure (.claude/agents, skills, hooks) lives repo-local. Six agents with least-privilege boundaries. Three skills orchestrate experiment lifecycle. Hook system enforces "remind, don't block" workflow discipline.

**Tech Stack:** Python 3.10+, Flask, matplotlib, PyYAML, Bash (hooks/bootstrap), Claude Code native (agents/skills/hooks)

**Spec:** `docs/specs/2026-03-18-cc-native-research-template-design.md`

---

## File Map

### Create (new files)

```
.claude/agents/project-advisor.md
.claude/agents/cc-advisor.md
.claude/agents/domain-expert.md
.claude/agents/exp-manager.md
.claude/agents/slides-maker.md
.claude/agents/viz-frontend.md
.claude/agents/CHANGELOG.md
.claude/skills/project-skill/SKILL.md
.claude/skills/project-skill/CHANGELOG.md
.claude/skills/update-project-skill/SKILL.md
.claude/skills/new-experiment/SKILL.md
.claude/skills/analyze-experiment/SKILL.md
.claude/hooks/pre-compact-remind.sh
.claude/hooks/stop-check-workflow.sh
.claude/hooks/post-commit-changelog.sh
.claude/hooks/slides-guard.sh
.claude/hooks/brainstorm-remind.sh
.claude/hooks/worktree-suggest.sh
exp/lib/__init__.py
exp/lib/analyze_common.py
exp/lib/plot_utils.py
exp/exp00a/README.md
exp/exp00a/config.yaml
exp/exp00a/run.py
exp/exp00a/analyze.py
exp/exp00a/results/.gitkeep
exp/exp00a/results/runs.log
exp/exp00a/results/summary.md
exp/summary.md
prompts/__init__.py
prompts/example/_v00.md
prompts/example/CHANGELOG.md
scripts/launch_exp.py
scripts/monitor_exp.sh
scripts/download_results.sh
viewer/app.py
viewer/static/index.html
bootstrap.sh
```

### Modify (existing files)

```
CLAUDE.md                  — replace all {PLACEHOLDER} with template defaults
.claude/settings.local.json — add hook configurations
.pipeline-state.json       — no change needed (already correct skeleton)
CHANGELOG.md               — update with implementation milestone
.gitignore                 — add exp/exp00a/results/* exception for template
```

---

## Phase 1: Agent Definitions (6 agents + CHANGELOG)

### Task 1: Create 6 agent definition files

**Files:**
- Create: `.claude/agents/project-advisor.md`
- Create: `.claude/agents/cc-advisor.md`
- Create: `.claude/agents/domain-expert.md`
- Create: `.claude/agents/exp-manager.md`
- Create: `.claude/agents/slides-maker.md`
- Create: `.claude/agents/viz-frontend.md`
- Create: `.claude/agents/CHANGELOG.md`

Each agent .md file uses Claude Code agent frontmatter format:

```yaml
---
model: opus|sonnet|haiku
description: One-line description for CLAUDE.md routing
tools:
  - Read
  - Grep
  - Glob
---
```

Followed by a system prompt body.

- [ ] **Step 1: Create project-advisor.md**

Model: opus. Tools: Read, Grep, Glob. Read-only.
System prompt: reads `.claude/skills/project-skill/SKILL.md` as primary knowledge source. Answers questions about project architecture, experiment history, codebase navigation. Tone: concise, cite specific file paths and experiment IDs.

- [ ] **Step 2: Create cc-advisor.md**

Model: sonnet. Tools: Read, Grep, Glob, Bash(read-only). Read-only.
System prompt: CC workflow best practices advisor. Knows about superpowers skills, hook system, agent patterns. Recommends workflow improvements. References `.claude/` structure.

- [ ] **Step 3: Create domain-expert.md**

Model: opus. Tools: Read, Grep, Glob. Read-only.
System prompt: Reads `docs/papers/` for domain knowledge. Provides domain-informed interpretation of experiment results. Placeholder `general machine learning` for bootstrap to fill. Returns ~500 word interpretation with paper citations.

- [ ] **Step 4: Create exp-manager.md**

Model: sonnet. Tools: Read, Bash, Glob. Write: Bash (retry commands).
System prompt: Monitors running experiments. Reads `runs.log`, error logs, system metrics. Decision table from spec (KeyError → diagnose+fix+retry, rate limit → observe, 10min no output → check hang, all done → summarize+advance). Updates `.pipeline-state.json` stage.

- [ ] **Step 5: Create slides-maker.md**

Model: sonnet. Tools: Read, Write, Glob, Grep. Write: `slides/` only.
System prompt: Generates analysis slides from experiment results. Uses `/frontend-slides` skill. Reads existing `slides/` for style consistency. Never writes outside `slides/`.

- [ ] **Step 6: Create viz-frontend.md**

Model: sonnet. Tools: Read, Write, Bash, Glob. Write: `viewer/` only.
System prompt: Builds/updates Flask analysis frontend. Single-file HTML pattern. Trajectory visualization, result dashboards. Uses `/frontend-design` for UI quality. Never writes outside `viewer/`.

- [ ] **Step 7: Create `.claude/agents/CHANGELOG.md`**

Initial entry: `## [0.1.0] - 2026-03-18 / Added: 6 agent definitions`

- [ ] **Step 8: Commit**

```bash
git add .claude/agents/
git commit -m "feat: add 6 agent definitions with least-privilege boundaries"
```

---

## Phase 2: Skill Definitions (4 skills)

### Task 2: Create project-skill skeleton

**Files:**
- Create: `.claude/skills/project-skill/SKILL.md`
- Create: `.claude/skills/project-skill/CHANGELOG.md`

- [ ] **Step 1: Create skeleton SKILL.md**

Template with standard sections (all placeholder content):
- Project overview: `cc-native-research-template — Claude Code native research project template — standardized agents, skills, hooks, and experiment lifecycle`
- Architecture: `(auto-generated after first /update-project-skill)`
- Experiment history table: empty
- Key pitfalls & lessons learned: empty (append-only)
- Active prompt versions: none yet
- Quick reference: template commands from CLAUDE.md

- [ ] **Step 2: Create CHANGELOG.md**

Initial entry: `## [0.1.0] - 2026-03-18 / Added: skeleton project skill`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/project-skill/
git commit -m "feat: add project-skill skeleton"
```

### Task 3: Create update-project-skill skill

**Files:**
- Create: `.claude/skills/update-project-skill/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Skill name in frontmatter: `update-project-skill`. Description: "Regenerate project knowledge skill from current codebase state".

Body instructions:
1. Spawn Opus subagent (via Agent tool, read-only) with detailed prompt to scan: code structure, `exp/`, `docs/papers/`, `prompts/`, previous SKILL.md, recent git log
2. Subagent returns updated SKILL.md content with standard sections
3. Diff against previous version, show to user
4. On approval: write SKILL.md, append CHANGELOG.md entry
5. Update `.pipeline-state.json` `skill_updated_at` to current Unix timestamp
6. Prompt: "Also run /commit-changelog? (Y/n)"

Safety: pitfall entries append-only, experiment status never downgraded, user-added custom sections preserved.

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/update-project-skill/
git commit -m "feat: add update-project-skill skill"
```

### Task 4: Create new-experiment skill

**Files:**
- Create: `.claude/skills/new-experiment/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Skill name: `new-experiment`. Description: "Scaffold a new experiment directory".

Body instructions:
1. Ask for: parent experiment (or none), variant letter (auto-suggest next available), one-line motivation, config base (parent config or blank)
2. Compute `exp_id` = `exp{NN}{x}` based on existing experiments
3. Create directory structure:
   ```
   exp/{exp_id}/README.md      — pre-filled template (Motivation, Relation, Settings, Pitfalls)
   exp/{exp_id}/config.yaml    — copied from parent or blank
   exp/{exp_id}/run.py         — skeleton with --dry-run, --resume flags
   exp/{exp_id}/analyze.py     — skeleton importing exp/lib/analyze_common
   exp/{exp_id}/results/.gitkeep
   exp/{exp_id}/results/runs.log — empty with format header comment
   ```
4. Append row to `exp/summary.md`
5. Update `.pipeline-state.json`: `current_exp` → new exp_id, `stage` → "experiment"
6. Remind about prompt version bump if prompts/ exists

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/new-experiment/
git commit -m "feat: add new-experiment skill"
```

### Task 5: Create analyze-experiment skill

**Files:**
- Create: `.claude/skills/analyze-experiment/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Skill name: `analyze-experiment`. Description: "Analyze results from current experiment".

Body instructions (MUST run in main context — spawns subagents):
1. Read `.pipeline-state.json` to get `current_exp`
2. Run `python exp/{current_exp}/analyze.py` → generates `results/summary.md`
3. Spawn **domain-expert** subagent (Agent tool, model: opus, read-only):
   - Prompt includes: experiment summary, `docs/papers/` inventory, research domain context
   - Returns: ~500 word domain interpretation with paper citations
4. Merge interpretation into `exp/{current_exp}/README.md` Findings section
5. Update `exp/summary.md` cross-experiment table with new row
6. Spawn **slides-maker** subagent (Agent tool, model: sonnet, write slides/):
   - Prompt includes: experiment summary + domain interpretation
   - Invokes /frontend-slides internally
   - Writes: `slides/{exp_id}-analysis.html`
7. Advance `.pipeline-state.json` stage → "analysis"
8. Print summary of what was generated

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/analyze-experiment/
git commit -m "feat: add analyze-experiment skill"
```

---

## Phase 3: Hook System (3 hooks + settings config)

### Task 6: Create hook scripts

**Files:**
- Create: `.claude/hooks/pre-compact-remind.sh`
- Create: `.claude/hooks/stop-check-workflow.sh`
- Create: `.claude/hooks/post-commit-changelog.sh`
- Create: `.claude/hooks/slides-guard.sh`
- Create: `.claude/hooks/brainstorm-remind.sh`
- Create: `.claude/hooks/worktree-suggest.sh`
- Modify: `.claude/settings.local.json`

- [ ] **Step 1: Create pre-compact-remind.sh**

Reads `.pipeline-state.json` `skill_updated_at`. Computes hours elapsed: `$(( ($(date +%s) - skill_updated_at) / 3600 ))`. If >24h, outputs reminder: "Project skill is {N}h stale. Run /update-project-skill before context compacts."

```bash
#!/bin/bash
STATE_FILE=".pipeline-state.json"
if [ ! -f "$STATE_FILE" ]; then exit 0; fi
UPDATED_AT=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('skill_updated_at', 0))")
NOW=$(date +%s)
HOURS=$(( (NOW - UPDATED_AT) / 3600 ))
if [ "$HOURS" -gt 24 ]; then
  echo "Project skill is ${HOURS}h stale. Run /update-project-skill before context compacts."
fi
```

- [ ] **Step 2: Create stop-check-workflow.sh**

Reads `.pipeline-state.json` stage. Reminds next action per stage:
- dev → "Consider /new-experiment to start next experiment"
- experiment → "Experiment in progress. Check exp-manager status"
- monitoring → "Monitor loop active. Wait for completion or check manually"
- analysis → "Analysis done. Run /commit-changelog to persist findings"
- commit → "Committed. Run /update-project-skill to update knowledge base"

Also checks if prompts/ or .claude/skills/ files were modified (via `git diff --name-only HEAD`) without CHANGELOG entry. Includes `skill-update` stage: "Run /update-project-skill to refresh project knowledge".

- [ ] **Step 3: Create post-commit-changelog.sh**

After git commit, checks if CHANGELOG.md was included.

```bash
#!/bin/bash
# Guard: only act if a git commit just happened
CHANGED=$(git diff --name-only HEAD~1 HEAD 2>/dev/null)
if [ -z "$CHANGED" ]; then exit 0; fi

# Check if prompts/ or .claude/skills/ were changed
HAS_PROMPTS=$(echo "$CHANGED" | grep "^prompts/" || true)
HAS_SKILLS=$(echo "$CHANGED" | grep "^\.claude/skills/" || true)
HAS_CHANGELOG=$(echo "$CHANGED" | grep "CHANGELOG" || true)

if [ -n "$HAS_PROMPTS" ] || [ -n "$HAS_SKILLS" ]; then
  if [ -z "$HAS_CHANGELOG" ]; then
    echo "Changed prompts/ or .claude/skills/ without CHANGELOG entry. Consider updating CHANGELOG.md."
  fi
fi
```

- [ ] **Step 4: Create slides-guard.sh (Layer 3 — hard-block)**

PreToolUse hook that blocks direct `/frontend-slides` invocation. Checks if the Skill tool is about to invoke `frontend-slides` without going through `/analyze-experiment`. Outputs: "Direct /frontend-slides is blocked. Use /analyze-experiment instead (it handles slides generation via slides-maker agent)." This is the **only hard-blocking hook** in the template.

- [ ] **Step 5: Create brainstorm-remind.sh (Layer 2)**

PreToolUse hook for Write/Edit tools. Checks if the user is about to create substantial new files (>50 lines) without a prior brainstorming session (checks for `docs/superpowers/specs/` files modified today). If no recent spec found, suggests: "Consider running /brainstorming first for big changes."

- [ ] **Step 6: Create worktree-suggest.sh (Layer 2)**

PreToolUse hook for Bash tool. Detects destructive git operations (`git reset --hard`, `git checkout -- .`, `git clean`) and suggests using `git worktree` instead.

- [ ] **Step 7: Update settings.local.json with hook configurations**

Add hook entries to the existing permissions config:

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
  },
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/pre-compact-remind.sh" }]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/stop-check-workflow.sh" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/post-commit-changelog.sh" }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/slides-guard.sh" }]
      },
      {
        "matcher": "Write",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/brainstorm-remind.sh" }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/worktree-suggest.sh" }]
      }
    ]
  }
}
```

- [ ] **Step 8: Make hook scripts executable**

```bash
chmod +x .claude/hooks/*.sh
```

- [ ] **Step 9: Commit**

```bash
git add .claude/hooks/ .claude/settings.local.json
git commit -m "feat: add 3-layer hook system (6 hooks) with remind-don't-block philosophy"
```

---

## Phase 4: Experiment Infrastructure

### Task 7: Create exp/lib/ shared utilities

**Files:**
- Create: `exp/lib/__init__.py`
- Create: `exp/lib/analyze_common.py`
- Create: `exp/lib/plot_utils.py`
- Test: `tests/test_exp_lib.py`

- [ ] **Step 1: Write failing tests for analyze_common**

```python
# tests/test_exp_lib.py
import pytest
from exp.lib.analyze_common import load_runs_log, compute_summary_stats


def test_load_runs_log_empty():
    """Empty log returns empty list."""
    result = load_runs_log("")
    assert result == []


def test_load_runs_log_parses_entries():
    """Parses well-formed runs.log lines."""
    log_content = "# 2026-03-18T10:00:00 baseline task_001 results/001.json\n# 2026-03-18T10:05:00 baseline task_002 results/002.json"
    result = load_runs_log(log_content)
    assert len(result) == 2
    assert result[0]["label"] == "baseline"
    assert result[0]["task_id"] == "task_001"


def test_load_runs_log_skips_blank_lines():
    """Blank lines and non-entry lines are skipped."""
    log_content = "\n# 2026-03-18T10:00:00 baseline task_001 results/001.json\n\n"
    result = load_runs_log(log_content)
    assert len(result) == 1


def test_compute_summary_stats_empty():
    """Empty entries returns empty stats."""
    result = compute_summary_stats([])
    assert result == {"total": 0, "labels": {}}
```

- [ ] **Step 2: Run tests — verify FAIL**

```bash
python3 -m pytest tests/test_exp_lib.py -v
```
Expected: ModuleNotFoundError

- [ ] **Step 3: Implement exp/lib/__init__.py**

Empty file (makes exp/lib a package).

- [ ] **Step 4: Implement analyze_common.py**

```python
"""Shared analysis utilities for experiment results."""
from __future__ import annotations


def load_runs_log(content: str) -> list[dict]:
    """Parse runs.log content into structured entries.

    Format: # {timestamp} {label} {task_id} {result_path}
    """
    entries = []
    for line in content.strip().splitlines():
        line = line.strip()
        if not line or not line.startswith("#"):
            continue
        parts = line[2:].split()
        if len(parts) < 4:
            continue
        entries.append({
            "timestamp": parts[0],
            "label": parts[1],
            "task_id": parts[2],
            "result_path": parts[3],
        })
    return entries


def compute_summary_stats(entries: list[dict]) -> dict:
    """Compute summary statistics from parsed log entries."""
    if not entries:
        return {"total": 0, "labels": {}}
    labels: dict[str, int] = {}
    for entry in entries:
        label = entry.get("label", "unknown")
        labels[label] = labels.get(label, 0) + 1
    return {"total": len(entries), "labels": labels}
```

- [ ] **Step 5: Implement plot_utils.py**

Minimal skeleton with one helper:

```python
"""Shared plotting utilities for experiment visualization."""
from __future__ import annotations

try:
    import matplotlib.pyplot as plt
except ImportError:
    plt = None


def save_bar_chart(data: dict[str, float], title: str, output_path: str) -> str:
    """Save a simple bar chart. Returns the output path."""
    if plt is None:
        raise ImportError("matplotlib is required for plotting. Install with: pip install matplotlib")
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar(list(data.keys()), list(data.values()))
    ax.set_title(title)
    ax.set_ylabel("Value")
    fig.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)
    return output_path
```

- [ ] **Step 6: Run tests — verify PASS**

```bash
python3 -m pytest tests/test_exp_lib.py -v
```

- [ ] **Step 7: Commit**

```bash
git add exp/lib/ tests/test_exp_lib.py
git commit -m "feat: add exp/lib shared analysis utilities with tests"
```

### Task 8: Create exp/exp00a/ example experiment

**Files:**
- Create: `exp/exp00a/README.md`
- Create: `exp/exp00a/config.yaml`
- Create: `exp/exp00a/run.py`
- Create: `exp/exp00a/analyze.py`
- Create: `exp/exp00a/results/.gitkeep`
- Create: `exp/exp00a/results/runs.log`
- Create: `exp/summary.md`

- [ ] **Step 1: Create exp00a/README.md**

Template README showing the standard structure:
```markdown
# exp00a: Example Experiment

## Motivation
Template example experiment. Replace this with your experiment motivation.

## Relation to Previous
First experiment — no predecessor.

## Settings
See `config.yaml` for configuration.

## Findings
(populated by /analyze-experiment)

## Pitfalls
(append lessons learned here)
```

- [ ] **Step 2: Create exp00a/config.yaml**

```yaml
# Experiment configuration
experiment:
  name: exp00a
  description: "Example experiment template"

# Model/method settings
model:
  name: "{MODEL_NAME}"

# Evaluation settings
eval:
  metrics: ["accuracy"]

# Execution settings
execution:
  num_runs: 1
  stagger_seconds: 0
```

- [ ] **Step 3: Create exp00a/run.py**

Skeleton with `--dry-run`, `--resume`, `--config` flags. Imports from `exp/lib/`. Appends to `results/runs.log`.

- [ ] **Step 4: Create exp00a/analyze.py**

Skeleton that reads `results/runs.log`, calls `analyze_common.load_runs_log()` and `compute_summary_stats()`, writes `results/summary.md`.

- [ ] **Step 5: Create results/.gitkeep, empty runs.log, and placeholder summary.md**

runs.log header:
```
# Format: {timestamp} {label} {task_id} {result_path}
```

results/summary.md placeholder:
```markdown
# exp00a Results Summary
(generated by analyze.py — do not edit manually)
```

- [ ] **Step 6: Create exp/summary.md**

```markdown
# Experiment Summary

| Exp | Description | Status | Key Finding |
|-----|-------------|--------|-------------|
| exp00a | Example experiment template | Template | N/A |
```

- [ ] **Step 7: Commit**

```bash
git add exp/
git commit -m "feat: add experiment infrastructure with exp00a template"
```

---

## Phase 5: Prompts Helper

### Task 9: Create prompts/ directory with loader

**Files:**
- Create: `prompts/__init__.py`
- Test: `tests/test_prompts.py`

- [ ] **Step 1: Write failing test**

```python
# tests/test_prompts.py
import pytest
import tempfile
import os
from prompts import load_prompt


def test_load_prompt_finds_version(tmp_path):
    """Loads specific prompt version."""
    comp_dir = tmp_path / "summarize"
    comp_dir.mkdir()
    (comp_dir / "_v00.md").write_text("Summarize the following: {input}")
    (comp_dir / "_v01.md").write_text("Provide a concise summary: {input}")

    result = load_prompt("summarize", version=1, prompts_dir=str(tmp_path))
    assert "concise summary" in result


def test_load_prompt_latest_version(tmp_path):
    """Without version, loads the latest."""
    comp_dir = tmp_path / "summarize"
    comp_dir.mkdir()
    (comp_dir / "_v00.md").write_text("V0")
    (comp_dir / "_v01.md").write_text("V1")
    (comp_dir / "_v02.md").write_text("V2")

    result = load_prompt("summarize", prompts_dir=str(tmp_path))
    assert result == "V2"


def test_load_prompt_missing_component(tmp_path):
    """Raises FileNotFoundError for missing component."""
    with pytest.raises(FileNotFoundError):
        load_prompt("nonexistent", prompts_dir=str(tmp_path))
```

- [ ] **Step 2: Run tests — verify FAIL**

```bash
python3 -m pytest tests/test_prompts.py -v
```

- [ ] **Step 3: Implement prompts/__init__.py**

```python
"""Versioned prompt template loader.

Convention: prompts/{component}/_v{NN}.md
"""
from __future__ import annotations
import os
import re
from pathlib import Path

_PROMPTS_DIR = Path(__file__).parent


def load_prompt(
    name: str,
    version: int | None = None,
    prompts_dir: str | None = None,
) -> str:
    """Load a prompt template by component name and optional version.

    Args:
        name: Component name (directory under prompts/)
        version: Specific version number. If None, loads latest.
        prompts_dir: Override prompts directory (for testing).

    Returns:
        Prompt template content as string.

    Raises:
        FileNotFoundError: If component or version doesn't exist.
    """
    base = Path(prompts_dir) if prompts_dir else _PROMPTS_DIR
    comp_dir = base / name

    if not comp_dir.is_dir():
        raise FileNotFoundError(f"Prompt component '{name}' not found at {comp_dir}")

    version_files = sorted(
        [f for f in comp_dir.iterdir() if re.match(r"_v\d+\.md$", f.name)],
        key=lambda f: int(re.search(r"_v(\d+)", f.name).group(1)),
    )

    if not version_files:
        raise FileNotFoundError(f"No version files found in {comp_dir}")

    if version is not None:
        target = comp_dir / f"_v{version:02d}.md"
        if not target.exists():
            raise FileNotFoundError(f"Version {version} not found: {target}")
        return target.read_text()

    return version_files[-1].read_text()
```

- [ ] **Step 4: Run tests — verify PASS**

```bash
python3 -m pytest tests/test_prompts.py -v
```

- [ ] **Step 5: Create example prompt component**

```
prompts/example/_v00.md     — "This is an example prompt template. Replace with your own."
prompts/example/CHANGELOG.md — "## [0.1.0] - 2026-03-18 / Added: initial example prompt"
```

This demonstrates the `prompts/{component}/_v{NN}.md + CHANGELOG.md` convention from the spec.

- [ ] **Step 6: Commit**

```bash
git add prompts/ tests/test_prompts.py
git commit -m "feat: add versioned prompt loader with example component and tests"
```

---

## Phase 6: Scripts

### Task 10: Create scripts/

**Files:**
- Create: `scripts/launch_exp.py`
- Create: `scripts/monitor_exp.sh`
- Create: `scripts/download_results.sh`

- [ ] **Step 1: Create launch_exp.py**

Experiment orchestrator. Reads `exp/{exp_id}/config.yaml`, launches `run.py` with stagger delay. Supports `--exp`, `--stagger`, `--dry-run` flags. Uses subprocess for parallel job launch.

- [ ] **Step 2: Create monitor_exp.sh**

Status monitoring script for `/loop` integration. Reads `exp/{exp_id}/results/runs.log`, counts completed/failed jobs, outputs one-line status. Exit code 0 = still running, exit code 1 = all done.

```bash
#!/bin/bash
# Usage: monitor_exp.sh <exp_id>
# Designed for: /loop 5m bash scripts/monitor_exp.sh <exp_id>
EXP_ID="${1:?Usage: monitor_exp.sh <exp_id>}"
LOG_FILE="exp/${EXP_ID}/results/runs.log"
if [ ! -f "$LOG_FILE" ]; then
  echo "No runs.log found for ${EXP_ID}"
  exit 1
fi
TOTAL=$(grep -c "^#" "$LOG_FILE" 2>/dev/null || echo 0)
echo "${EXP_ID}: ${TOTAL} entries in runs.log"
```

- [ ] **Step 3: Create download_results.sh**

Remote result fetching skeleton. Accepts `--server`, `--exp`, `--dest` flags. Uses rsync for transfer.

```bash
#!/bin/bash
# Usage: download_results.sh --server <host> --exp <exp_id>
# Downloads remote experiment results to local exp/{exp_id}/results/
echo "Usage: download_results.sh --server <host> --exp <exp_id>"
echo "Configure for your remote GPU setup."
```

- [ ] **Step 4: Make scripts executable**

```bash
chmod +x scripts/monitor_exp.sh scripts/download_results.sh
```

- [ ] **Step 5: Commit**

```bash
git add scripts/
git commit -m "feat: add experiment scripts (launch, monitor, download)"
```

---

## Phase 7: Viewer Skeleton

### Task 11: Create viewer/

**Files:**
- Create: `viewer/app.py`
- Create: `viewer/static/index.html`

- [ ] **Step 1: Create viewer/app.py**

Minimal Flask server that serves `static/index.html` and provides a `/api/experiments` endpoint returning experiment list from `exp/summary.md`.

```python
"""Analysis viewer — Flask server skeleton.

Run: python viewer/app.py
Customize: viz-frontend agent builds domain-specific views here.
"""
from __future__ import annotations
import json
from pathlib import Path
from flask import Flask, send_from_directory, jsonify

app = Flask(__name__, static_folder="static")
PROJECT_ROOT = Path(__file__).parent.parent


@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.route("/api/experiments")
def list_experiments():
    exp_dir = PROJECT_ROOT / "exp"
    experiments = []
    for d in sorted(exp_dir.iterdir()):
        if d.is_dir() and d.name.startswith("exp"):
            readme = d / "README.md"
            experiments.append({
                "id": d.name,
                "has_readme": readme.exists(),
                "has_results": (d / "results" / "runs.log").exists(),
            })
    return jsonify(experiments)


if __name__ == "__main__":
    app.run(debug=True, port=5001)
```

- [ ] **Step 2: Create viewer/static/index.html**

Minimal HTML shell that fetches `/api/experiments` and displays a table. Clean, no frameworks. Placeholder for viz-frontend agent to customize.

- [ ] **Step 3: Write viewer test**

```python
# tests/test_viewer.py
import pytest
from viewer.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_index_returns_html(client):
    response = client.get("/")
    assert response.status_code == 200


def test_api_experiments_returns_json(client):
    response = client.get("/api/experiments")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
```

- [ ] **Step 4: Run tests — verify PASS**

```bash
python3 -m pytest tests/test_viewer.py -v
```

- [ ] **Step 5: Commit**

```bash
git add viewer/ tests/test_viewer.py
git commit -m "feat: add viewer skeleton (Flask + static HTML) with tests"
```

---

## Phase 8: Bootstrap & Finalization

### Task 12: Create bootstrap.sh

**Files:**
- Create: `bootstrap.sh`

- [ ] **Step 1: Write bootstrap.sh**

Interactive script asking 4 questions:
1. Project name (kebab-case) → replaces `cc-native-research-template` everywhere
2. One-line description → replaces `Claude Code native research project template — standardized agents, skills, hooks, and experiment lifecycle`
3. Research domain → replaces `general machine learning` in domain-expert agent
4. Compute environment (local/remote/cloud) → configures settings.local.json

Uses `sed -i` for replacements across CLAUDE.md, SKILL.md, agent files.

Idempotency: if `.pipeline-state.json` has `last_commit` set, enters update mode.

Creates initial commit on first run.

- [ ] **Step 2: Make executable**

```bash
chmod +x bootstrap.sh
```

- [ ] **Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: add bootstrap.sh for first-run personalization"
```

### Task 13: Finalize CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Read current CLAUDE.md**

Verify current placeholder content.

- [ ] **Step 2: Rewrite CLAUDE.md**

Replace with the final template version (< 80 lines) per spec section 6:
- Project name + description (with `{PLACEHOLDER}` for bootstrap)
- Quick Commands table
- Project Knowledge pointers
- Agents table (6 agents)
- Skills table (3 user-facing skills)
- Workflow summary
- Conventions
- Current State (mutable section)

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: finalize CLAUDE.md as thin route hub"
```

### Task 14: Update CHANGELOG.md and final cleanup

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Update CHANGELOG.md**

Add implementation completion entry under `[0.1.0]`:
- Added: 6 agent definitions, 4 skills, 3 hooks, experiment infrastructure, prompt loader, scripts, viewer skeleton, bootstrap.sh
- Structure: full directory tree per spec

- [ ] **Step 2: Run all tests**

```bash
python3 -m pytest tests/ -v
```
Expected: all pass.

- [ ] **Step 3: Verify bootstrap dry-run**

Quick smoke test: check that all placeholder strings exist in expected files and that `bootstrap.sh` is syntactically valid.

```bash
bash -n bootstrap.sh && echo "Syntax OK"
grep -r "cc-native-research-template" CLAUDE.md .claude/skills/project-skill/SKILL.md
```

- [ ] **Step 4: Final commit**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG with full implementation"
```

---

## Dependency Graph

```
Task 1 (agents) ──────────┐
Task 2 (project-skill) ───┤
Task 3 (update-skill) ────┤
Task 4 (new-experiment) ──┼── all independent, can parallelize
Task 5 (analyze-exp) ─────┤
Task 9 (prompts) ─────────┤
Task 10 (scripts) ────────┤
Task 11 (viewer) ─────────┘
                           │
Task 6 (hooks) ────────────┤ depends on: nothing (runtime uses skills/prompts dirs)
Task 7 (exp/lib) ──────────┤ depends on: nothing (but Task 8 depends on it)
                           │
Task 8 (exp00a) ───────────┤ depends on: Task 7 (imports exp/lib)
                           │
Task 12 (bootstrap) ───────┤ depends on: all files exist (knows what to sed)
Task 13 (CLAUDE.md) ───────┤ depends on: agents + skills defined
Task 14 (final) ───────────┘ depends on: everything above
```

**Parallelizable batch 1:** Tasks 1, 2, 3, 4, 5, 6, 7, 9, 10, 11
**Sequential after batch 1:** Task 8 (needs Task 7)
**Sequential after batch 1:** Tasks 12, 13 (need all structure)
**Final:** Task 14
