;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass html-page (page)
  ((parse-tree :reader parse-tree :initform nil)))

(defmethod page-class ((filetype (eql :html)))
  (find-class 'html-page))

(defmethod load-page ((page html-page))
  (with-slots (file parse-tree) page
    (let ((plump:*tag-dispatchers* plump:*html-tags*))
      (setf parse-tree (plump:parse file))))
  page)

(defmethod page-title ((page html-page))
  (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
            do (let ((elements (-> page
                                   parse-tree
                                   (plump:get-elements-by-tag-name tag))))
                 (when elements
                   (return (-> elements first plump:text)))))
      "Untitled"))

(defview 👀content (page html-page)
  (html-view :title "Content" :priority 1
    (plump:serialize (parse-tree page)
                     html-inspector-views::*html-stream*)))

(defview 👀parse-tree (page html-page)
  (-> page
      parse-tree
      plump-inspector-views::👀children
      (rename :title "Parse tree" :priority 4)))
