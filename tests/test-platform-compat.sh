#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

jq -e 'has("agents") | not' "$ROOT/.codex-plugin/plugin.json" >/dev/null \
  || fail "Codex manifest must not declare Claude Markdown agents"
jq -e '.agents | length == 5' "$ROOT/.claude-plugin/plugin.json" >/dev/null \
  || fail "Claude manifest must keep five named agents"

explicit_skills=$(rg -l '^disable-model-invocation: true$' \
  "$ROOT"/skills/*/SKILL.md | sort)
[ "$(printf '%s\n' "$explicit_skills" | sed '/^$/d' | wc -l | tr -d ' ')" = "11" ] \
  || fail "expected eleven explicit-only skills"

while IFS= read -r skill_file; do
  [ -n "$skill_file" ] || continue
  metadata="$(dirname "$skill_file")/agents/openai.yaml"
  [ -f "$metadata" ] || fail "missing Codex policy: $metadata"
  grep -q '^  allow_implicit_invocation: false$' "$metadata" \
    || fail "incorrect Codex invocation policy: $metadata"
done <<< "$explicit_skills"

[ "$(find "$ROOT/skills" -path '*/agents/openai.yaml' | wc -l | tr -d ' ')" = "11" ] \
  || fail "unexpected number of Codex skill policy files"

package_version=$(jq -r '.version' "$ROOT/package.json")
claude_version=$(jq -r '.version' "$ROOT/.claude-plugin/plugin.json")
codex_version=$(jq -r '.version' "$ROOT/.codex-plugin/plugin.json")
[ "$package_version" = "$claude_version" ] \
  || fail "package and Claude manifest versions differ"
[ "$package_version" = "$codex_version" ] \
  || fail "package and Codex manifest versions differ"
grep -q "version-${package_version}-" "$ROOT/README.md" \
  || fail "README version badge differs from package version"
grep -q "version-${package_version}-" "$ROOT/README_ZH.md" \
  || fail "README_ZH version badge differs from package version"

cmp -s \
  "$ROOT/.claude/skills/project-skill/SKILL.md" \
  "$ROOT/.agents/skills/project-skill/SKILL.md" \
  || fail "standalone project skills differ"
cmp -s \
  "$ROOT/.claude/skills/project-skill/CHANGELOG.md" \
  "$ROOT/.agents/skills/project-skill/CHANGELOG.md" \
  || fail "standalone project skill changelogs differ"

[ -f "$ROOT/references/instruction-template-general.md" ] \
  || fail "missing general instruction template"
[ -f "$ROOT/references/instruction-template-research.md" ] \
  || fail "missing research instruction template"
[ ! -e "$ROOT/references/claude-md-template-general.md" ] \
  || fail "deprecated Claude-only general template still exists"
[ ! -e "$ROOT/references/claude-md-template-research.md" ] \
  || fail "deprecated Claude-only research template still exists"

runtime_paths=(
  "$ROOT/hooks"
  "$ROOT/references/instruction-template-general.md"
  "$ROOT/references/instruction-template-research.md"
  "$ROOT/references/project-skill-template.md"
  "$ROOT/references/viewer-static/index.html"
)
if rg -n \
  '@(domain-expert|project-advisor|exp-manager|slides-maker|viz-frontend)|/loop\b|/brainstorming\b|/(read-paper|survey-literature|new-experiment|monitor|analyze-experiment|visualize|commit-changelog|update-project-skill|update-docs)\b' \
  "${runtime_paths[@]}"; then
  fail "runtime hook or generated template contains host-specific routing"
fi

agent_backed_skills=(
  "$ROOT/skills/analyze-experiment/SKILL.md"
  "$ROOT/skills/monitor/SKILL.md"
  "$ROOT/skills/read-paper/SKILL.md"
  "$ROOT/skills/survey-literature/SKILL.md"
  "$ROOT/skills/update-project-skill/SKILL.md"
  "$ROOT/skills/visualize/SKILL.md"
)
if rg -n '@(domain-expert|exp-manager|slides-maker|viz-frontend)|Agent tool|Opus subagent' \
  "${agent_backed_skills[@]}"; then
  fail "agent-backed skill still requires a Claude-only agent interface"
fi

bash "$ROOT/tests/test-read-paper.sh"

mapfile_supported=0
if type mapfile >/dev/null 2>&1; then
  mapfile_supported=1
fi
if [ "$mapfile_supported" -eq 1 ]; then
  mapfile -t configured_hooks < <(
    jq -r '.hooks[][] | .hooks[] | .command' "$ROOT/hooks/hooks.json" \
      | awk '{print $NF}' \
      | sort -u
  )
else
  configured_hooks=()
  while IFS= read -r hook; do
    configured_hooks+=("$hook")
  done < <(
    jq -r '.hooks[][] | .hooks[] | .command' "$ROOT/hooks/hooks.json" \
      | awk '{print $NF}' \
      | sort -u
  )
fi

[ "${#configured_hooks[@]}" = "13" ] \
  || fail "expected thirteen configured hook handlers"
for hook in "${configured_hooks[@]}"; do
  rg -q "(run_hook|run_hook_env).*${hook}" "$ROOT/tests/test-hooks.sh" \
    || fail "configured hook lacks a direct test: $hook"
done

echo "platform compatibility checks passed"
