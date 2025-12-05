;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hypertext-cluster-interface
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export ;; Implementing HyperDoc variants
           #:abstract-hyperdoc #:abstract-page
           #:id-of
           ;; The catalog API
           #:catalog #:*catalog*
           #:register #:find-backlink-sources #:find-link-sources
           #:hyperdocs-of
           ;; Accessing items
           #:hyperdoc-of #:title-of #:entry-of
           #:find-page #:find-hyperdoc
           #:lookup-failure #:page-lookup-failure #:cluster-lookup-failure))
