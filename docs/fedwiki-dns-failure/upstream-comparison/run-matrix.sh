#!/bin/bash
# The same thirteen scenarios against several checkouts of hyperbook/fedwiki, each in a fresh SBCL under `unshare -rn`.
#   run-matrix.sh LABEL=CHECKOUT ...            (inside `nix develop .#fedwiki-original-editor`, which provides the SBCL and the registry)
# A checkout is any tree with hyperbook.asd: this repository at some commit, or an upstream checkout. Prints one row per checkout:
# the outcome of every scenario, S(tatus type) when the process survived and DIED(exit status) when it did not.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
scenarios="probe-real probe-try-again probe-no-recovery probe-host-not-found sitemap-try-again sitemap-no-recovery sitemap-host-not-found probe-nodata sitemap-nodata probe-network-unreachable sitemap-network-unreachable probe-unknown sitemap-unknown"
printf 'checkout'; for s in $scenarios; do printf '\t%s' "$s"; done; echo
for pair in "$@"; do
  label="${pair%%=*}"; tree="${pair#*=}"
  printf '%s' "$label"
  for s in $scenarios; do
    out=$(CHECKOUT="$tree" SCENARIO="$s" unshare -rn "$HYPERDOC_FEDWIKI_SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load "$here/scenario.lisp" 2>&1)
    status=$?
    if echo "$out" | grep -q "^SURVIVED"; then printf '\t%s' "S($(echo "$out" | grep '^SURVIVED' | sed 's/.*status=//;s/ printable=yes//;s/ printable=NO/, UNPRINTABLE/;s/USOCKET://;s/SB-BSD-SOCKETS://'))"
    else printf '\t%s' "DIED($status) $(echo "$out" | grep -m1 -o 'Unhandled [A-Z:-]*' | sed 's/Unhandled //;s/USOCKET://;s/SB-BSD-SOCKETS://')"; fi
  done
  echo
done
