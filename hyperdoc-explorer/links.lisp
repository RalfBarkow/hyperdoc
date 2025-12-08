;;;; Link and backlink views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/explorer)

;; Expression links

(defclass expr-link (hbe::object-link)
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
;; Link views
;;

(views:defview 👀links (page page)
  (when-let (links (hd::links-of page))
    (link-view links)))

(views:defview 👀backlinks (page page)
  (let* ((pages (hb:find-backlink-sources (-> page hyperbook-of id-of)
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
                    (let ((page (-> page-link hbe::thunk-of views:eval-thunk)))
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
                  (dolist (link (mapcar #'hbe::url-of web-links))
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

(defmethod find-link-sources ((hd hyperdoc) hyperdoc-id page-id)
  (loop for page being the hash-values of (pages-of hd)
        append (find-link-sources page hyperdoc-id page-id)))

(defmethod find-link-sources ((page page) (hyperdoc-id string) (page-id string))
  (let ((links (hd::links-of page))
        (link-sources ()))
    (dolist (page-link (cdr (assoc :page links)))
      (when (and (string-equal (hbe::target-hyperbook-of page-link) hyperdoc-id)
                 (equal (hbe::target-page-of page-link) page-id))
        (pushnew page link-sources :test #'eq)))
    link-sources))

(defmethod find-link-sources ((page page) (hyperdoc-id string) (page-id null))
  (let ((links (hd::links-of page))
        (link-sources ()))
    (dolist (link (cdr (assoc :hyperdoc links)))
      (when (string-equal (hbe::target-hyperbook-of link) hyperdoc-id)
        (pushnew page link-sources :test #'eq)))
    link-sources))
