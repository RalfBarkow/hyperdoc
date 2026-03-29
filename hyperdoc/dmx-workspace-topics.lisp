;;;; Guarded DMX workspace topic lifecycle helpers for MCP
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(define-condition dmx-workspace-topic-validation-error (fedwiki-dmx-import-error)
  ((boundary :reader dmx-workspace-topic-validation-boundary-of :initarg :boundary)
   (payload :reader dmx-workspace-topic-validation-payload-of :initarg :payload)
   (missing-fields
    :reader dmx-workspace-topic-validation-missing-fields-of
    :initarg :missing-fields
    :initform nil)
   (invalid-fields
    :reader dmx-workspace-topic-validation-invalid-fields-of
    :initarg :invalid-fields
    :initform nil))
  (:report (lambda (condition stream)
             (format stream "~A"
                     (fedwiki-dmx-import-message-of condition)))))

(define-condition dmx-workspace-topic-ownership-error (fedwiki-dmx-import-error)
  ((topic-id :reader dmx-workspace-topic-ownership-topic-id-of :initarg :topic-id)
   (ownership-class
    :reader dmx-workspace-topic-ownership-class-of
    :initarg :ownership-class)
   (uri :reader dmx-workspace-topic-ownership-uri-of :initarg :uri :initform nil)
   (allowed-actions
    :reader dmx-workspace-topic-ownership-allowed-actions-of
    :initarg :allowed-actions
    :initform nil))
  (:report (lambda (condition stream)
             (format stream "~A"
                     (fedwiki-dmx-import-message-of condition)))))

(defparameter *hyperdoc-workspace-note-uri-prefix* "hyperdoc:mcp/workspace-note/")
(defparameter *hyperdoc-handover-uri-prefix* "hyperdoc:mcp/handover/")
(defparameter *hyperdoc-topic-factory-snippet-uri-prefix*
  "hyperdoc:topic-factory-snippet/")

(defstruct dmx-workspace-topic-ownership
  class
  uri
  external-key
  type-uri
  workspace-topicmap-id
  owned-p
  reason)

(defstruct dmx-workspace-topicmap-membership-plan
  operation
  topicmap-id
  topic-id
  topic-uri
  topic-title
  in-topicmap-p
  topicmap-action
  view-props
  view-props-normalization
  intended-method
  intended-endpoint
  live-supported-p
  support-reason)

(defstruct dmx-workspace-topic-delete-plan
  operation
  topic-id
  note-key
  note-kind
  workspace-topicmap-id
  topic-uri
  topic-type-uri
  topic-title
  in-topicmap-p
  ownership
  delete-action
  intended-method
  intended-endpoint)

(defun dmx-workspace-topic-validation-message (boundary missing-fields invalid-fields)
  (with-output-to-string (stream)
    (format stream "DMX workspace topic validation failed at ~A" boundary)
    (when missing-fields
      (format stream "; missing fields: ~{~A~^, ~}" missing-fields))
    (when invalid-fields
      (format stream "; invalid fields: ~{~A~^, ~}" invalid-fields))))

(defun normalize-dmx-workspace-topic-string (value field boundary &key required?)
  (normalize-dmx-workspace-note-string value field boundary :required? required?))

(defun normalize-dmx-workspace-topic-id (value field boundary &key required?)
  (cond
    ((null value)
     (when required?
       (error 'dmx-workspace-topic-validation-error
              :message (dmx-workspace-topic-validation-message boundary
                                                              (list field)
                                                              nil)
              :boundary boundary
              :payload (list field value)
              :missing-fields (list field)))
     nil)
    (t
     (or (parse-positive-integer value)
         (error 'dmx-workspace-topic-validation-error
                :message (dmx-workspace-topic-validation-message boundary
                                                                nil
                                                                (list field))
                :boundary boundary
                :payload (list field value)
                :invalid-fields (list field))))))

(defun normalize-dmx-workspace-note-kind-designator (value boundary)
  (cond
    ((null value) :workspace-note)
    ((or (eq value :workspace-note)
         (string-equal value "workspace-note")
         (string-equal value "workspace_note"))
     :workspace-note)
    ((or (eq value :handover)
         (string-equal value "handover"))
     :handover)
    (t
     (error 'dmx-workspace-topic-validation-error
            :message (dmx-workspace-topic-validation-message boundary
                                                            nil
                                                            '(:note-kind))
            :boundary boundary
            :payload (list :note-kind value)
            :invalid-fields '(:note-kind)))))

(defun dmx-string-prefix-p (prefix string)
  (and (stringp prefix)
       (stringp string)
       (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun dmx-workspace-topic-title (topic)
  (or (dmx-json-child-value topic *dmx-notes-title-type-uri*)
      (dmx-json-object-value topic "value")
      "Untitled topic"))

(defun dmx-workspace-topicmap-child-id (topic)
  (let ((value (dmx-json-child-value topic
                                     *dmx-topic-factory-snippet-workspace-topicmap-type-uri*)))
    (or (parse-positive-integer value)
        (and (integerp value)
             (plusp value)
             value))))

(defun classify-dmx-workspace-topic-ownership (topic)
  (let* ((uri (or (dmx-json-object-value topic "uri") ""))
         (external-key (or (dmx-json-object-value topic "externalKey")
                           (dmx-json-object-value topic "external-key")
                           uri))
         (type-uri (dmx-json-object-value topic "typeUri"))
         (workspace-topicmap-id (dmx-workspace-topicmap-child-id topic)))
    (cond
      ((dmx-string-prefix-p *hyperdoc-workspace-note-uri-prefix* uri)
       (make-dmx-workspace-topic-ownership
        :class :hyperdoc-workspace-note
        :uri uri
        :external-key external-key
        :type-uri type-uri
        :workspace-topicmap-id workspace-topicmap-id
        :owned-p t
        :reason "HyperDoc workspace-note URI prefix"))
      ((dmx-string-prefix-p *hyperdoc-handover-uri-prefix* uri)
       (make-dmx-workspace-topic-ownership
        :class :hyperdoc-handover
        :uri uri
        :external-key external-key
        :type-uri type-uri
        :workspace-topicmap-id workspace-topicmap-id
        :owned-p t
        :reason "HyperDoc handover URI prefix"))
      ((dmx-string-prefix-p *hyperdoc-topic-factory-snippet-uri-prefix* uri)
       (make-dmx-workspace-topic-ownership
        :class :hyperdoc-topic-factory-snippet
        :uri uri
        :external-key external-key
        :type-uri type-uri
        :workspace-topicmap-id workspace-topicmap-id
        :owned-p t
        :reason "HyperDoc topic-factory snippet URI prefix"))
      (t
       (make-dmx-workspace-topic-ownership
        :class :foreign
        :uri uri
        :external-key external-key
        :type-uri type-uri
        :workspace-topicmap-id workspace-topicmap-id
        :owned-p nil
        :reason "No HyperDoc-owned URI or external-key prefix matched")))))

(defun dmx-workspace-topic-hard-delete-allowed-p (ownership workspace-topicmap-id)
  (case (dmx-workspace-topic-ownership-class ownership)
    ((:hyperdoc-workspace-note :hyperdoc-handover)
     t)
    (:hyperdoc-topic-factory-snippet
     (let ((bound-topicmap-id
             (dmx-workspace-topic-ownership-workspace-topicmap-id ownership)))
       (or (null workspace-topicmap-id)
           (null bound-topicmap-id)
           (eql workspace-topicmap-id bound-topicmap-id))))
    (otherwise
     nil)))

(defun dmx-workspace-topic-allowed-delete-actions (ownership workspace-topicmap-id)
  (if (dmx-workspace-topic-hard-delete-allowed-p ownership workspace-topicmap-id)
      '(:hard-delete)
      '()))

(defun dmx-workspace-topic-delete-plan-summary (plan)
  (let ((ownership (dmx-workspace-topic-delete-plan-ownership plan)))
    (list :operation (dmx-workspace-topic-delete-plan-operation plan)
          :topic-id (dmx-workspace-topic-delete-plan-topic-id plan)
          :note-key (dmx-workspace-topic-delete-plan-note-key plan)
          :note-kind (dmx-workspace-topic-delete-plan-note-kind plan)
          :workspace-topicmap-id
          (dmx-workspace-topic-delete-plan-workspace-topicmap-id plan)
          :topic-uri (dmx-workspace-topic-delete-plan-topic-uri plan)
          :topic-type-uri (dmx-workspace-topic-delete-plan-topic-type-uri plan)
          :topic-title (dmx-workspace-topic-delete-plan-topic-title plan)
          :in-topicmap-p (dmx-workspace-topic-delete-plan-in-topicmap-p plan)
          :ownership-class (dmx-workspace-topic-ownership-class ownership)
          :hyperdoc-owned-p (dmx-workspace-topic-ownership-owned-p ownership)
          :ownership-reason (dmx-workspace-topic-ownership-reason ownership)
          :ownership-workspace-topicmap-id
          (dmx-workspace-topic-ownership-workspace-topicmap-id ownership)
          :delete-action (dmx-workspace-topic-delete-plan-delete-action plan)
          :intended-method (dmx-workspace-topic-delete-plan-intended-method plan)
          :intended-endpoint (dmx-workspace-topic-delete-plan-intended-endpoint plan))))

(defun dmx-workspace-topicmap-membership-plan-summary (plan)
  (list :operation (dmx-workspace-topicmap-membership-plan-operation plan)
        :topicmap-id (dmx-workspace-topicmap-membership-plan-topicmap-id plan)
        :topic-id (dmx-workspace-topicmap-membership-plan-topic-id plan)
        :topic-uri (dmx-workspace-topicmap-membership-plan-topic-uri plan)
        :topic-title (dmx-workspace-topicmap-membership-plan-topic-title plan)
        :in-topicmap-p (dmx-workspace-topicmap-membership-plan-in-topicmap-p plan)
        :topicmap-action (dmx-workspace-topicmap-membership-plan-topicmap-action plan)
        :payload-validation-status
        (and (dmx-workspace-topicmap-membership-plan-view-props-normalization plan)
             (getf (dmx-workspace-topicmap-membership-plan-view-props-normalization plan)
                   :status))
        :normalized-view-props-json
        (and (dmx-workspace-topicmap-membership-plan-view-props plan)
             (dmx-topicmap-view-props-json-string
              (dmx-workspace-topicmap-membership-plan-view-props plan)))
        :intended-method (dmx-workspace-topicmap-membership-plan-intended-method plan)
        :intended-endpoint (dmx-workspace-topicmap-membership-plan-intended-endpoint plan)
        :live-supported-p (dmx-workspace-topicmap-membership-plan-live-supported-p plan)
        :support-reason (dmx-workspace-topicmap-membership-plan-support-reason plan)))

(defun normalize-dmx-workspace-topic-references (value)
  (remove-duplicates
   (remove nil
           (mapcar (lambda (item)
                     (and (dmx-non-empty-string-p item)
                          (string-trim '(#\Space #\Tab #\Newline #\Return) item)))
                   (or (json-array-elements value) '())))
   :test #'string=))

(defun mcp-json-object->plist (value)
  (cond
    ((null value) nil)
    ((hash-table-p value)
     (loop for key being the hash-keys of value using (hash-value nested-value)
           append (list (intern (string-upcase
                                 (substitute #\- #\_ (princ-to-string key)))
                                :keyword)
                        (cond
                          ((vectorp nested-value)
                           (coerce nested-value 'list))
                          (t
                           nested-value)))))
    ((and (listp value)
          (evenp (length value)))
     value)
    (t
     nil)))

(defun default-mcp-topic-factory-snippet-provenance
    (snippet-id workspace-topicmap-id source-path)
  (list :source-kind "hyperdoc-mcp-topic-factory-snippet"
        :provenance-granularity "manual-mcp-write"
        :provenance-classification "explicit-tool-payload"
        :snippet-id snippet-id
        :workspace-topicmap-id workspace-topicmap-id
        :source-file source-path
        :derivation-note
        "Created or updated through the guarded MCP topic-factory snippet upsert boundary."))

(defun make-mcp-topic-factory-snippet-definition
    (&key snippet-id snippet-text source-path workspace-topicmap-id references
          related-hyperdoc-page-title related-topic-id source-origin-id
          source-origin-path provenance)
  (let* ((resolved-snippet-id
           (normalize-dmx-workspace-topic-string
            snippet-id
            :snippet-id
            'make-mcp-topic-factory-snippet-definition
            :required? t))
         (resolved-snippet-text
           (normalize-dmx-workspace-topic-string
            snippet-text
            :snippet-text
            'make-mcp-topic-factory-snippet-definition
            :required? t))
         (resolved-source-path
           (normalize-dmx-workspace-topic-string
            source-path
            :source-path
            'make-mcp-topic-factory-snippet-definition
            :required? t))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-related-page-title
           (or (and related-hyperdoc-page-title
                    (normalize-dmx-workspace-topic-string
                     related-hyperdoc-page-title
                     :related-hyperdoc-page-title
                     'make-mcp-topic-factory-snippet-definition))
               resolved-snippet-id))
         (resolved-related-topic-id
           (or (and related-topic-id
                    (normalize-dmx-workspace-topic-string
                     related-topic-id
                     :related-topic-id
                     'make-mcp-topic-factory-snippet-definition))
               resolved-snippet-id))
         (resolved-source-origin-id
           (or (and source-origin-id
                    (normalize-dmx-workspace-topic-string
                     source-origin-id
                     :source-origin-id
                     'make-mcp-topic-factory-snippet-definition))
               (format nil "hyperdoc:mcp/topic-factory-snippet-source/~A"
                       resolved-snippet-id)))
         (resolved-source-origin-path
           (or (and source-origin-path
                    (normalize-dmx-workspace-topic-string
                     source-origin-path
                     :source-origin-path
                     'make-mcp-topic-factory-snippet-definition))
               resolved-source-path))
         (resolved-provenance
           (append (default-mcp-topic-factory-snippet-provenance
                     resolved-snippet-id
                     resolved-topicmap-id
                     resolved-source-path)
                   (mcp-json-object->plist provenance)))
         (resolved-references
           (remove-duplicates
            (append (copy-list references)
                    (list resolved-source-origin-id))
            :test #'string=)))
    (make-instance 'topic-definition-chunk
                   :id resolved-snippet-id
                   :title (format nil "~A topic-definition chunk"
                                  resolved-snippet-id)
                   :summary
                   "HyperDoc-owned workspace topic-factory snippet twin created through the guarded MCP boundary."
                   :source-path resolved-source-path
                   :references resolved-references
                   :snippet-id resolved-snippet-id
                   :snippet-text resolved-snippet-text
                   :source-origin-id resolved-source-origin-id
                   :source-origin-path resolved-source-origin-path
                   :related-hyperdoc-page-title resolved-related-page-title
                   :related-topic-id resolved-related-topic-id
                   :related-topic-ids (list resolved-related-topic-id)
                   :provenance resolved-provenance)))

(defun plan-dmx-workspace-topicmap-context-upsert
    (topic-id &key workspace-topicmap-id client view-props)
  (let* ((resolved-topic-id
           (normalize-dmx-workspace-topic-id
            topic-id
            :topic-id
            'plan-dmx-workspace-topicmap-context-upsert
            :required? t))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (topic (dmx-import-read-topic resolved-client resolved-topic-id)))
    (unless topic
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "Cannot place missing DMX topic ~D into workspace topicmap ~D"
                              resolved-topic-id
                              resolved-topicmap-id)))
    (multiple-value-bind (normalized-view-props normalization)
        (normalize-dmx-topicmap-view-props
         view-props
         :boundary 'plan-dmx-workspace-topicmap-context-upsert)
      (let ((in-topicmap-p
              (dmx-import-topic-in-topicmap-p resolved-client
                                             resolved-topicmap-id
                                             resolved-topic-id)))
        (make-dmx-workspace-topicmap-membership-plan
         :operation :workspace-topicmap-context-upsert
         :topicmap-id resolved-topicmap-id
         :topic-id resolved-topic-id
         :topic-uri (dmx-json-object-value topic "uri")
         :topic-title (dmx-workspace-topic-title topic)
         :in-topicmap-p in-topicmap-p
         :topicmap-action (if in-topicmap-p :set-view-props :add)
         :view-props normalized-view-props
         :view-props-normalization normalization
         :intended-method (if in-topicmap-p :put :post)
         :intended-endpoint
         (dmx-topicmap-add-topic-path resolved-topicmap-id resolved-topic-id)
         :live-supported-p t
         :support-reason "Validated POST/PUT topicmap-context boundary")))))

(defun execute-dmx-workspace-topicmap-context-upsert
    (topic-id &key workspace-topicmap-id client view-props (dry-run t))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-dmx-workspace-topicmap-context-upsert
                topic-id
                :workspace-topicmap-id workspace-topicmap-id
                :client resolved-client
                :view-props view-props)))
    (unless dry-run
      (ecase (dmx-workspace-topicmap-membership-plan-topicmap-action plan)
        (:add
         (dmx-import-add-topic-to-topicmap
          resolved-client
          (dmx-workspace-topicmap-membership-plan-topicmap-id plan)
          (dmx-workspace-topicmap-membership-plan-topic-id plan)
          (dmx-workspace-topicmap-membership-plan-view-props plan)))
        (:set-view-props
         (dmx-import-set-topic-view-props
          resolved-client
          (dmx-workspace-topicmap-membership-plan-topicmap-id plan)
          (dmx-workspace-topicmap-membership-plan-topic-id plan)
          (dmx-workspace-topicmap-membership-plan-view-props plan)))))
    (append (dmx-workspace-topicmap-membership-plan-summary plan)
            (list :dry-run dry-run))))

(defun plan-dmx-workspace-topicmap-context-remove
    (topic-id &key workspace-topicmap-id client)
  (let* ((resolved-topic-id
           (normalize-dmx-workspace-topic-id
            topic-id
            :topic-id
            'plan-dmx-workspace-topicmap-context-remove
            :required? t))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (topic (dmx-import-read-topic resolved-client resolved-topic-id)))
    (unless topic
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "Cannot unlink missing DMX topic ~D from workspace topicmap ~D"
                              resolved-topic-id
                              resolved-topicmap-id)))
    (let ((in-topicmap-p
            (dmx-import-topic-in-topicmap-p resolved-client
                                           resolved-topicmap-id
                                           resolved-topic-id))
         (live-supported-p
            (typep resolved-client 'memory-dmx-import-client)))
      (make-dmx-workspace-topicmap-membership-plan
       :operation :workspace-topicmap-context-remove
       :topicmap-id resolved-topicmap-id
       :topic-id resolved-topic-id
       :topic-uri (dmx-json-object-value topic "uri")
       :topic-title (dmx-workspace-topic-title topic)
       :in-topicmap-p in-topicmap-p
       :topicmap-action (if in-topicmap-p :remove :already-absent)
       :view-props nil
       :view-props-normalization nil
       :intended-method :delete
       :intended-endpoint
       (dmx-topicmap-add-topic-path resolved-topicmap-id resolved-topic-id)
       :live-supported-p live-supported-p
       :support-reason
       (if live-supported-p
           "Memory client supports typed topicmap unlink for smoke coverage."
           "Live HTTP unlink is intentionally unsupported until DELETE on /topicmaps/<topicmap>/<topic> is proven.")))))

(defun execute-dmx-workspace-topicmap-context-remove
    (topic-id &key workspace-topicmap-id client (dry-run t))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-dmx-workspace-topicmap-context-remove
                topic-id
                :workspace-topicmap-id workspace-topicmap-id
                :client resolved-client)))
    (unless dry-run
      (unless (dmx-workspace-topicmap-membership-plan-live-supported-p plan)
        (error 'dmx-import-unsupported-operation-error
               :message
               (dmx-workspace-topicmap-membership-plan-support-reason plan)
               :operation :remove-topic-from-topicmap
               :endpoint
               (dmx-workspace-topicmap-membership-plan-intended-endpoint plan)
               :reason
               (dmx-workspace-topicmap-membership-plan-support-reason plan)))
      (when (eql (dmx-workspace-topicmap-membership-plan-topicmap-action plan) :remove)
        (dmx-import-remove-topic-from-topicmap
         resolved-client
         (dmx-workspace-topicmap-membership-plan-topicmap-id plan)
         (dmx-workspace-topicmap-membership-plan-topic-id plan))))
    (append (dmx-workspace-topicmap-membership-plan-summary plan)
            (list :dry-run dry-run))))

(defun plan-dmx-workspace-topic-delete
    (topic-id &key workspace-topicmap-id client note-key note-kind)
  (let* ((resolved-topic-id
           (normalize-dmx-workspace-topic-id
            topic-id
            :topic-id
            'plan-dmx-workspace-topic-delete
            :required? t))
         (resolved-topicmap-id
           (and workspace-topicmap-id
                (normalize-required-workspace-topicmap-id workspace-topicmap-id)))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (topic (dmx-import-read-topic resolved-client resolved-topic-id)))
    (unless topic
      (error 'fedwiki-dmx-import-error
             :message (format nil "Cannot delete missing DMX topic ~D"
                              resolved-topic-id)))
    (let* ((ownership (classify-dmx-workspace-topic-ownership topic))
           (allowed-actions
             (dmx-workspace-topic-allowed-delete-actions ownership
                                                         resolved-topicmap-id))
           (in-topicmap-p
             (and resolved-topicmap-id
                  (dmx-import-topic-in-topicmap-p resolved-client
                                                 resolved-topicmap-id
                                                 resolved-topic-id))))
      (unless (member :hard-delete allowed-actions)
        (error 'dmx-workspace-topic-ownership-error
               :message
               (format nil
                       "Hard delete is limited to HyperDoc-owned workspace notes, handovers, and topic-factory snippet twins; topic ~D is ~A"
                       resolved-topic-id
                       (dmx-workspace-topic-ownership-class ownership))
               :topic-id resolved-topic-id
               :ownership-class (dmx-workspace-topic-ownership-class ownership)
               :uri (dmx-workspace-topic-ownership-uri ownership)
               :allowed-actions allowed-actions))
      (make-dmx-workspace-topic-delete-plan
       :operation :workspace-topic-delete
       :topic-id resolved-topic-id
       :note-key note-key
       :note-kind note-kind
       :workspace-topicmap-id resolved-topicmap-id
       :topic-uri (dmx-json-object-value topic "uri")
       :topic-type-uri (dmx-json-object-value topic "typeUri")
       :topic-title (dmx-workspace-topic-title topic)
       :in-topicmap-p in-topicmap-p
       :ownership ownership
       :delete-action :hard-delete
       :intended-method :delete
       :intended-endpoint (dmx-topic-update-path resolved-topic-id)))))

(defun execute-dmx-workspace-topic-delete
    (topic-id &key workspace-topicmap-id client (dry-run t))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-dmx-workspace-topic-delete
                topic-id
                :workspace-topicmap-id workspace-topicmap-id
                :client resolved-client)))
    (unless dry-run
      (dmx-import-delete-topic resolved-client
                               (dmx-workspace-topic-delete-plan-topic-id plan)))
    (append (dmx-workspace-topic-delete-plan-summary plan)
            (list :dry-run dry-run))))

(defun plan-dmx-workspace-note-delete
    (&key note-key topic-id note-kind workspace-topicmap-id client)
  (let* ((resolved-note-kind
           (normalize-dmx-workspace-note-kind-designator
            note-kind
            'plan-dmx-workspace-note-delete))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id)))
    (cond
      (topic-id
       (let* ((plan (plan-dmx-workspace-topic-delete
                     topic-id
                     :workspace-topicmap-id resolved-topicmap-id
                     :client resolved-client
                     :note-kind resolved-note-kind))
              (ownership-class
                (dmx-workspace-topic-ownership-class
                 (dmx-workspace-topic-delete-plan-ownership plan))))
         (unless (member ownership-class
                         '(:hyperdoc-workspace-note :hyperdoc-handover))
           (error 'dmx-workspace-topic-ownership-error
                  :message
                  (format nil "DMX note delete requires a HyperDoc-owned note or handover, got ~A"
                          ownership-class)
                  :topic-id (dmx-workspace-topic-delete-plan-topic-id plan)
                  :ownership-class ownership-class
                  :uri (dmx-workspace-topic-delete-plan-topic-uri plan)
                  :allowed-actions '(:hard-delete)))
         plan))
      (t
       (let* ((resolved-note-key
                (normalize-dmx-workspace-topic-string
                 note-key
                 :note-key
                 'plan-dmx-workspace-note-delete
                 :required? t))
              (resolution
                (resolve-dmx-workspace-note
                 :workspace-topicmap-id resolved-topicmap-id
                 :client resolved-client
                 :note-key resolved-note-key
                 :note-kind resolved-note-kind))
              (resolved-topic-id
                (dmx-workspace-note-resolution-existing-topic-id resolution)))
         (unless resolved-topic-id
           (error 'fedwiki-dmx-import-error
                  :message (format nil
                                   "Cannot delete missing HyperDoc note ~A"
                                   resolved-note-key)))
         (plan-dmx-workspace-topic-delete
          resolved-topic-id
          :workspace-topicmap-id resolved-topicmap-id
          :client resolved-client
          :note-key resolved-note-key
          :note-kind resolved-note-kind))))))

(defun execute-dmx-workspace-note-delete
    (&key note-key topic-id note-kind workspace-topicmap-id client (dry-run t))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-dmx-workspace-note-delete
                :note-key note-key
                :topic-id topic-id
                :note-kind note-kind
                :workspace-topicmap-id workspace-topicmap-id
                :client resolved-client)))
    (unless dry-run
      (dmx-import-delete-topic resolved-client
                               (dmx-workspace-topic-delete-plan-topic-id plan)))
    (append (dmx-workspace-topic-delete-plan-summary plan)
            (list :dry-run dry-run))))

(defun execute-dmx-workspace-topic-factory-snippet-upsert
    (&key snippet-id snippet-text source-path source-origin-id source-origin-path
       related-hyperdoc-page-title related-topic-id references provenance
       workspace-topicmap-id client (dry-run t) topic-type-uri view-props
       topic-value)
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (definition
           (make-mcp-topic-factory-snippet-definition
            :snippet-id snippet-id
            :snippet-text snippet-text
            :source-path source-path
            :workspace-topicmap-id workspace-topicmap-id
            :references (normalize-dmx-workspace-topic-references references)
            :related-hyperdoc-page-title related-hyperdoc-page-title
            :related-topic-id related-topic-id
            :source-origin-id source-origin-id
            :source-origin-path source-origin-path
            :provenance provenance))
         (stream (make-string-output-stream))
         (result
           (execute-topic-factory-snippet-dmx-write
            definition
            :workspace-topicmap-id workspace-topicmap-id
            :client resolved-client
            :dry-run dry-run
            :topic-type-uri topic-type-uri
            :view-props view-props
            :topic-value topic-value
            :stream stream))
         (execution-log (get-output-stream-string stream))
         (plan (getf result :plan))
         (existing-topic
           (dmx-import-find-existing-topic
            resolved-client
            (topic-factory-snippet-dmx-write-plan-uri plan)))
         (topic-id
           (dmx-import-object-id existing-topic)))
    (declare (ignore execution-log))
    (list :operation :workspace-topic-factory-snippet-upsert
          :dry-run dry-run
          :topic-id topic-id
          :snippet-id (topic-factory-snippet-dmx-write-plan-snippet-id plan)
          :uri (topic-factory-snippet-dmx-write-plan-uri plan)
          :workspace-topicmap-id
          (topic-factory-snippet-dmx-write-plan-workspace-topicmap-id plan)
          :topic-action
          (topic-factory-snippet-dmx-write-plan-topic-action plan)
          :topicmap-action
          (topic-factory-snippet-dmx-write-plan-topicmap-action plan)
          :topic-type-uri
          (topic-factory-snippet-dmx-write-plan-topic-type-uri plan)
          :topic-value
          (topic-factory-snippet-dmx-write-plan-topic-value plan)
          :source-path
          (topic-factory-snippet-dmx-write-plan-source-path plan)
          :related-hyperdoc-page-title
          (topic-factory-snippet-dmx-write-plan-related-hyperdoc-page-title plan)
          :related-topic-id
          (topic-factory-snippet-dmx-write-plan-related-topic-id plan)
          :view-props-validation-status
          (getf (topic-factory-snippet-dmx-write-plan-view-props-normalization plan)
                :status)
          :normalized-view-props-json
          (dmx-topicmap-view-props-json-string
           (topic-factory-snippet-dmx-write-plan-view-props plan)))))
