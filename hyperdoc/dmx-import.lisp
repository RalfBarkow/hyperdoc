;;;; FedWiki-to-DMX importer
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defparameter *fedwiki-import-source-kind* "fedwiki-page")
(defparameter *fedwiki-summary-paragraph-types*
  '("paragraph" "markdown" "reference"))
(defparameter *dmx-fedwiki-page-type-uri* "fedwiki.page")
(defparameter *dmx-fedwiki-slug-type-uri* "fedwiki.slug")
(defparameter *dmx-fedwiki-title-type-uri* "fedwiki.title")
(defparameter *dmx-fedwiki-page-json-type-uri* "fedwiki.page.json")
(defparameter *dmx-topic-fetch-query-string* "children=true&assocChildren=true")
(defparameter *base64-alphabet*
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
(defparameter *dmx-workspace-assignment-rehearsal-snapshot-kind*
  "hyperdoc.workspace_assignment_repair_snapshot")
(defparameter *http-dmx-import-evidence-body-prefix-limit* 2048)
(defparameter *http-dmx-import-debug-event-limit* 32)

;; The journal implementation file is loaded after several guarded write
;; helpers. Declare the dynamic boundary variables here so those helpers compile
;; cleanly while the later implementation remains the authority for defaults.
(defvar *workspace-journal-sink* :hyperdoc-local)
(defvar *allow-dmx-workspace-journal-writes* nil)

(define-condition fedwiki-dmx-import-error (error)
  ((message :reader fedwiki-dmx-import-message-of :initarg :message))
  (:report (lambda (condition stream)
             (format stream "~A"
                     (fedwiki-dmx-import-message-of condition)))))

(define-condition duplicate-fedwiki-import-key (fedwiki-dmx-import-error)
  ((external-key :reader duplicate-fedwiki-import-key-of :initarg :external-key))
  (:report (lambda (condition stream)
             (format stream "Duplicate FedWiki import key in one run: ~A"
                     (duplicate-fedwiki-import-key-of condition)))))

(define-condition dmx-import-config-error (fedwiki-dmx-import-error)
  ((missing-keys :reader dmx-import-missing-keys-of :initarg :missing-keys))
  (:report (lambda (condition stream)
             (format stream "Missing DMX import configuration: ~{~A~^, ~}"
                     (dmx-import-missing-keys-of condition)))))

(define-condition dmx-import-http-error (fedwiki-dmx-import-error)
  ((url :reader dmx-import-http-url-of :initarg :url)
   (status-code :reader dmx-import-http-status-code-of :initarg :status-code)
   (response-body :reader dmx-import-http-response-body-of :initarg :response-body)
   (evidence :reader dmx-import-http-evidence-of
             :initarg :evidence
             :initform nil))
  (:report (lambda (condition stream)
             (format stream "DMX import HTTP failure ~A for ~A"
                     (dmx-import-http-status-code-of condition)
                     (dmx-import-http-url-of condition)))))

(define-condition dmx-import-unsupported-operation-error (fedwiki-dmx-import-error)
  ((operation :reader dmx-import-unsupported-operation-of :initarg :operation)
   (endpoint :reader dmx-import-unsupported-endpoint-of
             :initarg :endpoint
             :initform nil)
   (reason :reader dmx-import-unsupported-reason-of
           :initarg :reason
           :initform nil))
  (:report (lambda (condition stream)
             (format stream "~A"
                     (fedwiki-dmx-import-message-of condition)))))

(define-condition dmx-topicmap-view-props-validation-error (fedwiki-dmx-import-error)
  ((boundary
    :reader dmx-topicmap-view-props-validation-boundary-of
    :initarg :boundary)
   (payload
    :reader dmx-topicmap-view-props-validation-payload-of
    :initarg :payload)
   (normalized-payload
    :reader dmx-topicmap-view-props-validation-normalized-payload-of
    :initarg :normalized-payload
    :initform nil)
   (missing-long-keys
    :reader dmx-topicmap-view-props-validation-missing-long-keys-of
    :initarg :missing-long-keys
    :initform nil)
   (forbidden-short-keys
    :reader dmx-topicmap-view-props-validation-forbidden-short-keys-of
    :initarg :forbidden-short-keys
    :initform nil)
   (unknown-keys
    :reader dmx-topicmap-view-props-validation-unknown-keys-of
    :initarg :unknown-keys
    :initform nil)
   (duplicate-fields
    :reader dmx-topicmap-view-props-validation-duplicate-fields-of
    :initarg :duplicate-fields
    :initform nil)
   (invalid-field-types
    :reader dmx-topicmap-view-props-validation-invalid-field-types-of
    :initarg :invalid-field-types
    :initform nil))
  (:report (lambda (condition stream)
             (format stream "~A"
                     (fedwiki-dmx-import-message-of condition)))))

(defstruct fedwiki-import-candidate
  external-key
  domain
  slug
  title
  canonical-html-url
  canonical-json-url
  summary
  source-kind
  page-json
  raw-journal-timestamp
  last-sync-timestamp)

(defstruct dmx-import-plan-entry
  action
  external-key
  candidate
  payload
  existing-topic)

(defclass dmx-import-client () ())

(defclass null-dmx-import-client (dmx-import-client) ())

(defclass memory-dmx-import-client (dmx-import-client)
  ((topics-by-external-key
    :reader topics-by-external-key-of
    :initarg :topics-by-external-key
    :initform (make-hash-table :test #'equal))
   (topicmap-memberships
    :reader topicmap-memberships-of
    :initarg :topicmap-memberships
    :initform (make-hash-table :test #'equal))
   (workspace-assignments
    :reader workspace-assignments-of
    :initarg :workspace-assignments
    :initform (make-hash-table :test #'eql))
   (next-topic-id
    :accessor next-topic-id-of
    :initarg :next-topic-id
    :initform 1000)))

(defclass http-dmx-import-client (dmx-import-client)
  ((base-url :reader dmx-import-base-url-of :initarg :base-url :initform nil)
   (authorization-header
    :reader dmx-import-authorization-header-of
    :initarg :authorization-header
    :initform nil)
   (session-cookie
    :accessor dmx-import-session-cookie-of
    :initarg :session-cookie
    :initform nil)
   (session-login-required-p
    :reader dmx-import-session-login-required-p-of
    :initarg :session-login-required-p
    :initform nil)
   (bootstrap-session-p
    :reader dmx-import-bootstrap-session-p-of
    :initarg :bootstrap-session-p
    :initform nil)
   (derived-auth-scheme
    :reader dmx-import-derived-auth-scheme-of
    :initarg :derived-auth-scheme
    :initform nil)
   (debug-events
    :accessor dmx-import-debug-events-of
    :initarg :debug-events
    :initform nil)
   (last-http-transaction-evidence
    :accessor dmx-import-last-http-transaction-evidence-of
    :initarg :last-http-transaction-evidence
    :initform nil)
   (workspace-id
    :reader dmx-import-workspace-id-of
    :initarg :workspace-id
    :initform nil)
   (topic-type-uri :reader dmx-import-topic-type-uri-of
                   :initarg :topic-type-uri
                   :initform *dmx-fedwiki-page-type-uri*)
   (verbose :reader dmx-import-verbose-of :initarg :verbose :initform nil)))

(defgeneric dmx-import-find-existing-topic (client external-key))
(defgeneric dmx-import-read-topic (client topic-id))
(defgeneric dmx-import-read-topicmap (client topicmap-id))
(defgeneric dmx-import-read-topic-workspace (client topic-id))
(defgeneric dmx-import-create-topic (client payload))
(defgeneric dmx-import-update-topic (client existing-topic payload))
(defgeneric dmx-import-assign-topic-to-workspace (client workspace-id topic-id))
(defgeneric dmx-import-topic-in-topicmap-p (client topicmap-id topic-id))
(defgeneric dmx-import-add-topic-to-topicmap (client topicmap-id topic-id view-props))
(defgeneric dmx-import-set-topic-view-props (client topicmap-id topic-id view-props))
(defgeneric dmx-import-remove-topic-from-topicmap (client topicmap-id topic-id))
(defgeneric dmx-import-delete-topic (client topic-id))

(defparameter *dmx-topicmap-view-prop-specs*
  '((:field :x
     :long-key "dmx.topicmaps.x"
     :short-key "x"
     :type-label "integer")
    (:field :y
     :long-key "dmx.topicmaps.y"
     :short-key "y"
     :type-label "integer")
    (:field :visibility
     :long-key "dmx.topicmaps.visibility"
     :short-key "visibility"
     :type-label "boolean")
    (:field :pinned
     :long-key "dmx.topicmaps.pinned"
     :short-key "pinned"
     :type-label "boolean")))

(defun dmx-topicmap-view-prop-spec-by-field (field)
  (find field
        *dmx-topicmap-view-prop-specs*
        :test #'eq
        :key (lambda (spec) (getf spec :field))))

(defun dmx-topicmap-view-prop-spec-by-key-name (key-name)
  (find key-name
        *dmx-topicmap-view-prop-specs*
        :test #'string=
        :key (lambda (spec)
               (or (and (string= key-name (getf spec :long-key))
                        (getf spec :long-key))
                   (and (string= key-name (getf spec :short-key))
                        (getf spec :short-key))))))

(defun dmx-topicmap-view-prop-key-name (key)
  (cond
    ((stringp key)
     (string-downcase key))
    ((symbolp key)
     (string-downcase (symbol-name key)))
    (t
     nil)))

(defun dmx-topicmap-view-prop-entries (view-props boundary)
  (cond
    ((hash-table-p view-props)
     (loop for key being the hash-keys of view-props using (hash-value value)
           collect (cons key value)))
    ((listp view-props)
     (unless (evenp (length view-props))
       (error 'dmx-topicmap-view-props-validation-error
              :message (format nil
                               "DMX topicmap view-props validation failed at ~A; property list has odd length"
                               boundary)
              :boundary boundary
              :payload view-props))
     (loop for (key value) on view-props by #'cddr
           collect (cons key value)))
    (t
     (error 'dmx-topicmap-view-props-validation-error
            :message (format nil
                             "DMX topicmap view-props validation failed at ~A; unsupported payload type ~S"
                             boundary
                             (type-of view-props))
            :boundary boundary
            :payload view-props))))

(defun dmx-topicmap-view-prop-boolean-p (value)
  (or (eq value t)
      (null value)))

(defun dmx-topicmap-view-prop-valid-type-p (field value)
  (ecase field
    (:x (integerp value))
    (:y (integerp value))
    (:visibility (dmx-topicmap-view-prop-boolean-p value))
    (:pinned (dmx-topicmap-view-prop-boolean-p value))))

(defun make-dmx-topicmap-view-props-json-object (&key x y visibility pinned)
  (let ((json (make-hash-table :test #'equal)))
    (setf (gethash "dmx.topicmaps.x" json) x
          (gethash "dmx.topicmaps.y" json) y
          (gethash "dmx.topicmaps.visibility" json) visibility
          (gethash "dmx.topicmaps.pinned" json) pinned)
    json))

(defun dmx-topicmap-view-props-value (view-props field)
  (gethash (getf (dmx-topicmap-view-prop-spec-by-field field) :long-key)
           view-props))

(defun dmx-topicmap-view-props-json-string (view-props)
  (format nil
          "{\"dmx.topicmaps.x\":~D,\"dmx.topicmaps.y\":~D,\"dmx.topicmaps.visibility\":~:[false~;true~],\"dmx.topicmaps.pinned\":~:[false~;true~]}"
          (dmx-topicmap-view-props-value view-props :x)
          (dmx-topicmap-view-props-value view-props :y)
          (dmx-topicmap-view-props-value view-props :visibility)
          (dmx-topicmap-view-props-value view-props :pinned)))

(defun dmx-topicmap-view-props-validation-message
    (boundary missing-long-keys forbidden-short-keys unknown-keys duplicate-fields invalid-field-types)
  (with-output-to-string (stream)
    (format stream
            "DMX topicmap view-props validation failed at ~A"
            boundary)
    (when missing-long-keys
      (format stream
              "; missing long-form keys: ~{~A~^, ~}"
              missing-long-keys))
    (when forbidden-short-keys
      (format stream
              "; forbidden short keys: ~{~A~^, ~}"
              forbidden-short-keys))
    (when unknown-keys
      (format stream
              "; unknown keys: ~{~A~^, ~}"
              unknown-keys))
    (when duplicate-fields
      (format stream
              "; duplicate fields: ~{~A~^, ~}"
              duplicate-fields))
    (when invalid-field-types
      (format stream
              "; invalid field types: ~{~A~^, ~}"
              invalid-field-types))))

(defun normalize-dmx-topicmap-view-props (view-props &key boundary)
  (let ((values (make-hash-table :test #'eq))
        (seen-fields (make-hash-table :test #'eq))
        (forbidden-short-keys '())
        (unknown-keys '())
        (duplicate-fields '()))
    (dolist (entry (dmx-topicmap-view-prop-entries view-props boundary))
      (let* ((raw-key (car entry))
             (value (cdr entry))
             (key-name (dmx-topicmap-view-prop-key-name raw-key))
             (spec (and key-name
                        (dmx-topicmap-view-prop-spec-by-key-name key-name))))
        (cond
          ((null key-name)
           (push (format nil "~S" raw-key) unknown-keys))
          ((null spec)
           (push key-name unknown-keys))
          (t
           (let ((field (getf spec :field)))
             (when (string= key-name (getf spec :short-key))
               (pushnew key-name forbidden-short-keys :test #'string=))
             (if (gethash field seen-fields)
                 (pushnew (string-downcase (symbol-name field))
                          duplicate-fields
                          :test #'string=)
                 (setf (gethash field values) value
                       (gethash field seen-fields) t)))))))
    (let* ((missing-long-keys
             (loop for spec in *dmx-topicmap-view-prop-specs*
                   for field = (getf spec :field)
                   unless (gethash field seen-fields)
                     collect (getf spec :long-key)))
           (invalid-field-types
             (loop for spec in *dmx-topicmap-view-prop-specs*
                   for field = (getf spec :field)
                   for value = (gethash field values)
                   when (and (gethash field seen-fields)
                             (not (dmx-topicmap-view-prop-valid-type-p field value)))
                     collect (format nil
                                     "~A expected ~A but got ~S"
                                     (getf spec :long-key)
                                     (getf spec :type-label)
                                     value)))
           (normalized-payload
             (make-dmx-topicmap-view-props-json-object
              :x (gethash :x values)
              :y (gethash :y values)
              :visibility (gethash :visibility values)
              :pinned (gethash :pinned values))))
      (when (or missing-long-keys
                forbidden-short-keys
                unknown-keys
                duplicate-fields
                invalid-field-types)
        (error 'dmx-topicmap-view-props-validation-error
               :message (dmx-topicmap-view-props-validation-message
                         boundary
                         missing-long-keys
                         forbidden-short-keys
                         unknown-keys
                         duplicate-fields
                         invalid-field-types)
               :boundary boundary
               :payload view-props
               :normalized-payload normalized-payload
               :missing-long-keys missing-long-keys
               :forbidden-short-keys forbidden-short-keys
               :unknown-keys unknown-keys
               :duplicate-fields duplicate-fields
               :invalid-field-types invalid-field-types))
      (values normalized-payload
              (list :status :canonical
                    :forbidden-short-keys nil)))))

(defun dmx-import-object-id (topic)
  (cond
    ((hash-table-p topic)
     (or (gethash "id" topic)
         (when-let (nested (gethash "topic" topic))
           (and (hash-table-p nested)
                (gethash "id" nested)))))
    ((listp topic)
     (or (getf topic :id)
         (when-let (nested (getf topic :topic))
           (and (listp nested)
                (getf nested :id)))))
    (t
     nil)))

(defun memory-topicmap-membership-key (topicmap-id topic-id)
  (list topicmap-id topic-id))

(defmethod dmx-import-find-existing-topic ((client null-dmx-import-client) external-key)
  (declare (ignore external-key))
  nil)

(defmethod dmx-import-read-topic ((client null-dmx-import-client) topic-id)
  (declare (ignore topic-id))
  nil)

(defmethod dmx-import-read-topicmap ((client null-dmx-import-client) topicmap-id)
  (declare (ignore topicmap-id))
  nil)

(defmethod dmx-import-read-topic-workspace ((client null-dmx-import-client) topic-id)
  (declare (ignore topic-id))
  nil)

(defmethod dmx-import-create-topic ((client null-dmx-import-client) payload)
  (declare (ignore payload))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live writes"))

(defmethod dmx-import-update-topic ((client null-dmx-import-client) existing-topic payload)
  (declare (ignore existing-topic payload))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live writes"))

(defmethod dmx-import-assign-topic-to-workspace ((client null-dmx-import-client)
                                                 workspace-id topic-id)
  (declare (ignore workspace-id topic-id))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live workspace assignment writes"))

(defmethod dmx-import-topic-in-topicmap-p ((client null-dmx-import-client) topicmap-id topic-id)
  (declare (ignore topicmap-id topic-id))
  nil)

(defmethod dmx-import-add-topic-to-topicmap ((client null-dmx-import-client) topicmap-id topic-id view-props)
  (declare (ignore topicmap-id topic-id view-props))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live topicmap writes"))

(defmethod dmx-import-set-topic-view-props ((client null-dmx-import-client) topicmap-id topic-id view-props)
  (declare (ignore topicmap-id topic-id view-props))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live topicmap writes"))

(defmethod dmx-import-remove-topic-from-topicmap ((client null-dmx-import-client) topicmap-id topic-id)
  (declare (ignore topicmap-id topic-id))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live topicmap unlink writes"))

(defmethod dmx-import-delete-topic ((client null-dmx-import-client) topic-id)
  (declare (ignore topic-id))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live deletes"))

(defmethod dmx-import-find-existing-topic ((client memory-dmx-import-client) external-key)
  (gethash external-key (topics-by-external-key-of client)))

(defun memory-dmx-import-topic-payload->json (topic)
  (when topic
    (let ((json (make-hash-table :test #'equal))
          (children-json (make-hash-table :test #'equal))
          (children (getf topic :children)))
      (labels ((put (key value)
                 (setf (gethash key json) value)))
        (put "id" (dmx-import-object-id topic))
        (put "uri" (or (getf topic :uri) ""))
        (put "typeUri" (or (getf topic :type-uri) ""))
        (put "value" (getf topic :value))
        (flet ((record-child (child-type-uri child-value)
                 (let ((child-json (make-hash-table :test #'equal)))
                   (setf (gethash "id" child-json) -1
                         (gethash "uri" child-json) ""
                         (gethash "typeUri" child-json) child-type-uri
                         (gethash "value" child-json) child-value
                         (gethash "children" child-json) (make-hash-table :test #'equal))
                   (setf (gethash child-type-uri children-json) child-json))))
          (cond
            ((hash-table-p children)
             (maphash #'record-child children))
            ((listp children)
             (loop for (child-type-uri child-value) on children by #'cddr
                   do (record-child child-type-uri child-value)))))
        (setf (gethash "children" json) children-json)
        json))))

(defmethod dmx-import-read-topic ((client memory-dmx-import-client) topic-id)
  (memory-dmx-import-topic-payload->json
   (find topic-id
         (alexandria:hash-table-values (topics-by-external-key-of client))
         :key #'dmx-import-object-id
         :test #'eql)))

(defmethod dmx-import-read-topicmap ((client memory-dmx-import-client) topicmap-id)
  (let ((topicmap-topic-json (make-hash-table :test #'equal))
        (json (make-hash-table :test #'equal))
        (topics '()))
    (setf (gethash "id" topicmap-topic-json) topicmap-id
          (gethash "uri" topicmap-topic-json) ""
          (gethash "typeUri" topicmap-topic-json) "dmx.topicmaps.topicmap"
          (gethash "value" topicmap-topic-json) (format nil "Memory topicmap ~D" topicmap-id)
          (gethash "children" topicmap-topic-json) (make-hash-table :test #'equal))
    (maphash
     (lambda (membership-key view-props)
       (destructuring-bind (membership-topicmap-id topic-id) membership-key
         (when (eql membership-topicmap-id topicmap-id)
           (when-let (topic-json (dmx-import-read-topic client topic-id))
             (setf (gethash "viewProps" topic-json) view-props)
             (push topic-json topics)))))
     (topicmap-memberships-of client))
    (setf (gethash "topic" json) topicmap-topic-json
          (gethash "viewProps" json) (make-hash-table :test #'equal)
          (gethash "topics" json) (coerce (nreverse topics) 'vector)
          (gethash "assocs" json) #())
    json))

(defun memory-dmx-import-workspace-json (workspace-id)
  (let ((json (make-hash-table :test #'equal))
        (children (make-hash-table :test #'equal)))
    (setf (gethash "id" json) workspace-id
          (gethash "uri" json) ""
          (gethash "typeUri" json) "dmx.workspaces.workspace"
          (gethash "value" json) (format nil "Memory workspace ~D" workspace-id)
          (gethash "children" json) children)
    json))

(defmethod dmx-import-read-topic-workspace ((client memory-dmx-import-client) topic-id)
  (when-let (workspace-id (gethash topic-id (workspace-assignments-of client)))
    (memory-dmx-import-workspace-json workspace-id)))

(defmethod dmx-import-create-topic ((client memory-dmx-import-client) payload)
  (let* ((id (or (getf payload :id)
                 (prog1 (next-topic-id-of client)
                   (incf (next-topic-id-of client)))))
         (stored (list* :id id payload)))
    (setf (gethash (getf payload :external-key) (topics-by-external-key-of client))
          stored)
    stored))

(defmethod dmx-import-update-topic ((client memory-dmx-import-client) existing-topic payload)
  (let* ((id (or (dmx-import-object-id existing-topic)
                 (getf payload :id)
                 (prog1 (next-topic-id-of client)
                   (incf (next-topic-id-of client)))))
         (stored (list* :id id payload)))
    (setf (gethash (getf payload :external-key) (topics-by-external-key-of client))
          stored)
    stored))

(defmethod dmx-import-assign-topic-to-workspace ((client memory-dmx-import-client)
                                                 workspace-id topic-id)
  (let ((resolved-workspace-id
          (or (parse-positive-integer workspace-id)
              (and (integerp workspace-id) (plusp workspace-id) workspace-id)
              (error 'fedwiki-dmx-import-error
                     :message (format nil
                                      "Workspace assignment requires a positive workspace id, got ~S"
                                      workspace-id))))
        (resolved-topic-id
          (or (parse-positive-integer topic-id)
              (and (integerp topic-id) (plusp topic-id) topic-id)
              (error 'fedwiki-dmx-import-error
                     :message (format nil
                                      "Workspace assignment requires a positive topic id, got ~S"
                                      topic-id)))))
    (unless (dmx-import-read-topic client resolved-topic-id)
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "Cannot assign missing DMX topic ~D to workspace ~D"
                              resolved-topic-id
                              resolved-workspace-id)))
    (setf (gethash resolved-topic-id (workspace-assignments-of client))
          resolved-workspace-id)
    (dmx-import-read-topic-workspace client resolved-topic-id)))

(defmethod dmx-import-topic-in-topicmap-p ((client memory-dmx-import-client) topicmap-id topic-id)
  (not (null (gethash (memory-topicmap-membership-key topicmap-id topic-id)
                      (topicmap-memberships-of client)))))

(defmethod dmx-import-add-topic-to-topicmap ((client memory-dmx-import-client)
                                             topicmap-id topic-id view-props)
  (multiple-value-bind (normalized-view-props)
      (normalize-dmx-topicmap-view-props
       view-props
       :boundary 'dmx-import-add-topic-to-topicmap)
  (setf (gethash (memory-topicmap-membership-key topicmap-id topic-id)
                 (topicmap-memberships-of client))
        normalized-view-props)
    normalized-view-props))

(defmethod dmx-import-set-topic-view-props ((client memory-dmx-import-client)
                                            topicmap-id topic-id view-props)
  (multiple-value-bind (normalized-view-props)
      (normalize-dmx-topicmap-view-props
       view-props
       :boundary 'dmx-import-set-topic-view-props)
  (setf (gethash (memory-topicmap-membership-key topicmap-id topic-id)
                 (topicmap-memberships-of client))
        normalized-view-props)
    normalized-view-props))

(defmethod dmx-import-remove-topic-from-topicmap ((client memory-dmx-import-client)
                                                  topicmap-id topic-id)
  (remhash (memory-topicmap-membership-key topicmap-id topic-id)
           (topicmap-memberships-of client))
  nil)

(defmethod dmx-import-delete-topic ((client memory-dmx-import-client) topic-id)
  (let ((external-keys-to-delete '())
        (memberships-to-delete '()))
    (maphash (lambda (external-key topic)
               (when (eql topic-id (dmx-import-object-id topic))
                 (push external-key external-keys-to-delete)))
             (topics-by-external-key-of client))
    (maphash (lambda (membership-key view-props)
               (declare (ignore view-props))
               (when (eql topic-id (second membership-key))
                 (push membership-key memberships-to-delete)))
             (topicmap-memberships-of client))
    (dolist (external-key external-keys-to-delete)
      (remhash external-key (topics-by-external-key-of client)))
    (dolist (membership-key memberships-to-delete)
      (remhash membership-key (topicmap-memberships-of client)))
    (remhash topic-id (workspace-assignments-of client))
    nil))

(defun dmx-workspace-assignment-rehearsal-required-hash
    (parent key boundary)
  (let ((value (and (hash-table-p parent)
                    (gethash key parent))))
    (unless (hash-table-p value)
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "DMX workspace-assignment rehearsal snapshot requires ~A at ~A"
                              key
                              boundary)))
    value))

(defun dmx-workspace-assignment-rehearsal-copy-json-object (json)
  (let ((copy (make-hash-table :test #'equal)))
    (when (hash-table-p json)
      (maphash (lambda (key value)
                 (setf (gethash key copy) value))
               json))
    copy))

(defun dmx-workspace-assignment-rehearsal-topic-json->payload (topic-json)
  (let ((children (make-hash-table :test #'equal))
        (children-json (and (hash-table-p topic-json)
                            (gethash "children" topic-json))))
    (when (hash-table-p children-json)
      (maphash (lambda (child-type-uri child-json)
                 (setf (gethash child-type-uri children)
                       (if (hash-table-p child-json)
                           (gethash "value" child-json)
                           child-json)))
               children-json))
    (list :id (and (hash-table-p topic-json)
                   (gethash "id" topic-json))
          :uri (and (hash-table-p topic-json)
                    (gethash "uri" topic-json))
          :type-uri (and (hash-table-p topic-json)
                         (gethash "typeUri" topic-json))
          :value (and (hash-table-p topic-json)
                      (gethash "value" topic-json))
          :external-key
          (and (hash-table-p topic-json)
               (or (gethash "externalKey" topic-json)
                   (gethash "external-key" topic-json)
                   (gethash "uri" topic-json)))
          :children children)))

(defun dmx-workspace-assignment-rehearsal-topic-entry-in-topicmap
    (topicmap-json topic-id)
  (find topic-id
        (json-array-elements
         (and (hash-table-p topicmap-json)
              (gethash "topics" topicmap-json)))
        :key #'dmx-import-object-id
        :test #'eql))

(defun dmx-workspace-assignment-rehearsal-copy-json-array (value)
  (cond
    ((null value)
     #())
    ((vectorp value)
     (copy-seq value))
    ((listp value)
     (coerce value 'vector))
    (t
     #())))

(defun make-dmx-workspace-assignment-rehearsal-snapshot
    (&key topic workspace-id workspace-topicmap-id workspace-assignment
       topicmap-memberships workspace-topicmap workspace-owner)
  (let* ((resolved-topic-id
           (or (dmx-import-object-id topic)
               (error 'fedwiki-dmx-import-error
                      :message
                      "DMX workspace-assignment rehearsal snapshot requires a captured topic with id")))
         (resolved-workspace-id
           (or (parse-positive-integer workspace-id)
               (and (integerp workspace-id) (plusp workspace-id) workspace-id)
               (error 'fedwiki-dmx-import-error
                      :message
                      "DMX workspace-assignment rehearsal snapshot requires a positive target workspace id")))
         (resolved-topicmap-id
           (or (parse-positive-integer workspace-topicmap-id)
               (and (integerp workspace-topicmap-id)
                    (plusp workspace-topicmap-id)
                    workspace-topicmap-id)
               (error 'fedwiki-dmx-import-error
                      :message
                      "DMX workspace-assignment rehearsal snapshot requires a positive target workspace topicmap id")))
         (snapshot (make-hash-table :test #'equal))
         (repair-target (make-hash-table :test #'equal))
         (captures (make-hash-table :test #'equal)))
    (unless (hash-table-p topic)
      (error 'fedwiki-dmx-import-error
             :message
             "DMX workspace-assignment rehearsal snapshot requires captured topic JSON"))
    (unless (hash-table-p workspace-topicmap)
      (error 'fedwiki-dmx-import-error
             :message
             "DMX workspace-assignment rehearsal snapshot requires captured workspace topicmap JSON"))
    (setf (gethash "snapshotKind" snapshot)
          *dmx-workspace-assignment-rehearsal-snapshot-kind*
          (gethash "schemaVersion" snapshot) 1
          (gethash "repairTarget" snapshot) repair-target
          (gethash "captures" snapshot) captures
          (gethash "topicId" repair-target) resolved-topic-id
          (gethash "workspaceId" repair-target) resolved-workspace-id
          (gethash "workspaceTopicmapId" repair-target) resolved-topicmap-id
          (gethash "topic" captures)
          (dmx-workspace-assignment-rehearsal-copy-json-object topic)
          (gethash "workspaceAssignment" captures)
          (and workspace-assignment
               (dmx-workspace-assignment-rehearsal-copy-json-object
                workspace-assignment))
          (gethash "topicmapMemberships" captures)
          (dmx-workspace-assignment-rehearsal-copy-json-array
           topicmap-memberships)
          (gethash "workspaceTopicmap" captures)
          (dmx-workspace-assignment-rehearsal-copy-json-object
           workspace-topicmap))
    (when workspace-owner
      (setf (gethash "workspaceOwner" captures) workspace-owner))
    snapshot))

(defun clear-memory-dmx-import-client-state (client)
  (clrhash (topics-by-external-key-of client))
  (clrhash (topicmap-memberships-of client))
  (clrhash (workspace-assignments-of client))
  client)

(defun read-dmx-workspace-assignment-rehearsal-snapshot (path)
  (let ((snapshot
          (with-open-file (stream path :direction :input)
            (shasht:read-json stream))))
    (unless (hash-table-p snapshot)
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "DMX workspace-assignment rehearsal snapshot must decode to a JSON object: ~A"
                              path)))
    (unless (string= (or (gethash "snapshotKind" snapshot) "")
                     *dmx-workspace-assignment-rehearsal-snapshot-kind*)
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "Unsupported DMX workspace-assignment rehearsal snapshot kind ~S in ~A"
                              (gethash "snapshotKind" snapshot)
                              path)))
    (unless (eql (or (gethash "schemaVersion" snapshot) 0) 1)
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "Unsupported DMX workspace-assignment rehearsal snapshot schemaVersion ~S in ~A"
                              (gethash "schemaVersion" snapshot)
                              path)))
    (dmx-workspace-assignment-rehearsal-required-hash
     snapshot
     "repairTarget"
     'read-dmx-workspace-assignment-rehearsal-snapshot)
    (let ((captures
            (dmx-workspace-assignment-rehearsal-required-hash
             snapshot
             "captures"
             'read-dmx-workspace-assignment-rehearsal-snapshot)))
      (dmx-workspace-assignment-rehearsal-required-hash
       captures
       "topic"
       'read-dmx-workspace-assignment-rehearsal-snapshot)
      (dmx-workspace-assignment-rehearsal-required-hash
       captures
       "workspaceTopicmap"
       'read-dmx-workspace-assignment-rehearsal-snapshot))
    snapshot))

(defun load-dmx-workspace-assignment-rehearsal-snapshot-into-memory-client
    (snapshot client &key (clear-state-p t))
  (unless (typep client 'memory-dmx-import-client)
    (error 'fedwiki-dmx-import-error
           :message (format nil
                            "DMX workspace-assignment rehearsal snapshot loader requires a memory-dmx-import-client, got ~S"
                            (type-of client))))
  (let* ((repair-target
           (dmx-workspace-assignment-rehearsal-required-hash
            snapshot
            "repairTarget"
            'load-dmx-workspace-assignment-rehearsal-snapshot-into-memory-client))
         (captures
           (dmx-workspace-assignment-rehearsal-required-hash
            snapshot
            "captures"
            'load-dmx-workspace-assignment-rehearsal-snapshot-into-memory-client))
         (topic-json
           (dmx-workspace-assignment-rehearsal-required-hash
            captures
            "topic"
            'load-dmx-workspace-assignment-rehearsal-snapshot-into-memory-client))
         (workspace-assignment (gethash "workspaceAssignment" captures))
         (topicmap-memberships (gethash "topicmapMemberships" captures))
         (workspace-topicmap
           (dmx-workspace-assignment-rehearsal-required-hash
            captures
            "workspaceTopicmap"
            'load-dmx-workspace-assignment-rehearsal-snapshot-into-memory-client))
         (topic-id
           (or (dmx-import-object-id topic-json)
               (parse-positive-integer (gethash "topicId" repair-target))
               (error 'fedwiki-dmx-import-error
                      :message
                      "DMX workspace-assignment rehearsal snapshot is missing repairTarget.topicId"))))
    (when clear-state-p
      (clear-memory-dmx-import-client-state client))
    (dmx-import-create-topic
     client
     (dmx-workspace-assignment-rehearsal-topic-json->payload topic-json))
    (when workspace-assignment
      (when-let (workspace-id (dmx-import-object-id workspace-assignment))
        (setf (gethash topic-id (workspace-assignments-of client))
              workspace-id)))
    (dolist (membership (json-array-elements topicmap-memberships))
      (let* ((topicmap-id (dmx-import-object-id membership))
             (topic-entry
               (and topicmap-id
                    (eql topicmap-id (dmx-import-object-id workspace-topicmap))
                    (dmx-workspace-assignment-rehearsal-topic-entry-in-topicmap
                     workspace-topicmap
                     topic-id))))
        (when topicmap-id
          (setf (gethash (memory-topicmap-membership-key topicmap-id topic-id)
                         (topicmap-memberships-of client))
                (dmx-workspace-assignment-rehearsal-copy-json-object
                 (and topic-entry
                      (gethash "viewProps" topic-entry)))))))
    (let* ((workspace-topicmap-id (dmx-import-object-id workspace-topicmap))
           (membership-key
             (and workspace-topicmap-id
                  (memory-topicmap-membership-key workspace-topicmap-id topic-id)))
           (topic-entry
             (and workspace-topicmap-id
                  (dmx-workspace-assignment-rehearsal-topic-entry-in-topicmap
                   workspace-topicmap
                   topic-id))))
      (when (and membership-key
                 topic-entry
                 (null (gethash membership-key (topicmap-memberships-of client))))
        (setf (gethash membership-key (topicmap-memberships-of client))
              (dmx-workspace-assignment-rehearsal-copy-json-object
               (gethash "viewProps" topic-entry)))))
    client))

(defun make-memory-dmx-import-client-from-workspace-assignment-rehearsal-snapshot
    (snapshot &key (next-topic-id 1000))
  (let ((client (make-instance 'memory-dmx-import-client
                               :next-topic-id next-topic-id)))
    (load-dmx-workspace-assignment-rehearsal-snapshot-into-memory-client
     snapshot
     client)
    client))

(defun encode-base64-octets (octets)
  (with-output-to-string (stream)
    (loop with length = (length octets)
          for index from 0 below length by 3
          for byte1 = (aref octets index)
          for index2 = (1+ index)
          for byte2 = (if (< index2 length) (aref octets index2) 0)
          for index3 = (+ index 2)
          for byte3 = (if (< index3 length) (aref octets index3) 0)
          for triple = (logior (ash byte1 16)
                               (ash byte2 8)
                               byte3)
          do (write-char (char *base64-alphabet* (ldb (byte 6 18) triple))
                         stream)
             (write-char (char *base64-alphabet* (ldb (byte 6 12) triple))
                         stream)
             (write-char (if (< index2 length)
                             (char *base64-alphabet* (ldb (byte 6 6) triple))
                             #\=)
                         stream)
             (write-char (if (< index3 length)
                             (char *base64-alphabet* (ldb (byte 6 0) triple))
                             #\=)
                         stream))))

(defun basic-authorization-header (username password)
  (let* ((credentials (format nil "~A:~A" username password))
         (octets (map 'vector
                      (lambda (char)
                        (let ((code (char-code char)))
                          (unless (<= code 255)
                            (error 'dmx-import-config-error
                                   :message "Basic auth credentials must be Latin-1 or use HYPERDOC_DMX_IMPORT_AUTH_HEADER"
                                   :missing-keys '("HYPERDOC_DMX_IMPORT_AUTH_HEADER")))
                          code))
                      credentials)))
    (format nil "Basic ~A" (encode-base64-octets octets))))

(defun normalize-fedwiki-import-text (text)
  (let ((string (or text "")))
    (string-trim
     '(#\Space #\Tab #\Newline #\Return)
     (cl-ppcre:regex-replace-all "\\s+" string " "))))

(defun meaningful-fedwiki-import-text-p (text)
  (plusp (length (normalize-fedwiki-import-text text))))

(defun fedwiki-summary-paragraph-item-p (item)
  (member (gethash "type" item)
          *fedwiki-summary-paragraph-types*
          :test #'string-equal))

(defun derive-fedwiki-summary-from-story (story title)
  (labels ((item-text (item)
             (normalize-fedwiki-import-text
              (and item
                   (gethash "text" item))))
           (first-matching-text (items predicate)
             (loop for item across (or items #())
                   for text = (item-text item)
                   when (and (funcall predicate item)
                             (meaningful-fedwiki-import-text-p text))
                     return text)))
    (or (first-matching-text story #'fedwiki-summary-paragraph-item-p)
        (first-matching-text story (lambda (item)
                                     (declare (ignore item))
                                     t))
        (normalize-fedwiki-import-text title))))

(defun fedwiki-import-external-key (domain slug)
  (format nil "fedwiki:~A/~A"
          (string-downcase domain)
          slug))

(defun last-fedwiki-journal-timestamp (journal)
  (loop for entry across (or journal #())
        for date = (and entry (gethash "date" entry))
        when (numberp date)
          maximize date))

(defun local-fedwiki-page-p (page)
  (and (typep page 'hyperbook/fedwiki::fedwiki-page)
       (not (typep page 'hyperbook/fedwiki::remote-fedwiki-page))
       (not (typep page 'hyperbook/fedwiki::fedwiki-plugin-page))))

(defun collect-local-fedwiki-pages (wiki)
  (hyperbook/fedwiki::wait-for-sitemap wiki)
  (sort (remove-if-not #'local-fedwiki-page-p
                       (alexandria:hash-table-values
                        (hyperbook/fedwiki::pages-of wiki)))
        #'string<
        :key #'hb:id-of))

(defun fetch-fedwiki-import-page-json (wiki page)
  (hyperbook/fedwiki::fetch-page-json (hyperbook/fedwiki::domain-name-of wiki)
                                      (hyperbook/fedwiki::protocol-of wiki)
                                      (hb:id-of page)))

(defun build-fedwiki-import-candidate (wiki page page-json
                                        &key (now (get-universal-time)))
  (let* ((domain (hyperbook/fedwiki::domain-name-of wiki))
         (slug (hb:id-of page))
         (title (or (gethash "title" page-json)
                    (hb:title-of page)
                    slug))
         (protocol (hyperbook/fedwiki::protocol-of wiki))
         (story (gethash "story" page-json))
         (journal (gethash "journal" page-json)))
    (make-fedwiki-import-candidate
     :external-key (fedwiki-import-external-key domain slug)
     :domain domain
     :slug slug
     :title title
     :canonical-html-url (hyperbook/fedwiki::wiki-url domain
                                                     protocol
                                                     (format nil "/~A.html" slug))
     :canonical-json-url (hyperbook/fedwiki::wiki-url domain
                                                     protocol
                                                     (format nil "/~A.json" slug))
     :summary (derive-fedwiki-summary-from-story story title)
     :source-kind *fedwiki-import-source-kind*
     :page-json page-json
     :raw-journal-timestamp (last-fedwiki-journal-timestamp journal)
     :last-sync-timestamp now)))

(defun enumerate-fedwiki-import-candidates (wiki
                                            &key
                                              limit
                                              (page-json-loader
                                               #'fetch-fedwiki-import-page-json)
                                              (now (get-universal-time)))
  (let ((pages (collect-local-fedwiki-pages wiki))
        (candidates '()))
    (loop for page in pages
          for index from 0
          when (and limit (>= index limit))
            do (loop-finish)
          do (push (build-fedwiki-import-candidate wiki
                                                   page
                                                   (funcall page-json-loader wiki page)
                                                   :now now)
                   candidates))
    (nreverse candidates)))

(defun fedwiki-import-ready-wiki-p (wiki)
  (hyperbook/fedwiki::fedwiki-ready-p wiki))

(defun resolve-fedwiki-import-wiki (domain &key wiki verbose (stream *standard-output*))
  (labels ((page-count (candidate-wiki)
             (hash-table-count (hyperbook/fedwiki::pages-of candidate-wiki)))
           (report-http-fallback (original-protocol original-pages retry-wiki)
             (when verbose
               (format stream
                       "~&FEDWIKI_DMX_IMPORT fallback=http original-protocol=~A original-pages=~D retry-pages=~D~%"
                       original-protocol
                       original-pages
                       (page-count retry-wiki)))))
    (let ((resolved-wiki (or wiki
                             (hyperbook/fedwiki::get-fedwiki domain nil t))))
      (hyperbook/fedwiki::wait-for-sitemap resolved-wiki)
      (cond
        ((and wiki
              (null (hyperbook/fedwiki::status-of resolved-wiki)))
         (values resolved-wiki nil))
        ((fedwiki-import-ready-wiki-p resolved-wiki)
         (values resolved-wiki nil))
        ((not (string= (hyperbook/fedwiki::protocol-of resolved-wiki)
                       "https"))
         (values resolved-wiki nil))
        (t
         (let ((original-protocol (hyperbook/fedwiki::protocol-of resolved-wiki))
               (original-pages (page-count resolved-wiki))
               (initial-condition
                 (and (typep (hyperbook/fedwiki::status-of resolved-wiki) 'condition)
                      (hyperbook/fedwiki::status-of resolved-wiki))))
           (multiple-value-bind (retry-wiki recovered-p)
               (hyperbook/fedwiki::retry-site-data-over-http
                resolved-wiki
                :initial-condition initial-condition
                :log-initial-failure? nil)
             (when recovered-p
               (report-http-fallback original-protocol original-pages retry-wiki))
             (values retry-wiki recovered-p))))))))

(defun fedwiki-import-source-envelope (candidate)
  (let ((json (make-hash-table :test #'equal)))
    (setf (gethash "externalKey" json)
          (fedwiki-import-candidate-external-key candidate)
          (gethash "siteDomain" json)
          (fedwiki-import-candidate-domain candidate)
          (gethash "slug" json)
          (fedwiki-import-candidate-slug candidate)
          (gethash "title" json)
          (fedwiki-import-candidate-title candidate)
          (gethash "canonicalHtmlUrl" json)
          (fedwiki-import-candidate-canonical-html-url candidate)
          (gethash "canonicalJsonUrl" json)
          (fedwiki-import-candidate-canonical-json-url candidate)
          (gethash "summary" json)
          (fedwiki-import-candidate-summary candidate)
          (gethash "sourceKind" json)
          (fedwiki-import-candidate-source-kind candidate)
          (gethash "lastSyncTimestamp" json)
          (fedwiki-import-candidate-last-sync-timestamp candidate)
          (gethash "pageJson" json)
          (fedwiki-import-candidate-page-json candidate))
    (when (fedwiki-import-candidate-raw-journal-timestamp candidate)
      (setf (gethash "rawJournalTimestamp" json)
            (fedwiki-import-candidate-raw-journal-timestamp candidate)))
    json))

(defun fedwiki-import-dmx-children (candidate)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash *dmx-fedwiki-slug-type-uri* children)
          (fedwiki-import-candidate-slug candidate)
          (gethash *dmx-fedwiki-title-type-uri* children)
          (fedwiki-import-candidate-title candidate)
          (gethash *dmx-fedwiki-page-json-type-uri* children)
          (encode-json-string (fedwiki-import-source-envelope candidate)))
    children))

(defun fedwiki-import-payload (candidate &key topic-type-uri)
  (list :type-uri (or topic-type-uri
                      *dmx-fedwiki-page-type-uri*)
        :uri (fedwiki-import-candidate-external-key candidate)
        :value (fedwiki-import-candidate-title candidate)
        :external-key (fedwiki-import-candidate-external-key candidate)
        :slug (fedwiki-import-candidate-slug candidate)
        :site-domain (fedwiki-import-candidate-domain candidate)
        :canonical-html-url (fedwiki-import-candidate-canonical-html-url candidate)
        :canonical-json-url (fedwiki-import-candidate-canonical-json-url candidate)
        :summary (fedwiki-import-candidate-summary candidate)
        :last-sync-timestamp (fedwiki-import-candidate-last-sync-timestamp candidate)
        :raw-journal-timestamp (fedwiki-import-candidate-raw-journal-timestamp candidate)
        :source-kind (fedwiki-import-candidate-source-kind candidate)
        :children (fedwiki-import-dmx-children candidate)))

(defun validate-unique-fedwiki-import-keys (candidates)
  (let ((seen (make-hash-table :test #'equal)))
    (dolist (candidate candidates)
      (let ((key (fedwiki-import-candidate-external-key candidate)))
        (when (gethash key seen)
          (error 'duplicate-fedwiki-import-key
                 :message "Duplicate FedWiki import key"
                 :external-key key))
        (setf (gethash key seen) t))))
  candidates)

(defun plan-fedwiki-site-dmx-import (candidates client &key topic-type-uri)
  (validate-unique-fedwiki-import-keys candidates)
  (loop for candidate in candidates
        for payload = (fedwiki-import-payload candidate
                                              :topic-type-uri
                                              (or topic-type-uri
                                                  (and (typep client 'http-dmx-import-client)
                                                       (dmx-import-topic-type-uri-of client))))
        for existing = (dmx-import-find-existing-topic
                        client
                        (fedwiki-import-candidate-external-key candidate))
        collect (make-dmx-import-plan-entry
                 :action (if existing :update :create)
                 :external-key (fedwiki-import-candidate-external-key candidate)
                 :candidate candidate
                 :payload payload
                 :existing-topic existing)))

(defun summarize-dmx-import-plan (plan)
  (let ((creates 0)
        (updates 0))
    (dolist (entry plan)
      (ecase (dmx-import-plan-entry-action entry)
        (:create (incf creates))
        (:update (incf updates))))
    (list :creates creates
          :updates updates
          :entries (length plan))))

(defun lookup-enabled-for-dmx-import-client-p (client)
  (not (typep client 'null-dmx-import-client)))

(defun render-dmx-import-plan-entry (entry &key (stream *standard-output*) verbose)
  (let ((candidate (dmx-import-plan-entry-candidate entry)))
    (format stream "~&~A ~A ~S~%"
            (string-upcase (symbol-name (dmx-import-plan-entry-action entry)))
            (dmx-import-plan-entry-external-key entry)
            (fedwiki-import-candidate-title candidate))
    (when verbose
      (format stream "  slug=~A site=~A~%"
              (fedwiki-import-candidate-slug candidate)
              (fedwiki-import-candidate-domain candidate))
      (format stream "  html=~A~%"
              (fedwiki-import-candidate-canonical-html-url candidate))
      (format stream "  json=~A~%"
              (fedwiki-import-candidate-canonical-json-url candidate))
      (format stream "  summary=~S~%"
              (fedwiki-import-candidate-summary candidate)))))

(defun execute-dmx-import-plan (plan client &key dry-run (stream *standard-output*) verbose)
  (dolist (entry plan)
    (render-dmx-import-plan-entry entry :stream stream :verbose verbose)
    (unless dry-run
      (ecase (dmx-import-plan-entry-action entry)
        (:create
         (dmx-import-create-topic client
                                  (dmx-import-plan-entry-payload entry)))
        (:update
         (dmx-import-update-topic client
                                  (dmx-import-plan-entry-existing-topic entry)
                                  (dmx-import-plan-entry-payload entry))))))
  plan)

(defun unreserved-url-char-p (char)
  (or (and (char>= char #\a) (char<= char #\z))
      (and (char>= char #\A) (char<= char #\Z))
      (and (char>= char #\0) (char<= char #\9))
      (find char "-._~" :test #'char=)))

(defun url-encode-component (text)
  (with-output-to-string (stream)
    (loop for char across (or text "")
          do (if (unreserved-url-char-p char)
                 (write-char char stream)
                 (format stream "%~2,'0X" (char-code char))))))

(defun absolute-http-url-p (url)
  (or (and url
           (<= 7 (length url))
           (string= "http://" url :end2 7))
      (and url
           (<= 8 (length url))
           (string= "https://" url :end2 8))))

(defun http-success-status-p (status)
  (and status (<= 200 status 299)))

(defun json-encoder-function ()
  (or (let* ((pkg (find-package "SHASHT"))
             (sym (and pkg (find-symbol "WRITE-JSON" pkg))))
        (and sym (fboundp sym) (symbol-function sym)))
      (let* ((pkg (or (find-package "COM.INUOE.JZON")
                      (find-package "JZON")))
             (sym (and pkg (find-symbol "STRINGIFY" pkg))))
        (and sym (fboundp sym)
             (lambda (object stream)
               (write-string (funcall (symbol-function sym) object) stream))))))

(defun encode-json-string (object)
  (let ((encoder (json-encoder-function)))
    (unless encoder
      (error 'fedwiki-dmx-import-error
             :message "No JSON encoder available for live DMX writes"))
    (with-output-to-string (stream)
      (funcall encoder object stream))))

(defun encode-http-json-request-body (object)
  (babel:string-to-octets (encode-json-string object)
                          :encoding :utf-8))

(defun dmx-import-children-json-object (children)
  (when children
    (let ((json (make-hash-table :test #'equal)))
      (maphash (lambda (child-type-uri child-value)
                 (setf (gethash child-type-uri json)
                       child-value))
               children)
      json)))

(defun dmx-import-json-object (payload)
  (let ((json (make-hash-table :test #'equal)))
    (labels ((put (key value)
               (when value
                 (setf (gethash key json) value))))
      (put "id" (getf payload :id))
      (put "uri" (getf payload :uri))
      (put "typeUri" (getf payload :type-uri))
      (put "value" (getf payload :value))
      (put "children"
           (dmx-import-children-json-object
            (getf payload :children))))
    json))

(defun normalize-http-client-url (client url)
  (cond
    ((null url) nil)
    ((absolute-http-url-p url)
     url)
    ((dmx-import-base-url-of client)
     (let ((base-url (string-right-trim "/" (dmx-import-base-url-of client))))
       (if (and (> (length url) 0)
                (char= (char url 0) #\/))
           (concatenate 'string base-url url)
           (format nil "~A/~A" base-url url))))
    (t
     url)))

(defun dmx-topic-uri-lookup-path (topic-uri)
  (format nil "/core/topic/uri/~A?~A"
          (url-encode-component topic-uri)
          *dmx-topic-fetch-query-string*))

(defun dmx-topic-create-path ()
  "/core/topic")

(defun dmx-topic-update-path (topic-id)
  (format nil "/core/topic/~A" topic-id))

(defun dmx-topic-id (topic)
  (and (hash-table-p topic)
       (gethash "id" topic)))

(defun dmx-topicmap-memberships-path (object-id)
  (format nil "/topicmaps/object/~D" object-id))

(defun dmx-workspace-object-path (object-id)
  (format nil "/workspaces/object/~D" object-id))

(defun dmx-workspace-assign-object-path (workspace-id object-id)
  (format nil "/workspaces/~D/object/~D" workspace-id object-id))

(defun dmx-access-control-login-path ()
  "/access-control/login")

(defun dmx-topicmap-add-topic-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

(defun dmx-topicmap-set-topic-view-props-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

(defun http-response-body-string (stream)
  (when stream
    (ignore-errors
      (uiop:slurp-stream-string stream))))

(defun http-response-header-value (headers header-name)
  (cdr (find header-name
             headers
             :test #'string-equal
             :key (lambda (entry)
                    (let ((name (car entry)))
                      (etypecase name
                        (string name)
                        (symbol (symbol-name name))))))))

(defun octet-vector-p (value)
  (and (vectorp value)
       (not (stringp value))
       (every (lambda (item)
                (and (integerp item)
                     (<= 0 item 255)))
              value)))

(defun http-request-content-string (content)
  (cond
    ((null content)
     nil)
    ((stringp content)
     content)
    ((octet-vector-p content)
     (or (ignore-errors
           (babel:octets-to-string content :encoding :utf-8))
         (format nil "#<~D octets>" (length content))))
    (t
     (format nil "~S" content))))

(defun bounded-http-evidence-string (string)
  (let ((value (or string "")))
    (subseq value
            0
            (min (length value)
                 *http-dmx-import-evidence-body-prefix-limit*))))

(defun http-body-evidence (prefix body)
  (let* ((string (or (http-request-content-string body) ""))
         (length (length string))
         (prefix-name (intern (format nil "~A-BODY-PREFIX" prefix) :keyword))
         (length-name (intern (format nil "~A-BODY-LENGTH" prefix) :keyword))
         (truncated-name
           (intern (format nil "~A-BODY-TRUNCATED-P" prefix) :keyword)))
    (list length-name length
          prefix-name (bounded-http-evidence-string string)
          truncated-name
          (> length *http-dmx-import-evidence-body-prefix-limit*))))

(defun plist-without-http-body-fields (plist)
  (loop for (key value) on plist by #'cddr
        unless (member key '(:request-body :response-body) :test #'eq)
          append (list key value)))

(defun sanitize-dmx-import-http-evidence (evidence)
  (when evidence
    (append
     (plist-without-http-body-fields evidence)
     (when (getf evidence :request-body)
       (http-body-evidence "REQUEST" (getf evidence :request-body)))
     (when (getf evidence :response-body)
       (http-body-evidence "RESPONSE" (getf evidence :response-body))))))

(defun sanitize-http-dmx-import-debug-value (key value)
  (cond
    ((member key
             '(:authorization-header :cookie :cookie-header :auth-token
               :password :token :session-cookie :headers :additional-headers)
             :test #'eq)
     "<redacted>")
    ((and (stringp value)
          (> (length value) *http-dmx-import-evidence-body-prefix-limit*))
     (bounded-http-evidence-string value))
    (t
     value)))

(defun sanitize-http-dmx-import-debug-event (event)
  (loop for (key value) on event by #'cddr
        append (list key
                     (sanitize-http-dmx-import-debug-value key value))))

(defun bounded-http-dmx-import-debug-events (events)
  (let ((length (length events)))
    (if (> length *http-dmx-import-debug-event-limit*)
        (last events *http-dmx-import-debug-event-limit*)
        events)))

(defun http-request-relative-path (client normalized-url)
  (let ((base-url (dmx-import-base-url-of client)))
    (if (and base-url
             (<= (length base-url) (length normalized-url))
             (string-equal base-url
                           normalized-url
                           :end2 (length base-url)))
        (subseq normalized-url (length base-url))
        normalized-url)))

(defun summarize-http-authorization-scheme (authorization-header)
  (cond
    ((null authorization-header) nil)
    ((search "Basic " authorization-header :test #'char-equal)
     "Basic")
    ((search "Bearer " authorization-header :test #'char-equal)
     "Bearer")
    (t
     "Custom")))

(defun http-dmx-import-session-bootstrap-required-p (client)
  (and (typep client 'http-dmx-import-client)
       (or (dmx-import-session-login-required-p-of client)
           (dmx-import-bootstrap-session-p-of client))))

(defun effective-http-dmx-import-authorization-header
    (client &key bootstrap-request-p)
  (let ((authorization-header (dmx-import-authorization-header-of client)))
    (cond
      ((null authorization-header)
       nil)
      ((and (not bootstrap-request-p)
            (http-dmx-import-session-bootstrap-required-p client)
            (dmx-import-session-cookie-of client))
       nil)
      (t
       authorization-header))))

(defun cookie-contains-token-p (cookie-header token)
  (and cookie-header
       (search token cookie-header :test #'char-equal)))

(defun summarize-http-cookie-shape (cookie-header)
  (cond
    ((null cookie-header)
     "none")
    ((and (cookie-contains-token-p cookie-header "JSESSIONID=")
          (cookie-contains-token-p cookie-header "dmx_workspace_id="))
     "JSESSIONID + dmx_workspace_id")
    ((cookie-contains-token-p cookie-header "JSESSIONID=")
     "JSESSIONID only")
    ((cookie-contains-token-p cookie-header "dmx_workspace_id=")
     "dmx_workspace_id only")
    (t
     "other")))

(defvar *http-dmx-import-request-workspace-id* nil)

(defmacro with-http-dmx-import-request-workspace-id ((workspace-id) &body body)
  `(let ((*http-dmx-import-request-workspace-id* ,workspace-id))
     ,@body))

(defun effective-http-dmx-import-workspace-id (client &key workspace-id)
  (or (and (integerp workspace-id)
           (plusp workspace-id)
           workspace-id)
      (parse-positive-integer workspace-id)
      (and (integerp *http-dmx-import-request-workspace-id*)
           (plusp *http-dmx-import-request-workspace-id*)
           *http-dmx-import-request-workspace-id*)
      (parse-positive-integer *http-dmx-import-request-workspace-id*)
      (and (typep client 'http-dmx-import-client)
           (integerp (dmx-import-workspace-id-of client))
           (plusp (dmx-import-workspace-id-of client))
           (dmx-import-workspace-id-of client))
      (and (typep client 'http-dmx-import-client)
           (parse-positive-integer (dmx-import-workspace-id-of client)))))

(defun http-dmx-import-request-cookie-values (client &key workspace-id)
  (append (when (dmx-import-session-cookie-of client)
            (list (dmx-import-session-cookie-of client)))
          (when-let (resolved-workspace-id
                     (effective-http-dmx-import-workspace-id
                      client
                      :workspace-id workspace-id))
            (list (format nil "dmx_workspace_id=~D" resolved-workspace-id)))))

(defun append-http-dmx-import-debug-event (client state &rest fields)
  (when (typep client 'http-dmx-import-client)
    (setf (dmx-import-debug-events-of client)
          (bounded-http-dmx-import-debug-events
           (append (dmx-import-debug-events-of client)
                   (list
                    (sanitize-http-dmx-import-debug-event
                     (append (list :state state) fields)))))))
  client)

(defun reset-http-dmx-import-debug-evidence (client)
  (when (typep client 'http-dmx-import-client)
    (let ((build-event
            (http-dmx-import-debug-event client :s3-explicit-auth-client-built)))
      (setf (dmx-import-debug-events-of client)
            (and build-event
                 (list build-event))
            (dmx-import-last-http-transaction-evidence-of client) nil)))
  client)

(defun http-dmx-import-debug-event (client state)
  (when (typep client 'http-dmx-import-client)
    (find state
          (dmx-import-debug-events-of client)
          :from-end t
          :test #'eq
          :key (lambda (event) (getf event :state)))))

(defun summarize-http-request-auth-mode (authorization-header cookie-header)
  (let ((authorization-scheme
          (summarize-http-authorization-scheme authorization-header))
        (cookie-shape
          (summarize-http-cookie-shape cookie-header))
        (jsessionid-cookie-p
          (and (cookie-contains-token-p cookie-header "JSESSIONID=") t))
        (workspace-cookie-p
          (and (cookie-contains-token-p cookie-header "dmx_workspace_id=") t)))
    (cond
      ((and jsessionid-cookie-p (null authorization-scheme))
       "session-only")
      ((and jsessionid-cookie-p authorization-scheme)
       (format nil "~A + session cookie" authorization-scheme))
      (authorization-scheme
       (format nil "~A header" authorization-scheme))
      (workspace-cookie-p
       (format nil "workspace cookie only (~A)" cookie-shape))
      (t
       "anonymous"))))

(defun http-dmx-import-response-header-evidence (headers)
  (remove nil
          (list
           (when-let (value (http-response-header-value headers "Content-Type"))
             (cons "Content-Type" value))
           (when-let (value (http-response-header-value headers "Content-Length"))
             (cons "Content-Length" value))
           (when-let (value (http-response-header-value headers "WWW-Authenticate"))
             (cons "WWW-Authenticate" value))
           (when-let (value (http-response-header-value headers "Location"))
             (cons "Location" value))
           (when-let (value (http-response-header-value headers "Set-Cookie"))
             (cons "Set-Cookie-Shape"
                   (summarize-http-cookie-shape value))))))

(defun dmx-import-bootstrap-evidence (client)
  (let ((request (http-dmx-import-debug-event client :s5-bootstrap-request-sent))
        (response (http-dmx-import-debug-event client :s6-bootstrap-response-received))
        (session (http-dmx-import-debug-event client :s7-session-material-extracted)))
    (list :bootstrap-ran-p (and (or request response session) t)
          :bootstrap-endpoint-path
          (or (and request (getf request :path))
              (and response (getf response :path))
              nil)
          :bootstrap-request-auth-mode-summary
          (or (and request (getf request :auth-mode-summary))
              nil)
          :bootstrap-authorization-scheme
          (or (and request (getf request :authorization-scheme))
              nil)
          :bootstrap-status-code
          (and response (getf response :status-code))
          :bootstrap-response-reason-phrase
          (and response (getf response :reason-phrase))
          :bootstrap-set-cookie-jsessionid-p
          (and response (getf response :set-cookie-jsessionid-p))
          :session-cookie-captured-p
          (and session (getf session :session-cookie-captured-p)))))

(defun dmx-import-http-transaction-evidence
    (client method normalized-url relative-path headers actual-content-type
     actual-content-length request-content response-status-code reason-phrase
     response-headers response-body)
  (let* ((authorization-header (http-response-header-value headers "Authorization"))
         (cookie-header (http-response-header-value headers "Cookie"))
         (authorization-scheme
           (summarize-http-authorization-scheme authorization-header))
         (cookie-shape
           (summarize-http-cookie-shape cookie-header)))
    (append
     (list :method method
           :url normalized-url
           :path relative-path
           :request-content-type actual-content-type
           :request-content-length actual-content-length
           :accept-header (http-response-header-value headers "Accept")
           :authorization-scheme authorization-scheme
          :auth-mode-summary
          (summarize-http-request-auth-mode authorization-header cookie-header)
          :session-login-required-p
          (and (typep client 'http-dmx-import-client)
               (dmx-import-session-login-required-p-of client))
          :bootstrap-session-p
          (and (typep client 'http-dmx-import-client)
               (dmx-import-bootstrap-session-p-of client))
          :derived-auth-scheme
          (and (typep client 'http-dmx-import-client)
               (dmx-import-derived-auth-scheme-of client))
           :cookie-shape cookie-shape
           :jsessionid-cookie-p
           (and (cookie-contains-token-p cookie-header "JSESSIONID=") t)
           :workspace-cookie-p
           (and (cookie-contains-token-p cookie-header "dmx_workspace_id=") t)
           :response-status-code response-status-code
           :response-reason-phrase reason-phrase
           :response-headers
           (http-dmx-import-response-header-evidence response-headers))
     (http-body-evidence "REQUEST" request-content)
     (http-body-evidence "RESPONSE" response-body)
     (dmx-import-bootstrap-evidence client))))

(defun classify-http-dmx-debug-request (method relative-path)
  (cond
    ((and (eq method :put)
          (search "/workspaces/" relative-path :test #'char-equal)
          (search "/object/" relative-path :test #'char-equal))
     :workspace-assignment)
    ((and (eq method :get)
          (search "/workspaces/object/" relative-path :test #'char-equal))
     :workspace-readback)
    ((and (eq method :get)
          (search "/topicmaps/object/" relative-path :test #'char-equal))
     :topicmap-readback)
    (t
     nil)))

(defun parse-set-cookie-cookie-pair (header &key cookie-name)
  (when header
    (let* ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) header))
           (end (or (position #\; trimmed) (length trimmed)))
           (cookie-pair (subseq trimmed 0 end)))
      (if cookie-name
          (and (<= (+ (length cookie-name) 1) (length cookie-pair))
               (string-equal (format nil "~A=" cookie-name)
                             cookie-pair
                             :end2 (+ (length cookie-name) 1))
               cookie-pair)
          cookie-pair))))

(defun bootstrap-http-dmx-import-session (client)
  (let* ((authorization-header
           (effective-http-dmx-import-authorization-header
            client
            :bootstrap-request-p t))
         (normalized-url
           (normalize-http-client-url client
                                      (dmx-access-control-login-path))))
    (append-http-dmx-import-debug-event
     client
     :s5-bootstrap-request-sent
     :method :post
     :path (http-request-relative-path client normalized-url)
     :auth-mode-summary
     (summarize-http-request-auth-mode authorization-header nil)
     :authorization-scheme
     (summarize-http-authorization-scheme
      authorization-header)
     :cookie-shape "none"
     :content-type nil
     :content-length 0
     :empty-body-p t)
    (multiple-value-bind (stream status-code response-headers response-uri must-close reason-phrase)
        (drakma:http-request normalized-url
                             :method :post
                             :want-stream t
                             :additional-headers
                             (when authorization-header
                               (list (cons "Authorization"
                                           authorization-header)))
                             :content ""
                             :content-length 0
                             :content-type nil)
      (declare (ignore response-uri must-close))
      (unwind-protect
           (let ((body (http-response-body-string stream)))
             (when (typep client 'http-dmx-import-client)
               (setf (dmx-import-last-http-transaction-evidence-of client)
                     (dmx-import-http-transaction-evidence
                      client
                      :post
                      normalized-url
                      (http-request-relative-path client normalized-url)
                      (when authorization-header
                        (list (cons "Authorization" authorization-header)))
                      nil
                      0
                      ""
                      status-code
                      reason-phrase
                      response-headers
                      body)))
             (append-http-dmx-import-debug-event
             client
             :s6-bootstrap-response-received
             :method :post
             :path (http-request-relative-path client normalized-url)
             :status-code status-code
             :reason-phrase reason-phrase
             :set-cookie-jsessionid-p
             (and (http-response-header-value response-headers "Set-Cookie")
                   (parse-set-cookie-cookie-pair
                    (http-response-header-value response-headers "Set-Cookie")
                    :cookie-name "JSESSIONID")
                   t))
             (if (http-success-status-p status-code)
                 (let ((session-cookie
                         (parse-set-cookie-cookie-pair
                          (http-response-header-value response-headers "Set-Cookie")
                          :cookie-name "JSESSIONID")))
                   (unless session-cookie
                     (error 'dmx-import-http-error
                            :message "DMX login succeeded without a JSESSIONID cookie"
                            :url normalized-url
                            :status-code status-code
                            :response-body (bounded-http-evidence-string body)
                            :evidence
                            (dmx-import-last-http-transaction-evidence-of
                             client)))
                   (setf (dmx-import-session-cookie-of client) session-cookie)
                   (append-http-dmx-import-debug-event
                    client
                    :s7-session-material-extracted
                    :session-cookie-captured-p t
                    :cookie-shape
                    (summarize-http-cookie-shape session-cookie)))
                 (error 'dmx-import-http-error
                        :message (or reason-phrase
                                     "DMX login request failed")
                        :url normalized-url
                        :status-code status-code
                        :response-body (bounded-http-evidence-string body)
                        :evidence
                        (dmx-import-last-http-transaction-evidence-of
                         client))))
        (when stream
          (ignore-errors (close stream)))))))

(defun blank-http-response-body-p (body)
  (or (null body)
      (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return) body)))))

(defun parse-http-response-body-json (body)
  (if (blank-http-response-body-p body)
      nil
      (handler-case
          (shasht:read-json body)
        (error ()
          body))))

(defun http-request-json
    (client method url
     &key payload body-object allow-404? extra-headers workspace-id
       ((:raw-content raw-content) nil raw-content-provided-p)
       (content-type nil content-type-provided-p)
       (content-length nil content-length-provided-p))
  (let* ((normalized-url (normalize-http-client-url client url))
         (relative-path (http-request-relative-path client normalized-url))
         (json-content
           (and (or payload body-object)
                (encode-http-json-request-body
                 (or body-object
                     (dmx-import-json-object payload)))))
         (authorization-header
           (effective-http-dmx-import-authorization-header client))
         (cookie-values
           (http-dmx-import-request-cookie-values
            client
            :workspace-id workspace-id))
         (headers (append (when authorization-header
                            (list (cons "Authorization"
                                        authorization-header)))
                          (when cookie-values
                            (list (cons "Cookie"
                                        (format nil "~{~A~^; ~}" cookie-values))))
                          extra-headers))
         (actual-request-content
           (cond
             (json-content json-content)
             (raw-content-provided-p raw-content)
             (t nil)))
         (actual-request-content-type
           (cond
             (json-content "application/json; charset=utf-8")
             (content-type-provided-p content-type)
             (t nil)))
         (actual-request-content-length
           (cond
             (json-content (length json-content))
             (content-length-provided-p content-length)
             (t nil)))
         (request-kind
           (classify-http-dmx-debug-request method relative-path))
         (request-args
           (append (list normalized-url
                         :method method
                         :want-stream t
                         :additional-headers headers)
                   (cond
                     (json-content
                      (list :content actual-request-content
                            :content-type actual-request-content-type
                            :content-length actual-request-content-length))
                     (raw-content-provided-p
                      (append (list :content actual-request-content)
                              (when content-type-provided-p
                                (list :content-type actual-request-content-type))
                              (when content-length-provided-p
                                (list :content-length actual-request-content-length))))))))
    (when (eql request-kind :workspace-assignment)
      (append-http-dmx-import-debug-event
       client
       :s9-guarded-repair-request-sent
       :method method
       :path relative-path
       :authorization-scheme
       (summarize-http-authorization-scheme
        (http-response-header-value headers "Authorization"))
       :cookie-shape
       (summarize-http-cookie-shape
        (http-response-header-value headers "Cookie"))
       :jsessionid-cookie-p
       (and (cookie-contains-token-p
             (http-response-header-value headers "Cookie")
             "JSESSIONID=")
            t)
       :workspace-cookie-p
       (and (cookie-contains-token-p
             (http-response-header-value headers "Cookie")
             "dmx_workspace_id=")
            t)
       :accept-header (http-response-header-value headers "Accept")
       :content-type actual-request-content-type
       :content-length actual-request-content-length
       :empty-body-p
       (cond
         (json-content nil)
         (raw-content-provided-p
          (and (stringp actual-request-content)
               (zerop (length actual-request-content))))
         (t
          nil))))
    (multiple-value-bind (stream status-code response-headers response-uri must-close reason-phrase)
        (apply #'drakma:http-request request-args)
      (declare (ignore response-uri must-close))
      (unwind-protect
           (let ((body (http-response-body-string stream)))
             (when (typep client 'http-dmx-import-client)
               (setf (dmx-import-last-http-transaction-evidence-of client)
                     (dmx-import-http-transaction-evidence
                      client
                      method
                      normalized-url
                      relative-path
                      headers
                      actual-request-content-type
                      actual-request-content-length
                      actual-request-content
                      status-code
                      reason-phrase
                      response-headers
                      body)))
             (when request-kind
               (append-http-dmx-import-debug-event
                client
                (case request-kind
                  (:workspace-assignment :s10-guarded-repair-response-received)
                  (:workspace-readback :s11-workspace-readback)
                  (:topicmap-readback :s11-topicmap-readback))
                :method method
                :path relative-path
                :status-code status-code
                :set-cookie-jsessionid-p
                (and (http-response-header-value response-headers "Set-Cookie")
                     (parse-set-cookie-cookie-pair
                      (http-response-header-value response-headers "Set-Cookie")
                      :cookie-name "JSESSIONID")
                     t)))
             (cond
               ((and allow-404? (= status-code 404))
                nil)
               ((or (= status-code 204)
                    (= status-code 205))
                nil)
               ((http-success-status-p status-code)
               (parse-http-response-body-json body))
               (t
                (error 'dmx-import-http-error
                       :message (or reason-phrase
                                    "DMX import request failed")
                       :url normalized-url
                       :status-code status-code
                       :response-body (bounded-http-evidence-string body)
                       :evidence
                       (and (typep client 'http-dmx-import-client)
                            (dmx-import-last-http-transaction-evidence-of
                             client))))))
        (when stream
          (ignore-errors (close stream)))))))

(defun validate-http-dmx-import-client (client &key live?)
  (let ((missing '()))
    (unless (dmx-import-base-url-of client)
      (push "HYPERDOC_DMX_IMPORT_BASE_URL" missing))
    (when (and live? missing)
      (error 'dmx-import-config-error
             :message "Incomplete live DMX import configuration"
             :missing-keys (nreverse missing)))
    (nreverse missing)))

(defun ensure-http-dmx-import-authenticated-operation (client operation)
  (unless (dmx-import-authorization-header-of client)
    (error 'dmx-import-config-error
           :message
           (format nil
                   "Authenticated DMX operation ~A requires HYPERDOC_DMX_IMPORT_AUTH_HEADER, HYPERDOC_DMX_IMPORT_USERNAME/HYPERDOC_DMX_IMPORT_PASSWORD, or HYPERDOC_DMX_IMPORT_AUTH_TOKEN"
                   operation)
           :missing-keys '("HYPERDOC_DMX_IMPORT_AUTH_HEADER"
                           "HYPERDOC_DMX_IMPORT_USERNAME"
                           "HYPERDOC_DMX_IMPORT_PASSWORD"
                           "HYPERDOC_DMX_IMPORT_AUTH_TOKEN")))
  (when (and (http-dmx-import-session-bootstrap-required-p client)
             (null (dmx-import-session-cookie-of client)))
    (append-http-dmx-import-debug-event
     client
     :s4-bootstrap-request-prepared
     :operation operation
     :authorization-scheme
     (summarize-http-authorization-scheme
      (effective-http-dmx-import-authorization-header
       client
       :bootstrap-request-p t)))
    (bootstrap-http-dmx-import-session client)))

(defun ensure-http-dmx-import-session-cookie-for-protected-mutation
    (client operation)
  (when (and (typep client 'http-dmx-import-client)
             (http-dmx-import-session-bootstrap-required-p client)
             (null (dmx-import-session-cookie-of client)))
    (ensure-http-dmx-import-authenticated-operation client operation)))

(defmethod dmx-import-read-topic ((client http-dmx-import-client) topic-id)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (format nil "/core/topic/~D?~A"
                             topic-id
                             *dmx-topic-fetch-query-string*)))

(defmethod dmx-import-read-topicmap ((client http-dmx-import-client) topicmap-id)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (format nil "/topicmaps/~D?children=true" topicmap-id)
                     :extra-headers '(("Accept" . "application/json"))))

(defmethod dmx-import-read-topic-workspace ((client http-dmx-import-client) topic-id)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (dmx-workspace-object-path topic-id)))

(defmethod dmx-import-find-existing-topic ((client http-dmx-import-client) external-key)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (dmx-topic-uri-lookup-path external-key)
                     :allow-404? t))

(defmethod dmx-import-create-topic ((client http-dmx-import-client) payload)
  (validate-http-dmx-import-client client :live? t)
  (ensure-http-dmx-import-session-cookie-for-protected-mutation
   client
   :create-topic)
  (http-request-json client
                     :post
                     (dmx-topic-create-path)
                     :payload payload))

(defmethod dmx-import-update-topic ((client http-dmx-import-client) existing-topic payload)
  (validate-http-dmx-import-client client :live? t)
  (ensure-http-dmx-import-session-cookie-for-protected-mutation
   client
   :update-topic)
  (let ((topic-id (dmx-import-object-id existing-topic)))
    (unless topic-id
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "Cannot update DMX topic without id for external key ~A"
                              (getf payload :external-key))))
    (http-request-json client
                       :put
                       (dmx-topic-update-path topic-id)
                       :payload (list* :id topic-id payload))))

(defmethod dmx-import-assign-topic-to-workspace ((client http-dmx-import-client)
                                                 workspace-id topic-id)
  (validate-http-dmx-import-client client :live? t)
  (ensure-http-dmx-import-authenticated-operation
   client
   :assign-topic-to-workspace)
  ;; Drakma turns a PUT with no explicit body into an empty
  ;; application/x-www-form-urlencoded request. The live DMX workspace
  ;; assignment route accepts PUT, but rejects that implicit form media
  ;; type with HTTP 415. Force an explicit zero-length body instead.
  (let* ((cookie-values
           (http-dmx-import-request-cookie-values
            client
            :workspace-id workspace-id))
         (cookie-header
           (and cookie-values
                (format nil "~{~A~^; ~}" cookie-values))))
    (append-http-dmx-import-debug-event
     client
     :s8-guarded-repair-request-prepared
     :method :put
     :path (dmx-workspace-assign-object-path workspace-id topic-id)
     :authorization-scheme
     (summarize-http-authorization-scheme
      (effective-http-dmx-import-authorization-header client))
     :cookie-shape
     (summarize-http-cookie-shape cookie-header)
     :jsessionid-cookie-p
     (and (dmx-import-session-cookie-of client) t)
     :workspace-cookie-p
     (and (effective-http-dmx-import-workspace-id
           client
           :workspace-id workspace-id)
          t)
     :accept-header "application/json"
     :content-type nil
     :content-length 0
     :empty-body-p t))
  (http-request-json client
                     :put
                     (dmx-workspace-assign-object-path workspace-id topic-id)
                     :extra-headers '(("Accept" . "application/json"))
                     :workspace-id workspace-id
                     :raw-content ""
                     :content-type nil
                     :content-length 0))

(defun http-topic-present-in-topicmap-p (client topicmap-id topic-id)
  (let ((topicmaps (http-request-json client
                                      :get
                                      (dmx-topicmap-memberships-path topic-id))))
    (find topicmap-id
          (json-array-elements topicmaps)
          :key #'dmx-import-object-id
          :test #'eql)))

(defmethod dmx-import-topic-in-topicmap-p ((client http-dmx-import-client) topicmap-id topic-id)
  (validate-http-dmx-import-client client)
  (and topic-id
       (http-topic-present-in-topicmap-p client topicmap-id topic-id)))

(defmethod dmx-import-add-topic-to-topicmap ((client http-dmx-import-client)
                                             topicmap-id topic-id view-props)
  (validate-http-dmx-import-client client :live? t)
  (ensure-http-dmx-import-session-cookie-for-protected-mutation
   client
   :add-topic-to-topicmap)
  (multiple-value-bind (normalized-view-props)
      (normalize-dmx-topicmap-view-props
       view-props
       :boundary 'dmx-import-add-topic-to-topicmap)
    (http-request-json client
                       :post
                       (dmx-topicmap-add-topic-path topicmap-id topic-id)
                       :body-object normalized-view-props)))

(defmethod dmx-import-set-topic-view-props ((client http-dmx-import-client)
                                            topicmap-id topic-id view-props)
  (validate-http-dmx-import-client client :live? t)
  (ensure-http-dmx-import-session-cookie-for-protected-mutation
   client
   :set-topic-view-props)
  (multiple-value-bind (normalized-view-props)
      (normalize-dmx-topicmap-view-props
       view-props
       :boundary 'dmx-import-set-topic-view-props)
    (http-request-json client
                       :put
                       (dmx-topicmap-set-topic-view-props-path topicmap-id topic-id)
                       :body-object normalized-view-props)))

(defmethod dmx-import-remove-topic-from-topicmap ((client http-dmx-import-client)
                                                  topicmap-id topic-id)
  (validate-http-dmx-import-client client :live? t)
  ;; The current repo contract proves POST/PUT on /topicmaps/<topicmap>/<topic>
  ;; but does not prove DELETE there. OPTIONS on the live route currently omits
  ;; DELETE, so live unlink stays intentionally unsupported until a typed
  ;; contract is demonstrated.
  (error 'dmx-import-unsupported-operation-error
         :message
         (format nil
                 "Live topicmap unlink is unsupported because DELETE is not proven for ~A"
                 (dmx-topicmap-add-topic-path topicmap-id topic-id))
         :operation :remove-topic-from-topicmap
         :endpoint (dmx-topicmap-add-topic-path topicmap-id topic-id)
         :reason "OPTIONS on the live DMX route does not advertise DELETE"))

(defmethod dmx-import-delete-topic ((client http-dmx-import-client) topic-id)
  (validate-http-dmx-import-client client :live? t)
  ;; DELETE on /core/topic/<id> is part of the currently proven DMX HTTP
  ;; contract: OPTIONS on the live route advertises DELETE for topic resources.
  (http-request-json client
                     :delete
                     (dmx-topic-update-path topic-id)))

(defun getenv-non-empty (name)
  (let ((value (uiop:getenv name)))
    (and value
         (> (length value) 0)
         value)))

(defun dmx-import-env-true-p (name)
  (let ((value (getenv-non-empty name)))
    (and value
         (member (string-downcase value)
                 '("1" "true" "yes" "on")
                 :test #'string=)
         t)))

(defun normalize-http-dmx-import-string (value field boundary &key required?)
  (let ((string (and value
                     (string-trim '(#\Space #\Tab #\Newline #\Return)
                                  (princ-to-string value)))))
    (cond
      ((and string (> (length string) 0))
       string)
      (required?
       (error 'dmx-import-config-error
              :message (format nil
                               "Incomplete explicit DMX import auth at ~A: missing ~A"
                               boundary
                               field)
              :missing-keys (list (princ-to-string field))))
      (t
       nil))))

(defun normalize-http-dmx-import-auth-mode (value boundary)
  (cond
    ((or (eq value :basic)
         (string-equal value "basic")
         (string-equal value "username-password")
         (string-equal value "username_password"))
     :basic)
    ((or (eq value :header)
         (string-equal value "header")
         (string-equal value "auth-header")
         (string-equal value "auth_header"))
     :header)
    ((or (eq value :token)
         (string-equal value "token")
         (string-equal value "bearer")
         (string-equal value "bearer-token")
         (string-equal value "bearer_token"))
     :token)
    (t
     (error 'dmx-import-config-error
            :message (format nil
                             "Invalid explicit DMX import auth mode ~S at ~A"
                             value
                             boundary)
            :missing-keys '("auth-mode")))))

(defun explicit-http-dmx-import-authorization-header
    (&key auth-mode authorization-header auth-token username password
       (boundary 'explicit-http-dmx-import-authorization-header))
  (ecase (normalize-http-dmx-import-auth-mode auth-mode boundary)
    (:basic
     (basic-authorization-header
      (normalize-http-dmx-import-string username :username boundary :required? t)
      (normalize-http-dmx-import-string password :password boundary :required? t)))
    (:header
     (normalize-http-dmx-import-string authorization-header
                                       :authorization-header
                                       boundary
                                       :required? t))
    (:token
     (format nil
             "Bearer ~A"
             (normalize-http-dmx-import-string auth-token
                                               :auth-token
                                               boundary
                                               :required? t)))))

(defun normalize-http-dmx-import-derived-auth-scheme
    (value auth-mode boundary)
  (cond
    ((null value)
     (if (eq auth-mode :basic) :basic :dmx))
    ((or (eq value :basic)
         (string-equal value "basic"))
     :basic)
    ((or (eq value :dmx)
         (string-equal value "dmx"))
     :dmx)
    (t
     (error 'dmx-import-config-error
            :message (format nil
                             "Invalid explicit DMX derived auth scheme ~S at ~A"
                             value
                             boundary)
            :missing-keys '("derived-auth-scheme")))))

(defun make-http-dmx-import-client-from-explicit-auth
    (&key base-url workspace-id topic-type-uri verbose auth-mode
       authorization-header auth-token username password
       (bootstrap-session-p nil bootstrap-session-supplied-p)
       derived-auth-scheme)
  (let* ((boundary 'make-http-dmx-import-client-from-explicit-auth)
         (resolved-auth-mode
           (normalize-http-dmx-import-auth-mode auth-mode boundary))
         (resolved-bootstrap-session-p
           (if bootstrap-session-supplied-p
               (and bootstrap-session-p t)
               (eq resolved-auth-mode :basic)))
         (resolved-derived-auth-scheme
           (normalize-http-dmx-import-derived-auth-scheme
            derived-auth-scheme
            resolved-auth-mode
            boundary))
         (resolved-base-url
           (or (normalize-http-dmx-import-string base-url :base-url boundary)
               (getenv-non-empty "HYPERDOC_DMX_IMPORT_BASE_URL")))
         (resolved-workspace-id
           (cond
             ((null workspace-id) nil)
             (t
              (or (parse-positive-integer workspace-id)
                  (and (integerp workspace-id) (plusp workspace-id) workspace-id)
                  (error 'dmx-import-config-error
                         :message (format nil
                                          "Invalid explicit DMX import workspace id ~S at ~A"
                                          workspace-id
                                          boundary)
                         :missing-keys '("workspace-id"))))))
         (resolved-topic-type-uri
           (or (normalize-http-dmx-import-string topic-type-uri :topic-type-uri boundary)
               (getenv-non-empty "HYPERDOC_DMX_IMPORT_TOPIC_TYPE_URI")
               *dmx-fedwiki-page-type-uri*))
         (resolved-auth-header
           (explicit-http-dmx-import-authorization-header
            :auth-mode resolved-auth-mode
            :authorization-header authorization-header
            :auth-token auth-token
            :username username
            :password password
            :boundary boundary)))
    (unless resolved-base-url
      (error 'dmx-import-config-error
             :message "Incomplete explicit DMX import configuration"
             :missing-keys '("HYPERDOC_DMX_IMPORT_BASE_URL" "base-url")))
    (let ((client
            (make-instance 'http-dmx-import-client
                           :base-url resolved-base-url
                           :authorization-header resolved-auth-header
                           :session-login-required-p
                           resolved-bootstrap-session-p
                           :bootstrap-session-p resolved-bootstrap-session-p
                           :derived-auth-scheme
                           resolved-derived-auth-scheme
                           :workspace-id resolved-workspace-id
                           :topic-type-uri resolved-topic-type-uri
                           :verbose verbose)))
      (append-http-dmx-import-debug-event
       client
       :s3-explicit-auth-client-built
       :auth-mode resolved-auth-mode
       :authorization-scheme
       (summarize-http-authorization-scheme resolved-auth-header)
       :username-present-p
       (and (dmx-non-empty-string-p username) t)
       :password-present-p
       (and (dmx-non-empty-string-p password) t)
       :authorization-header-present-p
       (and (dmx-non-empty-string-p authorization-header) t)
       :auth-token-present-p
       (and (dmx-non-empty-string-p auth-token) t)
       :session-login-required-p
       resolved-bootstrap-session-p
       :bootstrap-session-p resolved-bootstrap-session-p
       :derived-auth-scheme resolved-derived-auth-scheme
       :workspace-id resolved-workspace-id)
      client)))

(defun make-http-dmx-import-client-from-environment (&key verbose)
  (let* ((base-url (getenv-non-empty "HYPERDOC_DMX_IMPORT_BASE_URL"))
         (topic-type-uri
           (getenv-non-empty "HYPERDOC_DMX_IMPORT_TOPIC_TYPE_URI"))
         (workspace-id
           (let ((value (getenv-non-empty "HYPERDOC_DMX_IMPORT_WORKSPACE_ID")))
             (when value
               (or (parse-positive-integer value)
                   (error 'dmx-import-config-error
                          :message
                          (format nil
                                  "Invalid DMX import workspace id ~S in HYPERDOC_DMX_IMPORT_WORKSPACE_ID"
                                  value))))))
         (configured-auth-header
           (getenv-non-empty "HYPERDOC_DMX_IMPORT_AUTH_HEADER"))
         (configured-username
           (getenv-non-empty "HYPERDOC_DMX_IMPORT_USERNAME"))
         (configured-password
           (getenv-non-empty "HYPERDOC_DMX_IMPORT_PASSWORD"))
         (auth-header
           (or configured-auth-header
               (when (and configured-username configured-password)
                 (basic-authorization-header configured-username
                                             configured-password))))
         (session-login-required-p
           (and auth-header
                (string= (summarize-http-authorization-scheme auth-header)
                         "Basic")))
         (bootstrap-session-p
           (or session-login-required-p
               (dmx-import-env-true-p
                "HYPERDOC_DMX_IMPORT_BOOTSTRAP_SESSION")))
         (derived-auth-scheme
           (if session-login-required-p :basic :dmx))
         (legacy-auth-token
           (getenv-non-empty "HYPERDOC_DMX_IMPORT_AUTH_TOKEN")))
    (when (or base-url topic-type-uri auth-header legacy-auth-token)
      (make-instance 'http-dmx-import-client
                     :base-url base-url
                     :authorization-header (or auth-header
                                               (and legacy-auth-token
                                                   (format nil "Bearer ~A"
                                                           legacy-auth-token)))
                     :session-login-required-p bootstrap-session-p
                     :bootstrap-session-p bootstrap-session-p
                     :derived-auth-scheme derived-auth-scheme
                     :workspace-id workspace-id
                     :topic-type-uri (or topic-type-uri
                                         *dmx-fedwiki-page-type-uri*)
                     :verbose verbose))))

(defun make-default-dmx-import-client (&key dry-run verbose)
  (declare (ignore dry-run))
  (let ((client (make-http-dmx-import-client-from-environment :verbose verbose)))
    (cond
      ((and client
            (dmx-import-base-url-of client))
       client)
      (t
       (make-instance 'null-dmx-import-client)))))

(defparameter *dmx-auth-crosswalk-default-workspace-id* 919815)
(defparameter *dmx-auth-crosswalk-default-topic-id* 922464)
(defparameter *dmx-auth-crosswalk-default-username* "alice")
(defparameter *dmx-auth-crosswalk-default-password* "example-password")
(defparameter *dmx-auth-crosswalk-default-basic-header*
  "Basic YWxpY2U6ZXhhbXBsZS1wYXNzd29yZA==")
(defparameter *dmx-auth-crosswalk-default-bearer-token*
  "eyJhbGciOi...example")

(defclass dmx-auth-path-example (state-machine-run)
  ((input-mode :reader dmx-auth-path-example-input-mode-of
               :reader dmx-auth-mode-example-chosen-mode-of
               :initarg :input-mode)
   (raw-input :reader dmx-auth-path-example-raw-input-of
              :reader dmx-auth-mode-example-raw-fields-of
              :initarg :raw-input
              :initform nil)
   (normalized-mode :reader dmx-auth-path-example-normalized-mode-of
                    :reader dmx-auth-mode-example-normalized-mode-of
                    :initarg :normalized-mode)
   (derived-request-shape
    :reader dmx-auth-path-example-derived-request-shape-of
    :initarg :derived-request-shape
    :initform nil)
   (dmx-credentials-shape
    :reader dmx-auth-path-example-dmx-credentials-shape-of
    :reader dmx-auth-mode-example-derived-credentials-of
    :initarg :dmx-credentials-shape
    :initform nil)
   (authorization-method-name
    :reader dmx-auth-path-example-authorization-method-name-of
    :initarg :authorization-method-name
    :initform nil)
   (bootstrap-required-p
    :reader dmx-auth-path-example-bootstrap-required-p-of
    :reader dmx-auth-mode-example-bootstrap-capable-p-of
    :initarg :bootstrap-required-p
    :initform nil)
   (session-transition
    :reader dmx-auth-path-example-session-transition-of
    :initarg :session-transition
    :initform nil)
   (post-login-request-shape
    :reader dmx-auth-path-example-post-login-request-shape-of
    :reader dmx-auth-mode-example-post-bootstrap-request-shape-of
    :initarg :post-login-request-shape
    :initform nil)
   (state-trace
    :reader dmx-auth-path-example-state-trace-of
    :reader dmx-auth-mode-example-state-machine-steps-of
    :initarg :state-trace
    :initform nil)
   (source-evidence
    :reader dmx-auth-path-example-source-evidence-of
    :reader dmx-auth-mode-example-source-evidence-of
    :initarg :source-evidence
    :initform nil)
   (installation-dependencies
    :reader dmx-auth-path-example-installation-dependencies-of
    :initarg :installation-dependencies
    :initform nil)
   (detected-authorization-scheme
    :reader dmx-auth-mode-example-detected-authorization-scheme-of
    :initarg :detected-authorization-scheme
    :initform nil)
   (derived-authorization-header
    :reader dmx-auth-mode-example-derived-authorization-header-of
    :initarg :derived-authorization-header
    :initform nil)
   (bootstrap-request-shape
    :reader dmx-auth-mode-example-bootstrap-request-shape-of
    :initarg :bootstrap-request-shape
    :initform nil)
   (expected-cookie-shape
    :reader dmx-auth-mode-example-expected-cookie-shape-of
    :initarg :expected-cookie-shape
    :initform "none")
   (summarized-request-auth-mode
    :reader dmx-auth-mode-example-summarized-request-auth-mode-of
    :initarg :summarized-request-auth-mode
    :initform "anonymous")
   (workspace-id
    :reader dmx-auth-mode-example-workspace-id-of
    :initarg :workspace-id
    :initform *dmx-auth-crosswalk-default-workspace-id*)
   (topic-id
    :reader dmx-auth-mode-example-topic-id-of
    :initarg :topic-id
    :initform *dmx-auth-crosswalk-default-topic-id*)))

(defgeneric dmx-auth-path-example-notes-of (example))

(defmethod dmx-auth-path-example-notes-of ((example dmx-auth-path-example))
  (state-machine-run-notes-of example))

(defgeneric dmx-auth-mode-example-contract-notes-of (example))

(defmethod dmx-auth-mode-example-contract-notes-of
    ((example dmx-auth-path-example))
  (state-machine-run-notes-of example))

(defclass dmx-auth-crosswalk ()
  ((id :reader id-of
       :initarg :id
       :initform "dmx-auth-crosswalk/three-mode")
   (title :reader title-of
          :initarg :title
          :initform "HyperDoc three-mode DMX auth crosswalk")
   (summary :reader summary-of
            :initarg :summary
            :initform
            "Inspectable learning object that keeps the three HyperDoc DMX auth input modes, the DMX-side Authorization to Credentials path, and the JSESSIONID aftermath visible without changing guarded live behavior.")
   (examples :reader dmx-auth-crosswalk-examples-of
             :initarg :examples
             :initform nil)))

(defmethod print-object ((object dmx-auth-path-example) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dmx-auth-crosswalk) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun dmx-auth-mode-label (mode)
  (case (normalize-http-dmx-import-auth-mode mode 'dmx-auth-mode-label)
    (:basic "username/password")
    (:header "authorization header")
    (:token "bearer token")))

(defun base64-character-value (char)
  (let ((position (position char *base64-alphabet* :test #'char=)))
    (cond
      (position position)
      ((char= char #\=) nil)
      (t
       (error 'dmx-import-config-error
              :message (format nil
                               "Invalid Base64 character ~S while decoding Authorization header example"
                               char))))))

(defun decode-base64-string-to-octets (encoded)
  (let* ((clean (remove-if (lambda (char)
                             (find char '(#\Space #\Tab #\Newline #\Return)))
                           encoded))
         (length (length clean)))
    (unless (zerop (mod length 4))
      (error 'dmx-import-config-error
             :message (format nil
                              "Invalid Base64 length ~D while decoding Authorization header example"
                              length)))
    (let ((octets (make-array 0
                              :element-type '(unsigned-byte 8)
                              :adjustable t
                              :fill-pointer 0)))
      (loop for index from 0 below length by 4
            for c1 = (char clean index)
            for c2 = (char clean (1+ index))
            for c3 = (char clean (+ index 2))
            for c4 = (char clean (+ index 3))
            for v1 = (base64-character-value c1)
            for v2 = (base64-character-value c2)
            for v3 = (base64-character-value c3)
            for v4 = (base64-character-value c4)
            do (unless (and (integerp v1) (integerp v2))
                 (error 'dmx-import-config-error
                        :message "Invalid Base64 quartet while decoding Authorization header example"))
               (let ((triple (logior (ash v1 18)
                                     (ash v2 12)
                                     (ash (or v3 0) 6)
                                     (or v4 0))))
                 (vector-push-extend (ldb (byte 8 16) triple) octets)
                 (unless (null v3)
                   (vector-push-extend (ldb (byte 8 8) triple) octets))
                 (unless (null v4)
                   (vector-push-extend (ldb (byte 8 0) triple) octets))))
      octets)))

(defun latin1-octets-to-string (octets)
  (with-output-to-string (stream)
    (loop for octet across octets
          do (write-char (or (code-char octet) #\?) stream))))

(defun split-http-authorization-header (authorization-header)
  (let* ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return)
                               (or authorization-header "")))
         (separator
           (position-if (lambda (char)
                          (find char '(#\Space #\Tab)))
                        trimmed)))
    (if separator
        (list (subseq trimmed 0 separator)
              (string-trim '(#\Space #\Tab)
                           (subseq trimmed separator)))
        (list trimmed ""))))

(defun decode-basic-authorization-header-for-display (authorization-header)
  (destructuring-bind (method token)
      (split-http-authorization-header authorization-header)
    (when (and (plusp (length token))
               (string-equal method "Basic"))
      (let* ((decoded
               (latin1-octets-to-string
                (decode-base64-string-to-octets token)))
             (separator (position #\: decoded))
             (username (if separator
                           (subseq decoded 0 separator)
                           decoded))
             (password (if separator
                           (subseq decoded (1+ separator))
                           "")))
        (list (cons "username" username)
              (cons "password" password)
              (cons "methodName" method))))))

(defun dmx-auth-path-example-state-trace (mode)
  (let ((resolved-mode
          (normalize-http-dmx-import-auth-mode
           mode
           'dmx-auth-path-example-state-trace)))
    (append
     (list
      (list :label "S1 credentials captured in UI"
            :detail "The chosen mode now has enough raw input to derive an outgoing request shape."
            :classification "HyperDoc-derived")
      (list :label "S2 auth mode selected"
            :detail (format nil
                            "The active mode is ~A."
                            (dmx-auth-mode-label resolved-mode))
            :classification "HyperDoc-derived")
      (list :label "S3 explicit auth client built"
            :detail "HyperDoc normalizes the selected mode and derives the outgoing Authorization/session behavior without storing credentials durably."
            :classification "HyperDoc-derived"))
     (when (eq resolved-mode :basic)
       (list
        (list :label "S4 bootstrap request prepared"
              :detail "Username/password mode turns into a Basic Authorization header for POST /access-control/login."
              :classification "HyperDoc-derived")
        (list :label "S5 bootstrap request sent"
              :detail "DMX sees an Authorization header and constructs Credentials from it."
              :classification "DMX-core-native")
        (list :label "S6 bootstrap response received"
              :detail "Success is expected to return Set-Cookie: JSESSIONID=..."
              :classification "DMX-core-native")
        (list :label "S7 session material extracted"
              :detail "HyperDoc keeps JSESSIONID ephemerally and switches later guarded requests to session-backed auth."
              :classification "HyperDoc-derived")))
     (list
      (list :label "S8 guarded request prepared"
            :detail "The guarded repair/action request is shaped with either a carried Authorization header or the session cookie aftermath."
            :classification "HyperDoc-derived")
      (list :label "S9 guarded request sent"
            :detail "DMX evaluates object/workspace ACL at the actual mutation endpoint."
            :classification "DMX-core-native")
      (list :label "S10 guarded response received"
            :detail "The first real blocking boundary appears here if ACL, workspace assignment, or installation-specific auth support is missing."
            :classification "Shared boundary")))))

(defun dmx-auth-mode-example-state-machine-steps (mode)
  (dmx-auth-path-example-state-trace mode))

(defun dmx-auth-path-example-source-evidence (mode)
  (let ((resolved-mode
          (normalize-http-dmx-import-auth-mode
           mode
           'dmx-auth-path-example-source-evidence)))
    (append
     (list
      (list :layer "HyperDoc"
            :reference "hyperdoc/dmx-import.lisp :: normalize-http-dmx-import-auth-mode"
            :detail "Normalizes username/password, authorization header, and bearer token into the three explicit input modes.")
      (list :layer "HyperDoc"
            :reference "hyperdoc/dmx-import.lisp :: explicit-http-dmx-import-authorization-header"
            :detail "Builds the outgoing Authorization header for the selected input mode.")
      (list :layer "HyperDoc"
            :reference "hyperdoc/dmx-import.lisp :: make-http-dmx-import-client-from-explicit-auth"
            :detail "Marks username/password mode as session-login-required and preserves direct-header modes as direct-header only.")
      (list :layer "HyperDoc"
            :reference "hyperdoc/dmx-import.lisp :: summarize-http-authorization-scheme / summarize-http-cookie-shape / summarize-http-request-auth-mode"
            :detail "Produces the same auth and cookie summaries already used in the repair-console traces.")
      (list :layer "DMX platform"
            :reference "systems.dmx.accesscontrol.AccessControlPlugin.checkAuthorization"
            :detail "Reads Authorization, builds Credentials, resolves AuthorizationMethod for non-Basic method names, or falls back to AnonymousAccessFilter.")
      (list :layer "DMX platform"
            :reference "systems.dmx.core.service.accesscontrol.Credentials(String authHeader)"
            :detail "Parses the Authorization header into username/password/methodName for the DMX-side credential check path.")
      (list :layer "DMX platform"
            :reference "systems.dmx.accesscontrol.AccessControlPlugin.tryLogin / _login"
            :detail "Checks credentials and, on success, attaches username to the servlet session."))
     (when (eq resolved-mode :token)
       (list
        (list :layer "DMX platform"
              :reference "systems.dmx.accesscontrol.AuthorizationMethod"
              :detail "Bearer-like support depends on a registered non-Basic AuthorizationMethod or a compatible installation-specific gateway boundary.")))
     (list
      (list :layer "DMX platform"
            :reference "systems.dmx.accesscontrol.AnonymousAccessFilter"
            :detail "Anonymous access is a fallback filter for request prefixes and is not the primary repair-console input mode.")))))

(defun dmx-auth-mode-example-source-evidence (mode)
  (dmx-auth-path-example-source-evidence mode))

(defun dmx-auth-path-example-notes (mode)
  (let ((resolved-mode
          (normalize-http-dmx-import-auth-mode
           mode
           'dmx-auth-path-example-notes)))
    (case resolved-mode
      (:basic
       (list
        (list :label "Username/password input"
              :classification "HyperDoc-derived"
              :detail "This is a repair-console operator input mode, not a separate DMX wire format. HyperDoc derives an equivalent Basic Authorization header for the bootstrap request.")
        (list :label "Credentials path"
              :classification "DMX-core-native"
              :detail "DMX reads the Authorization header, constructs Credentials, checks them, and then attaches username to the servlet session.")
        (list :label "JSESSIONID aftermath"
              :classification "HyperDoc-derived"
              :detail "JSESSIONID is the later session-backed request shape after a successful bootstrap. It is not a primary credential entry mode.")))
      (:header
       (list
        (list :label "Authorization header input"
              :classification "HyperDoc-derived"
              :detail "HyperDoc preserves the supplied Authorization header exactly and does not synthesize a separate login bootstrap in this mode.")
        (list :label "Basic header decoding"
              :classification "DMX-core-native"
              :detail "If the supplied header is Basic, DMX-core-native Credentials parsing can be displayed safely as username/password/methodName for learning purposes.")
        (list :label "Session aftermath"
              :classification "HyperDoc-derived"
              :detail "Direct-header mode remains direct-header only in HyperDoc. JSESSIONID is not assumed unless the installation creates one separately.")))
      (:token
       (list
        (list :label "Bearer token input"
              :classification "HyperDoc-derived"
              :detail "HyperDoc synthesizes Authorization: Bearer <token> from the entered token.")
        (list :label "Backend contract"
              :classification "Installation-dependent"
              :detail "Bearer support is not universally native to DMX core. It depends on a registered non-Basic AuthorizationMethod or a compatible proxy/gateway in front of DMX.")
        (list :label "Anonymous fallback"
              :classification "DMX-core-native"
              :detail "AnonymousAccessFilter may still allow read paths, but guarded repair/mutation must not rely on anonymous fallback."))))))

(defun dmx-auth-mode-example-contract-notes (mode)
  (dmx-auth-path-example-notes mode))

(defun dmx-auth-path-example-installation-dependencies (mode &key detected-scheme)
  (let ((resolved-mode
          (normalize-http-dmx-import-auth-mode
           mode
           'dmx-auth-path-example-installation-dependencies)))
    (case resolved-mode
      (:basic
       (list
        (list :label "DMX core path"
              :classification "DMX-core-native"
              :detail "Basic Authorization parsing into Credentials and session bootstrap through /access-control/login are native DMX paths.")))
      (:header
       (if (or (null detected-scheme)
               (string= detected-scheme "Basic"))
           (list
            (list :label "Direct Basic header"
                  :classification "DMX-core-native"
                  :detail "A Basic Authorization header is directly interpretable by DMX Credentials without installation-specific extensions."))
           (list
            (list :label "Custom non-Basic scheme"
                  :classification "Installation-dependent"
                  :detail "A non-Basic Authorization header needs a matching AuthorizationMethod inside DMX or a compatible proxy/gateway that translates it before DMX checks credentials."))))
      (:token
        (list
         (list :label "Bearer support"
              :classification "Installation-dependent"
              :detail "Bearer token examples depend on a registered non-Basic AuthorizationMethod or a compatible proxy/gateway. HyperDoc does not claim bearer is universally native to DMX core."))))))

(defun dmx-auth-state-machine-source-evidence ()
  (list
   (list :layer "HyperDoc page"
         :reference "State machine"
         :detail "Generic reusable machine abstraction page for definition objects, run objects, and derived visualization.")
   (list :layer "HyperDoc page"
         :reference "Operational definition: state machine, state, transition, guard, run trace"
         :detail "Durable operational definition for the definition/run split used by this auth example.")
   (list :layer "HyperDoc page"
         :reference "Inspectable authentication-path traces for repair console"
         :detail "DMX auth remains one worked example instance of the generic machine model.")
   (list :layer "HyperDoc page"
         :reference "HyperDoc three-mode DMX auth crosswalk"
         :detail "Worked example crosswalk built from dmx-auth-path-example runtime objects.")
   (list :layer "Lisp source"
         :reference "hyperdoc/state-machines.lisp"
         :detail "Generic machine-definition and run runtime objects.")
   (list :layer "Lisp source"
         :reference "hyperdoc/dmx-import.lisp"
         :detail "DMX auth example specialization and request-shape derivation.")
   (list :layer "Test"
         :reference "tests/state-machine-smoke.lisp"
         :detail "Smoke coverage for the generic machine abstraction and the DMX auth example instance.")))

(defun make-dmx-auth-state-machine-definition ()
  (make-state-machine-definition
   :id "state-machine-definition/dmx-auth-path"
   :title "DMX auth path state machine"
   :summary
   "Generic state-machine-definition describing how HyperDoc auth inputs become request shapes, DMX-side credential interpretation, optional AuthorizationMethod resolution, session aftermath, and the later guarded request form."
   :states
   (list
    (make-state-machine-state
     :id "input-captured"
     :title "Input captured"
     :summary "One concrete operator input bundle is present."
     :role :initial
     :entry-condition "User has supplied one bounded auth example input."
     :exit-condition "Mode normalization begins")
    (make-state-machine-state
     :id "mode-normalized"
     :title "Mode normalized"
     :summary "HyperDoc has resolved the input into one supported auth mode."
     :entry-condition "normalize-http-dmx-import-auth-mode returned a stable mode"
     :exit-condition "Outgoing request shape is derived")
    (make-state-machine-state
     :id "request-shaped"
     :title "Request shaped"
     :summary "Authorization header and bootstrap/direct-header consequences are derived."
     :entry-condition "Derived Authorization/session shape is inspectable"
     :exit-condition "DMX-side interpretation path is identified")
    (make-state-machine-state
     :id "credentials-interpreted"
     :title "Credentials interpreted"
     :summary "DMX-core-native Credentials parsing is applicable to the request."
     :entry-condition "Basic or directly decodable Basic header is present"
     :exit-condition "Either bootstrap or direct-header carry path is chosen")
    (make-state-machine-state
     :id "authorization-method-resolved"
     :title "AuthorizationMethod resolved"
     :summary "A non-Basic scheme depends on a named AuthorizationMethod or compatible gateway."
     :entry-condition "Non-Basic header or bearer path is in play"
     :exit-condition "Either guarded request can be shaped or failure boundary is explicit")
    (make-state-machine-state
     :id "session-established"
     :title "Session established"
     :summary "Bootstrap succeeded and JSESSIONID exists as session aftermath."
     :entry-condition "POST /access-control/login succeeded"
     :exit-condition "Later guarded request uses session-backed cookie state")
    (make-state-machine-state
     :id "guarded-request-shaped"
     :title "Guarded request shaped"
     :summary "The later guarded request shape is inspectable."
     :role :terminal
     :entry-condition "Auth path has produced the later request shape"
     :notes "Terminal teaching state for the bounded example object.")
    (make-state-machine-state
     :id "failure-boundary"
     :title "Failure boundary"
     :summary "The auth path reached an explicit unmet-contract or denied branch."
     :role :failure
     :entry-condition "Required backend contract or support condition is missing"
     :notes "Explicit failure state for missing AuthorizationMethod or denied auth paths."))
   :transitions
   (list
    (make-state-machine-transition
     :id "capture->normalize"
     :from-state "input-captured"
     :to-state "mode-normalized"
     :trigger "normalize-mode"
     :guard "supported-input-mode"
     :emitted-evidence "normalized-mode"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "normalize->shape"
     :from-state "mode-normalized"
     :to-state "request-shaped"
     :trigger "derive-request-shape"
     :guard "supported-mode"
     :emitted-evidence "authorization-header-and-cookie-shape"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "shape->credentials"
     :from-state "request-shaped"
     :to-state "credentials-interpreted"
     :trigger "parse-basic-credentials"
     :guard "basic-or-basic-header"
     :emitted-evidence "dmx-credentials-shape"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "shape->authorization-method"
     :from-state "request-shaped"
     :to-state "authorization-method-resolved"
     :trigger "resolve-authorization-method"
     :guard "non-basic-header-or-token"
     :emitted-evidence "authorization-method-name"
     :side-effects "installation-dependent lookup"
     :reversible-p nil)
    (make-state-machine-transition
     :id "credentials->session"
     :from-state "credentials-interpreted"
     :to-state "session-established"
     :trigger "bootstrap-session"
     :guard "bootstrap-required"
     :emitted-evidence "jsessionid-aftermath"
     :side-effects "session becomes request-carried state"
     :reversible-p nil)
    (make-state-machine-transition
     :id "credentials->guarded-request"
     :from-state "credentials-interpreted"
     :to-state "guarded-request-shaped"
     :trigger "carry-direct-basic-header"
     :guard "direct-header-mode"
     :emitted-evidence "guarded-request-shape"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "authorization-method->guarded-request"
     :from-state "authorization-method-resolved"
     :to-state "guarded-request-shaped"
     :trigger "carry-direct-header"
     :guard "authorization-method-available-or-proxy-compatible"
     :emitted-evidence "guarded-request-shape"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "authorization-method->failure"
     :from-state "authorization-method-resolved"
     :to-state "failure-boundary"
     :trigger "resolve-authorization-method"
     :guard "authorization-method-missing"
     :emitted-evidence "installation-dependent-failure-note"
     :side-effects "no authenticated session"
     :reversible-p nil)
    (make-state-machine-transition
     :id "session->guarded-request"
     :from-state "session-established"
     :to-state "guarded-request-shaped"
     :trigger "prepare-guarded-request"
     :guard "session-cookie-present"
     :emitted-evidence "guarded-request-shape"
     :side-effects "later request now carries JSESSIONID aftermath"
     :reversible-p nil))
   :initial-state "input-captured"
   :terminal-states '("guarded-request-shaped")
   :guards '("supported-input-mode"
             "supported-mode"
             "basic-or-basic-header"
             "non-basic-header-or-token"
             "bootstrap-required"
             "direct-header-mode"
             "authorization-method-available-or-proxy-compatible"
             "authorization-method-missing"
             "session-cookie-present")
   :events '("normalize-mode"
             "derive-request-shape"
             "parse-basic-credentials"
             "resolve-authorization-method"
             "bootstrap-session"
             "carry-direct-basic-header"
             "carry-direct-header"
             "prepare-guarded-request")
   :invariants
   (list
    (list :label "One normalized mode"
          :detail "Each concrete auth example resolves to exactly one supported input mode.")
    (list :label "Derived request before backend interpretation"
          :detail "The outgoing request shape is derived before DMX-side Credentials interpretation or AuthorizationMethod lookup is discussed.")
    (list :label "JSESSIONID is aftermath"
          :detail "Session cookie state is modeled as a later consequence of bootstrap, never as a primary operator input mode.")
    (list :label "Failure is explicit"
          :detail "Installation-dependent non-Basic support failures terminate at an explicit failure boundary rather than being silently treated as anonymous success."))
   :failure-states '("failure-boundary")
   :source-evidence (dmx-auth-state-machine-source-evidence)
   :notes
   (list
    (list :label "Worked example"
          :detail "This is a DMX-auth-specific instance of the generic state-machine abstraction, not the abstraction itself."))
   :multi-initial-p nil
   :multi-current-p nil
   :allow-terminal-outgoing-p nil
   :acyclic-p t))

(defun dmx-auth-path-example-visited-states (mode &key detected-scheme)
  (let ((resolved-mode
          (normalize-http-dmx-import-auth-mode
           mode
           'dmx-auth-path-example-visited-states)))
    (case resolved-mode
      (:basic
       '("input-captured"
         "mode-normalized"
         "request-shaped"
         "credentials-interpreted"
         "session-established"
         "guarded-request-shaped"))
      (:header
       (if (or (null detected-scheme)
               (string= detected-scheme "Basic"))
           '("input-captured"
             "mode-normalized"
             "request-shaped"
             "credentials-interpreted"
             "guarded-request-shaped")
           '("input-captured"
             "mode-normalized"
             "request-shaped"
             "authorization-method-resolved"
             "guarded-request-shaped")))
      (:token
       '("input-captured"
         "mode-normalized"
         "request-shaped"
         "authorization-method-resolved"
         "guarded-request-shaped")))))

(defun dmx-auth-path-example-transition-trace (visited-states)
  (loop for from-state in visited-states
        for to-state in (rest visited-states)
        for timestamp from 1
        collect
        (list :timestamp timestamp
              :kind :transition
              :transition-id
              (cond
                ((and (equal from-state "input-captured")
                      (equal to-state "mode-normalized"))
                 "capture->normalize")
                ((and (equal from-state "mode-normalized")
                      (equal to-state "request-shaped"))
                 "normalize->shape")
                ((and (equal from-state "request-shaped")
                      (equal to-state "credentials-interpreted"))
                 "shape->credentials")
                ((and (equal from-state "request-shaped")
                      (equal to-state "authorization-method-resolved"))
                 "shape->authorization-method")
                ((and (equal from-state "credentials-interpreted")
                      (equal to-state "session-established"))
                 "credentials->session")
                ((and (equal from-state "credentials-interpreted")
                      (equal to-state "guarded-request-shaped"))
                 "credentials->guarded-request")
                ((and (equal from-state "authorization-method-resolved")
                      (equal to-state "guarded-request-shaped"))
                 "authorization-method->guarded-request")
                ((and (equal from-state "authorization-method-resolved")
                      (equal to-state "failure-boundary"))
                 "authorization-method->failure")
                ((and (equal from-state "session-established")
                      (equal to-state "guarded-request-shaped"))
                 "session->guarded-request")
                (t
                 (format nil "~A->~A" from-state to-state)))
              :from-state from-state
              :to-state to-state
              :detail
              (format nil "Auth path progressed from ~A to ~A."
                      from-state
                      to-state))))

(defun dmx-auth-path-example-evidence-trace
    (mode
     derived-authorization-header
     derived-credentials
     detected-scheme
     session-transition
     post-bootstrap-request-shape
     &key detected-authorization-method)
  (let ((resolved-mode
          (normalize-http-dmx-import-auth-mode
           mode
           'dmx-auth-path-example-evidence-trace)))
    (append
     (list
      (list :timestamp 0
            :kind :state-entry
            :state-id "input-captured"
            :evidence "A bounded auth example input bundle is present.")
      (list :timestamp 1
            :kind :transition
            :transition-id "capture->normalize"
            :evidence
            (format nil "Normalized mode: ~A."
                    (dmx-auth-mode-label resolved-mode)))
      (list :timestamp 2
            :kind :state-entry
            :state-id "request-shaped"
            :evidence
            (format nil "Derived Authorization header: ~A."
                    (or derived-authorization-header "-"))))
     (if (eq resolved-mode :token)
         (list
          (list :timestamp 3
                :kind :state-entry
                :state-id "authorization-method-resolved"
                :evidence
                (format nil
                        "Non-Basic path requires AuthorizationMethod or compatible gateway: ~A."
                        (or detected-authorization-method
                            detected-scheme
                            "Bearer"))))
         (list
          (list :timestamp 3
                :kind :state-entry
                :state-id "credentials-interpreted"
                :evidence
                (format nil "DMX Credentials-like summary: ~A."
                        derived-credentials))))
     (when (eq resolved-mode :basic)
       (list
        (list :timestamp 4
              :kind :state-entry
              :state-id "session-established"
              :evidence
              (format nil "Expected session aftermath: ~A."
                      (or (cdr (assoc "Session aftermath"
                                      session-transition
                                      :test #'equal))
                          "JSESSIONID=<session-id>")))))
     (list
      (list :timestamp 5
            :kind :state-entry
            :state-id "guarded-request-shaped"
            :evidence
            (format nil "Later guarded request shape: ~A."
                    post-bootstrap-request-shape))))))

(defun make-dmx-auth-path-example
    (&key auth-mode username password authorization-header auth-token
       (workspace-id *dmx-auth-crosswalk-default-workspace-id*)
       (topic-id *dmx-auth-crosswalk-default-topic-id*))
  (let* ((resolved-mode
           (normalize-http-dmx-import-auth-mode
            auth-mode
            'make-dmx-auth-path-example))
         (raw-fields
           (case resolved-mode
             (:basic
              (list (cons "Username" (or username ""))
                    (cons "Password" (or password ""))))
             (:header
              (list (cons "Authorization header" (or authorization-header ""))))
             (:token
              (list (cons "Bearer token" (or auth-token ""))))))
         (derived-authorization-header
           (explicit-http-dmx-import-authorization-header
            :auth-mode resolved-mode
            :authorization-header authorization-header
            :auth-token auth-token
            :username username
            :password password
            :boundary 'make-dmx-auth-path-example))
         (detected-scheme
           (summarize-http-authorization-scheme
            derived-authorization-header))
         (authorization-method-name
           (case resolved-mode
             (:basic "Basic")
             (:header detected-scheme)
             (:token "Bearer")))
         (derived-credentials
           (case resolved-mode
             (:basic
              (list (cons "username" (or username ""))
                    (cons "password" (or password ""))
                    (cons "methodName" "Basic")))
             (:header
              (or (ignore-errors
                    (decode-basic-authorization-header-for-display
                     derived-authorization-header))
                  (list (cons "note"
                              "No DMX-core-native Credentials summary available for this header."))))
             (:token
              (list (cons "note"
                          "No DMX-core-native Credentials summary is assumed for an arbitrary bearer token example.")))))
         (bootstrap-request-shape
           (if (eq resolved-mode :basic)
               (list (cons "Method" "POST")
                     (cons "Path" (dmx-access-control-login-path))
                     (cons "Authorization header" derived-authorization-header)
                     (cons "Cookie" "-")
                     (cons "Cookie shape" "none")
                     (cons "Accept" "-")
                     (cons "Content-Length" "0")
                     (cons "Content-Type" "-")
                     (cons "Summarized request auth mode"
                           (summarize-http-request-auth-mode
                            derived-authorization-header
                            nil)))
               (list (cons "Status" "not used")
                     (cons "Reason"
                           "This mode is direct-header only in HyperDoc and does not synthesize a separate login bootstrap request."))))
         (post-cookie-header
           (case resolved-mode
             (:basic
              (format nil "JSESSIONID=<session-id>; dmx_workspace_id=~D"
                      workspace-id))
             (otherwise
              (format nil "dmx_workspace_id=~D" workspace-id))))
         (post-authorization-header
           (if (eq resolved-mode :basic)
               nil
               derived-authorization-header))
         (post-bootstrap-request-shape
           (list (cons "Method" "PUT")
                 (cons "Path"
                       (dmx-workspace-assign-object-path workspace-id topic-id))
                 (cons "Authorization header"
                       (or post-authorization-header "-"))
                 (cons "Cookie" post-cookie-header)
                 (cons "Cookie shape"
                       (summarize-http-cookie-shape post-cookie-header))
                 (cons "Accept" "application/json")
                 (cons "Content-Length" "0")
                 (cons "Content-Type" "-")
                 (cons "Summarized request auth mode"
                       (summarize-http-request-auth-mode
                        post-authorization-header
                        post-cookie-header))))
         (derived-request-shape
           (list (cons "Detected Authorization scheme"
                       (or detected-scheme "-"))
                 (cons "AuthorizationMethod name"
                       (or authorization-method-name "-"))
                 (cons "Bootstrap request path"
                       (if (eq resolved-mode :basic)
                           (dmx-access-control-login-path)
                           "not used"))
                 (cons "Guarded request path"
                       (dmx-workspace-assign-object-path workspace-id topic-id))
                 (cons "Guarded request auth mode"
                       (summarize-http-request-auth-mode
                        post-authorization-header
                        post-cookie-header))
                 (cons "Expected cookie shape"
                       (summarize-http-cookie-shape post-cookie-header))))
         (session-transition
           (case resolved-mode
             (:basic
              (list (cons "Bootstrap request"
                          (format nil
                                  "POST ~A with Authorization: ~A"
                                  (dmx-access-control-login-path)
                                  derived-authorization-header))
                    (cons "Expected bootstrap outcome"
                          "204 No Content + Set-Cookie: JSESSIONID=...")
                    (cons "Session aftermath"
                          (format nil
                                  "JSESSIONID is captured ephemerally, then later guarded requests use Cookie: JSESSIONID=<session-id>; dmx_workspace_id=~D"
                                  workspace-id))
                    (cons "Bootstrap-capable"
                          "yes")))
             (otherwise
              (list (cons "Bootstrap request" "not used")
                    (cons "Expected bootstrap outcome"
                          "Direct-header mode stays on the original Authorization header unless the installation produces a session separately.")
                    (cons "Session aftermath"
                          "JSESSIONID is not treated as a primary input mode here.")
                    (cons "Bootstrap-capable"
                          "no")))))
         (mode-label (dmx-auth-mode-label resolved-mode)))
    (make-instance 'dmx-auth-path-example
                   :id (format nil "dmx-auth-path-example/~A"
                               (string-downcase (symbol-name resolved-mode)))
                   :title (format nil "DMX auth path example: ~A" mode-label)
                   :summary
                   (format nil
                           "Inspectable dmx-auth-path-example for ~A that shows raw input, normalized request shaping, DMX Credentials interpretation, AuthorizationMethod dependence, and the later request/cookie form without performing any live login."
                           mode-label)
                   :machine (make-dmx-auth-state-machine-definition)
                   :input raw-fields
                   :current-state "guarded-request-shaped"
                   :visited-states
                   (dmx-auth-path-example-visited-states
                    resolved-mode
                    :detected-scheme detected-scheme)
                   :transition-trace
                   (dmx-auth-path-example-transition-trace
                    (dmx-auth-path-example-visited-states
                     resolved-mode
                     :detected-scheme detected-scheme))
                   :evidence-trace
                   (dmx-auth-path-example-evidence-trace
                    resolved-mode
                    derived-authorization-header
                    derived-credentials
                    detected-scheme
                    session-transition
                    post-bootstrap-request-shape
                    :detected-authorization-method authorization-method-name)
                   :start-time 0
                   :end-time 5
                   :status (if (eq resolved-mode :token)
                               :installation-dependent
                               :prepared)
                   :failure-classification
                   (when (eq resolved-mode :token)
                     "AuthorizationMethod resolution is installation-dependent for bearer-token examples.")
                   :input-mode auth-mode
                   :raw-input raw-fields
                   :normalized-mode resolved-mode
                   :derived-request-shape derived-request-shape
                   :dmx-credentials-shape derived-credentials
                   :authorization-method-name authorization-method-name
                   :bootstrap-required-p (eq resolved-mode :basic)
                   :session-transition session-transition
                   :post-login-request-shape post-bootstrap-request-shape
                   :state-trace
                   (dmx-auth-path-example-state-trace resolved-mode)
                   :source-evidence
                   (dmx-auth-path-example-source-evidence resolved-mode)
                   :installation-dependencies
                   (dmx-auth-path-example-installation-dependencies
                    resolved-mode
                    :detected-scheme detected-scheme)
                   :notes
                   (dmx-auth-path-example-notes resolved-mode)
                   :detected-authorization-scheme detected-scheme
                   :derived-authorization-header derived-authorization-header
                   :bootstrap-request-shape bootstrap-request-shape
                   :expected-cookie-shape
                   (summarize-http-cookie-shape post-cookie-header)
                   :summarized-request-auth-mode
                   (summarize-http-request-auth-mode
                    post-authorization-header
                    post-cookie-header)
                   :workspace-id workspace-id
                   :topic-id topic-id)))

(defun make-dmx-auth-mode-example (&rest args &key &allow-other-keys)
  (apply #'make-dmx-auth-path-example args))

(defun dmx-auth-crosswalk-username-password-example ()
  (make-dmx-auth-path-example
   :auth-mode :basic
   :username *dmx-auth-crosswalk-default-username*
   :password *dmx-auth-crosswalk-default-password*))

(defun dmx-auth-crosswalk-authorization-header-example ()
  (make-dmx-auth-path-example
   :auth-mode :header
   :authorization-header *dmx-auth-crosswalk-default-basic-header*))

(defun dmx-auth-crosswalk-bearer-token-example ()
  (make-dmx-auth-path-example
   :auth-mode :token
   :auth-token *dmx-auth-crosswalk-default-bearer-token*))

(defun make-dmx-auth-crosswalk ()
  (make-instance 'dmx-auth-crosswalk
                 :examples
                 (list (dmx-auth-crosswalk-username-password-example)
                       (dmx-auth-crosswalk-authorization-header-example)
                       (dmx-auth-crosswalk-bearer-token-example))))

(defun import-fedwiki-site-to-dmx (&key
                                     domain
                                     (dry-run t)
                                     limit
                                     verbose
                                     wiki
                                     client
                                     topic-type-uri
                                     (stream *standard-output*)
                                     (page-json-loader #'fetch-fedwiki-import-page-json)
                                     (now (get-universal-time)))
  (unless domain
    (error 'fedwiki-dmx-import-error
           :message "A FedWiki domain is required"))
  (multiple-value-bind (resolved-wiki fallback-used)
      (resolve-fedwiki-import-wiki domain
                                   :wiki wiki
                                   :verbose verbose
                                   :stream stream)
    (let* ((all-pages (collect-local-fedwiki-pages resolved-wiki))
           (resolved-client (or client
                                (make-default-dmx-import-client :dry-run dry-run
                                                                :verbose verbose)))
           (candidates (enumerate-fedwiki-import-candidates resolved-wiki
                                                            :limit limit
                                                            :page-json-loader page-json-loader
                                                            :now now))
           (plan (plan-fedwiki-site-dmx-import candidates
                                               resolved-client
                                               :topic-type-uri topic-type-uri))
           (summary (summarize-dmx-import-plan plan))
           (lookup-enabled (lookup-enabled-for-dmx-import-client-p resolved-client))
           (resolved-protocol (hyperbook/fedwiki::protocol-of resolved-wiki))
           (available-count (length all-pages))
           (selected-count (length candidates))
           (skipped-count (- available-count selected-count)))
      (when (and (not dry-run)
                 (typep resolved-client 'null-dmx-import-client))
        (error 'dmx-import-config-error
               :message "Live DMX import requested without a configured HTTP client"
               :missing-keys '("HYPERDOC_DMX_IMPORT_BASE_URL")))
      (format stream "~&FEDWIKI_DMX_IMPORT domain=~A dry-run=~:[NIL~;T~] available=~D selected=~D skipped=~D limit=~A protocol=~A lookup=~:[NIL~;T~] http-fallback=~:[NIL~;T~]~%"
              domain
              dry-run
              available-count
              selected-count
              skipped-count
              (or limit "ALL")
              resolved-protocol
              lookup-enabled
              fallback-used)
      (when (and dry-run
                 (typep resolved-client 'null-dmx-import-client))
        (format stream "FEDWIKI_DMX_IMPORT note=no DMX base URL configured; dry-run assumes CREATE for unmatched external keys.~%"))
      (execute-dmx-import-plan plan
                               resolved-client
                               :dry-run dry-run
                               :stream stream
                               :verbose verbose)
      (format stream "~&FEDWIKI_DMX_IMPORT_SUMMARY candidates=~D creates=~D updates=~D duplicates=0 skipped=~D lookup=~:[NIL~;T~] protocol=~A http-fallback=~:[NIL~;T~]~%"
              (getf summary :entries)
              (getf summary :creates)
              (getf summary :updates)
              skipped-count
              lookup-enabled
              resolved-protocol
              fallback-used)
      (list :domain domain
            :dry-run dry-run
            :resolved-protocol resolved-protocol
            :http-fallback-used fallback-used
            :lookup-enabled lookup-enabled
            :available-candidates available-count
            :selected-candidates selected-count
            :skipped-candidates skipped-count
            :creates (getf summary :creates)
            :updates (getf summary :updates)
            :duplicates 0
            :plan plan))))
