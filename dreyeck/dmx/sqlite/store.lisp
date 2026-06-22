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
      (unless (dmx-sql-exists-p
               db-path
               (format nil
                       "select exists(select 1 from dmx_sql_object where local_id = ~A and object_kind = ~A);"
                       (sql-literal player-local-id)
                       (sql-literal player-kind)))
        (error "DMX association player ~A does not name an existing ~A."
               player-local-id player-kind)))))

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
         (associations (dmx-sqlite-associations db-path)))
    (list :ok-p (and (null broken-association-players)
                     (null broken-sync-identities))
          :counts (list :topics (length topics)
                        :associations (length associations))
          :broken-association-players broken-association-players
          :broken-sync-identities broken-sync-identities)))
