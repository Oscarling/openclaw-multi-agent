#!/usr/bin/env python3
"""Lightweight ledger lint for backlog/acceptance markdown files."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGERS = [ROOT / "BACKLOG.md", ROOT / "验收清单.md", ROOT / "DECISIONS.md"]
CHECKBOX_RE = re.compile(r"^- \[( |x)\] ")


def fail(msg: str) -> None:
    print(f"[backlog-lint] fail: {msg}", file=sys.stderr)
    raise SystemExit(1)


def lint_checkbox_file(path: Path) -> tuple[int, int]:
    checked = 0
    unchecked = 0
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.rstrip()
        if line.startswith("- ["):
            if not CHECKBOX_RE.match(line):
                fail(f"{path.name}:{lineno} malformed checkbox item")
            if line.startswith("- [x]"):
                checked += 1
            else:
                unchecked += 1
    return checked, unchecked


def main() -> None:
    for p in LEDGERS:
        if not p.exists():
            fail(f"missing ledger file: {p.name}")

    backlog_checked, backlog_unchecked = lint_checkbox_file(ROOT / "BACKLOG.md")
    ac_checked, ac_unchecked = lint_checkbox_file(ROOT / "验收清单.md")

    print("[backlog-lint] ok")
    print(
        f"[backlog-lint] BACKLOG checked={backlog_checked} unchecked={backlog_unchecked}"
    )
    print(
        f"[backlog-lint] 验收清单 checked={ac_checked} unchecked={ac_unchecked}"
    )


if __name__ == "__main__":
    main()
