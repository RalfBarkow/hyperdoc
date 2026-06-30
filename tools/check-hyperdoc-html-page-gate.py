#!/usr/bin/env python3
"""Light gate for static repo-native HyperDoc HTML pages."""

from __future__ import annotations

import html
import re
import subprocess
import sys
from pathlib import Path


EXECUTABLE_MARKERS = (
    "expr=",
    "<html-expr",
    "<html-generator",
    "<view-transclusion",
    "<source-of-function",
    "<source-of-class",
    "<lisp-code",
    "<script",
    "javascript:",
    "asdf:load-system",
    "load-system",
    "defsystem",
)

H1_RE = re.compile(r"<h1\b[^>]*>(.*?)</h1>", re.IGNORECASE | re.DOTALL)
IN_PACKAGE_RE = re.compile(
    r"<in-package>\s*hyperdoc\s*</in-package>", re.IGNORECASE
)
TAG_RE = re.compile(r"<[^>]+>")


def staged_html_pages() -> list[str]:
    result = subprocess.run(
        [
            "git",
            "diff",
            "--cached",
            "--name-only",
            "--diff-filter=AM",
            "--",
            "hyperdoc/*.html",
        ],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    return [line for line in result.stdout.splitlines() if line]


def line_number(content: str, offset: int) -> int:
    return content.count("\n", 0, offset) + 1


def readable_h1_text(match: re.Match[str]) -> str:
    raw = match.group(1)
    without_tags = TAG_RE.sub("", raw)
    return html.unescape(without_tags).strip()


def is_direct_hyperdoc_html(path: Path) -> bool:
    parts = path.parts
    return len(parts) == 2 and parts[0] == "hyperdoc" and path.suffix == ".html"


def validate_page(path_text: str) -> list[str]:
    path = Path(path_text)
    errors: list[str] = []

    if not is_direct_hyperdoc_html(path):
        errors.append(f"{path_text}: not a direct hyperdoc/*.html page")
        return errors

    if not path.is_file():
        errors.append(f"{path_text}: file does not exist")
        return errors

    try:
        content = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        errors.append(f"{path_text}: not valid UTF-8: {exc}")
        return errors

    h1 = H1_RE.search(content)
    if h1 is None:
        errors.append(f"{path_text}: missing <h1> page title")
    elif not readable_h1_text(h1):
        errors.append(f"{path_text}: empty <h1> page title")

    if IN_PACKAGE_RE.search(content) is None:
        errors.append(f"{path_text}: missing <in-package>hyperdoc</in-package>")

    lowered = content.lower()
    for marker in EXECUTABLE_MARKERS:
        offset = lowered.find(marker)
        if offset != -1:
            errors.append(
                f"{path_text}:{line_number(content, offset)}: "
                f"executable/runtime marker {marker!r} requires the full gate"
            )

    return errors


def main(argv: list[str]) -> int:
    paths = argv[1:] or staged_html_pages()
    if not paths:
        print("HTML_PAGE_GATE_OK")
        print("CHECKED_PAGES=0")
        return 0

    all_errors: list[str] = []
    for path in paths:
        all_errors.extend(validate_page(path))

    if all_errors:
        print("HTML_PAGE_GATE_FAIL")
        for error in all_errors:
            print(f"ERROR {error}")
        return 1

    print("HTML_PAGE_GATE_OK")
    print(f"CHECKED_PAGES={len(paths)}")
    for path in paths:
        print(f"PAGE {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
