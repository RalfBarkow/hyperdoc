;;;; HyperBook interface for Federated Wiki
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Implementation of the HyperBook interface
;;

(defclass fedwiki (hb:hyperbook)
  ((pages :reader pages-of :type hash-table :initform (make-hash-table :test #'equal))
   (slugs :reader slugs-of :type hash-table :initform (make-hash-table :test #'equal))
   (status :accessor status-of :initform nil)))

(defclass fedwiki-page (hb:page)
 ((slug :reader slug-of :type string :initarg :slug)
  (date :reader date-of :type (or null local-time:timestamp) :initarg :date)
  (synopsis :reader synopsis-of :type string :initarg :synopsis)
  (dom :reader hb:dom-of :type (or null plump:node) :initform nil)
  (links :reader hb:links-of :type (or null hb:links) :initform nil)
  (journal :reader journal-of :type vector)
  (context :reader context-of :type list)))

(defun domain-name-of (wiki)
  (->> wiki
    hb:id-of
    (str:split ":")
    second))

(defmethod hb:title-of ((wiki fedwiki))
  (domain-name-of wiki))

(defmethod hb:title-of ((page fedwiki-page))
  (hb:id-of page))

(defmethod hb:main-page-id-of ((wiki fedwiki))
  "Welcome Visitors")

(defmethod hb:find-page ((wiki fedwiki) id  &key signal-error?)
  (wait-for-sitemap wiki)
  (or (gethash id (pages-of wiki))
      (and signal-error?
           (error 'page-lookup-failure :hyperbook wiki :page-id id))))

(defun wait-for-sitemap (wiki)
  (let ((status (status-of wiki)))
    (when (typep status 'bt:thread)
      (bt:join-thread status))))

;;
;; Create a fedwiki proxy
;;

(defparameter *uri-scheme* "fedwiki:")

(defun make-fedwiki (domain-name)
  (let* ((wiki (make-instance 'fedwiki
                              :id (str:concat *uri-scheme* domain-name))))
    (setf (status-of wiki)
          (bt:make-thread #'(lambda () (get-sitemap wiki))))
    wiki))

(defun get-sitemap (wiki)
  (handler-case
      (let* ((response  (multiple-value-list
                         (drakma:http-request (make-wiki-url (domain-name-of wiki)
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
        (setf (status-of wiki) t))
    ((or stream-error
      usocket:timeout-error
      usocket:ns-host-not-found-error) (c)
      (setf (status-of wiki) c))))

(defun make-wiki-url (domain-name local-url)
  (assert (str:starts-with? "/" local-url))
  (assert (not (str:ends-with? "/" domain-name)))
  (format nil "http://~A~A" domain-name local-url))

(defun wiki-date-to-timestamp (date)
  (and date
       (local-time:unix-to-timestamp (round (/ date 1000)))))

;;
;; Global register of visited FedWiki sites
;; stored as a mapping from domain name to fedwiki object
;;

(defvar *neighborhood* (make-hash-table :test #'equal))

(defun get-fedwiki (domain-name &optional signal-error?)
  (declare (ignore signal-error?))
  (if-let (fedwiki (gethash domain-name *neighborhood*))
    fedwiki
    (setf (gethash domain-name *neighborhood*)
          (make-fedwiki domain-name))))

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
           (page-json (get-page-json wiki id))
           (page-html (get-page-html wiki id))
           (dom (plump:parse page-html)))
      (setf (slot-value page 'journal)
            (make-journal (gethash "journal" page-json)))
      ;; The context is used in adapting the DOM, so it
      ;; must be prepared first.
      (setf (slot-value page 'context)
            (extract-context (journal-of page)))
      (setf (slot-value page 'dom) dom)
      (adapt-dom page)
      (setf (slot-value page 'links) (hb:extract-links page)))))

(defun get-page-html (wiki page-title)
  (let* ((slug (gethash page-title (slugs-of wiki)))
         (url (make-wiki-url (domain-name-of wiki)
                             (str:concat "/" slug ".html"))))
    (drakma:http-request url :method :get)))

(defun get-page-json (wiki page-title)
  (let* ((slug (gethash page-title (slugs-of wiki)))
         (url (make-wiki-url (domain-name-of wiki)
                             (str:concat "/" slug ".json")))
         (stream (drakma:http-request url
                                      :method :get
                                      :want-stream t)))
    (shasht:read-json stream)))

(defun adapt-dom (page)
  (let ((dom (hb:dom-of page))
        (wiki (hb:hyperbook-of page)))
    ;; Remove the DOCTYPE node
    (plump:remove-child (elt (plump:children dom) 0))
    ;; Unwrap the HTML element
    (lquery:$ dom "html"
      (children)
      (first)
      (unwrap))
    ;; Remove the HEAD node
    (lquery:$ dom "head"
      (remove))
    ;; Unwrap the BODY node
    (lquery:$ dom "body"
      (children)
      (first)
      (unwrap))
    ;; Remove style nodes
    (lquery:$ dom "style"
      (remove))
    ;; Remove script nodes
    (lquery:$ dom "script"
      (remove))
    ;; Remove footer
    (lquery:$ dom "footer"
      (remove))
    ;; Remove icon with link to the Wiki
    (lquery:$ dom "a[href=/]"
      (remove))
    ;; Remove external link image
    (lquery:$ dom "img[src=/images/external-link-ltr-icon.png]"
      (remove))
    ;; Replace internal links by hyperbook links
    (lquery:$ dom "a.internal"
      (map #'(lambda (el)
               (let* ((href (plump:get-attribute el "href"))
                      ;; Strip off initial "/" and trailing ".html"
                      (slug (str:substring 1 -5 href))
                      (hyperbook-id nil)
                      (page-id (gethash slug (slugs-of wiki))))
                 ;; page-id is NIL for links to missing pages,
                 ;; including pages retrieved from the federation.
                 ;; Search the sites in the page context.
                 (unless page-id
                   (loop for remote in (context-of page)
                         for remote-page-id = (find-page-id-from-slug remote slug)
                         when remote-page-id
                           do (setf page-id remote-page-id)
                              (setf hyperbook-id (hb:id-of remote))
                              (return)))
                 ;; Replace links pointing to wiki pages by hyperbook links
                 (when page-id
                   (when hyperbook-id
                     (plump:set-attribute el "hyperbook" hyperbook-id))
                   (plump:set-attribute el "page" page-id) 
                   (plump:remove-attribute el "href")
                   (plump:remove-attribute el "class")
                   (plump:remove-attribute el "title")
                   (plump:remove-attribute el "data-page-name"))))))))

(defmethod find-page-id-from-slug (wiki slug)
  (wait-for-sitemap wiki)
  (gethash slug (slugs-of wiki)))

;;
;; Page journal
;;

(defclass journal-entry ()
  ((entry-type :reader entry-type-of :type keyword :initarg :entry-type)
   (date :reader date-of :type (or null local-time:timestamp) :initarg :date)
   (data :reader data-of :type hash-table :initarg :data)))

(defun make-journal (entries)
  (map 'vector #'make-journal-entry entries))

(defun make-journal-entry (entry)
  (let ((type (->> entry
                (gethash "type")
                (str:upcase)
                alexandria:make-keyword))
        (date (->> entry
                (gethash "date")
                wiki-date-to-timestamp)))
    (remhash "type" entry)
    (remhash "date" entry)
    (make-instance 'journal-entry
                   :entry-type type
                   :date date
                   :data entry)))

(defmethod views:text-representation ((entry journal-entry))
  (format nil "~A ~@[~A~]"
          (-> entry entry-type-of symbol-name str:downcase)
          (-> entry date-of)))

(views:defview 👀journal (page fedwiki-page)
  (load-page page)
  (-> page
    journal-of
    views:👀items
    (views:rename :title "Journal" :priority 3)))

(defun site-of (entry)
  (->> entry
    data-of
    (gethash "site")))

(defun extract-context (journal)
  (let (fork-sites)
    (loop for entry across journal
          for site = (site-of entry)
          when site
          do (pushnew site fork-sites :test #'equal))
    (mapcar #'get-fedwiki fork-sites)))

(views:defview 👀context (page fedwiki-page)
  (load-page page)
  (when-let (context (context-of page))
    (-> context
      views:👀items
      (views:rename :title "Context" :priority 4))))

;;
;; JSON view
;;

(views:defview 👀json (page fedwiki-page)
  (-> (get-page-json (hb:hyperbook-of page) (hb:id-of page))
    views:👀items
    (views:rename :title "JSON" :priority 7)))

;;
;; Register factory
;;

(hb:register-scheme :fedwiki #'get-fedwiki)
