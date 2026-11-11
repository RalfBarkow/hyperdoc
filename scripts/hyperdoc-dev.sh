#!/usr/bin/env bash
# hyperdoc-dev: one self-describing entry point to the commands the nix develop shell already provides.
# It orients, reviews a branch read-only, and starts the existing test and check mechanisms. It holds no list of tests,
# books, branches or commits, and it does not reimplement any test flow: `test` is `asdf:test-system`, `check` is `nix build`.
set -euo pipefail

repo_root() { git rev-parse --show-toplevel 2>/dev/null || { echo "hyperdoc-dev: not inside a Git worktree." >&2; return 1; }; }

nix_system() { nix eval --impure --raw --expr builtins.currentSystem 2>/dev/null; }

have() { command -v "$1" >/dev/null 2>&1; }

availability() { if have "$1"; then echo "available"; else echo "not in this shell"; fi; }

usage_short() { echo "Run 'hyperdoc-dev help' for the commands, what they need and what they change."; }

cmd_greeting() {
  # No network, no tests, no server. Local Git reads only.
  local root branch commit
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 0
  branch="$(git --no-optional-locks branch --show-current 2>/dev/null || true)"
  commit="$(git --no-optional-locks rev-parse --short HEAD 2>/dev/null || echo '?')"
  printf 'HyperDoc development shell\n'
  printf '  repository  %s\n' "$(basename "$root")"
  printf '  worktree    %s\n' "$root"
  printf '  branch      %s\n' "${branch:-(detached HEAD)}"
  printf '  commit      %s\n' "$commit"
  printf "  %s\n" "$(usage_short)"
}

cmd_help() {
  cat <<'EOF'
hyperdoc-dev: commands of this development shell

  Marks:  [read-only]  changes nothing in the worktree and starts nothing
          [artifacts]  writes local build or cache files (named below), no server
          [server]     starts a process that keeps running until you stop it

  hyperdoc-dev help                       [read-only]  this text
  hyperdoc-dev task-location              [read-only]  show the existing problem-bestimmen / task-location
                                          method and the current S2 routine lookup. No SHOP3 execution,
                                          SQLite creation or automatic problem classification.
  hyperdoc-dev review [--base REF] [--patch]
                                          [read-only]  what this worktree changes against REF
                                          (default: origin/dreyeck.ch if that ref exists). Shows base, merge base,
                                          HEAD, worktree status, files, diff statistics and commits. --patch opens the
                                          diff. No fetch, checkout, reset or other change; a missing ref is reported.
  hyperdoc-dev test SYSTEM                [artifacts]  (asdf:test-system "SYSTEM") in a fresh SBCL process.
                                          Compiled files go to ASDF's cache (~/.cache/common-lisp); some tests also use
                                          temporary directories. Examples:  hyperdoc-dev test dreyeck/catalog
  hyperdoc-dev check NAME                 [artifacts]  nix build .#checks.<this platform>.NAME, without a result link.
                                          Writes to the Nix store. Example:  hyperdoc-dev check catalog
                                          The platform is this machine's. A check that passed on x86_64-linux says
                                          nothing about aarch64-darwin, and the other way round.

Other commands in this shell (availability in this shell is stated):
EOF
  printf '  %-34s %s\n' "hyperdoc-sly" "[server]     fresh SBCL with Slynk on 127.0.0.1 and a clean Emacs/SLY client ($(availability hyperdoc-sly))"
  printf '  %-34s %s\n' "hyperdoc-catalog --help" "[read-only]  usage of the Catalog executable ($(availability hyperdoc-catalog))"
  printf '  %-34s %s\n' "hyperdoc-catalog" "[server]     serves the Catalog; without --help it starts"
  cat <<'EOF'

Alternative shells (enter with  nix develop .#NAME  from the repository root):
  tala                       the default shell plus D2/TALA, for the layout-dependent examples
  workflow-authoring         the default shell plus the workflow source editor, for authoring systems
  fedwiki-original-editor    Node and a browser for the Original Wiki Editor demonstration. Its commands
                             fedwiki-original-editor-demo [server] and fedwiki-original-editor-e2e [artifacts]
                             are only available there.

Tests that need something outside the repository. The tests say what is missing and fail; they do not skip.
  dreyeck/lisp-critic/engine-integration/tests, dreyeck/lisp-critic/page-station/tests
      need a Lisp Critic source station: the asset directory of the wiki page a-critic-for-lisp
      (a-critic-for-lisp.asd and vendor/lisp-critic/). Set DREYECK_LISP_CRITIC_ROOT=<that directory>/
      Without it they fail with ENGINE-INTEGRATION-REQUIRES-A-SOURCE-STATION.
      See dreyeck/tests/fixtures/lisp-critic/README.md.
  dreyeck/nested-actions/reading/tests
      checks commits and file contents in the author's local clones (paths recorded in
      dreyeck/nested-actions/sources/revision-provenance.json). Without the clones the recorded
      identities are still checked and the run says what was not exercised. On a machine that has
      the clones set HYPERDOC_REQUIRE_LOCAL_CHECKOUTS=1 to make their absence a failure.

Examples:
  HYPERDOC_REQUIRE_LOCAL_CHECKOUTS=1 hyperdoc-dev test dreyeck/nested-actions/reading/tests
  DREYECK_LISP_CRITIC_ROOT=/path/to/station/ hyperdoc-dev test dreyeck/lisp-critic/engine-integration/tests

Documentation: README.md (Fresh interactive Lisp image, Catalog), dreyeck/CATALOG-OPERATIONS.md, docs/hyperdoc-dev.md,
               docs/task-location-before-problem.md
EOF
}

cmd_task_location() {
  [ $# -eq 0 ] || { echo "hyperdoc-dev task-location: no arguments; this only reads the method note." >&2; return 2; }
  local root; root="$(repo_root)"
  cat "$root/docs/task-location-before-problem.md"
}

cmd_review() {
  local base="" patch=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --base) [ $# -ge 2 ] || { echo "hyperdoc-dev review: --base needs a ref." >&2; return 2; }; base="$2"; shift 2 ;;
      --base=*) base="${1#--base=}"; shift ;;
      --patch) patch=1; shift ;;
      -h|--help) cmd_help; return 0 ;;
      *) echo "hyperdoc-dev review: unknown argument '$1'. Use: review [--base REF] [--patch]" >&2; return 2 ;;
    esac
  done
  local root; root="$(repo_root)"; cd "$root"
  if [ -z "$base" ]; then
    if git rev-parse --verify --quiet "refs/remotes/origin/dreyeck.ch^{commit}" >/dev/null; then
      base="origin/dreyeck.ch"
    else
      echo "hyperdoc-dev review: the default base origin/dreyeck.ch does not exist in this clone." >&2
      echo "  Nothing was fetched. Name a ref you have:  hyperdoc-dev review --base REF" >&2
      echo "  Local refs:  git branch -a" >&2
      return 1
    fi
  fi
  local base_commit merge_base
  if ! base_commit="$(git rev-parse --verify --quiet "${base}^{commit}")"; then
    echo "hyperdoc-dev review: '$base' is not a commit in this clone. Nothing was fetched." >&2
    echo "  If it exists on the remote:  git fetch origin   (a change to your clone, so it is yours to run)" >&2
    return 1
  fi
  if ! merge_base="$(git merge-base "$base_commit" HEAD 2>/dev/null)"; then
    echo "hyperdoc-dev review: '$base' and HEAD have no common ancestor in this clone (shallow clone?)." >&2
    return 1
  fi
  # Every Git call below is read-only; --no-optional-locks keeps `status` from refreshing the index.
  local git_ro=(git --no-optional-locks)
  if [ "$patch" = 1 ]; then
    "${git_ro[@]}" diff "$merge_base"
    return 0
  fi
  printf 'Base ref     %s\n' "$base"
  printf 'Base commit  %s\n' "$("${git_ro[@]}" log -1 --format='%h %s' "$base_commit")"
  printf 'Merge base   %s\n' "$("${git_ro[@]}" log -1 --format='%h %s' "$merge_base")"
  printf 'HEAD         %s (%s)\n' "$("${git_ro[@]}" log -1 --format='%h %s' HEAD)" "$("${git_ro[@]}" branch --show-current || true)"
  printf '\nWorktree status (uncommitted changes, if any):\n'
  local status; status="$("${git_ro[@]}" status --short)"
  if [ -n "$status" ]; then printf '%s\n' "$status" | sed 's/^/  /'; else echo "  clean"; fi
  printf '\nFiles changed since the merge base (committed and uncommitted, tracked files):\n'
  "${git_ro[@]}" diff --name-status "$merge_base" | sed 's/^/  /'
  printf '\nDiff statistics:\n'
  "${git_ro[@]}" diff --stat "$merge_base" | sed 's/^/  /'
  printf '\nCommits on HEAD not in %s:\n' "$base"
  "${git_ro[@]}" log --format='  %h %s' "$base_commit..HEAD"
  printf '\nThe diff itself:  hyperdoc-dev review --base %s --patch\n' "$base"
}

prerequisite_note() {
  case "$1" in
    dreyeck/lisp-critic/engine-integration/tests|dreyeck/lisp-critic/page-station/tests)
      if [ -z "${DREYECK_LISP_CRITIC_ROOT:-}" ]; then
        echo "note: $1 needs a Lisp Critic source station and DREYECK_LISP_CRITIC_ROOT is not set." >&2
        echo "      The test will search the configured wiki site and then fail, not skip. See: hyperdoc-dev help" >&2
      fi ;;
    dreyeck/nested-actions/reading/tests)
      if [ -z "${HYPERDOC_REQUIRE_LOCAL_CHECKOUTS:-}" ]; then
        echo "note: HYPERDOC_REQUIRE_LOCAL_CHECKOUTS is not set: missing local clones will be reported but will not fail this run." >&2
      fi ;;
  esac
}

cmd_test() {
  [ $# -eq 1 ] || { echo "hyperdoc-dev test: give exactly one ASDF system name, e.g.  hyperdoc-dev test dreyeck/catalog" >&2; return 2; }
  local system="$1"
  case "$system" in
    ""|*[!A-Za-z0-9/._+-]*) echo "hyperdoc-dev test: '$system' is not a plausible ASDF system name." >&2; return 2 ;;
  esac
  have sbcl || { echo "hyperdoc-dev test: sbcl is not on PATH. Run this inside 'nix develop'." >&2; return 1; }
  local root; root="$(repo_root)"
  # This worktree must be on the source registry, or ASDF would test another checkout's systems.
  case "${CL_SOURCE_REGISTRY:-}" in
    *"$root//"*|*"$root/"*) ;;
    *) export CL_SOURCE_REGISTRY="$root//${CL_SOURCE_REGISTRY:+:$CL_SOURCE_REGISTRY}" ;;
  esac
  prerequisite_note "$system"
  # The name travels in the environment, never inside Lisp source text.
  HYPERDOC_DEV_SYSTEM="$system" exec sbcl --noinform --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(let ((name (uiop:getenv "HYPERDOC_DEV_SYSTEM")))
              (unless (asdf:find-system name nil)
                (format *error-output* "~&hyperdoc-dev test: ASDF does not know the system ~A.~%  Registry: ~A~%  List: (asdf:registered-systems) after loading dreyeck.asd.~%" name (uiop:getenv "CL_SOURCE_REGISTRY"))
                (uiop:quit 2))
              (asdf:test-system name))' \
    --eval '(uiop:quit 0)'
}

cmd_check() {
  [ $# -eq 1 ] || { echo "hyperdoc-dev check: give one check name, e.g.  hyperdoc-dev check catalog" >&2; return 2; }
  local name="$1"
  case "$name" in
    ""|*[!A-Za-z0-9._-]*) echo "hyperdoc-dev check: '$name' is not a plausible check name." >&2; return 2 ;;
  esac
  have nix || { echo "hyperdoc-dev check: nix is not on PATH." >&2; return 1; }
  local root system; root="$(repo_root)"
  system="$(nix_system)" || true
  [ -n "$system" ] || { echo "hyperdoc-dev check: could not determine this platform's Nix system." >&2; return 1; }
  echo "Building checks.$system.$name (Nix store only, no result link). This is the check for $system;"
  echo "a result for another platform (for example macOS against Linux) is not a result for this one."
  exec nix build "$root#checks.$system.$name" --no-link -L
}

main() {
  local command="${1:-help}"
  [ $# -gt 0 ] && shift
  case "$command" in
    help|-h|--help) cmd_help ;;
    greeting) cmd_greeting ;;
    review) cmd_review "$@" ;;
    task-location) cmd_task_location "$@" ;;
    test) cmd_test "$@" ;;
    check) cmd_check "$@" ;;
    *) echo "hyperdoc-dev: unknown command '$command'." >&2; usage_short >&2; return 2 ;;
  esac
}

main "$@"
