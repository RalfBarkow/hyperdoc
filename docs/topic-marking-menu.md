# Topic marking-menu integration

Implemented from clean `090656dbc7ec1ab2e39ecadaabac5f09dab609c6` on
`dreyeck.ch`. Model C, strict CURRENT-TOPIC, and the unprojected-Point Work
status-action fix remain unchanged. The Point panel and explicit sign inspection
table are retained.

The browser evidence below records this slice at `6ab7e62b`. PRIMARY was
subsequently corrected to compose Point movement and applicable Follow; see the
[PRIMARY activation report](topic-primary-activation.md). SECONDARY remains as
described here.

## Operations and fixed directions

The existing Gesture → Binding → semantic-operation-identity →
`operation-inspectable-object` path now offers three ordinary identities:

| Topic operation | Identity | Direction | Offering / result |
| --- | --- | --- | --- |
| Change work status (existing) | `operation/change-work-status` | 0° / right | Existing declared Work Topic applicability and execution. |
| Follow | `operation/follow` | 90° / down | Represented `fedwiki-page` or `federated-subject`; calls unchanged `follow-context-object`. |
| Inspect represented object | `operation/inspect-represented-object` | 180° / left | Non-NIL represented object; returns the exact Topic.object. |
| Inspect Topicmap sign | `operation/inspect-topicmap-sign` | 270° / up | Existing Topic occurrence; returns its exact Topic. |

Each operation has radial-menu and learned-mark bindings with the same identity,
center, and 30° half-width. Missing operations leave their fixed sector vacant.
At the reference commit, Change work status was the only production provider
of bindings for `:workspace-action-sign-occurrence`; it supplies both paths at
0°. Source-declaration gestures and Association bindings target different
structures. The existing Association contract inspection remains at 0°.

Tests inspect the actual applicable catalogues in generic, federated, and Work
environments. Within each interaction kind they compare every pair's circular
angular distance with the sum of its half-widths, requiring strict separation
because sector boundaries are inclusive. They also assert EQ operation identity
and identical centers for every menu/mark pair, including Work's existing pair.
Unsupported represented objects have no Follow binding; absent objects have
only sign inspection. Remaining inspection centers do not shift.

The new execution methods derive the Topic through `occurrence-topic`, using the
existing exact occurrence target. The shared ordinary validation helper refuses
wrong target types; object inspection refuses missing objects; Follow refuses
unsupported objects with the existing `operation-not-applicable` condition.
Execution never consults Workspace Point. Results use the unchanged gesture
selection and `%open-beside` transport.

The federated Follow binding provider is an around method specialized on T,
less specific than Work's existing occurrence-specialized around method. Both
providers therefore compose without replacing Work's method or adding a
provider protocol. Its runtime check restricts Follow to supported occurrences.

## Shared visible menu

Association menu drawing and element construction are now shared ordinary
helpers, `%draw-sign-menu`, `%sign-menu-element`, and `%make-sign-menu`.
Both consumers obtain their labels from `menu-bindings` on their existing Gesture
Window and target. Each label retains its Binding's angle; only the selected
learned mark's label appears. Completion or cancellation hides all labels.

Topic setup uses its existing projection callback, listener, reveal timer and
Gesture Window. Association setup uses the same factored drawing helpers.
Labels accept no pointer input. Their width is bounded to 140px with wrapping:
the browser showed a small overlap between the Work status and object-inspection
labels with the original unbounded Association style; bounded labels have
disjoint rectangles without changing directions.

No Operation classes, command framework, registry, applicability protocol,
direction registry, selected-Topic state, new event transport, browser domain
state, or parallel Follow/Inspect implementations were added. The added structures
are three identity values/accessors, six fixed bindings, three execution methods,
one Follow binding provider, and one shared target-validation helper. Existing
menu construction/drawing was factored for two consumers.

## Browser proof, 2026-10-05

An isolated localhost CLOG Inspector ran the actual federated TALA example in
Chrome headless. DOM-dispatched pointer/click events traversed the production
CLOG handlers, reveal timer, reducer, operation methods and Inspector pane
transport. They were synthetic (`isTrusted=false`); this is not a physical-input
or native pointer-capture proof. Test instrumentation lived outside application
code and counted GO-TO, Follow, source refreshes and exact operation results.

Federated A was Jan / John Dewey; B was Thompson / How We Think, with temporal
cursor 10. Work A was hyperdoc-page-authoring; Work B was lisp-source-authoring.

| Interaction | Observed result |
| --- | --- |
| SECONDARY hold on B, reveal, Follow down | All three applicable Topic labels visible; exact B page followed and opened in its default Story view. Point A, identical history, cursor 10. |
| Immediate learned Follow down on B | No menu-visible snapshot; same EQ Follow identity and same B page/Story result. Point A, identical history, cursor 10. |
| Object inspection left, both paths | Exact B represented object returned and opened; Point/history/time unchanged. |
| Sign inspection up, both paths | Exact Topic B returned and opened; Point/history/time unchanged. |
| PRIMARY B | Point B, history `[A]`, exactly one Point mark, same live occurrence, cursor 10; no new operation execution, Follow or `%open-beside`. |
| Work status right, visible menu and learned mark | Existing 0° operation selects Work B's exact editor context/Workspace; Point stays Work A with the identical history. Applicable status/object/sign sectors and visible label rectangles are disjoint; Follow's 90° sector is vacant. |
| PRIMARY Association | Opens the exact Association; Point/time unchanged, no secondary operation. |
| Association contract inspection right, both paths | Existing identity and exact relation-contract result; visible menu contains its binding-derived label; Point/time unchanged. |
| Association without a relation contract | Existing execution-time refusal; no new result pane. |

All checked secondary effects made zero GO-TO calls and zero source-pane
refreshes. The PRIMARY control made exactly one GO-TO and no source refresh.
Follow was invoked exactly twice, once by each Follow path. The pane transport
opened each exact returned object. No scroll compensation was introduced.

The explicit inspection table now duplicates the menu's ability to inspect an
arbitrary projected Topic/sign or represented object without moving Point.
It remains available and tested. Point-panel Follow and gesture Follow both use
the same unchanged `follow-context-object`; the panel was not rewritten to invoke
operation identities.

## Tests and scope

The following passed in the pinned repository runtime:

- `dreyeck/topicmap/gesture/tests`
- `dreyeck/gesture/operation-request/tests`
- `dreyeck/gesture/clog/tests`
- `dreyeck/gesture/transport/tests`
- `dreyeck/gesture-binding-witness/tests`
- `dreyeck/gesture/reading/tests`
- `dreyeck/work/reading/tests`
- `dreyeck/topicmap/tala/tests` (including D2 v0.9.0 / seed 44)
- `dreyeck/work/authoring/tests` in the required workflow-authoring environment

The reading run additionally asserts that workflow-authoring is absent. The
authoring environment uses workflow-editor commit
`38afb02d79838d4098589c2e203ba39799a44853`. Its full Work editor suite includes
the existing unprojected Workspace status-action / all-views regression.

Durable new tests cover exact A/B operation targets, Point/history/time
preservation, menu/mark identity and angle equality, sector separation,
applicability/refusal, supported Subject offering, vacant directions and the
unchanged PRIMARY reference. Existing reading and browser Work assertions now
check Work-specific offerings while allowing generic inspection bindings.

The federated production diff adds only the Follow bindings and method, between
unchanged `follow-context-object` and primary-reference definitions. Workspace
implementation/package and Work authoring production files are byte-identical
to the reference commit. Point/Projection lifetime, subject resolution, temporal
selection, Point panel, inspection table, Work status correctness fix, authority
policy, and Association operation semantics are outside this change.
