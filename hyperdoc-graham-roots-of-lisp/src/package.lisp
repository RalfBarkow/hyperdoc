;;;; Packages for the executable Roots of Lisp reconstruction.

(defpackage #:hyperdoc-graham-roots-of-lisp/object
  (:use #:cl)
  (:documentation
   "Reader package for object-language expressions. Forms read here are data;
they are never passed to Common Lisp EVAL."))

(defpackage #:hyperdoc-graham-roots-of-lisp
  (:use #:cl)
  (:nicknames #:roots-of-lisp)
  (:export
   ;; Conditions
   #:roots-language-error
   #:roots-language-error-expression-of
   #:roots-language-error-environment-of
   #:roots-language-error-reason-of

   ;; Model and accessors
   #:roots-topic
   #:roots-trace-event
   #:roots-evaluation
   #:roots-rule-comparison
   #:roots-session
   #:roots-transcript
   #:id-of
   #:title-of
   #:summary-of
   #:references-of
   #:page-of
   #:sequence-of
   #:depth-of
   #:kind-of
   #:expression-of
   #:environment-of
   #:detail-of
   #:result-of
   #:status-of
   #:events-of
   #:condition-of
   #:trace-truncated-p-of
   #:roots-comparison-case-of
   #:roots-comparison-source-locators-of
   #:roots-comparison-witness-of
   #:roots-comparison-rule-before-of
   #:roots-comparison-rule-after-of
   #:roots-comparison-mccarthy-evaluation-of
   #:roots-comparison-graham-evaluation-of
   #:roots-comparison-unlicensed-transition-of
   #:roots-comparison-replay-status-of
   #:source-of
   #:forms-of
   #:results-of
   #:history-of
   #:session-environment-of

   ;; Reader and evaluator
   #:roots-read-form
   #:roots-read-program
   #:roots-eval
   #:roots-evaluate
   #:roots-evaluate-source
   #:roots-object-equal

   ;; Session / Stanford-style adapter
   #:make-roots-session
   #:roots-session-define
   #:roots-session-evaluate
   #:roots-interpret-form
   #:roots-interpret-string
   #:roots-preload-accessors
   #:roots-load-graham-library
   #:roots-bootstrap-session
   #:roots-graham-library-source

   ;; Examples and reconstruction operations
   #:roots-example-report
   #:roots-seven-primitive-reports
   #:roots-direct-subst-report
   #:roots-surprise-report
   #:roots-named-call-double-evaluation-report
   #:roots-named-call-version-history
   #:roots-dynamic-binding-capture-report
   #:roots-reconstruction-summary
   #:roots-reading-order
   #:roots-stanford-crosswalk
   #:roots-nine-ideas-crosswalk
   #:roots-seven-primitives-example
   #:roots-lambda-and-label-example
   #:roots-direct-subst-example
   #:roots-surprise-example
   #:roots-named-call-double-evaluation-example
   #:roots-dynamic-binding-capture-example

   ;; Ben Lynn browser-runner integration
   #:roots-lynn-runner-asset
   #:roots-lynn-runner-asset-check
   #:roots-lynn-runner-artifact
   #:roots-lynn-runner-status
   #:roots-lynn-runner-surface
   #:make-roots-lynn-runner-artifact
   #:make-roots-lynn-runner-surface
   #:roots-lynn-runner-readiness
   #:roots-lynn-runner-local-public-url
   #:roots-lynn-frame-item-text
   #:roots-lynn-fedwiki-page
   #:roots-lynn-fedwiki-page-json
   #:register-roots-lynn-runtime-asset-path
   #:roots-lynn-runner-public-path-of
   #:roots-lynn-runner-asset-root-of
   #:roots-lynn-runner-manifest-of
   #:roots-lynn-runner-provenance-of
   #:roots-lynn-runner-trust-classification-of
   #:roots-lynn-runner-direct-open-fallback-of
   #:roots-lynn-runner-ready-p-of
   #:roots-lynn-runner-route-ready-p-of
   #:roots-lynn-runner-asset-checks-of
   #:roots-lynn-runner-failures-of
   #:roots-lynn-runner-artifact-of
   #:roots-lynn-runner-fedwiki-page-of
   #:roots-lynn-runner-native-page-of
   #:roots-lynn-runner-common-lisp-report-of
   #:roots-lynn-asset-relative-path-of
   #:roots-lynn-asset-upstream-url-of
   #:roots-lynn-asset-sha256-of
   #:roots-lynn-asset-check-status-of
   #:roots-lynn-asset-check-actual-sha256-of
   #:*roots-lynn-runner-artifact*
   #:*roots-lynn-runner-surface*
   #:*roots-hyperdoc*

   ;; Topics / HyperDoc integration
   #:all-roots-topics
   #:roots-topic-by-id
   #:roots-topic-by-title
   #:roots-of-lisp-topic
   #:roots-seven-primitives-topic
   #:roots-denoting-functions-topic
   #:roots-surprise-topic
   #:roots-stanford-adapter-topic
   #:roots-nine-ideas-topic
   #:roots-corrected-bugs-topic
   #:roots-dynamic-capture-topic
   #:roots-lynn-runner-topic
   #:register-roots-topics-into-hyperdoc
   #:materialize-roots-hyperdoc-pages))

(defpackage #:hyperdoc-graham-roots-of-lisp/tests
  (:use #:cl)
  (:export #:run-roots-of-lisp-smoke-tests))
