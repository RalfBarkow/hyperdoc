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
   #:example-entry
   #:example-result
   #:example-run
   #:example-source-reference
   #:register-example
   #:discover-examples
   #:make-example-run
   #:make-example-source-reference
   #:run-example-entry
   #:run-example-run!
   #:run-examples
   #:example-entry-system-of
   #:example-entry-id-of
   #:example-entry-title-of
   #:example-entry-function-of
   #:example-entry-locator-of
   #:example-entry-package-of
   #:example-entry-source-file-of
   #:example-entry-source-page-of
   #:example-entry-tags-of
   #:example-entry-class-or-group-of
   #:example-result-entry-of
   #:example-result-status-of
   #:example-result-value-of
   #:example-result-condition-of
   #:example-result-backtrace-of
   #:example-result-duration-ms-of
   #:example-result-assertions-of
   #:example-run-system-of
   #:example-run-entries-of
   #:example-run-results-of
   #:example-run-started-at-of
   #:example-run-finished-at-of
   #:example-run-summary-of
   #:example-source-reference-entry-of
   #:example-source-reference-function-of
   #:example-source-reference-locator-of
   #:example-source-reference-source-file-of
   #:example-source-reference-source-page-of
   #:example-source-reference-tags-of
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
   ;; DMX logical query layer and read-only topic inventory
   #:dmx-store-target
   #:dmx-neo4j-store-target
   #:dmx-http-store-target
   #:dmx-sqlite-query-store
   #:dmx-memory-store-target
   #:dmx-topic-row
   #:dmx-query
   #:dmx-query-run
   #:dmx-sync-plan
   #:dmx-sync-plan-item
   #:dmx-query-topic-materialization
   #:description-of
   #:dmx-run-query
   #:dmx-list-unassigned-topics
   #:dmx-store-topic-row
   #:dmx-persist-query-run
   #:dmx-load-query-runs
   #:dmx-compare-topic-stores
   #:dmx-plan-topic-sync
   #:dmx-materialize-query-as-topic
   #:dmx-persist-sync-plan
   #:make-local-dmx-neo4j-query-target
   #:make-local-dmx-http-query-target
   #:make-remote-dmx-http-query-target
   #:make-dmx-query-sqlite-store
   #:make-dmx-memory-query-target
   #:make-dmx-unassigned-topics-query
   #:list-local-dmx-unassigned-topics
   #:record-local-dmx-unassigned-topic-query
   #:plan-local-to-remote-dmx-unassigned-topic-sync
   #:dmx-neo4j-store-target-app-root-of
   #:dmx-neo4j-store-target-store-path-of
   #:dmx-neo4j-store-target-java-home-of
   #:dmx-neo4j-store-target-helper-source-path-of
   #:dmx-neo4j-store-target-helper-build-root-of
   #:dmx-http-store-target-base-url-of
   #:dmx-http-store-target-username-of
   #:dmx-http-store-target-credential-mode-of
   #:dmx-http-store-target-default-topicmap-id-of
   #:dmx-http-store-target-default-workspace-id-of
   #:dmx-sqlite-query-store-db-path-of
   #:dmx-sqlite-query-store-sqlite-program-of
   #:dmx-topic-row-store-id-of
   #:dmx-topic-row-backend-kind-of
   #:dmx-topic-row-topic-id-of
   #:dmx-topic-row-uri-of
   #:dmx-topic-row-type-uri-of
   #:dmx-topic-row-value-of
   #:dmx-topic-row-workspace-id-of
   #:dmx-topic-row-workspace-status-of
   #:dmx-topic-row-topicmap-ids-of
   #:dmx-topic-row-ownership-class-of
   #:dmx-topic-row-raw-source-of
   #:dmx-topic-row-evidence-path-of
   #:dmx-query-kind-of
   #:dmx-query-parameters-of
   #:dmx-query-created-at-of
   #:dmx-query-run-query-of
   #:dmx-query-run-source-target-of
   #:dmx-query-run-status-of
   #:dmx-query-run-rows-of
   #:dmx-query-run-command-records-of
   #:dmx-query-run-http-records-of
   #:dmx-query-run-raw-request-of
   #:dmx-query-run-raw-response-of
   #:dmx-query-run-executed-at-of
   #:dmx-query-run-error-detail-of
   #:dmx-sync-plan-source-target-of
   #:dmx-sync-plan-target-target-of
   #:dmx-sync-plan-query-run-a-of
   #:dmx-sync-plan-query-run-b-of
   #:dmx-sync-plan-items-of
   #:dmx-sync-plan-status-of
   #:dmx-sync-plan-item-uri-of
   #:dmx-sync-plan-item-source-row-of
   #:dmx-sync-plan-item-target-row-of
   #:dmx-sync-plan-item-action-of
   #:dmx-sync-plan-item-reason-of
   #:dmx-sync-plan-item-safe-p
   #:dmx-ensure-sqlite-query-schema
   #:dmx-sqlite-schema-status
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
   ;; FedWiki-attached ASDF system homes
   #:fedwiki-attached-asdf-system
   #:fedwiki-asdf-system-lookup-failure
   #:fedwiki-page-asset-root
   #:fedwiki-page-asdf-entrypoint
   #:make-fedwiki-attached-asdf-system
   #:load-fedwiki-attached-asdf-system
   #:asdf-system-home-page-of
   #:fedwiki-attached-asdf-system-slug
   #:fedwiki-attached-asdf-system-site-root
   #:fedwiki-attached-asdf-system-system-name
   #:fedwiki-attached-asdf-system-system-file
   #:fedwiki-attached-asdf-system-test-system-name
   #:fedwiki-attached-asdf-system-package-name
   #:fedwiki-attached-asdf-system-compatibility-system-name
   #:fedwiki-attached-asdf-system-previous-object
   #:fedwiki-attached-asdf-system-source-directory
   #:fedwiki-attached-asdf-system-state
   #:fedwiki-attached-asdf-system-available-actions
   #:fedwiki-attached-asdf-system-available-examples
   #:fedwiki-attached-asdf-system-available-tests
   #:fedwiki-attached-asdf-system-route-trace
   #:fedwiki-attached-asdf-system-candidate-routes
   #:fedwiki-attached-asdf-system-home-page-text
   #:fedwiki-asdf-lookup-failure-home
   #:fedwiki-asdf-lookup-failure-routes
   #:fedwiki-asdf-lookup-failure-condition
   #:fedwiki-asdf-lookup-failure-home-page
   #:fedwiki-asdf-lookup-failure-text
   ;; FedWiki page-local ASDF asset writer
   #:page-asdf-asset-spec
   #:page-asdf-asset-spec-system-name
   #:page-asdf-asset-spec-page-slug
   #:page-asdf-asset-spec-page-title
   #:page-asdf-asset-spec-asset-root
   #:page-asdf-asset-spec-source-topic-id
   #:page-asdf-asset-spec-files
   #:page-asdf-asset-spec-tests
   #:page-asdf-asset-spec-rendered-pages
   #:page-asdf-asset-spec-zip-name
   #:fedwiki-page-assets-directory
   #:make-page-asdf-asset-spec
   #:write-page-asdf-system
   #:load-page-asdf-system
   #:test-page-asdf-system
   #:inspect-page-asdf-system
   #:write-page-asdf-rendered-artifacts
   #:build-page-asdf-asset-zip
   #:deploy-page-asdf-asset-zip
   #:page-asdf-asset-workflow
   #:make-metagraph-jsonld-fluree-asset-spec
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
