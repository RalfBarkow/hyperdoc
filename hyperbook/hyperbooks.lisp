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
;; HyperBook. Retrieve the ID of that page. If it is NIL,
;; the HyperBook has no main page.
;;

(defgeneric main-page-id-of (hyperbook)
  (:documentation "The ID of the main page of HYPERBOOK.")
  (:method ((hb hyperbook))
    nil))

;;
;; A generic function to retrieve the links for a page.
;; The return value is an alist whose keys are keywords
;; indicating the link type. Standard link types are
;; :page (to a HyperBook page), :hyperbook (to a hyperbook),
;; and :web (a URL). Subclasses can define additional link
;; types.
;;

(defgeneric links-of (page)
  (:method ((page page))
    (declare (ignore page))
    nil))

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

;;
;; Looking up a relative path in a HyperBook
;;

(defgeneric lookup-path (hyperbook path)
  (:documentation "Look up PATH (a list of strings) in HYPERBOOK and return
the object to be shown, which can be a page or something else. A return
value of NIL indicates a lookup failure.")
  ;; The default implementation accepts only one-element paths. It
  ;; interprets the string as a page id and returns the page.
  (:method ((hyperbook hyperbook) path)
    (and (= 1 (length path))
         (find-page hyperbook (first path)))))

(defgeneric path-item-of (page)
  (:documentation "Return the path item that resolves to PAGE.")
  ;; The default implementation returns the page id.
  (:method ((page page))
    (id-of page)))
