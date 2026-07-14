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

(defstruct (commit-3-execution-context
             (:constructor %make-commit-3-execution-context))
  executor
  repository-root
  expected-head
  expected-branch
  provenance-commit
  canonical-plan
  canonical-plan-fingerprint
  authorization-object
  authorization-pair-enforced-p
  creation-report)

(defparameter +commit-3-provenance-commit+
  "6265f68e1c6cd27c74773a7589819bad0f75f06b")

(defparameter +commit-3-provenance-subject+
  "fix(shop3): preserve HyperDoc package identity")

(defparameter +commit-3-provenance-path+
  "dreyeck/shop3/package.lisp")

(defparameter *commit-3-private-authorization-object*
  (cons :perform-eighth-dreyeck-extraction-commit-3 (gensym "AUTHORIZATION-")))

(defparameter *commit-3-validation-private-authorization-object*
  (cons :execute-commit-3-non-mutating-validation-subplan
        (gensym "VALIDATION-AUTHORIZATION-")))

(defparameter +commit-3-non-mutating-validation-subplan+
  '((dreyeck/shop3::!run-shop3-reference-boundary-fixtures)
    (dreyeck/shop3::!run-direct-shop3-load-and-gap-canary)
    (dreyeck/shop3::!run-compatibility-shop3-load-and-gap-canary)
    (dreyeck/shop3::!run-dual-load-identity-canary)
    (dreyeck/shop3::!run-shop3-provider-boundary-tests)
    (dreyeck/shop3::!run-repository-load-gate)))

(defun commit-3-non-mutating-validation-subplan ()
  "Return a fresh copy of the exact authorized validation-only subplan."
  (copy-tree +commit-3-non-mutating-validation-subplan+))

(defun %authorization-purpose (authorization-object)
  (cond
    ((eq authorization-object *commit-3-private-authorization-object*)
     :perform-eighth-dreyeck-extraction-commit-3)
    ((eq authorization-object
         *commit-3-validation-private-authorization-object*)
     :execute-commit-3-non-mutating-validation-subplan)
    (t nil)))

(defun %authorization-required-plan (authorization-object)
  (cond
    ((eq authorization-object *commit-3-private-authorization-object*)
     (getf (commit-3-execution-plan) :normalized-plan))
    ((eq authorization-object
         *commit-3-validation-private-authorization-object*)
     (commit-3-non-mutating-validation-subplan))
    (t nil)))

(defvar *commit-3-dynamic-execution-authority* nil)

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

(defparameter +shop3-gap-canary-contract-source+
  #P"/Users/rgb/workspace/hauptsache/docs/operations/kioskbeerli-salon-switching-contract.shop3.lisp")

(defun %gap-canary-evaluation-form (system marker)
  (format nil
          "(progn (asdf:load-system ~S) (load ~S) (let* ((runner (symbol-function (find-symbol \"RUN-KIOSKBEERLI-SALON-SWITCHING-CONTRACT-GAP-PLAN-OBJECT\" \"DREYECK/SHOP3\"))) (result (funcall runner)) (plans (dreyeck/shop3:plans-of result)) (expected '((dreyeck/shop3::!record-salon-secret-contract-gap \"/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env\")))) (assert (= 1 (length plans))) (assert (equal expected (first plans))) (format t \"~~&~A~~%\")))"
          system
          (namestring +shop3-gap-canary-contract-source+)
          marker))

(defun %dual-load-canary-evaluation-form ()
  "(progn (asdf:load-system :dreyeck/shop3) (let ((package (find-package :dreyeck/shop3)) (class (find-class 'dreyeck/shop3:hyperdoc-htn-plan-result)) (function (symbol-function 'dreyeck/shop3:run-hyperdoc-asdf-refactor-plan-object))) (asdf:load-system :hyperdoc/shop3) (assert (eq package (find-package :hyperdoc/shop3))) (assert (eq class (find-class 'hyperdoc/shop3:hyperdoc-htn-plan-result))) (assert (eq function (symbol-function 'hyperdoc/shop3:run-hyperdoc-asdf-refactor-plan-object))) (format t \"~&DUAL_LOAD_PACKAGE_IDENTITY_CANARY=:PASS~%\")))")

(defun %default-validation-command-resolver (name executor)
  (let* ((root (plan-executor-repository-root executor))
         (checker (merge-pathnames
                   "tools/check-shop3-reference-boundary.lisp" root))
         (allowed (merge-pathnames
                   "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff"
                   root))
         (rejected (merge-pathnames
                    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff"
                    root))
         (load-gate (merge-pathnames "tools/check-lisp-load-gate.sh" root))
         (fresh-sbcl-prefix
           '("nix" "develop" "--command" "sbcl" "--no-userinit"
             "--non-interactive" "--eval" "(require :asdf)")))
    (ecase name
      (:reference-boundary-fixtures
       (list
        :dependencies
        (list (list :kind :program :value "nix")
              (list :kind :file :value checker)
              (list :kind :file :value allowed)
              (list :kind :file :value rejected))
        :commands
        (list
         (list :argv
               (list "nix" "develop" "--command" "sbcl" "--no-userinit"
                     "--script" (namestring checker) "--diff-file"
                     (namestring allowed))
               :expected-exit-status 0
               :expected-marker "SHOP3_REFERENCE_BOUNDARY_OK")
         (list :argv
               (list "nix" "develop" "--command" "sbcl" "--no-userinit"
                     "--script" (namestring checker) "--diff-file"
                     (namestring rejected))
               :expected-exit-status 1
               :expected-marker "SHOP3_REFERENCE_BOUNDARY_REJECTED"))))
      (:direct-shop3-gap-canary
       (list
        :dependencies
        (list (list :kind :program :value "nix")
              (list :kind :file :value +shop3-gap-canary-contract-source+))
        :commands
        (list
         (list :argv
               (append fresh-sbcl-prefix
                       (list "--eval"
                             (%gap-canary-evaluation-form
                              :dreyeck/shop3
                              "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS")))
               :expected-exit-status 0
               :expected-marker
               "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS"))))
      (:compatibility-shop3-gap-canary
       (list
        :dependencies
        (list (list :kind :program :value "nix")
              (list :kind :file :value +shop3-gap-canary-contract-source+))
        :commands
        (list
         (list :argv
               (append fresh-sbcl-prefix
                       (list "--eval"
                             (%gap-canary-evaluation-form
                              :hyperdoc/shop3
                              "COMPATIBILITY_HYPERDOC_SHOP3_GAP_CANARY=:PASS")))
               :expected-exit-status 0
               :expected-marker
               "COMPATIBILITY_HYPERDOC_SHOP3_GAP_CANARY=:PASS"))))
      (:dual-load-package-identity-canary
       (list
        :dependencies (list (list :kind :program :value "nix"))
        :commands
        (list
         (list :argv
               (append fresh-sbcl-prefix
                       (list "--eval" (%dual-load-canary-evaluation-form)))
               :expected-exit-status 0
               :expected-marker "DUAL_LOAD_PACKAGE_IDENTITY_CANARY=:PASS"))))
      (:hyperbook-server-load-gate
       (list
        :dependencies
        (list (list :kind :file :value load-gate))
        :commands
        (list
         (list :argv (list (namestring load-gate) ":hyperbook/server")
               :expected-exit-status 0
               :expected-marker "LOAD_GATE_OK")))))))

(defvar *validation-command-resolver*
  #'%default-validation-command-resolver)

(defun %validation-git (repository-root &rest arguments)
  (handler-case
      (multiple-value-bind (output error-output exit-status)
          (uiop:run-program
           (cons "git" arguments)
           :directory repository-root
           :output :string
           :error-output :string
           :ignore-error-status t)
        (list :argv (cons "git" arguments)
              :stdout output
              :stderr error-output
              :exit-status exit-status))
    (error (condition)
      (list :argv (cons "git" arguments)
            :stdout ""
            :stderr (princ-to-string condition)
            :exit-status 127))))

(defun %validation-git-output (repository-root &rest arguments)
  (let ((record (apply #'%validation-git repository-root arguments)))
    (if (zerop (getf record :exit-status))
        (string-right-trim '(#\Newline #\Return) (getf record :stdout))
        (list :git-observation-failure record))))

(defun %validation-operation-state (repository-root)
  (flet ((present-p (name)
           (zerop (getf (%validation-git repository-root
                                         "rev-parse" "--verify" "-q" name)
                        :exit-status)))
         (git-path-present-p (name)
           (let ((path (%validation-git-output repository-root
                                               "rev-parse" "--git-path" name)))
             (and (stringp path)
                  (probe-file (merge-pathnames path repository-root))))))
    (list :merge-head-p (present-p "MERGE_HEAD")
          :rebase-merge-p (not (null (git-path-present-p "rebase-merge")))
          :rebase-apply-p (not (null (git-path-present-p "rebase-apply")))
          :cherry-pick-head-p (present-p "CHERRY_PICK_HEAD")
          :revert-head-p (present-p "REVERT_HEAD"))))

(defun %validation-repository-snapshot (repository-root)
  (list
   :head (%validation-git-output repository-root "rev-parse" "HEAD")
   :branch (%validation-git-output repository-root "branch" "--show-current")
   :porcelain-v2-status
   (%validation-git-output repository-root "status" "--porcelain=v2"
                           "--untracked-files=all")
   :cached-diff
   (%validation-git-output repository-root "diff" "--cached" "--no-ext-diff"
                           "--binary" "--")
   :unmerged-paths
   (%validation-git-output repository-root "diff" "--name-only"
                           "--diff-filter=U" "--")
   :merge-rebase-cherry-pick-revert-state
   (%validation-operation-state repository-root)))

(defun %dependency-observation (dependency)
  (let* ((kind (getf dependency :kind))
         (value (getf dependency :value))
         (callable
           (case kind
             (:program
              (handler-case
                  (zerop
                   (nth-value
                    2
                    (uiop:run-program
                     (list value "--version")
                     :output :string
                     :error-output :string
                     :ignore-error-status t)))
                (error () nil)))
             (:file (not (null (probe-file value))))
             (otherwise nil))))
    (list :kind kind :value value :exists-and-callable-p callable)))

(defun %run-validation-command (command repository-root)
  (let ((argv (getf command :argv))
        (expected-exit-status (getf command :expected-exit-status))
        (expected-marker (getf command :expected-marker)))
    (handler-case
        (multiple-value-bind (stdout stderr exit-status)
            (uiop:run-program argv
                              :directory repository-root
                              :output :string
                              :error-output :string
                              :ignore-error-status t)
          (let ((marker-observed-p
                  (and (stringp expected-marker)
                       (not (null (search expected-marker stdout))))))
            (list :argv argv
                  :directory repository-root
                  :stdout stdout
                  :stderr stderr
                  :exit-status exit-status
                  :expected-exit-status expected-exit-status
                  :expected-marker expected-marker
                  :marker-observed-p marker-observed-p
                  :succeeded-p
                  (and (= exit-status expected-exit-status)
                       marker-observed-p))))
      (error (condition)
        (list :argv argv
              :directory repository-root
              :stdout ""
              :stderr (princ-to-string condition)
              :exit-status 127
              :expected-exit-status expected-exit-status
              :expected-marker expected-marker
              :marker-observed-p nil
              :succeeded-p nil)))))

(defun %validation-handler-failure
    (operator dependencies commands before after command-results reason)
  (list
   :status :failed
   :observed-effects nil
   :condition
   (%failure :handler-failure
             :operator operator
             :reason reason
             :execution-authorized-p t
             :handler-invoked-p t
             :executed-action-count 0
             :mutations-performed nil
             :later-handler-invoked-p nil
             :dependencies dependencies
             :command-specifications commands
             :command-results command-results
             :repository-before before
             :repository-after after
             :repository-unchanged-p (and after (equal before after)))))

(defun %execute-non-mutating-validation (executor action resolver-name)
  (let* ((operator (first action))
         (root (plan-executor-repository-root executor))
         (before (%validation-repository-snapshot root)))
    (unless (functionp *validation-command-resolver*)
      (return-from %execute-non-mutating-validation
        (%validation-handler-failure
         operator nil nil before (%validation-repository-snapshot root) nil
         :command-resolver-uncallable)))
    (let* ((specification
             (handler-case
                 (funcall *validation-command-resolver* resolver-name executor)
               (error () nil)))
           (dependencies (and (listp specification)
                              (getf specification :dependencies)))
           (commands (and (listp specification)
                          (getf specification :commands)))
           (dependency-observations
             (and dependencies (mapcar #'%dependency-observation dependencies))))
      (unless (and commands
                   (every (lambda (entry)
                            (getf entry :exists-and-callable-p))
                          dependency-observations))
        (return-from %execute-non-mutating-validation
          (%validation-handler-failure
           operator dependency-observations commands before
           (%validation-repository-snapshot root) nil
           :runtime-dependency-unavailable)))
      (let ((command-results nil))
        (dolist (command commands)
          (push (%run-validation-command command root) command-results)
          (unless (getf (first command-results) :succeeded-p)
            (let ((after (%validation-repository-snapshot root)))
              (return-from %execute-non-mutating-validation
                (%validation-handler-failure
                 operator dependency-observations commands before after
                 (nreverse command-results) :command-validation-failed)))))
        (setf command-results (nreverse command-results))
        (let* ((after (%validation-repository-snapshot root))
               (unchanged-p (equal before after)))
          (unless unchanged-p
            (return-from %execute-non-mutating-validation
              (%validation-handler-failure
               operator dependency-observations commands before after
               command-results :repository-state-changed)))
          (list
           :status :succeeded
           :observed-effects
           (list
            (list :operator operator
                  :status :executed
                  :mutation-class :non-mutating-validation
                  :operator-arity 0
                  :argv-list-command-p t
                  :shell-command-string-p nil
                  :directory-from-executor-repository-root-p t
                  :capture-stdout-p t
                  :capture-stderr-p t
                  :capture-exit-status-p t
                  :verify-expected-marker-p t
                  :marker-observed-p t
                  :verify-repository-unchanged-p t
                  :repository-unchanged-p t
                  :mutations-performed nil
                  :dependencies dependency-observations
                  :command-results command-results
                  :repository-before before
                  :repository-after after))))))))

(defun %execute-reference-boundary-fixtures (executor action context)
  (declare (ignore context))
  (%execute-non-mutating-validation
   executor action :reference-boundary-fixtures))

(defun %execute-direct-shop3-gap-canary (executor action context)
  (declare (ignore context))
  (%execute-non-mutating-validation
   executor action :direct-shop3-gap-canary))

(defun %execute-compatibility-shop3-gap-canary (executor action context)
  (declare (ignore context))
  (%execute-non-mutating-validation
   executor action :compatibility-shop3-gap-canary))

(defun %execute-dual-load-identity-canary (executor action context)
  (declare (ignore context))
  (%execute-non-mutating-validation
   executor action :dual-load-package-identity-canary))

(defun %execute-repository-load-gate (executor action context)
  (declare (ignore context))
  (%execute-non-mutating-validation
   executor action :hyperbook-server-load-gate))

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
          :execute-handler #'%execute-reference-boundary-fixtures
          :execute-handler-name :run-reference-boundary-fixtures
          :precondition-observer :fixture-presence
          :postcondition-observer :fixture-results)
   (%spec 'dreyeck/shop3::!run-direct-shop3-load-and-gap-canary 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-direct-shop3-canary
          :execute-handler #'%execute-direct-shop3-gap-canary
          :execute-handler-name :run-direct-shop3-canary
          :precondition-observer :direct-system-loadability
          :postcondition-observer :direct-gap-plan)
   (%spec 'dreyeck/shop3::!run-compatibility-shop3-load-and-gap-canary 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-compatibility-shop3-canary
          :execute-handler #'%execute-compatibility-shop3-gap-canary
          :execute-handler-name :run-compatibility-shop3-canary
          :precondition-observer :compatibility-system-loadability
          :postcondition-observer :compatibility-gap-plan)
   (%spec 'dreyeck/shop3::!run-dual-load-identity-canary 0
          #'%validate-no-arguments :no-arguments :non-mutating-validation
          #'%render-validation :run-dual-load-identity-canary
          :execute-handler #'%execute-dual-load-identity-canary
          :execute-handler-name :run-dual-load-identity-canary
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
          :execute-handler #'%execute-repository-load-gate
          :execute-handler-name :run-repository-load-gate
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

(defun %canonical-directory (directory)
  (handler-case
      (values (uiop:ensure-directory-pathname (truename directory)) nil)
    (error (condition)
      (values nil (%failure :repository-root-unavailable
                            :repository-root directory
                            :message (princ-to-string condition))))))

(defun %full-commit-id-p (value)
  (and (stringp value)
       (= 40 (length value))
       (every (lambda (character) (digit-char-p character 16)) value)))

(defun %readable-plan-string (canonical-plan)
  (with-standard-io-syntax
    (let ((*package* (find-package :keyword))
          (*print-pretty* nil)
          (*print-readably* t))
      (write-to-string canonical-plan))))

(defun %sha-256-hex (string)
  (handler-case
      (multiple-value-bind (output error-output exit-code)
          (uiop:run-program
           '("shasum" "-a" "256")
           :input (make-string-input-stream string)
           :output :string
           :error-output :string
           :ignore-error-status t)
        (if (zerop exit-code)
            (let ((separator (position #\Space output)))
              (if (and separator (= separator 64))
                  (values (subseq output 0 separator) nil)
                  (values nil (%failure :sha-256-invalid-output
                                        :output output))))
            (values nil (%failure :sha-256-unavailable
                                  :exit-code exit-code
                                  :error-output error-output))))
    (error (condition)
      (values nil (%failure :sha-256-unavailable
                            :message (princ-to-string condition))))))

(defun %canonical-plan-fingerprint (canonical-plan)
  (%sha-256-hex (%readable-plan-string canonical-plan)))

(defun %git-command (repository-root &rest arguments)
  (handler-case
      (multiple-value-bind (output error-output exit-code)
          (uiop:run-program
           (cons "git" arguments)
           :directory repository-root
           :output :string
           :error-output :string
           :ignore-error-status t)
        (values (string-right-trim '(#\Newline #\Return) output)
                (string-right-trim '(#\Newline #\Return) error-output)
                exit-code))
    (error (condition)
      (values "" (princ-to-string condition) 127))))

(defun %nonempty-lines (string)
  (remove-if (lambda (line) (zerop (length line)))
             (uiop:split-string string :separator '(#\Newline #\Return))))

(defun %repository-observation (repository-root)
  (multiple-value-bind (inside inside-error inside-code)
      (%git-command repository-root "rev-parse" "--is-inside-work-tree")
    (declare (ignore inside-error))
    (multiple-value-bind (top-level top-level-error top-level-code)
        (%git-command repository-root "rev-parse" "--show-toplevel")
      (declare (ignore top-level-error))
      (multiple-value-bind (head head-error head-code)
          (%git-command repository-root "rev-parse" "HEAD")
        (declare (ignore head-error))
        (multiple-value-bind (branch branch-error branch-code)
            (%git-command repository-root "branch" "--show-current")
          (declare (ignore branch-error))
          (multiple-value-bind (status status-error status-code)
              (%git-command repository-root "status" "--porcelain=v2"
                            "--untracked-files=all")
            (declare (ignore status-error))
            (multiple-value-bind (conflicts conflicts-error conflicts-code)
                (%git-command repository-root "diff" "--name-only"
                              "--diff-filter=U")
              (declare (ignore conflicts-error))
              (multiple-value-bind (merge merge-error merge-code)
                  (%git-command repository-root "rev-parse" "--verify" "-q"
                                "MERGE_HEAD")
                (declare (ignore merge merge-error))
                (multiple-value-bind (rebase-merge rebase-merge-error
                                      rebase-merge-code)
                    (%git-command repository-root "rev-parse" "--git-path"
                                  "rebase-merge")
                  (declare (ignore rebase-merge-error))
                  (multiple-value-bind (rebase-apply rebase-apply-error
                                        rebase-apply-code)
                      (%git-command repository-root "rev-parse" "--git-path"
                                    "rebase-apply")
                    (declare (ignore rebase-apply-error))
                    (multiple-value-bind (cherry cherry-error cherry-code)
                        (%git-command repository-root "rev-parse" "--verify" "-q"
                                      "CHERRY_PICK_HEAD")
                      (declare (ignore cherry cherry-error))
                      (multiple-value-bind (revert revert-error revert-code)
                          (%git-command repository-root "rev-parse" "--verify" "-q"
                                        "REVERT_HEAD")
                        (declare (ignore revert revert-error))
                        (let* ((root
                                 (and (zerop top-level-code)
                                      (ignore-errors
                                        (uiop:ensure-directory-pathname
                                         (truename top-level)))))
                               (rebase-merge-path
                                 (and (zerop rebase-merge-code)
                                      (merge-pathnames rebase-merge
                                                       repository-root)))
                               (rebase-apply-path
                                 (and (zerop rebase-apply-code)
                                      (merge-pathnames rebase-apply
                                                       repository-root)))
                               (operation-clean-p
                                 (and (not (zerop merge-code))
                                      (not (zerop cherry-code))
                                      (not (zerop revert-code))
                                      (or (null rebase-merge-path)
                                          (not (probe-file rebase-merge-path)))
                                      (or (null rebase-apply-path)
                                          (not (probe-file rebase-apply-path)))
                                      (zerop conflicts-code)
                                      (zerop (length conflicts)))))
                          (list
                           :inside-work-tree-p
                           (and (zerop inside-code) (string= inside "true"))
                           :repository-root root
                           :observed-head (and (zerop head-code) head)
                           :observed-branch (and (zerop branch-code) branch)
                           :worktree-clean-p
                           (and (zerop status-code) (zerop (length status)))
                           :repository-status status
                           :conflicted-paths (%nonempty-lines conflicts)
                           :merge-in-progress-p (zerop merge-code)
                           :rebase-in-progress-p
                           (or (and rebase-merge-path
                                    (not (null (probe-file rebase-merge-path))))
                               (and rebase-apply-path
                                    (not (null (probe-file rebase-apply-path)))))
                           :cherry-pick-in-progress-p (zerop cherry-code)
                           :revert-in-progress-p (zerop revert-code)
                           :repository-operation-state-clean-p
                           operation-clean-p))))))))))))))

(defun %repository-observation-failure
    (observation expected-root expected-head expected-branch)
  (cond
    ((not (getf observation :inside-work-tree-p))
     (%failure :execution-context-not-git-repository))
    ((not (equal (getf observation :repository-root) expected-root))
     (%failure :execution-context-repository-root-mismatch
               :expected expected-root
               :observed (getf observation :repository-root)))
    ((not (string= (or (getf observation :observed-head) "") expected-head))
     (%failure :execution-context-head-mismatch
               :expected expected-head
               :observed (getf observation :observed-head)))
    ((not (string= (or (getf observation :observed-branch) "")
                   expected-branch))
     (%failure :execution-context-branch-mismatch
               :expected expected-branch
               :observed (getf observation :observed-branch)))
    ((not (getf observation :repository-operation-state-clean-p))
     (%failure :execution-context-repository-operation-in-progress
               :merge-in-progress-p
               (getf observation :merge-in-progress-p)
               :rebase-in-progress-p
               (getf observation :rebase-in-progress-p)
               :cherry-pick-in-progress-p
               (getf observation :cherry-pick-in-progress-p)
               :revert-in-progress-p
               (getf observation :revert-in-progress-p)
               :conflicted-paths (getf observation :conflicted-paths)))
    ((not (getf observation :worktree-clean-p))
     (%failure :execution-context-worktree-dirty
               :status (getf observation :repository-status)))
    (t nil)))

(defun %provenance-observation (repository-root provenance-commit)
  (multiple-value-bind (exists-output exists-error exists-code)
      (%git-command repository-root "cat-file" "-e"
                    (format nil "~A^{commit}" provenance-commit))
    (declare (ignore exists-output exists-error))
    (let ((exists-p (zerop exists-code)))
      (multiple-value-bind (reachable-output reachable-error reachable-code)
          (%git-command repository-root "merge-base" "--is-ancestor"
                        provenance-commit "HEAD")
        (declare (ignore reachable-output reachable-error))
        (multiple-value-bind (subject subject-error subject-code)
            (%git-command repository-root "log" "-1" "--pretty=%s"
                          provenance-commit)
          (declare (ignore subject-error))
          (multiple-value-bind (paths paths-error paths-code)
              (%git-command repository-root "diff-tree" "--no-commit-id"
                            "--name-only" "-r" provenance-commit)
            (declare (ignore paths-error))
            (let ((paths-list (if (zerop paths-code)
                                  (%nonempty-lines paths)
                                  nil)))
              (list
               :provenance-commit provenance-commit
               :provenance-exists-p exists-p
               :provenance-reachable-p
               (and exists-p (zerop reachable-code))
               :provenance-subject subject
               :provenance-subject-match-p
               (and (zerop subject-code)
                    (string= subject +commit-3-provenance-subject+))
               :provenance-paths paths-list
               :provenance-paths-match-p
               (equal paths-list (list +commit-3-provenance-path+))))))))))

(defun %provenance-observation-failure (observation)
  (cond
    ((not (getf observation :provenance-exists-p))
     (%failure :execution-context-provenance-missing
               :commit (getf observation :provenance-commit)))
    ((not (getf observation :provenance-reachable-p))
     (%failure :execution-context-provenance-unreachable
               :commit (getf observation :provenance-commit)))
    ((not (getf observation :provenance-subject-match-p))
     (%failure :execution-context-provenance-subject-mismatch
               :expected +commit-3-provenance-subject+
               :observed (getf observation :provenance-subject)))
    ((not (getf observation :provenance-paths-match-p))
     (%failure :execution-context-provenance-paths-mismatch
               :expected (list +commit-3-provenance-path+)
               :observed (getf observation :provenance-paths)))
    (t nil)))

(defun %context-construction-failure
    (authorization-purpose type &rest details)
  (list :status :failed
        :authorization-purpose authorization-purpose
        :failure (apply #'%failure type details)))

(defun %make-checked-execution-context
    (executor plan required-plan repository-root expected-head expected-branch
     provenance-commit authorization-object authorization-purpose)
  (unless (plan-executor-p executor)
    (return-from %make-checked-execution-context
      (values nil (%context-construction-failure
                   authorization-purpose
                   :execution-context-invalid-executor))))
  (multiple-value-bind (root root-failure)
      (%canonical-directory repository-root)
    (when root-failure
      (return-from %make-checked-execution-context
        (values nil (list :status :failed
                          :authorization-purpose authorization-purpose
                          :failure root-failure))))
    (unless (equal root (plan-executor-repository-root executor))
      (return-from %make-checked-execution-context
        (values nil (%context-construction-failure
                     authorization-purpose
                     :execution-context-repository-root-mismatch
                     :expected (plan-executor-repository-root executor)
                     :observed root))))
    (unless (and (stringp expected-branch)
                 (string= expected-branch "hauptsache"))
      (return-from %make-checked-execution-context
        (values nil (%context-construction-failure
                     authorization-purpose
                     :execution-context-branch-mismatch
                     :expected "hauptsache" :observed expected-branch))))
    (unless (%full-commit-id-p expected-head)
      (return-from %make-checked-execution-context
        (values nil (%context-construction-failure
                     authorization-purpose
                     :execution-context-invalid-expected-head
                     :expected-head expected-head))))
    (unless (and (stringp provenance-commit)
                 (string= provenance-commit +commit-3-provenance-commit+))
      (return-from %make-checked-execution-context
        (values nil (%context-construction-failure
                     authorization-purpose
                     :execution-context-provenance-commit-mismatch
                     :expected +commit-3-provenance-commit+
                     :observed provenance-commit))))
    (multiple-value-bind (canonical-plan plan-failure plan-shape)
        (normalize-shop3-plan plan)
      (declare (ignore plan-shape))
      (when plan-failure
        (return-from %make-checked-execution-context
          (values nil (list :status :failed
                            :authorization-purpose authorization-purpose
                            :failure plan-failure))))
      (multiple-value-bind (canonical-required-plan required-failure
                            required-shape)
          (normalize-shop3-plan required-plan)
        (declare (ignore required-shape))
        (when required-failure
          (return-from %make-checked-execution-context
            (values nil (list :status :failed
                              :authorization-purpose authorization-purpose
                              :failure required-failure))))
        (unless (equal canonical-plan canonical-required-plan)
          (return-from %make-checked-execution-context
            (values nil (%context-construction-failure
                         authorization-purpose
                         :execution-context-plan-mismatch
                         :expected-action-count
                         (length canonical-required-plan)
                         :observed-action-count (length canonical-plan))))))
      (multiple-value-bind (fingerprint fingerprint-failure)
          (%canonical-plan-fingerprint canonical-plan)
        (when fingerprint-failure
          (return-from %make-checked-execution-context
            (values nil (list :status :failed
                              :authorization-purpose authorization-purpose
                              :failure fingerprint-failure))))
        (let* ((repository-observation (%repository-observation root))
               (repository-failure
                 (%repository-observation-failure
                  repository-observation root expected-head expected-branch)))
          (when repository-failure
            (return-from %make-checked-execution-context
              (values nil (list :status :failed
                                :authorization-purpose authorization-purpose
                                :failure repository-failure
                                :repository-observation
                                repository-observation))))
          (let* ((provenance-observation
                   (%provenance-observation root provenance-commit))
                 (provenance-failure
                   (%provenance-observation-failure provenance-observation)))
            (when provenance-failure
              (return-from %make-checked-execution-context
                (values nil (list :status :failed
                                  :authorization-purpose authorization-purpose
                                  :failure provenance-failure
                                  :repository-observation
                                  repository-observation
                                  :provenance-observation
                                  provenance-observation))))
            (let ((creation-report
                    (list :status :created
                          :authorization-purpose authorization-purpose
                          :repository-root root
                          :expected-head expected-head
                          :expected-branch expected-branch
                          :canonical-plan-action-count
                          (length canonical-plan)
                          :canonical-plan-fingerprint fingerprint
                          :repository-observation repository-observation
                          :provenance-observation provenance-observation)))
              (values
               (%make-commit-3-execution-context
                :executor executor
                :repository-root root
                :expected-head expected-head
                :expected-branch expected-branch
                :provenance-commit provenance-commit
                :canonical-plan canonical-plan
                :canonical-plan-fingerprint fingerprint
                :authorization-object authorization-object
                :authorization-pair-enforced-p t
                :creation-report creation-report)
               nil))))))))

(defun make-commit-3-execution-context
    (executor plan repository-root expected-head expected-branch
     provenance-commit)
  "Create an opaque, repository-bound authorization context for commit 3."
  (%make-checked-execution-context
   executor plan (getf (commit-3-execution-plan) :normalized-plan)
   repository-root expected-head expected-branch provenance-commit
   *commit-3-private-authorization-object*
   :perform-eighth-dreyeck-extraction-commit-3))

(defun make-commit-3-validation-execution-context
    (executor repository-root expected-head expected-branch provenance-commit)
  "Create an opaque context for the exact non-mutating validation subplan."
  (let ((plan (commit-3-non-mutating-validation-subplan)))
    (%make-checked-execution-context
     executor plan plan repository-root expected-head expected-branch
     provenance-commit *commit-3-validation-private-authorization-object*
     :execute-commit-3-non-mutating-validation-subplan)))

(defun commit-3-execution-context-report (execution-context)
  "Return a sanitized report without exposing the private capability object."
  (if (commit-3-execution-context-p execution-context)
      (list :status :available
            :authorization-purpose
            (%authorization-purpose
             (commit-3-execution-context-authorization-object
              execution-context))
            :repository-root
            (commit-3-execution-context-repository-root execution-context)
            :expected-head
            (commit-3-execution-context-expected-head execution-context)
            :expected-branch
            (commit-3-execution-context-expected-branch execution-context)
            :provenance-commit
            (commit-3-execution-context-provenance-commit execution-context)
            :canonical-plan-action-count
            (length
             (commit-3-execution-context-canonical-plan execution-context))
            :canonical-plan-fingerprint
            (commit-3-execution-context-canonical-plan-fingerprint
             execution-context)
            :creation-report
            (copy-tree
             (commit-3-execution-context-creation-report execution-context)))
      (list :status :failed
            :authorization-purpose nil
            :failure (%failure :execution-context-wrong-type))))

(defun %make-private-test-execution-context
    (executor plan repository-root expected-head expected-branch
     provenance-commit
     &optional
       (authorization-object *commit-3-private-authorization-object*)
       (authorization-pair-enforced-p nil))
  "Construct a fixture-bound context for tests without exporting a bypass."
  (multiple-value-bind (canonical-plan failure shape)
      (normalize-shop3-plan plan)
    (declare (ignore shape))
    (when failure
      (error "Cannot construct private test context: ~S" failure))
    (multiple-value-bind (fingerprint fingerprint-failure)
        (%canonical-plan-fingerprint canonical-plan)
      (when fingerprint-failure
        (error "Cannot fingerprint private test context: ~S"
               fingerprint-failure))
      (multiple-value-bind (root root-failure)
          (%canonical-directory repository-root)
        (when root-failure
          (error "Cannot resolve private test repository: ~S" root-failure))
        (%make-commit-3-execution-context
         :executor executor
         :repository-root root
         :expected-head expected-head
         :expected-branch expected-branch
         :provenance-commit provenance-commit
         :canonical-plan canonical-plan
         :canonical-plan-fingerprint fingerprint
         :authorization-object authorization-object
         :authorization-pair-enforced-p authorization-pair-enforced-p
         :creation-report
         (list :status :private-test-context
               :authorization-purpose
               (%authorization-purpose authorization-object)
               :repository-root root
               :expected-head expected-head
               :expected-branch expected-branch
               :provenance-commit provenance-commit
               :canonical-plan-action-count (length canonical-plan)
               :canonical-plan-fingerprint fingerprint))))))

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
    (when (and (eq mode :execute)
               (null (%authorization-purpose
                      *commit-3-dynamic-execution-authority*)))
      (let* ((condition
               (%failure :execute-plan-required
                         :handler-invoked-p nil
                         :action-started-event-count 0))
             (result (%action-result position action mode :failed nil nil
                                    nil nil condition)))
        (return-from execute-plan-action
          (list :action-result result
                :handler-invoked-p nil
                :action-started-event-count 0
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

(defun %gate-steps ()
  (mapcar (lambda (entry)
            (list :step-number (first entry)
                  :name (second entry)
                  :status :not-reached
                  :failure-type nil))
          '((1 :normalize-plan)
            (2 :validate-all-actions)
            (3 :require-execute-handler-for-every-action)
            (4 :validate-context-type)
            (5 :validate-executor-identity)
            (6 :recognize-authorization-object)
            (7 :validate-canonical-plan-match)
            (8 :validate-authorization-plan-pair)
            (9 :guard-validation-mutation-scope)
            (10 :reobserve-repository-state)
            (11 :verify-provenance-integrity)
            (12 :bind-private-dynamic-execution-authority)
            (13 :invoke-first-handler))))

(defun %mark-gate-step (gate-steps step-number status &optional failure-type)
  (let ((step (find step-number gate-steps
                    :key (lambda (entry) (getf entry :step-number)))))
    (setf (getf step :status) status
          (getf step :failure-type) failure-type))
  gate-steps)

(defun %registry-readiness (executor)
  (if (plan-executor-p executor)
      (let* ((registry (plan-executor-registry executor))
             (implemented
               (count-if #'operator-specification-execute-handler registry)))
        (values (length registry) implemented (- (length registry) implemented)))
      (values 0 0 0)))

(defun %base-armed-report (executor correlation-id)
  (multiple-value-bind (registered implemented missing)
      (%registry-readiness executor)
    (list :mode :execute
          :status :pending
          :failure nil
          :failure-type nil
          :authorization-purpose nil
          :execution-authorized-p nil
          :executor-identity-match-p nil
          :repository-root nil
          :observed-head nil
          :observed-branch nil
          :worktree-clean-p nil
          :repository-operation-state-clean-p nil
          :provenance-commit nil
          :provenance-exists-p nil
          :provenance-reachable-p nil
          :provenance-subject-match-p nil
          :provenance-paths-match-p nil
          :canonical-plan-action-count 0
          :canonical-plan-fingerprint nil
          :canonical-plan-match-p nil
          :registered-operator-count registered
          :implemented-handler-count implemented
          :missing-handler-count missing
          :missing-action-indexes nil
          :missing-operators nil
          :plan-valid-p nil
          :actions nil
          :planned-action-count 0
          :executed-action-count 0
          :mutations-performed nil
          :handler-invoked-p nil
          :action-started-event-count 0
          :stopped-p t
          :events (list (%event :plan-started nil correlation-id nil))
          :gate-steps (%gate-steps))))

(defun %finish-armed-failure (report correlation-id step-number failure)
  (%mark-gate-step (getf report :gate-steps) step-number :failed
                   (getf failure :type))
  (setf (getf report :status) :failed
        (getf report :failure) failure
        (getf report :failure-type) (getf failure :type)
        (getf report :stopped-p) t
        (getf report :events)
        (nconc (getf report :events)
               (list (%event :plan-stopped nil correlation-id nil failure))))
  (list :plan-result report))

(defun %validate-all-actions (executor actions)
  (unless (plan-executor-p executor)
    (return-from %validate-all-actions
      (values nil nil (%failure :invalid-executor))))
  (let ((specifications nil)
        (validations nil))
    (loop for action in actions
          for position from 1
          do (multiple-value-bind (spec validation failure)
                 (%validate-action executor action)
               (when failure
                 (return-from %validate-all-actions
                   (values nil nil
                           (append failure (list :action-index position)))))
               (push spec specifications)
               (push validation validations)))
    (values (nreverse specifications) (nreverse validations) nil)))

(defun %missing-handler-data (actions specifications)
  (let ((indexes nil)
        (operators nil))
    (loop for action in actions
          for specification in specifications
          for position from 1
          unless (operator-specification-execute-handler specification)
            do (push position indexes)
               (pushnew (first action) operators :test #'eq))
    (values (nreverse indexes) (nreverse operators))))

(defun %authorization-plan-pair-valid-p (execution-context actions)
  (or (not (commit-3-execution-context-authorization-pair-enforced-p
            execution-context))
      (equal actions
             (%authorization-required-plan
              (commit-3-execution-context-authorization-object
               execution-context)))))

(defun %validation-scope-violation-data (actions specifications)
  (let ((indexes nil)
        (operators nil)
        (classes nil))
    (loop for action in actions
          for specification in specifications
          for position from 1
          for mutation-class =
            (operator-specification-mutation-class specification)
          unless (eq :non-mutating-validation mutation-class)
            do (push position indexes)
               (push (first action) operators)
               (push mutation-class classes))
    (values (nreverse indexes) (nreverse operators) (nreverse classes))))

(defun %result-mutating-p (executor result)
  (and (eq :succeeded (getf result :status))
       (let ((specification
               (find (first (getf result :action))
                     (plan-executor-registry executor)
                     :key #'operator-specification-operator
                     :test #'eq)))
         (not (eq :non-mutating-validation
                  (operator-specification-mutation-class specification))))))

(defun execute-plan-armed (executor plan execution-context)
  "Execute PLAN only after the complete, ordered commit-3 arming gate passes."
  (let* ((correlation-id (%next-correlation-id))
         (report (%base-armed-report executor correlation-id))
         (actions nil)
         (specifications nil))
    (multiple-value-bind (normalized normalization-failure observed-shape)
        (normalize-shop3-plan plan)
      (declare (ignore observed-shape))
      (when normalization-failure
        (return-from execute-plan-armed
          (%finish-armed-failure report correlation-id 1
                                 normalization-failure)))
      (setf actions normalized
            (getf report :canonical-plan-action-count) (length normalized))
      (multiple-value-bind (fingerprint fingerprint-failure)
          (%canonical-plan-fingerprint normalized)
        (when fingerprint-failure
          (return-from execute-plan-armed
            (%finish-armed-failure report correlation-id 1
                                   fingerprint-failure)))
        (setf (getf report :canonical-plan-fingerprint) fingerprint))
      (%mark-gate-step (getf report :gate-steps) 1 :passed))
    (when (null actions)
      (return-from execute-plan-armed
        (%finish-armed-failure report correlation-id 2
                               (%failure :empty-plan))))
    (multiple-value-bind (validated-specifications validations action-failure)
        (%validate-all-actions executor actions)
      (declare (ignore validations))
      (when action-failure
        (return-from execute-plan-armed
          (%finish-armed-failure report correlation-id 2 action-failure)))
      (setf specifications validated-specifications
            (getf report :plan-valid-p) t)
      (%mark-gate-step (getf report :gate-steps) 2 :passed))
    (multiple-value-bind (missing-indexes missing-operators)
        (%missing-handler-data actions specifications)
      (setf (getf report :missing-action-indexes) missing-indexes
            (getf report :missing-operators) missing-operators
            (getf report :missing-handler-count) (length missing-operators))
      (when missing-operators
        (return-from execute-plan-armed
          (%finish-armed-failure
           report correlation-id 3
           (%failure :execute-handler-unavailable
                     :missing-handler-count (length missing-operators)
                     :missing-action-indexes missing-indexes
                     :missing-operators missing-operators
                     :registered-operator-count
                     (getf report :registered-operator-count)
                     :implemented-handler-count
                     (getf report :implemented-handler-count)
                     :execution-authorized-p nil
                     :handler-invoked-p nil
                     :executed-action-count 0
                     :mutations-performed nil
                     :action-started-event-count 0))))
      (%mark-gate-step (getf report :gate-steps) 3 :passed))
    (unless (commit-3-execution-context-p execution-context)
      (return-from execute-plan-armed
        (%finish-armed-failure
         report correlation-id 4
         (%failure :execution-context-wrong-type))))
    (%mark-gate-step (getf report :gate-steps) 4 :passed)
    (let ((identity-match-p
            (eq executor
                (commit-3-execution-context-executor execution-context))))
      (setf (getf report :executor-identity-match-p) identity-match-p)
      (unless identity-match-p
        (return-from execute-plan-armed
          (%finish-armed-failure
           report correlation-id 5
           (%failure :execution-context-executor-mismatch))))
      (%mark-gate-step (getf report :gate-steps) 5 :passed))
    (let* ((authorization-object
             (commit-3-execution-context-authorization-object
              execution-context))
           (authorization-purpose
             (%authorization-purpose authorization-object)))
      (setf (getf report :authorization-purpose) authorization-purpose)
      (unless authorization-purpose
        (return-from execute-plan-armed
          (%finish-armed-failure
           report correlation-id 6
           (%failure :execution-context-authorization-mismatch
                     :handler-invoked-p nil
                     :action-started-event-count 0
                     :executed-action-count 0
                     :mutations-performed nil))))
      (%mark-gate-step (getf report :gate-steps) 6 :passed))
    (let ((plan-match-p
            (equal actions
                   (commit-3-execution-context-canonical-plan
                    execution-context))))
      (setf (getf report :canonical-plan-match-p) plan-match-p)
      (unless plan-match-p
        (return-from execute-plan-armed
          (%finish-armed-failure
           report correlation-id 7
           (%failure :execution-context-plan-mismatch
                     :context-fingerprint
                     (commit-3-execution-context-canonical-plan-fingerprint
                      execution-context)
                     :execution-fingerprint
                     (getf report :canonical-plan-fingerprint)))))
      (%mark-gate-step (getf report :gate-steps) 7 :passed))
    (unless (%authorization-plan-pair-valid-p execution-context actions)
      (return-from execute-plan-armed
        (%finish-armed-failure
         report correlation-id 8
         (%failure :execution-context-authorization-mismatch
                   :authorization-purpose
                   (getf report :authorization-purpose)
                   :handler-invoked-p nil
                   :action-started-event-count 0
                   :executed-action-count 0
                   :mutations-performed nil))))
    (%mark-gate-step (getf report :gate-steps) 8 :passed)
    (if (eq :execute-commit-3-non-mutating-validation-subplan
            (getf report :authorization-purpose))
        (multiple-value-bind (violating-indexes violating-operators
                              observed-classes)
            (%validation-scope-violation-data actions specifications)
          (when violating-indexes
            (return-from execute-plan-armed
              (%finish-armed-failure
               report correlation-id 9
               (%failure :execution-context-scope-violation
                         :authorization-purpose
                         :execute-commit-3-non-mutating-validation-subplan
                         :violating-action-indexes violating-indexes
                         :violating-operators violating-operators
                         :observed-mutation-classes observed-classes
                         :handler-invoked-p nil
                         :action-started-event-count 0
                         :executed-action-count 0
                         :mutations-performed nil))))
          (%mark-gate-step (getf report :gate-steps) 9 :passed))
        (%mark-gate-step (getf report :gate-steps) 9 :passed))
    (let* ((repository-root
             (commit-3-execution-context-repository-root execution-context))
           (observation (%repository-observation repository-root))
           (failure
             (%repository-observation-failure
              observation repository-root
              (commit-3-execution-context-expected-head execution-context)
              (commit-3-execution-context-expected-branch execution-context))))
      (setf (getf report :repository-root) repository-root
            (getf report :observed-head) (getf observation :observed-head)
            (getf report :observed-branch) (getf observation :observed-branch)
            (getf report :worktree-clean-p)
            (getf observation :worktree-clean-p)
            (getf report :repository-operation-state-clean-p)
            (getf observation :repository-operation-state-clean-p))
      (when failure
        (return-from execute-plan-armed
          (%finish-armed-failure report correlation-id 10 failure)))
      (%mark-gate-step (getf report :gate-steps) 10 :passed))
    (let* ((provenance-commit
             (commit-3-execution-context-provenance-commit execution-context))
           (observation
             (%provenance-observation
              (commit-3-execution-context-repository-root execution-context)
              provenance-commit))
           (failure (%provenance-observation-failure observation)))
      (setf (getf report :provenance-commit) provenance-commit
            (getf report :provenance-exists-p)
            (getf observation :provenance-exists-p)
            (getf report :provenance-reachable-p)
            (getf observation :provenance-reachable-p)
            (getf report :provenance-subject-match-p)
            (getf observation :provenance-subject-match-p)
            (getf report :provenance-paths-match-p)
            (getf observation :provenance-paths-match-p))
      (when failure
        (return-from execute-plan-armed
          (%finish-armed-failure report correlation-id 11 failure)))
      (%mark-gate-step (getf report :gate-steps) 11 :passed))
    (let ((*commit-3-dynamic-execution-authority*
            (commit-3-execution-context-authorization-object
             execution-context))
          (events (getf report :events))
          (results nil)
          (failure nil)
          (executed-count 0))
      (setf (getf report :execution-authorized-p) t)
      (%mark-gate-step (getf report :gate-steps) 12 :passed)
      (loop for action in actions
            for position from 1
            until failure
            do (let* ((response
                        (execute-plan-action
                         executor action :mode :execute :position position
                         :context execution-context
                         :correlation-id correlation-id))
                      (result (getf response :action-result)))
                 (setf events
                       (nconc events (copy-list (getf response :events))))
                 (push result results)
                 (when (eq :succeeded (getf result :status))
                   (incf executed-count))
                 (when (%result-failed-p result)
                   (setf failure (getf result :condition)))))
      (setf results (nreverse results)
            (getf report :actions) results
            (getf report :planned-action-count) (length actions)
            (getf report :executed-action-count) executed-count
            (getf report :mutations-performed)
            (some (lambda (result) (%result-mutating-p executor result)) results)
            (getf report :handler-invoked-p)
            (not (null
                  (find :action-started events
                        :key (lambda (event) (getf event :type)))))
            (getf report :action-started-event-count)
            (count :action-started events
                   :key (lambda (event) (getf event :type)))
            (getf report :events) events)
      (if failure
          (return-from execute-plan-armed
            (%finish-armed-failure report correlation-id 13 failure))
          (progn
            (%mark-gate-step (getf report :gate-steps) 13 :passed)
            (setf (getf report :status) :succeeded
                  (getf report :stopped-p) nil
                  (getf report :failure) nil
                  (getf report :failure-type) nil
                  (getf report :events)
                  (nconc (getf report :events)
                         (list (%event :plan-completed nil correlation-id nil))))
            (list :plan-result report))))))

(defun execute-plan (executor plan &key (mode :plan-only) context)
  "Render PLAN in plan-only mode. Legacy execute mode is permanently closed."
  (declare (ignorable context))
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
    (when (eq mode :execute)
      (let ((failure
              (%failure :armed-entry-point-required
                        :execution-authorized-p nil
                        :handler-invoked-p nil
                        :executed-action-count 0
                        :mutations-performed nil
                        :action-started-event-count 0)))
        (return-from execute-plan
          (list :plan-result
                (list :mode :execute
                      :status :failed
                      :failure-type :armed-entry-point-required
                      :plan-valid-p nil
                      :actions nil
                      :planned-action-count 0
                      :executed-action-count 0
                      :mutations-performed nil
                      :execution-authorized-p nil
                      :handler-invoked-p nil
                      :action-started-event-count 0
                      :stopped-p t
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
                (list :mode :plan-only :plan-valid-p nil :plan-shape shape
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
                           :context nil :correlation-id correlation-id))
                        (result (getf response :action-result)))
                   (setf events
                         (nconc events (copy-list (getf response :events))))
                   (push result planned-results)
                   (when (%result-failed-p result)
                     (setf failure (getf result :condition)))))
        (setf planned-results (nreverse planned-results))
        (if failure
            (progn
              (setf events
                    (nconc events
                           (list (%event :plan-stopped nil correlation-id nil
                                         failure))))
              (list :plan-result
                    (list :mode :plan-only :plan-valid-p nil :plan-shape shape
                          :actions planned-results
                          :planned-action-count
                          (count :planned planned-results
                                 :key (lambda (result) (getf result :status)))
                          :executed-action-count 0 :mutations-performed nil
                          :stopped-p t :failure failure :events events)))
            (progn
              (setf events
                    (nconc events
                           (list (%event :plan-completed nil correlation-id nil))))
              (list :plan-result
                    (list :mode :plan-only :plan-valid-p t :plan-shape shape
                          :actions planned-results
                          :planned-action-count (length planned-results)
                          :executed-action-count 0 :mutations-performed nil
                          :stopped-p nil :failure nil :events events))))))))
