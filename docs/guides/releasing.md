# Releasing a New Version

> Developer guide for publishing a new labmate release.

## Prerequisites

- On `dev` branch with all changes committed
- `scripts/release.sh` present in repo
- Marketplace repo cloned at `~/.claude/plugins/marketplaces/labmate-marketplace/`

## Steps

### 1. Bump the canonical version

Edit `package.json` and update the `version` field:

```json
{
  "version": "X.Y.Z"
}
```

Then synchronize both plugin manifests and both README badges:

```bash
python3 scripts/sync-version.py --write
python3 scripts/sync-version.py --check
```

Commit the synchronized files on `dev`. Do not publish when package, Claude
manifest, Codex manifest, or README badges differ.

### 2. Run release script

```bash
./scripts/release.sh
```

The script automatically:
1. Runs version parity, hook, context-budget, deterministic-interface,
   platform compatibility, and available outer installer/plugin smoke checks
2. Verifies you're on `dev` with a clean working tree
3. Merges `dev` into `main` (no-ff) and pushes both branches
4. Updates the Claude marketplace version
5. Repairs local Claude install metadata and stale caches

Codex reads the version from `.codex-plugin/plugin.json`; its marketplace entry
does not duplicate the version. After releasing the LabMate repository, update
and commit the LabMate submodule pointer in `yuanbo-skills`.

When LabMate is checked out at `plugins/labmate` in `yuanbo-skills`, the script
uses temporary `HOME`/`CODEX_HOME` directories for installer and Codex plugin
smoke tests. A standalone LabMate checkout skips only those two outer-repository
checks.

### 3. Verify in a new session

**You must exit the current session.** The plugin loader locks the cache path at session start.

For Claude Code, in a new session:
```
/reload-plugins
```

Then invoke any labmate skill and check the `Base directory` line in the output matches the new version.

For Codex:

```bash
codex plugin marketplace upgrade yuanbo-skills
codex plugin add labmate@yuanbo-skills
codex plugin list
```

Start a new task, review changed hook hashes with `/hooks`, and invoke a skill
through `/skills` or `$labmate:<skill>`.

## Troubleshooting

### release.sh fails: "uncommitted changes"

The script checks tracked files only (not untracked). If you see this, run `git status` and commit or stash the changes.

### /reload-plugins still shows old version

1. Check `installed_plugins.json` has correct version, installPath, and gitCommitSha for all scopes
2. Verify gitCommitSha belongs to the **marketplace repo**, not the source repo
3. Delete stale cache: `rm -rf ~/.claude/plugins/cache/labmate-marketplace/labmate/<old-version>`
4. Open a **new session** and run `/reload-plugins`

### marketplace.json not updating

Check that the marketplace repo is on `main` and has the latest commit:
```bash
cd ~/.claude/plugins/marketplaces/labmate-marketplace
git log --oneline -3
cat .claude-plugin/marketplace.json
```
