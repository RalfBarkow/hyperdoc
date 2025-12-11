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
;; Find links to pages
;;

(defmethod find-link-sources ((hd hyperdoc) hyperdoc-id page-id)
  (loop for page being the hash-values of (pages-of hd)
        append (find-link-sources page hyperdoc-id page-id)))

(defmethod find-link-sources ((page page) (hyperdoc-id string) (page-id string))
  (let ((links (links-of page))
        (link-sources ()))
    (dolist (page-link (cdr (assoc :page links)))
      (when (and (string-equal (target-hyperbook-of page-link) hyperdoc-id)
                 (equal (target-page-of page-link) page-id))
        (pushnew page link-sources :test #'eq)))
    link-sources))

(defmethod find-link-sources ((page page) (hyperdoc-id string) (page-id null))
  (let ((links (links-of page))
        (link-sources ()))
    (dolist (link (cdr (assoc :hyperdoc links)))
      (when (string-equal (target-hyperbook-of link) hyperdoc-id)
        (pushnew page link-sources :test #'eq)))
    link-sources))
