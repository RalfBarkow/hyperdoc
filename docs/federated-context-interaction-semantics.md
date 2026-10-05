# Federated-context interaction semantics

Context Topicmap navigation follows the generic Workspace editor model:

- Primary context-sign click moves Workspace Point to that Topic, then invokes
  the existing Follow operation where applicable.
- A relation endpoint at Point moves Point along the graph.
- Follow at Point operates on `topicmap-workspace-current-object`.
- Explicit inspection at Point targets either that exact object or its Topic sign.
- Temporal sign clicks and Previous/Next select events and rebuild State/Delta.

Primary sign activation composes Point movement and applicable Follow. Explicit
secondary operations preserve Point; relation endpoints perform movement only.
Inspection and temporal selection remain separate operations. See the
[PRIMARY activation report](topic-primary-activation.md).

## Existing machinery

| Operation | Existing implementation used |
| --- | --- |
| Point movement | `topicmap-workspace-go-to`; sign and relation-endpoint references share `context-point-reference`, the existing `context-point-action` from `92025a7d`, and its local presentation callback. |
| Point panel replacement | Inspector `create-view-element` on the existing child container; it replaces child HTML and binds the new operation references. |
| Point mark | CLOG `attribute` setters on the existing TALA topic groups' `data-selected` attributes. |
| Follow/open working material | `follow-context-object`, `html-inspector-views:eval-button`, and the Inspector's existing `eval` handler (`create-pane`); native historical pages retain their Story/Links views. |
| Collaborative resolution | `make-wiki-link` → link thunk → `find-target-by-slug` → `lookup-slug-in-page-context`, retaining local/plugin/context precedence per source. |
| Open a concrete remote page | `find-hyperbook`, `find-page`, `load-page`; remote references retain `origin-of` and `origin-id-of`. |
| Persist/materialize | `materialize-fedwiki-page-json`. |
| Genuine local fork | `materialize-fedwiki-page-fork`, which appends a fork journal entry and persists JSON in the local site's page store. |

`follow-context-object` and subject resolution are unchanged from `40bdaadc`.
A page at Point follows the exact represented native historical page, with Story
selected by default. A subject follow evaluates its existing historical collaborative
links and uses the native context/neighborhood resolver. One complete candidate
follows directly; zero or multiple candidates, or lookup failures, show the existing
Subject chooser with site-qualified choices and failure evidence. No arbitrary
choice or new dispatch protocol is introduced. No Topic subclass is required.
`make-remote` remains an in-memory remote reference, not a persistent fork.
Materialization and genuine local forking remain explicit separate operations.

## Why Point movement does not rebuild the pane

The native renderer at `40bdaadc` creates a `topic-action-reference` whose thunk
returns the Topic returned by `topicmap-workspace-go-to`. Relation go-to buttons
also return that Topic. The Inspector's action handler treats any non-NIL result
as a request to `refresh` the source pane. `refresh` destroys the pane's children,
including `.inspector-body`, then loads views and recreates the DOM. Native Point
marks and the Point/relations panel are refreshed through that complete rerender.

The federated renderer keeps the non-destructive Point update proven in `92025a7d`:
the movement thunk calls `topicmap-workspace-go-to` and returns NIL. Its existing
evaluation callback updates only the Point panel and existing map mark.
New relation-endpoint actions receive that same callback whenever the panel is
replaced. Repeating the current Point does not redraw. The pane, outer body,
context viewport, temporal viewport, map geometry, and per-sign inspection table
remain present. Movement-only references never call Follow or temporal selection.
Applicable Topic signs now use the Inspector's existing `eval` reference: after
movement and the local update, the action returns the result of the existing
Follow identity on its exact occurrence. That handler opens the result beside
the source without refreshing it. Relation endpoints retain `action` references
and return NIL. A repeated sign activation can Follow again without redrawing
Point or adding history.

Inspector already supports this child-view replacement. Its reactive `subview`
references use the same `create-view-element` operation on a child div when a
Lisp cell changes. `change` references are form-input-to-cell bindings, not SVG
click operations. Workspace Point is an ordinary slot, so neither a reactive
Point mirror nor another interaction transport is needed here.

The Point panel has a bounded 16rem height and its own overflow. Changes in its
relation count therefore leave the surrounding document layout stable. The old
outer-scroll save/restore compensation is removed; Point movement reads or writes
no scroll offsets. The existing initial/full temporal-render viewport positioning
remains presentation-only and is not run by local Point updates.

## Point panel and complexity

`render-context-point` has one role: show what is at Point and operations at Point.
It shows the Topic label; one Follow operation; distinct `Inspect represented
object` and `Inspect Topicmap sign` links; and relations with direction, association
inspection, and go-to buttons for the other endpoints. Endpoint identity and
direction come from the generic Workspace helpers.

At `bab61506`, the explicit `Set Workspace Point` button was removed because primary clicks and
relation endpoints now use that exact Point operation. `select-context-topic` is
removed: it only wrapped go-to and returned T, which would request the unwanted
full refresh. No additional `projection-kind` branch disappeared in that slice;
the necessary temporal/context construction and primary-dispatch distinctions
remain. The per-sign highlight branch was already removed in `92025a7d`.

The explicit per-sign inspection table is retained and tested. Its two targets
can now also be reached through Point, making it structurally redundant for
inspection of the current Topic. The [Topic marking menu](topic-marking-menu.md)
now also inspects an arbitrary projected Topic or its represented object without
moving Point, duplicating that table's inspection capability. The table and Point
panel remain unchanged in this slice.

## Persistent Workspace: Model C

One `TOPICMAP-WORKSPACE` owns the federated editing session. Its Point ID and
history survive temporal and State/Delta changes, while its Projection changes.
Point is the semantic position; the map's Cursor is its visible mark in the
current Projection. Point can remain established while that mark is absent.

The generic `topicmap-workspace-reproject` operation changes only the existing
Workspace's Projection and returns that same Workspace. It exposes no public
Projection SETF writer. `topicmap-workspace-point-projected-p` is the authoritative
presence predicate. GO-TO remains strict about target presence, and CURRENT-TOPIC
and CURRENT-OBJECT retain their strict/error contracts.

`context-current-workspace` now re-projects its existing Workspace. The following
projection-change structures disappeared: Point migration, event-page replacement,
first-topic fallback, NIL Workspace fallback, and Workspace recreation. There is
no second session object, Point mirror, retained stale Topic, or Cursor state.

Initial creation remains separate and strict: the selected event's page must be
present in the initial Projection. The real example starts at event 10 in State
mode, with Jan / John Dewey present. The data audit confirms every event's State
contains its event page. A first-time initialization in a Delta that omits its
event page is rejected rather than inventing a Point; empty/absent Deltas reached
after session creation are ordinary supported re-projections.

When Point is unprojected, both the federated and native Workspace Point panels
show its stable ID and **Not present in current projection**. They test the
predicate before calling CURRENT-TOPIC. The Point panel has no Follow, object/sign
inspection, or relation operations in that state. The separate per-sign inspection
table remains unchanged and can still inspect Topics that are projected.

An empty Delta retains the Workspace, Point, and identical history list. Returning
to a Projection containing Point restores its Cursor and resolves its current
Topic/object from that Projection. Only GO-TO records a previous Point in history;
re-projection neither pushes nor clears history. Back/history traversal is absent.

Work editing, native fixed-projection navigation, TALA comparisons, and
`make-topicmap-workspace-for-object` continue using their existing fixed-projection
behavior. Native Point-panel rendering additionally handles an unprojected Point
when explicitly re-projected. No caller is forced to change its Workspace lifetime.

Persistent Workspace identity makes an observable Point cell more compelling:
observers could share one stable session owner across coordinate changes. A Point
cell alone would not redraw the panel or Cursor when only Projection changes;
that dependency would also need observation. This slice keeps Point as an ordinary
slot and retains the local update path from `bab61506`, with no hvr:subview/lwcells
refactor or browser domain state.

## Verification

The A/B/C regression uses:

- A: Jan / John Dewey, the initial Point at cursor 10.
- B: Thompson / How We Think, a distinct historical native page.
- C: How We Think, the represented subject reached through a relation from B.

The regression evaluates the actual rendered references. Primary B returns NIL,
changes Point and its presentation callback once, and makes no Follow call.
Follow at B returns its exact represented page and leaves Point/time unchanged.
Both Point inspections reference the exact page/Topic. Relation navigation to C
uses the same Point action and preserves time and Follow count. A temporal click
changes cursor 10 → 8 and retains the same Workspace, Point C and history.
The per-sign inspection tests and unique/ambiguous/incomplete subject controls
remain in place, now exercising Follow from Point. Repeated render/rebuild at all
11 events leaves empty catalog/neighborhood registries empty and raw evidence
unchanged.

Model C verification on 2026-10-05 used the actual temporal example in a fresh
localhost CLOG Inspector image. Synthetic DOM clicks went through its real sign,
relation, temporal, and mode handlers. The witness checked Lisp `EQ` identity,
the exact history cons list, actual GO-TO/Follow counts, and rendered DOM:

| Interaction | Observed result |
| --- | --- |
| Initial A → primary B → relation C at event 10/State | One Workspace; Point C; history `[B, A]`; exactly one C mark. Two GO-TO calls, zero Follow calls, zero source refreshes. |
| Temporal sign → event 8/State | Same Workspace, Point C, and identical history list; one C mark and current operations. |
| Event 8/Delta | Five projected Topics, C absent; zero marks. Panel shows `concept:How We Think` and **Not present in current projection**, with no buttons, object/sign inspection links, or relation rows. |
| Temporal signs → events 6 and 2/Delta | Both actual empty Projections preserve the same Workspace, Point C, and identical history list; no marks or Point operations. |
| Event 2/State, then Delta → State | One C mark and current operations return in State; disappear in Delta. Workspace, Point and history never change; GO-TO count remains two. |
| Event 10/State → Delta → State | Delta contains A, the selected event's page, but retains absent Point C and its history. Returning to State restores C's mark without GO-TO. |
| Explicit primary D: Reflective Practice | Same Workspace; Point D; history `[C, B, A]`, with the previous history list as its exact tail. One D mark, Follow/both inspections and five relations. Third GO-TO, zero Follow, cursor still 10. |
| Local D update after re-projections | Same source pane, outer body and Point container; one pane and zero additional source refreshes. Outer scrollTop remains 708; context offsets remain `(123, 234)`, with no application scroll compensation. |

Temporal/mode actions retained their existing full render behavior (ten refreshes
in this walkthrough); graph navigation retained the local update path. No browser
domain state or new interaction transport was introduced. The witness lived
outside the application.

The generic re-projection regression additionally checks strict CURRENT-TOPIC,
CURRENT-OBJECT and GO-TO failure while absent; unchanged history on refusal; native
absence/return rendering; fresh Topic/object identity on return; and navigation
from an unprojected Point to a present Topic. The federated regression covers both
empty Deltas and the event-page-present/Point-absent negative control.

The complete Work reading and generic/native/TALA suites passed, including D2
v0.9.0/seed 44 integration and `make-topicmap-workspace-for-object`. The complete
Work editor suite passed in the pinned workflow-authoring runtime, including
Point rendering, native navigation, two-Workspace isolation, both authoring
operations, stale refusal and optional-TALA behavior. The first Work editor attempt
used the reading runtime and lacked the explicit authoring capability; rerunning
with the repository's configured authoring source/environment passed.

Editor interaction verification at `bab61506` on 2026-10-05 used synthetic DOM clicks through the real
CLOG Inspector handlers in an isolated localhost image. Lisp assertions checked
the actual pane objects, operation counts, and DOM values:

| Interaction | Observed result |
| --- | --- |
| Primary B, starting at A/cursor 10 | Point B; one local Point update; zero Follow calls, zero source refreshes, one pane. The mark, label and six relations changed to B. |
| Follow at B | Opened the `EQ` represented historical/native B page. Point B and cursor 10 remained; exactly one Follow call and a second pane. |
| Inspect object/sign at B | Opened the exact represented page and exact Topic, respectively. No additional Follow, Point movement, cursor movement, or source refresh. |
| Relation B → C | Point C, with its own three relations and selected mark; cursor 10, Follow count one, source refresh count zero. |
| Replaced-panel relations and repetition | C → B → C relation buttons remained live after replacement. Two more primary A → B → C cycles passed. Ten local updates total; no additional Follow or source refresh. |
| Pane/scroll identity across all Point operations | Same source pane, outer body `CLOG111`, context map `context-map-685`, temporal map `temporal-map-658`, and Point container `workspace-point-729`. Outer scrollTop stayed 708; context offsets stayed (123, 234); temporal offsets stayed (0, 2496.5). Point panel height stayed 256px. |
| Temporal event at `bab61506` | Cursor 10 → 8 and four Delta relation changes, without another Follow. That commit's Workspace recreation/history loss is superseded by Model C above. |

The Work reading and TALA suites passed, including the native renderer tests and
D2 v0.9.0/seed 44 integration. Follow and subject resolution
were also compared byte-for-byte with `40bdaadc` and remain unchanged. The browser
proof introduced no application state or transport; the witness ran outside the
application.

Run the reading/generic/TALA suites in the pinned TALA environment and the Work
editor suite in its pinned authoring environment:

```sh
nix develop .#tala --command sbcl --noinform --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/tests")'

nix develop .#workflow-authoring --command sbcl --noinform --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/work/authoring/tests")' \
  --eval '(dreyeck/work/editor/tests:run-tests)'
```

For manual verification, open the `federated-context` Topicmap at cursor 10, click
Thompson / How We Think, then use Follow and both inspection links in the Point
panel. Use a relation endpoint to move Point to another Topic, then click a
temporal event. Point and history survive even if its ID is absent; only its map
Cursor and operations disappear until Point is projected again. The
separate inspection table remains under **Inspect context signs and represented
objects**. Candidate fixtures replace only the HTTP boundary; their resolution
results do not assert what a different live neighborhood will resolve today.
Authority policy and possible ungated outbound lookups remain outside this slice.
