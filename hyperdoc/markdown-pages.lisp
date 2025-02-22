;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass markdown-page (html-page) ())

(defmethod page-class ((filetype (eql :md)))
  (find-class 'markdown-page))

(defmethod load-page ((page markdown-page))
  (with-slots (file parse-tree) page
    (let* ((plump:*tag-dispatchers* plump:*html-tags*)
          (text (alexandria:read-file-into-string file))
          (html (with-output-to-string (str)
                  (3bmd:parse-string-and-print-to-stream text str))))
      (setf parse-tree (plump:parse html))))
  page)

