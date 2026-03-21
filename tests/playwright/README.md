# Playwright DOM Association Findings

The reusable pane-chrome regression harness for the current provider-based
Connect UI lives in:

- `tests/playwright/pane-chrome-harness.js`

It protects these invariants for future Connect/provider slices:

- main tabs stay clickable while Connect chrome is present
- the subordinate Connect row does not steal neighboring hit targets
- `?` opens a help panel attached to the Connect row without shifting the active view
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
- `pane-chrome help opens without shifting the active view`
  - proves the `?` help toggle opens in the subordinate pane-chrome Connect row
  - asserts the help panel does not move the active view or change document height
- `main tabs stay clickable while Connect help is open`
  - proves normal pane navigation still works while the Connect chrome is visible
  - exercises representative stable tabs through the reusable harness
- `provider-surface sync settles across a Pages round trip`
  - proves Connect availability follows the active view across a connectable/non-connectable switch
  - guards the resync timing boundary that previously left pane chrome in a stale state
- `source view exposes source anchors and opens an association`
  - expresses the intended `source-v1` provider behavior on the `Creating a HyperDoc` page
  - is currently marked `test.fail()` on all browsers because the remaining automation boundary is still reaching a text page and its `Source` provider reliably

## Run

If no server is already running, the Playwright config starts one locally on `http://127.0.0.1:18080/boot.html` via `nix run .`.

```sh
node_modules/.bin/playwright test -c tests/playwright/playwright.config.js
```

To reuse an existing local server instead:

```sh
HYPERDOC_BASE_URL=http://127.0.0.1:56719/boot.html \
  node_modules/.bin/playwright test -c tests/playwright/playwright.config.js
```

## Artifacts

Failure artifacts are written under:

- `test-results/playwright-artifacts/`
- `test-results/playwright-report/` on CI

Each spec attaches the browser-side event trace JSON so the request id, provider kind, and final pane state remain inspectable after the run.

The current expected Chromium state is:

- content transport test passes
- two-pane content association test passes
- HyperDoc-to-FedWiki association test passes
- help toggle test passes
- main-tab click-safety test passes
- provider-sync round-trip test passes
- source-provider test is an expected failure that documents the remaining boundary
