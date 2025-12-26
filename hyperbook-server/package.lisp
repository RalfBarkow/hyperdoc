;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperbook/server
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export :serve-catalog
           :serve-hyperbooks))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook/server)
