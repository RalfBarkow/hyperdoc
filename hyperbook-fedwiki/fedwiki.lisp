;;;; HyperBook interface for Federated Wiki
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Implementation of the HyperBook interface
;;

(defclass fedwiki (hb:hyperbook)
  ((pages :reader pages-of :type hash-table :initform (make-hash-table :test #'equal))
   (slugs :reader slugs-of :type hash-table :initform (make-hash-table :test #'equal))))

(defclass fedwiki-page (hb:page)
 ((slug :reader slug-of :type string :initarg :slug)
  (date :reader date-of :type (or null local-time:timestamp) :initarg :date)
  (synopsis :reader synopsis-of :type string :initarg :synopsis)
  (dom :reader hb:dom-of :type (or null plump:node) :initform nil)
  (links :reader hb:links-of :type (or null hb:links) :initform nil)))

(defmethod hb:title-of ((wiki fedwiki))
  (hb:id-of wiki))

(defmethod hb:title-of ((page fedwiki-page))
  (hb:id-of page))

(defmethod hb:main-page-id-of ((wiki fedwiki))
  "Welcome Visitors")

(defmethod hb:find-page ((wiki fedwiki) id  &key signal-error?)
  (or (gethash id (pages-of wiki))
      (and signal-error?
           (error 'page-lookup-failure :hyperbook wiki :page-id id))))

;;
;; Create a fedwiki proxy
;;

(defun make-fedwiki (domain-name)
  (let* ((wiki (make-instance 'fedwiki
                              :id domain-name))
         (response  (multiple-value-list
                     (drakma:http-request (make-wiki-url domain-name
                                                         "/system/sitemap.json")
                                          :method :get
                                          :want-stream t)))
         (stream (first response))
         (sitemap (shasht:read-json stream)))
    (loop for page-spec across sitemap
          for page = (make-instance 'fedwiki-page
                                    :hyperbook wiki
                                    :id (gethash "title" page-spec)
                                    :slug (gethash "slug" page-spec)
                                    :date (wiki-date-to-timestamp
                                          (gethash "date" page-spec))
                                    :synopsis (gethash "synopsis" page-spec))
          do (setf (gethash (hb:id-of page) (pages-of wiki)) page)
             (setf (gethash (slug-of page) (slugs-of wiki)) (hb:id-of page))
             (setf (gethash (hb:id-of page) (slugs-of wiki)) (slug-of page)))
    wiki))

(defun make-wiki-url (domain-name local-url)
  (assert (str:starts-with? "/" local-url))
  (assert (not (str:ends-with? "/" domain-name)))
  (format nil "http://~A~A" domain-name local-url))

(defun wiki-date-to-timestamp (date)
  (and date
       (local-time:unix-to-timestamp (round (/ date 1000)))))

;;
;; Load and display pages
;;

(defmethod views:👀content ((page fedwiki-page))
  (load-page page)
  (call-next-method))

(defmethod hb:👀links ((page fedwiki-page))
  (load-page page)
  (call-next-method))

(defun load-page (page)
  (unless (hb:dom-of page)
    (let* ((wiki (hb:hyperbook-of page))
           (id (hb:id-of page))
           (page-html (get-page-html wiki id))
           (dom (plump:parse page-html)))
      ;; (adapt-dom dom (hb:hyperbook-of page) id)
      (setf (slot-value page 'dom) dom)
      (setf (slot-value page 'links) (hb:extract-links page)))))

(defun get-page-html (wiki page-title)
  (let* ((slug (gethash page-title (slugs-of wiki)))
         (url (make-wiki-url (domain-name-of wiki)
                             (str:concat "/" slug ".html"))))
    (drakma:http-request url :method :get)))

(defun domain-name-of (wiki)
  (hb:id-of wiki))
