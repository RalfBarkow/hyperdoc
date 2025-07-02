;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc
  (:use :cl)
  (:import-from :alexandria
   :if-let :when-let :compose)
  (:import-from :arrow-macros
   :-> :-<> :->> :-<>> :<> :some-> :some->>)
  (:export #:*hyperdoc*
           #:*catalog*
           #:make-hyperdoc
           #:title #:directory #:asdf-system
           #:register
           #:defhyperdoc
           #:hyperdocs
           #:see #:page #:hyperdoc
           #:defexample
           #:assert-test #:assert-equalp #:assert-equal
           #:assert-eql #:assert-within-tolerance
           #:*development-features*))
