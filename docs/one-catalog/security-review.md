# One production Catalog: security review of the public Topic Maps surface (revision 2)

2026-10-29, on the working tree of `claude/one-catalog-topic-maps` (base `0c388f95b35b282f6d6437ef158eb16207c7434a`), uncommitted.
Revision 1 found that `run-button` was a test-time gate only and listed owner decisions. This revision implements the owner's decisions and
replaces the test-time gate by a run-time boundary. Evidence is in `evidence/security/` (revision 1) and `evidence/security-2/` (this revision);
the earlier build, snapshot and browser evidence in `evidence/` predates both.

Labels: **[obs]** observed in a run; **[der]** derived from source; **[open]** not established or not decided.

## What was decided, and what was done

| # | Decision | Done |
|---|---|---|
| 1 | Remove the newly added direct *Existing Work Workspace* link from the public view; keep existing navigation | The link is **not new code**: it is in the base `tmdm-work-entry` view, and became part of the public surface only when the readings did. It is now left out when the policy is enforced (served) and kept in a development server, so the local reading and `scripts/test-tmdm-model-navigation.mjs` are unchanged. The Workspace itself and every other route to it are untouched. [obs] |
| 2 | An unset `HYPERDOC_CATALOG_HOST` is `127.0.0.1` | `scripts/catalog-main.lisp` sets it before anything is loaded; an explicit host is kept. [obs] |
| 3 | A run-time boundary for executable Inspector actions, local to the authority layer | Done in `dreyeck/src/authority-policy.lisp`, no change to the Inspector. [obs] |
| 4 | Inspect `request-through-binding` and the Trails context actions | Below. |
| 5 | The `CONTEXT-FEDWIKI-PAGE` drift correction in a separate commit | Prepared as a patch, not applied here. Below. |

## 3. The run-time boundary

**Where.** The Inspector registers a control by `html-id` pushing `(id . thunk)` on the view accumulator, a view computes its references in a
`:before` method of `view-html` and `view-references`, and the click path (`eval-thunk-with-active-button`) evaluates whatever thunk is there. All of it is
upstream. The layer already relied on the first and last; the digests of `html-id` and of `view-references :before` are now in
`+containment-adapters+` too, so a change upstream is reported by the drift check [obs: no digest drifted].

**What.** Two methods of this layer, `:after` on `view-html` and on `view-references` for `html-view`, call `contain-controls`: when the policy is enforced, every
reference whose id begins `eval-` or `action-` and whose target is a thunk that is none of

- an `operation-thunk` or an `example-thunk` (they decide again when clicked),
- a `reviewed-thunk`, made by a call site that names a control registered in `authority-policy.lisp`,
- an instance of a reviewed class (`topic-action-reference`, `association-action-reference`, so `context-point-action`),
- a `refused-thunk`

has its cdr replaced, in place, by a `refused-thunk`, whose `eval-thunk` returns an `invocation-refused` condition and never calls the original. A target that is not a
thunk is left (the Inspector's `eval-thunk` returns it and a pane opens). Where the policy is not enforced nothing is replaced.

**Why a local boundary is enough.** Both the HTML and the references of a view pass through those two readers before the Inspector sees them, and the second is read again each time, so a control
appended later is replaced on the next read [obs]. Refusing at `hv:eval-thunk` instead would stop rendering: the Inspector evaluates plain thunks for lazy lists and views. Refusing in the
click path would modify upstream. Neither is needed.

**What it does not cover.** CLOG views (*Source*, *Text*, *Playground*) bind their own handlers, not thunks; the Playground evaluates only under `:playground? development`. A refused button is still drawn;
clicking it shows a refusal. A *reviewed* control is as reviewed as its registry entry: the registry is greppable and every use is checked against it (below).

**Tests, creation and invocation separately** (`dreyeck/tests/authority-policy.lisp`, `check-control-boundary`; all [obs]):

| | Served | Developing |
|---|---|---|
| creation: plain `hv:eval-button` | target is a `refused-thunk` whose original is the plain thunk; nothing ran | untouched |
| creation: plain `hv:action-button` | same | untouched |
| creation: `reviewed-thunk`, non-thunk target | kept | kept |
| invocation through the Inspector's click path | the refused control returns `invocation-refused`; its function **never ran**; the reviewed one ran | the plain one ran |
| a control appended to the references after the view was computed | replaced on the next read; clicking it is refused | n/a |
| `reviewed-thunk` with an unregistered identity | error at creation | error |

The click path is the Inspector's own function, run without a browser by stubbing the two CLOG calls it makes on the button. `check-reviewed-controls-match-their-sites` requires the registered identities to equal those the sources use. Mutants, each killed:
`contain-controls` a no-op; everything permitted; the `:after` on `view-references` removed; a dead registration (`evidence/security-2/mutants.txt`).

## 2. The inventory, again

The six objects are unchanged (revision 1 §1) except that object 4 no longer links the Workspace when served. `HYPERDOC_CATALOG_SYSTEM=dreyeck/work/topic-maps-ctm-review`
loads the readings; the seven buttons are still five call sites through `run-button`, which now also registers nothing.

**Walk** (300 objects, depth 2, from the six objects and the definitions of the two refused systems, served) [obs, bounded, **not exhaustive**]:
9,538 controls: 8,478 inert (target not a thunk), 993 slot-reader operations, 11 reviewed thunks, 56 instances of reviewed classes, **0 refused, 0 of unknown kind**.
So nothing the walk reached is disabled by the boundary. The reviewed controls it met are the Workspace *Go to topic* controls (`topicmap/workspace-go-to` and the topic signs); the conversation cursor is exercised by name below.

**Reviewed controls kept** (`evidence/security-2/reviewed-controls.txt`):

| Identity or class | Effect | Made at | Reachable from the six objects |
|---|---|---|---|
| `conversation/select-message` | bounded cursor of one session | `conversation-coordinates-reading.lisp:369-370` | yes: work topic → *Conversation sources* → session → *Chronology* |
| `topicmap/workspace-go-to`; `topic-action-reference`; `association-action-reference` | moves the Workspace Point (and pushes its history); the association one does nothing | `topicmap-inspector.lisp:124, 228, 488` | yes, through the Work Workspace's *Topicmap* view |
| `gesture/request-through-binding` | finds or makes the in-image request object for an operation on a definition | `gesture-operation-request.lisp:260` | yes: the CTM review hyperbook's code pages, view *Operations* (9 controls) |
| `trails/select-context-event`, `trails/set-context-mode`, `trails/follow-context-object`, `trails/native-context-page`; `context-point-action` | cursor, display mode, resolve a page the context's own data names | `trails-rendered-federated-context.lisp` | **not reached** (below) |
| `tala/guarded-action` | delegates to the original, gated action | `topicmap-tala-reading.lisp` | not reached |

**4a. `request-through-binding`.** Reached by navigation, then clicked in a served image: it returns an `operation-request`, a data object. Its views offer 547 controls: 516 inert, 31 slot readers, none reviewed, none refused [obs].
`ensure-operation-request` resolves the occurrence (reads page source) and memoises the request; it writes no file and runs no operation [der]. It cannot invoke executable behaviour from the controls it offers [obs for the controls, der for the rest].

**4b. Trails context actions.** From the six objects, a breadth-first search to depth 3 and 500 objects found no Trails or federated-context object [obs, bounded]. They are reached from the Trails pages of the existing Catalog, as before. Their controls change a cursor or a display mode, or resolve a wiki page
(`follow-context-object` may read the sites that context's own data names); none runs a page's code. They were plain thunks; they are now reviewed so that the boundary does not disable a reading the Catalog already serves.

## 4. An unknown button is rejected at run time [obs]

Beyond the creation and invocation tests above, `check-an-extra-button-is-refused` reaches a probe object by the walk, as a visitor would: its `hv:eval-button` is a `refused-thunk` and clicking it is refused. The seven original buttons remain markers with nothing registered (`check-view`, and the browser walk).

## Verification

| What | Result |
|---|---|
| seven buttons inert served; buttons developing | 6 objects, 7 buttons [obs] |
| development behaviour | the 46 HTML views of the six objects are identical to the base's after normalising ids, addresses, paths and counters (*developing: identical 46, different 0*). Served, four differ, by the seven buttons and by the missing Workspace link in object 4's view [obs] (`evidence/security-2/base-vs-candidate-views.txt`) |
| allowed controls work | Lisp: the conversation cursor moves and moves back, and a Workspace control is not refused, through the Inspector's click path [obs]. Browser, packaged, served: *Next selected message* moves the cursor `Message #2 → Message #8` and *Previous* moves it back, by real clicks [obs] |
| Project Workspace, page-attached loader | unchanged guard; startup refusals in the executable tests; closure check; the walk that started at their definitions met no control of an unknown kind [obs] |
| host | unset, empty, explicit `127.0.0.1` listen on `127.0.0.1`; explicit `0.0.0.0` listens on `0.0.0.0`, in the packaged executable [obs, Darwin and Linux] |
| `authority-policy` tests | the gate checks (12 of the suite's 15) run in the Nix check on both platforms; three are environment-dependent and run on a developer machine (§5) |

## 5. The adapter drift, and its separate commit

The single entry is `new title-bar actions on …CONTEXT-FEDWIKI-PAGE` (unchanged by this revision, at the base too). Verified, not assumed: `CONTEXT-FEDWIKI-PAGE` **is a subclass of `fedwiki-page`**
(`check-title-bar-actions-withheld` asserts it, and asserts that for every class with a primary title-bar method a withholding `:around` of this layer applies, with the two reviewed exceptions of revision 1). So its actions are withheld
served, and the known-class baseline is merely stale.

`evidence/security-2/drift-correction.patch` adds `"CONTEXT-FEDWIKI-PAGE"` to `+known-title-bar-classes+` with a comment naming that test. It is **not** in this candidate. Applied to a scratch copy of the candidate, the whole `dreyeck/authority-policy` suite
passes, including the drift check [obs]. It is to be its own commit, after review, because it edits a reviewed security baseline.

Three checks of that suite cannot run in the Nix sandbox and are excluded from `run-gate-tests`, which the Nix check runs: `check-fedwiki-actions-withheld` (reads `~/.wiki/dreyeck.ch`), `check-reload-withheld` (needs a HyperDoc the user can write; in the sandbox
the source is a store path owned by another user, so the Reload button is not offered even unserved) and `check-adapters-as-reviewed` (the drift). They run in `run-tests` on a developer machine.

## 8. Host, precisely

`scripts/catalog-main.lisp` sets `HYPERDOC_CATALOG_HOST` to `127.0.0.1` when it is unset or empty, before anything is loaded; it keeps any other value. The old staging rule (refuse every host but loopback) is **not** restored and no restriction beyond the default is added.
The production service sets `127.0.0.1` itself and nginx proxies to it, so its behaviour is unchanged [der]; a service that wants another interface says so.

## Limits, stated

- The walks are bounded (300 objects, depth 2; 500 objects, depth 3), over the HTML views and the title bar. They sample what a visitor can reach; they do not prove that no other control exists. What stands behind them is the structure: every control passes the two readers above, and every plain thunk among them is replaced when served.
- Controls made by a view that is not an `html-view` (CLOG views) are not covered; the three CLOG views of every object were listed in revision 1.
- A refused control is visible. A *reviewed* control is trusted as far as its registry entry is accurate; the entries state their effects and were checked against the sources, not exhaustively executed.
- The `trails/*` and `tala/*` controls were converted to reviewed thunks but not exercised.
- `topicmap-workspace-go-to` still pushes the Point history without bound (unchanged, and now a documented reviewed effect).
- Security evidence is on the Darwin working tree and the x86_64-linux Nix check named in the evidence table; the Linux builder has the Nix sandbox off, and the Nix check there runs without it.

## Found on the way, not in scope

- **A client that disconnects while the first page is being written can end the whole process.** In one Linux Nix-check run under load, the executable test's 1-second HTTP timeout closed a connection mid-response; two `hunchentoot-worker` threads
  logged `Unhandled SB-INT:BROKEN-PIPE`, and the process exited (the test saw it gone). `--script` disables the debugger, so an unhandled error in a worker thread is fatal [obs once; consistent with the mechanism; **not reproduced in isolation**].
  This is the base Catalog's behaviour (same wrapper, same server), not caused here. If it holds, any public client can take the service down until `Restart=on-failure` brings it back (about 30 s on the server). The executable tests now wait 30 s per request so they no longer provoke it.
  [open] A separate task: handle the condition in the worker or the server.
- **The pure builds on the server used its disk**: each candidate build leaves unrooted store paths (free space 2.5 GB before, 2.4–2.5 GB after). Nothing was garbage-collected.
