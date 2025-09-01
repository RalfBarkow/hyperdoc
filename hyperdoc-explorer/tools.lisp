;;;; Tools
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(views:defview views:👀content (tool tool-page)
  (views:html-view :title "Live" :priority 1
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc"))
    (views:include-css "/hyperdoc/css/hyperdoc.css")
    (views:html
      (:div :class "hyperdoc-page"
            (dolist (part (reverse (parts-of tool)))
              (render-tool-part tool (car part) (cdr part)))))))

(defun render-tool-part (tool kind content)
  (ccase kind
    (:html
      (let ((*page-state* (make-instance 'page-state
                                         :package (package-of tool)
                                         :page tool)))
        (plump:serialize
         (let ((plump:*tag-dispatchers* plump:*html-tags*))
           (plump:parse content))
         views::*html-stream*)))
    (:markdown
     (render-tool-part tool :html
                       (with-output-to-string (str)
                         (3bmd:parse-string-and-print-to-stream content str))))
    (:generator
     (funcall content))))
