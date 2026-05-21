;;;; Optional SQLite persistence for Kioskberrli local demo state.

(in-package :kioskberrli)

(define-condition kioskberrli-sqlite-unavailable (error)
  ((program :reader sqlite-unavailable-program-of
            :initarg :program)
   (detail :reader sqlite-unavailable-detail-of
           :initarg :detail))
  (:report (lambda (condition stream)
             (format stream
                     "Kioskberrli SQLite support is unavailable through ~S: ~A"
                     (sqlite-unavailable-program-of condition)
                     (sqlite-unavailable-detail-of condition)))))

(defclass kioskberrli-sqlite-store ()
  ((db-path :reader sqlite-store-db-path-of :initarg :db-path)
   (sqlite-program :reader sqlite-store-program-of
                   :initarg :sqlite-program
                   :initform "sqlite3")
   (schema-status :accessor sqlite-store-schema-status-of
                  :initarg :schema-status
                  :initform :unknown)))

(defmethod print-object ((store kioskberrli-sqlite-store) stream)
  (print-unreadable-object (store stream :type t :identity nil)
    (format stream "~A ~A"
            (sqlite-store-schema-status-of store)
            (sqlite-store-db-path-of store))))

(defun kioskberrli-sqlite-blank-string-p (value)
  (or (null value)
      (and (stringp value)
           (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       value))))))

(defun kioskberrli-sqlite-string-literal (value)
  (if (null value)
      "NULL"
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for char across (format nil "~A" value)
                      do (if (char= char #\')
                             (write-string "''" stream)
                             (write-char char stream)))))))

(defun kioskberrli-sqlite-integer-literal (value)
  (if value
      (format nil "~D" value)
      "NULL"))

(defun sqlite-available-p (&key (sqlite-program "sqlite3"))
  (and (not (kioskberrli-sqlite-blank-string-p sqlite-program))
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program (list sqlite-program "--version")
                                 :output :string
                                 :error-output :string
                                 :ignore-error-status t)
             (declare (ignore output error-output))
             (zerop exit-code))
         (error () nil))))

(defun ensure-kioskberrli-sqlite-available (sqlite-program)
  (unless (sqlite-available-p :sqlite-program sqlite-program)
    (error 'kioskberrli-sqlite-unavailable
           :program sqlite-program
           :detail "The sqlite3 command is not present or did not run successfully."))
  t)

(defun kioskberrli-sqlite-run (store sql &key json-p)
  (let* ((sqlite-program (sqlite-store-program-of store))
         (db-path (sqlite-store-db-path-of store))
         (parent (and db-path
                      (uiop:pathname-directory-pathname db-path))))
    (cond
      ((null db-path)
       (error 'kioskberrli-sqlite-unavailable
              :program sqlite-program
              :detail "No SQLite database path configured."))
      ((not (sqlite-available-p :sqlite-program sqlite-program))
       (error 'kioskberrli-sqlite-unavailable
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
           (error "Kioskberrli sqlite3 exited with code ~D: ~A"
                  exit-code
                  output))
         output)))))

(defun kioskberrli-sqlite-exec (store sql)
  (kioskberrli-sqlite-run store sql)
  store)

(defun kioskberrli-sqlite-schema-sql ()
  "CREATE TABLE IF NOT EXISTS kioskberrli_runs(
    id text primary key,
    title text,
    status text,
    created_at text,
    source_fedwiki_slug text,
    source_asset_ref text,
    source_hyperdoc_ref text
  );

  CREATE TABLE IF NOT EXISTS kioskberrli_plans(
    id text primary key,
    run_id text references kioskberrli_runs(id),
    title text,
    planner_kind text,
    execution_mode text,
    dry_run integer
  );

  CREATE TABLE IF NOT EXISTS kioskberrli_tasks(
    id text primary key,
    plan_id text references kioskberrli_plans(id),
    title text,
    state text,
    dependencies_json text,
    evidence_json text,
    source_fedwiki_slug text,
    source_asset_ref text,
    source_hyperdoc_ref text
  );

  CREATE TABLE IF NOT EXISTS kioskberrli_task_edges(
    parent_task_id text,
    child_task_id text,
    plan_id text references kioskberrli_plans(id),
    primary key(parent_task_id, child_task_id, plan_id)
  );

  CREATE TABLE IF NOT EXISTS kioskberrli_trace_events(
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

  CREATE TABLE IF NOT EXISTS kioskberrli_dashboard_snapshots(
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
  (kioskberrli-sqlite-exec store (kioskberrli-sqlite-schema-sql))
  (setf (sqlite-store-schema-status-of store) :ready)
  store)

(defun open-or-create-sqlite-store
    (&key (db-path #P"/tmp/kioskberrli.sqlite")
       (sqlite-program "sqlite3")
       ensure-schema)
  (ensure-kioskberrli-sqlite-available sqlite-program)
  (let ((store (make-instance 'kioskberrli-sqlite-store
                              :db-path db-path
                              :sqlite-program sqlite-program
                              :schema-status :available)))
    (if ensure-schema
        (ensure-sqlite-schema store)
        store)))

(defun kioskberrli-print-json-ish (value)
  (with-output-to-string (stream)
    (let ((*print-pretty* nil))
      (prin1 value stream))))

(defun persist-plan (store plan &key (run-id "demo-run"))
  (ensure-sqlite-schema store)
  (kioskberrli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskberrli_runs(id, title, status, created_at)
            VALUES(~A, ~A, ~A, datetime('now'));
            INSERT OR REPLACE INTO kioskberrli_plans(id, run_id, title, planner_kind, execution_mode, dry_run)
            VALUES(~A, ~A, ~A, ~A, ~A, ~D);"
           (kioskberrli-sqlite-string-literal run-id)
           (kioskberrli-sqlite-string-literal "Kioskberrli demo run")
           (kioskberrli-sqlite-string-literal "local")
           (kioskberrli-sqlite-string-literal (id-of plan))
           (kioskberrli-sqlite-string-literal run-id)
           (kioskberrli-sqlite-string-literal (title-of plan))
           (kioskberrli-sqlite-string-literal (planner-kind-of plan))
           (kioskberrli-sqlite-string-literal (execution-mode-of plan))
           (if (dry-run-p plan) 1 0)))
  (dolist (task (tasks-of plan))
    (persist-task store task :plan-id (id-of plan)))
  plan)

(defun persist-task
    (store task &key plan-id source-fedwiki-slug source-asset-reference
       source-hyperdoc-reference)
  (ensure-sqlite-schema store)
  (kioskberrli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskberrli_tasks(
              id, plan_id, title, state, dependencies_json, evidence_json,
              source_fedwiki_slug, source_asset_ref, source_hyperdoc_ref)
            VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A);"
           (kioskberrli-sqlite-string-literal (id-of task))
           (kioskberrli-sqlite-string-literal plan-id)
           (kioskberrli-sqlite-string-literal (title-of task))
           (kioskberrli-sqlite-string-literal (status-of task))
           (kioskberrli-sqlite-string-literal
            (kioskberrli-print-json-ish (dependencies-of task)))
           (kioskberrli-sqlite-string-literal
            (kioskberrli-print-json-ish (evidence-paths-of task)))
           (kioskberrli-sqlite-string-literal source-fedwiki-slug)
           (kioskberrli-sqlite-string-literal source-asset-reference)
           (kioskberrli-sqlite-string-literal source-hyperdoc-reference)))
  (dolist (dependency (dependencies-of task))
    (kioskberrli-sqlite-exec
     store
     (format nil
             "INSERT OR REPLACE INTO kioskberrli_task_edges(parent_task_id, child_task_id, plan_id)
              VALUES(~A, ~A, ~A);"
             (kioskberrli-sqlite-string-literal dependency)
             (kioskberrli-sqlite-string-literal (id-of task))
             (kioskberrli-sqlite-string-literal plan-id))))
  task)

(defun persist-trace-event
    (store entry &key payload source-fedwiki-slug source-asset-reference
       source-hyperdoc-reference trace-id)
  (ensure-sqlite-schema store)
  (kioskberrli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskberrli_trace_events(
              id, trace_id, task_id, timestamp, event_kind, from_state, to_state,
              status, payload, source_fedwiki_slug, source_asset_ref,
              source_hyperdoc_ref)
            VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A);"
           (kioskberrli-sqlite-string-literal (id-of entry))
           (kioskberrli-sqlite-string-literal trace-id)
           (kioskberrli-sqlite-string-literal (task-id-of entry))
           (kioskberrli-sqlite-string-literal (timestamp-of entry))
           (kioskberrli-sqlite-string-literal
            (or (scxml-event-of entry) (status-of entry)))
           (kioskberrli-sqlite-string-literal (from-state-of entry))
           (kioskberrli-sqlite-string-literal (to-state-of entry))
           (kioskberrli-sqlite-string-literal (status-of entry))
           (kioskberrli-sqlite-string-literal
            (or payload (note-of entry)))
           (kioskberrli-sqlite-string-literal source-fedwiki-slug)
           (kioskberrli-sqlite-string-literal source-asset-reference)
           (kioskberrli-sqlite-string-literal source-hyperdoc-reference)))
  entry)

(defun persist-dashboard-snapshot
    (store dashboard &key id payload source-fedwiki-slug source-asset-reference
       source-hyperdoc-reference)
  (ensure-sqlite-schema store)
  (kioskberrli-sqlite-exec
   store
   (format nil
           "INSERT OR REPLACE INTO kioskberrli_dashboard_snapshots(
              id, dashboard_id, title, status, payload, created_at,
              source_fedwiki_slug, source_asset_ref, source_hyperdoc_ref)
            VALUES(~A, ~A, ~A, ~A, ~A, datetime('now'), ~A, ~A, ~A);"
           (kioskberrli-sqlite-string-literal
            (or id (format nil "~A-snapshot" (id-of dashboard))))
           (kioskberrli-sqlite-string-literal (id-of dashboard))
           (kioskberrli-sqlite-string-literal (title-of dashboard))
           (kioskberrli-sqlite-string-literal
            (status-of (first (sections-of dashboard))))
           (kioskberrli-sqlite-string-literal
            (or payload (kioskberrli-print-json-ish
                         (kioskbeerli-dashboard-view-data dashboard))))
           (kioskberrli-sqlite-string-literal source-fedwiki-slug)
           (kioskberrli-sqlite-string-literal source-asset-reference)
           (kioskberrli-sqlite-string-literal source-hyperdoc-reference)))
  dashboard)
