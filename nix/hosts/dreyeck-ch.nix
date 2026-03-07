{ ... }:
{
  imports = [ ../modules/hyperdoc-release.nix ];

  # Host-specific deployment profile for dreyeck.ch.
  services.hyperdoc = {
    enable = true;
    serviceName = "hyperdoc";
    bindAddress = "127.0.0.1";
    port = 8080;
    reverseProxyDomain = "dreyeck.ch";
    publicOrigin = "https://dreyeck.ch";
    dataDir = "/var/lib/hyperdoc/data";
  };
}
