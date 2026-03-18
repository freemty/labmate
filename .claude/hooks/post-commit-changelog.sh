#!/bin/bash
# Hook: PostToolUse(Bash) — check CHANGELOG compliance after git commits
# Guard: only act if a git commit just happened
CHANGED=$(git diff --name-only HEAD~1 HEAD 2>/dev/null)
if [ -z "$CHANGED" ]; then exit 0; fi

HAS_PROMPTS=$(echo "$CHANGED" | grep "^prompts/" || true)
HAS_SKILLS=$(echo "$CHANGED" | grep "^\.claude/skills/" || true)
HAS_CHANGELOG=$(echo "$CHANGED" | grep "CHANGELOG" || true)

if [ -n "$HAS_PROMPTS" ] || [ -n "$HAS_SKILLS" ]; then
  if [ -z "$HAS_CHANGELOG" ]; then
    echo "Changed prompts/ or .claude/skills/ without CHANGELOG entry. Consider updating CHANGELOG.md."
  fi
fi
