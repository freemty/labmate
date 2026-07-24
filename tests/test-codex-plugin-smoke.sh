#!/usr/bin/env bash
set -euo pipefail

LABMATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE_ROOT="${1:-$(cd "$LABMATE_ROOT/../.." && pwd)}"
SMOKE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/labmate-codex-plugin.XXXXXX")"
SMOKE_HOME="$SMOKE_ROOT/home"
mkdir -p "$SMOKE_HOME"

cleanup() {
  case "$SMOKE_ROOT" in
    "${TMPDIR:-/tmp}"/labmate-codex-plugin.*) rm -rf -- "$SMOKE_ROOT" ;;
  esac
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

command -v codex >/dev/null || fail "codex CLI is required"
command -v jq >/dev/null || fail "jq is required"
[ -f "$MARKETPLACE_ROOT/.agents/plugins/marketplace.json" ] ||
  fail "not a Codex marketplace checkout: $MARKETPLACE_ROOT"

HOME="$SMOKE_HOME" CODEX_HOME="$SMOKE_ROOT" \
  codex plugin marketplace add "$MARKETPLACE_ROOT" --json >/dev/null
install_json="$(
  HOME="$SMOKE_HOME" CODEX_HOME="$SMOKE_ROOT" \
    codex plugin add labmate@yuanbo-skills --json
)"
list_json="$(
  HOME="$SMOKE_HOME" CODEX_HOME="$SMOKE_ROOT" \
    codex plugin list --json
)"

jq -e '
  .installed
  | map(select(
      .pluginId == "labmate@yuanbo-skills"
      and .installed == true
      and .enabled == true
    ))
  | length == 1
' <<< "$list_json" >/dev/null ||
  fail "Labmate was not installed and enabled exactly once"

installed_path="$(jq -r '.installedPath' <<< "$install_json")"
[ -d "$installed_path/skills" ] ||
  fail "installed Labmate skill directory is missing"

actual_skills="$(
  find "$installed_path/skills" \
    -mindepth 2 -maxdepth 2 -name SKILL.md -print \
    | sed 's|/SKILL.md$||' \
    | xargs -n1 basename \
    | sort
)"
expected_skills="$(
  printf '%s\n' \
    analyze-experiment \
    commit-changelog \
    init-project \
    monitor \
    new-experiment \
    read-paper \
    survey-literature \
    todo \
    update-docs \
    update-knowhow \
    update-project-skill \
    visualize
)"

[ "$(printf '%s\n' "$actual_skills" | wc -l | tr -d ' ')" = "12" ] ||
  fail "expected 12 installed Labmate skills"
[ "$actual_skills" = "$expected_skills" ] ||
  fail "installed Labmate skill set differs from the manifest"
[ "$(printf '%s\n' "$actual_skills" | uniq -d | wc -l | tr -d ' ')" = "0" ] ||
  fail "Labmate skill names are duplicated"
[ ! -e "$SMOKE_HOME/.agents/skills/read-paper" ] ||
  fail "plugin install unexpectedly created a legacy global skill link"

echo "Codex plugin smoke tests passed"
