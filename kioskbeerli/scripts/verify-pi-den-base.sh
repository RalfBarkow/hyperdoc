#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'usage: %s guest@<pi-ip>\n' "$0" >&2
  exit 64
fi

target=$1

ssh "$target" '
set -eu

echo "--- host ---"
hostname

echo "--- current system ---"
readlink /run/current-system || true

echo "--- system profile ---"
readlink /nix/var/nix/profiles/system || true

echo "--- root filesystem ---"
findmnt -no SOURCE / || true

echo "--- disk ---"
df -h /

echo "--- failed units ---"
systemctl --failed --no-pager || true

echo "--- jobs ---"
systemctl list-jobs --no-pager || true

if [ -d /etc/nixos ]; then
  cd /etc/nixos

  echo "--- flake show ---"
  nix --extra-experimental-features "nix-command flakes" flake show

  echo "--- effective NixOS hostname ---"
  nix --extra-experimental-features "nix-command flakes" \
    eval --raw .#nixosConfigurations.kioskbeerli-pi.config.networking.hostName
  echo

  echo "--- Den hostname ---"
  nix --extra-experimental-features "nix-command flakes" \
    eval --raw --expr "(import ./nix/den/kioskbeerli.nix).\"kioskbeerli-pi\".hostName"
  echo
else
  echo "--- flake show ---"
  echo "/etc/nixos is missing"
fi
'
