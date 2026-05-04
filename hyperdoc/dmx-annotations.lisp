;;;; Typed DMX workspace annotations for Dock relations
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defparameter *hyperdoc-workspace-annotation-uri-prefix*
  "hyperdoc:mcp/workspace-annotation/")

(defparameter *dmx-workspace-annotation-type-uri*
  "hyperdoc.annotation")
(defparameter *dmx-workspace-annotation-native-storage-mode*
  :native-annotation)
(defparameter *dmx-workspace-annotation-compatibility-storage-mode*
  :compatibility-note-carrier)
(defparameter *dmx-workspace-annotation-compatibility-storage-mode-name*
  "compatibility-note-carrier")
(defparameter *dmx-workspace-annotation-compatibility-envelope-version*
  1)
(defparameter *workspace-annotation-explicit-auth-retry-evidence-version*
  1)
(defparameter *dmx-workspace-annotation-compatibility-carrier-type-uri*
  *dmx-notes-note-type-uri*)
(defparameter *dmx-workspace-annotation-title-type-uri*
  "hyperdoc.annotation.title")
(defparameter *dmx-workspace-annotation-summary-type-uri*
  "hyperdoc.annotation.summary")
(defparameter *dmx-workspace-annotation-text-type-uri*
  "hyperdoc.annotation.text")
(defparameter *dmx-workspace-annotation-relation-kind-type-uri*
  "hyperdoc.annotation.relation_kind")
(defparameter *dmx-workspace-annotation-status-type-uri*
  "hyperdoc.annotation.status")
(defparameter *dmx-workspace-annotation-source-anchor-json-type-uri*
  "hyperdoc.annotation.source_anchor_json")
(defparameter *dmx-workspace-annotation-target-anchor-json-type-uri*
  "hyperdoc.annotation.target_anchor_json")
(defparameter *dmx-workspace-annotation-context-object-id-type-uri*
  "hyperdoc.annotation.context_object_id")
(defparameter *dmx-workspace-annotation-context-view-title-type-uri*
  "hyperdoc.annotation.context_view_title")
(defparameter *dmx-workspace-annotation-source-object-ref-type-uri*
  "hyperdoc.annotation.source_object_ref")
(defparameter *dmx-workspace-annotation-target-object-ref-type-uri*
  "hyperdoc.annotation.target_object_ref")
(defparameter *dmx-workspace-annotation-runtime-relation-id-type-uri*
  "hyperdoc.annotation.runtime_relation_id")
(defparameter *dmx-workspace-annotation-provenance-type-uri*
  "hyperdoc.annotation.provenance_json")
(defparameter *dmx-workspace-annotation-workspace-topicmap-type-uri*
  "hyperdoc.annotation.workspace_topicmap_id")
(defparameter *dmx-workspace-annotation-source-binding-type-uri*
  "hyperdoc.annotation.source_binding")
(defparameter *dmx-workspace-annotation-target-binding-type-uri*
  "hyperdoc.annotation.target_binding")
(defparameter *dmx-workspace-annotation-context-binding-type-uri*
  "hyperdoc.annotation.context_binding")
(defparameter *dmx-workspace-annotation-supersedes-type-uri*
  "hyperdoc.annotation.supersedes")

(defparameter *dmx-workspace-annotation-required-live-child-type-uris*
  (list *dmx-workspace-annotation-title-type-uri*
        *dmx-workspace-annotation-summary-type-uri*
        *dmx-workspace-annotation-text-type-uri*
        *dmx-workspace-annotation-relation-kind-type-uri*
        *dmx-workspace-annotation-status-type-uri*
        *dmx-workspace-annotation-source-anchor-json-type-uri*
        *dmx-workspace-annotation-target-anchor-json-type-uri*
        *dmx-workspace-annotation-context-object-id-type-uri*
        *dmx-workspace-annotation-context-view-title-type-uri*
        *dmx-workspace-annotation-source-object-ref-type-uri*
        *dmx-workspace-annotation-target-object-ref-type-uri*
        *dmx-workspace-annotation-runtime-relation-id-type-uri*
        *dmx-workspace-annotation-provenance-type-uri*
        *dmx-workspace-annotation-workspace-topicmap-type-uri*
        *dmx-workspace-annotation-source-binding-type-uri*
        *dmx-workspace-annotation-target-binding-type-uri*
        *dmx-workspace-annotation-context-binding-type-uri*
        *dmx-workspace-annotation-supersedes-type-uri*))
(defparameter *dmx-workspace-annotation-compatibility-required-live-type-uris*
  (list *dmx-notes-note-type-uri*
        *dmx-notes-title-type-uri*
        *dmx-notes-text-type-uri*))

(defparameter *dmx-workspace-annotation-known-live-create-topic-response-body*
  "{\"error\":\"Creating topic of type \\\"hyperdoc.annotation\\\" failed\",\"cause\":\"java.lang.RuntimeException: Topic type \\\"hyperdoc.annotation\\\" not found in DB\"}")

(defstruct dmx-workspace-annotation-destination
  workspace-id
  workspace-topicmap-id
  source
  workspace-source
  topicmap-source
  rationale)

(defstruct dmx-workspace-annotation-resolution
  annotation-key
  uri
  destination
  workspace-topicmap-id
  workspace-id
  storage-mode
  carrier-type-uri
  existing-topic
  existing-topic-id
  current-workspace-id
  in-topicmap-p
  topic-action
  workspace-action
  topicmap-action)

(defstruct dmx-workspace-annotation-write-plan
  operation
  annotation-key
  uri
  destination
  workspace-topicmap-id
  workspace-id
  title
  summary
  text
  relation-kind
  status
  source-anchor-json
  target-anchor-json
  context-object-id
  context-view-title
  source-object-ref
  target-object-ref
  runtime-relation-id
  provenance-json
  supersedes-topic-id
  view-props
  view-props-normalization
  payload-validation-status
  storage-mode
  carrier-type-uri
  topic-action
  workspace-action
  topicmap-action
  payload
  existing-topic
  existing-topic-id
  current-workspace-id)

(defparameter *dmx-workspace-annotation-persistence-stage-order*
  '(:normalize-annotation
    :build-write-plan
    :validate-payload
    :prepare-transition
    :topic-upsert
    :workspace-assignment
    :topicmap-placement
    :journal-transition
    :reopen-persisted-annotation))

(defparameter *dmx-workspace-annotation-path-diff-stage-order*
  '(:normalize-annotation
    :build-write-plan
    :validate-payload
    :backend-compatibility-preflight
    :topic-upsert
    :workspace-assignment
    :topicmap-placement
    :journal-transition
    :reopen-persisted-annotation))

(defparameter *dmx-workspace-annotation-live-report-stage-order*
  '(:topic-upsert
    :workspace-assignment
    :topicmap-placement
    :journal-transition
    :reopen-persisted-annotation))

(defclass workspace-annotation-persistence-debug ()
  ((annotation
    :initarg :annotation
    :reader workspace-annotation-persistence-debug-annotation-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader workspace-annotation-persistence-debug-workspace-topicmap-id-of)
   (workspace-id
    :initarg :workspace-id
    :initform nil
   :reader workspace-annotation-persistence-debug-workspace-id-of)
   (destination
    :initarg :destination
    :initform nil
    :reader workspace-annotation-persistence-debug-destination-of)
   (client
    :initarg :client
    :initform nil
    :reader workspace-annotation-persistence-debug-client-of)
   (view-props
    :initarg :view-props
    :initform nil
    :reader workspace-annotation-persistence-debug-view-props-of)
   (requested-status
    :initarg :requested-status
    :initform nil
    :reader workspace-annotation-persistence-debug-requested-status-of)
   (supersedes-topic-id
    :initarg :supersedes-topic-id
    :initform nil
    :reader workspace-annotation-persistence-debug-supersedes-topic-id-of)
   (annotation-key-override
    :initarg :annotation-key-override
    :initform nil
    :reader workspace-annotation-persistence-debug-annotation-key-override-of)
   (provenance-json
    :initarg :provenance-json
    :initform nil
    :reader workspace-annotation-persistence-debug-provenance-json-of)
   (exact-form
    :initarg :exact-form
    :reader workspace-annotation-persistence-debug-exact-form-of)
   (stepper-source
    :initarg :stepper-source
    :reader workspace-annotation-persistence-debug-stepper-source-of)
   (dry-run-preview
    :initarg :dry-run-preview
    :initform nil
    :reader workspace-annotation-persistence-debug-dry-run-preview-of)
   (preview-error
    :initarg :preview-error
    :initform nil
    :reader workspace-annotation-persistence-debug-preview-error-of)
   (annotation-key
    :initarg :annotation-key
    :initform nil
    :reader workspace-annotation-persistence-debug-annotation-key-of)
   (runtime-relation-id
    :initarg :runtime-relation-id
    :initform nil
    :reader workspace-annotation-persistence-debug-runtime-relation-id-of)
   (last-report
    :initarg :last-report
    :initform nil
    :accessor workspace-annotation-persistence-debug-last-report-of)))

(defclass workspace-annotation-persistence-report ()
  ((annotation
    :initarg :annotation
    :reader workspace-annotation-persistence-report-annotation-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader workspace-annotation-persistence-report-workspace-topicmap-id-of)
   (workspace-id
    :initarg :workspace-id
    :initform nil
    :reader workspace-annotation-persistence-report-workspace-id-of)
   (client
    :initarg :client
    :initform nil
    :reader workspace-annotation-persistence-report-client-of)
   (exact-form
    :initarg :exact-form
    :reader workspace-annotation-persistence-report-exact-form-of)
   (stepper-source
    :initarg :stepper-source
    :reader workspace-annotation-persistence-report-stepper-source-of)
   (dry-run-preview
    :initarg :dry-run-preview
    :initform nil
    :reader workspace-annotation-persistence-report-dry-run-preview-of)
   (annotation-key
    :initarg :annotation-key
    :initform nil
    :reader workspace-annotation-persistence-report-annotation-key-of)
   (runtime-relation-id
    :initarg :runtime-relation-id
    :initform nil
   :reader workspace-annotation-persistence-report-runtime-relation-id-of)
   (plan
    :initarg :plan
    :initform nil
    :reader workspace-annotation-persistence-report-plan-of)
   (stage-results
    :initarg :stage-results
    :initform '()
    :reader workspace-annotation-persistence-report-stage-results-of)
   (report-status
    :initarg :report-status
    :reader workspace-annotation-persistence-report-status-of)
   (failure-stage
    :initarg :failure-stage
    :initform nil
    :reader workspace-annotation-persistence-report-failure-stage-of)
   (condition
    :initarg :condition
    :initform nil
    :reader workspace-annotation-persistence-report-condition-of)
   (transport-diagnostics
    :initarg :transport-diagnostics
    :initform nil
    :reader workspace-annotation-persistence-report-transport-diagnostics-of)
   (topic-upsert-evidence
    :initarg :topic-upsert-evidence
    :initform nil
    :reader workspace-annotation-persistence-report-topic-upsert-evidence-of)
   (raw-result
    :initarg :raw-result
    :initform nil
    :reader workspace-annotation-persistence-report-raw-result-of)
   (persisted-topic-id
    :initarg :persisted-topic-id
    :initform nil
    :reader workspace-annotation-persistence-report-persisted-topic-id-of)
   (persisted-annotation
    :initarg :persisted-annotation
    :initform nil
    :reader workspace-annotation-persistence-report-persisted-annotation-of)
   (subject-key
    :initarg :subject-key
    :initform nil
    :reader workspace-annotation-persistence-report-subject-key-of)
   (previous-state
    :initarg :previous-state
    :initform nil
    :reader workspace-annotation-persistence-report-previous-state-of)
   (journal-preflight-summary
    :initarg :journal-preflight-summary
    :initform nil
    :reader workspace-annotation-persistence-report-journal-preflight-summary-of)
   (journal-preflight-repair-summary
    :initarg :journal-preflight-repair-summary
    :initform nil
    :reader
    workspace-annotation-persistence-report-journal-preflight-repair-summary-of)
   (journal-preflight-auth-context
    :initarg :journal-preflight-auth-context
    :initform nil
    :reader
    workspace-annotation-persistence-report-journal-preflight-auth-context-of)
   (explicit-auth-attempt-context
    :initarg :explicit-auth-attempt-context
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-attempt-context-of)
   (explicit-auth-retry-invoked-p
    :initarg :explicit-auth-retry-invoked-p
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-invoked-p)
   (explicit-auth-retry-request-id
    :initarg :explicit-auth-retry-request-id
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-request-id-of)
   (explicit-auth-retry-executed-at
    :initarg :explicit-auth-retry-executed-at
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-executed-at-of)
   (explicit-auth-retry-executed-at-label
    :initarg :explicit-auth-retry-executed-at-label
    :initform nil
    :reader
    workspace-annotation-persistence-report-explicit-auth-retry-executed-at-label-of)
   (explicit-auth-retry-mode
    :initarg :explicit-auth-retry-mode
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-mode-of)
   (explicit-auth-retry-mode-label
    :initarg :explicit-auth-retry-mode-label
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-mode-label-of)
   (explicit-auth-retry-source
    :initarg :explicit-auth-retry-source
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-source-of)
   (explicit-auth-retry-source-label
    :initarg :explicit-auth-retry-source-label
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-source-label-of)
   (explicit-auth-retry-evidence-version
    :initarg :explicit-auth-retry-evidence-version
    :initform nil
    :reader workspace-annotation-persistence-report-explicit-auth-retry-evidence-version-of)
   (assignment-auth-context
    :initarg :assignment-auth-context
    :initform nil
    :reader workspace-annotation-persistence-report-assignment-auth-context-of)))

(defclass workspace-annotation-persistence-success-readback ()
  ((id
    :reader id-of
    :initarg :id)
   (title
    :reader title-of
    :initarg :title)
   (summary
    :reader summary-of
    :initarg :summary)
   (topic-proxy
    :reader workspace-annotation-persistence-success-readback-topic-proxy-of
    :initarg :topic-proxy
    :initform nil)
   (workspace-proxy
    :reader workspace-annotation-persistence-success-readback-workspace-proxy-of
    :initarg :workspace-proxy
    :initform nil)
   (topicmap-proxy
    :reader workspace-annotation-persistence-success-readback-topicmap-proxy-of
    :initarg :topicmap-proxy
    :initform nil)
   (journal-expectation
    :reader
    workspace-annotation-persistence-success-readback-journal-expectation-of
    :initarg :journal-expectation
    :initform nil)
   (reopen-expectation
    :reader
    workspace-annotation-persistence-success-readback-reopen-expectation-of
    :initarg :reopen-expectation
    :initform nil)))

(defclass workspace-annotation-persistence-resolution ()
  ((id
    :reader id-of
    :initarg :id)
   (title
    :reader title-of
    :initarg :title)
   (summary
    :reader summary-of
    :initarg :summary)
   (report
    :reader workspace-annotation-persistence-resolution-report-of
    :initarg :report)
   (stage
    :reader workspace-annotation-persistence-resolution-stage-of
    :initarg :stage)
   (stage-label
    :reader workspace-annotation-persistence-resolution-stage-label-of
    :initarg :stage-label)
   (blocking-condition
    :reader workspace-annotation-persistence-resolution-blocking-condition-of
    :initarg :blocking-condition
    :initform nil)
   (required-next-action
    :reader workspace-annotation-persistence-resolution-required-next-action-of
    :initarg :required-next-action
    :initform nil)
   (required-auth-mode
    :reader workspace-annotation-persistence-resolution-required-auth-mode-of
    :initarg :required-auth-mode
    :initform nil)
   (recommended-tool-path
    :reader workspace-annotation-persistence-resolution-recommended-tool-path-of
    :initarg :recommended-tool-path
    :initform nil)
   (success-readback
    :reader workspace-annotation-persistence-resolution-success-readback-of
    :initarg :success-readback
    :initform nil)
   (do-not-do
    :reader workspace-annotation-persistence-resolution-do-not-do-of
    :initarg :do-not-do
    :initform nil)))

(defclass workspace-annotation-persistence-stage-operation ()
  ((id
    :reader id-of
    :initarg :id)
   (title
    :reader title-of
    :initarg :title)
   (summary
    :reader summary-of
    :initarg :summary)
   (report
    :reader workspace-annotation-persistence-stage-operation-report-of
    :initarg :report)
   (stage
    :reader workspace-annotation-persistence-stage-operation-stage-of
    :initarg :stage)
   (stage-label
    :reader workspace-annotation-persistence-stage-operation-stage-label-of
    :initarg :stage-label)
   (status
    :reader workspace-annotation-persistence-stage-operation-status-of
    :initarg :status)
   (boundary-or-endpoint
    :reader
    workspace-annotation-persistence-stage-operation-boundary-or-endpoint-of
    :initarg :boundary-or-endpoint
    :initform nil)
   (entry
    :reader workspace-annotation-persistence-stage-operation-entry-of
    :initarg :entry
    :initform nil)
   (evidence
    :reader workspace-annotation-persistence-stage-operation-evidence-of
    :initarg :evidence
    :initform nil)
   (result-object
    :reader workspace-annotation-persistence-stage-operation-result-object-of
    :initarg :result-object
    :initform nil)
   (next-step-targets
    :reader workspace-annotation-persistence-stage-operation-next-step-targets-of
    :initarg :next-step-targets
    :initform nil)
   (resolution
    :reader workspace-annotation-persistence-stage-operation-resolution-of
    :initarg :resolution
    :initform nil)))

(defclass workspace-annotation-persistence-stage-absence ()
  ((id
    :reader id-of
    :initarg :id)
   (title
    :reader title-of
    :initarg :title)
   (summary
    :reader summary-of
    :initarg :summary)
   (kind
    :reader workspace-annotation-persistence-stage-absence-kind-of
    :initarg :kind)
   (stage
    :reader workspace-annotation-persistence-stage-absence-stage-of
    :initarg :stage)
   (stage-label
    :reader workspace-annotation-persistence-stage-absence-stage-label-of
    :initarg :stage-label)
   (status
    :reader workspace-annotation-persistence-stage-absence-status-of
    :initarg :status
    :initform :not-reached)
   (boundary-or-endpoint
    :reader workspace-annotation-persistence-stage-absence-boundary-or-endpoint-of
    :initarg :boundary-or-endpoint
    :initform nil)
   (reason
    :reader workspace-annotation-persistence-stage-absence-reason-of
    :initarg :reason
    :initform nil)
   (blocking-stage
    :reader workspace-annotation-persistence-stage-absence-blocking-stage-of
    :initarg :blocking-stage
    :initform nil)
   (next-step-targets
    :reader workspace-annotation-persistence-stage-absence-next-step-targets-of
    :initarg :next-step-targets
    :initform nil)
   (success-readback
    :reader workspace-annotation-persistence-stage-absence-success-readback-of
    :initarg :success-readback
    :initform nil)))

(defclass workspace-annotation-path-diff ()
  ((annotation
    :initarg :annotation
    :reader workspace-annotation-path-diff-annotation-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader workspace-annotation-path-diff-workspace-topicmap-id-of)
   (workspace-id
    :initarg :workspace-id
    :initform nil
    :reader workspace-annotation-path-diff-workspace-id-of)
   (client
    :initarg :client
    :initform nil
    :reader workspace-annotation-path-diff-client-of)
   (destination
    :initarg :destination
    :initform nil
    :reader workspace-annotation-path-diff-destination-of)
   (plan
    :initarg :plan
    :initform nil
    :reader workspace-annotation-path-diff-plan-of)
   (raw-report
    :initarg :raw-report
    :initform nil
    :reader workspace-annotation-path-diff-raw-report-of)
   (continuation-topic-id
    :initarg :continuation-topic-id
    :initform nil
    :reader workspace-annotation-path-diff-continuation-topic-id-of)
   (guarded-assignment-summary
    :initarg :guarded-assignment-summary
    :initform nil
    :reader workspace-annotation-path-diff-guarded-assignment-summary-of)
   (guarded-assignment-condition
    :initarg :guarded-assignment-condition
    :initform nil
    :reader workspace-annotation-path-diff-guarded-assignment-condition-of)
   (guarded-topicmap-summary
    :initarg :guarded-topicmap-summary
    :initform nil
    :reader workspace-annotation-path-diff-guarded-topicmap-summary-of)
   (guarded-topicmap-condition
    :initarg :guarded-topicmap-condition
    :initform nil
    :reader workspace-annotation-path-diff-guarded-topicmap-condition-of)
   (state-snapshot
    :initarg :state-snapshot
    :initform nil
    :reader workspace-annotation-path-diff-state-snapshot-of)
   (consequences
    :initarg :consequences
    :initform nil
    :reader workspace-annotation-path-diff-consequences-of)))

(defclass workspace-annotation-path-next-step-target ()
  ((id
    :reader id-of
    :initarg :id)
   (title
    :reader title-of
    :initarg :title)
   (summary
    :reader summary-of
    :initarg :summary
    :initform nil)
   (kind
    :reader workspace-annotation-path-next-step-target-kind-of
    :initarg :kind
    :initform :tool)
   (label
    :reader workspace-annotation-path-next-step-target-label-of
    :initarg :label)
   (executor-or-surface-name
    :reader workspace-annotation-path-next-step-target-executor-or-surface-name-of
    :initarg :executor-or-surface-name)
   (mode
    :reader workspace-annotation-path-next-step-target-mode-of
    :initarg :mode
    :initform :inspect)
   (auth-required-p
    :reader workspace-annotation-path-next-step-target-auth-required-p-of
    :initarg :auth-required-p
    :initform nil)
   (stage-scope
    :reader workspace-annotation-path-next-step-target-stage-scope-of
    :initarg :stage-scope
    :initform nil)
   (target-object
    :reader workspace-annotation-path-next-step-target-object-of
    :initarg :target-object
    :initform nil)
   (target-select
    :reader workspace-annotation-path-next-step-target-select-of
    :initarg :target-select
    :initform nil)))

(defclass workspace-annotation-path-consequence ()
  ((id
    :reader id-of
    :initarg :id)
   (title
    :reader title-of
    :initarg :title)
   (summary
    :reader summary-of
    :initarg :summary)
   (kind
    :reader workspace-annotation-path-consequence-kind-of
    :initarg :kind
    :initform :review-divergence)
   (triggering-stages
    :reader workspace-annotation-path-consequence-triggering-stages-of
    :initarg :triggering-stages
    :initform nil)
   (triggering-evidence
    :reader workspace-annotation-path-consequence-triggering-evidence-of
    :initarg :triggering-evidence
    :initform nil)
   (actionability
    :reader workspace-annotation-path-consequence-actionability-of
    :initarg :actionability
    :initform :review-needed)
   (auth-required-p
    :reader workspace-annotation-path-consequence-auth-required-p-of
    :initarg :auth-required-p
    :initform nil)
   (next-step-targets
    :reader workspace-annotation-path-consequence-next-step-targets-of
    :initarg :next-step-targets
    :initform nil)))

(defmethod print-object ((object workspace-annotation-path-next-step-target)
                         stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A"
            (workspace-annotation-path-next-step-target-label-of object))))

(defmethod print-object ((object workspace-annotation-path-consequence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object
    ((object workspace-annotation-persistence-success-readback) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object workspace-annotation-persistence-resolution)
                         stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object
    ((object workspace-annotation-persistence-stage-operation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object
    ((object workspace-annotation-persistence-stage-absence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass workspace-annotation-create-topic-probe-report ()
  ((annotation
    :initarg :annotation
    :reader workspace-annotation-create-topic-probe-annotation-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader workspace-annotation-create-topic-probe-workspace-topicmap-id-of)
   (client
    :initarg :client
    :initform nil
    :reader workspace-annotation-create-topic-probe-client-of)
   (exact-form
    :initarg :exact-form
    :reader workspace-annotation-create-topic-probe-exact-form-of)
   (dry-run-preview
    :initarg :dry-run-preview
    :initform nil
    :reader workspace-annotation-create-topic-probe-dry-run-preview-of)
   (plan
    :initarg :plan
    :initform nil
    :reader workspace-annotation-create-topic-probe-plan-of)
   (payload-json
    :initarg :payload-json
    :initform nil
    :reader workspace-annotation-create-topic-probe-payload-json-of)
   (report-status
    :initarg :report-status
    :reader workspace-annotation-create-topic-probe-status-of)
   (condition
    :initarg :condition
    :initform nil
    :reader workspace-annotation-create-topic-probe-condition-of)
   (http-evidence
    :initarg :http-evidence
    :initform nil
    :reader workspace-annotation-create-topic-probe-http-evidence-of)
   (created-topic-id
    :initarg :created-topic-id
    :initform nil
    :reader workspace-annotation-create-topic-probe-created-topic-id-of)
   (created-topic
    :initarg :created-topic
    :initform nil
    :reader workspace-annotation-create-topic-probe-created-topic-of)))

(defclass workspace-annotation-backend-compatibility-report ()
  ((annotation
    :initarg :annotation
    :reader workspace-annotation-backend-compatibility-report-annotation-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader
    workspace-annotation-backend-compatibility-report-workspace-topicmap-id-of)
   (client
    :initarg :client
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-client-of)
   (exact-form
    :initarg :exact-form
    :reader workspace-annotation-backend-compatibility-report-exact-form-of)
   (dry-run-preview
    :initarg :dry-run-preview
    :initform nil
    :reader
    workspace-annotation-backend-compatibility-report-dry-run-preview-of)
   (plan
    :initarg :plan
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-plan-of)
   (payload-json
    :initarg :payload-json
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-payload-json-of)
   (report-status
    :initarg :report-status
    :reader workspace-annotation-backend-compatibility-report-status-of)
   (condition
    :initarg :condition
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-condition-of)
   (endpoint-path
    :initarg :endpoint-path
    :initform nil
   :reader workspace-annotation-backend-compatibility-report-endpoint-path-of)
   (failing-type-uri
    :initarg :failing-type-uri
    :initform nil
    :reader
    workspace-annotation-backend-compatibility-report-failing-type-uri-of)
   (native-failing-type-uri
    :initarg :native-failing-type-uri
    :initform nil
    :reader
    workspace-annotation-backend-compatibility-report-native-failing-type-uri-of)
   (selected-storage-mode
    :initarg :selected-storage-mode
    :initform nil
    :reader
    workspace-annotation-backend-compatibility-report-selected-storage-mode-of)
   (carrier-type-uri
    :initarg :carrier-type-uri
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-carrier-type-uri-of)
   (native-supported-p
    :initarg :native-supported-p
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-native-supported-p-of)
   (carrier-supported-p
    :initarg :carrier-supported-p
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-carrier-supported-p-of)
   (type-results
    :initarg :type-results
    :initform '()
    :reader workspace-annotation-backend-compatibility-report-type-results-of)
   (http-evidence
    :initarg :http-evidence
    :initform nil
    :reader workspace-annotation-backend-compatibility-report-http-evidence-of)
   (known-create-topic-response-body
    :initarg :known-create-topic-response-body
    :initform nil
    :reader
    workspace-annotation-backend-compatibility-report-known-create-topic-response-body-of)
   (next-actions
    :initarg :next-actions
    :initform '()
    :reader workspace-annotation-backend-compatibility-report-next-actions-of)))

(defclass workspace-dock-annotation (dock-annotation)
  ((workspace-topic-id
    :initarg :workspace-topic-id
    :initform nil
    :reader workspace-annotation-topic-id-of)
   (workspace-topic-uri
    :initarg :workspace-topic-uri
    :initform nil
    :reader workspace-annotation-topic-uri-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :initform nil
    :reader workspace-annotation-topicmap-id-of)
   (workspace-id
   :initarg :workspace-id
   :initform nil
   :reader workspace-annotation-workspace-id-of)
   (storage-mode
    :initarg :storage-mode
    :initform *dmx-workspace-annotation-native-storage-mode*
    :reader workspace-annotation-storage-mode-of)
   (carrier-type-uri
    :initarg :carrier-type-uri
    :initform nil
    :reader workspace-annotation-carrier-type-uri-of)
   (annotation-key
    :initarg :annotation-key
    :initform nil
    :reader workspace-annotation-key-of)
   (workspace-status
    :initarg :workspace-status
    :initform nil
    :reader workspace-annotation-status-of)
   (source-anchor-json
    :initarg :source-anchor-json
    :initform nil
    :reader workspace-annotation-source-anchor-json-of)
   (target-anchor-json
    :initarg :target-anchor-json
    :initform nil
    :reader workspace-annotation-target-anchor-json-of)
   (source-object-ref
    :initarg :source-object-ref
    :initform nil
    :reader workspace-annotation-source-object-ref-of)
   (target-object-ref
    :initarg :target-object-ref
    :initform nil
    :reader workspace-annotation-target-object-ref-of)
   (runtime-relation-id
    :initarg :runtime-relation-id
    :initform nil
    :reader workspace-annotation-runtime-relation-id-of)
   (provenance-json
    :initarg :provenance-json
    :initform nil
    :reader workspace-annotation-provenance-json-of)
   (source-binding
    :initarg :source-binding
    :initform nil
    :reader workspace-annotation-source-binding-of)
   (target-binding
    :initarg :target-binding
    :initform nil
    :reader workspace-annotation-target-binding-of)
   (context-binding
    :initarg :context-binding
    :initform nil
    :reader workspace-annotation-context-binding-of)
   (supersedes-binding
    :initarg :supersedes-binding
    :initform nil
    :reader workspace-annotation-supersedes-binding-of)
   (supersedes-topic-id
    :initarg :supersedes-topic-id
    :initform nil
    :reader workspace-annotation-supersedes-topic-id-of)))

(defparameter *hyperdoc-local-workspace-annotation-subject-kind*
  "workspace-annotation")
(defparameter *hyperdoc-local-workspace-annotation-ownership-class*
  "hyperdoc-local-workspace-annotation")
(defparameter *hyperdoc-local-workspace-annotation-observation-kind*
  "hyperdoc-local-first")
(defparameter *hyperdoc-local-workspace-annotation-actor*
  "hyperdoc-local-annotation-persist")
(defparameter *hyperdoc-local-workspace-annotation-status-local-only*
  "local-only")
(defparameter *hyperdoc-local-workspace-annotation-status-projected*
  "persisted")
(defparameter *hyperdoc-local-workspace-annotation-status-projection-pending*
  "projection-pending-auth")
(defparameter *hyperdoc-local-workspace-annotation-status-projection-failed*
  "projection-failed")
(defvar *hyperdoc-local-workspace-journal-streams*)

(defun workspace-annotation-replay-subject (object)
  (typecase object
    (workspace-annotation-backend-compatibility-report
     (workspace-annotation-backend-compatibility-report-annotation-of object))
    (workspace-annotation-create-topic-probe-report
     (workspace-annotation-create-topic-probe-annotation-of object))
    (workspace-annotation-persistence-debug
     (workspace-annotation-persistence-debug-annotation-of object))
    (workspace-annotation-persistence-report
     (workspace-annotation-persistence-report-annotation-of object))
    (t object)))

(defun workspace-annotation-probe-subject (object)
  (workspace-annotation-replay-subject object))

(defun workspace-dock-annotation-p (object)
  (typep object 'workspace-dock-annotation))

(defun workspace-annotation-topic-id-or-nil (annotation)
  (and (workspace-dock-annotation-p annotation)
       (ignore-errors (workspace-annotation-topic-id-of annotation))))

(defun workspace-annotation-strict-positive-topic-id-or-nil (value)
  (cond
    ((integerp value)
     (and (plusp value) value))
    ((stringp value)
     (let ((trimmed
             (string-trim '(#\Space #\Tab #\Newline #\Return)
                          value)))
       (and (plusp (length trimmed))
            (every #'digit-char-p trimmed)
            (parse-integer trimmed))))
    (t
     nil)))

(defun workspace-annotation-target-topic-id-or-nil (annotation)
  (let* ((target (and annotation
                      (ignore-errors (target-object-of annotation))))
         (target-id (and target
                         (ignore-errors (id-of target))))
         (target-anchor-object-id
           (and annotation
                (ignore-errors
                  (anchor-object-id-of
                   (target-anchor-of annotation))))))
    (or (workspace-annotation-strict-positive-topic-id-or-nil target)
        (workspace-annotation-strict-positive-topic-id-or-nil target-id)
        (workspace-annotation-strict-positive-topic-id-or-nil
         target-anchor-object-id))))

(defun workspace-annotation-continuation-topic-id-or-nil (annotation)
  (or (workspace-annotation-topic-id-or-nil annotation)
      (workspace-annotation-target-topic-id-or-nil annotation)))

(defun dmx-workspace-annotation-local-native-payload-from-object
    (annotation workspace-topicmap-id
     &key status supersedes-topic-id annotation-key provenance-json)
  (let* ((normalized
           (dmx-workspace-annotation-from-object
            annotation
            workspace-topicmap-id
            :status status
            :supersedes-topic-id supersedes-topic-id
            :annotation-key annotation-key
            :provenance-json provenance-json)))
    (dmx-workspace-annotation-native-payload
     :uri (getf normalized :uri)
     :title (getf normalized :title)
     :summary (getf normalized :summary)
     :text (getf normalized :text)
     :relation-kind (getf normalized :relation-kind)
     :status (getf normalized :status)
     :source-anchor-json (getf normalized :source-anchor-json)
     :target-anchor-json (getf normalized :target-anchor-json)
     :context-object-id (getf normalized :context-object-id)
     :context-view-title (getf normalized :context-view-title)
     :source-object-ref (getf normalized :source-object-ref)
     :target-object-ref (getf normalized :target-object-ref)
     :runtime-relation-id (getf normalized :runtime-relation-id)
     :provenance-json (getf normalized :provenance-json)
     :workspace-topicmap-id workspace-topicmap-id
     :supersedes-topic-id (getf normalized :supersedes-topic-id))))

(defun workspace-annotation-local-payload-with-status (payload status)
  (let* ((payload-copy
           (dmx-workspace-journal-payload-json->payload
            (dmx-workspace-journal-payload-json-from-payload payload)))
         (children (or (getf payload-copy :children)
                       (let ((json (make-hash-table :test #'equal)))
                         (setf (getf payload-copy :children) json)
                         json))))
    (setf (gethash *dmx-workspace-annotation-status-type-uri* children)
          (normalize-dmx-workspace-note-string
           status
           :status
           'workspace-annotation-local-payload-with-status
           :required? t))
    payload-copy))

(defun ensure-hyperdoc-local-workspace-annotation-stream
    (subject-key workspace-topicmap-id)
  (or (gethash subject-key *hyperdoc-local-workspace-journal-streams*)
      (setf (gethash subject-key *hyperdoc-local-workspace-journal-streams*)
            (dmx-workspace-journal-make-base-stream
             subject-key
             "uri"
             subject-key
             workspace-topicmap-id
             :subject-uri subject-key
             :subject-kind *hyperdoc-local-workspace-annotation-subject-kind*
             :ownership-class
             *hyperdoc-local-workspace-annotation-ownership-class*))))

(defun hyperdoc-local-workspace-annotation-current-state
    (stream subject-key workspace-topicmap-id)
  (or (dmx-workspace-journal-current-snapshot stream)
      (dmx-workspace-journal-absent-snapshot
       subject-key
       "uri"
       subject-key
       workspace-topicmap-id
       :subject-uri subject-key
       :subject-kind *hyperdoc-local-workspace-annotation-subject-kind*
       :ownership-class
       *hyperdoc-local-workspace-annotation-ownership-class*)))

(defun workspace-annotation-local-next-state-from-payload
    (subject-key workspace-topicmap-id payload
     &key topic-id workspace-id in-topicmap view-props)
  (dmx-workspace-journal-snapshot-from-payload
   subject-key
   "uri"
   subject-key
   workspace-topicmap-id
   (dmx-workspace-journal-payload-json-from-payload payload)
   :subject-uri subject-key
   :subject-kind *hyperdoc-local-workspace-annotation-subject-kind*
   :ownership-class *hyperdoc-local-workspace-annotation-ownership-class*
   :topic-id topic-id
   :in-topicmap (and in-topicmap t)
   :view-props view-props
   :workspace-id workspace-id
   :workspace-title
   (and workspace-id
        (dmx-workspace-annotation-workspace-label workspace-id))))

(defun workspace-annotation-local-apply-transition
    (subject-key workspace-topicmap-id next-state)
  (let* ((stream
           (ensure-hyperdoc-local-workspace-annotation-stream
            subject-key
            workspace-topicmap-id))
         (previous-state
           (hyperdoc-local-workspace-annotation-current-state
            stream
            subject-key
            workspace-topicmap-id))
         (events
           (dmx-workspace-journal-transition-events
            previous-state
            next-state
            *hyperdoc-local-workspace-annotation-observation-kind*
            *hyperdoc-local-workspace-annotation-actor*)))
    (when events
      (dmx-workspace-journal-apply-events-to-stream stream events))
    (set-hyperdoc-local-workspace-journal-stream subject-key stream)
    (values stream events previous-state next-state)))

(defun workspace-annotation-local-projection-status-from-report
    (report saved-topic-id)
  (cond
    ((and (typep report 'workspace-annotation-persistence-report)
          (eq (workspace-annotation-persistence-report-status-of report)
              :persisted))
     *hyperdoc-local-workspace-annotation-status-projected*)
    ((and saved-topic-id
          (typep report 'workspace-annotation-persistence-report)
          (workspace-annotation-pending-auth-p report))
     *hyperdoc-local-workspace-annotation-status-projection-pending*)
    (saved-topic-id
     *hyperdoc-local-workspace-annotation-status-projection-failed*)
    (t
     *hyperdoc-local-workspace-annotation-status-projection-failed*)))

(defun workspace-dock-annotation-from-hyperdoc-local-journal-snapshot
    (snapshot)
  (let* ((payload-json (and snapshot (gethash "payload" snapshot)))
         (payload
           (and (hash-table-p payload-json)
                (dmx-workspace-journal-payload-json->payload payload-json)))
         (source-anchor-json
           (and payload
                (dmx-json-child-value
                 payload
                 *dmx-workspace-annotation-source-anchor-json-type-uri*)))
         (target-anchor-json
           (and payload
                (dmx-json-child-value
                 payload
                 *dmx-workspace-annotation-target-anchor-json-type-uri*)))
         (source-anchor
           (and (dmx-non-empty-string-p source-anchor-json)
                (make-dom-annotation-anchor-from-json
                 (parse-dom-annotation-json source-anchor-json))))
         (target-anchor
           (and (dmx-non-empty-string-p target-anchor-json)
                (make-dom-annotation-anchor-from-json
                 (parse-dom-annotation-json target-anchor-json))))
         (topic-type-uri (and payload (getf payload :type-uri)))
         (workspace-topic-uri
           (or (and payload (getf payload :uri))
               (and snapshot (gethash "subjectUri" snapshot))
               (and snapshot (gethash "subjectKey" snapshot))))
         (topic-id (and snapshot (gethash "topicId" snapshot)))
         (storage-mode
           (if (or (string= (or topic-type-uri "")
                            *dmx-workspace-annotation-compatibility-carrier-type-uri*)
                   (string= (or topic-type-uri "")
                            *dmx-notes-note-type-uri*))
               *dmx-workspace-annotation-compatibility-storage-mode*
               *dmx-workspace-annotation-native-storage-mode*))
         (carrier-type-uri
           (and (dmx-workspace-annotation-compatibility-storage-mode-p
                 storage-mode)
                (or (and (dmx-non-empty-string-p topic-type-uri) topic-type-uri)
                    *dmx-workspace-annotation-compatibility-carrier-type-uri*)))
         (annotation-key
           (and (dmx-non-empty-string-p workspace-topic-uri)
                (dmx-string-prefix-p *hyperdoc-workspace-annotation-uri-prefix*
                                     workspace-topic-uri)
                (subseq workspace-topic-uri
                        (length *hyperdoc-workspace-annotation-uri-prefix*))))
         (source-object-ref
           (and payload
                (dmx-json-child-value
                 payload
                 *dmx-workspace-annotation-source-object-ref-type-uri*)))
         (target-object-ref
           (and payload
                (dmx-json-child-value
                 payload
                 *dmx-workspace-annotation-target-object-ref-type-uri*)))
         (runtime-relation-id
           (and payload
                (dmx-json-child-value
                 payload
                 *dmx-workspace-annotation-runtime-relation-id-type-uri*)))
         (summary
           (or (and payload
                    (dmx-json-child-value
                     payload
                     *dmx-workspace-annotation-summary-type-uri*))
               (and payload (getf payload :value))
               "Workspace annotation"))
         (title
           (or (and payload (getf payload :value))
               "Workspace annotation"))
         (stable-id
           (if (integerp topic-id)
               (format nil "workspace-annotation/~D" topic-id)
               (format nil "workspace-annotation/local/~A"
                       (or annotation-key
                           (dmx-workspace-annotation-slug
                            (or runtime-relation-id title "annotation"))))))
         (workspace-status
           (and payload
                (dmx-json-child-value
                 payload
                 *dmx-workspace-annotation-status-type-uri*))))
    (unless (and payload source-anchor target-anchor)
      (error 'fedwiki-dmx-import-error
             :message
             "HyperDoc-local workspace annotation journal snapshot is missing payload or anchor JSON"))
    (make-instance
     'workspace-dock-annotation
     :id stable-id
     :title title
     :summary summary
     :context-object
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-context-object-id-type-uri*)
     :context-view-title
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-context-view-title-type-uri*)
     :source-anchor source-anchor
     :target-anchor target-anchor
     :source-object source-object-ref
     :target-object (dmx-workspace-annotation-target-object target-object-ref)
     :relation-kind
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-relation-kind-type-uri*)
     :note (dmx-json-child-value payload
                                 *dmx-workspace-annotation-text-type-uri*)
     :matching-patch-target nil
     :matching-defect nil
     :matching-inserted-step nil
     :registry-key (or runtime-relation-id stable-id)
     :dock-capability "Annotation"
     :workspace-topic-id topic-id
     :workspace-topic-uri workspace-topic-uri
     :workspace-topicmap-id (and snapshot (gethash "topicmapId" snapshot))
     :workspace-id (and snapshot (gethash "workspaceId" snapshot))
     :storage-mode storage-mode
     :carrier-type-uri carrier-type-uri
     :annotation-key annotation-key
     :workspace-status workspace-status
     :source-anchor-json source-anchor-json
     :target-anchor-json target-anchor-json
     :source-object-ref source-object-ref
     :target-object-ref target-object-ref
     :runtime-relation-id runtime-relation-id
     :provenance-json
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-provenance-type-uri*)
     :source-binding
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-source-binding-type-uri*)
     :target-binding
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-target-binding-type-uri*)
     :context-binding
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-context-binding-type-uri*)
     :supersedes-binding
     (dmx-json-child-value payload
                           *dmx-workspace-annotation-supersedes-type-uri*)
     :supersedes-topic-id nil)))

(defun read-hyperdoc-local-workspace-annotation
    (&key subject-key annotation-key)
  (let* ((resolved-subject-key
           (or subject-key
               (and (dmx-non-empty-string-p annotation-key)
                    (dmx-workspace-annotation-uri annotation-key))
               (error 'fedwiki-dmx-import-error
                      :message
                      "Provide subject-key or annotation-key for HyperDoc-local workspace annotation read")))
         (stream (gethash resolved-subject-key
                          *hyperdoc-local-workspace-journal-streams*)))
    (unless stream
      (error 'fedwiki-dmx-import-error
             :message
             "No HyperDoc-local workspace annotation journal stream matched the requested subject"))
    (workspace-dock-annotation-from-hyperdoc-local-journal-snapshot
     (or (dmx-workspace-journal-current-snapshot stream)
         (dmx-workspace-journal-subject-snapshot-from-stream stream)))))

(defun workspace-annotation-storage-mode-label (storage-mode)
  (case storage-mode
    ((nil) "-")
    (:native-annotation "native hyperdoc.annotation")
    (:compatibility-note-carrier "compatibility note carrier")
    (otherwise
     (code-path-graph-human-label storage-mode))))

(defun dmx-workspace-annotation-native-storage-mode-p (storage-mode)
  (eq storage-mode *dmx-workspace-annotation-native-storage-mode*))

(defun dmx-workspace-annotation-compatibility-storage-mode-p (storage-mode)
  (eq storage-mode *dmx-workspace-annotation-compatibility-storage-mode*))

(defun dmx-workspace-annotation-storage-mode-carrier-type-uri (storage-mode)
  (when (dmx-workspace-annotation-compatibility-storage-mode-p storage-mode)
    *dmx-workspace-annotation-compatibility-carrier-type-uri*))

(defun dmx-workspace-annotation-default-storage-mode (client)
  (if (typep client 'http-dmx-import-client)
      *dmx-workspace-annotation-compatibility-storage-mode*
      *dmx-workspace-annotation-native-storage-mode*))

(defun make-default-workspace-annotation-live-client (&key verbose)
  (let* ((environment-client
           (make-http-dmx-import-client-from-environment :verbose verbose))
         (fallback-base-url
           (normalize-http-dmx-import-string
            *dmx-base-url*
            :base-url 'make-default-workspace-annotation-live-client)))
    (when fallback-base-url
      (make-instance
       'http-dmx-import-client
       :base-url (or (and environment-client
                          (dmx-import-base-url-of environment-client))
                     fallback-base-url)
       :authorization-header
       (and environment-client
            (dmx-import-authorization-header-of environment-client))
       :session-cookie
       (and environment-client
            (dmx-import-session-cookie-of environment-client))
       :session-login-required-p
       (and environment-client
            (dmx-import-session-login-required-p-of environment-client))
       :workspace-id
       (and environment-client
            (dmx-import-workspace-id-of environment-client))
       :topic-type-uri
       (or (and environment-client
                (dmx-import-topic-type-uri-of environment-client))
           *dmx-fedwiki-page-type-uri*)
       :verbose verbose))))

(defun resolve-dmx-workspace-annotation-client
    (&key client (dry-run t) verbose)
  (let ((resolved-client
          (or client
              (make-default-dmx-import-client :dry-run dry-run
                                              :verbose verbose))))
    (if (or dry-run
            (not (typep resolved-client 'null-dmx-import-client)))
        resolved-client
        (or (make-default-workspace-annotation-live-client :verbose verbose)
            resolved-client))))

(defun dmx-workspace-annotation-destination-source-label (source)
  (case source
    (:explicit-user-choice "explicit user choice")
    (:persisted-annotation-destination
     "current persisted annotation destination")
    (:http-client-workspace-context "current HTTP client/workspace context")
    (:context-window-default "context-window default fallback")
    (:mixed "mixed resolution")
    (otherwise
     (string-downcase (format nil "~A" source)))))

(defun dmx-workspace-annotation-workspace-label (workspace-id)
  (when workspace-id
    (if (eql workspace-id *dmx-context-window-workspace-id*)
        (format nil "context-window workspace (~D)" workspace-id)
        (format nil "workspace (~D)" workspace-id))))

(defun dmx-workspace-annotation-topicmap-label (workspace-topicmap-id)
  (when workspace-topicmap-id
    (if (eql workspace-topicmap-id *dmx-context-window-topicmap-id*)
        (format nil "context-window topicmap (~D)" workspace-topicmap-id)
        (format nil "workspace topicmap (~D)" workspace-topicmap-id))))

(defun normalize-optional-workspace-topicmap-id (workspace-topicmap-id)
  (when workspace-topicmap-id
    (or (parse-positive-integer workspace-topicmap-id)
        (error 'fedwiki-dmx-import-error
               :message (format nil
                                "Workspace annotation destination requires a positive workspace topicmap id, got ~S"
                                workspace-topicmap-id)))))

(defun workspace-annotation-destination-rationale-string
    (workspace-id workspace-source workspace-topicmap-id topicmap-source)
  (if (eq workspace-source topicmap-source)
      (case workspace-source
        (:explicit-user-choice
         (format nil
                 "Both workspace ~D and topicmap ~D came from explicit user choice."
                 workspace-id
                 workspace-topicmap-id))
        (:persisted-annotation-destination
         (format nil
                 "Both workspace ~D and topicmap ~D were reused from the current persisted annotation destination."
                 workspace-id
                 workspace-topicmap-id))
        (:http-client-workspace-context
         (format nil
                 "Workspace ~D and topicmap ~D were derived from the current HTTP client/workspace context."
                 workspace-id
                 workspace-topicmap-id))
        (otherwise
         (format nil
                 "Workspace ~D and topicmap ~D fell back to the context-window collaboration surface."
                 workspace-id
                 workspace-topicmap-id)))
      (format nil
              "Workspace ~D came from ~A; topicmap ~D came from ~A."
              workspace-id
              (dmx-workspace-annotation-destination-source-label
               workspace-source)
              workspace-topicmap-id
              (dmx-workspace-annotation-destination-source-label
               topicmap-source))))

(defun resolve-dmx-workspace-annotation-destination
    (annotation &key workspace-topicmap-id workspace-id client)
  (let* ((persisted-workspace-id
           (and (workspace-dock-annotation-p annotation)
                (workspace-annotation-workspace-id-of annotation)))
         (persisted-topicmap-id
           (and (workspace-dock-annotation-p annotation)
                (workspace-annotation-topicmap-id-of annotation)))
         (explicit-workspace-id
           (and workspace-id
                (dmx-workspace-annotation-topic-id
                 workspace-id
                 :workspace-id
                 'resolve-dmx-workspace-annotation-destination
                 :required? t)))
         (explicit-topicmap-id
           (normalize-optional-workspace-topicmap-id workspace-topicmap-id))
         (client-workspace-id
           (and (typep client 'http-dmx-import-client)
                (dmx-import-workspace-id-of client)))
         (resolved-workspace-id
           (or explicit-workspace-id
               persisted-workspace-id
               client-workspace-id
               *dmx-context-window-workspace-id*))
         (workspace-source
           (cond
             (explicit-workspace-id :explicit-user-choice)
             (persisted-workspace-id :persisted-annotation-destination)
             (client-workspace-id :http-client-workspace-context)
             (t :context-window-default)))
         (resolved-topicmap-id
           (or explicit-topicmap-id
               persisted-topicmap-id
               *dmx-context-window-topicmap-id*))
         (topicmap-source
           (cond
             (explicit-topicmap-id :explicit-user-choice)
             (persisted-topicmap-id :persisted-annotation-destination)
             (t :context-window-default)))
         (source
           (if (eq workspace-source topicmap-source)
               workspace-source
               :mixed)))
    (make-dmx-workspace-annotation-destination
     :workspace-id resolved-workspace-id
     :workspace-topicmap-id resolved-topicmap-id
     :source source
     :workspace-source workspace-source
     :topicmap-source topicmap-source
     :rationale
     (workspace-annotation-destination-rationale-string
      resolved-workspace-id
      workspace-source
      resolved-topicmap-id
      topicmap-source))))

(defun dmx-workspace-annotation-destination-summary (destination)
  (when destination
    (list :destination-source
          (dmx-workspace-annotation-destination-source destination)
          :destination-source-label
          (dmx-workspace-annotation-destination-source-label
           (dmx-workspace-annotation-destination-source destination))
          :workspace-source
          (dmx-workspace-annotation-destination-workspace-source destination)
          :workspace-source-label
          (dmx-workspace-annotation-destination-source-label
           (dmx-workspace-annotation-destination-workspace-source destination))
          :topicmap-source
          (dmx-workspace-annotation-destination-topicmap-source destination)
          :topicmap-source-label
          (dmx-workspace-annotation-destination-source-label
           (dmx-workspace-annotation-destination-topicmap-source destination))
          :destination-rationale
          (dmx-workspace-annotation-destination-rationale destination))))

(defun dmx-workspace-annotation-compatibility-envelope-from-string
    (json-string)
  (when (dmx-non-empty-string-p json-string)
    (handler-case
        (with-input-from-string (stream json-string)
          (let ((json (shasht:read-json stream)))
            (when (and (hash-table-p json)
                       (string= (or (gethash "storageMode" json) "")
                                *dmx-workspace-annotation-compatibility-storage-mode-name*)
                       (string= (or (gethash "nativeTypeUri" json) "")
                                *dmx-workspace-annotation-type-uri*))
              json)))
      (error ()
        nil))))

(defun dmx-workspace-annotation-compatibility-envelope-from-topic (topic)
  (and (string= (or (dmx-json-object-value topic "typeUri") "")
                *dmx-workspace-annotation-compatibility-carrier-type-uri*)
       (dmx-workspace-annotation-compatibility-envelope-from-string
        (dmx-json-child-value topic *dmx-notes-text-type-uri*))))

(defun dmx-workspace-annotation-topic-storage-mode (topic)
  (cond
    ((string= (or (dmx-json-object-value topic "typeUri") "")
              *dmx-workspace-annotation-type-uri*)
     *dmx-workspace-annotation-native-storage-mode*)
    ((dmx-workspace-annotation-compatibility-envelope-from-topic topic)
     *dmx-workspace-annotation-compatibility-storage-mode*)
    (t
     nil)))

(defun resolve-dmx-workspace-annotation-storage-mode
    (requested-storage-mode client existing-topic)
  (let ((existing-storage-mode
          (and existing-topic
               (dmx-workspace-annotation-topic-storage-mode existing-topic))))
    (cond
      (existing-storage-mode
       existing-storage-mode)
      ((null requested-storage-mode)
       (dmx-workspace-annotation-default-storage-mode client))
      ((member requested-storage-mode
               (list *dmx-workspace-annotation-native-storage-mode*
                     *dmx-workspace-annotation-compatibility-storage-mode*)
               :test #'eq)
       requested-storage-mode)
      (t
       (error 'fedwiki-dmx-import-error
              :message (format nil
                               "Unsupported workspace annotation storage mode ~S"
                               requested-storage-mode))))))

(defun workspace-annotation-persistence-stage-label (stage)
  (case stage
    (:normalize-annotation "Normalize annotation")
    (:build-write-plan "Build write plan")
    (:validate-payload "Validate payload and view props")
    (:backend-compatibility-preflight "Backend compatibility preflight")
    (:prepare-transition "Prepare workspace journal preflight")
    (:topic-upsert "Execute topic upsert")
    (:workspace-assignment "Assign topic to workspace")
    (:topicmap-placement "Add topic to workspace topicmap")
    (:journal-transition "Emit workspace journal event")
    (:reopen-persisted-annotation "Reopen persisted annotation")
    (otherwise
     (code-path-graph-human-label stage))))

(defun workspace-annotation-persistence-stage-entry
    (stage status summary &key detail)
  (list :stage stage
        :label (workspace-annotation-persistence-stage-label stage)
        :status status
        :summary summary
        :detail detail))

(defun workspace-annotation-persistence-stage-result (report stage)
  (find stage
        (workspace-annotation-persistence-report-stage-results-of report)
        :test #'eq
        :key (lambda (entry) (getf entry :stage))))

(defun first-non-latin-1-character-details (string)
  (when (stringp string)
    (loop for char across string
          for index from 0
          unless (<= (char-code char) 255)
            do (return (list :character (string char)
                             :code-point (char-code char)
                             :position index)))))

(defun workspace-annotation-transport-field-candidates (plan)
  (when plan
    (list (cons :title (dmx-workspace-annotation-write-plan-title plan))
          (cons :summary (dmx-workspace-annotation-write-plan-summary plan))
          (cons :text (dmx-workspace-annotation-write-plan-text plan))
          (cons :relation-kind
                (dmx-workspace-annotation-write-plan-relation-kind plan))
          (cons :status (dmx-workspace-annotation-write-plan-status plan))
          (cons :source-anchor-json
                (dmx-workspace-annotation-write-plan-source-anchor-json plan))
          (cons :target-anchor-json
                (dmx-workspace-annotation-write-plan-target-anchor-json plan))
          (cons :context-object-id
                (dmx-workspace-annotation-write-plan-context-object-id plan))
          (cons :context-view-title
                (dmx-workspace-annotation-write-plan-context-view-title plan))
          (cons :source-object-ref
                (dmx-workspace-annotation-write-plan-source-object-ref plan))
          (cons :target-object-ref
                (dmx-workspace-annotation-write-plan-target-object-ref plan))
          (cons :runtime-relation-id
                (dmx-workspace-annotation-write-plan-runtime-relation-id plan))
          (cons :provenance-json
                (dmx-workspace-annotation-write-plan-provenance-json plan)))))

(defun workspace-annotation-transport-diagnostics (plan failure-stage condition)
  (let ((message (and condition (format nil "~A" condition))))
    (when (and plan
               failure-stage
               (stringp message)
               (search "LATIN-1 character" message :test #'char-equal))
      (loop for (field . value) in (workspace-annotation-transport-field-candidates
                                    plan)
            for details = (first-non-latin-1-character-details value)
            when details
              do (return (append (list :transport-stage failure-stage
                                       :field field)
                                 details))))))

(defun workspace-annotation-write-plan-payload-json-string (plan)
  (when plan
    (encode-json-string
     (dmx-import-json-object
      (dmx-workspace-annotation-write-plan-payload plan)))))

(defun workspace-annotation-backend-compatibility-probe-form
    (workspace-topicmap-id &key workspace-id)
  (with-standard-io-syntax
    (let ((*package* (find-package :hyperdoc)))
      (prin1-to-string
       `(probe-live-workspace-annotation-type-support
         (workspace-annotation-backend-compatibility-report-annotation-of *)
         :workspace-topicmap-id ,workspace-topicmap-id
         ,@(when workspace-id
             `(:workspace-id ,workspace-id)))))))

(defun workspace-annotation-known-live-create-topic-response-body
    (failing-type-uri)
  (and (stringp failing-type-uri)
       (string= failing-type-uri *dmx-workspace-annotation-type-uri*)
       *dmx-workspace-annotation-known-live-create-topic-response-body*))

(defun workspace-annotation-backend-compatibility-next-actions
    (report-status selected-storage-mode failing-type-uri
     &key native-failing-type-uri carrier-type-uri)
  (cond
    ((eq report-status :compatible-via-carrier)
     (remove nil
             (list
              (format nil
                      "Live workspace annotation persistence will use compatibility storage via ~A."
                      (or carrier-type-uri
                          *dmx-workspace-annotation-compatibility-carrier-type-uri*))
              (when native-failing-type-uri
                (format nil
                        "The backend still does not expose ~A, so raw hyperdoc.annotation create-topic probes remain diagnostic only."
                        native-failing-type-uri))
              "Register hyperdoc.annotation and its child type family later only if native annotation topics become an explicit backend goal.")))
    ((eq report-status :unsupported)
     (remove nil
             (list
              (format nil
                      "Repair live support for ~A before offering workspace annotation persistence through the selected ~A path."
                      (or failing-type-uri *dmx-workspace-annotation-type-uri*)
                      (workspace-annotation-storage-mode-label
                       selected-storage-mode))
              (when native-failing-type-uri
                (format nil
                        "Raw hyperdoc.annotation remains unsupported at ~A."
                        native-failing-type-uri))
              (when (and (dmx-workspace-annotation-compatibility-storage-mode-p
                          selected-storage-mode)
                         carrier-type-uri)
                (format nil
                        "Expected installed compatibility carrier ~A to be readable on the live backend."
                        carrier-type-uri)))))
    ((eq report-status :error)
     (list
      "Repair the live DMX auth/bootstrap/type-read boundary first, then retry the compatibility probe."
      "Keep using dry-run plan inspection or the explicit create-topic probe for diagnostics until the backend contract is clear."))
    (t
     '())))

(defun workspace-annotation-backend-compatibility-blocked-p (report)
  (member (workspace-annotation-backend-compatibility-report-status-of report)
          '(:not-live :unsupported :error)
          :test #'eq))

(defun workspace-annotation-live-compatibility-preflight-required-p (client)
  (or (typep client 'http-dmx-import-client)
      (typep client 'null-dmx-import-client)))

(defun workspace-annotation-live-type-support-result
    (type-uri kind topic evidence)
  (list :type-uri type-uri
        :kind kind
        :supported-p (and topic t)
        :topic-id (dmx-import-object-id topic)
        :http-evidence (sanitize-dmx-import-http-evidence evidence)))

(defun probe-workspace-annotation-live-type-family
    (client type-uris kind-prefix)
  (let ((results '()))
    (labels ((probe-type-uri (type-uri kind)
               (let* ((topic (dmx-import-find-existing-topic client type-uri))
                      (evidence
                        (and (typep client 'http-dmx-import-client)
                             (dmx-import-last-http-transaction-evidence-of
                              client)))
                      (result
                        (workspace-annotation-live-type-support-result
                         type-uri
                         kind
                         topic
                         evidence)))
                 (push result results)
                 result)))
      (let* ((parent-result
               (probe-type-uri (first type-uris)
                               (ecase kind-prefix
                                 (:native :native-parent)
                                 (:carrier :carrier-parent))))
             (parent-supported-p (getf parent-result :supported-p)))
        (when parent-supported-p
          (dolist (child-type-uri (rest type-uris))
            (probe-type-uri child-type-uri
                            (ecase kind-prefix
                              (:native :native-child)
                              (:carrier :carrier-child)))))
        (let* ((ordered-results (nreverse results))
               (first-missing
                 (find-if-not (lambda (entry)
                                (getf entry :supported-p))
                              ordered-results)))
          (values ordered-results first-missing))))))

(defun workspace-annotation-create-topic-probe-form
    (workspace-topicmap-id &key workspace-id storage-mode)
  (with-standard-io-syntax
    (let ((*package* (find-package :hyperdoc)))
      (prin1-to-string
       `(probe-live-create-topic-for-dock-annotation
         (workspace-annotation-create-topic-probe-annotation-of *)
         :workspace-topicmap-id ,workspace-topicmap-id
         ,@(when workspace-id
             `(:workspace-id ,workspace-id))
         :storage-mode ,storage-mode)))))

(defun dmx-import-http-evidence (condition)
  (and (typep condition 'dmx-import-http-error)
         (let ((evidence
               (or (dmx-import-http-evidence-of condition)
                   (list :url (dmx-import-http-url-of condition)
                         :response-status-code
                         (dmx-import-http-status-code-of condition)))))
         (sanitize-dmx-import-http-evidence evidence))))

(defun workspace-annotation-topic-upsert-evidence (plan condition)
  (when-let (http-evidence (dmx-import-http-evidence condition))
    (append
     (list :planned-topic-action
           (and plan
                (dmx-workspace-annotation-write-plan-topic-action plan))
           :planned-workspace-action
           (and plan
                (dmx-workspace-annotation-write-plan-workspace-action plan))
           :planned-topicmap-action
           (and plan
                (dmx-workspace-annotation-write-plan-topicmap-action plan))
           :payload-json-length
           (length (or (workspace-annotation-write-plan-payload-json-string
                        plan)
                       ""))
           :payload-json-prefix
           (bounded-http-evidence-string
            (or (workspace-annotation-write-plan-payload-json-string plan)
                "")))
     http-evidence)))

(defun workspace-annotation-auth-mode-options ()
  '(:basic :header :token))

(defun workspace-annotation-client-auth-context (client)
  (let ((http-client-p (typep client 'http-dmx-import-client)))
    (list :environment-auth-present-p
          (and http-client-p
               (dmx-import-authorization-header-of client)
               t)
          :environment-auth-mode-summary
          (and http-client-p
               (summarize-http-request-auth-mode
                (dmx-import-authorization-header-of client)
                (dmx-import-session-cookie-of client)))
          :authorization-scheme
          (and http-client-p
               (summarize-http-authorization-scheme
                (dmx-import-authorization-header-of client)))
          :session-login-required-p
          (and http-client-p
               (dmx-import-session-login-required-p-of client))
          :session-cookie-present-p
          (and http-client-p
               (dmx-import-session-cookie-of client)
               t)
          :available-auth-modes
          (workspace-annotation-auth-mode-options))))

(defun workspace-annotation-assignment-endpoint-path (workspace-id topic-id)
  (when (and workspace-id topic-id)
    (dmx-workspace-assign-object-path workspace-id topic-id)))

(defun workspace-annotation-auth-missing-keys (condition)
  (and (typep condition 'dmx-import-config-error)
       (dmx-import-missing-keys-of condition)))

(defun workspace-annotation-http-auth-blocked-p (condition)
  (and (typep condition 'dmx-import-http-error)
       (member (dmx-import-http-status-code-of condition)
               '(401 403)
               :test #'eql)))

(defun workspace-annotation-auth-blocked-condition-p (condition)
  (or (typep condition 'dmx-import-config-error)
      (workspace-annotation-http-auth-blocked-p condition)))

(defun workspace-annotation-topic-upsert-existing-topic-anonymous-p
    (client plan)
  (and (typep client 'http-dmx-import-client)
       plan
       (eql (dmx-workspace-annotation-write-plan-topic-action plan)
            :update)
       (dmx-workspace-annotation-write-plan-existing-topic-id plan)
       (null (effective-http-dmx-import-authorization-header client))
       (null (dmx-import-session-cookie-of client))))

(defun workspace-annotation-topic-upsert-endpoint-path-for-plan (plan)
  (cond
    ((null plan)
     "/core/topic")
    ((eql (dmx-workspace-annotation-write-plan-topic-action plan)
          :update)
     (if-let (topic-id (dmx-workspace-annotation-write-plan-existing-topic-id
                        plan))
       (dmx-topic-update-path topic-id)
       "/core/topic"))
    (t
     (dmx-topic-create-path))))

(defun signal-workspace-annotation-topic-upsert-auth-boundary
    (client plan)
  (let* ((topic-id (dmx-workspace-annotation-write-plan-existing-topic-id plan))
         (path (workspace-annotation-topic-upsert-endpoint-path-for-plan plan))
         (workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan))
         (cookie-values
           (http-dmx-import-request-cookie-values
            client
            :workspace-id workspace-id))
         (cookie-header
           (and cookie-values
                (format nil "~{~A~^; ~}" cookie-values)))
         (payload-json
           (workspace-annotation-write-plan-payload-json-string plan)))
    (error 'dmx-import-http-error
           :message
           (format nil
                   "AUTH-BOUNDARY: anonymous TOPIC-UPSERT for existing topic ~D was blocked locally before HTTP write"
                   topic-id)
           :url (or (normalize-http-client-url client path)
                    path)
           :status-code 401
           :response-body
           "{\"error\":\"AUTH-BOUNDARY\",\"reason\":\"anonymous-topic-upsert-blocked-before-http\"}"
           :evidence
           (list :method :put
                 :path path
                 :request-content-type "application/json; charset=utf-8"
                 :auth-mode-summary "anonymous"
                 :authorization-scheme nil
                 :bootstrap-ran-p nil
                 :cookie-shape (summarize-http-cookie-shape cookie-header)
                 :jsessionid-cookie-p
                 (and (cookie-contains-token-p cookie-header "JSESSIONID=")
                      t)
                 :workspace-cookie-p
                 (and (cookie-contains-token-p cookie-header
                                               "dmx_workspace_id=")
                      t)
                 :response-status-code 401
                 :response-reason-phrase "AUTH-BOUNDARY"
                 :request-body-length (length payload-json)
                 :request-body-prefix
                 (bounded-http-evidence-string payload-json)
                 :response-body-length
                 (length "{\"error\":\"AUTH-BOUNDARY\",\"reason\":\"anonymous-topic-upsert-blocked-before-http\"}")
                 :response-body-prefix
                 "{\"error\":\"AUTH-BOUNDARY\",\"reason\":\"anonymous-topic-upsert-blocked-before-http\"}"
                 :blocked-before-http-p t
                 :auth-boundary-classification
                 "topic-upsert-existing-topic-anonymous"))))

(defun workspace-annotation-assignment-auth-context
    (plan client topic-id condition)
  (let ((client-auth-context
          (workspace-annotation-client-auth-context client))
        (destination
          (and plan
               (dmx-workspace-annotation-write-plan-destination plan))))
    (append
     (list :workspace-id
           (and plan
                (dmx-workspace-annotation-write-plan-workspace-id plan))
           :workspace-topicmap-id
           (and plan
                (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan))
           :created-topic-id topic-id
           :assignment-endpoint-path
           (and plan
                (workspace-annotation-assignment-endpoint-path
                 (dmx-workspace-annotation-write-plan-workspace-id plan)
                 topic-id))
           :destination-source
           (and destination
                (dmx-workspace-annotation-destination-source destination))
           :destination-source-label
           (and destination
                (dmx-workspace-annotation-destination-source-label
                 (dmx-workspace-annotation-destination-source destination)))
           :workspace-source
           (and destination
                (dmx-workspace-annotation-destination-workspace-source
                 destination))
           :workspace-source-label
           (and destination
                (dmx-workspace-annotation-destination-source-label
                 (dmx-workspace-annotation-destination-workspace-source
                  destination)))
           :topicmap-source
           (and destination
                (dmx-workspace-annotation-destination-topicmap-source
                 destination))
           :topicmap-source-label
           (and destination
                (dmx-workspace-annotation-destination-source-label
                 (dmx-workspace-annotation-destination-topicmap-source
                  destination)))
           :destination-rationale
           (and destination
                (dmx-workspace-annotation-destination-rationale destination))
           :http-evidence
           (and (typep condition 'dmx-import-http-error)
                (dmx-import-http-evidence condition))
           :auth-missing-keys
           (workspace-annotation-auth-missing-keys condition))
     client-auth-context)))

(defun workspace-annotation-journal-endpoint-path (summary condition)
  (or (and (dmx-import-http-evidence condition)
           (or (getf (dmx-import-http-evidence condition) :path)
               (getf (dmx-import-http-evidence condition) :url)))
      (and summary
           (getf summary :existing-topic-id)
           (dmx-topic-update-path (getf summary :existing-topic-id)))))

(defun workspace-annotation-journal-preflight-auth-context
    (plan client summary condition)
  (let ((client-auth-context
          (workspace-annotation-client-auth-context client))
        (destination
          (and plan
               (dmx-workspace-annotation-write-plan-destination plan)))
        (http-evidence (dmx-import-http-evidence condition)))
    (append
     (list :workspace-id
           (and plan
                (dmx-workspace-annotation-write-plan-workspace-id plan))
           :workspace-topicmap-id
           (and plan
                (dmx-workspace-annotation-write-plan-workspace-topicmap-id
                 plan))
           :journal-companion-label
           (workspace-annotation-journal-preflight-label summary)
           :journal-topic-id
           (and summary
                (getf summary :existing-topic-id))
           :journal-endpoint-path
           (workspace-annotation-journal-endpoint-path summary condition)
           :journal-note-key
           (and summary
                (getf summary :note-key))
           :journal-note-uri
           (and summary
                (getf summary :note-uri))
           :journal-current-revision
           (and summary
                (getf summary :current-revision))
           :journal-subject-key
           (and summary
                (getf summary :subject-key))
           :journal-subject-lookup-kind
           (and summary
                (getf summary :subject-lookup-kind))
           :journal-subject-lookup-value
           (and summary
                (getf summary :subject-lookup-value))
           :destination-source
           (and destination
                (dmx-workspace-annotation-destination-source destination))
           :destination-source-label
           (and destination
                (dmx-workspace-annotation-destination-source-label
                 (dmx-workspace-annotation-destination-source destination)))
           :workspace-source
           (and destination
                (dmx-workspace-annotation-destination-workspace-source
                 destination))
           :workspace-source-label
           (and destination
                (dmx-workspace-annotation-destination-source-label
                 (dmx-workspace-annotation-destination-workspace-source
                  destination)))
           :topicmap-source
           (and destination
                (dmx-workspace-annotation-destination-topicmap-source
                 destination))
           :topicmap-source-label
           (and destination
                (dmx-workspace-annotation-destination-source-label
                 (dmx-workspace-annotation-destination-topicmap-source
                  destination)))
           :destination-rationale
           (and destination
                (dmx-workspace-annotation-destination-rationale destination))
           :auth-missing-keys
           (workspace-annotation-auth-missing-keys condition)
           :http-evidence http-evidence)
     client-auth-context)))

(defun workspace-annotation-guarded-boundary-auth-awaiting-p (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (eq (workspace-annotation-persistence-report-status-of report)
           :pending-auth)
       (member (workspace-annotation-persistence-report-failure-stage-of report)
               '(:workspace-assignment :topicmap-placement)
               :test #'eq)))

(defun workspace-annotation-pending-auth-p (report)
  (workspace-annotation-guarded-boundary-auth-awaiting-p report))

(defun workspace-annotation-journal-preflight-auth-blocked-p (report)
  (and (eq (workspace-annotation-persistence-report-failure-stage-of report)
           :prepare-transition)
       (workspace-annotation-persistence-report-journal-preflight-auth-context-of
        report)))

(defun workspace-annotation-journal-preflight-assigned-workspace-label
    (summary)
  (let ((assigned-workspace-id
          (and summary
               (getf summary :assigned-workspace-id)))
        (assigned-workspace-title
          (and summary
               (getf summary :assigned-workspace-title)))
        (assigned-workspace-status
          (and summary
               (getf summary :assigned-workspace-status))))
    (cond
      (assigned-workspace-id
       (or (dmx-workspace-annotation-workspace-label assigned-workspace-id)
           assigned-workspace-title
           (format nil "workspace (~D)" assigned-workspace-id)))
      ((eq assigned-workspace-status :none)
       "none")
      ((and (dmx-non-empty-string-p assigned-workspace-title)
            (not (eq assigned-workspace-status :lookup-error)))
       assigned-workspace-title)
      (t
       nil))))

(defun workspace-annotation-journal-preflight-unassigned-companion-topic-p
    (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (eq (workspace-annotation-persistence-report-failure-stage-of report)
           :prepare-transition)
       (typep (workspace-annotation-persistence-report-condition-of report)
              'dmx-workspace-journal-unassigned-companion-topic-error)))

(defun workspace-annotation-journal-preflight-repair-failed-p (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (eq (workspace-annotation-persistence-report-failure-stage-of report)
           :prepare-transition)
       (typep (workspace-annotation-persistence-report-condition-of report)
              'dmx-workspace-journal-companion-repair-failed-error)))

(defun workspace-annotation-persistence-report-resumed-past-prepare-transition-p
    (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (not (eq (workspace-annotation-persistence-report-failure-stage-of report)
                :prepare-transition))
       (let ((prepare-transition
               (workspace-annotation-persistence-stage-result
                report
                :prepare-transition)))
         (or (null prepare-transition)
             (eq (getf prepare-transition :status) :completed)))))

(defun workspace-annotation-journal-preflight-repair-summary (report)
  (let* ((stored-summary
           (and (typep report 'workspace-annotation-persistence-report)
                (workspace-annotation-persistence-report-journal-preflight-repair-summary-of
                 report)))
         (failure-summary
           (and (workspace-annotation-journal-preflight-repair-failed-p report)
                (dmx-workspace-journal-companion-repair-summary-of
                 (workspace-annotation-persistence-report-condition-of report))))
         (summary (or stored-summary failure-summary)))
    (when summary
      (let ((copy (copy-list summary)))
        (setf (getf copy :writable-workspace-context-used-p)
              (and (getf copy :requested-workspace-id) t)
              (getf copy :stale-topic-id)
              (or (getf copy :existing-topic-id)
                  (workspace-annotation-persistence-report-journal-preflight-existing-topic-id-of
                   report))
              (getf copy :current-topic-id)
              (or (getf copy :replacement-topic-id)
                  (workspace-annotation-persistence-report-journal-preflight-existing-topic-id-of
                   report))
              (getf copy :resumed-past-prepare-transition-p)
              (workspace-annotation-persistence-report-resumed-past-prepare-transition-p
               report)
              (getf copy :resumed-past-prepare-transition-label)
              (if (workspace-annotation-persistence-report-resumed-past-prepare-transition-p
                   report)
                  "yes"
                  "no"))
        copy))))

(defun workspace-annotation-journal-preflight-unassigned-companion-summary
    (report)
  (when (workspace-annotation-journal-preflight-unassigned-companion-topic-p
         report)
    (let* ((summary
             (workspace-annotation-persistence-report-journal-preflight-summary-of
              report))
           (journal-topic-id
             (workspace-annotation-persistence-report-journal-topic-id-of
              report))
           (workspace-id
             (or (workspace-annotation-persistence-report-workspace-id-of report)
                 (and (workspace-annotation-persistence-report-plan-of report)
                      (dmx-workspace-annotation-write-plan-workspace-id
                       (workspace-annotation-persistence-report-plan-of
                        report)))))
           (workspace-label
             (and workspace-id
                  (dmx-workspace-annotation-workspace-label workspace-id)))
           (direct-put-endpoint
             (and journal-topic-id
                  (dmx-topic-update-path journal-topic-id))))
      (list :retry-outcome-classification :unassigned-companion-topic
            :retry-outcome-classification-label "unassigned-companion-topic"
            :assigned-workspace-id
            (getf summary :assigned-workspace-id)
            :assigned-workspace-label
            (or (workspace-annotation-journal-preflight-assigned-workspace-label
                 summary)
                "none")
            :blocked-endpoint-path direct-put-endpoint
            :direct-put-failure-detail
            (if direct-put-endpoint
                (format nil
                        "Direct PUT ~A will fail because DMX derives existing-topic WRITE from the journal companion topic's assigned workspace, and this existing companion is unassigned."
                        direct-put-endpoint)
                "Direct journal companion update will fail because DMX derives existing-topic WRITE from the companion topic's assigned workspace, and this existing companion is unassigned.")
            :common-workspace-insufficiency-detail
            (if workspace-label
                (format nil
                        "~A is not sufficient unless the journal companion topic is actually assigned there."
                        workspace-label)
                "A Common/shared workspace is not sufficient unless the journal companion topic is actually assigned there.")))))

(defun workspace-annotation-auth-awaiting-p (report)
  (or (workspace-annotation-guarded-boundary-auth-awaiting-p report)
      (workspace-annotation-journal-preflight-auth-blocked-p report)))

(defun workspace-annotation-auth-awaiting-stage-p
    (failure-stage failure-condition
     &key persisted-topic-id journal-preflight-auth-blocked-p)
  (or journal-preflight-auth-blocked-p
      (and persisted-topic-id
           (member failure-stage '(:workspace-assignment :topicmap-placement)
                   :test #'eq)
           (typep failure-condition 'dmx-import-config-error))))

(defun workspace-annotation-persistence-report-journal-preflight-existing-topic-id-of
    (report)
  (getf (workspace-annotation-persistence-report-journal-preflight-summary-of
         report)
        :existing-topic-id))

(defun workspace-annotation-persistence-report-journal-topic-id-of (report)
  (or (getf (workspace-annotation-journal-preflight-repair-summary report)
            :replacement-topic-id)
      (workspace-annotation-persistence-report-journal-preflight-existing-topic-id-of
       report)))

(defun workspace-annotation-persistence-report-journal-topic-proxy-of (report)
  (let ((journal-topic-id
          (workspace-annotation-persistence-report-journal-topic-id-of report))
        (workspace-topicmap-id
          (workspace-annotation-persistence-report-workspace-topicmap-id-of
           report))
        (client (workspace-annotation-persistence-report-client-of report)))
    (and journal-topic-id
         workspace-topicmap-id
         (ignore-errors
           (make-dmx-topic-proxy
            :topic-id journal-topic-id
            :topicmap-id workspace-topicmap-id
            :base-url
            (or (and (typep client 'http-dmx-import-client)
                     (dmx-import-base-url-of client))
                *dmx-base-url*))))))

(defun workspace-annotation-journal-preflight-label (summary)
  (when summary
    (or (getf summary :note-title)
        (getf summary :note-uri)
        (getf summary :note-key)
        "the workspace journal companion")))

(defun workspace-annotation-journal-preflight-blocked-cause (condition)
  (cond
    ((typep condition 'dmx-workspace-journal-unassigned-companion-topic-error)
     "the existing journal companion topic is not assigned to any workspace")
    ((typep condition 'dmx-workspace-journal-companion-repair-failed-error)
     "repairing the existing unassigned journal companion topic failed")
    ((typep condition 'dmx-import-config-error)
     "DMX auth is missing")
    ((workspace-annotation-http-auth-blocked-p condition)
     "DMX auth is missing or unauthorized for the journal companion topic")
    (t
     (format nil "~A" condition))))

(defun workspace-annotation-journal-preflight-blocked-detail
    (summary workspace-label topicmap-label condition)
  (if (typep condition 'dmx-workspace-journal-unassigned-companion-topic-error)
      (format nil
              "Before annotation topic upsert could start, HyperDoc found that ~A for ~A in ~A is an existing journal companion topic with no assigned workspace. Direct PUT /core/topic/~D will fail because DMX derives existing-topic WRITE from the companion topic's assigned workspace. ~A This is the workspace journal preflight boundary, not annotation topic upsert, workspace assignment, or topicmap placement."
              (workspace-annotation-journal-preflight-label summary)
              (or workspace-label "the selected workspace")
              (or topicmap-label "the selected topicmap")
              (dmx-workspace-journal-unassigned-companion-topic-id-of condition)
              (if workspace-label
                  (format nil
                          "~A is not sufficient unless the journal companion topic is actually assigned there."
                          workspace-label)
                  "A Common/shared workspace is not sufficient unless the journal companion topic is actually assigned there."))
      (if (typep condition 'dmx-workspace-journal-companion-repair-failed-error)
          (let* ((repair-summary
                   (dmx-workspace-journal-companion-repair-summary-of condition))
                 (stale-topic-id (getf repair-summary :existing-topic-id))
                 (replacement-topic-id
                   (getf repair-summary :replacement-topic-id))
                 (repair-strategy-label
                   (or (getf repair-summary :repair-strategy-label)
                       (workspace-annotation-render-value
                        (getf repair-summary :repair-strategy))))
                 (repair-step-label
                   (or (getf repair-summary :repair-step-label)
                       (workspace-annotation-render-value
                        (getf repair-summary :repair-step))))
                 (failure-message
                   (or (getf repair-summary :repair-failure-message)
                       (format nil "~A" condition))))
            (format nil
                    "Before annotation topic upsert could start, HyperDoc detected that ~A for ~A in ~A is an existing unassigned journal companion topic and selected the ~A repair path. The repair failed~@[ after replacement topic ~D was created while the stale topic was retained as history~]~@[ at ~A~] for stale companion topic ~D because ~A. This remains the workspace journal preflight boundary, not annotation topic upsert, workspace assignment, or topicmap placement."
                    (workspace-annotation-journal-preflight-label summary)
                    (or workspace-label "the selected workspace")
                    (or topicmap-label "the selected topicmap")
                    repair-strategy-label
                    replacement-topic-id
                    repair-step-label
                    stale-topic-id
                    failure-message))
          (format nil
                  "Before annotation topic upsert could start, HyperDoc could not reconcile ~A for ~A in ~A because ~A. This is the workspace journal preflight boundary, not annotation topic upsert, workspace assignment, or topicmap placement."
                  (workspace-annotation-journal-preflight-label summary)
                  (or workspace-label "the selected workspace")
                  (or topicmap-label "the selected topicmap")
                  (workspace-annotation-journal-preflight-blocked-cause condition)))))

(defun workspace-annotation-json-field-value (json key)
  (cond
    ((hash-table-p json)
     (or (gethash key json)
         (gethash (string-downcase key) json)
         (gethash (string-upcase key) json)))
    ((listp json)
     (or (cdr (assoc key json :test #'string-equal))
         (getf json (intern (string-upcase key) :keyword))))
    (t
     nil)))

(defun workspace-annotation-http-evidence-response-cause (http-evidence)
  (when http-evidence
    (let* ((parsed
             (parse-http-response-body-json
              (or (getf http-evidence :response-body-prefix)
                  (getf http-evidence :response-body))))
           (cause
             (or (workspace-annotation-json-field-value parsed "cause")
                 (workspace-annotation-json-field-value parsed "message")
                 (and (stringp parsed) parsed))))
      (and (dmx-non-empty-string-p cause)
           cause))))

(defun workspace-annotation-extract-quoted-fragment-after
    (text marker quote-char)
  (when (and (dmx-non-empty-string-p text)
             (dmx-non-empty-string-p marker))
    (when-let (start (search marker text :test #'char-equal))
      (let ((content-start (+ start (length marker))))
        (when-let (content-end
                    (position quote-char
                              text
                              :start content-start))
          (subseq text content-start content-end))))))

(defun workspace-annotation-extract-token-after (text marker)
  (when (and (dmx-non-empty-string-p text)
             (dmx-non-empty-string-p marker))
    (when-let (start (search marker text :test #'char-equal))
      (let* ((token-start (+ start (length marker)))
             (token-end
               (or (position-if
                    (lambda (char)
                      (or (member char '(#\Space #\Tab #\Newline
                                         #\Return #\: #\, #\. #\;)
                                  :test #'char=)
                          (char= char #\))))
                    text
                    :start token-start)
                   (length text))))
        (when (< token-start token-end)
          (subseq text token-start token-end))))))

(defun workspace-annotation-extract-between-markers
    (text start-marker end-marker)
  (when (and (dmx-non-empty-string-p text)
             (dmx-non-empty-string-p start-marker)
             (dmx-non-empty-string-p end-marker))
    (when-let (start (search start-marker text :test #'char-equal))
      (let ((content-start (+ start (length start-marker))))
        (when-let (content-end
                    (search end-marker
                            text
                            :start2 content-start
                            :test #'char-equal))
          (string-trim '(#\Space #\Tab #\Newline #\Return)
                       (subseq text content-start content-end)))))))

(defun workspace-annotation-extract-integer-after-marker (text marker)
  (when (and (dmx-non-empty-string-p text)
             (dmx-non-empty-string-p marker))
    (when-let (start (search marker text :test #'char-equal))
      (let* ((digits-start (+ start (length marker)))
             (digits-end
               (or (position-if-not #'digit-char-p
                                    text
                                    :start digits-start)
                   (length text))))
        (and (< digits-start digits-end)
             (parse-positive-integer
              (subseq text digits-start digits-end)))))))

(defun workspace-annotation-topic-id-from-core-topic-path (path)
  (or (workspace-annotation-extract-integer-after-marker
       path
       "/core/topic/")
      (workspace-annotation-extract-integer-after-marker
       path
       "/core/assoc/")))

(defun workspace-annotation-authorization-denial-details
    (cause &key blocked-endpoint-path fallback-object-topic-id)
  (when (dmx-non-empty-string-p cause)
    (let* ((principal
             (or (workspace-annotation-extract-quoted-fragment-after
                  cause
                  "user \""
                  #\")
                 (workspace-annotation-extract-quoted-fragment-after
                  cause
                  "user '"
                  #\')
                 (workspace-annotation-extract-quoted-fragment-after
                  cause
                  "principal \""
                  #\")
                 (workspace-annotation-extract-quoted-fragment-after
                  cause
                  "principal '"
                  #\')
                 (workspace-annotation-extract-token-after cause "user ")
                 (workspace-annotation-extract-token-after cause "principal ")))
           (required-permission
             (workspace-annotation-extract-between-markers
              cause
              " has no "
              " permission"))
           (blocked-object-topic-id
             (or (workspace-annotation-extract-integer-after-marker
                  cause
                  " object ")
                 (workspace-annotation-extract-integer-after-marker
                  cause
                  " topic ")
                 (workspace-annotation-topic-id-from-core-topic-path
                  blocked-endpoint-path)
                 fallback-object-topic-id)))
      (when (and (dmx-non-empty-string-p principal)
                 (not (string-equal principal "anonymous")))
        (list :authenticated-principal principal
              :required-permission required-permission
              :blocked-object-topic-id blocked-object-topic-id
              :response-cause cause)))))

(defun workspace-annotation-journal-preflight-authorization-summary-data
    (report context)
  (when (and (typep report 'workspace-annotation-persistence-report)
             context)
    (let* ((blocked-endpoint-path
             (or (getf context :guarded-request-endpoint-path)
                 (getf context :final-failing-endpoint-path)))
           (response-cause
             (or (getf context :response-cause)
                 (workspace-annotation-http-evidence-response-cause
                  (getf context :http-evidence))))
           (denial-details
             (workspace-annotation-authorization-denial-details
              response-cause
              :blocked-endpoint-path blocked-endpoint-path
              :fallback-object-topic-id
              (workspace-annotation-persistence-report-journal-topic-id-of
               report))))
      (when (and (or (workspace-annotation-persistence-report-explicit-auth-retry-invoked-p
                      report)
                     (getf context :continuation-invoked-p))
                 (eq (workspace-annotation-persistence-report-failure-stage-of
                      report)
                     :prepare-transition)
                 (getf context :bootstrap-attempted-p)
                 (getf context :bootstrap-succeeded-p)
                 (getf context :guarded-request-retried-p)
                 (member (getf context :final-failing-status-code)
                         '(401 403))
                 (not (string-equal
                       (or (getf context :guarded-request-auth-mode-summary) "")
                       "anonymous"))
                 denial-details)
        (append
         (list :retry-outcome-classification :authorization-failed
               :retry-outcome-classification-label "authorization-failed"
               :authentication-succeeded-p t
               :authentication-status-label "succeeded"
               :authorization-failed-p t
               :authorization-status-label "failed"
               :blocked-endpoint-path blocked-endpoint-path)
         denial-details)))))

(defun workspace-annotation-journal-preflight-authorization-summary (report)
  (let ((context
          (and (typep report 'workspace-annotation-persistence-report)
               (workspace-annotation-persistence-report-explicit-auth-attempt-context-of
                report))))
    (or (and context
             (getf context :authorization-failed-p)
             (list :retry-outcome-classification
                   (getf context :retry-outcome-classification)
                   :retry-outcome-classification-label
                   (getf context :retry-outcome-classification-label)
                   :authentication-succeeded-p
                   (getf context :authentication-succeeded-p)
                   :authentication-status-label
                   (getf context :authentication-status-label)
                   :authorization-failed-p
                   (getf context :authorization-failed-p)
                   :authorization-status-label
                   (getf context :authorization-status-label)
                   :authenticated-principal
                   (getf context :authenticated-principal)
                   :required-permission
                   (getf context :required-permission)
                   :blocked-object-topic-id
                   (getf context :blocked-object-topic-id)
                   :blocked-endpoint-path
                   (getf context :blocked-endpoint-path)
                   :response-cause
                   (getf context :response-cause)))
        (workspace-annotation-journal-preflight-authorization-summary-data
         report
         context))))

(defun workspace-annotation-journal-preflight-authorization-blocked-p (report)
  (and (workspace-annotation-journal-preflight-authorization-summary report)
       t))

(defun workspace-annotation-explicit-auth-mode-or-nil (value)
  (and value
       (handler-case
           (normalize-http-dmx-import-auth-mode
            value
            'workspace-annotation-explicit-auth-mode-or-nil)
         (error ()
           nil))))

(defun workspace-annotation-explicit-auth-client-mode (client)
  (let* ((built-event
           (and (typep client 'http-dmx-import-client)
                (http-dmx-import-debug-event client :s3-explicit-auth-client-built)))
         (authorization-header
           (and (typep client 'http-dmx-import-client)
                (dmx-import-authorization-header-of client)))
         (authorization-scheme
           (and authorization-header
                (summarize-http-authorization-scheme authorization-header))))
    (or (and built-event
             (getf built-event :auth-mode))
        (and (typep client 'http-dmx-import-client)
             (dmx-import-session-login-required-p-of client)
             :basic)
        (and authorization-scheme
             (string= authorization-scheme "Bearer")
             :token)
        (and authorization-header
             :header))))

(defun workspace-annotation-explicit-auth-input-flags
    (client requested-auth-mode username password authorization-header auth-token)
  (let* ((built-event
           (and (typep client 'http-dmx-import-client)
                (http-dmx-import-debug-event client :s3-explicit-auth-client-built)))
         (client-header
           (and (typep client 'http-dmx-import-client)
                (dmx-import-authorization-header-of client)))
         (client-scheme
           (and client-header
                (summarize-http-authorization-scheme client-header)))
         (basic-header-p (and client-scheme
                              (string= client-scheme "Basic")))
         (bearer-header-p (and client-scheme
                               (string= client-scheme "Bearer"))))
    (flet ((flag (direct event inferred)
             (cond
               ((not (null direct)) (and direct t))
               ((not (null event)) (and event t))
               (t (and inferred t)))))
      (let* ((username-present-p
               (flag (and (dmx-non-empty-string-p username) t)
                     (and built-event (getf built-event :username-present-p))
                     (and (eq requested-auth-mode :basic)
                          basic-header-p)))
             (password-present-p
               (flag (and (dmx-non-empty-string-p password) t)
                     (and built-event (getf built-event :password-present-p))
                     (and (eq requested-auth-mode :basic)
                          basic-header-p)))
             (authorization-header-present-p
               (flag (and (dmx-non-empty-string-p authorization-header) t)
                     (and built-event
                          (getf built-event :authorization-header-present-p))
                     (and (eq requested-auth-mode :header)
                          client-header)))
             (auth-token-present-p
               (flag (and (dmx-non-empty-string-p auth-token) t)
                     (and built-event (getf built-event :auth-token-present-p))
                     (and (eq requested-auth-mode :token)
                          bearer-header-p)))
             (selected-mode-credentials-present-p
               (case requested-auth-mode
                 (:basic
                  (and username-present-p password-present-p))
                 (:header
                  authorization-header-present-p)
                 (:token
                  auth-token-present-p)
                 (otherwise
                  nil))))
        (list :username-present-p username-present-p
              :password-present-p password-present-p
              :authorization-header-present-p authorization-header-present-p
              :auth-token-present-p auth-token-present-p
              :selected-mode-credentials-present-p
              (and selected-mode-credentials-present-p t))))))

(defun workspace-annotation-explicit-auth-attempt-diagnosis
    (requested-auth-mode flags bootstrap-required-p bootstrap-attempted-p
     bootstrap-succeeded-p guarded-request-retried-p
     guarded-request-remained-anonymous-p local-failure-p
     authorization-failed-p)
  (let ((username-present-p (getf flags :username-present-p))
        (password-present-p (getf flags :password-present-p))
        (selected-mode-credentials-present-p
          (getf flags :selected-mode-credentials-present-p)))
    (cond
      (local-failure-p
       (if (and (eq requested-auth-mode :basic)
                (or username-present-p password-present-p))
           "Credentials captured but no bootstrap attempted."
           "Local continuation/build failure before network I/O."))
      ((and (eq requested-auth-mode :basic)
            bootstrap-required-p
            (not bootstrap-attempted-p)
            selected-mode-credentials-present-p)
       "Credentials captured but no bootstrap attempted.")
      ((and bootstrap-attempted-p
            (not bootstrap-succeeded-p))
       "Bootstrap attempted and failed.")
      ((and bootstrap-succeeded-p
            guarded-request-retried-p
            guarded-request-remained-anonymous-p)
       "Bootstrap succeeded, but the guarded journal PUT remained anonymous unexpectedly.")
      ((and bootstrap-succeeded-p
            guarded-request-retried-p
            authorization-failed-p)
       "Authentication succeeded, but the authenticated principal is not authorized to write the journal companion topic.")
      ((and bootstrap-succeeded-p
            guarded-request-retried-p)
       "Bootstrap succeeded, but the guarded journal PUT still failed.")
      (guarded-request-retried-p
       "Explicit-auth retry reached the guarded journal PUT and still failed.")
      (bootstrap-attempted-p
       "Explicit-auth retry failed during bootstrap.")
      (t
       "Explicit-auth retry failed before network I/O."))))

(defun workspace-annotation-format-explicit-auth-retry-time (universal-time)
  (when universal-time
    (multiple-value-bind (second minute hour day month year)
        (decode-universal-time universal-time)
      (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
              year month day hour minute second))))

(defun workspace-annotation-explicit-auth-retry-request-id
    (&optional (prefix "journal-preflight-explicit-auth-retry"))
  (format nil "~A-~D-~D"
          prefix
          (get-universal-time)
          (mod (get-internal-real-time) 1000000)))

(defun workspace-annotation-explicit-auth-retry-source-label (source)
  (case source
    (:journal-preflight-explicit-auth
     "Journal-preflight explicit-auth continuation")
    (otherwise
     (and source
          (format nil "~A" source)))))

(defun workspace-annotation-explicit-auth-attempt-context
    (report client condition &key auth-mode username password
       authorization-header auth-token local-failure-stage
       continuation-request-id continuation-executed-at continuation-source)
  (let* ((requested-auth-mode
           (or (workspace-annotation-explicit-auth-mode-or-nil auth-mode)
               (workspace-annotation-explicit-auth-client-mode client)))
         (flags
           (workspace-annotation-explicit-auth-input-flags
            client
            requested-auth-mode
            username
            password
            authorization-header
            auth-token))
         (journal-auth-context
           (workspace-annotation-persistence-report-journal-preflight-auth-context-of
            report))
         (final-http-evidence
           (or (dmx-import-http-evidence condition)
               (and (typep client 'http-dmx-import-client)
                    (dmx-import-last-http-transaction-evidence-of client))))
         (bootstrap-request
           (and (typep client 'http-dmx-import-client)
                (http-dmx-import-debug-event client :s5-bootstrap-request-sent)))
         (bootstrap-response
           (and (typep client 'http-dmx-import-client)
                (http-dmx-import-debug-event client :s6-bootstrap-response-received)))
         (session-event
           (and (typep client 'http-dmx-import-client)
                (http-dmx-import-debug-event client :s7-session-material-extracted)))
         (bootstrap-required-p
           (and (or (eq requested-auth-mode :basic)
                    (and (typep client 'http-dmx-import-client)
                         (dmx-import-session-login-required-p-of client)))
                t))
         (bootstrap-endpoint-path
           (or (and bootstrap-request (getf bootstrap-request :path))
               (and bootstrap-response (getf bootstrap-response :path))
               (and final-http-evidence
                    (let ((path (or (getf final-http-evidence :path)
                                    (getf final-http-evidence :url))))
                      (and path
                           (search "/access-control/login"
                                   path
                                   :test #'char-equal)
                           path)))))
         (bootstrap-attempted-p
           (and (or bootstrap-request
                    bootstrap-response
                    bootstrap-endpoint-path)
                t))
         (bootstrap-request-auth-mode-summary
           (or (and bootstrap-request
                    (getf bootstrap-request :auth-mode-summary))
               (and bootstrap-attempted-p
                    final-http-evidence
                    (equal (or (getf final-http-evidence :path)
                               (getf final-http-evidence :url))
                           bootstrap-endpoint-path)
                    (getf final-http-evidence :auth-mode-summary))))
         (bootstrap-request-authorization-scheme
           (or (and bootstrap-request
                    (getf bootstrap-request :authorization-scheme))
               (and bootstrap-attempted-p
                    final-http-evidence
                    (equal (or (getf final-http-evidence :path)
                               (getf final-http-evidence :url))
                           bootstrap-endpoint-path)
                    (getf final-http-evidence :authorization-scheme))))
         (bootstrap-response-status-code
           (or (and bootstrap-response
                    (getf bootstrap-response :status-code))
               (and bootstrap-attempted-p
                    final-http-evidence
                    (equal (or (getf final-http-evidence :path)
                               (getf final-http-evidence :url))
                           bootstrap-endpoint-path)
                    (getf final-http-evidence :response-status-code))))
         (bootstrap-response-reason-phrase
           (or (and bootstrap-response
                    (getf bootstrap-response :reason-phrase))
               (and bootstrap-attempted-p
                    final-http-evidence
                    (equal (or (getf final-http-evidence :path)
                               (getf final-http-evidence :url))
                           bootstrap-endpoint-path)
                    (getf final-http-evidence :response-reason-phrase))))
         (bootstrap-set-cookie-jsessionid-p
           (or (and bootstrap-response
                    (getf bootstrap-response :set-cookie-jsessionid-p))
               (and final-http-evidence
                    (getf final-http-evidence :bootstrap-set-cookie-jsessionid-p))))
         (session-cookie-captured-p
           (or (and session-event
                    (getf session-event :session-cookie-captured-p))
               (and (typep client 'http-dmx-import-client)
                    (dmx-import-session-cookie-of client)
                    t)
               (and final-http-evidence
                    (getf final-http-evidence :session-cookie-captured-p))))
         (bootstrap-succeeded-p
           (and bootstrap-attempted-p
                bootstrap-response-status-code
                (http-success-status-p bootstrap-response-status-code)
                session-cookie-captured-p))
         (journal-endpoint-path
           (or (and journal-auth-context
                    (getf journal-auth-context :journal-endpoint-path))
               (and (workspace-annotation-persistence-report-journal-topic-id-of
                     report)
                    (dmx-topic-update-path
                     (workspace-annotation-persistence-report-journal-topic-id-of
                      report)))))
         (final-failing-endpoint-path
           (or (and final-http-evidence
                    (or (getf final-http-evidence :path)
                        (getf final-http-evidence :url)))
               (and (typep condition 'dmx-import-http-error)
                    (dmx-import-http-url-of condition))))
         (final-failing-status-code
           (or (and final-http-evidence
                    (getf final-http-evidence :response-status-code))
               (and (typep condition 'dmx-import-http-error)
                    (dmx-import-http-status-code-of condition))))
         (final-failing-reason-phrase
           (or (and final-http-evidence
                    (getf final-http-evidence :response-reason-phrase))
               nil))
         (guarded-request-retried-p
           (and journal-endpoint-path
                final-failing-endpoint-path
                (string-equal journal-endpoint-path
                              final-failing-endpoint-path)
                t))
         (guarded-request-auth-mode-summary
           (and guarded-request-retried-p
                final-http-evidence
                (getf final-http-evidence :auth-mode-summary)))
         (guarded-request-authorization-scheme
           (and guarded-request-retried-p
                final-http-evidence
                (getf final-http-evidence :authorization-scheme)))
         (guarded-request-cookie-shape
           (and guarded-request-retried-p
                final-http-evidence
                (getf final-http-evidence :cookie-shape)))
         (guarded-request-remained-anonymous-p
           (and guarded-request-retried-p
                (string-equal (or guarded-request-auth-mode-summary "")
                              "anonymous")
                t))
         (response-cause
           (or (workspace-annotation-http-evidence-response-cause
                final-http-evidence)
               (and condition
                    (format nil "~A" condition))))
         (local-failure-p
           (and (null final-http-evidence)
                (not bootstrap-attempted-p)
                (not guarded-request-retried-p)
                t))
         (base-context
           (append
            (list :requested-auth-mode requested-auth-mode
                  :requested-auth-mode-label
                  (and requested-auth-mode
                       (workspace-annotation-auth-mode-label requested-auth-mode))
                  :continuation-invoked-p t
                  :retry-request-id continuation-request-id
                  :retry-executed-at continuation-executed-at
                  :retry-executed-at-label
                  (workspace-annotation-format-explicit-auth-retry-time
                   continuation-executed-at)
                  :retry-mode-used requested-auth-mode
                  :retry-mode-used-label
                  (and requested-auth-mode
                       (workspace-annotation-auth-mode-label requested-auth-mode))
                  :retry-source continuation-source
                  :retry-source-label
                  (workspace-annotation-explicit-auth-retry-source-label
                   continuation-source)
                  :retry-evidence-version
                  *workspace-annotation-explicit-auth-retry-evidence-version*
                  :bootstrap-required-p bootstrap-required-p
                  :bootstrap-attempted-p bootstrap-attempted-p
                  :bootstrap-endpoint-path bootstrap-endpoint-path
                  :bootstrap-request-auth-mode-summary
                  bootstrap-request-auth-mode-summary
                  :bootstrap-request-authorization-scheme
                  bootstrap-request-authorization-scheme
                  :bootstrap-response-status-code bootstrap-response-status-code
                  :bootstrap-response-reason-phrase
                  bootstrap-response-reason-phrase
                  :bootstrap-set-cookie-jsessionid-p
                  (and bootstrap-set-cookie-jsessionid-p t)
                  :session-cookie-captured-p
                  (and session-cookie-captured-p t)
                  :bootstrap-succeeded-p
                  (and bootstrap-succeeded-p t)
                  :guarded-request-retried-p
                  guarded-request-retried-p
                  :guarded-request-endpoint-path
                  (and guarded-request-retried-p final-failing-endpoint-path)
                  :guarded-request-auth-mode-summary
                  guarded-request-auth-mode-summary
                  :guarded-request-authorization-scheme
                  guarded-request-authorization-scheme
                  :guarded-request-cookie-shape guarded-request-cookie-shape
                  :guarded-request-remained-anonymous-p
                  guarded-request-remained-anonymous-p
                  :final-failing-endpoint-path final-failing-endpoint-path
                  :final-failing-status-code final-failing-status-code
                  :final-failing-reason-phrase final-failing-reason-phrase
                  :response-cause response-cause
                  :local-failure-p local-failure-p
                  :local-failure-stage local-failure-stage
                  :condition-text
                  (and condition
                       (format nil "~A" condition))
                  :http-evidence final-http-evidence)
            flags))
         (authorization-summary
           (workspace-annotation-journal-preflight-authorization-summary-data
            report
            base-context)))
    (append
     base-context
     authorization-summary
     (list :attempt-diagnosis
           (workspace-annotation-explicit-auth-attempt-diagnosis
            requested-auth-mode
            flags
            bootstrap-required-p
            bootstrap-attempted-p
            bootstrap-succeeded-p
            guarded-request-retried-p
            guarded-request-remained-anonymous-p
            local-failure-p
            (and authorization-summary
                 (getf authorization-summary :authorization-failed-p)))))))

(defun workspace-annotation-persistence-report-saved-topic-id-of (report)
  (or (workspace-annotation-persistence-report-persisted-topic-id-of report)
      (let ((plan (workspace-annotation-persistence-report-plan-of report)))
        (or (and plan
                 (dmx-workspace-annotation-write-plan-existing-topic-id plan))
            (and plan
                 (if-let (topic
                          (dmx-workspace-annotation-write-plan-existing-topic
                           plan))
                   (dmx-import-object-id topic)))))
      (let ((annotation
              (workspace-annotation-persistence-report-annotation-of report)))
        (and (typep annotation 'workspace-dock-annotation)
             (workspace-annotation-topic-id-of annotation)))))

(defun workspace-annotation-persistence-report-existing-saved-topic-p (report)
  (let ((plan (workspace-annotation-persistence-report-plan-of report)))
    (and plan
         (eq (dmx-workspace-annotation-write-plan-topic-action plan)
             :update)
         (workspace-annotation-persistence-report-saved-topic-id-of report))))

(defun workspace-annotation-persistence-report-saved-storage-mode-of (report)
  (or (if-let (persisted
               (workspace-annotation-persistence-report-persisted-annotation-of
                report))
        (workspace-annotation-storage-mode-of persisted))
      (let ((annotation
              (workspace-annotation-persistence-report-annotation-of report)))
        (and (typep annotation 'workspace-dock-annotation)
             (workspace-annotation-storage-mode-of annotation)))
      (let ((plan (workspace-annotation-persistence-report-plan-of report)))
        (and plan
             (dmx-workspace-annotation-write-plan-storage-mode plan)))))

(defun workspace-annotation-persistence-report-saved-carrier-type-uri-of
    (report)
  (or (if-let (persisted
               (workspace-annotation-persistence-report-persisted-annotation-of
                report))
        (workspace-annotation-carrier-type-uri-of persisted))
      (let ((annotation
              (workspace-annotation-persistence-report-annotation-of report)))
        (and (typep annotation 'workspace-dock-annotation)
             (workspace-annotation-carrier-type-uri-of annotation)))
      (let ((plan (workspace-annotation-persistence-report-plan-of report)))
        (and plan
             (dmx-workspace-annotation-write-plan-carrier-type-uri plan)))))

(defun workspace-annotation-persistence-report-saved-annotation-of (report)
  (or (workspace-annotation-persistence-report-persisted-annotation-of report)
      (let* ((annotation
               (workspace-annotation-persistence-report-annotation-of report))
             (saved-topic-id
               (workspace-annotation-persistence-report-saved-topic-id-of
                report)))
        (and (typep annotation 'workspace-dock-annotation)
             (eql (workspace-annotation-topic-id-of annotation)
                  saved-topic-id)
             annotation))
      (let ((saved-topic-id
              (workspace-annotation-persistence-report-saved-topic-id-of
               report))
            (workspace-topicmap-id
              (workspace-annotation-persistence-report-workspace-topicmap-id-of
               report))
            (client (workspace-annotation-persistence-report-client-of report)))
        (and saved-topic-id
             workspace-topicmap-id
             client
             (ignore-errors
               (read-dmx-workspace-annotation
                :topic-id saved-topic-id
                :workspace-topicmap-id workspace-topicmap-id
                :client client))))))

(defun workspace-annotation-persistence-report-saved-carrier-topic-proxy-of
    (report)
  (let ((saved-topic-id
          (workspace-annotation-persistence-report-saved-topic-id-of report))
        (workspace-topicmap-id
          (workspace-annotation-persistence-report-workspace-topicmap-id-of
           report))
        (client (workspace-annotation-persistence-report-client-of report)))
    (and saved-topic-id
         workspace-topicmap-id
         (ignore-errors
           (make-dmx-topic-proxy
            :topic-id saved-topic-id
            :topicmap-id workspace-topicmap-id
            :base-url
            (or (and (typep client 'http-dmx-import-client)
                     (dmx-import-base-url-of client))
                *dmx-base-url*))))))

(defun workspace-annotation-persistence-live-stage-label (stage)
  (case stage
    (:topic-upsert "TOPIC-UPSERT")
    (:workspace-assignment "WORKSPACE-ASSIGNMENT")
    (:topicmap-placement "TOPICMAP-PLACEMENT")
    (:journal-transition "JOURNAL-RECORDING")
    (:reopen-persisted-annotation "REOPEN")
    (otherwise
     (workspace-annotation-persistence-stage-label stage))))

(defun workspace-annotation-persistence-stage-absence-kind-label (kind)
  (case kind
    (:not-reached-because-prior-stage-failed
     "not-reached-because-prior-stage-failed")
    (:not-applicable-in-this-mode
     "not-applicable-in-this-mode")
    (:credentials-pending
     "credentials-pending")
    (:unavailable-without-live-auth
     "unavailable-without-live-auth")
    (otherwise
     (format nil "~(~A~)" kind))))

(defun workspace-annotation-persistence-live-stage-position (stage)
  (position stage
            *dmx-workspace-annotation-live-report-stage-order*
            :test #'eq))

(defun workspace-annotation-persistence-live-stage-before-p
    (left-stage right-stage)
  (let ((left (workspace-annotation-persistence-live-stage-position left-stage))
        (right (workspace-annotation-persistence-live-stage-position
                right-stage)))
    (and left right (< left right))))

(defun workspace-annotation-persistence-report-base-url (report)
  (let ((client (workspace-annotation-persistence-report-client-of report)))
    (or (and (typep client 'http-dmx-import-client)
             (dmx-import-base-url-of client))
        *dmx-base-url*)))

(defun workspace-annotation-persistence-report-topic-proxy
    (report topic-id &key topicmap-id)
  (let ((resolved-topicmap-id
          (or topicmap-id
              (workspace-annotation-persistence-report-workspace-topicmap-id-of
               report))))
    (and topic-id
         resolved-topicmap-id
         (ignore-errors
           (make-dmx-topic-proxy
            :topic-id topic-id
            :topicmap-id resolved-topicmap-id
            :base-url
            (workspace-annotation-persistence-report-base-url report))))))

(defun workspace-annotation-persistence-report-workspace-proxy-of (report)
  (let ((workspace-id
          (workspace-annotation-persistence-report-workspace-id-of report)))
    (and workspace-id
         (workspace-annotation-persistence-report-topic-proxy
          report
          workspace-id))))

(defun workspace-annotation-persistence-report-topicmap-proxy-of (report)
  (let ((topicmap-id
          (workspace-annotation-persistence-report-workspace-topicmap-id-of
           report)))
    (and topicmap-id
         (ignore-errors
           (make-dmx-topicmap-proxy
            topicmap-id
            :base-url
            (workspace-annotation-persistence-report-base-url report))))))

(defun workspace-annotation-persistence-report-saved-topic-proxy-of (report)
  (workspace-annotation-persistence-report-topic-proxy
   report
   (workspace-annotation-persistence-report-saved-topic-id-of report)))

(defun workspace-annotation-persistence-report-topic-upsert-auth-blocked-p
    (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (eq (workspace-annotation-persistence-report-failure-stage-of report)
           :topic-upsert)
       (workspace-annotation-http-auth-blocked-p
        (workspace-annotation-persistence-report-condition-of report))
       (workspace-annotation-persistence-report-saved-topic-id-of report)))

(defun workspace-annotation-persistence-report-topic-upsert-evidence-path
    (report)
  (let ((evidence
          (workspace-annotation-persistence-report-topic-upsert-evidence-of
           report))
        (topic-id
          (workspace-annotation-persistence-report-saved-topic-id-of report)))
    (or (getf evidence :path)
        (and topic-id
             (dmx-topic-update-path topic-id))
        "/core/topic")))

(defun workspace-annotation-persistence-report-topic-upsert-endpoint-label
    (report)
  (let* ((evidence
           (workspace-annotation-persistence-report-topic-upsert-evidence-of
            report))
         (method (or (getf evidence :method)
                     (if (eq (and (workspace-annotation-persistence-report-plan-of
                                   report)
                                  (dmx-workspace-annotation-write-plan-topic-action
                                   (workspace-annotation-persistence-report-plan-of
                                    report)))
                             :update)
                         :put
                         :post)))
         (path
           (workspace-annotation-persistence-report-topic-upsert-evidence-path
            report)))
    (and path
         (format nil "~:@(~A~) ~A" method path))))

(defun workspace-annotation-persistence-stage-boundary-or-endpoint
    (report stage)
  (let* ((topic-id
           (workspace-annotation-persistence-report-saved-topic-id-of report))
         (workspace-id
           (workspace-annotation-persistence-report-workspace-id-of report))
         (topicmap-id
           (workspace-annotation-persistence-report-workspace-topicmap-id-of
            report)))
    (case stage
      (:topic-upsert
       (workspace-annotation-persistence-report-topic-upsert-endpoint-label
        report))
      (:workspace-assignment
       (and workspace-id
            topic-id
            (format nil
                    "PUT ~A"
                    (workspace-annotation-assignment-endpoint-path
                     workspace-id
                     topic-id))))
      (:topicmap-placement
       (and topicmap-id
            topic-id
            (format nil
                    "POST ~A"
                    (dmx-topicmap-add-topic-path topicmap-id topic-id))))
      (:journal-transition
       (if-let (journal-topic-id
                (workspace-annotation-persistence-report-journal-topic-id-of
                 report))
         (format nil
                 "dmx-workspace-journal-record-transition -> companion topic ~D"
                 journal-topic-id)
         "dmx-workspace-journal-record-transition"))
      (:reopen-persisted-annotation
       (and topicmap-id
            topic-id
            (format nil
                    "read-dmx-workspace-annotation topic ~D in topicmap ~D"
                    topic-id
                    topicmap-id)))
      (otherwise
       nil))))

(defun workspace-annotation-persistence-topic-upsert-resolution-summary
    (report)
  (let* ((topic-id
           (workspace-annotation-persistence-report-saved-topic-id-of report))
         (evidence
           (workspace-annotation-persistence-report-topic-upsert-evidence-of
            report))
         (status-code (or (getf evidence :response-status-code) 401)))
    (if (getf evidence :blocked-before-http-p)
        (format nil
                "FAILED at local AUTH-BOUNDARY because TOPIC-UPSERT would have attempted an anonymous write to existing topic ~D. The request was blocked before HTTP PUT. Workspace assignment, topicmap placement, journal recording, and reopen did not run."
                topic-id)
        (format nil
                "FAILED because TOPIC-UPSERT attempted an anonymous write to existing topic ~D and DMX returned ~D. This is an authentication-boundary failure before workspace assignment, topicmap placement, journal recording, and reopen."
                topic-id
                status-code))))

(defun workspace-annotation-persistence-topic-upsert-blocking-condition
    (report)
  (let* ((evidence
           (workspace-annotation-persistence-report-topic-upsert-evidence-of
            report))
         (auth-mode (or (getf evidence :auth-mode-summary)
                        "anonymous"))
         (status-code (or (getf evidence :response-status-code) 401)))
    (if (getf evidence :blocked-before-http-p)
        (format nil
                "AUTH-BOUNDARY blocked locally: ~A ~A before HTTP request"
                auth-mode
                (workspace-annotation-persistence-report-topic-upsert-endpoint-label
                 report))
        (format nil
                "~A ~A returned ~D"
                auth-mode
                (workspace-annotation-persistence-report-topic-upsert-endpoint-label
                 report)
                status-code))))

(defun workspace-annotation-persistence-report-continue-target (report)
  (let ((topic-id
          (workspace-annotation-persistence-report-saved-topic-id-of report)))
    (make-workspace-annotation-path-next-step-target
     "continue-workspace-annotation"
     "continue_workspace_annotation"
     "continue_workspace_annotation"
     :continue
     t
     '(:workspace-assignment :topicmap-placement
       :journal-transition :reopen-persisted-annotation)
     :summary
     (format nil
             "Bootstrap authenticated DMX session, then rerun the guarded annotation continuation from preserved topic ~D instead of retrying a raw anonymous topic PUT."
             topic-id))))

(defun workspace-annotation-persistence-report-repair-target (report)
  (declare (ignore report))
  (make-workspace-annotation-path-next-step-target
   "repair-workspace-topic-assignment"
   "repair_workspace_topic_assignment"
   "repair_workspace_topic_assignment"
   :repair
   t
   '(:workspace-assignment)
   :summary
   "Repair workspace assignment only. This keeps workspace ownership separate from topicmap placement."))

(defun workspace-annotation-persistence-report-recommended-next-step-targets
    (report stage)
  (cond
    ((and (workspace-annotation-persistence-report-saved-topic-id-of report)
          (or (workspace-annotation-persistence-report-topic-upsert-auth-blocked-p
               report)
              (workspace-annotation-pending-auth-p report)
              (workspace-annotation-journal-preflight-auth-blocked-p report)))
     (list (workspace-annotation-persistence-report-continue-target report)))
    ((and (eq stage :workspace-assignment)
          (not (workspace-annotation-persistence-report-saved-topic-id-of report)))
     (list (workspace-annotation-persistence-report-repair-target report)))
    (t
     nil)))

(defun workspace-annotation-persistence-report-success-readback-of (report)
  (let* ((topic-id
           (workspace-annotation-persistence-report-saved-topic-id-of report))
         (topic-proxy
           (workspace-annotation-persistence-report-saved-topic-proxy-of report))
         (workspace-proxy
           (workspace-annotation-persistence-report-workspace-proxy-of report))
         (topicmap-proxy
           (workspace-annotation-persistence-report-topicmap-proxy-of report)))
    (when topic-id
      (make-instance
       'workspace-annotation-persistence-success-readback
       :id (format nil
                   "workspace-annotation-success-readback/~D"
                   topic-id)
       :title (format nil
                      "Success readback for topic ~D"
                      topic-id)
       :summary
       (format nil
               "Success means topic ~D updates successfully, then reads back assigned to workspace 919815, present in topicmap 919822, journaled, and reopenable as workspace-dock-annotation."
               topic-id)
       :topic-proxy topic-proxy
       :workspace-proxy workspace-proxy
       :topicmap-proxy topicmap-proxy
       :journal-expectation
       "JOURNAL-RECORDING completes on the guarded workspace journal path."
       :reopen-expectation
       "REOPEN returns a workspace-dock-annotation for the saved topic."))))

(defun simple-context-window-saved-topic-success-readback ()
  (make-instance
   'workspace-annotation-persistence-success-readback
   :id "simple-context-window-saved-topic-success-readback/922586"
   :title "Saved topic 922586 in context-window"
   :summary
   "This example shows one already-saved topic read back through workspace 919815 and topicmap 919822."
   :topic-proxy
   (make-dmx-shared-workspace-topic-proxy 922586)
   :workspace-proxy
   (make-dmx-shared-workspace-topic-proxy *dmx-context-window-workspace-id*)
   :topicmap-proxy
   (make-dmx-topicmap-proxy *dmx-context-window-topicmap-id*)
   :journal-expectation
   "JOURNAL-RECORDING is part of the represented saved-state contract for this already-saved topic."
   :reopen-expectation
   "REOPEN stays an expectation on this example surface; the page demonstrates saved-state readback, not a live save from this shell."))

(defun workspace-annotation-persistence-report-resolution-of (report)
  (when (workspace-annotation-persistence-report-topic-upsert-auth-blocked-p
         report)
    (make-instance
     'workspace-annotation-persistence-resolution
     :id (format nil
                 "workspace-annotation-resolution/~D/~(~A~)"
                 (workspace-annotation-persistence-report-saved-topic-id-of
                  report)
                 (workspace-annotation-persistence-report-failure-stage-of
                  report))
     :title "Resolution"
     :summary
     (workspace-annotation-persistence-topic-upsert-resolution-summary
      report)
     :report report
     :stage :topic-upsert
     :stage-label
     (workspace-annotation-persistence-live-stage-label :topic-upsert)
     :blocking-condition
     (workspace-annotation-persistence-topic-upsert-blocking-condition
      report)
     :required-next-action
     (format nil
             "Do not retry anonymously. Authenticate explicitly using the existing explicit-auth path. If username/password mode is used, bootstrap the DMX session first with POST /access-control/login and obtain JSESSIONID. Then rerun the guarded continue_workspace_annotation path from preserved topic ~D."
             (workspace-annotation-persistence-report-saved-topic-id-of report))
     :required-auth-mode
     "Explicit action-time credentials; if username/password is chosen, obtain JSESSIONID first via login bootstrap."
     :recommended-tool-path
     (workspace-annotation-persistence-report-continue-target report)
     :success-readback
     (workspace-annotation-persistence-report-success-readback-of report)
     :do-not-do
     "Do not keep retrying the same anonymous/service-auth path as though the 401 were ambiguous.")))

(defun workspace-annotation-persistence-matrix-stage-status (report stage)
  (let ((entry (workspace-annotation-persistence-stage-result report stage)))
    (cond
      ((and entry (eq (getf entry :status) :completed))
       :completed)
      ((and entry (eq (getf entry :status) :error))
       :failed)
      ((and entry (eq (getf entry :status) :skipped))
       :not-applicable)
      ((and (workspace-annotation-persistence-report-failure-stage-of report)
            (workspace-annotation-persistence-live-stage-before-p
             (workspace-annotation-persistence-report-failure-stage-of report)
             stage))
       :not-reached)
      (t
       :pending))))

(defun workspace-annotation-persistence-stage-evidence (report stage)
  (case stage
    (:topic-upsert
     (workspace-annotation-persistence-report-topic-upsert-evidence-of report))
    (:workspace-assignment
     (and (eq (workspace-annotation-persistence-report-failure-stage-of report)
              :workspace-assignment)
          (workspace-annotation-persistence-report-assignment-auth-context-of
           report)))
    (:journal-transition
     (and (eq (workspace-annotation-persistence-report-failure-stage-of report)
              :prepare-transition)
          (workspace-annotation-persistence-report-journal-preflight-auth-context-of
           report)))
    (otherwise
     nil)))

(defun workspace-annotation-persistence-stage-absence-of (report stage)
  (let* ((entry (workspace-annotation-persistence-stage-result report stage))
         (failure-stage
           (workspace-annotation-persistence-report-failure-stage-of report))
         (resolution
           (workspace-annotation-persistence-report-resolution-of report))
         (next-step-targets
           (or (and resolution
                    (list
                     (workspace-annotation-persistence-resolution-recommended-tool-path-of
                      resolution)))
               (workspace-annotation-persistence-report-recommended-next-step-targets
                report
                stage)))
         (success-readback
           (or (and resolution
                    (workspace-annotation-persistence-resolution-success-readback-of
                     resolution))
               (workspace-annotation-persistence-report-success-readback-of
                report))))
    (cond
      ((and entry
            (eq (getf entry :status) :skipped))
       (make-instance
        'workspace-annotation-persistence-stage-absence
        :id (format nil
                    "workspace-annotation-stage-absence/~(~A~)/not-applicable"
                    stage)
        :title (format nil
                       "~A absence"
                       (workspace-annotation-persistence-live-stage-label
                        stage))
        :summary
        (or (getf entry :summary)
            "No write was needed at this stage.")
        :kind :not-applicable-in-this-mode
        :stage stage
        :stage-label
        (workspace-annotation-persistence-live-stage-label stage)
        :status :not-applicable
        :boundary-or-endpoint
        (workspace-annotation-persistence-stage-boundary-or-endpoint
         report
         stage)
        :reason
        (or (getf entry :detail)
            (getf entry :summary))
        :next-step-targets next-step-targets
        :success-readback success-readback))
      ((and (eq stage failure-stage)
            (or (workspace-annotation-persistence-report-topic-upsert-auth-blocked-p
                 report)
                (workspace-annotation-pending-auth-p report)
                (workspace-annotation-journal-preflight-auth-blocked-p report)))
       (make-instance
        'workspace-annotation-persistence-stage-absence
        :id (format nil
                    "workspace-annotation-stage-absence/~(~A~)/credentials-pending"
                    stage)
        :title (format nil
                       "~A absence"
                       (workspace-annotation-persistence-live-stage-label
                        stage))
        :summary
        (or (and resolution
                 (summary-of resolution))
            (or (getf entry :detail)
                (getf entry :summary)))
        :kind :credentials-pending
        :stage stage
        :stage-label
        (workspace-annotation-persistence-live-stage-label stage)
        :status :failed
        :boundary-or-endpoint
        (workspace-annotation-persistence-stage-boundary-or-endpoint
         report
         stage)
        :reason
        (or (and resolution
                 (workspace-annotation-persistence-resolution-blocking-condition-of
                  resolution))
            (getf entry :detail)
            (and (workspace-annotation-persistence-report-condition-of report)
                 (format nil
                         "~A"
                         (workspace-annotation-persistence-report-condition-of
                          report))))
        :next-step-targets next-step-targets
        :success-readback success-readback))
      ((and failure-stage
            (workspace-annotation-persistence-live-stage-before-p
             failure-stage
             stage))
       (make-instance
        'workspace-annotation-persistence-stage-absence
        :id (format nil
                    "workspace-annotation-stage-absence/~(~A~)/not-reached"
                    stage)
        :title (format nil
                       "~A absence"
                       (workspace-annotation-persistence-live-stage-label
                        stage))
        :summary
        (format nil
                "~A was not reached because ~A failed earlier."
                (workspace-annotation-persistence-live-stage-label stage)
                (workspace-annotation-persistence-live-stage-label
                 failure-stage))
        :kind :not-reached-because-prior-stage-failed
        :stage stage
        :stage-label
        (workspace-annotation-persistence-live-stage-label stage)
        :status :not-reached
        :boundary-or-endpoint
        (workspace-annotation-persistence-stage-boundary-or-endpoint
         report
         stage)
        :reason
        (format nil
                "~A did not run because ~A failed earlier. Downstream stages are not independently broken."
                (workspace-annotation-persistence-live-stage-label stage)
                (workspace-annotation-persistence-live-stage-label
                 failure-stage))
        :blocking-stage
        (workspace-annotation-persistence-live-stage-label failure-stage)
        :next-step-targets next-step-targets
        :success-readback success-readback))
      ((and (member stage '(:workspace-assignment :topicmap-placement
                            :journal-transition)
                    :test #'eq)
            (not (typep (workspace-annotation-persistence-report-client-of
                         report)
                        'http-dmx-import-client)))
       (make-instance
        'workspace-annotation-persistence-stage-absence
        :id (format nil
                    "workspace-annotation-stage-absence/~(~A~)/live-auth-required"
                    stage)
        :title (format nil
                       "~A absence"
                       (workspace-annotation-persistence-live-stage-label
                        stage))
        :summary
        "This stage requires a live HTTP client with usable auth."
        :kind :unavailable-without-live-auth
        :stage stage
        :stage-label
        (workspace-annotation-persistence-live-stage-label stage)
        :status :pending
        :boundary-or-endpoint
        (workspace-annotation-persistence-stage-boundary-or-endpoint
         report
         stage)
        :reason
        "The current report does not carry a live HTTP client that can execute this stage."
        :next-step-targets next-step-targets
        :success-readback success-readback))
      (t
       nil))))

(defun workspace-annotation-persistence-stage-result-or-absence-of
    (report stage)
  (let ((entry (workspace-annotation-persistence-stage-result report stage)))
    (cond
      ((and entry
            (eq (getf entry :status) :completed)
            (eq stage :topic-upsert))
       (workspace-annotation-persistence-report-saved-topic-proxy-of report))
      ((and entry
            (eq (getf entry :status) :completed)
            (eq stage :workspace-assignment))
       (workspace-annotation-persistence-report-workspace-proxy-of report))
      ((and entry
            (eq (getf entry :status) :completed)
            (eq stage :topicmap-placement))
       (workspace-annotation-persistence-report-topicmap-proxy-of report))
      ((and entry
            (eq (getf entry :status) :completed)
            (eq stage :journal-transition))
       (or (workspace-annotation-persistence-report-journal-topic-proxy-of
            report)
           (workspace-annotation-persistence-report-success-readback-of
            report)))
      ((and entry
            (eq (getf entry :status) :completed)
            (eq stage :reopen-persisted-annotation))
       (workspace-annotation-persistence-report-persisted-annotation-of report))
      (t
       (workspace-annotation-persistence-stage-absence-of report stage)))))

(defun workspace-annotation-persistence-stage-operation-of (report stage)
  (let* ((entry (workspace-annotation-persistence-stage-result report stage))
         (resolution
           (workspace-annotation-persistence-report-resolution-of report)))
    (make-instance
     'workspace-annotation-persistence-stage-operation
     :id (format nil
                 "workspace-annotation-stage-operation/~(~A~)"
                 stage)
     :title (format nil
                    "~A operation"
                    (workspace-annotation-persistence-live-stage-label stage))
     :summary
     (or (and entry (getf entry :summary))
         (format nil
                 "~A stage for the live workspace persistence path."
                 (workspace-annotation-persistence-live-stage-label stage)))
     :report report
     :stage stage
     :stage-label
     (workspace-annotation-persistence-live-stage-label stage)
     :status (workspace-annotation-persistence-matrix-stage-status report stage)
     :boundary-or-endpoint
     (workspace-annotation-persistence-stage-boundary-or-endpoint report stage)
     :entry entry
     :evidence
     (workspace-annotation-persistence-stage-evidence report stage)
     :result-object
     (workspace-annotation-persistence-stage-result-or-absence-of report stage)
     :next-step-targets
     (workspace-annotation-persistence-report-recommended-next-step-targets
      report
      stage)
     :resolution
     (and (eq stage (workspace-annotation-persistence-report-failure-stage-of
                     report))
          resolution))))

(defun workspace-annotation-persistence-stage-matrix-rows (report)
  (loop for stage in *dmx-workspace-annotation-live-report-stage-order*
        collect
        (list :stage stage
              :stage-label
              (workspace-annotation-persistence-live-stage-label stage)
              :status
              (workspace-annotation-persistence-matrix-stage-status report stage)
              :boundary-or-endpoint
              (workspace-annotation-persistence-stage-boundary-or-endpoint
               report
               stage)
              :operation
              (workspace-annotation-persistence-stage-operation-of report stage)
              :result-or-absence
              (workspace-annotation-persistence-stage-result-or-absence-of
               report
               stage)
              :next-step-targets
              (workspace-annotation-persistence-report-recommended-next-step-targets
               report
               stage))))

(defun workspace-annotation-stage-results-with-entry (stage-results entry)
  (let ((replaced-p nil)
        (stage (getf entry :stage))
        (results '()))
    (dolist (existing stage-results)
      (if (eq (getf existing :stage) stage)
          (progn
            (push entry results)
            (setf replaced-p t))
          (push existing results)))
    (unless replaced-p
      (push entry results))
    (nreverse results)))

(defun workspace-annotation-persistence-report-initargs (report)
  (list :annotation
        (workspace-annotation-persistence-report-annotation-of report)
        :workspace-topicmap-id
        (workspace-annotation-persistence-report-workspace-topicmap-id-of report)
        :workspace-id
        (workspace-annotation-persistence-report-workspace-id-of report)
        :client
        (workspace-annotation-persistence-report-client-of report)
        :exact-form
        (workspace-annotation-persistence-report-exact-form-of report)
        :stepper-source
        (workspace-annotation-persistence-report-stepper-source-of report)
        :dry-run-preview
        (workspace-annotation-persistence-report-dry-run-preview-of report)
        :annotation-key
        (workspace-annotation-persistence-report-annotation-key-of report)
        :runtime-relation-id
        (workspace-annotation-persistence-report-runtime-relation-id-of report)
        :plan
        (workspace-annotation-persistence-report-plan-of report)
        :stage-results
        (workspace-annotation-persistence-report-stage-results-of report)
        :report-status
        (workspace-annotation-persistence-report-status-of report)
        :failure-stage
        (workspace-annotation-persistence-report-failure-stage-of report)
        :condition
        (workspace-annotation-persistence-report-condition-of report)
        :transport-diagnostics
        (workspace-annotation-persistence-report-transport-diagnostics-of
         report)
        :topic-upsert-evidence
        (workspace-annotation-persistence-report-topic-upsert-evidence-of
         report)
        :raw-result
        (workspace-annotation-persistence-report-raw-result-of report)
        :persisted-topic-id
        (workspace-annotation-persistence-report-persisted-topic-id-of report)
        :persisted-annotation
        (workspace-annotation-persistence-report-persisted-annotation-of
         report)
        :subject-key
        (workspace-annotation-persistence-report-subject-key-of report)
        :previous-state
        (workspace-annotation-persistence-report-previous-state-of report)
        :journal-preflight-summary
        (workspace-annotation-persistence-report-journal-preflight-summary-of
         report)
        :journal-preflight-repair-summary
        (workspace-annotation-persistence-report-journal-preflight-repair-summary-of
         report)
        :journal-preflight-auth-context
        (workspace-annotation-persistence-report-journal-preflight-auth-context-of
         report)
        :explicit-auth-attempt-context
        (workspace-annotation-persistence-report-explicit-auth-attempt-context-of
         report)
        :explicit-auth-retry-invoked-p
        (workspace-annotation-persistence-report-explicit-auth-retry-invoked-p
         report)
        :explicit-auth-retry-request-id
        (workspace-annotation-persistence-report-explicit-auth-retry-request-id-of
         report)
        :explicit-auth-retry-executed-at
        (workspace-annotation-persistence-report-explicit-auth-retry-executed-at-of
         report)
        :explicit-auth-retry-executed-at-label
        (workspace-annotation-persistence-report-explicit-auth-retry-executed-at-label-of
         report)
        :explicit-auth-retry-mode
        (workspace-annotation-persistence-report-explicit-auth-retry-mode-of
         report)
        :explicit-auth-retry-mode-label
        (workspace-annotation-persistence-report-explicit-auth-retry-mode-label-of
         report)
        :explicit-auth-retry-source
        (workspace-annotation-persistence-report-explicit-auth-retry-source-of
         report)
        :explicit-auth-retry-source-label
        (workspace-annotation-persistence-report-explicit-auth-retry-source-label-of
         report)
        :explicit-auth-retry-evidence-version
        (workspace-annotation-persistence-report-explicit-auth-retry-evidence-version-of
         report)
        :assignment-auth-context
        (workspace-annotation-persistence-report-assignment-auth-context-of
         report)))

(defun make-workspace-annotation-persistence-report-like
    (report &rest overrides)
  (let ((initargs (copy-list
                   (workspace-annotation-persistence-report-initargs report))))
    (loop for (key value) on overrides by #'cddr
          do (setf (getf initargs key) value))
    (apply #'make-instance 'workspace-annotation-persistence-report initargs)))

(defun workspace-annotation-persistence-stepper-display-form
    (workspace-topicmap-id &key workspace-id storage-mode)
  (with-standard-io-syntax
    (let ((*package* (find-package :hyperdoc)))
      (prin1-to-string
       `(persist-dock-annotation-to-workspace
         (workspace-annotation-replay-subject *)
         :workspace-topicmap-id ,workspace-topicmap-id
         ,@(when workspace-id
             `(:workspace-id ,workspace-id))
         ,@(when storage-mode
             `(:storage-mode ,storage-mode))
         :dry-run nil)))))

(defun workspace-annotation-persistence-stepper-source
    (workspace-topicmap-id &key workspace-id storage-mode)
  (let ((subject-form "(hyperdoc::workspace-annotation-replay-subject *)"))
    (if storage-mode
        (format nil
                "(hyperdoc::plan-dmx-workspace-annotation-write-from-object ~A :workspace-topicmap-id ~D~@[ :workspace-id ~D~] :storage-mode ~S)~%~%(hyperdoc::persist-dock-annotation-to-workspace ~A :workspace-topicmap-id ~D~@[ :workspace-id ~D~] :storage-mode ~S :dry-run nil)"
                subject-form
                workspace-topicmap-id
                workspace-id
                storage-mode
                subject-form
                workspace-topicmap-id
                workspace-id
                storage-mode)
        (format nil
                "(hyperdoc::plan-dmx-workspace-annotation-write-from-object ~A :workspace-topicmap-id ~D~@[ :workspace-id ~D~])~%~%(hyperdoc::persist-dock-annotation-to-workspace ~A :workspace-topicmap-id ~D~@[ :workspace-id ~D~] :dry-run nil)"
                subject-form
                workspace-topicmap-id
                workspace-id
                subject-form
                workspace-topicmap-id
                workspace-id))))

(defun workspace-annotation-persistence-runtime-relation-id (annotation)
  (or (and (workspace-dock-annotation-p annotation)
           (workspace-annotation-runtime-relation-id-of annotation))
      (id-of annotation)))

(defun workspace-annotation-persistence-derived-key
    (annotation workspace-topicmap-id &key annotation-key-override)
  (or (and (workspace-dock-annotation-p annotation)
           (workspace-annotation-key-of annotation))
      annotation-key-override
      (ignore-errors
        (getf (dmx-workspace-annotation-from-object
               annotation
               workspace-topicmap-id
               :annotation-key annotation-key-override)
              :annotation-key))
      (ignore-errors
        (normalize-dmx-workspace-annotation-key
         annotation-key-override
         (title-of annotation)
         (workspace-annotation-persistence-runtime-relation-id annotation)))))

(defun probe-live-workspace-annotation-type-support
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json storage-mode)
  (let* ((annotation (workspace-annotation-replay-subject annotation))
         (resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run nil
            :verbose nil))
         (resolved-destination
           (resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client resolved-client))
         (resolved-topicmap-id
           (dmx-workspace-annotation-destination-workspace-topicmap-id
            resolved-destination))
         (preview nil)
         (plan nil)
         (payload-json nil)
         (exact-form
           (workspace-annotation-backend-compatibility-probe-form
            resolved-topicmap-id
            :workspace-id
            (dmx-workspace-annotation-destination-workspace-id
             resolved-destination))))
    (handler-case
        (setf preview
              (workspace-annotation-persistence-preview
               annotation
               resolved-topicmap-id
               :workspace-id
               (dmx-workspace-annotation-destination-workspace-id
                resolved-destination)
               :client resolved-client
               :view-props view-props
               :status status
               :supersedes-topic-id supersedes-topic-id
               :annotation-key annotation-key
               :provenance-json provenance-json
               :storage-mode storage-mode))
      (error ()
        ;; Keep the preview best-effort so the support report still opens even
        ;; when the dry-run path itself exposes a separate problem.
        nil))
    (let ((current-type-uri nil))
      (handler-case
          (let* ((normalized
                   (dmx-workspace-annotation-from-object
                    annotation
                    resolved-topicmap-id
                    :status status
                    :supersedes-topic-id supersedes-topic-id
                    :annotation-key annotation-key
                    :provenance-json provenance-json))
                 (type-results '()))
            (setf plan
                  (apply #'plan-dmx-workspace-annotation-write
                         (append normalized
                                 (list :workspace-id
                                       (dmx-workspace-annotation-destination-workspace-id
                                        resolved-destination)
                                       :workspace-topicmap-id
                                       resolved-topicmap-id
                                       :client resolved-client
                                       :view-props view-props
                                       :storage-mode storage-mode
                                       :destination resolved-destination))))
            (setf payload-json
                  (workspace-annotation-write-plan-payload-json-string plan))
            (cond
              ((not (typep resolved-client 'http-dmx-import-client))
               (make-instance
                'workspace-annotation-backend-compatibility-report
                :annotation annotation
                :workspace-topicmap-id resolved-topicmap-id
                :client resolved-client
                :exact-form exact-form
                :dry-run-preview preview
                :plan plan
                :payload-json payload-json
                :report-status :not-live
                :endpoint-path (dmx-topic-create-path)
                :next-actions
                '("This probe only applies to the live HTTP DMX client; memory/null clients do not enforce backend type registration.")))
              ((not (eq (dmx-workspace-annotation-write-plan-topic-action plan)
                        :create))
               (make-instance
                'workspace-annotation-backend-compatibility-report
                :annotation annotation
                :workspace-topicmap-id resolved-topicmap-id
                :client resolved-client
                :exact-form exact-form
                :dry-run-preview preview
                :plan plan
                :payload-json payload-json
                :report-status :not-create
                :endpoint-path (dmx-topic-create-path)
                :selected-storage-mode
                (dmx-workspace-annotation-write-plan-storage-mode plan)
                :carrier-type-uri
                (dmx-workspace-annotation-write-plan-carrier-type-uri plan)
                :next-actions
                '("The current annotation already resolves to an existing workspace topic, so create-topic compatibility is not needed for this write.")))
              (t
               (multiple-value-bind (native-results native-missing)
                   (progn
                     (setf current-type-uri *dmx-workspace-annotation-type-uri*)
                     (probe-workspace-annotation-live-type-family
                      resolved-client
                      (cons *dmx-workspace-annotation-type-uri*
                            *dmx-workspace-annotation-required-live-child-type-uris*)
                      :native))
                 (let* ((selected-storage-mode
                          (dmx-workspace-annotation-write-plan-storage-mode
                           plan))
                        (carrier-type-uri
                          (dmx-workspace-annotation-write-plan-carrier-type-uri
                           plan))
                        (carrier-results '())
                        (carrier-missing nil))
                   (when (dmx-workspace-annotation-compatibility-storage-mode-p
                          selected-storage-mode)
                     (multiple-value-setq (carrier-results carrier-missing)
                       (progn
                         (setf current-type-uri
                               *dmx-workspace-annotation-compatibility-carrier-type-uri*)
                         (probe-workspace-annotation-live-type-family
                          resolved-client
                          *dmx-workspace-annotation-compatibility-required-live-type-uris*
                          :carrier))))
                   (let* ((native-supported-p (null native-missing))
                          (carrier-supported-p
                            (if (dmx-workspace-annotation-compatibility-storage-mode-p
                                 selected-storage-mode)
                                (null carrier-missing)
                                nil))
                          (failing-type-uri
                            (cond
                              ((and (dmx-workspace-annotation-compatibility-storage-mode-p
                                     selected-storage-mode)
                                    carrier-missing)
                               (getf carrier-missing :type-uri))
                              ((and (dmx-workspace-annotation-native-storage-mode-p
                                     selected-storage-mode)
                                    native-missing)
                               (getf native-missing :type-uri))
                              (t
                               nil)))
                          (http-evidence
                            (cond
                              ((and (dmx-workspace-annotation-compatibility-storage-mode-p
                                     selected-storage-mode)
                                    carrier-missing)
                               (getf carrier-missing :http-evidence))
                              (native-missing
                               (getf native-missing :http-evidence))
                              (t
                               nil)))
                          (report-status
                            (cond
                              ((dmx-workspace-annotation-compatibility-storage-mode-p
                                selected-storage-mode)
                               (if carrier-supported-p
                                   :compatible-via-carrier
                                   :unsupported))
                              (native-supported-p
                               :supported)
                              (t
                               :unsupported))))
                     (make-instance
                      'workspace-annotation-backend-compatibility-report
                      :annotation annotation
                      :workspace-topicmap-id resolved-topicmap-id
                      :client resolved-client
                      :exact-form exact-form
                      :dry-run-preview preview
                      :plan plan
                      :payload-json payload-json
                      :report-status report-status
                      :endpoint-path (dmx-topic-create-path)
                      :selected-storage-mode selected-storage-mode
                      :carrier-type-uri carrier-type-uri
                      :native-supported-p native-supported-p
                      :carrier-supported-p carrier-supported-p
                      :failing-type-uri failing-type-uri
                      :native-failing-type-uri
                      (and native-missing (getf native-missing :type-uri))
                      :type-results (append native-results carrier-results)
                      :http-evidence http-evidence
                      :known-create-topic-response-body
                      (workspace-annotation-known-live-create-topic-response-body
                       (and native-missing (getf native-missing :type-uri)))
                      :next-actions
                      (workspace-annotation-backend-compatibility-next-actions
                       report-status
                       selected-storage-mode
                       failing-type-uri
                       :native-failing-type-uri
                       (and native-missing (getf native-missing :type-uri))
                       :carrier-type-uri carrier-type-uri))))))))
        (error (condition)
          (make-instance
           'workspace-annotation-backend-compatibility-report
           :annotation annotation
           :workspace-topicmap-id resolved-topicmap-id
           :client resolved-client
           :exact-form exact-form
           :dry-run-preview preview
           :plan plan
           :payload-json payload-json
           :report-status :error
           :condition condition
           :endpoint-path (dmx-topic-create-path)
            :failing-type-uri current-type-uri
           :selected-storage-mode
           (and plan
                (dmx-workspace-annotation-write-plan-storage-mode plan))
           :carrier-type-uri
           (and plan
                (dmx-workspace-annotation-write-plan-carrier-type-uri plan))
           :http-evidence
           (or (dmx-import-http-evidence condition)
               (and (typep resolved-client 'http-dmx-import-client)
                    (dmx-import-last-http-transaction-evidence-of
                     resolved-client)))
           :next-actions
           (workspace-annotation-backend-compatibility-next-actions
            :error
            (and plan
                 (dmx-workspace-annotation-write-plan-storage-mode plan))
            current-type-uri
            :native-failing-type-uri current-type-uri
            :carrier-type-uri
            (and plan
                 (dmx-workspace-annotation-write-plan-carrier-type-uri
                  plan)))))))))

(defun workspace-annotation-persistence-preview
    (annotation workspace-topicmap-id
     &key workspace-id client view-props status supersedes-topic-id
       annotation-key provenance-json storage-mode)
  (execute-dmx-workspace-annotation-write-from-object
   annotation
   :workspace-topicmap-id workspace-topicmap-id
   :workspace-id workspace-id
   :client client
   :view-props view-props
   :status status
   :supersedes-topic-id supersedes-topic-id
   :annotation-key annotation-key
   :provenance-json provenance-json
   :storage-mode storage-mode
   :dry-run t))

(defun debug-dock-annotation-workspace-persistence
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json storage-mode)
  (let* ((resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run nil
            :verbose nil))
         (resolved-destination
           (resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client resolved-client))
         (resolved-topicmap-id
           (dmx-workspace-annotation-destination-workspace-topicmap-id
            resolved-destination))
         (preview nil)
         (preview-error nil))
    (handler-case
        (setf preview
              (workspace-annotation-persistence-preview
               annotation
               resolved-topicmap-id
               :workspace-id
               (dmx-workspace-annotation-destination-workspace-id
                resolved-destination)
               :client resolved-client
               :view-props view-props
               :status status
               :supersedes-topic-id supersedes-topic-id
               :annotation-key annotation-key
               :provenance-json provenance-json
               :storage-mode storage-mode))
      (error (condition)
        (setf preview-error condition)))
    (make-instance
     'workspace-annotation-persistence-debug
     :annotation annotation
     :workspace-topicmap-id resolved-topicmap-id
     :workspace-id
     (dmx-workspace-annotation-destination-workspace-id resolved-destination)
     :destination resolved-destination
     :client resolved-client
     :view-props view-props
     :requested-status status
     :supersedes-topic-id supersedes-topic-id
     :annotation-key-override annotation-key
     :provenance-json provenance-json
     :exact-form
     (workspace-annotation-persistence-stepper-display-form
      resolved-topicmap-id
      :workspace-id
      (dmx-workspace-annotation-destination-workspace-id resolved-destination)
      :storage-mode storage-mode)
     :stepper-source
     (workspace-annotation-persistence-stepper-source
      resolved-topicmap-id
      :workspace-id
      (dmx-workspace-annotation-destination-workspace-id resolved-destination)
      :storage-mode storage-mode)
     :dry-run-preview preview
     :preview-error preview-error
     :annotation-key
     (or (getf preview :annotation-key)
         (workspace-annotation-persistence-derived-key
          annotation
          resolved-topicmap-id
          :annotation-key-override annotation-key))
     :runtime-relation-id
     (workspace-annotation-persistence-runtime-relation-id annotation))))

(defun workspace-annotation-persistence-stage-status (report stage)
  (or (and report
           (getf (workspace-annotation-persistence-stage-result report stage)
                 :status))
      :pending))

(defun workspace-annotation-persistence-stage-summary (report stage fallback)
  (or (and report
           (getf (workspace-annotation-persistence-stage-result report stage)
                 :summary))
      fallback))

(defun workspace-annotation-persistence-code-path-graph
    (annotation workspace-topicmap-id &key annotation-key runtime-relation-id
       report)
  (let ((persisted (and report
                        (workspace-annotation-persistence-report-persisted-annotation-of
                         report))))
    (make-code-path-graph
     :id "workspace-annotation-persistence-path"
     :title "Workspace annotation persistence path"
     :summary
     (format nil
             "Structured path for persisting a Dock annotation into DMX workspace topicmap ~D. It makes the exact write stages explicit so topic upsert, workspace assignment, topicmap placement, journal recording, and reopen failures stop looking like one opaque button."
             workspace-topicmap-id)
     :entrypoints
     (list
      (list :id "debug-action"
            :label "Debug workspace persistence"
            :summary
            "Inspectable entrypoint that exposes the exact persist form, the dry-run preview, and the staged live report.")
      (list :id "persist-action"
            :label "Persist to workspace"
            :summary
            "The normal live annotation action. It preflights raw hyperdoc.annotation support and, on live HTTP backends, can switch to the compatibility carrier before create-topic."))    
     :nodes
     (list
      (list :id "annotation"
            :label "Dock annotation"
            :role :runtime-input
            :object annotation
            :summary
            "Current pane-local annotation object bound to * for the stepper surface.")
      (list :id "normalize"
            :label "dmx-workspace-annotation-from-object"
            :role :read-helper
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "dmx-workspace-annotation-from-object"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :normalize-annotation
             "Normalize the draft annotation into the typed workspace payload fields."))
      (list :id "plan"
            :label "plan-dmx-workspace-annotation-write-from-object"
            :role :read-helper
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "plan-dmx-workspace-annotation-write-from-object"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :build-write-plan
             "Build the typed DMX annotation write plan from the current annotation object."))
      (list :id "validate"
            :label "Validate payload and view props"
            :role :diff-engine
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "plan-dmx-workspace-annotation-write"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :validate-payload
             "Confirm canonical payload fields and normalized topicmap view props before any live write."))
      (list :id "backend-compatibility-preflight"
            :label "Probe live annotation type support"
            :role :write-preflight
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "probe-live-workspace-annotation-type-support"
            :summary
            "Normal live persist preflights raw hyperdoc.annotation support and the deliberate compatibility carrier before issuing POST /core/topic.")
      (list :id "prepare-transition"
            :label "dmx-workspace-journal-prepare-transition"
            :role :write-preflight
            :source-file "hyperdoc/dmx-workspace-journal.lisp"
            :source-function "dmx-workspace-journal-prepare-transition"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :prepare-transition
             "Capture the previous workspace-journal state before the live write."))
      (list :id "topic-upsert"
            :label "Topic upsert"
            :role :write-entry
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "execute-dmx-workspace-annotation-write"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :topic-upsert
             "Create or update the selected workspace-annotation carrier topic."))
      (list :id "workspace-assignment"
            :label "dmx-import-assign-topic-to-workspace"
            :role :write-helper
            :source-file "hyperdoc/dmx-import.lisp"
            :source-function "dmx-import-assign-topic-to-workspace"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :workspace-assignment
             "Assign the annotation topic to workspace 919815 when needed."))
      (list :id "topicmap-placement"
            :label "dmx-import-add-topic-to-topicmap"
            :role :write-helper
            :source-file "hyperdoc/dmx-import.lisp"
            :source-function "dmx-import-add-topic-to-topicmap"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :topicmap-placement
             "Place the annotation topic into workspace topicmap 919822 with guarded view props."))
      (list :id "journal-transition"
            :label "dmx-workspace-journal-record-transition"
            :role :write-entry
            :source-file "hyperdoc/dmx-workspace-journal.lisp"
            :source-function "dmx-workspace-journal-record-transition"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :journal-transition
             "Append the durable workspace-journal events for the live annotation write."))
      (list :id "reopen"
            :label "read-dmx-workspace-annotation"
            :role :read-entry
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "read-dmx-workspace-annotation"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :reopen-persisted-annotation
             "Reopen the persisted annotation as a stable workspace-dock-annotation object."))
      (list :id "result"
            :label
            (if persisted
                (format nil "Workspace annotation ~D"
                        (workspace-annotation-topic-id-of persisted))
                "Persisted workspace annotation")
            :role :runtime-value
            :object persisted
            :summary
            (if persisted
                (format nil
                        "Persisted annotation reopened through workspace topic id ~D."
                        (workspace-annotation-topic-id-of persisted))
                (format nil
                        "Expected result object for annotation key ~A and runtime relation id ~A."
                        (or annotation-key "-")
                        (or runtime-relation-id "-")))))
     :edges
     (list
      (list :from "annotation"
            :to "normalize"
            :kind :read
            :status (workspace-annotation-persistence-stage-status
                     report
                     :normalize-annotation)
            :summary "Normalize the current annotation object into typed workspace fields.")
      (list :from "normalize"
            :to "plan"
            :kind :read
            :status (workspace-annotation-persistence-stage-status
                     report
                     :build-write-plan)
            :summary "Build the typed write plan for the annotation payload.")
      (list :from "plan"
            :to "validate"
            :kind :read-diff
            :status (workspace-annotation-persistence-stage-status
                     report
                     :validate-payload)
            :summary "Validate payload fields and normalize topicmap view props before writing.")
      (list :from "validate"
            :to "backend-compatibility-preflight"
            :kind :write-preflight
            :status :active
            :summary "Normal persist blocks here only if neither native annotation typing nor the deliberate compatibility carrier is available.")
      (list :from "backend-compatibility-preflight"
            :to "prepare-transition"
            :kind :write-preflight
            :status (workspace-annotation-persistence-stage-status
                     report
                     :prepare-transition)
            :summary "Capture the previous journal state before the write begins.")
      (list :from "prepare-transition"
            :to "topic-upsert"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :topic-upsert)
            :write-capable-p t
            :summary "Create or update the chosen carrier topic while preserving workspace-annotation semantics on reopen.")
      (list :from "topic-upsert"
            :to "workspace-assignment"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :workspace-assignment)
            :write-capable-p t
            :summary "Assign the topic to workspace 919815 when the plan requires it.")
      (list :from "workspace-assignment"
            :to "topicmap-placement"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :topicmap-placement)
            :write-capable-p t
            :summary "Add the topic to workspace topicmap 919822 when the plan requires it.")
      (list :from "topicmap-placement"
            :to "journal-transition"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :journal-transition)
            :write-capable-p t
            :summary "Record the journal transition after the live mutation succeeds.")
      (list :from "journal-transition"
            :to "reopen"
            :kind :read
            :status (workspace-annotation-persistence-stage-status
                     report
                     :reopen-persisted-annotation)
            :summary "Reopen the persisted annotation by workspace topic id.")
      (list :from "reopen"
            :to "result"
            :kind :result
            :status (workspace-annotation-persistence-stage-status
                     report
                     :reopen-persisted-annotation)
            :summary "Yield the stable workspace annotation inspectable object."))
     :focus-paths
     (list
      (list :id "main-persist-path"
            :label "Main persist path"
            :summary
            "The typed persistence path from the current Dock annotation to the reopened workspace annotation."
            :node-ids
            '("annotation"
              "normalize"
              "plan"
              "validate"
              "backend-compatibility-preflight"
              "prepare-transition"
              "topic-upsert"
              "workspace-assignment"
              "topicmap-placement"
              "journal-transition"
              "reopen"
              "result"))))))

(defun trace-dock-annotation-workspace-persistence-path
    (annotation &key workspace-topicmap-id workspace-id client annotation-key
       runtime-relation-id)
  (let* ((resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run nil
            :verbose nil))
         (destination
           (resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client resolved-client))
         (resolved-topicmap-id
           (dmx-workspace-annotation-destination-workspace-topicmap-id
            destination)))
    (workspace-annotation-persistence-code-path-graph
     annotation
     resolved-topicmap-id
     :annotation-key
     (or annotation-key
         (workspace-annotation-persistence-derived-key annotation
                                                      resolved-topicmap-id))
     :runtime-relation-id
     (or runtime-relation-id
         (workspace-annotation-persistence-runtime-relation-id annotation)))))

(defun dmx-workspace-annotation-plist-p (value)
  (and (listp value)
       (evenp (length value))
       (loop for (key nil) on value by #'cddr
             always (or (keywordp key)
                        (symbolp key)
                        (stringp key)))))

(defun dmx-workspace-annotation-camel-case-key (key)
  (let* ((name (string-downcase
                (string
                 (cond
                   ((keywordp key)
                    (symbol-name key))
                   ((symbolp key)
                    (symbol-name key))
                   (t
                    key)))))
         (segments (remove-if #'(lambda (segment) (zerop (length segment)))
                              (cl-ppcre:split "[-_]" name))))
    (with-output-to-string (stream)
      (when segments
        (write-string (first segments) stream)
        (dolist (segment (rest segments))
          (when (plusp (length segment))
            (write-string (string-capitalize segment) stream)))))))

(defun dmx-workspace-annotation-json-friendly-value (value)
  (cond
    ((stringp value)
     value)
    ((pathnamep value)
     (namestring value))
    ((hash-table-p value)
     (let ((json (make-hash-table :test #'equal)))
       (maphash
        (lambda (key child-value)
          (setf (gethash (if (stringp key)
                             key
                             (dmx-workspace-annotation-camel-case-key key))
                         json)
                (dmx-workspace-annotation-json-friendly-value child-value)))
        value)
       json))
    ((vectorp value)
     (map 'vector #'dmx-workspace-annotation-json-friendly-value value))
    ((dmx-workspace-annotation-plist-p value)
     (let ((json (make-hash-table :test #'equal)))
       (loop for (key child-value) on value by #'cddr
             do (setf (gethash (dmx-workspace-annotation-camel-case-key key) json)
                      (dmx-workspace-annotation-json-friendly-value child-value)))
       json))
    ((listp value)
     (coerce (mapcar #'dmx-workspace-annotation-json-friendly-value value)
             'vector))
    (t
     value)))

(defun dmx-workspace-annotation-json-object (&rest key-values)
  (let ((json (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (when value
               (setf (gethash key json)
                     (dmx-workspace-annotation-json-friendly-value value))))
    json))

(defun dmx-workspace-annotation-json-string (&rest key-values)
  (encode-json-string
   (apply #'dmx-workspace-annotation-json-object key-values)))

(defun dmx-workspace-annotation-topic-id (value field boundary &key required?)
  (cond
    ((null value)
     (when required?
       (error 'fedwiki-dmx-import-error
              :message (format nil "~A requires ~A" boundary field)))
     nil)
    (t
     (or (parse-positive-integer value)
         (error 'fedwiki-dmx-import-error
                :message (format nil "~A requires a positive ~A, got ~S"
                                 boundary
                                 field
                                 value))))))

(defun dmx-workspace-annotation-ref-string (value)
  (cond
    ((null value)
     nil)
    ((or (stringp value)
         (pathnamep value)
         (keywordp value)
         (numberp value))
     (format nil "~A" value))
    (t
     (or (ignore-errors (format nil "~A" (id-of value)))
         (ignore-errors (format nil "~A" (title-of value)))
         (format nil "~A" value)))))

(defun dmx-workspace-annotation-anchor-json (anchor)
  (when anchor
    (dmx-workspace-annotation-json-string
     "providerKind" (provider-kind-of anchor)
     "viewKind" (view-kind-of anchor)
     "viewTitle" (view-title-of anchor)
     "paneId" (pane-id-of anchor)
     "contextObjectId" (context-object-id-of anchor)
     "pageTitle" (page-title-of anchor)
     "siteDomain" (site-domain-of anchor)
     "pageSlug" (page-slug-of anchor)
     "storyItemId" (story-item-id-of anchor)
     "storyItemType" (story-item-type-of anchor)
     "strategy" (anchor-strategy-of anchor)
     "value" (anchor-value-of anchor)
     "selector" (selector-of anchor)
     "label" (label-of anchor)
     "tagName" (tag-name-of anchor)
     "textSnippet" (text-snippet-of anchor)
     "path" (and (path-of anchor)
                 (namestring (pathname (path-of anchor))))
     "startLine" (start-line-of anchor)
     "endLine" (end-line-of anchor)
     "startColumn" (start-column-of anchor)
     "endColumn" (end-column-of anchor)
     "sectionPath" (section-path-of anchor)
     "durabilityTier" (durability-tier-of anchor)
     "durabilityNote" (durability-note-of anchor)
     "fallbackStrategy" (fallback-strategy-of anchor)
     "fallbackValue" (fallback-value-of anchor)
     "objectId" (anchor-object-id-of anchor))))

(defun dmx-workspace-annotation-uri (annotation-key)
  (format nil "~A~A"
          *hyperdoc-workspace-annotation-uri-prefix*
          annotation-key))

(defun dmx-workspace-annotation-slug (value)
  (string-trim
   "-"
   (with-output-to-string (stream)
     (loop with previous-hyphen? = nil
           for char across (string-downcase (or value "annotation"))
           do (cond
                ((or (alphanumericp char)
                     (char= char #\_))
                 (write-char char stream)
                 (setf previous-hyphen? nil))
                ((member char '(#\Space #\/ #\- #\: #\. #\# #\@) :test #'char=)
                 (unless previous-hyphen?
                   (write-char #\- stream))
                 (setf previous-hyphen? t)))))))

(defun normalize-dmx-workspace-annotation-key
    (annotation-key title runtime-relation-id &key fresh-key-p)
  (let ((base
          (cond
            ((dmx-non-empty-string-p annotation-key)
             (dmx-workspace-annotation-slug annotation-key))
            ((dmx-non-empty-string-p runtime-relation-id)
             (dmx-workspace-annotation-slug runtime-relation-id))
            (t
             (dmx-workspace-annotation-slug title)))))
    (if fresh-key-p
        (format nil "~A-~D" (or base "annotation") (get-universal-time))
        (or base
            "annotation"))))

(defun dmx-workspace-annotation-topic-title (topic)
  (or (dmx-json-child-value topic *dmx-workspace-annotation-title-type-uri*)
      (dmx-json-object-value topic "value")
      "Workspace annotation"))

(defun dmx-workspace-annotation-annotation-player-ref (uri)
  (dmx-workspace-annotation-json-object
   "role" "annotation"
   "refKind" "topic-uri"
   "refValue" uri))

(defun dmx-workspace-annotation-player-ref (role ref-kind ref-value &key label)
  (dmx-workspace-annotation-json-object
   "role" role
   "refKind" ref-kind
   "refValue" ref-value
   "label" label))

(defun dmx-workspace-annotation-binding-json-string
    (binding-type annotation-uri other-player &rest extra-pairs)
  (apply #'dmx-workspace-annotation-json-string
         "bindingType" binding-type
         "player1" (dmx-workspace-annotation-annotation-player-ref annotation-uri)
         "player2" other-player
         extra-pairs))

(defun dmx-workspace-annotation-provenance-json
    (annotation workspace-topicmap-id)
  (dmx-workspace-annotation-json-string
   "savedFrom" "dock-annotation"
   "dockCapability" (dock-capability-of annotation)
   "runtimeRelationId" (id-of annotation)
   "registryKey" (registry-key-of annotation)
   "workspaceTopicmapId" workspace-topicmap-id
   "annotationClass" (format nil "~(~A~)" (class-name (class-of annotation)))))

(defun dmx-workspace-annotation-native-children
    (&key title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id uri supersedes-topic-id)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash *dmx-workspace-annotation-title-type-uri* children) title
          (gethash *dmx-workspace-annotation-summary-type-uri* children) summary
          (gethash *dmx-workspace-annotation-text-type-uri* children) text
          (gethash *dmx-workspace-annotation-relation-kind-type-uri* children)
          relation-kind
          (gethash *dmx-workspace-annotation-status-type-uri* children) status
          (gethash *dmx-workspace-annotation-source-anchor-json-type-uri* children)
          source-anchor-json
          (gethash *dmx-workspace-annotation-target-anchor-json-type-uri* children)
          target-anchor-json
          (gethash *dmx-workspace-annotation-context-object-id-type-uri* children)
          context-object-id
          (gethash *dmx-workspace-annotation-context-view-title-type-uri* children)
          context-view-title
          (gethash *dmx-workspace-annotation-source-object-ref-type-uri* children)
          source-object-ref
          (gethash *dmx-workspace-annotation-target-object-ref-type-uri* children)
          target-object-ref
          (gethash *dmx-workspace-annotation-runtime-relation-id-type-uri* children)
          runtime-relation-id
          (gethash *dmx-workspace-annotation-provenance-type-uri* children)
          provenance-json
          (gethash *dmx-workspace-annotation-workspace-topicmap-type-uri* children)
          (write-to-string workspace-topicmap-id)
          (gethash *dmx-workspace-annotation-source-binding-type-uri* children)
          (dmx-workspace-annotation-binding-json-string
           "annotation-source-binding"
           uri
           (dmx-workspace-annotation-player-ref
            "source-object"
            "object-ref"
            source-object-ref
            :label title))
          (gethash *dmx-workspace-annotation-target-binding-type-uri* children)
          (dmx-workspace-annotation-binding-json-string
           "annotation-target-binding"
           uri
           (dmx-workspace-annotation-player-ref
            "target-object"
            "object-ref"
            target-object-ref
            :label "Annotation"))
          (gethash *dmx-workspace-annotation-context-binding-type-uri* children)
          (dmx-workspace-annotation-binding-json-string
           "annotation-context-binding"
           uri
           (dmx-workspace-annotation-player-ref
            "context-object"
            "context-object-id"
            context-object-id
            :label context-view-title)))
    (when supersedes-topic-id
      (setf (gethash *dmx-workspace-annotation-supersedes-type-uri* children)
            (dmx-workspace-annotation-binding-json-string
             "annotation-supersedes"
             uri
             (dmx-workspace-annotation-player-ref
              "superseded-topic"
              "topic-id"
              supersedes-topic-id))))
    children))

(defun dmx-workspace-annotation-native-payload
    (&key uri title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id supersedes-topic-id)
  (list :uri uri
        :external-key uri
        :type-uri *dmx-workspace-annotation-type-uri*
        :value title
        :children (dmx-workspace-annotation-native-children
                   :uri uri
                   :title title
                   :summary summary
                   :text text
                   :relation-kind relation-kind
                   :status status
                   :source-anchor-json source-anchor-json
                   :target-anchor-json target-anchor-json
                   :context-object-id context-object-id
                   :context-view-title context-view-title
                   :source-object-ref source-object-ref
                   :target-object-ref target-object-ref
                   :runtime-relation-id runtime-relation-id
                   :provenance-json provenance-json
                   :workspace-topicmap-id workspace-topicmap-id
                   :supersedes-topic-id supersedes-topic-id)))

(defun dmx-workspace-annotation-compatibility-envelope
    (annotation-key workspace-topicmap-id runtime-relation-id native-payload)
  (dmx-workspace-annotation-json-object
   "schemaVersion" *dmx-workspace-annotation-compatibility-envelope-version*
   "storageMode" *dmx-workspace-annotation-compatibility-storage-mode-name*
   "carrierTypeUri" *dmx-workspace-annotation-compatibility-carrier-type-uri*
   "nativeTypeUri" *dmx-workspace-annotation-type-uri*
   "annotationKey" annotation-key
   "workspaceTopicmapId" workspace-topicmap-id
   "runtimeRelationId" runtime-relation-id
   "nativePayload" (dmx-import-json-object native-payload)))

(defun dmx-workspace-annotation-compatibility-note-payload
    (annotation-key workspace-topicmap-id runtime-relation-id native-payload)
  (let* ((uri (getf native-payload :uri))
         (title (getf native-payload :value))
         (text
           (encode-json-string
            (dmx-workspace-annotation-compatibility-envelope
             annotation-key
             workspace-topicmap-id
             runtime-relation-id
             native-payload))))
    (list :uri uri
          :external-key uri
          :type-uri *dmx-workspace-annotation-compatibility-carrier-type-uri*
          :value title
          :children (make-dmx-workspace-note-children
                     :title title
                     :text text))))

(defun resolve-dmx-workspace-annotation-workspace-id (workspace-id client)
  (or (and workspace-id
           (dmx-workspace-annotation-topic-id
            workspace-id
            :workspace-id
            'resolve-dmx-workspace-annotation-workspace-id
            :required? t))
      (and (typep client 'http-dmx-import-client)
           (dmx-import-workspace-id-of client))
      *dmx-context-window-workspace-id*))

(defun dmx-workspace-annotation-from-object
    (annotation workspace-topicmap-id &key status supersedes-topic-id
       annotation-key provenance-json)
  (let* ((resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (persisted-p (workspace-dock-annotation-p annotation))
         (runtime-relation-id
           (or (and persisted-p
                    (workspace-annotation-runtime-relation-id-of annotation))
               (id-of annotation)))
         (resolved-status
           (normalize-dmx-workspace-note-string
            (or status
                (and persisted-p
                     (workspace-annotation-status-of annotation))
                "persisted")
            :status
            'dmx-workspace-annotation-from-object
            :required? t))
         (fresh-key-p
           (and supersedes-topic-id
                (not persisted-p)))
         (resolved-key
           (normalize-dmx-workspace-annotation-key
            (or annotation-key
                (and persisted-p
                     (workspace-annotation-key-of annotation)))
            (title-of annotation)
            runtime-relation-id
            :fresh-key-p fresh-key-p))
         (resolved-uri
           (or (and persisted-p
                    (workspace-annotation-topic-uri-of annotation))
               (dmx-workspace-annotation-uri resolved-key))))
    (list :topic-id (and persisted-p
                         (workspace-annotation-topic-id-of annotation))
          :annotation-key resolved-key
          :uri resolved-uri
          :title (normalize-dmx-workspace-note-string
                  (title-of annotation)
                  :title
                  'dmx-workspace-annotation-from-object
                  :required? t)
          :summary (normalize-dmx-workspace-note-string
                    (summary-of annotation)
                    :summary
                    'dmx-workspace-annotation-from-object
                    :required? t)
          :text (normalize-dmx-workspace-note-string
                 (or (note-of annotation) "")
                 :text
                 'dmx-workspace-annotation-from-object
                 :required? t)
          :relation-kind (normalize-dmx-workspace-note-string
                          (or (relation-kind-of annotation)
                              "annotation")
                          :relation-kind
                          'dmx-workspace-annotation-from-object
                          :required? t)
          :status resolved-status
          :source-anchor-json
          (dmx-workspace-annotation-anchor-json (source-anchor-of annotation))
          :target-anchor-json
          (dmx-workspace-annotation-anchor-json (target-anchor-of annotation))
          :context-object-id
          (normalize-dmx-workspace-note-string
           (or (and persisted-p
                    (dmx-workspace-annotation-ref-string
                     (context-object-of annotation)))
               (dock-object-stable-id (or (context-object-of annotation)
                                          (source-object-of annotation)
                                          annotation)))
           :context-object-id
           'dmx-workspace-annotation-from-object
           :required? t)
          :context-view-title (normalize-dmx-workspace-note-string
                               (or (context-view-title-of annotation)
                                   "Inspector")
                               :context-view-title
                               'dmx-workspace-annotation-from-object
                               :required? t)
          :source-object-ref (normalize-dmx-workspace-note-string
                              (or (and persisted-p
                                       (workspace-annotation-source-object-ref-of
                                        annotation))
                                  (dmx-workspace-annotation-ref-string
                                   (source-object-of annotation))
                                  (anchor-object-id-of (source-anchor-of annotation))
                                  (anchor-value-of (source-anchor-of annotation)))
                              :source-object-ref
                              'dmx-workspace-annotation-from-object
                              :required? t)
          :target-object-ref (normalize-dmx-workspace-note-string
                              (or (and persisted-p
                                       (workspace-annotation-target-object-ref-of
                                        annotation))
                                  (dmx-workspace-annotation-ref-string
                                   (target-object-of annotation))
                                  (anchor-object-id-of (target-anchor-of annotation))
                                  (anchor-value-of (target-anchor-of annotation)))
                              :target-object-ref
                              'dmx-workspace-annotation-from-object
                              :required? t)
          :runtime-relation-id runtime-relation-id
          :provenance-json
          (or provenance-json
              (and persisted-p
                   (workspace-annotation-provenance-json-of annotation))
              (dmx-workspace-annotation-provenance-json
               annotation
               resolved-topicmap-id))
          :workspace-topicmap-id resolved-topicmap-id
          :supersedes-topic-id
          (or supersedes-topic-id
              (and persisted-p
                   (workspace-annotation-supersedes-topic-id-of annotation))))))

(defun resolve-dmx-workspace-annotation
    (&key client workspace-topicmap-id workspace-id annotation-key uri topic-id
       title runtime-relation-id supersedes-topic-id storage-mode destination)
  (let* ((resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run t
            :verbose nil))
         (resolved-destination
           (or destination
               (resolve-dmx-workspace-annotation-destination
                nil
                :workspace-topicmap-id workspace-topicmap-id
                :workspace-id workspace-id
                :client resolved-client)))
         (resolved-topicmap-id
           (dmx-workspace-annotation-destination-workspace-topicmap-id
            resolved-destination))
         (resolved-workspace-id
           (dmx-workspace-annotation-destination-workspace-id
            resolved-destination))
         (resolved-key
           (cond
             (topic-id
              nil)
             (uri
              (subseq uri (length *hyperdoc-workspace-annotation-uri-prefix*)))
             (t
              (normalize-dmx-workspace-annotation-key
               annotation-key
               title
               runtime-relation-id
               :fresh-key-p (and supersedes-topic-id (null topic-id))))))
         (resolved-uri
           (or uri
               (and resolved-key
                    (dmx-workspace-annotation-uri resolved-key))))
         (existing-topic
           (cond
             (topic-id
              (dmx-import-read-topic
               resolved-client
               (dmx-workspace-annotation-topic-id
                topic-id
                :topic-id
                'resolve-dmx-workspace-annotation
                :required? t)))
             (resolved-uri
              (dmx-import-find-existing-topic resolved-client resolved-uri))
             (t
              nil)))
         (existing-topic-id (dmx-import-object-id existing-topic))
         (resolved-storage-mode
           (resolve-dmx-workspace-annotation-storage-mode
            storage-mode
            resolved-client
            existing-topic)))
    (when (and existing-topic
               (null (dmx-workspace-annotation-topic-storage-mode existing-topic)))
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "DMX workspace annotation writes require a native ~A topic or a compatibility ~A carrier, but resolved topic ~D is ~A"
                              *dmx-workspace-annotation-type-uri*
                              *dmx-workspace-annotation-compatibility-carrier-type-uri*
                              existing-topic-id
                              (dmx-json-object-value existing-topic "typeUri"))))
    (let* ((in-topicmap-p
             (and existing-topic-id
                  (dmx-import-topic-in-topicmap-p
                   resolved-client
                   resolved-topicmap-id
                   existing-topic-id)))
           (current-workspace
             (and existing-topic-id
                  (dmx-import-read-topic-workspace
                   resolved-client
                   existing-topic-id)))
           (current-workspace-id
             (dmx-import-object-id current-workspace)))
      (make-dmx-workspace-annotation-resolution
       :annotation-key resolved-key
       :uri resolved-uri
       :destination resolved-destination
       :workspace-topicmap-id resolved-topicmap-id
       :workspace-id resolved-workspace-id
       :storage-mode resolved-storage-mode
       :carrier-type-uri
       (dmx-workspace-annotation-storage-mode-carrier-type-uri
        resolved-storage-mode)
       :existing-topic existing-topic
       :existing-topic-id existing-topic-id
       :current-workspace-id current-workspace-id
       :in-topicmap-p in-topicmap-p
       :topic-action (if existing-topic :update :create)
       :workspace-action (if (eql current-workspace-id resolved-workspace-id)
                             :unchanged
                             :assign)
       :topicmap-action (if in-topicmap-p :already-present :add)))))

(defun dmx-workspace-annotation-plan-summary (plan)
  (list :operation (dmx-workspace-annotation-write-plan-operation plan)
        :annotation-key (dmx-workspace-annotation-write-plan-annotation-key plan)
        :uri (dmx-workspace-annotation-write-plan-uri plan)
        :destination
        (dmx-workspace-annotation-write-plan-destination plan)
        :workspace-topicmap-id
        (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
        :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
        :destination-source
        (and (dmx-workspace-annotation-write-plan-destination plan)
             (dmx-workspace-annotation-destination-source
              (dmx-workspace-annotation-write-plan-destination plan)))
        :destination-source-label
        (and (dmx-workspace-annotation-write-plan-destination plan)
             (dmx-workspace-annotation-destination-source-label
              (dmx-workspace-annotation-destination-source
               (dmx-workspace-annotation-write-plan-destination plan))))
        :workspace-source
        (and (dmx-workspace-annotation-write-plan-destination plan)
             (dmx-workspace-annotation-destination-workspace-source
              (dmx-workspace-annotation-write-plan-destination plan)))
        :workspace-source-label
        (and (dmx-workspace-annotation-write-plan-destination plan)
             (dmx-workspace-annotation-destination-source-label
              (dmx-workspace-annotation-destination-workspace-source
               (dmx-workspace-annotation-write-plan-destination plan))))
        :topicmap-source
        (and (dmx-workspace-annotation-write-plan-destination plan)
             (dmx-workspace-annotation-destination-topicmap-source
              (dmx-workspace-annotation-write-plan-destination plan)))
        :topicmap-source-label
        (and (dmx-workspace-annotation-write-plan-destination plan)
             (dmx-workspace-annotation-destination-source-label
              (dmx-workspace-annotation-destination-topicmap-source
               (dmx-workspace-annotation-write-plan-destination plan))))
        :destination-rationale
        (and (dmx-workspace-annotation-write-plan-destination plan)
             (dmx-workspace-annotation-destination-rationale
              (dmx-workspace-annotation-write-plan-destination plan)))
        :storage-mode
        (dmx-workspace-annotation-write-plan-storage-mode plan)
        :carrier-type-uri
        (dmx-workspace-annotation-write-plan-carrier-type-uri plan)
        :topic-type-uri
        (getf (dmx-workspace-annotation-write-plan-payload plan) :type-uri)
        :title (dmx-workspace-annotation-write-plan-title plan)
        :status (dmx-workspace-annotation-write-plan-status plan)
        :payload-validation-status
        (dmx-workspace-annotation-write-plan-payload-validation-status plan)
        :topic-action (dmx-workspace-annotation-write-plan-topic-action plan)
        :workspace-action
        (dmx-workspace-annotation-write-plan-workspace-action plan)
        :topicmap-action (dmx-workspace-annotation-write-plan-topicmap-action plan)
        :existing-topic-id
        (dmx-workspace-annotation-write-plan-existing-topic-id plan)
        :supersedes-topic-id
        (dmx-workspace-annotation-write-plan-supersedes-topic-id plan)
        :normalized-view-props-json
        (and (dmx-workspace-annotation-write-plan-view-props plan)
             (dmx-topicmap-view-props-json-string
              (dmx-workspace-annotation-write-plan-view-props plan)))))

(defun plan-dmx-workspace-annotation-write
    (&key title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id workspace-id client
       annotation-key uri topic-id supersedes-topic-id view-props storage-mode
       destination)
  (let* ((resolved-title
           (normalize-dmx-workspace-note-string
            title
            :title
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-summary
           (normalize-dmx-workspace-note-string
            summary
            :summary
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-text
           (normalize-dmx-workspace-note-string
            text
            :text
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-relation-kind
           (normalize-dmx-workspace-note-string
            relation-kind
            :relation-kind
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-status
           (normalize-dmx-workspace-note-string
            status
            :status
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-source-anchor-json
           (normalize-dmx-workspace-note-string
            source-anchor-json
            :source-anchor-json
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-target-anchor-json
           (normalize-dmx-workspace-note-string
            target-anchor-json
            :target-anchor-json
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-context-object-id
           (normalize-dmx-workspace-note-string
            context-object-id
            :context-object-id
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-context-view-title
           (normalize-dmx-workspace-note-string
            context-view-title
            :context-view-title
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-source-object-ref
           (normalize-dmx-workspace-note-string
            source-object-ref
            :source-object-ref
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-target-object-ref
           (normalize-dmx-workspace-note-string
            target-object-ref
            :target-object-ref
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-runtime-relation-id
           (normalize-dmx-workspace-note-string
            runtime-relation-id
            :runtime-relation-id
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-provenance-json
           (normalize-dmx-workspace-note-string
            provenance-json
            :provenance-json
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run t
            :verbose nil))
         (resolved-destination
           (or destination
               (resolve-dmx-workspace-annotation-destination
                nil
                :workspace-topicmap-id workspace-topicmap-id
                :workspace-id workspace-id
                :client resolved-client)))
         (resolution
           (resolve-dmx-workspace-annotation
            :client resolved-client
            :workspace-topicmap-id
            (dmx-workspace-annotation-destination-workspace-topicmap-id
             resolved-destination)
            :workspace-id
            (dmx-workspace-annotation-destination-workspace-id
             resolved-destination)
            :annotation-key annotation-key
            :uri uri
            :topic-id topic-id
            :title resolved-title
            :runtime-relation-id resolved-runtime-relation-id
            :supersedes-topic-id supersedes-topic-id
            :storage-mode storage-mode
            :destination resolved-destination))
         (native-payload
           (dmx-workspace-annotation-native-payload
            :uri (dmx-workspace-annotation-resolution-uri resolution)
            :title resolved-title
            :summary resolved-summary
            :text resolved-text
            :relation-kind resolved-relation-kind
            :status resolved-status
            :source-anchor-json resolved-source-anchor-json
            :target-anchor-json resolved-target-anchor-json
            :context-object-id resolved-context-object-id
            :context-view-title resolved-context-view-title
            :source-object-ref resolved-source-object-ref
            :target-object-ref resolved-target-object-ref
            :runtime-relation-id resolved-runtime-relation-id
            :provenance-json resolved-provenance-json
            :workspace-topicmap-id
            (dmx-workspace-annotation-resolution-workspace-topicmap-id resolution)
            :supersedes-topic-id supersedes-topic-id))
         (payload
           (if (dmx-workspace-annotation-compatibility-storage-mode-p
                (dmx-workspace-annotation-resolution-storage-mode resolution))
               (dmx-workspace-annotation-compatibility-note-payload
                (dmx-workspace-annotation-resolution-annotation-key resolution)
                (dmx-workspace-annotation-resolution-workspace-topicmap-id
                 resolution)
                resolved-runtime-relation-id
                native-payload)
               native-payload)))
    (multiple-value-bind (resolved-view-props view-props-normalization)
        (normalize-dmx-workspace-note-view-props
         view-props
         'plan-dmx-workspace-annotation-write)
      (make-dmx-workspace-annotation-write-plan
       :operation :workspace-annotation-write
       :annotation-key (dmx-workspace-annotation-resolution-annotation-key
                        resolution)
       :uri (dmx-workspace-annotation-resolution-uri resolution)
       :destination
       (dmx-workspace-annotation-resolution-destination resolution)
       :workspace-topicmap-id
       (dmx-workspace-annotation-resolution-workspace-topicmap-id resolution)
       :workspace-id (dmx-workspace-annotation-resolution-workspace-id resolution)
       :title resolved-title
       :summary resolved-summary
       :text resolved-text
       :relation-kind resolved-relation-kind
       :status resolved-status
       :source-anchor-json resolved-source-anchor-json
       :target-anchor-json resolved-target-anchor-json
       :context-object-id resolved-context-object-id
       :context-view-title resolved-context-view-title
       :source-object-ref resolved-source-object-ref
       :target-object-ref resolved-target-object-ref
       :runtime-relation-id resolved-runtime-relation-id
       :provenance-json resolved-provenance-json
       :supersedes-topic-id supersedes-topic-id
       :view-props resolved-view-props
       :view-props-normalization view-props-normalization
       :payload-validation-status :canonical
       :storage-mode
       (dmx-workspace-annotation-resolution-storage-mode resolution)
       :carrier-type-uri
       (dmx-workspace-annotation-resolution-carrier-type-uri resolution)
       :topic-action (dmx-workspace-annotation-resolution-topic-action resolution)
       :workspace-action
       (dmx-workspace-annotation-resolution-workspace-action resolution)
       :topicmap-action
       (dmx-workspace-annotation-resolution-topicmap-action resolution)
       :payload payload
       :existing-topic (dmx-workspace-annotation-resolution-existing-topic resolution)
       :existing-topic-id
       (dmx-workspace-annotation-resolution-existing-topic-id resolution)
       :current-workspace-id
       (dmx-workspace-annotation-resolution-current-workspace-id resolution)))))

(defun plan-dmx-workspace-annotation-write-from-object
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json storage-mode)
  (let* ((resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run t
            :verbose nil))
         (destination
           (resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client resolved-client)))
    (apply #'plan-dmx-workspace-annotation-write
           (append (dmx-workspace-annotation-from-object
                    annotation
                    (dmx-workspace-annotation-destination-workspace-topicmap-id
                     destination)
                    :status status
                    :supersedes-topic-id supersedes-topic-id
                    :annotation-key annotation-key
                    :provenance-json provenance-json)
                   (list :workspace-id
                         (dmx-workspace-annotation-destination-workspace-id
                          destination)
                         :workspace-topicmap-id
                         (dmx-workspace-annotation-destination-workspace-topicmap-id
                          destination)
                         :client resolved-client
                         :view-props view-props
                         :storage-mode storage-mode
                         :destination destination)))))

(defun continue-dmx-workspace-annotation-write-after-topic-upsert
    (client plan previous-state topic-id)
  (with-http-dmx-import-request-workspace-id
      ((dmx-workspace-annotation-write-plan-workspace-id plan))
    (when (eql (dmx-workspace-annotation-write-plan-workspace-action plan)
               :assign)
      (dmx-import-assign-topic-to-workspace
       client
       (dmx-workspace-annotation-write-plan-workspace-id plan)
       topic-id))
    (when (eql (dmx-workspace-annotation-write-plan-topicmap-action plan)
               :add)
      (dmx-import-add-topic-to-topicmap
       client
       (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
       topic-id
       (dmx-workspace-annotation-write-plan-view-props plan))))
  (let* ((after-topic (dmx-import-read-topic client topic-id))
         (after-state
           (dmx-workspace-journal-live-snapshot
            client
            after-topic
            (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)))
         (journal-events
           (record-workspace-transition
            *workspace-journal-sink*
            previous-state
            after-state
            (dmx-workspace-annotation-write-plan-workspace-topicmap-id
             plan)
            :client client)))
    (values after-topic after-state journal-events)))

(defun execute-dmx-workspace-annotation-write
    (&key title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id workspace-id client
       annotation-key uri topic-id supersedes-topic-id view-props
       storage-mode destination
       (dry-run t))
  (let* ((resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run dry-run
            :verbose nil))
         (plan
           (plan-dmx-workspace-annotation-write
            :title title
            :summary summary
            :text text
            :relation-kind relation-kind
            :status status
            :source-anchor-json source-anchor-json
            :target-anchor-json target-anchor-json
            :context-object-id context-object-id
            :context-view-title context-view-title
            :source-object-ref source-object-ref
            :target-object-ref target-object-ref
            :runtime-relation-id runtime-relation-id
            :provenance-json provenance-json
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client resolved-client
            :annotation-key annotation-key
            :uri uri
            :topic-id topic-id
            :supersedes-topic-id supersedes-topic-id
            :view-props view-props
            :storage-mode storage-mode
            :destination destination))
         (subject-key (dmx-workspace-annotation-write-plan-uri plan))
         (previous-preview
           (if-let (existing-topic
                    (dmx-workspace-annotation-write-plan-existing-topic plan))
             (dmx-workspace-journal-live-snapshot
              resolved-client
              existing-topic
              (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan))
             (dmx-workspace-journal-absent-snapshot
              subject-key
              "uri"
              subject-key
              (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
              :subject-uri subject-key
              :subject-kind "workspace-annotation"
              :ownership-class "hyperdoc-workspace-annotation")))
         (next-preview
           (dmx-workspace-journal-snapshot-from-payload
            subject-key
            "uri"
            subject-key
            (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
            (dmx-workspace-journal-payload-json-from-payload
             (dmx-workspace-annotation-write-plan-payload plan))
            :subject-uri subject-key
            :subject-kind "workspace-annotation"
            :ownership-class "hyperdoc-workspace-annotation"
            :topic-id
            (dmx-workspace-annotation-write-plan-existing-topic-id plan)
            :in-topicmap t
            :view-props
            (if (eql (dmx-workspace-annotation-write-plan-topicmap-action plan)
                     :add)
                (dmx-workspace-annotation-write-plan-view-props plan)
                (gethash "viewProps" previous-preview))
            :workspace-id
            (dmx-workspace-annotation-write-plan-workspace-id plan)
            :workspace-title
            (gethash "workspaceTitle" previous-preview)))
         (journal-preview
           (dmx-workspace-journal-transition-preview
            previous-preview
            next-preview)))
    (if dry-run
        (append (dmx-workspace-annotation-plan-summary plan)
                (list :dry-run t
                      :journal-event-preview journal-preview))
        (let* ((previous-state
                 (dmx-workspace-journal-prepare-transition
                  resolved-client
                  subject-key
                  "uri"
                  subject-key
                  (dmx-workspace-annotation-write-plan-workspace-topicmap-id
                   plan)
                  :subject-uri subject-key
                  :subject-kind "workspace-annotation"
                  :ownership-class "hyperdoc-workspace-annotation"
                  :workspace-id
                  (dmx-workspace-annotation-write-plan-workspace-id plan)))
               (topic
                 (ecase (dmx-workspace-annotation-write-plan-topic-action plan)
                   (:create
                    (dmx-import-create-topic
                     resolved-client
                     (dmx-workspace-annotation-write-plan-payload plan)))
                   (:update
                    (progn
                      (when (workspace-annotation-topic-upsert-existing-topic-anonymous-p
                             resolved-client
                             plan)
                        (signal-workspace-annotation-topic-upsert-auth-boundary
                         resolved-client
                         plan))
                      (dmx-import-update-topic
                       resolved-client
                       (dmx-workspace-annotation-write-plan-existing-topic plan)
                       (dmx-workspace-annotation-write-plan-payload plan))))))
               (topic-id* (dmx-import-object-id topic)))
          (multiple-value-bind (_after-topic _after-state journal-events)
              (continue-dmx-workspace-annotation-write-after-topic-upsert
               resolved-client
               plan
               previous-state
               topic-id*)
            (declare (ignore _after-topic _after-state))
            (append (dmx-workspace-annotation-plan-summary plan)
                    (list :dry-run nil
                          :topic-id topic-id*
                          :journal-subject-key subject-key
                          :journal-event-count
                          (length journal-events))))))))

(defun execute-dmx-workspace-annotation-write-from-object
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       storage-mode
       (dry-run t))
  (let* ((resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run dry-run
            :verbose nil))
         (destination
           (resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client resolved-client)))
    (apply #'execute-dmx-workspace-annotation-write
           (append (dmx-workspace-annotation-from-object
                    annotation
                    (dmx-workspace-annotation-destination-workspace-topicmap-id
                     destination)
                    :status status
                    :supersedes-topic-id supersedes-topic-id
                    :annotation-key annotation-key
                    :provenance-json provenance-json)
                   (list :workspace-id
                         (dmx-workspace-annotation-destination-workspace-id
                          destination)
                         :workspace-topicmap-id
                         (dmx-workspace-annotation-destination-workspace-topicmap-id
                          destination)
                         :client resolved-client
                         :view-props view-props
                         :storage-mode storage-mode
                         :dry-run dry-run
                         :destination destination)))))

(defun run-dock-annotation-workspace-persistence-debug
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json storage-mode)
  (let* ((debug
           (debug-dock-annotation-workspace-persistence
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client client
            :view-props view-props
            :status status
            :supersedes-topic-id supersedes-topic-id
            :annotation-key annotation-key
            :provenance-json provenance-json
            :storage-mode storage-mode))
         (stage-results '())
         (failure-stage nil)
         (failure-condition nil)
         (persisted-topic-id nil)
         (persisted-annotation nil)
         (raw-result nil)
         (resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run nil
            :verbose nil))
         (resolved-topicmap-id
           (workspace-annotation-persistence-debug-workspace-topicmap-id-of debug))
         (subject-key nil)
         (previous-state nil)
         (journal-preflight-summary nil)
         (journal-preflight-repair-summary nil)
         (plan nil))
    (labels ((record-stage (stage status summary &key detail)
               (push (workspace-annotation-persistence-stage-entry
                      stage
                      status
                      summary
                      :detail detail)
                     stage-results))
             (materialize-stage-detail (detail &optional condition)
               (typecase detail
                 (function
                  (funcall detail condition))
                 (t
                  detail)))
             (run-stage (stage summary thunk &key detail error-summary error-detail)
               (handler-case
                   (let ((value (funcall thunk)))
                     (record-stage stage :completed summary :detail detail)
                     value)
                 (error (condition)
                   (setf failure-stage stage
                         failure-condition condition)
                   (record-stage stage
                                 :error
                                 (or error-summary summary)
                                 :detail (or (materialize-stage-detail
                                              error-detail
                                              condition)
                                             (format nil "~A" condition)))
                   (error condition)))))
      (handler-case
          (let ((normalized nil)
                (topic nil)
                (topic-id* nil)
                (after-topic nil)
                (after-state nil)
                (journal-events nil))
            (setf normalized
                  (run-stage
                   :normalize-annotation
                   "Derived the typed workspace annotation fields from the current Dock annotation."
                   (lambda ()
                     (dmx-workspace-annotation-from-object
                      annotation
                      resolved-topicmap-id
                      :status status
                      :supersedes-topic-id supersedes-topic-id
                      :annotation-key annotation-key
                      :provenance-json provenance-json))))
            (setf plan
                  (run-stage
                   :build-write-plan
                   "Built the typed DMX write plan for the annotation payload."
                   (lambda ()
                     (apply #'plan-dmx-workspace-annotation-write
                            (append normalized
                                    (list :workspace-id workspace-id
                                          :client resolved-client
                                          :view-props view-props
                                          :storage-mode storage-mode))))))
            (record-stage
             :validate-payload
             :completed
             (format nil
                     "Payload validation is ~A; topic action ~A, workspace action ~A, topicmap action ~A."
                     (dmx-workspace-annotation-write-plan-payload-validation-status
                      plan)
                     (dmx-workspace-annotation-write-plan-topic-action plan)
                     (dmx-workspace-annotation-write-plan-workspace-action plan)
                     (dmx-workspace-annotation-write-plan-topicmap-action plan))
             :detail
             (and (dmx-workspace-annotation-write-plan-view-props plan)
                  (dmx-topicmap-view-props-json-string
                   (dmx-workspace-annotation-write-plan-view-props plan))))
            (setf subject-key (dmx-workspace-annotation-write-plan-uri plan))
            (setf journal-preflight-summary
                  (dmx-workspace-journal-preflight-summary
                   resolved-client
                   subject-key
                   "uri"
                   subject-key
                   resolved-topicmap-id
                   :subject-uri subject-key
                   :subject-kind "workspace-annotation"
                   :ownership-class "hyperdoc-workspace-annotation"))
            (setf previous-state
                  (run-stage
                   :prepare-transition
                   "Prepared the workspace-journal preflight state for this annotation subject."
                   (lambda ()
                     (multiple-value-setq
                         (previous-state
                          journal-preflight-repair-summary)
                       (dmx-workspace-journal-prepare-transition
                        resolved-client
                        subject-key
                        "uri"
                        subject-key
                        resolved-topicmap-id
                        :subject-uri subject-key
                        :subject-kind "workspace-annotation"
                        :ownership-class "hyperdoc-workspace-annotation"
                        :workspace-id
                        (and plan
                             (dmx-workspace-annotation-write-plan-workspace-id
                              plan))))
                     previous-state)
                   :error-summary
                   "Workspace journal preflight blocked"
                   :error-detail
                   (lambda (condition)
                     (workspace-annotation-journal-preflight-blocked-detail
                      journal-preflight-summary
                      (dmx-workspace-annotation-workspace-label
                       (dmx-workspace-annotation-write-plan-workspace-id plan))
                      (dmx-workspace-annotation-topicmap-label
                       resolved-topicmap-id)
                      condition))))
            (setf topic
                  (run-stage
                   :topic-upsert
                   (format nil
                           "Executed the live annotation topic ~A step."
                           (dmx-workspace-annotation-write-plan-topic-action
                            plan))
                   (lambda ()
                     (ecase (dmx-workspace-annotation-write-plan-topic-action
                             plan)
                       (:create
                        (dmx-import-create-topic
                         resolved-client
                         (dmx-workspace-annotation-write-plan-payload plan)))
                       (:update
                        (progn
                          (when (workspace-annotation-topic-upsert-existing-topic-anonymous-p
                                 resolved-client
                                 plan)
                            (signal-workspace-annotation-topic-upsert-auth-boundary
                             resolved-client
                             plan))
                          (dmx-import-update-topic
                           resolved-client
                           (dmx-workspace-annotation-write-plan-existing-topic
                            plan)
                           (dmx-workspace-annotation-write-plan-payload
                            plan))))))))
            (setf topic-id* (dmx-import-object-id topic)
                  persisted-topic-id topic-id*
                  raw-result
                  (append (dmx-workspace-annotation-plan-summary plan)
                          (list :dry-run nil
                                :topic-id topic-id*
                                :journal-subject-key subject-key)))
            (if (eql (dmx-workspace-annotation-write-plan-workspace-action plan)
                     :assign)
                (run-stage
                 :workspace-assignment
                 "Assigned the created topic to the selected workspace."
                 (lambda ()
                   (dmx-import-assign-topic-to-workspace
                    resolved-client
                    (dmx-workspace-annotation-write-plan-workspace-id plan)
                    topic-id*))
                 :detail
                 (format nil
                         "Assigned created topic ~D to ~A. Topicmap placement in ~A remains a later separate step."
                         topic-id*
                         (dmx-workspace-annotation-workspace-label
                          (dmx-workspace-annotation-write-plan-workspace-id
                           plan))
                         (dmx-workspace-annotation-topicmap-label
                          resolved-topicmap-id))
                 :error-summary
                 "Workspace assignment blocked"
                 :error-detail
                 (lambda (condition)
                   (format nil
                           "Created topic ~D, but assignment to ~A could not start because ~A. Topicmap placement in ~A remains a later separate step; visibility there is not enough."
                           topic-id*
                           (dmx-workspace-annotation-workspace-label
                            (dmx-workspace-annotation-write-plan-workspace-id
                             plan))
                           (if (typep condition 'dmx-import-config-error)
                               "DMX auth is missing"
                               (format nil "~A" condition))
                           (dmx-workspace-annotation-topicmap-label
                            resolved-topicmap-id))))
                (record-stage
                 :workspace-assignment
                 :skipped
                 "Workspace assignment was already current; no additional write was needed."))
            (if (eql (dmx-workspace-annotation-write-plan-topicmap-action plan)
                     :add)
                (run-stage
                 :topicmap-placement
                 (format nil
                         "Added topic ~D to workspace topicmap ~D."
                         topic-id*
                         resolved-topicmap-id)
                 (lambda ()
                   (dmx-import-add-topic-to-topicmap
                    resolved-client
                    resolved-topicmap-id
                    topic-id*
                    (dmx-workspace-annotation-write-plan-view-props plan))))
                (record-stage
                 :topicmap-placement
                 :skipped
                 "Topicmap placement was already present; no add-to-topicmap write was needed."))
            (setf after-topic (dmx-import-read-topic resolved-client topic-id*)
                  after-state
                  (dmx-workspace-journal-live-snapshot
                   resolved-client
                   after-topic
                   resolved-topicmap-id))
            (setf journal-events
                  (run-stage
                   :journal-transition
                   "Recorded the workspace journal transition for the live annotation write."
                   (lambda ()
                     (record-workspace-transition
                      *workspace-journal-sink*
                      previous-state
                      after-state
                      resolved-topicmap-id
                      :client resolved-client))))
            (setf raw-result
                  (append (dmx-workspace-annotation-plan-summary plan)
                          (list :dry-run nil
                                :topic-id topic-id*
                                :journal-subject-key subject-key
                                :journal-event-count (length journal-events))))
            (setf persisted-annotation
                  (run-stage
                   :reopen-persisted-annotation
                   (format nil
                           "Reopened persisted annotation topic ~D as workspace-dock-annotation."
                           topic-id*)
                   (lambda ()
                     (read-dmx-workspace-annotation
                      :topic-id topic-id*
                     :workspace-topicmap-id resolved-topicmap-id
                     :client resolved-client)))))
        (error (condition)
          (setf failure-condition (or failure-condition condition))))
      (let* ((journal-preflight-auth-blocked-p
               (and (eq failure-stage :prepare-transition)
                    (workspace-annotation-auth-blocked-condition-p
                     failure-condition)))
             (pending-auth-p
               (workspace-annotation-auth-awaiting-stage-p
                failure-stage
                failure-condition
                :persisted-topic-id persisted-topic-id))
             (auth-awaiting-p
               (workspace-annotation-auth-awaiting-stage-p
                failure-stage
                failure-condition
                :persisted-topic-id persisted-topic-id
                :journal-preflight-auth-blocked-p
                journal-preflight-auth-blocked-p))
             (report
               (make-instance
                'workspace-annotation-persistence-report
                :annotation annotation
                :workspace-topicmap-id resolved-topicmap-id
                :workspace-id
                (or (and plan
                         (dmx-workspace-annotation-write-plan-workspace-id plan))
                    (workspace-annotation-persistence-debug-workspace-id-of
                     debug))
                :client resolved-client
                :exact-form
                (workspace-annotation-persistence-debug-exact-form-of debug)
                :stepper-source
                (workspace-annotation-persistence-debug-stepper-source-of debug)
                :dry-run-preview
                (workspace-annotation-persistence-debug-dry-run-preview-of debug)
                :annotation-key
                (workspace-annotation-persistence-debug-annotation-key-of debug)
                :runtime-relation-id
                (workspace-annotation-persistence-debug-runtime-relation-id-of
                 debug)
                :plan plan
                :stage-results (nreverse stage-results)
                :report-status (cond
                                 (auth-awaiting-p :pending-auth)
                                 (failure-stage :failed)
                                 (t :persisted))
                :failure-stage failure-stage
                :condition failure-condition
                :transport-diagnostics
                (workspace-annotation-transport-diagnostics
                 plan
                 failure-stage
                 failure-condition)
                :topic-upsert-evidence
                (and (eq failure-stage :topic-upsert)
                     (workspace-annotation-topic-upsert-evidence
                      plan
                      failure-condition))
                :raw-result raw-result
                :persisted-topic-id persisted-topic-id
                :persisted-annotation persisted-annotation
                :subject-key subject-key
                :previous-state previous-state
                :journal-preflight-summary journal-preflight-summary
                :journal-preflight-repair-summary
                (or journal-preflight-repair-summary
                    (and (typep failure-condition
                                'dmx-workspace-journal-companion-repair-failed-error)
                         (dmx-workspace-journal-companion-repair-summary-of
                          failure-condition)))
                :journal-preflight-auth-context
                (and journal-preflight-auth-blocked-p
                     (workspace-annotation-journal-preflight-auth-context
                      plan
                      resolved-client
                      journal-preflight-summary
                      failure-condition))
                :assignment-auth-context
                (and pending-auth-p
                     (workspace-annotation-assignment-auth-context
                      plan
                      resolved-client
                      persisted-topic-id
                      failure-condition)))))
        (setf (workspace-annotation-persistence-debug-last-report-of debug)
              report)
        report))))

(defun make-explicit-workspace-annotation-continuation-client
    (report &key auth-mode username password authorization-header auth-token)
  (let* ((report-client (workspace-annotation-persistence-report-client-of report))
         (plan (workspace-annotation-persistence-report-plan-of report)))
    (make-http-dmx-import-client-from-explicit-auth
     :base-url (and (typep report-client 'http-dmx-import-client)
                    (dmx-import-base-url-of report-client))
     :workspace-id (and plan
                        (dmx-workspace-annotation-write-plan-workspace-id plan))
     :auth-mode auth-mode
     :username username
     :password password
     :authorization-header authorization-header
     :auth-token auth-token
     :verbose nil)))

(defun workspace-annotation-continuation-ready-p (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (workspace-annotation-persistence-report-plan-of report)
       (workspace-annotation-persistence-report-saved-topic-id-of report)))

(defun workspace-annotation-continuation-stage-results
    (annotation plan topic-id workspace-topicmap-id)
  (declare (ignore workspace-topicmap-id))
  (list
   (workspace-annotation-persistence-stage-entry
    :normalize-annotation
    :completed
    "Reopened the saved annotation as the typed continuation input.")
   (workspace-annotation-persistence-stage-entry
    :build-write-plan
    :completed
    "Rebuilt the typed write plan for the saved annotation before guarded continuation.")
   (workspace-annotation-persistence-stage-entry
    :validate-payload
    :completed
    (format nil
            "Payload validation is ~A; topic action ~A, workspace action ~A, topicmap action ~A."
            (dmx-workspace-annotation-write-plan-payload-validation-status plan)
            (dmx-workspace-annotation-write-plan-topic-action plan)
            (dmx-workspace-annotation-write-plan-workspace-action plan)
            (dmx-workspace-annotation-write-plan-topicmap-action plan))
    :detail
    (and (dmx-workspace-annotation-write-plan-view-props plan)
         (dmx-topicmap-view-props-json-string
          (dmx-workspace-annotation-write-plan-view-props plan))))
   (workspace-annotation-persistence-stage-entry
    :backend-compatibility-preflight
    :completed
    "Backend compatibility was already established at the typed annotation entrypoint; continuation resumes from the preserved topic id.")
   (workspace-annotation-persistence-stage-entry
    :topic-upsert
    :completed
    (format nil
            "Saved annotation topic ~D already exists; guarded continuation starts after topic upsert."
            topic-id)
    :detail
    (format nil
            "Reopened ~A in ~A with storage mode ~A. Workspace assignment and topicmap placement remain later separate stages."
            (or (title-of annotation) "saved workspace annotation")
            (dmx-workspace-annotation-topicmap-label
             (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan))
            (workspace-annotation-storage-mode-label
             (dmx-workspace-annotation-write-plan-storage-mode plan))))))

(defun make-workspace-annotation-continuation-report
    (annotation plan topic-id workspace-topicmap-id client)
  (let* ((subject-key (dmx-workspace-annotation-write-plan-uri plan))
         (journal-preflight-summary
           (ignore-errors
             (dmx-workspace-journal-preflight-summary
              client
              subject-key
              "uri"
              subject-key
              workspace-topicmap-id
              :subject-uri subject-key
              :subject-kind "workspace-annotation"
              :ownership-class "hyperdoc-workspace-annotation"))))
    (make-instance
     'workspace-annotation-persistence-report
     :annotation annotation
     :workspace-topicmap-id workspace-topicmap-id
     :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
     :client client
     :exact-form
     (workspace-annotation-persistence-stepper-display-form
      workspace-topicmap-id
      :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
      :storage-mode (dmx-workspace-annotation-write-plan-storage-mode plan))
     :stepper-source
     (workspace-annotation-persistence-stepper-source
      workspace-topicmap-id
      :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
      :storage-mode (dmx-workspace-annotation-write-plan-storage-mode plan))
     :annotation-key (dmx-workspace-annotation-write-plan-annotation-key plan)
     :runtime-relation-id
     (and (typep annotation 'workspace-dock-annotation)
          (workspace-annotation-runtime-relation-id-of annotation))
     :plan plan
     :stage-results
     (workspace-annotation-continuation-stage-results
      annotation
      plan
      topic-id
      workspace-topicmap-id)
     :report-status :continuation-ready
     :failure-stage nil
     :condition nil
     :transport-diagnostics nil
     :topic-upsert-evidence nil
     :raw-result
     (append (dmx-workspace-annotation-plan-summary plan)
             (list :dry-run nil
                   :topic-id topic-id
                   :journal-subject-key subject-key
                   :continuation-source :saved-topic))
     :persisted-topic-id topic-id
     :persisted-annotation annotation
     :subject-key subject-key
     :previous-state nil
     :journal-preflight-summary journal-preflight-summary
     :journal-preflight-auth-context nil
     :assignment-auth-context nil)))

(defun continue-workspace-annotation-with-guarded-assignment
    (plan client topic-id workspace-topicmap-id &key (dry-run nil))
  (execute-dmx-workspace-topic-workspace-assignment-repair
   topic-id
   :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
   :workspace-topicmap-id workspace-topicmap-id
   :client client
   :dry-run dry-run))

(defun continue-workspace-annotation-with-guarded-topicmap-placement
    (plan client topic-id workspace-topicmap-id &key (dry-run nil))
  (execute-dmx-workspace-topicmap-context-upsert
   topic-id
   :workspace-topicmap-id workspace-topicmap-id
   :client client
   :view-props (dmx-workspace-annotation-write-plan-view-props plan)
   :dry-run dry-run))

(defun guarded-workspace-assignment-stage-summary (summary)
  (case (getf summary :workspace-action)
    (:assign
     (format nil
             "Guarded workspace-assignment repair assigned topic ~D to workspace ~D."
             (getf summary :topic-id)
             (getf summary :workspace-id)))
    (:already-assigned
     (format nil
             "Guarded workspace-assignment repair confirmed topic ~D already belonged to workspace ~D."
             (getf summary :topic-id)
             (getf summary :workspace-id)))
    (otherwise
     "Guarded workspace-assignment repair finished.")))

(defun guarded-workspace-assignment-stage-detail (summary)
  (format nil
          "Executor repair_workspace_topic_assignment kept workspace assignment distinct from topicmap placement. Result workspace: ~A. Topicmap preserved separately: ~A."
          (or (getf summary :result-workspace-id) "-")
          (if (getf summary :result-in-topicmap-p) "true" "false")))

(defun guarded-topicmap-placement-stage-summary (summary)
  (case (getf summary :topicmap-action)
    (:add
     (format nil
             "Guarded topicmap placement added topic ~D to workspace topicmap ~D."
             (getf summary :topic-id)
             (getf summary :topicmap-id)))
    (:set-view-props
     (format nil
             "Guarded topicmap placement refreshed validated view props for topic ~D in workspace topicmap ~D."
             (getf summary :topic-id)
             (getf summary :topicmap-id)))
    (otherwise
     "Guarded topicmap placement finished.")))

(defun guarded-topicmap-placement-stage-detail (summary)
  (declare (ignore summary))
  (format nil
          "Executor upsert_workspace_topicmap_context only changes topicmap membership/view props. Workspace ownership still has to be proven separately."))

(defun guarded-journal-transition-stage-summary
    (assignment-summary topicmap-summary)
  (let ((covered-stages
          (remove nil
                  (list (when assignment-summary "workspace-assignment")
                        (when topicmap-summary "topicmap-placement")))))
    (if covered-stages
        (format nil
                "Guarded continuation recorded journal transitions inside the shared-workspace executors for ~{~A~^ and ~}."
                covered-stages)
        "Guarded continuation had no remaining guarded journal transition to record.")))

(defun continue-workspace-annotation-persistence-with-client
    (report client)
  (unless (or (workspace-annotation-pending-auth-p report)
              (workspace-annotation-continuation-ready-p report))
    (error 'fedwiki-dmx-import-error
           :message
           "Workspace annotation persistence continuation requires a pending-auth report or a saved-topic continuation report"))
  (let* ((plan (workspace-annotation-persistence-report-plan-of report))
         (topic-id (workspace-annotation-persistence-report-persisted-topic-id-of
                    report))
         (workspace-topicmap-id
           (workspace-annotation-persistence-report-workspace-topicmap-id-of
            report))
         (subject-key
           (workspace-annotation-persistence-report-subject-key-of report))
         (previous-state
           (workspace-annotation-persistence-report-previous-state-of report))
         (stage-results
           (copy-tree
            (workspace-annotation-persistence-report-stage-results-of report)))
         (failure-stage nil)
         (failure-condition nil)
         (guarded-assignment-summary nil)
         (guarded-topicmap-summary nil)
         (persisted-annotation nil)
         (raw-result
           (or (workspace-annotation-persistence-report-raw-result-of report)
               (append (dmx-workspace-annotation-plan-summary plan)
                       (list :dry-run nil
                             :topic-id topic-id
                             :journal-subject-key subject-key)))))
    (labels ((record-stage (stage status summary &key detail)
               (setf stage-results
                     (workspace-annotation-stage-results-with-entry
                      stage-results
                      (workspace-annotation-persistence-stage-entry
                       stage
                       status
                       summary
                       :detail detail))))
             (materialize-stage-detail (detail &optional condition)
               (typecase detail
                 (function
                  (funcall detail condition))
                 (t
                  detail)))
             (run-stage (stage summary thunk &key detail)
               (handler-case
                   (let ((value (funcall thunk)))
                     (record-stage stage
                                   :completed
                                   summary
                                   :detail (materialize-stage-detail detail))
                     value)
                 (error (condition)
                   (setf failure-stage stage
                         failure-condition condition)
                   (record-stage stage
                                 :error
                                 summary
                                 :detail (or (materialize-stage-detail
                                              detail
                                              condition)
                                             (format nil "~A" condition)))
                   (error condition)))))
      (handler-case
          (progn
            (if (eql (dmx-workspace-annotation-write-plan-workspace-action plan)
                     :assign)
                (setf guarded-assignment-summary
                      (run-stage
                       :workspace-assignment
                       "Guarded workspace-assignment repair finished."
                       (lambda ()
                         (continue-workspace-annotation-with-guarded-assignment
                          plan
                          client
                          topic-id
                          workspace-topicmap-id))
                       :detail
                       (lambda (condition)
                         (declare (ignore condition))
                         (guarded-workspace-assignment-stage-detail
                          guarded-assignment-summary))))
                (record-stage
                 :workspace-assignment
                 :skipped
                 "Workspace assignment was already current; no guarded repair was needed."
                 :detail
                 "Workspace assignment stays distinct from topicmap placement even when no repair is needed."))
            (when guarded-assignment-summary
              (record-stage
               :workspace-assignment
               :completed
               (guarded-workspace-assignment-stage-summary
                guarded-assignment-summary)
               :detail
               (guarded-workspace-assignment-stage-detail
                guarded-assignment-summary)))
            (if (eql (dmx-workspace-annotation-write-plan-topicmap-action plan)
                     :add)
                (setf guarded-topicmap-summary
                      (run-stage
                       :topicmap-placement
                       "Guarded topicmap placement finished."
                       (lambda ()
                         (continue-workspace-annotation-with-guarded-topicmap-placement
                          plan
                          client
                          topic-id
                          workspace-topicmap-id))
                       :detail
                       (lambda (condition)
                         (declare (ignore condition))
                         (guarded-topicmap-placement-stage-detail
                          guarded-topicmap-summary))))
                (record-stage
                 :topicmap-placement
                 :skipped
                 "Topicmap placement was already present; no guarded topicmap upsert was needed."
                 :detail
                 "Topicmap visibility remains separate from workspace assignment."))
            (when guarded-topicmap-summary
              (record-stage
               :topicmap-placement
               :completed
               (guarded-topicmap-placement-stage-summary
                guarded-topicmap-summary)
               :detail
               (guarded-topicmap-placement-stage-detail
                guarded-topicmap-summary)))
            (record-stage
             :journal-transition
             :completed
             (guarded-journal-transition-stage-summary
              guarded-assignment-summary
              guarded-topicmap-summary)
             :detail
             "The shared-workspace repair and topicmap executors emit their own guarded journal transitions. Topicmap success there still does not imply workspace ownership.")
            (setf raw-result
                  (append raw-result
                          (list :guarded-workspace-assignment
                                guarded-assignment-summary
                                :guarded-topicmap-placement
                                guarded-topicmap-summary)))
            (setf persisted-annotation
                  (run-stage
                   :reopen-persisted-annotation
                   (format nil
                           "Reopened persisted annotation topic ~D as workspace-dock-annotation."
                           topic-id)
                   (lambda ()
                     (read-dmx-workspace-annotation
                      :topic-id topic-id
                      :workspace-topicmap-id workspace-topicmap-id
                      :client client)))))
        (error (condition)
          (setf failure-condition (or failure-condition condition))))
      (make-workspace-annotation-persistence-report-like
       report
       :client client
       :stage-results stage-results
       :report-status (cond
                        ((workspace-annotation-auth-awaiting-stage-p
                          failure-stage
                          failure-condition
                          :persisted-topic-id topic-id)
                         :pending-auth)
                        (failure-stage :failed)
                        (t :persisted))
       :failure-stage failure-stage
       :condition failure-condition
       :transport-diagnostics
       (workspace-annotation-transport-diagnostics
        plan
        failure-stage
        failure-condition)
       :raw-result raw-result
       :persisted-annotation persisted-annotation
       :assignment-auth-context
       (and (eq failure-stage :workspace-assignment)
            (workspace-annotation-auth-blocked-condition-p failure-condition)
            (workspace-annotation-assignment-auth-context
             plan
             client
             topic-id
             failure-condition))))))

(defun workspace-annotation-path-diff-guarded-assignment-preview
    (plan client topic-id workspace-topicmap-id)
  (when (and plan topic-id workspace-topicmap-id)
    (handler-case
        (values
         (continue-workspace-annotation-with-guarded-assignment
          plan
          client
          topic-id
          workspace-topicmap-id
          :dry-run t)
         nil)
      (error (condition)
        (values nil condition)))))

(defun workspace-annotation-path-diff-guarded-topicmap-preview
    (plan client topic-id workspace-topicmap-id)
  (when (and plan topic-id workspace-topicmap-id)
    (handler-case
        (values
         (continue-workspace-annotation-with-guarded-topicmap-placement
          plan
          client
          topic-id
          workspace-topicmap-id
          :dry-run t)
         nil)
      (error (condition)
        (values nil condition)))))

(defun workspace-annotation-path-diff-status-label (status)
  (when status
    (string-downcase (format nil "~A" status))))

(defun workspace-annotation-path-diff-raw-stage-status (comparison stage)
  (let ((report (workspace-annotation-path-diff-raw-report-of comparison)))
    (cond
      ((null report)
       :pending)
      ((typep report 'workspace-annotation-persistence-report)
       (if (eq stage :backend-compatibility-preflight)
           :completed
           (or (getf (workspace-annotation-persistence-stage-result report stage)
                     :status)
               :pending)))
      ((and (eq stage :backend-compatibility-preflight)
            (typep report 'workspace-annotation-backend-compatibility-report))
       (case (workspace-annotation-backend-compatibility-report-status-of report)
         (:available :completed)
         (:fallback-available :completed)
         (:blocked :error)
         (otherwise :pending)))
      (t
       :pending))))

(defun workspace-annotation-path-diff-guarded-stage-status (comparison stage)
  (let ((assignment-summary
          (workspace-annotation-path-diff-guarded-assignment-summary-of
           comparison))
        (assignment-condition
          (workspace-annotation-path-diff-guarded-assignment-condition-of
           comparison))
        (topicmap-summary
          (workspace-annotation-path-diff-guarded-topicmap-summary-of
           comparison))
        (topicmap-condition
          (workspace-annotation-path-diff-guarded-topicmap-condition-of
           comparison)))
    (case stage
      (:workspace-assignment
       (cond
         (assignment-condition :error)
         (assignment-summary
          (if (getf assignment-summary :dry-run) :active :completed))
         (t :pending)))
      (:topicmap-placement
       (cond
         (topicmap-condition :error)
         (topicmap-summary
          (if (getf topicmap-summary :dry-run) :active :completed))
         (t :pending)))
      (:journal-transition
       (cond
         ((or assignment-condition topicmap-condition) :error)
         ((or assignment-summary topicmap-summary)
          (if (or (getf assignment-summary :dry-run)
                  (getf topicmap-summary :dry-run))
              :active
              :completed))
         (t :pending)))
      (:reopen-persisted-annotation
       :pending)
      (otherwise
       :pending))))

(defun workspace-annotation-path-diff-stage-status (comparison stage)
  (let ((raw (workspace-annotation-path-diff-raw-stage-status comparison stage))
        (guarded (workspace-annotation-path-diff-guarded-stage-status
                  comparison
                  stage)))
    (if (and raw
             (not (eq raw :pending)))
        raw
        guarded)))

(defun workspace-annotation-path-diff-raw-live-label (comparison stage)
  (let ((report (workspace-annotation-path-diff-raw-report-of comparison)))
    (cond
      ((null report)
       nil)
      ((and (typep report 'workspace-annotation-persistence-report)
            (eq stage
                (workspace-annotation-persistence-report-failure-stage-of
                 report))
            (workspace-annotation-auth-awaiting-p report))
       "error (pending-auth)")
      (t
       (workspace-annotation-path-diff-status-label
        (workspace-annotation-path-diff-raw-stage-status comparison stage))))))

(defun workspace-annotation-path-diff-guarded-live-label (comparison stage)
  (let ((assignment-summary
          (workspace-annotation-path-diff-guarded-assignment-summary-of
           comparison))
        (assignment-condition
          (workspace-annotation-path-diff-guarded-assignment-condition-of
           comparison))
        (topicmap-summary
          (workspace-annotation-path-diff-guarded-topicmap-summary-of
           comparison))
        (topicmap-condition
          (workspace-annotation-path-diff-guarded-topicmap-condition-of
           comparison))
        (topic-id
          (workspace-annotation-path-diff-continuation-topic-id-of comparison)))
    (case stage
      (:topic-upsert
       (and topic-id "preserved topic id"))
      (:workspace-assignment
       (cond
         (assignment-condition "error")
         (assignment-summary
          (if (getf assignment-summary :dry-run)
              (format nil "dry-run (~A)"
                      (workspace-annotation-render-value
                       (getf assignment-summary :workspace-action)))
              "completed"))
         (t nil)))
      (:topicmap-placement
       (cond
         (topicmap-condition "error")
         (topicmap-summary
          (if (getf topicmap-summary :dry-run)
              (format nil "dry-run (~A)"
                      (workspace-annotation-render-value
                       (getf topicmap-summary :topicmap-action)))
              "completed"))
         (t nil)))
      (:journal-transition
       (cond
         ((or assignment-condition topicmap-condition) "blocked upstream")
         ((or (and assignment-summary (getf assignment-summary :dry-run))
              (and topicmap-summary (getf topicmap-summary :dry-run)))
          "dry-run preview")
         ((or assignment-summary topicmap-summary)
          "covered by guarded executors")
         (t nil)))
      (:reopen-persisted-annotation
       (and topic-id "not run"))
      (otherwise
       nil))))

(defun workspace-annotation-path-diff-stage-live-status (comparison stage)
  (let ((raw (workspace-annotation-path-diff-raw-live-label comparison stage))
        (guarded (workspace-annotation-path-diff-guarded-live-label
                  comparison
                  stage)))
    (cond
      ((and raw guarded)
       (format nil "raw: ~A; guarded: ~A" raw guarded))
      (raw
       (format nil "raw: ~A" raw))
      (guarded
       (format nil "guarded: ~A" guarded))
      (t
       nil))))

(defun workspace-annotation-path-next-step-mode-label (mode)
  (case mode
    (:inspect "read-only inspection")
    (:continue "guarded continuation")
    (:repair "explicit-auth repair")
    (:review "diagnostic review")
    (:none "no further action")
    (otherwise
     (format nil "~(~A~)" mode))))

(defun workspace-annotation-path-consequence-actionability-label (value)
  (case value
    (:no-change-yet "no change yet")
    (:review-needed "review needed")
    (:repair-needed "repair needed")
    (:ready-to-continue "ready to continue")
    (:no-further-action "no further action")
    (otherwise
     (format nil "~(~A~)" value))))

(defun workspace-annotation-path-consequence-kind-label (value)
  (case value
    (:no-change "no-change")
    (:continue-with-guarded-boundary "continue-with-guarded-boundary")
    (:repair-workspace-assignment "repair-workspace-assignment")
    (:inspect-state-before-mutation "inspect-state-before-mutation")
    (:review-divergence "review-divergence")
    (:persisted-success "persisted-success")
    (otherwise
     (format nil "~(~A~)" value))))

(defun make-workspace-annotation-path-next-step-target
    (id label executor-or-surface-name mode auth-required-p stage-scope
     &key (kind :tool) summary target-object target-select)
  (make-instance 'workspace-annotation-path-next-step-target
                 :id id
                 :title label
                 :summary summary
                 :kind kind
                 :label label
                 :executor-or-surface-name executor-or-surface-name
                 :mode mode
                 :auth-required-p auth-required-p
                 :stage-scope stage-scope
                 :target-object target-object
                 :target-select target-select))

(defun make-workspace-annotation-path-consequence
    (kind summary triggering-stages triggering-evidence actionability
     auth-required-p next-step-targets)
  (make-instance 'workspace-annotation-path-consequence
                 :id (format nil "workspace-annotation-consequence/~(~A~)"
                             kind)
                 :title (workspace-annotation-path-consequence-kind-label kind)
                 :summary summary
                 :kind kind
                 :triggering-stages triggering-stages
                 :triggering-evidence triggering-evidence
                 :actionability actionability
                 :auth-required-p auth-required-p
                 :next-step-targets next-step-targets))

(defun workspace-annotation-path-target-workspace-id (comparison)
  (or (and (workspace-annotation-path-diff-plan-of comparison)
           (dmx-workspace-annotation-write-plan-workspace-id
            (workspace-annotation-path-diff-plan-of comparison)))
      (workspace-annotation-path-diff-workspace-id-of comparison)))

(defun workspace-annotation-path-live-http-client-p (comparison)
  (typep (workspace-annotation-path-diff-client-of comparison)
         'http-dmx-import-client))

(defun inspect-workspace-annotation-path-state
    (client topic-id workspace-topicmap-id)
  (if (null topic-id)
      (list :status :not-applicable
            :topic-id nil
            :workspace-id nil
            :workspace-read-p nil
            :in-topicmap-p nil
            :topicmap-read-p nil
            :evidence
            (list (list :kind :continuation-topic-id
                        :value nil)))
      (let ((workspace-read-p nil)
            (topicmap-read-p nil)
            (workspace-id nil)
            (in-topicmap-p nil)
            (workspace-condition nil)
            (topicmap-condition nil))
        (handler-case
            (let ((workspace (dmx-import-read-topic-workspace client topic-id)))
              (setf workspace-id (and workspace
                                      (dmx-import-object-id workspace))
                    workspace-read-p t))
          (error (condition)
            (setf workspace-condition condition)))
        (handler-case
            (setf in-topicmap-p
                  (and workspace-topicmap-id
                       (dmx-import-topic-in-topicmap-p
                        client
                        workspace-topicmap-id
                        topic-id))
                  topicmap-read-p t)
          (error (condition)
            (setf topicmap-condition condition)))
        (list :status (cond
                        ((and workspace-read-p topicmap-read-p) :available)
                        ((or workspace-read-p topicmap-read-p) :partial)
                        (t :blocked))
              :topic-id topic-id
              :workspace-id workspace-id
              :workspace-read-p workspace-read-p
              :in-topicmap-p in-topicmap-p
              :topicmap-read-p topicmap-read-p
              :workspace-condition workspace-condition
              :topicmap-condition topicmap-condition
              :evidence
              (remove nil
                      (list
                       (list :kind :topic-id
                             :value topic-id)
                       (list :kind :workspace-read-p
                             :value workspace-read-p)
                       (list :kind :current-workspace-id
                             :value workspace-id)
                       (list :kind :topicmap-read-p
                             :value topicmap-read-p)
                       (list :kind :topicmap-visible-p
                             :value in-topicmap-p)
                       (and workspace-condition
                            (list :kind :workspace-read-condition
                                  :value (format nil "~A"
                                                 workspace-condition)))
                       (and topicmap-condition
                            (list :kind :topicmap-read-condition
                                  :value (format nil "~A"
                                                 topicmap-condition)))))))))

(defun workspace-annotation-path-diff-divergent-stages (comparison)
  (loop for stage in *dmx-workspace-annotation-path-diff-stage-order*
        for raw = (workspace-annotation-path-diff-raw-live-label
                   comparison
                   stage)
        for guarded = (workspace-annotation-path-diff-guarded-live-label
                       comparison
                       stage)
        when (or (eq stage :topic-upsert)
                 (and (or raw guarded)
                      (not (equal raw guarded))))
          collect stage))

(defun workspace-annotation-path-state-repair-needed-p (comparison)
  (let* ((state (workspace-annotation-path-diff-state-snapshot-of comparison))
         (target-workspace-id
           (workspace-annotation-path-target-workspace-id comparison)))
    (and state
         (getf state :workspace-read-p)
         (getf state :topicmap-read-p)
         (getf state :in-topicmap-p)
         target-workspace-id
         (not (eql (getf state :workspace-id)
                   target-workspace-id)))))

(defun workspace-annotation-path-state-current-p (comparison)
  (let* ((state (workspace-annotation-path-diff-state-snapshot-of comparison))
         (plan (workspace-annotation-path-diff-plan-of comparison))
         (target-workspace-id
           (workspace-annotation-path-target-workspace-id comparison)))
    (and state
         (getf state :workspace-read-p)
         (getf state :topicmap-read-p)
         (eql (getf state :workspace-id) target-workspace-id)
         (getf state :in-topicmap-p)
         (or (null plan)
             (not (eql (dmx-workspace-annotation-write-plan-workspace-action
                        plan)
                       :assign)))
         (or (null plan)
             (not (eql (dmx-workspace-annotation-write-plan-topicmap-action
                        plan)
                       :add))))))

(defun workspace-annotation-path-reopen-success-proved-p (comparison)
  (let ((annotation (workspace-annotation-path-diff-annotation-of comparison))
        (topic-id
          (workspace-annotation-path-diff-continuation-topic-id-of comparison)))
    (and (typep annotation 'workspace-dock-annotation)
         topic-id
         (eql (workspace-annotation-topic-id-of annotation)
              topic-id))))

(defun workspace-annotation-path-consequences-for-stages
    (comparison stages)
  (let ((stage-list (if (listp stages) stages (list stages))))
    (remove-if-not
     (lambda (consequence)
       (intersection stage-list
                     (workspace-annotation-path-consequence-triggering-stages-of
                      consequence)
                     :test #'eq))
     (workspace-annotation-path-diff-consequences-of comparison))))

(defun workspace-annotation-path-consequence-summary-for-stages
    (comparison stages)
  (let ((consequences
          (workspace-annotation-path-consequences-for-stages comparison stages)))
    (when consequences
      (format nil
              "Consequence: ~{~A~^; ~}"
              (mapcar #'title-of consequences)))))

(defun make-workspace-annotation-path-persisted-success-consequence
    (topic-id evidence)
  (make-workspace-annotation-path-consequence
   :persisted-success
   (format nil
           "The raw persist path reached reopen successfully for topic ~D. No further operational mutation is required."
           topic-id)
   '(:reopen-persisted-annotation)
   evidence
   :no-further-action
   nil
   (list
    (make-workspace-annotation-path-next-step-target
     "no-further-action"
     "No mutation required"
     "workspace_annotation result"
     :none
     nil
     '(:reopen-persisted-annotation)
     :kind :surface
     :summary
     "The persisted annotation is already reopened and inspectable."))))

(defun derive-workspace-annotation-path-consequences (comparison)
  (let* ((report (workspace-annotation-path-diff-raw-report-of comparison))
         (state (workspace-annotation-path-diff-state-snapshot-of comparison))
         (topic-id
           (workspace-annotation-path-diff-continuation-topic-id-of comparison))
         (live-http-p (workspace-annotation-path-live-http-client-p comparison))
         (target-workspace-id
           (workspace-annotation-path-target-workspace-id comparison))
         (divergent-stages
           (workspace-annotation-path-diff-divergent-stages comparison))
         (rows '()))
    (flet ((add (row)
             (push row rows)))
      (when (and (typep report 'workspace-annotation-persistence-report)
                 (workspace-annotation-pending-auth-p report)
                 topic-id)
        (add
         (make-workspace-annotation-path-consequence
          :continue-with-guarded-boundary
          (format nil
                  "Raw persist stopped at workspace assignment after topic upsert and preserved topic ~D. The operational next step is the guarded continuation boundary."
                  topic-id)
          '(:topic-upsert :workspace-assignment)
          (remove nil
                  (append
                   (list (list :kind :report-status
                               :value
                               (workspace-annotation-persistence-report-status-of
                                report))
                         (list :kind :failure-stage
                               :value
                               (workspace-annotation-persistence-report-failure-stage-of
                                report))
                         (list :kind :persisted-topic-id
                               :value topic-id))
                   (and state
                        (getf state :evidence))))
          :ready-to-continue
          live-http-p
          (list
           (make-workspace-annotation-path-next-step-target
            "continue-workspace-annotation"
            "continue_workspace_annotation"
            "continue_workspace_annotation"
            :continue
            live-http-p
            '(:workspace-assignment :topicmap-placement
              :journal-transition :reopen-persisted-annotation)
            :summary
            "Resume from the preserved topic id through the guarded post-upsert stages.")
           (make-workspace-annotation-path-next-step-target
            "raw-persistence-report"
            "Open preserved raw persistence report"
            "workspace-annotation-persistence-report"
            :review
            nil
            '(:workspace-assignment)
            :kind :surface
             :summary
             "Review the preserved raw report and its evidence before continuing."
             :target-object report
             :target-select "Overview")))))
      (when (workspace-annotation-path-state-repair-needed-p comparison)
        (add
         (make-workspace-annotation-path-consequence
          :repair-workspace-assignment
          (format nil
                  "Topic ~D is visible in workspace topicmap ~A but the workspace assignment fact is missing or differs from target workspace ~A. Topicmap visibility does not solve ownership."
                  topic-id
                  (workspace-annotation-render-value
                   (workspace-annotation-path-diff-workspace-topicmap-id-of
                    comparison))
                  (workspace-annotation-render-value target-workspace-id))
          '(:workspace-assignment :topicmap-placement)
          (remove nil
                  (append
                   (list (list :kind :target-workspace-id
                               :value target-workspace-id))
                   (and state
                        (getf state :evidence))))
          :repair-needed
          live-http-p
          (list
           (make-workspace-annotation-path-next-step-target
            "repair-workspace-topic-assignment"
            "repair_workspace_topic_assignment"
            "repair_workspace_topic_assignment"
            :repair
            live-http-p
            '(:workspace-assignment)
            :summary
            "Repair or confirm workspace ownership without treating topicmap placement as ownership.")
           (make-workspace-annotation-path-next-step-target
            "read-topic-before-repair"
            "read_dmx_topic"
            "read_dmx_topic"
            :inspect
             nil
             '(:workspace-assignment :topicmap-placement)
             :summary
             "Inspect the persisted topic state before running the guarded repair.")))))
      (when (and state
                 (member (getf state :status) '(:blocked :partial) :test #'eq)
                 topic-id
                 (null rows))
        (add
         (make-workspace-annotation-path-consequence
          :inspect-state-before-mutation
          (format nil
                  "State inspection is incomplete for topic ~D. Inspect the persisted topic and topicmap state before acting."
                  topic-id)
          '(:workspace-assignment :topicmap-placement)
          (getf state :evidence)
          :review-needed
          nil
          (list
           (make-workspace-annotation-path-next-step-target
            "read-dmx-topic"
            "read_dmx_topic"
            "read_dmx_topic"
            :inspect
            nil
            '(:workspace-assignment :topicmap-placement)
            :summary
            "Inspect the persisted topic object and current workspace assignment fact.")
           (make-workspace-annotation-path-next-step-target
            "read-dmx-topicmap"
            "read_dmx_topicmap"
            "read_dmx_topicmap"
            :inspect
             nil
             '(:topicmap-placement)
             :summary
             "Inspect the topicmap projection separately from workspace ownership.")))))
      (when (and (typep report 'workspace-annotation-persistence-report)
                 (eq (workspace-annotation-persistence-report-status-of report)
                     :persisted))
        (add
         (make-workspace-annotation-path-persisted-success-consequence
          (workspace-annotation-persistence-report-saved-topic-id-of report)
          (list
           (list :kind :report-status
                 :value
                 (workspace-annotation-persistence-report-status-of report))
           (list :kind :persisted-topic-id
                 :value
                 (workspace-annotation-persistence-report-saved-topic-id-of
                  report))))))
      (when (and (null report)
                 (workspace-annotation-path-state-current-p comparison)
                 (workspace-annotation-path-reopen-success-proved-p comparison))
        (add
         (make-workspace-annotation-path-persisted-success-consequence
          topic-id
          (append
           (list (list :kind :persisted-annotation-topic-id
                       :value topic-id))
           (and state
                (getf state :evidence))))))
      (when (and (null report)
                 (workspace-annotation-path-state-current-p comparison)
                 (not (workspace-annotation-path-reopen-success-proved-p
                       comparison)))
        (add
         (make-workspace-annotation-path-consequence
          :no-change
          "Compared paths do not imply a different operational next step yet, but this comparison does not by itself prove successful completion through reopen."
          '(:workspace-assignment :topicmap-placement)
          (append
           (list (list :kind :target-workspace-id
                       :value target-workspace-id))
           (and state
                (getf state :evidence)))
          :no-change-yet
          nil
          (list
           (make-workspace-annotation-path-next-step-target
            "no-change"
            "No change yet"
            "current compare state"
            :none
            nil
             '(:workspace-assignment :topicmap-placement)
             :kind :surface
             :summary
             "The compare surface shows no additional guarded mutation requirement.")))))
      (when (and (null rows)
                 (or (and (typep report 'workspace-annotation-persistence-report)
                          (eq (workspace-annotation-persistence-report-status-of
                               report)
                              :failed))
                     (workspace-annotation-path-diff-guarded-assignment-condition-of
                      comparison)
                     (workspace-annotation-path-diff-guarded-topicmap-condition-of
                      comparison)
                     divergent-stages))
        (add
         (make-workspace-annotation-path-consequence
          :review-divergence
          "The compared paths diverge in stage ownership or executor provenance without a narrower automatic mutation recommendation. Review the boundary before acting."
          (or divergent-stages
              '(:topic-upsert :workspace-assignment))
          (remove nil
                  (append
                   (and report
                        (list (list :kind :report-status
                                    :value
                                    (workspace-annotation-persistence-report-status-of
                                     report))
                              (list :kind :failure-stage
                                    :value
                                    (workspace-annotation-persistence-report-failure-stage-of
                                     report))))
                   (and (workspace-annotation-path-diff-guarded-assignment-condition-of
                         comparison)
                        (list
                         (list :kind :guarded-assignment-condition
                               :value
                               (format nil "~A"
                                       (workspace-annotation-path-diff-guarded-assignment-condition-of
                                        comparison)))))
                   (and (workspace-annotation-path-diff-guarded-topicmap-condition-of
                         comparison)
                        (list
                         (list :kind :guarded-topicmap-condition
                               :value
                               (format nil "~A"
                                       (workspace-annotation-path-diff-guarded-topicmap-condition-of
                                        comparison)))))))
          :review-needed
          nil
          (list
           (make-workspace-annotation-path-next-step-target
            "compare-surface"
            "Compare with guarded workspace path"
            "workspace-annotation-path-diff"
            :review
            nil
            divergent-stages
            :kind :surface
            :summary
            "Inspect the shared stage vocabulary and boundary ownership directly.")
           (make-workspace-annotation-path-next-step-target
            "read-dmx-topic-for-review"
            "read_dmx_topic"
            "read_dmx_topic"
            :inspect
            nil
            divergent-stages
            :summary
            "Inspect the persisted topic facts before choosing a mutation surface."))))))
    (nreverse rows)))

(defun workspace-annotation-path-diff-comparison-label (stage)
  (case stage
    ((:normalize-annotation
      :build-write-plan
      :validate-payload
      :backend-compatibility-preflight)
     "shared entrypoint")
    (:topic-upsert
     "divergent boundary")
    (otherwise
     "shared logical stage")))

(defun workspace-annotation-path-diff-auth-expectation (stage)
  (case stage
    ((:normalize-annotation :build-write-plan :validate-payload)
     "none")
    (:backend-compatibility-preflight
     "capability probe only")
    (:topic-upsert
     "carrier write auth only")
    (:workspace-assignment
     "guarded authenticated workspace mutation on live HTTP clients")
    (:topicmap-placement
     "guarded authenticated topicmap mutation; distinct from ownership")
    (:journal-transition
     "inherited from the guarded mutation executor")
    (:reopen-persisted-annotation
     "none")
    (otherwise
     "none")))

(defun workspace-annotation-path-diff-executor-name (stage)
  (case stage
    (:normalize-annotation
     "raw: dmx-workspace-annotation-from-object; guarded: reuse typed entrypoint result")
    (:build-write-plan
     "raw: plan-dmx-workspace-annotation-write-from-object; guarded: reuse typed write plan")
    (:validate-payload
     "raw: plan-dmx-workspace-annotation-write; guarded: reuse validated payload/view props")
    (:backend-compatibility-preflight
     "raw: probe-live-workspace-annotation-type-support; guarded: reuse prior preflight outcome")
    (:topic-upsert
     "raw: persist-dock-annotation-to-workspace / execute-dmx-workspace-annotation-write; guarded: preserved created topic id")
    (:workspace-assignment
     "raw: dmx-import-assign-topic-to-workspace; guarded: repair_workspace_topic_assignment / continue_workspace_annotation")
    (:topicmap-placement
     "raw: dmx-import-add-topic-to-topicmap; guarded: upsert_workspace_topicmap_context / continue_workspace_annotation")
    (:journal-transition
     "raw: dmx-workspace-journal-record-transition; guarded: continue_workspace_annotation via guarded shared-workspace executors")
    (:reopen-persisted-annotation
     "raw: read-dmx-workspace-annotation; guarded: continue_workspace_annotation")
    (otherwise
     "-")))

(defun workspace-annotation-path-diff-raw-behavior (comparison stage)
  (declare (ignore comparison))
  (case stage
    (:normalize-annotation
     "Typed entrypoint normalizes the Dock annotation into the workspace-annotation payload fields.")
    (:build-write-plan
     "Typed entrypoint builds one write plan that classifies topic, workspace, and topicmap actions together.")
    (:validate-payload
     "Typed entrypoint validates the payload and normalized topicmap view props before any live mutation.")
    (:backend-compatibility-preflight
     "Live persist probes raw hyperdoc.annotation support and the compatibility carrier before create-topic.")
    (:topic-upsert
     "Raw persist creates or updates the carrier topic before the workspace-assignment auth boundary.")
    (:workspace-assignment
     "Raw persist calls workspace assignment directly after topic upsert and stops here on pending-auth while preserving the created topic id.")
    (:topicmap-placement
     "Raw persist places the topic into the workspace topicmap only after workspace assignment. Topicmap membership is still not workspace ownership.")
    (:journal-transition
     "Raw persist records the workspace journal transition after the live mutation path succeeds.")
    (:reopen-persisted-annotation
     "Raw persist reopens the saved topic as a workspace-dock-annotation object.")
    (otherwise
     "-")))

(defun workspace-annotation-path-diff-guarded-behavior (comparison stage)
  (declare (ignore comparison))
  (case stage
    (:normalize-annotation
     "Guarded continuation reuses the same typed normalization result from the annotation persist entrypoint instead of inventing a second normalization path.")
    (:build-write-plan
     "Guarded continuation reuses the same typed write-plan semantics to decide which guarded post-upsert stages remain.")
    (:validate-payload
     "Guarded continuation relies on the already validated payload and view-props contract from the typed plan.")
    (:backend-compatibility-preflight
     "Guarded continuation assumes carrier compatibility was already resolved before the workspace-assignment auth boundary.")
    (:topic-upsert
     "Guarded continuation does not upsert the carrier topic again. It resumes from the preserved topic id after topic upsert.")
    (:workspace-assignment
     "repair_workspace_topic_assignment or continue_workspace_annotation covers only the workspace-assignment stage and keeps it distinct from topicmap placement.")
    (:topicmap-placement
     "upsert_workspace_topicmap_context or continue_workspace_annotation covers only topicmap placement. Topicmap success does not prove workspace ownership.")
    (:journal-transition
     "Guarded shared-workspace executors record their own journal transitions around assignment and topicmap writes without collapsing ownership into visibility.")
    (:reopen-persisted-annotation
     "continue_workspace_annotation reopens the persisted annotation after the guarded stages; the narrower repair/upsert tools stop earlier.")
    (otherwise
     "-")))

(defun workspace-annotation-path-diff-stage-rows (comparison)
  (loop for stage in *dmx-workspace-annotation-path-diff-stage-order*
        collect (list :stage stage
                      :label (workspace-annotation-persistence-stage-label stage)
                      :annotation-persist-path
                      (workspace-annotation-path-diff-raw-behavior
                       comparison
                       stage)
                      :guarded-path
                      (workspace-annotation-path-diff-guarded-behavior
                       comparison
                       stage)
                      :shared-vs-divergent
                      (workspace-annotation-path-diff-comparison-label stage)
                      :auth-expectation
                      (workspace-annotation-path-diff-auth-expectation stage)
                      :executor-or-tool
                      (workspace-annotation-path-diff-executor-name stage)
                      :live-status
                      (workspace-annotation-path-diff-stage-live-status
                       comparison
                       stage))))

(defun make-workspace-annotation-path-diff
    (annotation workspace-topicmap-id &key workspace-id client report
       view-props status supersedes-topic-id annotation-key provenance-json
       storage-mode)
  (let* ((report-plan
           (and (typep report 'workspace-annotation-persistence-report)
                (workspace-annotation-persistence-report-plan-of report)))
         (resolved-client
           (or client
               (and (typep report 'workspace-annotation-persistence-report)
                    (workspace-annotation-persistence-report-client-of report))
               (resolve-dmx-workspace-annotation-client
                :client client
                :dry-run t
                :verbose nil)))
         (destination
           (or (and report-plan
                    (dmx-workspace-annotation-write-plan-destination
                     report-plan))
               (resolve-dmx-workspace-annotation-destination
                annotation
                :workspace-topicmap-id workspace-topicmap-id
                :workspace-id workspace-id
                :client resolved-client)))
         (resolved-topicmap-id
           (or (and (typep report 'workspace-annotation-persistence-report)
                    (workspace-annotation-persistence-report-workspace-topicmap-id-of
                     report))
               (and destination
                    (dmx-workspace-annotation-destination-workspace-topicmap-id
                     destination))
               workspace-topicmap-id))
         (resolved-workspace-id
           (or (and report-plan
                    (dmx-workspace-annotation-write-plan-workspace-id
                     report-plan))
               (and (typep report 'workspace-annotation-persistence-report)
                    (workspace-annotation-persistence-report-workspace-id-of
                     report))
               (and destination
                    (dmx-workspace-annotation-destination-workspace-id
                     destination))
               workspace-id))
         (plan
           (or report-plan
               (plan-dmx-workspace-annotation-write-from-object
                annotation
                :workspace-topicmap-id resolved-topicmap-id
                :workspace-id resolved-workspace-id
                :client resolved-client
                :view-props view-props
                :status status
                :supersedes-topic-id supersedes-topic-id
                :annotation-key annotation-key
                :provenance-json provenance-json
                :storage-mode storage-mode)))
         (continuation-topic-id
           (or (and (typep report 'workspace-annotation-persistence-report)
                    (workspace-annotation-persistence-report-saved-topic-id-of
                     report))
               (and (typep annotation 'workspace-dock-annotation)
                    (workspace-annotation-topic-id-of annotation))
               (and plan
                    (dmx-workspace-annotation-write-plan-existing-topic-id
                     plan))))
         (state-snapshot
           (inspect-workspace-annotation-path-state
            resolved-client
            continuation-topic-id
            resolved-topicmap-id))
         (guarded-assignment-summary nil)
         (guarded-assignment-condition nil)
         (guarded-topicmap-summary nil)
         (guarded-topicmap-condition nil)
         (comparison nil))
    (when (and plan continuation-topic-id resolved-topicmap-id)
      (multiple-value-setq (guarded-assignment-summary
                            guarded-assignment-condition)
        (workspace-annotation-path-diff-guarded-assignment-preview
         plan
         resolved-client
         continuation-topic-id
         resolved-topicmap-id))
      (multiple-value-setq (guarded-topicmap-summary
                            guarded-topicmap-condition)
        (workspace-annotation-path-diff-guarded-topicmap-preview
         plan
         resolved-client
         continuation-topic-id
         resolved-topicmap-id)))
    (setf comparison
          (make-instance 'workspace-annotation-path-diff
                         :annotation annotation
                         :workspace-topicmap-id resolved-topicmap-id
                         :workspace-id resolved-workspace-id
                         :client resolved-client
                         :destination destination
                         :plan plan
                         :raw-report report
                         :continuation-topic-id continuation-topic-id
                         :guarded-assignment-summary guarded-assignment-summary
                         :guarded-assignment-condition guarded-assignment-condition
                         :guarded-topicmap-summary guarded-topicmap-summary
                         :guarded-topicmap-condition guarded-topicmap-condition
                         :state-snapshot state-snapshot))
    (setf (slot-value comparison 'consequences)
          (derive-workspace-annotation-path-consequences comparison))
    comparison))

(defun compare-dock-annotation-with-guarded-workspace-path
    (annotation &key workspace-topicmap-id workspace-id client report
       view-props status supersedes-topic-id annotation-key provenance-json
       storage-mode)
  (make-workspace-annotation-path-diff
   annotation
   workspace-topicmap-id
   :workspace-id workspace-id
   :client client
   :report report
   :view-props view-props
   :status status
   :supersedes-topic-id supersedes-topic-id
   :annotation-key annotation-key
   :provenance-json provenance-json
   :storage-mode storage-mode))

(defun workspace-annotation-path-diff-graph (comparison)
  (let* ((annotation (workspace-annotation-path-diff-annotation-of comparison))
         (plan (workspace-annotation-path-diff-plan-of comparison))
         (topic-id (workspace-annotation-path-diff-continuation-topic-id-of
                    comparison))
         (workspace-topicmap-id
           (workspace-annotation-path-diff-workspace-topicmap-id-of comparison))
         (divergence-consequence
           (workspace-annotation-path-consequence-summary-for-stages
            comparison
            '(:topic-upsert :workspace-assignment)))
         (assignment-consequence
           (workspace-annotation-path-consequence-summary-for-stages
            comparison
            :workspace-assignment))
         (topicmap-consequence
           (workspace-annotation-path-consequence-summary-for-stages
            comparison
            :topicmap-placement))
         (journal-consequence
           (workspace-annotation-path-consequence-summary-for-stages
            comparison
            :journal-transition))
         (result-consequence
           (workspace-annotation-path-consequence-summary-for-stages
            comparison
            :reopen-persisted-annotation)))
    (make-code-path-graph
     :id "workspace-annotation-path-diff"
     :title "Workspace annotation path diff"
     :summary
     (format nil
             "Compares the main annotation persist path with the guarded continuation / MCP path for workspace topicmap ~D. Workspace assignment and topicmap placement stay separate facts, and guarded topicmap success still does not prove workspace ownership."
             workspace-topicmap-id)
     :entrypoints
     (list
      (list :id "persist-entry"
            :label "persist-dock-annotation-to-workspace"
            :summary
            "Typed annotation planning and staging entrypoint for the main persist path.")
      (list :id "guarded-entry"
            :label "continue_workspace_annotation"
            :summary
            "Guarded continuation / MCP entrypoint after topic upsert has already produced or preserved a topic id."))
     :nodes
     (list
      (list :id "annotation"
            :label "Dock annotation"
            :role :runtime-input
            :object annotation
            :summary "Current annotation object under comparison.")
      (list :id "normalize"
            :label (workspace-annotation-persistence-stage-label
                    :normalize-annotation)
            :role :read-helper
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "dmx-workspace-annotation-from-object"
            :summary
            "Typed persist entrypoint normalizes the annotation payload once.")
      (list :id "plan"
            :label (workspace-annotation-persistence-stage-label
                    :build-write-plan)
            :role :read-helper
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "plan-dmx-workspace-annotation-write-from-object"
            :summary
            "Typed persist entrypoint builds the shared write plan.")
      (list :id "validate"
            :label (workspace-annotation-persistence-stage-label
                    :validate-payload)
            :role :diff-engine
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "plan-dmx-workspace-annotation-write"
            :summary
            "Payload and view props are validated before any live mutation.")
      (list :id "backend-compatibility-preflight"
            :label (workspace-annotation-persistence-stage-label
                    :backend-compatibility-preflight)
            :role :write-preflight
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "probe-live-workspace-annotation-type-support"
            :summary
            "Live persist resolves carrier compatibility before create-topic.")
      (list :id "topic-upsert"
            :label (workspace-annotation-persistence-stage-label :topic-upsert)
            :role :write-entry
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "execute-dmx-workspace-annotation-write"
            :summary
            (if topic-id
                (format nil
                        "Topic upsert completed before the guarded boundary and preserved topic ~D."
                        topic-id)
                "Topic upsert creates or updates the carrier topic before the guarded boundary."))
      (list :id "workspace-assignment-auth-boundary"
            :label "workspace-assignment auth boundary"
            :role :write-preflight
            :summary
            (format nil
                    "This is the divergence point: raw persist can stop with pending-auth here, while guarded continuation resumes explicitly from the preserved topic id.~@[ ~A~]"
                    divergence-consequence))
      (list :id "raw-pending-auth-stop"
            :label "raw pending-auth stop"
            :role :runtime-terminal
            :summary
            (format nil
                    "Raw persist preserves the created topic id and report semantics but stops before workspace assignment starts.~@[ ~A~]"
                    divergence-consequence))
      (list :id "guarded-explicit-auth-continuation"
            :label "guarded explicit-auth continuation"
            :role :write-entry
            :summary
            (format nil
                    "Guarded continuation resumes the remaining authenticated stages without redoing topic upsert.~@[ ~A~]"
                    divergence-consequence))
      (list :id "workspace-assignment"
            :label (workspace-annotation-persistence-stage-label
                    :workspace-assignment)
            :role :write-helper
            :source-file "hyperdoc/dmx-workspace-topics.lisp"
            :source-function
            "execute-dmx-workspace-topic-workspace-assignment-repair"
            :summary
            (format nil
                    "Workspace assignment remains distinct from topicmap placement on both paths.~@[ ~A~]"
                    assignment-consequence))
      (list :id "topicmap-placement"
            :label (workspace-annotation-persistence-stage-label
                    :topicmap-placement)
            :role :write-helper
            :source-file "hyperdoc/dmx-workspace-topics.lisp"
            :source-function "execute-dmx-workspace-topicmap-context-upsert"
            :summary
            (format nil
                    "Topicmap placement only affects topicmap context and does not prove workspace ownership.~@[ ~A~]"
                    topicmap-consequence))
      (list :id "journal-transition"
            :label (workspace-annotation-persistence-stage-label
                    :journal-transition)
            :role :write-entry
            :source-file "hyperdoc/dmx-workspace-journal.lisp"
            :source-function "dmx-workspace-journal-record-transition"
            :summary
            (format nil
                    "Journal transitions stay explicit on both paths.~@[ ~A~]"
                    journal-consequence))
      (list :id "reopen"
            :label (workspace-annotation-persistence-stage-label
                    :reopen-persisted-annotation)
            :role :read-entry
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "read-dmx-workspace-annotation"
            :summary
            (format nil
                    "Reopen the persisted topic as a workspace annotation object.~@[ ~A~]"
                    result-consequence))
      (list :id "result"
            :label
            (if topic-id
                (format nil "Workspace annotation ~D" topic-id)
                "Workspace annotation result")
            :role :runtime-value
            :object (and topic-id
                         (typep annotation 'workspace-dock-annotation)
                         annotation)
            :summary
            (if plan
                (format nil
                        "Comparison uses the shared typed write plan for annotation key ~A."
                        (or (dmx-workspace-annotation-write-plan-annotation-key
                             plan)
                            "-"))
                "Comparison reuses the shared typed write-plan vocabulary.")))
     :edges
     (list
      (list :from "annotation"
            :to "normalize"
            :kind :read
            :status (workspace-annotation-path-diff-raw-stage-status
                     comparison
                     :normalize-annotation)
            :summary "Typed normalization.")
      (list :from "normalize"
            :to "plan"
            :kind :read
            :status (workspace-annotation-path-diff-raw-stage-status
                     comparison
                     :build-write-plan)
            :summary "Typed write-plan construction.")
      (list :from "plan"
            :to "validate"
            :kind :read-diff
            :status (workspace-annotation-path-diff-raw-stage-status
                     comparison
                     :validate-payload)
            :summary "Payload and view-props validation.")
      (list :from "validate"
            :to "backend-compatibility-preflight"
            :kind :write-preflight
            :status (workspace-annotation-path-diff-raw-stage-status
                     comparison
                     :backend-compatibility-preflight)
            :summary "Carrier compatibility preflight.")
      (list :from "backend-compatibility-preflight"
            :to "topic-upsert"
            :kind :write
            :status (workspace-annotation-path-diff-raw-stage-status
                     comparison
                     :topic-upsert)
            :write-capable-p t
            :summary "Carrier topic upsert before the guarded boundary.")
      (list :from "topic-upsert"
            :to "workspace-assignment-auth-boundary"
            :kind :write-preflight
            :status :active
            :summary
            (format nil
                    "Created topic reaches the workspace-assignment auth boundary.~@[ ~A~]"
                    divergence-consequence))
      (list :from "workspace-assignment-auth-boundary"
            :to "raw-pending-auth-stop"
            :kind :write
            :status (if (and (typep (workspace-annotation-path-diff-raw-report-of
                                     comparison)
                                    'workspace-annotation-persistence-report)
                             (workspace-annotation-pending-auth-p
                              (workspace-annotation-path-diff-raw-report-of
                               comparison)))
                        :error
                        :suppressed)
            :write-capable-p t
            :summary
            (format nil
                    "Raw pending-auth stop preserves the topic id and report instead of silently continuing.~@[ ~A~]"
                    divergence-consequence))
      (list :from "workspace-assignment-auth-boundary"
            :to "workspace-assignment"
            :kind :write
            :status (workspace-annotation-path-diff-raw-stage-status
                     comparison
                     :workspace-assignment)
            :write-capable-p t
            :summary "Raw persist continues directly into workspace assignment when auth is already available.")
      (list :from "workspace-assignment-auth-boundary"
            :to "guarded-explicit-auth-continuation"
            :kind :write
            :status (if topic-id :active :pending)
            :write-capable-p t
            :summary
            (format nil
                    "Guarded continuation resumes from the preserved topic id with explicit auth and shared-workspace executors.~@[ ~A~]"
                    divergence-consequence))
      (list :from "guarded-explicit-auth-continuation"
            :to "workspace-assignment"
            :kind :write
            :status (workspace-annotation-path-diff-guarded-stage-status
                     comparison
                     :workspace-assignment)
            :write-capable-p t
            :summary
            (format nil
                    "repair_workspace_topic_assignment / continue_workspace_annotation cover only workspace assignment.~@[ ~A~]"
                    assignment-consequence))
      (list :from "workspace-assignment"
            :to "topicmap-placement"
            :kind :write
            :status (workspace-annotation-path-diff-stage-status
                     comparison
                     :topicmap-placement)
            :write-capable-p t
            :summary
            (format nil
                    "Topicmap placement stays separate from workspace ownership on both paths.~@[ ~A~]"
                    topicmap-consequence))
      (list :from "topicmap-placement"
            :to "journal-transition"
            :kind :write
            :status (workspace-annotation-path-diff-stage-status
                     comparison
                     :journal-transition)
            :write-capable-p t
            :summary
            (format nil
                    "Guarded executors emit journal transitions without collapsing ownership into topicmap visibility.~@[ ~A~]"
                    journal-consequence))
      (list :from "journal-transition"
            :to "reopen"
            :kind :read
            :status (workspace-annotation-path-diff-stage-status
                     comparison
                     :reopen-persisted-annotation)
            :summary
            (format nil
                    "Reopen after the remaining guarded stages.~@[ ~A~]"
                    result-consequence))
      (list :from "reopen"
            :to "result"
            :kind :result
            :status :pending
            :summary "Yield the reopened workspace annotation object."))
     :focus-paths
     (list
      (list :id "main-annotation-persist-path"
            :label "Main annotation persist path"
            :summary
            "Typed annotation planning and staging through topic upsert and the direct raw post-upsert path."
            :node-ids
            '("annotation"
              "normalize"
              "plan"
              "validate"
              "backend-compatibility-preflight"
              "topic-upsert"
              "workspace-assignment-auth-boundary"
              "workspace-assignment"
              "topicmap-placement"
              "journal-transition"
              "reopen"
              "result"))
      (list :id "guarded-continuation-path"
            :label "Guarded continuation path"
            :summary
            "Continuation from the preserved topic id through guarded assignment, topicmap placement, journal, and reopen."
            :node-ids
            '("workspace-assignment-auth-boundary"
              "guarded-explicit-auth-continuation"
              "workspace-assignment"
              "topicmap-placement"
              "journal-transition"
              "reopen"
              "result"))
      (list :id "raw-pending-auth-stop-path"
            :label "Raw pending-auth stop"
            :summary
            "Contrast path that stops at the auth boundary while preserving the created topic id."
            :node-ids
            '("annotation"
              "normalize"
              "plan"
              "validate"
              "backend-compatibility-preflight"
              "topic-upsert"
              "workspace-assignment-auth-boundary"
              "raw-pending-auth-stop"))))))

(defun continue-workspace-annotation-persistence-with-explicit-auth
    (report &key client auth-mode username password authorization-header
       auth-token)
  (handler-case
      (continue-workspace-annotation-persistence-with-client
       report
       (or client
           (make-explicit-workspace-annotation-continuation-client
            report
            :auth-mode auth-mode
            :username username
            :password password
            :authorization-header authorization-header
            :auth-token auth-token)))
    (error (condition)
      (make-workspace-annotation-persistence-report-like
       report
       :condition condition
       :report-status :pending-auth
       :failure-stage
       (workspace-annotation-persistence-report-failure-stage-of report)
       :assignment-auth-context
       (append (or (workspace-annotation-persistence-report-assignment-auth-context-of
                    report)
                   '())
               (list :explicit-auth-condition (format nil "~A" condition)))))))

(defun continue-workspace-annotation-journal-preflight-with-client
    (report client)
  (unless (workspace-annotation-journal-preflight-auth-blocked-p report)
    (error 'fedwiki-dmx-import-error
           :message "Workspace annotation journal continuation requires a journal-preflight auth-blocked report"))
  (let* ((plan (workspace-annotation-persistence-report-plan-of report))
         (annotation (workspace-annotation-persistence-report-annotation-of
                      report)))
    (run-dock-annotation-workspace-persistence-debug
     annotation
     :workspace-topicmap-id
     (workspace-annotation-persistence-report-workspace-topicmap-id-of report)
     :workspace-id
     (or (and plan
              (dmx-workspace-annotation-write-plan-workspace-id plan))
         (workspace-annotation-persistence-report-workspace-id-of report))
     :client client
     :view-props
     (and plan
          (dmx-workspace-annotation-write-plan-view-props plan))
     :status
     (and plan
          (dmx-workspace-annotation-write-plan-status plan))
     :supersedes-topic-id
     (and plan
          (dmx-workspace-annotation-write-plan-supersedes-topic-id plan))
     :annotation-key
     (workspace-annotation-persistence-report-annotation-key-of report)
     :provenance-json
     (and plan
          (dmx-workspace-annotation-write-plan-provenance-json plan))
     :storage-mode
     (and plan
          (dmx-workspace-annotation-write-plan-storage-mode plan)))))

(defun continue-workspace-annotation-journal-preflight-with-explicit-auth
    (report &key client auth-mode username password authorization-header
       auth-token)
  (let ((attempt-client nil)
        (retry-executed-at (get-universal-time))
        (retry-request-id
          (workspace-annotation-explicit-auth-retry-request-id)))
    (labels ((requested-auth-mode ()
             (or (workspace-annotation-explicit-auth-mode-or-nil auth-mode)
                 (workspace-annotation-explicit-auth-client-mode
                  attempt-client)))
           (retry-marker-overrides ()
             (list :explicit-auth-retry-invoked-p t
                   :explicit-auth-retry-request-id retry-request-id
                   :explicit-auth-retry-executed-at retry-executed-at
                   :explicit-auth-retry-executed-at-label
                   (workspace-annotation-format-explicit-auth-retry-time
                    retry-executed-at)
                   :explicit-auth-retry-mode (requested-auth-mode)
                   :explicit-auth-retry-mode-label
                   (and (requested-auth-mode)
                        (workspace-annotation-auth-mode-label
                         (requested-auth-mode)))
                   :explicit-auth-retry-source
                   :journal-preflight-explicit-auth
                   :explicit-auth-retry-source-label
                   (workspace-annotation-explicit-auth-retry-source-label
                    :journal-preflight-explicit-auth)
                   :explicit-auth-retry-evidence-version
                   *workspace-annotation-explicit-auth-retry-evidence-version*))
           (attempt-context (failure &key local-failure-stage)
             (workspace-annotation-explicit-auth-attempt-context
              report
              attempt-client
              failure
              :auth-mode auth-mode
              :username username
              :password password
              :authorization-header authorization-header
              :auth-token auth-token
              :local-failure-stage local-failure-stage
              :continuation-request-id retry-request-id
              :continuation-executed-at retry-executed-at
              :continuation-source :journal-preflight-explicit-auth))
           (decorate-report (result &key failure include-attempt-context-p)
             (if (typep result 'workspace-annotation-persistence-report)
                 (apply #'make-workspace-annotation-persistence-report-like
                        result
                        (append
                         (list :journal-preflight-auth-context
                               (workspace-annotation-persistence-report-journal-preflight-auth-context-of
                                report))
                         (when include-attempt-context-p
                           (list :explicit-auth-attempt-context
                                 (attempt-context failure)))
                         (retry-marker-overrides)))
                 result)))
      (handler-case
          (setf attempt-client
                (or client
                    (make-explicit-workspace-annotation-continuation-client
                     report
                     :auth-mode auth-mode
                     :username username
                     :password password
                     :authorization-header authorization-header
                     :auth-token auth-token)))
        (error (failure)
          (return-from continue-workspace-annotation-journal-preflight-with-explicit-auth
            (apply #'make-workspace-annotation-persistence-report-like
                   report
                   (append
                    (list :condition failure
                          :report-status
                          (workspace-annotation-persistence-report-status-of report)
                          :failure-stage
                          (workspace-annotation-persistence-report-failure-stage-of
                           report)
                          :explicit-auth-attempt-context
                          (attempt-context
                           failure
                           :local-failure-stage :build-explicit-auth-client))
                    (retry-marker-overrides))))))
      (reset-http-dmx-import-debug-evidence attempt-client)
      (handler-case
          (let ((continued
                  (progn
                    (ensure-http-dmx-import-authenticated-operation
                     attempt-client
                     :journal-preflight-continuation)
                    (continue-workspace-annotation-journal-preflight-with-client
                     report
                     attempt-client))))
            (decorate-report
             continued
             :failure
             (and (typep continued 'workspace-annotation-persistence-report)
                  (workspace-annotation-persistence-report-condition-of
                   continued))
             :include-attempt-context-p
             (and (typep continued 'workspace-annotation-persistence-report)
                  (not (eq (workspace-annotation-persistence-report-status-of
                            continued)
                           :persisted)))))
        (error (failure)
          (decorate-report
           (make-workspace-annotation-persistence-report-like
            report
            :client attempt-client
            :condition failure
           :report-status
            (workspace-annotation-persistence-report-status-of report)
           :failure-stage
            (workspace-annotation-persistence-report-failure-stage-of report))
           :failure failure
           :include-attempt-context-p t))))))

(defun probe-live-create-topic-for-dock-annotation
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       (storage-mode *dmx-workspace-annotation-native-storage-mode*))
  (let* ((annotation (workspace-annotation-replay-subject annotation))
         (resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run nil
            :verbose nil))
         (resolved-destination
           (resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client resolved-client))
         (resolved-topicmap-id
           (dmx-workspace-annotation-destination-workspace-topicmap-id
            resolved-destination))
         (preview
           (workspace-annotation-persistence-preview
            annotation
            resolved-topicmap-id
            :workspace-id
            (dmx-workspace-annotation-destination-workspace-id
             resolved-destination)
            :client resolved-client
            :view-props view-props
            :status status
            :supersedes-topic-id supersedes-topic-id
            :annotation-key annotation-key
            :provenance-json provenance-json
            :storage-mode storage-mode))
         (normalized
           (dmx-workspace-annotation-from-object
            annotation
            resolved-topicmap-id
            :status status
           :supersedes-topic-id supersedes-topic-id
           :annotation-key annotation-key
           :provenance-json provenance-json))
         (plan
           (apply #'plan-dmx-workspace-annotation-write
                  (append normalized
                          (list :workspace-id
                                (dmx-workspace-annotation-destination-workspace-id
                                 resolved-destination)
                                :workspace-topicmap-id
                                resolved-topicmap-id
                                :client resolved-client
                                :view-props view-props
                                :storage-mode storage-mode
                                :destination resolved-destination))))
         (payload-json
           (workspace-annotation-write-plan-payload-json-string plan))
         (exact-form
           (workspace-annotation-create-topic-probe-form
            resolved-topicmap-id
            :workspace-id
            (dmx-workspace-annotation-destination-workspace-id
             resolved-destination)
            :storage-mode storage-mode)))
    (cond
      ((not (eq (dmx-workspace-annotation-write-plan-topic-action plan) :create))
       (make-instance
        'workspace-annotation-create-topic-probe-report
        :annotation annotation
        :workspace-topicmap-id resolved-topicmap-id
        :client resolved-client
        :exact-form exact-form
        :dry-run-preview preview
        :plan plan
        :payload-json payload-json
        :report-status :not-create))
      (t
       (handler-case
           (let* ((topic
                    (dmx-import-create-topic
                     resolved-client
                     (dmx-workspace-annotation-write-plan-payload plan)))
                  (topic-id (dmx-import-object-id topic)))
             (make-instance
              'workspace-annotation-create-topic-probe-report
              :annotation annotation
              :workspace-topicmap-id resolved-topicmap-id
              :client resolved-client
              :exact-form exact-form
              :dry-run-preview preview
              :plan plan
              :payload-json payload-json
              :report-status :created
              :http-evidence
              (and (typep resolved-client 'http-dmx-import-client)
                   (dmx-import-last-http-transaction-evidence-of
                    resolved-client))
              :created-topic-id topic-id
              :created-topic topic))
         (error (condition)
           (make-instance
            'workspace-annotation-create-topic-probe-report
            :annotation annotation
            :workspace-topicmap-id resolved-topicmap-id
            :client resolved-client
            :exact-form exact-form
            :dry-run-preview preview
            :plan plan
            :payload-json payload-json
            :report-status :failed
            :condition condition
            :http-evidence
            (or (dmx-import-http-evidence condition)
                (and (typep resolved-client 'http-dmx-import-client)
                     (dmx-import-last-http-transaction-evidence-of
                      resolved-client))))))))))

(defun workspace-annotation-persistence-debug-graph (debug)
  (workspace-annotation-persistence-code-path-graph
   (workspace-annotation-persistence-debug-annotation-of debug)
   (workspace-annotation-persistence-debug-workspace-topicmap-id-of debug)
   :annotation-key
   (workspace-annotation-persistence-debug-annotation-key-of debug)
   :runtime-relation-id
   (workspace-annotation-persistence-debug-runtime-relation-id-of debug)
   :report (workspace-annotation-persistence-debug-last-report-of debug)))

(defun workspace-annotation-persistence-report-graph (report)
  (workspace-annotation-persistence-code-path-graph
   (workspace-annotation-persistence-report-annotation-of report)
   (workspace-annotation-persistence-report-workspace-topicmap-id-of report)
   :annotation-key
   (workspace-annotation-persistence-report-annotation-key-of report)
   :runtime-relation-id
   (workspace-annotation-persistence-report-runtime-relation-id-of report)
   :report report))

(defun dmx-workspace-annotation-child-json (topic child-type-uri)
  (let ((json-string (dmx-json-child-value topic child-type-uri)))
    (and (dmx-non-empty-string-p json-string)
         (with-input-from-string (stream json-string)
           (shasht:read-json stream)))))

(defun dmx-workspace-annotation-binding-topic-id (binding)
  (let* ((player (and binding (gethash "player2" binding)))
         (ref-kind (and player (gethash "refKind" player)))
         (ref-value (and player (gethash "refValue" player))))
    (when (and (string= (or ref-kind "") "topic-id")
               ref-value)
      (or (parse-positive-integer ref-value)
          (and (integerp ref-value) ref-value)))))

(defun dmx-workspace-annotation-target-object (target-object-ref)
  (let ((annotation-topic (annotation-topic)))
    (if (string= (or target-object-ref "")
                 (dmx-workspace-annotation-ref-string annotation-topic))
        annotation-topic
        target-object-ref)))

(defun dmx-workspace-annotation-native-topic-json-from-envelope
    (carrier-topic envelope)
  (let* ((native-payload (and envelope (gethash "nativePayload" envelope)))
         (children (and (hash-table-p native-payload)
                        (gethash "children" native-payload))))
    (unless (and (hash-table-p native-payload)
                 (hash-table-p children))
      (error 'fedwiki-dmx-import-error
             :message "Workspace annotation compatibility carrier is missing nativePayload.children"))
    (let ((topic (make-hash-table :test #'equal)))
      (setf (gethash "id" topic) (dmx-import-object-id carrier-topic)
            (gethash "uri" topic)
            (or (dmx-json-object-value carrier-topic "uri")
                (gethash "uri" native-payload)
                "")
            (gethash "typeUri" topic) *dmx-workspace-annotation-type-uri*
            (gethash "value" topic)
            (or (gethash "value" native-payload)
                (dmx-json-child-value carrier-topic *dmx-notes-title-type-uri*)
                "Workspace annotation")
            (gethash "children" topic) children)
      topic)))

(defun dmx-workspace-annotation-reopen-source
    (topic resolved-topic-id)
  (let ((storage-mode (dmx-workspace-annotation-topic-storage-mode topic)))
    (case storage-mode
      (:native-annotation
       (values topic
               storage-mode
               nil))
      (:compatibility-note-carrier
       (let ((envelope
               (dmx-workspace-annotation-compatibility-envelope-from-topic
                topic)))
         (values (dmx-workspace-annotation-native-topic-json-from-envelope
                  topic
                  envelope)
                 storage-mode
                 envelope)))
      (otherwise
       (error 'fedwiki-dmx-import-error
              :message (format nil
                               "DMX annotation reopen requires ~A or compatibility carrier ~A but topic ~D is ~A"
                               *dmx-workspace-annotation-type-uri*
                               *dmx-workspace-annotation-compatibility-carrier-type-uri*
                               resolved-topic-id
                               (dmx-json-object-value topic "typeUri")))))))

(defun read-dmx-workspace-annotation
    (&key topic-id client workspace-topicmap-id)
  (let* ((resolved-topic-id
           (dmx-workspace-annotation-topic-id
            topic-id
            :topic-id
            'read-dmx-workspace-annotation
            :required? t))
         (resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run t
            :verbose nil))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (topic (dmx-import-read-topic resolved-client resolved-topic-id)))
    (unless topic
      (error 'fedwiki-dmx-import-error
             :message (format nil "Unknown DMX annotation topic ~D"
                              resolved-topic-id)))
    (multiple-value-bind (annotation-topic storage-mode envelope)
        (dmx-workspace-annotation-reopen-source topic resolved-topic-id)
      (declare (ignore envelope))
      (let* ((source-anchor-json
             (dmx-json-child-value annotation-topic
                                   *dmx-workspace-annotation-source-anchor-json-type-uri*))
           (target-anchor-json
             (dmx-json-child-value annotation-topic
                                   *dmx-workspace-annotation-target-anchor-json-type-uri*))
           (source-anchor
             (make-dom-annotation-anchor-from-json
              (or (parse-dom-annotation-json source-anchor-json)
                  (error "Missing source anchor JSON for annotation topic ~D"
                         resolved-topic-id))))
           (target-anchor
             (make-dom-annotation-anchor-from-json
              (or (parse-dom-annotation-json target-anchor-json)
                  (error "Missing target anchor JSON for annotation topic ~D"
                         resolved-topic-id))))
           (workspace
             (dmx-import-read-topic-workspace resolved-client resolved-topic-id))
           (source-binding
             (dmx-workspace-annotation-child-json
              annotation-topic
              *dmx-workspace-annotation-source-binding-type-uri*))
           (target-binding
             (dmx-workspace-annotation-child-json
              annotation-topic
              *dmx-workspace-annotation-target-binding-type-uri*))
           (context-binding
             (dmx-workspace-annotation-child-json
              annotation-topic
              *dmx-workspace-annotation-context-binding-type-uri*))
           (supersedes-binding
             (dmx-workspace-annotation-child-json
              annotation-topic
              *dmx-workspace-annotation-supersedes-type-uri*))
           (source-object-ref
             (dmx-json-child-value annotation-topic
                                   *dmx-workspace-annotation-source-object-ref-type-uri*))
           (target-object-ref
             (dmx-json-child-value annotation-topic
                                   *dmx-workspace-annotation-target-object-ref-type-uri*))
           (runtime-relation-id
             (dmx-json-child-value annotation-topic
                                   *dmx-workspace-annotation-runtime-relation-id-type-uri*)))
      (make-instance
       'workspace-dock-annotation
       :id (format nil "workspace-annotation/~D" resolved-topic-id)
       :title (dmx-workspace-annotation-topic-title annotation-topic)
       :summary (or (dmx-json-child-value annotation-topic
                                          *dmx-workspace-annotation-summary-type-uri*)
                    (dmx-json-object-value annotation-topic "value"))
       :context-object
       (dmx-json-child-value annotation-topic
                             *dmx-workspace-annotation-context-object-id-type-uri*)
       :context-view-title
       (dmx-json-child-value annotation-topic
                             *dmx-workspace-annotation-context-view-title-type-uri*)
       :source-anchor source-anchor
       :target-anchor target-anchor
       :source-object source-object-ref
       :target-object (dmx-workspace-annotation-target-object target-object-ref)
       :relation-kind (dmx-json-child-value annotation-topic
                                            *dmx-workspace-annotation-relation-kind-type-uri*)
       :note (dmx-json-child-value annotation-topic
                                   *dmx-workspace-annotation-text-type-uri*)
       :matching-patch-target nil
       :matching-defect nil
       :matching-inserted-step nil
       :registry-key runtime-relation-id
       :dock-capability "Annotation"
       :workspace-topic-id resolved-topic-id
       :workspace-topic-uri (or (dmx-json-object-value topic "uri") "")
       :workspace-topicmap-id resolved-topicmap-id
       :workspace-id (dmx-import-object-id workspace)
       :storage-mode storage-mode
       :carrier-type-uri
       (dmx-workspace-annotation-storage-mode-carrier-type-uri storage-mode)
       :annotation-key
       (let ((uri (or (dmx-json-object-value topic "uri") "")))
         (if (dmx-string-prefix-p *hyperdoc-workspace-annotation-uri-prefix* uri)
             (subseq uri (length *hyperdoc-workspace-annotation-uri-prefix*))
             nil))
       :workspace-status
       (dmx-json-child-value annotation-topic
                             *dmx-workspace-annotation-status-type-uri*)
       :source-anchor-json source-anchor-json
       :target-anchor-json target-anchor-json
       :source-object-ref source-object-ref
       :target-object-ref target-object-ref
       :runtime-relation-id runtime-relation-id
       :provenance-json
       (dmx-json-child-value annotation-topic
                             *dmx-workspace-annotation-provenance-type-uri*)
       :source-binding source-binding
       :target-binding target-binding
       :context-binding context-binding
       :supersedes-binding supersedes-binding
       :supersedes-topic-id
       (dmx-workspace-annotation-binding-topic-id supersedes-binding))))))

(defun workspace-annotation-local-projection-topic-id (result)
  (cond
    ((typep result 'workspace-dock-annotation)
     (workspace-annotation-topic-id-or-nil result))
    ((typep result 'workspace-annotation-persistence-report)
     (workspace-annotation-persistence-report-saved-topic-id-of result))
    (t
     nil)))

(defun workspace-annotation-local-projection-workspace-id
    (result fallback-workspace-id)
  (cond
    ((typep result 'workspace-dock-annotation)
     (workspace-annotation-workspace-id-of result))
    ((typep result 'workspace-annotation-persistence-report)
     (let ((failure-stage
             (workspace-annotation-persistence-report-failure-stage-of result)))
       (if (eq failure-stage :topicmap-placement)
           fallback-workspace-id
           nil)))
    (t
     nil)))

(defun workspace-annotation-local-projection-in-topicmap-p (result)
  (cond
    ((typep result 'workspace-dock-annotation)
     t)
    ((typep result 'workspace-annotation-persistence-report)
     (eq (workspace-annotation-persistence-report-status-of result)
         :persisted))
    (t
     nil)))

(defun persist-dock-annotation-local-first
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       storage-mode
       (materialize-to-dmx-p nil))
  (let* ((annotation (workspace-annotation-replay-subject annotation))
         (planning-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run t
            :verbose nil))
         (destination
           (resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client planning-client))
         (resolved-topicmap-id
           (dmx-workspace-annotation-destination-workspace-topicmap-id
            destination))
         (resolved-workspace-id
           (dmx-workspace-annotation-destination-workspace-id destination))
         (native-payload
           (dmx-workspace-annotation-local-native-payload-from-object
            annotation
            resolved-topicmap-id
            :status status
            :supersedes-topic-id supersedes-topic-id
            :annotation-key annotation-key
            :provenance-json provenance-json))
         (subject-key
           (or (getf native-payload :uri)
               (error 'fedwiki-dmx-import-error
                      :message
                      "Workspace annotation local-first persistence requires a stable URI subject key")))
         (local-payload
           (workspace-annotation-local-payload-with-status
            native-payload
            *hyperdoc-local-workspace-annotation-status-local-only*))
         (local-state
           (workspace-annotation-local-next-state-from-payload
            subject-key
            resolved-topicmap-id
            local-payload)))
    (workspace-annotation-local-apply-transition
     subject-key
     resolved-topicmap-id
     local-state)
    (let ((local-annotation
            (read-hyperdoc-local-workspace-annotation
             :subject-key subject-key)))
      (unless materialize-to-dmx-p
        (return-from persist-dock-annotation-local-first local-annotation))
      (let* ((live-client
               (resolve-dmx-workspace-annotation-client
                :client client
                :dry-run nil
                :verbose nil))
             (projection-result
               (persist-dock-annotation-to-workspace
                local-annotation
                :workspace-topicmap-id resolved-topicmap-id
                :workspace-id resolved-workspace-id
                :client live-client
                :view-props view-props
                :status status
                :supersedes-topic-id supersedes-topic-id
                :annotation-key annotation-key
                :provenance-json provenance-json
                :storage-mode storage-mode
                :dry-run nil))
             (saved-topic-id
               (workspace-annotation-local-projection-topic-id
                projection-result))
             (saved-workspace-id
               (workspace-annotation-local-projection-workspace-id
                projection-result
                resolved-workspace-id))
             (projected-in-topicmap-p
               (workspace-annotation-local-projection-in-topicmap-p
                projection-result))
             (projection-status
               (cond
                 ((typep projection-result 'workspace-dock-annotation)
                  *hyperdoc-local-workspace-annotation-status-projected*)
                 ((typep projection-result 'workspace-annotation-persistence-report)
                  (workspace-annotation-local-projection-status-from-report
                   projection-result
                   saved-topic-id))
                 (t
                  *hyperdoc-local-workspace-annotation-status-projection-failed*)))
             (projected-payload
               (workspace-annotation-local-payload-with-status
                native-payload
                projection-status))
             (projected-state
               (workspace-annotation-local-next-state-from-payload
                subject-key
                resolved-topicmap-id
                projected-payload
                :topic-id saved-topic-id
                :workspace-id saved-workspace-id
                :in-topicmap projected-in-topicmap-p
                :view-props
                (and projected-in-topicmap-p view-props))))
        (workspace-annotation-local-apply-transition
         subject-key
         resolved-topicmap-id
         projected-state)
        projection-result))))

(defun persist-dock-annotation-to-workspace
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       storage-mode
       (dry-run t))
  (let* ((annotation (workspace-annotation-replay-subject annotation))
         (resolved-client
           (resolve-dmx-workspace-annotation-client
            :client client
            :dry-run dry-run
            :verbose nil))
         (compatibility-report
           (and (not dry-run)
                (workspace-annotation-live-compatibility-preflight-required-p
                 resolved-client)
                (probe-live-workspace-annotation-type-support
                 annotation
                 :workspace-topicmap-id workspace-topicmap-id
                 :workspace-id workspace-id
                 :client resolved-client
                 :view-props view-props
                 :status status
                 :supersedes-topic-id supersedes-topic-id
                 :annotation-key annotation-key
                 :provenance-json provenance-json
                 :storage-mode storage-mode))))
    (when (and compatibility-report
               (workspace-annotation-backend-compatibility-blocked-p
                compatibility-report))
      (return-from persist-dock-annotation-to-workspace
        compatibility-report))
    (if dry-run
        (execute-dmx-workspace-annotation-write-from-object
         annotation
         :workspace-topicmap-id workspace-topicmap-id
         :workspace-id workspace-id
         :client resolved-client
         :view-props view-props
         :status status
         :supersedes-topic-id supersedes-topic-id
         :annotation-key annotation-key
         :provenance-json provenance-json
         :storage-mode storage-mode
         :dry-run t)
        (let ((report
                (run-dock-annotation-workspace-persistence-debug
                 annotation
                 :workspace-topicmap-id workspace-topicmap-id
                 :workspace-id workspace-id
                 :client resolved-client
                 :view-props view-props
                 :status status
                 :supersedes-topic-id supersedes-topic-id
                 :annotation-key annotation-key
                 :provenance-json provenance-json
                 :storage-mode storage-mode)))
          (if (eq (workspace-annotation-persistence-report-status-of report)
                  :persisted)
              (or (workspace-annotation-persistence-report-persisted-annotation-of
                   report)
                  report)
              report)))))

(defun supersede-dock-annotation-in-workspace
    (annotation supersedes-topic-id
     &key workspace-topicmap-id workspace-id client view-props
       status annotation-key provenance-json (dry-run t))
  (persist-dock-annotation-to-workspace
   annotation
   :workspace-topicmap-id workspace-topicmap-id
   :workspace-id workspace-id
   :client client
   :view-props view-props
   :status (or status "superseding")
   :supersedes-topic-id supersedes-topic-id
   :annotation-key annotation-key
   :provenance-json provenance-json
   :dry-run dry-run))
