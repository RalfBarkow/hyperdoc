;;;; Required DMX MCP runtime definitions, extracted from f512aa847eab05cc2bdf2e78ef0bd1b516a11926.
;;;; See docs/dmx-mcp-source-manifest.json and LICENSE.
(in-package :hyperdoc)

;; From hyperdoc/dmx-import.lisp, characters 271..329.
(defparameter *dmx-fedwiki-page-type-uri* "fedwiki.page")

;; From hyperdoc/dmx-import.lisp, characters 515..596.
(defparameter *dmx-topic-fetch-query-string* "children=true&assocChildren=true")

;; From hyperdoc/dmx-import.lisp, characters 596..698.
(defparameter *base64-alphabet*
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

;; From hyperdoc/dmx-import.lisp, characters 814..879.
(defparameter *http-dmx-import-evidence-body-prefix-limit* 2048)

;; From hyperdoc/dmx-import.lisp, characters 879..933.
(defparameter *http-dmx-import-debug-event-limit* 32)

;; From hyperdoc/dmx-import.lisp, characters 1248..1531.
;; The journal implementation file is loaded after several guarded write
;; helpers. Declare the dynamic boundary variables here so those helpers compile
;; cleanly while the later implementation remains the authority for defaults.
(defvar *workspace-journal-sink* :hyperdoc-local)

;; From hyperdoc/dmx-import.lisp, characters 1531..1581.
(defvar *allow-dmx-workspace-journal-writes* nil)

;; From hyperdoc/dmx-import.lisp, characters 1581..1841.
(define-condition fedwiki-dmx-import-error (error)
  ((message :reader fedwiki-dmx-import-message-of :initarg :message))
  (:report (lambda (condition stream)
             (format stream "~A"
                     (fedwiki-dmx-import-message-of condition)))))

;; From hyperdoc/dmx-import.lisp, characters 2179..2503.
(define-condition dmx-import-config-error (fedwiki-dmx-import-error)
  ((missing-keys :reader dmx-import-missing-keys-of :initarg :missing-keys))
  (:report (lambda (condition stream)
             (format stream "Missing DMX import configuration: ~{~A~^, ~}"
                     (dmx-import-missing-keys-of condition)))))

;; From hyperdoc/dmx-import.lisp, characters 2503..3123.
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

;; From hyperdoc/dmx-import.lisp, characters 3123..3648.
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

;; From hyperdoc/dmx-import.lisp, characters 3648..4909.
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

;; From hyperdoc/dmx-import.lisp, characters 5208..5244.
(defclass dmx-import-client () ())

;; From hyperdoc/dmx-import.lisp, characters 5244..5302.
(defclass null-dmx-import-client (dmx-import-client) ())

;; From hyperdoc/dmx-import.lisp, characters 5302..5893.
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

;; From hyperdoc/dmx-import.lisp, characters 5893..7244.
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

;; From hyperdoc/dmx-import.lisp, characters 7244..7311.
(defgeneric dmx-import-find-existing-topic (client external-key))

;; From hyperdoc/dmx-import.lisp, characters 7311..7364.
(defgeneric dmx-import-read-topic (client topic-id))

;; From hyperdoc/dmx-import.lisp, characters 7364..7423.
(defgeneric dmx-import-read-topicmap (client topicmap-id))

;; From hyperdoc/dmx-import.lisp, characters 7423..7486.
(defgeneric dmx-import-read-topic-workspace (client topic-id))

;; From hyperdoc/dmx-import.lisp, characters 7486..7540.
(defgeneric dmx-import-create-topic (client payload))

;; From hyperdoc/dmx-import.lisp, characters 7540..7609.
(defgeneric dmx-import-update-topic (client existing-topic payload))

;; From hyperdoc/dmx-import.lisp, characters 7609..7690.
(defgeneric dmx-import-assign-topic-to-workspace (client workspace-id topic-id))

;; From hyperdoc/dmx-import.lisp, characters 7690..7764.
(defgeneric dmx-import-topic-in-topicmap-p (client topicmap-id topic-id))

;; From hyperdoc/dmx-import.lisp, characters 7764..7851.
(defgeneric dmx-import-add-topic-to-topicmap (client topicmap-id topic-id view-props))

;; From hyperdoc/dmx-import.lisp, characters 7851..7937.
(defgeneric dmx-import-set-topic-view-props (client topicmap-id topic-id view-props))

;; From hyperdoc/dmx-import.lisp, characters 7937..8018.
(defgeneric dmx-import-remove-topic-from-topicmap (client topicmap-id topic-id))

;; From hyperdoc/dmx-import.lisp, characters 8018..8073.
(defgeneric dmx-import-delete-topic (client topic-id))

;; From hyperdoc/dmx-import.lisp, characters 8073..8547.
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

;; From hyperdoc/dmx-import.lisp, characters 8547..8722.
(defun dmx-topicmap-view-prop-spec-by-field (field)
  (find field
        *dmx-topicmap-view-prop-specs*
        :test #'eq
        :key (lambda (spec) (getf spec :field))))

;; From hyperdoc/dmx-import.lisp, characters 8722..9119.
(defun dmx-topicmap-view-prop-spec-by-key-name (key-name)
  (find key-name
        *dmx-topicmap-view-prop-specs*
        :test #'string=
        :key (lambda (spec)
               (or (and (string= key-name (getf spec :long-key))
                        (getf spec :long-key))
                   (and (string= key-name (getf spec :short-key))
                        (getf spec :short-key))))))

;; From hyperdoc/dmx-import.lisp, characters 9119..9300.
(defun dmx-topicmap-view-prop-key-name (key)
  (cond
    ((stringp key)
     (string-downcase key))
    ((symbolp key)
     (string-downcase (symbol-name key)))
    (t
     nil)))

;; From hyperdoc/dmx-import.lisp, characters 9300..10340.
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

;; From hyperdoc/dmx-import.lisp, characters 10340..10429.
(defun dmx-topicmap-view-prop-boolean-p (value)
  (or (eq value t)
      (null value)))

;; From hyperdoc/dmx-import.lisp, characters 10429..10670.
(defun dmx-topicmap-view-prop-valid-type-p (field value)
  (ecase field
    (:x (integerp value))
    (:y (integerp value))
    (:visibility (dmx-topicmap-view-prop-boolean-p value))
    (:pinned (dmx-topicmap-view-prop-boolean-p value))))

;; From hyperdoc/dmx-import.lisp, characters 10670..11016.
(defun make-dmx-topicmap-view-props-json-object (&key x y visibility pinned)
  (let ((json (make-hash-table :test #'equal)))
    (setf (gethash "dmx.topicmaps.x" json) x
          (gethash "dmx.topicmaps.y" json) y
          (gethash "dmx.topicmaps.visibility" json) visibility
          (gethash "dmx.topicmaps.pinned" json) pinned)
    json))

;; From hyperdoc/dmx-import.lisp, characters 11016..11170.
(defun dmx-topicmap-view-props-value (view-props field)
  (gethash (getf (dmx-topicmap-view-prop-spec-by-field field) :long-key)
           view-props))

;; From hyperdoc/dmx-import.lisp, characters 11170..11629.
(defun dmx-topicmap-view-props-json-string (view-props)
  (format nil
          "{\"dmx.topicmaps.x\":~D,\"dmx.topicmaps.y\":~D,\"dmx.topicmaps.visibility\":~:[false~;true~],\"dmx.topicmaps.pinned\":~:[false~;true~]}"
          (dmx-topicmap-view-props-value view-props :x)
          (dmx-topicmap-view-props-value view-props :y)
          (dmx-topicmap-view-props-value view-props :visibility)
          (dmx-topicmap-view-props-value view-props :pinned)))

;; From hyperdoc/dmx-import.lisp, characters 11629..12580.
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

;; From hyperdoc/dmx-import.lisp, characters 12580..15965.
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

;; From hyperdoc/dmx-import.lisp, characters 15965..16379.
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

;; From hyperdoc/dmx-import.lisp, characters 16379..16472.
(defun memory-topicmap-membership-key (topicmap-id topic-id)
  (list topicmap-id topic-id))

;; From hyperdoc/dmx-import.lisp, characters 16472..16603.
(defmethod dmx-import-find-existing-topic ((client null-dmx-import-client) external-key)
  (declare (ignore external-key))
  nil)

;; From hyperdoc/dmx-import.lisp, characters 16603..16717.
(defmethod dmx-import-read-topic ((client null-dmx-import-client) topic-id)
  (declare (ignore topic-id))
  nil)

;; From hyperdoc/dmx-import.lisp, characters 16717..16840.
(defmethod dmx-import-read-topicmap ((client null-dmx-import-client) topicmap-id)
  (declare (ignore topicmap-id))
  nil)

;; From hyperdoc/dmx-import.lisp, characters 16840..16964.
(defmethod dmx-import-read-topic-workspace ((client null-dmx-import-client) topic-id)
  (declare (ignore topic-id))
  nil)

;; From hyperdoc/dmx-import.lisp, characters 16964..17179.
(defmethod dmx-import-create-topic ((client null-dmx-import-client) payload)
  (declare (ignore payload))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live writes"))

;; From hyperdoc/dmx-import.lisp, characters 17179..17424.
(defmethod dmx-import-update-topic ((client null-dmx-import-client) existing-topic payload)
  (declare (ignore existing-topic payload))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live writes"))

;; From hyperdoc/dmx-import.lisp, characters 17424..17750.
(defmethod dmx-import-assign-topic-to-workspace ((client null-dmx-import-client)
                                                 workspace-id topic-id)
  (declare (ignore workspace-id topic-id))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live workspace assignment writes"))

;; From hyperdoc/dmx-import.lisp, characters 17750..17897.
(defmethod dmx-import-topic-in-topicmap-p ((client null-dmx-import-client) topicmap-id topic-id)
  (declare (ignore topicmap-id topic-id))
  nil)

;; From hyperdoc/dmx-import.lisp, characters 17897..18178.
(defmethod dmx-import-add-topic-to-topicmap ((client null-dmx-import-client) topicmap-id topic-id view-props)
  (declare (ignore topicmap-id topic-id view-props))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live topicmap writes"))

;; From hyperdoc/dmx-import.lisp, characters 18178..18458.
(defmethod dmx-import-set-topic-view-props ((client null-dmx-import-client) topicmap-id topic-id view-props)
  (declare (ignore topicmap-id topic-id view-props))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live topicmap writes"))

;; From hyperdoc/dmx-import.lisp, characters 18458..18729.
(defmethod dmx-import-remove-topic-from-topicmap ((client null-dmx-import-client) topicmap-id topic-id)
  (declare (ignore topicmap-id topic-id))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live topicmap unlink writes"))

;; From hyperdoc/dmx-import.lisp, characters 18729..18947.
(defmethod dmx-import-delete-topic ((client null-dmx-import-client) topic-id)
  (declare (ignore topic-id))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live deletes"))

;; From hyperdoc/dmx-import.lisp, characters 18947..19100.
(defmethod dmx-import-find-existing-topic ((client memory-dmx-import-client) external-key)
  (gethash external-key (topics-by-external-key-of client)))

;; From hyperdoc/dmx-import.lisp, characters 19100..20481.
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

;; From hyperdoc/dmx-import.lisp, characters 20481..20755.
(defmethod dmx-import-read-topic ((client memory-dmx-import-client) topic-id)
  (memory-dmx-import-topic-payload->json
   (find topic-id
         (alexandria:hash-table-values (topics-by-external-key-of client))
         :key #'dmx-import-object-id
         :test #'eql)))

;; From hyperdoc/dmx-import.lisp, characters 20755..21976.
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

;; From hyperdoc/dmx-import.lisp, characters 21976..22408.
(defun memory-dmx-import-workspace-json (workspace-id)
  (let ((json (make-hash-table :test #'equal))
        (children (make-hash-table :test #'equal)))
    (setf (gethash "id" json) workspace-id
          (gethash "uri" json) ""
          (gethash "typeUri" json) "dmx.workspaces.workspace"
          (gethash "value" json) (format nil "Memory workspace ~D" workspace-id)
          (gethash "children" json) children)
    json))

;; From hyperdoc/dmx-import.lisp, characters 22408..22631.
(defmethod dmx-import-read-topic-workspace ((client memory-dmx-import-client) topic-id)
  (when-let (workspace-id (gethash topic-id (workspace-assignments-of client)))
    (memory-dmx-import-workspace-json workspace-id)))

;; From hyperdoc/dmx-import.lisp, characters 22631..23009.
(defmethod dmx-import-create-topic ((client memory-dmx-import-client) payload)
  (let* ((id (or (getf payload :id)
                 (prog1 (next-topic-id-of client)
                   (incf (next-topic-id-of client)))))
         (stored (list* :id id payload)))
    (setf (gethash (getf payload :external-key) (topics-by-external-key-of client))
          stored)
    stored))

;; From hyperdoc/dmx-import.lisp, characters 23009..23457.
(defmethod dmx-import-update-topic ((client memory-dmx-import-client) existing-topic payload)
  (let* ((id (or (dmx-import-object-id existing-topic)
                 (getf payload :id)
                 (prog1 (next-topic-id-of client)
                   (incf (next-topic-id-of client)))))
         (stored (list* :id id payload)))
    (setf (gethash (getf payload :external-key) (topics-by-external-key-of client))
          stored)
    stored))

;; From hyperdoc/dmx-import.lisp, characters 23457..24878.
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

;; From hyperdoc/dmx-import.lisp, characters 24878..25113.
(defmethod dmx-import-topic-in-topicmap-p ((client memory-dmx-import-client) topicmap-id topic-id)
  (not (null (gethash (memory-topicmap-membership-key topicmap-id topic-id)
                      (topicmap-memberships-of client)))))

;; From hyperdoc/dmx-import.lisp, characters 25113..25616.
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

;; From hyperdoc/dmx-import.lisp, characters 25616..26116.
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

;; From hyperdoc/dmx-import.lisp, characters 26116..26390.
(defmethod dmx-import-remove-topic-from-topicmap ((client memory-dmx-import-client)
                                                  topicmap-id topic-id)
  (remhash (memory-topicmap-membership-key topicmap-id topic-id)
           (topicmap-memberships-of client))
  nil)

;; From hyperdoc/dmx-import.lisp, characters 26390..27328.
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

;; From hyperdoc/dmx-import.lisp, characters 38770..39876.
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

;; From hyperdoc/dmx-import.lisp, characters 39876..40565.
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

;; From hyperdoc/dmx-import.lisp, characters 53117..53339.
(defun unreserved-url-char-p (char)
  (or (and (char>= char #\a) (char<= char #\z))
      (and (char>= char #\A) (char<= char #\Z))
      (and (char>= char #\0) (char<= char #\9))
      (find char "-._~" :test #'char=)))

;; From hyperdoc/dmx-import.lisp, characters 53339..53600.
(defun url-encode-component (text)
  (with-output-to-string (stream)
    (loop for char across (or text "")
          do (if (unreserved-url-char-p char)
                 (write-char char stream)
                 (format stream "%~2,'0X" (char-code char))))))

;; From hyperdoc/dmx-import.lisp, characters 53600..53817.
(defun absolute-http-url-p (url)
  (or (and url
           (<= 7 (length url))
           (string= "http://" url :end2 7))
      (and url
           (<= 8 (length url))
           (string= "https://" url :end2 8))))

;; From hyperdoc/dmx-import.lisp, characters 53817..53892.
(defun http-success-status-p (status)
  (and status (<= 200 status 299)))

;; From hyperdoc/dmx-import.lisp, characters 53892..54393.
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

;; From hyperdoc/dmx-import.lisp, characters 54393..54680.
(defun encode-json-string (object)
  (let ((encoder (json-encoder-function)))
    (unless encoder
      (error 'fedwiki-dmx-import-error
             :message "No JSON encoder available for live DMX writes"))
    (with-output-to-string (stream)
      (funcall encoder object stream))))

;; From hyperdoc/dmx-import.lisp, characters 54680..54826.
(defun encode-http-json-request-body (object)
  (babel:string-to-octets (encode-json-string object)
                          :encoding :utf-8))

;; From hyperdoc/dmx-import.lisp, characters 54826..55125.
(defun dmx-import-children-json-object (children)
  (when children
    (let ((json (make-hash-table :test #'equal)))
      (maphash (lambda (child-type-uri child-value)
                 (setf (gethash child-type-uri json)
                       child-value))
               children)
      json)))

;; From hyperdoc/dmx-import.lisp, characters 55125..55603.
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

;; From hyperdoc/dmx-import.lisp, characters 55603..56026.
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

;; From hyperdoc/dmx-import.lisp, characters 56026..56196.
(defun dmx-topic-uri-lookup-path (topic-uri)
  (format nil "/core/topic/uri/~A?~A"
          (url-encode-component topic-uri)
          *dmx-topic-fetch-query-string*))

;; From hyperdoc/dmx-import.lisp, characters 56196..56246.
(defun dmx-topic-create-path ()
  "/core/topic")

;; From hyperdoc/dmx-import.lisp, characters 56246..56329.
(defun dmx-topic-update-path (topic-id)
  (format nil "/core/topic/~A" topic-id))

;; From hyperdoc/dmx-import.lisp, characters 56416..56515.
(defun dmx-topicmap-memberships-path (object-id)
  (format nil "/topicmaps/object/~D" object-id))

;; From hyperdoc/dmx-import.lisp, characters 56515..56611.
(defun dmx-workspace-object-path (object-id)
  (format nil "/workspaces/object/~D" object-id))

;; From hyperdoc/dmx-import.lisp, characters 56611..56743.
(defun dmx-workspace-assign-object-path (workspace-id object-id)
  (format nil "/workspaces/~D/object/~D" workspace-id object-id))

;; From hyperdoc/dmx-import.lisp, characters 56743..56811.
(defun dmx-access-control-login-path ()
  "/access-control/login")

;; From hyperdoc/dmx-import.lisp, characters 56811..56932.
(defun dmx-topicmap-add-topic-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

;; From hyperdoc/dmx-import.lisp, characters 56932..57064.
(defun dmx-topicmap-set-topic-view-props-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

;; From hyperdoc/dmx-import.lisp, characters 57064..57184.
(defun http-response-body-string (stream)
  (when stream
    (ignore-errors
      (uiop:slurp-stream-string stream))))

;; From hyperdoc/dmx-import.lisp, characters 57184..57535.
(defun http-response-header-value (headers header-name)
  (cdr (find header-name
             headers
             :test #'string-equal
             :key (lambda (entry)
                    (let ((name (car entry)))
                      (etypecase name
                        (string name)
                        (symbol (symbol-name name))))))))

;; From hyperdoc/dmx-import.lisp, characters 57535..57746.
(defun octet-vector-p (value)
  (and (vectorp value)
       (not (stringp value))
       (every (lambda (item)
                (and (integerp item)
                     (<= 0 item 255)))
              value)))

;; From hyperdoc/dmx-import.lisp, characters 57746..58080.
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

;; From hyperdoc/dmx-import.lisp, characters 58080..58288.
(defun bounded-http-evidence-string (string)
  (let ((value (or string "")))
    (subseq value
            0
            (min (length value)
                 *http-dmx-import-evidence-body-prefix-limit*))))

;; From hyperdoc/dmx-import.lisp, characters 58288..58860.
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

;; From hyperdoc/dmx-import.lisp, characters 58860..59055.
(defun plist-without-http-body-fields (plist)
  (loop for (key value) on plist by #'cddr
        unless (member key '(:request-body :response-body) :test #'eq)
        append (list key value)))

;; From hyperdoc/dmx-import.lisp, characters 59055..59410.
(defun sanitize-dmx-import-http-evidence (evidence)
  (when evidence
    (append
     (plist-without-http-body-fields evidence)
     (when (getf evidence :request-body)
       (http-body-evidence "REQUEST" (getf evidence :request-body)))
     (when (getf evidence :response-body)
       (http-body-evidence "RESPONSE" (getf evidence :response-body))))))

;; From hyperdoc/dmx-import.lisp, characters 59410..59851.
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

;; From hyperdoc/dmx-import.lisp, characters 59851..60045.
(defun sanitize-http-dmx-import-debug-event (event)
  (loop for (key value) on event by #'cddr
        append (list key
                     (sanitize-http-dmx-import-debug-value key value))))

;; From hyperdoc/dmx-import.lisp, characters 60045..60264.
(defun bounded-http-dmx-import-debug-events (events)
  (let ((length (length events)))
    (if (> length *http-dmx-import-debug-event-limit*)
        (last events *http-dmx-import-debug-event-limit*)
        events)))

;; From hyperdoc/dmx-import.lisp, characters 60264..60664.
(defun http-request-relative-path (client normalized-url)
  (let ((base-url (dmx-import-base-url-of client)))
    (if (and base-url
             (<= (length base-url) (length normalized-url))
             (string-equal base-url
                           normalized-url
                           :end2 (length base-url)))
        (subseq normalized-url (length base-url))
        normalized-url)))

;; From hyperdoc/dmx-import.lisp, characters 60664..60957.
(defun summarize-http-authorization-scheme (authorization-header)
  (cond
    ((null authorization-header) nil)
    ((search "Basic " authorization-header :test #'char-equal)
     "Basic")
    ((search "Bearer " authorization-header :test #'char-equal)
     "Bearer")
    (t
     "Custom")))

;; From hyperdoc/dmx-import.lisp, characters 60957..61181.
(defun http-dmx-import-session-bootstrap-required-p (client)
  (and (typep client 'http-dmx-import-client)
       (or (dmx-import-session-login-required-p-of client)
           (dmx-import-bootstrap-session-p-of client))))

;; From hyperdoc/dmx-import.lisp, characters 61181..61615.
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

;; From hyperdoc/dmx-import.lisp, characters 61615..61747.
(defun cookie-contains-token-p (cookie-header token)
  (and cookie-header
       (search token cookie-header :test #'char-equal)))

;; From hyperdoc/dmx-import.lisp, characters 61747..62220.
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

;; From hyperdoc/dmx-import.lisp, characters 62220..62273.
(defvar *http-dmx-import-request-workspace-id* nil)

;; From hyperdoc/dmx-import.lisp, characters 62273..62433.
(defmacro with-http-dmx-import-request-workspace-id ((workspace-id) &body body)
  `(let ((*http-dmx-import-request-workspace-id* ,workspace-id))
     ,@body))

;; From hyperdoc/dmx-import.lisp, characters 62433..63219.
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

;; From hyperdoc/dmx-import.lisp, characters 63219..63667.
(defun http-dmx-import-request-cookie-values (client &key workspace-id)
  (append (when (dmx-import-session-cookie-of client)
            (list (dmx-import-session-cookie-of client)))
          (when-let (resolved-workspace-id
                     (effective-http-dmx-import-workspace-id
                      client
                      :workspace-id workspace-id))
            (list (format nil "dmx_workspace_id=~D" resolved-workspace-id)))))

;; From hyperdoc/dmx-import.lisp, characters 63667..64090.
(defun append-http-dmx-import-debug-event (client state &rest fields)
  (when (typep client 'http-dmx-import-client)
    (setf (dmx-import-debug-events-of client)
          (bounded-http-dmx-import-debug-events
           (append (dmx-import-debug-events-of client)
                   (list
                    (sanitize-http-dmx-import-debug-event
                     (append (list :state state) fields)))))))
  client)

;; From hyperdoc/dmx-import.lisp, characters 64492..64750.
(defun http-dmx-import-debug-event (client state)
  (when (typep client 'http-dmx-import-client)
    (find state
          (dmx-import-debug-events-of client)
          :from-end t
          :test #'eq
          :key (lambda (event) (getf event :state)))))

;; From hyperdoc/dmx-import.lisp, characters 64750..65626.
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

;; From hyperdoc/dmx-import.lisp, characters 65626..66388.
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

;; From hyperdoc/dmx-import.lisp, characters 66388..67569.
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

;; From hyperdoc/dmx-import.lisp, characters 67569..69646.
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

;; From hyperdoc/dmx-import.lisp, characters 69646..70176.
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

;; From hyperdoc/dmx-import.lisp, characters 70176..70751.
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

;; From hyperdoc/dmx-import.lisp, characters 70751..75266.
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

;; From hyperdoc/dmx-import.lisp, characters 75266..75406.
(defun blank-http-response-body-p (body)
  (or (null body)
      (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return) body)))))

;; From hyperdoc/dmx-import.lisp, characters 75406..75592.
(defun parse-http-response-body-json (body)
  (if (blank-http-response-body-p body)
      nil
      (handler-case
          (shasht:read-json body)
        (error ()
          body))))

;; From hyperdoc/dmx-import.lisp, characters 75592..82130.
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

;; From hyperdoc/dmx-import.lisp, characters 82130..82516.
(defun validate-http-dmx-import-client (client &key live?)
  (let ((missing '()))
    (unless (dmx-import-base-url-of client)
      (push "HYPERDOC_DMX_IMPORT_BASE_URL" missing))
    (when (and live? missing)
      (error 'dmx-import-config-error
             :message "Incomplete live DMX import configuration"
             :missing-keys (nreverse missing)))
    (nreverse missing)))

;; From hyperdoc/dmx-import.lisp, characters 82516..83639.
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

;; From hyperdoc/dmx-import.lisp, characters 83639..83981.
(defun ensure-http-dmx-import-session-cookie-for-protected-mutation
    (client operation)
  (when (and (typep client 'http-dmx-import-client)
             (http-dmx-import-session-bootstrap-required-p client)
             (null (dmx-import-session-cookie-of client)))
    (ensure-http-dmx-import-authenticated-operation client operation)))

;; From hyperdoc/dmx-import.lisp, characters 83981..84309.
(defmethod dmx-import-read-topic ((client http-dmx-import-client) topic-id)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (format nil "/core/topic/~D?~A"
                             topic-id
                             *dmx-topic-fetch-query-string*)))

;; From hyperdoc/dmx-import.lisp, characters 84309..84638.
(defmethod dmx-import-read-topicmap ((client http-dmx-import-client) topicmap-id)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (format nil "/topicmaps/~D?children=true" topicmap-id)
                     :extra-headers '(("Accept" . "application/json"))))

;; From hyperdoc/dmx-import.lisp, characters 84638..84882.
(defmethod dmx-import-read-topic-workspace ((client http-dmx-import-client) topic-id)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (dmx-workspace-object-path topic-id)))

;; From hyperdoc/dmx-import.lisp, characters 84882..85168.
(defmethod dmx-import-find-existing-topic ((client http-dmx-import-client) external-key)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (dmx-topic-uri-lookup-path external-key)
                     :allow-404? t))

;; From hyperdoc/dmx-import.lisp, characters 85168..85530.
(defmethod dmx-import-create-topic ((client http-dmx-import-client) payload)
  (validate-http-dmx-import-client client :live? t)
  (ensure-http-dmx-import-session-cookie-for-protected-mutation
   client
   :create-topic)
  (http-request-json client
                     :post
                     (dmx-topic-create-path)
                     :payload payload))

;; From hyperdoc/dmx-import.lisp, characters 85530..86246.
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

;; From hyperdoc/dmx-import.lisp, characters 86246..88134.
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

;; From hyperdoc/dmx-import.lisp, characters 88134..88502.
(defun http-topic-present-in-topicmap-p (client topicmap-id topic-id)
  (let ((topicmaps (http-request-json client
                                      :get
                                      (dmx-topicmap-memberships-path topic-id))))
    (find topicmap-id
          (dmx-runtime-array-elements topicmaps)
          :key #'dmx-import-object-id
          :test #'eql)))

;; From hyperdoc/dmx-import.lisp, characters 88502..88731.
(defmethod dmx-import-topic-in-topicmap-p ((client http-dmx-import-client) topicmap-id topic-id)
  (validate-http-dmx-import-client client)
  (and topic-id
       (http-topic-present-in-topicmap-p client topicmap-id topic-id)))

;; From hyperdoc/dmx-import.lisp, characters 88731..89392.
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

;; From hyperdoc/dmx-import.lisp, characters 89392..90059.
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

;; From hyperdoc/dmx-import.lisp, characters 90059..90974.
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

;; From hyperdoc/dmx-import.lisp, characters 90974..91371.
(defmethod dmx-import-delete-topic ((client http-dmx-import-client) topic-id)
  (validate-http-dmx-import-client client :live? t)
  ;; DELETE on /core/topic/<id> is part of the currently proven DMX HTTP
  ;; contract: OPTIONS on the live route advertises DELETE for topic resources.
  (http-request-json client
                     :delete
                     (dmx-topic-update-path topic-id)))

;; From hyperdoc/dmx-import.lisp, characters 91371..91502.
(defun getenv-non-empty (name)
  (let ((value (uiop:getenv name)))
    (and value
         (> (length value) 0)
         value)))

;; From hyperdoc/dmx-import.lisp, characters 91502..91726.
(defun dmx-import-env-true-p (name)
  (let ((value (getenv-non-empty name)))
    (and value
         (member (string-downcase value)
                 '("1" "true" "yes" "on")
                 :test #'string=)
         t)))

;; From hyperdoc/dmx-import.lisp, characters 114162..114808.
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

;; From hyperdoc/dmx-import.lisp, characters 114808..115708.
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

;; From hyperdoc/dmx-import.lisp, characters 115708..116703.
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

;; From hyperdoc/dmx-import.lisp, characters 116703..117298.
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

;; From hyperdoc/dmx-import.lisp, characters 117298..121050.
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

;; From hyperdoc/dmx-import.lisp, characters 121050..123620.
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

;; From hyperdoc/dmx-import.lisp, characters 123620..123942.
(defun make-default-dmx-import-client (&key dry-run verbose)
  (declare (ignore dry-run))
  (let ((client (make-http-dmx-import-client-from-environment :verbose verbose)))
    (cond
      ((and client
            (dmx-import-base-url-of client))
       client)
      (t
       (make-instance 'null-dmx-import-client)))))
