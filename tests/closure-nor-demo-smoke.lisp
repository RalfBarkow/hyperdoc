;;;; Smoke tests for the Graham closures and NOR graph matcher teaching slice

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-CLOSURE-NOR-DEMO-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun closure-nor-smoke-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun closure-nor-smoke-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun closure-nor-smoke-plist-key-present-p (plist key)
  (loop for (plist-key nil) on plist by #'cddr
        thereis (eq plist-key key)))

(defun closure-nor-smoke-report-result (report)
  (getf report :result))

(defun closure-nor-smoke-graph-report-shape-p (report)
  (and (closure-nor-smoke-plist-key-present-p report :expression)
       (closure-nor-smoke-plist-key-present-p report :graph)
       (closure-nor-smoke-plist-key-present-p report :result)
       (closure-nor-smoke-plist-key-present-p report :trace)))

(defun closure-nor-smoke-short-circuit-event-p (event)
  (and (consp event)
       (getf event :nor-short-circuit)
       (getf event :child-matched-p)
       (closure-nor-smoke-plist-key-present-p event :nor-result)
       (null (getf event :nor-result))))

(defun closure-nor-smoke-source-function-names (source)
  (let ((open-tag "<source-of-function>")
        (close-tag "</source-of-function>")
        (position 0)
        names)
    (loop
      for open = (search open-tag source :start2 position :test #'char=)
      while open
      for start = (+ open (length open-tag))
      for close = (search close-tag source :start2 start :test #'char=)
      do (unless close
           (error "Unclosed source-of-function tag starting at ~D" open))
         (push (string-trim '(#\Space #\Tab #\Newline #\Return)
                            (subseq source start close))
               names)
         (setf position (+ close (length close-tag))))
    (nreverse names)))

(defun closure-nor-smoke-hyperdoc-symbol-fbound-p (name)
  (multiple-value-bind (symbol status)
      (find-symbol (string-upcase name) :hyperdoc)
    (and status
         (fboundp symbol))))

(defun run-closure-nor-demo-example-smoke-tests ()
  (asdf:load-system :hyperdoc/closures-nor-demo)
  (let ((adder-report (hyperdoc::closure-nor-demo-make-adder-example))
        (complement-report (hyperdoc::closure-nor-demo-complement-example)))
    (closure-nor-smoke-assert-equal
     5
     (getf adder-report :add3-of-2)
     "MAKE-ADDER example must show the ADD3 closure remembering N=3")
    (closure-nor-smoke-assert-equal
     29
     (getf adder-report :add27-of-2)
     "MAKE-ADDER example must show the ADD27 closure remembering N=27")
    (closure-nor-smoke-assert-equal
     '(nil t nil t nil t)
     (getf complement-report :not-odd-results)
     "OUR-COMPLEMENT example must reverse ODDP through a returned closure"))
  (let ((leaf-report (hyperdoc::closure-nor-demo-graph-leaf-example))
        (nor-success-report
          (hyperdoc::closure-nor-demo-graph-nor-success-example))
        (package-nor-report
          (hyperdoc::closure-nor-demo-run
           (list (intern "NOR" :cl-user) '(:agent :missing))
           hyperdoc::*closure-nor-demo-apollo-graph*))
        (short-circuit-report
          (hyperdoc::closure-nor-demo-graph-nor-short-circuit-example))
        (positive-report
          (hyperdoc::closure-nor-demo-original-query-graph-positive-example))
        (negative-report
          (hyperdoc::closure-nor-demo-original-query-graph-negative-example)))
    (dolist (report (list leaf-report
                          nor-success-report
                          package-nor-report
                          short-circuit-report
                          positive-report
                          negative-report))
      (closure-nor-smoke-assert-true
       (closure-nor-smoke-graph-report-shape-p report)
       "Closure NOR graph reports must include expression/graph/result/trace"))
    (closure-nor-smoke-assert-equal
     t
     (closure-nor-smoke-report-result leaf-report)
     "Graph leaf example must succeed")
    (closure-nor-smoke-assert-equal
     t
     (closure-nor-smoke-report-result nor-success-report)
     "Graph NOR success example must return true")
    (closure-nor-smoke-assert-equal
     t
     (closure-nor-smoke-report-result package-nor-report)
     "Graham closure matcher must accept NOR symbols from other packages")
    (closure-nor-smoke-assert-equal
     nil
     (closure-nor-smoke-report-result short-circuit-report)
     "Graph NOR short-circuit example must return nil")
    (closure-nor-smoke-assert-true
     (some #'closure-nor-smoke-short-circuit-event-p
           (getf short-circuit-report :trace))
     "Graph NOR short-circuit example must record a short-circuit trace event")
    (closure-nor-smoke-assert-equal
     t
     (closure-nor-smoke-report-result positive-report)
     "Original graph query positive example must return true")
    (closure-nor-smoke-assert-equal
     nil
     (closure-nor-smoke-report-result negative-report)
     "Original graph query negative example must return nil")))

(defun run-closure-nor-demo-page-smoke-tests ()
  (asdf:load-system :hyperdoc/server)
  (let* ((page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "Graham Closures and the NOR Graph Matcher"
                                :signal-error? t))
         (source-page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "Graham closures and NOR graph matcher teaching code"
                                :signal-error? t))
         (source
           (uiop:read-file-string
            (asdf:system-relative-pathname
             :hyperdoc
             "hyperdoc/Graham Closures and the NOR Graph Matcher.html"))))
    (declare (ignore source-page))
    (closure-nor-smoke-assert-equal
     nil
     (hyperbook:lookup-issues-of page)
     "Graham closure teaching page must not have lookup issues")
    (dolist (name (closure-nor-smoke-source-function-names source))
      (closure-nor-smoke-assert-true
       (closure-nor-smoke-hyperdoc-symbol-fbound-p name)
       (format nil "Source-of-function target ~A must be fbound" name)))))

(defun run-closure-nor-demo-smoke-tests ()
  (run-closure-nor-demo-example-smoke-tests)
  (run-closure-nor-demo-page-smoke-tests)
  (format t "~&Closure NOR demo smoke tests passed.~%")
  t)
