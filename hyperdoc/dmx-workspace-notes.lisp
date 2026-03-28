;;;; Narrow DMX workspace-note writer for MCP and guarded handovers
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(define-condition dmx-workspace-note-validation-error (fedwiki-dmx-import-error)
  ((boundary :reader dmx-workspace-note-validation-boundary-of :initarg :boundary)
   (payload :reader dmx-workspace-note-validation-payload-of :initarg :payload)
   (missing-fields
    :reader dmx-workspace-note-validation-missing-fields-of
    :initarg :missing-fields
    :initform nil)
   (invalid-fields
    :reader dmx-workspace-note-validation-invalid-fields-of
    :initarg :invalid-fields
    :initform nil))
  (:report (lambda (condition stream)
             (format stream "~A"
                     (fedwiki-dmx-import-message-of condition)))))

(defstruct dmx-workspace-note-write-plan
  operation
  note-kind
  note-key
  uri
  workspace-topicmap-id
  title
  text
  view-props
  view-props-normalization
  payload-validation-status
  topic-action
  topicmap-action
  payload
  existing-topic
  existing-topic-id)

(defstruct dmx-workspace-note-resolution
  note-kind
  note-key
  uri
  workspace-topicmap-id
  existing-topic
  existing-topic-id
  in-topicmap-p
  topic-action
  topicmap-action)

(defun dmx-json-object-value (object key)
  (cond
    ((hash-table-p object)
     (gethash key object))
    ((listp object)
     (or (getf object (intern (string-upcase key) :keyword))
         (getf object (intern (string-upcase
                               (substitute #\- #\_ key))
                              :keyword))))
    (t
     nil)))

(defun dmx-json-child-value (topic child-type-uri)
  (let ((children (dmx-json-object-value topic "children")))
    (cond
      ((hash-table-p children)
       (let ((child (gethash child-type-uri children)))
         (cond
           ((hash-table-p child)
            (gethash "value" child))
           (t
            child))))
      ((listp children)
       (getf children (intern (string-upcase child-type-uri) :keyword)))
      (t
       nil))))

(defun dmx-non-empty-string-p (value)
  (and (stringp value)
       (plusp (length (string-trim '(#\Space #\Tab #\Newline #\Return) value)))))

(defun dmx-workspace-note-validation-message (boundary missing-fields invalid-fields)
  (with-output-to-string (stream)
    (format stream "DMX workspace note validation failed at ~A" boundary)
    (when missing-fields
      (format stream "; missing fields: ~{~A~^, ~}" missing-fields))
    (when invalid-fields
      (format stream "; invalid fields: ~{~A~^, ~}" invalid-fields))))

(defun normalize-dmx-workspace-note-string (value field boundary &key required?)
  (cond
    ((null value)
     (when required?
       (error 'dmx-workspace-note-validation-error
              :message (dmx-workspace-note-validation-message boundary
                                                              (list field)
                                                              nil)
              :boundary boundary
              :payload (list field value)
              :missing-fields (list field)))
     nil)
    ((dmx-non-empty-string-p value)
     (string-trim '(#\Space #\Tab #\Newline #\Return) value))
    (t
     (error 'dmx-workspace-note-validation-error
            :message (dmx-workspace-note-validation-message boundary
                                                            nil
                                                            (list field))
            :boundary boundary
            :payload (list field value)
            :invalid-fields (list field)))))

(defun normalize-dmx-workspace-note-key (note-key title note-kind)
  (labels ((slug (string)
             (string-trim
              "-"
              (with-output-to-string (stream)
                (loop with lowered = (string-downcase string)
                      with previous-hyphen? = nil
                      for char across lowered
                      do (cond
                           ((or (alphanumericp char)
                                (char= char #\_))
                            (write-char char stream)
                            (setf previous-hyphen? nil))
                           ((or (char= char #\Space)
                                (char= char #\/)
                                (char= char #\-)
                                (char= char #\:))
                            (unless previous-hyphen?
                              (write-char #\- stream))
                            (setf previous-hyphen? t))))))))
    (cond
      ((dmx-non-empty-string-p note-key)
       (normalize-dmx-workspace-note-string
        note-key
        :note-key
        'normalize-dmx-workspace-note-key
        :required? t))
      (t
       (let ((title-fragment (or (slug title) "note")))
         (format nil "~(~A~)-~A-~D"
                 note-kind
                 title-fragment
                 (get-universal-time)))))))

(defun dmx-workspace-note-uri (note-kind note-key)
  (format nil "hyperdoc:mcp/~(~A~)/~A" note-kind note-key))

(defun make-dmx-workspace-note-children (&key title text)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash *dmx-notes-title-type-uri* children) title
          (gethash *dmx-notes-text-type-uri* children) text)
    children))

(defun dmx-workspace-note-payload (title text uri)
  (list :uri uri
        :external-key uri
        :type-uri *dmx-notes-note-type-uri*
        :value title
        :children (make-dmx-workspace-note-children :title title :text text)))

(defun normalize-dmx-workspace-note-view-props (view-props boundary)
  (if view-props
      (normalize-dmx-topicmap-view-props view-props :boundary boundary)
      (values
       (make-dmx-topicmap-view-props-json-object
        :x (getf *topic-factory-snippet-dmx-default-view-props* :x)
        :y (getf *topic-factory-snippet-dmx-default-view-props* :y)
        :visibility (getf *topic-factory-snippet-dmx-default-view-props* :visibility)
        :pinned (getf *topic-factory-snippet-dmx-default-view-props* :pinned))
       (list :status :canonical
             :forbidden-short-keys nil))))

(defun dmx-workspace-note-plan-summary (plan)
  (list :operation (dmx-workspace-note-write-plan-operation plan)
        :note-kind (dmx-workspace-note-write-plan-note-kind plan)
        :note-key (dmx-workspace-note-write-plan-note-key plan)
        :uri (dmx-workspace-note-write-plan-uri plan)
        :workspace-topicmap-id (dmx-workspace-note-write-plan-workspace-topicmap-id plan)
        :title (dmx-workspace-note-write-plan-title plan)
        :payload-validation-status
        (dmx-workspace-note-write-plan-payload-validation-status plan)
        :topic-action (dmx-workspace-note-write-plan-topic-action plan)
        :topicmap-action (dmx-workspace-note-write-plan-topicmap-action plan)
        :existing-topic-id (dmx-workspace-note-write-plan-existing-topic-id plan)
        :normalized-view-props-json
        (and (dmx-workspace-note-write-plan-view-props plan)
             (dmx-topicmap-view-props-json-string
              (dmx-workspace-note-write-plan-view-props plan)))))

(defun resolve-dmx-workspace-note
    (&key workspace-topicmap-id client note-key title uri (note-kind :workspace-note))
  (let* ((resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolved-note-key
           (normalize-dmx-workspace-note-key
            note-key
            (or title "workspace note")
            note-kind))
         (resolved-uri
           (or uri
               (dmx-workspace-note-uri note-kind resolved-note-key)))
         (existing-topic
           (dmx-import-find-existing-topic resolved-client resolved-uri))
         (existing-topic-id (dmx-import-object-id existing-topic))
         (in-topicmap-p
           (and existing-topic-id
                (dmx-import-topic-in-topicmap-p resolved-client
                                               resolved-topicmap-id
                                               existing-topic-id))))
    (make-dmx-workspace-note-resolution
     :note-kind note-kind
     :note-key resolved-note-key
     :uri resolved-uri
     :workspace-topicmap-id resolved-topicmap-id
     :existing-topic existing-topic
     :existing-topic-id existing-topic-id
     :in-topicmap-p in-topicmap-p
     :topic-action (if existing-topic :update :create)
     :topicmap-action (if in-topicmap-p :already-present :add))))

(defun plan-dmx-workspace-note-write
    (title
     text
     &key workspace-topicmap-id client view-props note-key uri
          (note-kind :workspace-note))
  (let* ((resolved-title
           (normalize-dmx-workspace-note-string
            title
            :title
            'plan-dmx-workspace-note-write
            :required? t))
         (resolved-text
           (normalize-dmx-workspace-note-string
            text
            :text
            'plan-dmx-workspace-note-write
            :required? t))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolution
           (resolve-dmx-workspace-note
            :workspace-topicmap-id resolved-topicmap-id
            :client resolved-client
            :note-key note-key
            :title resolved-title
            :uri uri
            :note-kind note-kind))
         (resolved-note-key
           (dmx-workspace-note-resolution-note-key resolution))
         (resolved-uri
           (dmx-workspace-note-resolution-uri resolution))
         (payload (dmx-workspace-note-payload resolved-title
                                              resolved-text
                                              resolved-uri))
         (existing-topic
           (dmx-workspace-note-resolution-existing-topic resolution))
         (existing-topic-id
           (dmx-workspace-note-resolution-existing-topic-id resolution))
         (in-topicmap-p
           (dmx-workspace-note-resolution-in-topicmap-p resolution)))
    (multiple-value-bind (resolved-view-props view-props-normalization)
        (normalize-dmx-workspace-note-view-props
         view-props
         'plan-dmx-workspace-note-write)
      (make-dmx-workspace-note-write-plan
       :operation :workspace-note-write
       :note-kind note-kind
       :note-key resolved-note-key
       :uri resolved-uri
       :workspace-topicmap-id resolved-topicmap-id
       :title resolved-title
       :text resolved-text
       :view-props resolved-view-props
       :view-props-normalization view-props-normalization
       :payload-validation-status :canonical
       :topic-action (if existing-topic :update :create)
       :topicmap-action (if in-topicmap-p :already-present :add)
       :payload payload
       :existing-topic existing-topic
       :existing-topic-id existing-topic-id))))

(defun execute-dmx-workspace-note-write
    (title
     text
     &key workspace-topicmap-id client view-props note-key uri
          (note-kind :workspace-note)
          (dry-run t))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-dmx-workspace-note-write
                title
                text
                :workspace-topicmap-id workspace-topicmap-id
                :client resolved-client
                :view-props view-props
                :note-key note-key
                :uri uri
                :note-kind note-kind)))
    (if dry-run
        (append (dmx-workspace-note-plan-summary plan)
                (list :dry-run t))
        (let* ((topic (ecase (dmx-workspace-note-write-plan-topic-action plan)
                        (:create
                         (dmx-import-create-topic resolved-client
                                                  (dmx-workspace-note-write-plan-payload plan)))
                        (:update
                         (dmx-import-update-topic resolved-client
                                                  (dmx-workspace-note-write-plan-existing-topic plan)
                                                  (dmx-workspace-note-write-plan-payload plan)))))
               (topic-id (dmx-import-object-id topic)))
          (when (eql (dmx-workspace-note-write-plan-topicmap-action plan) :add)
            (dmx-import-add-topic-to-topicmap
             resolved-client
             (dmx-workspace-note-write-plan-workspace-topicmap-id plan)
             topic-id
             (dmx-workspace-note-write-plan-view-props plan)))
          (append (dmx-workspace-note-plan-summary plan)
                  (list :dry-run nil
                        :topic-id topic-id))))))

(defun plan-dmx-workspace-note-update (topic-id &key title text client)
  (let* ((resolved-topic-id
           (or (parse-positive-integer topic-id)
               (error 'fedwiki-dmx-import-error
                      :message (format nil
                                       "DMX workspace note update requires a positive topic id, got ~S"
                                       topic-id))))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (existing-topic (dmx-import-read-topic resolved-client resolved-topic-id)))
    (unless existing-topic
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "Cannot update missing DMX topic ~D"
                              resolved-topic-id)))
    (unless (string= (or (dmx-json-object-value existing-topic "typeUri") "")
                     *dmx-notes-note-type-uri*)
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "DMX workspace note update requires ~A but topic ~D is ~A"
                              *dmx-notes-note-type-uri*
                              resolved-topic-id
                              (dmx-json-object-value existing-topic "typeUri"))))
    (let* ((resolved-title
             (normalize-dmx-workspace-note-string
              (or title
                  (dmx-json-child-value existing-topic *dmx-notes-title-type-uri*)
                  (dmx-json-object-value existing-topic "value"))
              :title
              'plan-dmx-workspace-note-update
              :required? t))
           (resolved-text
             (normalize-dmx-workspace-note-string
              (or text
                  (dmx-json-child-value existing-topic *dmx-notes-text-type-uri*))
              :text
              'plan-dmx-workspace-note-update
              :required? t))
           (uri (or (dmx-json-object-value existing-topic "uri")
                    (format nil "hyperdoc:mcp/workspace-note/topic-~D"
                            resolved-topic-id)))
           (payload (dmx-workspace-note-payload resolved-title resolved-text uri)))
      (make-dmx-workspace-note-write-plan
       :operation :workspace-note-update
       :note-kind :workspace-note
       :note-key nil
       :uri uri
       :workspace-topicmap-id nil
       :title resolved-title
       :text resolved-text
       :view-props nil
       :view-props-normalization nil
       :payload-validation-status :canonical
       :topic-action :update
       :topicmap-action :unchanged
       :payload payload
       :existing-topic existing-topic
       :existing-topic-id resolved-topic-id))))

(defun execute-dmx-workspace-note-update (topic-id &key title text client (dry-run t))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-dmx-workspace-note-update topic-id
                                              :title title
                                              :text text
                                              :client resolved-client)))
    (if dry-run
        (append (dmx-workspace-note-plan-summary plan)
                (list :dry-run t
                      :topic-id (dmx-workspace-note-write-plan-existing-topic-id plan)))
        (let ((topic (dmx-import-update-topic resolved-client
                                              (dmx-workspace-note-write-plan-existing-topic plan)
                                              (dmx-workspace-note-write-plan-payload plan))))
          (append (dmx-workspace-note-plan-summary plan)
                  (list :dry-run nil
                        :topic-id (dmx-import-object-id topic)))))))

(defun dmx-workspace-handover-body
    (&key from-agent to-agent summary requested-action artifacts status)
  (with-output-to-string (stream)
    (format stream "From: ~A~%To: ~A~%Status: ~A~%~%"
            (or from-agent "Codex")
            (or to-agent "ChatGPT")
            (or status "open"))
    (format stream "Summary~%~A~%~%" summary)
    (when (dmx-non-empty-string-p requested-action)
      (format stream "Requested action~%~A~%~%" requested-action))
    (when artifacts
      (format stream "Artifacts~%")
      (dolist (artifact artifacts)
        (format stream "- ~A~%" artifact)))))

(defun create-dmx-workspace-handover
    (title
     summary
     &key from-agent to-agent requested-action artifacts status
          workspace-topicmap-id client view-props note-key uri
          (dry-run t))
  (let ((resolved-title
          (normalize-dmx-workspace-note-string
           title
           :title
           'create-dmx-workspace-handover
           :required? t))
        (resolved-summary
          (normalize-dmx-workspace-note-string
           summary
           :summary
           'create-dmx-workspace-handover
           :required? t)))
    (execute-dmx-workspace-note-write
     resolved-title
     (dmx-workspace-handover-body
      :from-agent from-agent
      :to-agent to-agent
      :summary resolved-summary
      :requested-action requested-action
      :artifacts artifacts
      :status status)
     :workspace-topicmap-id workspace-topicmap-id
     :client client
     :view-props view-props
     :note-key note-key
     :uri uri
     :note-kind :handover
     :dry-run dry-run)))
