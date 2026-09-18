
(DEFPACKAGE #:DREYECK/CATALOG/TESTS
  (:USE #:CL)
  (:EXPORT #:RUN-CATALOG-STARTUP-SMOKE-TESTS))

(IN-PACKAGE #:DREYECK/CATALOG/TESTS)

(DEFUN CHECK (CONDITION FORMAT-CONTROL &REST FORMAT-ARGUMENTS)
  (UNLESS CONDITION
    (ERROR (APPLY #'FORMAT NIL FORMAT-CONTROL FORMAT-ARGUMENTS))))

(DEFUN DREYECK-ASD-PATHNAME ()
  (TRUENAME
   (ASDF/SYSTEM:SYSTEM-SOURCE-FILE
    (ASDF/SYSTEM:FIND-SYSTEM "dreyeck/catalog/tests"))))

(DEFUN REPOSITORY-DIRECTORY ()
  (UIOP/PATHNAME:PATHNAME-DIRECTORY-PATHNAME (DREYECK-ASD-PATHNAME)))

(DEFUN STARTUP-SCRIPT-PATHNAME ()
  (MERGE-PATHNAMES #P"scripts/serve-catalog.sh" (REPOSITORY-DIRECTORY)))

(DEFUN HISTORICAL-STARTUP-SCRIPT-PATHNAME ()
  (MERGE-PATHNAMES #P"scripts/serve-wiki-link-contract-demo.sh"
                   (REPOSITORY-DIRECTORY)))

(DEFUN DELETED-DEMO-STARTUP-SCRIPT-PATHNAME ()
  (MERGE-PATHNAMES #P"dreyeck/scripts/serve-wiki-link-contract-demo.sh"
                   (REPOSITORY-DIRECTORY)))

(DEFUN REPOSITORY-SHELL-SCRIPT-PATHNAMES ()
  (DIRECTORY (MERGE-PATHNAMES #P"scripts/*.sh" (REPOSITORY-DIRECTORY))))

(DEFUN PRESENTATION-CONTROLLER-COVERAGE-CASES ()
  (COPY-TREE
   '((:FAILURE-ID
      "failure:dreyeck/catalog:presentation-controller-not-materialized"
      :FAILURE-LABEL "Catalog presentation controller not materialized"
      :CONDITION :FUNCTION-NOT-FBOUND-AFTER-SYSTEM-LOAD :TEST-CASE-ID
      "test-case:dreyeck/catalog:fresh-presentation-controller-present"
      :TEST-CASE-LABEL "Fresh catalog presentation controller is present"
      :EVALUATION "(LET* ((PACKAGE (FIND-PACKAGE \"DREYECK/CATALOG\"))
       (SYMBOL
        (AND PACKAGE (FIND-SYMBOL \"CATALOG-PRESENTATION-STATE\" PACKAGE))))
  (ASSERT (AND SYMBOL (FBOUNDP SYMBOL))))"
      :VERIFICATION (:STATUS :PRESENT :VERIFICATION :FRESH-PROCESS)
      :MAY-FAIL-AS-ID
      "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:not-materialized"
      :COVERED-BY-ID
      "association:failure:dreyeck/catalog:presentation-controller-not-materialized:covered-by:fresh-presentation-controller-present")
     (:FAILURE-ID
      "failure:dreyeck/catalog:presentation-controller-mutates-catalog-sequence"
      :FAILURE-LABEL "Catalog presentation controller mutates catalog sequence"
      :CONDITION :CATALOG-SEQUENCE-CHANGED-BY-PRESENTATION-CONTROLLER
      :TEST-CASE-ID
      "test-case:dreyeck/catalog:fresh-presentation-controller-preserves-catalog"
      :TEST-CASE-LABEL
      "Fresh presentation controller preserves catalog sequence" :EVALUATION
      "(LET* ((CATALOG HYPERBOOK:*CATALOG*)
       (BEFORE (COPY-LIST (HYPERBOOK:HYPERBOOKS-OF CATALOG))))
  (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE CATALOG NIL)
  (ASSERT (EQUAL BEFORE (HYPERBOOK:HYPERBOOKS-OF CATALOG))))"
      :VERIFICATION (:STATUS :PRESENT :VERIFICATION :FRESH-PROCESS)
      :MAY-FAIL-AS-ID
      "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:mutates-catalog-sequence"
      :COVERED-BY-ID
      "association:failure:dreyeck/catalog:presentation-controller-mutates-catalog-sequence:covered-by:fresh-presentation-controller-preserves-catalog")
     (:FAILURE-ID
      "failure:dreyeck/catalog:presentation-controller-misrepresents-workspace-topic"
      :FAILURE-LABEL
      "Catalog presentation controller misrepresents workspace topic"
      :CONDITION :WORKSPACE-TOPIC-ID-LABEL-OR-STATE-NOT-PRESERVED :TEST-CASE-ID
      "test-case:dreyeck/catalog:fresh-presentation-controller-presents-workspace"
      :TEST-CASE-LABEL "Fresh presentation controller presents workspace topic"
      :EVALUATION "(LET* ((TOPIC
        (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-TOPIC :ID \"workspace:test\"
                       :TYPE :WORKSPACE :LABEL \"Workspace Test\"))
       (STATE
        (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE HYPERBOOK:*CATALOG*
                                                    (LIST TOPIC)))
       (ENTRY (FIRST (GETF STATE :WORKSPACES))))
  (ASSERT
   (EQUAL ENTRY
          '(:ID \"workspace:test\" :LABEL \"Workspace Test\" :STATE :DISCOVERED)))
  T)"
      :VERIFICATION (:STATUS :PRESENT :VERIFICATION :FRESH-PROCESS)
      :MAY-FAIL-AS-ID
      "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:misrepresents-workspace-topic"
      :COVERED-BY-ID
      "association:failure:dreyeck/catalog:presentation-controller-misrepresents-workspace-topic:covered-by:fresh-presentation-controller-presents-workspace")
     (:FAILURE-ID
      "failure:dreyeck/catalog:presentation-controller-misrepresents-hyperbook"
      :FAILURE-LABEL "Catalog presentation controller misrepresents HyperBook"
      :CONDITION :HYPERBOOK-ID-TITLE-OR-STATE-NOT-PRESENTED-CORRECTLY
      :TEST-CASE-ID
      "test-case:dreyeck/catalog:fresh-presentation-controller-presents-hyperbook"
      :TEST-CASE-LABEL "Fresh presentation controller presents HyperBook"
      :EVALUATION "(LET* ((SUBJECT
        (FIND \"hyperdoc\" (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :KEY
              #'HYPERBOOK:ID-OF :TEST #'STRING=))
       (STATE
        (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE HYPERBOOK:*CATALOG* NIL))
       (ENTRY
        (AND SUBJECT
             (FIND (HYPERBOOK:ID-OF SUBJECT) (GETF STATE :HYPERBOOKS) :KEY
                   (LAMBDA (ITEM) (GETF ITEM :ID)) :TEST #'EQUAL))))
  (ASSERT SUBJECT)
  (ASSERT ENTRY)
  (ASSERT (EQUAL (HYPERBOOK:ID-OF SUBJECT) (GETF ENTRY :ID)))
  (ASSERT (EQUAL (HYPERBOOK:TITLE-OF SUBJECT) (GETF ENTRY :LABEL)))
  (ASSERT (EQ :MATERIALIZED (GETF ENTRY :STATE)))
  T)"
      :VERIFICATION (:STATUS :PRESENT :VERIFICATION :FRESH-PROCESS)
      :MAY-FAIL-AS-ID
      "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:misrepresents-hyperbook"
      :COVERED-BY-ID
      "association:failure:dreyeck/catalog:presentation-controller-misrepresents-hyperbook:covered-by:fresh-presentation-controller-presents-hyperbook")
     (:FAILURE-ID
      "failure:dreyeck/catalog:presentation-controller-misorders-hyperbooks"
      :FAILURE-LABEL "Catalog presentation controller misorders HyperBooks"
      :CONDITION :HYPERBOOKS-NOT-SORTED-BY-TITLE :TEST-CASE-ID
      "test-case:dreyeck/catalog:fresh-presentation-controller-sorts-hyperbooks"
      :TEST-CASE-LABEL "Fresh presentation controller sorts HyperBooks"
      :EVALUATION "(LET* ((EXPECTED
        (SORT
         (MAPCAR #'HYPERBOOK:TITLE-OF
                 (COPY-LIST (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*)))
         #'STRING<))
       (PRESENTED
        (MAPCAR (LAMBDA (ENTRY) (GETF ENTRY :LABEL))
                (GETF
                 (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE
                  HYPERBOOK:*CATALOG* NIL)
                 :HYPERBOOKS))))
  (ASSERT (EQUAL EXPECTED PRESENTED))
  T)"
      :VERIFICATION (:STATUS :PRESENT :VERIFICATION :FRESH-PROCESS)
      :MAY-FAIL-AS-ID
      "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:misorders-hyperbooks"
      :COVERED-BY-ID
      "association:failure:dreyeck/catalog:presentation-controller-misorders-hyperbooks:covered-by:fresh-presentation-controller-sorts-hyperbooks"))))

(DEFUN CONTROLLER-SOURCE-COVERAGE-SPECIFICATION ()
  (COPY-TREE
   '(:PATH-ID "path:dreyeck/catalog:controller-source" :PATH-LABEL
     "Dreyeck catalog controller source path" :CASES
     ((:STEP 1 :TRAVERSES-ID
       "association:path:dreyeck/catalog:controller-source:step-1" :EDGE-ID
       "edge:association:asdf-system:dreyeck/catalog:component:asdf-component:dreyeck/catalog:catalog-presentation-state"
       :FAILURE-ID "failure:dreyeck/catalog:component-missing" :FAILURE-LABEL
       "dreyeck/catalog component missing" :CONDITION :COMPONENT-CHILDREN-NIL
       :TEST-CASE-ID "test-case:dreyeck/catalog:fresh-component-present"
       :TEST-CASE-LABEL "Fresh catalog component is present" :EVALUATION
       "(let* ((system (asdf/system-registry:registered-system \"dreyeck/catalog\")) (children (asdf:component-children system))) (assert (not (null children))))"
       :MAY-FAIL-AS-ID
       "association:edge:dreyeck/catalog:component:may-fail-as:component-missing"
       :COVERED-BY-ID
       "association:failure:dreyeck/catalog:component-missing:covered-by:fresh-component-present"
       :VERIFICATION (:STATUS :PRESENT :VERIFICATION :FRESH-PROCESS))
      (:STEP 2 :TRAVERSES-ID
       "association:path:dreyeck/catalog:controller-source:step-2" :EDGE-ID
       "edge:association:asdf-component:dreyeck/catalog:catalog-presentation-state:source:function:dreyeck/catalog:catalog-presentation-state"
       :FAILURE-ID "failure:dreyeck/catalog:component-source-wrong"
       :FAILURE-LABEL "Catalog component source missing or wrong" :CONDITION
       :COMPONENT-PATHNAME-MISSING-OR-WRONG :TEST-CASE-ID
       "test-case:dreyeck/catalog:fresh-component-source" :TEST-CASE-LABEL
       "Fresh catalog component has expected source" :EVALUATION
       "(LET* ((SYSTEM (ASDF/SYSTEM-REGISTRY:REGISTERED-SYSTEM \"dreyeck/catalog\"))
       (COMPONENT (FIRST (ASDF/COMPONENT:COMPONENT-CHILDREN SYSTEM)))
       (EXPECTED
        (MERGE-PATHNAMES #P\"dreyeck/src/catalog.lisp\"
                         (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY SYSTEM))))
  (ASSERT
   (EQUAL (TRUENAME EXPECTED)
          (TRUENAME (ASDF/COMPONENT:COMPONENT-PATHNAME COMPONENT)))))"
       :MAY-FAIL-AS-ID
       "association:edge:dreyeck/catalog:source:may-fail-as:source-wrong"
       :COVERED-BY-ID
       "association:failure:dreyeck/catalog:component-source-wrong:covered-by:fresh-component-source"
       :VERIFICATION (:STATUS :PRESENT :VERIFICATION :FRESH-PROCESS))))))

(DEFUN FRESH-CATALOG-EVALUATIONS NIL
       (APPEND
               (LIST "(require :asdf)"
                     (FORMAT NIL "(asdf:load-asd #P~S)"
                             (NAMESTRING (DREYECK-ASD-PATHNAME))))
               (MAPCAR (LAMBDA (ENTRY) (GETF ENTRY :EVALUATION))
                       (GETF (CONTROLLER-SOURCE-COVERAGE-SPECIFICATION)
                             :CASES))
               (LIST "(asdf:load-system \"hyperdoc\")"
                     "(asdf:load-system \"hyperbook/server\")"
                     "(assert (null (find-package \"DREYECK/UPSTREAM-INTAKE\")))"
                     "(assert (null (find-package \"DREYECK/FEDWIKI-SOURCE-RELATIONS\")))"
                     "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/upstream-intake\"))))"
                     "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/fedwiki-source-relations\"))))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/wiki-link\")))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/upstream-intake\")))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/fedwiki-source-relations\")))"
                     "(assert (null (find-package \"DREYECK/LISP-IMAGE\")))"
                     "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/lisp-image\"))))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/lisp-image\")))"
                     "(asdf:load-system \"dreyeck/catalog\")")
               (MAPCAR (LAMBDA (ENTRY) (GETF ENTRY :EVALUATION))
                       (PRESENTATION-CONTROLLER-COVERAGE-CASES))
               (LIST
                     "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/lisp-image\")))"
                     "(assert (find-package \"DREYECK/LISP-IMAGE\"))"
                     "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/upstream-intake\")))"
                     "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/fedwiki-source-relations\")))"
                     "(assert (find-package \"DREYECK/UPSTREAM-INTAKE\"))"
                     "(assert (find-package \"DREYECK/FEDWIKI-SOURCE-RELATIONS\"))"
                     "(LET* ((WIKI (HYPERBOOK:FIND-HYPERBOOK \"dreyeck/wiki-link\" :SIGNAL-ERROR? T)) (INTAKE (HYPERBOOK:FIND-HYPERBOOK \"dreyeck/upstream-intake\" :SIGNAL-ERROR? T)) (RELATIONS (HYPERBOOK:FIND-HYPERBOOK \"dreyeck/fedwiki-source-relations\" :SIGNAL-ERROR? T)) (MEMBERS (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*))) (HYPERDOC::ENSURE-PAGES-LOADED WIKI) (HYPERDOC::ENSURE-PAGES-LOADED INTAKE) (HYPERDOC::ENSURE-PAGES-LOADED RELATIONS) (ASSERT (STRING= \"Wiki-link title and slug lookup contracts\" (HYPERBOOK:MAIN-PAGE-ID-OF WIKI))) (ASSERT (HYPERBOOK:FIND-PAGE WIKI \"Wiki-link title and slug lookup contracts\" :SIGNAL-ERROR? T)) (ASSERT (STRING= \"Upstream Intake as a Read-Only Observation\" (HYPERBOOK:MAIN-PAGE-ID-OF INTAKE))) (ASDF/OPERATE:LOAD-SYSTEM \"dreyeck/upstream-intake/tests\") (ASSERT (EQ INTAKE (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/UPSTREAM-INTAKE/TESTS :RUN-PAGE-ASDF-AND-CATALOG-TEST))) (ASSERT (= 1 (COUNT \"dreyeck/fedwiki-source-relations\" MEMBERS :KEY (FUNCTION HYPERBOOK:ID-OF) :TEST (FUNCTION STRING=)))) (ASSERT (STRING= \"FedWiki Component Order and Source Relations\" (HYPERBOOK:TITLE-OF RELATIONS))) (ASSERT (STRING= \"FedWiki Component Order and Source Relations\" (HYPERBOOK:MAIN-PAGE-ID-OF RELATIONS))) (ASSERT (= 1 (HASH-TABLE-COUNT (HYPERDOC:PAGES-OF RELATIONS)))) (ASSERT (HYPERBOOK:FIND-PAGE RELATIONS \"FedWiki Component Order and Source Relations\" :SIGNAL-ERROR? T)) (FORMAT T \"FRESH-DREYECK-CATALOG=~S~%\" (MAPCAR (LAMBDA (BOOK) (LIST (HYPERBOOK:ID-OF BOOK) (HYPERBOOK:TITLE-OF BOOK))) MEMBERS)))"
                     "(let* ((wiki (hyperbook:find-hyperbook \"dreyeck/wiki-link\" :signal-error? t)) (lisp-image (hyperbook:find-hyperbook \"dreyeck/lisp-image\" :signal-error? t)) (members (hyperbook:hyperbooks-of hyperbook:*catalog*))) (hyperdoc::ensure-pages-loaded wiki) (hyperdoc::ensure-pages-loaded lisp-image) (assert (= 1 (count \"dreyeck/lisp-image\" members :key #'hyperbook:id-of :test #'string=))) (assert (string= \"dreyeck.ch Lisp image\" (hyperbook:title-of lisp-image))) (assert (string= \"Lisp image HyperBook refactor\" (hyperbook:main-page-id-of lisp-image))) (assert (= 1 (hash-table-count (hyperdoc:pages-of lisp-image)))) (assert (hyperbook:find-page lisp-image \"Lisp image HyperBook refactor\" :signal-error? t)) (assert (null (hyperbook:find-page wiki \"Lisp image HyperBook refactor\" :signal-error? nil))))"
                     "(let ((git-intake (dreyeck/upstream-intake:make-hyperdoc-host-not-found-intake)) (component-intake (dreyeck/upstream-intake:make-hyperspec-component-intake))) (assert (find \"Upstream Intake\" (html-inspector-views:all-views git-intake) :key #'html-inspector-views:view-title :test #'string=)) (assert (find \"Upstream Intake\" (html-inspector-views:all-views component-intake) :key #'html-inspector-views:view-title :test #'string=)))"
                     "(format t \"Fresh Dreyeck catalog startup tests passed.~%\")"
                     "(PROGN
 (ASSERT (NULL (FIND-PACKAGE :DREYECK/WORKFLOW/AUTHORING)))
 (ASSERT (= 13 (LENGTH (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*))))
 (DOLIST
     (ENTRY
      '((\"dreyeck/topicmap/tala/reading\" \"Reading TALA as a Layout Layer\" 12)
        (\"dreyeck/workflow/reading\" \"Reconstructing Workflow\" 12)))
   (LET* ((BOOK (HYPERBOOK:FIND-HYPERBOOK (FIRST ENTRY) :SIGNAL-ERROR? T)))
     (HYPERDOC::ENSURE-PAGES-LOADED BOOK)
     (LET* ((PAGE (HYPERBOOK:FIND-PAGE BOOK (SECOND ENTRY) :SIGNAL-ERROR? T))
            (VIEW
             (FIND \"Content\" (HTML-INSPECTOR-VIEWS:ALL-VIEWS PAGE) :KEY
                   #'HTML-INSPECTOR-VIEWS:VIEW-TITLE :TEST #'STRING=)))
       (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW)
       (ASSERT
        (= (THIRD ENTRY) (LENGTH (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES VIEW))))
       (DOLIST (WIDGET (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES VIEW))
         (HTML-INSPECTOR-VIEWS:VIEW-HTML (CDR WIDGET))
         (ASSERT
          (= 1
             (COUNT-IF
              (LAMBDA (REF) (TYPEP (CDR REF) 'HTML-INSPECTOR-VIEWS:THUNK))
              (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES (CDR WIDGET)))))))))
 (FORMAT T
         \"NORMAL-LAUNCHER-PROOF: 13 books; TALA 12 and workflow 12 source/play thunks; no authoring runtime.~%\"))"
                     "(LET* ((BOOK (HYPERBOOK:FIND-HYPERBOOK \"dreyeck/upstream-intake\" :SIGNAL-ERROR? T)) (PAGE (HYPERBOOK:FIND-PAGE BOOK \"Upstream Intake as a Read-Only Observation\" :SIGNAL-ERROR? T)) (DOM (PLUMP-PARSER:PARSE (HYPERDOC:FILE-OF PAGE))) (ACTION \"(upstream-intake-removal-workspace-example)\") (ANCHORS (REMOVE-IF-NOT (LAMBDA (A) (EQUAL ACTION (PLUMP-DOM:ATTRIBUTE A \"expr\"))) (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM \"a\"))) (VIEW (FIND \"Content\" (HTML-INSPECTOR-VIEWS:ALL-VIEWS PAGE) :KEY (FUNCTION HTML-INSPECTOR-VIEWS:VIEW-TITLE) :TEST (FUNCTION EQUAL)))) (ASSERT (= 1 (LENGTH ANCHORS))) (ASSERT (EQUAL \"Topicmap\" (PLUMP-DOM:ATTRIBUTE (FIRST ANCHORS) \"view\"))) (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW) (LET* ((WIDGET (FIND-IF (LAMBDA (ENTRY) (SEARCH \"upstream-intake-removal-workspace-example\" (HTML-INSPECTOR-VIEWS:VIEW-HTML (CDR ENTRY)) :TEST (FUNCTION CHAR-EQUAL))) (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES VIEW))) (THUNKS (AND WIDGET (REMOVE-IF-NOT (LAMBDA (ENTRY) (TYPEP (CDR ENTRY) (QUOTE HTML-INSPECTOR-VIEWS:THUNK))) (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES (CDR WIDGET)))))) (ASSERT WIDGET) (ASSERT (= 1 (LENGTH THUNKS))) (LET* ((WORKSPACE (HTML-INSPECTOR-VIEWS:EVAL-THUNK (CDAR THUNKS))) (PROJECTION (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE)) (WORKSPACE-VIEW (FIND \"Topicmap\" (HTML-INSPECTOR-VIEWS:ALL-VIEWS WORKSPACE) :KEY (FUNCTION HTML-INSPECTOR-VIEWS:VIEW-TITLE) :TEST (FUNCTION EQUAL)))) (ASSERT (TYPEP WORKSPACE (QUOTE DREYECK/TOPICMAP:TOPICMAP-WORKSPACE))) (ASSERT (EQUAL \"page:dreyeck/upstream-intake/Observing an Upstream Commit\" (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE))) (PROGN (ASDF/OPERATE:LOAD-SYSTEM \"dreyeck/hyperdoc/curation/tests\") (LET ((EXPECTED (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/HYPERDOC/CURATION/TESTS :EXPECTED-INTAKE-IMPACT :COMMIT)) (ACTUAL (DREYECK/TOPICMAP/CURATION:IMPACT-SUMMARY PROJECTION))) (ASSERT (= (LENGTH EXPECTED) (LENGTH ACTUAL))) (ASSERT (NULL (SET-EXCLUSIVE-OR EXPECTED ACTUAL :TEST (FUNCTION EQUAL)))))) (ASSERT WORKSPACE-VIEW) (LET ((HTML (HTML-INSPECTOR-VIEWS:VIEW-HTML WORKSPACE-VIEW))) (ASSERT (SEARCH \"Point\" HTML)) (ASSERT (SEARCH \"Associations\" HTML))) (FORMAT T \"~%CATALOG-CURATION-DEMO-PASS: existing overview, one action/play thunk, Point and exact warranted impact.~%\"))))")))

(DEFUN FRESH-CATALOG-COMMAND ()
  (APPEND
   (LIST (NAMESTRING SB-EXT:*RUNTIME-PATHNAME*) "--noinform" "--no-userinit"
         "--non-interactive")
   (LOOP FOR FORM IN (FRESH-CATALOG-EVALUATIONS)
         APPEND (LIST "--eval" FORM))))

(DEFUN CHECK-NORMAL-STARTUP-CONTRACT ()
  (LET ((SCRIPT (STARTUP-SCRIPT-PATHNAME)))
    (CHECK (UIOP/FILESYSTEM:FILE-EXISTS-P SCRIPT)
     "The canonical Catalog launcher does not exist: ~A." SCRIPT)
    (UIOP/RUN-PROGRAM:RUN-PROGRAM (LIST "test" "-x" (NAMESTRING SCRIPT)))
    (LET ((SOURCE (UIOP/STREAM:READ-FILE-STRING SCRIPT)))
      (CHECK
       (SEARCH
        "HYPERDOC_CATALOG_SYSTEM=${HYPERDOC_CATALOG_SYSTEM:-dreyeck/catalog}"
        SOURCE)
       "Normal Catalog startup has no explicit dreyeck/catalog default.")
      (CHECK (SEARCH "asdf:load-system system" SOURCE)
       "Normal Catalog startup does not load its configured Catalog system.")
      (CHECK (NULL (SEARCH "HYPERDOC_DEMO_SYSTEM" SOURCE))
       "The canonical Catalog launcher still exposes the demo-system contract."))
    (CHECK (NOT (PROBE-FILE (HISTORICAL-STARTUP-SCRIPT-PATHNAME)))
     "The historical root-level launcher still exists.")
    (CHECK (NOT (PROBE-FILE (DELETED-DEMO-STARTUP-SCRIPT-PATHNAME)))
     "The deleted nested Dreyeck demo launcher still exists.")
    (DOLIST (SHELL-SCRIPT (REPOSITORY-SHELL-SCRIPT-PATHNAMES))
      (LET ((SHELL-SOURCE (UIOP/STREAM:READ-FILE-STRING SHELL-SCRIPT)))
        (CHECK
         (NULL
          (SEARCH "dreyeck/scripts/serve-wiki-link-contract-demo.sh"
                  SHELL-SOURCE))
         "Active launcher ~A still refers to the deleted nested launcher."
         SHELL-SCRIPT))))
  T)

(DEFUN VERIFY-FRESH-CATALOG-RECONSTRUCTION-SEQUENCE ()
  (LET* ((CONTROLLER-SOURCE-SPECIFICATION
          (CONTROLLER-SOURCE-COVERAGE-SPECIFICATION))
         (CONTROLLER-SOURCE-CASES
          (GETF CONTROLLER-SOURCE-SPECIFICATION :CASES))
         (CONTROLLER-SOURCE-EVALUATIONS
          (MAPCAR (LAMBDA (ENTRY) (GETF ENTRY :EVALUATION))
                  CONTROLLER-SOURCE-CASES))
         (PRESENTATION-CONTROLLER-CASES
          (PRESENTATION-CONTROLLER-COVERAGE-CASES))
         (PRESENTATION-CONTROLLER-EVALUATIONS
          (MAPCAR (LAMBDA (ENTRY) (GETF ENTRY :EVALUATION))
                  PRESENTATION-CONTROLLER-CASES))
         (FRESH-EVALUATIONS (FRESH-CATALOG-EVALUATIONS))
         (CATALOG-LOAD-EVALUATION "(asdf:load-system \"dreyeck/catalog\")")
         (CONTROLLER-SOURCE-START
          (SEARCH CONTROLLER-SOURCE-EVALUATIONS FRESH-EVALUATIONS :TEST
                  #'STRING=))
         (CATALOG-LOAD-POSITION
          (POSITION CATALOG-LOAD-EVALUATION FRESH-EVALUATIONS :TEST #'STRING=))
         (PRESENTATION-CONTROLLER-START
          (SEARCH PRESENTATION-CONTROLLER-EVALUATIONS FRESH-EVALUATIONS :TEST
                  #'STRING=)))
    (ASSERT (= 2 (LENGTH CONTROLLER-SOURCE-CASES)))
    (ASSERT (= 5 (LENGTH PRESENTATION-CONTROLLER-CASES)))
    (ASSERT CONTROLLER-SOURCE-START)
    (ASSERT CATALOG-LOAD-POSITION)
    (ASSERT PRESENTATION-CONTROLLER-START)
    (ASSERT (< CONTROLLER-SOURCE-START CATALOG-LOAD-POSITION))
    (ASSERT (= PRESENTATION-CONTROLLER-START (1+ CATALOG-LOAD-POSITION)))
    (LIST :CONTROLLER-SOURCE
          (LIST :CASE-COUNT (LENGTH CONTROLLER-SOURCE-CASES) :EVALUATION-COUNT
                (LENGTH CONTROLLER-SOURCE-EVALUATIONS) :START
                CONTROLLER-SOURCE-START :BEFORE-CATALOG-LOAD-P
                (< CONTROLLER-SOURCE-START CATALOG-LOAD-POSITION))
          :CATALOG-LOAD
          (LIST :EVALUATION CATALOG-LOAD-EVALUATION :POSITION
                CATALOG-LOAD-POSITION)
          :PRESENTATION-CONTROLLER
          (LIST :CASE-COUNT (LENGTH PRESENTATION-CONTROLLER-CASES)
                :EVALUATION-COUNT (LENGTH PRESENTATION-CONTROLLER-EVALUATIONS)
                :START PRESENTATION-CONTROLLER-START
                :IMMEDIATELY-AFTER-CATALOG-LOAD-P
                (= PRESENTATION-CONTROLLER-START (1+ CATALOG-LOAD-POSITION)))
          :FRESH-EVALUATION-COUNT (LENGTH FRESH-EVALUATIONS))))

(DEFUN RUN-CATALOG-STARTUP-SMOKE-TESTS ()
  (CHECK-NORMAL-STARTUP-CONTRACT)
  (VERIFY-FRESH-CATALOG-RECONSTRUCTION-SEQUENCE)
  (UIOP/RUN-PROGRAM:RUN-PROGRAM (FRESH-CATALOG-COMMAND) :DIRECTORY
                                (REPOSITORY-DIRECTORY) :OUTPUT
                                *STANDARD-OUTPUT* :ERROR-OUTPUT *ERROR-OUTPUT*)
  (FORMAT T "Dreyeck Catalog startup smoke tests passed.~%")
  T)

(DEFUN DREYECK/CATALOG/TESTS::RUN-TESTS ()
  (ASSERT (DREYECK/CATALOG/TESTS:RUN-CATALOG-STARTUP-SMOKE-TESTS))
  (LET ((OFFER (DREYECK/CATALOG::ADMIT :CATALOG "related-topics-for-topic")))
    (ASSERT
     (MEMBER OFFER (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :TEST #'EQ))
    (ASSERT
     (NOT
      (SLOT-BOUNDP OFFER 'DREYECK/PAGE-ATTACHED-WORKSPACE-OFFER::WORKSPACE)))
    (LIST :STATUS :PASSED :OFFER OFFER :WORKSPACE-MATERIALIZED-P NIL)))


