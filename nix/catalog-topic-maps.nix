# hyperdoc-catalog-topic-maps: the Catalog with the pinned Topic Maps snapshot in its ASDF registry, for loopback staging.
# A separate executable: nix/catalog.nix and the hyperdoc-catalog it builds are unchanged and never see topic-maps.
{ lib, writeShellApplication, git, runtime, source, topicMaps, d2-tala, revision }:
writeShellApplication {
  name = "hyperdoc-catalog-topic-maps";
  runtimeInputs = [ git d2-tala ];
  text = ''
    # Explicit store sources, as in hyperdoc-catalog, and the verified Topic Maps snapshot.
    export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${topicMaps}//:${source}//"
    export HYPERDOC_HYPERSPEC_ROOT="${runtime.hyperspecRoot}"
    # HyperDoc's revision as the flake states it (self.rev, or self.dirtyRev); the store source has no .git.
    export HYPERDOC_SOURCE_REVISION="${revision}"
    exec ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit \
      --script ${source}/scripts/catalog-topic-maps-main.lisp "$@"
  '';
  meta = {
    description = "Dreyeck HyperBook Catalog with the pinned Topic Maps snapshot, loopback only";
    mainProgram = "hyperdoc-catalog-topic-maps";
    platforms = lib.platforms.unix;
  };
}
