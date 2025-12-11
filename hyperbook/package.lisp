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
           #:register #:find-backlink-sources #:find-link-sources
           #:hyperbooks-of
           ;; Accessing items
           #:find-page #:find-hyperbook
           ;; Conditions and their accessors
           #:lookup-failure #:page-lookup-failure #:hyperbook-lookup-failure))
