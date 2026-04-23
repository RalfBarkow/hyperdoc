#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

EXPECTED_UPSTREAM_SHA256 = {
    "source/clog-element.lisp": "5d664613906c8defb7a10c81603a7e0eedb45dab038de17bed8461d692afe901",
    "static-files/boot.html": "8652a2d77ea7b3a0a520cd345858ecb36ea1b44b4cb2a6da5c8354d59e7d584a",
    "static-files/js/boot.js": "e0f1b9d914e8e3520bb35049d32ce87ee674aab9f0e69ea61b2f75f29670bd7d",
}


def normalize_newlines(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def sha256_normalized(text: str) -> str:
    return hashlib.sha256(normalize_newlines(text).encode("utf-8")).hexdigest()


def apply_override(root: Path, overlay_root: Path, relative_path: str) -> None:
    target = root / relative_path
    overlay = overlay_root / relative_path
    label = f"clog:{relative_path}"

    if not target.exists():
        raise SystemExit(f"{label} missing from unpacked source tree")
    if not overlay.exists():
        raise SystemExit(f"{label} missing from vendored override tree")

    current = target.read_text()
    desired = overlay.read_text()

    current_sha = sha256_normalized(current)
    desired_sha = sha256_normalized(desired)
    expected_upstream_sha = EXPECTED_UPSTREAM_SHA256[relative_path]

    if current_sha == desired_sha:
        print(f"{label}: already at vendored content ({desired_sha})")
        return

    if current_sha != expected_upstream_sha:
        raise SystemExit(
            f"{label} upstream snapshot mismatch: expected {expected_upstream_sha} "
            f"or vendored {desired_sha}, got {current_sha}"
        )

    target.write_text(desired)
    print(f"{label}: replaced upstream snapshot {current_sha} -> {desired_sha}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Apply deterministic vendored CLOG source overrides."
    )
    parser.add_argument(
        "--overlay-root",
        type=Path,
        required=True,
        help="Path to vendored override tree (nix/vendor/clog).",
    )
    args = parser.parse_args()

    root = Path(".").resolve()
    overlay_root = args.overlay_root.resolve()

    for relative_path in sorted(EXPECTED_UPSTREAM_SHA256):
        apply_override(root, overlay_root, relative_path)


if __name__ == "__main__":
    main()
