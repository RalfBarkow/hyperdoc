;;;; Domain findings from the existing Riesbeck/Beane rule engine.
(in-package #:dreyeck/lisp-critic)

(export '(critic-rule critic-target critique critic-rule-run-record
          rule-name-of rule-pattern-of rule-response-of rule-source-of
          target-form-of target-runs-of rule-of target-of critiques-of
          critique-record-of critique-evidence-of critique-explanation-of
          make-critic-source-station run-critic-rule car-cdr-critique-example))

(defclass critic-rule ()
  ((name :initarg :name :reader rule-name-of)
   (pattern :initarg :pattern :reader rule-pattern-of)
   (response :initarg :response :reader rule-response-of)
   (source :initarg :source :reader rule-source-of)
   (critiques :initform nil :accessor critiques-of)))

(defclass critic-target ()
  ((form :initarg :form :reader target-form-of)
   (runs :initform nil :accessor target-runs-of)))

(defclass critic-rule-run-record (lisp-critic-run-record)
  ((rule :initform nil :accessor rule-of)
   (target :initarg :target :reader target-of)
   (critiques :initform nil :accessor critiques-of)))

(defclass critique ()
  ((rule :initarg :rule :reader rule-of)
   (target :initarg :target :reader target-of)
   (record :initarg :record :reader critique-record-of)
   (evidence :initarg :evidence :reader critique-evidence-of)
   (explanation :initarg :explanation :reader critique-explanation-of)))

(defun %configured-critic-root ()
  "The root DREYECK_LISP_CRITIC_ROOT names, or NIL when it names none.

An environment variable that is set to the empty string is not a value,
and reading it with OR made it one: \"\" is true in Lisp, so it beat the
default, ENSURE-DIRECTORY-PATHNAME turned it into the current directory,
and PROBE-FILE then reported the source station present because a
current directory always exists. The station pointed nowhere in
particular and said it was fine; the failure surfaced much later as a
missing ASDF component.

The reading layer already read this variable correctly, testing its
length before believing it. Two places read one variable two ways, which
is how a test that restored an unset variable to \"\" — the only thing
UIOP can set it to — could make an unrelated child process fail."
  (let ((configured (uiop:getenv "DREYECK_LISP_CRITIC_ROOT")))
    (and configured (plusp (length configured)) configured)))

(defun make-critic-source-station (&optional root)
  "Use an explicit source station or the historical local asset; never download it."
  (make-instance 'lisp-critic-source-station
    :id "riesbeck-beane-lisp-critic" :title "Riesbeck/Beane Lisp Critic"
    :asset-root (namestring (uiop:ensure-directory-pathname
                 (or root (%configured-critic-root)
                     (merge-pathnames ".wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/"
                                      (user-homedir-pathname)))))
    :wrapper-system "a-critic-for-lisp" :wrapper-package "A-CRITIC-FOR-LISP"
    :wrapper-loader-symbol "LOAD-LISP-CRITIC"
    :wrapper-entrypoint-symbol "CRITIQUE-IF-AVAILABLE"
    :upstream-system "lisp-critic" :upstream-package "LISP-CRITIC"
    :upstream-file-entrypoint-symbol "CRITIQUE-FILE"
    :provenance '(:source-station "a-critic-for-lisp" :engine "Riesbeck/Beane")))

(defun critic-call (name &rest arguments)
  (apply #'uiop:symbol-call :lisp-critic name arguments))

(defun run-critic-rule (contract name target)
  "Apply one real engine rule to a form, without evaluating the target program.
The execution record exists even when no finding is produced or execution fails."
  (let* ((station (lisp-critic-contract-source-station-of contract))
         (record (make-instance 'critic-rule-run-record
                   :id (symbol-name (gensym "critic-rule-run-")) :contract contract
                   :target target :target-paths nil :status :running
                   :started-at (get-universal-time) :finished-at nil
                   :raw-output "" :error-output "" :condition-summary nil
                   :invocation-form (list :function "lisp-critic:apply-critique-rule"
                                          :rule name :form (copy-tree (target-form-of target)))
                   :notes '(:structured-engine-findings :target-not-evaluated))))
    (push record (target-runs-of target))
    (handler-case
        (progn
          (%load-lisp-critic-source-station station)
          (let* ((symbol (find-symbol (string-upcase name) :lisp-critic-user))
                 (pattern (and symbol (critic-call "GET-PATTERN" symbol))))
            (unless pattern (error "Critic rule ~S is unavailable." name))
            (let* ((rule (make-instance 'critic-rule :name symbol
                           :pattern (copy-tree pattern)
                           :response (copy-tree (critic-call "GET-RESPONSE" symbol))
                           :source (list :station station :system "lisp-critic"
                                         :pathname (asdf:system-relative-pathname
                                                    "lisp-critic" "lisp-rules.lisp")
                                         :definition symbol)))
                   (findings (progn (setf (rule-of record) rule)
                                    (critic-call "APPLY-CRITIQUE-RULE" symbol
                                                 (copy-tree (target-form-of target)))))
                   (critiques
                     (mapcar (lambda (finding)
                               (make-instance 'critique :rule rule :target target :record record
                                 :evidence (copy-tree finding)
                                 :explanation
                                 (critic-call "MAKE-RESPONSE-STRING" symbol
                                              (rule-response-of rule)
                                              (critic-call "CRITIQUE-BLIST" finding))))
                             findings)))
              (setf (critiques-of record) critiques
                    (critiques-of rule) critiques
                    (slot-value record 'raw-output)
                    (with-output-to-string (stream)
                      (critic-call "PRINT-CRITIQUE-RESPONSES" findings stream))
                    (slot-value record 'status) :completed))))
      (error (condition)
        (setf (slot-value record 'status) :failed
              (slot-value record 'condition-summary) (%lisp-critic-condition-summary condition)
              (slot-value record 'error-output) (%lisp-critic-condition-summary condition)
              (critiques-of record) nil)
        (when (rule-of record) (setf (critiques-of (rule-of record)) nil))))
    (setf (slot-value record 'finished-at) (get-universal-time))
    record))

(defmethod dreyeck/evaluation-record:evaluation-input-of ((record critic-rule-run-record))
  (target-of record))

(defmethod dreyeck/evaluation-record:evaluation-result-of ((record critic-rule-run-record))
  (critiques-of record))

(defun car-cdr-critique-example (&optional root)
  "Return the target as Inspector entry point to a real CAR-CDR run and its finding."
  (let* ((station (make-critic-source-station root))
         (contract (make-instance 'lisp-critic-contract :id "one-rule-critique"
                     :title "One real Critic rule" :source-station station
                     :input-policy '(:form :not-evaluated)
                     :invocation-policy '(:apply-one-rule)
                     :output-policy '(:structured-findings :raw-output-preserved)
                     :availability-policy '(:local-source-required)
                     :failure-policy '(:record-condition) :review-contract-role :critique))
         (target (make-instance 'critic-target :form '(car (cdr items)))))
    (run-critic-rule contract "CAR-CDR" target)
    target))
