# Hooks Enhancement: Transition Prompts + Periodic Reminders

**Date:** 2026-03-20
**Status:** Reviewed
**Context:** 5 agents + 9 skills is lean enough. Hooks should guide new users through the research lifecycle automatically.

---

## Design Principles

1. **Zero cognitive load** — hooks tell users what to do next, users never memorize commands
2. **24h frequency cap** — same reminder max once per day (tracked via `.labmate-hook-state.json`)
3. **Non-blocking** — all hooks output text reminders, never auto-execute skills
4. **Pipeline-aware** — read `.pipeline-state.json` to know what stage we're in

---

## Hook State File

New file `.labmate-hook-state.json` for frequency limiting (gitignored):

```json
{
  "last_remind_visualize": "2026-03-20T10:00:00",
  "last_remind_read_paper": "2026-03-15T10:00:00",
  "last_remind_weekly": "2026-03-19T10:00:00"
}
```

Helper function shared across hooks:

```bash
should_remind() {
  local key="$1"
  local hours="${2:-24}"
  local state_file=".labmate-hook-state.json"
  if [ ! -f "$state_file" ]; then echo "yes"; return; fi
  local result=$(python3 -c "
import json, sys
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

This helper should live in `hooks/hook-utils` and be sourced via `source "${SCRIPT_DIR}/hook-utils"` where `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`.

---

## New Hooks

### Hook 1: post-analyze-visualize (转场)

**Trigger:** PostToolUse(Bash) — after `/analyze-experiment` completes (detect: pipeline stage changes to "analysis")

**Behavior:** When `.pipeline-state.json` stage just became "analysis", output:
> Analysis complete for {exp_id}. Run `/visualize` to see results as a dashboard, or `/visualize compare` for cross-experiment comparison.

**Implementation:** Modify existing `post-analyze-remind` to add this as a second check. When stage is "analysis" and the skill just finished (not already reminded), append the visualize suggestion.

### Hook 2: post-new-experiment-monitor (转场)

**Trigger:** PostToolUse(Write) — after `/new-experiment` creates `exp/{id}/README.md`

**Behavior:** When a new `exp/*/README.md` is written:
> Experiment {exp_id} scaffolded. After starting your run, use `/monitor` to check status.

**Implementation:** New hook script. Match Write tool output path against `exp/*/README.md` pattern.

### Hook 3: post-read-paper-survey (转场)

**Trigger:** PostToolUse(Write) — after domain-expert writes a `*-deep-dive.md` file

**Behavior:** When a `docs/papers/*-deep-dive.md` is written:
> Paper archived to {filename}. landscape.md updated. Want to find related work? Try `/survey-literature {inferred topic}`.

**Implementation:** New hook script. Match Write tool output path against `docs/papers/*-deep-dive.md`.

### Hook 4: remind-read-paper (定期)

**Trigger:** SessionStart — frequency capped at once per 7 days

**Behavior:** Check most recent `docs/papers/*-deep-dive.md` or `docs/papers/*.md` modification time. If >7 days old (or no papers exist):
> It's been {N} days since your last paper deep-dive. Try `/read-paper` to stay current with the literature.

**Implementation:** Add to existing `session-start` hook. Use `should_remind("read_paper", 168)` (168h = 7 days).

### Hook 5: remind-weekly (定期)

**Trigger:** SessionStart — on Fridays (or later) if no weekly for current week

**Behavior:** Check if `docs/weekly/YYYY-WNN.md` exists for current ISO week. If not, and it's Friday or later:
> No weekly progress for {week}. Run `/commit-changelog --weekly` to summarize this week's work.

**Implementation:** Move the existing weekly check from `stop-check-workflow` to `session-start` (more visible). Use `should_remind("weekly", 24)` so it only fires once per day. Update the command from `/weekly-progress` to `/commit-changelog --weekly`.

---

## Modifications to Existing Hooks

### session-start (修改)

Add two periodic checks after the existing context injection:
1. Read-paper reminder (Hook 4)
2. Weekly progress reminder (Hook 5)

Also update the workflow hint to reflect current skill names:
```
Workflow: /new-experiment -> /monitor -> /analyze-experiment -> /visualize -> /commit-changelog
Skills: /read-paper /survey-literature /new-experiment /analyze-experiment /visualize /monitor /commit-changelog /update-project-skill
```

### stop-check-workflow (修改)

- Remove the weekly progress check (moved to session-start)
- Update `/weekly-progress` reference to `/commit-changelog --weekly`
- Update agent references (remove cc-advisor, template-presenter)

### post-analyze-remind (修改)

- Add visualize suggestion when stage is "analysis" (Hook 1)
- Update `/labmate:analyze-experiment` to `/analyze-experiment` (extensionless convention)

---

## Implementation Scope

### New files
- `hooks/hook-utils` — shared helper functions (should_remind, mark_reminded)
- `hooks/post-new-experiment-monitor` — Hook 2
- `hooks/post-read-paper-survey` — Hook 3

### Files to modify
- `hooks/session-start` — add Hook 4 + Hook 5, update skill/agent references
- `hooks/post-analyze-remind` — add Hook 1 (visualize suggestion)
- `hooks/stop-check-workflow` — remove weekly check, update references
- `hooks/hooks.json` — register new PostToolUse(Write) hooks:
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

### Implementation note on PostToolUse(Write)

PostToolUse hooks receive the original `tool_input` (including `file_path`) in their JSON input. Verify by adding `echo "$INPUT" | jq . > /tmp/labmate-debug-write-hook.json` during development. The `brainstorm-remind` hook (PreToolUse Write) already uses `.tool_input.file_path` — PostToolUse should have the same structure.

### Other
- Add `.labmate-hook-state.json` to `.gitignore` template in `references/gitignore-rules.md`
- Update CLAUDE.md hooks count from 6 to 8

### Not in scope
- No auto-execution of skills
- No new agents or skills
- No changes to existing skill behavior
