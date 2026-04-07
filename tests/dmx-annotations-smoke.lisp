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
         (initial-journal (hyperdoc::read-dmx-topic-journal
                           :workspace-topicmap-id
                           *dmx-annotations-smoke-workspace-topicmap-id*
                           :client client
                           :topic-id topic-id
                           :reconcile nil))
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
         (stepper
           (clog-moldable-inspector::make-playground-stepper
            annotation
            (hyperdoc::workspace-annotation-persistence-debug-stepper-source-of
             debug)))
         (graph (hyperdoc::workspace-annotation-persistence-debug-graph debug)))
    (assert-true
     (typep debug 'hyperdoc::workspace-annotation-persistence-debug)
     "Debug workspace persistence must return an inspectable debug object")
    (assert-true
     (search "Debug workspace persistence" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the Debug workspace persistence action")
    (assert-true
     (search "Trace workspace persistence path" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the Trace workspace persistence path action")
    (assert-true
     (search "Compare with guarded workspace path" workspace-html
             :test #'char-equal)
     "Workspace annotation inspector must expose the Compare with guarded workspace path action")
    (assert-true
     (search "Probe live annotation type support" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the live annotation type support probe")
    (assert-true
     (search "Probe live create-topic" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the Probe live create-topic action")
    (assert-true
     (search "Destination source" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the resolved save destination explicitly")
    (assert-true
     (search "context-window default fallback" workspace-html :test #'char-equal)
     "Workspace annotation inspector must label the context-window destination as a fallback, not as the only save story")
    (assert-true
     (getf (hyperdoc::workspace-annotation-persistence-debug-dry-run-preview-of
            debug)
           :dry-run)
     "Debug workspace persistence must preload the dry-run preview")
    (assert-true
     (search "persist-dock-annotation-to-workspace"
             (hyperdoc::workspace-annotation-persistence-debug-exact-form-of
              debug)
             :test #'char-equal)
     "Debug workspace persistence must expose the exact persist form")
    (assert-true
     (search "plan-dmx-workspace-annotation-write-from-object"
             (hyperdoc::workspace-annotation-persistence-debug-stepper-source-of
              debug))
     "Debug workspace persistence stepper source must stage the plan form first")
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
                  :client client)))
    (assert-true
     (typep report 'hyperdoc::workspace-annotation-persistence-report)
     "Live workspace persistence debug must return an inspectable report")
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
           (evidence
             (hyperdoc::workspace-annotation-backend-compatibility-report-http-evidence-of
              report)))
      (assert-true
       (typep report 'hyperdoc::workspace-annotation-backend-compatibility-report)
       "Backend compatibility probe must return an inspectable report")
      (assert-equal :compatible-via-carrier
                    (hyperdoc::workspace-annotation-backend-compatibility-report-status-of
                     report)
                    "When raw hyperdoc.annotation is unsupported but dmx.notes.note is available, the live path must classify as compatibility-carrier supported")
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
       "Compatibility report must state that the normal live path will use compatibility storage"))))

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
                  (probe-evidence
                    (hyperdoc::workspace-annotation-create-topic-probe-http-evidence-of
                     probe))
                  (report (hyperdoc::run-dock-annotation-workspace-persistence-debug
                           annotation
                           :workspace-topicmap-id
                           *dmx-annotations-smoke-workspace-topicmap-id*
                           :client client
                           :storage-mode
                           hyperdoc::*dmx-workspace-annotation-native-storage-mode*))
                  (report-evidence
                    (hyperdoc::workspace-annotation-persistence-report-topic-upsert-evidence-of
                     report)))
             (assert-true
              (typep probe 'hyperdoc::workspace-annotation-create-topic-probe-report)
              "Create-topic probe must return an inspectable probe report")
             (assert-equal :failed
                           (hyperdoc::workspace-annotation-create-topic-probe-status-of
                            probe)
                           "Create-topic probe must classify a 500 as failed")
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
             (assert-equal :failed
                           (hyperdoc::workspace-annotation-persistence-report-status-of
                            report)
                           "Full persistence debug must still fail when create-topic fails")
             (assert-equal :topic-upsert
                           (hyperdoc::workspace-annotation-persistence-report-failure-stage-of
                            report)
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
                 (views (dmx-annotation-smoke-load-inspector-views-for-object
                         report))
                 (overview (dmx-annotation-smoke-find-view-by-title views
                                                                    "Overview"))
                 (html (and overview
                            (html-inspector-views:view-html overview))))
            (assert-true
             (typep report 'hyperdoc::workspace-annotation-persistence-report)
             "Prepare-transition failures must still return an inspectable persistence report")
            (assert-equal :failed
                          (hyperdoc::workspace-annotation-persistence-report-status-of
                           report)
                          "Prepare-transition failures must classify the persistence report as failed")
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
             (hyperdoc::workspace-annotation-persistence-report-journal-topic-id-of
              report)
             "Prepare-transition failure reports must expose the journal companion topic id when known")
            (assert-equal journal-topic-id
                          (hyperdoc::workspace-annotation-persistence-report-journal-topic-id-of
                           report)
                          "Prepare-transition failure reports must preserve the actual journal companion topic id")
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
         (journal-summary-before
           (workspace-annotation-smoke-journal-summary create-client persisted))
         (journal-topic-id (getf journal-summary-before :existing-topic-id))
         (blocked-client
           (make-instance
            'journal-preflight-auth-blocked-compatibility-storage-http-dmx-import-client
            :base-url "https://dmx.ralfbarkow.ch"
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :topics-by-external-key topics
            :topicmap-memberships topicmap-memberships
            :workspace-assignments workspace-assignments
            :next-topic-id 9461))
         (auth-client
           (make-instance
            'journal-preflight-auth-blocked-compatibility-storage-http-dmx-import-client
            :base-url "https://dmx.ralfbarkow.ch"
            :authorization-header "Bearer explicit-test-token"
            :workspace-id *dmx-annotations-smoke-workspace-id*
            :journal-preflight-auth-available-p t
            :topics-by-external-key topics
            :topicmap-memberships topicmap-memberships
            :workspace-assignments workspace-assignments
            :next-topic-id 9462))
         (original
           (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)))
    (unwind-protect
        (progn
          (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
                (lambda (client subject-key lookup-kind lookup-value
                         workspace-topicmap-id
                         &rest args
                         &key subject-uri subject-kind ownership-class
                           note-key note-kind
                         &allow-other-keys)
                  (declare (ignore subject-uri subject-kind ownership-class
                                   note-key note-kind))
                  (if (and (typep client
                                  'journal-preflight-auth-blocked-compatibility-storage-http-dmx-import-client)
                           (not (journal-preflight-auth-available-p-of client)))
                      (signal-journal-preflight-http-401 journal-topic-id)
                      (apply original
                             client
                             subject-key
                             lookup-kind
                             lookup-value
                             workspace-topicmap-id
                             args))))
          (let* ((blocked
                   (hyperdoc::run-dock-annotation-workspace-persistence-debug
                    persisted
                    :workspace-topicmap-id
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    :client blocked-client))
                 (continued
                   (hyperdoc::continue-workspace-annotation-journal-preflight-with-explicit-auth
                    blocked
                    :client auth-client))
                 (prepare-transition
                   (hyperdoc::workspace-annotation-persistence-stage-result
                    continued
                    :prepare-transition))
                 (topic-upsert
                   (hyperdoc::workspace-annotation-persistence-stage-result
                    continued
                    :topic-upsert))
                 (reopened
                   (hyperdoc::workspace-annotation-persistence-report-persisted-annotation-of
                    continued)))
            (assert-true
             (hyperdoc::workspace-annotation-journal-preflight-auth-blocked-p
              blocked)
             "The continuation smoke must start from a journal-preflight auth-blocked report")
            (assert-equal :persisted
                          (hyperdoc::workspace-annotation-persistence-report-status-of
                           continued)
                          "Explicit-auth journal continuation must rerun the staged persist successfully")
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
            (assert-true
             (typep reopened 'hyperdoc::workspace-dock-annotation)
             "Successful journal continuation must reopen a workspace annotation object")
            (assert-equal saved-topic-id
                          (hyperdoc::workspace-annotation-topic-id-of reopened)
                          "Successful journal continuation must keep updating the existing saved carrier topic instead of creating a new one")))
      (setf (symbol-function 'hyperdoc::dmx-workspace-journal-prepare-transition)
            original))))

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

(defun run-dmx-annotations-smoke-tests ()
  (run-dmx-workspace-annotation-plan-smoke-test)
  (run-dmx-workspace-annotation-compatibility-plan-smoke-test)
  (run-dmx-workspace-annotation-dry-run-smoke-test)
  (run-dmx-workspace-annotation-live-create-and-reopen-smoke-test)
  (run-dmx-workspace-annotation-compatibility-live-create-and-reopen-smoke-test)
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
  (run-dmx-workspace-annotation-no-client-pending-auth-smoke-test)
  (run-dmx-workspace-annotation-pending-auth-smoke-test)
  (run-dmx-workspace-annotation-pending-auth-render-smoke-test)
  (run-dmx-workspace-annotation-pending-auth-compare-smoke-test)
  (run-dmx-workspace-annotation-assignment-topicmap-split-consequence-smoke-test)
  (run-dmx-workspace-annotation-no-change-consequence-smoke-test)
  (run-dmx-workspace-annotation-saved-topic-surface-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-failure-smoke-test)
  (run-dmx-workspace-annotation-journal-preflight-explicit-auth-continuation-smoke-test)
  (run-dmx-workspace-annotation-explicit-auth-continuation-smoke-test)
  (run-dmx-workspace-annotation-preflighted-persist-via-compatibility-carrier-smoke-test)
  (run-dmx-workspace-annotation-preflighted-persist-blocked-smoke-test)
  (format t "~&DMX workspace annotation smoke tests passed.~%")
  t)
