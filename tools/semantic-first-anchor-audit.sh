#!/usr/bin/env bash
set -u

host_sbcl_can_load_hyperdoc() {
  command -v sbcl >/dev/null 2>&1 || return 1
  sbcl --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(uiop:quit (if (ignore-errors (progn (asdf:load-system :hyperdoc) t)) 0 1))' \
    >/dev/null 2>&1
}

if host_sbcl_can_load_hyperdoc; then
  exec sbcl --no-userinit --script tools/semantic-first-anchor-audit.lisp "$@"
elif command -v nix >/dev/null 2>&1; then
  exec nix develop --command sbcl --no-userinit --script tools/semantic-first-anchor-audit.lisp "$@"
else
  echo "Missing sbcl (or nix fallback) for semantic-first anchor audit." >&2
  exit 2
fi
