
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

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::INVENTORY NIL
                   (NTH-VALUE 0
                              (DREYECK/UPSTREAM-INTAKE::UPSTREAM-INTAKE-CURATION-INPUTS)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::CONTRACTS NIL
                   (NTH-VALUE 1
                              (DREYECK/UPSTREAM-INTAKE::UPSTREAM-INTAKE-CURATION-INPUTS)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::CHECK-SOURCE-WARRANTS
                   (DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)
                   (COMMON-LISP:LABELS
                                       ((DREYECK/HYPERDOC/CURATION/TESTS::VERIFY
                                                                                 (DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                                                                 (PROGN
                                                                                        (COMMON-LISP:WHEN
                                                                                                          (COMMON-LISP:CONSP
                                                                                                                             DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                                                                                          (COMMON-LISP:WHEN
                                                                                                                            (COMMON-LISP:AND
                                                                                                                                             (COMMON-LISP:EQ
                                                                                                                                                             (COMMON-LISP:FIRST
                                                                                                                                                                                DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                                                                                                                                             :KIND)
                                                                                                                                             (COMMON-LISP:MEMBER
                                                                                                                                                                 (COMMON-LISP:SECOND
                                                                                                                                                                                     DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                                                                                                                                                 (QUOTE
                                                                                                                                                                        (:LISP-CST
                                                                                                                                                                                   :HTML-SOURCE-ELEMENT))))
                                                                                                                            (COMMON-LISP:LET
                                                                                                                                             ((DREYECK/HYPERDOC/CURATION/TESTS::SPAN
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
                                                                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::VALUE)))
                                                                                        (COMMON-LISP:WHEN
                                                                                                          (COMMON-LISP:AND
                                                                                                                           (COMMON-LISP:CONSP
                                                                                                                                              DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                                                                                                           (COMMON-LISP:EQ
                                                                                                                                           (COMMON-LISP:FIRST
                                                                                                                                                              DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                                                                                                                           :KIND)
                                                                                                                           (COMMON-LISP:EQ
                                                                                                                                           (COMMON-LISP:SECOND
                                                                                                                                                               DREYECK/HYPERDOC/CURATION/TESTS::VALUE)
                                                                                                                                           :PAGE-SOURCE-PATHNAME))
                                                                                                          (COMMON-LISP:ASSERT
                                                                                                                              (COMMON-LISP:EQUAL
                                                                                                                                                 (COMMON-LISP:GETF
                                                                                                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::VALUE
                                                                                                                                                                   :SOURCE)
                                                                                                                                                 (UIOP/STREAM:READ-FILE-STRING
                                                                                                                                                                               (COMMON-LISP:GETF
                                                                                                                                                                                                 DREYECK/HYPERDOC/CURATION/TESTS::VALUE
                                                                                                                                                                                                 :PATHNAME))))))))
                                       (COMMON-LISP:DOLIST
                                                           (DREYECK/HYPERDOC/CURATION/TESTS::EDGE
                                                                                                  (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                                                                                                                                        (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)))
                                                           (COMMON-LISP:LET
                                                                            ((DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                                                                                                                          (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                                                                                                                                                               DREYECK/HYPERDOC/CURATION/TESTS::EDGE)))
                                                                            (COMMON-LISP:ASSERT
                                                                                                (COMMON-LISP:MEMBER
                                                                                                                    (COMMON-LISP:GETF
                                                                                                                                      DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                                                                                                                                      :EPISTEMIC-STATUS)
                                                                                                                    (QUOTE
                                                                                                                           (:SOURCE-OBSERVED
                                                                                                                                             :LIVE-OBSERVED))))
                                                                            (COMMON-LISP:ASSERT
                                                                                                (COMMON-LISP:GETF
                                                                                                                  DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                                                                                                                  :WARRANT))
                                                                            (DREYECK/HYPERDOC/CURATION/TESTS::VERIFY
                                                                                                                     (COMMON-LISP:GETF
                                                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::PROPERTIES
                                                                                                                                       :WARRANT))))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS::RUN-WITNESS
                   (DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                                                           DREYECK/HYPERDOC/CURATION/TESTS::EXAMPLE
                                                           &OPTIONAL
                                                           EXACT-EXPECTED)
                   (COMMON-LISP:LET*
                                     ((DREYECK/HYPERDOC/CURATION/TESTS::PAGE
                                                                             (HYPERBOOK:FIND-PAGE
                                                                                                  DREYECK/UPSTREAM-INTAKE:*UPSTREAM-INTAKE-HYPERDOC*
                                                                                                  DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                                                                                                  :SIGNAL-ERROR?
                                                                                                  COMMON-LISP:T))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE
                                                                                  (DREYECK/HYPERDOC/CURATION:MAKE-REFERENCE-WORKSPACE
                                                                                                                                      DREYECK/HYPERDOC/CURATION/TESTS::PAGE
                                                                                                                                      :SOURCE-FILES
                                                                                                                                      (DREYECK/HYPERDOC/CURATION/TESTS::INVENTORY)
                                                                                                                                      :CONTRACTS
                                                                                                                                      (DREYECK/HYPERDOC/CURATION/TESTS::CONTRACTS)))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::PROJECTION
                                                                                   (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
                                                                                                                                      DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::POINT
                                                                              (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                                                                                                                            DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::IMPACT
                                                                               (DREYECK/TOPICMAP/CURATION:MAKE-IMPACT-WORKSPACE
                                                                                                                                DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE
                                                                                                                                :POLICY
                                                                                                                                (FUNCTION
                                                                                                                                          DREYECK/HYPERDOC/CURATION:HYPERDOC-REMOVAL-IMPACT)))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY
                                                                                (DREYECK/TOPICMAP/CURATION:IMPACT-SUMMARY
                                                                                                                          DREYECK/HYPERDOC/CURATION/TESTS::IMPACT))
                                      (DREYECK/HYPERDOC/CURATION/TESTS::EXPECTED
                                                                                 (COMMON-LISP:OR
                                                                                                 EXACT-EXPECTED
                                                                                                 (COMMON-LISP:LIST
                                                                                                                   (COMMON-LISP:LIST
                                                                                                                                     :REMOVE
                                                                                                                                     DREYECK/HYPERDOC/CURATION/TESTS::TITLE)
                                                                                                                   (COMMON-LISP:LIST
                                                                                                                                     :REMOVE-WITH-PAGE
                                                                                                                                     (FILE-NAMESTRING
                                                                                                                                                      (HYPERDOC:FILE-OF
                                                                                                                                                                        DREYECK/HYPERDOC/CURATION/TESTS::PAGE)))
                                                                                                                   (QUOTE
                                                                                                                          (:MUST-EDIT
                                                                                                                                      "Upstream Intake as a Read-Only Observation"))
                                                                                                                   (QUOTE
                                                                                                                          (:MUST-EDIT
                                                                                                                                      "+UPSTREAM-INTAKE-PAGE-SPECS+"))
                                                                                                                   (QUOTE
                                                                                                                          (:MUST-EDIT-OR-DELETE
                                                                                                                                                "CHECK-PAGE-NAVIGATION"))
                                                                                                                   (QUOTE
                                                                                                                          (:MUST-EDIT-OR-DELETE
                                                                                                                                                "RUN-HYPERDOC-PAGE-TESTS"))
                                                                                                                   (COMMON-LISP:LIST
                                                                                                                                     :KEEP
                                                                                                                                     DREYECK/HYPERDOC/CURATION/TESTS::EXAMPLE)))))
                                     (COMMON-LISP:DOLIST
                                                         (DREYECK/HYPERDOC/CURATION/TESTS::ROW
                                                                                               DREYECK/HYPERDOC/CURATION/TESTS::EXPECTED)
                                                         (COMMON-LISP:ASSERT
                                                                             (COMMON-LISP:MEMBER
                                                                                                 DREYECK/HYPERDOC/CURATION/TESTS::ROW
                                                                                                 DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY
                                                                                                 :TEST
                                                                                                 (FUNCTION
                                                                                                           COMMON-LISP:EQUAL))
                                                                             NIL
                                                                             "Missing impact ~S in ~S"
                                                                             DREYECK/HYPERDOC/CURATION/TESTS::ROW
                                                                             DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY))
                                     (COMMON-LISP:WHEN EXACT-EXPECTED
                                                       (COMMON-LISP:ASSERT
                                                                           (NULL
                                                                                 (SET-EXCLUSIVE-OR
                                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::EXPECTED
                                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY
                                                                                                   :TEST
                                                                                                   (FUNCTION
                                                                                                             COMMON-LISP:EQUAL))))
                                                       (COMMON-LISP:ASSERT
                                                                           (=
                                                                              (COMMON-LISP:LENGTH
                                                                                                  DREYECK/HYPERDOC/CURATION/TESTS::EXPECTED)
                                                                              (COMMON-LISP:LENGTH
                                                                                                  DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY))))
                                     (when (equal title "Observing an Upstream Commit")
  (assert
   (member
    '(:must-edit-or-delete "UPSTREAM-INTAKE-REMOVAL-WORKSPACE-EXAMPLE")
    summary :test #'equal))
  (check-literal-lookup-edge
   reference "UPSTREAM-INTAKE-REMOVAL-WORKSPACE-EXAMPLE")
  (multiple-value-bind (cut findings)
      (dreyeck/hyperdoc/curation:hyperdoc-removal-impact projection point)
    (declare (ignore cut))
    (assert
     (find :executable-page-dependency findings
           :key (lambda (finding) (getf finding :rule))))))
(DREYECK/HYPERDOC/CURATION/TESTS::CHECK-SOURCE-WARRANTS
                                                                                             DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)
                                     (COMMON-LISP:LET*
                                                       ((DREYECK/HYPERDOC/CURATION/TESTS::RESULT
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
                                                                           (COMMON-LISP:LET*
                                                                                             ((DREYECK/HYPERDOC/CURATION/TESTS::PROPS
                                                                                                                                      (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION/TESTS::EDGE))
                                                                                              (DREYECK/HYPERDOC/CURATION/TESTS::W
                                                                                                                                  (COMMON-LISP:GETF
                                                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::PROPS
                                                                                                                                                    :WARRANT)))
                                                                                             (COMMON-LISP:ASSERT
                                                                                                                 (COMMON-LISP:EQ
                                                                                                                                 :MECHANICALLY-DERIVED
                                                                                                                                 (COMMON-LISP:GETF
                                                                                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::PROPS
                                                                                                                                                   :EPISTEMIC-STATUS)))
                                                                                             (COMMON-LISP:ASSERT
                                                                                                                 (COMMON-LISP:EQUAL
                                                                                                                                    DREYECK/HYPERDOC/CURATION/TESTS::POINT
                                                                                                                                    (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                                                                                                                                                                   DREYECK/HYPERDOC/CURATION/TESTS::EDGE)))
                                                                                             (COMMON-LISP:DOLIST
                                                                                                                 (DREYECK/HYPERDOC/CURATION/TESTS::ID
                                                                                                                                                      (COMMON-LISP:GETF
                                                                                                                                                                        DREYECK/HYPERDOC/CURATION/TESTS::W
                                                                                                                                                                        :REFERENCE-EDGES))
                                                                                                                 (COMMON-LISP:ASSERT
                                                                                                                                     (COMMON-LISP:FIND
                                                                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::ID
                                                                                                                                                       DREYECK/HYPERDOC/CURATION/TESTS::REFERENCES
                                                                                                                                                       :KEY
                                                                                                                                                       (FUNCTION
                                                                                                                                                                 DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF)
                                                                                                                                                       :TEST
                                                                                                                                                       (FUNCTION
                                                                                                                                                                 COMMON-LISP:EQUAL))))
                                                                                             (COMMON-LISP:WHEN
                                                                                                               (COMMON-LISP:EQ
                                                                                                                               :KEEP
                                                                                                                               (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                                                                                                                                                                              DREYECK/HYPERDOC/CURATION/TESTS::EDGE))
                                                                                                               (COMMON-LISP:ASSERT
                                                                                                                                   (COMMON-LISP:GETF
                                                                                                                                                     DREYECK/HYPERDOC/CURATION/TESTS::W
                                                                                                                                                     :SURVIVING-RETENTION-EDGES))
                                                                                                               (COMMON-LISP:DOLIST
                                                                                                                                   (DREYECK/HYPERDOC/CURATION/TESTS::ID
                                                                                                                                                                        (COMMON-LISP:GETF
                                                                                                                                                                                          DREYECK/HYPERDOC/CURATION/TESTS::W
                                                                                                                                                                                          :SURVIVING-RETENTION-EDGES))
                                                                                                                                   (COMMON-LISP:LET
                                                                                                                                                    ((DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR
                                                                                                                                                                                                (COMMON-LISP:FIND
                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION/TESTS::ID
                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION/TESTS::REFERENCES
                                                                                                                                                                                                                  :KEY
                                                                                                                                                                                                                  (FUNCTION
                                                                                                                                                                                                                            DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF)
                                                                                                                                                                                                                  :TEST
                                                                                                                                                                                                                  (FUNCTION
                                                                                                                                                                                                                            COMMON-LISP:EQUAL))))
                                                                                                                                                    (COMMON-LISP:ASSERT
                                                                                                                                                                        DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR)
                                                                                                                                                    (COMMON-LISP:ASSERT
                                                                                                                                                                        (COMMON-LISP:MEMBER
                                                                                                                                                                                            (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR)
                                                                                                                                                                                            (QUOTE
                                                                                                                                                                                                   (:EXPOSES-EXECUTABLE-LINK
                                                                                                                                                                                                                             :INVOKES
                                                                                                                                                                                                                             :PRESENTS-SOURCE-OF))))
                                                                                                                                                    (COMMON-LISP:ASSERT
                                                                                                                                                                        (COMMON-LISP:NOT
                                                                                                                                                                                         (COMMON-LISP:MEMBER
                                                                                                                                                                                                             (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                                                                                                                                                                                                                                            DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR)
                                                                                                                                                                                                             DREYECK/HYPERDOC/CURATION/TESTS::CUT
                                                                                                                                                                                                             :TEST
                                                                                                                                                                                                             (FUNCTION
                                                                                                                                                                                                                       COMMON-LISP:EQUAL))))
                                                                                                                                                    (COMMON-LISP:ASSERT
                                                                                                                                                                        (COMMON-LISP:EQUAL
                                                                                                                                                                                           (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION/TESTS::SURVIVOR)
                                                                                                                                                                                           (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION/TESTS::EDGE)))))))))
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:EQUAL
                                                                            DREYECK/HYPERDOC/CURATION/TESTS::POINT
                                                                            (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                                                                                                                          DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)))
                                     (COMMON-LISP:ASSERT
                                                         (COMMON-LISP:EQ
                                                                         DREYECK/HYPERDOC/CURATION/TESTS::PROJECTION
                                                                         (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
                                                                                                                            DREYECK/HYPERDOC/CURATION/TESTS::REFERENCE)))
                                     (COMMON-LISP:FORMAT COMMON-LISP:T
                                                         "~%IMPACT ~A~%~S~%"
                                                         DREYECK/HYPERDOC/CURATION/TESTS::TITLE
                                                         DREYECK/HYPERDOC/CURATION/TESTS::SUMMARY)
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

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION/TESTS:RUN-TESTS NIL
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
(check-literal-lookup-fixtures page test-path)
(PROGN (CHECK-FIVE-PAGE-EVIDENCE)
       (CHECK-SOURCE-VIEW-PARSER)
       (DREYECK/HYPERDOC/CURATION/TESTS::RUN-WITNESS
        "Observing an Upstream Commit"
        "HYPERDOC-HOST-NOT-FOUND-UPSTREAM-INTAKE-EXAMPLE"
        (EXPECTED-INTAKE-IMPACT :COMMIT))
       (DREYECK/HYPERDOC/CURATION/TESTS::RUN-WITNESS
        "HyperDoc Page Loading: Source Ahead of the Running Image"
        NIL
        (EXPECTED-INTAKE-IMPACT :PAGE-LOADING)))
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
                                                                                                                                              NIL
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
                                                                        NIL)
                                                      (COMMON-LISP:ASSERT
                                                                          (COMMON-LISP:EQUAL
                                                                                             (COMMON-LISP:QUOTE
                                                                                                                (NIL
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
                                                         "~%CURATION-HYPERDOC-PASS: five-page evidence, exact cuts, source spans, structural rejection, proxies, source unchanged.~%")
                                     COMMON-LISP:T))

(defun literal-lookup-direct (book)
  (hyperbook:find-page book "Observing an Upstream Commit"))

(defun literal-lookup-value-bindings (book)
  (multiple-value-bind (book) (values book)
    (let* ((hyperbook:find-page nil)
           (page (hyperbook:find-page book "Observing an Upstream Commit")))
      (declare (ignore hyperbook:find-page))
      page)))

(defun literal-lookup-dynamic (book title)
  (hyperbook:find-page book title))

(defun literal-lookup-quoted ()
  '(hyperbook:find-page book "Observing an Upstream Commit"))

(defun literal-lookup-quasiquoted (book)
  `(value ,(hyperbook:find-page book "Observing an Upstream Commit")))

(defun literal-lookup-flet (book)
  (flet ((hyperbook:find-page (&rest args) (declare (ignore args)) nil))
    (hyperbook:find-page book "Observing an Upstream Commit")))

(defun literal-lookup-labels (book)
  (labels ((hyperbook:find-page (&rest args) (declare (ignore args)) nil))
    (hyperbook:find-page book "Observing an Upstream Commit")))

(defun literal-lookup-macrolet (book)
  (declare (ignore book))
  (macrolet ((hyperbook:find-page (&rest args) (declare (ignore args)) nil))
    (hyperbook:find-page book "Observing an Upstream Commit")))

(defun find-page (&rest args)
  (declare (ignore args))
  (never-evaluate))

(defun literal-lookup-wrong-package (book)
  (find-page book "Observing an Upstream Commit"))

(defun literal-lookup-missing-page (book)
  (hyperbook:find-page book "Not a current curation page"))

(defun check-literal-lookup-edge (reference name)
  (let* ((projection (dreyeck/topicmap:topicmap-workspace-projection-of reference))
         (edges (remove-if-not
                 (lambda (edge)
                   (eq :looks-up-page
                       (dreyeck/topicmap:topicmap-association-type-of edge)))
                 (dreyeck/topicmap:topicmap-projection-associations-of projection))))
    (assert (= 1 (length edges)))
    (let* ((edge (first edges))
           (warrant (getf (dreyeck/topicmap:topicmap-association-properties-of edge)
                          :warrant)))
      (assert (equal name
                     (dreyeck/topicmap:topicmap-topic-label-of
                      (dreyeck/topicmap:topicmap-projection-topic-by-id
                       projection (dreyeck/topicmap:topicmap-association-from-of edge)))))
      (assert (equal "Observing an Upstream Commit"
                     (dreyeck/topicmap:topicmap-topic-label-of
                      (dreyeck/topicmap:topicmap-projection-topic-by-id
                       projection (dreyeck/topicmap:topicmap-association-to-of edge)))))
      (assert (eq :lisp-cst (getf warrant :kind)))
      (assert (equal name (getf warrant :top-level-name)))
      (assert (equal (getf warrant :caller-contract)
                     (list :role :literal-page-lookup
                           :pathname (getf warrant :pathname) :name name)))
      (check-source-warrants reference)
      (format t "~%LITERAL-LOOKUP-WARRANT ~S~%" warrant))))

(defun check-literal-lookup-fixtures (page test-path)
  (let ((before (uiop:read-file-string test-path)))
    (assert
     (notany (lambda (edge)
               (eq :looks-up-page (dreyeck/topicmap:topicmap-association-type-of edge)))
             (dreyeck/topicmap:topicmap-projection-associations-of
              (dreyeck/topicmap:topicmap-workspace-projection-of
               (dreyeck/hyperdoc/curation:make-reference-workspace
                page :source-files (list test-path))))))
    (dolist (name '("LITERAL-LOOKUP-DIRECT" "LITERAL-LOOKUP-VALUE-BINDINGS"))
      (check-literal-lookup-edge
       (dreyeck/hyperdoc/curation:make-reference-workspace
        page :source-files (list test-path)
        :contracts (list (list :role :literal-page-lookup :pathname test-path :name name)))
       name))
    (dolist (name '("LITERAL-LOOKUP-DYNAMIC" "LITERAL-LOOKUP-QUOTED"
                    "LITERAL-LOOKUP-QUASIQUOTED" "LITERAL-LOOKUP-FLET"
                    "LITERAL-LOOKUP-LABELS" "LITERAL-LOOKUP-MACROLET"
                    "LITERAL-LOOKUP-WRONG-PACKAGE" "LITERAL-LOOKUP-MISSING-PAGE"))
      (assert
       (handler-case
           (progn
             (dreyeck/hyperdoc/curation:make-reference-workspace
              page :source-files (list test-path)
              :contracts (list (list :role :literal-page-lookup :pathname test-path :name name)))
             nil)
         (error (condition)
           (search "Declared contract has no supported structural evidence"
                   (princ-to-string condition)))))
      (format t "~%LITERAL-LOOKUP-REJECTED ~A~%" name))
    (assert (equal before (uiop:read-file-string test-path)))))
(defun expected-intake-impact (point)
  "Exact outcomes observed for the two supported reader witnesses."
  (ecase point
    (:commit
     '((:remove "Observing an Upstream Commit")
       (:remove-with-page "Observing an Upstream Commit.html")
       (:must-edit "An Upstream Supersession Hypothesis")
       (:must-edit "Upstream Intake as a Read-Only Observation")
       (:must-edit "+UPSTREAM-INTAKE-PAGE-SPECS+")
       (:must-edit-or-delete "CHECK-PAGE-NAVIGATION")
       (:must-edit-or-delete "RUN-HYPERDOC-PAGE-TESTS")
        (:must-edit-or-delete "UPSTREAM-INTAKE-REMOVAL-WORKSPACE-EXAMPLE")

       (:keep "HYPERDOC-HOST-NOT-FOUND-UPSTREAM-INTAKE-EXAMPLE")
       (:keep "MAKE-HYPERDOC-HOST-NOT-FOUND-INTAKE")))
    (:page-loading
     '((:remove "HyperDoc Page Loading: Source Ahead of the Running Image")
       (:remove-with-page "HyperDoc Page Loading - Source Ahead of the Running Image.html")
       (:must-edit "Upstream Intake as a Read-Only Observation")
       (:must-edit "+UPSTREAM-INTAKE-PAGE-SPECS+")
       (:must-edit-or-delete "CHECK-PAGE-NAVIGATION")
       (:must-edit-or-delete "RUN-HYPERDOC-PAGE-TESTS")
       (:review-for-orphaning "HYPERDOC-PAGE-LOADING-COMPARISON-EXAMPLE")
       (:review-for-orphaning "HYPERDOC-PAGE-LOADING-IMAGE-STATE-EXAMPLE")
       (:review-for-orphaning "HYPERDOC-PAGE-LOADING-SOURCE-STATE-EXAMPLE")
       (:review-for-orphaning "HYPERDOC-PAGE-LOADING-CHECKPOINT-EXAMPLE")))))

(defun check-five-page-evidence ()
  (let* ((book dreyeck/upstream-intake:*upstream-intake-hyperdoc*)
         (title "HyperDoc Page Loading: Source Ahead of the Running Image")
         (page (hyperbook:find-page book title :signal-error? t))
         (reference (dreyeck/hyperdoc/curation:make-reference-workspace
                     page :source-files (inventory) :contracts (contracts)))
         (projection (dreyeck/topicmap:topicmap-workspace-projection-of reference))
         (topics (dreyeck/topicmap:topicmap-projection-topics-of projection))
         (rows (dreyeck/topicmap/curation:reference-summary reference))
         (spec-record (find "+UPSTREAM-INTAKE-PAGE-SPECS+"
                            (dreyeck/hyperdoc/curation::source-records (inventory))
                            :key (lambda (record) (getf record :name)) :test #'equal))
         (specs (second (third (getf spec-record :raw)))))
    (assert (= (length specs) (count :page topics :key #'dreyeck/topicmap:topicmap-topic-type-of)))
    (assert (= (length specs) (count :html-source topics :key #'dreyeck/topicmap:topicmap-topic-type-of)))
    (dolist (spec specs)
      (destructuring-bind (id filename) spec
        (let* ((reader-page (hyperbook:find-page book id :signal-error? t))
               (page-topic (dreyeck/topicmap:topicmap-projection-topic-by-id
                            projection (format nil "page:dreyeck/upstream-intake/~A" id)))
               (file-topic (dreyeck/topicmap:topicmap-projection-topic-by-id
                            projection (format nil "file:~A" (hyperdoc:file-of reader-page)))))
          (assert (eq :page (dreyeck/topicmap:topicmap-topic-type-of page-topic)))
          (assert (equal id (dreyeck/topicmap:topicmap-topic-label-of page-topic)))
          (assert (eq :html-source (dreyeck/topicmap:topicmap-topic-type-of file-topic)))
          (assert (equal filename (dreyeck/topicmap:topicmap-topic-label-of file-topic)))
          (assert (member (list filename :source-of-page id) rows :test #'equal)))))
    (let ((expected
            (list (list "Upstream Intake" :contains-page title)
                  (list "HyperDoc Page Loading - Source Ahead of the Running Image.html" :source-of-page title)
                  (list "Upstream Intake as a Read-Only Observation" :links-to-page title)
                  (list title :links-to-page "Upstream Intake as a Read-Only Observation")
                  (list title :exposes-executable-link "HYPERDOC-PAGE-LOADING-COMPARISON-EXAMPLE")
                  (list title :presents-source-of "HYPERDOC-PAGE-LOADING-IMAGE-STATE-EXAMPLE")
                  (list title :presents-source-of "HYPERDOC-PAGE-LOADING-SOURCE-STATE-EXAMPLE")
                  (list title :presents-source-of "HYPERDOC-PAGE-LOADING-CHECKPOINT-EXAMPLE")
                  (list "+UPSTREAM-INTAKE-PAGE-SPECS+" :asserts-page-presence title)
                  (list "CHECK-PAGE-NAVIGATION" :asserts-navigation title)
                  (list "RUN-HYPERDOC-PAGE-TESTS" :tests-page title)))
          (actual (remove-if-not (lambda (row) (or (equal title (first row))
                                                   (equal title (third row)))) rows)))
      (assert (null (set-exclusive-or expected actual :test #'equal)))
      (assert (= (length expected) (length actual)))))
  t)

(defun check-source-view-parser ()
  (let* ((records (dreyeck/hyperdoc/curation::source-records
                   (list (asdf:system-relative-pathname "dreyeck" "dreyeck/tests/hyperdoc-curation-smoke.lisp"))))
         (dispatchers plump-parser:*tag-dispatchers*)
         (text (format nil "λ<!-- <source-of-function>never-evaluate</source-of-function> -->~%
<script>\"<source-of-function>never-evaluate</source-of-function>\"</script>
<SOURCE-OF-FUNCTION data-note='>'>never&#x2d;evaluate</SOURCE-OF-FUNCTION>
<source-of-function>~%never-evaluate~%</source-of-function>
<source-of-function>(never-evaluate)</source-of-function>
<source-of-function>never-evaluate quoted-reference</source-of-function>
<source-of-function>*not-a-page-table*</source-of-function>
<source-of-function>not-in-the-inventory</source-of-function>")))
    (uiop:with-temporary-file (:stream stream :pathname path :type "html")
      (write-string text stream)
      (finish-output stream)
      (multiple-value-bind (dom entries) (dreyeck/hyperdoc/curation::parse-html-source-views path)
        (declare (ignore dom))
        (assert (= 6 (length entries)))
        (loop for (element . evidence) in entries for index from 0
              for span = (getf evidence :region)
              for record = (dreyeck/hyperdoc/curation::source-view-function-record element (find-package :dreyeck/hyperdoc/curation/tests) records)
              do (assert (equal (getf evidence :source) (subseq text (car span) (cdr span))))
                 (if (< index 2)
                     (assert (equal "NEVER-EVALUATE" (getf record :name)))
                     (assert (null record))))
        (assert (not (equal (getf (cdar entries) :region) (getf (cdr (second entries)) :region))))))
    (assert (eq dispatchers plump-parser:*tag-dispatchers*)))
  t)
