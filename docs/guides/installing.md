# Installing and Updating LabMate

> User guide for installing, updating, and verifying LabMate.

## Prerequisites

- Claude Code CLI or OpenAI Codex CLI installed
- Git configured (for marketplace cloning)

## Install

### Claude Code

```
/plugin marketplace add freemty/labmate-marketplace
/plugin install labmate@labmate-marketplace
```

Then in your research project:
```
/labmate:init-project
```

### Recommended companions

```
/plugin install superpowers
/plugin install frontend-slides
/plugin install agent-reach
```

### OpenAI Codex

For a local checkout of the `yuanbo-skills` marketplace:

```bash
codex plugin marketplace add /path/to/yuanbo-skills
codex plugin add labmate@yuanbo-skills
```

Start a new Codex session after installation. Plugin hooks are not trusted just
because the plugin is enabled: open `/hooks`, review the LabMate definitions,
and trust the current hashes before expecting lifecycle reminders to run.

Use `/skills` or type `$labmate:init-project` to initialize the project.

Do not also link LabMate's plugin skills into `~/.agents/skills`; that registers
the same skill twice. If this repository's legacy installer created those
links, run:

```bash
./install.sh --target codex --prune-plugin-skill-links
```

Use `--include-plugin-skills` only with an older Codex build that cannot install
plugins.

## Update

### Claude Code

```
/plugin update
```

Then **open a new session** and run:
```
/reload-plugins
```

The current session caches the plugin path at startup. `/reload-plugins` in the same session will re-fetch content but still use the old path. A new session is required.

### OpenAI Codex

For a Git marketplace, refresh the marketplace snapshot and reinstall the
plugin version:

```bash
codex plugin marketplace upgrade yuanbo-skills
codex plugin add labmate@yuanbo-skills
```

For a local marketplace, the source checkout is already current; rerun
`codex plugin add labmate@yuanbo-skills` to refresh the installed snapshot.
Open a new session and review `/hooks` again because changed hook hashes require
new trust.

### Verify

Invoke any LabMate skill. Claude Code uses `/labmate:todo list`; Codex uses
`$labmate:todo list` or `/skills`.

Or check directly:
```
/plugin
```

On Codex:

```bash
codex plugin list
bash plugins/labmate/tests/test-hooks.sh
bash plugins/labmate/tests/test-codex-plugin-smoke.sh
```

Then use `/hooks` in an interactive Codex session and confirm the LabMate
`PreToolUse`, `PostToolUse`, and `SessionStart` commands are trusted.

## Troubleshooting

### Still loading old version after /plugin update

1. **Open a new session** first. This is the most common fix.

2. Check for stale project-scope installs:
```bash
grep -A5 "labmate@labmate-marketplace" ~/.claude/plugins/installed_plugins.json
```
If a `project` scope entry has an old version or installPath, update it manually or reinstall:
```
/plugin uninstall labmate@labmate-marketplace
/plugin install labmate@labmate-marketplace
```

3. Delete stale cache:
```bash
ls ~/.claude/plugins/cache/labmate-marketplace/labmate/
# Should only have the current version. Delete old ones:
rm -rf ~/.claude/plugins/cache/labmate-marketplace/labmate/<old-version>
```

### Skills not showing up

Run `/reload-plugins` in a new session. If skills still don't appear, check that the plugin is enabled:
```bash
grep labmate ~/.claude/settings.json
```
The value should not be `false`.

### "plugin not found" error

Ensure the marketplace is added:
```
/plugin marketplace add freemty/labmate-marketplace
```
Then install again.

### Codex skills load but hook reminders do not appear

1. Run `codex features list` and confirm `hooks` is enabled.
2. Open `/hooks` and trust the current LabMate hook hashes.
3. Start a new session after installing or updating the plugin.
4. Run `bash plugins/labmate/tests/test-hooks.sh` from the marketplace checkout
   to validate both Codex and Claude Code hook payloads.

### Codex shows each LabMate skill twice

The plugin and legacy global skill links are both active. From the
`yuanbo-skills` checkout, run:

```bash
./install.sh --target codex --prune-plugin-skill-links
```

Restart Codex and confirm each `labmate:<skill>` appears once.
