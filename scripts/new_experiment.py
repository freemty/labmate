#!/usr/bin/env python3
"""Plan, scaffold, or verify one LabMate experiment directory."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_ROOT = PLUGIN_ROOT / "references" / "experiment-template"
EXP_RE = re.compile(r"^exp(\d{2})([a-z])$")


def validate_parent(root: Path, parent: str) -> re.Match[str]:
    match = EXP_RE.match(parent)
    if not match:
        raise ValueError(f"invalid parent experiment id: {parent}")
    if not (root / "exp" / parent).is_dir():
        raise ValueError(f"parent experiment does not exist: {parent}")
    return match


def next_id(root: Path, parent: str | None) -> str:
    if parent:
        match = validate_parent(root, parent)
        major, letter = match.groups()
        for codepoint in range(ord(letter) + 1, ord("z") + 1):
            candidate = f"exp{major}{chr(codepoint)}"
            if not (root / "exp" / candidate).exists():
                return candidate
        raise ValueError(f"no variant id remains after {parent}")
    majors = [
        int(match.group(1))
        for path in (root / "exp").glob("exp[0-9][0-9][a-z]")
        if (match := EXP_RE.match(path.name))
    ]
    return f"exp{(max(majors, default=0) + 1):02d}a"


def render(text: str, exp_id: str, motivation: str, relation: str) -> str:
    return (
        text.replace("__EXP_ID__", exp_id)
        .replace("__MOTIVATION__", motivation)
        .replace("__RELATION__", relation)
    )


def paths(root: Path, exp_id: str) -> list[Path]:
    base = root / "exp" / exp_id
    return [
        base / "README.md",
        base / "config.yaml",
        base / "run.py",
        base / "analyze.py",
        base / "results" / ".gitkeep",
        base / "results" / "runs.log",
    ]


def retarget_config(text: str, exp_id: str, motivation: str) -> str:
    """Update id/name inside a top-level experiment mapping without YAML deps."""
    lines = text.splitlines()
    start = next(
        (index for index, line in enumerate(lines) if line.strip() == "experiment:"),
        None,
    )
    if start is None:
        return (
            f"experiment:\n  id: {exp_id}\n"
            f"  name: {json.dumps(motivation, ensure_ascii=False)}\n\n{text}"
        )
    base_indent = len(lines[start]) - len(lines[start].lstrip())
    end = len(lines)
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        indent = len(lines[index]) - len(lines[index].lstrip())
        if stripped and indent <= base_indent:
            end = index
            break
    found_id = found_name = False
    for index in range(start + 1, end):
        stripped = lines[index].strip()
        indent = lines[index][: len(lines[index]) - len(lines[index].lstrip())]
        if stripped.startswith("id:"):
            lines[index] = f"{indent}id: {exp_id}"
            found_id = True
        elif stripped.startswith("name:"):
            lines[index] = (
                f"{indent}name: {json.dumps(motivation, ensure_ascii=False)}"
            )
            found_name = True
    insertion = []
    child_indent = " " * (base_indent + 2)
    if not found_id:
        insertion.append(f"{child_indent}id: {exp_id}")
    if not found_name:
        insertion.append(
            f"{child_indent}name: {json.dumps(motivation, ensure_ascii=False)}"
        )
    lines[end:end] = insertion
    return "\n".join(lines).rstrip() + "\n"


def apply(args: argparse.Namespace, exp_id: str) -> list[dict[str, str]]:
    root = args.root.resolve()
    state_path = root / ".pipeline-state.json"
    if not state_path.is_file():
        raise ValueError("LabMate is not initialized: .pipeline-state.json is missing")
    state = json.loads(state_path.read_text(encoding="utf-8"))
    if state.get("type") not in {None, "research"}:
        raise ValueError("new experiments require a research LabMate project")
    base = root / "exp" / exp_id
    if base.exists():
        raise FileExistsError(f"experiment already exists: {base}")
    relation = (
        f"Variant of `{args.parent}`."
        if args.parent
        else "First experiment in this direction."
    )
    changes: list[dict[str, str]] = []
    for name in ("README.md", "run.py", "analyze.py"):
        destination = base / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(
            render(
                (TEMPLATE_ROOT / name).read_text(encoding="utf-8"),
                exp_id,
                args.motivation,
                relation,
            ),
            encoding="utf-8",
        )
        changes.append({"path": str(destination.relative_to(root)), "action": "create"})

    config = base / "config.yaml"
    config.parent.mkdir(parents=True, exist_ok=True)
    parent_config = (
        root / "exp" / args.parent / "config.yaml" if args.parent else None
    )
    if parent_config and parent_config.exists():
        config.write_text(
            retarget_config(
                parent_config.read_text(encoding="utf-8"), exp_id, args.motivation
            ),
            encoding="utf-8",
        )
        action = "copy-parent"
    else:
        config.write_text(
            render(
                (TEMPLATE_ROOT / "config.yaml").read_text(encoding="utf-8"),
                exp_id,
                args.motivation,
                relation,
            ),
            encoding="utf-8",
        )
        action = "create"
    changes.append({"path": str(config.relative_to(root)), "action": action})

    results = base / "results"
    results.mkdir(parents=True, exist_ok=True)
    (results / ".gitkeep").write_text("", encoding="utf-8")
    (results / "runs.log").write_text(
        "# Format: timestamp label task_id result_path\n", encoding="utf-8"
    )
    changes.extend(
        [
            {"path": str((results / ".gitkeep").relative_to(root)), "action": "create"},
            {"path": str((results / "runs.log").relative_to(root)), "action": "create"},
        ]
    )

    summary = root / "exp" / "summary.md"
    summary.parent.mkdir(parents=True, exist_ok=True)
    if not summary.exists():
        summary.write_text(
            "# Experiment Summary\n\n"
            "| Exp ID | Motivation | Status | Key Finding |\n"
            "|--------|------------|--------|-------------|\n",
            encoding="utf-8",
        )
    summary_motivation = " ".join(args.motivation.split()).replace("|", "\\|")
    with summary.open("a", encoding="utf-8") as handle:
        handle.write(f"| {exp_id} | {summary_motivation} | In Progress | — |\n")
    changes.append({"path": "exp/summary.md", "action": "append"})

    state.update({"current_exp": exp_id, "stage": "experiment"})
    state_path.write_text(
        json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    changes.append({"path": ".pipeline-state.json", "action": "update"})
    return changes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("plan", "apply", "check"))
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--exp-id", default="auto")
    parser.add_argument("--parent")
    parser.add_argument("--motivation", required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        if args.parent:
            validate_parent(root, args.parent)
        exp_id = next_id(root, args.parent) if args.exp_id == "auto" else args.exp_id
    except ValueError as error:
        parser.error(str(error))
    if not EXP_RE.match(exp_id):
        parser.error("--exp-id must match expNNx")

    if args.mode == "plan":
        payload = {
            "mode": "plan",
            "exp_id": exp_id,
            "paths": [str(path.relative_to(root)) for path in paths(root, exp_id)],
            "exists": (root / "exp" / exp_id).exists(),
        }
    elif args.mode == "apply":
        try:
            payload = {
                "mode": "apply",
                "exp_id": exp_id,
                "changes": apply(args, exp_id),
                "errors": [],
            }
        except (OSError, ValueError, json.JSONDecodeError) as error:
            payload = {
                "mode": "apply",
                "exp_id": exp_id,
                "changes": [],
                "errors": [str(error)],
            }
    else:
        missing = [
            str(path.relative_to(root))
            for path in paths(root, exp_id)
            if not path.exists()
        ]
        payload = {"mode": "check", "exp_id": exp_id, "missing": missing}
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    failed = bool(payload.get("missing") or payload.get("errors"))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
