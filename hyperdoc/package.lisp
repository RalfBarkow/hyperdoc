;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc
  (:use :cl)
  (:import-from :alexandria
                :if-let :when-let :compose)
  (:import-from :arrow-macros
                :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:import-from :hyperbook
                #:id #:hyperbook
                #:id-of #:hyperbook-of #:title-of #:main-page-id-of
                #:links-of
                ;; The catalog API
                #:catalog #:*catalog*
                #:register #:find-backlink-sources #:find-link-sources
                ;; Accessing items
                #:find-page #:find-hyperbook
                ;; Conditions and their accessors
                #:lookup-failure #:page-lookup-failure #:hyperbook-lookup-failure)
  (:export ;; Creating and registering HyperDocs
   #:defhyperdoc
   #:make-hyperdoc
   #:data-of
   ;; Referencing HyperDocs and pages from code files
   #:see #:page #:hyperdoc
   ;; Defining examples and using assertions in them
   #:defexample
   #:assert-test #:assert-equalp #:assert-equal
   #:assert-eql #:assert-within-tolerance
   #:run-ci-checks
   ;; Defining tools
   #:deftool #:html #:markdown #:html-generator
   #:defplayground
   ;; Article allegation slice scaffolding
   #:read-article-allegation-slice-input
   #:render-article-allegation-slice-bundle
   #:write-article-allegation-slice-bundle
   ;; DMX MCP server
   #:serve-dmx-mcp-server
   #:stop-dmx-mcp-server
   ;; FedWiki page materialization
   #:plan-fedwiki-page-materialization
   #:plan-fedwiki-slice-materialization
   #:print-fedwiki-materialization-plan
   #:materialize-fedwiki-materialization-plan
   ;; Bibliography subcollections and authoring plans
   #:make-default-bibliography-source
   #:ensure-bibliography-subcollections-hyperbook
   #:plan-bibliography-authoring
   #:materialize-bibliography-authoring-plan
   ;; Documentation validation helpers
   #:topic-coverage-report
   #:documentation-slice-validation-report
   #:documentation-topic-coverage-report
   #:documentation-topic-coverage-pass-p
   #:print-documentation-topic-coverage-report
   #:validate-documentation-slice
   #:semantic-first-anchor-audit-report
   #:semantic-first-anchor-audit-pass-p
   #:print-semantic-first-anchor-audit-report
   #:run-repo-documentation-slice-validation-check
   #:documentation-slice-validation-pass-p
   #:documentation-validation-checks-of
   #:documentation-validation-coverage-report-of
   #:print-documentation-slice-validation-report
   ;; DM6 page-local topicmap seeds
   #:page-dm6-topicmap-source-dom
   #:page-dm6-topicmap-dom-nodes
   #:page-dm6-topicmap-node-label
   #:page-dm6-topicmap-native-model
   #:page-dm6-topicmap-json
   #:insert-or-replace-dm6-stored-script!
   #:dm6-page-topicmap-seed-report
   #:dm6-inline-proof-page-pathname
   #:materialize-dm6-inline-proof-page-topicmap-seed!
   ;; Native source artifacts and generic topicmap projections
   #:file-artifact
   #:make-file-artifact
   #:ensure-file-artifact
   #:relative-path-of
   #:root-of
   #:pathname-of
   #:exists-p
   #:size-of
   #:content-of
   #:content-target-of
   #:source-content
   #:source-content-from-pathname
   #:source-content-from-artifact
   #:source-content-from-object
   #:source-target-of
   #:source-title-of
   #:source-text-of
   #:parsed-topic
   #:parsed-relation
   #:topicmap-projection
   #:inline-topicmap-view
   #:topics-of
   #:relations-of
   #:layout-of
   #:kind-of
   #:source-index-of
   #:source-of
   #:from-of
   #:to-of
   #:evidence-of
   #:projection-of
   #:mode-of
   #:selected-topic-of
   #:input-owner-of
   #:capabilities-of
   #:topicmap-projection-of
   #:topicmap-view-title-of
   #:topicmap-view-input-owner-of
   #:parse-source-content-into-topics
   #:project-source-content-to-topicmap
   #:project-artifact-to-topicmap
   #:project-object-to-topicmap
   #:make-inline-topicmap-view
   #:topicmap-projection-native-model
   #:topicmap-projection-json
   #:render-inline-topicmap-projection-html
   #:render-inline-topicmap-view-html
   #:render-topicmap-view-of-object-html
   #:write-topicmap-view-html
   #:inspect-artifact-content
   #:inspect-topicmap-view
   ;; Mobile progressive chrome reload boundary
   #:mobile-progressive-chrome-page
   #:mobile-progressive-chrome-system-slice
   #:mobile-progressive-chrome-state-model
   #:mobile-progressive-chrome-scxml-artifact
   #:mobile-progressive-chrome-plan
   #:reload-mobile-progressive-chrome-slice
   #:run-mobile-progressive-chrome-slice-checks
   ;; Page-as-ASDF-system reload boundaries
   #:page-system
   #:hyperdoc-page-system
   #:fedwiki-page-system
   #:external-page-system
   #:page-runtime-provider
   #:page-system-registry
   #:page-system-registry-systems
   #:register-page-system
   #:find-page-system
   #:ensure-page-system
   #:page-system-reload
   #:page-system-display-ready-p
   #:page-system-inspection-targets
   #:page-system-validation-checks
   #:page-system-asdf-form
   #:materialize-page-system-asd
   #:page-system-summary
   #:page-system-runtime-systems
   #:page-system-rendered-page
   #:page-system-local-twin-pathname
   #:page-system-id
   #:page-system-title
   #:page-system-kind
   #:page-system-asdf-system-name
   #:page-system-page-locator
   #:page-system-runtime-providers
   #:page-system-runtime-entry-points
   #:page-system-display-contract
   #:page-system-inspection-entry-points
   #:page-system-validation-entry-points
   #:page-system-source-files
   #:page-system-artifacts
   #:page-system-description
   #:page-runtime-provider-id
   #:page-runtime-provider-kind
   #:page-runtime-provider-asdf-system-name
   #:page-runtime-provider-ensure-function
   #:page-runtime-provider-readiness-function
   #:page-runtime-provider-display-notes
   #:page-runtime-provider-source-repo
   #:page-runtime-provider-upstream-url
   #:page-runtime-provider-local-override-note
   #:page-runtime-provider-license-note
   #:page-system-reload-report
   #:page-system-reload-report-page-system
   #:page-system-reload-report-asdf-system-name
   #:page-system-reload-report-loaded-p
   #:page-system-reload-report-display-ready-p
   #:page-system-reload-report-warnings
   #:page-system-latest-reload-report
   #:hyperdoc-runtime-provider
   #:hyperdoc-explorer-runtime-provider
   #:fedwiki-client-runtime-provider
   #:fedwiki-materialization-runtime-provider
   #:shop3-source-root-pathname
   #:ensure-shop3-runtime
   #:shop3-runtime-ready-p
   #:shop3-runtime-provider
   #:hyperdoc-shop3-planning-runtime-provider
   #:make-mobile-progressive-chrome-page-system
   #:make-dm6-appembed-inline-proof-page-system
   #:make-fedwiki-mobile-progressive-chrome-page-system
   #:make-fedwiki-shop3-page-system
   ;; LISP-CRITIC review plan surface
   #:hyperdoc-plan
   #:hyperdoc-task-topic
   #:hyperdoc-plan-task-relation
   #:integrate-lisp-critic-in-review-plan
   #:lisp-critic-review-plan-task-topics
   #:lisp-critic-review-task-topic-by-id
   #:lisp-critic-review-relations-for-task
   #:lisp-critic-review-relations-answering
   #:lisp-critic-review-goldberg-coverage
   #:lisp-critic-fedwiki-asset-present-p
   #:lisp-critic-review-normalize-goldberg-question-id
   ;; LISP-CRITIC source-station critic contract
   #:lisp-critic-source-station
   #:lisp-critic-contract
   #:lisp-critic-run-record
   #:default-lisp-critic-source-station
   #:default-lisp-critic-contract
   #:lisp-critic-source-station-present-p
   #:lisp-critic-contract-available-p
   #:run-lisp-critic-contract
   #:lisp-critic-run-record-status
   #:lisp-critic-run-record-raw-output
   #:lisp-critic-run-record-target-paths
   ;; Access to the global catalog of registered HyperDocs
   #:*catalog* #:hyperdocs-of
   ;; Access to HyperDoc data
   #:title-of #:directory-of #:asdf-system-of #:pages-of
   #:hyperdoc-of #:file-of
   ;; HyperDoc's own HyperDoc
   #:*hyperdoc*))

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperdoc)
