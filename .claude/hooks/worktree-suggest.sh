#!/bin/bash
# Hook: PreToolUse(Bash) — suggest worktree for destructive git ops

INPUT=$(cat)

# Check for destructive git operations
if echo "$INPUT" | grep -qE "git (reset --hard|checkout -- \.|clean -f|clean -fd|branch -D)"; then
  echo "Tip: Consider using 'git worktree' for destructive/exploratory changes."
  echo "This keeps your main working directory clean."
  echo "Usage: git worktree add ../my-experiment-branch experiment-branch"
fi
