
(IN-PACKAGE :DREYECK/WORKFLOW/TESTS)

(DEFUN RUN-CHANGE-VERIFICATION-TESTS (ENVIRONMENT SYSTEM SOURCE)
       (LET
            ((LOG (MAKE-INSTANCE (QUOTE WF:CHANGE-LOG)))
             (NAME (QUOTE COMMON-LISP-USER::WORKFLOW-PROOF-ANSWER)))
            (SETF (SYMBOL-FUNCTION NAME) (COMPILE NIL (QUOTE (LAMBDA NIL 43))))
            (LET ((A (WF:REGISTER-CHANGE NAME LOG)))
                 (SETF (SYMBOL-FUNCTION NAME)
                       (COMPILE NIL (QUOTE (LAMBDA NIL 44))))
                 (ASSERT (EQUAL (LIST A) (WF:OUTSTANDING-CHANGES LOG)))
                 (ASSERT (NULL (WF:CURRENT-OUTSTANDING-CHANGES LOG)))
                 (LET*
                       ((B (WF:REGISTER-CHANGE NAME LOG))
                        (BEFORE
                                (MAPCAR (FUNCTION WF:OBSERVE-CHANGE)
                                        (WF:OUTSTANDING-CHANGES LOG))))
                       (ASSERT (EQ B (WF:REGISTER-CHANGE NAME LOG)))
                       (ASSERT (EQUAL (LIST A B) (WF:OUTSTANDING-CHANGES LOG)))
                       (ASSERT
                               (EQUAL (LIST B)
                                      (WF:CURRENT-OUTSTANDING-CHANGES LOG)))
                       (FLET
                             ((PLAN (VALUE)
                                    (WF:PLAN-DEFINITION SYSTEM "answer" NAME
                                                        (LIST (QUOTE DEFUN)
                                                              NAME NIL VALUE)
                                                        (QUOTE
                                                               (=
                                                                  (COMMON-LISP-USER::WORKFLOW-PROOF-ANSWER)
                                                                  44)))))
                             (LET
                                  ((INITIAL
                                            (UIOP/STREAM:READ-FILE-STRING
                                                                          SOURCE))
                                   (REQUEST (PLAN 44)))
                                  (MUST-FAIL
                                             (LAMBDA NIL
                                                     (WF:PERSIST-IN REQUEST
                                                                    ENVIRONMENT
                                                                    :CHANGE
                                                                    A)))
                                  (MUST-FAIL
                                             (LAMBDA NIL
                                                     (WF:VERIFY-CHANGE B
                                                                       REQUEST
                                                                       ENVIRONMENT)))
                                  (ASSERT
                                          (STRING= INITIAL
                                                   (UIOP/STREAM:READ-FILE-STRING
                                                                                 SOURCE)))
                                  (ASSERT
                                          (EQ :UNVERIFIED
                                              (WF:CHANGE-RECONSTRUCTION-STATUS
                                                                               B))))
                             (PROGN
                                    (ASSERT
                                            (HANDLER-CASE
                                                          (PROGN
                                                                 (WF:PERSIST-IN
                                                                                (PLAN
                                                                                      45)
                                                                                ENVIRONMENT
                                                                                :CHANGE
                                                                                B)
                                                                 NIL)
                                                          (ERROR (CONDITION)
                                                                 (SEARCH
                                                                         "Fresh reconstruction exited"
                                                                         (PRINC-TO-STRING
                                                                                          CONDITION)))))
                                    (ASSERT
                                            (DREYECK/WORKFLOW:FORM-EQUAL
                                                                         (LIST
                                                                               (QUOTE
                                                                                      DEFUN)
                                                                               NAME
                                                                               NIL
                                                                               45)
                                                                         (FIND
                                                                               (LIST
                                                                                     :DEFINITION
                                                                                     NAME)
                                                                               (DREYECK/WORKFLOW:SOURCE-FORMS
                                                                                                              SOURCE)
                                                                               :KEY
                                                                               (FUNCTION
                                                                                         DREYECK/WORKFLOW:FORM-KEY)
                                                                               :TEST
                                                                               (FUNCTION
                                                                                         EQUAL)))))
                             (ASSERT
                                     (EQUAL (LIST A B)
                                            (WF:OUTSTANDING-CHANGES LOG)))
                             (ASSERT
                                     (EQUAL (LIST B)
                                            (WF:CURRENT-OUTSTANDING-CHANGES
                                                                            LOG)))
                             (ASSERT (NULL (WF:CHANGE-RECONSTRUCTION-PROOF B)))
                             (LET*
                                   ((REQUEST (PLAN 44))
                                    (PROOF
                                           (WF:PERSIST-IN REQUEST ENVIRONMENT
                                                          :CHANGE B)))
                                   (ASSERT (EQ B (GETF PROOF :CHANGE)))
                                   (ASSERT
                                           (EQ (WF:CHANGE-FUNCTION B)
                                               (GETF PROOF :FUNCTION)))
                                   (ASSERT
                                           (SEARCH
                                                   "WORKFLOW-FRESH-EXPECTATION-PASSED"
                                                   (GETF PROOF :FRESH-PROOF)))
                                   (ASSERT
                                           (EQ :VERIFIED
                                               (GETF (WF:OBSERVE-CHANGE B)
                                                     :RECONSTRUCTION)))
                                   (ASSERT
                                           (EQ :UNVERIFIED
                                               (GETF (WF:OBSERVE-CHANGE A)
                                                     :RECONSTRUCTION)))
                                   (ASSERT
                                           (EQUAL (LIST A)
                                                  (WF:OUTSTANDING-CHANGES
                                                                          LOG)))
                                   (ASSERT
                                           (NULL
                                                 (WF:CURRENT-OUTSTANDING-CHANGES
                                                                                 LOG)))
                                   (ASSERT
                                           (EQ B
                                               (WF:REGISTER-CHANGE NAME LOG)))
                                   (LET
                                        ((BYTES
                                                (UIOP/STREAM:READ-FILE-STRING
                                                                              SOURCE)))
                                        (ASSERT
                                                (EQ :VERIFIED
                                                    (GETF
                                                          (WF:VERIFY-CHANGE B
                                                                            REQUEST
                                                                            ENVIRONMENT)
                                                          :STATUS)))
                                        (ASSERT
                                                (STRING= BYTES
                                                         (UIOP/STREAM:READ-FILE-STRING
                                                                                       SOURCE))))
                                   (FORMAT T
                                           "Change verification passed: A superseded, B current, failed fresh proof stays open, successful B proof closes only B.~%")
                                   (LIST :STATUS :VERIFIED :LOG LOG :BEFORE
                                         BEFORE :A A :B B :AFTER
                                         (MAPCAR (FUNCTION WF:OBSERVE-CHANGE)
                                                 (LIST A B))
                                         :OUTSTANDING
                                         (WF:OUTSTANDING-CHANGES LOG) :CURRENT
                                         (WF:CURRENT-OUTSTANDING-CHANGES LOG)
                                         :PROOF
                                         (WF:CHANGE-RECONSTRUCTION-PROOF
                                                                         B))))))))

(COMMON-LISP:DEFUN DREYECK/WORKFLOW/TESTS:RUN-AUTHORING-TESTS NIL
                   (COMMON-LISP:LET*
                                     ((DREYECK/WORKFLOW/TESTS::ROOT
                                                                    (COMMON-LISP:MERGE-PATHNAMES
                                                                                                 (COMMON-LISP:FORMAT
                                                                                                                     NIL
                                                                                                                     "workflow-proof-~A/"
                                                                                                                     (COMMON-LISP:GENSYM))
                                                                                                 (UIOP/STREAM:TEMPORARY-DIRECTORY)))
                                      (DREYECK/WORKFLOW/TESTS::ASD
                                                                   (COMMON-LISP:MERGE-PATHNAMES
                                                                                                "workflow-proof.asd"
                                                                                                DREYECK/WORKFLOW/TESTS::ROOT))
                                      (DREYECK/WORKFLOW/TESTS::SOURCE
                                                                      (COMMON-LISP:MERGE-PATHNAMES
                                                                                                   "answer.lisp"
                                                                                                   DREYECK/WORKFLOW/TESTS::ROOT))
                                      (DREYECK/WORKFLOW/TESTS::ENVIRONMENT
                                                                           (DREYECK/WORKFLOW/AUTHORING:MAKE-AUTHORING-ENVIRONMENT))
                                      (DREYECK/WORKFLOW/TESTS::SYSTEM
                                                                      "workflow-proof")
                                      (DREYECK/WORKFLOW/TESTS::TRACKING NIL))
                                     (COMMON-LISP:ENSURE-DIRECTORIES-EXIST
                                                                           DREYECK/WORKFLOW/TESTS::SOURCE)
                                     (COMMON-LISP:UNWIND-PROTECT
                                                                 (COMMON-LISP:PROGN
                                                                                    (HTML-INSPECTOR-VIEWS/STANDARD::MATERIALIZE-LISP-SOURCE
                                                                                                                                            DREYECK/WORKFLOW/TESTS::ASD
                                                                                                                                            (QUOTE
                                                                                                                                                   ((ASDF/PARSE-DEFSYSTEM:DEFSYSTEM
                                                                                                                                                                                    "workflow-proof"
                                                                                                                                                                                    :COMPONENTS
                                                                                                                                                                                    ((:FILE
                                                                                                                                                                                            "answer"))
                                                                                                                                                                                    :DEPENDS-ON
                                                                                                                                                                                    ("dreyeck/workflow")))))
                                                                                    (HTML-INSPECTOR-VIEWS/STANDARD::MATERIALIZE-LISP-SOURCE
                                                                                                                                            DREYECK/WORKFLOW/TESTS::SOURCE
                                                                                                                                            (QUOTE
                                                                                                                                                   ((COMMON-LISP:IN-PACKAGE
                                                                                                                                                                            :CL-USER)
                                                                                                                                                    (COMMON-LISP:DEFUN
                                                                                                                                                                       COMMON-LISP-USER::WORKFLOW-PROOF-ANSWER
                                                                                                                                                                       NIL
                                                                                                                                                                       42)
                                                                                                                                                    (COMMON-LISP:DEFUN
                                                                                                                                                                       COMMON-LISP-USER::WORKFLOW-PROOF-NEIGHBOR
                                                                                                                                                                       NIL
                                                                                                                                                                       :UNCHANGED))))
                                                                                    (ASDF/FIND-SYSTEM:LOAD-ASD
                                                                                                               DREYECK/WORKFLOW/TESTS::ASD)
                                                                                    (COMMON-LISP:PROGN
                                                                                                       (ASDF/OPERATE:LOAD-SYSTEM
                                                                                                                                 DREYECK/WORKFLOW/TESTS::SYSTEM)
                                                                                                       (COMMON-LISP:SETF
                                                                                                                         DREYECK/WORKFLOW/TESTS::TRACKING
                                                                                                                         (DREYECK/WORKFLOW/TESTS::RUN-CHANGE-VERIFICATION-TESTS
                                                                                                                                                                                DREYECK/WORKFLOW/TESTS::ENVIRONMENT
                                                                                                                                                                                DREYECK/WORKFLOW/TESTS::SYSTEM
                                                                                                                                                                                DREYECK/WORKFLOW/TESTS::SOURCE)))
                                                                                    (COMMON-LISP:FLET
                                                                                                      ((DREYECK/WORKFLOW/TESTS::PLAN
                                                                                                                                     (DREYECK/WORKFLOW/TESTS::VALUE
                                                                                                                                                                    DREYECK/WORKFLOW/TESTS::EXPECTED)
                                                                                                                                     (DREYECK/WORKFLOW:PLAN-DEFINITION
                                                                                                                                                                       DREYECK/WORKFLOW/TESTS::SYSTEM
                                                                                                                                                                       "answer"
                                                                                                                                                                       (QUOTE
                                                                                                                                                                              COMMON-LISP-USER::WORKFLOW-PROOF-ANSWER)
                                                                                                                                                                       (COMMON-LISP:LIST
                                                                                                                                                                                         (QUOTE
                                                                                                                                                                                                COMMON-LISP:DEFUN)
                                                                                                                                                                                         (QUOTE
                                                                                                                                                                                                COMMON-LISP-USER::WORKFLOW-PROOF-ANSWER)
                                                                                                                                                                                         NIL
                                                                                                                                                                                         DREYECK/WORKFLOW/TESTS::VALUE)
                                                                                                                                                                       (COMMON-LISP:LIST
                                                                                                                                                                                         (QUOTE
                                                                                                                                                                                                COMMON-LISP:AND)
                                                                                                                                                                                         (QUOTE
                                                                                                                                                                                                (COMMON-LISP:NOT
                                                                                                                                                                                                                 (UIOP/OS:GETENV
                                                                                                                                                                                                                                 "HYPERDOC_WORKFLOW_EDITOR_SOURCE")))
                                                                                                                                                                                         (QUOTE
                                                                                                                                                                                                (COMMON-LISP:NOT
                                                                                                                                                                                                                 (COMMON-LISP:FBOUNDP
                                                                                                                                                                                                                                      (COMMON-LISP:FIND-SYMBOL
                                                                                                                                                                                                                                                               "REPLACE-CST-EXPRESSION-IN-FILE"
                                                                                                                                                                                                                                                               :HTML-INSPECTOR-VIEWS/STANDARD))))
                                                                                                                                                                                         (COMMON-LISP:LIST
                                                                                                                                                                                                           (QUOTE
                                                                                                                                                                                                                  COMMON-LISP:=)
                                                                                                                                                                                                           (COMMON-LISP:LIST
                                                                                                                                                                                                                             (QUOTE
                                                                                                                                                                                                                                    COMMON-LISP-USER::WORKFLOW-PROOF-ANSWER))
                                                                                                                                                                                                           DREYECK/WORKFLOW/TESTS::EXPECTED)))))
                                                                                                      (COMMON-LISP:LET*
                                                                                                                        ((DREYECK/WORKFLOW/TESTS::CHANGE
                                                                                                                                                         (DREYECK/WORKFLOW/TESTS::PLAN
                                                                                                                                                                                       43
                                                                                                                                                                                       43))
                                                                                                                         (DREYECK/WORKFLOW/TESTS::NEIGHBOR
                                                                                                                                                           (COMMON-LISP:THIRD
                                                                                                                                                                              (DREYECK/WORKFLOW:SOURCE-FORMS
                                                                                                                                                                                                             DREYECK/WORKFLOW/TESTS::SOURCE)))
                                                                                                                         (DREYECK/WORKFLOW/TESTS::RESULT
                                                                                                                                                         (DREYECK/WORKFLOW:PERSIST-IN
                                                                                                                                                                                      DREYECK/WORKFLOW/TESTS::CHANGE
                                                                                                                                                                                      DREYECK/WORKFLOW/TESTS::ENVIRONMENT)))
                                                                                                                        (COMMON-LISP:ASSERT
                                                                                                                                            (COMMON-LISP:EQ
                                                                                                                                                            :VERIFIED
                                                                                                                                                            (COMMON-LISP:GETF
                                                                                                                                                                              DREYECK/WORKFLOW/TESTS::RESULT
                                                                                                                                                                              :STATUS)))
                                                                                                                        (COMMON-LISP:ASSERT
                                                                                                                                            (COMMON-LISP:SEARCH
                                                                                                                                                                "WORKFLOW-FRESH-EXPECTATION-PASSED"
                                                                                                                                                                (COMMON-LISP:GETF
                                                                                                                                                                                  DREYECK/WORKFLOW/TESTS::RESULT
                                                                                                                                                                                  :FRESH-PROOF)))
                                                                                                                        (COMMON-LISP:ASSERT
                                                                                                                                            (DREYECK/WORKFLOW:FORM-EQUAL
                                                                                                                                                                         DREYECK/WORKFLOW/TESTS::NEIGHBOR
                                                                                                                                                                         (COMMON-LISP:THIRD
                                                                                                                                                                                            (DREYECK/WORKFLOW:SOURCE-FORMS
                                                                                                                                                                                                                           DREYECK/WORKFLOW/TESTS::SOURCE))))
                                                                                                                        (DREYECK/WORKFLOW/TESTS::MUST-FAIL
                                                                                                                                                           (COMMON-LISP:LAMBDA
                                                                                                                                                                               NIL
                                                                                                                                                                               (DREYECK/WORKFLOW:PERSIST-IN
                                                                                                                                                                                                            DREYECK/WORKFLOW/TESTS::CHANGE
                                                                                                                                                                                                            DREYECK/WORKFLOW/TESTS::ENVIRONMENT))))
                                                                                                      (DREYECK/WORKFLOW/TESTS::MUST-FAIL
                                                                                                                                         (COMMON-LISP:LAMBDA
                                                                                                                                                             NIL
                                                                                                                                                             (DREYECK/WORKFLOW:PERSIST-IN
                                                                                                                                                                                          (DREYECK/WORKFLOW/TESTS::PLAN
                                                                                                                                                                                                                        44
                                                                                                                                                                                                                        999)
                                                                                                                                                                                          DREYECK/WORKFLOW/TESTS::ENVIRONMENT)))
                                                                                                      (COMMON-LISP:LET
                                                                                                                       ((DREYECK/WORKFLOW/TESTS::DEPENDENCY
                                                                                                                                                            (DREYECK/WORKFLOW:PLAN-DEPENDENCY
                                                                                                                                                                                              DREYECK/WORKFLOW/TESTS::SYSTEM
                                                                                                                                                                                              "workflow-deliberately-missing-dependency"
                                                                                                                                                                                              COMMON-LISP:T)))
                                                                                                                       (DREYECK/WORKFLOW/TESTS::MUST-FAIL
                                                                                                                                                          (COMMON-LISP:LAMBDA
                                                                                                                                                                              NIL
                                                                                                                                                                              (DREYECK/WORKFLOW:PERSIST-IN
                                                                                                                                                                                                           DREYECK/WORKFLOW/TESTS::DEPENDENCY
                                                                                                                                                                                                           DREYECK/WORKFLOW/TESTS::ENVIRONMENT)))))
                                                                                    (COMMON-LISP:FORMAT
                                                                                                        COMMON-LISP:T
                                                                                                        "Workflow authoring tests passed: actual writer, fresh ordinary reconstruction, stale source, wrong behavior, missing dependency.~%")
                                                                                    DREYECK/WORKFLOW/TESTS::TRACKING)
                                                                 (ASDF/SYSTEM-REGISTRY:CLEAR-SYSTEM
                                                                                                    DREYECK/WORKFLOW/TESTS::SYSTEM)
                                                                 (UIOP/FILESYSTEM:DELETE-DIRECTORY-TREE
                                                                                                        DREYECK/WORKFLOW/TESTS::ROOT
                                                                                                        :VALIDATE
                                                                                                        COMMON-LISP:T
                                                                                                        :IF-DOES-NOT-EXIST
                                                                                                        :IGNORE))))
