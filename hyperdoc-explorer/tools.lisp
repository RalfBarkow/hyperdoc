;;;; Tools
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/explorer)

;;
;; Tool pages
;;

(views:defview views:👀content (tool hd::tool-page)
  (views:html-view :title "Live" :priority 1
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc/"))
    (views:include-css "/hyperdoc/css/hyperdoc.css")
    (views:html
      (:div :class "hyperdoc-page"
            (dolist (part (reverse (hd::parts-of tool)))
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

(defmethod parse-tree-of ((page hd::tool-page))
  (let ((root (plump:make-root)))
    (dolist (part (reverse (hd::parts-of page)))
      (when-let (parsed-part (parse-tool-part page (car part) (cdr part)))
        (loop for element across (plump:children parsed-part)
              do (plump:append-child root element))))
    root))

(defun parse-tool-part (tool kind content)
  (case kind
    (:html
      (let ((*page-state* (make-instance 'page-state
                                         :package (package-of tool)
                                         :page tool)))
        (let ((plump:*tag-dispatchers* plump:*html-tags*))
          (plump:parse content))))
    (:markdown
     (parse-tool-part tool :html
                      (with-output-to-string (str)
                        (3bmd:parse-string-and-print-to-stream content str))))
    (:generator nil)))

(defmethod load-page ((page hd::tool-page))
  (extract-links page))

;;
;; Playground pages
;;

(views:defview views:👀playground (pg hd::playground-page)
  (let ((view (call-next-method)))
    ;; Move playground view to the first position,
    ;; with its tab in non-dimmed text.
    (views:rename view :title "Playground" :priority 1)))

(defmethod views/standard:playground-package ((pg hd::playground-page))
  (find-package "CL-USER"))

(defmethod views/standard:initial-playground-content ((pg hd::playground-page))
  (hd::initial-content-of pg))

(defmethod views:title-bar-action-buttons ((pg hd::playground-page))
  (views:action-button "Reset"
                       (views:thunk (views/standard:store-playground-content
                                     pg (hd::initial-content-of pg))
                         t)
                       "Reset to initial content"))

(defmethod load-page ((page hd::playground-page))
  (declare (ignore page)))
