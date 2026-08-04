#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"

cd "$repo_root"

export HYPERDOC_REPO_ROOT="$repo_root"

printf 'Repository: %s\n' "$repo_root"
printf 'Branch:     %s\n' "$(git branch --show-current)"
printf 'Commit:     %s\n' "$(git rev-parse --short=12 HEAD)"
printf '\nStarting Emacs, SLY, and a fresh SBCL image...\n'

exec emacs -Q \
  --eval '
    (progn
      (require (quote sly))

      (setq default-directory
            (file-name-as-directory
             (getenv "HYPERDOC_REPO_ROOT")))

      ;; Never reuse an unrelated existing SLY connection.
      (setq sly-command-switch-to-existing-lisp
            (quote never))

      ;; SLY starts SBCL, loads Slynk, connects, and opens the mREPL.
      (sly
       (quote
        ("sbcl"
         "--dynamic-space-size" "8192"
         "--noinform"
         "--no-userinit"))
       (quote utf-8-unix)))'