# Separating subordinate execution from event propagation

Extension of the existing Nested Actions in Solo slice, 2026-10-07.

## Starting coordinates and preserved state

Observed repository/worktree: /Users/rgb/workspace/hyperdoc-dreyeck-ch, branch dreyeck.ch, HEAD 073c72f3fe39051ace057a9870a5f86629c89e94. The index contained only the pre-existing staged dreyeck/pages/work/Trails Rendered public reproduction.html patch. The checkout was otherwise clean. The root is a linked worktree of /Users/rgb/workspace/hyperdoc. No AGENTS.md was found in the checked checkout/ancestors.

The long-running scripts/hyperdoc-slynk.lisp SBCL (PID 76403 at reconnaissance) was observed separately and not reloaded. All source reconstruction and tests used fresh SBCL. No remote deployment, SSH, plugin-repository mutation, or source fetch was performed.

## What was located

The existing two text pages, three code pages, reading Workspace and acceptance suite were inspected in dreyeck/nested-actions, dreyeck/pages/nested-actions and dreyeck/tests/nested-actions-reading.lisp. The current ASDF, Catalog, structural writer, native Topicmap and TALA mechanisms were reused.

Local plugin observations:

- /Users/rgb/workspace/wiki-plugin-mech-upstream was clean at a028b4bba04e539dcaa090423d38a00a0050489d (2026-09-10 revision). Exact Git object source was read, rather than assuming the working copy matched an earlier observation.
- /Users/rgb/workspace/wiki-plugin-mech was at older 47cba6d57bef6db43e237abcbad60829d78b691c with untracked development artifacts.
- /Users/rgb/workspace/wiki-plugin-solo was at 17915844349bada64c901bd5ea73472702c446f9 with unrelated existing local changes. Its retained clickready code emits doInternalLink, not Ward's newly supplied publishSourceData fragment.
- Searches of retained plugin/client code, local Wiki assets and earlier saved served assets did not locate the newer nested LISTEN input transformation. This is a local search boundary, not a claim about all source elsewhere.

Retained Mech source coordinates are recorded in dreyeck/nested-actions/sources/provenance.json: LISTEN (blocks.js:878–915), REPORT (305–314), MESSAGE (917–928), run (224–241), and rendering emit (mech.js:18–42). The exact excerpts, SHA-256 hashes and original MIT notice are committed. Ward's supplied producer fragment has separate provenance, no invented revision, and SHA-256 920f15162bf07e719f7815855e47724add942ef9669d2ce8c8df17c3197c74c8.

## The two relations and the remaining gap

1. REPORT is subordinate to LISTEN because it is nested beneath LISTEN in the supplied action composition, and Ward reports that enclosing actions execute nested statements. The subordinate relation identifies execution structure.
2. LISTEN can hear an event from elsewhere because its event source is separate from that structure. Ward reports activation on rendering and intentional broadcast forward/backward across the lineup. Retained Mech source independently shows rendering calling run, block dispatch calling emit, and LISTEN registering on the window message channel. That retained handler filters by action and topic/name without a lineup-position filter.
3. title enters the event path in the supplied producer: message.title is props.title or props.name with newlines replaced by spaces, before window.opener.postMessage(message). The popup's opener is the receiving realm; LISTEN's window is the receiver's window, not the popup window.
4. The trace stops at the transition from the received node message to the current nested-action input. Retained LISTEN counts matching events and does not dispatch a nested body. Retained REPORT reads state[args[0] || 'temperature'], so REPORT title reads state.title in that revision. The newer implementation's input transformation, exact lookup target and continued use of that REPORT lookup are not established.

postMessage targets the opener. It is not silently equated with a proof of the whole FedWiki lineup's broadcast policy. That historical policy is author-reported, while the native-browser witness proves delivery in the bounded fixture.

Ward's proposed scope is event-emitter reach through supplying an alternative to window. No lexical/dynamic variable scope is inferred. No alternative emitter was implemented.

The earlier rebinding/context framing was explicitly corrected on both existing pages. The original Ralf quotation remains in EXPERIMENT-EVIDENCE with :INTERPRETATION-STATUS :HISTORICAL-HYPOTHESIS and an explicit correction field. It is not retained as an established account of how title reaches REPORT. The outer/inner-title probe is retained as superseded; the primary future probe now captures the current message reception, nested dispatch and REPORT input/lookup together.

## Reading and inspectable objects

Three text pages:

- Nested Actions in Solo — original observation and explicit correction; routes to both witnesses.
- Two Relations Hidden in One Nest — the two routes, source fragment, four answers, native message capture and emitter proposal.
- What Does a Nested Action Inherit? — revised input/lookup/lifetime questions and the exact source gap.

Four code pages: the original Inspecting the Observed Nested Action Tree, Proposed Nested Action Probes, Navigating the Nested Actions Investigation, and new Following One Node Message (message-path.lisp).

Native route: Catalog → Nested Actions in Solo → Two Relations Hidden in One Nest → exact producer Source evidence → recorded Message path → witness Topicmap point. Code pages link back to all three readings. The existing Catalog entry is reused; Catalog membership remains 20 books.

MESSAGE-SOURCE objects retain exact source text, pathname and provenance. EMITTED-MESSAGE-WITNESS reconstructs fresh structured objects from the recorded capture, not a live Solo evaluator. Its Message path view exposes producer props, emitted payload, channel/realm descriptor, native reception, listener observations, absent retained listener output, unknown current nested input and unknown current REPORT target.

The scoped-emitter object is :DESIGN-PROPOSAL, :MEANING :EVENT-EMITTER-REACH, :IMPLEMENTED-P NIL and :VARIABLE-SCOPE :NOT-ESTABLISHED.

## Native browser witness

The bounded message-witness.html fixture was authored with the existing html-inspector-views HTML DSL and reparsed with Plump. It executes Ward's exact supplied producer fragment and the exact retained LISTEN excerpt on native window message APIs.

An isolated Chrome test context sent two messages through a real popup/opener relationship:

| Producer input | Received title | Listener counts |
| --- | --- | --- |
| props.title = Payload Title | Payload Title | 1, 1 |
| props.title empty, props.name = Fallback + newline + Node | Fallback Node | 2, 2 |

Both native MessageEvents reported sourceIsPopup, distinctFromSenderObject and isTrusted true. These are observations of this fixture, not proof of human interaction or the historical FedWiki run. The emitted and received message objects agree on action=publishSourceData, topic=node and title.

The fixture's receivers are placed before and after its launch control; they are not the FedWiki lineup. Its synthetic props, DOM status instrumentation, pass-through listener-registration instrumentation and inert jQuery thumb-hook shim are disclosed. It has no nested-input assignment, REPORT invocation or alternative emitter. Listener output and current REPORT input remain null with explicit boundary statuses.

Recorded artifact: dreyeck/nested-actions/message-witness.json, SHA-256 df3803329a340bf1c75dc27657acdc1fd20ee2ea3bfc736407e8f0f1fd2b440e. The capture pins the fixture hash and source provenance too. An independent snapshot of each event's status history was retained. The manual replay artifact is committed at dreyeck/nested-actions/message-witness.html; serve the checkout on localhost and open it, then its producer popup.

The normal browser tool could not initialize because the configured /Users/rgb/.nix-profile writable root is a symlink. The existing installed Playwright/Chrome test runtime supplied the native capture. No existing browser session was controlled. The temporary localhost server was stopped after capture.

## Workspace semantics and warrants

The existing Workspace now has 25 Topics and 29 Associations. It preserves the original Topic IDs and adds popup-handler, message, node-topic, title-payload, window-emitter, broadcast, subordinate-execution, scoped-emitter, nested-input, report-target and witness.

Every Association has one of two :RELATION-KIND values:

- :SUBORDINATE-EXECUTION — containment, reported nested execution and the REPORT/input investigation.
- :EVENT-PROPAGATION — producer/payload/channel/listener path, broadcast reach, current transformation gaps and the scoped-emitter proposal.

These relations exist in the projection before TALA layout. Mechanism kinds, endpoints, warrants, original objects and native Point/history survive the layout comparison.

Warrants distinguish :SOURCE-OBSERVED, :AUTHOR-REPORTED, :OBSERVED (supplied structure or explicitly bounded recorded fixture), :DERIVED, :OPEN and :DESIGN-PROPOSAL. Source-observed retained LISTEN/REPORT relations also carry a revision-boundary property. Every scoped-emitter relation is a design proposal; none is observed. No generic “establishes execution context” or “LISTEN may rebind” edge remains.

## Exact test entry points and results

All completed with exit 0 after forcing current reading/test reconstruction:

```sh
nix develop --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/nested-actions/reading" :force t)' \
  --eval '(asdf:test-system "dreyeck/nested-actions/reading/tests" :force t)'

nix develop .#tala --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/nested-actions/reading" :force t)' \
  --eval '(asdf:load-system "dreyeck/nested-actions/reading/tests" :force t)' \
  --eval '(asdf:test-system "dreyeck/nested-actions/tala/tests")' \
  --eval '(asdf:test-system "dreyeck/topicmap/tests")' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/tests")' \
  --eval '(asdf:test-system "dreyeck/catalog/tests")'
```

Evidence: /private/tmp/nested-follow-reading-final.log and /private/tmp/nested-follow-tala-catalog-final.log. They contain the revised NESTED-ACTIONS-READING-PASS, NESTED-ACTIONS-TALA-PASS, generic Topicmap passes, D2 v0.9.0 / seed 44 integration and fresh Catalog startup pass. The normal Catalog child also ran the revised slice suite without an authoring runtime.

Extended tests prove the two independent relation kinds, topic=node/title payload, source/capture/fixture hashes, proposal-only scoped-emitter status, native reading/source/witness/Topicmap routes, explicit empty current handoff/lookup targets and preserved native Point/history. Browser capture was a separate executed witness; ordinary ASDF tests inspect its pinned observation and do not claim to rerun the browser.

## Executor discipline and replans

Operator: Codex. Exact reconnaissance and substantive executor invocations are retained in the companion nested-actions-event-propagation-executors.json; the chat tool transcript contains the individual read/diagnostic/poll operations. Full authoring scripts and stdout/stderr remain under /private/tmp/nested-follow-* and /private/tmp/nested-message-*.

- Reconnaissance expected current identity and source chain. It found the preserved index and only retained, older implementations. Resulting plan separated source-observed legacy behavior from author-reported new behavior.
- Source retention used Git SHOW at the measured revision, exact excerpt boundaries, hashes and MIT attribution. No plugin working copy was modified.
- HTML fixture authoring initially refused an incorrect four-button assertion; the authored fixture has three controls. The corrected write/reparse passed.
- Port 18094 was occupied, so the capture server used a distinct localhost port 18739; no existing service was changed.
- CUA browser initialization failed on the configured symlink writable root. The isolated installed browser-test runtime then produced real native reception; this was not an approval-review rejection.
- Structural authoring used the pinned html-inspector-views 38afb02d79838d4098589c2e203ba39799a44853 writer. All changed Lisp/ASDF forms were read back and compared with intended forms and unchanged surrounding forms. HTML pages used its DSL and title/h1/package/link reparse checks.
- The first source/page authoring run completed those writes, then refused a temporary proposal's wrong DEFUN-body selector when inserting test checks. The selector was corrected, and only test operations resumed; verified page/model writes were not repeated.
- Initial ordinary/TALA tests loaded a same-second earlier test FASL. Persisted source had the correct revised assertion. Canonical structural serialization and explicit ASDF force-load/test removed that ambiguity; the current-source suites passed.
- Selective Git commit uses DREYECK/GIT:GIT-RUN-STRING with exact slice paths and COMMIT --only, since COMMIT-REPOSITORY-SLICE's empty-index precondition does not apply to this checkout. The original staged patch is compared byte for byte before and after committing. Commit identity and actual final dirty state are reported in the final response.

Source bytes, generated HTML, recorded browser data, fresh reconstructed images and the separate long-running image remain distinct evidence. The stopping condition is met with an explicit gap, not a guessed current input transformation.


Commit entry point: /private/tmp/nested-follow-commit.lisp; complete returned evidence: /private/tmp/nested-follow-commit.log. The server was verified as task-owned PID 26681 and stopped with SIGTERM; its executor session exited 143. No source or layout change followed the passing current-source suites; only reports were completed before the selective commit.
