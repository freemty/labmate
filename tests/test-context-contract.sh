#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

skill_count=$(find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
[ "$skill_count" = "12" ] || { echo "expected 12 skills, found $skill_count" >&2; exit 1; }

explicit=0
for skill in "$ROOT"/skills/*/SKILL.md; do
  words=$(wc -w < "$skill" | tr -d ' ')
  [ "$words" -le 500 ] || { echo "$skill exceeds 500 words: $words" >&2; exit 1; }
  description=$(awk '
    /^description:/ {capture=1}
    capture {print}
    capture && /^---$/ {exit}
  ' "$skill")
  printf '%s' "$description" | grep -q '^description: Use when' \
    || { echo "$skill description must begin with Use when" >&2; exit 1; }
  if grep -q '^disable-model-invocation: true$' "$skill"; then
    explicit=$((explicit + 1))
    policy="$(dirname "$skill")/agents/openai.yaml"
    grep -q 'allow_implicit_invocation: false' "$policy" \
      || { echo "missing explicit Codex policy: $policy" >&2; exit 1; }
  fi
done
[ "$explicit" = "11" ] || { echo "expected 11 explicit skills, found $explicit" >&2; exit 1; }

for agent in "$ROOT"/agents/*.md; do
  words=$(wc -w < "$agent" | tr -d ' ')
  [ "$words" -le 350 ] || { echo "$agent exceeds 350 words: $words" >&2; exit 1; }
done

if rg -n '/loop|/brainstorming|@(domain-expert|project-advisor|exp-manager|slides-maker|viz-frontend)' \
  "$ROOT/skills" "$ROOT/hooks" "$ROOT/references/instruction-template-"*.md; then
  echo "portable runtime content contains host command or named-agent syntax" >&2
  exit 1
fi

session_chars=$(PLUGIN_ROOT="$ROOT" bash "$ROOT/hooks/session-start" \
  | jq -r '.hookSpecificOutput.additionalContext' | wc -c | tr -d ' ')
[ "$session_chars" -le 160 ] \
  || { echo "uninitialized SessionStart exceeds 160 chars" >&2; exit 1; }

echo "PASS: LabMate context contract"
