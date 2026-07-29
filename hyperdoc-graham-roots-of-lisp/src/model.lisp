;;;; Inspectable objects for the Roots of Lisp reconstruction.

(in-package #:hyperdoc-graham-roots-of-lisp)

(define-condition roots-language-error (error)
  ((expression
    :initarg :expression
    :reader roots-language-error-expression-of)
   (environment
    :initarg :environment
    :reader roots-language-error-environment-of)
   (reason
    :initarg :reason
    :reader roots-language-error-reason-of))
  (:report
   (lambda (condition stream)
     (format stream "Roots Lisp error while evaluating ~S: ~A"
             (roots-language-error-expression-of condition)
             (roots-language-error-reason-of condition)))))

(defclass roots-topic ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (references :initarg :references :initform nil :reader references-of)
   (page :initarg :page :initform nil :reader page-of)))

(defclass roots-trace-event ()
  ((sequence :initarg :sequence :reader sequence-of)
   (depth :initarg :depth :reader depth-of)
   (kind :initarg :kind :reader kind-of)
   (expression :initarg :expression :initform nil :reader expression-of)
   (environment :initarg :environment :initform nil :reader environment-of)
   (detail :initarg :detail :initform nil :reader detail-of)
   (result :initarg :result :initform nil :reader result-of)))

(defclass roots-evaluation ()
  ((source :initarg :source :initform nil :reader source-of)
   (expression :initarg :expression :reader expression-of)
   (environment :initarg :environment :initform nil :reader environment-of)
   (result :initarg :result :initform nil :reader result-of)
   (status :initarg :status :reader status-of)
   (events :initarg :events :initform nil :reader events-of)
   (condition :initarg :condition :initform nil :reader condition-of)
   (trace-truncated-p
    :initarg :trace-truncated-p
    :initform nil
    :reader trace-truncated-p-of)))

(defclass roots-rule-comparison ()
  ((case
    :initarg :case
    :reader roots-comparison-case-of)
   (source-locators
    :initarg :source-locators
    :reader roots-comparison-source-locators-of)
   (witness
    :initarg :witness
    :reader roots-comparison-witness-of)
   (rule-before
    :initarg :rule-before
    :reader roots-comparison-rule-before-of)
   (rule-after
    :initarg :rule-after
    :reader roots-comparison-rule-after-of)
   (mccarthy-evaluation
    :initarg :mccarthy-evaluation
    :reader roots-comparison-mccarthy-evaluation-of)
   (graham-evaluation
    :initarg :graham-evaluation
    :reader roots-comparison-graham-evaluation-of)
   (unlicensed-transition
    :initarg :unlicensed-transition
    :reader roots-comparison-unlicensed-transition-of)
   (replay-status
    :initarg :replay-status
    :reader roots-comparison-replay-status-of)))

(defclass roots-session ()
  ((environment
    :initarg :environment
    :initform nil
    :accessor session-environment-of)
   (history
    :initarg :history
    :initform nil
    :accessor history-of)))

(defclass roots-transcript ()
  ((source :initarg :source :reader source-of)
   (forms :initarg :forms :initform nil :reader forms-of)
   (results :initarg :results :initform nil :reader results-of)
   (environment :initarg :environment :initform nil :reader environment-of)
   (status :initarg :status :reader status-of)
   (condition :initarg :condition :initform nil :reader condition-of)))

(defmethod print-object ((topic roots-topic) stream)
  (print-unreadable-object (topic stream :type t)
    (format stream "~A" (title-of topic))))

(defmethod print-object ((event roots-trace-event) stream)
  (print-unreadable-object (event stream :type t)
    (format stream "~D/~D ~A ~S"
            (sequence-of event)
            (depth-of event)
            (kind-of event)
            (expression-of event))))

(defmethod print-object ((evaluation roots-evaluation) stream)
  (print-unreadable-object (evaluation stream :type t)
    (format stream "~A ~S => ~S"
            (status-of evaluation)
            (expression-of evaluation)
            (result-of evaluation))))

(defmethod print-object ((comparison roots-rule-comparison) stream)
  (print-unreadable-object (comparison stream :type t)
    (format stream "~A: ~A -> ~A (~A)"
            (roots-comparison-case-of comparison)
            (roots-comparison-rule-before-of comparison)
            (roots-comparison-rule-after-of comparison)
            (roots-comparison-replay-status-of comparison))))

(defmethod print-object ((session roots-session) stream)
  (print-unreadable-object (session stream :type t)
    (format stream "~D bindings, ~D history entries"
            (length (session-environment-of session))
            (length (history-of session)))))

(defmethod print-object ((transcript roots-transcript) stream)
  (print-unreadable-object (transcript stream :type t)
    (format stream "~A, ~D forms"
            (status-of transcript)
            (length (forms-of transcript)))))
