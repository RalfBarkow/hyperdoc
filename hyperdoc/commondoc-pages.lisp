;;;; CommonDoc pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass commondoc-page (page)
  ((document :reader document :initform nil)))

(defclass scriba-page (commondoc-page)
  ())

(defmethod page-class ((filetype (eql :scr)))
  (find-class 'scriba-page))

(defmethod load-page ((page scriba-page))
  (with-slots (file document) page
    (let ((*current-page* page))
      (setf document (parse-and-expand file))))
  page)

(defun parse-and-expand (file)
  (let* ((format (make-instance 'scriba:scriba))
         (document (common-doc.format:parse-document format file)))
    (common-doc.macro:expand-macros document)))

(defmethod page-title ((page commondoc-page))
  (-> page
      document
      common-doc:title))

(defclass emitter-state ()
  ((package :initarg :package)
   (page :initarg :page)))

(defvar *emitter-state* nil)

(defview 👀content (page commondoc-page)
  (html-view :title "Content" :priority 1
    (add-asset-path "/hyperdoc/"
                    (asdf:system-relative-pathname
                     :hyperdoc
                     "assets/hyperdoc"))
    (include-css "/hyperdoc/css/hyperdoc.css")
    (html
      (:div :class "hyperdoc-page"
            (:h1 (esc (page-title page)))
            (let ((*emitter-state* (make-instance 'emitter-state
                                                  :package (find-package "CL-USER")
                                                  :page page))
                  ;; The page title is <h1>, so section titles need to start with <h2>
                  (common-html.emitter::*section-depth* 2)
                  ;; The output stream is the one used by cl-who
                  (common-html.emitter::*output-stream* html-inspector-views::*html-stream*))
              ;; Don't use common-doc.format:emit-document here. It creates an
              ;; HTML string for the document and in the end sends it to the
              ;; specified output string. This interferes with the implementation
              ;; of object references. Moreover, it creates a !DOCTYPE tag for
              ;; an independent document, whereas we want a snippet that goes
              ;; into a view.
              (common-html.emitter::emit (common-doc:children (document page))))))))

(defview 👀document (page commondoc-page)
  (-> page
      document
      👀items
      (rename :title "CommonDoc" :priority 4)))
