#!/bin/sh
# The without-DNS experiment, end to end, from a checkout. Linux only (network namespaces); needs no network, no root and no production data.
#   scripts/check-fedwiki-without-dns.sh [--record]     --record also replaces docs/fedwiki-without-dns with this run's record and evidence
# What it does, in order:
#   1. the library and demo tests (process-local: a loopback server, an injected resolver; they need no namespace),
#   2. the experiment in two network namespaces joined by a veth pair, into a temporary directory,
#   3. a comparison of that run with the committed record (same outcomes and digests; times and versions may differ),
#   4. the browser walk Catalog -> demo HyperBook -> page -> Inspector observation (Chromium via $CHROMIUM or /opt/pw-browsers).
# `ip` (iproute2) comes from PATH or $IP; without either, nixpkgs' from this flake's pinned input is used.
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
if ! unshare -rn true 2>/dev/null; then
  echo "Network namespaces are not available here (unshare -rn fails)." >&2
  echo "The process-local part still runs: nix develop .#fedwiki-original-editor -c sbcl --non-interactive --eval '(require :asdf)' --eval '(asdf:test-system \"dreyeck/fedwiki-without-dns\")'" >&2
  echo "It reads a page through a given endpoint with the resolver injected to fail; it does not show a DNS failure of the real stack." >&2
  exit 2
fi
IPBIN="${IP:-$(command -v ip || true)}"
[ -n "$IPBIN" ] || IPBIN="$(nix build --inputs-from . nixpkgs#iproute2 --no-link --print-out-paths)/bin/ip"
out="$(mktemp -d "${TMPDIR:-/tmp}/fedwiki-without-dns-check.XXXXXX")"
nix develop .#fedwiki-original-editor -c sh -c '
  set -eu
  for system in dreyeck/fedwiki-without-dns dreyeck/fedwiki-without-dns-demo; do
    "$HYPERDOC_FEDWIKI_SBCL" --noinform --no-sysinit --no-userinit --non-interactive --eval "(require :asdf)" --eval "(asdf:test-system \"$system\")" 2>&1 | grep -E "^FEDWIKI-WITHOUT-DNS(-DEMO)?-PASS" 
  done
  IP="$1" python3 tests/fedwiki-without-dns/harness.py --out "$2/run"
  COMPARE_A=docs/fedwiki-without-dns/experiment-record.lisp-data COMPARE_B="$2/run/experiment-record.lisp-data" \
    "$HYPERDOC_FEDWIKI_SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load tests/fedwiki-without-dns/compare-records.lisp 2>&1 | grep -E "^RECORDS-"
  node tests/fedwiki-without-dns/e2e.mjs "$HYPERDOC_FEDWIKI_SBCL" "$2/browser" | grep "\"passed\""
' sh "$IPBIN" "$out"
if [ "${1:-}" = "--record" ]; then
  cp "$out/run/experiment-record.lisp-data" docs/fedwiki-without-dns/experiment-record.lisp-data
  cp "$out/run/evidence/"* docs/fedwiki-without-dns/evidence/
  echo "docs/fedwiki-without-dns replaced by this run."
fi
echo "outputs in $out"
