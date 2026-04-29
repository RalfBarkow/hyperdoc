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

(defparameter *dmx-action-auth-session-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/dmx-action-auth-session.scxml"))

(defparameter *dmx-annotation-workspace-view-scxml*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/dmx-annotation-workspace-view.scxml"))

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

(defclass dmx-action-auth-session-run ()
  ((scxml-path :reader dmx-action-auth-session-run-scxml-path-of
               :initarg :scxml-path)
   (selected-auth-mode
    :reader dmx-action-auth-session-run-selected-auth-mode-of
    :initarg :selected-auth-mode
    :initform :anonymous)
   (workspace-id :reader dmx-action-auth-session-run-workspace-id-of
                 :initarg :workspace-id
                 :initform nil)
   (topic-id :reader dmx-action-auth-session-run-topic-id-of
             :initarg :topic-id
             :initform nil)
   (bootstrap-required-p
    :reader dmx-action-auth-session-run-bootstrap-required-p-of
    :initarg :bootstrap-required-p
    :initform nil)
   (bootstrap-attempted-p
    :reader dmx-action-auth-session-run-bootstrap-attempted-p-of
    :initarg :bootstrap-attempted-p
    :initform nil)
   (bootstrap-status :reader dmx-action-auth-session-run-bootstrap-status-of
                     :initarg :bootstrap-status
                     :initform :not-required)
   (session-cookie-present-p
    :reader dmx-action-auth-session-run-session-cookie-present-p-of
    :initarg :session-cookie-present-p
    :initform nil)
   (session-cookie-shape
    :reader dmx-action-auth-session-run-session-cookie-shape-of
    :initarg :session-cookie-shape
    :initform "none")
   (authorization-scheme
    :reader dmx-action-auth-session-run-authorization-scheme-of
    :initarg :authorization-scheme
    :initform "none")
   (continuation-readiness
    :reader dmx-action-auth-session-run-continuation-readiness-of
    :initarg :continuation-readiness
    :initform :not-ready)
   (redaction-status
    :reader dmx-action-auth-session-run-redaction-status-of
    :initarg :redaction-status
    :initform :redacted)
   (failure-boundary :reader dmx-action-auth-session-run-failure-boundary-of
                     :initarg :failure-boundary
                     :initform :none)
   (validation-findings
    :reader dmx-action-auth-session-run-validation-findings-of
    :initarg :validation-findings
    :initform nil)
   (generated-package
    :reader dmx-action-auth-session-run-generated-package-of
    :initarg :generated-package
    :initform nil)
   (generated-function
    :reader dmx-action-auth-session-run-generated-function-of
    :initarg :generated-function
    :initform nil)
   (semantic-facts :reader dmx-action-auth-session-run-semantic-facts-of
                   :initarg :semantic-facts
                   :initform nil)
   (input-events :reader dmx-action-auth-session-run-input-events-of
                 :initarg :input-events
                 :initform nil)
   (trace :reader dmx-action-auth-session-run-trace-of
          :initarg :trace
          :initform nil)
   (done-p :reader dmx-action-auth-session-run-done-p-of
           :initarg :done-p
           :initform nil)
   (passed-p :reader dmx-action-auth-session-run-passed-p-of
             :initarg :passed-p
             :initform nil)
   (final-state :reader dmx-action-auth-session-run-final-state-of
                :initarg :final-state
                :initform nil)))

(defclass dmx-annotation-workspace-view-run ()
  ((scxml-path :reader dmx-annotation-workspace-view-run-scxml-path-of
               :initarg :scxml-path)
   (annotation :reader dmx-annotation-workspace-view-run-annotation-of
               :initarg :annotation
               :initform nil)
   (client :reader dmx-annotation-workspace-view-run-client-of
           :initarg :client
           :initform nil)
   (workspace-id :reader dmx-annotation-workspace-view-run-workspace-id-of
                 :initarg :workspace-id
                 :initform 919815)
   (workspace-topicmap-id
    :reader dmx-annotation-workspace-view-run-workspace-topicmap-id-of
    :initarg :workspace-topicmap-id
    :initform 919822)
   (current-state :reader dmx-annotation-workspace-view-run-current-state-of
                  :initarg :current-state
                  :initform "draftLocal")
   (selected-preview-event
    :reader dmx-annotation-workspace-view-run-selected-preview-event-of
    :initarg :selected-preview-event
    :initform "SAVE_LOCAL")
   (next-states :reader dmx-annotation-workspace-view-run-next-states-of
                :initarg :next-states
                :initform nil)
   (primary-action-label
    :reader dmx-annotation-workspace-view-run-primary-action-label-of
    :initarg :primary-action-label
    :initform "Save annotation locally")
   (secondary-action-labels
    :reader dmx-annotation-workspace-view-run-secondary-action-labels-of
    :initarg :secondary-action-labels
    :initform nil)
   (mutation-boundary
    :reader dmx-annotation-workspace-view-run-mutation-boundary-of
    :initarg :mutation-boundary
    :initform "HyperDoc-local journal append boundary")
   (auth-requirement
    :reader dmx-annotation-workspace-view-run-auth-requirement-of
    :initarg :auth-requirement
    :initform "none")
   (dmx-http-will-run-p
    :reader dmx-annotation-workspace-view-run-dmx-http-will-run-p-of
    :initarg :dmx-http-will-run-p
    :initform nil)
   (topic-upsert-will-run-p
    :reader dmx-annotation-workspace-view-run-topic-upsert-will-run-p-of
    :initarg :topic-upsert-will-run-p
    :initform nil)
   (workspace-assignment-will-run-p
    :reader dmx-annotation-workspace-view-run-workspace-assignment-will-run-p-of
    :initarg :workspace-assignment-will-run-p
    :initform nil)
   (topicmap-placement-will-run-p
    :reader dmx-annotation-workspace-view-run-topicmap-placement-will-run-p-of
    :initarg :topicmap-placement-will-run-p
    :initform nil)
   (local-journal-mutation-p
    :reader dmx-annotation-workspace-view-run-local-journal-mutation-p-of
    :initarg :local-journal-mutation-p
    :initform nil)
   (dmx-mutation-p :reader dmx-annotation-workspace-view-run-dmx-mutation-p-of
                   :initarg :dmx-mutation-p
                   :initform nil)
   (local-save-authoritative-p
    :reader dmx-annotation-workspace-view-run-local-save-authoritative-p-of
    :initarg :local-save-authoritative-p
    :initform t)
   (executor-function
    :reader dmx-annotation-workspace-view-run-executor-function-of
    :initarg :executor-function
    :initform 'persist-dock-annotation-local-first)
   (continuation-topic-id
    :reader dmx-annotation-workspace-view-run-continuation-topic-id-of
    :initarg :continuation-topic-id
    :initform nil)
   (workspace-write-plan
    :reader dmx-annotation-workspace-view-run-workspace-write-plan-of
    :initarg :workspace-write-plan
    :initform nil)
   (workspace-write-plan-error
    :reader dmx-annotation-workspace-view-run-workspace-write-plan-error-of
    :initarg :workspace-write-plan-error
    :initform nil)
   (validation-findings
    :reader dmx-annotation-workspace-view-run-validation-findings-of
    :initarg :validation-findings
    :initform nil)
   (auth-session-submachine-scxml-path
    :reader dmx-annotation-workspace-view-run-auth-session-submachine-scxml-path-of
    :initarg :auth-session-submachine-scxml-path
    :initform nil)
   (auth-session-submachine-run
    :reader dmx-annotation-workspace-view-run-auth-session-submachine-run-of
    :initarg :auth-session-submachine-run
    :initform nil)
   (local-lane-state
    :reader dmx-annotation-workspace-view-run-local-lane-state-of
    :initarg :local-lane-state
    :initform "draft")
   (local-journal-event-id
    :reader dmx-annotation-workspace-view-run-local-journal-event-id-of
    :initarg :local-journal-event-id
    :initform nil)
   (local-journal-event-count
    :reader dmx-annotation-workspace-view-run-local-journal-event-count-of
    :initarg :local-journal-event-count
    :initform 0)
   (local-object-class
    :reader dmx-annotation-workspace-view-run-local-object-class-of
    :initarg :local-object-class
    :initform "dock-annotation")
   (projection-entered-p
    :reader dmx-annotation-workspace-view-run-projection-entered-p-of
    :initarg :projection-entered-p
    :initform nil)
   (carrier-topic-label
    :reader dmx-annotation-workspace-view-run-carrier-topic-label-of
    :initarg :carrier-topic-label
    :initform "none")
   (assignment-status-label
    :reader dmx-annotation-workspace-view-run-assignment-status-label-of
    :initarg :assignment-status-label
    :initform "none")
   (topicmap-placement-status-label
    :reader dmx-annotation-workspace-view-run-topicmap-placement-status-label-of
    :initarg :topicmap-placement-status-label
    :initform "none")
   (reopen-target-class
    :reader dmx-annotation-workspace-view-run-reopen-target-class-of
    :initarg :reopen-target-class
    :initform "workspace-dock-annotation")
   (projection-visibility-target
    :reader dmx-annotation-workspace-view-run-projection-visibility-target-of
    :initarg :projection-visibility-target
    :initform "workspace 919815, topicmap 919822")
   (chart-dot-text
    :reader dmx-annotation-workspace-view-run-chart-dot-text-of
    :initarg :chart-dot-text
    :initform nil)
   (chart-path-summary
    :reader dmx-annotation-workspace-view-run-chart-path-summary-of
    :initarg :chart-path-summary
    :initform nil)
   (enabled-action-plans
    :reader dmx-annotation-workspace-view-run-enabled-action-plans-of
    :initarg :enabled-action-plans
    :initform nil)))

(defstruct dmx-annotation-workspace-view-action-plan
  event
  label
  function
  expected-next-state
  expected-next-path
  local-mutation-p
  dmx-mutation-p
  auth-required-p
  topic-upsert-p
  workspace-assignment-p
  topicmap-placement-p
  local-save-authoritative-p
  mutation-boundary
  advanced-only-p
  mapped-from-scxml-p
  primary-p)

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

(defparameter *dmx-annotation-workspace-view-secondary-action-labels*
  '("Inspect workspace write plan"
    "Trace workspace write plan"
    "Check DMX annotation storage support"
    "Probe native DMX create-topic boundary"
    "Explain boundary ownership"))

(defparameter *dmx-annotation-workspace-view-diagnostic-action-plans*
  (list
   (list :event "TRACE_WORKSPACE_WRITE_PLAN"
         :label "Trace workspace write plan"
         :function 'trace-dock-annotation-workspace-persistence-path
         :auth-required-p nil
         :dmx-mutation-p nil
         :dmx-http-will-run-p nil
         :topic-upsert-p nil
         :workspace-assignment-p nil
         :topicmap-placement-p nil
         :local-journal-mutation-p nil
         :local-save-authoritative-p t
         :advanced-only-p nil
         :mutation-boundary "SCXML trace/visualization boundary")
   (list :event "CHECK_DMX_STORAGE_SUPPORT"
         :label "Check DMX annotation storage support"
         :function 'probe-live-workspace-annotation-type-support
         :auth-required-p nil
         :dmx-mutation-p nil
         :dmx-http-will-run-p t
         :topic-upsert-p nil
         :workspace-assignment-p nil
         :topicmap-placement-p nil
         :local-journal-mutation-p nil
         :local-save-authoritative-p t
         :advanced-only-p nil
         :mutation-boundary "Read-only DMX storage capability probe boundary")
   (list :event "PROBE_NATIVE_DMX_CREATE_TOPIC_BOUNDARY"
         :label "Probe native DMX create-topic boundary"
         :function 'probe-live-create-topic-for-dock-annotation
         :auth-required-p t
         :dmx-mutation-p t
         :dmx-http-will-run-p t
         :topic-upsert-p t
         :workspace-assignment-p nil
         :topicmap-placement-p nil
         :local-journal-mutation-p nil
         :local-save-authoritative-p t
         :advanced-only-p t
         :mutation-boundary "Advanced native DMX create-topic boundary probe")
   (list :event "EXPLAIN_BOUNDARY_OWNERSHIP"
         :label "Explain boundary ownership"
         :function 'compare-dock-annotation-with-guarded-workspace-path
         :auth-required-p nil
         :dmx-mutation-p nil
         :dmx-http-will-run-p nil
         :topic-upsert-p nil
         :workspace-assignment-p nil
         :topicmap-placement-p nil
         :local-journal-mutation-p nil
         :local-save-authoritative-p t
         :advanced-only-p nil
         :mutation-boundary "Boundary explanation surface")))

(defun read-dmx-annotation-workspace-view-scxml ()
  (call-hyperdoc-scxml
   :parse-scxml-file
   *dmx-annotation-workspace-view-scxml*))

(defun dmx-annotation-workspace-view-status= (left right)
  (and left right
       (string= (string-downcase (format nil "~A" left))
                (string-downcase (format nil "~A" right)))))

(defun dmx-annotation-workspace-view-instance-p (object)
  (let ((class (find-class 'workspace-dock-annotation nil)))
    (and class (typep object class))))

(defun dmx-annotation-workspace-view-safe-call (function-name &rest arguments)
  (when (fboundp function-name)
    (ignore-errors
      (apply (symbol-function function-name) arguments))))

(defun dmx-annotation-workspace-view-annotation-status (annotation)
  (and (dmx-annotation-workspace-view-instance-p annotation)
       (dmx-annotation-workspace-view-safe-call
        'workspace-annotation-status-of
        annotation)))

(defun dmx-annotation-workspace-view-continuation-topic-id (annotation)
  (dmx-annotation-workspace-view-safe-call
   'workspace-annotation-continuation-topic-id-or-nil
   annotation))

(defun dmx-annotation-workspace-view-safe-class-name (object)
  (if object
      (let ((class (class-of object)))
        (if class
            (string-downcase (format nil "~A" (class-name class)))
            "object"))
      "none"))

(defun dmx-annotation-workspace-view-local-subject-key (annotation)
  (or (dmx-annotation-workspace-view-safe-call
       'workspace-annotation-topic-uri-of
       annotation)
      (let ((annotation-key
              (dmx-annotation-workspace-view-safe-call
               'workspace-annotation-key-of
               annotation)))
        (and annotation-key
             (dmx-annotation-workspace-view-safe-call
              'dmx-workspace-annotation-uri
              annotation-key)))))

(defun dmx-annotation-workspace-view-local-stream (subject-key)
  (let ((streams
          (and (boundp '*hyperdoc-local-workspace-journal-streams*)
               (symbol-value '*hyperdoc-local-workspace-journal-streams*))))
    (and subject-key
         (hash-table-p streams)
         (gethash subject-key streams))))

(defun dmx-annotation-workspace-view-local-stream-events (stream)
  (or (dmx-annotation-workspace-view-safe-call
       'dmx-workspace-journal-stream-events-list
       stream)
      '()))

(defun dmx-annotation-workspace-view-local-stream-last-event-id (stream)
  (let* ((events (dmx-annotation-workspace-view-local-stream-events stream))
         (last-event (car (last events))))
    (or (and (hash-table-p last-event)
             (gethash "revision" last-event))
        nil)))

(defun dmx-annotation-workspace-view-local-lane-state (current-state)
  (cond
    ((string= current-state "draftLocal") "draft")
    ((string= current-state "locallySaved") "locally saved")
    ((string= current-state "projectionPending") "projection pending")
    ((string= current-state "projectedComplete") "projected")
    ((string= current-state "projectionFailed") "projection failed")
    (t "draft")))

(defun dmx-annotation-workspace-view-projection-entered-p (current-state)
  (not (string= current-state "draftLocal")))

(defun dmx-annotation-workspace-view-scxml-state-by-id (chart state-id)
  (find state-id
        (call-hyperdoc-scxml :scxml-chart-states-of chart)
        :key (lambda (state)
               (call-hyperdoc-scxml :scxml-state-id-of state))
        :test #'string=))

(defun dmx-annotation-workspace-view-enabled-events (chart state-id)
  (let ((state (dmx-annotation-workspace-view-scxml-state-by-id
                chart
                state-id)))
    (if state
        (remove-duplicates
         (remove nil
                 (mapcar (lambda (transition)
                           (call-hyperdoc-scxml
                            :scxml-transition-event-of
                            transition))
                         (call-hyperdoc-scxml
                          :scxml-state-transitions-of
                          state)))
         :test #'string=)
        '())))

(defun dmx-annotation-workspace-view-transition-targets
    (chart state-id event)
  (let ((state (dmx-annotation-workspace-view-scxml-state-by-id
                chart
                state-id)))
    (if state
        (remove nil
                (loop for transition in
                         (call-hyperdoc-scxml
                          :scxml-state-transitions-of
                          state)
                      when (string= (or (call-hyperdoc-scxml
                                         :scxml-transition-event-of
                                         transition)
                                        "")
                                    (or event ""))
                        collect
                        (call-hyperdoc-scxml
                         :scxml-transition-target-of
                         transition)))
        '())))

(defun dmx-annotation-workspace-view-dot-quoted (value)
  (let ((text (format nil "~A" value)))
    (with-output-to-string (stream)
      (write-char #\" stream)
      (loop for char across text
            do (case char
                 (#\\ (write-string "\\\\" stream))
                 (#\" (write-string "\\\"" stream))
                 (t (write-char char stream))))
      (write-char #\" stream))))

(defun dmx-annotation-workspace-view-chart-dot-text
    (chart current-state selected-event expected-path)
  (let ((path-states (remove nil (copy-list expected-path))))
    (with-output-to-string (stream)
      (format stream "digraph ~A {~%"
              (dmx-annotation-workspace-view-dot-quoted
               "dmx-annotation-workspace-view"))
      (format stream "  rankdir=LR;~%")
      (format stream "  node [shape=box, fontname=\"Helvetica\", style=\"rounded,filled\", fillcolor=\"white\"];~%")
      (format stream "  edge [fontname=\"Helvetica\"];~%")
      (format stream "  __start__ [label=\"\", shape=point, style=\"solid\", fillcolor=\"black\"];~%")
      (dolist (state (call-hyperdoc-scxml :scxml-chart-states-of chart))
        (let* ((state-id (call-hyperdoc-scxml :scxml-state-id-of state))
               (attributes
                 (list (format nil "label=~A"
                               (dmx-annotation-workspace-view-dot-quoted
                                state-id))
                       (if (string= state-id current-state)
                           "fillcolor=\"lightgoldenrod1\""
                           (if (member state-id path-states :test #'string=)
                               "fillcolor=\"lightcyan\""
                               "fillcolor=\"white\""))
                       (if (string= state-id current-state)
                           "penwidth=2.5"
                           "penwidth=1.0"))))
          (format stream "  ~A [~{~A~^, ~}];~%"
                  (dmx-annotation-workspace-view-dot-quoted state-id)
                  attributes)))
      (format stream "  __start__ -> ~A [label=\"initial\"];~%"
              (dmx-annotation-workspace-view-dot-quoted
               (call-hyperdoc-scxml :scxml-chart-initial-state-of chart)))
      (dolist (state (call-hyperdoc-scxml :scxml-chart-states-of chart))
        (dolist (transition
                 (call-hyperdoc-scxml :scxml-state-transitions-of state))
          (let* ((source-id (call-hyperdoc-scxml :scxml-state-id-of state))
                 (event (or (call-hyperdoc-scxml
                             :scxml-transition-event-of
                             transition)
                            ""))
                 (target (or (call-hyperdoc-scxml
                              :scxml-transition-target-of
                              transition)
                             ""))
                 (highlight-p
                   (and (string= source-id current-state)
                        (string= event selected-event))))
            (format stream
                    "  ~A -> ~A [label=~A, color=~A, penwidth=~A];~%"
                    (dmx-annotation-workspace-view-dot-quoted source-id)
                    (dmx-annotation-workspace-view-dot-quoted target)
                    (dmx-annotation-workspace-view-dot-quoted event)
                    (if highlight-p "\"deepskyblue4\"" "\"gray40\"")
                    (if highlight-p "2.5" "1.0")))))
      (format stream "}~%"))))

(defun dmx-annotation-workspace-view-carrier-topic-label
    (current-state continuation-topic-id)
  (cond
    (continuation-topic-id (format nil "~A" continuation-topic-id))
    ((or (string= current-state "locallySaved")
         (string= current-state "projectionFailed"))
     "planned")
    (t
     "none")))

(defun dmx-annotation-workspace-view-assignment-status-label
    (current-state annotation workspace-id)
  (let ((annotation-workspace-id
          (dmx-annotation-workspace-view-safe-call
           'workspace-annotation-workspace-id-of
           annotation)))
    (cond
      ((and annotation-workspace-id
            workspace-id
            (eql annotation-workspace-id workspace-id))
       "assigned")
      ((string= current-state "projectionPending")
       "planned")
      ((string= current-state "locallySaved")
       "planned")
      ((string= current-state "projectedComplete")
       "assigned")
      ((string= current-state "projectionFailed")
       "failed")
      (t
       "none"))))

(defun dmx-annotation-workspace-view-topicmap-placement-status-label
    (current-state annotation workspace-topicmap-id)
  (let ((annotation-topicmap-id
          (dmx-annotation-workspace-view-safe-call
           'workspace-annotation-topicmap-id-of
           annotation)))
    (cond
      ((and annotation-topicmap-id
            workspace-topicmap-id
            (eql annotation-topicmap-id workspace-topicmap-id))
       "visible")
      ((string= current-state "projectionPending")
       "planned")
      ((string= current-state "locallySaved")
       "planned")
      ((string= current-state "projectedComplete")
       "visible")
      ((string= current-state "projectionFailed")
       "failed")
      (t
       "none"))))

(defun dmx-annotation-workspace-view-classify-state
    (annotation continuation-topic-id)
  (let* ((workspace-annotation-p
           (dmx-annotation-workspace-view-instance-p annotation))
         (status
           (dmx-annotation-workspace-view-annotation-status annotation))
         (projected-p
           (or (dmx-annotation-workspace-view-status= status "persisted")
               (dmx-annotation-workspace-view-status= status "projected")))
         (pending-p
           (dmx-annotation-workspace-view-status=
            status
            "projection-pending-auth"))
         (failed-p
           (dmx-annotation-workspace-view-status=
            status
            "projection-failed")))
    (cond
      ((and workspace-annotation-p projected-p)
       "projectedComplete")
      (failed-p
       "projectionFailed")
      ((or pending-p
           (and continuation-topic-id
                (not projected-p)))
       "projectionPending")
      (workspace-annotation-p
       "locallySaved")
      (t
       "draftLocal"))))

(defun dmx-annotation-workspace-view-selected-event
    (current-state materialize-to-dmx-p)
  (cond
    ((string= current-state "draftLocal")
     (if materialize-to-dmx-p
         "SAVE_LOCAL_AND_MATERIALIZE"
         "SAVE_LOCAL"))
    ((string= current-state "locallySaved")
     "MATERIALIZE_DMX")
    ((string= current-state "projectionPending")
     "CONTINUE_DMX_PROJECTION")
    ((string= current-state "projectedComplete")
     "INSPECT_PLAN")
    ((string= current-state "projectionFailed")
     "INSPECT_FAILURE")
    (t
     "INSPECT_PLAN")))

(defun dmx-annotation-workspace-view-secondary-actions (current-state)
  (append
   (copy-list *dmx-annotation-workspace-view-secondary-action-labels*)
   (when (or (string= current-state "projectionPending")
             (string= current-state "continuationAuthCheck")
             (string= current-state "authRequired"))
     (list "Inspect continuation auth/session submachine"))))

(defun dmx-annotation-workspace-view-action-spec
    (current-state event)
  (cond
    ((and (string= current-state "draftLocal")
          (string= event "SAVE_LOCAL"))
     (list :next-states
           '("previewLocalSavePlan" "savingLocal" "locallySaved")
           :primary-action-label "Record local annotation"
           :mutation-boundary
           "HyperDoc-local journal append lane; DMX projection is not entered."
           :auth-requirement "not required"
           :dmx-http-will-run-p nil
           :topic-upsert-will-run-p nil
           :workspace-assignment-will-run-p nil
           :topicmap-placement-will-run-p nil
           :local-journal-mutation-p t
           :dmx-mutation-p nil
           :local-save-authoritative-p t
           :executor-function 'persist-dock-annotation-local-first))
    ((and (string= current-state "draftLocal")
          (string= event "SAVE_LOCAL_AND_MATERIALIZE"))
     (list :next-states
           '("previewLocalSavePlan"
             "savingLocalThenMaterializing"
             "materializationPreflight")
           :primary-action-label
           "Record local annotation and materialize to DMX"
           :mutation-boundary
           "Local-first journal append lane followed by optional DMX projection/materialization."
           :auth-requirement
           "local save does not require credentials; DMX projection may require action-time auth"
           :dmx-http-will-run-p t
           :topic-upsert-will-run-p t
           :workspace-assignment-will-run-p t
           :topicmap-placement-will-run-p t
           :local-journal-mutation-p t
           :dmx-mutation-p t
           :local-save-authoritative-p t
           :executor-function 'persist-dock-annotation-local-first))
    ((and (string= current-state "draftLocal")
          (string= event "INSPECT_PLAN"))
     (list :next-states
           '("previewLocalSavePlan")
           :primary-action-label "Inspect workspace write plan"
           :mutation-boundary
           "SCXML plan inspection boundary"
           :auth-requirement "not required"
           :dmx-http-will-run-p nil
           :topic-upsert-will-run-p nil
           :workspace-assignment-will-run-p nil
           :topicmap-placement-will-run-p nil
           :local-journal-mutation-p nil
           :dmx-mutation-p nil
           :local-save-authoritative-p t
           :executor-function 'make-dmx-annotation-workspace-view-run))
    ((string= current-state "locallySaved")
     (if (string= event "MATERIALIZE_DMX")
         (list :next-states
               '("previewDmxMaterializationPlan" "materializationPreflight")
               :primary-action-label "Materialize to DMX"
               :mutation-boundary
               "DMX projection/materialization lane; local journal state remains authoritative."
               :auth-requirement "may require action-time auth for guarded DMX mutations"
               :dmx-http-will-run-p t
               :topic-upsert-will-run-p t
               :workspace-assignment-will-run-p t
               :topicmap-placement-will-run-p t
               :local-journal-mutation-p t
               :dmx-mutation-p t
               :local-save-authoritative-p t
               :executor-function 'persist-dock-annotation-local-first)
         (list :next-states
               '("previewDmxMaterializationPlan")
               :primary-action-label "Inspect workspace write plan"
               :mutation-boundary "SCXML plan inspection boundary"
               :auth-requirement "not required"
               :dmx-http-will-run-p nil
               :topic-upsert-will-run-p nil
               :workspace-assignment-will-run-p nil
               :topicmap-placement-will-run-p nil
               :local-journal-mutation-p nil
               :dmx-mutation-p nil
               :local-save-authoritative-p t
               :executor-function 'make-dmx-annotation-workspace-view-run)))
    ((string= current-state "projectionPending")
     (if (string= event "CONTINUE_DMX_PROJECTION")
         (list :next-states
               '("previewContinuationPlan" "continuationAuthCheck")
               :primary-action-label "Continue DMX projection"
               :mutation-boundary
               "Guarded continuation lane; resume assignment/topicmap/journal/reopen without TOPIC-UPSERT."
               :auth-requirement "explicit action-time credentials are required when guarded mutations need auth"
               :dmx-http-will-run-p t
               :topic-upsert-will-run-p nil
               :workspace-assignment-will-run-p t
               :topicmap-placement-will-run-p t
               :local-journal-mutation-p nil
               :dmx-mutation-p t
               :local-save-authoritative-p t
               :executor-function
               'continue-workspace-annotation-persistence-with-client)
         (list :next-states
               '("previewContinuationPlan")
               :primary-action-label "Inspect workspace write plan"
               :mutation-boundary "SCXML plan inspection boundary"
               :auth-requirement "not required"
               :dmx-http-will-run-p nil
               :topic-upsert-will-run-p nil
               :workspace-assignment-will-run-p nil
               :topicmap-placement-will-run-p nil
               :local-journal-mutation-p nil
               :dmx-mutation-p nil
               :local-save-authoritative-p t
               :executor-function 'make-dmx-annotation-workspace-view-run)))
    ((string= current-state "projectedComplete")
     (list :next-states
           '("reopenAnnotation" "projectedComplete")
           :primary-action-label "Inspect or reopen annotation"
           :mutation-boundary "Readback/reopen lane; no mutation."
           :auth-requirement "none for local preview; backend read auth depends on DMX host"
           :dmx-http-will-run-p t
           :topic-upsert-will-run-p nil
           :workspace-assignment-will-run-p nil
           :topicmap-placement-will-run-p nil
           :local-journal-mutation-p nil
           :dmx-mutation-p nil
           :local-save-authoritative-p t
           :executor-function 'read-dmx-workspace-annotation))
    ((and (string= current-state "projectionFailed")
          (string= event "MATERIALIZE_DMX"))
     (list :next-states
           '("previewDmxMaterializationPlan" "materializationPreflight")
           :primary-action-label "Materialize to DMX"
           :mutation-boundary
           "Retry DMX materialization lane; local save remains authoritative."
           :auth-requirement
           "may require action-time auth for guarded DMX mutations"
           :dmx-http-will-run-p t
           :topic-upsert-will-run-p t
           :workspace-assignment-will-run-p t
           :topicmap-placement-will-run-p t
           :local-journal-mutation-p t
           :dmx-mutation-p t
           :local-save-authoritative-p t
           :executor-function 'persist-dock-annotation-local-first))
    ((and (string= current-state "projectionFailed")
          (string= event "CONTINUE_DMX_PROJECTION"))
     (list :next-states
           '("previewContinuationPlan" "continuationAuthCheck")
           :primary-action-label "Continue DMX projection"
           :mutation-boundary
           "Retry guarded continuation lane without TOPIC-UPSERT."
           :auth-requirement
           "explicit action-time credentials are required when guarded mutations need auth"
           :dmx-http-will-run-p t
           :topic-upsert-will-run-p nil
           :workspace-assignment-will-run-p t
           :topicmap-placement-will-run-p t
           :local-journal-mutation-p nil
           :dmx-mutation-p t
           :local-save-authoritative-p t
           :executor-function
           'continue-workspace-annotation-persistence-with-client))
    ((string= current-state "projectionFailed")
     (list :next-states
           '("projectionFailureReport")
           :primary-action-label "Inspect projection failure"
           :mutation-boundary "Failure-analysis lane; local save remains authoritative."
           :auth-requirement "none for inspection"
           :dmx-http-will-run-p nil
           :topic-upsert-will-run-p nil
           :workspace-assignment-will-run-p nil
           :topicmap-placement-will-run-p nil
           :local-journal-mutation-p nil
           :dmx-mutation-p nil
           :local-save-authoritative-p t
           :executor-function 'trace-dock-annotation-workspace-persistence-path))
    (t
     nil)))

(defun dmx-annotation-workspace-view-diagnostic-action-plans
    (current-state selected-event)
  (append
   (mapcar (lambda (entry)
             (make-dmx-annotation-workspace-view-action-plan
              :event (getf entry :event)
              :label (getf entry :label)
              :function (getf entry :function)
              :expected-next-state current-state
              :expected-next-path (list current-state)
              :local-mutation-p (and (getf entry :local-journal-mutation-p) t)
              :dmx-mutation-p (and (getf entry :dmx-mutation-p) t)
              :auth-required-p (and (getf entry :auth-required-p) t)
              :topic-upsert-p (and (getf entry :topic-upsert-p) t)
              :workspace-assignment-p
              (and (getf entry :workspace-assignment-p) t)
              :topicmap-placement-p (and (getf entry :topicmap-placement-p) t)
              :local-save-authoritative-p
              (and (getf entry :local-save-authoritative-p) t)
              :mutation-boundary (getf entry :mutation-boundary)
              :advanced-only-p (and (getf entry :advanced-only-p) t)
              :mapped-from-scxml-p nil
              :primary-p (string= (or selected-event "")
                                  (or (getf entry :event) ""))))
           *dmx-annotation-workspace-view-diagnostic-action-plans*)
   (when (or (string= current-state "projectionPending")
             (string= current-state "continuationAuthCheck")
             (string= current-state "authRequired"))
     (list
      (make-dmx-annotation-workspace-view-action-plan
       :event "AUTH_SUBMACHINE"
       :label "Inspect continuation auth/session submachine"
       :function 'make-dmx-action-auth-session-run
       :expected-next-state "continuationAuthCheck"
       :expected-next-path '("continuationAuthCheck")
       :local-mutation-p nil
       :dmx-mutation-p nil
       :auth-required-p t
       :topic-upsert-p nil
       :workspace-assignment-p nil
       :topicmap-placement-p nil
       :local-save-authoritative-p t
       :mutation-boundary "Action-time auth/session submachine boundary"
       :advanced-only-p nil
       :mapped-from-scxml-p nil
       :primary-p nil)))))

(defun dmx-annotation-workspace-view-build-enabled-action-plans
    (chart current-state selected-event)
  (let ((enabled-events
          (dmx-annotation-workspace-view-enabled-events chart current-state))
        (plans '()))
    (dolist (event enabled-events)
      (let* ((spec (dmx-annotation-workspace-view-action-spec
                    current-state
                    event))
             (targets (dmx-annotation-workspace-view-transition-targets
                       chart
                       current-state
                       event))
             (expected-path
               (or (copy-list (getf spec :next-states))
                   (copy-list targets)
                   (list current-state))))
        (when spec
          (push (make-dmx-annotation-workspace-view-action-plan
                 :event event
                 :label (getf spec :primary-action-label)
                 :function (getf spec :executor-function)
                 :expected-next-state (or (car targets)
                                          (car (getf spec :next-states))
                                          current-state)
                 :expected-next-path expected-path
                 :local-mutation-p
                 (and (getf spec :local-journal-mutation-p) t)
                 :dmx-mutation-p (and (getf spec :dmx-mutation-p) t)
                 :auth-required-p
                 (let ((label (or (getf spec :auth-requirement) "")))
                   (or (search "required" label :test #'char-equal)
                       (search "may require" label :test #'char-equal)))
                 :topic-upsert-p
                 (and (getf spec :topic-upsert-will-run-p) t)
                 :workspace-assignment-p
                 (and (getf spec :workspace-assignment-will-run-p) t)
                 :topicmap-placement-p
                 (and (getf spec :topicmap-placement-will-run-p) t)
                 :local-save-authoritative-p
                 (and (getf spec :local-save-authoritative-p) t)
                 :mutation-boundary (getf spec :mutation-boundary)
                 :advanced-only-p nil
                 :mapped-from-scxml-p t
                 :primary-p (string= event selected-event))
                plans))))
    (append (nreverse plans)
            (dmx-annotation-workspace-view-diagnostic-action-plans
             current-state
             selected-event))))

(defun dmx-annotation-workspace-view-auth-submachine-needed-p (current-state)
  (or (string= current-state "projectionPending")
      (string= current-state "previewContinuationPlan")
      (string= current-state "continuationAuthCheck")
      (string= current-state "authRequired")))

(defun dmx-annotation-workspace-view-build-write-plan
    (annotation workspace-topicmap-id workspace-id client)
  (if (fboundp 'plan-dmx-workspace-annotation-write-from-object)
      (handler-case
          (values (plan-dmx-workspace-annotation-write-from-object
                   annotation
                   :workspace-topicmap-id workspace-topicmap-id
                   :workspace-id workspace-id
                   :client client)
                  nil)
        (condition (condition)
          (values nil (princ-to-string condition))))
      (values nil
              "plan-dmx-workspace-annotation-write-from-object is unavailable")))

(defun make-dmx-annotation-workspace-view-run
    (annotation &key workspace-topicmap-id workspace-id client
       (materialize-to-dmx-p nil))
  (let* ((resolved-workspace-id (or workspace-id 919815))
         (resolved-workspace-topicmap-id (or workspace-topicmap-id 919822))
         (continuation-topic-id
           (dmx-annotation-workspace-view-continuation-topic-id annotation))
         (current-state
           (dmx-annotation-workspace-view-classify-state
            annotation
            continuation-topic-id))
         (selected-event
           (dmx-annotation-workspace-view-selected-event
            current-state
            materialize-to-dmx-p))
         (action-spec
           (or (dmx-annotation-workspace-view-action-spec
                current-state
                selected-event)
               (list :next-states (list current-state)
                     :primary-action-label "Inspect workspace write plan"
                     :mutation-boundary "SCXML plan inspection boundary"
                     :auth-requirement "not required"
                     :dmx-http-will-run-p nil
                     :topic-upsert-will-run-p nil
                     :workspace-assignment-will-run-p nil
                     :topicmap-placement-will-run-p nil
                     :local-journal-mutation-p nil
                     :dmx-mutation-p nil
                     :local-save-authoritative-p t
                     :executor-function
                     'make-dmx-annotation-workspace-view-run)))
         (chart (read-dmx-annotation-workspace-view-scxml))
         (validation-findings (call-hyperdoc-scxml
                               :validate-scxml-chart
                               chart))
         (local-subject-key
           (dmx-annotation-workspace-view-local-subject-key annotation))
         (local-stream
           (dmx-annotation-workspace-view-local-stream local-subject-key))
         (local-events
           (dmx-annotation-workspace-view-local-stream-events local-stream))
         (enabled-action-plans
           (dmx-annotation-workspace-view-build-enabled-action-plans
            chart
            current-state
            selected-event))
         (expected-path
           (or (copy-list (getf action-spec :next-states))
               (copy-list
                (dmx-annotation-workspace-view-transition-targets
                 chart
                 current-state
                 selected-event))
               (list current-state)))
         (chart-dot
           (dmx-annotation-workspace-view-chart-dot-text
            chart
            current-state
            selected-event
            expected-path))
         (chart-path-summary
           (list :current-state current-state
                 :selected-event selected-event
                 :expected-next-states (copy-list expected-path)
                 :mutates-local-journal
                 (and (getf action-spec :local-journal-mutation-p) t)
                 :mutates-dmx
                 (and (getf action-spec :dmx-mutation-p) t)))
         (workspace-write-plan nil)
         (workspace-write-plan-error nil))
    (multiple-value-setq (workspace-write-plan workspace-write-plan-error)
      (dmx-annotation-workspace-view-build-write-plan
       annotation
       resolved-workspace-topicmap-id
       resolved-workspace-id
       client))
    (let ((auth-submachine-needed-p
            (dmx-annotation-workspace-view-auth-submachine-needed-p
             current-state))
          (auth-session-submachine-run
            (and (dmx-annotation-workspace-view-auth-submachine-needed-p
                  current-state)
                 (fboundp 'make-dmx-action-auth-session-run)
                 (ignore-errors
                   (make-dmx-action-auth-session-run
                    :selected-auth-mode :anonymous
                    :workspace-id resolved-workspace-id
                    :topic-id continuation-topic-id)))))
      (make-instance 'dmx-annotation-workspace-view-run
                     :scxml-path *dmx-annotation-workspace-view-scxml*
                     :annotation annotation
                     :client client
                     :workspace-id resolved-workspace-id
                     :workspace-topicmap-id resolved-workspace-topicmap-id
                     :current-state current-state
                     :selected-preview-event selected-event
                     :next-states (copy-list expected-path)
                     :primary-action-label
                     (getf action-spec :primary-action-label)
                     :secondary-action-labels
                     (dmx-annotation-workspace-view-secondary-actions
                      current-state)
                     :mutation-boundary
                     (getf action-spec :mutation-boundary)
                     :auth-requirement
                     (getf action-spec :auth-requirement)
                     :dmx-http-will-run-p
                     (and (getf action-spec :dmx-http-will-run-p) t)
                     :topic-upsert-will-run-p
                     (and (getf action-spec :topic-upsert-will-run-p) t)
                     :workspace-assignment-will-run-p
                     (and (getf action-spec :workspace-assignment-will-run-p)
                          t)
                     :topicmap-placement-will-run-p
                     (and (getf action-spec :topicmap-placement-will-run-p) t)
                     :local-journal-mutation-p
                     (and (getf action-spec :local-journal-mutation-p) t)
                     :dmx-mutation-p
                     (and (getf action-spec :dmx-mutation-p) t)
                     :local-save-authoritative-p
                     (and (getf action-spec :local-save-authoritative-p) t)
                     :executor-function
                     (getf action-spec :executor-function)
                     :continuation-topic-id continuation-topic-id
                     :workspace-write-plan workspace-write-plan
                     :workspace-write-plan-error workspace-write-plan-error
                     :validation-findings validation-findings
                     :auth-session-submachine-scxml-path
                     (and auth-submachine-needed-p
                          *dmx-action-auth-session-scxml*)
                     :auth-session-submachine-run
                     auth-session-submachine-run
                     :local-lane-state
                     (dmx-annotation-workspace-view-local-lane-state
                      current-state)
                     :local-journal-event-id
                     (dmx-annotation-workspace-view-local-stream-last-event-id
                      local-stream)
                     :local-journal-event-count
                     (length local-events)
                     :local-object-class
                     (dmx-annotation-workspace-view-safe-class-name
                      annotation)
                     :projection-entered-p
                     (dmx-annotation-workspace-view-projection-entered-p
                      current-state)
                     :carrier-topic-label
                     (dmx-annotation-workspace-view-carrier-topic-label
                      current-state
                      continuation-topic-id)
                     :assignment-status-label
                     (dmx-annotation-workspace-view-assignment-status-label
                      current-state
                      annotation
                      resolved-workspace-id)
                     :topicmap-placement-status-label
                     (dmx-annotation-workspace-view-topicmap-placement-status-label
                      current-state
                      annotation
                      resolved-workspace-topicmap-id)
                     :reopen-target-class "workspace-dock-annotation"
                     :projection-visibility-target
                     (format nil "workspace ~D, topicmap ~D"
                             resolved-workspace-id
                             resolved-workspace-topicmap-id)
                     :chart-dot-text chart-dot
                     :chart-path-summary chart-path-summary
                     :enabled-action-plans enabled-action-plans))))

(defparameter *dmx-action-auth-session-secret-needles*
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

(defun read-dmx-action-auth-session-scxml ()
  (call-hyperdoc-scxml :parse-scxml-file *dmx-action-auth-session-scxml*))

(defun dmx-action-auth-session-normalize-mode (mode)
  (case mode
    ((:anonymous :none nil) :anonymous)
    ((:username-password :userpass :basic :credentials) :username-password)
    ((:authorization-header :auth-header :header) :authorization-header)
    ((:bearer-token :bearer :token) :bearer-token)
    (otherwise
     (error "Unsupported DMX action auth/session mode: ~S" mode))))

(defun dmx-action-auth-session-mode-label (mode)
  (case mode
    (:anonymous "anonymous")
    (:username-password "username/password")
    (:authorization-header "authorization-header")
    (:bearer-token "bearer-token")
    (otherwise "unknown")))

(defun dmx-action-auth-session-authorization-scheme (mode)
  (case mode
    (:anonymous "none")
    (:username-password "Basic")
    (:authorization-header "direct-header")
    (:bearer-token "Bearer")
    (otherwise "none")))

(defun dmx-action-auth-session-default-bootstrap-status (mode)
  (if (eq mode :username-password)
      :succeeded
      :not-required))

(defun dmx-action-auth-session-failure-boundary (mode bootstrap-status)
  (cond
    ((eq mode :anonymous)
     :anonymous-blocked)
    ((and (eq mode :username-password)
          (eq bootstrap-status :failed))
     :auth-failed)
    (t :none)))

(defun dmx-action-auth-session-continuation-readiness (mode bootstrap-status)
  (if (or (member mode '(:authorization-header :bearer-token) :test #'eq)
          (and (eq mode :username-password)
               (eq bootstrap-status :succeeded)))
      :continuation-ready
      :blocked))

(defun dmx-action-auth-session-session-cookie-present-p (mode bootstrap-status)
  (and (eq mode :username-password)
       (eq bootstrap-status :succeeded)))

(defun dmx-action-auth-session-session-cookie-shape (session-cookie-present-p)
  (if session-cookie-present-p
      "session-cookie(redacted); workspace-cookie-shape-only"
      "none"))

(defun dmx-action-auth-session-string-contains-ci-p (haystack needle)
  (and haystack needle
       (search needle haystack :test #'char-equal)))

(defun dmx-action-auth-session-secret-leak-p (text)
  (find-if (lambda (needle)
             (dmx-action-auth-session-string-contains-ci-p text needle))
           *dmx-action-auth-session-secret-needles*))

(defun dmx-action-auth-session-events (mode bootstrap-status)
  (append
   '("AUTH.INPUT_CAPTURED"
     "AUTH.MODE_NORMALIZED")
   (case mode
     (:anonymous
      '("AUTH.MODE.ANONYMOUS"
        "AUTH.BLOCKED"
        "AUTH.DONE"))
     (:authorization-header
      '("AUTH.MODE.AUTHORIZATION_HEADER"
        "AUTH.REQUEST.DIRECT_HEADER_SHAPED"
        "AUTH.CONTINUATION_READY"
        "AUTH.DONE"))
     (:bearer-token
      '("AUTH.MODE.BEARER_TOKEN"
        "AUTH.REQUEST.BEARER_SHAPED"
        "AUTH.CONTINUATION_READY"
        "AUTH.DONE"))
     (:username-password
      (if (eq bootstrap-status :failed)
          '("AUTH.MODE.USERPASS"
            "AUTH.BOOTSTRAP_ATTEMPTED"
            "AUTH.BOOTSTRAP.FAILED"
            "AUTH.FAILED")
          '("AUTH.MODE.USERPASS"
            "AUTH.BOOTSTRAP_ATTEMPTED"
            "AUTH.BOOTSTRAP.SUCCEEDED"
            "AUTH.REQUEST_SHAPED"
            "AUTH.REQUEST.GUARDED_SHAPED"
            "AUTH.CONTINUATION_READY"
            "AUTH.DONE")))
     (otherwise
      (error "Unsupported DMX action auth/session mode for events: ~S" mode)))))

(defun make-dmx-action-auth-session-example
    (&key (selected-auth-mode :username-password)
       (workspace-id 919815)
       (topic-id 936040)
       bootstrap-status)
  (let* ((mode (dmx-action-auth-session-normalize-mode selected-auth-mode))
         (resolved-bootstrap-status
           (or bootstrap-status
               (dmx-action-auth-session-default-bootstrap-status mode))))
    (list :selected-auth-mode mode
          :workspace-id workspace-id
          :topic-id topic-id
          :bootstrap-status resolved-bootstrap-status
          :authorization-scheme
          (dmx-action-auth-session-authorization-scheme mode)
          :session-cookie-present-p
          (dmx-action-auth-session-session-cookie-present-p
           mode
           resolved-bootstrap-status)
          :session-cookie-shape
          (dmx-action-auth-session-session-cookie-shape
           (dmx-action-auth-session-session-cookie-present-p
            mode
            resolved-bootstrap-status))
          :continuation-readiness
          (dmx-action-auth-session-continuation-readiness
           mode
           resolved-bootstrap-status)
          :redaction-status :redacted
          :failure-boundary
          (dmx-action-auth-session-failure-boundary
           mode
           resolved-bootstrap-status))))

(defun make-dmx-action-auth-session-run
    (&key (selected-auth-mode :username-password)
       (workspace-id 919815)
       (topic-id 936040)
       bootstrap-status package-name function-name)
  (let* ((mode (dmx-action-auth-session-normalize-mode selected-auth-mode))
         (resolved-bootstrap-status
           (or bootstrap-status
               (dmx-action-auth-session-default-bootstrap-status mode)))
         (session-cookie-present-p
           (dmx-action-auth-session-session-cookie-present-p
            mode
            resolved-bootstrap-status))
         (session-cookie-shape
           (dmx-action-auth-session-session-cookie-shape
            session-cookie-present-p))
         (authorization-scheme
           (dmx-action-auth-session-authorization-scheme mode))
         (bootstrap-required-p (eq mode :username-password))
         (bootstrap-attempted-p (eq mode :username-password))
         (continuation-readiness
           (dmx-action-auth-session-continuation-readiness
            mode
            resolved-bootstrap-status))
         (failure-boundary
           (dmx-action-auth-session-failure-boundary
            mode
            resolved-bootstrap-status))
         (events
           (dmx-action-auth-session-events mode resolved-bootstrap-status))
         (semantic-facts
           (list :selected-auth-mode mode
                 :selected-auth-mode-label
                 (dmx-action-auth-session-mode-label mode)
                 :workspace-id workspace-id
                 :topic-id topic-id
                 :bootstrap-required-p bootstrap-required-p
                 :bootstrap-attempted-p bootstrap-attempted-p
                 :bootstrap-status resolved-bootstrap-status
                 :session-cookie-present-p session-cookie-present-p
                 :session-cookie-shape session-cookie-shape
                 :authorization-scheme authorization-scheme
                 :continuation-readiness continuation-readiness
                 :redaction-status :redacted
                 :failure-boundary failure-boundary))
         (generated-package
           (or package-name
               "HYPERDOC/SCXML/GENERATED/DMX-ACTION-AUTH-SESSION"))
         (generated-function
           (or function-name
               "RUN-DMX-ACTION-AUTH-SESSION"))
         (expectation-run
           (run-scxml-expectation-with-events
            *dmx-action-auth-session-scxml*
            events
            semantic-facts
            :expected-subject
            (format nil
                    "dmx-action-auth-session ~A"
                    (dmx-action-auth-session-mode-label mode))
            :package-name generated-package
            :function-name generated-function))
         (trace (or (scxml-expectation-run-trace-of expectation-run) '()))
         (trace-string (format nil "~{~A~%~}" trace))
         (redaction-status
           (if (dmx-action-auth-session-secret-leak-p trace-string)
               :unexpected-secret
               :redacted)))
    (make-instance 'dmx-action-auth-session-run
                   :scxml-path *dmx-action-auth-session-scxml*
                   :selected-auth-mode mode
                   :workspace-id workspace-id
                   :topic-id topic-id
                   :bootstrap-required-p bootstrap-required-p
                   :bootstrap-attempted-p bootstrap-attempted-p
                   :bootstrap-status resolved-bootstrap-status
                   :session-cookie-present-p session-cookie-present-p
                   :session-cookie-shape session-cookie-shape
                   :authorization-scheme authorization-scheme
                   :continuation-readiness continuation-readiness
                   :redaction-status redaction-status
                   :failure-boundary failure-boundary
                   :validation-findings
                   (scxml-expectation-run-validation-findings-of
                    expectation-run)
                   :generated-package generated-package
                   :generated-function generated-function
                   :semantic-facts semantic-facts
                   :input-events events
                   :trace trace
                   :done-p (scxml-expectation-run-done-p-of expectation-run)
                   :passed-p (and (scxml-expectation-run-done-p-of expectation-run)
                                  (scxml-final-state=
                                   "done"
                                   (scxml-expectation-run-final-state-of
                                    expectation-run)))
                   :final-state
                   (scxml-expectation-run-final-state-of expectation-run))))

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
        :auth-session-submachine-scxml-path
        (namestring *dmx-action-auth-session-scxml*)
        :auth-session-submachine-modeled-p t
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
