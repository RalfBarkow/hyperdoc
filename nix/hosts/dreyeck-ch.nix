{ ... }:
{
  imports = [
    ../modules/hyperdoc-release.nix
    ../modules/hyperdoc-mcp-release.nix
  ];

  # Host-specific deployment profile for dreyeck.ch.
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
    enableLiveWrites = false;
    allowedOrigins = [
      "https://dreyeck.ch"
      "https://mcp.dreyeck.ch"
    ];
    reverseProxyHost = "mcp.dreyeck.ch";
    reverseProxyPath = "/mcp";
  };

  security.acme.acceptTerms = true;
  security.acme.certs."mcp.dreyeck.ch".email = "ralf.barkow@me.com";
}
