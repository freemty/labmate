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
  local cwd="$1"
  local hook="$2"
  local payload="$3"
  (
    cd "$cwd"
    printf '%s' "$payload" | bash "$ROOT/hooks/$hook"
  )
}

run_hook_env() {
  local cwd="$1"
  local hook="$2"
  local payload="$3"
  shift 3
  (
    cd "$cwd"
    printf '%s' "$payload" | env "$@" bash "$ROOT/hooks/$hook"
  )
}

assert_context() {
  local output="$1"
  local event="$2"
  local text="$3"
  printf '%s' "$output" | jq -e \
    --arg event "$event" \
    --arg text "$text" \
    '.hookSpecificOutput.hookEventName == $event
      and (.hookSpecificOutput.additionalContext | contains($text))' \
    >/dev/null || fail "missing ${event} context containing: ${text}"
}

assert_system_message() {
  local output="$1"
  local text="$2"
  printf '%s' "$output" | jq -e \
    --arg text "$text" \
    '.continue == true and (.systemMessage | contains($text))' \
    >/dev/null || fail "missing systemMessage containing: ${text}"
}

for hook in "$ROOT"/hooks/*; do
  case "$hook" in
    *.json) continue ;;
  esac
  bash -n "$hook"
done
jq -e . "$ROOT/hooks/hooks.json" >/dev/null

mkdir -p "$TEST_TMP/codex-response" "$TEST_TMP/claude-response"

session_repo="$TEST_TMP/session-start"
mkdir -p \
  "$session_repo/.agents/skills/project-skill" \
  "$session_repo/.claude/skills/project-skill" \
  "$session_repo/docs"
printf '%s\n' '{"current_exp":"exp01a","stage":"analysis","skill_updated_at":null}' \
  > "$session_repo/.pipeline-state.json"
printf '%s\n' '# Codex project skill' \
  > "$session_repo/.agents/skills/project-skill/SKILL.md"
printf '%s\n' '# Claude project skill' \
  > "$session_repo/.claude/skills/project-skill/SKILL.md"
printf '%s\n' '# TODO' '## P0' '- [ ] Blocker — 2026-07-24' \
  > "$session_repo/docs/TODO.md"

output=$(run_hook_env "$session_repo" session-start '{}' \
  "PLUGIN_ROOT=$ROOT" "CLAUDE_PLUGIN_ROOT=$ROOT")
assert_context "$output" "SessionStart" ".agents/skills/project-skill/SKILL.md"
assert_context "$output" "SessionStart" "docs/TODO.md has 1 open P0 items"
if printf '%s' "$output" | grep -qE '@domain-expert|/monitor|/read-paper'; then
  fail "Codex SessionStart contains Claude-only agent or command syntax"
fi

output=$(run_hook_env "$session_repo" session-start '{}' \
  "CLAUDE_PLUGIN_ROOT=$ROOT")
assert_context "$output" "SessionStart" ".claude/skills/project-skill/SKILL.md"

uninitialized_repo="$TEST_TMP/uninitialized"
mkdir -p "$uninitialized_repo"
output=$(run_hook_env "$uninitialized_repo" session-start '{}' \
  "PLUGIN_ROOT=$ROOT" "CLAUDE_PLUGIN_ROOT=$ROOT")
assert_context "$output" "SessionStart" "LabMate's init-project skill"

codex_knowhow_payload=$(
  jq -cn '{
    hook_event_name: "PostToolUse",
    tool_input: {cmd: "python3 debug.py"},
    tool_response: {exit_code: 1, output: "CUDA error: missing device"}
  }'
)
output=$(run_hook "$TEST_TMP/codex-response" post-knowhow-remind "$codex_knowhow_payload")
assert_context "$output" "PostToolUse" "problem、cause、solution"
printf '%s' "$(cat "$TEST_TMP/codex-response/.labmate-hook-state.json")" \
  | jq -e '.knowhow_session.id == "date:'"$(date +%Y-%m-%d)"'"
      and .knowhow_session.count == 1' >/dev/null \
  || fail "knowhow reminder did not initialize date-bucket session state"

claude_knowhow_payload=$(
  jq -cn '{
    hook_event_name: "PostToolUse",
    tool_input: {command: "python3 debug.py"},
    tool_output: {exit_code: 1, stdout: "connection refused", stderr: ""}
  }'
)
output=$(run_hook "$TEST_TMP/claude-response" post-knowhow-remind "$claude_knowhow_payload")
assert_context "$output" "PostToolUse" "problem、cause、solution"

session_payload=$(
  jq -cn '{
    session_id: "session-a",
    hook_event_name: "PostToolUse",
    tool_input: {command: "python3 debug.py"},
    tool_response: {exit_code: 1, output: "connection refused"}
  }'
)
session_count_repo="$TEST_TMP/session-count"
mkdir -p "$session_count_repo"
output=$(run_hook "$session_count_repo" post-knowhow-remind "$session_payload")
assert_context "$output" "PostToolUse" "problem、cause、solution"
python3 -c "
import json
p = '$session_count_repo/.labmate-hook-state.json'
s = json.load(open(p))
s.pop('knowhow_remind', None)
json.dump(s, open(p, 'w'), indent=2)
"
session_payload_b=$(printf '%s' "$session_payload" | jq '.session_id = "session-b"')
output=$(run_hook "$session_count_repo" post-knowhow-remind "$session_payload_b")
assert_context "$output" "PostToolUse" "problem、cause、solution"
jq -e '.knowhow_session.id == "session-b" and .knowhow_session.count == 1' \
  "$session_count_repo/.labmate-hook-state.json" >/dev/null \
  || fail "knowhow reminder did not reset count for a new session"

arxiv_payload=$(
  jq -cn '{prompt: "Read https://arxiv.org/abs/2402.01030"}'
)
output=$(run_hook "$TEST_TMP" arxiv-detect "$arxiv_payload")
assert_context "$output" "UserPromptSubmit" "2402.01030"

patch_command=$'*** Begin Patch\n*** Add File: exp/exp01a/README.md\n+# Experiment\n*** Add File: docs/papers/example-deep-dive.md\n+# Paper\n*** End Patch\n'
patch_payload=$(
  jq -cn --arg command "$patch_command" '{
    hook_event_name: "PostToolUse",
    tool_input: {command: $command},
    tool_response: {output: "Success"}
  }'
)
output=$(run_hook "$TEST_TMP" post-new-experiment-monitor "$patch_payload")
assert_context "$output" "PostToolUse" "Experiment exp01a scaffolded"
output=$(run_hook "$TEST_TMP" post-read-paper-survey "$patch_payload")
assert_context "$output" "PostToolUse" "Paper archived: example"

freeform_patch_payload=$(
  jq -cn --arg patch "$patch_command" '{
    hook_event_name: "PostToolUse",
    tool_input: $patch,
    tool_response: {output: "Success"}
  }'
)
output=$(run_hook "$TEST_TMP" post-new-experiment-monitor "$freeform_patch_payload")
assert_context "$output" "PostToolUse" "Experiment exp01a scaffolded"

pretool_patch_payload=$(
  jq -cn --arg patch "$patch_command" '{
    hook_event_name: "PreToolUse",
    tool_input: {input: $patch}
  }'
)
output=$(run_hook "$TEST_TMP" brainstorm-remind "$pretool_patch_payload")
assert_context "$output" "PreToolUse" "Creating exp/exp01a/README.md"

worktree_payload=$(
  jq -cn '{
    hook_event_name: "PreToolUse",
    tool_input: {command: "git reset --hard HEAD~1"}
  }'
)
output=$(run_hook "$TEST_TMP" worktree-suggest "$worktree_payload")
assert_context "$output" "PreToolUse" "git worktree"

analyze_payload=$(
  jq -cn '{
    hook_event_name: "PostToolUse",
    tool_input: {command: "python3 exp/exp01a/analyze.py"},
    tool_response: {exit_code: 0, output: "done"}
  }'
)
output=$(run_hook "$TEST_TMP" post-analyze-remind "$analyze_payload")
assert_context "$output" "PostToolUse" "analyze-experiment skill"

printf '%s\n' '{"skill_updated_at": 1}' > "$TEST_TMP/.pipeline-state.json"
output=$(run_hook "$TEST_TMP" pre-compact-remind '{}')
assert_system_message "$output" "Project skill is"

printf '%s\n' '{"skill_updated_at": null}' > "$TEST_TMP/.pipeline-state.json"
output=$(run_hook "$TEST_TMP" pre-compact-remind '{}')
assert_system_message "$output" "has not been refreshed yet"

commit_repo="$TEST_TMP/commit-repo"
mkdir -p "$commit_repo"
git -C "$commit_repo" init -q
git -C "$commit_repo" config user.name "LabMate Test"
git -C "$commit_repo" config user.email "labmate@example.invalid"
printf '# Changelog\n\n## Unreleased\n' > "$commit_repo/CHANGELOG.md"
printf 'base\n' > "$commit_repo/sample.py"
git -C "$commit_repo" add CHANGELOG.md sample.py
git -C "$commit_repo" commit -qm "chore: initialize fixture"
printf 'changed\n' >> "$commit_repo/sample.py"
git -C "$commit_repo" add sample.py
git -C "$commit_repo" commit -qm "feat: change sample"

commit_payload=$(
  jq -cn '{
    hook_event_name: "PostToolUse",
    tool_input: {command: "git commit -m \"feat: change sample\""},
    tool_response: {exit_code: 0, output: "committed"}
  }'
)
output=$(run_hook "$commit_repo" post-commit-changelog "$commit_payload")
assert_context "$output" "PostToolUse" "CHANGELOG.md was NOT updated"
output=$(run_hook "$commit_repo" post-docs-remind "$commit_payload")
assert_context "$output" "PostToolUse" "相关文档可能需要同步更新"

printf '%s\n' '{"skill_updated_at": 1700000000}' > "$commit_repo/.pipeline-state.json"
for index in 1 2 3 4 5; do
  printf 'stale-%s\n' "$index" >> "$commit_repo/sample.py"
  git -C "$commit_repo" add sample.py
  git -C "$commit_repo" commit -qm "fix: stale fixture $index"
done
output=$(run_hook "$commit_repo" post-skill-stale "$commit_payload")
assert_context "$output" "PostToolUse" "update-project-skill skill"

archive_repo="$TEST_TMP/archive-repo"
mkdir -p "$archive_repo"
git -C "$archive_repo" init -q
git -C "$archive_repo" config user.name "LabMate Test"
git -C "$archive_repo" config user.email "labmate@example.invalid"
printf 'base\n' > "$archive_repo/sample.py"
git -C "$archive_repo" add sample.py
git -C "$archive_repo" commit -qm "chore: initialize archive fixture"
printf '%s\n' '{"knowhow_session":{"id":"session-a","count":1}}' \
  > "$archive_repo/.labmate-hook-state.json"
output=$(run_hook "$archive_repo" pre-compact-archive '{}')
assert_system_message "$output" "LabMate 的 update-docs skill"

docs_repo="$TEST_TMP/docs-repo"
mkdir -p "$docs_repo"
git -C "$docs_repo" init -q
git -C "$docs_repo" config user.name "LabMate Test"
git -C "$docs_repo" config user.email "labmate@example.invalid"
printf 'base\n' > "$docs_repo/sample.py"
printf '# Instructions\n' > "$docs_repo/AGENTS.md"
git -C "$docs_repo" add sample.py AGENTS.md
git -C "$docs_repo" commit -qm "chore: initialize docs fixture"
printf 'changed\n' >> "$docs_repo/sample.py"
printf '\nUpdated\n' >> "$docs_repo/AGENTS.md"
git -C "$docs_repo" add sample.py AGENTS.md
git -C "$docs_repo" commit -qm "fix: update code and agent docs"
output=$(run_hook "$docs_repo" post-docs-remind "$commit_payload")
[ -z "$output" ] || fail "post-docs-remind fired even though AGENTS.md changed"

echo "hook compatibility tests passed"
