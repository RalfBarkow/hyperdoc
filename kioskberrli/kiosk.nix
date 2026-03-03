{ config, pkgs, lib, ... }:

let
  url = "https://hauptsache.dreyeck.ch/assets/home/index.html";
in
{
  networking.hostName = "kioskberrli";
  time.timeZone = "Europe/Amsterdam";

  # Network: robust and practical for a kiosk you may need to reconfigure on-site.
  networking.networkmanager.enable = true;

  # Remote access (optional but recommended for maintenance)
  services.openssh.enable = true;

  users.users.kiosk = {
    isNormalUser = true;
    description = "Kiosk user";
    extraGroups = [ "video" "input" ];
  };

  # Wayland kiosk shell
  services.cage = {
    enable = true;
    user = "kiosk";
    program =
      "${pkgs.chromium}/bin/chromium " +
      "--kiosk --noerrdialogs --disable-infobars " +
      "--check-for-update-interval=31536000 " +
      "${lib.escapeShellArg url}";
  };

  # Self-heal after crashes / power loss
  systemd.services.cage-tty1.serviceConfig = {
    Restart = "always";
    RestartSec = "2s";
  };

  # Image size / compression
  sdImage = {
    compressImage = true;
    imageSize = 4096; # MiB
  };

  # NixOS release compatibility marker
  system.stateVersion = "25.11";
}
