;;;; Smoke tests for first-class inspector view contracts
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-VIEW-CONTRACT-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun view-contract-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun view-contract-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun view-contract-assert-external-symbol (name)
  (multiple-value-bind (symbol status)
      (find-symbol name :html-inspector-views)
    (declare (ignore symbol))
    (view-contract-assert-true
     (eq status :external)
     (format nil "html-inspector-views must export ~A" name))))

(defun view-contract-test-view ()
  (html-inspector-views:html-view
      :title "Ordinary Smoke View"
      :priority 42
    (html-inspector-views:html
      (:p "ordinary view body"))))

(defun view-contract-view-titles (object)
  (mapcar #'html-inspector-views:view-title
          (html-inspector-views:all-views object)))

(defun view-contract-assert-view-titles (object titles)
  (let ((actual (view-contract-view-titles object)))
    (dolist (title titles)
      (view-contract-assert-true
       (member title actual :test #'string=)
       (format nil "Missing view-contract inspector view ~S" title)))))

(defun run-view-contract-package-protocol-smoke-test ()
  (dolist (name '("INSPECTOR-VIEW-SPECIFICATION"
                  "VIEW-ID-OF"
                  "VIEW-TITLE-OF"
                  "SUBJECT-TYPE-OF"
                  "READER-QUESTION-OF"
                  "CONTENT-MODEL-OF"
                  "BOX-CONTRACT-OF"
                  "PRIORITY-POLICY-OF"
                  "ACTIONS-OF"
                  "EVIDENCE-OF"
                  "FAILURE-MODES-OF"
                  "VIEW-SPECIFICATION"
                  "VIEW-READER-QUESTION"
                  "VIEW-CONTENT-MODEL"
                  "VIEW-BOX-CONTRACT"
                  "VIEW-PRIORITY-POLICY"
                  "VIEW-FAILURE-MODES"))
    (view-contract-assert-external-symbol name))
  (let* ((view (view-contract-test-view))
         (subject '(:ordinary-subject))
         (spec (html-inspector-views:view-specification view subject)))
    (view-contract-assert-true
     (typep spec 'html-inspector-views:inspector-view-specification)
     "Ordinary views must produce an inspector-view-specification.")
    (view-contract-assert-equal
     "Ordinary Smoke View"
     (html-inspector-views:view-title-of spec)
     "Default view contract must preserve the view title.")
    (view-contract-assert-true
     (member '(:layout-snapshot :missing-evidence)
             (html-inspector-views:evidence-of spec)
             :test #'equal)
     "Default view contract evidence must include missing layout snapshot evidence.")
    (view-contract-assert-view-titles
     spec
     '("Summary"
       "Content model"
       "Box contract"
       "Priority policy"
       "Actions"
       "Evidence"
       "Failure modes"))
    (let* ((evidence-view
             (find "Evidence"
                   (html-inspector-views:all-views spec)
                   :key #'html-inspector-views:view-title
                   :test #'string=))
           (evidence-html
             (and evidence-view
                  (html-inspector-views:view-html evidence-view))))
      (view-contract-assert-true
       (and evidence-html
            (search "Missing evidence" evidence-html :test #'char=)
            (search "rendered layout snapshot" evidence-html :test #'char=))
       "Evidence view must explain missing rendered layout snapshot evidence."))))

(defun run-view-contract-hyperdoc-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  (let* ((view (view-contract-test-view))
         (subject '(:runtime-subject))
         (spec
           (clog-moldable-inspector::view-contract-for-view-and-subject
            view
            subject))
         (source
           (uiop:read-file-string
            (asdf:system-relative-pathname
             :hyperdoc
             "hyperbook-server/inspector-dom-association.lisp"))))
    (view-contract-assert-true
     (typep spec 'html-inspector-views:inspector-view-specification)
     "HyperDoc runtime helper must return a view contract object.")
    (view-contract-assert-equal
     "Ordinary Smoke View"
     (html-inspector-views:view-title-of spec)
     "HyperDoc runtime helper must inspect the active view, not only the subject.")
    (view-contract-assert-equal
     (type-of subject)
     (html-inspector-views:subject-type-of spec)
     "HyperDoc runtime helper must preserve the pane subject type.")
    (view-contract-assert-true
     (member '(:layout-snapshot :missing-evidence)
             (html-inspector-views:evidence-of spec)
             :test #'equal)
     "HyperDoc runtime evidence must report missing layout snapshot explicitly.")
    (view-contract-assert-true
     (search "Inspect view contract" source :test #'char=)
     "Pane chrome source must expose the Inspect view contract label.")
    (view-contract-assert-true
     (search "view-contract-for-pane pane" source :test #'char=)
     "Pane chrome action must build a contract from the active view and pane subject.")
    (view-contract-assert-true
     (not (member "View Contract"
                  (view-contract-view-titles subject)
                  :test #'string=))
     "View Contract must not be a permanent tab on ordinary domain objects.")))

(defun run-view-contract-smoke-tests ()
  (run-view-contract-package-protocol-smoke-test)
  (run-view-contract-hyperdoc-runtime-smoke-test)
  (format t "~&View contract smoke tests passed.~%")
  t)
