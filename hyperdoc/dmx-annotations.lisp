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
   (journal-preflight-auth-context
    :initarg :journal-preflight-auth-context
    :initform nil
    :reader
    workspace-annotation-persistence-report-journal-preflight-auth-context-of)
   (assignment-auth-context
    :initarg :assignment-auth-context
    :initform nil
    :reader workspace-annotation-persistence-report-assignment-auth-context-of)))

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
    :reader workspace-annotation-topic-id-of)
   (workspace-topic-uri
    :initarg :workspace-topic-uri
    :reader workspace-annotation-topic-uri-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
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

(defun workspace-dock-annotation-p (object)
  (typep object 'workspace-dock-annotation))

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
         *
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
        :http-evidence evidence))

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
         *
         :workspace-topicmap-id ,workspace-topicmap-id
         ,@(when workspace-id
             `(:workspace-id ,workspace-id))
         :storage-mode ,storage-mode)))))

(defun dmx-import-http-evidence (condition)
  (and (typep condition 'dmx-import-http-error)
       (or (dmx-import-http-evidence-of condition)
           (list :url (dmx-import-http-url-of condition)
                 :response-status-code
                 (dmx-import-http-status-code-of condition)
                 :response-body
                 (dmx-import-http-response-body-of condition)))))

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
           :payload-json
           (workspace-annotation-write-plan-payload-json-string plan))
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

(defun workspace-annotation-pending-auth-p (report)
  (eq (workspace-annotation-persistence-report-status-of report)
      :pending-auth))

(defun workspace-annotation-journal-preflight-auth-blocked-p (report)
  (and (eq (workspace-annotation-persistence-report-failure-stage-of report)
           :prepare-transition)
       (workspace-annotation-persistence-report-journal-preflight-auth-context-of
        report)))

(defun workspace-annotation-persistence-report-journal-topic-id-of (report)
  (getf (workspace-annotation-persistence-report-journal-preflight-summary-of
         report)
        :existing-topic-id))

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
    ((typep condition 'dmx-import-config-error)
     "DMX auth is missing")
    ((workspace-annotation-http-auth-blocked-p condition)
     "DMX auth is missing or unauthorized for the journal companion topic")
    (t
     (format nil "~A" condition))))

(defun workspace-annotation-journal-preflight-blocked-detail
    (summary workspace-label topicmap-label condition)
  (format nil
          "Before annotation topic upsert could start, HyperDoc could not reconcile ~A for ~A in ~A because ~A. This is the workspace journal preflight boundary, not annotation topic upsert, workspace assignment, or topicmap placement."
          (workspace-annotation-journal-preflight-label summary)
          (or workspace-label "the selected workspace")
          (or topicmap-label "the selected topicmap")
          (workspace-annotation-journal-preflight-blocked-cause condition)))

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
        :journal-preflight-auth-context
        (workspace-annotation-persistence-report-journal-preflight-auth-context-of
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
         *
         :workspace-topicmap-id ,workspace-topicmap-id
         ,@(when workspace-id
             `(:workspace-id ,workspace-id))
         ,@(when storage-mode
             `(:storage-mode ,storage-mode))
         :dry-run nil)))))

(defun workspace-annotation-persistence-stepper-source
    (workspace-topicmap-id &key workspace-id storage-mode)
  (if storage-mode
      (format nil
              "(hyperdoc::plan-dmx-workspace-annotation-write-from-object * :workspace-topicmap-id ~D~@[ :workspace-id ~D~] :storage-mode ~S)~%~%(hyperdoc::persist-dock-annotation-to-workspace * :workspace-topicmap-id ~D~@[ :workspace-id ~D~] :storage-mode ~S :dry-run nil)"
              workspace-topicmap-id
              workspace-id
              storage-mode
              workspace-topicmap-id
              workspace-id
              storage-mode)
      (format nil
              "(hyperdoc::plan-dmx-workspace-annotation-write-from-object * :workspace-topicmap-id ~D~@[ :workspace-id ~D~])~%~%(hyperdoc::persist-dock-annotation-to-workspace * :workspace-topicmap-id ~D~@[ :workspace-id ~D~] :dry-run nil)"
              workspace-topicmap-id
              workspace-id
              workspace-topicmap-id
              workspace-id)))

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
     (dmx-workspace-annotation-write-plan-view-props plan)))
  (let* ((after-topic (dmx-import-read-topic client topic-id))
         (after-state
           (dmx-workspace-journal-live-snapshot
            client
            after-topic
            (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)))
         (journal-events
           (dmx-workspace-journal-record-transition
            client
            previous-state
            after-state
            (dmx-workspace-annotation-write-plan-workspace-topicmap-id
             plan))))
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
                  :ownership-class "hyperdoc-workspace-annotation"))
               (topic
                 (ecase (dmx-workspace-annotation-write-plan-topic-action plan)
                   (:create
                    (dmx-import-create-topic
                     resolved-client
                     (dmx-workspace-annotation-write-plan-payload plan)))
                   (:update
                    (dmx-import-update-topic
                     resolved-client
                     (dmx-workspace-annotation-write-plan-existing-topic plan)
                     (dmx-workspace-annotation-write-plan-payload plan)))))
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
                     (dmx-workspace-journal-prepare-transition
                      resolved-client
                      subject-key
                      "uri"
                      subject-key
                      resolved-topicmap-id
                      :subject-uri subject-key
                      :subject-kind "workspace-annotation"
                      :ownership-class "hyperdoc-workspace-annotation"))
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
                        (dmx-import-update-topic
                         resolved-client
                         (dmx-workspace-annotation-write-plan-existing-topic
                          plan)
                         (dmx-workspace-annotation-write-plan-payload
                          plan)))))))
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
                     (dmx-workspace-journal-record-transition
                      resolved-client
                      previous-state
                      after-state
                      resolved-topicmap-id))))
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
               (and (eq failure-stage :workspace-assignment)
                    persisted-topic-id
                    (typep failure-condition 'dmx-import-config-error)))
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
                                 (pending-auth-p :pending-auth)
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

(defun continue-workspace-annotation-persistence-with-client
    (report client)
  (unless (workspace-annotation-pending-auth-p report)
    (error 'fedwiki-dmx-import-error
           :message "Workspace annotation persistence continuation requires a pending-auth report"))
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
             (run-stage (stage summary thunk &key detail)
               (handler-case
                   (let ((value (funcall thunk)))
                     (record-stage stage :completed summary :detail detail)
                     value)
                 (error (condition)
                   (setf failure-stage stage
                         failure-condition condition)
                   (record-stage stage
                                 :error
                                 summary
                                 :detail (or detail
                                             (format nil "~A" condition)))
                   (error condition)))))
      (handler-case
          (let ((after-topic nil)
                (after-state nil)
                (journal-events nil))
            (if (eql (dmx-workspace-annotation-write-plan-workspace-action plan)
                     :assign)
                (run-stage
                 :workspace-assignment
                 (format nil
                         "Assigned topic ~D to workspace ~D."
                         topic-id
                         (dmx-workspace-annotation-write-plan-workspace-id plan))
                 (lambda ()
                   (dmx-import-assign-topic-to-workspace
                    client
                    (dmx-workspace-annotation-write-plan-workspace-id plan)
                    topic-id)))
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
                         topic-id
                         workspace-topicmap-id)
                 (lambda ()
                   (dmx-import-add-topic-to-topicmap
                    client
                    workspace-topicmap-id
                    topic-id
                    (dmx-workspace-annotation-write-plan-view-props plan))))
                (record-stage
                 :topicmap-placement
                 :skipped
                 "Topicmap placement was already present; no add-to-topicmap write was needed."))
            (setf after-topic (dmx-import-read-topic client topic-id)
                  after-state
                  (dmx-workspace-journal-live-snapshot
                   client
                   after-topic
                   workspace-topicmap-id))
            (setf journal-events
                  (run-stage
                   :journal-transition
                   "Recorded the workspace journal transition for the live annotation write."
                   (lambda ()
                     (dmx-workspace-journal-record-transition
                      client
                      previous-state
                      after-state
                      workspace-topicmap-id))))
            (setf raw-result
                  (append raw-result
                          (list :journal-event-count (length journal-events))))
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
                        ((and (eq failure-stage :workspace-assignment)
                              (typep failure-condition
                                     'dmx-import-config-error))
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
            (typep failure-condition 'dmx-import-config-error)
            (workspace-annotation-assignment-auth-context
             plan
             client
             topic-id
             failure-condition))))))

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
  (handler-case
      (continue-workspace-annotation-journal-preflight-with-client
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
       :report-status
       (workspace-annotation-persistence-report-status-of report)
       :failure-stage
       (workspace-annotation-persistence-report-failure-stage-of report)
       :journal-preflight-auth-context
       (append
        (or (workspace-annotation-persistence-report-journal-preflight-auth-context-of
             report)
            '())
        (list :explicit-auth-condition (format nil "~A" condition)))))))

(defun probe-live-create-topic-for-dock-annotation
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       (storage-mode *dmx-workspace-annotation-native-storage-mode*))
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

(defun persist-dock-annotation-to-workspace
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       storage-mode
       (dry-run t))
  (let* ((resolved-client
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
