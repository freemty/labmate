# Pre-Launch Repo Optimization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the labmate repo release-ready by improving README conversion rate and adding project hygiene files.

**Architecture:** Pure file creation/editing — no code logic. README gets badges + comparison table + BibTeX. Project hygiene adds CONTRIBUTING.md, CODE_OF_CONDUCT.md, and GitHub issue templates.

**Tech Stack:** Markdown, YAML (issue templates)

**Spec:** `docs/specs/2026-03-20-pre-launch-repo-optimization-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `package.json` | Version 0.4.0 → 0.4.3 |
| Modify | `README.md` | Badges, GIF placeholder, comparison table, BibTeX |
| Modify | `README_ZH.md` | Chinese sync of all README changes |
| Create | `CONTRIBUTING.md` | Contributor guide |
| Create | `CODE_OF_CONDUCT.md` | Contributor Covenant v2.1 |
| Create | `.github/ISSUE_TEMPLATE/bug_report.yml` | Bug report form |
| Create | `.github/ISSUE_TEMPLATE/feature_request.yml` | Feature request form |
| Create | `.github/ISSUE_TEMPLATE/config.yml` | Blank issue option |

---

### Task 1: Version alignment

**Files:**
- Modify: `package.json:2` (version field)

- [ ] **Step 1: Update version**

In `package.json`, change:
```json
"version": "0.4.0",
```
to:
```json
"version": "0.4.3",
```

- [ ] **Step 2: Verify consistency**

Run: `grep -r '"version"' package.json .claude-plugin/plugin.json`
Expected: both show `0.4.3`

- [ ] **Step 3: Commit**

```bash
git add package.json
git commit -m "chore: align package.json version to 0.4.3"
```

---

### Task 2: README.md overhaul

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add badge row + GIF placeholder**

After line 1 (`# LabMate`), before the blank line, insert:

```markdown

![version](https://img.shields.io/badge/version-0.4.3-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![agents](https://img.shields.io/badge/agents-7-orange)
![skills](https://img.shields.io/badge/skills-7-orange)

<!-- TODO: 30s demo GIF — record with VHS or asciinema -->
```

- [ ] **Step 2: Add comparison table**

Between `## Workflow` (ends at line 63) and `## Customization` (line 65), insert:

```markdown
## How it compares

| Feature | labmate | [K-Dense](https://github.com/K-Dense-AI/claude-scientific-skills) | [Orchestra](https://github.com/Orchestra-Research/AI-Research-SKILLs) | [ARIS](https://github.com/conglu1997/ARIS) |
|---------|---------|---------|-----------|------|
| Deep paper reading | Yes | No | No | No |
| Experiment design | Yes | No | Partial | No |
| Research memory/context | Yes | No | No | No |
| ML experiment tracking | Yes | No | Yes | Yes |
| Paper writing pipeline | Partial | No | Partial | Partial |
| Cross-discipline support | Yes | Bio/Chem | ML/AI only | ML only |
```

- [ ] **Step 3: Add BibTeX entry**

Before `## License` section, insert a `## Citing` heading followed by a bibtex code block containing:

```
@software{labmate2026,
  title   = {LabMate: Research Harness for Claude Code},
  author  = {freemty},
  year    = {2026},
  version = {0.4.3},
  url     = {https://github.com/freemty/labmate}
}
```

Note: In the actual file, wrap the BibTeX content in a fenced code block with `bibtex` language tag.

- [ ] **Step 4: Verify README renders correctly**

Run: `head -20 README.md` to spot-check badge row is in place.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: add badges, comparison table, and BibTeX to README"
```

---

### Task 3: README_ZH.md sync

**Files:**
- Modify: `README_ZH.md`

- [ ] **Step 1: Add badge row + GIF placeholder**

After line 1 (`# LabMate`), insert the same badge row as README.md (badges are language-neutral).

- [ ] **Step 2: Add comparison table**

Between `## 工作流` (ends at line 63) and `## 定制` (line 65), insert:

```markdown
## 横向对比

| 功能 | labmate | [K-Dense](https://github.com/K-Dense-AI/claude-scientific-skills) | [Orchestra](https://github.com/Orchestra-Research/AI-Research-SKILLs) | [ARIS](https://github.com/conglu1997/ARIS) |
|------|---------|---------|-----------|------|
| 论文深度阅读 | Yes | No | No | No |
| 实验设计 | Yes | No | Partial | No |
| 研究记忆/上下文 | Yes | No | No | No |
| ML 实验追踪 | Yes | No | Yes | Yes |
| 论文写作 pipeline | Partial | No | Partial | Partial |
| 跨学科支持 | Yes | 生物/化学 | 仅 ML/AI | 仅 ML |
```

- [ ] **Step 3: Add BibTeX entry**

Before `## License` section, insert a `## 引用` heading followed by a bibtex code block containing:

```
@software{labmate2026,
  title   = {LabMate: Research Harness for Claude Code},
  author  = {freemty},
  year    = {2026},
  version = {0.4.3},
  url     = {https://github.com/freemty/labmate}
}
```

Note: In the actual file, wrap the BibTeX content in a fenced code block with `bibtex` language tag.

- [ ] **Step 4: Commit**

```bash
git add README_ZH.md
git commit -m "docs: sync badges, comparison table, and BibTeX to README_ZH"
```

---

### Task 4: CONTRIBUTING.md

**Files:**
- Create: `CONTRIBUTING.md`

- [ ] **Step 1: Create file**

```markdown
# Contributing to LabMate

Thanks for your interest in contributing! LabMate is a pure-Markdown Claude Code plugin — no build step, no dependencies.

## Quick start

1. Fork and clone the repo
2. Add the plugin to your Claude Code settings:
   ```json
   {
     "plugins": ["/path/to/your/labmate"]
   }
   ```
3. Create a branch: `git checkout -b feat/your-feature`
4. Make changes
5. Commit using conventional commits (see below)
6. Open a PR

## What you can contribute

**Agents** (`agents/*.md`):
- One Markdown file per agent
- Frontmatter: name, description, model (haiku/sonnet/opus)
- Keep under 400 lines

**Skills** (`skills/<name>/SKILL.md`):
- One directory per skill, with a `SKILL.md` file
- Frontmatter: name, description
- Follow the existing skill structure

**Hooks** (`hooks/`):
- Shell scripts (extensionless) in hooks/
- Register in `hooks/hooks.json`

## Commit format

```
<type>: <description>

Types: feat, fix, refactor, docs, test, chore
```

## Code conventions

- Pure Markdown — no runtime dependencies
- Files under 400 lines
- Test changes by installing the plugin locally and running the relevant skill/agent

## Finding work

Check issues labeled [`good first issue`](https://github.com/freemty/labmate/labels/good%20first%20issue) for starter tasks.

## Questions?

Open an issue — there are no dumb questions.
```

- [ ] **Step 2: Commit**

```bash
git add CONTRIBUTING.md
git commit -m "docs: add CONTRIBUTING.md"
```

---

### Task 5: CODE_OF_CONDUCT.md

**Files:**
- Create: `CODE_OF_CONDUCT.md`

- [ ] **Step 1: Create file**

Use Contributor Covenant v2.1 verbatim. Enforcement contact: GitHub issues on this repo.

Full text at: https://www.contributor-covenant.org/version/2/1/code_of_conduct/

- [ ] **Step 2: Commit**

```bash
git add CODE_OF_CONDUCT.md
git commit -m "docs: add CODE_OF_CONDUCT.md (Contributor Covenant v2.1)"
```

---

### Task 6: GitHub issue templates

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/ISSUE_TEMPLATE/feature_request.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`

- [ ] **Step 1: Create bug_report.yml**

```yaml
name: Bug Report
description: Report a bug in LabMate
labels: ["bug"]
body:
  - type: textarea
    id: description
    attributes:
      label: Description
      description: What happened?
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      description: How can we reproduce this?
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
      description: What did you expect to happen?
    validations:
      required: true
  - type: input
    id: cc-version
    attributes:
      label: Claude Code version
      placeholder: "e.g. 1.0.12"
    validations:
      required: true
  - type: dropdown
    id: os
    attributes:
      label: Operating system
      options:
        - macOS
        - Linux
        - Windows (WSL)
        - Other
    validations:
      required: true
  - type: input
    id: related
    attributes:
      label: Related skill or agent (optional)
      placeholder: "e.g. @domain-expert, /labmate:analyze-experiment"
```

- [ ] **Step 2: Create feature_request.yml**

```yaml
name: Feature Request
description: Suggest a feature or improvement
labels: ["enhancement"]
body:
  - type: textarea
    id: description
    attributes:
      label: Description
      description: What would you like to see?
    validations:
      required: true
  - type: textarea
    id: use-case
    attributes:
      label: Use case
      description: How would this help your research workflow?
    validations:
      required: true
  - type: dropdown
    id: contribute
    attributes:
      label: Would you be willing to contribute a PR?
      options:
        - "Yes"
        - "No"
        - Maybe — I'd need guidance
    validations:
      required: true
```

- [ ] **Step 3: Create config.yml**

```yaml
blank_issues_enabled: true
```

- [ ] **Step 4: Commit**

```bash
git add .github/
git commit -m "docs: add GitHub issue templates (bug report + feature request)"
```

---

### Task 7: Post-push — create good first issues

**Prerequisite:** Code is pushed to GitHub.

- [ ] **Step 1: Create issues with `good first issue` label**

```bash
gh issue create --title "Add Zotero integration to domain-expert agent" --label "good first issue" --body "domain-expert currently reads papers from local files. Add optional Zotero integration to pull papers from a user's Zotero library."
gh issue create --title "Add --dry-run flag to init-project skill" --label "good first issue" --body "Let users preview what init-project would create without actually writing files."
gh issue create --title "Chinese localization for tutorial.md" --label "good first issue" --body "Translate docs/tutorial.md to Chinese, similar to README_ZH.md."
gh issue create --title "Add experiment tagging/filtering to summary.md" --label "good first issue" --body "When experiments accumulate, users need to filter by tag (e.g. domain, method). Add tag support to exp/summary.md format."
gh issue create --title "Create demo recording with asciinema or VHS" --label "good first issue" --body "Record a 30-second demo GIF showing the init → new-experiment → analyze workflow. See README placeholder."
gh issue create --title "Add session-start hook test script" --label "good first issue" --body "Create a test script that verifies the session-start hook outputs correct context for different .pipeline-state.json states."
```

- [ ] **Step 2: Create `help wanted` issue**

```bash
gh issue create --title "Support Gemini CLI / Codex tool mapping" --label "help wanted" --body "Add cross-platform support so labmate skills work in Gemini CLI and Codex, not just Claude Code. Requires tool name mapping and conditional instructions."
```
