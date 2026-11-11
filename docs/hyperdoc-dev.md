# `hyperdoc-dev`: orientation, review, tests and checks in `nix develop`

`nix develop` (the default shell) puts `hyperdoc-dev` on `PATH`. It is one thin script, `scripts/hyperdoc-dev.sh`, packaged in
`flake.nix`. It keeps no list of tests, books, branches or commits and does not reimplement any test flow: `test` is
`asdf:test-system`, `check` is `nix build`, `review` is read-only Git.

## Before implementation: task location

Run `hyperdoc-dev task-location` to read [Task location before problem determination](task-location-before-problem.md). This applies the existing `problem-bestimmen` distinction (Zettel 6129 / Simon 48.2): a task is a *problem* only if existing routines of behavior, action or interaction cannot solve it. Locate tasks in the existing learned task space (Zettel 8992) before inventing an implementation, changing the store, or opening a development assignment.

The command deliberately **does not** run SHOP3, perform repository search, declare a problem, create a database, or change the worktree. For a bounded case, identify the task, inspect candidate routines and their contracts, then use an existing SHOP3 domain only if its task and preconditions fit. Preserve native alternatives and `:plan-only` status; a missing domain is not evidence of a missing routine.

Zettel 11605 illustrates this with Ward's `making-the-welcome-page` link: S1 successfully acquired the source, existing local-only code can observe and plan a link in a file-backed own-site, but **no destination wiki has yet been chosen**. ASDF reports `sqlite` and `dbi` available in the operator's image; this does not establish a SQLite-backed local page store. The [Work HyperDoc reading](../dreyeck/pages/work/Task%20Location%20Before%20S2%20Storage%20Selection.html) exposes that distinction alongside the existing source-backed Local-only and SHOP3 readings. It is documentation, not an accepted new S2 implementation.

## Greeting

In an interactive `nix develop` the shell prints repository, worktree, branch, short commit and a pointer to
`hyperdoc-dev help`. It reads local Git state only: no network, no tests, no server. It is not printed for
`nix develop --command …`, scripts or pipes (the hook checks for an interactive shell on a terminal).

## Commands

| Command | Kind | What it does |
|---|---|---|
| `hyperdoc-dev help` | read-only | The commands, what each changes, and the external prerequisites of some tests. |
| `hyperdoc-dev task-location` | read-only | Display the existing `problem-bestimmen` method and source-backed S2 routine lookup. No automatic problem classification, SHOP3 search, file write or new SQLite store. |
| `hyperdoc-dev review [--base REF] [--patch]` | read-only | Base ref and commit, merge base, HEAD, worktree status, files, diff statistics, commit list. `--patch` prints the diff against the merge base. Default base `origin/dreyeck.ch` if that ref exists; otherwise it says so and asks for `--base`. No fetch, checkout or reset. |
| `hyperdoc-dev test SYSTEM` | local artifacts | `(asdf:test-system "SYSTEM")` in a fresh SBCL process. Compiled files go to ASDF's cache; some tests use temporary directories. |
| `hyperdoc-dev check NAME` | Nix store | `nix build .#checks.<this platform>.NAME --no-link -L`. Example: `hyperdoc-dev check catalog`. |
| `hyperdoc-sly` | starts a process | Fresh SBCL with Slynk on `127.0.0.1` and a clean Emacs/SLY (see README). |
| `hyperdoc-catalog --help` | read-only | Usage. Without `--help`, `hyperdoc-catalog` serves the Catalog. |

Other shells (`nix develop .#NAME`): `tala` (plus D2/TALA), `workflow-authoring` (plus the workflow source editor),
`fedwiki-original-editor` (Node and a browser; `fedwiki-original-editor-demo` starts a server,
`fedwiki-original-editor-e2e` writes artifacts).

## Platform

`check` builds for the machine it runs on. A result on `x86_64-linux` is not a result on `aarch64-darwin`. Untracked files are not
part of a Git flake: `git add` them (or `git add -N`) before a check that must see them.

## Tests with external prerequisites

They are explained, not bypassed; the tests fail and say what is missing.

- `dreyeck/lisp-critic/engine-integration/tests` and `dreyeck/lisp-critic/page-station/tests` need the Lisp Critic source station,
  the asset directory of the wiki page `a-critic-for-lisp` (`a-critic-for-lisp.asd`, `vendor/lisp-critic/`):

  ```sh
  DREYECK_LISP_CRITIC_ROOT=/path/to/station/ hyperdoc-dev test dreyeck/lisp-critic/engine-integration/tests
  DREYECK_LISP_CRITIC_ROOT=/path/to/station/ hyperdoc-dev test dreyeck/lisp-critic/page-station/tests
  ```

  Details: `dreyeck/tests/fixtures/lisp-critic/README.md`.
- `dreyeck/nested-actions/reading/tests` checks commits and file contents in local clones whose paths are recorded in
  `dreyeck/nested-actions/sources/revision-provenance.json`. Without them the recorded identities are still checked and the run
  prints `NESTED-ACTIONS-LOCAL-CHECKOUTS-NOT-EXERCISED`. On a machine that has them:

  ```sh
  HYPERDOC_REQUIRE_LOCAL_CHECKOUTS=1 hyperdoc-dev test dreyeck/nested-actions/reading/tests
  ```
