;;;; Focused smoke tests for live Mech deployment provenance materialization
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-MECH-DEPLOYMENT-PROVENANCE-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun mech-provenance-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun mech-provenance-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun mech-provenance-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun read-mech-provenance-page (namestring)
  (uiop:read-file-string
   (asdf:system-relative-pathname :hyperdoc namestring)))

(defun mech-provenance-page-pathname (namestring)
  (asdf:system-relative-pathname :hyperdoc namestring))

(defun normalize-mech-provenance-whitespace (string)
  (with-output-to-string (stream)
    (loop with pending-space = nil
          with wrote-char = nil
          for char across string
          do (if (find char '(#\Space #\Tab #\Newline #\Return))
                 (setf pending-space t)
                 (progn
                   (when pending-space
                     (when wrote-char
                       (write-char #\Space stream))
                     (setf pending-space nil))
                   (write-char char stream)
                   (setf wrote-char t))))))

(defun mech-provenance-page-contains-all-p (page-source needles)
  (let ((normalized (normalize-mech-provenance-whitespace page-source)))
    (every (lambda (needle)
             (search (normalize-mech-provenance-whitespace needle)
                     normalized
                     :test #'char=))
           needles)))

(defun run-mech-provenance-topic-factory-smoke-test ()
  (dolist (spec '((hyperdoc::live-mech-deployment-provenance-topic
                   . "Live Mech deployment provenance")
                  (hyperdoc::host-by-host-live-runtime-comparison-topic
                   . "Host-by-host live runtime comparison")
                  (hyperdoc::patched-mech-discourse-graphs-block-vocabulary-topic
                   . "Patched Mech / Discourse-Graphs block vocabulary")))
    (let ((symbol (car spec))
          (title (cdr spec)))
      (mech-provenance-assert-true
       (fboundp symbol)
       (format nil "Missing topic factory ~A" symbol))
      (mech-provenance-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Missing Topics HyperBook page ~A" title)))))

(defun run-mech-provenance-page-smoke-test ()
  (let* ((page-namestring
           "hyperdoc/FedWiki Graphviz story item render trace.html")
         (page-pathname (mech-provenance-page-pathname page-namestring))
         (page-source (read-mech-provenance-page page-namestring)))
    (mech-provenance-assert-true
     (probe-file page-pathname)
     "FedWiki Graphviz story item render trace page must exist.")
    (mech-provenance-assert-true
     (mech-provenance-page-contains-all-p
      page-source
      '("Live Mech deployment provenance"
        "Host-by-host live runtime comparison"
        "Patched Mech / Discourse-Graphs block vocabulary"
        "(make-live-mech-deployment-provenance-skill)"
        "(make-live-mech-plugin-provenance-check)"))
     "Canonical page must expose the provenance topics and inspectable objects.")))

(defun run-live-mech-deployment-provenance-skill-smoke-test ()
  (let ((skill (hyperdoc::make-live-mech-deployment-provenance-skill)))
    (mech-provenance-assert-typep
     'hyperdoc::live-plugin-provenance-skill
     skill
     "Skill factory must materialize a live-plugin-provenance-skill.")
    (mech-provenance-assert-equal
     '(:upstream :patched :proxied :unresolved)
     (hyperdoc::live-plugin-provenance-skill-classification-outcomes-of skill)
     "Skill must preserve the four provenance classification outcomes.")
    (mech-provenance-assert-equal
     'hyperdoc::make-live-mech-plugin-provenance-check
     (hyperdoc::live-plugin-provenance-skill-operation-factory-of skill)
     "Skill must point to the read-only provenance-check operation factory.")
    (mech-provenance-assert-equal
     "FedWiki Graphviz story item render trace"
     (hyperdoc::live-plugin-provenance-skill-canonical-page-of skill)
     "Skill must keep the canonical page anchor.")))

(defun run-live-mech-plugin-provenance-check-smoke-test ()
  (let* ((operation (hyperdoc::make-live-mech-plugin-provenance-check))
         (reports (hyperdoc::live-mech-plugin-provenance-check-reports-of
                   operation))
         (classifications
           (hyperdoc::mech-plugin-provenance-check-host-classifications
            operation))
         (discourse-report
           (find "discourse.dreyeck.ch"
                 reports
                 :key #'hyperdoc::mech-host-runtime-provenance-host-of
                 :test #'string=))
         (wiki-report
           (find "wiki.ralfbarkow.ch"
                 reports
                 :key #'hyperdoc::mech-host-runtime-provenance-host-of
                 :test #'string=)))
    (mech-provenance-assert-typep
     'hyperdoc::live-mech-plugin-provenance-check
     operation
     "Operation factory must materialize a live-mech-plugin-provenance-check.")
    (mech-provenance-assert-true
     (hyperdoc::live-mech-plugin-provenance-check-read-only-p-of operation)
     "Live Mech provenance check must remain read-only.")
    (mech-provenance-assert-equal
     hyperdoc::*upstream-mech-reference-commit*
     (hyperdoc::live-mech-plugin-provenance-check-upstream-reference-commit-of
      operation)
     "Operation must preserve the upstream reference commit.")
    (mech-provenance-assert-equal
     :patched
     (cdr (assoc "discourse.dreyeck.ch" classifications :test #'string=))
     "Discourse host must be classified as patched.")
    (mech-provenance-assert-equal
     :patched
     (cdr (assoc "wiki.ralfbarkow.ch" classifications :test #'string=))
     "Wiki host must be classified as patched.")
    (mech-provenance-assert-equal
     "abd88d2da6c89029515f2a456356832dffe038ab"
     (hyperdoc::mech-host-runtime-provenance-build-commit-of discourse-report)
     "Discourse host must preserve the exact proved build commit.")
    (mech-provenance-assert-true
     (null (hyperdoc::mech-host-runtime-provenance-build-commit-of wiki-report))
     "Wiki host must remain unresolved at the exact-commit level.")
    (mech-provenance-assert-true
     (hyperdoc::patched-mech-block-vocabulary-present-p
      (hyperdoc::mech-host-runtime-provenance-served-vocabulary-of
       discourse-report))
     "Discourse host must preserve the patched Mech block vocabulary evidence.")
    (mech-provenance-assert-true
     (hyperdoc::patched-mech-block-vocabulary-present-p
      (hyperdoc::mech-host-runtime-provenance-served-vocabulary-of
       wiki-report))
     "Wiki host must preserve the patched Mech block vocabulary evidence.")))

(defun run-mech-deployment-provenance-smoke-tests ()
  (run-mech-provenance-topic-factory-smoke-test)
  (run-mech-provenance-page-smoke-test)
  (run-live-mech-deployment-provenance-skill-smoke-test)
  (run-live-mech-plugin-provenance-check-smoke-test)
  (format t "~&Mech deployment provenance smoke tests passed.~%")
  t)
