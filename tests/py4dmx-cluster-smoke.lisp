;;;; Focused smoke tests for the Py4dmx documentation cluster
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-PY4DMX-CLUSTER-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun py4dmx-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun py4dmx-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun py4dmx-smoke-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-py4dmx-page (namestring)
  (uiop:read-file-string
   (py4dmx-smoke-relative-path namestring)))

(defun normalize-py4dmx-smoke-whitespace (string)
  (with-output-to-string (stream)
    (loop with pending-space = nil
          with wrote-char = nil
          for char across string
          do (if (find char '(#\Space #\Tab #\Newline #\Return))
                 (setf pending-space t)
                 (progn
                   (when pending-space
                     (when wrote-char
                       (write-char #\Space stream))
                     (setf pending-space nil))
                   (write-char char stream)
                   (setf wrote-char t))))))

(defun assert-py4dmx-page-contains-all (page-source page-label needles)
  (let ((normalized-page-source
         (normalize-py4dmx-smoke-whitespace page-source)))
    (dolist (needle needles)
      (py4dmx-assert-true
       (search (normalize-py4dmx-smoke-whitespace needle)
               normalized-page-source
               :test #'char=)
       (format nil "~A must contain ~S" page-label needle)))))

(defun run-py4dmx-cluster-topic-and-page-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let ((topic (hyperdoc::py4dmx-topic)))
    (py4dmx-assert-true
     (fboundp 'hyperdoc::py4dmx-topic)
     "Missing topic function HYPERDOC::PY4DMX-TOPIC")
    (py4dmx-assert-equal
     "Py4dmx"
     (hyperbook:title-of topic)
     "Py4dmx topic title")
    (py4dmx-assert-true
     (hyperbook:find-page hyperdoc::*topics* "Py4dmx" :signal-error? t)
     "Missing Topics HyperBook page Py4dmx")
    (py4dmx-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* "Py4dmx" :signal-error? t)
     "Missing HyperDoc page Py4dmx")))

(defun run-py4dmx-cluster-documentation-smoke-test ()
  (assert-py4dmx-page-contains-all
   (read-py4dmx-page "hyperdoc/Py4dmx.html")
   "Py4dmx"
   '("dmx.py"
     "dmx.cfg.example"
     "note_example.json"
     "person_example.vcf"
     "GET /core/topic/0"
     "DMX plugin extension boundary"
     "What should remain external"))
  (assert-py4dmx-page-contains-all
   (read-py4dmx-page "hyperdoc/DMX session bootstrap and JSESSIONID.html")
   "DMX session bootstrap and JSESSIONID"
   '("Py4dmx"
     "GET /core/topic/0"
     "HyperDoc's guarded auth teaching surfaces still model"
     "POST /access-control/login"))
  (assert-py4dmx-page-contains-all
   (read-py4dmx-page "hyperdoc/DMX machine-readable read paths.html")
   "DMX machine-readable read paths"
   '("Py4dmx"
     "core/topics/query"
     "related-topics"
     "webclient URLs"))
  (assert-py4dmx-page-contains-all
   (read-py4dmx-page "hyperdoc/HyperDoc DMX architectural implications.html")
   "HyperDoc DMX architectural implications"
   '("Py4dmx"
     "generic topic and assoc creation"
     "raw plugin GET/POST"
     "Generic DMX scripting remains external evidence")))

(defun run-py4dmx-cluster-smoke-tests ()
  (run-py4dmx-cluster-topic-and-page-smoke-test)
  (run-py4dmx-cluster-documentation-smoke-test)
  (format t "~&Py4dmx cluster smoke tests passed.~%")
  t)
