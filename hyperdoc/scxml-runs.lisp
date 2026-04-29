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

(defparameter *localhost-fedwiki-page-promotion-workflow-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/localhost-fedwiki-page-promotion-workflow.scxml"))

(defparameter *hyperdoc-test-system-runbook-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/hyperdoc-test-system-runbook.scxml"))

(defparameter *dmx-annotation-local-first-continuation-runbook-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/dmx-annotation-local-first-continuation-runbook.scxml"))

(defparameter *dmx-annotation-acceptance-runbook-accepted-commits*
  '("0c2673e"
    "242410c"
    "9f489ab"))

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

(defclass localhost-fedwiki-page-promotion-workflow-scxml-run ()
  ((scxml-path :reader localhost-fedwiki-page-promotion-workflow-scxml-run-scxml-path-of
               :initarg :scxml-path)
   (promotion-surface
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-promotion-surface-of
    :initarg :promotion-surface
    :initform nil)
   (plan-id :reader localhost-fedwiki-page-promotion-workflow-scxml-run-plan-id-of
            :initarg :plan-id
            :initform nil)
   (plan-title :reader localhost-fedwiki-page-promotion-workflow-scxml-run-plan-title-of
               :initarg :plan-title
               :initform nil)
   (semantic-facts
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-semantic-facts-of
    :initarg :semantic-facts
    :initform nil)
   (input-events
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-input-events-of
    :initarg :input-events
    :initform nil)
   (phase-results
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-phase-results-of
    :initarg :phase-results
    :initform nil)
   (validation-findings
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-validation-findings-of
    :initarg :validation-findings
    :initform nil)
   (trace :reader localhost-fedwiki-page-promotion-workflow-scxml-run-trace-of
          :initarg :trace
          :initform nil)
   (final-state
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
    :initarg :final-state
    :initform nil)
   (done-p :reader localhost-fedwiki-page-promotion-workflow-scxml-run-done-p-of
           :initarg :done-p
           :initform nil)
   (passed-p :reader localhost-fedwiki-page-promotion-workflow-scxml-run-passed-p-of
             :initarg :passed-p
             :initform nil)
   (blocker :reader localhost-fedwiki-page-promotion-workflow-scxml-run-blocker-of
            :initarg :blocker
            :initform nil)
   (failure-classification
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-failure-classification-of
    :initarg :failure-classification
    :initform :unknown)
   (suggested-next-action
    :reader localhost-fedwiki-page-promotion-workflow-scxml-run-suggested-next-action-of
    :initarg :suggested-next-action
    :initform nil)))

(defclass dmx-annotation-acceptance-scxml-run ()
  ((scxml-path :reader dmx-annotation-acceptance-scxml-run-scxml-path-of
               :initarg :scxml-path)
   (accepted-commits
    :reader dmx-annotation-acceptance-scxml-run-accepted-commits-of
    :initarg :accepted-commits
    :initform nil)
   (generated-package
    :reader dmx-annotation-acceptance-scxml-run-generated-package-of
    :initarg :generated-package
    :initform nil)
   (generated-function
    :reader dmx-annotation-acceptance-scxml-run-generated-function-of
    :initarg :generated-function
    :initform nil)
   (validation-findings
    :reader dmx-annotation-acceptance-scxml-run-validation-findings-of
    :initarg :validation-findings
    :initform nil)
   (semantic-facts
    :reader dmx-annotation-acceptance-scxml-run-semantic-facts-of
    :initarg :semantic-facts
    :initform nil)
   (input-events :reader dmx-annotation-acceptance-scxml-run-input-events-of
                 :initarg :input-events
                 :initform nil)
   (trace :reader dmx-annotation-acceptance-scxml-run-trace-of
          :initarg :trace
          :initform nil)
   (done-p :reader dmx-annotation-acceptance-scxml-run-done-p-of
           :initarg :done-p
           :initform nil)
   (passed-p :reader dmx-annotation-acceptance-scxml-run-passed-p-of
             :initarg :passed-p
             :initform nil)
   (final-state :reader dmx-annotation-acceptance-scxml-run-final-state-of
                :initarg :final-state
                :initform nil)
   (skipped-checks
    :reader dmx-annotation-acceptance-scxml-run-skipped-checks-of
    :initarg :skipped-checks
    :initform nil)
   (replay-mode :reader dmx-annotation-acceptance-scxml-run-replay-mode-of
                :initarg :replay-mode
                :initform :dry-native)
   (replay-command
    :reader dmx-annotation-acceptance-scxml-run-replay-command-of
    :initarg :replay-command
    :initform nil)
   (live-ran-p :reader dmx-annotation-acceptance-scxml-run-live-ran-p-of
               :initarg :live-ran-p
               :initform nil)
   (live-exit-code
    :reader dmx-annotation-acceptance-scxml-run-live-exit-code-of
    :initarg :live-exit-code
    :initform nil)
   (live-stdout :reader dmx-annotation-acceptance-scxml-run-live-stdout-of
                :initarg :live-stdout
                :initform nil)
   (live-stderr :reader dmx-annotation-acceptance-scxml-run-live-stderr-of
                :initarg :live-stderr
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

(defun localhost-fedwiki-page-promotion-workflow-find-plan
    (surface plan-id)
  (let ((plans (and surface
                    (localhost-fedwiki-page-promotion-surface-plans
                     surface))))
    (or (and plan-id
             (find plan-id
                   plans
                   :key #'localhost-fedwiki-page-promotion-plan-id
                   :test #'equal))
        (first plans))))

(defun localhost-fedwiki-page-promotion-workflow-default-semantic-facts ()
  (list :source-resolved-p t
        :source-normalized-p t
        :source-envelope-malformed-p nil
        :source-availability-state :available
        :promotion-plan-built-p t
        :page-composed-p t
        :snippet-generated-p t
        :page-artifact-state :synced
        :snippet-artifact-state :synced
        :dmx-dry-run-payload-built-p t
        :dmx-payload-valid-p t
        :guarded-write-boundary :accepted
        :live-dmx-write :skipped-precondition
        :unexpected-regression-p nil
        :unexpected-regression-condition nil))

(defun localhost-fedwiki-page-promotion-workflow-normalize-semantic-facts
    (facts)
  (apply #'plist-with-overrides
         (localhost-fedwiki-page-promotion-workflow-default-semantic-facts)
         facts))

(defun localhost-fedwiki-page-promotion-workflow-artifact-state
    (synced-p freshness-state source-availability-state)
  (cond
    ((eq :source-unavailable source-availability-state)
     :source-unavailable)
    (synced-p :synced)
    ((eq :stale freshness-state) :stale)
    ((eq :unknown-malformed-envelope freshness-state)
     :malformed-envelope)
    ((eq :unknown-missing-envelope freshness-state)
     :missing-envelope)
    (t :unknown)))

(defun localhost-fedwiki-page-promotion-workflow-semantic-facts
    (&key promotion-surface plan-id (live-dmx-write :skipped-precondition))
  (let* ((surface (or promotion-surface
                      (current-localhost-fedwiki-page-promotion-surface)))
         (plan (localhost-fedwiki-page-promotion-workflow-find-plan
                surface
                plan-id)))
    (unless plan
      (error "No localhost FedWiki page-promotion plan is available for workflow SCXML run."))
    (let* ((status (localhost-fedwiki-page-promotion-plan-sync-status plan))
           (dmx-summary (getf status :dmx-dry-run-summary))
           (source-availability-state
             (getf status :source-availability-state :unknown))
           (page-freshness-state
             (getf status :page-source-freshness-state :unknown))
           (snippet-freshness-state
             (getf status :snippet-source-freshness-state :unknown))
           (source-envelope-malformed-p
             (or (eq :unknown-malformed-envelope page-freshness-state)
                 (eq :unknown-malformed-envelope snippet-freshness-state)))
           (page-artifact-state
             (localhost-fedwiki-page-promotion-workflow-artifact-state
              (getf status :page-synced)
              page-freshness-state
              source-availability-state))
           (snippet-artifact-state
             (localhost-fedwiki-page-promotion-workflow-artifact-state
              (getf status :snippet-synced)
              snippet-freshness-state
              source-availability-state))
           (dmx-dry-run-payload-built-p
             (and dmx-summary
                  (getf dmx-summary :available)))
           (dmx-payload-valid-p
             (and dmx-dry-run-payload-built-p
                  (eq :canonical
                      (getf dmx-summary :view-props-validation-status))
                  (null (getf dmx-summary :forbidden-short-keys))))
           (guarded-write-boundary
             (if dmx-payload-valid-p
                 :accepted
                 :rejected)))
      (localhost-fedwiki-page-promotion-workflow-normalize-semantic-facts
       (list :promotion-surface surface
             :plan-id (localhost-fedwiki-page-promotion-plan-id plan)
             :plan-title (localhost-fedwiki-page-promotion-plan-title plan)
             :source-page-id
             (localhost-fedwiki-page-promotion-plan-source-page-id plan)
             :source-page-slug
             (localhost-fedwiki-page-promotion-plan-source-page-slug plan)
             :source-resolved-p
             (not (eq :source-unavailable source-availability-state))
             :source-normalized-p
             (and (eq :available source-availability-state)
                  (not source-envelope-malformed-p))
             :source-envelope-malformed-p source-envelope-malformed-p
             :source-availability-state source-availability-state
             :promotion-plan-built-p t
             :page-composed-p
             (let ((rendered-page
                     (localhost-fedwiki-page-promotion-plan-rendered-page
                      plan)))
               (and (stringp rendered-page)
                    (plusp (length rendered-page))))
             :snippet-generated-p
             (let ((snippet
                     (snippet-text-of
                      (localhost-fedwiki-page-promotion-plan-topic-definition
                       plan))))
               (and (stringp snippet)
                    (plusp (length snippet))))
             :page-artifact-state page-artifact-state
             :snippet-artifact-state snippet-artifact-state
             :dmx-dry-run-payload-built-p dmx-dry-run-payload-built-p
             :dmx-payload-valid-p dmx-payload-valid-p
             :guarded-write-boundary guarded-write-boundary
             :live-dmx-write live-dmx-write
             :unexpected-regression-p nil
             :unexpected-regression-condition nil
             :sync-status status
             :dmx-dry-run-summary dmx-summary)))))

(defun localhost-fedwiki-page-promotion-workflow-events (semantic-facts)
  (let* ((facts
           (localhost-fedwiki-page-promotion-workflow-normalize-semantic-facts
            semantic-facts))
         (events '()))
    (labels ((emit (event)
               (push event events)))
      (block workflow
        (when (getf facts :unexpected-regression-p)
          (emit "WORKFLOW.UNEXPECTED_REGRESSION")
          (return-from workflow (nreverse events)))

        (when (eq :source-unavailable
                  (getf facts :source-availability-state))
          (emit "SOURCE.UNAVAILABLE")
          (return-from workflow (nreverse events)))

        (emit "SOURCE.RESOLVED")
        (when (getf facts :source-envelope-malformed-p)
          (emit "SOURCE.ENVELOPE_MALFORMED")
          (return-from workflow (nreverse events)))

        (if (getf facts :source-normalized-p)
            (emit "SOURCE.NORMALIZED")
            (progn
              (emit "WORKFLOW.UNEXPECTED_REGRESSION")
              (return-from workflow (nreverse events))))

        (if (getf facts :promotion-plan-built-p)
            (emit "PROMOTION_PLAN.BUILT")
            (progn
              (emit "WORKFLOW.UNEXPECTED_REGRESSION")
              (return-from workflow (nreverse events))))

        (if (getf facts :page-composed-p)
            (emit "HYPERDOC_PAGE.COMPOSED")
            (progn
              (emit "WORKFLOW.UNEXPECTED_REGRESSION")
              (return-from workflow (nreverse events))))

        (if (getf facts :snippet-generated-p)
            (emit "TOPIC_FACTORY_SNIPPET.GENERATED")
            (progn
              (emit "WORKFLOW.UNEXPECTED_REGRESSION")
              (return-from workflow (nreverse events))))

        (case (getf facts :page-artifact-state)
          (:synced
           (emit "PAGE_ARTIFACT.SYNCED"))
          (:stale
           (emit "PAGE_ARTIFACT.STALE")
           (return-from workflow (nreverse events)))
          (otherwise
           (emit "WORKFLOW.UNEXPECTED_REGRESSION")
           (return-from workflow (nreverse events))))

        (case (getf facts :snippet-artifact-state)
          (:synced
           (emit "SNIPPET_ARTIFACT.SYNCED"))
          (:stale
           (emit "SNIPPET_ARTIFACT.STALE")
           (return-from workflow (nreverse events)))
          (otherwise
           (emit "WORKFLOW.UNEXPECTED_REGRESSION")
           (return-from workflow (nreverse events))))

        (if (getf facts :dmx-dry-run-payload-built-p)
            (emit "DMX.DRY_RUN_PAYLOAD.BUILT")
            (progn
              (emit "WORKFLOW.UNEXPECTED_REGRESSION")
              (return-from workflow (nreverse events))))

        (if (getf facts :dmx-payload-valid-p)
            (emit "DMX.PAYLOAD.VALIDATED")
            (progn
              (emit "DMX.PAYLOAD.INVALID")
              (return-from workflow (nreverse events))))

        (case (getf facts :guarded-write-boundary)
          (:accepted
           (emit "GUARDED_WRITE_BOUNDARY.ACCEPTED"))
          (:rejected
           (emit "GUARDED_WRITE_BOUNDARY.REJECTED")
           (return-from workflow (nreverse events)))
          (otherwise
           (emit "WORKFLOW.UNEXPECTED_REGRESSION")
           (return-from workflow (nreverse events))))

        (case (getf facts :live-dmx-write)
          (:skipped-precondition
           (emit "LIVE_DMX_WRITE.SKIPPED_PRECONDITION")
           (emit "WORKFLOW.PASSED"))
          (:succeeded
           (emit "LIVE_DMX_WRITE.SUCCEEDED")
           (emit "WORKFLOW.PASSED"))
          (:precondition-missing
           (emit "LIVE_DMX_WRITE.PRECONDITION_MISSING")
           (return-from workflow (nreverse events)))
          (otherwise
           (emit "WORKFLOW.UNEXPECTED_REGRESSION")
           (return-from workflow (nreverse events))))
        (nreverse events)))))

(defun localhost-fedwiki-page-promotion-workflow-phase-results
    (semantic-facts)
  (let ((facts
          (localhost-fedwiki-page-promotion-workflow-normalize-semantic-facts
           semantic-facts)))
    (list :resolve-source
          (case (getf facts :source-availability-state)
            (:source-unavailable :source-unavailable)
            (:available :pass)
            (otherwise :unknown))
          :normalize-fedwiki-source
          (cond
            ((eq :source-unavailable
                 (getf facts :source-availability-state))
             :skipped-source-unavailable)
            ((getf facts :source-envelope-malformed-p)
             :malformed-envelope)
            ((getf facts :source-normalized-p)
             :pass)
            (t :failed))
          :build-promotion-plan
          (if (getf facts :promotion-plan-built-p) :pass :failed)
          :compose-hyperdoc-page
          (if (getf facts :page-composed-p) :pass :failed)
          :generate-topic-factory-snippet
          (if (getf facts :snippet-generated-p) :pass :failed)
          :check-page-artifact-sync
          (getf facts :page-artifact-state)
          :check-snippet-artifact-sync
          (getf facts :snippet-artifact-state)
          :build-dmx-dry-run-payload
          (if (getf facts :dmx-dry-run-payload-built-p) :pass :failed)
          :validate-dmx-payload
          (if (getf facts :dmx-payload-valid-p) :pass :invalid)
          :review-guarded-write-boundary
          (getf facts :guarded-write-boundary)
          :live-dmx-write
          (getf facts :live-dmx-write))))

(defun localhost-fedwiki-page-promotion-workflow-failure-classification
    (final-state)
  (cond
    ((scxml-final-state= "passed" final-state)
     :none)
    ((scxml-final-state= "sourceUnavailable" final-state)
     :source-unavailable)
    ((scxml-final-state= "malformedSourceEnvelope" final-state)
     :malformed-source-envelope)
    ((scxml-final-state= "pageArtifactStale" final-state)
     :page-artifact-stale)
    ((scxml-final-state= "snippetArtifactStale" final-state)
     :snippet-artifact-stale)
    ((scxml-final-state= "dmxPayloadInvalid" final-state)
     :dmx-payload-invalid)
    ((scxml-final-state= "guardedWriteRejected" final-state)
     :guarded-write-rejected)
    ((scxml-final-state= "liveWritePreconditionMissing" final-state)
     :live-write-precondition-missing)
    ((scxml-final-state= "unexpectedRegression" final-state)
     :unexpected-regression)
    (t :unknown)))

(defun localhost-fedwiki-page-promotion-workflow-blocker-summary
    (classification)
  (case classification
    (:none nil)
    (:source-unavailable
     "Localhost FedWiki source page is unavailable for the selected promotion plan.")
    (:malformed-source-envelope
     "Promotion source snapshot envelope is malformed and blocks workflow normalization.")
    (:page-artifact-stale
     "Generated HyperDoc page artifact is stale relative to the normalized source.")
    (:snippet-artifact-stale
     "Generated topic-factory snippet artifact is stale relative to the normalized source.")
    (:dmx-payload-invalid
     "DMX dry-run payload failed validation for the selected promotion plan.")
    (:guarded-write-rejected
     "Guarded DMX write boundary rejected the selected promotion plan.")
    (:live-write-precondition-missing
     "Live DMX write precondition is missing in strict mode.")
    (:unexpected-regression
     "Unexpected regression interrupted the page-promotion workflow.")
    (:unknown
     "Unclassified page-promotion workflow failure.")
    (otherwise
     "Unclassified page-promotion workflow failure.")))

(defun localhost-fedwiki-page-promotion-workflow-suggested-next-action
    (classification)
  (case classification
    (:none
     "No blocking action is required; the page-promotion workflow passed.")
    (:source-unavailable
     "Restore the missing localhost FedWiki source page file and rerun the promotion workflow.")
    (:malformed-source-envelope
     "Repair or regenerate malformed source snapshot envelope evidence, then rerun the workflow.")
    (:page-artifact-stale
     "Regenerate the HyperDoc page artifact from the current normalized source and rerun checks.")
    (:snippet-artifact-stale
     "Regenerate the topic-factory snippet artifact from the current normalized source and rerun checks.")
    (:dmx-payload-invalid
     "Inspect DMX dry-run payload validation findings and correct the payload contract.")
    (:guarded-write-rejected
     "Review guarded write boundary requirements and fix the rejected promotion payload.")
    (:live-write-precondition-missing
     "Set explicit live-write preconditions or keep live writes in skipped-precondition mode.")
    (:unexpected-regression
     "Run focused reproduction/classification on the failing promotion-workflow phase before changing expectations.")
    (:unknown
     "Run focused reproduction/classification for the workflow failure and classify the blocker.")
    (otherwise
     "Run focused reproduction/classification for the workflow failure and classify the blocker.")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml
    (&key promotion-surface plan-id semantic-facts input-events
       package-name function-name)
  (let* ((resolved-surface
           (or promotion-surface
               (ignore-errors
                 (current-localhost-fedwiki-page-promotion-surface))))
         (resolved-plan
           (and resolved-surface
                (localhost-fedwiki-page-promotion-workflow-find-plan
                 resolved-surface
                 plan-id)))
         (computed-facts
           (or semantic-facts
               (handler-case
                   (localhost-fedwiki-page-promotion-workflow-semantic-facts
                    :promotion-surface resolved-surface
                    :plan-id plan-id)
                 (error (condition)
                   (list :plan-id
                         (or plan-id
                             (and resolved-plan
                                  (localhost-fedwiki-page-promotion-plan-id
                                   resolved-plan)))
                         :plan-title
                         (and resolved-plan
                              (localhost-fedwiki-page-promotion-plan-title
                               resolved-plan))
                         :source-resolved-p nil
                         :source-normalized-p nil
                         :source-availability-state :unknown
                         :unexpected-regression-p t
                         :unexpected-regression-condition
                         (princ-to-string condition))))))
         (resolved-facts
           (localhost-fedwiki-page-promotion-workflow-normalize-semantic-facts
            computed-facts))
         (resolved-input-events
           (or input-events
               (localhost-fedwiki-page-promotion-workflow-events
                resolved-facts)))
         (phase-results
           (localhost-fedwiki-page-promotion-workflow-phase-results
            resolved-facts))
         (resolved-package
           (or package-name
               "HYPERDOC/SCXML/GENERATED/LOCALHOST-FEDWIKI-PAGE-PROMOTION-WORKFLOW"))
         (resolved-function
           (or function-name
               "RUN-LOCALHOST-FEDWIKI-PAGE-PROMOTION-WORKFLOW"))
         (expectation-run
           (run-scxml-expectation-with-events
            *localhost-fedwiki-page-promotion-workflow-scxml*
            resolved-input-events
            resolved-facts
            :expected-subject
            (format nil
                    "localhost-fedwiki-page-promotion-workflow ~A"
                    (or (getf resolved-facts :plan-id)
                        (and resolved-plan
                             (localhost-fedwiki-page-promotion-plan-id
                              resolved-plan))
                        "default-plan"))
            :package-name resolved-package
            :function-name resolved-function))
         (final-state
           (scxml-expectation-run-final-state-of expectation-run))
         (classification
           (localhost-fedwiki-page-promotion-workflow-failure-classification
            final-state))
         (blocker
           (localhost-fedwiki-page-promotion-workflow-blocker-summary
            classification))
         (suggested-next-action
           (localhost-fedwiki-page-promotion-workflow-suggested-next-action
            classification)))
    (make-instance 'localhost-fedwiki-page-promotion-workflow-scxml-run
                   :scxml-path *localhost-fedwiki-page-promotion-workflow-scxml*
                   :promotion-surface resolved-surface
                   :plan-id
                   (or (getf resolved-facts :plan-id)
                       (and resolved-plan
                            (localhost-fedwiki-page-promotion-plan-id
                             resolved-plan)))
                   :plan-title
                   (or (getf resolved-facts :plan-title)
                       (and resolved-plan
                            (localhost-fedwiki-page-promotion-plan-title
                             resolved-plan)))
                   :semantic-facts (copy-tree resolved-facts)
                   :input-events (copy-list resolved-input-events)
                   :phase-results (copy-tree phase-results)
                   :validation-findings
                   (scxml-expectation-run-validation-findings-of
                    expectation-run)
                   :trace (scxml-expectation-run-trace-of expectation-run)
                   :final-state final-state
                   :done-p (scxml-expectation-run-done-p-of expectation-run)
                   :passed-p (scxml-expectation-run-passed-p-of expectation-run)
                   :blocker blocker
                   :failure-classification classification
                   :suggested-next-action suggested-next-action)))

(defparameter *dmx-annotation-acceptance-runbook-secret-needles*
  '("Authorization:"
    "Authorization="
    "Cookie:"
    "Cookie="
    "JSESSIONID="
    "Bearer "
    "bearer "
    "password="
    "password:"
    "\"password\""
    "token="
    "\"token\":\""))

(defparameter *dmx-annotation-acceptance-runbook-expected-live-pass-lines*
  '("DMX workspace annotation live smoke tests passed."
    "DMX workspace annotation smoke tests passed."))

(defun dmx-annotation-acceptance-live-enabled-p ()
  (string= (string-trim '(#\Space #\Tab #\Newline #\Return)
                        (or (uiop:getenv
                             "HYPERDOC_RUN_LIVE_DMX_ANNOTATION_TESTS")
                            ""))
           "1"))

(defun dmx-annotation-acceptance-string-contains-ci-p (haystack needle)
  (and haystack needle
       (search needle haystack :test #'char-equal)))

(defun dmx-annotation-acceptance-secret-line-p (line)
  (find-if (lambda (needle)
             (dmx-annotation-acceptance-string-contains-ci-p line needle))
           *dmx-annotation-acceptance-runbook-secret-needles*))

(defun dmx-annotation-acceptance-sanitize-output (text)
  (when text
    (with-output-to-string (stream)
      (dolist (line (uiop:split-string text :separator '(#\Newline)))
        (if (dmx-annotation-acceptance-secret-line-p line)
            (write-line "[REDACTED secret-like content]" stream)
            (write-line line stream))))))

(defun dmx-annotation-acceptance-live-command ()
  (list "env"
        "HYPERDOC_RUN_LIVE_DMX_ANNOTATION_TESTS=1"
        "nix"
        "develop"
        "-c"
        "sbcl"
        "--no-userinit"
        "--non-interactive"
        "--eval"
        "(require :asdf)"
        "--eval"
        "(asdf:load-system :hyperdoc/tests)"
        "--eval"
        "(uiop:symbol-call :hyperdoc/tests :run-dmx-annotations-smoke-tests)"
        "--eval"
        "(uiop:quit 0)"))

(defun dmx-annotation-acceptance-runbook-events (live-run-enabled-p)
  (append
   '("PRECHECK.CLEAN_TREE"
     "COMMITS.ACCEPTED"
     "LOCAL_FIRST_SAVE.WITHOUT_CREDENTIALS"
     "DMX.MATERIALIZATION.ONE_CARRIER_LANE"
     "CREATE_TOPIC_FAILURE_EVIDENCE.SKIP_RECORDED"
     "CONTINUATION.GUARDED_PATH"
     "WORKSPACE_ASSIGNMENT.READBACK_919815"
     "TOPICMAP.READBACK_INCLUDES_919822"
     "REOPEN.WORKSPACE_DOCK_ANNOTATION"
     "SECRET_LEAKAGE_AUDIT.PASSED")
   (list (if live-run-enabled-p
             "LIVE_SMOKE.EXIT_0_EXPECTED_PASSES"
             "LIVE_SMOKE.SKIPPED_PRECONDITION"))))

(defun dmx-annotation-acceptance-runbook-semantic-facts
    (&key live-run-enabled-p live-exit-code live-pass-lines-observed-p)
  (list :accepted-commits
        (copy-list *dmx-annotation-acceptance-runbook-accepted-commits*)
        :workspace-id 919815
        :workspace-topicmap-id 919822
        :preserved-topic-id 936040
        :local-first-save-no-credentials-p t
        :local-journal-reconstructable-p t
        :optional-materialization-one-carrier-lane-p t
        :continuation-guarded-no-raw-topic-upsert-p t
        :workspace-assignment-readback-id 919815
        :topicmap-readback-includes-919822-p t
        :reopen-reconstructs-workspace-dock-annotation-p t
        :reopen-preserves-topic-id-p t
        :secret-leakage-audit-passed-p t
        :create-topic-failure-evidence-smoke-status :skipped-pre-topic-upsert
        :live-smoke-enabled-p live-run-enabled-p
        :live-smoke-exit-code live-exit-code
        :live-smoke-pass-lines-observed-p
        (if live-run-enabled-p
            live-pass-lines-observed-p
            :skipped-precondition)))

(defun dmx-annotation-acceptance-runbook-skipped-checks
    (&key live-run-enabled-p)
  (append
   (list (list :check
               "create-topic failure evidence smoke"
               :status :skipped
               :reason
               "Skipped at pre-topic-upsert preconditions by design."))
   (unless live-run-enabled-p
     (list (list :check
                 "live smoke replay"
                 :status :skipped
                 :reason
                 "Set HYPERDOC_RUN_LIVE_DMX_ANNOTATION_TESTS=1 and call with :live? T.")))))

(defun dmx-annotation-acceptance-trace-contains-state-p (trace state-id)
  (find-if (lambda (line)
             (dmx-annotation-acceptance-string-contains-ci-p
              line
              (format nil "Entering: ~A" state-id)))
           trace))

(defun dmx-annotation-acceptance-live-pass-lines-observed-p (stdout)
  (every (lambda (line)
           (dmx-annotation-acceptance-string-contains-ci-p stdout line))
         *dmx-annotation-acceptance-runbook-expected-live-pass-lines*))

(defun run-dmx-annotation-acceptance-scxml-runbook (&key live?)
  (let* ((run-live-p (and live?
                          (dmx-annotation-acceptance-live-enabled-p)))
         (command (and run-live-p
                       (dmx-annotation-acceptance-live-command)))
         (live-stdout nil)
         (live-stderr nil)
         (live-exit-code nil))
    (when run-live-p
      (multiple-value-bind (stdout stderr exit-code)
          (uiop:run-program command
                            :output :string
                            :error-output :string
                            :ignore-error-status t)
        (setf live-stdout (dmx-annotation-acceptance-sanitize-output stdout)
              live-stderr (dmx-annotation-acceptance-sanitize-output stderr)
              live-exit-code exit-code)))
    (let* ((input-events
             (dmx-annotation-acceptance-runbook-events run-live-p))
           (semantic-facts
             (dmx-annotation-acceptance-runbook-semantic-facts
              :live-run-enabled-p run-live-p
              :live-exit-code live-exit-code
              :live-pass-lines-observed-p
              (and run-live-p
                   (zerop live-exit-code)
                   (dmx-annotation-acceptance-live-pass-lines-observed-p
                    live-stdout))))
           (generated-package
             "HYPERDOC/SCXML/GENERATED/DMX-ANNOTATION-ACCEPTANCE-RUNBOOK")
           (generated-function
             "RUN-DMX-ANNOTATION-ACCEPTANCE-RUNBOOK")
           (chart (call-hyperdoc-scxml
                   :parse-scxml-file
                   *dmx-annotation-local-first-continuation-runbook-scxml*))
           (validation-findings (call-hyperdoc-scxml
                                 :validate-scxml-chart
                                 chart))
           (error-findings
             (scxml-validation-error-findings validation-findings)))
      (if error-findings
          (make-instance 'dmx-annotation-acceptance-scxml-run
                         :scxml-path
                         *dmx-annotation-local-first-continuation-runbook-scxml*
                         :accepted-commits
                         (copy-list
                          *dmx-annotation-acceptance-runbook-accepted-commits*)
                         :generated-package generated-package
                         :generated-function generated-function
                         :validation-findings validation-findings
                         :semantic-facts semantic-facts
                         :input-events (copy-list input-events)
                         :trace nil
                         :done-p nil
                         :passed-p nil
                         :final-state nil
                         :skipped-checks
                         (dmx-annotation-acceptance-runbook-skipped-checks
                          :live-run-enabled-p run-live-p)
                         :replay-mode (if run-live-p :live :dry-native)
                         :replay-command command
                         :live-ran-p run-live-p
                         :live-exit-code live-exit-code
                         :live-stdout live-stdout
                         :live-stderr live-stderr)
          (let* ((generated-run
                   (call-hyperdoc-scxml
                    :compile-and-run-scxml-file-with-events
                    *dmx-annotation-local-first-continuation-runbook-scxml*
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
                 (scxml-passed-p
                   (and done-p
                        (scxml-final-state=
                         "accepted"
                         final-state)))
                 (critical-state-ids
                   '("preflightCleanTree"
                     "recordAcceptedCommits"
                     "localFirstSaveWithoutCredentials"
                     "optionalDmxMaterialization"
                     "createTopicFailureEvidenceSmokeSkippedPreTopicUpsert"
                     "guardedContinuationForExistingTopic936040"
                     "workspaceAssignmentReadback919815"
                     "topicmapReadbackIncludes919822"
                     "reopenReconstructsWorkspaceDockAnnotation"
                     "secretLeakageAudit"
                     "liveSmokeReplay"
                     "accepted"))
                 (critical-trace-present-p
                   (every (lambda (state-id)
                            (dmx-annotation-acceptance-trace-contains-state-p
                             trace
                             state-id))
                          critical-state-ids))
                 (live-passed-p
                   (or (not run-live-p)
                       (and (zerop live-exit-code)
                            (dmx-annotation-acceptance-live-pass-lines-observed-p
                             live-stdout))))
                 (passed-p (and scxml-passed-p
                                critical-trace-present-p
                                live-passed-p)))
            (make-instance 'dmx-annotation-acceptance-scxml-run
                           :scxml-path
                           *dmx-annotation-local-first-continuation-runbook-scxml*
                           :accepted-commits
                           (copy-list
                            *dmx-annotation-acceptance-runbook-accepted-commits*)
                           :generated-package generated-package
                           :generated-function generated-function
                           :validation-findings validation-findings
                           :semantic-facts semantic-facts
                           :input-events (copy-list input-events)
                           :trace trace
                           :done-p done-p
                           :passed-p passed-p
                           :final-state final-state
                           :skipped-checks
                           (dmx-annotation-acceptance-runbook-skipped-checks
                            :live-run-enabled-p run-live-p)
                           :replay-mode (if run-live-p :live :dry-native)
                           :replay-command command
                           :live-ran-p run-live-p
                           :live-exit-code live-exit-code
                           :live-stdout live-stdout
                           :live-stderr live-stderr))))))

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
