;;;; Minimal HyperBooks with HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(defclass html-page (page)
  ((file :reader file-of :initarg :file)
   (dom :reader dom-of :initarg :dom)
   (links :reader links-of :initarg :links :initform nil)))

(defmethod find-page ((hb html-hyperbook) page-id &key signal-error?)
  (load-pages hb)
  (or (gethash page-id (pages-of hb))
      (and signal-error?
           (error 'page-lookup-failure :hyperbook hb :page-id page-id))))

(defun load-pages (hb)
  (unless (pages-of hb)
    (setf (pages-of hb) (make-hash-table :test #'equal))
    (dolist (file (html-files-of hb))
      (let* ((plump:*tag-dispatchers* plump:*html-tags*)
             (dom (plump:parse file))
             (title (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
                          do (let ((elements (-> dom
                                               (plump:get-elements-by-tag-name tag))))
                               (when elements
                                 (return (-> elements first plump:text))))))
             (page (make-instance 'html-page
                                  :hyperbook hb
                                  :id title
                                  :file file
                                  :dom dom)))
        (setf (slot-value page 'links) (extract-links page))
        (setf (gethash title (pages-of hb)) page)
        (unless (main-page-id-of hb)
          (setf (slot-value hb 'main-page-id) title))))))

(views:defview views:👀content (hb html-hyperbook)
  (load-pages hb)
  (call-next-method))

(views:defview 👀main-page (hb html-hyperbook)
  (load-pages hb)
  (call-next-method))

(views:defview views:👀items (hb html-hyperbook)
  (load-pages hb)
  (-> hb
      pages-of
      alexandria:hash-table-values
      (sort #'string< :key #'id-of)
      views:👀items
      (views:rename :title "Pages" :priority 3)))

(defun include-source-surface-assets ()
  ;; The shared line-numbered source pane uses HyperDoc's source-surface CSS
  ;; when those assets are available in the current runtime.
  (ignore-errors
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc/"))
    (views:include-css "/hyperdoc/css/dom-annotation-connect.css")))

(defun render-source-surface-line (line-number line-text)
  (views:html
    (:div :class "hyperdoc-source-pane-line"
          (:span :class "hyperdoc-source-pane-line-number"
                 (views:esc (format nil "~D" line-number)))
          (:span :class "hyperdoc-source-pane-line-text"
                 (views:esc line-text)))))

(defun render-source-surface-lines (pathname render-line
                                    &key
                                      (wrapper-class "hyperdoc-source-pane"))
  (views:html
    (:div :class wrapper-class
          (loop for line-text in (uiop:read-file-lines pathname)
                for line-number from 1
                do (funcall render-line line-number line-text)))))

(defun render-file-source-surface (pathname)
  (include-source-surface-assets)
  (render-source-surface-lines pathname #'render-source-surface-line))

(views:defview views:👀source (page html-page)
  (views:html-view :title "Source" :priority 10
    (render-file-source-surface (file-of page))))

(defmethod find-link-sources ((hb html-hyperbook) hyperbook-id page-id)
  (load-pages hb)
  (loop for page being the hash-values of (pages-of hb)
        append (find-link-sources page hyperbook-id page-id)))
