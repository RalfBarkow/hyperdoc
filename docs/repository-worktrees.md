# HyperDoc repository and worktree roles

This records which working directory holds which authority. It is a role
document: the roles are durable, the commit hashes quoted anywhere below are
observations at a point in time and are not policy.

## Canonical repository

`/Users/rgb/workspace/hyperdoc` is the canonical checkout. Its `.git` is the
common Git directory that every linked worktree shares, so all worktrees named
here resolve the same objects, refs and reflogs.

## Durable worktrees

| Path | Branch | Role | Access |
|---|---|---|---|
| `/Users/rgb/workspace/hyperdoc` | `workflow` | Active development. Holds the canonical `.git`. | writable |
| `/Users/rgb/workspace/hyperdoc-dreyeck-ch` | `dreyeck.ch` | The deployable branch. Reading pages, catalog and the Dreyeck overlay are verified here. | writable |
| `/Users/rgb/workspace/hyperdoc-hauptsache` | `hauptsache` | Durable reference and comparison worktree for the long-running `hauptsache` line, which diverged from `dreyeck.ch` and carries substantial independent history. | writable, but kept as a reference point |
| `/Users/rgb/workspace/hyperdoc-khinsen-upstream` | `main` | Konrad Hinsen's upstream, as a **separate repository**, not a linked worktree. Read-only observation only: no fetch, checkout, commit or index mutation. | observation-only |

A temporary feature or WIP worktree is legitimate only while it holds unique
unfinished work. Once its work is integrated or archived, the worktree is
removed and its branch is either deleted (when provably identical to an
integrated branch) or retained as provenance.

## Retained refs without a worktree

Some refs are deliberately kept with no working directory:

- `wip/*` — superseded development lines retained as provenance.
- `archive/*` — unique but unfinished material committed verbatim before its
  worktree was closed. Provenance only; not a development line.
- `preserve/*` — exact snapshots of a dirty index or worktree taken before a
  cleanup. Provenance only. Files are recovered with
  `git checkout <preserve-ref> -- <path>`.
- `integrate/*` — named integration checkpoints already contained in
  `dreyeck.ch`.

## Two different things called "hauptsache"

`refs/heads/hauptsache` in this repository and
`/Users/rgb/workspace/hauptsache` are unrelated. The first is a HyperDoc
branch whose durable worktree is `/Users/rgb/workspace/hyperdoc-hauptsache`.
The second is a separate standalone repository with its own history and
remotes; nothing in this document governs it.

## Relationship to Konrad upstream

Upstream is observed, never merged. The upstream commits are present in this
repository's object database through the `khinsen` and `upstream` remotes, so
historical observation needs no separate checkout and no network access.

Source adoption, semantic equivalence, patch equivalence and Git ancestry are
four different relations and are kept apart. Adopting upstream source does not
make an upstream commit an ancestor of a local branch. See
`docs/hyperdoc-upstream-boundary.md` and the Upstream Intake reading pages.

## Auxiliary directories

These are not worktrees of this repository:

| Path | What it is |
|---|---|
| `/Users/rgb/workspace/hyperdoc-khinsen-deps` | Plain directory holding reference clones of three upstream dependency repositories. The Nix flake fetches those dependencies itself and builds `CL_SOURCE_REGISTRY` from store paths, so these clones are not load-bearing for any build. |
| `/Users/rgb/workspace/hyperdoc-assets` | Plain, unversioned directory holding the `llm-wiki-paper-hyperdoc` project. It is under no version control at all, so it has no backup other than the filesystem. |
| `/Users/rgb/workspace/hyperdoc-template` | Separate clone of `khinsen/hyperdoc-template`, referenced from `hyperdoc/creating-a-hyperdoc.md` by URL. |
