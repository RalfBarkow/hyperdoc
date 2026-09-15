
(COMMON-LISP:DEFPACKAGE :DREYECK/HYPERDOC/CURATION/TESTS
  (:USE :CL)
  (:EXPORT :RUN-TESTS))

(COMMON-LISP:IN-PACKAGE :DREYECK/HYPERDOC/CURATION/TESTS)

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::NEVER-EVALUATE ()
  (COMMON-LISP:ERROR "Curation executed an inventoried definition."))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::QUOTED-REFERENCE ()
  '(DREYECK/HYPERDOC/CURATION/TESTS::NEVER-EVALUATE))

(COMMON-LISP:DEFPARAMETER DREYECK/HYPERDOC/CURATION/TESTS::*NOT-A-PAGE-TABLE*
  '(("not a page/file contract")))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::NOT-A-NAVIGATION-CONTRACT
                   ()
  "Observing an Upstream Commit")

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::REJECTED-P
                   (DREYECK/HYPERDOC/CURATION/TESTS::THUNK)
  (COMMON-LISP:HANDLER-CASE
   (COMMON-LISP:PROGN
    (COMMON-LISP:FUNCALL DREYECK/HYPERDOC/CURATION/TESTS::THUNK)
    COMMON-LISP:NIL)
   (COMMON-LISP:ERROR COMMON-LISP:NIL COMMON-LISP:T)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::INVENTORY ()
  (COMMON-LISP:MAPCAR
   (COMMON-LISP:LAMBDA (DREYECK/HYPERDOC/CURATION/TESTS::PATH)
     (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME "dreyeck"
                                           DREYECK/HYPERDOC/CURATION/TESTS::PATH))
   '("dreyeck/src/upstream-intake.lisp"
     "dreyeck/src/upstream-intake-hyperdoc.lisp"
     "dreyeck/tests/upstream-intake-smoke.lisp")))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::CONTRACTS ()
  (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION/TESTS::PATH
                     (COMMON-LISP:THIRD
                      (DREYECK/HYPERDOC/CURATION/TESTS::INVENTORY))))
    (COMMON-LISP:LOOP DREYECK/HYPERDOC/CURATION/TESTS::FOR (DREYECK/HYPERDOC/CURATION/TESTS::ROLE
                                                            DREYECK/HYPERDOC/CURATION/TESTS::NAME) DREYECK/HYPERDOC/CURATION/TESTS::IN '((:EXPECTED-PAGE-SET
                                                                                                                                          "+UPSTREAM-INTAKE-PAGE-SPECS+")
                                                                                                                                         (:NAVIGATION
                                                                                                                                          "CHECK-PAGE-NAVIGATION")
                                                                                                                                         (:PAGE-EXECUTABLE
                                                                                                                                          "RUN-HYPERDOC-PAGE-TESTS")
                                                                                                                                         (:SYMBOL-EXISTENCE
                                                                                                                                          "RUN-UPSTREAM-INTAKE-TESTS"))
                      DREYECK/HYPERDOC/CURATION/TESTS::COLLECT (COMMON-LISP:LIST
                                                                :ROLE
                                                                DREYECK/HYPERDOC/CURATION/TESTS::ROLE
                                                                :PATHNAME
                                                                DREYECK/HYPERDOC/CURATION/TESTS::PATH
                                                                :NAME
                                                                DREYECK/HYPERDOC/CURATION/TESTS::NAME))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::CHECK-SOURCE-WARRANTS
                   (DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)
  (COMMON-LISP:LABELS ((DREYECK/HYPERDOC/CURATION/TESTS::VERIFY
                           (DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                         (COMMON-LISP:WHEN
                             (COMMON-LISP:CONSP
                              DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                           (COMMON-LISP:WHEN
                               (COMMON-LISP:AND
                                (COMMON-LISP:EQ
                                 (COMMON-LISP:FIRST
                                  DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                 :KIND)
                                (COMMON-LISP:EQ
                                 (COMMON-LISP:SECOND
                                  DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                 :LISP-CST))
                             (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION/TESTS::SPAN
                                                (COMMON-LISP:GETF
                                                 DREYECK/HYPERDOC/CURATION/TESTS::VALUE
                                                 :REGION)))
                               (COMMON-LISP:ASSERT
                                (COMMON-LISP:EQUAL
                                 (COMMON-LISP:GETF
                                  DREYECK/HYPERDOC/CURATION/TESTS::VALUE
                                  :SOURCE)
                                 (COMMON-LISP:SUBSEQ
                                  (UIOP/STREAM:READ-FILE-STRING
                                   (COMMON-LISP:GETF
                                    DREYECK/HYPERDOC/CURATION/TESTS::VALUE
                                    :PATHNAME))
                                  (COMMON-LISP:CAR
                                   DREYECK/HYPERDOC/CURATION/TESTS::SPAN)
                                  (COMMON-LISP:CDR
                                   DREYECK/HYPERDOC/CURATION/TESTS::SPAN))))))
                           (DREYECK/HYPERDOC/CURATION/TESTS::VERIFY
                            (COMMON-LISP:CAR
                             DREYECK/HYPERDOC/CURATION/TESTS::VALUE))
                           (DREYECK/HYPERDOC/CURATION/TESTS::VERIFY
                            (COMMON-LISP:CDR
                             DREYECK/HYPERDOC/CURATION/TESTS::VALUE)))))
    (COMMON-LISP:DOLIST
        (DREYECK/HYPERDOC/CURATION/TESTS::EDGE
         (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
          (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
           DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)))
      (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                         (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                          DREYECK/HYPERDOC/CURATION/TESTS::EDGE)))
        (COMMON-LISP:ASSERT
         (COMMON-LISP:MEMBER
          (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                            :EPISTEMIC-STATUS)
          '(:SOURCE-OBSERVED :LIVE-OBSERVED)))
        (COMMON-LISP:ASSERT
         (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                           :WARRANT))
        (DREYECK/HYPERDOC/CURATION/TESTS::VERIFY
         (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                           :WARRANT))))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::RUN-WITNESS
                   (DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                    DREYECK/HYPERDOC/CURATION/TESTS::EXAMPLE)
  (COMMON-LISP:LET* ((DREYECK/HYPERDOC/CURATION/TESTS::PAGE
                      (HYPERBOOK:FIND-PAGE
                       DREYECK/UPSTREAM-INTAKE:*UPSTREAM-INTAKE-HYPERDOC*
                       DREYECK/HYPERDOC/CURATION/TESTS::TITLE :SIGNAL-ERROR?
                       COMMON-LISP:T))
                     (DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE
                      (DREYECK/HYPERDOC/CURATION:MAKE-REFERENCE-WORKSPACE
                       DREYECK/HYPERDOC/CURATION/TESTS::PAGE :SOURCE-FILES
                       (DREYECK/HYPERDOC/CURATION/TESTS::INVENTORY) :CONTRACTS
                       (DREYECK/HYPERDOC/CURATION/TESTS::CONTRACTS)))
                     (DREYECK/HYPERDOC/CURATION/TESTS::PROJECTION
                      (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
                       DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE))
                     (DREYECK/HYPERDOC/CURATION/TESTS::POINT
                      (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                       DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE))
                     (DREYECK/HYPERDOC/CURATION/TESTS::IMPACT
                      (DREYECK/TOPICMAP/CURATION:MAKE-IMPACT-WORKSPACE
                       DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE :POLICY
                       #'DREYECK/HYPERDOC/CURATION:HYPERDOC-REMOVAL-IMPACT))
                     (DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY
                      (DREYECK/TOPICMAP/CURATION:IMPACT-SUMMARY
                       DREYECK/HYPERDOC/CURATION/TESTS::IMPACT))
                     (DREYECK/HYPERDOC/CURATION/TESTS::EXPECTED
                      (COMMON-LISP:LIST
                       (COMMON-LISP:LIST :REMOVE
                                         DREYECK/HYPERDOC/CURATION/TESTS::TITLE)
                       (COMMON-LISP:LIST :REMOVE-WITH-PAGE
                                         (COMMON-LISP:CONCATENATE
                                          'COMMON-LISP:STRING
                                          DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                                          ".html"))
                       '(:MUST-EDIT
                         "Upstream Intake as a Read-Only Observation")
                       '(:MUST-EDIT "+UPSTREAM-INTAKE-PAGE-SPECS+")
                       '(:MUST-EDIT-OR-DELETE "CHECK-PAGE-NAVIGATION")
                       '(:MUST-EDIT-OR-DELETE "RUN-HYPERDOC-PAGE-TESTS")
                       (COMMON-LISP:LIST :KEEP
                                         DREYECK/HYPERDOC/CURATION/TESTS::EXAMPLE))))
    (COMMON-LISP:DOLIST
        (DREYECK/HYPERDOC/CURATION/TESTS::ROW
         DREYECK/HYPERDOC/CURATION/TESTS::EXPECTED)
      (COMMON-LISP:ASSERT
       (COMMON-LISP:MEMBER DREYECK/HYPERDOC/CURATION/TESTS::ROW
                           DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY :TEST
                           #'COMMON-LISP:EQUAL)
       COMMON-LISP:NIL "Missing impact ~S in ~S"
       DREYECK/HYPERDOC/CURATION/TESTS::ROW
       DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY))
    (DREYECK/HYPERDOC/CURATION/TESTS::CHECK-SOURCE-WARRANTS
     DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)
    (COMMON-LISP:LET* ((DREYECK/HYPERDOC/CURATION/TESTS::RESULT
                        (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
                         DREYECK/HYPERDOC/CURATION/TESTS::IMPACT))
                       (DREYECK/HYPERDOC/CURATION/TESTS::CUT
                        (COMMON-LISP:GETF
                         (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-SOURCE-OF
                          DREYECK/HYPERDOC/CURATION/TESTS::RESULT)
                         :CUT-TOPIC-IDS))
                       (DREYECK/HYPERDOC/CURATION/TESTS::REFERENCES
                        (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                         DREYECK/HYPERDOC/CURATION/TESTS::PROJECTION)))
      (COMMON-LISP:DOLIST
          (DREYECK/HYPERDOC/CURATION/TESTS::EDGE
           (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
            DREYECK/HYPERDOC/CURATION/TESTS::RESULT))
        (COMMON-LISP:LET* ((DREYECK/HYPERDOC/CURATION/TESTS::PROPS
                            (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                             DREYECK/HYPERDOC/CURATION/TESTS::EDGE))
                           (DREYECK/HYPERDOC/CURATION/TESTS::W
                            (COMMON-LISP:GETF
                             DREYECK/HYPERDOC/CURATION/TESTS::PROPS :WARRANT)))
          (COMMON-LISP:ASSERT
           (COMMON-LISP:EQ :MECHANICALLY-DERIVED
                           (COMMON-LISP:GETF
                            DREYECK/HYPERDOC/CURATION/TESTS::PROPS
                            :EPISTEMIC-STATUS)))
          (COMMON-LISP:DOLIST
              (DREYECK/HYPERDOC/CURATION/TESTS::ID
               (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION/TESTS::W
                                 :REFERENCE-EDGES))
            (COMMON-LISP:ASSERT
             (COMMON-LISP:FIND DREYECK/HYPERDOC/CURATION/TESTS::ID
                               DREYECK/HYPERDOC/CURATION/TESTS::REFERENCES :KEY
                               #'DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF
                               :TEST #'COMMON-LISP:EQUAL)))
          (COMMON-LISP:WHEN
              (COMMON-LISP:EQ :KEEP
                              (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                               DREYECK/HYPERDOC/CURATION/TESTS::EDGE))
            (COMMON-LISP:ASSERT
             (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION/TESTS::W
                               :SURVIVING-RETENTION-EDGES))
            (COMMON-LISP:ASSERT
             (COMMON-LISP:SOME
              (COMMON-LISP:LAMBDA (DREYECK/HYPERDOC/CURATION/TESTS::ID)
                (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR
                                   (COMMON-LISP:FIND
                                    DREYECK/HYPERDOC/CURATION/TESTS::ID
                                    DREYECK/HYPERDOC/CURATION/TESTS::REFERENCES
                                    :KEY
                                    #'DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF
                                    :TEST #'COMMON-LISP:EQUAL)))
                  (COMMON-LISP:AND DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR
                                   (COMMON-LISP:EQ :EXPOSES-EXECUTABLE-LINK
                                                   (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                                                    DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR))
                                   (COMMON-LISP:NOT
                                    (COMMON-LISP:MEMBER
                                     (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                      DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR)
                                     DREYECK/HYPERDOC/CURATION/TESTS::CUT :TEST
                                     #'COMMON-LISP:EQUAL))
                                   (COMMON-LISP:EQUAL
                                    "Upstream Intake as a Read-Only Observation"
                                    (DREYECK/TOPICMAP:TOPICMAP-TOPIC-LABEL-OF
                                     (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-TOPIC-BY-ID
                                      DREYECK/HYPERDOC/CURATION/TESTS::PROJECTION
                                      (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                       DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR)))))))
              (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION/TESTS::W
                                :SURVIVING-RETENTION-EDGES)))))))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQUAL DREYECK/HYPERDOC/CURATION/TESTS::POINT
                        (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                         DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQ DREYECK/HYPERDOC/CURATION/TESTS::PROJECTION
                     (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
                      DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)))
    (COMMON-LISP:FORMAT COMMON-LISP:T "~%REFERENCE ~A~%"
                        DREYECK/HYPERDOC/CURATION/TESTS::TITLE)
    (COMMON-LISP:DOLIST
        (DREYECK/HYPERDOC/CURATION/TESTS::ROW
         (DREYECK/TOPICMAP/CURATION:REFERENCE-SUMMARY
          DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE))
      (COMMON-LISP:WHEN
          (COMMON-LISP:OR
           (COMMON-LISP:EQUAL DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                              (COMMON-LISP:FIRST
                               DREYECK/HYPERDOC/CURATION/TESTS::ROW))
           (COMMON-LISP:EQUAL DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                              (COMMON-LISP:THIRD
                               DREYECK/HYPERDOC/CURATION/TESTS::ROW)))
        (COMMON-LISP:FORMAT COMMON-LISP:T "~S~%"
                            DREYECK/HYPERDOC/CURATION/TESTS::ROW)))
    (COMMON-LISP:FORMAT COMMON-LISP:T "~%IMPACT ~A~%~S~%"
                        DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                        DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY)
    (COMMON-LISP:FORMAT COMMON-LISP:T "~%UNRESOLVED ~D~%"
                        (COMMON-LISP:LENGTH
                         (COMMON-LISP:GETF
                          (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-SOURCE-OF
                           DREYECK/HYPERDOC/CURATION/TESTS::PROJECTION)
                          :DIAGNOSTICS)))
    DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE))

(DEFUN PAGE-CONTRACT-WITHOUT-USE (BOOK)
  (LET ((PAGE
         (HYPERBOOK:FIND-PAGE BOOK "Observing an Upstream Commit"
                              :SIGNAL-ERROR? T)))
    (DECLARE (IGNORE PAGE))
    NIL))

(DEFUN TEXTUAL-PAGE-CONTRACT-ONLY ()
  "(check-page-executable-contract page ...)")

(DEFUN SHADOWED-PAGE-CONTRACT (BOOK OTHER-PAGE)
  (FLET ((CHECK-PAGE-EXECUTABLE-CONTRACT (&REST ARGUMENTS)
           (DECLARE (IGNORE ARGUMENTS))
           NIL))
    (LET ((PAGE
           (HYPERBOOK:FIND-PAGE BOOK "Observing an Upstream Commit"
                                :SIGNAL-ERROR? T)))
      (DECLARE (IGNORE PAGE))
      (LET ((PAGE OTHER-PAGE))
        (CHECK-PAGE-EXECUTABLE-CONTRACT PAGE
         "(hyperdoc-host-not-found-upstream-intake-example)" NIL "fixture")))))

(DEFUN CHECK-PAGE-EXECUTABLE-NEGATIVE-CONTRACTS (PAGE TEST-PATH)
  (DOLIST
      (NAME
       '("PAGE-CONTRACT-WITHOUT-USE" "TEXTUAL-PAGE-CONTRACT-ONLY"
         "SHADOWED-PAGE-CONTRACT"))
    (ASSERT
     (REJECTED-P
      (LAMBDA ()
        (DREYECK/HYPERDOC/CURATION:MAKE-REFERENCE-WORKSPACE PAGE :SOURCE-FILES
                                                            (LIST TEST-PATH)
                                                            :CONTRACTS
                                                            (LIST
                                                             (LIST :ROLE
                                                                   :PAGE-EXECUTABLE
                                                                   :PATHNAME
                                                                   TEST-PATH
                                                                   :NAME
                                                                   NAME)))))))
  T)

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS:RUN-TESTS COMMON-LISP:NIL
                   (COMMON-LISP:LET*
                                     ((DREYECK/HYPERDOC/CURATION/TESTS::BOOK
                                                                             DREYECK/UPSTREAM-INTAKE:*UPSTREAM-INTAKE-HYPERDOC*)
                                      (PAGE
                                            (HYPERBOOK:FIND-PAGE
                                                                 DREYECK/HYPERDOC/CURATION/TESTS::BOOK
                                                                 "Observing an Upstream Commit"
                                                                 :SIGNAL-ERROR?
                                                                 COMMON-LISP:T))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::PATHS
                                                                              (COMMON-LISP:APPEND
                                                                                                  (DREYECK/HYPERDOC/CURATION/TESTS::INVENTORY)
                                                                                                  (COMMON-LISP:LOOP
                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::FOR
                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::P
                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::BEING
                                                                                                                    COMMON-LISP:THE
                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::HASH-VALUES
                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::OF
                                                                                                                    (HYPERDOC:PAGES-OF
                                                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::BOOK)
                                                                                                                    COMMON-LISP:WHEN
                                                                                                                    (COMMON-LISP:TYPEP
                                                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::P
                                                                                                                                       (COMMON-LISP:FIND-CLASS
                                                                                                                                                               (COMMON-LISP:FIND-SYMBOL
                                                                                                                                                                                        "HTML-PAGE"
                                                                                                                                                                                        "HYPERDOC")))
                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::COLLECT
                                                                                                                    (HYPERDOC:FILE-OF
                                                                                                                                      DREYECK/HYPERDOC/CURATION/TESTS::P))))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::BEFORE
                                                                               (COMMON-LISP:MAPCAR
                                                                                                   (COMMON-LISP:FUNCTION
                                                                                                                         UIOP/STREAM:READ-FILE-STRING)
                                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::PATHS))
                                      (TEST-PATH
                                                 (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
                                                                                       "dreyeck"
                                                                                       "dreyeck/tests/hyperdoc-curation-smoke.lisp"))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::OWN-RECORDS
                                                                                    (DREYECK/HYPERDOC/CURATION::SOURCE-RECORDS
                                                                                                                               (COMMON-LISP:LIST
                                                                                                                                                 TEST-PATH))))
                                     (DREYECK/HYPERDOC/CURATION/TESTS::RUN-WITNESS
                                                                                   "Observing an Upstream Commit"
                                                                                   "HYPERDOC-HOST-NOT-FOUND-UPSTREAM-INTAKE-EXAMPLE")
                                     (DREYECK/HYPERDOC/CURATION/TESTS::RUN-WITNESS
                                                                                   "An Upstream Supersession Hypothesis"
                                                                                   "HYPERSPEC-COMPONENT-UPSTREAM-INTAKE-EXAMPLE")
                                     (COMMON-LISP:DOLIST
                                                         (DREYECK/HYPERDOC/CURATION/TESTS::SPEC
                                                                                                (COMMON-LISP:QUOTE
                                                                                                                   ((:EXPECTED-PAGE-SET
                                                                                                                                        "*NOT-A-PAGE-TABLE*")
                                                                                                                    (:NAVIGATION
                                                                                                                                 "NOT-A-NAVIGATION-CONTRACT")
                                                                                                                    (:PAGE-EXECUTABLE
                                                                                                                                      "NOT-A-NAVIGATION-CONTRACT")
                                                                                                                    (:SYMBOL-EXISTENCE
                                                                                                                                       "NOT-A-NAVIGATION-CONTRACT"))))
                                                         (COMMON-LISP:ASSERT
                                                                             (DREYECK/HYPERDOC/CURATION/TESTS::REJECTED-P
                                                                                                                          (COMMON-LISP:LAMBDA
                                                                                                                                              COMMON-LISP:NIL
                                                                                                                                              (DREYECK/HYPERDOC/CURATION:MAKE-REFERENCE-WORKSPACE
                                                                                                                                                                                                  PAGE
                                                                                                                                                                                                  :SOURCE-FILES
                                                                                                                                                                                                  (COMMON-LISP:LIST
                                                                                                                                                                                                                    TEST-PATH)
                                                                                                                                                                                                  :CONTRACTS
                                                                                                                                                                                                  (COMMON-LISP:LIST
                                                                                                                                                                                                                    (COMMON-LISP:LIST
                                                                                                                                                                                                                                      :ROLE
                                                                                                                                                                                                                                      (COMMON-LISP:FIRST
                                                                                                                                                                                                                                                         DREYECK/HYPERDOC/CURATION/TESTS::SPEC)
                                                                                                                                                                                                                                      :PATHNAME
                                                                                                                                                                                                                                      TEST-PATH
                                                                                                                                                                                                                                      :NAME
                                                                                                                                                                                                                                      (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                          DREYECK/HYPERDOC/CURATION/TESTS::SPEC))))))))
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:NULL
                                                                           (DREYECK/HYPERDOC/CURATION::DIRECT-CALLS
                                                                                                                    (COMMON-LISP:FIND
                                                                                                                                      "QUOTED-REFERENCE"
                                                                                                                                      DREYECK/HYPERDOC/CURATION/TESTS::OWN-RECORDS
                                                                                                                                      :TEST
                                                                                                                                      (COMMON-LISP:FUNCTION
                                                                                                                                                            COMMON-LISP:EQUAL)
                                                                                                                                      :KEY
                                                                                                                                      (COMMON-LISP:LAMBDA
                                                                                                                                                          (DREYECK/HYPERDOC/CURATION/TESTS::R)
                                                                                                                                                          (COMMON-LISP:GETF
                                                                                                                                                                            DREYECK/HYPERDOC/CURATION/TESTS::R
                                                                                                                                                                            :NAME)))
                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::OWN-RECORDS)))
                                     (COMMON-LISP:MULTIPLE-VALUE-BIND
                                                                      (DREYECK/HYPERDOC/CURATION/TESTS::CODE
                                                                                                             DREYECK/HYPERDOC/CURATION/TESTS::RECOVERED)
                                                                      (HTML-INSPECTOR-VIEWS/STANDARD:PARSE-LISP-CODE
                                                                                                                     "(defun curation-missing-package::subject () (quote #:uninterned))")
                                                                      (COMMON-LISP:ASSERT
                                                                                          (COMMON-LISP:NOT
                                                                                                           DREYECK/HYPERDOC/CURATION/TESTS::RECOVERED))
                                                                      (COMMON-LISP:LET*
                                                                                        ((DREYECK/HYPERDOC/CURATION/TESTS::RAW
                                                                                                                               (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                                         (HTML-INSPECTOR-VIEWS/STANDARD:CST-OF
                                                                                                                                                                                               (COMMON-LISP:FIRST
                                                                                                                                                                                                                  (HTML-INSPECTOR-VIEWS/STANDARD:TOP-LEVEL-FORMS-OF
                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::CODE)))))
                                                                                         (DREYECK/HYPERDOC/CURATION/TESTS::TOKEN
                                                                                                                                 (COMMON-LISP:SECOND
                                                                                                                                                     DREYECK/HYPERDOC/CURATION/TESTS::RAW)))
                                                                                        (COMMON-LISP:ASSERT
                                                                                                            (COMMON-LISP:EQUAL
                                                                                                                               "SUBJECT"
                                                                                                                               (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                                                                                                                                                                      DREYECK/HYPERDOC/CURATION/TESTS::TOKEN)))
                                                                                        (COMMON-LISP:ASSERT
                                                                                                            (COMMON-LISP:EQUAL
                                                                                                                               "CURATION-MISSING-PACKAGE"
                                                                                                                               (COMMON-LISP:FIRST
                                                                                                                                                  (DREYECK/HYPERDOC/CURATION::TOKEN-KEY
                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION/TESTS::TOKEN))))))
                                     (COMMON-LISP:LET
                                                      ((DREYECK/HYPERDOC/CURATION/TESTS::PROXY
                                                                                               (COMMON-LISP:MAKE-INSTANCE
                                                                                                                          (COMMON-LISP:QUOTE
                                                                                                                                             HTML-INSPECTOR-VIEWS/STANDARD::SYMBOL-PROXY))))
                                                      (COMMON-LISP:SETF
                                                                        (COMMON-LISP:SLOT-VALUE
                                                                                                DREYECK/HYPERDOC/CURATION/TESTS::PROXY
                                                                                                (COMMON-LISP:QUOTE
                                                                                                                   HTML-INSPECTOR-VIEWS/STANDARD::NAME))
                                                                        "UNRESOLVED"
                                                                        (COMMON-LISP:SLOT-VALUE
                                                                                                DREYECK/HYPERDOC/CURATION/TESTS::PROXY
                                                                                                (COMMON-LISP:QUOTE
                                                                                                                   COMMON-LISP:PACKAGE-NAME))
                                                                        COMMON-LISP:NIL)
                                                      (COMMON-LISP:ASSERT
                                                                          (COMMON-LISP:EQUAL
                                                                                             (COMMON-LISP:QUOTE
                                                                                                                (COMMON-LISP:NIL
                                                                                                                                 "UNRESOLVED"))
                                                                                             (DREYECK/HYPERDOC/CURATION::TOKEN-KEY
                                                                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::PROXY)))
                                                      (COMMON-LISP:ASSERT
                                                                          (COMMON-LISP:NULL
                                                                                            (DREYECK/HYPERDOC/CURATION::RESOLVE-RECORD
                                                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::PROXY
                                                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::OWN-RECORDS))))
                                     (PROGN
                                            (CHECK-PAGE-EXECUTABLE-NEGATIVE-CONTRACTS
                                                                                      PAGE
                                                                                      TEST-PATH)
                                            (COMMON-LISP:ASSERT
                                                                (COMMON-LISP:EQUAL
                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::BEFORE
                                                                                   (COMMON-LISP:MAPCAR
                                                                                                       (COMMON-LISP:FUNCTION
                                                                                                                             UIOP/STREAM:READ-FILE-STRING)
                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::PATHS))))
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:NOT
                                                                          (COMMON-LISP:FIND-PACKAGE
                                                                                                    :DREYECK/WORKFLOW/AUTHORING)))
                                     (COMMON-LISP:FORMAT COMMON-LISP:T
                                                         "~%CURATION-HYPERDOC-PASS: two witnesses, structural rejection, proxies, source unchanged.~%")
                                     COMMON-LISP:T))
