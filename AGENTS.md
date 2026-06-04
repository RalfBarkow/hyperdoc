# AGENTS.md

## Repo Orientation

- Project root: `/Users/rgb/workspace/hyperdoc`
- Working directory shorthand: `~/workspace/hyperdoc`
- Main branch in use: `hauptsache` (tracking `gitweb/hauptsache`)
- HyperDoc Documentation pages context: this branch is related to
  `~/workspace/hauptsache` on branch `main`

This repository is a Common Lisp multi-system project centered on HyperDoc and HyperBook.

## Core Systems

- `hyperdoc.asd`
  - `hyperdoc`: core HyperDoc
  - `hyperdoc/inspector`: HyperDoc integration for moldable inspector
  - `hyperdoc/explorer`: explorer UI and page/link tooling
  - `hyperdoc/server`: compatibility alias to runtime server stack
- `hyperbook.asd`
  - `hyperbook`: base HyperBook abstractions
  - `hyperbook/explorer`: explorer support
  - `hyperbook/server`: web server implementation
  - `hyperbook/wikipedia`: Wikipedia integration
  - `hyperbook/fedwiki`: Federated Wiki integration

## Important Paths

- `hyperdoc/`: HyperDoc content and sources (`.html`, `.md`, `.lisp`)
- `/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages`: localhost FedWiki pages related to HyperDoc page workflows
- `hyperdoc-explorer/`: explorer implementation for HyperDoc
- `hyperbook-server/`: server implementation and playground/debug wiring
- `hyperdoc-inspector/`: inspector-facing HyperDoc views/docs
- `assets/`: shared CSS, JS, icons
- `tools/`: utility scripts

## Runtime Entry Points

- `README.md` shows the minimal SBCL startup for serving catalog.
- `start.sh` is the robust non-interactive launcher (env-driven, source registry setup).
- `dev.sh` is the development launcher:
  - enters `nix develop`
  - starts Swank
  - auto-selects free ports
  - loads `hyperbook/server`

## Quick Start (Recommended)

1. `nix develop`
2. `./dev.sh`
3. Open `http://127.0.0.1:8080/boot.html` (or the printed host/port)

## Useful Environment Variables

- `HYPERDOC_PORT` (default: `8080` if free)
- `HYPERDOC_BIND_ADDRESS` (default: `127.0.0.1`)
- `HYPERDOC_DEVELOPMENT` (`1` enables playground eval)
- `SWANK_PORT` (optional override)
- `SWANK_INTERFACE` (default: `127.0.0.1`)

## Notes for Agents

- Prefer loading `hyperdoc/server` or `hyperbook/server` via ASDF, depending on scope.
- Prefer repo git steps through `nix develop --command git ...` so git runs inside the same authoritative repo shell as validation; use `nix shell nixpkgs#git -c ...` only as a narrower fallback when the dev shell is unavailable.
- Use `dev.sh` for local iteration and debugging; use `start.sh` for stricter startup behavior.
- Content updates are often in `hyperdoc/`; runtime behavior typically lives in `hyperbook-server/` and `hyperdoc-explorer/`.
- Treat HyperDoc pages and localhost FedWiki pages as connected communication surfaces. HyperDoc pages can be mirrored or linked to FedWiki counterparts in `/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages` when workflows depend on wiki journaling/editing.
- Apply the two-surface rule when documenting:
  - put durable architecture/reference content in HyperDoc pages,
  - keep fast-moving collaborative trail in localhost FedWiki pages,
  - maintain navigable links/counterparts per topic instead of forcing identical content in both places.

## S-Expression Prompt / Split-View Contract

When a slice touches prompt design, executable prompts, page-to-topicmap
projection, FedWiki story generation, HyperDoc page generation, or inspector
topicmap views, treat the prompt as a homoiconic S-expression program with
three explicit layers:

1. Knowledge
   - rules
   - constraints
   - invariants
   - repo boundaries
   - terminology
   - validation policy

2. Input
   - concrete execution data
   - source page path
   - parsed DOM/tree
   - selected story items
   - source evidence
   - operator task

3. Output contract
   - required response views
   - validation predicates
   - replay expectations
   - exact success/failure shape

A valid HyperDoc prompt response in this workflow must be representable as a
split view:

- FedWiki story view: human-readable sequence of story items.
- Topic map program view: the corresponding S-expression topic/relation program.

The topic map program is not an external syntax tree. It is the durable program.
HTML, FedWiki story JSON, DMX topic maps, inspector views, and rendered pages are
projections of that program unless the slice explicitly says otherwise.

Do not create a prose-only answer for these slices. Preserve the program form,
validate it, and expose it through the inspector.

## Executable DITA Task Contract

When a slice touches Codex prompts, executable plans, DITA-like task topics,
SCXML execution contracts, or prompt/plan/evidence sharing, prefer representing
the work as an `executable-dita-task` object when the task has durable identity
and replay value.

Preserve this model:

- The canonical S-expression task object is the source of truth.
- DITA XML, HyperDoc HTML, SCXML XML, SQLite rows, and rendered pages are
  projections of that object.
- Stable identity is the task `:id`.
- PDDL/SHOP3-shaped fields are data unless the planner runtime is explicitly
  coherent in the current slice.
- Operator execution is guarded; print/inspect is the safe default.
- SQLite evidence for this contract stays under
  `/Users/rgb/workspace/hyperdoc/var/`.
- Moldable inspector views are read-only projections of the task object,
  SQLite task row, SQLite next-task candidates, and ranked selection output.
  They must expose canonical S-expression, DITA, HyperDoc HTML, SCXML, and
  SQLite evidence without becoming a second source of truth.

For the first implementation surface, load the narrow ASDF system
`hyperdoc/executable-dita-tasks`. Do not require Quicklisp, do not use
Quicklisp package-prefixed symbols in readable source, do not require `:shop3`
for the smoke test, and do not load full `:kioskbeerli` just to inspect or
persist executable DITA task objects.

## Touch-Fahrplan Route Terminology

When a slice touches Connect, Dock, Annotation, Touch-Fahrplan, or DMX
association authoring, keep this wording model durable across prompts, docs,
and user-facing copy:

- User-facing concept: `route-laying gesture`
- Preferred user-facing action label: `Lay route`
- Touch-Fahrplan metaphor:
  - topics are stations
  - associations are routes between stations
  - the route is itself a first-class topic/object
- Low-level implementation term: `drag-to-connect`
- Acceptable non-drag fallback term: `two-tap route-laying`
- Avoid as canonical term: plain `swipe`

Preserve these semantic distinctions:

- `Lay route` = author a new association topic / route topic between two
  stations/topics
- `Follow route` = traverse an existing association / route
- Keep the DMX idea that the association is itself first-class and preserve
  player-role framing such as `player1` and `player2` where relevant
- Do not make DMX or Touch-Fahrplan a competing permanent Dock identity
- Keep HyperDoc's Dock as the capability-introduction layer
- Keep richer route/traversal UI in the pane body or another dedicated surface
- Keep Annotation as a sibling capability in the same grammar

When one sentence needs both layers, prefer explicit phrasing such as:
`Touch-Fahrplan route-laying gesture (implemented initially as drag-to-connect).`

## Touch-Fahrplan Route Language and Touch-first McCLIM Grammar

When a slice touches Touch-Fahrplan, Connect, Dock, Annotation, DMX
association authoring, or touch-first McCLIM interaction, preserve this
guidance as a durable architectural rule.

Read it first as a Touch-Fahrplan route language for HyperDoc:

- topics are stations
- associations are routes between stations
- the route is itself first-class
- `Lay route` is the preferred user-facing authoring label
- `Follow route` is the preferred traversal label
- `drag-to-connect` is the mechanic term, not the primary user-facing label
- `two-tap route-laying` is the non-drag fallback

The touch-first gesture grammar exists to preserve and operationalize that
route-language model. It should not be presented first as a generic mobile
touch catalog.

### Canonical Touch-Fahrplan mapping

Keep the branded Touch-Fahrplan mapping readable as a route-language system:

- orient
  - tap = focus
  - press = inspect
  - two-finger tap = metadata
  - tap(blank) = clear
- move
  - swipe-left/right = back/forward
  - swipe-up/down = parent/child or collapse/expand
  - edge-swipe = global navigation rail
- understand
  - drag(source -> target) = route preview / route reveal
  - press-then-drag(source -> target) = `Lay route`
  - tap(link) = `Follow route`
  - double-tap = open / drill in
- scale
  - pinch-out = more detail
  - pinch-in = more abstraction
  - scrub = preview alternate views

### Semantic authority

- gestures are the input language
- semantic objects on screen are the nouns
- CLIM commands are the verbs
- command execution is the only way application state changes

Interpretation:

- interactive content must be presentation-backed
- gesture recognition feeds command dispatch
- dispatch is the semantic authority
- commands mutate frame/application state and then redisplay
- do not mutate UI state directly from raw pointer handlers or widget-local
  callbacks

### Required presentation-backed object model

Use at least these semantic target classes when this area is in scope:

- `doc-node`
- `doc-link`
- `doc-collection`
- `doc-view`
- `doc-anchor`
- `doc-tool`
- `doc-selection`
- `doc-blank-area`

These are the noun layer. The recognizer may start from raw pointer input, but
gesture meaning must resolve against these presentation-backed semantic
objects.

### Interaction layers

Keep the architecture explicit:

1. raw touch / pointer-event layer
2. gesture-recognition layer
3. command-dispatch layer

Raw events are not the semantic contract. The command-dispatch layer is.

### Normalized gesture namespace

Use this normalized technical gesture vocabulary:

- `hd-tap`
- `hd-double-tap`
- `hd-press`
- `hd-drag`
- `hd-flick-left`
- `hd-flick-right`
- `hd-swipe-up`
- `hd-swipe-down`
- `hd-pinch-in`
- `hd-pinch-out`
- `hd-two-finger-tap`
- `hd-edge-swipe-left`
- `hd-edge-swipe-right`
- `hd-lasso`
- `hd-scrub`

Notes:

- `press-then-drag` is the explicit armed relation-creation pattern built from
  `hd-press` plus `hd-drag`; it does not need a separate durable namespace
  token unless a slice proves that one is required.
- The recognizer namespace may include `swipe`, but plain `swipe` is still not
  the durable user-facing term for route authoring or route traversal. Keep
  `Lay route`, `Follow route`, `drag-to-connect`, and `two-tap route-laying`
  distinct.

### Semantic gesture defaults

- tap = focus / select / nearest primary action
- double-tap = open / drill in / expand primary detail
- press = reveal actions / inspect / secondary affordances
- drag = route preview / reorder / pan from blank area
- flick = navigate / dismiss / neighbor / history
- swipe left-right = back-forward or sibling traversal
- swipe up-down = hierarchy traversal or collapse-expand
- pinch-out = more detail / zoom in / lower abstraction
- pinch-in = more abstraction / zoom out / collapse detail
- two-finger tap = metadata / cancel transient state / dismiss overlay
- press-then-drag = explicit relation creation
- edge-swipe = global navigation rail / hidden context pane / stack pop
- lasso = multi-select
- scrub = preview alternate views without commit

### Target-specific command mapping

On `doc-node`:

- tap -> `com-focus-object`
- second tap on focused node -> `com-select-object`
- double-tap -> `com-open-object`
- press -> `com-show-actions`
- drag node->node -> route preview / route reveal, commit `com-show-relation`
- press-then-drag node->node -> `Lay route`, dispatch `com-create-relation`
- swipe-left -> `com-go-back`
- swipe-right -> `com-go-forward`
- swipe-up -> `com-go-parent`
- swipe-down -> `com-go-child` or `com-expand-object`
- pinch-out -> `com-expand-neighborhood` or `com-zoom-in`
- pinch-in -> `com-collapse-neighborhood` or `com-zoom-out`
- two-finger tap -> `com-show-metadata`

Touch-Fahrplan interpretation:

- a topic-like `doc-node` is a station
- drag in Browse mode previews or reveals a route between stations
- `press-then-drag` or explicit Author mode lays a new route
- use `Lay route` for the user-facing authoring label
- keep `Follow route` distinct as traversal of an existing route
- use `drag-to-connect` only for the underlying mechanic

On `doc-link`:

- tap -> `Follow route` via `com-follow-link`
- press -> `com-show-citations` or `com-show-metadata`
- drag -> `com-highlight-path`

On `doc-collection`:

- tap -> `com-focus-object`
- double-tap -> `com-open-object`
- press -> `com-show-actions`
- swipe-up -> `com-collapse-object`
- swipe-down -> `com-expand-object`
- pinch-in -> higher abstraction
- pinch-out -> lower abstraction

On `doc-blank-area`:

- tap -> `com-clear-selection`
- drag -> viewport pan through command-driven navigation
- flick-left -> `com-go-forward`
- flick-right -> `com-go-back`
- press -> `com-toggle-overview`
- two-finger tap -> `com-dismiss-overlay`
- pinch-out -> global zoom-in
- pinch-in -> global zoom-out
- lasso -> `com-select-region`

On `doc-view`:

- tap -> `com-switch-view`
- scrub -> preview alternate views with no commit until release
- double-tap -> `com-switch-view` plus recenter current focus

### Safety and parsing rules

- Browse mode is the safe default.
- Plain drag between semantic objects defaults to non-destructive route preview
  or route reveal, not route authoring.
- Destructive or authoring semantics require explicit Author mode or
  `press-then-drag`.
- Never bind destructive semantics to plain tap.

Parsing precedence:

1. press beats tap after hold threshold
2. drag beats press after motion threshold
3. flick beats ordinary drag on end velocity
4. stable second contact makes multi-touch win
5. initial target fixes source semantics
6. relation creation requires explicit arm state or Author mode

### Explicit gesture states and feedback

Recognizer states:

- `idle`
- `contact-began`
- `armed-tap`
- `armed-press`
- `dragging`
- `multitouch`
- `preview`
- `commit`
- `cancel`

Mandatory visual feedback:

- focus halo on contact
- press ring when hold threshold crosses
- relation line preview while dragging
- snap highlight on candidate target
- ghost overlay for previewed expansion
- cancellation fade on abort

### McCLIM implementation stance

Future slices in this area should frame implementation in McCLIM terms:

- presentation-backed output for all semantic targets
- presentation translators and presentation-to-command translators for dispatch
- blank-area translators for background gestures
- `define-gesture-name` for normalized gesture names
- pointer tracking / pointer-motion handling for recognizer support
- command objects and redisplay, not widget-local hidden mutation

### Minimal first implementation profile

If a slice only establishes the first credible touch-first surface, keep it to:

Gestures:

- tap
- press
- drag
- swipe-left-right
- pinch-in-out
- two-finger tap

Commands:

- `com-focus-object`
- `com-open-object`
- `com-show-actions`
- `com-show-relation`
- `com-go-back`
- `com-go-forward`
- `com-expand-object`
- `com-collapse-object`
- `com-zoom-in`
- `com-zoom-out`
- `com-clear-selection`

Do not broaden beyond that profile unless the slice explicitly asks for it.

## Codex task execution rules

- Work one slice per thread. Do not switch to a different slice inside the same thread unless I explicitly retarget the task.
- Treat `nix develop` as the authoritative environment for this repository's repo-defined validation, dependency resolution, and bundled tooling.
- If a raw host command fails because a dependency, executable, or ASDF component is missing, do not stop there if the same command can be rerun inside `nix develop`.
- For repo-scoped checks, prefer this order:
  1. try the requested command as written if practical
  2. if it fails due to host-environment or tooling resolution, rerun it inside `nix develop`
  3. treat the `nix develop` result as authoritative unless the task is explicitly about host portability, system service behavior, or a non-Nix runtime or deployment path
- Distinguish environment failures from slice failures in the report.
- When relevant, report both outcomes:
  - host-environment failure, if any
  - authoritative `nix develop` validation result
- Do not describe a slice as blocked merely because the host environment is missing repo-managed dependencies or tools.
- If the task is explicitly about host portability, systemd services, launcher scripts outside the dev shell, deployment hosts, or non-Nix runtime behavior, host behavior is part of the task and must be reported as such.
- Do not stop at planning when the slice, file scope, and validation command are already concrete.
- Do not broaden scope. If one small adjacent documentation update is explicitly in scope, keep it tightly coupled to the code change.
- Return exact files changed, exact validation commands run, and exact outcomes.

### Analysis and explanation quality

- For analysis, review, and documentation work, prefer rationale and evidence over verbose paraphrase of code that is already visible.
- Keep explanation length proportional to the importance, risk, and complexity of the point; do not turn straightforward code paths into long prose walkthroughs.
- State the inspected evidence basis for analysis claims when it matters, for example the relevant code paths, authored HyperDoc pages, tests, issue pages, or discussion pages.
- Separate `observation`, `inference`, and `recommendation` so readers can tell what was directly seen, what was concluded, and what is being proposed.
- Do not create durable pages whose main value is restating code behavior without adding rationale, boundary clarification, evidence, or a reusable concept.

## Expectation Handling Policy

When an expectation fails, preserve the expectation itself as an artifact before
explaining it away.

Use this decision pattern:

1. Expectation
2. Observed reality
3. Why this expectation was plausible
4. Classification
5. Resolution
6. Prevention

### False vs. disappointed expectations

- `False expectation`
  - the expectation was not actually supported by the system, the reference
    implementation, or the agreed contract
  - response:
    - do not change the system merely to satisfy the mistaken assumption
    - state the actual behavior and the authority for it
    - tighten the nearby promise surface so the same mistaken inference is less
      likely

- `Disappointed expectation`
  - the expectation was reasonable because the docs, UI, previous behavior,
    naming, examples, or workflow strongly suggested it
  - response:
    - treat the mismatch as a product/documentation/design defect
    - identify which layer created the expectation
    - either restore the expected behavior, preserve the current behavior but
      repair the surrounding promise surface, or introduce a clearer boundary

Rules:
- always record the expectation in the user’s or operator’s original frame
  before correcting it
- avoid jumping straight to root cause
- distinguish semantic mismatch from operational failure
- never collapse “reasonable but unmet” into “simply wrong”
- prefer fixing the layer that generated the expectation
- document the failed expectation at the boundary where it was created, not
  only where it became visible

Compact formula:
- preserve the expectation
- classify it as false or disappointed
- for false expectations, correct the model
- for disappointed expectations, repair the system or the promise surface
- in both cases, leave behind a clearer boundary than before

### Specialized rule: stale example expectation before helper change

When an example fails, but helper, surrounding docs, and reference semantics
agree, verify the example expectation before changing the helper.

Rules:
- do not change a helper reflexively just because an assertion failed
- for ordering semantics, derive behavior from:
  - traversal direction
  - dedup strategy
  - `nil`/`null` filtering
  - append vs. prepend
  - reference implementation behavior
- do not smuggle a sorted or intuitive order into the expectation when the
  semantics are history-derived

Adjust the example assertion to the actual specified behavior when:
- implementation and reference system agree, and
- surrounding documentation supports that behavior or does not contradict it

Change the helper only for an actual contract violation, for example when:
- the implementation contradicts the reference semantics
- the documentation clearly promises something else
- multiple existing tests/examples consistently encode the opposite semantics
- the current behavior is internally inconsistent

Interpretation:
- this is usually a `false` or stale expectation case
- it becomes a `disappointed expectation` case if the system itself created the
  wrong expectation through docs, naming, UI, or examples
- in that case, repair the promise surface too, not only the assertion

## Documentation page genres: reference vs walkthrough example

When producing or revising HyperDoc documentation pages, explicitly classify the
target page genre before drafting.

### 1) Reference/contract pages

Use this genre for:

- definitions
- contracts
- inventories
- architecture summaries
- browseable inspectable-object indexes

### 2) Walkthrough example pages

Use this genre for:

- story-driven demonstrations
- click-through learning
- before/after workflows
- operational "how and why this works" teaching pages

Rule:
- if the user asks for an `example page`, default to a walkthrough example page
  unless they explicitly ask for a reference/contract page.
- do not respond to an example-page request with an index/catalog page plus
  numbered headings.

### Required structure for walkthrough example pages

Default structure:

- `Goal`
- `Starting situation`
- `Step 1`, `Step 2`, ...
- `Expected result` and/or `Why this matters`
- `Boundary`

Each step must include, compactly:

- `Click:` what to open/run
- `Observe:` what to notice
- `Why this matters:` what that observation proves

### Narrative arc requirement

Walkthrough example pages should follow this arc:

- start state
- inspect cause
- inspect derivation
- act / mutate / run
- observe changed result
- explain significance

For mutation/rewrite/debug walkthroughs, require explicit:

- before
- cause
- action
- after

### HyperDoc-specific clickable example rule

Clickable `expr` links alone do not make a page a good example page.
A HyperDoc walkthrough example page must stage clickable expressions as a
sequence of actions with observations and consequences.

### Style constraints for walkthrough example pages

- compact prose
- task-centric rather than object-centric organization
- operational examples do most of the teaching
- every step states what the reader should notice
- include a minimal but explicit `Boundary` section
- avoid manifesto-style expansion
- do not mistake "clickable" for "example-driven"

### Walkthrough acceptance heuristic

Before marking an example page done, verify:

1. Does the page tell a story?
2. Does each step include `Click / Observe / Why`?
3. Is there a clear before/after payoff?
4. Could a reader follow it without already knowing the architecture?
5. Would it still read as an example if raw object names were hidden?

If any answer is no, rewrite the page as a walkthrough rather than polishing an
index page.

## Routine: Update HyperDoc + FedWiki Twins + Topics

When adding/updating a concept cluster (e.g. new external input, architecture note, workflow correction), update all three surfaces together:

1. HyperDoc page(s): update or add `hyperdoc/*.html` page content.
2. Lisp topic objects: update `hyperdoc/topics.lisp` with inspectable topic constructors.
3. Localhost FedWiki twins: update/add pages in `/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages`.

### Topic object requirements

- Define one topic function per inspectable concept in `hyperdoc/topics.lisp`.
- Each topic must include:
  - `:id` (stable slug/key),
  - `:title` (human label),
  - `:summary` (one-sentence synopsis),
  - `:references` (optional editorial references, HyperDoc pages and/or URLs).
- Topic title is the canonical page id in HyperBook `topics`; keep stable key separate for Lisp identity/migration.
- HyperDoc pages should expose topics via `hyperbook="topics" page="Exact Topic Title"` in an `Inspectable objects` section.

### FedWiki twin requirements

- For each topic id, maintain a FedWiki page with:
  - `slug` = topic `:id` (filename in pages store),
  - `title` = topic `:title`,
  - first paragraph = topic `:summary`,
  - references section linking each `:references` entry
    (`[[Page]]` for internal pages, `[url url]` for external links).
- Keep the related narrative twin page updated (if one exists), and add an anchor note to the relevant daily page (e.g. `2026-03-05`).

### Linking and lookup rules

- Prefer slug-keyed links for FedWiki hyperbooks:
  - `hyperbook="fedwiki:wiki.ralfbarkow.ch" page="<slug>"`
- Use title only for visible link text.
- If you see `No page "<Title>" in HyperBook "wiki.ralfbarkow.ch"`, switch `page=` to the slug/file key.

### Verification checklist

- `asdf:load-system :hyperdoc` succeeds.
- New topic functions are `fboundp`.
- FedWiki JSON files parse (`python3 -m json.tool`).
- HyperDoc page links to FedWiki use slug-based `page=...`.
- Commit HyperDoc repo and FedWiki pages repo separately.

### Documentation-slice quick procedure

For the full rationale and examples, see
`hyperdoc/Authoring Documentation in HyperDoc.html`.

1. Create/update a durable HyperDoc page when the distinction should remain stable.
2. Add topic objects in `hyperdoc/topics.lisp` when concepts must be reusable inspectable handles.
3. Link page-to-topic relations explicitly with `hyperbook="topics" page="Exact Topic Title"`.
4. Add FedWiki twins when collaborative journaling/parallel working trace is useful; do not force literal page symmetry.
5. Split commits by surface:
   - `docs(hyperdoc)`: durable page/topic/cross-link changes
   - `docs(fedwiki)`: twin page changes
6. Run helper:
   - `tools/validate-documentation-slice.sh --page "hyperdoc/<Page>.html" --topic <topic-fn> [--topic ...] [--fedwiki /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug> ...]`
7. Mandatory checks:
   - `asdf:load-system :hyperdoc`
   - `fboundp` for new topic functions
   - `tools/check-topic-coverage.lisp` on the page
   - `python3 -m json.tool` for changed FedWiki files (if any)
8. Optional check (recommended when FedWiki pages are edited):
   - journal semantic checker clear of `CREATION`, `CHRONOLOGY`, `REVISION`, `MALFORMED`.

### JSON validation with `python3 -m json.tool`

Use `json.tool` as a syntax/structure guard before committing FedWiki page files.

- Validate a single page file:
  - `python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug> >/tmp/<slug>.json`
- Validate multiple touched files:
  - `python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/2026-03-05 >/tmp/2026-03-05.json`
  - `python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<other-slug> >/tmp/<other-slug>.json`

What this check guarantees:

- valid JSON syntax
- parsable object structure

What it does not guarantee:

- FedWiki semantic correctness of `journal` action ordering/consistency
- page-link correctness (slug/title mapping)
- chronology/replay validity (those require journalmatic checks)

### Mandatory pre-commit: Journal Checker (FedWiki pages)

For any commit touching localhost FedWiki page JSON files, run journalmatic
checks before commit, not after:

1. Syntax gate (json.tool):
   - `python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug> >/tmp/<slug>.json`
2. Semantic gate (journal checker findings):
   - Must be clear of: `CREATION`, `CHRONOLOGY`, `REVISION`, `MALFORMED`
3. If findings exist:
   - repair journal first (e.g. restore `create` first, fix monotonic dates, rebuild replayable journal),
   - rerun checker until clear.
4. Binding workflow rule for page edits:
   - all FedWiki page changes are journal actions recorded after the fact, so the
     `story` remains reconstructable by replaying `journal`,
   - `create` must be first action,
   - action dates use runtime epoch millis with monotonic rule:
     `max(now, last-date + 1)`,
   - never hardcode fixed/future date constants in generated journals.
5. Commit slicing:
   - commit repair-only journal fixes separately from content/topic updates,
   - keep HyperDoc repo commit(s) separate from localhost FedWiki repo commit(s),
   - do not push unless explicitly requested.

### Story-item ID normalization mapping

When a bulk story/journal ID normalization migration is done, write a durable
old->new lookup mapping in localhost FedWiki pages storage so old IDs remain
searchable.

Current mapping artifacts (2026-03-06 migration commit `a3db41d5`):

- `/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/fedwiki-story-id-normalization-map-2026-03-06/id-normalization-map-2026-03-06.tsv`
- `/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/fedwiki-story-id-normalization-map-2026-03-06/id-normalization-map-2026-03-06.json`
- `/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/fedwiki-story-id-normalization-map-2026-03-06/id-normalization-index-2026-03-06.json`
- `/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/fedwiki-story-id-normalization-map-2026-03-06`

Lookup commands:

- TSV grep:
  - `rg -n '^<OLD_ID>\t' /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/fedwiki-story-id-normalization-map-2026-03-06/id-normalization-map-2026-03-06.tsv`
- JSON index:
  - `jq -r '.old_id_index["<OLD_ID>"][] | [.new_id,.page,.path] | @tsv' /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/fedwiki-story-id-normalization-map-2026-03-06/id-normalization-index-2026-03-06.json`

Notes:

- The same old ID string can map to different new IDs in different pages.
- Use `(page, path)` to disambiguate.

## Mandatory: Every Answer Reconstruction Protocol

This is not optional and does not apply only to code-change turns.
Each assistant answer must be reconstructable as HyperDoc + Lisp + FedWiki artifacts.

### Two Answer Surfaces (must be distinguished)

Every response must explicitly distinguish:

1. **Surface Answer** (Terminal/Codex session)
   - Immediate answer to the user in this chat.
   - Can be concise, but must still include minimal reconstruction metadata.

2. **Artifact Answer** (HyperDoc/FedWiki/Lisp changes)
   - Durable representation in repository/wiki artifacts.
   - Includes page/topic/code edits and validation outputs.

Rule:
- If the user asks for implementation/documentation/update, deliver both Surface + Artifact.
- If the user asks only a conceptual question, deliver Surface now and include an Artifact plan delta (what would be changed, where), unless user explicitly says no artifact updates.

For every answer, include enough structure to derive:

1. **Process Trace**
   - What was inspected, inferred, and decided.
   - Which commands/checks were used (or would be used).

2. **HyperDoc Reconstruction**
   - Which HyperDoc page(s) to create/update.
   - The section-level content delta (headings, inspectable objects, related links).

3. **Lisp Source Reconstruction**
   - Which topic/object/view/function definitions to add/update.
   - Concrete function names and expected references.

4. **FedWiki Twin Reconstruction**
   - Slug/title/summary/references updates for localhost twin pages.
   - Daily anchor updates when relevant.

5. **Replayability Checks**
   - Validation steps sufficient to replay the result:
     - JSON parse checks (`python3 -m json.tool`)
     - journal integrity expectations (creation first, chronology monotonic, revision replay)
     - link resolution checks (slug over title for FedWiki hyperbooks).

6. **Skillization Requirement**
   - Extract recurring patterns from the answer into explicit skill candidates.
   - Update skill instructions/specs when patterns recur, so Lisp/runtime code can execute the routine directly instead of requiring repeated assistant intervention.
   - Link skill updates back into HyperDoc/FedWiki topic graph.

### Minimum response contract

Even for short/non-edit answers, provide at least a minimal reconstruction block that covers:
- process trace,
- HyperDoc page delta,
- Lisp/topic delta,
- FedWiki delta,
- replay check.

For non-edit turns, these can be marked as:
- `No file changes; proposed artifact deltas: ...`

## SLY MREPL inspectability requirement

For any Common Lisp change that introduces or refactors runtime objects,
Codex must provide one copy-pasteable SLY MREPL snippet that creates and
inspects a minimal object. The snippet must define its own safe `i` helper
unless the surrounding page already defines it.

The snippet must:
- load required ASDF systems when needed;
- not depend on pre-existing repository examples unless the task is specifically about those examples;
- construct a minimal fixture object directly;
- exercise the changed runtime path;
- bind important objects to globals such as `*example-entry*`, `*example-result*`, or `*example-run*`;
- print type, status, and core value;
- end with `(i <object>)`;
- be actually pasteable into SLY MREPL.
- never call `slynk:inspect-in-emacs` directly or depend on SLYNK private
  dynamic state such as `slynk::*buffer-package*`;
- prefer `clog-moldable-inspector:clog-inspect` only when the
  `CLOG-MOLDABLE-INSPECTOR` package and `CLOG-INSPECT` function are already
  loaded; otherwise use `cl:inspect`.

Use this `i` shape for snippets unless the slice has a more specific stable
inspector entrypoint:

```lisp
(defun i (object)
  "Safe inspector helper for SLY mREPL.
Prefer CLOG only if it is already loaded; otherwise use CL:INSPECT.
Never calls SLYNK:INSPECT-IN-EMACS directly."
  (let* ((clog-package (find-package "CLOG-MOLDABLE-INSPECTOR"))
         (clog-symbol
           (and clog-package
                (find-symbol "CLOG-INSPECT" clog-package))))
    (cond
      ((and clog-symbol (fboundp clog-symbol))
       (handler-case
           (progn
             (funcall (symbol-function clog-symbol) :object object)
             object)
         (condition (condition)
           (format t "~&CLOG inspector failed; falling back to CL:INSPECT: ~A~%"
                   condition)
           (inspect object)
           object)))
      (t
       (inspect object)
       object))))
```

For the Examples runtime, the minimum demo is:
1. create one `hyperdoc:example-entry`;
2. run it with `hyperdoc:run-example-entry`;
3. inspect the resulting `hyperdoc:example-result` with `(i *example-result*)`.

Passing tests are not enough unless this MREPL inspection path is also provided.

## Inspectable source navigation requirement

For any Common Lisp runtime object that displays a function, method, example,
test, action, or runnable entry, Codex must provide a source-navigation path in
the inspector when source metadata is available.

A runtime function object is not sufficient as a source target. The inspector
must expose one of:
- a source-file/pathname target;
- a symbol or locator target with a source view;
- a source artifact object;
- or an explicit source-unavailable diagnostic.

Topic-backed source text must be backed by a durable source artifact store,
initially SQLite-compatible. A topic-backed `example-source-reference` points
to a persisted `example-source-artifact`; the inspector must render topic
source by loading that artifact, not by scraping the raw function object or
depending on transient in-memory source text.

For a persisted `example-source-artifact`, the primary/default inspector view
is `Source code`. It renders only source text. Source id, topic, language, form
kind, provenance, and store/backend diagnostics belong in a separate `Meta`
view. Do not put metadata, explanatory prose, or materialized-file diagnostics
inside the `Source code` view. Use a `Summary` view only for an actual human
summary, not as the source artifact's metadata view.

For Examples work specifically:
- `example-result` must expose its `example-entry`;
- `example-entry` must expose function, locator, source-file, source-page, and tags;
- the `example-result` summary must include a source-oriented row/action separate
  from the raw Function row;
- file-backed examples must open a source/code view from the Source action;
- supplied topic source text must be persisted before being exposed as a topic
  source reference;
- MREPL-only examples must explicitly report source unavailable or SLY MREPL.

The minimal SLY MREPL demo must prove both:
1. an inspectable runtime result exists, ending with `(i *example-result*)`;
2. the result gives an inspector path toward source metadata, even if the demo
   function itself was defined in the MREPL and has no file-backed source.

## Inspectable topic/association path evidence

Everything transformed by Codex, ChatGPT, or agentic tooling must be representable in HyperDoc’s lingua franca: topics and associations.

This applies to source artifacts, examples, runs, tests, inspector views, UI paths, SCXML transitions, Playwright observations, Codex handoffs, failures, diagnostics, and transformation results.

Paths are first-class graph objects. A path must not remain only a prose description, console log, transient trace, or test helper. It must be translated into topics and associations so that a human can inspect, compare, annotate, and reason about it in CLOG/HyperDoc.

The local persistence layer for these artifacts should be SQLite-backed and functionally equivalent to the relevant DMX topic/association model, without requiring Neo4j.

For path-sensitive work, Codex must persist:

- a path trace topic;
- ordered path step topics;
- associations between steps;
- associations to source objects, methods, endpoints, SCXML states/events/transitions/actions, Playwright observations, rendered views, and DOM evidence;
- provenance linking the trace to the agent run and validation command.

When a bug is described as a mismatch between paths, Codex must produce an inspectable comparison artifact showing both paths side by side and identifying the first divergent step.

For UI work, Codex must distinguish:

- model/view path;
- synthetic smoke-test path;
- actual CLOG inspector path;
- Playwright browser path;
- SCXML behavior path.

Acceptance for path-sensitive UI behavior requires:

1. an inspectable path artifact;
2. SQLite-backed topic/association persistence;
3. a path comparison when more than one candidate path exists;
4. a human-readable CLOG visualization;
5. replay instructions from SLY MREPL;
6. tests at the correct layer.

Do not claim completion from a final result alone. For path-sensitive UI behavior, the route to the result is part of the product.
