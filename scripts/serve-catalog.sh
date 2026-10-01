#!/usr/bin/env sh
set -eu

# Compatibility name; the packaged application supplies its own Lisp runtime.
exec hyperdoc-catalog "$@"
