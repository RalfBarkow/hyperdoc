;;;; Page and HyperDoc links embedded in Lisp code 
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;; Wrap the expression in a lambda to get it compiled and checked,
;; but not run.
(defmacro see (&body body)
  `(lambda () ,@body))

;;
;; Find a page from its title and HyperDoc title
;; The implementation is in hyperdoc/explorer.
;;

(defgeneric page (title &key hyperdoc))

;;
;; Find a HyperDoc from its title
;; The implementation is in hyperdoc/explorer.
;;

(defgeneric hyperdoc (title))

