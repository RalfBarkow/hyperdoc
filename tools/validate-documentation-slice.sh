#!/usr/bin/env bash
set -u

host_sbcl_can_load_hyperdoc() {
  command -v sbcl >/dev/null 2>&1 || return 1
  sbcl --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(uiop:quit (if (ignore-errors (progn (asdf:load-system :hyperdoc) t)) 0 1))' \
    >/dev/null 2>&1
}

run_documentation_validation() {
  if host_sbcl_can_load_hyperdoc; then
    sbcl --no-userinit --script tools/validate-documentation-slice.lisp "$@"
  elif command -v nix >/dev/null 2>&1; then
    nix develop --command sbcl --no-userinit --script tools/validate-documentation-slice.lisp "$@"
  elif command -v sbcl >/dev/null 2>&1; then
    sbcl --no-userinit --script tools/validate-documentation-slice.lisp "$@"
  else
    echo "Missing sbcl (or nix fallback) for documentation validation." >&2
    return 2
  fi
}

run_documentation_validation "$@" || exit $?
./tools/semantic-first-anchor-audit.sh
