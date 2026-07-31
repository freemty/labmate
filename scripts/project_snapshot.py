#!/usr/bin/env python3
"""Collect bounded project facts for update-project-skill."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path


def run(root: Path, *args: str) -> str:
    result = subprocess.run(
        args,
        cwd=root,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    return result.stdout.strip()


def read_headings(path: Path) -> list[str]:
    if not path.exists():
        return []
    return [
        line.strip()
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines()
        if line.startswith("#")
    ][:40]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--max-files", type=int, default=200)
    args = parser.parse_args()
    root = args.root.resolve()
    tracked = run(root, "git", "ls-files").splitlines()[: args.max_files]
    experiments = []
    for path in sorted((root / "exp").glob("exp[0-9][0-9][a-z]")):
        experiments.append(
            {
                "id": path.name,
                "readme_headings": read_headings(path / "README.md"),
                "has_summary": (path / "results" / "summary.md").exists(),
            }
        )
    payload = {
        "root": str(root),
        "branch": run(root, "git", "branch", "--show-current"),
        "recent_commits": run(root, "git", "log", "-10", "--format=%h %s").splitlines(),
        "tracked_files": tracked,
        "pipeline_state": (
            json.loads((root / ".pipeline-state.json").read_text(encoding="utf-8"))
            if (root / ".pipeline-state.json").exists()
            else None
        ),
        "experiments": experiments,
        "summary_headings": read_headings(root / "exp" / "summary.md"),
        "todo_headings": read_headings(root / "docs" / "TODO.md"),
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
