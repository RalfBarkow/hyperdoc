{ ... }:
{
  imports = [
    ../modules/hyperdoc-release.nix
    ../modules/hyperdoc-mcp-release.nix
  ];

  # Historical full-host deployment profile for dreyeck.ch.
  #
  # Production activation on the live host remains authoritative in /etc/nixos.
  # For MCP on the real host, install host-owned copies into /etc/nixos via
  # tools/install-dreyeck-hyperdoc-mcp-sidecar.sh and import the resulting
  # /etc/nixos/hyperdoc/dreyeck-hyperdoc-mcp-sidecar.nix there instead of
  # switching this full profile.
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/sda" ];
  networking.useDHCP = false;
  networking.interfaces.ens3.useDHCP = true;
  time.timeZone = "Europe/Zurich";
  system.stateVersion = "20.09";

  services.hyperdoc = {
    enable = true;
    enableZotero = false;
    serviceName = "hyperdoc";
    bindAddress = "127.0.0.1";
    port = 8080;
    reverseProxyDomain = "dreyeck.ch";
    publicOrigin = "https://dreyeck.ch";
    dataDir = "/var/lib/hyperdoc/data";
    gitRepositoryRoot = "/home/rgb/workspace/hyperdoc";
  };

  services.hyperdocMcp = {
    enable = true;
    serviceName = "hyperdoc-mcp";
    bindAddress = "127.0.0.1";
    port = 8787;
    dataDir = "/var/lib/hyperdoc/mcp";
    workspaceTopicmapId = 919822;
    dmxBaseUrl = "https://dmx.ralfbarkow.ch";
    dmxWorkspaceId = 919815;
    dmxImportEnvironmentFile = "-/etc/nixos/hyperdoc/dmx-import.env";
    enableLiveWrites = false;
    allowedOrigins = [
      "https://dreyeck.ch"
      "https://mcp.dreyeck.ch"
    ];
    reverseProxyHost = "mcp.dreyeck.ch";
    reverseProxyPath = "/mcp";
    useACMEHost = "dreyeck.ch";
  };

  security.acme.acceptTerms = true;
}
