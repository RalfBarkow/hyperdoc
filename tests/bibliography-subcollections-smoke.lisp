;;;; Smoke tests for bibliography subcollections and authoring plans
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-BIBLIOGRAPHY-SUBCOLLECTIONS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun bibliography-subcollections-smoke-tempdir ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "bibliography-subcollections-smoke-~D-~A/"
            (get-universal-time)
            (gensym "RUN"))
    (uiop:temporary-directory))))

(defun write-bibliography-smoke-text-file (path content)
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string content stream))
  path)

(defun run-bibliography-smoke-sqlite-script (database-path sql)
  (multiple-value-bind (output error-output exit-code)
      (uiop:run-program (list "sqlite3"
                              (namestring database-path)
                              sql)
                        :output :string
                        :error-output :output
                        :ignore-error-status t)
    (declare (ignore error-output))
    (unless (zerop exit-code)
      (error "sqlite3 bibliography fixture setup failed (~A): ~A"
             exit-code
             output))))

(defun bibliography-smoke-fixture-sql ()
  "BEGIN;
CREATE TABLE collections (
  collectionID INTEGER PRIMARY KEY,
  collectionName TEXT NOT NULL,
  parentCollectionID INT DEFAULT NULL,
  clientDateModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  libraryID INT NOT NULL,
  key TEXT NOT NULL,
  version INT NOT NULL DEFAULT 0,
  synced INT NOT NULL DEFAULT 0
);
CREATE TABLE collectionItems (
  collectionID INT NOT NULL,
  itemID INT NOT NULL,
  orderIndex INT NOT NULL DEFAULT 0
);
CREATE TABLE itemTypes (
  itemTypeID INTEGER PRIMARY KEY,
  typeName TEXT NOT NULL
);
CREATE TABLE items (
  itemID INTEGER PRIMARY KEY,
  itemTypeID INT NOT NULL,
  key TEXT NOT NULL
);
CREATE TABLE fields (
  fieldID INTEGER PRIMARY KEY,
  fieldName TEXT NOT NULL
);
CREATE TABLE itemDataValues (
  valueID INTEGER PRIMARY KEY,
  value TEXT
);
CREATE TABLE itemData (
  itemID INT NOT NULL,
  fieldID INT NOT NULL,
  valueID INT NOT NULL
);
CREATE TABLE creatorTypes (
  creatorTypeID INTEGER PRIMARY KEY,
  creatorType TEXT NOT NULL
);
CREATE TABLE creators (
  creatorID INTEGER PRIMARY KEY,
  firstName TEXT,
  lastName TEXT,
  fieldMode INT
);
CREATE TABLE itemCreators (
  itemID INT NOT NULL,
  creatorID INT NOT NULL,
  creatorTypeID INT NOT NULL,
  orderIndex INT NOT NULL DEFAULT 0
);
CREATE TABLE tags (
  tagID INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);
CREATE TABLE itemTags (
  itemID INT NOT NULL,
  tagID INT NOT NULL,
  type INT NOT NULL DEFAULT 0
);

INSERT INTO collections VALUES (10, 'Research', NULL, CURRENT_TIMESTAMP, 1, 'ROOT10', 1, 1);
INSERT INTO collections VALUES (11, 'coachmark', 10, CURRENT_TIMESTAMP, 1, 'COACH11', 1, 1);

INSERT INTO itemTypes VALUES (1, 'journalArticle');
INSERT INTO itemTypes VALUES (2, 'document');
INSERT INTO itemTypes VALUES (3, 'report');

INSERT INTO items VALUES (1001, 1, 'ITEM1001');
INSERT INTO items VALUES (1002, 2, 'ITEM1002');
INSERT INTO items VALUES (1003, 1, 'ITEM1003');
INSERT INTO items VALUES (1004, 3, 'ITEM1004');

INSERT INTO collectionItems VALUES (11, 1001, 0);
INSERT INTO collectionItems VALUES (11, 1002, 1);
INSERT INTO collectionItems VALUES (11, 1003, 2);
INSERT INTO collectionItems VALUES (11, 1004, 3);

INSERT INTO fields VALUES (1, 'title');
INSERT INTO fields VALUES (2, 'abstractNote');
INSERT INTO fields VALUES (3, 'date');
INSERT INTO fields VALUES (4, 'url');
INSERT INTO fields VALUES (5, 'publicationTitle');
INSERT INTO fields VALUES (6, 'publisher');
INSERT INTO fields VALUES (7, 'DOI');

INSERT INTO itemDataValues VALUES (1, 'Designing coach marks for guided tours');
INSERT INTO itemDataValues VALUES (2, 'Coach marks can act as help overlays during first-run onboarding.');
INSERT INTO itemDataValues VALUES (3, '2021');
INSERT INTO itemDataValues VALUES (4, 'https://example.test/coach-marks-guided-tours');
INSERT INTO itemDataValues VALUES (5, 'Journal of UX Patterns');
INSERT INTO itemDataValues VALUES (6, '10.5555/coach.2021.1');

INSERT INTO itemDataValues VALUES (7, 'Improving usability with user onboarding in event software');
INSERT INTO itemDataValues VALUES (8, 'Short user-onboarding study with contextual help notes.');
INSERT INTO itemDataValues VALUES (9, '2019');
INSERT INTO itemDataValues VALUES (10, 'https://example.test/user-onboarding');
INSERT INTO itemDataValues VALUES (11, 'UX Research Notes');

INSERT INTO itemDataValues VALUES (12, 'Narrative motion in mobile onboarding');
INSERT INTO itemDataValues VALUES (13, 'Motion cues for mobile onboarding and walkthrough patterns.');
INSERT INTO itemDataValues VALUES (14, '2017');
INSERT INTO itemDataValues VALUES (15, 'https://example.test/mobile-onboarding');
INSERT INTO itemDataValues VALUES (16, 'Mobile UX Journal');

INSERT INTO itemDataValues VALUES (17, 'Help overlays and guided tours for first-run experience');
INSERT INTO itemDataValues VALUES (18, 'Guided tours and help overlays are compared as onboarding patterns.');
INSERT INTO itemDataValues VALUES (19, '2020');
INSERT INTO itemDataValues VALUES (20, 'https://example.test/help-overlays');
INSERT INTO itemDataValues VALUES (21, 'Practice Report Series');

INSERT INTO itemData VALUES (1001, 1, 1);
INSERT INTO itemData VALUES (1001, 2, 2);
INSERT INTO itemData VALUES (1001, 3, 3);
INSERT INTO itemData VALUES (1001, 4, 4);
INSERT INTO itemData VALUES (1001, 5, 5);
INSERT INTO itemData VALUES (1001, 7, 6);

INSERT INTO itemData VALUES (1002, 1, 7);
INSERT INTO itemData VALUES (1002, 2, 8);
INSERT INTO itemData VALUES (1002, 3, 9);
INSERT INTO itemData VALUES (1002, 4, 10);
INSERT INTO itemData VALUES (1002, 6, 11);

INSERT INTO itemData VALUES (1003, 1, 12);
INSERT INTO itemData VALUES (1003, 2, 13);
INSERT INTO itemData VALUES (1003, 3, 14);
INSERT INTO itemData VALUES (1003, 4, 15);
INSERT INTO itemData VALUES (1003, 5, 16);

INSERT INTO itemData VALUES (1004, 1, 17);
INSERT INTO itemData VALUES (1004, 2, 18);
INSERT INTO itemData VALUES (1004, 3, 19);
INSERT INTO itemData VALUES (1004, 4, 20);
INSERT INTO itemData VALUES (1004, 6, 21);

INSERT INTO creatorTypes VALUES (8, 'author');

INSERT INTO creators VALUES (201, 'Riley', 'Ng', 0);
INSERT INTO creators VALUES (202, 'Pat', 'Rivera', 0);
INSERT INTO creators VALUES (203, 'Jordan', 'Kim', 0);
INSERT INTO creators VALUES (204, 'Alex', 'Meyer', 0);

INSERT INTO itemCreators VALUES (1001, 201, 8, 0);
INSERT INTO itemCreators VALUES (1002, 202, 8, 0);
INSERT INTO itemCreators VALUES (1003, 203, 8, 0);
INSERT INTO itemCreators VALUES (1004, 204, 8, 0);

INSERT INTO tags VALUES (301, 'coach marks');
INSERT INTO tags VALUES (302, 'guided tours');
INSERT INTO tags VALUES (303, 'help overlays');
INSERT INTO tags VALUES (304, 'user onboarding');
INSERT INTO tags VALUES (305, 'onboarding');
INSERT INTO tags VALUES (306, 'mobile onboarding');

INSERT INTO itemTags VALUES (1001, 301, 0);
INSERT INTO itemTags VALUES (1001, 302, 0);
INSERT INTO itemTags VALUES (1001, 303, 0);
INSERT INTO itemTags VALUES (1002, 304, 0);
INSERT INTO itemTags VALUES (1002, 305, 0);
INSERT INTO itemTags VALUES (1003, 306, 0);
INSERT INTO itemTags VALUES (1003, 305, 0);
INSERT INTO itemTags VALUES (1004, 302, 0);
INSERT INTO itemTags VALUES (1004, 303, 0);
INSERT INTO itemTags VALUES (1004, 305, 0);
COMMIT;"
  )

(defun make-bibliography-smoke-fixture ()
  (let* ((root (bibliography-subcollections-smoke-tempdir))
         (database-path (merge-pathnames "zotero.sqlite" root))
         (storage-root (merge-pathnames "storage/" root)))
    (ensure-directories-exist storage-root)
    (run-bibliography-smoke-sqlite-script
     database-path
     (bibliography-smoke-fixture-sql))
    (list :root root
          :database-path database-path
          :storage-root storage-root)))

(defun make-bibliography-smoke-source (&optional fixture)
  (let* ((fixture (or fixture (make-bibliography-smoke-fixture)))
         (bridge (hyperdoc::make-zotero-library-bridge
                  :db-path (getf fixture :database-path)
                  :storage-root (getf fixture :storage-root))))
    (hyperdoc::make-zotero-bibliography-source
     :bridge bridge
     :default-collection "coachmark"
     :materialization-root (merge-pathnames "materialized/" (getf fixture :root)))))

(defun make-bibliography-missing-db-source (&optional fixture)
  (let* ((fixture (or fixture (make-bibliography-smoke-fixture)))
         (missing-db-path (merge-pathnames "missing-zotero.sqlite" (getf fixture :root)))
         (bridge (hyperdoc::make-zotero-library-bridge
                  :db-path missing-db-path
                  :storage-root (getf fixture :storage-root))))
    (hyperdoc::make-zotero-bibliography-source
     :bridge bridge
     :default-collection "coachmark"
     :materialization-root (merge-pathnames "materialized-missing/" (getf fixture :root)))))

(defun find-candidate-by-title (plan title)
  (find title
        (hyperdoc::hyperdoc-authoring-plan-candidate-topics-of plan)
        :key #'hyperdoc::candidate-topic-title-of
        :test #'string-equal))

(defun find-decision-by-title (plan title)
  (find title
        (hyperdoc::hyperdoc-authoring-plan-authoring-decisions-of plan)
        :key (lambda (decision)
               (hyperdoc::candidate-topic-title-of
                (hyperdoc::authoring-decision-candidate-topic-of decision)))
        :test #'string-equal))

(defun inspector-view-titles-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (mapcar #'html-inspector-views:view-title
            (slot-value pane 'clog-moldable-inspector::views))))

(defun make-synthetic-candidate (title)
  (let* ((aliases (hyperdoc::phrase-aliases title))
         (signal (make-instance 'hyperdoc::candidate-topic-signal
                                :source-kind :entry-tag
                                :field :tags
                                :raw-value title
                                :display-title title
                                :normalized-key (hyperdoc::candidate-topic-key
                                                 title
                                                 aliases)
                                :aliases aliases
                                :detail "Synthetic candidate for comparison smoke tests.")))
    (make-instance 'hyperdoc::candidate-topic
                   :title title
                   :normalized-key (hyperdoc::candidate-topic-key title aliases)
                   :aliases aliases
                   :signals (list signal)
                   :collection-signals nil
                   :entry-signals (list signal)
                   :source-entries nil
                   :support-count 1
                   :broader-hints (remove title
                                          (hyperdoc::candidate-broader-hints title)
                                          :test #'string-equal)
                   :editorial-notes nil)))

(defun run-bibliography-subcollection-lookup-smoke-test ()
  (let* ((fixture (make-bibliography-smoke-fixture))
         (source (make-bibliography-smoke-source fixture))
         (book (hyperdoc:ensure-bibliography-subcollections-hyperbook :source source))
         (subcollection (hyperbook:find-page book "coachmark" :signal-error? t)))
    (assert-true (typep source 'hyperdoc::zotero-bibliography-source)
                 "Default bibliography source for this slice must be Zotero-backed")
    (assert-true (typep subcollection 'hyperdoc::bibliography-subcollection)
                 "coachmark lookup must expose a first-class bibliography-subcollection object")
    (assert-equal "Research / coachmark"
                  (hyperdoc::zotero-collection-path-of
                   (hyperdoc::bibliography-subcollection-collection-hit-of subcollection))
                  "Subcollection provenance must preserve the Zotero collection path")
    (assert-equal 4
                  (length (hyperdoc::bibliography-subcollection-entries-of subcollection))
                  "Fixture should import four coachmark bibliography entries")
    (assert-true (plusp (length (hyperdoc::bibliography-subcollection-candidate-topics-of
                                 subcollection)))
                 "Subcollection lookup must keep candidate topics inspectable without forcing the authoring plan")
    (assert-true (null (hyperdoc::bibliography-subcollection-authoring-plan-of subcollection))
                 "Subcollection lookup must leave the authoring plan deferred until explicit request")))

(defun run-bibliography-subcollection-query-failure-smoke-test ()
  (let* ((fixture (make-bibliography-smoke-fixture))
         (source (make-bibliography-missing-db-source fixture))
         (book (hyperdoc:ensure-bibliography-subcollections-hyperbook :source source))
         (result (hyperbook:find-page book "coachmark" :signal-error? nil))
         (failed-attempt (hyperdoc::bibliography-subcollection-load-failure-failed-attempt-of result))
         (book-titles (inspector-view-titles-for-object book))
         (result-titles (inspector-view-titles-for-object result)))
    (assert-true (typep result 'hyperdoc::bibliography-subcollection-load-failure)
                 "Missing Zotero DB must return a bounded bibliography load-failure object instead of crashing")
    (assert-equal :collection-query
                  (hyperdoc::bibliography-subcollection-load-failure-stage-of result)
                  "Missing Zotero DB should fail during collection lookup")
    (assert-true (search "Zotero database not found"
                         (hyperdoc::bibliography-subcollection-load-failure-detail-of result))
                 "Failure object should preserve the underlying missing-database detail")
    (assert-true (typep (hyperdoc::bibliography-subcollection-load-failure-collection-query-of result)
                        'hyperdoc::zotero-collection-query)
                 "Failure object must preserve the collection query evidence")
    (assert-true (typep failed-attempt 'hyperdoc::zotero-query-missing-attempt)
                 "The NIL selected-attempt seam should be normalized into an explicit Zotero boundary object")
    (assert-equal :error
                  (hyperdoc::zotero-query-protocol-status-of failed-attempt)
                  "Missing Zotero DB should normalize into an error-status boundary attempt")
    (assert-true (null (hyperdoc::zotero-query-protocol-rows-of failed-attempt))
                 "Boundary attempt must answer rows safely with NIL rather than dispatching on raw NIL")
    (assert-equal '(hyperdoc::lookup-zotero-collection "coachmark")
                  (hyperdoc::zotero-query-missing-attempt-intent-of failed-attempt)
                  "Boundary attempt should preserve the higher-level lookup intent")
    (assert-true (member "Main page" book-titles :test #'string=)
                 "Bibliography hyperbook should remain inspectable even when its main page lookup fails softly")
    (dolist (title '("Overview" "Query evidence"))
      (assert-true (member title result-titles :test #'string=)
                   (format nil "Load-failure object should expose ~A" title)))
    (let ((plan (hyperdoc::plan-bibliography-authoring
                 "coachmark"
                 :source source
                 :signal-error? nil)))
      (assert-true (typep plan 'hyperdoc::bibliography-subcollection-load-failure)
                   "Authoring-plan entry through a missing Zotero DB must preserve the bounded failure object"))))

(defun run-bibliography-authoring-plan-deferred-smoke-test ()
  (let* ((fixture (make-bibliography-smoke-fixture))
         (source (make-bibliography-smoke-source fixture))
         (book (hyperdoc:ensure-bibliography-subcollections-hyperbook :source source))
         (subcollection (hyperbook:find-page book "coachmark" :signal-error? t))
         (plan (hyperdoc::plan-bibliography-authoring subcollection
                                                      :source source
                                                      :signal-error? t)))
    (assert-true (typep plan 'hyperdoc::hyperdoc-authoring-plan)
                 "Explicit authoring-plan access must still build the inspectable plan object")
    (assert-true (eq plan
                     (hyperdoc::bibliography-subcollection-authoring-plan-of subcollection))
                 "Explicit authoring-plan access must cache the resulting plan on the subcollection")
    (assert-equal (length (hyperdoc::hyperdoc-authoring-plan-candidate-topics-of plan))
                  (length (hyperdoc::bibliography-subcollection-candidate-topics-of subcollection))
                  "Deferred plan construction must preserve the candidate-topic inventory that page-open already exposed")))

(defun run-bibliography-entry-normalization-smoke-test ()
  (let* ((source (make-bibliography-smoke-source))
         (subcollection (hyperdoc::coachmark-bibliography-subcollection :source source
                                                                        :signal-error? t))
         (entry (first (hyperdoc::bibliography-subcollection-entries-of subcollection))))
    (assert-equal "Designing coach marks for guided tours"
                  (hyperdoc::bibliography-entry-title-of entry)
                  "First fixture entry title")
    (assert-equal '("Riley Ng")
                  (hyperdoc::bibliography-entry-authors-of entry)
                  "First fixture entry authors")
    (assert-equal 2021
                  (hyperdoc::bibliography-entry-year-of entry)
                  "First fixture entry year")
    (assert-equal "journalArticle"
                  (hyperdoc::bibliography-entry-work-type-of entry)
                  "First fixture entry type")
    (assert-equal "Research / coachmark"
                  (hyperdoc::bibliography-entry-collection-path-of entry)
                  "Entry provenance must include the Zotero collection path")
    (assert-true (search "source-system: Zotero"
                         (hyperdoc::bibliography-entry-raw-source-text-of entry))
                 "Entry raw source text must preserve Zotero provenance")))

(defun run-bibliography-candidate-extraction-smoke-test ()
  (let* ((source (make-bibliography-smoke-source))
         (plan (hyperdoc::coachmark-bibliography-authoring-plan :source source
                                                                :signal-error? t))
         (candidate-titles
          (mapcar #'hyperdoc::candidate-topic-title-of
                  (hyperdoc::hyperdoc-authoring-plan-candidate-topics-of plan)))
         (coach-marks (find-candidate-by-title plan "Coach marks"))
         (mobile-onboarding (find-candidate-by-title plan "Mobile onboarding")))
    (dolist (title '("Coach marks"
                     "Onboarding"
                     "User onboarding"
                     "Help overlays"
                     "Guided tours"
                     "Mobile onboarding"))
      (assert-true (member title candidate-titles :test #'string-equal)
                   (format nil "Coachmark fixture should surface candidate topic ~A"
                           title)))
    (assert-true coach-marks
                 "Coach marks candidate must exist")
    (assert-true (plusp (length (hyperdoc::candidate-topic-collection-signals-of coach-marks)))
                 "Coach marks candidate must preserve explicit collection-name provenance evidence")
    (assert-true (plusp (length (hyperdoc::candidate-topic-entry-signals-of coach-marks)))
                 "Coach marks candidate must also preserve entry-derived evidence")
    (assert-true mobile-onboarding
                 "Mobile onboarding candidate must exist")
    (assert-true (plusp (hyperdoc::candidate-topic-support-count-of mobile-onboarding))
                 "Mobile onboarding candidate must keep supporting-entry count")))

(defun run-bibliography-topic-comparison-smoke-test ()
  (let* ((exact (hyperdoc::compare-candidate-topic
                 (make-synthetic-candidate "Topic factory")))
         (alias (hyperdoc::compare-candidate-topic
                 (make-synthetic-candidate "Topic factories")))
         (source (make-bibliography-smoke-source))
         (plan (hyperdoc::coachmark-bibliography-authoring-plan :source source
                                                                :signal-error? t))
         (guided-tours (find-candidate-by-title plan "Guided tours"))
         (guided-report (hyperdoc::compare-candidate-topic guided-tours)))
    (assert-equal :exact-title-match
                  (hyperdoc::topic-comparison-report-status-of exact)
                  "Exact title comparison should win first when the Topics HyperBook already contains the title")
    (assert-equal :alias-match
                  (hyperdoc::topic-comparison-report-status-of alias)
                  "Alias comparison should normalize Topic factories into the existing Topic factory topic")
    (assert-equal :new-topic
                  (hyperdoc::topic-comparison-report-status-of guided-report)
                  "Guided tours from the coachmark fixture should remain a genuinely new topic candidate in the current Topics model")))

(defun run-bibliography-authoring-decision-smoke-test ()
  (let* ((source (make-bibliography-smoke-source))
         (plan (hyperdoc::coachmark-bibliography-authoring-plan :source source
                                                                :signal-error? t))
         (coach-marks (find-decision-by-title plan "Coach marks"))
         (mobile-onboarding (find-decision-by-title plan "Mobile onboarding")))
    (assert-equal :new-topic-proposal
                  (hyperdoc::authoring-decision-kind-of coach-marks)
                  "Coach marks should be classified as a new-topic proposal")
    (assert-equal :add-new-topic-factory
                  (hyperdoc::authoring-decision-topic-action-of coach-marks)
                  "Coach marks should become a proposed new topic factory in the fixture plan")
    (assert-equal :write-new-page
                  (hyperdoc::authoring-decision-page-action-of coach-marks)
                  "Coach marks should become a proposed new HyperDoc page in the fixture plan")
    (assert-true (member :add-topic
                         (hyperdoc::authoring-decision-materialization-consequence-of coach-marks))
                 "Coach marks should propose adding a topic")
    (assert-true (member :write-page
                         (hyperdoc::authoring-decision-materialization-consequence-of coach-marks))
                 "Coach marks should propose writing a page")
    (assert-true (find "Collection path: Research / coachmark"
                       (hyperdoc::authoring-decision-zotero-provenance-evidence-of coach-marks)
                       :test #'string=)
                 "Decision surface must expose Zotero provenance evidence")
    (assert-true (plusp (length (hyperdoc::authoring-decision-entry-title-evidence-of coach-marks)))
                 "Decision surface must expose entry-title evidence")
    (assert-true (plusp (length (hyperdoc::authoring-decision-notes-keywords-tag-evidence-of coach-marks)))
                 "Decision surface must expose notes/keywords/tag evidence")
    (assert-true (plusp (length (hyperdoc::authoring-decision-broader-neighborhood-evidence-of coach-marks)))
                 "Decision surface must expose broader/editorial evidence")
    (assert-true (search "hyperdoc/topics.lisp"
                         (format nil "~{~A~^~%~}"
                                 (hyperdoc::authoring-decision-repo-touch-preview-of coach-marks)))
                 "Decision surface must name the topic file touched by later materialization review")
    (assert-true (search "hyperdoc/Coach marks.html"
                         (format nil "~{~A~^~%~}"
                                 (hyperdoc::authoring-decision-repo-touch-preview-of coach-marks)))
                 "Decision surface must name the page file touched by later materialization review")
    (assert-true (search "coach-marks-topic"
                         (format nil "~{~A~^~%~}"
                                 (hyperdoc::authoring-decision-repo-touch-preview-of coach-marks)))
                 "Decision surface must name the proposed topic function for a new topic")
    (assert-equal :leave-arrangement-only
                  (hyperdoc::authoring-decision-topic-action-of mobile-onboarding)
                  "Mobile onboarding should stay arrangement-only when the broader onboarding candidate is present")
    (assert-equal :arrangement-only-mention
                  (hyperdoc::authoring-decision-page-action-of mobile-onboarding)
                  "Mobile onboarding should be kept as an arrangement-only page mention rather than a standalone page in the first slice")
    (assert-true (member :no-write-yet
                         (hyperdoc::authoring-decision-materialization-consequence-of mobile-onboarding))
                 "Arrangement-only candidates should explicitly report that there is no direct repo write yet")
    (assert-true (search "no direct repo write yet"
                         (format nil "~{~A~^~%~}"
                                 (hyperdoc::authoring-decision-repo-touch-preview-of mobile-onboarding)))
                 "Arrangement-only decisions should expose a no-write-yet touch preview")))

(defun run-bibliography-subcollection-inspector-surface-smoke-test ()
  (let* ((source (make-bibliography-smoke-source))
         (subcollection (hyperdoc::coachmark-bibliography-subcollection :source source
                                                                        :signal-error? t))
         (plan (hyperdoc::plan-bibliography-authoring subcollection
                                                      :source source
                                                      :signal-error? t))
         (subcollection-titles (inspector-view-titles-for-object subcollection))
         (plan-titles (inspector-view-titles-for-object plan)))
    (assert-equal "Collection summary"
                  (first subcollection-titles)
                  "Bibliography subcollection should land on Collection summary before generic tabs")
    (dolist (title '("Collection summary" "Entries" "Candidate topics"))
      (assert-true (member title subcollection-titles :test #'string=)
                   (format nil "Bibliography subcollection should expose ~A" title)))
    (assert-true (member "Page write/update plan" plan-titles :test #'string=)
                 "Authoring plan should expose the decision surface directly")
    (assert-true (member "Materialization preview" plan-titles :test #'string=)
                 "Authoring plan should expose the materialization preview directly")))

(defun run-bibliography-materialization-smoke-test ()
  (let* ((fixture (make-bibliography-smoke-fixture))
         (root (merge-pathnames "bundle/" (getf fixture :root)))
         (source (hyperdoc::make-zotero-bibliography-source
                  :bridge (hyperdoc::make-zotero-library-bridge
                           :db-path (getf fixture :database-path)
                           :storage-root (getf fixture :storage-root))
                  :default-collection "coachmark"
                  :materialization-root root))
         (plan (hyperdoc::coachmark-bibliography-authoring-plan :source source
                                                                :signal-error? t
                                                                :output-root root)))
    (hyperdoc:materialize-bibliography-authoring-plan plan)
    (assert-true (uiop:file-exists-p (merge-pathnames "plan-summary.txt" root))
                 "Materialization should write the plan summary bundle file")
    (assert-true (uiop:file-exists-p
                  (merge-pathnames "topic-factories/coach-marks-topic.lisp" root))
                 "Materialization should write a topic-factory snippet for a new topic")
    (assert-true (uiop:file-exists-p
                  (merge-pathnames "page-fragments/Coach marks.html" root))
                 "Materialization should write a page fragment scaffold for a new page")
    (assert-true (uiop:file-exists-p
                  (merge-pathnames "page-update-notes/onboarding.txt" root))
                 "Materialization should write an arrangement/update note for scoped candidates")
    (let ((topic-entry
           (find :topic-factory-snippet
                 (hyperdoc::hyperdoc-authoring-plan-materialization-entries-of plan)
                 :key #'hyperdoc::bibliography-materialization-entry-kind-of))
          (page-entry
           (find :page-fragment
                 (hyperdoc::hyperdoc-authoring-plan-materialization-entries-of plan)
                 :key #'hyperdoc::bibliography-materialization-entry-kind-of)))
      (assert-true (search "hyperdoc/topics.lisp"
                           (format nil "~{~A~^~%~}"
                                   (hyperdoc::bibliography-materialization-entry-repo-touch-preview-of
                                    topic-entry)))
                   "Materialization preview must name the topic file it proposes to touch later")
      (assert-true (search "hyperdoc/Coach marks.html"
                           (format nil "~{~A~^~%~}"
                                   (hyperdoc::bibliography-materialization-entry-repo-touch-preview-of
                                    page-entry)))
                   "Materialization preview must name the page file it proposes to touch later"))))

(defun run-bibliography-standin-report-smoke-test ()
  (let* ((fixture (make-bibliography-smoke-fixture))
         (source (make-bibliography-smoke-source fixture))
         (report (hyperdoc::bibliography-authoring-plan-standin-report
                  "coachmark"
                  :source source
                  :mode :fixture
                  :entry-page-title "Bibliography subcollections in HyperDoc"
                  :link-text "coachmark")))
    (assert-true (typep report 'hyperdoc::bibliography-authoring-plan-standin-report)
                 "Stand-in seam should expose a first-class bibliography-authoring-plan-standin-report object")
    (assert-equal "tracked-entry-page-selected"
                  (hyperdoc::bibliography-standin-entry-page-selection-classification-of report)
                  "Stand-in report must preserve tracked entry-page selection as a first-class classification")
    (assert-equal "runtime-entry-page-with-live-link"
                  (hyperdoc::bibliography-standin-runtime-surface-inventory-classification-of report)
                  "Stand-in report must preserve runtime-surface inventory classification")
    (assert-equal "tracked-page-no-mismatch-risk"
                  (hyperdoc::bibliography-standin-workspace-vs-flake-mismatch-classification-of report)
                  "Stand-in report must preserve workspace-vs-flake mismatch classification")
    (assert-true (hyperdoc::bibliography-standin-plan-ready-p report)
                 "Stand-in report must show authoring-plan readiness before browser rendering")
    (assert-true (typep (hyperdoc::bibliography-standin-authoring-plan-of report)
                        'hyperdoc::hyperdoc-authoring-plan)
                 "Stand-in report must keep the authoring plan inspectable")
    (assert-true (hyperdoc::bibliography-standin-artifact-bundle-ready-p report)
                 "Stand-in report must preserve artifact-bundle readiness")
    (assert-equal "ready-before-pane-open"
                  (hyperdoc::bibliography-standin-failure-classification-before-browser-of report)
                  "Fixture stand-in report must prove readiness before the browser pane seam")
    (assert-equal "artifact-bundle-written"
                  (hyperdoc::bibliography-standin-last-protocol-boundary-of report)
                  "Stand-in report should record the last protocol boundary it reached")
    (assert-true (plusp (hyperdoc::bibliography-standin-candidate-count-of report))
                 "Stand-in report must keep candidate counts inspectable")
    (assert-true (plusp (hyperdoc::bibliography-standin-decision-count-of report))
                 "Stand-in report must keep decision counts inspectable")
    (assert-true (uiop:file-exists-p
                  (hyperdoc::bibliography-standin-plan-summary-path-of report))
                 "Stand-in report must preserve the generated artifact bundle summary path")))

(defun run-bibliography-subcollections-smoke-tests ()
  (run-bibliography-subcollection-lookup-smoke-test)
  (run-bibliography-subcollection-query-failure-smoke-test)
  (run-bibliography-authoring-plan-deferred-smoke-test)
  (run-bibliography-entry-normalization-smoke-test)
  (run-bibliography-candidate-extraction-smoke-test)
  (run-bibliography-topic-comparison-smoke-test)
  (run-bibliography-authoring-decision-smoke-test)
  (run-bibliography-subcollection-inspector-surface-smoke-test)
  (run-bibliography-materialization-smoke-test)
  (run-bibliography-standin-report-smoke-test)
  (format t "~&Bibliography subcollections smoke tests passed.~%")
  t)
