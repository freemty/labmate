#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing required file: $1"
}

require_dir() {
  [ -d "$1" ] || fail "missing required directory: $1"
}

reject_contains() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    if rg -n "$pattern" "$@"; then
      fail "forbidden pattern found: $pattern"
    fi
  elif grep -RInE "$pattern" "$@"; then
    fail "forbidden pattern found: $pattern"
  fi
}

if [ -f "CLAUDE.md" ] && [ -f "AGENTS.md" ]; then
  require_file ".claude/skills/project-skill/SKILL.md"
  require_file ".agents/skills/project-skill/SKILL.md"
  cmp -s ".claude/skills/project-skill/SKILL.md" ".agents/skills/project-skill/SKILL.md" \
    || fail "project-skill SKILL.md differs between .claude and .agents"

  if [ -f ".claude/skills/project-skill/CHANGELOG.md" ] || [ -f ".agents/skills/project-skill/CHANGELOG.md" ]; then
    require_file ".claude/skills/project-skill/CHANGELOG.md"
    require_file ".agents/skills/project-skill/CHANGELOG.md"
    cmp -s ".claude/skills/project-skill/CHANGELOG.md" ".agents/skills/project-skill/CHANGELOG.md" \
      || fail "project-skill CHANGELOG.md differs between .claude and .agents"
  fi

  if [ -d ".claude/agent-memory" ] || [ -d ".agents/agent-memory" ]; then
    require_dir ".claude/agent-memory"
    require_dir ".agents/agent-memory"
    diff -qr ".claude/agent-memory" ".agents/agent-memory" >/dev/null \
      || fail "agent-memory differs between .claude and .agents"
  fi
fi

search_paths=()
for path in CLAUDE.md AGENTS.md .claude .agents docs; do
  [ -e "$path" ] && search_paths+=("$path")
done
if [ "${#search_paths[@]}" -gt 0 ]; then
  reject_contains "Codex Opus|AGENTS\\.md / AGENTS\\.md" "${search_paths[@]}"
fi

echo "agent parity check passed"
