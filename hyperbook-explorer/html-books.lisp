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
  (-> hb
      pages-of
      alexandria:hash-table-values
      (sort #'string< :key #'id-of)
      views:👀items
      (views:rename :title "Pages" :priority 3)))

(views:defview views:👀source (page html-page)
  (-> page
      file-of
      views:👀content
      (views:rename :title "Source" :priority 10)))
