# Handover: FAQ asdf-fasl-nix-store, revision 2

Files in this bundle:

- `asdf-fasl-nix-store.md`: the entry, revision 2
- `check-asdf-fasl-destination.lisp`: check for a fresh SBCL process, with exit codes
- `diagnose-asdf-fasl-destination.lisp`: read-only diagnosis inside a running image
- `SHA256SUMS`

## Verified state

| Item | Value |
|---|---|
| Date | 2026-11-20 |
| Repository | RalfBarkow/hyperdoc |
| Commit | `55f03bc2b6448972bafbdccb4c164712fbb4bb3a` (branch `dreyeck.ch` at the time). `flake.nix` and `flake.lock` are identical at `85696f457a55b0bb273d071512fcd6b293f9b3a6` and `c574f597fc2ac9ab5672b9ffec334d2b64fa7eaf`. |
| `flake.lock` | git blob `5c86702d8c0a32aa36d1dfc102b36b7de294bce9`, SHA-256 `019dcaff428e1abf426f165c3afd70fe163077454d1c348d4965d86a93a7e836` |
| nixpkgs | `50ab793786d9de88ee30ec4e4c24fb4236fc2674`, narHash `sha256-/bVBlRpECLVzjV19t5KMdMFWSwKLtb5RyXdjz3LJT+g=` |
| Dev shell | `nix develop --no-update-lock-file` (fails instead of changing the lock) |
| Platform | x86_64-linux |
| `sbcl` | `/nix/store/nnv2shrcjhyq76y7dcb380ycggv44s84-sbcl-with-packages/bin/sbcl`, SBCL 2.4.10, ASDF 3.3.1 |
| `salza2` | `/nix/store/sl2w45plgmshgj1q7fb77bcpqqi4h6wv-sbcl-salza2-2.1` |
| User | Nix runs single-user (root) in this container. The dev shell was entered as root; every SBCL run below ran as the unprivileged user `nobody` (via `runuser`), each with a fresh `HOME`. |

## Check: calls and expected results

Run inside `nix develop --no-update-lock-file` in a HyperDoc checkout, as a user
who cannot write to `/nix/store`. `$C` is the path to
`check-asdf-fasl-destination.lisp`, `$T` a fresh empty directory, `$S` the
salza2 store path above. Each call is

```bash
env <settings> sbcl --noinform --non-interactive --no-userinit --load "$C"; echo "exit $?"
```

| Case | Settings | Exit | Last line |
|---|---|---|---|
| C1 | `HOME=$T` | 0 | `PASS: destination is outside the store and can be created.` |
| C2 | `HOME=$T FAQ_SYSTEM=salza2` | 0 | `PASS prebuilt: …` |
| C3 | `HOME=$T FAQ_SYSTEM=salza2 FAQ_COMPONENT=package` | 0 | `PASS prebuilt: …` |
| C4 | `HOME=$T ASDF_OUTPUT_TRANSLATIONS=/nix/store/:/nix/store/` | 1 | `FAIL store-destination: …` |
| C5 | `HOME=$T FAQ_PROBE_SOURCE=$S/no-such-file.lisp` | 1 | `FAIL store-destination: …` |
| C6 | `HOME=/nonexistent` (not writable, no `XDG_CACHE_HOME`) | 2 | `FAIL not-creatable: …` |
| C7 | `HOME=$T FAQ_CHECK_READ_ONLY=1` | 0 | `PASS read-only: …`; `$T` stays empty |
| C8 | `HOME=$T FAQ_SYSTEM=no-such-system` | 3 | `FAIL not-found: …` |
| C9 | `HOME=$T ASDF_OUTPUT_TRANSLATIONS=/nix/store/:$T/.cache/asdf-nix-store/` | 0 | `PASS: …`, destination under `$T/.cache/asdf-nix-store/` |
| C10 | as C9 plus `FAQ_SYSTEM=salza2` | 0 | `PASS prebuilt: …`; the destination stays in the store |
| C11 | `HOME=$T FAQ_SYSTEM=shop3` | 0 | `PASS: …`; flake input, destination in the user cache |

As root on a writable store, C6 gives a different result, because root can
create `/nonexistent`. The check itself never writes into the store; it creates
only the cache directory for destinations outside the store, and nothing with
`FAQ_CHECK_READ_ONLY=1`.

## Load experiments behind the entry

Same dev shell, unprivileged user, fresh `HOME`, in this order:

| Form | Result |
|---|---|
| `(asdf:load-system "salza2")` | loaded from the prebuilt `.fasl` files in `$S`, nothing written |
| `(asdf:load-system "salza2" :force '("salza2"))` | `Permission denied` on `$S/package-tmp….fasl` |
| the same with fix A in the environment | same error |
| fix B, then the forced load | loaded; 21 compiled files in `$HOME/.cache/common-lisp/…` |
| fix B, then `(asdf:initialize-output-translations)` | destination stays in the user cache |
| fix B, then `(asdf:clear-output-translations)` | destination stays in the user cache |
| fix B, then `(asdf:initialize-output-translations nil)` | destination back in `$S` |

`nix store verify --no-trust "$S"` reported no modification afterwards.
**Never run the forced load as root:** root would write into `$S`.

## Read-only run on the Mac

1. In the running image (in SLY, choose `*ABORT` to return to the REPL prompt first):

   ```lisp
   (load "/path/to/diagnose-asdf-fasl-destination.lisp")
   ```

   It reads ASDF state and probes files. It compiles nothing, loads no system,
   searches no registry and creates no file. If the image has not initialized
   its translations yet, the call initializes them; `translations-initialized`
   is printed before that. Please pass on the whole output.

2. In a fresh process, from the HyperDoc checkout (`55f03bc` or `c574f597`, same lock):

   ```bash
   nix develop --no-update-lock-file -c env FAQ_CHECK_READ_ONLY=1 FAQ_SYSTEM=salza2 sbcl --noinform --non-interactive --no-userinit --load /path/to/check-asdf-fasl-destination.lisp; echo "exit $?"
   ```

   Then the same call without `FAQ_SYSTEM=salza2`. `nix develop` may build or
   fetch the shell into the store; it does not change the checkout.
   `--no-userinit` skips `~/.sbclrc`, so settings the image took from there show
   up only in step 1.

macOS is not verified by me. Codex's PR #57 log (x86_64-darwin, same nixpkgs)
shows salza2 at `/nix/store/kx4fxynbmzg2k9bqwhl803wzw1ip8jak-sbcl-salza2-2.1` with
a prebuilt `package.fasl`.
