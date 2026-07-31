#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_TMP="$(mktemp -d)"

cleanup() {
  case "$TEST_TMP" in
    /tmp/*|/private/tmp/*|/var/folders/*) rm -rf -- "$TEST_TMP" ;;
    *) echo "refusing to remove unexpected temp path: $TEST_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run_hook() {
  local cwd="$1" hook="$2" payload="$3"
  shift 3
  (
    cd "$cwd"
    printf '%s' "$payload" | env "$@" bash "$ROOT/hooks/$hook"
  )
}

assert_context() {
  local output="$1" event="$2" text="$3"
  printf '%s' "$output" | jq -e \
    --arg event "$event" --arg text "$text" \
    '.hookSpecificOutput.hookEventName == $event
      and (.hookSpecificOutput.additionalContext | contains($text))' >/dev/null \
    || fail "missing ${event} context containing ${text}"
}

for hook in hook-utils run-hook.cmd session-start pre-compact-archive worktree-suggest; do
  bash -n "$ROOT/hooks/$hook"
done
jq -e '.hooks | keys | sort == ["PreCompact","PreToolUse","SessionStart"]' \
  "$ROOT/hooks/hooks.json" >/dev/null
jq -e '[.hooks[][] | .hooks[]] | length == 3' "$ROOT/hooks/hooks.json" >/dev/null

uninitialized="$TEST_TMP/uninitialized"
mkdir -p "$uninitialized"
output=$(run_hook "$uninitialized" session-start '{}' "PLUGIN_ROOT=$ROOT")
assert_context "$output" "SessionStart" '<labmate state="uninitialized" />'

repo="$TEST_TMP/repo"
mkdir -p "$repo/.agents/skills/project-skill" "$repo/.claude/skills/project-skill"
printf '%s\n' '{"current_exp":"exp01a","stage":"analysis"}' > "$repo/.pipeline-state.json"
printf '# project\n' > "$repo/.agents/skills/project-skill/SKILL.md"
printf '# project\n' > "$repo/.claude/skills/project-skill/SKILL.md"

output=$(run_hook "$repo" session-start '{}' "PLUGIN_ROOT=$ROOT" "CLAUDE_PLUGIN_ROOT=$ROOT")
assert_context "$output" "SessionStart" 'exp="exp01a"'
assert_context "$output" "SessionStart" '.agents/skills/project-skill/SKILL.md'
if printf '%s' "$output" | grep -qE '/loop|/monitor|@domain-expert|Available skills|Workflow:'; then
  fail "SessionStart injected a command, role catalog, or workflow"
fi

output=$(run_hook "$repo" session-start '{}' "CLAUDE_PLUGIN_ROOT=$ROOT")
assert_context "$output" "SessionStart" '.claude/skills/project-skill/SKILL.md'

output=$(run_hook "$repo" session-start '{}' "CURSOR_PLUGIN_ROOT=$ROOT")
printf '%s' "$output" | jq -e '.additional_context | contains("exp01a")' >/dev/null \
  || fail "Cursor branch did not emit additional_context"

codex_payload=$(jq -cn '{tool_input:{cmd:"git reset --hard HEAD~1"}}')
output=$(run_hook "$repo" worktree-suggest "$codex_payload")
assert_context "$output" "PreToolUse" "Destructive git operation detected"

claude_payload=$(jq -cn '{tool_input:{command:"git clean -fd"}}')
output=$(run_hook "$repo" worktree-suggest "$claude_payload")
assert_context "$output" "PreToolUse" "Destructive git operation detected"

benign_payload=$(jq -cn '{tool_input:{cmd:"git status"}}')
output=$(run_hook "$repo" worktree-suggest "$benign_payload")
[ -z "$output" ] || fail "benign git command emitted context"

git -C "$repo" init -q
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name Test
for n in 1 2 3; do
  printf '%s\n' "$n" > "$repo/file-$n"
  git -C "$repo" add "file-$n"
  git -C "$repo" commit -qm "test $n"
done
output=$(run_hook "$repo" pre-compact-archive '{}')
printf '%s' "$output" | jq -e \
  '.continue == true and (.systemMessage | contains("archive only verified findings"))' \
  >/dev/null || fail "heavy session did not emit bounded archival hint"

echo "PASS: 3 LabMate hook handlers"
