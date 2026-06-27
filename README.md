# HyperDoc

Hypertext documentation system based on [html-inspector-views](https://codeberg.org/khinsen/html-inspector-views).

## Running a Web server for the HyperDoc catalog

The basic command for SBCL is:
```
sbcl --no-userinit \
     --eval '(require :asdf)' \
     --eval '(asdf:load-system "hyperdoc/server")' \
     --eval '(hyperbook/server:serve-catalog)'
```

This will serve a catalog containing a single HyperDoc, the one for HyperDoc itself, with explorer methods loaded for navigation.

## Docs Topic Coverage Gate

To validate `expr="(hyperdoc::...)"` references for the SD-image docs cluster:

```
nix develop --command sbcl --no-userinit --non-interactive \
  --load tools/check-topic-coverage.lisp
```

To check an explicit set of pages instead of the default cluster:

```
nix develop --command sbcl --no-userinit --non-interactive \
  --load tools/check-topic-coverage.lisp -- hyperdoc/page-a.html hyperdoc/page-b.html
```

When explicit page paths are provided, only those pages are checked.

## Semantic-first Anchor Audit

To guard the current semantic-first anchor model against wording and rendering
drift:

```sh
./tools/semantic-first-anchor-audit.sh
```

The audit is source-based and checks:

- semantic identity vs presentation fallback separation in the anchor model
- provider/help copy for stale DOM-first phrasing
- inspector rendering for separate semantic, fallback, and durability surfaces

The source of truth for this audit now lives in HyperDoc Lisp via
`hyperdoc:semantic-first-anchor-audit-report`. The documentation-slice helper
includes it as a named validation sub-check, so it is part of the normal repo
validation flow for that entrypoint. The broader repo-level
`hyperdoc:run-ci-checks` path includes a first-class documentation-slice
validation check, and that check now reports the semantic-first anchor audit
explicitly through the same HyperDoc-owned validation report.

## Repomix Context Packs

Repomix snapshots are subsystem-scoped by default. Use the smallest pack that
matches the task; reserve `full` for intentional whole-project reviews.

| Task | Pack |
| --- | --- |
| Project orientation | `core` |
| Dock, Connect, mobile route-first UI | `dock` |
| ASDF, test runner, smoke load blockers | `validation` |
| FedWiki story/materialization/promotion | `fedwiki` |
| DMX annotation/import/workspace work | `dmx` |
| dreyeck, Nix, release, deployment | `deployment` |
| DM6 Elm/app embedding | `dm6` |
| Zotero and topic enrichment | `zotero` |
| Whole-repo review | `full` |

Generate a pack with:

```sh
tools/repomix-pack.sh dock
```

or explicitly:

```sh
repomix -c repomix.config.dock.json
```

Inside the project development shell, the same runner can be invoked as:

```sh
nix develop --command tools/repomix-pack.sh dock
```

The runner uses `repomix` from `PATH` first. If it is missing and `nix` is
available, it falls back to `nix run nixpkgs#repomix`; set
`HYPERDOC_REPOMIX_DISABLE_NIX_FALLBACK=1` to disable that fallback.

Do not attach the `full` pack for Dock, validation, FedWiki, deployment, DM6,
DMX, or Zotero slices unless cross-subsystem context is actually needed. Generated
`repomix-output*.md` and `repomix-output*.xml` files are ignored and should not be
committed as handoff artifacts.

## Article Allegation Slice Helper

Use `tools/article-allegation-slice.lisp` to scaffold an article-driven,
allegation-qualified documentation slice from a structured Lisp input file.
The committed example input lives at
`tools/testdata/article-allegation-slice/minab-example.lisp`, and the helper
accepts a compact spec built around `:slice-id`, `:mode`,
`:incident-title`, `:source-label`, `:epistemic-status`, `:summary`,
`:incident-sections`, concept `:topic-handle`s, and `:anchor-date`. You can
audit the derived titles, topic handles, FedWiki slugs, and daily-anchor
target before writing anything:

```sh
nix develop --command sbcl --script tools/article-allegation-slice.lisp \
  --input tools/testdata/article-allegation-slice/minab-example.lisp \
  --print-plan
```

Then refresh a deterministic dry-run bundle like this:

```sh
nix develop --command sbcl --script tools/article-allegation-slice.lisp \
  --input tools/testdata/article-allegation-slice/minab-example.lisp \
  --dry-run-dir tools/testdata/article-allegation-slice/minab-dry-run
```

Live writes stay branch- and repo-aware:

- HyperDoc pages, topic object code under `hyperdoc/topics/`, and helper code belong in the `hyperdoc` repo on branch `hauptsache`; production project topic persistence belongs to the Dreyeck/DMX SQLite database.
- FedWiki twins and daily-anchor updates belong in `/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages` on branch `localhost`.
- The helper checks those branch expectations before `--write-live` touches real files.

Epistemic safeguards are built into the scaffolder rather than left to ad hoc prose:

- article-derived incident claims default to reported/alleged/disputed language;
- responsibility is not flattened into settled fact unless the input explicitly marks stronger verification;
- legal conclusions stay qualified unless verified legal attribution is explicitly supplied;
- AI wording stays at the level of decision support, review acceleration, automation-bias risk, and human responsibility.

Validation workflow after generation:

1. Run `asdf:load-system :hyperdoc`.
2. Verify `fboundp` for generated reusable topic constructors.
3. Run `tools/check-topic-coverage.lisp` on the generated HyperDoc pages.
4. Run `python3 -m json.tool` on each changed FedWiki page file.
5. Run `tools/journal-gate.lisp` on the actual changed FedWiki pages only.

The example dry-run output is committed under
`tools/testdata/article-allegation-slice/minab-dry-run/` so the emitted page
shape, topic snippet, FedWiki JSON, and `slice-metadata.lisp` are reviewable
without touching live artifacts. The metadata file records the slice id,
derived page titles, topic handles, FedWiki slugs, and daily-anchor target so
the bundle remains reconstructible as one unit.

## License

[BSD](./LICENSE)

Copyright (c) 2025 Konrad Hinsen

The SVG icons in the directory [assets/hyperdoc/icons](./assets/hyperdoc/icons) are from the [Font Awesome](https://fontawesome.com) collection, and are subject to its [license](https://fontawesome.com/license/free).
