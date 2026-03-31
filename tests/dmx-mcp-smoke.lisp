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

(defun mcp-json-array-strings (value)
  (mapcar #'identity (hyperdoc::json-array-elements value)))

(defun mcp-journal-event-types (events)
  (mapcar (lambda (event) (gethash "eventType" event))
          (hyperdoc::json-array-elements events)))

(defun mcp-last-json-array-element (value)
  (car (last (hyperdoc::json-array-elements value))))

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
                     ((and (eq method :get)
                           (search "/workspaces/object/907120" url))
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "id" 919815
                         "uri" ""
                         "typeUri" "dmx.workspaces.workspace"
                         "value" "context-window"))
                       200 nil nil nil "OK"))
                     ((and (eq method :get)
                           (search "/workspaces/object/921742" url))
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "id" 919815
                         "uri" ""
                         "typeUri" "dmx.workspaces.workspace"
                         "value" "context-window"))
                       200 nil nil nil "OK"))
                     ((and (eq method :get)
                           (search "/topicmaps/object/907120" url))
                      (values
                       (mcp-test-json-stream
                        (vector
                         (mcp-test-json-object
                          "id" 919822
                          "value" "context-window"
                          "assoc" (mcp-test-json-object "id" 1))))
                       200 nil nil nil "OK"))
                     ((and (eq method :get)
                           (search "/topicmaps/object/921742" url))
                      (values
                       (mcp-test-json-stream
                        (vector
                         (mcp-test-json-object
                          "id" 919822
                          "value" "context-window"
                          "assoc" (mcp-test-json-object "id" 2))))
                       200 nil nil nil "OK"))
                     ((and (eq method :get)
                           (search "/topicmaps/919822?children=true" url))
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "topic" (mcp-test-json-object
                                  "id" 919822
                                  "uri" ""
                                  "typeUri" "dmx.topicmaps.topicmap"
                                  "value" "context-window")
                         "viewProps" (mcp-test-json-object)
                         "topics"
                         (vector
                          (mcp-test-json-object
                           "id" 907120
                           "uri" "hyperdoc:mcp/workspace-note/dmx-incident-remediation-for-hyperdoc"
                           "typeUri" "dmx.notes.note"
                           "value" "DMX incident remediation for HyperDoc"
                           "children" (mcp-test-json-object)
                           "viewProps" (mcp-test-view-props :x 160 :y 120))
                          (mcp-test-json-object
                           "id" 921742
                           "uri" "hyperdoc:mcp/workspace-note/context-window-workspace-as-shared-blackboard"
                           "typeUri" "dmx.notes.note"
                           "value" "Context window workspace as shared blackboard"
                           "children" (mcp-test-json-object)
                           "viewProps" (mcp-test-view-props :x 160 :y 120)))
                         "assocs" #()))
                       200 nil nil nil "OK"))
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
                     ((and (eq method :get)
                           (search "/core/topic/921742?" url))
                      (values
                       (mcp-test-json-stream
                        (mcp-test-json-object
                         "id" 921742
                         "uri" "hyperdoc:mcp/workspace-note/context-window-workspace-as-shared-blackboard"
                         "typeUri" "dmx.notes.note"
                         "value" "Context window workspace as shared blackboard"
                         "children" (mcp-test-json-object
                                     "dmx.notes.title"
                                     "Context window workspace as shared blackboard"
                                     "dmx.notes.text"
                                     "Shared-blackboard intent and collaboration context.")))
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
                                        :workspace-id 919815))
                 (hyperdoc::*dmx-workspace-journal-suppressed-p* t))
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
              :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
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
                                        "read_workspace_journal"
                                        "read_topic_journal"
                                        "list_workspace_topic_revisions"
                                        "append_workspace_note"
                                        "update_workspace_note"
                                        "upsert_workspace_topicmap_context"
                                        "remove_workspace_topic_from_topicmap"
                                        "repair_workspace_topic_assignment"
                                        "delete_workspace_note"
                                        "delete_workspace_topic"
                                        "restore_workspace_topic_revision"
                                        "restore_workspace_note_revision"
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
                                     "noteKey" "codex-chatgpt-handover"
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
                                    "create_handover must return a topic id")
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
                        "new handover note must be readable from the workspace resource")))
                   (multiple-value-bind (handover-resolve-body handover-resolve-status __)
                       (mcp-test-call url
                                      (mcp-test-json-object
                                       "jsonrpc" "2.0"
                                       "id" 14
                                       "method" "tools/call"
                                       "params"
                                       (mcp-test-json-object
                                        "name" "resolve_workspace_note"
                                        "arguments"
                                        (mcp-test-json-object
                                         "noteKey" "codex-chatgpt-handover"
                                         "noteKind" "handover")))
                                      :session-id session-id)
                     (declare (ignore __))
                     (mcp-assert-equal 200 handover-resolve-status
                                       "resolve_workspace_note handover status")
                     (let* ((resolve-result (gethash "result" handover-resolve-body))
                            (resolve-structured
                              (gethash "structuredContent" resolve-result)))
                       (mcp-assert-true
                        (null (gethash "isError" resolve-result))
                        "resolve_workspace_note handover must not be flagged as error")
                       (mcp-assert-equal "handover"
                                         (gethash "noteKind" resolve-structured)
                                         "resolve_workspace_note handover kind")
                       (mcp-assert-equal created-topic-id
                                         (gethash "existingTopicId" resolve-structured)
                                         "resolve_workspace_note handover topic id")
                       (mcp-assert-equal "update"
                                         (gethash "topicAction" resolve-structured)
                                         "resolve_workspace_note handover topic action")
                       (mcp-assert-equal "already-present"
                                         (gethash "topicmapAction" resolve-structured)
                                         "resolve_workspace_note handover topicmap action"))))))))
      (hyperdoc::stop-dmx-mcp-server)))
  t)

(defun run-dmx-mcp-workspace-journal-smoke-test ()
  (let* ((port (mcp-test-port))
         (url (format nil "http://127.0.0.1:~D/mcp" port))
         (server (make-dmx-mcp-smoke-server))
         (client (hyperdoc::dmx-mcp-server-write-client server))
         (note-key "workspace-journal-smoke-note")
         (note-title "Workspace journal smoke note")
         (note-uri (hyperdoc::dmx-workspace-note-uri :workspace-note note-key))
         (created-topic-id nil)
         (created-subject-key nil)
         (updated-revision nil))
    (unwind-protect
         (progn
           (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
           (sleep 0.2)
           (let ((session-id
                   (mcp-test-open-session url
                                          :id 401
                                          :client-name "hyperdoc-workspace-journal-smoke")))
             (multiple-value-bind (dry-run-body dry-run-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  402
                  "append_workspace_note"
                  (mcp-test-json-object
                   "title" note-title
                   "text" "Initial journaled text."
                   "noteKey" note-key
                   "dryRun" t))
               (declare (ignore _))
               (mcp-assert-equal 200 dry-run-status
                                 "append_workspace_note dry-run journal status")
               (let* ((tool-result (gethash "result" dry-run-body))
                      (structured (gethash "structuredContent" tool-result))
                      (preview (gethash "journal-event-preview" structured)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "append_workspace_note dry-run for journal smoke must succeed")
                 (mcp-assert-equal
                  '("note-create" "add-to-topicmap")
                  (mcp-journal-event-types preview)
                  "Dry-run note create must preview note-create plus add-to-topicmap")))
             (multiple-value-bind (create-body create-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  403
                  "append_workspace_note"
                  (mcp-test-json-object
                   "title" note-title
                   "text" "Initial journaled text."
                   "noteKey" note-key
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 create-status
                                 "append_workspace_note live journal status")
               (let* ((tool-result (gethash "result" create-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "append_workspace_note live for journal smoke must succeed")
                 (setf created-topic-id (gethash "topic-id" structured)
                       created-subject-key (gethash "journal-subject-key" structured))
                 (mcp-assert-equal 2
                                   (gethash "journal-event-count" structured)
                                   "Live note create must emit create plus add journal events")))
             (mcp-assert-equal note-uri
                               created-subject-key
                               "Live note create must surface the stable journal subject key")
             (multiple-value-bind (read-body read-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  404
                  "read_topic_journal"
                  (mcp-test-json-object
                   "noteKey" note-key))
               (declare (ignore _))
               (mcp-assert-equal 200 read-status "read_topic_journal initial status")
               (let* ((tool-result (gethash "result" read-body))
                      (structured (gethash "structuredContent" tool-result))
                      (current-state (gethash "currentState" structured))
                      (revisions (gethash "revisions" structured)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "read_topic_journal initial must succeed")
                 (mcp-assert-equal 2
                                   (gethash "currentRevision" structured)
                                   "Initial note journal must expose two revisions")
                 (mcp-assert-equal note-uri
                                   (gethash "subjectKey" structured)
                                   "Initial note journal must keep the stable subject key")
                 (mcp-assert-equal note-title
                                   (gethash "value" (gethash "payload" current-state))
                                   "Replay to current state must preserve the note title")
                 (mcp-assert-equal
                  '("note-create" "add-to-topicmap")
                  (mapcar (lambda (revision) (gethash "eventType" revision))
                          (hyperdoc::json-array-elements revisions))
                  "Initial note journal must replay create and add revisions")))
             (multiple-value-bind (update-body update-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  405
                  "update_workspace_note"
                  (mcp-test-json-object
                   "topicId" created-topic-id
                   "text" "Updated journaled text."
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 update-status
                                 "update_workspace_note live journal status")
               (let* ((tool-result (gethash "result" update-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "update_workspace_note live for journal smoke must succeed")
                 (mcp-assert-equal 1
                                   (gethash "journal-event-count" structured)
                                   "Live note update must emit one note-update journal event")))
             (multiple-value-bind (revision-body revision-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  406
                  "list_workspace_topic_revisions"
                  (mcp-test-json-object
                   "noteKey" note-key))
               (declare (ignore _))
               (mcp-assert-equal 200 revision-status
                                 "list_workspace_topic_revisions note status")
               (let* ((tool-result (gethash "result" revision-body))
                      (structured (gethash "structuredContent" tool-result))
                      (revisions (hyperdoc::json-array-elements
                                  (gethash "revisions" structured)))
                      (event-types
                        (mapcar (lambda (revision) (gethash "eventType" revision))
                                revisions)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "list_workspace_topic_revisions for note must succeed")
                 (setf updated-revision (gethash "currentRevision" structured))
                 (mcp-assert-true (>= updated-revision 3)
                                  "Note revision list must advance after update")
                 (mcp-assert-equal
                  '("note-create" "add-to-topicmap")
                  (subseq event-types 0 2)
                  "Note revision list must start with create/add history")
                 (mcp-assert-equal "note-update"
                                   (car (last event-types))
                                   "Note revision list must end with note-update")))
             (hyperdoc::dmx-import-remove-topic-from-topicmap
              client
              *dmx-mcp-smoke-workspace-topicmap-id*
              created-topic-id)
             (mcp-assert-true
              (null (hyperdoc::dmx-import-topic-in-topicmap-p
                     client
                     *dmx-mcp-smoke-workspace-topicmap-id*
                     created-topic-id))
              "Out-of-band topicmap removal must remove the live membership before reconciliation")
             (multiple-value-bind (reconciled-body reconciled-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  407
                  "read_topic_journal"
                  (mcp-test-json-object
                   "noteKey" note-key
                   "reconcile" t))
               (declare (ignore _))
               (mcp-assert-equal 200 reconciled-status
                                 "read_topic_journal reconciled status")
               (let* ((tool-result (gethash "result" reconciled-body))
                      (structured (gethash "structuredContent" tool-result))
                      (events (gethash "events" structured))
                      (last-event (mcp-last-json-array-element events)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Reconciled note journal must succeed")
                 (mcp-assert-equal "remove-from-topicmap"
                                   (gethash "eventType" last-event)
                                   "Out-of-band topicmap removal must synthesize remove-from-topicmap")
                 (mcp-assert-equal "synthesized-from-diff"
                                   (gethash "observationKind" last-event)
                                   "Out-of-band topicmap removal must be marked synthesized-from-diff")))
             (multiple-value-bind (restore-membership-body restore-membership-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  408
                  "restore_workspace_note_revision"
                  (mcp-test-json-object
                   "noteKey" note-key
                   "revision" updated-revision
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 restore-membership-status
                                 "restore_workspace_note_revision membership status")
               (let* ((tool-result (gethash "result" restore-membership-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Membership restore must succeed")
                 (mcp-assert-equal "restored"
                                   (gethash "status" structured)
                                   "Membership restore must report restored")
                 (mcp-assert-equal
                  '("restore-topicmap-membership")
                  (mcp-json-array-strings (gethash "actions" structured))
                  "Membership restore must explicitly report restore-topicmap-membership")))
             (mcp-assert-true
              (hyperdoc::dmx-import-topic-in-topicmap-p
               client
               *dmx-mcp-smoke-workspace-topicmap-id*
               created-topic-id)
              "Membership restore must reattach the note to the workspace topicmap")
             (multiple-value-bind (delete-body delete-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  409
                  "delete_workspace_note"
                  (mcp-test-json-object
                   "noteKey" note-key
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 delete-status
                                 "delete_workspace_note journal status")
               (let* ((tool-result (gethash "result" delete-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "delete_workspace_note for journal smoke must succeed")
                 (mcp-assert-equal 2
                                   (gethash "journal-event-count" structured)
                                   "Live note delete must emit archive plus delete journal events")))
             (mcp-assert-true
              (null (hyperdoc::dmx-import-find-existing-topic client note-uri))
              "Live note delete must remove the note topic while preserving the journal stream")
             (multiple-value-bind (restore-note-body restore-note-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  410
                  "restore_workspace_note_revision"
                  (mcp-test-json-object
                   "noteKey" note-key
                   "dryRun" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 restore-note-status
                                 "restore_workspace_note_revision delete status")
               (let* ((tool-result (gethash "result" restore-note-body))
                      (structured (gethash "structuredContent" tool-result)))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Restore after delete must succeed for HyperDoc-owned notes")
                 (mcp-assert-equal "restored"
                                   (gethash "status" structured)
                                   "Restore after delete must report restored")
                 (mcp-assert-equal
                  '("create-topic" "restore-topicmap-membership")
                  (mcp-json-array-strings (gethash "actions" structured))
                  "Restore after delete must explicitly recreate the topic and reattach membership")))
             (let ((restored-topic (hyperdoc::dmx-import-find-existing-topic client note-uri)))
               (mcp-assert-true restored-topic
                                "Restore after delete must recreate the note topic")
               (mcp-assert-true
                (hyperdoc::dmx-import-topic-in-topicmap-p
                 client
                 *dmx-mcp-smoke-workspace-topicmap-id*
                 (hyperdoc::dmx-import-object-id restored-topic))
                "Restore after delete must return the note to the workspace topicmap"))
             (multiple-value-bind (final-read-body final-read-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  411
                  "read_topic_journal"
                  (mcp-test-json-object
                   "noteKey" note-key
                   "reconcile" t))
               (declare (ignore _))
               (mcp-assert-equal 200 final-read-status
                                 "read_topic_journal final status")
               (let* ((tool-result (gethash "result" final-read-body))
                      (structured (gethash "structuredContent" tool-result))
                      (events (hyperdoc::json-array-elements
                               (gethash "events" structured))))
                 (mcp-assert-true
                 (null (gethash "isError" tool-result))
                 "Final note journal read must succeed")
                 (mcp-assert-equal
                  '("note-archive"
                    "note-delete"
                    "restore-topic"
                    "restore-topicmap-membership")
                  (mapcar (lambda (event) (gethash "eventType" event))
                          (subseq events (- (length events) 4)))
                  "Delete plus restore must append explicit archive, delete, and restore events to the journal")))
             (multiple-value-bind (workspace-body workspace-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  412
                  "read_workspace_journal"
                  (mcp-test-json-object
                   "reconcile" t))
               (declare (ignore _))
               (mcp-assert-equal 200 workspace-status
                                 "read_workspace_journal status")
               (let* ((tool-result (gethash "result" workspace-body))
                      (structured (gethash "structuredContent" tool-result))
                      (backend-contract (gethash "backendHistoryContract" structured))
                      (streams (hyperdoc::json-array-elements
                                (gethash "streams" structured))))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "read_workspace_journal must succeed")
                 (mcp-assert-equal "not-proven"
                                   (gethash "status" backend-contract)
                                   "Workspace journal must disclose the unproven backend history contract")
                 (mcp-assert-true
                 (find created-subject-key
                       streams
                       :test #'string=
                       :key (lambda (stream) (gethash "subjectKey" stream)))
                  "Workspace journal overview must include the created note stream")))))
      (hyperdoc::stop-dmx-mcp-server)))
  t)

(defun run-dmx-workspace-journal-foreign-restore-guardrail-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 940000))
         (topic-uri "dmx://foreign/workspace-topic/940100")
         (topic-id nil))
    (let ((topic
            (hyperdoc::dmx-import-create-topic
             client
             (list :uri topic-uri
                   :external-key topic-uri
                   :type-uri "dmx.notes.note"
                   :value "Foreign workspace topic"
                   :children
                   (mcp-test-json-object
                    "dmx.notes.title" "Foreign workspace topic"
                    "dmx.notes.text" "Out-of-band foreign state")))))
      (setf topic-id (hyperdoc::dmx-import-object-id topic))
      (hyperdoc::dmx-import-add-topic-to-topicmap
       client
       *dmx-mcp-smoke-workspace-topicmap-id*
       topic-id
       (mcp-test-view-props :x 610 :y 620))
      (let* ((initial-journal
               (hyperdoc::read-dmx-topic-journal
               :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
               :client client
               :topic-id topic-id
               :reconcile t))
             (events (gethash "events" initial-journal)))
        (mcp-assert-equal
         '("create-topic" "add-to-topicmap")
         (mcp-journal-event-types events)
         "Foreign out-of-band create must be synthesized into create-topic plus add-to-topicmap")))
    (hyperdoc::dmx-import-delete-topic client topic-id)
    (let* ((deleted-journal
             (hyperdoc::read-dmx-topic-journal
              :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
              :client client
              :subject-key topic-uri
              :reconcile t))
           (all-events (hyperdoc::json-array-elements
                        (gethash "events" deleted-journal)))
           (delete-events (subseq all-events (- (length all-events) 2)))
           (restore-result
             (hyperdoc::restore-dmx-workspace-topic-revision
              :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
              :client client
              :subject-key topic-uri
              :dry-run nil)))
      (mcp-assert-equal '("archive-topic" "delete-topic")
                        (mapcar (lambda (event) (gethash "eventType" event))
                                delete-events)
                        "Foreign out-of-band delete must be synthesized into archive-topic plus delete-topic")
      (dolist (event delete-events)
        (mcp-assert-equal "synthesized-from-diff"
                          (gethash "observationKind" event)
                          "Foreign out-of-band delete events must be marked synthesized-from-diff"))
      (mcp-assert-equal "repair_candidate"
                        (gethash "status" restore-result)
                        "Foreign absent topic restore must stop at a repair candidate")
      (mcp-assert-true
       (search "will not hard-recreate it blindly."
               (gethash "reason" (gethash "repairCandidate" restore-result))
               :test #'char=)
       "Foreign absent topic restore must explain the ownership guardrail")
      (mcp-assert-true
       (null (hyperdoc::dmx-import-find-existing-topic client topic-uri))
       "Foreign absent topic restore must not recreate the topic automatically")))
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
  (run-dmx-mcp-workspace-journal-smoke-test)
  (run-dmx-mcp-owned-topic-lifecycle-proof-smoke-test)
  (run-dmx-workspace-journal-foreign-restore-guardrail-smoke-test)
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
