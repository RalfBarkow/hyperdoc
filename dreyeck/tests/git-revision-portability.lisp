;;;; Portable Git Revision Inspection Acceptance

(DEFPACKAGE #:DREYECK/GIT/PORTABILITY/TESTS
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:G #:DREYECK/GIT)
                    (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:R #:DREYECK/NESTED-ACTIONS)
                    (#:TM #:DREYECK/TOPICMAP))
  (:EXPORT #:RUN-AVAILABLE-TESTS #:RUN-UNAVAILABLE-TESTS #:RUN-TESTS))

(IN-PACKAGE #:DREYECK/GIT/PORTABILITY/TESTS)

(DEFUN RENDER (OBJECT TITLE)
  (LET ((VIEW
         (OR
          (FIND TITLE (V:ALL-VIEWS OBJECT) :KEY #'V:VIEW-TITLE :TEST #'EQUAL)
          (ERROR "Missing ~A view of ~S" TITLE OBJECT))))
    (V:VIEW-HTML VIEW)
    (ASSERT
     (NOTANY (LAMBDA (REF) (TYPEP (CDR REF) 'CONDITION))
             (V:VIEW-REFERENCES VIEW)))
    VIEW))

(DEFUN REFS (VIEW) (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW)))

(DEFUN WRITE-TEXT (FILE TEXT)
  (WITH-OPEN-FILE (OUT FILE :DIRECTION :OUTPUT :IF-EXISTS :SUPERSEDE)
    (WRITE-STRING TEXT OUT)))

(DEFUN FIXTURE-REVISION (REPOSITORY OID)
  (G:MAKE-GIT-REVISION-REFERENCE :REPOSITORY REPOSITORY :AUTHORITY
                                 "https://example.test/portable-git" :OID OID
                                 :ROLE :FIXTURE :WEB-URL
                                 (FORMAT NIL
                                         "https://example.test/portable-git/commit/~A"
                                         OID)))

(DEFUN CHECK-UNAVAILABLE (OBJECT TITLES REASON)
  (DOLIST (TITLE TITLES)
    (LET* ((VIEW (RENDER OBJECT TITLE))
           (HTML (V:VIEW-HTML VIEW))
           (COMMIT
            (ETYPECASE OBJECT
              (G:GIT-COMMIT OBJECT)
              (G:GIT-FILE-AT-COMMIT (G:GIT-FILE-COMMIT-OF OBJECT)))))
      (ASSERT (SEARCH "Local Git inspection is unavailable" HTML))
      (ASSERT (SEARCH REASON HTML))
      (ASSERT (SEARCH (G:GIT-COMMIT-HASH-OF COMMIT) HTML))
      (ASSERT (SEARCH (G:GIT-REVISION-WEB-URL-OF COMMIT) HTML))
      (ASSERT (MEMBER COMMIT (REFS VIEW) :TEST #'EQ))
      (ASSERT (NOT (SEARCH "Couldn't change directory" HTML))))))

(DEFUN CHECK-NO-IMPLICIT-FETCH (REPOSITORY REVISION DIRECTORY)
       "An absent promised blob stays absent; the local-only remote is never contacted."
       (ASSERT (EQ :AVAILABLE (G:GIT-LOCAL-OBJECT-STATUS REPOSITORY)))
       (LET*
             ((FILE (G:ENSURE-GIT-EVIDENCE-FILE REVISION "fixture.js"))
              (OID
                   (G:TRIM-GIT-OUTPUT
                                      (G:GIT-RUN-STRING DIRECTORY "rev-parse"
                                                        (G:GIT-FILE-BLOB-SPEC
                                                                              FILE))))
              (LOOSE
                     (MERGE-PATHNAMES
                                      (FORMAT NIL ".git/objects/~A/~A"
                                              (SUBSEQ OID 0 2) (SUBSEQ OID 2))
                                      DIRECTORY)))
             (ASSERT (PROBE-FILE LOOSE))
             (G:GIT-RUN-STRING DIRECTORY "config" "remote.promisor.url"
                               (NAMESTRING
                                           (MERGE-PATHNAMES
                                                            "never-created-remote/"
                                                            DIRECTORY)))
             (G:GIT-RUN-STRING DIRECTORY "config" "remote.promisor.promisor"
                               "true")
             (G:GIT-RUN-STRING DIRECTORY "config" "extensions.partialClone"
                               "promisor")
             (DELETE-FILE LOOSE)
             (WITH-INPUT-FROM-STRING (INPUT (FORMAT NIL "~A~%" OID))
                                     (MULTIPLE-VALUE-BIND
                                                          (STDOUT STDERR
                                                                  EXIT-CODE)
                                                          (G::GIT-RUN-VALUES-WITH-INPUT
                                                                                        DIRECTORY
                                                                                        INPUT
                                                                                        "cat-file"
                                                                                        "--batch-check=%(objecttype)")
                                                          (ASSERT
                                                                  (ZEROP
                                                                         EXIT-CODE))
                                                          (ASSERT
                                                                  (ZEROP
                                                                         (LENGTH
                                                                                 STDERR)))
                                                          (ASSERT
                                                                  (EQUAL
                                                                         (FORMAT
                                                                                 NIL
                                                                                 "~A missing~%"
                                                                                 OID)
                                                                         STDOUT))))
             (ASSERT (EQ :BLOB-UNAVAILABLE (G:GIT-LOCAL-OBJECT-STATUS FILE)))
             (CHECK-UNAVAILABLE FILE (QUOTE ("Contents"))
                                "exact file blob is absent"))
       (FORMAT T
               "~&GIT-PORTABILITY-NO-FETCH-PASS: absent promised blob, successful missing response, empty stderr, no remote access.~%"))

(DEFUN RUN-AVAILABLE-TESTS NIL
       (LET ((DIRECTORY (DREYECK/GIT/TESTS::MAKE-FIXTURE-DIRECTORY)))
            (UNWIND-PROTECT
                            (PROGN
                                   (DREYECK/GIT/TESTS::INITIALIZE-GIT-FIXTURE
                                                                              DIRECTORY)
                                   (DOLIST
                                           (ENTRY
                                                  (QUOTE
                                                         (("fixture.js" . "const fixture = 7;")
                                                          ("fixture.html" . "<p>portable fixture</p>")
                                                          ("fixture.asd" . "(asdf:defsystem \"portable-fixture\" :depends-on (\"asdf\"))"))))
                                           (WRITE-TEXT
                                                       (MERGE-PATHNAMES
                                                                        (CAR
                                                                             ENTRY)
                                                                        DIRECTORY)
                                                       (CDR ENTRY)))
                                   (G:GIT-RUN-STRING DIRECTORY "add"
                                                     "fixture.js"
                                                     "fixture.html"
                                                     "fixture.asd")
                                   (G:GIT-RUN-STRING DIRECTORY "commit"
                                                     "--quiet" "-m"
                                                     "Portable fixture")
                                   (LET*
                                         ((REPOSITORY
                                                      (MAKE-INSTANCE
                                                                     (QUOTE
                                                                            G:GIT-REPOSITORY-CHECKOUT)
                                                                     :ROOT
                                                                     DIRECTORY
                                                                     :ROOT-SOURCE
                                                                     :PORTABILITY-FIXTURE))
                                          (HEAD
                                                (G:MAKE-GIT-COMMIT :REPOSITORY
                                                                   REPOSITORY))
                                          (REVISION
                                                    (FIXTURE-REVISION
                                                                      REPOSITORY
                                                                      (G:GIT-COMMIT-HASH-OF
                                                                                            HEAD)))
                                          (LISP-FILE
                                                     (G:ENSURE-GIT-EVIDENCE-FILE
                                                                                 REVISION
                                                                                 "example.lisp")))
                                         (ASSERT
                                                 (EQ :AVAILABLE
                                                     (G:GIT-LOCAL-OBJECT-STATUS
                                                                                REVISION)))
                                         (ASSERT
                                                 (EQ :COMMIT-PRESENT
                                                     (G:GIT-REVISION-LOCAL-STATUS
                                                                                  REVISION)))
                                         (DOLIST
                                                 (ENTRY
                                                        (QUOTE
                                                               (("Commit" . "Portable fixture")
                                                                ("Metadata" . "Portable fixture")
                                                                ("Stat" . "fixture.js")
                                                                ("Patch" . "+const fixture = 7;"))))
                                                 (ASSERT
                                                         (SEARCH (CDR ENTRY)
                                                                 (V:VIEW-HTML
                                                                              (RENDER
                                                                                      REVISION
                                                                                      (CAR
                                                                                           ENTRY))))))
                                         (LET
                                              ((CHANGES
                                                        (REFS
                                                              (RENDER REVISION
                                                                      "Changed files"))))
                                              (ASSERT
                                                      (= 3
                                                         (COUNT-IF
                                                                   (LAMBDA (O)
                                                                           (TYPEP
                                                                                  O
                                                                                  (QUOTE
                                                                                         G:GIT-FILE-AT-COMMIT)))
                                                                   CHANGES))))
                                         (DOLIST
                                                 (ENTRY
                                                        (QUOTE
                                                               (("example.lisp" . "fixture-value")
                                                                ("fixture.js" . "const fixture = 7;")
                                                                ("fixture.html" . "portable fixture")
                                                                ("fixture.asd" . "portable-fixture"))))
                                                 (LET*
                                                       ((FILE
                                                              (G:ENSURE-GIT-EVIDENCE-FILE
                                                                                          REVISION
                                                                                          (CAR
                                                                                               ENTRY)))
                                                        (HTML
                                                              (V:VIEW-HTML
                                                                           (RENDER
                                                                                   FILE
                                                                                   "Contents"))))
                                                       (ASSERT
                                                               (EQ :AVAILABLE
                                                                   (G:GIT-LOCAL-OBJECT-STATUS
                                                                                              FILE)))
                                                       (ASSERT
                                                               (SEARCH
                                                                       (CDR
                                                                            ENTRY)
                                                                       (G:GIT-FILE-CONTENTS
                                                                                            FILE)))
                                                       (ASSERT
                                                               (SEARCH
                                                                       (CDR
                                                                            ENTRY)
                                                                       HTML))
                                                       (ASSERT
                                                               (NOT
                                                                    (SEARCH
                                                                            "Local Git inspection is unavailable"
                                                                            HTML)))))
                                         (ASSERT
                                                 (SEARCH
                                                         "Historical declarations"
                                                         (V:VIEW-HTML
                                                                      (RENDER
                                                                              (G:ENSURE-GIT-EVIDENCE-FILE
                                                                                                          REVISION
                                                                                                          "fixture.asd")
                                                                              "ASDF references"))))
                                         (ASSERT
                                                 (TM:TOPICMAP-PROJECTION-OF
                                                                            REPOSITORY))
                                         (ASSERT
                                                 (TM:TOPICMAP-PROJECTION-OF
                                                                            (G:ENSURE-GIT-EVIDENCE-FILE
                                                                                                        REVISION
                                                                                                        "fixture.asd")))
                                         (LET
                                              ((MISSING
                                                        (FIXTURE-REVISION
                                                                          REPOSITORY
                                                                          (MAKE-STRING
                                                                                       40
                                                                                       :INITIAL-ELEMENT
                                                                                       (CHAR
                                                                                             "f"
                                                                                             0)))))
                                              (ASSERT
                                                      (EQ :COMMIT-UNAVAILABLE
                                                          (G:GIT-LOCAL-OBJECT-STATUS
                                                                                     MISSING)))
                                              (CHECK-UNAVAILABLE MISSING
                                                                 (QUOTE
                                                                        ("Commit"
                                                                         "Metadata"
                                                                         "Stat"
                                                                         "Changed files"
                                                                         "Patch"))
                                                                 "exact commit object is absent"))
                                         (LET
                                              ((MISSING-FILE
                                                             (G:ENSURE-GIT-EVIDENCE-FILE
                                                                                         REVISION
                                                                                         "missing.asd")))
                                              (ASSERT
                                                      (EQ :BLOB-UNAVAILABLE
                                                          (G:GIT-LOCAL-OBJECT-STATUS
                                                                                     MISSING-FILE)))
                                              (CHECK-UNAVAILABLE MISSING-FILE
                                                                 (QUOTE
                                                                        ("Contents"
                                                                         "ASDF references"))
                                                                 "exact file blob is absent")
                                              (ASSERT
                                                      (NULL
                                                            (TM:TOPICMAP-PROJECTION-OF
                                                                                       MISSING-FILE))))
                                         (ASSERT
                                                 (EQUAL
                                                        (G:GIT-REVISION-IDENTITY
                                                                                 REVISION)
                                                        (G:GIT-REVISION-IDENTITY
                                                                                 (FIXTURE-REVISION
                                                                                                   NIL
                                                                                                   (G:GIT-COMMIT-HASH-OF
                                                                                                                         REVISION)))))
                                         (LET*
                                               ((CONFIG
                                                        (MERGE-PATHNAMES
                                                                         ".git/config"
                                                                         DIRECTORY))
                                                (BEFORE
                                                        (UIOP/STREAM:READ-FILE-STRING
                                                                                      CONFIG)))
                                               (UNWIND-PROTECT
                                                               (PROGN
                                                                      (WRITE-TEXT
                                                                                  CONFIG
                                                                                  "[broken")
                                                                      (ASSERT
                                                                              (HANDLER-CASE
                                                                                            (PROGN
                                                                                                   (G:GIT-LOCAL-OBJECT-STATUS
                                                                                                                              REVISION)
                                                                                                   NIL)
                                                                                            (G:GIT-COMMAND-FAILED
                                                                                                                  (CONDITION)
                                                                                                                  (NOT
                                                                                                                       (ZEROP
                                                                                                                              (G:GIT-COMMAND-FAILED-EXIT-CODE-OF
                                                                                                                                                                 CONDITION))))))
                                                                      (LET
                                                                           ((HTML
                                                                                  (V:VIEW-HTML
                                                                                               (RENDER
                                                                                                       REVISION
                                                                                                       "Patch"))))
                                                                           (ASSERT
                                                                                   (SEARCH
                                                                                           "Git inspection failed"
                                                                                           HTML))
                                                                           (ASSERT
                                                                                   (NOT
                                                                                        (SEARCH
                                                                                                "Local Git inspection is unavailable"
                                                                                                HTML)))))
                                                               (WRITE-TEXT
                                                                           CONFIG
                                                                           BEFORE)))
                                         (PROGN
                                                (CHECK-NO-IMPLICIT-FETCH
                                                                         REPOSITORY
                                                                         REVISION
                                                                         DIRECTORY)
                                                (LET
                                                     ((PATCH
                                                             (DREYECK/INSPECTOR/GIT::👀PATCH
                                                                                            REVISION))
                                                      (CONTENTS
                                                                (DREYECK/INSPECTOR/GIT::👀CONTENTS
                                                                                                  LISP-FILE)))
                                                     (UIOP/FILESYSTEM:DELETE-DIRECTORY-TREE
                                                                                            DIRECTORY
                                                                                            :VALIDATE
                                                                                            T)
                                                     (ASSERT
                                                             (SEARCH
                                                                     "no usable checkout"
                                                                     (V:VIEW-HTML
                                                                                  PATCH)))
                                                     (ASSERT
                                                             (SEARCH
                                                                     "no usable checkout"
                                                                     (V:VIEW-HTML
                                                                                  CONTENTS)))))))
                            (UIOP/FILESYSTEM:DELETE-DIRECTORY-TREE DIRECTORY
                                                                   :VALIDATE T
                                                                   :IF-DOES-NOT-EXIST
                                                                   :IGNORE)))
       (LET ((REVISION (R:MECH-EVIDENCE-REVISION)))
            (ASSERT
                    (EQ :COMMIT-PRESENT
                        (G:GIT-REVISION-LOCAL-STATUS REVISION)))
            (DOLIST
                    (TITLE
                           (QUOTE
                                  ("Evidence revision"
                                   "Commit"
                                   "Metadata"
                                   "Stat"
                                   "Changed files"
                                   "Patch")))
                    (ASSERT
                            (NOT
                                 (SEARCH "Local Git inspection is unavailable"
                                         (V:VIEW-HTML
                                                      (RENDER REVISION
                                                              TITLE)))))))
       (FORMAT T
               "~&GIT-PORTABILITY-AVAILABLE-PASS: exact commit/blob views, ASDF/Topicmap, missing objects, unrelated Git failures, and lazy disappearance.~%")
       T)

(DEFUN CALL-WITH-REBOUND-FUNCTIONS (BINDINGS FUNCTION)
  "Test-only simulation; restore all runtime functions even after a failure."
  (LET ((BEFORE
         (MAPCAR
          (LAMBDA (BINDING)
            (CONS (CAR BINDING) (SYMBOL-FUNCTION (CAR BINDING))))
          BINDINGS)))
    (UNWIND-PROTECT
        (PROGN
         (DOLIST (BINDING BINDINGS)
           (SETF (SYMBOL-FUNCTION (CAR BINDING)) (CDR BINDING)))
         (FUNCALL FUNCTION))
      (DOLIST (BINDING BEFORE)
        (SETF (SYMBOL-FUNCTION (CAR BINDING)) (CDR BINDING))))))

(DEFUN RUN-UNAVAILABLE-TESTS NIL
       (LET*
             ((METADATA
                        (R::READ-MESSAGE-JSON
                                              "dreyeck/nested-actions/sources/revision-provenance.json"))
              (ROOTS
                     (MAP (QUOTE LIST)
                          (LAMBDA (M)
                                  (NAMESTRING
                                              (UIOP/PATHNAME:ENSURE-DIRECTORY-PATHNAME
                                                                                       (PATHNAME
                                                                                                 (GETHASH
                                                                                                          "root"
                                                                                                          M)))))
                          METADATA))
              (DIRECTORY-EXISTS
                                (SYMBOL-FUNCTION
                                                 (QUOTE
                                                        UIOP/FILESYSTEM:DIRECTORY-EXISTS-P)))
              (GIT-CALLS 0))
             (CALL-WITH-REBOUND-FUNCTIONS
                                          (LIST
                                                (CONS
                                                      (QUOTE
                                                             UIOP/FILESYSTEM:DIRECTORY-EXISTS-P)
                                                      (LAMBDA (PATH)
                                                              (UNLESS
                                                                      (MEMBER
                                                                              (NAMESTRING
                                                                                          (UIOP/PATHNAME:ENSURE-DIRECTORY-PATHNAME
                                                                                                                                   PATH))
                                                                              ROOTS
                                                                              :TEST
                                                                              (FUNCTION
                                                                                        EQUAL))
                                                                      (FUNCALL
                                                                               DIRECTORY-EXISTS
                                                                               PATH))))
                                                (CONS
                                                      (QUOTE
                                                             G::GIT-RUN-VALUES-WITH-INPUT)
                                                      (LAMBDA (&REST ARGUMENTS)
                                                              (INCF GIT-CALLS)
                                                              (ERROR
                                                                     "Unavailable evidence path invoked Git: ~S"
                                                                     ARGUMENTS))))
                                          (LAMBDA NIL
                                                  (LET*
                                                        ((REVISION
                                                                   (R:MECH-EVIDENCE-REVISION))
                                                         (VIEW
                                                               (RENDER REVISION
                                                                       "Evidence revision"))
                                                         (HTML
                                                               (V:VIEW-HTML
                                                                            VIEW))
                                                         (FILES
                                                                (REMOVE-IF-NOT
                                                                               (LAMBDA
                                                                                       (O)
                                                                                       (TYPEP
                                                                                              O
                                                                                              (QUOTE
                                                                                                     G:GIT-EVIDENCE-FILE)))
                                                                               (REFS
                                                                                     VIEW))))
                                                        (ASSERT
                                                                (NULL
                                                                      (G:GIT-COMMIT-REPOSITORY-OF
                                                                                                  REVISION)))
                                                        (ASSERT
                                                                (EQ
                                                                    :CHECKOUT-UNAVAILABLE
                                                                    (G:GIT-REVISION-LOCAL-STATUS
                                                                                                 REVISION)))
                                                        (ASSERT
                                                                (EQUAL
                                                                       (G:GIT-REVISION-IDENTITY
                                                                                                REVISION)
                                                                       (QUOTE
                                                                              ("https://github.com/WardCunningham/wiki-plugin-mech"
                                                                               "a028b4bba04e539dcaa090423d38a00a0050489d"))))
                                                        (ASSERT
                                                                (EQUAL
                                                                       "/Users/rgb/workspace/wiki-plugin-mech-upstream"
                                                                       (G:GIT-REVISION-RECORDED-CHECKOUT-PATH-OF
                                                                                                                 REVISION)))
                                                        (ASSERT
                                                                (SEARCH
                                                                        "provenance only"
                                                                        HTML))
                                                        (ASSERT
                                                                (SEARCH
                                                                        (G:GIT-REVISION-WEB-URL-OF
                                                                                                   REVISION)
                                                                        HTML))
                                                        (ASSERT
                                                                (= 2
                                                                   (LENGTH
                                                                           FILES)))
                                                        (CHECK-UNAVAILABLE
                                                                           REVISION
                                                                           (QUOTE
                                                                                  ("Commit"
                                                                                   "Metadata"
                                                                                   "Stat"
                                                                                   "Changed files"
                                                                                   "Patch"))
                                                                           "no usable checkout")
                                                        (LET*
                                                              ((FILE
                                                                     (FIND
                                                                           "src/client/blocks.js"
                                                                           FILES
                                                                           :KEY
                                                                           (FUNCTION
                                                                                     G:GIT-FILE-PATH-OF)
                                                                           :TEST
                                                                           (FUNCTION
                                                                                     EQUAL)))
                                                               (LOCATIONS
                                                                          (REFS
                                                                                (RENDER
                                                                                        FILE
                                                                                        "Evidence locations"))))
                                                              (ASSERT FILE)
                                                              (ASSERT
                                                                      (MEMBER
                                                                              REVISION
                                                                              (REFS
                                                                                    (RENDER
                                                                                            FILE
                                                                                            "Overview"))
                                                                              :TEST
                                                                              (FUNCTION
                                                                                        EQ)))
                                                              (DOLIST
                                                                      (ROLE
                                                                            (QUOTE
                                                                                   ("listen"
                                                                                    "report")))
                                                                      (LET*
                                                                            ((SOURCE
                                                                                     (FIND-IF
                                                                                              (LAMBDA
                                                                                                      (O)
                                                                                                      (AND
                                                                                                           (TYPEP
                                                                                                                  O
                                                                                                                  (QUOTE
                                                                                                                         R:MESSAGE-SOURCE))
                                                                                                           (EQUAL
                                                                                                                  ROLE
                                                                                                                  (GETHASH
                                                                                                                           "role"
                                                                                                                           (R:SOURCE-METADATA
                                                                                                                                              O)))))
                                                                                              LOCATIONS))
                                                                             (SOURCE-VIEW
                                                                                          (RENDER
                                                                                                  SOURCE
                                                                                                  "Source evidence")))
                                                                            (ASSERT
                                                                                    SOURCE)
                                                                            (ASSERT
                                                                                    (R:SOURCE-DEFINITION
                                                                                                         SOURCE))
                                                                            (ASSERT
                                                                                    (EQUAL
                                                                                           (R:SOURCE-TEXT
                                                                                                          SOURCE)
                                                                                           (UIOP/STREAM:READ-FILE-STRING
                                                                                                                         (R:SOURCE-FILE
                                                                                                                                        SOURCE))))
                                                                            (ASSERT
                                                                                    (MEMBER
                                                                                            REVISION
                                                                                            (REFS
                                                                                                  SOURCE-VIEW)
                                                                                            :TEST
                                                                                            (FUNCTION
                                                                                                      EQ)))
                                                                            (ASSERT
                                                                                    (MEMBER
                                                                                            FILE
                                                                                            (REFS
                                                                                                  SOURCE-VIEW)
                                                                                            :TEST
                                                                                            (FUNCTION
                                                                                                      EQ)))))
                                                              (CHECK-UNAVAILABLE
                                                                                 FILE
                                                                                 (QUOTE
                                                                                        ("Contents"))
                                                                                 "no usable checkout"))
                                                        (LET*
                                                              ((LEGACY-ROOT
                                                                            (UIOP/PATHNAME:ENSURE-DIRECTORY-PATHNAME
                                                                                                                     (PATHNAME
                                                                                                                               (G:GIT-REVISION-RECORDED-CHECKOUT-PATH-OF
                                                                                                                                                                         REVISION))))
                                                               (LEGACY-REPOSITORY
                                                                                  (MAKE-INSTANCE
                                                                                                 (QUOTE
                                                                                                        G:GIT-REPOSITORY-CHECKOUT)
                                                                                                 :ROOT
                                                                                                 LEGACY-ROOT
                                                                                                 :ROOT-SOURCE
                                                                                                 :LEGACY-RUNTIME))
                                                               (LEGACY
                                                                       (G:MAKE-GIT-REVISION-REFERENCE
                                                                                                      :REPOSITORY
                                                                                                      LEGACY-REPOSITORY
                                                                                                      :AUTHORITY
                                                                                                      (G:GIT-REVISION-AUTHORITY-OF
                                                                                                                                   REVISION)
                                                                                                      :OID
                                                                                                      (G:GIT-COMMIT-HASH-OF
                                                                                                                            REVISION)
                                                                                                      :ROLE
                                                                                                      :LEGACY
                                                                                                      :WEB-URL
                                                                                                      (G:GIT-REVISION-WEB-URL-OF
                                                                                                                                 REVISION))))
                                                              (CHECK-UNAVAILABLE
                                                                                 LEGACY
                                                                                 (QUOTE
                                                                                        ("Commit"
                                                                                         "Metadata"
                                                                                         "Stat"
                                                                                         "Changed files"
                                                                                         "Patch"))
                                                                                 "no usable checkout")
                                                              (PROGN
                                                                     (ASSERT
                                                                             (NULL
                                                                                   (TM:TOPICMAP-PROJECTION-OF
                                                                                                              LEGACY-REPOSITORY)))
                                                                     (ASSERT
                                                                             (SEARCH
                                                                                     "no usable checkout"
                                                                                     (V:VIEW-HTML
                                                                                                  (RENDER
                                                                                                          LEGACY-REPOSITORY
                                                                                                          "Local checkout")))))
                                                              (DOLIST
                                                                      (PATH
                                                                            (QUOTE
                                                                                   ("absent.lisp"
                                                                                    "absent.html"
                                                                                    "absent.js"
                                                                                    "absent.asd")))
                                                                      (LET
                                                                           ((FILE
                                                                                  (G:ENSURE-GIT-EVIDENCE-FILE
                                                                                                              LEGACY
                                                                                                              PATH)))
                                                                           (CHECK-UNAVAILABLE
                                                                                              FILE
                                                                                              (QUOTE
                                                                                                     ("Contents"))
                                                                                              "no usable checkout")
                                                                           (WHEN
                                                                                 (STRING=
                                                                                          PATH
                                                                                          "absent.asd")
                                                                                 (CHECK-UNAVAILABLE
                                                                                                    FILE
                                                                                                    (QUOTE
                                                                                                           ("ASDF references"))
                                                                                                    "no usable checkout")
                                                                                 (ASSERT
                                                                                         (NULL
                                                                                               (G:GIT-FILE-ASDF-REFERENCE-PROJECTION
                                                                                                                                     FILE)))
                                                                                 (ASSERT
                                                                                         (NULL
                                                                                               (TM:TOPICMAP-PROJECTION-OF
                                                                                                                          FILE)))))))
                                                        (LET*
                                                              ((PAGE
                                                                     (HYPERBOOK:FIND-PAGE
                                                                                          "dreyeck/nested-actions/reading"
                                                                                          "From Message to Nested Input"
                                                                                          :SIGNAL-ERROR?
                                                                                          T))
                                                               (CONTENT
                                                                        (RENDER
                                                                                PAGE
                                                                                "Content"))
                                                               (LINKED
                                                                       (FIND-IF
                                                                                (LAMBDA
                                                                                        (O)
                                                                                        (TYPEP
                                                                                               O
                                                                                               (QUOTE
                                                                                                      G:GIT-REVISION-REFERENCE)))
                                                                                (REFS
                                                                                      CONTENT))))
                                                              (ASSERT LINKED)
                                                              (ASSERT
                                                                      (EQUAL
                                                                             (G:GIT-REVISION-IDENTITY
                                                                                                      REVISION)
                                                                             (G:GIT-REVISION-IDENTITY
                                                                                                      LINKED)))
                                                              (RENDER LINKED
                                                                      "Evidence revision")))))
             (ASSERT (ZEROP GIT-CALLS))
             (FORMAT T
                     "~&GIT-PORTABILITY-UNAVAILABLE-PASS: recorded macOS checkout absent, native LISTEN/REPORT excerpts and external commit navigable; all dependent views graceful; Git calls=~D.~%"
                     GIT-CALLS))
       T)

(DEFUN RUN-TESTS () (RUN-AVAILABLE-TESTS) (RUN-UNAVAILABLE-TESTS))
