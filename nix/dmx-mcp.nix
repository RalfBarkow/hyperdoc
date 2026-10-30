# Opt-in, independent of the Catalog, Inspector, DMX backend and ISO reader packages.
{ lib, sbcl, writeShellApplication, source, revision ? "unrecorded" }:
let
  runtime = sbcl.withPackages (ps: with ps; [
    alexandria arrow-macros babel cl-ppcre drakma hunchentoot puri shasht
    trivial-package-local-nicknames
  ]);
in writeShellApplication {
  name = "hyperdoc-dmx-mcp";
  text = ''
    export CL_SOURCE_REGISTRY="${source}/"
    export ASDF_OUTPUT_TRANSLATIONS="${source}/:''${XDG_CACHE_HOME:-''${TMPDIR:-/tmp}}/hyperdoc-dmx-mcp/fasl/"
    export HYPERDOC_SOURCE_REVISION="${revision}"
    exec ${runtime}/bin/sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
      --script ${source}/scripts/dmx-mcp-main.lisp "$@"
  '';
  passthru = { inherit runtime; };
  meta = {
    description = "Independently loadable guarded DMX MCP application";
    mainProgram = "hyperdoc-dmx-mcp";
    platforms = lib.platforms.unix;
  };
}
