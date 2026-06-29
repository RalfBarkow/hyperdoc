;;;; Bounded DMX SQLite association-edge reassignment.

(in-package #:dreyeck.dmx.sqlite)

(defun association-edge-id (source predicate target)
  (format nil "assoc:~A:~A:~A" source predicate target))

(defun association-edge-type-uri (predicate)
  (format nil "dreyeck.dmx.association.~A" predicate))

(defun normalize-association-edge-triple (edge label)
  (unless (and (listp edge)
               (= 3 (length edge))
               (every #'stringp edge))
    (error "~A must be a three-string association edge triple, got ~S."
           label
           edge))
  edge)

(defun association-edge-players (source target)
  (topic-association-players
   source
   "dmx.role.player1"
   target
   "dmx.role.player2"))

(defun association-edge-present-p (db-path edge)
  "Return true when EDGE is present with the canonical binary DMX shape."
  (destructuring-bind (source predicate target)
      (normalize-association-edge-triple edge "Association edge")
    (let* ((assoc-id (association-edge-id source predicate target))
           (association (dmx-sqlite-association db-path assoc-id)))
      (and association
           (string= (getf association :type-uri)
                    (association-edge-type-uri predicate))
           (string= (or (getf association :value) "")
                    predicate)
           (equal (getf association :players)
                  (association-edge-players source target))))))

(defun association-edge-association-ids (db-path)
  (mapcar
   #'first
   (dmx-sqlite-query-rows
    db-path
    "select local_id from dmx_sql_object where object_kind = 'assoc' order by local_id;")))

(defun string-set-difference (left right)
  (set-difference left right :test #'string=))

(defun association-edge-delta (before after)
  (list :removed-association-ids (string-set-difference before after)
        :added-association-ids (string-set-difference after before)))

(defun association-edge-unexpected-delta (expected actual)
  (let ((missing-removed
          (string-set-difference
           (getf expected :removed-association-ids)
           (getf actual :removed-association-ids)))
        (extra-removed
          (string-set-difference
           (getf actual :removed-association-ids)
           (getf expected :removed-association-ids)))
        (missing-added
          (string-set-difference
           (getf expected :added-association-ids)
           (getf actual :added-association-ids)))
        (extra-added
          (string-set-difference
           (getf actual :added-association-ids)
           (getf expected :added-association-ids))))
    (when (or missing-removed extra-removed missing-added extra-added)
      (list :missing-removed-association-ids missing-removed
            :extra-removed-association-ids extra-removed
            :missing-added-association-ids missing-added
            :extra-added-association-ids extra-added))))

(defun ensure-association-edge-topic (db-path topic-id label)
  (unless (dmx-sqlite-topic db-path topic-id)
    (error "~A topic ~S is absent." label topic-id)))

(defun association-edge-journal-id (old-assoc-id new-assoc-id)
  (format nil "journal:reassign-association-edge:~A:to:~A"
          old-assoc-id
          new-assoc-id))

(defun association-edge-journal-payload-json
    (old-edge new-edge old-assoc-id new-assoc-id reason evidence actor
     convergence)
  (json-object
   :old-edge old-edge
   :new-edge new-edge
   :old-association-id old-assoc-id
   :new-association-id new-assoc-id
   :reason reason
   :evidence evidence
   :actor actor
   :convergence convergence))

(defun delete-old-association-edge-sql (old-assoc-id)
  (format nil
"DELETE FROM dmx_sql_assoc_player WHERE assoc_id = ~A;
DELETE FROM dmx_sql_assoc WHERE local_id = ~A;
DELETE FROM dmx_sql_object WHERE local_id = ~A;~%"
          (sql-literal old-assoc-id)
          (sql-literal old-assoc-id)
          (sql-literal old-assoc-id)))

(defun insert-new-association-edge-sql (new-assoc-id source predicate new-target)
  (format nil
"INSERT INTO dmx_sql_object(local_id, object_kind, uri, type_uri, value, payload_json, sync_state, modified_at)
VALUES(~A, 'assoc', NULL, ~A, ~A, NULL, 'local', CURRENT_TIMESTAMP);
INSERT INTO dmx_sql_assoc(local_id) VALUES(~A);
INSERT INTO dmx_sql_assoc_player(assoc_id, player_no, role_type_uri, player_kind, player_local_id)
VALUES(~A, 1, 'dmx.role.player1', 'topic', ~A);
INSERT INTO dmx_sql_assoc_player(assoc_id, player_no, role_type_uri, player_kind, player_local_id)
VALUES(~A, 2, 'dmx.role.player2', 'topic', ~A);~%"
          (sql-literal new-assoc-id)
          (sql-literal (association-edge-type-uri predicate))
          (sql-literal predicate)
          (sql-literal new-assoc-id)
          (sql-literal new-assoc-id)
          (sql-literal source)
          (sql-literal new-assoc-id)
          (sql-literal new-target)))

(defun journal-edge-reassignment-sql
    (journal-id new-assoc-id source predicate old-target new-target
     old-assoc-id reason evidence actor convergence)
  (format nil
"INSERT OR REPLACE INTO dmx_sql_sync_journal(
  id, journal_kind, local_object_id, action, status, detail, payload_json)
VALUES(~A, 'dreyeck.dmx.sqlite.edge-reassignment', ~A,
       'reassign-association-edge', 'passed', ~A, ~A);~%"
          (sql-literal journal-id)
          (sql-literal new-assoc-id)
          (sql-literal reason)
          (sql-literal
           (association-edge-journal-payload-json
            (list source predicate old-target)
            (list source predicate new-target)
            old-assoc-id
            new-assoc-id
            reason
            evidence
            actor
            convergence))))

(defun reassign-association-edge-sql
    (old-assoc-id new-assoc-id source predicate old-target new-target journal-id
     reason evidence actor convergence remove-old-p add-new-p)
  (format nil
"PRAGMA foreign_keys = ON;
BEGIN;
~A~A~ACOMMIT;"
          (if remove-old-p
              (delete-old-association-edge-sql old-assoc-id)
              "")
          (if add-new-p
              (insert-new-association-edge-sql
               new-assoc-id source predicate new-target)
              "")
          (journal-edge-reassignment-sql
           journal-id new-assoc-id source predicate old-target new-target
           old-assoc-id reason evidence actor convergence)))

(defun reassign-association-edge
    (db-path old-edge new-edge &key reason evidence actor
                                 (require-old-edge-p t))
  "Move one binary association edge to a new target and report graph delta."
  (destructuring-bind (old-source old-predicate old-target)
      (normalize-association-edge-triple old-edge "Old edge")
    (destructuring-bind (new-source new-predicate new-target)
        (normalize-association-edge-triple new-edge "New edge")
      (unless (string= old-source new-source)
        (error "Association edge reassignment cannot change source ~S to ~S."
               old-source
               new-source))
      (unless (string= old-predicate new-predicate)
        (error "Association edge reassignment cannot change predicate ~S to ~S."
               old-predicate
               new-predicate))
      (when (string= old-target new-target)
        (error "Association edge reassignment requires a different target."))
      (ensure-association-edge-topic db-path old-source "Source")
      (ensure-association-edge-topic db-path old-target "Old target")
      (ensure-association-edge-topic db-path new-target "New target")
      (let* ((old-assoc-id
               (association-edge-id old-source old-predicate old-target))
             (new-assoc-id
               (association-edge-id old-source old-predicate new-target))
             (old-present-before
               (association-edge-present-p db-path old-edge))
             (new-edge-present-before
               (association-edge-present-p db-path new-edge))
             (new-object-present-before
               (dmx-sql-object-exists-p db-path new-assoc-id)))
        (when (and require-old-edge-p (not old-present-before))
          (error "Required old association edge ~S is absent." old-edge))
        (when (and new-object-present-before (not new-edge-present-before))
          (error "New association edge object ~S already exists but does not match ~S."
                 new-assoc-id
                 new-edge))
        (let* ((remove-old-p old-present-before)
               (add-new-p (not new-edge-present-before))
               (before (association-edge-association-ids db-path))
               (expected
                 (list :removed-association-ids
                       (if remove-old-p (list old-assoc-id) nil)
                       :added-association-ids
                       (if add-new-p (list new-assoc-id) nil)))
               (convergence
                 (list :new-edge-already-present-p new-edge-present-before
                       :already-completed-p
                       (and (not old-present-before)
                            new-edge-present-before)))
               (journal-id
                 (association-edge-journal-id old-assoc-id new-assoc-id))
               (sql
                 (reassign-association-edge-sql
                  old-assoc-id
                  new-assoc-id
                  old-source
                  old-predicate
                  old-target
                  new-target
                  journal-id
                  reason
                  evidence
                  actor
                  convergence
                  remove-old-p
                  add-new-p)))
          (multiple-value-bind (stdout stderr exit-code)
              (sqlite-run db-path sql)
            (unless (zerop exit-code)
              (error "Could not reassign association edge:~%~A~%~A"
                     stdout
                     stderr)))
          (let* ((after (association-edge-association-ids db-path))
                 (actual (association-edge-delta before after))
                 (unexpected
                   (association-edge-unexpected-delta expected actual))
                 (journal-entry
                   (first
                    (dmx-sqlite-journal-entries
                     db-path
                     :local-object-id new-assoc-id))))
            (list :operation :reassign-association-edge
                  :status (if unexpected :failed :passed)
                  :atomic-change
                  (list :removed (and remove-old-p old-edge)
                        :added (and add-new-p new-edge)
                        :already-present
                        (and new-edge-present-before new-edge))
                  :expected-graph-delta expected
                  :actual-graph-delta actual
                  :unexpected-graph-delta unexpected
                  :convergence convergence
                  :derivative-effects
                  (list :journal-entry journal-entry)
                  :reason reason)))))))

(defun association-edge-reassignment-reader-surface
    (&key old-edge new-edge raw-report
          (source-of-truth "production DMX SQLite DB"))
  "Return the reader-facing operation answer before raw evidence."
  (let* ((normalized-old-edge
           (and old-edge
                (normalize-association-edge-triple old-edge "Old edge")))
         (normalized-new-edge
           (and new-edge
                (normalize-association-edge-triple new-edge "New edge")))
         (reported-atomic-change
           (getf raw-report :atomic-change))
         (removed-edge
           (or (getf reported-atomic-change :removed)
               normalized-old-edge))
         (added-or-confirmed-edge
           (or (getf reported-atomic-change :added)
               (getf reported-atomic-change :already-present)
               normalized-new-edge))
         (primary-answer
           (list :operation :reassign-association-edge
                 :status (or (getf raw-report :status) :passed)
                 :atomic-change
                 (list :removed removed-edge
                       :added-or-confirmed added-or-confirmed-edge)
                 :unexpected-graph-delta
                 (getf raw-report :unexpected-graph-delta)
                 :source-of-truth source-of-truth)))
    (list :kind :association-edge-reassignment-reader-surface
          :reader-question
          "Did one bounded association edge move to the intended target, and did the graph remain otherwise unchanged?"
          :primary-answer primary-answer
          :secondary-evidence
          (list :raw-report raw-report
                :raw-report-secondary-p t)
          :goldberg-questions
          '((:what-changed
             "The atomic change is one removed edge and one added or confirmed edge.")
            (:what-stayed-true
             "The source and predicate stay immutable, topics must already exist, and unexpected graph delta must be nil.")
            (:what-is-derivative
             "Journal entries and materializer evidence explain the change but are not the maintained graph source of truth.")))))
