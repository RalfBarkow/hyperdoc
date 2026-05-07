;;;; Page and HyperDoc links embedded in Lisp code
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The macro "see" has special rendering support in HyperDoc.
;; Clicking on its argument opens an inspector on its value.
;; The implementation of "see" is very basic. It wraps the argument
;; expression in a lambda to get it compiled and checked, but not run.
;;

(defmacro see (&body body)
  `(lambda () ,@body))

;;
;; Find pages and HyperDocs from their titles, for use with "see".
;;

;; In order to reduce the dependencies of the core HyperDoc system,
;; these are unimplemented generic functions.

(defgeneric page (id &key hyperbook)
  (:documentation "Look up the page with ID in HYPERBOOK, if given,
or else in the HyperDoc that contains the function call."))

(defgeneric hyperbook (id)
  (:documentation "Look up the HyperBook specified by ID in the catalog of
registered HyperBooks."))

;; The implementation methods are in the system hyperdoc/explorer:

(see (page "Implementation of page and HyperBook links embedded in Lisp code"
           :hyperbook "HyperDoc Explorer"))

;; The use of embedded links is explained in:

(see (page "Writing source code pages"))
