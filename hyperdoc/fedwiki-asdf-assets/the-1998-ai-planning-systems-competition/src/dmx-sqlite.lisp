;;;; Asset-local DMX-shaped SQLite schema and seed materializer.

(in-package #:the-1998-ai-planning-systems-competition)

(defparameter *dmx-sqlite-schema-sql*
  "PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS dmx_topics (
  id TEXT PRIMARY KEY,
  type_uri TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  source_anchor TEXT,
  payload_json TEXT
);

CREATE TABLE IF NOT EXISTS dmx_associations (
  id TEXT PRIMARY KEY,
  type_uri TEXT NOT NULL,
  label TEXT NOT NULL,
  summary TEXT
);

CREATE TABLE IF NOT EXISTS dmx_assoc_players (
  assoc_id TEXT NOT NULL REFERENCES dmx_associations(id) ON DELETE CASCADE,
  player_no INTEGER NOT NULL,
  role_type_uri TEXT NOT NULL,
  player_topic_id TEXT NOT NULL REFERENCES dmx_topics(id),
  PRIMARY KEY (assoc_id, player_no)
);

CREATE INDEX IF NOT EXISTS dmx_assoc_players_topic_idx
  ON dmx_assoc_players(player_topic_id);

CREATE TABLE IF NOT EXISTS fedwiki_pages (
  slug TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  source_topic_id TEXT NOT NULL REFERENCES dmx_topics(id)
);

CREATE TABLE IF NOT EXISTS fedwiki_story_items (
  page_slug TEXT NOT NULL REFERENCES fedwiki_pages(slug) ON DELETE CASCADE,
  item_order INTEGER NOT NULL,
  item_id TEXT NOT NULL,
  item_type TEXT NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (page_slug, item_order)
);

CREATE TABLE IF NOT EXISTS fedwiki_journal_actions (
  page_slug TEXT NOT NULL REFERENCES fedwiki_pages(slug) ON DELETE CASCADE,
  action_order INTEGER NOT NULL,
  action_type TEXT NOT NULL,
  item_id TEXT,
  date_epoch_ms INTEGER NOT NULL,
  payload_json TEXT,
  PRIMARY KEY (page_slug, action_order)
);

CREATE TABLE IF NOT EXISTS source_fragments (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL REFERENCES dmx_topics(id),
  anchor TEXT NOT NULL,
  fragment_type TEXT NOT NULL,
  text TEXT NOT NULL
);")

(defun sqlite-run (db-path sql &key separator)
  "Run SQL against DB-PATH through sqlite3 and return UIOP run-program values."
  (let ((args (append (when separator (list "-separator" separator))
                      (list (namestring db-path) sql))))
    (uiop:run-program (cons "sqlite3" args)
                      :output :string
                      :error-output :string
                      :ignore-error-status t)))

(defun sqlite-exec (db-path sql &key separator)
  (multiple-value-bind (stdout stderr exit-code)
      (sqlite-run db-path sql :separator separator)
    (unless (zerop exit-code)
      (error "SQLite command failed for ~A:~%~A~%~A"
             db-path stdout stderr))
    stdout))

(defun sqlite-scalar (db-path sql)
  (string-trim '(#\Space #\Tab #\Newline #\Return)
               (sqlite-exec db-path sql :separator (string #\Tab))))

(defun sql-literal (value)
  (if value
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for ch across (format nil "~A" value)
                      do (case ch
                           (#\' (write-string "''" stream))
                           (otherwise (write-char ch stream))))))
      "NULL"))

(defun initialize-dmx-sqlite-asset
    (&key (db-path (asset-db-pathname)) clear)
  (ensure-directories-exist db-path)
  (when (and clear (probe-file db-path))
    (delete-file db-path))
  (sqlite-exec db-path *dmx-sqlite-schema-sql*)
  db-path)

(defun seed-topic-sql (topic)
  (destructuring-bind (id type title summary source-anchor) topic
    (format nil
            "INSERT OR REPLACE INTO dmx_topics(id, type_uri, title, summary, source_anchor, payload_json) VALUES(~A, ~A, ~A, ~A, ~A, NULL);"
            (sql-literal id)
            (sql-literal type)
            (sql-literal title)
            (sql-literal summary)
            (sql-literal source-anchor))))

(defun seed-association-sql (association)
  (destructuring-bind (id type label from-topic to-topic) association
    (format nil
            "INSERT OR REPLACE INTO dmx_associations(id, type_uri, label, summary) VALUES(~A, ~A, ~A, ~A);
DELETE FROM dmx_assoc_players WHERE assoc_id = ~A;
INSERT OR REPLACE INTO dmx_assoc_players(assoc_id, player_no, role_type_uri, player_topic_id) VALUES(~A, 1, 'dmx.role/source', ~A);
INSERT OR REPLACE INTO dmx_assoc_players(assoc_id, player_no, role_type_uri, player_topic_id) VALUES(~A, 2, 'dmx.role/target', ~A);"
            (sql-literal id)
            (sql-literal type)
            (sql-literal label)
            (sql-literal label)
            (sql-literal id)
            (sql-literal id)
            (sql-literal from-topic)
            (sql-literal id)
            (sql-literal to-topic))))

(defun seed-source-fragment-sql (fragment)
  (destructuring-bind (id source-id anchor fragment-type text) fragment
    (format nil
            "INSERT OR REPLACE INTO source_fragments(id, source_id, anchor, fragment_type, text) VALUES(~A, ~A, ~A, ~A, ~A);"
            (sql-literal id)
            (sql-literal source-id)
            (sql-literal anchor)
            (sql-literal fragment-type)
            (sql-literal text))))

(defun seed-fedwiki-page-sql ()
  (with-output-to-string (stream)
    (format stream
            "INSERT OR REPLACE INTO fedwiki_pages(slug, title, source_topic_id) VALUES(~A, ~A, ~A);~%"
            (sql-literal *reading-slug*)
            (sql-literal *reading-title*)
            (sql-literal *reading-slug*))
    (format stream
            "DELETE FROM fedwiki_story_items WHERE page_slug = ~A;~%"
            (sql-literal *reading-slug*))
    (loop for (id type text) in (story-item-definitions)
          for order from 1
          do (format stream
                     "INSERT INTO fedwiki_story_items(page_slug, item_order, item_id, item_type, text) VALUES(~A, ~D, ~A, ~A, ~A);~%"
                     (sql-literal *reading-slug*)
                     order
                     (sql-literal id)
                     (sql-literal type)
                     (sql-literal text)))
    (format stream
            "DELETE FROM fedwiki_journal_actions WHERE page_slug = ~A;~%"
            (sql-literal *reading-slug*))
    (format stream
            "INSERT INTO fedwiki_journal_actions(page_slug, action_order, action_type, item_id, date_epoch_ms, payload_json) VALUES(~A, 1, 'create', NULL, ~D, ~A);~%"
            (sql-literal *reading-slug*)
            *fedwiki-journal-date-ms*
            (sql-literal "{\"origin\":\"dmx-sqlite-materialization\"}"))))

(defun seed-reading-topics (&key (db-path (asset-db-pathname)))
  (initialize-dmx-sqlite-asset :db-path db-path)
  (let ((sql
          (with-output-to-string (stream)
            (write-string "BEGIN;" stream)
            (terpri stream)
            (dolist (topic (topic-definitions))
              (write-string (seed-topic-sql topic) stream)
              (terpri stream))
            (dolist (association (association-definitions))
              (write-string (seed-association-sql association) stream)
              (terpri stream))
            (dolist (fragment (source-fragment-definitions))
              (write-string (seed-source-fragment-sql fragment) stream)
              (terpri stream))
            (write-string (seed-fedwiki-page-sql) stream)
            (write-string "COMMIT;" stream)
            (terpri stream))))
    (sqlite-exec db-path sql))
  db-path)

(defun table-count (db-path table)
  (parse-integer
   (sqlite-scalar db-path (format nil "SELECT count(*) FROM ~A;" table))))

(defun schema-status (&key (db-path (asset-db-pathname)))
  (list :db-path db-path
        :exists-p (not (null (probe-file db-path)))
        :tables
        (loop for table in '("dmx_topics"
                             "dmx_associations"
                             "dmx_assoc_players"
                             "fedwiki_pages"
                             "fedwiki_story_items"
                             "fedwiki_journal_actions"
                             "source_fragments")
              collect (list :table table
                            :rows (if (probe-file db-path)
                                      (table-count db-path table)
                                      0)))))

(defun sqlite-exists-p (db-path sql)
  (string= "1" (sqlite-scalar db-path sql)))

(defun topic-exists-p (topic-id &key (db-path (asset-db-pathname)))
  (and (probe-file db-path)
       (sqlite-exists-p
        db-path
        (format nil "SELECT EXISTS(SELECT 1 FROM dmx_topics WHERE id = ~A);"
                (sql-literal topic-id)))))

(defun association-exists-p (association-id &key (db-path (asset-db-pathname)))
  (and (probe-file db-path)
       (sqlite-exists-p
        db-path
        (format nil "SELECT EXISTS(SELECT 1 FROM dmx_associations WHERE id = ~A);"
                (sql-literal association-id)))))

(defun required-topics-present-p (&key (db-path (asset-db-pathname)))
  (every (lambda (topic-id)
           (topic-exists-p topic-id :db-path db-path))
         (required-topic-ids)))

(defun required-associations-present-p (&key (db-path (asset-db-pathname)))
  (every (lambda (association-id)
           (association-exists-p association-id :db-path db-path))
         (required-association-ids)))
