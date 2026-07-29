;;;; Stateful top-level adapter corresponding to the Stanford web interpreter.

(in-package #:hyperdoc-graham-roots-of-lisp)

(defun make-roots-session (&key (environment nil))
  (make-instance 'roots-session
                 :environment (roots-copy-tree environment)))

(defun roots-session-define (session name function-expression)
  "Install a newest-first top-level function binding in SESSION."
  (push (list name function-expression)
        (session-environment-of session))
  (let ((result
          (list :kind :definition
                :name name
                :value function-expression)))
    (push result (history-of session))
    result))

(defun roots-session-evaluate
    (session expression &key source (event-limit 1000) (signal-error nil))
  "Evaluate EXPRESSION in SESSION without changing its environment."
  (let ((evaluation
          (roots-evaluate
           expression
           :environment (session-environment-of session)
           :source source
           :event-limit event-limit
           :signal-error signal-error)))
    (push evaluation (history-of session))
    evaluation))

(defun roots-defun-form-p (form)
  (and (consp form)
       (roots-object-name= (car form) "DEFUN")))

(defun roots-top-level-label-form-p (form)
  (and (consp form)
       (roots-object-name= (car form) "LABEL")))

(defun roots-interpret-form
    (session form &key source (event-limit 1000) (signal-error nil))
  "Interpret one top-level FORM.

DEFUN and top-level LABEL mutate the session environment. Other forms are
evaluated by the Graham evaluator. This top-level mutation is an adapter layer,
not part of the seven-operator semantic core."
  (cond
    ((roots-defun-form-p form)
     (unless (and (consp (cdr form))
                  (consp (cddr form))
                  (consp (cdddr form))
                  (null (cddddr form)))
       (error "DEFUN must have a name, parameter list, and one body: ~S." form))
     (roots-session-define
      session
      (second form)
      (list (roots-object-symbol "LAMBDA")
            (third form)
            (fourth form))))

    ((roots-top-level-label-form-p form)
     (unless (and (consp (cdr form))
                  (consp (cddr form))
                  (null (cdddr form)))
       (error "Top-level LABEL must have a name and function: ~S." form))
     (roots-session-define session (second form) (third form)))

    (t
     (roots-session-evaluate
      session
      form
      :source source
      :event-limit event-limit
      :signal-error signal-error))))

(defun roots-interpret-string
    (source &key (session (make-roots-session)) (event-limit 1000)
                 (stop-on-error t))
  "Read and interpret every form in SOURCE, returning a ROOTS-TRANSCRIPT."
  (multiple-value-bind (forms read-status read-condition)
      (roots-read-program source)
    (unless (eq read-status :complete)
      (return-from roots-interpret-string
        (make-instance
         'roots-transcript
         :source source
         :forms nil
         :results nil
         :environment (roots-copy-tree (session-environment-of session))
         :status read-status
         :condition read-condition)))
    (let ((results nil)
          (status :ok)
          (condition nil))
      (dolist (form forms)
        (handler-case
            (let ((result
                    (roots-interpret-form
                     session
                     form
                     :source source
                     :event-limit event-limit)))
              (push result results)
              (when (and (typep result 'roots-evaluation)
                         (eq (status-of result) :error))
                (setf status :evaluation-error
                      condition (condition-of result))
                (when stop-on-error
                  (return))))
          (condition (caught)
            (setf status :adapter-error
                  condition caught)
            (when stop-on-error
              (return)))))
      (make-instance
       'roots-transcript
       :source source
       :forms forms
       :results (nreverse results)
       :environment (roots-copy-tree (session-environment-of session))
       :status status
       :condition condition))))

(defun roots-ad-strings (length)
  (if (zerop length)
      (list "")
      (loop for prefix in (roots-ad-strings (1- length))
            append (list (concatenate 'string prefix "A")
                         (concatenate 'string prefix "D")))))

(defun roots-accessor-body (letters variable)
  (let ((form variable))
    (loop for character across (reverse letters)
          do (setf form
                   (list (roots-object-symbol
                          (if (char-equal character #\A) "CAR" "CDR"))
                         form)))
    form))

(defun roots-accessor-definition (letters)
  (let* ((name (roots-object-symbol
                (format nil "C~AR" (string-downcase letters))))
         (x (roots-object-symbol "X")))
    (list (roots-object-symbol "DEFUN")
          name
          (list x)
          (roots-accessor-body letters x))))

(defun roots-preload-accessors (session)
  "Define CAAR through CDDDDR as paper-level abbreviations."
  (loop for length from 2 to 4
        append
        (loop for letters in (roots-ad-strings length)
              collect
              (roots-interpret-form
               session
               (roots-accessor-definition letters)))))

(defparameter *roots-graham-library-source*
  "
(defun null. (x)
  (eq x '()))

(defun and. (x y)
  (cond (x (cond (y 't) ('t '())))
        ('t '())))

(defun not. (x)
  (cond (x '())
        ('t 't)))

(defun append. (x y)
  (cond ((null. x) y)
        ('t (cons (car x) (append. (cdr x) y)))))

(defun pair. (x y)
  (cond ((and. (null. x) (null. y)) '())
        ((and. (not. (atom x)) (not. (atom y)))
         (cons (list (car x) (car y))
               (pair. (cdr x) (cdr y))))))

(defun assoc. (x y)
  (cond ((eq (caar y) x) (cadar y))
        ('t (assoc. x (cdr y)))))

(defun eval. (e a)
  (cond
    ((atom e) (assoc. e a))
    ((atom (car e))
     (cond
       ((eq (car e) 'quote) (cadr e))
       ((eq (car e) 'atom) (atom (eval. (cadr e) a)))
       ((eq (car e) 'eq)
        (eq (eval. (cadr e) a)
            (eval. (caddr e) a)))
       ((eq (car e) 'car)
        (car (eval. (cadr e) a)))
       ((eq (car e) 'cdr)
        (cdr (eval. (cadr e) a)))
       ((eq (car e) 'cons)
        (cons (eval. (cadr e) a)
              (eval. (caddr e) a)))
       ((eq (car e) 'cond)
        (evcon. (cdr e) a))
       ('t
        (eval. (cons (assoc. (car e) a)
                     (cdr e))
               a))))
    ((eq (caar e) 'label)
     (eval. (cons (caddar e) (cdr e))
            (cons (list (cadar e) (car e)) a)))
    ((eq (caar e) 'lambda)
     (eval. (caddar e)
            (append. (pair. (cadar e)
                            (evlis. (cdr e) a))
                     a)))))

(defun evcon. (c a)
  (cond ((eval. (caar c) a)
         (eval. (cadar c) a))
        ('t
         (evcon. (cdr c) a))))

(defun evlis. (m a)
  (cond ((null. m) '())
        ('t
         (cons (eval. (car m) a)
               (evlis. (cdr m) a)))))
"
  "The paper's nonprimitive library, entered as object-language source.")

(defun roots-graham-library-source ()
  *roots-graham-library-source*)

(defun roots-load-graham-library (session)
  "Load NULL. through EVLIS. into SESSION."
  (roots-interpret-string
   *roots-graham-library-source*
   :session session
   :event-limit 0))

(defun roots-bootstrap-session ()
  "Return a session containing c[ad]+r abbreviations and Graham's library."
  (let ((session (make-roots-session)))
    (roots-preload-accessors session)
    (roots-load-graham-library session)
    session))
