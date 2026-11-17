# The production Catalog carries the Topic Maps snapshot in its ASDF registry.
# Its startup verifies the snapshot before loading the application and its standard readings.
{ lib, writeShellApplication, git, runtime, source, topicMaps, d2-tala, revision }:
writeShellApplication {
  name = "hyperdoc-catalog";
  runtimeInputs = [ git d2-tala ];
  text = ''
    # Explicit store sources, independent of shellHook, cwd and personal ASDF config.
    export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${topicMaps}//:${source}//"
    export HYPERDOC_HYPERSPEC_ROOT="${runtime.hyperspecRoot}"
    # HyperDoc's revision as the flake states it (self.rev, or self.dirtyRev); the store source has no .git.
    export HYPERDOC_SOURCE_REVISION="${revision}"
    exec ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit \
      --script ${source}/scripts/catalog-main.lisp "$@"
  '';
  meta = {
    description = "Dreyeck HyperBook Catalog with local FedWiki views and the pinned Topic Maps snapshot";
    mainProgram = "hyperdoc-catalog";
    platforms = lib.platforms.unix;
  };
}
