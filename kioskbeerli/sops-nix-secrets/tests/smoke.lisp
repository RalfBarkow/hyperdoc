;;;; Smoke tests for the Kioskbeerli sops-nix secrets planning subsystem.

(in-package :kioskbeerli/sops-nix-secrets/tests)

(defun assert-true (condition message)
  (unless condition
    (error "Sops-nix secrets smoke test failed: ~A" message))
  condition)

(defun assert-false (condition message)
  (when condition
    (error "Sops-nix secrets smoke test failed: ~A" message))
  t)

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "Sops-nix secrets smoke test failed: ~A -- expected ~S, got ~S"
           message
           expected
           actual))
  actual)

(defun assert-contains (needle haystack message)
  (assert-true (and haystack (find needle haystack :test #'equal))
               (format nil "~A -- missing ~S" message needle)))

(defun collect-plan-strings (plan)
  (let ((strings nil))
    (labels ((collect (value)
               (cond
                 ((stringp value) (push value strings))
                 ((symbolp value) (push (symbol-name value) strings))
                 ((listp value) (mapc #'collect value))
                 ((typep value 'sops-nix-secrets-plan-task)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (dependencies-of value)
                              (preconditions-of value)
                              (effects-of value)
                              (status-of value)
                              (evidence-of value)
                              (state-id-of value)
                              (scxml-event-of value)
                              (command-specs-of value))))
                 ((typep value 'sops-nix-secrets-plan)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (execution-mode-of value)
                              (tasks-of value)
                              (guards-of value)
                              (command-specs-of value))))
                 ((typep value 'sops-nix-secrets-session)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (execution-mode-of value)
                              (plan-of value)
                              (topic-bundle-of value)
                              (next-actions-of value))))
                 ((typep value 'sops-nix-secrets-command-spec)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (task-id-of value)
                              (command-text-of value)
                              (argv-of value)
                              (safety-boundary-of value))))
                 ((typep value 'sops-nix-secrets-task-topic)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (task-id-of value)
                              (state-id-of value)
                              (preconditions-of value)
                              (steps-of value)
                              (result-of value)
                              (postrequisites-of value))))
                 ((typep value 'sops-nix-secrets-topic)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (category-of value)
                              (references-of value)
                              (related-task-ids-of value))))
                 ((typep value 'sops-nix-secrets-topic-bundle)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (tasks-of value)
                              (concepts-of value)
                              (references-of value)
                              (guards-of value)
                              (failures-of value)
                              (recoveries-of value))))
                 ((typep value 'sops-nix-secrets-guard)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (status-of value)
                              (recovery-of value)
                              (blocked-state-id-of value)))))))
      (collect plan))
    strings))

(defun suspicious-secret-fragment-p (string)
  (some (lambda (fragment)
          (search fragment string :test #'char-equal))
        (list "$y$" "$6$" "$5$" "$2a$" "$2b$" "$argon2"
              (concatenate 'string "BEGIN AGE " "SECRET KEY"))))

(defun run-asdf-load-smoke-test ()
  (assert-true (asdf:find-system :kioskbeerli/sops-nix-secrets nil)
               "ASDF must know :KIOSKBEERLI/SOPS-NIX-SECRETS")
  (asdf:load-system :kioskbeerli/sops-nix-secrets)
  (assert-true (find-package :kioskbeerli/sops-nix-secrets)
               "Package :KIOSKBEERLI/SOPS-NIX-SECRETS must exist"))

(defun run-plan-shape-smoke-test ()
  (let* ((plan (make-sops-nix-secrets-plan))
         (task-ids (mapcar #'id-of (tasks-of plan))))
    (assert-true (typep plan 'sops-nix-secrets-plan)
                 "Plan constructor must return a plan object")
    (assert-equal :plan-only (execution-mode-of plan)
                  "Default execution mode must be :PLAN-ONLY")
    (assert-true (dry-run-p plan)
                 "Plan must be marked as dry-run")
    (assert-equal (sops-nix-secrets-plan-task-ids)
                  task-ids
                  "Plan must expose the expected task IDs in order")
    (dolist (task (tasks-of plan))
      (assert-true (preconditions-of task)
                   "Every task must have preconditions")
      (assert-true (effects-of task)
                   "Every task must have effects")
      (assert-true (status-of task)
                   "Every task must have a status")
      (assert-true (evidence-of task)
                   "Every task must have evidence fields"))
    (assert-equal '("check-local-sops-tools")
                  (mapcar #'id-of (sops-nix-secrets-next-actions :plan plan))
                  "Only the first post-baseline action should be available by default")))

(defun run-shop3-boundary-smoke-test ()
  (let* ((plan (make-sops-nix-secrets-plan))
         (shop3-result (sops-nix-secrets-shop3-plan-result plan))
         (steps (sops-nix-secrets-shop3-plan-steps plan))
         (checklist (hyperdoc/shop3:hyperdoc-plan-checklist shop3-result)))
    (assert-true (typep plan 'hyperdoc/shop3:hyperdoc-htn-plan-result)
                 "Plan must be a HyperDoc SHOP3 plan result")
    (assert-true (eq plan shop3-result)
                 "SHOP3 adapter should return the plan itself")
    (assert-equal (length (tasks-of plan))
                  (length steps)
                  "SHOP3 step projection must cover every local task")
    (assert-equal (length (tasks-of plan))
                  (length checklist)
                  "HyperDoc SHOP3 checklist must cover every local task")
    (assert-equal (sops-nix-secrets-plan-task-ids)
                  (mapcar (lambda (step)
                            (second step))
                          steps)
                  "SHOP3 step projection must preserve task IDs")
    (assert-equal :plan-only
                  (hyperdoc/shop3:execution-mode-of shop3-result)
                  "SHOP3 result must preserve the plan-only execution mode")))

(defun run-shop3-class-precedence-smoke-test ()
  (let* ((plan (make-sops-nix-secrets-plan))
         (class-names
           (mapcar #'class-name
                   (sb-mop:class-precedence-list
                    (class-of plan)))))
    (assert-equal 'sops-nix-secrets-plan
                  (first class-names)
                  "Plan must be the most specific class")
    (assert-equal 'hyperdoc/shop3:hyperdoc-htn-plan-result
                  (second class-names)
                  "HyperDoc SHOP3 plan result must be the direct superclass")
    (assert-true (member 'standard-object class-names)
                 "Class precedence must include STANDARD-OBJECT")
    (assert-equal 't
                  (car (last class-names))
                  "Class precedence must end at T")))

(defun run-scxml-smoke-test ()
  (let* ((path (sops-nix-secrets-scxml-pathname))
         (chart (sops-nix-secrets-scxml-chart))
         (state-ids (sops-nix-secrets-scxml-state-ids chart)))
    (assert-true (probe-file path)
                 "SCXML file must exist")
    (assert-true (typep chart 'hyperdoc/scxml:scxml-chart)
                 "SCXML file must parse")
    (dolist (state '("den-base-verified"
                     "tools-available"
                     "age-identity-ready"
                     "recipients-ready"
                     "policy-drafted"
                     "secret-encrypted"
                     "host-module-patched"
                     "files-staged"
                     "root-applied"
                     "flake-evaluated"
                     "test-activated"
                     "runtime-secret-verified"
                     "switched"
                     "complete"))
      (assert-contains state state-ids
                       "SCXML chart must include required progress state"))
    (dolist (state (sops-nix-secrets-blocked-state-ids))
      (assert-contains state state-ids
                       "SCXML chart must include required blocked state"))))

(defun run-task-state-link-smoke-test ()
  (let ((links (sops-nix-secrets-task-state-links)))
    (assert-equal (sops-nix-secrets-plan-task-ids)
                  (mapcar #'task-id-of links)
                  "Every task must have a task-to-state link")
    (dolist (link links)
      (assert-true (scxml-event-of link)
                   "Every state link must have an event")
      (assert-true (scxml-state-of link)
                   "Every state link must have a target state"))))

(defun run-topic-bundle-smoke-test ()
  (let ((bundle (sops-nix-secrets-topic-bundle)))
    (assert-true (typep bundle 'sops-nix-secrets-topic-bundle)
                 "Topic bundle must be inspectable")
    (assert-true (tasks-of bundle)
                 "Topic bundle must contain task topics")
    (assert-true (concepts-of bundle)
                 "Topic bundle must contain concept topics")
    (assert-true (references-of bundle)
                 "Topic bundle must contain reference topics")
    (assert-true (guards-of bundle)
                 "Topic bundle must contain guard topics")
    (assert-true (failures-of bundle)
                 "Topic bundle must contain failure topics")
    (assert-true (recoveries-of bundle)
                 "Topic bundle must contain recovery topics")))

(defun run-plan-only-command-smoke-test ()
  (let ((plan (make-sops-nix-secrets-plan)))
    (dolist (spec (command-specs-of plan))
      (assert-false (executed-p spec)
                    "No command spec may be executed during smoke tests")
      (assert-equal :manual-only
                    (execution-mode-of spec)
                    "Command specs must be manual-only"))
    (assert-equal :plan-only
                  (execution-mode-of plan)
                  "Plan must remain plan-only")))

(defun run-command-non-mutation-boundary-smoke-test ()
  (let ((dangerous-tokens '("ssh" "sudo" "sops" "nixos-rebuild" "dmx"))
        (specs (sops-nix-secrets-command-specs)))
    (dolist (spec specs)
      (let ((first-token (first (argv-of spec))))
        (when (and first-token
                   (find first-token dangerous-tokens :test #'string=))
          (assert-equal :manual-only
                        (execution-mode-of spec)
                        "Dangerous command specs must remain manual-only")
          (assert-false (executed-p spec)
                        "Dangerous command specs must never execute in smoke tests"))))
    (assert-false
     (some (lambda (spec)
             (let ((argv (argv-of spec)))
               (and argv
                    (member (first argv) '("ssh" "sudo" "sops" "dmx")
                            :test #'string=))))
           specs)
     "Command specs must not contain ssh, sudo, sops, or DMX command argv")))

(defun run-no-secret-fixture-smoke-test ()
  (let ((strings (collect-plan-strings (make-sops-nix-secrets-session))))
    (dolist (string strings)
      (assert-false (suspicious-secret-fragment-p string)
                    (format nil "Fixture must not contain secret-looking material: ~S"
                            string)))))

(defun run-session-smoke-test ()
  (let ((session (make-sops-nix-secrets-session)))
    (assert-true (typep session 'sops-nix-secrets-session)
                 "Session constructor must return a session object")
    (assert-equal :plan-only
                  (execution-mode-of session)
                  "Session must inherit plan-only execution mode")
    (assert-true (plan-of session)
                 "Session must expose its plan")
    (assert-true (chart-of session)
                 "Session must expose its SCXML chart")
    (assert-true (topic-bundle-of session)
                 "Session must expose its topic bundle")))

(defun run-sops-nix-secrets-smoke-tests ()
  (run-asdf-load-smoke-test)
  (run-plan-shape-smoke-test)
  (run-shop3-boundary-smoke-test)
  (run-shop3-class-precedence-smoke-test)
  (run-scxml-smoke-test)
  (run-task-state-link-smoke-test)
  (run-topic-bundle-smoke-test)
  (run-plan-only-command-smoke-test)
  (run-command-non-mutation-boundary-smoke-test)
  (run-no-secret-fixture-smoke-test)
  (run-session-smoke-test)
  (format t "~&Kioskbeerli sops-nix secrets smoke tests passed.~%")
  t)
