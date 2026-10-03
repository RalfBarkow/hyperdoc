;;;; Tutorials 1 and 2 mount on a running CLOG server and start none.
;;;;
;;;; What is observed is CLOG's own routing state: the table its
;;;; ON-CONNECT reads to choose a window handler, and the table its HTTP
;;;; layer reads to answer a path with a boot page. No listener is opened
;;;; and no browser connects, so nothing here says the page renders or
;;;; that a click turns the heading green. That takes a live server.
(defpackage #:dreyeck/clog-tutorial/tests
  (:use #:cl)
  (:local-nicknames (#:tut #:dreyeck/clog-tutorial))
  (:export #:run-tests))

(in-package #:dreyeck/clog-tutorial/tests)

(defparameter *path* "/clog-tutorial/01")

(defparameter *paths* '("/clog-tutorial/01" "/clog-tutorial/02")
  "Every path these tests may write to. CALL-WITH-CLOG puts each back.")

(defun %routes ()
  "CLOG's routing state as two alists, path -> window handler and
path -> boot file, each in a stable order."
  (flet ((entries (table)
           (let ((entries nil))
             (maphash (lambda (key value) (push (cons key value) entries)) table)
             (sort entries #'string< :key (lambda (entry) (princ-to-string (car entry)))))))
    (list (entries clog::*url-to-on-new-window*)
          (entries clog-connection::*url-to-boot-file*))))

(defun %added (before after)
  "The entries of AFTER that BEFORE does not have, table by table."
  (mapcar (lambda (old new) (set-difference new old :test #'equal)) before after))

(defun call-with-clog (running thunk)
  "Call THUNK with CLOG's running flag bound to RUNNING, and CLOG:INITIALIZE
and CLOG:OPEN-BROWSER replaced by recorders, so a call to either is seen
and neither opens a socket or a browser. Binding the flag stands in for a
server only as far as CLOG:IS-RUNNING-P reads it.

THUNK writes to CLOG's real routing tables. Whatever it set at *PATHS* is
put back as it was before returning. The result holds THUNK's value, the
recorded calls, and the routes before and after THUNK."
  (let ((initialize (fdefinition 'clog:initialize))
        (open-browser (fdefinition 'clog:open-browser))
        (saved (loop for path in *paths*
                     append (loop for table in (list clog::*url-to-on-new-window*
                                                     clog-connection::*url-to-boot-file*)
                                  collect (list* path table
                                                 (multiple-value-list (gethash path table))))))
        (before (%routes))
        (calls nil))
    (unwind-protect
         (progn
           (setf (fdefinition 'clog:initialize)
                 (lambda (&rest arguments) (push (cons :initialize arguments) calls))
                 (fdefinition 'clog:open-browser)
                 (lambda (&rest arguments) (push (cons :open-browser arguments) calls)))
           (let* ((value (let ((clog-connection:*clog-running* running))
                           (funcall thunk)))
                  (after (%routes)))
             (list :value value :calls (reverse calls)
                   :before before :after after)))
      (setf (fdefinition 'clog:initialize) initialize
            (fdefinition 'clog:open-browser) open-browser)
      (loop for (path table value present) in saved
            do (if present
                   (setf (gethash path table) value)
                   (remhash path table))))))

(defun %install ()
  (handler-case (tut:install-tutorial-1-route)
    (error (condition) condition)))

(defun %handler-symbol ()
  (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-1"))

(defun test-mounts-only-on-a-running-server ()
  "Without a server, the install refuses: no route, no load. With one,
the same call loads Tutorial 1 -- inside the observed call, since the
package did not exist before it -- and registers, and neither
CLOG:INITIALIZE nor CLOG:OPEN-BROWSER is reached, the two calls the
tutorial's START-TUTORIAL makes."
  (let ((stopped (call-with-clog nil #'%install)))
    (assert (typep (getf stopped :value) 'error))
    (assert (null (getf stopped :calls)))
    (assert (equal (getf stopped :before) (getf stopped :after)))
    (assert (null (find-package "CLOG-TUT-1"))))
  (let ((running (call-with-clog t #'%install)))
    (assert (equal *path* (getf running :value)))
    (assert (null (getf running :calls)))
    (assert (not (equal (getf running :before) (getf running :after)))))
  (assert (find-package "CLOG-TUT-1"))
  (multiple-value-bind (symbol status) (find-symbol "START-TUTORIAL" "CLOG-TUT-1")
    (assert (and symbol (eq :external status) (fboundp symbol))))
  t)

(defun test-route-is-the-tutorial-handler ()
  "The install adds exactly two entries and removes none:
/clog-tutorial/01 to the symbol CLOG-TUT-1::ON-NEW-WINDOW, whose
definition comes from the file in CLOG's own installation, and
/clog-tutorial/01 to CLOG's default boot page."
  (let* ((observed (call-with-clog t #'tut:install-tutorial-1-route))
         (before (getf observed :before))
         (after (getf observed :after))
         (symbol (%handler-symbol))
         (source (tut:tutorial-1-source)))
    (assert (eq :internal (nth-value 1 (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-1"))))
    (assert (equal (list (list (cons *path* symbol))
                         (list (cons *path* "./boot.html")))
                   (%added before after)))
    (assert (equal '(nil nil) (%added after before)))
    (assert (probe-file source))
    (assert (uiop:subpathp source (clog:clog-install-dir)))
    (assert (equal (namestring (truename source))
                   (namestring
                    (truename
                     (sb-introspect:definition-source-pathname
                      (sb-introspect:find-definition-source
                       (fdefinition symbol))))))))
  t)

(defun test-reinstall-changes-nothing ()
  "A second install leaves CLOG's routes as the first left them, and does
not reload the tutorial. Reloading would be visible: it is done below on
purpose, and the function object changes, while the route keeps naming
the symbol and so reaches the new definition."
  (let* ((symbol (%handler-symbol))
         (definition (fdefinition symbol))
         (observed (call-with-clog
                    t (lambda ()
                        (tut:install-tutorial-1-route)
                        (let ((once (%routes)))
                          (tut:install-tutorial-1-route)
                          (list once (%routes)))))))
    (destructuring-bind (once twice) (getf observed :value)
      (assert (equal once twice)))
    (assert (eq definition (fdefinition symbol)))
    ;; Positive control: a real reload does change the function object.
    (handler-bind ((warning #'muffle-warning))
      (load (tut:tutorial-1-source)))
    (assert (not (eq definition (fdefinition symbol))))
    (let* ((observed (call-with-clog t #'tut:install-tutorial-1-route))
           (handler (cdr (assoc *path* (first (getf observed :after))
                                :test #'equal))))
      (assert (eq symbol handler))
      (assert (not (eq definition (fdefinition handler))))))
  t)


;;; Tutorial 2, against the same tables. Each claim is the one made for
;;; Tutorial 1, checked again on Tutorial 2's own source and handler.

(defun %tutorial-2-handler-symbol ()
  (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-2"))

(defun %install-2 ()
  (handler-case (tut:install-tutorial-2-route)
    (error (condition) condition)))

(defun test-tutorial-2-mounts-only-on-a-running-server ()
  "Refused without a server, nothing loaded. With one, Tutorial 2 is loaded
inside the observed call, START-TUTORIAL is not reached, and the route
holds Tutorial 2's handler at /clog-tutorial/02 -- not Tutorial 1's."
  (let ((stopped (call-with-clog nil #'%install-2)))
    (assert (typep (getf stopped :value) 'error))
    (assert (null (getf stopped :calls)))
    (assert (equal (getf stopped :before) (getf stopped :after)))
    (assert (null (find-package "CLOG-TUT-2"))))
  (let ((running (call-with-clog t #'%install-2)))
    (assert (equal "/clog-tutorial/02" (getf running :value)))
    (assert (null (getf running :calls)))
    (assert (find-package "CLOG-TUT-2"))
    (let ((handler (%tutorial-2-handler-symbol)))
      (assert (eq :internal (nth-value 1 (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-2"))))
      (assert (not (eq handler (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-1"))))
      (assert (equal (list (list (cons "/clog-tutorial/02" handler))
                           (list (cons "/clog-tutorial/02" "./boot.html")))
                     (%added (getf running :before) (getf running :after))))
      (assert (equal '(nil nil) (%added (getf running :after) (getf running :before))))))
  (multiple-value-bind (symbol status) (find-symbol "START-TUTORIAL" "CLOG-TUT-2")
    (assert (and symbol (eq :external status) (fboundp symbol))))
  t)

(defun test-tutorial-2-source-is-installed ()
  "Tutorial 2's handler was defined by 02-tutorial.lisp in CLOG's own
installation."
  (let ((source (tut:tutorial-2-source)))
    (assert (probe-file source))
    (assert (uiop:subpathp source (clog:clog-install-dir)))
    (assert (equal "02-tutorial" (pathname-name source)))
    (assert (equal (namestring (truename source))
                   (namestring
                    (truename
                     (sb-introspect:definition-source-pathname
                      (sb-introspect:find-definition-source
                       (fdefinition (%tutorial-2-handler-symbol)))))))))
  t)

(defun test-tutorial-2-reinstall-changes-nothing ()
  "Mounting Tutorial 2 twice leaves the routes as once did and does not
reload it; mounting both tutorials leaves each route with its own handler."
  (let* ((definition (fdefinition (%tutorial-2-handler-symbol)))
         (observed (call-with-clog
                    t (lambda ()
                        (tut:install-tutorial-2-route)
                        (let ((once (%routes)))
                          (tut:install-tutorial-2-route)
                          (tut:install-tutorial-1-route)
                          (list once (%routes)))))))
    (destructuring-bind (once both) (getf observed :value)
      (assert (equal (first once) (remove "/clog-tutorial/01" (first both)
                                          :key #'car :test #'equal)))
      (assert (eq (%tutorial-2-handler-symbol)
                  (cdr (assoc "/clog-tutorial/02" (first both) :test #'equal))))
      (assert (eq (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-1")
                  (cdr (assoc "/clog-tutorial/01" (first both) :test #'equal)))))
    (assert (eq definition (fdefinition (%tutorial-2-handler-symbol)))))
  t)

(defun run-tests ()
  (assert (and (null (find-package "CLOG-TUT-1")) (null (find-package "CLOG-TUT-2"))) ()
          "A tutorial is already loaded in this image, so its first load ~
cannot be observed. Run these tests in a fresh image.")
  (test-mounts-only-on-a-running-server)
  (test-route-is-the-tutorial-handler)
  (test-reinstall-changes-nothing)
  (test-tutorial-2-mounts-only-on-a-running-server)
  (test-tutorial-2-source-is-installed)
  (test-tutorial-2-reinstall-changes-nothing)
  (format t "~&CLOG tutorial tests passed: refusal, no initialize, route, reinstall; the same for Tutorial 2.~%")
  t)
