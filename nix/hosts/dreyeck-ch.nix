{ ... }:
{
  imports = [ ../modules/hyperdoc-release.nix ];

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
}
