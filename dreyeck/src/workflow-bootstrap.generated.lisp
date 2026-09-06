;;;; Regenerated from the live DREYECK/WORKFLOW state.
;;;; Bootstrap plus operation installation.

(DEFPACKAGE #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
  (:USE #A((11) BASE-CHAR . "COMMON-LISP"))
  (:EXPORT "ADMIT"
           "ASSIGN"
           "AUDIT"
           "AUDIT-COMPLETE"
           "COMMIT"
           "DEPEND-ON"
           "FRESH-TEST"
           "FRESH-VERIFY"
           "PERSIST"
           "PERSIST-IN"
           "RECONCILE"
           "RECONSTRUCT"
           "RETIRE"
           "VERIFY"))

(IN-PACKAGE "DREYECK/WORKFLOW")

(REQUIRE :SB-INTROSPECT)

(DEFPARAMETER DREYECK/WORKFLOW::*WORKFLOW-OPERATION-ASSEMBLY-SPECIFICATIONS*
  NIL)

(DEFPARAMETER DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*
  (MAKE-HASH-TABLE :TEST 'EQUAL))

(DEFPARAMETER DREYECK/WORKFLOW::*WORKFLOW-CONSTRUCTION-MATERIALIZERS*
  (MAKE-HASH-TABLE :TEST 'EQ))

(DEFUN DREYECK/WORKFLOW::DECODE-PERSISTENCE-NODE
       (DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE
        &OPTIONAL
        (DREYECK/WORKFLOW::%CODEC-LEXICAL-UNINTERNED-SYMBOLS
         (MAKE-HASH-TABLE :TEST #'EQL)))
  (BLOCK DREYECK/WORKFLOW::DECODE-PERSISTENCE-NODE
    (BLOCK DREYECK/WORKFLOW::DECODE-PERSISTENCE-NODE
      (ASSERT (CONSP DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))
      (CASE (FIRST DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE)
        (:NULL NIL)
        (:KEYWORD
         (INTERN (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE) "KEYWORD"))
        (:COMMON-LISP-SYMBOL
         (OR
          (FIND-SYMBOL (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE)
                       "COMMON-LISP")
          (ERROR "Unknown COMMON-LISP symbol ~S."
                 (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))))
        (:SYMBOL
         (LET ((PACKAGE
                (FIND-PACKAGE (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))))
           (UNLESS PACKAGE
             (ERROR "Package ~S is unavailable while decoding ~S."
                    (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE)
                    DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))
           (INTERN (THIRD DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE) PACKAGE)))
        (:UNINTERNED-SYMBOL
         (LET* ((DREYECK/WORKFLOW::%CODEC-LEXICAL-ID
                 (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))
                (DREYECK/WORKFLOW::%CODEC-LEXICAL-NAME
                 (THIRD DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))
                (DREYECK/WORKFLOW::%CODEC-LEXICAL-EXISTING
                 (GETHASH DREYECK/WORKFLOW::%CODEC-LEXICAL-ID
                          DREYECK/WORKFLOW::%CODEC-LEXICAL-UNINTERNED-SYMBOLS)))
           (OR DREYECK/WORKFLOW::%CODEC-LEXICAL-EXISTING
               (SETF (GETHASH DREYECK/WORKFLOW::%CODEC-LEXICAL-ID
                              DREYECK/WORKFLOW::%CODEC-LEXICAL-UNINTERNED-SYMBOLS)
                       (MAKE-SYMBOL DREYECK/WORKFLOW::%CODEC-LEXICAL-NAME)))))
        (:CONS
         (CONS
          (DREYECK/WORKFLOW::DECODE-PERSISTENCE-NODE
           (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE)
           DREYECK/WORKFLOW::%CODEC-LEXICAL-UNINTERNED-SYMBOLS)
          (DREYECK/WORKFLOW::DECODE-PERSISTENCE-NODE
           (THIRD DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE)
           DREYECK/WORKFLOW::%CODEC-LEXICAL-UNINTERNED-SYMBOLS)))
        (:STRING (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))
        (:NUMBER (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))
        (:CHARACTER (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))
        (:PATHNAME (PATHNAME (SECOND DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE)))
        (OTHERWISE
         (ERROR "Unknown workflow persistence node ~S."
                DREYECK/WORKFLOW::%CODEC-LEXICAL-NODE))))))

(DEFUN DREYECK/WORKFLOW::WORKFLOW-FRAGMENT-CARRIER (DREYECK/WORKFLOW::ENTRY)
  (BLOCK DREYECK/WORKFLOW::WORKFLOW-FRAGMENT-CARRIER
    (LET ((DREYECK/WORKFLOW::RECORD (GETF DREYECK/WORKFLOW::ENTRY :RECORD)))
      (UNLESS DREYECK/WORKFLOW::RECORD
        (ERROR "Workflow registry entry has no source record: ~S."
               DREYECK/WORKFLOW::ENTRY))
      (DREYECK/WORKFLOW::DECODE-PERSISTENCE-NODE
       (GETF DREYECK/WORKFLOW::RECORD :SEMANTIC-CARRIER)))))

(DEFUN DREYECK/WORKFLOW::WORKFLOW-CARRIER-FIELD-VALUE
       (DREYECK/WORKFLOW::CARRIER DREYECK/WORKFLOW::FIELD)
  (BLOCK DREYECK/WORKFLOW::WORKFLOW-CARRIER-FIELD-VALUE
    (LET ((DREYECK/WORKFLOW::FIELD-RECORD
           (FIND DREYECK/WORKFLOW::FIELD
                 (GETF DREYECK/WORKFLOW::CARRIER :FIELDS) :TEST #'EQ :KEY
                 (LAMBDA (DREYECK/WORKFLOW::CANDIDATE)
                   (GETF DREYECK/WORKFLOW::CANDIDATE :FIELD)))))
      (UNLESS DREYECK/WORKFLOW::FIELD-RECORD
        (ERROR "Workflow semantic carrier ~S has no field ~S."
               DREYECK/WORKFLOW::CARRIER DREYECK/WORKFLOW::FIELD))
      (GETF DREYECK/WORKFLOW::FIELD-RECORD :VALUE))))

(DEFUN DREYECK/WORKFLOW::WORKFLOW-COMPILE-LAMBDA-EXPRESSION
       (DREYECK/WORKFLOW::LAMBDA-EXPRESSION)
  (BLOCK DREYECK/WORKFLOW::WORKFLOW-COMPILE-LAMBDA-EXPRESSION
    (UNLESS
        (AND (CONSP DREYECK/WORKFLOW::LAMBDA-EXPRESSION)
             (EQ 'LAMBDA (FIRST DREYECK/WORKFLOW::LAMBDA-EXPRESSION)))
      (ERROR "Expected workflow lambda expression, got ~S."
             DREYECK/WORKFLOW::LAMBDA-EXPRESSION))
    (MULTIPLE-VALUE-BIND
        (FUNCTION DREYECK/WORKFLOW::WARNINGS-P DREYECK/WORKFLOW::FAILURE-P)
        (COMPILE NIL DREYECK/WORKFLOW::LAMBDA-EXPRESSION)
      (DECLARE (IGNORE DREYECK/WORKFLOW::WARNINGS-P))
      (WHEN DREYECK/WORKFLOW::FAILURE-P
        (ERROR "Failed to compile workflow lambda expression ~S."
               DREYECK/WORKFLOW::LAMBDA-EXPRESSION))
      FUNCTION)))

(DEFUN DREYECK/WORKFLOW::WORKFLOW-MAKE-GUARDED-EXTENSION-FUNCTION
       (DREYECK/WORKFLOW::PREVIOUS DREYECK/WORKFLOW::LAMBDA-LIST
        DREYECK/WORKFLOW::GUARD DREYECK/WORKFLOW::EXTENSION-BODY
        DREYECK/WORKFLOW::FALLBACK-BODY)
  (BLOCK DREYECK/WORKFLOW::WORKFLOW-MAKE-GUARDED-EXTENSION-FUNCTION
    (UNLESS
        (AND (CONSP DREYECK/WORKFLOW::FALLBACK-BODY)
             (EQ 'FUNCALL (FIRST DREYECK/WORKFLOW::FALLBACK-BODY))
             (SYMBOLP (SECOND DREYECK/WORKFLOW::FALLBACK-BODY)))
      (ERROR
       "Cannot recover predecessor binding from workflow fallback body ~S."
       DREYECK/WORKFLOW::FALLBACK-BODY))
    (LET* ((DREYECK/WORKFLOW::PREVIOUS-BINDING
            (SECOND DREYECK/WORKFLOW::FALLBACK-BODY))
           (DREYECK/WORKFLOW::FACTORY-FORM
            (LIST 'LAMBDA (LIST DREYECK/WORKFLOW::PREVIOUS-BINDING)
                  (LIST 'LAMBDA DREYECK/WORKFLOW::LAMBDA-LIST
                        (LIST 'IF DREYECK/WORKFLOW::GUARD
                              DREYECK/WORKFLOW::EXTENSION-BODY
                              DREYECK/WORKFLOW::FALLBACK-BODY))))
           (DREYECK/WORKFLOW::FACTORY
            (DREYECK/WORKFLOW::WORKFLOW-COMPILE-LAMBDA-EXPRESSION
             DREYECK/WORKFLOW::FACTORY-FORM)))
      (FUNCALL DREYECK/WORKFLOW::FACTORY DREYECK/WORKFLOW::PREVIOUS))))

(DEFUN DREYECK/WORKFLOW::COLLECT-OPERATION-FRAGMENTS
       (DREYECK/WORKFLOW::OPERATION)
  (BLOCK DREYECK/WORKFLOW::COLLECT-OPERATION-FRAGMENTS
    (LET* ((DREYECK/WORKFLOW::SPECIFICATION
            (FIND DREYECK/WORKFLOW::OPERATION
                  DREYECK/WORKFLOW::*WORKFLOW-OPERATION-ASSEMBLY-SPECIFICATIONS*
                  :TEST #'EQ :KEY
                  (LAMBDA (DREYECK/WORKFLOW::CANDIDATE)
                    (GETF DREYECK/WORKFLOW::CANDIDATE :OPERATION))))
           (DREYECK/WORKFLOW::EXPECTED-FRAGMENT-KEYS
            (AND DREYECK/WORKFLOW::SPECIFICATION
                 (GETF DREYECK/WORKFLOW::SPECIFICATION
                       :EXPECTED-FRAGMENT-KEYS)))
           (DREYECK/WORKFLOW::EXPECTED-ENTRIES NIL)
           (DREYECK/WORKFLOW::UNEXPECTED-ENTRIES NIL))
      (UNLESS DREYECK/WORKFLOW::SPECIFICATION
        (ERROR "No workflow assembly specification for ~S."
               DREYECK/WORKFLOW::OPERATION))
      (DOLIST
          (DREYECK/WORKFLOW::FRAGMENT-KEY
           DREYECK/WORKFLOW::EXPECTED-FRAGMENT-KEYS)
        (MULTIPLE-VALUE-BIND
            (DREYECK/WORKFLOW::ENTRY DREYECK/WORKFLOW::PRESENT-P)
            (GETHASH DREYECK/WORKFLOW::FRAGMENT-KEY
                     DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          (WHEN DREYECK/WORKFLOW::PRESENT-P
            (PUSH DREYECK/WORKFLOW::ENTRY
                  DREYECK/WORKFLOW::EXPECTED-ENTRIES))))
      (MAPHASH
       (LAMBDA (DREYECK/WORKFLOW::FRAGMENT-KEY DREYECK/WORKFLOW::ENTRY)
         (WHEN
             (AND
              (EQ DREYECK/WORKFLOW::OPERATION
                  (GETF DREYECK/WORKFLOW::ENTRY :OPERATION))
              (NOT
               (MEMBER DREYECK/WORKFLOW::FRAGMENT-KEY
                       DREYECK/WORKFLOW::EXPECTED-FRAGMENT-KEYS :TEST
                       #'EQUAL)))
           (PUSH DREYECK/WORKFLOW::ENTRY
                 DREYECK/WORKFLOW::UNEXPECTED-ENTRIES)))
       DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
      (APPEND (NREVERSE DREYECK/WORKFLOW::EXPECTED-ENTRIES)
              DREYECK/WORKFLOW::UNEXPECTED-ENTRIES))))

(DEFUN DREYECK/WORKFLOW::VALIDATE-CONSTRUCTION-COMPLETENESS
       (DREYECK/WORKFLOW::OPERATION)
  (BLOCK DREYECK/WORKFLOW::VALIDATE-CONSTRUCTION-COMPLETENESS
    (LET* ((DREYECK/WORKFLOW::SPECIFICATION
            (FIND DREYECK/WORKFLOW::OPERATION
                  DREYECK/WORKFLOW::*WORKFLOW-OPERATION-ASSEMBLY-SPECIFICATIONS*
                  :TEST #'EQ :KEY
                  (LAMBDA (DREYECK/WORKFLOW::CANDIDATE)
                    (GETF DREYECK/WORKFLOW::CANDIDATE :OPERATION))))
           (DREYECK/WORKFLOW::ENTRIES
            (DREYECK/WORKFLOW::COLLECT-OPERATION-FRAGMENTS
             DREYECK/WORKFLOW::OPERATION)))
      (UNLESS DREYECK/WORKFLOW::SPECIFICATION
        (ERROR "No workflow assembly specification for ~S."
               DREYECK/WORKFLOW::OPERATION))
      (LET* ((DREYECK/WORKFLOW::EXPECTED-FRAGMENT-KEYS
              (COPY-TREE
               (GETF DREYECK/WORKFLOW::SPECIFICATION :EXPECTED-FRAGMENT-KEYS)))
             (DREYECK/WORKFLOW::ACTUAL-FRAGMENT-KEYS
              (MAPCAR
               (LAMBDA (DREYECK/WORKFLOW::ENTRY)
                 (COPY-TREE (GETF DREYECK/WORKFLOW::ENTRY :FRAGMENT-KEY)))
               DREYECK/WORKFLOW::ENTRIES))
             (DREYECK/WORKFLOW::MISSING-FRAGMENT-KEYS
              (REMOVE-IF
               (LAMBDA (DREYECK/WORKFLOW::FRAGMENT-KEY)
                 (MEMBER DREYECK/WORKFLOW::FRAGMENT-KEY
                         DREYECK/WORKFLOW::ACTUAL-FRAGMENT-KEYS :TEST #'EQUAL))
               DREYECK/WORKFLOW::EXPECTED-FRAGMENT-KEYS))
             (DREYECK/WORKFLOW::UNEXPECTED-FRAGMENT-KEYS
              (REMOVE-IF
               (LAMBDA (DREYECK/WORKFLOW::FRAGMENT-KEY)
                 (MEMBER DREYECK/WORKFLOW::FRAGMENT-KEY
                         DREYECK/WORKFLOW::EXPECTED-FRAGMENT-KEYS :TEST
                         #'EQUAL))
               DREYECK/WORKFLOW::ACTUAL-FRAGMENT-KEYS))
             (DREYECK/WORKFLOW::CONSTRUCTION-MISMATCHES
              (REMOVE-IF
               (LAMBDA (DREYECK/WORKFLOW::ENTRY)
                 (EQ (GETF DREYECK/WORKFLOW::SPECIFICATION :CONSTRUCTION)
                     (GETF DREYECK/WORKFLOW::ENTRY :CONSTRUCTION)))
               DREYECK/WORKFLOW::ENTRIES))
             (DREYECK/WORKFLOW::COMPLETE-P
              (AND (NULL DREYECK/WORKFLOW::MISSING-FRAGMENT-KEYS)
                   (NULL DREYECK/WORKFLOW::UNEXPECTED-FRAGMENT-KEYS)
                   (NULL DREYECK/WORKFLOW::CONSTRUCTION-MISMATCHES))))
        (LIST :OPERATION DREYECK/WORKFLOW::OPERATION :CONSTRUCTION
              (GETF DREYECK/WORKFLOW::SPECIFICATION :CONSTRUCTION)
              :EXPECTED-FRAGMENT-COUNT
              (LENGTH DREYECK/WORKFLOW::EXPECTED-FRAGMENT-KEYS)
              :ACTUAL-FRAGMENT-COUNT
              (LENGTH DREYECK/WORKFLOW::ACTUAL-FRAGMENT-KEYS)
              :MISSING-FRAGMENT-KEYS DREYECK/WORKFLOW::MISSING-FRAGMENT-KEYS
              :UNEXPECTED-FRAGMENT-KEYS
              DREYECK/WORKFLOW::UNEXPECTED-FRAGMENT-KEYS
              :CONSTRUCTION-MISMATCHES
              DREYECK/WORKFLOW::CONSTRUCTION-MISMATCHES :COMPLETE-P
              DREYECK/WORKFLOW::COMPLETE-P)))))

(DEFUN DREYECK/WORKFLOW::MATERIALIZE-CONSTRUCTION-SOURCE-FORM (CONSTRUCTION)
  (BLOCK DREYECK/WORKFLOW::MATERIALIZE-CONSTRUCTION-SOURCE-FORM
    (LET* ((FUNCTION
            (GETHASH CONSTRUCTION
                     DREYECK/WORKFLOW::*WORKFLOW-CONSTRUCTION-MATERIALIZERS*))
           (LAMBDA-EXPRESSION
            (AND FUNCTION (NTH-VALUE 0 (FUNCTION-LAMBDA-EXPRESSION FUNCTION)))))
      (ASSERT FUNCTION)
      (ASSERT LAMBDA-EXPRESSION)
      (ASSERT (NOT (SB-KERNEL:CLOSUREP FUNCTION)))
      (LIST 'SETF
            (LIST 'GETHASH CONSTRUCTION
                  'DREYECK/WORKFLOW::*WORKFLOW-CONSTRUCTION-MATERIALIZERS*)
            (LIST 'FUNCTION LAMBDA-EXPRESSION)))))

(DEFUN DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
       (DREYECK/WORKFLOW::OPERATION)
  (BLOCK DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
    (ASSERT (SYMBOLP DREYECK/WORKFLOW::OPERATION))
    (LET* ((DREYECK/WORKFLOW::VALIDATION
            (DREYECK/WORKFLOW::VALIDATE-CONSTRUCTION-COMPLETENESS
             DREYECK/WORKFLOW::OPERATION))
           (DREYECK/WORKFLOW::SPECIFICATION
            (FIND DREYECK/WORKFLOW::OPERATION
                  DREYECK/WORKFLOW::*WORKFLOW-OPERATION-ASSEMBLY-SPECIFICATIONS*
                  :TEST #'EQ :KEY
                  (LAMBDA (DREYECK/WORKFLOW::CANDIDATE)
                    (GETF DREYECK/WORKFLOW::CANDIDATE :OPERATION))))
           (DREYECK/WORKFLOW::CONSTRUCTION
            (GETF DREYECK/WORKFLOW::SPECIFICATION :CONSTRUCTION))
           (DREYECK/WORKFLOW::MATERIALIZER
            (GETHASH DREYECK/WORKFLOW::CONSTRUCTION
                     DREYECK/WORKFLOW::*WORKFLOW-CONSTRUCTION-MATERIALIZERS*)))
      (UNLESS (GETF DREYECK/WORKFLOW::VALIDATION :COMPLETE-P)
        (ERROR "Incomplete workflow construction for ~S: ~S."
               DREYECK/WORKFLOW::OPERATION DREYECK/WORKFLOW::VALIDATION))
      (UNLESS DREYECK/WORKFLOW::MATERIALIZER
        (ERROR "No workflow construction materializer registered for ~S."
               DREYECK/WORKFLOW::CONSTRUCTION))
      (LET ((DREYECK/WORKFLOW::MATERIALIZED-FUNCTION
             (FUNCALL DREYECK/WORKFLOW::MATERIALIZER
                      DREYECK/WORKFLOW::OPERATION
                      (DREYECK/WORKFLOW::COLLECT-OPERATION-FRAGMENTS
                       DREYECK/WORKFLOW::OPERATION)
                      DREYECK/WORKFLOW::SPECIFICATION)))
        (UNLESS (FUNCTIONP DREYECK/WORKFLOW::MATERIALIZED-FUNCTION)
          (ERROR "Materializer for ~S returned non-function ~S."
                 DREYECK/WORKFLOW::OPERATION
                 DREYECK/WORKFLOW::MATERIALIZED-FUNCTION))
        (SETF (SYMBOL-FUNCTION DREYECK/WORKFLOW::OPERATION)
                DREYECK/WORKFLOW::MATERIALIZED-FUNCTION)
        (LIST :OPERATION DREYECK/WORKFLOW::OPERATION :CONSTRUCTION
              DREYECK/WORKFLOW::CONSTRUCTION :FRAGMENT-COUNT
              (GETF DREYECK/WORKFLOW::VALIDATION :ACTUAL-FRAGMENT-COUNT)
              :FUNCTION DREYECK/WORKFLOW::MATERIALIZED-FUNCTION :STATUS
              :MATERIALIZED)))))

(DEFPARAMETER DREYECK/WORKFLOW::*WORKFLOW-OPERATION-ASSEMBLY-SPECIFICATIONS*
  '((:OPERATION DREYECK/WORKFLOW:ADMIT :CONSTRUCTION :FORWARDING-CLOSURE
     :EXPECTED-FRAGMENT-COUNT 2 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:ADMIT :PART :CAPABILITY-RELATION)
      (:OPERATION DREYECK/WORKFLOW:ADMIT :PART :FORWARDER))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow" "dreyeck/workflow/catalog")
     :CROSS-AUTHORITY-P T :CONSTRUCTION-HISTORY-ORDINALS NIL
     :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :RESOLVE-CAPABILITY-RELATION :CONSTRUCT-FORWARDER))
    (:OPERATION DREYECK/WORKFLOW:ASSIGN :CONSTRUCTION
     :GUARDED-OPERATION-EXTENSION :EXPECTED-FRAGMENT-COUNT 2
     :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:ASSIGN :PART :BASE-DEFINITION)
      (:OPERATION DREYECK/WORKFLOW:ASSIGN :PART :GUARDED-EXTENSION))
     :AUTHORITY-SYSTEM-NAMES
     ("dreyeck/workflow/catalog" "dreyeck/workflow/catalog/tests")
     :CROSS-AUTHORITY-P T :CONSTRUCTION-HISTORY-ORDINALS NIL
     :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :MATERIALIZE-PREDECESSOR :APPLY-GUARDED-EXTENSION))
    (:OPERATION DREYECK/WORKFLOW:AUDIT :CONSTRUCTION
     :GUARDED-OPERATION-EXTENSION :EXPECTED-FRAGMENT-COUNT 2
     :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:AUDIT :PART :BASE-DEFINITION)
      (:OPERATION DREYECK/WORKFLOW:AUDIT :PART :GUARDED-EXTENSION))
     :AUTHORITY-SYSTEM-NAMES
     ("dreyeck/workflow" "dreyeck/workflow/catalog/tests") :CROSS-AUTHORITY-P T
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :MATERIALIZE-PREDECESSOR :APPLY-GUARDED-EXTENSION))
    (:OPERATION DREYECK/WORKFLOW:AUDIT-COMPLETE :CONSTRUCTION
     :DEFINITION-SUFFICIENT :EXPECTED-FRAGMENT-COUNT 1 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:AUDIT-COMPLETE :PART :DEFINITION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow") :CROSS-AUTHORITY-P NIL
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DEFINITION))
    (:OPERATION DREYECK/WORKFLOW:COMMIT :CONSTRUCTION :ADAPTER-FORWARDING
     :EXPECTED-FRAGMENT-COUNT 2 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:COMMIT :PART :ADAPTER-DEFINITION)
      (:OPERATION DREYECK/WORKFLOW:COMMIT :PART :CAPABILITY-RELATION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow" "dreyeck/workflow/git")
     :CROSS-AUTHORITY-P T :CONSTRUCTION-HISTORY-ORDINALS NIL
     :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :RESOLVE-CAPABILITY-RELATION :CONSTRUCT-ADAPTER))
    (:OPERATION DREYECK/WORKFLOW:DEPEND-ON :CONSTRUCTION :DEFINITION-SUFFICIENT
     :EXPECTED-FRAGMENT-COUNT 1 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:DEPEND-ON :PART :DEFINITION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow") :CROSS-AUTHORITY-P NIL
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DEFINITION))
    (:OPERATION DREYECK/WORKFLOW:FRESH-TEST :CONSTRUCTION :FORWARDING-CLOSURE
     :EXPECTED-FRAGMENT-COUNT 2 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:FRESH-TEST :PART :CAPABILITY-RELATION)
      (:OPERATION DREYECK/WORKFLOW:FRESH-TEST :PART :FORWARDER))
     :AUTHORITY-SYSTEM-NAMES
     ("dreyeck/workflow" "dreyeck/workflow/fresh-image-runner")
     :CROSS-AUTHORITY-P T :CONSTRUCTION-HISTORY-ORDINALS NIL
     :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :RESOLVE-CAPABILITY-RELATION :CONSTRUCT-FORWARDER))
    (:OPERATION DREYECK/WORKFLOW:FRESH-VERIFY :CONSTRUCTION
     :DEFINITION-SUFFICIENT :EXPECTED-FRAGMENT-COUNT 1 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:FRESH-VERIFY :PART :DEFINITION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow/catalog") :CROSS-AUTHORITY-P
     NIL :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DEFINITION))
    (:OPERATION DREYECK/WORKFLOW:PERSIST :CONSTRUCTION :SUM-TYPE-DISPATCH
     :EXPECTED-FRAGMENT-COUNT 3 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:PERSIST :PART :CONS-KIND-DISPATCH)
      (:OPERATION DREYECK/WORKFLOW:PERSIST :PART :SUBJECT-TYPE-DISPATCH)
      (:OPERATION DREYECK/WORKFLOW:PERSIST :PART :SYMBOL-HANDLER))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow") :CROSS-AUTHORITY-P NIL
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DISPATCH))
    (:OPERATION DREYECK/WORKFLOW:PERSIST-IN :CONSTRUCTION
     :GUARDED-OPERATION-EXTENSION-CHAIN :EXPECTED-FRAGMENT-COUNT 6
     :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:PERSIST-IN :PART :BASE-DEFINITION)
      (:OPERATION DREYECK/WORKFLOW:PERSIST-IN :PART
       :CONSTRUCTION-HISTORY-EXTENSION :ORDINAL 0)
      (:OPERATION DREYECK/WORKFLOW:PERSIST-IN :PART
       :CONSTRUCTION-HISTORY-EXTENSION :ORDINAL 1)
      (:OPERATION DREYECK/WORKFLOW:PERSIST-IN :PART
       :CONSTRUCTION-HISTORY-EXTENSION :ORDINAL 2)
      (:OPERATION DREYECK/WORKFLOW:PERSIST-IN :PART
       :CONSTRUCTION-HISTORY-EXTENSION :ORDINAL 3)
      (:OPERATION DREYECK/WORKFLOW:PERSIST-IN :PART :VERIFICATION-CONTRACT))
     :AUTHORITY-SYSTEM-NAMES
     ("dreyeck/workflow/catalog" "dreyeck/workflow/catalog/tests"
      "dreyeck/workflow/tests")
     :CROSS-AUTHORITY-P T :CONSTRUCTION-HISTORY-ORDINALS (0 1 2 3)
     :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :MATERIALIZE-BASE-DEFINITION
      :SORT-CONSTRUCTION-HISTORY-BY-ORDINAL :FOLD-GUARDED-EXTENSIONS
      :DERIVE-EFFECTIVE-SEMANTICS))
    (:OPERATION DREYECK/WORKFLOW:RECONCILE :CONSTRUCTION :DEFINITION-SUFFICIENT
     :EXPECTED-FRAGMENT-COUNT 1 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:RECONCILE :PART :DEFINITION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow/git") :CROSS-AUTHORITY-P NIL
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DEFINITION))
    (:OPERATION DREYECK/WORKFLOW:RECONSTRUCT :CONSTRUCTION
     :DEFINITION-SUFFICIENT :EXPECTED-FRAGMENT-COUNT 1 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:RECONSTRUCT :PART :DEFINITION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow") :CROSS-AUTHORITY-P NIL
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DEFINITION))
    (:OPERATION DREYECK/WORKFLOW:RETIRE :CONSTRUCTION :DEFINITION-SUFFICIENT
     :EXPECTED-FRAGMENT-COUNT 1 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:RETIRE :PART :DEFINITION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow") :CROSS-AUTHORITY-P NIL
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DEFINITION))
    (:OPERATION DREYECK/WORKFLOW:VERIFY :CONSTRUCTION :DEFINITION-SUFFICIENT
     :EXPECTED-FRAGMENT-COUNT 1 :EXPECTED-FRAGMENT-KEYS
     ((:OPERATION DREYECK/WORKFLOW:VERIFY :PART :DEFINITION))
     :AUTHORITY-SYSTEM-NAMES ("dreyeck/workflow") :CROSS-AUTHORITY-P NIL
     :CONSTRUCTION-HISTORY-ORDINALS NIL :REQUIRED-MATERIALIZER-OPERATORS
     (:DECODE-FRAGMENT :INSTANTIATE-DEFINITION))))

(PROGN
 (DEFPARAMETER DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*
   (MAKE-HASH-TABLE :TEST 'EQUAL))
 (PROGN
  (SETF (GETHASH
         '(:OPERATION DREYECK/WORKFLOW:AUDIT-COMPLETE :PART :DEFINITION)
         DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:AUDIT-COMPLETE :PART :DEFINITION)
            :OPERATION DREYECK/WORKFLOW:AUDIT-COMPLETE :CONSTRUCTION
            :DEFINITION-SUFFICIENT :ROLE :DEFINITION :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS
               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                "AUDIT-COMPLETE")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((10) BASE-CHAR . "DEFINITION")) (:NULL)))))
             :CONSTRUCTION :DEFINITION-SUFFICIENT :ROLE :DEFINITION
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                          #A((7) BASE-CHAR . "SUBJECT"))
                         (:NULL))
                        (:CONS
                         (:CONS (:COMMON-LISP-SYMBOL #A((3) BASE-CHAR . "LET"))
                          (:CONS
                           (:CONS
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((5) BASE-CHAR . "AUDIT"))
                             (:CONS
                              (:CONS
                               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                                "AUDIT")
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((7) BASE-CHAR . "SUBJECT"))
                                (:NULL)))
                              (:NULL)))
                            (:NULL))
                           (:CONS
                            (:CONS
                             (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "ASSERT"))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((5) BASE-CHAR . "EQUAL"))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((4) BASE-CHAR . "GETF"))
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((5) BASE-CHAR . "AUDIT"))
                                  (:CONS
                                   (:KEYWORD #A((9) BASE-CHAR . "NEXT-FORM"))
                                   (:NULL))))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((4) BASE-CHAR . "LIST"))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((5) BASE-CHAR . "QUOTE"))
                                    (:CONS
                                     (:SYMBOL
                                      #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                                      "AUDIT-COMPLETE")
                                     (:NULL)))
                                   (:CONS
                                    (:SYMBOL
                                     #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                     #A((7) BASE-CHAR . "SUBJECT"))
                                    (:NULL))))
                                 (:NULL))))
                              (:NULL)))
                            (:CONS
                             (:CONS
                              (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "LIST"))
                              (:CONS (:KEYWORD #A((6) BASE-CHAR . "STATUS"))
                               (:CONS (:KEYWORD #A((8) BASE-CHAR . "COMPLETE"))
                                (:CONS (:KEYWORD #A((7) BASE-CHAR . "SUBJECT"))
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((7) BASE-CHAR . "SUBJECT"))
                                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "AUDIT"))
                                   (:CONS
                                    (:SYMBOL
                                     #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                     #A((5) BASE-CHAR . "AUDIT"))
                                    (:NULL))))))))
                             (:NULL)))))
                         (:NULL))))
                      (:NULL)))))
                  (:NULL))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:DEPEND-ON :PART :DEFINITION)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:DEPEND-ON :PART :DEFINITION)
            :OPERATION DREYECK/WORKFLOW:DEPEND-ON :CONSTRUCTION
            :DEFINITION-SUFFICIENT :ROLE :DEFINITION :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS
               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "DEPEND-ON")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((10) BASE-CHAR . "DEFINITION")) (:NULL)))))
             :CONSTRUCTION :DEFINITION-SUFFICIENT :ROLE :DEFINITION
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                          #A((6) BASE-CHAR . "SYSTEM"))
                         (:CONS
                          (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                           #A((10) BASE-CHAR . "DEPENDENCY"))
                          (:NULL)))
                        (:CONS
                         (:CONS (:COMMON-LISP-SYMBOL #A((2) BASE-CHAR . "IF"))
                          (:CONS
                           (:CONS
                            (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "MEMBER"))
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((10) BASE-CHAR . "DEPENDENCY"))
                             (:CONS
                              (:CONS
                               (:SYMBOL #A((11) BASE-CHAR . "ASDF/SYSTEM")
                                "SYSTEM-DEPENDS-ON")
                               (:CONS
                                (:CONS
                                 (:SYMBOL #A((11) BASE-CHAR . "ASDF/SYSTEM")
                                  "FIND-SYSTEM")
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((6) BASE-CHAR . "SYSTEM"))
                                  (:NULL)))
                                (:NULL)))
                              (:CONS (:KEYWORD #A((4) BASE-CHAR . "TEST"))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((8) BASE-CHAR . "FUNCTION"))
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((5) BASE-CHAR . "EQUAL"))
                                  (:NULL)))
                                (:NULL))))))
                           (:CONS
                            (:CONS
                             (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "LIST"))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((5) BASE-CHAR . "QUOTE"))
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                                 "RECONSTRUCT")
                                (:NULL)))
                              (:CONS
                               (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                #A((6) BASE-CHAR . "SYSTEM"))
                               (:NULL))))
                            (:CONS
                             (:CONS
                              (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "LIST"))
                              (:CONS
                               (:CONS
                                (:COMMON-LISP-SYMBOL
                                 #A((5) BASE-CHAR . "QUOTE"))
                                (:CONS
                                 (:SYMBOL
                                  #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                                  "PERSIST")
                                 (:NULL)))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((4) BASE-CHAR . "LIST"))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((5) BASE-CHAR . "QUOTE"))
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((5) BASE-CHAR . "QUOTE"))
                                    (:NULL)))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((4) BASE-CHAR . "LIST"))
                                    (:CONS
                                     (:KEYWORD
                                      #A((15) BASE-CHAR . "ASDF-DEPENDENCY"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((6) BASE-CHAR . "SYSTEM"))
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((10) BASE-CHAR . "DEPENDENCY"))
                                       (:NULL)))))
                                   (:NULL))))
                                (:NULL))))
                             (:NULL)))))
                         (:NULL))))
                      (:NULL)))))
                  (:NULL))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:RECONSTRUCT :PART :DEFINITION)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:RECONSTRUCT :PART :DEFINITION)
            :OPERATION DREYECK/WORKFLOW:RECONSTRUCT :CONSTRUCTION
            :DEFINITION-SUFFICIENT :ROLE :DEFINITION :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS
               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "RECONSTRUCT")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((10) BASE-CHAR . "DEFINITION")) (:NULL)))))
             :CONSTRUCTION :DEFINITION-SUFFICIENT :ROLE :DEFINITION
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                          #A((9) BASE-CHAR . "OPERATION"))
                         (:NULL))
                        (:CONS
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "LET*"))
                          (:CONS
                           (:CONS
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((12) BASE-CHAR . "OLD-FUNCTION"))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((15) BASE-CHAR . "SYMBOL-FUNCTION"))
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((9) BASE-CHAR . "OPERATION"))
                                (:NULL)))
                              (:NULL)))
                            (:CONS
                             (:CONS
                              (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                               #A((10) BASE-CHAR . "DEFINITION"))
                              (:CONS
                               (:CONS
                                (:SYMBOL #A((13) BASE-CHAR . "SB-INTROSPECT")
                                 #A((22) BASE-CHAR . "FIND-DEFINITION-SOURCE"))
                                (:CONS
                                 (:SYMBOL
                                  #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                  #A((12) BASE-CHAR . "OLD-FUNCTION"))
                                 (:NULL)))
                               (:NULL)))
                             (:CONS
                              (:CONS
                               (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                #A((6) BASE-CHAR . "SOURCE"))
                               (:CONS
                                (:CONS
                                 (:SYMBOL #A((13) BASE-CHAR . "SB-INTROSPECT")
                                  #A((26) BASE-CHAR
                                     . "DEFINITION-SOURCE-PATHNAME"))
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((10) BASE-CHAR . "DEFINITION"))
                                  (:NULL)))
                                (:NULL)))
                              (:NULL))))
                           (:CONS
                            (:CONS
                             (:COMMON-LISP-SYMBOL
                              #A((11) BASE-CHAR . "FMAKUNBOUND"))
                             (:CONS
                              (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                               #A((9) BASE-CHAR . "OPERATION"))
                              (:NULL)))
                            (:CONS
                             (:CONS
                              (:COMMON-LISP-SYMBOL
                               #A((12) BASE-CHAR . "HANDLER-CASE"))
                              (:CONS
                               (:CONS
                                (:COMMON-LISP-SYMBOL
                                 #A((5) BASE-CHAR . "PROGN"))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((4) BASE-CHAR . "LOAD"))
                                  (:CONS
                                   (:SYMBOL
                                    #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                    #A((6) BASE-CHAR . "SOURCE"))
                                   (:NULL)))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((6) BASE-CHAR . "ASSERT"))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((7) BASE-CHAR . "FBOUNDP"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((9) BASE-CHAR . "OPERATION"))
                                      (:NULL)))
                                    (:NULL)))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((4) BASE-CHAR . "LET*"))
                                    (:CONS
                                     (:CONS
                                      (:CONS
                                       (:COMMON-LISP-SYMBOL
                                        #A((7) BASE-CHAR . "PACKAGE"))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((12) BASE-CHAR . "FIND-PACKAGE"))
                                         (:CONS (:STRING "DREYECK/WORKFLOW")
                                          (:NULL)))
                                        (:NULL)))
                                      (:CONS
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((6) BASE-CHAR . "VERIFY"))
                                        (:CONS
                                         (:CONS
                                          (:COMMON-LISP-SYMBOL
                                           #A((6) BASE-CHAR . "INTERN"))
                                          (:CONS (:STRING "VERIFY")
                                           (:CONS
                                            (:COMMON-LISP-SYMBOL
                                             #A((7) BASE-CHAR . "PACKAGE"))
                                            (:NULL))))
                                         (:NULL)))
                                       (:NULL)))
                                     (:CONS
                                      (:CONS
                                       (:COMMON-LISP-SYMBOL
                                        #A((6) BASE-CHAR . "EXPORT"))
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((6) BASE-CHAR . "VERIFY"))
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((7) BASE-CHAR . "PACKAGE"))
                                         (:NULL))))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((4) BASE-CHAR . "LIST"))
                                        (:CONS
                                         (:KEYWORD
                                          #A((6) BASE-CHAR . "STATUS"))
                                         (:CONS
                                          (:KEYWORD
                                           #A((13) BASE-CHAR
                                              . "RECONSTRUCTED"))
                                          (:CONS
                                           (:KEYWORD
                                            #A((9) BASE-CHAR . "OPERATION"))
                                           (:CONS
                                            (:SYMBOL
                                             #A((16) BASE-CHAR
                                                . "COMMON-LISP-USER")
                                             #A((9) BASE-CHAR . "OPERATION"))
                                            (:CONS
                                             (:KEYWORD
                                              #A((6) BASE-CHAR . "SOURCE"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((6) BASE-CHAR . "SOURCE"))
                                              (:CONS
                                               (:KEYWORD
                                                #A((9) BASE-CHAR
                                                   . "NEXT-FORM"))
                                               (:CONS
                                                (:CONS
                                                 (:COMMON-LISP-SYMBOL
                                                  #A((4) BASE-CHAR . "LIST"))
                                                 (:CONS
                                                  (:SYMBOL
                                                   #A((16) BASE-CHAR
                                                      . "COMMON-LISP-USER")
                                                   #A((6) BASE-CHAR
                                                      . "VERIFY"))
                                                  (:CONS
                                                   (:SYMBOL
                                                    #A((16) BASE-CHAR
                                                       . "COMMON-LISP-USER")
                                                    #A((9) BASE-CHAR
                                                       . "OPERATION"))
                                                   (:NULL))))
                                                (:NULL))))))))))
                                       (:NULL)))))
                                   (:NULL)))))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((5) BASE-CHAR . "ERROR"))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((9) BASE-CHAR . "CONDITION"))
                                   (:NULL))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((4) BASE-CHAR . "SETF"))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((15) BASE-CHAR . "SYMBOL-FUNCTION"))
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((9) BASE-CHAR . "OPERATION"))
                                       (:NULL)))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((12) BASE-CHAR . "OLD-FUNCTION"))
                                      (:NULL))))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((5) BASE-CHAR . "ERROR"))
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((9) BASE-CHAR . "CONDITION"))
                                      (:NULL)))
                                    (:NULL)))))
                                (:NULL))))
                             (:NULL)))))
                         (:NULL))))
                      (:NULL)))))
                  (:NULL))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:RETIRE :PART :DEFINITION)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:RETIRE :PART :DEFINITION) :OPERATION
            DREYECK/WORKFLOW:RETIRE :CONSTRUCTION :DEFINITION-SUFFICIENT :ROLE
            :DEFINITION :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "RETIRE")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((10) BASE-CHAR . "DEFINITION")) (:NULL)))))
             :CONSTRUCTION :DEFINITION-SUFFICIENT :ROLE :DEFINITION
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                          #A((7) BASE-CHAR . "SUBJECT"))
                         (:NULL))
                        (:CONS
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "ECASE"))
                          (:CONS
                           (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                            #A((7) BASE-CHAR . "SUBJECT"))
                           (:CONS
                            (:CONS
                             (:KEYWORD
                              #A((22) BASE-CHAR . "OFFER-ACTIVATION-SLICE"))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "LET*"))
                               (:CONS
                                (:CONS
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((16) BASE-CHAR . "PROTOTYPE-SYMBOL"))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((11) BASE-CHAR . "FIND-SYMBOL"))
                                    (:CONS
                                     (:STRING "REPAIR-WORKSPACE-HYPERBOOK")
                                     (:CONS (:STRING "CL-USER") (:NULL))))
                                   (:NULL)))
                                 (:CONS
                                  (:CONS
                                   (:SYMBOL
                                    #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                    #A((15) BASE-CHAR . "PROTOTYPE-CLASS"))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((3) BASE-CHAR . "AND"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((16) BASE-CHAR . "PROTOTYPE-SYMBOL"))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((10) BASE-CHAR . "FIND-CLASS"))
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((16) BASE-CHAR
                                             . "PROTOTYPE-SYMBOL"))
                                         (:CONS (:NULL) (:NULL))))
                                       (:NULL))))
                                    (:NULL)))
                                  (:CONS
                                   (:CONS
                                    (:SYMBOL
                                     #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                     #A((17) BASE-CHAR . "ACTIVATION-SYMBOL"))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((11) BASE-CHAR . "FIND-SYMBOL"))
                                      (:CONS
                                       (:STRING
                                        "*CONVERSATION-10666-LIVE-ACTIVATION-OPERATION*")
                                       (:CONS (:STRING "CL-USER") (:NULL))))
                                     (:NULL)))
                                   (:CONS
                                    (:CONS
                                     (:SYMBOL
                                      #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                      #A((17) BASE-CHAR . "GENERIC-FUNCTIONS"))
                                     (:CONS
                                      (:CONS
                                       (:COMMON-LISP-SYMBOL
                                        #A((3) BASE-CHAR . "AND"))
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((15) BASE-CHAR
                                            . "PROTOTYPE-CLASS"))
                                        (:CONS
                                         (:CONS
                                          (:COMMON-LISP-SYMBOL
                                           #A((9) BASE-CHAR . "COPY-LIST"))
                                          (:CONS
                                           (:CONS
                                            (:SYMBOL
                                             #A((6) BASE-CHAR . "SB-MOP")
                                             #A((36) BASE-CHAR
                                                . "SPECIALIZER-DIRECT-GENERIC-FUNCTIONS"))
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((15) BASE-CHAR
                                                 . "PROTOTYPE-CLASS"))
                                             (:NULL)))
                                           (:NULL)))
                                         (:NULL))))
                                      (:NULL)))
                                    (:CONS
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((15) BASE-CHAR . "REMOVED-METHODS"))
                                      (:CONS (:NULL) (:NULL)))
                                     (:CONS
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((25) BASE-CHAR
                                           . "RETIRED-GENERIC-FUNCTIONS"))
                                       (:CONS (:NULL) (:NULL)))
                                      (:NULL)))))))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((4) BASE-CHAR . "WHEN"))
                                  (:CONS
                                   (:SYMBOL
                                    #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                    #A((15) BASE-CHAR . "PROTOTYPE-CLASS"))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((6) BASE-CHAR . "DOLIST"))
                                     (:CONS
                                      (:CONS
                                       (:COMMON-LISP-SYMBOL
                                        #A((16) BASE-CHAR
                                           . "GENERIC-FUNCTION"))
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((17) BASE-CHAR
                                            . "GENERIC-FUNCTIONS"))
                                        (:NULL)))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((6) BASE-CHAR . "DOLIST"))
                                        (:CONS
                                         (:CONS
                                          (:COMMON-LISP-SYMBOL
                                           #A((6) BASE-CHAR . "METHOD"))
                                          (:CONS
                                           (:CONS
                                            (:COMMON-LISP-SYMBOL
                                             #A((9) BASE-CHAR . "COPY-LIST"))
                                            (:CONS
                                             (:CONS
                                              (:SYMBOL
                                               #A((6) BASE-CHAR . "SB-MOP")
                                               #A((24) BASE-CHAR
                                                  . "GENERIC-FUNCTION-METHODS"))
                                              (:CONS
                                               (:COMMON-LISP-SYMBOL
                                                #A((16) BASE-CHAR
                                                   . "GENERIC-FUNCTION"))
                                               (:NULL)))
                                             (:NULL)))
                                           (:NULL)))
                                         (:CONS
                                          (:CONS
                                           (:COMMON-LISP-SYMBOL
                                            #A((4) BASE-CHAR . "WHEN"))
                                           (:CONS
                                            (:CONS
                                             (:COMMON-LISP-SYMBOL
                                              #A((6) BASE-CHAR . "MEMBER"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((15) BASE-CHAR
                                                  . "PROTOTYPE-CLASS"))
                                              (:CONS
                                               (:CONS
                                                (:SYMBOL
                                                 #A((6) BASE-CHAR . "SB-MOP")
                                                 #A((19) BASE-CHAR
                                                    . "METHOD-SPECIALIZERS"))
                                                (:CONS
                                                 (:COMMON-LISP-SYMBOL
                                                  #A((6) BASE-CHAR . "METHOD"))
                                                 (:NULL)))
                                               (:CONS
                                                (:KEYWORD
                                                 #A((4) BASE-CHAR . "TEST"))
                                                (:CONS
                                                 (:CONS
                                                  (:COMMON-LISP-SYMBOL
                                                   #A((8) BASE-CHAR
                                                      . "FUNCTION"))
                                                  (:CONS
                                                   (:COMMON-LISP-SYMBOL
                                                    #A((2) BASE-CHAR . "EQ"))
                                                   (:NULL)))
                                                 (:NULL))))))
                                            (:CONS
                                             (:CONS
                                              (:COMMON-LISP-SYMBOL
                                               #A((13) BASE-CHAR
                                                  . "REMOVE-METHOD"))
                                              (:CONS
                                               (:COMMON-LISP-SYMBOL
                                                #A((16) BASE-CHAR
                                                   . "GENERIC-FUNCTION"))
                                               (:CONS
                                                (:COMMON-LISP-SYMBOL
                                                 #A((6) BASE-CHAR . "METHOD"))
                                                (:NULL))))
                                             (:CONS
                                              (:CONS
                                               (:COMMON-LISP-SYMBOL
                                                #A((4) BASE-CHAR . "PUSH"))
                                               (:CONS
                                                (:COMMON-LISP-SYMBOL
                                                 #A((6) BASE-CHAR . "METHOD"))
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((16) BASE-CHAR
                                                     . "COMMON-LISP-USER")
                                                  #A((15) BASE-CHAR
                                                     . "REMOVED-METHODS"))
                                                 (:NULL))))
                                              (:NULL)))))
                                          (:NULL))))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((4) BASE-CHAR . "WHEN"))
                                         (:CONS
                                          (:CONS
                                           (:COMMON-LISP-SYMBOL
                                            #A((3) BASE-CHAR . "AND"))
                                           (:CONS
                                            (:CONS
                                             (:COMMON-LISP-SYMBOL
                                              #A((4) BASE-CHAR . "NULL"))
                                             (:CONS
                                              (:CONS
                                               (:SYMBOL
                                                #A((6) BASE-CHAR . "SB-MOP")
                                                #A((24) BASE-CHAR
                                                   . "GENERIC-FUNCTION-METHODS"))
                                               (:CONS
                                                (:COMMON-LISP-SYMBOL
                                                 #A((16) BASE-CHAR
                                                    . "GENERIC-FUNCTION"))
                                                (:NULL)))
                                              (:NULL)))
                                            (:CONS
                                             (:CONS
                                              (:COMMON-LISP-SYMBOL
                                               #A((3) BASE-CHAR . "LET"))
                                              (:CONS
                                               (:CONS
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((16) BASE-CHAR
                                                     . "COMMON-LISP-USER")
                                                  #A((4) BASE-CHAR . "NAME"))
                                                 (:CONS
                                                  (:CONS
                                                   (:SYMBOL
                                                    #A((6) BASE-CHAR
                                                       . "SB-MOP")
                                                    #A((21) BASE-CHAR
                                                       . "GENERIC-FUNCTION-NAME"))
                                                   (:CONS
                                                    (:COMMON-LISP-SYMBOL
                                                     #A((16) BASE-CHAR
                                                        . "GENERIC-FUNCTION"))
                                                    (:NULL)))
                                                  (:NULL)))
                                                (:NULL))
                                               (:CONS
                                                (:CONS
                                                 (:COMMON-LISP-SYMBOL
                                                  #A((3) BASE-CHAR . "AND"))
                                                 (:CONS
                                                  (:CONS
                                                   (:COMMON-LISP-SYMBOL
                                                    #A((7) BASE-CHAR
                                                       . "SYMBOLP"))
                                                   (:CONS
                                                    (:SYMBOL
                                                     #A((16) BASE-CHAR
                                                        . "COMMON-LISP-USER")
                                                     #A((4) BASE-CHAR
                                                        . "NAME"))
                                                    (:NULL)))
                                                  (:CONS
                                                   (:CONS
                                                    (:COMMON-LISP-SYMBOL
                                                     #A((2) BASE-CHAR . "EQ"))
                                                    (:CONS
                                                     (:CONS
                                                      (:COMMON-LISP-SYMBOL
                                                       #A((14) BASE-CHAR
                                                          . "SYMBOL-PACKAGE"))
                                                      (:CONS
                                                       (:SYMBOL
                                                        #A((16) BASE-CHAR
                                                           . "COMMON-LISP-USER")
                                                        #A((4) BASE-CHAR
                                                           . "NAME"))
                                                       (:NULL)))
                                                     (:CONS
                                                      (:CONS
                                                       (:COMMON-LISP-SYMBOL
                                                        #A((12) BASE-CHAR
                                                           . "FIND-PACKAGE"))
                                                       (:CONS
                                                        (:STRING "CL-USER")
                                                        (:NULL)))
                                                      (:NULL))))
                                                   (:NULL))))
                                                (:NULL))))
                                             (:NULL))))
                                          (:CONS
                                           (:CONS
                                            (:COMMON-LISP-SYMBOL
                                             #A((3) BASE-CHAR . "LET"))
                                            (:CONS
                                             (:CONS
                                              (:CONS
                                               (:SYMBOL
                                                #A((16) BASE-CHAR
                                                   . "COMMON-LISP-USER")
                                                #A((4) BASE-CHAR . "NAME"))
                                               (:CONS
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((6) BASE-CHAR . "SB-MOP")
                                                  #A((21) BASE-CHAR
                                                     . "GENERIC-FUNCTION-NAME"))
                                                 (:CONS
                                                  (:COMMON-LISP-SYMBOL
                                                   #A((16) BASE-CHAR
                                                      . "GENERIC-FUNCTION"))
                                                  (:NULL)))
                                                (:NULL)))
                                              (:NULL))
                                             (:CONS
                                              (:CONS
                                               (:COMMON-LISP-SYMBOL
                                                #A((11) BASE-CHAR
                                                   . "FMAKUNBOUND"))
                                               (:CONS
                                                (:SYMBOL
                                                 #A((16) BASE-CHAR
                                                    . "COMMON-LISP-USER")
                                                 #A((4) BASE-CHAR . "NAME"))
                                                (:NULL)))
                                              (:CONS
                                               (:CONS
                                                (:COMMON-LISP-SYMBOL
                                                 #A((4) BASE-CHAR . "PUSH"))
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((16) BASE-CHAR
                                                     . "COMMON-LISP-USER")
                                                  #A((4) BASE-CHAR . "NAME"))
                                                 (:CONS
                                                  (:SYMBOL
                                                   #A((16) BASE-CHAR
                                                      . "COMMON-LISP-USER")
                                                   #A((25) BASE-CHAR
                                                      . "RETIRED-GENERIC-FUNCTIONS"))
                                                  (:NULL))))
                                               (:NULL)))))
                                           (:NULL))))
                                        (:NULL)))))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((4) BASE-CHAR . "SETF"))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((10) BASE-CHAR . "FIND-CLASS"))
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((16) BASE-CHAR
                                             . "PROTOTYPE-SYMBOL"))
                                         (:NULL)))
                                       (:CONS (:NULL) (:NULL))))
                                     (:NULL)))))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((4) BASE-CHAR . "WHEN"))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((3) BASE-CHAR . "AND"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((17) BASE-CHAR
                                          . "ACTIVATION-SYMBOL"))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((6) BASE-CHAR . "BOUNDP"))
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((17) BASE-CHAR
                                             . "ACTIVATION-SYMBOL"))
                                         (:NULL)))
                                       (:NULL))))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((10) BASE-CHAR . "MAKUNBOUND"))
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((17) BASE-CHAR
                                           . "ACTIVATION-SYMBOL"))
                                       (:NULL)))
                                     (:NULL))))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((4) BASE-CHAR . "LIST"))
                                    (:CONS
                                     (:KEYWORD #A((7) BASE-CHAR . "SUBJECT"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((7) BASE-CHAR . "SUBJECT"))
                                      (:CONS
                                       (:KEYWORD
                                        #A((13) BASE-CHAR . "RETIRED-CLASS"))
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((16) BASE-CHAR
                                            . "PROTOTYPE-SYMBOL"))
                                        (:CONS
                                         (:KEYWORD
                                          #A((20) BASE-CHAR
                                             . "REMOVED-METHOD-COUNT"))
                                         (:CONS
                                          (:CONS
                                           (:COMMON-LISP-SYMBOL
                                            #A((6) BASE-CHAR . "LENGTH"))
                                           (:CONS
                                            (:SYMBOL
                                             #A((16) BASE-CHAR
                                                . "COMMON-LISP-USER")
                                             #A((15) BASE-CHAR
                                                . "REMOVED-METHODS"))
                                            (:NULL)))
                                          (:CONS
                                           (:KEYWORD
                                            #A((33) BASE-CHAR
                                               . "RETIRED-PRIVATE-GENERIC-FUNCTIONS"))
                                           (:CONS
                                            (:CONS
                                             (:COMMON-LISP-SYMBOL
                                              #A((8) BASE-CHAR . "NREVERSE"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((25) BASE-CHAR
                                                  . "RETIRED-GENERIC-FUNCTIONS"))
                                              (:NULL)))
                                            (:CONS
                                             (:KEYWORD
                                              #A((19) BASE-CHAR
                                                 . "ACTIVATION-VARIABLE"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((17) BASE-CHAR
                                                  . "ACTIVATION-SYMBOL"))
                                              (:CONS
                                               (:KEYWORD
                                                #A((29) BASE-CHAR
                                                   . "PROTOTYPE-CLASS-STILL-NAMED-P"))
                                               (:CONS
                                                (:CONS
                                                 (:COMMON-LISP-SYMBOL
                                                  #A((3) BASE-CHAR . "AND"))
                                                 (:CONS
                                                  (:SYMBOL
                                                   #A((16) BASE-CHAR
                                                      . "COMMON-LISP-USER")
                                                   #A((16) BASE-CHAR
                                                      . "PROTOTYPE-SYMBOL"))
                                                  (:CONS
                                                   (:CONS
                                                    (:COMMON-LISP-SYMBOL
                                                     #A((3) BASE-CHAR . "NOT"))
                                                    (:CONS
                                                     (:CONS
                                                      (:COMMON-LISP-SYMBOL
                                                       #A((4) BASE-CHAR
                                                          . "NULL"))
                                                      (:CONS
                                                       (:CONS
                                                        (:COMMON-LISP-SYMBOL
                                                         #A((10) BASE-CHAR
                                                            . "FIND-CLASS"))
                                                        (:CONS
                                                         (:SYMBOL
                                                          #A((16) BASE-CHAR
                                                             . "COMMON-LISP-USER")
                                                          #A((16) BASE-CHAR
                                                             . "PROTOTYPE-SYMBOL"))
                                                         (:CONS (:NULL)
                                                          (:NULL))))
                                                       (:NULL)))
                                                     (:NULL)))
                                                   (:NULL))))
                                                (:CONS
                                                 (:KEYWORD
                                                  #A((24) BASE-CHAR
                                                     . "ACTIVATION-STILL-BOUND-P"))
                                                 (:CONS
                                                  (:CONS
                                                   (:COMMON-LISP-SYMBOL
                                                    #A((3) BASE-CHAR . "AND"))
                                                   (:CONS
                                                    (:SYMBOL
                                                     #A((16) BASE-CHAR
                                                        . "COMMON-LISP-USER")
                                                     #A((17) BASE-CHAR
                                                        . "ACTIVATION-SYMBOL"))
                                                    (:CONS
                                                     (:CONS
                                                      (:COMMON-LISP-SYMBOL
                                                       #A((6) BASE-CHAR
                                                          . "BOUNDP"))
                                                      (:CONS
                                                       (:SYMBOL
                                                        #A((16) BASE-CHAR
                                                           . "COMMON-LISP-USER")
                                                        #A((17) BASE-CHAR
                                                           . "ACTIVATION-SYMBOL"))
                                                       (:NULL)))
                                                     (:NULL))))
                                                  (:CONS
                                                   (:KEYWORD
                                                    #A((9) BASE-CHAR
                                                       . "NEXT-FORM"))
                                                   (:CONS
                                                    (:CONS
                                                     (:COMMON-LISP-SYMBOL
                                                      #A((4) BASE-CHAR
                                                         . "LIST"))
                                                     (:CONS
                                                      (:CONS
                                                       (:COMMON-LISP-SYMBOL
                                                        #A((5) BASE-CHAR
                                                           . "QUOTE"))
                                                       (:CONS
                                                        (:SYMBOL
                                                         #A((16) BASE-CHAR
                                                            . "DREYECK/WORKFLOW")
                                                         "AUDIT")
                                                        (:NULL)))
                                                      (:CONS
                                                       (:SYMBOL
                                                        #A((16) BASE-CHAR
                                                           . "COMMON-LISP-USER")
                                                        #A((7) BASE-CHAR
                                                           . "SUBJECT"))
                                                       (:NULL))))
                                                    (:NULL))))))))))))))))))
                                   (:NULL))))))
                              (:NULL)))
                            (:NULL))))
                         (:NULL))))
                      (:NULL)))))
                  (:NULL))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:VERIFY :PART :DEFINITION)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:VERIFY :PART :DEFINITION) :OPERATION
            DREYECK/WORKFLOW:VERIFY :CONSTRUCTION :DEFINITION-SUFFICIENT :ROLE
            :DEFINITION :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "VERIFY")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((10) BASE-CHAR . "DEFINITION")) (:NULL)))))
             :CONSTRUCTION :DEFINITION-SUFFICIENT :ROLE :DEFINITION
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                          #A((9) BASE-CHAR . "OPERATION"))
                         (:NULL))
                        (:CONS
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "LET*"))
                          (:CONS
                           (:CONS
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((5) BASE-CHAR . "OFFER"))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((7) BASE-CHAR . "FUNCALL"))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((15) BASE-CHAR . "SYMBOL-FUNCTION"))
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((9) BASE-CHAR . "OPERATION"))
                                  (:NULL)))
                                (:CONS (:KEYWORD #A((7) BASE-CHAR . "CATALOG"))
                                 (:CONS (:STRING "related-topics-for-topic")
                                  (:NULL)))))
                              (:NULL)))
                            (:CONS
                             (:CONS
                              (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                               #A((14) BASE-CHAR . "WORKSPACE-SLOT"))
                              (:CONS
                               (:CONS
                                (:COMMON-LISP-SYMBOL
                                 #A((4) BASE-CHAR . "FIND"))
                                (:CONS (:STRING "WORKSPACE")
                                 (:CONS
                                  (:CONS
                                   (:SYMBOL #A((6) BASE-CHAR . "SB-MOP")
                                    #A((11) BASE-CHAR . "CLASS-SLOTS"))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((8) BASE-CHAR . "CLASS-OF"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((5) BASE-CHAR . "OFFER"))
                                      (:NULL)))
                                    (:NULL)))
                                  (:CONS (:KEYWORD #A((3) BASE-CHAR . "KEY"))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((6) BASE-CHAR . "LAMBDA"))
                                     (:CONS
                                      (:CONS
                                       (:SYMBOL #A((8) BASE-CHAR . "SB-ALIEN")
                                        #A((4) BASE-CHAR . "SLOT"))
                                       (:NULL))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((11) BASE-CHAR . "SYMBOL-NAME"))
                                        (:CONS
                                         (:CONS
                                          (:SYMBOL #A((6) BASE-CHAR . "SB-MOP")
                                           #A((20) BASE-CHAR
                                              . "SLOT-DEFINITION-NAME"))
                                          (:CONS
                                           (:SYMBOL
                                            #A((8) BASE-CHAR . "SB-ALIEN")
                                            #A((4) BASE-CHAR . "SLOT"))
                                           (:NULL)))
                                         (:NULL)))
                                       (:NULL))))
                                    (:CONS
                                     (:KEYWORD #A((4) BASE-CHAR . "TEST"))
                                     (:CONS
                                      (:CONS
                                       (:COMMON-LISP-SYMBOL
                                        #A((8) BASE-CHAR . "FUNCTION"))
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((7) BASE-CHAR . "STRING="))
                                        (:NULL)))
                                      (:NULL))))))))
                               (:NULL)))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((7) BASE-CHAR . "PACKAGE"))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((12) BASE-CHAR . "FIND-PACKAGE"))
                                 (:CONS (:STRING "DREYECK/WORKFLOW") (:NULL)))
                                (:NULL)))
                              (:CONS
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((12) BASE-CHAR . "FRESH-VERIFY"))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((6) BASE-CHAR . "INTERN"))
                                  (:CONS (:STRING "FRESH-VERIFY")
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((7) BASE-CHAR . "PACKAGE"))
                                    (:NULL))))
                                 (:NULL)))
                               (:NULL)))))
                           (:CONS
                            (:CONS
                             (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "EXPORT"))
                             (:CONS
                              (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                               #A((12) BASE-CHAR . "FRESH-VERIFY"))
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((7) BASE-CHAR . "PACKAGE"))
                               (:NULL))))
                            (:CONS
                             (:CONS
                              (:COMMON-LISP-SYMBOL
                               #A((6) BASE-CHAR . "ASSERT"))
                              (:CONS
                               (:CONS
                                (:COMMON-LISP-SYMBOL
                                 #A((6) BASE-CHAR . "MEMBER"))
                                (:CONS
                                 (:SYMBOL
                                  #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                  #A((5) BASE-CHAR . "OFFER"))
                                 (:CONS
                                  (:CONS
                                   (:SYMBOL #A((9) BASE-CHAR . "HYPERBOOK")
                                    #A((13) BASE-CHAR . "HYPERBOOKS-OF"))
                                   (:CONS
                                    (:SYMBOL #A((9) BASE-CHAR . "HYPERBOOK")
                                     #A((9) BASE-CHAR . "*CATALOG*"))
                                    (:NULL)))
                                  (:CONS (:KEYWORD #A((4) BASE-CHAR . "TEST"))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((8) BASE-CHAR . "FUNCTION"))
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((2) BASE-CHAR . "EQ"))
                                      (:NULL)))
                                    (:NULL))))))
                               (:NULL)))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((6) BASE-CHAR . "ASSERT"))
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((14) BASE-CHAR . "WORKSPACE-SLOT"))
                                (:NULL)))
                              (:CONS
                               (:CONS
                                (:COMMON-LISP-SYMBOL
                                 #A((6) BASE-CHAR . "ASSERT"))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((3) BASE-CHAR . "NOT"))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((11) BASE-CHAR . "SLOT-BOUNDP"))
                                    (:CONS
                                     (:SYMBOL
                                      #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                      #A((5) BASE-CHAR . "OFFER"))
                                     (:CONS
                                      (:CONS
                                       (:SYMBOL #A((6) BASE-CHAR . "SB-MOP")
                                        #A((20) BASE-CHAR
                                           . "SLOT-DEFINITION-NAME"))
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((14) BASE-CHAR . "WORKSPACE-SLOT"))
                                        (:NULL)))
                                      (:NULL))))
                                   (:NULL)))
                                 (:NULL)))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((4) BASE-CHAR . "LIST"))
                                 (:CONS (:KEYWORD #A((6) BASE-CHAR . "STATUS"))
                                  (:CONS
                                   (:KEYWORD #A((8) BASE-CHAR . "VERIFIED"))
                                   (:CONS
                                    (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
                                    (:CONS
                                     (:SYMBOL
                                      #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                      #A((9) BASE-CHAR . "OPERATION"))
                                     (:CONS
                                      (:KEYWORD #A((5) BASE-CHAR . "OFFER"))
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((5) BASE-CHAR . "OFFER"))
                                       (:CONS
                                        (:KEYWORD
                                         #A((24) BASE-CHAR
                                            . "WORKSPACE-MATERIALIZED-P"))
                                        (:CONS (:NULL)
                                         (:CONS
                                          (:KEYWORD
                                           #A((9) BASE-CHAR . "NEXT-FORM"))
                                          (:CONS
                                           (:CONS
                                            (:COMMON-LISP-SYMBOL
                                             #A((4) BASE-CHAR . "LIST"))
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((12) BASE-CHAR
                                                 . "FRESH-VERIFY"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((9) BASE-CHAR . "OPERATION"))
                                              (:NULL))))
                                           (:NULL))))))))))))
                                (:NULL))))))))
                         (:NULL))))
                      (:NULL)))))
                  (:NULL))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:ADMIT :PART :FORWARDER)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:ADMIT :PART :FORWARDER) :OPERATION
            DREYECK/WORKFLOW:ADMIT :CONSTRUCTION :FORWARDING-CLOSURE :ROLE
            :FORWARDER :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "ADMIT")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((9) BASE-CHAR . "FORWARDER")) (:NULL)))))
             :CONSTRUCTION :FORWARDING-CLOSURE :ROLE :FORWARDER
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "&REST"))
                         (:CONS
                          (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                           #A((9) BASE-CHAR . "ARGUMENTS"))
                          (:NULL)))
                        (:CONS
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "APPLY"))
                          (:CONS
                           (:CONS
                            (:COMMON-LISP-SYMBOL
                             #A((15) BASE-CHAR . "SYMBOL-FUNCTION"))
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((17) BASE-CHAR . "PERSISTENT-SYMBOL"))
                             (:NULL)))
                           (:CONS
                            (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                             #A((9) BASE-CHAR . "ARGUMENTS"))
                            (:NULL))))
                         (:NULL))))
                      (:NULL)))))
                  (:CONS
                   (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                    (:CONS (:KEYWORD #A((17) BASE-CHAR . "AUTHORITY-BINDING"))
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                      (:CONS
                       (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                        #A((17) BASE-CHAR . "PERSISTENT-SYMBOL"))
                       (:NULL)))))
                   (:NULL)))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:FRESH-TEST :PART :FORWARDER)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:FRESH-TEST :PART :FORWARDER)
            :OPERATION DREYECK/WORKFLOW:FRESH-TEST :CONSTRUCTION
            :FORWARDING-CLOSURE :ROLE :FORWARDER :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS
               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "FRESH-TEST")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((9) BASE-CHAR . "FORWARDER")) (:NULL)))))
             :CONSTRUCTION :FORWARDING-CLOSURE :ROLE :FORWARDER
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                          #A((17) BASE-CHAR . "SYSTEM-DESIGNATOR"))
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "&REST"))
                          (:CONS
                           (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                            #A((9) BASE-CHAR . "ARGUMENTS"))
                           (:NULL))))
                        (:CONS
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "APPLY"))
                          (:CONS
                           (:CONS
                            (:COMMON-LISP-SYMBOL
                             #A((15) BASE-CHAR . "SYMBOL-FUNCTION"))
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((27) BASE-CHAR
                                 . "FRESH-TEST-OPERATION-SYMBOL"))
                             (:NULL)))
                           (:CONS
                            (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                             #A((17) BASE-CHAR . "SYSTEM-DESIGNATOR"))
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((9) BASE-CHAR . "ARGUMENTS"))
                             (:NULL)))))
                         (:NULL))))
                      (:NULL)))))
                  (:CONS
                   (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                    (:CONS (:KEYWORD #A((17) BASE-CHAR . "AUTHORITY-BINDING"))
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                      (:CONS
                       (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                        #A((27) BASE-CHAR . "FRESH-TEST-OPERATION-SYMBOL"))
                       (:NULL)))))
                   (:NULL)))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:AUDIT :PART :BASE-DEFINITION)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:AUDIT :PART :BASE-DEFINITION)
            :OPERATION DREYECK/WORKFLOW:AUDIT :CONSTRUCTION
            :GUARDED-OPERATION-EXTENSION :ROLE :BASE-DEFINITION :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "AUDIT")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((15) BASE-CHAR . "BASE-DEFINITION"))
                 (:NULL)))))
             :CONSTRUCTION :GUARDED-OPERATION-EXTENSION :ROLE :BASE-DEFINITION
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((11) BASE-CHAR . "LAMBDA-LIST"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS
                       (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                        #A((7) BASE-CHAR . "SUBJECT"))
                       (:NULL))
                      (:NULL)))))
                  (:CONS
                   (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                    (:CONS
                     (:KEYWORD #A((22) BASE-CHAR . "BASE-LAMBDA-EXPRESSION"))
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                      (:CONS
                       (:CONS
                        (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                        (:CONS
                         (:CONS
                          (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                           #A((7) BASE-CHAR . "SUBJECT"))
                          (:NULL))
                         (:CONS
                          (:CONS
                           (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "ECASE"))
                           (:CONS
                            (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                             #A((7) BASE-CHAR . "SUBJECT"))
                            (:CONS
                             (:CONS
                              (:KEYWORD
                               #A((22) BASE-CHAR . "OFFER-ACTIVATION-SLICE"))
                              (:CONS
                               (:CONS
                                (:COMMON-LISP-SYMBOL
                                 #A((6) BASE-CHAR . "LABELS"))
                                (:CONS
                                 (:CONS
                                  (:CONS
                                   (:SYMBOL
                                    #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                    #A((9) BASE-CHAR . "SOURCE-OF"))
                                   (:CONS
                                    (:CONS
                                     (:SYMBOL
                                      #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                      #A((6) BASE-CHAR . "OBJECT"))
                                     (:NULL))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((3) BASE-CHAR . "LET"))
                                      (:CONS
                                       (:CONS
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((6) BASE-CHAR . "SOURCE"))
                                         (:CONS
                                          (:CONS
                                           (:COMMON-LISP-SYMBOL
                                            #A((12) BASE-CHAR
                                               . "HANDLER-CASE"))
                                           (:CONS
                                            (:CONS
                                             (:SYMBOL
                                              #A((13) BASE-CHAR
                                                 . "SB-INTROSPECT")
                                              #A((22) BASE-CHAR
                                                 . "FIND-DEFINITION-SOURCE"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((6) BASE-CHAR . "OBJECT"))
                                              (:NULL)))
                                            (:CONS
                                             (:CONS
                                              (:COMMON-LISP-SYMBOL
                                               #A((5) BASE-CHAR . "ERROR"))
                                              (:CONS (:NULL)
                                               (:CONS (:NULL) (:NULL))))
                                             (:NULL))))
                                          (:NULL)))
                                        (:NULL))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((3) BASE-CHAR . "AND"))
                                         (:CONS
                                          (:SYMBOL
                                           #A((16) BASE-CHAR
                                              . "COMMON-LISP-USER")
                                           #A((6) BASE-CHAR . "SOURCE"))
                                          (:CONS
                                           (:CONS
                                            (:COMMON-LISP-SYMBOL
                                             #A((12) BASE-CHAR
                                                . "HANDLER-CASE"))
                                            (:CONS
                                             (:CONS
                                              (:SYMBOL
                                               #A((13) BASE-CHAR
                                                  . "SB-INTROSPECT")
                                               #A((26) BASE-CHAR
                                                  . "DEFINITION-SOURCE-PATHNAME"))
                                              (:CONS
                                               (:SYMBOL
                                                #A((16) BASE-CHAR
                                                   . "COMMON-LISP-USER")
                                                #A((6) BASE-CHAR . "SOURCE"))
                                               (:NULL)))
                                             (:CONS
                                              (:CONS
                                               (:COMMON-LISP-SYMBOL
                                                #A((5) BASE-CHAR . "ERROR"))
                                               (:CONS (:NULL)
                                                (:CONS (:NULL) (:NULL))))
                                              (:NULL))))
                                           (:NULL))))
                                        (:NULL))))
                                     (:NULL))))
                                  (:NULL))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((4) BASE-CHAR . "LET*"))
                                   (:CONS
                                    (:CONS
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((12) BASE-CHAR . "OFFER-SYMBOL"))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((11) BASE-CHAR . "FIND-SYMBOL"))
                                        (:CONS
                                         (:STRING
                                          "PAGE-ATTACHED-WORKSPACE-OFFER")
                                         (:CONS
                                          (:STRING
                                           "DREYECK/PAGE-ATTACHED-WORKSPACE-OFFER")
                                          (:NULL))))
                                       (:NULL)))
                                     (:CONS
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((11) BASE-CHAR . "OFFER-CLASS"))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((3) BASE-CHAR . "AND"))
                                         (:CONS
                                          (:SYMBOL
                                           #A((16) BASE-CHAR
                                              . "COMMON-LISP-USER")
                                           #A((12) BASE-CHAR . "OFFER-SYMBOL"))
                                          (:CONS
                                           (:CONS
                                            (:COMMON-LISP-SYMBOL
                                             #A((10) BASE-CHAR . "FIND-CLASS"))
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((12) BASE-CHAR
                                                 . "OFFER-SYMBOL"))
                                             (:CONS (:NULL) (:NULL))))
                                           (:NULL))))
                                        (:NULL)))
                                      (:CONS
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((12) BASE-CHAR . "OFFER-SOURCE"))
                                        (:CONS
                                         (:CONS
                                          (:COMMON-LISP-SYMBOL
                                           #A((3) BASE-CHAR . "AND"))
                                          (:CONS
                                           (:SYMBOL
                                            #A((16) BASE-CHAR
                                               . "COMMON-LISP-USER")
                                            #A((11) BASE-CHAR . "OFFER-CLASS"))
                                           (:CONS
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((9) BASE-CHAR . "SOURCE-OF"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((11) BASE-CHAR
                                                  . "OFFER-CLASS"))
                                              (:NULL)))
                                            (:NULL))))
                                         (:NULL)))
                                       (:CONS
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((16) BASE-CHAR
                                             . "PROTOTYPE-SYMBOL"))
                                         (:CONS
                                          (:CONS
                                           (:COMMON-LISP-SYMBOL
                                            #A((11) BASE-CHAR . "FIND-SYMBOL"))
                                           (:CONS
                                            (:STRING
                                             "REPAIR-WORKSPACE-HYPERBOOK")
                                            (:CONS (:STRING "CL-USER")
                                             (:NULL))))
                                          (:NULL)))
                                        (:CONS
                                         (:CONS
                                          (:SYMBOL
                                           #A((16) BASE-CHAR
                                              . "COMMON-LISP-USER")
                                           #A((15) BASE-CHAR
                                              . "PROTOTYPE-CLASS"))
                                          (:CONS
                                           (:CONS
                                            (:COMMON-LISP-SYMBOL
                                             #A((3) BASE-CHAR . "AND"))
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((16) BASE-CHAR
                                                 . "PROTOTYPE-SYMBOL"))
                                             (:CONS
                                              (:CONS
                                               (:COMMON-LISP-SYMBOL
                                                #A((10) BASE-CHAR
                                                   . "FIND-CLASS"))
                                               (:CONS
                                                (:SYMBOL
                                                 #A((16) BASE-CHAR
                                                    . "COMMON-LISP-USER")
                                                 #A((16) BASE-CHAR
                                                    . "PROTOTYPE-SYMBOL"))
                                                (:CONS (:NULL) (:NULL))))
                                              (:NULL))))
                                           (:NULL)))
                                         (:CONS
                                          (:CONS
                                           (:SYMBOL
                                            #A((16) BASE-CHAR
                                               . "COMMON-LISP-USER")
                                            #A((16) BASE-CHAR
                                               . "PROTOTYPE-SOURCE"))
                                           (:CONS
                                            (:CONS
                                             (:COMMON-LISP-SYMBOL
                                              #A((3) BASE-CHAR . "AND"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((15) BASE-CHAR
                                                  . "PROTOTYPE-CLASS"))
                                              (:CONS
                                               (:CONS
                                                (:SYMBOL
                                                 #A((16) BASE-CHAR
                                                    . "COMMON-LISP-USER")
                                                 #A((9) BASE-CHAR
                                                    . "SOURCE-OF"))
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((16) BASE-CHAR
                                                     . "COMMON-LISP-USER")
                                                  #A((15) BASE-CHAR
                                                     . "PROTOTYPE-CLASS"))
                                                 (:NULL)))
                                               (:NULL))))
                                            (:NULL)))
                                          (:CONS
                                           (:CONS
                                            (:SYMBOL
                                             #A((16) BASE-CHAR
                                                . "COMMON-LISP-USER")
                                             #A((17) BASE-CHAR
                                                . "ACTIVATION-SYMBOL"))
                                            (:CONS
                                             (:CONS
                                              (:COMMON-LISP-SYMBOL
                                               #A((11) BASE-CHAR
                                                  . "FIND-SYMBOL"))
                                              (:CONS
                                               (:STRING
                                                "*CONVERSATION-10666-LIVE-ACTIVATION-OPERATION*")
                                               (:CONS (:STRING "CL-USER")
                                                (:NULL))))
                                             (:NULL)))
                                           (:CONS
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((10) BASE-CHAR
                                                 . "ACTIVATION"))
                                             (:CONS
                                              (:CONS
                                               (:COMMON-LISP-SYMBOL
                                                #A((3) BASE-CHAR . "AND"))
                                               (:CONS
                                                (:SYMBOL
                                                 #A((16) BASE-CHAR
                                                    . "COMMON-LISP-USER")
                                                 #A((17) BASE-CHAR
                                                    . "ACTIVATION-SYMBOL"))
                                                (:CONS
                                                 (:CONS
                                                  (:COMMON-LISP-SYMBOL
                                                   #A((6) BASE-CHAR
                                                      . "BOUNDP"))
                                                  (:CONS
                                                   (:SYMBOL
                                                    #A((16) BASE-CHAR
                                                       . "COMMON-LISP-USER")
                                                    #A((17) BASE-CHAR
                                                       . "ACTIVATION-SYMBOL"))
                                                   (:NULL)))
                                                 (:CONS
                                                  (:CONS
                                                   (:COMMON-LISP-SYMBOL
                                                    #A((12) BASE-CHAR
                                                       . "SYMBOL-VALUE"))
                                                   (:CONS
                                                    (:SYMBOL
                                                     #A((16) BASE-CHAR
                                                        . "COMMON-LISP-USER")
                                                     #A((17) BASE-CHAR
                                                        . "ACTIVATION-SYMBOL"))
                                                    (:NULL)))
                                                  (:NULL)))))
                                              (:NULL)))
                                            (:CONS
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((17) BASE-CHAR
                                                  . "ACTIVATION-SOURCE"))
                                              (:CONS
                                               (:CONS
                                                (:COMMON-LISP-SYMBOL
                                                 #A((3) BASE-CHAR . "AND"))
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((16) BASE-CHAR
                                                     . "COMMON-LISP-USER")
                                                  #A((10) BASE-CHAR
                                                     . "ACTIVATION"))
                                                 (:CONS
                                                  (:CONS
                                                   (:SYMBOL
                                                    #A((16) BASE-CHAR
                                                       . "COMMON-LISP-USER")
                                                    #A((9) BASE-CHAR
                                                       . "SOURCE-OF"))
                                                   (:CONS
                                                    (:SYMBOL
                                                     #A((16) BASE-CHAR
                                                        . "COMMON-LISP-USER")
                                                     #A((10) BASE-CHAR
                                                        . "ACTIVATION"))
                                                    (:NULL)))
                                                  (:NULL))))
                                               (:NULL)))
                                             (:CONS
                                              (:CONS
                                               (:SYMBOL
                                                #A((16) BASE-CHAR
                                                   . "COMMON-LISP-USER")
                                                #A((13) BASE-CHAR
                                                   . "HYPERBOOK-ASD"))
                                               (:CONS
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((11) BASE-CHAR
                                                     . "ASDF/SYSTEM")
                                                  "SYSTEM-SOURCE-FILE")
                                                 (:CONS
                                                  (:CONS
                                                   (:SYMBOL
                                                    #A((11) BASE-CHAR
                                                       . "ASDF/SYSTEM")
                                                    "FIND-SYSTEM")
                                                   (:CONS (:STRING "hyperbook")
                                                    (:NULL)))
                                                  (:NULL)))
                                                (:NULL)))
                                              (:CONS
                                               (:CONS
                                                (:SYMBOL
                                                 #A((16) BASE-CHAR
                                                    . "COMMON-LISP-USER")
                                                 #A((8) BASE-CHAR
                                                    . "PAGE-ASD"))
                                                (:CONS
                                                 (:CONS
                                                  (:SYMBOL
                                                   #A((11) BASE-CHAR
                                                      . "ASDF/SYSTEM")
                                                   "SYSTEM-SOURCE-FILE")
                                                  (:CONS
                                                   (:CONS
                                                    (:SYMBOL
                                                     #A((11) BASE-CHAR
                                                        . "ASDF/SYSTEM")
                                                     "FIND-SYSTEM")
                                                    (:CONS
                                                     (:STRING
                                                      "related-topics-for-topic")
                                                     (:NULL)))
                                                   (:NULL)))
                                                 (:NULL)))
                                               (:CONS
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((16) BASE-CHAR
                                                     . "COMMON-LISP-USER")
                                                  #A((12) BASE-CHAR
                                                     . "FRESH-RESULT"))
                                                 (:CONS
                                                  (:CONS
                                                   (:SYMBOL
                                                    #A((16) BASE-CHAR
                                                       . "DREYECK/WORKFLOW")
                                                    "FRESH-TEST")
                                                   (:CONS
                                                    (:STRING
                                                     "dreyeck/page-attached-workspace-offer/tests")
                                                    (:CONS
                                                     (:KEYWORD
                                                      #A((15) BASE-CHAR
                                                         . "ADDITIONAL-ASDS"))
                                                     (:CONS
                                                      (:CONS
                                                       (:COMMON-LISP-SYMBOL
                                                        #A((4) BASE-CHAR
                                                           . "LIST"))
                                                       (:CONS
                                                        (:SYMBOL
                                                         #A((16) BASE-CHAR
                                                            . "COMMON-LISP-USER")
                                                         #A((13) BASE-CHAR
                                                            . "HYPERBOOK-ASD"))
                                                        (:CONS
                                                         (:SYMBOL
                                                          #A((16) BASE-CHAR
                                                             . "COMMON-LISP-USER")
                                                          #A((8) BASE-CHAR
                                                             . "PAGE-ASD"))
                                                         (:NULL))))
                                                      (:NULL)))))
                                                  (:NULL)))
                                                (:CONS
                                                 (:CONS
                                                  (:SYMBOL
                                                   #A((16) BASE-CHAR
                                                      . "COMMON-LISP-USER")
                                                   #A((18) BASE-CHAR
                                                      . "LEGACY-LIVE-ONLY-P"))
                                                  (:CONS
                                                   (:CONS
                                                    (:COMMON-LISP-SYMBOL
                                                     #A((2) BASE-CHAR . "OR"))
                                                    (:CONS
                                                     (:CONS
                                                      (:COMMON-LISP-SYMBOL
                                                       #A((3) BASE-CHAR
                                                          . "AND"))
                                                      (:CONS
                                                       (:SYMBOL
                                                        #A((16) BASE-CHAR
                                                           . "COMMON-LISP-USER")
                                                        #A((15) BASE-CHAR
                                                           . "PROTOTYPE-CLASS"))
                                                       (:CONS
                                                        (:CONS
                                                         (:COMMON-LISP-SYMBOL
                                                          #A((4) BASE-CHAR
                                                             . "NULL"))
                                                         (:CONS
                                                          (:SYMBOL
                                                           #A((16) BASE-CHAR
                                                              . "COMMON-LISP-USER")
                                                           #A((16) BASE-CHAR
                                                              . "PROTOTYPE-SOURCE"))
                                                          (:NULL)))
                                                        (:NULL))))
                                                     (:CONS
                                                      (:CONS
                                                       (:COMMON-LISP-SYMBOL
                                                        #A((3) BASE-CHAR
                                                           . "AND"))
                                                       (:CONS
                                                        (:SYMBOL
                                                         #A((16) BASE-CHAR
                                                            . "COMMON-LISP-USER")
                                                         #A((10) BASE-CHAR
                                                            . "ACTIVATION"))
                                                        (:CONS
                                                         (:CONS
                                                          (:COMMON-LISP-SYMBOL
                                                           #A((4) BASE-CHAR
                                                              . "NULL"))
                                                          (:CONS
                                                           (:SYMBOL
                                                            #A((16) BASE-CHAR
                                                               . "COMMON-LISP-USER")
                                                            #A((17) BASE-CHAR
                                                               . "ACTIVATION-SOURCE"))
                                                           (:NULL)))
                                                         (:NULL))))
                                                      (:NULL))))
                                                   (:NULL)))
                                                 (:NULL))))))))))))))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((6) BASE-CHAR . "ASSERT"))
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((11) BASE-CHAR . "OFFER-CLASS"))
                                       (:NULL)))
                                     (:CONS
                                      (:CONS
                                       (:COMMON-LISP-SYMBOL
                                        #A((6) BASE-CHAR . "ASSERT"))
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((12) BASE-CHAR . "OFFER-SOURCE"))
                                        (:NULL)))
                                      (:CONS
                                       (:CONS
                                        (:COMMON-LISP-SYMBOL
                                         #A((6) BASE-CHAR . "ASSERT"))
                                        (:CONS
                                         (:CONS
                                          (:COMMON-LISP-SYMBOL
                                           #A((2) BASE-CHAR . "EQ"))
                                          (:CONS
                                           (:KEYWORD
                                            #A((6) BASE-CHAR . "PASSED"))
                                           (:CONS
                                            (:CONS
                                             (:COMMON-LISP-SYMBOL
                                              #A((4) BASE-CHAR . "GETF"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((12) BASE-CHAR
                                                  . "FRESH-RESULT"))
                                              (:CONS
                                               (:KEYWORD
                                                #A((6) BASE-CHAR . "STATUS"))
                                               (:NULL))))
                                            (:NULL))))
                                         (:NULL)))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((4) BASE-CHAR . "LIST"))
                                         (:CONS
                                          (:KEYWORD
                                           #A((7) BASE-CHAR . "SUBJECT"))
                                          (:CONS
                                           (:SYMBOL
                                            #A((16) BASE-CHAR
                                               . "COMMON-LISP-USER")
                                            #A((7) BASE-CHAR . "SUBJECT"))
                                           (:CONS
                                            (:KEYWORD
                                             #A((15) BASE-CHAR
                                                . "CANONICAL-OFFER"))
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((11) BASE-CHAR
                                                 . "OFFER-CLASS"))
                                             (:CONS
                                              (:KEYWORD
                                               #A((22) BASE-CHAR
                                                  . "CANONICAL-OFFER-SOURCE"))
                                              (:CONS
                                               (:SYMBOL
                                                #A((16) BASE-CHAR
                                                   . "COMMON-LISP-USER")
                                                #A((12) BASE-CHAR
                                                   . "OFFER-SOURCE"))
                                               (:CONS
                                                (:KEYWORD
                                                 #A((12) BASE-CHAR
                                                    . "FRESH-RESULT"))
                                                (:CONS
                                                 (:SYMBOL
                                                  #A((16) BASE-CHAR
                                                     . "COMMON-LISP-USER")
                                                  #A((12) BASE-CHAR
                                                     . "FRESH-RESULT"))
                                                 (:CONS
                                                  (:KEYWORD
                                                   #A((16) BASE-CHAR
                                                      . "LEGACY-PROTOTYPE"))
                                                  (:CONS
                                                   (:SYMBOL
                                                    #A((16) BASE-CHAR
                                                       . "COMMON-LISP-USER")
                                                    #A((15) BASE-CHAR
                                                       . "PROTOTYPE-CLASS"))
                                                   (:CONS
                                                    (:KEYWORD
                                                     #A((23) BASE-CHAR
                                                        . "LEGACY-PROTOTYPE-SOURCE"))
                                                    (:CONS
                                                     (:SYMBOL
                                                      #A((16) BASE-CHAR
                                                         . "COMMON-LISP-USER")
                                                      #A((16) BASE-CHAR
                                                         . "PROTOTYPE-SOURCE"))
                                                     (:CONS
                                                      (:KEYWORD
                                                       #A((17) BASE-CHAR
                                                          . "LEGACY-ACTIVATION"))
                                                      (:CONS
                                                       (:SYMBOL
                                                        #A((16) BASE-CHAR
                                                           . "COMMON-LISP-USER")
                                                        #A((10) BASE-CHAR
                                                           . "ACTIVATION"))
                                                       (:CONS
                                                        (:KEYWORD
                                                         #A((24) BASE-CHAR
                                                            . "LEGACY-ACTIVATION-SOURCE"))
                                                        (:CONS
                                                         (:SYMBOL
                                                          #A((16) BASE-CHAR
                                                             . "COMMON-LISP-USER")
                                                          #A((17) BASE-CHAR
                                                             . "ACTIVATION-SOURCE"))
                                                         (:CONS
                                                          (:KEYWORD
                                                           #A((18) BASE-CHAR
                                                              . "LEGACY-LIVE-ONLY-P"))
                                                          (:CONS
                                                           (:SYMBOL
                                                            #A((16) BASE-CHAR
                                                               . "COMMON-LISP-USER")
                                                            #A((18) BASE-CHAR
                                                               . "LEGACY-LIVE-ONLY-P"))
                                                           (:CONS
                                                            (:KEYWORD
                                                             #A((9) BASE-CHAR
                                                                . "NEXT-FORM"))
                                                            (:CONS
                                                             (:CONS
                                                              (:COMMON-LISP-SYMBOL
                                                               #A((2) BASE-CHAR
                                                                  . "IF"))
                                                              (:CONS
                                                               (:SYMBOL
                                                                #A((16)
                                                                   BASE-CHAR
                                                                   . "COMMON-LISP-USER")
                                                                #A((18)
                                                                   BASE-CHAR
                                                                   . "LEGACY-LIVE-ONLY-P"))
                                                               (:CONS
                                                                (:CONS
                                                                 (:COMMON-LISP-SYMBOL
                                                                  #A((4)
                                                                     BASE-CHAR
                                                                     . "LIST"))
                                                                 (:CONS
                                                                  (:CONS
                                                                   (:COMMON-LISP-SYMBOL
                                                                    #A((5)
                                                                       BASE-CHAR
                                                                       . "QUOTE"))
                                                                   (:CONS
                                                                    (:SYMBOL
                                                                     #A((16)
                                                                        BASE-CHAR
                                                                        . "DREYECK/WORKFLOW")
                                                                     "RETIRE")
                                                                    (:NULL)))
                                                                  (:CONS
                                                                   (:SYMBOL
                                                                    #A((16)
                                                                       BASE-CHAR
                                                                       . "COMMON-LISP-USER")
                                                                    #A((7)
                                                                       BASE-CHAR
                                                                       . "SUBJECT"))
                                                                   (:NULL))))
                                                                (:CONS
                                                                 (:CONS
                                                                  (:COMMON-LISP-SYMBOL
                                                                   #A((4)
                                                                      BASE-CHAR
                                                                      . "LIST"))
                                                                  (:CONS
                                                                   (:CONS
                                                                    (:COMMON-LISP-SYMBOL
                                                                     #A((5)
                                                                        BASE-CHAR
                                                                        . "QUOTE"))
                                                                    (:CONS
                                                                     (:SYMBOL
                                                                      #A((16)
                                                                         BASE-CHAR
                                                                         . "DREYECK/WORKFLOW")
                                                                      "AUDIT-COMPLETE")
                                                                     (:NULL)))
                                                                   (:CONS
                                                                    (:SYMBOL
                                                                     #A((16)
                                                                        BASE-CHAR
                                                                        . "COMMON-LISP-USER")
                                                                     #A((7)
                                                                        BASE-CHAR
                                                                        . "SUBJECT"))
                                                                    (:NULL))))
                                                                 (:NULL)))))
                                                             (:NULL))))))))))))))))))))))
                                        (:NULL)))))))
                                  (:NULL))))
                               (:NULL)))
                             (:NULL))))
                          (:NULL))))
                       (:NULL)))))
                   (:NULL)))
                 (:NULL))))))))
  (SETF (GETHASH
         '(:OPERATION DREYECK/WORKFLOW:COMMIT :PART :ADAPTER-DEFINITION)
         DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:COMMIT :PART :ADAPTER-DEFINITION)
            :OPERATION DREYECK/WORKFLOW:COMMIT :CONSTRUCTION
            :ADAPTER-FORWARDING :ROLE :ADAPTER-DEFINITION :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "COMMIT")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((18) BASE-CHAR . "ADAPTER-DEFINITION"))
                 (:NULL)))))
             :CONSTRUCTION :ADAPTER-FORWARDING :ROLE :ADAPTER-DEFINITION
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                       (:CONS
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                          #A((10) BASE-CHAR . "REPOSITORY"))
                         (:CONS
                          (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                           #A((5) BASE-CHAR . "FILES"))
                          (:CONS
                           (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                            #A((7) BASE-CHAR . "MESSAGE"))
                           (:NULL))))
                        (:CONS
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((7) BASE-CHAR . "FUNCALL"))
                          (:CONS
                           (:CONS
                            (:COMMON-LISP-SYMBOL
                             #A((15) BASE-CHAR . "SYMBOL-FUNCTION"))
                            (:CONS
                             (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                              #A((17) BASE-CHAR . "GIT-COMMIT-SYMBOL"))
                             (:NULL)))
                           (:CONS
                            (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                             #A((10) BASE-CHAR . "REPOSITORY"))
                            (:CONS
                             (:CONS
                              (:COMMON-LISP-SYMBOL
                               #A((6) BASE-CHAR . "MAPCAR"))
                              (:CONS
                               (:CONS
                                (:COMMON-LISP-SYMBOL
                                 #A((6) BASE-CHAR . "LAMBDA"))
                                (:CONS
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((4) BASE-CHAR . "FILE"))
                                  (:NULL))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((9) BASE-CHAR . "ETYPECASE"))
                                   (:CONS
                                    (:SYMBOL
                                     #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                     #A((4) BASE-CHAR . "FILE"))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((6) BASE-CHAR . "STRING"))
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((4) BASE-CHAR . "FILE"))
                                       (:NULL)))
                                     (:CONS
                                      (:CONS
                                       (:COMMON-LISP-SYMBOL
                                        #A((8) BASE-CHAR . "PATHNAME"))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((10) BASE-CHAR . "NAMESTRING"))
                                         (:CONS
                                          (:SYMBOL
                                           #A((16) BASE-CHAR
                                              . "COMMON-LISP-USER")
                                           #A((4) BASE-CHAR . "FILE"))
                                          (:NULL)))
                                        (:NULL)))
                                      (:NULL)))))
                                  (:NULL))))
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((5) BASE-CHAR . "FILES"))
                                (:NULL))))
                             (:CONS
                              (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                               #A((7) BASE-CHAR . "MESSAGE"))
                              (:NULL))))))
                         (:NULL))))
                      (:NULL)))))
                  (:CONS
                   (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                    (:CONS (:KEYWORD #A((17) BASE-CHAR . "AUTHORITY-BINDING"))
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                      (:CONS
                       (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                        #A((17) BASE-CHAR . "GIT-COMMIT-SYMBOL"))
                       (:NULL)))))
                   (:NULL)))
                 (:NULL))))))))
  (SETF (GETHASH
         '(:OPERATION DREYECK/WORKFLOW:PERSIST :PART :SUBJECT-TYPE-DISPATCH)
         DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:PERSIST :PART :SUBJECT-TYPE-DISPATCH)
            :OPERATION DREYECK/WORKFLOW:PERSIST :CONSTRUCTION
            :SUM-TYPE-DISPATCH :ROLE :SUBJECT-TYPE-DISPATCH :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS
               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "PERSIST")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((21) BASE-CHAR . "SUBJECT-TYPE-DISPATCH"))
                 (:NULL)))))
             :CONSTRUCTION :SUM-TYPE-DISPATCH :ROLE :SUBJECT-TYPE-DISPATCH
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((11) BASE-CHAR . "LAMBDA-LIST"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS
                       (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                        #A((7) BASE-CHAR . "SUBJECT"))
                       (:NULL))
                      (:NULL)))))
                  (:CONS
                   (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                    (:CONS (:KEYWORD #A((13) BASE-CHAR . "DISPATCH-FORM"))
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                      (:CONS
                       (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                        #A((7) BASE-CHAR . "SUBJECT"))
                       (:NULL)))))
                   (:NULL)))
                 (:NULL))))))))
  (SETF (GETHASH '(:OPERATION DREYECK/WORKFLOW:PERSIST :PART :SYMBOL-HANDLER)
                 DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:PERSIST :PART :SYMBOL-HANDLER)
            :OPERATION DREYECK/WORKFLOW:PERSIST :CONSTRUCTION
            :SUM-TYPE-DISPATCH :ROLE :SYMBOL-HANDLER :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS
               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "PERSIST")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((14) BASE-CHAR . "SYMBOL-HANDLER"))
                 (:NULL)))))
             :CONSTRUCTION :SUM-TYPE-DISPATCH :ROLE :SYMBOL-HANDLER
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((14) BASE-CHAR . "SYMBOL-HANDLER"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS
                       (:KEYWORD #A((17) BASE-CHAR . "LAMBDA-EXPRESSION"))
                       (:CONS
                        (:CONS
                         (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "LAMBDA"))
                         (:CONS
                          (:CONS
                           (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                            #A((9) BASE-CHAR . "OPERATION"))
                           (:NULL))
                          (:CONS
                           (:CONS
                            (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "LET*"))
                            (:CONS
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL
                                #A((8) BASE-CHAR . "FUNCTION"))
                               (:CONS
                                (:CONS
                                 (:COMMON-LISP-SYMBOL
                                  #A((15) BASE-CHAR . "SYMBOL-FUNCTION"))
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((9) BASE-CHAR . "OPERATION"))
                                  (:NULL)))
                                (:NULL)))
                              (:CONS
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((10) BASE-CHAR . "DEFINITION"))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((12) BASE-CHAR . "HANDLER-CASE"))
                                  (:CONS
                                   (:CONS
                                    (:SYMBOL
                                     #A((13) BASE-CHAR . "SB-INTROSPECT")
                                     #A((22) BASE-CHAR
                                        . "FIND-DEFINITION-SOURCE"))
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((8) BASE-CHAR . "FUNCTION"))
                                     (:NULL)))
                                   (:CONS
                                    (:CONS
                                     (:COMMON-LISP-SYMBOL
                                      #A((5) BASE-CHAR . "ERROR"))
                                     (:CONS (:NULL) (:CONS (:NULL) (:NULL))))
                                    (:NULL))))
                                 (:NULL)))
                               (:CONS
                                (:CONS
                                 (:SYMBOL
                                  #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                  #A((6) BASE-CHAR . "SOURCE"))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((3) BASE-CHAR . "AND"))
                                   (:CONS
                                    (:SYMBOL
                                     #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                     #A((10) BASE-CHAR . "DEFINITION"))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((12) BASE-CHAR . "HANDLER-CASE"))
                                      (:CONS
                                       (:CONS
                                        (:SYMBOL
                                         #A((13) BASE-CHAR . "SB-INTROSPECT")
                                         #A((26) BASE-CHAR
                                            . "DEFINITION-SOURCE-PATHNAME"))
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((10) BASE-CHAR . "DEFINITION"))
                                         (:NULL)))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((5) BASE-CHAR . "ERROR"))
                                         (:CONS (:NULL)
                                          (:CONS (:NULL) (:NULL))))
                                        (:NULL))))
                                     (:NULL))))
                                  (:NULL)))
                                (:NULL))))
                             (:CONS
                              (:CONS
                               (:COMMON-LISP-SYMBOL #A((2) BASE-CHAR . "IF"))
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((6) BASE-CHAR . "SOURCE"))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((4) BASE-CHAR . "LIST"))
                                  (:CONS
                                   (:KEYWORD #A((6) BASE-CHAR . "STATUS"))
                                   (:CONS
                                    (:KEYWORD
                                     #A((10) BASE-CHAR . "PERSISTENT"))
                                    (:CONS
                                     (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((9) BASE-CHAR . "OPERATION"))
                                      (:CONS
                                       (:KEYWORD #A((6) BASE-CHAR . "SOURCE"))
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((6) BASE-CHAR . "SOURCE"))
                                        (:NULL))))))))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((4) BASE-CHAR . "LIST"))
                                   (:CONS
                                    (:KEYWORD #A((6) BASE-CHAR . "STATUS"))
                                    (:CONS
                                     (:KEYWORD
                                      #A((16) BASE-CHAR . "NEEDS-ASSIGNMENT"))
                                     (:CONS
                                      (:KEYWORD
                                       #A((9) BASE-CHAR . "OPERATION"))
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((9) BASE-CHAR . "OPERATION"))
                                       (:CONS
                                        (:KEYWORD
                                         #A((9) BASE-CHAR . "NEXT-FORM"))
                                        (:CONS
                                         (:CONS
                                          (:COMMON-LISP-SYMBOL
                                           #A((4) BASE-CHAR . "LIST"))
                                          (:CONS
                                           (:SYMBOL
                                            #A((16) BASE-CHAR
                                               . "COMMON-LISP-USER")
                                            #A((6) BASE-CHAR . "ASSIGN"))
                                           (:CONS
                                            (:SYMBOL
                                             #A((16) BASE-CHAR
                                                . "COMMON-LISP-USER")
                                             #A((9) BASE-CHAR . "OPERATION"))
                                            (:NULL))))
                                         (:NULL))))))))
                                  (:NULL)))))
                              (:NULL))))
                           (:NULL))))
                        (:CONS
                         (:KEYWORD
                          #A((21) BASE-CHAR . "SOURCE-PRESENT-STATUS"))
                         (:CONS (:KEYWORD #A((10) BASE-CHAR . "PERSISTENT"))
                          (:CONS
                           (:KEYWORD
                            #A((20) BASE-CHAR . "SOURCE-ABSENT-STATUS"))
                           (:CONS
                            (:KEYWORD #A((16) BASE-CHAR . "NEEDS-ASSIGNMENT"))
                            (:CONS
                             (:KEYWORD
                              #A((20) BASE-CHAR . "CONTINUATION-BINDING"))
                             (:CONS
                              (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                               #A((6) BASE-CHAR . "ASSIGN"))
                              (:CONS
                               (:KEYWORD
                                #A((19) BASE-CHAR . "CONTINUATION-TARGET"))
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                                 "ASSIGN")
                                (:CONS
                                 (:KEYWORD
                                  #A((31) BASE-CHAR
                                     . "CONTINUATION-AUTHORITY-PROVED-P"))
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL #A((1) BASE-CHAR . "T"))
                                  (:CONS
                                   (:KEYWORD #A((8) BASE-CHAR . "RELATION"))
                                   (:CONS
                                    (:CONS
                                     (:KEYWORD #A((4) BASE-CHAR . "FROM"))
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                                       "PERSIST")
                                      (:CONS
                                       (:KEYWORD #A((4) BASE-CHAR . "WHEN"))
                                       (:CONS
                                        (:KEYWORD
                                         #A((31) BASE-CHAR
                                            . "SYMBOL-WITHOUT-SOURCE-AUTHORITY"))
                                        (:CONS
                                         (:KEYWORD
                                          #A((17) BASE-CHAR
                                             . "RETURNS-NEXT-FORM"))
                                         (:CONS
                                          (:CONS
                                           (:SYMBOL
                                            #A((16) BASE-CHAR
                                               . "DREYECK/WORKFLOW")
                                            "ASSIGN")
                                           (:CONS
                                            (:KEYWORD
                                             #A((9) BASE-CHAR . "OPERATION"))
                                            (:NULL)))
                                          (:NULL)))))))
                                    (:NULL)))))))))))))))
                      (:NULL)))))
                  (:CONS
                   (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                    (:CONS (:KEYWORD #A((13) BASE-CHAR . "SYMBOL-CLAUSE"))
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                      (:CONS
                       (:CONS
                        (:COMMON-LISP-SYMBOL #A((6) BASE-CHAR . "SYMBOL"))
                        (:CONS
                         (:CONS
                          (:COMMON-LISP-SYMBOL #A((7) BASE-CHAR . "FUNCALL"))
                          (:CONS
                           (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                            #A((17) BASE-CHAR . "PERSIST-OPERATION"))
                           (:CONS
                            (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                             #A((7) BASE-CHAR . "SUBJECT"))
                            (:NULL))))
                         (:NULL)))
                       (:NULL)))))
                   (:CONS
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                     (:CONS (:KEYWORD #A((17) BASE-CHAR . "AUTHORITY-BINDING"))
                      (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                       (:CONS
                        (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                         #A((6) BASE-CHAR . "ASSIGN"))
                        (:NULL)))))
                    (:CONS
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                      (:CONS (:KEYWORD #A((16) BASE-CHAR . "AUTHORITY-TARGET"))
                       (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                        (:CONS
                         (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW")
                          "ASSIGN")
                         (:NULL)))))
                     (:NULL)))))
                 (:NULL))))))))
  (SETF (GETHASH
         '(:OPERATION DREYECK/WORKFLOW:PERSIST :PART :CONS-KIND-DISPATCH)
         DREYECK/WORKFLOW::*WORKFLOW-FRAGMENT-REGISTRY*)
          '(:AUTHORITY-SYSTEM-NAME "dreyeck/workflow" :FRAGMENT-KEY
            (:OPERATION DREYECK/WORKFLOW:PERSIST :PART :CONS-KIND-DISPATCH)
            :OPERATION DREYECK/WORKFLOW:PERSIST :CONSTRUCTION
            :SUM-TYPE-DISPATCH :ROLE :CONS-KIND-DISPATCH :RECORD
            (:FRAGMENT-KEY
             (:CONS (:KEYWORD #A((9) BASE-CHAR . "OPERATION"))
              (:CONS
               (:SYMBOL #A((16) BASE-CHAR . "DREYECK/WORKFLOW") "PERSIST")
               (:CONS (:KEYWORD #A((4) BASE-CHAR . "PART"))
                (:CONS (:KEYWORD #A((18) BASE-CHAR . "CONS-KIND-DISPATCH"))
                 (:NULL)))))
             :CONSTRUCTION :SUM-TYPE-DISPATCH :ROLE :CONS-KIND-DISPATCH
             :SEMANTIC-CARRIER
             (:CONS (:KEYWORD #A((4) BASE-CHAR . "KIND"))
              (:CONS (:KEYWORD #A((9) BASE-CHAR . "FIELD-SET"))
               (:CONS (:KEYWORD #A((6) BASE-CHAR . "FIELDS"))
                (:CONS
                 (:CONS
                  (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                   (:CONS (:KEYWORD #A((11) BASE-CHAR . "CONS-CLAUSE"))
                    (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                     (:CONS
                      (:CONS (:COMMON-LISP-SYMBOL #A((4) BASE-CHAR . "CONS"))
                       (:CONS
                        (:CONS
                         (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "ECASE"))
                         (:CONS
                          (:CONS
                           (:COMMON-LISP-SYMBOL #A((5) BASE-CHAR . "FIRST"))
                           (:CONS
                            (:SYMBOL #A((16) BASE-CHAR . "COMMON-LISP-USER")
                             #A((7) BASE-CHAR . "SUBJECT"))
                            (:NULL)))
                          (:CONS
                           (:CONS
                            (:KEYWORD #A((15) BASE-CHAR . "ASDF-DEPENDENCY"))
                            (:CONS
                             (:CONS
                              (:COMMON-LISP-SYMBOL
                               #A((18) BASE-CHAR . "DESTRUCTURING-BIND"))
                              (:CONS
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((4) BASE-CHAR . "KIND"))
                                (:CONS
                                 (:SYMBOL
                                  #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                  #A((17) BASE-CHAR . "SYSTEM-DESIGNATOR"))
                                 (:CONS
                                  (:SYMBOL
                                   #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                   #A((21) BASE-CHAR
                                      . "DEPENDENCY-DESIGNATOR"))
                                  (:NULL))))
                               (:CONS
                                (:SYMBOL
                                 #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                 #A((7) BASE-CHAR . "SUBJECT"))
                                (:CONS
                                 (:CONS
                                  (:COMMON-LISP-SYMBOL
                                   #A((7) BASE-CHAR . "DECLARE"))
                                  (:CONS
                                   (:CONS
                                    (:COMMON-LISP-SYMBOL
                                     #A((6) BASE-CHAR . "IGNORE"))
                                    (:CONS
                                     (:SYMBOL
                                      #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                      #A((4) BASE-CHAR . "KIND"))
                                     (:NULL)))
                                   (:NULL)))
                                 (:CONS
                                  (:CONS
                                   (:COMMON-LISP-SYMBOL
                                    #A((4) BASE-CHAR . "LET*"))
                                   (:CONS
                                    (:CONS
                                     (:CONS
                                      (:SYMBOL
                                       #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                       #A((6) BASE-CHAR . "SYSTEM"))
                                      (:CONS
                                       (:CONS
                                        (:SYMBOL
                                         #A((11) BASE-CHAR . "ASDF/SYSTEM")
                                         "FIND-SYSTEM")
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((17) BASE-CHAR
                                             . "SYSTEM-DESIGNATOR"))
                                         (:NULL)))
                                       (:NULL)))
                                     (:CONS
                                      (:CONS
                                       (:SYMBOL
                                        #A((16) BASE-CHAR . "COMMON-LISP-USER")
                                        #A((9) BASE-CHAR . "AUTHORITY"))
                                       (:CONS
                                        (:CONS
                                         (:SYMBOL
                                          #A((11) BASE-CHAR . "ASDF/SYSTEM")
                                          "SYSTEM-SOURCE-FILE")
                                         (:CONS
                                          (:SYMBOL
                                           #A((16) BASE-CHAR
                                              . "COMMON-LISP-USER")
                                           #A((6) BASE-CHAR . "SYSTEM"))
                                          (:NULL)))
                                        (:NULL)))
                                      (:CONS
                                       (:CONS
                                        (:SYMBOL
                                         #A((16) BASE-CHAR
                                            . "COMMON-LISP-USER")
                                         #A((12) BASE-CHAR . "DEPENDENCIES"))
                                        (:CONS
                                         (:CONS
                                          (:SYMBOL
                                           #A((11) BASE-CHAR . "ASDF/SYSTEM")
                                           "SYSTEM-DEPENDS-ON")
                                          (:CONS
                                           (:SYMBOL
                                            #A((16) BASE-CHAR
                                               . "COMMON-LISP-USER")
                                            #A((6) BASE-CHAR . "SYSTEM"))
                                           (:NULL)))
                                         (:NULL)))
                                       (:CONS
                                        (:CONS
                                         (:SYMBOL
                                          #A((16) BASE-CHAR
                                             . "COMMON-LISP-USER")
                                          #A((9) BASE-CHAR . "PRESENT-P"))
                                         (:CONS
                                          (:CONS
                                           (:COMMON-LISP-SYMBOL
                                            #A((6) BASE-CHAR . "MEMBER"))
                                           (:CONS
                                            (:SYMBOL
                                             #A((16) BASE-CHAR
                                                . "COMMON-LISP-USER")
                                             #A((21) BASE-CHAR
                                                . "DEPENDENCY-DESIGNATOR"))
                                            (:CONS
                                             (:SYMBOL
                                              #A((16) BASE-CHAR
                                                 . "COMMON-LISP-USER")
                                              #A((12) BASE-CHAR
                                                 . "DEPENDENCIES"))
                                             (:CONS
                                              (:KEYWORD
                                               #A((4) BASE-CHAR . "TEST"))
                                              (:CONS
                                               (:CONS
                                                (:COMMON-LISP-SYMBOL
                                                 #A((8) BASE-CHAR
                                                    . "FUNCTION"))
                                                (:CONS
                                                 (:COMMON-LISP-SYMBOL
                                                  #A((5) BASE-CHAR . "EQUAL"))
                                                 (:NULL)))
                                               (:NULL))))))
                                          (:NULL)))
                                        (:NULL)))))
                                    (:CONS
                                     (:CONS
                                      (:COMMON-LISP-SYMBOL
                                       #A((4) BASE-CHAR . "LIST"))
                                      (:CONS
                                       (:KEYWORD #A((6) BASE-CHAR . "STATUS"))
                                       (:CONS
                                        (:CONS
                                         (:COMMON-LISP-SYMBOL
                                          #A((2) BASE-CHAR . "IF"))
                                         (:CONS
                                          (:SYMBOL
                                           #A((16) BASE-CHAR
                                              . "COMMON-LISP-USER")
                                           #A((9) BASE-CHAR . "PRESENT-P"))
                                          (:CONS
                                           (:KEYWORD
                                            #A((10) BASE-CHAR . "PERSISTENT"))
                                           (:CONS
                                            (:KEYWORD
                                             #A((17) BASE-CHAR
                                                . "NEEDS-PERSISTENCE"))
                                            (:NULL)))))
                                        (:CONS
                                         (:KEYWORD
                                          #A((7) BASE-CHAR . "SUBJECT"))
                                         (:CONS
                                          (:SYMBOL
                                           #A((16) BASE-CHAR
                                              . "COMMON-LISP-USER")
                                           #A((7) BASE-CHAR . "SUBJECT"))
                                          (:CONS
                                           (:KEYWORD
                                            #A((9) BASE-CHAR . "AUTHORITY"))
                                           (:CONS
                                            (:SYMBOL
                                             #A((16) BASE-CHAR
                                                . "COMMON-LISP-USER")
                                             #A((9) BASE-CHAR . "AUTHORITY"))
                                            (:CONS
                                             (:KEYWORD
                                              #A((20) BASE-CHAR
                                                 . "CURRENT-DEPENDENCIES"))
                                             (:CONS
                                              (:SYMBOL
                                               #A((16) BASE-CHAR
                                                  . "COMMON-LISP-USER")
                                               #A((12) BASE-CHAR
                                                  . "DEPENDENCIES"))
                                              (:CONS
                                               (:KEYWORD
                                                #A((9) BASE-CHAR
                                                   . "NEXT-FORM"))
                                               (:CONS
                                                (:CONS
                                                 (:COMMON-LISP-SYMBOL
                                                  #A((6) BASE-CHAR . "UNLESS"))
                                                 (:CONS
                                                  (:SYMBOL
                                                   #A((16) BASE-CHAR
                                                      . "COMMON-LISP-USER")
                                                   #A((9) BASE-CHAR
                                                      . "PRESENT-P"))
                                                  (:CONS
                                                   (:CONS
                                                    (:COMMON-LISP-SYMBOL
                                                     #A((4) BASE-CHAR
                                                        . "LIST"))
                                                    (:CONS
                                                     (:CONS
                                                      (:COMMON-LISP-SYMBOL
                                                       #A((5) BASE-CHAR
                                                          . "QUOTE"))
                                                      (:CONS
                                                       (:SYMBOL
                                                        #A((16) BASE-CHAR
                                                           . "DREYECK/WORKFLOW")
                                                        "PERSIST-IN")
                                                       (:NULL)))
                                                     (:CONS
                                                      (:SYMBOL
                                                       #A((16) BASE-CHAR
                                                          . "COMMON-LISP-USER")
                                                       #A((9) BASE-CHAR
                                                          . "AUTHORITY"))
                                                      (:CONS
                                                       (:CONS
                                                        (:COMMON-LISP-SYMBOL
                                                         #A((4) BASE-CHAR
                                                            . "LIST"))
                                                        (:CONS
                                                         (:CONS
                                                          (:COMMON-LISP-SYMBOL
                                                           #A((5) BASE-CHAR
                                                              . "QUOTE"))
                                                          (:CONS
                                                           (:COMMON-LISP-SYMBOL
                                                            #A((5) BASE-CHAR
                                                               . "QUOTE"))
                                                           (:NULL)))
                                                         (:CONS
                                                          (:SYMBOL
                                                           #A((16) BASE-CHAR
                                                              . "COMMON-LISP-USER")
                                                           #A((7) BASE-CHAR
                                                              . "SUBJECT"))
                                                          (:NULL))))
                                                       (:NULL)))))
                                                   (:NULL))))
                                                (:NULL))))))))))))
                                     (:NULL))))
                                  (:NULL))))))
                             (:NULL)))
                           (:NULL))))
                        (:NULL)))
                      (:NULL)))))
                  (:CONS
                   (:CONS (:KEYWORD #A((5) BASE-CHAR . "FIELD"))
                    (:CONS (:KEYWORD #A((14) BASE-CHAR . "CONS-CASE-KEYS"))
                     (:CONS (:KEYWORD #A((5) BASE-CHAR . "VALUE"))
                      (:CONS
                       (:CONS (:KEYWORD #A((15) BASE-CHAR . "ASDF-DEPENDENCY"))
                        (:NULL))
                       (:NULL)))))
                   (:NULL)))
                 (:NULL))))))))))

(SETF (GETHASH :SUM-TYPE-DISPATCH
               DREYECK/WORKFLOW::*WORKFLOW-CONSTRUCTION-MATERIALIZERS*)
        #'(LAMBDA
              (DREYECK/WORKFLOW::OPERATION DREYECK/WORKFLOW::FRAGMENTS
               DREYECK/WORKFLOW::SPECIFICATION)
            (DECLARE
             (IGNORE DREYECK/WORKFLOW::OPERATION
              DREYECK/WORKFLOW::SPECIFICATION))
            (FLET ((DREYECK/WORKFLOW::FIELD
                       (DREYECK/WORKFLOW::ROLE DREYECK/WORKFLOW::NAME)
                     (DREYECK/WORKFLOW::WORKFLOW-CARRIER-FIELD-VALUE
                      (DREYECK/WORKFLOW::WORKFLOW-FRAGMENT-CARRIER
                       (FIND DREYECK/WORKFLOW::ROLE DREYECK/WORKFLOW::FRAGMENTS
                             :KEY
                             (LAMBDA (DREYECK/WORKFLOW::FRAGMENT)
                               (GETF DREYECK/WORKFLOW::FRAGMENT :ROLE))))
                      DREYECK/WORKFLOW::NAME)))
              (LET* ((DREYECK/WORKFLOW::HANDLER
                      (DREYECK/WORKFLOW::FIELD :SYMBOL-HANDLER
                       :SYMBOL-HANDLER))
                     (DREYECK/WORKFLOW::BINDING
                      (DREYECK/WORKFLOW::FIELD :SYMBOL-HANDLER
                       :AUTHORITY-BINDING))
                     (DREYECK/WORKFLOW::TARGET
                      (DREYECK/WORKFLOW::FIELD :SYMBOL-HANDLER
                       :AUTHORITY-TARGET))
                     (DREYECK/WORKFLOW::PERSIST-OPERATION
                      (EVAL
                       `(LET ((,DREYECK/WORKFLOW::BINDING
                               ',DREYECK/WORKFLOW::TARGET))
                          ,(GETF DREYECK/WORKFLOW::HANDLER
                                 :LAMBDA-EXPRESSION)))))
                (EVAL
                 `(LET ((DREYECK/WORKFLOW::PERSIST-OPERATION
                         ,DREYECK/WORKFLOW::PERSIST-OPERATION))
                    (LAMBDA
                        ,(DREYECK/WORKFLOW::FIELD :SUBJECT-TYPE-DISPATCH
                          :LAMBDA-LIST)
                      (ETYPECASE
                          ,(DREYECK/WORKFLOW::FIELD :SUBJECT-TYPE-DISPATCH
                            :DISPATCH-FORM)
                        ,(DREYECK/WORKFLOW::FIELD :SYMBOL-HANDLER
                          :SYMBOL-CLAUSE)
                        ,(DREYECK/WORKFLOW::FIELD :CONS-KIND-DISPATCH
                          :CONS-CLAUSE)))))))))

(SETF (GETHASH :DEFINITION-SUFFICIENT
               DREYECK/WORKFLOW::*WORKFLOW-CONSTRUCTION-MATERIALIZERS*)
        #'(LAMBDA
              (DREYECK/WORKFLOW::OPERATION DREYECK/WORKFLOW::FRAGMENTS
               DREYECK/WORKFLOW::SPECIFICATION)
            (DECLARE
             (IGNORE DREYECK/WORKFLOW::OPERATION
              DREYECK/WORKFLOW::SPECIFICATION))
            (LET* ((DREYECK/WORKFLOW::FRAGMENT
                    (FIND :DEFINITION DREYECK/WORKFLOW::FRAGMENTS :KEY
                          (LAMBDA (DREYECK/WORKFLOW::FRAGMENT)
                            (GETF DREYECK/WORKFLOW::FRAGMENT :ROLE))))
                   (DREYECK/WORKFLOW::CARRIER
                    (DREYECK/WORKFLOW::WORKFLOW-FRAGMENT-CARRIER
                     DREYECK/WORKFLOW::FRAGMENT))
                   (DREYECK/WORKFLOW::LAMBDA-EXPRESSION
                    (DREYECK/WORKFLOW::WORKFLOW-CARRIER-FIELD-VALUE
                     DREYECK/WORKFLOW::CARRIER :LAMBDA-EXPRESSION)))
              (DREYECK/WORKFLOW::WORKFLOW-COMPILE-LAMBDA-EXPRESSION
               DREYECK/WORKFLOW::LAMBDA-EXPRESSION))))

(DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
 'DREYECK/WORKFLOW:AUDIT-COMPLETE)

(DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
 'DREYECK/WORKFLOW:DEPEND-ON)

(DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
 'DREYECK/WORKFLOW:RECONSTRUCT)

(DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
 'DREYECK/WORKFLOW:RETIRE)

(DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
 'DREYECK/WORKFLOW:VERIFY)

(DREYECK/WORKFLOW::MATERIALIZE-OPERATION-DETERMINISTICALLY
 'DREYECK/WORKFLOW:PERSIST)

