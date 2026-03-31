;;;; Typed DMX workspace annotations for Dock relations
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defparameter *hyperdoc-workspace-annotation-uri-prefix*
  "hyperdoc:mcp/workspace-annotation/")

(defparameter *dmx-workspace-annotation-type-uri*
  "hyperdoc.annotation")
(defparameter *dmx-workspace-annotation-title-type-uri*
  "hyperdoc.annotation.title")
(defparameter *dmx-workspace-annotation-summary-type-uri*
  "hyperdoc.annotation.summary")
(defparameter *dmx-workspace-annotation-text-type-uri*
  "hyperdoc.annotation.text")
(defparameter *dmx-workspace-annotation-relation-kind-type-uri*
  "hyperdoc.annotation.relation_kind")
(defparameter *dmx-workspace-annotation-status-type-uri*
  "hyperdoc.annotation.status")
(defparameter *dmx-workspace-annotation-source-anchor-json-type-uri*
  "hyperdoc.annotation.source_anchor_json")
(defparameter *dmx-workspace-annotation-target-anchor-json-type-uri*
  "hyperdoc.annotation.target_anchor_json")
(defparameter *dmx-workspace-annotation-context-object-id-type-uri*
  "hyperdoc.annotation.context_object_id")
(defparameter *dmx-workspace-annotation-context-view-title-type-uri*
  "hyperdoc.annotation.context_view_title")
(defparameter *dmx-workspace-annotation-source-object-ref-type-uri*
  "hyperdoc.annotation.source_object_ref")
(defparameter *dmx-workspace-annotation-target-object-ref-type-uri*
  "hyperdoc.annotation.target_object_ref")
(defparameter *dmx-workspace-annotation-runtime-relation-id-type-uri*
  "hyperdoc.annotation.runtime_relation_id")
(defparameter *dmx-workspace-annotation-provenance-type-uri*
  "hyperdoc.annotation.provenance_json")
(defparameter *dmx-workspace-annotation-workspace-topicmap-type-uri*
  "hyperdoc.annotation.workspace_topicmap_id")
(defparameter *dmx-workspace-annotation-source-binding-type-uri*
  "hyperdoc.annotation.source_binding")
(defparameter *dmx-workspace-annotation-target-binding-type-uri*
  "hyperdoc.annotation.target_binding")
(defparameter *dmx-workspace-annotation-context-binding-type-uri*
  "hyperdoc.annotation.context_binding")
(defparameter *dmx-workspace-annotation-supersedes-type-uri*
  "hyperdoc.annotation.supersedes")

(defstruct dmx-workspace-annotation-resolution
  annotation-key
  uri
  workspace-topicmap-id
  workspace-id
  existing-topic
  existing-topic-id
  current-workspace-id
  in-topicmap-p
  topic-action
  workspace-action
  topicmap-action)

(defstruct dmx-workspace-annotation-write-plan
  operation
  annotation-key
  uri
  workspace-topicmap-id
  workspace-id
  title
  summary
  text
  relation-kind
  status
  source-anchor-json
  target-anchor-json
  context-object-id
  context-view-title
  source-object-ref
  target-object-ref
  runtime-relation-id
  provenance-json
  supersedes-topic-id
  view-props
  view-props-normalization
  payload-validation-status
  topic-action
  workspace-action
  topicmap-action
  payload
  existing-topic
  existing-topic-id
  current-workspace-id)

(defparameter *dmx-workspace-annotation-persistence-stage-order*
  '(:normalize-annotation
    :build-write-plan
    :validate-payload
    :prepare-transition
    :topic-upsert
    :workspace-assignment
    :topicmap-placement
    :journal-transition
    :reopen-persisted-annotation))

(defclass workspace-annotation-persistence-debug ()
  ((annotation
    :initarg :annotation
    :reader workspace-annotation-persistence-debug-annotation-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader workspace-annotation-persistence-debug-workspace-topicmap-id-of)
   (workspace-id
    :initarg :workspace-id
    :initform nil
    :reader workspace-annotation-persistence-debug-workspace-id-of)
   (client
    :initarg :client
    :initform nil
    :reader workspace-annotation-persistence-debug-client-of)
   (view-props
    :initarg :view-props
    :initform nil
    :reader workspace-annotation-persistence-debug-view-props-of)
   (requested-status
    :initarg :requested-status
    :initform nil
    :reader workspace-annotation-persistence-debug-requested-status-of)
   (supersedes-topic-id
    :initarg :supersedes-topic-id
    :initform nil
    :reader workspace-annotation-persistence-debug-supersedes-topic-id-of)
   (annotation-key-override
    :initarg :annotation-key-override
    :initform nil
    :reader workspace-annotation-persistence-debug-annotation-key-override-of)
   (provenance-json
    :initarg :provenance-json
    :initform nil
    :reader workspace-annotation-persistence-debug-provenance-json-of)
   (exact-form
    :initarg :exact-form
    :reader workspace-annotation-persistence-debug-exact-form-of)
   (stepper-source
    :initarg :stepper-source
    :reader workspace-annotation-persistence-debug-stepper-source-of)
   (dry-run-preview
    :initarg :dry-run-preview
    :initform nil
    :reader workspace-annotation-persistence-debug-dry-run-preview-of)
   (preview-error
    :initarg :preview-error
    :initform nil
    :reader workspace-annotation-persistence-debug-preview-error-of)
   (annotation-key
    :initarg :annotation-key
    :initform nil
    :reader workspace-annotation-persistence-debug-annotation-key-of)
   (runtime-relation-id
    :initarg :runtime-relation-id
    :initform nil
    :reader workspace-annotation-persistence-debug-runtime-relation-id-of)
   (last-report
    :initarg :last-report
    :initform nil
    :accessor workspace-annotation-persistence-debug-last-report-of)))

(defclass workspace-annotation-persistence-report ()
  ((annotation
    :initarg :annotation
    :reader workspace-annotation-persistence-report-annotation-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader workspace-annotation-persistence-report-workspace-topicmap-id-of)
   (workspace-id
    :initarg :workspace-id
    :initform nil
    :reader workspace-annotation-persistence-report-workspace-id-of)
   (client
    :initarg :client
    :initform nil
    :reader workspace-annotation-persistence-report-client-of)
   (exact-form
    :initarg :exact-form
    :reader workspace-annotation-persistence-report-exact-form-of)
   (stepper-source
    :initarg :stepper-source
    :reader workspace-annotation-persistence-report-stepper-source-of)
   (dry-run-preview
    :initarg :dry-run-preview
    :initform nil
    :reader workspace-annotation-persistence-report-dry-run-preview-of)
   (annotation-key
    :initarg :annotation-key
    :initform nil
    :reader workspace-annotation-persistence-report-annotation-key-of)
   (runtime-relation-id
    :initarg :runtime-relation-id
    :initform nil
    :reader workspace-annotation-persistence-report-runtime-relation-id-of)
   (stage-results
    :initarg :stage-results
    :initform '()
    :reader workspace-annotation-persistence-report-stage-results-of)
   (report-status
    :initarg :report-status
    :reader workspace-annotation-persistence-report-status-of)
   (failure-stage
    :initarg :failure-stage
    :initform nil
    :reader workspace-annotation-persistence-report-failure-stage-of)
   (condition
    :initarg :condition
    :initform nil
    :reader workspace-annotation-persistence-report-condition-of)
   (raw-result
    :initarg :raw-result
    :initform nil
    :reader workspace-annotation-persistence-report-raw-result-of)
   (persisted-topic-id
    :initarg :persisted-topic-id
    :initform nil
    :reader workspace-annotation-persistence-report-persisted-topic-id-of)
   (persisted-annotation
    :initarg :persisted-annotation
    :initform nil
    :reader workspace-annotation-persistence-report-persisted-annotation-of)))

(defclass workspace-dock-annotation (dock-annotation)
  ((workspace-topic-id
    :initarg :workspace-topic-id
    :reader workspace-annotation-topic-id-of)
   (workspace-topic-uri
    :initarg :workspace-topic-uri
    :reader workspace-annotation-topic-uri-of)
   (workspace-topicmap-id
    :initarg :workspace-topicmap-id
    :reader workspace-annotation-topicmap-id-of)
   (workspace-id
    :initarg :workspace-id
    :initform nil
    :reader workspace-annotation-workspace-id-of)
   (annotation-key
    :initarg :annotation-key
    :initform nil
    :reader workspace-annotation-key-of)
   (workspace-status
    :initarg :workspace-status
    :initform nil
    :reader workspace-annotation-status-of)
   (source-anchor-json
    :initarg :source-anchor-json
    :initform nil
    :reader workspace-annotation-source-anchor-json-of)
   (target-anchor-json
    :initarg :target-anchor-json
    :initform nil
    :reader workspace-annotation-target-anchor-json-of)
   (source-object-ref
    :initarg :source-object-ref
    :initform nil
    :reader workspace-annotation-source-object-ref-of)
   (target-object-ref
    :initarg :target-object-ref
    :initform nil
    :reader workspace-annotation-target-object-ref-of)
   (runtime-relation-id
    :initarg :runtime-relation-id
    :initform nil
    :reader workspace-annotation-runtime-relation-id-of)
   (provenance-json
    :initarg :provenance-json
    :initform nil
    :reader workspace-annotation-provenance-json-of)
   (source-binding
    :initarg :source-binding
    :initform nil
    :reader workspace-annotation-source-binding-of)
   (target-binding
    :initarg :target-binding
    :initform nil
    :reader workspace-annotation-target-binding-of)
   (context-binding
    :initarg :context-binding
    :initform nil
    :reader workspace-annotation-context-binding-of)
   (supersedes-binding
    :initarg :supersedes-binding
    :initform nil
    :reader workspace-annotation-supersedes-binding-of)
   (supersedes-topic-id
    :initarg :supersedes-topic-id
    :initform nil
    :reader workspace-annotation-supersedes-topic-id-of)))

(defun workspace-dock-annotation-p (object)
  (typep object 'workspace-dock-annotation))

(defun workspace-annotation-persistence-stage-label (stage)
  (case stage
    (:normalize-annotation "Normalize annotation")
    (:build-write-plan "Build write plan")
    (:validate-payload "Validate payload and view props")
    (:prepare-transition "Prepare workspace journal transition")
    (:topic-upsert "Execute topic upsert")
    (:workspace-assignment "Assign topic to workspace")
    (:topicmap-placement "Add topic to workspace topicmap")
    (:journal-transition "Emit workspace journal event")
    (:reopen-persisted-annotation "Reopen persisted annotation")
    (otherwise
     (code-path-graph-human-label stage))))

(defun workspace-annotation-persistence-stage-entry
    (stage status summary &key detail)
  (list :stage stage
        :label (workspace-annotation-persistence-stage-label stage)
        :status status
        :summary summary
        :detail detail))

(defun workspace-annotation-persistence-stage-result (report stage)
  (find stage
        (workspace-annotation-persistence-report-stage-results-of report)
        :test #'eq
        :key (lambda (entry) (getf entry :stage))))

(defun workspace-annotation-persistence-stepper-display-form ()
  (with-standard-io-syntax
    (let ((*package* (find-package :hyperdoc)))
      (prin1-to-string
       '(persist-dock-annotation-to-workspace
         *
         :workspace-topicmap-id *dmx-context-window-topicmap-id*
         :dry-run nil)))))

(defun workspace-annotation-persistence-stepper-source (workspace-topicmap-id)
  (format nil
          "(hyperdoc::plan-dmx-workspace-annotation-write-from-object * :workspace-topicmap-id ~D)~%~%(hyperdoc::persist-dock-annotation-to-workspace * :workspace-topicmap-id ~D :dry-run nil)"
          workspace-topicmap-id
          workspace-topicmap-id))

(defun workspace-annotation-persistence-runtime-relation-id (annotation)
  (or (and (workspace-dock-annotation-p annotation)
           (workspace-annotation-runtime-relation-id-of annotation))
      (id-of annotation)))

(defun workspace-annotation-persistence-derived-key
    (annotation workspace-topicmap-id &key annotation-key-override)
  (or (and (workspace-dock-annotation-p annotation)
           (workspace-annotation-key-of annotation))
      annotation-key-override
      (ignore-errors
        (getf (dmx-workspace-annotation-from-object
               annotation
               workspace-topicmap-id
               :annotation-key annotation-key-override)
              :annotation-key))
      (ignore-errors
        (normalize-dmx-workspace-annotation-key
         annotation-key-override
         (title-of annotation)
         (workspace-annotation-persistence-runtime-relation-id annotation)))))

(defun workspace-annotation-persistence-preview
    (annotation workspace-topicmap-id
     &key workspace-id client view-props status supersedes-topic-id
       annotation-key provenance-json)
  (execute-dmx-workspace-annotation-write-from-object
   annotation
   :workspace-topicmap-id workspace-topicmap-id
   :workspace-id workspace-id
   :client client
   :view-props view-props
   :status status
   :supersedes-topic-id supersedes-topic-id
   :annotation-key annotation-key
   :provenance-json provenance-json
   :dry-run t))

(defun debug-dock-annotation-workspace-persistence
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json)
  (let* ((resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (preview nil)
         (preview-error nil))
    (handler-case
        (setf preview
              (workspace-annotation-persistence-preview
               annotation
               resolved-topicmap-id
               :workspace-id workspace-id
               :client client
               :view-props view-props
               :status status
               :supersedes-topic-id supersedes-topic-id
               :annotation-key annotation-key
               :provenance-json provenance-json))
      (error (condition)
        (setf preview-error condition)))
    (make-instance
     'workspace-annotation-persistence-debug
     :annotation annotation
     :workspace-topicmap-id resolved-topicmap-id
     :workspace-id workspace-id
     :client client
     :view-props view-props
     :requested-status status
     :supersedes-topic-id supersedes-topic-id
     :annotation-key-override annotation-key
     :provenance-json provenance-json
     :exact-form (workspace-annotation-persistence-stepper-display-form)
     :stepper-source
     (workspace-annotation-persistence-stepper-source resolved-topicmap-id)
     :dry-run-preview preview
     :preview-error preview-error
     :annotation-key
     (or (getf preview :annotation-key)
         (workspace-annotation-persistence-derived-key
          annotation
          resolved-topicmap-id
          :annotation-key-override annotation-key))
     :runtime-relation-id
     (workspace-annotation-persistence-runtime-relation-id annotation))))

(defun workspace-annotation-persistence-stage-status (report stage)
  (or (and report
           (getf (workspace-annotation-persistence-stage-result report stage)
                 :status))
      :pending))

(defun workspace-annotation-persistence-stage-summary (report stage fallback)
  (or (and report
           (getf (workspace-annotation-persistence-stage-result report stage)
                 :summary))
      fallback))

(defun workspace-annotation-persistence-code-path-graph
    (annotation workspace-topicmap-id &key annotation-key runtime-relation-id
       report)
  (let ((persisted (and report
                        (workspace-annotation-persistence-report-persisted-annotation-of
                         report))))
    (make-code-path-graph
     :id "workspace-annotation-persistence-path"
     :title "Workspace annotation persistence path"
     :summary
     (format nil
             "Structured path for persisting a Dock annotation into DMX workspace topicmap ~D. It makes the exact write stages explicit so topic upsert, workspace assignment, topicmap placement, journal recording, and reopen failures stop looking like one opaque button."
             workspace-topicmap-id)
     :entrypoints
     (list
      (list :id "debug-action"
            :label "Debug workspace persistence"
            :summary
            "Inspectable entrypoint that exposes the exact persist form, the dry-run preview, and the staged live report.")
      (list :id "persist-action"
            :label "Persist to workspace"
            :summary
            "The existing live annotation action; it remains available unchanged."))    
     :nodes
     (list
      (list :id "annotation"
            :label "Dock annotation"
            :role :runtime-input
            :object annotation
            :summary
            "Current pane-local annotation object bound to * for the stepper surface.")
      (list :id "normalize"
            :label "dmx-workspace-annotation-from-object"
            :role :read-helper
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "dmx-workspace-annotation-from-object"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :normalize-annotation
             "Normalize the draft annotation into the typed workspace payload fields."))
      (list :id "plan"
            :label "plan-dmx-workspace-annotation-write-from-object"
            :role :read-helper
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "plan-dmx-workspace-annotation-write-from-object"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :build-write-plan
             "Build the typed DMX annotation write plan from the current annotation object."))
      (list :id "validate"
            :label "Validate payload and view props"
            :role :diff-engine
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "plan-dmx-workspace-annotation-write"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :validate-payload
             "Confirm canonical payload fields and normalized topicmap view props before any live write."))
      (list :id "prepare-transition"
            :label "dmx-workspace-journal-prepare-transition"
            :role :write-preflight
            :source-file "hyperdoc/dmx-workspace-journal.lisp"
            :source-function "dmx-workspace-journal-prepare-transition"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :prepare-transition
             "Capture the previous workspace-journal state before the live write."))
      (list :id "topic-upsert"
            :label "Topic upsert"
            :role :write-entry
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "execute-dmx-workspace-annotation-write"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :topic-upsert
             "Create or update the typed hyperdoc.annotation topic."))
      (list :id "workspace-assignment"
            :label "dmx-import-assign-topic-to-workspace"
            :role :write-helper
            :source-file "hyperdoc/dmx-import.lisp"
            :source-function "dmx-import-assign-topic-to-workspace"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :workspace-assignment
             "Assign the annotation topic to workspace 919815 when needed."))
      (list :id "topicmap-placement"
            :label "dmx-import-add-topic-to-topicmap"
            :role :write-helper
            :source-file "hyperdoc/dmx-import.lisp"
            :source-function "dmx-import-add-topic-to-topicmap"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :topicmap-placement
             "Place the annotation topic into workspace topicmap 919822 with guarded view props."))
      (list :id "journal-transition"
            :label "dmx-workspace-journal-record-transition"
            :role :write-entry
            :source-file "hyperdoc/dmx-workspace-journal.lisp"
            :source-function "dmx-workspace-journal-record-transition"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :journal-transition
             "Append the durable workspace-journal events for the live annotation write."))
      (list :id "reopen"
            :label "read-dmx-workspace-annotation"
            :role :read-entry
            :source-file "hyperdoc/dmx-annotations.lisp"
            :source-function "read-dmx-workspace-annotation"
            :summary
            (workspace-annotation-persistence-stage-summary
             report
             :reopen-persisted-annotation
             "Reopen the persisted annotation as a stable workspace-dock-annotation object."))
      (list :id "result"
            :label
            (if persisted
                (format nil "Workspace annotation ~D"
                        (workspace-annotation-topic-id-of persisted))
                "Persisted workspace annotation")
            :role :runtime-value
            :object persisted
            :summary
            (if persisted
                (format nil
                        "Persisted annotation reopened through workspace topic id ~D."
                        (workspace-annotation-topic-id-of persisted))
                (format nil
                        "Expected result object for annotation key ~A and runtime relation id ~A."
                        (or annotation-key "-")
                        (or runtime-relation-id "-")))))
     :edges
     (list
      (list :from "annotation"
            :to "normalize"
            :kind :read
            :status (workspace-annotation-persistence-stage-status
                     report
                     :normalize-annotation)
            :summary "Normalize the current annotation object into typed workspace fields.")
      (list :from "normalize"
            :to "plan"
            :kind :read
            :status (workspace-annotation-persistence-stage-status
                     report
                     :build-write-plan)
            :summary "Build the typed write plan for the annotation payload.")
      (list :from "plan"
            :to "validate"
            :kind :read-diff
            :status (workspace-annotation-persistence-stage-status
                     report
                     :validate-payload)
            :summary "Validate payload fields and normalize topicmap view props before writing.")
      (list :from "validate"
            :to "prepare-transition"
            :kind :write-preflight
            :status (workspace-annotation-persistence-stage-status
                     report
                     :prepare-transition)
            :summary "Capture the previous journal state before the write begins.")
      (list :from "prepare-transition"
            :to "topic-upsert"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :topic-upsert)
            :write-capable-p t
            :summary "Create or update the annotation topic.")
      (list :from "topic-upsert"
            :to "workspace-assignment"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :workspace-assignment)
            :write-capable-p t
            :summary "Assign the topic to workspace 919815 when the plan requires it.")
      (list :from "workspace-assignment"
            :to "topicmap-placement"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :topicmap-placement)
            :write-capable-p t
            :summary "Add the topic to workspace topicmap 919822 when the plan requires it.")
      (list :from "topicmap-placement"
            :to "journal-transition"
            :kind :write
            :status (workspace-annotation-persistence-stage-status
                     report
                     :journal-transition)
            :write-capable-p t
            :summary "Record the journal transition after the live mutation succeeds.")
      (list :from "journal-transition"
            :to "reopen"
            :kind :read
            :status (workspace-annotation-persistence-stage-status
                     report
                     :reopen-persisted-annotation)
            :summary "Reopen the persisted annotation by workspace topic id.")
      (list :from "reopen"
            :to "result"
            :kind :result
            :status (workspace-annotation-persistence-stage-status
                     report
                     :reopen-persisted-annotation)
            :summary "Yield the stable workspace annotation inspectable object."))
     :focus-paths
     (list
      (list :id "main-persist-path"
            :label "Main persist path"
            :summary
            "The typed persistence path from the current Dock annotation to the reopened workspace annotation."
            :node-ids
            '("annotation"
              "normalize"
              "plan"
              "validate"
              "prepare-transition"
              "topic-upsert"
              "workspace-assignment"
              "topicmap-placement"
              "journal-transition"
              "reopen"
              "result"))))))

(defun trace-dock-annotation-workspace-persistence-path
    (annotation &key workspace-topicmap-id annotation-key runtime-relation-id)
  (let ((resolved-topicmap-id
          (normalize-required-workspace-topicmap-id workspace-topicmap-id)))
    (workspace-annotation-persistence-code-path-graph
     annotation
     resolved-topicmap-id
     :annotation-key
     (or annotation-key
         (workspace-annotation-persistence-derived-key annotation
                                                      resolved-topicmap-id))
     :runtime-relation-id
     (or runtime-relation-id
         (workspace-annotation-persistence-runtime-relation-id annotation)))))

(defun dmx-workspace-annotation-plist-p (value)
  (and (listp value)
       (evenp (length value))
       (loop for (key nil) on value by #'cddr
             always (or (keywordp key)
                        (symbolp key)
                        (stringp key)))))

(defun dmx-workspace-annotation-camel-case-key (key)
  (let* ((name (string-downcase
                (string
                 (cond
                   ((keywordp key)
                    (symbol-name key))
                   ((symbolp key)
                    (symbol-name key))
                   (t
                    key)))))
         (segments (remove-if #'(lambda (segment) (zerop (length segment)))
                              (cl-ppcre:split "[-_]" name))))
    (with-output-to-string (stream)
      (when segments
        (write-string (first segments) stream)
        (dolist (segment (rest segments))
          (when (plusp (length segment))
            (write-string (string-capitalize segment) stream)))))))

(defun dmx-workspace-annotation-json-friendly-value (value)
  (cond
    ((stringp value)
     value)
    ((pathnamep value)
     (namestring value))
    ((hash-table-p value)
     (let ((json (make-hash-table :test #'equal)))
       (maphash
        (lambda (key child-value)
          (setf (gethash (if (stringp key)
                             key
                             (dmx-workspace-annotation-camel-case-key key))
                         json)
                (dmx-workspace-annotation-json-friendly-value child-value)))
        value)
       json))
    ((vectorp value)
     (map 'vector #'dmx-workspace-annotation-json-friendly-value value))
    ((dmx-workspace-annotation-plist-p value)
     (let ((json (make-hash-table :test #'equal)))
       (loop for (key child-value) on value by #'cddr
             do (setf (gethash (dmx-workspace-annotation-camel-case-key key) json)
                      (dmx-workspace-annotation-json-friendly-value child-value)))
       json))
    ((listp value)
     (coerce (mapcar #'dmx-workspace-annotation-json-friendly-value value)
             'vector))
    (t
     value)))

(defun dmx-workspace-annotation-json-object (&rest key-values)
  (let ((json (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (when value
               (setf (gethash key json)
                     (dmx-workspace-annotation-json-friendly-value value))))
    json))

(defun dmx-workspace-annotation-json-string (&rest key-values)
  (encode-json-string
   (apply #'dmx-workspace-annotation-json-object key-values)))

(defun dmx-workspace-annotation-topic-id (value field boundary &key required?)
  (cond
    ((null value)
     (when required?
       (error 'fedwiki-dmx-import-error
              :message (format nil "~A requires ~A" boundary field)))
     nil)
    (t
     (or (parse-positive-integer value)
         (error 'fedwiki-dmx-import-error
                :message (format nil "~A requires a positive ~A, got ~S"
                                 boundary
                                 field
                                 value))))))

(defun dmx-workspace-annotation-ref-string (value)
  (cond
    ((null value)
     nil)
    ((or (stringp value)
         (pathnamep value)
         (keywordp value)
         (numberp value))
     (format nil "~A" value))
    (t
     (or (ignore-errors (format nil "~A" (id-of value)))
         (ignore-errors (format nil "~A" (title-of value)))
         (format nil "~A" value)))))

(defun dmx-workspace-annotation-anchor-json (anchor)
  (when anchor
    (dmx-workspace-annotation-json-string
     "providerKind" (provider-kind-of anchor)
     "viewKind" (view-kind-of anchor)
     "viewTitle" (view-title-of anchor)
     "paneId" (pane-id-of anchor)
     "contextObjectId" (context-object-id-of anchor)
     "pageTitle" (page-title-of anchor)
     "siteDomain" (site-domain-of anchor)
     "pageSlug" (page-slug-of anchor)
     "storyItemId" (story-item-id-of anchor)
     "storyItemType" (story-item-type-of anchor)
     "strategy" (anchor-strategy-of anchor)
     "value" (anchor-value-of anchor)
     "selector" (selector-of anchor)
     "label" (label-of anchor)
     "tagName" (tag-name-of anchor)
     "textSnippet" (text-snippet-of anchor)
     "path" (and (path-of anchor)
                 (namestring (pathname (path-of anchor))))
     "startLine" (start-line-of anchor)
     "endLine" (end-line-of anchor)
     "startColumn" (start-column-of anchor)
     "endColumn" (end-column-of anchor)
     "sectionPath" (section-path-of anchor)
     "durabilityTier" (durability-tier-of anchor)
     "durabilityNote" (durability-note-of anchor)
     "fallbackStrategy" (fallback-strategy-of anchor)
     "fallbackValue" (fallback-value-of anchor)
     "objectId" (anchor-object-id-of anchor))))

(defun dmx-workspace-annotation-uri (annotation-key)
  (format nil "~A~A"
          *hyperdoc-workspace-annotation-uri-prefix*
          annotation-key))

(defun dmx-workspace-annotation-slug (value)
  (string-trim
   "-"
   (with-output-to-string (stream)
     (loop with previous-hyphen? = nil
           for char across (string-downcase (or value "annotation"))
           do (cond
                ((or (alphanumericp char)
                     (char= char #\_))
                 (write-char char stream)
                 (setf previous-hyphen? nil))
                ((member char '(#\Space #\/ #\- #\: #\. #\# #\@) :test #'char=)
                 (unless previous-hyphen?
                   (write-char #\- stream))
                 (setf previous-hyphen? t)))))))

(defun normalize-dmx-workspace-annotation-key
    (annotation-key title runtime-relation-id &key fresh-key-p)
  (let ((base
          (cond
            ((dmx-non-empty-string-p annotation-key)
             (dmx-workspace-annotation-slug annotation-key))
            ((dmx-non-empty-string-p runtime-relation-id)
             (dmx-workspace-annotation-slug runtime-relation-id))
            (t
             (dmx-workspace-annotation-slug title)))))
    (if fresh-key-p
        (format nil "~A-~D" (or base "annotation") (get-universal-time))
        (or base
            "annotation"))))

(defun dmx-workspace-annotation-topic-title (topic)
  (or (dmx-json-child-value topic *dmx-workspace-annotation-title-type-uri*)
      (dmx-json-object-value topic "value")
      "Workspace annotation"))

(defun dmx-workspace-annotation-annotation-player-ref (uri)
  (dmx-workspace-annotation-json-object
   "role" "annotation"
   "refKind" "topic-uri"
   "refValue" uri))

(defun dmx-workspace-annotation-player-ref (role ref-kind ref-value &key label)
  (dmx-workspace-annotation-json-object
   "role" role
   "refKind" ref-kind
   "refValue" ref-value
   "label" label))

(defun dmx-workspace-annotation-binding-json-string
    (binding-type annotation-uri other-player &rest extra-pairs)
  (apply #'dmx-workspace-annotation-json-string
         "bindingType" binding-type
         "player1" (dmx-workspace-annotation-annotation-player-ref annotation-uri)
         "player2" other-player
         extra-pairs))

(defun dmx-workspace-annotation-provenance-json
    (annotation workspace-topicmap-id)
  (dmx-workspace-annotation-json-string
   "savedFrom" "dock-annotation"
   "dockCapability" (dock-capability-of annotation)
   "runtimeRelationId" (id-of annotation)
   "registryKey" (registry-key-of annotation)
   "workspaceTopicmapId" workspace-topicmap-id
   "annotationClass" (format nil "~(~A~)" (class-name (class-of annotation)))))

(defun dmx-workspace-annotation-children
    (&key title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id uri supersedes-topic-id)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash *dmx-workspace-annotation-title-type-uri* children) title
          (gethash *dmx-workspace-annotation-summary-type-uri* children) summary
          (gethash *dmx-workspace-annotation-text-type-uri* children) text
          (gethash *dmx-workspace-annotation-relation-kind-type-uri* children)
          relation-kind
          (gethash *dmx-workspace-annotation-status-type-uri* children) status
          (gethash *dmx-workspace-annotation-source-anchor-json-type-uri* children)
          source-anchor-json
          (gethash *dmx-workspace-annotation-target-anchor-json-type-uri* children)
          target-anchor-json
          (gethash *dmx-workspace-annotation-context-object-id-type-uri* children)
          context-object-id
          (gethash *dmx-workspace-annotation-context-view-title-type-uri* children)
          context-view-title
          (gethash *dmx-workspace-annotation-source-object-ref-type-uri* children)
          source-object-ref
          (gethash *dmx-workspace-annotation-target-object-ref-type-uri* children)
          target-object-ref
          (gethash *dmx-workspace-annotation-runtime-relation-id-type-uri* children)
          runtime-relation-id
          (gethash *dmx-workspace-annotation-provenance-type-uri* children)
          provenance-json
          (gethash *dmx-workspace-annotation-workspace-topicmap-type-uri* children)
          (write-to-string workspace-topicmap-id)
          (gethash *dmx-workspace-annotation-source-binding-type-uri* children)
          (dmx-workspace-annotation-binding-json-string
           "annotation-source-binding"
           uri
           (dmx-workspace-annotation-player-ref
            "source-object"
            "object-ref"
            source-object-ref
            :label title))
          (gethash *dmx-workspace-annotation-target-binding-type-uri* children)
          (dmx-workspace-annotation-binding-json-string
           "annotation-target-binding"
           uri
           (dmx-workspace-annotation-player-ref
            "target-object"
            "object-ref"
            target-object-ref
            :label "Annotation"))
          (gethash *dmx-workspace-annotation-context-binding-type-uri* children)
          (dmx-workspace-annotation-binding-json-string
           "annotation-context-binding"
           uri
           (dmx-workspace-annotation-player-ref
            "context-object"
            "context-object-id"
            context-object-id
            :label context-view-title)))
    (when supersedes-topic-id
      (setf (gethash *dmx-workspace-annotation-supersedes-type-uri* children)
            (dmx-workspace-annotation-binding-json-string
             "annotation-supersedes"
             uri
             (dmx-workspace-annotation-player-ref
              "superseded-topic"
              "topic-id"
              supersedes-topic-id))))
    children))

(defun dmx-workspace-annotation-payload
    (&key uri title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id supersedes-topic-id)
  (list :uri uri
        :external-key uri
        :type-uri *dmx-workspace-annotation-type-uri*
        :value title
        :children (dmx-workspace-annotation-children
                   :uri uri
                   :title title
                   :summary summary
                   :text text
                   :relation-kind relation-kind
                   :status status
                   :source-anchor-json source-anchor-json
                   :target-anchor-json target-anchor-json
                   :context-object-id context-object-id
                   :context-view-title context-view-title
                   :source-object-ref source-object-ref
                   :target-object-ref target-object-ref
                   :runtime-relation-id runtime-relation-id
                   :provenance-json provenance-json
                   :workspace-topicmap-id workspace-topicmap-id
                   :supersedes-topic-id supersedes-topic-id)))

(defun resolve-dmx-workspace-annotation-workspace-id (workspace-id client)
  (or (and workspace-id
           (dmx-workspace-annotation-topic-id
            workspace-id
            :workspace-id
            'resolve-dmx-workspace-annotation-workspace-id
            :required? t))
      (and (typep client 'http-dmx-import-client)
           (dmx-import-workspace-id-of client))
      *dmx-context-window-workspace-id*))

(defun dmx-workspace-annotation-from-object
    (annotation workspace-topicmap-id &key status supersedes-topic-id
       annotation-key provenance-json)
  (let* ((resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (persisted-p (workspace-dock-annotation-p annotation))
         (runtime-relation-id
           (or (and persisted-p
                    (workspace-annotation-runtime-relation-id-of annotation))
               (id-of annotation)))
         (resolved-status
           (normalize-dmx-workspace-note-string
            (or status
                (and persisted-p
                     (workspace-annotation-status-of annotation))
                "persisted")
            :status
            'dmx-workspace-annotation-from-object
            :required? t))
         (fresh-key-p
           (and supersedes-topic-id
                (not persisted-p)))
         (resolved-key
           (normalize-dmx-workspace-annotation-key
            (or annotation-key
                (and persisted-p
                     (workspace-annotation-key-of annotation)))
            (title-of annotation)
            runtime-relation-id
            :fresh-key-p fresh-key-p))
         (resolved-uri
           (or (and persisted-p
                    (workspace-annotation-topic-uri-of annotation))
               (dmx-workspace-annotation-uri resolved-key))))
    (list :topic-id (and persisted-p
                         (workspace-annotation-topic-id-of annotation))
          :annotation-key resolved-key
          :uri resolved-uri
          :title (normalize-dmx-workspace-note-string
                  (title-of annotation)
                  :title
                  'dmx-workspace-annotation-from-object
                  :required? t)
          :summary (normalize-dmx-workspace-note-string
                    (summary-of annotation)
                    :summary
                    'dmx-workspace-annotation-from-object
                    :required? t)
          :text (normalize-dmx-workspace-note-string
                 (or (note-of annotation) "")
                 :text
                 'dmx-workspace-annotation-from-object
                 :required? t)
          :relation-kind (normalize-dmx-workspace-note-string
                          (or (relation-kind-of annotation)
                              "annotation")
                          :relation-kind
                          'dmx-workspace-annotation-from-object
                          :required? t)
          :status resolved-status
          :source-anchor-json
          (dmx-workspace-annotation-anchor-json (source-anchor-of annotation))
          :target-anchor-json
          (dmx-workspace-annotation-anchor-json (target-anchor-of annotation))
          :context-object-id
          (normalize-dmx-workspace-note-string
           (or (and persisted-p
                    (dmx-workspace-annotation-ref-string
                     (context-object-of annotation)))
               (dock-object-stable-id (or (context-object-of annotation)
                                          (source-object-of annotation)
                                          annotation)))
           :context-object-id
           'dmx-workspace-annotation-from-object
           :required? t)
          :context-view-title (normalize-dmx-workspace-note-string
                               (or (context-view-title-of annotation)
                                   "Inspector")
                               :context-view-title
                               'dmx-workspace-annotation-from-object
                               :required? t)
          :source-object-ref (normalize-dmx-workspace-note-string
                              (or (and persisted-p
                                       (workspace-annotation-source-object-ref-of
                                        annotation))
                                  (dmx-workspace-annotation-ref-string
                                   (source-object-of annotation))
                                  (anchor-object-id-of (source-anchor-of annotation))
                                  (anchor-value-of (source-anchor-of annotation)))
                              :source-object-ref
                              'dmx-workspace-annotation-from-object
                              :required? t)
          :target-object-ref (normalize-dmx-workspace-note-string
                              (or (and persisted-p
                                       (workspace-annotation-target-object-ref-of
                                        annotation))
                                  (dmx-workspace-annotation-ref-string
                                   (target-object-of annotation))
                                  (anchor-object-id-of (target-anchor-of annotation))
                                  (anchor-value-of (target-anchor-of annotation)))
                              :target-object-ref
                              'dmx-workspace-annotation-from-object
                              :required? t)
          :runtime-relation-id runtime-relation-id
          :provenance-json
          (or provenance-json
              (and persisted-p
                   (workspace-annotation-provenance-json-of annotation))
              (dmx-workspace-annotation-provenance-json
               annotation
               resolved-topicmap-id))
          :workspace-topicmap-id resolved-topicmap-id
          :supersedes-topic-id
          (or supersedes-topic-id
              (and persisted-p
                   (workspace-annotation-supersedes-topic-id-of annotation))))))

(defun resolve-dmx-workspace-annotation
    (&key client workspace-topicmap-id workspace-id annotation-key uri topic-id
       title runtime-relation-id supersedes-topic-id)
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-workspace-id
           (resolve-dmx-workspace-annotation-workspace-id workspace-id
                                                          resolved-client))
         (resolved-key
           (cond
             (topic-id
              nil)
             (uri
              (subseq uri (length *hyperdoc-workspace-annotation-uri-prefix*)))
             (t
              (normalize-dmx-workspace-annotation-key
               annotation-key
               title
               runtime-relation-id
               :fresh-key-p (and supersedes-topic-id (null topic-id))))))
         (resolved-uri
           (or uri
               (and resolved-key
                    (dmx-workspace-annotation-uri resolved-key))))
         (existing-topic
           (cond
             (topic-id
              (dmx-import-read-topic
               resolved-client
               (dmx-workspace-annotation-topic-id
                topic-id
                :topic-id
                'resolve-dmx-workspace-annotation
                :required? t)))
             (resolved-uri
              (dmx-import-find-existing-topic resolved-client resolved-uri))
             (t
              nil)))
         (existing-topic-id (dmx-import-object-id existing-topic)))
    (when (and existing-topic
               (not (string= (or (dmx-json-object-value existing-topic "typeUri") "")
                             *dmx-workspace-annotation-type-uri*)))
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "DMX workspace annotation writes require ~A but resolved topic ~D is ~A"
                              *dmx-workspace-annotation-type-uri*
                              existing-topic-id
                              (dmx-json-object-value existing-topic "typeUri"))))
    (let* ((in-topicmap-p
             (and existing-topic-id
                  (dmx-import-topic-in-topicmap-p
                   resolved-client
                   resolved-topicmap-id
                   existing-topic-id)))
           (current-workspace
             (and existing-topic-id
                  (dmx-import-read-topic-workspace
                   resolved-client
                   existing-topic-id)))
           (current-workspace-id
             (dmx-import-object-id current-workspace)))
      (make-dmx-workspace-annotation-resolution
       :annotation-key resolved-key
       :uri resolved-uri
       :workspace-topicmap-id resolved-topicmap-id
       :workspace-id resolved-workspace-id
       :existing-topic existing-topic
       :existing-topic-id existing-topic-id
       :current-workspace-id current-workspace-id
       :in-topicmap-p in-topicmap-p
       :topic-action (if existing-topic :update :create)
       :workspace-action (if (eql current-workspace-id resolved-workspace-id)
                             :unchanged
                             :assign)
       :topicmap-action (if in-topicmap-p :already-present :add)))))

(defun dmx-workspace-annotation-plan-summary (plan)
  (list :operation (dmx-workspace-annotation-write-plan-operation plan)
        :annotation-key (dmx-workspace-annotation-write-plan-annotation-key plan)
        :uri (dmx-workspace-annotation-write-plan-uri plan)
        :workspace-topicmap-id
        (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
        :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
        :title (dmx-workspace-annotation-write-plan-title plan)
        :status (dmx-workspace-annotation-write-plan-status plan)
        :payload-validation-status
        (dmx-workspace-annotation-write-plan-payload-validation-status plan)
        :topic-action (dmx-workspace-annotation-write-plan-topic-action plan)
        :workspace-action
        (dmx-workspace-annotation-write-plan-workspace-action plan)
        :topicmap-action (dmx-workspace-annotation-write-plan-topicmap-action plan)
        :existing-topic-id
        (dmx-workspace-annotation-write-plan-existing-topic-id plan)
        :supersedes-topic-id
        (dmx-workspace-annotation-write-plan-supersedes-topic-id plan)
        :normalized-view-props-json
        (and (dmx-workspace-annotation-write-plan-view-props plan)
             (dmx-topicmap-view-props-json-string
              (dmx-workspace-annotation-write-plan-view-props plan)))))

(defun plan-dmx-workspace-annotation-write
    (&key title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id workspace-id client
       annotation-key uri topic-id supersedes-topic-id view-props)
  (let* ((resolved-title
           (normalize-dmx-workspace-note-string
            title
            :title
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-summary
           (normalize-dmx-workspace-note-string
            summary
            :summary
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-text
           (normalize-dmx-workspace-note-string
            text
            :text
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-relation-kind
           (normalize-dmx-workspace-note-string
            relation-kind
            :relation-kind
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-status
           (normalize-dmx-workspace-note-string
            status
            :status
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-source-anchor-json
           (normalize-dmx-workspace-note-string
            source-anchor-json
            :source-anchor-json
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-target-anchor-json
           (normalize-dmx-workspace-note-string
            target-anchor-json
            :target-anchor-json
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-context-object-id
           (normalize-dmx-workspace-note-string
            context-object-id
            :context-object-id
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-context-view-title
           (normalize-dmx-workspace-note-string
            context-view-title
            :context-view-title
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-source-object-ref
           (normalize-dmx-workspace-note-string
            source-object-ref
            :source-object-ref
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-target-object-ref
           (normalize-dmx-workspace-note-string
            target-object-ref
            :target-object-ref
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-runtime-relation-id
           (normalize-dmx-workspace-note-string
            runtime-relation-id
            :runtime-relation-id
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-provenance-json
           (normalize-dmx-workspace-note-string
            provenance-json
            :provenance-json
            'plan-dmx-workspace-annotation-write
            :required? t))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolution
           (resolve-dmx-workspace-annotation
            :client resolved-client
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :annotation-key annotation-key
            :uri uri
            :topic-id topic-id
            :title resolved-title
            :runtime-relation-id resolved-runtime-relation-id
            :supersedes-topic-id supersedes-topic-id))
         (payload
           (dmx-workspace-annotation-payload
            :uri (dmx-workspace-annotation-resolution-uri resolution)
            :title resolved-title
            :summary resolved-summary
            :text resolved-text
            :relation-kind resolved-relation-kind
            :status resolved-status
            :source-anchor-json resolved-source-anchor-json
            :target-anchor-json resolved-target-anchor-json
            :context-object-id resolved-context-object-id
            :context-view-title resolved-context-view-title
            :source-object-ref resolved-source-object-ref
            :target-object-ref resolved-target-object-ref
            :runtime-relation-id resolved-runtime-relation-id
            :provenance-json resolved-provenance-json
            :workspace-topicmap-id
            (dmx-workspace-annotation-resolution-workspace-topicmap-id resolution)
            :supersedes-topic-id supersedes-topic-id)))
    (multiple-value-bind (resolved-view-props view-props-normalization)
        (normalize-dmx-workspace-note-view-props
         view-props
         'plan-dmx-workspace-annotation-write)
      (make-dmx-workspace-annotation-write-plan
       :operation :workspace-annotation-write
       :annotation-key (dmx-workspace-annotation-resolution-annotation-key
                        resolution)
       :uri (dmx-workspace-annotation-resolution-uri resolution)
       :workspace-topicmap-id
       (dmx-workspace-annotation-resolution-workspace-topicmap-id resolution)
       :workspace-id (dmx-workspace-annotation-resolution-workspace-id resolution)
       :title resolved-title
       :summary resolved-summary
       :text resolved-text
       :relation-kind resolved-relation-kind
       :status resolved-status
       :source-anchor-json resolved-source-anchor-json
       :target-anchor-json resolved-target-anchor-json
       :context-object-id resolved-context-object-id
       :context-view-title resolved-context-view-title
       :source-object-ref resolved-source-object-ref
       :target-object-ref resolved-target-object-ref
       :runtime-relation-id resolved-runtime-relation-id
       :provenance-json resolved-provenance-json
       :supersedes-topic-id supersedes-topic-id
       :view-props resolved-view-props
       :view-props-normalization view-props-normalization
       :payload-validation-status :canonical
       :topic-action (dmx-workspace-annotation-resolution-topic-action resolution)
       :workspace-action
       (dmx-workspace-annotation-resolution-workspace-action resolution)
       :topicmap-action
       (dmx-workspace-annotation-resolution-topicmap-action resolution)
       :payload payload
       :existing-topic (dmx-workspace-annotation-resolution-existing-topic resolution)
       :existing-topic-id
       (dmx-workspace-annotation-resolution-existing-topic-id resolution)
       :current-workspace-id
       (dmx-workspace-annotation-resolution-current-workspace-id resolution)))))

(defun plan-dmx-workspace-annotation-write-from-object
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json)
  (apply #'plan-dmx-workspace-annotation-write
         (append (dmx-workspace-annotation-from-object
                  annotation
                  workspace-topicmap-id
                  :status status
                  :supersedes-topic-id supersedes-topic-id
                  :annotation-key annotation-key
                  :provenance-json provenance-json)
                 (list :workspace-id workspace-id
                       :client client
                       :view-props view-props))))

(defun execute-dmx-workspace-annotation-write
    (&key title summary text relation-kind status source-anchor-json
       target-anchor-json context-object-id context-view-title
       source-object-ref target-object-ref runtime-relation-id
       provenance-json workspace-topicmap-id workspace-id client
       annotation-key uri topic-id supersedes-topic-id view-props
       (dry-run t))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-dmx-workspace-annotation-write
                :title title
                :summary summary
                :text text
                :relation-kind relation-kind
                :status status
                :source-anchor-json source-anchor-json
                :target-anchor-json target-anchor-json
                :context-object-id context-object-id
                :context-view-title context-view-title
                :source-object-ref source-object-ref
                :target-object-ref target-object-ref
                :runtime-relation-id runtime-relation-id
                :provenance-json provenance-json
                :workspace-topicmap-id workspace-topicmap-id
                :workspace-id workspace-id
                :client resolved-client
                :annotation-key annotation-key
                :uri uri
                :topic-id topic-id
                :supersedes-topic-id supersedes-topic-id
                :view-props view-props))
         (subject-key (dmx-workspace-annotation-write-plan-uri plan))
         (previous-preview
           (if-let (existing-topic
                    (dmx-workspace-annotation-write-plan-existing-topic plan))
             (dmx-workspace-journal-live-snapshot
              resolved-client
              existing-topic
              (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan))
             (dmx-workspace-journal-absent-snapshot
              subject-key
              "uri"
              subject-key
              (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
              :subject-uri subject-key
              :subject-kind "workspace-annotation"
              :ownership-class "hyperdoc-workspace-annotation")))
         (next-preview
           (dmx-workspace-journal-snapshot-from-payload
            subject-key
            "uri"
            subject-key
            (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
            (dmx-workspace-journal-payload-json-from-payload
             (dmx-workspace-annotation-write-plan-payload plan))
            :subject-uri subject-key
            :subject-kind "workspace-annotation"
            :ownership-class "hyperdoc-workspace-annotation"
            :topic-id (dmx-workspace-annotation-write-plan-existing-topic-id plan)
            :in-topicmap t
            :view-props
            (if (eql (dmx-workspace-annotation-write-plan-topicmap-action plan)
                     :add)
                (dmx-workspace-annotation-write-plan-view-props plan)
                (gethash "viewProps" previous-preview))
            :workspace-id (dmx-workspace-annotation-write-plan-workspace-id plan)
            :workspace-title (gethash "workspaceTitle" previous-preview)))
         (journal-preview
           (dmx-workspace-journal-transition-preview
            previous-preview
            next-preview)))
    (if dry-run
        (append (dmx-workspace-annotation-plan-summary plan)
                (list :dry-run t
                      :journal-event-preview journal-preview))
        (let* ((previous-state
                 (dmx-workspace-journal-prepare-transition
                  resolved-client
                  subject-key
                  "uri"
                  subject-key
                  (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
                  :subject-uri subject-key
                  :subject-kind "workspace-annotation"
                  :ownership-class "hyperdoc-workspace-annotation"))
               (topic (ecase (dmx-workspace-annotation-write-plan-topic-action plan)
                        (:create
                         (dmx-import-create-topic
                          resolved-client
                          (dmx-workspace-annotation-write-plan-payload plan)))
                        (:update
                         (dmx-import-update-topic
                          resolved-client
                          (dmx-workspace-annotation-write-plan-existing-topic plan)
                          (dmx-workspace-annotation-write-plan-payload plan)))))
               (topic-id* (dmx-import-object-id topic)))
          (when (eql (dmx-workspace-annotation-write-plan-workspace-action plan)
                     :assign)
            (dmx-import-assign-topic-to-workspace
             resolved-client
             (dmx-workspace-annotation-write-plan-workspace-id plan)
             topic-id*))
          (when (eql (dmx-workspace-annotation-write-plan-topicmap-action plan) :add)
            (dmx-import-add-topic-to-topicmap
             resolved-client
             (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)
             topic-id*
             (dmx-workspace-annotation-write-plan-view-props plan)))
          (let* ((after-topic (dmx-import-read-topic resolved-client topic-id*))
                 (after-state
                   (dmx-workspace-journal-live-snapshot
                    resolved-client
                    after-topic
                    (dmx-workspace-annotation-write-plan-workspace-topicmap-id plan)))
                 (journal-events
                   (dmx-workspace-journal-record-transition
                    resolved-client
                    previous-state
                    after-state
                    (dmx-workspace-annotation-write-plan-workspace-topicmap-id
                     plan))))
            (append (dmx-workspace-annotation-plan-summary plan)
                    (list :dry-run nil
                          :topic-id topic-id*
                          :journal-subject-key subject-key
                          :journal-event-count (length journal-events))))))))

(defun execute-dmx-workspace-annotation-write-from-object
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       (dry-run t))
  (apply #'execute-dmx-workspace-annotation-write
         (append (dmx-workspace-annotation-from-object
                  annotation
                  workspace-topicmap-id
                  :status status
                  :supersedes-topic-id supersedes-topic-id
                  :annotation-key annotation-key
                  :provenance-json provenance-json)
                 (list :workspace-id workspace-id
                       :client client
                       :view-props view-props
                       :dry-run dry-run))))

(defun run-dock-annotation-workspace-persistence-debug
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json)
  (let* ((debug
           (debug-dock-annotation-workspace-persistence
            annotation
            :workspace-topicmap-id workspace-topicmap-id
            :workspace-id workspace-id
            :client client
            :view-props view-props
            :status status
            :supersedes-topic-id supersedes-topic-id
            :annotation-key annotation-key
            :provenance-json provenance-json))
         (stage-results '())
         (failure-stage nil)
         (failure-condition nil)
         (persisted-topic-id nil)
         (persisted-annotation nil)
         (raw-result nil)
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run nil :verbose nil)))
         (resolved-topicmap-id
           (workspace-annotation-persistence-debug-workspace-topicmap-id-of debug))
         (subject-key nil)
         (previous-state nil)
         (plan nil))
    (labels ((record-stage (stage status summary &key detail)
               (push (workspace-annotation-persistence-stage-entry
                      stage
                      status
                      summary
                      :detail detail)
                     stage-results))
             (run-stage (stage summary thunk &key detail)
               (handler-case
                   (let ((value (funcall thunk)))
                     (record-stage stage :completed summary :detail detail)
                     value)
                 (error (condition)
                   (setf failure-stage stage
                         failure-condition condition)
                   (record-stage stage
                                 :error
                                 summary
                                 :detail (or detail
                                             (format nil "~A" condition)))
                   (error condition)))))
      (handler-case
          (let ((normalized nil)
                (topic nil)
                (topic-id* nil)
                (after-topic nil)
                (after-state nil)
                (journal-events nil))
            (setf normalized
                  (run-stage
                   :normalize-annotation
                   "Derived the typed workspace annotation fields from the current Dock annotation."
                   (lambda ()
                     (dmx-workspace-annotation-from-object
                      annotation
                      resolved-topicmap-id
                      :status status
                      :supersedes-topic-id supersedes-topic-id
                      :annotation-key annotation-key
                      :provenance-json provenance-json))))
            (setf plan
                  (run-stage
                   :build-write-plan
                   "Built the typed DMX write plan for the annotation payload."
                   (lambda ()
                     (apply #'plan-dmx-workspace-annotation-write
                            (append normalized
                                    (list :workspace-id workspace-id
                                          :client resolved-client
                                          :view-props view-props))))))
            (record-stage
             :validate-payload
             :completed
             (format nil
                     "Payload validation is ~A; topic action ~A, workspace action ~A, topicmap action ~A."
                     (dmx-workspace-annotation-write-plan-payload-validation-status
                      plan)
                     (dmx-workspace-annotation-write-plan-topic-action plan)
                     (dmx-workspace-annotation-write-plan-workspace-action plan)
                     (dmx-workspace-annotation-write-plan-topicmap-action plan))
             :detail
             (and (dmx-workspace-annotation-write-plan-view-props plan)
                  (dmx-topicmap-view-props-json-string
                   (dmx-workspace-annotation-write-plan-view-props plan))))
            (setf subject-key (dmx-workspace-annotation-write-plan-uri plan))
            (setf previous-state
                  (run-stage
                   :prepare-transition
                   "Loaded the previous workspace-journal state for this annotation subject."
                   (lambda ()
                     (dmx-workspace-journal-prepare-transition
                      resolved-client
                      subject-key
                      "uri"
                      subject-key
                      resolved-topicmap-id
                      :subject-uri subject-key
                      :subject-kind "workspace-annotation"
                      :ownership-class "hyperdoc-workspace-annotation"))))
            (setf topic
                  (run-stage
                   :topic-upsert
                   (format nil
                           "Executed the live annotation topic ~A step."
                           (dmx-workspace-annotation-write-plan-topic-action
                            plan))
                   (lambda ()
                     (ecase (dmx-workspace-annotation-write-plan-topic-action
                             plan)
                       (:create
                        (dmx-import-create-topic
                         resolved-client
                         (dmx-workspace-annotation-write-plan-payload plan)))
                       (:update
                        (dmx-import-update-topic
                         resolved-client
                         (dmx-workspace-annotation-write-plan-existing-topic
                          plan)
                         (dmx-workspace-annotation-write-plan-payload
                          plan)))))))
            (setf topic-id* (dmx-import-object-id topic)
                  persisted-topic-id topic-id*)
            (if (eql (dmx-workspace-annotation-write-plan-workspace-action plan)
                     :assign)
                (run-stage
                 :workspace-assignment
                 (format nil
                         "Assigned topic ~D to workspace ~D."
                         topic-id*
                         (dmx-workspace-annotation-write-plan-workspace-id plan))
                 (lambda ()
                   (dmx-import-assign-topic-to-workspace
                    resolved-client
                    (dmx-workspace-annotation-write-plan-workspace-id plan)
                    topic-id*)))
                (record-stage
                 :workspace-assignment
                 :skipped
                 "Workspace assignment was already current; no additional write was needed."))
            (if (eql (dmx-workspace-annotation-write-plan-topicmap-action plan)
                     :add)
                (run-stage
                 :topicmap-placement
                 (format nil
                         "Added topic ~D to workspace topicmap ~D."
                         topic-id*
                         resolved-topicmap-id)
                 (lambda ()
                   (dmx-import-add-topic-to-topicmap
                    resolved-client
                    resolved-topicmap-id
                    topic-id*
                    (dmx-workspace-annotation-write-plan-view-props plan))))
                (record-stage
                 :topicmap-placement
                 :skipped
                 "Topicmap placement was already present; no add-to-topicmap write was needed."))
            (setf after-topic (dmx-import-read-topic resolved-client topic-id*)
                  after-state
                  (dmx-workspace-journal-live-snapshot
                   resolved-client
                   after-topic
                   resolved-topicmap-id))
            (setf journal-events
                  (run-stage
                   :journal-transition
                   "Recorded the workspace journal transition for the live annotation write."
                   (lambda ()
                     (dmx-workspace-journal-record-transition
                      resolved-client
                      previous-state
                      after-state
                      resolved-topicmap-id))))
            (setf raw-result
                  (append (dmx-workspace-annotation-plan-summary plan)
                          (list :dry-run nil
                                :topic-id topic-id*
                                :journal-subject-key subject-key
                                :journal-event-count (length journal-events))))
            (setf persisted-annotation
                  (run-stage
                   :reopen-persisted-annotation
                   (format nil
                           "Reopened persisted annotation topic ~D as workspace-dock-annotation."
                           topic-id*)
                   (lambda ()
                     (read-dmx-workspace-annotation
                      :topic-id topic-id*
                      :workspace-topicmap-id resolved-topicmap-id
                      :client resolved-client)))))
        (error (condition)
          (setf failure-condition (or failure-condition condition))))
      (let ((report
              (make-instance
               'workspace-annotation-persistence-report
               :annotation annotation
               :workspace-topicmap-id resolved-topicmap-id
               :workspace-id workspace-id
               :client client
               :exact-form
               (workspace-annotation-persistence-debug-exact-form-of debug)
               :stepper-source
               (workspace-annotation-persistence-debug-stepper-source-of debug)
               :dry-run-preview
               (workspace-annotation-persistence-debug-dry-run-preview-of debug)
               :annotation-key
               (workspace-annotation-persistence-debug-annotation-key-of debug)
               :runtime-relation-id
               (workspace-annotation-persistence-debug-runtime-relation-id-of
                debug)
               :stage-results (nreverse stage-results)
               :report-status (if failure-stage :failed :persisted)
               :failure-stage failure-stage
               :condition failure-condition
               :raw-result raw-result
               :persisted-topic-id persisted-topic-id
               :persisted-annotation persisted-annotation)))
        (setf (workspace-annotation-persistence-debug-last-report-of debug)
              report)
        report))))

(defun workspace-annotation-persistence-debug-graph (debug)
  (workspace-annotation-persistence-code-path-graph
   (workspace-annotation-persistence-debug-annotation-of debug)
   (workspace-annotation-persistence-debug-workspace-topicmap-id-of debug)
   :annotation-key
   (workspace-annotation-persistence-debug-annotation-key-of debug)
   :runtime-relation-id
   (workspace-annotation-persistence-debug-runtime-relation-id-of debug)
   :report (workspace-annotation-persistence-debug-last-report-of debug)))

(defun workspace-annotation-persistence-report-graph (report)
  (workspace-annotation-persistence-code-path-graph
   (workspace-annotation-persistence-report-annotation-of report)
   (workspace-annotation-persistence-report-workspace-topicmap-id-of report)
   :annotation-key
   (workspace-annotation-persistence-report-annotation-key-of report)
   :runtime-relation-id
   (workspace-annotation-persistence-report-runtime-relation-id-of report)
   :report report))

(defun dmx-workspace-annotation-child-json (topic child-type-uri)
  (let ((json-string (dmx-json-child-value topic child-type-uri)))
    (and (dmx-non-empty-string-p json-string)
         (with-input-from-string (stream json-string)
           (shasht:read-json stream)))))

(defun dmx-workspace-annotation-binding-topic-id (binding)
  (let* ((player (and binding (gethash "player2" binding)))
         (ref-kind (and player (gethash "refKind" player)))
         (ref-value (and player (gethash "refValue" player))))
    (when (and (string= (or ref-kind "") "topic-id")
               ref-value)
      (or (parse-positive-integer ref-value)
          (and (integerp ref-value) ref-value)))))

(defun dmx-workspace-annotation-target-object (target-object-ref)
  (let ((annotation-topic (annotation-topic)))
    (if (string= (or target-object-ref "")
                 (dmx-workspace-annotation-ref-string annotation-topic))
        annotation-topic
        target-object-ref)))

(defun read-dmx-workspace-annotation
    (&key topic-id client workspace-topicmap-id)
  (let* ((resolved-topic-id
           (dmx-workspace-annotation-topic-id
            topic-id
            :topic-id
            'read-dmx-workspace-annotation
            :required? t))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (topic (dmx-import-read-topic resolved-client resolved-topic-id)))
    (unless topic
      (error 'fedwiki-dmx-import-error
             :message (format nil "Unknown DMX annotation topic ~D"
                              resolved-topic-id)))
    (unless (string= (or (dmx-json-object-value topic "typeUri") "")
                     *dmx-workspace-annotation-type-uri*)
      (error 'fedwiki-dmx-import-error
             :message (format nil
                              "DMX annotation reopen requires ~A but topic ~D is ~A"
                              *dmx-workspace-annotation-type-uri*
                              resolved-topic-id
                              (dmx-json-object-value topic "typeUri"))))
    (let* ((source-anchor-json
             (dmx-json-child-value topic
                                   *dmx-workspace-annotation-source-anchor-json-type-uri*))
           (target-anchor-json
             (dmx-json-child-value topic
                                   *dmx-workspace-annotation-target-anchor-json-type-uri*))
           (source-anchor
             (make-dom-annotation-anchor-from-json
              (or (parse-dom-annotation-json source-anchor-json)
                  (error "Missing source anchor JSON for annotation topic ~D"
                         resolved-topic-id))))
           (target-anchor
             (make-dom-annotation-anchor-from-json
              (or (parse-dom-annotation-json target-anchor-json)
                  (error "Missing target anchor JSON for annotation topic ~D"
                         resolved-topic-id))))
           (workspace
             (dmx-import-read-topic-workspace resolved-client resolved-topic-id))
           (source-binding
             (dmx-workspace-annotation-child-json
              topic
              *dmx-workspace-annotation-source-binding-type-uri*))
           (target-binding
             (dmx-workspace-annotation-child-json
              topic
              *dmx-workspace-annotation-target-binding-type-uri*))
           (context-binding
             (dmx-workspace-annotation-child-json
              topic
              *dmx-workspace-annotation-context-binding-type-uri*))
           (supersedes-binding
             (dmx-workspace-annotation-child-json
              topic
              *dmx-workspace-annotation-supersedes-type-uri*))
           (source-object-ref
             (dmx-json-child-value topic
                                   *dmx-workspace-annotation-source-object-ref-type-uri*))
           (target-object-ref
             (dmx-json-child-value topic
                                   *dmx-workspace-annotation-target-object-ref-type-uri*))
           (runtime-relation-id
             (dmx-json-child-value topic
                                   *dmx-workspace-annotation-runtime-relation-id-type-uri*)))
      (make-instance
       'workspace-dock-annotation
       :id (format nil "workspace-annotation/~D" resolved-topic-id)
       :title (dmx-workspace-annotation-topic-title topic)
       :summary (or (dmx-json-child-value topic
                                          *dmx-workspace-annotation-summary-type-uri*)
                    (dmx-json-object-value topic "value"))
       :context-object
       (dmx-json-child-value topic
                             *dmx-workspace-annotation-context-object-id-type-uri*)
       :context-view-title
       (dmx-json-child-value topic
                             *dmx-workspace-annotation-context-view-title-type-uri*)
       :source-anchor source-anchor
       :target-anchor target-anchor
       :source-object source-object-ref
       :target-object (dmx-workspace-annotation-target-object target-object-ref)
       :relation-kind (dmx-json-child-value topic
                                            *dmx-workspace-annotation-relation-kind-type-uri*)
       :note (dmx-json-child-value topic
                                   *dmx-workspace-annotation-text-type-uri*)
       :matching-patch-target nil
       :matching-defect nil
       :matching-inserted-step nil
       :registry-key runtime-relation-id
       :dock-capability "Annotation"
       :workspace-topic-id resolved-topic-id
       :workspace-topic-uri (or (dmx-json-object-value topic "uri") "")
       :workspace-topicmap-id resolved-topicmap-id
       :workspace-id (dmx-import-object-id workspace)
       :annotation-key
       (let ((uri (or (dmx-json-object-value topic "uri") "")))
         (if (dmx-string-prefix-p *hyperdoc-workspace-annotation-uri-prefix* uri)
             (subseq uri (length *hyperdoc-workspace-annotation-uri-prefix*))
             nil))
       :workspace-status
       (dmx-json-child-value topic *dmx-workspace-annotation-status-type-uri*)
       :source-anchor-json source-anchor-json
       :target-anchor-json target-anchor-json
       :source-object-ref source-object-ref
       :target-object-ref target-object-ref
       :runtime-relation-id runtime-relation-id
       :provenance-json
       (dmx-json-child-value topic *dmx-workspace-annotation-provenance-type-uri*)
       :source-binding source-binding
       :target-binding target-binding
       :context-binding context-binding
       :supersedes-binding supersedes-binding
       :supersedes-topic-id
       (dmx-workspace-annotation-binding-topic-id supersedes-binding)))))

(defun persist-dock-annotation-to-workspace
    (annotation &key workspace-topicmap-id workspace-id client view-props
       status supersedes-topic-id annotation-key provenance-json
       (dry-run t))
  (let ((result
          (execute-dmx-workspace-annotation-write-from-object
           annotation
           :workspace-topicmap-id workspace-topicmap-id
           :workspace-id workspace-id
           :client client
           :view-props view-props
           :status status
           :supersedes-topic-id supersedes-topic-id
           :annotation-key annotation-key
           :provenance-json provenance-json
           :dry-run dry-run)))
    (if dry-run
        result
        (read-dmx-workspace-annotation
         :topic-id (getf result :topic-id)
         :workspace-topicmap-id
         (or workspace-topicmap-id *dmx-context-window-topicmap-id*)
         :client (or client
                     (make-default-dmx-import-client :dry-run nil :verbose nil))))))

(defun supersede-dock-annotation-in-workspace
    (annotation supersedes-topic-id
     &key workspace-topicmap-id workspace-id client view-props
       status annotation-key provenance-json (dry-run t))
  (persist-dock-annotation-to-workspace
   annotation
   :workspace-topicmap-id workspace-topicmap-id
   :workspace-id workspace-id
   :client client
   :view-props view-props
   :status (or status "superseding")
   :supersedes-topic-id supersedes-topic-id
   :annotation-key annotation-key
   :provenance-json provenance-json
   :dry-run dry-run))
