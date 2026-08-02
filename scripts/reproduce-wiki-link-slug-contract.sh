#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
mode=${1:-all}

case "$mode" in
  red)
    runner=hyperbook/fedwiki/tests:run-wiki-link-slug-contract-test
    ;;
  all)
    runner=hyperbook/fedwiki/tests:run-wiki-link-slug-contract-tests
    ;;
  *)
    printf 'Usage: %s [red|all]\n' "$0" >&2
    exit 2
    ;;
esac

cd "$repo_dir"

exec nix develop "path:$repo_dir" -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system :clog)' \
  --eval '(asdf:load-asd (truename "hyperbook.asd"))' \
  --eval '(asdf:load-system :hyperbook/fedwiki)' \
  --eval '(load (truename "tests/wiki-link-slug-contract.lisp"))' \
  --eval "($runner)"
