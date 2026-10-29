# The hyperdoc-catalog contract, in the build sandbox: no network, an empty HOME and compilation cache, and the package's own
# registry, which holds the verified Topic Maps snapshot. Its output keeps the logs of this run.
{ runCommand, python3, catalog, runtime, source, topicMaps, revision }:
runCommand "catalog-startup-contract" { nativeBuildInputs = [ python3 ]; } ''
  export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache"
  mkdir -p "$HOME" "$XDG_CACHE_HOME" "$out"
  export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${topicMaps}//:${source}//"
  export HYPERDOC_HYPERSPEC_ROOT="${runtime.hyperspecRoot}"
  export HYPERDOC_SOURCE_REVISION="${revision}"
  ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:test-system "dreyeck/catalog-application")' >"$out/application.log" 2>&1 \
    || { cat "$out/application.log"; exit 1; }
  python3 ${source}/tests/test_conversation_sources.py
  # Topic Maps: every system from the verified snapshot, the startup guard, and the views a served Catalog offers.
  export HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE=nix-store-snapshot
  ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive \
    --load ${source}/scripts/test-catalog-topic-maps.lisp >"$out/lisp.log" 2>&1 \
    || { cat "$out/lisp.log"; exit 1; }
  grep -q '^CATALOG-TOPIC-MAPS-PACKAGE-PASS$' "$out/lisp.log"
  # The views a served Catalog offers, one by one, served and developing.
  ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:test-system "dreyeck/topic-maps-public-views")' >"$out/public-views.log" 2>&1 \
    || { cat "$out/public-views.log"; exit 1; }
  grep -q '^TOPIC-MAPS-PUBLIC-VIEWS-PASS' "$out/public-views.log"
  unset HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE
  # ASDF's own methods before and after the startup policy is loaded: the same objects, the same behaviour, in a fresh process.
  ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive \
    --load ${source}/scripts/test-asdf-method-preservation.lisp >"$out/asdf-methods.log" 2>&1 \
    || { cat "$out/asdf-methods.log"; exit 1; }
  grep -q '^ASDF-METHOD-PRESERVATION-PASS' "$out/asdf-methods.log"
  # No other topic-maps.asd anywhere in the registry: one Topic Maps per image.
  for tree in $(echo "$CL_SOURCE_REGISTRY" | tr ':' ' '); do
    find "''${tree%//}" -name topic-maps.asd 2>/dev/null
  done | sort -u >"$out/topic-maps-asd"
  test "$(cat "$out/topic-maps-asd")" = "${topicMaps}/topic-maps.asd"
  python3 ${source}/tests/test_catalog_executable.py ${catalog}/bin/hyperdoc-catalog >"$out/executable.log" 2>&1 \
    || { cat "$out/executable.log"; exit 1; }
''
