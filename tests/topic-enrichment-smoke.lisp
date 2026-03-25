;;;; Smoke tests for topic enrichment routes, plans, and reports
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-TOPIC-ENRICHMENT-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun topic-enrichment-smoke-tempdir ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "topic-enrichment-smoke-~D-~A/"
            (get-universal-time)
            (gensym "RUN"))
    (uiop:temporary-directory))))

(defun topic-enrichment-smoke-fixture-sql ()
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

INSERT INTO itemTypes VALUES (5, 'journalArticle');

INSERT INTO fields VALUES (1, 'title');
INSERT INTO fields VALUES (2, 'DOI');
INSERT INTO fields VALUES (3, 'citationKey');
INSERT INTO fields VALUES (4, 'date');

INSERT INTO items VALUES (501, 5, '2026-03-25 08:00:00', '2026-03-25 08:10:00', '2026-03-25 08:10:01', 1, 'CHUNK001');
INSERT INTO items VALUES (502, 5, '2026-03-25 09:00:00', '2026-03-25 09:10:00', '2026-03-25 09:10:01', 1, 'BASIS001');

INSERT INTO itemDataValues VALUES (1, 'Chunk');
INSERT INTO itemDataValues VALUES (2, '10.5555/chunk.1977');
INSERT INTO itemDataValues VALUES (3, 'mcdermottChunk1977');
INSERT INTO itemDataValues VALUES (4, '1977');
INSERT INTO itemDataValues VALUES (5, 'Basis');
INSERT INTO itemDataValues VALUES (6, '10.5555/basis.1977');
INSERT INTO itemDataValues VALUES (7, 'mcdermottBasis1977');
INSERT INTO itemDataValues VALUES (8, '1977');

INSERT INTO itemData VALUES (501, 1, 1);
INSERT INTO itemData VALUES (501, 2, 2);
INSERT INTO itemData VALUES (501, 3, 3);
INSERT INTO itemData VALUES (501, 4, 4);

INSERT INTO itemData VALUES (502, 1, 5);
INSERT INTO itemData VALUES (502, 2, 6);
INSERT INTO itemData VALUES (502, 3, 7);
INSERT INTO itemData VALUES (502, 4, 8);
COMMIT;")

(defun make-topic-enrichment-smoke-fixture ()
  (let* ((root (topic-enrichment-smoke-tempdir))
         (database-path (merge-pathnames "zotero.sqlite" root))
         (storage-root (merge-pathnames "storage/" root)))
    (ensure-directories-exist storage-root)
    (run-smoke-sqlite-script
     database-path
     (topic-enrichment-smoke-fixture-sql))
    (list :root root
          :database-path database-path
          :storage-root storage-root)))

(defun make-topic-enrichment-smoke-bridge (&optional fixture)
  (let ((fixture (or fixture (make-topic-enrichment-smoke-fixture))))
    (hyperdoc::make-zotero-library-bridge
     :db-path (getf fixture :database-path)
     :storage-root (getf fixture :storage-root))))

(defun make-topic-enrichment-smoke-source-designator (bridge)
  (hyperdoc::make-zotero-library-source-designator
   :id "zotero-library/topic-enrichment-smoke"
   :title "Smoke Zotero library"
   :summary "Fixture-backed read-only Zotero library for topic-enrichment smoke tests."
   :bridge-provider (lambda () bridge)))

(defun make-topic-enrichment-smoke-route (topic &optional fixture)
  (let ((bridge (make-topic-enrichment-smoke-bridge fixture)))
    (hyperdoc::make-topic-source-route
     topic
     (make-topic-enrichment-smoke-source-designator bridge))))

(defun run-topic-enrichment-success-smoke-test ()
  (let* ((fixture (make-topic-enrichment-smoke-fixture))
         (route (make-topic-enrichment-smoke-route
                 (hyperdoc::chunk-topic)
                 fixture))
         (plan (hyperdoc::topic-source-route-default-plan route))
         (report (hyperdoc::run-topic-enrichment-query-plan plan))
         (signal-titles
           (mapcar #'hyperdoc::candidate-topic-signal-display-title-of
                   (hyperdoc::topic-enrichment-report-candidate-signals-of
                    report)))
         (route-titles (inspector-view-titles-for-object route))
         (plan-titles (inspector-view-titles-for-object plan))
         (report-titles (inspector-view-titles-for-object report))
         (topic-titles (inspector-view-titles-for-object (hyperdoc::chunk-topic)))
         (topic-page-titles
           (inspector-view-titles-for-object
            (hyperbook:find-page hyperdoc::*topics* "Chunk" :signal-error? t))))
    (assert-equal :ready-to-attempt
                  (hyperdoc::topic-enrichment-plan-execution-readiness-of plan)
                  "Fixture-backed plan should be executable")
    (assert-equal :matched
                  (hyperdoc::topic-enrichment-report-status-of report)
                  "Chunk route should produce a successful exact-title report")
    (assert-true (typep (hyperdoc::topic-enrichment-report-query-evidence-of report)
                        'hyperdoc::zotero-title-query)
                 "Successful report should expose Zotero title-query evidence")
    (assert-true (typep (hyperdoc::topic-enrichment-report-query-attempt-of report)
                        'hyperdoc::zotero-query-attempt)
                 "Successful report should expose the selected Zotero attempt")
    (assert-equal 1
                  (length (hyperdoc::topic-enrichment-report-matched-items-of report))
                  "Chunk fixture should match exactly one Zotero item")
    (assert-true (member "Chunk" signal-titles :test #'string=)
                 "Successful report should preserve the matched title as a candidate signal")
    (assert-true (member "10.5555/chunk.1977" signal-titles :test #'string=)
                 "Successful report should derive DOI candidate signals")
    (assert-true (member "mcdermottChunk1977" signal-titles :test #'string=)
                 "Successful report should derive citation-key candidate signals")
    (assert-true (eq report
                     (hyperdoc::topic-source-route-latest-successful-report route))
                 "Successful report should be cached on the route")
    (dolist (title '("Overview" "Inputs"))
      (assert-true (member title route-titles :test #'string=)
                   (format nil "Route inspector should expose ~A" title)))
    (dolist (title '("Overview" "Execution path" "Raw data" "Failure / repair"))
      (assert-true (member title plan-titles :test #'string=)
                   (format nil "Plan inspector should expose ~A" title)))
    (dolist (title '("Overview" "Matches" "Candidate signals" "Editorial consequences" "Raw data"))
      (assert-true (member title report-titles :test #'string=)
                   (format nil "Report inspector should expose ~A" title)))
    (assert-true (member "Touch-Fahrplan" topic-titles :test #'string=)
                 "Topic inspector should expose the Touch-Fahrplan view")
    (assert-true (member "Touch-Fahrplan" topic-page-titles :test #'string=)
                 "Topic page inspector should expose the Touch-Fahrplan view")))

(defun run-topic-enrichment-zero-match-smoke-test ()
  (let* ((fixture (make-topic-enrichment-smoke-fixture))
         (topic (hyperdoc::make-topic
                 :id "ghost-chunk"
                 :title "Ghost chunk"
                 :summary "Synthetic zero-match topic for topic-enrichment smoke tests."))
         (route (make-topic-enrichment-smoke-route topic fixture))
         (report (hyperdoc::run-topic-enrichment-query-plan
                  (hyperdoc::topic-source-route-default-plan route))))
    (assert-equal :zero-matches
                  (hyperdoc::topic-enrichment-report-status-of report)
                  "Unknown title should degrade into a zero-match report")
    (assert-true (null (hyperdoc::topic-enrichment-report-matched-items-of report))
                 "Zero-match report should keep matched items empty")
    (assert-equal "no-zotero-title-match"
                  (hyperdoc::topic-enrichment-report-failure-classification-of report)
                  "Zero-match report should classify the failure explicitly")
    (assert-true (null (hyperdoc::topic-source-route-latest-successful-report route))
                 "Zero-match report must not overwrite the latest successful cache")))

(defun run-topic-enrichment-route-definition-smoke-test ()
  (let ((routes
         (hyperdoc::topic-source-route-durable-routes-for-topic
          (hyperdoc::chunk-topic))))
    (assert-true (plusp (length routes))
                 "Chunk should have at least one durable route definition.")
    (dolist (route routes)
      (assert-true (hyperdoc::topic-source-route-definition-of route)
                   "Durable route must keep its definition.")
      (assert-true (typep (hyperdoc::topic-source-route-annotation-of route)
                          'hyperdoc::dom-relation-annotation)
                   "Durable route should expose the Connect annotation."))))

(defun run-topic-enrichment-blocked-plan-smoke-test ()
  (let* ((source (hyperdoc::make-zotero-library-source-designator
                  :id "zotero-library/topic-enrichment-blocked"
                  :title "Blocked Zotero source"
                  :bridge-provider
                  (lambda ()
                    (hyperdoc::make-zotero-backend-unavailable
                     "topic enrichment smoke"))))
         (route (hyperdoc::make-topic-source-route
                 (hyperdoc::chunk-topic)
                 source))
         (plan (hyperdoc::topic-source-route-default-plan route))
         (report (hyperdoc::run-topic-enrichment-query-plan plan)))
    (assert-equal :blocked
                  (hyperdoc::topic-enrichment-plan-execution-readiness-of plan)
                  "Unavailable bridge should block the plan before execution")
    (assert-true (hyperdoc::topic-enrichment-plan-failure-classification-of plan)
                 "Blocked plan should preserve a failure classification")
    (assert-equal :blocked
                  (hyperdoc::topic-enrichment-report-status-of report)
                  "Blocked plan should degrade into a blocked report")
    (assert-true (typep (hyperdoc::topic-enrichment-report-query-attempt-of report)
                        'hyperdoc::zotero-backend-unavailable)
                 "Blocked report should preserve the unavailable-backend object")))

(defun run-topic-enrichment-smoke-tests ()
  (run-topic-enrichment-blocked-plan-smoke-test)
  (run-topic-enrichment-success-smoke-test)
  (run-topic-enrichment-zero-match-smoke-test)
  (run-topic-enrichment-route-definition-smoke-test)
  (format t "~&Topic enrichment smoke tests passed.~%")
  t)
