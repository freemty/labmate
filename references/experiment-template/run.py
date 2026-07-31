"""Run experiment __EXP_ID__."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import yaml


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="exp/__EXP_ID__/config.yaml")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--resume")
    args = parser.parse_args()

    config = yaml.safe_load(Path(args.config).read_text(encoding="utf-8"))
    if args.dry_run:
        print(json.dumps(config, indent=2))
        return

    raise NotImplementedError("Implement the experiment body before launching")


if __name__ == "__main__":
    main()
