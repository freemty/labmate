# Hooks Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 3 transition hooks + 2 periodic reminders to guide users through the research lifecycle automatically.

**Architecture:** New `hook-utils` shared helper, 2 new hook scripts, 3 existing hooks modified, hooks.json updated.

**Tech Stack:** Bash scripts with embedded Python for date logic.

**Spec:** `docs/specs/2026-03-20-hooks-enhancement-design.md`

---

### Task 1: Create hook-utils shared helper

**Files:**
- Create: `hooks/hook-utils`

- [ ] **Step 1: Write hook-utils**

Create `hooks/hook-utils`:

```bash
#!/usr/bin/env bash
# Shared helper functions for LabMate hooks
# Source this file: source "${SCRIPT_DIR}/hook-utils"

should_remind() {
  local key="$1"
  local hours="${2:-24}"
  local state_file=".labmate-hook-state.json"
  if [ ! -f "$state_file" ]; then echo "yes"; return; fi
  local result=$(python3 -c "
import json
from datetime import datetime, timedelta
s = json.load(open('$state_file'))
last = s.get('$key', '2000-01-01T00:00:00')
if datetime.fromisoformat(last) < datetime.now() - timedelta(hours=$hours):
    print('yes')
else:
    print('no')
" 2>/dev/null || echo "yes")
  echo "$result"
}

mark_reminded() {
  local key="$1"
  local state_file=".labmate-hook-state.json"
  python3 -c "
import json
from datetime import datetime
f = '$state_file'
try:
    s = json.load(open(f))
except:
    s = {}
s['$key'] = datetime.now().isoformat()
json.dump(s, open(f, 'w'), indent=2)
" 2>/dev/null
}
```

- [ ] **Step 2: Commit**

```bash
git add hooks/hook-utils
git commit -m "feat: add hooks/hook-utils — shared should_remind/mark_reminded helpers"
```

---

### Task 2: Update session-start — add periodic reminders

**Files:**
- Modify: `hooks/session-start`

- [ ] **Step 1: Read current file**

Read `hooks/session-start` to understand structure.

- [ ] **Step 2: Update workflow hint**

In the `else` branch (project initialized), update the context string to reflect current skills:

Change the workflow line to:
```
Workflow: /new-experiment -> /monitor -> /analyze-experiment -> /visualize -> /commit-changelog
```

Change the Skills line to:
```
Skills: /read-paper /survey-literature /new-experiment /analyze-experiment /visualize /monitor /commit-changelog /update-project-skill
```

Change the Agents line to:
```
Agents: @domain-expert @project-advisor @exp-manager @slides-maker @viz-frontend
```

- [ ] **Step 3: Add periodic reminders after context injection**

After the `fi` that closes the project state check (before the `escaped=` line), add:

```bash
# --- Periodic reminders (frequency-capped) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/hook-utils"

reminders=""

# Hook 4: Read-paper reminder (7-day cap)
if [ "$(should_remind 'read_paper' 168)" = "yes" ]; then
  # Check if any paper was read in last 7 days
  latest_paper=""
  if [ -d "docs/papers" ]; then
    latest_paper=$(find docs/papers -name "*.md" -not -name "landscape.md" -newer "$(date -v-7d +%Y%m%d 2>/dev/null || date -d '7 days ago' +%Y%m%d)" 2>/dev/null | head -1)
  fi
  if [ -z "$latest_paper" ]; then
    days_since=$(python3 -c "
import os, glob
from datetime import datetime
papers = glob.glob('docs/papers/*.md')
papers = [p for p in papers if 'landscape' not in p]
if not papers:
    print('never')
else:
    latest = max(os.path.getmtime(p) for p in papers)
    days = (datetime.now().timestamp() - latest) / 86400
    print(int(days))
" 2>/dev/null || echo "never")
    if [ "$days_since" = "never" ]; then
      reminders="${reminders}No papers in docs/papers/ yet. Try /read-paper to start building your literature base.\n"
    else
      reminders="${reminders}It's been ${days_since} days since your last paper note. Try /read-paper to stay current.\n"
    fi
    mark_reminded "read_paper"
  fi
fi

# Hook 5: Weekly progress reminder (Friday+, 24h cap)
DOW=$(date +%u)  # 1=Mon, 7=Sun
if [ "$DOW" -ge 5 ]; then
  WEEK=$(date +%Y-W%V)
  WEEKLY_FILE="docs/weekly/${WEEK}.md"
  if [ ! -f "$WEEKLY_FILE" ] && [ "$(should_remind 'weekly' 24)" = "yes" ]; then
    reminders="${reminders}No weekly progress for ${WEEK}. Run /commit-changelog --weekly to summarize this week.\n"
    mark_reminded "weekly"
  fi
fi

# Append reminders to context if any
if [ -n "$reminders" ]; then
  context="${context}\n---\nReminders:\n${reminders}"
fi
```

- [ ] **Step 3: Verify**

Read the full file and confirm:
- SCRIPT_DIR and source hook-utils are before the reminders block
- The reminders are appended to `$context` before `escaped=`
- No syntax errors in bash

- [ ] **Step 4: Commit**

```bash
git add hooks/session-start
git commit -m "feat: add periodic reminders to session-start (read-paper 7d, weekly Fri)"
```

---

### Task 3: Update post-analyze-remind — add visualize suggestion

**Files:**
- Modify: `hooks/post-analyze-remind`

- [ ] **Step 1: Read current file and update**

Read `hooks/post-analyze-remind`. Make two changes:

1. Replace all `/labmate:analyze-experiment` with `/analyze-experiment`

2. In the `analysis)` case, change the message to include visualize suggestion:
```bash
    analysis)
      echo "Analysis complete. Run /visualize to see results as a dashboard, or /visualize compare for cross-experiment comparison."
      ;;
```

- [ ] **Step 2: Commit**

```bash
git add hooks/post-analyze-remind
git commit -m "feat: add /visualize suggestion to post-analyze hook + fix extensionless refs"
```

---

### Task 4: Create post-new-experiment-monitor hook

**Files:**
- Create: `hooks/post-new-experiment-monitor`

- [ ] **Step 1: Write hook script**

Create `hooks/post-new-experiment-monitor`:

```bash
#!/bin/bash
# Hook: PostToolUse(Write) — remind to use /monitor after new experiment scaffolding
INPUT=$(cat)

# Guard: only act on Write to exp/*/README.md
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
if [ -z "$FILE_PATH" ]; then exit 0; fi

# Match exp/{id}/README.md pattern
if ! echo "$FILE_PATH" | grep -qE 'exp/[^/]+/README\.md$'; then exit 0; fi

# Extract experiment ID from path
EXP_ID=$(echo "$FILE_PATH" | sed -E 's|.*/exp/([^/]+)/README\.md$|\1|')

echo "Experiment ${EXP_ID} scaffolded. After starting your run, use /monitor to check status."
```

- [ ] **Step 2: Make executable**

```bash
chmod +x hooks/post-new-experiment-monitor
```

- [ ] **Step 3: Commit**

```bash
git add hooks/post-new-experiment-monitor
git commit -m "feat: add post-new-experiment-monitor hook — suggest /monitor after scaffolding"
```

---

### Task 5: Create post-read-paper-survey hook

**Files:**
- Create: `hooks/post-read-paper-survey`

- [ ] **Step 1: Write hook script**

Create `hooks/post-read-paper-survey`:

```bash
#!/bin/bash
# Hook: PostToolUse(Write) — suggest /survey-literature after paper deep-dive archival
INPUT=$(cat)

# Guard: only act on Write to docs/papers/*-deep-dive.md
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
if [ -z "$FILE_PATH" ]; then exit 0; fi

if ! echo "$FILE_PATH" | grep -qE 'docs/papers/.*-deep-dive\.md$'; then exit 0; fi

# Extract paper name from filename
PAPER_NAME=$(basename "$FILE_PATH" | sed 's/-deep-dive\.md$//')

echo "Paper archived: ${PAPER_NAME}. Want to find related work? Try /survey-literature"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x hooks/post-read-paper-survey
```

- [ ] **Step 3: Commit**

```bash
git add hooks/post-read-paper-survey
git commit -m "feat: add post-read-paper-survey hook — suggest /survey-literature after archival"
```

---

### Task 6: Update hooks.json — register new hooks

**Files:**
- Modify: `hooks/hooks.json`

- [ ] **Step 1: Add PostToolUse(Write) entries**

Read `hooks/hooks.json`. Add two new entries to the `PostToolUse` array:

```json
{
  "matcher": "Write",
  "hooks": [{"type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" post-new-experiment-monitor", "async": false}]
},
{
  "matcher": "Write",
  "hooks": [{"type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" post-read-paper-survey", "async": false}]
}
```

- [ ] **Step 2: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: register post-new-experiment-monitor + post-read-paper-survey in hooks.json"
```

---

### Task 7: Update stop-check-workflow

**Files:**
- Modify: `hooks/stop-check-workflow`

- [ ] **Step 1: Read and update**

Read `hooks/stop-check-workflow`. Make three changes:

1. Remove the weekly progress check block (lines 45-53 approximately — the `WEEK=`, `WEEKLY_FILE=`, and the `if` block checking DOW). This is now handled by session-start.

2. Update any `/weekly-progress` references to `/commit-changelog --weekly`.

3. The agent references in the file don't mention cc-advisor or template-presenter, so no change needed there (verify by reading).

- [ ] **Step 2: Commit**

```bash
git add hooks/stop-check-workflow
git commit -m "refactor: remove weekly check from stop hook (moved to session-start)"
```

---

### Task 8: Update CLAUDE.md + gitignore template

**Files:**
- Modify: `CLAUDE.md`
- Modify: `references/gitignore-rules.md`

- [ ] **Step 1: Update CLAUDE.md hooks count**

Change `Hooks (6)` to `Hooks (8)` in the Plugin architecture table.

- [ ] **Step 2: Update gitignore template**

Read `references/gitignore-rules.md`. Add `.labmate-hook-state.json` to the labmate-specific section.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md references/gitignore-rules.md
git commit -m "docs: update hooks count to 8 + add .labmate-hook-state.json to gitignore template"
```
