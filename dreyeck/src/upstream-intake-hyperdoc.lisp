;;;; HyperDoc pages for the read-only Upstream Intake process.

(in-package #:dreyeck/upstream-intake)

(defun upstream-intake-curation-inputs ()
  "The bounded reading inventory shared by the executable demo and its tests."
  (let* ((paths
          (mapcar
           (lambda (path)
             (asdf/system:system-relative-pathname "dreyeck" path))
           '("dreyeck/src/upstream-intake.lisp"
             "dreyeck/src/upstream-intake-hyperdoc.lisp"
             "dreyeck/tests/upstream-intake-smoke.lisp")))
         (test-path (third paths)))
    (values paths
            (append
            (list (list :role :literal-page-lookup :pathname (second paths)
                        :name "UPSTREAM-INTAKE-REMOVAL-WORKSPACE-EXAMPLE"))
            (loop for (role
                       name) in '((:expected-page-set
                                   "+UPSTREAM-INTAKE-PAGE-SPECS+")
                                  (:navigation "CHECK-PAGE-NAVIGATION")
                                  (:page-executable "RUN-HYPERDOC-PAGE-TESTS")
                                  (:symbol-existence
                                   "RUN-UPSTREAM-INTAKE-TESTS"))
                  collect (list :role role :pathname test-path :name name))))))

(hyperdoc:defexample upstream-intake-removal-workspace-example
  "Inspect the warranted consequences of removing one page; authorize no change."
  (multiple-value-bind (paths contracts)
      (upstream-intake-curation-inputs)
    (let ((reference
           (dreyeck/hyperdoc/curation:make-reference-workspace
            (hyperbook:find-page *upstream-intake-hyperdoc*
                                 "Observing an Upstream Commit" :signal-error?
                                 t)
            :source-files paths :contracts contracts)))
      (dreyeck/topicmap/curation:make-impact-workspace reference :policy
                                                       #'dreyeck/hyperdoc/curation:hyperdoc-removal-impact))))

(hyperdoc:defhyperdoc *upstream-intake-hyperdoc*
  :title "Upstream Intake"
  :id "dreyeck/upstream-intake"
  :asdf-system-name "dreyeck/upstream-intake"
  :subdirectory "dreyeck/pages/upstream-intake"
  :main-page-id "Upstream Intake as a Read-Only Observation")
