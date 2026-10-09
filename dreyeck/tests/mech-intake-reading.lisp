;;;; Maintained Mech Reading Acceptance

(DEFPACKAGE #:DREYECK/MECH-INTAKE/TESTS
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:R #:DREYECK/MECH-INTAKE)
                    (#:N #:DREYECK/NESTED-ACTIONS)
                    (#:TM #:DREYECK/TOPICMAP)
                    (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:GIT #:DREYECK/GIT)
                    (#:LAYOUT #:DREYECK/INSPECTOR/TOPICMAP/TALA))
  (:EXPORT #:RUN-TESTS #:RUN-TALA-TESTS))

(IN-PACKAGE #:DREYECK/MECH-INTAKE/TESTS)

(DEFVAR *CHECKS* 0)

(DEFUN CHECK (VALUE &OPTIONAL (DESCRIPTION "Mech intake contract"))
  (INCF *CHECKS*)
  (UNLESS VALUE (ERROR "Failed: ~A" DESCRIPTION))
  VALUE)

(DEFUN RENDER (OBJECT TITLE)
  (LET ((VIEW
         (FIND TITLE (V:ALL-VIEWS OBJECT) :KEY #'V:VIEW-TITLE :TEST #'EQUAL)))
    (CHECK VIEW (FORMAT NIL "~A view" TITLE))
    (V:VIEW-HTML VIEW)
    (CHECK
     (NOTANY (LAMBDA (REF) (TYPEP (CDR REF) 'CONDITION))
             (V:VIEW-REFERENCES VIEW))
     "native references resolve")
    VIEW))

(DEFUN REFERENCES (VIEW) (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW)))

(DEFUN CHECK-PAGES ()
  (LET* ((BOOK
          (HYPERBOOK:FIND-HYPERBOOK "dreyeck/mech-intake/reading"
                                    :SIGNAL-ERROR? T))
         (TEXTS
          '("Reading a Maintained Mech Composition"
            "From Upstream Mech to an Owned Extension"
            "Which Graph Does WALK Produce?"
            "Evidence, Deviations and Acceptance"))
         (CODES
          '("Inspecting Mech Catalog and Source Identities"
            "Tracing EXTRACT through WALK to SOLO"
            "Inspecting Mech Acceptance and Deviations"
            "Navigating a Maintained Mech Composition")))
    (CHECK
     (= 1
        (COUNT "dreyeck/mech-intake/reading"
               (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :KEY
               #'HYPERBOOK:ID-OF :TEST #'EQUAL)))
    (CHECK (EQUAL (FIRST TEXTS) (HYPERBOOK:TITLE-OF BOOK)))
    (CHECK
     (EQ (R:READING-PAGE (FIRST TEXTS))
         (HYPERBOOK:LOOKUP-PATH BOOK (LIST (FIRST TEXTS)))))
    (DOLIST (TITLE TEXTS)
      (LET* ((PAGE (R:READING-PAGE TITLE))
             (DOM (PLUMP-PARSER:PARSE (HYPERDOC:FILE-OF PAGE)))
             (VIEW (RENDER PAGE "Content")))
        (DOLIST (TAG '("title" "h1"))
          (CHECK
           (EQUAL TITLE
                  (PLUMP-DOM:TEXT
                   (FIRST (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM TAG))))))
        (DOLIST (ANCHOR (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM "a"))
          (LET ((TARGET (PLUMP-DOM:ATTRIBUTE ANCHOR "page"))
                (EXPRESSION (PLUMP-DOM:ATTRIBUTE ANCHOR "expr"))
                (AUTHORITY (PLUMP-DOM:ATTRIBUTE ANCHOR "hyperbook")))
            (WHEN TARGET
              (CHECK
               (HYPERBOOK:FIND-PAGE (OR AUTHORITY BOOK) TARGET :SIGNAL-ERROR?
                                    T)))
            (WHEN EXPRESSION
              (LET* ((*PACKAGE* (FIND-PACKAGE :DREYECK/MECH-INTAKE))
                     (VALUE
                      (EVAL
                       (READ-FROM-STRING
                        (PLUMP-DOM:DECODE-ENTITIES EXPRESSION)))))
                (CHECK VALUE "native expression returns a domain object")
                (CHECK (NOT (TYPEP VALUE 'CONDITION)))
                (WHEN (TYPEP VALUE 'TM:TOPICMAP-WORKSPACE)
                  (CHECK (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT VALUE)))))))
        (DOLIST (CODE CODES)
          (CHECK
           (MEMBER (R:READING-PAGE CODE) (REFERENCES VIEW) :TEST #'EQ)))))
    (LET ((EXAMPLES 0))
      (DOLIST (TITLE CODES)
        (LET* ((PAGE (R:READING-PAGE TITLE)) (SOURCE (RENDER PAGE "Source")))
          (HYPERDOC:LOAD-PAGE PAGE)
          (DOLIST (TITLE TEXTS)
            (LET ((LINK
                   (FIND TITLE
                         (HYPERBOOK:PAGE-LINKS-OF (HYPERBOOK:LINKS-OF PAGE))
                         :TEST #'EQUAL :KEY #'HYPERBOOK:TARGET-PAGE-OF)))
              (CHECK LINK "code page links back to reading")
              (CHECK
               (EQ (R:READING-PAGE TITLE)
                   (V:EVAL-THUNK (HYPERBOOK:THUNK-OF LINK))))))
          (DOLIST (REF (REFERENCES SOURCE))
            (WHEN (TYPEP REF 'V:THUNK)
              (INCF EXAMPLES)
              (CHECK (V:EVAL-THUNK REF) "Inspector play example executes")))))
      (CHECK (>= EXAMPLES 6) "all six executable examples discoverable"))))

(DEFUN CHECK-EVIDENCE-AND-SOURCE (COMPOSITION)
  (LET* ((ACCEPTANCE (R:RECORD-OF COMPOSITION "acceptance.json"))
         (BROWSER (GETHASH "browser" (GETHASH "checks" ACCEPTANCE)))
         (IDENTITY (GETHASH "moduleIdentity" ACCEPTANCE)))
    (CHECK (EQUAL "PASS" (GETHASH "aggregate" BROWSER)))
    (CHECK (= 36 (GETHASH "passed" BROWSER)))
    (CHECK (= 0 (GETHASH "exitCode" BROWSER)))
    (LOOP FOR I FROM 1 TO 9
          DO (CHECK
              (EQUAL "PASS"
                     (GETHASH "status"
                              (GETHASH (FORMAT NIL "T~D" I)
                                       (GETHASH "acceptance" BROWSER))))))
    (CHECK
     (EQUAL "FAIL"
            (GETHASH "status"
                     (R:RECORD-OF COMPOSITION "behavioral-equivalence.json"))))
    (CHECK
     (= 33
        (GETHASH "passed"
                 (R:RECORD-OF COMPOSITION "behavioral-equivalence.json"))))
    (CHECK
     (= 2
        (GETHASH "failed"
                 (R:RECORD-OF COMPOSITION "behavioral-equivalence.json"))))
    (CHECK (NULL (GETHASH "extensionCommitOid" IDENTITY)))
    (CHECK
     (EQUALP IDENTITY
             (GETHASH "module"
                      (GETHASH "observation"
                               (R:COMPOSITION-MANIFEST COMPOSITION)))))
    (CHECK
     (EQUAL "dc5edee13803ef230f3f6e2611d3700573e6216685cb95b3938bc92ccf6b358f"
            (GETHASH "sourceContentSha256" IDENTITY)))
    (CHECK
     (NULL
      (GETHASH "runtimeExecuted"
               (GETHASH "observation" (R:COMPOSITION-MANIFEST COMPOSITION)))))
    (DOLIST (SOURCE (R:COMPOSITION-SOURCES COMPOSITION))
      (LET* ((METADATA (N:SOURCE-METADATA SOURCE))
             (VIEW (RENDER SOURCE "Composition source")))
        (CHECK
         (EQ COMPOSITION (FIND COMPOSITION (REFERENCES VIEW) :TEST #'EQ)))
        (WHEN (GETHASH "moduleDigest" METADATA)
          (CHECK (EQUAL "integrations/mech" (GETHASH "modulePath" METADATA)))
          (CHECK
           (EQUAL (GETHASH "sourceContentSha256" IDENTITY)
                  (GETHASH "moduleDigest" METADATA)))
          (CHECK
           (EQUAL (GETHASH "authority" IDENTITY)
                  (GETHASH "authority" METADATA)))
          (CHECK
           (EQUAL (GETHASH "baseCommitOid" IDENTITY)
                  (GETHASH "baseRevision" METADATA)))
          (CHECK
           (EQUAL
            (CONCATENATE 'STRING "integrations/mech/"
                         (GETHASH "moduleRelativePath" METADATA))
            (GETHASH "path" METADATA))
           "owned source path is repository-qualified"))
        (WHEN (GETHASH "moduleDigest" METADATA)
          (LET* ((FILE (R::SOURCE-COMMIT-FILE SOURCE))
                 (REVISION (GIT:GIT-FILE-COMMIT-OF FILE)))
            (CHECK FILE
                   "owned retained source has separate later source-file reference")
            (CHECK
             (EQUAL
              (LIST "https://github.com/RalfBarkow/wiki"
                    "971794d2066f87f63e7685447352340d5276a959")
              (GIT:GIT-REVISION-IDENTITY REVISION)))
            (CHECK
             (EQ :SUBSEQUENT-SOURCE-COMMIT-NOT-EXECUTION-REVISION
                 (GIT:GIT-REVISION-ROLE-OF REVISION)))
            (CHECK
             (EQUAL (GETHASH "path" METADATA) (GIT:GIT-FILE-PATH-OF FILE)))
            (CHECK (MEMBER FILE (REFERENCES VIEW) :TEST #'EQ))
            (CHECK
             (MEMBER SOURCE (GIT:GIT-EVIDENCE-FILE-LOCATIONS-OF FILE) :TEST
                     #'EQ))
            (RENDER FILE "Evidence locations")))
        (LET ((LEGACY (RENDER SOURCE "Source evidence")))
          (CHECK (MEMBER COMPOSITION (REFERENCES LEGACY) :TEST #'EQ)
                 "inherited source view uses this reading context")
          (CHECK
           (MEMBER (R:READING-PAGE "From Upstream Mech to an Owned Extension")
                   (REFERENCES LEGACY) :TEST #'EQ)))
        (CHECK
         (MEMBER (R:READING-PAGE "From Upstream Mech to an Owned Extension")
                 (REFERENCES VIEW) :TEST #'EQ))
        (IF (GETHASH "revision" METADATA)
            (PROGN
             (CHECK
              (EQUAL
               (LIST (GETHASH "authority" METADATA)
                     (GETHASH "revision" METADATA))
               (GIT:GIT-REVISION-IDENTITY (N:SOURCE-REVISION SOURCE))))
             (CHECK
              (EQ (N:SOURCE-REVISION SOURCE)
                  (GIT:GIT-FILE-COMMIT-OF (N:SOURCE-REVISION-FILE SOURCE))))
             (CHECK
              (MEMBER SOURCE
                      (GIT:GIT-EVIDENCE-FILE-LOCATIONS-OF
                       (N:SOURCE-REVISION-FILE SOURCE))
                      :TEST #'EQ)))
            (PROGN
             (CHECK (NULL (N:SOURCE-REVISION SOURCE))
                    "no invented revision for uncommitted or author source")
             (CHECK (NULL (N:SOURCE-REVISION-FILE SOURCE)))
             (CHECK (SEARCH "pending" (GETHASH "immutableLink" METADATA)))))))
    (DOLIST (REVISION (R:COMPOSITION-REVISIONS COMPOSITION))
      (CHECK (NULL (GIT:GIT-COMMIT-REPOSITORY-OF (CDR REVISION))))
      (RENDER (CDR REVISION) "Evidence revision")
      (RENDER (CDR REVISION) "Patch"))
    (CHECK
     (HANDLER-CASE
      (PROGN
       (GIT:MAKE-GIT-REVISION-REFERENCE :AUTHORITY "repo" :OID "a028b4b")
       NIL)
      (ERROR NIL T))
     "short SHA is insufficient")
    (LET ((MISSING
           (GIT:MAKE-GIT-REVISION-REFERENCE :AUTHORITY
                                            "https://example.invalid/unavailable"
                                            :OID
                                            (MAKE-STRING 40 :INITIAL-ELEMENT
                                                         (CHAR "0" 0)))))
      (RENDER MISSING "Evidence revision")
      (RENDER MISSING "Changed files"))
    (LET* ((ORIGINAL (SYMBOL-FUNCTION 'R:READ-EVIDENCE-JSON))
           (MANIFEST (FUNCALL ORIGINAL "manifest.json")))
      (SETF (GETHASH "revision" (AREF (GETHASH "sources" MANIFEST) 0))
              (MAKE-STRING 40 :INITIAL-ELEMENT (CHAR "0" 0)))
      (UNWIND-PROTECT
          (PROGN
           (SETF (SYMBOL-FUNCTION 'R:READ-EVIDENCE-JSON)
                   (LAMBDA (NAME)
                     (IF (EQUAL NAME "manifest.json")
                         MANIFEST
                         (FUNCALL ORIGINAL NAME))))
           (CHECK
            (HANDLER-CASE (PROGN (R:RETAINED-COMPOSITION) NIL) (ERROR NIL T))
            "missing explicit source revision fails closed"))
        (SETF (SYMBOL-FUNCTION 'R:READ-EVIDENCE-JSON) ORIGINAL)))
    (LET ((QUESTIONS (R:OPEN-DECISIONS COMPOSITION)))
      (CHECK (= 4 (LENGTH QUESTIONS)))
      (CHECK
       (EVERY (LAMBDA (Q) (EQ :OPEN (GETF Q :STATUS))) (SUBSEQ QUESTIONS 0 3)))
      (CHECK (NULL (GETF (FOURTH QUESTIONS) :REVISION)))
      (CHECK (NULL (GETF (FOURTH QUESTIONS) :EXPLOIT-ESTABLISHED)))
      (CHECK (EQ :INFERRED (GETF (FOURTH QUESTIONS) :INFERENCE-STATUS)))
      (CHECK
       (SEARCH "run(body, state, 'listen')"
               (N:SOURCE-TEXT (GETF (FOURTH QUESTIONS) :SOURCE)))))))

(DEFUN CHECK-EXECUTION (COMPOSITION)
  (LET* ((TRACE (R:RETAINED-EXECUTION COMPOSITION))
         (RECORD (R:EXECUTION-RECORD TRACE))
         (STAGES (R:TRACE-STAGES TRACE))
         (GRAPH (CDR (ASSOC "neighborhood-graph" STAGES :TEST #'EQUAL)))
         (TYPED (AREF (GETHASH "edges" (GETHASH "extracted" RECORD)) 0)))
    (CHECK (EQUAL "question" (GETHASH "role" TYPED)))
    (CHECK (EQUAL "alpha.fixture.test+shared-page" (GETHASH "toId" TYPED)))
    (CHECK
     (EQ (R:EXECUTION-SOURCE-PAGE TRACE)
         (CDR (ASSOC "source-page" STAGES :TEST #'EQUAL))))
    (CHECK (= 2 (LENGTH (GETHASH "nodes" GRAPH))))
    (CHECK (= 2 (LENGTH (GETHASH "rels" GRAPH))))
    (CHECK
     (EVERY (LAMBDA (REL) (EQUAL "" (GETHASH "type" REL)))
            (GETHASH "rels" GRAPH)))
    (CHECK
     (GETHASH "siteConstraintEvaluated" (AREF (GETHASH "lookups" RECORD) 0)))
    (CHECK
     (NULL
      (GETHASH "siteConstraintEvaluated" (AREF (GETHASH "lookups" RECORD) 1))))
    (CHECK (GETHASH "tracingMatchesUninstrumented" RECORD))
    (CHECK
     (EQUALP (GETHASH "data" (AREF (GETHASH "publications" RECORD) 0))
             (GETHASH "aspects"
                      (AREF
                       (GETHASH "sources"
                                (GETHASH "data"
                                         (AREF (GETHASH "batches" RECORD) 0)))
                       0))))
    (CHECK
     (NOT
      (EQ (GETHASH "data" (AREF (GETHASH "publications" RECORD) 0))
          (GETHASH "aspects"
                   (AREF
                    (GETHASH "sources"
                             (GETHASH "data"
                                      (AREF (GETHASH "batches" RECORD) 0)))
                    0)))))
    (LET ((REVERSE
           (R:RETAINED-EXECUTION COMPOSITION "composite" "beta.fixture.test")))
      (CHECK
       (EQUAL "beta.fixture.test+shared-page"
              (GETHASH "id"
                       (GETHASH "tracedGraphTarget"
                                (R:EXECUTION-RECORD REVERSE)))))
      (CHECK
       (EQUALP (GETHASH "extracted" RECORD)
               (GETHASH "extracted" (R:EXECUTION-RECORD REVERSE)))))
    (LET ((VIEW (RENDER TRACE "Execution trace")))
      (DOLIST (STAGE STAGES)
        (CHECK (MEMBER (CDR STAGE) (REFERENCES VIEW) :TEST #'EQ)))
      (CHECK
       (MEMBER (R:READING-PAGE "Which Graph Does WALK Produce?")
               (REFERENCES VIEW) :TEST #'EQ)))))

(DEFUN CHECK-WORKSPACES (COMPOSITION)
  (DOLIST (MODE '(:SOURCE :EXECUTION))
    (LET* ((WORKSPACE (R:READING-WORKSPACE COMPOSITION MODE))
           (PROJECTION (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))
           (BEFORE (DREYECK/TOPICMAP/TALA:PROJECTION-STATE PROJECTION)))
      (RENDER WORKSPACE "Topicmap")
      (CHECK (EQUAL BEFORE (DREYECK/TOPICMAP/TALA:PROJECTION-STATE PROJECTION))
             "rendering is semantic read only")
      (DOLIST (TOPIC (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION))
        (CHECK (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC))
        (CHECK
         (NOT
          (EQUAL (TM:TOPICMAP-TOPIC-ID-OF TOPIC)
                 (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC)))))
      (DOLIST (ASSOCIATION (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION))
        (LET* ((PROPERTIES (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF ASSOCIATION))
               (WARRANT (GETF PROPERTIES :WARRANT)))
          (CHECK (GETF PROPERTIES :RELATION-KIND))
          (CHECK (GETF PROPERTIES :BASIS))
          (CHECK
           (MEMBER (GETF PROPERTIES :EVIDENCE-STATUS)
                   '(:OBSERVED :DERIVED :INFERRED :HYPOTHESIZED :OPEN)))
          (CHECK
           (EQ (GETF PROPERTIES :EVIDENCE-STATUS) (GETF WARRANT :STATUS)))
          (CHECK (GETF WARRANT :SOURCE))
          (CHECK
           (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION
                                               (TM:TOPICMAP-ASSOCIATION-FROM-OF
                                                ASSOCIATION)))
          (CHECK
           (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION
                                               (TM:TOPICMAP-ASSOCIATION-TO-OF
                                                ASSOCIATION)))))))
  (LET* ((WORKSPACE (R:READING-WORKSPACE COMPOSITION))
         (PROJECTION (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))
         (SOURCE (R:SOURCE-BY-KEY COMPOSITION "upstream:blocks")))
    (CHECK (EQ SOURCE (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE)))
    (TM:TOPICMAP-WORKSPACE-GO-TO WORKSPACE "acceptance")
    (LET ((HISTORY (COPY-LIST (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE)))
          (OBJECT (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE)))
      (CHECK (EQ WORKSPACE (R:SWITCH-PROJECTION WORKSPACE :EXECUTION)))
      (CHECK (EQUAL HISTORY (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE)))
      (CHECK (EQ OBJECT (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE)))
      (R:SWITCH-PROJECTION WORKSPACE :SOURCE))
    (TM:TOPICMAP-WORKSPACE-GO-TO WORKSPACE "catalog-source")
    (LET ((HISTORY (COPY-LIST (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE))))
      (R:SWITCH-PROJECTION WORKSPACE :EXECUTION)
      (CHECK
       (EQUAL "catalog-source" (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
      (CHECK (EQUAL HISTORY (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE)))
      (CHECK (NOT (TM:TOPICMAP-WORKSPACE-POINT-PROJECTED-P WORKSPACE))))
    (CHECK (EQ COMPOSITION (TM:TOPICMAP-PROJECTION-SOURCE-OF PROJECTION)))))

(DEFUN RUN-TESTS ()
  (LET ((*CHECKS* 0) (COMPOSITION (R:RETAINED-COMPOSITION)))
    (CHECK-PAGES)
    (CHECK-EVIDENCE-AND-SOURCE COMPOSITION)
    (CHECK-EXECUTION COMPOSITION)
    (CHECK-WORKSPACES COMPOSITION)
    (DOLIST
        (NAME
         '(R:RETAINED-COMPOSITION R:CATALOG-EVIDENCE R:TRACE-EXTRACT-WALK-SOLO
                                  R:ACCEPTANCE-EVIDENCE
                                  R:MAINTAINED-MECH-WORKSPACE
                                  R:LAYOUT-COMPARISON))
      (CHECK (DREYECK/AUTHORITY-POLICY:FIND-EXAMPLE-CONTRACT NAME)))
    (FORMAT T
            "~&MECH-INTAKE-READING-PASS: ~D checks; 4 Text/4 Code Pages; retained technical PASS / full equivalence FAIL.~%"
            *CHECKS*)
    T))

(DEFUN RUN-TALA-TESTS ()
  (LET ((*CHECKS* 0) (COMPOSITION (R:RETAINED-COMPOSITION)))
    (DOLIST (MODE '(:SOURCE :EXECUTION))
      (LET* ((WORKSPACE (R:READING-WORKSPACE COMPOSITION MODE))
             (BEFORE
              (DREYECK/TOPICMAP/TALA:PROJECTION-STATE
               (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE)))
             (COMPARISON (LAYOUT:COMPARE-WORKSPACE-LAYOUTS WORKSPACE :SEED 44)))
        (CHECK (TYPEP COMPARISON 'LAYOUT:TALA-COMPARISON))
        (CHECK
         (EQ :PASSED (GETF (LAYOUT:COMPARISON-INVARIANTS COMPARISON) :STATUS)))
        (DREYECK/TOPICMAP/TESTS::CHECK-TALA-COMPARISON-NAVIGATION COMPARISON)
        (CHECK
         (EQUAL BEFORE
                (DREYECK/TOPICMAP/TALA:PROJECTION-STATE
                 (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))))))
    (FORMAT T
            "~&MECH-INTAKE-TALA-PASS: ~D checks; both projections preserve objects, warrants and Point/history.~%"
            *CHECKS*)
    T))
