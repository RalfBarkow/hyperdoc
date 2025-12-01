;;;; The HyperDoc catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The HyperDoc catalog has only one global instance (singleton).
;;

(defclass catalog ()
  ((hyperdocs :accessor hyperdocs-of :initform nil :type list)))

(defvar *catalog*
  (make-instance 'catalog))


;;
;; Registration of HyperDocs
;;

(defun register (hdoc)
  "Register HyperDoc HDOC in the global HyperDoc catalog."
  (push hdoc (hyperdocs-of *catalog*)))

;;
;; Catalog lookup
;;

(define-condition hyperdoc-lookup-failure (lookup-failure)
  ((title-or-id :initarg :title-or-id)))

(declaim (ftype (function (string &key (:signal-error? boolean))
                          (or abstract-hyperdoc null))
                find-hyperdoc))

(defun find-hyperdoc (title-or-id &key signal-error?)
  "Look up the TITLE-OR-ID in the global catalog. If no HyperDoc with
that title or id exists, then return NIL if SIGNAL-ERROR? is nil, else
signal hyperdoc-lookup-failure."
  (or (dolist (hd (hyperdocs-of *catalog*))
        (when (or (string= title-or-id (title-of hd))
                  (string-equal title-or-id (id-of hd)))
          (return hd)))
      (and signal-error?
           (error 'hyperdoc-lookup-failure :title-or-id title-or-id))))

;;
;; Link lookup (for backlinks)
;;

(defgeneric find-link-sources (target hyperdoc-id page-title))

(defmethod find-link-sources ((target catalog) hyperdoc-id page-title)
  (loop for hd in (hyperdocs-of target)
        append (find-link-sources hd hyperdoc-id page-title)))

(defun find-backlink-sources (hyperdoc-id &optional page-title)
  (find-link-sources *catalog* hyperdoc-id page-title))
