(require :asdf)
(asdf:load-system :hyperdoc/tests)

(defun argument-value (name &optional default)
  (let ((arguments (uiop:command-line-arguments)))
    (or (loop for (option value) on arguments by #'cddr
              when (string= option name)
                do (return value))
        default)))

(defun truth-string (value)
  (if value "T" "NIL"))

(defun emit-line (key value)
  (format t "~A=~A~%" key value))

(defun make-standin-source (mode)
  (cond
    ((string-equal mode "fixture")
     (hyperdoc/tests::make-bibliography-smoke-source))
    ((string-equal mode "live")
     (hyperdoc::make-default-bibliography-source))
    (t
     (error "Unsupported bibliography stand-in mode ~A" mode))))

(let* ((mode (argument-value "--mode" "live"))
       (collection (argument-value "--collection" "coachmark"))
       (entry-page-title
         (argument-value "--entry-page" "Bibliography subcollections in HyperDoc"))
       (link-text (argument-value "--link-text" collection))
       (source (make-standin-source mode))
       (report (hyperdoc::bibliography-authoring-plan-standin-report
                collection
                :source source
                :mode (if (string-equal mode "fixture") :fixture :live)
                :entry-page-title entry-page-title
                :link-text link-text))
       (plan (hyperdoc::bibliography-standin-authoring-plan-of report)))
  (emit-line "MODE" mode)
  (emit-line "COLLECTION" collection)
  (emit-line "ENTRY_PAGE_TITLE" entry-page-title)
  (emit-line "LINK_TEXT" link-text)
  (emit-line "ENTRY_PAGE_RUNTIME_PRESENT"
             (truth-string (hyperdoc::bibliography-standin-entry-page-of report)))
  (emit-line "ENTRY_PAGE_SOURCE_PATH"
             (or (hyperdoc::pathname-namestring-or-nil
                  (hyperdoc::bibliography-standin-entry-page-source-path-of report))
                 ""))
  (emit-line "ENTRY_PAGE_TRACKED_IN_GIT"
             (truth-string
              (eq t (hyperdoc::bibliography-standin-entry-page-tracked-in-git-p report))))
  (emit-line "ENTRY_PAGE_LINK_PRESENT"
             (truth-string
              (hyperdoc::bibliography-standin-entry-page-link-present-p report)))
  (emit-line "ENTRY_PAGE_SELECTION_CLASSIFICATION"
             (hyperdoc::bibliography-standin-entry-page-selection-classification-of report))
  (emit-line "RUNTIME_SURFACE_INVENTORY_CLASSIFICATION"
             (hyperdoc::bibliography-standin-runtime-surface-inventory-classification-of
              report))
  (emit-line "WORKSPACE_VS_FLAKE_MISMATCH_CLASSIFICATION"
             (hyperdoc::bibliography-standin-workspace-vs-flake-mismatch-classification-of
              report))
  (emit-line "PLAN_READY"
             (truth-string (hyperdoc::bibliography-standin-plan-ready-p report)))
  (emit-line "PLAN_BUILD_MS"
             (or (hyperdoc::bibliography-standin-plan-build-ms-of report) ""))
  (emit-line "PLAN_TYPE"
             (if plan
                 (string-upcase (symbol-name (type-of plan)))
                 ""))
  (emit-line "PLAN_ERROR"
             (or (hyperdoc::bibliography-standin-plan-error-of report) ""))
  (emit-line "LAST_PROTOCOL_BOUNDARY"
             (or (hyperdoc::bibliography-standin-last-protocol-boundary-of report) ""))
  (emit-line "FAILURE_CLASSIFICATION_BEFORE_BROWSER"
             (or (hyperdoc::bibliography-standin-failure-classification-before-browser-of
                  report)
                 ""))
  (emit-line "IMPORTED_ENTRY_COUNT"
             (hyperdoc::bibliography-standin-imported-entry-count-of report))
  (emit-line "CANDIDATE_COUNT"
             (hyperdoc::bibliography-standin-candidate-count-of report))
  (emit-line "DECISION_COUNT"
             (hyperdoc::bibliography-standin-decision-count-of report))
  (emit-line "MATERIALIZATION_ENTRY_COUNT"
             (hyperdoc::bibliography-standin-materialization-entry-count-of report))
  (emit-line "MATERIALIZATION_MS"
             (or (hyperdoc::bibliography-standin-materialization-ms-of report) ""))
  (emit-line "ARTIFACT_BUNDLE_READY"
             (truth-string
              (hyperdoc::bibliography-standin-artifact-bundle-ready-p report)))
  (emit-line "EXECUTION_REPORT_COUNT"
             (hyperdoc::bibliography-standin-execution-report-count-of report))
  (emit-line "PLAN_SUMMARY_PATH"
             (or (hyperdoc::pathname-namestring-or-nil
                  (hyperdoc::bibliography-standin-plan-summary-path-of report))
                 "")))
