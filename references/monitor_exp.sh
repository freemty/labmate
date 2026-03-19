#!/bin/bash
# Experiment status monitor — designed for /loop integration
# Usage: monitor_exp.sh <exp_id>
# Exit 0 = still running (or no data), Exit 1 = all done
#
# Example: /loop 5m bash scripts/monitor_exp.sh exp01a

set -euo pipefail

EXP_ID="${1:?Usage: monitor_exp.sh <exp_id>}"
LOG_FILE="exp/${EXP_ID}/results/runs.log"

if [ ! -f "$LOG_FILE" ]; then
  echo "[${EXP_ID}] No runs.log found — experiment may not have started."
  exit 0
fi

# Count entries (lines starting with #, excluding the format header)
TOTAL=$(grep -c "^# [0-9]" "$LOG_FILE" 2>/dev/null || echo 0)
LAST_ENTRY=$(grep "^# [0-9]" "$LOG_FILE" 2>/dev/null | tail -1 || echo "none")
LAST_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$LOG_FILE" 2>/dev/null || stat -c "%y" "$LOG_FILE" 2>/dev/null | cut -d. -f1 || echo "unknown")

echo "[${EXP_ID}] ${TOTAL} entries | Last modified: ${LAST_MODIFIED}"
echo "  Last: ${LAST_ENTRY}"

# Check for recent activity (modified in last 10 minutes)
if [ "$(uname)" = "Darwin" ]; then
  MINUTES_AGO=$(( ($(date +%s) - $(stat -f "%m" "$LOG_FILE")) / 60 ))
else
  MINUTES_AGO=$(( ($(date +%s) - $(stat -c "%Y" "$LOG_FILE")) / 60 ))
fi

if [ "$MINUTES_AGO" -gt 10 ]; then
  echo "  Warning: No activity for ${MINUTES_AGO} minutes."
fi
