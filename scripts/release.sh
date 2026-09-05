#!/bin/bash
set -euo pipefail
# Release verification is deliberately separate from publication and installation.
RELEASE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RELEASE_ROOT"
case "${1:---check}" in
  --check) ;;
  *) echo "Usage: scripts/release.sh [--check]. Publish via the reviewed release guide." >&2; exit 2 ;;
esac
python3 scripts/sync-version.py --check
bash tests/test-hooks.sh
bash tests/test-platform-compat.sh
bash tests/test-context-contract.sh
bash tests/test-scripts.sh
PARENT_MARKETPLACE="$(cd ../.. && pwd)"
if [ -f "$PARENT_MARKETPLACE/scripts/check_release.py" ]; then
  python3 "$PARENT_MARKETPLACE/scripts/check_release.py"
  bash "$PARENT_MARKETPLACE/tests/test-context-audit.sh"
  bash "$PARENT_MARKETPLACE/tests/test-install.sh"
else
  echo "Outer marketplace checks unavailable in this standalone checkout."
fi
echo "Release checks complete. No commits, merges, pushes or installation changes made."
