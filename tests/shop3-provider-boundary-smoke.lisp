(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export
   (list (intern "RUN-SHOP3-PROVIDER-BOUNDARY-SMOKE-TESTS"
                 :hyperdoc/tests))
   :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun spb-system-relative-pathname (relative)
  (asdf:system-relative-pathname :hyperdoc relative))

(defun spb-file-string (relative)
  (uiop:read-file-string (spb-system-relative-pathname relative)))

(defun spb-assert (condition message)
  (assert condition nil "~A" message))

(defun spb-dependencies-of (system-designator)
  (let ((system (asdf:find-system system-designator)))
    (mapcar (lambda (dependency)
              (etypecase dependency
                (symbol (string-downcase (symbol-name dependency)))
                (string (string-downcase dependency))
                (cons (string-downcase (princ-to-string dependency)))))
            (asdf:system-depends-on system))))

(defun spb-report-value (report indicator)
  (getf report indicator))

(defun spb-report-selected-directory-p (report needle)
  (some (lambda (directory)
          (search needle directory :test #'char=))
        (spb-report-value report :selected-directories)))

(defun spb-report-rejected-directory-p (report classification)
  (some (lambda (entry)
          (eq classification (getf entry :classification)))
        (spb-report-value report :rejected-directories)))

(defun run-shop3-provider-boundary-report-smoke-test ()
  (let ((report
         (hyperdoc/shop3-provider:register-shop3-provider-source-registry
          :additional-directories
          (list #P"/Users/rgb/workspace/shop3/"
                #P"/Users/rgb/workspace/shop3/jenkins/ext/alexandria/"))))
    (spb-assert (eq :shop3-provider-boundary-report
                    (spb-report-value report :kind))
                "Provider helper must return an inspectable report.")
    (spb-assert (spb-report-value report :broad-shop3-root-tree-avoided)
                "Provider helper must avoid broad SHOP3 root tree registration.")
    (spb-assert (spb-report-value report :vendored-alexandria-provider-avoided)
                "Provider helper must avoid vendored Alexandria provider registration.")
    (spb-assert (spb-report-value report :inherited-source-registry-ignored)
                "Provider helper must ignore inherited source-registry configuration.")
    (let ((registry-form (spb-report-value report :source-registry-form)))
      (spb-assert (member :ignore-inherited-configuration registry-form)
                  "Provider helper must ignore inherited ASDF source-registry entries.")
      (spb-assert (not (member :inherit-configuration registry-form))
                  "Provider helper must not inherit broad caller source-registry entries."))
    (spb-assert (spb-report-selected-directory-p
                 report "/Users/rgb/workspace/shop3/shop3/")
                "Provider helper must select the narrow SHOP3 ASDF directory.")
    (spb-assert (spb-report-selected-directory-p
                 report "/Users/rgb/workspace/shop3/jenkins/ext/pddl-tools/")
                "Provider helper must select the narrow pddl-tools ASDF directory.")
    (spb-assert (not (spb-report-selected-directory-p
                      report "/Users/rgb/workspace/shop3/jenkins/ext/alexandria/"))
                "Provider helper must not select vendored Alexandria.")
    (spb-assert (spb-report-rejected-directory-p
                 report :rejected-broad-shop3-root)
                "Provider helper must explicitly reject the broad SHOP3 root.")
    (spb-assert (spb-report-rejected-directory-p
                 report :rejected-vendored-alexandria)
                "Provider helper must explicitly reject vendored Alexandria.")
    (let ((alexandria-state
           (spb-report-value report :existing-alexandria-package-state)))
      (spb-assert (member (getf alexandria-state :classification)
                          '(:alexandria-version-nickname-present
                            :alexandria-package-state-present
                            :alexandria-package-state-absent))
                  "Provider helper must report Alexandria package state."))
    report))

(defun run-shop3-provider-boundary-source-smoke-test ()
  (let ((source (spb-file-string "hyperdoc-shop3/provider-boundary.lisp"))
        (plan (spb-file-string
               "hyperdoc/zettel-9182-shop3-provider-boundary-repair-plan.sexp")))
    (spb-assert (not (search "delete-package" source :test #'char-equal))
                "Provider helper must not delete packages.")
    (spb-assert (not (search "rename-package" source :test #'char-equal))
                "Provider helper must not rename packages.")
    (spb-assert (not (search "(:tree \"/Users/rgb/workspace/shop3/\"" source
                             :test #'char=))
                "Provider helper must not register the whole SHOP3 tree.")
    (spb-assert (search ":ignore-inherited-configuration" source
                        :test #'char=)
                "Provider helper must ignore inherited source-registry entries.")
    (spb-assert (search ":forbid-vendored-alexandria-provider t" plan
                        :test #'char=)
                "Zettel 9182 plan must forbid vendored Alexandria provider.")
    (spb-assert (search ":forbid-shop3-root-tree t" plan :test #'char=)
                "Zettel 9182 plan must forbid broad SHOP3 root tree.")
    (spb-assert (search ":ignore-inherited-source-registry t" plan
                        :test #'char=)
                "Zettel 9182 plan must ignore inherited source-registry contamination.")
    t))

(defun run-shop3-provider-boundary-core-dependency-smoke-test ()
  (let ((hyperdoc-dependencies (spb-dependencies-of :hyperdoc))
        (provider-dependencies
          (spb-dependencies-of :hyperdoc/shop3-provider-boundary))
        (tests-source
          (spb-file-string "tests/shop3-provider-boundary-smoke.lisp"))
        (forbidden-load-system-fragment
          (concatenate 'string "load-system " ":kioskbeerli")))
    (spb-assert (not (member "shop3" hyperdoc-dependencies :test #'string=))
                ":hyperdoc must load without depending on SHOP3.")
    (spb-assert (not (member "kioskbeerli" hyperdoc-dependencies
                             :test #'string=))
                ":hyperdoc must not depend on Kioskbeerli.")
    (spb-assert (not (member "shop3" provider-dependencies :test #'string=))
                "Provider boundary helper must be loadable before SHOP3.")
    (spb-assert (not (member "hyperdoc" provider-dependencies :test #'string=))
                "Provider boundary helper must be loadable before HyperDoc.")
    (spb-assert (not (search forbidden-load-system-fragment tests-source
                             :test #'char-equal))
                "Provider boundary tests must not load Kioskbeerli.")
    t))

(defun run-shop3-provider-boundary-smoke-tests ()
  (run-shop3-provider-boundary-report-smoke-test)
  (run-shop3-provider-boundary-source-smoke-test)
  (run-shop3-provider-boundary-core-dependency-smoke-test)
  (format t "~&SHOP3 provider boundary smoke tests passed.~%")
  t)
