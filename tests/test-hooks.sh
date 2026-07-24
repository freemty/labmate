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

codex_knowhow_payload=$(
  jq -cn '{
    hook_event_name: "PostToolUse",
    tool_input: {command: "python3 debug.py"},
    tool_response: {exit_code: 1, output: "CUDA error: missing device"}
  }'
)
output=$(run_hook "$TEST_TMP/codex-response" post-knowhow-remind "$codex_knowhow_payload")
assert_context "$output" "PostToolUse" "problem、cause、solution"

claude_knowhow_payload=$(
  jq -cn '{
    hook_event_name: "PostToolUse",
    tool_input: {command: "python3 debug.py"},
    tool_output: {exit_code: 1, stdout: "connection refused", stderr: ""}
  }'
)
output=$(run_hook "$TEST_TMP/claude-response" post-knowhow-remind "$claude_knowhow_payload")
assert_context "$output" "PostToolUse" "problem、cause、solution"

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

pretool_patch_payload=$(
  jq -cn --arg command "$patch_command" '{
    hook_event_name: "PreToolUse",
    tool_input: {command: $command}
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
assert_context "$output" "PostToolUse" "/analyze-experiment"

printf '%s\n' '{"skill_updated_at": 1}' > "$TEST_TMP/.pipeline-state.json"
output=$(run_hook "$TEST_TMP" pre-compact-remind '{}')
assert_system_message "$output" "Project skill is"

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

echo "hook compatibility tests passed"
