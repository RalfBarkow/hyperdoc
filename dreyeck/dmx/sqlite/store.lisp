;;;; Standalone DMX-shaped SQLite store.
;;;;
;;;; Ported from Hauptsache-local :hauptsache-dmx-sqlite at
;;;; d0bcff34c73af7fc4c6e394007ea4fbed4990f9b after the live SHOP3
;;;; planner selected :hyperdoc-dreyeck-owner.

(in-package #:dreyeck.dmx.sqlite)

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

CREATE TABLE IF NOT EXISTS dmx_sql_property_target (
  property_id TEXT PRIMARY KEY REFERENCES dmx_sql_property(id) ON DELETE CASCADE,
  target_object_id TEXT NOT NULL REFERENCES dmx_sql_object(local_id)
);

CREATE TABLE IF NOT EXISTS dmx_sql_property_observation (
  property_id TEXT PRIMARY KEY REFERENCES dmx_sql_property(id) ON DELETE CASCADE,
  sync_state TEXT NOT NULL DEFAULT 'local',
  modified_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dmx_sql_query_run (
  id TEXT PRIMARY KEY,
  query_kind TEXT NOT NULL,
  local_object_id TEXT REFERENCES dmx_sql_object(local_id),
  status TEXT NOT NULL DEFAULT 'observed',
  payload_json TEXT,
  result_json TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  modified_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dmx_sql_journal_query_run (
  journal_id TEXT PRIMARY KEY REFERENCES dmx_sql_sync_journal(id) ON DELETE CASCADE,
  query_run_id TEXT NOT NULL REFERENCES dmx_sql_query_run(id)
);
")

(defun sqlite-run
    (db-path sql &key (header nil) (column nil) separator (ignore-error-status t))
  "Run SQL against DB-PATH through the sqlite3 executable.
Return the usual UIOP values: stdout, stderr, exit code. The call is non-interactive."
  (let ((args (append (when header (list "-header"))
                      (when column (list "-column"))
                      (when separator (list "-separator" separator))
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

(defun sqlite-true-p (value)
  (string= "1"
           (string-trim '(#\Space #\Tab #\Newline #\Return)
                        (or value ""))))

(defun dmx-sql-exists-p (db-path sql)
  (sqlite-true-p (dmx-sql-scalar db-path sql)))

(defun sql-is-clause (column value)
  (format nil "~A IS ~A" column (sql-literal value)))

(defun sql-integer-or-null (value)
  (if value
      (format nil "~A" value)
      "NULL"))

(defun dmx-sql-record-state (exists-p content-equal-p replace-existing?)
  (cond
    ((not exists-p) :created)
    (content-equal-p :unchanged)
    (replace-existing? :updated)
    (t :conflict)))

(defun dmx-sql-object-row (db-path local-id)
  "Return a lightweight plist for LOCAL-ID, or NIL when the object is absent."
  (when (dmx-sql-object-exists-p db-path local-id)
    (flet ((column (name)
             (let ((value
                     (dmx-sql-scalar
                      db-path
                      (format nil
                              "select coalesce(~A, '') from dmx_sql_object where local_id = ~A;"
                              name
                              (sql-literal local-id)))))
               (unless (string= value "") value))))
      (list :local-id local-id
            :object-kind (column "object_kind")
            :uri (column "uri")
            :type-uri (column "type_uri")
            :value (column "value")
            :payload-json (column "payload_json")
            :sync-state (column "sync_state")))))

(defun dmx-sql-object-content-equal-p
    (db-path local-id object-kind uri type-uri value payload-json sync-state)
  (dmx-sql-exists-p
   db-path
   (format nil
           "select exists(select 1 from dmx_sql_object where local_id = ~A and ~A and ~A and ~A and ~A and ~A and ~A);"
           (sql-literal local-id)
           (sql-is-clause "object_kind" object-kind)
           (sql-is-clause "uri" uri)
           (sql-is-clause "type_uri" type-uri)
           (sql-is-clause "value" value)
           (sql-is-clause "payload_json" payload-json)
           (sql-is-clause "sync_state" sync-state))))

(defun dmx-sql-object-uri-conflict-p (db-path local-id uri)
  (and uri
       (dmx-sql-exists-p
        db-path
        (format nil
                "select exists(select 1 from dmx_sql_object where uri = ~A and local_id <> ~A);"
                (sql-literal uri)
                (sql-literal local-id)))))

(defun %put-dmx-topic-row!
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

(defun normalize-dmx-association-players (players)
  (loop for player in players
        for index from 1
        collect
        (destructuring-bind
            (&key player-no role-type-uri (player-kind "topic") player-local-id)
            player
          (unless role-type-uri
            (error "DMX association player ~D has no role type URI." index))
          (unless player-local-id
            (error "DMX association player ~D has no player local id." index))
          (list :player-no (or player-no index)
                :role-type-uri role-type-uri
                :player-kind player-kind
                :player-local-id player-local-id))))

(defun topic-association-players
    (player1-id player1-role player2-id player2-role)
  (list (list :player-no 1
              :role-type-uri player1-role
              :player-kind "topic"
              :player-local-id player1-id)
        (list :player-no 2
              :role-type-uri player2-role
              :player-kind "topic"
              :player-local-id player2-id)))

(defun dmx-sql-association-players-equal-p (db-path assoc-id players)
  (let ((normalized (normalize-dmx-association-players players)))
    (dmx-sql-exists-p
     db-path
     (format nil
             "select case when (select count(*) from dmx_sql_assoc_player where assoc_id = ~A) = ~D and ~{~A~^ and ~} then 1 else 0 end;"
             (sql-literal assoc-id)
             (length normalized)
             (loop for player in normalized
                   collect
                   (format nil
                           "exists(select 1 from dmx_sql_assoc_player where assoc_id = ~A and player_no = ~D and ~A and ~A and ~A)"
                           (sql-literal assoc-id)
                           (getf player :player-no)
                           (sql-is-clause "role_type_uri"
                                          (getf player :role-type-uri))
                           (sql-is-clause "player_kind"
                                          (getf player :player-kind))
                           (sql-is-clause "player_local_id"
                                          (getf player :player-local-id))))))))

(defun %put-dmx-association-row!
    (db-path assoc-id assoc-type-uri players &key value payload-json)
  (let* ((normalized (normalize-dmx-association-players players))
         (player-sql
           (with-output-to-string (stream)
             (dolist (player normalized)
               (format stream
                       "INSERT OR REPLACE INTO dmx_sql_assoc_player(assoc_id, player_no, role_type_uri, player_kind, player_local_id)
VALUES(~A, ~D, ~A, ~A, ~A);~%"
                       (sql-literal assoc-id)
                       (getf player :player-no)
                       (sql-literal (getf player :role-type-uri))
                       (sql-literal (getf player :player-kind))
                       (sql-literal (getf player :player-local-id)))))))
    (sqlite-run
     db-path
     (format nil
"BEGIN;
INSERT OR REPLACE INTO dmx_sql_object(local_id, object_kind, uri, type_uri, value, payload_json, sync_state, modified_at)
VALUES(~A, 'assoc', NULL, ~A, ~A, ~A, 'local', CURRENT_TIMESTAMP);
INSERT OR REPLACE INTO dmx_sql_assoc(local_id) VALUES(~A);
DELETE FROM dmx_sql_assoc_player WHERE assoc_id = ~A;
~ACOMMIT;"
             (sql-literal assoc-id)
             (sql-literal assoc-type-uri)
             (sql-literal value)
             (sql-literal payload-json)
             (sql-literal assoc-id)
             (sql-literal assoc-id)
             player-sql))))

(defun dmx-sync-identity-id (local-object-id host remote-id remote-uri)
  (format nil "~A:~A" host (or remote-id remote-uri local-object-id)))

(defun dmx-sync-identity-identity-clauses
    (local-object-id host remote-id remote-uri)
  (remove
   nil
   (list
    (format nil "id = ~A"
            (sql-literal
             (dmx-sync-identity-id local-object-id host remote-id remote-uri)))
    (when remote-id
      (format nil "(host = ~A and remote_id = ~A)"
              (sql-literal host)
              (sql-integer-or-null remote-id)))
    (when remote-uri
      (format nil "(host = ~A and remote_uri = ~A)"
              (sql-literal host)
              (sql-literal remote-uri))))))

(defun sql-or-clauses (clauses)
  (format nil "~{~A~^ or ~}" clauses))

(defun dmx-sql-sync-identity-exists-p
    (db-path local-object-id host remote-id remote-uri)
  (let ((identity-clauses
          (dmx-sync-identity-identity-clauses
           local-object-id host remote-id remote-uri)))
    (dmx-sql-exists-p
     db-path
     (format nil
             "select exists(select 1 from dmx_sql_sync_identity where ~A);"
             (sql-or-clauses identity-clauses)))))

(defun dmx-sql-sync-identity-content-equal-p
    (db-path local-object-id host remote-id remote-uri remote-type-uri sync-state)
  (let ((identity-clauses
          (dmx-sync-identity-identity-clauses
           local-object-id host remote-id remote-uri)))
    (dmx-sql-exists-p
     db-path
     (format nil
             "select exists(select 1 from dmx_sql_sync_identity where (~A) and ~A and ~A and remote_id IS ~A and ~A and ~A and ~A);"
             (sql-or-clauses identity-clauses)
             (sql-is-clause "local_object_id" local-object-id)
             (sql-is-clause "host" host)
             (sql-integer-or-null remote-id)
             (sql-is-clause "remote_uri" remote-uri)
             (sql-is-clause "remote_type_uri" remote-type-uri)
             (sql-is-clause "sync_state" sync-state)))))

(defun %put-dmx-sync-identity-row!
    (db-path local-object-id host &key remote-id remote-uri remote-type-uri sync-state)
  (sqlite-run
   db-path
   (format nil
"INSERT OR REPLACE INTO dmx_sql_sync_identity(
   id, local_object_id, host, remote_id, remote_uri, remote_type_uri, last_seen_at, sync_state)
 VALUES(~A, ~A, ~A, ~A, ~A, ~A, CURRENT_TIMESTAMP, ~A);"
           (sql-literal (dmx-sync-identity-id local-object-id host remote-id remote-uri))
           (sql-literal local-object-id)
           (sql-literal host)
           (sql-integer-or-null remote-id)
           (sql-literal remote-uri)
           (sql-literal remote-type-uri)
           (sql-literal (or sync-state "observed")))))

(defun record-dmx-topic-value
    (db-path local-id type-uri value &key uri payload-json sync-state replace-existing?)
  "Record a topic value in the local DMX-shaped SQLite mirror.
Return :CREATED, :UNCHANGED, :CONFLICT, or :UPDATED. Existing different
content is never replaced unless REPLACE-EXISTING? is true."
  (let* ((effective-sync-state (or sync-state "local"))
         (exists (dmx-sql-object-exists-p db-path local-id))
         (same (and exists
                    (dmx-sql-object-content-equal-p
                     db-path local-id "topic" uri type-uri value payload-json
                     effective-sync-state)))
         (uri-conflict (dmx-sql-object-uri-conflict-p db-path local-id uri))
         (state (if uri-conflict
                    (if replace-existing? :updated :conflict)
                    (dmx-sql-record-state exists same replace-existing?))))
    (when (member state '(:created :updated))
      (%put-dmx-topic-row! db-path local-id type-uri value
                           :uri uri
                           :payload-json payload-json
                           :sync-state effective-sync-state))
    state))

(defun record-dmx-association-value
    (db-path assoc-id assoc-type-uri &key players value payload-json replace-existing?)
  "Record an association value with role-bearing PLAYERS.
PLAYERS is a list of plists with :PLAYER-NO, :ROLE-TYPE-URI, :PLAYER-KIND, and
:PLAYER-LOCAL-ID. This keeps the API ready for n-ary associations even though
current callers mostly record binary topic associations."
  (unless players
    (error "DMX association ~A must have at least one player." assoc-id))
  (let* ((normalized (normalize-dmx-association-players players))
         (exists (dmx-sql-object-exists-p db-path assoc-id))
         (same (and exists
                    (dmx-sql-object-content-equal-p
                     db-path assoc-id "assoc" nil assoc-type-uri value
                     payload-json "local")
                    (dmx-sql-association-players-equal-p
                     db-path assoc-id normalized)))
         (state (dmx-sql-record-state exists same replace-existing?)))
    (ensure-dmx-association-player-integrity db-path normalized)
    (when (member state '(:created :updated))
      (%put-dmx-association-row! db-path assoc-id assoc-type-uri normalized
                                 :value value
                                 :payload-json payload-json))
    state))

(defun record-dmx-sync-identity-value
    (db-path local-object-id host &key remote-id remote-uri remote-type-uri sync-state
                                  replace-existing?)
  "Record a local-to-DMX identity correspondence in the SQLite mirror."
  (let* ((effective-sync-state (or sync-state "observed"))
         (exists (dmx-sql-sync-identity-exists-p
                  db-path local-object-id host remote-id remote-uri))
         (same (and exists
                    (dmx-sql-sync-identity-content-equal-p
                     db-path local-object-id host remote-id remote-uri
                     remote-type-uri effective-sync-state)))
         (state (dmx-sql-record-state exists same replace-existing?)))
    (when (member state '(:created :updated))
      (%put-dmx-sync-identity-row! db-path local-object-id host
                                   :remote-id remote-id
                                   :remote-uri remote-uri
                                   :remote-type-uri remote-type-uri
                                   :sync-state effective-sync-state))
    state))

(defun dmx-sql-record-content-state (db-path id table equal-sql replace-existing?)
  (dmx-sql-record-state
   (dmx-sql-exists-p db-path
                      (format nil "select exists(select 1 from ~A where id = ~A);"
                              table (sql-literal id)))
   (dmx-sql-exists-p db-path equal-sql)
   replace-existing?))

(defun ensure-dmx-sql-object-reference (db-path local-id label)
  (unless (dmx-sql-object-exists-p db-path local-id)
    (error "DMX ~A ~A does not name an existing object." label local-id)))

(defun record-dmx-property-value
    (db-path property-id object-id property-uri
     &key value value-json target-object-id sync-state replace-existing?)
  "Record a generic property value and optional target-object reference."
  (ensure-dmx-sql-object-reference db-path object-id "property owner")
  (when target-object-id
    (ensure-dmx-sql-object-reference db-path target-object-id "property target"))
  (let* ((effective-state (or sync-state "local"))
         (same-sql
           (format nil
                   "select exists(select 1 from dmx_sql_property p left join dmx_sql_property_target t on t.property_id = p.id left join dmx_sql_property_observation o on o.property_id = p.id where p.id = ~A and ~A and ~A and ~A and ~A and ~A and ~A);"
                   (sql-literal property-id)
                   (sql-is-clause "p.object_id" object-id)
                   (sql-is-clause "p.property_uri" property-uri)
                   (sql-is-clause "p.value" value)
                   (sql-is-clause "p.value_json" value-json)
                   (sql-is-clause "t.target_object_id" target-object-id)
                   (sql-is-clause "o.sync_state" effective-state)))
         (state (dmx-sql-record-content-state
                 db-path property-id "dmx_sql_property" same-sql replace-existing?)))
    (when (member state '(:created :updated))
      (multiple-value-bind (stdout stderr exit-code)
          (sqlite-run
           db-path
           (format nil
                   "BEGIN; INSERT OR REPLACE INTO dmx_sql_property(id, object_id, property_uri, value, value_json) VALUES(~A, ~A, ~A, ~A, ~A); DELETE FROM dmx_sql_property_target WHERE property_id = ~A; ~A INSERT OR REPLACE INTO dmx_sql_property_observation(property_id, sync_state, modified_at) VALUES(~A, ~A, CURRENT_TIMESTAMP); COMMIT;"
                   (sql-literal property-id) (sql-literal object-id)
                   (sql-literal property-uri) (sql-literal value)
                   (sql-literal value-json) (sql-literal property-id)
                   (if target-object-id
                       (format nil "INSERT INTO dmx_sql_property_target(property_id, target_object_id) VALUES(~A, ~A);"
                               (sql-literal property-id) (sql-literal target-object-id))
                       "")
                   (sql-literal property-id) (sql-literal effective-state)))
        (unless (zerop exit-code)
          (error "Could not record DMX property:~%~A~%~A" stdout stderr))))
    state))

(defun record-dmx-query-run-value
    (db-path run-id query-kind &key local-object-id status payload-json result-json replace-existing?)
  "Record a durable generic query-run observation."
  (when local-object-id
    (ensure-dmx-sql-object-reference db-path local-object-id "query-run owner"))
  (let* ((effective-status (or status "observed"))
         (same-sql
           (format nil
                   "select exists(select 1 from dmx_sql_query_run where id = ~A and ~A and ~A and ~A and ~A and ~A);"
                   (sql-literal run-id) (sql-is-clause "query_kind" query-kind)
                   (sql-is-clause "local_object_id" local-object-id)
                   (sql-is-clause "status" effective-status)
                   (sql-is-clause "payload_json" payload-json)
                   (sql-is-clause "result_json" result-json)))
         (state (dmx-sql-record-content-state
                 db-path run-id "dmx_sql_query_run" same-sql replace-existing?)))
    (when (member state '(:created :updated))
      (sqlite-run db-path
                  (format nil
                          "INSERT OR REPLACE INTO dmx_sql_query_run(id, query_kind, local_object_id, status, payload_json, result_json, modified_at) VALUES(~A, ~A, ~A, ~A, ~A, ~A, CURRENT_TIMESTAMP);"
                          (sql-literal run-id) (sql-literal query-kind)
                          (sql-literal local-object-id) (sql-literal effective-status)
                          (sql-literal payload-json) (sql-literal result-json))))
    state))

(defun record-dmx-journal-entry-value
    (db-path journal-id journal-kind action status
     &key local-object-id host remote-id detail payload-json query-run-id replace-existing?)
  "Record a generic journal observation, optionally linked to a query run."
  (when local-object-id
    (ensure-dmx-sql-object-reference db-path local-object-id "journal owner"))
  (when query-run-id
    (unless (dmx-sql-exists-p db-path
                              (format nil "select exists(select 1 from dmx_sql_query_run where id = ~A);"
                                      (sql-literal query-run-id)))
      (error "DMX journal query run ~A is absent." query-run-id)))
  (let* ((same-sql
           (format nil
                   "select exists(select 1 from dmx_sql_sync_journal j left join dmx_sql_journal_query_run q on q.journal_id = j.id where j.id = ~A and ~A and ~A and ~A and ~A and ~A and ~A and ~A and ~A);"
                   (sql-literal journal-id) (sql-is-clause "j.journal_kind" journal-kind)
                   (sql-is-clause "j.action" action) (sql-is-clause "j.status" status)
                   (sql-is-clause "j.local_object_id" local-object-id)
                   (sql-is-clause "j.host" host) (sql-is-clause "j.remote_id" remote-id)
                   (sql-is-clause "j.detail" detail) (sql-is-clause "q.query_run_id" query-run-id)))
         (state (dmx-sql-record-content-state
                 db-path journal-id "dmx_sql_sync_journal" same-sql replace-existing?)))
    (when (member state '(:created :updated))
      (sqlite-run db-path
                  (format nil
                          "BEGIN; INSERT OR REPLACE INTO dmx_sql_sync_journal(id, journal_kind, local_object_id, host, remote_id, action, status, detail, payload_json) VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A); DELETE FROM dmx_sql_journal_query_run WHERE journal_id = ~A; ~A COMMIT;"
                          (sql-literal journal-id) (sql-literal journal-kind)
                          (sql-literal local-object-id) (sql-literal host)
                          (sql-integer-or-null remote-id) (sql-literal action)
                          (sql-literal status) (sql-literal detail)
                          (sql-literal payload-json) (sql-literal journal-id)
                          (if query-run-id
                              (format nil "INSERT INTO dmx_sql_journal_query_run(journal_id, query_run_id) VALUES(~A, ~A);"
                                      (sql-literal journal-id) (sql-literal query-run-id))
                              ""))))
    state))

(defun dmx-sql-scalar (db-path sql)
  (multiple-value-bind (stdout stderr exit-code)
      (sqlite-run db-path sql :separator (string #\Tab))
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

(defun dmx-sql-association-has-role-bearing-players-p (db-path assoc-id)
  "Return true only when ASSOC-ID has persisted players with nonempty roles."
  (dmx-sql-exists-p
   db-path
   (format nil
           "select exists(select 1 from dmx_sql_assoc a join dmx_sql_assoc_player p on p.assoc_id = a.local_id where a.local_id = ~A and p.role_type_uri is not null and p.role_type_uri <> '');"
           (sql-literal assoc-id))))

(defun dmx-sql-relationship-p (db-path left-local-id right-local-id)
  "Relationship evidence requires a role-bearing association, not just topics."
  (dmx-sql-exists-p
   db-path
   (format nil
           "select exists(select 1 from dmx_sql_assoc a join dmx_sql_assoc_player left_player on left_player.assoc_id = a.local_id join dmx_sql_assoc_player right_player on right_player.assoc_id = a.local_id where left_player.player_local_id = ~A and right_player.player_local_id = ~A and left_player.player_no <> right_player.player_no and left_player.role_type_uri <> '' and right_player.role_type_uri <> '');"
           (sql-literal left-local-id)
           (sql-literal right-local-id))))

(defun ensure-dmx-association-player-integrity (db-path players)
  "Reject association players that do not name an existing object of their kind."
  (let ((object-keys nil))
    (dolist (player players)
      (let ((player-local-id (getf player :player-local-id))
            (player-kind (getf player :player-kind))
            (role-type-uri (getf player :role-type-uri)))
        (unless (member player-kind '("topic" "assoc") :test #'string=)
          (error "DMX association player ~A has invalid kind ~S."
                 player-local-id player-kind))
        (unless (and role-type-uri (plusp (length role-type-uri)))
          (error "DMX association player ~A must have a role type URI."
                 player-local-id))
        (pushnew (list player-local-id player-kind)
                 object-keys
                 :test #'equal)))
    (let* ((object-keys (nreverse object-keys))
           (where
             (and object-keys
                  (format nil "~{(~A)~^ or ~}"
                          (loop for (player-local-id player-kind)
                                  in object-keys
                                collect
                                (format nil
                                        "local_id = ~A and object_kind = ~A"
                                        (sql-literal player-local-id)
                                        (sql-literal player-kind))))))
           (existing-count
             (if where
                 (parse-integer
                  (dmx-sql-scalar
                   db-path
                   (format nil
                           "select count(*) from dmx_sql_object where ~A;"
                           where)))
                 0)))
      (when (/= existing-count (length object-keys))
        ;; This branch is exceptional; use precise per-player diagnostics only
        ;; after the batched validation says something is missing.
        (dolist (player players)
          (let ((player-local-id (getf player :player-local-id))
                (player-kind (getf player :player-kind)))
            (unless (dmx-sql-exists-p
                     db-path
                     (format nil
                             "select exists(select 1 from dmx_sql_object where local_id = ~A and object_kind = ~A);"
                             (sql-literal player-local-id)
                             (sql-literal player-kind)))
              (error "DMX association player ~A does not name an existing ~A."
                     player-local-id player-kind))))))))

(defun dmx-sql-counts (&key (db-path *default-dmx-associative-mirror-path*))
  "Return SQLite's object-kind count table for the DMX-shaped store."
  (sqlite-run db-path
              "select object_kind, count(*) as n from dmx_sql_object group by object_kind order by object_kind;"
              :header t
              :column t))

;;;; Read-only logical DMX query protocol

(defun dmx-sqlite-split-tab-row (line)
  "Split LINE on tabs while preserving empty SQLite result columns."
  (loop with start = 0
        for tab = (position #\Tab line :start start)
        collect (subseq line start (or tab (length line)))
        while tab
        do (setf start (1+ tab))))

(defun dmx-sqlite-query-rows (db-path sql)
  "Run a tab-separated read query and return its rows as lists of strings."
  (multiple-value-bind (stdout stderr exit-code)
      (sqlite-run db-path sql :separator (string #\Tab))
    (unless (zerop exit-code)
      (error "DMX SQLite logical query failed:~%~A~%~A" stdout stderr))
    (loop for line in (uiop:split-string stdout :separator '(#\Newline))
          unless (string= line "")
            collect (dmx-sqlite-split-tab-row line))))

(defun dmx-sqlite-nullable-string (value)
  (unless (string= value "") value))

(defun dmx-sqlite-nullable-integer (value)
  (unless (string= value "")
    (parse-integer value)))

(defun dmx-sqlite-object-from-row (row)
  (destructuring-bind
      (local-id object-kind uri type-uri value payload-json sync-state)
      row
    (list :local-id local-id
          :object-kind object-kind
          :uri (dmx-sqlite-nullable-string uri)
          :type-uri type-uri
          :value (dmx-sqlite-nullable-string value)
          :payload-json (dmx-sqlite-nullable-string payload-json)
          :sync-state (dmx-sqlite-nullable-string sync-state))))

(defun dmx-sqlite-object-rows (db-path &key where (order-by "local_id"))
  (mapcar #'dmx-sqlite-object-from-row
          (dmx-sqlite-query-rows
           db-path
           (format nil
                   "select local_id, object_kind, coalesce(uri, ''), type_uri, coalesce(value, ''), coalesce(payload_json, ''), coalesce(sync_state, '') from dmx_sql_object where ~A order by ~A;"
                   (or where "1 = 1")
                   order-by))))

(defun dmx-sqlite-object (db-path local-id)
  "Return the logical DMX object named by LOCAL-ID, or NIL.

The result is a property list and deliberately does not expose SQLite rows or
table names to callers."
  (first
   (dmx-sqlite-object-rows
    db-path
    :where (format nil "local_id = ~A" (sql-literal local-id)))))

(defun dmx-sqlite-topic (db-path local-id)
  "Return the topic named by LOCAL-ID, or NIL when it is absent or non-topic."
  (let ((object (dmx-sqlite-object db-path local-id)))
    (when (and object
               (string= (getf object :object-kind) "topic"))
      object)))

(defun dmx-sqlite-string-in-clause (column values)
  (when values
    (format nil "~A in (~{~A~^, ~})"
            column
            (mapcar #'sql-literal values))))

(defun dmx-sqlite-topics (db-path &key type-uri include-type-uris)
  "List logical topics in stable order.

INCLUDE-TYPE-URIS additionally admits objects of named DMX types.  This lets
projections treat selected trace or task objects as nodes without learning the
physical store layout."
  (let* ((topic-or-included
           (or (dmx-sqlite-string-in-clause "type_uri" include-type-uris)
               "0 = 1"))
         (clauses
           (list (format nil "(object_kind = 'topic' or ~A)" topic-or-included)
                 (when type-uri
                   (format nil "type_uri = ~A" (sql-literal type-uri))))))
    (dmx-sqlite-object-rows
     db-path
     :where (format nil "~{~A~^ and ~}" (remove nil clauses))
     :order-by "object_kind, type_uri, local_id")))

(defun dmx-sqlite-association-players (db-path assoc-id)
  "Return ASSOC-ID's role-bearing player descriptions in player-number order."
  (loop for row in
        (dmx-sqlite-query-rows
         db-path
         (format nil
                 "select player_no, role_type_uri, player_kind, player_local_id from dmx_sql_assoc_player where assoc_id = ~A order by player_no;"
                 (sql-literal assoc-id)))
        collect
        (destructuring-bind (player-no role-type-uri player-kind player-local-id) row
          (list :player-no (parse-integer player-no)
                :role-type-uri (dmx-sqlite-nullable-string role-type-uri)
                :player-kind player-kind
                :player-local-id player-local-id))))

(defun dmx-sqlite-association (db-path assoc-id)
  "Return a logical association with its ordered players, or NIL."
  (let ((object (dmx-sqlite-object db-path assoc-id)))
    (when (and object
               (string= (getf object :object-kind) "assoc"))
      (append object
              (list :players (dmx-sqlite-association-players db-path assoc-id))))))

(defun dmx-sqlite-associations (db-path &key type-uri)
  "List logical associations with ordered role-bearing players."
  (loop for object in
        (dmx-sqlite-object-rows
         db-path
         :where (if type-uri
                    (format nil "object_kind = 'assoc' and type_uri = ~A"
                            (sql-literal type-uri))
                    "object_kind = 'assoc'")
         :order-by "type_uri, local_id")
        collect (dmx-sqlite-association db-path (getf object :local-id))))

(defun dmx-sqlite-role-bearing-association-ids-for-object (db-path local-id)
  (mapcar #'first
          (dmx-sqlite-query-rows
           db-path
           (format nil
                   "select distinct a.local_id from dmx_sql_assoc a join dmx_sql_assoc_player p on p.assoc_id = a.local_id where p.player_local_id = ~A and p.role_type_uri is not null and p.role_type_uri <> '' and exists (select 1 from dmx_sql_assoc_player other where other.assoc_id = a.local_id and other.player_no <> p.player_no and other.role_type_uri is not null and other.role_type_uri <> '') order by a.local_id;"
                   (sql-literal local-id)))))

(defun dmx-sqlite-object-neighborhood (db-path local-id)
  "Return LOCAL-ID, its role-bearing associations, and distinct neighbor objects.

An isolated topic returns an empty association and neighbor list.  This keeps
topic existence separate from relationship evidence."
  (let* ((object (dmx-sqlite-object db-path local-id))
         (association-ids
           (and object
                (dmx-sqlite-role-bearing-association-ids-for-object db-path local-id)))
         (associations
           (mapcar (lambda (assoc-id) (dmx-sqlite-association db-path assoc-id))
                   association-ids))
         (neighbor-ids
           (remove-duplicates
            (loop for association in associations
                  append (loop for player in (getf association :players)
                               for player-id = (getf player :player-local-id)
                               unless (string= player-id local-id)
                                 collect player-id))
            :test #'string=)))
    (when object
      (list :object object
            :associations associations
            :neighbors (remove nil
                               (mapcar (lambda (neighbor-id)
                                         (dmx-sqlite-object db-path neighbor-id))
                                       neighbor-ids))))))

(defun dmx-sqlite-relationship-exists-p (db-path left-local-id right-local-id)
  "Return true only for an association with two distinct role-bearing players."
  (dmx-sql-relationship-p db-path left-local-id right-local-id))

(defun dmx-sqlite-sync-identities
    (db-path &key local-object-id host remote-id remote-uri)
  "List logical local-to-remote identity correspondences matching supplied keys."
  (let ((clauses
          (remove
           nil
           (list (when local-object-id
                   (format nil "local_object_id = ~A" (sql-literal local-object-id)))
                 (when host
                   (format nil "host = ~A" (sql-literal host)))
                 (when remote-id
                   (format nil "remote_id = ~A" (sql-integer-or-null remote-id)))
                 (when remote-uri
                   (format nil "remote_uri = ~A" (sql-literal remote-uri)))))))
    (loop for row in
          (dmx-sqlite-query-rows
           db-path
           (format nil
                   "select id, local_object_id, host, coalesce(remote_id, ''), coalesce(remote_uri, ''), coalesce(remote_type_uri, ''), coalesce(last_seen_hash, ''), coalesce(last_seen_at, ''), sync_state from dmx_sql_sync_identity where ~A order by host, remote_id, remote_uri, id;"
                   (if clauses
                       (format nil "~{~A~^ and ~}" clauses)
                       "1 = 1")))
          collect
          (destructuring-bind
              (id local-id identity-host identity-remote-id identity-remote-uri
               remote-type-uri last-seen-hash last-seen-at sync-state)
              row
            (list :id id
                  :local-object-id local-id
                  :host identity-host
                  :remote-id (dmx-sqlite-nullable-integer identity-remote-id)
                  :remote-uri (dmx-sqlite-nullable-string identity-remote-uri)
                  :remote-type-uri (dmx-sqlite-nullable-string remote-type-uri)
                  :last-seen-hash (dmx-sqlite-nullable-string last-seen-hash)
                  :last-seen-at (dmx-sqlite-nullable-string last-seen-at)
                  :sync-state sync-state)))))

(defun dmx-sqlite-properties
    (db-path &key object-id property-uri target-object-id)
  "List generic properties with owner, scalar value, target, and observation state."
  (let ((clauses
          (remove nil
                  (list (when object-id
                          (format nil "p.object_id = ~A" (sql-literal object-id)))
                        (when property-uri
                          (format nil "p.property_uri = ~A" (sql-literal property-uri)))
                        (when target-object-id
                          (format nil "t.target_object_id = ~A"
                                  (sql-literal target-object-id)))))))
    (loop for row in
          (dmx-sqlite-query-rows
           db-path
           (format nil
                   "select p.id, p.object_id, p.property_uri, coalesce(p.value, ''), coalesce(p.value_json, ''), coalesce(t.target_object_id, ''), coalesce(o.sync_state, 'local') from dmx_sql_property p left join dmx_sql_property_target t on t.property_id = p.id left join dmx_sql_property_observation o on o.property_id = p.id where ~A order by p.object_id, p.property_uri, p.id;"
                   (if clauses (format nil "~{~A~^ and ~}" clauses) "1 = 1")))
          collect
          (destructuring-bind (id owner-uri key value value-json target sync-state) row
            (list :id id :object-id owner-uri :property-uri key
                  :value (dmx-sqlite-nullable-string value)
                  :value-json (dmx-sqlite-nullable-string value-json)
                  :target-object-id (dmx-sqlite-nullable-string target)
                  :sync-state sync-state)))))

(defun dmx-sqlite-object-properties (db-path object-id)
  (dmx-sqlite-properties db-path :object-id object-id))

(defun dmx-sqlite-property-values (db-path &key object-id property-uri)
  (dmx-sqlite-properties db-path :object-id object-id :property-uri property-uri))

(defun dmx-sqlite-query-runs (db-path &key run-id local-object-id query-kind status)
  "List durable generic query-run observations."
  (let ((clauses
          (remove nil
                  (list (when run-id
                          (format nil "id = ~A" (sql-literal run-id)))
                        (when local-object-id
                          (format nil "local_object_id = ~A" (sql-literal local-object-id)))
                        (when query-kind
                          (format nil "query_kind = ~A" (sql-literal query-kind)))
                        (when status
                          (format nil "status = ~A" (sql-literal status)))))))
    (loop for row in
          (dmx-sqlite-query-rows
           db-path
           (format nil
                   "select id, query_kind, coalesce(local_object_id, ''), status, coalesce(payload_json, ''), coalesce(result_json, '') from dmx_sql_query_run where ~A order by id;"
                   (if clauses (format nil "~{~A~^ and ~}" clauses) "1 = 1")))
          collect
          (destructuring-bind (id kind object status-value payload result) row
            (list :id id :query-kind kind
                  :local-object-id (dmx-sqlite-nullable-string object)
                  :status status-value
                  :payload-json (dmx-sqlite-nullable-string payload)
                  :result-json (dmx-sqlite-nullable-string result))))))

(defun dmx-sqlite-query-run (db-path run-id)
  (first (dmx-sqlite-query-runs db-path :run-id run-id)))

(defun dmx-sqlite-journal-entries (db-path &key local-object-id query-run-id)
  "List generic journal observations and optional query-run links."
  (let ((clauses
          (remove nil
                  (list (when local-object-id
                          (format nil "j.local_object_id = ~A" (sql-literal local-object-id)))
                        (when query-run-id
                          (format nil "q.query_run_id = ~A" (sql-literal query-run-id)))))))
    (loop for row in
          (dmx-sqlite-query-rows
           db-path
           (format nil
                   "select j.id, j.journal_kind, coalesce(j.local_object_id, ''), coalesce(j.host, ''), coalesce(j.remote_id, ''), j.action, j.status, coalesce(j.detail, ''), coalesce(j.payload_json, ''), coalesce(q.query_run_id, '') from dmx_sql_sync_journal j left join dmx_sql_journal_query_run q on q.journal_id = j.id where ~A order by j.id;"
                   (if clauses (format nil "~{~A~^ and ~}" clauses) "1 = 1")))
          collect
          (destructuring-bind (id kind object host remote action status detail payload run) row
            (list :id id :journal-kind kind
                  :local-object-id (dmx-sqlite-nullable-string object)
                  :host (dmx-sqlite-nullable-string host)
                  :remote-id (dmx-sqlite-nullable-integer remote)
                  :action action :status status
                  :detail (dmx-sqlite-nullable-string detail)
                  :payload-json (dmx-sqlite-nullable-string payload)
                  :query-run-id (dmx-sqlite-nullable-string run))))))

(defun dmx-sqlite-sync-identities-for-remote (db-path host &key remote-id remote-uri)
  (dmx-sqlite-sync-identities db-path :host host :remote-id remote-id :remote-uri remote-uri))

(defun dmx-sqlite-sync-identity-conflicts (db-path)
  "Return impossible imported remote identities that point at multiple local objects."
  (loop for row in
        (dmx-sqlite-query-rows
         db-path
         "select host, coalesce(remote_id, ''), coalesce(remote_uri, ''), count(distinct local_object_id) from dmx_sql_sync_identity group by host, remote_id, remote_uri having count(distinct local_object_id) > 1 order by host;")
        collect
        (destructuring-bind (host remote-id remote-uri count) row
          (list :host host :remote-id (dmx-sqlite-nullable-integer remote-id)
                :remote-uri (dmx-sqlite-nullable-string remote-uri)
                :local-object-count (parse-integer count)))))

(defun dmx-sqlite-sync-workflow-summary (db-path)
  (let ((identities (dmx-sqlite-sync-identities db-path))
        (conflicts (dmx-sqlite-sync-identity-conflicts db-path)))
    (list :identity-count (length identities)
          :conflicts conflicts
          :query-run-count (length (dmx-sqlite-query-runs db-path))
          :journal-entry-count (length (dmx-sqlite-journal-entries db-path))
          :ok-p (null conflicts))))

(defun dmx-sqlite-reference-integrity-findings (db-path)
  (flet ((rows (sql)
           (mapcar (lambda (row) (list :id (first row) :reference (second row)))
                   (dmx-sqlite-query-rows db-path sql))))
    (list
     :broken-property-owners
     (rows "select p.id, p.object_id from dmx_sql_property p left join dmx_sql_object o on o.local_id = p.object_id where o.local_id is null order by p.id;")
     :broken-property-targets
     (rows "select t.property_id, t.target_object_id from dmx_sql_property_target t left join dmx_sql_object o on o.local_id = t.target_object_id where o.local_id is null order by t.property_id;")
     :broken-query-run-objects
     (rows "select q.id, q.local_object_id from dmx_sql_query_run q left join dmx_sql_object o on o.local_id = q.local_object_id where q.local_object_id is not null and o.local_id is null order by q.id;")
     :broken-journal-objects
     (rows "select j.id, j.local_object_id from dmx_sql_sync_journal j left join dmx_sql_object o on o.local_id = j.local_object_id where j.local_object_id is not null and o.local_id is null order by j.id;")
     :broken-journal-query-runs
     (rows "select j.journal_id, j.query_run_id from dmx_sql_journal_query_run j left join dmx_sql_query_run q on q.id = j.query_run_id where q.id is null order by j.journal_id;"))))

(defun dmx-sqlite-integrity-report (db-path)
  "Return logical integrity findings without changing the SQLite store.

The report detects malformed association players and sync identities whose
local object no longer exists.  It is useful for stores that predate the
current writer-side checks or were imported by external tooling."
  (let* ((broken-association-players
           (loop for row in
                 (dmx-sqlite-query-rows
                  db-path
                  "select p.assoc_id, p.player_no, coalesce(p.role_type_uri, ''), p.player_kind, p.player_local_id from dmx_sql_assoc_player p left join dmx_sql_assoc a on a.local_id = p.assoc_id left join dmx_sql_object object on object.local_id = p.player_local_id where a.local_id is null or object.local_id is null or object.object_kind <> p.player_kind or p.role_type_uri is null or p.role_type_uri = '' order by p.assoc_id, p.player_no;")
                 collect
                 (destructuring-bind
                     (assoc-id player-no role-type-uri player-kind player-local-id)
                     row
                   (list :assoc-id assoc-id
                         :player-no (parse-integer player-no)
                         :role-type-uri (dmx-sqlite-nullable-string role-type-uri)
                         :player-kind player-kind
                         :player-local-id player-local-id))))
         (broken-sync-identities
           (loop for row in
                 (dmx-sqlite-query-rows
                  db-path
                  "select identity.id, identity.local_object_id, identity.host, coalesce(identity.remote_id, ''), coalesce(identity.remote_uri, '') from dmx_sql_sync_identity identity left join dmx_sql_object object on object.local_id = identity.local_object_id where object.local_id is null order by identity.id;")
                 collect
                 (destructuring-bind (id local-object-id host remote-id remote-uri) row
                   (list :id id
                         :local-object-id local-object-id
                         :host host
                         :remote-id (dmx-sqlite-nullable-integer remote-id)
                         :remote-uri (dmx-sqlite-nullable-string remote-uri)))))
         (topics (dmx-sqlite-topics db-path))
         (associations (dmx-sqlite-associations db-path))
         (references (dmx-sqlite-reference-integrity-findings db-path)))
    (list :ok-p (and (null broken-association-players)
                     (null broken-sync-identities)
                     (null (getf references :broken-property-owners))
                     (null (getf references :broken-property-targets))
                     (null (getf references :broken-query-run-objects))
                     (null (getf references :broken-journal-objects))
                     (null (getf references :broken-journal-query-runs)))
          :counts (list :topics (length topics)
                        :associations (length associations))
          :broken-association-players broken-association-players
          :broken-sync-identities broken-sync-identities
          :broken-property-owners (getf references :broken-property-owners)
          :broken-property-targets (getf references :broken-property-targets)
          :broken-query-run-objects (getf references :broken-query-run-objects)
          :broken-journal-objects (getf references :broken-journal-objects)
          :broken-journal-query-runs (getf references :broken-journal-query-runs))))
