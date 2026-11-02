# The library ownership contract that needs no Git history: the fork's library paths against the manifest of upstream's definitions (docs/code-ownership/manifest.lisp-data)
# and the inventory that says why each difference stands (docs/code-ownership/inventory.lisp-data). It reads a source snapshot (cleanSource: no .git), in the build
# sandbox: no network, no history, no Git binary. The history-based comparison (dreyeck/hyperdoc/library-tests) needs the retained upstream objects and cannot run here.
{ runCommand, runtime, source }:
runCommand "library-inventory-contract" { } ''
  export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache"
  mkdir -p "$HOME" "$XDG_CACHE_HOME" "$out"
  export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${source}//"
  test ! -e ${source}/.git   # a snapshot, not a repository
  ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit --script ${source}/scripts/code-ownership.lisp --check >"$out/inventory.log" 2>&1 \
    || { cat "$out/inventory.log"; exit 1; }
  grep -q 'uninventoried: 0; problems: 0' "$out/inventory.log"
''
