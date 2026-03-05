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
- `inspector-hyperdoc/`: inspector-facing HyperDoc views/docs
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
