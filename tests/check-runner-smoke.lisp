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
  (run-check-source-target-smoke-test)
  (run-passing-check-smoke-test)
  (run-failure-and-error-smoke-test)
  (run-batch-summary-smoke-test)
  (run-rerun-failed-smoke-test)
  (run-single-example-compatibility-smoke-test)
  (format t "~&Runner smoke tests passed.~%")
  t)
