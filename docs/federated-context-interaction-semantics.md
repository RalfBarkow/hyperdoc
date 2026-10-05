# Federated-context interaction semantics

Context Topicmap navigation follows the generic Workspace editor model:

- Primary context-sign click moves Workspace Point to that Topic.
- A relation endpoint at Point moves Point along the graph.
- Follow at Point operates on `topicmap-workspace-current-object`.
- Explicit inspection at Point targets either that exact object or its Topic sign.
- Temporal sign clicks and Previous/Next select events and rebuild State/Delta.

Point movement, Follow, inspection, and temporal selection are independent.

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

The federated renderer keeps the non-destructive transport proven in `92025a7d`:
the ordinary Point action calls `topicmap-workspace-go-to` and returns NIL. Its
existing evaluation callback updates only the Point panel and existing map mark.
New relation-endpoint actions receive that same callback whenever the panel is
replaced. Repeating the current Point does not redraw. The pane, outer body,
context viewport, temporal viewport, map geometry, and per-sign inspection table
remain present. Point movement never calls Follow or temporal selection.

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

The explicit `Set Workspace Point` button is removed because primary clicks and
relation endpoints now use that exact Point operation. `select-context-topic` is
removed: it only wrapped go-to and returned T, which would request the unwanted
full refresh. No additional `projection-kind` branch disappears in this slice;
the necessary temporal/context construction and primary-dispatch distinctions
remain. The per-sign highlight branch was already removed in `92025a7d`.

The explicit per-sign inspection table is retained and tested. Its two targets
can now also be reached through Point, making it structurally redundant for
inspection of the current Topic. It still supports inspecting another sign without
moving Point, and remains useful for comparison.

## Point survival and history observation

When temporal selection or State/Delta changes yields a different context
projection object, `context-current-workspace` creates a new Workspace. It keeps
the prior Point ID if present. If absent, it chooses the selected event's page ID
when present, otherwise the projection's first Topic; an empty projection yields
NIL. History is not copied, even when Point survives. Returning to a cached
projection does not recover its old Workspace history. These existing rules are
observed, not repaired in this slice.

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
changes cursor 10 → 8, retains C by ID, and observes the existing history reset.
The per-sign inspection tests and unique/ambiguous/incomplete subject controls
remain in place, now exercising Follow from Point. Repeated render/rebuild at all
11 events leaves empty catalog/neighborhood registries empty and raw evidence
unchanged.

Browser verification on 2026-10-05 used synthetic DOM clicks through the real
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
| Temporal event | Cursor 10 → 8 and four Delta relation changes; Point C survived by ID. Follow count stayed one, pane count stayed two, and the existing open Inspector object stayed `EQ`. The existing temporal path performed one source refresh and created a new Workspace with empty history. |

The Work reading and TALA suites passed, including the native renderer tests and
D2 v0.9.0/seed 44 integration. Follow, subject resolution, and Workspace rebuilding
were also compared byte-for-byte with `40bdaadc` and remain unchanged. The browser
proof introduced no application state or transport; the witness ran outside the
application.

Run the automated suites in the pinned TALA environment:

```sh
nix develop .#tala --command sbcl --noinform --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/tests")'
```

For manual verification, open the `federated-context` Topicmap at cursor 10, click
Thompson / How We Think, then use Follow and both inspection links in the Point
panel. Use a relation endpoint to move Point to another Topic, then click a
temporal event. Point survives if its ID is in the resulting projection. The
separate inspection table remains under **Inspect context signs and represented
objects**. Candidate fixtures replace only the HTTP boundary; their resolution
results do not assert what a different live neighborhood will resolve today.
Authority policy and possible ungated outbound lookups remain outside this slice.
