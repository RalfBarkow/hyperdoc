# FAQ asdf-fasl-nix-store

**Question.** Loading a Lisp system with ASDF fails because ASDF tries to write a
compiled file (for example `package.fasl` or `package-tmpXXXX.fasl`) into
`/nix/store/…`. Why, and what fixes it?

| Field | Value |
|---|---|
| Status | verified on Linux |
| Revision | 2, 2026-11-20 (revision 1 wrongly said the dev shell uses ASDF's defaults; see the end) |
| Verified | 2026-11-20, Claude Code (independent reviewer) |
| Environment | x86_64-linux; HyperDoc dev shell of RalfBarkow/hyperdoc `55f03bc2b6448972bafbdccb4c164712fbb4bb3a` (`nix develop --no-update-lock-file`); SBCL 2.4.10, ASDF 3.3.1; checks run as an unprivileged user |
| Check | `check-asdf-fasl-destination.lisp` (fresh process) and `diagnose-asdf-fasl-destination.lisp` (running image, read-only) |
| Not verified | macOS; other Lisp implementations and ASDF versions; why a given image recompiles a packaged library |

## Answer

ASDF writes a compiled file where its **output translations** say.

In the HyperDoc dev shell, `sbcl` is the nixpkgs `sbcl.withPackages` wrapper.
When it starts SBCL, it sets `ASDF_OUTPUT_TRANSLATIONS` itself; the shell
variable stays unset. It maps every packaged Lisp library onto its own store
path, for example `/nix/store/…-sbcl-salza2-2.1/`. Those libraries were
compiled when the package was built, and their `.fasl` files lie next to the
sources. Loading them reads the store and writes nothing.

All other sources go to the user cache, `$XDG_CACHE_HOME/common-lisp/…` or
`$HOME/.cache/common-lisp/…`. That includes store paths outside the wrapper's
list, such as HyperDoc's flake input `shop3` in `/nix/store/…-source/`.

ASDF tries to write into the store only when it must compile a file whose
destination is in the store:

1. **A packaged library is recompiled.** Observed with
   `(asdf:load-system "salza2" :force '("salza2"))`: `Permission denied` on
   `/nix/store/…-sbcl-salza2-2.1/package-tmp….fasl`. Why ASDF recompiles in a
   particular image is not established here.
2. **The store as a whole is mapped onto itself**, for example by
   `ASDF_OUTPUT_TRANSLATIONS=/nix/store/:/nix/store/` or
   `(asdf:disable-output-translations)`.

`XDG_CACHE_HOME` changes neither case.

A separate failure: if neither `XDG_CACHE_HOME` nor `HOME` is writable, ASDF
stops with `Can't create directory …/.cache/common-lisp/…`.

## Diagnose

In a fresh process (ends the process; never load it into a working image):

```bash
FAQ_SYSTEM=salza2 sbcl --noinform --non-interactive --no-userinit --load check-asdf-fasl-destination.lisp; echo "exit $?"
```

Exit 0: no write into the store is needed. Exit 1: the destination is in the
store and the compiled file is missing. Exit 2: the cache cannot be created.
Exit 3: the system was not found. `FAQ_CHECK_READ_ONLY=1` creates nothing.

In the running image (read-only; edit the system name in the file):

```lisp
(load "diagnose-asdf-fasl-destination.lisp")
```

## Fix

For case 1, first find out why ASDF recompiles, and remove that cause; ASDF
then uses the prebuilt files again. If a recompilation is really wanted,
use fix B.

For case 2, fix A or fix B.

A. Before starting Lisp, map the store to a writable directory:

```bash
export ASDF_OUTPUT_TRANSLATIONS="/nix/store/:$HOME/.cache/asdf-nix-store/"
```

The wrapper puts its own entries first, so fix A changes the destination only
for store paths outside the wrapper's list. **It does not help in case 1.**

B. In Lisp, before loading, return to the user cache:

```lisp
(asdf:initialize-output-translations
 '(:output-translations :ignore-inherited-configuration :enable-user-cache))
```

This also discards the wrapper's mappings. Every library loaded afterwards is
compiled into the user cache instead of using the prebuilt files. Loading
`salza2` this way wrote 21 compiled files. If `HOME` is not writable, also set
`XDG_CACHE_HOME` to a writable directory.

To return to the wrapper's mappings in the same image, pass `nil` explicitly:

```lisp
(asdf:initialize-output-translations nil)
```

Without the argument, ASDF applies the last configuration it was given again,
so after fix B the destination stays in the user cache.
`(asdf:clear-output-translations)` does not restore the wrapper's mappings
either.

## Do not

Do not run as root to make the error go away. Where root can write to the store,
ASDF writes the compiled file **into the store path** and corrupts it.
Observed during verification: `nix store verify --no-trust <path>` then reports
`path '…' was modified! expected hash …`.

## Evidence (unprivileged user)

Packaged library `salza2` 2.1:

| Case | Destination | Result |
|---|---|---|
| plain load | store, prebuilt `package.fasl` present | loaded, nothing written |
| forced recompile | store | `Permission denied` on `…/package-tmp….fasl` |
| forced recompile with fix A | store (unchanged) | `Permission denied` |
| forced recompile with fix B | `$HOME/.cache/common-lisp/sbcl-2.4.10-linux-x64/nix/store/…-sbcl-salza2-2.1/` | loaded, 21 compiled files written |
| fix B, then `(asdf:initialize-output-translations)` | user cache (unchanged) | wrapper mapping not restored |
| fix B, then `(asdf:clear-output-translations)` | user cache (unchanged) | wrapper mapping not restored |
| fix B, then `(asdf:initialize-output-translations nil)` | store, prebuilt `package.fasl` | wrapper mapping restored |

A probe system in the store, outside the wrapper's list:

| Case | Destination | Result |
|---|---|---|
| no extra setting, `XDG_CACHE_HOME` set | `$XDG_CACHE_HOME/common-lisp/sbcl-2.4.10-linux-x64/nix/store/…` | loaded |
| `HOME=/nonexistent`, no `XDG_CACHE_HOME` | `/nonexistent/.cache/…` | `Can't create directory` |
| `ASDF_OUTPUT_TRANSLATIONS=/nix/store/:/nix/store/` | the store path | `Permission denied` |
| `(asdf:disable-output-translations)` | the store path | `Permission denied` |
| fix A | `$HOME/.cache/asdf-nix-store/<hash>-…/` | loaded |
| fix B | `$HOME/.cache/common-lisp/…` or `$XDG_CACHE_HOME/common-lisp/…` | loaded |

After these runs, `nix store verify --no-trust` reported the store paths
unmodified. The calls of the check with their exit codes are listed in
`HANDOVER.md`.

## Correction of revision 1

Revision 1 said: "The HyperDoc dev shell itself sets no
`ASDF_OUTPUT_TRANSLATIONS`, so it shows the default behaviour." The shell
variable is indeed unset, but the `sbcl` wrapper sets it when SBCL starts. The
first check script tested only a store path outside the wrapper's list and so
missed case 1. Revision 1 also presented fix A as a general fix.
