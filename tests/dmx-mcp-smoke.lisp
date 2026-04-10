;;;; Smoke tests for the DMX MCP server

(in-package :hyperdoc/tests)

(export (list (intern "RUN-DMX-MCP-SMOKE-TESTS" :hyperdoc/tests))
        :hyperdoc/tests)

(defparameter *dmx-mcp-smoke-workspace-topicmap-id* 919822)
(defparameter *dmx-mcp-smoke-workspace-id* 919815)
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

(defun mcp-json-null-p (value)
  (or (null value)
      (and (hash-table-p value)
           (zerop (hash-table-count value)))))

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

(defun ensure-dmx-mcp-smoke-runtime-loaded ()
  (unless (and (fboundp 'hyperdoc::make-dmx-mcp-server)
               (fboundp 'hyperdoc::serve-dmx-mcp-server))
    (load (merge-pathnames "hyperdoc/mcp-server.lisp"
                           (uiop:getcwd)))))

(defun mcp-json-array-strings (value)
  (mapcar #'identity (hyperdoc::json-array-elements value)))

(defun mcp-journal-event-types (events)
  (mapcar (lambda (event) (gethash "eventType" event))
          (hyperdoc::json-array-elements events)))

(defun mcp-last-json-array-element (value)
  (car (last (hyperdoc::json-array-elements value))))

(defun mcp-json-array-find-keyed-object (value key)
  (find key
        (hyperdoc::json-array-elements value)
        :key (lambda (object) (gethash "key" object))
        :test #'string=))

(defun mcp-signal-journal-preflight-http-401-with-header-evidence (topic-id)
  (let ((path (hyperdoc::dmx-topic-update-path topic-id))
        (url (format nil "https://dmx.ralfbarkow.ch/core/topic/~D" topic-id)))
    (error 'hyperdoc::dmx-import-http-error
           :message (format nil "DMX import HTTP failure 401 for ~A" url)
           :url url
           :status-code 401
           :response-body "{\"error\":\"journal-preflight-unauthorized\"}"
           :evidence
           (list :method :put
                 :path path
                 :auth-mode-summary "anonymous"
                 :authorization-scheme nil
                 :bootstrap-ran-p nil
                 :request-content-type "application/json; charset=utf-8"
                 :response-status-code 401
                 :response-reason-phrase "Unauthorized"
                 :response-body "{\"error\":\"journal-preflight-unauthorized\"}"
                 :response-headers
                 (list (cons "Content-Type" "application/json; charset=utf-8")
                       (cons "WWW-Authenticate" "Bearer realm=\"dmx\""))))))

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

(defclass mcp-journal-repair-observing-http-dmx-import-client
    (hyperdoc::memory-dmx-import-client
     hyperdoc::http-dmx-import-client)
  ((journal-create-observations
    :accessor mcp-journal-create-observations-of
    :initarg :journal-create-observations
    :initform '())
   (journal-update-topic-ids
    :accessor mcp-journal-update-topic-ids-of
    :initarg :journal-update-topic-ids
    :initform '())
   (journal-delete-topic-ids
    :accessor mcp-journal-delete-topic-ids-of
    :initarg :journal-delete-topic-ids
    :initform '())
   (journal-placement-observations
   :accessor mcp-journal-placement-observations-of
   :initarg :journal-placement-observations
   :initform '())
   (fail-journal-hidden-placement-p
    :accessor mcp-fail-journal-hidden-placement-p-of
    :initarg :fail-journal-hidden-placement-p
    :initform nil)
   (fail-journal-replacement-create-p
    :accessor mcp-fail-journal-replacement-create-p-of
    :initarg :fail-journal-replacement-create-p
    :initform nil)))

(defun mcp-journal-uri-p (value)
  (and (stringp value)
       (hyperdoc::dmx-string-prefix-p
        hyperdoc::*hyperdoc-workspace-journal-uri-prefix*
        value)))

(defun mcp-topic-external-key-by-id (client topic-id)
  (loop for external-key being the hash-keys of (hyperdoc::topics-by-external-key-of client)
          using (hash-value topic)
        when (eql topic-id (hyperdoc::dmx-import-object-id topic))
          do (return external-key)))

(defun mcp-journal-topic-id-p (client topic-id)
  (mcp-journal-uri-p
   (mcp-topic-external-key-by-id client topic-id)))

(defun mcp-hidden-journal-view-props-p (view-props)
  (hyperdoc::dmx-workspace-journal-hidden-view-props-p view-props))

(defun mcp-clear-journal-repair-observations (client)
  (setf (mcp-journal-create-observations-of client) '()
        (mcp-journal-update-topic-ids-of client) '()
        (mcp-journal-delete-topic-ids-of client) '()
        (mcp-journal-placement-observations-of client) '()))

(defmethod hyperdoc::dmx-import-create-topic
    ((client mcp-journal-repair-observing-http-dmx-import-client)
     payload)
  (let* ((external-key (or (getf payload :external-key)
                           (getf payload :uri)))
         (journal-p (mcp-journal-uri-p external-key))
         (workspace-id
           (hyperdoc::effective-http-dmx-import-workspace-id client))
         (_failure
           (when (and journal-p
                      (mcp-fail-journal-replacement-create-p-of client))
             (error "Simulated MCP journal replacement create failure")))
         (topic (call-next-method)))
    (declare (ignore _failure))
    (when journal-p
      (push (list :topic-id (hyperdoc::dmx-import-object-id topic)
                  :external-key external-key
                  :workspace-id workspace-id)
            (mcp-journal-create-observations-of client)))
    topic))

(defmethod hyperdoc::dmx-import-update-topic
    ((client mcp-journal-repair-observing-http-dmx-import-client)
     existing-topic
     payload)
  (declare (ignore payload))
  (when (mcp-journal-uri-p
         (or (hyperdoc::dmx-json-object-value existing-topic "uri")
             (getf existing-topic :external-key)
             (getf existing-topic :uri)))
    (push (hyperdoc::dmx-import-object-id existing-topic)
          (mcp-journal-update-topic-ids-of client)))
  (call-next-method))

(defmethod hyperdoc::dmx-import-delete-topic
    ((client mcp-journal-repair-observing-http-dmx-import-client)
     topic-id)
  (when (mcp-journal-topic-id-p client topic-id)
    (push topic-id (mcp-journal-delete-topic-ids-of client)))
  (call-next-method))

(defmethod hyperdoc::dmx-import-add-topic-to-topicmap
    ((client mcp-journal-repair-observing-http-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (when (mcp-journal-topic-id-p client topic-id)
    (push (list :action :add-to-topicmap
                :topicmap-id topicmap-id
                :topic-id topic-id
                :view-props view-props)
          (mcp-journal-placement-observations-of client))
    (when (mcp-fail-journal-hidden-placement-p-of client)
      (error "Simulated MCP journal hidden placement failure")))
  (call-next-method))

(defmethod hyperdoc::dmx-import-set-topic-view-props
    ((client mcp-journal-repair-observing-http-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (when (mcp-journal-topic-id-p client topic-id)
    (push (list :action :set-view-props
                :topicmap-id topicmap-id
                :topic-id topic-id
                :view-props view-props)
          (mcp-journal-placement-observations-of client))
    (when (mcp-fail-journal-hidden-placement-p-of client)
      (error "Simulated MCP journal hidden placement failure")))
  (call-next-method))

(defun mcp-test-make-journal-stream (subject-key)
  (hyperdoc::dmx-workspace-journal-make-base-stream
   subject-key
   "uri"
   subject-key
   *dmx-mcp-smoke-workspace-topicmap-id*
   :subject-uri subject-key
   :subject-kind "workspace-annotation"
   :ownership-class "hyperdoc-workspace-annotation"))

(defun mcp-test-seed-journal-companion
    (client id subject-key
     &key workspace-id
          (topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*)
          (view-props (mcp-test-view-props :x 40 :y 60 :visibility t :pinned nil)))
  (let* ((stream (mcp-test-make-journal-stream subject-key))
         (topic (hyperdoc::dmx-import-create-topic
                 client
                 (list* :id id
                        (hyperdoc::dmx-workspace-note-payload
                         (hyperdoc::dmx-workspace-journal-visible-title stream)
                         (hyperdoc::encode-json-string stream)
                         (hyperdoc::dmx-workspace-journal-note-uri subject-key))))))
    (when workspace-id
      (hyperdoc::dmx-import-assign-topic-to-workspace client workspace-id id))
    (when topicmap-id
      (hyperdoc::dmx-import-add-topic-to-topicmap
       client
       topicmap-id
       id
       view-props))
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

(defun make-dmx-mcp-journal-companion-repair-server
    (&key (fail-hidden-placement-p nil)
          (fail-replacement-create-p nil)
          (authorization-header "Bearer smoke-token"))
  (ensure-dmx-mcp-smoke-runtime-loaded)
  (let ((client
          (make-instance 'mcp-journal-repair-observing-http-dmx-import-client
                         :base-url "https://dmx.ralfbarkow.ch"
                         :authorization-header authorization-header
                         :workspace-id *dmx-mcp-smoke-workspace-id*
                         :next-topic-id 933000
                         :fail-journal-replacement-create-p
                         fail-replacement-create-p
                         :fail-journal-hidden-placement-p
                         fail-hidden-placement-p)))
    (values
     (hyperdoc::make-dmx-mcp-server
      :read-client client
      :write-client client
      :workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*
      :known-topic-ids '()
      :bearer-token nil
      :allowed-origins nil
      :live-writes-enabled-p t
      :sessions (make-hash-table :test #'equal)
      :log-stream nil)
     client)))

(defun make-dmx-mcp-annotation-smoke-server ()
  (let* ((client (make-instance 'compatibility-storage-http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :workspace-id *dmx-annotations-smoke-workspace-id*
                                :next-topic-id 931000))
         (annotation (make-test-dock-annotation
                      :note "Saved annotation for MCP continuation smoke"))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            annotation
            :workspace-topicmap-id *dmx-annotations-smoke-workspace-topicmap-id*
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :client client
            :dry-run nil))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of persisted)))
    (values
     (hyperdoc::make-dmx-mcp-server
      :read-client client
      :write-client client
      :workspace-topicmap-id *dmx-annotations-smoke-workspace-topicmap-id*
      :known-topic-ids (list topic-id)
      :bearer-token nil
      :allowed-origins nil
      :live-writes-enabled-p t
     :sessions (make-hash-table :test #'equal)
     :log-stream nil)
     topic-id)))

(defun make-dmx-mcp-annotation-auth-blocked-server ()
  (let* ((topics (make-hash-table :test #'equal))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (create-client
           (make-instance 'compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :authorization-header "Bearer test-token"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 931100))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Saved annotation for MCP auth-blocked continuation smoke")
            :workspace-topicmap-id *dmx-annotations-smoke-workspace-topicmap-id*
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :client create-client
            :dry-run nil))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of persisted))
         (journal-summary
           (workspace-annotation-smoke-journal-summary create-client persisted))
         (journal-topic-id (getf journal-summary :existing-topic-id))
         (blocked-client
           (make-instance
            'journal-preflight-auth-blocked-compatibility-storage-http-dmx-import-client
            :base-url "https://dmx.ralfbarkow.ch"
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :topics-by-external-key topics
            :topicmap-memberships topicmap-memberships
            :workspace-assignments workspace-assignments
            :next-topic-id 931101)))
    (remhash topic-id workspace-assignments)
    (values
     (hyperdoc::make-dmx-mcp-server
      :read-client blocked-client
      :write-client blocked-client
      :workspace-topicmap-id *dmx-annotations-smoke-workspace-topicmap-id*
      :known-topic-ids (list topic-id)
      :bearer-token nil
      :allowed-origins nil
      :live-writes-enabled-p t
      :sessions (make-hash-table :test #'equal)
      :log-stream nil)
     topic-id
     journal-topic-id)))

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
	                                        "continue_workspace_annotation"
	                                        "repair_workspace_journal_companion"
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
             (multiple-value-bind (stored-body stored-status _)
                 (mcp-test-call-tool
                  url
                  session-id
                  4071
                  "read_topic_journal"
                  (mcp-test-json-object
                   "noteKey" note-key
                   "reconcile" nil))
               (declare (ignore _))
               (mcp-assert-equal 200 stored-status
                                 "read_topic_journal stored status")
               (let* ((tool-result (gethash "result" stored-body))
                      (structured (gethash "structuredContent" tool-result))
                      (current-state (gethash "currentState" structured))
                      (events (hyperdoc::json-array-elements
                               (gethash "events" structured))))
                 (mcp-assert-true
                  (null (gethash "isError" tool-result))
                  "Stored note journal must succeed after a reconciled read")
                 (mcp-assert-equal updated-revision
                                   (gethash "currentRevision" structured)
                                   "Reconciled read must not persist synthesized events")
                 (mcp-assert-true
                  (gethash "inTopicmap" current-state)
                  "Stored journal state must remain unchanged for reconcile=false")
                 (mcp-assert-equal
                  "note-update"
                  (gethash "eventType" (car (last events)))
                  "Stored journal stream must still end at the explicit note-update event")))
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
         "Foreign out-of-band create must be synthesized into create-topic plus add-to-topicmap"))
      ;; Reconcile-on-read is intentionally side-effect free. Materialize a
      ;; durable baseline through the explicit journal-write preflight before
      ;; exercising delete/restore guardrails.
      (let* ((live-topic (hyperdoc::dmx-import-read-topic client topic-id))
             (metadata
               (hyperdoc::dmx-workspace-journal-subject-metadata-from-topic
                live-topic))
             (lookup (gethash "subjectLookup" metadata)))
        (hyperdoc::dmx-workspace-journal-prepare-transition
         client
         (gethash "subjectKey" metadata)
         (gethash "kind" lookup)
         (gethash "value" lookup)
         *dmx-mcp-smoke-workspace-topicmap-id*
         :subject-uri (gethash "subjectUri" metadata)
         :subject-kind (gethash "subjectKind" metadata)
         :ownership-class (gethash "ownershipClass" metadata)
         :note-key (gethash "noteKey" metadata)
         :note-kind (gethash "noteKind" metadata))))
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

(defun run-dmx-workspace-journal-assignment-repair-nonrecursive-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 942000))
         (workspace-topicmap-id *dmx-mcp-smoke-workspace-topicmap-id*)
         (subject-key "hyperdoc:mcp/workspace-annotation/nonrecursive-repair-smoke")
         (journal-uri (hyperdoc::dmx-workspace-journal-note-uri subject-key))
         (nested-uri (hyperdoc::dmx-workspace-journal-note-uri journal-uri))
         (journal-topic
           (hyperdoc::dmx-import-create-topic
            client
            (hyperdoc::dmx-workspace-note-payload
             "Workspace journal repair smoke"
             "{\"journalOwner\":\"hyperdoc\",\"schemaVersion\":1}"
             journal-uri)))
         (journal-topic-id (hyperdoc::dmx-import-object-id journal-topic))
         (topic-count-before
           (hash-table-count (hyperdoc::topics-by-external-key-of client)))
         (result
           (hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair
            journal-topic-id
            :workspace-id 919815
            :workspace-topicmap-id workspace-topicmap-id
            :client client
            :dry-run nil))
         (topic-count-after
           (hash-table-count (hyperdoc::topics-by-external-key-of client))))
    (mcp-assert-equal 919815
                      (getf result :result-workspace-id)
                      "Workspace-journal assignment repair must assign the target workspace")
    (mcp-assert-true
     (null (getf result :journal-event-preview))
     "Workspace-journal assignment repair must suppress recursive journal previews")
    (mcp-assert-equal topic-count-before
                      topic-count-after
                      "Workspace-journal assignment repair must not create nested companion topics")
    (mcp-assert-true
     (null (hyperdoc::dmx-import-find-existing-topic client nested-uri))
     "Workspace-journal assignment repair must not create a nested workspace-journal companion")
    t))

(defun run-dmx-mcp-workspace-journal-companion-repair-smoke-test ()
  (multiple-value-bind (server client)
      (make-dmx-mcp-journal-companion-repair-server)
    (let* ((port (mcp-test-port))
           (url (format nil "http://127.0.0.1:~D/mcp" port))
           (nonjournal-topic-id 921680)
           (assigned-topic-id 921681)
           (stale-topic-id 921682)
           (assigned-subject-key
             "hyperdoc:mcp/workspace-annotation/mcp-journal-companion-assigned")
           (stale-subject-key
             "hyperdoc:mcp/workspace-annotation/mcp-journal-companion-stale"))
      (mcp-test-seed-note client
                          nonjournal-topic-id
                          "Non-journal note"
                          "This stays outside the journal repair boundary."
                          :uri (hyperdoc::dmx-workspace-note-uri
                                :workspace-note
                                "mcp-non-journal-note"))
      (mcp-test-seed-journal-companion
       client
       assigned-topic-id
       assigned-subject-key
       :workspace-id *dmx-mcp-smoke-workspace-id*
       :view-props (mcp-test-view-props :x 120 :y 140 :visibility t :pinned nil))
      (mcp-test-seed-journal-companion
       client
       stale-topic-id
       stale-subject-key
       :view-props (mcp-test-view-props :x 40 :y 60 :visibility t :pinned nil))
      (mcp-clear-journal-repair-observations client)
      (unwind-protect
           (progn
             (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
             (sleep 0.2)
             (let ((session-id
                     (mcp-test-open-session
                      url
                      :id 501
                      :client-name "hyperdoc-journal-companion-repair-smoke")))
               (multiple-value-bind (reject-body reject-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    502
                    "repair_workspace_journal_companion"
                    (mcp-test-json-object
                     "journalTopicId" nonjournal-topic-id
                     "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                     "workspaceId" *dmx-mcp-smoke-workspace-id*
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200 reject-status
                                   "Non-journal repair rejection status")
                 (let* ((tool-result (gethash "result" reject-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (gethash "isError" tool-result)
                    "Journal-companion repair must reject non-journal topics")
                   (mcp-assert-equal "rejected"
                                     (gethash "repair-status" structured)
                                     "Non-journal repair must surface REJECTED status")
                   (mcp-assert-equal "hyperdoc-workspace-note"
                                     (gethash "ownership-class" structured)
                                     "Non-journal repair must preserve the narrower owned note classification")))
               (mcp-assert-true
                (hyperdoc::dmx-import-read-topic client nonjournal-topic-id)
                "Rejecting the journal repair tool must not broaden into generic note delete")
               (multiple-value-bind (assigned-body assigned-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    503
                    "repair_workspace_journal_companion"
                    (mcp-test-json-object
                     "journalTopicId" assigned-topic-id
                     "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                     "workspaceId" *dmx-mcp-smoke-workspace-id*
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200 assigned-status
                                   "Already-assigned companion rejection status")
                 (let* ((tool-result (gethash "result" assigned-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (gethash "isError" tool-result)
                    "Journal-companion repair must reject already-assigned companions")
                   (mcp-assert-equal "not-needed"
                                     (gethash "repair-status" structured)
                                     "Already-assigned companions must stay outside the stale repair class")
                   (mcp-assert-equal assigned-topic-id
                                     (gethash "current-topic-id" structured)
                                     "Already-assigned companions must preserve current identity")))
               (multiple-value-bind (dry-run-body dry-run-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    504
                    "repair_workspace_journal_companion"
                    (mcp-test-json-object
                     "subjectKey" stale-subject-key
                     "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                     "workspaceId" *dmx-mcp-smoke-workspace-id*
                     "dryRun" t))
                 (declare (ignore _))
                 (mcp-assert-equal 200 dry-run-status
                                   "Stale companion repair dry-run status")
                 (let* ((tool-result (gethash "result" dry-run-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "Stale journal companion dry-run must remain a normal typed planning result")
                   (mcp-assert-equal "create-replacement-and-retain-stale"
                                     (gethash "repair-strategy" structured)
                                     "Journal companion repair dry-run must plan create-and-retain-stale only")
                   (mcp-assert-equal t
                                     (gethash "repairable-p" structured)
                                     "Stale journal companion dry-run must confirm the repairable class")
                   (mcp-assert-equal "planned"
                                     (gethash "repair-status" structured)
                                     "Stale journal companion dry-run must stay planned")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "stale-topic-id" structured)
                                     "Dry-run must preserve the stale companion identity")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "current-topic-id" structured)
                                     "Dry-run must leave the stale companion as current before repair")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "replacement-topic-id" structured))
                    "Dry-run must not fabricate a replacement id")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "hidden-placement-enforced-p" structured))
                    "Dry-run must not claim placement enforcement happened yet")))
               (mcp-assert-true
                (null (mcp-journal-delete-topic-ids-of client))
                "Dry-run must not execute stale delete")
               (mcp-assert-true
                (null (mcp-journal-create-observations-of client))
                "Dry-run must not create a replacement companion")
               (mcp-assert-true
                (null (mcp-journal-placement-observations-of client))
                "Dry-run must not mutate hidden placement")
               (multiple-value-bind (live-body live-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    505
                    "repair_workspace_journal_companion"
                    (mcp-test-json-object
                     "journalTopicId" stale-topic-id
                     "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                     "workspaceId" *dmx-mcp-smoke-workspace-id*
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200 live-status
                                   "Stale companion repair live status")
                 (let* ((tool-result (gethash "result" live-body))
                        (structured (gethash "structuredContent" tool-result))
                        (replacement-topic-id (gethash "replacement-topic-id" structured))
                        (replacement-topic
                          (and replacement-topic-id
                               (hyperdoc::dmx-import-read-topic
                                client
                                replacement-topic-id)))
                        (replacement-workspace
                          (and replacement-topic-id
                               (hyperdoc::dmx-import-read-topic-workspace
                                client
                                replacement-topic-id)))
                        (replacement-membership
                          (and replacement-topic-id
                               (gethash (hyperdoc::memory-topicmap-membership-key
                                         *dmx-mcp-smoke-workspace-topicmap-id*
                                         replacement-topic-id)
                                        (hyperdoc::topicmap-memberships-of client)))))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "Stale journal companion repair must succeed on the typed repair path")
                   (mcp-assert-equal "create-replacement-and-retain-stale"
                                     (gethash "repair-strategy" structured)
                                     "Live repair must keep the runtime create-and-retain-stale truth")
                   (mcp-assert-equal "completed"
                                     (gethash "repair-status" structured)
                                     "Live repair must report completion")
                   (mcp-assert-equal t
                                     (gethash "repair-completed-p" structured)
                                     "Live repair must report repair completion")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "stale-topic-id" structured)
                                     "Live repair must preserve the stale identity")
                   (mcp-assert-true
                    (and (integerp replacement-topic-id)
                         (/= replacement-topic-id stale-topic-id))
                    "Live repair must create a distinct replacement companion topic")
                   (mcp-assert-equal replacement-topic-id
                                     (gethash "current-topic-id" structured)
                                     "Live repair must flip current identity to the replacement topic")
                   (mcp-assert-equal t
                                     (gethash "stale-topic-retained-p" structured)
                                     "Live repair must preserve that the stale topic was retained as history")
                   (mcp-assert-equal t
                                     (gethash "stale-topic-superseded-p" structured)
                                     "Live repair must preserve that the stale topic was superseded by the replacement")
                   (mcp-assert-equal *dmx-mcp-smoke-workspace-id*
                                     (gethash "assigned-workspace-id-after" structured)
                                     "Live repair must report the replacement workspace assignment")
                   (mcp-assert-equal t
                                     (gethash "hidden-placement-enforced-p" structured)
                                     "Live repair must enforce hidden/off-canvas placement")
                   (mcp-assert-equal t
                                     (gethash "hidden-view-props-restored-p" structured)
                                     "Live repair must restore hidden journal view props")
                   (mcp-assert-true
                    replacement-topic
                    "Live repair must leave the replacement companion topic readable")
                   (mcp-assert-equal *dmx-mcp-smoke-workspace-id*
                                     (hyperdoc::dmx-import-object-id replacement-workspace)
                                     "Live repair must create the replacement under the intended workspace context")
                   (mcp-assert-true
                    (mcp-hidden-journal-view-props-p replacement-membership)
                    "Live repair must enforce the hidden/off-canvas placement invariant")))
               (mcp-assert-true
                (null (mcp-journal-delete-topic-ids-of client))
                "Live repair must not delete the stale unassigned companion topic")
               (mcp-assert-equal 1
                                 (length (mcp-journal-create-observations-of client))
                                 "Live repair must create exactly one replacement companion")
               (mcp-assert-equal *dmx-mcp-smoke-workspace-id*
                                 (getf (first (mcp-journal-create-observations-of client))
                                       :workspace-id)
                                 "Replacement create must run under the resolved writable workspace context")
               (mcp-assert-true
                (null (mcp-journal-update-topic-ids-of client))
                "Live repair must not re-enter the generic direct-update path for journal companions")
               (mcp-assert-true
                (hyperdoc::dmx-import-read-topic client stale-topic-id)
                "Live repair must retain the stale companion topic as history after replacement create"))))
        (hyperdoc::stop-dmx-mcp-server))
    t)

(defun run-dmx-mcp-workspace-journal-companion-repair-failure-smoke-test ()
  (multiple-value-bind (server client)
      (make-dmx-mcp-journal-companion-repair-server)
    (let* ((port (mcp-test-port))
           (url (format nil "http://127.0.0.1:~D/mcp" port))
           (stale-topic-id 921683)
           (stale-subject-key
             "hyperdoc:mcp/workspace-annotation/mcp-journal-companion-failure"))
      (mcp-test-seed-journal-companion
       client
       stale-topic-id
       stale-subject-key
       :view-props (mcp-test-view-props :x 80 :y 90 :visibility t :pinned nil))
      (mcp-clear-journal-repair-observations client)
      (setf (mcp-fail-journal-hidden-placement-p-of client) t)
      (unwind-protect
           (progn
             (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
             (sleep 0.2)
             (let ((session-id
                     (mcp-test-open-session
                      url
                      :id 551
                      :client-name "hyperdoc-journal-companion-repair-failure")))
               (multiple-value-bind (failure-body failure-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    552
                    "repair_workspace_journal_companion"
                    (mcp-test-json-object
                     "journalTopicId" stale-topic-id
                     "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                     "workspaceId" *dmx-mcp-smoke-workspace-id*
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200 failure-status
                                   "Journal companion repair failure status")
                 (let* ((tool-result (gethash "result" failure-body))
                        (structured (gethash "structuredContent" tool-result))
                        (replacement-topic-id (gethash "replacement-topic-id" structured))
                        (replacement-workspace
                          (and replacement-topic-id
                               (hyperdoc::dmx-import-read-topic-workspace
                                client
                                replacement-topic-id))))
                   (mcp-assert-true
                    (gethash "isError" tool-result)
                    "Repair failure after retained-stale replacement create must stay a typed repair error")
                   (mcp-assert-equal "failed"
                                     (gethash "repair-status" structured)
                                     "Repair failure must preserve FAILED status")
                   (mcp-assert-equal "create-replacement-and-retain-stale"
                                     (gethash "repair-strategy" structured)
                                     "Repair failure must preserve the create-and-retain-stale strategy")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "stale-topic-id" structured)
                                     "Repair failure must preserve the stale companion id")
                   (mcp-assert-true
                    (integerp replacement-topic-id)
                    "Repair failure after recreate must preserve the replacement id")
                   (mcp-assert-equal replacement-topic-id
                                     (gethash "current-topic-id" structured)
                                     "Repair failure must preserve the last valid post-repair identity")
                   (mcp-assert-equal t
                                     (gethash "stale-topic-retained-p" structured)
                                     "Repair failure must preserve that the stale topic was retained")
                   (mcp-assert-equal t
                                     (gethash "stale-topic-superseded-p" structured)
                                     "Repair failure after replacement create must preserve stale-superseded truth")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "stale-delete-attempted-p" structured))
                    "Repair failure must preserve that stale delete was not attempted")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "stale-delete-succeeded-p" structured))
                    "Repair failure must preserve that stale delete did not run")
                   (mcp-assert-equal t
                                     (gethash "replacement-create-attempted-p" structured)
                                     "Repair failure must preserve replacement create attempt evidence")
                   (mcp-assert-equal t
                                     (gethash "replacement-create-succeeded-p" structured)
                                     "Repair failure must preserve replacement create success evidence")
                   (mcp-assert-equal t
                                     (gethash "hidden-placement-attempted-p" structured)
                                     "Repair failure must preserve hidden placement attempt evidence")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "hidden-placement-succeeded-p" structured))
                    "Repair failure must keep hidden placement failure visible")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "repair-completed-p" structured))
                                     "Repair failure must not claim repair completion")
                   (mcp-assert-equal *dmx-mcp-smoke-workspace-id*
                                     (hyperdoc::dmx-import-object-id replacement-workspace)
                                     "Repair failure must still preserve the recreated topic's workspace assignment"))))
               (mcp-assert-true
                (null (mcp-journal-delete-topic-ids-of client))
                "Repair failure must retain the stale companion when placement fails")
               (mcp-assert-equal 1
                                 (length (mcp-journal-create-observations-of client))
                                 "Repair failure must still record the replacement create attempt")
               (mcp-assert-true
                (null (mcp-journal-update-topic-ids-of client))
                "Repair failure must not fall back to a broader journal direct-update path")))
        (hyperdoc::stop-dmx-mcp-server))
    t))

(defun run-dmx-mcp-workspace-journal-companion-replacement-create-failure-smoke-test ()
  (multiple-value-bind (server client)
      (make-dmx-mcp-journal-companion-repair-server)
    (let* ((port (mcp-test-port))
           (url (format nil "http://127.0.0.1:~D/mcp" port))
           (stale-topic-id 921685)
           (stale-subject-key
             "hyperdoc:mcp/workspace-annotation/mcp-journal-companion-create-failure"))
      (mcp-test-seed-journal-companion
       client
       stale-topic-id
       stale-subject-key
       :view-props (mcp-test-view-props :x 88 :y 92 :visibility t :pinned nil))
      (mcp-clear-journal-repair-observations client)
      (setf (mcp-fail-journal-replacement-create-p-of client) t)
      (unwind-protect
           (progn
             (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
             (sleep 0.2)
             (let ((session-id
                     (mcp-test-open-session
                      url
                      :id 553
                      :client-name "hyperdoc-journal-companion-repair-create-failure")))
               (multiple-value-bind (failure-body failure-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    554
                    "repair_workspace_journal_companion"
                    (mcp-test-json-object
                     "journalTopicId" stale-topic-id
                     "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                     "workspaceId" *dmx-mcp-smoke-workspace-id*
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200 failure-status
                                   "Journal companion replacement-create failure status")
                 (let* ((tool-result (gethash "result" failure-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (gethash "isError" tool-result)
                    "Replacement-create failure must stay a typed repair error")
                   (mcp-assert-equal "failed"
                                     (gethash "repair-status" structured)
                                     "Replacement-create failure must preserve FAILED status")
                   (mcp-assert-equal "create-replacement-and-retain-stale"
                                     (gethash "repair-strategy" structured)
                                     "Replacement-create failure must preserve the create-and-retain-stale strategy")
                   (mcp-assert-equal "create-replacement"
                                     (gethash "repair-step" structured)
                                     "Replacement-create failure must stop at create-replacement")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "stale-topic-id" structured)
                                     "Replacement-create failure must preserve the stale companion id")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "current-topic-id" structured)
                                     "Replacement-create failure must keep current identity on the stale companion")
                   (mcp-assert-equal t
                                     (gethash "stale-topic-retained-p" structured)
                                     "Replacement-create failure must preserve stale-retained truth")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "stale-topic-superseded-p" structured))
                    "Replacement-create failure must not claim the stale topic was already superseded")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "replacement-topic-id" structured))
                    "Replacement-create failure must not fabricate a replacement id")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "stale-delete-attempted-p" structured))
                    "Replacement-create failure must not attempt stale delete")
                   (mcp-assert-equal t
                                     (gethash "replacement-create-attempted-p" structured)
                                     "Replacement-create failure must record the create attempt")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "replacement-create-succeeded-p" structured))
                    "Replacement-create failure must preserve create failure truth")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "hidden-placement-attempted-p" structured))
                    "Replacement-create failure must not attempt hidden placement"))))
               (mcp-assert-true
                (null (mcp-journal-delete-topic-ids-of client))
                "Replacement-create failure must not delete the stale companion")
               (mcp-assert-true
                (null (mcp-journal-create-observations-of client))
                "Replacement-create failure must not record a created replacement topic")
               (mcp-assert-true
                (hyperdoc::dmx-import-read-topic client stale-topic-id)
                "Replacement-create failure must leave the stale companion readable"))))
        (hyperdoc::stop-dmx-mcp-server))
    t))

(defun run-dmx-mcp-workspace-journal-companion-repair-missing-auth-config-smoke-test ()
  (multiple-value-bind (server client)
      (make-dmx-mcp-journal-companion-repair-server
       :authorization-header nil)
    (let* ((port (mcp-test-port))
           (url (format nil "http://127.0.0.1:~D/mcp" port))
           (stale-topic-id 921684)
           (stale-subject-key
             "hyperdoc:mcp/workspace-annotation/mcp-journal-companion-missing-auth"))
      (mcp-test-seed-journal-companion
       client
       stale-topic-id
       stale-subject-key
       :view-props (mcp-test-view-props :x 120 :y 110 :visibility nil :pinned nil))
      (mcp-clear-journal-repair-observations client)
      (unwind-protect
           (progn
             (hyperdoc::serve-dmx-mcp-server :port port :address "127.0.0.1" :server server)
             (sleep 0.2)
             (let ((session-id
                     (mcp-test-open-session
                      url
                      :id 561
                      :client-name "hyperdoc-journal-companion-repair-missing-auth")))
               (multiple-value-bind (blocked-body blocked-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    562
                    "repair_workspace_journal_companion"
                    (mcp-test-json-object
                     "journalTopicId" stale-topic-id
                     "workspaceTopicmapId" *dmx-mcp-smoke-workspace-topicmap-id*
                     "workspaceId" *dmx-mcp-smoke-workspace-id*
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200 blocked-status
                                   "Journal companion repair missing-auth status")
                 (let* ((tool-result (gethash "result" blocked-body))
                        (structured (gethash "structuredContent" tool-result)))
                   (mcp-assert-true
                    (gethash "isError" tool-result)
                    "Missing server-side DMX auth config must stay a typed repair error")
                   (mcp-assert-equal "blocked"
                                     (gethash "repair-status" structured)
                                     "Missing server-side DMX auth config must surface BLOCKED status")
                   (mcp-assert-equal "missing-server-side-dmx-auth-config"
                                     (gethash "repair-reason" structured)
                                     "Missing server-side DMX auth config must surface a precise repair reason")
                   (mcp-assert-equal "preflight"
                                     (gethash "repair-step" structured)
                                     "Missing server-side DMX auth config must stay at preflight")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "stale-topic-id" structured)
                                     "Blocked repair must preserve stale topic identity")
                   (mcp-assert-equal stale-topic-id
                                     (gethash "current-topic-id" structured)
                                     "Blocked repair must keep current topic on the stale identity")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "replacement-topic-id" structured))
                    "Blocked repair must not fabricate a replacement topic id")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "assigned-workspace-id-after" structured))
                    "Blocked repair must not claim post-recreate workspace assignment")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "hidden-placement-enforced-p" structured))
                    "Blocked repair must not claim hidden placement enforcement")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "stale-delete-attempted-p" structured))
                    "Blocked repair must report stale delete not attempted")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "replacement-create-attempted-p" structured))
                    "Blocked repair must report replacement create not attempted")
                   (mcp-assert-true
                    (mcp-json-null-p
                     (gethash "hidden-placement-attempted-p" structured))
                    "Blocked repair must report hidden placement not attempted")
                   (mcp-assert-true
                    (search "HYPERDOC_DMX_IMPORT_AUTH_HEADER"
                            (or (gethash "repair-failure-message" structured) ""))
                    "Blocked repair must keep the missing server-side auth evidence visible"))))
               (mcp-assert-true
                (null (mcp-journal-delete-topic-ids-of client))
                "Blocked repair must not delete the stale companion")
               (mcp-assert-true
                (null (mcp-journal-create-observations-of client))
                "Blocked repair must not create a replacement companion")
               (mcp-assert-true
                (null (mcp-journal-placement-observations-of client))
                "Blocked repair must not attempt hidden placement")))
        (hyperdoc::stop-dmx-mcp-server))
    t))

(defun run-dmx-mcp-workspace-annotation-continuation-smoke-test ()
  (multiple-value-bind (server topic-id)
      (make-dmx-mcp-annotation-smoke-server)
    (let* ((port (mcp-test-port))
           (url (format nil "http://127.0.0.1:~D/mcp" port)))
      (unwind-protect
           (progn
             (hyperdoc::serve-dmx-mcp-server
              :port port
              :address "127.0.0.1"
              :server server)
             (sleep 0.2)
             (let ((session-id (mcp-test-open-session url :id 401)))
               (multiple-value-bind (dry-run-body dry-run-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    402
                    "continue_workspace_annotation"
                    (mcp-test-json-object
                     "topicId" topic-id
                     "dryRun" t))
                 (declare (ignore _))
                 (mcp-assert-equal 200
                                   dry-run-status
                                   "continue_workspace_annotation dry-run status")
                 (let* ((tool-result (gethash "result" dry-run-body))
                        (structured (gethash "structuredContent" tool-result))
                        (plan (gethash "plan" structured))
                        (saved-annotation
                          (gethash "savedAnnotationObject" structured)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "continue_workspace_annotation dry-run must not be flagged as error")
                   (mcp-assert-equal "workspace_annotation_dry_run"
                                     (gethash "resultKind" structured)
                                     "Annotation continuation dry-run result kind")
                   (mcp-assert-equal "update"
                                     (gethash "topicAction" plan)
                                     "Saved annotation continuation dry-run must plan an update")
                   (mcp-assert-equal "compatibility note carrier"
                                     (gethash "storageModeLabel" plan)
                                     "Saved annotation continuation dry-run must stay on compatibility storage")
                   (mcp-assert-equal "workspace-dock-annotation"
                                     (gethash "kind" saved-annotation)
                                     "Saved annotation continuation dry-run must expose the semantic annotation object")))
               (multiple-value-bind (live-body live-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    403
                    "continue_workspace_annotation"
                    (mcp-test-json-object
                     "topicId" topic-id
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200
                                   live-status
                                   "continue_workspace_annotation live status")
                 (let* ((tool-result (gethash "result" live-body))
                        (structured (gethash "structuredContent" tool-result))
                        (annotation (gethash "annotation" structured))
                        (saved-carrier-topic
                          (gethash "savedCarrierTopic" structured))
                        (journal-topic
                          (gethash "journalCompanionTopic" structured)))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "continue_workspace_annotation live must not be flagged as error")
                   (mcp-assert-equal "workspace_annotation"
                                     (gethash "resultKind" structured)
                                     "Annotation continuation live result kind")
                   (mcp-assert-equal topic-id
                                     (gethash "workspaceTopicId" annotation)
                                     "Annotation continuation live must preserve the saved topic id")
                   (mcp-assert-equal "compatibility note carrier"
                                     (gethash "storageModeLabel" annotation)
                                     "Annotation continuation live must preserve compatibility storage")
                   (mcp-assert-equal topic-id
                                     (gethash "topicId" saved-carrier-topic)
                                     "Annotation continuation live must expose the saved carrier topic")
                   (mcp-assert-true
                    (integerp (gethash "topicId" journal-topic))
                    "Annotation continuation live must expose the journal companion topic")
                   (mcp-assert-true
                    (/= (gethash "topicId" journal-topic) topic-id)
                    "Journal companion topic must remain distinct from the saved annotation carrier topic")))))
        (hyperdoc::stop-dmx-mcp-server)))
    t))

(defun run-dmx-mcp-workspace-annotation-continuation-auth-blocked-smoke-test ()
  (multiple-value-bind (server topic-id journal-topic-id)
      (make-dmx-mcp-annotation-auth-blocked-server)
    (let* ((port (mcp-test-port))
           (url (format nil "http://127.0.0.1:~D/mcp" port))
           (original
             (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)))
      (unwind-protect
           (progn
             (hyperdoc::serve-dmx-mcp-server
              :port port
              :address "127.0.0.1"
              :server server)
             (sleep 0.2)
             (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
                   (lambda (client subject-key lookup-kind lookup-value
                            workspace-topicmap-id
                            &rest args
                            &key subject-uri subject-kind ownership-class
                              note-key note-kind
                            &allow-other-keys)
                     (declare (ignore client subject-key lookup-kind lookup-value
                                      workspace-topicmap-id args subject-uri
                                      subject-kind ownership-class note-key
                                      note-kind))
                     (mcp-signal-journal-preflight-http-401-with-header-evidence
                      journal-topic-id)))
             (let ((session-id (mcp-test-open-session url :id 451)))
               (multiple-value-bind (blocked-body blocked-status _)
                   (mcp-test-call-tool
                    url
                    session-id
                    452
                    "continue_workspace_annotation"
                    (mcp-test-json-object
                     "topicId" topic-id
                     "workspaceId" *dmx-annotations-smoke-workspace-id*
                     "workspaceTopicmapId"
                     *dmx-annotations-smoke-workspace-topicmap-id*
                     "dryRun" nil))
                 (declare (ignore _))
                 (mcp-assert-equal 200
                                   blocked-status
                                   "continue_workspace_annotation auth-blocked status")
                 (let* ((tool-result (gethash "result" blocked-body))
                        (structured (gethash "structuredContent" tool-result))
                        (saved-annotation
                          (gethash "savedAnnotationObject" structured))
                        (saved-carrier-topic
                          (gethash "savedCarrierTopic" structured))
                        (journal-topic
                          (gethash "journalCompanionTopic" structured))
                        (assignment-auth-context
                          (gethash "assignmentAuthContext" structured))
                        (http-evidence
                          (and assignment-auth-context
                               (gethash "http-evidence" assignment-auth-context)))
                        (response-headers
                          (and http-evidence
                               (gethash "response-headers" http-evidence)))
                        (content-type-header
                          (and response-headers
                               (mcp-json-array-find-keyed-object
                                response-headers
                                "Content-Type"))))
                   (mcp-assert-true
                    (null (gethash "isError" tool-result))
                    "continue_workspace_annotation auth-blocked reports must stay in structured content")
                  (mcp-assert-equal "workspace_annotation_persistence_report"
                                     (gethash "resultKind" structured)
                                     "Annotation continuation auth-blocked result kind")
                   (mcp-assert-equal "failed"
                                     (gethash "reportStatus" structured)
                                     "Annotation continuation auth-blocked reports must stay failed")
                   (mcp-assert-equal "workspace-assignment"
                                     (gethash "failureStage" structured)
                                     "Annotation continuation auth-blocked reports must fail at the guarded workspace-assignment stage")
                   (mcp-assert-equal "workspace-dock-annotation"
                                     (gethash "kind" saved-annotation)
                                     "Annotation continuation auth-blocked reports must still expose the semantic annotation object")
                   (mcp-assert-equal topic-id
                                     (gethash "topicId" saved-carrier-topic)
                                     "Annotation continuation auth-blocked reports must expose the saved carrier topic")
                   (mcp-assert-equal journal-topic-id
                                     (gethash "topicId" journal-topic)
                                     "Annotation continuation auth-blocked reports must expose the journal companion topic")
                   (mcp-assert-true
                    response-headers
                    "Annotation continuation auth-blocked reports must preserve guarded-assignment HTTP response header evidence")
                   (mcp-assert-equal "application/json; charset=utf-8"
                                     (gethash "value" content-type-header)
                                     "Annotation continuation auth-blocked reports must normalize dotted-pair response headers")))))
        (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
              original)
        (hyperdoc::stop-dmx-mcp-server)))
    t))

(defun run-dmx-mcp-smoke-tests ()
  (run-dmx-workspace-note-http-single-content-type-smoke-test)
  (run-dmx-import-delete-and-remove-contract-smoke-test)
  (run-dmx-import-workspace-assignment-contract-smoke-test)
  (run-dmx-import-explicit-basic-login-bootstrap-smoke-test)
  (run-dmx-mcp-smoke-test)
  (run-dmx-mcp-workspace-annotation-continuation-smoke-test)
  (run-dmx-mcp-workspace-annotation-continuation-auth-blocked-smoke-test)
  (run-dmx-mcp-workspace-topic-lifecycle-smoke-test)
  (run-dmx-mcp-workspace-journal-smoke-test)
  (run-dmx-mcp-workspace-journal-companion-repair-smoke-test)
  (run-dmx-mcp-workspace-journal-companion-repair-failure-smoke-test)
  (run-dmx-mcp-workspace-journal-companion-replacement-create-failure-smoke-test)
  (run-dmx-mcp-owned-topic-lifecycle-proof-smoke-test)
  (run-dmx-workspace-journal-foreign-restore-guardrail-smoke-test)
  (run-dmx-mcp-workspace-assignment-repair-smoke-test)
  (run-dmx-workspace-journal-assignment-repair-nonrecursive-smoke-test)
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
