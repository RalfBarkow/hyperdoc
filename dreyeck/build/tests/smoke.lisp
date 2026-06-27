;;;; Smoke tests for Dreyeck build/check tasks.

(in-package #:dreyeck/build/tests)

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A: expected ~S, got ~S" message expected actual)))

(defun assert-true (value message)
  (unless value
    (error "~A" message)))

(defun temporary-dreyeck-build-dmx-db-path ()
  (merge-pathnames
   (format nil "dreyeck-build-dmx-~D.sqlite" (random 1000000))
   (uiop:temporary-directory)))

(defun build-task-ids ()
  (mapcar (lambda (definition) (getf definition :id))
          (list-build-tasks)))

(defun task-result (task-result)
  (getf task-result :result))

(defun task-action-state (task-result)
  (getf task-result :action-state))

(defun action-state-for-task (status task-id)
  (find task-id (getf status :actions)
        :key (lambda (state) (getf state :task-name))
        :test #'eq))

(defun run-dreyeck-build-smoke-tests ()
  (let ((db (temporary-dreyeck-build-dmx-db-path))
        (compat-db (temporary-dreyeck-build-dmx-db-path)))
    (unwind-protect
         (progn
           (dolist (task-id '(:dmx-durable-note-materialization-status
                              :inspect-dmx-learning-topics
                              :validate-dmx-learning-topics))
             (assert-true (member task-id (build-task-ids))
                          "Build task registry must include the required task"))
           (let* ((session (make-build-session :db-path db))
                  (initial-referee
                    (build-session-next-action
                     session :task-id :validate-dmx-learning-topics))
                  (plan
                    (plan-build-task session :validate-dmx-learning-topics))
                  (planned-state (task-action-state plan))
                  (check
                    (check-build-task session :validate-dmx-learning-topics))
                  (checked-state (task-action-state check))
                  (checked-referee
                    (build-session-next-action
                     session :task-id :validate-dmx-learning-topics))
                  (checked-route
                    (build-session-next-action-route
                     session :task-id :validate-dmx-learning-topics))
                  (route-selected-task
                    (build-referee-decision-route-selected-task-of
                     checked-route))
                  (route-selected-state-before-perform
                    (action-state-for-task
                     (build-session-status session)
                     route-selected-task))
                  (perform
                    (perform-build-task
                     session route-selected-task))
                  (performed-status (build-session-status session))
                  (performed-state
                    (action-state-for-task
                     performed-status
                     route-selected-task))
                  (second-perform
                    (perform-build-task
                     session route-selected-task))
                  (final-referee
                    (build-session-next-action
                     session
                     :task-id route-selected-task))
                  (validate
                    (run-build-task :validate-dmx-learning-topics
                                    :db-path compat-db))
                  (status
                    (run-build-task
                     :dmx-durable-note-materialization-status
                     :db-path compat-db))
                  (learning-topics
                    (getf (task-result validate)
                          :learning-topics)))
             (assert-equal :dreyeck-build-session
                           (getf session :kind)
                           "A build session must be created")
             (assert-equal :plan-build-task
                           (getf initial-referee :next-action)
                           "Referee must select planning before session state exists")
             (assert-equal :planned (getf plan :status)
                           "Planning a known task must produce a plan result")
             (assert-true (not (getf planned-state
                                      :up-to-date-before-session-p))
                          "Fresh temp DB should not be up to date before the session")
             (assert-true (getf planned-state :needed-in-session-p)
                          "Plan must mark missing validation as needed")
             (assert-true (not (getf planned-state :done-in-session-p))
                          "Plan must not perform the task")
             (assert-true (not (probe-file db))
                          "Plan must not create or mutate the temp DB")
             (assert-equal :failed (getf check :status)
                           "Check must report missing validation without performing it")
             (assert-true (not (getf checked-state :done-in-session-p))
                          "Check must not mark the task done")
             (assert-true (not (probe-file db))
                          "Check/status must not create or mutate the temp DB")
             (assert-true (member (getf checked-referee :next-action)
                                  '(:perform-build-task :check-build-task))
                          "Referee must return an admissible Lisp next-action after check")
             (assert-equal :dreyeck-build-referee-next-action
                           (getf checked-referee :kind)
                           "Referee result must be inspectable Lisp data")
             (assert-equal :dreyeck-build-lisp-referee
                           (getf checked-referee :decision-owner)
                           "Next-move decision must belong to the Lisp referee")
             (assert-equal :reader-and-display-surface
                           (getf checked-referee :codex-role)
                           "Codex role must be recorded as reader/display")
             (assert-true
              (typep checked-route 'build-referee-decision-route)
              "Build session must produce a referee route object")
             (assert-equal (getf checked-referee :next-action)
                           (build-referee-decision-route-selected-action-of
                            checked-route)
                           "Route must preserve the referee selected action")
             (assert-equal :perform-build-task
                           (build-referee-decision-route-selected-action-of
                            checked-route)
                           "Checked route must select explicit performance next")
             (assert-true
              (getf
               (build-referee-decision-route-decoded-operation-of
                checked-route)
               :action-label)
              "Route must include a decoded operation label")
             (assert-true
              (build-referee-decision-route-candidate-actions-of
               checked-route)
              "Route must include candidate actions")
             (assert-true
              (build-referee-decision-route-needed-in-session-p-of
               checked-route)
              "Route must expose needed-in-session state")
             (assert-true
              (not
               (build-referee-decision-route-done-in-session-p-of
                checked-route))
              "Route must expose not-done state before perform")
             (assert-true
              (not
               (build-referee-decision-route-up-to-date-before-session-p-of
                checked-route))
              "Route must expose up-to-date-before-session state")
             (assert-true
              (build-referee-decision-route-safe-to-perform-p-of
               checked-route)
              "Route must mark the selected checked action safe to perform")
             (assert-equal 'perform-build-task
                           (build-referee-decision-route-perform-entry-point-of
                            checked-route)
                           "Route must expose the explicit perform entry point")
             (assert-true route-selected-state-before-perform
                          "Route selected task must have session state")
             (assert-true
              (not (getf route-selected-state-before-perform
                         :done-in-session-p))
              "Route creation must not mark the selected action done")
             (assert-equal :failed (getf perform :status)
                           "Performing the selected route task must record its result")
             (assert-true (getf performed-state :done-in-session-p)
                          "Explicit perform must mark the route action done in the session")
             (assert-equal :already-done (getf second-perform :status)
                           "Second same-session perform must not duplicate work")
             (assert-equal :complete (getf final-referee :next-action)
                           "Referee must report completion after the selected action is done")
             (assert-equal :passed (getf validate :status)
                           "Validation task must pass after replay")
             (assert-equal :passed (getf status :status)
                           "Status task must pass after validation")
             (assert-equal :idempotent
                           (getf (task-result validate)
                                 :last-replay-status)
                           "Compatibility validation task must report idempotent replay")
             (assert-equal :passed
                           (getf (task-result status)
                                 :status)
                           "Materialization status task must remain passed")
             (assert-equal (namestring compat-db)
                           (getf learning-topics :production-db-path)
                           "Learning-topic status must report the selected DB path")
             (dolist (topic-id '("codex-is-not-the-build-system"
                                 "reusable-common-lisp-build-tasks-for-codex"
                                 "dmx-learning-topic-inspection"
                                 "codex-dmx-learning-topics"
                                 "plan-then-perform-build-session"
                                 "build-referee-decision-route"))
               (assert-true
                (find topic-id (getf learning-topics :topics)
                      :key (lambda (topic) (getf topic :id))
                      :test #'equal)
                "Inspect task must include each required learning topic")))
           (format t "~&Dreyeck build task smoke tests passed.~%")
           t)
      (when (probe-file db)
        (delete-file db))
      (when (probe-file compat-db)
        (delete-file compat-db)))))
