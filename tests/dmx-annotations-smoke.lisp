;;;; Smoke tests for typed DMX workspace annotations
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DMX-ANNOTATIONS-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *dmx-annotations-smoke-workspace-topicmap-id* 919822)
(defparameter *dmx-annotations-smoke-workspace-id* 919815)

(defclass failing-topicmap-placement-dmx-import-client
    (hyperdoc::memory-dmx-import-client)
  ())

(defclass latin1-failing-topic-create-dmx-import-client
    (hyperdoc::memory-dmx-import-client)
  ())

(defclass compatibility-storage-http-dmx-import-client
    (hyperdoc::memory-dmx-import-client
     hyperdoc::http-dmx-import-client)
  ((supported-type-uris
    :reader supported-type-uris-of
    :initarg :supported-type-uris
    :initform
    (list hyperdoc::*dmx-notes-note-type-uri*
          hyperdoc::*dmx-notes-title-type-uri*
          hyperdoc::*dmx-notes-text-type-uri*))))

(defclass pending-auth-compatibility-storage-http-dmx-import-client
    (compatibility-storage-http-dmx-import-client)
  ((assignment-auth-available-p
    :accessor assignment-auth-available-p-of
    :initarg :assignment-auth-available-p
    :initform nil)))

(defclass journal-preflight-auth-blocked-compatibility-storage-http-dmx-import-client
    (compatibility-storage-http-dmx-import-client)
  ((journal-preflight-auth-available-p
    :accessor journal-preflight-auth-available-p-of
    :initarg :journal-preflight-auth-available-p
    :initform nil)))

(defclass failing-topic-update-dmx-import-client
    (compatibility-storage-http-dmx-import-client)
  ())

(defclass auth-blocked-topic-update-dmx-import-client
    (compatibility-storage-http-dmx-import-client)
  ())

(defclass counting-topic-update-compatibility-storage-http-dmx-import-client
    (compatibility-storage-http-dmx-import-client)
  ((topic-update-count
    :accessor topic-update-count-of
    :initarg :topic-update-count
    :initform 0)))

(defclass journal-repair-observing-compatibility-storage-http-dmx-import-client
    (counting-topic-update-compatibility-storage-http-dmx-import-client)
  ((journal-create-observations
    :accessor journal-create-observations-of
    :initarg :journal-create-observations
    :initform '())
   (journal-update-topic-ids
    :accessor journal-update-topic-ids-of
    :initarg :journal-update-topic-ids
    :initform '())
   (journal-delete-topic-ids
    :accessor journal-delete-topic-ids-of
    :initarg :journal-delete-topic-ids
    :initform '())
   (journal-placement-observations
    :accessor journal-placement-observations-of
    :initarg :journal-placement-observations
    :initform '())
   (fail-journal-hidden-placement-p
    :accessor fail-journal-hidden-placement-p-of
    :initarg :fail-journal-hidden-placement-p
    :initform nil)))

(defclass preserved-workspace-annotation-http-dmx-import-client
    (hyperdoc::http-dmx-import-client)
  ((topics-by-id
    :accessor preserved-topics-by-id-of
    :initarg :topics-by-id
    :initform (make-hash-table :test #'eql))
   (topicmap-memberships
    :accessor preserved-topicmap-memberships-of
    :initarg :topicmap-memberships
    :initform (make-hash-table :test #'equal))
   (workspace-assignments
    :accessor preserved-workspace-assignments-of
    :initarg :workspace-assignments
    :initform (make-hash-table :test #'eql))))

(defun preserved-topicmap-membership-key (topicmap-id topic-id)
  (list topicmap-id topic-id))

(defun make-preserved-workspace-annotation-carrier-topic-json
    (&key (topic-id 936040)
      (workspace-id *dmx-annotations-smoke-workspace-id*)
      (workspace-topicmap-id *dmx-annotations-smoke-workspace-topicmap-id*))
  (let* ((planning-client (make-instance 'hyperdoc::memory-dmx-import-client))
         (annotation (make-test-dock-annotation
                      :note "Preserved compatibility carrier topic"))
         (plan (hyperdoc::plan-dmx-workspace-annotation-write-from-object
                annotation
                :workspace-id workspace-id
                :workspace-topicmap-id workspace-topicmap-id
                :client planning-client
                :storage-mode
                hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*))
         (payload (copy-tree
                   (hyperdoc::dmx-workspace-annotation-write-plan-payload
                    plan)))
         (view-props
           (hyperdoc::dmx-workspace-annotation-write-plan-view-props plan))
         (topic-json nil))
    (setf (getf payload :id) topic-id
          topic-json (hyperdoc::dmx-import-json-object payload))
    (values topic-json payload view-props)))

(defun workspace-annotation-smoke-journal-uri-p (value)
  (and (stringp value)
       (hyperdoc::dmx-string-prefix-p
        hyperdoc::*hyperdoc-workspace-journal-uri-prefix*
        value)))

(defun workspace-annotation-smoke-journal-topic-object-p (topic)
  (workspace-annotation-smoke-journal-uri-p
   (or (hyperdoc::dmx-json-object-value topic "uri")
       (getf topic :external-key)
       (getf topic :uri))))

(defun workspace-annotation-smoke-topic-external-key-by-id (client topic-id)
  (loop for external-key being the hash-keys of (hyperdoc::topics-by-external-key-of client)
          using (hash-value topic)
        when (eql topic-id (hyperdoc::dmx-import-object-id topic))
          do (return external-key)))

(defun workspace-annotation-smoke-journal-topic-id-p (client topic-id)
  (workspace-annotation-smoke-journal-uri-p
   (workspace-annotation-smoke-topic-external-key-by-id client topic-id)))

(defun workspace-annotation-smoke-hidden-view-props-p (view-props)
  (hyperdoc::dmx-workspace-journal-hidden-view-props-p view-props))

(defmethod hyperdoc::dmx-import-read-topic
    ((client preserved-workspace-annotation-http-dmx-import-client) topic-id)
  (gethash topic-id (preserved-topics-by-id-of client)))

(defmethod hyperdoc::dmx-import-find-existing-topic
    ((client preserved-workspace-annotation-http-dmx-import-client) external-key)
  (loop for topic being the hash-values of (preserved-topics-by-id-of client)
        when (and (hash-table-p topic)
                  (or (string= external-key
                               (or (gethash "uri" topic) ""))
                      (string= external-key
                               (or (gethash "externalKey" topic) ""))))
          return topic))

(defmethod hyperdoc::dmx-import-read-topic-workspace
    ((client preserved-workspace-annotation-http-dmx-import-client) topic-id)
  (let ((workspace-id
          (gethash topic-id (preserved-workspace-assignments-of client))))
    (when workspace-id
      (hyperdoc::memory-dmx-import-workspace-json workspace-id))))

(defmethod hyperdoc::dmx-import-topic-in-topicmap-p
    ((client preserved-workspace-annotation-http-dmx-import-client)
     topicmap-id
     topic-id)
  (not (null (gethash (preserved-topicmap-membership-key topicmap-id topic-id)
                      (preserved-topicmap-memberships-of client)))))

(defmethod hyperdoc::dmx-import-read-topicmap
    ((client preserved-workspace-annotation-http-dmx-import-client) topicmap-id)
  (let ((topicmap-topic-json (make-hash-table :test #'equal))
        (json (make-hash-table :test #'equal))
        (topics '()))
    (setf (gethash "id" topicmap-topic-json) topicmap-id
          (gethash "uri" topicmap-topic-json) ""
          (gethash "typeUri" topicmap-topic-json) "dmx.topicmaps.topicmap"
          (gethash "value" topicmap-topic-json) (format nil "Topicmap ~D" topicmap-id)
          (gethash "children" topicmap-topic-json) (make-hash-table :test #'equal))
    (maphash
     (lambda (membership-key view-props)
       (destructuring-bind (membership-topicmap-id topic-id) membership-key
         (when (eql membership-topicmap-id topicmap-id)
           (let ((topic-json
                   (gethash topic-id (preserved-topics-by-id-of client))))
             (when topic-json
               (setf (gethash "viewProps" topic-json) view-props)
               (push topic-json topics))))))
     (preserved-topicmap-memberships-of client))
    (setf (gethash "topic" json) topicmap-topic-json
          (gethash "viewProps" json) (make-hash-table :test #'equal)
          (gethash "topics" json) (coerce (nreverse topics) 'vector)
          (gethash "assocs" json) #())
    json))

(defmethod hyperdoc::dmx-import-assign-topic-to-workspace
    ((client preserved-workspace-annotation-http-dmx-import-client)
     workspace-id
     topic-id)
  (prog1
      (call-next-method)
    (setf (gethash topic-id (preserved-workspace-assignments-of client))
          workspace-id)))

(defmethod hyperdoc::dmx-import-add-topic-to-topicmap
    ((client preserved-workspace-annotation-http-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (prog1
      (call-next-method)
    (setf (gethash (preserved-topicmap-membership-key topicmap-id topic-id)
                   (preserved-topicmap-memberships-of client))
          view-props)))

(defmethod hyperdoc::dmx-import-update-topic
    ((client preserved-workspace-annotation-http-dmx-import-client)
     existing-topic
     payload)
  (let* ((updated-topic (call-next-method))
         (topic-id (or (hyperdoc::dmx-import-object-id updated-topic)
                       (hyperdoc::dmx-import-object-id existing-topic)
                       (getf payload :id))))
    (when topic-id
      (setf (gethash topic-id (preserved-topics-by-id-of client))
            updated-topic))
    updated-topic))

(defmethod hyperdoc::dmx-import-set-topic-view-props
    ((client preserved-workspace-annotation-http-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (prog1
      (call-next-method)
    (setf (gethash (preserved-topicmap-membership-key topicmap-id topic-id)
                   (preserved-topicmap-memberships-of client))
          view-props)))

(defun make-type-support-topic-json (type-uri)
  (let ((json (make-hash-table :test #'equal)))
    (setf (gethash "id" json) (+ 970000 (sxhash type-uri))
          (gethash "uri" json) type-uri
          (gethash "typeUri" json) "dmx.core.topic_type"
          (gethash "value" json) type-uri
          (gethash "children" json) (make-hash-table :test #'equal))
    json))

(defmethod hyperdoc::dmx-import-find-existing-topic
    ((client compatibility-storage-http-dmx-import-client) external-key)
  (or (call-next-method)
      (let* ((supported-p (member external-key
                                  (supported-type-uris-of client)
                                  :test #'string=))
             (path (hyperdoc::dmx-topic-uri-lookup-path external-key))
             (evidence
               (list :method :get
                     :path path
                     :auth-mode-summary "Bearer header"
                     :authorization-scheme "Bearer"
                     :bootstrap-ran-p nil
                     :response-status-code (if supported-p 200 404)
                     :response-reason-phrase (if supported-p "OK" "Not Found")
                     :response-body (if supported-p
                                        (format nil "{\"uri\":\"~A\"}" external-key)
                                        ""))))
        (setf (hyperdoc::dmx-import-last-http-transaction-evidence-of client)
              evidence)
        (when supported-p
          (make-type-support-topic-json external-key)))))

(defmethod hyperdoc::dmx-import-add-topic-to-topicmap
    ((client failing-topicmap-placement-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (declare (ignore client topicmap-id topic-id view-props))
  (error "Simulated topicmap placement failure"))

(defmethod hyperdoc::dmx-import-assign-topic-to-workspace
    ((client pending-auth-compatibility-storage-http-dmx-import-client)
     workspace-id
     topic-id)
  (declare (ignore workspace-id topic-id))
  (if (assignment-auth-available-p-of client)
      (call-next-method)
      (error 'hyperdoc::dmx-import-config-error
             :message
             "Authenticated DMX operation ASSIGN-TOPIC-TO-WORKSPACE requires HYPERDOC_DMX_IMPORT_AUTH_HEADER, HYPERDOC_DMX_IMPORT_USERNAME/HYPERDOC_DMX_IMPORT_PASSWORD, or HYPERDOC_DMX_IMPORT_AUTH_TOKEN"
             :missing-keys '("HYPERDOC_DMX_IMPORT_AUTH_HEADER"
                             "HYPERDOC_DMX_IMPORT_USERNAME"
                             "HYPERDOC_DMX_IMPORT_PASSWORD"
                             "HYPERDOC_DMX_IMPORT_AUTH_TOKEN"))))

(defmethod hyperdoc::dmx-import-update-topic
    ((client failing-topic-update-dmx-import-client)
     existing-topic
     payload)
  (declare (ignore client existing-topic payload))
  (error "Simulated topic update failure"))

(defmethod hyperdoc::dmx-import-update-topic
    ((client auth-blocked-topic-update-dmx-import-client)
     existing-topic
     payload)
  (declare (ignore payload))
  (let* ((topic-id (hyperdoc::dmx-import-object-id existing-topic))
         (path (hyperdoc::dmx-topic-update-path topic-id))
         (url (format nil "~A~A"
                      (hyperdoc::dmx-import-base-url-of client)
                      path)))
    (error 'hyperdoc::dmx-import-http-error
           :message (format nil "DMX import HTTP failure 401 for ~A" url)
           :url url
           :status-code 401
           :response-body "{\"error\":\"annotation-update-unauthorized\"}"
           :evidence
           (list :method :put
                 :path path
                 :auth-mode-summary "anonymous"
                 :authorization-scheme nil
                 :bootstrap-ran-p nil
                 :request-content-type "application/json; charset=utf-8"
                 :response-status-code 401
                 :response-reason-phrase "Unauthorized"
                 :response-body "{\"error\":\"annotation-update-unauthorized\"}"))))

(defmethod hyperdoc::dmx-import-update-topic
    ((client counting-topic-update-compatibility-storage-http-dmx-import-client)
     existing-topic
     payload)
  (incf (topic-update-count-of client))
  (call-next-method))

(defmethod hyperdoc::dmx-import-create-topic
    ((client journal-repair-observing-compatibility-storage-http-dmx-import-client)
     payload)
  (let* ((external-key (or (getf payload :external-key)
                           (getf payload :uri)))
         (journal-p (workspace-annotation-smoke-journal-uri-p external-key))
         (workspace-id (hyperdoc::effective-http-dmx-import-workspace-id client))
         (topic (call-next-method)))
    (when journal-p
      (push (list :topic-id (hyperdoc::dmx-import-object-id topic)
                  :external-key external-key
                  :workspace-id workspace-id)
            (journal-create-observations-of client)))
    topic))

(defmethod hyperdoc::dmx-import-update-topic
    ((client journal-repair-observing-compatibility-storage-http-dmx-import-client)
     existing-topic
     payload)
  (when (workspace-annotation-smoke-journal-topic-object-p existing-topic)
    (push (hyperdoc::dmx-import-object-id existing-topic)
          (journal-update-topic-ids-of client)))
  (call-next-method))

(defmethod hyperdoc::dmx-import-delete-topic
    ((client journal-repair-observing-compatibility-storage-http-dmx-import-client)
     topic-id)
  (when (workspace-annotation-smoke-journal-topic-id-p client topic-id)
    (push topic-id (journal-delete-topic-ids-of client)))
  (call-next-method))

(defmethod hyperdoc::dmx-import-add-topic-to-topicmap
    ((client journal-repair-observing-compatibility-storage-http-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (when (workspace-annotation-smoke-journal-topic-id-p client topic-id)
    (push (list :action :add-to-topicmap
                :topicmap-id topicmap-id
                :topic-id topic-id
                :view-props view-props)
          (journal-placement-observations-of client))
    (when (fail-journal-hidden-placement-p-of client)
      (error "Simulated journal hidden placement failure")))
  (call-next-method))

(defmethod hyperdoc::dmx-import-set-topic-view-props
    ((client journal-repair-observing-compatibility-storage-http-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (when (workspace-annotation-smoke-journal-topic-id-p client topic-id)
    (push (list :action :set-view-props
                :topicmap-id topicmap-id
                :topic-id topic-id
                :view-props view-props)
          (journal-placement-observations-of client))
    (when (fail-journal-hidden-placement-p-of client)
      (error "Simulated journal hidden placement failure")))
  (call-next-method))

(defmethod hyperdoc::dmx-import-create-topic
    ((client latin1-failing-topic-create-dmx-import-client)
     payload)
  (declare (ignore client payload))
  (error "#\\HORIZONTAL_ELLIPSIS (code 8230) is not a LATIN-1 character."))

(defun annotation-journal-event-types (events)
  (mapcar (lambda (event) (gethash "eventType" event))
          (hyperdoc::json-array-elements events)))

(defun dmx-annotation-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun dmx-annotation-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun workspace-annotation-consequence-kinds (comparison)
  (mapcar #'hyperdoc::workspace-annotation-path-consequence-kind-of
          (hyperdoc::workspace-annotation-path-diff-consequences-of
           comparison)))

(defun workspace-annotation-smoke-journal-summary (client annotation)
  (let ((subject-key (hyperdoc::workspace-annotation-topic-uri-of annotation)))
    (hyperdoc::dmx-workspace-journal-preflight-summary
     client
     subject-key
     "uri"
     subject-key
     *dmx-annotations-smoke-workspace-topicmap-id*
     :subject-uri subject-key
     :subject-kind "workspace-annotation"
     :ownership-class "hyperdoc-workspace-annotation")))

(defun workspace-annotation-smoke-journal-topic-id (client annotation)
  (getf (workspace-annotation-smoke-journal-summary client annotation)
        :existing-topic-id))

(defun workspace-annotation-smoke-assign-journal-topic-to-workspace
    (client annotation
     &optional (workspace-id *dmx-annotations-smoke-workspace-id*))
  (let ((journal-topic-id
          (workspace-annotation-smoke-journal-topic-id client annotation)))
    (when journal-topic-id
      (setf (gethash journal-topic-id
                     (hyperdoc::workspace-assignments-of client))
            workspace-id)
      journal-topic-id)))

(defun workspace-annotation-smoke-ensure-assigned-journal-topic
    (client annotation
     &optional (workspace-id *dmx-annotations-smoke-workspace-id*))
  (or (workspace-annotation-smoke-assign-journal-topic-to-workspace
       client
       annotation
       workspace-id)
      (let* ((summary (workspace-annotation-smoke-journal-summary
                       client
                       annotation))
             (subject-key (getf summary :subject-key))
             (lookup-kind (getf summary :subject-lookup-kind))
             (lookup-value (getf summary :subject-lookup-value))
             (workspace-topicmap-id (getf summary :workspace-topicmap-id))
             (journal-uri (getf summary :note-uri))
             (stream
               (hyperdoc::dmx-workspace-journal-make-base-stream
                subject-key
                lookup-kind
                lookup-value
                workspace-topicmap-id
                :subject-uri (getf summary :subject-uri)
                :subject-kind (getf summary :subject-kind)
                :ownership-class (getf summary :ownership-class)
                :note-key (getf summary :note-key)
                :note-kind (getf summary :note-kind)))
             (topic
               (hyperdoc::dmx-import-create-topic
                client
                (hyperdoc::dmx-workspace-note-payload
                 (getf summary :note-title)
                 (hyperdoc::encode-json-string stream)
                 journal-uri)))
             (journal-topic-id (hyperdoc::dmx-import-object-id topic)))
        (setf (gethash journal-topic-id
                       (hyperdoc::workspace-assignments-of client))
              workspace-id)
        journal-topic-id)))

(defun workspace-annotation-smoke-reset-journal-stream-to-base
    (client annotation)
  (let* ((summary (workspace-annotation-smoke-journal-summary client annotation))
         (journal-uri (getf summary :note-uri))
         (subject-key (hyperdoc::workspace-annotation-topic-uri-of annotation))
         (stored-topic
           (and journal-uri
                (gethash journal-uri
                         (hyperdoc::topics-by-external-key-of client))))
         (children (and stored-topic (getf stored-topic :children))))
    (unless (and stored-topic (hash-table-p children))
      (error "Missing stored journal topic for ~A" journal-uri))
    (setf (gethash hyperdoc::*dmx-notes-text-type-uri* children)
          (hyperdoc::encode-json-string
           (hyperdoc::dmx-workspace-journal-make-base-stream
            subject-key
            "uri"
            subject-key
            *dmx-annotations-smoke-workspace-topicmap-id*
            :subject-uri subject-key
            :subject-kind "workspace-annotation"
            :ownership-class "hyperdoc-workspace-annotation")))
    summary))

(defun signal-journal-preflight-http-401 (topic-id)
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
                 :response-body "{\"error\":\"journal-preflight-unauthorized\"}"))))

(defun make-test-dock-annotation (&key note
                                       (context-view-title "Main page")
                                       (source-label "Text pages")
                                       (source-value
                                         "list-item:main-page/text-pages"))
  (let* ((hyperdoc-page (hyperdoc::find-page hyperdoc::*hyperdoc*
                                             "HyperDoc"
                                             :signal-error? t))
         (annotation-from-connect
           (hyperdoc::make-association-annotation-from-json
            :context-object hyperdoc-page
            :context-view-title context-view-title
            :source-json (dock-annotation-source-json "HYPERDOC"
                                                      source-label
                                                      source-value)
            :target-json (dock-annotation-target-json "HYPERDOC"))))
    (hyperdoc::make-dock-annotation
     :context-object hyperdoc-page
     :context-view-title context-view-title
     :source-anchor (hyperdoc::source-anchor-of annotation-from-connect)
     :source-object (hyperdoc::source-object-of annotation-from-connect)
     :target-anchor (hyperdoc::target-anchor-of annotation-from-connect)
     :relation-kind (hyperdoc::relation-kind-of annotation-from-connect)
     :note (or note
               (hyperdoc::note-of annotation-from-connect)))))

(defun run-dmx-workspace-annotation-plan-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation))
         (plan (hyperdoc::plan-dmx-workspace-annotation-write-from-object
                annotation
                :workspace-topicmap-id
                *dmx-annotations-smoke-workspace-topicmap-id*
                :client client))
         (payload (hyperdoc::dmx-workspace-annotation-write-plan-payload plan))
         (children (getf payload :children))
         (source-binding
           (with-input-from-string
               (stream
                (gethash hyperdoc::*dmx-workspace-annotation-source-binding-type-uri*
                         children))
             (shasht:read-json stream)))
         (provenance
           (with-input-from-string
               (stream
                (gethash hyperdoc::*dmx-workspace-annotation-provenance-type-uri*
                         children))
             (shasht:read-json stream))))
    (assert-equal :create
                  (hyperdoc::dmx-workspace-annotation-write-plan-topic-action plan)
                  "Fresh workspace annotation plan must create the DMX topic")
    (assert-equal :assign
                  (hyperdoc::dmx-workspace-annotation-write-plan-workspace-action plan)
                  "Fresh workspace annotation plan must assign the topic to the context-window workspace")
    (assert-equal :add
                  (hyperdoc::dmx-workspace-annotation-write-plan-topicmap-action plan)
                  "Fresh workspace annotation plan must add the annotation to the workspace topicmap")
    (assert-equal "hyperdoc.annotation"
                  (getf payload :type-uri)
                  "Workspace annotation payload must use the typed hyperdoc.annotation family")
    (assert-equal "persisted"
                  (gethash hyperdoc::*dmx-workspace-annotation-status-type-uri*
                           children)
                  "Workspace annotation payload must record a persisted status")
    (assert-equal "919822"
                  (gethash hyperdoc::*dmx-workspace-annotation-workspace-topicmap-type-uri*
                           children)
                  "Workspace annotation payload must persist the workspace topicmap id")
    (assert-true
     (search "\"providerKind\"" (gethash hyperdoc::*dmx-workspace-annotation-source-anchor-json-type-uri*
                                         children))
     "Workspace annotation payload must persist the source anchor JSON")
    (assert-equal "annotation-source-binding"
                  (gethash "bindingType" source-binding)
                  "Workspace annotation payload must record the typed source binding object")
    (assert-equal "source-object"
                  (gethash "role" (gethash "player2" source-binding))
                  "Workspace annotation source binding must keep explicit player roles")
    (assert-equal "dock-annotation"
                  (gethash "savedFrom" provenance)
                  "Workspace annotation provenance must preserve the Dock capture origin")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (hyperdoc::dmx-workspace-annotation-write-plan-workspace-id plan)
                  "Workspace annotation plan must target workspace 919815")))

(defun run-dmx-workspace-annotation-compatibility-plan-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation :note "Compatibility carrier plan"))
         (plan (hyperdoc::plan-dmx-workspace-annotation-write-from-object
                annotation
                :workspace-topicmap-id
                *dmx-annotations-smoke-workspace-topicmap-id*
                :client client
                :storage-mode
                hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*))
         (payload (hyperdoc::dmx-workspace-annotation-write-plan-payload plan))
         (children (getf payload :children))
         (carrier-text (gethash hyperdoc::*dmx-notes-text-type-uri* children))
         (envelope (with-input-from-string (stream carrier-text)
                     (shasht:read-json stream)))
         (native-payload (gethash "nativePayload" envelope))
         (native-children (gethash "children" native-payload))
         (source-binding-json
           (gethash hyperdoc::*dmx-workspace-annotation-source-binding-type-uri*
                    native-children))
         (source-binding
           (and source-binding-json
                (with-input-from-string (stream source-binding-json)
                  (shasht:read-json stream)))))
    (assert-equal hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
                  (hyperdoc::dmx-workspace-annotation-write-plan-storage-mode plan)
                  "Compatibility-storage plan must declare the explicit compatibility storage mode")
    (assert-equal hyperdoc::*dmx-notes-note-type-uri*
                  (getf payload :type-uri)
                  "Compatibility-storage plan must write through the installed dmx.notes.note carrier")
    (assert-equal hyperdoc::*dmx-notes-note-type-uri*
                  (hyperdoc::dmx-workspace-annotation-write-plan-carrier-type-uri plan)
                  "Compatibility-storage plan must record the chosen carrier type")
    (assert-equal "compatibility-note-carrier"
                  (gethash "storageMode" envelope)
                  "Compatibility-storage envelope must persist its deliberate storage mode")
    (assert-equal "hyperdoc.annotation"
                  (gethash "nativeTypeUri" envelope)
                  "Compatibility-storage envelope must preserve the native annotation type identity")
    (assert-equal "hyperdoc.annotation"
                  (gethash "typeUri" native-payload)
                  "Compatibility-storage envelope must carry the full native annotation payload")
    (assert-true
     (search "\"providerKind\""
             (or (gethash hyperdoc::*dmx-workspace-annotation-source-anchor-json-type-uri*
                          native-children)
                 "")
             :test #'char-equal)
     "Compatibility-storage envelope must preserve the source anchor JSON losslessly")
    (assert-equal "annotation-source-binding"
                  (and source-binding
                       (gethash "bindingType" source-binding))
                  "Compatibility-storage envelope must preserve the typed source binding JSON")
    (assert-equal (getf payload :value)
                  (gethash hyperdoc::*dmx-notes-title-type-uri* children)
                  "Compatibility-storage carrier must still expose the annotation title through dmx.notes.title")))

(defun run-dmx-workspace-annotation-dry-run-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation))
         (result (hyperdoc::execute-dmx-workspace-annotation-write-from-object
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client
                  :dry-run t)))
    (assert-true (getf result :dry-run)
                 "Dry-run workspace annotation execution must report dry-run T")
    (assert-equal 0
                  (hash-table-count (hyperdoc::topics-by-external-key-of client))
                  "Dry-run workspace annotation execution must not mutate the topic store")
    (assert-equal 0
                  (hash-table-count (hyperdoc::topicmap-memberships-of client))
                  "Dry-run workspace annotation execution must not mutate topicmap memberships")
    (assert-equal 0
                  (hash-table-count (hyperdoc::workspace-assignments-of client))
                  "Dry-run workspace annotation execution must not mutate workspace assignments")
    (assert-true
     (plusp (length (hyperdoc::json-array-elements
                     (getf result :journal-event-preview))))
     "Dry-run workspace annotation execution must expose a journal event preview")))

(defun live-dmx-annotation-smoke-enabled-p ()
  (string= (or (uiop:getenv "HYPERDOC_RUN_LIVE_DMX_ANNOTATION_TESTS") "")
           "1"))

(defun run-dmx-workspace-annotation-live-create-and-reopen-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation))
         (persisted (hyperdoc::persist-dock-annotation-to-workspace
                     annotation
                     :workspace-topicmap-id
                     *dmx-annotations-smoke-workspace-topicmap-id*
                     :client client
                     :dry-run nil))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of persisted))
         (journal (hyperdoc::read-dmx-topic-journal
                   :workspace-topicmap-id
                   *dmx-annotations-smoke-workspace-topicmap-id*
                   :client client
                   :topic-id topic-id
                   :reconcile nil))
         (event-types (annotation-journal-event-types (gethash "events" journal)))
         (reopened (hyperdoc::read-dmx-workspace-annotation
                    :workspace-topicmap-id
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    :client client
                    :topic-id topic-id)))
    (assert-true (typep persisted 'hyperdoc::workspace-dock-annotation)
                 "Live workspace annotation persistence must reopen as a typed inspectable object")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (hyperdoc::workspace-annotation-workspace-id-of persisted)
                  "Persisted workspace annotations must carry the assigned workspace id")
    (assert-true
     (eq (hyperdoc::target-object-of persisted)
         (hyperdoc::annotation-topic))
     "Persisted workspace annotations must reopen with the Annotation topic as the target object")
    (assert-true
     (member "create-topic" event-types :test #'string=)
     "Workspace annotation journal must record topic creation")
    (assert-true
     (member "add-to-topicmap" event-types :test #'string=)
     "Workspace annotation journal must record topicmap membership")
    (assert-equal (hyperdoc::note-of persisted)
                  (hyperdoc::note-of reopened)
                  "Workspace annotations must reopen by topic id with stable persisted text")))

(defun run-dmx-workspace-annotation-live-smoke-tests ()
  (run-dmx-workspace-annotation-live-create-and-reopen-smoke-test)
  (run-dmx-workspace-annotation-compatibility-live-create-and-reopen-smoke-test)
  (format t "~&DMX workspace annotation live smoke tests passed.~%")
  t)

(defun run-dmx-workspace-annotation-live-smoke-tests-if-enabled ()
  (if (live-dmx-annotation-smoke-enabled-p)
      (run-dmx-workspace-annotation-live-smoke-tests)
      (progn
        (format t "~&DMX workspace annotation live smoke skipped: HYPERDOC_RUN_LIVE_DMX_ANNOTATION_TESTS is not set.~%")
        t)))

(defun run-dmx-workspace-annotation-compatibility-live-create-and-reopen-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation
                      :note "Compatibility carrier persisted text"))
         (persisted (hyperdoc::persist-dock-annotation-to-workspace
                     annotation
                     :workspace-topicmap-id
                     *dmx-annotations-smoke-workspace-topicmap-id*
                     :client client
                     :storage-mode
                     hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
                     :dry-run nil))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of persisted))
         (carrier-topic (hyperdoc::dmx-import-read-topic client topic-id))
         (carrier-text (hyperdoc::dmx-json-child-value
                        carrier-topic
                        hyperdoc::*dmx-notes-text-type-uri*))
         (envelope (with-input-from-string (stream carrier-text)
                     (shasht:read-json stream)))
         (reopened (hyperdoc::read-dmx-workspace-annotation
                    :workspace-topicmap-id
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    :client client
                    :topic-id topic-id)))
    (assert-true (typep persisted 'hyperdoc::workspace-dock-annotation)
                 "Compatibility-storage persistence must still reopen as a workspace-dock-annotation")
    (assert-equal hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
                  (hyperdoc::workspace-annotation-storage-mode-of persisted)
                  "Compatibility-storage reopen must preserve the storage mode on the workspace annotation object")
    (assert-equal hyperdoc::*dmx-notes-note-type-uri*
                  (hyperdoc::dmx-json-object-value carrier-topic "typeUri")
                  "Compatibility-storage live writes must create dmx.notes.note carrier topics")
    (assert-equal "compatibility-note-carrier"
                  (gethash "storageMode" envelope)
                  "Compatibility-storage carrier text must preserve the deliberate storage-mode marker")
    (assert-equal (hyperdoc::note-of persisted)
                  (hyperdoc::note-of reopened)
                  "Compatibility-storage topics must reopen with stable annotation text")
    (assert-equal (hyperdoc::summary-of persisted)
                  (hyperdoc::summary-of reopened)
                  "Compatibility-storage topics must reopen with stable annotation summary")
    (assert-equal (hyperdoc::workspace-annotation-source-object-ref-of persisted)
                  (hyperdoc::workspace-annotation-source-object-ref-of reopened)
                  "Compatibility-storage topics must reopen with stable source bindings")))

(defun run-dmx-workspace-annotation-supersede-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation :note "Initial workspace annotation"))
         (persisted (hyperdoc::persist-dock-annotation-to-workspace
                     annotation
                     :workspace-topicmap-id
                     *dmx-annotations-smoke-workspace-topicmap-id*
                     :client client
                     :dry-run nil))
         (superseding (hyperdoc::supersede-dock-annotation-in-workspace
                       annotation
                       (hyperdoc::workspace-annotation-topic-id-of persisted)
                       :workspace-topicmap-id
                       *dmx-annotations-smoke-workspace-topicmap-id*
                       :client client
                       :dry-run nil)))
    (assert-true
     (/= (hyperdoc::workspace-annotation-topic-id-of persisted)
         (hyperdoc::workspace-annotation-topic-id-of superseding))
     "Superseding a workspace annotation must create a distinct topic")
    (assert-equal (hyperdoc::workspace-annotation-topic-id-of persisted)
                  (hyperdoc::workspace-annotation-supersedes-topic-id-of superseding)
                  "Superseding workspace annotations must persist the typed supersedes binding")
    (assert-equal "superseding"
                  (hyperdoc::workspace-annotation-status-of superseding)
                  "Superseding workspace annotations must keep the superseding status")))

(defun run-dmx-workspace-annotation-restore-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (original (make-test-dock-annotation :note "Original workspace annotation"))
         (persisted (hyperdoc::persist-dock-annotation-to-workspace
                     original
                     :workspace-topicmap-id
                     *dmx-annotations-smoke-workspace-topicmap-id*
                     :client client
                     :dry-run nil))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of persisted))
         (initial-journal
           (handler-case
               (hyperdoc::read-dmx-topic-journal
                :workspace-topicmap-id
                *dmx-annotations-smoke-workspace-topicmap-id*
                :client client
                :topic-id topic-id
                :reconcile nil)
             (hyperdoc::fedwiki-dmx-import-error (condition)
               (format t "~&DMX workspace annotation restore smoke skipped: no matching workspace journal stream for requested subject.~%")
               (format t "  reason: ~A~%" condition)
               (return-from run-dmx-workspace-annotation-restore-smoke-test t))))
         (initial-revision (gethash "currentRevision" initial-journal))
         (updated (make-test-dock-annotation :note "Updated workspace annotation"))
         (updated-persisted (hyperdoc::persist-dock-annotation-to-workspace
                             updated
                             :workspace-topicmap-id
                             *dmx-annotations-smoke-workspace-topicmap-id*
                             :client client
                             :dry-run nil))
         (restore-result (hyperdoc::restore-dmx-workspace-topic-revision
                          :workspace-topicmap-id
                          *dmx-annotations-smoke-workspace-topicmap-id*
                          :client client
                          :topic-id topic-id
                          :revision initial-revision
                          :dry-run nil))
         (restored (hyperdoc::read-dmx-workspace-annotation
                    :workspace-topicmap-id
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    :client client
                    :topic-id topic-id)))
    (declare (ignore updated-persisted))
    (assert-equal "restored"
                  (gethash "status" restore-result)
                  "Workspace annotation restore must complete through the typed workspace journal restore path")
    (assert-equal "Original workspace annotation"
                  (hyperdoc::note-of restored)
                  "Workspace annotation restore must recover the earlier persisted text")))

(defun run-dmx-workspace-annotation-debug-surface-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation))
         (views (dmx-annotation-smoke-load-inspector-views-for-object
                 annotation))
         (workspace-view
           (dmx-annotation-smoke-find-view-by-title views "Workspace"))
         (workspace-html
           (and workspace-view
                (html-inspector-views:view-html workspace-view)))
         (debug (hyperdoc::debug-dock-annotation-workspace-persistence
                 annotation
                 :workspace-topicmap-id
                 *dmx-annotations-smoke-workspace-topicmap-id*
                 :client client))
         (exact-form
           (hyperdoc::workspace-annotation-persistence-debug-exact-form-of
            debug))
         (stepper-source
           (hyperdoc::workspace-annotation-persistence-debug-stepper-source-of
            debug))
         (replayed
           (hyperdoc::persist-dock-annotation-to-workspace
            debug
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client client
            :dry-run nil))
         (stepper
           (clog-moldable-inspector::make-playground-stepper
            annotation
            stepper-source))
         (graph (hyperdoc::workspace-annotation-persistence-debug-graph debug)))
    (assert-true
     (typep debug 'hyperdoc::workspace-annotation-persistence-debug)
     "Debug workspace persistence must return an inspectable debug object")
    (assert-true
     (eq annotation
         (hyperdoc::workspace-annotation-replay-subject debug))
     "Replay subject helper must unwrap persistence debug objects to the underlying annotation")
    (assert-true
     (typep replayed 'hyperdoc::workspace-dock-annotation)
     "Replaying persistence from the debug wrapper must still persist the underlying annotation")
    (assert-equal (hyperdoc::note-of annotation)
                  (hyperdoc::note-of replayed)
                  "Persistence replay from the debug wrapper must preserve the underlying annotation text")
    (assert-true
     (null (search "Debug workspace persistence" workspace-html
                   :test #'char-equal))
     "Workspace annotation primary Workspace view must not expose the old Debug workspace persistence action")
    (assert-true
     (search "Local journal lane" workspace-html :test #'char-equal)
     "Workspace annotation inspector must render the Local journal lane in the Workspace dashboard")
    (assert-true
     (search "DMX context-window lane" workspace-html :test #'char-equal)
     "Workspace annotation inspector must render the DMX context-window lane in the Workspace dashboard")
    (assert-true
     (search "SCXML chart visualization" workspace-html :test #'char-equal)
     "Workspace annotation inspector must render the Workspace-view SCXML chart visualization")
    (assert-true
     (search "Next action panel" workspace-html :test #'char-equal)
     "Workspace annotation inspector must render SCXML-backed next actions")
    (assert-true
     (search "Inspect workspace write plan" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the SCXML-backed Inspect workspace write plan action")
    (assert-true
     (search "Trace workspace write plan" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the Trace workspace write plan action")
    (assert-true
     (search "Check DMX annotation storage support" workspace-html
             :test #'char-equal)
     "Workspace annotation inspector must expose the DMX annotation storage support probe")
    (assert-true
     (search "Probe native DMX create-topic boundary" workspace-html
             :test #'char-equal)
     "Workspace annotation inspector must expose the advanced native create-topic boundary probe")
    (assert-true
     (null (search "Compare with guarded workspace path"
                   workspace-html
                   :test #'char-equal))
     "Workspace annotation inspector primary view must remove the old Compare with guarded workspace path label")
    (assert-true
     (search "919815" workspace-html :test #'char-equal)
     "Workspace annotation dashboard must expose workspace target 919815")
    (assert-true
     (search "919822" workspace-html :test #'char-equal)
     "Workspace annotation dashboard must expose topicmap target 919822")
    (assert-true
     (getf (hyperdoc::workspace-annotation-persistence-debug-dry-run-preview-of
            debug)
           :dry-run)
     "Debug workspace persistence must preload the dry-run preview")
    (assert-true
     (search "persist-dock-annotation-to-workspace"
             exact-form
             :test #'char-equal)
     "Debug workspace persistence must expose the exact persist form")
    (assert-true
     (search "workspace-annotation-replay-subject"
             exact-form
             :test #'char-equal)
     "Debug persistence exact form must unwrap the annotation from a wrapper object explicitly")
    (assert-true
     (null (search "(persist-dock-annotation-to-workspace *"
                   exact-form
                   :test #'char-equal))
     "Debug persistence exact form must not rely on bare * as the annotation subject")
    (assert-true
     (search "plan-dmx-workspace-annotation-write-from-object"
             stepper-source)
     "Debug workspace persistence stepper source must stage the plan form first")
    (assert-true
     (search "workspace-annotation-replay-subject"
             stepper-source
             :test #'char-equal)
     "Debug workspace persistence stepper source must unwrap wrapper subjects before plan or persist replay")
    (assert-true
     (typep stepper 'clog-moldable-inspector::playground-stepper)
     "Debug workspace persistence must be step-throughable through the Playground stepper")
    (assert-true
     (typep graph 'hyperdoc::code-path-graph)
     "Debug workspace persistence must expose a reusable code-path graph")
    (assert-true
     (hyperdoc::code-path-graph-node graph "topicmap-placement")
     "Workspace persistence graph must expose the topicmap placement stage explicitly")))

(defun run-dmx-workspace-annotation-compare-surface-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9310))
         (annotation (make-test-dock-annotation
                      :note "Compare surface smoke"))
         (comparison
           (hyperdoc::compare-dock-annotation-with-guarded-workspace-path
            annotation
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client client))
         (views (dmx-annotation-smoke-load-inspector-views-for-object
                 comparison))
         (path-diff (dmx-annotation-smoke-find-view-by-title views "Path diff"))
         (consequences-view
           (dmx-annotation-smoke-find-view-by-title views "Consequences"))
         (graph-view (dmx-annotation-smoke-find-view-by-title views "Graph"))
         (path-diff-html (and path-diff
                              (html-inspector-views:view-html path-diff)))
         (consequences-html (and consequences-view
                                 (html-inspector-views:view-html
                                  consequences-view)))
         (graph-html (and graph-view
                          (html-inspector-views:view-html graph-view))))
    (assert-true
     (typep comparison 'hyperdoc::workspace-annotation-path-diff)
     "Compare action must construct a workspace-annotation-path-diff object")
    (assert-true
     path-diff
     "Workspace annotation path diff must expose a Path diff view")
    (assert-true
     graph-view
     "Workspace annotation path diff must expose a Graph view")
    (assert-true
     consequences-view
     "Workspace annotation path diff must expose a Consequences view")
    (assert-true
     (stringp path-diff-html)
     "Workspace annotation path diff must render Path diff HTML")
    (assert-true
     (stringp consequences-html)
     "Workspace annotation path diff must render Consequences HTML")
    (assert-true
     (stringp graph-html)
     "Workspace annotation path diff must render Graph HTML")
    (assert-true
     (search "Stage label" path-diff-html :test #'char-equal)
     "Path diff view must render the comparison table header")
    (assert-true
     (search "continue_workspace_annotation" path-diff-html :test #'char-equal)
     "Path diff view must name the guarded continuation tool")
    (assert-true
     (search "repair_workspace_topic_assignment" path-diff-html
             :test #'char-equal)
     "Path diff view must name the guarded assignment tool")
    (assert-true
     (search "upsert_workspace_topicmap_context" path-diff-html
             :test #'char-equal)
     "Path diff view must name the guarded topicmap tool")
    (assert-true
     (search "Workspace assignment and topicmap placement are separate facts"
             path-diff-html
             :test #'char-equal)
     "Path diff view must keep workspace assignment and topicmap placement separate in UI text")
    (assert-true
     (search "Guarded topicmap success does not prove workspace ownership"
             path-diff-html
             :test #'char-equal)
     "Path diff view must not let guarded topicmap success imply workspace ownership")
    (assert-true
     (search "Next steps" path-diff-html :test #'char-equal)
     "Path diff view must expose a next-step consequence section")
    (assert-true
     (search "Consequence kind" consequences-html :test #'char-equal)
     "Consequences view must render the structured consequence table header")
    (assert-true
     (member :review-divergence
             (workspace-annotation-consequence-kinds comparison))
     "Unsaved compare surfaces must still classify the executor divergence explicitly")
    (assert-true
     (search "Main annotation persist path" graph-html :test #'char-equal)
     "Graph view must expose the main annotation persist focused path")
    (assert-true
     (search "Guarded continuation path" graph-html :test #'char-equal)
     "Graph view must expose the guarded continuation focused path")
    (assert-true
     (search "workspace-assignment auth boundary" graph-html
             :test #'char-equal)
     "Graph view must expose the explicit workspace-assignment auth divergence node")
    (assert-true
     (search "review-divergence" graph-html :test #'char-equal)
     "Graph view must render divergence consequences from the shared consequence rows")))

(defun run-dmx-workspace-annotation-debug-report-success-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation))
         (report (hyperdoc::run-dock-annotation-workspace-persistence-debug
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client))
         (exact-form
           (hyperdoc::workspace-annotation-persistence-report-exact-form-of
            report))
         (replayed
           (hyperdoc::persist-dock-annotation-to-workspace
            report
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client client
            :dry-run nil)))
    (assert-true
     (typep report 'hyperdoc::workspace-annotation-persistence-report)
     "Live workspace persistence debug must return an inspectable report")
    (assert-true
     (eq annotation
         (hyperdoc::workspace-annotation-replay-subject report))
     "Replay subject helper must unwrap persistence report objects to the underlying annotation")
    (assert-equal :persisted
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   report)
                  "Successful live workspace persistence debug must classify the run as persisted")
    (assert-equal nil
                  (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                   report)
                  "Successful live workspace persistence debug must not report a failure stage")
    (assert-true
     (typep (hyperdoc::workspace-annotation-persistence-report-persisted-annotation-of
             report)
            'hyperdoc::workspace-dock-annotation)
     "Successful live workspace persistence debug must reopen the persisted annotation")
    (assert-true
     (typep replayed 'hyperdoc::workspace-dock-annotation)
     "Replaying persistence from the report wrapper must still persist the underlying annotation")
    (assert-equal (hyperdoc::note-of annotation)
                  (hyperdoc::note-of replayed)
                  "Persistence replay from the report wrapper must preserve the underlying annotation text")
    (assert-true
     (search "workspace-annotation-replay-subject"
             exact-form
             :test #'char-equal)
     "Persistence report exact form must unwrap the annotation from a wrapper object explicitly")
    (assert-true
     (null (search "(persist-dock-annotation-to-workspace *"
                   exact-form
                   :test #'char-equal))
     "Persistence report exact form must not rely on bare * as the annotation subject")
    (assert-true
     (getf (hyperdoc::workspace-annotation-persistence-report-raw-result-of
            report)
           :topic-id)
     "Successful live workspace persistence debug must expose the persisted topic id in the raw result")))

(defun run-dmx-workspace-annotation-debug-report-failure-smoke-test ()
  (let* ((client (make-instance 'failing-topicmap-placement-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation))
         (report (hyperdoc::run-dock-annotation-workspace-persistence-debug
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client))
         (failure-stage
           (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
            report))
         (topic-upsert
           (hyperdoc::workspace-annotation-persistence-stage-result
            report
            :topic-upsert))
         (topicmap-placement
           (hyperdoc::workspace-annotation-persistence-stage-result
            report
            :topicmap-placement)))
    (assert-equal :failed
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   report)
                  "Topicmap placement failure must surface as a failed persistence report")
    (assert-equal :topicmap-placement
                  failure-stage
                  "Topicmap placement failures must be classified at the topicmap-placement stage")
    (assert-equal :completed
                  (getf topic-upsert :status)
                  "The report must preserve earlier completed stages before the failure")
    (assert-equal :error
                  (getf topicmap-placement :status)
                  "The report must mark the failing topicmap placement stage as error")
    (assert-true
     (search "Simulated topicmap placement failure"
             (format nil "~A"
                     (hyperdoc::workspace-annotation-persistence-report-condition-of
                      report)))
     "The report must preserve the live condition text")
    (assert-true
     (search "persist-dock-annotation-to-workspace"
             (hyperdoc::workspace-annotation-persistence-report-exact-form-of
              report)
             :test #'char-equal)
     "The report must preserve the exact persist form that was attempted")))

(defun run-dmx-workspace-annotation-unicode-transport-diagnostics-smoke-test ()
  (let* ((client (make-instance 'latin1-failing-topic-create-dmx-import-client
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation
                      :note "Unicode ellipsis … in workspace note"))
         (report (hyperdoc::run-dock-annotation-workspace-persistence-debug
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client))
         (diagnostics
           (hyperdoc::workspace-annotation-persistence-report-transport-diagnostics-of
            report)))
    (assert-equal :failed
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   report)
                  "Unicode transport failures must still return a failed inspectable report")
    (assert-equal :topic-upsert
                  (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                   report)
                  "Unicode transport failures must classify at the topic-upsert stage")
    (assert-equal :topic-upsert
                  (getf diagnostics :transport-stage)
                  "Transport diagnostics must preserve the stage that reached the Latin-1 boundary")
    (assert-equal :text
                  (getf diagnostics :field)
                  "Transport diagnostics must identify the first failing string field")
    (assert-equal "…"
                  (getf diagnostics :character)
                  "Transport diagnostics must preserve the exact failing Unicode character")
    (assert-equal 8230
                  (getf diagnostics :code-point)
                  "Transport diagnostics must preserve the Unicode code point")))

(defun run-dmx-workspace-annotation-destination-default-resolution-smoke-test ()
  (let* ((annotation (make-test-dock-annotation :note "Default destination"))
         (destination
           (hyperdoc::resolve-dmx-workspace-annotation-destination
            annotation
            :client (make-instance 'hyperdoc::memory-dmx-import-client
                                   :next-topic-id 9300)))
         (preview
           (hyperdoc::workspace-annotation-persistence-preview
            annotation
            nil
            :client (make-instance 'hyperdoc::memory-dmx-import-client
                                   :next-topic-id 9301))))
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (hyperdoc::dmx-workspace-annotation-destination-workspace-id
                   destination)
                  "Default destination resolution must still fall back to the context-window workspace when nothing more specific exists")
    (assert-equal *dmx-annotations-smoke-workspace-topicmap-id*
                  (hyperdoc::dmx-workspace-annotation-destination-workspace-topicmap-id
                   destination)
                  "Default destination resolution must still fall back to the context-window topicmap when nothing more specific exists")
    (assert-equal :context-window-default
                  (hyperdoc::dmx-workspace-annotation-destination-source
                   destination)
                  "Default destination resolution must classify the context-window destination as a fallback")
    (assert-equal "context-window default fallback"
                  (getf preview :destination-source-label)
                  "Dry-run preview must expose the destination source label explicitly")
    (assert-equal *dmx-annotations-smoke-workspace-topicmap-id*
                  (getf preview :workspace-topicmap-id)
                  "Dry-run preview must expose the chosen workspace topicmap explicitly")
    (assert-true
     (search "context-window collaboration surface"
             (or (getf preview :destination-rationale) "")
             :test #'char-equal)
     "Dry-run preview must explain why the fallback destination was chosen")))

(defun run-dmx-workspace-annotation-destination-persisted-reuse-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9300))
         (persisted (hyperdoc::persist-dock-annotation-to-workspace
                     (make-test-dock-annotation :note "Persisted destination")
                     :workspace-topicmap-id
                     *dmx-annotations-smoke-workspace-topicmap-id*
                     :client client
                     :dry-run nil))
         (other-client
           (make-instance 'hyperdoc::http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :workspace-id 999111))
         (destination
           (hyperdoc::resolve-dmx-workspace-annotation-destination
            persisted
            :client other-client)))
    (assert-equal (hyperdoc::workspace-annotation-workspace-id-of persisted)
                  (hyperdoc::dmx-workspace-annotation-destination-workspace-id
                   destination)
                  "Persisted annotation updates must reuse their own workspace destination coherently")
    (assert-equal (hyperdoc::workspace-annotation-topicmap-id-of persisted)
                  (hyperdoc::dmx-workspace-annotation-destination-workspace-topicmap-id
                   destination)
                  "Persisted annotation updates must reuse their own topicmap destination coherently")
    (assert-equal :persisted-annotation-destination
                  (hyperdoc::dmx-workspace-annotation-destination-source
                   destination)
                  "Persisted annotation updates must classify destination reuse explicitly")))

(defun run-dmx-workspace-annotation-destination-explicit-override-smoke-test ()
  (let* ((annotation (make-test-dock-annotation :note "Explicit destination"))
         (destination
           (hyperdoc::resolve-dmx-workspace-annotation-destination
            annotation
            :workspace-id 999001
            :workspace-topicmap-id 999002
            :client (make-instance 'hyperdoc::http-dmx-import-client
                                   :base-url "https://dmx.ralfbarkow.ch"
                                   :workspace-id *dmx-annotations-smoke-workspace-id*))))
    (assert-equal 999001
                  (hyperdoc::dmx-workspace-annotation-destination-workspace-id
                   destination)
                  "Explicit workspace overrides must win over fallback destination resolution")
    (assert-equal 999002
                  (hyperdoc::dmx-workspace-annotation-destination-workspace-topicmap-id
                   destination)
                  "Explicit topicmap overrides must win over fallback destination resolution")
    (assert-equal :explicit-user-choice
                  (hyperdoc::dmx-workspace-annotation-destination-source
                   destination)
                  "Explicit workspace/topicmap overrides must classify as explicit user choice")))

(defun run-dmx-workspace-annotation-backend-compatibility-probe-smoke-test ()
  (let* ((client (make-instance 'compatibility-storage-http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer test-token"
                                :workspace-id *dmx-annotations-smoke-workspace-id*))
         (annotation (make-test-dock-annotation
                      :note "Backend compatibility probe")))
    (let* ((report (hyperdoc::probe-live-workspace-annotation-type-support
                    annotation
                    :workspace-topicmap-id
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    :client client))
           (exact-form
             (hyperdoc::workspace-annotation-backend-compatibility-report-exact-form-of
              report))
           (evidence
             (hyperdoc::workspace-annotation-backend-compatibility-report-http-evidence-of
              report))
           (replayed-report
             (hyperdoc::probe-live-workspace-annotation-type-support
              report
              :workspace-topicmap-id
              *dmx-annotations-smoke-workspace-topicmap-id*
              :client client)))
      (assert-true
       (typep report 'hyperdoc::workspace-annotation-backend-compatibility-report)
       "Backend compatibility probe must return an inspectable report")
      (assert-true
       (eq annotation
           (hyperdoc::workspace-annotation-backend-compatibility-report-annotation-of
            report))
       "Direct backend compatibility probes must preserve the underlying dock annotation")
      (assert-equal :compatible-via-carrier
                    (hyperdoc::workspace-annotation-backend-compatibility-report-status-of
                     report)
                    "When raw hyperdoc.annotation is unsupported but dmx.notes.note is available, the live path must classify as compatibility-carrier supported")
      (assert-true
       (typep replayed-report
              'hyperdoc::workspace-annotation-backend-compatibility-report)
       "Replaying the backend compatibility probe from its report object must still return an inspectable report")
      (assert-true
       (eq annotation
           (hyperdoc::workspace-annotation-backend-compatibility-report-annotation-of
            replayed-report))
       "Backend compatibility probe replay must unwrap the underlying annotation instead of probing the report object itself")
      (assert-equal hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
                    (hyperdoc::workspace-annotation-backend-compatibility-report-selected-storage-mode-of
                     report)
                    "Compatibility report must preserve the selected compatibility storage mode")
      (assert-equal hyperdoc::*dmx-notes-note-type-uri*
                    (hyperdoc::workspace-annotation-backend-compatibility-report-carrier-type-uri-of
                     report)
                    "Compatibility report must make the chosen carrier explicit")
      (assert-equal hyperdoc::*dmx-workspace-annotation-type-uri*
                    (hyperdoc::workspace-annotation-backend-compatibility-report-native-failing-type-uri-of
                     report)
                    "Compatibility report must preserve the unsupported raw hyperdoc.annotation type")
      (assert-equal t
                    (hyperdoc::workspace-annotation-backend-compatibility-report-carrier-supported-p-of
                     report)
                    "Compatibility report must record that the installed carrier type family is available")
      (assert-equal "/core/topic"
                    (hyperdoc::workspace-annotation-backend-compatibility-report-endpoint-path-of
                     report)
                    "Compatibility report must preserve the create-topic endpoint that would be used")
      (assert-equal "/core/topic/uri/hyperdoc.annotation?children=true&assocChildren=true"
                    (getf evidence :path)
                    "Compatibility report must preserve the raw parent type probe path")
      (assert-equal "Bearer header"
                    (getf evidence :auth-mode-summary)
                    "Compatibility report must preserve the outgoing auth mode")
      (assert-equal nil
                    (getf evidence :bootstrap-ran-p)
                    "Compatibility report must show that no bootstrap login happened")
      (assert-true
       (search "Topic type \\\"hyperdoc.annotation\\\" not found in DB"
               (or (hyperdoc::workspace-annotation-backend-compatibility-report-known-create-topic-response-body-of
                    report)
                   "")
               :test #'char-equal)
       "Compatibility report must preserve the known raw create-topic backend cause when available")
      (assert-true
       (find-if (lambda (action)
                  (search "compatibility storage"
                          action
                          :test #'char-equal))
                (hyperdoc::workspace-annotation-backend-compatibility-report-next-actions-of
                 report))
       "Compatibility report must state that the normal live path will use compatibility storage")
      (assert-true
       (search "workspace-annotation-backend-compatibility-report-annotation-of"
               exact-form
               :test #'char-equal)
       "Backend compatibility probe exact form must unwrap the annotation from the report object explicitly")
      (assert-true
       (null (search "(probe-live-workspace-annotation-type-support *"
                     exact-form
                     :test #'char-equal))
       "Backend compatibility probe exact form must not rely on bare * as the probe subject"))))

(defun run-dmx-http-unicode-json-request-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"))
         (payload (list :type-uri "hyperdoc.annotation"
                        :uri "hyperdoc:mcp/workspace-annotation/unicode-smoke"
                        :value "Unicode … probe"
                        :children
                        (let ((children (make-hash-table :test #'equal)))
                          (setf (gethash hyperdoc::*dmx-workspace-annotation-text-type-uri*
                                         children)
                                "Body with ellipsis … here")
                          children)))
         (captured-args nil)
         (original (symbol-function 'drakma:http-request)))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (&rest args)
                   (setf captured-args args)
                   (values (make-string-input-stream "{\"id\":9300}")
                           200
                           nil
                           nil
                           nil
                           nil)))
           (hyperdoc::dmx-import-create-topic client payload))
      (setf (symbol-function 'drakma:http-request) original))
    (let ((content (getf (cdr captured-args) :content))
          (content-type (getf (cdr captured-args) :content-type))
          (content-length (getf (cdr captured-args) :content-length)))
      (assert-true
       (vectorp content)
       "Live DMX JSON writes must encode request content as octets before reaching Drakma")
      (assert-equal "application/json; charset=utf-8"
                    content-type
                    "Live DMX JSON writes must declare UTF-8 explicitly")
      (assert-equal (length content)
                    content-length
                    "Live DMX JSON writes must use the encoded octet length")
      (assert-true
       (search "Unicode … probe"
               (babel:octets-to-string content :encoding :utf-8)
               :test #'char-equal)
       "Live DMX JSON writes must preserve Unicode ellipsis content through UTF-8 encoding"))))

(defun run-dmx-workspace-annotation-live-create-topic-failure-evidence-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer test-token"
                                :workspace-id *dmx-annotations-smoke-workspace-id*))
         (annotation (make-test-dock-annotation :note "Probe live create-topic"))
         (original (symbol-function 'drakma:http-request)))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method want-stream content-type content
                             content-length additional-headers
                             &allow-other-keys)
                   (declare (ignore want-stream content-length))
                   (cond
                     ((search "/core/topic/uri/" url)
                      (values (make-string-input-stream "")
                              404
                              '(("Content-Type" . "application/json"))
                              nil nil "Not Found"))
                     ((search "/core/topic" url)
                      (assert-equal :post method
                                    "Create-topic probe must POST the DMX topic create endpoint")
                      (assert-equal "application/json; charset=utf-8"
                                    content-type
                                    "Create-topic probe must declare UTF-8 JSON writes")
                      (assert-equal "Bearer test-token"
                                    (cdr (assoc "Authorization"
                                                additional-headers
                                                :test #'string-equal))
                                    "Create-topic probe must preserve the configured auth header")
                      (assert-true
                       (search "\"typeUri\": \"hyperdoc.annotation\""
                               (babel:octets-to-string content :encoding :utf-8)
                               :test #'char-equal)
                       "Create-topic probe must send the typed hyperdoc.annotation payload")
                      (values (make-string-input-stream "{\"error\":\"validation failed\",\"field\":\"children\"}")
                              500
                              '(("Content-Type" . "application/json")
                                ("WWW-Authenticate" . "Bearer realm=dmx"))
                              nil nil "Internal Server Error"))
                     (t
                      (error "Unexpected create-topic probe HTTP call ~S" url)))))
           (let* ((probe (hyperdoc::probe-live-create-topic-for-dock-annotation
                          annotation
                          :workspace-topicmap-id
                          *dmx-annotations-smoke-workspace-topicmap-id*
                          :client client))
                  (exact-form
                    (hyperdoc::workspace-annotation-create-topic-probe-exact-form-of
                     probe))
                  (probe-evidence
                    (hyperdoc::workspace-annotation-create-topic-probe-http-evidence-of
                     probe))
                  (replayed-probe
                    (hyperdoc::probe-live-create-topic-for-dock-annotation
                     probe
                     :workspace-topicmap-id
                     *dmx-annotations-smoke-workspace-topicmap-id*
                     :client client))
                  (report (hyperdoc::run-dock-annotation-workspace-persistence-debug
                           annotation
                           :workspace-topicmap-id
                           *dmx-annotations-smoke-workspace-topicmap-id*
                           :client client
                           :storage-mode
                           hyperdoc::*dmx-workspace-annotation-native-storage-mode*))
                  (report-condition
                    (hyperdoc::workspace-annotation-persistence-report-condition-of
                     report))
                  (failure-stage
                    (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                     report))
                  (report-evidence
                    (hyperdoc::workspace-annotation-persistence-report-topic-upsert-evidence-of
                     report)))
             (when (eq failure-stage :prepare-transition)
               (format t "~&DMX workspace annotation create-topic failure evidence smoke skipped: preconditions not met before topic-upsert (failure-stage=:prepare-transition).~%")
               (when report-condition
                 (format t "  reason: ~A~%" report-condition))
               (return-from run-dmx-workspace-annotation-live-create-topic-failure-evidence-smoke-test
                 t))
             (assert-true
              (typep probe 'hyperdoc::workspace-annotation-create-topic-probe-report)
              "Create-topic probe must return an inspectable probe report")
             (assert-true
              (eq annotation
                  (hyperdoc::workspace-annotation-create-topic-probe-annotation-of
                   probe))
              "Direct create-topic probes must preserve the underlying dock annotation")
             (assert-equal :failed
                           (hyperdoc::workspace-annotation-create-topic-probe-status-of
                            probe)
                           "Create-topic probe must classify a 500 as failed")
             (assert-true
              (typep replayed-probe
                     'hyperdoc::workspace-annotation-create-topic-probe-report)
              "Replaying the create-topic probe from its report object must still return an inspectable probe report")
             (assert-true
              (eq annotation
                  (hyperdoc::workspace-annotation-create-topic-probe-annotation-of
                   replayed-probe))
              "Create-topic probe replay must unwrap the underlying annotation instead of probing the report object itself")
             (assert-equal "/core/topic"
                           (getf probe-evidence :path)
                           "Create-topic probe evidence must preserve the normalized endpoint path")
             (assert-equal "Bearer header"
                           (getf probe-evidence :auth-mode-summary)
                           "Create-topic probe evidence must classify the outgoing auth mode")
             (assert-equal nil
                           (getf probe-evidence :bootstrap-ran-p)
                           "Create-topic probe must show that no bootstrap login happened")
             (assert-equal 500
                           (getf probe-evidence :response-status-code)
                           "Create-topic probe evidence must preserve the failing response status")
             (assert-equal "Internal Server Error"
                           (getf probe-evidence :response-reason-phrase)
                           "Create-topic probe evidence must preserve the reason phrase")
             (assert-true
              (search "\"validation failed\""
                      (or (getf probe-evidence :response-body) "")
                      :test #'char-equal)
              "Create-topic probe evidence must preserve the response body")
             (assert-true
              (search "\"hyperdoc.annotation.text\""
                      (or (hyperdoc::workspace-annotation-create-topic-probe-payload-json-of
                           probe)
                          "")
                      :test #'char-equal)
              "Create-topic probe must preserve the exact outgoing payload JSON")
             (assert-true
              (search "workspace-annotation-create-topic-probe-annotation-of"
                      exact-form
                      :test #'char-equal)
              "Create-topic probe exact form must unwrap the annotation from the report object explicitly")
             (assert-true
              (null (search "(probe-live-create-topic-for-dock-annotation *"
                            exact-form
                            :test #'char-equal))
              "Create-topic probe exact form must not rely on bare * as the probe subject")
             (assert-equal :failed
                           (hyperdoc::workspace-annotation-persistence-report-status-of
                            report)
                           "Full persistence debug must still fail when create-topic fails")
             (assert-equal :topic-upsert
                           failure-stage
                           "Full persistence debug must classify the live 500 at topic-upsert")
             (assert-equal "/core/topic"
                           (getf report-evidence :path)
                           "Persistence report must thread the same create-topic evidence")
             (assert-equal 500
                           (getf report-evidence :response-status-code)
                           "Persistence report must preserve the failing create-topic status")
             (assert-true
              (search "\"field\":\"children\""
                      (or (getf report-evidence :response-body) "")
                      :test #'char-equal)
              "Persistence report must preserve the backend response body for topic-upsert failures")))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-workspace-annotation-create-topic-probe-render-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer test-token"
                                :workspace-id *dmx-annotations-smoke-workspace-id*))
         (annotation (make-test-dock-annotation :note "Probe render with T"))
         (original (symbol-function 'drakma:http-request)))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method want-stream content-type content
                             content-length additional-headers
                             &allow-other-keys)
                   (declare (ignore method
                                    want-stream
                                    content-type
                                    content
                                    content-length
                                    additional-headers))
                   (cond
                     ((search "/core/topic/uri/" url)
                      (values (make-string-input-stream "")
                              404
                              '(("Content-Type" . "application/json"))
                              nil nil "Not Found"))
                     ((search "/core/topic" url)
                      ;; Live Drakma evidence can carry a boolean reason phrase.
                      (values (make-string-input-stream
                               "{\"error\":\"validation failed\",\"field\":\"children\"}")
                              500
                              '(("Content-Type" . "application/json")
                                ("Set-Cookie" . "JSESSIONID=abc123; Path=/"))
                              nil
                              nil
                              t))
                     (t
                      (error "Unexpected create-topic probe render HTTP call ~S"
                             url)))))
           (let* ((probe (hyperdoc::probe-live-create-topic-for-dock-annotation
                          annotation
                          :workspace-topicmap-id
                          *dmx-annotations-smoke-workspace-topicmap-id*
                          :client client))
                  (views (dmx-annotation-smoke-load-inspector-views-for-object
                          probe))
                  (overview
                    (dmx-annotation-smoke-find-view-by-title views "Overview"))
                  (html (and overview
                             (html-inspector-views:view-html overview))))
             (assert-true
              (typep probe 'hyperdoc::workspace-annotation-create-topic-probe-report)
              "Create-topic probe render smoke must build the inspectable probe report")
             (assert-true
              overview
              "Create-topic probe render smoke must find the Overview view")
             (assert-true
              (stringp html)
              "Create-topic probe Overview must render to HTML even when response-reason-phrase is T")
             (assert-true
              (search "/core/topic" html :test #'char-equal)
              "Rendered create-topic probe Overview must preserve the endpoint path")
             (assert-true
              (search "validation failed" html :test #'char-equal)
              "Rendered create-topic probe Overview must preserve the response body")))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-workspace-annotation-default-live-client-resolution-smoke-test ()
  (let ((original
          (symbol-function
           'hyperdoc::make-http-dmx-import-client-from-environment)))
    (unwind-protect
         (progn
           (setf (symbol-function
                  'hyperdoc::make-http-dmx-import-client-from-environment)
                 (lambda (&key verbose)
                   (declare (ignore verbose))
                   nil))
           (let ((client
                   (hyperdoc::resolve-dmx-workspace-annotation-client
                    :dry-run nil
                    :verbose nil)))
             (assert-true
              (typep client 'hyperdoc::http-dmx-import-client)
              "Live workspace annotation client resolution must fall back to an HTTP client when no environment DMX client is configured")
             (assert-true
              (not (typep client 'hyperdoc::null-dmx-import-client))
              "Live workspace annotation client resolution must not leave non-dry-run persistence on the null client")
             (assert-equal hyperdoc::*dmx-base-url*
                           (hyperdoc::dmx-import-base-url-of client)
                           "Live workspace annotation client resolution must fall back to HyperDoc's known DMX base URL")
             (assert-equal nil
                           (hyperdoc::dmx-import-authorization-header-of client)
                           "Fallback live client resolution must keep anonymous create-topic possible when no auth is configured")))
      (setf (symbol-function
             'hyperdoc::make-http-dmx-import-client-from-environment)
            original))))

(defun run-dmx-workspace-annotation-environment-basic-service-auth-smoke-test ()
  (let* ((annotation (make-test-dock-annotation
                      :note "Environment Basic service auth"))
         (created-topic-id 9300)
         (captured-calls '())
         (created-topic nil)
         (assigned-workspace-id nil)
         (added-topicmap-id nil)
         (added-view-props nil)
         (env-values
           (list (cons "HYPERDOC_DMX_IMPORT_BASE_URL"
                       "https://dmx.ralfbarkow.ch")
                 (cons "HYPERDOC_DMX_IMPORT_USERNAME" "shared-service-user")
                 (cons "HYPERDOC_DMX_IMPORT_PASSWORD" "shared-service-password")
                 (cons "HYPERDOC_DMX_IMPORT_WORKSPACE_ID"
                       (format nil "~D"
                               *dmx-annotations-smoke-workspace-id*))))
         (original-getenv (symbol-function 'hyperdoc::getenv-non-empty))
         (original-request (symbol-function 'drakma:http-request))
         (original-journal-suppressed-p
           hyperdoc::*dmx-workspace-journal-suppressed-p*))
    (labels ((env-value (name)
               (cdr (assoc name env-values :test #'string=)))
             (header-value (headers name)
               (cdr (find name headers
                          :test #'string-equal
                          :key #'car)))
             (content-string (content)
               (cond
                 ((null content) "")
                 ((stringp content) content)
                 ((vectorp content)
                  (babel:octets-to-string content :encoding :utf-8))
                 (t
                  (format nil "~A" content))))
             (content-json (content)
               (with-input-from-string (stream (content-string content))
                 (shasht:read-json stream)))
             (json-object (&rest key-values)
               (let ((json (make-hash-table :test #'equal)))
                 (loop for (key value) on key-values by #'cddr
                       do (setf (gethash key json) value))
                 json))
             (json-stream (object)
               (make-string-input-stream
                (hyperdoc::encode-json-string object)))
             (workspace-json ()
               (json-object "id" *dmx-annotations-smoke-workspace-id*
                            "uri" ""
                            "typeUri" "dmx.workspaces.workspace"
                            "value" "context-window"))
             (topicmap-memberships-json ()
               (if (eql added-topicmap-id
                        *dmx-annotations-smoke-workspace-topicmap-id*)
                   (vector
                    (json-object "id"
                                 *dmx-annotations-smoke-workspace-topicmap-id*
                                 "value" "context-window"
                                 "assoc" (json-object "id" 1)))
                   #()))
             (topicmap-json ()
               (json-object
                "topic" (json-object
                         "id" *dmx-annotations-smoke-workspace-topicmap-id*
                         "uri" ""
                         "typeUri" "dmx.topicmaps.topicmap"
                         "value" "context-window")
                "viewProps" (json-object)
                "topics"
                (if (and created-topic
                         (eql added-topicmap-id
                              *dmx-annotations-smoke-workspace-topicmap-id*))
                    (vector
                     (json-object
                      "id" created-topic-id
                      "uri" (gethash "uri" created-topic)
                      "typeUri" (gethash "typeUri" created-topic)
                      "value" (gethash "value" created-topic)
                      "viewProps" (or added-view-props (json-object))))
                    #())
                "assocs" #())))
      (unwind-protect
           (progn
             ;; The production path may maintain workspace-journal state for
             ;; annotation subjects. This smoke intentionally proves only that
             ;; environment-backed Basic service auth now bootstraps correctly
             ;; for the ordinary shared-workspace assignment path.
             (setf hyperdoc::*dmx-workspace-journal-suppressed-p* t)
             (setf (symbol-function 'hyperdoc::getenv-non-empty)
                   (lambda (name)
                     (env-value name)))
             (setf (symbol-function 'drakma:http-request)
                   (lambda (url &key method additional-headers content content-type
                               content-length want-stream
                               &allow-other-keys)
                     (declare (ignore want-stream content-type content-length))
                     (push (list :url url
                                 :method method
                                 :headers additional-headers
                                 :content content)
                           captured-calls)
                     (cond
                       ((and (eq method :get)
                             (search
                              (hyperdoc::dmx-topic-uri-lookup-path
                               hyperdoc::*dmx-workspace-annotation-type-uri*)
                              url
                              :test #'char-equal))
                        (values (make-string-input-stream "")
                                404 nil nil nil "Not Found"))
                       ((and (eq method :get)
                             (search
                              (hyperdoc::dmx-topic-uri-lookup-path
                               hyperdoc::*dmx-notes-note-type-uri*)
                              url
                              :test #'char-equal))
                        (values (json-stream
                                 (make-type-support-topic-json
                                  hyperdoc::*dmx-notes-note-type-uri*))
                                200 nil nil nil "OK"))
                       ((and (eq method :get)
                             (search
                              (hyperdoc::dmx-topic-uri-lookup-path
                               hyperdoc::*dmx-notes-title-type-uri*)
                              url
                              :test #'char-equal))
                        (values (json-stream
                                 (make-type-support-topic-json
                                  hyperdoc::*dmx-notes-title-type-uri*))
                                200 nil nil nil "OK"))
                       ((and (eq method :get)
                             (search
                              (hyperdoc::dmx-topic-uri-lookup-path
                               hyperdoc::*dmx-notes-text-type-uri*)
                              url
                              :test #'char-equal))
                        (values (json-stream
                                 (make-type-support-topic-json
                                  hyperdoc::*dmx-notes-text-type-uri*))
                                200 nil nil nil "OK"))
                       ((and (eq method :get)
                             (search "/core/topic/uri/" url :test #'char-equal))
                        (values (make-string-input-stream "")
                                404 nil nil nil "Not Found"))
                       ((and (eq method :post)
                             (search (hyperdoc::dmx-topic-create-path)
                                     url
                                     :test #'char-equal))
                        (setf created-topic (content-json content)
                              (gethash "id" created-topic) created-topic-id)
                        (values (json-stream created-topic)
                                200 nil nil nil "OK"))
                       ((and (eq method :post)
                             (search "/access-control/login"
                                     url
                                     :test #'char-equal))
                        (values nil
                                204
                                '(("Set-Cookie"
                                   . "JSESSIONID=session-123;Path=/;SameSite=Strict"))
                                nil nil "No Content"))
                       ((and (eq method :put)
                             (search
                              (hyperdoc::dmx-workspace-assign-object-path
                               *dmx-annotations-smoke-workspace-id*
                               created-topic-id)
                              url
                              :test #'char-equal))
                        (setf assigned-workspace-id
                              *dmx-annotations-smoke-workspace-id*)
                        (values (make-string-input-stream "")
                                204 nil nil nil "No Content"))
                       ((and (eq method :post)
                             (search
                              (hyperdoc::dmx-topicmap-add-topic-path
                               *dmx-annotations-smoke-workspace-topicmap-id*
                               created-topic-id)
                              url
                              :test #'char-equal))
                        (setf added-topicmap-id
                              *dmx-annotations-smoke-workspace-topicmap-id*
                              added-view-props
                              (content-json content))
                        (values (make-string-input-stream "")
                                204 nil nil nil "No Content"))
                       ((and (eq method :get)
                             (search
                              (format nil "~A?"
                                      (hyperdoc::dmx-topic-update-path
                                       created-topic-id))
                              url
                              :test #'char-equal))
                        (values (json-stream created-topic)
                                200 nil nil nil "OK"))
                       ((and (eq method :get)
                             (search
                              (hyperdoc::dmx-workspace-object-path
                               created-topic-id)
                              url
                              :test #'char-equal))
                        (if assigned-workspace-id
                            (values (json-stream (workspace-json))
                                    200 nil nil nil "OK")
                            (values (make-string-input-stream "")
                                    404 nil nil nil "Not Found")))
                       ((and (eq method :get)
                             (search
                              (hyperdoc::dmx-topicmap-memberships-path
                               created-topic-id)
                              url
                              :test #'char-equal))
                        (values (json-stream (topicmap-memberships-json))
                                200 nil nil nil "OK"))
                       ((and (eq method :get)
                             (search
                              (format nil "/topicmaps/~D?children=true"
                                      *dmx-annotations-smoke-workspace-topicmap-id*)
                              url
                              :test #'char-equal))
                        (values (json-stream (topicmap-json))
                                200 nil nil nil "OK"))
                       (t
                        (error "Unexpected workspace-annotation HTTP call ~S"
                               url)))))
             (let* ((report
                      (hyperdoc::run-dock-annotation-workspace-persistence-debug
                       annotation
                       :workspace-topicmap-id
                       *dmx-annotations-smoke-workspace-topicmap-id*))
                    (client
                      (hyperdoc::workspace-annotation-persistence-report-client-of
                       report))
                    (persisted
                      (hyperdoc::workspace-annotation-persistence-report-persisted-annotation-of
                       report))
                    (assignment-stage
                      (hyperdoc::workspace-annotation-persistence-stage-result
                       report
                       :workspace-assignment))
                    (calls (nreverse captured-calls))
                    (login-position
                      (position-if
                       (lambda (call)
                         (search "/access-control/login"
                                 (getf call :url)
                                 :test #'char-equal))
                       calls))
                    (assignment-position
                      (position-if
                       (lambda (call)
                         (search
                          (hyperdoc::dmx-workspace-assign-object-path
                           *dmx-annotations-smoke-workspace-id*
                           created-topic-id)
                          (getf call :url)
                          :test #'char-equal))
                       calls))
                    (login-call
                      (and login-position
                           (nth login-position calls)))
                    (assignment-call
                      (and assignment-position
                           (nth assignment-position calls))))
               (assert-true
                (typep client 'hyperdoc::http-dmx-import-client)
                "No-client live writes with environment service auth must resolve to the HTTP DMX client")
               (assert-equal t
                             (and (hyperdoc::dmx-import-session-login-required-p-of
                                   client)
                                  t)
                             "Environment-built Basic shared service auth must require the same session bootstrap flag as explicit Basic auth")
               (assert-true
                (search "Basic "
                        (or (hyperdoc::dmx-import-authorization-header-of client)
                            "")
                        :test #'char-equal)
                "Environment-built shared service auth must still carry the Basic Authorization header before bootstrap")
               (assert-equal :persisted
                             (hyperdoc::workspace-annotation-persistence-report-status-of
                              report)
                             "No-client live writes with environment-backed Basic service auth must persist instead of falling into pending-auth")
               (assert-true
                (not (hyperdoc::workspace-annotation-pending-auth-p report))
                "Environment-backed Basic service auth must keep the ordinary Common-workspace path out of pending-auth")
               (assert-equal nil
                             (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                              report)
                             "Successful environment-backed service-auth writes must not preserve a failing stage")
               (assert-equal :completed
                             (getf assignment-stage :status)
                             "Shared service-auth bootstrap parity must carry the workspace-assignment stage to completion")
               (assert-true
                (typep persisted 'hyperdoc::workspace-dock-annotation)
                "Successful environment-backed service-auth writes must still reopen as a workspace-dock-annotation")
               (assert-equal *dmx-annotations-smoke-workspace-id*
                             (hyperdoc::workspace-annotation-workspace-id-of
                              persisted)
                             "No per-action user auth should be required once shared service auth bootstraps correctly for the Common workspace")
               (assert-equal "JSESSIONID=session-123"
                             (hyperdoc::dmx-import-session-cookie-of client)
                             "Environment-built Basic service auth must retain the bootstrapped JSESSIONID after login")
               (assert-true
                (and login-position
                     assignment-position
                     (< login-position assignment-position))
                "Shared service-auth bootstrap must happen before workspace assignment on the no-client live annotation path")
               (assert-true
                (search "Basic "
                        (or (header-value (getf login-call :headers)
                                          "Authorization")
                            "")
                        :test #'char-equal)
                "The bootstrap request must use the environment-built Basic service Authorization header")
               (assert-equal nil
                             (header-value (getf login-call :headers) "Cookie")
                             "The bootstrap request must not carry the workspace cookie")
               (assert-equal nil
                             (header-value (getf assignment-call :headers)
                                           "Authorization")
                             "Workspace assignment must switch to session-only auth after shared service bootstrap")
               (assert-equal "JSESSIONID=session-123; dmx_workspace_id=919815"
                             (header-value (getf assignment-call :headers)
                                           "Cookie")
                             "Workspace assignment must combine the bootstrapped JSESSIONID with the Common-workspace cookie")))
        (setf (symbol-function 'drakma:http-request) original-request
              (symbol-function 'hyperdoc::getenv-non-empty) original-getenv
              hyperdoc::*dmx-workspace-journal-suppressed-p*
              original-journal-suppressed-p)))))

(defun run-dmx-http-workspace-assignment-cookie-context-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer explicit-test-token"))
         (assignment-cookie nil)
         (assignment-auth-header nil)
         (original (symbol-function 'drakma:http-request)))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method want-stream content-type content
                             content-length additional-headers
                             &allow-other-keys)
                   (declare (ignore want-stream content-type content
                                    content-length))
                   (cond
                     ((search "/workspaces/919815/object/9300" url)
                      (assert-equal :put method
                                    "Workspace assignment must PUT the guarded workspace endpoint")
                      (setf assignment-cookie
                            (cdr (assoc "Cookie"
                                        additional-headers
                                        :test #'string-equal))
                            assignment-auth-header
                            (cdr (assoc "Authorization"
                                        additional-headers
                                        :test #'string-equal)))
                      (values (make-string-input-stream "")
                              204
                              '(("Content-Type" . "application/json"))
                              nil nil "No Content"))
                     (t
                      (error "Unexpected workspace-assignment HTTP call ~S"
                             url)))))
           (assert-equal nil
                         (hyperdoc::dmx-import-assign-topic-to-workspace
                          client
                          *dmx-annotations-smoke-workspace-id*
                          9300)
                         "A mocked 204 workspace assignment must round-trip as NIL")
           (assert-equal "dmx_workspace_id=919815"
                         assignment-cookie
                         "Workspace assignment must carry dmx_workspace_id from the explicit request workspace even when the live HTTP client itself has no workspace-id")
           (assert-equal "Bearer explicit-test-token"
                         assignment-auth-header
                         "Header-mode assignment must preserve the original Authorization header while adding the request-time workspace cookie"))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-http-topicmap-mutation-workspace-cookie-context-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"))
         (topicmap-cookie nil)
         (original (symbol-function 'drakma:http-request)))
    (labels ((make-view-props ()
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "dmx.topicmaps.x" json) 24
                       (gethash "dmx.topicmaps.y" json) 44
                       (gethash "dmx.topicmaps.visibility" json) t
                       (gethash "dmx.topicmaps.pinned" json) nil)
                 json)))
      (unwind-protect
           (progn
             (setf (symbol-function 'drakma:http-request)
                   (lambda (url &key method want-stream additional-headers
                               content-type content content-length
                               &allow-other-keys)
                     (declare (ignore want-stream content-type content
                                      content-length))
                     (cond
                       ((search (hyperdoc::dmx-topicmap-add-topic-path
                                 *dmx-annotations-smoke-workspace-topicmap-id*
                                 9300)
                                url)
                        (assert-equal :post method
                                      "Topicmap add must POST the topicmap membership endpoint")
                        (setf topicmap-cookie
                              (cdr (assoc "Cookie"
                                          additional-headers
                                          :test #'string-equal)))
                        (values (make-string-input-stream "{\"dmx.topicmaps.x\":24}")
                                200
                                '(("Content-Type" . "application/json"))
                                nil nil "OK"))
                       (t
                        (error "Unexpected topicmap-mutation HTTP call ~S"
                               url)))))
             (hyperdoc::with-http-dmx-import-request-workspace-id
                 (*dmx-annotations-smoke-workspace-id*)
               (hyperdoc::dmx-import-add-topic-to-topicmap
                client
                *dmx-annotations-smoke-workspace-topicmap-id*
                9300
                (make-view-props)))
             (assert-equal "dmx_workspace_id=919815"
                           topicmap-cookie
                           "Workspace-scoped topicmap mutation must carry dmx_workspace_id from the request-time workspace context"))
        (setf (symbol-function 'drakma:http-request) original)))))

(defun run-dmx-workspace-annotation-no-client-pending-auth-smoke-test ()
  (let* ((resolved-client
           (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :next-topic-id 9300))
         (annotation (make-test-dock-annotation
                      :note "Pending auth without explicit client"))
         (original
           (symbol-function 'hyperdoc::resolve-dmx-workspace-annotation-client)))
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::resolve-dmx-workspace-annotation-client)
                 (lambda (&key client dry-run verbose)
                   (declare (ignore client dry-run verbose))
                   resolved-client))
           (let* ((result (hyperdoc::persist-dock-annotation-to-workspace
                           annotation
                           :workspace-topicmap-id
                           *dmx-annotations-smoke-workspace-topicmap-id*
                           :dry-run nil))
                  (topic-stage
                    (hyperdoc::workspace-annotation-persistence-stage-result
                     result
                     :topic-upsert)))
             (assert-true
              (typep result 'hyperdoc::workspace-annotation-persistence-report)
              "Non-dry-run workspace annotation persist without an explicit client must still return the inspectable persistence report")
             (assert-equal :pending-auth
                           (hyperdoc::workspace-annotation-persistence-report-status-of
                            result)
                           "No-client live persist must advance past topic create and stop later at the pending-auth assignment boundary")
             (assert-equal :workspace-assignment
                           (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                            result)
                           "No-client live persist must preserve workspace assignment as the first failing guarded step")
             (assert-true
              (eq resolved-client
                  (hyperdoc::workspace-annotation-persistence-report-client-of
                   result))
              "No-client live persist must thread the resolved live client through the persistence report")
             (assert-true
              (not (typep (hyperdoc::workspace-annotation-persistence-report-client-of
                           result)
                          'hyperdoc::null-dmx-import-client))
              "No-client live persist must not fall back to the null DMX import client at topic-upsert time")
             (assert-true
              (hyperdoc::workspace-annotation-persistence-report-persisted-topic-id-of
               result)
              "No-client live persist must preserve the created topic id before the later auth boundary")
             (assert-equal :completed
                           (getf topic-stage :status)
                           "No-client live persist must complete topic-upsert before reaching pending-auth")))
      (setf (symbol-function 'hyperdoc::resolve-dmx-workspace-annotation-client)
            original))))

(defun run-dmx-workspace-annotation-pending-auth-smoke-test ()
  (let* ((client (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :workspace-id *dmx-annotations-smoke-workspace-id*
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation
                      :note "Pending auth after create"))
         (result (hyperdoc::persist-dock-annotation-to-workspace
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client
                  :dry-run nil))
         (pending-context
           (hyperdoc::workspace-annotation-persistence-report-assignment-auth-context-of
            result))
         (topic-id
           (hyperdoc::workspace-annotation-persistence-report-persisted-topic-id-of
            result)))
    (assert-true
     (typep result 'hyperdoc::workspace-annotation-persistence-report)
     "Missing workspace-assignment auth must return an inspectable persistence report")
    (assert-equal :pending-auth
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   result)
                  "Create succeeded but missing assignment auth must classify as pending-auth")
    (assert-equal :workspace-assignment
                  (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                   result)
                  "Pending-auth reports must preserve that the blocker is workspace assignment")
    (assert-true
     topic-id
     "Pending-auth reports must preserve the already-created topic id")
    (assert-equal (format nil "/workspaces/~D/object/~D"
                          *dmx-annotations-smoke-workspace-id*
                          topic-id)
                  (getf pending-context :assignment-endpoint-path)
                  "Pending-auth reports must preserve the guarded assignment endpoint")
    (assert-equal nil
                  (getf pending-context :environment-auth-present-p)
                  "Pending-auth reports must state that no env auth is currently present")
    (assert-equal "anonymous"
                  (getf pending-context :environment-auth-mode-summary)
                  "Pending-auth reports must preserve the current anonymous auth summary")
    (assert-true
     (member "HYPERDOC_DMX_IMPORT_AUTH_HEADER"
             (getf pending-context :auth-missing-keys)
             :test #'string=)
     "Pending-auth reports must preserve the missing authenticated mutation config keys")))

(defun run-dmx-workspace-annotation-pending-auth-render-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((client (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :workspace-id *dmx-annotations-smoke-workspace-id*
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation
                      :note "Pending auth render"))
         (report (hyperdoc::persist-dock-annotation-to-workspace
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client
                  :dry-run nil))
         (views (dmx-annotation-smoke-load-inspector-views-for-object report))
         (overview (dmx-annotation-smoke-find-view-by-title views "Overview"))
         (html (and overview
                    (html-inspector-views:view-html overview))))
    (assert-true
     overview
     "Pending-auth persistence reports must expose an Overview view")
    (assert-true
     (stringp html)
     "Pending-auth persistence report Overview must render to HTML")
    (assert-true
     (search "Workspace assignment blocked" html :test #'char-equal)
     "Pending-auth Overview must explain the blocked assignment boundary without implying that assignment already succeeded")
    (assert-true
     (search "Continue with explicit auth" html :test #'char-equal)
     "Pending-auth Overview must expose the explicit-auth continuation action")
    (assert-true
     (search "Operational consequences" html :test #'char-equal)
     "Pending-auth Overview must expose typed operational consequences")
    (assert-true
     (search "continue-with-guarded-boundary" html :test #'char-equal)
     "Pending-auth Overview must classify the blocked boundary as continue-with-guarded-boundary")
    (assert-true
     (search "Destination source" html :test #'char-equal)
     "Pending-auth Overview must expose the resolved destination explicitly")
    (assert-true
     (search "context-window workspace (919815)" html :test #'char-equal)
     "Pending-auth Overview must expose the destination workspace with a human-readable label")
    (assert-true
     (search "context-window topicmap (919822)" html :test #'char-equal)
     "Pending-auth Overview must expose the destination topicmap with a human-readable label")
    (assert-true
     (search "current HTTP client/workspace context" html
             :test #'char-equal)
     "Pending-auth Overview must expose the workspace side of the destination rationale")
    (assert-true
     (search "explicit user choice" html
             :test #'char-equal)
     "Pending-auth Overview must expose the destination rationale")
    (assert-true
     (search "DMX auth is missing" html :test #'char-equal)
     "Pending-auth Overview must explain that assignment is blocked before it starts because auth is missing")
    (assert-true
     (search "not a saved-enough outcome" html :test #'char-equal)
     "Pending-auth Overview must keep topicmap placement distinct from workspace assignment")
    (assert-true
     (null (search "Assigned topic" html :test #'char-equal))
     "Pending-auth Overview must not falsely claim that workspace assignment already happened")))

(defun run-dmx-workspace-annotation-pending-auth-compare-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((client (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :workspace-id *dmx-annotations-smoke-workspace-id*
                                :next-topic-id 9302))
         (annotation (make-test-dock-annotation
                      :note "Pending auth compare"))
         (report (hyperdoc::persist-dock-annotation-to-workspace
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client
                  :dry-run nil))
         (topic-id
           (hyperdoc::workspace-annotation-persistence-report-persisted-topic-id-of
            report))
         (comparison
           (hyperdoc::compare-dock-annotation-with-guarded-workspace-path
            annotation
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :client client
            :report report))
         (views (dmx-annotation-smoke-load-inspector-views-for-object
                 comparison))
         (path-diff (dmx-annotation-smoke-find-view-by-title views "Path diff"))
         (consequences-view
           (dmx-annotation-smoke-find-view-by-title views "Consequences"))
         (overview (dmx-annotation-smoke-find-view-by-title views "Overview"))
         (graph-view (dmx-annotation-smoke-find-view-by-title views "Graph"))
         (path-diff-html (and path-diff
                              (html-inspector-views:view-html path-diff)))
         (consequences-html (and consequences-view
                                 (html-inspector-views:view-html
                                  consequences-view)))
         (graph-html (and graph-view
                          (html-inspector-views:view-html graph-view)))
         (overview-html (and overview
                             (html-inspector-views:view-html overview))))
    (assert-equal topic-id
                  (hyperdoc::workspace-annotation-path-diff-continuation-topic-id-of
                   comparison)
                  "Pending-auth compare objects must preserve the created topic id from the raw report")
    (assert-true
     (hyperdoc::workspace-annotation-path-diff-guarded-assignment-summary-of
      comparison)
     "Pending-auth compare objects must attach a guarded assignment preview from the preserved topic id")
    (assert-true
     (hyperdoc::workspace-annotation-path-diff-guarded-topicmap-summary-of
      comparison)
     "Pending-auth compare objects must attach a guarded topicmap preview from the preserved topic id")
    (assert-true
     (member :continue-with-guarded-boundary
             (workspace-annotation-consequence-kinds comparison))
     "Pending-auth compare objects must yield a continue-with-guarded-boundary consequence")
    (assert-true
     (search "raw: error (pending-auth); guarded: dry-run" path-diff-html
             :test #'char-equal)
     "Pending-auth Path diff must show the raw stop and guarded dry-run continuation on the same row")
    (assert-true
     (search "continue-with-guarded-boundary" consequences-html
             :test #'char-equal)
     "Pending-auth Consequences view must surface continue-with-guarded-boundary explicitly")
    (assert-true
     (search "continue_workspace_annotation" path-diff-html
             :test #'char-equal)
     "Pending-auth Path diff next steps must name continue_workspace_annotation")
    (assert-true
     (search "Open preserved raw persistence report" path-diff-html
             :test #'char-equal)
     "Pending-auth Path diff must link back to the preserved raw persistence report")
    (assert-true
     (search "Open preserved persistence report" overview-html
             :test #'char-equal)
     "Pending-auth compare Overview must keep the preserved report reachable")
    (assert-true
     (search "Topicmap visibility is not workspace ownership" overview-html
             :test #'char-equal)
     "Pending-auth compare Overview must keep assignment/topicmap separation explicit")
    (assert-true
     (search "continue-with-guarded-boundary" graph-html
             :test #'char-equal)
     "Pending-auth Graph view must attach the guarded-boundary consequence to the divergence surface")))

(defun run-dmx-workspace-annotation-assignment-topicmap-split-consequence-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((topics (make-hash-table :test #'equal))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (client
           (make-instance 'compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :authorization-header "Bearer test-token"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9390))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Assignment/topicmap split consequence")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :client client
            :dry-run nil))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of persisted)))
    (remhash topic-id workspace-assignments)
    (let* ((comparison
             (hyperdoc::compare-dock-annotation-with-guarded-workspace-path
              persisted
              :workspace-topicmap-id
              *dmx-annotations-smoke-workspace-topicmap-id*
              :workspace-id *dmx-annotations-smoke-workspace-id*
              :client client))
           (views (dmx-annotation-smoke-load-inspector-views-for-object
                   comparison))
           (path-diff (dmx-annotation-smoke-find-view-by-title views "Path diff"))
           (consequences-view
             (dmx-annotation-smoke-find-view-by-title views "Consequences"))
           (graph-view (dmx-annotation-smoke-find-view-by-title views "Graph"))
           (path-diff-html (and path-diff
                                (html-inspector-views:view-html path-diff)))
           (consequences-html (and consequences-view
                                   (html-inspector-views:view-html
                                    consequences-view)))
           (graph-html (and graph-view
                            (html-inspector-views:view-html graph-view))))
      (assert-true
       (member :repair-workspace-assignment
               (workspace-annotation-consequence-kinds comparison))
       "Topicmap-visible but assignment-missing compare objects must yield repair-workspace-assignment")
      (assert-true
       (search "repair_workspace_topic_assignment" consequences-html
               :test #'char-equal)
       "The repair consequence must point to repair_workspace_topic_assignment")
      (assert-true
       (search "Topicmap visibility does not solve ownership" consequences-html
               :test #'char-equal)
       "The repair consequence must keep topicmap visibility separate from workspace ownership")
      (assert-true
       (search "repair-workspace-assignment" path-diff-html
               :test #'char-equal)
       "Path diff next steps must surface the ownership-repair consequence")
      (assert-true
       (search "repair-workspace-assignment" graph-html
               :test #'char-equal)
       "Graph view must render the ownership-repair consequence from the shared consequence rows"))))

(defun run-dmx-workspace-annotation-no-change-consequence-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9395))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "No-change consequence")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :client client
            :dry-run nil))
         (comparison
           (hyperdoc::compare-dock-annotation-with-guarded-workspace-path
            persisted
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :client client))
         (views (dmx-annotation-smoke-load-inspector-views-for-object
                 comparison))
         (path-diff (dmx-annotation-smoke-find-view-by-title views "Path diff"))
         (consequences-view
           (dmx-annotation-smoke-find-view-by-title views "Consequences"))
         (graph-view (dmx-annotation-smoke-find-view-by-title views "Graph"))
         (path-diff-html (and path-diff
                              (html-inspector-views:view-html path-diff)))
         (consequences-html (and consequences-view
                                 (html-inspector-views:view-html
                                  consequences-view)))
         (graph-html (and graph-view
                          (html-inspector-views:view-html graph-view))))
    (assert-true
     (member :persisted-success
             (workspace-annotation-consequence-kinds comparison))
     "Reopened persisted annotation compare objects must yield persisted-success")
    (assert-true
     (not (member :no-change
                  (workspace-annotation-consequence-kinds comparison)))
     "Reopened persisted annotation compare objects must no longer collapse terminal success into no-change")
    (assert-true
     (search "persisted-success" consequences-html :test #'char-equal)
     "Consequences view must label terminal reopen success as persisted-success")
    (assert-true
     (search "No mutation required" path-diff-html :test #'char-equal)
     "Path diff next steps must render the no-mutation target for terminal reopen success")
    (assert-true
     (search "persisted-success" graph-html :test #'char-equal)
     "Graph consequence surfaces must label terminal reopen success as persisted-success")))

(defun run-dmx-workspace-annotation-saved-topic-surface-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
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
                          :next-topic-id 9400))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Saved topic surface smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client create-client
            :dry-run nil))
         (saved-topic-id (hyperdoc::workspace-annotation-topic-id-of persisted))
         (update-client
           (make-instance 'failing-topic-update-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :authorization-header "Bearer test-token"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9401))
         (report
           (hyperdoc::run-dock-annotation-workspace-persistence-debug
            persisted
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client update-client))
         (views (dmx-annotation-smoke-load-inspector-views-for-object report))
         (overview (dmx-annotation-smoke-find-view-by-title views "Overview"))
         (html (and overview
                    (html-inspector-views:view-html overview))))
    (assert-true
     (typep report 'hyperdoc::workspace-annotation-persistence-report)
     "Existing persisted annotation update failures must still return an inspectable persistence report")
    (assert-equal :failed
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   report)
                  "A simulated carrier update failure must keep the report in failed status")
    (assert-equal :topic-upsert
                  (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                   report)
                  "The saved-topic surface smoke must fail exactly at topic-upsert")
    (assert-equal :update
                  (hyperdoc::dmx-workspace-annotation-write-plan-topic-action
                   (hyperdoc::workspace-annotation-persistence-report-plan-of
                    report))
                  "The saved-topic surface smoke must exercise the existing-topic UPDATE path")
    (assert-equal saved-topic-id
                  (hyperdoc::workspace-annotation-persistence-report-saved-topic-id-of
                   report)
                  "Update-failure reports must preserve the already-saved topic id")
    (assert-true
     (typep (hyperdoc::workspace-annotation-persistence-report-saved-annotation-of
             report)
            'hyperdoc::workspace-dock-annotation)
     "Update-failure reports must expose the semantic reopened workspace annotation object")
    (assert-true
     (typep (hyperdoc::workspace-annotation-persistence-report-saved-carrier-topic-proxy-of
             report)
            'hyperdoc::dmx-topic-proxy)
     "Update-failure reports must expose the physical saved carrier topic proxy")
    (assert-true
     overview
     "Update-failure reports must expose an Overview view")
    (assert-true
     (stringp html)
     "Update-failure reports must render an Overview HTML surface")
    (assert-true
     (search "Saved annotation topic" html :test #'char-equal)
     "The Overview must surface the already-saved annotation topic explicitly")
    (assert-true
     (search "Saved annotation object" html :test #'char-equal)
     "The Overview must expose the semantic reopened annotation object")
    (assert-true
     (search "Saved carrier topic" html :test #'char-equal)
     "The Overview must expose the physical saved carrier topic")
    (assert-true
     (search (format nil "~D" saved-topic-id) html :test #'char-equal)
     "The Overview must include the already-saved topic id")
    (assert-true
     (search "context-window workspace (919815)" html :test #'char-equal)
     "The Overview must show the saved workspace with a human-readable label")
    (assert-true
     (search "context-window topicmap (919822)" html :test #'char-equal)
     "The Overview must show the saved topicmap with a human-readable label")
    (assert-true
     (search "dmx.notes.note" html :test #'char-equal)
     "The Overview must keep the physical carrier type explicit")))

(defun run-dmx-workspace-annotation-simple-success-readback-example-smoke-test
    ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "Simple example: topic saved to context-window"
                                :signal-error? t))
         (object (hyperdoc::simple-context-window-saved-topic-success-readback))
         (topic-proxy
           (hyperdoc::workspace-annotation-persistence-success-readback-topic-proxy-of
            object))
         (workspace-proxy
           (hyperdoc::workspace-annotation-persistence-success-readback-workspace-proxy-of
            object))
         (topicmap-proxy
           (hyperdoc::workspace-annotation-persistence-success-readback-topicmap-proxy-of
            object))
         (views (dmx-annotation-smoke-load-inspector-views-for-object object))
         (overview (dmx-annotation-smoke-find-view-by-title views "Overview"))
         (html (and overview
                    (html-inspector-views:view-html overview))))
    (assert-true
     page
     "The simple example page must resolve through HyperDoc page lookup")
    (assert-true
     (typep object 'hyperdoc::workspace-annotation-persistence-success-readback)
     "The simple example must reuse workspace-annotation-persistence-success-readback")
    (assert-true
     (typep topic-proxy 'hyperdoc::dmx-topic-proxy)
     "The simple example must expose a saved-topic proxy")
    (assert-equal 922586
                  (hyperdoc::dmx-topic-id-of topic-proxy)
                  "The simple example must point to the fixed saved topic 922586")
    (assert-true
     (typep workspace-proxy 'hyperdoc::dmx-topic-proxy)
     "The simple example must expose a workspace proxy")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (hyperdoc::dmx-topic-id-of workspace-proxy)
                  "The simple example must point to workspace 919815")
    (assert-true
     (typep topicmap-proxy 'hyperdoc::dmx-topic-proxy)
     "The simple example must expose a topicmap proxy")
    (assert-equal *dmx-annotations-smoke-workspace-topicmap-id*
                  (hyperdoc::dmx-topic-id-of topicmap-proxy)
                  "The simple example must point to topicmap 919822")
    (assert-true
     overview
     "The simple example must expose an Overview view")
    (assert-true
     (stringp html)
     "The simple example Overview must render to HTML")
    (assert-true
     (search "Saved annotation topic" html :test #'char-equal)
     "The simple example Overview must keep the saved-topic row")
    (assert-true
     (search "922586" html :test #'char-equal)
     "The simple example Overview must show the fixed saved topic id")
    (assert-true
     (search "Workspace context-window workspace (919815)"
             html
             :test #'char-equal)
     "The simple example Overview must show the exact workspace label")
    (assert-true
     (search "Topicmap context-window topicmap (919822)"
             html
             :test #'char-equal)
     "The simple example Overview must show the exact topicmap label")))

(defun run-dmx-workspace-annotation-auth-blocked-saved-topic-resolution-smoke-test
    ()
  (asdf:load-system :hyperdoc/explorer)
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
                          :next-topic-id 928840))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Saved topic auth-boundary resolution smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client create-client
            :dry-run nil))
         (update-client
           (make-instance 'auth-blocked-topic-update-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 928841))
         (report
           (hyperdoc::run-dock-annotation-workspace-persistence-debug
            persisted
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client update-client))
         (resolution
           (hyperdoc::workspace-annotation-persistence-report-resolution-of
            report))
         (topic-upsert-operation
           (hyperdoc::workspace-annotation-persistence-stage-operation-of
            report
            :topic-upsert))
         (workspace-assignment-absence
           (hyperdoc::workspace-annotation-persistence-stage-result-or-absence-of
            report
            :workspace-assignment))
         (topicmap-placement-absence
           (hyperdoc::workspace-annotation-persistence-stage-result-or-absence-of
            report
            :topicmap-placement))
         (report-views
           (dmx-annotation-smoke-load-inspector-views-for-object report))
         (overview
           (dmx-annotation-smoke-find-view-by-title report-views "Overview"))
         (stages
           (dmx-annotation-smoke-find-view-by-title report-views "Stages"))
         (overview-html (and overview
                             (html-inspector-views:view-html overview)))
         (stages-html (and stages
                           (html-inspector-views:view-html stages)))
         (operation-views
           (dmx-annotation-smoke-load-inspector-views-for-object
            topic-upsert-operation))
         (operation-overview
           (dmx-annotation-smoke-find-view-by-title operation-views "Overview"))
         (operation-html
           (and operation-overview
                (html-inspector-views:view-html operation-overview)))
         (absence-views
           (dmx-annotation-smoke-load-inspector-views-for-object
            workspace-assignment-absence))
         (absence-overview
           (dmx-annotation-smoke-find-view-by-title absence-views "Overview"))
         (absence-html
           (and absence-overview
                (html-inspector-views:view-html absence-overview))))
    (assert-true
     (typep report 'hyperdoc::workspace-annotation-persistence-report)
     "Saved-topic auth-boundary failures must still return an inspectable persistence report")
    (assert-equal :failed
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   report)
                  "Anonymous existing-topic PUT 401 must keep the raw persistence report in failed status")
    (assert-equal :topic-upsert
                  (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                   report)
                  "The auth-boundary saved-topic smoke must fail at TOPIC-UPSERT")
    (assert-equal 928840
                  (hyperdoc::workspace-annotation-persistence-report-saved-topic-id-of
                   report)
                  "The auth-boundary saved-topic smoke must preserve saved topic 928840")
    (assert-true
     (typep (hyperdoc::workspace-annotation-persistence-report-workspace-proxy-of
             report)
            'hyperdoc::dmx-topic-proxy)
     "The report must expose workspace 919815 as an inspectable DMX proxy")
    (assert-true
     (typep (hyperdoc::workspace-annotation-persistence-report-topicmap-proxy-of
             report)
            'hyperdoc::dmx-topic-proxy)
     "The report must expose topicmap 919822 as an inspectable DMX proxy")
    (assert-true
     (typep (hyperdoc::workspace-annotation-persistence-report-saved-topic-proxy-of
             report)
            'hyperdoc::dmx-topic-proxy)
     "The report must expose the saved annotation topic as an inspectable DMX proxy")
    (assert-true
     (typep resolution 'hyperdoc::workspace-annotation-persistence-resolution)
     "Auth-boundary topic-upsert failures must derive an inspectable Resolution object")
    (assert-true
     (typep topic-upsert-operation
            'hyperdoc::workspace-annotation-persistence-stage-operation)
     "The failed TOPIC-UPSERT row must expose an inspectable operation object")
    (assert-true
     (typep workspace-assignment-absence
            'hyperdoc::workspace-annotation-persistence-stage-absence)
     "Blocked downstream stages must expose inspectable absence objects")
    (assert-equal :not-reached-because-prior-stage-failed
                  (hyperdoc::workspace-annotation-persistence-stage-absence-kind-of
                   workspace-assignment-absence)
                  "WORKSPACE-ASSIGNMENT must be modeled as not reached because TOPIC-UPSERT failed")
    (assert-equal :not-reached-because-prior-stage-failed
                  (hyperdoc::workspace-annotation-persistence-stage-absence-kind-of
                   topicmap-placement-absence)
                  "TOPICMAP-PLACEMENT must be modeled as not reached because TOPIC-UPSERT failed")
    (assert-true
     (search "Resolution" overview-html :test #'char-equal)
     "Overview must render a top-level Resolution section")
    (assert-true
     (search "AUTH-BOUNDARY blocked locally: anonymous PUT /core/topic/928840 before HTTP request"
             overview-html
             :test #'char-equal)
     "Overview Resolution must preserve the local pre-HTTP blocking condition")
    (assert-true
     (search "Do not retry anonymously."
             overview-html
             :test #'char-equal)
     "Overview Resolution must tell the operator not to retry anonymously")
    (assert-true
     (search "POST /access-control/login"
             overview-html
             :test #'char-equal)
     "Overview Resolution must name the login bootstrap step for username/password mode")
    (assert-true
     (search "JSESSIONID"
             overview-html
             :test #'char-equal)
     "Overview Resolution must name the session bootstrap artifact explicitly")
    (assert-true
     (search "continue_workspace_annotation"
             overview-html
             :test #'char-equal)
     "Overview Resolution must point to continue_workspace_annotation for the saved-topic auth-boundary case")
    (assert-true
     (search "Saved annotation topic 928840"
             overview-html
             :test #'char-equal)
     "Overview must render the saved annotation topic as an inspectable object ref")
    (assert-true
     (search "context-window workspace (919815)"
             overview-html
             :test #'char-equal)
     "Overview must render the destination workspace as an inspectable object ref label")
    (assert-true
     (search "context-window topicmap (919822)"
             overview-html
             :test #'char-equal)
     "Overview must render the destination topicmap as an inspectable object ref label")
    (assert-true
     (search "TOPIC-UPSERT"
             stages-html
             :test #'char-equal)
     "Stages view must use the explicit TOPIC-UPSERT stage label")
    (assert-true
     (search "WORKSPACE-ASSIGNMENT"
             stages-html
             :test #'char-equal)
     "Stages view must use the explicit WORKSPACE-ASSIGNMENT stage label")
    (assert-true
     (search "TOPICMAP-PLACEMENT"
             stages-html
             :test #'char-equal)
     "Stages view must use the explicit TOPICMAP-PLACEMENT stage label")
    (assert-true
     (search "JOURNAL-RECORDING"
             stages-html
             :test #'char-equal)
     "Stages view must use the explicit JOURNAL-RECORDING stage label")
    (assert-true
     (search "REOPEN"
             stages-html
             :test #'char-equal)
     "Stages view must use the explicit REOPEN stage label")
    (assert-true
     (search "credentials-pending"
             stages-html
             :test #'char-equal)
     "Stages view must expose the failed TOPIC-UPSERT result as credentials-pending")
    (assert-true
     (search "not-reached-because-prior-stage-failed"
             stages-html
             :test #'char-equal)
     "Stages view must expose downstream stages as not reached because the prior stage failed")
    (assert-true
     (search "What must the operator do next?"
             operation-html
             :test #'char-equal)
     "The failed stage object must explicitly answer what the operator must do next")
    (assert-true
     (search "What readback will prove success?"
             operation-html
             :test #'char-equal)
     "The failed stage object must explicitly answer what readback proves success")
    (assert-true
     (search "Failure evidence"
             operation-html
             :test #'char-equal)
     "The failed stage object must surface inspectable failure evidence")
    (assert-true
     (search "Why did this not run?"
             absence-html
             :test #'char-equal)
     "Downstream absence objects must explain why the stage did not run")
    (assert-true
     (search "What readback will prove success?"
             absence-html
             :test #'char-equal)
     "Downstream absence objects must point to the success readback criteria")))

(defun run-dmx-workspace-annotation-preserved-topic-936040-continuation-smoke-test
    ()
  (let* ((topic-id 936040)
         (workspace-id *dmx-annotations-smoke-workspace-id*)
         (workspace-topicmap-id *dmx-annotations-smoke-workspace-topicmap-id*)
         (topics (make-hash-table :test #'eql))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (topic-json
           (nth-value
            0
            (make-preserved-workspace-annotation-carrier-topic-json
             :topic-id topic-id
             :workspace-id workspace-id
             :workspace-topicmap-id workspace-topicmap-id))))
    (setf (gethash topic-id topics) topic-json)
    (let* ((read-client
             (make-instance
              'preserved-workspace-annotation-http-dmx-import-client
              :base-url "https://dmx.ralfbarkow.ch"
              :workspace-id workspace-id
              :topics-by-id topics
              :topicmap-memberships topicmap-memberships
              :workspace-assignments workspace-assignments))
           (reconstructed
             (hyperdoc::read-dmx-workspace-annotation
              :topic-id topic-id
              :workspace-topicmap-id workspace-topicmap-id
              :client read-client))
           (plan
             (hyperdoc::plan-dmx-workspace-annotation-write-from-object
              reconstructed
              :workspace-id workspace-id
              :workspace-topicmap-id workspace-topicmap-id
              :client read-client))
           (continuation-report
             (hyperdoc::make-workspace-annotation-continuation-report
              reconstructed
              plan
              topic-id
              workspace-topicmap-id
              read-client))
           (topic-upsert-stage
             (hyperdoc::workspace-annotation-persistence-stage-result
              continuation-report
              :topic-upsert)))
      (assert-true
       (typep reconstructed 'hyperdoc::workspace-dock-annotation)
       "Preserved-topic continuation must reopen the compatibility carrier as a semantic workspace annotation object")
      (assert-equal topic-id
                    (hyperdoc::workspace-annotation-topic-id-of reconstructed)
                    "Preserved-topic continuation must target topic 936040")
      (assert-equal
       hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
       (hyperdoc::workspace-annotation-storage-mode-of reconstructed)
       "Preserved-topic continuation must reconstruct compatibility storage semantics from the carrier")
      (assert-equal :continuation-ready
                    (hyperdoc::workspace-annotation-persistence-report-status-of
                     continuation-report)
                    "Preserved-topic continuation reports must be continuation-ready")
      (assert-equal :completed
                    (getf topic-upsert-stage :status)
                    "Preserved-topic continuation reports must mark TOPIC-UPSERT as already complete")
      (assert-true
       (search "starts after topic upsert"
               (or (getf topic-upsert-stage :summary) "")
               :test #'char-equal)
       "Preserved-topic continuation reports must state that guarded continuation starts after topic upsert")
      (assert-equal :update
                    (hyperdoc::dmx-workspace-annotation-write-plan-topic-action
                     plan)
                    "Preserved-topic continuation plan must still classify the preserved topic as UPDATE")
      (assert-equal topic-id
                    (hyperdoc::dmx-workspace-annotation-write-plan-existing-topic-id
                     plan)
                    "Preserved-topic continuation plan must preserve existing topic id 936040")
      (assert-equal workspace-id
                    (hyperdoc::dmx-workspace-annotation-write-plan-workspace-id
                     plan)
                    "Preserved-topic continuation plan must keep workspace target 919815")
      (assert-equal workspace-topicmap-id
                    (hyperdoc::dmx-workspace-annotation-write-plan-workspace-topicmap-id
                     plan)
                    "Preserved-topic continuation plan must keep topicmap target 919822")
      (let ((anonymous-client
              (make-instance
               'preserved-workspace-annotation-http-dmx-import-client
               :base-url "https://dmx.ralfbarkow.ch"
               :workspace-id workspace-id
               :topics-by-id topics
               :topicmap-memberships topicmap-memberships
               :workspace-assignments workspace-assignments))
            (captured-calls '())
            (continued nil)
            (original-drakma
              (symbol-function 'drakma:http-request)))
        (labels ((core-topic-upsert-call-p (call)
                   (and (eq (getf call :method) :put)
                        (search (format nil "/core/topic/~D" topic-id)
                                (getf call :url)
                                :test #'char-equal))))
          (unwind-protect
               (progn
                 (setf (symbol-function 'drakma:http-request)
                       (lambda (url &key method additional-headers content-type
                                   content content-length want-stream
                                   &allow-other-keys)
                         (declare (ignore want-stream))
                         (push (list :url url
                                     :method method
                                     :headers additional-headers
                                     :content-type content-type
                                     :content content
                                     :content-length content-length)
                               captured-calls)
                         (values (make-string-input-stream "{}")
                                 200
                                 '(("Content-Type" . "application/json"))
                                 nil
                                 nil
                                 "OK")))
                 (let ((hyperdoc::*dmx-workspace-journal-suppressed-p* t))
                   (setf continued
                         (hyperdoc::continue-workspace-annotation-persistence-with-client
                          continuation-report
                          anonymous-client))))
            (setf (symbol-function 'drakma:http-request)
                  original-drakma))
          (assert-true
           (typep continued 'hyperdoc::workspace-annotation-persistence-report)
           "Anonymous preserved-topic continuation must return an inspectable continuation report")
          (assert-equal :pending-auth
                        (hyperdoc::workspace-annotation-persistence-report-status-of
                         continued)
                        "Anonymous preserved-topic continuation must stay at the explicit-auth boundary")
          (assert-equal :workspace-assignment
                        (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                         continued)
                        "Anonymous preserved-topic continuation must block at workspace assignment")
          (assert-true
           (null (find-if #'core-topic-upsert-call-p captured-calls))
           "Anonymous preserved-topic continuation must skip TOPIC-UPSERT and must not PUT /core/topic/936040")
          (assert-equal nil
                        (gethash topic-id workspace-assignments)
                        "Anonymous preserved-topic continuation must not mutate workspace assignment")
          (assert-true
           (null (gethash (preserved-topicmap-membership-key
                           workspace-topicmap-id
                           topic-id)
                          topicmap-memberships))
           "Anonymous preserved-topic continuation must not mutate topicmap placement")))
      (let* ((auth-topics (make-hash-table :test #'eql))
             (auth-topicmap-memberships (make-hash-table :test #'equal))
             (auth-workspace-assignments (make-hash-table :test #'eql))
             (auth-client
               (make-instance
                'preserved-workspace-annotation-http-dmx-import-client
                :base-url "https://dmx.ralfbarkow.ch"
                :workspace-id workspace-id
                :authorization-header
                (hyperdoc::basic-authorization-header "rgb" "secret")
                :session-login-required-p t
                :topics-by-id auth-topics
                :topicmap-memberships auth-topicmap-memberships
                :workspace-assignments auth-workspace-assignments))
             (workspace-json-string
               (hyperdoc::encode-json-string
                (hyperdoc::memory-dmx-import-workspace-json workspace-id)))
             (captured-calls '())
             (continued nil)
             (original-drakma (symbol-function 'drakma:http-request)))
        (setf (gethash topic-id auth-topics) topic-json)
        (labels ((header-value (call name)
                   (cdr (assoc name
                               (getf call :headers)
                               :test #'string-equal)))
                 (jsessionid-cookie-p (call)
                   (search "JSESSIONID="
                           (or (header-value call "Cookie") "")
                           :test #'char-equal))
                 (core-topic-upsert-call-p (call)
                   (and (eq (getf call :method) :put)
                        (search (format nil "/core/topic/~D" topic-id)
                                (getf call :url)
                                :test #'char-equal))))
          (unwind-protect
               (progn
                 (setf (symbol-function 'drakma:http-request)
                       (lambda (url &key method additional-headers content-type
                                   content content-length want-stream
                                   &allow-other-keys)
                         (declare (ignore want-stream))
                         (push (list :url url
                                     :method method
                                     :headers additional-headers
                                     :content-type content-type
                                     :content content
                                     :content-length content-length)
                               captured-calls)
                         (cond
                           ((search "/access-control/login" url :test #'char-equal)
                            (values
                             (make-string-input-stream "")
                             204
                             '(("Set-Cookie" . "JSESSIONID=session-936040; Path=/; SameSite=Strict"))
                             nil
                             nil
                             "No Content"))
                           ((search (format nil "/workspaces/~D/object/~D"
                                            workspace-id
                                            topic-id)
                                    url
                                    :test #'char-equal)
                            (values
                             (make-string-input-stream workspace-json-string)
                             200
                             '(("Content-Type" . "application/json"))
                             nil
                             nil
                             "OK"))
                           ((search (format nil "/topicmaps/~D/topic/~D"
                                            workspace-topicmap-id
                                            topic-id)
                                    url
                                    :test #'char-equal)
                            (values
                             (make-string-input-stream "{}")
                             200
                             '(("Content-Type" . "application/json"))
                             nil
                             nil
                             "OK"))
                           (t
                            (error "Unexpected preserved-topic explicit-auth HTTP call ~S"
                                   url)))))
                 (let ((hyperdoc::*dmx-workspace-journal-suppressed-p* t))
                   (setf continued
                         (hyperdoc::continue-workspace-annotation-persistence-with-client
                          continuation-report
                          auth-client))))
            (setf (symbol-function 'drakma:http-request)
                  original-drakma))
          (let* ((calls (nreverse captured-calls))
                 (login-call
                   (find-if (lambda (call)
                              (search "/access-control/login"
                                      (getf call :url)
                                      :test #'char-equal))
                            calls))
                 (assignment-call
                   (find-if (lambda (call)
                              (and (eq (getf call :method) :put)
                                   (search (format nil "/workspaces/~D/object/~D"
                                                   workspace-id
                                                   topic-id)
                                           (getf call :url)
                                           :test #'char-equal)))
                            calls))
                 (topicmap-call
                   (find-if (lambda (call)
                              (and (eq (getf call :method) :post)
                                   (search (format nil "/topicmaps/~D/topic/~D"
                                                   workspace-topicmap-id
                                                   topic-id)
                                           (getf call :url)
                                           :test #'char-equal)))
                            calls))
                 (persisted
                   (hyperdoc::workspace-annotation-persistence-report-persisted-annotation-of
                    continued))
                 (carrier-topic (gethash topic-id auth-topics))
                 (carrier-text
                   (or (and carrier-topic
                            (hyperdoc::dmx-json-child-value
                             carrier-topic
                             hyperdoc::*dmx-notes-text-type-uri*))
                       "")))
            (assert-true
             (search "JSESSIONID="
                     (or (hyperdoc::dmx-import-session-cookie-of auth-client) "")
                     :test #'char-equal)
             "Explicit-auth continuation must capture JSESSIONID after POST /access-control/login")
            (assert-true
             (and login-call
                  (eq (getf login-call :method) :post))
             "Explicit-auth continuation must bootstrap with POST /access-control/login")
            (assert-true
             (typep continued 'hyperdoc::workspace-annotation-persistence-report)
             "Explicit-auth continuation must return an inspectable continuation report")
            (assert-equal :persisted
                          (hyperdoc::workspace-annotation-persistence-report-status-of
                           continued)
                          "Explicit-auth continuation must finish the remaining guarded projection stages")
            (assert-equal nil
                          (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                           continued)
                          "Successful explicit-auth continuation must clear failure-stage")
            (assert-true
             (typep persisted 'hyperdoc::workspace-dock-annotation)
             "Explicit-auth continuation must reopen the preserved topic as workspace-dock-annotation")
            (assert-equal topic-id
                          (and persisted
                               (hyperdoc::workspace-annotation-topic-id-of persisted))
                          "Explicit-auth continuation must reopen preserved topic 936040")
            (assert-true
             assignment-call
             "Preserved-topic explicit-auth continuation must call workspace assignment")
            (assert-true
             (jsessionid-cookie-p assignment-call)
             "Preserved-topic explicit-auth continuation must include Cookie/JSESSIONID on workspace assignment")
            (assert-true
             topicmap-call
             "Preserved-topic explicit-auth continuation must call topicmap placement")
            (assert-true
             (jsessionid-cookie-p topicmap-call)
             "Preserved-topic explicit-auth continuation must include Cookie/JSESSIONID on topicmap placement")
            (assert-true
             (null (find-if #'core-topic-upsert-call-p calls))
             "Preserved-topic continuation must skip TOPIC-UPSERT and must not PUT /core/topic/936040")
            (assert-equal workspace-id
                          (gethash topic-id auth-workspace-assignments)
                          "Preserved-topic explicit-auth continuation must assign workspace 919815")
            (assert-true
             (not (null (gethash (preserved-topicmap-membership-key
                                  workspace-topicmap-id
                                  topic-id)
                                 auth-topicmap-memberships)))
             "Preserved-topic explicit-auth continuation must place topic 936040 in topicmap 919822")
            (assert-equal 1
                          (hash-table-count auth-topics)
                          "Preserved-topic continuation must not create duplicate carrier topics")
            (assert-true
             (null (search "secret"
                           carrier-text
                           :test #'char-equal))
             "Credentials must stay request-scoped and must not be serialized into compatibility carrier payload text")
            (assert-true
             (null (search "JSESSIONID" carrier-text :test #'char-equal))
             "Session cookie values must not be serialized into compatibility carrier payload text")
            (assert-true
             (null (search "Authorization" carrier-text :test #'char-equal))
             "Authorization headers must not be serialized into compatibility carrier payload text")
            (assert-true
             (null (search "Cookie" carrier-text :test #'char-equal))
             "Cookie headers must not be serialized into compatibility carrier payload text")))))))

(defun run-dmx-workspace-annotation-journal-preflight-failure-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((topics (make-hash-table :test #'equal))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (client
           (make-instance 'compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :authorization-header "Bearer test-token"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9450))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Journal preflight failure smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client client
            :dry-run nil))
         (saved-topic-id (hyperdoc::workspace-annotation-topic-id-of persisted))
         (assigned-journal-topic-id
           (workspace-annotation-smoke-assign-journal-topic-to-workspace
            client
            persisted))
         (journal-summary-before
           (workspace-annotation-smoke-journal-summary client persisted))
         (journal-topic-id (getf journal-summary-before :existing-topic-id))
         (original
           (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)))
    (unwind-protect
        (progn
          (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
                (lambda (client subject-key lookup-kind lookup-value workspace-topicmap-id
                         &rest args
                         &key subject-uri subject-kind ownership-class
                           note-key note-kind
                         &allow-other-keys)
                  (declare (ignore client subject-key lookup-kind lookup-value
                                   workspace-topicmap-id args subject-uri
                                   subject-kind ownership-class note-key
                                   note-kind))
                  (signal-journal-preflight-http-401 journal-topic-id)))
          (let* ((report
                   (hyperdoc::run-dock-annotation-workspace-persistence-debug
                    persisted
                    :workspace-topicmap-id
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    :client client))
                 (prepare-transition
                   (hyperdoc::workspace-annotation-persistence-stage-result
                    report
                    :prepare-transition))
                 (topic-upsert
                   (hyperdoc::workspace-annotation-persistence-stage-result
                    report
                    :topic-upsert))
                 (journal-summary
                   (hyperdoc::workspace-annotation-persistence-report-journal-preflight-summary-of
                    report))
                 (journal-auth-context
                   (hyperdoc::workspace-annotation-persistence-report-journal-preflight-auth-context-of
                    report))
                 (journal-topic-proxy
                   (hyperdoc::workspace-annotation-persistence-report-journal-topic-proxy-of
                    report))
                 (comparison
                   (hyperdoc::compare-dock-annotation-with-guarded-workspace-path
                    persisted
                    :workspace-topicmap-id
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    :workspace-id *dmx-annotations-smoke-workspace-id*
                    :client client
                    :report report))
                 (views (dmx-annotation-smoke-load-inspector-views-for-object
                         report))
                 (overview (dmx-annotation-smoke-find-view-by-title views
                                                                    "Overview"))
                 (html (and overview
                            (html-inspector-views:view-html overview))))
            (assert-true
             (typep report 'hyperdoc::workspace-annotation-persistence-report)
             "Prepare-transition failures must still return an inspectable persistence report")
            (assert-equal :pending-auth
                          (hyperdoc::workspace-annotation-persistence-report-status-of
                           report)
                          "Journal-preflight auth-blocked reports must classify the persistence report as pending-auth")
            (assert-equal :prepare-transition
                          (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                           report)
                          "Prepare-transition failures must stay classified at the journal preflight boundary")
            (assert-equal :error
                          (getf prepare-transition :status)
                          "The prepare-transition stage must be marked as error")
            (assert-true
             (search "Workspace journal preflight blocked"
                     (getf prepare-transition :summary)
                     :test #'char-equal)
             "Prepare-transition failures must use explicit blocked wording instead of a reused success summary")
            (assert-true
             (null (search "Loaded the previous workspace-journal state"
                           (getf prepare-transition :summary)
                           :test #'char-equal))
             "Prepare-transition failures must not reuse the old success wording")
            (assert-true
             (null topic-upsert)
             "Journal-preflight failures must stop before topic-upsert starts")
            (assert-true
             journal-summary
             "Prepare-transition failure reports must preserve the journal preflight summary")
            (assert-true
             journal-auth-context
             "Prepare-transition auth failures must preserve a dedicated journal auth context")
            (assert-true
             (hyperdoc::workspace-annotation-journal-preflight-auth-blocked-p
              report)
             "Prepare-transition auth failures must classify as a continuable journal auth-blocked boundary")
            (assert-true
             (not (hyperdoc::workspace-annotation-journal-preflight-authorization-blocked-p
                   report))
             "Anonymous journal-preflight blocking reports must not be misclassified as authenticated authorization failures")
            (assert-true
             (hyperdoc::workspace-annotation-auth-awaiting-p report)
             "Prepare-transition auth failures must classify as auth-awaiting at the top-level report status")
            (assert-true
             (not (hyperdoc::workspace-annotation-pending-auth-p report))
             "Prepare-transition auth failures must not masquerade as the post-topic-upsert guarded-boundary pending-auth case")
            (assert-equal "error (pending-auth)"
                          (hyperdoc::workspace-annotation-path-diff-raw-live-label
                           comparison
                           :prepare-transition)
                          "Path-diff raw live labels must surface journal-preflight auth-awaiting as error (pending-auth) on the prepare-transition stage")
            (assert-true
             (hyperdoc::workspace-annotation-persistence-report-journal-topic-id-of
              report)
             "Prepare-transition failure reports must expose the journal companion topic id when known")
            (assert-equal journal-topic-id
                          (hyperdoc::workspace-annotation-persistence-report-journal-topic-id-of
                           report)
                          "Prepare-transition failure reports must preserve the actual journal companion topic id")
            (assert-equal assigned-journal-topic-id
                          journal-topic-id
                          "The auth-blocked journal-preflight smoke must run on an assigned existing journal companion topic")
            (assert-true
             (not (eql saved-topic-id journal-topic-id))
             "The journal companion topic must remain distinct from the saved annotation carrier topic")
            (assert-true
             (typep journal-topic-proxy 'hyperdoc::dmx-topic-proxy)
             "Prepare-transition failure reports must expose the journal companion topic as an inspectable proxy")
            (assert-true
             overview
             "Prepare-transition failure reports must expose an Overview view")
            (assert-true
             (stringp html)
             "Prepare-transition failure reports must render an Overview HTML surface")
            (assert-true
             (search "Workspace journal preflight" html :test #'char-equal)
             "The Overview must expose the journal-preflight section explicitly")
            (assert-true
             (search "Workspace journal preflight blocked" html
                     :test #'char-equal)
             "The Overview must use blocked wording for journal preflight failures")
            (assert-true
             (search "before annotation topic upsert" html :test #'char-equal)
             "The Overview must explain that the journal boundary happens before topic-upsert")
            (assert-true
             (search "Saved annotation object" html :test #'char-equal)
             "The Overview must still expose the semantic saved annotation object")
            (assert-true
             (search "Saved carrier topic" html :test #'char-equal)
             "The Overview must still expose the physical saved carrier topic")
            (assert-true
             (search "Journal companion topic" html :test #'char-equal)
             "The Overview must expose the journal-side topic distinctly")
            (assert-true
             (search "Journal companion auth blocked" html
                     :test #'char-equal)
             "The Overview must expose the journal auth-blocked subsection explicitly")
	            (assert-true
	             (search "Continue journal preflight with explicit auth" html
	                     :test #'char-equal)
	             "The Overview must expose an explicit-auth continuation path for the journal boundary")
	            (assert-true
	             (search "returned retry report in a new pane" html
	                     :test #'char-equal)
	             "The blocked journal-preflight form must tell operators that the continuation opens the returned retry report in a new pane")
	            (assert-true
	             (null (search "Continuation invoked" html
	                           :test #'char-equal))
	             "The original anonymous blocked report must not render the executed-retry marker rows before any retry runs")
            (assert-true
             (search "different objects" html :test #'char-equal)
             "The Overview must explain that the saved annotation carrier topic and the journal companion topic are different objects")
            (assert-true
             (search "context-window workspace (919815)" html
                     :test #'char-equal)
             "The Overview must show the workspace destination with a human-readable label")
            (assert-true
             (search "context-window topicmap (919822)" html
                     :test #'char-equal)
             "The Overview must show the topicmap destination with a human-readable label")
            (assert-true
             (null (search "Loaded the previous workspace-journal state"
                           html
                           :test #'char-equal))
             "The Overview must not reuse the old journal success wording on failure")))
      (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
            original))))

(defun run-dmx-workspace-annotation-journal-preflight-unassigned-companion-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((topics (make-hash-table :test #'equal))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (create-client
           (make-instance 'journal-repair-observing-compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :authorization-header "Bearer test-token"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9455))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Journal preflight unassigned companion smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client create-client
            :dry-run nil))
         (stale-summary
           (workspace-annotation-smoke-reset-journal-stream-to-base
           create-client
           persisted))
         (journal-topic-id (getf stale-summary :existing-topic-id))
         (guard-client
           (make-instance
            'journal-repair-observing-compatibility-storage-http-dmx-import-client
            :base-url "https://dmx.ralfbarkow.ch"
            :authorization-header "Bearer test-token"
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :topics-by-external-key topics
            :topicmap-memberships topicmap-memberships
            :workspace-assignments workspace-assignments
            :next-topic-id 9555))
         (report
           (hyperdoc::run-dock-annotation-workspace-persistence-debug
            persisted
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client guard-client))
         (prepare-transition
           (hyperdoc::workspace-annotation-persistence-stage-result
            report
            :prepare-transition))
         (topic-upsert
           (hyperdoc::workspace-annotation-persistence-stage-result
            report
            :topic-upsert))
         (summary
           (hyperdoc::workspace-annotation-persistence-report-journal-preflight-summary-of
            report))
         (repair-summary
           (hyperdoc::workspace-annotation-journal-preflight-repair-summary
            report))
         (replacement-topic-id (getf repair-summary :replacement-topic-id))
         (current-journal-topic-id
           (hyperdoc::workspace-annotation-persistence-report-journal-topic-id-of
            report))
         (replacement-membership
           (and replacement-topic-id
                (gethash (list *dmx-annotations-smoke-workspace-topicmap-id*
                               replacement-topic-id)
                         topicmap-memberships)))
         (views
           (dmx-annotation-smoke-load-inspector-views-for-object report))
         (overview
           (dmx-annotation-smoke-find-view-by-title views "Overview"))
         (html
           (and overview
                (html-inspector-views:view-html overview))))
    (assert-equal 0
                  (length (journal-delete-topic-ids-of create-client))
                  "No-existing-companion persistence must keep using the normal journal create path without deleting any prior companion topic")
    (assert-true
     (= 1 (length (journal-create-observations-of create-client)))
     "No-existing-companion persistence must create exactly one initial journal companion topic")
    (assert-true
     journal-topic-id
     "The unassigned-companion smoke must start from an existing journal companion topic")
    (assert-equal nil
                  (getf stale-summary :assigned-workspace-id)
                  "The stale journal companion topic must start unassigned to exercise the DMX object-write boundary")
    (assert-equal :none
                  (getf stale-summary :assigned-workspace-status)
                  "The stale journal companion topic must classify as assigned-workspace none before the guarded write")
    (assert-equal :persisted
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   report)
                  "Existing unassigned journal companions must repair and continue instead of stopping at prepare-transition")
    (assert-true
     (null (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
            report))
     "Successful create-and-retain-stale repair must clear the prepare-transition failure boundary")
    (assert-true
     repair-summary
     "The repaired run must preserve structured journal companion repair evidence on the returned report")
    (assert-true
     (not (hyperdoc::workspace-annotation-journal-preflight-auth-blocked-p
           report))
     "Delete-and-recreate repair must not masquerade as journal auth-blocked failure")
    (assert-true
     (not (hyperdoc::workspace-annotation-auth-awaiting-p report))
     "Successful unassigned-companion repair must not classify as auth-awaiting")
    (assert-equal :completed
                  (getf prepare-transition :status)
                  "Repairing the stale unassigned companion must still complete the prepare-transition stage")
    (assert-equal :completed
                  (getf topic-upsert :status)
                  "After repair, the staged persist must continue beyond PREPARE-TRANSITION into topic-upsert")
    (assert-equal journal-topic-id
                  (getf summary :existing-topic-id)
                  "The report must preserve the stale journal companion topic id as repair history")
    (assert-equal "create-replacement-and-retain-stale"
                  (getf repair-summary :repair-strategy-label)
                  "Repair evidence must identify create-and-retain-stale as the chosen strategy")
    (assert-equal journal-topic-id
                  (getf repair-summary :stale-topic-id)
                  "Repair evidence must preserve the stale journal companion topic id explicitly")
    (assert-true
     (not (eql current-journal-topic-id journal-topic-id))
     "The current journal topic id must flip away from the stale companion id after successful recreate")
    (assert-equal replacement-topic-id
                  current-journal-topic-id
                  "The current journal topic id must equal the replacement companion id after successful recreate")
    (assert-true
     replacement-topic-id
     "Successful repair must preserve the replacement journal companion topic id")
    (assert-true
     (getf repair-summary :writable-workspace-context-used-p)
     "Create-and-retain-stale repair must record that the resolved writable workspace context was used")
    (assert-true
     (getf repair-summary :stale-topic-retained-p)
     "Successful repair must preserve that the stale companion topic was retained as history")
    (assert-true
     (getf repair-summary :stale-topic-superseded-p)
     "Successful repair must preserve that the stale companion topic was superseded by the replacement")
    (assert-true
     (null (getf repair-summary :stale-delete-attempted-p))
     "Create-and-retain-stale repair must not attempt stale delete")
    (assert-true
     (null (getf repair-summary :stale-delete-succeeded-p))
     "Create-and-retain-stale repair must not claim stale delete success")
    (assert-true
     (getf repair-summary :replacement-create-attempted-p)
     "Create-and-retain-stale repair must record that replacement create was attempted")
    (assert-true
     (getf repair-summary :replacement-create-succeeded-p)
     "Create-and-retain-stale repair must record that replacement create succeeded")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (getf repair-summary :assigned-workspace-id-after)
                  "Replacement companion topics must end up assigned to the intended workspace")
    (assert-true
     (getf repair-summary :hidden-placement-attempted-p)
     "Create-and-retain-stale repair must record that hidden placement was attempted")
    (assert-true
     (getf repair-summary :hidden-placement-succeeded-p)
     "Create-and-retain-stale repair must record that hidden placement succeeded")
    (assert-true
     (getf repair-summary :hidden-placement-enforced-p)
     "Create-and-retain-stale repair must record that hidden/off-canvas placement was enforced")
    (assert-equal "yes"
                  (getf repair-summary :resumed-past-prepare-transition-label)
                  "Successful repair must record that the run resumed beyond PREPARE-TRANSITION")
    (assert-true
     (null (journal-delete-topic-ids-of guard-client))
     "The stale journal companion topic must be retained as history instead of being deleted")
    (assert-true
     (= 1 (length (journal-create-observations-of guard-client)))
     "Create-and-retain-stale repair must create exactly one replacement journal companion topic during prepare-transition")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (getf (first (journal-create-observations-of guard-client))
                        :workspace-id)
                  "Replacement companion create must run under the resolved workspace request context")
    (assert-equal replacement-topic-id
                  (getf (first (journal-create-observations-of guard-client))
                        :topic-id)
                  "The create observation must preserve the replacement companion topic id")
    (assert-true
     (not (member journal-topic-id
                  (journal-update-topic-ids-of guard-client)
                  :test #'eql))
     "The old doomed direct update path against the stale companion id must not be attempted")
    (assert-equal replacement-topic-id
                  (or (first (journal-update-topic-ids-of guard-client))
                      replacement-topic-id)
                  "Any follow-on journal companion update after repair must target the replacement companion id rather than the stale id")
    (assert-true
     (<= (length (journal-update-topic-ids-of guard-client)) 1)
     "Successful repair must not perform a redundant direct update of the replacement companion before any later journal-transition update")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (gethash replacement-topic-id workspace-assignments)
                  "The replacement companion topic must be assigned to the intended workspace in live client state")
    (assert-true
     (workspace-annotation-smoke-journal-topic-id-p guard-client journal-topic-id)
     "The stale journal companion topic must remain present as retained history")
    (assert-true
     (workspace-annotation-smoke-hidden-view-props-p replacement-membership)
     "The replacement companion topic must be placed with the hidden/off-canvas journal view-props invariant")
    (assert-true
     overview
     "Repaired journal companion reports must still render an Overview view")
    (assert-true
     (stringp html)
     "Repaired journal companion reports must render Overview HTML")
    (assert-true
     (search "Journal companion repair" html :test #'char-equal)
     "The Overview must render a dedicated journal companion repair section")
    (assert-true
     (search "create-replacement-and-retain-stale" html :test #'char-equal)
     "The Overview must show create-and-retain-stale as the repair strategy")
    (assert-true
     (search (format nil "~D" journal-topic-id) html :test #'char-equal)
     "The Overview must keep the stale companion id visible as repair history")
    (assert-true
     (search (format nil "~D" replacement-topic-id) html :test #'char-equal)
     "The Overview must show the replacement companion id after successful recreate")
    (assert-true
     (search "Current journal companion topic id" html :test #'char-equal)
     "The Overview must distinguish the current journal companion id from the stale id history")
    (assert-true
     (search "Resumed beyond PREPARE-TRANSITION" html :test #'char-equal)
     "The Overview must render the report-level continuation outcome field explicitly")
    (assert-true
     (search ">yes<" html :test #'char-equal)
     "The repaired report must render resumed beyond PREPARE-TRANSITION = yes")
    (workspace-annotation-smoke-reset-journal-stream-to-base
     create-client
     persisted)
    (let* ((assigned-client
             (make-instance
              'journal-repair-observing-compatibility-storage-http-dmx-import-client
              :base-url "https://dmx.ralfbarkow.ch"
              :authorization-header "Bearer test-token"
              :workspace-id *dmx-annotations-smoke-workspace-id*
              :topics-by-external-key topics
              :topicmap-memberships topicmap-memberships
              :workspace-assignments workspace-assignments
              :next-topic-id 9655))
           (assigned-report
             (hyperdoc::run-dock-annotation-workspace-persistence-debug
              persisted
              :workspace-topicmap-id
              *dmx-annotations-smoke-workspace-topicmap-id*
              :client assigned-client))
           (assigned-prepare-transition
             (hyperdoc::workspace-annotation-persistence-stage-result
             assigned-report
             :prepare-transition))
           (assigned-summary
             (hyperdoc::workspace-annotation-persistence-report-journal-preflight-summary-of
              assigned-report))
           (assigned-journal-topic-id
             (hyperdoc::workspace-annotation-persistence-report-journal-topic-id-of
              assigned-report))
           (assigned-repair-summary
             (hyperdoc::workspace-annotation-journal-preflight-repair-summary
              assigned-report)))
      (assert-equal *dmx-annotations-smoke-workspace-id*
                    (getf assigned-summary :assigned-workspace-id)
                    "Already-assigned journal companions must preserve the assigned workspace in the preflight summary")
      (assert-equal :assigned
                    (getf assigned-summary :assigned-workspace-status)
                    "Already-assigned journal companions must classify as assigned")
      (assert-equal :persisted
       (hyperdoc::workspace-annotation-persistence-report-status-of
                     assigned-report)
                    "Already-assigned journal companions must keep using the normal guarded update path")
      (assert-true
       (null (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
              assigned-report))
       "Already-assigned journal companions must clear the prepare-transition failure once the workspace assignment exists")
      (assert-true
       (null assigned-repair-summary)
       "Already-assigned journal companions must keep using the old guarded update path unchanged instead of triggering create-and-retain-stale repair")
      (assert-equal :completed
                    (getf assigned-prepare-transition :status)
                    "Already-assigned journal companions must complete the journal preflight stage")
      (assert-equal replacement-topic-id
                    assigned-journal-topic-id
                    "Already-assigned journal companions must keep the retained-stale replacement companion as current identity")
      (assert-true
       (or (null (journal-update-topic-ids-of assigned-client))
           (member replacement-topic-id
                   (journal-update-topic-ids-of assigned-client)
                   :test #'eql))
       "Already-assigned journal companions may skip redundant journal companion updates once the replacement is already current, but must never fall back to stale-companion repair")
      (assert-true
       (null (journal-create-observations-of assigned-client))
       "Already-assigned journal companions must not create a second replacement topic")
      (assert-true
       (null (journal-delete-topic-ids-of assigned-client))
       "Already-assigned journal companions must not delete any retained history topic")
      (assert-true
       (not (hyperdoc::workspace-annotation-journal-preflight-unassigned-companion-topic-p
             assigned-report))
       "Assigned companion reports must not retain the unassigned classification"))))

(defun run-dmx-workspace-annotation-journal-preflight-repair-failure-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((topics (make-hash-table :test #'equal))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (create-client
           (make-instance 'journal-repair-observing-compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :authorization-header "Bearer test-token"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9755))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Journal repair failure smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client create-client
            :dry-run nil))
         (stale-summary
           (workspace-annotation-smoke-reset-journal-stream-to-base
            create-client
            persisted))
         (journal-topic-id (getf stale-summary :existing-topic-id))
         (failing-client
           (make-instance
            'journal-repair-observing-compatibility-storage-http-dmx-import-client
            :base-url "https://dmx.ralfbarkow.ch"
            :authorization-header "Bearer test-token"
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :fail-journal-hidden-placement-p t
            :topics-by-external-key topics
            :topicmap-memberships topicmap-memberships
            :workspace-assignments workspace-assignments
            :next-topic-id 9855))
         (report
           (hyperdoc::run-dock-annotation-workspace-persistence-debug
            persisted
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client failing-client))
         (prepare-transition
           (hyperdoc::workspace-annotation-persistence-stage-result
            report
            :prepare-transition))
         (repair-summary
           (hyperdoc::workspace-annotation-journal-preflight-repair-summary
            report))
         (replacement-topic-id (getf repair-summary :replacement-topic-id))
         (current-journal-topic-id
           (hyperdoc::workspace-annotation-persistence-report-journal-topic-id-of
            report))
         (views
           (dmx-annotation-smoke-load-inspector-views-for-object report))
         (overview
           (dmx-annotation-smoke-find-view-by-title views "Overview"))
         (html
           (and overview
                (html-inspector-views:view-html overview))))
    (assert-true
     journal-topic-id
     "The repair-failure smoke must start from an existing stale journal companion topic")
    (assert-equal :failed
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   report)
                  "Placement failure during create-and-retain-stale repair must surface as a failed persistence report")
    (assert-equal :prepare-transition
                  (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                   report)
                  "Repair failure must stay classified at PREPARE-TRANSITION")
    (assert-true
     (hyperdoc::workspace-annotation-journal-preflight-repair-failed-p report)
     "Placement failure after stale delete must classify as a journal companion repair failure")
    (assert-true
     (typep (hyperdoc::workspace-annotation-persistence-report-condition-of report)
            'hyperdoc::dmx-workspace-journal-companion-repair-failed-error)
     "Repair failure reports must preserve the dedicated journal companion repair condition")
    (assert-true
     repair-summary
     "Repair failure reports must preserve structured repair history")
    (assert-equal "create-replacement-and-retain-stale"
                  (getf repair-summary :repair-strategy-label)
                  "Repair failure reports must preserve the chosen create-and-retain-stale strategy")
    (assert-equal journal-topic-id
                  (getf repair-summary :stale-topic-id)
                  "Repair failure reports must preserve the stale companion topic id")
    (assert-true
     (getf repair-summary :stale-topic-retained-p)
     "Repair failure reports must preserve that the stale companion was retained")
    (assert-true
     (getf repair-summary :stale-topic-superseded-p)
     "Repair failure after replacement create must preserve stale-superseded truth")
    (assert-true
     (null (getf repair-summary :stale-delete-attempted-p))
     "Repair failure reports must preserve that stale delete was not attempted")
    (assert-true
     (getf repair-summary :replacement-create-attempted-p)
     "Repair failure reports must preserve that replacement create was attempted")
    (assert-true
     (getf repair-summary :replacement-create-succeeded-p)
     "Repair failure reports must preserve that replacement create succeeded before placement failed")
    (assert-true
     (getf repair-summary :hidden-placement-attempted-p)
     "Repair failure reports must preserve that hidden placement was attempted")
    (assert-true
     (not (getf repair-summary :hidden-placement-succeeded-p))
     "Repair failure reports must preserve that hidden placement did not succeed")
    (assert-equal replacement-topic-id
                  current-journal-topic-id
                  "On repair failure after recreate, the current journal companion id must reflect the last valid post-repair identity state")
    (assert-equal "no"
                  (getf repair-summary :resumed-past-prepare-transition-label)
                  "Repair failure reports must render resumed beyond PREPARE-TRANSITION = no")
    (assert-equal :error
                  (getf prepare-transition :status)
                  "Repair failure must leave the PREPARE-TRANSITION stage in error")
    (assert-true
     (null (journal-delete-topic-ids-of failing-client))
     "Repair failure history must preserve that stale delete did not happen")
    (assert-equal 1
                  (length (journal-create-observations-of failing-client))
                  "Repair failure after recreate must still preserve the created replacement topic observation")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (getf (first (journal-create-observations-of failing-client))
                        :workspace-id)
                  "Repair failure history must preserve the writable workspace context used for replacement create")
    (assert-true
     (not (member journal-topic-id
                  (journal-update-topic-ids-of failing-client)
                  :test #'eql))
     "Repair failure must still avoid the old doomed direct update path against the stale companion id")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (getf repair-summary :assigned-workspace-id-after)
                  "Repair failure after recreate must preserve the replacement companion workspace assignment when it was already established before failure")
    (assert-true
     overview
     "Repair failure reports must still render an Overview")
    (assert-true
     (stringp html)
     "Repair failure reports must render Overview HTML")
    (assert-true
     (search "Journal companion repair failed" html :test #'char-equal)
     "The Overview must render a dedicated repair failure section")
    (assert-true
     (search (format nil "~D" journal-topic-id) html :test #'char-equal)
     "The Overview must keep the stale companion id visible on repair failure")
    (assert-true
     (search (format nil "~D" replacement-topic-id) html :test #'char-equal)
     "The Overview must preserve the replacement companion id reached before placement failure")
    (assert-true
     (search "Resumed beyond PREPARE-TRANSITION" html :test #'char-equal)
     "Repair failure reports must still render the continuation outcome field")
    (assert-true
     (search ">no<" html :test #'char-equal)
     "Repair failure reports must render resumed beyond PREPARE-TRANSITION = no")
    (assert-true
     (null (search "Journal companion auth blocked" html :test #'char-equal))
     "Repair failure must not be rendered as a generic journal auth-blocked report")))

(defun run-dmx-workspace-annotation-journal-preflight-explicit-auth-continuation-smoke-test ()
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
                          :next-topic-id 9460))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Journal preflight continuation smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client create-client
            :dry-run nil))
         (saved-topic-id (hyperdoc::workspace-annotation-topic-id-of persisted))
         (assigned-journal-topic-id
           (workspace-annotation-smoke-assign-journal-topic-to-workspace
            create-client
            persisted))
         (journal-summary-before
           (workspace-annotation-smoke-journal-summary create-client persisted))
         (journal-topic-id (getf journal-summary-before :existing-topic-id))
         (guarded-journal-put-available-p nil)
         (captured-calls '())
         (original-summary
           (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary))
         (original-prepare
           (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition))
         (original-drakma
           (symbol-function 'drakma:http-request)))
    (labels ((journal-topic-json ()
               (let ((json (make-hash-table :test #'equal))
                     (children (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) journal-topic-id
                       (gethash "uri" json)
                       (or (getf journal-summary-before :note-uri) "")
                       (gethash "typeUri" json) "dmx.notes.note"
                       (gethash "value" json)
                       (or (getf journal-summary-before :note-title)
                           "Workspace journal")
                       (gethash "children" json) children)
                 json))
             (journal-topic-payload ()
               (list :external-key
                     (or (getf journal-summary-before :note-uri)
                         (getf journal-summary-before :subject-key)
                         "workspace-journal")
                     :type-uri "dmx.notes.note"
                     :value
                     (or (getf journal-summary-before :note-title)
                         "Workspace journal")
                     :children (make-hash-table :test #'equal)))
             (saved-annotation-topic-json-string ()
               (hyperdoc::encode-json-string
                (hyperdoc::dmx-import-read-topic
                 create-client
                 (hyperdoc::workspace-annotation-topic-id-of persisted))))
             (workspace-json-string ()
               (hyperdoc::encode-json-string
                (hyperdoc::memory-dmx-import-workspace-json
                 *dmx-annotations-smoke-workspace-id*)))
             (topicmap-memberships-json-string ()
               (format nil
                       "[{\"id\":~D}]"
                       *dmx-annotations-smoke-workspace-topicmap-id*)))
      (unwind-protect
          (progn
            (setf (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary)
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
                    journal-summary-before))
            (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
                  (lambda (client subject-key lookup-kind lookup-value
                           workspace-topicmap-id
                           &rest args
                           &key subject-uri subject-kind ownership-class
                             note-key note-kind
                           &allow-other-keys)
                    (declare (ignore subject-key lookup-kind lookup-value
                                     workspace-topicmap-id args subject-uri
                                     subject-kind ownership-class note-key
                                     note-kind))
                    (if guarded-journal-put-available-p
                        (hyperdoc::dmx-import-update-topic
                         client
                         (journal-topic-json)
                         (journal-topic-payload))
                        (signal-journal-preflight-http-401 journal-topic-id))))
            (setf (symbol-function 'drakma:http-request)
                  (lambda (url &key method additional-headers content-type
                              content content-length want-stream
                              &allow-other-keys)
                    (declare (ignore want-stream))
                    (push (list :url url
                                :method method
                                :headers additional-headers
                                :content-type content-type
                                :content content
                                :content-length content-length)
                          captured-calls)
                    (cond
                      ((search "/access-control/login" url :test #'char-equal)
                       (values (make-string-input-stream "")
                               204
                               '(("Set-Cookie" . "JSESSIONID=session-9470; Path=/; SameSite=Strict"))
                               nil
                               nil
                               "No Content"))
                      ((search "/core/topic/" url :test #'char-equal)
                       (if (eq method :put)
                           (values
                            (make-string-input-stream
                             (saved-annotation-topic-json-string))
                            200
                            '(("Content-Type" . "application/json"))
                            nil
                            nil
                            "OK")
                           (values
                            (make-string-input-stream
                             (saved-annotation-topic-json-string))
                            200
                            '(("Content-Type" . "application/json"))
                            nil
                            nil
                            "OK")))
                      ((search "/workspaces/object/" url :test #'char-equal)
                       (values
                        (make-string-input-stream
                         (workspace-json-string))
                        200
                        '(("Content-Type" . "application/json"))
                        nil
                        nil
                        "OK"))
                      ((search "/topicmaps/object/" url :test #'char-equal)
                       (values
                        (make-string-input-stream
                         (topicmap-memberships-json-string))
                        200
                        '(("Content-Type" . "application/json"))
                        nil
                        nil
                        "OK"))
                      (t
                       (error "Unexpected journal explicit-auth continuation HTTP call ~S"
                              url)))))
            (let* ((blocked
                     (hyperdoc::run-dock-annotation-workspace-persistence-debug
                      persisted
                      :workspace-topicmap-id
                      *dmx-annotations-smoke-workspace-topicmap-id*
                      :client create-client))
                   (continued
                     (progn
                       (setf guarded-journal-put-available-p t)
                       (hyperdoc::continue-workspace-annotation-journal-preflight-with-explicit-auth
                        blocked
                        :auth-mode :basic
                        :username "rgb"
                        :password "secret")))
                   (prepare-transition
                     (hyperdoc::workspace-annotation-persistence-stage-result
                      continued
                      :prepare-transition))
                   (topic-upsert
                     (hyperdoc::workspace-annotation-persistence-stage-result
                      continued
                      :topic-upsert))
                   (continued-client
                     (hyperdoc::workspace-annotation-persistence-report-client-of
                      continued))
                   (views
                     (dmx-annotation-smoke-load-inspector-views-for-object
                      continued))
                   (overview
                     (dmx-annotation-smoke-find-view-by-title views "Overview"))
                   (html
                     (and overview
                          (html-inspector-views:view-html overview)))
                   (calls (nreverse captured-calls))
                   (login-call
                     (find-if (lambda (call)
                                (search "/access-control/login"
                                        (getf call :url)
                                        :test #'char-equal))
                              calls))
                   (guarded-call
                     (find-if (lambda (call)
                                (and (eq (getf call :method) :put)
                                     (search (format nil "/core/topic/~D"
                                                     journal-topic-id)
                                             (getf call :url)
                                             :test #'char-equal)))
                              calls))
                   (topic-upsert-call
                     (find-if (lambda (call)
                                (and (eq (getf call :method) :put)
                                     (search (format nil "/core/topic/~D"
                                                     saved-topic-id)
                                             (getf call :url)
                                             :test #'char-equal)))
                              calls))
                   (retry-calls
                     (remove-if-not
                      (lambda (call)
                        (or (search "/access-control/login"
                                    (getf call :url)
                                    :test #'char-equal)
                            (and (eq (getf call :method) :put)
                                 (search (format nil "/core/topic/~D"
                                                 journal-topic-id)
                                         (getf call :url)
                                         :test #'char-equal))))
                      calls)))
              (assert-true
               (hyperdoc::workspace-annotation-journal-preflight-auth-blocked-p
                blocked)
               (format nil
                       "The continuation smoke must start from a journal-preflight auth-blocked report; got status=~S failure-stage=~S condition=~A"
                       (hyperdoc::workspace-annotation-persistence-report-status-of
                        blocked)
                       (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                        blocked)
                       (hyperdoc::workspace-annotation-persistence-report-condition-of
                        blocked)))
              (assert-equal assigned-journal-topic-id
                            journal-topic-id
                            "The continuation smoke must exercise an assigned existing journal companion topic before simulating the later auth boundary")
              (assert-equal :pending-auth
                            (hyperdoc::workspace-annotation-persistence-report-status-of
                             blocked)
                            "Journal-preflight auth-blocked reports must remain pending-auth before explicit continuation")
              (assert-true
               (hyperdoc::workspace-annotation-auth-awaiting-p blocked)
               "Journal-preflight auth-blocked reports must classify as auth-awaiting before explicit continuation")
              (assert-true
               (not (hyperdoc::workspace-annotation-pending-auth-p blocked))
               "Journal-preflight auth-blocked reports must stay separate from the post-topic-upsert guarded-boundary pending-auth continuation")
	              (assert-equal :persisted
	                            (hyperdoc::workspace-annotation-persistence-report-status-of
	                             continued)
	                            "Username/password explicit-auth journal continuation must rerun the staged persist successfully")
	              (assert-equal t
                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-invoked-p
                             continued)
                            "Successful username/password journal continuation must mark the returned report as a retry result")
	              (assert-true
	               (let ((value
	                       (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-request-id-of
	                        continued)))
	                 (and (stringp value)
	                      (> (length value) 0)))
	               "Successful username/password journal continuation must preserve a retry request id marker")
	              (assert-true
	               (let ((value
	                       (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-executed-at-label-of
	                        continued)))
	                 (and (stringp value)
	                      (> (length value) 0)))
	               "Successful username/password journal continuation must preserve a retry timestamp marker")
	              (assert-equal "username/password"
	                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-mode-label-of
	                             continued)
	                            "Successful username/password journal continuation must preserve the retry mode label")
	              (assert-equal "Journal-preflight explicit-auth continuation"
	                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-source-label-of
	                             continued)
	                            "Successful username/password journal continuation must preserve the retry source label")
	              (assert-equal 1
	                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-evidence-version-of
	                             continued)
	                            "Successful username/password journal continuation must expose the retry evidence version marker")
	              (assert-true
	               (null (hyperdoc::workspace-annotation-persistence-report-explicit-auth-attempt-context-of
	                      continued))
	               "Successful username/password journal continuation must not preserve a failed-attempt diagnostic context")
              (assert-true
               (null (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                      continued))
               "Successful journal continuation must clear the failure stage")
              (assert-equal :completed
                            (getf prepare-transition :status)
                            "Successful journal continuation must complete the prepare-transition stage")
              (assert-equal :completed
                            (getf topic-upsert :status)
                            "Successful journal continuation must advance through topic-upsert after the journal boundary clears")
              (assert-equal saved-topic-id
                            (hyperdoc::workspace-annotation-persistence-report-persisted-topic-id-of
                             continued)
                            "Successful journal continuation must keep updating the existing saved carrier topic instead of creating a new one")
              (assert-true
               topic-upsert-call
               "Successful journal continuation must continue from the cleared journal boundary into the annotation topic upsert")
              (assert-true
               (search "JSESSIONID="
                       (or (and continued-client
                                (hyperdoc::dmx-import-session-cookie-of continued-client))
                           "")
                       :test #'char-equal)
               "Successful username/password continuation must capture JSESSIONID on the explicit-auth client")
              (assert-equal 2
                            (length retry-calls)
                            "Successful username/password continuation must attempt login and then retry the guarded journal PUT")
              (assert-equal :post
                            (getf login-call :method)
                            "Successful username/password continuation must POST the DMX login bootstrap")
              (assert-true
               (search "Basic "
                       (or (cdr (assoc "Authorization"
                                       (getf login-call :headers)
                                       :test #'string-equal))
                           "")
                       :test #'char-equal)
               "Successful username/password continuation must send Basic auth on the bootstrap request")
              (assert-equal nil
                            (cdr (assoc "Authorization"
                                        (getf guarded-call :headers)
                                        :test #'string-equal))
                            "The guarded journal PUT must switch to session-backed auth after successful bootstrap")
	              (assert-equal "JSESSIONID=session-9470; dmx_workspace_id=919815"
	                            (cdr (assoc "Cookie"
	                                        (getf guarded-call :headers)
	                                        :test #'string-equal))
	                            "Successful username/password continuation must retry the guarded journal PUT with session-backed auth plus the workspace cookie")
	              (assert-true
	               overview
	               "Successful username/password journal continuation must still expose an Overview view")
	              (assert-true
	               (stringp html)
	               "Successful username/password journal continuation must render Overview HTML")
	              (assert-true
	               (search "Explicit-auth retry result" html :test #'char-equal)
	               "Successful username/password journal continuation must render the top-level retry marker")
	              (assert-true
	               (search "Continuation invoked" html :test #'char-equal)
	               "Successful username/password journal continuation must render that the retry was invoked")
	              (assert-true
	               (search "Retry executed at" html :test #'char-equal)
	               "Successful username/password journal continuation must render the retry timestamp marker")
	              (assert-true
	               (search "Retry request id" html :test #'char-equal)
	               "Successful username/password journal continuation must render the retry request id marker")
	              (assert-true
	               (search "Retry mode used" html :test #'char-equal)
	               "Successful username/password journal continuation must render the retry mode marker")
	              (assert-true
	               (search "Retry evidence version" html :test #'char-equal)
	               "Successful username/password journal continuation must render the retry evidence version marker")
	              (assert-true
	               (search "Original blocking attempt" html :test #'char-equal)
	               "Successful username/password journal continuation must preserve the original anonymous block as historical evidence")
	              (assert-true
	               (search "successful continuation report preserves the original anonymous journal-preflight block"
	                       html
	                       :test #'char-equal)
	               "Successful username/password journal continuation must explain why the original block is still shown")
	              (assert-true
	               (null (search "Explicit auth continuation attempt" html
	                             :test #'char-equal))
	               "Successful username/password journal continuation must not render the failed-retry-only subsection")
	              (assert-true
	               (null (search "Continue journal preflight with explicit auth" html
	                             :test #'char-equal))
	               "Successful username/password journal continuation must not re-render the retry form as if the journal boundary were still blocked")))
        (setf (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary)
              original-summary
              (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
              original-prepare
              (symbol-function 'drakma:http-request)
              original-drakma)))))

(defun run-dmx-workspace-annotation-journal-preflight-explicit-auth-bootstrap-failure-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
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
                          :next-topic-id 9465))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Journal preflight bootstrap failure smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client create-client
            :dry-run nil))
         (assigned-journal-topic-id
           (workspace-annotation-smoke-assign-journal-topic-to-workspace
            create-client
            persisted))
         (journal-summary-before
           (workspace-annotation-smoke-journal-summary create-client persisted))
         (journal-topic-id (getf journal-summary-before :existing-topic-id))
         (guarded-journal-put-available-p nil)
         (captured-calls '())
         (original-summary
           (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary))
         (original-prepare
           (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition))
         (original-drakma
           (symbol-function 'drakma:http-request)))
    (labels ((saved-annotation-topic-json-string ()
               (hyperdoc::encode-json-string
                (hyperdoc::dmx-import-read-topic
                 create-client
                 (hyperdoc::workspace-annotation-topic-id-of persisted))))
             (workspace-json-string ()
               (hyperdoc::encode-json-string
                (hyperdoc::memory-dmx-import-workspace-json
                 *dmx-annotations-smoke-workspace-id*)))
             (topicmap-memberships-json-string ()
               (format nil
                       "[{\"id\":~D}]"
                       *dmx-annotations-smoke-workspace-topicmap-id*)))
      (unwind-protect
          (progn
            (setf (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary)
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
                    journal-summary-before))
            (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
                  (lambda (client subject-key lookup-kind lookup-value
                           workspace-topicmap-id
                           &rest args
                           &key subject-uri subject-kind ownership-class
                             note-key note-kind
                           &allow-other-keys)
                    (declare (ignore subject-key lookup-kind lookup-value
                                     workspace-topicmap-id args subject-uri
                                     subject-kind ownership-class note-key
                                     note-kind))
                    (if guarded-journal-put-available-p
                        (error "Bootstrap failure smoke must not reach guarded journal PUT without a successful login")
                        (signal-journal-preflight-http-401 journal-topic-id))))
            (setf (symbol-function 'drakma:http-request)
                  (lambda (url &key method additional-headers content-type
                              content content-length want-stream
                              &allow-other-keys)
                    (declare (ignore want-stream))
                    (push (list :url url
                                :method method
                                :headers additional-headers
                                :content-type content-type
                                :content content
                                :content-length content-length)
                          captured-calls)
                    (cond
                      ((search "/access-control/login" url :test #'char-equal)
                       (values
                        (make-string-input-stream
                         "{\"error\":\"login-failed\"}")
                        401
                        '(("Content-Type" . "application/json"))
                        nil
                        nil
                        "Unauthorized"))
                      ((search "/core/topic/" url :test #'char-equal)
                       (values
                        (make-string-input-stream
                         (saved-annotation-topic-json-string))
                        200
                        '(("Content-Type" . "application/json"))
                        nil
                        nil
                        "OK"))
                      ((search "/workspaces/object/" url :test #'char-equal)
                       (values
                        (make-string-input-stream
                         (workspace-json-string))
                        200
                        '(("Content-Type" . "application/json"))
                        nil
                        nil
                        "OK"))
                      ((search "/topicmaps/object/" url :test #'char-equal)
                       (values
                        (make-string-input-stream
                         (topicmap-memberships-json-string))
                        200
                        '(("Content-Type" . "application/json"))
                        nil
                        nil
                        "OK"))
                      (t
                       (error "Unexpected journal explicit-auth bootstrap-failure HTTP call ~S"
                              url)))))
            (let* ((blocked
                     (hyperdoc::run-dock-annotation-workspace-persistence-debug
                      persisted
                      :workspace-topicmap-id
                      *dmx-annotations-smoke-workspace-topicmap-id*
                      :client create-client))
                   (failed
                     (progn
                       (setf guarded-journal-put-available-p t)
                       (hyperdoc::continue-workspace-annotation-journal-preflight-with-explicit-auth
                        blocked
                        :auth-mode :basic
                        :username "rgb"
                        :password "secret")))
                   (attempt-context
                     (hyperdoc::workspace-annotation-persistence-report-explicit-auth-attempt-context-of
                      failed))
                   (views (dmx-annotation-smoke-load-inspector-views-for-object
                           failed))
                   (overview
                     (dmx-annotation-smoke-find-view-by-title views "Overview"))
                   (html (and overview
                              (html-inspector-views:view-html overview)))
                   (calls (nreverse captured-calls))
                   (login-call
                     (find-if (lambda (call)
                                (search "/access-control/login"
                                        (getf call :url)
                                        :test #'char-equal))
                              calls))
                   (guarded-call
                     (find-if (lambda (call)
                                (and (eq (getf call :method) :put)
                                     (search "/core/topic/"
                                             (getf call :url)
                                             :test #'char-equal)))
                              calls))
                   (retry-calls
                     (remove-if-not
                      (lambda (call)
                        (or (search "/access-control/login"
                                    (getf call :url)
                                    :test #'char-equal)
                            (and (eq (getf call :method) :put)
                                 (search "/core/topic/"
                                         (getf call :url)
                                         :test #'char-equal))))
                      calls)))
              (assert-true
               (hyperdoc::workspace-annotation-journal-preflight-auth-blocked-p
                blocked)
               "The bootstrap-failure smoke must start from a journal-preflight auth-blocked report")
              (assert-equal assigned-journal-topic-id
                            journal-topic-id
                            "The bootstrap-failure smoke must exercise an assigned existing journal companion topic before simulating the later auth boundary")
              (assert-equal :pending-auth
                            (hyperdoc::workspace-annotation-persistence-report-status-of
                             failed)
                            "Bootstrap-failed journal continuation must remain pending-auth")
              (assert-equal :prepare-transition
                            (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                             failed)
                            "Bootstrap-failed journal continuation must stay staged at prepare-transition")
	              (assert-true
	               attempt-context
	               "Bootstrap-failed journal continuation must preserve explicit-auth attempt evidence")
	              (assert-equal t
	                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-invoked-p
	                             failed)
	                            "Bootstrap-failed journal continuation must mark the returned report as a retry result")
	              (assert-equal "username/password"
	                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-mode-label-of
	                             failed)
	                            "Bootstrap-failed journal continuation must preserve the retry mode label")
	              (assert-equal t
	                            (getf attempt-context :bootstrap-attempted-p)
	                            "Bootstrap-failed journal continuation must record that login was attempted")
              (assert-equal "/access-control/login"
                            (getf attempt-context :bootstrap-endpoint-path)
                            "Bootstrap-failed journal continuation must record the login endpoint")
              (assert-equal 401
                            (getf attempt-context :bootstrap-response-status-code)
                            "Bootstrap-failed journal continuation must record the login failure status")
              (assert-equal "Unauthorized"
                            (getf attempt-context :bootstrap-response-reason-phrase)
                            "Bootstrap-failed journal continuation must record the login failure reason")
              (assert-equal nil
                            (getf attempt-context :session-cookie-captured-p)
                            "Bootstrap-failed journal continuation must show that no JSESSIONID was captured")
              (assert-equal nil
                            (getf attempt-context :guarded-request-retried-p)
                            "Bootstrap-failed journal continuation must not claim the guarded journal PUT was retried")
              (assert-true
               (not (hyperdoc::workspace-annotation-journal-preflight-authorization-blocked-p
                     failed))
               "Bootstrap-failed journal continuation must not be misclassified as an authorization denial after successful authentication")
              (assert-equal "/access-control/login"
                            (getf attempt-context :final-failing-endpoint-path)
                            "Bootstrap-failed journal continuation must record the login endpoint as the final failing endpoint")
              (assert-equal 401
                            (getf attempt-context :final-failing-status-code)
                            "Bootstrap-failed journal continuation must record the login failure status as final status")
              (assert-equal "Bootstrap attempted and failed."
                            (getf attempt-context :attempt-diagnosis)
                            "Bootstrap-failed journal continuation must diagnose bootstrap failure precisely")
              (assert-equal 1
                            (length retry-calls)
                            "Bootstrap-failed journal continuation must attempt login and stop before the guarded journal PUT")
              (assert-equal :post
                            (getf login-call :method)
                            "Bootstrap-failed journal continuation must POST the DMX login bootstrap")
              (assert-true
               (search "Basic "
                       (or (cdr (assoc "Authorization"
                                       (getf login-call :headers)
                                       :test #'string-equal))
                           "")
                       :test #'char-equal)
               "Bootstrap-failed journal continuation must send Basic auth on the login request")
              (assert-true
               (null guarded-call)
               "Bootstrap-failed journal continuation must not reach the guarded journal PUT")
              (assert-true
               overview
               "Bootstrap-failed journal continuation must still expose an Overview view")
              (assert-true
               (stringp html)
               "Bootstrap-failed journal continuation must render Overview HTML")
	              (assert-true
	               (search "Explicit auth continuation attempt" html :test #'char-equal)
	               "The Overview must expose the explicit-auth retry subsection for bootstrap failures")
	              (assert-true
	               (search "Explicit-auth retry result" html :test #'char-equal)
	               "The Overview must expose the top-level retry marker for bootstrap failures")
	              (assert-true
	               (search "Retry request id" html :test #'char-equal)
	               "The Overview must expose the retry request id marker for bootstrap failures")
	              (assert-true
	               (search "Retry evidence version" html :test #'char-equal)
	               "The Overview must expose the retry evidence version marker for bootstrap failures")
	              (assert-true
	               (search "Bootstrap attempted and failed." html :test #'char-equal)
	               "The Overview must report bootstrap failure precisely")
              (assert-true
               (search "/access-control/login" html :test #'char-equal)
               "The Overview must expose the login endpoint for bootstrap failures")
              (assert-true
               (null (search "secret" html :test #'char-equal))
               "The Overview must never render the raw password during bootstrap failures")))
        (setf (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary)
              original-summary
              (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
              original-prepare
              (symbol-function 'drakma:http-request)
              original-drakma)))))

(defun run-dmx-workspace-annotation-journal-preflight-explicit-auth-failure-evidence-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
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
                          :next-topic-id 9470))
         (persisted
           (hyperdoc::persist-dock-annotation-to-workspace
            (make-test-dock-annotation
             :note "Journal preflight explicit-auth failure smoke")
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client create-client
            :dry-run nil))
         (assigned-journal-topic-id
           (workspace-annotation-smoke-assign-journal-topic-to-workspace
            create-client
            persisted))
         (journal-summary-before
           (workspace-annotation-smoke-journal-summary create-client persisted))
         (journal-topic-id (getf journal-summary-before :existing-topic-id))
         (guarded-journal-put-available-p nil)
         (captured-calls '())
         (original-summary
           (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary))
         (original-prepare
           (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition))
         (original-drakma (symbol-function 'drakma:http-request)))
	    (labels ((journal-topic-json ()
	               (let ((json (make-hash-table :test #'equal))
	                     (children (make-hash-table :test #'equal)))
	                 (setf (gethash "id" json) journal-topic-id
	                       (gethash "uri" json)
	                       (or (getf journal-summary-before :note-uri) "")
	                       (gethash "typeUri" json) "dmx.notes.note"
	                       (gethash "value" json)
	                       (or (getf journal-summary-before :note-title)
	                           "Workspace journal")
	                       (gethash "children" json) children)
	                 json))
	             (journal-topic-payload ()
	               (list :external-key
	                     (or (getf journal-summary-before :note-uri)
	                         (getf journal-summary-before :subject-key)
	                         "workspace-journal")
	                     :type-uri "dmx.notes.note"
	                     :value
	                     (or (getf journal-summary-before :note-title)
	                         "Workspace journal")
	                     :children (make-hash-table :test #'equal)))
	             (saved-annotation-topic-json ()
	               (hyperdoc::dmx-import-read-topic
	                create-client
	                (hyperdoc::workspace-annotation-topic-id-of persisted)))
	             (saved-annotation-topic-json-string ()
	               (hyperdoc::encode-json-string
	                (saved-annotation-topic-json)))
	             (workspace-json-string ()
	               (hyperdoc::encode-json-string
	                (hyperdoc::memory-dmx-import-workspace-json
	                 *dmx-annotations-smoke-workspace-id*)))
	             (topicmap-memberships-json-string ()
	               (format nil
	                       "[{\"id\":~D}]"
	                       *dmx-annotations-smoke-workspace-topicmap-id*)))
	      (unwind-protect
	          (progn
            (setf (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary)
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
                    journal-summary-before))
            (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
                  (lambda (client subject-key lookup-kind lookup-value
                           workspace-topicmap-id
                           &rest args
                           &key subject-uri subject-kind ownership-class
                             note-key note-kind
                           &allow-other-keys)
                    (declare (ignore subject-key lookup-kind lookup-value
                                     workspace-topicmap-id args subject-uri
                                     subject-kind ownership-class note-key
                                     note-kind))
                    (if guarded-journal-put-available-p
                        (hyperdoc::dmx-import-update-topic
                         client
                         (journal-topic-json)
                         (journal-topic-payload))
                        (signal-journal-preflight-http-401 journal-topic-id))))
            (setf (symbol-function 'drakma:http-request)
                  (lambda (url &key method additional-headers content-type
                              content content-length want-stream
                              &allow-other-keys)
                    (declare (ignore want-stream))
                    (push (list :url url
                                :method method
                                :headers additional-headers
                                :content-type content-type
                                :content content
                                :content-length content-length)
                          captured-calls)
	                    (cond
	                      ((search "/access-control/login" url :test #'char-equal)
	                       (values (make-string-input-stream "")
	                               204
                               '(("Set-Cookie" . "JSESSIONID=session-9470; Path=/; SameSite=Strict"))
                               nil
                               nil
                               "No Content"))
	                      ((search "/core/topic/" url :test #'char-equal)
	                       (if (eq method :put)
	                           (values
	                            (make-string-input-stream
	                             (format nil
	                                     "{\"error\":\"journal-retry-unauthorized\",\"cause\":\"user \\\"rgb\\\" has no WRITE permission for object ~D\"}"
	                                     journal-topic-id))
	                            401
	                            '(("Content-Type" . "application/json"))
	                            nil
	                            nil
	                            "Unauthorized")
	                           (values
	                            (make-string-input-stream
	                             (saved-annotation-topic-json-string))
	                            200
	                            '(("Content-Type" . "application/json"))
	                            nil
	                            nil
	                            "OK")))
	                      ((search "/workspaces/object/" url :test #'char-equal)
	                       (values
	                        (make-string-input-stream
	                         (workspace-json-string))
	                        200
	                        '(("Content-Type" . "application/json"))
	                        nil
	                        nil
	                        "OK"))
	                      ((search "/topicmaps/object/" url :test #'char-equal)
	                       (values
	                        (make-string-input-stream
	                         (topicmap-memberships-json-string))
	                        200
	                        '(("Content-Type" . "application/json"))
	                        nil
	                        nil
	                        "OK"))
	                      (t
	                       (error "Unexpected journal explicit-auth retry HTTP call ~S"
	                              url)))))
            (let* ((blocked
                     (hyperdoc::run-dock-annotation-workspace-persistence-debug
                      persisted
                      :workspace-topicmap-id
                      *dmx-annotations-smoke-workspace-topicmap-id*
                      :client create-client))
                   (failed
                     (progn
                       (setf guarded-journal-put-available-p t)
                       (hyperdoc::continue-workspace-annotation-journal-preflight-with-explicit-auth
                        blocked
                        :auth-mode :basic
                        :username "rgb"
                        :password "secret")))
	                   (attempt-context
	                     (hyperdoc::workspace-annotation-persistence-report-explicit-auth-attempt-context-of
	                      failed))
	                   (authorization-summary
	                     (hyperdoc::workspace-annotation-journal-preflight-authorization-summary
	                      failed))
	                   (original-context
	                     (hyperdoc::workspace-annotation-persistence-report-journal-preflight-auth-context-of
	                      failed))
	                   (views (dmx-annotation-smoke-load-inspector-views-for-object
	                           failed))
	                   (overview
	                     (dmx-annotation-smoke-find-view-by-title views "Overview"))
	                   (html (and overview
	                              (html-inspector-views:view-html overview)))
	                   (calls (nreverse captured-calls))
	                   (login-call
	                     (find-if (lambda (call)
	                                (search "/access-control/login"
	                                        (getf call :url)
	                                        :test #'char-equal))
	                              calls))
	                   (guarded-call
	                     (find-if (lambda (call)
	                                (and (eq (getf call :method) :put)
	                                     (search "/core/topic/"
	                                             (getf call :url)
	                                             :test #'char-equal)))
	                              calls))
	                   (retry-calls
	                     (remove-if-not
	                      (lambda (call)
	                        (or (search "/access-control/login"
	                                    (getf call :url)
	                                    :test #'char-equal)
	                            (and (eq (getf call :method) :put)
	                                 (search "/core/topic/"
	                                         (getf call :url)
	                                         :test #'char-equal))))
	                      calls)))
              (assert-true
               (hyperdoc::workspace-annotation-journal-preflight-auth-blocked-p
                blocked)
               "The explicit-auth failure smoke must start from a journal-preflight auth-blocked report")
              (assert-equal assigned-journal-topic-id
                            journal-topic-id
                            "The explicit-auth failure smoke must exercise an assigned existing journal companion topic before simulating the later auth boundary")
              (assert-true
               (typep failed 'hyperdoc::workspace-annotation-persistence-report)
               "Failed explicit-auth journal continuation must still return an inspectable persistence report")
              (assert-equal :pending-auth
                            (hyperdoc::workspace-annotation-persistence-report-status-of
                             failed)
                            "Failed explicit-auth journal continuation must preserve the auth-awaiting report status")
              (assert-equal :prepare-transition
                            (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                             failed)
                            "Failed explicit-auth journal continuation must stay staged at prepare-transition")
              (assert-true
               (hyperdoc::workspace-annotation-journal-preflight-authorization-blocked-p
                failed)
               "Authenticated journal-preflight retry denials must classify as authorization-blocked")
	              (assert-true
	               attempt-context
	               "Failed explicit-auth journal continuation must record a distinct explicit-auth attempt context")
              (assert-true
               authorization-summary
               "Authenticated journal-preflight retry denials must expose a structured authorization summary")
	              (assert-equal t
	                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-invoked-p
	                             failed)
	                            "Failed explicit-auth journal continuation must mark the returned report as a retry result")
	              (assert-equal "username/password"
	                            (hyperdoc::workspace-annotation-persistence-report-explicit-auth-retry-mode-label-of
	                             failed)
	                            "Failed explicit-auth journal continuation must preserve the retry mode label")
	              (assert-equal :basic
	                            (getf attempt-context :requested-auth-mode)
	                            "Failed explicit-auth journal continuation must record the selected username/password auth mode")
              (assert-equal "username/password"
                            (getf attempt-context :requested-auth-mode-label)
                            "Failed explicit-auth journal continuation must render a human-readable auth mode label")
              (assert-equal t
                            (getf attempt-context :selected-mode-credentials-present-p)
                            "Failed explicit-auth journal continuation must prove credentials were present for the selected mode")
              (assert-equal t
                            (getf attempt-context :username-present-p)
                            "Failed explicit-auth journal continuation must record that a username was provided")
              (assert-equal t
                            (getf attempt-context :password-present-p)
                            "Failed explicit-auth journal continuation must record that a password was provided without echoing it")
              (assert-equal t
                            (getf attempt-context :bootstrap-required-p)
                            "Username/password retry must record that a bootstrap login was required")
	              (assert-equal t
	                            (getf attempt-context :bootstrap-attempted-p)
	                            "Username/password retry failures must record that bootstrap/login was actually attempted")
	              (assert-equal "/access-control/login"
	                            (getf attempt-context :bootstrap-endpoint-path)
	                            "Failed explicit-auth journal continuation must record the bootstrap endpoint")
	              (assert-equal "Basic header"
	                            (getf attempt-context :bootstrap-request-auth-mode-summary)
	                            "Failed explicit-auth journal continuation must summarize bootstrap auth safely")
	              (assert-equal "Basic"
	                            (getf attempt-context :bootstrap-request-authorization-scheme)
	                            "Failed explicit-auth journal continuation must preserve the bootstrap authorization scheme")
	              (assert-equal 204
	                            (getf attempt-context :bootstrap-response-status-code)
	                            "Failed explicit-auth journal continuation must record the bootstrap response status")
	              (assert-equal "No Content"
	                            (getf attempt-context :bootstrap-response-reason-phrase)
	                            "Failed explicit-auth journal continuation must record the bootstrap response reason")
	              (assert-equal t
	                            (getf attempt-context :bootstrap-set-cookie-jsessionid-p)
	                            "Failed explicit-auth journal continuation must record that login returned Set-Cookie JSESSIONID")
	              (assert-equal t
	                            (getf attempt-context :session-cookie-captured-p)
	                            "Failed explicit-auth journal continuation must record that JSESSIONID was captured in memory")
	              (assert-equal t
	                            (getf attempt-context :guarded-request-retried-p)
	                            "Failed explicit-auth journal continuation must record that the guarded journal PUT was retried")
	              (assert-equal (format nil "/core/topic/~D" journal-topic-id)
	                            (getf attempt-context :guarded-request-endpoint-path)
	                            "Failed explicit-auth journal continuation must record the guarded journal PUT endpoint")
	              (assert-equal "session-only"
	                            (getf attempt-context :guarded-request-auth-mode-summary)
	                            "Failed explicit-auth journal continuation must prove the guarded journal PUT retried with session-backed auth")
	              (assert-equal "JSESSIONID + dmx_workspace_id"
	                            (getf attempt-context :guarded-request-cookie-shape)
	                            "Failed explicit-auth journal continuation must preserve the guarded request cookie shape safely")
	              (assert-equal nil
	                            (getf attempt-context :guarded-request-remained-anonymous-p)
	                            "Failed explicit-auth journal continuation must show when the guarded journal PUT did not remain anonymous")
              (assert-equal (format nil "/core/topic/~D" journal-topic-id)
                            (getf attempt-context :final-failing-endpoint-path)
                            "Failed explicit-auth journal continuation must record the final failing endpoint")
              (assert-equal 401
                            (getf attempt-context :final-failing-status-code)
                            "Failed explicit-auth journal continuation must record the final failing status")
              (assert-equal "Unauthorized"
                            (getf attempt-context :final-failing-reason-phrase)
                            "Failed explicit-auth journal continuation must record the final failing reason")
              (assert-equal
               (format nil
                       "user \"rgb\" has no WRITE permission for object ~D"
                       journal-topic-id)
               (getf attempt-context :response-cause)
               "Failed explicit-auth journal continuation must preserve the backend authorization cause text")
              (assert-equal t
                            (getf attempt-context :authentication-succeeded-p)
                            "Failed explicit-auth journal continuation must record successful authentication when login succeeded")
              (assert-equal "succeeded"
                            (getf attempt-context :authentication-status-label)
                            "Failed explicit-auth journal continuation must label authentication success explicitly")
              (assert-equal t
                            (getf attempt-context :authorization-failed-p)
                            "Failed explicit-auth journal continuation must record authorization failure explicitly")
              (assert-equal "failed"
                            (getf attempt-context :authorization-status-label)
                            "Failed explicit-auth journal continuation must label authorization failure explicitly")
              (assert-equal :authorization-failed
                            (getf attempt-context :retry-outcome-classification)
                            "Failed explicit-auth journal continuation must classify the retry outcome as authorization-failed")
              (assert-equal "authorization-failed"
                            (getf attempt-context :retry-outcome-classification-label)
                            "Failed explicit-auth journal continuation must preserve a readable retry outcome classification")
              (assert-equal "rgb"
                            (getf attempt-context :authenticated-principal)
                            "Failed explicit-auth journal continuation must record the authenticated principal from the denial cause")
              (assert-equal "WRITE"
                            (getf attempt-context :required-permission)
                            "Failed explicit-auth journal continuation must extract the required permission from the denial cause")
              (assert-equal journal-topic-id
                            (getf attempt-context :blocked-object-topic-id)
                            "Failed explicit-auth journal continuation must extract the blocked journal topic id from the denial cause")
              (assert-equal (format nil "/core/topic/~D" journal-topic-id)
                            (getf attempt-context :blocked-endpoint-path)
                            "Failed explicit-auth journal continuation must preserve the blocked journal endpoint in the authorization summary")
	              (assert-equal "Authentication succeeded, but the authenticated principal is not authorized to write the journal companion topic."
	                            (getf attempt-context :attempt-diagnosis)
	                            "Failed explicit-auth journal continuation must distinguish successful authentication from a later authorization denial on the journal companion write")
              (assert-true
               (null (getf original-context :explicit-auth-condition))
               "The original anonymous journal-preflight context must stay separate from the explicit-auth retry evidence")
              (assert-equal :authorization-failed
                            (getf authorization-summary :retry-outcome-classification)
                            "The authorization summary must preserve the structured retry outcome classification")
              (assert-equal "authorization-failed"
                            (getf authorization-summary :retry-outcome-classification-label)
                            "The authorization summary must preserve the readable retry outcome classification")
              (assert-equal t
                            (getf authorization-summary :authentication-succeeded-p)
                            "The authorization summary must preserve that authentication succeeded")
              (assert-equal "succeeded"
                            (getf authorization-summary :authentication-status-label)
                            "The authorization summary must render authentication success explicitly")
              (assert-equal t
                            (getf authorization-summary :authorization-failed-p)
                            "The authorization summary must preserve that authorization failed")
              (assert-equal "failed"
                            (getf authorization-summary :authorization-status-label)
                            "The authorization summary must render authorization failure explicitly")
              (assert-equal "rgb"
                            (getf authorization-summary :authenticated-principal)
                            "The authorization summary must preserve the authenticated principal")
              (assert-equal "WRITE"
                            (getf authorization-summary :required-permission)
                            "The authorization summary must preserve the required permission")
              (assert-equal journal-topic-id
                            (getf authorization-summary :blocked-object-topic-id)
                            "The authorization summary must preserve the blocked journal topic id")
              (assert-equal (format nil "/core/topic/~D" journal-topic-id)
                            (getf authorization-summary :blocked-endpoint-path)
                            "The authorization summary must preserve the blocked endpoint")
              (assert-equal
               (format nil
                       "user \"rgb\" has no WRITE permission for object ~D"
                       journal-topic-id)
               (getf authorization-summary :response-cause)
               "The authorization summary must preserve the backend denial cause text")
              (assert-equal "anonymous"
                            (getf (getf original-context :http-evidence)
                                  :auth-mode-summary)
                            "The original blocking attempt must remain inspectably anonymous")
	              (assert-equal 2
	                            (length retry-calls)
	                            "The failed explicit-auth retry must make one bootstrap call and one guarded journal PUT before later diagnostic reads")
	              (assert-equal :post
	                            (getf login-call :method)
	                            "The failed explicit-auth retry must POST the DMX login bootstrap")
	              (assert-true
	               (search "Basic "
	                       (or (cdr (assoc "Authorization"
	                                       (getf login-call :headers)
	                                       :test #'string-equal))
	                           "")
	                       :test #'char-equal)
	               "The failed explicit-auth retry must send Basic auth on the bootstrap request")
	              (assert-equal nil
	                            (cdr (assoc "Authorization"
	                                        (getf guarded-call :headers)
	                                        :test #'string-equal))
	                            "The guarded journal PUT must switch to session-backed auth after bootstrap")
	              (assert-equal "JSESSIONID=session-9470; dmx_workspace_id=919815"
	                            (cdr (assoc "Cookie"
	                                        (getf guarded-call :headers)
	                                        :test #'string-equal))
	                            "The guarded journal PUT must carry JSESSIONID plus the workspace cookie")
              (assert-true
               overview
               "Failed explicit-auth journal continuation must still expose an Overview view")
              (assert-true
               (stringp html)
               "Failed explicit-auth journal continuation must render Overview HTML")
	              (assert-true
	               (search "Original blocking attempt" html :test #'char-equal)
	               "The Overview must distinguish the original anonymous block from the explicit-auth retry attempt")
	              (assert-true
	               (search "Explicit-auth retry result" html :test #'char-equal)
	               "The Overview must expose the top-level retry marker for failed retries")
	              (assert-true
	               (search "Retry executed at" html :test #'char-equal)
	               "The Overview must expose the retry timestamp marker for failed retries")
	              (assert-true
	               (search "Retry request id" html :test #'char-equal)
	               "The Overview must expose the retry request id marker for failed retries")
	              (assert-true
	               (search "Retry evidence version" html :test #'char-equal)
	               "The Overview must expose the retry evidence version marker for failed retries")
              (assert-true
               (search "Retry outcome classification" html :test #'char-equal)
               "The Overview must expose the retry outcome classification near the top of the retry result")
              (assert-true
               (search "Authentication" html :test #'char-equal)
               "The Overview must expose authentication success explicitly near the retry result")
              (assert-true
               (search "Authorization" html :test #'char-equal)
               "The Overview must expose authorization failure explicitly near the retry result")
              (assert-true
               (search "Authenticated principal" html :test #'char-equal)
               "The Overview must expose the authenticated principal near the retry result")
              (assert-true
               (search "Required permission" html :test #'char-equal)
               "The Overview must expose the required permission near the retry result")
              (assert-true
               (search "Blocked object/topic id" html :test #'char-equal)
               "The Overview must expose the blocked journal topic id near the retry result")
              (assert-true
               (search "Blocked endpoint" html :test #'char-equal)
               "The Overview must expose the blocked journal endpoint near the retry result")
	              (assert-true
	               (search "Journal companion auth blocked" html :test #'char-equal)
	               "The Overview must preserve the original journal companion auth-blocked wording")
              (assert-true
               (search "Explicit auth continuation attempt" html :test #'char-equal)
               "The Overview must expose a dedicated explicit-auth retry subsection")
              (assert-true
               (search "Bootstrap/login attempted" html :test #'char-equal)
               "The Overview must expose whether bootstrap was attempted on the explicit-auth retry")
	              (assert-true
	               (search "Guarded journal PUT retried" html :test #'char-equal)
	               "The Overview must expose whether the guarded journal PUT was retried")
	              (assert-true
	               (search "authorization-failed"
	                       html
	                       :test #'char-equal)
	               "The Overview must expose the retry outcome classification value explicitly")
	              (assert-true
	               (search "succeeded"
	                       html
	                       :test #'char-equal)
	               "The Overview must expose authentication success explicitly")
	              (assert-true
	               (search "failed"
	                       html
	                       :test #'char-equal)
	               "The Overview must expose authorization failure explicitly")
	              (assert-true
	               (search "rgb"
	                       html
	                       :test #'char-equal)
	               "The Overview must expose the authenticated principal when authorization fails")
	              (assert-true
	               (search "WRITE"
	                       html
	                       :test #'char-equal)
	               "The Overview must expose the required permission when authorization fails")
	              (assert-true
	               (search "Authentication succeeded, but the authenticated principal is not authorized to write the journal companion topic."
	                       html
	                       :test #'char-equal)
	               "The Overview must distinguish authentication success from the later authorization denial on the guarded journal PUT")
	              (assert-true
	               (search "/access-control/login" html :test #'char-equal)
	               "The Overview must expose the bootstrap endpoint when the retry reached login")
	              (assert-true
	               (null (search "Credentials captured but no bootstrap attempted."
	                             html
	                             :test #'char-equal))
	               "Username/password explicit-auth continuation must not diagnose missing bootstrap when the retry path supports login")
	              (assert-true
	               (search (format nil "/core/topic/~D" journal-topic-id)
	                       html
                       :test #'char-equal)
               "The Overview must expose the final guarded journal PUT endpoint")
              (assert-true
               (search (format nil
                               "user &quot;rgb&quot; has no WRITE permission for object ~D"
                               journal-topic-id)
                       html
                       :test #'char-equal)
               "The Overview must surface the backend authorization cause without forcing operators into raw HTTP evidence")
              (assert-true
               (null (search "secret" html :test #'char-equal))
               "The Overview must never render the raw password")
	              (assert-true
	               (null (search "session-9470" html :test #'char-equal))
	               "The Overview must never render the raw JSESSIONID value")))
	        (setf (symbol-function 'hyperdoc::dmx-workspace-journal-preflight-summary)
	              original-summary
	              (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
              original-prepare
              (symbol-function 'drakma:http-request)
              original-drakma)))))

(defun run-dmx-workspace-annotation-explicit-auth-continuation-smoke-test ()
  (let* ((topics (make-hash-table :test #'equal))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (pending-client
           (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9300))
         (auth-client
           (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :authorization-header "Bearer explicit-test-token"
                          :assignment-auth-available-p t
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9301))
         (annotation (make-test-dock-annotation
                      :note "Continue after explicit auth"))
         (pending (hyperdoc::persist-dock-annotation-to-workspace
                   annotation
                   :workspace-topicmap-id
                   *dmx-annotations-smoke-workspace-topicmap-id*
                   :client pending-client
                   :dry-run nil))
         (saved-annotation
           (hyperdoc::workspace-annotation-persistence-report-saved-annotation-of
            pending))
         (assigned-journal-topic-id
           (workspace-annotation-smoke-ensure-assigned-journal-topic
            pending-client
            saved-annotation))
         (continued (hyperdoc::continue-workspace-annotation-persistence-with-explicit-auth
                     pending
                     :client auth-client))
         (topic-id
           (hyperdoc::workspace-annotation-persistence-report-persisted-topic-id-of
            continued))
         (persisted
           (hyperdoc::workspace-annotation-persistence-report-persisted-annotation-of
            continued)))
    (assert-equal :persisted
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   continued)
                  "Explicit-auth continuation must finish the remaining guarded live write")
    (assert-equal
     (workspace-annotation-smoke-journal-topic-id auth-client saved-annotation)
     assigned-journal-topic-id
     "Explicit-auth continuation smoke must assign the existing journal companion before the guarded continuation path reruns")
    (assert-true
     (typep persisted 'hyperdoc::workspace-dock-annotation)
     "Explicit-auth continuation must reopen the created carrier topic as a workspace annotation")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (gethash topic-id workspace-assignments)
                  "Explicit-auth continuation must assign the already-created topic to workspace 919815")
    (assert-true
     (hyperdoc::dmx-import-topic-in-topicmap-p
      auth-client
      *dmx-annotations-smoke-workspace-topicmap-id*
      topic-id)
     "Explicit-auth continuation must finish topicmap placement for the already-created topic")
    (assert-equal hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
                  (hyperdoc::workspace-annotation-storage-mode-of persisted)
                  "Explicit-auth continuation must preserve compatibility-storage reopen semantics")))

(defun run-dmx-workspace-annotation-preflighted-persist-via-compatibility-carrier-smoke-test ()
  (let* ((client (make-instance 'compatibility-storage-http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer test-token"
                                :workspace-id *dmx-annotations-smoke-workspace-id*
                                :next-topic-id 9300))
         (annotation (make-test-dock-annotation
                      :note "Persist via compatibility carrier"))
         (result (hyperdoc::persist-dock-annotation-to-workspace
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client
                  :dry-run nil))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of result))
         (carrier-topic (hyperdoc::dmx-import-read-topic client topic-id))
         (carrier-text (hyperdoc::dmx-json-child-value
                        carrier-topic
                        hyperdoc::*dmx-notes-text-type-uri*)))
    (assert-true
     (typep result 'hyperdoc::workspace-dock-annotation)
     "When compatibility storage is available, the normal live persist path must return the reopened workspace annotation instead of a blocked-state report")
    (assert-equal hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
                  (hyperdoc::workspace-annotation-storage-mode-of result)
                  "Compatibility-carrier live persist must reopen with the compatibility storage mode")
    (assert-equal hyperdoc::*dmx-notes-note-type-uri*
                  (hyperdoc::dmx-json-object-value carrier-topic "typeUri")
                  "Compatibility-carrier live persist must write a dmx.notes.note topic")
    (assert-true
     (search "\"nativePayload\"" carrier-text :test #'char-equal)
     "Compatibility-carrier live persist must preserve the native annotation payload inside the note carrier text")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (hyperdoc::workspace-annotation-workspace-id-of result)
                  "Compatibility-carrier live persist must still assign the topic to workspace 919815")))

(defun run-dmx-workspace-annotation-preflighted-persist-blocked-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer test-token"
                                :workspace-id *dmx-annotations-smoke-workspace-id*))
         (annotation (make-test-dock-annotation
                      :note "Blocked before create-topic"))
         (post-count 0)
         (original (symbol-function 'drakma:http-request)))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method &allow-other-keys)
                   (declare (ignore method))
                   (cond
                     ((search "/core/topic/uri/" url)
                      (values (make-string-input-stream "")
                              404
                              '(("Content-Type" . "application/json"))
                              nil nil "Not Found"))
                     ((search "/core/topic" url)
                      (incf post-count)
                      (error "Persist preflight must not reach create-topic when support is missing"))
                     (t
                      (error "Unexpected preflighted persist HTTP call ~S"
                             url)))))
           (let ((result (hyperdoc::persist-dock-annotation-to-workspace
                          annotation
                          :workspace-topicmap-id
                          *dmx-annotations-smoke-workspace-topicmap-id*
                          :client client
                          :dry-run nil)))
             (assert-true
              (typep result 'hyperdoc::workspace-annotation-backend-compatibility-report)
             "Preflighted live persist must return the blocked-state compatibility report when the backend is unsupported")
             (assert-equal :unsupported
                           (hyperdoc::workspace-annotation-backend-compatibility-report-status-of
                            result)
                           "Live backends must still block the normal persist path when both raw and compatibility carrier type support are unavailable")
             (assert-equal 0
                           post-count
                           "Unsupported live backends must be blocked before POST /core/topic is attempted")))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-workspace-annotation-local-first-save-smoke-test ()
  (hyperdoc::clear-hyperdoc-local-workspace-journal-store)
  (let* ((annotation (make-test-dock-annotation
                      :note "Local-first annotation save"))
         (saved (hyperdoc::persist-dock-annotation-local-first
                 annotation
                 :workspace-topicmap-id
                 *dmx-annotations-smoke-workspace-topicmap-id*))
         (subject-key (hyperdoc::workspace-annotation-topic-uri-of saved))
         (journal (hyperdoc::read-hyperdoc-topic-journal
                   :subject-key subject-key))
         (events (gethash "events" journal))
         (event-types (annotation-journal-event-types events))
         (current-state (gethash "currentState" journal))
         (reconstructed (hyperdoc::read-hyperdoc-local-workspace-annotation
                         :subject-key subject-key)))
    (assert-true
     (typep saved 'hyperdoc::workspace-dock-annotation)
     "Local-first save must return a typed workspace annotation object")
    (assert-equal nil
                  (hyperdoc::workspace-annotation-topic-id-of saved)
                  "Local-first save without materialization must not require a DMX topic id")
    (assert-equal "local-only"
                  (hyperdoc::workspace-annotation-status-of saved)
                  "Local-first save must classify the saved annotation as local-only")
    (assert-true
     (member "create-topic" event-types :test #'string=)
     "Local-first save must append a create-topic-style local journal event")
    (assert-equal nil
                  (gethash "workspaceId" current-state)
                  "Local-first save must not claim a live DMX workspace assignment")
    (assert-equal (hyperdoc::note-of annotation)
                  (hyperdoc::note-of reconstructed)
                  "Local-first annotation must be reconstructable from HyperDoc-local journal payload alone")
    (assert-equal (hyperdoc::summary-of annotation)
                  (hyperdoc::summary-of reconstructed)
                  "Local-first reconstruction must preserve annotation summary")))

(defun run-dmx-workspace-annotation-local-first-materialize-compatibility-smoke-test ()
  (hyperdoc::clear-hyperdoc-local-workspace-journal-store)
  (let* ((client (make-instance 'compatibility-storage-http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer test-token"
                                :workspace-id *dmx-annotations-smoke-workspace-id*
                                :next-topic-id 9310))
         (annotation (make-test-dock-annotation
                      :note "Local-first with DMX materialization"))
         (result (hyperdoc::persist-dock-annotation-local-first
                  annotation
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client
                  :materialize-to-dmx-p t))
         (subject-key (hyperdoc::workspace-annotation-topic-uri-of result))
         (topic-id (hyperdoc::workspace-annotation-topic-id-of result))
         (journal (hyperdoc::read-hyperdoc-topic-journal
                   :subject-key subject-key))
         (events (gethash "events" journal))
         (event-types (annotation-journal-event-types events))
         (current-state (gethash "currentState" journal)))
    (assert-true
     (typep result 'hyperdoc::workspace-dock-annotation)
     "Local-first materialize path must still reopen as workspace-dock-annotation")
    (assert-equal hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
                  (hyperdoc::workspace-annotation-storage-mode-of result)
                  "Optional DMX materialization must keep the compatibility carrier path when available")
    (assert-true
     (integerp topic-id)
     "Optional DMX materialization success must capture the resulting topic id")
    (assert-equal topic-id
                  (gethash "topicId" current-state)
                  "Local journal current state must preserve the projected DMX topic id")
    (assert-equal *dmx-annotations-smoke-workspace-id*
                  (gethash "workspaceId" current-state)
                  "Local journal current state must preserve projected workspace assignment metadata")
    (assert-equal t
                  (gethash "inTopicmap" current-state)
                  "Local journal current state must preserve projected topicmap membership metadata")
    (assert-true
     (member "repair-workspace-assignment" event-types :test #'string=)
     "Local-first projection should record assignment materialization transition locally")
    (assert-true
     (member "restore-topicmap-membership" event-types :test #'string=)
     "Local-first projection should record topicmap materialization transition locally")))

(defun run-dmx-workspace-annotation-local-first-pending-auth-continuation-smoke-test ()
  (hyperdoc::clear-hyperdoc-local-workspace-journal-store)
  (let* ((topics (make-hash-table :test #'equal))
         (topicmap-memberships (make-hash-table :test #'equal))
         (workspace-assignments (make-hash-table :test #'eql))
         (pending-client
           (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9320))
         (auth-client
           (make-instance 'pending-auth-compatibility-storage-http-dmx-import-client
                          :base-url "https://dmx.ralfbarkow.ch"
                          :workspace-id *dmx-annotations-smoke-workspace-id*
                          :authorization-header "Bearer explicit-test-token"
                          :assignment-auth-available-p t
                          :topics-by-external-key topics
                          :topicmap-memberships topicmap-memberships
                          :workspace-assignments workspace-assignments
                          :next-topic-id 9321))
         (annotation (make-test-dock-annotation
                      :note "Local-first pending-auth continuation"))
         (blocked (hyperdoc::persist-dock-annotation-local-first
                   annotation
                   :workspace-topicmap-id
                   *dmx-annotations-smoke-workspace-topicmap-id*
                   :client pending-client
                   :materialize-to-dmx-p t))
         (saved-topic-id
           (hyperdoc::workspace-annotation-persistence-report-saved-topic-id-of
            blocked))
         (saved-annotation
           (hyperdoc::workspace-annotation-persistence-report-saved-annotation-of
            blocked))
         (subject-key
           (or (and saved-annotation
                    (hyperdoc::workspace-annotation-topic-uri-of
                     saved-annotation))
               (hyperdoc::dmx-workspace-annotation-write-plan-uri
                (hyperdoc::workspace-annotation-persistence-report-plan-of
                 blocked))))
         (journal (hyperdoc::read-hyperdoc-topic-journal
                   :subject-key subject-key))
         (journal-json-string (hyperdoc::encode-json-string journal))
         (current-state (gethash "currentState" journal))
         (carrier-topic (hyperdoc::dmx-import-read-topic pending-client saved-topic-id))
         (carrier-text (or (and carrier-topic
                                (hyperdoc::dmx-json-child-value
                                 carrier-topic
                                 hyperdoc::*dmx-notes-text-type-uri*))
                           ""))
         (continued (hyperdoc::continue-workspace-annotation-persistence-with-explicit-auth
                     blocked
                     :client auth-client)))
    (assert-true
     (typep blocked 'hyperdoc::workspace-annotation-persistence-report)
     "Local-first materialization auth blocks must still return a continuation report")
    (assert-equal :pending-auth
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   blocked)
                  "Local-first materialization must preserve the pending-auth continuation boundary when assignment auth is missing")
    (assert-true
     (integerp saved-topic-id)
     "Local-first pending-auth reports must preserve the created topic id for continuation")
    (assert-equal saved-topic-id
                  (gethash "topicId" current-state)
                  "Local journal current state must preserve the created topic id after materialization blocks")
    (assert-equal nil
                  (gethash "workspaceId" current-state)
                  "Blocked local-first materialization must not claim completed workspace assignment")
    (assert-equal :persisted
                  (hyperdoc::workspace-annotation-persistence-report-status-of
                   continued)
                  "Local-first pending-auth reports must continue through the existing explicit-auth continuation path")
    (assert-true
     (null (search "explicit-test-token"
                   journal-json-string
                   :test #'char-equal))
     "Action-time authorization tokens must not be serialized into HyperDoc-local journal state")
    (assert-true
     (null (search "Authorization"
                   journal-json-string
                   :test #'char-equal))
     "Authorization header metadata must not be serialized into HyperDoc-local journal state")
    (assert-true
     (null (search "Cookie"
                   journal-json-string
                   :test #'char-equal))
     "Cookie header metadata must not be serialized into HyperDoc-local journal state")
    (assert-true
     (null (search "JSESSIONID"
                   journal-json-string
                   :test #'char-equal))
     "Session cookies must not be serialized into HyperDoc-local journal state")
    (assert-true
     (null (search "explicit-test-token"
                   carrier-text
                   :test #'char-equal))
     "Action-time authorization tokens must not be serialized into compatibility carrier text")
    (assert-true
     (null (search "Authorization"
                   carrier-text
                   :test #'char-equal))
     "Authorization headers must not be serialized into compatibility carrier text")
    (assert-true
     (null (search "Cookie"
                   carrier-text
                   :test #'char-equal))
     "Cookie headers must not be serialized into compatibility carrier text")
    (assert-true
     (null (search "JSESSIONID"
                   carrier-text
                   :test #'char-equal))
     "Session cookies must not be serialized into compatibility carrier text")))

(defun run-dmx-workspace-annotation-workspace-view-scxml-contract-smoke-test ()
  (asdf:load-system :hyperdoc/scxml)
  (let* ((scxml-path
           (asdf:system-relative-pathname
            :hyperdoc
            "hyperdoc/dmx-annotation-workspace-view.scxml"))
         (chart (hyperdoc/scxml:parse-scxml-file scxml-path))
         (findings (hyperdoc/scxml:validate-scxml-chart chart))
         (errors
           (remove-if-not (lambda (finding)
                            (eq :error
                                (hyperdoc/scxml:scxml-validation-finding-severity-of
                                 finding)))
                          findings)))
    (assert-true
     (null errors)
     (format nil "Workspace view SCXML must validate without errors: ~S"
             (mapcar #'hyperdoc/scxml:scxml-validation-finding-code-of
                     errors))))
  (hyperdoc::clear-hyperdoc-local-workspace-journal-store)
  (let* ((draft (make-test-dock-annotation
                 :note "Workspace view SCXML contract draft"))
         (draft-run
           (hyperdoc::make-dmx-annotation-workspace-view-run
            draft
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :materialize-to-dmx-p nil))
         (draft-save-result
           (hyperdoc::persist-dock-annotation-local-first
            draft
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :materialize-to-dmx-p nil))
         (draft-materialize-run
           (hyperdoc::make-dmx-annotation-workspace-view-run
            draft
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :materialize-to-dmx-p t))
         (locally-saved draft-save-result)
         (locally-saved-run
           (hyperdoc::make-dmx-annotation-workspace-view-run
            locally-saved
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :materialize-to-dmx-p nil))
         (topic-backed-draft
           (make-test-dock-annotation
            :note "Workspace view SCXML contract continuation"))
         (_set-topic-id
           (setf (slot-value topic-backed-draft 'hyperdoc::target-object) 936040))
         (topic-backed-run
           (hyperdoc::make-dmx-annotation-workspace-view-run
            topic-backed-draft
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :materialize-to-dmx-p nil))
         (projected locally-saved)
         (_projected-topic-id
           (setf (slot-value projected 'hyperdoc::workspace-topic-id) 936041))
         (_projected-workspace-id
           (setf (slot-value projected 'hyperdoc::workspace-id)
                 *dmx-annotations-smoke-workspace-id*))
         (_projected-status
           (setf (slot-value projected 'hyperdoc::workspace-status)
                 "persisted"))
         (projected-run
           (hyperdoc::make-dmx-annotation-workspace-view-run
            projected
            :workspace-topicmap-id
            *dmx-annotations-smoke-workspace-topicmap-id*
            :client nil
            :materialize-to-dmx-p nil))
         (plan-views
           (dmx-annotation-smoke-load-inspector-views-for-object draft-run))
         (plan-overview
           (dmx-annotation-smoke-find-view-by-title
            plan-views
            "DMX annotation Workspace view SCXML plan"))
         (plan-actions
           (dmx-annotation-smoke-find-view-by-title
            plan-views
            "Actions"))
         (plan-overview-html
           (and plan-overview
                (html-inspector-views:view-html plan-overview)))
         (plan-actions-html
           (and plan-actions
                (html-inspector-views:view-html plan-actions))))
    (declare (ignore _set-topic-id
                     _projected-topic-id
                     _projected-workspace-id
                     _projected-status))
    (assert-equal
     "draftLocal"
     (hyperdoc::dmx-annotation-workspace-view-run-current-state-of draft-run)
     "Draft annotations must classify to draftLocal")
    (assert-equal
     "SAVE_LOCAL"
     (hyperdoc::dmx-annotation-workspace-view-run-selected-preview-event-of
      draft-run)
     "Draft-local/no-materialize path must preview SAVE_LOCAL")
    (assert-equal
     "Record local annotation"
     (hyperdoc::dmx-annotation-workspace-view-run-primary-action-label-of
      draft-run)
     "Draft-local/no-materialize path primary action must be Record local annotation")
    (assert-true
     (null
      (hyperdoc::dmx-annotation-workspace-view-run-dmx-http-will-run-p-of
       draft-run))
     "Draft-local/no-materialize path must keep DMX HTTP disabled")
    (assert-true
     (null
      (hyperdoc::dmx-annotation-workspace-view-run-topic-upsert-will-run-p-of
       draft-run))
     "Draft-local/no-materialize path must keep TOPIC_UPSERT disabled")
    (assert-true
     (typep draft-save-result 'hyperdoc::workspace-dock-annotation)
     "Draft local save must return a local workspace-dock-annotation object")
    (assert-true
     (not (typep draft-save-result
                 'hyperdoc::workspace-annotation-persistence-report))
     "Draft local save must not return a workspace-annotation-persistence-report")
    (assert-equal
     "SAVE_LOCAL_AND_MATERIALIZE"
     (hyperdoc::dmx-annotation-workspace-view-run-selected-preview-event-of
      draft-materialize-run)
     "Draft/local + materialize selector must preview SAVE_LOCAL_AND_MATERIALIZE")
    (assert-true
     (search "materializationPreflight"
             (format nil "~{~A~^, ~}"
                     (hyperdoc::dmx-annotation-workspace-view-run-next-states-of
                      draft-materialize-run))
             :test #'char-equal)
     "Draft/local + materialize selector must preview transition to materializationPreflight")
    (assert-true
     (hyperdoc::dmx-annotation-workspace-view-run-local-save-authoritative-p-of
      draft-materialize-run)
     "Local save must remain authoritative even when materialization is selected")
    (assert-equal
     "locallySaved"
     (hyperdoc::dmx-annotation-workspace-view-run-current-state-of
      locally-saved-run)
     "Locally saved unprojected annotations must classify to locallySaved")
    (assert-equal
     "Materialize to DMX"
     (hyperdoc::dmx-annotation-workspace-view-run-primary-action-label-of
      locally-saved-run)
     "Locally saved unprojected annotations must expose Materialize to DMX as primary action")
    (assert-true
     (hyperdoc::dmx-annotation-workspace-view-run-topic-upsert-will-run-p-of
      locally-saved-run)
     "Locally saved unprojected materialization preview must allow TOPIC_UPSERT")
    (assert-equal
     "projectionPending"
     (hyperdoc::dmx-annotation-workspace-view-run-current-state-of
      topic-backed-run)
     "Existing topic-backed annotations must classify to projectionPending")
    (assert-equal
     "Continue DMX projection"
     (hyperdoc::dmx-annotation-workspace-view-run-primary-action-label-of
      topic-backed-run)
     "Existing topic-backed annotations must expose Continue DMX projection as primary action")
    (assert-true
     (null
      (hyperdoc::dmx-annotation-workspace-view-run-topic-upsert-will-run-p-of
       topic-backed-run))
     "Existing topic-backed continuation preview must keep TOPIC_UPSERT disabled")
    (assert-equal
     *dmx-annotations-smoke-workspace-id*
     (hyperdoc::dmx-annotation-workspace-view-run-workspace-id-of
      topic-backed-run)
     "Continuation preview must target workspace 919815")
    (assert-equal
     *dmx-annotations-smoke-workspace-topicmap-id*
     (hyperdoc::dmx-annotation-workspace-view-run-workspace-topicmap-id-of
      topic-backed-run)
     "Continuation preview must target topicmap 919822")
    (assert-true
     (typep projected 'hyperdoc::workspace-dock-annotation)
     "Projected-complete fixture must be a workspace-dock-annotation")
    (assert-equal
     "projectedComplete"
     (hyperdoc::dmx-annotation-workspace-view-run-current-state-of projected-run)
     "Projected-complete annotations must classify to projectedComplete")
    (assert-equal
     "Inspect or reopen annotation"
     (hyperdoc::dmx-annotation-workspace-view-run-primary-action-label-of
      projected-run)
     "Projected-complete annotations must expose reopen/inspect, not save, as primary action")
    (assert-true
     plan-overview
     "Workspace-view SCXML run object must expose an overview inspector view")
    (assert-true
     plan-actions
     "Workspace-view SCXML run object must expose an actions inspector view")
    (assert-true
     (search "Selected preview event" plan-overview-html :test #'char-equal)
     "Workspace-view SCXML overview must render selected preview event")
    (assert-true
     (search "Target workspace id" plan-overview-html :test #'char-equal)
     "Workspace-view SCXML overview must render target workspace id")
    (assert-true
     (search "Target topicmap id" plan-overview-html :test #'char-equal)
     "Workspace-view SCXML overview must render target topicmap id")
    (assert-true
     (search "Explain boundary ownership" plan-actions-html :test #'char-equal)
     "Workspace-view SCXML actions view must expose Explain boundary ownership")))

(defun run-dmx-workspace-annotation-workspace-view-local-first-ux-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (hyperdoc::clear-hyperdoc-local-workspace-journal-store)
  (let* ((draft (make-test-dock-annotation
                 :note "Workspace view local-first draft"))
         (draft-views (dmx-annotation-smoke-load-inspector-views-for-object draft))
         (draft-workspace-view
           (dmx-annotation-smoke-find-view-by-title draft-views "Workspace"))
         (draft-html (and draft-workspace-view
                          (html-inspector-views:view-html draft-workspace-view)))
         (locally-saved (hyperdoc::persist-dock-annotation-local-first
                         draft
                         :workspace-topicmap-id
                         *dmx-annotations-smoke-workspace-topicmap-id*))
         (saved-views
           (dmx-annotation-smoke-load-inspector-views-for-object locally-saved))
         (saved-workspace-view
           (dmx-annotation-smoke-find-view-by-title saved-views "Workspace"))
         (saved-html (and saved-workspace-view
                          (html-inspector-views:view-html saved-workspace-view)))
         (topic-backed-draft (make-test-dock-annotation
                              :note "Workspace view continuation routing"))
         (_set-topic-id
           (setf (slot-value topic-backed-draft 'hyperdoc::target-object) 936040))
         (topic-backed-views
           (dmx-annotation-smoke-load-inspector-views-for-object topic-backed-draft))
         (topic-backed-workspace-view
           (dmx-annotation-smoke-find-view-by-title topic-backed-views "Workspace"))
         (topic-backed-html
           (and topic-backed-workspace-view
                (html-inspector-views:view-html topic-backed-workspace-view))))
    (declare (ignore _set-topic-id))
    (assert-true
     (search "Record local annotation"
             draft-html
             :test #'char-equal)
     "Draft workspace view must expose Record local annotation as the primary action")
    (assert-true
     (search "Current SCXML state"
             draft-html
             :test #'char-equal)
     "Draft workspace view must expose SCXML current state in the preview table")
    (assert-true
     (search "draftLocal"
             draft-html
             :test #'char-equal)
     "Draft workspace preview must classify current state as draftLocal")
    (assert-true
     (search "SAVE_LOCAL"
             draft-html
             :test #'char-equal)
     "Draft workspace preview must show SAVE_LOCAL as the selected event")
    (assert-true
     (search "Next event mutates DMX"
             draft-html
             :test #'char-equal)
     "Draft workspace preview must expose whether the selected event mutates DMX")
    (assert-true
     (search "TOPIC_UPSERT"
             draft-html
             :test #'char-equal)
     "Draft workspace preview must expose TOPIC_UPSERT effect flags in the action table")
    (assert-true
     (search "Record local annotation and materialize to DMX"
             draft-html
             :test #'char-equal)
     "Draft workspace view must expose optional local-save-and-materialize action")
    (assert-true
     (null (search "Persist to workspace"
                   draft-html
                   :test #'char-equal))
     "Draft workspace view must no longer expose Persist to workspace")
    (assert-true
     (search "Local journal lane"
             saved-html
             :test #'char-equal)
     "Locally saved annotations must render the Local journal lane in the Workspace dashboard")
    (assert-true
     (search "Materialize to DMX"
             saved-html
             :test #'char-equal)
     "Locally saved annotations must offer a dedicated Materialize to DMX action")
    (assert-true
     (search "locallySaved"
             saved-html
             :test #'char-equal)
     "Locally saved annotations must render locallySaved as current SCXML state")
    (assert-true
     (null (search "Persist to workspace"
                   saved-html
                   :test #'char-equal))
     "Locally saved annotations must no longer expose Persist to workspace")
    (assert-true
     (search "Continue DMX projection"
             topic-backed-html
             :test #'char-equal)
     "Topic-backed annotations must route to guarded continuation in workspace view")
    (assert-true
     (search "projectionPending"
             topic-backed-html
             :test #'char-equal)
     "Topic-backed annotations must render projectionPending as current SCXML state")
    (assert-true
     (null (search "Record local annotation"
                   topic-backed-html
                   :test #'char-equal))
     "Topic-backed annotations must not expose Record local annotation as primary action")
    (assert-true
     (search "TOPIC_UPSERT"
             topic-backed-html
             :test #'char-equal)
     "Topic-backed annotations must render TOPIC_UPSERT effect flags in the action table")
    (assert-true
     (null (search "Persist to workspace"
                   topic-backed-html
                   :test #'char-equal))
     "Topic-backed annotations must not route through raw Persist to workspace action")))

(defun run-dmx-annotations-smoke-tests ()
  (run-dmx-workspace-annotation-plan-smoke-test)
  (run-dmx-workspace-annotation-compatibility-plan-smoke-test)
  (run-dmx-workspace-annotation-dry-run-smoke-test)
  (run-dmx-workspace-annotation-live-smoke-tests-if-enabled)
  (run-dmx-workspace-annotation-supersede-smoke-test)
  (run-dmx-workspace-annotation-restore-smoke-test)
  (run-dmx-workspace-annotation-debug-surface-smoke-test)
  (run-dmx-workspace-annotation-compare-surface-smoke-test)
  (run-dmx-workspace-annotation-debug-report-success-smoke-test)
  (run-dmx-workspace-annotation-debug-report-failure-smoke-test)
  (run-dmx-workspace-annotation-unicode-transport-diagnostics-smoke-test)
  (run-dmx-workspace-annotation-destination-default-resolution-smoke-test)
  (run-dmx-workspace-annotation-destination-persisted-reuse-smoke-test)
  (run-dmx-workspace-annotation-destination-explicit-override-smoke-test)
  (run-dmx-workspace-annotation-backend-compatibility-probe-smoke-test)
  (run-dmx-http-unicode-json-request-smoke-test)
  (run-dmx-workspace-annotation-live-create-topic-failure-evidence-smoke-test)
  (run-dmx-workspace-annotation-create-topic-probe-render-smoke-test)
  (run-dmx-workspace-annotation-default-live-client-resolution-smoke-test)
  (run-dmx-workspace-annotation-environment-basic-service-auth-smoke-test)
  (run-dmx-http-workspace-assignment-cookie-context-smoke-test)
  (run-dmx-http-topicmap-mutation-workspace-cookie-context-smoke-test)
  (run-dmx-workspace-annotation-no-client-pending-auth-smoke-test)
  (run-dmx-workspace-annotation-pending-auth-smoke-test)
  (run-dmx-workspace-annotation-pending-auth-render-smoke-test)
  (run-dmx-workspace-annotation-pending-auth-compare-smoke-test)
  (run-dmx-workspace-annotation-assignment-topicmap-split-consequence-smoke-test)
  (run-dmx-workspace-annotation-no-change-consequence-smoke-test)
  (run-dmx-workspace-annotation-saved-topic-surface-smoke-test)
  (run-dmx-workspace-annotation-simple-success-readback-example-smoke-test)
  (run-dmx-workspace-annotation-auth-blocked-saved-topic-resolution-smoke-test)
  (run-dmx-workspace-annotation-preserved-topic-936040-continuation-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-failure-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-unassigned-companion-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-repair-failure-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-explicit-auth-continuation-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-explicit-auth-bootstrap-failure-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-explicit-auth-failure-evidence-smoke-test)
  (run-dmx-workspace-annotation-explicit-auth-continuation-smoke-test)
  (run-dmx-workspace-annotation-preflighted-persist-via-compatibility-carrier-smoke-test)
  (run-dmx-workspace-annotation-preflighted-persist-blocked-smoke-test)
  (run-dmx-workspace-annotation-local-first-save-smoke-test)
  (run-dmx-workspace-annotation-local-first-materialize-compatibility-smoke-test)
  (run-dmx-workspace-annotation-local-first-pending-auth-continuation-smoke-test)
  (run-dmx-workspace-annotation-workspace-view-scxml-contract-smoke-test)
  (run-dmx-workspace-annotation-workspace-view-local-first-ux-smoke-test)
  (format t "~&DMX workspace annotation smoke tests passed.~%")
  t)
