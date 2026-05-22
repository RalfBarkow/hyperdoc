;;;; Views for examples and legacy check-runner objects
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

(defun example-status-label (status)
  (ecase status
    (:success "success")
    (:failure "failure")
    (:error "error")
    (:skipped "skipped")
    (:not-executed "not executed")))

(defun example-summary-value (run key)
  (getf (example-run-summary-of run) key 0))

(defun render-example-summary-chip (text)
  (views:html
   (:span :class "hyperdoc-example-summary-chip"
          (views:esc text))
   " "))

(defun render-example-run-summary (run)
  (views:html
   (:p
    (render-example-summary-chip
     (format nil "~D example~:P"
             (example-summary-value run :total)))
    (render-example-summary-chip
     (format nil "~D executed"
             (example-summary-value run :executed)))
    (render-example-summary-chip
     (format nil "~D success~:P"
             (example-summary-value run :success)))
    (render-example-summary-chip
     (format nil "~D failure~:P"
             (example-summary-value run :failure)))
    (render-example-summary-chip
     (format nil "~D error~:P"
             (example-summary-value run :error)))
    (render-example-summary-chip
     (format nil "~D skipped"
             (example-summary-value run :skipped)))
    (render-example-summary-chip
     (format nil "~D not executed"
             (example-summary-value run :not-executed))))))

(defun render-example-execution-location ()
  (views:html
   (:p
    (:span :class "hyperdoc-example-local-active" (views:esc "Local active"))
    " "
    (:span :class "hyperdoc-example-remote-disabled"
           (views:esc "Remote unavailable")))))

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
  (make-example-run :system (asdf-system-name-string system-designator)))

(defun examples-runner-for-fedwiki-home (home)
  (let* ((loaded (load-fedwiki-attached-asdf-system home))
         (system-name (fedwiki-asdf-system-name-string
                       (fedwiki-attached-asdf-system-system-name home))))
    (if (typep loaded 'asdf:system)
        (values (examples-runner-for-system loaded) nil)
        (values (make-example-run :system system-name :entries nil)
                loaded))))

(defun validation-runner-for-system (system-designator)
  (make-discovered-check-run :system (asdf-system-name-string system-designator)
                             :include-examples nil
                             :include-tests t))

(defun discovered-examples-for-system (system)
  (discover-examples :system (asdf-system-name-string system)))

(defun discovered-validation-checks-for-system (system)
  (discover-test-checks :system (asdf-system-name-string system)))

(defun check-locator-page (spec)
  (getf (check-locator-of spec) :page))

(defun check-locator-package (spec)
  (getf (check-locator-of spec) :package))

(defun example-source-reference-for (example)
  (etypecase example
    (example-source-reference example)
    (example-result
     (make-example-source-reference (example-result-entry-of example)))
    (example-entry
     (make-example-source-reference example))))

(defun example-function-label (function-symbol)
  (if function-symbol
      (format nil "~(~A~)" function-symbol)
      "n/a"))

(defun example-source-pathname (reference)
  (when-let (source-file (example-source-reference-source-file-of reference))
    (let ((pathname (pathname source-file)))
      (or (ignore-errors (truename pathname))
          pathname))))

(defun example-source-status (reference)
  (example-source-reference-source-kind-of reference))

(defun example-source-status-label (status)
  (ecase status
    (:file "source file available")
    (:topic "topic source artifact")
    (:unavailable "source unavailable")))

(defun example-source-reference-status-label (reference)
  (case (example-source-status reference)
    (:unavailable
     (or (example-source-reference-diagnostic-of reference)
         (example-source-status-label :unavailable)))
    (otherwise
     (example-source-status-label (example-source-status reference)))))

(defun example-source-file-label (reference)
  (let ((pathname (example-source-pathname reference)))
    (if pathname
        (namestring pathname)
        (example-source-reference-status-label reference))))

(defun example-source-system-directory (reference)
  (let* ((entry (example-source-reference-entry-of reference))
         (system-name (example-entry-system-of entry)))
    (when system-name
      (ignore-errors
        (asdf:system-source-directory (asdf:find-system system-name))))))

(defun example-source-file-candidates (reference)
  (when-let (pathname (example-source-pathname reference))
    (let ((system-directory (example-source-system-directory reference))
          (hyperdoc-directory (ignore-errors
                                (asdf:system-source-directory :hyperdoc))))
      (remove nil
              (remove-duplicates
               (list (namestring pathname)
                     (and system-directory
                          (ignore-errors
                            (enough-namestring pathname system-directory)))
                     (and hyperdoc-directory
                          (ignore-errors
                            (enough-namestring pathname hyperdoc-directory))))
               :test #'string=)))))

(defun example-source-reference-source-target (reference)
  (case (example-source-status reference)
    (:file
     (or (loop for candidate in (example-source-file-candidates reference)
               for target = (ignore-errors
                              (source-pane-layout-source-target candidate))
               when (typep target 'code-page)
                 do (return target))
         (example-source-pathname reference)))
    (:topic
     (example-source-reference-source-artifact-of reference))
    (otherwise nil)))

(defun example-source-navigation-target (reference)
  (let ((target (example-source-reference-source-target reference))
        (function-symbol (example-source-reference-function-of reference)))
    (if (and function-symbol
             (typep target 'code-page))
        (make-code-page-source-navigation target function-symbol)
        target)))

(defun example-source-reference-default-view-title (reference)
  (case (example-source-status reference)
    (:topic "Source code")
    (otherwise "Source")))

(defun example-source-reference-navigation-object (reference)
  (case (example-source-status reference)
    (:topic (or (example-source-reference-source-artifact-of reference)
                reference))
    (otherwise reference)))

(defun render-example-source-reference (reference &key (display "Source"))
  (views:object-ref (example-source-reference-navigation-object reference)
                    :display display
                    :select (example-source-reference-default-view-title
                             reference)))

(defun render-example-source-unavailable (reference)
  (views:html
   (:h3 "Source unavailable")
   (:p
    (views:esc
     (example-source-reference-status-label reference)))
   (:p
    "The example result is inspectable, but this entry does not carry a "
    "file-backed or persisted topic source artifact. This is expected for "
    "examples defined directly in SLY MREPL without supplied source text.")
   (:table :class "inspector-table"
           (:tr (:td (views:esc "Function"))
                (:td (:tt (views:esc
                           (example-function-label
                            (example-source-reference-function-of
                             reference))))))
           (:tr (:td (views:esc "Locator"))
                (:td (views:object-ref
                      (example-source-reference-locator-of reference)))))))

(defun render-example-source-artifact-source-only (artifact)
  (views:html
   (:pre :class "lisp-source-code-file hyperdoc-example-source-code"
         (views:esc
          (or (example-source-artifact-source-text-of artifact)
              "")))))

(defun render-example-source-artifact-meta (artifact)
  (views:html
   (:h3 (views:esc (title-of artifact)))
   (:table :class "inspector-table"
           (:tr (:td (views:esc "Source id"))
                (:td (:code (views:esc
                             (example-source-artifact-source-id-of
                              artifact)))))
           (:tr (:td (views:esc "Topic id"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-topic-id-of artifact)
                               "n/a")))))
           (:tr (:td (views:esc "Topic slug"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-topic-slug-of
                                artifact)
                               "n/a")))))
           (:tr (:td (views:esc "Topic title"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-topic-title-of
                                artifact)
                               "n/a")))))
           (:tr (:td (views:esc "ASDF system"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-asdf-system-name-of
                                artifact)
                               "n/a")))))
           (:tr (:td (views:esc "FedWiki page"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-fedwiki-page-identity-of
                                artifact)
                               "n/a")))))
           (:tr (:td (views:esc "Function"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-function-symbol-of
                                artifact)
                               "n/a")))))
           (:tr (:td (views:esc "Locator"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-locator-of artifact)
                               "n/a")))))
           (:tr (:td (views:esc "Language"))
                (:td (:tt (views:esc
                           (format nil "~(~A~)"
                                   (example-source-artifact-source-language-of
                                    artifact))))))
           (:tr (:td (views:esc "Form kind"))
                (:td (:tt (views:esc
                           (format nil "~(~A~)"
                                   (example-source-artifact-source-form-kind-of
                                    artifact))))))
           (:tr (:td (views:esc "Provenance"))
                (:td (:tt (views:esc
                           (format nil "~(~A~)"
                                   (example-source-artifact-provenance-of
                                    artifact))))))
           (:tr (:td (views:esc "Created"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-created-at-of artifact)
                               "n/a")))))
           (:tr (:td (views:esc "Updated"))
                (:td (:tt (views:esc
                           (or (example-source-artifact-updated-at-of artifact)
                               "n/a")))))
           (:tr (:td (views:esc "Store/backend"))
                (:td (:tt (views:esc
                           (typecase (current-example-source-store)
                             (example-source-sqlite-store
                              "SQLite-compatible example source artifact store")
                             (t "example source artifact store"))))))
           (:tr (:td (views:esc "Store path"))
                (:td (:tt (views:esc
                           (typecase (current-example-source-store)
                             (example-source-sqlite-store
                              (namestring
                               (example-source-sqlite-store-db-path-of
                                (current-example-source-store))))
                             (t "n/a"))))))
           (:tr (:td (views:esc "LISP-CRITIC"))
                (:td (:tt (views:esc "review protocol placeholder")))))))

(defun example-source-view (example)
  (let* ((reference (example-source-reference-for example))
         (status (example-source-status reference))
         (target (example-source-navigation-target reference)))
    (case status
      (:file
       (typecase target
         ((or code-page code-page-source-navigation source-pane-file-target)
          (let ((view (views:👀source target)))
            (if view
                (views:rename view :title "Source" :priority 2)
                (views:html-view :title "Source" :priority 2
                                 (views:html
                                  (:p "Source target has no Source view.")
                                  (:p (views:object-ref target)))))))
         (pathname
          (views:html-view :title "Source" :priority 2
                           (hb:render-file-source-surface target)))
         (t
          (views:html-view :title "Source" :priority 2
                           (views:html
                            (:p "Source file is available but no source view could be resolved.")
                            (:p (:tt (views:esc
                                      (example-source-file-label
                                       reference)))))))))
      (:topic
       (if target
           (let ((view (views:👀source target)))
             (if view
                 view
                 (views:html-view
                  :title "Source code" :priority 0
                  (render-example-source-artifact-source-only target))))
           (views:html-view :title "Source" :priority 2
                            (render-example-source-unavailable reference))))
      (otherwise
       (views:html-view :title "Source" :priority 2
                        (render-example-source-unavailable reference))))))

(defun example-result-for-entry (entry results)
  (find (example-entry-id-of entry)
        results
        :key (lambda (result)
               (example-entry-id-of (example-result-entry-of result)))
        :test #'equal))

(defun render-example-entry-table (run)
  (let ((results (example-run-results-of run)))
    (views:html
     (:table :class "inspector-table"
             (:tr (:th (views:esc "Status"))
                  (:th (views:esc "Class / Package / Group"))
                  (:th (views:esc "Selector / Example"))
                  (:th (views:esc "Result"))
                  (:th (views:esc "Actions")))
             (loop for entry in (example-run-entries-of run)
                   for result = (example-result-for-entry entry results)
                   for source-reference = (example-source-reference-for entry)
                   do (views:html
                       (:tr
                        (:td (:tt (views:esc
                                   (if result
                                       (example-status-label
                                        (example-result-status-of result))
                                       (example-status-label
                                        :not-executed)))))
                        (:td (:tt (views:esc
                                   (or (example-entry-class-or-group-of entry)
                                       (example-entry-package-of entry)
                                       "n/a"))))
                        (:td (views:object-ref entry))
                        (:td (if result
                                 (views:object-ref result)
                                 (views:html (:tt (views:esc "N/A")))))
                        (:td
                         (views:eval-button
                          "Run"
                          (views:thunk (run-example-entry entry))
                          "Run this example and inspect the result")
                         " "
                         (render-example-source-reference source-reference)
                         (when result
                           (views:html
                            " "
                            (views:eval-button
                             "Result"
                             (views:thunk result)
                             "Inspect this example result")))))))))))

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

(defmethod views:text-representation ((entry example-entry))
  (example-entry-title-of entry))

(defmethod views:text-representation ((result example-result))
  (format nil "[~A] ~A"
          (string-upcase
           (example-status-label (example-result-status-of result)))
          (example-entry-title-of (example-result-entry-of result))))

(defmethod views:text-representation ((reference example-source-reference))
  (format nil "Source for ~A"
          (example-entry-title-of
           (example-source-reference-entry-of reference))))

(defmethod views:text-representation ((artifact example-source-artifact))
  (format nil "Source artifact ~A"
          (example-source-artifact-source-id-of artifact)))

(defmethod views:text-representation ((trace inspector-path-trace))
  (format nil "Inspector path trace ~A"
          (inspector-path-trace-path-name-of trace)))

(defmethod views:text-representation ((comparison inspector-path-comparison))
  (format nil "Inspector path comparison ~:[diverged~;equivalent~]"
          (inspector-path-comparison-equivalent-p-of comparison)))

(defmethod views:text-representation ((run example-run))
  (let ((summary (example-run-summary-of run)))
    (format nil "Examples (~D success, ~D failure, ~D error)"
            (getf summary :success 0)
            (getf summary :failure 0)
            (getf summary :error 0))))

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

(defmethod views:title-bar-action-buttons ((run example-run))
  (views:action-button "Run Examples"
                       (views:thunk
                        (run-example-run! run)
                        t)
                       "Run examples for this system scope"))

(defmethod views:title-bar-action-buttons ((result check-result))
  (views:action-button "Rerun"
                       (views:thunk
                        (refresh-check-result! result)
                        t)
                       "Rerun this item"))

(defmethod views:title-bar-action-buttons ((result example-result))
  (views:action-button "Run"
                       (views:thunk
                        (run-example-entry (example-result-entry-of result))
                        t)
                       "Run this example again"))

(views:defview 👀summary (reference example-source-reference)
  (let* ((entry (example-source-reference-entry-of reference))
         (target (example-source-navigation-target reference)))
    (views:html-view :title "Summary" :priority 1
                     (views:html
                      (:h3 "Example source")
                      (:table :class "inspector-table"
                              (:tr (:td (views:esc "Example entry"))
                                   (:td (views:object-ref entry)))
                              (:tr (:td (views:esc "Function"))
                                   (:td (:tt (views:esc
                                              (example-function-label
                                               (example-source-reference-function-of
                                                reference))))))
                              (:tr (:td (views:esc "Source"))
                                   (:td (render-example-source-reference
                                         reference
                                         :display
                                         (example-source-reference-status-label
                                          reference))))
                              (:tr (:td (views:esc "Source file"))
                                   (:td (:tt (views:esc
                                              (example-source-file-label
                                               reference)))))
                              (:tr (:td (views:esc "Source page"))
                                   (:td (:tt (views:esc
                                              (or (example-source-reference-source-page-of
                                                   reference)
                                                  "n/a")))))
                              (:tr (:td (views:esc "Source artifact"))
                                   (:td (if (example-source-reference-source-artifact-of
                                            reference)
                                            (views:object-ref
                                             (example-source-reference-source-artifact-of
                                              reference))
                                            (views:html
                                             (:tt (views:esc "n/a"))))))
                              (:tr (:td (views:esc "Locator"))
                                   (:td (views:object-ref
                                         (example-source-reference-locator-of
                                          reference))))
                              (:tr (:td (views:esc "Resolved target"))
                                   (:td (if target
                                            (views:object-ref target)
                                            (views:html
                                             (:tt (views:esc "n/a")))))))))))

(views:defview views:👀source (reference example-source-reference)
  (example-source-view reference))

(views:defview 👀summary (artifact example-source-artifact)
  (views:html-view :title "Meta" :priority 1
                   (render-example-source-artifact-meta artifact)))

;; Suppress the package-local legacy source view for artifacts. The exported
;; html-inspector-views source generic below owns the single Source code tab.
(views:defview 👀source (artifact example-source-artifact)
  nil)

(views:defview views:👀source (artifact example-source-artifact)
  (views:html-view :title "Source code" :priority 0
                   (render-example-source-artifact-source-only artifact)))

(defun render-inspector-path-value (value)
  (cond
    ((null value) (views:html (:tt (views:esc "n/a"))))
    ((listp value)
     (views:html (:pre :style "white-space: pre-wrap"
                       (views:esc
                        (with-output-to-string (stream)
                          (let ((*print-pretty* t)
                                (*print-circle* t))
                            (prin1 value stream)))))))
    (t (views:html (:tt (views:esc (format nil "~A" value)))))))

(defun render-inspector-path-step-row (step)
  (views:html
   (:tr
    (:td (:tt (views:esc
               (format nil "~D" (inspector-path-step-index-of step)))))
    (:td (:tt (views:esc (inspector-path-step-path-name-of step))))
    (:td (:tt (views:esc (inspector-path-step-phase-of step))))
    (:td (render-inspector-path-value
          (inspector-path-step-action-of step)))
    (:td (render-inspector-path-value
          (or (inspector-path-step-dom-labels-of step)
              (inspector-path-step-view-titles-of step))))
    (:td (render-inspector-path-value
          (inspector-path-step-result-of step))))))

(defun render-inspector-path-steps-table (steps)
  (views:html
   (:table :class "inspector-table"
           (:tr (:th (views:esc "#"))
                (:th (views:esc "Path"))
                (:th (views:esc "Phase"))
                (:th (views:esc "Action"))
                (:th (views:esc "Views / DOM labels"))
                (:th (views:esc "Result")))
           (loop for step in steps
                 do (render-inspector-path-step-row step)))))

(defun render-inspector-path-topic-table (topics)
  (views:html
   (:table :class "inspector-table"
           (:tr (:th (views:esc "Topic id"))
                (:th (views:esc "Type"))
                (:th (views:esc "Title")))
           (loop for topic in topics
                 do (views:html
                     (:tr
                      (:td (:code (views:esc (path-topic-id-of topic))))
                      (:td (:tt (views:esc (path-topic-type-of topic))))
                      (:td (views:esc (path-topic-title-of topic)))))))))

(defun render-inspector-path-association-table (associations)
  (views:html
   (:table :class "inspector-table"
           (:tr (:th (views:esc "Association id"))
                (:th (views:esc "Type"))
                (:th (views:esc "From"))
                (:th (views:esc "To")))
           (loop for association in associations
                 do (views:html
                     (:tr
                      (:td (:code (views:esc
                                   (path-association-id-of association))))
                      (:td (:tt (views:esc
                                 (path-association-type-of association))))
                      (:td (:code (views:esc
                                   (path-association-from-topic-id-of
                                    association))))
                      (:td (:code (views:esc
                                   (path-association-to-topic-id-of
                                    association))))))))))

(defun inspector-path-scxml-steps (trace)
  (remove-if-not #'inspector-path-step-scxml-record-of
                 (inspector-path-trace-steps-of trace)))

(defun inspector-path-dom-steps (trace)
  (remove-if-not
   (lambda (step)
     (or (inspector-path-step-dom-labels-of step)
         (inspector-path-step-view-titles-of step)))
   (inspector-path-trace-steps-of trace)))

(views:defview 👀overview (trace inspector-path-trace)
  (views:html-view
   :title "Overview"
   :priority 0
   (views:html
    (:h3 (views:esc (title-of trace)))
    (:table :class "inspector-table"
            (:tr (:td (views:esc "Path"))
                 (:td (:tt (views:esc
                            (inspector-path-trace-path-name-of trace)))))
            (:tr (:td (views:esc "Object type"))
                 (:td (:tt (views:esc
                            (inspector-path-trace-object-type-of trace)))))
            (:tr (:td (views:esc "Object identity"))
                 (:td (:tt (views:esc
                            (inspector-path-trace-object-identity-of
                             trace)))))
            (:tr (:td (views:esc "Entry function"))
                 (:td (:tt (views:esc
                            (or (inspector-path-trace-entry-function-of trace)
                                "n/a")))))
            (:tr (:td (views:esc "Result"))
                 (:td (:tt (views:esc
                            (format nil "~A"
                                    (inspector-path-trace-result-of
                                     trace))))))
            (:tr (:td (views:esc "SQLite store"))
                 (:td (:tt (views:esc
                            (typecase (inspector-path-trace-store-of trace)
                              (inspector-path-sqlite-store
                               (namestring
                                (inspector-path-sqlite-store-db-path-of
                                 (inspector-path-trace-store-of trace))))
                              (t "n/a"))))))))))

(views:defview 👀steps (trace inspector-path-trace)
  (views:html-view
   :title "Steps"
   :priority 1
   (render-inspector-path-steps-table
    (inspector-path-trace-steps-of trace))))

(views:defview 👀associations (trace inspector-path-trace)
  (views:html-view
   :title "Associations"
   :priority 2
   (render-inspector-path-association-table
    (inspector-path-trace-associations-of trace))))

(views:defview 👀scxml (trace inspector-path-trace)
  (views:html-view
   :title "SCXML"
   :priority 3
   (let ((steps (inspector-path-scxml-steps trace)))
     (if steps
         (render-inspector-path-steps-table steps)
         (views:html (:p "No SCXML events were recorded for this trace."))))))

(views:defview 👀dom (trace inspector-path-trace)
  (views:html-view
   :title "DOM evidence"
   :priority 4
   (let ((steps (inspector-path-dom-steps trace)))
     (if steps
         (render-inspector-path-steps-table steps)
         (views:html (:p "No DOM or final label evidence was recorded."))))))

(views:defview 👀raw (trace inspector-path-trace)
  (views:html-view
   :title "Raw topic graph"
   :priority 5
   (views:html
    (:h4 "Topics")
    (render-inspector-path-topic-table
     (inspector-path-trace-topics-of trace))
    (:h4 "Associations")
    (render-inspector-path-association-table
     (inspector-path-trace-associations-of trace)))))

(views:defview 👀overview (comparison inspector-path-comparison)
  (views:html-view
   :title "Overview"
   :priority 0
   (let ((store (inspector-path-comparison-store-of comparison)))
     (views:html
      (:h3 "Inspector path comparison")
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Equivalent"))
                   (:td (:tt (views:esc
                              (if (inspector-path-comparison-equivalent-p-of
                                   comparison)
                                  "yes"
                                  "no")))))
              (:tr (:td (views:esc "First divergence"))
                   (:td (render-inspector-path-value
                         (inspector-path-comparison-first-divergence-of
                          comparison))))
              (:tr (:td (views:esc "SQLite store"))
                   (:td (:tt (views:esc
                              (typecase store
                                (inspector-path-sqlite-store
                                 (namestring
                                  (inspector-path-sqlite-store-db-path-of
                                   store)))
                                (t "n/a")))))))))))

(views:defview 👀divergence (comparison inspector-path-comparison)
  (views:html-view
   :title "Divergence"
   :priority 1
   (let ((divergence
           (inspector-path-comparison-first-divergence-of comparison)))
     (if divergence
         (render-inspector-path-value divergence)
         (views:html (:p "No divergence recorded at the compared labels."))))))

(views:defview 👀steps (comparison inspector-path-comparison)
  (views:html-view
   :title "Steps"
   :priority 2
   (views:html
    (loop for trace in (inspector-path-comparison-traces-of comparison)
          do (views:html
              (:h4 (views:esc
                    (inspector-path-trace-path-name-of trace)))
              (render-inspector-path-steps-table
               (inspector-path-trace-steps-of trace)))))))

(views:defview 👀associations (comparison inspector-path-comparison)
  (views:html-view
   :title "Associations"
   :priority 3
   (views:html
    (loop for trace in (inspector-path-comparison-traces-of comparison)
          do (views:html
              (:h4 (views:esc
                    (inspector-path-trace-path-name-of trace)))
              (render-inspector-path-association-table
               (inspector-path-trace-associations-of trace)))))))

(views:defview 👀raw (comparison inspector-path-comparison)
  (views:html-view
   :title "Raw topic graph"
   :priority 4
   (views:html
    (:h4 "Comparison topics")
    (render-inspector-path-topic-table
     (inspector-path-comparison-topics-of comparison))
    (:h4 "Comparison associations")
    (render-inspector-path-association-table
     (inspector-path-comparison-associations-of comparison)))))

(views:defview 👀summary (entry example-entry)
  (let ((source-reference (example-source-reference-for entry)))
    (views:html-view :title "Summary" :priority 1
                     (views:html
                      (:h3 (views:esc (example-entry-title-of entry)))
                      (:p
                       (views:eval-button "Run"
                                          (views:thunk
                                           (run-example-entry entry))
                                          "Run this example and inspect the result"))
                      (:table :class "inspector-table"
                              (:tr (:td (views:esc "Identifier"))
                                   (:td (:code (views:esc
                                                (example-entry-id-of entry)))))
                              (:tr (:td (views:esc "System"))
                                   (:td (:tt (views:esc
                                              (or (example-entry-system-of entry)
                                                  "n/a")))))
                              (:tr (:td (views:esc "Package"))
                                   (:td (:tt (views:esc
                                              (or (example-entry-package-of entry)
                                                  "n/a")))))
                              (:tr (:td (views:esc "Function"))
                                   (:td (:tt (views:esc
                                              (example-function-label
                                               (example-entry-function-of
                                                entry))))))
                              (:tr (:td (views:esc "Source"))
                                   (:td (render-example-source-reference
                                         source-reference
                                         :display
                                         (example-source-reference-status-label
                                          source-reference))))
                              (:tr (:td (views:esc "Source file"))
                                   (:td (:tt (views:esc
                                              (example-source-file-label
                                               source-reference)))))
                              (:tr (:td (views:esc "Page"))
                                   (:td (:tt (views:esc
                                              (or (example-entry-source-page-of entry)
                                                  "n/a")))))
                              (:tr (:td (views:esc "Locator"))
                                   (:td (views:object-ref
                                         (example-entry-locator-of entry))))
                              (:tr (:td (views:esc "Tags"))
                                   (:td (views:object-ref
                                         (example-entry-tags-of entry)))))))))

(views:defview views:👀source (entry example-entry)
  (example-source-view entry))

(views:defview 👀summary (result example-result)
  (let* ((entry (example-result-entry-of result))
         (source-reference (example-source-reference-for result)))
    (views:html-view :title "Summary" :priority 1
                     (views:html
                      (:h3 (views:esc (example-entry-title-of entry)))
                      (:p
                       (:b (views:esc "Status: "))
                       (:tt (views:esc
                             (example-status-label
                              (example-result-status-of result)))))
                      (:p
                       (views:eval-button "Run"
                                          (views:thunk
                                           (run-example-entry entry))
                                          "Run this example again"))
                      (:table :class "inspector-table"
                              (:tr (:td (views:esc "Identifier"))
                                   (:td (:code (views:esc
                                                (example-entry-id-of entry)))))
                              (:tr (:td (views:esc "System"))
                                   (:td (:tt (views:esc
                                              (or (example-entry-system-of entry)
                                                  "n/a")))))
                              (:tr (:td (views:esc "Example entry"))
                                   (:td (views:object-ref entry)))
                              (:tr (:td (views:esc "Function"))
                                   (:td (:tt (views:esc
                                              (example-function-label
                                               (example-entry-function-of
                                                entry))))))
                              (:tr (:td (views:esc "Source"))
                                   (:td (render-example-source-reference
                                         source-reference
                                         :display
                                         (example-source-reference-status-label
                                          source-reference))))
                              (:tr (:td (views:esc "Source file"))
                                   (:td (:tt (views:esc
                                              (example-source-file-label
                                               source-reference)))))
                              (:tr (:td (views:esc "Locator"))
                                   (:td (views:object-ref
                                         (example-entry-locator-of entry))))
                              (:tr (:td (views:esc "Duration"))
                                   (:td (:tt (views:esc
                                              (format nil "~D ms"
                                                      (example-result-duration-ms-of
                                                       result))))))
                              (:tr (:td (views:esc "Assertions"))
                                   (:td (views:object-ref
                                         (example-result-assertions-of result))))
                              (:tr (:td (views:esc "Value"))
                                   (:td (views:object-ref
                                         (example-result-value-of result))))
                              (:tr (:td (views:esc "Condition"))
                                   (:td (views:object-ref
                                         (example-result-condition-of result)))))
                      (when (example-result-backtrace-of result)
                        (views:html
                         (:h4 "Backtrace")
                         (:pre :style "white-space: pre-wrap"
                               (views:esc
                                (example-result-backtrace-of result)))))))))

(views:defview views:👀source (result example-result)
  (example-source-view result))

(views:defview 👀summary (run example-run)
  (views:html-view :title "Summary" :priority 1
                   (views:html
                    (:h3 "Examples")
                    (:p
                     (views:action-button "Run Examples"
                                          (views:thunk
                                           (run-example-run! run)
                                           t)
                                          "Run examples for this system scope"))
                    (render-example-execution-location)
                    (render-example-run-summary run)
                    (if (example-run-entries-of run)
                        (render-example-entry-table run)
                        (views:html
                         (:p "No examples are currently registered for this system."))))))

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
  (let ((run (examples-runner-for-system system)))
    (views:html-view :title "Examples" :priority 2
                     (include-hyperbook-link-assets)
                     (views:html
                      (:h3 "Examples")
                      (:p
                       (render-examples-concept-ref)
                       " belong to this ASDF system and act as runnable explanatory slices of its behavior.")
                      (:p
                       (views:eval-button "Inspect Examples"
                                          (views:thunk run)
                                          "Open the examples as an inspectable run object")
                       " "
                       (views:eval-button "Run Examples"
                                          (views:thunk
                                           (run-example-run! run)
                                           run)
                                          "Run examples for this system scope and inspect the results"))
                      (render-example-execution-location)
                      (render-example-run-summary run)
                      (if (example-run-entries-of run)
                          (render-example-entry-table run)
                          (views:html
                           (:p "No examples are currently registered for this system.")))))))

(views:defview 👀examples (home fedwiki-attached-asdf-system)
  (multiple-value-bind (run load-failure)
      (examples-runner-for-fedwiki-home home)
    (views:html-view :title "Examples" :priority 2
                     (include-hyperbook-link-assets)
                     (views:html
                      (:h3 "Examples")
                      (:p
                       (render-examples-concept-ref)
                       " belong to the ASDF system attached to this FedWiki page home.")
                      (:p
                       (:b (views:esc "ASDF entrypoint: "))
                       (:tt (views:esc
                             (namestring (fedwiki-page-asdf-entrypoint home)))))
                      (when load-failure
                        (views:html
                         (:p
                          (:b (views:esc "Load state: "))
                          (views:object-ref load-failure))))
                      (:p
                       (views:eval-button "Inspect Examples"
                                          (views:thunk run)
                                          "Open the examples as an inspectable run object")
                       " "
                       (views:eval-button "Run Examples"
                                          (views:thunk
                                           (run-example-run! run)
                                           run)
                                          "Run examples for this system scope and inspect the results"))
                      (render-example-execution-location)
                      (render-example-run-summary run)
                      (if (example-run-entries-of run)
                          (render-example-entry-table run)
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
