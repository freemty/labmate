#!/bin/bash
# Hook: PreToolUse(Skill) — block direct /frontend-slides invocation
# This is the ONLY hard-blocking hook in the template.
# Prevents: (1) context pollution from ~60KB HTML, (2) enforces analysis-first workflow

# The hook receives tool input via stdin in Claude Code hooks
INPUT=$(cat)

# Check if the skill being invoked is frontend-slides
if echo "$INPUT" | grep -q "frontend-slides"; then
  echo "BLOCK: Direct /frontend-slides is blocked."
  echo "Use /analyze-experiment instead — it handles slides generation via the slides-maker agent,"
  echo "keeping heavy HTML output out of your main context."
  exit 2
fi
