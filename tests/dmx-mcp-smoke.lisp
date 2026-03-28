;;;; Smoke tests for the DMX MCP server

(in-package :hyperdoc/tests)

(defparameter *dmx-mcp-smoke-workspace-topicmap-id* 919822)
(defparameter *dmx-mcp-smoke-primary-topic-id* 907120)
(defparameter *dmx-mcp-smoke-secondary-topic-id* 921494)

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

(defun mcp-test-seed-note (client id title text &key (topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*) (x 160) (y 120))
  (let ((topic (hyperdoc::dmx-import-create-topic
                client
                (list* :id id
                       (hyperdoc::dmx-workspace-note-payload
                        title
                        text
                        (format nil "hyperdoc:mcp/test/note/~D" id))))))
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
                        "Live MCP smoke topic body")
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
                                        "append_workspace_note"
                                        "update_workspace_note"
                                        "create_handover"))
                     (mcp-assert-true
                      (member tool-name tool-names :test #'string=)
                      (format nil "tools/list must include ~A" tool-name)))))
               (multiple-value-bind (dry-run-body dry-run-status _)
                   (mcp-test-call url
                                  (mcp-test-json-object
                                   "jsonrpc" "2.0"
                                   "id" 6
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
                 (let* ((tool-result (gethash "result" dry-run-body))
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
                                   "id" 7
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
                                   "id" 8
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
                                     "id" 9
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
  (run-dmx-mcp-smoke-test)
  (format t "~&DMX MCP smoke tests passed.~%")
  t)
