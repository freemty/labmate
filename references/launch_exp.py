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

import re


def main() -> None:
    parser = argparse.ArgumentParser(description="Launch experiment runs")
    parser.add_argument("--exp", required=True, help="Experiment ID (e.g., exp01a)")
    parser.add_argument("--stagger", type=int, default=0, help="Seconds between job launches")
    parser.add_argument("--num-runs", type=int, default=1, help="Number of parallel runs")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without executing")
    args = parser.parse_args()

    if not re.fullmatch(r'exp[0-9]+[a-z]*', args.exp) or args.num_runs < 1 or args.stagger < 0:
        parser.error('invalid experiment ID, run count or stagger')
    exp_dir = Path(f"exp/{args.exp}")
    config_path = exp_dir / "config.yaml"
    run_script = exp_dir / "run.py"

    if not exp_dir.is_dir():
        print(f"Error: Experiment directory not found: {exp_dir}", file=sys.stderr)
        sys.exit(1)

    if not run_script.exists():
        print(f"Error: Run script not found: {run_script}", file=sys.stderr)
        sys.exit(1)

    if not config_path.is_file():
        parser.error(f"Config not found: {config_path}")
    print(f"Launching {args.num_runs} run(s) for {args.exp}")
    print(f"Config: {config_path}")

    if args.stagger > 0:
        print(f"Stagger: {args.stagger}s between launches")

    for i in range(args.num_runs):
        cmd = [sys.executable, str(run_script), "--config", str(config_path)]

        if args.dry_run:
            print(f"[DRY RUN] Job {i}: {' '.join(cmd)}")
        else:
            print(f"Launching job {i}...")
            process = subprocess.Popen(cmd)
            print(f"Job {i} PID: {process.pid}; completion not yet verified")

        if i < args.num_runs - 1 and args.stagger > 0:
            if not args.dry_run:
                time.sleep(args.stagger)

    print("Launch plan complete." if args.dry_run else "Launch requests sent; inspect each run for actual completion.")


if __name__ == "__main__":
    main()
