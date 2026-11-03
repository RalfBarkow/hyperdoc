# Case reading of 58a2b2c: acceptance evidence, 2026-11-03

What was run, and what it shows. Nothing here was deployed, restarted or merged; Konrad Hinsen's checkout was not touched.

| File | What it is |
|---|---|
| `browser/upstream-assessment-browser.json` | the report of `scripts/test-upstream-assessment-browser.mjs` against a served Catalog (no development mode), 127.0.0.1, headless Chromium: ten steps, no browser error, no external request |
| `browser/1-page.png` … `8-commit-narrow.png` | the page, the commit, the upstream change, the fork's definition `initialize-fedwiki`, the ownership judgement, the decision, the change view, the commit at 520 px |
| `tests.txt` | the test systems on the base `afe2dfc0` and on this branch, side by side, and the Nix `catalog` check |
| `mutants.txt` | seven mutants of the new checks, all detected |

The Catalog was started from the working tree as `dreyeck/catalog-application:main` with `HYPERDOC_CATALOG_HOST=127.0.0.1` and an empty site root. That is the code path of the
public Catalog, not `dreyeck.ch` itself: the diagnosis of "Not run here: no operation contract" was reproduced there (the marker is the tooltip of the `▷` before an
example's source; the link above it navigates), and was not observed on the deployed site.

The sandbox could not fetch the ten `github:` inputs of the flake as archives, so the dev shell and the Nix check ran with `--override-input … git+https://github.com/…?rev=<locked rev>`;
`flake.lock` is unchanged.

Reproduce the walk against a running served Catalog:

```bash
node scripts/test-upstream-assessment-browser.mjs PLAYWRIGHT_DIR default OUTPUT_DIR --origin http://127.0.0.1:8099
```
