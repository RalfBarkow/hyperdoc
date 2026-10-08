;;;; Concrete Source-to-Result Trail Acceptance

(IN-PACKAGE #:DREYECK/WORK/TRAILS-RENDERED-READING/TESTS)

(DEFUN FOLLOWING-VIEW (OBJECT TITLE)
  (LET ((VIEW
         (OR
          (FIND TITLE (VIEWS:ALL-VIEWS OBJECT) :KEY #'VIEWS:VIEW-TITLE :TEST
                #'EQUAL)
          (ERROR "Missing ~A view of ~S" TITLE OBJECT))))
    (VIEWS:VIEW-HTML VIEW)
    (ASSERT
     (NOTANY (LAMBDA (REF) (TYPEP (CDR REF) 'CONDITION))
             (VIEWS:VIEW-REFERENCES VIEW)))
    VIEW))

(DEFUN FOLLOWING-TOPIC (PROJECTION ID)
  (OR
   (FIND ID (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION) :KEY
         #'TM:TOPICMAP-TOPIC-ID-OF :TEST #'EQUAL)
   (ERROR "Missing learning Topic ~A" ID)))

(DEFUN CHECK-TRAIL-FOLLOWING NIL
       (LET*
             ((FOLLOWING (READING:TRAIL-FOLLOWING))
              (CONTEXT (READING::FOLLOWING-CONTEXT FOLLOWING))
              (RAW (READING::FOLLOWING-RAW FOLLOWING))
              (TRAILS (READING::FOLLOWING-TRAILS FOLLOWING))
              (PROJECTION (READING::TRAIL-LEARNING-PROJECTION FOLLOWING))
              (NODES
                     (MAPCAR
                             (LAMBDA (TRAIL)
                                     (AREF
                                           (GETHASH "nodes"
                                                    (GETHASH "graph"
                                                             (READING::TRAIL-ASPECT
                                                                                    TRAIL)))
                                           2))
                             TRAILS))
              (MANIFEST (READING::FOLLOWING-MANIFEST FOLLOWING)))
             (ASSERT (= 2 (LENGTH TRAILS)))
             (ASSERT
                     (EQ RAW
                         (GETHASH "raw"
                                  (READING::PAGE-EVIDENCE
                                                          (READING::FOLLOWING-PAGE
                                                                                   FOLLOWING)))))
             (ASSERT
                     (TYPEP (READING::FOLLOWING-PAGE FOLLOWING)
                            (QUOTE READING::CONTEXT-FEDWIKI-PAGE)))
             (ASSERT
                     (EQUAL "fedwiki:ward.voices.ustawi.wiki"
                            (HYPERBOOK:ID-OF
                                             (HYPERBOOK:HYPERBOOK-OF
                                                                     (READING::FOLLOWING-PAGE
                                                                                              FOLLOWING)))))
             (ASSERT
                     (EQUAL "trails-rendered"
                            (HYPERBOOK:ID-OF
                                             (READING::FOLLOWING-PAGE
                                                                      FOLLOWING))))
             (LOOP FOR TRAIL IN TRAILS FOR INDEX FROM 0 FOR ID IN
                   (QUOTE ("93cd119d6286888a" "fc6c7d06e5bce7d3")) FOR NAMES IN
                   (QUOTE
                          (("Susan Kare" "John Dewey" "Reflective Practice")
                           ("Jean Lave"
                            "Dorothy Smith"
                            "Reflective Practice")))
                   FOR PARAGRAPH = (READING::TRAIL-PARAGRAPH TRAIL) FOR
                   CORRESPONDENCE = (READING::TRAIL-CORRESPONDENCE TRAIL) DO
                   (ASSERT
                           (EQ PARAGRAPH
                               (FIND ID (GETHASH "story" RAW) :KEY
                                     (LAMBDA (ITEM) (GETHASH "id" ITEM)) :TEST
                                     (FUNCTION EQUAL))))
                   (ASSERT (EQUAL NAMES (GETF CORRESPONDENCE :TARGETS)))
                   (ASSERT (GETF CORRESPONDENCE :MATCHES))
                   (ASSERT (NOT (GETF CORRESPONDENCE :IDENTITY-PRESERVED)))
                   (ASSERT
                           (EQ (READING::TRAIL-ASPECT TRAIL)
                               (AREF
                                     (GETHASH "aspects"
                                              (AREF
                                                    (GETHASH "sources"
                                                             (READING::FOLLOWING-BATCH
                                                                                       FOLLOWING))
                                                    0))
                                     INDEX)))
                   (ASSERT
                           (EQ (READING::TRAIL-BEAM-ASPECT TRAIL)
                               (AREF (READING::FOLLOWING-BEAM FOLLOWING)
                                     INDEX)))
                   (ASSERT
                           (NOT
                                (EQ (READING::TRAIL-ASPECT TRAIL)
                                    (READING::TRAIL-BEAM-ASPECT TRAIL))))
                   (LOOP FOR RELATION ACROSS (READING::TRAIL-RELATIONS TRAIL)
                         DO
                         (ASSERT
                                 (MEMBER RELATION
                                         (GETF
                                               (READING::FOLLOWING-STATE
                                                                         FOLLOWING)
                                               :RELATIONS)
                                         :TEST (FUNCTION EQ))))
                   (LET
                        ((REFERENCES
                                     (MAPCAR (FUNCTION CDR)
                                             (VIEWS:VIEW-REFERENCES
                                                                    (FOLLOWING-VIEW
                                                                                    TRAIL
                                                                                    "Trail provenance")))))
                        (DOLIST
                                (ACTUAL
                                        (LIST FOLLOWING PARAGRAPH
                                              (READING::TRAIL-RELATIONS TRAIL)
                                              (READING::TRAIL-ASPECT TRAIL)
                                              (READING::TRAIL-BEAM-ASPECT
                                                                          TRAIL)))
                                (ASSERT
                                        (MEMBER ACTUAL REFERENCES :TEST
                                                (FUNCTION EQ))))))
             (PROGN
                    (PROGN (ASSERT (NOT (EQ (FIRST NODES) (SECOND NODES))))
                           (LET
                                ((OLD-CURSOR
                                             (READING::CONTEXT-CURSOR
                                                                      CONTEXT)))
                                (UNWIND-PROTECT
                                                (PROGN
                                                       (READING::SELECT-CONTEXT-EVENT
                                                                                      CONTEXT
                                                                                      0)
                                                       (ASSERT
                                                               (EQ
                                                                   (READING::FOLLOWING-PAGE
                                                                                            FOLLOWING)
                                                                   (TM:TOPICMAP-TOPIC-OBJECT-OF
                                                                                                (FOLLOWING-TOPIC
                                                                                                                 (READING::TRAIL-LEARNING-PROJECTION
                                                                                                                                                     FOLLOWING)
                                                                                                                 "fedwiki:ward.voices.ustawi.wiki/trails-rendered")))))
                                                (READING::SELECT-CONTEXT-EVENT
                                                                               CONTEXT
                                                                               OLD-CURSOR))))
                    (ASSERT
                            (EQ
                                (TM:TOPICMAP-TOPIC-OBJECT-OF
                                                             (FOLLOWING-TOPIC
                                                                              PROJECTION
                                                                              "learning:svg-node:2"))
                                (FIND "2"
                                      (GETHASH "svgNodes"
                                               (READING::FOLLOWING-RENDER
                                                                          FOLLOWING))
                                      :KEY
                                      (LAMBDA (ENTRY) (GETHASH "title" ENTRY))
                                      :TEST (FUNCTION EQUAL))))
                    (DOLIST
                            (PAIR
                                  (QUOTE
                                         (("learning:batch" "learning:beam")
                                          ("learning:beam"
                                           "learning:composite"))))
                            (LET
                                 ((ASSOCIATION
                                               (FIND-IF
                                                        (LAMBDA (A)
                                                                (AND
                                                                     (EQUAL
                                                                            (FIRST
                                                                                   PAIR)
                                                                            (TM:TOPICMAP-ASSOCIATION-FROM-OF
                                                                                                             A))
                                                                     (EQUAL
                                                                            (SECOND
                                                                                    PAIR)
                                                                            (TM:TOPICMAP-ASSOCIATION-TO-OF
                                                                                                           A))))
                                                        (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                                                                                PROJECTION))))
                                 (ASSERT
                                         (EQ :DERIVED
                                             (GETF
                                                   (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                                                                          ASSOCIATION)
                                                   :WARRANT)))
                                 (ASSERT
                                         (EQ :DIFFERENT-CAPTURES
                                             (GETF
                                                   (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                                                                          ASSOCIATION)
                                                   :IDENTITY))))))
             (LOOP FOR NODE IN NODES FOR INDEX FROM 0 DO
                   (ASSERT
                           (EQ NODE
                               (TM:TOPICMAP-TOPIC-OBJECT-OF
                                                            (FOLLOWING-TOPIC
                                                                             PROJECTION
                                                                             (FORMAT
                                                                                     NIL
                                                                                     "learning:trail:~D:node:2"
                                                                                     INDEX))))))
             (ASSERT
                     (EVERY
                            (LAMBDA (TOPIC)
                                    (LET
                                         ((OBJECT
                                                  (TM:TOPICMAP-TOPIC-OBJECT-OF
                                                                               TOPIC)))
                                         (AND OBJECT (NOT (STRINGP OBJECT)))))
                            (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION)))
             (ASSERT
                     (= (LENGTH (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION))
                        (LENGTH
                                (REMOVE-DUPLICATES
                                                   (TM:TOPICMAP-PROJECTION-TOPICS-OF
                                                                                     PROJECTION)
                                                   :KEY
                                                   (FUNCTION
                                                             TM:TOPICMAP-TOPIC-ID-OF)
                                                   :TEST (FUNCTION EQUAL)))))
             (DOLIST (A (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION))
                     (FOLLOWING-TOPIC PROJECTION
                                      (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
                     (FOLLOWING-TOPIC PROJECTION
                                      (TM:TOPICMAP-ASSOCIATION-TO-OF A))
                     (ASSERT
                             (MEMBER
                                     (GETF
                                           (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF
                                                                                  A)
                                           :WARRANT)
                                     (QUOTE
                                            (:OBSERVED :DERIVED :INFERRED
                                                       :HYPOTHESIZED)))))
             (LOOP FOR SOURCE IN (READING::FOLLOWING-SOURCES FOLLOWING) DO
                   (LET*
                         ((VIEW (FOLLOWING-VIEW SOURCE "Retained source"))
                          (FILE (READING::FRAGMENT-REVISION-FILE SOURCE))
                          (REVISION (DREYECK/GIT:GIT-FILE-COMMIT-OF FILE)))
                         (ASSERT
                                 (MEMBER FILE
                                         (MAPCAR (FUNCTION CDR)
                                                 (VIEWS:VIEW-REFERENCES VIEW))
                                         :TEST (FUNCTION EQ)))
                         (ASSERT
                                 (= 40
                                    (LENGTH
                                            (DREYECK/GIT:GIT-COMMIT-HASH-OF
                                                                            REVISION))))
                         (ASSERT
                                 (MEMBER SOURCE
                                         (DREYECK/GIT:GIT-EVIDENCE-FILE-LOCATIONS-OF
                                                                                     FILE)
                                         :TEST (FUNCTION EQ)))))
             (LET*
                   ((TRAIL (FIRST TRAILS))
                    (NODE (FIRST NODES))
                    (PROPS (GETHASH "props" NODE))
                    (BEFORE (GETHASH "name" PROPS)))
                   (UNWIND-PROTECT
                                   (PROGN
                                          (SETF (GETHASH "name" PROPS)
                                                "Different")
                                          (ASSERT
                                                  (NOT
                                                       (GETF
                                                             (READING::TRAIL-CORRESPONDENCE
                                                                                            TRAIL)
                                                             :MATCHES))))
                                   (SETF (GETHASH "name" PROPS) BEFORE)))
             (LET*
                   ((WORKSPACE (READING::CONTEXT-CURRENT-WORKSPACE CONTEXT))
                    (BEFORE-PROJECTION
                                       (TM:TOPICMAP-WORKSPACE-PROJECTION-OF
                                                                            WORKSPACE))
                    (BEFORE-POINT (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE))
                    (CURSOR (READING::CONTEXT-CURSOR CONTEXT))
                    (MODE (READING::CONTEXT-MODE CONTEXT))
                    (BATCH-BEFORE
                                  (DREYECK/WORK/READING::%COPY-JSON
                                                                    (READING::FOLLOWING-BATCH
                                                                                              FOLLOWING)))
                    (BEAM-BEFORE
                                 (DREYECK/WORK/READING::%COPY-JSON
                                                                   (READING::FOLLOWING-BEAM
                                                                                            FOLLOWING)))
                    (ORIGINAL
                              (SYMBOL-FUNCTION
                                               (QUOTE
                                                      UIOP/RUN-PROGRAM:RUN-PROGRAM)))
                    (NODE-CALLS 0))
                   (UNWIND-PROTECT
                                   (PROGN
                                          (SETF
                                                (SYMBOL-FUNCTION
                                                                 (QUOTE
                                                                        UIOP/RUN-PROGRAM:RUN-PROGRAM))
                                                (LAMBDA (COMMAND &REST ARGS)
                                                        (WHEN
                                                              (AND
                                                                   (CONSP
                                                                          COMMAND)
                                                                   (MEMBER
                                                                           "node"
                                                                           COMMAND
                                                                           :TEST
                                                                           (FUNCTION
                                                                                     EQUAL)))
                                                              (INCF NODE-CALLS)
                                                              (ERROR
                                                                     "Rendering executed the witness."))
                                                        (APPLY ORIGINAL COMMAND
                                                               ARGS)))
                                          (FOLLOWING-VIEW FOLLOWING
                                                          "Follow the trail")
                                          (FOLLOWING-VIEW FOLLOWING
                                                          "Recorded result")
                                          (FOLLOWING-VIEW FOLLOWING
                                                          "Topicmap"))
                                   (SETF
                                         (SYMBOL-FUNCTION
                                                          (QUOTE
                                                                 UIOP/RUN-PROGRAM:RUN-PROGRAM))
                                         ORIGINAL))
                   (ASSERT (ZEROP NODE-CALLS))
                   (ASSERT (= CURSOR (READING::CONTEXT-CURSOR CONTEXT)))
                   (ASSERT (EQ MODE (READING::CONTEXT-MODE CONTEXT)))
                   (ASSERT
                           (EQ BEFORE-PROJECTION
                               (TM:TOPICMAP-WORKSPACE-PROJECTION-OF
                                                                    WORKSPACE)))
                   (ASSERT
                           (EQUAL BEFORE-POINT
                                  (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
                   (ASSERT
                           (DREYECK/WORK/READING::%JSON-EQUAL BATCH-BEFORE
                                                              (READING::FOLLOWING-BATCH
                                                                                        FOLLOWING)))
                   (ASSERT
                           (DREYECK/WORK/READING::%JSON-EQUAL BEAM-BEFORE
                                                              (READING::FOLLOWING-BEAM
                                                                                       FOLLOWING)))
                   (ASSERT (EQ WORKSPACE (READING:TRAIL-WORKSPACE FOLLOWING)))
                   (ASSERT
                           (EQUAL BEFORE-POINT
                                  (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
                   (ASSERT
                           (FOLLOWING-TOPIC
                                            (TM:TOPICMAP-WORKSPACE-PROJECTION-OF
                                                                                 WORKSPACE)
                                            "learning:source")))
             (LET*
                   ((EXECUTION (READING:EXECUTE-TRAIL-WITNESS))
                    (SAVED (READING::FOLLOWING-WITNESS FOLLOWING)))
                   (ASSERT (DREYECK/WORK/READING::%JSON-EQUAL SAVED EXECUTION))
                   (ASSERT
                           (EQ :TRUE
                               (GETHASH "matchesCapturedBatch" EXECUTION)))
                   (ASSERT
                           (EQ :TRUE
                               (GETHASH "matchesRecordedRenderFields"
                                        EXECUTION)))
                   (ASSERT
                           (EQ :FALSE
                               (GETHASH "inputReflectiveNodesIdentical"
                                        EXECUTION)))
                   (ASSERT
                           (EQ :TRUE
                               (GETHASH "outputReflectiveTargetShared"
                                        EXECUTION)))
                   (ASSERT
                           (EVERY
                                  (LAMBDA (ENTRY)
                                          (EQ :FALSE
                                              (GETHASH "sameNodeObject"
                                                       ENTRY)))
                                  (GETHASH "nodeMap" EXECUTION)))
                   (ASSERT
                           (EQUAL (QUOTE (0 1 2 3 4 2))
                                  (MAP (QUOTE LIST)
                                       (LAMBDA (ENTRY)
                                               (GETHASH "outputIndex" ENTRY))
                                       (GETHASH "nodeMap" EXECUTION))))
                   (LOOP FOR CONTROL ACROSS (GETHASH "controls" EXECUTION) DO
                         (ASSERT (= 6 (GETHASH "nodeCount" CONTROL)))
                         (ASSERT (= 4 (GETHASH "relationCount" CONTROL)))))
             (LET ((RESULT (FOLLOWING-VIEW FOLLOWING "Recorded result")))
                  (ASSERT
                          (SEARCH "data:image/png;base64,"
                                  (VIEWS:VIEW-HTML RESULT)))
                  (ASSERT
                          (SEARCH
                                  "complete original SVG outerHTML was not retained"
                                  (VIEWS:VIEW-HTML RESULT))))
             (ASSERT (= 4 (LENGTH (GETHASH "limits" MANIFEST))))
             (LET*
                   ((RENDERING
                               (DREYECK/TOPICMAP/TALA:RUN-TALA
                                                               (DREYECK/TOPICMAP/TALA:PROJECTION-TALA-INPUT
                                                                                                            PROJECTION)))
                    (INPUT
                           (DREYECK/TOPICMAP/TALA:TALA-RENDERING-INPUT
                                                                       RENDERING)))
                   (ASSERT
                           (DREYECK/TOPICMAP/TALA:VALIDATE-TALA-SVG INPUT
                                                                    (DREYECK/TOPICMAP/TALA:TALA-RENDERING-SVG
                                                                                                              RENDERING)))
                   (ASSERT
                           (EQ PROJECTION
                               (DREYECK/TOPICMAP/TALA:TALA-INPUT-PROJECTION
                                                                            INPUT)))
                   (DOLIST
                           (TOPIC
                                  (TM:TOPICMAP-PROJECTION-TOPICS-OF
                                                                    PROJECTION))
                           (ASSERT (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC)))))
       (LET*
             ((BOOK
                    (HYPERBOOK:FIND-HYPERBOOK "dreyeck/work/reading"
                                              :SIGNAL-ERROR? T))
              (READING (RENDER-PAGE BOOK "Following One Recorded Trail"))
              (CODE
                    (HYPERBOOK:FIND-PAGE BOOK "Tracing One Recorded Trail"
                                         :SIGNAL-ERROR? T)))
             (MULTIPLE-VALUE-BIND (PAGE VIEW)
                                  (RENDER-PAGE BOOK
                                               "Trails Rendered public reproduction")
                                  (DECLARE (IGNORE PAGE))
                                  (ASSERT
                                          (MEMBER READING
                                                  (MAPCAR (FUNCTION CDR)
                                                          (VIEWS:VIEW-REFERENCES
                                                                                 VIEW))
                                                  :TEST (FUNCTION EQ))))
             (MULTIPLE-VALUE-BIND (PAGE VIEW)
                                  (RENDER-PAGE BOOK
                                               "Following One Recorded Trail")
                                  (DECLARE (IGNORE PAGE))
                                  (LET
                                       ((REFS
                                              (MAPCAR (FUNCTION CDR)
                                                      (VIEWS:VIEW-REFERENCES
                                                                             VIEW))))
                                       (ASSERT
                                               (MEMBER CODE REFS :TEST
                                                       (FUNCTION EQ)))
                                       (ASSERT
                                               (FIND-IF
                                                        (LAMBDA (O)
                                                                (TYPEP O
                                                                       (QUOTE
                                                                              READING:TRAIL-FOLLOWING)))
                                                        REFS))
                                       (LET
                                            ((ORIGINAL
                                                       (FIND-IF
                                                                (LAMBDA (O)
                                                                        (AND
                                                                             (TYPEP
                                                                                    O
                                                                                    (QUOTE
                                                                                           HYPERBOOK/FEDWIKI::FEDWIKI-PAGE))
                                                                             (EQUAL
                                                                                    "trails-rendered"
                                                                                    (HYPERBOOK:ID-OF
                                                                                                     O))))
                                                                REFS)))
                                            (ASSERT ORIGINAL)
                                            (ASSERT
                                                    (EQUAL
                                                           "fedwiki:ward.voices.ustawi.wiki"
                                                           (HYPERBOOK:ID-OF
                                                                            (HYPERBOOK:HYPERBOOK-OF
                                                                                                    ORIGINAL)))))))
             (HYPERDOC:LOAD-PAGE CODE)
             (ASSERT
                     (FIND "Following One Recorded Trail"
                           (HYPERBOOK:PAGE-LINKS-OF (HYPERBOOK:LINKS-OF CODE))
                           :KEY (FUNCTION HYPERBOOK:TARGET-PAGE-OF) :TEST
                           (FUNCTION EQUAL)))
             (FOLLOWING-VIEW CODE "Source"))
       (FORMAT T
               "~&TRAIL-FOLLOWING-PASS: actual paragraph/relations/aspect/node objects, namespaced identities, derived cross-capture correspondences, explicit witness/control execution, pure rendering, shared Workspace and native source/reading/code navigation.~%")
       T)
