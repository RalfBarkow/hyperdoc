
(COMMON-LISP:IN-PACKAGE :DREYECK/TOPICMAP/CURATION)

(COMMON-LISP:DEFUN DREYECK/TOPICMAP/CURATION::PROJECTION-OF
                   (DREYECK/TOPICMAP/CURATION::REFERENCE)
  (COMMON-LISP:ETYPECASE DREYECK/TOPICMAP/CURATION::REFERENCE
    (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE
     (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-PROJECTION-OF
      DREYECK/TOPICMAP/CURATION::REFERENCE))
    (DREYECK/TOPICMAP:TOPICMAP-PROJECTION
     DREYECK/TOPICMAP/CURATION::REFERENCE)))

(COMMON-LISP:DEFUN DREYECK/TOPICMAP/CURATION:REFERENCE-SUMMARY
                   (DREYECK/TOPICMAP/CURATION::REFERENCE)
  (COMMON-LISP:LET ((DREYECK/TOPICMAP/CURATION::PROJECTION
                     (DREYECK/TOPICMAP/CURATION::PROJECTION-OF
                      DREYECK/TOPICMAP/CURATION::REFERENCE)))
    (COMMON-LISP:MAPCAR
     (COMMON-LISP:LAMBDA (DREYECK/TOPICMAP/CURATION::EDGE)
       (COMMON-LISP:LIST
        (DREYECK/TOPICMAP:TOPICMAP-TOPIC-LABEL-OF
         (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-TOPIC-BY-ID
          DREYECK/TOPICMAP/CURATION::PROJECTION
          (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
           DREYECK/TOPICMAP/CURATION::EDGE)))
        (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
         DREYECK/TOPICMAP/CURATION::EDGE)
        (DREYECK/TOPICMAP:TOPICMAP-TOPIC-LABEL-OF
         (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-TOPIC-BY-ID
          DREYECK/TOPICMAP/CURATION::PROJECTION
          (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
           DREYECK/TOPICMAP/CURATION::EDGE)))))
     (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
      DREYECK/TOPICMAP/CURATION::PROJECTION))))

(COMMON-LISP:DEFUN DREYECK/TOPICMAP/CURATION:IMPACT-SUMMARY
                   (DREYECK/TOPICMAP/CURATION::REFERENCE)
  (COMMON-LISP:MAPCAR
   (COMMON-LISP:LAMBDA (DREYECK/TOPICMAP/CURATION::ROW)
     (COMMON-LISP:LIST (COMMON-LISP:SECOND DREYECK/TOPICMAP/CURATION::ROW)
                       (COMMON-LISP:THIRD DREYECK/TOPICMAP/CURATION::ROW)))
   (DREYECK/TOPICMAP/CURATION:REFERENCE-SUMMARY
    DREYECK/TOPICMAP/CURATION::REFERENCE)))

(COMMON-LISP:DEFUN DREYECK/TOPICMAP/CURATION:MAKE-IMPACT-WORKSPACE
                   (DREYECK/TOPICMAP/CURATION::REFERENCE
                    COMMON-LISP:&KEY
                    (DREYECK/TOPICMAP/CURATION::OPERATION :REMOVE)
                    DREYECK/TOPICMAP/CURATION::TARGET
                    DREYECK/TOPICMAP/CURATION::POLICY)
  "POLICY receives (projection target) and returns cut IDs, findings and retention
edges. A finding is (:target ID :category KEYWORD :rule DESIGNATOR :edges LIST).
All evidence edges must belong to the reference and have a warrant. No mutation
or authorization is performed. Domain relation names belong exclusively to POLICY."
  (COMMON-LISP:UNLESS
      (COMMON-LISP:EQ DREYECK/TOPICMAP/CURATION::OPERATION :REMOVE)
    (COMMON-LISP:ERROR "Unsupported operation ~S."
                       DREYECK/TOPICMAP/CURATION::OPERATION))
  (COMMON-LISP:UNLESS DREYECK/TOPICMAP/CURATION::POLICY
    (COMMON-LISP:ERROR "An explicit impact policy is required."))
  (COMMON-LISP:LET* ((DREYECK/TOPICMAP/CURATION::PROJECTION
                      (DREYECK/TOPICMAP/CURATION::PROJECTION-OF
                       DREYECK/TOPICMAP/CURATION::REFERENCE))
                     (DREYECK/TOPICMAP/CURATION::POINT
                      (COMMON-LISP:OR DREYECK/TOPICMAP/CURATION::TARGET
                                      (COMMON-LISP:AND
                                       (COMMON-LISP:TYPEP
                                        DREYECK/TOPICMAP/CURATION::REFERENCE
                                        'DREYECK/TOPICMAP:TOPICMAP-WORKSPACE)
                                       (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-POINT-OF
                                        DREYECK/TOPICMAP/CURATION::REFERENCE))))
                     (DREYECK/TOPICMAP/CURATION::EDGES
                      (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                       DREYECK/TOPICMAP/CURATION::PROJECTION))
                     (DREYECK/TOPICMAP/CURATION::IMPACTS COMMON-LISP:NIL))
    (COMMON-LISP:LABELS ((DREYECK/TOPICMAP/CURATION::TOPIC
                             (DREYECK/TOPICMAP/CURATION::ID)
                           (COMMON-LISP:OR
                            (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-TOPIC-BY-ID
                             DREYECK/TOPICMAP/CURATION::PROJECTION
                             DREYECK/TOPICMAP/CURATION::ID)
                            (COMMON-LISP:ERROR "Unknown impact topic ~S."
                                               DREYECK/TOPICMAP/CURATION::ID)))
                         (DREYECK/TOPICMAP/CURATION::EDGE-IDS
                             (DREYECK/TOPICMAP/CURATION::EVIDENCE)
                           (COMMON-LISP:MAPCAR
                            (COMMON-LISP:LAMBDA
                                (DREYECK/TOPICMAP/CURATION::EDGE)
                              (COMMON-LISP:UNLESS
                                  (COMMON-LISP:AND
                                   (COMMON-LISP:MEMBER
                                    DREYECK/TOPICMAP/CURATION::EDGE
                                    DREYECK/TOPICMAP/CURATION::EDGES :TEST
                                    #'COMMON-LISP:EQ)
                                   (COMMON-LISP:GETF
                                    (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                     DREYECK/TOPICMAP/CURATION::EDGE)
                                    :WARRANT))
                                (COMMON-LISP:ERROR
                                 "Impact evidence is not a warranted reference edge."))
                              (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF
                               DREYECK/TOPICMAP/CURATION::EDGE))
                            DREYECK/TOPICMAP/CURATION::EVIDENCE))
                         (DREYECK/TOPICMAP/CURATION::EMIT
                             (DREYECK/TOPICMAP/CURATION::CATEGORY
                              DREYECK/TOPICMAP/CURATION::AFFECTED
                              DREYECK/TOPICMAP/CURATION::RULE
                              DREYECK/TOPICMAP/CURATION::EVIDENCE
                              COMMON-LISP:&OPTIONAL
                              DREYECK/TOPICMAP/CURATION::SURVIVORS)
                           (DREYECK/TOPICMAP/CURATION::TOPIC
                            DREYECK/TOPICMAP/CURATION::AFFECTED)
                           (COMMON-LISP:PUSH
                            (DREYECK/TOPICMAP:MAKE-TOPICMAP-ASSOCIATION :ID
                                                                        (COMMON-LISP:FORMAT
                                                                         COMMON-LISP:NIL
                                                                         "impact:~D"
                                                                         (COMMON-LISP:LENGTH
                                                                          DREYECK/TOPICMAP/CURATION::IMPACTS))
                                                                        :TYPE
                                                                        DREYECK/TOPICMAP/CURATION::CATEGORY
                                                                        :FROM
                                                                        DREYECK/TOPICMAP/CURATION::POINT
                                                                        :TO
                                                                        DREYECK/TOPICMAP/CURATION::AFFECTED
                                                                        :PROPERTIES
                                                                        (COMMON-LISP:LIST
                                                                         :EPISTEMIC-STATUS
                                                                         :MECHANICALLY-DERIVED
                                                                         :WARRANT
                                                                         (COMMON-LISP:LIST
                                                                          :RULE
                                                                          DREYECK/TOPICMAP/CURATION::RULE
                                                                          :REFERENCE-EDGES
                                                                          (DREYECK/TOPICMAP/CURATION::EDGE-IDS
                                                                           DREYECK/TOPICMAP/CURATION::EVIDENCE)
                                                                          :SURVIVING-RETENTION-EDGES
                                                                          (DREYECK/TOPICMAP/CURATION::EDGE-IDS
                                                                           DREYECK/TOPICMAP/CURATION::SURVIVORS))))
                            DREYECK/TOPICMAP/CURATION::IMPACTS)))
      (DREYECK/TOPICMAP/CURATION::TOPIC DREYECK/TOPICMAP/CURATION::POINT)
      (COMMON-LISP:MULTIPLE-VALUE-BIND
          (DREYECK/TOPICMAP/CURATION::CUT DREYECK/TOPICMAP/CURATION::FINDINGS
           DREYECK/TOPICMAP/CURATION::RETENTION)
          (COMMON-LISP:FUNCALL DREYECK/TOPICMAP/CURATION::POLICY
                               DREYECK/TOPICMAP/CURATION::PROJECTION
                               DREYECK/TOPICMAP/CURATION::POINT)
        (COMMON-LISP:SETF DREYECK/TOPICMAP/CURATION::CUT
                            (COMMON-LISP:REMOVE-DUPLICATES
                             (COMMON-LISP:CONS DREYECK/TOPICMAP/CURATION::POINT
                                               DREYECK/TOPICMAP/CURATION::CUT)
                             :TEST #'COMMON-LISP:EQUAL))
        (COMMON-LISP:MAPC #'DREYECK/TOPICMAP/CURATION::TOPIC
                          DREYECK/TOPICMAP/CURATION::CUT)
        (DREYECK/TOPICMAP/CURATION::EDGE-IDS
         DREYECK/TOPICMAP/CURATION::RETENTION)
        (DREYECK/TOPICMAP/CURATION::EMIT :REMOVE
         DREYECK/TOPICMAP/CURATION::POINT :EXPLICIT-HYPOTHETICAL-REQUEST
         COMMON-LISP:NIL)
        (COMMON-LISP:DOLIST
            (DREYECK/TOPICMAP/CURATION::FINDING
             DREYECK/TOPICMAP/CURATION::FINDINGS)
          (COMMON-LISP:UNLESS
              (COMMON-LISP:AND
               (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING :RULE)
               (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING :EDGES)
               (COMMON-LISP:KEYWORDP
                (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING
                                  :CATEGORY))
               (COMMON-LISP:NOT
                (COMMON-LISP:MEMBER
                 (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING
                                   :CATEGORY)
                 '(:KEEP :REVIEW-FOR-ORPHANING :REMOVE))))
            (COMMON-LISP:ERROR "Incomplete or reserved policy finding ~S."
                               DREYECK/TOPICMAP/CURATION::FINDING))
          (DREYECK/TOPICMAP/CURATION::EMIT
           (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING :CATEGORY)
           (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING :TARGET)
           (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING :RULE)
           (COMMON-LISP:GETF DREYECK/TOPICMAP/CURATION::FINDING :EDGES)))
        (COMMON-LISP:DOLIST
            (DREYECK/TOPICMAP/CURATION::AFFECTED
             (COMMON-LISP:REMOVE-DUPLICATES
              (COMMON-LISP:LOOP DREYECK/TOPICMAP/CURATION::FOR DREYECK/TOPICMAP/CURATION::EDGE DREYECK/TOPICMAP/CURATION::IN DREYECK/TOPICMAP/CURATION::RETENTION
                                COMMON-LISP:WHEN (COMMON-LISP:AND
                                                  (COMMON-LISP:MEMBER
                                                   (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                                    DREYECK/TOPICMAP/CURATION::EDGE)
                                                   DREYECK/TOPICMAP/CURATION::CUT
                                                   :TEST #'COMMON-LISP:EQUAL)
                                                  (COMMON-LISP:NOT
                                                   (COMMON-LISP:MEMBER
                                                    (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                                     DREYECK/TOPICMAP/CURATION::EDGE)
                                                    DREYECK/TOPICMAP/CURATION::CUT
                                                    :TEST
                                                    #'COMMON-LISP:EQUAL)))
                                DREYECK/TOPICMAP/CURATION::COLLECT (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                                                    DREYECK/TOPICMAP/CURATION::EDGE))
              :TEST #'COMMON-LISP:EQUAL))
          (COMMON-LISP:LET ((DREYECK/TOPICMAP/CURATION::LOST COMMON-LISP:NIL)
                            (DREYECK/TOPICMAP/CURATION::SURVIVING
                             COMMON-LISP:NIL))
            (COMMON-LISP:DOLIST
                (DREYECK/TOPICMAP/CURATION::EDGE
                 DREYECK/TOPICMAP/CURATION::RETENTION)
              (COMMON-LISP:WHEN
                  (COMMON-LISP:EQUAL DREYECK/TOPICMAP/CURATION::AFFECTED
                                     (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                      DREYECK/TOPICMAP/CURATION::EDGE))
                (COMMON-LISP:IF (COMMON-LISP:MEMBER
                                 (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                  DREYECK/TOPICMAP/CURATION::EDGE)
                                 DREYECK/TOPICMAP/CURATION::CUT :TEST
                                 #'COMMON-LISP:EQUAL)
                                (COMMON-LISP:PUSH
                                 DREYECK/TOPICMAP/CURATION::EDGE
                                 DREYECK/TOPICMAP/CURATION::LOST)
                                (COMMON-LISP:PUSH
                                 DREYECK/TOPICMAP/CURATION::EDGE
                                 DREYECK/TOPICMAP/CURATION::SURVIVING))))
            (DREYECK/TOPICMAP/CURATION::EMIT
             (COMMON-LISP:IF DREYECK/TOPICMAP/CURATION::SURVIVING
                             :KEEP
                             :REVIEW-FOR-ORPHANING)
             DREYECK/TOPICMAP/CURATION::AFFECTED
             :RETENTION-AFTER-HYPOTHETICAL-CUT DREYECK/TOPICMAP/CURATION::LOST
             DREYECK/TOPICMAP/CURATION::SURVIVING)))
        (DREYECK/TOPICMAP:MAKE-TOPICMAP-WORKSPACE
         (DREYECK/TOPICMAP:MAKE-TOPICMAP-PROJECTION :SOURCE
                                                    (COMMON-LISP:LIST :KIND
                                                                      :CURATION-IMPACT
                                                                      :REFERENCE
                                                                      DREYECK/TOPICMAP/CURATION::PROJECTION
                                                                      :OPERATION
                                                                      DREYECK/TOPICMAP/CURATION::OPERATION
                                                                      :TARGET
                                                                      DREYECK/TOPICMAP/CURATION::POINT
                                                                      :HYPOTHETICAL
                                                                      COMMON-LISP:T
                                                                      :AUTHORIZATION
                                                                      :NONE
                                                                      :CUT-TOPIC-IDS
                                                                      DREYECK/TOPICMAP/CURATION::CUT)
                                                    :TOPICS
                                                    (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-TOPICS-OF
                                                     DREYECK/TOPICMAP/CURATION::PROJECTION)
                                                    :ASSOCIATIONS
                                                    (COMMON-LISP:NREVERSE
                                                     DREYECK/TOPICMAP/CURATION::IMPACTS))
         DREYECK/TOPICMAP/CURATION::POINT)))))
