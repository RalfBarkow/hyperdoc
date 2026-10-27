# Topic Maps as a packaged component of the dreyeck.ch Catalog

Local packaging of the independent Topic Maps implementation (`topic-maps` at `b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc`) as a
separate Catalog executable, `hyperdoc-catalog-topic-maps`. Prepared on 2026-10-26 on `dreyeck.ch` on top of `53ee9993`, uncommitted.

[The Phase A design](phase-a-design.md) is kept as reviewed. This page records the decisions taken on it, what was built, what was
run, and what is still open.

Each statement carries a label for how it is known:
- **[obs]** observed in a run listed below;
- **[der]** derived from source or evaluation, not executed;
- **[inf]** inferred, still to be tested;
- **[op]** needs operator evidence.

## Decisions (2026-10-26)

| | Decision | What follows here |
|---|---|---|
| D1 | A separate `hyperdoc-catalog-topic-maps` package; the production package stays unchanged | `nix/catalog.nix` and `scripts/catalog-main.lisp` are untouched; `hyperdoc-catalog` is shown unchanged below |
| D2 | A small, immutable, content-addressed archive of `b2eecffa` without `reports/`, prepared and verified locally; nothing published | `nix/topic-maps-source.nix` names the intended GitHub release URL, which does not exist yet |
| D3 | An independent x86_64-linux builder, possibly the Hetzner NixOS test instance, after checking its configuration and capacity; never the production server while its disk is uncertain | nothing was built for Linux; Linux was only evaluated |
| D4 | No push; a candidate with exact revisions and evidence | nothing is committed or pushed |
| D5 | Loopback-only staging; plain `v:thunk` buttons never public; no change to the proxy, service or authority policy | the executable refuses any host other than `127.0.0.1` and `::1` |

## What was built

**The snapshot.** `scripts/topic-maps-snapshot.py create` writes the archive and HyperDoc's manifest from the local repository, reading it
only (`git archive`, `git cat-file`).

| | |
|---|---|
| Archive | `topic-maps-b2eecffa-runtime.tar.gz`, 1,033,963 octets, SHA-256 `8a7b9755ecbe31fc25defca869fe0893b1b9b30268abf82ab6ff319147ba41b3` |
| Content | every root entry of `b2eecffa` except `reports/`: 2,328 files (2,325 of mode 100644, 3 of mode 100755), 5,740,208 NAR octets |
| Nix pin | `sha256-Nu7zDGGWj2rYEozoe4sVj6hiDC3HBHGdSvzOBaBcylw=` in `nix/topic-maps-source.nix` (a `fetchzip`), so `flake.lock` is unchanged |
| Store path | `/nix/store/1l6im929rknvgp3jxx83i01crcf3ahmg-source`, the same on every system because the path is content-addressed |
| Git pin | `nix/topic-maps-b2eecffa.manifest`: the raw commit object, the root tree listing, the excluded entry and the NAR hash; no implementation file |

Further facts:
- Creating the archive twice gave identical bytes [obs]. The NAR hash does not depend on the archive bytes anyway.
- The archive itself is not in either repository. It is in the session scratchpad and can be regenerated with the script.
- The path the `fetchzip` pins equals the path that `nix store add --mode nar --name source` gives for the unpacked archive [obs]. So a store
  that holds the snapshot builds the packages without fetching anything, which is option B of the design.
- The local build did not contact the unpublished URL [obs].

**Lisp.**
- **`dreyeck/source-snapshot`** verifies a `/nix/store` snapshot without `.git`:
  - the commit object hashes to `b2eecffa`;
  - it names root tree `2b2ad058…`;
  - the root listing hashes to that tree;
  - the snapshot's root entries are exactly the shipped ones;
  - every shipped file, mode and subtree hashes to the commit.

  Names come from `readdir`, kinds from `lstat`, and a link is refused. `reports/` is named by its tree id `44adbb2c…`; it is neither
  shipped nor verified.
- **The tree check is independent of location.** Accepting a tree as the loaded source is a separate policy (`source-kind`):
  - **`:git-checkout`:** `.git` is present, and Git's own checks apply unchanged;
  - **`:nix-store-snapshot`:** a read-only `/nix/store` path without `.git`, verified;
  - **`:unverifiable`:** anything else, which is refused.
- **Only the 22U reading and the CTM review dispatch on that policy:** `checked-source-evidence`, `run-example`, `%file-at-revision` and
  `%hyperdoc-state`. Every other Git-only check is unchanged, including `tmdm-reading`'s `checked-repository`, which still refuses outside
  a checkout.
- **Runs record which evidence they had.** The 22U run's annotation and the review run's evidence carry `:topic-maps-source-evidence`
  and `:hyperdoc-revision-evidence`, and the review's Provenance section says them in words.
- **HyperDoc's own revision**, from a store source, is the one the wrapper states (`self.rev`, or `self.dirtyRev`). It is labelled
  *"as stated by the Nix package, not verified here"*.
- **`dreyeck/catalog-topic-maps`** is the variant's startup. It checks that every Topic Maps system comes from the one verified snapshot,
  then refuses the Project Workspace. The refusal is a check of the variant's own startup, `refuse-project-workspace`: the Catalog loads
  exactly one system by choice, the one `HYPERDOC_CATALOG_SYSTEM` names, and the check reads that system's definition and its
  dependencies' definitions from ASDF. If one of them is `dreyeck/work/project` or a subsystem of it, the variant refuses to start,
  before the Catalog loads or starts anything. The same check refuses `dreyeck/page-attached-hyperdoc`, which loads a system named
  by a wiki page after startup (and `dreyeck/fedwiki-hyperdoc` and the activation button of a local FedWiki page, which depend on it),
  so that no wiki page can introduce the Project Workspace afterwards. It adds no method to ASDF and replaces none; ASDF's own methods
  stay ASDF's (`scripts/test-asdf-method-preservation.lisp`, in a fresh process). It is made once, at startup: it does not stop a load
  made later by other means, such as a Lisp prompt in the running image. What it protects and what it does not is in
  [staging.md](staging.md#what-the-catalogs-startup-guard-protects-and-what-it-does-not), with the operator procedure for staging on
  `dreyeck.ch` (`nix/nixos-staging.nix`).

  Then it runs the Catalog's unchanged `main`.
- **`scripts/catalog-topic-maps-main.lisp`** refuses a non-loopback host before anything is loaded, and sets an unset host to
  `127.0.0.1`.

**Nix.**
- `flake.nix` adds the packages `topic-maps-source` and `hyperdoc-catalog-topic-maps`, and the check `catalog-topic-maps`.
- **The wrapper** (`nix/catalog-topic-maps.nix`) uses the same runtime, with the snapshot added before HyperDoc's source in the registry.
- **The check** (`nix/catalog-topic-maps-check.nix`) runs in the build sandbox, with an empty `HOME` and `XDG_CACHE_HOME`. It runs:
  - the four Lisp suites on the package's own registry;
  - a search that finds exactly one `topic-maps.asd`;
  - the executable contract.

## How each requirement is shown

| Requirement | Shown by | Result |
|---|---|---|
| Archive equals the pinned commit, accounting for `.gitattributes`, modes, symlinks, included files and excluded `reports/` | `topic-maps-snapshot.py verify`, using Git and Nix and not the Lisp verifier: 19 checks ([evidence](evidence/archive-verification.json)) | pass [obs] |
| … and the verifier can fail | `tests/test_topic_maps_snapshot.py`: the unaltered archive verifies, and 9 alterations are refused (byte, mode, extra file, missing file, symlink, a `reports/` member, NAR hash, exclusion list, commit object) ([log](evidence/archive-controls.log)) | 10 of 10 [obs] |
| The Lisp verifier, without `.git` | `dreyeck/source-snapshot` tests: 34 checks, with blob ids compared against `git rev-parse b2eecffa:<path>` as an independent oracle, and 13 refusals (8 tree changes, 4 manifest changes, a file changed after verification). They ran in the sandbox and from the checkout | pass [obs] |
| Verified snapshot kept apart from Git checkout; Git-only checks not weakened | Both kinds run the same 22U and review suites. The expected kind must be **stated** (`HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE`, defaulting to a Git checkout) and is checked against what was found. Mutant: `source-kind` always reporting a snapshot is killed by `TOPIC-MAPS-SOURCE-KIND-AS-STATED` | pass [obs] |
| ASDF source origins | the package check prints `ASDF-ORIGIN` for each system: every Topic Maps system is from `1l6im929…-source`, `dreyeck` from its store source, libraries from the runtime. Exactly one `topic-maps.asd` is in the registry ([log](evidence/package-check/lisp.log), [asd](evidence/package-check/topic-maps-asd)) | pass [obs] |
| Project Workspace (`5a4a668`) never loaded against `b2eecffa` | `dreyeck/catalog-topic-maps` tests: the system, its tests, a probe depending on it, and a direct `perform` are all refused; no package or component of it is loaded. Executable test: `HYPERDOC_CATALOG_SYSTEM=dreyeck/work/project` exits non-zero before listening | pass [obs] |
| CTM results preserved, including the scheme-plus rejection | the review suite (58 checks) in both modes: the control is read, `svn+ssh` is rejected with `INVALID-OCCURRENCE-LITERAL` at character 3, the evaluation is refuted, observed and derived are kept apart; the reviewed files' SHA-256 is unchanged. topic-maps is unchanged at `b2eecffa` with a clean status. No corpus case or PASS/FAIL/NOT-RUN classification is touched | pass [obs] |
| Both 22U navigation paths | the 22U suite (41 checks) in both modes, plus the 22U browser test against the checkout ([evidence](evidence/browser-22u-checkout.json)) | pass [obs] |
| Browser navigation and identity | the review browser test against the **checkout** and against the **store snapshot**: all six identity tags (claim, function, run, condition, control map, observation); in snapshot mode, `src/ctm/lexer.lisp` is read through a verification made when it is shown; the 1280×800 overflow check passes ([checkout](evidence/browser-review-checkout.json), [snapshot](evidence/browser-review-snapshot.json), [screenshot](evidence/execution-view-snapshot.png)) | pass [obs] |
| Rendering runs nothing; no writer | `rendering-does-not-execute` and `no-persistence-writer-loaded` in both suites, in both modes | pass [obs] |
| `hyperdoc-catalog` unchanged | `scripts/compare-catalog-derivation.py`, comparing `53ee9993` with this tree for x86_64-linux and x86_64-darwin: identical except HyperDoc's source path and the output path that follows from it; every input derivation is equal. Positive control: a one-flag change of the wrapper is reported as different ([linux](evidence/catalog-unchanged-x86_64-linux.json), [darwin](evidence/catalog-unchanged-x86_64-darwin.json), [control](evidence/catalog-control-changed-wrapper.json)) | pass [obs; evaluation only, no Linux build] |
| Production startup still works | `checks.x86_64-darwin.catalog` on this tree: the Catalog application suite, 9 conversation-source tests, and 2 executable tests (HTTP and shutdown) ([log](evidence/production-check.log)) | pass [obs, darwin] |
| Loopback only (D5) | the executable refuses `0.0.0.0`, `::`, `localhost` and `dreyeck.ch` with exit 2 before anything is loaded; staging on `127.0.0.1` answers HTTP 200 and stops cleanly on SIGTERM, with the port closed afterwards ([log](evidence/package-check/executable.log)) | pass [obs] |
| The tests can fail | mutants, all killed ([log](evidence/mutants.log)): a constant refuted rule, rendering that runs the experiment, an observation sharing the input string, `source-kind` always reporting a snapshot, and the tree not hashed | 5 of 5 [obs] |

## Runs: new versus historical

**New in this step.** All runs were on 2026-10-26, after the last change to a program or test file; the 21 tested files' SHA-256 are in
[tested-files-sha256.txt](evidence/tested-files-sha256.txt). This documentation was written afterwards and is not an input to any test.

| Run | UTC | Environment |
|---|---|---|
| `checks.x86_64-darwin.catalog-topic-maps` | 11:05:14 to 11:07:38 | Nix build sandbox, SBCL 2.4.10, a fresh derivation (no earlier output existed) |
| `checks.x86_64-darwin.catalog` | 11:07:38 to 11:09:59 | the same |
| Checkout suites (review, 22U, source snapshot) | 11:0x | fresh SBCL, `XDG_CACHE_HOME` in the scratchpad (231 FASLs compiled there) |
| Review browser test, checkout and snapshot | 11:00:54 to 11:02:34 | sandboxed loopback server, fresh cache |
| 22U browser test, checkout | 11:02:57 to 11:03:38 | the same |
| Mutants | 11:04 | fresh SBCL, fresh cache |
| Archive verification and controls; derivation comparison and control | after 11:05 | Python 3.14, Git 2.50.1, Determinate Nix 3.11.2 (2.31.1) |

**Historical, not rerun here:**
- `docs/topic-maps-22u-integration/*`;
- the CTM review runs before commit `53ee9993`;
- the topic-maps corpus results (262/4/7 of 273).

Nothing here re-executes or reclassifies the corpus.

## Corrections

1. **The compilation cache.**
   - **The earlier claim:** the 22U and CTM review runs said their FASLs went into a temporary cache (`HYPERDOC_22U_FASL_ROOT`).
   - **What actually happened:** they did not. The SBCL wrapper prefixes `ASDF_OUTPUT_TRANSLATIONS` itself, so `env -u` before it has no
     effect, and the bootstrap's explicit translation did not take effect in a probe.
   - **The effect:** those runs compiled into the user-level `~/.cache/common-lisp/sbcl-2.4.10-macosx-x64/`. The review's FASL there is
     dated 2026-10-26 10:22:26 CET, the time of the last pre-commit run. They were fresh processes, not necessarily fresh compilations;
     ASDF recompiles stale files, but nothing proved a clean cache.
   - **What the runs here use instead:** a fresh `XDG_CACHE_HOME` (in the browser test, the variable is passed to the server), or the
     sandbox's empty `HOME`.
   - The 22U report carries the same correction.
2. **Nested `.gitattributes`.**
   - **The earlier claim:** Phase A said `.gitattributes` holds only `-whitespace` rules.
   - **What was found:** that is true of the root file only. `vendor/cxtm/.gitattributes` sets `*.cxtm text eol=lf`, `*.ctm binary` and
     `*.xtm binary`.
   - **Why it does not change the archive:** neither attribute rewrites an LF blob in `git archive`, and every archived file hashes to
     its commit blob [obs].
   - **How the verifier treats it:** it allows these attributes for that stated reason and refuses `export-subst`, `export-ignore`,
     `filter`, `ident`, `working-tree-encoding`, `crlf` and any `eol` other than `lf`.
   - **Hermetic runs:** creation and verification ignore system and user attribute files. This repository has no `info/attributes`.

## Storage

Measured on x86_64-darwin [obs]:
- **Production Catalog closure:** 1,741,635,328 NAR octets in 369 paths.
- **What the variant adds:** exactly two paths, the snapshot (5,740,208 octets) and its wrapper, 5,742,488 octets together. The variant
  shares every other path.
- **Compile cache:** one process compiled about 8 MB of FASLs for the review and 22U systems.
- **HyperDoc's source snapshot:** about 19 MB per revision, used by both packages.

On x86_64-linux the snapshot has the same bytes and the wrappers are small [der]. Before any Linux build:
- **[op]** free space on the builder's `/nix`;
- **[op]** whether the builder already has the locked runtime closure (nixpkgs `50ab7937`);
- **[inf]** with that closure present, a candidate adds about 25 MB of store paths plus build-time temporary space;
- **[inf]** a builder without it must substitute the closure, about 1.7 GB on darwin and similar on Linux.

Store paths and system generations are never deleted as automatic cleanup.

## Rollback

- **Locally:** nothing is committed. To undo the working tree:
  - `git reset` drops the intent-to-add index entries;
  - `git checkout -- <files>` restores the tracked files;
  - removing the new files removes the rest.
- **Local store:**
  - the snapshot and builds are ordinary store paths;
  - the scratchpad out-links `result-*` are their only GC roots;
  - removing those links releases them for the user's own garbage collection, which is not run here.
- **topic-maps:** never written.
- **Server:** nothing happened. In Phase D, the rollback in `dreyeck/CATALOG-OPERATIONS.md` applies unchanged:
  - restore the saved declaration and lock and rebuild, or switch to a recorded generation;
  - the variant is not in the public service, so it never needs a service rollback.

## Not done, and the gates before it

- **No x86_64-linux build or test** (Phase C). It waits for the builder decision (D3) and its evidence: configuration, Nix version, disk,
  and whether the closure is already present.
- **No publication.** Before Phase C on a remote builder:
  - the archive must either be published at the URL in `nix/topic-maps-source.nix` (D2, needs approval), or be added to that builder's
    store, after checking that its path equals `1l6im929…`;
  - pushing `dreyeck.ch` needs approval (D4).
- **No server staging or activation** (Phase D). This needs the operator's read-only server evidence (to come separately), the
  procedure in [phase-a-design.md](phase-a-design.md) §3, and explicit approval.
- **The plain-thunk buttons stay ungated by the authority policy** (D5). The variant is loopback-only. Public exposure needs a separate
  decision on reviewed example contracts, or an authenticated instance.
- **`tmdm-reading` corpus executions** still need a Git checkout. In the package they are refused, not bypassed.
