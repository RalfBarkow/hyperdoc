;;;; A Reference Is Not Necessarily a Widget
(in-package #:dreyeck/inspector/topicmap/tala)

(hyperdoc:see (hyperdoc:page "A Reference Is Not Necessarily a Widget"))

(defun page-widget-references (view)
  "The references of VIEW that are executable page widgets.
A page link retains the page object and an EXPR link retains the object
it names, so VIEW-REFERENCES answers a wider question than \"which
widgets does this page have\". Only a reference whose object is itself a
view can be rendered and run."
  (remove-if-not (lambda (reference)
                   (typep (cdr reference) 'views:view))
                 (views:view-references view)))

(defun classify-page-references (view)
  "Each reference of VIEW beside the runtime type of the object it kept."
  (mapcar (lambda (reference)
            (let ((object (cdr reference)))
              (list :id (car reference)
                    :runtime-type (type-of object)
                    :widget-p (and (typep object 'views:view) t)
                    :object object)))
          (views:view-references view)))

(defun reading-page-content-view (page-id)
  "The rendered Content view of PAGE-ID in the TALA reading book.
References are collected while a view renders, so the HTML is produced
before the references are read."
  (let* ((book (hyperbook:find-hyperbook "dreyeck/topicmap/tala/reading"
                                         :signal-error? t))
         (page (hyperbook:find-page book page-id :signal-error? t))
         (view (find "Content" (views:all-views page)
                     :key #'views:view-title :test #'string=)))
    (views:view-html view)
    view))

(defun page-reference-report (page-id)
  "How many references PAGE-ID has, how many of them are widgets, and why."
  (let ((view (reading-page-content-view page-id)))
    (list :page page-id
          :references (length (views:view-references view))
          :widgets (length (page-widget-references view))
          :entries (classify-page-references view))))

(hyperdoc:defexample reading-page-reference-classification
  (mapcar #'page-reference-report
          '("From DEFVIEW to Generic Dispatch"
            "Reading TALA as a Layout Layer")))
