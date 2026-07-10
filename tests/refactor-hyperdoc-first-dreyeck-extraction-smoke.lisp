(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (defpackage :hyperdoc/tests
      (:use :cl)))
  (export
   (list (intern "RUN-REFACTOR-HYPERDOC-FIRST-DREYECK-EXTRACTION-SMOKE-TESTS"
                 :hyperdoc/tests))
   :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun first-dreyeck-extraction-root ()
  (or (ignore-errors
        (asdf:system-source-directory :hyperdoc))
      #P"/Users/rgb/workspace/hyperdoc/"))

(defun first-dreyeck-extraction-path (relative)
  (merge-pathnames relative (first-dreyeck-extraction-root)))

(defun first-dreyeck-extraction-string (relative)
  (uiop:read-file-string (first-dreyeck-extraction-path relative)))

(defun first-dreyeck-extraction-form (relative)
  (with-open-file (stream (first-dreyeck-extraction-path relative)
                          :direction :input)
    (read stream)))

(defun first-dreyeck-extraction-assert-present (relative)
  (assert (probe-file (first-dreyeck-extraction-path relative))
          nil
          "Expected file to exist: ~A" relative))

(defun first-dreyeck-extraction-assert-absent (relative)
  (assert (not (probe-file (first-dreyeck-extraction-path relative)))
          nil
          "Expected file to be absent: ~A" relative))

(defun first-dreyeck-extraction-assert-search (needle haystack)
  (assert (search needle haystack :test #'char=)
          nil
          "Expected to find ~S." needle))

(defun first-dreyeck-extraction-assert-not-search (needle haystack)
  (assert (not (search needle haystack :test #'char=))
          nil
          "Expected not to find ~S." needle))

(defun run-refactor-hyperdoc-first-dreyeck-extraction-smoke-tests ()
  (let* ((selection
           "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-selection.sexp")
         (result
           "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-result.sexp")
         (htn
           "dreyeck/codex/contact-db/contact-db-codex-next-htn.sexp")
         (shop3
           "dreyeck/codex/contact-db/contact-db-codex-next-shop3-plan.sexp")
         (prompt
           "dreyeck/codex/contact-db/contact-db-codex-next-prompt.md")
         (selection-text (first-dreyeck-extraction-string selection))
         (result-text (first-dreyeck-extraction-string result))
         (htn-text (first-dreyeck-extraction-string htn)))
    (first-dreyeck-extraction-form selection)
    (first-dreyeck-extraction-form result)
    (first-dreyeck-extraction-form htn)
    (first-dreyeck-extraction-form shop3)
    (first-dreyeck-extraction-assert-present htn)
    (first-dreyeck-extraction-assert-present shop3)
    (first-dreyeck-extraction-assert-present prompt)
    (first-dreyeck-extraction-assert-absent
     "hyperdoc/contact-db-codex-next-htn.sexp")
    (first-dreyeck-extraction-assert-absent
     "hyperdoc/contact-db-codex-next-shop3-plan.sexp")
    (first-dreyeck-extraction-assert-absent
     "hyperdoc/contact-db-codex-next-prompt.md")
    (first-dreyeck-extraction-assert-search
     "(:target-system :dreyeck/codex)"
     selection-text)
    (first-dreyeck-extraction-assert-search
     "(:compatibility-required-p nil)"
     selection-text)
    (first-dreyeck-extraction-assert-search
     "(:asdf-updates nil)"
     result-text)
    (first-dreyeck-extraction-assert-search
     "dreyeck/codex/contact-db/contact-db-codex-next-prompt.md"
     htn-text)
    (first-dreyeck-extraction-assert-not-search
     "hyperdoc/contact-db-codex-next-prompt.md"
     htn-text)
    (first-dreyeck-extraction-assert-not-search
     "uiop:run-program"
     result-text)
    (first-dreyeck-extraction-assert-not-search
     "sb-ext:run-program"
     result-text)
    (format t "~&First Dreyeck extraction smoke tests passed.~%")
    t))
