;;;; Workflow runtime falsification tests
(DEFPACKAGE :DREYECK/WORKFLOW/TESTS
  (:USE :CL)
  (:LOCAL-NICKNAMES (:WF :DREYECK/WORKFLOW))
  (:EXPORT :RUN-TESTS :RUN-AUTHORING-TESTS :RUN-READING-TESTS))

(IN-PACKAGE :DREYECK/WORKFLOW/TESTS)

(DEFUN MUST-FAIL (FUNCTION)
  (ASSERT (HANDLER-CASE (PROGN (FUNCALL FUNCTION) NIL) (ERROR NIL T))))

(DEFUN CURRENT-PLAN ()
  (LET* ((PATH
          (ASDF/COMPONENT:COMPONENT-PATHNAME
           (ASDF/COMPONENT:FIND-COMPONENT
            (ASDF/SYSTEM:FIND-SYSTEM "dreyeck/workflow")
            "dreyeck/src/workflow-model")))
         (BEFORE
          (FIND '(:DEFINITION WF:PLAN-STATUS) (WF:SOURCE-FORMS PATH) :KEY
                #'WF:FORM-KEY :TEST #'EQUAL))
         (PROPOSED (COPY-TREE BEFORE)))
    (ASSERT BEFORE)
    (SETF (CDDDR PROPOSED)
            (CONS "A structurally staged documentation change."
                  (CDDDR PROPOSED)))
    (WF:PLAN-DEFINITION "dreyeck/workflow" "dreyeck/src/workflow-model"
                        'WF:PLAN-STATUS PROPOSED '(FBOUNDP 'WF:PLAN-STATUS))))

(DEFUN RUN-CHANGE-TRACKING-TESTS NIL
       (LET
            ((NAME (GENSYM "LIVE-ONLY-"))
             (UNREGISTERED (GENSYM "UNREGISTERED-"))
             (LOG (MAKE-INSTANCE (QUOTE WF:CHANGE-LOG))))
            (UNWIND-PROTECT
                            (PROGN
                                   (SETF (SYMBOL-FUNCTION NAME)
                                         (COMPILE NIL
                                                  (QUOTE (LAMBDA (X) (+ X 1))))
                                         (SYMBOL-FUNCTION UNREGISTERED)
                                         (COMPILE NIL
                                                  (QUOTE
                                                         (LAMBDA NIL
                                                                 :INVISIBLE))))
                                   (LET*
                                         ((CHANGE
                                                  (WF:REGISTER-CHANGE NAME
                                                                      LOG))
                                          (OBSERVATION
                                                       (WF:CHANGE-OBSERVATION
                                                                              CHANGE)))
                                         (PROGN
                                                (ASSERT
                                                        (EQUAL (LIST CHANGE)
                                                               (WF:OUTSTANDING-CHANGES
                                                                                       LOG)))
                                                (ASSERT
                                                        (EQUAL (LIST CHANGE)
                                                               (WF:CURRENT-OUTSTANDING-CHANGES
                                                                                               LOG))))
                                         (ASSERT
                                                 (NULL
                                                       (GETF OBSERVATION
                                                             :SOURCE)))
                                         (ASSERT
                                                 (EQ :UNOWNED-OR-UNAVAILABLE
                                                     (GETF OBSERVATION
                                                           :STATUS)))
                                         (ASSERT
                                                 (EQ NAME
                                                     (WF:CHANGE-OPERATION
                                                                          CHANGE)))
                                         (ASSERT
                                                 (= 4
                                                    (FUNCALL
                                                             (WF:CHANGE-FUNCTION
                                                                                 CHANGE)
                                                             3)))
                                         (ASSERT
                                                 (NOT
                                                      (FIND UNREGISTERED
                                                            (WF:OUTSTANDING-CHANGES
                                                                                    LOG)
                                                            :KEY
                                                            (FUNCTION
                                                                      WF:CHANGE-OPERATION))))
                                         (ASSERT
                                                 (EQ CHANGE
                                                     (WF:REGISTER-CHANGE NAME
                                                                         LOG)))
                                         (ASSERT
                                                 (= 1
                                                    (LENGTH
                                                            (WF:OUTSTANDING-CHANGES
                                                                                    LOG))))
                                         (SETF (SYMBOL-FUNCTION NAME)
                                               (COMPILE NIL
                                                        (QUOTE
                                                               (LAMBDA (X)
                                                                       (+ X
                                                                          2)))))
                                         (PROGN
                                                (ASSERT
                                                        (NOT
                                                             (GETF
                                                                   (WF:OBSERVE-CHANGE
                                                                                      CHANGE)
                                                                   :RECORDED-DEFINITION-CURRENT-P)))
                                                (ASSERT
                                                        (NULL
                                                              (WF:CURRENT-OUTSTANDING-CHANGES
                                                                                              LOG))))
                                         (ASSERT
                                                 (= 1
                                                    (LENGTH
                                                            (WF:OUTSTANDING-CHANGES
                                                                                    LOG))))
                                         (LET
                                              ((NEW
                                                    (WF:REGISTER-CHANGE NAME
                                                                        LOG)))
                                              (ASSERT (NOT (EQ CHANGE NEW)))
                                              (ASSERT
                                                      (EQUAL (LIST CHANGE NEW)
                                                             (WF:OUTSTANDING-CHANGES
                                                                                     LOG)))
                                              (ASSERT
                                                      (EQ NEW
                                                          (WF:REGISTER-CHANGE
                                                                              NAME
                                                                              LOG)))
                                              (PROGN
                                                     (ASSERT
                                                             (GETF
                                                                   (WF:OBSERVE-CHANGE
                                                                                      NEW)
                                                                   :RECORDED-DEFINITION-CURRENT-P))
                                                     (ASSERT
                                                             (EQUAL (LIST NEW)
                                                                    (WF:CURRENT-OUTSTANDING-CHANGES
                                                                                                    LOG)))))
                                         (LET
                                              ((COPY
                                                     (WF:OUTSTANDING-CHANGES
                                                                             LOG)))
                                              (SETF (CAR COPY) NIL)
                                              (ASSERT
                                                      (EQ CHANGE
                                                          (FIRST
                                                                 (WF:OUTSTANDING-CHANGES
                                                                                         LOG)))))
                                         (LET
                                              ((OWNED
                                                      (WF:REGISTER-CHANGE
                                                                          (QUOTE
                                                                                 WF:PLAN-STATUS)
                                                                          LOG)))
                                              (ASSERT
                                                      (EQ :SOURCE-LOCATED
                                                          (GETF
                                                                (WF:CHANGE-OBSERVATION
                                                                                       OWNED)
                                                                :STATUS)))
                                              (ASSERT
                                                      (EQ :UNVERIFIED
                                                          (WF:CHANGE-RECONSTRUCTION-STATUS
                                                                                           OWNED)))
                                              (PROGN
                                                     (ASSERT
                                                             (MEMBER OWNED
                                                                     (WF:OUTSTANDING-CHANGES
                                                                                             LOG)))
                                                     (ASSERT
                                                             (MEMBER OWNED
                                                                     (WF:CURRENT-OUTSTANDING-CHANGES
                                                                                                     LOG)))))
                                         (ASSERT
                                                 (EVERY
                                                        (LAMBDA (ITEM)
                                                                (EQ :UNVERIFIED
                                                                    (WF:CHANGE-RECONSTRUCTION-STATUS
                                                                                                     ITEM)))
                                                        (WF:OUTSTANDING-CHANGES
                                                                                LOG)))))
                            (FMAKUNBOUND NAME) (FMAKUNBOUND UNREGISTERED)))
       (FORMAT T
               "Explicit change tracking passed: live-only observation, registration scope, deduplication, redefinition and unverified owned source.~%")
       T)

(DEFUN RUN-TESTS NIL
       (LET*
             ((PLAN (CURRENT-PLAN))
              (BEFORE (UIOP/STREAM:READ-FILE-STRING (WF:PLAN-PATH PLAN))))
             (ASSERT (EQ :NEEDS-PERSISTENCE (WF:PLAN-STATUS PLAN)))
             (ASSERT
                     (EQUAL (QUOTE (:DEFINITION WF:PLAN-STATUS))
                            (WF:PLAN-KEY PLAN)))
             (ASSERT (WF:PLAN-EXPECTATION PLAN))
             (MUST-FAIL
                        (LAMBDA NIL
                                (WF:PERSIST-IN PLAN :NO-AUTHORING-CAPABILITY)))
             (MUST-FAIL
                        (LAMBDA NIL
                                (WF:PLAN-CHANGE "asdf" (WF:PLAN-PATH PLAN)
                                                (WF:PLAN-KEY PLAN)
                                                (WF:PLAN-PROPOSED PLAN) T)))
             (MUST-FAIL
                        (LAMBDA NIL
                                (WF:PLAN-DEFINITION "dreyeck/workflow"
                                                    "dreyeck/src/workflow-model"
                                                    (QUOTE WF:PLAN-STATUS)
                                                    (QUOTE
                                                           (DEFUN WRONG-NAME
                                                                  NIL T))
                                                    T)))
             (ASSERT
                     (STRING= BEFORE
                              (UIOP/STREAM:READ-FILE-STRING
                                                            (WF:PLAN-PATH
                                                                          PLAN))))
             (LET ((SYMBOL (GENSYM "UNFILED-")))
                  (UNWIND-PROTECT
                                  (PROGN
                                         (SETF (SYMBOL-FUNCTION SYMBOL)
                                               (COMPILE NIL
                                                        (QUOTE
                                                               (LAMBDA NIL
                                                                       :EPHEMERAL))))
                                         (ASSERT
                                                 (EQ :UNOWNED-OR-UNAVAILABLE
                                                     (GETF
                                                           (WF:OBSERVE-OPERATION
                                                                                 SYMBOL)
                                                           :STATUS))))
                                  (FMAKUNBOUND SYMBOL))))
       (FORMAT T
               "Workflow runtime tests passed: owned plans, identity, unowned observation, no implicit writer.~%")
       (RUN-CHANGE-TRACKING-TESTS) T)
