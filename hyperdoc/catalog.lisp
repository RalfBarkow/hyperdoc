;;;; Catalog of registered HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The global catalog of HyperDocs
;;

(defclass catalog ()
  ((hyperdocs :accessor hyperdocs :initform (fset:empty-set))))

(defvar *catalog*
  (make-instance 'catalog))

(defmethod text-representation ((catalog catalog))
  "Registered HyperDocs")

;;
;; Registration
;;

(defun register (hdoc)
  (fset:includef (hyperdocs *catalog*) hdoc))

;;
;; Lookup
;;

(defun find-hyperdoc (title)
  (fset:do-set (hd (hyperdocs *catalog*))
    (when (string= title (title hd))
        (return hd))))

;;
;; Item view
;;

(defview 👀items (hdcat catalog)
  (-> hdcat
      hyperdocs
      (fset:sort #'string< :key #'title)
      👀items
      (rename :title "HyperDocs" :priority 1)))
