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
                                        :base-url "https://dmx.ralfbarkow.ch")))
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

(defun run-dmx-mcp-smoke-tests ()
  (run-dmx-workspace-note-http-single-content-type-smoke-test)
  (run-dmx-mcp-smoke-test)
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
