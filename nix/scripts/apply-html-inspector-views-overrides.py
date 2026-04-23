#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

EXPECTED_UPSTREAM_SHA256 = {
    "assets/html-inspector-views/js/process-graphviz-elements.js": "6d473aab0e649924fdfc9809e530a1403fac09284ca2942e927df2186b5478f8",
    "package.lisp": "6e43f754e4112931cdf9eabd37f25a74d22dcaf3f595856ae1110ab0ac138512",
    "view-support.lisp": "861e3c9e53be74085b2799061caa0ec8b9dc2bef825e8bd00794481cbad5562f",
}

FILES_TO_ENSURE = [
    "package.lisp",
    "view-support.lisp",
    "assets/html-inspector-views/js/process-graphviz-elements.js",
    "assets/html-inspector-views/css/graphviz.css",
    "assets/html-inspector-views/js/graphviz.js",
]


def normalize_newlines(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def sha256_normalized(text: str) -> str:
    return hashlib.sha256(normalize_newlines(text).encode("utf-8")).hexdigest()


def apply_override(root: Path, overlay_root: Path, relative_path: str) -> None:
    target = root / relative_path
    overlay = overlay_root / relative_path
    label = f"html-inspector-views:{relative_path}"

    if not overlay.exists():
        raise SystemExit(f"{label} missing from vendored override tree")

    desired = overlay.read_text()
    desired_sha = sha256_normalized(desired)
    expected_upstream_sha = EXPECTED_UPSTREAM_SHA256.get(relative_path)

    if target.exists():
        current = target.read_text()
        current_sha = sha256_normalized(current)

        if current_sha == desired_sha:
            print(f"{label}: already at vendored content ({desired_sha})")
            return

        if expected_upstream_sha is None:
            raise SystemExit(
                f"{label} exists with unexpected content ({current_sha}); "
                f"expected missing file or vendored {desired_sha}"
            )

        if current_sha != expected_upstream_sha:
            raise SystemExit(
                f"{label} upstream snapshot mismatch: expected {expected_upstream_sha} "
                f"or vendored {desired_sha}, got {current_sha}"
            )

        target.write_text(desired)
        print(f"{label}: replaced upstream snapshot {current_sha} -> {desired_sha}")
        return

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(desired)
    print(f"{label}: created vendored file ({desired_sha})")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Apply deterministic vendored html-inspector-views overrides."
    )
    parser.add_argument(
        "--overlay-root",
        type=Path,
        required=True,
        help="Path to vendored override tree (nix/vendor/html-inspector-views).",
    )
    args = parser.parse_args()

    root = Path(".").resolve()
    overlay_root = args.overlay_root.resolve()

    for relative_path in FILES_TO_ENSURE:
        apply_override(root, overlay_root, relative_path)


if __name__ == "__main__":
    main()
