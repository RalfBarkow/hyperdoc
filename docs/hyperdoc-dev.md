# `hyperdoc-dev`: orientation, review, tests and checks in `nix develop`

`nix develop` (the default shell) puts `hyperdoc-dev` on `PATH`. It is one thin script, `scripts/hyperdoc-dev.sh`, packaged in
`flake.nix`. It keeps no list of tests, books, branches or commits and does not reimplement any test flow: `test` is
`asdf:test-system`, `check` is `nix build`, `review` is read-only Git.

## Greeting

In an interactive `nix develop` the shell prints repository, worktree, branch, short commit and a pointer to
`hyperdoc-dev help`. It reads local Git state only: no network, no tests, no server. It is not printed for
`nix develop --command …`, scripts or pipes (the hook checks for an interactive shell on a terminal).

## Commands

| Command | Kind | What it does |
|---|---|---|
| `hyperdoc-dev help` | read-only | The commands, what each changes, and the external prerequisites of some tests. |
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
