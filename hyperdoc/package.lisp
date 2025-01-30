;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc
  (:use :cl :hyperdoc/core :html-inspector-views)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:import-from :html-inspector-views/standard
   :var-definition)
  (:export :*catalog*
           :*hyperdoc*
           :make-hyperdoc
           :find-page
           :find-hyperdoc
           :register))
