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

(defmethod hyperdoc::dmx-import-add-topic-to-topicmap
    ((client failing-topicmap-placement-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (declare (ignore client topicmap-id topic-id view-props))
  (error "Simulated topicmap placement failure"))

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

(defun run-dmx-annotations-smoke-tests ()
  (run-dmx-workspace-annotation-plan-smoke-test)
  (run-dmx-workspace-annotation-dry-run-smoke-test)
  (run-dmx-workspace-annotation-live-create-and-reopen-smoke-test)
  (run-dmx-workspace-annotation-supersede-smoke-test)
  (run-dmx-workspace-annotation-restore-smoke-test)
  (run-dmx-workspace-annotation-debug-surface-smoke-test)
  (run-dmx-workspace-annotation-debug-report-success-smoke-test)
  (run-dmx-workspace-annotation-debug-report-failure-smoke-test)
  (format t "~&DMX workspace annotation smoke tests passed.~%")
  t)
