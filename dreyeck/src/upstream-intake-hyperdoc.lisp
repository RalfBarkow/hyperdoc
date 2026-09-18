;;;; HyperDoc pages for the read-only Upstream Intake process.

(in-package #:dreyeck/upstream-intake)

(hyperdoc:see
  (hyperdoc:page "HyperDoc Page Loading: Source Ahead of the Running Image"))

(hyperdoc:defexample hyperdoc-page-loading-image-state-example
  (labels ((generic-state (name)
             (let* ((package (find-package "HYPERDOC"))
                    (symbol (and package (find-symbol name package)))
                    (function
                     (and symbol (fboundp symbol) (fdefinition symbol))))
               (list :symbol symbol :visibility
                     (and symbol (nth-value 1 (find-symbol name package)))
                     :generic-function-p
                     (and function (typep function 'generic-function)) :methods
                     (and function (typep function 'generic-function)
                          (mapcar
                           (lambda (method)
                             (list :qualifiers (method-qualifiers method)
                                   :specializers
                                   (mapcar #'princ-to-string
                                           (sb-mop:method-specializers
                                            method))))
                           (sb-mop:generic-function-methods function)))))))
    (list :evidence-kind :live-image-observation :cwd (uiop/os:getcwd)
          :load-page (generic-state "LOAD-PAGE") :page-class
          (generic-state "PAGE-CLASS") :dreyeck-hyperdoc-package
          (find-package "DREYECK/HYPERDOC") :intake-evidence-api
          (let ((package (find-package "DREYECK/UPSTREAM-INTAKE")))
            (and package
                 (mapcar
                  (lambda (name)
                    (multiple-value-list (find-symbol name package)))
                  '("HYPERDOC-PAGE-LOADING-BEFORE"
                    "MAKE-HYPERDOC-PAGE-LOADING-INTAKE"
                    "HYPERDOC-PAGE-LOADING-EVIDENCE"
                    "PAGE-LOADING-SOURCE-RELATIONS")))))))

(hyperdoc:defexample hyperdoc-page-loading-source-state-example
  (let* ((root (asdf/system:system-source-directory "dreyeck/upstream-intake"))
         (policy-path (merge-pathnames "dreyeck/src/hyperdoc-pages.lisp" root))
         (intake-path
          (merge-pathnames "dreyeck/src/upstream-intake-hyperdoc.lisp" root))
         (policy
          (and (probe-file policy-path)
               (uiop/stream:read-file-string policy-path)))
         (intake
          (and (probe-file intake-path)
               (uiop/stream:read-file-string intake-path))))
    (list :evidence-kind :source-text-observation :policy
          (list :path policy-path :exists (not (null (probe-file policy-path)))
                :page-class-present
                (not
                 (null
                  (and policy
                       (search "PAGE-CLASS" policy :test #'char-equal))))
                :load-page-present
                (not
                 (null
                  (and policy
                       (search "LOAD-PAGE" policy :test #'char-equal)))))
          :intake
          (list :path intake-path :exists (not (null (probe-file intake-path)))
                :source-relations-present
                (not
                 (null
                  (and intake
                       (search "PAGE-LOADING-SOURCE-RELATIONS" intake :test
                               #'char-equal))))
                :unfinished-git-rung-present
                (not
                 (null
                  (and intake
                       (search "GIT-RUNG" intake :test #'char-equal))))))))

(hyperdoc:defexample hyperdoc-page-loading-checkpoint-example
  (list :subject :hyperdoc-page-loading :live-image
        (hyperdoc-page-loading-image-state-example) :source-now
        (hyperdoc-page-loading-source-state-example) :upstream-reference
        (list :commit "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
              :git-classification :available-not-integrated :evidence-kind
              :reported-checkpoint)
        :relations
        (list :git-ancestry-is-not-protocol-adoption t
              :source-state-is-not-loaded-image-state t
              :source-observation-is-not-fresh-reconstruction t
              :observation-is-not-integration-decision t)))










(hyperdoc:defexample hyperdoc-page-loading-comparison-example
  "Compare preserved pre-integration evidence with a new read-only observation."
  (list :before (hyperdoc-page-loading-before) :now
        (upstream-reference-summary (make-hyperdoc-page-loading-intake))
        :application :separate-authorized-source-refactor :proof-system
        "dreyeck/hyperdoc/boundary-tests"))

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
