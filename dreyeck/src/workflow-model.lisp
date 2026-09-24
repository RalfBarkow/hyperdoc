;;;; Workflow plans and reconstruction
(DEFPACKAGE :DREYECK/WORKFLOW (:USE :CL)
            (:LOCAL-NICKNAMES (:HV :HTML-INSPECTOR-VIEWS/STANDARD))
            (:EXPORT :PERSISTENCE-PLAN :PLAN-CHANGE :PLAN-DEFINITION
                     :PLAN-DEPENDENCY :PLAN-SYSTEM :PLAN-PATH :PLAN-KEY
                     :PLAN-BEFORE :PLAN-PROPOSED :PLAN-SOURCE :PLAN-EXPECTATION
                     :PLAN-STATUS :OBSERVE-OPERATION :RECONSTRUCT :PERSIST-IN
                     :SOURCE-FORMS :FORM-KEY :FORM-EQUAL :CHANGE-LOG
                     :RECORDED-CHANGE :*CHANGE-LOG* :REGISTER-CHANGE
                     :OUTSTANDING-CHANGES :CHANGE-OPERATION :CHANGE-FUNCTION
                     :CHANGE-OBSERVATION :CHANGE-RECONSTRUCTION-STATUS
                     :OBSERVE-CHANGE :CURRENT-OUTSTANDING-CHANGES
                     :VERIFY-CHANGE :CHANGE-RECONSTRUCTION-PROOF))

(IN-PACKAGE :DREYECK/WORKFLOW)

(DEFCLASS PERSISTENCE-PLAN NIL
          ((SYSTEM :INITARG :SYSTEM :READER PLAN-SYSTEM)
           (PATH :INITARG :PATH :READER PLAN-PATH)
           (KEY :INITARG :KEY :READER PLAN-KEY)
           (BEFORE :INITARG :BEFORE :READER PLAN-BEFORE)
           (PROPOSED :INITARG :PROPOSED :READER PLAN-PROPOSED)
           (SOURCE :INITARG :SOURCE :READER PLAN-SOURCE)
           (EXPECTATION :INITARG :EXPECTATION :READER PLAN-EXPECTATION)))

(DEFUN FORM-EQUAL (A B)
       "Compare source data including independently read uninterned ASDF symbols."
       (COND
             ((AND (CONSP A) (CONSP B))
              (AND (FORM-EQUAL (CAR A) (CAR B)) (FORM-EQUAL (CDR A) (CDR B))))
             ((AND (SYMBOLP A) (SYMBOLP B))
              (AND (EQ (SYMBOL-PACKAGE A) (SYMBOL-PACKAGE B))
                   (STRING= (SYMBOL-NAME A) (SYMBOL-NAME B))))
             (T (EQUAL A B))))

(DEFUN SOURCE-FORMS (SOURCE)
       (MULTIPLE-VALUE-BIND (CODE RECOVERED) (HV:PARSE-LISP-CODE SOURCE)
                            (WHEN RECOVERED
                                  (ERROR
                                         "Source required reader recovery; refusing authority."))
                            (VALUES
                                    (MAPCAR (FUNCTION HV:S-EXP)
                                            (HV:TOP-LEVEL-FORMS-OF CODE))
                                    CODE)))

(DEFUN FORM-KEY (FORM)
       "Only explicit top-level DEFUN, DEFPARAMETER, DEFINE-CONDITION, DEFPACKAGE, DEFMETHOD, DEFSYSTEM and HyperDoc DEFEXAMPLE ownership is supported. A package key carries the designator's string rather than the designator: #:FOO read twice yields two uninterned symbols that are never EQUAL, and EQUAL is what key comparison uses. A method is one function among several with its name, so its key carries its qualifiers and the specializers of its required parameters, which is what distinguishes it from its siblings. DEFEXAMPLE is recognised by name, like DEFSYSTEM, because this package does not depend on HyperDoc."
       (WHEN (AND (CONSP FORM) (SYMBOLP (FIRST FORM)))
             (COND
                   ((EQ (FIRST FORM) (QUOTE DEFUN))
                    (LIST :DEFINITION (SECOND FORM)))
                   ((EQ (FIRST FORM) (QUOTE DEFPARAMETER))
                    (LIST :PARAMETER (SECOND FORM)))
                   ((EQ (FIRST FORM) (QUOTE DEFINE-CONDITION))
                    (LIST :CONDITION (SECOND FORM)))
                   ((EQ (FIRST FORM) (QUOTE DEFPACKAGE))
                    (LIST :PACKAGE (STRING (SECOND FORM))))
                   ((EQ (FIRST FORM) (QUOTE DEFMETHOD))
                    (LET* ((QUALIFIERS
                            (LOOP FOR ITEM IN (CDDR FORM)
                                  UNTIL (LISTP ITEM) COLLECT ITEM))
                           (LAMBDA-LIST (NTH (LENGTH QUALIFIERS) (CDDR FORM))))
                      (LIST :METHOD (SECOND FORM) QUALIFIERS
                            (LOOP FOR PARAMETER IN LAMBDA-LIST
                                  UNTIL (MEMBER PARAMETER LAMBDA-LIST-KEYWORDS)
                                  COLLECT (IF (CONSP PARAMETER)
                                              (SECOND PARAMETER)
                                              T)))))
                   ((STRING= (SYMBOL-NAME (FIRST FORM)) "DEFEXAMPLE")
                    (LIST :EXAMPLE (SECOND FORM)))
                   ((STRING= (SYMBOL-NAME (FIRST FORM)) "DEFSYSTEM")
                    (LIST :SYSTEM (STRING-DOWNCASE (STRING (SECOND FORM))))))))

(DEFUN OWNED-PATHS (SYSTEM)
       (LABELS
               ((PATHS (COMPONENT)
                       (IF (TYPEP COMPONENT (QUOTE ASDF/COMPONENT:MODULE))
                           (MAPCAN (FUNCTION PATHS)
                                   (ASDF/COMPONENT:COMPONENT-CHILDREN
                                                                      COMPONENT))
                           (LIST
                                 (ASDF/COMPONENT:COMPONENT-PATHNAME
                                                                    COMPONENT)))))
               (CONS (ASDF/SYSTEM:SYSTEM-SOURCE-FILE SYSTEM) (PATHS SYSTEM))))

(DEFUN PLAN-CHANGE (SYSTEM-NAME PATH KEY PROPOSED EXPECTATION)
       "Observe an owned form and propose data. Never evaluate or write it."
       (LET*
             ((SYSTEM (ASDF/SYSTEM:FIND-SYSTEM SYSTEM-NAME))
              (AUTHORITY (TRUENAME PATH))
              (SOURCE
                      (UIOP/STREAM:READ-FILE-STRING AUTHORITY :EXTERNAL-FORMAT
                                                    :UTF-8))
              (FORMS (SOURCE-FORMS SOURCE))
              (MATCHES
                       (REMOVE-IF-NOT (LAMBDA (F) (EQUAL KEY (FORM-KEY F)))
                                      FORMS)))
             (UNLESS
                     (MEMBER AUTHORITY (OWNED-PATHS SYSTEM) :KEY
                             (FUNCTION TRUENAME) :TEST (FUNCTION EQUAL))
                     (ERROR "~A is not owned by ASDF system ~A." AUTHORITY
                            SYSTEM-NAME))
             (UNLESS (= 1 (LENGTH MATCHES))
                     (ERROR "Authority must contain exactly one ~S." KEY))
             (UNLESS (EQUAL KEY (FORM-KEY PROPOSED))
                     (ERROR "Proposed form changes structural identity."))
             (UNLESS EXPECTATION
                     (ERROR "A fresh reconstruction expectation is required."))
             (MAKE-INSTANCE (QUOTE PERSISTENCE-PLAN) :SYSTEM
                            (ASDF/COMPONENT:COMPONENT-NAME SYSTEM) :PATH
                            AUTHORITY :KEY KEY :BEFORE
                            (COPY-TREE (FIRST MATCHES)) :PROPOSED
                            (COPY-TREE PROPOSED) :SOURCE SOURCE :EXPECTATION
                            (COPY-TREE EXPECTATION))))

(DEFUN PLAN-DEFINITION (SYSTEM COMPONENT NAME PROPOSED EXPECTATION)
       (LET
            ((OWNER
                    (ASDF/COMPONENT:FIND-COMPONENT
                                                   (ASDF/SYSTEM:FIND-SYSTEM
                                                                            SYSTEM)
                                                   COMPONENT)))
            (UNLESS OWNER
                    (ERROR "Missing ASDF source component ~S." COMPONENT))
            (PLAN-CHANGE SYSTEM (ASDF/COMPONENT:COMPONENT-PATHNAME OWNER)
                         (LIST :DEFINITION NAME) PROPOSED EXPECTATION)))

(DEFUN PLAN-DEPENDENCY (SYSTEM-NAME DEPENDENCY EXPECTATION)
       "ASDF owns dependencies. Propose one DEFSYSTEM transformation, not a new graph."
       (LET*
             ((SYSTEM (ASDF/SYSTEM:FIND-SYSTEM SYSTEM-NAME))
              (PATH (ASDF/SYSTEM:SYSTEM-SOURCE-FILE SYSTEM))
              (KEY (LIST :SYSTEM (ASDF/COMPONENT:COMPONENT-NAME SYSTEM)))
              (FORMS (SOURCE-FORMS PATH))
              (MATCHES
                       (REMOVE-IF-NOT (LAMBDA (F) (EQUAL KEY (FORM-KEY F)))
                                      FORMS)))
             (UNLESS (= 1 (LENGTH MATCHES))
                     (ERROR "Ambiguous DEFSYSTEM ownership."))
             (LET*
                   ((PROPOSED (COPY-TREE (FIRST MATCHES)))
                    (OPTIONS (CDDR PROPOSED))
                    (DEPENDENCIES (GETF OPTIONS :DEPENDS-ON)))
                   (UNLESS
                           (MEMBER DEPENDENCY DEPENDENCIES :TEST
                                   (FUNCTION STRING-EQUAL) :KEY
                                   (FUNCTION STRING))
                           (SETF (GETF OPTIONS :DEPENDS-ON)
                                 (APPEND DEPENDENCIES (LIST DEPENDENCY))))
                   (SETF (CDDR PROPOSED) OPTIONS)
                   (PLAN-CHANGE SYSTEM-NAME PATH KEY PROPOSED EXPECTATION))))

(DEFUN PLAN-STATUS (PLAN)
       (COND
             ((NOT
                   (STRING= (PLAN-SOURCE PLAN)
                            (UIOP/STREAM:READ-FILE-STRING (PLAN-PATH PLAN)
                                                          :EXTERNAL-FORMAT
                                                          :UTF-8)))
              :STALE-AUTHORITY)
             ((FORM-EQUAL (PLAN-BEFORE PLAN) (PLAN-PROPOSED PLAN)) :UNCHANGED)
             (T :NEEDS-PERSISTENCE)))

(DEFUN OBSERVE-OPERATION (NAME)
       "Bounded evidence for one supplied name. Source location is not equivalence."
       (IF (NOT (FBOUNDP NAME)) (LIST :NAME NAME :STATUS :ABSENT)
           (LET*
                 ((FN (FDEFINITION NAME))
                  (DEFINITION
                              (IGNORE-ERRORS
                                             (SB-INTROSPECT:FIND-DEFINITION-SOURCE
                                                                                   FN)))
                  (PATH
                        (AND DEFINITION
                             (SB-INTROSPECT:DEFINITION-SOURCE-PATHNAME
                                                                       DEFINITION))))
                 (LIST :NAME NAME :FUNCTION FN :SOURCE PATH :STATUS
                       (IF (AND PATH (PROBE-FILE PATH)) :SOURCE-LOCATED
                           :UNOWNED-OR-UNAVAILABLE)
                       :EQUIVALENCE :NOT-PROVEN :SCOPE
                       :SUPPLIED-OPERATION-ONLY))))

(DEFUN RECONSTRUCT (SYSTEM)
       "Delegate reconstruction and dependency order to ASDF."
       (ASDF/OPERATE:LOAD-SYSTEM SYSTEM :FORCE T)
       (LIST :STATUS :LOADED :SYSTEM SYSTEM :AUTHORITY
             (ASDF/SYSTEM:SYSTEM-SOURCE-FILE (ASDF/SYSTEM:FIND-SYSTEM SYSTEM))))

(DEFCLASS CHANGE-LOG NIL ((CHANGES :INITFORM NIL :ACCESSOR RECORDED-CHANGES))
          (:DOCUMENTATION
           "Explicit registrations in this image, not discovered image contents. Use separate logs for isolated examples/tests."))

(DEFCLASS RECORDED-CHANGE NIL
          ((OPERATION :INITARG :OPERATION :READER CHANGE-OPERATION)
           (FUNCTION :INITARG :FUNCTION :READER CHANGE-FUNCTION)
           (OBSERVATION :INITARG :OBSERVATION :READER CHANGE-OBSERVATION)
           (RECONSTRUCTION-PROOF :INITFORM NIL :READER
                                 CHANGE-RECONSTRUCTION-PROOF))
          (:DOCUMENTATION
                          "An explicitly registered operation/function identity. Captured source location is not verification."))

(DEFVAR *CHANGE-LOG*
  (MAKE-INSTANCE 'CHANGE-LOG)
  "Default image-local registration log. Reloading source does not discard pending changes.")

(DEFUN REGISTER-CHANGE (OPERATION &OPTIONAL (LOG *CHANGE-LOG*))
  "Explicit sequential registration after mutation. Same symbol and EQ function returns the same record; a different function records a distinct change."
  (UNLESS
      (AND (SYMBOLP OPERATION) (FBOUNDP OPERATION)
           (NOT (MACRO-FUNCTION OPERATION))
           (NOT (SPECIAL-OPERATOR-P OPERATION)))
    (ERROR "Expected a bound ordinary function symbol: ~S" OPERATION))
  (LET ((FUNCTION (FDEFINITION OPERATION)))
    (OR
     (FIND-IF
      (LAMBDA (CHANGE)
        (AND (EQ OPERATION (CHANGE-OPERATION CHANGE))
             (EQ FUNCTION (CHANGE-FUNCTION CHANGE))))
      (RECORDED-CHANGES LOG))
     (LET ((CHANGE
            (MAKE-INSTANCE 'RECORDED-CHANGE :OPERATION OPERATION :FUNCTION
                           FUNCTION :OBSERVATION
                           (OBSERVE-OPERATION OPERATION))))
       (PUSH CHANGE (RECORDED-CHANGES LOG))
       CHANGE))))

(DEFUN CHANGE-RECONSTRUCTION-STATUS (CHANGE)
       "Only accepted fresh-process evidence closes this particular record."
       (CHECK-TYPE CHANGE RECORDED-CHANGE)
       (IF (CHANGE-RECONSTRUCTION-PROOF CHANGE) :VERIFIED :UNVERIFIED))

(DEFUN OUTSTANDING-CHANGES (&OPTIONAL (LOG *CHANGE-LOG*))
  "Return a fresh list of registered unverified changes, oldest first. Unregistered mutations are invisible; source availability does not remove entries."
  (REVERSE
   (REMOVE-IF-NOT
    (LAMBDA (CHANGE) (EQ :UNVERIFIED (CHANGE-RECONSTRUCTION-STATUS CHANGE)))
    (RECORDED-CHANGES LOG))))

(DEFUN CURRENT-OUTSTANDING-CHANGES (&OPTIONAL (LOG *CHANGE-LOG*))
  "Registered, unverified definitions still EQ-current, in registration order. No whole-image discovery."
  (REMOVE-IF-NOT
   (LAMBDA (CHANGE)
     (GETF (OBSERVE-CHANGE CHANGE) :RECORDED-DEFINITION-CURRENT-P))
   (OUTSTANDING-CHANGES LOG)))

(DEFUN OBSERVE-CHANGE (CHANGE)
  "Keep registration, current observation and verification distinct. Later unregistered redefinitions can be observed but are not automatically registered."
  (LET ((CURRENT (OBSERVE-OPERATION (CHANGE-OPERATION CHANGE))))
    (LIST :CHANGE CHANGE :OPERATION (CHANGE-OPERATION CHANGE)
          :RECORDED-OBSERVATION (CHANGE-OBSERVATION CHANGE)
          :CURRENT-OBSERVATION CURRENT :RECORDED-DEFINITION-CURRENT-P
          (EQ (CHANGE-FUNCTION CHANGE) (GETF CURRENT :FUNCTION))
          :RECONSTRUCTION (CHANGE-RECONSTRUCTION-STATUS CHANGE))))

(DEFGENERIC VERIFY-CHANGE
    (CHANGE PLAN AUTHORING-CAPABILITY)
  (:DOCUMENTATION
   "Close this registered ordinary-function obligation only after fresh ordinary-runtime reconstruction satisfies the explicit expectation. Requires a matching persisted plan and a still-current recorded function. Ordinary runtime supplies no verifier."))

(DEFGENERIC PERSIST-IN (PLAN AUTHORING-CAPABILITY &KEY CHANGE)
            (:DOCUMENTATION
                            "Execute a plan through explicit pinned authoring capability.
Ordinary runtime defines the request and protocol only. Acceptance requires
structural read-back and a fresh ordinary-runtime reconstruction."))
