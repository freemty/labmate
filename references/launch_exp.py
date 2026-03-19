"""Experiment orchestrator — launches experiment runs with stagger delay.

Usage:
    python scripts/launch_exp.py --exp exp01a
    python scripts/launch_exp.py --exp exp01a --stagger 10 --num-runs 5
    python scripts/launch_exp.py --exp exp01a --dry-run
"""
from __future__ import annotations
import argparse
import subprocess
import sys
import time
from pathlib import Path

import yaml


def main() -> None:
    parser = argparse.ArgumentParser(description="Launch experiment runs")
    parser.add_argument("--exp", required=True, help="Experiment ID (e.g., exp01a)")
    parser.add_argument("--stagger", type=int, default=0, help="Seconds between job launches")
    parser.add_argument("--num-runs", type=int, default=1, help="Number of parallel runs")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without executing")
    args = parser.parse_args()

    exp_dir = Path(f"exp/{args.exp}")
    config_path = exp_dir / "config.yaml"
    run_script = exp_dir / "run.py"

    if not exp_dir.is_dir():
        print(f"Error: Experiment directory not found: {exp_dir}", file=sys.stderr)
        sys.exit(1)

    if not run_script.exists():
        print(f"Error: Run script not found: {run_script}", file=sys.stderr)
        sys.exit(1)

    config = yaml.safe_load(config_path.read_text()) if config_path.exists() else {}
    print(f"Launching {args.num_runs} run(s) for {args.exp}")
    print(f"Config: {config.get('experiment', {}).get('name', 'unknown')}")

    if args.stagger > 0:
        print(f"Stagger: {args.stagger}s between launches")

    for i in range(args.num_runs):
        cmd = [sys.executable, str(run_script), "--config", str(config_path)]

        if args.dry_run:
            print(f"[DRY RUN] Job {i}: {' '.join(cmd)}")
        else:
            print(f"Launching job {i}...")
            subprocess.Popen(cmd)

        if i < args.num_runs - 1 and args.stagger > 0:
            if not args.dry_run:
                time.sleep(args.stagger)

    print("All jobs launched.")


if __name__ == "__main__":
    main()
