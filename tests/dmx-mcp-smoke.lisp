;;;; Smoke tests for the DMX MCP server

(in-package :hyperdoc/tests)

(defparameter *dmx-mcp-smoke-workspace-topicmap-id* 919822)
(defparameter *dmx-mcp-smoke-primary-topic-id* 907120)
(defparameter *dmx-mcp-smoke-secondary-topic-id* 921494)
(defparameter *dmx-mcp-live-secondary-topic-id* 921464)
(defparameter *dmx-mcp-smoke-primary-note-key*
  "dmx-incident-remediation-for-hyperdoc")

(defun mcp-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun mcp-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected ~S but got ~S" message expected actual)))

(defun mcp-test-json-object (&rest key-values)
  (let ((json (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (setf (gethash key json) value))
    json))

(defun mcp-test-response-header (headers name)
  (cdr (find name headers :test #'string-equal :key #'car)))

(defun mcp-test-body-string (body)
  (cond
    ((null body) nil)
    ((stringp body) body)
    ((vectorp body) (babel:octets-to-string body :encoding :utf-8))
    (t body)))

(defun mcp-test-port ()
  (+ 19000 (random 2000)))

(defun mcp-test-view-props (&key (x 160) (y 120) (visibility t) (pinned nil))
  (hyperdoc::make-dmx-topicmap-view-props-json-object
   :x x :y y :visibility visibility :pinned pinned))

(defun mcp-test-header-value (headers name)
  (cdr (find name headers :test #'string-equal :key #'car)))

(defun mcp-test-json-stream (object)
  (make-string-input-stream (hyperdoc::encode-json-string object)))

(defun run-dmx-workspace-note-http-single-content-type-smoke-test ()
  (let ((original (symbol-function 'drakma:http-request))
        (create-call nil)
        (add-call nil)
        (update-call nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method additional-headers content content-type
                               &allow-other-keys)
                   (cond
                     ((and (eq method :get)
                           (search "/core/topic/uri/" url))
                      (values (make-string-input-stream "") 404 nil nil nil "Not Found"))
                     ((and (eq method :post)
                           (search "/core/topic" url))
                      (setf create-call (list :url url
                                              :headers additional-headers
                                              :content-type content-type
                                              :content content))
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "id" 921742
                         "uri" "hyperdoc:mcp/workspace-note/context-window-workspace-as-shared-blackboard"
                         "typeUri" "dmx.notes.note"
                         "value" "Context window workspace as shared blackboard"))
                       200 nil nil nil "OK"))
                     ((and (eq method :post)
                           (search "/topicmaps/919822/topic/921742" url))
                      (setf add-call (list :url url
                                           :headers additional-headers
                                           :content-type content-type
                                           :content content))
                      (values (make-string-input-stream "") 204 nil nil nil "No Content"))
                     ((and (eq method :get)
                           (search "/core/topic/907120?" url))
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "id" 907120
                         "uri" "dmx://topic/907120"
                         "typeUri" "dmx.notes.note"
                         "value" "DMX incident remediation for HyperDoc"
                         "children" (mcp-test-json-object
                                     "dmx.notes.title" "DMX incident remediation for HyperDoc"
                                     "dmx.notes.text" "Existing remediation body")))
                       200 nil nil nil "OK"))
                     ((and (eq method :put)
                           (search "/core/topic/907120" url))
                      (setf update-call (list :url url
                                              :headers additional-headers
                                              :content-type content-type
                                              :content content))
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "id" 907120
                         "uri" "dmx://topic/907120"
                         "typeUri" "dmx.notes.note"
                         "value" "DMX incident remediation for HyperDoc"))
                       200 nil nil nil "OK"))
                     (t
                      (error "Unexpected Drakma call ~S ~S" method url)))))
           (let ((client (make-instance 'hyperdoc::http-dmx-import-client
                                        :base-url "https://dmx.ralfbarkow.ch"
                                        :workspace-id 919815)))
             (hyperdoc::execute-dmx-workspace-note-write
              "Context window workspace as shared blackboard"
              "Shared-blackboard intent and collaboration context."
              :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
              :client client
              :note-key "context-window-workspace-as-shared-blackboard"
              :dry-run nil)
             (hyperdoc::execute-dmx-workspace-note-update
              907120
              :text "Updated remediation body."
              :client client
              :dry-run nil))
           (dolist (call (list create-call add-call update-call))
             (mcp-assert-true call "Each guarded HTTP write call must be captured")
             (mcp-assert-equal "application/json"
                               (getf call :content-type)
                               "Guarded HTTP write must keep Drakma content-type")
             (mcp-assert-equal "dmx_workspace_id=919815"
                               (mcp-test-header-value (getf call :headers) "Cookie")
                               "Guarded HTTP write must carry the configured DMX workspace cookie")
             (mcp-assert-true
              (null (mcp-test-header-value (getf call :headers) "Content-Type"))
              "Guarded HTTP write must not duplicate Content-Type in additional headers"))
           (mcp-assert-true
            (search "\"dmx.notes.title\"" (getf create-call :content))
            "Guarded create payload must still carry the note title child")
           (mcp-assert-true
            (search "\"dmx.notes.text\"" (getf update-call :content))
            "Guarded update payload must still carry the note text child"))
      (setf (symbol-function 'drakma:http-request) original))))

(defun mcp-test-seed-note
    (client id title text
     &key (topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*)
          (x 160)
          (y 120)
          uri)
  (let ((topic (hyperdoc::dmx-import-create-topic
                client
                (list* :id id
                       (hyperdoc::dmx-workspace-note-payload
                        title
                        text
                        (or uri
                            (format nil "hyperdoc:mcp/test/note/~D" id)))))))
    (hyperdoc::dmx-import-add-topic-to-topicmap
     client
     topicmap-id
     id
     (mcp-test-view-props :x x :y y))
    topic))

(defun make-dmx-mcp-smoke-server ()
  (let ((client (make-instance 'hyperdoc::memory-dmx-import-client
                               :next-topic-id 930000)))
    (mcp-test-seed-note client
                        *dmx-mcp-smoke-primary-topic-id*
                        "DMX incident remediation for HyperDoc"
                        "Live MCP smoke topic body"
                        :uri (hyperdoc::dmx-workspace-note-uri
                              :workspace-note
                              *dmx-mcp-smoke-primary-note-key*))
    (mcp-test-seed-note client
                        *dmx-mcp-smoke-secondary-topic-id*
                        "Topic factory snippet probe"
                        "Secondary workspace topic"
                        :x 220 :y 240)
    (hyperdoc::make-dmx-mcp-server
     :read-client client
     :write-client client
     :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
     :known-topic-ids (list *dmx-mcp-smoke-primary-topic-id*)
     :bearer-token nil
     :allowed-origins nil
     :live-writes-enabled-p t
     :sessions (make-hash-table :test #'equal)
     :log-stream nil)))

(defun make-dmx-mcp-live-server ()
  (let ((client (or (hyperdoc::make-http-dmx-import-client-from-environment
                     :verbose nil)
                    (error "Live DMX MCP smoke test requires HYPERDOC_DMX_IMPORT_BASE_URL"))))
    (hyperdoc::make-dmx-mcp-server
     :read-client client
     :write-client client
     :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
     :known-topic-ids (list *dmx-mcp-smoke-primary-topic-id*
                            *dmx-mcp-live-secondary-topic-id*)
     :bearer-token nil
     :allowed-origins nil
     :live-writes-enabled-p nil
     :sessions (make-hash-table :test #'equal)
     :log-stream nil)))

(defun mcp-test-call (url payload &key session-id)
  (multiple-value-bind (body status headers)
      (drakma:http-request url
                           :method :post
                           :content (hyperdoc::encode-json-string payload)
                           :content-type "application/json"
                           :additional-headers
                           (append '(("Accept" . "application/json, text/event-stream"))
                                   (when session-id
                                     (list (cons "Mcp-Session-Id" session-id)))))
    (values (and body (shasht:read-json (mcp-test-body-string body)))
            status
            headers)))

(defun mcp-test-notify-initialized (url session-id)
  (multiple-value-bind (body status headers)
      (drakma:http-request url
                           :method :post
                           :content (hyperdoc::encode-json-string
                                     (mcp-test-json-object
                                      "jsonrpc" "2.0"
                                      "method" "notifications/initialized"))
                           :content-type "application/json"
                           :additional-headers
                           `(("Accept" . "application/json, text/event-stream")
                             ("Mcp-Session-Id" . ,session-id)))
    (values body status headers)))

(defun mcp-test-call-tool (url session-id id name &optional (arguments (mcp-test-json-object)))
  (mcp-test-call url
                 (mcp-test-json-object
                  "jsonrpc" "2.0"
                  "id" id
                  "method" "tools/call"
                  "params"
                  (mcp-test-json-object
                   "name" name
                   "arguments" arguments))
                 :session-id session-id))

(defun mcp-test-open-session (url &key (id 1) (client-name "hyperdoc-smoke") (client-version "1.0"))
  (multiple-value-bind (initialize-body initialize-status initialize-headers)
      (mcp-test-call
       url
       (mcp-test-json-object
        "jsonrpc" "2.0"
        "id" id
        "method" "initialize"
        "params"
        (mcp-test-json-object
         "protocolVersion" "2025-03-26"
         "clientInfo" (mcp-test-json-object
                       "name" client-name
                       "version" client-version))))
    (mcp-assert-equal 200 initialize-status "initialize status")
    (let ((session-id (mcp-test-response-header initialize-headers "Mcp-Session-Id")))
      (mcp-assert-true session-id "initialize must return Mcp-Session-Id")
      (mcp-assert-equal "hyperdoc-dmx-mcp"
                        (gethash "name"
                                 (gethash "serverInfo"
                                          (gethash "result" initialize-body)))
                        "initialize serverInfo.name")
      (multiple-value-bind (_ notify-status __)
          (mcp-test-notify-initialized url session-id)
        (declare (ignore _ __))
        (mcp-assert-equal 202 notify-status "initialized notification status"))
      session-id)))

(defun run-dmx-mcp-smoke-test ()
  (let* ((port (mcp-test-port))
         (url (format nil "http://127.0.0.1:~D/mcp" port))
         (server (make-dmx-mcp-smoke-server)))
    (unwind-protect
         (progn
           (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
           (sleep 0.2)
           (multiple-value-bind (initialize-body initialize-status initialize-headers)
               (mcp-test-call
                url
                (mcp-test-json-object
                 "jsonrpc" "2.0"
                 "id" 1
                 "method" "initialize"
                 "params"
                 (mcp-test-json-object
                  "protocolVersion" "2025-03-26"
                  "clientInfo" (mcp-test-json-object
                                "name" "hyperdoc-smoke"
                                "version" "1.0"))))
             (mcp-assert-equal 200 initialize-status "initialize status")
             (let ((session-id (mcp-test-response-header initialize-headers "Mcp-Session-Id")))
               (mcp-assert-true session-id "initialize must return Mcp-Session-Id")
               (mcp-assert-equal "hyperdoc-dmx-mcp"
                                 (gethash "name"
                                          (gethash "serverInfo"
                                                   (gethash "result" initialize-body)))
                                 "initialize serverInfo.name")
               (multiple-value-bind (_ notify-status __)
                   (mcp-test-notify-initialized url session-id)
                 (declare (ignore _ __))
                 (mcp-assert-equal 202 notify-status "initialized notification status"))
               (multiple-value-bind (resources-body resources-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 2
                                   "method" "resources/list")
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 resources-status "resources/list status")
                 (let* ((resources (hyperdoc::json-array-elements
                                    (gethash "resources"
                                             (gethash "result" resources-body))))
                        (resource-uris (mapcar (lambda (resource)
                                                 (gethash "uri" resource))
                                               resources)))
                   (mcp-assert-true
                    (member "dmx://workspace/context-window" resource-uris :test #'string=)
                    "resources/list must include workspace/context-window")
                   (mcp-assert-true
                    (member "dmx://topic/907120" resource-uris :test #'string=)
                    "resources/list must include topic/907120")
                   (mcp-assert-true
                    (member "dmx://topic/921494" resource-uris :test #'string=)
                    "resources/list must include an additional workspace topic")))
               (multiple-value-bind (workspace-body workspace-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 3
                                   "method" "resources/read"
                                   "params"
                                   (mcp-test-json-object
                                    "uri" "dmx://workspace/context-window"))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 workspace-status "workspace read status")
                 (let* ((contents (hyperdoc::json-array-elements
                                   (gethash "contents"
                                            (gethash "result" workspace-body))))
                        (workspace-json (shasht:read-json
                                         (gethash "text" (first contents)))))
                   (mcp-assert-equal *dmx-mcp-smoke-workspace-topicmap-id*
                                     (gethash "topicmapId"
                                              (gethash "workspace" workspace-json))
                                     "workspace summary topicmap id")
                   (mcp-assert-equal 2
                                     (gethash "noteCount" workspace-json)
                                     "workspace summary note count")))
               (dolist (resource-uri '("dmx://topic/907120" "dmx://topic/921494"))
                 (multiple-value-bind (topic-body topic-status _)
                     (mcp-test-call url
                                    (mcp-test-json-object
                                     "jsonrpc" "2.0"
                                     "id" 4
                                     "method" "resources/read"
                                     "params" (mcp-test-json-object
                                               "uri" resource-uri))
                                    :session-id session-id)
                   (declare (ignore _))
                   (mcp-assert-equal 200 topic-status
                                     (format nil "resource read status for ~A" resource-uri))
                   (let* ((contents (hyperdoc::json-array-elements
                                     (gethash "contents"
                                              (gethash "result" topic-body))))
                          (topic-json (shasht:read-json
                                       (gethash "text" (first contents)))))
                     (mcp-assert-true
                      (hyperdoc::dmx-non-empty-string-p (gethash "title" topic-json))
                      (format nil "topic resource must expose title for ~A" resource-uri)))))
               (multiple-value-bind (tools-body tools-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 5
                                   "method" "tools/list")
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 tools-status "tools/list status")
                 (let ((tool-names
                         (mapcar (lambda (tool) (gethash "name" tool))
                                 (hyperdoc::json-array-elements
                                  (gethash "tools"
                                           (gethash "result" tools-body))))))
                   (dolist (tool-name '("validated_dmx_write_dry_run"
                                        "read_dmx_topicmap"
                                        "read_dmx_topic"
                                        "resolve_workspace_note"
                                        "append_workspace_note"
                                        "update_workspace_note"
                                        "upsert_workspace_topicmap_context"
                                        "remove_workspace_topic_from_topicmap"
                                        "repair_workspace_topic_assignment"
                                        "delete_workspace_note"
                                        "delete_workspace_topic"
                                        "upsert_workspace_topic_factory_snippet"
                                        "create_handover"))
                     (mcp-assert-true
                      (member tool-name tool-names :test #'string=)
                      (format nil "tools/list must include ~A" tool-name)))))
               (multiple-value-bind (topicmap-body topicmap-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 6
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "read_dmx_topicmap"
                                    "arguments" (mcp-test-json-object)))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 topicmap-status "read_dmx_topicmap status")
                 (let* ((tool-result (gethash "result" topicmap-body))
                        (structured (gethash "structuredContent" tool-result))
                        (projection (gethash "projection" structured))
                        (note-ids (mapcar (lambda (summary) (gethash "id" summary))
                                          (hyperdoc::json-array-elements
                                           (gethash "notes" projection)))))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "read_dmx_topicmap must not be flagged as error")
                   (mcp-assert-equal *dmx-mcp-smoke-workspace-topicmap-id*
                                     (gethash "topicmapId" structured)
                                     "read_dmx_topicmap topicmap id")
                   (mcp-assert-equal 2
                                     (gethash "noteCount" projection)
                                     "read_dmx_topicmap note count")
                   (mcp-assert-true
                    (member *dmx-mcp-smoke-primary-topic-id* note-ids :test #'eql)
                    "read_dmx_topicmap must include the primary note id")))
               (multiple-value-bind (topic-body topic-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 7
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "read_dmx_topic"
                                    "arguments"
                                    (mcp-test-json-object
                                     "topicId" *dmx-mcp-smoke-primary-topic-id*)))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 topic-status "read_dmx_topic status")
                 (let* ((tool-result (gethash "result" topic-body))
                        (structured (gethash "structuredContent" tool-result))
                        (topic (gethash "topic" structured)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "read_dmx_topic must not be flagged as error")
                   (mcp-assert-equal "DMX incident remediation for HyperDoc"
                                     (gethash "title" topic)
                                     "read_dmx_topic title")
                   (mcp-assert-equal "Live MCP smoke topic body"
                                     (gethash "text" topic)
                                     "read_dmx_topic text")))
               (multiple-value-bind (resolve-body resolve-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 8
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "resolve_workspace_note"
                                    "arguments"
                                    (mcp-test-json-object
                                     "noteKey" *dmx-mcp-smoke-primary-note-key*)))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 resolve-status "resolve_workspace_note status")
                 (let* ((tool-result (gethash "result" resolve-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "resolve_workspace_note must not be flagged as error")
                   (mcp-assert-equal *dmx-mcp-smoke-primary-topic-id*
                                     (gethash "existingTopicId" structured)
                                     "resolve_workspace_note existing topic id")
                   (mcp-assert-equal "update"
                                     (gethash "topicAction" structured)
                                     "resolve_workspace_note topic action")
                   (mcp-assert-equal "already-present"
                                     (gethash "topicmapAction" structured)
                                     "resolve_workspace_note topicmap action")))
               (multiple-value-bind (dry-run-body dry-run-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 9
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "append_workspace_note"
                                    "arguments"
                                    (mcp-test-json-object
                                     "title" "DMX incident remediation for HyperDoc"
                                     "text" "Updated body through dry-run."
                                     "noteKey" *dmx-mcp-smoke-primary-note-key*
                                     "dryRun" t)))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 dry-run-status "append_workspace_note dry-run status")
                 (let* ((tool-result (gethash "result" dry-run-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "append_workspace_note dry-run must not be flagged as error")
                   (mcp-assert-equal *dmx-mcp-smoke-primary-topic-id*
                                     (gethash "existing-topic-id" structured)
                                     "append_workspace_note dry-run existing topic id")
                   (mcp-assert-equal "update"
                                     (gethash "topic-action" structured)
                                     "append_workspace_note dry-run topic action")
                   (mcp-assert-equal "already-present"
                                     (gethash "topicmap-action" structured)
                                     "append_workspace_note dry-run topicmap action")))
               (multiple-value-bind (validated-body dry-run-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 10
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "validated_dmx_write_dry_run"
                                    "arguments"
                                    (mcp-test-json-object
                                     "writeKind" "topicmap_context_add"
                                     "topicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                                     "topicId" *dmx-mcp-smoke-primary-topic-id*
                                     "viewProps"
                                     (mcp-test-view-props :x 333 :y 444))))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 dry-run-status "validated_dmx_write_dry_run status")
                 (let* ((tool-result (gethash "result" validated-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "canonical long-form dry-run must not be flagged as error")
                   (mcp-assert-equal "topicmap_context_add"
                                     (gethash "writeKind" structured)
                                     "dry-run write kind")
                   (mcp-assert-equal 333
                                     (gethash "dmx.topicmaps.x"
                                              (gethash "normalizedPayload" structured))
                                     "dry-run normalized x")
                   (mcp-assert-equal "canonical"
                                     (gethash "validationStatus" structured)
                                     "dry-run validation status")))
               (multiple-value-bind (invalid-body invalid-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 11
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "validated_dmx_write_dry_run"
                                    "arguments"
                                    (mcp-test-json-object
                                     "writeKind" "topicmap_context_add"
                                     "topicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                                     "topicId" *dmx-mcp-smoke-primary-topic-id*
                                     "viewProps"
                                     (mcp-test-json-object
                                      "x" 1
                                      "y" 2
                                      "visibility" t
                                      "pinned" nil))))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 invalid-status "invalid dry-run status")
                 (let* ((tool-result (gethash "result" invalid-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true (gethash "isError" tool-result)
                                    "short-key dry-run must be flagged as error")
                   (mcp-assert-equal "validation_error"
                                     (gethash "status" structured)
                                     "short-key rejection status")
                   (mcp-assert-true
                    (member "x"
                            (hyperdoc::json-array-elements
                             (gethash "forbiddenShortKeys" structured))
                            :test #'string=)
                    "short-key rejection must name x")))
               (multiple-value-bind (handover-body handover-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 12
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "create_handover"
                                    "arguments"
                                    (mcp-test-json-object
                                     "title" "Codex/ChatGPT handover"
                                     "summary" "Promote the guarded DMX workspace write path."
                                     "requestedAction" "Read the workspace and continue from the new handover note."
                                     "artifacts" #("hyperdoc/mcp-server.lisp")
                                     "dryRun" nil)))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 handover-status "create_handover status")
                 (let* ((tool-result (gethash "result" handover-body))
                        (structured (gethash "structuredContent" tool-result))
                        (created-topic-id (gethash "topic-id" structured)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "create_handover live memory write must succeed")
                   (mcp-assert-true (integerp created-topic-id)
                                    "create_handover must return a topic id"))
                 (multiple-value-bind (workspace-after-body workspace-after-status __)
                     (mcp-test-call url
                                    (mcp-test-json-object
                                     "jsonrpc" "2.0"
                                     "id" 13
                                     "method" "resources/read"
                                     "params"
                                     (mcp-test-json-object
                                      "uri" "dmx://workspace/context-window"))
                                    :session-id session-id)
                   (declare (ignore __))
                   (mcp-assert-equal 200 workspace-after-status "workspace read after handover")
                   (let* ((contents (hyperdoc::json-array-elements
                                     (gethash "contents"
                                              (gethash "result" workspace-after-body))))
                          (workspace-json (shasht:read-json
                                           (gethash "text" (first contents)))))
                     (mcp-assert-equal 3
                                       (gethash "noteCount" workspace-json)
                                       "live create_handover must add a third note")
                     (mcp-assert-true
                      (find "Codex/ChatGPT handover"
                            (mapcar (lambda (summary) (gethash "title" summary))
                                    (hyperdoc::json-array-elements
                                     (gethash "notes" workspace-json)))
                            :test #'string=)
                      "new handover note must be readable from the workspace resource")))))))
      (hyperdoc::stop-dmx-mcp-server)))
  t)

(defun run-dmx-import-delete-and-remove-contract-smoke-test ()
  (let ((original (symbol-function 'drakma:http-request))
        (captured-delete-call nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method &allow-other-keys)
                   (setf captured-delete-call (list :url url :method method))
                   (values (make-string-input-stream "") 204 nil nil nil "No Content")))
           (let ((client (make-instance 'hyperdoc::http-dmx-import-client
                                        :base-url "https://dmx.ralfbarkow.ch"
                                        :authorization-header "Bearer test-token")))
             (hyperdoc::dmx-import-delete-topic client 907120)
             (mcp-assert-equal :delete
                               (getf captured-delete-call :method)
                               "HTTP topic delete must stay a DELETE")
             (mcp-assert-true
              (search "/core/topic/907120" (getf captured-delete-call :url))
              "HTTP topic delete must target /core/topic/<id>")
             (handler-case
                 (progn
                   (hyperdoc::dmx-import-remove-topic-from-topicmap
                    client
                    *dmx-mcp-smoke-workspace-topicmap-id*
                    *dmx-mcp-smoke-primary-topic-id*)
                   (error "Expected live HTTP topicmap unlink to stay unsupported"))
               (hyperdoc::dmx-import-unsupported-operation-error (condition)
                 (mcp-assert-true
                  (search "/topicmaps/919822/topic/907120"
                          (hyperdoc::dmx-import-unsupported-endpoint-of condition))
                  "Unsupported topicmap unlink must name the membership endpoint")
                 (mcp-assert-true
                  (search "DELETE"
                          (hyperdoc::fedwiki-dmx-import-message-of condition))
                 "Unsupported topicmap unlink must explain the missing DELETE proof")))))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-import-workspace-assignment-contract-smoke-test ()
  (let ((original (symbol-function 'drakma:http-request))
        (captured-assign-call nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method additional-headers content-type content content-length
                               &allow-other-keys)
                   (setf captured-assign-call
                         (list :url url
                               :method method
                               :headers additional-headers
                               :content-type content-type
                               :content content
                               :content-length content-length))
                   (values
                    (mcp-test-json-stream
                     (mcp-test-json-object
                      "id" 919815
                      "uri" ""
                      "typeUri" "dmx.workspaces.workspace"
                      "value" "context-window"))
                    200 nil nil nil "OK")))
           (let ((client (make-instance 'hyperdoc::http-dmx-import-client
                                        :base-url "https://dmx.ralfbarkow.ch"
                                        :authorization-header "Bearer test-token"
                                        :workspace-id 919815)))
             (hyperdoc::dmx-import-assign-topic-to-workspace client 919815 922464)
             (mcp-assert-equal :put
                               (getf captured-assign-call :method)
                               "HTTP workspace assignment must stay a PUT")
             (mcp-assert-true
              (search "/workspaces/919815/object/922464"
                      (getf captured-assign-call :url))
              "HTTP workspace assignment must target /workspaces/<workspace>/object/<topic>")
             (mcp-assert-equal "Bearer test-token"
                               (mcp-test-header-value
                                (getf captured-assign-call :headers)
                                "Authorization")
                               "HTTP workspace assignment must carry the configured auth header")
             (mcp-assert-equal "application/json"
                               (mcp-test-header-value
                                (getf captured-assign-call :headers)
                                "Accept")
                               "HTTP workspace assignment must ask for JSON readback")
             (mcp-assert-equal "dmx_workspace_id=919815"
                               (mcp-test-header-value
                                (getf captured-assign-call :headers)
                                "Cookie")
                               "HTTP workspace assignment must preserve the configured workspace cookie")
             (mcp-assert-equal ""
                               (getf captured-assign-call :content)
                               "HTTP workspace assignment must send an explicit empty body")
             (mcp-assert-equal 0
                               (getf captured-assign-call :content-length)
                               "HTTP workspace assignment must send an explicit zero Content-Length")
             (mcp-assert-equal nil
                               (getf captured-assign-call :content-type)
                               "HTTP workspace assignment must not let Drakma fall back to form media")
             (mcp-assert-true
              (null (mcp-test-header-value (getf captured-assign-call :headers)
                                           "Content-Type"))
              "HTTP workspace assignment must not duplicate Content-Type in additional headers")))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-import-explicit-basic-login-bootstrap-smoke-test ()
  (let ((original (symbol-function 'drakma:http-request))
        (captured-calls '()))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method additional-headers content-type content content-length
                               &allow-other-keys)
                   (push (list :url url
                               :method method
                               :headers additional-headers
                               :content-type content-type
                               :content content
                               :content-length content-length)
                         captured-calls)
                   (cond
                     ((search "/access-control/login" url)
                      (values nil
                              204
                              '(("Set-Cookie" . "JSESSIONID=session-123;Path=/;SameSite=Strict"))
                              nil nil "No Content"))
                     (t
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "id" 919815
                         "uri" ""
                         "typeUri" "dmx.workspaces.workspace"
                         "value" "context-window"))
                       200 nil nil nil "OK")))))
           (let ((client
                   (hyperdoc::make-http-dmx-import-client-from-explicit-auth
                    :base-url "https://dmx.ralfbarkow.ch"
                    :workspace-id 919815
                    :auth-mode :basic
                    :username "rgb"
                    :password "secret")))
             (hyperdoc::dmx-import-assign-topic-to-workspace client 919815 922464)
             (let ((calls (nreverse captured-calls)))
               (mcp-assert-equal 2
                                 (length calls)
                                 "Basic auth mode must bootstrap one DMX login before the workspace assignment PUT")
               (let ((login-call (first calls))
                     (assign-call (second calls)))
                 (mcp-assert-equal :post
                                   (getf login-call :method)
                                   "Username/password mode must bootstrap /access-control/login with POST")
                 (mcp-assert-true
                  (search "/access-control/login" (getf login-call :url))
                  "Username/password mode must hit the DMX login endpoint first")
                 (mcp-assert-true
                  (search "Basic " (mcp-test-header-value (getf login-call :headers)
                                                          "Authorization"))
                  "Username/password mode must send a Basic authorization header on login")
                 (mcp-assert-equal nil
                                   (mcp-test-header-value (getf login-call :headers)
                                                          "Cookie")
                                   "Login bootstrap must not send the workspace cookie")
                 (mcp-assert-equal ""
                                   (getf login-call :content)
                                   "Login bootstrap must send an explicit empty body")
                 (mcp-assert-equal 0
                                   (getf login-call :content-length)
                                   "Login bootstrap must send an explicit zero Content-Length")
                 (mcp-assert-equal nil
                                   (getf login-call :content-type)
                                   "Login bootstrap must not force a content type")
                 (mcp-assert-equal :put
                                   (getf assign-call :method)
                                   "Workspace assignment must remain a PUT after login bootstrap")
                 (mcp-assert-true
                 (search "/workspaces/919815/object/922464"
                         (getf assign-call :url))
                  "Workspace assignment must still target /workspaces/<workspace>/object/<topic>")
                 (mcp-assert-equal nil
                                   (mcp-test-header-value (getf assign-call :headers)
                                                          "Authorization")
                                   "Workspace assignment must switch to session-only auth after login bootstrap")
                 (mcp-assert-equal "JSESSIONID=session-123; dmx_workspace_id=919815"
                                   (mcp-test-header-value (getf assign-call :headers)
                                                          "Cookie")
                                   "Workspace assignment must combine JSESSIONID with the workspace cookie")
                 (mcp-assert-equal "JSESSIONID=session-123"
                                   (hyperdoc::dmx-import-session-cookie-of client)
                                   "The explicit-auth client must retain the bootstrapped JSESSIONID in memory")))))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-mcp-workspace-topic-lifecycle-smoke-test ()
  (let* ((port (mcp-test-port))
         (url (format nil "http://127.0.0.1:~D/mcp" port))
         (server (make-dmx-mcp-smoke-server))
         (client (hyperdoc::dmx-mcp-server-write-client server))
         (foreign-topic-id 921650))
    (mcp-test-seed-note client
                        foreign-topic-id
                        "Foreign workspace note"
                        "Foreign note body"
                        :uri (format nil "dmx://foreign/topic/~D" foreign-topic-id))
    (unwind-protect
         (progn
           (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
           (sleep 0.2)
           (let* ((session-id
                    (mcp-test-open-session url
                                           :id 201
                                           :client-name "hyperdoc-lifecycle-smoke"))
                  (definition (make-test-topic-factory-snippet-definition))
                  (snippet-id (hyperdoc::snippet-id-of definition))
                  (snippet-source-path (hyperdoc::source-path-of definition))
                  (snippet-related-page
                    (hyperdoc::related-hyperdoc-page-title-of definition))
                  (snippet-related-topic-id
                    (hyperdoc::related-topic-id-of definition))
                  (snippet-uri nil)
                  (snippet-topic-id nil))
             (multiple-value-bind (snippet-body snippet-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  202
                  "upsert_workspace_topic_factory_snippet"
                  (mcp-test-json-object
                   "snippetId" snippet-id
                   "snippetText" (hyperdoc::snippet-text-of definition)
                   "sourcePath" snippet-source-path
                   "relatedHyperdocPageTitle" snippet-related-page
                   "relatedTopicId" snippet-related-topic-id
                   "topicValue" "HyperDoc snippet twin smoke topic"
                   "viewProps" (mcp-test-view-props :x 410 :y 430)
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 snippet-status
                                 "upsert_workspace_topic_factory_snippet create status")
               (let* ((tool-result (gethash "result" snippet-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "topic-factory snippet upsert create must succeed")
                 (mcp-assert-equal "create"
                                   (gethash "topic-action" structured)
                                   "topic-factory snippet create must expose CREATE")
                 (mcp-assert-equal "add"
                                   (gethash "topicmap-action" structured)
                                   "topic-factory snippet create must expose ADD")
                 (setf snippet-uri (gethash "uri" structured)
                       snippet-topic-id (gethash "topic-id" structured))))
             (mcp-assert-true (integerp snippet-topic-id)
                              "Snippet upsert create must return a topic id")
             (mcp-assert-true
              (hyperdoc::dmx-import-topic-in-topicmap-p
               client
               *dmx-mcp-smoke-workspace-topicmap-id*
               snippet-topic-id)
              "Snippet upsert create must place the topic in the workspace topicmap")
             (multiple-value-bind (snippet-update-body snippet-update-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  203
                  "upsert_workspace_topic_factory_snippet"
                  (mcp-test-json-object
                   "snippetId" snippet-id
                   "snippetText" "Updated snippet text through MCP."
                   "sourcePath" snippet-source-path
                   "relatedHyperdocPageTitle" snippet-related-page
                   "relatedTopicId" snippet-related-topic-id
                   "topicValue" "HyperDoc snippet twin smoke topic"
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 snippet-update-status
                                 "upsert_workspace_topic_factory_snippet update status")
               (let* ((tool-result (gethash "result" snippet-update-body))
                      (structured (gethash "structuredContent" tool-result))
                      (updated-topic (hyperdoc::dmx-import-read-topic client snippet-topic-id)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "topic-factory snippet upsert update must succeed")
                 (mcp-assert-equal "update"
                                   (gethash "topic-action" structured)
                                   "topic-factory snippet update must expose UPDATE")
                 (mcp-assert-equal "already-present"
                                   (gethash "topicmap-action" structured)
                                   "topic-factory snippet update must preserve membership")
                 (mcp-assert-equal
                  "Updated snippet text through MCP."
                  (hyperdoc::dmx-json-child-value
                   updated-topic
                   hyperdoc::*dmx-topic-factory-snippet-text-type-uri*)
                  "topic-factory snippet update must replace the snippet text child")))
             (multiple-value-bind (placement-body placement-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  204
                  "upsert_workspace_topicmap_context"
                  (mcp-test-json-object
                   "topicId" *dmx-mcp-smoke-secondary-topic-id*
                   "viewProps" (mcp-test-view-props :x 333 :y 444)
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 placement-status
                                 "upsert_workspace_topicmap_context status")
               (let* ((tool-result (gethash "result" placement-body))
                      (structured (gethash "structuredContent" tool-result))
                      (view-props
                        (gethash (hyperdoc::memory-topicmap-membership-key
                                  *dmx-mcp-smoke-workspace-topicmap-id*
                                  *dmx-mcp-smoke-secondary-topic-id*)
                                 (hyperdoc::topicmap-memberships-of client))))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "upsert_workspace_topicmap_context must succeed")
                 (mcp-assert-equal "set-view-props"
                                   (gethash "topicmap-action" structured)
                                   "Existing membership must expose SET-VIEW-PROPS")
                 (mcp-assert-equal 333
                                   (gethash "dmx.topicmaps.x" view-props)
                                   "Live topicmap-context upsert must update x")))
             (multiple-value-bind (invalid-body invalid-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  205
                  "upsert_workspace_topicmap_context"
                  (mcp-test-json-object
                   "topicId" *dmx-mcp-smoke-secondary-topic-id*
                   "viewProps"
                   (mcp-test-json-object
                    "x" 1
                    "y" 2
                    "visibility" t
                    "pinned" nil)
                   "dryRun" t))
               (declare (ignore _))
               (mcp-assert-equal 200 invalid-status
                                 "Invalid topicmap-context dry-run status")
               (let* ((tool-result (gethash "result" invalid-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (gethash "isError" tool-result)
                  "Short-key topicmap-context upsert must be flagged as error")
                 (mcp-assert-equal "validation_error"
                                   (gethash "status" structured)
                                   "Short-key topicmap-context upsert must surface validation_error")
                 (mcp-assert-true
                  (member "x"
                          (hyperdoc::json-array-elements
                           (gethash "forbiddenShortKeys" structured))
                          :test #'string=)
                  "Short-key topicmap-context upsert must name x")))
             (multiple-value-bind (remove-body remove-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  206
                  "remove_workspace_topic_from_topicmap"
                  (mcp-test-json-object
                   "topicId" *dmx-mcp-smoke-secondary-topic-id*
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 remove-status
                                 "remove_workspace_topic_from_topicmap status")
               (let* ((tool-result (gethash "result" remove-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Memory-backed topicmap remove must succeed")
                 (mcp-assert-equal "remove"
                                   (gethash "topicmap-action" structured)
                                   "Memory-backed topicmap remove must expose REMOVE"))
               (mcp-assert-true
                (null (gethash (hyperdoc::memory-topicmap-membership-key
                                *dmx-mcp-smoke-workspace-topicmap-id*
                                *dmx-mcp-smoke-secondary-topic-id*)
                               (hyperdoc::topicmap-memberships-of client)))
                "Topicmap remove must drop the membership while keeping the topic"))
             (multiple-value-bind (foreign-delete-body foreign-delete-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  207
                  "delete_workspace_topic"
                  (mcp-test-json-object
                   "topicId" foreign-topic-id
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 foreign-delete-status
                                 "Foreign topic delete status")
               (let* ((tool-result (gethash "result" foreign-delete-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (gethash "isError" tool-result)
                  "Foreign topic delete must be ownership-blocked")
                 (mcp-assert-equal "ownership_error"
                                   (gethash "status" structured)
                                   "Foreign topic delete must surface ownership_error"))
               (mcp-assert-true
                (hyperdoc::dmx-import-read-topic client foreign-topic-id)
                "Ownership-blocked foreign topic delete must leave the topic intact"))
             (multiple-value-bind (note-delete-body note-delete-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  208
                  "delete_workspace_note"
                  (mcp-test-json-object
                   "noteKey" *dmx-mcp-smoke-primary-note-key*
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 note-delete-status
                                 "delete_workspace_note status")
               (let* ((tool-result (gethash "result" note-delete-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "delete_workspace_note must succeed for HyperDoc-owned notes")
                 (mcp-assert-equal "hard-delete"
                                   (gethash "delete-action" structured)
                                   "delete_workspace_note must expose hard-delete"))
               (mcp-assert-true
                (null (hyperdoc::dmx-import-read-topic
                       client
                       *dmx-mcp-smoke-primary-topic-id*))
                "delete_workspace_note must remove the owned note topic"))
             (multiple-value-bind (snippet-delete-body snippet-delete-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  209
                  "delete_workspace_topic"
                  (mcp-test-json-object
                   "topicId" snippet-topic-id
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 snippet-delete-status
                                 "delete_workspace_topic status")
               (let* ((tool-result (gethash "result" snippet-delete-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "delete_workspace_topic must succeed for HyperDoc-owned snippet twins")
                 (mcp-assert-equal snippet-uri
                                   (gethash "topic-uri" structured)
                                   "delete_workspace_topic must surface the deleted HyperDoc snippet URI"))
               (mcp-assert-true
                (null (hyperdoc::dmx-import-read-topic client snippet-topic-id))
                "delete_workspace_topic must remove the owned snippet twin"))))
      (hyperdoc::stop-dmx-mcp-server)))
  t)

(defun run-dmx-mcp-owned-topic-lifecycle-proof-smoke-test ()
  (let* ((port (mcp-test-port))
         (url (format nil "http://127.0.0.1:~D/mcp" port))
         (server (make-dmx-mcp-smoke-server))
         (client (hyperdoc::dmx-mcp-server-write-client server))
         (foreign-topic-id 921651)
         (owned-topic-id nil))
    (mcp-test-seed-note client
                        foreign-topic-id
                        "Foreign workspace lifecycle topic"
                        "Foreign topic body"
                        :uri (format nil "dmx://foreign/topic/~D" foreign-topic-id))
    (unwind-protect
         (progn
           (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
           (sleep 0.2)
           (let* ((session-id
                    (mcp-test-open-session url
                                           :id 301
                                           :client-name "hyperdoc-owned-lifecycle-smoke"))
                  (definition (make-test-topic-factory-snippet-definition))
                  (snippet-id (hyperdoc::snippet-id-of definition))
                  (snippet-source-path (hyperdoc::source-path-of definition))
                  (snippet-related-page
                    (hyperdoc::related-hyperdoc-page-title-of definition))
                  (snippet-related-topic-id
                    (hyperdoc::related-topic-id-of definition)))
             (multiple-value-bind (create-body create-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  302
                  "upsert_workspace_topic_factory_snippet"
                  (mcp-test-json-object
                   "snippetId" snippet-id
                   "snippetText" "Guarded lifecycle proof snippet text."
                   "sourcePath" snippet-source-path
                   "relatedHyperdocPageTitle" snippet-related-page
                   "relatedTopicId" snippet-related-topic-id
                   "topicValue" "Guarded lifecycle proof topic"
                   "viewProps" (mcp-test-view-props :x 520 :y 540)
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 create-status
                                 "Owned topic lifecycle proof create status")
               (let* ((tool-result (gethash "result" create-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Owned topic lifecycle proof create must succeed")
                 (mcp-assert-equal "create"
                                   (gethash "topic-action" structured)
                                   "Owned topic lifecycle proof must create the snippet twin")
                 (mcp-assert-equal "add"
                                   (gethash "topicmap-action" structured)
                                   "Owned topic lifecycle proof must add the topic to the workspace")
                  (setf owned-topic-id (gethash "topic-id" structured)))
             (mcp-assert-true (integerp owned-topic-id)
                              "Owned topic lifecycle proof must return a topic id")
             (mcp-assert-true
              (hyperdoc::dmx-import-topic-in-topicmap-p
               client
               *dmx-mcp-smoke-workspace-topicmap-id*
               owned-topic-id)
              "Owned topic lifecycle proof must place the topic in the workspace topicmap")
             (multiple-value-bind (remove-body remove-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  303
                  "remove_workspace_topic_from_topicmap"
                  (mcp-test-json-object
                   "topicId" owned-topic-id
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 remove-status
                                 "Owned topic lifecycle proof remove status")
               (let* ((tool-result (gethash "result" remove-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Owned topic lifecycle proof remove must succeed on the memory client")
                 (mcp-assert-equal "remove"
                                   (gethash "topicmap-action" structured)
                                   "Owned topic lifecycle proof remove must expose REMOVE")))
             (mcp-assert-true
              (null (gethash (hyperdoc::memory-topicmap-membership-key
                              *dmx-mcp-smoke-workspace-topicmap-id*
                              owned-topic-id)
                             (hyperdoc::topicmap-memberships-of client)))
              "Owned topic lifecycle proof remove must leave the topic alive but absent from the topicmap")
             (mcp-assert-true
              (hyperdoc::dmx-import-read-topic client owned-topic-id)
              "Owned topic lifecycle proof remove must not hard-delete the topic")
             (multiple-value-bind (delete-body delete-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  304
                  "delete_workspace_topic"
                  (mcp-test-json-object
                   "topicId" owned-topic-id
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 delete-status
                                 "Owned topic lifecycle proof delete status")
               (let* ((tool-result (gethash "result" delete-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Owned topic lifecycle proof delete must succeed")
                 (mcp-assert-equal "hard-delete"
                                   (gethash "delete-action" structured)
                                   "Owned topic lifecycle proof delete must expose HARD-DELETE")))
             (mcp-assert-true
              (null (hyperdoc::dmx-import-read-topic client owned-topic-id))
              "Owned topic lifecycle proof delete must remove the HyperDoc-owned topic")
             (multiple-value-bind (foreign-delete-body foreign-delete-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  305
                  "delete_workspace_topic"
                  (mcp-test-json-object
                   "topicId" foreign-topic-id
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 foreign-delete-status
                                 "Owned topic lifecycle proof foreign delete status")
               (let* ((tool-result (gethash "result" foreign-delete-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (gethash "isError" tool-result)
                  "Owned topic lifecycle proof must reject foreign hard delete")
                 (mcp-assert-equal "ownership_error"
                                   (gethash "status" structured)
                                   "Owned topic lifecycle proof foreign delete must surface ownership_error")))
             (mcp-assert-true
              (hyperdoc::dmx-import-read-topic client foreign-topic-id)
              "Owned topic lifecycle proof foreign delete must leave the foreign topic intact"))))
      (hyperdoc::stop-dmx-mcp-server)))
  t)

(defun run-dmx-mcp-workspace-assignment-repair-smoke-test ()
  (let* ((port (mcp-test-port))
         (url (format nil "http://127.0.0.1:~D/mcp" port))
         (server (make-dmx-mcp-smoke-server))
         (client (hyperdoc::dmx-mcp-server-write-client server))
         (owned-topic-id 921662)
         (foreign-topic-id 921663))
    (mcp-test-seed-note client
                        owned-topic-id
                        "Owned pre-fix note"
                        "Owned topic body"
                        :uri (hyperdoc::dmx-workspace-note-uri
                              :workspace-note
                              "owned-prefx-note"))
    (mcp-test-seed-note client
                        foreign-topic-id
                        "Foreign pre-fix note"
                        "Foreign topic body"
                        :uri (format nil "dmx://foreign/topic/~D" foreign-topic-id))
    (unwind-protect
         (progn
           (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
           (sleep 0.2)
           (let ((session-id
                   (mcp-test-open-session url
                                          :id 401
                                          :client-name "hyperdoc-assignment-repair-smoke")))
             (multiple-value-bind (dry-run-body dry-run-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  402
                  "validated_dmx_write_dry_run"
                  (mcp-test-json-object
                   "writeKind" "workspace_assignment_repair"
                   "topicId" owned-topic-id
                   "workspaceId" 919815
                   "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*))
               (declare (ignore _))
               (mcp-assert-equal 200 dry-run-status
                                 "workspace_assignment_repair dry-run status")
               (let* ((tool-result (gethash "result" dry-run-body))
                      (structured (gethash "structuredContent" tool-result))
                      (summary (gethash "summary" structured)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "workspace_assignment_repair dry-run must not be flagged as error")
                 (mcp-assert-equal "assign"
                                   (gethash "workspace-action" summary)
                                   "workspace_assignment_repair dry-run must expose ASSIGN")
                 (mcp-assert-equal 919815
                                   (gethash "workspace-id" summary)
                                   "workspace_assignment_repair dry-run must carry the target workspace id")))
             (mcp-assert-true
              (null (hyperdoc::dmx-import-read-topic-workspace client owned-topic-id))
              "Owned pre-fix note must start without a workspace assignment")
             (multiple-value-bind (repair-body repair-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  403
                  "repair_workspace_topic_assignment"
                  (mcp-test-json-object
                   "topicId" owned-topic-id
                   "workspaceId" 919815
                   "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 repair-status
                                 "repair_workspace_topic_assignment status")
               (let* ((tool-result (gethash "result" repair-body))
                      (structured (gethash "structuredContent" tool-result))
                      (workspace (hyperdoc::dmx-import-read-topic-workspace
                                  client
                                  owned-topic-id)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "repair_workspace_topic_assignment must succeed for HyperDoc-owned topics")
                 (mcp-assert-equal 919815
                                   (gethash "result-workspace-id" structured)
                                   "repair_workspace_topic_assignment must return the repaired workspace id")
                 (mcp-assert-equal 919815
                                   (hyperdoc::dmx-import-object-id workspace)
                                   "repair_workspace_topic_assignment must persist the workspace assignment")
                 (mcp-assert-equal t
                                   (gethash "result-in-topicmap-p" structured)
                                   "repair_workspace_topic_assignment must leave topicmap placement intact")))
             (multiple-value-bind (foreign-body foreign-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  404
                  "repair_workspace_topic_assignment"
                  (mcp-test-json-object
                   "topicId" foreign-topic-id
                   "workspaceId" 919815
                   "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 foreign-status
                                 "Foreign workspace assignment repair status")
               (let* ((tool-result (gethash "result" foreign-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (gethash "isError" tool-result)
                  "Foreign workspace assignment repair must be ownership-blocked")
                 (mcp-assert-equal "ownership_error"
                                   (gethash "status" structured)
                                   "Foreign workspace assignment repair must surface ownership_error")))
             (mcp-assert-true
             (null (hyperdoc::dmx-import-read-topic-workspace client foreign-topic-id))
              "Foreign topic must remain without a workspace assignment after rejection")))
      (hyperdoc::stop-dmx-mcp-server))
  t))

(defun run-dmx-mcp-smoke-tests ()
  (run-dmx-workspace-note-http-single-content-type-smoke-test)
  (run-dmx-import-delete-and-remove-contract-smoke-test)
  (run-dmx-import-workspace-assignment-contract-smoke-test)
  (run-dmx-import-explicit-basic-login-bootstrap-smoke-test)
  (run-dmx-mcp-smoke-test)
  (run-dmx-mcp-workspace-topic-lifecycle-smoke-test)
  (run-dmx-mcp-owned-topic-lifecycle-proof-smoke-test)
  (run-dmx-mcp-workspace-assignment-repair-smoke-test)
  (format t "~&DMX MCP smoke tests passed.~%")
  t)

(defun run-dmx-mcp-live-read-smoke-test ()
  (let* ((port (mcp-test-port))
         (url (format nil "http://127.0.0.1:~D/mcp" port))
         (server (make-dmx-mcp-live-server))
         (workspace-note-count nil)
         (primary-title nil)
         (secondary-title nil)
         (dry-run-status nil)
         (invalid-status-label nil)
         (invalid-forbidden-keys nil))
    (unwind-protect
         (progn
           (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
           (sleep 0.2)
           (multiple-value-bind (initialize-body initialize-status initialize-headers)
               (mcp-test-call
                url
                (mcp-test-json-object
                 "jsonrpc" "2.0"
                 "id" 101
                 "method" "initialize"
                 "params"
                 (mcp-test-json-object
                  "protocolVersion" "2025-03-26"
                  "clientInfo" (mcp-test-json-object
                                "name" "hyperdoc-live-smoke"
                                "version" "1.0"))))
             (mcp-assert-equal 200 initialize-status "live initialize status")
             (let ((session-id (mcp-test-response-header initialize-headers "Mcp-Session-Id")))
               (mcp-assert-true session-id "live initialize must return Mcp-Session-Id")
               (mcp-assert-equal "hyperdoc-dmx-mcp"
                                 (gethash "name"
                                          (gethash "serverInfo"
                                                   (gethash "result" initialize-body)))
                                 "live initialize serverInfo.name")
               (multiple-value-bind (_ notify-status __)
                   (mcp-test-notify-initialized url session-id)
                 (declare (ignore _ __))
                 (mcp-assert-equal 202 notify-status "live initialized notification status"))
               (multiple-value-bind (resources-body resources-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 102
                                   "method" "resources/list")
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 resources-status "live resources/list status")
                 (let* ((resources (hyperdoc::json-array-elements
                                    (gethash "resources"
                                             (gethash "result" resources-body))))
                        (resource-uris (mapcar (lambda (resource)
                                                 (gethash "uri" resource))
                                               resources)))
                   (dolist (resource-uri (list "dmx://workspace/context-window"
                                               "dmx://topic/907120"
                                               "dmx://topic/921464"))
                     (mcp-assert-true
                      (member resource-uri resource-uris :test #'string=)
                      (format nil "live resources/list must include ~A" resource-uri)))))
               (multiple-value-bind (workspace-body workspace-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 103
                                   "method" "resources/read"
                                   "params"
                                   (mcp-test-json-object
                                    "uri" "dmx://workspace/context-window"))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 workspace-status "live workspace read status")
                 (let* ((contents (hyperdoc::json-array-elements
                                   (gethash "contents"
                                            (gethash "result" workspace-body))))
                        (workspace-json (shasht:read-json
                                         (gethash "text" (first contents)))))
                   (mcp-assert-equal *dmx-mcp-smoke-workspace-topicmap-id*
                                     (gethash "topicmapId"
                                              (gethash "workspace" workspace-json))
                                     "live workspace summary topicmap id")
                   (mcp-assert-true
                    (integerp (gethash "noteCount" workspace-json))
                    "live workspace summary must expose noteCount")
                   (mcp-assert-true
                    (find *dmx-mcp-smoke-primary-topic-id*
                          (mapcar (lambda (summary) (gethash "id" summary))
                                  (hyperdoc::json-array-elements
                                   (gethash "notes" workspace-json))))
                    "live workspace summary must include topic 907120")
                   (setf workspace-note-count
                         (gethash "noteCount" workspace-json))))
               (dolist (resource-uri '("dmx://topic/907120" "dmx://topic/921464"))
                 (multiple-value-bind (topic-body topic-status _)
                     (mcp-test-call url
                                    (mcp-test-json-object
                                     "jsonrpc" "2.0"
                                     "id" 104
                                     "method" "resources/read"
                                     "params" (mcp-test-json-object
                                               "uri" resource-uri))
                                    :session-id session-id)
                   (declare (ignore _))
                   (mcp-assert-equal 200 topic-status
                                     (format nil "live resource read status for ~A" resource-uri))
                   (let* ((contents (hyperdoc::json-array-elements
                                     (gethash "contents"
                                              (gethash "result" topic-body))))
                          (topic-json (shasht:read-json
                                       (gethash "text" (first contents)))))
                     (mcp-assert-true
                      (hyperdoc::dmx-non-empty-string-p (gethash "title" topic-json))
                      (format nil "live topic resource must expose title for ~A" resource-uri))
                     (cond
                       ((string= resource-uri "dmx://topic/907120")
                        (setf primary-title (gethash "title" topic-json)))
                       ((string= resource-uri "dmx://topic/921464")
                        (setf secondary-title (gethash "title" topic-json))))))
               (multiple-value-bind (dry-run-body dry-run-http-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 105
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "validated_dmx_write_dry_run"
                                    "arguments"
                                    (mcp-test-json-object
                                     "writeKind" "topicmap_context_add"
                                     "topicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                                     "topicId" *dmx-mcp-smoke-primary-topic-id*
                                     "viewProps"
                                     (mcp-test-view-props :x 333 :y 444))))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 dry-run-http-status "live validated_dmx_write_dry_run status")
                 (let* ((tool-result (gethash "result" dry-run-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "live canonical dry-run must not be flagged as error")
                   (mcp-assert-equal 333
                                     (gethash "dmx.topicmaps.x"
                                              (gethash "normalizedPayload" structured))
                                     "live dry-run normalized x")
                   (mcp-assert-equal "canonical"
                                     (gethash "validationStatus" structured)
                                     "live dry-run validation status")
                   (setf dry-run-status
                         (gethash "validationStatus" structured))))
               (multiple-value-bind (invalid-body invalid-http-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 106
                                   "method" "tools/call"
                                   "params"
                                   (mcp-test-json-object
                                    "name" "validated_dmx_write_dry_run"
                                    "arguments"
                                    (mcp-test-json-object
                                     "writeKind" "topicmap_context_add"
                                     "topicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                                     "topicId" *dmx-mcp-smoke-primary-topic-id*
                                     "viewProps"
                                     (mcp-test-json-object
                                      "x" 1
                                      "y" 2
                                      "visibility" t
                                      "pinned" nil))))
                                  :session-id session-id)
                 (declare (ignore _))
                 (mcp-assert-equal 200 invalid-http-status "live invalid dry-run status")
                 (let* ((tool-result (gethash "result" invalid-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true (gethash "isError" tool-result)
                                    "live short-key dry-run must be flagged as error")
                   (mcp-assert-equal "validation_error"
                                     (gethash "status" structured)
                                     "live short-key rejection status")
                   (mcp-assert-true
                    (member "x"
                            (hyperdoc::json-array-elements
                             (gethash "forbiddenShortKeys" structured))
                            :test #'string=)
                    "live short-key rejection must name x")
                   (setf invalid-status-label
                         (gethash "status" structured)
                         invalid-forbidden-keys
                         (hyperdoc::json-array-elements
                          (gethash "forbiddenShortKeys" structured)))))))
      (hyperdoc::stop-dmx-mcp-server)))
  (format t
          "~&DMX MCP live read smoke passed. workspace-topicmap=~D note-count=~D topic907120=~S topic921464=~S dry-run-status=~A invalid-status=~A forbidden-short-keys=~S~%"
          *dmx-mcp-smoke-workspace-topicmap-id*
          workspace-note-count
          primary-title
          secondary-title
          dry-run-status
          invalid-status-label
          invalid-forbidden-keys)
  t)))
