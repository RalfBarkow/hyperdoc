;;;; Markdown pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Markdown pages are parsed, serialized as HTML, and
;; then processed just like HTML pages.
;;

;; The Markdown page class adds nothing to the HTML page
;; class, it just provides a different name for dispatching.

(defclass markdown-page (html-page) ())

;; The page class for file type "md" is markdown-page.

(defmethod page-class ((hyperdoc::hd hyperdoc:hyperdoc) (filetype (eql :md)))
           (declare (ignore hyperdoc::hd)) (find-class (quote markdown-page)))

;;
;; Load a Markdown page into an HTML parse tree.
;;

(defmethod load-page ((page markdown-page))
  (with-slots (file parse-tree links) page
    (let* ((plump:*tag-dispatchers* plump:*html-tags*)
           (text (alexandria:read-file-into-string file))
           (html (with-output-to-string (str)
                   (3bmd:parse-string-and-print-to-stream text str))))
      (setf parse-tree (plump:parse html))
      (set-title page)
      (setf links (hb:extract-links page))))
  page)
