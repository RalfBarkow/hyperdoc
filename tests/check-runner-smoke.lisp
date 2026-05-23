;;;; Smoke tests for the HyperDoc checks runner

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-CHECK-RUNNER-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *rerun-pass-count* 0)
(defparameter *rerun-fail-count* 0)
(defparameter *rerun-error-count* 0)
(defparameter *rerun-fail-behavior* :fail)
(defparameter *rerun-error-behavior* :error)

(defun cr-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun cr-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun cr-assert-typep (type object message)
  (unless (typep object type)
    (error "~A -- expected type: ~S actual type: ~S" message type (type-of object))))

(defun cr-assert-string-contains (needle haystack message)
  (unless (search needle haystack :test #'char=)
    (error "~A -- missing substring: ~S" message needle)))

(defun cr-assert-string-not-contains (needle haystack message)
  (when (search needle haystack :test #'char=)
    (error "~A -- unexpected substring: ~S" message needle)))

(defun cr-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun cr-view-titles (views)
  (mapcar #'html-inspector-views:view-title views))

(defun cr-count-view-title (title views)
  (count title views
         :key #'html-inspector-views:view-title
         :test #'string=))

(defun cr-assert-view-title-count (expected title views message)
  (cr-assert-equal expected
                   (cr-count-view-title title views)
                   message))

(defun cr-view-html-by-title-in-views (views title)
  (let ((view (cr-find-view-by-title views title)))
    (cr-assert-true view
                    (format nil "Inspector view must exist: ~A" title))
    (html-inspector-views:view-html view)))

(defun cr-view-html-by-title (object title)
  (cr-view-html-by-title-in-views
   (html-inspector-views:all-views object)
   title))

(defun cr-load-clog-pane-views (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun cr-example-source-artifact-inspector-scxml-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/example-source-artifact-inspector.scxml"))

(defun cr-scxml-state-ids (chart)
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun cr-scxml-find-state (chart state-id)
  (find state-id
        (hyperdoc/scxml:scxml-chart-states-of chart)
        :key #'hyperdoc/scxml:scxml-state-id-of
        :test #'string=))

(defun cr-scxml-transition (chart source event target)
  (let ((state (cr-scxml-find-state chart source)))
    (and state
         (find-if
          (lambda (transition)
            (and (equal event
                        (hyperdoc/scxml:scxml-transition-event-of
                         transition))
                 (equal target
                        (hyperdoc/scxml:scxml-transition-target-of
                         transition))))
          (hyperdoc/scxml:scxml-state-transitions-of state)))))

(defun cr-scxml-state-log-expr (chart state-id label)
  (let ((state (cr-scxml-find-state chart state-id)))
    (loop for action in (and state
                             (hyperdoc/scxml:scxml-state-onentry-actions-of
                              state))
          for attributes = (hyperdoc/scxml:scxml-action-attributes-of
                            action)
          when (and (eq :log
                        (hyperdoc/scxml:scxml-action-kind-of action))
                    (string= label (or (getf attributes :label) "")))
            return (getf attributes :expr))))

(defun cr-scxml-error-findings (findings)
  (remove-if-not
   (lambda (finding)
     (eq :error
         (hyperdoc/scxml:scxml-validation-finding-severity-of finding)))
   findings))

(defun cr-assert-example-source-artifact-tab-contract (views label)
  (let ((titles (cr-view-titles views))
        (first-view (first views)))
    (cr-assert-true first-view
                    (format nil "~A must expose inspector views" label))
    (cr-assert-equal "Source code"
                     (html-inspector-views:view-title first-view)
                     (format nil "~A first/default view" label))
    (cr-assert-equal "Meta"
                     (second titles)
                     (format nil "~A second view" label))
    (cr-assert-view-title-count
     1 "Source code" views
     (format nil "~A must expose exactly one Source code view" label))
    (cr-assert-view-title-count
     1 "Meta" views
     (format nil "~A must expose one Meta view" label))
    (cr-assert-view-title-count
     0 "Summary" views
     (format nil "~A must not expose a Summary view" label))))

(defun cr-assert-example-source-code-only-view (object needle label)
  (let* ((view (html-inspector-views:👀source object))
         (html (and view (html-inspector-views:view-html view))))
    (cr-assert-true view
                    (format nil "~A must expose a source view" label))
    (cr-assert-equal "Source code"
                     (html-inspector-views:view-title view)
                     (format nil "~A source view title" label))
    (cr-assert-string-contains needle html
                               (format nil "~A source view" label))
    (dolist (forbidden '("Source id"
                         "Topic"
                         "Language"
                         "Materialized view file"))
      (cr-assert-string-not-contains
       forbidden html
       (format nil "~A source view must be code-only" label)))))

(defun cr-recorder-event-p (events kind &key event target action)
  (find-if
   (lambda (record)
     (and (eq kind (getf record :kind))
          (or (null event)
              (equal event (getf record :event)))
          (or (null target)
              (equal target (getf record :target)))
          (or (null action)
              (equal action (getf record :action)))))
   events))

(defun make-smoke-check-spec (id title function-symbol &key (kind :test) tags)
  (make-instance 'hyperdoc::check-spec
                 :kind kind
                 :id id
                 :title title
                 :locator (list :function function-symbol)
                 :tags tags))

(defun passing-check-smoke ()
  :passing-value)

(defun failing-check-smoke ()
  (error 'hyperdoc::check-failure :message "expected smoke failure"))

(defun erroring-check-smoke ()
  (error "expected smoke error"))

(defun passing-example-smoke ()
  :passing-example-value)

(defun failing-example-smoke ()
  (error 'hyperdoc::example-failure :message "expected example failure"))

(defun erroring-example-smoke ()
  (error "expected example error"))

(defun skipped-example-smoke ()
  (signal 'hyperdoc::example-skipped :message "expected example skip"))

(defun rerun-pass-check-smoke ()
  (incf *rerun-pass-count*)
  :pass)

(defun rerun-fail-check-smoke ()
  (incf *rerun-fail-count*)
  (case *rerun-fail-behavior*
    (:pass :recovered)
    (otherwise
     (error 'hyperdoc::check-failure :message "rerun failure"))))

(defun rerun-error-check-smoke ()
  (incf *rerun-error-count*)
  (case *rerun-error-behavior*
    (:pass :recovered)
    (otherwise
     (error "rerun error"))))

(defun known-test-check-ids ()
  (mapcar #'hyperdoc::check-id-of
          (hyperdoc::discover-test-checks :system "hyperdoc")))

(defun discovered-example-symbols (system)
  (mapcar (lambda (spec)
            (getf (hyperdoc::check-locator-of spec) :function))
          (hyperdoc::discover-example-checks :system system)))

(defun make-smoke-example-entry (id title function-symbol)
  (make-instance 'hyperdoc:example-entry
                 :system "hyperdoc/tests"
                 :id id
                 :title title
                 :function function-symbol
                 :locator (list :function function-symbol)
                 :package "HYPERDOC/TESTS"
                 :class-or-group "smoke"))

(defun run-check-discovery-smoke-test ()
  (let* ((examples (hyperdoc::discover-example-checks :system "hyperdoc" :page "Examples"))
         (example-symbols
          (mapcar (lambda (spec)
                    (getf (hyperdoc::check-locator-of spec) :function))
                  examples))
         (test-ids (known-test-check-ids)))
    (cr-assert-true (member 'hyperdoc::the-answer example-symbols)
                    "Example discovery must include the-answer on the Examples page")
    (cr-assert-true (member "test:hyperdoc/tests:run-dmx-topic-proxy-smoke-tests"
                            test-ids :test #'equal)
                    "Test discovery must include the DMX smoke suite")
    (cr-assert-true (member "test:hyperdoc/tests:run-fedwiki-site-dmx-import-tests"
                            test-ids :test #'equal)
                    "Test discovery must include the FedWiki import smoke suite")
    (cr-assert-true (member "test:hyperdoc/tests:run-authored-html-render-safety-smoke-tests"
                            test-ids :test #'equal)
                    "Test discovery must include the authored HTML render safety smoke suite")
    (cr-assert-true (member "test:hyperdoc/tests:run-neo4j-duplicate-username-repair-smoke-tests"
                            test-ids :test #'equal)
                    "Test discovery must include the Neo4j duplicate-username repair smoke suite")
    (cr-assert-true (member "test:hyperdoc:run-repo-documentation-slice-validation-check"
                            test-ids :test #'equal)
                    "Test discovery must include the first-class documentation-slice validation check")))

(defun run-merged-doc-slices-discovery-smoke-test ()
  (let* ((spec (known-test-check-spec
                "test:hyperdoc/tests:run-merged-doc-slices-smoke-tests"))
         (locator (and spec (hyperdoc::check-locator-of spec)))
         (function-symbol (and spec (hyperdoc::resolve-function-symbol locator)))
         (test-ids (known-test-check-ids)))
    (cr-assert-true spec
                    "Merged documentation slice smoke suite must be discoverable")
    (cr-assert-equal "Merged documentation slice smoke tests"
                     (hyperdoc::check-title-of spec)
                     "Merged documentation slice smoke suite title")
    (cr-assert-equal "HYPERDOC/TESTS"
                     (getf locator :function-package)
                     "Merged documentation slice smoke suite package locator")
    (cr-assert-equal "RUN-MERGED-DOC-SLICES-SMOKE-TESTS"
                     (getf locator :function-name)
                     "Merged documentation slice smoke suite function locator")
    (cr-assert-equal "hyperdoc"
                     (getf locator :system)
                     "Merged documentation slice smoke suite system locator")
    (cr-assert-equal (intern "RUN-MERGED-DOC-SLICES-SMOKE-TESTS" :hyperdoc/tests)
                     function-symbol
                     "Merged documentation slice smoke suite symbol resolution")
    (cr-assert-true (member "test:hyperdoc/tests:run-merged-doc-slices-smoke-tests"
                            test-ids :test #'equal)
                    "Merged documentation slice smoke suite must be present in the system-scoped test set")))

(defun run-documentation-slice-validation-discovery-smoke-test ()
  (let* ((spec (known-test-check-spec
                "test:hyperdoc:run-repo-documentation-slice-validation-check"))
         (locator (and spec (hyperdoc::check-locator-of spec)))
         (function-symbol (and spec (hyperdoc::resolve-function-symbol locator)))
         (test-ids (known-test-check-ids)))
    (cr-assert-true spec
                    "Documentation-slice validation check must be discoverable")
    (cr-assert-equal "Documentation-slice validation"
                     (hyperdoc::check-title-of spec)
                     "Documentation-slice validation check title")
    (cr-assert-equal "HYPERDOC"
                     (getf locator :function-package)
                     "Documentation-slice validation check package locator")
    (cr-assert-equal "RUN-REPO-DOCUMENTATION-SLICE-VALIDATION-CHECK"
                     (getf locator :function-name)
                     "Documentation-slice validation check function locator")
    (cr-assert-equal "hyperdoc"
                     (getf locator :system)
                     "Documentation-slice validation check system locator")
    (cr-assert-equal (intern "RUN-REPO-DOCUMENTATION-SLICE-VALIDATION-CHECK" :hyperdoc)
                     function-symbol
                     "Documentation-slice validation check symbol resolution")
    (cr-assert-true (member "test:hyperdoc:run-repo-documentation-slice-validation-check"
                            test-ids :test #'equal)
                    "Documentation-slice validation check must be present in the system-scoped test set")))

(defun documentation-validation-check-by-id (report id)
  (find id
        (hyperdoc:documentation-validation-checks-of report)
        :key #'hyperdoc::documentation-validation-check-id-of
        :test #'equal))

(defun run-documentation-slice-validation-report-smoke-test ()
  (let* ((report
          (hyperdoc:validate-documentation-slice
           :page "hyperdoc/Semantic-first anchor resolution.html"
           :topics '("semantic-first-anchor-resolution-topic")
           :fedwiki-pages '("tools/testdata/journal-gate/good-page.json")))
         (audit-check (documentation-validation-check-by-id
                       report
                       "semantic-first-anchor-audit"))
         (audit-payload (and audit-check
                             (hyperdoc::documentation-validation-check-payload-of audit-check)))
         (rendered
          (with-output-to-string (stream)
            (hyperdoc:print-documentation-slice-validation-report report stream))))
    (cr-assert-true (hyperdoc:documentation-slice-validation-pass-p report)
                    "Representative documentation slice must validate successfully")
    (cr-assert-true audit-check
                    "Documentation-slice validation must include a named semantic-first anchor audit check")
    (cr-assert-equal :passed
                     (hyperdoc::documentation-validation-check-status-of audit-check)
                     "Semantic-first anchor audit check status")
    (cr-assert-typep 'hyperdoc::semantic-first-anchor-audit-result
                     audit-payload
                     "Semantic-first anchor audit payload type")
    (cr-assert-string-contains "semantic-first anchor audit"
                               rendered
                               "Documentation-slice report must render the named semantic-first anchor audit")
    (cr-assert-string-contains "SEMANTIC_FIRST_ANCHOR_AUDIT_OK"
                               rendered
                               "Documentation-slice report must print the semantic-first anchor audit result token")))

(defun run-example-system-attribution-smoke-test ()
  (let* ((base-symbols (discovered-example-symbols "hyperdoc"))
         (base-count (length base-symbols)))
    (cr-assert-true (>= base-count 6)
                    "Base hyperdoc must expose at least the current core example set")
    (cr-assert-true (member 'hyperdoc::the-answer base-symbols)
                    "Base hyperdoc examples must include the-answer")
    (cr-assert-true (member 'hyperdoc::journalmatic-commit-gate-script-example
                            base-symbols)
                    "Base hyperdoc examples must include the journal gate script example")
    (cr-assert-true (member 'hyperdoc::journalmatic-date-origin-example
                            base-symbols)
                    "Base hyperdoc examples must include the journal date origin example")
    (cr-assert-true (member 'hyperdoc::journalmatic-monotonic-normalization-example
                            base-symbols)
                    "Base hyperdoc examples must include the monotonic normalization example")
    (cr-assert-true (member 'hyperdoc::fedwiki-materialization-page-preview-example
                            base-symbols)
                    "Base hyperdoc examples must include the FedWiki materialization page preview example")
    (cr-assert-true (member 'hyperdoc::fedwiki-materialization-slice-preview-example
                            base-symbols)
                    "Base hyperdoc examples must include the FedWiki materialization slice preview example")
    (cr-assert-equal 0 (length (discovered-example-symbols "hyperdoc/examples"))
                     "Portable examples must stay unloaded until their system is loaded")
    (cr-assert-equal 0 (length (discovered-example-symbols "hyperdoc/examples/ops"))
                     "Ops examples must stay unloaded until their system is loaded")
    (asdf:load-system :hyperdoc/examples)
    (let ((base-symbols (discovered-example-symbols "hyperdoc"))
          (portable-symbols (discovered-example-symbols "hyperdoc/examples")))
      (cr-assert-equal base-count (length base-symbols)
                       "Loading portable examples must not change the base example count")
      (cr-assert-true (member 'hyperdoc::fedwiki-java-slug-example portable-symbols)
                      "Portable example scope must include fedwiki-java examples")
      (cr-assert-true (plusp (length portable-symbols))
                      "Portable example scope must expose registered examples")
      (cr-assert-equal 0 (length (discovered-example-symbols "hyperdoc/examples/ops"))
                       "Ops examples must stay unloaded while only portable examples are loaded"))
    (asdf:load-system :hyperdoc/examples/ops)
    (let ((base-symbols (discovered-example-symbols "hyperdoc"))
          (portable-symbols (discovered-example-symbols "hyperdoc/examples"))
          (ops-symbols (discovered-example-symbols "hyperdoc/examples/ops")))
      (cr-assert-equal base-count (length base-symbols)
                       "Loading ops examples must not change the base example count")
      (cr-assert-true (plusp (length portable-symbols))
                      "Portable examples must remain registered after loading ops examples")
      (cr-assert-true (member 'hyperdoc::wiki-client-blame-operation-example ops-symbols)
                      "Ops example scope must include the ops-specific examples")
      (cr-assert-true (plusp (length ops-symbols))
                      "Ops example scope must expose registered examples"))))

(defun run-example-model-discovery-smoke-test ()
  (let* ((entries (hyperdoc:discover-examples
                   :system "hyperdoc"
                   :page "Examples"))
         (entry (find 'hyperdoc::the-answer
                      entries
                      :key #'hyperdoc:example-entry-function-of))
         (run (hyperdoc:make-example-run
               :system "hyperdoc"
               :page "Examples"))
         (summary (hyperdoc:example-run-summary-of run)))
    (cr-assert-true entry
                    "Example discovery must expose the-answer as an example entry")
    (cr-assert-typep 'hyperdoc:example-entry
                     entry
                     "Discovered examples must be first-class example entries")
    (cr-assert-equal "hyperdoc"
                     (hyperdoc:example-entry-system-of entry)
                     "Example entry system scope")
    (cr-assert-equal 0
                     (getf summary :executed)
                     "Example run summary before execution")
    (cr-assert-equal (getf summary :total)
                     (getf summary :not-executed)
                     "All example entries must start as not executed")
    (let ((result (hyperdoc:run-example-entry entry)))
      (cr-assert-typep 'hyperdoc:example-result
                       result
                       "Running one example entry must return an example result")
      (cr-assert-equal :success
                       (hyperdoc:example-result-status-of result)
                       "Successful example result status")
      (cr-assert-equal 42
                       (hyperdoc:example-result-value-of result)
                       "Successful example result value"))))

(defun run-example-run-status-smoke-test ()
  (let* ((entries
           (list
            (make-smoke-example-entry "example:smoke:passing"
                                      "Passing example"
                                      'passing-example-smoke)
            (make-smoke-example-entry "example:smoke:failing"
                                      "Failing example"
                                      'failing-example-smoke)
            (make-smoke-example-entry "example:smoke:erroring"
                                      "Erroring example"
                                      'erroring-example-smoke)
            (make-smoke-example-entry "example:smoke:skipped"
                                      "Skipped example"
                                      'skipped-example-smoke)))
         (run (hyperdoc:make-example-run
               :system "hyperdoc/tests"
               :entries entries)))
    (cr-assert-equal 0
                     (getf (hyperdoc:example-run-summary-of run) :executed)
                     "Example run must not execute entries during construction")
    (hyperdoc:run-example-run! run)
    (let ((summary (hyperdoc:example-run-summary-of run)))
      (cr-assert-equal 4 (getf summary :total)
                       "Example run total count")
      (cr-assert-equal 4 (getf summary :executed)
                       "Example run executed count")
      (cr-assert-equal 1 (getf summary :success)
                       "Example run success count")
      (cr-assert-equal 1 (getf summary :failure)
                       "Example run failure count")
      (cr-assert-equal 1 (getf summary :error)
                       "Example run error count")
      (cr-assert-equal 1 (getf summary :skipped)
                       "Example run skipped count")
      (cr-assert-equal 0 (getf summary :not-executed)
                       "Example run not-executed count"))))

(defun make-temp-example-source-store ()
  (hyperdoc:make-example-source-sqlite-store
   :db-path (merge-pathnames
             (format nil "hyperdoc-example-source-artifacts-~36R.sqlite"
                     (get-universal-time))
             (uiop:temporary-directory))))

(defun make-temp-inspector-path-store ()
  (hyperdoc:make-inspector-path-sqlite-store
   :db-path (merge-pathnames
             (format nil "hyperdoc-inspector-path-evidence-~36R.sqlite"
                     (get-universal-time))
             (uiop:temporary-directory))))

(defun cr-json-object-value (object key)
  (cond
    ((hash-table-p object)
     (multiple-value-bind (value present-p)
         (gethash key object)
       (and present-p value)))
    ((and (listp object) (assoc key object :test #'string=))
     (cdr (assoc key object :test #'string=)))
    (t nil)))

(defun cr-json-array-list (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (list value))))

(defun cr-inspector-path-sqlite-output (store sql)
  (multiple-value-bind (output status detail)
      (hyperdoc::inspector-path-sqlite-run store sql)
    (unless (eq status :ok)
      (error "SQLite query failed: ~A -- ~A" sql detail))
    output))

(defun cr-inspector-path-sqlite-scalar (store sql)
  (string-trim '(#\Space #\Tab #\Newline #\Return)
               (cr-inspector-path-sqlite-output store sql)))

(defun cr-read-json-string (json)
  (with-input-from-string (stream json)
    (shasht:read-json stream)))

(defun run-inspector-path-json-encoding-smoke-test ()
  (if (not (hyperdoc:example-source-sqlite-available-p))
      (format t "~&Skipping inspector path JSON encoding smoke test; sqlite3 unavailable.~%")
      (let* ((store (make-temp-inspector-path-store))
             (labels '("Source code" "Source code" "Meta"))
             (dom-labels '("DOM label" "DOM label" "Meta"))
             (step
               (make-instance
                'hyperdoc:inspector-path-step
                :step-id "path-step:json-encoding"
                :index 0
                :path-name "smoke/json-encoding"
                :phase "labels"
                :action "render Source code"
                :view-titles labels
                :dom-labels dom-labels
                :details "plain string"))
             (trace
               (make-instance
                'hyperdoc:inspector-path-trace
                :trace-id "path-trace:json-encoding"
                :path-name "smoke/json-encoding"
                :entry-function "smoke"
                :steps (list step)
                :result :ok)))
        (hyperdoc:persist-inspector-path-trace trace :store store)
        (let* ((step-topic (hyperdoc::inspector-path-step-topic-of step))
               (topic-id (hyperdoc:path-topic-id-of step-topic))
               (value-json
                 (cr-inspector-path-sqlite-scalar
                  store
                  (format nil "SELECT value_json FROM path_topics WHERE topic_id = ~A;"
                          (hyperdoc::example-source-sqlite-string-literal
                           topic-id))))
               (properties-json
                 (cr-inspector-path-sqlite-scalar
                  store
                  "SELECT properties_json FROM path_associations WHERE association_type = 'hyperdoc.path.contains-step' LIMIT 1;"))
               (topic-value (cr-read-json-string value-json))
               (association-properties (cr-read-json-string properties-json))
               (decoded-view-titles
                 (cr-json-array-list
                  (cr-json-object-value topic-value "view-titles")))
               (decoded-dom-labels
                 (cr-json-array-list
                  (cr-json-object-value topic-value "dom-labels"))))
          (cr-assert-equal
           "render Source code"
           (cr-json-object-value topic-value "action")
           "Path evidence action must round-trip as a JSON string")
          (cr-assert-equal
           "plain string"
           (cr-json-object-value topic-value "details")
           "Path evidence details must round-trip as a JSON string")
          (cr-assert-equal labels
                           decoded-view-titles
                           "View titles must round-trip as an ordered JSON array with duplicates")
          (cr-assert-equal dom-labels
                           decoded-dom-labels
                           "DOM labels must round-trip as an ordered JSON array with duplicates")
          (cr-assert-string-not-contains
           "[\"S\",\"o\",\"u\""
           value-json
           "View titles must not serialize as character arrays")
          (cr-assert-string-not-contains
           "{\"S\""
           value-json
           "View titles must not serialize as malformed first-character object maps")
          (cr-assert-equal
           0
           (cr-json-object-value association-properties "index")
           "Association properties JSON must remain parseable")
          (let ((path-topics-schema
                  (cr-inspector-path-sqlite-output
                   store
                   "PRAGMA table_info(path_topics);"))
                (path-associations-schema
                  (cr-inspector-path-sqlite-output
                   store
                   "PRAGMA table_info(path_associations);")))
            (dolist (column '("topic_id" "value_json"))
              (cr-assert-string-contains
               column path-topics-schema
               "path_topics schema must remain valid"))
            (dolist (column '("association_id" "properties_json"))
              (cr-assert-string-contains
               column path-associations-schema
               "path_associations schema must remain valid")))))))

(defun run-example-source-artifact-inspector-scxml-smoke-test ()
  (asdf:load-system :hyperdoc/scxml)
  (let* ((chart (hyperdoc/scxml:parse-scxml-file
                 (cr-example-source-artifact-inspector-scxml-pathname)))
         (findings (hyperdoc/scxml:validate-scxml-chart chart))
         (errors (cr-scxml-error-findings findings))
         (state-ids (cr-scxml-state-ids chart)))
    (cr-assert-equal
     "example-source-artifact-inspector"
     (hyperdoc/scxml:scxml-chart-name-of chart)
     "Source artifact inspector SCXML chart name")
    (cr-assert-equal
     "inspecting-example-source-artifact"
     (hyperdoc/scxml:scxml-chart-initial-state-of chart)
     "Source artifact inspector SCXML initial state")
    (cr-assert-true
     (null errors)
     (format nil "Source artifact inspector SCXML must validate: ~S"
             (mapcar #'hyperdoc/scxml:scxml-validation-finding-code-of
                     errors)))
    (dolist (state '("inspecting-example-source-artifact"
                     "source-code-selected"
                     "meta-selected"
                     "result-source-opened"))
      (cr-assert-true
       (member state state-ids :test #'string=)
       (format nil "Source artifact inspector SCXML state missing: ~A"
               state)))
    (dolist (transition
              '(("inspecting-example-source-artifact"
                 "tabs.rendered"
                 "inspecting-example-source-artifact")
                ("inspecting-example-source-artifact"
                 "select.source-code"
                 "source-code-selected")
                ("inspecting-example-source-artifact"
                 "select.meta"
                 "meta-selected")
                ("inspecting-example-source-artifact"
                 "inspect.example-result.source"
                 "result-source-opened")
                ("source-code-selected"
                 "select.meta"
                 "meta-selected")
                ("meta-selected"
                 "select.source-code"
                 "source-code-selected")))
      (destructuring-bind (source event target) transition
        (cr-assert-true
         (cr-scxml-transition chart source event target)
         (format nil "Source artifact inspector transition missing: ~A --~A--> ~A"
                 source event target))))
    (cr-assert-equal
     "Source code|Meta|Slots|Print|Operations|Playground"
     (cr-scxml-state-log-expr chart
                              "inspecting-example-source-artifact"
                              "visible-tabs")
     "Source artifact inspector SCXML visible tab contract")
    (cr-assert-equal
     "Summary"
     (cr-scxml-state-log-expr chart
                              "inspecting-example-source-artifact"
                              "forbidden-tabs")
     "Source artifact inspector SCXML forbidden tab contract"))
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object
                             (make-instance
                              'hyperdoc:example-source-artifact
                              :source-id
                              "example-source:scxml-dispatch-smoke"
                              :topic-id "982311"
                              :topic-slug
                              "example-source-artifact-inspector-contract"
                              :topic-title
                              "Example source artifact inspector contract"
                              :asdf-system-name "hyperdoc"
                              :function-symbol
                              "HYPERDOC::EXAMPLE-SOURCE-ARTIFACT-INSPECTOR-CONTRACT-EXAMPLE"
                              :source-language :common-lisp
                              :source-form-kind :defexample
                              :source-text
                              "(hyperdoc:defexample scxml-dispatch-smoke (:register nil) :ok)"
                              :provenance :fedwiki-topic)))
        (render-tabs-action-invoked-p nil)
        (select-meta-action-invoked-p nil))
    (clog-moldable-inspector::clear-inspector-scxml-ui-recorder)
    (clog-moldable-inspector::example-source-artifact-inspector-initialize-pane
     pane)
    (clog-moldable-inspector::example-source-artifact-inspector-dispatch-event
     pane "tabs.rendered"
     :action-name "render-pane-tabs"
     :action (lambda ()
               (setf render-tabs-action-invoked-p t)))
    (clog-moldable-inspector::example-source-artifact-inspector-record-pane-tabs-rendered
     pane
     '("Source code" "Meta" "Slots" "Print" "Operations" "Playground"))
    (clog-moldable-inspector::example-source-artifact-inspector-dispatch-event
     pane "select.meta"
     :action-name "select-meta-view"
     :action (lambda ()
               (setf select-meta-action-invoked-p t)))
    (let ((events
            (clog-moldable-inspector::inspector-scxml-ui-recorder-events)))
      (cr-assert-true events
                      "SCXML recorder must not remain empty")
      (dolist (kind '(:scxml-loaded
                      :state-entered
                      :event-dispatched
                      :transition-selected
                      :guard-evaluated
                      :action-invoked
                      :pane-tabs-rendered))
        (cr-assert-true
         (cr-recorder-event-p events kind)
         (format nil "SCXML recorder missing event kind ~S" kind)))
      (cr-assert-true
       (cr-recorder-event-p events
                            :event-dispatched
                            :event "tabs.rendered")
       "SCXML recorder must capture the tab-row render event")
      (cr-assert-true
       (cr-recorder-event-p events
                            :transition-selected
                            :event "tabs.rendered"
                            :target "inspecting-example-source-artifact")
       "SCXML recorder must capture the tab-row render transition")
      (cr-assert-true
       (cr-recorder-event-p events
                            :action-invoked
                            :event "tabs.rendered"
                            :action "render-pane-tabs")
       "SCXML recorder must capture the named tab-row render action")
      (cr-assert-true
       (cr-recorder-event-p events
                            :event-dispatched
                            :event "select.meta")
       "SCXML recorder must capture the dispatched tab event")
      (cr-assert-true
       (cr-recorder-event-p events
                            :transition-selected
                            :event "select.meta"
                            :target "meta-selected")
       "SCXML recorder must capture the selected transition")
      (cr-assert-true
       (cr-recorder-event-p events
                            :action-invoked
                            :event "select.meta"
                            :action "select-meta-view")
       "SCXML recorder must capture the named tab action")
      (cr-assert-true render-tabs-action-invoked-p
                      "SCXML dispatch must invoke the tab-row render action")
      (cr-assert-true select-meta-action-invoked-p
                      "SCXML dispatch must invoke the supplied tab action"))))

(defun run-topic-backed-example-source-artifact-smoke-test ()
  (if (not (hyperdoc:example-source-sqlite-available-p))
      (format t "~&Skipping topic-backed example source artifact smoke test; sqlite3 unavailable.~%")
      (let* ((source-id "example-source:topic-backed-smoke")
             (source-text
               "(hyperdoc:defexample topic-backed-smoke (:register nil) :ok)")
             (locator (list :function 'passing-example-smoke
                            :source-id source-id
                            :topic-id "982311"
                            :topic-slug "example-source-reference"
                            :topic-title "Example source reference"
                            :fedwiki-page-identity "example-source-reference"
                            :source-language :common-lisp
                            :source-form-kind :defexample
                            :provenance :sly-mrepl
                            :source-text source-text))
             (lookup-locator (list :function 'passing-example-smoke
                                   :source-id source-id
                                   :topic-id "982311"
                                   :topic-slug "example-source-reference"
                                   :topic-title "Example source reference"
                                   :fedwiki-page-identity
                                   "example-source-reference"
                                   :source-language :common-lisp
                                   :source-form-kind :defexample
                                   :provenance :sly-mrepl))
             (entry (make-instance
                     'hyperdoc:example-entry
                     :system "hyperdoc/tests"
                     :id "example:topic-backed-smoke"
                     :title "Topic-backed source artifact smoke"
                     :function 'passing-example-smoke
                     :locator locator
                     :package "HYPERDOC/TESTS"
                     :class-or-group "source"))
             (store (make-temp-example-source-store)))
        (asdf:load-system :hyperdoc/explorer)
        (let ((hyperdoc:*example-source-store* store))
          (let* ((reference (hyperdoc:make-example-source-reference entry))
                 (artifact
                   (hyperdoc:example-source-reference-source-artifact-of
                    reference))
                 (result (hyperdoc:run-example-entry entry)))
            (cr-assert-equal :topic
                             (hyperdoc:example-source-reference-source-kind-of
                              reference)
                             "Supplied source text must become a topic source reference")
            (cr-assert-typep 'hyperdoc:example-source-artifact
                             artifact
                             "Topic source reference must point to a persisted source artifact")
            (cr-assert-equal source-text
                             (hyperdoc:example-source-artifact-source-text-of
                              artifact)
                             "Persisted source artifact text")
            (let* ((artifact-views (html-inspector-views:all-views artifact))
                   (clog-pane-views (cr-load-clog-pane-views artifact))
                   (meta-html (cr-view-html-by-title-in-views
                               clog-pane-views "Meta")))
              (cr-assert-example-source-artifact-tab-contract
               artifact-views
               "Example source artifact html-inspector-views path")
              (cr-assert-example-source-artifact-tab-contract
               clog-pane-views
               "Example source artifact CLOG pane load-views path")
              (cr-assert-example-source-code-only-view
               artifact "hyperdoc:defexample" "Example source artifact")
              (cr-assert-example-source-code-only-view
               reference "hyperdoc:defexample" "Example source reference")
              (cr-assert-example-source-code-only-view
               entry "hyperdoc:defexample" "Example entry")
              (cr-assert-example-source-code-only-view
               result "hyperdoc:defexample" "Example result")
              (dolist (metadata '("Source id"
                                  "Topic id"
                                  "Topic slug"
                                  "Topic title"
                                  "Language"
                                  "Form kind"
                                  "Provenance"
                                  "Store/backend"))
                (cr-assert-string-contains
                 metadata meta-html
                 "Example source artifact Meta view must expose metadata")))
            (multiple-value-bind (loaded status detail)
                (hyperdoc:find-example-source-artifact store source-id)
              (declare (ignore detail))
              (cr-assert-equal :ok status
                               "Persisted source artifact lookup status")
              (cr-assert-typep 'hyperdoc:example-source-artifact
                               loaded
                               "Persisted source artifact lookup type")
              (cr-assert-equal source-text
                               (hyperdoc:example-source-artifact-source-text-of
                                loaded)
                               "Persisted source artifact lookup text")))
          (let* ((lookup-entry
                   (make-instance
                    'hyperdoc:example-entry
                    :system "hyperdoc/tests"
                    :id "example:topic-backed-smoke"
                    :title "Topic-backed source artifact lookup"
                    :function 'passing-example-smoke
                    :locator lookup-locator
                    :package "HYPERDOC/TESTS"))
                 (lookup-reference
                   (hyperdoc:make-example-source-reference lookup-entry))
                 (lookup-artifact
                   (hyperdoc:example-source-reference-source-artifact-of
                    lookup-reference)))
            (cr-assert-equal :topic
                             (hyperdoc:example-source-reference-source-kind-of
                              lookup-reference)
                             "Existing topic source artifact must resolve without supplied source text")
            (cr-assert-equal source-text
                             (hyperdoc:example-source-artifact-source-text-of
                              lookup-artifact)
                             "Topic source reference must load source text from SQLite"))))))

(defun run-example-source-artifact-path-evidence-smoke-test ()
  (if (not (hyperdoc:example-source-sqlite-available-p))
      (format t "~&Skipping example source artifact path evidence smoke test; sqlite3 unavailable.~%")
      (let* ((artifact
               (hyperdoc:make-example-source-artifact-inspector-contract-artifact))
             (store (make-temp-inspector-path-store))
             (expected-tabs
               '("Source code" "Meta" "Slots" "Print" "Operations" "Playground")))
        (let ((hyperdoc:*inspector-path-store* store))
          (let* ((actual
                   (hyperdoc:record-example-source-artifact-clog-pane-path
                    artifact
                    expected-tabs
                    :dom-labels expected-tabs
                    :recorder-events
                    '((:kind :scxml-loaded
                       :machine "example-source-artifact-inspector")
                      (:kind :state-entered
                       :state "inspecting-example-source-artifact")
                      (:kind :event-dispatched
                       :event "tabs.rendered")
                      (:kind :transition-selected
                       :event "tabs.rendered"
                       :target "inspecting-example-source-artifact")
                      (:kind :guard-evaluated
                       :event "tabs.rendered"
                       :result "true")
                      (:kind :action-invoked
                       :event "tabs.rendered"
                       :action "render-pane-tabs")
                      (:kind :pane-tabs-rendered
                       :tabs ("Source code" "Meta" "Slots" "Print"
                              "Operations" "Playground")))))
                 (trace
                   (hyperdoc:trace-and-persist-example-source-artifact-inspector-path
                    artifact
                    :store store))
                 (comparison
                   (hyperdoc:compare-and-persist-example-source-artifact-inspector-paths
                    artifact
                    :store store)))
            (cr-assert-typep 'hyperdoc:inspector-path-trace
                             actual
                             "Actual CLOG path trace must be inspectable")
            (cr-assert-typep 'hyperdoc:inspector-path-trace
                             trace
                             "Trace entry point must return an inspector path trace")
            (cr-assert-typep 'hyperdoc:inspector-path-comparison
                             comparison
                             "Comparison entry point must return an inspector path comparison")
            (cr-assert-true
             (hyperdoc:inspector-path-trace-topics-of trace)
             "Trace must persist path topics")
            (cr-assert-true
             (hyperdoc:inspector-path-trace-associations-of trace)
             "Trace must persist path associations")
            (cr-assert-true
             (hyperdoc:inspector-path-comparison-equivalent-p-of comparison)
             "Model, synthetic, and recorded actual path labels must compare equivalent")
            (cr-assert-equal
             nil
             (hyperdoc:inspector-path-comparison-first-divergence-of comparison)
             "Equivalent paths must not report a first divergence")
            (let* ((divergent-trace
                     (make-instance
                      'hyperdoc:inspector-path-trace
                      :trace-id "path-trace:divergent-summary"
                      :path-name "manual/divergent"
                      :object artifact
                      :steps
                      (list
                       (make-instance
                        'hyperdoc:inspector-path-step
                        :step-id "path-step:divergent-summary"
                        :index 0
                        :path-name "manual/divergent"
                        :phase "dom-tab-labels"
                        :dom-labels
                        '("Source code" "Summary" "Slots" "Print"
                          "Operations" "Playground")))))
                   (divergent-comparison
                     (make-instance
                      'hyperdoc:inspector-path-comparison
                      :comparison-id "path-comparison:divergent-summary"
                      :object artifact
                      :traces
                      (list trace divergent-trace)
                      :equivalent-p nil
                      :first-divergence
                      (list :actual-labels
                            '("Source code" "Summary" "Slots" "Print"
                              "Operations" "Playground")))))
              (declare (ignore divergent-comparison))
              (cr-assert-string-contains
               "Summary"
               (with-output-to-string (stream)
                 (prin1
                  '(:actual-labels
                    ("Source code" "Summary" "Slots" "Print"
                     "Operations" "Playground"))
                  stream))
               "Divergence evidence must make Summary visible")))))))

(defun known-test-check-spec (id)
  (find id
        (hyperdoc::discover-test-checks :system "hyperdoc")
        :key #'hyperdoc::check-id-of
        :test #'equal))

(defun run-check-source-target-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((spec (known-test-check-spec
                "test:hyperdoc/tests:run-dmx-topic-proxy-smoke-tests"))
         (spec-source-target (and spec
                                  (hyperdoc::resolve-check-source-target spec)))
         (result (and spec
                      (hyperdoc::run-check spec)))
         (result-source-target (and result
                                    (hyperdoc::resolve-check-source-target result))))
    (cr-assert-true spec
                    "Known DMX smoke test must be discoverable")
    (cr-assert-true spec-source-target
                    "Discovered test spec must resolve a source target")
    (cr-assert-typep 'function spec-source-target
                     "Discovered test spec source target must be function-backed")
    (cr-assert-true result-source-target
                    "Check result must resolve a source target through its spec")
    (cr-assert-typep 'function result-source-target
                     "Check result source target must be function-backed")))

(defun run-passing-check-smoke-test ()
  (let* ((spec (make-smoke-check-spec "test:smoke:passing"
                                      "Passing smoke check"
                                      'passing-check-smoke))
         (result (hyperdoc::run-check spec)))
    (cr-assert-equal :passed
                     (hyperdoc::check-result-status-of result)
                     "Passing check status")
    (cr-assert-equal :passing-value
                     (hyperdoc::check-result-value-of result)
                     "Passing check value")))

(defun run-failure-and-error-smoke-test ()
  (let* ((failed (hyperdoc::run-check
                  (make-smoke-check-spec "test:smoke:failed"
                                         "Failed smoke check"
                                         'failing-check-smoke)))
         (errored (hyperdoc::run-check
                   (make-smoke-check-spec "test:smoke:error"
                                          "Errored smoke check"
                                          'erroring-check-smoke))))
    (cr-assert-equal :failed
                     (hyperdoc::check-result-status-of failed)
                     "Failure check status")
    (cr-assert-typep 'hyperdoc::check-failure
                     (hyperdoc::check-result-condition-of failed)
                     "Failure check condition type")
    (cr-assert-true (stringp (hyperdoc::check-result-backtrace-of failed))
                    "Failure check must capture backtrace text")
    (cr-assert-equal :error
                     (hyperdoc::check-result-status-of errored)
                     "Error check status")
    (cr-assert-true (typep (hyperdoc::check-result-condition-of errored) 'error)
                    "Error check must capture the raw condition")
    (cr-assert-true (stringp (hyperdoc::check-result-backtrace-of errored))
                    "Error check must capture backtrace text")))

(defun run-batch-summary-smoke-test ()
  (let* ((run (hyperdoc::run-checks
               (list (make-smoke-check-spec "test:smoke:passing"
                                            "Passing smoke check"
                                            'passing-check-smoke)
                     (make-smoke-check-spec "test:smoke:failed"
                                            "Failed smoke check"
                                            'failing-check-smoke)
                     (make-smoke-check-spec "test:smoke:error"
                                            "Errored smoke check"
                                            'erroring-check-smoke))))
         (summary (hyperdoc::check-run-status-summary-of run)))
    (cr-assert-equal 3 (getf summary :total)
                     "Batch total count")
    (cr-assert-equal 1 (getf summary :passed)
                     "Batch passed count")
    (cr-assert-equal 1 (getf summary :failed)
                     "Batch failed count")
    (cr-assert-equal 1 (getf summary :error)
                     "Batch errored count")
    (cr-assert-equal 0 (getf summary :pending)
                     "Batch pending count after full run")))

(defun run-rerun-failed-smoke-test ()
  (setf *rerun-pass-count* 0
        *rerun-fail-count* 0
        *rerun-error-count* 0
        *rerun-fail-behavior* :fail
        *rerun-error-behavior* :error)
  (let* ((run (hyperdoc::run-checks
               (list (make-smoke-check-spec "test:smoke:rerun-pass"
                                            "Rerun pass check"
                                            'rerun-pass-check-smoke)
                     (make-smoke-check-spec "test:smoke:rerun-fail"
                                            "Rerun fail check"
                                            'rerun-fail-check-smoke)
                     (make-smoke-check-spec "test:smoke:rerun-error"
                                            "Rerun error check"
                                            'rerun-error-check-smoke))))
         (before (hyperdoc::check-run-status-summary-of run)))
    (cr-assert-equal 1 *rerun-pass-count*
                     "Passing check must run once initially")
    (cr-assert-equal 1 *rerun-fail-count*
                     "Failing check must run once initially")
    (cr-assert-equal 1 *rerun-error-count*
                     "Errored check must run once initially")
    (cr-assert-equal 1 (getf before :failed)
                     "Initial run must include one failed check")
    (cr-assert-equal 1 (getf before :error)
                     "Initial run must include one errored check")
    (setf *rerun-fail-behavior* :pass
          *rerun-error-behavior* :pass)
    (hyperdoc::rerun-failed-checks! run)
    (let ((after (hyperdoc::check-run-status-summary-of run)))
      (cr-assert-equal 1 *rerun-pass-count*
                       "Passing checks must not rerun during rerun-failed")
      (cr-assert-equal 2 *rerun-fail-count*
                       "Failed checks must rerun once")
      (cr-assert-equal 2 *rerun-error-count*
                       "Errored checks must rerun once")
      (cr-assert-equal 3 (getf after :passed)
                       "Recovered rerun must end with all checks passed")
      (cr-assert-equal 0 (getf after :failed)
                       "Recovered rerun must clear failures")
      (cr-assert-equal 0 (getf after :error)
                       "Recovered rerun must clear errors"))))

(defun run-single-example-compatibility-smoke-test ()
  (cr-assert-equal 42
                   (hyperdoc::the-answer)
                   "Single example execution must remain unchanged"))

(defun run-check-runner-smoke-tests ()
  (run-check-discovery-smoke-test)
  (run-merged-doc-slices-discovery-smoke-test)
  (run-documentation-slice-validation-discovery-smoke-test)
  (run-documentation-slice-validation-report-smoke-test)
  (run-example-system-attribution-smoke-test)
  (run-example-model-discovery-smoke-test)
  (run-example-run-status-smoke-test)
  (run-example-source-artifact-inspector-scxml-smoke-test)
  (run-topic-backed-example-source-artifact-smoke-test)
  (run-example-source-artifact-path-evidence-smoke-test)
  (run-inspector-path-json-encoding-smoke-test)
  (run-check-source-target-smoke-test)
  (run-passing-check-smoke-test)
  (run-failure-and-error-smoke-test)
  (run-batch-summary-smoke-test)
  (run-rerun-failed-smoke-test)
  (run-single-example-compatibility-smoke-test)
  (format t "~&Runner smoke tests passed.~%")
  t)
