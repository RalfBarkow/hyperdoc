# Kioskbeerli Den base-system milestone

This page records the current Raspberry Pi Kioskbeerli Den base-system
milestone and the local reconstruction boundary. It is documentation only: it
does not mutate the Pi, write DMX, enable sops-nix, enable kiosk mode, force the
hostname, or commit generated backup state.

## Verified target state

Hardware and host context:

- Raspberry Pi target: `guest@192.168.178.34`
- Runtime hostname: `myhostname`
- Den intended hostname: `kioskbeerli`

NixOS state at the checkpoint:

- Current system:
  `/nix/store/qa4s1sfd2xkzyg1z6mllyg96np7yi7y5-nixos-system-myhostname-24.11.20250630.50ab793`
- System profile: `system-3-link`
- Root filesystem: `/dev/disk/by-label/NIXOS_SD`
- Disk at checkpoint: `8.6G` free, `38%` used
- Failed systemd units: `0`
- Systemd jobs: none
- Result: Den-based flake switch survived reboot

Flake state:

- `/etc/nixos/flake.nix` exists on the Pi.
- `/etc/nixos/flake.lock` exists on the Pi.
- `flake show` exposes `nixosConfigurations.kioskbeerli-pi`.
- The effective NixOS hostname evaluates to `myhostname`.
- The Den hostname evaluates to `kioskbeerli`.

## Local backup

The local operator backup is:

```text
var/kioskbeerli-pi-backup/
```

It is intentionally under `var/` and must not be committed unless explicitly
requested. The backup contains:

```text
MILESTONE.txt
etc-nixos/
  configuration.nix
  flake.nix
  flake.lock
  README.kioskbeerli-den.md
  nix/den/kioskbeerli.nix
  nix/nixos/hosts/kioskbeerli-pi.nix
  nix/nixos/modules/kiosk-cage-chromium.nix
  nix/nixos/modules/raspberry-pi4-sd.nix
  nix/nixos/modules/secrets-sops.nix
  nix/nixos/modules/ssh-operator.nix
```

The files that define the Den/Dendritic Nix scaffold are:

- `etc-nixos/flake.nix`
- `etc-nixos/nix/den/kioskbeerli.nix`
- `etc-nixos/nix/nixos/hosts/kioskbeerli-pi.nix`
- `etc-nixos/nix/nixos/modules/ssh-operator.nix`
- staged but inactive modules:
  `secrets-sops.nix`, `kiosk-cage-chromium.nix`, and
  `raspberry-pi4-sd.nix`

## Intentionally postponed

These items are not done yet:

- `sops-nix` secrets are not implemented.
- `secrets-sops.nix` is staged but inactive.
- `kiosk-cage-chromium.nix` is staged but inactive.
- `raspberry-pi4-sd.nix` is staged but inactive.
- Hostname forcing is not enabled; the effective runtime hostname remains
  `myhostname`.
- Kiosk mode, Cage, and Chromium are not enabled yet.
- No live DMX writes or DMX/Neo4j synchronization are part of this milestone.

The next safe task is to create encrypted `sops-nix` secrets. The first secret
is:

```text
users/guest/hashed-password
```

The plan-only ASDF subsystem for that next mutation is:

```lisp
(asdf:load-system :kioskbeerli/sops-nix-secrets)
(kioskbeerli/sops-nix-secrets:make-sops-nix-secrets-session)
```

It is documented in `hyperdoc/Kioskbeerli sops-nix secrets.html`. The subsystem
is inspectable only by default: it does not run `ssh`, `sudo`, `sops`,
`nixos-rebuild`, or DMX writes, and it does not contain cleartext secrets or
password hashes.

## Pending optional hardware acceleration milestone

A separate future milestone is to add the pinned `nixos-hardware` Raspberry Pi
4 module for hardware-specific support:

```text
Add pinned nixos-hardware Raspberry Pi 4 module
```

The tutorial-style import uses an unpinned tarball from the moving `master`
branch:

```nix
imports = [
  "${fetchTarball "https://github.com/NixOS/nixos-hardware/tarball/master"}/raspberry-pi/4"
];
```

Do not use that form in the Den/flake configuration. The future Kioskbeerli
change should add a pinned flake input instead:

```nix
inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
```

and then import the module through the flake input:

```nix
inputs.nixos-hardware.nixosModules.raspberry-pi-4
```

This milestone is not implemented yet. It belongs after the verified Den
base-system milestone and before, or separate from, kiosk/Cage/Chromium
enablement. It should be reviewed as its own small step so hardware support can
be validated independently from browser kiosk behavior.

Required validation before any `switch`:

```sh
nix flake show
nixos-rebuild test --flake .#kioskbeerli-pi
```

Do not run `switch` for this milestone until the flake output and test rebuild
have both been inspected.

## Verify from SLY/HyperDoc

Use this read-only SLY/MREPL sequence when the
`kioskbeerli-den-executable-dita` package is loaded in the operator image:

```lisp
(in-package #:kioskbeerli-den-executable-dita)

(kb-status)
(kb-flake-show)
(kb-flake-eval-hostname)
(kb-den-eval-hostname)

(ssh/bash
 "echo '--- current system ---'
  readlink /run/current-system
  echo '--- system profile ---'
  readlink /nix/var/nix/profiles/system
  echo '--- disk ---'
  df -h /
  echo '--- failed units ---'
  systemctl --failed
  echo '--- jobs ---'
  systemctl list-jobs"
 :dry-run nil)
```

Expected observations:

- `/run/current-system` resolves to the current system path above.
- `/nix/var/nix/profiles/system` resolves to `system-3-link`.
- `hostname` or the helper status reports `myhostname`.
- The Den hostname evaluation reports `kioskbeerli`.
- `systemctl --failed` reports zero failed units.
- `systemctl list-jobs` reports no jobs.
- `df -h /` remains consistent with the recorded SD-card root filesystem.

## Verify from shell

The repo helper is read-only and does not use `sudo`:

```sh
kioskbeerli/scripts/verify-pi-den-base.sh guest@192.168.178.34
```

It prints the current system, system profile, hostname, root filesystem, disk
state, failed units, jobs, `flake show`, the effective NixOS hostname, and the
Den hostname.

## Reconstruct /etc/nixos from the local backup

On a replacement or repaired Pi, copy the local backup to a staging directory
under the normal user account:

```sh
rsync -avz var/kioskbeerli-pi-backup/etc-nixos/ guest@<pi-ip>:/home/guest/kioskbeerli-restore/etc-nixos/
```

Then install the staged copy into `/etc/nixos`:

```sh
ssh -tt guest@<pi-ip> \
  'sudo mkdir -p /etc/nixos && sudo cp -a $HOME/kioskbeerli-restore/etc-nixos/. /etc/nixos/ && sudo chown -R root:root /etc/nixos'
```

Verify the flake without rebuilding:

```sh
ssh guest@<pi-ip> 'cd /etc/nixos && nix --extra-experimental-features "nix-command flakes" flake show'
```

Only after inspection, run a test rebuild first:

```sh
ssh -tt guest@<pi-ip> \
  'cd /etc/nixos && sudo env NIX_CONFIG="experimental-features = nix-command flakes" nixos-rebuild test --flake .#kioskbeerli-pi'
```

Do not document or run `switch` as the first reconstruction command. The first
rebuild boundary is `test`.
