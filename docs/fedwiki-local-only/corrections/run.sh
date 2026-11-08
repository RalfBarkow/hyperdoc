#!/usr/bin/env bash
# A configured SBCL/ASDF closure (or SBCL wrapper) and strace are required.
# All fixture writes are temporary. The old review directory is read-only input.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(git -C "$HERE" rev-parse --show-toplevel)
OUT=${1:?usage: run.sh OUTPUT_DIRECTORY}; mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
SBCL=${SBCL:-sbcl}
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
cd "$ROOT"
export PR_TREE="$ROOT" PROBE_DIR="$WORK/probes"
mkdir -p "$PROBE_DIR"
python3 "$HERE/check.py" snapshot "$OUT/source-before.json"
run() {
  local name=$1 script=$2 trace=$3; shift 3
  local prefix=(); if [ "$trace" = yes ]; then prefix=(strace -f -qq -e trace=%network,mkdir -o "$OUT/$name.strace"); fi
  env "$@" "${prefix[@]}" "$SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load "$script" > "$OUT/$name.log" 2>&1
  echo "$name exit=0"
}
run integration scripts/test-fedwiki-local-only.lisp yes
run probes docs/fedwiki-local-only/review/probes/probes35.lisp yes
run regressions docs/defederation-consolidation/regressions.lisp no
run wiki-link docs/fedwiki-local-only/review/probes/suite.lisp no SUITE=dreyeck/wiki-link/tests
# The suite prints its condition and returns normally; check.py does not count SUITE-ERROR as a pass.
run reading docs/fedwiki-local-only/review/probes/suite.lisp no SUITE=dreyeck/work/reading/tests
python3 "$HERE/check.py" snapshot "$OUT/source-after.json"
cmp "$OUT/source-before.json" "$OUT/source-after.json"
python3 "$HERE/check.py" results "$OUT" | tee "$OUT/checks.log"
