#!/usr/bin/env python3
"""Typed CRUD interface for docs/TODO.md."""

from __future__ import annotations

import argparse
import json
import re
from datetime import date
from pathlib import Path


PRIORITIES = ("P0", "P1", "P2", "P3")
ITEM_RE = re.compile(
    r"^- \[(?P<done>[ x])\] (?P<text>.*?)(?: <!-- (?P<date>\d{4}-\d{2}-\d{2}) -->)?$"
)


def empty_document() -> str:
    blocks = ["# TODO", ""]
    for priority in PRIORITIES:
        blocks.extend([f"## {priority}", ""])
    return "\n".join(blocks).rstrip() + "\n"


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(empty_document(), encoding="utf-8")


def add(path: Path, priority: str, text: str) -> None:
    text = " ".join(text.split())
    if not text:
        raise ValueError("task text must not be empty")
    content = path.read_text(encoding="utf-8")
    if any(
        line.startswith("- [ ]") and ITEM_RE.match(line)
        and ITEM_RE.match(line).group("text").casefold() == text.casefold()
        for line in content.splitlines()
    ):
        raise ValueError(f"open task already exists: {text}")
    heading = f"## {priority}\n"
    item = f"- [ ] {text} <!-- {date.today().isoformat()} -->\n"
    if heading not in content:
        content = content.rstrip() + f"\n\n{heading}\n"
    content = content.replace(heading, heading + "\n" + item, 1)
    path.write_text(content, encoding="utf-8")


def mark_done(path: Path, query: str) -> str:
    lines = path.read_text(encoding="utf-8").splitlines()
    matches = [
        index
        for index, line in enumerate(lines)
        if line.startswith("- [ ]") and query.casefold() in line.casefold()
    ]
    if len(matches) != 1:
        raise ValueError(f"expected one open match for {query!r}, found {len(matches)}")
    index = matches[0]
    lines[index] = lines[index].replace("- [ ]", "- [x]", 1)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return lines[index]


def clean(path: Path) -> int:
    lines = path.read_text(encoding="utf-8").splitlines()
    kept = [line for line in lines if not line.startswith("- [x]")]
    removed = len(lines) - len(kept)
    path.write_text("\n".join(kept).rstrip() + "\n", encoding="utf-8")
    return removed


def list_items(path: Path) -> list[dict[str, str | bool]]:
    priority = ""
    items: list[dict[str, str | bool]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            priority = line[3:].strip()
            continue
        match = ITEM_RE.match(line)
        if match:
            items.append(
                {
                    "priority": priority,
                    "done": match.group("done") == "x",
                    "text": match.group("text"),
                    "date": match.group("date") or "",
                }
            )
    return items


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    subparsers = parser.add_subparsers(dest="operation", required=True)
    add_parser = subparsers.add_parser("add")
    add_parser.add_argument("text")
    add_parser.add_argument("--priority", choices=PRIORITIES, default="P1")
    done_parser = subparsers.add_parser("done")
    done_parser.add_argument("query")
    subparsers.add_parser("list")
    subparsers.add_parser("clean")
    args = parser.parse_args()
    path = args.root.resolve() / "docs" / "TODO.md"
    ensure(path)

    try:
        if args.operation == "add":
            add(path, args.priority, args.text)
            payload = {
                "operation": "add",
                "priority": args.priority,
                "text": " ".join(args.text.split()),
            }
        elif args.operation == "done":
            payload = {"operation": "done", "item": mark_done(path, args.query)}
        elif args.operation == "clean":
            payload = {"operation": "clean", "removed": clean(path)}
        else:
            payload = {"operation": "list", "items": list_items(path)}
    except ValueError as error:
        payload = {"operation": args.operation, "error": str(error)}
    payload["path"] = str(path)
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 2 if "error" in payload else 0


if __name__ == "__main__":
    raise SystemExit(main())
