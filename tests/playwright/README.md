# Playwright DOM Association Findings

This suite materializes the current DOM association findings as browser tests:

- `content view opens an association through pane-chrome Connect`
  - proves the working `dom-v1` provider path
  - asserts the authoritative transport is `button-payload-v1`
- `pane-chrome help opens without shifting the active view`
  - proves the `?` help toggle opens in pane chrome
  - asserts the help panel does not move the active view or change document height
- `Pages tab stays clickable while Connect help is open`
  - proves normal pane navigation still works while the Connect chrome is visible
  - asserts the non-connectable `Pages` view can still be activated even with help open
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
- help toggle test passes
- Pages tab regression test passes
- source-provider test is an expected failure that documents the remaining boundary
