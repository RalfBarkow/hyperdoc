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

(defun test-menu-follows-window-bindings ()
  "A menu shows the window's own Bindings for the pressed subject's type:
the code page keeps exactly its sectors, and an Association window offers
Inspect relation contract and nothing from the code page."
  (let* ((code-page (g:make-gesture-window))
         (association (g:make-gesture-window
                       :bindings (w:make-association-binding-catalog)))
         (code-subject (list :type :lisp-source-definition :name 'gesture-clog-tests))
         (association-subject (list :type :topicmap-association))
         (ids (lambda (window subject kind)
                (mapcar #'w:gesture-binding-id (g:menu-bindings window subject kind)))))
    (assert (equal '("binding/radial-insert-defexample" "binding/radial-disabled-sector")
                   (funcall ids code-page code-subject :radial-menu)))
    (assert (equal '("binding/mark-insert-defexample")
                   (funcall ids code-page code-subject :learned-mark)))
    (assert (equal '("binding/radial-inspect-relation-contract")
                   (funcall ids association association-subject :radial-menu)))
    (assert (equal '("binding/mark-inspect-relation-contract")
                   (funcall ids association association-subject :learned-mark)))
    (assert (equal '("Inspect relation contract")
                   (mapcar #'g::%label-text
                           (g:menu-bindings association association-subject :radial-menu))))
    ;; Neither window offers the other's sectors.
    (assert (null (g:menu-bindings association code-subject :radial-menu)))
    (assert (null (g:menu-bindings code-page association-subject :radial-menu)))
    ;; The menu reads the very Bindings the window's reducer selects from.
    (assert (every (lambda (binding)
                     (member binding (tp:input-session-bindings
                                      (tp:witness-input (g:gesture-window-witness association)))
                             :test #'eq))
                   (g:menu-bindings association association-subject :radial-menu)))
    ;; Production: two Bindings, one EQ Operation, for Topicmap Associations.
    (let ((catalog (w:make-association-binding-catalog)))
      (assert (equal '(:radial-menu :learned-mark) (mapcar #'w:gesture-binding-kind catalog)))
      (assert (every (lambda (b) (eq (w:inspect-relation-contract-operation)
                                     (w:gesture-binding-operation b)))
                     catalog))
      (assert (every (lambda (b) (eq :topicmap-association (w:gesture-binding-target-type b)))
                     catalog))))
  t)

(defun test-terminal-interaction-shows-nothing ()
  "Completed and cancelled interactions keep their record -- :MENU-VISIBLE
stays true once revealed, the mode stays :MARKING -- but a surface shows
no menu, no mark and no highlight for them. A deadline arriving after the
end redraws the surface and shows nothing; the next press starts clean."
  (let* ((shown nil)
         (window (g:make-gesture-window
                  :projection (lambda (window snapshot)
                                (declare (ignore window))
                                (push (list* (getf snapshot :state) (getf snapshot :menu-visible)
                                             (multiple-value-list (g:menu-presentation snapshot)))
                                      shown))))
         (sequence 0))
    (flet ((feed (kind &key (x 0) which (buttons 2))
             (g:receive-envelope window (%envelope (incf sequence) kind :x x :which which
                                                                        :buttons buttons))
             (first shown)))
      ;; Novice: the menu shows while open, highlights its sector, and goes on completion.
      (feed :pointer-down :which 3)
      (assert (equal '(:pressed nil nil nil nil) (first shown)))
      (assert (equal '(:menu-visible t t nil nil) (feed :reveal-deadline)))
      (assert (equal '(:sector-selected t t nil "binding/radial-insert-defexample")
                     (feed :pointer-move :x 20)))
      (assert (equal '(:completed t nil nil nil) (feed :pointer-up :x 20 :buttons 0)))
      ;; Expert: the mark shows while selected and goes on completion.
      (assert (equal '(:pressed nil nil nil nil) (feed :pointer-down :which 3)))
      (assert (equal '(:sector-selected nil nil t "binding/mark-insert-defexample")
                     (feed :pointer-move :x 20)))
      (assert (equal '(:completed nil nil nil nil) (feed :pointer-up :x 20 :buttons 0)))
      ;; A deadline after completion changes nothing in the closed session;
      ;; the surface is drawn again and still shows nothing.
      (assert (equal '(:completed nil nil nil nil) (feed :reveal-deadline)))
      ;; Released with the menu open but no sector: cancelled, nothing shown.
      (feed :pointer-down :which 3)
      (feed :reveal-deadline)
      (assert (equal '(:cancelled t nil nil nil) (feed :pointer-up :buttons 0)))
      ;; Cancelled by the browser while marking a sector: nothing shown.
      (feed :pointer-down :which 3)
      (feed :pointer-move :x 20)
      (assert (equal '(:cancelled nil nil nil nil) (feed :pointer-cancel :x 20 :buttons 0)))))
  t)

(defun run-gesture-clog-tests ()
  (test-arrival-order-is-reconstructed-across-threads)
  (test-one-mutator-at-a-time)
  (test-windows-own-their-state)
  (test-route-installs-into-a-running-server)
  (test-menu-follows-window-bindings)
  (test-terminal-interaction-shows-nothing)
  (format t "~&GESTURE-CLOG-PASS: arrival 1 3 2 on three threads delivered ~
1 2 3; a callback that arrives during another's delivery waits for it; two ~
windows own two transports, two sessions and two locks, and both count from ~
one; the route is added to a running server without starting one; each menu ~
shows its own window's Bindings for the pressed subject; a completed or ~
cancelled interaction shows no menu, mark or highlight, and a late deadline ~
cannot bring one back.~%")
  t)
