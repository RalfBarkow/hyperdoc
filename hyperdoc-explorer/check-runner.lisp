;;;; Views for the HyperDoc checks runner
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun check-status-label (status)
  (ecase status
    (:passed "passed")
    (:failed "failed")
    (:error "error")
    (:skipped "skipped")
    (:pending "pending")))

(defun check-kind-label (kind)
  (ecase kind
    (:example "example")
    (:test "test")))

(defun check-summary-value (run key)
  (getf (check-run-status-summary-of run) key 0))

(defun check-runner-for-hyperdoc (hd)
  (make-discovered-check-run :system (asdf-system-name-of hd)))

(defmethod views:text-representation ((spec check-spec))
  (format nil "~A" (check-title-of spec)))

(defmethod views:text-representation ((result check-result))
  (format nil "[~A] ~A"
          (string-upcase (check-status-label (check-result-status-of result)))
          (check-title-of (check-result-spec-of result))))

(defmethod views:text-representation ((run check-run))
  (let ((summary (check-run-status-summary-of run)))
    (format nil "Checks (~D passed, ~D failed, ~D errored)"
            (getf summary :passed 0)
            (getf summary :failed 0)
            (getf summary :error 0))))

(defmethod views:title-bar-action-buttons ((run check-run))
  (views:html
    (views:action-button "Run all"
                         (views:thunk
                           (run-check-run! run)
                           t)
                         "Run all discovered checks")
    " "
    (views:action-button "Rerun failed"
                         (views:thunk
                           (rerun-failed-checks! run)
                           t)
                         "Rerun failed, errored, or skipped checks")))

(defmethod views:title-bar-action-buttons ((result check-result))
  (views:action-button "Rerun"
                       (views:thunk
                         (refresh-check-result! result)
                         t)
                       "Rerun this check"))

(views:defview 👀summary (spec check-spec)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (check-title-of spec)))
      (:p
       (views:eval-button "Run check"
                          (views:thunk (run-check spec))
                          "Run this one check and inspect the result"))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Kind"))
                   (:td (:tt (views:esc (check-kind-label (check-kind-of spec))))))
              (:tr (:td (views:esc "Identifier"))
                   (:td (:code (views:esc (check-id-of spec)))))
              (:tr (:td (views:esc "Locator"))
                   (:td (views:object-ref (check-locator-of spec))))
              (:tr (:td (views:esc "Tags"))
                   (:td (views:object-ref (check-tags-of spec))))))))

(views:defview 👀summary (result check-result)
  (let ((spec (check-result-spec-of result)))
    (views:html-view :title "Summary" :priority 1
      (views:html
        (:h3 (views:esc (check-title-of spec)))
        (:p
         (:b (views:esc "Status: "))
         (:tt (views:esc (check-status-label (check-result-status-of result)))))
        (:p
         (views:eval-button "Rerun"
                            (views:thunk
                              (refresh-check-result! result))
                            "Rerun this check in place"))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Identifier"))
                     (:td (:code (views:esc (check-id-of spec)))))
                (:tr (:td (views:esc "Kind"))
                     (:td (:tt (views:esc (check-kind-label (check-kind-of spec))))))
                (:tr (:td (views:esc "Duration"))
                     (:td (:tt (views:esc (format nil "~D ms"
                                                  (check-result-duration-ms-of result))))))
                (:tr (:td (views:esc "Assertions"))
                     (:td (views:object-ref (check-result-assertions-of result))))
                (:tr (:td (views:esc "Value"))
                     (:td (views:object-ref (check-result-value-of result))))
                (:tr (:td (views:esc "Condition"))
                     (:td (views:object-ref (check-result-condition-of result)))))
        (when (check-result-backtrace-of result)
          (views:html
            (:h4 "Backtrace")
            (:pre :style "white-space: pre-wrap"
                  (views:esc (check-result-backtrace-of result)))))))))

(views:defview 👀checks (run check-run)
  (views:html-view :title "Checks" :priority 3
    (if (check-run-specs-of run)
        (views:html
          (:table :class "inspector-table"
                  (:tr (:th (views:esc "Check"))
                       (:th (views:esc "Kind"))
                       (:th (views:esc "Identifier")))
                  (loop for spec in (check-run-specs-of run)
                        do (views:html
                             (:tr (:td (views:object-ref spec))
                                  (:td (:tt (views:esc (check-kind-label (check-kind-of spec)))))
                                  (:td (:code (views:esc (check-id-of spec)))))))))
        (views:html (:p "No checks discovered.")))))

(views:defview 👀failures (run check-run)
  (let ((failures (failed-check-results run)))
    (views:html-view :title "Failures" :priority 2
      (if failures
          (views:html
            (:p
             (views:action-button "Rerun failed"
                                  (views:thunk
                                    (rerun-failed-checks! run)
                                    t)
                                  "Rerun failed, errored, or skipped checks"))
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Status"))
                         (:th (views:esc "Check"))
                         (:th (views:esc "Condition")))
                    (loop for result in failures
                          do (views:html
                               (:tr (:td (:tt (views:esc (check-status-label
                                                          (check-result-status-of result)))))
                                    (:td (views:object-ref result))
                                    (:td (views:object-ref (check-result-condition-of result))))))))
          (views:html (:p "No failed, errored, or skipped checks."))))))

(views:defview 👀summary (run check-run)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 "Checks run")
      (:p
       (views:action-button "Run all"
                            (views:thunk
                              (run-check-run! run)
                              t)
                            "Run all discovered checks")
       " "
       (views:action-button "Rerun failed"
                            (views:thunk
                              (rerun-failed-checks! run)
                              t)
                            "Rerun failed, errored, or skipped checks"))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Total"))
                   (:td (:tt (views:esc (check-summary-value run :total)))))
              (:tr (:td (views:esc "Passed"))
                   (:td (:tt (views:esc (check-summary-value run :passed)))))
              (:tr (:td (views:esc "Failed"))
                   (:td (:tt (views:esc (check-summary-value run :failed)))))
              (:tr (:td (views:esc "Errored"))
                   (:td (:tt (views:esc (check-summary-value run :error)))))
              (:tr (:td (views:esc "Skipped"))
                   (:td (:tt (views:esc (check-summary-value run :skipped)))))
              (:tr (:td (views:esc "Pending"))
                   (:td (:tt (views:esc (check-summary-value run :pending)))))
              (:tr (:td (views:esc "Duration"))
                   (:td (:tt (views:esc (format nil "~:[n/a~;~:*~D ms~]"
                                                (check-run-duration-ms run)))))))
      (if (check-run-results-of run)
          (views:html
            (:h4 "Results")
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Status"))
                         (:th (views:esc "Check"))
                         (:th (views:esc "Duration")))
                    (loop for result in (check-run-results-of run)
                          do (views:html
                               (:tr (:td (:tt (views:esc (check-status-label
                                                          (check-result-status-of result)))))
                                    (:td (views:object-ref result))
                                    (:td (:tt (views:esc (format nil "~D ms"
                                                                 (check-result-duration-ms-of result))))))))))
          (views:html (:p "Checks have been discovered but not run yet."))))))

(views:defview 👀checks (hd hyperdoc)
  (let ((run (check-runner-for-hyperdoc hd)))
    (views:html-view :title "Checks" :priority 8
      (views:html
        (:h3 "Examples & tests")
        (:p "Discover repo-local examples and smoke tests as inspectable runtime objects.")
        (:p
         (views:eval-button "Inspect discovered checks"
                            (views:thunk run)
                            "Open the discovered checks as an inspectable run object")
         " "
         (views:eval-button "Run all checks"
                            (views:thunk
                              (run-check-run! run)
                              run)
                            "Run all discovered checks and inspect the results"))
        (:p
         (:b (views:esc "Discovered: "))
         (:tt (views:esc (check-summary-value run :total))))))))
