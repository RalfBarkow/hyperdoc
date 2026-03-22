#!/usr/bin/env bash
set -u

if command -v sbcl >/dev/null 2>&1; then
  exec sbcl --no-userinit --script tools/semantic-first-anchor-audit.lisp "$@"
elif command -v nix >/dev/null 2>&1; then
  exec nix develop --command sbcl --no-userinit --script tools/semantic-first-anchor-audit.lisp "$@"
else
  echo "Missing sbcl (or nix fallback) for semantic-first anchor audit." >&2
  exit 2
fi
