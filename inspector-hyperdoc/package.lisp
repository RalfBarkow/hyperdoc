;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc/inspector
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export :hyperdoc
           :hyperspec-http-root
           :hyperspec-root-pathname))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperdoc/inspector)

(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperdoc/inspector)
