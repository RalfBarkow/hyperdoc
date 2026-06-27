;;;; Deterministic Dreyeck build/check tasks for Codex and inspectors.

(in-package #:dreyeck/build)

(defparameter *dreyeck-build-task-definitions*
  '((:id :dmx-durable-note-materialization-status
     :title "DMX durable-note materialization status"
     :summary "Read structured materialization status from the DMX SQLite production store."
     :mutates-p nil
     :dependencies nil)
    (:id :inspect-dmx-learning-topics
     :title "Inspect DMX learning topics"
     :summary "Read the materialized learning-topic subset and its required associations."
     :mutates-p nil
     :dependencies (:dmx-durable-note-materialization-status))
    (:id :validate-dmx-learning-topics
     :title "Validate DMX learning topics"
     :summary "Replay durable-note materialization and verify learning topics plus idempotence."
     :mutates-p t
     :dependencies (:dmx-durable-note-materialization-status
                    :inspect-dmx-learning-topics))))

(defun list-build-tasks ()
  "Return the stable Dreyeck build/check tasks available to Codex."
  (copy-tree *dreyeck-build-task-definitions*))

(defun build-task-known-p (task-id)
  (find task-id *dreyeck-build-task-definitions*
        :key (lambda (definition) (getf definition :id))
        :test #'eq))

(defun build-task-definition (task-id)
  (or (build-task-known-p task-id)
      (error "Unknown Dreyeck build task ~S." task-id)))

(defun build-task-dependencies (task-id)
  (copy-list (getf (build-task-definition task-id) :dependencies)))

(defun build-task-mutates-p (task-id)
  (and (getf (build-task-definition task-id) :mutates-p) t))

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

(defun build-session-id ()
  (format nil "dreyeck-build-session-~D" (get-universal-time)))

(defun make-build-session
    (&key (id (build-session-id))
          (db-path *dreyeck-dmx-production-db-path*))
  "Create a Dreyeck build/check session.

The session records action state independently from task definitions so Codex
can inspect planning and checking without becoming the build system."
  (list :kind :dreyeck-build-session
        :id id
        :db-path db-path
        :started-at (get-universal-time)
        :ended-at nil
        :actions (make-hash-table :test #'eq)
        :errors nil))

(defun build-session-action-table (session)
  (getf session :actions))

(defun build-action-state (session task-id &key create)
  (or (gethash task-id (build-session-action-table session))
      (when create
        (let* ((definition (build-task-definition task-id))
               (state
                 (list :kind :dreyeck-build-action-state
                       :task-name task-id
                       :dependencies
                       (copy-list (getf definition :dependencies))
                       :inputs (list :db-path (namestring (getf session :db-path)))
                       :up-to-date-before-session-p nil
                       :needed-in-session-p nil
                       :done-in-session-p nil
                       :plan-result nil
                       :check-result nil
                       :perform-result nil
                       :errors nil
                       :started-at nil
                       :ended-at nil)))
          (setf (gethash task-id (build-session-action-table session))
                state)))))

(defun build-session-action-states (session)
  (loop for state being the hash-values of (build-session-action-table session)
        collect (copy-tree state)))

(defun build-task-result
    (task-id phase status result &key session action-state condition)
  (let ((now (get-universal-time)))
    (list :kind :dreyeck-build-task-result
          :task task-id
          :phase phase
          :status status
          :session-id (getf session :id)
          :started-at (or (and action-state
                               (getf action-state :started-at))
                          now)
          :finished-at now
          :result result
          :action-state (and action-state (copy-tree action-state))
          :condition condition)))

(defun dmx-learning-topics-status-passed-p (learning-topics)
  (and (eq :passed (getf learning-topics :status))
       (null (getf learning-topics :missing-learning-topic-ids))
       (null (getf learning-topics :missing-learning-association-ids))))

(defun read-only-task-check (task-id db-path)
  (ecase task-id
    (:dmx-durable-note-materialization-status
     (run-dmx-durable-note-materialization-status-task db-path))
    (:inspect-dmx-learning-topics
     (run-inspect-dmx-learning-topics-task db-path))
    (:validate-dmx-learning-topics
     (let* ((status (durable-note-materialization-status :db-path db-path))
            (learning-topics
              (dmx-materialized-learning-topics :db-path db-path))
            (passed? (and (eq :passed (getf status :last-validation-status))
                          (dmx-learning-topics-status-passed-p
                           learning-topics))))
       (list :status (if passed? :passed :failed)
             :production-db-path (getf status :production-db-path)
             :materialization-status status
             :learning-topics learning-topics
             :last-replay-status :not-run
             :perform-required-p (not passed?)
             :non-mutating-p t)))))

(defun task-up-to-date-before-session-p (task-id db-path)
  (eq :passed (build-task-result-status
               (read-only-task-check task-id db-path))))

(defun task-needed-in-session-p (task-id up-to-date-p force)
  (or force
      (not up-to-date-p)
      (not (build-task-mutates-p task-id))))

(defun update-action-plan-state
    (state task-id db-path up-to-date-p needed-p force)
  (let ((plan-result
          (list :kind :dreyeck-build-task-plan
                :task task-id
                :dependencies (build-task-dependencies task-id)
                :inputs (list :db-path (namestring db-path))
                :up-to-date-before-session-p up-to-date-p
                :needed-in-session-p needed-p
                :done-in-session-p (getf state :done-in-session-p)
                :force-p force
                :will-perform-p needed-p
                :non-mutating-p (not (build-task-mutates-p task-id)))))
    (setf (getf state :inputs) (getf plan-result :inputs)
          (getf state :up-to-date-before-session-p) up-to-date-p
          (getf state :needed-in-session-p) needed-p
          (getf state :plan-result) plan-result)
    plan-result))

(defun plan-build-task
    (session task-id &key (db-path (getf session :db-path)) force)
  "Plan TASK-ID in SESSION without performing it."
  (handler-case
      (let* ((state (build-action-state session task-id :create t))
             (started-at (get-universal-time))
             (up-to-date-p (task-up-to-date-before-session-p task-id db-path))
             (needed-p (task-needed-in-session-p task-id up-to-date-p force))
             (plan nil))
        (setf (getf state :started-at) started-at)
        (dolist (dependency (build-task-dependencies task-id))
          (plan-build-task session dependency :db-path db-path :force nil))
        (setf plan
              (update-action-plan-state
               state task-id db-path up-to-date-p needed-p force))
        (setf (getf state :ended-at) (get-universal-time))
        (build-task-result task-id :plan :planned plan
                           :session session
                           :action-state state))
    (error (condition)
      (build-task-result task-id :plan :failed nil
                         :session session
                         :condition (princ-to-string condition)))))

(defun check-build-task
    (session task-id &key (db-path (getf session :db-path)) force)
  "Check TASK-ID in SESSION without performing mutating work."
  (handler-case
      (let* ((state (or (build-action-state session task-id)
                        (progn
                          (plan-build-task session task-id
                                           :db-path db-path
                                           :force force)
                          (build-action-state session task-id))))
             (started-at (get-universal-time))
             (check-result nil)
             (status nil))
        (setf (getf state :started-at) started-at)
        (dolist (dependency (build-task-dependencies task-id))
          (check-build-task session dependency :db-path db-path))
        (setf check-result (read-only-task-check task-id db-path)
              status (build-task-result-status check-result)
              (getf state :check-result) check-result
              (getf state :needed-in-session-p)
              (task-needed-in-session-p task-id (eq :passed status) force)
              (getf state :ended-at) (get-universal-time))
        (build-task-result task-id :check status check-result
                           :session session
                           :action-state state))
    (error (condition)
      (let ((state (build-action-state session task-id :create t)))
        (push (princ-to-string condition) (getf state :errors))
        (build-task-result task-id :check :failed nil
                           :session session
                           :action-state state
                           :condition (princ-to-string condition))))))

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

(defun perform-build-task* (task-id db-path)
  (ecase task-id
    (:dmx-durable-note-materialization-status
     (run-dmx-durable-note-materialization-status-task db-path))
    (:inspect-dmx-learning-topics
     (run-inspect-dmx-learning-topics-task db-path))
    (:validate-dmx-learning-topics
     (run-validate-dmx-learning-topics-task db-path))))

(defun perform-build-task
    (session task-id &key (db-path (getf session :db-path)) force)
  "Perform TASK-ID in SESSION, running only actions marked needed.

Calling this twice for the same task in the same session returns the recorded
result unless FORCE is true."
  (handler-case
      (let* ((state (or (build-action-state session task-id)
                        (progn
                          (plan-build-task session task-id
                                           :db-path db-path
                                           :force force)
                          (build-action-state session task-id))))
             (already-done-p (and (getf state :done-in-session-p)
                                  (not force)))
             (started-at (get-universal-time)))
        (cond
          (already-done-p
           (build-task-result
            task-id :perform :already-done
            (or (getf state :perform-result)
                (getf state :check-result)
                (getf state :plan-result))
            :session session
            :action-state state))
          (t
           (check-build-task session task-id :db-path db-path :force force)
           (dolist (dependency (build-task-dependencies task-id))
             (perform-build-task session dependency :db-path db-path))
           (setf (getf state :started-at) started-at)
           (let* ((needed-p (or force
                                (getf state :needed-in-session-p)))
                  (perform-result
                    (if needed-p
                        (perform-build-task* task-id db-path)
                        (list :status :passed
                              :perform-status :skipped-up-to-date
                              :production-db-path (namestring db-path)
                              :check-result (getf state :check-result)
                              :last-replay-status :up-to-date-before-session
                              :reason :not-needed-in-session)))
                  (status (build-task-result-status perform-result)))
             (setf (getf state :perform-result) perform-result
                   (getf state :done-in-session-p) t
                   (getf state :ended-at) (get-universal-time))
             (build-task-result task-id :perform status perform-result
                                :session session
                                :action-state state)))))
    (error (condition)
      (let ((state (build-action-state session task-id :create t)))
        (push (princ-to-string condition) (getf state :errors))
        (build-task-result task-id :perform :failed nil
                           :session session
                           :action-state state
                           :condition (princ-to-string condition))))))

(defun build-session-status (session)
  "Return a structured snapshot of SESSION without performing work."
  (list :kind :dreyeck-build-session-status
        :id (getf session :id)
        :production-db-path (namestring (getf session :db-path))
        :started-at (getf session :started-at)
        :ended-at (getf session :ended-at)
        :actions (build-session-action-states session)
        :errors (copy-list (getf session :errors))))

(defclass build-referee-decision-route ()
  ((id :accessor build-referee-decision-route-id-of
       :initarg :id)
   (title :accessor build-referee-decision-route-title-of
          :initarg :title)
   (summary :accessor build-referee-decision-route-summary-of
            :initarg :summary)
   (session-id :accessor build-referee-decision-route-session-id-of
               :initarg :session-id)
   (requested-goal
    :accessor build-referee-decision-route-requested-goal-of
    :initarg :requested-goal)
   (candidate-actions
    :accessor build-referee-decision-route-candidate-actions-of
    :initarg :candidate-actions)
   (selected-task
    :accessor build-referee-decision-route-selected-task-of
    :initarg :selected-task)
   (selected-action
    :accessor build-referee-decision-route-selected-action-of
    :initarg :selected-action)
   (decoded-operation
    :accessor build-referee-decision-route-decoded-operation-of
    :initarg :decoded-operation)
   (dependencies
    :accessor build-referee-decision-route-dependencies-of
    :initarg :dependencies)
   (up-to-date-before-session-p
    :accessor build-referee-decision-route-up-to-date-before-session-p-of
    :initarg :up-to-date-before-session-p)
   (needed-in-session-p
    :accessor build-referee-decision-route-needed-in-session-p-of
    :initarg :needed-in-session-p)
   (done-in-session-p
    :accessor build-referee-decision-route-done-in-session-p-of
    :initarg :done-in-session-p)
   (reason :accessor build-referee-decision-route-reason-of
           :initarg :reason)
   (safe-to-perform-p
    :accessor build-referee-decision-route-safe-to-perform-p-of
    :initarg :safe-to-perform-p)
   (safe-to-perform-reason
    :accessor build-referee-decision-route-safe-to-perform-reason-of
    :initarg :safe-to-perform-reason)
   (perform-entry-point
    :accessor build-referee-decision-route-perform-entry-point-of
    :initarg :perform-entry-point)
   (source :accessor build-referee-decision-route-source-of
           :initarg :source)
   (referee-result
    :accessor build-referee-decision-route-referee-result-of
    :initarg :referee-result)
   (session-status
    :accessor build-referee-decision-route-session-status-of
    :initarg :session-status)))

(defmethod print-object ((object build-referee-decision-route) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (build-referee-decision-route-requested-goal-of object)
            (build-referee-decision-route-selected-action-of object))))

(defun build-action-state-for-task (status task-id)
  (find task-id (getf status :actions)
        :key (lambda (state) (getf state :task-name))
        :test #'eq))

(defun build-task-display-title (task-id)
  (getf (build-task-definition task-id) :title))

(defun build-referee-operation-entry-point (action)
  (case action
    (:plan-build-task 'plan-build-task)
    (:check-build-task 'check-build-task)
    (:perform-build-task 'perform-build-task)
    (otherwise nil)))

(defun build-referee-action-label (action task-id)
  (case action
    (:plan-build-task
     (format nil "Plan ~A" (build-task-display-title task-id)))
    (:check-build-task
     (format nil "Check ~A" (build-task-display-title task-id)))
    (:perform-build-task
     (format nil "Perform ~A" (build-task-display-title task-id)))
    (:complete
     (format nil "~A is complete or not needed"
             (build-task-display-title task-id)))
    (otherwise
     (format nil "~(~A~) ~A" action (build-task-display-title task-id)))))

(defun decode-build-referee-operation (action task-id)
  (let ((definition (build-task-definition task-id)))
    (list :kind :build-referee-decoded-operation
          :task task-id
          :task-title (getf definition :title)
          :task-summary (getf definition :summary)
          :action action
          :action-label (build-referee-action-label action task-id)
          :entry-point (build-referee-operation-entry-point action)
          :mutates-p (and (eq action :perform-build-task)
                          (build-task-mutates-p task-id))
          :dependencies (build-task-dependencies task-id))))

(defun build-referee-safe-to-perform (action state)
  (cond
    ((not (eq action :perform-build-task))
     (values nil :selected-action-is-not-perform))
    ((null state)
     (values nil :selected-task-has-no-session-state))
    ((getf state :done-in-session-p)
     (values nil :already-done-in-session))
    ((not (getf state :needed-in-session-p))
     (values nil :not-needed-in-session))
    (t
     (values t :checked-needed-and-not-done))))

(defun build-referee-candidate-action
    (task-id action state reason action-call selected-p)
  (multiple-value-bind (safe-to-perform-p safe-reason)
      (build-referee-safe-to-perform action state)
    (list :kind :build-referee-candidate-action
          :task task-id
          :selected-p selected-p
          :next-action action
          :decoded-operation (decode-build-referee-operation action task-id)
          :dependencies (build-task-dependencies task-id)
          :up-to-date-before-session-p
          (and state (getf state :up-to-date-before-session-p))
          :needed-in-session-p
          (and state (getf state :needed-in-session-p))
          :done-in-session-p
          (and state (getf state :done-in-session-p))
          :reason reason
          :safe-to-perform-p safe-to-perform-p
          :safe-to-perform-reason safe-reason
          :perform-entry-point 'perform-build-task
          :action-call action-call
          :action-state (and state (copy-tree state)))))

(defun build-referee-route-candidate-actions (referee session-status)
  (let* ((requested-task (getf referee :requested-task))
         (selected-task (getf referee :task))
         (selected-action (getf referee :next-action))
         (dependency-actions
           (copy-tree (getf referee :dependency-actions)))
         (requested-state
           (build-action-state-for-task session-status requested-task))
         (requested-candidate
           (build-referee-candidate-action
            requested-task
            (if (eq selected-task requested-task)
                selected-action
                (build-session-next-action-for-state requested-state))
            requested-state
            (if (eq selected-task requested-task)
                (getf referee :reason)
                (build-session-next-action-reason
                 (build-session-next-action-for-state requested-state)
                 requested-state))
            (if (eq selected-task requested-task)
                (getf referee :action-call)
                (build-session-next-action-call
                 (build-session-next-action-for-state requested-state)
                 requested-task))
            (eq selected-task requested-task))))
    (append
     (loop for dependency-action in dependency-actions
           for task = (getf dependency-action :task)
           for action = (getf dependency-action :next-action)
           for state = (build-action-state-for-task session-status task)
           collect
           (build-referee-candidate-action
            task
            action
            state
            (getf dependency-action :reason)
            (getf dependency-action :action-call)
            (eq selected-task task)))
     (list requested-candidate))))

(defun build-session-next-action-route
    (session &key (task-id :validate-dmx-learning-topics)
             (db-path (getf session :db-path)))
  "Return an inspectable route projection of the Lisp referee decision.

This projection reads BUILD-SESSION-NEXT-ACTION and BUILD-SESSION-STATUS. It
does not plan, check, or perform work on its own."
  (let* ((referee (build-session-next-action session
                                             :task-id task-id
                                             :db-path db-path))
         (session-status (build-session-status session))
         (selected-task (getf referee :task))
         (selected-action (getf referee :next-action))
         (selected-state
           (build-action-state-for-task session-status selected-task))
         (candidate-actions
           (build-referee-route-candidate-actions referee session-status))
         (selected-candidate
           (find selected-task candidate-actions
                 :key (lambda (candidate) (getf candidate :task))
                 :test #'eq)))
    (make-instance
     'build-referee-decision-route
     :id (format nil "build-referee-route-~A-~(~A~)"
                 (getf session :id)
                 task-id)
     :title "Build Referee Route"
     :summary
     "Inspectable route projection of a Dreyeck build referee decision."
     :session-id (getf session :id)
     :requested-goal task-id
     :candidate-actions candidate-actions
     :selected-task selected-task
     :selected-action selected-action
     :decoded-operation
     (decode-build-referee-operation selected-action selected-task)
     :dependencies (build-task-dependencies selected-task)
     :up-to-date-before-session-p
     (and selected-state
          (getf selected-state :up-to-date-before-session-p))
     :needed-in-session-p
     (and selected-state
          (getf selected-state :needed-in-session-p))
     :done-in-session-p
     (and selected-state
          (getf selected-state :done-in-session-p))
     :reason (getf referee :reason)
     :safe-to-perform-p
     (and selected-candidate
          (getf selected-candidate :safe-to-perform-p))
     :safe-to-perform-reason
     (and selected-candidate
          (getf selected-candidate :safe-to-perform-reason))
     :perform-entry-point 'perform-build-task
     :source "dreyeck/build:build-session-next-action"
     :referee-result referee
     :session-status session-status)))

(defun build-session-next-action-for-state (state)
  (cond
    ((null state)
     :plan-build-task)
    ((null (getf state :plan-result))
     :plan-build-task)
    ((null (getf state :check-result))
     :check-build-task)
    ((and (getf state :needed-in-session-p)
          (not (getf state :done-in-session-p)))
     :perform-build-task)
    (t
     :complete)))

(defun build-session-next-action-call (action task-id)
  (case action
    (:plan-build-task
     (list 'plan-build-task 'session task-id))
    (:check-build-task
     (list 'check-build-task 'session task-id))
    (:perform-build-task
     (list 'perform-build-task 'session task-id))
    (:complete
     (list :complete task-id))
    (otherwise
     (list :unknown task-id))))

(defun build-session-next-action-reason (action state)
  (case action
    (:plan-build-task
     (if state :planned-state-missing-plan-result :no-session-state))
    (:check-build-task
     :planned-but-not-checked)
    (:perform-build-task
     :checked-and-needed-but-not-done)
    (:complete
     (if (getf state :done-in-session-p)
         :done-in-session
         :not-needed-in-session))
    (otherwise
     :unknown)))

(defun build-session-next-action
    (session &key (task-id :validate-dmx-learning-topics)
             (db-path (getf session :db-path)))
  "Select the next admissible action as inspectable Common Lisp data.

This is the referee form. It reads SHOP3-shaped plan context, build session
state, and read-only DMX status. It does not mutate the session or production
store."
  (let* ((state (build-action-state session task-id))
         (dependencies (build-task-dependencies task-id))
         (dependency-actions
           (loop for dependency in dependencies
                 for dependency-state = (build-action-state session dependency)
                 for action = (build-session-next-action-for-state
                               dependency-state)
                 collect
                 (list :task dependency
                       :next-action action
                       :reason
                       (build-session-next-action-reason
                        action dependency-state)
                       :action-call
                       (build-session-next-action-call
                        action dependency)
                       :action-state
                       (and dependency-state
                            (copy-tree dependency-state)))))
         (dependency-action
           (find-if-not (lambda (action)
                          (eq :complete (getf action :next-action)))
                        dependency-actions))
         (selected-task (if dependency-action
                            (getf dependency-action :task)
                            task-id))
         (selected-state (if dependency-action
                             (build-action-state session selected-task)
                             state))
         (selected-action (if dependency-action
                              (getf dependency-action :next-action)
                              (build-session-next-action-for-state state)))
         (selected-reason (if dependency-action
                              (getf dependency-action :reason)
                              (build-session-next-action-reason
                               selected-action state)))
         (dmx-status (durable-note-materialization-status :db-path db-path))
         (dmx-learning (dmx-materialized-learning-topics :db-path db-path)))
    (list :kind :dreyeck-build-referee-next-action
          :source :build-session-next-action
          :session-id (getf session :id)
          :shop3-plan-source
          "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
          :requested-task task-id
          :task selected-task
          :next-action selected-action
          :admissible-p (not (eq :complete selected-action))
          :reason selected-reason
          :action-call
          (build-session-next-action-call selected-action selected-task)
          :dependency-actions dependency-actions
          :action-state (and selected-state (copy-tree selected-state))
          :dmx-state
          (list :production-db-path (getf dmx-status :production-db-path)
                :materialization-status
                (getf dmx-status :last-validation-status)
                :learning-topic-status (getf dmx-learning :status)
                :missing-learning-topic-ids
                (getf dmx-learning :missing-learning-topic-ids)
                :missing-learning-association-ids
                (getf dmx-learning
                      :missing-learning-association-ids))
          :decision-owner :dreyeck-build-lisp-referee
          :codex-role :reader-and-display-surface)))

(defun run-build-task
    (task-id &key (db-path *dreyeck-dmx-production-db-path*) force)
  "Run TASK-ID and return a structured result.

This is the compatibility convenience API. The primitive model is the session
API: MAKE-BUILD-SESSION, PLAN-BUILD-TASK, CHECK-BUILD-TASK, and
PERFORM-BUILD-TASK."
  (let ((session (make-build-session :db-path db-path)))
    (if (not (build-task-known-p task-id))
        (build-task-result task-id :perform :unknown-task nil
                           :session session
                           :condition
                           (format nil "Unknown Dreyeck build task ~S."
                                   task-id))
        (progn
          (plan-build-task session task-id :db-path db-path :force force)
          (perform-build-task session task-id :db-path db-path :force force)))))
