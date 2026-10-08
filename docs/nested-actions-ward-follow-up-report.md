# Ward follow-up: subordination and event reach

This is the completed subordination/event-reach slice. The subsequent received-message input-boundary slice is reported in [nested-actions-input-boundary-report.md](nested-actions-input-boundary-report.md).

This report records the follow-up revision starting from committed HEAD 5446360490e8949e476e84ad21c4173abced3442, not the original Nested Actions slice.

## Starting state and scope

The current HEAD and index were checked before editing. Checkout: /Users/rgb/workspace/hyperdoc-dreyeck-ch, branch dreyeck.ch. The sole pre-existing dirty item was the staged dreyeck/pages/work/Trails Rendered public reproduction.html patch. The earlier broad reconnaissance was not repeated: the committed reading, source excerpts, witness, tests and established structural writer were used directly.

The long-running Lisp image was not reloaded. There was no SSH, deployment, new event framework, alternative event emitter or new browser run. Source and fixture hashes in the existing recorded native-message witness remain unchanged.

## Changes made for this request

The reading now states explicitly: **Subordination and event reach are independent dimensions.** It explains that nesting identifies subordinate statements and cannot describe where LISTEN receives events from. Ward's three exact supplied quotations appear in “Two Relations Hidden in One Nest” and as structured evidence with :AUTHOR-REPORTED, :AUTHOR-REPORTED and :DESIGN-PROPOSAL statuses.

The enclosing-context, inherited-context and event-context Topics are preserved as historical hypotheses, with their earlier claims, Ralf's original quotation and Ward's new evidence/refinement attached. They are no longer relabelled as current input questions. HISTORICAL-CONTEXT-HYPOTHESES constructs these inspectable records. The earlier “SOLO establishes an execution context” interpretation is challenged as a complete account of event reception; the unresolved current handoff has separate nested-input and report-target Topics.

The requested canonical Topic IDs now exist:

solo-popup-click, publish-source-data-message, node-topic, title-payload, window-event-emitter, broadcast-event-reach, subordinate-execution, scoped-event-emitter-proposal.

Previous follow-up point links remain usable through aliases in TOPIC-WORKSPACE. Native Topicmap navigation itself still uses the existing production GO-TO operation.

The Workspace contains 25 Topics and 31 warranted Associations. Every relation has an independent mechanism kind: :SUBORDINATE-EXECUTION or :EVENT-PROPAGATION. The following directed relations are explicitly tested:

| From → to | Relation | Warrant |
| --- | --- | --- |
| solo-popup-click → publish-source-data-message | constructs | source-observed |
| publish-source-data-message → node-topic | carries | source-observed |
| publish-source-data-message → title-payload | carries | source-observed |
| solo-popup-click → window-event-emitter | posts-via window.opener.postMessage | source-observed |
| window-event-emitter → LISTEN | provides broadcast reach | author-reported |
| SOLO → LISTEN | contains / subordinates | already observed supplied composition |
| LISTEN → scoped-event-emitter-proposal | could-use alternative to window | design proposal |

The retained source registration relation and author-reported broadcast-reach relation remain separate, even though both concern window and LISTEN. No SOLO → LISTEN event-scoping relation exists. Every relation involving the scoped emitter remains a design proposal; no lexical/dynamic variable-scope claim or emitter implementation was added.

## Concrete source/data path and exact boundary

The committed supplied fragment establishes:

```javascript
const message = {
  action: 'publishSourceData',
  topic: 'node',
  title: props.title || props.name.replaceAll(/\n/g,' ')
}
window.opener.postMessage(message)
```

The retained source evidence is still revision-specific. Mech a028b4bba04e539dcaa090423d38a00a0050489d LISTEN registers window.addEventListener('message', listen) and accepts publishSourceData when data.topic or data.name matches node. Its handler counts events; it contains no nested-body/input dispatch. Retained REPORT reads state[args[0] || 'temperature'], hence state.title for REPORT title in that revision.

The recorded native browser witness establishes supplied producer fragment → emitted message → actual popup/opener channel → reception by the retained listener. It retains structured producer props, emitted and received messages, emitter/channel, listener observations, missing retained listener output, and explicit null/unknown current nested input and REPORT target. Both title and newline-normalized name branches remain in the pinned capture.

**The exact unverified transition is received node message → Ward's current nested-action input, including the current REPORT lookup target.** The newer LISTEN dispatch and current REPORT implementation are not established by the retained revision. The old generic context-inheritance question is not substituted for this boundary.

The captured witness is bounded: synthetic props, exact supplied producer, retained LISTEN, real native window/opener delivery. It does not establish the entire FedWiki lineup policy or execute the newer nested implementation. That limitation remains visible in the Inspector.

## Four separate reading answers

1. REPORT is subordinate to LISTEN because it is nested below it in the supplied composition, and Ward reports enclosing/subordinate execution.
2. LISTEN can hear an event originating elsewhere because event reach is an independent window/broadcast route. Ward reports activation on rendering and intentional forward/backward lineup broadcast; retained source demonstrates registration/filtering on window separately from nesting.
3. title enters as message.title in the supplied producer, from props.title or normalized props.name, before postMessage.
4. Received message → current nested input / REPORT lookup target remains unverified. The retained listener/count and retained state.title lookup are explicitly distinguished from the current implementation.

“Scope” in Ward's proposal means event-emitter reach through replacing window. Variable-scope semantics remain unestablished.

## Native reading/code/witness routes

Catalog entry: Nested Actions in Solo (unchanged; 20 Catalog books).

Reading pages: Nested Actions in Solo; Two Relations Hidden in One Nest; What Does a Nested Action Inherit?. All three now expose the independent-dimensions statement and links to the historical hypotheses.

Code pages: Inspecting the Observed Nested Action Tree; Following One Node Message; Proposed Nested Action Probes; Navigating the Nested Actions Investigation.

The acceptance test traverses actual Content references from Two Relations Hidden in One Nest → producer Source evidence → recorded Message path → Topicmap Workspace. It validates the canonical producer point and explicit gap object. Code → reading links and native/TALA Point/history checks also remain covered.

## Tests executed and observed results

All commands below completed with exit 0.

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
  --eval '(asdf:test-system "dreyeck/topicmap/tala/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/catalog/tests")'
```

Evidence: /private/tmp/nested-ward-reading-final.log and /private/tmp/nested-ward-regressions-final.log.

Observed results include WARD-FOLLOW-UP-CONTRACT-PASS; updated NESTED-ACTIONS-READING-PASS (25 Topics/31 Associations); NESTED-ACTIONS-TALA-PASS; generic Topicmap and D2 v0.9.0 / seed 44 integration; all TALA reading/source-widget/checkout/reference checks; and fresh Catalog startup. The Catalog child also executes the updated follow-up contract without loading an authoring runtime.

New tests check exact quotations/statuses, all canonical Topics, required directed/warranted relations, preservation of historical objects, old point aliases, prohibition of SOLO event scoping, proposal-only scoped emitter, and traversal of actual reader-facing references to the witness and Topicmap. Existing source, fixture and capture hashes remain verified.

## Executor report and assimilated replans

Operator throughout: Codex. The accompanying nested-actions-ward-follow-up-executors.json retains exact substantive entry points with expected/observed effects, evidence, assimilation and replan. Individual read/diagnostic/poll operations are in the chat tool transcript; complete scripts/stdout/stderr are under /private/tmp/nested-ward-*.

| Executor / exact entry | Expected effect | Observed effect and assimilation | Resulting replan |
| --- | --- | --- | --- |
| Git rev-parse HEAD; status --short; diff --cached --name-status | Establish the committed base and index | HEAD 54463604 and only the staged Trails Rendered patch | Continue from committed source; preserve index |
| Targeted reads of committed slice/excerpts/tests and previous writer helper | Match the exact follow-up requirements | Canonical names/direct edge direction and historical-object presentation required refinement; retained LISTEN/input boundary still explicit | Change those concrete gaps; no broad rediscovery |
| Pinned authoring SBCL --load /private/tmp/nested-ward-revision-author.lisp | Structurally write/reparse requested changes | Package export verified; temporary quotation proposal failed to read | Fix literal quotation construction; resume only unapplied operations |
| Same environment --load /private/tmp/nested-ward-revision-resume.lisp | Finish source/model/page writes | Ward quotations, history objects, model, aliases and all three HTML DSL pages reparsed; new temporary test form had one unclosed form | Preserve verified writes; fix and resume test insertion only |
| Same environment --load /private/tmp/nested-ward-tests-resume.lisp | Finish tests and canonical serialization | WARD-REVISION-STRUCTURAL-AUTHORING-PASS; intended/surrounding Lisp forms and HTML metadata verified | Force fresh current-source test reconstruction |
| ASDF TEST-OP commands above | Verify task contract and regressions | Both processes exited 0; all named passes observed | Complete report and selective commit |
| DREYECK/GIT:GIT-RUN-STRING via /private/tmp/nested-ward-commit.lisp | Commit exact slice paths and preserve unrelated staged patch | Returned commit/status and byte-identical staged-patch assertion recorded in /private/tmp/nested-ward-commit.log | Return measured commit identity and final state |

Structural writing uses the existing pinned html-inspector-views writer at 38afb02d79838d4098589c2e203ba39799a44853. Changed Lisp forms are written, reparsed and compared with intended and unchanged surrounding forms; final canonical serialization preserves those forms. Pages are written through its established HTML DSL and reparsed for title, h1, package and native links. No additional page-generation mechanism was introduced.

The configured symlink writable root prevents normal sandbox startup; reviewed shell execution was used without changing the permission configuration. No automatic approval-review rejection occurred.

The selective commit uses COMMIT --only through the existing Git primitive because the high-level COMMIT-REPOSITORY-SLICE requires an empty index. Its exact path list is retained in the commit script. The final response supplies the new commit hash and measured post-commit status; the staged Trails Rendered diff is asserted byte-identical before and after.

The first commit attempt staged only the intended files, then stopped at the staged-patch whitespace check because this new report had an extra blank line at EOF. The report whitespace was corrected; source/tests were unchanged. The refused attempt is retained in /private/tmp/nested-ward-commit-attempt1.log.
