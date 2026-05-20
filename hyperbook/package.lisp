;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperbook
  (:use :cl)
  (:import-from :alexandria
                :if-let :when-let :compose)
  (:import-from :arrow-macros
                :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export ;; The abstract classes and their accessors
   #:hyperbook #:page
   #:id-of #:hyperbook-of #:title-of #:main-page-id-of
   #:links-of
   ;; The catalog API
   #:catalog #:*catalog*
   #:register #:register-scheme #:register-link-redirection
   #:find-backlink-sources #:find-link-sources
   #:hyperbooks-of
   ;; Accessing items
   #:find-page #:find-hyperbook
   #:lookup-path #:path-item-of
   ;; Conditions and their accessors
   #:lookup-failure #:page-lookup-failure #:hyperbook-lookup-failure
   ;; HTML HyperBooks
   #:html-hyperbook #:html-files-of
   ;; Explorer link API
   #:link
   #:source-page-of
   #:source-hyperbook-of
   #:key-of
   #:link-text-of
   #:source-section-of
   #:target-hyperbook-of
   #:target-page-of
   #:object-link
   #:thunk-of
   #:view-of
   #:page-link
   #:hyperbook-link
   #:web-link
   #:url-of
   #:make-page-link
   #:make-hyperbook-link
   #:make-web-link
   #:links
   #:web-links-of
   #:page-links-of
   #:hyperbook-links-of
   #:no-links?
   #:extract-links
   #:lookup-issue
   #:page-lookup-issue
   #:function-lookup-issue
   #:target-grouping-issue
   #:make-page-lookup-issue
   #:make-function-lookup-issue
   #:make-target-grouping-issue
   #:lookup-issue-source-page-title-of
   #:lookup-issue-source-page-id-of
   #:lookup-issue-source-section-of
   #:lookup-issue-link-text-of
   #:lookup-issue-expected-page-id-of
   #:lookup-issue-target-hyperbook-id-of
   #:lookup-issue-target-site-of
   #:lookup-issue-target-kind-of
   #:lookup-issue-classification-of
   #:lookup-issue-status-of
   #:lookup-issue-suggested-repair-of
   #:lookup-issue-repair-description-of
   #:lookup-issue-details-of
   #:lookup-issue-underlying-condition-of
   #:lookup-issue-underlying-message-of
   #:lookup-issue-link-of
   #:lookup-issue-source-object-of
   #:lookup-issue-signature
   #:mark-lookup-issue!
   #:bounded-lookup-issue-current-status-of
   #:bounded-lookup-issue-current-suggested-repair-of
   #:bounded-lookup-issue-current-repair-description-of
   #:bounded-lookup-issue-current-repair-thunk-of
   #:bounded-lookup-issue-current-details-of
   #:enrich-lookup-issue
   #:lookup-issues-of
   #:replace-by-hyperbook-link
   #:register-link-target-rewriter
   #:render-hyperbook-or-page-link
   #:render-source-surface-lines
   #:render-file-source-surface
   #:👀links
   #:👀backlinks
   #:👀lookup-issues
   #:dom-of
   #:html-nodes
   #:render-node
   #:serialize-a-element
   ;; Documentation
   #:*hyperbook*))
