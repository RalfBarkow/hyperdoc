# Evidence of the corrected candidate

The files one level up describe the **first version** of the Project Workspace guard (runs of 2026-10-26) and are unchanged,
as are the collision probe's records under `dreyeck/work/topic-maps-deployment-review/asdf-collision/evidence/`. These files
describe the candidate after the guard was corrected on 2026-10-27. A passed run here is evidence, never an acceptance.

## Identity

- **HyperDoc base:** `53ee999358f455a2dcb375743072d56d0f4c31cd` (branch `dreyeck.ch`).
- **Tree:** the base plus the uncommitted candidate (the packaging, the guard correction, the review reading and the staging
  files). The runs below were made on that working tree, before it was committed. `tested-files-sha256.txt` lists the SHA-256 of
  each tested file; it was computed before the runs and was equal after them.
- **Topic Maps:** `b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc`, as the verified snapshot
  `/nix/store/1l6im929rknvgp3jxx83i01crcf3ahmg-source`, NAR hash `sha256-Nu7zDGGWj2rYEozoe4sVj6hiDC3HBHGdSvzOBaBcylw=`.
  Its archive is `topic-maps-b2eecffa-runtime.tar.gz`, 1,033,963 octets, SHA-256
  `8a7b9755ecbe31fc25defca869fe0893b1b9b30268abf82ab6ff319147ba41b3` (`nix/topic-maps-b2eecffa.manifest`).

## What ran, by hand on x86_64-darwin (not a Nix sandbox build)

Environment: SBCL 2.4.10 with the pinned library set of `nix/lisp-runtime.nix`, ASDF 3.3.1, a store copy of the source without
`.git`, the verified snapshot, an empty `HOME` and `XDG_CACHE_HOME`. Each log says "NOT A NIX SANDBOX BUILD" at its top.

| Record | What it shows |
|---|---|
| `contract-lisp.log` | the contract's Lisp suites: startup (29 assertions), source snapshot (34), 22U (41), CTM review (58) |
| `asdf-methods.log` | `scripts/test-asdf-method-preservation.lisp`: every ASDF method object is the same before and after loading the guard; ASDF's behaviour is equal; a deliberate colliding method is detected (183 assertions) |
| `executable.log` | `tests/test_catalog_topic_maps_executable.py` against a wrapper mirroring `nix/catalog-topic-maps.nix`: public hosts refused, the Project Workspace refused before listening, loopback start and clean shutdown (3 tests) |
| `derivations-unchanged-x86_64-{linux,darwin}.json` | `hyperdoc-catalog`'s derivation is unchanged from the base apart from HyperDoc's source and the output that follows (evaluated, nothing built) |
| `module-evaluation.json` | `nix/nixos-staging.nix` in a minimal NixOS configuration: not wanted at boot, no firewall ports, no reverse proxy, loopback address only (evaluated, nothing started) |

## What ran on x86_64-linux, in `x86_64-linux/`

The builder is a local Docker Desktop Linux VM (a container from `nixos/nix:2.31.1`), **not the production server**. Its Nix
sandbox is **off** (the image's `nix.conf`), so these are Nix builds, not sandboxed Nix builds. The tree built is git tree
`a2db814640299db0f0550a5d1ee2769d25128ea5`, exported with `git archive` (no `.git`); the builder's own `git write-tree`
reproduced that hash.

| Record | What it shows |
|---|---|
| `nix-build.log` | `nix build .#checks.x86_64-linux.catalog-topic-maps .#packages.x86_64-linux.hyperdoc-catalog-topic-maps` exited 0 |
| `contract-lisp.log`, `asdf-methods.log`, `executable.log`, `topic-maps-asd` | the contract's own kept logs: the four Lisp suites, the fresh-process ASDF preservation test (inside the Nix check), the executable contract, and exactly one `topic-maps.asd` in the registry |
| `builder-and-snapshot.txt` | the builder, the derivations, and the snapshot reconstructed from its 1,033,963-octet archive to the same store path and NAR hash |
| `packaged-reading.log` | in the built package's runtime, without `.git`: the reading's three suites pass (304, 267, 76), the executable listens on 127.0.0.1 only, answers HTTP 200 and stops with exit 0 on SIGTERM |
| `browser-walk.json` | a real browser, through a forwarder to a published port, walked the Linux-served reading in 8 steps; the executable stayed on its loopback |
| `linux-validate.sh`, `reading-suites.lisp`, `walk-linux.mjs` | the procedures behind the last two records |

**Relation to the commit.** The Linux runs are of tree `a2db8146…`. The tree of the commit that records them differs from it by
these evidence files and by the reading's claims and pages that cite them (nothing in a tested program or test file). The same runs
on the commit's own tree (`057d303f7c79d0163b8a3ddf6876e990955093cf`, commit `7080162b`) are in
`x86_64-linux/of-commit-7080162b/`, recorded in the commit that follows it: built and checked on x86_64-linux with exit 0, the
reading's suites 324, 267 and 76, the executable on 127.0.0.1 only with a clean shutdown, and an 8-step browser walk.

**What carried the Topic Maps snapshot.** Not the 2.47 GB repository: the archive, created by `scripts/topic-maps-snapshot.py`
from the read-only repository and reproducing `nix/topic-maps-b2eecffa.manifest` byte for byte, was unpacked in the builder and
added by content. Nothing was published.

## What did not run, or did not complete

- **`checks.x86_64-darwin.catalog-topic-maps` did not build.** `nix-darwin-blocker.log` records the attempt: the Darwin
  bootstrap stdenv derivations had been garbage-collected from the local store and cannot be rebuilt offline. This is an
  environment blocker, not a result of the candidate. The by-hand runs above are not a substitute for it and are not reported as one.
- **Nothing ran on the production server,** and nothing was deployed, pushed or published. The staging module was evaluated, not started.
- **No sandboxed Nix build.** The Linux builder's sandbox is off; the Darwin check could not build at all.
