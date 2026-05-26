;;;; DMX associative SQL mirror for Kioskbeerli traces
;;;; This file is intended to be loadable from SLY instead of pasted form-by-form.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf))

(defpackage #:kioskbeerli.dmx-associative-mirror
  (:use #:cl)
  (:export
   #:*default-dmx-associative-mirror-path*
   #:initialize-dmx-associative-mirror
   #:sqlite-run
   #:upsert-dmx-topic
   #:upsert-dmx-assoc
   #:upsert-dmx-sync-identity
   #:seed-kioskbeerli-provenance-topics
   #:persist-kioskbeerli-trace-as-dmx-sql
   #:persist-kioskbeerli-trace-entry-as-dmx-sql
   #:dmx-sql-counts
   #:dmx-sql-trace-events
   #:dmx-sql-provenance-associations
   #:run-dmx-associative-mirror-smoke))

(in-package #:kioskbeerli.dmx-associative-mirror)

(defparameter *default-dmx-associative-mirror-path*
  (merge-pathnames #p"var/dmx-associative-mirror.sqlite"
                   (uiop:getcwd)))

(defparameter *dmx-associative-schema-sql*
"PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS dmx_sql_object (
  local_id TEXT PRIMARY KEY,
  object_kind TEXT NOT NULL CHECK (object_kind IN ('topic', 'assoc')),
  uri TEXT,
  type_uri TEXT NOT NULL,
  value TEXT,
  payload_json TEXT,
  content_hash TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  modified_at TEXT DEFAULT CURRENT_TIMESTAMP,
  sync_state TEXT DEFAULT 'local'
);

CREATE UNIQUE INDEX IF NOT EXISTS dmx_sql_object_uri_unique
  ON dmx_sql_object(uri)
  WHERE uri IS NOT NULL;

CREATE TABLE IF NOT EXISTS dmx_sql_topic (
  local_id TEXT PRIMARY KEY REFERENCES dmx_sql_object(local_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS dmx_sql_assoc (
  local_id TEXT PRIMARY KEY REFERENCES dmx_sql_object(local_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS dmx_sql_assoc_player (
  assoc_id TEXT NOT NULL REFERENCES dmx_sql_assoc(local_id) ON DELETE CASCADE,
  player_no INTEGER NOT NULL,
  role_type_uri TEXT NOT NULL,
  player_kind TEXT NOT NULL CHECK (player_kind IN ('topic', 'assoc')),
  player_local_id TEXT NOT NULL REFERENCES dmx_sql_object(local_id),
  PRIMARY KEY (assoc_id, player_no)
);

CREATE INDEX IF NOT EXISTS dmx_sql_assoc_player_player_idx
  ON dmx_sql_assoc_player(player_local_id);

CREATE INDEX IF NOT EXISTS dmx_sql_assoc_player_role_idx
  ON dmx_sql_assoc_player(role_type_uri);

CREATE TABLE IF NOT EXISTS dmx_sql_property (
  id TEXT PRIMARY KEY,
  object_id TEXT NOT NULL REFERENCES dmx_sql_object(local_id) ON DELETE CASCADE,
  property_uri TEXT NOT NULL,
  value TEXT,
  value_json TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dmx_sql_sync_identity (
  id TEXT PRIMARY KEY,
  local_object_id TEXT NOT NULL REFERENCES dmx_sql_object(local_id) ON DELETE CASCADE,
  host TEXT NOT NULL,
  remote_id INTEGER,
  remote_uri TEXT,
  remote_type_uri TEXT,
  last_seen_hash TEXT,
  last_seen_at TEXT,
  sync_state TEXT NOT NULL DEFAULT 'observed',
  UNIQUE(host, remote_id),
  UNIQUE(host, remote_uri)
);

CREATE TABLE IF NOT EXISTS dmx_sql_sync_journal (
  id TEXT PRIMARY KEY,
  journal_kind TEXT NOT NULL,
  local_object_id TEXT REFERENCES dmx_sql_object(local_id),
  host TEXT,
  remote_id INTEGER,
  action TEXT NOT NULL,
  status TEXT NOT NULL,
  detail TEXT,
  payload_json TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
")

(defun sqlite-run (db-path sql &key (header nil) (column nil) (ignore-error-status t))
  "Run SQL against DB-PATH through the sqlite3 executable.
Return the usual UIOP values: stdout, stderr, exit code. The call is non-interactive."
  (let ((args (append (when header (list "-header"))
                      (when column (list "-column"))
                      (list (namestring db-path) sql))))
    (uiop:run-program (cons "sqlite3" args)
                      :output :string
                      :error-output :string
                      :ignore-error-status ignore-error-status)))

(defun sql-literal (value)
  "Return VALUE as a single-quoted SQLite literal, or NULL."
  (if value
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for ch across (format nil "~A" value)
                      do (case ch
                           (#\' (write-string "''" stream))
                           (otherwise (write-char ch stream))))))
      "NULL"))

(defun json-string (value)
  (with-output-to-string (stream)
    (write-char #\" stream)
    (loop for ch across (format nil "~A" (or value ""))
          do (case ch
               (#\" (write-string "\\\"" stream))
               (#\\ (write-string "\\\\" stream))
               (#\Newline (write-string "\\n" stream))
               (#\Return (write-string "\\r" stream))
               (#\Tab (write-string "\\t" stream))
               (otherwise (write-char ch stream))))
    (write-char #\" stream)))

(defun json-object (&rest plist)
  (with-output-to-string (stream)
    (write-char #\{ stream)
    (loop for (key value) on plist by #'cddr
          for firstp = t then nil
          unless firstp do (write-char #\, stream)
          do (format stream "~A:~A"
                     (json-string (string-downcase (symbol-name key)))
                     (json-string value)))
    (write-char #\} stream)))

(defun initialize-dmx-associative-mirror
    (&key (db-path *default-dmx-associative-mirror-path*) (clear nil))
  "Create the DMX-shaped SQL mirror schema.
When CLEAR is true, delete the existing file first."
  (ensure-directories-exist db-path)
  (when (and clear (probe-file db-path))
    (delete-file db-path))
  (multiple-value-bind (stdout stderr exit-code)
      (sqlite-run db-path *dmx-associative-schema-sql*)
    (unless (zerop exit-code)
      (error "Could not initialize DMX associative mirror:~%~A~%~A" stdout stderr))
    db-path))

(defun upsert-dmx-topic
    (db-path local-id type-uri value &key uri payload-json sync-state)
  (sqlite-run
   db-path
   (format nil
"BEGIN;
INSERT OR REPLACE INTO dmx_sql_object(local_id, object_kind, uri, type_uri, value, payload_json, sync_state, modified_at)
VALUES(~A, 'topic', ~A, ~A, ~A, ~A, ~A, CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO dmx_sql_topic(local_id) VALUES(~A);
COMMIT;"
           (sql-literal local-id)
           (sql-literal uri)
           (sql-literal type-uri)
           (sql-literal value)
           (sql-literal payload-json)
           (sql-literal (or sync-state "local"))
           (sql-literal local-id))))

(defun upsert-dmx-assoc
    (db-path assoc-id assoc-type-uri player1-id player1-role player2-id player2-role
     &key value payload-json)
  (sqlite-run
   db-path
   (format nil
"BEGIN;
INSERT OR REPLACE INTO dmx_sql_object(local_id, object_kind, uri, type_uri, value, payload_json, sync_state, modified_at)
VALUES(~A, 'assoc', NULL, ~A, ~A, ~A, 'local', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO dmx_sql_assoc(local_id) VALUES(~A);
INSERT OR REPLACE INTO dmx_sql_assoc_player(assoc_id, player_no, role_type_uri, player_kind, player_local_id)
VALUES(~A, 1, ~A, 'topic', ~A);
INSERT OR REPLACE INTO dmx_sql_assoc_player(assoc_id, player_no, role_type_uri, player_kind, player_local_id)
VALUES(~A, 2, ~A, 'topic', ~A);
COMMIT;"
           (sql-literal assoc-id)
           (sql-literal assoc-type-uri)
           (sql-literal value)
           (sql-literal payload-json)
           (sql-literal assoc-id)
           (sql-literal assoc-id) (sql-literal player1-role) (sql-literal player1-id)
           (sql-literal assoc-id) (sql-literal player2-role) (sql-literal player2-id))))

(defun upsert-dmx-sync-identity
    (db-path local-object-id host &key remote-id remote-uri remote-type-uri sync-state)
  (sqlite-run
   db-path
   (format nil
"INSERT OR REPLACE INTO dmx_sql_sync_identity(
   id, local_object_id, host, remote_id, remote_uri, remote_type_uri, last_seen_at, sync_state)
 VALUES(~A, ~A, ~A, ~A, ~A, ~A, CURRENT_TIMESTAMP, ~A);"
           (sql-literal (format nil "~A:~A" host (or remote-id remote-uri local-object-id)))
           (sql-literal local-object-id)
           (sql-literal host)
           (or remote-id "NULL")
           (sql-literal remote-uri)
           (sql-literal remote-type-uri)
           (sql-literal (or sync-state "observed")))))

(defun seed-kioskbeerli-provenance-topics (db-path)
  "Seed the known DMX notes that anchor this reconstruction path."
  (upsert-dmx-topic db-path
                    "topic:dreyeck:982950"
                    "dmx.notes.note"
                    "Kioskbeerli SQLite persistence schema"
                    :uri "dmx://dreyeck/topic/982950"
                    :sync-state "observed")
  (upsert-dmx-sync-identity db-path
                            "topic:dreyeck:982950"
                            "dreyeck"
                            :remote-id 982950
                            :remote-uri "dmx://dreyeck/topic/982950"
                            :remote-type-uri "dmx.notes.note"
                            :sync-state "observed")
  (upsert-dmx-topic db-path
                    "topic:dreyeck:982981"
                    "dmx.notes.note"
                    "a successful SQLite read"
                    :uri "dmx://dreyeck/topic/982981"
                    :sync-state "observed")
  (upsert-dmx-sync-identity db-path
                            "topic:dreyeck:982981"
                            "dreyeck"
                            :remote-id 982981
                            :remote-uri "dmx://dreyeck/topic/982981"
                            :remote-type-uri "dmx.notes.note"
                            :sync-state "observed")
  db-path)

(defun call-kioskbeerli-accessor (name object &optional default)
  "Call Kioskbeerli accessor NAME on OBJECT when available.

NAME is a string such as \"entries-of\" or \"id-of\".  This helper
intentionally uses the package name string \"KIOSKBEERLI\" instead of
#:KIOSKBEERLI, because #: symbols are uninterned symbols and are not
self-evaluating in ordinary function calls."
  (let* ((package (find-package "KIOSKBEERLI"))
         (symbol (and package
                      (multiple-value-bind (found-symbol status)
                          (find-symbol (string-upcase name) package)
                        (declare (ignore status))
                        found-symbol))))
    (if (and symbol (fboundp symbol))
        (funcall symbol object)
        default)))

(defun ensure-topic (db-path local-id type-uri value &key uri payload-json sync-state)
  (upsert-dmx-topic db-path local-id type-uri value
                    :uri uri
                    :payload-json payload-json
                    :sync-state sync-state)
  local-id)

(defun persist-kioskbeerli-trace-entry-as-dmx-sql (db-path trace entry)
  "Represent one Kioskbeerli trace ENTRY as DMX-shaped SQL topics and associations."
  (let* ((trace-id (call-kioskbeerli-accessor "id-of" trace "kioskbeerli-project-trace"))
         (trace-topic "topic:kioskbeerli:project-trace")
         (entry-id (call-kioskbeerli-accessor "id-of" entry "unknown-entry"))
         (event-topic (format nil "topic:kioskbeerli:trace-event:~A" entry-id))
         (task-id (or (call-kioskbeerli-accessor "task-id-of" entry nil) "unknown-task"))
         (task-topic (format nil "topic:kioskbeerli:task:~A" task-id))
         (status (or (call-kioskbeerli-accessor "status-of" entry nil) "unknown-status"))
         (status-topic (format nil "topic:kioskbeerli:status:~A" status))
         (from-state (or (call-kioskbeerli-accessor "from-state-of" entry nil) "unknown"))
         (to-state (or (call-kioskbeerli-accessor "to-state-of" entry nil) "unknown"))
         (from-topic (format nil "topic:kioskbeerli:state:~A" from-state))
         (to-topic (format nil "topic:kioskbeerli:state:~A" to-state))
         (scxml-event (call-kioskbeerli-accessor "scxml-event-of" entry nil))
         (note (call-kioskbeerli-accessor "note-of" entry nil))
         (payload (json-object :trace-id trace-id
                               :entry-id entry-id
                               :task-id task-id
                               :status status
                               :from-state from-state
                               :to-state to-state
                               :scxml-event scxml-event
                               :note note)))
    (ensure-topic db-path trace-topic
                  "hyperdoc.kioskbeerli.project_trace"
                  "Kioskbeerli Project Trace"
                  :uri "hyperdoc:kioskbeerli/project-trace"
                  :sync-state "local")
    (ensure-topic db-path event-topic
                  "hyperdoc.kioskbeerli.trace_event"
                  entry-id
                  :uri (format nil "hyperdoc:kioskbeerli/trace-event/~A" entry-id)
                  :payload-json payload
                  :sync-state "local")
    (ensure-topic db-path task-topic
                  "hyperdoc.kioskbeerli.task"
                  task-id
                  :uri (format nil "hyperdoc:kioskbeerli/task/~A" task-id)
                  :sync-state "local")
    (ensure-topic db-path status-topic
                  "hyperdoc.kioskbeerli.status"
                  status
                  :uri (format nil "hyperdoc:kioskbeerli/status/~A" status)
                  :sync-state "local")
    (ensure-topic db-path from-topic
                  "hyperdoc.kioskbeerli.state"
                  from-state
                  :uri (format nil "hyperdoc:kioskbeerli/state/~A" from-state)
                  :sync-state "local")
    (ensure-topic db-path to-topic
                  "hyperdoc.kioskbeerli.state"
                  to-state
                  :uri (format nil "hyperdoc:kioskbeerli/state/~A" to-state)
                  :sync-state "local")
    (upsert-dmx-assoc db-path
                      (format nil "assoc:kioskbeerli:trace-has-event:~A" entry-id)
                      "hyperdoc.assoc.trace_has_event"
                      trace-topic "hyperdoc.role.trace"
                      event-topic "hyperdoc.role.event")
    (upsert-dmx-assoc db-path
                      (format nil "assoc:kioskbeerli:event-for-task:~A" entry-id)
                      "hyperdoc.assoc.event_for_task"
                      event-topic "hyperdoc.role.event"
                      task-topic "hyperdoc.role.task")
    (upsert-dmx-assoc db-path
                      (format nil "assoc:kioskbeerli:event-has-status:~A" entry-id)
                      "hyperdoc.assoc.event_has_status"
                      event-topic "hyperdoc.role.event"
                      status-topic "hyperdoc.role.status")
    (upsert-dmx-assoc db-path
                      (format nil "assoc:kioskbeerli:event-from-state:~A" entry-id)
                      "hyperdoc.assoc.event_from_state"
                      event-topic "hyperdoc.role.event"
                      from-topic "hyperdoc.role.state")
    (upsert-dmx-assoc db-path
                      (format nil "assoc:kioskbeerli:event-to-state:~A" entry-id)
                      "hyperdoc.assoc.event_to_state"
                      event-topic "hyperdoc.role.event"
                      to-topic "hyperdoc.role.state")
    (upsert-dmx-assoc db-path
                      (format nil "assoc:kioskbeerli:event-provenance-schema:~A" entry-id)
                      "hyperdoc.assoc.has_provenance"
                      event-topic "hyperdoc.role.subject"
                      "topic:dreyeck:982950" "hyperdoc.role.provenance")
    (upsert-dmx-assoc db-path
                      (format nil "assoc:kioskbeerli:event-provenance-read:~A" entry-id)
                      "hyperdoc.assoc.has_provenance"
                      event-topic "hyperdoc.role.subject"
                      "topic:dreyeck:982981" "hyperdoc.role.provenance")
    event-topic))

(defun persist-kioskbeerli-trace-as-dmx-sql
    (trace &key (db-path *default-dmx-associative-mirror-path*) (initialize t))
  "Persist TRACE into a DMX-shaped SQL mirror and return created event topic ids."
  (when initialize
    (initialize-dmx-associative-mirror :db-path db-path)
    (seed-kioskbeerli-provenance-topics db-path))
  (let ((entries (call-kioskbeerli-accessor "entries-of" trace nil)))
    (unless entries
      (error "Could not retrieve trace entries through KIOSKBEERLI::ENTRIES-OF."))
    (loop for entry in entries
          collect (persist-kioskbeerli-trace-entry-as-dmx-sql db-path trace entry))))

(defun dmx-sql-counts (&key (db-path *default-dmx-associative-mirror-path*))
  (sqlite-run db-path
              "select object_kind, count(*) as n from dmx_sql_object group by object_kind order by object_kind;"
              :header t
              :column t))

(defun dmx-sql-trace-events (&key (db-path *default-dmx-associative-mirror-path*))
  (sqlite-run db-path
              "select local_id, uri, type_uri, value from dmx_sql_object where type_uri = 'hyperdoc.kioskbeerli.trace_event' order by local_id;"
              :header t
              :column t))

(defun dmx-sql-provenance-associations (&key (db-path *default-dmx-associative-mirror-path*))
  (sqlite-run db-path
"select a.local_id as assoc_id,
        p1.player_local_id as subject,
        p2.player_local_id as provenance
   from dmx_sql_object a
   join dmx_sql_assoc_player p1
     on p1.assoc_id = a.local_id and p1.player_no = 1
   join dmx_sql_assoc_player p2
     on p2.assoc_id = a.local_id and p2.player_no = 2
  where a.type_uri = 'hyperdoc.assoc.has_provenance'
  order by subject, provenance;"
              :header t
              :column t))

(defun run-dmx-associative-mirror-smoke
    (&key (db-path (merge-pathnames #p"/tmp/dmx-associative-mirror-smoke.sqlite")))
  "Create a fresh mirror, seed provenance topics, and verify the basic graph tables."
  (initialize-dmx-associative-mirror :db-path db-path :clear t)
  (seed-kioskbeerli-provenance-topics db-path)
  (upsert-dmx-topic db-path
                    "topic:smoke:test"
                    "hyperdoc.test.topic"
                    "Smoke test"
                    :uri "hyperdoc:test/smoke"
                    :sync-state "local")
  (multiple-value-bind (stdout stderr exit-code)
      (sqlite-run db-path
                  "select local_id, object_kind, type_uri, value from dmx_sql_object where local_id = 'topic:smoke:test';")
    (unless (and (zerop exit-code)
                 (search "topic:smoke:test" stdout))
      (error "Smoke test failed:~%stdout=~A~%stderr=~A~%exit=~A"
             stdout stderr exit-code))
    (list :ok t :db-path db-path :stdout stdout)))
