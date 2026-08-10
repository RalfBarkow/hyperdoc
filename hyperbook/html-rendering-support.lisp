;;;; Support infrastructure for extending the HTML rendering system
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(defclass html-page-assets ()
  ((inherit :reader inherit-of :type (or null html-page-assets)
            :initarg :inherit :initform nil)
   (paths :reader paths-of :type list :initarg :paths :initform nil)
   (css :reader css-of :type list :initarg :css :initform nil)
   (js :reader js-of :type list :initarg :js :initform nil)
   (tag-dispatchers :reader tag-dispatchers-of :type (or list symbol)
                    :initarg :tag-dispatchers :initform nil)))

(defvar *hyperbook-html-page-assets*
  (make-instance 'html-page-assets
                 :paths (list (cons "/hyperbook/"
                                    (asdf:system-relative-pathname
                                     :hyperbook
                                     "assets/hyperbook/")))
                 :css '("/hyperbook/css/hyperbook.css")
                 :tag-dispatchers '*hyperbook-tags*))

(defgeneric html-page-assets-of (page-or-class-or-class-name)
  (:method ((page page))
    (html-page-assets-of (hyperbook-of page)))
  (:method ((hb hyperbook))
    *hyperbook-html-page-assets*))
