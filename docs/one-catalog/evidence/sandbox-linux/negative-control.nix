# The walk's negative control (negative-control.lisp) in the same sandbox and environment as checks.x86_64-linux.catalog.
#   nix build --impure -f docs/one-catalog/evidence/sandbox-linux/negative-control.nix --argstr flake "git+file://$PWD" -L
# It succeeds only if CHECK-REACHABLE-CONTROLS fails against a development server.
{ flake }:
let
  check = (builtins.getFlake flake).checks.x86_64-linux.catalog;
  lines = builtins.filter builtins.isString (builtins.split "\n" check.buildCommand);
  setup = builtins.filter (l: builtins.match " *(export (HOME|CL_SOURCE_REGISTRY|HYPERDOC_HYPERSPEC_ROOT|HYPERDOC_SOURCE_REVISION)=.*|mkdir .*)" l != null) lines;
  sbcl = builtins.head (builtins.match ".*(/nix/store/[^ ]*-sbcl-with-packages/bin/sbcl).*" check.buildCommand);
in check.overrideAttrs (old: {
  name = "walk-negative-control";
  # An empty substring keeps the original command's store references, which builtins.match drops.
  buildCommand = builtins.substring 0 0 old.buildCommand + builtins.concatStringsSep "\n" setup + ''

    export HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE=nix-store-snapshot
    ${sbcl} --noinform --no-sysinit --no-userinit --non-interactive --load ${./negative-control.lisp} >"$out/negative-control.log" 2>&1 \
      || { cat "$out/negative-control.log"; exit 1; }
    grep '^WALK\|^NEGATIVE-CONTROL' "$out/negative-control.log"
    grep -q '^NEGATIVE-CONTROL-FAILS-AS-EXPECTED' "$out/negative-control.log"
  '';
})
