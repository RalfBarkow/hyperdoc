;;;; Inspecting Mech Catalog and Source Identities

(DEFPACKAGE #:DREYECK/MECH-INTAKE
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:TM #:DREYECK/TOPICMAP)
                    (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:N #:DREYECK/NESTED-ACTIONS)
                    (#:GIT #:DREYECK/GIT)
                    (#:LAYOUT #:DREYECK/INSPECTOR/TOPICMAP/TALA))
  (:EXPORT #:MAINTAINED-MECH-WORKSPACE
           #:TRACE-EXTRACT-WALK-SOLO
           #:RETAINED-COMPOSITION
           #:MECH-COMPOSITION
           #:COMPOSITION-SOURCES
           #:COMPOSITION-RECORDS
           #:COMPOSITION-MANIFEST
           #:COMPOSITION-REVISIONS
           #:COMPOSITION-SOURCE
           #:SOURCE-BY-KEY
           #:RECORD-OF
           #:CATALOG-EVIDENCE
           #:RETAINED-EXECUTION
           #:EXECUTION-TRACE
           #:EXECUTION-RECORD
           #:EXECUTION-COMPOSITION
           #:EXECUTION-SOURCE-PAGE
           #:TRACE-STAGES
           #:ACCEPTANCE-EVIDENCE
           #:OPEN-DECISIONS
           #:READING-WORKSPACE
           #:SOURCE-PROJECTION
           #:EXECUTION-PROJECTION
           #:SWITCH-PROJECTION
           #:LAYOUT-COMPARISON
           #:READING-PAGE
           #:READ-EVIDENCE-JSON))

(IN-PACKAGE #:DREYECK/MECH-INTAKE)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "From Upstream Mech to an Owned Extension" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Which Graph Does WALK Produce?" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Evidence, Deviations and Acceptance" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Reading a Maintained Mech Composition" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(DEFUN EVIDENCE-PATH (NAME)
  (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME "dreyeck/mech-intake/reading"
                                        (CONCATENATE 'STRING
                                                     "dreyeck/mech-intake/evidence/"
                                                     NAME)))

(DEFUN READ-EVIDENCE-JSON (NAME)
  (WITH-OPEN-FILE (IN (EVIDENCE-PATH NAME) :EXTERNAL-FORMAT :UTF-8)
    (SHASHT:READ-JSON* :STREAM IN :SINGLE-VALUE T :OBJECT-FORMAT :HASH-TABLE
                       :HASH-TABLE-TEST 'EQUAL :ARRAY-FORMAT :VECTOR
                       :TRUE-VALUE T :FALSE-VALUE NIL :NULL-VALUE NIL)))

(DEFUN FILE-DIGEST (PATH)
  (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING (IRONCLAD:DIGEST-FILE :SHA256 PATH)))

(DEFUN TEXT-DIGEST (TEXT)
  (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
   (IRONCLAD:DIGEST-SEQUENCE :SHA256
                             (BABEL:STRING-TO-OCTETS TEXT :ENCODING :UTF-8))))

(DEFUN READING-PAGE (TITLE)
  (HYPERBOOK:FIND-PAGE "dreyeck/mech-intake/reading" TITLE :SIGNAL-ERROR? T))

(DEFCLASS MECH-COMPOSITION NIL
          ((MANIFEST :INITARG :MANIFEST :READER COMPOSITION-MANIFEST)
           (SOURCES :INITFORM NIL :ACCESSOR COMPOSITION-SOURCES)
           (RECORDS :INITARG :RECORDS :READER COMPOSITION-RECORDS)
           (REVISIONS :INITARG :REVISIONS :READER COMPOSITION-REVISIONS)))

(DEFCLASS COMPOSITION-SOURCE (N:MESSAGE-SOURCE)
          ((COMPOSITION :INITARG :COMPOSITION :READER SOURCE-COMPOSITION)
           (VERIFIED-COMMIT-FILE :INITARG :VERIFIED-COMMIT-FILE :READER
            SOURCE-COMMIT-FILE :INITFORM NIL)))

(DEFUN RECORD-OF (COMPOSITION NAME)
  (OR (CDR (ASSOC NAME (COMPOSITION-RECORDS COMPOSITION) :TEST #'EQUAL))
      (ERROR "No retained Mech record ~S" NAME)))

(DEFUN SOURCE-BY-KEY (COMPOSITION KEY)
  (OR
   (FIND KEY (COMPOSITION-SOURCES COMPOSITION) :TEST #'EQUAL :KEY
         (LAMBDA (S) (GETHASH "key" (N:SOURCE-METADATA S))))
   (ERROR "No retained source definition ~S" KEY)))

(DEFUN MAKE-EVIDENCE-REVISION (AUTHORITY OID ROLE)
  (GIT:MAKE-GIT-REVISION-REFERENCE :AUTHORITY AUTHORITY :OID OID :ROLE ROLE
                                   :WEB-URL
                                   (FORMAT NIL "~A/commit/~A" AUTHORITY OID)))

(DEFUN VERIFIED-SOURCE-COMMIT-FILE (COMPOSITION METADATA)
  "Link matching source bytes to the later source commit, separately from retained execution provenance."
  (WHEN (GETHASH "moduleDigest" METADATA)
    (LET* ((OBSERVATION
            (GETHASH "sourceCommitObservation"
                     (COMPOSITION-MANIFEST COMPOSITION)))
           (MATCH
            (FIND (GETHASH "file" METADATA) (GETHASH "files" OBSERVATION) :TEST
                  #'EQUAL :KEY (LAMBDA (ENTRY) (GETHASH "file" ENTRY))))
           (REVISION
            (CDR
             (ASSOC "wiki-source-commit" (COMPOSITION-REVISIONS COMPOSITION)
                    :TEST #'EQUAL))))
      (UNLESS
          (AND MATCH REVISION
               (EQUAL (GETHASH "path" MATCH) (GETHASH "path" METADATA))
               (EQUAL (GETHASH "sha256" MATCH)
                      (GETHASH "fileSha256" METADATA)))
        (ERROR "Retained source does not match verified source commit: ~A"
               (GETHASH "key" METADATA)))
      (GIT:ENSURE-GIT-EVIDENCE-FILE REVISION (GETHASH "path" MATCH)))))

(HYPERDOC:DEFEXAMPLE RETAINED-COMPOSITION
  "Read and verify retained source/decision bytes; no browser, Git subprocess or Mech execution occurs."
  (LET* ((MANIFEST (READ-EVIDENCE-JSON "manifest.json"))
         (ACCEPTANCE (READ-EVIDENCE-JSON "acceptance.json"))
         (IDENTITY (GETHASH "moduleIdentity" ACCEPTANCE))
         (COMPOSITION
          (MAKE-INSTANCE 'MECH-COMPOSITION :MANIFEST MANIFEST :RECORDS
                         (LOOP FOR NAME IN '("acceptance.json"
                                             "prior-acceptance.json"
                                             "twins-results.json"
                                             "twins-input.json"
                                             "behavioral-equivalence.json"
                                             "selected-contracts.json"
                                             "browser-results.json"
                                             "sources.json")
                               COLLECT (CONS NAME (READ-EVIDENCE-JSON NAME)))
                         :REVISIONS
                         (LIST
                          (CONS "upstream"
                                (MAKE-EVIDENCE-REVISION
                                 (GETHASH "authority"
                                          (GETHASH "upstream" ACCEPTANCE))
                                 (GETHASH "oid"
                                          (GETHASH "upstream" ACCEPTANCE))
                                 :TESTED-UPSTREAM-PIN))
                          (CONS "behavioralBaseline"
                                (MAKE-EVIDENCE-REVISION
                                 (GETHASH "authority"
                                          (GETHASH "behavioralBaseline"
                                                   ACCEPTANCE))
                                 (GETHASH "oid"
                                          (GETHASH "behavioralBaseline"
                                                   ACCEPTANCE))
                                 :BEHAVIORAL-BASELINE))
                          (CONS "wiki-base"
                                (MAKE-EVIDENCE-REVISION
                                 (GETHASH "authority" IDENTITY)
                                 (GETHASH "baseCommitOid" IDENTITY)
                                 :BASE-ONLY-NOT-EXTENSION-REVISION))
                          (CONS "wiki-source-commit"
                                (LET ((LATER
                                       (GETHASH "sourceCommitObservation"
                                                MANIFEST)))
                                  (MAKE-EVIDENCE-REVISION
                                   (GETHASH "authority" LATER)
                                   (GETHASH "oid" LATER)
                                   :SUBSEQUENT-SOURCE-COMMIT-NOT-EXECUTION-REVISION)))))))
    (LOOP FOR METADATA ACROSS (GETHASH "files" MANIFEST)
          DO (UNLESS
                 (EQUAL (FILE-DIGEST (EVIDENCE-PATH (GETHASH "file" METADATA)))
                        (GETHASH "sha256" METADATA))
               (ERROR "Retained Mech evidence hash mismatch: ~A"
                      (GETHASH "file" METADATA))))
    (UNLESS (NULL (GETHASH "extensionCommitOid" IDENTITY))
      (ERROR
       "This retained uncommitted observation must not acquire an invented extension revision."))
    (SETF (COMPOSITION-SOURCES COMPOSITION)
            (LOOP FOR METADATA ACROSS (GETHASH "sources" MANIFEST)
                  FOR TEXT = (UIOP/STREAM:READ-FILE-STRING
                              (EVIDENCE-PATH (GETHASH "file" METADATA)))
                  FOR EXCERPT = (SUBSEQ TEXT (GETHASH "start" METADATA)
                                        (GETHASH "end" METADATA))
                  FOR OID = (GETHASH "revision" METADATA)
                  FOR REVISION = (AND OID
                                      (FIND OID
                                            (MAPCAR #'CDR
                                                    (COMPOSITION-REVISIONS
                                                     COMPOSITION))
                                            :KEY #'GIT:GIT-COMMIT-HASH-OF :TEST
                                            #'EQUAL))
                  FOR FILE = (AND REVISION
                                  (GIT:ENSURE-GIT-EVIDENCE-FILE REVISION
                                                                (GETHASH "path"
                                                                         METADATA)))
                  DO (UNLESS
                         (EQUAL (TEXT-DIGEST EXCERPT)
                                (GETHASH "sha256" METADATA))
                       (ERROR
                        "Definition excerpt differs from recorded source coordinates: ~A"
                        (GETHASH "key" METADATA))) (WHEN
                                                       (AND OID (NOT REVISION))
                                                     (ERROR
                                                      "Unresolved recorded source revision: ~A"
                                                      OID))
                  COLLECT (LET ((SOURCE
                                 (MAKE-INSTANCE 'COMPOSITION-SOURCE
                                                :COMPOSITION COMPOSITION
                                                :METADATA METADATA :FILE
                                                (EVIDENCE-PATH
                                                 (GETHASH "file" METADATA))
                                                :TEXT EXCERPT :DEFINITION
                                                (GETHASH "definition" METADATA)
                                                :REVISION REVISION
                                                :REVISION-FILE FILE
                                                :VERIFIED-COMMIT-FILE
                                                (VERIFIED-SOURCE-COMMIT-FILE
                                                 COMPOSITION METADATA))))
                            (WHEN FILE
                              (GIT:ADD-GIT-EVIDENCE-LOCATION FILE SOURCE))
                            (WHEN (SOURCE-COMMIT-FILE SOURCE)
                              (GIT:ADD-GIT-EVIDENCE-LOCATION
                               (SOURCE-COMMIT-FILE SOURCE) SOURCE))
                            SOURCE)))
    COMPOSITION))

(HYPERDOC:DEFEXAMPLE CATALOG-EVIDENCE
  "The actual catalog arrays retained from browser-loaded upstream/composite bundles, with source authority."
  (LET* ((COMPOSITION (RETAINED-COMPOSITION))
         (TESTS
          (GETHASH "tests" (RECORD-OF COMPOSITION "browser-results.json"))))
    (LIST :EVIDENCE-STATUS :RETAINED-BROWSER-RECORD :COMPOSITION COMPOSITION
          :UPSTREAM
          (LOOP FOR TEST ACROSS TESTS
                WHEN (AND (EQUAL "upstream" (GETHASH "configuration" TEST))
                          (EQUAL "Bundle loaded with expected plugin entry"
                                 (GETHASH "name" TEST))) RETURN (GETHASH
                                                                 "evidence"
                                                                 TEST))
          :DISCOURSE
          (LOOP FOR TEST ACROSS TESTS
                WHEN (AND (EQUAL "composite" (GETHASH "configuration" TEST))
                          (EQUAL "Bundle loaded with expected plugin entry"
                                 (GETHASH "name" TEST))) RETURN (GETHASH
                                                                 "evidence"
                                                                 TEST))
          :CATALOG-SOURCE (SOURCE-BY-KEY COMPOSITION "upstream:blocks")
          :DISPATCHER-SOURCE (SOURCE-BY-KEY COMPOSITION "upstream:run")
          :EXTENSION-SOURCE
          (SOURCE-BY-KEY COMPOSITION "owned:installDiscourse"))))

(DEFMETHOD V:TEXT-REPRESENTATION ((COMPOSITION MECH-COMPOSITION))
  "Maintained Mech: pinned upstream, historical execution, verified later source commit")

(DEFMETHOD V:TEXT-REPRESENTATION ((SOURCE COMPOSITION-SOURCE))
  (FORMAT NIL "~A — ~A" (N:SOURCE-DEFINITION SOURCE)
          (GETHASH "authority" (N:SOURCE-METADATA SOURCE))))

(DEFUN RENDER-COMPOSITION-SOURCE (SOURCE)
  (V:HTML
    (:H3 (CL-WHO:ESC (N:SOURCE-DEFINITION SOURCE)))
    (:P
     (V:OBJECT-REF (N:SOURCE-METADATA SOURCE) :DISPLAY
                   "Authority, exact coordinates, digest and status"))
    (:P
     (V:OBJECT-REF (N:SOURCE-FILE SOURCE) :DISPLAY "Retained full source file"))
    (IF (N:SOURCE-REVISION SOURCE)
        (V:HTML
          (:P
           (V:OBJECT-REF (N:SOURCE-REVISION SOURCE) :SELECT "Evidence revision"
                         :DISPLAY "Repository-qualified full revision")
           " · "
           (V:OBJECT-REF (N:SOURCE-REVISION-FILE SOURCE) :SELECT
                         "Evidence locations" :DISPLAY
                         "File at revision and definitions")))
        (V:HTML
          (:P
           (CL-WHO:ESC
            (IF (GETHASH "moduleDigest" (N:SOURCE-METADATA SOURCE))
                "In the retained execution observation the module was uncommitted. Its base is not a commit containing it. A matching later source commit is linked separately below."
                "Author-reported temporary experiment: repository and revision unknown. Not established as current or pinned upstream code."))
           (V:OBJECT-REF
            (GETHASH "observation"
                     (COMPOSITION-MANIFEST (SOURCE-COMPOSITION SOURCE)))
            :DISPLAY "Provisional module identity and local observation"))))
    (WHEN (SOURCE-COMMIT-FILE SOURCE)
      (V:HTML
        (:P
         "These retained file bytes also match the later source commit; this is not a new execution identity. "
         (V:OBJECT-REF (GIT:GIT-FILE-COMMIT-OF (SOURCE-COMMIT-FILE SOURCE))
                       :SELECT "Evidence revision" :DISPLAY
                       "Verified Wiki source commit")
         " · "
         (V:OBJECT-REF (SOURCE-COMMIT-FILE SOURCE) :SELECT "Evidence locations"
                       :DISPLAY "Matching file and retained definitions"))))
    (:PRE (CL-WHO:ESC (N:SOURCE-TEXT SOURCE)))
    (:P
     (V:OBJECT-REF (SOURCE-COMPOSITION SOURCE) :SELECT "Composition" :DISPLAY
                   "Source and retained execution evidence")
     " · "
     (V:OBJECT-REF (READING-PAGE "From Upstream Mech to an Owned Extension")
                   :SELECT "Content" :DISPLAY "Return to the reading"))))

(V:DEFVIEW COMPOSITION-SOURCE-VIEW (SOURCE COMPOSITION-SOURCE)
           (V:HTML-VIEW :TITLE "Composition source" :PRIORITY 0
                        (RENDER-COMPOSITION-SOURCE SOURCE)))

(V:DEFVIEW N::MESSAGE-SOURCE-VIEW (SOURCE COMPOSITION-SOURCE)
           (V:HTML-VIEW :TITLE "Source evidence" :PRIORITY 1
                        (RENDER-COMPOSITION-SOURCE SOURCE)))

(V:DEFVIEW COMPOSITION-VIEW (COMPOSITION MECH-COMPOSITION)
           (V:HTML-VIEW :TITLE "Composition" :PRIORITY 0
                        (V:HTML
                          (:P
                           "This Inspector reads retained bytes. It does not run Mech, build a bundle, or verify a deployed runtime.")
                          (:P
                           (V:OBJECT-REF
                            (GETHASH "observation"
                                     (COMPOSITION-MANIFEST COMPOSITION))
                            :DISPLAY
                            "Historical pre-commit execution identity"))
                          (DOLIST
                              (REVISION (COMPOSITION-REVISIONS COMPOSITION))
                            (V:HTML
                              (:P (CL-WHO:ESC (CAR REVISION)) " "
                               (V:OBJECT-REF (CDR REVISION) :SELECT
                                             "Evidence revision"))))
                          (DOLIST (SOURCE (COMPOSITION-SOURCES COMPOSITION))
                            (V:HTML
                              (:P
                               (V:OBJECT-REF SOURCE :SELECT
                                             "Composition source" :DISPLAY
                                             (GETHASH "key"
                                                      (N:SOURCE-METADATA
                                                       SOURCE))))))
                          (:P
                           (V:OBJECT-REF (RETAINED-EXECUTION COMPOSITION)
                                         :SELECT "Execution trace" :DISPLAY
                                         "Follow actual retained EXTRACT → WALK → SOLO objects"))
                          (:P
                           (V:OBJECT-REF (READING-WORKSPACE COMPOSITION)
                                         :SELECT "Topicmap" :DISPLAY
                                         "Source Composition Workspace")
                           " · "
                           (V:OBJECT-REF
                            (READING-PAGE
                             "Reading a Maintained Mech Composition")
                            :SELECT "Content" :DISPLAY
                            "Return to the reading")))))
