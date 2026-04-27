;;;; SCXML run objects for repair-protocol dry-runs
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *uscxml-browser*
  (or (uiop:getenv "USCXML_BROWSER")
      "/Users/rgb/workspace/uscxml/build/bin/uscxml-browser"))

(defparameter *page-lookup-topic-repair-stub-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/page-lookup-issue-topic-repair.stub.scxml"))

(defparameter *page-promotion-output-sync-expectation-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/page-promotion-output-sync-expectation.scxml"))

(defparameter *hyperdoc-test-system-runbook-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/hyperdoc-test-system-runbook.scxml"))

(defclass page-lookup-topic-repair-scxml-run ()
  ((issue :reader scxml-run-issue-of
          :initarg :issue
          :initform nil)
   (scxml-path :reader scxml-run-scxml-path-of
               :initarg :scxml-path)
   (command :reader scxml-run-command-of
            :initarg :command)
   (stdout :reader scxml-run-stdout-of
           :initarg :stdout)
   (stderr :reader scxml-run-stderr-of
           :initarg :stderr)
   (exit-code :reader scxml-run-exit-code-of
              :initarg :exit-code)))

(defclass page-lookup-topic-repair-native-scxml-run ()
  ((issue :reader native-scxml-run-issue-of
          :initarg :issue
          :initform nil)
   (scxml-path :reader native-scxml-run-scxml-path-of
               :initarg :scxml-path)
   (generated-package :reader native-scxml-run-generated-package-of
                      :initarg :generated-package)
   (generated-function :reader native-scxml-run-generated-function-of
                       :initarg :generated-function)
   (trace :reader native-scxml-run-trace-of
          :initarg :trace
          :initform nil)
   (final-state :reader native-scxml-run-final-state-of
                :initarg :final-state
                :initform nil)
   (done-p :reader native-scxml-run-done-p-of
           :initarg :done-p
           :initform nil)
   (validation-findings :reader native-scxml-run-validation-findings-of
                        :initarg :validation-findings
                        :initform nil)))

(defclass scxml-expectation-run ()
  ((scxml-path :reader scxml-expectation-run-scxml-path-of
               :initarg :scxml-path)
   (expected-subject :reader scxml-expectation-run-expected-subject-of
                     :initarg :expected-subject
                     :initform nil)
   (input-events :reader scxml-expectation-run-input-events-of
                 :initarg :input-events
                 :initform nil)
   (semantic-facts :reader scxml-expectation-run-semantic-facts-of
                   :initarg :semantic-facts
                   :initform nil)
   (validation-findings :reader scxml-expectation-run-validation-findings-of
                        :initarg :validation-findings
                        :initform nil)
   (generated-package :reader scxml-expectation-run-generated-package-of
                      :initarg :generated-package
                      :initform nil)
   (generated-function :reader scxml-expectation-run-generated-function-of
                       :initarg :generated-function
                       :initform nil)
   (trace :reader scxml-expectation-run-trace-of
          :initarg :trace
          :initform nil)
   (final-state :reader scxml-expectation-run-final-state-of
                :initarg :final-state
                :initform nil)
   (done-p :reader scxml-expectation-run-done-p-of
           :initarg :done-p
           :initform nil)
   (passed-p :reader scxml-expectation-run-passed-p-of
             :initarg :passed-p
             :initform nil)))

(defclass hyperdoc-test-system-scxml-run ()
  ((scxml-path :reader hyperdoc-test-system-scxml-run-scxml-path-of
               :initarg :scxml-path)
   (environment-summary :reader hyperdoc-test-system-scxml-run-environment-summary-of
                        :initarg :environment-summary
                        :initform nil)
   (input-events :reader hyperdoc-test-system-scxml-run-input-events-of
                 :initarg :input-events
                 :initform nil)
   (phase-results :reader hyperdoc-test-system-scxml-run-phase-results-of
                  :initarg :phase-results
                  :initform nil)
   (focused-check-results :reader hyperdoc-test-system-scxml-run-focused-check-results-of
                          :initarg :focused-check-results
                          :initform nil)
   (full-suite-result :reader hyperdoc-test-system-scxml-run-full-suite-result-of
                      :initarg :full-suite-result
                      :initform nil)
   (blocker :reader hyperdoc-test-system-scxml-run-blocker-of
            :initarg :blocker
            :initform nil)
   (blocker-classification :reader hyperdoc-test-system-scxml-run-blocker-classification-of
                           :initarg :blocker-classification
                           :initform :unknown)
   (suggested-next-action :reader hyperdoc-test-system-scxml-run-suggested-next-action-of
                          :initarg :suggested-next-action
                          :initform nil)
   (validation-findings :reader hyperdoc-test-system-scxml-run-validation-findings-of
                        :initarg :validation-findings
                        :initform nil)
   (trace :reader hyperdoc-test-system-scxml-run-trace-of
          :initarg :trace
          :initform nil)
   (final-state :reader hyperdoc-test-system-scxml-run-final-state-of
                :initarg :final-state
                :initform nil)
   (done-p :reader hyperdoc-test-system-scxml-run-done-p-of
           :initarg :done-p
           :initform nil)
   (passed-p :reader hyperdoc-test-system-scxml-run-passed-p-of
             :initarg :passed-p
             :initform nil)))

(defun uscxml-browser-pathname ()
  (let ((browser *uscxml-browser*))
    (and browser (probe-file browser))))

(defun run-page-lookup-topic-repair-stub-scxml (&optional issue)
  (let ((browser (uscxml-browser-pathname)))
    (unless browser
      (error "uSCXML browser not found. Set USCXML_BROWSER or update HYPERDOC::*USCXML-BROWSER*."))

    (let* ((command (list (namestring browser)
                          "-v"
                          "-l5"
                          (namestring *page-lookup-topic-repair-stub-scxml*))))
      (multiple-value-bind (stdout stderr exit-code)
          (uiop:run-program command
                            :output :string
                            :error-output :string
                            :ignore-error-status t)
        (make-instance 'page-lookup-topic-repair-scxml-run
                       :issue issue
                       :scxml-path *page-lookup-topic-repair-stub-scxml*
                       :command command
                       :stdout stdout
                       :stderr stderr
                       :exit-code exit-code)))))

(defun ensure-hyperdoc-scxml-system-loaded ()
  (asdf:load-system :hyperdoc/scxml))

(defun call-hyperdoc-scxml (function &rest arguments)
  (ensure-hyperdoc-scxml-system-loaded)
  (apply #'uiop:symbol-call :hyperdoc/scxml function arguments))

(defun scxml-validation-error-findings (findings)
  (remove-if-not (lambda (finding)
                   (eq :error
                       (call-hyperdoc-scxml
                        :scxml-validation-finding-severity-of
                        finding)))
                 findings))

(defun scxml-final-state= (expected final-state)
  (let ((state
          (cond
            ((stringp final-state) final-state)
            ((symbolp final-state) (string-downcase (symbol-name final-state)))
            (t (princ-to-string final-state)))))
    (string= (string-downcase expected)
             (string-downcase state))))

(defun run-scxml-expectation-with-events
    (scxml-path input-events semantic-facts
     &key expected-subject package-name function-name)
  (let* ((resolved-path (pathname scxml-path))
         (generated-package (or package-name
                                "HYPERDOC/SCXML/GENERATED/EXPECTATION"))
         (generated-function (or function-name
                                 "RUN-SCXML-EXPECTATION"))
         (chart (call-hyperdoc-scxml
                 :parse-scxml-file
                 resolved-path))
         (validation-findings (call-hyperdoc-scxml
                               :validate-scxml-chart
                               chart))
         (error-findings (scxml-validation-error-findings validation-findings)))
    (if error-findings
        (make-instance 'scxml-expectation-run
                       :scxml-path resolved-path
                       :expected-subject expected-subject
                       :input-events (copy-list input-events)
                       :semantic-facts (copy-tree semantic-facts)
                       :validation-findings validation-findings
                       :generated-package generated-package
                       :generated-function generated-function
                       :trace nil
                       :final-state nil
                       :done-p nil
                       :passed-p nil)
        (let* ((generated-run (call-hyperdoc-scxml
                               :compile-and-run-scxml-file-with-events
                               resolved-path
                               input-events
                               :package-name generated-package
                               :function-name generated-function))
               (trace (call-hyperdoc-scxml
                       :generated-scxml-run-trace-of
                       generated-run))
               (final-state (call-hyperdoc-scxml
                             :generated-scxml-run-final-state-of
                             generated-run))
               (done-p (call-hyperdoc-scxml
                        :generated-scxml-run-done-p
                        generated-run))
               (passed-p (and done-p
                              (scxml-final-state=
                               "passed"
                               final-state))))
          (make-instance 'scxml-expectation-run
                         :scxml-path resolved-path
                         :expected-subject expected-subject
                         :input-events (copy-list input-events)
                         :semantic-facts (copy-tree semantic-facts)
                         :validation-findings validation-findings
                         :generated-package generated-package
                         :generated-function generated-function
                         :trace trace
                         :final-state final-state
                         :done-p done-p
                         :passed-p passed-p)))))

(defun test-system-runbook-string-contains-ci-p (haystack needle)
  (and haystack needle
       (search needle haystack :test #'char-equal)))

(defun default-hyperdoc-test-system-phase-results ()
  (list :environment :captured
        :scxml-compiler :pass
        :uscxml-repair :pass
        :dmx-annotations :pass
        :collective-knowledge :pass
        :fedwiki-promotion-output-sync :pass
        :topic-factory-dmx :pass))

(defun default-hyperdoc-test-system-focused-check-results (phase-results)
  (list :scxml-compiler (getf phase-results :scxml-compiler :pass)
        :uscxml-repair (getf phase-results :uscxml-repair :pass)
        :dmx-annotations (getf phase-results :dmx-annotations :pass)
        :collective-knowledge (getf phase-results :collective-knowledge :pass)
        :fedwiki-promotion-output-sync
        (getf phase-results :fedwiki-promotion-output-sync :pass)
        :topic-factory-dmx (getf phase-results :topic-factory-dmx :pass)))

(defun default-hyperdoc-test-system-full-suite-result ()
  (list :status :pass
        :event "ASDF.TEST_SYSTEM.PASS"
        :classification :none
        :condition-text nil
        :blocker nil))

(defun default-hyperdoc-test-system-environment-summary ()
  (list :lisp-implementation (lisp-implementation-type)
        :lisp-version (lisp-implementation-version)
        :machine-instance (machine-instance)
        :machine-type (machine-type)
        :machine-version (machine-version)
        :software-type (software-type)
        :software-version (software-version)
        :hyperdoc-system (asdf:component-version (asdf:find-system :hyperdoc))))

(defun hyperdoc-test-system-condition-classification (condition-text)
  (cond
    ((or (test-system-runbook-string-contains-ci-p condition-text ":FORCE/:FORCE-NOT")
         (test-system-runbook-string-contains-ci-p condition-text "nested ASDF force")
         (test-system-runbook-string-contains-ci-p condition-text "nested ASDF :force"))
     :compile-order)
    ((test-system-runbook-string-contains-ci-p condition-text
                                                "No workspace journal stream matched the requested subject")
     :live-precondition)
    ((or (test-system-runbook-string-contains-ci-p condition-text "collective-knowledge")
         (test-system-runbook-string-contains-ci-p condition-text "collective knowledge"))
     :fixture-drift)
    ((or (test-system-runbook-string-contains-ci-p condition-text "materialization")
         (test-system-runbook-string-contains-ci-p condition-text "output must stay synced")
         (test-system-runbook-string-contains-ci-p condition-text "fresh no-action summary")
         (test-system-runbook-string-contains-ci-p condition-text "missing-source"))
     :materialization-drift)
    ((or (test-system-runbook-string-contains-ci-p condition-text "long-form x")
         (test-system-runbook-string-contains-ci-p condition-text "serializer contract"))
     :serializer-contract)
    (t :unknown)))

(defun hyperdoc-test-system-failure-classification-from-event (event)
  (cond
    ((null event) nil)
    ((string= event "COMPILE_ORDER.FAIL_NESTED_ASDF_FORCE")
     :compile-order)
    ((string= event "DMX.ANNOTATIONS.FAIL_LIVE_PRECONDITION")
     :live-precondition)
    ((string= event "COLLECTIVE_KNOWLEDGE.FAIL_FIXTURE_DRIFT")
     :fixture-drift)
    ((or (string= event "COLLECTIVE_KNOWLEDGE.FAIL_MATERIALIZATION_DRIFT")
         (string= event "FEDWIKI.PROMOTION.FAIL_MATERIALIZATION_DRIFT"))
     :materialization-drift)
    ((string= event "TOPIC_FACTORY_DMX.FAIL_SERIALIZER_CONTRACT")
     :serializer-contract)
    ((or (string= event "TOPIC_FACTORY_DMX.FAIL_UNEXPECTED_REGRESSION")
         (string= event "FEDWIKI.PROMOTION.FAIL_UNEXPECTED_REGRESSION")
         (string= event "ASDF.TEST_SYSTEM.FAIL_UNEXPECTED_REGRESSION"))
     :unexpected-regression)
    ((string= event "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")
     :unknown)
    (t nil)))

(defun hyperdoc-test-system-classification->failure-event (classification)
  (case classification
    (:compile-order "COMPILE_ORDER.FAIL_NESTED_ASDF_FORCE")
    (:live-precondition "DMX.ANNOTATIONS.FAIL_LIVE_PRECONDITION")
    (:fixture-drift "COLLECTIVE_KNOWLEDGE.FAIL_FIXTURE_DRIFT")
    (:materialization-drift "FEDWIKI.PROMOTION.FAIL_MATERIALIZATION_DRIFT")
    (:serializer-contract "TOPIC_FACTORY_DMX.FAIL_SERIALIZER_CONTRACT")
    (:unexpected-regression "ASDF.TEST_SYSTEM.FAIL_UNEXPECTED_REGRESSION")
    (:unknown "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")
    (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))

(defun hyperdoc-test-system-phase-event (phase status)
  (case phase
    (:scxml-compiler
     (case status
       (:pass "SCXML.COMPILER.PASS")
       (:fail-compile-order "COMPILE_ORDER.FAIL_NESTED_ASDF_FORCE")
       (:fail-unexpected-regression "ASDF.TEST_SYSTEM.FAIL_UNEXPECTED_REGRESSION")
       (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))
    (:uscxml-repair
     (case status
       (:pass "USCXML.REPAIR.PASS")
       (:fail-unexpected-regression "ASDF.TEST_SYSTEM.FAIL_UNEXPECTED_REGRESSION")
       (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))
    (:dmx-annotations
     (case status
       (:pass "DMX.ANNOTATIONS.PASS")
       (:skipped-live-precondition "DMX.ANNOTATIONS.SKIPPED_LIVE_PRECONDITION")
       (:fail-live-precondition "DMX.ANNOTATIONS.FAIL_LIVE_PRECONDITION")
       (:fail-unexpected-regression "ASDF.TEST_SYSTEM.FAIL_UNEXPECTED_REGRESSION")
       (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))
    (:collective-knowledge
     (case status
       (:pass "COLLECTIVE_KNOWLEDGE.PASS")
       (:fail-fixture-drift "COLLECTIVE_KNOWLEDGE.FAIL_FIXTURE_DRIFT")
       (:fail-materialization-drift "COLLECTIVE_KNOWLEDGE.FAIL_MATERIALIZATION_DRIFT")
       (:fail-unexpected-regression "ASDF.TEST_SYSTEM.FAIL_UNEXPECTED_REGRESSION")
       (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))
    (:fedwiki-promotion-output-sync
     (case status
       (:pass "FEDWIKI.PROMOTION_OUTPUT_SYNC.PASS")
       (:fail-materialization-drift "FEDWIKI.PROMOTION.FAIL_MATERIALIZATION_DRIFT")
       (:fail-unexpected-regression "FEDWIKI.PROMOTION.FAIL_UNEXPECTED_REGRESSION")
       (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))
    (:topic-factory-dmx
     (case status
       (:pass "TOPIC_FACTORY_DMX.PASS")
       (:fail-serializer-contract "TOPIC_FACTORY_DMX.FAIL_SERIALIZER_CONTRACT")
       (:fail-unexpected-regression "TOPIC_FACTORY_DMX.FAIL_UNEXPECTED_REGRESSION")
       (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))
    (otherwise "ASDF.TEST_SYSTEM.FAIL_UNKNOWN")))

(defun hyperdoc-test-system-failure-event-p (event)
  (and event
       (test-system-runbook-string-contains-ci-p event ".FAIL")))

(defun hyperdoc-test-system-full-suite-failure-event (full-suite-result)
  (or (getf full-suite-result :event)
      (hyperdoc-test-system-classification->failure-event
       (or (getf full-suite-result :classification)
           (hyperdoc-test-system-condition-classification
            (getf full-suite-result :condition-text))
           :unknown))))

(defun hyperdoc-test-system-runbook-events (phase-results full-suite-result)
  (let* ((resolved-phase-results
           (or phase-results
               (default-hyperdoc-test-system-phase-results)))
         (resolved-full-suite-result
           (or full-suite-result
               (default-hyperdoc-test-system-full-suite-result)))
         (events (list "ENV.CAPTURED")))
    (labels ((emit (phase-key)
               (let ((event (hyperdoc-test-system-phase-event
                             phase-key
                             (getf resolved-phase-results phase-key :pass))))
                 (setf events (append events (list event)))
                 event))
             (emit-full-suite ()
               (if (eq :pass (getf resolved-full-suite-result :status :pass))
                   (setf events (append events
                                        '("ASDF.TEST_SYSTEM.PASS"
                                          "RUNBOOK.PASSED"
                                          "EXPECTATION.PASSED")))
                   (setf events
                         (append events
                                 (list
                                  (hyperdoc-test-system-full-suite-failure-event
                                   resolved-full-suite-result)))))))
      (when (hyperdoc-test-system-failure-event-p (emit :scxml-compiler))
        (return-from hyperdoc-test-system-runbook-events events))
      (when (hyperdoc-test-system-failure-event-p (emit :uscxml-repair))
        (return-from hyperdoc-test-system-runbook-events events))
      (when (hyperdoc-test-system-failure-event-p (emit :dmx-annotations))
        (return-from hyperdoc-test-system-runbook-events events))
      (when (hyperdoc-test-system-failure-event-p (emit :collective-knowledge))
        (return-from hyperdoc-test-system-runbook-events events))
      (when (hyperdoc-test-system-failure-event-p
             (emit :fedwiki-promotion-output-sync))
        (return-from hyperdoc-test-system-runbook-events events))
      (when (hyperdoc-test-system-failure-event-p (emit :topic-factory-dmx))
        (return-from hyperdoc-test-system-runbook-events events))
      (emit-full-suite)
      events)))

(defun hyperdoc-test-system-runbook-classification
    (input-events full-suite-result)
  (or (loop for event in input-events
            for classification
              = (hyperdoc-test-system-failure-classification-from-event event)
            when classification
              return classification)
      (if (eq :pass (getf full-suite-result :status :pass))
          :none
          (or (getf full-suite-result :classification)
              (hyperdoc-test-system-condition-classification
               (getf full-suite-result :condition-text))
              :unknown))))

(defun hyperdoc-test-system-runbook-blocker-summary (classification)
  (case classification
    (:none nil)
    (:compile-order "Nested ASDF :force/:force-not compile-order path")
    (:live-precondition "DMX live workspace or journal precondition")
    (:fixture-drift "Collective-knowledge fixture drift")
    (:materialization-drift "FedWiki promotion materialization drift")
    (:serializer-contract "Topic factory DMX serializer contract")
    (:unexpected-regression "Unexpected deterministic regression")
    (:unknown "Unclassified full-suite failure")
    (otherwise "Unclassified full-suite failure")))

(defun hyperdoc-test-system-runbook-suggested-next-action (classification)
  (case classification
    (:none
     "No blocker is classified for this runbook execution.")
    (:compile-order
     "Run compile-order focused smoke and remove nested ASDF :force/:force-not usage from nested operate paths.")
    (:live-precondition
     "Gate the live precondition in default smoke and keep a strict/manual live entrypoint for explicit checks.")
    (:fixture-drift
     "Refresh deterministic fixtures for the failing slice and rerun focused smoke before full-suite rerun.")
    (:materialization-drift
     "Rebuild deterministic materialized artifacts, confirm focused output expectations, then rerun full suite.")
    (:serializer-contract
     "Run topic-factory DMX focused smoke, inspect outbound JSON serialization, and align contract assertions.")
    (:unexpected-regression
     "Create a focused deterministic reproduction for the regression, fix it, and rerun prior stabilized smokes.")
    (:unknown
     "Run a focused reproduction for the failing slice, classify the blocker type, then update the runbook classifier.")
    (otherwise
     "Run a focused reproduction and classify the blocker before changing expectations.")))

(defun hyperdoc-test-system-runbook-semantic-facts
    (environment-summary phase-results focused-check-results
     full-suite-result input-events classification blocker suggested-next-action)
  (list :environment-summary environment-summary
        :phase-results phase-results
        :focused-check-results focused-check-results
        :full-suite-result full-suite-result
        :input-events input-events
        :blocker-classification classification
        :blocker blocker
        :suggested-next-action suggested-next-action))

(defun run-hyperdoc-test-system-runbook-scxml-observation
    (&key phase-results focused-check-results
       full-suite-result input-events environment-summary)
  (let* ((resolved-phase-results
           (or phase-results
               (default-hyperdoc-test-system-phase-results)))
         (resolved-focused-check-results
           (or focused-check-results
               (default-hyperdoc-test-system-focused-check-results
                 resolved-phase-results)))
         (resolved-full-suite-result
           (or full-suite-result
               (default-hyperdoc-test-system-full-suite-result)))
         (resolved-environment-summary
           (or environment-summary
               (default-hyperdoc-test-system-environment-summary)))
         (resolved-input-events
           (or input-events
               (hyperdoc-test-system-runbook-events
                resolved-phase-results
                resolved-full-suite-result)))
         (classification
           (hyperdoc-test-system-runbook-classification
            resolved-input-events
            resolved-full-suite-result))
         (blocker
           (or (getf resolved-full-suite-result :blocker)
               (hyperdoc-test-system-runbook-blocker-summary classification)))
         (suggested-next-action
           (hyperdoc-test-system-runbook-suggested-next-action
            classification))
         (semantic-facts
           (hyperdoc-test-system-runbook-semantic-facts
            resolved-environment-summary
            resolved-phase-results
            resolved-focused-check-results
            resolved-full-suite-result
            resolved-input-events
            classification
            blocker
            suggested-next-action))
         (expectation-run
           (run-scxml-expectation-with-events
            *hyperdoc-test-system-runbook-scxml*
            resolved-input-events
            semantic-facts
            :expected-subject "asdf:test-system :hyperdoc runbook"
            :package-name
            "HYPERDOC/SCXML/GENERATED/HYPERDOC-TEST-SYSTEM-RUNBOOK"
            :function-name
            "RUN-HYPERDOC-TEST-SYSTEM-RUNBOOK")))
    (make-instance 'hyperdoc-test-system-scxml-run
                   :scxml-path *hyperdoc-test-system-runbook-scxml*
                   :environment-summary resolved-environment-summary
                   :input-events (copy-list resolved-input-events)
                   :phase-results (copy-tree resolved-phase-results)
                   :focused-check-results
                   (copy-tree resolved-focused-check-results)
                   :full-suite-result (copy-tree resolved-full-suite-result)
                   :blocker blocker
                   :blocker-classification classification
                   :suggested-next-action suggested-next-action
                   :validation-findings
                   (hyperdoc::scxml-expectation-run-validation-findings-of
                    expectation-run)
                   :trace (hyperdoc::scxml-expectation-run-trace-of
                           expectation-run)
                   :final-state
                   (hyperdoc::scxml-expectation-run-final-state-of
                    expectation-run)
                   :done-p (hyperdoc::scxml-expectation-run-done-p-of
                            expectation-run)
                   :passed-p (hyperdoc::scxml-expectation-run-passed-p-of
                              expectation-run))))

(defun run-hyperdoc-test-system-runbook-scxml-live
    (&key (run-full-suite-p t))
  (asdf:load-system :hyperdoc/tests)
  (labels ((run-live-check (test-function-name)
             (handler-case
                 (progn
                   (uiop:symbol-call :hyperdoc/tests test-function-name)
                   (values :pass nil))
               (error (condition)
                 (values :fail (princ-to-string condition)))))
           (classification->phase-status (phase classification)
             (case phase
               (:scxml-compiler
                (if (eq classification :compile-order)
                    :fail-compile-order
                    :fail-unexpected-regression))
               (:uscxml-repair :fail-unexpected-regression)
               (:dmx-annotations
                (if (eq classification :live-precondition)
                    :fail-live-precondition
                    :fail-unexpected-regression))
               (:collective-knowledge
                (case classification
                  (:fixture-drift :fail-fixture-drift)
                  (:materialization-drift :fail-materialization-drift)
                  (otherwise :fail-unexpected-regression)))
               (:fedwiki-promotion-output-sync
                (if (eq classification :materialization-drift)
                    :fail-materialization-drift
                    :fail-unexpected-regression))
               (:topic-factory-dmx
                (if (eq classification :serializer-contract)
                    :fail-serializer-contract
                    :fail-unexpected-regression))
               (otherwise :fail-unexpected-regression))))
    (let ((phase-results
            (default-hyperdoc-test-system-phase-results))
          (full-suite-result
            (default-hyperdoc-test-system-full-suite-result))
          (focused-check-results nil)
          (stop-after-focused-failure nil))
      (dolist (phase-spec
               '((:scxml-compiler
                  :run-scxml-compiler-smoke-tests)
                 (:uscxml-repair
                  :run-page-lookup-topic-repair-scxml-smoke-tests)
                 (:dmx-annotations
                  :run-dmx-annotations-smoke-tests)
                 (:collective-knowledge
                  :run-collective-knowledge-slice-smoke-tests)
                 (:fedwiki-promotion-output-sync
                  :run-localhost-fedwiki-page-promotion-output-sync-smoke-test)
                 (:topic-factory-dmx
                  :run-topic-factory-snippet-dmx-smoke-tests)))
        (unless stop-after-focused-failure
          (destructuring-bind (phase function-name) phase-spec
            (multiple-value-bind (status condition-text)
                (run-live-check function-name)
              (if (eq status :pass)
                  (setf (getf phase-results phase) :pass)
                  (let* ((classification
                           (hyperdoc-test-system-condition-classification
                            condition-text))
                         (phase-status
                           (classification->phase-status phase classification)))
                    (setf (getf phase-results phase) phase-status
                          (getf full-suite-result :status) :fail
                          (getf full-suite-result :classification) classification
                          (getf full-suite-result :event)
                          (hyperdoc-test-system-classification->failure-event
                           classification)
                          (getf full-suite-result :condition-text) condition-text
                          (getf full-suite-result :blocker)
                          (hyperdoc-test-system-runbook-blocker-summary
                           classification)
                          stop-after-focused-failure t)))))))
      (unless stop-after-focused-failure
        (if run-full-suite-p
            (handler-case
                (progn
                  (asdf:test-system :hyperdoc)
                  (setf (getf full-suite-result :status) :pass
                        (getf full-suite-result :classification) :none
                        (getf full-suite-result :event) "ASDF.TEST_SYSTEM.PASS"
                        (getf full-suite-result :condition-text) nil
                        (getf full-suite-result :blocker) nil))
              (error (condition)
                (let* ((condition-text (princ-to-string condition))
                       (classification
                         (hyperdoc-test-system-condition-classification
                          condition-text)))
                  (setf (getf full-suite-result :status) :fail
                        (getf full-suite-result :classification) classification
                        (getf full-suite-result :event)
                        (hyperdoc-test-system-classification->failure-event
                         classification)
                        (getf full-suite-result :condition-text) condition-text
                        (getf full-suite-result :blocker)
                        (hyperdoc-test-system-runbook-blocker-summary
                         classification)))))
            (setf (getf full-suite-result :status) :fail
                  (getf full-suite-result :classification) :unknown
                  (getf full-suite-result :event) "ASDF.TEST_SYSTEM.FAIL_UNKNOWN"
                  (getf full-suite-result :condition-text)
                  "Live mode skipped full suite execution."
                  (getf full-suite-result :blocker)
                  "Full suite not executed in live mode.")))
      (setf focused-check-results
            (default-hyperdoc-test-system-focused-check-results phase-results))
      (run-hyperdoc-test-system-runbook-scxml-observation
       :phase-results phase-results
       :focused-check-results focused-check-results
       :full-suite-result full-suite-result
       :environment-summary
       (default-hyperdoc-test-system-environment-summary)))))

(defun run-hyperdoc-test-system-runbook-scxml
    (&key (mode :observation)
       phase-results focused-check-results
       full-suite-result input-events environment-summary
       (run-full-suite-p t))
  (ecase mode
    (:observation
     (run-hyperdoc-test-system-runbook-scxml-observation
      :phase-results phase-results
      :focused-check-results focused-check-results
      :full-suite-result full-suite-result
      :input-events input-events
      :environment-summary environment-summary))
    (:live
     (run-hyperdoc-test-system-runbook-scxml-live
      :run-full-suite-p run-full-suite-p))))

(defun run-page-lookup-topic-repair-native-scxml (&optional issue)
  (let* ((scxml-path *page-lookup-topic-repair-stub-scxml*)
         (generated-package "HYPERDOC/SCXML/GENERATED/PAGE-LOOKUP-TOPIC-REPAIR")
         (generated-function "RUN-PAGE-LOOKUP-ISSUE-TOPIC-REPAIR")
         (chart (call-hyperdoc-scxml
                 :parse-scxml-file
                 scxml-path))
         (validation-findings (call-hyperdoc-scxml
                               :validate-scxml-chart
                               chart))
         (error-findings (scxml-validation-error-findings validation-findings)))
    (if error-findings
        (make-instance 'page-lookup-topic-repair-native-scxml-run
                       :issue issue
                       :scxml-path scxml-path
                       :generated-package generated-package
                       :generated-function generated-function
                       :trace nil
                       :final-state nil
                       :done-p nil
                       :validation-findings validation-findings)
        (let* ((generated-run (call-hyperdoc-scxml
                               :compile-and-run-scxml-file
                               scxml-path
                               :package-name generated-package
                               :function-name generated-function))
               (trace (call-hyperdoc-scxml
                       :generated-scxml-run-trace-of
                       generated-run))
               (final-state (call-hyperdoc-scxml
                             :generated-scxml-run-final-state-of
                             generated-run))
               (done-p (call-hyperdoc-scxml
                        :generated-scxml-run-done-p
                        generated-run)))
          (make-instance 'page-lookup-topic-repair-native-scxml-run
                         :issue issue
                         :scxml-path scxml-path
                         :generated-package generated-package
                         :generated-function generated-function
                         :trace trace
                         :final-state final-state
                         :done-p done-p
                         :validation-findings validation-findings)))))
