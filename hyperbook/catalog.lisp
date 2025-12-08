;;;; The HyperBook catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; The HyperBook catalog has only one global instance (singleton).
;;

(defclass catalog ()
  ((hyperbooks :accessor hyperbooks-of :initform nil :type list)))

(defvar *catalog*
  (make-instance 'catalog))


;;
;; Registration of HyperBooks
;;

(defun register (hbook)
  "Register HyperBook HBOOK in the global HyperBook catalog."
  (push hbook (hyperbooks-of *catalog*)))

;;
;; Catalog lookup
;;

(define-condition hyperbook-lookup-failure (lookup-failure)
  ((hyperbook-id :initarg :hyperbook-id)))

(declaim (ftype (function (string &key (:signal-error? boolean))
                          (or hyperbook null))
                find-hyperbook))

(defun find-hyperbook (id &key signal-error?)
  "Look up ID in the global catalog. If no HyperBook with
that id exists, then return NIL if SIGNAL-ERROR? is nil, else
signal cluster-lookup-failure."
  (or (dolist (hb (hyperbooks-of *catalog*))
        (when (equal id (id-of hb))
          (return hb)))
      (and signal-error?
           (error 'hyperbook-lookup-failure :hyperbook-id id))))

;;
;; Link lookup (for backlinks)
;;

(defgeneric find-link-sources (target hyperbook-id page-id))

(defmethod find-link-sources ((target catalog) hyperbook-id page-id)
  (loop for hd in (hyperbooks-of target)
        append (find-link-sources hd hyperbook-id page-id)))

(defun find-backlink-sources (hyperbook-id &optional page-id)
  (find-link-sources *catalog* hyperbook-id page-id))
