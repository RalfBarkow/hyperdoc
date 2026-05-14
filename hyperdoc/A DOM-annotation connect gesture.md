# A DOM-annotation connect gesture

Legacy title retained for continuity. The canonical user-facing concept in
this cluster is the Touch-Fahrplan route-laying gesture. Prefer `Lay route`
for user-facing copy, `drag-to-connect` for implementation mechanics,
`two-tap route-laying` for the non-drag fallback, and avoid plain `swipe` as
the durable term.

We are in ~/workspace/hyperdoc.
You may also inspect ~/workspace/dmx-platform for UX reference.

Refinement of the previous design:

Do not scope the route-laying gesture only to “existing inspectable objects”.
Instead, implement a more general first slice:

A Touch-Fahrplan route-laying gesture between any two DOM elements within a
single rendered tree/pane.

Goal:
Create a reusable HyperDoc capability where a user can lay a route between any
two rendered DOM elements in one pane, producing a first-class relation/route
annotation anchored to those two DOM positions.

Semantic boundary:
- Lay route = author a new relation/route topic between two visible anchors
- Follow route = traverse an existing relation/route
- In this first slice the visible anchors may still be DOM elements, but the
  authored result must read as a first-class route, not as a transient swipe

Current follow-up note:
- plain click on `Connect` still starts the existing gesture
- on smartphone/narrow viewports, the Dock route strip starts the same
  internal Connect route with the first station tap, so the visible grammar is
  `Tap a station` followed by `From: <source> -- tap target or operation`
- `Shift`-click on `Connect` opens the live Connect state snapshot object with `Summary`, `Panes`, `Transitions`, and `Payload / Anchors` views
- `Option` / `Alt`-click on `Connect` opens the deeper model/evidence side behind the same capability
- repeated modifier-click inspection from the same live pane reuses the same inspection target where the existing inspector reuse rules already apply, instead of opening an unbounded stack of duplicates
- `Shift` + `Option` / `Alt` follows the model/evidence path while preserving trailing right-hand panes
- the inspection surface reports current phase/session state and recent stage-log entries without changing the semantic-first persistence contract

This should be the general substrate.
The existing “missing step between Boot Raspberry Pi from flashed card and Edit /etc/nixos/configuration.nix” is then just the first concrete use case built on top of it.

Why this is better:
- more general than object-only connections
- closer to the DMX “lay a route between two visible things” UX
- lets HyperDoc treat rendered prose/headings/list items/links as annotatable anchors
- avoids prematurely locking the feature to one object family

Scope constraints:
- single rendering tree / single pane only for this first slice
- no cross-pane or cross-window connections yet
- no full graph editor
- no arbitrary canvas redesign
- keep the slice narrow and demonstrable

Please do this:

1. Inspect DMX for the interaction pattern
In ~/workspace/dmx-platform, find the relevant UI code for drawing/creating an association between visible topics.
Return a short grounded summary of:
- how the gesture starts
- what the user sees while connecting
- what gets created at completion

2. Inspect HyperDoc for the best DOM-level insertion point
Find where rendered pane DOM is created and where click/mouse events can be attached for a single inspector pane.
Identify the narrowest place to add a pane-local connect mode.

3. Implement a general route-laying mode for one rendered pane
MVP interaction:
- user activates a pane-local `Lay route` affordance
  - compatibility label `Connect` is acceptable if the UI cannot yet rename it
- first click picks a source DOM element / source station in that pane
- moving the mouse shows a temporary visible line/overlay or equivalent live route affordance
- second click picks a target DOM element / target station in the same pane
- completion creates or opens a first-class relation annotation / route object prefilled with:
  - source DOM anchor
  - target DOM anchor
  - pane/page/object context

If a true drag-line is too invasive for the first slice, acceptable fallback:
- two-tap route-laying:
  - click source
  - visible “laying route…” state
  - click target
- with a temporary overlay if possible

Mobile refinement:
- the canonical mobile form is now two taps with no separate Connect button:
  tap a source station, then tap a destination station or operation
- Annotation is a destination operation in that route language, so
  `Tap Text pages` followed by `Tap Annotation` creates or reopens the
  first-class source-to-Annotation relation
- the route strip carries the teaching copy; the large coachmark is not shown
  by default on narrow viewports

But prefer an actual temporary line if it is cheap in the current CLOG
inspector architecture. That line is the initial `drag-to-connect`
implementation of the route-laying gesture.

4. Define the anchor model
For this first slice, anchor the relation to DOM elements, not just objects.
Use the most stable anchor representation available in the current renderer, for example:
- element ids
- data attributes
- stable path/index selectors within the rendered tree
- or an existing internal reference/anchor model if one already exists

Be explicit about the stability tradeoff.
Do not pretend the anchors are stronger than they are.
If needed, limit the first slice to connectable elements that already have stable identifiers.

5. Define the created object
Create or reuse a general relation-annotation / patch-target object with:
- source anchor
- target anchor
- anchor context (page/object/view)
- optional label / relation kind
- optional note/annotation text

Prefer reusing existing annotation/patch-target machinery if possible.
Do not invent a parallel unrelated object model if HyperDoc already has one that can carry source/target anchors.
The resulting object should be describable as a first-class route between two
stations/topics, not only as an invisible payload blob.

6. Make the first concrete use case work
Use this concrete workflow example to prove the feature:
- in the official workflow rendering, connect:
  - “Boot Raspberry Pi from flashed card”
  - to “Edit /etc/nixos/configuration.nix”
- land in a prefilled relation annotation / patch-target object
- from there, the user can classify it as something like:
  - missing headless connection step
  - connect to the Pi over SSH
  - or similar inserted-step topic

Important:
The route-laying gesture should operate on the rendered DOM items themselves,
not require the user to separately inspect both objects first.

7. UI expectations
At minimum provide:
- a visible `Lay route` affordance in the pane
- visible source selection
- visible temporary route-laying state
- created/prefilled relation annotation / route object after target selection
- immediate inspectability of that resulting object

If there is already an “Edit / Patch Target” surface, it is acceptable and preferred to land there prefilled after the DOM gesture.

8. Keep it narrow
Do not solve:
- cross-pane relations
- cross-page global graph editing
- auto-layout
- every renderer in the system

Do solve:
- one pane
- rendered DOM elements
- temporary route-laying gesture
- relation annotation object creation/prefill
- one verified workflow example

9. Verification
Return:
- the DMX interaction pattern you found
- the HyperDoc insertion point you chose
- the exact route-laying gesture the user performs
- the anchor representation used
- the exact created/prefilled object shape
- the exact files changed
- compile/runtime validation performed
- the concrete demonstration path for the Pi workflow example
- any limits of this first slice

Also provide:
- a conventional commit message in plain text

Constraints:
- prefer existing HyperDoc annotation/patch-target machinery
- no fake placeholder UI
- no unrelated runbook redesign
- single rendering tree only
- keep the slice narrow and demonstrable
