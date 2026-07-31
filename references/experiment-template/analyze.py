"""Summarize runs logged for __EXP_ID__."""

from __future__ import annotations

import json
from pathlib import Path


def main() -> None:
    results = Path("exp/__EXP_ID__/results")
    records = []
    for path in sorted(results.glob("*.json")):
        records.append({"path": str(path), "result": json.loads(path.read_text())})

    lines = ["# __EXP_ID__ Results Summary", "", f"Result files: {len(records)}", ""]
    for record in records:
        lines.append(f"- `{record['path']}`")
    output = results / "summary.md"
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
