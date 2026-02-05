;;;; HyperBook interface for Federated Wiki
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Implementation of the HyperBook interface
;;

;; A fedwiki object stores the information retrieved from
;; a wiki's site map. The HyperBook id is "fedwiki:"
;; followed by the wiki's domain name. Page ids are
;; the page titles for local pages.
;;
;; The map from slugs to page titles is stored because
;; (1) the title -> slug function is not invertible, and
;; (2) we retrieve rendered HTML from the server,
;; and therefore have to handle page references expressed
;; as slugs rather than titles.

(defclass fedwiki (hb:hyperbook)
  ((pages :reader pages-of :type hash-table
          :initform (make-hash-table :test #'equal)
          :documentation "A map from page ids to page objects")
   (plugins :reader plugins-of :type hash-table
            :initform (make-hash-table :test #'equal)
            :documentation "The map from plugin names to plugins")
   (slugs :reader slugs-of :type hash-table
          :initform (make-hash-table :test #'equal)
          :documentation "A map from slugs to page ids and back")
   (status :accessor status-of :initform nil
           :documentation "The initialization status of the wiki,
one of (1) the thread loading the site map, (2) t for a fully
loaded site map, or (3) a conditon object recording an error
that occurred when reading the site map.")))

;; A wiki page is a JSON data structure with three fields: title,
;; story, and journal. The title becomes the HyperBook page id. Story
;; and journal are lightly transformed into something more Lispy.

(defclass fedwiki-page (hb:page)
  ((story :reader story-of :type (or null vector) :initform nil
          :documentation "A sequence of story items such as paragraphs,
images, etc.")
   (journal :reader journal-of :type (or null vector) :initform nil
            :documentation "A sequence of events such as edits, forks, etc.")
   ;; The page context is constructed from the fork entries of
   ;; the journal. It is used for resolving page links in the
   ;; federation.
   (context :reader context-of :type list)
   ;; The DOM is a parse tree of the HTML representation of the page.
   ;; It is retrieved from the server and heavily modified.
   (dom :reader hb:dom-of :type (or null plump:node) :initform nil)
   ;; The list of link is extracted from the DOM.
   (links :reader hb:links-of :type (or null hb:links) :initform nil)))

;; A remote page is referenced but not stored in the wiki it belongs to.

(defclass remote-fedwiki-page (fedwiki-page)
  ((origin :reader origin-of :type fedwiki :initarg :origin
           :documentation "The wiki in which the page is stored")
   (origin-id :reader origin-id-of :type string :initarg :origin-id
              :documentation "The page id in the origin wiki")))

;; For non-remote pages, the origin is the containing wiki.

(defmethod origin-of ((page fedwiki-page))
  (hb:hyperbook-of page))

(defmethod origin-id-of ((page fedwiki-page))
  (hb:id-of page))

;;
;; Computed attributes of wikis and their pages
;;

(defun domain-name-of (wiki)
  (->> wiki
    hb:id-of
    (str:split ":")
    second))

(defmethod hb:title-of ((wiki fedwiki))
  (domain-name-of wiki))

(defmethod hb:title-of ((page fedwiki-page))
  (hb:id-of page))

(defmethod hb:title-of ((page remote-fedwiki-page))
  (origin-id-of page))

(defmethod hb:main-page-id-of ((wiki fedwiki))
  "Welcome Visitors")

;;
;; Page lookup
;;

(defmethod hb:find-page ((wiki fedwiki) id  &key signal-error?)
  (wait-for-sitemap wiki)
  (or (gethash id (pages-of wiki))
      (get-remote-page wiki id)
      (and signal-error?
           (error 'hb:page-lookup-failure :hyperbook wiki :page-id id))))

(defun wait-for-sitemap (wiki)
  (let ((status (status-of wiki)))
    (when (typep status 'bt:thread)
      (bt:join-thread status))))

(defun get-remote-page (wiki page-id)
  (let* ((id-parts (str:split " 「" page-id) )
         (origin-id (first id-parts)))
    (when (and (= 2 (length id-parts))
               (str:ends-with? "」" (second id-parts)))
      (let* ((domain-name (str:substring 0 -1 (second id-parts)))
             (page (make-instance 'remote-fedwiki-page
                                  :hyperbook wiki
                                  :id page-id
                                  :origin (get-fedwiki domain-name)
                                  :origin-id origin-id)))
        (setf (gethash page-id (pages-of wiki)) page)
        page))))

;;
;; Create a fedwiki proxy
;;

(defparameter *uri-scheme* "fedwiki:")

(defun make-fedwiki (domain-name)
  (let* ((wiki (make-instance 'fedwiki
                              :id (str:concat *uri-scheme* domain-name))))
    (setf (status-of wiki)
          (bt:make-thread
           #'(lambda ()
               (handler-case
                   (progn (fetch-sitemap wiki)
                          (fetch-plugin-data wiki)
                          (setf (status-of wiki) t))
                 ((or stream-error
                      usocket:timeout-error
                      usocket:ns-host-not-found-error) (c)
                      (setf (status-of wiki) c))))))
    wiki))

(defun fetch-sitemap (wiki)
  (let* ((sitemap-url (make-wiki-url (domain-name-of wiki)
                                     "/system/sitemap.json"))
         (sitemap (fetch-json sitemap-url)))
    (loop for page-spec across sitemap
          for slug = (gethash "slug" page-spec)
          for title = (gethash "title" page-spec)
          for links = (some->> page-spec
                               (gethash "links")
                               alexandria:hash-table-keys)
          for page = (make-instance 'fedwiki-page
                                    :hyperbook wiki
                                    :id title)
          do (setf (gethash (hb:id-of page) (pages-of wiki))
                   page)
          (setf (gethash slug (slugs-of wiki))
                (hb:id-of page))
          (setf (gethash (hb:id-of page) (slugs-of wiki))
                slug))))

(defun fetch-json (url)
  (let ((stream (drakma:http-request url :method :get :want-stream t)))
    (shasht:read-json stream)))

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
  (let* ((origin (origin-of page))
         (id (origin-id-of page)))
    (unless (story-of page)
      (set-page-data page (fetch-page-json origin :page-title id))
      (unless (eq origin (hb:hyperbook-of page))
        (push origin (slot-value page 'context))))
    (unless (hb:dom-of page)
      (set-page-html page (fetch-page-html origin :page-title id)))))

(defun set-page-data (page json)
  (let* ((story (make-story (gethash "story" json)))
         (journal (make-journal (gethash "journal" json)))
         (context (extract-context journal)))
    (setf (slot-value page 'story) story)
    (setf (slot-value page 'journal) journal)
    (setf (slot-value page 'context) context)))

(defun set-page-html (page html)
  (setf (slot-value page 'dom) (plump:parse html))
  (adapt-dom page)
  (setf (slot-value page 'links) (hb:extract-links page)))

(defun fetch-page-html (wiki &key page-title slug)
  (assert (or page-title slug))
  (unless slug
    (setf slug (gethash page-title (slugs-of wiki))))
  (let ((url (make-wiki-url (domain-name-of wiki)
                            (str:concat "/" slug ".html"))))
    (drakma:http-request url :method :get)))

(defun fetch-page-json (wiki &key page-title slug)
  (assert (or page-title slug))
  (unless slug
    (setf slug (gethash page-title (slugs-of wiki))))
  (fetch-json (make-wiki-url (domain-name-of wiki)
                             (str:concat "/" slug ".json"))))

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
                      (page-id (gethash slug (slugs-of wiki))))
                 ;; page-id is NIL for links to missing pages,
                 ;; including pages retrieved from the federation.
                 ;; Search the sites in the page context.
                 (unless page-id
                   (loop for remote in (context-of page)
                         for remote-page-id = (find-page-id-from-slug remote slug)
                         when remote-page-id
                           do (setf page-id (str:concat remote-page-id
                                                        " 「"
                                                        (domain-name-of remote)
                                                        "」"))
                              (return)))
                 ;; If page-id is still NIL, it could refer to a plugin
                 ;; page, which is not listed in the site map.
                 (unless page-id
                   (when-let (page (get-plugin-page wiki slug))
                     (setf page-id (hb:id-of page))))
                 ;; If page-id is still NIL, there is no matching page
                 ;; anywhere. Ideally, we would use the page title as
                 ;; the page-id in the link, causing a lookup failure
                 ;; with the correct page name. But all we have is the
                 ;; slug.
                 (unless page-id
                   (setf page-id slug))
                 ;; Replace link by hyperbook link
                 (plump:set-attribute el "page" page-id) 
                 (plump:remove-attribute el "href")
                 (plump:remove-attribute el "class")
                 (plump:remove-attribute el "title")
                 (plump:remove-attribute el "data-page-name")))))))

(defmethod find-page-id-from-slug (wiki slug)
  (wait-for-sitemap wiki)
  (gethash slug (slugs-of wiki)))

(defun slug-of (page)
  (gethash (hb:id-of page) (slugs-of (origin-of page))))

;;
;; Page story
;;

(defclass story-item ()
  ((item-type :reader item-type-of :type keyword :initarg :item-type)
   (id :reader id-of :type string :initarg :id)
   (text :reader text-of :type string :initarg :text)
   (data :reader data-of :type hash-table :initarg :data)))

(defun make-story (items)
  (map 'vector #'make-story-item items))

(defun make-story-item (item)
  (let ((type (->> item
                (gethash "type")
                (str:upcase)
                alexandria:make-keyword))
        (id (->> item
                (gethash "id")))
        (text (->> item
                (gethash "text"))))
    (remhash "type" item)
    (remhash "id" item)
    (remhash "text" item)
    (when (zerop (hash-table-count item))
      (setf item nil))
    (make-instance 'story-item
                   :item-type type
                   :id (or id "")
                   :text (or text "")
                   :data item)))

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

(defun site-of (entry)
  (->> entry
    data-of
    (gethash "site")))

(defun extract-context (journal)
  (let (fork-sites)
    (loop for entry across journal
          for site = (site-of entry)
          when site
            do (setf fork-sites
                     (cons site
                           (remove site fork-sites :test #'equal))))
    (mapcar #'get-fedwiki fork-sites)))

;;
;; Register a HyperBook factory
;;

(hb:register-scheme :fedwiki #'get-fedwiki)
