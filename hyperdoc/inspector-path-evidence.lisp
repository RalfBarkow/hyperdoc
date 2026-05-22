;;;; Inspectable inspector path evidence persisted as topics and associations.

(in-package :hyperdoc)

(defclass path-topic ()
  ((topic-id :initarg :topic-id :reader path-topic-id-of)
   (topic-type :initarg :topic-type :reader path-topic-type-of)
   (title :initarg :title :reader path-topic-title-of)
   (value :initarg :value :initform nil :reader path-topic-value-of)
   (created-at :initarg :created-at :initform nil
               :reader path-topic-created-at-of)
   (updated-at :initarg :updated-at :initform nil
               :reader path-topic-updated-at-of)
   (provenance :initarg :provenance :initform :codex
               :reader path-topic-provenance-of)))

(defclass path-association ()
  ((association-id :initarg :association-id
                   :reader path-association-id-of)
   (association-type :initarg :association-type
                     :reader path-association-type-of)
   (from-topic-id :initarg :from-topic-id
                  :reader path-association-from-topic-id-of)
   (to-topic-id :initarg :to-topic-id
                :reader path-association-to-topic-id-of)
   (role-1 :initarg :role-1 :initform "player1"
           :reader path-association-role-1-of)
   (role-2 :initarg :role-2 :initform "player2"
           :reader path-association-role-2-of)
   (properties :initarg :properties :initform nil
               :reader path-association-properties-of)
   (created-at :initarg :created-at :initform nil
               :reader path-association-created-at-of)
   (provenance :initarg :provenance :initform :codex
               :reader path-association-provenance-of)))

(defclass inspector-path-step ()
  ((step-id :initarg :step-id :reader inspector-path-step-id-of)
   (index :initarg :index :reader inspector-path-step-index-of)
   (path-name :initarg :path-name :reader inspector-path-step-path-name-of)
   (phase :initarg :phase :reader inspector-path-step-phase-of)
   (action :initarg :action :initform nil
           :reader inspector-path-step-action-of)
   (object-type :initarg :object-type :initform nil
                :reader inspector-path-step-object-type-of)
   (object-identity :initarg :object-identity :initform nil
                    :reader inspector-path-step-object-identity-of)
   (entry-function :initarg :entry-function :initform nil
                   :reader inspector-path-step-entry-function-of)
   (generic-function :initarg :generic-function :initform nil
                     :reader inspector-path-step-generic-function-of)
   (selected-methods :initarg :selected-methods :initform nil
                     :reader inspector-path-step-selected-methods-of)
   (scxml-record :initarg :scxml-record :initform nil
                 :reader inspector-path-step-scxml-record-of)
   (view-titles :initarg :view-titles :initform nil
                :reader inspector-path-step-view-titles-of)
   (dom-labels :initarg :dom-labels :initform nil
               :reader inspector-path-step-dom-labels-of)
   (result :initarg :result :initform nil
           :reader inspector-path-step-result-of)
   (details :initarg :details :initform nil
            :reader inspector-path-step-details-of)
   (topic :initarg :topic :initform nil
          :accessor inspector-path-step-topic-of)))

(defclass inspector-path-trace ()
  ((trace-id :initarg :trace-id :reader inspector-path-trace-id-of)
   (path-name :initarg :path-name :reader inspector-path-trace-path-name-of)
   (object :initarg :object :initform nil
           :reader inspector-path-trace-object-of)
   (object-type :initarg :object-type :initform nil
                :reader inspector-path-trace-object-type-of)
   (object-identity :initarg :object-identity :initform nil
                    :reader inspector-path-trace-object-identity-of)
   (entry-function :initarg :entry-function :initform nil
                   :reader inspector-path-trace-entry-function-of)
   (steps :initarg :steps :initform nil
          :accessor inspector-path-trace-steps-of)
   (result :initarg :result :initform :unknown
           :accessor inspector-path-trace-result-of)
   (store :initarg :store :initform nil
          :accessor inspector-path-trace-store-of)
   (topics :initarg :topics :initform nil
           :accessor inspector-path-trace-topics-of)
   (associations :initarg :associations :initform nil
                 :accessor inspector-path-trace-associations-of)
   (created-at :initarg :created-at :initform nil
               :reader inspector-path-trace-created-at-of)
   (provenance :initarg :provenance :initform :codex
               :reader inspector-path-trace-provenance-of)))

(defclass inspector-path-comparison ()
  ((comparison-id :initarg :comparison-id
                  :reader inspector-path-comparison-id-of)
   (object :initarg :object :initform nil
           :reader inspector-path-comparison-object-of)
   (traces :initarg :traces :initform nil
           :reader inspector-path-comparison-traces-of)
   (equivalent-p :initarg :equivalent-p :initform nil
                 :reader inspector-path-comparison-equivalent-p-of)
   (first-divergence :initarg :first-divergence :initform nil
                     :reader inspector-path-comparison-first-divergence-of)
   (store :initarg :store :initform nil
          :accessor inspector-path-comparison-store-of)
   (topics :initarg :topics :initform nil
           :accessor inspector-path-comparison-topics-of)
   (associations :initarg :associations :initform nil
                 :accessor inspector-path-comparison-associations-of)
   (created-at :initarg :created-at :initform nil
               :reader inspector-path-comparison-created-at-of)))

(defclass inspector-path-sqlite-store ()
  ((db-path :initarg :db-path :reader inspector-path-sqlite-store-db-path-of)
   (sqlite-program :initarg :sqlite-program :initform "sqlite3"
                   :reader inspector-path-sqlite-store-program-of)
   (schema-status :initarg :schema-status :initform :unknown
                  :accessor inspector-path-sqlite-store-schema-status-of)))

(defparameter *inspector-path-store* nil)
(defparameter *default-inspector-path-store* nil)
(defparameter *last-example-source-artifact-inspector-path-trace* nil)

(defun default-inspector-path-sqlite-path ()
  (merge-pathnames #P"hyperdoc/inspector-path-evidence.sqlite"
                   (merge-pathnames #P".cache/" (user-homedir-pathname))))

(defun make-inspector-path-sqlite-store
    (&key (db-path (default-inspector-path-sqlite-path))
       (sqlite-program "sqlite3"))
  (make-instance 'inspector-path-sqlite-store
                 :db-path (etypecase db-path
                            (pathname db-path)
                            (string (pathname db-path)))
                 :sqlite-program sqlite-program))

(defun default-inspector-path-store ()
  (or *default-inspector-path-store*
      (setf *default-inspector-path-store*
            (make-inspector-path-sqlite-store))))

(defun current-inspector-path-store ()
  (or *inspector-path-store*
      (default-inspector-path-store)))

(defun inspector-path-sqlite-run (store sql &key json-p)
  (let ((source-store
          (make-example-source-sqlite-store
           :db-path (inspector-path-sqlite-store-db-path-of store)
           :sqlite-program (inspector-path-sqlite-store-program-of store))))
    (example-source-sqlite-run source-store sql :json-p json-p)))

(defun inspector-path-json-string (value)
  (with-output-to-string (stream)
    (let ((shasht:*write-alist-as-object* t))
      (shasht:write-json value stream))))

(defun inspector-path->json-value (value)
  (cond
    ((null value) nil)
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value) (format nil "~A" value))
    ((pathnamep value) (namestring value))
    ((listp value) (mapcar #'inspector-path->json-value value))
    ((vectorp value) (map 'list #'inspector-path->json-value value))
    (t (format nil "~A" value))))

(defun inspector-path-plist->alist (plist)
  (loop for (key value) on plist by #'cddr
        collect (cons (string-downcase (symbol-name key))
                      (inspector-path->json-value value))))

(defun inspector-path-topic-value-json (plist)
  (inspector-path-json-string (inspector-path-plist->alist plist)))

(defun inspector-path-store-schema-sql ()
  "CREATE TABLE IF NOT EXISTS path_topics(
    topic_id text primary key,
    topic_type text not null,
    title text not null,
    value_json text,
    created_at text not null,
    updated_at text not null,
    provenance text
  );

  CREATE TABLE IF NOT EXISTS path_associations(
    association_id text primary key,
    association_type text not null,
    from_topic_id text not null,
    to_topic_id text not null,
    role_1 text,
    role_2 text,
    properties_json text,
    created_at text not null,
    provenance text
  );

  CREATE INDEX IF NOT EXISTS path_associations_from_idx
    ON path_associations(from_topic_id);

  CREATE INDEX IF NOT EXISTS path_associations_to_idx
    ON path_associations(to_topic_id);")

(defun ensure-inspector-path-store-schema
    (&optional (store (current-inspector-path-store)))
  (multiple-value-bind (output status detail)
      (inspector-path-sqlite-run store (inspector-path-store-schema-sql))
    (declare (ignore output))
    (if (eq status :ok)
        (progn
          (setf (inspector-path-sqlite-store-schema-status-of store) :ready)
          (values store :ok nil))
        (progn
          (setf (inspector-path-sqlite-store-schema-status-of store) status)
          (values nil status detail)))))

(defun inspector-path-object-type (object)
  (if object
      (let ((class (class-of object)))
        (format nil "~A" (class-name class)))
      "n/a"))

(defun inspector-path-object-identity (object)
  (cond
    ((typep object 'example-source-artifact)
     (example-source-artifact-source-id-of object))
    ((typep object 'example-source-reference)
     (example-entry-id-of (example-source-reference-entry-of object)))
    ((typep object 'example-result)
     (example-entry-id-of (example-result-entry-of object)))
    ((typep object 'example-entry)
     (example-entry-id-of object))
    (object
     (with-output-to-string (stream)
       (let ((*print-pretty* nil)
             (*print-circle* t))
         (prin1 object stream))))
    (t "n/a")))

(defun inspector-path-safe-id (value)
  (example-source-safe-id-component value))

(defun inspector-path-run-id ()
  (format nil "~36R" (get-universal-time)))

(defun make-inspector-path-step
    (path-name index phase &rest initargs)
  (apply #'make-instance
         'inspector-path-step
         :step-id (format nil "path-step:~A:~3,'0D:~A"
                          (inspector-path-safe-id path-name)
                          index
                          (inspector-path-safe-id phase))
         :path-name path-name
         :index index
         :phase phase
         initargs))

(defun make-inspector-path-trace
    (&key path-name object entry-function steps
       (result :unknown)
       (trace-id (format nil "path-trace:~A:~A"
                         (inspector-path-safe-id path-name)
                         (inspector-path-run-id)))
       (created-at (example-source-now-string))
       (provenance :codex))
  (make-instance 'inspector-path-trace
                 :trace-id trace-id
                 :path-name path-name
                 :object object
                 :object-type (inspector-path-object-type object)
                 :object-identity (inspector-path-object-identity object)
                 :entry-function entry-function
                 :steps steps
                 :result result
                 :created-at created-at
                 :provenance provenance))

(defun inspector-path-topic-for-trace (trace)
  (let ((now (or (inspector-path-trace-created-at-of trace)
                 (example-source-now-string))))
    (make-instance
     'path-topic
     :topic-id (inspector-path-trace-id-of trace)
     :topic-type "hyperdoc.path.trace"
     :title (format nil "Inspector path trace: ~A"
                    (inspector-path-trace-path-name-of trace))
     :value (list :path-name (inspector-path-trace-path-name-of trace)
                  :object-type (inspector-path-trace-object-type-of trace)
                  :object-identity
                  (inspector-path-trace-object-identity-of trace)
                  :entry-function
                  (inspector-path-trace-entry-function-of trace)
                  :result (inspector-path-trace-result-of trace))
     :created-at now
     :updated-at now
     :provenance (inspector-path-trace-provenance-of trace))))

(defun inspector-path-topic-for-step (trace step)
  (let ((now (example-source-now-string)))
    (make-instance
     'path-topic
     :topic-id (format nil "~A:~A"
                       (inspector-path-trace-id-of trace)
                       (inspector-path-step-id-of step))
     :topic-type "hyperdoc.path.step"
     :title (format nil "~A #~D ~A"
                    (inspector-path-step-path-name-of step)
                    (inspector-path-step-index-of step)
                    (inspector-path-step-phase-of step))
     :value (list :index (inspector-path-step-index-of step)
                  :phase (inspector-path-step-phase-of step)
                  :action (inspector-path-step-action-of step)
                  :object-type (inspector-path-step-object-type-of step)
                  :object-identity
                  (inspector-path-step-object-identity-of step)
                  :entry-function
                  (inspector-path-step-entry-function-of step)
                  :generic-function
                  (inspector-path-step-generic-function-of step)
                  :selected-methods
                  (inspector-path-step-selected-methods-of step)
                  :scxml-record
                  (inspector-path-step-scxml-record-of step)
                  :view-titles (inspector-path-step-view-titles-of step)
                  :dom-labels (inspector-path-step-dom-labels-of step)
                  :result (inspector-path-step-result-of step)
                  :details (inspector-path-step-details-of step))
     :created-at now
     :updated-at now
     :provenance (inspector-path-trace-provenance-of trace))))

(defun inspector-path-association
    (id type from to &key (role-1 "player1") (role-2 "player2")
       properties (provenance :codex))
  (make-instance 'path-association
                 :association-id id
                 :association-type type
                 :from-topic-id from
                 :to-topic-id to
                 :role-1 role-1
                 :role-2 role-2
                 :properties properties
                 :created-at (example-source-now-string)
                 :provenance provenance))

(defun inspector-path-upsert-topic-sql (topic)
  (let ((now (or (path-topic-updated-at-of topic)
                 (example-source-now-string)))
        (value-json (inspector-path-topic-value-json
                     (path-topic-value-of topic))))
    (format nil
            "INSERT INTO path_topics(topic_id, topic_type, title, value_json,
                                     created_at, updated_at, provenance)
             VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A)
             ON CONFLICT(topic_id) DO UPDATE SET
               topic_type = excluded.topic_type,
               title = excluded.title,
               value_json = excluded.value_json,
               updated_at = excluded.updated_at,
               provenance = excluded.provenance;"
            (example-source-sqlite-string-literal
             (path-topic-id-of topic))
            (example-source-sqlite-string-literal
             (path-topic-type-of topic))
            (example-source-sqlite-string-literal
             (path-topic-title-of topic))
            (example-source-sqlite-string-literal value-json)
            (example-source-sqlite-string-literal
             (or (path-topic-created-at-of topic) now))
            (example-source-sqlite-string-literal now)
            (example-source-sqlite-string-literal
             (example-source-keyword-label
              (path-topic-provenance-of topic))))))

(defun inspector-path-upsert-association-sql (association)
  (format nil
          "INSERT INTO path_associations(
             association_id, association_type, from_topic_id, to_topic_id,
             role_1, role_2, properties_json, created_at, provenance)
           VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A)
           ON CONFLICT(association_id) DO UPDATE SET
             association_type = excluded.association_type,
             from_topic_id = excluded.from_topic_id,
             to_topic_id = excluded.to_topic_id,
             role_1 = excluded.role_1,
             role_2 = excluded.role_2,
             properties_json = excluded.properties_json,
             provenance = excluded.provenance;"
          (example-source-sqlite-string-literal
           (path-association-id-of association))
          (example-source-sqlite-string-literal
           (path-association-type-of association))
          (example-source-sqlite-string-literal
           (path-association-from-topic-id-of association))
          (example-source-sqlite-string-literal
           (path-association-to-topic-id-of association))
          (example-source-sqlite-string-literal
           (path-association-role-1-of association))
          (example-source-sqlite-string-literal
           (path-association-role-2-of association))
          (example-source-sqlite-string-literal
           (inspector-path-topic-value-json
            (path-association-properties-of association)))
          (example-source-sqlite-string-literal
           (or (path-association-created-at-of association)
               (example-source-now-string)))
          (example-source-sqlite-string-literal
           (example-source-keyword-label
            (path-association-provenance-of association)))))

(defun persist-path-topic (store topic)
  (multiple-value-bind (output status detail)
      (inspector-path-sqlite-run store
                                 (inspector-path-upsert-topic-sql topic))
    (declare (ignore output))
    (values topic status detail)))

(defun persist-path-association (store association)
  (multiple-value-bind (output status detail)
      (inspector-path-sqlite-run
       store
       (inspector-path-upsert-association-sql association))
    (declare (ignore output))
    (values association status detail)))

(defun persist-inspector-path-trace
    (trace &key (store (current-inspector-path-store)))
  (multiple-value-bind (schema schema-status schema-detail)
      (ensure-inspector-path-store-schema store)
    (declare (ignore schema))
    (unless (eq schema-status :ok)
      (setf (inspector-path-trace-result-of trace) schema-status)
      (return-from persist-inspector-path-trace
        (values trace schema-status schema-detail))))
  (let* ((trace-topic (inspector-path-topic-for-trace trace))
         (step-topics
           (loop for step in (inspector-path-trace-steps-of trace)
                 for topic = (inspector-path-topic-for-step trace step)
                 do (setf (inspector-path-step-topic-of step) topic)
                 collect topic))
         (associations
           (append
            (loop for topic in step-topics
                  for index from 0
                  collect
                  (inspector-path-association
                   (format nil "~A:contains-step:~D"
                           (path-topic-id-of trace-topic)
                           index)
                   "hyperdoc.path.contains-step"
                   (path-topic-id-of trace-topic)
                   (path-topic-id-of topic)
                   :role-1 "trace"
                   :role-2 "step"
                   :properties (list :index index)
                   :provenance
                   (inspector-path-trace-provenance-of trace)))
            (loop for previous in step-topics
                  for next in (rest step-topics)
                  for index from 0
                  collect
                  (inspector-path-association
                   (format nil "~A:next-step:~D"
                           (path-topic-id-of trace-topic)
                           index)
                   "hyperdoc.path.next-step"
                   (path-topic-id-of previous)
                   (path-topic-id-of next)
                   :role-1 "previous"
                   :role-2 "next"
                   :properties (list :index index)
                   :provenance
                   (inspector-path-trace-provenance-of trace))))))
    (dolist (topic (cons trace-topic step-topics))
      (persist-path-topic store topic))
    (dolist (association associations)
      (persist-path-association store association))
    (setf (inspector-path-trace-store-of trace) store
          (inspector-path-trace-topics-of trace) (cons trace-topic step-topics)
          (inspector-path-trace-associations-of trace) associations)
    (values trace :ok nil)))

(defun inspector-path-call (package-name function-name &rest arguments)
  (let* ((package (find-package package-name))
         (symbol (and package (find-symbol function-name package))))
    (when (and symbol (fboundp symbol))
      (apply (symbol-function symbol) arguments))))

(defun inspector-path-symbol (package-name symbol-name)
  (let ((package (find-package package-name)))
    (and package (find-symbol symbol-name package))))

(defun inspector-path-visible-label (value)
  (let ((string (format nil "~A" (or value ""))))
    (with-output-to-string (stream)
      (loop with inside-tag-p = nil
            for character across string
            do (cond
                 ((char= character #\<)
                  (setf inside-tag-p t))
                 ((char= character #\>)
                  (setf inside-tag-p nil))
                 ((not inside-tag-p)
                  (write-char character stream)))))))

(defun inspector-path-view-title (view)
  (inspector-path-visible-label
   (or (inspector-path-call "HTML-INSPECTOR-VIEWS" "VIEW-TITLE" view)
       (inspector-path-call "HTML-INSPECTOR-VIEWS" "VIEW-TITLE-OF" view)
       (ignore-errors
         (when-let (title-slot
                     (inspector-path-symbol "HTML-INSPECTOR-VIEWS" "TITLE"))
           (slot-value view title-slot)))
       "n/a")))

(defun inspector-path-view-titles (views)
  (mapcar #'inspector-path-view-title views))

(defun inspector-path-selected-methods (generic-function object)
  (let* ((symbol
           (and generic-function
                (symbolp generic-function)
                generic-function))
         (function (and symbol (fboundp symbol) (symbol-function symbol))))
    (when (and function (typep function 'generic-function))
      (mapcar
       (lambda (method)
         (with-output-to-string (stream)
           (prin1 method stream)))
       (ignore-errors
         (compute-applicable-methods function (list object)))))))

(defun trace-example-source-artifact-model-view-path (artifact)
  (let* ((path-name "model/html-inspector-views:all-views")
         (views (or (inspector-path-call "HTML-INSPECTOR-VIEWS"
                                         "ALL-VIEWS"
                                         artifact)
                    '()))
         (titles (inspector-path-view-titles views))
         (steps
           (list
            (make-inspector-path-step
             path-name 0 "entry"
             :object-type (inspector-path-object-type artifact)
             :object-identity (inspector-path-object-identity artifact)
             :generic-function "html-inspector-views:all-views"
             :selected-methods
             (inspector-path-selected-methods
              (inspector-path-symbol "HTML-INSPECTOR-VIEWS" "ALL-VIEWS")
              artifact))
            (make-inspector-path-step
             path-name 1 "final-view-titles"
             :view-titles titles
             :result :rendered))))
    (make-inspector-path-trace :path-name path-name
                               :object artifact
                               :entry-function "html-inspector-views:all-views"
                               :steps steps
                               :result :ok)))

(defun trace-example-source-artifact-synthetic-clog-path (artifact)
  (let* ((path-name "synthetic/clog-moldable-inspector::load-views")
         (pane-class (find-class
                      (inspector-path-symbol "CLOG-MOLDABLE-INSPECTOR" "PANE")
                      nil))
         (views nil)
         (status :unavailable)
         (detail nil))
    (when pane-class
      (handler-case
          (let ((pane (make-instance pane-class :inspector nil
                                     :object artifact)))
            (inspector-path-call "CLOG-MOLDABLE-INSPECTOR" "LOAD-VIEWS"
                                 pane)
            (setf views
                  (slot-value
                   pane
                   (inspector-path-symbol "CLOG-MOLDABLE-INSPECTOR"
                                          "VIEWS"))
                  status :ok))
        (error (condition)
          (setf status :error
                detail (princ-to-string condition)))))
    (let* ((titles (inspector-path-view-titles views))
           (steps
             (list
              (make-inspector-path-step
               path-name 0 "make-pane"
               :action "make-instance clog-moldable-inspector::pane"
               :object-type (inspector-path-object-type artifact)
               :object-identity (inspector-path-object-identity artifact))
              (make-inspector-path-step
               path-name 1 "load-views"
               :entry-function "clog-moldable-inspector::load-views"
               :selected-methods
               (inspector-path-selected-methods
                (inspector-path-symbol "CLOG-MOLDABLE-INSPECTOR"
                                       "LOAD-VIEWS")
                (and pane-class
                     (ignore-errors
                       (make-instance pane-class :inspector nil
                                      :object artifact))))
               :result status
               :details detail)
              (make-inspector-path-step
               path-name 2 "final-view-titles"
               :view-titles titles
               :result status))))
      (make-inspector-path-trace :path-name path-name
                                 :object artifact
                                 :entry-function
                                 "clog-moldable-inspector::load-views"
                                 :steps steps
                                 :result status))))

(defun trace-example-source-artifact-scxml-path
    (artifact &optional recorder-events)
  (let* ((path-name "behavior/scxml")
         (events (or recorder-events
                     (inspector-path-call
                      "CLOG-MOLDABLE-INSPECTOR"
                      "INSPECTOR-SCXML-UI-RECORDER-EVENTS")
                     '()))
         (steps
           (loop for event in events
                 for index from 0
                 collect
                 (make-inspector-path-step
                  path-name index
                  (format nil "~(~A~)" (or (getf event :kind) :event))
                  :object-type (inspector-path-object-type artifact)
                  :object-identity (inspector-path-object-identity artifact)
                  :scxml-record event
                  :result (getf event :kind)))))
    (make-inspector-path-trace :path-name path-name
                               :object artifact
                               :entry-function
                               "hyperdoc/example-source-artifact-inspector.scxml"
                               :steps steps
                               :result (if events :ok :empty))))

(defun trace-example-source-artifact-actual-clog-path
    (artifact &key view-titles dom-labels recorder-events
       (entry-function "clog-moldable-inspector:clog-inspect"))
  (let* ((path-name "actual/sly-clog-inspect")
         (steps
           (append
            (list
             (make-inspector-path-step
              path-name 0 "entry"
              :entry-function entry-function
              :object-type (inspector-path-object-type artifact)
              :object-identity (inspector-path-object-identity artifact)
              :action "(i *example-source-artifact*) / fresh CLOG inspect")
             (make-inspector-path-step
              path-name 1 "pane-create-or-reuse"
              :action "clog-moldable-inspector pane creation/reuse"
              :object-type (inspector-path-object-type artifact)
              :object-identity (inspector-path-object-identity artifact))
             (make-inspector-path-step
              path-name 2 "load-views"
              :entry-function "clog-moldable-inspector::load-views"
              :view-titles view-titles
              :result :loaded)
             (make-inspector-path-step
              path-name 3 "create-tabs"
              :entry-function "clog-moldable-inspector::create-tabs"
              :view-titles view-titles
              :dom-labels dom-labels
              :result :rendered))
            (loop for event in recorder-events
                  for index from 4
                  collect
                  (make-inspector-path-step
                   path-name index
                   (format nil "scxml:~(~A~)"
                           (or (getf event :kind) :event))
                   :scxml-record event
                   :result (getf event :kind))))))
    (make-inspector-path-trace :path-name path-name
                               :object artifact
                               :entry-function entry-function
                               :steps steps
                               :result :ok)))

(defun trace-example-source-artifact-playwright-path
    (artifact &key dom-labels recorder-events)
  (let ((path-name "browser/playwright"))
    (make-inspector-path-trace
     :path-name path-name
     :object artifact
     :entry-function "Playwright browser/CLOG inspector route"
     :steps
     (list
      (make-inspector-path-step
       path-name 0 "browser-open"
       :action "open HyperDoc/CLOG inspector page"
       :object-type (inspector-path-object-type artifact)
       :object-identity (inspector-path-object-identity artifact))
      (make-inspector-path-step
       path-name 1 "dom-tab-labels"
       :dom-labels dom-labels
       :result :observed)
      (make-inspector-path-step
       path-name 2 "scxml-recorder"
       :scxml-record recorder-events
       :result (if recorder-events :recorded :empty)))
     :result :ok)))

(defun inspector-path-final-labels (trace)
  (loop for step in (reverse (inspector-path-trace-steps-of trace))
        for dom = (inspector-path-step-dom-labels-of step)
        for views = (inspector-path-step-view-titles-of step)
        when (or dom views)
          return (mapcar #'inspector-path-visible-label (or dom views))))

(defun inspector-path-first-divergence (traces)
  (let* ((labelled-traces
           (remove-if-not #'inspector-path-final-labels traces))
         (reference (first labelled-traces))
         (expected (and reference
                        (inspector-path-final-labels reference))))
    (loop for trace in (rest labelled-traces)
          for labels = (inspector-path-final-labels trace)
          unless (equal expected labels)
            return (list :expected-path
                         (inspector-path-trace-path-name-of reference)
                         :expected-labels expected
                         :actual-path
                         (inspector-path-trace-path-name-of trace)
                         :actual-labels labels
                         :classification :first-visible-label-divergence))))

(defun persist-inspector-path-comparison
    (comparison &key (store (current-inspector-path-store)))
  (dolist (trace (inspector-path-comparison-traces-of comparison))
    (persist-inspector-path-trace trace :store store))
  (let* ((now (or (inspector-path-comparison-created-at-of comparison)
                  (example-source-now-string)))
         (topic
           (make-instance
            'path-topic
            :topic-id (inspector-path-comparison-id-of comparison)
            :topic-type "hyperdoc.path.comparison"
            :title "Inspector path comparison"
            :value (list :equivalent-p
                         (inspector-path-comparison-equivalent-p-of
                          comparison)
                         :first-divergence
                         (inspector-path-comparison-first-divergence-of
                          comparison)
                         :paths
                         (mapcar #'inspector-path-trace-path-name-of
                                 (inspector-path-comparison-traces-of
                                  comparison)))
            :created-at now
            :updated-at now
            :provenance :codex))
         (associations
           (loop for trace in (inspector-path-comparison-traces-of comparison)
                 for index from 0
                 collect
                 (inspector-path-association
                  (format nil "~A:compares:~D"
                          (inspector-path-comparison-id-of comparison)
                          index)
                  "hyperdoc.path.compares"
                  (inspector-path-comparison-id-of comparison)
                  (inspector-path-trace-id-of trace)
                  :role-1 "comparison"
                  :role-2 "trace"
                  :properties (list :index index)))))
    (ensure-inspector-path-store-schema store)
    (persist-path-topic store topic)
    (dolist (association associations)
      (persist-path-association store association))
    (setf (inspector-path-comparison-store-of comparison) store
          (inspector-path-comparison-topics-of comparison) (list topic)
          (inspector-path-comparison-associations-of comparison)
          associations)
    (values comparison :ok nil)))

(defun record-example-source-artifact-clog-pane-path
    (artifact view-titles &key dom-labels recorder-events)
  (when (typep artifact 'example-source-artifact)
    (let ((trace
            (trace-example-source-artifact-actual-clog-path
             artifact
             :view-titles view-titles
             :dom-labels (or dom-labels view-titles)
             :recorder-events recorder-events)))
      (multiple-value-bind (persisted status detail)
          (persist-inspector-path-trace trace)
        (declare (ignore status detail))
        (setf *last-example-source-artifact-inspector-path-trace*
              persisted)
        persisted))))

(defun trace-and-persist-example-source-artifact-inspector-path
    (artifact &key (store (current-inspector-path-store)))
  (let* ((last *last-example-source-artifact-inspector-path-trace*)
         (trace (if (and last
                         (equal (inspector-path-object-identity artifact)
                                (inspector-path-trace-object-identity-of last)))
                    last
                    (trace-example-source-artifact-synthetic-clog-path
                     artifact))))
    (persist-inspector-path-trace trace :store store)
    trace))

(defun compare-and-persist-example-source-artifact-inspector-paths
    (artifact &key (store (current-inspector-path-store)))
  (let* ((model (trace-example-source-artifact-model-view-path artifact))
         (synthetic (trace-example-source-artifact-synthetic-clog-path
                     artifact))
         (actual (or (and *last-example-source-artifact-inspector-path-trace*
                          (equal (inspector-path-object-identity artifact)
                                 (inspector-path-trace-object-identity-of
                                  *last-example-source-artifact-inspector-path-trace*))
                          *last-example-source-artifact-inspector-path-trace*)
                     (trace-example-source-artifact-actual-clog-path
                      artifact
                      :view-titles (inspector-path-final-labels synthetic)
                      :dom-labels nil
                      :recorder-events nil)))
         (scxml (trace-example-source-artifact-scxml-path artifact))
         (traces (list model synthetic actual scxml))
         (divergence (inspector-path-first-divergence traces))
         (comparison
           (make-instance
            'inspector-path-comparison
            :comparison-id
            (format nil "path-comparison:example-source-artifact:~A"
                    (inspector-path-run-id))
            :object artifact
            :traces traces
            :equivalent-p (null divergence)
            :first-divergence divergence
            :store store
            :created-at (example-source-now-string))))
    (persist-inspector-path-comparison comparison :store store)
    comparison))

(defmethod title-of ((trace inspector-path-trace))
  (format nil "Inspector path trace: ~A"
          (inspector-path-trace-path-name-of trace)))

(defmethod summary-of ((trace inspector-path-trace))
  (format nil "~D steps for ~A"
          (length (inspector-path-trace-steps-of trace))
          (inspector-path-trace-object-identity-of trace)))

(defmethod title-of ((comparison inspector-path-comparison))
  "Inspector path comparison")

(defmethod summary-of ((comparison inspector-path-comparison))
  (if (inspector-path-comparison-equivalent-p-of comparison)
      "Compared inspector paths are equivalent at the recorded labels."
      "Compared inspector paths diverge; inspect the Divergence view."))
