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
   (response-body :reader dmx-import-http-response-body-of :initarg :response-body))
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
(defgeneric dmx-import-create-topic (client payload))
(defgeneric dmx-import-update-topic (client existing-topic payload))
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

(defmethod dmx-import-create-topic ((client null-dmx-import-client) payload)
  (declare (ignore payload))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live writes"))

(defmethod dmx-import-update-topic ((client null-dmx-import-client) existing-topic payload)
  (declare (ignore existing-topic payload))
  (error 'fedwiki-dmx-import-error
         :message "Dry-run/null DMX client cannot perform live writes"))

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
    nil))

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

(defun dmx-topicmap-add-topic-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

(defun dmx-topicmap-set-topic-view-props-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

(defun http-response-body-string (stream)
  (when stream
    (ignore-errors
      (uiop:slurp-stream-string stream))))

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

(defun http-request-json (client method url &key payload body-object allow-404? extra-headers)
  (let* ((normalized-url (normalize-http-client-url client url))
         (headers (append (when (dmx-import-authorization-header-of client)
                            (list (cons "Authorization"
                                        (dmx-import-authorization-header-of client))))
                          (when (dmx-import-workspace-id-of client)
                            (list (cons "Cookie"
                                        (format nil "dmx_workspace_id=~D"
                                                (dmx-import-workspace-id-of client)))))
                          extra-headers))
         (request-args (append (list normalized-url
                                     :method method
                                     :want-stream t
                                     :additional-headers headers)
                               (when (or payload body-object)
                                 (list :content (encode-json-string
                                                 (or body-object
                                                     (dmx-import-json-object payload)))
                                       :content-type "application/json")))))
    (multiple-value-bind (stream status-code response-headers response-uri must-close reason-phrase)
        (apply #'drakma:http-request request-args)
      (declare (ignore response-headers response-uri must-close))
      (unwind-protect
           (let ((body (http-response-body-string stream)))
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
                       :response-body body))))
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

(defmethod dmx-import-find-existing-topic ((client http-dmx-import-client) external-key)
  (validate-http-dmx-import-client client)
  (http-request-json client
                     :get
                     (dmx-topic-uri-lookup-path external-key)
                     :allow-404? t))

(defmethod dmx-import-create-topic ((client http-dmx-import-client) payload)
  (validate-http-dmx-import-client client :live? t)
  (http-request-json client
                     :post
                     (dmx-topic-create-path)
                     :payload payload))

(defmethod dmx-import-update-topic ((client http-dmx-import-client) existing-topic payload)
  (validate-http-dmx-import-client client :live? t)
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
         (auth-header
           (or (getenv-non-empty "HYPERDOC_DMX_IMPORT_AUTH_HEADER")
               (let ((username (getenv-non-empty "HYPERDOC_DMX_IMPORT_USERNAME"))
                     (password (getenv-non-empty "HYPERDOC_DMX_IMPORT_PASSWORD")))
                 (when (and username password)
                   (basic-authorization-header username password)))))
         (legacy-auth-token
           (getenv-non-empty "HYPERDOC_DMX_IMPORT_AUTH_TOKEN")))
    (when (or base-url topic-type-uri auth-header legacy-auth-token)
      (make-instance 'http-dmx-import-client
                     :base-url base-url
                     :authorization-header (or auth-header
                                               (and legacy-auth-token
                                                    (format nil "Bearer ~A"
                                                            legacy-auth-token)))
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
