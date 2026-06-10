(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (defpackage :hyperdoc/tests
      (:use :cl)
      (:export :run-hyperdoc-tests
               :run-s-expression-prompt-pure-core-smoke-test
               :run-s-expression-prompt-pure-boundary-smoke-test
               :run-s-expression-prompt-roundtrip-smoke-test
               :run-s-expression-prompt-generated-page-smoke-test
               :run-s-expression-prompt-smoke-tests))))

(in-package :hyperdoc/tests)

(eval-when (:load-toplevel :execute)
  (unless (fboundp 'run-s-expression-prompt-smoke-tests)
    (require :asdf)
    (let* ((asdf-package (find-package "ASDF"))
           (load-system-symbol
             (and asdf-package
                  (find-symbol "LOAD-SYSTEM" asdf-package))))
      (unless (and load-system-symbol
                   (fboundp load-system-symbol))
        (error "ASDF:LOAD-SYSTEM is unavailable after REQUIRE :ASDF."))
      (funcall (symbol-function load-system-symbol) :hyperdoc/tests))))


(defun run-fedwiki-loader-examples-smoke-tests ()
  "Run the ASDF-backed FedWiki loader examples from the legacy test runner.

This keeps the examples-driven suite visible from both:
  1. ASDF:TEST-SYSTEM on :HYPERDOC-FEDWIKI-LOADER-EXAMPLES;
  2. the existing HYPERDOC/TESTS smoke boundary."
  (require :asdf)
  (let* ((asdf-package
           (find-package "ASDF"))
         (load-asd
           (and asdf-package
                (find-symbol "LOAD-ASD" asdf-package)))
         (load-system
           (and asdf-package
                (find-symbol "LOAD-SYSTEM" asdf-package)))
         (test-system
           (and asdf-package
                (find-symbol "TEST-SYSTEM" asdf-package)))
         (find-system
           (and asdf-package
                (find-symbol "FIND-SYSTEM" asdf-package)))
         (system-source-directory
           (and asdf-package
                (find-symbol "SYSTEM-SOURCE-DIRECTORY" asdf-package))))
    (unless (and load-system test-system find-system system-source-directory)
      (error "Required ASDF entry points are unavailable."))

    (unless (ignore-errors
              (funcall (symbol-function find-system)
                       :hyperdoc-fedwiki-loader-examples
                       nil))
      (unless load-asd
        (error "ASDF:LOAD-ASD is unavailable; cannot register examples system."))
      (funcall
       (symbol-function load-asd)
       (merge-pathnames
        #p"hyperdoc-fedwiki-loader-examples.asd"
        (funcall (symbol-function system-source-directory)
                 :hyperdoc))))

    (funcall (symbol-function load-system)
             :hyperdoc-fedwiki-loader-examples)
    (funcall (symbol-function test-system)
             :hyperdoc-fedwiki-loader-examples)

    (let* ((hyperdoc-package
             (find-package "HYPERDOC"))
           (runner
             (and hyperdoc-package
                  (find-symbol "RUN-FEDWIKI-LOADER-EXAMPLES"
                               hyperdoc-package))))
      (unless (and runner
                   (fboundp runner))
        (error "RUN-FEDWIKI-LOADER-EXAMPLES is unavailable after loading examples system."))
      (let ((suite
              (funcall (symbol-function runner))))
        (unless (eq (getf suite :status) :pass)
          (error "FedWiki loader examples smoke failed: ~S" suite))
        (format t "~&FedWiki loader examples smoke tests passed.~%")
        t))))

(defun run-hyperdoc-tests ()
  ;; This boundary check must run before compile-order tests intentionally load
  ;; :hyperdoc/inspector, which depends on the optional Zotero backend.
  (run-zotero-optional-smoke-tests)
  (run-compile-order-smoke-tests :force? nil)
  (run-code-path-graphs-smoke-tests)
  (run-dmx-topic-proxy-smoke-tests)
  (run-state-machine-smoke-tests)
  (run-scxml-compiler-smoke-tests)
  (run-page-lookup-topic-repair-scxml-smoke-tests)
  (run-shared-projection-ir-smoke-tests)
  (run-snippet-playground-artifact-smoke-tests)
  (run-authored-relation-artifact-pattern-smoke-tests)
  (run-surface-smoke-tests)
  (run-boundary-smoke-tests)
  (run-relation-topic-proposals-smoke-tests)
  (run-lisp-critic-review-plan-smoke-tests)
  (run-lisp-critic-contract-smoke-tests)
  (run-dock-presentation-smoke-tests)
  (run-dock-annotation-smoke-tests)
  (run-mobile-progressive-chrome-smoke-tests)
  (run-reel-accessible-carousel-smoke-tests)
  (run-layout-topicmap-smoke-tests)
  (run-dmx-annotations-smoke-tests)
  (run-dmx-workspace-journal-sink-smoke-tests)
  (run-dmx-auth-session-boundary-smoke-tests)
  (run-dmx-annotation-936040-regression-smoke-tests)
  (run-sly-evidence-bounds-smoke-tests)
  (run-dmx-workspace-assignment-auth-diagnosis-smoke-tests)
  (run-dmx-platform-workspace-assignment-semantics-smoke-tests)
  (run-article-allegation-slice-smoke-tests)
  (run-fedwiki-materialization-smoke-tests)
  (run-fedwiki-loader-examples-smoke-tests)
  (run-authored-html-render-safety-smoke-tests)
  (run-lookup-issue-docs-render-smoke-tests)
  (run-page-lookup-issues-smoke-tests)
  (run-page-lookup-disconnection-smoke-tests)
  (run-function-lookup-issues-smoke-tests)
  (run-class-lookup-issues-smoke-tests)
  (run-collective-knowledge-slice-smoke-tests)
  (run-reproducible-devenv-as-knowledge-artifact-slice-smoke-tests)
  (run-localhost-fedwiki-page-pipeline-smoke-tests)
  (run-localhost-fedwiki-page-promotion-plans-smoke-tests)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-smoke-tests)
  (run-topic-factory-snippet-dmx-smoke-tests)
  (run-hyperdoc-test-system-runbook-smoke-tests)
  (run-dmx-annotation-acceptance-scxml-runbook-smoke-tests)
  (run-dmx-mcp-smoke-tests)
  (run-dmx-incident-arc-smoke-tests)
  (run-dmx-query-layer-smoke-tests)
  (run-dm6-page-topicmap-smoke-tests)
  (run-topicmap-view-smoke-tests)
  (run-topic-files-topicmap-smoke-tests)
  (run-s-expression-prompt-smoke-tests)
  (run-fedwiki-asdf-assets-smoke-tests)
  (run-fedwiki-attached-asdf-system-smoke-tests)
  (run-dmx-shared-workspace-docs-smoke-tests)
  (run-neo4j-duplicate-username-repair-smoke-tests)
  (run-hyperdoc-neo4j-topic-delete-tool-operation-ir-smoke-tests)
  (run-fedwiki-site-dmx-import-tests)
  (run-check-runner-smoke-tests)
  (run-fedwiki-story-items-smoke-tests)
  (run-view-contract-smoke-tests)
  (run-inspector-performance-smoke-tests)
  (run-merged-doc-slices-smoke-tests)
  (run-iconic-retrieval-smoke-tests)
  (run-git-commit-assimilation-smoke-tests)
  (run-skillization-smoke-tests)
  (run-mech-deployment-provenance-smoke-tests)
  (run-runtime-coherence-smoke-tests)
  (run-interaction-net-smoke-tests)
  (run-closure-nor-demo-smoke-tests)
  (run-nor-graph-matcher-smoke-tests)
  (run-continuation-route-trace-smoke-tests)
  t)

(export '(run-hyperdoc-tests))
