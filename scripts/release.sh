#!/bin/bash
set -euo pipefail

MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/labmate-marketplace"
MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"

VERSION=$(python3 -c "import json; print(json.load(open('package.json'))['version'])")

echo "=== Releasing labmate v${VERSION} ==="

# 1. Verify platform parity and tests before any release mutation
python3 scripts/sync-version.py --check
bash tests/test-hooks.sh
bash tests/test-platform-compat.sh
PARENT_MARKETPLACE="$(cd ../.. 2>/dev/null && pwd || true)"
if [ -f "$PARENT_MARKETPLACE/.agents/plugins/marketplace.json" ] &&
   [ -x "$PARENT_MARKETPLACE/tests/test-install.sh" ]; then
  bash "$PARENT_MARKETPLACE/tests/test-install.sh"
  if command -v codex >/dev/null 2>&1; then
    bash tests/test-codex-plugin-smoke.sh "$PARENT_MARKETPLACE"
  fi
else
  echo "NOTE: outer yuanbo-skills checkout not found; installer smoke skipped"
fi

# 2. Verify on dev branch with clean state
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "dev" ]; then
  echo "ERROR: must be on dev branch (currently on $BRANCH)"
  exit 1
fi

if [ -n "$(git diff --name-only HEAD)" ] || [ -n "$(git diff --cached --name-only)" ]; then
  echo "ERROR: uncommitted changes, commit first"
  exit 1
fi

# 3. Merge dev → main
echo "[1/5] Merging dev → main..."
git checkout main
git merge dev --no-ff -m "release: v${VERSION}"

# 4. Push both branches
echo "[2/5] Pushing main + dev..."
git push origin main
git checkout dev
git push origin dev

# 5. Sync the Claude marketplace version. Codex reads the plugin manifest.
echo "[3/5] Syncing Claude marketplace.json → v${VERSION}..."
if [ ! -f "$MARKETPLACE_JSON" ]; then
  echo "ERROR: marketplace.json not found at $MARKETPLACE_JSON"
  exit 1
fi

python3 -c "
import json, pathlib
p = pathlib.Path('$MARKETPLACE_JSON')
data = json.loads(p.read_text())
data['plugins'][0]['version'] = '$VERSION'
p.write_text(json.dumps(data, indent=2) + '\n')
"

cd "$MARKETPLACE_DIR"
git add .claude-plugin/marketplace.json
if git diff --cached --quiet; then
  echo "  marketplace.json already at v${VERSION}, skipping"
else
  git commit -m "chore: bump labmate version to v${VERSION}"
  git push origin main
fi

# 6. Fix Claude installed_plugins.json — update version + correct SHA
echo "[4/5] Fixing Claude installed_plugins.json..."
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
CACHE_PATH="$HOME/.claude/plugins/cache/labmate-marketplace/labmate/${VERSION}"
MARKETPLACE_SHA=$(cd "$MARKETPLACE_DIR" && git rev-parse HEAD)
if [ -f "$INSTALLED" ]; then
  python3 -c "
import json, pathlib
p = pathlib.Path('$INSTALLED')
data = json.loads(p.read_text())
entries = data.get('plugins', {}).get('labmate@labmate-marketplace', [])
changed = False
for e in entries:
    needs_update = (
        e.get('version') != '$VERSION'
        or e.get('installPath') != '$CACHE_PATH'
        or e.get('gitCommitSha') != '$MARKETPLACE_SHA'
    )
    if needs_update:
        e['version'] = '$VERSION'
        e['installPath'] = '$CACHE_PATH'
        e['gitCommitSha'] = '$MARKETPLACE_SHA'
        changed = True
if changed:
    p.write_text(json.dumps(data, indent=2) + '\n')
    print(f'  Updated {len(entries)} entries to v$VERSION (sha: $MARKETPLACE_SHA)')
else:
    print('  All entries already at v$VERSION')
"
fi

# 7. Clean up stale Claude cache versions
echo "[5/5] Cleaning stale cache..."
CACHE_BASE="$HOME/.claude/plugins/cache/labmate-marketplace/labmate"
for dir in "$CACHE_BASE"/*/; do
  dir_version=$(basename "$dir")
  if [ "$dir_version" != "$VERSION" ]; then
    rm -rf "$dir"
    echo "  Removed stale cache: $dir_version"
  fi
done

# 8. Done
echo ""
echo "  labmate v${VERSION} released."
echo "  Claude: open a new session and run '/reload-plugins'."
echo "  Codex: update and commit the yuanbo-skills submodule pointer,"
echo "         refresh the marketplace, reinstall LabMate, and review /hooks."
