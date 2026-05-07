;;;; Smoke tests for the read-only Zotero title-resolution bridge
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-ZOTERO-BRIDGE-SMOKE-TESTS" :hyperdoc/tests)
                (intern "RUN-ZOTERO-BRIDGE-LIVE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun zotero-bridge-smoke-tempdir ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "zotero-bridge-smoke-~D/" (get-universal-time))
    (uiop:temporary-directory))))

(defun write-smoke-text-file (path content)
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string content stream))
  path)

(defun write-smoke-pdf-file (path)
  (write-smoke-text-file path "%PDF-1.4\n% smoke fixture\n"))

(defun run-smoke-sqlite-script (database-path sql)
  (multiple-value-bind (output error-output exit-code)
      (uiop:run-program (list "sqlite3"
                              (namestring database-path)
                              sql)
                        :output :string
                        :error-output :output
                        :ignore-error-status t)
    (declare (ignore error-output))
    (unless (zerop exit-code)
      (error "sqlite3 fixture setup failed (~A): ~A" exit-code output))))

(defun zotero-smoke-fixture-sql (linked-path)
  (format nil
          "BEGIN;
CREATE TABLE itemTypes (itemTypeID INTEGER PRIMARY KEY, typeName TEXT);
CREATE TABLE items (
  itemID INTEGER PRIMARY KEY,
  itemTypeID INT NOT NULL,
  dateAdded TIMESTAMP NOT NULL,
  dateModified TIMESTAMP NOT NULL,
  clientDateModified TIMESTAMP NOT NULL,
  libraryID INT NOT NULL,
  key TEXT NOT NULL
);
CREATE TABLE fields (fieldID INTEGER PRIMARY KEY, fieldName TEXT);
CREATE TABLE itemDataValues (valueID INTEGER PRIMARY KEY, value TEXT);
CREATE TABLE itemData (itemID INT, fieldID INT, valueID INT);
CREATE TABLE itemAttachments (
  itemID INTEGER PRIMARY KEY,
  parentItemID INT,
  linkMode INT,
  contentType TEXT,
  path TEXT,
  storageModTime INT,
  lastProcessedModificationTime INT
);
INSERT INTO itemTypes VALUES (1, 'book');
INSERT INTO itemTypes VALUES (2, 'attachment');
INSERT INTO itemTypes VALUES (3, 'note');
INSERT INTO itemTypes VALUES (4, 'annotation');
INSERT INTO itemTypes VALUES (5, 'journalArticle');
INSERT INTO fields VALUES (1, 'title');
INSERT INTO fields VALUES (2, 'DOI');
INSERT INTO fields VALUES (3, 'citationKey');
INSERT INTO fields VALUES (4, 'date');
INSERT INTO items VALUES (75704, 1, '2026-03-21 10:00:00', '2026-03-21 11:00:00', '2026-03-21 11:00:01', 1, 'GFC9WKM6');
INSERT INTO items VALUES (75718, 2, '2026-03-21 11:05:00', '2026-03-21 11:05:00', '2026-03-21 11:05:00', 1, 'UULEU9Z7');
INSERT INTO items VALUES (200, 1, '2026-03-23 09:00:00', '2026-03-23 15:45:00', '2026-03-23 15:45:30', 1, 'ITEMLINK1');
INSERT INTO items VALUES (201, 2, '2026-03-23 15:46:00', '2026-03-23 15:46:00', '2026-03-23 15:46:00', 1, 'LINKPDF1');
INSERT INTO items VALUES (300, 5, '2026-03-24 07:00:00', '2026-03-24 09:30:00', '2026-03-24 09:31:00', 1, 'RECENT001');
INSERT INTO items VALUES (400, 3, '2026-03-24 10:00:00', '2026-03-24 10:00:00', '2026-03-24 10:00:00', 1, 'NOTE0001');
INSERT INTO items VALUES (401, 4, '2026-03-24 10:05:00', '2026-03-24 10:05:00', '2026-03-24 10:05:00', 1, 'ANN00001');
INSERT INTO itemDataValues VALUES (1, 'Mind and Mechanism');
INSERT INTO itemDataValues VALUES (2, 'mcdermottMindMechanism2001');
INSERT INTO itemDataValues VALUES (3, '2001');
INSERT INTO itemDataValues VALUES (4, 'Linked attachment sample');
INSERT INTO itemDataValues VALUES (5, 'linkedAttachmentSample2026');
INSERT INTO itemDataValues VALUES (6, '2026');
INSERT INTO itemDataValues VALUES (7, 'Snapshot');
INSERT INTO itemDataValues VALUES (8, 'Recent change article');
INSERT INTO itemData VALUES (75704, 1, 1);
INSERT INTO itemData VALUES (75704, 3, 2);
INSERT INTO itemData VALUES (75704, 4, 3);
INSERT INTO itemData VALUES (75718, 1, 7);
INSERT INTO itemData VALUES (200, 1, 4);
INSERT INTO itemData VALUES (200, 3, 5);
INSERT INTO itemData VALUES (200, 4, 6);
INSERT INTO itemData VALUES (201, 1, 7);
INSERT INTO itemData VALUES (300, 1, 8);
INSERT INTO itemAttachments VALUES (75718, 75704, 0, 'application/pdf', 'storage:McDermott - 2001 - Mind and Mechanism.pdf', 1774340400000, 1774340405000);
INSERT INTO itemAttachments VALUES (201, 200, 2, 'application/pdf', '~A', 1774511160000, 1774511165000);
COMMIT;"
          linked-path))

(defun make-zotero-smoke-fixture ()
  (let* ((root (zotero-bridge-smoke-tempdir))
         (database-path (merge-pathnames "zotero.sqlite" root))
         (storage-root (merge-pathnames "storage/" root))
         (stored-pdf (merge-pathnames
                      "storage/UULEU9Z7/McDermott - 2001 - Mind and Mechanism.pdf"
                      root))
         (linked-pdf (merge-pathnames
                      "linked/Linked Attachment Sample.pdf"
                      root))
         (notes-root (merge-pathnames "notes/" root))
         (note-path (merge-pathnames "notes/mind-and-mechanism.md" root))
         (linked-note-path (merge-pathnames "notes/linked-attachment.md" root)))
    (write-smoke-pdf-file stored-pdf)
    (write-smoke-pdf-file linked-pdf)
    (write-smoke-text-file
     note-path
     "Mind and Mechanism\ncitekey: mcdermottMindMechanism2001\nzotero: GFC9WKM6\nfile: McDermott - 2001 - Mind and Mechanism.pdf\n")
    (write-smoke-text-file
     linked-note-path
     "Linked attachment sample\ncitekey: linkedAttachmentSample2026\nfile: Linked Attachment Sample.pdf\n")
    (run-smoke-sqlite-script
     database-path
     (zotero-smoke-fixture-sql (namestring linked-pdf)))
    (list :root root
          :database-path database-path
          :storage-root storage-root
          :stored-pdf stored-pdf
          :linked-pdf linked-pdf
          :notes-root notes-root)))

(defun zotero-note-clue-kinds (evidence)
  (remove-duplicates
   (loop for note in evidence
         append (mapcar #'hyperdoc::zotero-note-clue-kind-of
                        (hyperdoc::zotero-note-evidence-matches-of note)))
   :test #'eq))

(defun assert-hyperdoc-page-present (title)
  (assert-true (hyperbook:find-page hyperdoc:*hyperdoc* title)
               (format nil "HyperDoc page must be present: ~A" title)))

(defun assert-zotero-topic-function-present (symbol title)
  (assert-true (fboundp symbol)
               (format nil "Topic function must be present for ~A" title)))

(defun run-zotero-bridge-smoke-tests ()
  (dolist (entry '((hyperdoc::zotero-library-topic "Zotero library")
                   (hyperdoc::zotero-attachment-topic "Zotero attachment")
                   (hyperdoc::zotero-recent-changes-query-topic "Zotero recent changes query")
                   (hyperdoc::zotero-recent-change-hit-topic "Zotero recent change hit")
                   (hyperdoc::attachment-path-resolution-topic "Attachment path resolution")
                   (hyperdoc::linked-file-attachment-topic "Linked file attachment")
                   (hyperdoc::stored-attachment-topic "Stored attachment")))
    (destructuring-bind (symbol title) entry
      (assert-zotero-topic-function-present symbol title)))
  (dolist (title '("Zotero library bridge for HyperDoc"
                   "Recent changes in a local Zotero library"
                   "Zotero attachment path resolution"
                   "Zettelkasten note lookup for Zotero resolution"
                   "Resolve a local PDF from Zotero in HyperDoc"))
    (assert-hyperdoc-page-present title))
  (let* ((fixture (make-zotero-smoke-fixture))
         (bridge (hyperdoc::make-zotero-library-bridge
                  :db-path (getf fixture :database-path)
                  :storage-root (getf fixture :storage-root)
                  :note-roots (list (getf fixture :notes-root))))
         (exact-title-items nil)
         (title-query nil)
         (loose-title-items nil)
         (loose-title-query nil)
         (item-hit nil)
         (item-id-query nil)
         (attachments nil)
         (attachment-query nil)
         (stored-attachment nil)
         (stored-path-report nil)
         (candidate-reports nil)
         (candidate-evidence nil)
         (recent-changes-query nil)
         (recent-change-hits nil)
         (recent-changes-with-attachments-query nil)
         (recent-change-hits-with-attachments nil)
         (recent-change-groups nil)
         (stored-report
          (hyperdoc::resolve-zotero-title-to-local-pdf-report
           "Mind and Mechanism"
           :bridge bridge))
         (linked-report
          (hyperdoc::resolve-zotero-title-to-local-pdf-report
           "Linked attachment sample"
           :bridge bridge))
         (stored-clue-kinds
          (zotero-note-clue-kinds
           (hyperdoc::zotero-report-note-evidence-of stored-report))))
    (multiple-value-setq (exact-title-items title-query)
      (hyperdoc::lookup-zotero-items-by-title
       "Mind and Mechanism"
       :bridge bridge
       :match-mode :exact))
    (multiple-value-setq (loose-title-items loose-title-query)
      (hyperdoc::lookup-zotero-items-by-title
       "Mind"
       :bridge bridge
       :match-mode :loose))
    (multiple-value-setq (item-hit item-id-query)
      (hyperdoc::lookup-zotero-item-by-id 75704 :bridge bridge))
    (multiple-value-setq (attachments attachment-query)
      (hyperdoc::list-zotero-attachments-for-item item-hit :bridge bridge))
    (setf recent-changes-query
          (hyperdoc::recent-zotero-changes
           :bridge bridge
           :limit 2
           :since "2026-03-23"))
    (setf recent-change-hits
          (hyperdoc::zotero-recent-changes-query-recent-items-of
           recent-changes-query))
    (setf recent-change-groups
          (hyperdoc::group-zotero-recent-change-hits-by-day
           recent-change-hits))
    (setf recent-changes-with-attachments-query
          (hyperdoc::recent-zotero-changes
           :bridge bridge
           :limit 5
           :since "2026-03-20"
           :include-attachments? t))
    (setf recent-change-hits-with-attachments
          (hyperdoc::zotero-recent-changes-query-recent-items-of
           recent-changes-with-attachments-query))
    (setf stored-attachment
          (find "UULEU9Z7"
                attachments
                :key #'hyperdoc::zotero-attachment-key-of
                :test #'string=))
    (setf stored-path-report
          (hyperdoc::resolve-zotero-stored-attachment-path
           stored-attachment
           :bridge bridge
           :item-hit item-hit))
    (multiple-value-bind (reports query attachments-query items all-attachments
                                  note-evidence note-search-status
                                  note-files-searched evidence)
        (hyperdoc::resolve-zotero-title-to-candidate-pdf-reports
         "Mind and Mechanism"
         :bridge bridge
         :match-mode :exact)
      (declare (ignore query attachments-query items all-attachments
                       note-evidence note-search-status note-files-searched))
      (setf candidate-reports reports
            candidate-evidence evidence))
    (assert-equal 1
                  (length exact-title-items)
                  "Exact title lookup should return one bibliographic hit")
    (assert-true (typep title-query 'hyperdoc::zotero-title-query)
                 "Title lookup should expose a dedicated zotero-title-query object")
    (assert-equal :exact
                  (hyperdoc::zotero-title-query-match-mode-of title-query)
                  "Exact title lookup should record match mode")
    (assert-equal 1
                  (length loose-title-items)
                  "Loose title lookup should return one bibliographic hit in the fixture")
    (assert-equal :loose
                  (hyperdoc::zotero-title-query-match-mode-of loose-title-query)
                  "Loose title lookup should record match mode")
    (assert-equal 75704
                  (hyperdoc::zotero-item-id-of item-hit)
                  "Item-id lookup should expose the deterministic fixture item")
    (assert-true (typep item-id-query 'hyperdoc::zotero-item-id-query)
                 "Item-id lookup should expose a dedicated zotero-item-id-query object")
    (assert-true (not (null (hyperdoc::zotero-query-selected-attempt-of item-id-query)))
                 "Item-id lookup should expose its query evidence")
    (assert-true (typep recent-changes-query 'hyperdoc::zotero-recent-changes-query)
                 "Recent changes should expose a dedicated zotero-recent-changes-query object")
    (assert-true (not (null (hyperdoc::zotero-query-selected-attempt-of recent-changes-query)))
                 "Recent changes should preserve SQLite query evidence")
    (assert-equal 2
                  (hyperdoc::zotero-recent-changes-query-limit-of recent-changes-query)
                  "Recent changes query should preserve the requested limit")
    (assert-equal "2026-03-23"
                  (hyperdoc::zotero-recent-changes-query-since-of recent-changes-query)
                  "Recent changes query should preserve the since filter")
    (assert-equal 2
                  (length recent-change-hits)
                  "Recent changes query should honor the limit after filtering")
    (assert-equal '(300 200)
                  (mapcar #'hyperdoc::zotero-item-id-of recent-change-hits)
                  "Recent changes should order bibliographic items by items.dateModified descending")
    (assert-equal '("2026-03-24 09:30:00" "2026-03-23 15:45:00")
                  (mapcar #'hyperdoc::zotero-recent-change-hit-change-timestamp-of
                          recent-change-hits)
                  "Recent changes should surface the chosen item-row timestamp values")
    (assert-equal "items.dateModified"
                  (hyperdoc::zotero-recent-change-hit-change-timestamp-field-of
                   (first recent-change-hits))
                  "Recent changes should name the chosen timestamp field explicitly")
    (assert-equal "selected-attempt.rows[0]"
                  (hyperdoc::zotero-recent-change-hit-evidence-path-of
                   (first recent-change-hits))
                  "Recent changes hits should preserve a stable evidence path into the selected query rows")
    (assert-equal 2
                  (length recent-change-groups)
                  "Recent changes grouping should split the filtered hits by day")
    (assert-equal "2026-03-24"
                  (getf (first recent-change-groups) :day)
                  "Recent changes grouping should use the chosen timestamp day")
    (assert-equal 5
                  (length recent-change-hits-with-attachments)
                  "Recent changes should include attachments when explicitly requested")
    (assert-true (member "attachment"
                         (mapcar #'hyperdoc::zotero-item-type-of
                                 recent-change-hits-with-attachments)
                         :test #'string=)
                 "Attachment-inclusive recent changes should surface attachment hits")
    (assert-true (not (member "note"
                              (mapcar #'hyperdoc::zotero-item-type-of
                                      recent-change-hits-with-attachments)
                              :test #'string=))
                 "Recent changes should keep notes out of the first slice")
    (assert-true (not (member "annotation"
                              (mapcar #'hyperdoc::zotero-item-type-of
                                      recent-change-hits-with-attachments)
                              :test #'string=))
                 "Recent changes should keep annotations out of the first slice")
    (assert-equal 1
                  (length attachments)
                  "Item-id lookup should list exactly one child attachment in the fixture")
    (assert-true (not (null (hyperdoc::zotero-query-selected-attempt-of attachment-query)))
                 "Attachment lookup should expose its query evidence")
    (assert-true (not (null stored-attachment))
                 "Attachment listing should surface the deterministic UULEU9Z7 stored PDF")
    (assert-equal "UULEU9Z7"
                  (hyperdoc::zotero-attachment-key-of stored-attachment)
                  "Stored attachment lookup should preserve the attachment key")
    (assert-true (equal "McDermott - 2001 - Mind and Mechanism.pdf"
                        (hyperdoc::zotero-path-report-storage-relative-path-of
                         stored-path-report))
                 "Stored path resolution should preserve the storage-relative suffix")
    (assert-true (equal (getf fixture :stored-pdf)
                        (hyperdoc::zotero-path-report-resolved-path-of
                         stored-path-report))
                 "Stored path resolution should derive the local fixture pathname")
    (assert-true (hyperdoc::zotero-path-report-exists-p stored-path-report)
                 "Stored path report should confirm file existence")
    (assert-equal 1
                  (length candidate-reports)
                  "Title lookup should produce one candidate PDF report in the fixture")
    (assert-equal 1
                  (length candidate-evidence)
                  "Title lookup should produce one explicit resolution-evidence object")
    (assert-equal :resolved
                  (hyperdoc::zotero-report-status-of stored-report)
                  "Stored attachment report should resolve successfully")
    (assert-equal nil
                  (hyperdoc::zotero-report-failure-mode-of stored-report)
                  "Stored attachment report should not carry a failure mode")
    (assert-equal 1
                  (length (hyperdoc::zotero-report-item-candidates-of stored-report))
                  "Stored attachment fixture should match exactly one bibliographic item")
    (assert-equal 1
                  (length (hyperdoc::zotero-report-attachment-candidates-of stored-report))
                  "Stored attachment fixture should expose exactly one child attachment")
    (assert-true (equal (getf fixture :stored-pdf)
                        (hyperdoc::zotero-report-resolved-path-of stored-report))
                 "Stored attachment path should resolve through storage root plus attachment key")
    (assert-true (hyperdoc::zotero-report-exists-p stored-report)
                 "Stored attachment path should exist")
    (assert-true (member :title stored-clue-kinds)
                 "Note evidence should record the exact title clue")
    (assert-true (member :citation-key stored-clue-kinds)
                 "Note evidence should record the citekey clue")
    (assert-true (member :zotero-item-key stored-clue-kinds)
                 "Note evidence should record the Zotero item key clue")
    (assert-true (member :attachment-filename stored-clue-kinds)
                 "Note evidence should record the attachment filename clue")
    (assert-equal :resolved
                  (hyperdoc::zotero-report-status-of linked-report)
                  "Linked attachment report should resolve successfully")
    (assert-true (equal (getf fixture :linked-pdf)
                        (hyperdoc::zotero-report-resolved-path-of linked-report))
                 "Linked attachment path should resolve directly from the linked path")
    (assert-true (hyperdoc::zotero-report-exists-p linked-report)
                 "Linked attachment path should exist")
    (format t "~&Zotero bridge smoke tests passed.~%")
    t))

(defun run-zotero-bridge-live-tests ()
  (if (not (string= (or (uiop:getenv "HYPERDOC_RUN_ZOTERO_LIVE_TESTS") "") "1"))
      (progn
        (format t "~&Zotero bridge live tests skipped. Set HYPERDOC_RUN_ZOTERO_LIVE_TESTS=1 to enable.~%")
        t)
      (let* ((item-id (hyperdoc::mind-and-mechanism-zotero-demo-item-id))
             (attachment-key (hyperdoc::mind-and-mechanism-zotero-demo-attachment-key))
             (item-hit (hyperdoc::mind-and-mechanism-zotero-item-hit))
             (attachment-hit (hyperdoc::mind-and-mechanism-zotero-attachment-hit))
             (path-report (hyperdoc::mind-and-mechanism-zotero-path-resolution-report))
             (title-report (hyperdoc::mind-and-mechanism-zotero-resolution-report)))
        (assert-true (not (null item-hit))
                     "Live item-id lookup should return a Zotero item")
        (assert-equal item-id
                      (hyperdoc::zotero-item-id-of item-hit)
                      "Live item-id lookup should match the configured demo item id")
        (assert-true (not (null attachment-hit))
                     "Live attachment lookup should return the configured demo attachment")
        (assert-equal attachment-key
                      (hyperdoc::zotero-attachment-key-of attachment-hit)
                      "Live attachment lookup should match the configured attachment key")
        (assert-true (not (null path-report))
                     "Live stored-path resolution should return a report object")
        (assert-true (hyperdoc::zotero-path-report-exists-p path-report)
                     "Live stored-path resolution should reach an existing local file")
        (assert-equal :resolved
                      (hyperdoc::zotero-report-status-of title-report)
                      "Live title lookup should also resolve successfully")
        (format t "~&Zotero bridge live tests passed.~%")
        t)))
