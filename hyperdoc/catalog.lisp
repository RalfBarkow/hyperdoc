;;;; The HyperDoc catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The HyperDoc catalog has only one global instance ("singleton").
;;

(defclass catalog ()
  ((hyperdocs :accessor hyperdocs :initform nil)))

(defvar *catalog*
  (make-instance 'catalog))


;;
;; Registration of HyperDocs
;;

(defun register (hdoc)
  (push hdoc (hyperdocs *catalog*)))

;;
;; Catalog lookup
;;

(defun find-hyperdoc (title &key signal-error?)
  (or (dolist (hd (hyperdocs *catalog*))
        (when (string= title (title hd))
          (return hd)))
      (and signal-error?
           (error 'hyperdoc-lookup-failure :title title))))

(defun find-hyperdoc-in-directory (pathname  &key signal-error?)
  (or (dolist (hd (hyperdocs *catalog*))
        (when (equal pathname (hyperdoc-directory hd))
          (return hd)))
      (and signal-error?
           (error 'directory-lookup-failure :catalog *catalog* :pathname pathname))))
