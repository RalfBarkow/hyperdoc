{ runCommand, python3, catalog, runtime, source }:
runCommand "catalog-startup-contract" { nativeBuildInputs = [ python3 ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${source}//"
  export HYPERDOC_HYPERSPEC_ROOT="${runtime.hyperspecRoot}"
  ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:test-system "dreyeck/catalog-application")' >lisp.log 2>&1 \
    || { cat lisp.log; exit 1; }
  python3 ${source}/tests/test_catalog_executable.py ${catalog}/bin/hyperdoc-catalog
  touch "$out"
''
