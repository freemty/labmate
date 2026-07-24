#!/usr/bin/env python3
"""Keep LabMate package, manifests, and README badges on one version."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "package.json"
MANIFESTS = [
    ROOT / ".claude-plugin" / "plugin.json",
    ROOT / ".codex-plugin" / "plugin.json",
]
READMES = [ROOT / "README.md", ROOT / "README_ZH.md"]
BADGE_PATTERN = re.compile(r"version-\d+\.\d+\.\d+-blue")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="verify parity")
    mode.add_argument("--write", action="store_true", help="sync from package.json")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    version = json.loads(PACKAGE.read_text())["version"]
    problems: list[str] = []

    for path in MANIFESTS:
        data = json.loads(path.read_text())
        if data.get("version") != version:
            if args.write:
                data["version"] = version
                path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
            else:
                problems.append(f"{path.relative_to(ROOT)}: {data.get('version')}")

    expected_badge = f"version-{version}-blue"
    for path in READMES:
        content = path.read_text()
        if expected_badge not in content:
            if args.write:
                updated, count = BADGE_PATTERN.subn(expected_badge, content, count=1)
                if count != 1:
                    problems.append(f"{path.relative_to(ROOT)}: version badge not found")
                else:
                    path.write_text(updated)
            else:
                problems.append(f"{path.relative_to(ROOT)}: version badge differs")

    if problems:
        print("version parity check failed:")
        for problem in problems:
            print(f"- {problem}")
        return 1

    action = "synced" if args.write else "verified"
    print(f"version parity {action}: {version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
