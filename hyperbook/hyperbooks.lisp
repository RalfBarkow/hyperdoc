;;;; HyperBooks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; A HyperBook is a collection of pages that can contain links to pages
;; in the same HyperBook or in other HyperBooks. A central HyperBook catalog
;; enables backlink detection across HyperBooks.
;;
;; This system contains only an abstract interface for HyperBooks and the
;; implementation of the catalog. Specific HyperBooks can be implemented
;; on top of this.
;;

;;
;; Abstract base classes for HyperBooks and their pages
;;
;; Each HyperBook is identified by a unique ID (a string). Each page
;; in a HyperBook is identifier by an ID (a string) that must be unique
;; inside the HyperBook.
;;

(defclass hyperbook ()
  ((id :reader id-of :type string :initarg :id)))

(defclass page ()
  ((hyperbook :reader hyperbook-of :type hyperbook :initarg :hyperbook)
   (id :reader id-of :type string :initarg :id)))

;;
;; HyperBooks and their pages have titles. In most places in a UI, the titles
;; rather than the IDs are displayed. A default implementation returns the
;; ID as a title.
;;

(defgeneric title-of (item)
  (:documentation "The title of ITEM.")
  (:method ((item hyperbook))
    (id-of item))
  (:method ((item page))
    (id-of item)))

;;
;; HyperBooks have a main page that is shown when viewing the
;; HyperBook. Retrieve the ID of that page.
;;

(defgeneric main-page-id-of (hyperbook)
  (:documentation "The ID of the main page of HYPERBOOK."))

;;
;; Finding a page in a HyperBook
;;

(define-condition lookup-failure (error) ())

(define-condition page-lookup-failure (lookup-failure)
  ((hyperbook :initarg :hyperbook :type hyperbook)
   (page-id :initarg :page-id :type string)))

(defgeneric find-page (hyperbook page-id &key signal-error?)
  (:documentation "Look up PAGE-ID in HYPERBOOK and return the page if found.
If no page with PAGE-ID exists, return NIL if SIGNAL-ERROR is NIL,
otherwise signal PAGE-LOOKUP-FAILURE."))

