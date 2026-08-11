#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
mode=${1:-all}

case "$mode" in
  red)
    runner=dreyeck/wiki-link/contract-tests:run-wiki-link-slug-contract-test
    ;;
  all)
    runner=dreyeck/wiki-link/contract-tests:run-wiki-link-slug-contract-tests
    ;;
  *)
    printf 'Usage: %s [red|all]\n' "$0" >&2
    exit 2
    ;;
esac

cd "$repo_dir"

exec nix develop -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system :dreyeck/wiki-link/tests)' \
  --eval "($runner)"
