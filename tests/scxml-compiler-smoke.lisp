;;;; Smoke tests for HyperDoc Lisp-native SCXML compiler
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun scxml-compiler-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun scxml-compiler-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun scxml-compiler-assert-substring (needle haystack message)
  (scxml-compiler-assert-true
   (and haystack
        (search needle haystack :test #'char-equal))
   (format nil "~A -- missing substring ~S" message needle)))

(defun scxml-compiler-stub-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/page-lookup-issue-topic-repair.stub.scxml"))

(defun scxml-compiler-state-ids (chart)
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun run-scxml-compiler-parse-smoke-test ()
  (let* ((chart (hyperdoc/scxml:parse-scxml-file
                 (scxml-compiler-stub-pathname)))
         (state-ids (scxml-compiler-state-ids chart))
         (fixed-state
           (find "fixed"
                 (hyperdoc/scxml:scxml-chart-states-of chart)
                 :key #'hyperdoc/scxml:scxml-state-id-of
                 :test #'string=)))
    (scxml-compiler-assert-true
     (or (hyperdoc/scxml:scxml-chart-name-of chart)
         (hyperdoc/scxml:scxml-chart-initial-state-of chart))
     "Parsed chart must expose name or initial state")
    (scxml-compiler-assert-equal
     "openIssue"
     (hyperdoc/scxml:scxml-chart-initial-state-of chart)
     "Parsed chart initial state must be openIssue")
    (dolist (expected-state
             '("openIssue"
               "deriveTargetChunk"
               "classify"
               "missingTopic"
               "planTopicFactoryAddition"
               "previewTopicFactoryAddition"
               "checkExistingTopicFactory"
               "applyTopicFactoryAddition"
               "loadTopicsSource"
               "rebuildTopicIndex"
               "verifyTopicPage"
               "fixed"))
      (scxml-compiler-assert-true
       (member expected-state state-ids :test #'string=)
       (format nil "Parsed chart must include state ~A" expected-state)))
    (scxml-compiler-assert-true
     (and fixed-state
          (hyperdoc/scxml:scxml-state-final-p-of fixed-state))
     "State fixed must be marked final")))

(defun run-scxml-compiler-validate-smoke-test ()
  (let* ((chart (hyperdoc/scxml:parse-scxml-file
                 (scxml-compiler-stub-pathname)))
         (findings (hyperdoc/scxml:validate-scxml-chart chart))
         (error-findings
           (remove-if-not
            (lambda (finding)
              (eq :error
                  (hyperdoc/scxml:scxml-validation-finding-severity-of finding)))
            findings)))
    (scxml-compiler-assert-true
     (null error-findings)
     (format nil "Stub SCXML must validate without :error findings: ~S"
             (mapcar #'hyperdoc/scxml:scxml-validation-finding-code-of
                     error-findings)))))

(defun run-scxml-compiler-codegen-smoke-test ()
  (let* ((chart (hyperdoc/scxml:parse-scxml-file
                 (scxml-compiler-stub-pathname)))
         (generated-source
           (hyperdoc/scxml:compile-scxml-chart-to-string
            chart
            :package-name "HYPERDOC/SCXML/GENERATED/SMOKE-CODE"
            :function-name "RUN-PAGE-LOOKUP-ISSUE-TOPIC-REPAIR")))
    (scxml-compiler-assert-substring
     "defpackage"
     generated-source
     "Generated source must define a package")
    (scxml-compiler-assert-substring
     "run-page-lookup-issue-topic-repair"
     generated-source
     "Generated source must contain requested run function")
    (scxml-compiler-assert-substring
     "classification=missing-topic"
     generated-source
     "Generated source must embed chart log strings")))

(defun run-scxml-compiler-runtime-smoke-test ()
  (let* ((result
           (hyperdoc/scxml:compile-and-run-scxml-file
            (scxml-compiler-stub-pathname)
            :package-name "HYPERDOC/SCXML/GENERATED/SMOKE-RUNTIME"
            :function-name "RUN-PAGE-LOOKUP-ISSUE-TOPIC-REPAIR"))
         (trace (hyperdoc/scxml:generated-scxml-run-trace-of result))
         (final-state (hyperdoc/scxml:generated-scxml-run-final-state-of result)))
    (scxml-compiler-assert-true
     (hyperdoc/scxml:generated-scxml-run-done-p result)
     "Native SCXML runtime must finish in done state")
    (scxml-compiler-assert-true
     (or (equal "fixed" final-state)
         (equal :fixed final-state))
     (format nil "Final state must be fixed. Actual: ~S" final-state))
    (dolist (needle '("classification=missing-topic"
                      "repairOperation='create topic'"
                      "UI.REPAIR_FIXED"))
      (scxml-compiler-assert-true
       (find-if (lambda (line)
                  (search needle line :test #'char-equal))
                trace)
       (format nil "Runtime trace must include ~S" needle)))))

(defun run-scxml-compiler-no-uscxml-dependency-smoke-test ()
  (let ((hyperdoc::*uscxml-browser* "/definitely/missing/uscxml-browser"))
    (let ((native-run (hyperdoc::run-page-lookup-topic-repair-native-scxml)))
      (scxml-compiler-assert-true
       (hyperdoc::native-scxml-run-done-p-of native-run)
       "Native SCXML run must not depend on USCXML_BROWSER")
      (scxml-compiler-assert-true
       (find-if (lambda (line)
                  (search "UI.REPAIR_FIXED" line :test #'char-equal))
                (hyperdoc::native-scxml-run-trace-of native-run))
       "Native SCXML run must reach fixed without uscxml-browser"))))

(defun run-scxml-compiler-smoke-tests ()
  (run-scxml-compiler-parse-smoke-test)
  (run-scxml-compiler-validate-smoke-test)
  (run-scxml-compiler-codegen-smoke-test)
  (run-scxml-compiler-runtime-smoke-test)
  (run-scxml-compiler-no-uscxml-dependency-smoke-test)
  (format t "~&SCXML compiler smoke tests passed.~%")
  t)
