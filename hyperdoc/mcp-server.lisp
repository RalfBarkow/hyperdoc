;;;; Streamable HTTP MCP server for the DMX context-window workspace
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defparameter *dmx-mcp-protocol-version* "2025-03-26")
(defparameter *dmx-mcp-server-name* "hyperdoc-dmx-mcp")
(defparameter *dmx-mcp-server-version* "0.1.0")
(defparameter *dmx-mcp-default-port* 8787)
(defparameter *dmx-mcp-default-bind-address* "127.0.0.1")
(defparameter *dmx-mcp-default-workspace-topicmap-id* 919822)
(defparameter *dmx-mcp-default-topic-id* 907120)
(defvar *dmx-mcp-server* nil)
(defvar *dmx-mcp-acceptor* nil)
(defvar *dmx-mcp-random-state* (make-random-state t))

(defstruct dmx-mcp-server
  read-client
  write-client
  workspace-topicmap-id
  known-topic-ids
  bearer-token
  allowed-origins
  live-writes-enabled-p
  sessions
  log-stream)

(defun getenv-truthy-p (name &optional (default nil))
  (let ((value (uiop:getenv name)))
    (cond
      ((null value) default)
      ((member (string-downcase value)
               '("1" "true" "yes" "on")
               :test #'string=)
       t)
      (t nil))))

(defun split-comma-separated-env (name)
  (let ((value (uiop:getenv name)))
    (when (dmx-non-empty-string-p value)
      (loop for start = 0 then (1+ comma)
            for comma = (position #\, value :start start)
            for piece = (string-trim '(#\Space #\Tab #\Newline #\Return)
                                     (subseq value
                                             start
                                             (or comma (length value))))
            when (plusp (length piece))
              collect piece
            while comma))))

(defun make-default-dmx-mcp-server ()
  (let* ((client (make-http-dmx-import-client-from-environment :verbose nil))
         (allowed-origins (split-comma-separated-env "HYPERDOC_MCP_ALLOWED_ORIGINS"))
         (live-writes-enabled-p (getenv-truthy-p "HYPERDOC_MCP_ENABLE_LIVE_WRITES" nil)))
    (make-dmx-mcp-server
     :read-client (or client
                      (make-instance 'null-dmx-import-client))
     :write-client (or client
                       (make-instance 'null-dmx-import-client))
     :workspace-topicmap-id
     (or (parse-positive-integer (uiop:getenv "HYPERDOC_MCP_WORKSPACE_TOPICMAP_ID"))
         *dmx-mcp-default-workspace-topicmap-id*)
     :known-topic-ids (list *dmx-mcp-default-topic-id*)
     :bearer-token (uiop:getenv "HYPERDOC_MCP_BEARER_TOKEN")
     :allowed-origins allowed-origins
     :live-writes-enabled-p live-writes-enabled-p
     :sessions (make-hash-table :test #'equal)
     :log-stream *error-output*)))

(defun dmx-mcp-log (server format-string &rest args)
  (when-let (stream (and server (dmx-mcp-server-log-stream server)))
    (apply #'format stream
           (concatenate 'string "~&[dmx-mcp] " format-string "~%")
           args)
    (finish-output stream)))

(defun dmx-mcp-json-object (&rest key-values)
  (let ((json (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (setf (gethash key json) value))
    json))

(defun dmx-mcp-json-array (&rest items)
  (coerce items 'vector))

(defun dmx-mcp-text-content (text)
  (dmx-mcp-json-object
   "type" "text"
   "text" text))

(defun dmx-mcp-plist-p (value)
  (and (listp value)
       (evenp (length value))
       (loop for (key value*) on value by #'cddr
             always (and (keywordp key)
                         (or value* t)))))

(defun dmx-mcp-normalize-json-value (value)
  (cond
    ((hash-table-p value)
     (let ((json (make-hash-table :test #'equal)))
       (maphash (lambda (key nested-value)
                  (setf (gethash (princ-to-string key) json)
                        (dmx-mcp-normalize-json-value nested-value)))
                value)
       json))
    ((dmx-mcp-plist-p value)
     (let ((json (make-hash-table :test #'equal)))
       (loop for (key nested-value) on value by #'cddr
             do (setf (gethash (string-downcase (symbol-name key)) json)
                      (dmx-mcp-normalize-json-value nested-value)))
       json))
    ((and (listp value)
          (not (null value)))
     (coerce (mapcar #'dmx-mcp-normalize-json-value value) 'vector))
    ((keywordp value)
     (string-downcase (symbol-name value)))
    (t
     value)))

(defun dmx-mcp-content-from-object (object)
  (dmx-mcp-json-array
   (dmx-mcp-text-content
    (encode-json-string (dmx-mcp-normalize-json-value object)))))

(defun dmx-mcp-topic-resource-uri (topic-id)
  (format nil "dmx://topic/~D" topic-id))

(defun dmx-mcp-topicmap-resource-uri (topicmap-id)
  (format nil "dmx://topicmap/~D" topicmap-id))

(defun dmx-mcp-workspace-resource-uri ()
  "dmx://workspace/context-window")

(defun dmx-mcp-json-response (body &key (status 200) session-id)
  (setf (hunchentoot:return-code*) status
        (hunchentoot:content-type*) "application/json; charset=utf-8"
        (hunchentoot:header-out "MCP-Protocol-Version") *dmx-mcp-protocol-version*)
  (when session-id
    (setf (hunchentoot:header-out "Mcp-Session-Id") session-id))
  (encode-json-string body))

(defun dmx-mcp-empty-response (&key (status 202) session-id)
  (setf (hunchentoot:return-code*) status
        (hunchentoot:content-type*) "application/json; charset=utf-8"
        (hunchentoot:header-out "MCP-Protocol-Version") *dmx-mcp-protocol-version*)
  (when session-id
    (setf (hunchentoot:header-out "Mcp-Session-Id") session-id))
  "")

(defun dmx-mcp-json-rpc-success (id result &key session-id)
  (dmx-mcp-json-response
   (dmx-mcp-json-object
    "jsonrpc" "2.0"
    "id" id
    "result" result)
   :session-id session-id))

(defun dmx-mcp-json-rpc-error (id code message &key data (status 200) session-id)
  (let ((error-object (dmx-mcp-json-object
                       "code" code
                       "message" message)))
    (when data
      (setf (gethash "data" error-object) data))
    (dmx-mcp-json-response
     (dmx-mcp-json-object
      "jsonrpc" "2.0"
      "id" id
      "error" error-object)
     :status status
     :session-id session-id)))

(defun dmx-mcp-session-id ()
  (format nil "mcp-~8,'0X~8,'0X"
          (random #xffffffff *dmx-mcp-random-state*)
          (random #xffffffff *dmx-mcp-random-state*)))

(defun dmx-mcp-server-require-auth (server)
  (let ((expected-token (and server (dmx-mcp-server-bearer-token server))))
    (when (dmx-non-empty-string-p expected-token)
      (let ((auth (or (hunchentoot:header-in* "authorization")
                      "")))
        (unless (string= auth (format nil "Bearer ~A" expected-token))
          (setf (hunchentoot:return-code*) 401
                (hunchentoot:content-type*) "application/json; charset=utf-8")
          (return-from dmx-mcp-server-require-auth
            (encode-json-string
             (dmx-mcp-json-object
              "error" "unauthorized"
              "message" "Missing or invalid bearer token")))))))
  nil)

(defun dmx-mcp-server-origin-allowed-p (server)
  (let ((allowed-origins (and server (dmx-mcp-server-allowed-origins server)))
        (origin (hunchentoot:header-in* "origin")))
    (or (null origin)
        (null allowed-origins)
        (member origin allowed-origins :test #'string=))))

(defun dmx-mcp-server-require-origin (server)
  (unless (dmx-mcp-server-origin-allowed-p server)
    (setf (hunchentoot:return-code*) 403
          (hunchentoot:content-type*) "application/json; charset=utf-8")
    (return-from dmx-mcp-server-require-origin
      (encode-json-string
       (dmx-mcp-json-object
        "error" "forbidden_origin"
        "message" "Origin is not allowed for this MCP server"))))
  nil)

(defun dmx-mcp-request-json ()
  (let ((body (hunchentoot:raw-post-data :force-text t)))
    (unless (dmx-non-empty-string-p body)
      (error 'fedwiki-dmx-import-error
             :message "MCP POST request body was empty"))
    (shasht:read-json body)))

(defun dmx-mcp-request-id (request)
  (and (hash-table-p request)
       (gethash "id" request)))

(defun dmx-mcp-request-method-name (request)
  (and (hash-table-p request)
       (gethash "method" request)))

(defun dmx-mcp-request-params (request)
  (and (hash-table-p request)
       (gethash "params" request)))

(defun dmx-mcp-argument (arguments key &optional default)
  (multiple-value-bind (value present-p) (gethash key arguments)
    (if present-p value default)))

(defun dmx-mcp-session-for-request (server &key initialize?)
  (let ((session-id (hunchentoot:header-in* "Mcp-Session-Id")))
    (cond
      (initialize?
       (values nil nil))
      ((null session-id)
       (values nil :missing))
      (t
       (let ((session (gethash session-id (dmx-mcp-server-sessions server))))
         (if session
             (values session-id session)
             (values session-id :unknown)))))))

(defun dmx-mcp-server-capabilities ()
  (dmx-mcp-json-object
   "resources" (dmx-mcp-json-object)
   "tools" (dmx-mcp-json-object)))

(defun dmx-mcp-resource-metadata (uri name description &key title)
  (let ((json (dmx-mcp-json-object
               "uri" uri
               "name" name
               "description" description
               "mimeType" "application/json")))
    (when title
      (setf (gethash "title" json) title))
    json))

(defun dmx-mcp-resource-template-metadata (uri-template name description)
  (dmx-mcp-json-object
   "uriTemplate" uri-template
   "name" name
   "description" description
   "mimeType" "application/json"))

(defun dmx-mcp-topic-title (topic)
  (or (dmx-json-child-value topic *dmx-notes-title-type-uri*)
      (dmx-json-object-value topic "value")
      "Untitled topic"))

(defun dmx-mcp-topic-summary (topic)
  (dmx-mcp-json-object
   "id" (dmx-json-object-value topic "id")
   "uri" (dmx-json-object-value topic "uri")
   "typeUri" (dmx-json-object-value topic "typeUri")
   "title" (dmx-mcp-topic-title topic)
   "value" (dmx-json-object-value topic "value")
   "text" (dmx-json-child-value topic *dmx-notes-text-type-uri*)
   "resourceUri" (dmx-mcp-topic-resource-uri
                  (dmx-json-object-value topic "id"))))

(defun dmx-mcp-note-summaries (topic-summaries)
  (remove-if-not
   (lambda (summary)
     (string= (or (gethash "typeUri" summary) "")
              *dmx-notes-note-type-uri*))
   topic-summaries))

(defun dmx-mcp-topicmap-topic-summaries (topicmap-json)
  (sort
   (loop for topic in (or (and topicmap-json
                               (json-array-elements (gethash "topics" topicmap-json)))
                          '())
         collect (dmx-mcp-topic-summary topic))
   #'<
   :key (lambda (summary)
          (gethash "id" summary))))

(defun dmx-mcp-workspace-summary (server &optional topicmap-id)
  (let* ((resolved-topicmap-id (or topicmap-id
                                   (dmx-mcp-server-workspace-topicmap-id server)))
         (topicmap-json (dmx-import-read-topicmap
                         (dmx-mcp-server-read-client server)
                         resolved-topicmap-id))
         (topicmap-topic (and topicmap-json (gethash "topic" topicmap-json)))
         (topic-summaries (and topicmap-json
                               (dmx-mcp-topicmap-topic-summaries topicmap-json)))
         (note-summaries (dmx-mcp-note-summaries topic-summaries)))
    (dmx-mcp-json-object
     "workspace" (dmx-mcp-json-object
                  "slug" (if (eql resolved-topicmap-id
                                   (dmx-mcp-server-workspace-topicmap-id server))
                             "context-window"
                             (format nil "topicmap-~D" resolved-topicmap-id))
                  "topicmapId" resolved-topicmap-id
                  "topicmapTitle" (and topicmap-topic
                                       (dmx-mcp-topic-title topicmap-topic)))
     "topicCount" (length topic-summaries)
     "noteCount" (length note-summaries)
     "topics" (coerce topic-summaries 'vector)
     "notes" (coerce note-summaries 'vector)
     "source" (dmx-mcp-json-object
               "readPath" "/topicmaps/<id>?children=true"
               "topicReadPath" "/core/topic/<id>?children=true&assocChildren=true"))))

(defun dmx-mcp-topic-projection (topic)
  (let ((selected-children (dmx-mcp-json-object)))
    (dolist (child-type-uri (list *dmx-notes-title-type-uri*
                                  *dmx-notes-text-type-uri*
                                  "dmx.timestamps.created"
                                  "dmx.timestamps.modified"))
      (when-let (value (dmx-json-child-value topic child-type-uri))
        (setf (gethash child-type-uri selected-children) value)))
    (dmx-mcp-json-object
     "id" (dmx-json-object-value topic "id")
     "uri" (dmx-json-object-value topic "uri")
     "typeUri" (dmx-json-object-value topic "typeUri")
     "title" (dmx-mcp-topic-title topic)
     "value" (dmx-json-object-value topic "value")
     "text" (dmx-json-child-value topic *dmx-notes-text-type-uri*)
     "children" selected-children)))

(defun dmx-mcp-topicmap-projection (topicmap-json)
  (let* ((topicmap-topic (gethash "topic" topicmap-json))
         (topic-summaries (dmx-mcp-topicmap-topic-summaries topicmap-json))
         (note-summaries (dmx-mcp-note-summaries topic-summaries)))
    (dmx-mcp-json-object
     "id" (dmx-json-object-value topicmap-topic "id")
     "uri" (dmx-json-object-value topicmap-topic "uri")
     "typeUri" (dmx-json-object-value topicmap-topic "typeUri")
     "title" (dmx-mcp-topic-title topicmap-topic)
     "topicCount" (length topic-summaries)
     "topics" (coerce topic-summaries 'vector)
     "noteCount" (length note-summaries)
     "notes" (coerce note-summaries 'vector)
     "assocsCount"
     (length (json-array-elements (gethash "assocs" topicmap-json)))
     "viewProps" (gethash "viewProps" topicmap-json))))

(defun dmx-mcp-known-topic-ids (server)
  (let* ((topicmap-json (dmx-import-read-topicmap
                         (dmx-mcp-server-read-client server)
                         (dmx-mcp-server-workspace-topicmap-id server)))
         (workspace-topic-ids
           (loop for topic in (or (and topicmap-json
                                       (json-array-elements (gethash "topics" topicmap-json)))
                                  '())
                 for topic-id = (dmx-json-object-value topic "id")
                 when topic-id
                   collect topic-id)))
    (remove-duplicates
     (append (dmx-mcp-server-known-topic-ids server)
             workspace-topic-ids)
     :test #'eql)))

(defun dmx-mcp-resource-list (server)
  (let ((resources
          (list (dmx-mcp-resource-metadata
                 (dmx-mcp-workspace-resource-uri)
                 "workspace/context-window"
                 "Summary projection of the shared DMX context-window workspace.")
                (dmx-mcp-resource-metadata
                 (dmx-mcp-topicmap-resource-uri
                  (dmx-mcp-server-workspace-topicmap-id server))
                 (format nil "topicmap/~D"
                         (dmx-mcp-server-workspace-topicmap-id server))
                 "Topicmap projection for the current shared workspace."))))
    (dolist (topic-id (dmx-mcp-known-topic-ids server))
      (let ((topic (dmx-import-read-topic (dmx-mcp-server-read-client server) topic-id)))
        (when topic
          (push (dmx-mcp-resource-metadata
                 (dmx-mcp-topic-resource-uri topic-id)
                 (format nil "topic/~D" topic-id)
                 (format nil "DMX topic ~D through the canonical core/topic read path." topic-id)
                 :title (dmx-mcp-topic-title topic))
                resources))))
    (coerce (nreverse resources) 'vector)))

(defun dmx-mcp-resource-templates ()
  (dmx-mcp-json-array
   (dmx-mcp-resource-template-metadata
    "dmx://topic/{id}"
    "topic/<id>"
    "Read a DMX topic by id.")
   (dmx-mcp-resource-template-metadata
    "dmx://topicmap/{id}"
    "topicmap/<id>"
    "Read a DMX topicmap by id.")))

(defun dmx-mcp-read-resource (server uri)
  (cond
    ((string= uri (dmx-mcp-workspace-resource-uri))
     (dmx-mcp-workspace-summary server))
    ((string= uri
              (dmx-mcp-topicmap-resource-uri
               (dmx-mcp-server-workspace-topicmap-id server)))
     (dmx-mcp-topicmap-projection
      (dmx-import-read-topicmap
       (dmx-mcp-server-read-client server)
       (dmx-mcp-server-workspace-topicmap-id server))))
    ((search "dmx://topic/" uri :test #'char=)
     (let* ((topic-id (parse-positive-integer uri))
            (topic (and topic-id
                        (dmx-import-read-topic
                         (dmx-mcp-server-read-client server)
                         topic-id))))
       (unless topic
         (error 'fedwiki-dmx-import-error
                :message (format nil "Unknown DMX topic resource ~A" uri)))
       (dmx-mcp-topic-projection topic)))
    ((search "dmx://topicmap/" uri :test #'char=)
     (let* ((topicmap-id (parse-positive-integer uri))
            (topicmap-json (and topicmap-id
                                (dmx-import-read-topicmap
                                 (dmx-mcp-server-read-client server)
                                 topicmap-id))))
       (unless topicmap-json
         (error 'fedwiki-dmx-import-error
                :message (format nil "Unknown DMX topicmap resource ~A" uri)))
       (dmx-mcp-topicmap-projection topicmap-json)))
    (t
     (error 'fedwiki-dmx-import-error
            :message (format nil "Unsupported MCP resource URI ~A" uri)))))

(defun dmx-mcp-live-write-available-p (server)
  (and (dmx-mcp-server-live-writes-enabled-p server)
       (or (typep (dmx-mcp-server-write-client server) 'memory-dmx-import-client)
           (and (typep (dmx-mcp-server-write-client server) 'http-dmx-import-client)
                (dmx-import-base-url-of (dmx-mcp-server-write-client server))
                (dmx-import-authorization-header-of
                 (dmx-mcp-server-write-client server))))))

(defun dmx-mcp-write-unavailable-error ()
  (dmx-mcp-json-object
   "status" "write_unavailable"
   "message"
   "Live DMX writes are disabled. Set HYPERDOC_MCP_ENABLE_LIVE_WRITES=1 and configure DMX write credentials before calling live tools."))

(defun dmx-mcp-validation-error-object (condition)
  (typecase condition
    (dmx-topicmap-view-props-validation-error
     (dmx-mcp-json-object
      "status" "validation_error"
      "message" (fedwiki-dmx-import-message-of condition)
      "boundary"
      (format nil "~A"
              (dmx-topicmap-view-props-validation-boundary-of condition))
      "missingLongKeys"
      (coerce (dmx-topicmap-view-props-validation-missing-long-keys-of condition)
              'vector)
      "forbiddenShortKeys"
      (coerce (dmx-topicmap-view-props-validation-forbidden-short-keys-of condition)
              'vector)
      "normalizedPayload"
      (dmx-topicmap-view-props-validation-normalized-payload-of condition)))
    (dmx-workspace-note-validation-error
     (dmx-mcp-json-object
      "status" "validation_error"
      "message" (fedwiki-dmx-import-message-of condition)
      "boundary"
      (format nil "~A"
              (dmx-workspace-note-validation-boundary-of condition))
      "missingFields"
      (coerce (dmx-workspace-note-validation-missing-fields-of condition) 'vector)
      "invalidFields"
      (coerce (dmx-workspace-note-validation-invalid-fields-of condition) 'vector)))
    (dmx-workspace-topic-validation-error
     (dmx-mcp-json-object
      "status" "validation_error"
      "message" (fedwiki-dmx-import-message-of condition)
      "boundary"
      (format nil "~A"
              (dmx-workspace-topic-validation-boundary-of condition))
      "missingFields"
      (coerce (dmx-workspace-topic-validation-missing-fields-of condition) 'vector)
      "invalidFields"
      (coerce (dmx-workspace-topic-validation-invalid-fields-of condition) 'vector)))
    (dmx-workspace-topic-ownership-error
     (dmx-mcp-json-object
      "status" "ownership_error"
      "message" (fedwiki-dmx-import-message-of condition)
      "topicId" (dmx-workspace-topic-ownership-topic-id-of condition)
      "ownershipClass"
      (format nil "~(~A~)" (dmx-workspace-topic-ownership-class-of condition))
      "uri" (dmx-workspace-topic-ownership-uri-of condition)
      "allowedActions"
      (coerce (mapcar (lambda (action) (format nil "~(~A~)" action))
                      (dmx-workspace-topic-ownership-allowed-actions-of condition))
              'vector)))
    (dmx-import-unsupported-operation-error
     (dmx-mcp-json-object
      "status" "unsupported_operation"
      "message" (fedwiki-dmx-import-message-of condition)
      "operation"
      (format nil "~(~A~)" (dmx-import-unsupported-operation-of condition))
      "endpoint" (dmx-import-unsupported-endpoint-of condition)
      "reason" (dmx-import-unsupported-reason-of condition)))
    (t
     (dmx-mcp-json-object
      "status" "error"
      "message" (princ-to-string condition)))))

(defun dmx-mcp-tool-result (object &key is-error)
  (let* ((normalized-object (dmx-mcp-normalize-json-value object))
         (result (dmx-mcp-json-object
                  "content" (dmx-mcp-content-from-object normalized-object)
                  "structuredContent" normalized-object)))
    (when is-error
      (setf (gethash "isError" result) t))
    result))

(defun dmx-mcp-dry-run-topicmap-context (arguments)
  (let ((topicmap-id (or (parse-positive-integer
                          (gethash "topicmapId" arguments))
                         (error 'fedwiki-dmx-import-error
                                :message "topicmapId is required for topicmap_context_add")))
        (topic-id (or (parse-positive-integer
                       (gethash "topicId" arguments))
                      (error 'fedwiki-dmx-import-error
                             :message "topicId is required for topicmap_context_add"))))
    (multiple-value-bind (normalized-view-props normalization)
        (normalize-dmx-topicmap-view-props
         (gethash "viewProps" arguments)
         :boundary 'validated-dmx-write-dry-run)
      (dmx-mcp-json-object
       "writeKind" "topicmap_context_add"
       "topicmapId" topicmap-id
       "topicId" topic-id
       "validationStatus" (getf normalization :status)
       "normalizedPayload" normalized-view-props
       "intendedEndpoint"
       (dmx-topicmap-add-topic-path topicmap-id topic-id)))))

(defun dmx-mcp-dry-run-topicmap-context-upsert (server arguments)
  (dmx-mcp-json-object
   "writeKind" "topicmap_context_upsert"
   "summary"
   (execute-dmx-workspace-topicmap-context-upsert
    (gethash "topicId" arguments)
    :workspace-topicmap-id
    (or (dmx-mcp-argument arguments "topicmapId")
        (dmx-mcp-server-workspace-topicmap-id server))
    :client (dmx-mcp-server-read-client server)
    :view-props (gethash "viewProps" arguments)
    :dry-run t)))

(defun dmx-mcp-dry-run-topicmap-context-remove (server arguments)
  (dmx-mcp-json-object
   "writeKind" "topicmap_context_remove"
   "summary"
   (execute-dmx-workspace-topicmap-context-remove
    (gethash "topicId" arguments)
    :workspace-topicmap-id
    (or (dmx-mcp-argument arguments "topicmapId")
        (dmx-mcp-server-workspace-topicmap-id server))
    :client (dmx-mcp-server-read-client server)
    :dry-run t)))

(defun dmx-mcp-dry-run-workspace-note (server arguments)
  (let ((summary
          (plan-dmx-workspace-note-write
           (gethash "title" arguments)
           (gethash "text" arguments)
           :workspace-topicmap-id
           (or (dmx-mcp-argument arguments "workspaceTopicmapId")
               (dmx-mcp-server-workspace-topicmap-id server))
           :client (dmx-mcp-server-read-client server)
           :view-props (gethash "viewProps" arguments)
           :note-key (dmx-mcp-argument arguments "noteKey")
           :uri (dmx-mcp-argument arguments "uri"))))
    (dmx-mcp-json-object
     "writeKind" "workspace_note_create"
     "summary" (dmx-workspace-note-plan-summary summary)
     "payload" (dmx-import-json-object
                (dmx-workspace-note-write-plan-payload summary)))))

(defun dmx-mcp-dry-run-workspace-note-update (server arguments)
  (let ((plan (plan-dmx-workspace-note-update
               (gethash "topicId" arguments)
               :title (dmx-mcp-argument arguments "title")
               :text (dmx-mcp-argument arguments "text")
               :client (dmx-mcp-server-read-client server))))
    (dmx-mcp-json-object
     "writeKind" "workspace_note_update"
     "summary" (dmx-workspace-note-plan-summary plan)
     "payload" (dmx-import-json-object
                (dmx-workspace-note-write-plan-payload plan)))))

(defun dmx-mcp-dry-run-handover (server arguments)
  (let ((result
          (create-dmx-workspace-handover
           (gethash "title" arguments)
           (gethash "summary" arguments)
           :from-agent (dmx-mcp-argument arguments "fromAgent")
           :to-agent (dmx-mcp-argument arguments "toAgent")
           :requested-action (dmx-mcp-argument arguments "requestedAction")
           :artifacts (coerce (or (json-array-elements (gethash "artifacts" arguments))
                                  #())
                              'list)
           :status (dmx-mcp-argument arguments "status")
           :workspace-topicmap-id
           (or (dmx-mcp-argument arguments "workspaceTopicmapId")
               (dmx-mcp-server-workspace-topicmap-id server))
           :client (dmx-mcp-server-read-client server)
           :view-props (gethash "viewProps" arguments)
           :note-key (dmx-mcp-argument arguments "noteKey")
           :dry-run t)))
    (dmx-mcp-json-object
     "writeKind" "handover_create"
     "summary" result)))

(defun dmx-mcp-read-topicmap-tool (server arguments)
  (let* ((topicmap-id (or (parse-positive-integer
                           (gethash "topicmapId" arguments))
                          (dmx-mcp-server-workspace-topicmap-id server)))
         (topicmap-json (dmx-import-read-topicmap
                         (dmx-mcp-server-read-client server)
                         topicmap-id)))
    (unless topicmap-json
      (error 'fedwiki-dmx-import-error
             :message (format nil "Unknown DMX topicmap ~D" topicmap-id)))
    (dmx-mcp-json-object
     "topicmapId" topicmap-id
     "projection" (dmx-mcp-topicmap-projection topicmap-json)
     "source" (dmx-mcp-json-object
               "resourceUri" (dmx-mcp-topicmap-resource-uri topicmap-id)
               "readPath" (format nil "/topicmaps/~D?children=true" topicmap-id)))))

(defun dmx-mcp-read-topic-tool (server arguments)
  (let* ((topic-id (or (parse-positive-integer
                        (gethash "topicId" arguments))
                       (error 'fedwiki-dmx-import-error
                              :message "topicId is required for read_dmx_topic")))
         (topic (dmx-import-read-topic
                 (dmx-mcp-server-read-client server)
                 topic-id)))
    (unless topic
      (error 'fedwiki-dmx-import-error
             :message (format nil "Unknown DMX topic ~D" topic-id)))
    (dmx-mcp-json-object
     "topicId" topic-id
     "topic" (dmx-mcp-topic-projection topic)
     "source" (dmx-mcp-json-object
               "resourceUri" (dmx-mcp-topic-resource-uri topic-id)
               "readPath" (format nil "/core/topic/~D?children=true&assocChildren=true"
                                  topic-id)))))

(defun dmx-mcp-resolve-workspace-note-tool (server arguments)
  (let* ((note-key
           (or (dmx-mcp-argument arguments "noteKey")
               (error 'fedwiki-dmx-import-error
                      :message "noteKey is required for resolve_workspace_note")))
         (resolution
           (resolve-dmx-workspace-note
            :workspace-topicmap-id
            (or (dmx-mcp-argument arguments "workspaceTopicmapId")
                (dmx-mcp-server-workspace-topicmap-id server))
            :client (dmx-mcp-server-read-client server)
            :note-key note-key
            :note-kind :workspace-note))
         (existing-topic
           (dmx-workspace-note-resolution-existing-topic resolution)))
    (dmx-mcp-json-object
     "noteKey" (dmx-workspace-note-resolution-note-key resolution)
     "uri" (dmx-workspace-note-resolution-uri resolution)
     "workspaceTopicmapId"
     (dmx-workspace-note-resolution-workspace-topicmap-id resolution)
     "existingTopicId"
     (dmx-workspace-note-resolution-existing-topic-id resolution)
     "inTopicmap"
     (and (dmx-workspace-note-resolution-existing-topic-id resolution)
          (dmx-workspace-note-resolution-in-topicmap-p resolution))
     "topicAction"
     (format nil "~(~A~)" (dmx-workspace-note-resolution-topic-action resolution))
     "topicmapAction"
     (format nil "~(~A~)" (dmx-workspace-note-resolution-topicmap-action resolution))
     "lookup" (dmx-mcp-json-object
               "kind" "uri_lookup"
               "resourceUri"
               (and (dmx-workspace-note-resolution-existing-topic-id resolution)
                    (dmx-mcp-topic-resource-uri
                     (dmx-workspace-note-resolution-existing-topic-id resolution)))
               "lookupPath"
               (format nil "/core/topic/uri/<uri>?~A"
                       *dmx-topic-fetch-query-string*))
     "topic" (and existing-topic
                  (dmx-mcp-topic-projection existing-topic)))))

(defun dmx-mcp-call-dry-run-tool (server arguments)
  (let ((write-kind (gethash "writeKind" arguments)))
    (cond
      ((equal write-kind "topicmap_context_add")
       (dmx-mcp-dry-run-topicmap-context arguments))
      ((equal write-kind "topicmap_context_upsert")
       (dmx-mcp-dry-run-topicmap-context-upsert server arguments))
      ((equal write-kind "topicmap_context_remove")
       (dmx-mcp-dry-run-topicmap-context-remove server arguments))
      ((equal write-kind "workspace_note_create")
       (dmx-mcp-dry-run-workspace-note server arguments))
      ((equal write-kind "workspace_note_update")
       (dmx-mcp-dry-run-workspace-note-update server arguments))
      ((equal write-kind "handover_create")
       (dmx-mcp-dry-run-handover server arguments))
      (t
       (error 'fedwiki-dmx-import-error
              :message (format nil "Unsupported validated_dmx_write_dry_run writeKind ~S"
                               write-kind))))))

(defun dmx-mcp-call-write-tool (server tool-name arguments)
  (let ((dry-run (dmx-mcp-argument arguments "dryRun" t)))
    (flet ((ensure-live-write-available ()
             (unless (or dry-run
                         (dmx-mcp-live-write-available-p server))
               (return-from dmx-mcp-call-write-tool
                 (dmx-mcp-tool-result (dmx-mcp-write-unavailable-error)
                                      :is-error t)))))
      (handler-case
          (cond
            ((equal tool-name "validated_dmx_write_dry_run")
             (dmx-mcp-tool-result (dmx-mcp-call-dry-run-tool server arguments)))
            ((equal tool-name "read_dmx_topicmap")
             (dmx-mcp-tool-result
              (dmx-mcp-read-topicmap-tool server arguments)))
            ((equal tool-name "read_dmx_topic")
             (dmx-mcp-tool-result
              (dmx-mcp-read-topic-tool server arguments)))
            ((equal tool-name "resolve_workspace_note")
             (dmx-mcp-tool-result
              (dmx-mcp-resolve-workspace-note-tool server arguments)))
            ((equal tool-name "append_workspace_note")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (execute-dmx-workspace-note-write
               (gethash "title" arguments)
               (gethash "text" arguments)
               :workspace-topicmap-id
               (or (dmx-mcp-argument arguments "workspaceTopicmapId")
                   (dmx-mcp-server-workspace-topicmap-id server))
               :client (dmx-mcp-server-write-client server)
               :view-props (gethash "viewProps" arguments)
               :note-key (dmx-mcp-argument arguments "noteKey")
               :uri (dmx-mcp-argument arguments "uri")
               :dry-run dry-run)))
            ((equal tool-name "update_workspace_note")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (execute-dmx-workspace-note-update
               (gethash "topicId" arguments)
               :title (dmx-mcp-argument arguments "title")
               :text (dmx-mcp-argument arguments "text")
               :client (dmx-mcp-server-write-client server)
               :dry-run dry-run)))
            ((equal tool-name "create_handover")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (create-dmx-workspace-handover
               (gethash "title" arguments)
               (gethash "summary" arguments)
               :from-agent (dmx-mcp-argument arguments "fromAgent")
               :to-agent (dmx-mcp-argument arguments "toAgent")
               :requested-action (dmx-mcp-argument arguments "requestedAction")
               :artifacts (coerce (or (json-array-elements (gethash "artifacts" arguments))
                                      #())
                                  'list)
               :status (dmx-mcp-argument arguments "status")
               :workspace-topicmap-id
               (or (dmx-mcp-argument arguments "workspaceTopicmapId")
                   (dmx-mcp-server-workspace-topicmap-id server))
               :client (dmx-mcp-server-write-client server)
               :view-props (gethash "viewProps" arguments)
               :note-key (dmx-mcp-argument arguments "noteKey")
               :uri (dmx-mcp-argument arguments "uri")
               :dry-run dry-run)))
            ((equal tool-name "upsert_workspace_topicmap_context")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (execute-dmx-workspace-topicmap-context-upsert
               (gethash "topicId" arguments)
               :workspace-topicmap-id
               (or (dmx-mcp-argument arguments "topicmapId")
                   (dmx-mcp-server-workspace-topicmap-id server))
               :client (dmx-mcp-server-write-client server)
               :view-props (gethash "viewProps" arguments)
               :dry-run dry-run)))
            ((equal tool-name "remove_workspace_topic_from_topicmap")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (execute-dmx-workspace-topicmap-context-remove
               (gethash "topicId" arguments)
               :workspace-topicmap-id
               (or (dmx-mcp-argument arguments "topicmapId")
                   (dmx-mcp-server-workspace-topicmap-id server))
               :client (dmx-mcp-server-write-client server)
               :dry-run dry-run)))
            ((equal tool-name "delete_workspace_topic")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (execute-dmx-workspace-topic-delete
               (gethash "topicId" arguments)
               :workspace-topicmap-id
               (or (dmx-mcp-argument arguments "workspaceTopicmapId")
                   (dmx-mcp-server-workspace-topicmap-id server))
               :client (dmx-mcp-server-write-client server)
               :dry-run dry-run)))
            ((equal tool-name "delete_workspace_note")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (execute-dmx-workspace-note-delete
               :note-key (dmx-mcp-argument arguments "noteKey")
               :topic-id (dmx-mcp-argument arguments "topicId")
               :note-kind (dmx-mcp-argument arguments "noteKind")
               :workspace-topicmap-id
               (or (dmx-mcp-argument arguments "workspaceTopicmapId")
                   (dmx-mcp-server-workspace-topicmap-id server))
               :client (dmx-mcp-server-write-client server)
               :dry-run dry-run)))
            ((equal tool-name "upsert_workspace_topic_factory_snippet")
             (ensure-live-write-available)
             (dmx-mcp-tool-result
              (execute-dmx-workspace-topic-factory-snippet-upsert
               :snippet-id (dmx-mcp-argument arguments "snippetId")
               :snippet-text (dmx-mcp-argument arguments "snippetText")
               :source-path (dmx-mcp-argument arguments "sourcePath")
               :source-origin-id (dmx-mcp-argument arguments "sourceOriginId")
               :source-origin-path (dmx-mcp-argument arguments "sourceOriginPath")
               :related-hyperdoc-page-title
               (dmx-mcp-argument arguments "relatedHyperdocPageTitle")
               :related-topic-id (dmx-mcp-argument arguments "relatedTopicId")
               :references (gethash "references" arguments)
               :provenance (gethash "provenance" arguments)
               :workspace-topicmap-id
               (or (dmx-mcp-argument arguments "workspaceTopicmapId")
                   (dmx-mcp-server-workspace-topicmap-id server))
               :client (dmx-mcp-server-write-client server)
               :topic-type-uri (dmx-mcp-argument arguments "topicTypeUri")
               :view-props (gethash "viewProps" arguments)
               :topic-value (dmx-mcp-argument arguments "topicValue")
               :dry-run dry-run)))
            (t
             (dmx-mcp-tool-result
              (dmx-mcp-json-object
               "status" "error"
               "message" (format nil "Unknown MCP tool ~A" tool-name))
              :is-error t)))
        (dmx-topicmap-view-props-validation-error (condition)
          (dmx-mcp-tool-result (dmx-mcp-validation-error-object condition)
                               :is-error t))
        (dmx-workspace-note-validation-error (condition)
          (dmx-mcp-tool-result (dmx-mcp-validation-error-object condition)
                               :is-error t))
        (dmx-workspace-topic-validation-error (condition)
          (dmx-mcp-tool-result (dmx-mcp-validation-error-object condition)
                               :is-error t))
        (dmx-workspace-topic-ownership-error (condition)
          (dmx-mcp-tool-result (dmx-mcp-validation-error-object condition)
                               :is-error t))
        (dmx-import-unsupported-operation-error (condition)
          (dmx-mcp-tool-result (dmx-mcp-validation-error-object condition)
                               :is-error t))
        (fedwiki-dmx-import-error (condition)
          (dmx-mcp-tool-result (dmx-mcp-validation-error-object condition)
                               :is-error t))))))

(defun dmx-mcp-tool-definitions ()
  (dmx-mcp-json-array
   (dmx-mcp-json-object
    "name" "validated_dmx_write_dry_run"
    "description"
    "Return the normalized payload and validation status for one narrow HyperDoc-to-DMX write shape without mutating DMX."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "writeKind" (dmx-mcp-json-object
                   "type" "string"
                   "enum" (dmx-mcp-json-array
                           "topicmap_context_add"
                           "topicmap_context_upsert"
                           "topicmap_context_remove"
                           "workspace_note_create"
                           "workspace_note_update"
                           "handover_create"))
      "topicmapId" (dmx-mcp-json-object "type" "integer")
      "topicId" (dmx-mcp-json-object "type" "integer")
      "title" (dmx-mcp-json-object "type" "string")
      "text" (dmx-mcp-json-object "type" "string")
      "summary" (dmx-mcp-json-object "type" "string")
      "noteKey" (dmx-mcp-json-object "type" "string")
      "workspaceTopicmapId" (dmx-mcp-json-object "type" "integer")
      "viewProps" (dmx-mcp-json-object "type" "object")
      "artifacts" (dmx-mcp-json-object "type" "array"
                                      "items" (dmx-mcp-json-object "type" "string")))
     "required" (dmx-mcp-json-array "writeKind")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "append_workspace_note"
    "description"
    "Create or update a typed dmx.notes.note in the shared context-window workspace through the guarded HyperDoc adapter."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "title" (dmx-mcp-json-object "type" "string")
      "text" (dmx-mcp-json-object "type" "string")
      "noteKey" (dmx-mcp-json-object "type" "string")
      "workspaceTopicmapId" (dmx-mcp-json-object "type" "integer")
      "viewProps" (dmx-mcp-json-object "type" "object")
     "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array "title" "text")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "upsert_workspace_topicmap_context"
    "description"
    "Ensure a typed topicmap-context placement for an existing topic by adding it to a workspace topicmap or updating its validated long-form view props."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "topicId" (dmx-mcp-json-object "type" "integer")
      "topicmapId" (dmx-mcp-json-object "type" "integer")
      "viewProps" (dmx-mcp-json-object "type" "object")
      "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array "topicId" "viewProps")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "remove_workspace_topic_from_topicmap"
    "description"
    "Plan or execute a typed workspace-topic unlink from a topicmap. Live HTTP unlink remains disabled until a DELETE contract is proven for the topicmap membership route."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "topicId" (dmx-mcp-json-object "type" "integer")
      "topicmapId" (dmx-mcp-json-object "type" "integer")
      "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array "topicId")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "read_dmx_topicmap"
    "description"
    "Read a DMX topicmap projection, defaulting to the current shared workspace topicmap, including topic and note ids."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "topicmapId" (dmx-mcp-json-object "type" "integer"))
     "required" (dmx-mcp-json-array)
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "read_dmx_topic"
    "description"
    "Read a DMX topic by id, including note body and selected child metadata when present."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "topicId" (dmx-mcp-json-object "type" "integer"))
     "required" (dmx-mcp-json-array "topicId")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "resolve_workspace_note"
    "description"
    "Resolve a workspace note by noteKey through the read client and report the existing topic id plus topicmap membership."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "noteKey" (dmx-mcp-json-object "type" "string")
      "workspaceTopicmapId" (dmx-mcp-json-object "type" "integer"))
     "required" (dmx-mcp-json-array "noteKey")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "update_workspace_note"
    "description"
    "Update an existing dmx.notes.note topic body by topic id through the guarded HyperDoc adapter."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "topicId" (dmx-mcp-json-object "type" "integer")
      "title" (dmx-mcp-json-object "type" "string")
      "text" (dmx-mcp-json-object "type" "string")
     "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array "topicId")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "delete_workspace_note"
    "description"
    "Hard-delete a HyperDoc-owned workspace note or handover by noteKey or topic id. Foreign notes are rejected by the ownership guard."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "noteKey" (dmx-mcp-json-object "type" "string")
      "topicId" (dmx-mcp-json-object "type" "integer")
      "noteKind" (dmx-mcp-json-object "type" "string")
      "workspaceTopicmapId" (dmx-mcp-json-object "type" "integer")
      "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array)
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "delete_workspace_topic"
    "description"
    "Hard-delete a HyperDoc-owned workspace topic by topic id. Ownership checks reject foreign topics and unsupported delete targets."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "topicId" (dmx-mcp-json-object "type" "integer")
      "workspaceTopicmapId" (dmx-mcp-json-object "type" "integer")
      "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array "topicId")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "upsert_workspace_topic_factory_snippet"
    "description"
    "Create or update a HyperDoc-owned topic-factory snippet twin and place it into the shared workspace topicmap through the guarded topic/topicmap adapter."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "snippetId" (dmx-mcp-json-object "type" "string")
      "snippetText" (dmx-mcp-json-object "type" "string")
      "sourcePath" (dmx-mcp-json-object "type" "string")
      "sourceOriginId" (dmx-mcp-json-object "type" "string")
      "sourceOriginPath" (dmx-mcp-json-object "type" "string")
      "relatedHyperdocPageTitle" (dmx-mcp-json-object "type" "string")
      "relatedTopicId" (dmx-mcp-json-object "type" "string")
      "references" (dmx-mcp-json-object "type" "array"
                                        "items" (dmx-mcp-json-object "type" "string"))
      "provenance" (dmx-mcp-json-object "type" "object")
      "workspaceTopicmapId" (dmx-mcp-json-object "type" "integer")
      "topicTypeUri" (dmx-mcp-json-object "type" "string")
      "topicValue" (dmx-mcp-json-object "type" "string")
      "viewProps" (dmx-mcp-json-object "type" "object")
      "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array "snippetId" "snippetText" "sourcePath")
     "additionalProperties" t))
   (dmx-mcp-json-object
    "name" "create_handover"
    "description"
    "Create a structured handover note in the shared context-window workspace through the guarded HyperDoc adapter."
    "inputSchema"
    (dmx-mcp-json-object
     "type" "object"
     "properties"
     (dmx-mcp-json-object
      "title" (dmx-mcp-json-object "type" "string")
      "summary" (dmx-mcp-json-object "type" "string")
      "fromAgent" (dmx-mcp-json-object "type" "string")
      "toAgent" (dmx-mcp-json-object "type" "string")
      "requestedAction" (dmx-mcp-json-object "type" "string")
      "status" (dmx-mcp-json-object "type" "string")
      "artifacts" (dmx-mcp-json-object "type" "array"
                                      "items" (dmx-mcp-json-object "type" "string"))
      "noteKey" (dmx-mcp-json-object "type" "string")
      "workspaceTopicmapId" (dmx-mcp-json-object "type" "integer")
      "viewProps" (dmx-mcp-json-object "type" "object")
      "dryRun" (dmx-mcp-json-object "type" "boolean"))
     "required" (dmx-mcp-json-array "title" "summary")
     "additionalProperties" t))))

(defun dmx-mcp-handle-initialize (server request)
  (let* ((id (dmx-mcp-request-id request))
         (params (or (dmx-mcp-request-params request)
                     (make-hash-table :test #'equal)))
         (requested-version (or (gethash "protocolVersion" params)
                                *dmx-mcp-protocol-version*))
         (session-id (dmx-mcp-session-id)))
    (setf (gethash session-id (dmx-mcp-server-sessions server))
          (list :client-info (gethash "clientInfo" params)
                :initialized nil
                :protocol-version requested-version))
    (dmx-mcp-log server "initialize session=~A version=~A" session-id requested-version)
    (dmx-mcp-json-rpc-success
     id
     (dmx-mcp-json-object
      "protocolVersion" *dmx-mcp-protocol-version*
      "capabilities" (dmx-mcp-server-capabilities)
      "serverInfo"
      (dmx-mcp-json-object
       "name" *dmx-mcp-server-name*
       "version" *dmx-mcp-server-version*))
     :session-id session-id)))

(defun dmx-mcp-handle-request (server request session-id session)
  (let ((id (dmx-mcp-request-id request))
        (method (dmx-mcp-request-method-name request))
        (params (or (dmx-mcp-request-params request)
                    (make-hash-table :test #'equal))))
    (dmx-mcp-log server "request method=~A session=~A" method session-id)
    (cond
      ((string= method "notifications/initialized")
       (setf (getf session :initialized) t
             (gethash session-id (dmx-mcp-server-sessions server)) session)
       (dmx-mcp-empty-response :status 202 :session-id session-id))
      ((string= method "ping")
       (dmx-mcp-json-rpc-success id (dmx-mcp-json-object) :session-id session-id))
      ((string= method "resources/list")
       (dmx-mcp-json-rpc-success
        id
        (dmx-mcp-json-object
         "resources" (dmx-mcp-resource-list server))
        :session-id session-id))
      ((string= method "resources/templates/list")
       (dmx-mcp-json-rpc-success
        id
        (dmx-mcp-json-object
         "resourceTemplates" (dmx-mcp-resource-templates))
        :session-id session-id))
      ((string= method "resources/read")
       (let* ((uri (gethash "uri" params))
              (resource (dmx-mcp-read-resource server uri)))
         (dmx-mcp-json-rpc-success
          id
          (dmx-mcp-json-object
           "contents"
           (dmx-mcp-json-array
            (dmx-mcp-json-object
             "uri" uri
             "mimeType" "application/json"
             "text" (encode-json-string resource))))
          :session-id session-id)))
      ((string= method "tools/list")
       (dmx-mcp-json-rpc-success
        id
        (dmx-mcp-json-object
         "tools" (dmx-mcp-tool-definitions))
        :session-id session-id))
      ((string= method "tools/call")
       (dmx-mcp-json-rpc-success
        id
        (dmx-mcp-call-write-tool server
                                 (gethash "name" params)
                                 (or (gethash "arguments" params)
                                     (make-hash-table :test #'equal)))
        :session-id session-id))
      (t
       (dmx-mcp-json-rpc-error
        id
        -32601
        (format nil "Method not found: ~A" method)
        :session-id session-id)))))

(hunchentoot:define-easy-handler (dmx-mcp-endpoint :uri "/mcp") ()
  (let ((server *dmx-mcp-server*))
    (or (dmx-mcp-server-require-auth server)
        (dmx-mcp-server-require-origin server)
        (handler-case
            (case (hunchentoot:request-method*)
              (:post
               (let* ((request (dmx-mcp-request-json))
                      (method (dmx-mcp-request-method-name request))
                      (initialize? (string= method "initialize")))
                 (multiple-value-bind (session-id session)
                     (dmx-mcp-session-for-request server :initialize? initialize?)
                   (cond
                     (initialize?
                      (dmx-mcp-handle-initialize server request))
                     ((eq session :missing)
                      (dmx-mcp-json-rpc-error
                       (dmx-mcp-request-id request)
                       -32000
                       "Missing Mcp-Session-Id header"
                       :status 400))
                     ((eq session :unknown)
                      (dmx-mcp-json-rpc-error
                       (dmx-mcp-request-id request)
                       -32001
                       "Unknown MCP session"
                       :status 404))
                     (t
                      (dmx-mcp-handle-request server request session-id session))))))
              (:delete
               (multiple-value-bind (session-id session)
                   (dmx-mcp-session-for-request server)
                 (declare (ignore session))
                 (when session-id
                   (remhash session-id (dmx-mcp-server-sessions server)))
                 (dmx-mcp-empty-response :status 204)))
              (otherwise
               (setf (hunchentoot:return-code*) 405
                     (hunchentoot:content-type*) "application/json; charset=utf-8")
               (encode-json-string
                (dmx-mcp-json-object
                 "error" "method_not_allowed"
                 "message" "Use POST for MCP JSON-RPC requests"))))
          (dmx-topicmap-view-props-validation-error (condition)
            (dmx-mcp-json-rpc-error
             nil
             -32010
             (fedwiki-dmx-import-message-of condition)
             :data (dmx-mcp-validation-error-object condition)))
          (dmx-workspace-note-validation-error (condition)
            (dmx-mcp-json-rpc-error
             nil
             -32010
             (fedwiki-dmx-import-message-of condition)
             :data (dmx-mcp-validation-error-object condition)))
          (fedwiki-dmx-import-error (condition)
            (dmx-mcp-json-rpc-error
             nil
             -32010
             (fedwiki-dmx-import-message-of condition)
             :data (dmx-mcp-validation-error-object condition)))
          (error (condition)
            (dmx-mcp-log server "unhandled error: ~A" condition)
            (dmx-mcp-json-rpc-error
             nil
             -32099
             "Internal MCP server error"
             :data (dmx-mcp-json-object
                    "detail" (princ-to-string condition))))))))

(defun serve-dmx-mcp-server (&key port address server)
  (when *dmx-mcp-acceptor*
    (stop-dmx-mcp-server))
  (setf *dmx-mcp-server* (or server
                             (make-default-dmx-mcp-server)))
  (let ((resolved-port (or port
                           (parse-positive-integer (uiop:getenv "HYPERDOC_MCP_PORT"))
                           *dmx-mcp-default-port*))
        (resolved-address (or address
                              (uiop:getenv "HYPERDOC_MCP_BIND_ADDRESS")
                              *dmx-mcp-default-bind-address*)))
    (setf *dmx-mcp-acceptor*
          (make-instance 'hunchentoot:easy-acceptor
                         :port resolved-port
                         :address resolved-address))
    (hunchentoot:start *dmx-mcp-acceptor*)
    (dmx-mcp-log *dmx-mcp-server*
                 "listening on http://~A:~D/mcp workspace-topicmap-id=~D live-writes=~:[off~;on~]"
                 resolved-address
                 resolved-port
                 (dmx-mcp-server-workspace-topicmap-id *dmx-mcp-server*)
                 (dmx-mcp-live-write-available-p *dmx-mcp-server*))
    *dmx-mcp-acceptor*))

(defun stop-dmx-mcp-server ()
  (when *dmx-mcp-acceptor*
    (ignore-errors (hunchentoot:stop *dmx-mcp-acceptor*))
    (setf *dmx-mcp-acceptor* nil
          *dmx-mcp-server* nil))
  t)
