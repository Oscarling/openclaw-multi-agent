#!/usr/bin/env python3
"""Ledger sync guard.

If any core ledger is changed, require all core ledgers to be changed together:
- BACKLOG.md
- DECISIONS.md
- 验收清单.md
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGERS = {"BACKLOG.md", "DECISIONS.md", "验收清单.md"}


def run_lines(*cmd: str) -> set[str]:
    cp = subprocess.run(
        cmd,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True,
    )
    return {line.strip() for line in cp.stdout.splitlines() if line.strip()}


def all_changed_files() -> set[str]:
    changed = set()
    changed |= run_lines("git", "-c", "core.quotePath=false", "diff", "--name-only")
    changed |= run_lines(
        "git", "-c", "core.quotePath=false", "diff", "--cached", "--name-only"
    )
    changed |= run_lines(
        "git",
        "-c",
        "core.quotePath=false",
        "ls-files",
        "--others",
        "--exclude-standard",
    )
    return changed


def main() -> None:
    changed = all_changed_files()
    changed_ledgers = changed & LEDGERS

    if not changed_ledgers:
        print("[backlog-sync] ok: no ledger changes in working tree")
        return

    missing = sorted(LEDGERS - changed_ledgers)
    if missing:
        print(
            "[backlog-sync] fail: partial ledger update detected; "
            "please sync all three ledgers."
        )
        print(f"[backlog-sync] changed_ledgers={sorted(changed_ledgers)}")
        print(f"[backlog-sync] missing_ledgers={missing}")
        raise SystemExit(1)

    print("[backlog-sync] ok: core ledgers are synced")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        print(f"[backlog-sync] fail: command error: {exc}", file=sys.stderr)
        raise SystemExit(1)
