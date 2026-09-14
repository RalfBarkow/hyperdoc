;;;; Pinned structural persistence boundary
(DEFPACKAGE :DREYECK/WORKFLOW/AUTHORING
  (:USE :CL)
  (:LOCAL-NICKNAMES (:WF :DREYECK/WORKFLOW)
                    (:HV :HTML-INSPECTOR-VIEWS/STANDARD))
  (:EXPORT :MAKE-AUTHORING-ENVIRONMENT))

(IN-PACKAGE :DREYECK/WORKFLOW/AUTHORING)

(DEFCLASS AUTHORING-ENVIRONMENT NIL
          ((RUNTIME-REGISTRY :INITARG :RUNTIME-REGISTRY :READER
            RUNTIME-REGISTRY)))

(DEFUN MAKE-AUTHORING-ENVIRONMENT ()
  (LET ((SOURCE (UIOP/OS:GETENV "HYPERDOC_WORKFLOW_EDITOR_SOURCE"))
        (RUNTIME (UIOP/OS:GETENV "HYPERDOC_RUNTIME_SOURCE_REGISTRY")))
    (UNLESS
        (AND SOURCE RUNTIME
             (EQUAL (TRUENAME SOURCE)
                    (TRUENAME
                     (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY
                      "html-inspector-views/standard")))
             (STRING= "4b0607d93b193e21bd2ca5dc0d7e47c062ac8112"
                      (UIOP/OS:GETENV "HYPERDOC_WORKFLOW_EDITOR_COMMIT"))
             (FBOUNDP 'HV::REPLACE-CST-EXPRESSION-IN-FILE))
      (ERROR
       "Use nix develop .#workflow-authoring; explicit pinned authoring capability is absent."))
    (MAKE-INSTANCE 'AUTHORING-ENVIRONMENT :RUNTIME-REGISTRY RUNTIME)))

(DEFUN CHECK-CHANGE-PLAN (CHANGE PLAN)
  "Bind the expectation to one still-current record, never just its operation name."
  (CHECK-TYPE CHANGE WF:RECORDED-CHANGE)
  (UNLESS
      (EQUAL (WF:PLAN-KEY PLAN)
             (LIST :DEFINITION (WF:CHANGE-OPERATION CHANGE)))
    (ERROR "Plan does not own the registered operation."))
  (UNLESS (GETF (WF:OBSERVE-CHANGE CHANGE) :RECORDED-DEFINITION-CURRENT-P)
    (ERROR "Registered definition has been superseded."))
  (UNLESS (EVAL (WF:PLAN-EXPECTATION PLAN))
    (ERROR
     "Recorded live definition does not satisfy the explicit expectation."))
  (UNLESS (GETF (WF:OBSERVE-CHANGE CHANGE) :RECORDED-DEFINITION-CURRENT-P)
    (ERROR "Expectation changed the registered definition."))
  T)

(DEFUN CHECK-PERSISTED-PLAN (PLAN)
  (LET* ((EXPECTED (WF:SOURCE-FORMS (WF:PLAN-SOURCE PLAN)))
         (MATCHES
          (REMOVE-IF-NOT
           (LAMBDA (F) (EQUAL (WF:PLAN-KEY PLAN) (WF:FORM-KEY F))) EXPECTED))
         (SOURCE
          (UIOP/STREAM:READ-FILE-STRING (WF:PLAN-PATH PLAN) :EXTERNAL-FORMAT
                                        :UTF-8)))
    (UNLESS (= 1 (LENGTH MATCHES)) (ERROR "Plan target is ambiguous."))
    (SETF (NTH (POSITION (FIRST MATCHES) EXPECTED) EXPECTED)
            (WF:PLAN-PROPOSED PLAN))
    (UNLESS (WF:FORM-EQUAL EXPECTED (WF:SOURCE-FORMS SOURCE))
      (ERROR
       "Persisted source does not match the intended plan and surrounding forms."))
    SOURCE))

(DEFUN VERIFY-FRESH (PLAN ENVIRONMENT)
       (LET*
             ((SYSTEM (ASDF/SYSTEM:FIND-SYSTEM (WF:PLAN-SYSTEM PLAN)))
              (ASD (ASDF/SYSTEM:SYSTEM-SOURCE-FILE SYSTEM))
              (EXPRESSIONS
                           (LIST (QUOTE (REQUIRE :ASDF))
                                 (LIST (QUOTE ASDF/FIND-SYSTEM:LOAD-ASD) ASD)
                                 (LIST (QUOTE ASDF/OPERATE:LOAD-SYSTEM)
                                       (WF:PLAN-SYSTEM PLAN) :FORCE T)
                                 (LIST (QUOTE ASSERT)
                                       (WF:PLAN-EXPECTATION PLAN))
                                 (QUOTE
                                        (FORMAT T
                                                "WORKFLOW-FRESH-EXPECTATION-PASSED~%")))))
             (MULTIPLE-VALUE-BIND (OUTPUT ERRORS STATUS)
                                  (UIOP/RUN-PROGRAM:RUN-PROGRAM
                                                                (APPEND
                                                                        (LIST
                                                                              "env"
                                                                              "-u"
                                                                              "HYPERDOC_WORKFLOW_EDITOR_SOURCE"
                                                                              "-u"
                                                                              "HYPERDOC_WORKFLOW_EDITOR_COMMIT"
                                                                              "-u"
                                                                              "HYPERDOC_RUNTIME_SOURCE_REGISTRY"
                                                                              (CONCATENATE
                                                                                           (QUOTE
                                                                                                  STRING)
                                                                                           "CL_SOURCE_REGISTRY="
                                                                                           (RUNTIME-REGISTRY
                                                                                                             ENVIRONMENT))
                                                                              "sbcl"
                                                                              "--noinform"
                                                                              "--no-userinit"
                                                                              "--non-interactive")
                                                                        (LOOP
                                                                              FOR
                                                                              EXPRESSION
                                                                              IN
                                                                              EXPRESSIONS
                                                                              APPEND
                                                                              (LIST
                                                                                    "--eval"
                                                                                    (LET
                                                                                         ((*PRINT-READABLY*
                                                                                                            T)
                                                                                          (*PACKAGE*
                                                                                                     (FIND-PACKAGE
                                                                                                                   :CL-USER)))
                                                                                         (WRITE-TO-STRING
                                                                                                          EXPRESSION)))))
                                                                :OUTPUT :STRING
                                                                :ERROR-OUTPUT
                                                                :STRING
                                                                :IGNORE-ERROR-STATUS
                                                                T)
                                  (UNLESS (ZEROP STATUS)
                                          (ERROR
                                                 "Fresh reconstruction exited ~D:~%~A~%~A"
                                                 STATUS OUTPUT ERRORS))
                                  OUTPUT)))

(DEFMETHOD WF:VERIFY-CHANGE
           ((CHANGE WF:RECORDED-CHANGE) (PLAN WF:PERSISTENCE-PLAN)
            (ENVIRONMENT AUTHORING-ENVIRONMENT))
  "Verify persisted source against the same explicit behavioral expectation as the recorded live definition."
  (CHECK-CHANGE-PLAN CHANGE PLAN)
  (LET* ((SOURCE (CHECK-PERSISTED-PLAN PLAN))
         (OUTPUT (VERIFY-FRESH PLAN ENVIRONMENT)))
    (CHECK-CHANGE-PLAN CHANGE PLAN)
    (UNLESS (STRING= SOURCE (CHECK-PERSISTED-PLAN PLAN))
      (ERROR "Source changed during fresh verification."))
    (LET ((PROOF
           (LIST :STATUS :VERIFIED :CHANGE CHANGE :FUNCTION
                 (WF:CHANGE-FUNCTION CHANGE) :PLAN PLAN :EXPECTATION
                 (COPY-TREE (WF:PLAN-EXPECTATION PLAN)) :FRESH-PROOF OUTPUT
                 :SCOPE :EXPLICIT-EXPECTATION :WRITER-COMMIT
                 "4b0607d93b193e21bd2ca5dc0d7e47c062ac8112")))
      (SETF (SLOT-VALUE CHANGE 'WF::RECONSTRUCTION-PROOF) PROOF)
      PROOF)))

(DEFMETHOD WF:PERSIST-IN
           ((PLAN WF:PERSISTENCE-PLAN)
            (ENVIRONMENT AUTHORING-ENVIRONMENT)
            &KEY
            CHANGE)
           "The one execution seam used by authoring tests and reading examples."
           (WHEN CHANGE (CHECK-CHANGE-PLAN CHANGE PLAN))
           (UNLESS (EQ :NEEDS-PERSISTENCE (WF:PLAN-STATUS PLAN))
                   (ERROR "Plan must be current and changed, not ~S."
                          (WF:PLAN-STATUS PLAN)))
           (MULTIPLE-VALUE-BIND (BEFORE CODE)
                                (WF:SOURCE-FORMS (WF:PLAN-PATH PLAN))
                                (LET*
                                      ((TLFS (HV:TOP-LEVEL-FORMS-OF CODE))
                                       (MATCHES
                                                (REMOVE-IF-NOT
                                                               (LAMBDA (TLF)
                                                                       (EQUAL
                                                                              (WF:PLAN-KEY
                                                                                           PLAN)
                                                                              (WF:FORM-KEY
                                                                                           (HV:S-EXP
                                                                                                     TLF))))
                                                               TLFS)))
                                      (UNLESS (= 1 (LENGTH MATCHES))
                                              (ERROR
                                                     "Structural target is no longer unique."))
                                      (LET*
                                            ((TARGET (FIRST MATCHES))
                                             (INDEX (POSITION TARGET TLFS)))
                                            (UNLESS
                                                    (WF:FORM-EQUAL
                                                                   (WF:PLAN-BEFORE
                                                                                   PLAN)
                                                                   (NTH INDEX
                                                                        BEFORE))
                                                    (ERROR
                                                           "Structural authority changed."))
                                            (HV::REPLACE-CST-EXPRESSION-IN-FILE
                                                                                (WF:PLAN-PATH
                                                                                              PLAN)
                                                                                CODE
                                                                                (HV:CST-OF
                                                                                           TARGET)
                                                                                (WF:PLAN-PROPOSED
                                                                                                  PLAN))
                                            (LET
                                                 ((AFTER
                                                         (WF:SOURCE-FORMS
                                                                          (WF:PLAN-PATH
                                                                                        PLAN))))
                                                 (SETF (NTH INDEX BEFORE)
                                                       (WF:PLAN-PROPOSED PLAN))
                                                 (UNLESS
                                                         (EVERY
                                                                (FUNCTION
                                                                          WF:FORM-EQUAL)
                                                                BEFORE AFTER)
                                                         (ERROR
                                                                "Structural read-back differs from intended file."))
                                                 (UNLESS
                                                         (= (LENGTH BEFORE)
                                                            (LENGTH AFTER))
                                                         (ERROR
                                                                "Unexpected top-level forms.")))
                                            (HANDLER-CASE
                                                          (IF CHANGE
                                                              (WF:VERIFY-CHANGE
                                                                                CHANGE
                                                                                PLAN
                                                                                ENVIRONMENT)
                                                              (LET
                                                                   ((PROOF
                                                                           (VERIFY-FRESH
                                                                                         PLAN
                                                                                         ENVIRONMENT)))
                                                                   (LIST
                                                                         :STATUS
                                                                         :VERIFIED
                                                                         :PLAN
                                                                         PLAN
                                                                         :FRESH-PROOF
                                                                         PROOF
                                                                         :WRITER-COMMIT
                                                                         "4b0607d93b193e21bd2ca5dc0d7e47c062ac8112")))
                                                          (ERROR (CONDITION)
                                                                 (ERROR
                                                                        "Source was written and reparsed, but fresh reconstruction failed: ~A"
                                                                        CONDITION)))))))
