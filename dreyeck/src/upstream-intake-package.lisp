;;;; Package for read-only observation of upstream references.

(defpackage #:dreyeck/upstream-intake
  (:use #:cl)
  (:export
   #:upstream-reference
   #:upstream-reference-kind-of
   #:upstream-reference-origin-of
   #:upstream-reference-reference-of
   #:upstream-reference-local-context-of
   #:upstream-reference-observations
   #:upstream-local-context
   #:upstream-local-context-repository-of
   #:upstream-local-context-branch-of
   #:upstream-local-context-current-head-of
   #:git-commit-upstream-reference
   #:git-commit-upstream-commit-of
   #:git-commit-upstream-object-present-p
   #:git-commit-upstream-ancestor-of-head-p
   #:git-commit-upstream-merge-base-of
   #:git-commit-upstream-refs-containing-of
   #:git-commit-upstream-classification-of
   #:component-upstream-reference
   #:component-upstream-component-name-of
   #:component-upstream-url-of
   #:component-upstream-local-subject-of
   #:component-upstream-proposed-relation-of
   #:component-upstream-status-of
   #:component-upstream-contracts-of
   #:contract-observation
   #:contract-observation-name-of
   #:contract-observation-status-of
   #:make-contract-observation
   #:make-upstream-commit-intake
   #:make-component-intake
   #:make-hyperdoc-host-not-found-intake
   #:make-hyperspec-component-intake
   #:upstream-reference-summary
   #:hyperdoc-host-not-found-upstream-intake-example
   #:hyperspec-component-upstream-intake-example))
