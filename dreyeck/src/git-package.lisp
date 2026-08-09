;;;; Package for Dreyeck's experimental Git inspection objects.

(defpackage #:dreyeck/git
  (:use #:cl)
  (:export
   #:git-repository-checkout
   #:git-repository-root-of
   #:git-repository-root-source-of
   #:git-program-of
   #:make-current-git-repository-checkout
   #:current-git-repository-checkout
   #:git-command-failed
   #:git-command-failed-repository-root-of
   #:git-command-failed-arguments-of
   #:git-command-failed-exit-code-of
   #:git-command-failed-stdout-of
   #:git-command-failed-stderr-of
   #:git-run-string
   #:trim-git-output
   #:git-commit
   #:git-commit-repository-of
   #:git-commit-ish-of
   #:git-commit-hash-of
   #:make-git-commit
   #:current-head-git-commit
   #:git-commit-one-line
   #:git-commit-metadata
   #:git-commit-stat
   #:git-commit-patch
   #:git-commit-changed-files
   #:git-file-at-commit
   #:git-file-commit-of
   #:git-file-path-of
   #:git-commit-file-change
   #:git-commit-file-change-commit-of
   #:git-commit-file-change-status-of
   #:git-commit-file-change-path-of
   #:git-commit-file-change-old-path-of
   #:git-commit-file-changes
   #:git-commit-file-change-file
   #:git-file-blob-spec
   #:git-file-contents))
