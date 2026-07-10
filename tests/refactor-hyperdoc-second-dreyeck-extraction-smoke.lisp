(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (defpackage :hyperdoc/tests
      (:use :cl)))
  (export
   (list (intern "RUN-REFACTOR-HYPERDOC-SECOND-DREYECK-EXTRACTION-SMOKE-TESTS"
                 :hyperdoc/tests))
   :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun second-dreyeck-extraction-root ()
  (or (ignore-errors
        (asdf:system-source-directory :hyperdoc))
      #P"/Users/rgb/workspace/hyperdoc/"))

(defun second-dreyeck-extraction-path (relative)
  (merge-pathnames relative (second-dreyeck-extraction-root)))

(defun second-dreyeck-extraction-string (relative)
  (uiop:read-file-string (second-dreyeck-extraction-path relative)))

(defun second-dreyeck-extraction-form (relative)
  (with-open-file (stream (second-dreyeck-extraction-path relative)
                          :direction :input)
    (read stream)))

(defun second-dreyeck-extraction-assert-present (relative)
  (assert (probe-file (second-dreyeck-extraction-path relative))
          nil
          "Expected file to exist: ~A" relative))

(defun second-dreyeck-extraction-assert-absent (relative)
  (assert (not (probe-file (second-dreyeck-extraction-path relative)))
          nil
          "Expected file to be absent: ~A" relative))

(defun second-dreyeck-extraction-assert-search (needle haystack)
  (assert (search needle haystack :test #'char=)
          nil
          "Expected to find ~S." needle))

(defun second-dreyeck-extraction-assert-not-search (needle haystack)
  (assert (not (search needle haystack :test #'char=))
          nil
          "Expected not to find ~S." needle))

(defun run-refactor-hyperdoc-second-dreyeck-extraction-smoke-tests ()
  (let* ((old-plan
           (concatenate 'string
                        "hyperdoc/"
                        "materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"))
         (new-plan
           "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")
         (result
           "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-result.sexp")
         (durable-notes
           "dreyeck/dmx/sqlite/durable-notes.lisp")
         (competition-plan
           "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp")
         (operation-plan
           "hyperdoc/materialize-and-verify-operation-documentation-topics-shop3-plan.sexp")
         (new-plan-text (second-dreyeck-extraction-string new-plan))
         (result-text (second-dreyeck-extraction-string result))
         (durable-notes-text (second-dreyeck-extraction-string durable-notes))
         (competition-plan-text (second-dreyeck-extraction-string competition-plan))
         (operation-plan-text (second-dreyeck-extraction-string operation-plan)))
    (second-dreyeck-extraction-form new-plan)
    (second-dreyeck-extraction-form result)
    (second-dreyeck-extraction-assert-present new-plan)
    (second-dreyeck-extraction-assert-absent old-plan)
    (dolist (text (list new-plan-text
                        durable-notes-text
                        competition-plan-text
                        operation-plan-text))
      (second-dreyeck-extraction-assert-search new-plan text)
      (second-dreyeck-extraction-assert-not-search old-plan text))
    (second-dreyeck-extraction-assert-search
     "(:compatibility-shells nil)"
     result-text)
    (second-dreyeck-extraction-assert-search
     "(:asdf-updates nil)"
     result-text)
    (second-dreyeck-extraction-assert-not-search
     "uiop:run-program"
     result-text)
    (second-dreyeck-extraction-assert-not-search
     "sb-ext:run-program"
     result-text)
    (format t "~&Second Dreyeck extraction smoke tests passed.~%")
    t))
