#!/bin/bash
# Hook: PreToolUse(Write) — remind to brainstorm before big changes
# Checks if user is creating substantial new content without a recent spec

# Only remind, never block
RECENT_SPEC=$(find docs/specs/ docs/superpowers/specs/ -name "*.md" -mtime -1 2>/dev/null | head -1)

if [ -z "$RECENT_SPEC" ]; then
  # No recent spec found — but only warn for substantial files
  # This is a gentle reminder, not a blocker
  echo "Tip: No recent spec found. Consider /brainstorming first for big changes."
fi
