;;;; A window owns its interaction, and mutates it one context at a time.
(defpackage #:dreyeck/gesture/clog/tests
  (:use #:cl)
  (:local-nicknames (#:g #:dreyeck/gesture/clog)
                    (#:tp #:dreyeck/gesture/transport)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:sm #:dreyeck/state-machine)
                    (#:bt #:bordeaux-threads))
  (:export #:run-gesture-clog-tests))

(in-package #:dreyeck/gesture/clog/tests)

(defun %envelope (sequence kind &key (x 0) which (buttons 2))
  (tp:make-transport-envelope
   :sequence sequence :kind kind :x x :y 0 :which which :buttons buttons
   :target (list :type :lisp-source-definition :name 'gesture-clog-tests)))

(defun %in-thread (thunk)
  "Run THUNK on its own thread, as a CLOG callback would be. An error comes
back to the joining thread instead of ending the process."
  (bt:make-thread (lambda () (handler-case (progn (funcall thunk) nil)
                               (error (condition) condition)))))

(defun %join (thread)
  (let ((condition (bt:join-thread thread)))
    (when condition (error "A callback thread failed: ~A" condition))))

(defun %delivered (window)
  (mapcar (lambda (snapshot) (getf snapshot :sequence))
          (reverse (g:gesture-window-log window))))

(defun test-arrival-order-is-reconstructed-across-threads ()
  "Three callbacks on three threads, arriving 1, 3, 2."
  (let ((window (g:make-gesture-window))
        (envelopes (list (%envelope 1 :pointer-down :which 3)
                         (%envelope 2 :pointer-move :x 20)
                         (%envelope 3 :pointer-move :x 30))))
    (dolist (sequence '(1 3 2))
      (let ((envelope (find sequence envelopes :key #'tp:transport-envelope-sequence)))
        (%join (%in-thread (lambda () (g:receive-envelope window envelope))))))
    (let ((transport (tp:witness-transport (g:gesture-window-witness window))))
      (assert (equal '(1 3 2) (tp:transport-arrival-order transport)))
      (assert (equal '(1 2 3) (tp:transport-delivery-order transport))))
    (assert (equal '(1 2 3) (%delivered window)))
    (assert (eq :marking (getf (g:gesture-window-result window) :mode))))
  t)

(defun test-one-mutator-at-a-time ()
  "The first delivery is held open inside the window. A second callback
arrives meanwhile with the next number. It must wait: had it gone ahead,
it would have been inside the window at the same time, and the reducer
would have seen the two out of order or overlapping."
  (let* ((busy 0) (most 0) (order nil)
         (guard (bt:make-lock "probe"))
         (window (g:make-gesture-window
                  :projection
                  (lambda (window snapshot)
                    (declare (ignore window))
                    (bt:with-lock-held (guard)
                      (incf busy) (setf most (max most busy))
                      (push (getf snapshot :sequence) order))
                    (when (eql 1 (getf snapshot :sequence)) (sleep 0.3))
                    (bt:with-lock-held (guard) (decf busy)))))
         (first (%in-thread
                 (lambda () (g:receive-envelope window (%envelope 1 :pointer-down :which 3))))))
    (sleep 0.05)
    (let ((second (%in-thread
                   (lambda () (g:receive-envelope window (%envelope 2 :pointer-move :x 20))))))
      (%join first)
      (%join second))
    (assert (= 1 most))
    (assert (equal '(1 2) (reverse order)))
    (assert (equal '(1 2) (%delivered window))))
  t)

(defun test-windows-own-their-state ()
  "Two windows, two sequence spaces, both starting at one."
  (let ((a (g:make-gesture-window)) (b (g:make-gesture-window)))
    (assert (not (eq (tp:witness-transport (g:gesture-window-witness a))
                     (tp:witness-transport (g:gesture-window-witness b)))))
    (assert (not (eq (tp:witness-input (g:gesture-window-witness a))
                     (tp:witness-input (g:gesture-window-witness b)))))
    (assert (not (eq (g:gesture-window-lock a) (g:gesture-window-lock b))))
    (dolist (window (list a b))
      (g:receive-envelope window (%envelope 1 :pointer-down :which 3))
      (g:receive-envelope window (%envelope 2 :pointer-move :x 20)))
    (assert (equal '(1 2) (%delivered a)))
    (assert (equal '(1 2) (%delivered b))))
  t)

(defun test-route-installs-into-a-running-server ()
  "The route is added to the server that is running; no server is started."
  (let ((initialize (fdefinition 'clog:initialize))
        (set-on-new-window (fdefinition 'clog:set-on-new-window))
        (started nil) (recorded nil))
    (unwind-protect
         (progn
           (setf (fdefinition 'clog:initialize)
                 (lambda (&rest arguments) (setf started (or arguments t))))
           (setf (fdefinition 'clog:set-on-new-window)
                 (lambda (handler &key path) (push (list handler path) recorded)))
           (assert (equal "/gesture" (g:install-gesture-route))))
      (setf (fdefinition 'clog:initialize) initialize)
      (setf (fdefinition 'clog:set-on-new-window) set-on-new-window))
    (assert (null started))
    (assert (equal '("/gesture") (mapcar #'second recorded)))
    (assert (eq (fdefinition 'g:on-gesture-window) (first (first recorded)))))
  t)

(defun run-gesture-clog-tests ()
  (test-arrival-order-is-reconstructed-across-threads)
  (test-one-mutator-at-a-time)
  (test-windows-own-their-state)
  (test-route-installs-into-a-running-server)
  (format t "~&GESTURE-CLOG-PASS: arrival 1 3 2 on three threads delivered ~
1 2 3; a callback that arrives during another's delivery waits for it; two ~
windows own two transports, two sessions and two locks, and both count from ~
one; the route is added to a running server without starting one.~%")
  t)
