;;;; Optional SQLite persistence for Kioskbeerli local demo state.

(in-package :kioskbeerli)

(define-condition kioskbeerli-sqlite-unavailable (error)
  ((program :reader sqlite-unavailable-program-of
            :initarg :program)
   (detail :reader sqlite-unavailable-detail-of
           :initarg :detail))
  (:report (lambda (condition stream)
             (format stream
                     "Kioskbeerli SQLite support is unavailable through ~S: ~A"
                     (sqlite-unavailable-program-of condition)
                     (sqlite-unavailable-detail-of condition)))))

(defclass kioskbeerli-sqlite-store ()
  ((db-path :reader sqlite-store-db-path-of :initarg :db-path)
   (sqlite-program :reader sqlite-store-program-of
                   :initarg :sqlite-program
                   :initform "sqlite3")
   (schema-status :accessor sqlite-store-schema-status-of
                  :initarg :schema-status
                  :initform :unknown)))

(defmethod print-object ((store kioskbeerli-sqlite-store) stream)
  (print-unreadable-object (store stream :type t :identity nil)
    (format stream "~A ~A"
            (sqlite-store-schema-status-of store)
            (sqlite-store-db-path-of store))))

(defun kioskbeerli-sqlite-blank-string-p (value)
  (or (null value)
      (and (stringp value)
           (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       value))))))

(defun kioskbeerli-sqlite-string-literal (value)
  (if (null value)
      "NULL"
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for char across (format nil "~A" value)
                      do (if (char= char #\')
                             (write-string "''" stream)
                             (write-char char stream)))))))

(defun kioskbeerli-sqlite-integer-literal (value)
  (if value
      (format nil "~D" value)
      "NULL"))

(defun sqlite-available-p (&key (sqlite-program "sqlite3"))
  (and (not (kioskbeerli-sqlite-blank-string-p sqlite-program))
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program (list sqlite-program "--version")
                                 :output :string
                                 :error-output :string
                                 :ignore-error-status t)
             (declare (ignore output error-output))
             (zerop exit-code))
         (error () nil))))

(defun ensure-kioskbeerli-sqlite-available (sqlite-program)
  (unless (sqlite-available-p :sqlite-program sqlite-program)
    (error 'kioskbeerli-sqlite-unavailable
           :program sqlite-program
           :detail "The sqlite3 command is not present or did not run successfully."))
  t)

(defun kioskbeerli-sqlite-run (store sql &key json-p)
  (let* ((sqlite-program (sqlite-store-program-of store))
         (db-path (sqlite-store-db-path-of store))
         (parent (and db-path
                      (uiop:pathname-directory-pathname db-path))))
    (cond
      ((null db-path)
       (error 'kioskbeerli-sqlite-unavailable
              :program sqlite-program
              :detail "No SQLite database path configured."))
      ((not (sqlite-available-p :sqlite-program sqlite-program))
       (error 'kioskbeerli-sqlite-unavailable
              :program sqlite-program
              :detail "The sqlite3 command is not available."))
      (t
       (when parent
         (ensure-directories-exist parent))
       (multiple-value-bind (output error-output exit-code)
           (uiop:run-program
            (append (list sqlite-program)
                    (when json-p (list "-json"))
                    (list (namestring db-path) sql))
            :output :string
            :error-output :output
            :ignore-error-status t)
         (declare (ignore error-output))
         (unless (zerop exit-code)
           (error "Kioskbeerli sqlite3 exited with code ~D: ~A"
                  exit-code
                  output))
         output)))))

(defun kioskbeerli-sqlite-exec (store sql)
  (kioskbeerli-sqlite-run store sql)
  store)

(defun kioskbeerli-sqlite-schema-sql ()
  "CREATE TABLE IF NOT EXISTS kioskbeerli_runs(
    id text primary key,
    title text,
    status text,
    created_at text,
    source_fedwiki_slug text,
    source_asset_ref text,
    source_hyperdoc_ref text
  );

  CREATE TABLE IF NOT EXISTS kioskbeerli_plans(
    id text primary key,
    run_id text references kioskbeerli_runs(id),
    title text,
    planner_kind text,
    execution_mode text,
    dry_run integer
  );

  CREATE TABLE IF NOT EXISTS kioskbeerli_tasks(
    id text primary key,
    plan_id text references kioskbeerli_plans(id),
    title text,
    state text,
    dependencies_json text,
    evidence_json text,
    source_fedwiki_slug text,
    source_asset_ref text,
    source_hyperdoc_ref text
  );

  CREATE TABLE IF NOT EXISTS kioskbeerli_task_edges(
    parent_task_id text,
    child_task_id text,
    plan_id text references kioskbeerli_plans(id),
    primary key(parent_task_id, child_task_id, plan_id)
  );

  CREATE TABLE IF NOT EXISTS kioskbeerli_trace_events(
    id text primary key,
    trace_id text,
    task_id text,
    timestamp text,
    event_kind text,
    from_state text,
    to_state text,
    status text,
    payload text,
    source_fedwiki_slug text,
    source_asset_ref text,
    source_hyperdoc_ref text
  );

  CREATE TABLE IF NOT EXISTS kioskbeerli_dashboard_snapshots(
    id text primary key,
    dashboard_id text,
    title text,
    status text,
    payload text,
    created_at text,
    source_fedwiki_slug text,
    source_asset_ref text,
    source_hyperdoc_ref text
  );")

(defun ensure-sqlite-schema (store)
  (kioskbeerli-sqlite-exec store (kioskbeerli-sqlite-schema-sql))
  (setf (sqlite-store-schema-status-of store) :ready)
  store)

(defun open-or-create-sqlite-store
    (&key (db-path #P"/tmp/kioskbeerli.sqlite")
       (sqlite-program "sqlite3")
       ensure-schema)
  (ensure-kioskbeerli-sqlite-available sqlite-program)
  (let ((store (make-instance 'kioskbeerli-sqlite-store
                              :db-path db-path
                              :sqlite-program sqlite-program
                              :schema-status :available)))
    (if ensure-schema
        (ensure-sqlite-schema store)
        store)))

(defun kioskbeerli-print-json-ish (value)
  (with-output-to-string (stream)
    (let ((*print-pretty* nil))
      (prin1 value stream))))

(defun persist-plan (store plan &key (run-id "demo-run"))
  (ensure-sqlite-schema store)
  (kioskbeerli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskbeerli_runs(id, title, status, created_at)
            VALUES(~A, ~A, ~A, datetime('now'));
            INSERT OR REPLACE INTO kioskbeerli_plans(id, run_id, title, planner_kind, execution_mode, dry_run)
            VALUES(~A, ~A, ~A, ~A, ~A, ~D);"
           (kioskbeerli-sqlite-string-literal run-id)
           (kioskbeerli-sqlite-string-literal "Kioskbeerli demo run")
           (kioskbeerli-sqlite-string-literal "local")
           (kioskbeerli-sqlite-string-literal (id-of plan))
           (kioskbeerli-sqlite-string-literal run-id)
           (kioskbeerli-sqlite-string-literal (title-of plan))
           (kioskbeerli-sqlite-string-literal (planner-kind-of plan))
           (kioskbeerli-sqlite-string-literal (execution-mode-of plan))
           (if (dry-run-p plan) 1 0)))
  (dolist (task (tasks-of plan))
    (persist-task store task :plan-id (id-of plan)))
  plan)

(defun persist-task
    (store task &key plan-id source-fedwiki-slug source-asset-reference
       source-hyperdoc-reference)
  (ensure-sqlite-schema store)
  (kioskbeerli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskbeerli_tasks(
              id, plan_id, title, state, dependencies_json, evidence_json,
              source_fedwiki_slug, source_asset_ref, source_hyperdoc_ref)
            VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A);"
           (kioskbeerli-sqlite-string-literal (id-of task))
           (kioskbeerli-sqlite-string-literal plan-id)
           (kioskbeerli-sqlite-string-literal (title-of task))
           (kioskbeerli-sqlite-string-literal (status-of task))
           (kioskbeerli-sqlite-string-literal
            (kioskbeerli-print-json-ish (dependencies-of task)))
           (kioskbeerli-sqlite-string-literal
            (kioskbeerli-print-json-ish (evidence-paths-of task)))
           (kioskbeerli-sqlite-string-literal source-fedwiki-slug)
           (kioskbeerli-sqlite-string-literal source-asset-reference)
           (kioskbeerli-sqlite-string-literal source-hyperdoc-reference)))
  (dolist (dependency (dependencies-of task))
    (kioskbeerli-sqlite-exec
     store
     (format nil
             "INSERT OR REPLACE INTO kioskbeerli_task_edges(parent_task_id, child_task_id, plan_id)
              VALUES(~A, ~A, ~A);"
             (kioskbeerli-sqlite-string-literal dependency)
             (kioskbeerli-sqlite-string-literal (id-of task))
             (kioskbeerli-sqlite-string-literal plan-id))))
  task)

(defun persist-trace-event
    (store entry &key payload source-fedwiki-slug source-asset-reference
       source-hyperdoc-reference trace-id)
  (ensure-sqlite-schema store)
  (kioskbeerli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskbeerli_trace_events(
              id, trace_id, task_id, timestamp, event_kind, from_state, to_state,
              status, payload, source_fedwiki_slug, source_asset_ref,
              source_hyperdoc_ref)
            VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A);"
           (kioskbeerli-sqlite-string-literal (id-of entry))
           (kioskbeerli-sqlite-string-literal trace-id)
           (kioskbeerli-sqlite-string-literal (task-id-of entry))
           (kioskbeerli-sqlite-string-literal (timestamp-of entry))
           (kioskbeerli-sqlite-string-literal
            (or (scxml-event-of entry) (status-of entry)))
           (kioskbeerli-sqlite-string-literal (from-state-of entry))
           (kioskbeerli-sqlite-string-literal (to-state-of entry))
           (kioskbeerli-sqlite-string-literal (status-of entry))
           (kioskbeerli-sqlite-string-literal
            (or payload (note-of entry)))
           (kioskbeerli-sqlite-string-literal source-fedwiki-slug)
           (kioskbeerli-sqlite-string-literal source-asset-reference)
           (kioskbeerli-sqlite-string-literal source-hyperdoc-reference)))
  entry)

(defun persist-dashboard-snapshot
    (store dashboard &key id payload source-fedwiki-slug source-asset-reference
       source-hyperdoc-reference)
  (ensure-sqlite-schema store)
  (kioskbeerli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskbeerli_dashboard_snapshots(
              id, dashboard_id, title, status, payload, created_at,
              source_fedwiki_slug, source_asset_ref, source_hyperdoc_ref)
            VALUES(~A, ~A, ~A, ~A, ~A, datetime('now'), ~A, ~A, ~A);"
           (kioskbeerli-sqlite-string-literal
            (or id (format nil "~A-snapshot" (id-of dashboard))))
           (kioskbeerli-sqlite-string-literal (id-of dashboard))
           (kioskbeerli-sqlite-string-literal (title-of dashboard))
           (kioskbeerli-sqlite-string-literal
            (status-of (first (sections-of dashboard))))
           (kioskbeerli-sqlite-string-literal
            (or payload (kioskbeerli-print-json-ish
                         (kioskbeerli-dashboard-view-data dashboard))))
           (kioskbeerli-sqlite-string-literal source-fedwiki-slug)
           (kioskbeerli-sqlite-string-literal source-asset-reference)
           (kioskbeerli-sqlite-string-literal source-hyperdoc-reference)))
  dashboard)
