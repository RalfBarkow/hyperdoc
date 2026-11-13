;;;; Package definition
;;
;;;; Copyright (c) 2025-2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

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
   ;; HTML rendering support
   #:html-page-assets #:html-page-assets-of #:*HYPERBOOK-HTML-PAGE-ASSETS*
   ;; Documentation
   #:*hyperbook*
   ;; Symbols defined in system hyperbook/explorer
   #:link #:source-page-of #:target-hyperbook-of #:target-page-of #:key-of
   #:object-link #:thunk-of #:view-of
   #:page-link
   #:hyperbook-link
   #:web-link #:url-of
   #:make-page-link
   #:make-hyperbook-link
   #:make-web-link
   #:links #:web-links-of #:page-links-of #:hyperbook-links-of
   #:no-links?
   #:extract-links
   #:replace-by-hyperbook-link
   #:render-hyperbook-or-page-link
   #:👀links
   #:👀backlinks
   #:dom-of
   #:html-nodes
   #:render-node
   #:serialize-a-element
   #:serialize-page-dom
   #:*current-page*
   #:*current-hyperbook*))
