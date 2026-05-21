;;;; Smoke tests for the canonical Kioskberrli ASDF system.

(in-package :kioskberrli/tests)

(defun assert-true (condition message)
  (unless condition
    (error "Kioskberrli smoke test failed: ~A" message))
  condition)

(defun assert-false (condition message)
  (when condition
    (error "Kioskberrli smoke test failed: ~A" message))
  t)

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "Kioskberrli smoke test failed: ~A -- expected ~S, got ~S"
           message
           expected
           actual))
  actual)

(defun assert-contains (needle haystack message)
  (assert-true (and haystack (search needle haystack :test #'char=))
               (format nil "~A -- missing ~S" message needle)))

(defun smoke-temp-root ()
  (merge-pathnames
   (format nil "kioskberrli-assets-smoke-~D-~D/assets/pages/"
           (get-universal-time)
           (random 1000000))
   (uiop:temporary-directory)))

(defun run-asdf-load-smoke-test ()
  (assert-true (asdf:find-system :kioskberrli nil)
               "ASDF must know the canonical :kioskberrli system")
  (asdf:load-system :kioskberrli)
  (assert-true (find-package :kioskberrli)
               "Canonical package :KIOSKBERRLI must exist")
  (assert-true (eq (find-package :kioskberrli)
                   (find-package :dreyeck/kioskbeerli))
               "Compatibility package nickname :DREYECK/KIOSKBEERLI must resolve to :KIOSKBERRLI")
  (assert-true (eq (find-package :kioskberrli)
                   (find-package :kioskbeerli))
               "Compatibility package nickname :KIOSKBEERLI must resolve to :KIOSKBERRLI"))

(defun run-demo-object-smoke-test ()
  (let ((dashboard (make-demo-dashboard))
        (plan (make-demo-plan))
        (trace (make-demo-trace)))
    (assert-true (typep dashboard 'kioskberrli-topic-dashboard)
                 "MAKE-DEMO-DASHBOARD must return a dashboard object")
    (assert-true (typep plan 'kioskberrli-plan-run)
                 "MAKE-DEMO-PLAN must return a plan object")
    (assert-true (typep trace 'kioskberrli-project-trace)
                 "MAKE-DEMO-TRACE must return a trace object")
    (assert-true (find "boot-pi" (tasks-of plan) :key #'id-of :test #'string=)
                 "Demo plan must include the boot-pi task")))

(defun run-trace-event-smoke-test ()
  (let* ((trace (make-demo-trace))
         (before (length (entries-of trace)))
         (entry (record-trace-event
                 :trace trace
                 :task-id "build-aarch64-image"
                 :from-state "linux-builder-required"
                 :to-state "linux-builder-required"
                 :scxml-event "EVIDENCE_MISSING"
                 :status "missing-evidence"
                 :evidence-paths '("missing: smoke-test artifact")
                 :note "Smoke test trace event.")))
    (assert-true (typep entry 'kioskberrli-trace-entry)
                 "RECORD-TRACE-EVENT must return the recorded trace entry")
    (assert-equal (1+ before)
                  (length (entries-of trace))
                  "RECORD-TRACE-EVENT must append one trace entry")))

(defun run-fedwiki-asset-smoke-test ()
  (let* ((root (smoke-temp-root))
         (manifest (materialize-fedwiki-assets :slug "kioskberrli"
                                               :root root
                                               :clean t))
         (page-dir (merge-pathnames "kioskberrli/" root)))
    (assert-true (typep manifest 'kioskberrli-fedwiki-asset-manifest)
                 "Materialization must return a manifest object")
    (assert-equal "http://localhost:3000/assets/pages/kioskberrli/"
                  (asset-url-prefix-of manifest)
                  "Manifest must expose the FedWiki page asset URL shape")
    (assert-true (probe-file (merge-pathnames "kioskberrli.asd" page-dir))
                 "Asset directory must contain the flat kioskberrli.asd")
    (assert-true (probe-file (merge-pathnames "src/package.lisp" page-dir))
                 "Asset directory must contain src/package.lisp")
    (assert-true (probe-file (merge-pathnames "src/kioskberrli.scxml" page-dir))
                 "Asset directory must contain the SCXML artifact")
    (assert-true (probe-file (merge-pathnames "tests/smoke.lisp" page-dir))
                 "Asset directory must contain tests/smoke.lisp")
    (assert-true (probe-file (merge-pathnames "MANIFEST.txt" page-dir))
                 "Asset directory must contain MANIFEST.txt")
    (assert-false (probe-file (merge-pathnames "kioskberrli/src/package.lisp"
                                               page-dir))
                  "Asset directory must not contain a nested canonical source tree")
    (assert-contains
     "http://localhost:3000/assets/pages/kioskberrli/"
     (uiop:read-file-string (merge-pathnames "MANIFEST.txt" page-dir))
     "Manifest text must include the local FedWiki asset URL prefix")
    manifest))

(defun run-sqlite-smoke-test ()
  (let ((db (merge-pathnames
             (format nil "kioskberrli-smoke-~D.sqlite" (random 1000000))
             (uiop:temporary-directory))))
    (handler-case
        (let ((store (open-or-create-sqlite-store :db-path db
                                                  :ensure-schema t)))
          (assert-true (probe-file db)
                       "SQLite store creation must create the database file")
          (assert-equal :ready
                        (sqlite-store-schema-status-of store)
                        "SQLite schema status must be ready after schema creation")
          (persist-plan store (make-demo-plan))
          (record-trace-event
           :store store
           :task-id "build-aarch64-image"
           :from-state "linux-builder-required"
           :to-state "linux-builder-required"
           :status "missing-evidence"
           :payload "{\"smoke\":true}"
           :source-fedwiki-slug "kioskberrli"
           :source-asset-reference "assets/pages/kioskberrli/kioskberrli.asd")
          :ran)
      (kioskberrli-sqlite-unavailable (condition)
        (format t "~&Skipping SQLite smoke test: ~A~%" condition)
        :skipped))))

(defun run-no-chatgpt-dependency-smoke-test ()
  (let ((asd (uiop:read-file-string
              (asdf:system-relative-pathname :kioskberrli
                                             "kioskberrli.asd"))))
    (assert-false (search "chatgpt-hyperdoc" asd :test #'char-equal)
                  ":kioskberrli ASDF definition must not depend on chatgpt-hyperdoc")))

(defun run-compatibility-load-smoke-test ()
  (asdf:load-system :dreyeck/kioskbeerli)
  (assert-true (asdf:find-system :dreyeck/kioskbeerli nil)
               "Compatibility ASDF system :DREYECK/KIOSKBEERLI must load")
  (assert-true (typep (kioskbeerli-planner-run) 'kioskberrli-plan-run)
               "Old kioskbeerli planner entrypoint must return the canonical plan class")
  t)

(defun run-kioskberrli-smoke-tests ()
  (run-asdf-load-smoke-test)
  (run-demo-object-smoke-test)
  (run-trace-event-smoke-test)
  (run-fedwiki-asset-smoke-test)
  (run-sqlite-smoke-test)
  (run-no-chatgpt-dependency-smoke-test)
  (run-compatibility-load-smoke-test)
  (format t "~&Kioskberrli smoke tests passed.~%")
  t)
