# NixOS Parallels clean baseline

Status: verified

Decision:
Use the nixpkgs-managed Parallels Tools baseline via `hardware.parallels.enable = true`.
Do not use the host ISO installer payload as the production path.

Verified state:
- SSH works.
- Passwordless sudo works.
- Booted generation equals current generation.
- System state is running.
- Display manager is active.
- User graphical session is Wayland.
- `prltoolsd` is active and comes from nixpkgs `prl-tools-26.3.2-57398`.
- Rejected host payload `/usr/lib/parallels-tools` is absent.
- `/bin/bash`, `/bin/sh`, `/usr/bin/prlfsmountd`, `/bin/sed`, `/bin/tail` are NixOS compatibility shims pointing back to `/run/current-system` or `/nix/store`.

Known residual:
- Parallels shared-folder automount still logs attempts to touch `/etc/fstab`.
- Treat `/mnt/psf` / Parallels shared folders as unavailable for now.
- Use SSH, SCP, or rsync for file transfer.

Rejected experiments:
- Host ISO Tools runtime: rejected.
- X11 session test: rejected; caused display-manager core dump.
- Interactive clipboard probing: stopped.
