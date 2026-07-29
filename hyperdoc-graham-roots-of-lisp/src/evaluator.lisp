;;;; A traced Common Lisp host implementation of Graham's evaluator.
;;;;
;;;; The object language is represented by ordinary Common Lisp cons trees and
;;;; symbols. The host reader produces data; CL:EVAL is never used.

(in-package #:hyperdoc-graham-roots-of-lisp)

(defvar *roots-trace-events* nil)
(defvar *roots-trace-sequence* 0)
(defvar *roots-trace-depth* 0)
(defvar *roots-trace-limit* 1000)
(defvar *roots-trace-truncated-p* nil)
(defvar *roots-named-call-rule* :graham-corrected)

(defun roots-normalize-named-call-rule (rule)
  (unless (member rule '(:mccarthy-paper :graham-corrected))
    (error "Unknown Roots named-call rule ~S." rule))
  rule)

(defun roots-object-package ()
  (or (find-package "HYPERDOC-GRAHAM-ROOTS-OF-LISP/OBJECT")
      (error "The Roots object-language package is not available.")))

(defun roots-object-symbol (name)
  (intern (string-upcase (string name)) (roots-object-package)))

(defun roots-object-name= (object name)
  (and (symbolp object)
       (string= (symbol-name object)
                (string-upcase (string name)))))

(defun roots-object-equal (left right)
  "Structural equality for test expectations across package boundaries."
  (cond
    ((and (symbolp left) (symbolp right))
     (string= (symbol-name left) (symbol-name right)))
    ((and (consp left) (consp right))
     (and (roots-object-equal (car left) (car right))
          (roots-object-equal (cdr left) (cdr right))))
    (t
     (eql left right))))

(defun roots-copy-tree (object)
  (if (consp object)
      (cons (roots-copy-tree (car object))
            (roots-copy-tree (cdr object)))
      object))

(defun roots-record-event
    (kind &key expression environment detail result
                (depth *roots-trace-depth*))
  (cond
    ((< *roots-trace-sequence* *roots-trace-limit*)
     (incf *roots-trace-sequence*)
     (push (make-instance
            'roots-trace-event
            :sequence *roots-trace-sequence*
            :depth depth
            :kind kind
            :expression (roots-copy-tree expression)
            :environment (roots-copy-tree environment)
            :detail (roots-copy-tree detail)
            :result (roots-copy-tree result))
           *roots-trace-events*))
    (t
     (setf *roots-trace-truncated-p* t)))
  nil)

(defun roots-fail (expression environment format-control &rest arguments)
  (error 'roots-language-error
         :expression (roots-copy-tree expression)
         :environment (roots-copy-tree environment)
         :reason (apply #'format nil format-control arguments)))

(defun roots-environment-lookup (name environment)
  "Return two values: the newest binding for NAME and whether it exists."
  (loop for binding in environment
        when (and (consp binding)
                  (symbolp (first binding))
                  (roots-object-name= (first binding) name))
          do (return (values (second binding) t))
        finally (return (values nil nil))))

(defun roots-ensure-arity (operator arguments expected expression environment)
  (let ((actual
          (handler-case
              (length arguments)
            (type-error () nil))))
    (unless (and actual (= actual expected))
      (roots-fail expression environment
                  "~A expects ~D argument~:P, received ~S."
                  operator expected arguments))))

(defun roots-boolean (value)
  (if value t nil))

(defun roots-eval-list (expressions environment)
  (cond
    ((null expressions) nil)
    ((consp expressions)
     (cons (roots-eval (car expressions) environment)
           (roots-eval-list (cdr expressions) environment)))
    (t
     (roots-fail expressions environment
                 "An argument sequence must be a proper list."))))

(defun roots-pair (parameters values expression environment)
  (cond
    ((and (null parameters) (null values)) nil)
    ((and (consp parameters) (consp values))
     (cons (list (car parameters) (car values))
           (roots-pair (cdr parameters)
                       (cdr values)
                       expression
                       environment)))
    (t
     (roots-fail expression environment
                 "Lambda parameter and argument counts differ: ~S versus ~S."
                 parameters values))))

(defun roots-eval-cond (clauses environment whole-expression)
  (cond
    ((null clauses)
     (roots-fail whole-expression environment
                 "No COND clause succeeded."))
    ((not (and (consp (car clauses))
               (consp (cdr (car clauses)))
               (null (cddr (car clauses)))))
     (roots-fail whole-expression environment
                 "Each COND clause must contain a predicate and result: ~S."
                 (car clauses)))
    (t
     (let* ((clause (car clauses))
            (predicate-form (first clause))
            (result-form (second clause))
            (predicate-value (roots-eval predicate-form environment)))
       (roots-record-event
        :cond-test
        :expression predicate-form
        :environment environment
        :detail (list :clause clause
                      :predicate-value predicate-value))
       (if predicate-value
           (progn
             (roots-record-event
              :cond-selected
              :expression result-form
              :environment environment
              :detail (list :clause clause))
             (roots-eval result-form environment))
           (roots-eval-cond (cdr clauses)
                            environment
                            whole-expression))))))

(defun roots-eval-atomic-operator (expression environment)
  (let ((operator (car expression))
        (arguments (cdr expression)))
    (cond
      ((roots-object-name= operator "QUOTE")
       (roots-ensure-arity "QUOTE" arguments 1 expression environment)
       (let ((result (first arguments)))
         (roots-record-event
          :quote
          :expression expression
          :environment environment
          :result result)
         result))

      ((roots-object-name= operator "ATOM")
       (roots-ensure-arity "ATOM" arguments 1 expression environment)
       (let* ((value (roots-eval (first arguments) environment))
              (result (roots-boolean (atom value))))
         (roots-record-event
          :primitive
          :expression expression
          :environment environment
          :detail (list :operator 'atom :arguments (list value))
          :result result)
         result))

      ((roots-object-name= operator "EQ")
       (roots-ensure-arity "EQ" arguments 2 expression environment)
       (let* ((left (roots-eval (first arguments) environment))
              (right (roots-eval (second arguments) environment))
              (result
                (roots-boolean
                 (and (atom left)
                      (atom right)
                      (eql left right)))))
         (roots-record-event
          :primitive
          :expression expression
          :environment environment
          :detail (list :operator 'eq :arguments (list left right))
          :result result)
         result))

      ((roots-object-name= operator "CAR")
       (roots-ensure-arity "CAR" arguments 1 expression environment)
       (let ((value (roots-eval (first arguments) environment)))
         (unless (consp value)
           (roots-fail expression environment
                       "CAR expects a non-empty list, received ~S." value))
         (let ((result (car value)))
           (roots-record-event
            :primitive
            :expression expression
            :environment environment
            :detail (list :operator 'car :arguments (list value))
            :result result)
           result)))

      ((roots-object-name= operator "CDR")
       (roots-ensure-arity "CDR" arguments 1 expression environment)
       (let ((value (roots-eval (first arguments) environment)))
         (unless (consp value)
           (roots-fail expression environment
                       "CDR expects a non-empty list, received ~S." value))
         (let ((result (cdr value)))
           (roots-record-event
            :primitive
            :expression expression
            :environment environment
            :detail (list :operator 'cdr :arguments (list value))
            :result result)
           result)))

      ((roots-object-name= operator "CONS")
       (roots-ensure-arity "CONS" arguments 2 expression environment)
       (let* ((head (roots-eval (first arguments) environment))
              (tail (roots-eval (second arguments) environment))
              (result (cons head tail)))
         (roots-record-event
          :primitive
          :expression expression
          :environment environment
          :detail (list :operator 'cons :arguments (list head tail))
          :result result)
         result))

      ((roots-object-name= operator "COND")
       (roots-eval-cond arguments environment expression))

      ;; LIST is not an eighth primitive. Graham introduces it as an
      ;; abbreviation for nested CONS. The adapter recognizes it explicitly so
      ;; the paper's PAIR. definition can be entered unchanged.
      ((roots-object-name= operator "LIST")
       (let ((result (roots-eval-list arguments environment)))
         (roots-record-event
          :surface-abbreviation
          :expression expression
          :environment environment
          :detail (list :abbreviation 'list)
          :result result)
         result))

      (t
       (multiple-value-bind (function found-p)
           (roots-environment-lookup operator environment)
         (unless found-p
           (roots-fail expression environment
                       "Unbound operator ~S." operator))
         (ecase *roots-named-call-rule*
           (:graham-corrected
            (let ((rewritten (cons function arguments)))
              (roots-record-event
               :named-operator-rewrite
               :expression expression
               :environment environment
               :detail (list :rule :graham-corrected
                             :operator operator
                             :function function
                             :rewritten rewritten))
              (roots-eval rewritten environment)))
           (:mccarthy-paper
            (let* ((evaluated-arguments
                     (roots-eval-list arguments environment))
                   (rewritten (cons function evaluated-arguments)))
              (roots-record-event
               :named-operator-rewrite
               :expression expression
               :environment environment
               :detail (list :rule :mccarthy-paper
                             :operator operator
                             :function function
                             :evaluated-arguments evaluated-arguments
                             :rewritten rewritten))
              (roots-eval rewritten environment)))))))))

(defun roots-eval-compound-operator (expression environment)
  (let ((operator (car expression))
        (arguments (cdr expression)))
    (cond
      ((and (consp operator)
            (roots-object-name= (car operator) "LABEL"))
       (unless (and (consp (cdr operator))
                    (consp (cddr operator))
                    (null (cdddr operator)))
         (roots-fail expression environment
                     "LABEL must have a name and function expression: ~S."
                     operator))
       (let* ((name (second operator))
              (function (third operator))
              (extended-environment
                (cons (list name operator) environment))
              (rewritten (cons function arguments)))
         (roots-record-event
          :label-bind
          :expression expression
          :environment extended-environment
          :detail (list :name name
                        :function operator
                        :rewritten rewritten))
         (roots-eval rewritten extended-environment)))

      ((and (consp operator)
            (roots-object-name= (car operator) "LAMBDA"))
       (unless (and (consp (cdr operator))
                    (consp (cddr operator))
                    (null (cdddr operator)))
         (roots-fail expression environment
                     "LAMBDA must have parameters and one body: ~S."
                     operator))
       (let* ((parameters (second operator))
              (body (third operator))
              (values (roots-eval-list arguments environment))
              (bindings (roots-pair parameters
                                    values
                                    expression
                                    environment))
              ;; This is the dynamic environment of McCarthy/Graham's
              ;; evaluator, not a Common Lisp lexical closure.
              (extended-environment (append bindings environment)))
         (roots-record-event
          :lambda-bind
          :expression expression
          :environment extended-environment
          :detail (list :parameters parameters
                        :values values
                        :bindings bindings
                        :body body))
         (roots-eval body extended-environment)))

      (t
       (roots-fail expression environment
                   "The operator must be an atom, LABEL, or LAMBDA: ~S."
                   operator)))))

(defun roots-eval-step (expression environment)
  (cond
    ((atom expression)
     (multiple-value-bind (value found-p)
         (roots-environment-lookup expression environment)
       (unless found-p
         (roots-fail expression environment
                     "Unbound atom ~S." expression))
       (roots-record-event
        :atom-lookup
        :expression expression
        :environment environment
        :detail (list :name expression)
        :result value)
       value))
    ((atom (car expression))
     (roots-eval-atomic-operator expression environment))
    (t
     (roots-eval-compound-operator expression environment))))

(defun roots-eval (expression environment)
  "Evaluate one already-read object-language EXPRESSION in ENVIRONMENT.

ENVIRONMENT is Graham's association list of two-element lists. The function
is deliberately small enough to read next to the paper's EVAL. definition."
  (let ((depth *roots-trace-depth*))
    (roots-record-event
     :enter
     :expression expression
     :environment environment
     :depth depth)
    (let ((*roots-trace-depth* (1+ depth)))
      (handler-case
          (let ((result (roots-eval-step expression environment)))
            (roots-record-event
             :return
             :expression expression
             :environment environment
             :result result
             :depth depth)
            result)
        (roots-language-error (condition)
          (roots-record-event
           :error
           :expression expression
           :environment environment
           :detail (roots-language-error-reason-of condition)
           :depth depth)
          (error condition))))))

(defun roots-evaluate
    (expression &key (environment nil) source (event-limit 1000)
                     (signal-error nil)
                     (named-call-rule :graham-corrected))
  "Return an inspectable ROOTS-EVALUATION for EXPRESSION."
  (let ((*roots-trace-events* nil)
        (*roots-trace-sequence* 0)
        (*roots-trace-depth* 0)
        (*roots-trace-limit* event-limit)
        (*roots-trace-truncated-p* nil)
        (*roots-named-call-rule*
          (roots-normalize-named-call-rule named-call-rule)))
    (handler-case
        (let ((result (roots-eval expression environment)))
          (make-instance
           'roots-evaluation
           :source source
           :expression (roots-copy-tree expression)
           :environment (roots-copy-tree environment)
           :result (roots-copy-tree result)
           :status :ok
           :events (nreverse *roots-trace-events*)
           :trace-truncated-p *roots-trace-truncated-p*))
      (condition (condition)
        (when signal-error
          (error condition))
        (make-instance
         'roots-evaluation
         :source source
         :expression (roots-copy-tree expression)
         :environment (roots-copy-tree environment)
         :status :error
         :events (nreverse *roots-trace-events*)
         :condition condition
         :trace-truncated-p *roots-trace-truncated-p*)))))

(defun roots-read-program (source)
  "Read SOURCE as zero or more object-language forms.

Returns three values: forms, status (:COMPLETE, :INCOMPLETE, or :READER-ERROR),
and a condition when applicable. Common Lisp's reader is used only as a parser;
*READ-EVAL* is NIL."
  (let ((*package* (roots-object-package))
        (*read-eval* nil)
        (eof (gensym "EOF")))
    (with-input-from-string (stream source)
      (handler-case
          (values
           (loop for form = (read stream nil eof)
                 until (eq form eof)
                 collect form)
           :complete
           nil)
        (end-of-file (condition)
          (values nil :incomplete condition))
        (reader-error (condition)
          (values nil :reader-error condition))))))

(defun roots-read-form (source)
  "Read exactly one object-language form from SOURCE."
  (multiple-value-bind (forms status condition)
      (roots-read-program source)
    (unless (eq status :complete)
      (error "Cannot read Roots form (~A): ~A" status condition))
    (unless (= (length forms) 1)
      (error "Expected exactly one Roots form, read ~D." (length forms)))
    (first forms)))

(defun roots-evaluate-source
    (source &key (environment nil) (event-limit 1000) (signal-error nil)
                 (named-call-rule :graham-corrected))
  "Read and evaluate one form from SOURCE."
  (let ((expression (roots-read-form source)))
    (roots-evaluate expression
                    :environment environment
                    :source source
                    :event-limit event-limit
                    :signal-error signal-error
                    :named-call-rule named-call-rule)))
