{ lib, ... }:
{
  warnings = [
    ''
      Using fallback hardware module for dreyeck-ch.
      Add nix/hosts/dreyeck-ch/hardware-configuration.nix for real host deployment.
    ''
  ];

  # Minimal fallback so nixosConfiguration evaluates in local migration phases.
  fileSystems."/" = lib.mkDefault {
    device = "none";
    fsType = "tmpfs";
  };

  boot.loader.grub.enable = lib.mkDefault false;
  boot.loader.systemd-boot.enable = lib.mkDefault false;
}
