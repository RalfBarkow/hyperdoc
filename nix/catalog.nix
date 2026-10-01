{ lib, writeShellApplication, git, runtime, source, d2-tala }:
writeShellApplication {
  name = "hyperdoc-catalog";
  runtimeInputs = [ git d2-tala ];
  text = ''
    # Explicit store sources, independent of shellHook, cwd and personal ASDF config.
    export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${source}//"
    export HYPERDOC_HYPERSPEC_ROOT="${runtime.hyperspecRoot}"
    exec ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit \
      --script ${source}/scripts/catalog-main.lisp "$@"
  '';
  meta = {
    description = "Dreyeck HyperBook Catalog with local FedWiki views";
    mainProgram = "hyperdoc-catalog";
    platforms = lib.platforms.unix;
  };
}
