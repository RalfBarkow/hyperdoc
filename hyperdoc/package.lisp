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
           ;; Access to the global catalog of registered HyperDocs
           #:*catalog* #:hyperdocs-of
           ;; Access to HyperDoc data
           #:title-of #:directory-of #:asdf-system-of #:pages-of
           #:hyperdoc-of #:file-of
           ;; HyperDoc's own HyperDoc
           #:*hyperdoc*))

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperdoc)
