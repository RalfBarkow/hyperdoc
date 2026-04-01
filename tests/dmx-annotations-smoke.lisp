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

(defmethod hyperdoc::dmx-import-add-topic-to-topicmap
    ((client failing-topicmap-placement-dmx-import-client)
     topicmap-id
     topic-id
     view-props)
  (declare (ignore client topicmap-id topic-id view-props))
  (error "Simulated topicmap placement failure"))

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
     (search "Probe live annotation type support" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the live annotation type support probe")
    (assert-true
     (search "Probe live create-topic" workspace-html :test #'char-equal)
     "Workspace annotation inspector must expose the Probe live create-topic action")
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

(defun run-dmx-workspace-annotation-backend-compatibility-probe-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                :base-url "https://dmx.ralfbarkow.ch"
                                :authorization-header "Bearer test-token"
                                :workspace-id *dmx-annotations-smoke-workspace-id*))
         (annotation (make-test-dock-annotation
                      :note "Backend compatibility probe"))
         (original (symbol-function 'drakma:http-request)))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key &allow-other-keys)
                   (if (search "/core/topic/uri/" url)
                       (values (make-string-input-stream "")
                               404
                               '(("Content-Type" . "application/json"))
                               nil nil "Not Found")
                       (error "Unexpected backend compatibility HTTP call ~S"
                              url))))
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
             (assert-equal :unsupported
                           (hyperdoc::workspace-annotation-backend-compatibility-report-status-of
                            report)
                           "Missing live annotation types must classify as unsupported")
             (assert-equal hyperdoc::*dmx-workspace-annotation-type-uri*
                           (hyperdoc::workspace-annotation-backend-compatibility-report-failing-type-uri-of
                            report)
                           "The parent hyperdoc.annotation type must be reported as the failing URI")
             (assert-equal "/core/topic"
                           (hyperdoc::workspace-annotation-backend-compatibility-report-endpoint-path-of
                            report)
                           "Compatibility report must preserve the create-topic endpoint that would have been used")
             (assert-equal "/core/topic/uri/hyperdoc.annotation?children=true&assocChildren=true"
                           (getf evidence :path)
                           "Compatibility report must preserve the parent type probe path")
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
              "Compatibility report must preserve the known live backend cause when available")
             (assert-true
             (find-if (lambda (action)
                         (search "Register hyperdoc.annotation"
                                 action
                                 :test #'char-equal))
                       (hyperdoc::workspace-annotation-backend-compatibility-report-next-actions-of
                        report))
              "Compatibility report must guide the operator toward backend type registration")))
      (setf (symbol-function 'drakma:http-request) original))))

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
                           :client client))
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
                           "Unsupported live backends must block the normal persist path")
             (assert-equal 0
                           post-count
                           "Unsupported live backends must be blocked before POST /core/topic is attempted")))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-dmx-annotations-smoke-tests ()
  (run-dmx-workspace-annotation-plan-smoke-test)
  (run-dmx-workspace-annotation-dry-run-smoke-test)
  (run-dmx-workspace-annotation-live-create-and-reopen-smoke-test)
  (run-dmx-workspace-annotation-supersede-smoke-test)
  (run-dmx-workspace-annotation-restore-smoke-test)
  (run-dmx-workspace-annotation-debug-surface-smoke-test)
  (run-dmx-workspace-annotation-debug-report-success-smoke-test)
  (run-dmx-workspace-annotation-debug-report-failure-smoke-test)
  (run-dmx-workspace-annotation-unicode-transport-diagnostics-smoke-test)
  (run-dmx-workspace-annotation-backend-compatibility-probe-smoke-test)
  (run-dmx-http-unicode-json-request-smoke-test)
  (run-dmx-workspace-annotation-live-create-topic-failure-evidence-smoke-test)
  (run-dmx-workspace-annotation-create-topic-probe-render-smoke-test)
  (run-dmx-workspace-annotation-preflighted-persist-blocked-smoke-test)
  (format t "~&DMX workspace annotation smoke tests passed.~%")
  t)
