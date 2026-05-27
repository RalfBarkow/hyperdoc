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
   #:persist-shop3-checklist-coverage-assertion-as-dmx-sql-topics
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

(define-condition shop3-checklist-coverage-assertion-parse-failure (error)
  ((assertion :initarg :assertion :reader parse-failure-assertion)
   (reason :initarg :reason :reader parse-failure-reason))
  (:report
   (lambda (condition stream)
     (format stream "Could not parse SHOP3 checklist coverage assertion ~S: ~A"
             (parse-failure-assertion condition)
             (parse-failure-reason condition)))))

(defun fail-shop3-checklist-coverage-parse (assertion reason)
  (error 'shop3-checklist-coverage-assertion-parse-failure
         :assertion assertion
         :reason reason))

(defun final-integer-in-string (string)
  (loop with start = nil
        with value = nil
        for index from 0 below (length string)
        for ch = (char string index)
        do (cond
             ((and (digit-char-p ch) (not start))
              (setf start index))
             ((and start (not (digit-char-p ch)))
              (setf value (parse-integer string :start start :end index)
                    start nil)))
        finally
           (return (if start
                       (parse-integer string :start start)
                       value))))

(defun parse-shop3-checklist-coverage-assertion (assertion)
  (unless (stringp assertion)
    (fail-shop3-checklist-coverage-parse assertion "assertion must be a string"))
  (let* ((normalized (string-downcase assertion))
         (count (final-integer-in-string normalized)))
    (unless (search "shop3 checklist projection" normalized)
      (fail-shop3-checklist-coverage-parse
       assertion
       "expected the phrase \"SHOP3 checklist projection\""))
    (unless (search "cover" normalized)
      (fail-shop3-checklist-coverage-parse
       assertion
       "expected a coverage relation"))
    (unless (search "local task" normalized)
      (fail-shop3-checklist-coverage-parse
       assertion
       "expected local tasks as the covered object"))
    (unless count
      (fail-shop3-checklist-coverage-parse
       assertion
       "expected a numeric local task count"))
    (list :projection-kind "SHOP3 checklist projection"
          :relation "covers"
          :count count
          :object "local tasks")))

(defun dmx-sql-scalar (db-path sql)
  (multiple-value-bind (stdout stderr exit-code)
      (sqlite-run db-path sql)
    (unless (zerop exit-code)
      (error "SQLite scalar query failed:~%~A~%~A" stdout stderr))
    (string-trim '(#\Space #\Tab #\Newline #\Return) stdout)))

(defun dmx-sql-object-exists-p (db-path local-id)
  (string= "1"
           (dmx-sql-scalar
            db-path
            (format nil
                    "select exists(select 1 from dmx_sql_object where local_id = ~A);"
                    (sql-literal local-id)))))

(defun dmx-sql-property-exists-p (db-path property-id)
  (string= "1"
           (dmx-sql-scalar
            db-path
            (format nil
                    "select exists(select 1 from dmx_sql_property where id = ~A);"
                    (sql-literal property-id)))))

(defun dmx-sql-topic-local-id (uri)
  (format nil "topic:~A" uri))

(defun dmx-sql-assoc-local-id (slug)
  (format nil "assoc:hyperdoc:kioskbeerli/sops-nix-secrets/~A" slug))

(defun dmx-sql-property-id (object-id property-uri)
  (format nil "property:~A:~A" object-id property-uri))

(defun record-dmx-sql-property
    (db-path object-id property-uri value &key replace-existing?)
  (let* ((property-id (dmx-sql-property-id object-id property-uri))
         (exists (dmx-sql-property-exists-p db-path property-id)))
    (when (or replace-existing? (not exists))
      (sqlite-run
       db-path
       (format nil
"INSERT OR ~A INTO dmx_sql_property(id, object_id, property_uri, value, value_json)
 VALUES(~A, ~A, ~A, ~A, NULL);"
               (if replace-existing? "REPLACE" "IGNORE")
               (sql-literal property-id)
               (sql-literal object-id)
               (sql-literal property-uri)
               (sql-literal value))))
    (cond
      ((not exists) :created)
      (replace-existing? :updated)
      (t :unchanged))))

(defun record-dmx-sql-topic
    (db-path local-id type-uri value &key uri payload-json replace-existing?)
  (let ((exists (dmx-sql-object-exists-p db-path local-id)))
    (when (or replace-existing? (not exists))
      (upsert-dmx-topic db-path local-id type-uri value
                        :uri uri
                        :payload-json payload-json
                        :sync-state "local")
      (when uri
        (upsert-dmx-sync-identity db-path local-id "hyperdoc-local-sql-mirror"
                                  :remote-uri uri
                                  :remote-type-uri type-uri
                                  :sync-state "mirror-provenance")))
    (cond
      ((not exists) :created)
      (replace-existing? :updated)
      (t :unchanged))))

(defun record-dmx-sql-assoc
    (db-path assoc-id assoc-type-uri player1-id player1-role player2-id player2-role
     &key value payload-json replace-existing?)
  (let ((exists (dmx-sql-object-exists-p db-path assoc-id)))
    (when (or replace-existing? (not exists))
      (upsert-dmx-assoc db-path assoc-id assoc-type-uri
                        player1-id player1-role
                        player2-id player2-role
                        :value value
                        :payload-json payload-json))
    (cond
      ((not exists) :created)
      (replace-existing? :updated)
      (t :unchanged))))

(defun count-record-states (states state)
  (count state states :test #'eq))

(defun persist-shop3-checklist-coverage-assertion-as-dmx-sql-topics
    (assertion
     &key
       (db-path *default-dmx-associative-mirror-path*)
       (subject-uri "hyperdoc:kioskbeerli/sops-nix-secrets/plan")
       (subject-label "Kioskbeerli sops-nix secrets plan")
       (plan-system ":kioskbeerli/sops-nix-secrets")
       checklist-count
       task-count
       evidence
       source
       replace-existing?)
  "Persist one parsed SHOP3 checklist coverage assertion into the local SQL mirror.

This function writes only to the DMX-shaped SQLite mirror named by DB-PATH. It
does not write live DMX or Neo4j, contact the Pi, run sops, run nixos-rebuild,
or execute any plan command."
  (let* ((parsed (parse-shop3-checklist-coverage-assertion assertion))
         (parsed-count (getf parsed :count))
         (checklist-count (or checklist-count parsed-count))
         (task-count (or task-count parsed-count)))
    (unless (= checklist-count parsed-count)
      (fail-shop3-checklist-coverage-parse
       assertion
       (format nil "checklist count ~D does not match parsed count ~D"
               checklist-count parsed-count)))
    (unless (= task-count parsed-count)
      (fail-shop3-checklist-coverage-parse
       assertion
       (format nil "task count ~D does not match parsed count ~D"
               task-count parsed-count)))
    (initialize-dmx-associative-mirror :db-path db-path)
    (let* ((projection-uri "hyperdoc:kioskbeerli/sops-nix-secrets/shop3-checklist-projection")
           (task-graph-uri "hyperdoc:kioskbeerli/sops-nix-secrets/local-task-graph")
           (assertion-uri
             (format nil
                     "hyperdoc:kioskbeerli/sops-nix-secrets/assertion/shop3-checklist-covers-~D-local-tasks"
                     parsed-count))
           (plan-topic (dmx-sql-topic-local-id subject-uri))
           (projection-topic (dmx-sql-topic-local-id projection-uri))
           (task-graph-topic (dmx-sql-topic-local-id task-graph-uri))
           (assertion-topic (dmx-sql-topic-local-id assertion-uri))
           (has-projection-assoc
             (dmx-sql-assoc-local-id "plan-has-shop3-checklist-projection"))
           (covers-assoc
             (dmx-sql-assoc-local-id "shop3-checklist-projection-covers-local-task-graph"))
           (asserts-assoc
             (dmx-sql-assoc-local-id "assertion-asserts-shop3-checklist-coverage"))
           (has-evidence-assoc
             (dmx-sql-assoc-local-id "assertion-has-evidence"))
           (topic-states
             (list
              (record-dmx-sql-topic db-path plan-topic
                                    "hyperdoc.shop3.plan"
                                    subject-label
                                    :uri subject-uri
                                    :payload-json
                                    (json-object :plan-system plan-system)
                                    :replace-existing? replace-existing?)
              (record-dmx-sql-topic db-path projection-topic
                                    "hyperdoc.shop3.checklist-projection"
                                    "SHOP3 checklist projection"
                                    :uri projection-uri
                                    :payload-json
                                    (json-object :checklist-count checklist-count
                                                 :execution-mode ":PLAN-ONLY")
                                    :replace-existing? replace-existing?)
              (record-dmx-sql-topic db-path task-graph-topic
                                    "hyperdoc.task-graph"
                                    "Local task graph"
                                    :uri task-graph-uri
                                    :payload-json
                                    (json-object :task-count task-count)
                                    :replace-existing? replace-existing?)
              (record-dmx-sql-topic db-path assertion-topic
                                    "hyperdoc.assertion"
                                    assertion
                                    :uri assertion-uri
                                    :payload-json
                                    (json-object :status "verified"
                                                 :evidence evidence
                                                 :source source
                                                 :boundary "plan-only; no command execution; no Pi mutation")
                                    :replace-existing? replace-existing?)))
           (property-states
             (list
              (record-dmx-sql-property db-path projection-topic
                                       "hyperdoc.property.checklist-count"
                                       checklist-count
                                       :replace-existing? replace-existing?)
              (record-dmx-sql-property db-path projection-topic
                                       "hyperdoc.property.execution-mode"
                                       ":PLAN-ONLY"
                                       :replace-existing? replace-existing?)
              (record-dmx-sql-property db-path projection-topic
                                       "hyperdoc.property.plan-system"
                                       plan-system
                                       :replace-existing? replace-existing?)
              (record-dmx-sql-property db-path task-graph-topic
                                       "hyperdoc.property.task-count"
                                       task-count
                                       :replace-existing? replace-existing?)
              (record-dmx-sql-property db-path assertion-topic
                                       "hyperdoc.property.status"
                                       "verified"
                                       :replace-existing? replace-existing?)
              (record-dmx-sql-property db-path assertion-topic
                                       "hyperdoc.property.evidence"
                                       evidence
                                       :replace-existing? replace-existing?)
              (record-dmx-sql-property db-path assertion-topic
                                       "hyperdoc.property.source"
                                       source
                                       :replace-existing? replace-existing?)
              (record-dmx-sql-property db-path assertion-topic
                                       "hyperdoc.property.boundary"
                                       "plan-only; no command execution; no Pi mutation"
                                       :replace-existing? replace-existing?)))
           (assoc-states
             (list
              (record-dmx-sql-assoc db-path has-projection-assoc
                                    "hyperdoc.relation.has-projection"
                                    plan-topic "hyperdoc.role.source"
                                    projection-topic "hyperdoc.role.target"
                                    :replace-existing? replace-existing?)
              (record-dmx-sql-assoc db-path covers-assoc
                                    "hyperdoc.relation.covers"
                                    projection-topic "hyperdoc.role.source"
                                    task-graph-topic "hyperdoc.role.target"
                                    :payload-json
                                    (json-object :checklist-count checklist-count
                                                 :task-count task-count
                                                 :coverage "complete")
                                    :replace-existing? replace-existing?)
              (record-dmx-sql-assoc db-path asserts-assoc
                                    "hyperdoc.relation.asserts"
                                    assertion-topic "hyperdoc.role.assertion"
                                    task-graph-topic "hyperdoc.role.target"
                                    :payload-json
                                    (json-object :asserted-association covers-assoc
                                                 :source projection-topic
                                                 :target task-graph-topic)
                                    :replace-existing? replace-existing?)
              (record-dmx-sql-assoc db-path has-evidence-assoc
                                    "hyperdoc.relation.has-evidence"
                                    assertion-topic "hyperdoc.role.assertion"
                                    assertion-topic "hyperdoc.role.evidence"
                                    :value "Evidence stored as assertion properties."
                                    :payload-json
                                    (json-object :evidence evidence
                                                 :source source)
                                    :replace-existing? replace-existing?))))
      (declare (ignore property-states))
      (record-dmx-sql-property db-path covers-assoc
                               "hyperdoc.property.checklist-count"
                               checklist-count
                               :replace-existing? replace-existing?)
      (record-dmx-sql-property db-path covers-assoc
                               "hyperdoc.property.task-count"
                               task-count
                               :replace-existing? replace-existing?)
      (record-dmx-sql-property db-path covers-assoc
                               "hyperdoc.property.coverage"
                               "complete"
                               :replace-existing? replace-existing?)
      (list :ok t
            :db-path db-path
            :assertion assertion
            :topics 4
            :associations 4
            :topics-created (count-record-states topic-states :created)
            :topics-updated (count-record-states topic-states :updated)
            :associations-created (count-record-states assoc-states :created)
            :associations-updated (count-record-states assoc-states :updated)
            :stable-uris (list subject-uri projection-uri task-graph-uri assertion-uri)
            :counts (list :checklist-count checklist-count
                          :task-count task-count)
            :checklist-count checklist-count
            :task-count task-count
            :coverage :complete
            :boundary :local-sql-mirror-only))))

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
