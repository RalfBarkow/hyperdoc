
(COMMON-LISP:DEFPACKAGE :DREYECK/TOPICMAP/CURATION/TESTS
  (:USE :CL)
  (:EXPORT :RUN-TESTS))

(COMMON-LISP:IN-PACKAGE :DREYECK/TOPICMAP/CURATION/TESTS)

(COMMON-LISP:DEFUN DREYECK/TOPICMAP/CURATION/TESTS:RUN-TESTS ()
  (COMMON-LISP:LET* ((DREYECK/TOPICMAP/CURATION/TESTS::TOPICS
                      (COMMON-LISP:LOOP DREYECK/TOPICMAP/CURATION/TESTS::FOR DREYECK/TOPICMAP/CURATION/TESTS::ID DREYECK/TOPICMAP/CURATION/TESTS::IN '("cut"
                                                                                                                                                       "survivor"
                                                                                                                                                       "shared"
                                                                                                                                                       "orphan")
                                        DREYECK/TOPICMAP/CURATION/TESTS::COLLECT (DREYECK/TOPICMAP:MAKE-TOPICMAP-TOPIC
                                                                                  :ID
                                                                                  DREYECK/TOPICMAP/CURATION/TESTS::ID
                                                                                  :TYPE
                                                                                  :FIXTURE
                                                                                  :LABEL
                                                                                  DREYECK/TOPICMAP/CURATION/TESTS::ID
                                                                                  :OBJECT
                                                                                  DREYECK/TOPICMAP/CURATION/TESTS::ID)))
                     (DREYECK/TOPICMAP/CURATION/TESTS::EDGES
                      (COMMON-LISP:LOOP DREYECK/TOPICMAP/CURATION/TESTS::FOR (DREYECK/TOPICMAP/CURATION/TESTS::ID
                                                                              DREYECK/TOPICMAP/CURATION/TESTS::FROM
                                                                              DREYECK/TOPICMAP/CURATION/TESTS::TO) DREYECK/TOPICMAP/CURATION/TESTS::IN '(("a"
                                                                                                                                                          "cut"
                                                                                                                                                          "shared")
                                                                                                                                                         ("b"
                                                                                                                                                          "survivor"
                                                                                                                                                          "shared")
                                                                                                                                                         ("c"
                                                                                                                                                          "cut"
                                                                                                                                                          "orphan"))
                                        DREYECK/TOPICMAP/CURATION/TESTS::COLLECT (DREYECK/TOPICMAP:MAKE-TOPICMAP-ASSOCIATION
                                                                                  :ID
                                                                                  DREYECK/TOPICMAP/CURATION/TESTS::ID
                                                                                  :TYPE
                                                                                  :FIXTURE-USE
                                                                                  :FROM
                                                                                  DREYECK/TOPICMAP/CURATION/TESTS::FROM
                                                                                  :TO
                                                                                  DREYECK/TOPICMAP/CURATION/TESTS::TO
                                                                                  :PROPERTIES
                                                                                  '(:WARRANT
                                                                                    (:FIXTURE
                                                                                     COMMON-LISP:T)))))
                     (DREYECK/TOPICMAP/CURATION/TESTS::PROJECTION
                      (DREYECK/TOPICMAP:MAKE-TOPICMAP-PROJECTION :SOURCE
                                                                 :FIXTURE
                                                                 :TOPICS
                                                                 DREYECK/TOPICMAP/CURATION/TESTS::TOPICS
                                                                 :ASSOCIATIONS
                                                                 DREYECK/TOPICMAP/CURATION/TESTS::EDGES))
                     (DREYECK/TOPICMAP/CURATION/TESTS::REFERENCE
                      (DREYECK/TOPICMAP:MAKE-TOPICMAP-WORKSPACE
                       DREYECK/TOPICMAP/CURATION/TESTS::PROJECTION "cut"))
                     (DREYECK/TOPICMAP/CURATION/TESTS::POLICY
                      (COMMON-LISP:LAMBDA
                          (DREYECK/TOPICMAP/CURATION/TESTS::P
                           DREYECK/TOPICMAP/CURATION/TESTS::TARGET)
                        (COMMON-LISP:DECLARE
                         (COMMON-LISP:IGNORE
                          DREYECK/TOPICMAP/CURATION/TESTS::TARGET))
                        (COMMON-LISP:VALUES COMMON-LISP:NIL COMMON-LISP:NIL
                                            (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                             DREYECK/TOPICMAP/CURATION/TESTS::P))))
                     (DREYECK/TOPICMAP/CURATION/TESTS::IMPACT
                      (DREYECK/TOPICMAP/CURATION:MAKE-IMPACT-WORKSPACE
                       DREYECK/TOPICMAP/CURATION/TESTS::REFERENCE :POLICY
                       DREYECK/TOPICMAP/CURATION/TESTS::POLICY))
                     (DREYECK/TOPICMAP/CURATION/TESTS::SUMMARY
                      (DREYECK/TOPICMAP/CURATION:IMPACT-SUMMARY
                       DREYECK/TOPICMAP/CURATION/TESTS::IMPACT)))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:MEMBER '(:KEEP "shared")
                         DREYECK/TOPICMAP/CURATION/TESTS::SUMMARY :TEST
                         #'COMMON-LISP:EQUAL))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:MEMBER '(:REVIEW-FOR-ORPHANING "orphan")
                         DREYECK/TOPICMAP/CURATION/TESTS::SUMMARY :TEST
                         #'COMMON-LISP:EQUAL))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQUAL "cut"
                        (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                         DREYECK/TOPICMAP/CURATION/TESTS::REFERENCE)))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQ DREYECK/TOPICMAP/CURATION/TESTS::PROJECTION
                     (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
                      DREYECK/TOPICMAP/CURATION/TESTS::REFERENCE)))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQUAL DREYECK/TOPICMAP/CURATION/TESTS::EDGES
                        (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                         DREYECK/TOPICMAP/CURATION/TESTS::PROJECTION)))
    (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-GO-TO
     DREYECK/TOPICMAP/CURATION/TESTS::IMPACT "shared")
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQUAL "shared"
                        (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                         DREYECK/TOPICMAP/CURATION/TESTS::IMPACT)))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:EQUAL "cut"
                        (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                         DREYECK/TOPICMAP/CURATION/TESTS::REFERENCE)))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:HANDLER-CASE
      (COMMON-LISP:PROGN
       (DREYECK/TOPICMAP/CURATION:MAKE-IMPACT-WORKSPACE
        DREYECK/TOPICMAP/CURATION/TESTS::REFERENCE)
       COMMON-LISP:NIL)
      (COMMON-LISP:ERROR COMMON-LISP:NIL COMMON-LISP:T)))
    (COMMON-LISP:ASSERT
     (COMMON-LISP:HANDLER-CASE
      (COMMON-LISP:PROGN
       (DREYECK/TOPICMAP/CURATION:MAKE-IMPACT-WORKSPACE
        DREYECK/TOPICMAP/CURATION/TESTS::REFERENCE :POLICY
        (COMMON-LISP:LAMBDA
            (DREYECK/TOPICMAP/CURATION/TESTS::P
             DREYECK/TOPICMAP/CURATION/TESTS::ID)
          (COMMON-LISP:DECLARE
           (COMMON-LISP:IGNORE DREYECK/TOPICMAP/CURATION/TESTS::P
            DREYECK/TOPICMAP/CURATION/TESTS::ID))
          (COMMON-LISP:VALUES '("missing") COMMON-LISP:NIL COMMON-LISP:NIL)))
       COMMON-LISP:NIL)
      (COMMON-LISP:ERROR COMMON-LISP:NIL COMMON-LISP:T)))
    (COMMON-LISP:FORMAT COMMON-LISP:T
                        "~%CURATION-CORE-PASS: policy-only derivation, KEEP, REVIEW, native navigation.~%")
    COMMON-LISP:T))
