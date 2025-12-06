;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperbook/wikipedia
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export :request-wikipedia))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook/wikipedia)

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperbook/wikipedia)
