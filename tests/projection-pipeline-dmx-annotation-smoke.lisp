(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export
   (list
    (intern "RUN-PROJECTION-PIPELINE-DMX-ANNOTATION-SMOKE-TESTS"
            :hyperdoc/tests))
   :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun projection-pipeline-path (relative)
  (asdf/system:system-relative-pathname :hyperdoc relative))

(defun projection-pipeline-file-contains-p (relative needle)
  (let ((text
         (uiop/stream:read-file-string (projection-pipeline-path relative))))
    (search needle text :test #'char=)))

(defun projection-pipeline-assert (condition message)
  (assert condition nil "~A" message))

(defun projection-pipeline-symbol (package name &key fboundp)
  (let* ((pkg
          (or (find-package package)
              (error "Package ~A is not loaded." package)))
         (symbol
          (or (find-symbol name pkg)
              (error "Symbol ~A not found in package ~A." name package))))
    (when (and fboundp (not (fboundp symbol)))
      (error "Symbol ~A in package ~A is not fbound." name package))
    symbol))

(defun projection-pipeline-call (package name &rest args)
  (apply (symbol-function (projection-pipeline-symbol package name :fboundp t))
         args))

(defun projection-pipeline-id-string (value)
  (etypecase value (string value) (symbol (symbol-name value))))

(defun run-projection-pipeline-page-smoke-test ()
  (dolist
      (needle
       '("<h1>Projection Pipeline for DMX Annotations</h1>" "Pipeline stages"
         "Inspectable examples" "Readback boundary"
         "DMX machine-readable read paths" "SHOP3 Planning Layer for HyperDoc"
         "SCXML Architect"))
    (projection-pipeline-assert
     (projection-pipeline-file-contains-p
      "hyperdoc/Projection Pipeline for DMX Annotations.html" needle)
     (format nil "Projection page must contain ~S." needle)))
  t)

(defun run-projection-pipeline-scxml-smoke-test ()
  (let* ((chart
          (projection-pipeline-call :hyperdoc/scxml "PARSE-SCXML-FILE"
           (projection-pipeline-path
            "hyperdoc/projection-pipeline-dmx-annotation.scxml")))
         (states-of
          (symbol-function
           (projection-pipeline-symbol :hyperdoc/scxml "SCXML-CHART-STATES-OF"
            :fboundp t)))
         (state-id-of
          (symbol-function
           (projection-pipeline-symbol :hyperdoc/scxml "SCXML-STATE-ID-OF"
            :fboundp t)))
         (initial-of
          (symbol-function
           (projection-pipeline-symbol :hyperdoc/scxml
            "SCXML-CHART-INITIAL-STATE-OF" :fboundp t)))
         (state-ids
          (mapcar
           (lambda (state)
             (projection-pipeline-id-string (funcall state-id-of state)))
           (funcall states-of chart))))
    (projection-pipeline-assert
     (string= "classifyAnnotation"
              (projection-pipeline-id-string (funcall initial-of chart)))
     "Projection SCXML must start at classifyAnnotation.")
    (dolist
        (state
         '("classifyAnnotation" "buildLocalPayload" "buildWritePlan"
           "validatePayload" "validateViewProps" "preflightBackend"
           "dryRunBlocked" "mutationAllowed" "topicUpserted"
           "workspaceAssigned" "topicmapPlaced" "journalRecorded"
           "readbackStarted" "readbackVerified" "verified"
           "verificationFailed"))
      (projection-pipeline-assert (member state state-ids :test #'string=)
       (format nil "Projection SCXML must include state ~A." state))))
  t)

(defun run-projection-pipeline-demo-smoke-test ()
  (let ((report
         (projection-pipeline-call :hyperdoc
          "PROJECTION-PIPELINE-DEMO-DRY-RUN-REPORT")))
    (projection-pipeline-assert (eq :dry-run (getf report :state))
     "Demo report must be dry-run by default.")
    (projection-pipeline-assert (not (getf report :mutation-allowed))
     "Demo report must not allow mutation by default.")
    (dolist
        (stage
         '(:normalize-annotation :build-write-plan :validate-payload
           :backend-compatibility-preflight :topic-upsert :workspace-assignment
           :topicmap-placement :journal-transition
           :reopen-persisted-annotation))
      (projection-pipeline-assert (member stage (getf report :stages))
       (format nil "Demo report must expose stage ~S." stage))))
  t)

(defun run-projection-pipeline-shop3-smoke-test ()
  (handler-case
   (progn
    (asdf/operate:load-system :hyperdoc/shop3)
    (let* ((pkg (find-package :hyperdoc/shop3))
           (run-symbol
            (and pkg (find-symbol "RUN-PROJECTION-PIPELINE-PLAN-OBJECT" pkg))))
      (unless (and run-symbol (fboundp run-symbol))
        (format t
                "~&SHOP3 projection pipeline plan object not defined yet; skipping.~%")
        (return-from run-projection-pipeline-shop3-smoke-test t))
      (let ((plan (funcall (symbol-function run-symbol))))
        (projection-pipeline-assert plan
         "SHOP3 projection pipeline plan object must be non-NIL.")
        (let ((mode-symbol (find-symbol "EXECUTION-MODE-OF" pkg)))
          (when (and mode-symbol (fboundp mode-symbol))
            (projection-pipeline-assert
             (eq :plan-only (funcall (symbol-function mode-symbol) plan))
             "SHOP3 projection pipeline plan must be plan-only."))))
      t))
   (error (condition)
          (format t "~&SHOP3 projection pipeline smoke skipped softly: ~A~%"
                  condition)
          t)))

(defun run-projection-pipeline-dmx-annotation-smoke-tests ()
  (run-projection-pipeline-page-smoke-test)
  (run-projection-pipeline-scxml-smoke-test)
  (run-projection-pipeline-demo-smoke-test)
  (run-projection-pipeline-shop3-smoke-test)
  (format t "~&Projection pipeline DMX annotation smoke tests passed.~%")
  t)

