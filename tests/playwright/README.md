# Playwright DOM Association Findings

The reusable pane-chrome regression harness for the current provider-based
Connect UI lives in:

- `tests/playwright/pane-chrome-harness.js`

It protects these invariants for future Connect/provider slices:

- main tabs stay clickable while Connect chrome is present
- the subordinate Connect row does not steal neighboring hit targets
- `?` opens a help panel attached to the Connect row without shifting the active view
- the visible `Inspect` action opens a real Connect session object without requiring devtools
- provider-surface availability resyncs correctly across connectable and non-connectable tab switches
- browser-side Connect event traces remain collectable while the chrome harness evolves

This suite materializes the current DOM association findings as browser tests:

- `content view opens an association through pane-chrome Connect`
  - proves the working `dom-v1` provider path with resolved content anchors
  - asserts the authoritative transport is `button-payload-v2`
- `content view opens a cross-pane association through pane-chrome Connect`
  - proves an explicit two-pane Connect session survives source selection in one pane and target selection in another
  - asserts the authoritative transport carries distinct source and target pane ids
- `content view opens a HyperDoc to FedWiki association through pane-chrome Connect`
  - proves the first real heterogeneous two-pane path: HyperDoc content anchor -> FedWiki story-item anchor
  - asserts the authoritative transport remains `button-payload-v2` while carrying `dom-v1` on one side and `fedwiki-v1` on the other
- `Connect inspection is reachable from the pane chrome`
  - proves the running pane exposes a discoverable `Inspect` affordance
  - asserts the opened object has `Summary`, `Panes`, `Transitions`, and `Payload / Anchors` views
- `Connect inspection reflects choose-source, choose-target, and cancel reset`
  - proves the inspectable session object reports `choose-source` before selection and `choose-target` with the selected source label afterward
  - proves repeated `Inspect` clicks reuse the live inspection pane for the same source pane instead of opening duplicates
  - asserts the `Panes`, `Transitions`, and `Payload / Anchors` views stay aligned with pane-local phase and stage-log vocabulary
- `Connect inspection resets cleanly after a successful association`
  - proves the snapshot returns to `idle` after success while retaining recent transition history such as `request-payload-written` and `pane-open-succeeded`
- `pane-chrome help opens without shifting the active view`
  - proves the `?` help toggle opens in the subordinate pane-chrome Connect row
  - asserts the help panel does not move the active view or change document height
- `main tabs stay clickable while Connect help is open`
  - proves normal pane navigation still works while the Connect chrome is visible
  - exercises representative stable tabs through the reusable harness
- `provider-surface sync settles across a Pages round trip`
  - proves Connect availability follows the active view across a connectable/non-connectable switch
  - guards the resync timing boundary that previously left pane chrome in a stale state
- `plain Source stays readable and Connect source opens a source-line association`
  - proves the `source-v1` provider behavior on the `Creating a HyperDoc` page through the explicit Connect source view after confirming the default Source view is plain/readable
  - asserts the authoritative transport remains `button-payload-v2` for source-line anchors too

The bibliography authoring-plan follow-up also has a live-gated browser suite:

- `tests/playwright/bibliography-authoring-plan-live.spec.js`
  - opens the tracked bibliography capability page and follows machine-local live plan probes for real Zotero subcollections
  - checks that sparse continuity-shell cases, arrangement-vs-new-topic ambiguity, and thin generic new-topic proposals remain inspectable before materialization
  - records per-case `paneOpenMs` and `paneOpenTimeoutMs` JSON attachments so slow live collections are measurable rather than anecdotal
  - requires `HYPERDOC_RUN_ZOTERO_LIVE_TESTS=1`

The bibliography slice now also has a stand-in/protocol layer:

- `tests/playwright/bibliography-authoring-plan-standin.spec.js`
  - keeps the browser-facing seam explicit by proving readiness before any real pane-open/render step
  - checks tracked entry-page selection, runtime-surface inventory classification, workspace-vs-flake mismatch classification, authoring-plan readiness, and artifact-bundle production
  - uses `tools/bibliography-authoring-plan-standin-report.lisp` as the non-browser probe
  - keeps Playwright only as the test runner and artifact surface here; it does not depend on a rendered browser pane for the readiness classification
  - requires `HYPERDOC_RUN_ZOTERO_LIVE_TESTS=1` only for the live `Plastics Packaging` probe

The current authoritative live Chromium status for that gated suite is:

- `HTML Rewriting`: failed in the latest authoritative rerun before pane-open timing was reached, at the browser-entry boundary in `gotoCatalog` while waiting for the first `.inspector-pane`; the configured `60_000ms` pane-open budget was not used
- `Topological Intelligence`: did not run in that serial rerun; its configured pane-open budget remains `45_000ms`
- `Plastics Packaging`: did not run in that serial rerun; its configured pane-open budget remains `60_000ms`

`Plastics Packaging` is the heaviest current live case because the full pane-open
path combines a broader live import, more candidate extraction from thin cues,
more inspector content to render, and longer UI polling before the plan pane is
fully visible. The latest authoritative rerun did not reach that heavy-case
boundary because the suite failed earlier, at the browser-entry boundary before
the first live case opened HyperDoc. The suite keeps that boundary explicit; it
does not add silent retries.

## Run

If no server is already running, the Playwright config starts one locally on `http://127.0.0.1:18080/boot.html` via `nix run .`.

```sh
nix develop --command npm ci
nix develop --command npm run test:playwright:nor
nix develop --command npm run test:playwright
```

To reuse an existing local server instead:

```sh
HYPERDOC_BASE_URL=http://127.0.0.1:56719/boot.html \
  nix develop --command npm run test:playwright:nor
```

The Playwright Test runner is provided by the root `@playwright/test`
devDependency. Browser binaries come from the Nix dev shell through
`PLAYWRIGHT_BROWSERS_PATH`, with browser downloads skipped during `npm ci`.
Running `playwright install` should not be needed.

## Artifacts

Failure artifacts are written under:

- `test-results/playwright-artifacts/`
- `test-results/playwright-report/` on CI

Each spec attaches the browser-side event trace JSON so the request id, provider kind, and final pane state remain inspectable after the run.

The live bibliography suite additionally attaches one `*-pane-open-timing.json`
artifact per case with the measured open time, the explicit timeout budget, and
the documented reason for that budget.

It also attaches one `*-pane-open-diagnostic.json` artifact per case. On
success it records the opened-pane path. On a pane-open timeout it records the
last successful UI step, current URL, before/after pane summaries, mutation
samples, and a coarse classification such as `blocked-or-hung-before-pane-create`
or `rendered-into-existing-pane-or-mutated-without-new-pane`.

The current expected Chromium state is:

- content transport test passes
- two-pane content association test passes
- HyperDoc-to-FedWiki association test passes
- help toggle test passes
- main-tab click-safety test passes
- provider-sync round-trip test passes
- source-provider test passes
