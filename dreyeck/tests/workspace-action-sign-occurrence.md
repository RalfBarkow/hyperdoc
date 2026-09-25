# Gestures on a Workspace action sign occurrence

`WORKSPACE-ACTION-SIGN-OCCURRENCE` describes one concrete occurrence of the
existing transparent workspace action rectangle, not the whole Topic sign.
`%RENDER-NATIVE-TOPICMAP-WORKSPACE-ACTION-SIGN` still supplies that rectangle.
The Inspector's `CREATE-VIEW-ELEMENT :AFTER` method attaches the contextual
adapter to its action ID after the ordinary Inspector click handler is installed.
There is no new geometry or layout change.

The action reference is still an Inspector thunk. It also retains the Topic,
Projection and Workspace. The occurrence retains that reference, its CLOG
element, Pane, View, transient element token and Gesture Window. Topic ID is
read from the Topic; the inspectable ASDF object is a separate object reached
through the Topic. A Gesture target contains the exact occurrence object.
Neither Topic ID nor the element token replaces it.
`TOPICMAP-PROJECTION-OF` constructs a fresh projection each time; the occurrence
retains the one used for rendering, not a later reconstruction. Its projection
source is the Workspace, and its Topic is the exact member of that projection.

PRIMARY returns before capture, sequencing, timer or Gesture forwarding. The
existing click invokes `TOPICMAP-WORKSPACE-GO-TO`, then the Inspector refreshes.
SECONDARY uses the existing transport/reducer through a per-occurrence Gesture
Window. Production bindings are NIL: no Topic Operation is offered or executed.
The test system alone supplies inert radial/mark bindings. This slice exposes
reducer state and selection; it does not draw a new radial-menu widget.

Refresh invalidates the old occurrences before replacing the Pane's content.
Currentness also checks the live connection, DOM attachment and element token;
once false it stays false. Detached elements dispose their browser listeners,
capture and reveal timer. Queued input for an ended occurrence is refused.
The registry is weak and is an inspection aid, not persistent storage.

## Evidence obtained

The live witness uses `READING-SOURCE-WORKSPACE` with the production Inspector
stylesheet and unchanged default positions. `elementFromPoint` freshly found
`asdf-system:dreyeck/topicmap/tala/reading/tests` as the reachable action sign;
it covers the preferred `asdf-system:dreyeck/topicmap/tala` sign. The harness
checks the hit rectangle, action class, token and View action reference, together
with the exact Workspace and Projection. It fails if this layout observation
changes, rather than silently gesturing at another sign.

The direct Lisp/CLOG/browser run established:

- Synthetic PRIMARY held beyond the reveal deadline causes no Gesture input,
  log or capture attempt. A separately dispatched click performs the existing
  navigation, preserving the old Point in History.
- Refresh ends A and creates B. A and B are distinct occurrences, with no
  requirement that their Topics differ or remain EQ.
- On B, synthetic SECONDARY press/wait/move/release and immediate movement
  select the respective inert radial/mark binding with B as the exact target.
  Point and History do not change. CLOG observes the resulting DOM state.
- DOM removal outside refresh ends B. A fresh occurrence after another refresh
  also ceases to be current when its browser connection is closed.

All dispatched pointer events above have `isTrusted=false`. The generated
reveal deadline is also recorded as untrusted. A true flag for a pointer event
would mean browser input pipeline provenance, not proof of a human operator.
Synthetic pointer dispatch does not test native capture or manufacture a native
click; the physical witness below covers that remaining acceptance layer.

## Replay automated gates

Run from the checkout. Tests use the pinned repository environments.

```sh
nix develop --offline --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(dolist (s (list "dreyeck/topicmap/gesture/tests" "dreyeck/topicmap/tests" "dreyeck/gesture/operation-request/tests" "dreyeck/gesture/clog/tests" "dreyeck/gesture/transport/tests" "dreyeck/gesture-binding-witness/tests" "dreyeck/gesture/reading/tests")) (asdf:test-system s))' \
  --eval '(assert (null (find-package "DREYECK/WORKFLOW/AUTHORING")))'
nix develop --offline --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' --eval '(asdf:test-system "dreyeck/catalog/tests")' \
  --eval '(assert (null (find-package "DREYECK/WORKFLOW/AUTHORING")))'
nix develop .#tala --offline --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' --eval '(asdf:test-system "dreyeck/topicmap/tala/reading/tests")'
nix develop --offline --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' --eval '(asdf:load-system "dreyeck/topicmap/gesture/tests")' \
  --eval '(unwind-protect (dreyeck/topicmap/gesture/tests::run-live-workspace-action-sign-test) (clog:shutdown))'
```

The last command opens the ordinary local browser. It owns its Lisp objects,
queries DOM directly with CLOG, and waits on Lisp callbacks/semaphores. It needs
no Playwright, CDP driver, JSON file or separate result-polling process.

The assertions supply these falsifiers (not a claim of mutation testing):

| Fault | Assertion that rejects it |
| --- | --- |
| A: identity reduced to Topic ID | Two occurrences share a Topic ID but have distinct tokens/windows; exact EQ target checked in pure and live tests. |
| B: PRIMARY enters Gesture | Pure adapter rejects primary down; live hold checks zero inputs/log/capture, then tests navigation separately. |
| C: old occurrence stays current | Live refresh requires A false, B true and A not EQ B; ended occurrence rejects input. |
| D: Topic equals inspectable object | Actual Topic type and exact ASDF object are checked separately. |
| E: adapter attached to painted sibling | Live elementFromPoint must equal the occurrence's action rect, whose ID resolves to the exact action reference in its View. |

Pure tests also check empty production bindings, radial/mark selection, trust
recording and both statuses in the human-readable occurrence overview.

## Manual physical witness: pending

No human physical-input run was performed during the automated evidence run.
Use an isolated mREPL from `nix develop`; the helper creates an ordinary
Inspector on the real Workspace. The explicit test option enables only inert
bindings on this test Pane, including after refresh. Omit it for production
behavior. It never changes the production binding variable globally.

```lisp
(asdf:load-system "dreyeck/topicmap/gesture/tests")
(defparameter *physical-a*
  (dreyeck/topicmap/gesture/tests::start-workspace-action-sign-witness
   :test-bindings t))
(defparameter *physical-old-point*
  (dreyeck/topicmap:topicmap-workspace-point-of
   (dreyeck/inspector/topicmap:occurrence-workspace *physical-a*)))
```

Physically click the visible `dreyeck/topicmap/tala/reading/tests` sign with
PRIMARY. Then evaluate:

```lisp
(defparameter *physical-b*
  (dreyeck/topicmap/gesture/tests::%current-occurrence))
(assert (not (eq *physical-a* *physical-b*)))
(assert (not (dreyeck/inspector/topicmap:workspace-action-sign-occurrence-current-p
              *physical-a*)))
(assert (null (dreyeck/inspector/topicmap:occurrence-inputs *physical-a*)))
(assert (null (dreyeck/gesture/clog:gesture-window-log
               (dreyeck/inspector/topicmap:occurrence-gesture-window *physical-a*))))
(defparameter *physical-workspace*
  (dreyeck/inspector/topicmap:occurrence-workspace *physical-b*))
(assert (equal "asdf-system:dreyeck/topicmap/tala/reading/tests"
               (dreyeck/topicmap:topicmap-workspace-point-of *physical-workspace*)))
(assert (equal *physical-old-point*
               (first (dreyeck/topicmap:topicmap-workspace-history-of *physical-workspace*))))
(defparameter *physical-evidence*
  (list (list :primary :navigation-passed :old *physical-a* :new *physical-b*)))
```

On the same sign, physically hold SECONDARY for more than 500 ms, move at least
70 browser pixels right, then release. There is no new visible radial widget;
inspect the reducer result in Lisp. Then evaluate:

```lisp
(assert (equal "test-only/radial-menu"
               (dreyeck/topicmap/gesture/tests::%selected *physical-b*)))
(assert (eq *physical-b*
            (nth-value 1 (dreyeck/topicmap/gesture/tests::%selected *physical-b*))))
(push (list :secondary-wait
            :result (dreyeck/topicmap/gesture/tests::%result *physical-b*)
            :inputs (copy-list (dreyeck/inspector/topicmap:occurrence-inputs *physical-b*)))
      *physical-evidence*)
```

Physically press SECONDARY again, immediately move right, and release before
500 ms. Then record the second result and open the real occurrence overview:

```lisp
(assert (equal "test-only/learned-mark"
               (dreyeck/topicmap/gesture/tests::%selected *physical-b*)))
(assert (eq *physical-b*
            (nth-value 1 (dreyeck/topicmap/gesture/tests::%selected *physical-b*))))
(assert (eq *physical-b* (dreyeck/topicmap/gesture/tests::%current-occurrence)))
(assert (= 1 (length (dreyeck/topicmap:topicmap-workspace-history-of *physical-workspace*))))
(push (list :secondary-immediate
            :result (dreyeck/topicmap/gesture/tests::%result *physical-b*)
            :inputs (copy-list (dreyeck/inspector/topicmap:occurrence-inputs *physical-b*)))
      *physical-evidence*)
(clog-moldable-inspector:clog-inspect :object *physical-b*)
```

Record the operator/date and `*physical-evidence*` when this procedure is
actually performed. Pointer entries should report the browser's trust flag;
the reveal deadline remains generated. The overview shows currentness, Topic
ID, Topic, Projection, Workspace, Inspectable object, Element, Pane, View and
Gesture Window. Disconnect/currentness is exercised by the automated witness.

## Addressing and durability boundary

The commonality with SOURCE-OCCURRENCE is retaining a concrete observation and
its context instead of replacing it with semantic identity. Source uses page,
snapshot, form key and character range. This case uses the exact action element
and its Topic/Projection/Workspace/View/Pane context while current. It promises
no restart-stable occurrence identity and introduces no universal Subject.

In historical Connect vocabulary, provider/strategy/value/durability remain
comparison questions: which context produced the sign, how it is reached,
what it denotes, and how long that address is valid. No old Connect classes or
JavaScript are ported. Topic ID alone cannot address this occurrence.

Element, token, Pane, View, Gesture Window, input log, queues, capture and timers
are transient. A Topic ID plus a reconstruction context, Workspace Point/history
or projection settings might be persistence candidates in a later design;
the current Topic and ASDF object references are runtime objects, not stored
addresses. This slice adds no persistence schema, source execution, Change
Request, SHOP3 or authorisation behavior.
