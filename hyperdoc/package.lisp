;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export ;; Implementing HyperDoc variants
           #:abstract-hyperdoc #:abstract-page
           #:register
           #:title-of #:entry-of
           #:find-page
           #:lookup-failure #:page-lookup-failure
           ;; Creating and registering HyperDocs
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
           ;; HyperDoc's own HyperDoc
           #:*hyperdoc*))
