;;;; Focused smoke tests for the closed-dispatch SHOP3 plan executor.

(in-package #:dreyeck/shop3/extraction-planning/tests)

(defun executor-test-result-body (result)
  (getf result :plan-result))

(defun executor-test-action-body (result)
  (getf result :action-result))

(defun executor-test-condition-type (result)
  (getf (getf result :condition) :type))

(defun executor-test-file-string (pathname)
  (with-open-file (stream pathname :direction :input)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      contents)))

(defun run-eighth-extraction-commit-3-executor-smoke-tests ()
  (let* ((live (dreyeck/shop3/executor:commit-3-execution-plan))
         (raw (getf live :raw-plan))
         (shorter (getf live :shorter-plan))
         (normalized (getf live :normalized-plan))
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
    (commit-3-smoke-assert (= 12 (length registry))
                           "The closed registry must contain 12 operator schemas.")
    (dolist (action normalized)
      (multiple-value-bind (spec failure)
          (dreyeck/shop3/executor:resolve-operator-handler executor (first action))
        (commit-3-smoke-assert spec
                               (format nil "Accepted operator ~S must resolve."
                                       (first action)))
        (commit-3-smoke-assert (null failure)
                               "Accepted operator resolution must not fail.")))
    (let* ((default-result
             (dreyeck/shop3/executor:execute-plan executor raw))
           (body (executor-test-result-body default-result))
           (events (getf body :events))
           (event-types (mapcar (lambda (event) (getf event :type)) events)))
      (commit-3-smoke-assert (eq :plan-only (getf body :mode))
                             "The executor must default to PLAN-ONLY.")
      (commit-3-smoke-assert (getf body :plan-valid-p)
                             "The accepted live plan must pass preflight.")
      (commit-3-smoke-assert (= 18 (getf body :planned-action-count))
                             "All 18 accepted actions must be planned.")
      (commit-3-smoke-assert (zerop (getf body :executed-action-count))
                             "PLAN-ONLY must execute zero actions.")
      (commit-3-smoke-assert (null (getf body :mutations-performed))
                             "PLAN-ONLY must perform no mutations.")
      (dolist (snapshot legacy-snapshots)
        (commit-3-smoke-assert
         (string= (cdr snapshot)
                  (executor-test-file-string
                   (merge-pathnames (car snapshot)
                                    #P"/Users/rgb/workspace/hyperdoc/")))
         (format nil "PLAN-ONLY must preserve ~A byte-for-byte."
                 (car snapshot))))
      (commit-3-smoke-assert
       (every (lambda (action-result)
                (and (eq :planned (getf action-result :status))
                     (null (getf action-result :observed-effects))))
              (getf body :actions))
       "PLAN-ONLY action results must not fabricate observed effects.")
      (commit-3-smoke-assert
       (equal event-types
              (append (list :plan-started)
                      (make-list 18 :initial-element :action-planned)
                      (list :plan-completed)))
       "PLAN-ONLY must produce an ordered, data-only lifecycle trace.")
      (let* ((sample (first (getf body :actions)))
             (validation (getf sample :validation)))
        (commit-3-smoke-assert (getf validation :operator-allowed)
                               "Action evidence must record operator validation.")
        (commit-3-smoke-assert (getf validation :arity-valid)
                               "Action evidence must record arity validation.")
        (commit-3-smoke-assert (getf validation :path-within-repository)
                               "Action evidence must record path validation.")))
    (multiple-value-bind (spec failure)
        (dreyeck/shop3/executor:resolve-operator-handler
         executor 'dreyeck/shop3::!not-an-accepted-operator)
      (commit-3-smoke-assert (null spec)
                             "An unknown operator must not resolve.")
      (commit-3-smoke-assert (eq :unknown-operator (getf failure :type))
                             "Unknown resolution must be a structured failure."))
    (flet ((rejection-type (action)
             (executor-test-condition-type
              (executor-test-action-body
               (dreyeck/shop3/executor:execute-plan-action executor action)))))
      (commit-3-smoke-assert
       (eq :unknown-operator
           (rejection-type
            '(dreyeck/shop3::!not-an-accepted-operator)))
       "An unknown action must be rejected structurally.")
      (commit-3-smoke-assert
       (eq :wrong-arity
           (rejection-type
            '(dreyeck/shop3::!delete-legacy-shop3-copy)))
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
              executor '(dreyeck/shop3::!run-shop3-provider-boundary-tests)
              :mode :surprise))))
       "An invalid execution mode must be rejected structurally."))
    (let* ((execute-result
             (dreyeck/shop3/executor:execute-plan
              executor
              '((dreyeck/shop3::!run-shop3-provider-boundary-tests))
              :mode :execute))
           (body (executor-test-result-body execute-result))
           (action (first (getf body :actions))))
      (commit-3-smoke-assert (not (getf body :stopped-p))
                             "The non-mutating handler must complete.")
      (commit-3-smoke-assert (= 1 (getf body :executed-action-count))
                             "One non-mutating handler must execute.")
      (commit-3-smoke-assert (null (getf body :mutations-performed))
                             "The exercised handler must remain non-mutating.")
      (commit-3-smoke-assert (getf action :observed-effects)
                             "Execute success must contain observed evidence."))
    (let* ((failing-executor
             (dreyeck/shop3/executor:make-commit-3-executor
              :handler-overrides
              (list
               (cons 'dreyeck/shop3::!run-shop3-provider-boundary-tests
                     (lambda (executor action context)
                       (declare (ignore executor action context))
                       (error "Intentional handler failure"))))))
           (result
             (dreyeck/shop3/executor:execute-plan
              failing-executor
              '((dreyeck/shop3::!run-shop3-provider-boundary-tests)
                (dreyeck/shop3::!run-repository-load-gate))
              :mode :execute))
           (body (executor-test-result-body result)))
      (commit-3-smoke-assert (getf body :stopped-p)
                             "A handler failure must stop the plan.")
      (commit-3-smoke-assert (= 1 (length (getf body :actions)))
                             "No later action may execute after failure.")
      (commit-3-smoke-assert
       (eq :handler-failure (getf (getf body :failure) :type))
       "Handler failure evidence must retain its structured type."))
    (let* ((temporary-directory
             (uiop:ensure-directory-pathname
              (merge-pathnames
               (format nil "shop3-executor-test-~D/" (get-universal-time))
               (uiop:temporary-directory))))
           (sentinel (merge-pathnames "sentinel.txt" temporary-directory)))
      (unwind-protect
           (progn
             (ensure-directories-exist sentinel)
             (with-open-file (stream sentinel :direction :output
                                    :if-exists :supersede
                                    :if-does-not-exist :create)
               (write-string "unchanged" stream))
             (let ((before (executor-test-file-string sentinel)))
               (dreyeck/shop3/executor:execute-plan
                executor raw :mode :plan-only)
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
  (format t "~&Eighth extraction commit-3 closed-dispatch executor smoke tests passed.~%")
  t)

(defun run-eighth-extraction-commit-3-planning-and-executor-smoke-tests ()
  (run-eighth-extraction-commit-3-localization-preparation-and-execution-smoke-tests)
  (run-eighth-extraction-commit-3-executor-smoke-tests))
