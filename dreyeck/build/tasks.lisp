;;;; Deterministic Dreyeck build/check tasks for Codex and inspectors.

(in-package #:dreyeck/build)

(defparameter *dreyeck-build-task-definitions*
  '((:id :dmx-durable-note-materialization-status
     :title "DMX durable-note materialization status"
     :summary "Read structured materialization status from the DMX SQLite production store."
     :mutates-p nil)
    (:id :inspect-dmx-learning-topics
     :title "Inspect DMX learning topics"
     :summary "Read the materialized learning-topic subset and its required associations."
     :mutates-p nil)
    (:id :validate-dmx-learning-topics
     :title "Validate DMX learning topics"
     :summary "Replay durable-note materialization and verify learning topics plus idempotence."
     :mutates-p t)))

(defun list-build-tasks ()
  "Return the stable Dreyeck build/check tasks available to Codex."
  (copy-tree *dreyeck-build-task-definitions*))

(defun build-task-known-p (task-id)
  (find task-id *dreyeck-build-task-definitions*
        :key (lambda (definition) (getf definition :id))
        :test #'eq))

(defun build-task-result-status (result)
  (or (getf result :status)
      (getf result :last-validation-status)
      (let ((status (getf result :materialization-status)))
        (getf status :last-validation-status))
      :unknown))

(defun materialization-run-unchanged-p (run)
  (and (every (lambda (result)
                (eq (getf result :state) :unchanged))
              (getf run :topic-results))
       (every (lambda (result)
                (eq (getf result :state) :unchanged))
              (getf run :association-results))))

(defun run-dmx-durable-note-materialization-status-task (db-path)
  (let ((status (durable-note-materialization-status :db-path db-path)))
    (list :status (getf status :last-validation-status)
          :materialization-status status
          :production-db-path (getf status :production-db-path))))

(defun run-inspect-dmx-learning-topics-task (db-path)
  (dmx-materialized-learning-topics :db-path db-path))

(defun run-validate-dmx-learning-topics-task (db-path)
  (let* ((first-run
           (materialize-durable-notes-into-production-db :db-path db-path))
         (second-run
           (materialize-durable-notes-into-production-db :db-path db-path))
         (status (durable-note-materialization-status :db-path db-path))
         (learning-topics (dmx-materialized-learning-topics :db-path db-path))
         (second-run-unchanged-p (materialization-run-unchanged-p second-run))
         (passed? (and (eq :passed (getf status :last-validation-status))
                       (eq :passed (getf learning-topics :status))
                       second-run-unchanged-p)))
    (list :status (if passed? :passed :failed)
          :production-db-path (getf status :production-db-path)
          :materialization-status status
          :learning-topics learning-topics
          :first-replay-result first-run
          :second-replay-result second-run
          :last-replay-status (if second-run-unchanged-p
                                  :idempotent
                                  :changed)
          :second-replay-unchanged-p second-run-unchanged-p)))

(defun run-build-task* (task-id db-path)
  (ecase task-id
    (:dmx-durable-note-materialization-status
     (run-dmx-durable-note-materialization-status-task db-path))
    (:inspect-dmx-learning-topics
     (run-inspect-dmx-learning-topics-task db-path))
    (:validate-dmx-learning-topics
     (run-validate-dmx-learning-topics-task db-path))))

(defun run-build-task
    (task-id &key (db-path *dreyeck-dmx-production-db-path*))
  "Run TASK-ID and return a structured result.

Tasks are Common Lisp functions, not shell commands. This boundary lets Codex
and inspector views call stable project operations without becoming the build
system themselves."
  (let ((started-at (get-universal-time)))
    (if (not (build-task-known-p task-id))
        (list :kind :dreyeck-build-task-result
              :task task-id
              :status :unknown-task
              :started-at started-at
              :finished-at (get-universal-time)
              :condition (format nil "Unknown Dreyeck build task ~S."
                                 task-id))
        (handler-case
            (let* ((result (run-build-task* task-id db-path))
                   (status (build-task-result-status result)))
              (list :kind :dreyeck-build-task-result
                    :task task-id
                    :status status
                    :started-at started-at
                    :finished-at (get-universal-time)
                    :result result))
          (error (condition)
            (list :kind :dreyeck-build-task-result
                  :task task-id
                  :status :failed
                  :started-at started-at
                  :finished-at (get-universal-time)
                  :condition (princ-to-string condition)))))))
