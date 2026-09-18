#!/bin/sh
# Run from a repository with the verified upstream object available locally.
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
nix develop path:. -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/workflow/upstream-intake")' \
  --eval '(assert (not (find-package :hyperdoc)))' \
  --eval '(assert (not (find-package :dreyeck/workflow/authoring)))' \
  --eval '(asdf:test-system "dreyeck/hyperdoc/boundary-tests")' \
  --eval '(asdf:test-system "dreyeck/hyperdoc/compatibility-tests")' \
  --eval '(asdf:test-system "dreyeck/hyperdoc/library-tests")' \
  --eval '(asdf:test-system "dreyeck/hyperspec/tests")' \
  --eval '(asdf:test-system "dreyeck/upstream-intake/tests")' \
  --eval '(asdf:test-system "dreyeck/wiki-link/tests")' \
  --eval '(asdf:test-system "dreyeck/fedwiki-navigation/tests")' \
  --eval '(asdf:test-system "dreyeck/page-attached-hyperdoc/tests")' \
  --eval '(asdf:test-system "dreyeck/fedwiki-hyperdoc/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/catalog/tests")'
nix develop path:.#tala -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/tests")' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/reading/tests")'
