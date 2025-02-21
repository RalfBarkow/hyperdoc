;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass html-page (page)
   ())

(defmethod page-class ((filetype (eql :html)))
  (find-class 'html-page))

(defmethod load-page ((page html-page))
  page)

(defmethod page-title ((page html-page))
  "HTML page title")

(defview 👀content (page html-page)
  nil)
