# Pre-Launch Repo Optimization

Date: 2026-03-20
Status: Approved

## Goal

Make labmate repo release-ready for external users. Focus on star conversion rate (README) and contributor retention (project hygiene).

## Scope

GIF recording is explicitly OUT of scope — deferred to later.

---

## 1. README Overhaul

### 1a. Badge row (after title, before problem section)

Static badges for now; replace with dynamic after GitHub push:

```
![version](https://img.shields.io/badge/version-0.4.3-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![agents](https://img.shields.io/badge/agents-7-orange)
![skills](https://img.shields.io/badge/skills-7-orange)
```

### 1b. Demo GIF placeholder

Invisible HTML comment below badges:

```html
<!-- TODO: 30s demo GIF — record with VHS or asciinema -->
```

### 1c. Comparison table

New section `## How it compares` after `What's inside`.

Competitors with links:
- [K-Dense Scientific Skills](https://github.com/K-Dense-AI/claude-scientific-skills) (~5,700 stars)
- [Orchestra AI Research SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)
- [ARIS (Auto-Research-In-Sleep)](https://github.com/aris-org/aris) (early stage)

| Feature | labmate | K-Dense | Orchestra | ARIS |
|---------|---------|---------|-----------|------|
| Deep paper reading | Yes | No | No | No |
| Experiment design | Yes | No | Partial | No |
| Research memory/context | Yes | No | No | No |
| ML experiment tracking | Yes | No | Yes | Yes |
| Paper writing pipeline | Partial | No | Partial | Partial |
| Cross-discipline support | Yes | Bio/Chem | ML/AI only | ML only |

### 1d. BibTeX entry

New section `## Citing` before License:

```bibtex
@software{labmate2026,
  title   = {LabMate: Research Harness for Claude Code},
  author  = {freemty},
  year    = {2026},
  version = {0.4.3},
  url     = {https://github.com/freemty/labmate}
}
```

### 1e. README_ZH.md sync

Apply all changes (badges, comparison table, BibTeX) to Chinese version with localized section headings.

### 1f. Version alignment

`package.json` version: 0.4.0 -> 0.4.3 to match `.claude-plugin/plugin.json`.

---

## 2. Project Hygiene Files

### 2a. CONTRIBUTING.md

Under 80 lines. Sections:
- How to contribute (fork -> branch -> PR)
- Dev setup (clone + add plugin path to settings.json)
- Code conventions (pure Markdown, no dependencies)
- Commit format (conventional commits: feat/fix/docs/refactor)
- Three contribution types: agents (.md in agents/), skills (SKILL.md in skills/<name>/), hooks (script in hooks/)
- Pointer to `good first issue` label

### 2b. CODE_OF_CONDUCT.md

Contributor Covenant v2.1 verbatim. Contact: GitHub issues.

### 2c. .github/ISSUE_TEMPLATE/

**bug_report.yml:**
- Fields: description, steps to reproduce, expected behavior, Claude Code version, OS, related skill/agent (optional)

**feature_request.yml:**
- Fields: description, use case, willing to contribute PR (yes/no)

**config.yml:**
- Blank issue option for other types

No PR template.

---

## 3. Good First Issues (post-push)

Create via `gh issue create` with `good first issue` label:

Label `good first issue`:
1. Add Zotero integration to domain-expert agent
2. Add `--dry-run` flag to init-project skill
3. Chinese localization for tutorial.md
4. Add experiment tagging/filtering to summary.md
5. Create demo recording with asciinema/VHS
6. Add session-start hook test script

Label `help wanted` (higher complexity):
7. Support Gemini CLI / Codex tool mapping

---

## Execution Order

1. Version alignment (package.json)
2. README badge row + GIF placeholder + comparison table + BibTeX
3. README_ZH.md sync
4. CONTRIBUTING.md
5. CODE_OF_CONDUCT.md
6. .github/ISSUE_TEMPLATE/ (3 files)
7. Commit all
8. After push: create good first issues
