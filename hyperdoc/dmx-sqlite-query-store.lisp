;;;; SQLite persistence for DMX query runs and dry-run sync plans

(in-package :hyperdoc)

(defgeneric dmx-persist-sync-plan (sqlite-store sync-plan)
  (:documentation "Persist a dry-run DMX sync plan and its items."))

(defun dmx-sqlite-blank-string-p (value)
  (or (null value)
      (and (stringp value)
           (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       value))))))

(defun dmx-sqlite-string-literal (value)
  (if (null value)
      "NULL"
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for char across (format nil "~A" value)
                      do (if (char= char #\')
                             (write-string "''" stream)
                             (write-char char stream)))))))

(defun dmx-sqlite-integer-literal (value)
  (if value
      (format nil "~D" value)
      "NULL"))

(defun dmx-sqlite-run (store sql &key json-p)
  (let* ((sqlite-program (dmx-sqlite-query-store-sqlite-program-of store))
         (db-path (dmx-sqlite-query-store-db-path-of store))
         (parent (and db-path
                      (uiop:pathname-directory-pathname db-path))))
    (cond
      ((null db-path)
       (values nil :configuration-error "No SQLite database path configured."))
      ((dmx-sqlite-blank-string-p sqlite-program)
       (values nil :configuration-error "No sqlite3 program configured."))
      (t
       (when parent
         (ensure-directories-exist parent))
       (let ((command (append (list sqlite-program)
                              (when json-p (list "-json"))
                              (list (namestring db-path)
                                    sql))))
         (handler-case
             (multiple-value-bind (output error-output exit-code)
                 (uiop:run-program command
                                   :output :string
                                   :error-output :output
                                   :ignore-error-status t)
               (declare (ignore error-output))
               (if (zerop exit-code)
                   (values output :ok nil)
                   (values output :error
                           (format nil "sqlite3 exited with code ~D: ~A"
                                   exit-code
                                   output))))
           (error (condition)
             (values nil :error (princ-to-string condition)))))))))

(defun dmx-sqlite-exec (store sql)
  (multiple-value-bind (output status detail)
      (dmx-sqlite-run store sql)
    (declare (ignore output))
    (unless (eq status :ok)
      (error "SQLite DMX query store failed: ~A" detail)))
  store)

(defun dmx-sqlite-schema-sql ()
  "CREATE TABLE IF NOT EXISTS stores(
    id text primary key,
    kind text not null,
    title text,
    endpoint text,
    created_at text
  );

  CREATE TABLE IF NOT EXISTS queries(
    id text primary key,
    title text not null,
    query_kind text not null,
    query_sexp text not null,
    created_at text not null
  );

  CREATE TABLE IF NOT EXISTS query_runs(
    id text primary key,
    query_id text not null references queries(id),
    store_id text not null references stores(id),
    status text not null,
    executed_at text not null,
    row_count integer,
    raw_request text,
    raw_response text,
    error_detail text
  );

  CREATE TABLE IF NOT EXISTS topic_answers(
    id text primary key,
    query_run_id text not null references query_runs(id),
    store_id text not null,
    backend_kind text not null,
    topic_id text,
    uri text,
    type_uri text,
    value text,
    workspace_id text,
    workspace_status text not null,
    topicmap_ids_json text,
    ownership_class text,
    raw_json text,
    evidence_path text
  );

  CREATE TABLE IF NOT EXISTS sync_plans(
    id text primary key,
    source_store_id text not null,
    target_store_id text not null,
    query_id text not null,
    status text not null,
    created_at text not null
  );

  CREATE TABLE IF NOT EXISTS sync_plan_items(
    id text primary key,
    sync_plan_id text not null references sync_plans(id),
    uri text,
    action text not null,
    reason text,
    safe_p integer not null,
    source_topic_json text,
    target_topic_json text
  );")

(defun dmx-ensure-sqlite-query-schema (store)
  (dmx-sqlite-exec store (dmx-sqlite-schema-sql)))

(defun dmx-store-target-endpoint (target)
  (typecase target
    (dmx-neo4j-store-target
     (namestring (dmx-neo4j-store-target-store-path-of target)))
    (dmx-http-store-target
     (dmx-http-store-target-base-url-of target))
    (dmx-sqlite-query-store
     (namestring (dmx-sqlite-query-store-db-path-of target)))
    (t nil)))

(defun dmx-sqlite-upsert-store-sql (target)
  (format nil
          "INSERT OR REPLACE INTO stores(id, kind, title, endpoint, created_at)
           VALUES(~A, ~A, ~A, ~A, ~A);"
          (dmx-sqlite-string-literal (id-of target))
          (dmx-sqlite-string-literal (dmx-query-keyword-label
                                      (kind-of target)))
          (dmx-sqlite-string-literal (title-of target))
          (dmx-sqlite-string-literal (dmx-store-target-endpoint target))
          (dmx-sqlite-string-literal (dmx-query-now-string))))

(defun dmx-sqlite-upsert-query-sql (query)
  (format nil
          "INSERT OR REPLACE INTO queries(id, title, query_kind, query_sexp, created_at)
           VALUES(~A, ~A, ~A, ~A, ~A);"
          (dmx-sqlite-string-literal (id-of query))
          (dmx-sqlite-string-literal (title-of query))
          (dmx-sqlite-string-literal (dmx-query-keyword-label
                                      (dmx-query-kind-of query)))
          (dmx-sqlite-string-literal
           (with-output-to-string (stream)
             (let ((*print-pretty* nil))
               (prin1 (dmx-query-parameters-of query) stream))))
          (dmx-sqlite-string-literal (dmx-query-created-at-of query))))

(defun dmx-sqlite-insert-query-run-sql (query-run)
  (format nil
          "INSERT OR REPLACE INTO query_runs(id, query_id, store_id, status, executed_at,
                                             row_count, raw_request, raw_response, error_detail)
           VALUES(~A, ~A, ~A, ~A, ~A, ~D, ~A, ~A, ~A);"
          (dmx-sqlite-string-literal (id-of query-run))
          (dmx-sqlite-string-literal
           (id-of (dmx-query-run-query-of query-run)))
          (dmx-sqlite-string-literal
           (id-of (dmx-query-run-source-target-of query-run)))
          (dmx-sqlite-string-literal
           (dmx-query-keyword-label (dmx-query-run-status-of query-run)))
          (dmx-sqlite-string-literal (dmx-query-run-executed-at-of query-run))
          (length (dmx-query-run-rows-of query-run))
          (dmx-sqlite-string-literal (dmx-query-run-raw-request-of query-run))
          (dmx-sqlite-string-literal (dmx-query-run-raw-response-of query-run))
          (dmx-sqlite-string-literal (dmx-query-run-error-detail-of query-run))))

(defun dmx-sqlite-topic-answer-id (query-run row index)
  (format nil "~A:row:~D:~A"
          (id-of query-run)
          index
          (or (dmx-topic-row-uri-of row)
              (dmx-topic-row-topic-id-of row)
              "no-identity")))

(defun dmx-sqlite-insert-topic-answer-sql (query-run row index)
  (format nil
          "INSERT OR REPLACE INTO topic_answers(
             id, query_run_id, store_id, backend_kind, topic_id, uri, type_uri, value,
             workspace_id, workspace_status, topicmap_ids_json, ownership_class,
             raw_json, evidence_path)
           VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A);"
          (dmx-sqlite-string-literal
           (dmx-sqlite-topic-answer-id query-run row index))
          (dmx-sqlite-string-literal (id-of query-run))
          (dmx-sqlite-string-literal (dmx-topic-row-store-id-of row))
          (dmx-sqlite-string-literal
           (dmx-query-keyword-label (dmx-topic-row-backend-kind-of row)))
          (dmx-sqlite-string-literal (dmx-topic-row-topic-id-of row))
          (dmx-sqlite-string-literal (dmx-topic-row-uri-of row))
          (dmx-sqlite-string-literal (dmx-topic-row-type-uri-of row))
          (dmx-sqlite-string-literal (dmx-topic-row-value-of row))
          (dmx-sqlite-string-literal
           (and (dmx-topic-row-workspace-id-of row)
                (format nil "~A" (dmx-topic-row-workspace-id-of row))))
          (dmx-sqlite-string-literal
           (dmx-query-keyword-label (dmx-topic-row-workspace-status-of row)))
          (dmx-sqlite-string-literal
           (dmx-query-json-string
            (coerce (dmx-topic-row-topicmap-ids-of row) 'vector)))
          (dmx-sqlite-string-literal
           (dmx-query-keyword-label (dmx-topic-row-ownership-class-of row)))
          (dmx-sqlite-string-literal
           (dmx-query-json-string (dmx-topic-row-json-object row)))
          (dmx-sqlite-string-literal (dmx-topic-row-evidence-path-of row))))

(defmethod dmx-persist-query-run
    ((sqlite-store dmx-sqlite-query-store) (query-run dmx-query-run))
  (dmx-ensure-sqlite-query-schema sqlite-store)
  (let ((sql (with-output-to-string (stream)
               (write-line "BEGIN;" stream)
               (write-line
                (dmx-sqlite-upsert-store-sql
                 (dmx-query-run-source-target-of query-run))
                stream)
               (write-line
                (dmx-sqlite-upsert-query-sql
                 (dmx-query-run-query-of query-run))
                stream)
               (write-line (dmx-sqlite-insert-query-run-sql query-run)
                           stream)
               (loop for row in (dmx-query-run-rows-of query-run)
                     for index from 0
                     do (write-line
                         (dmx-sqlite-insert-topic-answer-sql
                          query-run
                          row
                          index)
                         stream))
               (write-line "COMMIT;" stream))))
    (dmx-sqlite-exec sqlite-store sql))
  query-run)

(defun dmx-sqlite-json-query (store sql)
  (multiple-value-bind (output status detail)
      (dmx-sqlite-run store sql :json-p t)
    (if (eq status :ok)
        (dmx-query-parse-json-list output)
        (list (let ((row (make-hash-table :test #'equal)))
                (setf (gethash "status" row) (dmx-query-keyword-label status)
                      (gethash "detail" row) detail)
                row)))))

(defmethod dmx-load-query-runs
    ((sqlite-store dmx-sqlite-query-store)
     &key query-id source-target-id (limit 20))
  (dmx-ensure-sqlite-query-schema sqlite-store)
  (dmx-sqlite-json-query
   sqlite-store
   (format nil
           "SELECT * FROM query_runs
            WHERE 1=1
            ~@[AND query_id = ~A~]
            ~@[AND store_id = ~A~]
            ORDER BY executed_at DESC
            LIMIT ~D;"
           (and query-id (dmx-sqlite-string-literal query-id))
           (and source-target-id
                (dmx-sqlite-string-literal source-target-id))
           limit)))

(defun dmx-sqlite-insert-sync-plan-sql (plan)
  (format nil
          "INSERT OR REPLACE INTO sync_plans(
             id, source_store_id, target_store_id, query_id, status, created_at)
           VALUES(~A, ~A, ~A, ~A, ~A, ~A);"
          (dmx-sqlite-string-literal (id-of plan))
          (dmx-sqlite-string-literal
           (id-of (dmx-sync-plan-source-target-of plan)))
          (dmx-sqlite-string-literal
           (id-of (dmx-sync-plan-target-target-of plan)))
          (dmx-sqlite-string-literal
           (id-of (dmx-query-run-query-of
                   (dmx-sync-plan-query-run-a-of plan))))
          (dmx-sqlite-string-literal
           (dmx-query-keyword-label (dmx-sync-plan-status-of plan)))
          (dmx-sqlite-string-literal (dmx-query-now-string))))

(defun dmx-sqlite-insert-sync-plan-item-sql (plan item)
  (format nil
          "INSERT OR REPLACE INTO sync_plan_items(
             id, sync_plan_id, uri, action, reason, safe_p,
             source_topic_json, target_topic_json)
           VALUES(~A, ~A, ~A, ~A, ~A, ~D, ~A, ~A);"
          (dmx-sqlite-string-literal (id-of item))
          (dmx-sqlite-string-literal (id-of plan))
          (dmx-sqlite-string-literal (dmx-sync-plan-item-uri-of item))
          (dmx-sqlite-string-literal
           (dmx-query-keyword-label (dmx-sync-plan-item-action-of item)))
          (dmx-sqlite-string-literal (dmx-sync-plan-item-reason-of item))
          (if (dmx-sync-plan-item-safe-p item) 1 0)
          (dmx-sqlite-string-literal
           (and (dmx-sync-plan-item-source-row-of item)
                (dmx-query-json-string
                 (dmx-topic-row-json-object
                  (dmx-sync-plan-item-source-row-of item)))))
          (dmx-sqlite-string-literal
           (and (dmx-sync-plan-item-target-row-of item)
                (dmx-query-json-string
                 (dmx-topic-row-json-object
                  (dmx-sync-plan-item-target-row-of item)))))))

(defmethod dmx-persist-sync-plan
    ((sqlite-store dmx-sqlite-query-store) (plan dmx-sync-plan))
  (dmx-ensure-sqlite-query-schema sqlite-store)
  (let ((sql (with-output-to-string (stream)
               (write-line "BEGIN;" stream)
               (write-line
                (dmx-sqlite-upsert-store-sql
                 (dmx-sync-plan-source-target-of plan))
                stream)
               (write-line
                (dmx-sqlite-upsert-store-sql
                 (dmx-sync-plan-target-target-of plan))
                stream)
               (write-line
                (dmx-sqlite-upsert-query-sql
                 (dmx-query-run-query-of
                  (dmx-sync-plan-query-run-a-of plan)))
                stream)
               (write-line (dmx-sqlite-insert-sync-plan-sql plan)
                           stream)
               (dolist (item (dmx-sync-plan-items-of plan))
                 (write-line
                  (dmx-sqlite-insert-sync-plan-item-sql plan item)
                  stream))
               (write-line "COMMIT;" stream))))
    (dmx-sqlite-exec sqlite-store sql))
  plan)

(defun dmx-sqlite-schema-status (store)
  (dmx-sqlite-json-query
   store
   "SELECT name, type FROM sqlite_master
    WHERE type IN ('table', 'index')
    ORDER BY type, name;"))
