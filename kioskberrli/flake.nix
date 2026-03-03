{
  description = "Kioskberrli: NixOS SD image for Raspberry Pi 4 Model B kiosk";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "aarch64-linux";
  in
  {
    nixosConfigurations.kioskberrli = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # SD-card image builder (aarch64)
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"

        ./kiosk.nix
      ];
    };
  };
}
