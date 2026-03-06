;;;; The HyperBook catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; The HyperBook catalog has only one global instance (singleton).
;;

(defclass catalog ()
  ((hyperbooks :accessor hyperbooks-of
               :initform nil
               :type list)
   (factories :accessor factories-of
              :initform (make-hash-table :test #'equal)
              :type hash-table)
   (link-redirections :accessor link-redirections-of
                      :initform nil
                      :type list)))

(defvar *catalog*
  (make-instance 'catalog))


;;
;; Registration of HyperBooks, HyperBook schemes, and link redirections
;;
;; HyperBook ids are URIs. A non-empty scheme means that the id
;; is passed to the factory registered for that scheme.
;;

(defgeneric register (hbook)
  (:documentation  "Register HyperBook HBOOK in the global HyperBook catalog.")
  (:method ((hbook hyperbook))
    (pushnew hbook (hyperbooks-of *catalog*) :key #'id-of :test #'equal)))

(defun register-scheme (scheme factory)
  "Register FACTORY for SCHEME."
  (setf (gethash scheme (factories-of *catalog*)) factory))

(defun register-link-redirection (fn)
  "Register FN as a link redirection. FN will be called with a
   single string argument (a URL). Its return value must be
   NIL (no redirection), or a list of one or two strings, a
   HyperBook id and optionally a page id."
  (pushnew fn (link-redirections-of *catalog*)))

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
  (let* ((uri (puri:parse-uri id))
         (scheme (puri:uri-scheme uri))
         (path (puri:uri-path uri)))
    ;; First, look up the id in the catalog.
    (or (find id (hyperbooks-of *catalog*) :key #'id-of :test #'equal)
        ;; If not found, but the id has a scheme,
        ;; call the factory function.
        (when scheme
          (when-let (factory (gethash scheme (factories-of *catalog*)))
            (when-let (hb (funcall factory path signal-error?))
              (register hb)
              hb)))
        ;; Otherwise, signal an error if requested.
        (and signal-error?
             (error 'hyperbook-lookup-failure :hyperbook-id id)))))

;;
;; Link lookup (for backlinks)
;;

(defgeneric find-link-sources (target hyperbook-id page-id))

(defmethod find-link-sources ((target catalog) hyperbook-id page-id)
  (loop for hd in (hyperbooks-of target)
        append (find-link-sources hd hyperbook-id page-id)))

(defmethod find-link-sources ((target hyperbook) hyperbook-id page-id)
  (declare (ignore target hyperbook-id page-id))
  nil)

(defun find-backlink-sources (hyperbook-id &optional page-id)
  (find-link-sources *catalog* hyperbook-id page-id))
