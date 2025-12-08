;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperbook/explorer
  (:use :cl :hyperbook)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export #:link #:object-link
           #:make-page-link #:make-hyperbook-link #:make-web-link))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook/explorer)
(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperbook/explorer)
