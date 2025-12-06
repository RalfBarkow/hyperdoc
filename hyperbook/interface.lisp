;;;; HyperBook interface
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; An abstract interface for minimal HyperDoc functionality.
;; This is meant to be used for implementing hypertext units
;; that are different from HyperDoc but interoperable.
;;

;;
;; Abstract base classes for HyperDocs and their pages
;;
(defclass abstract-hyperdoc ()
  ((id :reader id-of :type string :initarg :id)))

(defclass abstract-page ()
  ((hyperdoc :reader hyperdoc-of :type abstract-hyperdoc :initarg :hyperdoc)))

;;
;; Retrieving the title of a HyperDoc
;;

(defgeneric title-of (hyperdoc)
  (:documentation "The title of HYPERDOC."))

;;
;; Retrieving the entry page of a HyperDoc
;;

(defgeneric entry-of (hyperdoc)
  (:documentation "The entry page of HYPERDOC."))

;;
;; Finding a page in a HyperDoc
;;

(define-condition lookup-failure (error) ())

(define-condition page-lookup-failure (lookup-failure)
  ((hyperdoc :initarg :hyperdoc :type abstract-hyperdoc)
   (page-title :initarg :title :type string)))

(defgeneric find-page (hyperdoc title &key signal-error?)
  (:documentation "Look up TITLE in HYPERDOC and return the page if found.
If no page with TITLE exists, return NIL if SIGNAL-ERROR is NIL, otherwise signal
PAGE-LOOKUP-FAILURE."))

