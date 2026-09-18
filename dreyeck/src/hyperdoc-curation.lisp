
(COMMON-LISP:IN-PACKAGE :DREYECK/HYPERDOC/CURATION)

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                   (DREYECK/HYPERDOC/CURATION::VALUE)
  (COMMON-LISP:TYPECASE DREYECK/HYPERDOC/CURATION::VALUE
    (COMMON-LISP:SYMBOL
     (COMMON-LISP:SYMBOL-NAME DREYECK/HYPERDOC/CURATION::VALUE))
    (HTML-INSPECTOR-VIEWS/STANDARD::SYMBOL-PROXY
     (COMMON-LISP:SLOT-VALUE DREYECK/HYPERDOC/CURATION::VALUE
                             'HTML-INSPECTOR-VIEWS/STANDARD::NAME))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::TOKEN-KEY
                   (DREYECK/HYPERDOC/CURATION::VALUE)
  (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION::NAME
                     (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                      DREYECK/HYPERDOC/CURATION::VALUE)))
    (COMMON-LISP:WHEN DREYECK/HYPERDOC/CURATION::NAME
      (COMMON-LISP:LIST
       (COMMON-LISP:TYPECASE DREYECK/HYPERDOC/CURATION::VALUE
         (COMMON-LISP:SYMBOL
          (COMMON-LISP:AND
           (COMMON-LISP:SYMBOL-PACKAGE DREYECK/HYPERDOC/CURATION::VALUE)
           (COMMON-LISP:PACKAGE-NAME
            (COMMON-LISP:SYMBOL-PACKAGE DREYECK/HYPERDOC/CURATION::VALUE))))
         (HTML-INSPECTOR-VIEWS/STANDARD::SYMBOL-PROXY
          (COMMON-LISP:SLOT-VALUE DREYECK/HYPERDOC/CURATION::VALUE
                                  'COMMON-LISP:PACKAGE-NAME)))
       DREYECK/HYPERDOC/CURATION::NAME))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::OP-P
                   (DREYECK/HYPERDOC/CURATION::RAW
                    DREYECK/HYPERDOC/CURATION::NAME)
  (COMMON-LISP:AND (COMMON-LISP:CONSP DREYECK/HYPERDOC/CURATION::RAW)
                   (COMMON-LISP:EQUAL
                    (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                     (COMMON-LISP:CAR DREYECK/HYPERDOC/CURATION::RAW))
                    DREYECK/HYPERDOC/CURATION::NAME)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::CHILDREN
                   (DREYECK/HYPERDOC/CURATION::NODE)
  (COMMON-LISP:LOOP DREYECK/HYPERDOC/CURATION::FOR DREYECK/HYPERDOC/CURATION::CELL COMMON-LISP:= DREYECK/HYPERDOC/CURATION::NODE DREYECK/HYPERDOC/CURATION::THEN (CONCRETE-SYNTAX-TREE:REST
                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::CELL)
                    DREYECK/HYPERDOC/CURATION::WHILE (COMMON-LISP:CONSP
                                                      (CONCRETE-SYNTAX-TREE:RAW
                                                       DREYECK/HYPERDOC/CURATION::CELL))
                    DREYECK/HYPERDOC/CURATION::COLLECT (CONCRETE-SYNTAX-TREE:FIRST
                                                        DREYECK/HYPERDOC/CURATION::CELL)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::SYNTAX-NODES
                   (DREYECK/HYPERDOC/CURATION::NODE)
  "Structural syntax inventory; these nodes are NOT automatically calls."
  (COMMON-LISP:CONS DREYECK/HYPERDOC/CURATION::NODE
                    (COMMON-LISP:WHEN
                        (COMMON-LISP:AND
                         (COMMON-LISP:CONSP
                          (CONCRETE-SYNTAX-TREE:RAW
                           DREYECK/HYPERDOC/CURATION::NODE))
                         (COMMON-LISP:NOT
                          (COMMON-LISP:MEMBER
                           (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                            (COMMON-LISP:CAR
                             (CONCRETE-SYNTAX-TREE:RAW
                              DREYECK/HYPERDOC/CURATION::NODE)))
                           '("QUOTE" "QUASIQUOTE") :TEST #'COMMON-LISP:EQUAL)))
                      (COMMON-LISP:MAPCAN
                       #'DREYECK/HYPERDOC/CURATION::SYNTAX-NODES
                       (DREYECK/HYPERDOC/CURATION::CHILDREN
                        DREYECK/HYPERDOC/CURATION::NODE)))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::SOURCE-RECORDS
                   (DREYECK/HYPERDOC/CURATION::PATHS)
  (COMMON-LISP:LOOP DREYECK/HYPERDOC/CURATION::FOR DREYECK/HYPERDOC/CURATION::PATH DREYECK/HYPERDOC/CURATION::IN (COMMON-LISP:REMOVE-DUPLICATES
                                                                                                                  DREYECK/HYPERDOC/CURATION::PATHS
                                                                                                                  :TEST
                                                                                                                  #'COMMON-LISP:EQUAL)
                    COMMON-LISP:APPEND (COMMON-LISP:MULTIPLE-VALUE-BIND
                                           (DREYECK/HYPERDOC/CURATION::CODE
                                            DREYECK/HYPERDOC/CURATION::RECOVERED)
                                           (HTML-INSPECTOR-VIEWS/STANDARD:PARSE-LISP-CODE
                                            DREYECK/HYPERDOC/CURATION::PATH)
                                         (COMMON-LISP:WHEN
                                             DREYECK/HYPERDOC/CURATION::RECOVERED
                                           (COMMON-LISP:ERROR
                                            "Reader recovery in ~A; no source evidence accepted."
                                            DREYECK/HYPERDOC/CURATION::PATH))
                                         (COMMON-LISP:LOOP DREYECK/HYPERDOC/CURATION::FOR DREYECK/HYPERDOC/CURATION::TOP DREYECK/HYPERDOC/CURATION::IN (HTML-INSPECTOR-VIEWS/STANDARD:TOP-LEVEL-FORMS-OF
                                                                                                                                                        DREYECK/HYPERDOC/CURATION::CODE)
                                                           DREYECK/HYPERDOC/CURATION::FOR DREYECK/HYPERDOC/CURATION::NODE COMMON-LISP:= (HTML-INSPECTOR-VIEWS/STANDARD:CST-OF
                                                                                                                                         DREYECK/HYPERDOC/CURATION::TOP)
                                                           DREYECK/HYPERDOC/CURATION::FOR DREYECK/HYPERDOC/CURATION::RAW COMMON-LISP:= (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                        DREYECK/HYPERDOC/CURATION::NODE)
                                                           COMMON-LISP:WHEN (COMMON-LISP:AND
                                                                             (COMMON-LISP:CONSP
                                                                              DREYECK/HYPERDOC/CURATION::RAW)
                                                                             (COMMON-LISP:MEMBER
                                                                              (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                                                                               (COMMON-LISP:CAR
                                                                                DREYECK/HYPERDOC/CURATION::RAW))
                                                                              '("DEFUN"
                                                                                "DEFEXAMPLE"
                                                                                "DEFPARAMETER"
                                                                                "DEFVAR")
                                                                              :TEST
                                                                              #'COMMON-LISP:EQUAL))
                                                           DREYECK/HYPERDOC/CURATION::COLLECT (COMMON-LISP:LIST
                                                                                               :PATH
                                                                                               DREYECK/HYPERDOC/CURATION::PATH
                                                                                               :NODE
                                                                                               DREYECK/HYPERDOC/CURATION::NODE
                                                                                               :RAW
                                                                                               DREYECK/HYPERDOC/CURATION::RAW
                                                                                               :KEY
                                                                                               (DREYECK/HYPERDOC/CURATION::TOKEN-KEY
                                                                                                (COMMON-LISP:SECOND
                                                                                                 DREYECK/HYPERDOC/CURATION::RAW))
                                                                                               :NAME
                                                                                               (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                                                                                                (COMMON-LISP:SECOND
                                                                                                 DREYECK/HYPERDOC/CURATION::RAW))
                                                                                               :ID
                                                                                               (COMMON-LISP:FORMAT
                                                                                                COMMON-LISP:NIL
                                                                                                "form:~A:~S"
                                                                                                DREYECK/HYPERDOC/CURATION::PATH
                                                                                                (DREYECK/HYPERDOC/CURATION::TOKEN-KEY
                                                                                                 (COMMON-LISP:SECOND
                                                                                                  DREYECK/HYPERDOC/CURATION::RAW))))))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::WARRANT
                   (DREYECK/HYPERDOC/CURATION::RECORD
                    DREYECK/HYPERDOC/CURATION::NODE
                    DREYECK/HYPERDOC/CURATION::PATTERN)
  (COMMON-LISP:LET* ((DREYECK/HYPERDOC/CURATION::SPAN
                      (CONCRETE-SYNTAX-TREE:SOURCE
                       DREYECK/HYPERDOC/CURATION::NODE))
                     (DREYECK/HYPERDOC/CURATION::PATH
                      (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION::RECORD
                                        :PATH))
                     (DREYECK/HYPERDOC/CURATION::TEXT
                      (UIOP/STREAM:READ-FILE-STRING
                       DREYECK/HYPERDOC/CURATION::PATH)))
    (COMMON-LISP:UNLESS
        (COMMON-LISP:AND (COMMON-LISP:CONSP DREYECK/HYPERDOC/CURATION::SPAN)
                         (COMMON-LISP:INTEGERP
                          (COMMON-LISP:CAR DREYECK/HYPERDOC/CURATION::SPAN))
                         (COMMON-LISP:INTEGERP
                          (COMMON-LISP:CDR DREYECK/HYPERDOC/CURATION::SPAN))
                         (COMMON-LISP:<= 0
                                         (COMMON-LISP:CAR
                                          DREYECK/HYPERDOC/CURATION::SPAN)
                                         (COMMON-LISP:CDR
                                          DREYECK/HYPERDOC/CURATION::SPAN)
                                         (COMMON-LISP:LENGTH
                                          DREYECK/HYPERDOC/CURATION::TEXT)))
      (COMMON-LISP:ERROR "No exact source boundary for ~S."
                         DREYECK/HYPERDOC/CURATION::PATTERN))
    (COMMON-LISP:LIST :KIND :LISP-CST :PATHNAME DREYECK/HYPERDOC/CURATION::PATH
                      :REGION
                      (COMMON-LISP:COPY-TREE DREYECK/HYPERDOC/CURATION::SPAN)
                      :SOURCE
                      (COMMON-LISP:SUBSEQ DREYECK/HYPERDOC/CURATION::TEXT
                                          (COMMON-LISP:CAR
                                           DREYECK/HYPERDOC/CURATION::SPAN)
                                          (COMMON-LISP:CDR
                                           DREYECK/HYPERDOC/CURATION::SPAN))
                      :TOP-LEVEL-NAME
                      (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION::RECORD
                                        :NAME)
                      :TOP-LEVEL-REGION
                      (COMMON-LISP:COPY-TREE
                       (CONCRETE-SYNTAX-TREE:SOURCE
                        (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION::RECORD
                                          :NODE)))
                      :PATTERN DREYECK/HYPERDOC/CURATION::PATTERN)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::RESOLVE-RECORD
                   (DREYECK/HYPERDOC/CURATION::VALUE
                    DREYECK/HYPERDOC/CURATION::RECORDS)
  (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION::KEY
                     (DREYECK/HYPERDOC/CURATION::TOKEN-KEY
                      DREYECK/HYPERDOC/CURATION::VALUE)))
    (COMMON-LISP:WHEN
        (COMMON-LISP:AND DREYECK/HYPERDOC/CURATION::KEY
                         (COMMON-LISP:FIRST DREYECK/HYPERDOC/CURATION::KEY))
      (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION::MATCHES
                         (COMMON-LISP:REMOVE-IF-NOT
                          (COMMON-LISP:LAMBDA (DREYECK/HYPERDOC/CURATION::R)
                            (COMMON-LISP:EQUAL DREYECK/HYPERDOC/CURATION::KEY
                                               (COMMON-LISP:GETF
                                                DREYECK/HYPERDOC/CURATION::R
                                                :KEY)))
                          DREYECK/HYPERDOC/CURATION::RECORDS)))
        (COMMON-LISP:WHEN
            (COMMON-LISP:= 1
                           (COMMON-LISP:LENGTH
                            DREYECK/HYPERDOC/CURATION::MATCHES))
          (COMMON-LISP:FIRST DREYECK/HYPERDOC/CURATION::MATCHES))))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::EXPRESSION-RECORD
                   (DREYECK/HYPERDOC/CURATION::TEXT COMMON-LISP:PACKAGE
                    DREYECK/HYPERDOC/CURATION::RECORDS)
  (COMMON-LISP:MULTIPLE-VALUE-BIND
      (DREYECK/HYPERDOC/CURATION::CODE DREYECK/HYPERDOC/CURATION::RECOVERED)
      (HTML-INSPECTOR-VIEWS/STANDARD:PARSE-LISP-CODE
       DREYECK/HYPERDOC/CURATION::TEXT COMMON-LISP:PACKAGE)
    (COMMON-LISP:UNLESS DREYECK/HYPERDOC/CURATION::RECOVERED
      (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION::TOPS
                         (HTML-INSPECTOR-VIEWS/STANDARD:TOP-LEVEL-FORMS-OF
                          DREYECK/HYPERDOC/CURATION::CODE)))
        (COMMON-LISP:WHEN
            (COMMON-LISP:= 1
                           (COMMON-LISP:LENGTH
                            DREYECK/HYPERDOC/CURATION::TOPS))
          (COMMON-LISP:LET ((DREYECK/HYPERDOC/CURATION::RAW
                             (CONCRETE-SYNTAX-TREE:RAW
                              (HTML-INSPECTOR-VIEWS/STANDARD:CST-OF
                               (COMMON-LISP:FIRST
                                DREYECK/HYPERDOC/CURATION::TOPS)))))
            (COMMON-LISP:AND (COMMON-LISP:CONSP DREYECK/HYPERDOC/CURATION::RAW)
                             (DREYECK/HYPERDOC/CURATION::RESOLVE-RECORD
                              (COMMON-LISP:CAR DREYECK/HYPERDOC/CURATION::RAW)
                              DREYECK/HYPERDOC/CURATION::RECORDS))))))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::PAGE-ID
                   (DREYECK/HYPERDOC/CURATION::PAGE)
  (COMMON-LISP:FORMAT COMMON-LISP:NIL "page:~A/~A"
                      (HYPERBOOK:ID-OF
                       (HYPERBOOK:HYPERBOOK-OF
                        DREYECK/HYPERDOC/CURATION::PAGE))
                      (HYPERBOOK:ID-OF DREYECK/HYPERDOC/CURATION::PAGE)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::FILE-ID
                   (DREYECK/HYPERDOC/CURATION::PATH)
  (COMMON-LISP:FORMAT COMMON-LISP:NIL "file:~A"
                      DREYECK/HYPERDOC/CURATION::PATH))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION::DIRECT-CALLS
                   (DREYECK/HYPERDOC/CURATION::RECORD
                    DREYECK/HYPERDOC/CURATION::RECORDS)
  "Conservative expression positions: bodies, LET initializers, PROGN/IF/WHEN/
UNLESS and direct calls to inventoried functions. Unknown macros stay opaque."
  (COMMON-LISP:LABELS ((DREYECK/HYPERDOC/CURATION::WALK
                           (DREYECK/HYPERDOC/CURATION::NODE)
                         (COMMON-LISP:LET* ((DREYECK/HYPERDOC/CURATION::RAW
                                             (CONCRETE-SYNTAX-TREE:RAW
                                              DREYECK/HYPERDOC/CURATION::NODE))
                                            (DREYECK/HYPERDOC/CURATION::PARTS
                                             (COMMON-LISP:AND
                                              (COMMON-LISP:CONSP
                                               DREYECK/HYPERDOC/CURATION::RAW)
                                              (DREYECK/HYPERDOC/CURATION::CHILDREN
                                               DREYECK/HYPERDOC/CURATION::NODE)))
                                            (DREYECK/HYPERDOC/CURATION::NAME
                                             (COMMON-LISP:AND
                                              DREYECK/HYPERDOC/CURATION::PARTS
                                              (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                                               (COMMON-LISP:CAR
                                                DREYECK/HYPERDOC/CURATION::RAW)))))
                           (COMMON-LISP:COND
                            ((COMMON-LISP:MEMBER
                              DREYECK/HYPERDOC/CURATION::NAME '("LET" "LET*")
                              :TEST #'COMMON-LISP:EQUAL)
                             (COMMON-LISP:APPEND
                              (COMMON-LISP:LOOP DREYECK/HYPERDOC/CURATION::FOR DREYECK/HYPERDOC/CURATION::BINDING DREYECK/HYPERDOC/CURATION::IN (DREYECK/HYPERDOC/CURATION::CHILDREN
                                                                                                                                                 (COMMON-LISP:SECOND
                                                                                                                                                  DREYECK/HYPERDOC/CURATION::PARTS))
                                                COMMON-LISP:WHEN (COMMON-LISP:CONSP
                                                                  (CONCRETE-SYNTAX-TREE:RAW
                                                                   DREYECK/HYPERDOC/CURATION::BINDING))
                                                COMMON-LISP:APPEND (COMMON-LISP:MAPCAN
                                                                    #'DREYECK/HYPERDOC/CURATION::WALK
                                                                    (COMMON-LISP:REST
                                                                     (DREYECK/HYPERDOC/CURATION::CHILDREN
                                                                      DREYECK/HYPERDOC/CURATION::BINDING))))
                              (COMMON-LISP:MAPCAN
                               #'DREYECK/HYPERDOC/CURATION::WALK
                               (COMMON-LISP:CDDR
                                DREYECK/HYPERDOC/CURATION::PARTS))))
                            ((COMMON-LISP:MEMBER
                              DREYECK/HYPERDOC/CURATION::NAME
                              '("PROGN" "IF" "WHEN" "UNLESS") :TEST
                              #'COMMON-LISP:EQUAL)
                             (COMMON-LISP:MAPCAN
                              #'DREYECK/HYPERDOC/CURATION::WALK
                              (COMMON-LISP:REST
                               DREYECK/HYPERDOC/CURATION::PARTS)))
                            ((COMMON-LISP:AND DREYECK/HYPERDOC/CURATION::PARTS
                                              (DREYECK/HYPERDOC/CURATION::RESOLVE-RECORD
                                               (COMMON-LISP:CAR
                                                DREYECK/HYPERDOC/CURATION::RAW)
                                               DREYECK/HYPERDOC/CURATION::RECORDS)
                                              (COMMON-LISP:MEMBER
                                               (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                                                (COMMON-LISP:CAR
                                                 (COMMON-LISP:GETF
                                                  (DREYECK/HYPERDOC/CURATION::RESOLVE-RECORD
                                                   (COMMON-LISP:CAR
                                                    DREYECK/HYPERDOC/CURATION::RAW)
                                                   DREYECK/HYPERDOC/CURATION::RECORDS)
                                                  :RAW)))
                                               '("DEFUN" "DEFEXAMPLE") :TEST
                                               #'COMMON-LISP:EQUAL))
                             (COMMON-LISP:CONS DREYECK/HYPERDOC/CURATION::NODE
                                               (COMMON-LISP:MAPCAN
                                                #'DREYECK/HYPERDOC/CURATION::WALK
                                                (COMMON-LISP:REST
                                                 DREYECK/HYPERDOC/CURATION::PARTS))))))))
    (COMMON-LISP:WHEN
        (COMMON-LISP:MEMBER
         (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
          (COMMON-LISP:CAR
           (COMMON-LISP:GETF DREYECK/HYPERDOC/CURATION::RECORD :RAW)))
         '("DEFUN" "DEFEXAMPLE") :TEST #'COMMON-LISP:EQUAL)
      (COMMON-LISP:MAPCAN #'DREYECK/HYPERDOC/CURATION::WALK
                          (COMMON-LISP:NTHCDR 3
                                              (DREYECK/HYPERDOC/CURATION::CHILDREN
                                               (COMMON-LISP:GETF
                                                DREYECK/HYPERDOC/CURATION::RECORD
                                                :NODE)))))))

(defun literal-page-lookups (record)
  "Return literal HYPERBOOK:FIND-PAGE calls in bounded expression positions.
Only DEFUN/DEFEXAMPLE bodies, LET/LET* initializers and bodies, MULTIPLE-VALUE-BIND
values and bodies, simple control forms, and known global function arguments are
visible. Local function/macro binders, quoted data, lambda lists, declarations,
and unknown macros stay opaque. Neither source nor macro expansion is evaluated."
  (labels ((operator-is (raw symbol)
             (and (consp raw) (equal (token-key (car raw)) (token-key symbol))))
           (global-function-p (operator)
             (let* ((key (token-key operator))
                    (package (and (first key) (find-package (first key))))
                    (symbol (and package (find-symbol (second key) package))))
               (and symbol (fboundp symbol)
                    (not (macro-function symbol))
                    (not (special-operator-p symbol)))))
           (walk (node)
             (let* ((raw (concrete-syntax-tree:raw node))
                    (parts (and (consp raw) (children node))))
               (cond
                 ((or (operator-is raw 'let) (operator-is raw 'let*))
                  (append
                   (loop for binding in (children (second parts))
                         when (consp (concrete-syntax-tree:raw binding))
                           append (mapcan #'walk (rest (children binding))))
                   (mapcan #'walk (cddr parts))))
                 ((operator-is raw 'multiple-value-bind)
                  (mapcan #'walk (cddr parts)))
                 ((some (lambda (op) (operator-is raw op))
                        '(progn if when unless))
                  (mapcan #'walk (rest parts)))
                 ((and parts (global-function-p (car raw)))
                  (append
                   (when (and (operator-is raw 'hyperbook:find-page)
                              (stringp (third raw)))
                     (list node))
                   (mapcan #'walk (rest parts))))))))
    (let ((raw (getf record :raw))
          (parts (children (getf record :node))))
      (cond ((operator-is raw 'defun) (mapcan #'walk (nthcdr 3 parts)))
            ((operator-is raw 'hyperdoc:defexample)
             (mapcan #'walk (cddr parts)))))))

(DEFUN LEXICAL-PAGE-CONTRACT-USES (SCOPE VARIABLE-KEY)
  "Return structurally visible CHECK-PAGE-EXECUTABLE-CONTRACT uses of VARIABLE-KEY.
LET and LET* shadowing are modeled. QUOTE and unmodeled lexical binders are
opaque, so this recognizer prefers false negatives over unsupported relations."
  (LABELS ((SAME-VARIABLE-P (OBJECT)
             (EQUAL VARIABLE-KEY (TOKEN-KEY OBJECT)))
           (CONTRACT-USE-P (NODE)
             (LET ((RAW (CONCRETE-SYNTAX-TREE:RAW NODE)))
               (AND (CONSP RAW) (OP-P RAW "CHECK-PAGE-EXECUTABLE-CONTRACT")
                    (SAME-VARIABLE-P (SECOND RAW)) (STRINGP (THIRD RAW)))))
           (BINDING-KEY (BINDING)
             (LET ((RAW (CONCRETE-SYNTAX-TREE:RAW BINDING)))
               (IF (CONSP RAW)
                   (TOKEN-KEY (FIRST RAW))
                   (TOKEN-KEY RAW))))
           (BINDING-INITIALIZER (BINDING)
             (LET ((RAW (CONCRETE-SYNTAX-TREE:RAW BINDING)))
               (WHEN (CONSP RAW) (SECOND (CHILDREN BINDING)))))
           (OPAQUE-BINDER-P (RAW)
             (AND (CONSP RAW)
                  (MEMBER (TOKEN-NAME (FIRST RAW))
                          '("LAMBDA" "FLET" "LABELS" "MACROLET"
                            "SYMBOL-MACROLET" "MULTIPLE-VALUE-BIND"
                            "DESTRUCTURING-BIND" "DO" "DO*" "DOLIST" "DOTIMES")
                          :TEST #'EQUAL)))
           (WALK-SEQUENCE (NODES VISIBLE-P)
             (WHEN VISIBLE-P (MAPCAN (LAMBDA (NODE) (WALK NODE T)) NODES)))
           (WALK-LET (NODE SEQUENTIAL-P VISIBLE-P)
             (WHEN VISIBLE-P
               (LET* ((PARTS (CHILDREN NODE))
                      (BINDINGS (CHILDREN (SECOND PARTS)))
                      (BODY (CDDR PARTS))
                      (RESULT NIL)
                      (VISIBLE T))
                 (IF SEQUENTIAL-P
                     (PROGN
                      (DOLIST (BINDING BINDINGS)
                        (LET ((INITIALIZER (BINDING-INITIALIZER BINDING)))
                          (WHEN INITIALIZER
                            (SETF RESULT
                                    (NCONC RESULT
                                           (WALK INITIALIZER VISIBLE)))))
                        (WHEN (EQUAL VARIABLE-KEY (BINDING-KEY BINDING))
                          (SETF VISIBLE NIL)))
                      (WHEN VISIBLE
                        (SETF RESULT (NCONC RESULT (WALK-SEQUENCE BODY T)))))
                     (PROGN
                      (DOLIST (BINDING BINDINGS)
                        (LET ((INITIALIZER (BINDING-INITIALIZER BINDING)))
                          (WHEN INITIALIZER
                            (SETF RESULT
                                    (NCONC RESULT (WALK INITIALIZER T))))))
                      (UNLESS
                          (SOME
                           (LAMBDA (BINDING)
                             (EQUAL VARIABLE-KEY (BINDING-KEY BINDING)))
                           BINDINGS)
                        (SETF RESULT (NCONC RESULT (WALK-SEQUENCE BODY T))))))
                 RESULT)))
           (WALK (NODE VISIBLE-P)
             (WHEN VISIBLE-P
               (LET ((RAW (CONCRETE-SYNTAX-TREE:RAW NODE)))
                 (COND ((CONTRACT-USE-P NODE) (LIST NODE))
                       ((AND (CONSP RAW) (OP-P RAW "QUOTE")) NIL)
                       ((AND (CONSP RAW) (OP-P RAW "LET"))
                        (WALK-LET NODE NIL T))
                       ((AND (CONSP RAW) (OP-P RAW "LET*"))
                        (WALK-LET NODE T T))
                       ((OPAQUE-BINDER-P RAW) NIL)
                       ((CONSP RAW)
                        (MAPCAN (LAMBDA (CHILD) (WALK CHILD T))
                                (CHILDREN NODE)))
                       (T NIL))))))
    (WALK SCOPE T)))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION:MAKE-REFERENCE-WORKSPACE
                   (DREYECK/HYPERDOC/CURATION::PAGE COMMON-LISP:&KEY
                                                    DREYECK/HYPERDOC/CURATION::SOURCE-FILES
                                                    DREYECK/HYPERDOC/CURATION::CONTRACTS)
                   "Observe one book and explicit source files. CONTRACTS contains caller-declared
(:role ROLE :pathname PATH :name TOPLEVEL-NAME) entries. Supported roles are
:expected-page-set, :navigation, :page-executable, :symbol-existence and :literal-page-lookup.
Roles select interpretation; exact syntax supplies evidence. No HTML EXPR or
source form is evaluated. Unsupported and unresolved references remain diagnostics."
                   (COMMON-LISP:LET*
                                     ((DREYECK/HYPERDOC/CURATION::BOOK
                                                                       (HYPERBOOK:HYPERBOOK-OF
                                                                                               DREYECK/HYPERDOC/CURATION::PAGE))
                                      (DREYECK/HYPERDOC/CURATION::RECORDS
                                                                          (DREYECK/HYPERDOC/CURATION::SOURCE-RECORDS
                                                                                                                     DREYECK/HYPERDOC/CURATION::SOURCE-FILES))
                                      (DREYECK/HYPERDOC/CURATION::TOPICS NIL)
                                      (DREYECK/HYPERDOC/CURATION::EDGES NIL)
                                      (DREYECK/HYPERDOC/CURATION::DIAGNOSTICS
                                                                              NIL)
                                      (DREYECK/HYPERDOC/CURATION::PAGES NIL)
                                      (DREYECK/HYPERDOC/CURATION::BOOK-ID
                                                                          (COMMON-LISP:FORMAT
                                                                                              NIL
                                                                                              "book:~A"
                                                                                              (HYPERBOOK:ID-OF
                                                                                                               DREYECK/HYPERDOC/CURATION::BOOK))))
                                     (COMMON-LISP:LABELS
                                                         ((DREYECK/HYPERDOC/CURATION::TOPIC
                                                                                            (DREYECK/HYPERDOC/CURATION::ID
                                                                                                                           COMMON-LISP:TYPE
                                                                                                                           DREYECK/HYPERDOC/CURATION::LABEL
                                                                                                                           DREYECK/HYPERDOC/CURATION::OBJECT)
                                                                                            (COMMON-LISP:UNLESS
                                                                                                                (COMMON-LISP:FIND
                                                                                                                                  DREYECK/HYPERDOC/CURATION::ID
                                                                                                                                  DREYECK/HYPERDOC/CURATION::TOPICS
                                                                                                                                  :TEST
                                                                                                                                  (COMMON-LISP:FUNCTION
                                                                                                                                                        COMMON-LISP:EQUAL)
                                                                                                                                  :KEY
                                                                                                                                  (COMMON-LISP:FUNCTION
                                                                                                                                                        DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF))
                                                                                                                (COMMON-LISP:PUSH
                                                                                                                                  (DREYECK/TOPICMAP:MAKE-TOPICMAP-TOPIC
                                                                                                                                                                        :ID
                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::ID
                                                                                                                                                                        :TYPE
                                                                                                                                                                        COMMON-LISP:TYPE
                                                                                                                                                                        :LABEL
                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::LABEL
                                                                                                                                                                        :OBJECT
                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::OBJECT)
                                                                                                                                  DREYECK/HYPERDOC/CURATION::TOPICS))
                                                                                            DREYECK/HYPERDOC/CURATION::ID)
                                                          (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                           (COMMON-LISP:TYPE
                                                                                                             DREYECK/HYPERDOC/CURATION::FROM
                                                                                                             DREYECK/HYPERDOC/CURATION::TO
                                                                                                             DREYECK/HYPERDOC/CURATION::STATUS
                                                                                                             DREYECK/HYPERDOC/CURATION::EVIDENCE)
                                                                                           (COMMON-LISP:ASSERT
                                                                                                               DREYECK/HYPERDOC/CURATION::EVIDENCE)
                                                                                           (COMMON-LISP:PUSH
                                                                                                             (DREYECK/TOPICMAP:MAKE-TOPICMAP-ASSOCIATION
                                                                                                                                                         :ID
                                                                                                                                                         (COMMON-LISP:FORMAT
                                                                                                                                                                             NIL
                                                                                                                                                                             "reference:~D"
                                                                                                                                                                             (COMMON-LISP:LENGTH
                                                                                                                                                                                                 DREYECK/HYPERDOC/CURATION::EDGES))
                                                                                                                                                         :TYPE
                                                                                                                                                         COMMON-LISP:TYPE
                                                                                                                                                         :FROM
                                                                                                                                                         DREYECK/HYPERDOC/CURATION::FROM
                                                                                                                                                         :TO
                                                                                                                                                         DREYECK/HYPERDOC/CURATION::TO
                                                                                                                                                         :PROPERTIES
                                                                                                                                                         (COMMON-LISP:LIST
                                                                                                                                                                           :EPISTEMIC-STATUS
                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::STATUS
                                                                                                                                                                           :WARRANT
                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::EVIDENCE))
                                                                                                             DREYECK/HYPERDOC/CURATION::EDGES))
                                                          (DREYECK/HYPERDOC/CURATION::NAMED-PAGE
                                                                                                 (DREYECK/HYPERDOC/CURATION::TITLE)
                                                                                                 (COMMON-LISP:AND
                                                                                                                  (COMMON-LISP:STRINGP
                                                                                                                                       DREYECK/HYPERDOC/CURATION::TITLE)
                                                                                                                  (COMMON-LISP:FIND
                                                                                                                                    DREYECK/HYPERDOC/CURATION::TITLE
                                                                                                                                    DREYECK/HYPERDOC/CURATION::PAGES
                                                                                                                                    :TEST
                                                                                                                                    (COMMON-LISP:FUNCTION
                                                                                                                                                          COMMON-LISP:EQUAL)
                                                                                                                                    :KEY
                                                                                                                                    (COMMON-LISP:FUNCTION
                                                                                                                                                          HYPERBOOK:ID-OF))))
                                                          (DREYECK/HYPERDOC/CURATION::SOURCE-EDGE
                                                                                                  (COMMON-LISP:TYPE
                                                                                                                    DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                    DREYECK/HYPERDOC/CURATION::NODE
                                                                                                                    DREYECK/HYPERDOC/CURATION::TARGET
                                                                                                                    DREYECK/HYPERDOC/CURATION::PATTERN
                                                                                                                    COMMON-LISP:&OPTIONAL
                                                                                                                    COMMON-LISP:DECLARATION)
                                                                                                  (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                   COMMON-LISP:TYPE
                                                                                                                                   (COMMON-LISP:GETF
                                                                                                                                                     DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                                                     :ID)
                                                                                                                                   DREYECK/HYPERDOC/CURATION::TARGET
                                                                                                                                   :SOURCE-OBSERVED
                                                                                                                                   (COMMON-LISP:APPEND
                                                                                                                                                       (DREYECK/HYPERDOC/CURATION::WARRANT
                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::NODE
                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::PATTERN)
                                                                                                                                                       (COMMON-LISP:WHEN
                                                                                                                                                                         COMMON-LISP:DECLARATION
                                                                                                                                                                         (COMMON-LISP:LIST
                                                                                                                                                                                           :CALLER-CONTRACT
                                                                                                                                                                                           COMMON-LISP:DECLARATION)))))
                                                          (DREYECK/HYPERDOC/CURATION::CONTRACT-RECORD
                                                                                                      (DREYECK/HYPERDOC/CURATION::CONTRACT)
                                                                                                      (COMMON-LISP:LET
                                                                                                                       ((DREYECK/HYPERDOC/CURATION::MATCHES
                                                                                                                                                            (COMMON-LISP:REMOVE-IF-NOT
                                                                                                                                                                                       (LAMBDA
                                                                                                                                                                                               (DREYECK/HYPERDOC/CURATION::R)
                                                                                                                                                                                               (COMMON-LISP:AND
                                                                                                                                                                                                                (COMMON-LISP:EQUAL
                                                                                                                                                                                                                                   (COMMON-LISP:PATHNAME
                                                                                                                                                                                                                                                         (COMMON-LISP:GETF
                                                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::CONTRACT
                                                                                                                                                                                                                                                                           :PATHNAME))
                                                                                                                                                                                                                                   (COMMON-LISP:PATHNAME
                                                                                                                                                                                                                                                         (COMMON-LISP:GETF
                                                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                                           :PATH)))
                                                                                                                                                                                                                (COMMON-LISP:EQUAL
                                                                                                                                                                                                                                   (COMMON-LISP:GETF
                                                                                                                                                                                                                                                     DREYECK/HYPERDOC/CURATION::CONTRACT
                                                                                                                                                                                                                                                     :NAME)
                                                                                                                                                                                                                                   (COMMON-LISP:GETF
                                                                                                                                                                                                                                                     DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                     :NAME))))
                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::RECORDS)))
                                                                                                                       (COMMON-LISP:UNLESS
                                                                                                                                           (COMMON-LISP:=
                                                                                                                                                          1
                                                                                                                                                          (COMMON-LISP:LENGTH
                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::MATCHES))
                                                                                                                                           (COMMON-LISP:ERROR
                                                                                                                                                              "Contract must identify one inventoried top-level form: ~S."
                                                                                                                                                              DREYECK/HYPERDOC/CURATION::CONTRACT))
                                                                                                                       (COMMON-LISP:FIRST
                                                                                                                                          DREYECK/HYPERDOC/CURATION::MATCHES))))
                                                         (HYPERDOC::ENSURE-PAGES-LOADED
                                                                                        DREYECK/HYPERDOC/CURATION::BOOK)
                                                         (COMMON-LISP:SETF
                                                                           DREYECK/HYPERDOC/CURATION::PAGES
                                                                           (COMMON-LISP:SORT
                                                                                             (COMMON-LISP:LOOP
                                                                                                               DREYECK/HYPERDOC/CURATION::FOR
                                                                                                               DREYECK/HYPERDOC/CURATION::P
                                                                                                               DREYECK/HYPERDOC/CURATION::BEING
                                                                                                               COMMON-LISP:THE
                                                                                                               DREYECK/HYPERDOC/CURATION::HASH-VALUES
                                                                                                               DREYECK/HYPERDOC/CURATION::OF
                                                                                                               (HYPERDOC:PAGES-OF
                                                                                                                                  DREYECK/HYPERDOC/CURATION::BOOK)
                                                                                                               COMMON-LISP:WHEN
                                                                                                               (COMMON-LISP:TYPEP
                                                                                                                                  DREYECK/HYPERDOC/CURATION::P
                                                                                                                                  (COMMON-LISP:FIND-CLASS
                                                                                                                                                          (COMMON-LISP:FIND-SYMBOL
                                                                                                                                                                                   "HTML-PAGE"
                                                                                                                                                                                   "HYPERDOC")))
                                                                                                               DREYECK/HYPERDOC/CURATION::COLLECT
                                                                                                               DREYECK/HYPERDOC/CURATION::P)
                                                                                             (COMMON-LISP:FUNCTION
                                                                                                                   COMMON-LISP:STRING<)
                                                                                             :KEY
                                                                                             (COMMON-LISP:FUNCTION
                                                                                                                   HYPERBOOK:ID-OF)))
                                                         (COMMON-LISP:UNLESS
                                                                             (COMMON-LISP:MEMBER
                                                                                                 DREYECK/HYPERDOC/CURATION::PAGE
                                                                                                 DREYECK/HYPERDOC/CURATION::PAGES
                                                                                                 :TEST
                                                                                                 (COMMON-LISP:FUNCTION
                                                                                                                       COMMON-LISP:EQ))
                                                                             (COMMON-LISP:ERROR
                                                                                                "Page is not a current book member."))
                                                         (DREYECK/HYPERDOC/CURATION::TOPIC
                                                                                           DREYECK/HYPERDOC/CURATION::BOOK-ID
                                                                                           :HYPERBOOK
                                                                                           (HYPERBOOK:TITLE-OF
                                                                                                               DREYECK/HYPERDOC/CURATION::BOOK)
                                                                                           DREYECK/HYPERDOC/CURATION::BOOK)
                                                         (COMMON-LISP:DOLIST
                                                                             (DREYECK/HYPERDOC/CURATION::P
                                                                                                           DREYECK/HYPERDOC/CURATION::PAGES)
                                                                             (DREYECK/HYPERDOC/CURATION::TOPIC
                                                                                                               (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                   DREYECK/HYPERDOC/CURATION::P)
                                                                                                               :PAGE
                                                                                                               (HYPERBOOK:ID-OF
                                                                                                                                DREYECK/HYPERDOC/CURATION::P)
                                                                                                               DREYECK/HYPERDOC/CURATION::P)
                                                                             (DREYECK/HYPERDOC/CURATION::TOPIC
                                                                                                               (DREYECK/HYPERDOC/CURATION::FILE-ID
                                                                                                                                                   (HYPERDOC:FILE-OF
                                                                                                                                                                     DREYECK/HYPERDOC/CURATION::P))
                                                                                                               :HTML-SOURCE
                                                                                                               (COMMON-LISP:FILE-NAMESTRING
                                                                                                                                            (HYPERDOC:FILE-OF
                                                                                                                                                              DREYECK/HYPERDOC/CURATION::P))
                                                                                                               (HYPERDOC:FILE-OF
                                                                                                                                 DREYECK/HYPERDOC/CURATION::P))
                                                                             (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                              :CONTAINS-PAGE
                                                                                                              DREYECK/HYPERDOC/CURATION::BOOK-ID
                                                                                                              (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                  DREYECK/HYPERDOC/CURATION::P)
                                                                                                              :LIVE-OBSERVED
                                                                                                              (COMMON-LISP:LIST
                                                                                                                                :KIND
                                                                                                                                :BOOK-MEMBERSHIP
                                                                                                                                :BOOK
                                                                                                                                DREYECK/HYPERDOC/CURATION::BOOK
                                                                                                                                :PAGE
                                                                                                                                DREYECK/HYPERDOC/CURATION::P))
                                                                             (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                              :SOURCE-OF-PAGE
                                                                                                              (DREYECK/HYPERDOC/CURATION::FILE-ID
                                                                                                                                                  (HYPERDOC:FILE-OF
                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::P))
                                                                                                              (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                  DREYECK/HYPERDOC/CURATION::P)
                                                                                                              :LIVE-OBSERVED
                                                                                                              (COMMON-LISP:LIST
                                                                                                                                :KIND
                                                                                                                                :PAGE-SOURCE-PATHNAME
                                                                                                                                :PAGE
                                                                                                                                DREYECK/HYPERDOC/CURATION::P
                                                                                                                                :PATHNAME
                                                                                                                                (HYPERDOC:FILE-OF
                                                                                                                                                  DREYECK/HYPERDOC/CURATION::P)
                                                                                                                                :SOURCE
                                                                                                                                (UIOP/STREAM:READ-FILE-STRING
                                                                                                                                                              (HYPERDOC:FILE-OF
                                                                                                                                                                                DREYECK/HYPERDOC/CURATION::P)))))
                                                         (COMMON-LISP:DOLIST
                                                                             (DREYECK/HYPERDOC/CURATION::R
                                                                                                           DREYECK/HYPERDOC/CURATION::RECORDS)
                                                                             (DREYECK/HYPERDOC/CURATION::TOPIC
                                                                                                               (DREYECK/HYPERDOC/CURATION::FILE-ID
                                                                                                                                                   (COMMON-LISP:GETF
                                                                                                                                                                     DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                     :PATH))
                                                                                                               :LISP-SOURCE
                                                                                                               (COMMON-LISP:FILE-NAMESTRING
                                                                                                                                            (COMMON-LISP:GETF
                                                                                                                                                              DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                              :PATH))
                                                                                                               (COMMON-LISP:GETF
                                                                                                                                 DREYECK/HYPERDOC/CURATION::R
                                                                                                                                 :PATH))
                                                                             (DREYECK/HYPERDOC/CURATION::TOPIC
                                                                                                               (COMMON-LISP:GETF
                                                                                                                                 DREYECK/HYPERDOC/CURATION::R
                                                                                                                                 :ID)
                                                                                                               :DEFINITION
                                                                                                               (COMMON-LISP:GETF
                                                                                                                                 DREYECK/HYPERDOC/CURATION::R
                                                                                                                                 :NAME)
                                                                                                               DREYECK/HYPERDOC/CURATION::R)
                                                                             (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                              :DEFINES
                                                                                                              (DREYECK/HYPERDOC/CURATION::FILE-ID
                                                                                                                                                  (COMMON-LISP:GETF
                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                    :PATH))
                                                                                                              (COMMON-LISP:GETF
                                                                                                                                DREYECK/HYPERDOC/CURATION::R
                                                                                                                                :ID)
                                                                                                              :SOURCE-OBSERVED
                                                                                                              (DREYECK/HYPERDOC/CURATION::WARRANT
                                                                                                                                                  DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                  (COMMON-LISP:GETF
                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                    :NODE)
                                                                                                                                                  :TOP-LEVEL-DEFINITION))
                                                                             (COMMON-LISP:DOLIST
                                                                                                 (DREYECK/HYPERDOC/CURATION::CALL
                                                                                                                                  (DREYECK/HYPERDOC/CURATION::DIRECT-CALLS
                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::RECORDS))
                                                                                                 (DREYECK/HYPERDOC/CURATION::SOURCE-EDGE
                                                                                                                                         :INVOKES
                                                                                                                                         DREYECK/HYPERDOC/CURATION::R
                                                                                                                                         DREYECK/HYPERDOC/CURATION::CALL
                                                                                                                                         (COMMON-LISP:GETF
                                                                                                                                                           (DREYECK/HYPERDOC/CURATION::RESOLVE-RECORD
                                                                                                                                                                                                      (COMMON-LISP:CAR
                                                                                                                                                                                                                       (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                                                                                                                                 DREYECK/HYPERDOC/CURATION::CALL))
                                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::RECORDS)
                                                                                                                                                           :ID)
                                                                                                                                         :DIRECT-CALL-IN-SUPPORTED-EXPRESSION-POSITION)))
                                                         (COMMON-LISP:DOLIST
                                                                             (DREYECK/HYPERDOC/CURATION::P
                                                                                                           DREYECK/HYPERDOC/CURATION::PAGES)
                                                                             (COMMON-LISP:LET*
                                                                                               ((DREYECK/HYPERDOC/CURATION::PATH
                                                                                                                                 (HYPERDOC:FILE-OF
                                                                                                                                                   DREYECK/HYPERDOC/CURATION::P))
                                                                                                (HTML-EVIDENCE
                                                                                                               (MULTIPLE-VALUE-LIST
                                                                                                                                    (PARSE-HTML-SOURCE-VIEWS
                                                                                                                                                             DREYECK/HYPERDOC/CURATION::PATH)))
                                                                                                (DREYECK/HYPERDOC/CURATION::DOM
                                                                                                                                (COMMON-LISP:FIRST
                                                                                                                                                   HTML-EVIDENCE))
                                                                                                (SOURCE-VIEWS
                                                                                                              (COMMON-LISP:SECOND
                                                                                                                                  HTML-EVIDENCE))
                                                                                                (DREYECK/HYPERDOC/CURATION::DECLARATIONS
                                                                                                                                         (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME
                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::DOM
                                                                                                                                                                             "in-package"))
                                                                                                (COMMON-LISP:PACKAGE
                                                                                                                     (COMMON-LISP:AND
                                                                                                                                      (COMMON-LISP:=
                                                                                                                                                     1
                                                                                                                                                     (COMMON-LISP:LENGTH
                                                                                                                                                                         DREYECK/HYPERDOC/CURATION::DECLARATIONS))
                                                                                                                                      (COMMON-LISP:FIND-PACKAGE
                                                                                                                                                                (COMMON-LISP:STRING-UPCASE
                                                                                                                                                                                           (COMMON-LISP:STRING-TRIM
                                                                                                                                                                                                                    (COMMON-LISP:QUOTE
                                                                                                                                                                                                                                       (#\Space
                                                                                                                                                                                                                                        #\Tab
                                                                                                                                                                                                                                        #\Newline))
                                                                                                                                                                                                                    (PLUMP-DOM:TEXT
                                                                                                                                                                                                                                    (COMMON-LISP:FIRST
                                                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::DECLARATIONS))))))))
                                                                                               (COMMON-LISP:LOOP
                                                                                                                 DREYECK/HYPERDOC/CURATION::FOR
                                                                                                                 DREYECK/HYPERDOC/CURATION::A
                                                                                                                 DREYECK/HYPERDOC/CURATION::IN
                                                                                                                 (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME
                                                                                                                                                     DREYECK/HYPERDOC/CURATION::DOM
                                                                                                                                                     "a")
                                                                                                                 DREYECK/HYPERDOC/CURATION::FOR
                                                                                                                 DREYECK/HYPERDOC/CURATION::INDEX
                                                                                                                 DREYECK/HYPERDOC/CURATION::FROM
                                                                                                                 0
                                                                                                                 DREYECK/HYPERDOC/CURATION::FOR
                                                                                                                 DREYECK/HYPERDOC/CURATION::TITLE
                                                                                                                 COMMON-LISP:=
                                                                                                                 (PLUMP-DOM:ATTRIBUTE
                                                                                                                                      DREYECK/HYPERDOC/CURATION::A
                                                                                                                                      "page")
                                                                                                                 DREYECK/HYPERDOC/CURATION::FOR
                                                                                                                 DREYECK/HYPERDOC/CURATION::EXPR
                                                                                                                 COMMON-LISP:=
                                                                                                                 (PLUMP-DOM:ATTRIBUTE
                                                                                                                                      DREYECK/HYPERDOC/CURATION::A
                                                                                                                                      "expr")
                                                                                                                 COMMON-LISP:DO
                                                                                                                 (COMMON-LISP:WHEN
                                                                                                                                   (COMMON-LISP:AND
                                                                                                                                                    (DREYECK/HYPERDOC/CURATION::NAMED-PAGE
                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::TITLE)
                                                                                                                                                    (COMMON-LISP:NOT
                                                                                                                                                                     (PLUMP-DOM:ATTRIBUTE
                                                                                                                                                                                          DREYECK/HYPERDOC/CURATION::A
                                                                                                                                                                                          "hyperbook")))
                                                                                                                                   (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                                                    :LINKS-TO-PAGE
                                                                                                                                                                    (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::P)
                                                                                                                                                                    (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                                                                        (DREYECK/HYPERDOC/CURATION::NAMED-PAGE
                                                                                                                                                                                                                                               DREYECK/HYPERDOC/CURATION::TITLE))
                                                                                                                                                                    :SOURCE-OBSERVED
                                                                                                                                                                    (COMMON-LISP:LIST
                                                                                                                                                                                      :KIND
                                                                                                                                                                                      :HTML-DOM
                                                                                                                                                                                      :PATHNAME
                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::PATH
                                                                                                                                                                                      :ANCHOR-INDEX
                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::INDEX
                                                                                                                                                                                      :ATTRIBUTE
                                                                                                                                                                                      "page"
                                                                                                                                                                                      :VALUE
                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::TITLE)))
                                                                                                                 (COMMON-LISP:WHEN
                                                                                                                                   DREYECK/HYPERDOC/CURATION::EXPR
                                                                                                                                   (COMMON-LISP:LET
                                                                                                                                                    ((DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                   (COMMON-LISP:AND
                                                                                                                                                                                                    COMMON-LISP:PACKAGE
                                                                                                                                                                                                    (DREYECK/HYPERDOC/CURATION::EXPRESSION-RECORD
                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::EXPR
                                                                                                                                                                                                                                                  COMMON-LISP:PACKAGE
                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::RECORDS))))
                                                                                                                                                    (COMMON-LISP:IF
                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                    (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                                                                                     :EXPOSES-EXECUTABLE-LINK
                                                                                                                                                                                                     (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                                                                                                         DREYECK/HYPERDOC/CURATION::P)
                                                                                                                                                                                                     (COMMON-LISP:GETF
                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                       :ID)
                                                                                                                                                                                                     :SOURCE-OBSERVED
                                                                                                                                                                                                     (COMMON-LISP:LIST
                                                                                                                                                                                                                       :KIND
                                                                                                                                                                                                                       :HTML-DOM
                                                                                                                                                                                                                       :PATHNAME
                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::PATH
                                                                                                                                                                                                                       :ANCHOR-INDEX
                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::INDEX
                                                                                                                                                                                                                       :ATTRIBUTE
                                                                                                                                                                                                                       "expr"
                                                                                                                                                                                                                       :VALUE
                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::EXPR
                                                                                                                                                                                                                       :PACKAGE
                                                                                                                                                                                                                       (COMMON-LISP:PACKAGE-NAME
                                                                                                                                                                                                                                                 COMMON-LISP:PACKAGE)
                                                                                                                                                                                                                       :INTERPRETATION
                                                                                                                                                                                                                       :OPERATOR-REFERENCE-NOT-EXECUTION))
                                                                                                                                                                    (COMMON-LISP:PUSH
                                                                                                                                                                                      (COMMON-LISP:LIST
                                                                                                                                                                                                        :UNRESOLVED-EXPR
                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::EXPR
                                                                                                                                                                                                        :PATHNAME
                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::PATH
                                                                                                                                                                                                        :ANCHOR-INDEX
                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::INDEX)
                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::DIAGNOSTICS)))))
                                                                                               (COMMON-LISP:DOLIST
                                                                                                                   (DREYECK/HYPERDOC/CURATION::ENTRY
                                                                                                                                                     SOURCE-VIEWS)
                                                                                                                   (COMMON-LISP:LET*
                                                                                                                                     ((ELEMENT
                                                                                                                                               (COMMON-LISP:CAR
                                                                                                                                                                DREYECK/HYPERDOC/CURATION::ENTRY))
                                                                                                                                      (HTML-WARRANT
                                                                                                                                                    (CDR
                                                                                                                                                         DREYECK/HYPERDOC/CURATION::ENTRY))
                                                                                                                                      (DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                                                                         (SOURCE-VIEW-FUNCTION-RECORD
                                                                                                                                                                                                      ELEMENT
                                                                                                                                                                                                      COMMON-LISP:PACKAGE
                                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::RECORDS)))
                                                                                                                                     (COMMON-LISP:IF
                                                                                                                                                     DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                                                     (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                                                                      :PRESENTS-SOURCE-OF
                                                                                                                                                                                      (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                                                                                          DREYECK/HYPERDOC/CURATION::P)
                                                                                                                                                                                      (COMMON-LISP:GETF
                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                                                                                                        :ID)
                                                                                                                                                                                      :SOURCE-OBSERVED
                                                                                                                                                                                      (COMMON-LISP:LIST
                                                                                                                                                                                                        :ELEMENT
                                                                                                                                                                                                        HTML-WARRANT
                                                                                                                                                                                                        :DEFINITION
                                                                                                                                                                                                        (DREYECK/HYPERDOC/CURATION::WARRANT
                                                                                                                                                                                                                                            DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                                                                                                                                            (COMMON-LISP:GETF
                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::RECORD
                                                                                                                                                                                                                                                              :NODE)
                                                                                                                                                                                                                                            :NAMED-FUNCTION-SOURCE)
                                                                                                                                                                                                        :PACKAGE
                                                                                                                                                                                                        (COMMON-LISP:PACKAGE-NAME
                                                                                                                                                                                                                                  COMMON-LISP:PACKAGE)
                                                                                                                                                                                                        :INTERPRETATION
                                                                                                                                                                                                        :SOURCE-PRESENTATION-NOT-EXECUTION))
                                                                                                                                                     (COMMON-LISP:PUSH
                                                                                                                                                                       (COMMON-LISP:LIST
                                                                                                                                                                                         :UNRESOLVED-SOURCE-VIEW
                                                                                                                                                                                         (PLUMP-DOM:TEXT
                                                                                                                                                                                                         ELEMENT)
                                                                                                                                                                                         :ELEMENT
                                                                                                                                                                                         HTML-WARRANT)
                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::DIAGNOSTICS))))))
                                                         (COMMON-LISP:DOLIST
                                                                             (DREYECK/HYPERDOC/CURATION::CONTRACT
                                                                                                                  DREYECK/HYPERDOC/CURATION::CONTRACTS)
                                                                             (COMMON-LISP:LET*
                                                                                               ((DREYECK/HYPERDOC/CURATION::R
                                                                                                                              (DREYECK/HYPERDOC/CURATION::CONTRACT-RECORD
                                                                                                                                                                          DREYECK/HYPERDOC/CURATION::CONTRACT))
                                                                                                (DREYECK/HYPERDOC/CURATION::RAW
                                                                                                                                (COMMON-LISP:GETF
                                                                                                                                                  DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                  :RAW))
                                                                                                (DREYECK/HYPERDOC/CURATION::NODES
                                                                                                                                  (DREYECK/HYPERDOC/CURATION::SYNTAX-NODES
                                                                                                                                                                           (COMMON-LISP:GETF
                                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                             :NODE)))
                                                                                                (DREYECK/HYPERDOC/CURATION::RECOGNIZED
                                                                                                                                       NIL))
                                                                                               (COMMON-LISP:CASE
                                                                                                                 (COMMON-LISP:GETF
                                                                                                                                   DREYECK/HYPERDOC/CURATION::CONTRACT
                                                                                                                                   :ROLE)
                                                                                                                 (:EXPECTED-PAGE-SET
                                                                                                                                     (COMMON-LISP:UNLESS
                                                                                                                                                         (COMMON-LISP:AND
                                                                                                                                                                          (COMMON-LISP:MEMBER
                                                                                                                                                                                              (DREYECK/HYPERDOC/CURATION::TOKEN-NAME
                                                                                                                                                                                                                                     (COMMON-LISP:CAR
                                                                                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::RAW))
                                                                                                                                                                                              (COMMON-LISP:QUOTE
                                                                                                                                                                                                                 ("DEFPARAMETER"
                                                                                                                                                                                                                  "DEFVAR"))
                                                                                                                                                                                              :TEST
                                                                                                                                                                                              (COMMON-LISP:FUNCTION
                                                                                                                                                                                                                    COMMON-LISP:EQUAL))
                                                                                                                                                                          (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                           (COMMON-LISP:THIRD
                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::RAW)
                                                                                                                                                                                                           "QUOTE")
                                                                                                                                                                          (COMMON-LISP:LISTP
                                                                                                                                                                                             (COMMON-LISP:SECOND
                                                                                                                                                                                                                 (COMMON-LISP:THIRD
                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::RAW))))
                                                                                                                                                         (COMMON-LISP:ERROR
                                                                                                                                                                            "Expected-page contract is not a quoted table."))
                                                                                                                                     (COMMON-LISP:DOLIST
                                                                                                                                                         (DREYECK/HYPERDOC/CURATION::ENTRY
                                                                                                                                                                                           (COMMON-LISP:SECOND
                                                                                                                                                                                                               (COMMON-LISP:THIRD
                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::RAW)))
                                                                                                                                                         (COMMON-LISP:LET
                                                                                                                                                                          ((DREYECK/HYPERDOC/CURATION::P
                                                                                                                                                                                                         (COMMON-LISP:AND
                                                                                                                                                                                                                          (COMMON-LISP:LISTP
                                                                                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::ENTRY)
                                                                                                                                                                                                                          (COMMON-LISP:=
                                                                                                                                                                                                                                         2
                                                                                                                                                                                                                                         (COMMON-LISP:LENGTH
                                                                                                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::ENTRY))
                                                                                                                                                                                                                          (DREYECK/HYPERDOC/CURATION::NAMED-PAGE
                                                                                                                                                                                                                                                                 (COMMON-LISP:FIRST
                                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::ENTRY)))))
                                                                                                                                                                          (COMMON-LISP:WHEN
                                                                                                                                                                                            (COMMON-LISP:AND
                                                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::P
                                                                                                                                                                                                             (COMMON-LISP:EQUAL
                                                                                                                                                                                                                                (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::ENTRY)
                                                                                                                                                                                                                                (COMMON-LISP:FILE-NAMESTRING
                                                                                                                                                                                                                                                             (HYPERDOC:FILE-OF
                                                                                                                                                                                                                                                                               DREYECK/HYPERDOC/CURATION::P))))
                                                                                                                                                                                            (COMMON-LISP:SETF
                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::RECOGNIZED
                                                                                                                                                                                                              COMMON-LISP:T)
                                                                                                                                                                                            (DREYECK/HYPERDOC/CURATION::SOURCE-EDGE
                                                                                                                                                                                                                                    :ASSERTS-PAGE-PRESENCE
                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                    (COMMON-LISP:THIRD
                                                                                                                                                                                                                                                       (DREYECK/HYPERDOC/CURATION::CHILDREN
                                                                                                                                                                                                                                                                                            (COMMON-LISP:GETF
                                                                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                                                                              :NODE)))
                                                                                                                                                                                                                                    (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                                                                                                                                        DREYECK/HYPERDOC/CURATION::P)
                                                                                                                                                                                                                                    :CALLER-DECLARED-EXPECTED-TITLE-PATH-TABLE
                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::CONTRACT)))))
                                                                                                                 (:NAVIGATION
                                                                                                                              (COMMON-LISP:DOLIST
                                                                                                                                                  (DREYECK/HYPERDOC/CURATION::N
                                                                                                                                                                                DREYECK/HYPERDOC/CURATION::NODES)
                                                                                                                                                  (COMMON-LISP:LET
                                                                                                                                                                   ((DREYECK/HYPERDOC/CURATION::F
                                                                                                                                                                                                  (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                                                                                                            DREYECK/HYPERDOC/CURATION::N)))
                                                                                                                                                                   (COMMON-LISP:WHEN
                                                                                                                                                                                     (COMMON-LISP:AND
                                                                                                                                                                                                      (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::F
                                                                                                                                                                                                                                       "CHECK")
                                                                                                                                                                                                      (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                       (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::F)
                                                                                                                                                                                                                                       "EQUAL")
                                                                                                                                                                                                      (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                       (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                           (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                                               DREYECK/HYPERDOC/CURATION::F))
                                                                                                                                                                                                                                       "QUOTE")
                                                                                                                                                                                                      (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                       (COMMON-LISP:THIRD
                                                                                                                                                                                                                                                          (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::F))
                                                                                                                                                                                                                                       "PAGE-LINKS"))
                                                                                                                                                                                     (COMMON-LISP:DOLIST
                                                                                                                                                                                                         (DREYECK/HYPERDOC/CURATION::TITLE
                                                                                                                                                                                                                                           (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                               (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                                                   (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::F))))
                                                                                                                                                                                                         (COMMON-LISP:WHEN
                                                                                                                                                                                                                           (DREYECK/HYPERDOC/CURATION::NAMED-PAGE
                                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::TITLE)
                                                                                                                                                                                                                           (COMMON-LISP:SETF
                                                                                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::RECOGNIZED
                                                                                                                                                                                                                                             COMMON-LISP:T)
                                                                                                                                                                                                                           (DREYECK/HYPERDOC/CURATION::SOURCE-EDGE
                                                                                                                                                                                                                                                                   :ASSERTS-NAVIGATION
                                                                                                                                                                                                                                                                   DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                                   DREYECK/HYPERDOC/CURATION::N
                                                                                                                                                                                                                                                                   (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                                                                                                                                                                       (DREYECK/HYPERDOC/CURATION::NAMED-PAGE
                                                                                                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::TITLE))
                                                                                                                                                                                                                                                                   :CHECK-EQUAL-QUOTED-TITLES-PAGE-LINKS
                                                                                                                                                                                                                                                                   DREYECK/HYPERDOC/CURATION::CONTRACT)))))))
                                                                                                                 (:PAGE-EXECUTABLE
                                                                                                                                   (COMMON-LISP:DOLIST
                                                                                                                                                       (DREYECK/HYPERDOC/CURATION::N
                                                                                                                                                                                     DREYECK/HYPERDOC/CURATION::NODES)
                                                                                                                                                       (COMMON-LISP:LET
                                                                                                                                                                        ((DREYECK/HYPERDOC/CURATION::F
                                                                                                                                                                                                       (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                                                                                                                 DREYECK/HYPERDOC/CURATION::N)))
                                                                                                                                                                        (COMMON-LISP:WHEN
                                                                                                                                                                                          (COMMON-LISP:OR
                                                                                                                                                                                                          (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::F
                                                                                                                                                                                                                                           "LET")
                                                                                                                                                                                                          (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::F
                                                                                                                                                                                                                                           "LET*"))
                                                                                                                                                                                          (COMMON-LISP:LET*
                                                                                                                                                                                                            ((DREYECK/HYPERDOC/CURATION::PARTS
                                                                                                                                                                                                                                               (DREYECK/HYPERDOC/CURATION::CHILDREN
                                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::N))
                                                                                                                                                                                                             (DREYECK/HYPERDOC/CURATION::BINDINGS
                                                                                                                                                                                                                                                  (DREYECK/HYPERDOC/CURATION::CHILDREN
                                                                                                                                                                                                                                                                                       (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::PARTS)))
                                                                                                                                                                                                             (DREYECK/HYPERDOC/CURATION::BODY
                                                                                                                                                                                                                                              (COMMON-LISP:CDDR
                                                                                                                                                                                                                                                                DREYECK/HYPERDOC/CURATION::PARTS)))
                                                                                                                                                                                                            (COMMON-LISP:DOLIST
                                                                                                                                                                                                                                (DREYECK/HYPERDOC/CURATION::BINDING
                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::BINDINGS)
                                                                                                                                                                                                                                (COMMON-LISP:LET*
                                                                                                                                                                                                                                                  ((DREYECK/HYPERDOC/CURATION::B
                                                                                                                                                                                                                                                                                 (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::BINDING))
                                                                                                                                                                                                                                                   (DREYECK/HYPERDOC/CURATION::LOOKUP
                                                                                                                                                                                                                                                                                      (COMMON-LISP:AND
                                                                                                                                                                                                                                                                                                       (COMMON-LISP:CONSP
                                                                                                                                                                                                                                                                                                                          DREYECK/HYPERDOC/CURATION::B)
                                                                                                                                                                                                                                                                                                       (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                                                                                           DREYECK/HYPERDOC/CURATION::B)))
                                                                                                                                                                                                                                                   (DREYECK/HYPERDOC/CURATION::P
                                                                                                                                                                                                                                                                                 (COMMON-LISP:AND
                                                                                                                                                                                                                                                                                                  (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                                                                                                                   DREYECK/HYPERDOC/CURATION::LOOKUP
                                                                                                                                                                                                                                                                                                                                   "FIND-PAGE")
                                                                                                                                                                                                                                                                                                  (DREYECK/HYPERDOC/CURATION::NAMED-PAGE
                                                                                                                                                                                                                                                                                                                                         (COMMON-LISP:THIRD
                                                                                                                                                                                                                                                                                                                                                            DREYECK/HYPERDOC/CURATION::LOOKUP)))))
                                                                                                                                                                                                                                                  (COMMON-LISP:WHEN
                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::P
                                                                                                                                                                                                                                                                    (COMMON-LISP:LET*
                                                                                                                                                                                                                                                                                      ((VARIABLE-KEY
                                                                                                                                                                                                                                                                                                     (DREYECK/HYPERDOC/CURATION::TOKEN-KEY
                                                                                                                                                                                                                                                                                                                                           (COMMON-LISP:FIRST
                                                                                                                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::B)))
                                                                                                                                                                                                                                                                                       (DREYECK/HYPERDOC/CURATION::USES
                                                                                                                                                                                                                                                                                                                        (MAPCAN
                                                                                                                                                                                                                                                                                                                                (LAMBDA
                                                                                                                                                                                                                                                                                                                                        (DREYECK/HYPERDOC/CURATION::BODY-NODE)
                                                                                                                                                                                                                                                                                                                                        (LEXICAL-PAGE-CONTRACT-USES
                                                                                                                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::BODY-NODE
                                                                                                                                                                                                                                                                                                                                                                    VARIABLE-KEY))
                                                                                                                                                                                                                                                                                                                                DREYECK/HYPERDOC/CURATION::BODY)))
                                                                                                                                                                                                                                                                                      (COMMON-LISP:DOLIST
                                                                                                                                                                                                                                                                                                          (DREYECK/HYPERDOC/CURATION::USE-NODE
                                                                                                                                                                                                                                                                                                                                               DREYECK/HYPERDOC/CURATION::USES)
                                                                                                                                                                                                                                                                                                          (COMMON-LISP:LET
                                                                                                                                                                                                                                                                                                                           ((DREYECK/HYPERDOC/CURATION::USE
                                                                                                                                                                                                                                                                                                                                                            (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                                                                                                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::USE-NODE)))
                                                                                                                                                                                                                                                                                                                           (COMMON-LISP:SETF
                                                                                                                                                                                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::RECOGNIZED
                                                                                                                                                                                                                                                                                                                                             COMMON-LISP:T)
                                                                                                                                                                                                                                                                                                                           (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                                                                                                                                                                                                                                            :TESTS-PAGE
                                                                                                                                                                                                                                                                                                                                                            (COMMON-LISP:GETF
                                                                                                                                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                                                                                                                                              :ID)
                                                                                                                                                                                                                                                                                                                                                            (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                                                                                                                                                                                                                                                                                DREYECK/HYPERDOC/CURATION::P)
                                                                                                                                                                                                                                                                                                                                                            :SOURCE-OBSERVED
                                                                                                                                                                                                                                                                                                                                                            (COMMON-LISP:LIST
                                                                                                                                                                                                                                                                                                                                                                              :BINDING
                                                                                                                                                                                                                                                                                                                                                                              (DREYECK/HYPERDOC/CURATION::WARRANT
                                                                                                                                                                                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::BINDING
                                                                                                                                                                                                                                                                                                                                                                                                                  :LET-FIND-PAGE-BINDING)
                                                                                                                                                                                                                                                                                                                                                                              :USE
                                                                                                                                                                                                                                                                                                                                                                              (DREYECK/HYPERDOC/CURATION::WARRANT
                                                                                                                                                                                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::USE-NODE
                                                                                                                                                                                                                                                                                                                                                                                                                  :LEXICALLY-BOUND-PAGE-EXECUTABLE-CONTRACT)
                                                                                                                                                                                                                                                                                                                                                                              :CALLER-CONTRACT
                                                                                                                                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::CONTRACT))
                                                                                                                                                                                                                                                                                                                           (COMMON-LISP:LET
                                                                                                                                                                                                                                                                                                                                            ((DREYECK/HYPERDOC/CURATION::ID
                                                                                                                                                                                                                                                                                                                                                                            (DREYECK/HYPERDOC/CURATION::TOPIC
                                                                                                                                                                                                                                                                                                                                                                                                              (COMMON-LISP:FORMAT
                                                                                                                                                                                                                                                                                                                                                                                                                                  NIL
                                                                                                                                                                                                                                                                                                                                                                                                                                  "expression:~S"
                                                                                                                                                                                                                                                                                                                                                                                                                                  (COMMON-LISP:THIRD
                                                                                                                                                                                                                                                                                                                                                                                                                                                     DREYECK/HYPERDOC/CURATION::USE))
                                                                                                                                                                                                                                                                                                                                                                                                              :EXPRESSION-TEXT
                                                                                                                                                                                                                                                                                                                                                                                                              (COMMON-LISP:THIRD
                                                                                                                                                                                                                                                                                                                                                                                                                                 DREYECK/HYPERDOC/CURATION::USE)
                                                                                                                                                                                                                                                                                                                                                                                                              (COMMON-LISP:THIRD
                                                                                                                                                                                                                                                                                                                                                                                                                                 DREYECK/HYPERDOC/CURATION::USE))))
                                                                                                                                                                                                                                                                                                                                            (DREYECK/HYPERDOC/CURATION::SOURCE-EDGE
                                                                                                                                                                                                                                                                                                                                                                                    :ASSERTS-EXPRESSION-TEXT
                                                                                                                                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::USE-NODE
                                                                                                                                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::ID
                                                                                                                                                                                                                                                                                                                                                                                    :EXECUTABLE-CONTRACT-LITERAL-ARGUMENT
                                                                                                                                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::CONTRACT)))))))))))))
                     (:literal-page-lookup
                      (dolist (node (literal-page-lookups r))
                        (let ((page (named-page
                                     (third (concrete-syntax-tree:raw node)))))
                          (when page
                            (setf recognized t)
                            (source-edge :looks-up-page r node (page-id page)
                                         :literal-hyperbook-find-page-call
                                         contract)))))
                                                                                                                 (:SYMBOL-EXISTENCE
                                                                                                                                    (COMMON-LISP:DOLIST
                                                                                                                                                        (DREYECK/HYPERDOC/CURATION::N
                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::NODES)
                                                                                                                                                        (COMMON-LISP:LET*
                                                                                                                                                                          ((DREYECK/HYPERDOC/CURATION::F
                                                                                                                                                                                                         (CONCRETE-SYNTAX-TREE:RAW
                                                                                                                                                                                                                                   DREYECK/HYPERDOC/CURATION::N))
                                                                                                                                                                           (COMMON-LISP:CONDITION
                                                                                                                                                                                                  (COMMON-LISP:AND
                                                                                                                                                                                                                   (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::F
                                                                                                                                                                                                                                                    "CHECK")
                                                                                                                                                                                                                   (COMMON-LISP:SECOND
                                                                                                                                                                                                                                       DREYECK/HYPERDOC/CURATION::F)))
                                                                                                                                                                           (DREYECK/HYPERDOC/CURATION::QUOTED
                                                                                                                                                                                                              (COMMON-LISP:AND
                                                                                                                                                                                                                               (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                                                COMMON-LISP:CONDITION
                                                                                                                                                                                                                                                                "FBOUNDP")
                                                                                                                                                                                                                               (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                   COMMON-LISP:CONDITION)))
                                                                                                                                                                           (DREYECK/HYPERDOC/CURATION::DEFINITION
                                                                                                                                                                                                                  (COMMON-LISP:AND
                                                                                                                                                                                                                                   (DREYECK/HYPERDOC/CURATION::OP-P
                                                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::QUOTED
                                                                                                                                                                                                                                                                    "QUOTE")
                                                                                                                                                                                                                                   (DREYECK/HYPERDOC/CURATION::RESOLVE-RECORD
                                                                                                                                                                                                                                                                              (COMMON-LISP:SECOND
                                                                                                                                                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::QUOTED)
                                                                                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::RECORDS))))
                                                                                                                                                                          (COMMON-LISP:WHEN
                                                                                                                                                                                            DREYECK/HYPERDOC/CURATION::DEFINITION
                                                                                                                                                                                            (COMMON-LISP:SETF
                                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::RECOGNIZED
                                                                                                                                                                                                              COMMON-LISP:T)
                                                                                                                                                                                            (DREYECK/HYPERDOC/CURATION::SOURCE-EDGE
                                                                                                                                                                                                                                    :ASSERTS-FBOUNDP
                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::R
                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::N
                                                                                                                                                                                                                                    (COMMON-LISP:GETF
                                                                                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::DEFINITION
                                                                                                                                                                                                                                                      :ID)
                                                                                                                                                                                                                                    :CHECK-FBOUNDP-QUOTED-SYMBOL
                                                                                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::CONTRACT)))))
                                                                                                                 (COMMON-LISP:OTHERWISE
                                                                                                                                        (COMMON-LISP:ERROR
                                                                                                                                                           "Unknown bounded contract role ~S."
                                                                                                                                                           (COMMON-LISP:GETF
                                                                                                                                                                             DREYECK/HYPERDOC/CURATION::CONTRACT
                                                                                                                                                                             :ROLE))))
                                                                                               (COMMON-LISP:UNLESS
                                                                                                                   DREYECK/HYPERDOC/CURATION::RECOGNIZED
                                                                                                                   (COMMON-LISP:ERROR
                                                                                                                                      "Declared contract has no supported structural evidence: ~S."
                                                                                                                                      DREYECK/HYPERDOC/CURATION::CONTRACT))))
                                                         (DREYECK/TOPICMAP:MAKE-TOPICMAP-WORKSPACE
                                                                                                   (DREYECK/TOPICMAP:MAKE-TOPICMAP-PROJECTION
                                                                                                                                              :SOURCE
                                                                                                                                              (COMMON-LISP:LIST
                                                                                                                                                                :KIND
                                                                                                                                                                :CURATION-REFERENCE
                                                                                                                                                                :BOOK
                                                                                                                                                                DREYECK/HYPERDOC/CURATION::BOOK
                                                                                                                                                                :SOURCE-FILES
                                                                                                                                                                DREYECK/HYPERDOC/CURATION::SOURCE-FILES
                                                                                                                                                                :CONTRACTS
                                                                                                                                                                DREYECK/HYPERDOC/CURATION::CONTRACTS
                                                                                                                                                                :DIAGNOSTICS
                                                                                                                                                                (COMMON-LISP:NREVERSE
                                                                                                                                                                                      DREYECK/HYPERDOC/CURATION::DIAGNOSTICS)
                                                                                                                                                                :LIMITS
                                                                                                                                                                :BOUNDED-STRUCTURAL-PATTERNS-NOT-COMPLETE-CALL-GRAPH)
                                                                                                                                              :TOPICS
                                                                                                                                              (COMMON-LISP:NREVERSE
                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::TOPICS)
                                                                                                                                              :ASSOCIATIONS
                                                                                                                                              (COMMON-LISP:NREVERSE
                                                                                                                                                                    DREYECK/HYPERDOC/CURATION::EDGES))
                                                                                                   (DREYECK/HYPERDOC/CURATION::PAGE-ID
                                                                                                                                       DREYECK/HYPERDOC/CURATION::PAGE)))))

(COMMON-LISP:DEFUN DREYECK/HYPERDOC/CURATION:HYPERDOC-REMOVAL-IMPACT
                   (DREYECK/HYPERDOC/CURATION::PROJECTION
                                                          DREYECK/HYPERDOC/CURATION::TARGET)
                   "Interpret HyperDoc relations for the generic hypothetical-cut machinery."
                   (COMMON-LISP:LET
                                    ((DREYECK/HYPERDOC/CURATION::CUT
                                                                     (COMMON-LISP:LIST
                                                                                       DREYECK/HYPERDOC/CURATION::TARGET))
                                     (DREYECK/HYPERDOC/CURATION::FINDINGS NIL)
                                     (DREYECK/HYPERDOC/CURATION::EDGES
                                                                       (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                                                                                                                             DREYECK/HYPERDOC/CURATION::PROJECTION)))
                                    (COMMON-LISP:LABELS
                                                        ((DREYECK/HYPERDOC/CURATION::FINDING
                                                                                             (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                              DREYECK/HYPERDOC/CURATION::CATEGORY
                                                                                                                              DREYECK/HYPERDOC/CURATION::RULE)
                                                                                             (COMMON-LISP:PUSH
                                                                                                               (COMMON-LISP:LIST
                                                                                                                                 :TARGET
                                                                                                                                 (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                                                                                                                                                                DREYECK/HYPERDOC/CURATION::EDGE)
                                                                                                                                 :CATEGORY
                                                                                                                                 DREYECK/HYPERDOC/CURATION::CATEGORY
                                                                                                                                 :RULE
                                                                                                                                 DREYECK/HYPERDOC/CURATION::RULE
                                                                                                                                 :EDGES
                                                                                                                                 (COMMON-LISP:LIST
                                                                                                                                                   DREYECK/HYPERDOC/CURATION::EDGE))
                                                                                                               DREYECK/HYPERDOC/CURATION::FINDINGS)))
                                                        (COMMON-LISP:DOLIST
                                                                            (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                             DREYECK/HYPERDOC/CURATION::EDGES)
                                                                            (COMMON-LISP:WHEN
                                                                                              (COMMON-LISP:AND
                                                                                                               (COMMON-LISP:EQUAL
                                                                                                                                  DREYECK/HYPERDOC/CURATION::TARGET
                                                                                                                                  (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                                                                                                                                                               DREYECK/HYPERDOC/CURATION::EDGE))
                                                                                                               (COMMON-LISP:EQ
                                                                                                                               :SOURCE-OF-PAGE
                                                                                                                               (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::EDGE)))
                                                                                              (COMMON-LISP:PUSHNEW
                                                                                                                   (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                                                                                                                                                  DREYECK/HYPERDOC/CURATION::EDGE)
                                                                                                                   DREYECK/HYPERDOC/CURATION::CUT
                                                                                                                   :TEST
                                                                                                                   (FUNCTION
                                                                                                                             COMMON-LISP:EQUAL))
                                                                                              (DREYECK/HYPERDOC/CURATION::FINDING
                                                                                                                                  DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                  :REMOVE-WITH-PAGE
                                                                                                                                  :PAGE-SOURCE-CUT)))
                                                        (COMMON-LISP:DOLIST
                                                                            (DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                             DREYECK/HYPERDOC/CURATION::EDGES)
                                                                            (COMMON-LISP:WHEN
                                                                                              (COMMON-LISP:AND
                                                                                                               (COMMON-LISP:EQUAL
                                                                                                                                  DREYECK/HYPERDOC/CURATION::TARGET
                                                                                                                                  (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                                                                                                                                                               DREYECK/HYPERDOC/CURATION::EDGE))
                                                                                                               (COMMON-LISP:NOT
                                                                                                                                (COMMON-LISP:MEMBER
                                                                                                                                                    (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                                                                                                                                                                                   DREYECK/HYPERDOC/CURATION::EDGE)
                                                                                                                                                    DREYECK/HYPERDOC/CURATION::CUT
                                                                                                                                                    :TEST
                                                                                                                                                    (FUNCTION
                                                                                                                                                              COMMON-LISP:EQUAL))))
                                                                                              (COMMON-LISP:CASE
                                                                                                                (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                                                                                                                                                               DREYECK/HYPERDOC/CURATION::EDGE)
                                                                                                                ((:LINKS-TO-PAGE
                                                                                                                                 :ASSERTS-PAGE-PRESENCE)
                                                                                                                 (DREYECK/HYPERDOC/CURATION::FINDING
                                                                                                                                                     DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                                     :MUST-EDIT
                                                                                                                                                     :INCOMING-PAGE-REFERENCE))
                                                                                                                (:LOOKS-UP-PAGE
             (DREYECK/HYPERDOC/CURATION::FINDING
              DREYECK/HYPERDOC/CURATION::EDGE
              :MUST-EDIT-OR-DELETE :EXECUTABLE-PAGE-DEPENDENCY))
            ((:ASSERTS-NAVIGATION
                                                                                                                                      :TESTS-PAGE)
                                                                                                                 (DREYECK/HYPERDOC/CURATION::FINDING
                                                                                                                                                     DREYECK/HYPERDOC/CURATION::EDGE
                                                                                                                                                     :MUST-EDIT-OR-DELETE
                                                                                                                                                     :PAGE-CONTRACT)))))
                                                        (COMMON-LISP:VALUES
                                                                            DREYECK/HYPERDOC/CURATION::CUT
                                                                            (COMMON-LISP:NREVERSE
                                                                                                  DREYECK/HYPERDOC/CURATION::FINDINGS)
                                                                            (COMMON-LISP:REMOVE-IF-NOT
                                                                                                       (COMMON-LISP:LAMBDA
                                                                                                                           (DREYECK/HYPERDOC/CURATION::EDGE)
                                                                                                                           (COMMON-LISP:MEMBER
                                                                                                                                               (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                                                                                                                                                                                              DREYECK/HYPERDOC/CURATION::EDGE)
                                                                                                                                               (QUOTE
                                                                                                                                                      (:EXPOSES-EXECUTABLE-LINK
                                                                                                                                                                                :INVOKES
                                                                                                                                                                                :PRESENTS-SOURCE-OF))))
                                                                                                       DREYECK/HYPERDOC/CURATION::EDGES)))))

(defun parse-html-source-views (pathname)
  "Parse with Plump, retaining exact source spans for source-view elements.
The dispatcher is dynamically scoped; ordinary parser behavior is unchanged."
  (let* ((source (uiop:read-file-string pathname))
         (records nil)
         (dispatcher
           (plump-parser::make-tag-dispatcher
            :name 'curation-source-view
            :test (lambda (name) (string-equal name "source-of-function"))
            :parser
            (lambda (name)
              (let* ((start (- plump-lexer:*index* (length name) 1))
                     (element (plump-parser::read-standard-tag name))
                     (end plump-lexer:*index*))
                (when element
                  (push (cons element
                              (list :kind :html-source-element :pathname pathname
                                    :region (cons start end)
                                    :source (subseq source start end)
                                    :tag "source-of-function"))
                        records))
                element))))
         (plump-parser:*tag-dispatchers*
           (cons dispatcher plump-parser:*tag-dispatchers*)))
    (let ((dom (plump:parse source)))
      (values dom (nreverse records)))))

(defun source-view-function-record (element package records)
  "Resolve one named function without evaluating source-view content."
  (when (and package
             (every (lambda (child) (typep child 'plump:text-node))
                    (plump:children element)))
    (multiple-value-bind (code recovered)
        (html-inspector-views/standard:parse-lisp-code (plump:text element) package)
      (unless recovered
        (let ((tops (html-inspector-views/standard:top-level-forms-of code)))
          (when (= 1 (length tops))
            (let* ((raw (concrete-syntax-tree:raw
                         (html-inspector-views/standard:cst-of (first tops))))
                   (record (and (not (consp raw)) (resolve-record raw records))))
              (when (and record
                         (member (token-name (first (getf record :raw)))
                                 '("DEFUN" "DEFEXAMPLE") :test #'equal))
                record))))))))


