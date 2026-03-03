# Kioskberrli (Raspberry Pi 4 Model B)

Build a reproducible NixOS SD-card image that boots and displays:

https://hauptsache.dreyeck.ch/assets/home/index.html

## Build

From repo root:

```sh
cd kioskberrli
nix build .#nixosConfigurations.kioskberrli.config.system.build.sdImage
```

The result is a compressed SD image in `result/`.

## Flash (example)

Decompress if needed and write to SD card, e.g. with `zstd -d` + `dd` or a GUI flasher.

## Notes

* Target: Raspberry Pi 4 Model B (ARM64 / aarch64-linux)
* Kiosk compositor: `services.cage`
* Browser: Chromium in `--kiosk` mode
