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
           ;; Defining tools
           #:deftool #:html #:markdown #:html-generator
           #:defplayground
           ;; Access to the global catalog of registered HyperDocs
           #:*catalog* #:hyperdocs-of
           ;; Access to HyperDoc data
           #:title-of #:directory-of #:asdf-system-of #:pages-of
           #:hyperdoc-of #:file-of
           ;; HTML page assets
           #:*hyperdoc-html-page-assets*
           ;; Renderer-independent topicmap projections
           #:topicmap-projection
           #:make-topicmap-projection
           #:topicmap-projection-source-of
           #:topicmap-projection-topics-of
           #:topicmap-projection-associations-of
           #:topicmap-projection-view-properties-of
           #:topicmap-topic
           #:make-topicmap-topic
           #:topicmap-topic-id-of
           #:topicmap-topic-type-of
           #:topicmap-topic-label-of
           #:topicmap-topic-object-of
           #:topicmap-topic-temporal-scope-of
           #:topicmap-topic-view-properties-of
           #:topicmap-association
           #:make-topicmap-association
           #:topicmap-association-id-of
           #:topicmap-association-type-of
           #:topicmap-association-from-of
           #:topicmap-association-to-of
           #:topicmap-association-properties-of
           #:topicmap-projection-of
           ;; HyperDoc's own HyperDoc
           #:*hyperdoc*))

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperdoc)
