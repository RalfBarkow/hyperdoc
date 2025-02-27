;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc
  (:use :cl :html-inspector-views)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export :*hyperdoc*
           :*catalog* :catalog
           :make-hyperdoc
           :load-pages
           :find-page
           :find-hyperdoc
           :register
           :hyperdoc :page
           :hyperdoc-directory
           :title
           :pages
           :code-files
           :entry))
