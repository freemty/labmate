# Releasing LabMate

Version 0.11.0 uses four default lifecycle handlers. The canonical version is
`package.json`; synchronize both manifests and both README badges with
`python3 scripts/sync-version.py --write`, then verify with `--check`.

## Verification, not publication

```bash
bash scripts/release.sh --check
```

The default and only automated mode runs hook, platform, context, deterministic
script and available outer-marketplace checks. It never merges branches, pushes,
repairs installed registries or deletes caches. This replaces the older
release script's automatic local-install cleanup.

Run `tests/test-codex-plugin-smoke.sh /path/to/yuanbo-skills` separately when a
compatible Codex CLI is available. It uses temporary HOME/Codex directories.
Native model, browser/media and Claude named-agent behavior are separate live
checks; fixtures cannot establish them.

## Authorized publication sequence

Review all diffs and test evidence. Commit the LabMate repository first, then
update and commit the LabMate submodule pointer in yuanbo-skills. Publish only
the branches/tags and remotes the user authorized, and inspect outgoing commits.
Codex marketplace entries do not duplicate version; the manifest owns it.
The main-branch CI updates the configured Claude marketplace only after checks.

## Installation is a separate migration

Publishing does not authorize modifying the current machine. Before a requested
migration, inventory actual enabled registrations and global links, back up real
directories and registry metadata, then use the host's supported update path.
Do not fabricate installed cache paths or manually repair version/SHA fields.

Use plugin installation or legacy global symlinks, not both. The outer installer's
prune option removes only verified skill symlinks into that checkout, never real
directories. It does not clean an old real web-fetcher directory. See
[installing.md](installing.md) for installation paths and host-specific syntax.
Restart the host and review changed hooks after migration; keep the backup until
the new registration and task behavior are verified.
