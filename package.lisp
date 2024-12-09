;;;; Package definition
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :html-inspector-views/hyperdoc
  (:use :cl :html-inspector-views)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:import-from :cl-who :esc :fmt :htm :str))
