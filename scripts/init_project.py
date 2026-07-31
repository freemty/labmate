#!/usr/bin/env python3
"""Plan, apply, or verify a LabMate project skeleton.

The command is intentionally deterministic. The calling skill owns inference and
user confirmation; this script owns filesystem layout, idempotency, and parity.
"""

from __future__ import annotations

import argparse
import json
import shutil
from dataclasses import dataclass
from datetime import date
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parent.parent
REFERENCES = PLUGIN_ROOT / "references"


@dataclass(frozen=True)
class Target:
    instruction: Path
    project_skill: Path


TARGETS = {
    "codex": Target(Path("AGENTS.md"), Path(".agents/skills/project-skill")),
    "claude": Target(Path("CLAUDE.md"), Path(".claude/skills/project-skill")),
}


def render(path: Path, values: dict[str, str]) -> str:
    text = path.read_text(encoding="utf-8")
    for key, value in values.items():
        text = text.replace("{" + key + "}", value)
    return text


def target_names(value: str) -> list[str]:
    return ["codex", "claude"] if value == "both" else [value]


def mirror_conflicts(root: Path, names: list[str]) -> list[str]:
    if len(names) != 2:
        return []
    conflicts: list[str] = []
    for filename in ("SKILL.md", "CHANGELOG.md"):
        left = root / TARGETS["codex"].project_skill / filename
        right = root / TARGETS["claude"].project_skill / filename
        if left.exists() and right.exists() and left.read_bytes() != right.read_bytes():
            conflicts.append(f"project-skill mirrors differ: {filename}")
    return conflicts


def expected_files(project_type: str, names: list[str]) -> list[Path]:
    files = [
        Path(".pipeline-state.json"),
        Path("CHANGELOG.md"),
        Path("docs/specs/.gitkeep"),
        Path("docs/knowhow/infrastructure/.gitkeep"),
        Path("docs/knowhow/toolchain/.gitkeep"),
        Path("docs/knowhow/debug-solutions/.gitkeep"),
        Path("docs/knowhow/runbooks/.gitkeep"),
    ]
    for name in names:
        target = TARGETS[name]
        files.extend(
            [
                target.instruction,
                target.project_skill / "SKILL.md",
                target.project_skill / "CHANGELOG.md",
            ]
        )
    if project_type == "research":
        files.extend(
            [
                Path("exp/.gitkeep"),
                Path("exp/summary.md"),
                Path("docs/papers/.gitkeep"),
                Path("docs/papers/landscape.md"),
                Path("docs/weekly/.gitkeep"),
                Path("docs/archive/.gitkeep"),
                Path("scripts/launch_exp.py"),
                Path("scripts/monitor_exp.sh"),
                Path("scripts/download_results.sh"),
                Path("viewer/app.py"),
                Path("viewer/static/index.html"),
                Path("slides/.gitkeep"),
            ]
        )
    if len(names) == 2:
        files.append(Path("scripts/check_agent_parity.sh"))
    return files


def section_map(text: str) -> list[tuple[str, str]]:
    lines = text.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.startswith("## ")]
    sections: list[tuple[str, str]] = []
    for pos, start in enumerate(starts):
        end = starts[pos + 1] if pos + 1 < len(starts) else len(lines)
        title = lines[start].strip()
        sections.append((title, "".join(lines[start:end]).rstrip() + "\n"))
    return sections


def merge_missing_sections(existing: str, template: str) -> str:
    titles = {title for title, _ in section_map(existing)}
    missing = [body for title, body in section_map(template) if title not in titles]
    if not missing:
        return existing
    return existing.rstrip() + "\n\n" + "\n".join(missing)


def write_if_missing(root: Path, rel: Path, content: str, changes: list[dict]) -> None:
    path = root / rel
    if path.exists():
        changes.append({"path": str(rel), "action": "skip"})
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    changes.append({"path": str(rel), "action": "create"})


def sync_instruction(
    root: Path, rel: Path, content: str, changes: list[dict]
) -> None:
    path = root / rel
    if not path.exists():
        write_if_missing(root, rel, content, changes)
        return
    existing = path.read_text(encoding="utf-8")
    merged = merge_missing_sections(existing, content)
    if merged == existing:
        changes.append({"path": str(rel), "action": "skip"})
        return
    path.write_text(merged, encoding="utf-8")
    changes.append({"path": str(rel), "action": "append-sections"})


def append_gitignore(root: Path, project_type: str, changes: list[dict]) -> None:
    path = root / ".gitignore"
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    if project_type == "research":
        desired = (REFERENCES / "gitignore-rules.md").read_text(encoding="utf-8")
    else:
        desired = "# labmate rules\n.pipeline-state.json\n.labmate-hook-state.json\n"
    existing_rules = {
        line.strip()
        for line in existing.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    desired_lines = desired.splitlines()
    desired_rules = {
        line.strip()
        for line in desired_lines
        if line.strip() and not line.lstrip().startswith("#")
    }
    if desired_rules.issubset(existing_rules):
        changes.append({"path": ".gitignore", "action": "skip"})
        return
    additions: list[str] = []
    for line in desired_lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or stripped not in existing_rules:
            additions.append(line)
            if stripped and not stripped.startswith("#"):
                existing_rules.add(stripped)
    if not additions:
        changes.append({"path": ".gitignore", "action": "skip"})
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    prefix = "\n" if existing and not existing.endswith("\n") else ""
    path.write_text(existing + prefix + "\n".join(additions).rstrip() + "\n", encoding="utf-8")
    changes.append(
        {"path": ".gitignore", "action": "create" if not existing else "append"}
    )


def project_values(args: argparse.Namespace, skill_path: str) -> dict[str, str]:
    return {
        "project-name": args.project_name,
        "description": args.description,
        "domain": args.domain,
        "research-domain": args.domain,
        "compute_env": args.compute_env,
        "date": date.today().isoformat(),
        "project-skill-path": skill_path,
        "current_exp": "null",
    }


def apply(args: argparse.Namespace) -> list[dict]:
    root = args.root.resolve()
    names = target_names(args.target)
    conflicts = mirror_conflicts(root, names)
    if conflicts:
        raise ValueError("; ".join(conflicts))
    changes: list[dict] = []
    state = {
        "type": args.project_type,
        "project_name": args.project_name,
        "description": args.description,
        "domain": args.domain,
        "compute_env": args.compute_env,
        "current_exp": None,
        "stage": "dev",
        "skill_updated_at": None,
    }
    write_if_missing(
        root,
        Path(".pipeline-state.json"),
        json.dumps(state, ensure_ascii=False, indent=2) + "\n",
        changes,
    )
    write_if_missing(
        root,
        Path("CHANGELOG.md"),
        "# Changelog\n\n## Unreleased\n\n- Project initialized with LabMate\n",
        changes,
    )
    for rel in [
        Path("docs/specs/.gitkeep"),
        Path("docs/knowhow/infrastructure/.gitkeep"),
        Path("docs/knowhow/toolchain/.gitkeep"),
        Path("docs/knowhow/debug-solutions/.gitkeep"),
        Path("docs/knowhow/runbooks/.gitkeep"),
    ]:
        write_if_missing(root, rel, "", changes)

    existing_skill: Path | None = None
    for name in names:
        candidate = root / TARGETS[name].project_skill / "SKILL.md"
        if candidate.exists():
            existing_skill = candidate
            break

    for name in names:
        target = TARGETS[name]
        values = project_values(args, str(target.project_skill / "SKILL.md"))
        if existing_skill:
            skill_text = existing_skill.read_text(encoding="utf-8")
        else:
            skill_text = render(REFERENCES / "project-skill-template.md", values)
        write_if_missing(root, target.project_skill / "SKILL.md", skill_text, changes)
        write_if_missing(
            root,
            target.project_skill / "CHANGELOG.md",
            f"# project-skill CHANGELOG\n\n## {date.today().isoformat()} — v0\n\n"
            "Initial skeleton created by LabMate.\n",
            changes,
        )
        template_name = (
            "instruction-template-research.md"
            if args.project_type == "research"
            else "instruction-template-general.md"
        )
        sync_instruction(
            root,
            target.instruction,
            render(REFERENCES / template_name, values),
            changes,
        )

    if args.project_type == "research":
        for rel in [
            Path("exp/.gitkeep"),
            Path("docs/papers/.gitkeep"),
            Path("docs/weekly/.gitkeep"),
            Path("docs/archive/.gitkeep"),
            Path("slides/.gitkeep"),
        ]:
            write_if_missing(root, rel, "", changes)
        write_if_missing(
            root,
            Path("exp/summary.md"),
            "# Experiment Summary\n\n"
            "Cross-experiment flight recorder. One row per experiment.\n\n"
            "| Exp ID | Motivation | Status | Key Finding |\n"
            "|--------|------------|--------|-------------|\n",
            changes,
        )
        write_if_missing(
            root,
            Path("docs/papers/landscape.md"),
            f"# Domain Literature Landscape\n\n> Research domain: {args.domain}\n\n"
            "## Key Papers\n\n(none yet)\n\n## Research Gaps\n\n(none yet)\n",
            changes,
        )
        copies = {
            Path("scripts/launch_exp.py"): Path("launch_exp.py"),
            Path("scripts/monitor_exp.sh"): Path("monitor_exp.sh"),
            Path("scripts/download_results.sh"): Path("download_results.sh"),
            Path("viewer/app.py"): Path("viewer-app.py"),
            Path("viewer/static/index.html"): Path("viewer-static/index.html"),
        }
        for destination, source in copies.items():
            write_if_missing(
                root,
                destination,
                (REFERENCES / source).read_text(encoding="utf-8"),
                changes,
            )

    if len(names) == 2:
        write_if_missing(
            root,
            Path("scripts/check_agent_parity.sh"),
            (REFERENCES / "check_agent_parity.sh").read_text(encoding="utf-8"),
            changes,
        )
        parity = root / "scripts/check_agent_parity.sh"
        parity.chmod(parity.stat().st_mode | 0o111)

    append_gitignore(root, args.project_type, changes)
    return changes


def check(args: argparse.Namespace) -> tuple[list[str], list[str]]:
    root = args.root.resolve()
    names = target_names(args.target)
    missing = [
        str(path)
        for path in expected_files(args.project_type, names)
        if not (root / path).exists()
    ]
    errors = mirror_conflicts(root, names)
    return missing, errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("plan", "apply", "check"))
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--type", dest="project_type", choices=("general", "research"), required=True)
    parser.add_argument("--target", choices=("codex", "claude", "both"), required=True)
    parser.add_argument("--project-name", required=True)
    parser.add_argument("--description", required=True)
    parser.add_argument("--domain", default="general")
    parser.add_argument("--compute-env", default="local")
    args = parser.parse_args()

    if args.mode == "plan":
        names = target_names(args.target)
        root = args.root.resolve()
        payload = {
            "mode": "plan",
            "root": str(root),
            "existing": [
                str(path)
                for path in expected_files(args.project_type, names)
                if (root / path).exists()
            ],
            "missing": [
                str(path)
                for path in expected_files(args.project_type, names)
                if not (root / path).exists()
            ],
            "conflicts": mirror_conflicts(root, names),
        }
    elif args.mode == "apply":
        try:
            payload = {"mode": "apply", "changes": apply(args), "errors": []}
        except (OSError, ValueError) as error:
            payload = {"mode": "apply", "changes": [], "errors": [str(error)]}
    else:
        missing, errors = check(args)
        payload = {"mode": "check", "missing": missing, "errors": errors}

    print(json.dumps(payload, ensure_ascii=False, indent=2))
    failed = bool(payload.get("errors")) or (
        args.mode == "check" and bool(payload.get("missing"))
    )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
