# Federated-context interaction semantics

The context Topicmap follows represented wiki material. Temporal signs select
their represented events. Inspection links independently expose either the
represented object or the Topicmap sign. **Set Workspace Point** independently
moves Point to that sign through the existing `topicmap-workspace-go-to` operation.

Existing machinery:

| Operation | Existing implementation used |
| --- | --- |
| Follow/open working material | `html-inspector-views:eval-id`, `eval-thunk`, and the Inspector's `eval` handler (`create-pane`); direct native pages retain their Story/Links views. |
| Collaborative resolution | `hyperbook/fedwiki::make-wiki-link` → link thunk → `find-target-by-slug` → `lookup-slug-in-page-context`; this preserves local/plugin/context precedence per source. |
| Open a concrete remote page | `hyperbook:find-hyperbook`, `hyperbook:find-page`, `load-page`; remote references retain `origin-of` and `origin-id-of`. |
| Persist/materialize | `dreyeck/fedwiki-page-materialization:materialize-fedwiki-page-json`. |
| Genuine local fork | `materialize-fedwiki-page-fork`, which appends a fork journal entry and persists page JSON in the local site's page store. |
| Workspace movement | The inspection table's `Set Workspace Point` action calls `select-context-topic` → `topicmap-workspace-go-to`; this remains separate from primary context following. |

`make-remote` creates an in-memory remote reference. It is not a persistent
fork. Following a sign opens wiki working material using the existing Inspector
transport; this slice does not automatically fork it. Genuine materialization
remains an explicit operation.

Previously, a context sign invoked `select-context-topic`, moved Workspace Point,
and returned true. The Inspector's `action` handler consequently called
`refresh`. That destroys and recreates the pane's children, including the outer
`.inspector-body` scroll container. The existing `context-map-scroll-offsets`
hook repositions the inner Temporal/Context maps after rebuilding, but cannot
restore that destroyed outer viewport. This explains the jump toward Temporal.

Now the renderer supplies the correct primary reference when it creates each
TALA sign, avoiding orphaned sign-inspection references with replaced DOM IDs.
A temporal reference is an `action` over the represented event. A context
reference is an `eval` over the represented object. Context following changes
neither the temporal cursor nor Workspace Point and does not refresh the source
pane. The existing Lisp Inspector state and transport preserve its viewport.
Historical page following opens the exact represented page, with Story selected
by default; its Source / Time evidence remains available.

A subject follow evaluates its existing historical collaborative links. For an
unresolved link, it invokes the native live collaborative resolver from that
link's source page. It collects recorded and cached neighborhood candidates,
deduplicating remote references by their concrete origin site and slug. One
complete candidate follows directly. Zero candidates, multiple candidates, or
operational lookup failures open the existing Subject view with explicit
site-qualified choices and failure references. An incomplete lookup never
silently selects the sole candidate found elsewhere.

The explicit inspection table provides `Inspect represented object`,
`Inspect Topicmap sign`, and `Set Workspace Point` for every context sign. The
Workspace Point summary presents only its label and relations, without duplicate
follow/inspection links. The old summary already passed the object
to its represented-object link; the new tests verify the actual DOM reference
and browser pane target, rather than inferring correctness from the label.

Verification on 2026-10-05:

| Case | Evidence |
| --- | --- |
| Temporal event | Browser click changed cursor 10 → 8, changed State, and produced four Delta relation changes. Wiki pane count and its exact page object stayed unchanged; one source refresh occurred. |
| Jan / John Dewey follow | Browser opened the `EQ` represented `CONTEXT-FEDWIKI-PAGE`, with site `fedwiki:jan.voices.ustawi.wiki`, slug `john-dewey`, and active view Story. Cursor remained 10. |
| Reflective Practice, unique | Offline native resolver fixture followed `fedwiki:thompson.voices.ustawi.wiki/reflective-practice` only when it was the complete single candidate. The browser opened the `EQ` native page; cursor remained 10. |
| Reflective Practice, ambiguous | Fixture supplied Jan and Thompson as distinct genuine native page candidates. The Subject chooser exposed both; an explicit browser selection opened Jan's exact page. No automatic tie-breaker was used. |
| Incomplete resolution | Regression control supplied an operational source lookup failure with one discovered page; the result remained the Subject chooser with failure evidence. |
| Inspect Reflective Practice | The exact inspection DOM ID and browser pane target were `EQ` to the represented `FEDERATED-SUBJECT`, not `TOPICMAP-TOPIC`. |
| Inspect Jan / John Dewey | The exact inspection DOM ID and browser pane target were `EQ` to the represented historical native page. |
| Explicit Workspace Point | With A = Jan / John Dewey and B = Thompson / How We Think, Follow B opened B's exact historical page while Point stayed A. `Set Workspace Point` then changed Point to B and its visible summary/highlight, without changing time, the wiki pane count, the opened page, or follow count. Source refresh count was zero; repeating Point B did not redraw. |
| Inspect/temporal independence after Point movement | Browser inspection opened B's exact page with Point B and cursor 10 unchanged. A subsequent temporal click changed cursor 10 → 8 and produced four Delta relation changes; Point B, wiki pane count, and opened wiki object stayed unchanged, with no further follow. |
| Scroll | Before and after context follows, chooser selection, explicit inspection, and explicit Point movement: outer `scrollTop=708`; context `scrollLeft=123`, `scrollTop=234`; temporal offsets `(0, 2496.5)`; same context DOM element. Source refresh count remained zero. The Point update also retained its own container and the existing inspection table. |
| Projection effects | Rebuild/render State and Delta at all 11 events left empty catalog/neighborhood registries empty and raw evidence unchanged. Browser witness trapped both genuine materialization functions; call count stayed zero through rendering, following, inspection, and temporal selection. |

Browser evidence used synthetic clicks through the real CLOG Inspector handlers
in an isolated localhost image, and Lisp assertions on the actual pane objects
and DOM scroll offsets. Candidate fixtures replace only the HTTP boundary; the
production collaborative/context resolver is exercised. These fixture results
do not assert which page a different live neighborhood will resolve today.

The explicit Point action is an ordinary Inspector action using the existing
Topicmap action-reference class. Its NIL result suppresses source-pane refresh.
A presentation callback updates only the Point summary's HTML/relation references
and the existing SVG selection attributes. It retains the outer view's scroll
offset, including when a changed relation paragraph would trigger scroll
anchoring. It neither opens a wiki pane nor moves the temporal cursor. Repeating
the current Point does not redraw its presentation. There is no new Workspace
state or interaction protocol.

The A/B regression uses A = Jan / John Dewey and B = Thompson / How We Think.
Following B opens its exact represented page while Point remains A. Explicitly
setting Point B performs no follow and returns NIL; inspecting B preserves Point
and time. A temporal click changes the cursor while retaining Point B when that
topic remains present in the resulting context projection. The per-sign
`projection-kind` selection branch was removed by computing the selected ID once;
the branches needed for temporal versus context projection/actions remain.

Run the automated suites in the pinned TALA environment:

```sh
nix develop .#tala --command sbcl --noinform --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/fedwiki-page-materialization/tests")' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/tests")'
```

For manual browser verification, open the `federated-context` example's Topicmap,
click Jan / John Dewey and Reflective Practice, and expand **Inspect context
signs and represented objects** for the separate inspection links and the explicit
**Set Workspace Point** button. A subject's
concrete candidate set depends on the existing live source contexts and cached
neighborhood. Temporal Previous/Next and event-sign clicks retain their existing
State/Delta semantics.
