;;;; Links in HyperBook pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; The source of each link is a HyperBook page, represented by a pair
;; of two strings, the HyperBook id and the page id.
;;
;; Each link type defines a key, which is the information that uniquely
;; identifies a target. Keys are used for de-duplicating links that
;; point to the same target.
;;

(defclass link ()
  ((source-hyperbook :reader source-hyperbook-of :initarg :source-hyperbook
                     :type string)
   (source-page :reader source-page-of :initarg :source-page
                :type string)
   (link-text :reader link-text-of :initarg :link-text
              :initform nil :type (or null string))
   (source-section :reader source-section-of :initarg :source-section
                   :initform nil :type (or null string))))

(defgeneric key-of (link))

(defun link-signature (link)
  (list (class-name (class-of link))
        (key-of link)
        (source-section-of link)
        (link-text-of link)))

;;
;; A mix-in for links whose target is an object in memory.
;; It stores a thunk that computes the object, and the
;; possibly nil name of the view to preselect.
;;

(defclass object-link (link)
  ((thunk :reader thunk-of :initarg :thunk :type function)
   (view :reader view-of :initarg :view :initform nil :type (or string null))))

;;
;; Page links point to a HyperBook page, defined like the source
;; by a HyperBook id and a page id. The key is a pair combining
;; both ids.
;;

(defclass page-link (object-link)
  ((target-hyperbook :reader target-hyperbook-of :initarg :target-hyperbook
                     :type string)
   (target-page :reader target-page-of :initarg :target-page
                :type string)))

(defmethod key-of ((link page-link))
  (cons (target-hyperbook-of link) (target-page-of link)))

(defmethod views:text-representation ((link page-link))
  (format nil "~A/~A → ~A/~A"
          (source-hyperbook-of link)
          (source-page-of link)
          (target-hyperbook-of link)
          (target-page-of link)))

(defmacro result-or-condition (&body body)
  `(handler-case (progn ,@body)
     (error (c) c)))

(defun make-page-link (source-page target-hyperbook-id target-page-id
                       &key view link-text source-section)
  (make-instance 'page-link
                 :source-hyperbook (-> source-page hyperbook-of id-of)
                 :source-page (-> source-page id-of)
                 :link-text link-text
                 :source-section source-section
                 :target-hyperbook target-hyperbook-id
                 :target-page target-page-id
                 :thunk (views:thunk
                         (result-or-condition
                          (find-page target-hyperbook-id target-page-id
                                     :signal-error? t)))
                 :view view))

;;
;; HyperBook links point to an entire HyperBook, represented by its id
;;

(defclass hyperbook-link (object-link)
  ((target-hyperbook :reader target-hyperbook-of :initarg :target-hyperbook
                     :type string)))

(defmethod key-of ((link hyperbook-link))
  (target-hyperbook-of link))

(defmethod views:text-representation ((link hyperbook-link))
  (format nil "~A/~A → ~A"
          (source-hyperbook-of link)
          (source-page-of link)
          (target-hyperbook-of link)))

(defun make-hyperbook-link (source-page target-hyperbook-id
                            &key view link-text source-section)
  (make-instance 'hyperbook-link
                 :source-hyperbook (-> source-page hyperbook-of id-of)
                 :source-page (-> source-page id-of)
                 :link-text link-text
                 :source-section source-section
                 :target-hyperbook target-hyperbook-id
                 :thunk (views:thunk
                         (result-or-condition
                          (find-hyperbook target-hyperbook-id :signal-error? t)))
                 :view view))

;;
;; Web links point to a URL
;;

(defun local-file-url-p (url)
  (and (stringp url)
       (let* ((uri (handler-case (puri:parse-uri url)
                     (error () nil)))
              (scheme (and uri (puri:uri-scheme uri))))
         (and scheme (string-equal "file" scheme)))))

(defclass web-link (link)
  ((url :reader url-of :initarg :url :type string)))

(defmethod key-of ((link web-link))
  (url-of link))

(defmethod views:text-representation ((link web-link))
  (format nil "~A/~A → ~A"
          (source-hyperbook-of link)
          (source-page-of link)
          (url-of link)))

(defun make-web-link (source-page url &key link-text source-section)
  (make-instance 'web-link
                 :source-hyperbook (-> source-page hyperbook-of id-of)
                 :source-page (-> source-page id-of)
                 :link-text link-text
                 :source-section source-section
                 :url url))

(defun trimmed-node-text (node)
  (let ((text (plump:text node)))
    (and text
         (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return #\Page)
                                     text)))
           (unless (zerop (length trimmed))
             trimmed)))))

(defun heading-node-p (node)
  (and (typep node 'plump:element)
       (member (plump:tag-name node)
               '("h1" "h2" "h3" "h4" "h5" "h6")
               :test #'string-equal)))

(defun source-section-for-link-element (dom target)
  (let ((section nil)
        (found nil))
    (labels ((walk (node)
               (when (and (not found) (typep node 'plump:nesting-node))
                 (when (heading-node-p node)
                   (setf section (trimmed-node-text node)))
                 (when (eq node target)
                   (setf found t))
                 (loop for child across (plump:children node)
                       while (not found)
                       do (walk child)))))
      (walk dom))
    section))

(defun make-link-list (page elements make-fn)
  (let ((dom (dom-of page)))
    (nreverse
     (reduce #'(lambda (links element)
                 (let* ((link-text (trimmed-node-text element))
                        (source-section (and dom
                                             (source-section-for-link-element dom element)))
                        (link (funcall make-fn page element link-text source-section)))
                   (adjoin link
                           links
                           :test #'equal
                           :key #'link-signature)))
             elements
             :initial-value nil))))

;;
;; Extract the links from a page implementing dom-of
;;

(defclass links ()
  ((page-links :reader page-links-of :initarg :page-links :initform nil)
   (hyperbook-links :reader hyperbook-links-of :initarg :hyperbook-links :initform nil)
   (web-links :reader web-links-of :initarg :web-links :initform nil)))

(defmethod page-links-of ((links null))
  nil)

(defmethod hyperbook-links-of ((links null))
  nil)

(defmethod web-links-of ((links null))
  nil)

(defgeneric no-links? (links)
  (:method ((links null))
    t)
  (:method ((links links))
    (and (null (page-links-of links))
         (null (hyperbook-links-of links))
         (null (web-links-of links)))))

(defun extract-links (page)
  (let ((dom (dom-of page)))
    (make-instance 'links
                   :page-links
                   (make-link-list page (lquery:$ dom "a[page]")
                                   #'(lambda (page element link-text source-section)
                                       (let ((hyperbook (or (plump:get-attribute element "hyperbook")
                                                            (-> page hyperbook-of id-of))))
                                         (make-page-link page hyperbook
                                                         (plump:get-attribute element "page")
                                                         :view (plump:get-attribute element "view")
                                                         :link-text link-text
                                                         :source-section source-section))))
                   :hyperbook-links
                   (make-link-list page (lquery:$ dom
                                                  "a[hyperbook]"
                                                  (filter #'(lambda (el)
                                                              (not (plump:has-attribute el "page")))))
                                   #'(lambda (page element link-text source-section)
                                       (make-hyperbook-link page
                                                            (plump:get-attribute element "hyperbook")
                                                            :view (plump:get-attribute element "view")
                                                            :link-text link-text
                                                            :source-section source-section)))
                   :web-links
                   (make-link-list page (lquery:$ dom "a[href]")
                                   #'(lambda (page element link-text source-section)
                                       (make-web-link page
                                                      (plump:get-attribute element "href")
                                                      :link-text link-text
                                                      :source-section source-section))))))

;;
;; Find links
;;

(defmethod find-link-sources ((page page) (hyperbook-id string) (page-id string))
  (reduce #'(lambda (pages link)
              (if (and (equal (target-hyperbook-of link) hyperbook-id)
                       (equal (target-page-of link) page-id))
                  (adjoin page pages :test #'eq)
                  pages))
          (some-> page links-of page-links-of)
          :initial-value nil))

(defmethod find-link-sources ((page page) (hyperbook-id string) (page-id null))
  (reduce #'(lambda (pages link)
              (if (equal (target-hyperbook-of link) hyperbook-id)
                  (adjoin page pages :test #'eq)
                  pages))
          (some-> page links-of hyperbook-links-of)
          :initial-value nil))
