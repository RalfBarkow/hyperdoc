;;;; Link and backlink views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Link classes
;;

(defclass link ()
  ((from-hyperdoc :reader from-hyperdoc-of :initarg :from-hyperdoc
                  :type string)
   (from-page :reader from-page-of :initarg :from-page
              :type string)))

(defgeneric key-of (link))

(defclass object-link (link)
  ((thunk :reader thunk-of :initarg :thunk :type function)
   (view :reader view-of :initarg :view :type (or string null))))

;; Page links

(defclass page-link (object-link)
  ((to-hyperdoc :reader to-hyperdoc-of :initarg :to-hyperdoc
                :type string)
   (to-page :reader to-page-of :initarg :to-page
            :type string)))

(defmethod key-of ((link page-link))
  (cons (to-hyperdoc-of link) (to-page-of link)))

(defmacro result-or-condition (&body body)
  `(handler-case (progn ,@body)
     (error (c) c)))

(defun make-page-link (page to-hyperdoc to-page &optional view)
  (make-instance 'page-link
                 :from-hyperdoc (-> page hyperbook-of id-of)
                 :from-page (-> page title-of)
                 :to-hyperdoc to-hyperdoc
                 :to-page to-page
                 :thunk (views:thunk
                          (let ((hyperdoc (result-or-condition
                                           (find-hyperbook to-hyperdoc))))
                            (result-or-condition
                             (find-page hyperdoc to-page))))
                 :view view))

;; HyperDoc links

(defclass hyperdoc-link (object-link)
  ((to-hyperdoc :reader to-hyperdoc-of :initarg :to-hyperdoc
                :type string)))

(defmethod key-of ((link hyperdoc-link))
  (to-hyperdoc-of link))

(defun make-hyperdoc-link (page to-hyperdoc &optional view)
  (make-instance 'hyperdoc-link
                 :from-hyperdoc (-> page hyperbook-of id-of)
                 :from-page (-> page title-of)
                 :to-hyperdoc to-hyperdoc
                 :thunk (views:thunk
                          (result-or-condition
                            (find-hyperbook to-hyperdoc)))
                 :view view))

;; Web links

(defclass web-link (link)
  ((url :reader url-of :initarg :url :type string)))

(defmethod key-of ((link web-link))
  (url-of link))

(defun make-web-link (page url)
  (make-instance 'web-link
                 :from-hyperdoc (-> page hyperbook-of id-of)
                 :from-page (-> page title-of)
                 :url url))

;; Expression links

(defclass expr-link (object-link)
  ((form :reader form-of :initarg :form)
   (package :reader package-of :initarg :package :type package)))

(defmethod key-of ((link expr-link))
  (cons (form-of link) (package-of link)))

(defun make-expr-link (page expr package &optional view)
  (let* ((*package* package)
         (form (parse expr)))
    (make-instance 'expr-link
                   :from-hyperdoc (-> page hyperbook-of id-of)
                   :from-page (-> page title-of)
                   :form form
                   :package package
                   :thunk (views:thunk (let ((*package* package))
                                         (eval-parsed form)))
                   :view view)))

;;
;; Link views
;;

(views:defview 👀links (page page)
  (when-let (links (links-of page))
    (link-view links)))

(views:defview 👀backlinks (page page)
  (let* ((pages (find-backlink-sources (-> page hyperbook-of id-of)
                                       (-> page title-of)))
         (page-links (mapcar #'(lambda (page)
                                 (make-page-link page
                                                 (-> page hyperbook-of id-of)
                                                 (-> page title-of)))
                             pages)))
    (-> (when page-links `((:page ,@page-links)))
        link-view
        (views:rename :title "Backlinks" :priority 6))))

(defun link-view (links)
  (views:html-view :title "Links" :priority 5
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc/"))
    (views:include-css "/hyperdoc/css/hyperdoc.css")
    (views:html
      (:div :class "hyperdoc-page"
            (when-let (page-links (cdr (assoc :page links)))
              (views:html
                (:h2 (views:esc "Pages"))
                (let ((by-hyperdoc (make-hash-table))
                      lookup-failures)
                  (dolist (page-link page-links)
                    (let ((page (-> page-link thunk-of views:eval-thunk)))
                      (if (typep page 'hb:page)
                          (let ((hd (-> page hyperbook-of)))
                            (alexandria:ensure-gethash hd by-hyperdoc nil)
                            (pushnew page (gethash hd by-hyperdoc)))
                          (pushnew page lookup-failures))))
                  (loop for hd being the hash-keys of by-hyperdoc
                          using (hash-value pages)
                        do (views:html
                             (:table :class "inspector-table"
                               (:tr (:td (:i (views:object-ref hd))))
                               (:tr (:td (views:html-table pages))))))
                  (when lookup-failures
                    (views:html
                      (:h4 "Bad links")
                      (views:html-table lookup-failures))))))
            (when-let (hyperdoc-links (cdr (assoc :hyperdoc links)))
              (views:html
                (:h2 (views:esc "HyperDocs"))
                (views:html-table (mapcar #'(lambda (l)
                                              (-> l thunk-of views:eval-thunk))
                                          hyperdoc-links))))
            (when-let (web-links (cdr (assoc :web links)))
              (views:html
                (:h2 (views:esc "Web links"))
                (:table :class "inspector-table"
                  (dolist (link (mapcar #'url-of web-links))
                    (views:html
                      (:tr (:td (:a :href link :target "_blank"
                                    (views:esc link)))))))))
            (when-let (expr-links (cdr (assoc :expr links)))
              (views:html
                (:h2 (Views:esc "Expressions"))
                (views:html-table expr-links
                                  :inspect #'(lambda (l)
                                               (-> l thunk-of views:eval-thunk))
                                  :display (list #'form-of))))))
    (unless links
      (views:html (views:esc "None"))))  )

;;
;; Find links to pages
;;

(defmethod find-link-sources ((hd hyperdoc) hyperdoc-id page-title)
  (loop for page being the hash-values of (pages-of hd)
        append (find-link-sources page hyperdoc-id page-title)))

(defmethod find-link-sources ((page page) (hyperdoc-id string) (page-title string))
  (let ((links (links-of page))
        (link-sources ()))
    (dolist (page-link (cdr (assoc :page links)))
      (when (and (string-equal (to-hyperdoc-of page-link) hyperdoc-id)
                 (equal (to-page-of page-link) page-title))
        (pushnew page link-sources :test #'eq)))
    link-sources))

(defmethod find-link-sources ((page page) (hyperdoc-id string) (page-title null))
  (let ((links (links-of page))
        (link-sources ()))
    (dolist (link (cdr (assoc :hyperdoc links)))
      (when (string-equal (to-hyperdoc-of link) hyperdoc-id)
        (pushnew page link-sources :test #'eq)))
    link-sources))
