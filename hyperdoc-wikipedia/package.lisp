;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hypertext/wikipedia
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export :request-wikipedia))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hypertext/wikipedia)

(trivial-package-local-nicknames:add-package-local-nickname
 :hci :hypertext-cluster-interface :hypertext/wikipedia)
