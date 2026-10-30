;;;; Required DMX MCP runtime definitions, extracted from f512aa847eab05cc2bdf2e78ef0bd1b516a11926.
;;;; See docs/dmx-mcp-source-manifest.json and LICENSE.
(in-package :hyperdoc)

;; From hyperdoc/dmx-annotations.lisp, characters 247..323.
(defparameter *dmx-workspace-annotation-type-uri*
  "hyperdoc.annotation")

;; From hyperdoc/dmx-annotations.lisp, characters 323..406.
(defparameter *dmx-workspace-annotation-native-storage-mode*
  :native-annotation)

;; From hyperdoc/dmx-annotations.lisp, characters 406..505.
(defparameter *dmx-workspace-annotation-compatibility-storage-mode*
  :compatibility-note-carrier)

;; From hyperdoc/dmx-annotations.lisp, characters 505..610.
(defparameter *dmx-workspace-annotation-compatibility-storage-mode-name*
  "compatibility-note-carrier")

;; From hyperdoc/dmx-annotations.lisp, characters 610..687.
(defparameter *dmx-workspace-annotation-compatibility-envelope-version*
  1)

;; From hyperdoc/dmx-annotations.lisp, characters 766..867.
(defparameter *dmx-workspace-annotation-compatibility-carrier-type-uri*
  *dmx-notes-note-type-uri*)

;; From hyperdoc/dmx-annotations.lisp, characters 867..954.
(defparameter *dmx-workspace-annotation-title-type-uri*
  "hyperdoc.annotation.title")

;; From hyperdoc/dmx-annotations.lisp, characters 954..1045.
(defparameter *dmx-workspace-annotation-summary-type-uri*
  "hyperdoc.annotation.summary")

;; From hyperdoc/dmx-annotations.lisp, characters 1045..1130.
(defparameter *dmx-workspace-annotation-text-type-uri*
  "hyperdoc.annotation.text")

;; From hyperdoc/dmx-annotations.lisp, characters 1130..1233.
(defparameter *dmx-workspace-annotation-relation-kind-type-uri*
  "hyperdoc.annotation.relation_kind")

;; From hyperdoc/dmx-annotations.lisp, characters 1233..1322.
(defparameter *dmx-workspace-annotation-status-type-uri*
  "hyperdoc.annotation.status")

;; From hyperdoc/dmx-annotations.lisp, characters 1322..1435.
(defparameter *dmx-workspace-annotation-source-anchor-json-type-uri*
  "hyperdoc.annotation.source_anchor_json")

;; From hyperdoc/dmx-annotations.lisp, characters 1435..1548.
(defparameter *dmx-workspace-annotation-target-anchor-json-type-uri*
  "hyperdoc.annotation.target_anchor_json")

;; From hyperdoc/dmx-annotations.lisp, characters 1548..1659.
(defparameter *dmx-workspace-annotation-context-object-id-type-uri*
  "hyperdoc.annotation.context_object_id")

;; From hyperdoc/dmx-annotations.lisp, characters 1659..1772.
(defparameter *dmx-workspace-annotation-context-view-title-type-uri*
  "hyperdoc.annotation.context_view_title")

;; From hyperdoc/dmx-annotations.lisp, characters 1772..1883.
(defparameter *dmx-workspace-annotation-source-object-ref-type-uri*
  "hyperdoc.annotation.source_object_ref")

;; From hyperdoc/dmx-annotations.lisp, characters 1883..1994.
(defparameter *dmx-workspace-annotation-target-object-ref-type-uri*
  "hyperdoc.annotation.target_object_ref")

;; From hyperdoc/dmx-annotations.lisp, characters 1994..2109.
(defparameter *dmx-workspace-annotation-runtime-relation-id-type-uri*
  "hyperdoc.annotation.runtime_relation_id")

;; From hyperdoc/dmx-annotations.lisp, characters 2109..2211.
(defparameter *dmx-workspace-annotation-provenance-type-uri*
  "hyperdoc.annotation.provenance_json")

;; From hyperdoc/dmx-annotations.lisp, characters 2211..2327.
(defparameter *dmx-workspace-annotation-workspace-topicmap-type-uri*
  "hyperdoc.annotation.workspace_topicmap_id")

;; From hyperdoc/dmx-annotations.lisp, characters 2327..2432.
(defparameter *dmx-workspace-annotation-source-binding-type-uri*
  "hyperdoc.annotation.source_binding")

;; From hyperdoc/dmx-annotations.lisp, characters 2432..2537.
(defparameter *dmx-workspace-annotation-target-binding-type-uri*
  "hyperdoc.annotation.target_binding")

;; From hyperdoc/dmx-annotations.lisp, characters 2537..2644.
(defparameter *dmx-workspace-annotation-context-binding-type-uri*
  "hyperdoc.annotation.context_binding")

;; From hyperdoc/dmx-annotations.lisp, characters 2644..2741.
(defparameter *dmx-workspace-annotation-supersedes-type-uri*
  "hyperdoc.annotation.supersedes")

;; From hyperdoc/dmx-annotations.lisp, characters 2741..3865.
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

;; From hyperdoc/dmx-annotations.lisp, characters 3865..4049.
(defparameter *dmx-workspace-annotation-compatibility-required-live-type-uris*
  (list *dmx-notes-note-type-uri*
        *dmx-notes-title-type-uri*
        *dmx-notes-text-type-uri*))

;; From hyperdoc/dmx-annotations.lisp, characters 4049..4305.
(defparameter *dmx-workspace-annotation-known-live-create-topic-response-body*
  "{\"error\":\"Creating topic of type \\\"hyperdoc.annotation\\\" failed\",\"cause\":\"java.lang.RuntimeException: Topic type \\\"hyperdoc.annotation\\\" not found in DB\"}")

;; From hyperdoc/dmx-annotations.lisp, characters 4305..4452.
(defstruct dmx-workspace-annotation-destination
  workspace-id
  workspace-topicmap-id
  source
  workspace-source
  topicmap-source
  rationale)

;; From hyperdoc/dmx-annotations.lisp, characters 4452..4739.
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

;; From hyperdoc/dmx-annotations.lisp, characters 4739..5335.
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

;; From hyperdoc/dmx-annotations.lisp, characters 6113..8413.
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

;; From hyperdoc/dmx-annotations.lisp, characters 8413..13812.
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

;; From hyperdoc/dmx-annotations.lisp, characters 24501..26051.
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

;; From hyperdoc/dmx-annotations.lisp, characters 26051..29047.
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

;; From hyperdoc/dmx-annotations.lisp, characters 29047..31476.
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

;; From hyperdoc/dmx-annotations.lisp, characters 32298..32868.
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

;; From hyperdoc/dmx-annotations.lisp, characters 32968..33058.
(defun workspace-dock-annotation-p (object)
  (typep object 'workspace-dock-annotation))

;; From hyperdoc/dmx-annotations.lisp, characters 47310..47593.
(defun workspace-annotation-storage-mode-label (storage-mode)
  (case storage-mode
    ((nil) "-")
    (:native-annotation "native hyperdoc.annotation")
    (:compatibility-note-carrier "compatibility note carrier")
    (otherwise
     (code-path-graph-human-label storage-mode))))

;; From hyperdoc/dmx-annotations.lisp, characters 47593..47731.
(defun dmx-workspace-annotation-native-storage-mode-p (storage-mode)
  (eq storage-mode *dmx-workspace-annotation-native-storage-mode*))

;; From hyperdoc/dmx-annotations.lisp, characters 47731..47883.
(defun dmx-workspace-annotation-compatibility-storage-mode-p (storage-mode)
  (eq storage-mode *dmx-workspace-annotation-compatibility-storage-mode*))

;; From hyperdoc/dmx-annotations.lisp, characters 47883..48102.
(defun dmx-workspace-annotation-storage-mode-carrier-type-uri (storage-mode)
  (when (dmx-workspace-annotation-compatibility-storage-mode-p storage-mode)
    *dmx-workspace-annotation-compatibility-carrier-type-uri*))

;; From hyperdoc/dmx-annotations.lisp, characters 48102..48325.
(defun dmx-workspace-annotation-default-storage-mode (client)
  (if (typep client 'http-dmx-import-client)
      *dmx-workspace-annotation-compatibility-storage-mode*
      *dmx-workspace-annotation-native-storage-mode*))

;; From hyperdoc/dmx-annotations.lisp, characters 48325..49592.
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

;; From hyperdoc/dmx-annotations.lisp, characters 49592..50071.
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

;; From hyperdoc/dmx-annotations.lisp, characters 50071..50531.
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

;; From hyperdoc/dmx-annotations.lisp, characters 50531..50797.
(defun dmx-workspace-annotation-workspace-label (workspace-id)
  (when workspace-id
    (if (eql workspace-id *dmx-context-window-workspace-id*)
        (format nil "context-window workspace (~D)" workspace-id)
        (format nil "workspace (~D)" workspace-id))))

;; From hyperdoc/dmx-annotations.lisp, characters 50797..51114.
(defun dmx-workspace-annotation-topicmap-label (workspace-topicmap-id)
  (when workspace-topicmap-id
    (if (eql workspace-topicmap-id *dmx-context-window-topicmap-id*)
        (format nil "context-window topicmap (~D)" workspace-topicmap-id)
        (format nil "workspace topicmap (~D)" workspace-topicmap-id))))

;; From hyperdoc/dmx-annotations.lisp, characters 51114..51525.
(defun normalize-optional-workspace-topicmap-id (workspace-topicmap-id)
  (when workspace-topicmap-id
    (or (parse-positive-integer workspace-topicmap-id)
        (error 'fedwiki-dmx-import-error
               :message (format nil
                                "Workspace annotation destination requires a positive workspace topicmap id, got ~S"
                                workspace-topicmap-id)))))

;; From hyperdoc/dmx-annotations.lisp, characters 51525..52993.
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

;; From hyperdoc/dmx-annotations.lisp, characters 52993..55292.
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

;; From hyperdoc/dmx-annotations.lisp, characters 56309..56960.
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

;; From hyperdoc/dmx-annotations.lisp, characters 56960..57308.
(defun dmx-workspace-annotation-compatibility-envelope-from-topic (topic)
  (and (string= (or (dmx-json-object-value topic "typeUri") "")
                *dmx-workspace-annotation-compatibility-carrier-type-uri*)
       (dmx-workspace-annotation-compatibility-envelope-from-string
        (dmx-json-child-value topic *dmx-notes-text-type-uri*))))

;; From hyperdoc/dmx-annotations.lisp, characters 57308..57693.
(defun dmx-workspace-annotation-topic-storage-mode (topic)
  (cond
    ((string= (or (dmx-json-object-value topic "typeUri") "")
              *dmx-workspace-annotation-type-uri*)
     *dmx-workspace-annotation-native-storage-mode*)
    ((dmx-workspace-annotation-compatibility-envelope-from-topic topic)
     *dmx-workspace-annotation-compatibility-storage-mode*)
    (t
     nil)))

;; From hyperdoc/dmx-annotations.lisp, characters 57693..58571.
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

;; From hyperdoc/dmx-annotations.lisp, characters 58571..59275.
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

;; From hyperdoc/dmx-annotations.lisp, characters 59275..59529.
(defun workspace-annotation-persistence-stage-entry
    (stage status summary &key detail)
  (list :stage stage
        :label (workspace-annotation-persistence-stage-label stage)
        :status status
        :summary summary
        :detail detail))

;; From hyperdoc/dmx-annotations.lisp, characters 59529..59757.
(defun workspace-annotation-persistence-stage-result (report stage)
  (find stage
        (workspace-annotation-persistence-report-stage-results-of report)
        :test #'eq
        :key (lambda (entry) (getf entry :stage))))

;; From hyperdoc/dmx-annotations.lisp, characters 59757..60094.
(defun first-non-latin-1-character-details (string)
  (when (stringp string)
    (loop for char across string
          for index from 0
          unless (<= (char-code char) 255)
          do (return (list :character (string char)
                           :code-point (char-code char)
                           :position index)))))

;; From hyperdoc/dmx-annotations.lisp, characters 60094..61484.
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

;; From hyperdoc/dmx-annotations.lisp, characters 61484..62168.
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

;; From hyperdoc/dmx-annotations.lisp, characters 62168..62362.
(defun workspace-annotation-write-plan-payload-json-string (plan)
  (when plan
    (encode-json-string
     (dmx-import-json-object
      (dmx-workspace-annotation-write-plan-payload plan)))))

;; From hyperdoc/dmx-annotations.lisp, characters 62362..62834.
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

;; From hyperdoc/dmx-annotations.lisp, characters 62834..63102.
(defun workspace-annotation-known-live-create-topic-response-body
    (failing-type-uri)
  (and (stringp failing-type-uri)
       (string= failing-type-uri *dmx-workspace-annotation-type-uri*)
       *dmx-workspace-annotation-known-live-create-topic-response-body*))

;; From hyperdoc/dmx-annotations.lisp, characters 63102..65296.
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

;; From hyperdoc/dmx-annotations.lisp, characters 65296..65511.
(defun workspace-annotation-backend-compatibility-blocked-p (report)
  (member (workspace-annotation-backend-compatibility-report-status-of report)
          '(:not-live :unsupported :error)
          :test #'eq))

;; From hyperdoc/dmx-annotations.lisp, characters 65511..65681.
(defun workspace-annotation-live-compatibility-preflight-required-p (client)
  (or (typep client 'http-dmx-import-client)
      (typep client 'null-dmx-import-client)))

;; From hyperdoc/dmx-annotations.lisp, characters 65681..65968.
(defun workspace-annotation-live-type-support-result
    (type-uri kind topic evidence)
  (list :type-uri type-uri
        :kind kind
        :supported-p (and topic t)
        :topic-id (dmx-import-object-id topic)
        :http-evidence (sanitize-dmx-import-http-evidence evidence)))

;; From hyperdoc/dmx-annotations.lisp, characters 65968..67597.
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

;; From hyperdoc/dmx-annotations.lisp, characters 68099..68511.
(defun dmx-import-http-evidence (condition)
  (and (typep condition 'dmx-import-http-error)
       (let ((evidence
              (or (dmx-import-http-evidence-of condition)
                  (list :url (dmx-import-http-url-of condition)
                        :response-status-code
                        (dmx-import-http-status-code-of condition)))))
         (sanitize-dmx-import-http-evidence evidence))))

;; From hyperdoc/dmx-annotations.lisp, characters 68511..69409.
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

;; From hyperdoc/dmx-annotations.lisp, characters 69409..69487.
(defun workspace-annotation-auth-mode-options ()
  '(:basic :header :token))

;; From hyperdoc/dmx-annotations.lisp, characters 69487..70514.
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

;; From hyperdoc/dmx-annotations.lisp, characters 70514..70691.
(defun workspace-annotation-assignment-endpoint-path (workspace-id topic-id)
  (when (and workspace-id topic-id)
    (dmx-workspace-assign-object-path workspace-id topic-id)))

;; From hyperdoc/dmx-annotations.lisp, characters 70691..70848.
(defun workspace-annotation-auth-missing-keys (condition)
  (and (typep condition 'dmx-import-config-error)
       (dmx-import-missing-keys-of condition)))

;; From hyperdoc/dmx-annotations.lisp, characters 70848..71071.
(defun workspace-annotation-http-auth-blocked-p (condition)
  (and (typep condition 'dmx-import-http-error)
       (member (dmx-import-http-status-code-of condition)
               '(401 403)
               :test #'eql)))

;; From hyperdoc/dmx-annotations.lisp, characters 71071..71247.
(defun workspace-annotation-auth-blocked-condition-p (condition)
  (or (typep condition 'dmx-import-config-error)
      (workspace-annotation-http-auth-blocked-p condition)))

;; From hyperdoc/dmx-annotations.lisp, characters 71247..71673.
(defun workspace-annotation-topic-upsert-existing-topic-anonymous-p
    (client plan)
  (and (typep client 'http-dmx-import-client)
       plan
       (eql (dmx-workspace-annotation-write-plan-topic-action plan)
            :update)
       (dmx-workspace-annotation-write-plan-existing-topic-id plan)
       (null (effective-http-dmx-import-authorization-header client))
       (null (dmx-import-session-cookie-of client))))

;; From hyperdoc/dmx-annotations.lisp, characters 71673..72088.
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

;; From hyperdoc/dmx-annotations.lisp, characters 72088..74607.
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

;; From hyperdoc/dmx-annotations.lisp, characters 74607..76951.
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

;; From hyperdoc/dmx-annotations.lisp, characters 76951..77337.
(defun workspace-annotation-journal-endpoint-path (summary condition)
  (or (and (dmx-import-http-evidence condition)
           (or (getf (dmx-import-http-evidence condition) :path)
               (getf (dmx-import-http-evidence condition) :url)))
      (and summary
           (getf summary :existing-topic-id)
           (dmx-topic-update-path (getf summary :existing-topic-id)))))

;; From hyperdoc/dmx-annotations.lisp, characters 77337..80360.
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

;; From hyperdoc/dmx-annotations.lisp, characters 80360..80760.
(defun workspace-annotation-guarded-boundary-auth-awaiting-p (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (eq (workspace-annotation-persistence-report-status-of report)
           :pending-auth)
       (member (workspace-annotation-persistence-report-failure-stage-of report)
               '(:workspace-assignment :topicmap-placement)
               :test #'eq)))

;; From hyperdoc/dmx-annotations.lisp, characters 80760..80879.
(defun workspace-annotation-pending-auth-p (report)
  (workspace-annotation-guarded-boundary-auth-awaiting-p report))

;; From hyperdoc/dmx-annotations.lisp, characters 82449..82839.
(defun workspace-annotation-journal-preflight-repair-failed-p (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (eq (workspace-annotation-persistence-report-failure-stage-of report)
           :prepare-transition)
       (typep (workspace-annotation-persistence-report-condition-of report)
              'dmx-workspace-journal-companion-repair-failed-error)))

;; From hyperdoc/dmx-annotations.lisp, characters 82839..83377.
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

;; From hyperdoc/dmx-annotations.lisp, characters 83377..85010.
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

;; From hyperdoc/dmx-annotations.lisp, characters 87633..88027.
(defun workspace-annotation-auth-awaiting-stage-p
    (failure-stage failure-condition
     &key persisted-topic-id journal-preflight-auth-blocked-p)
  (or journal-preflight-auth-blocked-p
      (and persisted-topic-id
           (member failure-stage '(:workspace-assignment :topicmap-placement)
                   :test #'eq)
           (typep failure-condition 'dmx-import-config-error))))

;; From hyperdoc/dmx-annotations.lisp, characters 88027..88251.
(defun workspace-annotation-persistence-report-journal-preflight-existing-topic-id-of
    (report)
  (getf (workspace-annotation-persistence-report-journal-preflight-summary-of
         report)
        :existing-topic-id))

;; From hyperdoc/dmx-annotations.lisp, characters 88251..88541.
(defun workspace-annotation-persistence-report-journal-topic-id-of (report)
  (or (getf (workspace-annotation-journal-preflight-repair-summary report)
            :replacement-topic-id)
      (workspace-annotation-persistence-report-journal-preflight-existing-topic-id-of
       report)))

;; From hyperdoc/dmx-annotations.lisp, characters 89301..89526.
(defun workspace-annotation-journal-preflight-label (summary)
  (when summary
    (or (getf summary :note-title)
        (getf summary :note-uri)
        (getf summary :note-key)
        "the workspace journal companion")))

;; From hyperdoc/dmx-annotations.lisp, characters 89526..90166.
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

;; From hyperdoc/dmx-annotations.lisp, characters 90166..93837.
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

;; From hyperdoc/dmx-annotations.lisp, characters 121769..122543.
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

;; From hyperdoc/dmx-annotations.lisp, characters 123543..124226.
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

;; From hyperdoc/dmx-annotations.lisp, characters 124226..125432.
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

;; From hyperdoc/dmx-annotations.lisp, characters 152207..152643.
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

;; From hyperdoc/dmx-annotations.lisp, characters 152643..156743.
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

;; From hyperdoc/dmx-annotations.lisp, characters 156743..157115.
(defun make-workspace-annotation-persistence-report-like
    (report &rest overrides)
  (let ((initargs (copy-list
                   (workspace-annotation-persistence-report-initargs report))))
    (loop for (key value) on overrides by #'cddr
          do (setf (getf initargs key) value))
    (apply #'make-instance 'workspace-annotation-persistence-report initargs)))

;; From hyperdoc/dmx-annotations.lisp, characters 157115..157661.
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

;; From hyperdoc/dmx-annotations.lisp, characters 157661..158884.
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

;; From hyperdoc/dmx-annotations.lisp, characters 158884..159106.
(defun workspace-annotation-persistence-runtime-relation-id (annotation)
  (or (and (workspace-dock-annotation-p annotation)
           (workspace-annotation-runtime-relation-id-of annotation))
      (id-of annotation)))

;; From hyperdoc/dmx-annotations.lisp, characters 159106..159798.
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

;; From hyperdoc/dmx-annotations.lisp, characters 159798..171525.
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

;; From hyperdoc/dmx-annotations.lisp, characters 171525..172100.
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

;; From hyperdoc/dmx-annotations.lisp, characters 172100..174904.
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

;; From hyperdoc/dmx-annotations.lisp, characters 187780..188045.
(defun dmx-workspace-annotation-plist-p (value)
  (and (listp value)
       (evenp (length value))
       (loop for (key nil) on value by #'cddr
             always (or (keywordp key)
                        (symbolp key)
                        (stringp key)))))

;; From hyperdoc/dmx-annotations.lisp, characters 188045..188769.
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

;; From hyperdoc/dmx-annotations.lisp, characters 188769..189898.
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

;; From hyperdoc/dmx-annotations.lisp, characters 189898..190213.
(defun dmx-workspace-annotation-json-object (&rest key-values)
  (let ((json (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (when value
               (setf (gethash key json)
                     (dmx-workspace-annotation-json-friendly-value value))))
    json))

;; From hyperdoc/dmx-annotations.lisp, characters 190213..190362.
(defun dmx-workspace-annotation-json-string (&rest key-values)
  (encode-json-string
   (apply #'dmx-workspace-annotation-json-object key-values)))

;; From hyperdoc/dmx-annotations.lisp, characters 190362..190897.
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

;; From hyperdoc/dmx-annotations.lisp, characters 190897..191280.
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

;; From hyperdoc/dmx-annotations.lisp, characters 191280..192593.
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

;; From hyperdoc/dmx-annotations.lisp, characters 192593..192748.
(defun dmx-workspace-annotation-uri (annotation-key)
  (format nil "~A~A"
          *hyperdoc-workspace-annotation-uri-prefix*
          annotation-key))

;; From hyperdoc/dmx-annotations.lisp, characters 192748..193363.
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

;; From hyperdoc/dmx-annotations.lisp, characters 193363..193944.
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

;; From hyperdoc/dmx-annotations.lisp, characters 193944..194149.
(defun dmx-workspace-annotation-topic-title (topic)
  (or (dmx-json-child-value topic *dmx-workspace-annotation-title-type-uri*)
      (dmx-json-object-value topic "value")
      "Workspace annotation"))

;; From hyperdoc/dmx-annotations.lisp, characters 194149..194318.
(defun dmx-workspace-annotation-annotation-player-ref (uri)
  (dmx-workspace-annotation-json-object
   "role" "annotation"
   "refKind" "topic-uri"
   "refValue" uri))

;; From hyperdoc/dmx-annotations.lisp, characters 194318..194519.
(defun dmx-workspace-annotation-player-ref (role ref-kind ref-value &key label)
  (dmx-workspace-annotation-json-object
   "role" role
   "refKind" ref-kind
   "refValue" ref-value
   "label" label))

;; From hyperdoc/dmx-annotations.lisp, characters 194519..194859.
(defun dmx-workspace-annotation-binding-json-string
    (binding-type annotation-uri other-player &rest extra-pairs)
  (apply #'dmx-workspace-annotation-json-string
         "bindingType" binding-type
         "player1" (dmx-workspace-annotation-annotation-player-ref annotation-uri)
         "player2" other-player
         extra-pairs))

;; From hyperdoc/dmx-annotations.lisp, characters 194859..195287.
(defun dmx-workspace-annotation-provenance-json
    (annotation workspace-topicmap-id)
  (dmx-workspace-annotation-json-string
   "savedFrom" "dock-annotation"
   "dockCapability" (dock-capability-of annotation)
   "runtimeRelationId" (id-of annotation)
   "registryKey" (registry-key-of annotation)
   "workspaceTopicmapId" workspace-topicmap-id
   "annotationClass" (format nil "~(~A~)" (class-name (class-of annotation)))))

;; From hyperdoc/dmx-annotations.lisp, characters 195287..198547.
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

;; From hyperdoc/dmx-annotations.lisp, characters 198547..199827.
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

;; From hyperdoc/dmx-annotations.lisp, characters 199827..200472.
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

;; From hyperdoc/dmx-annotations.lisp, characters 200472..201199.
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

;; From hyperdoc/dmx-annotations.lisp, characters 201622..207291.
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

;; From hyperdoc/dmx-annotations.lisp, characters 207291..211376.
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

;; From hyperdoc/dmx-annotations.lisp, characters 211376..214936.
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

;; From hyperdoc/dmx-annotations.lisp, characters 214936..222923.
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

;; From hyperdoc/dmx-annotations.lisp, characters 222923..224508.
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

;; From hyperdoc/dmx-annotations.lisp, characters 224508..225836.
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

;; From hyperdoc/dmx-annotations.lisp, characters 225836..231631.
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

;; From hyperdoc/dmx-annotations.lisp, characters 231631..233318.
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

;; From hyperdoc/dmx-annotations.lisp, characters 233318..250534.
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

;; From hyperdoc/dmx-annotations.lisp, characters 250534..251292.
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

;; From hyperdoc/dmx-annotations.lisp, characters 251292..251554.
(defun workspace-annotation-continuation-ready-p (report)
  (and (typep report 'workspace-annotation-persistence-report)
       (workspace-annotation-persistence-report-plan-of report)
       (workspace-annotation-persistence-report-saved-topic-id-of report)))

;; From hyperdoc/dmx-annotations.lisp, characters 251554..253678.
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

;; From hyperdoc/dmx-annotations.lisp, characters 253678..256060.
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

;; From hyperdoc/dmx-annotations.lisp, characters 256060..256422.
(defun continue-workspace-annotation-with-guarded-assignment
    (plan client topic-id workspace-topicmap-id &key (dry-run nil))
  (execute-dmx-workspace-topic-workspace-assignment-repair
   topic-id
   :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
   :workspace-topicmap-id workspace-topicmap-id
   :client client
   :dry-run dry-run))

;; From hyperdoc/dmx-annotations.lisp, characters 256422..256778.
(defun continue-workspace-annotation-with-guarded-topicmap-placement
    (plan client topic-id workspace-topicmap-id &key (dry-run nil))
  (execute-dmx-workspace-topicmap-context-upsert
   topic-id
   :workspace-topicmap-id workspace-topicmap-id
   :client client
   :view-props (dmx-workspace-annotation-write-plan-view-props plan)
   :dry-run dry-run))

;; From hyperdoc/dmx-annotations.lisp, characters 256778..257375.
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

;; From hyperdoc/dmx-annotations.lisp, characters 257375..257745.
(defun guarded-workspace-assignment-stage-detail (summary)
  (format nil
          "Executor repair_workspace_topic_assignment kept workspace assignment distinct from topicmap placement. Result workspace: ~A. Topicmap preserved separately: ~A."
          (or (getf summary :result-workspace-id) "-")
          (if (getf summary :result-in-topicmap-p) "true" "false")))

;; From hyperdoc/dmx-annotations.lisp, characters 257745..258328.
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

;; From hyperdoc/dmx-annotations.lisp, characters 258328..258586.
(defun guarded-topicmap-placement-stage-detail (summary)
  (declare (ignore summary))
  (format nil
          "Executor upsert_workspace_topicmap_context only changes topicmap membership/view props. Workspace ownership still has to be proven separately."))

;; From hyperdoc/dmx-annotations.lisp, characters 258586..259155.
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

;; From hyperdoc/dmx-annotations.lisp, characters 259155..267689.
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

;; From hyperdoc/dmx-annotations.lisp, characters 323357..324412.
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

;; From hyperdoc/dmx-annotations.lisp, characters 337471..337746.
(defun dmx-workspace-annotation-child-json (topic child-type-uri)
  (let ((json-string (dmx-json-child-value topic child-type-uri)))
    (and (dmx-non-empty-string-p json-string)
         (with-input-from-string (stream json-string)
           (shasht:read-json stream)))))

;; From hyperdoc/dmx-annotations.lisp, characters 337746..338164.
(defun dmx-workspace-annotation-binding-topic-id (binding)
  (let* ((player (and binding (gethash "player2" binding)))
         (ref-kind (and player (gethash "refKind" player)))
         (ref-value (and player (gethash "refValue" player))))
    (when (and (string= (or ref-kind "") "topic-id")
               ref-value)
      (or (parse-positive-integer ref-value)
          (and (integerp ref-value) ref-value)))))

;; From hyperdoc/dmx-annotations.lisp, characters 338164..338448.
(defun dmx-workspace-annotation-target-object (target-object-ref)
  (let ((annotation-topic (annotation-topic)))
    (if (string= (or target-object-ref "")
                 (dmx-workspace-annotation-ref-string annotation-topic))
        annotation-topic
        target-object-ref)))

;; From hyperdoc/dmx-annotations.lisp, characters 338448..339591.
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

;; From hyperdoc/dmx-annotations.lisp, characters 339591..340693.
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

;; From hyperdoc/dmx-annotations.lisp, characters 340693..346805.
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

;; From hyperdoc/dmx-annotations.lisp, characters 352542..355189.
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
