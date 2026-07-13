;;;; Plan-only-first, closed-dispatch execution of accepted SHOP3 actions.

(in-package #:dreyeck/shop3/executor)

(defparameter +commit-3-repository-root+
  #P"/Users/rgb/workspace/hyperdoc/")

(defparameter +legacy-shop3-copy-paths+
  '("hyperdoc-shop3/package.lisp"
    "hyperdoc-shop3/manual-topics.lisp"
    "hyperdoc-shop3/plan-objects.lisp"
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    "hyperdoc-shop3/examples.lisp"
    "hyperdoc-shop3/views.lisp"))

(defstruct (operator-specification
             (:constructor %make-operator-specification))
  operator
  arity
  argument-contract
  argument-contract-name
  mutation-class
  plan-only-renderer
  renderer-name
  execute-handler
  execute-handler-name
  precondition-observer
  postcondition-observer
  result-event-type)

(defstruct (plan-executor (:constructor %make-plan-executor))
  repository-root
  registry)

(defvar *execution-correlation-counter* 0)

(defun %next-correlation-id ()
  (format nil "SHOP3-EXECUTION-~D"
          (incf *execution-correlation-counter*)))

(defun %failure (type &rest details)
  (list* :type type details))

(defun %proper-list-length (object)
  (handler-case
      (let ((length (list-length object)))
        (if (or length (null object))
            (values length nil)
            (values nil (%failure :circular-list :value object))))
    (type-error ()
      (values nil (%failure :improper-action :value object)))))

(defun %relative-repository-path (executor value)
  (unless (stringp value)
    (return-from %relative-repository-path
      (values nil (%failure :wrong-argument-type
                            :expected :repository-relative-path
                            :value value))))
  (let* ((pathname (pathname value))
         (directory (pathname-directory pathname)))
    (when (or (uiop:absolute-pathname-p pathname)
              (member :up directory)
              (member :back directory)
              (wild-pathname-p pathname)
              (position (code-char 0) value))
      (return-from %relative-repository-path
        (values nil (%failure :path-outside-repository :value value))))
    (let* ((root (plan-executor-repository-root executor))
           (absolute (merge-pathnames pathname root))
           (root-string (uiop:unix-namestring root))
           (absolute-string (uiop:unix-namestring absolute)))
      (unless (and (<= (length root-string) (length absolute-string))
                   (string= root-string absolute-string
                            :end2 (length root-string)))
        (return-from %relative-repository-path
          (values nil (%failure :path-outside-repository :value value))))
      (values value nil))))

(defun %validate-no-arguments (executor arguments)
  (declare (ignore executor))
  (if (null arguments)
      (values (list :argument-types-valid t
                    :path-within-repository :not-applicable)
              nil)
      (values nil (%failure :wrong-arity :expected 0
                            :actual (length arguments)))))

(defun %validate-exact-path (executor arguments accepted-paths)
  (multiple-value-bind (path path-failure)
      (%relative-repository-path executor (first arguments))
    (cond
      (path-failure
       (values nil path-failure))
      ((not (member path accepted-paths :test #'string=))
       (values nil (%failure :unaccepted-repository-path
                             :value path
                             :accepted accepted-paths)))
      (t
       (values (list :argument-types-valid t
                     :path-within-repository t
                     :canonical-relative-path path)
               nil)))))

(defun %validate-legacy-copy (executor arguments)
  (%validate-exact-path executor arguments +legacy-shop3-copy-paths+))

(defun %validate-checker-path (executor arguments)
  (%validate-exact-path
   executor arguments '("tools/check-shop3-reference-boundary.lisp")))

(defun %validate-gate-path (executor arguments)
  (%validate-exact-path executor arguments '("tools/pre-commit-gate.sh")))

(defun %validate-evidence-path (executor arguments)
  (%validate-exact-path
   executor arguments
   '("hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp")))

(defun %validate-fixture (executor arguments)
  (let ((kind (first arguments))
        (path (second arguments)))
    (unless (member kind '(:allowed :rejected) :test #'eq)
      (return-from %validate-fixture
        (values nil (%failure :wrong-argument-type
                              :position 1
                              :expected '(:member :allowed :rejected)
                              :value kind))))
    (multiple-value-bind (validated-path path-failure)
        (%relative-repository-path executor path)
      (declare (ignore validated-path))
      (when path-failure
        (return-from %validate-fixture (values nil path-failure)))
      (let ((expected
              (ecase kind
                (:allowed
                 "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
                (:rejected
                 "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff"))))
        (if (string= path expected)
            (values (list :argument-types-valid t
                          :path-within-repository t
                          :fixture-kind kind
                          :canonical-relative-path path)
                    nil)
            (values nil (%failure :unaccepted-repository-path
                                  :value path
                                  :accepted (list expected))))))))

(defun %render-delete (executor arguments context)
  (declare (ignore executor context))
  (list :intended-preconditions
        (list (list :file-present (first arguments)))
        :intended-effects
        (list (list :file-absent (first arguments)))
        :intended-call
        (list :repository-file-delete (first arguments))))

(defun %render-write-checker (executor arguments context)
  (declare (ignore executor context))
  (list :intended-preconditions '((:accepted-checker-contract-available t))
        :intended-effects (list (list :file-written (first arguments)))
        :intended-call (list :write-reference-boundary-checker
                             (first arguments))))

(defun %render-write-fixture (executor arguments context)
  (declare (ignore executor context))
  (list :intended-preconditions
        (list (list :accepted-fixture-contract (first arguments)))
        :intended-effects (list (list :file-written (second arguments)))
        :intended-call (list :write-reference-boundary-fixture
                             (first arguments) (second arguments))))

(defun %render-wire-gate (executor arguments context)
  (declare (ignore executor context))
  (list :intended-preconditions
        '((:reference-boundary-checker-present t))
        :intended-effects (list (list :gate-wired (first arguments)))
        :intended-call (list :wire-reference-boundary-checker
                             (first arguments))))

(defun %render-validation (executor arguments context)
  (declare (ignore executor arguments))
  (list :intended-preconditions '((:repository-worktree-available t))
        :intended-effects (list (list :validation-passed
                                      (getf context :operator)))
        :intended-call (list :run-validation (getf context :operator))))

(defun %render-write-evidence (executor arguments context)
  (declare (ignore executor context))
  (list :intended-preconditions '((:all-required-validations-passed t))
        :intended-effects (list (list :evidence-written (first arguments)))
        :intended-call (list :write-structured-evidence (first arguments))))

(defun %render-record-complete (executor arguments context)
  (declare (ignore executor arguments context))
  (list :intended-preconditions '((:execution-evidence-written t))
        :intended-effects '((:commit-3-execution-recorded-complete t))
        :intended-call '(:record-execution-complete)))

(defun %execute-provider-boundary-tests (executor action context)
  (declare (ignore executor action context))
  (unless (find-package :hyperdoc/tests)
    (asdf:load-system :hyperdoc/shop3-provider-boundary/tests))
  (let ((observed
          (uiop:symbol-call :hyperdoc/tests
                            :run-shop3-provider-boundary-smoke-tests)))
    (if observed
        (list :status :succeeded
              :observed-effects
              '((:shop3-provider-boundary-tests-passed t)))
        (list :status :failed
              :observed-effects
              '((:shop3-provider-boundary-tests-passed nil))
              :condition (%failure :postcondition-not-observed
                                   :expected t
                                   :observed observed)))))

(defun %spec (operator arity argument-contract argument-contract-name
              mutation-class renderer
              renderer-name &key execute-handler execute-handler-name
                                precondition-observer postcondition-observer
                                (result-event-type :action-result))
  (%make-operator-specification
   :operator operator
   :arity arity
   :argument-contract argument-contract
   :argument-contract-name argument-contract-name
   :mutation-class mutation-class
   :plan-only-renderer renderer
   :renderer-name renderer-name
   :execute-handler execute-handler
   :execute-handler-name execute-handler-name
   :precondition-observer precondition-observer
   :postcondition-observer postcondition-observer
   :result-event-type result-event-type))

(defun %commit-3-registry ()
  (list
   (%spec 'dreyeck/shop3::!delete-legacy-shop3-copy 1
          #'%validate-legacy-copy :legacy-copy-repository-path
          :repository-delete
          #'%render-delete :delete-legacy-shop3-copy
          :precondition-observer :file-presence
          :postcondition-observer :file-absence)
   (%spec 'dreyeck/shop3::!write-shop3-reference-boundary-checker 1
          #'%validate-checker-path :accepted-checker-repository-path
          :repository-write
          #'%render-write-checker :write-reference-boundary-checker
          :precondition-observer :checker-contract
          :postcondition-observer :file-content)
   (%spec 'dreyeck/shop3::!write-shop3-reference-boundary-fixture 2
          #'%validate-fixture :fixture-kind-and-accepted-repository-path
          :repository-write
          #'%render-write-fixture :write-reference-boundary-fixture
          :precondition-observer :fixture-contract
          :postcondition-observer :file-content)
   (%spec 'dreyeck/shop3::!wire-shop3-reference-boundary-checker 1
          #'%validate-gate-path :pre-commit-gate-repository-path
          :repository-modification
          #'%render-wire-gate :wire-reference-boundary-checker
          :precondition-observer :gate-content
          :postcondition-observer :gate-content)
   (%spec 'dreyeck/shop3::!run-shop3-reference-boundary-fixtures 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-reference-boundary-fixtures
          :precondition-observer :fixture-presence
          :postcondition-observer :fixture-results)
   (%spec 'dreyeck/shop3::!run-direct-shop3-load-and-gap-canary 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-direct-shop3-canary
          :precondition-observer :direct-system-loadability
          :postcondition-observer :direct-gap-plan)
   (%spec 'dreyeck/shop3::!run-compatibility-shop3-load-and-gap-canary 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-compatibility-shop3-canary
          :precondition-observer :compatibility-system-loadability
          :postcondition-observer :compatibility-gap-plan)
   (%spec 'dreyeck/shop3::!run-dual-load-identity-canary 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-dual-load-identity-canary
          :precondition-observer :dual-system-loadability
          :postcondition-observer :runtime-identities)
   (%spec 'dreyeck/shop3::!run-shop3-provider-boundary-tests 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-provider-boundary-tests
          :execute-handler #'%execute-provider-boundary-tests
          :execute-handler-name :run-provider-boundary-tests
          :precondition-observer :provider-boundary-test-system
          :postcondition-observer :provider-boundary-test-result)
   (%spec 'dreyeck/shop3::!run-repository-load-gate 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-repository-load-gate
          :precondition-observer :repository-load-command
          :postcondition-observer :load-gate-marker)
   (%spec 'dreyeck/shop3::!write-commit-3-execution-evidence 1
          #'%validate-evidence-path :accepted-evidence-repository-path
          :repository-write
          #'%render-write-evidence :write-commit-3-execution-evidence
          :precondition-observer :validation-results
          :postcondition-observer :safe-single-form)
   (%spec 'dreyeck/shop3::!record-commit-3-execution-complete 0
          #'%validate-no-arguments :no-arguments :execution-record
          #'%render-record-complete :record-commit-3-execution-complete
          :precondition-observer :execution-evidence
          :postcondition-observer :next-task)))

(defun %replace-handler (registry operator handler)
  (let ((spec (find operator registry
                    :key #'operator-specification-operator :test #'eq)))
    (unless spec
      (error "Cannot override unregistered operator ~S." operator))
    (unless (eq :non-mutating-validation
                (operator-specification-mutation-class spec))
      (error "Execute-handler overrides are limited to non-mutating validations."))
    (unless (functionp handler)
      (error "The execute-handler override for ~S is not a function." operator))
    (setf (operator-specification-execute-handler spec) handler
          (operator-specification-execute-handler-name spec) :trusted-override))
  registry)

(defun make-commit-3-executor
    (&key (repository-root +commit-3-repository-root+) handler-overrides)
  "Construct the accepted commit-3 executor. HANDLER-OVERRIDES are trusted
construction-time adapters, never values obtained from plan data."
  (let* ((root (uiop:ensure-directory-pathname (truename repository-root)))
         (registry (%commit-3-registry)))
    (dolist (override handler-overrides)
      (%replace-handler registry (car override) (cdr override)))
    (%make-plan-executor :repository-root root :registry registry)))

(defun resolve-operator-handler (executor operator-name)
  "Resolve OPERATOR-NAME only when it is in EXECUTOR's closed registry."
  (let ((spec (and (symbolp operator-name)
                   (find operator-name (plan-executor-registry executor)
                         :key #'operator-specification-operator :test #'eq))))
    (if spec
        (values spec nil)
        (values nil (%failure :unknown-operator :operator operator-name)))))

(defun operator-registry (executor)
  "Return the closed registry as inspectable data without function objects."
  (mapcar
   (lambda (spec)
     (list :operator (operator-specification-operator spec)
           :arity (operator-specification-arity spec)
           :argument-validators
           (operator-specification-argument-contract-name spec)
           :mutation-class (operator-specification-mutation-class spec)
           :plan-only-renderer (operator-specification-renderer-name spec)
           :execute-handler (operator-specification-execute-handler-name spec)
           :precondition-observer
           (operator-specification-precondition-observer spec)
           :postcondition-observer
           (operator-specification-postcondition-observer spec)
           :result-event-type
           (operator-specification-result-event-type spec)))
   (plan-executor-registry executor)))

(defun %action-form-p (value)
  (and (consp value) (symbolp (first value))))

(defun normalize-shop3-plan (plan)
  "Normalize either SHOP3's raw action/cost list or SHORTER-PLAN action list.
Returns the normalized plan, a structured failure, and the observed input shape."
  (multiple-value-bind (length failure) (%proper-list-length plan)
    (when failure
      (return-from normalize-shop3-plan (values nil failure nil)))
    (cond
      ((every #'%action-form-p plan)
       (values (copy-tree plan) nil
               (list :representation :shorter-plan :input-length length
                     :normalized-action-count length)))
      ((and (evenp length)
            (loop for (action cost) on plan by #'cddr
                  always (and (%action-form-p action) (numberp cost))))
       (let ((actions (loop for tail on plan by #'cddr
                            collect (copy-tree (first tail)))))
         (values actions nil
                 (list :representation :raw-action-cost-alternation
                       :input-length length
                       :normalized-action-count (length actions)))))
      (t
       (values nil (%failure :unsupported-plan-representation :value plan)
               (list :representation :unknown :input-length length))))))

(defun commit-3-execution-plan ()
  "Run the accepted live SHOP3 problem and expose its related plan projections."
  (let* ((planner-result
           (dreyeck/shop3::run-eighth-dreyeck-extraction-commit-3-execution-plan))
         (raw-plan (first (getf planner-result :raw-plans)))
         (shorter-plan (first (getf planner-result :shorter-plans))))
    (multiple-value-bind (normalized failure shape)
        (normalize-shop3-plan raw-plan)
      (when failure
        (error "The accepted live SHOP3 plan could not be normalized: ~S"
               failure))
      (list :planner-result planner-result
            :raw-plan raw-plan
            :shorter-plan shorter-plan
            :normalized-plan normalized
            :plan-shape shape
            :plan-trees (getf planner-result :plan-trees)
            :final-states (getf planner-result :final-states)))))

(defun %action-result (position action mode status handler validation
                       intended observed condition)
  (list :position position
        :action action
        :mode mode
        :status status
        :handler handler
        :validation validation
        :intended-preconditions (getf intended :intended-preconditions)
        :intended-effects (getf intended :intended-effects)
        :intended-call (getf intended :intended-call)
        :observed-effects observed
        :condition condition))

(defun %event (type position correlation-id action &optional result)
  (list :type type
        :position position
        :correlation-id correlation-id
        :action action
        :result result))

(defun %validate-action (executor action)
  (multiple-value-bind (action-length list-failure) (%proper-list-length action)
    (when list-failure
      (return-from %validate-action (values nil nil list-failure)))
    (when (zerop action-length)
      (return-from %validate-action
        (values nil nil (%failure :empty-action))))
    (let ((operator (first action))
          (arguments (rest action)))
      (multiple-value-bind (spec resolution-failure)
          (resolve-operator-handler executor operator)
        (when resolution-failure
          (return-from %validate-action
            (values nil nil resolution-failure)))
        (unless (= (length arguments) (operator-specification-arity spec))
          (return-from %validate-action
            (values spec nil
                    (%failure :wrong-arity
                              :operator operator
                              :expected (operator-specification-arity spec)
                              :actual (length arguments)))))
        (multiple-value-bind (argument-validation argument-failure)
            (funcall (operator-specification-argument-contract spec)
                     executor arguments)
          (if argument-failure
              (values spec nil argument-failure)
              (values spec
                      (append (list :operator-allowed t
                                    :arity-valid t)
                              argument-validation)
                      nil)))))))

(defun execute-plan-action
    (executor action &key (mode :plan-only) (position 0) context correlation-id)
  "Validate, render, and optionally execute one accepted primitive action."
  (let ((correlation-id (or correlation-id (%next-correlation-id))))
    (unless (member mode '(:plan-only :execute) :test #'eq)
      (let* ((condition (%failure :invalid-execution-mode :mode mode))
             (result (%action-result position action mode :rejected nil nil
                                    nil nil condition)))
        (return-from execute-plan-action
          (list :action-result result
                :events (list (%event :action-failed position correlation-id
                                      action result))))))
    (multiple-value-bind (spec validation failure)
        (%validate-action executor action)
      (when failure
        (let ((result (%action-result
                       position action mode :rejected
                       (and spec (operator-specification-renderer-name spec))
                       validation nil nil failure)))
          (return-from execute-plan-action
            (list :action-result result
                  :events (list (%event :action-failed position correlation-id
                                        action result))))))
      (let* ((renderer (operator-specification-plan-only-renderer spec))
             (render-context (list* :operator (first action) context))
             (intended (funcall renderer executor (rest action) render-context))
             (handler-name (operator-specification-renderer-name spec)))
        (if (eq mode :plan-only)
            (let ((result (%action-result position action mode :planned
                                          handler-name validation intended
                                          nil nil)))
              (list :action-result result
                    :events (list (%event :action-planned position correlation-id
                                          action result))))
            (let ((handler (operator-specification-execute-handler spec)))
              (unless handler
                (let* ((condition
                         (%failure :execute-handler-unavailable
                                   :operator (first action)))
                       (result
                         (%action-result position action mode :failed
                                         handler-name validation intended
                                         nil condition)))
                  (return-from execute-plan-action
                    (list :action-result result
                          :events
                          (list (%event :action-started position correlation-id
                                        action)
                                (%event :action-failed position correlation-id
                                        action result))))))
              (handler-case
                  (let* ((handler-result (funcall handler executor action context))
                         (observed (getf handler-result :observed-effects))
                         (declared-status (getf handler-result :status))
                         (condition (getf handler-result :condition))
                         (succeeded (and (eq declared-status :succeeded)
                                         observed
                                         (null condition)))
                         (status (if succeeded :succeeded :failed))
                         (effective-condition
                           (or condition
                               (unless succeeded
                                 (%failure :unobserved-or-failed-handler-result
                                           :handler-result handler-result))))
                         (result (%action-result position action mode status
                                                handler-name validation intended
                                                observed effective-condition)))
                    (list :action-result result
                          :events
                          (list (%event :action-started position correlation-id
                                        action)
                                (%event (if succeeded
                                            :action-succeeded
                                            :action-failed)
                                        position correlation-id action result))))
                (error (condition)
                  (let* ((structured
                           (%failure :handler-failure
                                     :operator (first action)
                                     :message (princ-to-string condition)))
                         (result
                           (%action-result position action mode :failed
                                           handler-name validation intended
                                           nil structured)))
                    (list :action-result result
                          :events
                          (list (%event :action-started position correlation-id
                                        action)
                                (%event :action-failed position correlation-id
                                        action result))))))))))))

(defun %result-failed-p (result)
  (member (getf result :status) '(:failed :rejected) :test #'eq))

(defun execute-plan (executor plan &key (mode :plan-only) context)
  "Execute PLAN through normalization, preflight, closed dispatch, and handlers.
PLAN-ONLY is the default and never invokes execute handlers. EXECUTE always
preflights every action before invoking the first handler."
  (let ((correlation-id (%next-correlation-id)))
    (unless (member mode '(:plan-only :execute) :test #'eq)
      (let ((failure (%failure :invalid-execution-mode :mode mode)))
        (return-from execute-plan
          (list :plan-result
                (list :mode mode :plan-valid-p nil :actions nil
                      :planned-action-count 0 :executed-action-count 0
                      :mutations-performed nil :stopped-p t
                      :failure failure
                      :events
                      (list (%event :plan-started nil correlation-id nil)
                            (%event :plan-stopped nil correlation-id nil
                                    failure)))))))
    (multiple-value-bind (actions normalization-failure shape)
        (normalize-shop3-plan plan)
      (when normalization-failure
        (return-from execute-plan
          (list :plan-result
                (list :mode mode :plan-valid-p nil :plan-shape shape
                      :actions nil :planned-action-count 0
                      :executed-action-count 0 :mutations-performed nil
                      :stopped-p t :failure normalization-failure
                      :events
                      (list (%event :plan-started nil correlation-id nil)
                            (%event :plan-stopped nil correlation-id nil
                                    normalization-failure))))))
      (let ((events (list (%event :plan-started nil correlation-id nil)))
            (planned-results nil)
            (failure nil))
        (loop for action in actions
              for position from 1
              until failure
              do (let* ((response
                          (execute-plan-action
                           executor action :mode :plan-only :position position
                           :context context :correlation-id correlation-id))
                        (result (getf response :action-result)))
                   (setf events (nconc events (copy-list (getf response :events))))
                   (push result planned-results)
                   (when (%result-failed-p result)
                     (setf failure (getf result :condition)))))
        (setf planned-results (nreverse planned-results))
        (when failure
          (setf events
                (nconc events
                       (list (%event :plan-stopped nil correlation-id nil
                                     failure))))
          (return-from execute-plan
            (list :plan-result
                  (list :mode mode :plan-valid-p nil :plan-shape shape
                        :actions planned-results
                        :planned-action-count
                        (count :planned planned-results
                               :key (lambda (result) (getf result :status)))
                        :executed-action-count 0 :mutations-performed nil
                        :stopped-p t :failure failure :events events))))
        (when (eq mode :plan-only)
          (setf events
                (nconc events
                       (list (%event :plan-completed nil correlation-id nil))))
          (return-from execute-plan
            (list :plan-result
                  (list :mode :plan-only :plan-valid-p t :plan-shape shape
                        :actions planned-results
                        :planned-action-count (length planned-results)
                        :executed-action-count 0 :mutations-performed nil
                        :stopped-p nil :failure nil :events events))))
        (let ((executed-results nil)
              (executed-count 0))
          (loop for action in actions
                for position from 1
                until failure
                do (let* ((response
                            (execute-plan-action
                             executor action :mode :execute :position position
                             :context context :correlation-id correlation-id))
                          (result (getf response :action-result)))
                     (setf events
                           (nconc events (copy-list (getf response :events))))
                     (push result executed-results)
                     (when (eq :succeeded (getf result :status))
                       (incf executed-count))
                     (when (%result-failed-p result)
                       (setf failure (getf result :condition)))))
          (setf executed-results (nreverse executed-results))
          (setf events
                (nconc events
                       (list (%event (if failure :plan-stopped :plan-completed)
                                     nil correlation-id nil failure))))
          (list :plan-result
                (list :mode :execute :plan-valid-p t :plan-shape shape
                      :actions executed-results
                      :planned-action-count (length planned-results)
                      :executed-action-count executed-count
                      :mutations-performed
                      (some (lambda (result)
                              (and (eq :succeeded (getf result :status))
                                   (let ((spec
                                           (find (first (getf result :action))
                                                 (plan-executor-registry executor)
                                                 :key #'operator-specification-operator
                                                 :test #'eq)))
                                     (not (eq :non-mutating-validation
                                              (operator-specification-mutation-class
                                               spec))))))
                            executed-results)
                      :stopped-p (not (null failure))
                      :failure failure :events events)))))))
