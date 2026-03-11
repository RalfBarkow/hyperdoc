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

(defun check-action-label (spec)
  (ecase (check-kind-of spec)
    (:example "Run example")
    (:test "Run test")))

(defun check-summary-value (run key)
  (getf (check-run-status-summary-of run) key 0))

(defun count-string (value)
  (format nil "~D" value))

(defun examples-concept-target ()
  (or (ignore-errors
        (when (fboundp 'scoped-examples-topic)
          (let ((topic (scoped-examples-topic)))
            (or (ignore-errors
                  (find-page *topics* (title-of topic) :signal-error? t))
                topic))))
      (ignore-errors
        (find-page *hyperdoc* "Running HyperDoc Examples" :signal-error? t))))

(defun render-examples-concept-ref (&key (display "Examples"))
  (let ((target (examples-concept-target)))
    (cond
      ((typep target 'hb:page)
       (hb:render-hyperbook-or-page-link (id-of (hyperbook-of target))
                                         (id-of target)
                                         display))
      (target
       (views:object-ref target :display display))
      (t
       (views:html (views:esc display))))))

(defun include-hyperbook-link-assets ()
  (views:add-asset-path "/hyperbook/"
                        (asdf:system-relative-pathname
                         :hyperbook
                         "assets/hyperbook/"))
  (views:include-css "/hyperbook/css/hyperbook.css"))

(defun asdf-system-name-string (system-designator)
  (etypecase system-designator
    (asdf:system
     (asdf:component-name system-designator))
    (string
     system-designator)
    (symbol
     (string-downcase (symbol-name system-designator)))))

(defun examples-runner-for-system (system-designator)
  (make-discovered-check-run :system (asdf-system-name-string system-designator)
                             :include-examples t
                             :include-tests nil))

(defun validation-runner-for-system (system-designator)
  (make-discovered-check-run :system (asdf-system-name-string system-designator)
                             :include-examples nil
                             :include-tests t))

(defun discovered-example-checks-for-system (system)
  (discover-example-checks :system (asdf-system-name-string system)))

(defun discovered-validation-checks-for-system (system)
  (discover-test-checks :system (asdf-system-name-string system)))

(defun check-locator-page (spec)
  (getf (check-locator-of spec) :page))

(defun check-locator-package (spec)
  (getf (check-locator-of spec) :package))

(defun resolve-check-source-target (check)
  (typecase check
    (check-result
     (resolve-check-source-target (check-result-spec-of check)))
    (check-spec
     (or (ignore-errors
           (resolve-check-function check))
         (getf (check-locator-of check) :source-file)))
    (t nil)))

(defun check-source-target-label (target)
  (typecase target
    (function "Function")
    (pathname "Source file")
    (t "Source")))

(defun check-source-view (check)
  (let ((target (resolve-check-source-target check)))
    (typecase target
      (function
       (-> target
           views:👀source
           (views:rename :title "Source" :priority 2)))
      (pathname
       (let ((view (views:👀content target)))
         (if view
             (views:rename view :title "Source" :priority 2)
             (views:html-view :title "Source" :priority 2
               (views:html
                 (:p "Source file is available but has no content view.")
                 (:p (views:object-ref target)))))))
      (t
       (views:html-view :title "Source" :priority 2
         (views:html
           (:p "No source target could be resolved for this check.")))))))

(defun render-example-spec-table (specs)
  (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Example"))
                 (:th (views:esc "Page"))
                 (:th (views:esc "Package"))
                 (:th (views:esc "Run")))
            (loop for spec in specs
                  do (views:html
                       (:tr
                        (:td (views:object-ref spec))
                        (:td (:tt (views:esc (or (check-locator-page spec) "n/a"))))
                        (:td (:tt (views:esc (or (check-locator-package spec) "n/a"))))
                        (:td (views:eval-button
                              "Run"
                              (views:thunk (run-check spec))
                              "Run this example and inspect the result"))))))))

(defun render-validation-spec-table (specs)
  (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Test"))
                 (:th (views:esc "Kind"))
                 (:th (views:esc "Identifier"))
                 (:th (views:esc "Run")))
            (loop for spec in specs
                  do (views:html
                       (:tr
                        (:td (views:object-ref spec))
                        (:td (:tt (views:esc (check-kind-label (check-kind-of spec)))))
                        (:td (:code (views:esc (check-id-of spec))))
                        (:td (views:eval-button
                              "Run"
                              (views:thunk (run-check spec))
                              "Run this test and inspect the result"))))))))

(defmethod views:text-representation ((spec check-spec))
  (format nil "~A" (check-title-of spec)))

(defmethod views:text-representation ((result check-result))
  (format nil "[~A] ~A"
          (string-upcase (check-status-label (check-result-status-of result)))
          (check-title-of (check-result-spec-of result))))

(defmethod views:text-representation ((run check-run))
  (let ((summary (check-run-status-summary-of run)))
    (format nil "Run (~D passed, ~D failed, ~D errored)"
            (getf summary :passed 0)
            (getf summary :failed 0)
            (getf summary :error 0))))

(defmethod views:title-bar-action-buttons ((run check-run))
  (views:html
    (views:action-button "Run all"
                         (views:thunk
                           (run-check-run! run)
                           t)
                         "Run all discovered tests and examples")
    " "
    (views:action-button "Rerun failed"
                         (views:thunk
                           (rerun-failed-checks! run)
                           t)
                         "Rerun failed, errored, or skipped tests and examples")))

(defmethod views:title-bar-action-buttons ((result check-result))
  (views:action-button "Rerun"
                       (views:thunk
                         (refresh-check-result! result)
                         t)
                       "Rerun this item"))

(views:defview 👀summary (spec check-spec)
  (let ((source-target (resolve-check-source-target spec)))
    (views:html-view :title "Summary" :priority 1
      (views:html
        (:h3 (views:esc (check-title-of spec)))
        (:p
         (views:eval-button (check-action-label spec)
                            (views:thunk (run-check spec))
                            "Run this item and inspect the result"))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Kind"))
                     (:td (:tt (views:esc (check-kind-label (check-kind-of spec))))))
                (:tr (:td (views:esc "Identifier"))
                     (:td (:code (views:esc (check-id-of spec)))))
                (when source-target
                  (views:html
                    (:tr (:td (views:esc (check-source-target-label source-target)))
                         (:td (views:object-ref source-target)))))
                (:tr (:td (views:esc "Locator"))
                     (:td (views:object-ref (check-locator-of spec))))
                (:tr (:td (views:esc "Tags"))
                     (:td (views:object-ref (check-tags-of spec)))))))))

(views:defview 👀source (spec check-spec)
  (check-source-view spec))

(views:defview 👀summary (result check-result)
  (let* ((spec (check-result-spec-of result))
         (source-target (resolve-check-source-target result)))
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
                            "Rerun this item in place"))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Identifier"))
                     (:td (:code (views:esc (check-id-of spec)))))
                (:tr (:td (views:esc "Kind"))
                     (:td (:tt (views:esc (check-kind-label (check-kind-of spec))))))
                (when source-target
                  (views:html
                    (:tr (:td (views:esc (check-source-target-label source-target)))
                         (:td (views:object-ref source-target)))))
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

(views:defview 👀source (result check-result)
  (check-source-view result))

(views:defview 👀checks (run check-run)
  (views:html-view :title "Tests & examples" :priority 3
    (if (check-run-specs-of run)
        (views:html
          (:table :class "inspector-table"
                  (:tr (:th (views:esc "Item"))
                       (:th (views:esc "Kind"))
                       (:th (views:esc "Identifier")))
                  (loop for spec in (check-run-specs-of run)
                        do (views:html
                             (:tr (:td (views:object-ref spec))
                                  (:td (:tt (views:esc (check-kind-label (check-kind-of spec)))))
                                  (:td (:code (views:esc (check-id-of spec)))))))))
        (views:html (:p "No tests or examples discovered.")))))

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
                                  "Rerun failed, errored, or skipped tests and examples"))
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Status"))
                         (:th (views:esc "Item"))
                         (:th (views:esc "Condition")))
                    (loop for result in failures
                          do (views:html
                               (:tr (:td (:tt (views:esc (check-status-label
                                                          (check-result-status-of result)))))
                                    (:td (views:object-ref result))
                                    (:td (views:object-ref (check-result-condition-of result))))))))
          (views:html (:p "No failed, errored, or skipped tests or examples."))))))

(views:defview 👀summary (run check-run)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 "Run summary")
      (:p
       (views:action-button "Run all"
                            (views:thunk
                              (run-check-run! run)
                              t)
                            "Run all discovered tests and examples")
       " "
       (views:action-button "Rerun failed"
                            (views:thunk
                              (rerun-failed-checks! run)
                              t)
                            "Rerun failed, errored, or skipped tests and examples"))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Total"))
                   (:td (:tt (views:esc (count-string (check-summary-value run :total))))))
              (:tr (:td (views:esc "Passed"))
                   (:td (:tt (views:esc (count-string (check-summary-value run :passed))))))
              (:tr (:td (views:esc "Failed"))
                   (:td (:tt (views:esc (count-string (check-summary-value run :failed))))))
              (:tr (:td (views:esc "Errored"))
                   (:td (:tt (views:esc (count-string (check-summary-value run :error))))))
              (:tr (:td (views:esc "Skipped"))
                   (:td (:tt (views:esc (count-string (check-summary-value run :skipped))))))
              (:tr (:td (views:esc "Pending"))
                   (:td (:tt (views:esc (count-string (check-summary-value run :pending))))))
              (:tr (:td (views:esc "Duration"))
                   (:td (:tt (views:esc (format nil "~:[n/a~;~:*~D ms~]"
                                                (check-run-duration-ms run)))))))
      (if (check-run-results-of run)
          (views:html
            (:h4 "Results")
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Status"))
                         (:th (views:esc "Item"))
                         (:th (views:esc "Duration")))
                    (loop for result in (check-run-results-of run)
                          do (views:html
                               (:tr (:td (:tt (views:esc (check-status-label
                                                          (check-result-status-of result)))))
                                    (:td (views:object-ref result))
                                    (:td (:tt (views:esc (format nil "~D ms"
                                                                 (check-result-duration-ms-of result))))))))))
          (views:html (:p "Tests and examples have been discovered but not run yet."))))))

(views:defview 👀examples (system asdf:system)
  (let* ((specs (discovered-example-checks-for-system system))
         (run (examples-runner-for-system system)))
    (views:html-view :title "Examples" :priority 2
      (include-hyperbook-link-assets)
      (views:html
        (:h3 "Scoped examples")
        (:p
         (render-examples-concept-ref)
         " belong to this ASDF system and act as runnable explanatory slices of its behavior.")
        (:p
         (views:eval-button "Inspect example set"
                            (views:thunk run)
                            "Open the discovered examples as an inspectable run object")
         " "
         (views:eval-button "Run all examples"
                            (views:thunk
                              (run-check-run! run)
                              run)
                            "Run all discovered examples and inspect the results"))
        (:p
         (:b (views:esc "Discovered: "))
         (:tt (views:esc (count-string (check-summary-value run :total)))))
        (if specs
            (render-example-spec-table specs)
            (views:html
              (:p "No examples are currently registered for this system.")))))))

(views:defview 👀validation (system asdf:system)
  (let ((validation-systems (validation-subsystems-for-system system)))
    (when validation-systems
      (let* ((specs (discovered-validation-checks-for-system system))
             (run (validation-runner-for-system system)))
        (views:html-view :title "Tests" :priority 3
          (include-hyperbook-link-assets)
          (views:html
            (:h3 "Tests for this system")
            (:p
             "Tests are an operational surface for this system. They are related to "
             (render-examples-concept-ref)
             ", but separate from the HyperDoc root identity.")
            (:p
             (:b (views:esc "Test systems: "))
             (render-object-ref-list validation-systems))
            (:p
             (views:eval-button "Inspect test run"
                                (views:thunk run)
                                "Open the discovered tests as an inspectable run object")
             " "
             (views:eval-button "Run tests"
                                (views:thunk
                                  (run-check-run! run)
                                  run)
                                "Run all discovered tests and inspect the results"))
            (:p
             (:b (views:esc "Discovered: "))
             (:tt (views:esc (count-string (check-summary-value run :total)))))
            (if specs
                (render-validation-spec-table specs)
                (views:html
                  (:p "No tests are currently registered for this system.")))))))))

(views:defview 👀maintenance (hd hyperdoc)
  (let* ((system (asdf-system-of hd))
         (validation-systems (validation-subsystems-for-system system)))
    (views:html-view :title "Tests" :priority 5
      (include-hyperbook-link-assets)
      (views:html
        (:h3 "Tests")
        (:p
         (render-examples-concept-ref)
         " help you understand a system. Tests help you verify it. This root surface is a local pointer to test entry points for this HyperDoc.")
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Primary system"))
                     (:td (views:object-ref system)))
                (:tr (:td (views:esc "Test systems"))
                     (:td (render-object-ref-list
                           validation-systems
                           :empty "Open the system object for any scoped test entry points."))))
        (when validation-systems
          (let ((run (validation-runner-for-system system)))
            (views:html
              (:p
               (views:eval-button "Inspect test run"
                                  (views:thunk run)
                                  "Open the scoped test run object")
               " "
               (views:eval-button "Run tests"
                                  (views:thunk
                                    (run-check-run! run)
                                    run)
                                  "Run the scoped tests and inspect the results"))
              (:p
               (:b (views:esc "Discovered tests: "))
               (:tt (views:esc (count-string (check-summary-value run :total))))))))))))
