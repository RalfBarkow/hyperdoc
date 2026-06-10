#!/usr/bin/env bash
set -euo pipefail

system="${1:-:hyperdoc/server}"

echo "[check-lisp-load-gate] loading $system in a fresh SBCL"

env \
  -u CL_SOURCE_REGISTRY \
  -u ASDF_OUTPUT_TRANSLATIONS \
  nix develop --command sbcl \
    --no-userinit \
    --non-interactive \
    --eval '(require :asdf)' \
    --eval "(asdf:load-system $system :force t)" \
    --eval '(format t "~&LOAD_GATE_OK~%")' \
    --eval '(uiop:quit 0)'
