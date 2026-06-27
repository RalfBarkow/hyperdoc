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

(defun run-dreyeck-build-smoke-tests ()
  (let ((db (temporary-dreyeck-build-dmx-db-path)))
    (unwind-protect
         (progn
           (dolist (task-id '(:dmx-durable-note-materialization-status
                              :inspect-dmx-learning-topics
                              :validate-dmx-learning-topics))
             (assert-true (member task-id (build-task-ids))
                          "Build task registry must include the required task"))
           (let* ((validate
                    (run-build-task :validate-dmx-learning-topics
                                    :db-path db))
                  (status
                    (run-build-task
                     :dmx-durable-note-materialization-status
                     :db-path db))
                  (inspect
                    (run-build-task :inspect-dmx-learning-topics
                                    :db-path db))
                  (learning-topics (task-result inspect)))
             (assert-equal :passed (getf validate :status)
                           "Validation task must pass after replay")
             (assert-equal :passed (getf status :status)
                           "Status task must pass after validation")
             (assert-equal :passed (getf inspect :status)
                           "Inspect task must pass after validation")
             (assert-equal :idempotent
                           (getf (task-result validate)
                                 :last-replay-status)
                           "Validation task must report idempotent replay")
             (assert-equal (namestring db)
                           (getf learning-topics :production-db-path)
                           "Inspect task must report the selected DB path")
             (dolist (topic-id '("codex-is-not-the-build-system"
                                 "reusable-common-lisp-build-tasks-for-codex"
                                 "dmx-learning-topic-inspection"
                                 "codex-dmx-learning-topics"))
               (assert-true
                (find topic-id (getf learning-topics :topics)
                      :key (lambda (topic) (getf topic :id))
                      :test #'equal)
                "Inspect task must include each required learning topic")))
           (format t "~&Dreyeck build task smoke tests passed.~%")
           t)
      (when (probe-file db)
        (delete-file db)))))
