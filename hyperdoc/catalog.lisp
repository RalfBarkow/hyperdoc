;;;; The HyperDoc catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The HyperDoc catalog has only one global instance (singleton).
;;

(defclass catalog ()
  ((hyperdocs :accessor hyperdocs-of :initform nil)))

(defvar *catalog*
  (make-instance 'catalog))


;;
;; Registration of HyperDocs
;;

(defun register (hdoc)
  "Register HyperDoc HDOC in the globale HyperDoc catalog."
  (push hdoc (hyperdocs-of *catalog*)))

;;
;; Catalog lookup
;;

(defun find-hyperdoc (title &key signal-error?)
  "Look up the HyperDoc entitled TITLE in the global catalog. If no such HyperDoc
exists, then return NIL if SIGNAL-ERROR? is nil, else signal
hyperdoc-lookup-failure."
  (or (dolist (hd (hyperdocs *catalog*))
        (when (string= title (title hd))
          (return hd)))
      (and signal-error?
           (error 'hyperdoc-lookup-failure :title title))))

(defun find-hyperdoc-in-directory (pathname  &key signal-error?)
  "Look up the HyperDoc whose directory is PATHNAME in the global catalog.
If no such HyperDoc exists, then return NIL if SIGNAL-ERROR? is nil, else
signal directory-lookup-failure."
  (or (dolist (hd (hyperdocs *catalog*))
        (when (equal pathname (hyperdoc-directory hd))
          (return hd)))
      (and signal-error?
           (error 'directory-lookup-failure :catalog *catalog* :pathname pathname))))
