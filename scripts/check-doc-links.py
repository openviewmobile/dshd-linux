#!/usr/bin/env python3
"""Check relative links and images in Markdown files.

External URLs are not fetched (CI must stay offline-friendly). Fenced code
blocks and inline code are ignored so examples do not create false positives.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {".git", "dist", "node_modules", "__pycache__"}
LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
FENCE = re.compile(r"```.*?```", re.S)
INLINE_CODE = re.compile(r"`[^`]*`")


def clean_target(raw: str) -> str:
    target = raw.strip()
    if target.startswith("<") and ">" in target:
        target = target[1:target.index(">")]
    else:
        target = target.split()[0]
    return unquote(target.split("#", 1)[0].split("?", 1)[0])


def main() -> int:
    bad: list[tuple[Path, str]] = []
    for md in sorted(ROOT.rglob("*.md")):
        if any(part in SKIP_DIRS for part in md.parts):
            continue
        text = FENCE.sub("", md.read_text(encoding="utf-8", errors="ignore"))
        text = INLINE_CODE.sub("", text)
        for match in LINK.finditer(text):
            target = clean_target(match.group(1))
            if not target or "://" in target or target.startswith(("mailto:", "tel:")):
                continue
            if not (md.parent / target).resolve().exists():
                bad.append((md.relative_to(ROOT), target))
    for md, target in bad:
        print(f"{md}: missing {target}", file=sys.stderr)
    if bad:
        print(f"{len(bad)} broken relative link(s)", file=sys.stderr)
        return 1
    print("relative documentation links: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
