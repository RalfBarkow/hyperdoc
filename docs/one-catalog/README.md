# One production Catalog with Topic Maps

Prepared 2026-10-29 on branch `claude/one-catalog-topic-maps`, from `dreyeck.ch` at `0c388f95b35b282f6d6437ef158eb16207c7434a`.
Nothing here is committed, merged, pushed or deployed. It is a production candidate for review.

Labels: **[obs]** observed in a run listed under Evidence; **[der]** derived from source, not executed; **[op]** needs the operator.

## Review status

The architecture is approved in principle; the public exposure is under review, and this is **revision 2** after the owner's decisions of 2026-10-29.
[security-review.md](security-review.md) is the review; its evidence is in `evidence/security/` (revision 1) and `evidence/security-2/` (revision 2), separate from
the build, snapshot and browser evidence below. Done in this revision: the direct Workspace link is left out of the served view; an unset host is `127.0.0.1`;
the test-time-only gate is replaced by a **run-time boundary in the authority layer** (an unknown button is refused when served, whoever made it); the Trails and gesture
controls are inspected and kept as reviewed controls; the `CONTEXT-FEDWIKI-PAGE` baseline correction is a separate patch, not in this candidate. Still not approved:
any public inspector run button, retiring the historical deployment readings and tests, production memory limits, deployment. This candidate does none of them.

## What this changes, in one paragraph

`hyperdoc-catalog` becomes the only production Catalog. It carries the verified Topic Maps snapshot (`88994c1b`) in its ASDF
registry, and its startup verifies that snapshot and refuses the Project Workspace before anything is served. Which Topic Maps
readings the Catalog loads is a choice of the service (`HYPERDOC_CATALOG_SYSTEM`), not of the package. The readings' run buttons
are not offered by a served Catalog. The separate `hyperdoc-catalog-topic-maps` executable and the staging service are no
longer needed in production; the operator has already removed the staging service (NixOS generation 755, `7rvm05b4…`).

## The four capabilities, kept apart

| | Capability | In the candidate |
|---|---|---|
| A | TMDM functionality loaded and available | The snapshot is in the package's registry and verified at every start (commit object, root tree, every shipped file and mode, every Topic Maps system from the one snapshot). Without a reading named, Topic Maps is available and verified but **not loaded**: `dreyeck/catalog` depends on no Topic Maps system. With the service's reading named, `topic-maps`, `topic-maps/tmdm`, `/ctm` and `/cxtm` load [der from the readings' dependencies; the start itself is obs]. |
| B | Read-only Topic Maps inspection and navigation | Six objects (table below) are served; navigation into the model continues (function objects, source at the pinned commit, the Work Workspace Topic Map) [obs]. |
| C | Executable inspector controls | **Not public, enforced at run time.** The seven run buttons are markers served and register nothing (`run-button`). Beyond them, `dreyeck/authority-policy` replaces every control that is not an operation, an example, a reviewed control or not a thunk by a `refused-thunk` when it is served, so a button added later by `hv:eval-button` is refused when clicked. In a development server nothing changes [obs]. |
| D | Project Workspace admission | **Refused**, unchanged: `dreyeck/work/project`, its tests, and the page-attached loader (`dreyeck/page-attached-hyperdoc`) exit non-zero before listening [obs]. |

Successful ASDF loading grants nothing: B is what is rendered and walked, C is withheld by the policy layer and tested in both
modes, D is the startup guard. The guard's source (`dreyeck/src/catalog-topic-maps.lisp`) is **untouched**.

### The views, individually

`HYPERDOC_CATALOG_SYSTEM=dreyeck/work/topic-maps-ctm-review` loads the CTM review, and through it the 22U reading and the TMDM model
reading. Each object below is rendered served and in a development server by `dreyeck/tests/topic-maps-public-views.lisp`, and
walked in a real browser by `scripts/test-catalog-topic-maps-served-browser.mjs`.

| Object | Views it offers | Run buttons served |
|---|---|---|
| 22U reading page `Reading Slice 22U` (new hyperbook *Topic Maps Project Example (22U)*) | Topic Maps 22U | Read a fresh 22U Map; Exercise on a separate fresh Map |
| `Work Breakdown` (**existing page** of *Working on HyperDoc*) | gains Topic Maps 22U and TMDM model | the two above |
| `Authoring the CTM Plan Page` (**existing page**) | gains TMDM model | none |
| Work topic `ctm-plan-page-authoring` | TMDM model | Read default-type example; Read explicit-type example |
| `Reviewing the CTM Reader` (new hyperbook *Topic Maps CTM Review (22U)*) | the page | none |
| Claim `scheme-plus` | Claim (eight parts, "Not executed in this image.") | Run the experiment |

Every Inspector object also has the generic *Source* and *Playground* views, which draw with CLOG and have no thunk to read. The
Playground evaluates only where the Inspector is started with its playground flag (`:playground? development`), which a served
Catalog does not set. The test lists them and fails on any other non-HTML view.

The *deployment review* reading (`topic-maps-deployment-review`, with its collision extension) is **not** in this set: it reviews the
staging candidate, has two more run buttons, and is a record. It stays in the repository.

## The minimal source diff

21 files outside `docs/`, +941 −58 (`git diff HEAD --stat -- . ':!docs'`); the archive, the browser walk and the security tests are most of the additions.

| File | Change |
|---|---|
| `nix/catalog.nix`, `flake.nix` | `hyperdoc-catalog` takes `topicMaps` and `revision`, puts the snapshot in `CL_SOURCE_REGISTRY` and states `HYPERDOC_SOURCE_REVISION`, as the staging wrapper did |
| `scripts/catalog-main.lisp` | loads `dreyeck/catalog-topic-maps` and runs its `main` (verify, refuse, then the Catalog's own `main`); an unset or empty `HYPERDOC_CATALOG_HOST` becomes `127.0.0.1` |
| `nix/topic-maps-source.nix`, `nix/topic-maps-88994c1b-runtime.tar.gz` | see *Source distribution* |
| `dreyeck/src/authority-policy.lisp` | `run-button`; the run-time boundary (`contain-controls`, `refused-thunk`, `reviewed-thunk` and its registry of eight controls, two reviewed classes) and two more upstream digests |
| `dreyeck/work/conversation-coordinates-reading.lisp`, `dreyeck/src/topicmap-inspector.lisp`, `dreyeck/work/trails-rendered-federated-context.lisp`, `dreyeck/src/gesture-operation-request.lisp`, `dreyeck/src/topicmap-tala-reading.lisp` | eleven plain thunks become `reviewed-thunk`s of registered controls, so the boundary keeps them; no behaviour changes |
| `dreyeck/work/{topic-maps-project-example,topic-maps-ctm-review,tmdm-model-reading}.lisp` | five `v:eval-button` become `run-button`; the TMDM model view omits the direct Workspace link when served; `dreyeck.asd` adds the dependencies |
| `dreyeck/tests/topic-maps-public-views.lisp`, `dreyeck.asd` | the view-by-view test, as its own system `dreyeck/topic-maps-public-views` |
| `dreyeck/tests/authority-policy.lisp` | `check-run-buttons`, `check-control-boundary` (creation, invocation, late registration, developing), `check-reviewed-controls-match-their-sites`; the checks that need the machine are split out of `run-gate-tests` |
| `nix/catalog-check.nix`, `tests/test_catalog_executable.py` | the `catalog` check now carries the Topic Maps contract; executable tests for the guard and for the readings; start deadlines 180 → 600 s |
| `scripts/test-catalog-topic-maps-served-browser.mjs` | the browser walk |
| `dreyeck/work/topic-maps-deployment-review/code/candidate.lisp` | names this change as a successor of the files that reading protects (its own mechanism) |

Not touched: the guard, `catalog-application`, the Project Workspace and every Project CTM test (so the 90-second read-and-model
check is unchanged), the Mech host, the Wiki assets, nginx.

**The host.** The staging executable refused every host but loopback. The production Catalog is not made loopback-only; an **unset or empty `HYPERDOC_CATALOG_HOST` is now `127.0.0.1`**
and any named host is kept (so the server's explicit `127.0.0.1` and nginx's proxying are unchanged). Tested: unset, empty, explicit loopback and explicit `0.0.0.0` in the packaged executable.

**The retired variant stays in the tree for now.** `hyperdoc-catalog-topic-maps`, its check, its wrapper and `nix/nixos-staging.nix` are
unchanged because the deployment review quotes them and pins their bytes. They are not used in production. Removing them belongs with
retiring that reading.

## Source distribution

The 88994c1b archive was not published at the URL `nix/topic-maps-source.nix` named, and the server's store does not hold it
(the staging package it ran pinned `b2eecffa`). Chosen: **the archive is in the repository** and a fixed-output derivation unpacks it.

- `nix/topic-maps-88994c1b-runtime.tar.gz`: 1,062,834 octets, SHA-256 `6fe74dc31e5291b03d440cfbeaf41c38d021225f36ce7fb96afcbcd632006cdd`.
- `scripts/topic-maps-snapshot.py create <topic-maps> 88994c1b9e1edbf13e665e984a5c9c3b2cdf7575 <out>` reproduced it from the clean checkout,
  and its manifest is byte-identical to `nix/topic-maps-88994c1b.manifest` (`cmp`) [obs].
- The derivation is fixed-output with NAR hash `sha256-5h3t+4tb0J49Zt9bWtu3ZCX46OjDVmZOWlfy/pu7h40=`: Nix itself refuses a tree with another hash.
  Its store path is `/nix/store/kna6395gl32f2hl4n3ha4776zm9r0sgb-source`, the same one a `fetchzip` of the same tree gave, and it was built
  from the archive on x86_64-linux in the builder **and on the server** [obs]. At every start `dreyeck/source-snapshot` verifies the tree
  against the Git objects in the manifest.
- No release has to be published and no builder fetches the snapshot. The cost is a 1 MB binary in the repository and a vendored copy of
  Topic Maps' runtime files. The alternative, a GitHub release asset at the old URL, needs the owner's authorization to publish and leaves
  every build dependent on it; `topic-maps-source.nix` can return to a `fetchzip` with the same hash.

## Evidence

All in `docs/one-catalog/evidence/` with `SHA256SUMS`; the security evidence is in `evidence/security/` and described in [security-review.md](security-review.md). **The build, check, snapshot and browser evidence below was gathered before the security review**, on the tree of the tested code, `18712a54ddd80a1ceb4b0b8fcaf6a83704905677`
(`git write-tree` of the working tree, also reproduced by the builder); the commit that records it adds `docs/one-catalog/`, which the
package sources include, so the committed package's store path differs from the tested one and its `revision` is the commit's. The committed tree also differs from `18712a54…` by the security review's additions (`dreyeck/tests/topic-maps-public-views.lisp`, `dreyeck.asd`, `docs/one-catalog/`). The Linux check, the packaged browser walks and the pure NixOS build must be run again on the exact committed revision before deployment.

| What | Result |
|---|---|
| **Revision 2** (after the security review's decisions; `evidence/security-2/`) | |
| `checks.x86_64-linux.catalog` and the package, tree `7e16e77e…` (builder, sandbox off) | exit 0 [obs]: the application suite, the guard, snapshot, 22U and CTM review suites, ASDF preservation, the public-views test with the 12 authority-policy gate checks, and 5 executable tests (400 s), including the host behaviour |
| `checks.x86_64-darwin.catalog`, the same tree (sandboxed) | exit 0 [obs]. Two earlier runs failed and were corrected, not retried: the time cap of the walk made its coverage depend on the machine (now fixed by object count and depth), and one client timeout in the executable test provoked a crash (now 30 s; see security-review.md) |
| The walk on both platforms | 300 objects, 9,538 controls: 8,478 inert, 993 slot readers, 11 reviewed, 56 of reviewed classes, 0 refused, 0 unknown; identical numbers on Linux and Darwin [obs] |
| Packaged browser walks, served, 9 steps each | Linux (through the relay) and Darwin: the seven buttons are markers; the Workspace link is absent; the conversation cursor moves and moves back by real clicks [obs] |
| The walk can fail | against a development server it fails at its first assertion [obs] |
| Pure NixOS build on the server, no `--impure`, tree `1f60ff42…` | toplevel `9ivdb5k3…`; the closure gains the 7.0 MiB `source`; under `etc/` only `hyperdoc.service` differs, by the two lines [obs] |
| `dreyeck/authority-policy` with the drift patch | the whole suite passes in a scratch copy [obs]; without it, 12 gate checks pass and three need the developer's machine |
| **Revision 1 and the original runs (below) are kept as they were** | |
| `checks.x86_64-linux.catalog` and `packages.x86_64-linux.hyperdoc-catalog` (builder: Docker Desktop VM, `nixos/nix:2.31.1`, **Nix sandbox off**) | exit 0 [obs] |
| in it: the Catalog application suite, conversation sources, the guard (29), the source snapshot (34), 22U (41), CTM review (58), the public views (6 objects, 7 buttons), ASDF method preservation in a fresh process (183), exactly one `topic-maps.asd`, 4 executable tests (300 s) | pass [obs] |
| ASDF origins | every Topic Maps system from `kna6395g…-source`, `dreyeck` from its store source (`linux-check/lisp.log`, `topic-maps-asd`) [obs] |
| Executable, packaged | default start verifies the snapshot, serves, stops with exit 0 on SIGTERM and SIGINT; `dreyeck/work/project`, `…/tests` and `dreyeck/page-attached-hyperdoc` exit non-zero before listening; the readings start under the same verification [obs] |
| Real browser over the **Linux** package, through a relay to the container's loopback | 8 steps, no page error, no external request [obs] (`browser/linux-served-browser.json`) |
| The same walk over the Darwin package | 8 steps, shutdown exit 0 [obs] |
| The walk can fail | against a development server, where the buttons are offered, it fails at its first assertion [obs] (`browser/development-control.txt`); the Lisp test also fails with `run-button` mutated to upstream's button [obs] |
| `checks.x86_64-darwin.catalog` | exit 0 [obs]. A first run failed: `test_foreground_http_and_shutdown` timed out at 180 s because three heavy jobs shared the host; the deadline is now 600 s, as in the other executable test |
| Cold start, Linux, fresh cache | 80 s default, 68 s with the readings; peak RSS 442 MB and 445 MB, steady 421 and 396 MB [obs] (`linux-measure.txt`). Production's Graph A restart took 32 s |
| Pure NixOS build on the server, without `--impure` | `nixos-rebuild`-equivalent `nix build` of the toplevel as `rgb`, the candidate tree as the `hyperdoc` input, succeeded: `7f9kklav…` [obs] (`server-pure-build.txt`) |
| Reviewed service diff against generation 755 | the closure gains the 6.7 MiB `source`; under `etc/` only `hyperdoc.service` differs, by two lines (the new `HYPERDOC_CATALOG_SYSTEM` and the new `ExecStart`); no staging unit; kernel, initrd and `sw` equal [obs] |
| Deployment review tests | `topic-maps-deployment-review` passes its 343 assertions on this tree as on the base, then fails `CROSSCHECK-RETAINED-CTM-IS-THE-FILE` on both: that failure is at `0c388f95` already (Graph A changed the project CTM) and is not caused here [obs] |

## What did not run, or is not established

- **The Nix sandbox was off in the Linux builder** (Docker). The server's `nix build` of the NixOS configuration ran with the daemon's defaults, but it did not build the check; the check ran only in the container and on Darwin.
- **Nothing ran on the public URL**: nothing is deployed. Public HTTP, runtime identity and memory after activation are the operator's checks below.
- **`dreyeck/authority-policy/tests` is not part of the Nix contract and reports adapter drift on Darwin at the base already** ("new title-bar actions on TRAILS-RENDERED-READING::CONTEXT-FEDWIKI-PAGE"). Its new check, `check-run-buttons`, runs before the drift check and passes. The drift was not investigated.
- **The `Work Breakdown` page, an existing public page, gains two views**, and rendering the TMDM one computes the Work projection. Its cost was not measured apart from the browser walk, which completed.
- **The first start after the switch compiles the new systems**; the service is down for that time (68–80 s in the builder, more on the server's CPU).
- The service has no `MemoryMax`, and SBCL is started with `--dynamic-space-size 3000` on a 3.8 GB host. This change does not alter that.

## Deployment (operator)

Preconditions that are not mine to do: the candidate is committed on the development branch, reviewed, brought into `dreyeck.ch` and
pushed; the server's flake input is `github:RalfBarkow/hyperdoc?ref=dreyeck.ch`. The staging service is already gone (generation 755).

Record, as root on the server:

```bash
readlink -f /run/current-system /nix/var/nix/profiles/system && systemctl show hyperdoc.service -p ExecStart -p MainPID && cd /etc/nixos && cp -p flake.nix flake.nix.pre-one-catalog && cp -p flake.lock flake.lock.pre-one-catalog && cp -p hyperdoc-service.nix hyperdoc-service.nix.pre-one-catalog
```

The one configuration change, in `/etc/nixos/hyperdoc-service.nix`, `systemd.services.hyperdoc.environment`:

```diff
       HYPERDOC_CATALOG_HOST = "127.0.0.1";
+      HYPERDOC_CATALOG_SYSTEM = "dreyeck/work/topic-maps-ctm-review";
       HYPERDOC_MECH_PLUGIN_HOST_URL = "https://mech.dreyeck.ch/assets/hyperdoc-mech/";
```

Update only the `hyperdoc` input, and check the lock diff: only that node moves, to the pushed commit.

```bash
cd /etc/nixos && nix flake update hyperdoc && diff -u flake.lock.pre-one-catalog flake.lock
```

Build without `--impure`, from a directory that is not `/etc/nixos`, and compare with what was reviewed:

```bash
cd /root && nixos-rebuild build --flake /etc/nixos#dreyeck && nix store diff-closures /run/current-system ./result && diff /run/current-system/etc/systemd/system/hyperdoc.service ./result/etc/systemd/system/hyperdoc.service
```

Gate: the closure difference is the `source` (plus the package), and the unit differs by the `HYPERDOC_CATALOG_SYSTEM` line and the `ExecStart` only. Then:

```bash
cd /root && nixos-rebuild dry-activate --flake /etc/nixos#dreyeck
```

```bash
cd /root && nixos-rebuild switch --flake /etc/nixos#dreyeck
```

After the switch (the service restarts and compiles first; allow a few minutes): `hyperdoc.service` active with the new `ExecStart`; the journal
shows `Topic Maps 88994c1b: /nix/store/kna6395g…-source/` and `Topic Maps snapshot verified without .git`; only 8080 on loopback listens, 18780 does not;
the public Catalog answers; Topic Maps readings are present with their buttons shown as *not run in a served Catalog*; memory and
restart count. The runtime's revision is the pushed commit, stated by the package, not checked by the runtime.

Rollback: `nixos-rebuild switch --rollback` returns to generation 755 (`7rvm05b4…`); the lock and service file copies above restore the sources.
The old store paths and the staging state directories are kept; nothing is garbage-collected.

## Decisions for the owner

1. **Vendor the archive** in the repository (chosen) or publish it as a release asset.
2. **The public set**: the three readings, including two new views on the existing `Work Breakdown` page, or a smaller set. (The owner kept the six objects.)
3. **The run-time boundary** keeps eight reviewed controls at eleven call sites, and two reviewed classes (cursor, Point, request, Trails, TALA); accept the registry, or review it entry by entry (`evidence/security-2/reviewed-controls.txt`).
4. **When to remove** `hyperdoc-catalog-topic-maps`, `nix/nixos-staging.nix` and the deployment review.
5. **A `MemoryHigh`/`MemoryMax` for `hyperdoc.service`**, which this change does not add.
6. **The drift commit** (`evidence/security-2/drift-correction.patch`): apply it after this candidate, as its own commit.
