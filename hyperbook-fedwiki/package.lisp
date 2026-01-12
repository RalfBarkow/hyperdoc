;;;; Package definition
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperbook/fedwiki
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook/fedwiki)

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperbook/fedwiki)
