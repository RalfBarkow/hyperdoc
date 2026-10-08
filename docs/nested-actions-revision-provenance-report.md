# Git revision provenance and historical Solo additions

This slice starts from `fab214334279bc5d3df0f2f624d34e6a1bdc1897` in `/Users/rgb/workspace/hyperdoc-dreyeck-ch`, branch `dreyeck.ch`. The sole pre-existing change was the staged Trails Rendered page. Its exact staged diff was saved at `/private/tmp/nested-git-provenance-trails-before.patch` before any writes. The worktree's Git directory is `/Users/rgb/workspace/hyperdoc/.git/worktrees/hyperdoc-upstream-intake-cut`, common directory `/Users/rgb/workspace/hyperdoc/.git`.

The two questions have separate answers. “Mech a028b4b” now denotes an explicit repository/full-OID reference, with native revision → file → definition navigation. Local historical Solo source establishes a message receiver that appends incoming graphs to an already-rendered popup beam. It also establishes a later replacement convention and separate Speed Bot async-fetch/result processing. Continuity between those paths and the current LISTEN → nested-input/REPORT transition remains unverified.

## Exact identity and existing mechanisms reused

The witness source identity is:

- Repository authority: `https://github.com/WardCunningham/wiki-plugin-mech`.
- Full OID: `a028b4bba04e539dcaa090423d38a00a0050489d`.
- Display: `a028b4b`, presentation only.
- Local checkout: `/Users/rgb/workspace/wiki-plugin-mech-upstream/`.
- Confirmed authority source: that checkout's `origin`, `https://github.com/WardCunningham/wiki-plugin-mech.git`, with the commit present and contained by the recorded origin/main ref.
- Role: locally retained source used for the recorded native message/input witness, not an identified current nested implementation.

The original source excerpts remain in the reading's sources directory, with their original hashes. The local checkout holds the full Git objects; the excerpts allow the witness to be inspected against fixed bytes without following a moving branch. The reading states both meanings of retention and why those bytes were kept. Its displayed a028b4b is now a native expression link, not inert text.

Reconnaissance found existing `git-repository-checkout`, `git-commit`, `git-file-at-commit`, Git blob readers, commit/file Inspector views, source-slice objects, historical ASDF readers, and the existing source-fragment evidence model. Historical ASDF and CST/source-range readers concern different syntax; none is used to interpret JavaScript or arbitrary hexadecimal text. The current `message-source` already represented exact hash-verified excerpts and was extended rather than replaced with a second fragment representation.

The reusable addition in `dreyeck/git` is `git-revision-reference`, a subclass of the existing commit object, with explicit authority, abbreviated display id, provenance role, external commit URL and associated files. Its identity function returns authority + full OID. Construction rejects short IDs, HEAD and missing authorities; abbreviated presentation does not participate in identity. `git-evidence-file` extends the existing file-at-commit object with Inspector evidence locations. Existing commit metadata, patch, file and blob readers remain available. No new parser, git: reader, regex SHA autolinker, repository fetch or source evaluator was introduced. HyperDoc uses its existing authored EXPR links and JSON reader.

Default Inspector labels include authority and display id; the Evidence revision view exposes the full OID and live local availability separately. Recorded identity and excerpt evidence remain representable when the optional external checkout is absent. The full live blob reader requires that local Git object; it does not silently fetch or substitute a snapshot for a missing full file.

## Reader-facing path and warrants

`From Message to Nested Input` links the claim to `MECH-EVIDENCE-REVISION`. The Evidence revision view links to `src/client/blocks.js` and `src/client/mech.js` as file-at-commit objects. The Evidence locations view of blocks.js reaches LISTEN and REPORT `message-source` objects, which display named definitions, exact source ranges, verified text, the retained excerpt path, and references back to the revision and file.

The retained LISTEN definition is blocks.js lines 878–915; its event callback is 897–914, data extraction at 899 and action/topic predicate at 900. REPORT is 305–314, with the key at 306, membership test at 307 and state[key] lookup at 308. The source-excerpt content is checked against the actual full Git blob in acceptance, as well as against its retained-file hash.

The Topicmap's source-observed Mech and supplied-producer warrants now keep actual source evidence objects in SOURCE. Historical source warrants do the same. SOURCE-KEY remains a stable descriptive role for test/query use; it is not the revision identity. Each revision boundary keeps the actual revision object and states that the current implementation is not established. Current input-trace stages also point to the source objects instead of textual revision lists. The supplied producer still has no invented Git identity because Ward provided no revision for that fragment.

The same book now has five text/seven code pages and 39 Topics/52 Associations. The three established mechanism concerns remain distinct: subordinate execution, event propagation, and payload-to-input. Added provenance-navigation and historical-popup-update relation kinds do not collapse them into generic context. The earlier context hypotheses remain historical objects, and the scoped emitter remains only a design proposal.

New text page: **Adding to an Already Rendered Solo Popup**. New code pages: **Git Revisions Behind the Source** and **Tracing Historical Popup Additions**. All code pages link to the readings; the existing readings link into the new source/history paths.

## Historical source established locally

Every revision below is constructed as a first-class Git reference in `revision-provenance.json` and exposed through the historical Inspector. The authority was confirmed through a local remote and ref containment, not inferred from the author name or a bare SHA.

| Authority / local checkout | Full OID | Evidence role |
| --- | --- | --- |
| WardCunningham/wiki-plugin-solo, `/Users/rgb/workspace/wiki-plugin-solo/`, upstream/main | `19ebc93886703c8d9b23ce66882d8c893ddd7928` | March 2024 append receiver and reliable-message sender convention |
| same authority/checkout | `4a940c7021c38c3d63f3b4729f6e1fb0770071a1` | April 2024 replacement batch convention |
| WardCunningham/assets, `/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/`, ward/master | `5dc2f4e8ab130e4d74de2d27eb36eb869dae7c4b` | February 2022 earlier getfrom source |
| same authority/checkout | `ddd2b29a5e7304d422a19e9a2781f7d32c0d0937` | March 2022 Speed Bot runner and matching telling.js |

Eight exact excerpts, original repository path, full revision, definition name, source range, whole-blob OID and excerpt SHA-256 are retained in `historical-provenance.json`. The local Wiki's Speed Bot, Speed Bot Journey, Markov Monkey and Super Monkey stories also supplied artifact pointers and author-reported context; later unrelated journal prose was not treated as implementation evidence. Uncommitted changes in the external Solo/assets checkouts were observed and left untouched; source observations use committed blobs.

**Early Solo append mechanism.** In 19ebc93, client/solo.js dopopup (60–76) rotates a batch through todo, constructs `{type:'batch', graphs}`, opens/reuses the named solo popup, and posts after load or directly to an existing dialog. The dialog's message callback (53–60) assigns a date to each received graph, performs `beam.push(...data.graphs)`, and calls refreshBeam. That function (62–102) rebuilds beamlist.innerHTML from the accumulated beam. The persistent receiver and retained beam array allow another delivered batch to extend an already-rendered popup.

**The sender's async boundary.** In the same revision, link/emit (42–58) fetch and parse JSONL, but emit awaits `Promise.all(parsed.graphs)` before adding the popup button. The demonstrated sender is a button path after this barrier. This is not a per-fetch completion callback injecting results into the popup. Ward's “spontaneous additions” clue is preserved as author-reported; the source establishes message-driven extension but not the spontaneous fetch trigger he remembers.

**Later Solo replacement.** In 4a940c7, the dialog callback (40–50) changes to sources/aspects and calls `beam.splice(0)` before appending the new aspects. It clears the old beam on each batch. The old append behavior is therefore revision-specific and is not attributed to every Solo version.

**Speed Bot fetch optimization and results.** At ddd2b29, telling.js fastfetch/getfrom (23–51) concurrently fills missing cached sitemaps with Promise.all, selects a candidate site from the requested sites using sitemap membership, fetches that page, then derives the next sites from references and the page journal. Site selection precedes inspection of that fetched page's journal. fastfetch has an abort timeout. This source supports an approximate resolution/concurrent sitemap path; it does not establish a benchmark or every detail of Ward's recalled optimization. Earlier 5dc2f4e used a global cache-key candidate search; the later matching runner revision uses the supplied sites ordering.

Speed Bot's dostart (49–101) awaits getfrom for each hop, pushes the resulting place into all, extends DOT/display, changes pick, and at the end calls imported frame open with a generated Journey page. The locally available runner contains no Solo graph-batch sender. Its external frame import's precise runtime revision is not identified by this source inspection.

## Exact remaining boundary

The observed historical mechanisms are source-observed, not newly runtime-observed. No new historical runtime is claimed and no missing Solo/LISTEN behavior was implemented. The existing native captures and their fixtures remain unchanged.

The source chain stops at two different places:

1. Speed Bot fetch/result append → a producer sending those results to the Solo append receiver: no matching sender/revision chain was located in the inspected artifacts.
2. Historical Solo beam mutation → current LISTEN nested-action input → current REPORT caller/lookup target: no implementation continuity was located.

A persistent receiver plus incoming-data mutation/refresh is a plausible analogy and is explicitly `:HYPOTHESIZED`; its answer is NIL, current handoff OPEN, and runtime claim NIL. The graph's fetch-to-popup edge is OPEN. Historical source resemblance is not promoted into observed ancestry. The original retained Mech alias/filter/count result and independently tested state.title lookup remain bounded to their witness revision.

## Verification and execution record

Acceptance traverses actual native references from reading → revision → file → LISTEN/REPORT definition, compares excerpt text to live immutable Git blobs, checks authority/full-OID identity (including different authorities with the same OID), rejects bare short IDs, validates every new typed-source warrant, and checks append/replacement/fetch-barrier and unknown ancestry statuses. Existing nested tree, native message identity capture, current gap, proposal-only scoped emitter, Topicmap Point/history, TALA and Catalog contracts remain covered.

Exact fresh entry points and measured results are recorded in the companion executor JSON and logs:

```sh
nix develop --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system "dreyeck/nested-actions/reading" :force t)' \
  --eval '(asdf:test-system "dreyeck/nested-actions/reading/tests" :force t)' \
  --eval '(asdf:test-system "dreyeck/git/tests")'

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

Both final processes exited 0. Observed: REVISION-PROVENANCE-HISTORY-PASS; all prior Ward/input contracts; Git commit/source-slice/repository/ASDF-reference passes; NESTED-ACTIONS-TALA-PASS; Topicmap and D2 v0.9.0 / seed 44 integration; TALA Reading, checkout, source-widget, authored D2, dispatch and reference passes; and fresh 20-book Catalog startup. Logs: `/private/tmp/nested-provenance-reading-git-final.log` and `/private/tmp/nested-provenance-regressions-final.log`. The first acceptance attempt caught a local binding collision between the earlier context-hypothesis list and the new Solo history object; the bindings were separated and the same matrix rerun. The second attempt caught a missing native current-input code-page link on the added historical page; that link was added without weakening the navigation contract. Failed logs are retained with attempt1 and attempt2 names. The corrected reading and Git suites completed with exit 0, including REVISION-PROVENANCE-HISTORY-PASS and all Git inspection/source-slice/repository/reference passes. Writer diagnostics also retained an initially absent Inspector reader context, incorrect system-key case and one excess parenthesis in a temporary HTML proposal; only guarded/reparsed results were accepted.

Lisp and ASDF writes used the existing pinned structural writer; HTML used the existing DSL and metadata/link reparses. No SHA recognition/parser, new source evaluator, authoring runtime dependency or Nix runtime pin was added. The live Lisp image was not reloaded. No source fetch, SSH or deployment occurred. Reviewed shell execution was used because the configured writable symlink prevents normal sandbox initialization; no permission configuration was changed and no automatic approval review rejection occurred.

The selective commit executor uses the existing Git primitive and commit --only, with exact staged-patch and blob/file-byte preservation assertions for Trails Rendered (staged patch SHA-256 30b874b55d4dc82fdddd8391001e953c37997490d58321981597b37becb9d994; unchanged staged/file blob 00febd71cd6b266c9dd574a6fcea23b0a78dee60). Its post-commit status assertion permits only that pre-existing staged page. The final response returns the measured new commit hash and final status. The previous input-boundary report is explicitly linked forward to this follow-up rather than presented as its implementation.

The first selective-commit attempt stopped at the staged whitespace check on a trailing space in the verbatim speed-run.js excerpt. That space is present in the historical Git blob and is covered by the excerpt hash and live-blob equality tests. The commit executor retains those bytes, checks all other files normally, and checks only this excerpt with the process-local core.whitespace=-blank-at-eol option. No Git configuration or source evidence was changed. The refused attempt is retained in /private/tmp/nested-provenance-commit-attempt1.log.
