(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (defpackage :hyperdoc/tests
      (:use :cl)))
  (export
   (list (intern "RUN-REFACTOR-HYPERDOC-UPSTREAM-CORE-PLAN-SMOKE-TESTS"
                 :hyperdoc/tests))
   :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun refactor-plan-root ()
  (or (ignore-errors
        (asdf:system-source-directory :hyperdoc))
      #P"/Users/rgb/workspace/hyperdoc/"))

(defun refactor-plan-path (relative)
  (merge-pathnames relative (refactor-plan-root)))

(defun refactor-plan-string (relative)
  (uiop:read-file-string (refactor-plan-path relative)))

(defun refactor-plan-form (relative)
  (with-open-file (stream (refactor-plan-path relative)
                          :direction :input)
    (read stream)))

(defun refactor-plan-assert-search (needle haystack)
  (assert (search needle haystack :test #'char=)
          nil
          "Expected to find ~S." needle))

(defun refactor-plan-assert-not-search (needle haystack)
  (assert (not (search needle haystack :test #'char=))
          nil
          "Expected not to find ~S." needle))

(defun run-refactor-hyperdoc-upstream-core-plan-smoke-tests ()
  (let* ((plan-path
           "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
         (baseline-path
           "hyperdoc/evidence/refactor-hyperdoc-upstream-baseline-0d5bd1b0.sexp")
         (delta-path
           "hyperdoc/evidence/refactor-hyperdoc-local-delta-inventory.sexp")
         (asdf-path
           "hyperdoc/evidence/refactor-hyperdoc-asdf-ownership-inventory.sexp")
         (plan (refactor-plan-form plan-path))
         (baseline (refactor-plan-form baseline-path))
         (delta (refactor-plan-form delta-path))
         (asdf-inventory (refactor-plan-form asdf-path))
         (plan-text (refactor-plan-string plan-path))
         (delta-text (refactor-plan-string delta-path))
         (asdf-text (refactor-plan-string asdf-path)))
    (declare (ignore plan baseline delta asdf-inventory))
    (refactor-plan-assert-search
     "refactor-hyperdoc-to-upstream-core-and-dreyeck-systems"
     plan-text)
    (refactor-plan-assert-search
     "0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc"
     plan-text)
    (refactor-plan-assert-search
     ":do-not-move-files-in-first-slice t"
     plan-text)
    (refactor-plan-assert-search
     ":do-not-delete-files-in-first-slice t"
     plan-text)
    (refactor-plan-assert-search
     ":preserve-hyperdoc-shop3-provider-boundary-repair t"
     plan-text)
    (refactor-plan-assert-search
     ":preserve-hauptsache-kioskbeerli-loader-boundary-repair t"
     plan-text)
    (refactor-plan-assert-search
     "Dreyeck Extraction Plan for upstream main into hauptsache"
     plan-text)
    (refactor-plan-assert-search
     "materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     plan-text)
    (refactor-plan-assert-search
     "(!execute-first-low-risk-dreyeck-extraction-slice)"
     plan-text)
    (refactor-plan-assert-search
     "(:changed-paths-vs-upstream"
     delta-text)
    (refactor-plan-assert-search
     "(:all-deltas-classified-or-manual-review t)"
     delta-text)
    (refactor-plan-assert-search
     "(:dreyeck-owned-situated-surface 57)"
     delta-text)
    (refactor-plan-assert-search
     "(:manual-review 1075)"
     delta-text)
    (refactor-plan-assert-search
     ":hyperdoc/shop3-provider-boundary"
     asdf-text)
    (refactor-plan-assert-search
     ":dreyeck/dmx/sqlite"
     asdf-text)
    (refactor-plan-assert-search
     ":candidate-compatibility-shells"
     asdf-text)
    (refactor-plan-assert-not-search
     "nixos-rebuild switch"
     plan-text)
    (refactor-plan-assert-not-search
     "uiop:run-program"
     plan-text)
    (refactor-plan-assert-not-search
     "sb-ext:run-program"
     plan-text)
    (format t "~&HyperDoc upstream-core refactor plan smoke tests passed.~%")
    t))
