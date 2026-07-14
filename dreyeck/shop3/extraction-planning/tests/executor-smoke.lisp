;;;; Focused smoke tests for the armed SHOP3 commit-3 plan executor.

(in-package #:dreyeck/shop3/extraction-planning/tests)

(defun executor-test-result-body (result)
  (getf result :plan-result))

(defun executor-test-action-body (result)
  (getf result :action-result))

(defun executor-test-condition-type (result)
  (getf (getf result :condition) :type))

(defun executor-test-failure-type (result)
  (let ((body (executor-test-result-body result)))
    (or (getf body :failure-type)
        (getf (getf body :failure) :type))))

(defun executor-test-file-string (pathname)
  (with-open-file (stream pathname :direction :input)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      contents)))

(defun executor-test-write-string (pathname contents)
  (ensure-directories-exist pathname)
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write-string contents stream)))

(defun executor-test-git (repository-root &rest arguments)
  (multiple-value-bind (output error-output exit-code)
      (uiop:run-program
       (cons "git" arguments)
       :directory repository-root
       :output :string
       :error-output :string
       :ignore-error-status t)
    (unless (zerop exit-code)
      (error "Fixture Git command failed (~{~A~^ ~}): ~A"
             arguments error-output))
    (string-right-trim '(#\Newline #\Return) output)))

(defun make-executor-test-repository ()
  (let* ((root
           (uiop:ensure-directory-pathname
            (merge-pathnames
             (format nil "shop3-executor-test-~D-~D/"
                     (get-universal-time) (random 1000000))
             (uiop:temporary-directory))))
         (package-path (merge-pathnames "dreyeck/shop3/package.lisp" root)))
    (ensure-directories-exist package-path)
    (executor-test-git root "init" "-q")
    (executor-test-git root "config" "user.name" "HyperDoc Executor Test")
    (executor-test-git root "config" "user.email" "executor-test@example.invalid")
    (executor-test-git root "checkout" "-q" "-b" "hauptsache")
    ;; A parent makes the contract commit's exact diff-tree path observable.
    (executor-test-git root "commit" "-q" "--allow-empty" "-m"
                       "fixture bootstrap")
    (executor-test-write-string package-path
                                ";;;; Fixture DREYECK/SHOP3 package identity.\n")
    (executor-test-git root "add" "dreyeck/shop3/package.lisp")
    (executor-test-git root "commit" "-q" "-m"
                       "fix(shop3): preserve HyperDoc package identity")
    (let ((head (executor-test-git root "rev-parse" "HEAD")))
      (list :root root :head head :provenance head))))

(defmacro with-executor-test-repository ((root head provenance) &body body)
  `(let* ((fixture (make-executor-test-repository))
          (,root (getf fixture :root))
          (,head (getf fixture :head))
          (,provenance (getf fixture :provenance)))
     (unwind-protect
          (locally ,@body)
       (uiop:delete-directory-tree ,root
                                   :validate t
                                   :if-does-not-exist :ignore))))

(defun executor-test-context (executor plan root head provenance)
  (dreyeck/shop3/executor::%make-private-test-execution-context
   executor plan root head "hauptsache" provenance))

(defun executor-test-provider-plan ()
  '((dreyeck/shop3::!run-shop3-provider-boundary-tests)))

(defun executor-test-load-gate-plan ()
  '((dreyeck/shop3::!run-repository-load-gate)))

(defun executor-test-validation-plan ()
  '((dreyeck/shop3::!run-shop3-reference-boundary-fixtures)
    (dreyeck/shop3::!run-direct-shop3-load-and-gap-canary)
    (dreyeck/shop3::!run-compatibility-shop3-load-and-gap-canary)
    (dreyeck/shop3::!run-dual-load-identity-canary)
    (dreyeck/shop3::!run-shop3-provider-boundary-tests)
    (dreyeck/shop3::!run-repository-load-gate)))

(defun executor-test-validation-operators ()
  '(dreyeck/shop3::!run-shop3-reference-boundary-fixtures
    dreyeck/shop3::!run-direct-shop3-load-and-gap-canary
    dreyeck/shop3::!run-compatibility-shop3-load-and-gap-canary
    dreyeck/shop3::!run-dual-load-identity-canary
    dreyeck/shop3::!run-repository-load-gate))

(defun executor-test-unique-temporary-root (label)
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "shop3-validation-~A-~D-~D/"
            label (get-universal-time) (random 1000000))
    (uiop:temporary-directory))))

(defun executor-test-write-validation-command (temporary-root)
  (let ((script (merge-pathnames "validation-command.lisp" temporary-root)))
    (executor-test-write-string
     script
     (format nil
             "(require :asdf)~%(let ((arguments (uiop:command-line-arguments)))~%  (when (third arguments)~%    (with-open-file (stream (third arguments) :direction :output :if-exists :supersede :if-does-not-exist :create)~%      (write-line \"unexpected mutation\" stream)))~%  (format t \"~~&~~A~~%\" (first arguments))~%  (uiop:quit (parse-integer (second arguments))))~%"))
    script))

(defun executor-test-validation-command-specification
    (temporary-root marker &key missing-dependency-p command-failure-p
                                reference-fixtures-p repository-mutation-path)
  (let* ((script (executor-test-write-validation-command temporary-root))
         (allowed (merge-pathnames "allowed-added-lines.diff" temporary-root))
         (rejected (merge-pathnames "rejected-added-lines.diff" temporary-root))
         (missing (merge-pathnames "missing-runtime-dependency" temporary-root)))
    (when reference-fixtures-p
      (executor-test-write-string allowed
                                  "diff --git a/allowed b/allowed\n")
      (executor-test-write-string rejected
                                  "diff --git a/rejected b/rejected\n"))
    (list
     :dependencies
     (append
      (list (list :kind :program :value "sbcl")
            (list :kind :file
                  :value (if missing-dependency-p missing script)))
      (when reference-fixtures-p
        (list (list :kind :file :value allowed)
              (list :kind :file :value rejected))))
     :commands
     (if reference-fixtures-p
         (list
          (list :argv (list "sbcl" "--no-userinit" "--script"
                            (namestring script)
                            "SHOP3_REFERENCE_BOUNDARY_OK" "0")
                :expected-exit-status 0
                :expected-marker "SHOP3_REFERENCE_BOUNDARY_OK")
          (list :argv (list "sbcl" "--no-userinit" "--script"
                            (namestring script)
                            "SHOP3_REFERENCE_BOUNDARY_REJECTED" "1")
                :expected-exit-status 1
                :expected-marker "SHOP3_REFERENCE_BOUNDARY_REJECTED"))
         (list
          (list :argv (append
                       (list "sbcl" "--no-userinit" "--script"
                             (namestring script) marker
                             (if command-failure-p "7" "0"))
                       (when repository-mutation-path
                         (list (namestring repository-mutation-path))))
                :expected-exit-status 0
                :expected-marker marker))))))

(defun executor-test-run-repository-delta-validation-handler
    (root head provenance)
  (let* ((operator
           'dreyeck/shop3::!run-direct-shop3-load-and-gap-canary)
         (plan (list (list operator)))
         (executor
           (dreyeck/shop3/executor:make-commit-3-executor
            :repository-root root))
         (context (executor-test-context executor plan root head provenance))
         (temporary-root (executor-test-unique-temporary-root "delta"))
         (mutation-path (merge-pathnames "unexpected-validation-delta.txt" root)))
    (unwind-protect
         (let ((dreyeck/shop3/executor::*validation-command-resolver*
                 (lambda (name ignored-executor)
                   (declare (ignore ignored-executor))
                   (commit-3-smoke-assert
                    (eq :direct-shop3-gap-canary name)
                    "The delta test must select the direct canary surface.")
                   (executor-test-validation-command-specification
                    temporary-root
                    "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS"
                    :repository-mutation-path mutation-path))))
           (let* ((result
                    (dreyeck/shop3/executor:execute-plan-armed
                     executor plan context))
                  (body (executor-test-result-body result))
                  (failure (getf body :failure)))
             (commit-3-smoke-assert
              (eq :handler-failure (executor-test-failure-type result))
              "A successful command with a Git delta must fail closed.")
             (commit-3-smoke-assert
              (eq :repository-state-changed (getf failure :reason))
              "Repository deltas must retain their exact failure reason.")
             (commit-3-smoke-assert (null (getf body :mutations-performed))
                                    "A delta failure must not authorize mutation.")))
      (when (probe-file mutation-path)
        (delete-file mutation-path))
      (uiop:delete-directory-tree temporary-root
                                  :validate t :if-does-not-exist :ignore))
    (commit-3-smoke-assert
     (zerop (length (executor-test-git root "status" "--porcelain=v2"
                                       "--untracked-files=all")))
     "The synthetic repository must be clean after delta-test cleanup.")))

(defun executor-test-first-observed-validation (result)
  (first
   (getf (first (getf (executor-test-result-body result) :actions))
         :observed-effects)))

(defun executor-test-run-positive-validation-handler
    (root head provenance operator resolver-name marker reference-fixtures-p)
  (let* ((plan (list (list operator)))
         (executor
           (dreyeck/shop3/executor:make-commit-3-executor
            :repository-root root))
         (context (executor-test-context executor plan root head provenance))
         (temporary-root (executor-test-unique-temporary-root "success"))
         (repository-status-before (executor-test-git root "status"
                                                       "--porcelain=v2"
                                                       "--untracked-files=all"))
         (result nil))
    (unwind-protect
         (progn
           (ensure-directories-exist
            (merge-pathnames "fixture-root-sentinel" temporary-root))
           (let ((dreyeck/shop3/executor::*validation-command-resolver*
                 (lambda (name ignored-executor)
                   (declare (ignore ignored-executor))
                   (commit-3-smoke-assert
                    (eq resolver-name name)
                    "The handler must request its exact command surface.")
                   (executor-test-validation-command-specification
                    temporary-root marker
                    :reference-fixtures-p reference-fixtures-p))))
           (commit-3-smoke-assert
            (null (search (namestring (truename root))
                          (namestring (truename temporary-root))))
            "Temporary validation roots must be outside the repository truename.")
           (setf result
                 (dreyeck/shop3/executor:execute-plan-armed
                  executor plan context))
           (let ((body (executor-test-result-body result))
                 (observed (executor-test-first-observed-validation result)))
             (commit-3-smoke-assert (eq :succeeded (getf body :status))
                                    "A validation fixture command must succeed.")
             (commit-3-smoke-assert (eq :executed (getf observed :status))
                                    "A positive handler must report EXECUTED.")
             (commit-3-smoke-assert (getf observed :marker-observed-p)
                                    "A positive handler must observe its marker.")
             (commit-3-smoke-assert (getf observed :repository-unchanged-p)
                                    "A positive handler must preserve Git state.")
             (commit-3-smoke-assert (null (getf observed :mutations-performed))
                                    "A validation handler must report no mutation.")
             (dolist (key '(:argv-list-command-p
                            :directory-from-executor-repository-root-p
                            :capture-stdout-p
                            :capture-stderr-p
                            :capture-exit-status-p
                            :verify-expected-marker-p
                            :verify-repository-unchanged-p))
               (commit-3-smoke-assert
                (getf observed key)
                (format nil "Positive handler evidence must assert ~S." key)))
             (commit-3-smoke-assert
              (null (getf observed :shell-command-string-p))
              "Validation commands must never be shell command strings.")
             (commit-3-smoke-assert
              (string= repository-status-before
                       (executor-test-git root "status" "--porcelain=v2"
                                          "--untracked-files=all"))
              "External validation fixtures must never alter repository status."))))
      (uiop:delete-directory-tree temporary-root
                                  :validate t :if-does-not-exist :ignore))
    (commit-3-smoke-assert (null (probe-file temporary-root))
                           "Success fixtures must be cleaned with UNWIND-PROTECT.")
    result))

(defun executor-test-run-negative-validation-handler
    (root head provenance operator resolver-name marker reference-fixtures-p)
  (let* ((later-handler-invoked-p nil)
         (plan (list (list operator)
                     '(dreyeck/shop3::!run-shop3-provider-boundary-tests)))
         (executor
           (dreyeck/shop3/executor:make-commit-3-executor
            :repository-root root
            :handler-overrides
            (list
             (cons 'dreyeck/shop3::!run-shop3-provider-boundary-tests
                   (lambda (ignored-executor ignored-action ignored-context)
                     (declare (ignore ignored-executor ignored-action
                                      ignored-context))
                     (setf later-handler-invoked-p t)
                     (list :status :succeeded
                           :observed-effects '((:later-handler t))))))))
         (context (executor-test-context executor plan root head provenance))
         (temporary-root (executor-test-unique-temporary-root "failure"))
         (result nil))
    (unwind-protect
         (let ((dreyeck/shop3/executor::*validation-command-resolver*
                 (lambda (name ignored-executor)
                   (declare (ignore ignored-executor))
                   (commit-3-smoke-assert
                    (eq resolver-name name)
                    "The negative handler must request its exact command surface.")
                   (executor-test-validation-command-specification
                    temporary-root marker
                    :missing-dependency-p t
                    :reference-fixtures-p reference-fixtures-p))))
           (setf result
                 (dreyeck/shop3/executor:execute-plan-armed
                  executor plan context))
           (let ((body (executor-test-result-body result)))
             (commit-3-smoke-assert
              (eq :handler-failure (executor-test-failure-type result))
              "A missing runtime dependency must fail as HANDLER-FAILURE.")
             (commit-3-smoke-assert (getf body :execution-authorized-p)
                                    "The arming gate must authorize before dispatch.")
             (commit-3-smoke-assert (getf body :handler-invoked-p)
                                    "The failing handler must be invoked.")
             (commit-3-smoke-assert
              (zerop (getf body :executed-action-count))
              "A failed validation action must not count as executed.")
             (commit-3-smoke-assert (null (getf body :mutations-performed))
                                    "A failed handler must report no mutations.")
             (commit-3-smoke-assert (null later-handler-invoked-p)
                                    "No later handler may run after failure.")))
      (uiop:delete-directory-tree temporary-root
                                  :validate t :if-does-not-exist :ignore))
    (commit-3-smoke-assert (null (probe-file temporary-root))
                           "Failure fixtures must be cleaned with UNWIND-PROTECT.")
    result))

(defun executor-test-assert-gate-report-shape (report)
  (dolist (key '(:status
                 :failure
                 :execution-authorized-p
                 :executor-identity-match-p
                 :repository-root
                 :observed-head
                 :observed-branch
                 :worktree-clean-p
                 :repository-operation-state-clean-p
                 :provenance-commit
                 :provenance-exists-p
                 :provenance-reachable-p
                 :provenance-subject-match-p
                 :provenance-paths-match-p
                 :canonical-plan-action-count
                 :canonical-plan-fingerprint
                 :canonical-plan-match-p
                 :registered-operator-count
                 :implemented-handler-count
                 :missing-handler-count
                 :gate-steps))
    (commit-3-smoke-assert
     (loop for tail on report by #'cddr
           thereis (eq key (first tail)))
     (format nil "Armed report must contain ~S." key)))
  (dolist (step (getf report :gate-steps))
    (dolist (key '(:step-number :name :status :failure-type))
      (commit-3-smoke-assert
       (loop for tail on step by #'cddr
             thereis (eq key (first tail)))
       (format nil "Gate step must contain ~S." key)))))

(defun run-eighth-extraction-commit-3-executor-smoke-tests ()
  (let* ((live (dreyeck/shop3/executor:commit-3-execution-plan))
         (raw (getf live :raw-plan))
         (shorter (getf live :shorter-plan))
         (normalized (getf live :normalized-plan))
         (provider-handler-identity-before
           (symbol-function
            'dreyeck/shop3/executor::%execute-provider-boundary-tests))
         (hyperdoc-repository-snapshot-before
           (dreyeck/shop3/executor::%validation-repository-snapshot
            #P"/Users/rgb/workspace/hyperdoc/"))
         (executor (dreyeck/shop3/executor:make-commit-3-executor))
         (registry (dreyeck/shop3/executor:operator-registry executor))
         (legacy-paths
           '("hyperdoc-shop3/package.lisp"
             "hyperdoc-shop3/manual-topics.lisp"
             "hyperdoc-shop3/plan-objects.lisp"
             "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
             "hyperdoc-shop3/examples.lisp"
             "hyperdoc-shop3/views.lisp"))
         (legacy-snapshots
           (mapcar
            (lambda (path)
              (cons path
                    (executor-test-file-string
                     (merge-pathnames path #P"/Users/rgb/workspace/hyperdoc/"))))
            legacy-paths)))
    (commit-3-smoke-assert (= 36 (length raw))
                           "The observed raw SHOP3 plan must have 36 cells.")
    (commit-3-smoke-assert (= 18 (length shorter))
                           "SHOP3:SHORTER-PLAN must contain 18 actions.")
    (commit-3-smoke-assert (equal shorter normalized)
                           "Raw-plan normalization must preserve action order.")
    (multiple-value-bind (normalized-again failure shape)
        (dreyeck/shop3/executor:normalize-shop3-plan normalized)
      (declare (ignore shape))
      (commit-3-smoke-assert (null failure)
                             "Normalized plans must normalize again.")
      (commit-3-smoke-assert (equal normalized normalized-again)
                             "Normalization must be idempotent.")
      (commit-3-smoke-assert (not (eq normalized normalized-again))
                             "Normalization must return a fresh list.")
      (commit-3-smoke-assert (integerp (list-length normalized-again))
                             "Normalization must return a proper list."))
    (multiple-value-bind (from-raw raw-failure raw-shape)
        (dreyeck/shop3/executor:normalize-shop3-plan raw)
      (declare (ignore raw-shape))
      (multiple-value-bind (from-shorter shorter-failure shorter-shape)
          (dreyeck/shop3/executor:normalize-shop3-plan shorter)
        (declare (ignore shorter-shape))
        (commit-3-smoke-assert (and (null raw-failure)
                                    (null shorter-failure)
                                    (equal from-raw from-shorter))
                               "Raw and shorter plans must canonicalize equally.")))
    (commit-3-smoke-assert (= 12 (length registry))
                           "The closed registry must contain 12 operator schemas.")
    (commit-3-smoke-assert
     (= 6 (count-if (lambda (entry) (getf entry :execute-handler)) registry))
     "The registry must expose exactly six implemented execute handlers.")
    (commit-3-smoke-assert
     (= 6 (count-if-not (lambda (entry) (getf entry :execute-handler)) registry))
     "The registry must retain exactly six blocked handlers.")
    (dolist (operator
             '(dreyeck/shop3::!delete-legacy-shop3-copy
               dreyeck/shop3::!write-shop3-reference-boundary-checker
               dreyeck/shop3::!write-shop3-reference-boundary-fixture
               dreyeck/shop3::!wire-shop3-reference-boundary-checker
               dreyeck/shop3::!write-commit-3-execution-evidence
               dreyeck/shop3::!record-commit-3-execution-complete))
      (let ((entry (find operator registry :key (lambda (item)
                                                  (getf item :operator)))))
        (commit-3-smoke-assert entry
                               "Each blocked operator must remain registered.")
        (commit-3-smoke-assert (null (getf entry :execute-handler))
                               "Blocked operators must retain no handler.")))
    (dolist (action normalized)
      (multiple-value-bind (spec failure)
          (dreyeck/shop3/executor:resolve-operator-handler executor (first action))
        (commit-3-smoke-assert spec
                               (format nil "Accepted operator ~S must resolve."
                                       (first action)))
        (commit-3-smoke-assert (null failure)
                               "Accepted operator resolution must not fail.")))
    (let* ((default-result
             (dreyeck/shop3/executor:execute-plan
              executor raw :context :ignored-in-plan-only))
           (body (executor-test-result-body default-result))
           (events (getf body :events))
           (event-types (mapcar (lambda (event) (getf event :type)) events)))
      (commit-3-smoke-assert (eq :plan-only (getf body :mode))
                             "The executor must default to PLAN-ONLY.")
      (commit-3-smoke-assert (getf body :plan-valid-p)
                             "The accepted live plan must pass plan-only preflight.")
      (commit-3-smoke-assert (= 18 (getf body :planned-action-count))
                             "All 18 accepted actions must be planned.")
      (commit-3-smoke-assert (zerop (getf body :executed-action-count))
                             "PLAN-ONLY must execute zero actions.")
      (commit-3-smoke-assert (null (getf body :mutations-performed))
                             "PLAN-ONLY must perform no mutations.")
      (commit-3-smoke-assert
       (every (lambda (action-result)
                (and (eq :planned (getf action-result :status))
                     (null (getf action-result :observed-effects))))
              (getf body :actions))
       "PLAN-ONLY results must not fabricate observed effects.")
      (commit-3-smoke-assert
       (equal event-types
              (append (list :plan-started)
                      (make-list 18 :initial-element :action-planned)
                      (list :plan-completed)))
       "PLAN-ONLY must preserve the ordered lifecycle trace."))
    (dolist (snapshot legacy-snapshots)
      (commit-3-smoke-assert
       (string= (cdr snapshot)
                (executor-test-file-string
                 (merge-pathnames (car snapshot)
                                  #P"/Users/rgb/workspace/hyperdoc/")))
       (format nil "PLAN-ONLY must preserve ~A byte-for-byte." (car snapshot))))
    (multiple-value-bind (spec failure)
        (dreyeck/shop3/executor:resolve-operator-handler
         executor 'dreyeck/shop3::!not-an-accepted-operator)
      (commit-3-smoke-assert (null spec)
                             "An unknown operator must not resolve.")
      (commit-3-smoke-assert (eq :unknown-operator (getf failure :type))
                             "Unknown resolution must be structured."))
    (flet ((rejection-type (action)
             (executor-test-condition-type
              (executor-test-action-body
               (dreyeck/shop3/executor:execute-plan-action executor action)))))
      (commit-3-smoke-assert
       (eq :unknown-operator
           (rejection-type '(dreyeck/shop3::!not-an-accepted-operator)))
       "An unknown action must be rejected structurally.")
      (commit-3-smoke-assert
       (eq :wrong-arity
           (rejection-type '(dreyeck/shop3::!delete-legacy-shop3-copy)))
       "Wrong arity must be rejected structurally.")
      (commit-3-smoke-assert
       (eq :wrong-argument-type
           (rejection-type
            '(dreyeck/shop3::!delete-legacy-shop3-copy 42)))
       "Wrong argument type must be rejected structurally.")
      (commit-3-smoke-assert
       (eq :path-outside-repository
           (rejection-type
            '(dreyeck/shop3::!delete-legacy-shop3-copy "../outside.lisp")))
       "A path escaping the repository must be rejected structurally.")
      (commit-3-smoke-assert
       (eq :invalid-execution-mode
           (executor-test-condition-type
            (executor-test-action-body
             (dreyeck/shop3/executor:execute-plan-action
              executor (first (executor-test-provider-plan))
              :mode :surprise))))
       "An invalid action execution mode must be rejected structurally."))
    (let* ((result
             (dreyeck/shop3/executor:execute-plan
              executor (executor-test-provider-plan) :mode :execute
              :context :cannot-arm-legacy-entry))
           (body (executor-test-result-body result)))
      (commit-3-smoke-assert
       (eq :armed-entry-point-required (executor-test-failure-type result))
       "Legacy execute mode must require the armed entry point.")
      (commit-3-smoke-assert (null (getf body :execution-authorized-p))
                             "Legacy execute mode must never authorize.")
      (commit-3-smoke-assert (null (getf body :handler-invoked-p))
                             "Legacy execute mode must invoke no handler.")
      (commit-3-smoke-assert (zerop (getf body :action-started-event-count))
                             "Legacy execute mode must start no action."))
    (commit-3-smoke-assert
     (handler-case
         (progn
           (apply (symbol-function
                   'dreyeck/shop3/executor:execute-plan-armed)
                  (list executor (executor-test-provider-plan)))
           nil)
       (program-error () t))
     "Calling the armed entry point without context must signal PROGRAM-ERROR.")
    (let* ((result
             (dreyeck/shop3/executor:execute-plan-armed
              executor normalized nil))
           (body (executor-test-result-body result)))
      (executor-test-assert-gate-report-shape body)
      (commit-3-smoke-assert
       (eq :execute-handler-unavailable (executor-test-failure-type result))
       "The current eighteen-action plan must stop at handler preflight.")
      (commit-3-smoke-assert (= 6 (getf body :missing-handler-count))
                             "The current plan must expose six missing handlers.")
      (commit-3-smoke-assert
       (equal '(1 2 3 4 5 6 7 8 9 10 17 18)
              (getf body :missing-action-indexes))
       "Full preflight must report every occurrence of missing handlers.")
      (commit-3-smoke-assert (= 12 (getf body :registered-operator-count))
                             "The armed report must expose twelve registrations.")
      (commit-3-smoke-assert (= 6 (getf body :implemented-handler-count))
                             "The armed report must expose six implementations.")
      (commit-3-smoke-assert (null (getf body :handler-invoked-p))
                             "Handler preflight failure must invoke no handler.")
      (commit-3-smoke-assert (zerop (getf body :executed-action-count))
                             "Handler preflight failure must execute no action.")
      (commit-3-smoke-assert (null (getf body :mutations-performed))
                             "Handler preflight failure must perform no mutation."))
    (let* ((missing-first-plan
             '((dreyeck/shop3::!delete-legacy-shop3-copy
                "hyperdoc-shop3/package.lisp")))
           (result
             (dreyeck/shop3/executor:execute-plan-armed
              executor missing-first-plan nil))
           (body (executor-test-result-body result)))
      (commit-3-smoke-assert
       (eq :execute-handler-unavailable (executor-test-failure-type result))
       "A missing first handler must fail in full-plan preflight.")
      (commit-3-smoke-assert (null (getf body :handler-invoked-p))
                             "A missing first handler must not be invoked."))
    (let* ((result
             (dreyeck/shop3/executor:execute-plan-armed
              executor (executor-test-validation-plan) nil))
           (body (executor-test-result-body result)))
      (commit-3-smoke-assert (getf body :plan-valid-p)
                             "The six-action validation subplan must be valid.")
      (commit-3-smoke-assert
       (= 6 (getf body :canonical-plan-action-count))
       "The validation subplan must contain six actions.")
      (commit-3-smoke-assert
       (zerop (getf body :missing-handler-count))
       "The validation subplan must have complete handler coverage.")
      (commit-3-smoke-assert
       (eq :execution-context-wrong-type (executor-test-failure-type result))
       "Coverage preflight must stop before authoritative execution."))
    (dolist (resolver-name
             '(:direct-shop3-gap-canary
               :compatibility-shop3-gap-canary
               :dual-load-package-identity-canary
               :hyperbook-server-load-gate))
      (let* ((specification
               (dreyeck/shop3/executor::%default-validation-command-resolver
                resolver-name executor))
             (observations
               (mapcar #'dreyeck/shop3/executor::%dependency-observation
                       (getf specification :dependencies))))
        (commit-3-smoke-assert
         (every (lambda (entry) (getf entry :exists-and-callable-p))
                observations)
         (format nil "The ~S invocation dependencies must be present."
                 resolver-name))))
    (let* ((response
             (dreyeck/shop3/executor:execute-plan-action
              executor (first (executor-test-provider-plan)) :mode :execute))
           (body (executor-test-action-body response)))
      (commit-3-smoke-assert
       (eq :execute-plan-required (executor-test-condition-type body))
       "Direct execute-mode action calls must require execute-plan-armed.")
      (commit-3-smoke-assert (null (getf response :handler-invoked-p))
                             "Direct execute calls must invoke no handler.")
      (commit-3-smoke-assert
       (zerop (getf response :action-started-event-count))
       "Direct execute calls must emit no action-started event."))
    (multiple-value-bind (context failure)
        (dreyeck/shop3/executor:make-commit-3-execution-context
         executor (executor-test-provider-plan)
         #P"/Users/rgb/workspace/hyperdoc/"
         "6265f68e1c6cd27c74773a7589819bad0f75f06b"
         "hauptsache"
         "6265f68e1c6cd27c74773a7589819bad0f75f06b")
      (commit-3-smoke-assert (null context)
                             "A non-current public constructor plan must fail.")
      (commit-3-smoke-assert
       (eq :execution-context-plan-mismatch
           (getf (getf failure :failure) :type))
       "Public context construction must enforce the canonical commit-3 plan."))
    (with-executor-test-repository (root head provenance)
      (let* ((fixture-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root))
             (provider-plan (executor-test-provider-plan))
             (context
               (executor-test-context fixture-executor provider-plan
                                      root head provenance)))
        (let ((wrong-type-result
                (dreyeck/shop3/executor:execute-plan-armed
                 fixture-executor provider-plan :not-a-context)))
          (commit-3-smoke-assert
           (eq :execution-context-wrong-type
               (executor-test-failure-type wrong-type-result))
           "Wrong context types must fail after handler preflight."))
        (let* ((other-executor
                 (dreyeck/shop3/executor:make-commit-3-executor
                  :repository-root root))
               (other-result
                 (dreyeck/shop3/executor:execute-plan-armed
                  other-executor provider-plan context)))
          (commit-3-smoke-assert
           (eq :execution-context-executor-mismatch
               (executor-test-failure-type other-result))
           "Contexts must be bound to executor identity."))
        (let* ((load-handler-called-p nil)
               (two-handler-executor
                 (dreyeck/shop3/executor:make-commit-3-executor
                  :repository-root root
                  :handler-overrides
                  (list
                   (cons 'dreyeck/shop3::!run-repository-load-gate
                         (lambda (executor action context)
                           (declare (ignore executor action context))
                           (setf load-handler-called-p t)
                           (list :status :succeeded
                                 :observed-effects '((:load-gate-test t))))))))
               (two-handler-context
                 (executor-test-context
                  two-handler-executor provider-plan root head provenance))
               (different-result
                 (dreyeck/shop3/executor:execute-plan-armed
                  two-handler-executor (executor-test-load-gate-plan)
                  two-handler-context)))
          (commit-3-smoke-assert
           (eq :execution-context-plan-mismatch
               (executor-test-failure-type different-result))
           "Execution must equal the context's canonical plan.")
          (commit-3-smoke-assert (null load-handler-called-p)
                                 "Plan mismatch must precede handler dispatch."))
        (let* ((success
                 (dreyeck/shop3/executor:execute-plan-armed
                  fixture-executor provider-plan context))
               (body (executor-test-result-body success))
               (public-report
                 (dreyeck/shop3/executor:commit-3-execution-context-report
                  context)))
          (commit-3-smoke-assert (eq :succeeded (getf body :status))
                                 "A fully armed provider handler must execute.")
          (commit-3-smoke-assert (= 1 (getf body :executed-action-count))
                                 "The provider test handler must execute once.")
          (commit-3-smoke-assert (null (getf body :mutations-performed))
                                 "The provider handler must remain non-mutating.")
          (commit-3-smoke-assert
           (eq :perform-eighth-dreyeck-extraction-commit-3
               (getf public-report :authorization-purpose))
           "The public report may expose only the authorization purpose.")
          (commit-3-smoke-assert
           (not (member
                 dreyeck/shop3/executor::*commit-3-private-authorization-object*
                 public-report :test #'eq))
           "The public report must not expose the authorization object."))))
    (with-executor-test-repository (root head provenance)
      (let ((cases
              '((dreyeck/shop3::!run-shop3-reference-boundary-fixtures
                 :reference-boundary-fixtures
                 "SHOP3_REFERENCE_BOUNDARY_OK" t)
                (dreyeck/shop3::!run-direct-shop3-load-and-gap-canary
                 :direct-shop3-gap-canary
                 "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS" nil)
                (dreyeck/shop3::!run-compatibility-shop3-load-and-gap-canary
                 :compatibility-shop3-gap-canary
                 "COMPATIBILITY_HYPERDOC_SHOP3_GAP_CANARY=:PASS" nil)
                (dreyeck/shop3::!run-dual-load-identity-canary
                 :dual-load-package-identity-canary
                 "DUAL_LOAD_PACKAGE_IDENTITY_CANARY=:PASS" nil)
                (dreyeck/shop3::!run-repository-load-gate
                 :hyperbook-server-load-gate "LOAD_GATE_OK" nil))))
        (dolist (case cases)
          (destructuring-bind
              (operator resolver-name marker reference-fixtures-p) case
            (executor-test-run-positive-validation-handler
             root head provenance operator resolver-name marker
             reference-fixtures-p)
            (executor-test-run-negative-validation-handler
             root head provenance operator resolver-name marker
             reference-fixtures-p)))
        (executor-test-run-repository-delta-validation-handler
         root head provenance)
        (let* ((plan
                 '((dreyeck/shop3::!run-shop3-reference-boundary-fixtures)))
               (default-executor
                 (dreyeck/shop3/executor:make-commit-3-executor
                  :repository-root root))
               (default-context
                 (executor-test-context default-executor plan
                                        root head provenance))
               (default-result
                 (dreyeck/shop3/executor:execute-plan-armed
                  default-executor plan default-context)))
          (commit-3-smoke-assert
           (eq :handler-failure (executor-test-failure-type default-result))
           "The production reference handler must fail closed when its authoritative files are absent."))))
    (commit-3-smoke-assert
     (eq provider-handler-identity-before
         (symbol-function
          'dreyeck/shop3/executor::%execute-provider-boundary-tests))
     "The existing provider-boundary handler identity must remain EQ.")
    (commit-3-smoke-assert
     (equal hyperdoc-repository-snapshot-before
            (dreyeck/shop3/executor::%validation-repository-snapshot
             #P"/Users/rgb/workspace/hyperdoc/"))
     "Temporary fixture tests must preserve the exact HyperDoc Git snapshot.")
    (with-executor-test-repository (root head provenance)
      (let* ((fixture-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root))
             (plan (executor-test-provider-plan))
             (context
               (executor-test-context fixture-executor plan root head provenance)))
        (executor-test-write-string (merge-pathnames "dirty.txt" root) "dirty\n")
        (let ((result
                (dreyeck/shop3/executor:execute-plan-armed
                 fixture-executor plan context)))
          (commit-3-smoke-assert
           (eq :execution-context-worktree-dirty
               (executor-test-failure-type result))
           "Untracked fixture files must fail closed."))))
    (with-executor-test-repository (root head provenance)
      (let* ((fixture-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root))
             (plan (executor-test-provider-plan))
             (context
               (executor-test-context fixture-executor plan root head provenance)))
        (executor-test-write-string (merge-pathnames ".git/MERGE_HEAD" root)
                                    (format nil "~A~%" provenance))
        (let ((result
                (dreyeck/shop3/executor:execute-plan-armed
                 fixture-executor plan context)))
          (commit-3-smoke-assert
           (eq :execution-context-repository-operation-in-progress
               (executor-test-failure-type result))
           "MERGE_HEAD must fail closed as an operation in progress."))))
    (with-executor-test-repository (root head provenance)
      (let* ((fixture-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root))
             (plan (executor-test-provider-plan))
             (context
               (executor-test-context fixture-executor plan root head provenance)))
        (executor-test-write-string
         (merge-pathnames ".git/rebase-merge/head-name" root)
         "refs/heads/hauptsache\n")
        (let ((result
                (dreyeck/shop3/executor:execute-plan-armed
                 fixture-executor plan context)))
          (commit-3-smoke-assert
           (eq :execution-context-repository-operation-in-progress
               (executor-test-failure-type result))
           "A rebase-merge directory must fail closed."))))
    (with-executor-test-repository (root head provenance)
      (let* ((fixture-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root))
             (plan (executor-test-provider-plan))
             (context
               (executor-test-context fixture-executor plan root head provenance)))
        (executor-test-write-string (merge-pathnames "moved.txt" root) "moved\n")
        (executor-test-git root "add" "moved.txt")
        (executor-test-git root "commit" "-q" "-m" "move fixture head")
        (let ((result
                (dreyeck/shop3/executor:execute-plan-armed
                 fixture-executor plan context)))
          (commit-3-smoke-assert
           (eq :execution-context-head-mismatch
               (executor-test-failure-type result))
           "A moved HEAD must fail closed."))))
    (with-executor-test-repository (root head provenance)
      (commit-3-smoke-assert
       (not (string= provenance
                     "0000000000000000000000000000000000000000"))
       "The fixture provenance must differ from the missing commit probe.")
      (let* ((fixture-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root))
             (plan (executor-test-provider-plan))
             (context
               (executor-test-context fixture-executor plan root head
                                      "0000000000000000000000000000000000000000"))
             (result
               (dreyeck/shop3/executor:execute-plan-armed
                fixture-executor plan context)))
        (commit-3-smoke-assert
         (eq :execution-context-provenance-missing
             (executor-test-failure-type result))
         "A missing provenance commit must fail closed.")))
    (with-executor-test-repository (root head provenance)
      (let* ((fixture-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root))
             (plan (executor-test-provider-plan)))
        (executor-test-git root "checkout" "-q" "-b" "other")
        (executor-test-write-string (merge-pathnames "other.txt" root) "other\n")
        (executor-test-git root "add" "other.txt")
        (executor-test-git root "commit" "-q" "-m" "unreachable fixture commit")
        (let ((unreachable (executor-test-git root "rev-parse" "HEAD")))
          (commit-3-smoke-assert
           (not (string= provenance unreachable))
           "The unreachable fixture commit must differ from provenance.")
          (executor-test-git root "checkout" "-q" "hauptsache")
          (let* ((context
                   (executor-test-context fixture-executor plan root head
                                          unreachable))
                 (result
                   (dreyeck/shop3/executor:execute-plan-armed
                    fixture-executor plan context)))
            (commit-3-smoke-assert
             (eq :execution-context-provenance-unreachable
                 (executor-test-failure-type result))
             "A provenance commit outside HEAD ancestry must fail closed.")))))
    (with-executor-test-repository (root head provenance)
      (let* ((later-handler-invoked-p nil)
             (failing-executor
               (dreyeck/shop3/executor:make-commit-3-executor
                :repository-root root
                :handler-overrides
                (list
                 (cons 'dreyeck/shop3::!run-shop3-provider-boundary-tests
                       (lambda (executor action context)
                         (declare (ignore executor action context))
                         (error "Intentional handler failure")))
                 (cons 'dreyeck/shop3::!run-repository-load-gate
                       (lambda (executor action context)
                         (declare (ignore executor action context))
                         (setf later-handler-invoked-p t)
                         (list :status :succeeded
                               :observed-effects '((:later-handler t))))))))
             (plan
               '((dreyeck/shop3::!run-shop3-provider-boundary-tests)
                 (dreyeck/shop3::!run-repository-load-gate)))
             (context
               (executor-test-context failing-executor plan root head provenance))
             (result
               (dreyeck/shop3/executor:execute-plan-armed
                failing-executor plan context))
             (body (executor-test-result-body result)))
        (commit-3-smoke-assert
         (eq :handler-failure (executor-test-failure-type result))
         "Intentional provider failure must remain structured.")
        (commit-3-smoke-assert (= 1 (length (getf body :actions)))
                               "Handler failure must stop before later actions.")
        (commit-3-smoke-assert (null later-handler-invoked-p)
                               "A later handler must not run after failure.")))
    (let* ((temporary-directory
             (uiop:ensure-directory-pathname
              (merge-pathnames
               (format nil "shop3-executor-sentinel-~D/" (get-universal-time))
               (uiop:temporary-directory))))
           (sentinel (merge-pathnames "sentinel.txt" temporary-directory)))
      (unwind-protect
           (progn
             (executor-test-write-string sentinel "unchanged")
             (let ((before (executor-test-file-string sentinel)))
               (dreyeck/shop3/executor:execute-plan executor raw :mode :plan-only)
               (commit-3-smoke-assert
                (string= before (executor-test-file-string sentinel))
                "PLAN-ONLY must not mutate a filesystem sentinel.")))
        (uiop:delete-directory-tree temporary-directory
                                    :validate t :if-does-not-exist :ignore)))
    (let* ((system (asdf:find-system :dreyeck/shop3/extraction-planning))
           (dependencies (asdf:system-depends-on system)))
      (commit-3-smoke-assert
       (not (member "hyperdoc/scxml" dependencies :test #'string-equal))
       "The executor system must not require SCXML.")))
  (format t "~&Eighth extraction commit-3 armed executor smoke tests passed.~%")
  t)

(defun run-eighth-extraction-commit-3-planning-and-executor-smoke-tests ()
  (run-eighth-extraction-commit-3-localization-preparation-and-execution-smoke-tests)
  (run-eighth-extraction-commit-3-executor-smoke-tests))
