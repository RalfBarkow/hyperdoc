;;; Exercise the production editor bootstrap using real SLY connections.
(require 'cl-lib)
(require 'sly)
(defun hyperdoc-test-ready (connection)
  (let ((deadline (+ (float-time) 30)))
    (while (not (sly-pid connection))
      (when (> (float-time) deadline) (error "SLY connection timed out"))
      (accept-process-output nil 0.1)))
  connection)
(defun hyperdoc-test-eval (connection code)
  (let ((sly-dispatching-connection connection))
    (cadr (sly-eval `(slynk:eval-and-grab-output ,code) "CL-USER"))))
(let* ((first (hyperdoc-test-ready (car sly-net-processes)))
       (pid (sly-pid first))
       (port (getenv "HYPERDOC_SLYNK_PORT")))
  (cl-assert (equal (hyperdoc-test-eval first "(boundp '*multi-client-witness*)") "NIL"))
  (hyperdoc-test-eval first
    "(defparameter *multi-client-witness* (gensym \"WHITE-IMAGE-\"))")
  (hyperdoc-test-eval first
    "(defparameter *original-witness* *multi-client-witness*)")
  (let ((second (hyperdoc-test-ready
                 (sly-connect "127.0.0.1" (string-to-number port)))))
    (cl-assert (= pid (sly-pid second)))
    (cl-assert (equal (hyperdoc-test-eval second
      "(eq *original-witness* *multi-client-witness*)") "T"))
    ;; Inspect the real listener, not merely the endpoint metadata.
    (cl-assert (equal (hyperdoc-test-eval second
      (format "(multiple-value-bind (host port) (sb-bsd-sockets:socket-name (first (find %s slynk::*servers* :key #'second))) (and (equalp host #(127 0 0 1)) (= port %s)))" port port)) "T"))
    (hyperdoc-test-eval second "(setf *multi-client-witness* :changed-by-second)")
    (cl-assert (equal (hyperdoc-test-eval first "*multi-client-witness*") ":CHANGED-BY-SECOND"))
    (delete-process second))
  ;; A later client can still attach after another has disconnected.
  (let ((third (hyperdoc-test-ready
                (sly-connect "127.0.0.1" (string-to-number port)))))
    (cl-assert (= pid (sly-pid third)))
    (cl-assert (equal (hyperdoc-test-eval third "*multi-client-witness*") ":CHANGED-BY-SECOND"))
    (hyperdoc-test-eval third "(makunbound '*multi-client-witness*)")
    (hyperdoc-test-eval third "(makunbound '*original-witness*)")
    (cl-assert (equal (hyperdoc-test-eval third
       "(and (not (boundp '*multi-client-witness*)) (not (boundp '*original-witness*)) (null slynk::*loaded-user-init-file*))") "T"))
    (delete-process third))
  (with-temp-file (getenv "HYPERDOC_TEST_RESULT")
    (insert (format "%s\n%s\n" pid port)))
  (delete-process first))
