# Workflow reconstruction evidence

The executable entry is `dreyeck/workflow/reading`, titled **Reconstructing Workflow**. This document records the integration evidence and limits; the HyperDoc page is the interactive explanation.

## Source coordinates and reconciliation

The initial target `dreyeck.ch` was `e2928cce72fe7faee32a0b9dbdd51f20fc59c70d`; historical `workflow` was `c4ebfd8d3d8bec5c9aead22ee8b4f5d046220d34`; their merge base was `0aae85da29d085e0c41d53243fcff97c460b2c39`. The target had two unique commits (TALA `ac7d83b5039e08ed5d46d52bacd2c3d380faa382` and Catalog registration `e2928cce`); workflow had twelve.

The twelve historical commits are c4ebfd8d, 5d5933d0, d1bb18bb, 9a3b43e6, 46e91a31, d68ecc8a, 299bd1ef, 7c5e2e8c, 0207cb08, 4e863b03, 9c84d1a1 and 9d22c9d2. Full identities remain reachable from the exact workflow head above. Historical changed files were `dreyeck.asd`, `dreyeck/src/workflow.lisp`, `dreyeck/src/workspace-topicmap-rescue.lisp`, and `dreyeck/tests/topicmap-view-smoke.lisp`.

Only `dreyeck.asd` changed on both sides. Structural comparison identified target changes to `dreyeck/topicmap/tests`, `dreyeck/catalog` and the five TALA systems; historical changes were to `dreyeck` and `dreyeck/workflow/tests`. Their semantic DEFSYSTEM targets did not overlap. Reimplementation was chosen, not a wholesale merge. The dedicated worktree is `hyperdoc-workflow-reconstruction`, branch `codex/workflow-reconstruction`, based exactly on the initial target. All Git operations use Common Lisp `dreyeck/git`. Historical `workflow`, its checkout and all unrelated worktrees/untracked files remain untouched.

## Historical decisions and falsification

| Mechanism / material | Classification | Decision and observation |
| --- | --- | --- |
| Persistent source ownership | Semantic requirement | Retained: ASDF system/component path plus unique structural DEFUN/DEFSYSTEM identity. Wrong owner and identity are rejected. |
| Operation and operation specification | Useful distinction, overbuilt representation | Simplified to ordinary named Lisp definitions and proposed Lisp data. No parallel operation registry. |
| Encoded carriers, fragments, assembly specifications | Incidental historical machinery | Replaced by persisted direct definitions. The historical test required 14 assembled operation names; that tests assembly existence, not the need for assembly. |
| Ordered guarded extensions | Historical implementation | Replaced for this slice: overlapping string/symbol ASDF guards describe evolution of the same dependency operation. No observed external consumer requires extension-chain ordering. |
| Materializers and PERSIST-IN | Semantic requirement / useful implementation | One explicit authoring method writes one structurally identified form and verifies fresh behavior. Existing committed writer is reused. |
| Deterministic assembly | Implementation-specific hypothesis | Not retained as a separate mechanism. Fresh ASDF reconstruction and behavior expectations supply the tested observation without fragment assembly. |
| FRESH-VERIFY / RECONCILE / source audit | Useful requirement, limited evidence | Fresh verification retained; no completeness claim for a global registry audit. Inspect a supplied operation and report source/equivalence limits. |
| ADMIT / COMMIT wrappers | Redundant forwarding | Catalog and dreyeck/git already own these operations. They remain with their authorities. |
| Audit coverage additions | Test/evidence | Coverage derived from registered cases is not proof of whole-image completeness. New tests challenge owned source, stale source, missing dependencies and wrong behavior. |
| Conversation coordinate, resume helpers, black Lisp lab / Workspace rescue | Unrelated work / historical evidence | Left on the historical branch, not imported as core persistence semantics. |

Read-only inspection of persisted callers found no direct `dreyeck/workflow` consumer outside its own sources/tests and ASDF wiring. This is evidence for reduction, not proof that no dynamic caller exists. The old workflow source/tests remain archived in the repository but are no longer ASDF components of the reconstructed system. They are not deleted or silently interpreted as the new implementation.

Historical PERSIST-IN had Catalog ADMIT append/reload/forwarding, Catalog tests append/reload, and overlapping ASDF-dependency replacement guards. The new slice deliberately supports replacement of an existing uniquely owned DEFUN and transformation of a DEFSYSTEM dependency list. It does not claim arbitrary closure persistence, general insertion, batch CLEANUP or global change detection. Adding unsupported forms requires an observable requirement, not revival of the registry by default.

## Interlisp / Medley evidence

Primary historical documentation: [Interlisp timeline, 1971](https://interlisp.org/history/timeline/#1971). It describes file ownership, changed/unfiled components and the contemporary absence of make-like dependency knowledge.

Actual source inspected: [Interlisp/medley](https://github.com/Interlisp/medley), exact commit `3a14c9aa040d6cd897e3d6c3c3fa664a3e2d1442`, `sources/FILEPKG`, blob `46d6906bdb1f92c49e19b128459ca223289717ed` (279892 bytes). Reading objects retain these coordinates, links, warrants and license attribution. No Medley code is vendored or required at runtime.

| Locus | Observation |
| --- | --- |
| FILECREATED, line 3 | Header creation metadata; not proof that reconstructed behavior is equivalent. |
| CLEANUP, line 362 | Coordinates MAKEFILES and optional compilation/listing. |
| MAKEFILE, line 435 | Calls UPDATEFILES, consults file properties / TOBEDUMPED and version metadata. |
| MARKASCHANGED, line 1033 | Tracks changed names by type and WHENCHANGED hooks. |
| FILECOMS, line 1060 | Resolves a file command-variable name, not a workflow operation registry. |
| FILES?, line 1569; FILES?1, line 1608 | Reports files/components needing attention. |
| CHECKIMPORTS, line 4708 | Checks imported versions and IMPORTFILE. |

MIT attribution: Interlisp.org, original Xerox/Venue/John Sybalsky and other contributors; see the LICENSE at the exact commit. No implementation excerpts were copied.

Ownership and outstanding change are useful conceptual continuations of the File Package problem. FILECOMS = fragment registry was rejected; MAKEFILE = fresh behavioral proof was rejected. The claim that modern Medley has *no* dependency knowledge is falsified by CHECKIMPORTS: the 1971 statement cannot be generalized. In HyperDoc, ASDF already supplies system/component dependencies and order. A source file can be correctly owned yet fail reconstruction when an ASDF dependency is missing; the authoring test demonstrates this. No generic graph replaces these different relations.

## Minimal persisted model

`workflow-model.lisp` defines an inspectable persistence plan: owning ASDF system, canonical source path, structural key, prior form, proposed form, complete source witness and fresh expectation. `PLAN-STATUS` distinguishes unchanged, needs-persistence and stale authority. This describes an explicit proposal, not automatically inferred live/source equivalence. `OBSERVE-OPERATION` inspects a supplied symbol using SBCL source introspection and explicitly reports equivalence as not proven. An unowned live function test demonstrates the limit without a global scanner.

`RECONSTRUCT` loads the persisted ASDF system. Ordinary runtime contains the PERSIST-IN generic protocol but no implicit writer method. `workflow-authoring.lisp` supplies the sole executor only with an explicit authoring capability. It uses the existing stale-source and reader-recovery guards, reparses, compares intended and unrelated forms, then starts fresh pinned SBCL and checks the supplied expectation. A failed fresh check is an error; the written source is not reported as accepted and is not automatically rolled back. Child stdout/stderr are retained in the diagnostic.

The authoring environment is `nix develop .#workflow-authoring`. Its independent lock input pins html-inspector-views `4b0607d93b193e21bd2ca5dc0d7e47c062ac8112`, NAR hash `sha256-zxGKX51RIHI9zPB3Aa9hPC3AOy+2h2FPqy30Uk00XQY=`. The ordinary runtime pin remains `386df8937a21457b3d91e1b61e070f836550ff71`. No local html-inspector-views checkout is a reconstruction dependency.

Fresh children restore the ordinary source registry, remove authoring variables and invoke Nix's `sbcl` wrapper. Direct invocation of the underlying binary was falsified by a missing CL-WHO dependency; bypassing the wrapper lost Nix library initialization. The strengthened fixture depends on the real workflow and checks that the child has no structural writer or authoring marker while reconstructing its changed answer.

All new/changed repository Lisp and ASDF forms in this reconstruction were materialized, replaced or inserted through the committed writer, reparsed and compared structurally. Source formatting is its serialization output. Temporary authoring scripts construct Lisp data; no Lisp edit targets came from regex, line numbers or substring heuristics. Earlier textual TALA edits are historical baseline: they were already structurally readable and tested and were not rewritten. CST package-sensitive quoted fixture data was serialized with explicit package qualification and verified again.

## Source authoring boundaries

Creating a source authority and mutating one are two different authoring
operations. The structural writer protects the identity and the neighbourhood
of forms that are already persisted. A path that is not yet a source authority
has no such neighbourhood to protect, so forcing it through the same mechanism
would merge two different cases.

The boundary is the existence of the file, not the convenience of the moment.

```
path absent   -> CREATE-LISP-SOURCE permitted
path exists   -> whole-file rewrite prohibited; targeted structural change
```

`CREATE-LISP-SOURCE` may write one complete new Lisp source authority
textually. Before the commit that persists it, it must satisfy all of:

- the file parses with no reader recovery;
- the intended package identity is preserved;
- every top-level form round-trips structurally, compared package-aware and
  by symbol identity rather than by `EQUAL`, which uninterned `#:` symbols
  never satisfy;
- every declared definition is individually identifiable and named exactly
  once;
- ASDF ownership and component membership are explicit where applicable;
- a fresh load and the system's tests succeed.

Afterwards the file is a persisted source authority, and a targeted change to
one of its forms belongs to the structural mutation path wherever that contract
applies. Whole-file creation is never a way to overwrite an authority that
already exists.

This is the contract as it stands, stated prospectively. It is not a claim that
the writer was ever optional for mutation, and it does not retroactively bless
the 110 hand-authored files in `dreyeck/src` as a model; they are baseline, on
the same grounds as the earlier textual TALA edits recorded above.

A stronger contract remains open and is deliberately not derived from this one:
new Lisp and ASDF source could itself be produced from inspectable authored
data through an explicit, deterministic creation operation, so that first
creation is part of the reconstructible path rather than only its result. That
operation is not modelled yet — the name `MATERIALIZE-LISP-SOURCE` does not
exist in this repository — and its inputs and identity guarantees would have to
be designed and falsified before it could become a repository-wide requirement.

The first executable form of the acceptance list above is
`CHECK-CREATED-SOURCE-AUTHORITY` in
`dreyeck/tests/gesture-binding-witness-smoke.lisp`, applied to the two files
that slice created. It lives beside them rather than in a shared place because
it has one caller; a second caller is what would move it.

## Reading and layout

Ten actual DEFEXAMPLEs are transcluded, not manually duplicated in HTML: plan, live operation, dependency, authoring boundary, Medley evidence, historical model, bootstrap, Workspace, layout comparison and persistence roundtrip. The plan Inspector view links to authority, prior/proposed forms, status and reconstruction expectation. The persistence button returns an explicit capability request in ordinary runtime; in authoring it exercises the same production PERSIST-IN seam against temporary fixture authorities, including failures.

The comparison Workspace contains five real domain/evidence objects and four associations. Associations store source-observed, mechanically-derived, design-inference or working-hypothesis status and warrants. Native placement explains the ownership comparison; optional TALA produces a second derived layout. The existing TALA comparison/navigation checker is reused for the workflow Workspace. Spatial placement does not alter authority, provenance, Topic/Association identities, endpoints, point, history or native navigation thunks. The TALA rendering remains the existing static rendering proof.

Bootstrap seed: Common Lisp, ASDF, pinned dependencies, HyperDoc/HyperBook, DEFEXAMPLE, source transclusion, Inspector and Topicmap/Workspace. Source reconstructs plans; reading definitions derive observations; HTML transcludes them; Catalog ASDF dependencies register the book. There is no claim of complete self-hosting.

## Catalog and local checks

`scripts/serve-catalog.sh` loads its configured system, default `dreyeck/catalog`; its ASDF dependencies load books whose DEFHYPERDOC forms register them. The persisted Catalog change adds `dreyeck/workflow/reading` to that same dependency list. TALA registration from e2928cce remains intact. Registration does not require D2, invoke persistence or mutate Git.

Reproducible local commands (from the repository):

```sh
nix develop . -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/catalog")' \
  --eval '(asdf:test-system "dreyeck/workflow/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/catalog/tests")'

nix develop .#workflow-authoring -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/workflow/authoring/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/reading/tests")'

nix develop .#tala -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/reading/tests")'
```

## External deployment boundary

Local repository reconstruction is not remote deployment verification. Deployment authority is server-local `/etc/nixos/hyperdoc-service.nix`. Operator-supplied evidence says ExecStart uses `nix develop .#tala -c ./scripts/serve-catalog.sh 8080` in `/home/rgb/workspace/hyperdoc`, and the TALA reading page is available. This already selects the existing pinned `nix/d2-tala.nix` package. No NixOS migration, service modification, deployment or restart is part of this reconstruction.

An initial read of the service file occurred before the operator prohibited direct access. A subsequent dependency probe was rejected and did not execute. No further SSH/SCP/rsync/remote-shell access is authorized. The durable workflow performs none; remote evidence is explicitly operator-supplied and mutations are operator-controlled. This boundary is inspectable in READING-BOOTSTRAP and explained in the page.

If a remote executable witness is desired, the operator may run the read-only dependency command shown in the reading page. Expected: supported D2 v0.9.0 with TALA. No such returned runtime witness is claimed here. To deploy this local reconstruction, the operator must advance the server checkout to the resulting dreyeck.ch commit and restart the service under their normal deployment procedure. Local tests do not establish that this has happened.

## Recorded validation results

Fresh baseline archive of e2928cce: **12 Catalog items**. Fresh reconstructed Catalog: **13**. The ordinary unchanged launcher was run locally, with a temporary assertion inserted before serving; both reading pages were retrieved, all twelve TALA and ten Workflow source widgets each contained one callable thunk, and the authoring package was absent. The same assertion is persisted in `fresh-catalog-evaluations`, preserving the existing startup/controller checks. No reading system was manually loaded before the normal Catalog startup.

The workflow runtime tests, explicit authoring tests (including writer absence in the fresh child), all ten reading play buttons in ordinary and authoring environments, existing TALA reading/integration tests, and the workflow Workspace's existing TALA navigation checker passed. The original TALA input/real-workspace tests reported D2 v0.9.0, seed 44, two Topics, one Association, exact SVG identity coverage and native Inspector thunks. Runtime startup uses the unchanged old dependency pin; D2 is optional for registration. Dependency libraries produce existing warnings; tests do not hide them.

## Explicit live-image change tracking (follow-up slice)

Direct pre-change observation: worktree `/Users/rgb/workspace/hyperdoc-workflow-reconstruction`, branch `dreyeck.ch`, HEAD `43bcb871a0df00e128a002808c86343d8b2c3520`. Tracked source was clean; the pre-existing untracked `dreyeck/pages/.DS_Store` was left untouched.

The question “What in the running image is not yet persistent?” now has a bounded executable answer: registered live-image changes whose reconstruction has not been verified. `REGISTER-CHANGE` records an ordinary function symbol, its EQ fdefinition and the existing `OBSERVE-OPERATION` result. `*CHANGE-LOG*` is the default image-local log; explicit `CHANGE-LOG` instances isolate examples/tests. `OUTSTANDING-CHANGES` returns a fresh oldest-first list. `OBSERVE-CHANGE` distinguishes the recorded observation from the current observation and says whether the captured function is still current. This is recording before observation/planning, not a second persistence implementation.

Same symbol plus identical function object returns the identical record. A different fdefinition produces a distinct record; the old one remains outstanding. An unregistered redefinition is visible when observing an existing record, but does not silently create a new registration. `CHANGE-RECONSTRUCTION-STATUS` is explicitly `:UNVERIFIED`: no clearing transition is included. Source discovery, ASDF load and source writing cannot clear records. Future verification must establish the relevant change identity through the existing fresh-process acceptance seam; no unsupported success flag is provided here.

The tests cover source-less compiled functions (`:SOURCE NIL`, `:UNOWNED-OR-UNAVAILABLE`), unregistered function exclusion, duplicate registration, subsequent redefinition, retained old records, fresh query list ownership, and source-located functions remaining unverified. Existing authoring semantics and pins are unchanged. All Lisp modifications use the same pinned structural writer and complete-file read-back checks.

`READING-OUTSTANDING-CHANGES` is the eleventh real transcluded DEFEXAMPLE. It uses an isolated log and fresh symbol, mutates only example-owned live state, and returns records plus observations for Inspector navigation. It relates recording to Medley MARKASCHANGED and pending-work display to FILES?, without claiming FILEPKG compatibility. Ordinary Catalog still has 13 books; the startup test now reconstructs 12 TALA and 11 Workflow source/play thunks.

SLY/mREPL:

```lisp
(dreyeck/workflow:outstanding-changes)
```

After an intentional mutation, explicitly register its name, for example `(dreyeck/workflow:register-change 'cl-user::workflow-live-only-increment)`. Use `CHANGE-OPERATION`, `CHANGE-OBSERVATION` and `OBSERVE-CHANGE` to continue into existing observation and ownership/planning facilities. The list and records are ordinary inspectable objects.

Limits: no global scanner, interception, decompilation, remote access or persisted image log. Unregistered changes are invisible. Registration is sequential; synchronization of concurrent writers is outside this slice. DEFVAR preserves the log across ordinary source reload, not across process restarts. No transition to verified or discarded is implemented.

Fresh validation commands for this follow-up:

```sh
nix develop path:. -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/workflow/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/catalog/tests")'

nix develop path:.#workflow-authoring -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/workflow/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/authoring/tests")' \
  --eval '(asdf:test-system "dreyeck/workflow/reading/tests")'
```
