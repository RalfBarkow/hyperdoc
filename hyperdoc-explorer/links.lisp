;;;; Link and backlink views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Expression links
;;

(defclass expr-link (object-link)
  ((form :reader form-of :initarg :form)
   (package :reader package-of :initarg :package :type package)))

(defmethod key-of ((link expr-link))
  (cons (form-of link) (package-of link)))

(defun make-expr-link (source-page expr package &optional view)
  (let* ((*package* package)
         (form (parse expr)))
    (make-instance 'expr-link
                   :source-hyperbook (-> source-page hb:hyperbook-of hb:id-of)
                   :source-page (-> source-page hb:id-of)
                   :form form
                   :package package
                   :thunk (views:thunk (let ((*package* package))
                                         (eval-parsed form)))
                   :view view)))

;;
;; View section for expression links
;;

(defmethod hyperbook::link-view-section ((kind (eql :expr)) links)
  (views:html
   (:h2 (Views:esc "Expressions"))
   (views:html-table
    links
    :inspect #'(lambda (l)
                 (-> l thunk-of views:eval-thunk))
    :display (list #'form-of))))

;;
;; Gather link sources across all pages
;;

(defmethod find-link-sources ((hd hyperdoc) hyperbook-id page-id)
  (loop for page being the hash-values of (pages-of hd)
        append (find-link-sources page hyperbook-id page-id)))
