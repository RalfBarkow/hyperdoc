# Integrating Topic Maps 6162ed68 into HyperDoc

A local, uncommitted candidate on top of `dreyeck.ch` `8e64e718`, prepared on 2026-10-28 in the separate worktree
`/Users/rgb/workspace/hyperdoc-topic-maps-6162ed68` (branch `claude/topic-maps-6162ed68-integration`). Nothing here is committed,
pushed, published or deployed, and no server was touched. A human-readable reading of the same facts is the HyperBook
*Integrating Topic Maps 6162ed68* (`dreyeck/work/topic-maps-integration-review/`, served by its `serve.sh`).

Labels: **[obs]** observed in a run recorded under `dreyeck/work/topic-maps-integration-review/evidence/`; **[der]** derived from
source; **[open]** not done.

## Phases

| Phase | State |
|---|---|
| A. Integrate Task 1C (`6162ed68`) into Topic Maps | **done**, local |
| B. Prepare HyperDoc: pins, Project Workspace, snapshot, tests, reading | **done as a candidate**, uncommitted |
| Commit of the HyperDoc candidate | **needs approval** |
| Push of Topic Maps or HyperDoc; publication of the snapshot archive | **needs approval** |
| Linux build; staging on `dreyeck.ch` (`hyperdoc-catalog-topic-maps-staging`, port 18780 in the module's example); any change to production `hyperdoc.service` | **not started; needs approval and an operator** |

## Phase A: Topic Maps

- Primary checkout `/Users/rgb/workspace/topic-maps`, branch `codex/project-work-slice-22u` (tracks `gitweb/codex/project-work-slice-22u`),
  was at `b2eecffa` with a clean tree. The reviewed commit `6162ed68c94ea4796b8cf2282edd347d9607b08c` is its direct child, so
  `git merge --ff-only 6162ed68` was possible and was done. **[obs]** The tree equals the reviewed commit's tree
  (`a4e787b0…`); `git diff 6162ed68 HEAD` is empty; no other branch moved; `b2eecffa` is still a commit object on three refs.
- The experimental association index is not in it.
- The full Topic Maps suite (`scripts/fresh-sbcl.lisp`, fresh FASL cache, report files) was repeated in the integrated checkout:
  exit 0, no warnings, the 25 report files byte-identical to the unmodified baseline's, one added `NORMALIZATION-INDEX-PASS`
  line (120 checks). **[obs]** `evidence/phase-a-integration.txt`.
- The remote `gitweb` still names `b2eecffa`; nothing was pushed.

## Phase B: what HyperDoc changes

HyperDoc names one Topic Maps commit in four places and one image holds one Topic Maps, so they move together.

| Where | Change |
|---|---|
| `dreyeck/src/catalog-topic-maps.lisp` `+topic-maps-commit+` | `b2eecffa` → `6162ed68` |
| `dreyeck/work/topic-maps-project-example.lisp` `+source-revision+` (also the CTM review's) | same |
| `dreyeck/work/project/project-workspace.lisp` `+topic-maps-revision+` | `5a4a668` → `6162ed68` |
| `nix/topic-maps-source.nix` | the 6162ed68 archive: URL (unpublished), NAR hash `sha256-t3E4HX4JxGPGNDnCMRg8GGIg7zhtquBbCU7CLU4TU2M=` |
| `nix/topic-maps-6162ed68.manifest` (new) | raw commit object, root tree listing, excluded `reports`, NAR hash, archive SHA-256 `439816d8…5188`, 1,049,501 octets |
| `nix/topic-maps-b2eecffa.manifest` | **kept**, as history |

**The Project Workspace.** `topic-maps-source-identity` now distinguishes a Git checkout, a **verified** Git-free `/nix/store`
snapshot (through the existing `dreyeck/source-snapshot` verifier: the commit object, the tree chain and every shipped file hash as
Git hashes them), an unverified snapshot and an unverifiable directory. It returns `:kind`, `:commit`, `:clean`, `:one-root`,
`:pinned`; a directory Git cannot identify has no commit and is neither clean nor pinned (before, it looked clean with an empty
commit). `pinned-state-p` states the pin: the commit, no change, one root for the four Topic Maps systems. `dreyeck/work/project`
now depends on `dreyeck/source-snapshot`. The Roundtrip view says which kind of root it has. The Work pages, the CTM emitter and
the Workspace itself are unchanged.

**The guard stays.** The Catalog's startup guard still refuses `dreyeck/work/project` and everything that depends on it, and the
page-attached loader. Its message no longer says the Workspace is bound to another lineage (it no longer is); it says that
admitting the Workspace is a separate decision. Behaviour and the tests that require the refusal are unchanged; two tests assert the
new wording. Nothing was removed to make a system load.

**Tests that changed because a fact changed:** the verifier's file count (2,328 → 2,354: the 26 new files of Task 1C) and
oracle comment; the Project test that `def t() end` is refused (5a4a668) now checks that b2eecffa and its descendants read it as an
empty map, and a malformed document is still refused with its code `:missing-association-close`. New pin tests: `pinned-state-p`
negatives (changed tree, another commit, b2eecffa, an empty commit, two roots) and an unverifiable directory.

## Evidence

All runs on x86_64-darwin (Intel i5-8279U, SBCL 2.4.10 packaged unless noted); records are the files under
`dreyeck/work/topic-maps-integration-review/evidence/`, each checked against `SHA256SUMS`.

| Claim | Evidence |
|---|---|
| The archive for 6162ed68 is the commit's tree minus `reports/` (2,354 files); archive and manifest reproducible | `scripts/topic-maps-snapshot.py verify`: 19 checks pass **[obs]**; two `create` runs byte-identical **[obs]** |
| Verifier, 22U reading, CTM review on the Git-free snapshot | 34, 41, 58 assertions pass **[obs]** |
| Project Workspace suite on the integrated Git checkout | 265 + 186 + 125 checks pass, including the 90-second bound **[obs]** |
| Workspace on the original CTM (SHA-256 `f4f04bb4…`, unchanged), Git checkout and verified snapshot | 55/57/4/40 model; 327 Topics, 572 Associations; trace clean; 148 signs, 286 edges; 8 navigation keys; CXTM `6f957018…` equal to the 5a4a668 reference **[obs]**; 35 s and 39 s read-and-model |
| The same under overload | 161 s (load average above 100): kept, and explained **[obs]** |
| CTM read, integrated primary checkout, three fresh processes | 34.5 / 33.7 / 28.7 s; signature and CXTM equal to the reference **[obs]** |
| Negative pins | 5a4a668 checkout: not pinned; b2eecffa snapshot: does not verify as 6162ed68 (no commit, not clean); an unidentified directory: not pinned **[obs]** |
| Packaged contract in the Nix sandbox | `checks.x86_64-darwin.catalog-topic-maps` passes: origins from the one snapshot, 29 + 34 + 41 + 58 assertions, ASDF methods unchanged (183), executable refuses public hosts and the Workspace **[obs]** |
| The reading | 293 checks: pages and links, evidence digests, claims, performance rows against the review's text, pins, Workspace integrity, rendering runs nothing, the guard still refuses **[obs]**; served and navigated in a browser (interactive) **[obs]** |

Independent evidence for the change itself (the 2026-10-28 review: GO) is in the same directory and on the reading's pages.

## What is not verified

- **Linux.** No x86_64-linux build or check. **[open]**
- **The browser walk with the Git-free snapshot** as the Topic Maps root (it passes from a Git checkout). **[open]**
- **Production-sized host.** Timings are from one Intel Mac and move with load; the 90-second line has not been measured on the server.
- **`hyperdoc-catalog` (production)** was not rebuilt or compared in this step.
- **The earlier deployment review's second test procedure** (the proposals') fails at `EVIDENCE-NAMES-ITS-RECORD` at `8e64e718` too; not touched.
- **The staging module's default additional book** is that earlier review. The reading of this integration cannot replace it in the packaged
  executable: it loads the Project Workspace, which the executable's guard refuses by design.
- Optional XTM integration suites; a controlled idle-machine benchmark.

## Before committing: the second review round (2026-10-28)

**A. `DECLARED-PATHS-AGREE`.** It protects one historical change set: the earlier deployment review's candidate at its completion
commit `8e64e718` (base `53ee9993`): exactly its 73 declared paths and 23 tested files with their recorded bytes (at `7080162b` only 66
paths match; the Linux evidence came later). It compared the working tree, so any later change failed it; the integration changes seven
protected files on purpose. That is a **limit of the test's scope, not a regression** of the candidate or of the integration. The contract is
now explicitly bound to `8e64e718`, names the seven successor changes with reasons, and keeps its teeth: controls show an extra path, a
missing path, an altered tested file and an unlisted modification are still detected, and four mutants of the contract are killed
(`declared-paths-mutation-controls.txt`). The declared list was not extended and no check removed. A second failure the first concealed
(an excerpt of the Workspace's pin that legitimately changed) is handled by a historical excerpt of the reviewed lines. The earlier review's
main suite passes (344 assertions); its second procedure (the proposals') fails at `EVIDENCE-NAMES-ITS-RECORD` at `8e64e718` too and was not
touched. Facts and results: `dreyeck/work/topic-maps-integration-review/evidence/phase-c-declared-paths-agree.txt`.

**B. The Project Workspace in a browser.** `scripts/test-project-workspace.mjs`, fresh process, headless Chrome, the original CTM, Topic Maps
6162ed68 as a clean Git checkout: **pass**. Its expectation is the Workspace's own pin, read from its source, and the checkout is verified by
the test with Git's answers and a committed manifest, not by the Lisp that serves it. The walk: a declared Work Item, its source page, its plan
relationship, an Implementation Assignment and its evidence file; the absent acceptance record is named; the Work Breakdown page is the same
Lisp object (same printed address under the Print tab) reached from the Workspace Topic and from the reading's Sources table, and another page is
not (control); the Work pages and the CTM keep their digests and Git shows them unchanged. It ran in a **trusted review runtime**
(`scripts/serve-project-workspace.lisp`), not in the packaged executable, whose startup guard still refuses the Workspace (the Nix contract with
that refusal passes). It was not run with the Git-free snapshot as the Topic Maps root.

**C. The reading** now also shows the four commits, the corrected contract, the browser evidence, the guarded-Catalog boundary and the relation to
Zettel 11359: the wished-for navigation exists only as four relations of class *proposed* from one proposed Work Item to the real subjects; no
Work page, WBS declaration, acceptance record or CTM was written and the earlier proposals were not promoted.

## Commit boundaries (none made)

Each boundary below was checked for what it needs: boundaries 1 and 2 were **committed in a scratch clone** (not this worktree) and tested at each commit
(`evidence/phase-d-boundary-rehearsal.txt`); 3 and 4 by the reading's own suite in the final tree. The reading's tests also check that the boundaries'
file sets are disjoint apart from two files split by hunk and are together exactly the changed paths.

| # | Proposed subject line | Files | Depends on | Tests at the boundary |
|---|---|---|---|---|
| 1 | Pin Topic Maps 6162ed68: snapshot manifest, pins and the earlier review's version-bound contract | whole: `nix/topic-maps-6162ed68.manifest`, `nix/topic-maps-source.nix`, `dreyeck/work/topic-maps-project-example.lisp`, `dreyeck/tests/source-snapshot.lisp`, and in `dreyeck/work/topic-maps-deployment-review/`: `code/candidate.lisp`, `code/package.lisp`, `tests/review.lisp`, `pages/Keeping the Project Workspace Out.html`, `asdf-collision/topic-maps-deployment-review-asdf-collision.asd`, `asdf-collision/evidence/project-workspace-pin-at-8e64e718.lisp`; by hunk: `dreyeck.asd` (the manifest), `dreyeck/src/catalog-topic-maps.lisp` (the pin) | nothing: applies to `8e64e718` | verifier 34, 22U 41, CTM review 58 on the Git-free snapshot; earlier review main suite 344; Nix `checks.catalog-topic-maps` **[obs]** |
| 2 | Bind the Project Workspace to Topic Maps 6162ed68 and identify a Git-free snapshot | whole: `dreyeck/work/project/project-workspace.lisp`, `dreyeck/work/project/project-ctm.lisp`, `dreyeck/tests/project-ctm.lisp`, `scripts/run-project-workspace-integration.lisp`, `scripts/test-project-workspace.mjs`, `dreyeck/tests/catalog-topic-maps.lisp`, `tests/test_catalog_topic_maps_executable.py`; by hunk: `dreyeck.asd` (the dependency), `dreyeck/src/catalog-topic-maps.lisp` (the refusal's wording) | 1 | snapshot suites; Project suite 265 + 186 + 125; browser test; Nix contract with the new wording **[obs]** |
| 3 | Add the reading of the Topic Maps 6162ed68 integration | everything under `dreyeck/work/topic-maps-integration-review/` | 1, 2 | `topic-maps-integration-review/tests`; served and navigated in a browser **[obs]** |
| 4 | Document the integration, its limits and the proposed staging procedure | everything under `docs/topic-maps-6162ed68-integration/` | 1, 2, 3 | prose |

Source identity of each file is shown live by the reading (Git blob id and SHA-256). Rehearsal commits: boundary 1 tree `94d21b2e7dcb110b770c47af2a8c9184733398b7`
boundary 2 tree `857211810fdd9d09f127e3f70cb6d2f0969389ff` and boundary 3 tree `18906fd61b2fc259f127ee2d8c53c9b37ff4f0f1` (scratch commits `19e6688d`, `21c3e3ee`, `941c13c3`;
the real commits will differ by their dates, but their trees must equal these if the same hunks are staged). The fourth rehearsal commit's tree equals the tree of this worktree's
final state (checked with a temporary index; it is not written here because it would include this file). The rehearsal suites passed at boundary 3 (without the documentation present) and at boundary 4: 293 checks.

**Regressions that pass:** Topic Maps full suite (25 report files identical); verifier, 22U reading, CTM review; Project suite; the browser walk; the
Nix contract (darwin) at boundaries 1 and 2; the earlier review's main suite; the reading's suite.
**Unexecuted:** x86_64-linux build and checks; the browser walk with the snapshot as Topic Maps root; a timing on the server's hardware; production
`hyperdoc-catalog` re-comparison; the optional XTM suites; the earlier review's second procedure (failing before any change).
**Limitations that belong to later Linux/deployment acceptance only:** the unpublished release URL of the archive, the Linux build, staging, and the
decision to admit the Project Workspace to a served runtime. None is needed to authorize local commits.

## Proposed staging deployment procedure (nothing below has been run; stop before any server mutation)

It follows `docs/topic-maps-deployment/staging.md`, whose preconditions and guard scope still hold, with these differences.

**Preconditions (all outside this repository).**
1. The owner approves committing the candidate and pushing `dreyeck.ch` (or approves transferring the package without pushing).
2. The operator records free space and memory on the server first (disk was the constraint; the staging unit is bounded by `MemoryMax=3G`).
3. The snapshot reaches the builder: either the archive is published at the URL in `nix/topic-maps-source.nix` (a release, needs the
   owner's authorization) or it is transferred and added by content. The archive is reproducible:
   `python3 scripts/topic-maps-snapshot.py create /Users/rgb/workspace/topic-maps 6162ed68c94ea4796b8cf2282edd347d9607b08c OUT`
   must reproduce `nix/topic-maps-6162ed68.manifest` byte for byte and give an archive of 1,049,501 octets with SHA-256
   `439816d86df01f02a2ff8e4243a74aa7a7f5ab6503734f01ea3a9e65ed8f5188`; unpacked, `nix hash path --type sha256 --sri` must print
   `sha256-t3E4HX4JxGPGNDnCMRg8GGIg7zhtquBbCU7CLU4TU2M=`, and `nix store add --mode nar --name source <unpacked directory>` must print
   `/nix/store/wii905xa1b2v6rhyqx230gpy3xq40y8l-source`.

**Build on an independent x86_64-linux builder, not the production server.**
1. Export the committed tree (`git archive`), check `git write-tree` equals the commit's tree, add the snapshot by content, then
   `nix build --print-build-logs .#checks.x86_64-linux.catalog-topic-maps .#packages.x86_64-linux.hyperdoc-catalog-topic-maps`.
2. Accept the build only if the check passes and `topic-maps.asd` appears exactly once in the registry, in the 6162ed68 snapshot.
3. Compare `hyperdoc-catalog` with the previous revision (`scripts/compare-catalog-derivation.py`): identical except HyperDoc's source path.

**Stage on loopback only** (module `nix/nixos-staging.nix`, unchanged; choose a port nothing listens on):
1. Import the module and set `package` to the new `hyperdoc-catalog-topic-maps`; `nixos-rebuild switch` adds the unit and does not
   start it. `catalogSystem` stays the default: the Project Workspace reading cannot be the additional book (the guard refuses it).
2. `systemctl start hyperdoc-catalog-topic-maps-staging`; the journal must say *Topic Maps 6162ed68* and *snapshot verified without .git*,
   then *listening on 127.0.0.1*; `ss -ltnp` shows the port on 127.0.0.1 only. The first start compiles for minutes.
3. Reach it through an SSH tunnel from an authorized machine; read the Catalog and the packaged reading; check the first-start memory.
4. Roll back: `systemctl stop`, or remove the block and `nixos-rebuild switch`, or `nixos-rebuild switch --rollback`. The production
   service is neither stopped nor restarted at any point.

**Not part of staging:** admitting the Project Workspace to the served runtime (a separate, tested policy decision that must also
measure the 90-second read on the server's hardware), and any public exposure of the plain `v:thunk` buttons.
