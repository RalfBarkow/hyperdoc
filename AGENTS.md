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
- Use `dev.sh` for local iteration and debugging; use `start.sh` for stricter startup behavior.
- Content updates are often in `hyperdoc/`; runtime behavior typically lives in `hyperbook-server/` and `hyperdoc-explorer/`.
- Treat HyperDoc pages and localhost FedWiki pages as connected communication surfaces. HyperDoc pages can be mirrored or linked to FedWiki counterparts in `/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages` when workflows depend on wiki journaling/editing.
- Apply the two-surface rule when documenting:
  - put durable architecture/reference content in HyperDoc pages,
  - keep fast-moving collaborative trail in localhost FedWiki pages,
  - maintain navigable links/counterparts per topic instead of forcing identical content in both places.

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
  - `:references` (HyperDoc pages and/or URLs).
- HyperDoc pages should expose these via `expr="(hyperdoc::...-topic)"` in an `Inspectable objects` section.

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
