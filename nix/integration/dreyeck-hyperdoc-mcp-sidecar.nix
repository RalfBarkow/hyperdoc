{ lib, pkgs, ... }:
let
  hyperdocRepo = /home/rgb/workspace/hyperdoc;
  hyperdocFlake = builtins.getFlake (toString hyperdocRepo);
in
{
  # Temporary recovery bridge only.
  #
  # Final steady-state path:
  # 1. run tools/install-dreyeck-hyperdoc-mcp-sidecar.sh
  # 2. install host-owned copies under /etc/nixos/hyperdoc
  # 3. import the host-owned /etc/nixos/hyperdoc/dreyeck-hyperdoc-mcp-sidecar.nix
  #
  # Keep this repo-import path only as a short-lived escape hatch if the
  # host-owned copy is missing and recovery must happen quickly.
  imports = [
    (hyperdocRepo + "/nix/modules/hyperdoc-mcp-release.nix")
  ];

  services.hyperdocMcp = {
    enable = true;
    package = hyperdocFlake.packages.${pkgs.system}.hyperdoc-release;
    bindAddress = "127.0.0.1";
    port = 8787;
    dataDir = "/var/lib/hyperdoc/mcp";
    workspaceTopicmapId = 919822;
    dmxBaseUrl = "https://dmx.ralfbarkow.ch";
    enableLiveWrites = false;
    allowedOrigins = [
      "https://mcp.dreyeck.ch"
    ];
    reverseProxyHost = "mcp.dreyeck.ch";
    reverseProxyPath = "/mcp";
  };

  security.acme.certs."mcp.dreyeck.ch".email =
    lib.mkDefault "ralf.barkow@me.com";
}
