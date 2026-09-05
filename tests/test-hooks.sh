#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for hook in "$ROOT"/hooks/*; do
  case "$hook" in *.json) continue ;; esac
  bash -n "$hook"
done
python3 "$ROOT/tests/test_lifecycle.py"
