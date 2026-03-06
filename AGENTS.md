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
4. Commit slicing:
   - commit repair-only journal fixes separately from content/topic updates,
   - keep HyperDoc repo commit(s) separate from localhost FedWiki repo commit(s),
   - do not push unless explicitly requested.

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
