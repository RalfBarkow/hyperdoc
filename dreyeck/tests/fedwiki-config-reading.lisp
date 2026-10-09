;;;; FedWiki Configuration Reader Acceptance

(DEFPACKAGE #:DREYECK/FEDWIKI-CONFIG/TESTS
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:R #:DREYECK/FEDWIKI-CONFIG)
                    (#:N #:DREYECK/NESTED-ACTIONS)
                    (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:GIT #:DREYECK/GIT)
                    (#:TM #:DREYECK/TOPICMAP)
                    (#:LAYOUT #:DREYECK/INSPECTOR/TOPICMAP/TALA))
  (:EXPORT #:RUN-TESTS #:RUN-TALA-TESTS))

(IN-PACKAGE #:DREYECK/FEDWIKI-CONFIG/TESTS)

(DEFVAR *CHECKS* 0)

(DEFUN CHECK (VALUE &OPTIONAL (REASON "FedWiki reading contract"))
  (INCF *CHECKS*)
  (UNLESS VALUE (ERROR "Failed: ~A" REASON))
  VALUE)

(DEFUN RENDER (OBJECT TITLE)
  (LET ((VIEW
         (FIND TITLE (V:ALL-VIEWS OBJECT) :KEY #'V:VIEW-TITLE :TEST #'EQUAL)))
    (CHECK VIEW TITLE)
    (V:VIEW-HTML VIEW)
    (CHECK
     (NOTANY (LAMBDA (ENTRY) (TYPEP (CDR ENTRY) 'CONDITION))
             (V:VIEW-REFERENCES VIEW))
     "native references resolve")
    VIEW))

(DEFUN REFS (VIEW) (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW)))

(DEFUN CHECK-PAGES ()
  (LET* ((BOOK
          (HYPERBOOK:FIND-HYPERBOOK "dreyeck/fedwiki-config/reading"
                                    :SIGNAL-ERROR? T))
         (TEXTS
          '("Reading FedWiki Configuration and Fork Behavior"
            "From Declared Inputs to Resolved Packages"
            "Two Mech Profiles in One Wiki Recipe"
            "Forking a Local Page Across Origins"))
         (CODES
          '("Inspecting Declared and Resolved Wiki Sources"
            "Inspecting Mech Package Composition"
            "Inspecting Fork Access and Journal Provenance"
            "Navigating Deployment and Fork Projections"))
         (PLAY-COUNT 0))
    (CHECK
     (= 1
        (COUNT "dreyeck/fedwiki-config/reading"
               (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :KEY
               #'HYPERBOOK:ID-OF :TEST #'EQUAL)))
    (CHECK (EQUAL (FIRST TEXTS) (HYPERBOOK:TITLE-OF BOOK)))
    (DOLIST (TITLE TEXTS)
      (LET* ((PAGE (R:READING-PAGE TITLE))
             (DOM (PLUMP-PARSER:PARSE (HYPERDOC:FILE-OF PAGE)))
             (VIEW (RENDER PAGE "Content")))
        (DOLIST (TAG '("title" "h1"))
          (CHECK
           (EQUAL TITLE
                  (PLUMP-DOM:TEXT
                   (FIRST (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM TAG))))))
        (DOLIST (A (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM "a"))
          (LET ((TARGET (PLUMP-DOM:ATTRIBUTE A "page"))
                (AUTHORITY (PLUMP-DOM:ATTRIBUTE A "hyperbook"))
                (EXPR (PLUMP-DOM:ATTRIBUTE A "expr")))
            (WHEN TARGET
              (CHECK
               (HYPERBOOK:FIND-PAGE (OR AUTHORITY BOOK) TARGET :SIGNAL-ERROR?
                                    T)))
            (WHEN EXPR
              (LET* ((*PACKAGE* (FIND-PACKAGE :DREYECK/FEDWIKI-CONFIG))
                     (VALUE
                      (EVAL
                       (READ-FROM-STRING (PLUMP-DOM:DECODE-ENTITIES EXPR)))))
                (CHECK VALUE
                 "native expression returns an actual domain object")
                (CHECK (NOT (TYPEP VALUE 'CONDITION)))
                (WHEN (TYPEP VALUE 'R:DEPLOYMENT-SOURCE)
                  (RENDER VALUE "Configuration source"))
                (WHEN (TYPEP VALUE 'R:CONFIGURATION-BASE)
                  (RENDER VALUE "Configuration"))
                (WHEN (TYPEP VALUE 'R:MECH-PROFILE)
                  (RENDER VALUE "Mech profile"))
                (WHEN (TYPEP VALUE 'R:FORK-CASE)
                  (RENDER VALUE "Fork contract"))))))
        (DOLIST (TITLE CODES)
          (CHECK (MEMBER (R:READING-PAGE TITLE) (REFS VIEW) :TEST #'EQ)))))
    (DOLIST (TITLE CODES)
      (LET* ((PAGE (R:READING-PAGE TITLE)) (VIEW (RENDER PAGE "Source")))
        (HYPERDOC:LOAD-PAGE PAGE)
        (DOLIST (TITLE TEXTS)
          (LET ((LINK
                 (FIND TITLE
                       (HYPERBOOK:PAGE-LINKS-OF (HYPERBOOK:LINKS-OF PAGE)) :KEY
                       #'HYPERBOOK:TARGET-PAGE-OF :TEST #'EQUAL)))
            (CHECK LINK "Code Page returns to explanatory reading")
            (CHECK
             (EQ (R:READING-PAGE TITLE)
                 (V:EVAL-THUNK (HYPERBOOK:THUNK-OF LINK))))))
        (DOLIST (REF (REFS VIEW))
          (WHEN (TYPEP REF 'V:THUNK)
            (INCF PLAY-COUNT)
            (CHECK (V:EVAL-THUNK REF)
             "actual Inspector play thunk executes")))))
    (CHECK (= 8 PLAY-COUNT)
     "eight Inspector-accessible executable Lisp examples")))

(DEFUN CHECK-SOURCES (CONTEXT)
  (CHECK (= 33 (LENGTH (R:CONTEXT-SOURCES CONTEXT))))
  (DOLIST (SOURCE (R:CONTEXT-SOURCES CONTEXT))
    (LET* ((METADATA (N:SOURCE-METADATA SOURCE))
           (REVISION (N:SOURCE-REVISION SOURCE))
           (FILE (N:SOURCE-REVISION-FILE SOURCE))
           (VIEW (RENDER SOURCE "Configuration source")))
      (CHECK
       (EQUAL (GETHASH "sha256" METADATA)
              (DREYECK/MECH-INTAKE::FILE-DIGEST (N:SOURCE-FILE SOURCE))))
      (CHECK
       (EQUAL (GETHASH "excerptSha256" METADATA)
              (DREYECK/MECH-INTAKE::TEXT-DIGEST (N:SOURCE-TEXT SOURCE))))
      (CHECK
       (EQUAL
        (LIST (GETHASH "authority" METADATA) (GETHASH "revision" METADATA))
        (GIT:GIT-REVISION-IDENTITY REVISION)))
      (CHECK (EQ REVISION (GIT:GIT-FILE-COMMIT-OF FILE)))
      (CHECK (EQUAL (GETHASH "path" METADATA) (GIT:GIT-FILE-PATH-OF FILE)))
      (CHECK
       (MEMBER SOURCE (GIT:GIT-EVIDENCE-FILE-LOCATIONS-OF FILE) :TEST #'EQ))
      (CHECK (MEMBER REVISION (REFS VIEW) :TEST #'EQ))
      (CHECK (MEMBER FILE (REFS VIEW) :TEST #'EQ))
      (CHECK
       (MEMBER
        (R:READING-PAGE "Reading FedWiki Configuration and Fork Behavior")
        (REFS VIEW) :TEST #'EQ))
      (CHECK (MEMBER CONTEXT (REFS VIEW) :TEST #'EQ))
      (CHECK (NULL (GIT:GIT-COMMIT-REPOSITORY-OF REVISION))
       "no development checkout pathname crosses runtime boundary")
      (RENDER REVISION "Evidence revision")
      (RENDER FILE "Evidence locations")
      (RENDER REVISION "Patch")
      (CHECK
       (MEMBER SOURCE (REFS (RENDER FILE "Evidence locations")) :TEST #'EQ))
      (CHECK
       (MEMBER CONTEXT (REFS (RENDER SOURCE "Source evidence")) :TEST #'EQ)))))

(DEFUN CHECK-CONFIGURATIONS (CONTEXT)
  (CHECK (= 3 (LENGTH (R:CONTEXT-BASES CONTEXT))))
  (LOOP FOR (KEY BRANCH
             OID) IN '(("localhost" "localhost"
                        "4dd6be43453b451615ce04fc9ac4e5792eede46e")
                       ("dreyeck" "dreyeck.ch"
                        "db98a893a7c710fcb3506150b68b1aa08915c47e")
                       ("ralfbarkow" "wiki.ralfbarkow.ch"
                        "6774447eff17d705a3083378ab2c9a93b237cf91"))
        FOR BASE = (R:CONFIGURATION-OF CONTEXT KEY)
        FOR RECORD = (R:CONFIGURATION-RECORD BASE)
        DO (CHECK (EQUAL BRANCH (GETHASH "branch" RECORD))) (CHECK
                                                             (EQUAL
                                                              (LIST
                                                               "https://github.com/RalfBarkow/wiki"
                                                               OID)
                                                              (GIT:GIT-REVISION-IDENTITY
                                                               (R:CONFIGURATION-REVISION
                                                                BASE)))) (CHECK
                                                                          (EQUAL
                                                                           "unknown"
                                                                           (GETHASH
                                                                            "status"
                                                                            (GETHASH
                                                                             "activeDeployment"
                                                                             RECORD)))) (LET* ((COMPONENTS
                                                                                                (GETHASH
                                                                                                 "components"
                                                                                                 (GETHASH
                                                                                                  "composition"
                                                                                                  (R:CONFIGURATION-PACKAGES
                                                                                                   BASE))))
                                                                                               (CLIENT
                                                                                                (GETHASH
                                                                                                 "wiki-client"
                                                                                                 COMPONENTS))
                                                                                               (SERVER
                                                                                                (GETHASH
                                                                                                 "wiki-server"
                                                                                                 COMPONENTS)))
                                                                                          (CHECK
                                                                                           (EQUAL
                                                                                            (GETHASH
                                                                                             "packageVersion"
                                                                                             (GETHASH
                                                                                              "client"
                                                                                              RECORD))
                                                                                            (GETHASH
                                                                                             "version"
                                                                                             CLIENT)))
                                                                                          (CHECK
                                                                                           (EQUAL
                                                                                            (GETHASH
                                                                                             "packageVersion"
                                                                                             (GETHASH
                                                                                              "server"
                                                                                              RECORD))
                                                                                            (GETHASH
                                                                                             "version"
                                                                                             SERVER)))))
  (LET* ((BASE (R:CONFIGURATION-OF CONTEXT "localhost"))
         (RECORD (R:CONFIGURATION-RECORD BASE))
         (DECLARED
          (FIND "wiki-client-src" (GETHASH "declaredInputs" RECORD) :KEY
                (LAMBDA (X) (GETHASH "name" X)) :TEST #'EQUAL))
         (INPUT
          (FIND "wiki-client-src" (R:CONFIGURATION-INPUTS BASE) :KEY
                (LAMBDA (X) (GETHASH "name" X)) :TEST #'EQUAL)))
    (CHECK
     (SEARCH "1aba55920f95b957bc8ccf3b3648c9b23d534c9a"
             (GETHASH "url" DECLARED)))
    (CHECK
     (EQUAL "4b290709a1906c2010306f0f47ebfad530d8b4b6"
            (GETHASH "rev" (GETHASH "locked" INPUT))))
    (CHECK
     (EQUAL
      (LIST "https://github.com/RalfBarkow/wiki-client"
            "4b290709a1906c2010306f0f47ebfad530d8b4b6")
      (GIT:GIT-REVISION-IDENTITY (R:CONFIGURATION-CLIENT BASE)))))
  (LET* ((RECORD
          (R:CONFIGURATION-RECORD (R:CONFIGURATION-OF CONTEXT "ralfbarkow")))
         (CLIENT (GETHASH "client" RECORD)))
    (CHECK
     (EQUAL "reconstructed-npm-archive" (GETHASH "selectionKind" CLIENT)))
    (CHECK
     (EQUAL "d59dbd68c2a539d32add72e06d2fd74e9d6d60c2" (GETHASH "oid" CLIENT)))
    (CHECK
     (EQUAL "f3c72d9fc31a3db8a296c7f2d05b36364395e4fe"
            (GETHASH "oid" (GETHASH "personalRevision" CLIENT)))))
  (LET* ((BASE (R:CONFIGURATION-OF CONTEXT "ralfbarkow"))
         (VIEW (RENDER BASE "Configuration")))
    (DOLIST
        (KEY
         '("p41-provenance" "p41-source-inputs" "p41-wiki-client"
           "p41-production-client" "p41-build"))
      (CHECK (MEMBER (R:SOURCE-OF CONTEXT KEY) (REFS VIEW) :TEST #'EQ)
       "P41 patch/input definitions are directly navigable"))
    (CHECK
     (FIND "reconstruct"
           (GETHASH "availableOutputs" (R:CONFIGURATION-RECORD BASE)) :TEST
           #'EQUAL)))
  (LET* ((RECORD (R:RECORD-OF CONTEXT "package-evidence"))
         (TESTS (GETHASH "moduleTests" RECORD))
         (FULL (GETHASH "fullBehavioralEquivalence" TESTS)))
    (CHECK (EQUAL "FAIL" (GETHASH "status" FULL)))
    (CHECK (= 33 (GETHASH "passed" FULL)))
    (CHECK (= 2 (GETHASH "failed" FULL)))
    (CHECK (= 4 (GETHASH "ambiguityCases" TESTS)))
    (CHECK (= 4 (GETHASH "uninstrumentedControls" TESTS)))
    (CHECK (NULL (GETHASH "built" (GETHASH "linux" RECORD)))))
  (DOLIST (NAME '("upstream" "discourse"))
    (LET* ((PROFILE (R:PROFILE-OF CONTEXT NAME))
           (MECH (GETHASH "mech" (R:PROFILE-RECORD PROFILE))))
      (CHECK (EQUAL NAME (GETHASH "profile" MECH)))
      (CHECK
       (EQUAL "a028b4bba04e539dcaa090423d38a00a0050489d"
              (GETHASH "oid" (GETHASH "source" MECH))))
      (IF (EQUAL NAME "upstream")
          (CHECK (NULL (GETHASH "extension" MECH)))
          (CHECK (GETHASH "extension" MECH)))
      (RENDER PROFILE "Mech profile")))
  (LET ((OLD
         (DREYECK/MECH-INTAKE:RECORD-OF (R:CONTEXT-MECH CONTEXT)
                                        "acceptance.json")))
    (CHECK (NULL (GETHASH "extensionCommitOid" (GETHASH "moduleIdentity" OLD)))
     "historical execution identity is not relabeled")))

(DEFUN CHECK-FORKS (CONTEXT)
  (DOLIST (LABEL '("localhost" "dreyeck" "ralfbarkow"))
    (LET* ((CASE (R:FORK-OF CONTEXT LABEL))
           (RECORD (R:FORK-RECORD CASE))
           (TESTS (GETHASH "tests" RECORD))
           (ACQUISITION (AREF TESTS 0))
           (PROVENANCE (AREF TESTS 4)))
      (CHECK (= 8 (LENGTH TESTS)))
      (CHECK (SEARCH "PASS: controls" (GETHASH "status" RECORD)))
      (CHECK (= 64 (LENGTH (GETHASH "servedClientSha256" RECORD))))
      (CHECK (GETHASH "packageProvenance" RECORD))
      (CHECK
       (SEARCH "disposable browser route" (GETHASH "fixtureBoundary" RECORD)))
      (CHECK (= 403 (GETHASH "httpStatus" (AREF TESTS 5))))
      (CHECK (GETHASH "remoteUnchanged" (AREF TESTS 5)))
      (IF (EQUAL LABEL "ralfbarkow")
          (PROGN
           (CHECK (= 0 (GETHASH "actualSourceRequests" ACQUISITION)))
           (CHECK (SEARCH "Blocked loopback" (GETHASH "error" ACQUISITION))))
          (CHECK (EQUAL "PASS" (GETHASH "status" ACQUISITION))))
      (IF (EQUAL LABEL "dreyeck")
          (CHECK (EQUAL "localhost:3000" (GETHASH "site" PROVENANCE)))
          (CHECK (NULL (GETHASH "site" PROVENANCE))))
      (RENDER CASE "Fork contract")))
  (CHECK
   (SEARCH "shouldStripLoopbackProvenance"
           (N:SOURCE-TEXT (R:SOURCE-OF CONTEXT "localhost-pageHandler"))))
  (CHECK
   (SEARCH "shouldBlockLoopbackTarget"
           (N:SOURCE-TEXT (R:SOURCE-OF CONTEXT "ralfbarkow-siteAdapter"))))
  (LET ((RECORD (R:RECORD-OF CONTEXT "fork-evidence")))
    (CHECK (NULL (GETHASH "productionAuthenticationVerified" RECORD)))
    (CHECK (NULL (GETHASH "productionHTTPSLocalNetworkAccessVerified" RECORD)))
    (CHECK (NULL (GETHASH "clientServerSourceChanges" RECORD)))
    (CHECK (NULL (GETHASH "weakenedPolicy" RECORD)))
    (CHECK (> (LENGTH (GETHASH "fixtureDevelopmentObservations" RECORD)) 0)
     "failed fixture attempt retained separately")))

(DEFUN CHECK-WORKSPACES (CONTEXT)
  (LOOP FOR MODE IN '(:DEPLOYMENT :FORK)
        FOR
        COUNT IN '(26 26)
        FOR EDGES IN '(26 32)
        DO (LET* ((WORKSPACE (R:READING-WORKSPACE CONTEXT MODE))
                  (PROJECTION (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))
                  (BEFORE (DREYECK/TOPICMAP/TALA:PROJECTION-STATE PROJECTION)))
             (CHECK
              (= COUNT (LENGTH (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION))))
             (CHECK
              (= EDGES
                 (LENGTH (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION))))
             (RENDER WORKSPACE "Topicmap")
             (CHECK
              (EQUAL BEFORE
                     (DREYECK/TOPICMAP/TALA:PROJECTION-STATE PROJECTION))
              "rendering does not change persisted semantics")
             (DOLIST (TOPIC (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION))
               (CHECK (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC))
               (CHECK (NOT (STRINGP (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC)))
                "domain object, not an ID/title"))
             (DOLIST (EDGE (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION))
               (LET* ((PROPERTIES (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF EDGE))
                      (WARRANT (GETF PROPERTIES :WARRANT)))
                 (CHECK (GETF PROPERTIES :RELATION-KIND))
                 (CHECK (GETF PROPERTIES :BASIS))
                 (CHECK (GETF WARRANT :SOURCE))
                 (CHECK
                  (MEMBER (GETF WARRANT :STATUS) '(:OBSERVED :DERIVED :OPEN)))
                 (CHECK
                  (EQ (GETF WARRANT :STATUS)
                      (GETF PROPERTIES :EVIDENCE-STATUS)))
                 (CHECK
                  (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION
                                                      (TM:TOPICMAP-ASSOCIATION-FROM-OF
                                                       EDGE)))
                 (CHECK
                  (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION
                                                      (TM:TOPICMAP-ASSOCIATION-TO-OF
                                                       EDGE)))
                 (WHEN
                     (EQ :DEPLOYMENT-BOUNDARY (GETF PROPERTIES :RELATION-KIND))
                   (CHECK (EQ :OPEN (GETF WARRANT :STATUS))))))))
  (LET ((PROJECTION (R:FORK-PROJECTION CONTEXT)))
    (DOLIST (KEY '("localhost" "ralfbarkow"))
      (CHECK
       (EQ (R:SOURCE-OF CONTEXT (CONCATENATE 'STRING KEY "-networkSecurity"))
           (TM:TOPICMAP-TOPIC-OBJECT-OF
            (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION
                                                (CONCATENATE 'STRING KEY
                                                             "-policy"))))
       "policy Topic holds the actual source object")))
  (LET* ((WORKSPACE (R:READING-WORKSPACE CONTEXT))
         (BASE (R:CONFIGURATION-OF CONTEXT "localhost")))
    (CHECK (EQ BASE (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE)))
    (LET ((HISTORY (COPY-LIST (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE))))
      (R:SWITCH-PROJECTION WORKSPACE :FORK)
      (CHECK (EQUAL HISTORY (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE)))
      (CHECK (EQ BASE (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE))))
    (R:SWITCH-PROJECTION WORKSPACE :DEPLOYMENT)
    (TM:TOPICMAP-WORKSPACE-GO-TO WORKSPACE "installer")
    (LET ((HISTORY (COPY-LIST (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE))))
      (R:SWITCH-PROJECTION WORKSPACE :FORK)
      (CHECK (NOT (TM:TOPICMAP-WORKSPACE-POINT-PROJECTED-P WORKSPACE)))
      (CHECK (EQUAL HISTORY (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE))))))

(DEFUN CHECK-READER-JOURNEY (CONTEXT)
  (LET* ((BASE (R:CONFIGURATION-OF CONTEXT "localhost"))
         (VIEW (RENDER BASE "Configuration"))
         (FLAKE (R:SOURCE-OF CONTEXT "localhost-flake"))
         (LOCK (R:SOURCE-OF CONTEXT "localhost-lock"))
         (DEFINITION (R:SOURCE-OF CONTEXT "localhost-pageHandler"))
         (REVISION (R:CONFIGURATION-CLIENT BASE)))
    (DOLIST (OBJECT (LIST FLAKE LOCK DEFINITION REVISION))
      (CHECK (MEMBER OBJECT (REFS VIEW) :TEST #'EQ)
       "configuration to source and client navigation"))
    (CHECK (EQ REVISION (N:SOURCE-REVISION DEFINITION)))
    (CHECK
     (MEMBER DEFINITION
             (REFS
              (RENDER (N:SOURCE-REVISION-FILE DEFINITION)
               "Evidence locations"))
             :TEST #'EQ))
    (LET ((CASE (R:FORK-OF CONTEXT "localhost")))
      (CHECK (MEMBER CASE (REFS VIEW) :TEST #'EQ))
      (CHECK
       (MEMBER DEFINITION (REFS (RENDER CASE "Fork contract")) :TEST #'EQ)))
    (LET* ((WORKSPACE (R:READING-WORKSPACE CONTEXT :FORK))
           (PROJECTION (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))
           (TOPIC
            (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION "localhost-put")))
      (CHECK (EQ DEFINITION (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC)))
      (TM:TOPICMAP-WORKSPACE-GO-TO WORKSPACE "localhost-put")
      (CHECK
       (EQ DEFINITION (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE))))))

(DEFUN RUN-TESTS ()
  (LET ((*CHECKS* 0)
        (SAVED (SYMBOL-FUNCTION 'GIT:GIT-RUN-STRING))
        (GIT-CALLS 0))
    (UNWIND-PROTECT
        (PROGN
         (SETF (SYMBOL-FUNCTION 'GIT:GIT-RUN-STRING)
                 (LAMBDA (&REST ARGS)
                   (DECLARE (IGNORE ARGS))
                   (INCF GIT-CALLS)
                   (ERROR "Reading must not call Git")))
         (LET ((CONTEXT (R:RETAINED-CONFIGURATIONS)))
           (CHECK-PAGES)
           (CHECK-SOURCES CONTEXT)
           (CHECK-CONFIGURATIONS CONTEXT)
           (CHECK-FORKS CONTEXT)
           (CHECK-WORKSPACES CONTEXT)
           (CHECK-READER-JOURNEY CONTEXT))
         (CHECK (= 0 GIT-CALLS) "portable reading does not invoke Git")
         (FORMAT T
                 "~&FEDWIKI-CONFIG-READING-PASS: ~D checks; 4 Text/4 Code Pages; 8 runnable examples; complete native reader journey; no Git.~%"
                 *CHECKS*)
         T)
      (SETF (SYMBOL-FUNCTION 'GIT:GIT-RUN-STRING) SAVED))))

(DEFUN RUN-TALA-TESTS ()
  (LET ((*CHECKS* 0) (CONTEXT (R:RETAINED-CONFIGURATIONS)))
    (DOLIST (MODE '(:DEPLOYMENT :FORK))
      (LET* ((WORKSPACE (R:READING-WORKSPACE CONTEXT MODE))
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
            "~&FEDWIKI-CONFIG-TALA-PASS: ~D checks; both projections retain objects, warrants and Point/history.~%"
            *CHECKS*)
    T))
