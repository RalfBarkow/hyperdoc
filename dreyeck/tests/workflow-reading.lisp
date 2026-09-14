
(IN-PACKAGE :DREYECK/WORKFLOW/TESTS)

(DEFUN RUN-READING-TESTS NIL
       (LET*
             ((DREYECK/WORKFLOW/TESTS::EXAMPLE
                                               (DREYECK/WORKFLOW/READING::READING-OUTSTANDING-CHANGES))
              (DREYECK/WORKFLOW/TESTS::A
                                         (GETF DREYECK/WORKFLOW/TESTS::EXAMPLE
                                               :A))
              (DREYECK/WORKFLOW/TESTS::B
                                         (GETF DREYECK/WORKFLOW/TESTS::EXAMPLE
                                               :B))
              (DREYECK/WORKFLOW/TESTS::PRIOR
                                             (GETF
                                                   DREYECK/WORKFLOW/TESTS::EXAMPLE
                                                   :AFTER-REDEFINITION)))
             (ASSERT
                     (EQUAL (LIST DREYECK/WORKFLOW/TESTS::A)
                            (GETF DREYECK/WORKFLOW/TESTS::PRIOR :OUTSTANDING)))
             (ASSERT (NULL (GETF DREYECK/WORKFLOW/TESTS::PRIOR :CURRENT)))
             (ASSERT
                     (NOT
                          (GETF
                                (GETF DREYECK/WORKFLOW/TESTS::PRIOR
                                      :OBSERVATION)
                                :RECORDED-DEFINITION-CURRENT-P)))
             (ASSERT
                     (EQUAL
                            (LIST DREYECK/WORKFLOW/TESTS::A
                                  DREYECK/WORKFLOW/TESTS::B)
                            (GETF DREYECK/WORKFLOW/TESTS::EXAMPLE
                                  :OUTSTANDING)))
             (ASSERT
                     (EQUAL (LIST DREYECK/WORKFLOW/TESTS::B)
                            (GETF DREYECK/WORKFLOW/TESTS::EXAMPLE :CURRENT)))
             (ASSERT
                     (NOT
                          (GETF
                                (FIRST
                                       (GETF DREYECK/WORKFLOW/TESTS::EXAMPLE
                                             :OBSERVATIONS))
                                :RECORDED-DEFINITION-CURRENT-P)))
             (ASSERT
                     (GETF
                           (SECOND
                                   (GETF DREYECK/WORKFLOW/TESTS::EXAMPLE
                                         :OBSERVATIONS))
                           :RECORDED-DEFINITION-CURRENT-P)))
       (LET*
             ((BOOK
                    (HYPERBOOK:FIND-HYPERBOOK "dreyeck/workflow/reading"
                                              :SIGNAL-ERROR? T))
              (PATH
                    (MERGE-PATHNAMES "dreyeck/src/workflow-reading.lisp"
                                     (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY
                                                                          "dreyeck/workflow")))
              (BEFORE (UIOP/STREAM:READ-FILE-STRING PATH))
              (FORMS (DREYECK/WORKFLOW:SOURCE-FORMS PATH))
              (EXAMPLES
                        (LOOP FOR F IN FORMS WHEN
                              (EQ (CAR F) (QUOTE HYPERDOC:DEFEXAMPLE)) COLLECT
                              (SECOND F))))
             (ASSERT (= 12 (LENGTH EXAMPLES)))
             (HYPERDOC::ENSURE-PAGES-LOADED BOOK)
             (LET*
                   ((PAGE
                          (HYPERBOOK:FIND-PAGE BOOK "Reconstructing Workflow"
                                               :SIGNAL-ERROR? T))
                    (VIEW
                          (FIND "Content" (HTML-INSPECTOR-VIEWS:ALL-VIEWS PAGE)
                                :KEY (FUNCTION HTML-INSPECTOR-VIEWS:VIEW-TITLE)
                                :TEST (FUNCTION STRING=))))
                   (ASSERT VIEW) (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW)
                   (LET
                        ((WIDGETS
                                  (MAPCAR (FUNCTION CDR)
                                          (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES
                                                                                VIEW)))
                         (CLICKS 0))
                        (ASSERT (= 12 (LENGTH WIDGETS)))
                        (DOLIST (WIDGET WIDGETS)
                                (HTML-INSPECTOR-VIEWS:VIEW-HTML WIDGET)
                                (LET
                                     ((ACTIONS
                                               (REMOVE-IF-NOT
                                                              (LAMBDA (R)
                                                                      (TYPEP
                                                                             (CDR
                                                                                  R)
                                                                             (QUOTE
                                                                                    HTML-INSPECTOR-VIEWS:THUNK)))
                                                              (HTML-INSPECTOR-VIEWS:VIEW-REFERENCES
                                                                                                    WIDGET))))
                                     (ASSERT (= 1 (LENGTH ACTIONS)))
                                     (ASSERT
                                             (HTML-INSPECTOR-VIEWS:EVAL-THUNK
                                                                              (CDAR
                                                                                    ACTIONS)))
                                     (INCF CLICKS)))
                        (ASSERT (= CLICKS 12))))
             (ASSERT (STRING= BEFORE (UIOP/STREAM:READ-FILE-STRING PATH)))
             (UNLESS (UIOP/OS:GETENV "HYPERDOC_WORKFLOW_EDITOR_SOURCE")
                     (ASSERT (NOT (FIND-PACKAGE :DREYECK/WORKFLOW/AUTHORING))))
             (LET ((WORKSPACE (DREYECK/WORKFLOW/READING::READING-WORKSPACE)))
                  (ASSERT
                          (TYPEP WORKSPACE
                                 (QUOTE DREYECK/TOPICMAP:TOPICMAP-WORKSPACE)))
                  (LET
                       ((PROJECTION
                                    (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-OF
                                                                             WORKSPACE)))
                       (ASSERT
                               (= 5
                                  (LENGTH
                                          (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-TOPICS-OF
                                                                                          PROJECTION))))
                       (ASSERT
                               (= 4
                                  (LENGTH
                                          (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                                                                                PROJECTION))))))
             (DOLIST (EVIDENCE (DREYECK/WORKFLOW/READING::READING-MEDLEY))
                     (ASSERT (EQ :SOURCE-OBSERVED (GETF EVIDENCE :STATUS)))
                     (ASSERT
                             (EQUAL "46d6906bdb1f92c49e19b128459ca223289717ed"
                                    (GETF EVIDENCE :BLOB))))
             (FORMAT T
                     "Workflow reading passed: 12 reconstructed source transclusions and executed thunks; explicit authoring boundary.~%")
             (WHEN
                   (EQ :AVAILABLE
                       (GETF (DREYECK/TOPICMAP/TALA:TALA-DEPENDENCY-STATUS)
                             :STATUS))
                   (ASDF/OPERATE:LOAD-SYSTEM
                                             "dreyeck/topicmap/tala/reading/tests")
                   (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/TOPICMAP/TESTS
                                             :CHECK-TALA-COMPARISON-NAVIGATION
                                             (DREYECK/WORKFLOW/READING::READING-LAYOUT-COMPARISON)))
             T))
