;;;; Smoke tests for DMX topic proxy wrapper mapping

(in-package :hyperdoc/tests)

(defparameter *dmx-wrapper-smoke-specs*
  '((hyperdoc::concept-operational-definition 912384 912102)
    (hyperdoc::dmx-topic-912138 912138 912102)
    (hyperdoc::prepare-aarch64-image-topic 912384 912102)
    (hyperdoc::dmx-topic-912384 912384 912102)))

(defun expected-dmx-webclient-url (topicmap-id topic-id)
  (format nil "https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/~D/topic/~D"
          topicmap-id
          topic-id))

(defun expected-dmx-core-topic-url (id)
  (format nil "https://dmx.ralfbarkow.ch/core/topic/~D?children=true&assocChildren=true"
          id))

(defun expected-dmx-workspace-object-url (id)
  (format nil "https://dmx.ralfbarkow.ch/workspaces/object/~D" id))

(defun expected-dmx-topicmap-memberships-url (id)
  (format nil "https://dmx.ralfbarkow.ch/topicmaps/object/~D" id))

(defun expected-dmx-topicmap-projection-url (id)
  (format nil "https://dmx.ralfbarkow.ch/topicmaps/~D?children=true" id))

(defun expected-dmx-workspace-owner-url (workspace-id)
  (format nil "https://dmx.ralfbarkow.ch/access-control/workspace/~D/owner"
          workspace-id))

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun assert-type (expected-type object message)
  (unless (eq expected-type (type-of object))
    (error "~A -- expected type: ~S actual type: ~S" message expected-type (type-of object))))

(defun dmx-topic-proxy-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun dmx-topic-proxy-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun dmx-topic-proxy-smoke-rendered-html (value)
  (or (ignore-errors
        (html-inspector-views:view-html value))
      value))

(defun run-one-wrapper-smoke-test (spec)
  (destructuring-bind (wrapper topic-id topicmap-id) spec
    (let ((proxy (funcall (symbol-function wrapper))))
      (assert-type 'hyperdoc::dmx-topic-proxy
                   proxy
                   (format nil "Wrapper ~S must return DMX proxy" wrapper))
      (assert-equal topic-id
                    (hyperdoc::dmx-topic-id-of proxy)
                    (format nil "Wrapper ~S topic-id" wrapper))
      (assert-equal topicmap-id
                    (hyperdoc::dmx-topicmap-id-of proxy)
                    (format nil "Wrapper ~S topicmap-id" wrapper))
      (assert-equal (expected-dmx-webclient-url topicmap-id topic-id)
                    (hyperdoc::dmx-webclient-url proxy)
                    (format nil "Wrapper ~S URL" wrapper)))))

(defun make-smoke-json (label)
  (let ((table (make-hash-table :test #'equal)))
    (setf (gethash "value" table) label)
    table))

(defun make-smoke-topicmap-projection (topics)
  (let ((projection (make-hash-table :test #'equal))
        (topicmap (make-hash-table :test #'equal)))
    (setf (gethash "id" topicmap) 919822
          (gethash "typeUri" topicmap) "dmx.topicmaps.topicmap"
          (gethash "value" topicmap) "context-window"
          (gethash "children" topicmap) (make-hash-table :test #'equal)
          (gethash "topic" projection) topicmap
          (gethash "viewProps" projection) (make-hash-table :test #'equal)
          (gethash "topics" projection) (coerce topics 'vector)
          (gethash "assocs" projection) #())
    projection))

(defun make-smoke-topicmap-projection-topic (id value)
  (let ((topic (make-hash-table :test #'equal)))
    (setf (gethash "id" topic) id
          (gethash "typeUri" topic) "dmx.notes.note"
          (gethash "value" topic) value
          (gethash "viewProps" topic) (make-hash-table :test #'equal))
    topic))

(defun make-smoke-diagnostics-proxy
    (topic-id title &key workspace-id
                      (ownership-class :hyperdoc-workspace-note)
                      (hyperdoc-owned-p t)
                      (status :ok)
                      (repair-needed-p nil))
  (let ((proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy topic-id)))
    (setf (hyperdoc::dmx-diagnostics-of proxy)
          (hyperdoc::make-dmx-topic-diagnostics
           :topic-id topic-id
           :topicmap-id 919822
           :topic-title title
           :workspace-id workspace-id
           :workspace-title (and workspace-id "context-window")
           :selected-topicmap-membership-p t
           :ownership-class ownership-class
           :ownership-reason "smoke"
           :hyperdoc-owned-p hyperdoc-owned-p
           :status status
           :status-reason "smoke"
           :repair-needed-p repair-needed-p))
    proxy))

(defun run-topicmap-endpoint-regression-test ()
  (let* ((proxy (hyperdoc::make-dmx-topic-proxy :topic-id 912384
                                                :topicmap-id 912102))
         (book (hyperbook:hyperbook-of proxy))
         (calls nil)
         (topic-json (make-smoke-json "topic"))
         (topicmap-json (make-smoke-json "topicmap"))
         (original (symbol-function 'hyperdoc::dmx-fetch-json)))
    (clrhash (hyperdoc::dmx-cache-of book))
    (setf (hyperdoc::dmx-cache-order-of book) nil
          (hyperdoc::dmx-topic-data-of proxy) nil
          (hyperdoc::dmx-topicmap-data-of proxy) nil
          (hyperdoc::dmx-load-error-of proxy) nil)
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::dmx-fetch-json)
                 (lambda (book endpoint &key parameters)
                   (declare (ignore book))
                   (push (list endpoint parameters) calls)
                   (cond
                     ((and (string= endpoint "/core/topic/912384")
                           (equal parameters
                                  (hyperdoc::dmx-children+assoc-parameters)))
                      topic-json)
                     ((and (string= endpoint "/core/topic/912102")
                           (equal parameters
                                  (hyperdoc::dmx-children+assoc-parameters)))
                      topicmap-json)
                     (t
                      (error "Unexpected DMX fetch call ~S ~S"
                             endpoint
                             parameters)))))
           (hyperdoc::ensure-dmx-topic-data proxy :force? t)
           (hyperdoc::ensure-dmx-topicmap-data proxy :force? t)
           (assert-equal topic-json
                         (hyperdoc::dmx-topic-data-of proxy)
                         "Topic data should come from /core/topic/<topic-id>")
           (assert-equal topicmap-json
                         (hyperdoc::dmx-topicmap-data-of proxy)
                         "Topicmap data should come from /core/topic/<topicmap-id>")
           (assert-equal (expected-dmx-core-topic-url 912102)
                         (hyperdoc::dmx-topicmap-core-topic-url proxy)
                         "Topicmap helper must expose the exact core-topic URL")
           (assert-true
            (member (list "/core/topic/912102"
                          (hyperdoc::dmx-children+assoc-parameters))
                    calls
                    :test #'equal)
            "Topicmap data fetch must use the core topic endpoint")
           (assert-true
            (notany (lambda (call)
                      (search "/topicmaps/" (first call)))
                    calls)
            "No /topicmaps/<id> fetch should remain in the exercised topicmap path"))
      (setf (symbol-function 'hyperdoc::dmx-fetch-json) original))))

(defun run-workspace-diagnostics-regression-test ()
  (let* ((missing-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922464))
         (annotation-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 928648))
         (journal-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 928674))
         (fixed-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922586))
         (foreign-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922451))
         (book (hyperbook:hyperbook-of missing-proxy))
         (calls nil)
         (topicmap-json (make-smoke-json "context-window"))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (labels ((make-membership (topicmap-id assoc-id &optional (value "context-window"))
               (let ((membership (make-hash-table :test #'equal))
                     (assoc (make-hash-table :test #'equal)))
                 (setf (gethash "id" membership) topicmap-id
                       (gethash "value" membership) value
                       (gethash "assoc" membership) assoc
                       (gethash "id" assoc) assoc-id)
                 membership))
             (make-topic-json (id uri type-uri value)
               (let ((json (make-hash-table :test #'equal))
                     (children (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) id
                       (gethash "uri" json) uri
                       (gethash "typeUri" json) type-uri
                       (gethash "value" json) value
                       (gethash "children" json) children)
                 json))
             (make-workspace-json (id value)
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) id
                       (gethash "typeUri" json) "dmx.workspaces.workspace"
                       (gethash "value" json) value
                       (gethash "children" json) (make-hash-table :test #'equal))
                 json)))
      (clrhash (hyperdoc::dmx-cache-of book))
      (setf (hyperdoc::dmx-cache-order-of book) nil)
      (dolist (proxy (list missing-proxy
                           annotation-proxy
                           journal-proxy
                           fixed-proxy
                           foreign-proxy))
        (setf (hyperdoc::dmx-topic-data-of proxy) nil
              (hyperdoc::dmx-workspace-data-of proxy) nil
              (hyperdoc::dmx-workspace-owner-of proxy) nil
              (hyperdoc::dmx-topicmap-memberships-of proxy) nil
              (hyperdoc::dmx-diagnostics-of proxy) nil
              (hyperdoc::dmx-topicmap-data-of proxy) nil
              (hyperdoc::dmx-related-topics-of proxy) nil
              (hyperdoc::dmx-load-error-of proxy) nil))
      (unwind-protect
           (progn
             (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                   (lambda (book endpoint &key parameters accept)
                     (declare (ignore book parameters accept))
                     (push endpoint calls)
                     (cond
                       ((string= endpoint "/core/topic/922464")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           922464
                           "hyperdoc:mcp/workspace-note/operational-definition-chunk-chunk-note-manifest-note-content-topic"
                           "dmx.notes.note"
                           "Operational definition: chunk, chunk note, manifest note, content topic"))
                         200
                         (expected-dmx-core-topic-url 922464)
                         "OK"))
                       ((string= endpoint "/core/topic/922586")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           922586
                           "hyperdoc:mcp/workspace-note/topic-922586"
                           "dmx.notes.note"
                           "Guarded workspace default verification note"))
                         200
                         (expected-dmx-core-topic-url 922586)
                         "OK"))
                       ((string= endpoint "/core/topic/928648")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           928648
                           "hyperdoc:mcp/workspace-annotation/test-workspace-annotation"
                           "dmx.notes.note"
                           "Workspace annotation compatibility carrier"))
                         200
                         (expected-dmx-core-topic-url 928648)
                         "OK"))
                       ((string= endpoint "/core/topic/928674")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           928674
                           "hyperdoc:mcp/workspace-journal/test-workspace-journal"
                           "dmx.notes.note"
                           "Workspace journal companion"))
                         200
                         (expected-dmx-core-topic-url 928674)
                         "OK"))
                       ((string= endpoint "/core/topic/922451")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           922451
                           "hyperdoc:mcp/auth-probe-20260330-1"
                           "dmx.notes.note"
                           "auth probe"))
                         200
                         (expected-dmx-core-topic-url 922451)
                         "OK"))
                       ((string= endpoint "/core/topic/919822")
                        (values
                         (hyperdoc::encode-json-string topicmap-json)
                         200
                         (expected-dmx-core-topic-url 919822)
                         "OK"))
                       ((member endpoint '("/workspaces/object/922464"
                                           "/workspaces/object/928648"
                                           "/workspaces/object/928674")
                                :test #'string=)
                        (values
                         ""
                         204
                         (expected-dmx-workspace-object-url
                          (parse-integer
                           (subseq endpoint
                                   (length "/workspaces/object/"))))
                         "No Content"))
                       ((string= endpoint "/workspaces/object/922586")
                        (values
                         (hyperdoc::encode-json-string
                          (make-workspace-json 919815 "context-window"))
                         200
                         (expected-dmx-workspace-object-url 922586)
                         "OK"))
                       ((string= endpoint "/workspaces/object/922451")
                        (values "" 204 (expected-dmx-workspace-object-url 922451) "No Content"))
                       ((string= endpoint "/access-control/workspace/919815/owner")
                        (values "rgb" 200 (expected-dmx-workspace-owner-url 919815) "OK"))
                       ((member endpoint '("/topicmaps/object/922464"
                                           "/topicmaps/object/928648"
                                           "/topicmaps/object/928674")
                                :test #'string=)
                        (values
                         (hyperdoc::encode-json-string
                          (vector (make-membership
                                   919822
                                   (+ 7
                                      (parse-integer
                                       (subseq endpoint
                                               (length "/topicmaps/object/")))))))
                         200
                         (expected-dmx-topicmap-memberships-url
                          (parse-integer
                           (subseq endpoint
                                   (length "/topicmaps/object/"))))
                         "OK"))
                       ((string= endpoint "/topicmaps/object/922586")
                        (values
                         (hyperdoc::encode-json-string
                          (vector (make-membership 919822 922599)))
                         200
                         (expected-dmx-topicmap-memberships-url 922586)
                         "OK"))
                       ((string= endpoint "/topicmaps/object/922451")
                        (values
                         (hyperdoc::encode-json-string
                          (vector (make-membership 919822 922524)))
                         200
                         (expected-dmx-topicmap-memberships-url 922451)
                         "OK"))
                       (t
                        (error "Unexpected DMX diagnostics fetch ~S" endpoint)))))
             (hyperdoc::ensure-dmx-topic-diagnostics missing-proxy :force? t)
             (hyperdoc::ensure-dmx-topic-diagnostics annotation-proxy :force? t)
             (hyperdoc::ensure-dmx-topic-diagnostics journal-proxy :force? t)
             (hyperdoc::ensure-dmx-topic-diagnostics fixed-proxy :force? t)
             (hyperdoc::ensure-dmx-topic-diagnostics foreign-proxy :force? t)
             (let ((missing (hyperdoc::dmx-diagnostics-of missing-proxy))
                   (annotation (hyperdoc::dmx-diagnostics-of annotation-proxy))
                   (journal (hyperdoc::dmx-diagnostics-of journal-proxy))
                   (fixed (hyperdoc::dmx-diagnostics-of fixed-proxy))
                   (foreign (hyperdoc::dmx-diagnostics-of foreign-proxy)))
               (assert-equal :in-topicmap-but-unassigned
                             (hyperdoc::dmx-topic-diagnostics-status missing)
                             "Missing-assignment topic must surface in-topicmap-but-unassigned")
               (assert-true
                (hyperdoc::dmx-topic-diagnostics-repair-needed-p missing)
                "Missing-assignment topic must flag repair-needed")
               (assert-equal 919822
                             (hyperdoc::dmx-topic-diagnostics-topicmap-id missing)
                             "Missing-assignment topic must keep the selected topicmap id")
               (assert-equal "operational-definition-chunk-chunk-note-manifest-note-content-topic"
                             (hyperdoc::dmx-topic-diagnostics-note-key missing)
                             "Workspace-note URI must expose the note key")
               (assert-equal :hyperdoc-workspace-annotation
                             (hyperdoc::dmx-topic-diagnostics-ownership-class
                              annotation)
                             "Workspace annotation topic must no longer false-negative as foreign")
               (assert-true
                (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p annotation)
                "Workspace annotation topic must remain HyperDoc-owned")
               (assert-equal :in-topicmap-but-unassigned
                             (hyperdoc::dmx-topic-diagnostics-status annotation)
                             "Workspace annotation topic must surface in-topicmap-but-unassigned")
               (assert-equal :hyperdoc-workspace-journal
                             (hyperdoc::dmx-topic-diagnostics-ownership-class
                              journal)
                             "Workspace journal topic must no longer false-negative as foreign")
               (assert-true
                (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p journal)
                "Workspace journal topic must remain HyperDoc-owned")
               (assert-equal :in-topicmap-but-unassigned
                             (hyperdoc::dmx-topic-diagnostics-status journal)
                             "Workspace journal topic must surface in-topicmap-but-unassigned")
               (assert-equal :ok
                             (hyperdoc::dmx-topic-diagnostics-status fixed)
                             "Assigned topic must surface OK")
               (assert-equal 919815
                             (hyperdoc::dmx-topic-diagnostics-workspace-id fixed)
                             "Assigned topic must carry workspace 919815")
               (assert-equal "rgb"
                             (hyperdoc::dmx-topic-diagnostics-workspace-owner fixed)
                             "Assigned topic must carry workspace owner rgb")
               (assert-equal :foreign-object
                             (hyperdoc::dmx-topic-diagnostics-status foreign)
                             "Foreign probe topic must surface foreign-object")
               (assert-true
                (not (hyperdoc::dmx-topic-diagnostics-repair-needed-p foreign))
                "Foreign topic must not be marked repair-needed"))
             (assert-true
              (member "/workspaces/object/922464" calls :test #'equal)
              "Diagnostics must read the workspace-assignment endpoint")
             (assert-true
              (member "/workspaces/object/928648" calls :test #'equal)
              "Diagnostics must read the workspace endpoint for workspace annotations")
             (assert-true
              (member "/workspaces/object/928674" calls :test #'equal)
              "Diagnostics must read the workspace endpoint for workspace journals")
             (assert-true
              (member "/topicmaps/object/922464" calls :test #'equal)
              "Diagnostics must read the topicmap-memberships endpoint")
             (assert-true
              (member "/topicmaps/object/928648" calls :test #'equal)
              "Diagnostics must read the topicmap-memberships endpoint for workspace annotations")
             (assert-true
              (member "/topicmaps/object/928674" calls :test #'equal)
              "Diagnostics must read the topicmap-memberships endpoint for workspace journals")
             (assert-true
              (member "/access-control/workspace/919815/owner" calls :test #'equal)
              "Diagnostics must read the workspace-owner endpoint when a workspace exists"))
        (setf (symbol-function 'hyperdoc::dmx-http-request-body) original-http)))))

(defun run-workspace-repair-triage-regression-test ()
  (let* ((page (hyperdoc::make-dmx-shared-workspace-repair-triage))
         (book (hyperbook:hyperbook-of page))
         (calls nil)
         (topicmap-json (make-smoke-json "context-window"))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (labels ((make-membership (topicmap-id assoc-id &optional (value "context-window"))
               (let ((membership (make-hash-table :test #'equal))
                     (assoc (make-hash-table :test #'equal)))
                 (setf (gethash "id" membership) topicmap-id
                       (gethash "value" membership) value
                       (gethash "assoc" membership) assoc
                       (gethash "id" assoc) assoc-id)
                 membership))
             (make-topic-json (id uri value)
               (let ((json (make-hash-table :test #'equal))
                     (children (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) id
                       (gethash "uri" json) uri
                       (gethash "typeUri" json) "dmx.notes.note"
                       (gethash "value" json) value
                       (gethash "children" json) children)
                 json))
             (make-workspace-json (id value)
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) id
                       (gethash "typeUri" json) "dmx.workspaces.workspace"
                       (gethash "value" json) value
                       (gethash "children" json) (make-hash-table :test #'equal))
                 json))
             (make-topicmap-projection (topics)
               (let ((projection (make-hash-table :test #'equal))
                     (topic (make-hash-table :test #'equal)))
                 (setf (gethash "id" topic) 919822
                       (gethash "typeUri" topic) "dmx.topicmaps.topicmap"
                       (gethash "value" topic) "context-window"
                       (gethash "children" topic) (make-hash-table :test #'equal)
                       (gethash "topic" projection) topic
                       (gethash "viewProps" projection) (make-hash-table :test #'equal)
                       (gethash "topics" projection) (coerce topics 'vector)
                       (gethash "assocs" projection) #())
                 projection)))
      (clrhash (hyperdoc::dmx-cache-of book))
      (setf (hyperdoc::dmx-cache-order-of book) nil
            (hyperdoc::dmx-topicmap-projection-of page) nil
            (hyperdoc::dmx-triage-topic-proxies-of page) nil
            (hyperdoc::dmx-repair-topic-proxies-of page) nil
            (hyperdoc::dmx-load-error-of page) nil)
      (unwind-protect
           (progn
             (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                   (lambda (book endpoint &key parameters accept)
                     (declare (ignore book parameters accept))
                     (push endpoint calls)
                     (cond
                       ((string= endpoint "/topicmaps/919822")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topicmap-projection
                           (list (make-topic-json
                                  922451
                                  "hyperdoc:mcp/auth-probe-20260330-1"
                                  "auth probe")
                                 (make-topic-json
                                  922464
                                  "hyperdoc:mcp/workspace-note/operational-definition-chunk-chunk-note-manifest-note-content-topic"
                                  "Operational definition: chunk, chunk note, manifest note, content topic")
                                 (make-topic-json
                                  922479
                                  "hyperdoc:mcp/workspace-note/terminology-boundary-chunk-versus-chunk-note"
                                  "Terminology boundary: Chunk versus chunk note")
                                 (make-topic-json
                                  922500
                                  "hyperdoc:mcp/handover/handover-codex-remediate-probe-topic-922451"
                                  "Remediate probe topic 922451 outside topicmap 919822")
                                 (make-topic-json
                                  922515
                                  "hyperdoc:mcp/workspace-note/chat-memory-2026-03-30"
                                  "chat memory")
                                 (make-topic-json
                                  922532
                                  "hyperdoc:mcp/workspace-note/maintenance-note-probe-topic-922451-disposition"
                                  "Maintenance note for probe topic 922451")
                                 (make-topic-json
                                  922565
                                  "hyperdoc:mcp/handover/set-default-workspace-and-owner"
                                  "Set default workspace and owner")
                                 (make-topic-json
                                  928648
                                  "hyperdoc:mcp/workspace-annotation/test-workspace-annotation"
                                  "Workspace annotation compatibility carrier")
                                 (make-topic-json
                                  928674
                                  "hyperdoc:mcp/workspace-journal/test-workspace-journal"
                                  "Workspace journal companion")
                                 (make-topic-json
                                  922586
                                  "hyperdoc:mcp/workspace-note/guarded-default-workspace-owner-verification-2026-03-30"
                                  "Guarded workspace default verification note"))))
                         200
                         (expected-dmx-topicmap-projection-url 919822)
                         "OK"))
                       ((string= endpoint "/core/topic/919822")
                        (values
                         (hyperdoc::encode-json-string topicmap-json)
                         200
                         (expected-dmx-core-topic-url 919822)
                         "OK"))
                       ((member endpoint '("/workspaces/object/922464"
                                           "/workspaces/object/922479"
                                           "/workspaces/object/922500"
                                           "/workspaces/object/922515"
                                           "/workspaces/object/922532"
                                           "/workspaces/object/922565"
                                           "/workspaces/object/928648"
                                           "/workspaces/object/928674"
                                           "/workspaces/object/922451")
                                :test #'string=)
                        (values "" 204
                                (expected-dmx-workspace-object-url
                                 (parse-integer (subseq endpoint
                                                        (length "/workspaces/object/"))))
                                "No Content"))
                       ((string= endpoint "/workspaces/object/922586")
                        (values
                         (hyperdoc::encode-json-string
                          (make-workspace-json 919815 "context-window"))
                         200
                         (expected-dmx-workspace-object-url 922586)
                         "OK"))
                       ((string= endpoint "/access-control/workspace/919815/owner")
                        (values "rgb" 200 (expected-dmx-workspace-owner-url 919815) "OK"))
                       ((member endpoint '("/topicmaps/object/922451"
                                           "/topicmaps/object/922464"
                                           "/topicmaps/object/922479"
                                           "/topicmaps/object/922500"
                                           "/topicmaps/object/922515"
                                           "/topicmaps/object/922532"
                                           "/topicmaps/object/922565"
                                           "/topicmaps/object/928648"
                                           "/topicmaps/object/928674"
                                           "/topicmaps/object/922586")
                                :test #'string=)
                        (let* ((id-string (subseq endpoint
                                                  (length "/topicmaps/object/")))
                               (id (parse-integer id-string)))
                          (values
                           (hyperdoc::encode-json-string
                            (vector (make-membership 919822 (+ 1000 id))))
                           200
                           (expected-dmx-topicmap-memberships-url id)
                           "OK")))
                       (t
                        (error "Unexpected DMX repair triage fetch ~S" endpoint)))))
             (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
             (let* ((repair-proxies (hyperdoc::dmx-repair-topic-proxies-of page))
                    (repair-ids (mapcar #'hyperdoc::dmx-topic-id-of repair-proxies)))
               (assert-equal '(922464 922479 922500 922515 922532 922565 928648 928674)
                             repair-ids
                             "Repair triage must list HyperDoc-owned missing-assignment topics across note, annotation, handover, and journal families")
               (assert-true
                (not (member 922586 repair-ids))
                "Assigned note 922586 must not appear in repair triage")
               (assert-true
                (not (member 922451 repair-ids))
                "Foreign topic 922451 must not appear in repair triage")
               (dolist (proxy repair-proxies)
                 (let ((diagnostics (hyperdoc::dmx-diagnostics-of proxy)))
                   (assert-equal :in-topicmap-but-unassigned
                                 (hyperdoc::dmx-topic-diagnostics-status
                                  diagnostics)
                                 "Repair triage rows must share the actionable defect status")
                   (assert-true
                    (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p
                     diagnostics)
                    "Repair triage rows must remain HyperDoc-owned")
                   (assert-equal nil
                                 (hyperdoc::dmx-topic-diagnostics-workspace-id
                                  diagnostics)
                                 "Repair triage rows must have no workspace assignment")))
               (let ((annotation-proxy (find 928648 repair-proxies
                                             :key #'hyperdoc::dmx-topic-id-of))
                     (journal-proxy (find 928674 repair-proxies
                                          :key #'hyperdoc::dmx-topic-id-of)))
                 (assert-equal :hyperdoc-workspace-annotation
                               (hyperdoc::dmx-topic-diagnostics-ownership-class
                                (hyperdoc::dmx-diagnostics-of annotation-proxy))
                               "Repair triage must recognize workspace annotations as HyperDoc-owned")
                 (assert-equal :hyperdoc-workspace-journal
                               (hyperdoc::dmx-topic-diagnostics-ownership-class
                                (hyperdoc::dmx-diagnostics-of journal-proxy))
                               "Repair triage must recognize workspace journals as HyperDoc-owned")))
             (assert-true
              (member "/topicmaps/919822" calls :test #'equal)
              "Repair triage must read the topicmap projection endpoint")
             (assert-true
              (member "/topicmaps/object/922464" calls :test #'equal)
              "Repair triage must still use the per-topic membership endpoint")
             (assert-true
              (member "/workspaces/object/922464" calls :test #'equal)
              "Repair triage must still use the per-topic workspace endpoint"))
        (setf (symbol-function 'hyperdoc::dmx-http-request-body) original-http)))))

(defun run-explicit-dmx-repair-client-builder-test ()
  (let ((basic-client
         (hyperdoc::make-http-dmx-import-client-from-explicit-auth
          :base-url "https://dmx.ralfbarkow.ch"
          :workspace-id 919815
          :auth-mode :basic
          :username "rgb"
          :password "secret"))
        (header-client
         (hyperdoc::make-http-dmx-import-client-from-explicit-auth
          :base-url "https://dmx.ralfbarkow.ch"
          :workspace-id 919815
          :auth-mode :header
          :authorization-header "Basic abc123"))
        (token-client
         (hyperdoc::make-http-dmx-import-client-from-explicit-auth
          :base-url "https://dmx.ralfbarkow.ch"
          :workspace-id 919815
          :auth-mode :token
          :auth-token "tok-123")))
    (assert-equal "https://dmx.ralfbarkow.ch"
                  (hyperdoc::dmx-import-base-url-of basic-client)
                  "Explicit auth builder must preserve the base URL")
    (assert-equal 919815
                  (hyperdoc::dmx-import-workspace-id-of basic-client)
                  "Explicit auth builder must preserve the workspace id")
    (assert-true
     (search "Basic " (hyperdoc::dmx-import-authorization-header-of basic-client))
     "Basic auth mode must synthesize a Basic authorization header")
    (assert-equal "Basic abc123"
                  (hyperdoc::dmx-import-authorization-header-of header-client)
                  "Header auth mode must preserve the explicit authorization header")
    (assert-equal "Bearer tok-123"
                  (hyperdoc::dmx-import-authorization-header-of token-client)
                  "Token auth mode must synthesize a Bearer authorization header")))

(defun run-repair-console-helper-regression-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client))
         (triage-page (hyperdoc::make-dmx-shared-workspace-repair-triage))
         (single-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922464))
         (book (hyperbook:hyperbook-of triage-page))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (labels ((make-view-props (x y)
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "dmx.topicmaps.x" json) x
                       (gethash "dmx.topicmaps.y" json) y
                       (gethash "dmx.topicmaps.visibility" json) t
                       (gethash "dmx.topicmaps.pinned" json) nil)
                 json))
             (seed-topic (id uri value)
               (hyperdoc::dmx-import-create-topic
                client
                (list :id id
                      :uri uri
                      :external-key uri
                      :type-uri "dmx.notes.note"
                      :value value
                      :children nil)))
             (topicmap-memberships-json (topic-id)
               (let ((memberships '()))
                 (maphash
                  (lambda (membership-key view-props)
                    (declare (ignore view-props))
                    (destructuring-bind (topicmap-id member-topic-id) membership-key
                      (when (eql member-topic-id topic-id)
                        (let ((membership (make-hash-table :test #'equal))
                              (assoc (make-hash-table :test #'equal)))
                          (setf (gethash "id" membership) topicmap-id
                                (gethash "value" membership) "context-window"
                                (gethash "assoc" membership) assoc
                                (gethash "id" assoc) (+ 1000 topic-id))
                          (push membership memberships)))))
                  (hyperdoc::topicmap-memberships-of client))
                 (coerce (nreverse memberships) 'vector)))
             (topicmap-core-json ()
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) 919822
                       (gethash "uri" json) ""
                       (gethash "typeUri" json) "dmx.topicmaps.topicmap"
                       (gethash "value" json) "context-window"
                       (gethash "children" json) (make-hash-table :test #'equal))
                 json))
             (memory-body-for-topic (topic-id)
               (let ((topic (hyperdoc::dmx-import-read-topic client topic-id)))
                 (if topic
                     (values (hyperdoc::encode-json-string topic)
                             200
                             (expected-dmx-core-topic-url topic-id)
                             "OK")
                     (values "" 404 (expected-dmx-core-topic-url topic-id) "Not Found")))))
      (declare (ignore book))
      (seed-topic 922451
                  "hyperdoc:mcp/auth-probe-20260330-1"
                  "auth probe")
      (seed-topic 922464
                  "hyperdoc:mcp/workspace-note/operational-definition-chunk-chunk-note-manifest-note-content-topic"
                  "Operational definition: chunk, chunk note, manifest note, content topic")
      (seed-topic 922500
                  "hyperdoc:mcp/handover/handover-codex-remediate-probe-topic-922451"
                  "Remediate probe topic 922451 outside topicmap 919822")
      (seed-topic 922586
                  "hyperdoc:mcp/workspace-note/guarded-default-workspace-owner-verification-2026-03-30"
                  "Guarded workspace default verification note")
      (dolist (topic-id '(922451 922464 922500 922586))
        (hyperdoc::dmx-import-add-topic-to-topicmap
         client
         919822
         topic-id
         (make-view-props (+ 10 (mod topic-id 50))
                          (+ 20 (mod topic-id 40)))))
      (hyperdoc::dmx-import-assign-topic-to-workspace client 919815 922586)
      (clrhash (hyperdoc::dmx-cache-of (hyperbook:hyperbook-of single-proxy)))
      (clrhash (hyperdoc::dmx-cache-of (hyperbook:hyperbook-of triage-page)))
      (setf (hyperdoc::dmx-cache-order-of (hyperbook:hyperbook-of single-proxy)) nil
            (hyperdoc::dmx-cache-order-of (hyperbook:hyperbook-of triage-page)) nil)
      (unwind-protect
           (progn
             (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                   (lambda (book endpoint &key parameters accept)
                     (declare (ignore book parameters accept))
                     (cond
                       ((string= endpoint "/topicmaps/919822")
                        (values
                         (hyperdoc::encode-json-string
                          (hyperdoc::dmx-import-read-topicmap client 919822))
                         200
                         (expected-dmx-topicmap-projection-url 919822)
                         "OK"))
                       ((string= endpoint "/core/topic/919822")
                        (values
                         (hyperdoc::encode-json-string (topicmap-core-json))
                         200
                         (expected-dmx-core-topic-url 919822)
                         "OK"))
                       ((search "/core/topic/" endpoint)
                        (memory-body-for-topic
                         (parse-integer (subseq endpoint (length "/core/topic/")))))
                       ((search "/workspaces/object/" endpoint)
                        (let* ((topic-id (parse-integer
                                          (subseq endpoint
                                                  (length "/workspaces/object/"))))
                               (workspace (hyperdoc::dmx-import-read-topic-workspace
                                           client
                                           topic-id)))
                          (if workspace
                              (values (hyperdoc::encode-json-string workspace)
                                      200
                                      (expected-dmx-workspace-object-url topic-id)
                                      "OK")
                              (values ""
                                      204
                                      (expected-dmx-workspace-object-url topic-id)
                                      "No Content"))))
                       ((search "/topicmaps/object/" endpoint)
                        (let ((topic-id (parse-integer
                                         (subseq endpoint
                                                 (length "/topicmaps/object/")))))
                          (values
                           (hyperdoc::encode-json-string
                            (topicmap-memberships-json topic-id))
                           200
                           (expected-dmx-topicmap-memberships-url topic-id)
                           "OK")))
                       ((string= endpoint "/access-control/workspace/919815/owner")
                        (values "rgb" 200 (expected-dmx-workspace-owner-url 919815) "OK"))
                       (t
                        (error "Unexpected DMX repair-console fetch ~S" endpoint)))))
             (hyperdoc::ensure-dmx-workspace-repair-triage triage-page :force? t)
             (assert-equal '(922464 922500)
                           (mapcar #'hyperdoc::dmx-topic-id-of
                                   (hyperdoc::dmx-repair-topic-proxies-of triage-page))
                           "Repair console triage must begin with the two unassigned HyperDoc-owned topics")
             (let ((single-result
                    (hyperdoc/inspector::repair-topic-proxy-with-client
                     single-proxy
                     client
                     :dry-run nil
                     :auth-mode :header)))
               (assert-true (getf single-result :success-p)
                            "Single-topic repair helper must succeed on a HyperDoc-owned unassigned topic")
               (assert-equal 919815
                             (getf single-result :result-workspace-id)
                             "Single-topic repair helper must read back workspace 919815")
               (assert-true
                (getf single-result :result-in-topicmap-p)
                "Single-topic repair helper must keep topicmap placement intact")
               (assert-equal 919815
                             (hyperdoc::dmx-topic-diagnostics-workspace-id
                              (hyperdoc::dmx-diagnostics-of single-proxy))
                             "Single-topic proxy diagnostics must refresh to workspace 919815"))
             (hyperdoc::ensure-dmx-workspace-repair-triage triage-page :force? t)
             (assert-equal '(922500)
                           (mapcar #'hyperdoc::dmx-topic-id-of
                                   (hyperdoc::dmx-repair-topic-proxies-of triage-page))
                           "The repaired canary must disappear from backlog triage")
             (let ((backlog-results
                    (hyperdoc/inspector::repair-workspace-triage-backlog-with-client
                     triage-page
                     client
                     :dry-run nil
                     :auth-mode :header)))
               (assert-equal '(922500)
                             (mapcar (lambda (result) (getf result :topic-id))
                                     backlog-results)
                             "Backlog repair helper must repair only the remaining backlog topic")
               (assert-true
                (every (lambda (result)
                         (and (getf result :success-p)
                              (eql (getf result :result-workspace-id) 919815)
                              (getf result :result-in-topicmap-p)))
                       backlog-results)
                "Backlog repair helper must read back workspace 919815 while preserving topicmap placement"))
             (hyperdoc::ensure-dmx-workspace-repair-triage triage-page :force? t)
             (assert-equal nil
                           (mapcar #'hyperdoc::dmx-topic-id-of
                                   (hyperdoc::dmx-repair-topic-proxies-of triage-page))
                           "Repair triage must empty after backlog repair completes")
             (assert-equal 919815
                           (hyperdoc::dmx-import-object-id
                            (hyperdoc::dmx-import-read-topic-workspace client 922464))
                           "Canary topic must now be assigned in the memory client")
             (assert-equal 919815
                           (hyperdoc::dmx-import-object-id
                            (hyperdoc::dmx-import-read-topic-workspace client 922500))
                           "Backlog topic must now be assigned in the memory client")
             (assert-equal 919815
                           (hyperdoc::dmx-import-object-id
                            (hyperdoc::dmx-import-read-topic-workspace client 922586))
                           "Already-correct control must remain assigned")
             (assert-equal nil
                           (hyperdoc::dmx-import-read-topic-workspace client 922451)
                           "Foreign control must remain excluded from repair"))
        (setf (symbol-function 'hyperdoc::dmx-http-request-body) original-http)))))

(defun run-repair-console-localhost-rehearsal-bridge-smoke-test ()
  (let* ((remote-client (make-instance 'hyperdoc::memory-dmx-import-client))
         (triage-page (hyperdoc::make-dmx-shared-workspace-repair-triage))
         (book (hyperbook:hyperbook-of triage-page))
         (events nil)
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body))
         (original-explicit-client
          (symbol-function 'hyperdoc/inspector::make-explicit-dmx-repair-client))
         (original-rehearsal-builder
          (symbol-function
           'hyperdoc::make-memory-dmx-import-client-from-workspace-assignment-rehearsal-snapshot))
         (original-execute
          (symbol-function
           'hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair))
         (original-journal-suppressed-p
          hyperdoc::*dmx-workspace-journal-suppressed-p*))
    (labels ((make-view-props (x y)
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "dmx.topicmaps.x" json) x
                       (gethash "dmx.topicmaps.y" json) y
                       (gethash "dmx.topicmaps.visibility" json) t
                       (gethash "dmx.topicmaps.pinned" json) nil)
                 json))
             (seed-topic (id uri value)
               (hyperdoc::dmx-import-create-topic
                remote-client
                (list :id id
                      :uri uri
                      :external-key uri
                      :type-uri "dmx.notes.note"
                      :value value
                      :children nil)))
             (topicmap-memberships-json (topic-id)
               (let ((memberships '()))
                 (maphash
                  (lambda (membership-key view-props)
                    (declare (ignore view-props))
                    (destructuring-bind (topicmap-id member-topic-id) membership-key
                      (when (eql member-topic-id topic-id)
                        (let ((membership (make-hash-table :test #'equal))
                              (assoc (make-hash-table :test #'equal)))
                          (setf (gethash "id" membership) topicmap-id
                                (gethash "value" membership) "context-window"
                                (gethash "assoc" membership) assoc
                                (gethash "id" assoc) (+ 1000 topic-id))
                          (push membership memberships)))))
                  (hyperdoc::topicmap-memberships-of remote-client))
                 (coerce (nreverse memberships) 'vector)))
             (topicmap-core-json ()
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) 919822
                       (gethash "uri" json) ""
                       (gethash "typeUri" json) "dmx.topicmaps.topicmap"
                       (gethash "value" json) "context-window"
                       (gethash "children" json) (make-hash-table :test #'equal))
                 json))
             (memory-body-for-topic (topic-id)
               (let ((topic (hyperdoc::dmx-import-read-topic remote-client topic-id)))
                 (if topic
                     (values (hyperdoc::encode-json-string topic)
                             200
                             (expected-dmx-core-topic-url topic-id)
                             "OK")
                     (values "" 404 (expected-dmx-core-topic-url topic-id) "Not Found")))))
      (declare (ignore book))
      (seed-topic 922451
                  "hyperdoc:mcp/auth-probe-20260330-1"
                  "auth probe")
      (seed-topic 922500
                  "hyperdoc:mcp/handover/handover-codex-remediate-probe-topic-922451"
                  "Remediate probe topic 922451 outside topicmap 919822")
      (seed-topic 922586
                  "hyperdoc:mcp/workspace-note/guarded-default-workspace-owner-verification-2026-03-30"
                  "Guarded workspace default verification note")
      (dolist (topic-id '(922451 922500 922586))
        (hyperdoc::dmx-import-add-topic-to-topicmap
         remote-client
         919822
         topic-id
         (make-view-props (+ 10 (mod topic-id 50))
                          (+ 20 (mod topic-id 40)))))
      (hyperdoc::dmx-import-assign-topic-to-workspace remote-client 919815 922586)
      (clrhash (hyperdoc::dmx-cache-of (hyperbook:hyperbook-of triage-page)))
      (setf (hyperdoc::dmx-cache-order-of (hyperbook:hyperbook-of triage-page)) nil
            (hyperdoc::dmx-topicmap-projection-of triage-page) nil
            (hyperdoc::dmx-triage-topic-proxies-of triage-page) nil
            (hyperdoc::dmx-repair-topic-proxies-of triage-page) nil
            (hyperdoc::dmx-load-error-of triage-page) nil)
      (unwind-protect
           (progn
             (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                   (lambda (book endpoint &key parameters accept)
                     (declare (ignore book parameters accept))
                     (cond
                       ((string= endpoint "/topicmaps/919822")
                        (values
                         (hyperdoc::encode-json-string
                          (hyperdoc::dmx-import-read-topicmap remote-client 919822))
                         200
                         (expected-dmx-topicmap-projection-url 919822)
                         "OK"))
                       ((string= endpoint "/core/topic/919822")
                        (values
                         (hyperdoc::encode-json-string (topicmap-core-json))
                         200
                         (expected-dmx-core-topic-url 919822)
                         "OK"))
                       ((search "/core/topic/" endpoint)
                        (memory-body-for-topic
                         (parse-integer (subseq endpoint (length "/core/topic/")))))
                       ((search "/workspaces/object/" endpoint)
                        (let* ((topic-id (parse-integer
                                          (subseq endpoint
                                                  (length "/workspaces/object/"))))
                               (workspace (hyperdoc::dmx-import-read-topic-workspace
                                           remote-client
                                           topic-id)))
                          (if workspace
                              (values (hyperdoc::encode-json-string workspace)
                                      200
                                      (expected-dmx-workspace-object-url topic-id)
                                      "OK")
                              (values ""
                                      204
                                      (expected-dmx-workspace-object-url topic-id)
                                      "No Content"))))
                       ((search "/topicmaps/object/" endpoint)
                        (let ((topic-id (parse-integer
                                         (subseq endpoint
                                                 (length "/topicmaps/object/")))))
                          (values
                           (hyperdoc::encode-json-string
                            (topicmap-memberships-json topic-id))
                           200
                           (expected-dmx-topicmap-memberships-url topic-id)
                           "OK")))
                       ((string= endpoint "/access-control/workspace/919815/owner")
                        (values "rgb" 200 (expected-dmx-workspace-owner-url 919815) "OK"))
                       (t
                        (error "Unexpected DMX repair-console rehearsal fetch ~S"
                               endpoint)))))
             (setf (symbol-function 'hyperdoc/inspector::make-explicit-dmx-repair-client)
                   (lambda (&rest args)
                     (declare (ignore args))
                     remote-client))
             (setf (symbol-function
                    'hyperdoc::make-memory-dmx-import-client-from-workspace-assignment-rehearsal-snapshot)
                   (lambda (snapshot &rest args)
                     (let* ((repair-target (gethash "repairTarget" snapshot))
                            (captures (gethash "captures" snapshot))
                            (topic-id (gethash "topicId" repair-target))
                            (workspace-assignment
                             (gethash "workspaceAssignment" captures))
                            (topicmap-memberships
                             (gethash "topicmapMemberships" captures)))
                       (push (list :snapshot
                                   topic-id
                                   (length (hyperdoc::json-array-elements
                                            topicmap-memberships))
                                   (and workspace-assignment t))
                             events))
                     (apply original-rehearsal-builder snapshot args)))
             (setf (symbol-function
                    'hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair)
                   (lambda (topic-id &rest args &key client dry-run &allow-other-keys)
                     (push (list (if (eq client remote-client)
                                     :remote
                                     :localhost-rehearsal)
                                 topic-id
                                 (and dry-run t)
                                 (and hyperdoc::*dmx-workspace-journal-suppressed-p* t))
                           events)
                     (apply original-execute topic-id args)))
             (hyperdoc::ensure-dmx-workspace-repair-triage triage-page :force? t)
             (assert-equal '(922500)
                           (mapcar #'hyperdoc::dmx-topic-id-of
                                   (hyperdoc::dmx-repair-topic-proxies-of triage-page))
                           "Backlog rehearsal bridge must start from the filtered triage backlog")
             (let ((results
                    (hyperdoc/inspector::repair-workspace-triage-backlog-with-explicit-auth
                     triage-page
                     :dry-run nil
                     :auth-mode :header
                     :authorization-header "Bearer smoke-token")))
               (assert-equal 1
                             (length results)
                             "Backlog rehearsal bridge must return one repaired backlog item")
               (let ((result (first results)))
                 (assert-equal 922500
                               (getf result :topic-id)
                               "Backlog rehearsal bridge must target the selected backlog topic")
                 (assert-true
                  (getf result :localhost-rehearsal-ran-p)
                  "Backlog repair must record that localhost rehearsal ran first")
                 (assert-true
                  (getf result :localhost-rehearsal-success-p)
                  "Backlog repair must require a successful localhost rehearsal before remote mutation")
                 (assert-true
                  (getf result :success-p)
                  "Backlog repair must still succeed remotely after rehearsal")
                 (assert-equal 919815
                               (getf result :result-workspace-id)
                               "Backlog repair must read back workspace 919815 after remote mutation")
                 (assert-true
                  (getf result :result-in-topicmap-p)
                  "Backlog repair must keep topicmap placement intact")))
             (assert-equal
              '((:snapshot 922500 1 nil)
                (:localhost-rehearsal 922500 nil t)
                (:remote 922500 nil nil))
              (nreverse events)
              "Backlog repair must build a bounded rehearsal snapshot, execute localhost rehearsal first, then execute remote repair")
             (assert-equal 919815
                           (hyperdoc::dmx-import-object-id
                            (hyperdoc::dmx-import-read-topic-workspace remote-client
                                                                       922500))
                           "Remote client must receive the final workspace assignment after rehearsal succeeds")
             (assert-true
              (hyperdoc::dmx-import-topic-in-topicmap-p remote-client 919822 922500)
              "Remote repair must not change topicmap placement")
             (assert-equal nil
                           (mapcar #'hyperdoc::dmx-topic-id-of
                                   (hyperdoc::dmx-repair-topic-proxies-of triage-page))
                           "Backlog triage must empty after the remote repair completes")
             (assert-equal original-journal-suppressed-p
                           hyperdoc::*dmx-workspace-journal-suppressed-p*
                           "Localhost rehearsal must restore workspace-journal suppression after the bridge completes"))
        (setf (symbol-function 'hyperdoc::dmx-http-request-body) original-http
              (symbol-function 'hyperdoc/inspector::make-explicit-dmx-repair-client)
              original-explicit-client
              (symbol-function
               'hyperdoc::make-memory-dmx-import-client-from-workspace-assignment-rehearsal-snapshot)
              original-rehearsal-builder
              (symbol-function
               'hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair)
              original-execute)))))

(defun run-repair-console-debug-trace-regression-test ()
  (let* ((single-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922464))
         (book (hyperbook:hyperbook-of single-proxy))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body))
         (original-drakma (symbol-function 'drakma:http-request)))
    (labels ((make-view-props (x y)
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "dmx.topicmaps.x" json) x
                       (gethash "dmx.topicmaps.y" json) y
                       (gethash "dmx.topicmaps.visibility" json) t
                       (gethash "dmx.topicmaps.pinned" json) nil)
                 json))
             (make-membership (topicmap-id assoc-id &optional (value "context-window"))
               (let ((membership (make-hash-table :test #'equal))
                     (assoc (make-hash-table :test #'equal)))
                 (setf (gethash "id" membership) topicmap-id
                       (gethash "value" membership) value
                       (gethash "assoc" membership) assoc
                       (gethash "id" assoc) assoc-id)
                 membership))
             (make-topic-json (id uri type-uri value &optional children-alist)
               (let ((json (make-hash-table :test #'equal))
                     (children (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) id
                       (gethash "uri" json) uri
                       (gethash "typeUri" json) type-uri
                       (gethash "value" json) value
                       (gethash "children" json) children)
                 (dolist (entry children-alist)
                   (let ((child (make-hash-table :test #'equal)))
                     (setf (gethash "value" child) (cdr entry)
                           (gethash (car entry) children) child)))
                 json))
             (canary-topic-json ()
               (make-topic-json
                922464
                "hyperdoc:mcp/workspace-note/operational-definition-chunk-chunk-note-manifest-note-content-topic"
                "dmx.notes.note"
                "Operational definition: chunk, chunk note, manifest note, content topic"))
             (topicmap-core-json ()
               (make-topic-json 919822 "" "dmx.topicmaps.topicmap" "context-window"))
             (topicmap-projection-json ()
               (let ((json (make-hash-table :test #'equal))
                     (topics (make-hash-table :test #'equal))
                     (topic-entry (make-hash-table :test #'equal)))
                 (setf (gethash "id" topic-entry) 922464
                       (gethash "value" topic-entry)
                       "Operational definition: chunk, chunk note, manifest note, content topic"
                       (gethash "viewProps" topic-entry)
                       (make-view-props 24 44)
                       (gethash "topics" json) (vector topic-entry))
                 json))
             (topicmap-memberships-json (topic-id)
               (declare (ignore topic-id))
               (vector (make-membership 919822 922471)))
             (journal-companion-topic-json ()
               (let* ((topic (canary-topic-json))
                      (metadata
                       (hyperdoc::dmx-workspace-journal-subject-metadata-from-topic
                        topic))
                      (subject-key (gethash "subjectKey" metadata))
                      (lookup (gethash "subjectLookup" metadata))
                      (lookup-kind (gethash "kind" lookup))
                      (lookup-value (gethash "value" lookup))
                      (payload
                       (hyperdoc::dmx-workspace-journal-payload-json-from-topic
                        topic))
                      (view-props (make-view-props 24 44))
                      (current-state
                       (hyperdoc::dmx-workspace-journal-snapshot-from-payload
                        subject-key
                        lookup-kind
                        lookup-value
                        919822
                        payload
                        :subject-uri (gethash "subjectUri" metadata)
                        :subject-kind (gethash "subjectKind" metadata)
                        :ownership-class (gethash "ownershipClass" metadata)
                        :note-key (gethash "noteKey" metadata)
                        :note-kind (gethash "noteKind" metadata)
                        :topic-id 922464
                        :in-topicmap t
                        :view-props view-props
                        :workspace-id nil
                        :workspace-title nil))
                      (previous-state
                       (hyperdoc::dmx-workspace-journal-absent-snapshot
                        subject-key
                        lookup-kind
                        lookup-value
                        919822
                        :subject-uri (gethash "subjectUri" metadata)
                        :subject-kind (gethash "subjectKind" metadata)
                        :ownership-class (gethash "ownershipClass" metadata)
                        :note-key (gethash "noteKey" metadata)
                        :note-kind (gethash "noteKind" metadata)))
                      (stream
                       (hyperdoc::dmx-workspace-journal-make-base-stream
                        subject-key
                        lookup-kind
                        lookup-value
                        919822
                        :subject-uri (gethash "subjectUri" metadata)
                        :subject-kind (gethash "subjectKind" metadata)
                        :ownership-class (gethash "ownershipClass" metadata)
                        :note-key (gethash "noteKey" metadata)
                        :note-kind (gethash "noteKind" metadata)))
                      (events
                       (hyperdoc::dmx-workspace-journal-transition-events
                        previous-state
                        current-state
                        hyperdoc::*dmx-workspace-journal-diff-observation-kind*
                        hyperdoc::*dmx-workspace-journal-diff-actor*)))
                 (hyperdoc::dmx-workspace-journal-apply-events-to-stream
                  stream
                  events)
                 (make-topic-json
                  930001
                  (hyperdoc::dmx-workspace-journal-note-uri subject-key)
                  "dmx.notes.note"
                  (hyperdoc::dmx-workspace-journal-visible-title stream)
                  (list (cons hyperdoc::*dmx-notes-text-type-uri*
                              (hyperdoc::encode-json-string stream))))))
             (json-stream (object)
               (make-string-input-stream (hyperdoc::encode-json-string object))))
      (clrhash (hyperdoc::dmx-cache-of book))
      (setf (hyperdoc::dmx-cache-order-of book) nil
            (hyperdoc::dmx-topic-data-of single-proxy) nil
            (hyperdoc::dmx-workspace-data-of single-proxy) nil
            (hyperdoc::dmx-workspace-owner-of single-proxy) nil
            (hyperdoc::dmx-topicmap-memberships-of single-proxy) nil
            (hyperdoc::dmx-diagnostics-of single-proxy) nil
            (hyperdoc::dmx-topicmap-data-of single-proxy) nil
            (hyperdoc::dmx-related-topics-of single-proxy) nil
            (hyperdoc::dmx-repair-results-of single-proxy) nil
            (hyperdoc::dmx-load-error-of single-proxy) nil)
      (unwind-protect
           (progn
             (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                   (lambda (book endpoint &key parameters accept)
                     (declare (ignore book parameters accept))
                     (cond
                       ((string= endpoint "/core/topic/922464")
                        (values
                         (hyperdoc::encode-json-string
                          (canary-topic-json))
                         200
                         (expected-dmx-core-topic-url 922464)
                         "OK"))
                       ((string= endpoint "/core/topic/919822")
                        (values
                         (hyperdoc::encode-json-string (topicmap-core-json))
                         200
                         (expected-dmx-core-topic-url 919822)
                         "OK"))
                       ((string= endpoint "/workspaces/object/922464")
                        (values "" 204 (expected-dmx-workspace-object-url 922464) "No Content"))
                       ((string= endpoint "/topicmaps/object/922464")
                        (values
                         (hyperdoc::encode-json-string
                          (topicmap-memberships-json 922464))
                         200
                         (expected-dmx-topicmap-memberships-url 922464)
                         "OK"))
                       (t
                        (error "Unexpected DMX repair-console fetch ~S" endpoint)))))
             (setf (symbol-function 'drakma:http-request)
                   (lambda (url &key method additional-headers content-type content
                                  content-length want-stream &allow-other-keys)
                     (declare (ignore want-stream))
                     (cond
                       ((search (hyperdoc::dmx-topic-uri-lookup-path
                                 "hyperdoc:mcp/workspace-note/operational-definition-chunk-chunk-note-manifest-note-content-topic")
                                url)
                        (values
                         (json-stream (canary-topic-json))
                         200
                         nil
                         nil nil "OK"))
                       ((search (hyperdoc::dmx-topic-uri-lookup-path
                                 (hyperdoc::dmx-workspace-journal-note-uri
                                  "hyperdoc:mcp/workspace-note/operational-definition-chunk-chunk-note-manifest-note-content-topic"))
                                url)
                        (values
                         (json-stream (journal-companion-topic-json))
                         200
                         nil
                         nil nil "OK"))
                       ((search "/topicmaps/919822?children=true" url)
                        (values
                         (json-stream (topicmap-projection-json))
                         200
                         nil
                         nil nil "OK"))
                       ((search "/core/topic/922464" url)
                        (values
                         (json-stream (canary-topic-json))
                         200
                         nil
                         nil nil "OK"))
                       ((search "/access-control/login" url)
                        (assert-equal :post method
                                      "Repair-console debug trace must POST the login bootstrap")
                        (assert-true
                         (search "Basic "
                                 (cdr (assoc "Authorization"
                                             additional-headers
                                             :test #'string-equal)))
                         "Repair-console debug trace must send Basic auth on the login bootstrap")
                        (values (make-string-input-stream "")
                                204
                                '(("Set-Cookie" . "JSESSIONID=session-123;Path=/;SameSite=Strict"))
                                nil nil "No Content"))
                       ((search "/workspaces/919815/object/922464" url)
                        (assert-equal :put method
                                      "Repair-console debug trace must PUT the workspace assignment")
                        (assert-equal nil
                                      (cdr (assoc "Authorization"
                                                  additional-headers
                                                  :test #'string-equal))
                                      "Repair-console debug trace must switch to session-only auth on the guarded PUT")
                        (assert-equal "JSESSIONID=session-123; dmx_workspace_id=919815"
                                      (cdr (assoc "Cookie"
                                                  additional-headers
                                                  :test #'string-equal))
                                      "Repair-console debug trace must attach JSESSIONID and dmx_workspace_id on the guarded PUT")
                        (assert-equal "application/json"
                                      (cdr (assoc "Accept"
                                                  additional-headers
                                                  :test #'string-equal))
                                      "Repair-console debug trace must ask for JSON on the guarded PUT")
                        (assert-equal nil
                                      content-type
                                      "Repair-console debug trace must leave Content-Type unset on the guarded PUT")
                        (assert-equal 0
                                      content-length
                                      "Repair-console debug trace must keep Content-Length 0 on the guarded PUT")
                        (assert-equal ""
                                      content
                                      "Repair-console debug trace must send an explicit empty body on the guarded PUT")
                        (values (make-string-input-stream "")
                                401
                                nil
                                nil nil "Unauthorized"))
                       ((search "/workspaces/object/922464" url)
                        (values (make-string-input-stream "")
                                204
                                nil
                                nil nil "No Content"))
                       ((search "/topicmaps/object/922464" url)
                        (values (json-stream (topicmap-memberships-json 922464))
                                200
                                nil
                                nil nil "OK"))
                       (t
                        (error "Unexpected Drakma repair-console call ~S" url)))))
             (let* ((auth-context
                     (hyperdoc/inspector::build-dmx-repair-auth-context
                      :auth-mode :basic
                      :username "rgb"
                      :password "secret"))
                    (client
                     (hyperdoc::make-http-dmx-import-client-from-explicit-auth
                      :base-url "https://dmx.ralfbarkow.ch"
                      :workspace-id 919815
                      :auth-mode :basic
                      :username "rgb"
                      :password "secret"))
                    (result
                     (hyperdoc/inspector::repair-topic-proxy-with-client
                      single-proxy
                      client
                      :dry-run nil
                      :auth-mode :basic
                      :auth-context auth-context))
                    (debug-report (getf result :debug-report))
                    (states (getf debug-report :states)))
               (assert-true
                (not (getf result :success-p))
                "Repair-console debug trace regression must surface the guarded PUT failure")
               (assert-equal :basic
                             (getf debug-report :auth-mode)
                             "Repair-console debug trace must preserve the selected auth mode")
               (assert-true
                (getf debug-report :bootstrap-ran-p)
                "Repair-console debug trace must show the login bootstrap ran")
               (assert-equal 204
                             (getf debug-report :bootstrap-status-code)
                             "Repair-console debug trace must record the bootstrap status")
               (assert-true
                (getf debug-report :bootstrap-set-cookie-jsessionid-p)
                "Repair-console debug trace must record the Set-Cookie JSESSIONID receipt")
               (assert-true
                (getf debug-report :session-cookie-captured-p)
                "Repair-console debug trace must record that JSESSIONID was captured in memory")
               (assert-equal nil
                             (getf debug-report :guarded-put-authorization-scheme)
                             "Repair-console debug trace must redact the guarded PUT as session-only after bootstrap")
               (assert-equal "JSESSIONID + dmx_workspace_id"
                             (getf debug-report :guarded-put-cookie-shape)
                             "Repair-console debug trace must redact the guarded PUT cookie shape")
               (assert-true
                (getf debug-report :guarded-put-jsessionid-cookie-p)
                "Repair-console debug trace must prove the guarded PUT carried JSESSIONID")
               (assert-true
                (getf debug-report :guarded-put-workspace-cookie-p)
                "Repair-console debug trace must prove the guarded PUT carried the workspace cookie")
               (assert-equal "application/json"
                             (getf debug-report :guarded-put-accept-header)
                             "Repair-console debug trace must expose the guarded PUT Accept header")
               (assert-equal 0
                             (getf debug-report :guarded-put-content-length)
                             "Repair-console debug trace must expose the guarded PUT Content-Length")
               (assert-true
                (getf debug-report :guarded-put-empty-body-p)
                "Repair-console debug trace must expose the guarded PUT empty-body flag")
               (assert-equal 401
                             (getf debug-report :guarded-put-status-code)
                             "Repair-console debug trace must expose the guarded PUT failure status")
               (assert-equal 204
                             (getf debug-report :workspace-readback-status-code)
                             "Repair-console debug trace must expose the post-failure workspace readback status")
               (assert-equal 200
                             (getf debug-report :topicmap-readback-status-code)
                             "Repair-console debug trace must expose the post-failure topicmap readback status")
               (assert-equal nil
                             (getf result :result-workspace-id)
                             "Repair-console debug trace must preserve the missing workspace assignment after failed readback")
               (assert-true
                (getf result :result-in-topicmap-p)
                "Repair-console debug trace must preserve the successful topicmap readback even after the failed PUT")
               (assert-equal "S13 terminal failure"
                             (getf debug-report :current-state-label)
                             "Repair-console debug trace must identify the terminal failure state")
               (assert-equal "S9 -> S10 (guarded PUT reached DMX with JSESSIONID but returned 401)"
                             (getf debug-report :failure-transition)
                             "Repair-console debug trace must pinpoint the failing transition")
               (assert-true
                (getf (find :s5 states
                            :key (lambda (row) (getf row :state))
                            :test #'eq)
                      :reached-p)
                "Repair-console debug trace must mark S5 reached")
               (assert-true
                (getf (find :s10 states
                            :key (lambda (row) (getf row :state))
                            :test #'eq)
                      :reached-p)
                "Repair-console debug trace must mark S10 reached")
               (assert-true
                (getf (find :s11 states
                            :key (lambda (row) (getf row :state))
                            :test #'eq)
                      :reached-p)
                "Repair-console debug trace must mark S11 reached after the failed PUT")
               (assert-true
                (getf (find :s13 states
                            :key (lambda (row) (getf row :state))
                            :test #'eq)
                      :reached-p)
                "Repair-console debug trace must mark S13 reached")
               (assert-true
                (not (getf (find :s12 states
                                 :key (lambda (row) (getf row :state))
                                 :test #'eq)
                           :reached-p))
                "Repair-console debug trace must leave S12 unreached on error"))))
      (setf (symbol-function 'hyperdoc::dmx-http-request-body) original-http
            (symbol-function 'drakma:http-request) original-drakma))))

(defun run-topicmap-designator-helper-test ()
  (let* ((id 913836)
         (url "https://dmx.ralfbarkow.ch/core/topic/913836?children=true&assocChildren=true")
         (proxy-from-integer (hyperdoc::make-dmx-topicmap-proxy id))
         (proxy-from-url (hyperdoc::make-dmx-topicmap-proxy url)))
    (dolist (proxy (list proxy-from-integer proxy-from-url))
      (assert-type 'hyperdoc::dmx-topic-proxy
                   proxy
                   "Topicmap helper must return DMX proxy")
      (assert-equal id
                    (hyperdoc::dmx-topic-id-of proxy)
                    "Topicmap helper topic-id")
      (assert-equal id
                    (hyperdoc::dmx-topicmap-id-of proxy)
                    "Topicmap helper topicmap-id")
      (assert-equal (expected-dmx-core-topic-url id)
                    (hyperdoc::dmx-topicmap-core-topic-url proxy)
                    "Topicmap helper must expose the exact core-topic URL")))
  (let ((raised nil))
    (handler-case
        (hyperdoc::make-dmx-topicmap-proxy 'hyperdoc::not-a-topicmap)
      (hyperdoc::unknown-dmx-topic-identifier ()
        (setf raised t)))
    (unless raised
      (error "Bad topicmap helper input must signal HYPERDOC::UNKNOWN-DMX-TOPIC-IDENTIFIER"))))

(defun run-shared-workspace-operational-state-page-awareness-test ()
  (let* ((page (hyperdoc::make-dmx-shared-workspace-object
                :workspace-id 111111
                :topicmap-id 222222))
         (matching-result
          '(:success-p t
            :dry-run nil
            :result-workspace-id 111111
            :result-in-topicmap-p t))
         (mismatched-result
          '(:success-p t
            :dry-run nil
            :result-workspace-id 919815
            :result-in-topicmap-p t)))
    (assert-equal "repair-succeeded"
                  (hyperdoc/inspector::dmx-repair-result-operational-state-label
                   page
                   matching-result)
                  "Operational-state helper must classify success against the page workspace id")
    (assert-equal "in-topicmap-but-unassigned"
                  (hyperdoc/inspector::dmx-repair-result-operational-state-label
                   page
                   mismatched-result)
                  "Operational-state helper must not treat mismatched workspace ids as repair success")))

(defun run-dmx-repair-auth-state-machine-run-status-smoke-test ()
  (let* ((running-run
          (hyperdoc/inspector::make-dmx-repair-auth-state-machine-run
           :result '(:trace-state :s6 :success-p nil)
           :auth-context '(:auth-mode :basic)
           :debug-events nil))
         (success-run
          (hyperdoc/inspector::make-dmx-repair-auth-state-machine-run
           :result '(:trace-state :s12 :success-p t :outcome :ok)
           :auth-context '(:auth-mode :basic)
           :debug-events nil))
         (failure-run
          (hyperdoc/inspector::make-dmx-repair-auth-state-machine-run
           :result '(:trace-state :s13 :success-p nil :outcome :repair-failed)
           :auth-context '(:auth-mode :basic)
           :debug-events nil)))
    (assert-equal :running
                  (hyperdoc::state-machine-run-status-of running-run)
                  "Intermediate auth states must remain running")
    (assert-equal :finished
                  (hyperdoc::state-machine-run-status-of success-run)
                  "S12 must classify as finished")
    (assert-equal :failed
                  (hyperdoc::state-machine-run-status-of failure-run)
                  "S13 must classify as failed")))

(defun run-shared-workspace-nondefault-id-rendering-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((missing-proxy
          (make-smoke-diagnostics-proxy
           922464
           "Operational definition: chunk, chunk note, manifest note, content topic"
           :workspace-id nil
           :status :in-topicmap-but-unassigned
           :repair-needed-p t))
         (projection
          (make-smoke-topicmap-projection
           (list (make-smoke-topicmap-projection-topic
                  922464
                  "Operational definition: chunk, chunk note, manifest note, content topic"))))
         (workspace (hyperdoc::make-dmx-shared-workspace-object
                     :workspace-id 111111
                     :topicmap-id 222222))
         (topicmap (hyperdoc::make-dmx-shared-topicmap-object
                    :workspace-id 111111
                    :topicmap-id 222222))
         (original-ensure
          (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)))
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page))
           (dolist (page (list workspace topicmap))
             (setf (hyperdoc::dmx-topicmap-projection-of page) projection
                   (hyperdoc::dmx-triage-topic-proxies-of page) (list missing-proxy)
                   (hyperdoc::dmx-repair-topic-proxies-of page) (list missing-proxy)
                   (hyperdoc::dmx-repair-results-of page) nil
                   (hyperdoc::dmx-repair-summary-of page) nil
                   (hyperdoc::dmx-load-error-of page) nil))
           (let* ((workspace-views
                   (dmx-topic-proxy-smoke-load-inspector-views-for-object workspace))
                  (topicmap-views
                   (dmx-topic-proxy-smoke-load-inspector-views-for-object topicmap))
                  (workspace-overview
                   (dmx-topic-proxy-smoke-find-view-by-title workspace-views "Overview"))
                  (workspace-missing
                   (dmx-topic-proxy-smoke-find-view-by-title
                    workspace-views
                    "Topics missing workspace assignment"))
                  (topicmap-overview
                   (dmx-topic-proxy-smoke-find-view-by-title topicmap-views "Overview")))
             (assert-true
              (search "topicmap 222222"
                      (html-inspector-views:view-html workspace-overview)
                      :test #'char=)
              "Workspace overview must render the page topicmap id, not a hard-coded default")
             (assert-true
              (search "topicmap 222222"
                      (html-inspector-views:view-html workspace-missing)
                      :test #'char=)
              "Missing-assignment view must render the page topicmap id, not a hard-coded default")
             (assert-true
              (search "workspace 111111"
                      (html-inspector-views:view-html workspace-missing)
                      :test #'char=)
              "Missing-assignment view must render the page workspace id, not a hard-coded default")
             (assert-true
              (search "topicmap 222222"
                      (html-inspector-views:view-html topicmap-overview)
                      :test #'char=)
              "Topicmap overview must render the page topicmap id, not a hard-coded default")))
      (setf (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)
            original-ensure))))

(defun run-repair-results-table-page-aware-state-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((page (hyperdoc::make-dmx-shared-workspace-object
                :workspace-id 111111
                :topicmap-id 222222))
         (result
          '(:topic-id 922464
            :topic-title "Operational definition: chunk, chunk note, manifest note, content topic"
            :auth-mode :header
            :success-p t
            :dry-run nil
            :workspace-action :assigned
            :result-workspace-id 111111
            :result-workspace-title "alt-context"
            :result-in-topicmap-p t
            :debug-report (:current-state-label "S12 terminal success")))
         (original-ensure
          (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)))
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page))
           (setf (hyperdoc::dmx-topicmap-projection-of page) nil
                 (hyperdoc::dmx-triage-topic-proxies-of page) nil
                 (hyperdoc::dmx-repair-topic-proxies-of page) nil
                 (hyperdoc::dmx-repair-results-of page) (list result)
                 (hyperdoc::dmx-repair-summary-of page) nil
                 (hyperdoc::dmx-load-error-of page) nil)
           (let* ((views (dmx-topic-proxy-smoke-load-inspector-views-for-object page))
                  (repair-view
                   (dmx-topic-proxy-smoke-find-view-by-title views "Repair console"))
                  (html (html-inspector-views:view-html repair-view)))
             (assert-true
              (search "Operational state" html :test #'char=)
              "Repair-results table must keep the Operational state column")
             (assert-true
              (search "repair-succeeded" html :test #'char=)
              "Repair-results table must classify state with the page-aware helper")
             (assert-true
              (search "In topicmap 222222" html :test #'char=)
              "Repair-results table header must render the page topicmap id")))
      (setf (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)
            original-ensure))))

(defun run-shared-workspace-inspectable-object-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((healthy-proxy
          (make-smoke-diagnostics-proxy
           922586
           "Guarded workspace default verification note"
           :workspace-id 919815
           :status :ok))
         (missing-proxy
          (make-smoke-diagnostics-proxy
           922464
           "Operational definition: chunk, chunk note, manifest note, content topic"
           :workspace-id nil
           :status :in-topicmap-but-unassigned
           :repair-needed-p t))
         (foreign-proxy
          (make-smoke-diagnostics-proxy
           922451
           "auth probe"
           :workspace-id nil
           :ownership-class :foreign
           :hyperdoc-owned-p nil
           :status :foreign-object))
         (projection
          (make-smoke-topicmap-projection
           (list (make-smoke-topicmap-projection-topic
                  922451
                  "auth probe")
                 (make-smoke-topicmap-projection-topic
                  922464
                  "Operational definition: chunk, chunk note, manifest note, content topic")
                 (make-smoke-topicmap-projection-topic
                  922586
                  "Guarded workspace default verification note"))))
         (topic-proxies (list healthy-proxy missing-proxy foreign-proxy))
         (repair-proxies (list missing-proxy))
         (workspace (hyperdoc::make-dmx-shared-workspace-object))
         (topicmap (hyperdoc::make-dmx-shared-topicmap-object))
         (original-ensure
          (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)))
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page))
           (dolist (page (list workspace topicmap))
             (setf (hyperdoc::dmx-topicmap-projection-of page) projection
                   (hyperdoc::dmx-triage-topic-proxies-of page) topic-proxies
                   (hyperdoc::dmx-repair-topic-proxies-of page) repair-proxies
                   (hyperdoc::dmx-repair-results-of page) nil
                   (hyperdoc::dmx-repair-summary-of page) nil
                   (hyperdoc::dmx-load-error-of page) nil))
           (assert-type 'hyperdoc::dmx-shared-workspace-object
                        workspace
                        "Shared workspace helper must return a first-class workspace object")
           (assert-type 'hyperdoc::dmx-shared-topicmap-object
                        topicmap
                        "Shared topicmap helper must return a first-class topicmap object")
           (assert-equal 919815
                         (hyperdoc::dmx-workspace-id-of workspace)
                         "Workspace object must keep workspace 919815")
           (assert-equal 919822
                         (hyperdoc::dmx-topicmap-id-of topicmap)
                         "Topicmap object must keep topicmap 919822")
           (assert-equal '(922464)
                         (hyperdoc/inspector::repair-workspace-triage-topic-ids workspace)
                         "Workspace object must reuse the existing narrow repair backlog helper")
           (assert-equal '(922464)
                         (hyperdoc/inspector::repair-workspace-triage-topic-ids topicmap)
                         "Topicmap object must reuse the existing narrow repair backlog helper")
           (let* ((workspace-views
                   (dmx-topic-proxy-smoke-load-inspector-views-for-object workspace))
                  (topicmap-views
                   (dmx-topic-proxy-smoke-load-inspector-views-for-object topicmap))
                  (workspace-overview
                   (dmx-topic-proxy-smoke-find-view-by-title workspace-views "Overview"))
                  (workspace-missing
                   (dmx-topic-proxy-smoke-find-view-by-title
                    workspace-views
                    "Topics missing workspace assignment"))
                  (workspace-assigned
                   (dmx-topic-proxy-smoke-find-view-by-title
                    workspace-views
                    "Assigned topics"))
                  (workspace-repair
                   (dmx-topic-proxy-smoke-find-view-by-title
                    workspace-views
                    "Repair console"))
                  (topicmap-overview
                   (dmx-topic-proxy-smoke-find-view-by-title topicmap-views "Overview"))
                  (topicmap-visible
                   (dmx-topic-proxy-smoke-find-view-by-title
                    topicmap-views
                    "Visible topics"))
                  (topicmap-unassigned
                   (dmx-topic-proxy-smoke-find-view-by-title
                    topicmap-views
                    "Visible but unassigned"))
                  (topicmap-repair
                   (dmx-topic-proxy-smoke-find-view-by-title
                    topicmap-views
                    "Repair console")))
             (dolist (view (list workspace-overview
                                 workspace-missing
                                 workspace-assigned
                                 workspace-repair
                                 topicmap-overview
                                 topicmap-visible
                                 topicmap-unassigned
                                 topicmap-repair))
               (assert-true view
                            "Inspectable workspace/topicmap smoke must expose all expected views"))
             (assert-true
              (search "Workspace context-window workspace (919815)"
                      (html-inspector-views:view-html workspace-overview)
                      :test #'char=)
              "Workspace overview must expose the inspectable workspace anchor")
             (assert-true
              (search "Topicmap context-window topicmap (919822)"
                      (html-inspector-views:view-html workspace-overview)
                      :test #'char=)
              "Workspace overview must expose the inspectable topicmap anchor")
             (assert-true
              (search "in-topicmap-but-unassigned"
                      (html-inspector-views:view-html workspace-missing)
                      :test #'char=)
              "Workspace missing-assignment view must expose the canonical defect state")
             (assert-true
              (search "foreign-no-action"
                      (html-inspector-views:view-html workspace-missing)
                      :test #'char=)
              "Workspace missing-assignment view must keep foreign rows read-only")
             (assert-true
              (search "healthy"
                      (html-inspector-views:view-html workspace-assigned)
                      :test #'char=)
              "Workspace assigned-topics view must expose healthy rows")
             (assert-true
              (search "Workspace diagnostics"
                      (html-inspector-views:view-html topicmap-unassigned)
                      :test #'char=)
              "Topicmap unassigned view must link rows to the existing single-topic diagnostics surface")
             (assert-true
              (search "repair_workspace_topic_assignment"
                      (html-inspector-views:view-html topicmap-repair)
                      :test #'char=)
              "Topicmap repair console must name the existing narrow repair operation")
             (assert-true
              (search "Repair all missing workspace assignments"
                      (html-inspector-views:view-html topicmap-repair)
                      :test #'char=)
              "Topicmap repair console must expose only the guarded batch wrapper label")
             (assert-true
              (search "healthy"
                      (html-inspector-views:view-html topicmap-visible)
                      :test #'char=)
              "Topicmap visible-topics view must classify assigned rows as healthy")))
      (setf (symbol-function 'hyperdoc::ensure-dmx-workspace-repair-triage)
            original-ensure))))

(defparameter *dmx-topic-936040-uri*
  "hyperdoc:mcp/workspace-annotation/dom-relation-list-item-h1-lafont-1990-interaction-nets-h2-core-concepts-from-lafont-1990-ul-2-item-3-an-active-alive-pair-is-two-agents-connected-by-principal-ports-to-dock-annotation")

(defparameter *dmx-topic-936040-title*
  "Annotation: An active/alive pair is two agents connected by principal ports.")

(defparameter *dmx-topic-936040-annotation-key*
  "dom-relation-list-item-h1-lafont-1990-interaction-nets-h2-core-concepts-from-lafont-1990-ul-2-item-3-an-active-alive-pair-is-two-agents-connected-by-principal-ports-to-dock-annotation")

(defparameter *dmx-topic-936040-runtime-relation-id*
  "dom-relation-list-item-h1-lafont-1990-interaction-nets-h2-core-concepts-from-lafont-1990-ul-2-item-3")

(defun make-dmx-topic-proxy-meta-json-object (&rest key-values)
  (let ((object (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (setf (gethash key object) value))
    object))

(defun make-dmx-topic-proxy-meta-child (type-uri value)
  (make-dmx-topic-proxy-meta-json-object
   "typeUri" type-uri
   "value" value))

(defun make-dmx-topic-936040-carrier-json-string ()
  (hyperdoc::encode-json-string
   (make-dmx-topic-proxy-meta-json-object
    "schemaVersion" 1
    "storageMode" "compatibility-note-carrier"
    "nativeTypeUri" "hyperdoc.annotation"
    "annotationKey"
    *dmx-topic-936040-annotation-key*
    "runtimeRelationId"
    *dmx-topic-936040-runtime-relation-id*
    "workspaceTopicmapId" 919822
    "nativePayload"
    (make-dmx-topic-proxy-meta-json-object
     "sourceAnchor"
     (make-dmx-topic-proxy-meta-json-object
      "page" "Lafont 1990 Interaction Nets"
      "headingPath" (vector "Lafont 1990 Interaction Nets"
                            "Core concepts from Lafont 1990")
      "listContainer" "ul[2]"
      "itemIndex" 3)
     "targetAnchor"
     (make-dmx-topic-proxy-meta-json-object
      "target" "dock-annotation"
      "label" "Annotation")))))

(defun make-dmx-topic-936040-topic-json ()
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash "dmx.notes.title" children)
          (make-dmx-topic-proxy-meta-child "dmx.notes.title"
                                           *dmx-topic-936040-title*)
          (gethash "dmx.notes.text" children)
          (make-dmx-topic-proxy-meta-child "dmx.notes.text"
                                           (make-dmx-topic-936040-carrier-json-string))
          (gethash "dmx.timestamps.created" children)
          (make-dmx-topic-proxy-meta-child "dmx.timestamps.created"
                                           1778000000000)
          (gethash "dmx.timestamps.modified" children)
          (make-dmx-topic-proxy-meta-child "dmx.timestamps.modified"
                                           1778000001000))
    (make-dmx-topic-proxy-meta-json-object
     "id" 936040
     "uri" *dmx-topic-936040-uri*
     "typeUri" "dmx.notes.note"
     "value" *dmx-topic-936040-title*
     "children" children)))

(defun make-dmx-topic-936040-memberships-json ()
  (let ((assoc (make-dmx-topic-proxy-meta-json-object "id" 936041)))
    (vector
     (make-dmx-topic-proxy-meta-json-object
      "id" 919822
      "value" "context-window"
      "assoc" assoc))))

(defun make-dmx-topic-936040-type-topics-json ()
  (vector
   (make-dmx-topic-proxy-meta-json-object
    "id" 1234
    "uri" "dmx.notes.note"
    "typeUri" "dmx.core.topic_type"
    "value" "Note")))

(defun seed-dmx-topic-936040-proxy-fixture (proxy)
  (setf (hyperdoc::dmx-topic-data-of proxy) (make-dmx-topic-936040-topic-json)
        (hyperdoc::dmx-workspace-data-of proxy) nil
        (hyperdoc::dmx-workspace-owner-of proxy) nil
        (hyperdoc::dmx-topicmap-memberships-of proxy)
        (make-dmx-topic-936040-memberships-json)
        (hyperdoc::dmx-topicmap-data-of proxy) (make-smoke-json "context-window")
        (hyperdoc::dmx-related-topics-of proxy)
        (make-dmx-topic-936040-type-topics-json)
        (hyperdoc::dmx-load-error-of proxy) nil
        (hyperdoc::dmx-diagnostics-of proxy)
        (hyperdoc::make-dmx-topic-diagnostics
         :topic-id 936040
         :topicmap-id 919822
         :topic-uri *dmx-topic-936040-uri*
         :topic-type-uri "dmx.notes.note"
         :topic-title *dmx-topic-936040-title*
         :workspace-id nil
         :workspace-title nil
         :workspace-owner nil
         :topicmap-memberships
         (coerce (make-dmx-topic-936040-memberships-json) 'list)
         :selected-topicmap-membership-p t
         :ownership-class :hyperdoc-workspace-annotation
         :ownership-reason "936040 smoke fixture"
         :hyperdoc-owned-p t
         :source-endpoints nil
         :status :in-topicmap-but-unassigned
         :status-reason "Topicmap placement present; workspace assignment missing."
         :repair-needed-p t))
  proxy)

(defun make-dmx-topic-936040-dock-annotation-fixture ()
  (let ((source-anchor
         (make-instance
          'hyperdoc::dom-annotation-anchor
          :provider-kind "dom-v1"
          :view-kind "content"
          :view-title "Main page"
          :context-object-id "lafont-1990-interaction-nets"
          :strategy "list-item-anchor"
          :value "list-item:h1/lafont-1990-interaction-nets/h2/core-concepts-from-lafont-1990/ul[2]/item[3]"
          :label "An active/alive pair is two agents connected by principal ports."
          :section-path
          '("Lafont 1990 Interaction Nets"
            "Core concepts from Lafont 1990")
          :object-id "lafont-active-alive-pair-item"))
        (target-anchor
         (make-instance
          'hyperdoc::dom-annotation-anchor
          :provider-kind "dock-v1"
          :view-kind "dock-target"
          :view-title "Main page"
          :context-object-id "lafont-1990-interaction-nets"
          :strategy "annotation-topic"
          :value "dock-annotation"
          :label "Annotation"
          :object-id "dock-annotation")))
    (make-instance
     'hyperdoc::workspace-dock-annotation
     :id *dmx-topic-936040-runtime-relation-id*
     :title *dmx-topic-936040-title*
     :summary "HyperDoc workspace annotation carrier fixture for the Lafont active/alive pair relation."
     :context-view-title "Main page"
     :source-anchor source-anchor
     :target-anchor target-anchor
     :target-object (hyperdoc::annotation-topic)
     :relation-kind "annotation"
     :note "Preserved compatibility carrier topic"
     :workspace-topic-id 936040
     :workspace-topic-uri *dmx-topic-936040-uri*
     :workspace-topicmap-id 919822
     :workspace-id nil
     :storage-mode hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*
     :carrier-type-uri "dmx.notes.note"
     :annotation-key *dmx-topic-936040-annotation-key*
     :runtime-relation-id *dmx-topic-936040-runtime-relation-id*)))

(defun run-dmx-topic-proxy-meta-view-936040-smoke-test ()
  (let* ((proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 936040))
         (original-ensure-diagnostics
          (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics))
         (original-ensure-related
          (symbol-function 'hyperdoc::ensure-dmx-related-topics))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (seed-dmx-topic-936040-proxy-fixture proxy)
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page)
                 (symbol-function 'hyperdoc::ensure-dmx-related-topics)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page)
                 (symbol-function 'hyperdoc::dmx-http-request-body)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (error "DMX topic 936040 Meta fixture must not issue HTTP calls")))
           (let* ((views (dmx-topic-proxy-smoke-load-inspector-views-for-object
                          proxy))
                  (meta (dmx-topic-proxy-smoke-find-view-by-title
                         views
                         "Meta"))
                  (raw (dmx-topic-proxy-smoke-find-view-by-title
                        views
                        "Raw fetched data"))
                  (diagnostics
                   (dmx-topic-proxy-smoke-find-view-by-title
                    views
                    "Workspace diagnostics"))
                  (html (and meta
                             (html-inspector-views:view-html meta))))
             (assert-true meta
                          "DMX topic proxy must expose the Meta view")
             (assert-true raw
                          "Raw fetched data view must remain available")
             (assert-true diagnostics
                          "Workspace diagnostics view must remain available")
             (dolist (needle (list "936040"
                                   *dmx-topic-936040-uri*
                                   *dmx-topic-936040-title*
                                   "Note"
                                   "dmx.notes.note"
                                   "n/a"
                                   "annotationKey"
                                   "runtimeRelationId"
                                   "workspaceTopicmapId"
                                   "hyperdoc.annotation"
                                   "Lafont 1990 Interaction Nets"
                                   "Core concepts from Lafont 1990"
                                   "ul[2]"
                                   "dock-annotation"
                                   "Annotation"
                                   "Public assignment blocked; use privileged initial assignment repair"))
               (assert-true
                (search needle html :test #'char=)
                (format nil "Meta view for topic 936040 must render ~S"
                        needle)))
             (assert-true
              (search "Read-only DMX-inspired metadata view"
                      html
                      :test #'char=)
              "Meta view must state the read-only boundary")))
      (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
            original-ensure-diagnostics
            (symbol-function 'hyperdoc::ensure-dmx-related-topics)
            original-ensure-related
            (symbol-function 'hyperdoc::dmx-http-request-body)
            original-http))))

(defun run-dmx-topic-proxy-workspace-assignment-card-936040-smoke-test ()
  (let* ((proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 936040))
         (original-ensure-diagnostics
          (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (seed-dmx-topic-936040-proxy-fixture proxy)
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page)
                 (symbol-function 'hyperdoc::dmx-http-request-body)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (error "Workspace assignment repair card smoke test must not issue HTTP calls")))
           (let* ((views (dmx-topic-proxy-smoke-load-inspector-views-for-object
                          proxy))
                  (diagnostics
                   (dmx-topic-proxy-smoke-find-view-by-title
                    views
                    "Workspace diagnostics"))
                  (html (and diagnostics
                             (html-inspector-views:view-html diagnostics))))
             (assert-true diagnostics
                          "DMX topic proxy must expose Workspace diagnostics")
             (dolist (needle (list "Workspace assignment"
                                   "Current workspace"
                                   "n/a"
                                   "Selected topicmap"
                                   "919822"
                                   "Target workspace"
                                   "context-window / 919815"
                                   "PUT /workspaces/919815/object/936040"
                                   "zero-length body"
                                   "Content-Length: 0"
                                   "application/json"
                                   "JSESSIONID"
                                   "redacted"
                                   "dmx_workspace_id=919815"
                                   "Dry-run assignment"
                                   "Public assignment blocked; use privileged initial assignment repair"
                                   "No topic upsert"
                                   "no DMX workspace-journal write"))
               (assert-true
                (search needle html :test #'char=)
                (format nil
                        "Workspace assignment card for topic 936040 must render ~S"
                        needle)))
             (dolist (forbidden '("super-secret" "raw-secret" "token-secret"
                                  "Assign workspace"))
               (assert-true
                (not (search forbidden html :test #'char=))
                (format nil
                        "Workspace assignment card must not render secret-like field ~S"
                        forbidden)))))
      (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
            original-ensure-diagnostics
            (symbol-function 'hyperdoc::dmx-http-request-body)
            original-http))))

(defun run-dmx-topic-proxy-inline-assignment-dry-run-smoke-test ()
  (let* ((proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 936040))
         (events nil)
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body))
         (original-execute
          (symbol-function
           'hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair)))
    (seed-dmx-topic-936040-proxy-fixture proxy)
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (error "Inline dry-run assignment must not issue live HTTP calls"))
                 (symbol-function
                  'hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair)
                 (lambda (topic-id &rest args
                          &key client dry-run workspace-id workspace-topicmap-id
                            &allow-other-keys)
                   (push (list :topic-id topic-id
                               :client-type (type-of client)
                               :dry-run (and dry-run t)
                               :workspace-id workspace-id
                               :workspace-topicmap-id workspace-topicmap-id)
                         events)
                   (apply original-execute topic-id args)))
           (let ((result
                  (hyperdoc/inspector::run-dmx-topic-proxy-inline-workspace-assignment
                   proxy
                   :dry-run t
                   :auth-mode :basic
                   :username "ignored"
                   :password "super-secret"
                   :authorization-header "Basic raw-secret"
                   :auth-token "token-secret"
                   :workspace-id 919815
                   :workspace-topicmap-id 919822)))
             (assert-true (getf result :success-p)
                          "Inline dry-run assignment must return a successful local plan")
             (assert-true (getf result :dry-run)
                          "Inline dry-run assignment must mark the result as dry-run")
             (assert-equal :assign
                           (getf result :workspace-action)
                           "Inline dry-run assignment must plan the workspace assignment")
             (assert-equal
              '((:topic-id 936040
                 :client-type hyperdoc::memory-dmx-import-client
                 :dry-run t
                 :workspace-id 919815
                 :workspace-topicmap-id 919822))
              (reverse events)
              "Inline dry-run assignment must call the existing executor with a memory client")
             (let ((table-input
                    (write-to-string
                     (hyperdoc::dmx-repair-results-of proxy))))
               (dolist (forbidden '("super-secret" "raw-secret" "token-secret"
                                    "Authorization: " "Cookie: "))
                 (assert-true
                  (not (search forbidden table-input :test #'char=))
                  (format nil
                          "Inline dry-run result data must not retain ~S"
                          forbidden))))))
      (setf (symbol-function 'hyperdoc::dmx-http-request-body) original-http
            (symbol-function
             'hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair)
            original-execute))))

(defun run-dmx-topic-proxy-inline-assignment-delegates-smoke-test ()
  (let* ((proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 936040))
         (calls nil)
         (original-explicit
          (symbol-function
           'hyperdoc/inspector::repair-topic-proxy-with-explicit-auth))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (seed-dmx-topic-936040-proxy-fixture proxy)
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (error "Inline assignment delegation smoke test must not issue HTTP calls"))
                 (symbol-function
                  'hyperdoc/inspector::repair-topic-proxy-with-explicit-auth)
                 (lambda (page &rest args
                          &key dry-run auth-mode username password
                            authorization-header auth-token workspace-id
                            workspace-topicmap-id &allow-other-keys)
                   (declare (ignore page username password authorization-header
                                    auth-token))
                   (push (list :dry-run (and dry-run t)
                               :auth-mode auth-mode
                               :workspace-id workspace-id
                               :workspace-topicmap-id workspace-topicmap-id)
                         calls)
                   (list :topic-id 936040
                         :dry-run (and dry-run t)
                         :success-p nil
                         :auth-mode auth-mode
                         :message "stubbed explicit-auth repair helper")))
           (hyperdoc/inspector::run-dmx-topic-proxy-inline-workspace-assignment
            proxy
            :dry-run nil
            :auth-mode :basic
            :username "operator"
            :password "super-secret"
            :authorization-header "Basic raw-secret"
            :auth-token "token-secret"
            :workspace-id 919815
            :workspace-topicmap-id 919822)
           (assert-equal
            '((:dry-run nil
               :auth-mode :basic
               :workspace-id 919815
               :workspace-topicmap-id 919822))
            (reverse calls)
            "Inline Assign workspace action must delegate to the existing explicit-auth repair helper"))
      (setf (symbol-function
             'hyperdoc/inspector::repair-topic-proxy-with-explicit-auth)
            original-explicit
            (symbol-function 'hyperdoc::dmx-http-request-body)
            original-http))))

(defun run-dmx-topic-proxy-url-view-936040-smoke-test ()
  (let* ((proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 936040))
         (original-ensure-diagnostics
          (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics))
         (original-ensure-related
          (symbol-function 'hyperdoc::ensure-dmx-related-topics))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (seed-dmx-topic-936040-proxy-fixture proxy)
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page)
                 (symbol-function 'hyperdoc::ensure-dmx-related-topics)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page)
                 (symbol-function 'hyperdoc::dmx-http-request-body)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (error "DMX topic proxy URL view fixture must not issue HTTP calls")))
           (let* ((views (dmx-topic-proxy-smoke-load-inspector-views-for-object
                          proxy))
                  (url (dmx-topic-proxy-smoke-find-view-by-title views "URL"))
                  (html (and url (html-inspector-views:view-html url))))
             (assert-true url
                          "DMX topic proxy must expose a URL view")
             (dolist (needle '("not routable yet"
                               "(make-dmx-topic-proxy :topic-id 936040 :topicmap-id 919822)"
                               "DMX webclient"))
               (assert-true
                (search needle html :test #'char=)
                (format nil "DMX topic proxy URL view must render ~S"
                        needle)))
             (dolist (forbidden '("127.0.0.1"
                                  "FF160-dmx-topicmap-919822/topic-936040"
                                  "hyperbook-slug"))
               (assert-true
                (not (search forbidden html :test #'char=))
                (format nil
                        "DMX topic proxy URL view must not advertise broken route fragment ~S"
                        forbidden)))))
      (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
            original-ensure-diagnostics
            (symbol-function 'hyperdoc::ensure-dmx-related-topics)
            original-ensure-related
            (symbol-function 'hyperdoc::dmx-http-request-body)
            original-http))))

(defun run-dock-annotation-open-dmx-meta-action-smoke-test ()
  (let* ((annotation (make-dmx-topic-936040-dock-annotation-fixture))
         (original-ensure-diagnostics
          (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics))
         (original-ensure-related
          (symbol-function 'hyperdoc::ensure-dmx-related-topics))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body))
         (proxy nil)
         (buttons-html nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page)
                 (symbol-function 'hyperdoc::ensure-dmx-related-topics)
                 (lambda (page &key force?)
                   (declare (ignore force?))
                   page)
                 (symbol-function 'hyperdoc::dmx-http-request-body)
                 (lambda (&rest args)
                   (declare (ignore args))
                   (error "The dock annotation DMX Meta bridge must not issue HTTP calls in this fixture")))
           (setf proxy (hyperdoc::dock-annotation-dmx-topic-proxy annotation)
                 buttons-html
                 (dmx-topic-proxy-smoke-rendered-html
                  (html-inspector-views:title-bar-action-buttons annotation)))
           (assert-type 'hyperdoc::dmx-topic-proxy
                        proxy
                        "Dock annotation DMX Meta action must resolve a DMX topic proxy")
           (assert-equal 936040
                         (hyperdoc::dmx-topic-id-of proxy)
                         "Dock annotation DMX Meta action must target topic 936040")
           (assert-equal 919822
                         (hyperdoc::dmx-topicmap-id-of proxy)
                         "Dock annotation DMX Meta action must preserve topicmap 919822")
           (assert-true
            (search "Open DMX Meta" buttons-html :test #'char=)
            "Dock annotation title-bar actions must expose Open DMX Meta")
           (seed-dmx-topic-936040-proxy-fixture proxy)
           (let* ((views (dmx-topic-proxy-smoke-load-inspector-views-for-object
                          proxy))
                  (meta (dmx-topic-proxy-smoke-find-view-by-title
                         views
                         "Meta"))
                  (html (and meta
                             (html-inspector-views:view-html meta))))
             (assert-true meta
                          "Opened DMX topic proxy must expose the existing Meta view")
             (dolist (needle (list "936040"
                                   *dmx-topic-936040-uri*
                                   *dmx-topic-936040-title*
                                   "Note"
                                   "dmx.notes.note"
                                   "annotationKey"
                                   "runtimeRelationId"
                                   "workspaceTopicmapId"))
               (assert-true
                (search needle html :test #'char=)
                (format nil "Dock annotation DMX Meta bridge must render ~S"
                        needle)))))
      (setf (symbol-function 'hyperdoc::ensure-dmx-topic-diagnostics)
            original-ensure-diagnostics
            (symbol-function 'hyperdoc::ensure-dmx-related-topics)
            original-ensure-related
            (symbol-function 'hyperdoc::dmx-http-request-body)
            original-http))))

(defun run-operational-definition-launcher-helper-test ()
  (let ((proxy (hyperdoc::make-operational-definition-note-proxy)))
    (assert-type 'hyperdoc::dmx-topic-proxy
                 proxy
                 "Operational-definition launcher must return DMX proxy")
    (assert-equal 922464
                  (hyperdoc::dmx-topic-id-of proxy)
                  "Operational-definition launcher topic-id")
    (assert-equal 919822
                  (hyperdoc::dmx-topicmap-id-of proxy)
                  "Operational-definition launcher topicmap-id")
    (assert-equal (expected-dmx-webclient-url 919822 922464)
                  (hyperdoc::dmx-webclient-url proxy)
                  "Operational-definition launcher must keep the selected topic URL inside the shared workspace topicmap")))

(defun run-unknown-wrapper-smoke-test ()
  (let ((raised nil))
    (handler-case
        (hyperdoc::make-mapped-topic-proxy 'hyperdoc::not-a-mapped-wrapper)
      (hyperdoc::unknown-dmx-topic-wrapper ()
        (setf raised t)))
    (unless raised
      (error "Unknown wrapper must signal HYPERDOC::UNKNOWN-DMX-TOPIC-WRAPPER"))))

(defun run-dmx-topic-proxy-smoke-tests ()
  (dolist (spec *dmx-wrapper-smoke-specs*)
    (run-one-wrapper-smoke-test spec))
  (run-topicmap-designator-helper-test)
  (run-operational-definition-launcher-helper-test)
  (run-topicmap-endpoint-regression-test)
  (run-workspace-diagnostics-regression-test)
  (run-workspace-repair-triage-regression-test)
  (run-explicit-dmx-repair-client-builder-test)
  (run-repair-console-helper-regression-test)
  (run-repair-console-localhost-rehearsal-bridge-smoke-test)
  (run-repair-console-debug-trace-regression-test)
  (run-shared-workspace-operational-state-page-awareness-test)
  (run-dmx-repair-auth-state-machine-run-status-smoke-test)
  (run-shared-workspace-nondefault-id-rendering-smoke-test)
  (run-repair-results-table-page-aware-state-smoke-test)
  (run-shared-workspace-inspectable-object-smoke-test)
  (run-dmx-topic-proxy-meta-view-936040-smoke-test)
  (run-dmx-topic-proxy-workspace-assignment-card-936040-smoke-test)
  (run-dmx-topic-proxy-inline-assignment-dry-run-smoke-test)
  (run-dmx-topic-proxy-inline-assignment-delegates-smoke-test)
  (run-dmx-topic-proxy-url-view-936040-smoke-test)
  (run-dock-annotation-open-dmx-meta-action-smoke-test)
  (run-unknown-wrapper-smoke-test)
  (format t "~&DMX topic proxy smoke tests passed (~D wrappers + topicmap helper + title-first launcher helper + endpoint regression + workspace diagnostics regression + workspace repair triage regression + explicit auth builder regression + repair console helper regression + repair console localhost-rehearsal bridge smoke + repair console debug trace regression + shared-workspace operational-state page-awareness smoke + repair-auth state-machine run-status smoke + shared-workspace nondefault-id rendering smoke + repair-results table page-aware-state smoke + shared-workspace inspectable-object smoke + 936040 Meta view smoke + 936040 inline workspace-assignment repair card smoke + inline dry-run smoke + inline Assign delegation smoke + DMX topic proxy URL view smoke + dock-annotation Open DMX Meta bridge smoke + unknown-wrapper condition).~%"
          (length *dmx-wrapper-smoke-specs*))
  t)
