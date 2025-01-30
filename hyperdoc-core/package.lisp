;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc/core
  (:use :cl :html-inspector-views)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export :*catalog*
           :catalog
           :hyperdocs
           :find-hyperdoc
           :register
           :*hyperdoc*
           :hyperdoc
           :hyperdoc-directory
           :title
           :pages
           :code-files
           :entry
           :make-hyperdoc))
