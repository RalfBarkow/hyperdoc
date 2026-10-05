# Topic PRIMARY activation

Built from clean `6ab7e62b8924ebe20f8013a8b9cc54974b821359` on `dreyeck.ch`.

## Previous and corrected behavior

Previously, a federated context Topic sign's PRIMARY action moved Workspace
Point and returned NIL. Follow required a separate explicit operation.

A followable context Topic sign now composes:

1. `topicmap-workspace-go-to` for its exact Topic ID;
2. the existing local Point presentation callback;
3. `operation-inspectable-object` with the existing EQ Follow identity and
   that sign's existing occurrence target;
4. the Inspector's existing `eval` reference handler opening the returned
   material beside the source.

Point, its mark, panel and relations are established before Follow executes.
Repeated activation still follows, while unchanged Point needs no redraw and
adds no history. Ambiguity or operational failure evidence uses the unchanged
Subject chooser behavior. An execution error does not undo Point movement.

Non-followable context signs retain movement-only `action` references and return
NIL. There is no fallback Inspect/default operation. Relation-endpoint references
remain movement-only, even when their endpoint's object is followable. Temporal
sign references retain temporal selection. Native Work PRIMARY remains its
existing Point movement; its represented HyperDoc object is not Followable.

## Applicability, identity and transport

`context-followable-object-p` extracts the existing supported page/subject type
decision. Binding offering, execution-time refusal and PRIMARY reference selection
now share it. `follow-context-object` retains its authoritative ETYPECASE and
unchanged page/subject resolution. No new identity, resolver, applicability
protocol or default-operation registry was introduced.

The existing `context-point-action` gains one transient `operation-target` field.
After the generic Inspector adapter creates the sign occurrence,
`bind-context-point-actions` associates EVAL activations with that exact occurrence
by EQ reference. The target is the same existing plist/occurrence representation
used by SECONDARY. The field stores no Point, Projection lifetime, selected Topic
or browser domain state. Relation endpoints receive no activation target.

PRIMARY returns the semantic operation's result through the existing Inspector
EVAL transport. SECONDARY still uses its unchanged gesture result / `%open-beside`
transport. Both reach the same Follow identity and execution method. No reusable
operation-invocation helper was needed: existing calls compose without duplicating
pane-opening, refusal or Follow semantics.

## Browser proof, 2026-10-05

Actual CLOG handlers ran in isolated localhost Chrome headless sessions with
synthetic DOM pointer/click events (`isTrusted=false`). This proves the production
CLOG/reducer/operation/Inspector path, not physical input or native capture.
Test instrumentation and the offline HTTP-miss boundary stayed outside production
code. The real subject resolver was retained.

| Control | Observation |
| --- | --- |
| Page PRIMARY: A = Jan / John Dewey, B = Thompson / How We Think | Point B; history `[A]`; exact B page opens in Story. EQ Follow identity and exact B occurrence. Point, panel and mark already B when Follow begins. Cursor 10, zero source refreshes. |
| Subject PRIMARY from A: How We Think | Point becomes `concept:How We Think` before Follow. Existing chooser opens with three captured candidates and no resolution failures; Point remains B, cursor 10. |
| SECONDARY visible-menu Follow on B from A | B's exact page opens through `%open-beside`; Point remains A, identical history, no GO-TO or source refresh. |
| Immediate learned Follow on B from A | Same EQ Follow identity/occurrence/result; no menu-visible snapshot, unchanged Point/history/time. |
| Relation endpoint from A: Jan / How We Think | Moves Point to this followable page Topic; no Follow or other operation, cursor 10, zero source refreshes. |
| Temporal PRIMARY | Cursor 10 → 8; same Workspace, Point `concept:How We Think`, identical history; no Follow/operation. Existing temporal refresh behavior remains. |
| Non-followable Work PRIMARY: lisp-source-authoring | Point moves from hyperdoc-page-authoring; history records that prior Point. No Follow, other operation or new pane. Native PRIMARY behavior and status bindings at 0° remain. |
| Local PRIMARY after temporal re-projection | Exact current page opens. All five relations at B are already rendered when Follow executes. Zero additional source refreshes; source body, Point container and both map containers retain their identities and offsets. |

For the final local activation, measured source body scrollTop stayed 538,
context offsets stayed `(123, 234)`, and temporal offsets stayed `(0, 2013)`.
The complete before/after snapshot, including container IDs, was identical.
PRIMARY used the Inspector's existing EVAL pane opening and made no
`%open-beside` call. No application scroll save/restore was added.

## Durable tests and unchanged scope

The updated rendered-reference tests bind the same concrete reference/occurrence
association as CLOG. They prove Point/presentation before Follow, exact primary
page results, repeated activation without another Point update, and PRIMARY
subject resolution for zero, unique, ambiguous and incomplete candidate sets.
The identity test records all three successful Follow invocations—radial, learned
and PRIMARY—and requires the same EQ identity and exact Topic B. SECONDARY sees
Point A; PRIMARY sees Point B.

A non-followable object control checks movement-only ACTION/NIL with no semantic
operation call. A forced Follow execution error checks that Point B and its new
history entry survive. Relation-endpoint and temporal controls retain no-Follow
assertions. The Model C test establishes its positions through movement-only
references so re-projection can still categorically refuse any Follow effect.

Passed in the pinned repository runtime:

- `dreyeck/work/reading/tests`, including Model C, subject controls and the new
  activation/error assertions; workflow-authoring asserted absent.
- `dreyeck/topicmap/gesture/tests`.
- `dreyeck/topicmap/tala/tests`, including D2 v0.9.0 / seed 44.
- `dreyeck/work/authoring/tests` in the required workflow-authoring environment,
  using workflow-editor commit `38afb02d79838d4098589c2e203ba39799a44853`, including
  the existing unprojected status-action/all-views correctness regression.

Generic Workspace/Point/Projection implementation, the Work status fix, gesture
transport/reducer, operation identities, SECONDARY execution, fixed binding pairs,
Association behavior, Point-panel Follow and the explicit inspection table remain
unchanged. Binding-pair consolidation and authority policy were not part of this
slice.
