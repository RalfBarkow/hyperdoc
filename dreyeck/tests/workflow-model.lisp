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

(DEFUN RUN-TESTS ()
  (LET* ((PLAN (CURRENT-PLAN))
         (BEFORE (UIOP/STREAM:READ-FILE-STRING (WF:PLAN-PATH PLAN))))
    (ASSERT (EQ :NEEDS-PERSISTENCE (WF:PLAN-STATUS PLAN)))
    (ASSERT (EQUAL '(:DEFINITION WF:PLAN-STATUS) (WF:PLAN-KEY PLAN)))
    (ASSERT (WF:PLAN-EXPECTATION PLAN))
    (MUST-FAIL (LAMBDA () (WF:PERSIST-IN PLAN :NO-AUTHORING-CAPABILITY)))
    (MUST-FAIL
     (LAMBDA ()
       (WF:PLAN-CHANGE "asdf" (WF:PLAN-PATH PLAN) (WF:PLAN-KEY PLAN)
                       (WF:PLAN-PROPOSED PLAN) T)))
    (MUST-FAIL
     (LAMBDA ()
       (WF:PLAN-DEFINITION "dreyeck/workflow" "dreyeck/src/workflow-model"
                           'WF:PLAN-STATUS '(DEFUN WRONG-NAME () T) T)))
    (ASSERT
     (STRING= BEFORE (UIOP/STREAM:READ-FILE-STRING (WF:PLAN-PATH PLAN))))
    (LET ((SYMBOL (GENSYM "UNFILED-")))
      (UNWIND-PROTECT
          (PROGN
           (SETF (SYMBOL-FUNCTION SYMBOL)
                   (COMPILE NIL '(LAMBDA () :EPHEMERAL)))
           (ASSERT
            (EQ :UNOWNED-OR-UNAVAILABLE
                (GETF (WF:OBSERVE-OPERATION SYMBOL) :STATUS))))
        (FMAKUNBOUND SYMBOL))))
  (FORMAT T
          "Workflow runtime tests passed: owned plans, identity, unowned observation, no implicit writer.~%")
  T)
