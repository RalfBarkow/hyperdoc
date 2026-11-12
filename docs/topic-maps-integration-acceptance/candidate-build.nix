# Acceptance-only parameter override; neither PR implementation nor the active source expression is edited.
let
  flake = builtins.getFlake "git+file:///workspace/work/acceptance-pr42?rev=36c69d3312ae70748ecd40a5452759fcfaad25c4";
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  runtime = import (flake.outPath + "/nix/lisp-runtime.nix") {
    inherit pkgs;
    sources = flake.inputs;
    commonLispHyperSpec = flake.packages.x86_64-linux.common-lisp-hyperspec;
  };
  candidate = pkgs.runCommand "topic-maps-c446a822-acceptance-source" {
    nativeBuildInputs = [ pkgs.gnutar pkgs.gzip ];
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-d+qp4MmVOwHnEIRn3zzyIQhR/eUYCBos+XAu7OHs3/I=";
  } ''
    mkdir "$out"
    tar -xzf ${flake.outPath}/nix/topic-maps-c446a822-runtime.tar.gz -C "$out" --strip-components=1 --no-same-owner
  '';
in {
  inherit candidate;
  catalog = flake.packages.x86_64-linux.hyperdoc-catalog.override { topicMaps = candidate; };
  exporter-check = pkgs.runCommand "hyperdoc-instance-of-acceptance" {} ''
    export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$out"
    export CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${candidate}//:${flake.outPath}//"
    export TOPIC_MAPS_CANDIDATE_ROOT="${candidate}"
    ${runtime.sbcl}/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive \
      --load ${./nix-exporter.lisp} >"$out/exporter.log" 2>&1 \
      || { cat "$out/exporter.log"; exit 1; }
    cat "$out/exporter.log"
  '';
}
