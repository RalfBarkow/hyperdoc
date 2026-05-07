;;;; Web debugger integration for HyperBook (SBCL)
;;
;;;; This is a pragmatic, GT-inspired debugger object model:
;;;;   - when a thread enters the debugger, create a session object
;;;;   - expose it through the inspector (as a normal Lisp object)
;;;;   - allow invoking restarts from the web UI
;;
;;;; In non-development mode this is not enabled.
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :clog-moldable-inspector)

(defclass web-debugger-registry () ())

(defclass web-debugger-session ()
  ((id :initarg :id :reader web-debugger-session-id)
   (created :initarg :created :reader web-debugger-session-created)
   (thread :initarg :thread :reader web-debugger-session-thread)
   (condition :initarg :condition :reader web-debugger-session-condition)
   (backtrace :initarg :backtrace :reader web-debugger-session-backtrace)
   ;; Restart objects are only valid while the paused thread remains in the hook.
   (restarts :initarg :restarts :reader web-debugger-session-restarts)
   (restart-info :initarg :restart-info :reader web-debugger-session-restart-info)
   (mutex :initarg :mutex :reader web-debugger-session-mutex)
   (waitq :initarg :waitq :reader web-debugger-session-waitq)
   (queue :initform '() :accessor web-debugger-session-queue)
   (closed? :initform nil :accessor web-debugger-session-closed?)))

(defvar *web-debugger-registry* (make-instance 'web-debugger-registry))
(defvar *web-debugger-sessions* (make-hash-table :test #'equal))
(defvar *web-debugger-sessions-mutex* (sb-thread:make-mutex :name "web-debugger-sessions"))
(defvar *web-debugger-next-id* 0)
(defvar *web-debugger-prev-hook* nil)
(defvar *web-debugger-enabled* nil)

(defun web-debugger-registry ()
  *web-debugger-registry*)

(defun next-web-debugger-session-id ()
  (sb-thread:with-mutex (*web-debugger-sessions-mutex*)
    (incf *web-debugger-next-id*)
    (format nil "~8,'0X" *web-debugger-next-id*)))

(defun register-web-debugger-session (session)
  (sb-thread:with-mutex (*web-debugger-sessions-mutex*)
    (setf (gethash (web-debugger-session-id session) *web-debugger-sessions*) session))
  session)

(defun remove-web-debugger-session (session)
  (sb-thread:with-mutex (*web-debugger-sessions-mutex*)
    (remhash (web-debugger-session-id session) *web-debugger-sessions*))
  session)

(defun list-web-debugger-sessions ()
  (sb-thread:with-mutex (*web-debugger-sessions-mutex*)
    (let (acc)
      (maphash (lambda (_k v)
                 (declare (ignore _k))
                 (push v acc))
               *web-debugger-sessions*)
      (sort acc #'string< :key #'web-debugger-session-id))))

(defun find-web-debugger-session (id)
  (sb-thread:with-mutex (*web-debugger-sessions-mutex*)
    (gethash id *web-debugger-sessions*)))

(defun capture-condition-backtrace (condition &key (count 200))
  (or (ignore-errors
        (with-output-to-string (s)
          (uiop:print-condition-backtrace condition :stream s)))
      (ignore-errors
        (with-output-to-string (s)
          (sb-debug:print-backtrace :count count :stream s)))
      ""))

(defun restart->info (restart)
  (let* ((name (ignore-errors (restart-name restart)))
         (name* (or name :anonymous))
         (report (ignore-errors
                   (with-output-to-string (s)
                     (format s "~A" restart)))))
    (list :name name* :report (or report ""))))

(defun make-web-debugger-session (condition)
  (let* ((id (next-web-debugger-session-id))
         (mutex (sb-thread:make-mutex :name (format nil "web-debugger-session-~A" id)))
         (waitq (sb-thread:make-waitqueue :name (format nil "web-debugger-session-wq-~A" id)))
         (restarts (compute-restarts condition))
         (info (mapcar #'restart->info restarts))
         (bt (capture-condition-backtrace condition)))
    (make-instance 'web-debugger-session
                   :id id
                   :created (get-universal-time)
                   :thread sb-thread:*current-thread*
                   :condition condition
                   :backtrace bt
                   :restarts restarts
                   :restart-info info
                   :mutex mutex
                   :waitq waitq)))

(defun enqueue-web-debugger-command (session command)
  (sb-thread:with-mutex ((web-debugger-session-mutex session))
    (push command (web-debugger-session-queue session))
    (sb-thread:condition-notify (web-debugger-session-waitq session)))
  t)

(defun dequeue-web-debugger-command (session)
  (sb-thread:with-mutex ((web-debugger-session-mutex session))
    (loop while (and (null (web-debugger-session-queue session))
                     (not (web-debugger-session-closed? session)))
          do (sb-thread:condition-wait (web-debugger-session-waitq session)
                                       (web-debugger-session-mutex session)))
    (pop (web-debugger-session-queue session))))

(defun web-debugger-invoke-restart (session restart-index)
  (enqueue-web-debugger-command session (list :invoke restart-index)))

(defun web-debugger-fallback-to-sbcl-debugger (session)
  (enqueue-web-debugger-command session (list :fallback)))

(defun web-debugger-dismiss (session)
  ;; Removes it from the registry but does not resume the paused thread.
  (remove-web-debugger-session session)
  (setf (web-debugger-session-closed? session) t)
  (enqueue-web-debugger-command session (list :noop)))

#+sbcl
(defun web-debugger-invoke-debugger-hook (condition old-hook)
  (handler-case
      (let ((session (register-web-debugger-session
                      (make-web-debugger-session condition))))
        (loop
         (let ((cmd (dequeue-web-debugger-command session)))
           (when (null cmd)
             (return))
           (ecase (first cmd)
             (:noop
              nil)
             (:fallback
              (remove-web-debugger-session session)
              (setf (web-debugger-session-closed? session) t)
              (when (and old-hook (functionp old-hook))
                (funcall old-hook condition nil))
              (return))
             (:invoke
              (let* ((idx (second cmd))
                     (restart (nth idx (web-debugger-session-restarts session))))
                (when restart
                  (remove-web-debugger-session session)
                  (setf (web-debugger-session-closed? session) t)
                  (invoke-restart restart)
                  (return))))))))
    (error (e)
      (declare (ignore e))
      (when (and old-hook (functionp old-hook))
        (ignore-errors (funcall old-hook condition nil))))))

(defun enable-web-debugger ()
  "Enable the web debugger. Intended for development mode only."
  #+sbcl
  (unless *web-debugger-enabled*
    (setf *web-debugger-prev-hook* sb-ext:*invoke-debugger-hook*)
    (setf sb-ext:*invoke-debugger-hook*
          #'(lambda (condition old-hook)
              (web-debugger-invoke-debugger-hook condition
                                                 (or old-hook *web-debugger-prev-hook*))))
    (setf *web-debugger-enabled* t))
  t)

(defun disable-web-debugger ()
  "Disable the web debugger and restore the previous hook."
  #+sbcl
  (when *web-debugger-enabled*
    (setf sb-ext:*invoke-debugger-hook* *web-debugger-prev-hook*)
    (setf *web-debugger-prev-hook* nil)
    (setf *web-debugger-enabled* nil))
  t)

(defmethod hv:text-representation ((r web-debugger-registry))
  (format nil "Debugger Sessions (~D)"
          (length (list-web-debugger-sessions))))

(hv:defview 👀debugger (r web-debugger-registry)
  (let ((sessions (list-web-debugger-sessions)))
    (hv:html-view :title "Debugger" :priority 1
                  (hv:html
                   (:h3 "Active debugger sessions")
                   (if (null sessions)
                       (hv:html (:p "No active sessions."))
                       (hv:html
                        (:ul
                         (loop for session in sessions
                               do (hv:html
                                   (:li
                                    (hv:eval-button
                                     (format nil "Inspect ~A" (web-debugger-session-id session))
                                     (hv:thunk session)
                                     "Inspect this debugger session")
                                    " "
                                    (:span (hv:esc (format nil "~A"
                                                           (type-of (web-debugger-session-condition session)))))
                                    " -- "
                                    (:span (hv:esc (format nil "~A"
                                                           (web-debugger-session-condition session))))))))))))))

(defmethod hv:text-representation ((session web-debugger-session))
  (format nil "Debug Session ~A" (web-debugger-session-id session)))

(hv:defview 👀debugger (session web-debugger-session)
  (let ((info (web-debugger-session-restart-info session)))
    (hv:html-view :title "Debug Session" :priority 1
                  (hv:html
                   (:h3 "Condition")
                   (:pre (hv:esc (format nil "~A" (web-debugger-session-condition session))))
                   (:h3 "Thread")
                   (:pre (hv:esc (format nil "~A" (web-debugger-session-thread session))))
                   (:h3 "Restarts")
                   (if (null info)
                       (hv:html (:p "No restarts reported."))
                       (hv:html
                        (:ol
                         (loop for entry in info
                               for i from 0
                               do (hv:html
                                   (:li
                                    (hv:action-button
                                     (format nil "[~D] ~A" i (getf entry :name))
                                     (hv:thunk (web-debugger-invoke-restart session i) t)
                                     (or (getf entry :report) "Invoke restart"))
                                    " "
                                    (:small (hv:esc (or (getf entry :report) "")))))))))
                   (:p
                    (hv:action-button
                     "Fallback to SBCL debugger"
                     (hv:thunk (web-debugger-fallback-to-sbcl-debugger session) t)
                     "Let SBCL enter its own debugger (TTY/Swank)")
                    " "
                    (hv:action-button
                     "Dismiss session"
                     (hv:thunk (web-debugger-dismiss session) t)
                     "Remove from the session list (does not resume paused thread)"))
                   (:h3 "Backtrace")
                   (:pre :style "white-space: pre-wrap"
                         (hv:esc (or (web-debugger-session-backtrace session) "")))))))
