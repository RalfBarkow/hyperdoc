# Re-pinning HyperDoc to Topic Maps 88994c1b (Task 1E): candidate, evidence and commit plan

A local review candidate on top of `dreyeck.ch`-based `909bcab3`, in the worktree `/Users/rgb/workspace/hyperdoc-topic-maps-88994c1b`
(branch `claude/topic-maps-88994c1b-integration`), prepared 2026-10-28. **Nothing is committed, pushed, published or deployed.** It is
eligible for a local review commit; it is not release or deployment acceptance. The human-readable reading of the same facts is the
HyperBook *Re-pinning Topic Maps to 88994c1b* (`dreyeck/work/topic-maps-task-1e-review/serve.sh`, loopback only).

Labels: **[obs]** observed in a recorded run (`evidence/`); **[open]** not done.

## What changed

- `nix/topic-maps-88994c1b.manifest` (new), `nix/topic-maps-source.nix` (archive and NAR hash), `dreyeck.asd` (the manifest as a static file),
  and the four consumers of the commit: `dreyeck/src/catalog-topic-maps.lisp`, `dreyeck/work/topic-maps-project-example.lisp`,
  `dreyeck/work/project/project-workspace.lisp`, `dreyeck/tests/source-snapshot.lisp` (also the file count 2,354 -> 2,384).
- `dreyeck/work/topic-maps-task-1e-review/`: the new reading, its tests, its evidence and its serve scripts.
- The Catalog's startup guard and its refusal of the Project Workspace are textually unchanged. Topic Maps, Work declarations, Acceptance Records,
  the Stage 1 files of Zettel 11359 and the earlier manifests and readings are untouched.

## Verified, and what each result covers [obs]

| Claim | Evidence |
|---|---|
| Manifest, Topic Maps HEAD and the four consumers agree on `88994c1b…`; the manifest's root tree equals the commit's tree `b0835676…`; the Nix hash equals the manifest's NAR hash | inventory file; reading suite `pins:*` checks |
| Snapshot reproducible (two `create` runs byte-identical), 19 independent checks pass, 2,384 files | `dreyeck/work/topic-maps-task-1e-review/evidence/` |
| Verifier, 22U reading, CTM review on the snapshot: 34, 41, 58 assertions | same |
| Project suite, original CTM, Git checkout: 265 + 186 (10.9 s) + 125 | `evidence/project-suite-original-ctm-PASS.log` |
| Project suite, Stage 1 files in a disposable copy: 345 + 224 (19.4 s, the unchanged 90 s check met) + 125 + 196 | `evidence/project-suite-stage1-copy-PASS.log` |
| Same-bytes control (Stage 1 CTM `fe2955e9…`): 82.3 s and 85.8 s under 6162ed68, 23.7 s under 88994c1b | reading evidence, `evidence/control-…` |
| The reading's suite: 105 checks, exit 0, no skipped check; the guard of the pin, rendering and numbers are asserted, not just strings | `evidence/reading-suite-run3-105-checks-FINAL.log` |
| The reading served on loopback and walked in a browser; the served ASDF origins are the 88994c1b snapshot and this candidate | `evidence/browser-walk-notes.md`, `evidence/served-reading-server.log` |

Each preserved log has its SHA-256 in `evidence/SHA256SUMS`. The final run (run 3, 18:07:00) is of the files as they now are: no candidate
file was modified after 18:05:49 (the inventory lists their digests). The Project suite run on the Stage 1 copy was made before the reading
existed; its pin files are byte-identical to the candidate's, and only `dreyeck.asd` differs, by the Zettel 11359 scope hunks (shown by diff,
not in this candidate).

## Open items, kept visible [open]

1. **Historical reading.** *Integrating Topic Maps 6162ed68* is a historical, revision-bound reading and stays so; its source identity is not
   replaced. Its check `pins:catalog-and-22u-reading-and-workspace-and-reading-name-one-commit` fails in the current runtime, and that **is a
   failure, not a pass**: a historical test that cannot execute in the current runtime does not count. Three contracts are to be kept apart:
   historical reproduction (needs 6162ed68 and an isolated runtime, as the 6162ed68 candidate provided), current integration (needs 88994c1b),
   and the packaged check. The separation itself (running the historical reading in its own revision's runtime, and not as part of the
   current system) is an **open integration requirement**; nothing was weakened or edited. Because the suite stops at its first failure, its later
   checks have not been seen at 88994c1b.
2. **The packaged Nix Catalog check** (`checks.<system>.catalog-topic-maps`) was not run. `dreyeck/catalog-topic-maps/tests` run from a
   development tree stops at its own precondition (`HYPERDOC-FROM-A-STORE-SOURCE`); that is not a result either way.
3. The earlier deployment review: main suite passes (343 assertions here, 344 in its 6162ed68 record, unexplained: its baseline run was stopped);
   its second procedure fails at `EVIDENCE-NAMES-ITS-RECORD`, as it did before.
4. Not run here: the older browser walks (`scripts/test-project-workspace.mjs`, the Zettel 11359 scope walk), Linux, the Stage 2 CTM, peak memory
   on the constrained host (about 460-510 MB per process was observed), high-arity performance, the Python NFC checker (pre-existing Unicode mismatch).
5. The archive is added to the local Nix store only; it is not published at the URL in `nix/topic-maps-source.nix`.
6. **Stage 1 is not in this candidate.** The Stage 1 CTM, pages and tests live uncommitted in the Zettel 11359 worktree; the reading cites their digests
   and the results of a disposable copy. A commit of this candidate therefore does not contain the CTM it reports on.

## Commit plan: three commits (nothing committed; parents are the expected ones)

The pins, the snapshot manifest and the Project Workspace binding are one consistency boundary, so they are one atomic commit: no commit
in the chain holds two Topic Maps revisions. The earlier integration history is not rewritten, and the candidate's bytes are committed as
tested (stage exactly the listed paths; no edit between the final run and the commit). Suggested trailer on each:
`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

| # | Subject | Files | Parent | Required evidence | Status |
|---|---|---|---|---|---|
| 1 | Integrate Topic Maps 88994c1b: snapshot manifest, revision pins and Project Workspace binding | `nix/topic-maps-88994c1b.manifest`, `nix/topic-maps-source.nix`, `dreyeck.asd`, `dreyeck/src/catalog-topic-maps.lisp`, `dreyeck/tests/source-snapshot.lisp`, `dreyeck/work/topic-maps-project-example.lisp`, `dreyeck/work/project/project-workspace.lisp` (7 paths) | `909bcab3` | archive reproducible, 19 independent checks, verifier/22U/CTM-review suites on the snapshot (34/41/58), Project suite on the original CTM (265+186+125), same-bytes control, negative pin | verified as the **whole candidate**, see below |
| 2 | Add the reading of the Topic Maps 88994c1b re-pin: tests and evidence | everything under `dreyeck/work/topic-maps-task-1e-review/` (28 files: code, pages, tests, evidence with its `SHA256SUMS`, `serve.sh`, `serve.lisp`, `.asd`) | 1 | reading suite 105 checks, exit 0, no skipped check; served and walked in a browser | verified as part of the whole candidate |
| 3 | Document the Topic Maps 88994c1b re-pin, its execution evidence and remaining requirements | `docs/topic-maps-88994c1b-integration/` (`README.md`, `evidence/` with `SHA256SUMS`) | 2 | hashes of the preserved logs verify | verified (hashes only) |

**What was tested.** The *full candidate* (all three commits' content together) was tested: the reading's 105-check run, the browser walk and the
snapshot-backed runs ran on the working tree as it stands. **The intermediate commits were not tested independently** and no boundary rehearsal was
run: commit 1 alone has no reading to test, and commit 1+2 alone lacks only the documentation. Say this in commit 1's message.

**Commit-message statements that must be true.** Each of 1-3 names what is not verified: (a) the historical reading *Integrating Topic Maps
6162ed68* is preserved unchanged, its pin check fails in the current runtime (a failure, not a pass; the suite stops there), and keeping it
runnable in its own revision's isolated runtime is an open integration requirement; (b) the packaged Nix Catalog check was not run; (c) Stage 1
results come from a disposable copy of the uncommitted Zettel 11359 worktree, not from this tree; (d) Linux, Stage 2, memory on the constrained
host, high-arity performance, the older browser walks and any deployment or publication of the archive are not done.

Before committing: `git status`; stage by explicit path; the staged set per commit must equal its row, and the union must equal the inventory in
`evidence/source-identities-and-candidate-inventory.txt` (except this directory in commit 3); compare staged blob hashes with that inventory. No
hook, rewrite or amend of `909bcab3` or earlier.

## Blockers to a truthful local review commit

None prevents it, provided the messages state the limits above: (a) do not describe the historical reading's test as passing, (b) do not describe the
packaged Catalog as verified, (c) say the Stage 1 results come from a disposable copy of an uncommitted worktree, (d) say the full candidate, not each
commit, was tested.
