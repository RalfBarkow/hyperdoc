#!/bin/sh
# Integration test, run explicitly and never by the Nix check: the platform's real resolver is asked for a name that cannot exist, in an empty
# network namespace (unshare -rn), and the process must survive. Needs `unshare` (Linux). Its outcome depends on the resolver configuration.
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
nix develop "${HYPERDOC_DEVSHELL:-path:.#fedwiki-original-editor}" -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/catalog-application/tests")' \
  --eval '(dreyeck/catalog-application/tests:check-fedwiki-real-resolver-integration)'
