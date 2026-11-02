;;;; Package for the code ownership inventory of the library paths: which definitions of upstream's library the fork has changed, added or removed,
;;;; since when, why, who owns them, and where they should go.

(defpackage #:dreyeck/code-ownership
  (:use #:cl)
  (:local-nicknames (#:ua #:dreyeck/upstream-assessment) (#:g #:dreyeck/git))
  (:export #:+library-paths+ #:library-files-at #:current-library-files #:build-manifest #:manifest-form #:read-manifest #:write-manifest
           #:manifest-reference #:manifest-files #:current-deviations #:deviation-path #:deviation-key #:deviation-kind
           #:deviation-upstream-digest #:deviation-current-digest #:deviation-origin #:read-inventory #:write-inventory #:inventory-entries
           #:check-library-inventory #:inventory-report #:inventory-report-problems #:inventory-report-lines #:inventory-report-counts
           #:inventory-report-ok-p #:inventory-report-clean-p #:print-inventory-report #:definition-at-path #:blob-definitions))
