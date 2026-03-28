{ lib, pkgs, ... }:
let
  hyperdocRepo = /home/rgb/workspace/hyperdoc;
  hyperdocFlake = builtins.getFlake (toString hyperdocRepo);
in
{
  # Import this file from /etc/nixos to add HyperDoc MCP beside the existing
  # workspace-based hyperdoc.service deployment on dreyeck.
  #
  # The HyperDoc repo remains responsible for the reusable MCP package and
  # module. The host's authoritative system definition stays in /etc/nixos.
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
