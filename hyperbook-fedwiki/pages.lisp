;;;; Wiki pages
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; The page class
;;

;; A wiki page is a JSON data structure with three fields: title,
;; story, and journal. The remaining slots cache computed data.

(defclass fedwiki-page (hb:page)
  ((title :reader hb:title-of :type (or null string) :initarg :title :initform nil)
   (story :reader story-of :type (or null vector) :initform nil
          :documentation "A sequence of story items such as paragraphs,
images, etc.")
   (journal :reader journal-of :type (or null vector) :initform nil
            :documentation "A sequence of events such as edits, forks, etc.")
   ;; The page context is constructed from the fork entries of
   ;; the journal. It is used for resolving page links in the
   ;; federation.
   (context :reader context-of :type list :initform nil)
   ;; The list of links is extracted from the story
   ;; or from the sitemap.
   (links :reader hb:links-of :type (or null hb:links) :initform nil)))

;; A remote page is referenced but not stored in the wiki it belongs to.
;; The standard Wiki client shows them with blue borders.

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

(defmethod views:html-representation ((page remote-fedwiki-page) &optional id)
  (views:html (:span :id id
                     (views:esc (hb:title-of page))
                     (views:esc " ")
                     (:small (views:esc "(")
                             (views:esc (-> page origin-of domain-name-of))
                             (views:esc ")")))))

;;
;; Construct pages
;;
;; The pages are made as empty skeleton when a Wiki's sitemap is read.
;; The actual page contents are fetched on demand when needed,
;; e.g. for display.
;;

(defun make-fedwiki-page (wiki slug title)
  (make-instance 'fedwiki-page
                 :hyperbook wiki
                 :id slug
                 :title title))

(defun remote-page-id? (page-id)
  (and (find #\/ page-id)
       t))

(defun get-remote-page  (wiki page-id &optional title)
  (or (gethash page-id (remote-pages-of wiki))
      (make-remote-page wiki page-id title)))

(defun make-remote-page (wiki page-id &optional title)
  (let* ((id-parts (str:split "/" page-id) )
         (domain-name (first id-parts))
         (remote-site (get-fedwiki domain-name))
         (origin-id (second id-parts)))
    (let* ((page (make-instance 'remote-fedwiki-page
                                :hyperbook wiki
                                :id page-id
                                :title title
                                :origin remote-site
                                :origin-id origin-id)))
      (setf (gethash page-id (remote-pages-of wiki)) page)
      page)))

(defun load-page (page)
  (unless (story-of page)
    (reload-page page)))

(defun reload-page (page)
  (let* ((origin (origin-of page))
         (id (origin-id-of page))
         (page-data (fetch-page-json (domain-name-of origin)
                                     (protocol-of origin)
                                     id)))
    (set-page-data page page-data)
    ;; For remote pages, add the origin to the page context
    (unless (eq origin (hb:hyperbook-of page))
      (push origin (slot-value page 'context)))))

(defun set-page-data (page json)
  (let* ((title (gethash "title" json))
         (story (make-story (gethash "story" json)))
         (journal (make-journal (gethash "journal" json)))
         (context (extract-context journal)))
    (setf (slot-value page 'title) title)
    (setf (slot-value page 'story) story)
    (setf (slot-value page 'journal) journal)
    (setf (slot-value page 'context) context)
    (setf (slot-value page 'links) (extract-links page))))

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

(defmethod views:text-representation ((item story-item))
  (let* ((text (text-of item))
         (length (length text))
         (length-limit 60)
         (excerpt (str:substring 0 length-limit text)))
    (str:concat (-> item item-type-of symbol-name str:downcase)
                ": "
                (if (<= length length-limit)
                    excerpt
                    (str:concat excerpt "...")))))

(views:defview 👀data (item story-item)
  (views:html-view :title "Data" :priority 1
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "type"))
                                 (:td (views:object-ref (-> item item-type-of symbol-name str:downcase))))
                            (:tr (:td (views:esc "id"))
                                 (:td (views:object-ref (id-of item))))
                            (:tr (:td (views:esc "text"))
                                 (:td (views:object-ref (text-of item))))
                            (when-let (data (data-of item))
                              (loop for key being the hash-keys in data
                                    using (hash-value value)
                                    do (views:html
                                        (:tr (:td (views:esc key))
                                             (:td (views:object-ref value))))))))))

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

;;
;; Localhost page persistence
;;

(defun default-localhost-fedwiki-root-directory ()
  (merge-pathnames ".wiki/" (user-homedir-pathname)))

(defun localhost-fedwiki-pages-directory (domain-name)
  (merge-pathnames (format nil "~A/pages/" domain-name)
                   (default-localhost-fedwiki-root-directory)))

(defun localhost-fedwiki-page-pathname-from-domain-and-slug (domain-name slug)
  (merge-pathnames slug
                   (localhost-fedwiki-pages-directory domain-name)))

(defun localhost-fedwiki-page-pathname (page)
  (localhost-fedwiki-page-pathname-from-domain-and-slug
   (domain-name-of (origin-of page))
   (origin-id-of page)))

(defun env-truthy-p (name &optional (default nil))
  (let ((v (uiop:getenv name)))
    (cond
      ((null v) default)
      ((member (string-downcase v)
               '("1" "true" "yes" "on")
               :test #'string=)
       t)
      (t nil))))

(defun server-development-mode-value ()
  "Return the active server development policy when that runtime seam is loaded."
  (let* ((pkg (find-package "HYPERBOOK/SERVER"))
         (sym (and pkg (find-symbol "DEVELOPMENT-MODE-P" pkg))))
    (if (and sym (fboundp sym))
        (values (funcall sym) t)
        (values nil nil))))

(defun localhost-fedwiki-editing-enabled-p ()
  "Reuse the same development-mode policy that gates Playground evaluation."
  (multiple-value-bind (development-mode known-p)
      (server-development-mode-value)
    (if known-p
        development-mode
        (env-truthy-p "HYPERDOC_DEVELOPMENT" nil))))

(defun ensure-localhost-fedwiki-editing-enabled ()
  (unless (localhost-fedwiki-editing-enabled-p)
    (error "FedWiki page editing is disabled outside development mode.")))

(defun localhost-fedwiki-story-item-editable-p (page)
  (and (localhost-fedwiki-editing-enabled-p)
       (typep page 'fedwiki-page)
       (probe-file (localhost-fedwiki-page-pathname page))))

(defun read-localhost-fedwiki-page-json-file (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (shasht:read-json stream)))

(defun write-localhost-fedwiki-page-json-file (path json)
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (shasht:write-json json stream)))

(defun copy-json-like-value (value)
  (cond
    ((hash-table-p value)
     (let ((copy (make-hash-table :test #'equal)))
       (loop for key being the hash-keys in value
             using (hash-value hash-value)
             do (setf (gethash key copy)
                      (copy-json-like-value hash-value)))
       copy))
    ((stringp value)
     value)
    ((vectorp value)
     (map 'vector #'copy-json-like-value value))
    ((listp value)
     (mapcar #'copy-json-like-value value))
    (t
     value)))

(defun fedwiki-story-item-type-name (type)
  (etypecase type
    (keyword (str:downcase (symbol-name type)))
    (string type)))

(defun json-array-elements (value)
  (cond
    ((null value)
     '())
    ((listp value)
     value)
    ((vectorp value)
     (coerce value 'list))
    (t
     (error "Expected a JSON array represented as a list or vector, got ~A."
            (type-of value)))))

(defun next-localhost-fedwiki-journal-date (page-json)
  (let* ((journal (json-array-elements (gethash "journal" page-json)))
         (last-entry (car (last journal)))
         (last-date (if last-entry
                        (let ((value (gethash "date" last-entry)))
                          (if (numberp value)
                              value
                              0))
                        0))
         (now (* 1000 (local-time:timestamp-to-unix (local-time:now)))))
    (max now (1+ last-date))))

(defun find-story-item-json-by-id (page-json item-id)
  (find item-id
        (json-array-elements (gethash "story" page-json))
        :key (lambda (item)
               (and (hash-table-p item)
                    (gethash "id" item)))
        :test #'equal))

(defun apply-story-item-text-edit-to-page-json (page-json item-id new-text
                                                &key item-type)
  (let ((item (find-story-item-json-by-id page-json item-id)))
    (unless item
      (error "No FedWiki story item with id ~A in page JSON." item-id))
    (when item-type
      (let* ((normalized-type (fedwiki-story-item-type-name item-type))
             (existing-type (gethash "type" item)))
        (when (and existing-type
                   (not (string= existing-type normalized-type)))
          (error "FedWiki story item ~A changed type from ~A to ~A."
                 item-id existing-type normalized-type))
        (setf (gethash "type" item) normalized-type)))
    (setf (gethash "id" item) item-id
          (gethash "text" item) new-text)
    (let ((journal-entry (make-hash-table :test #'equal))
          (journal (copy-list (json-array-elements (gethash "journal" page-json)))))
      (setf (gethash "type" journal-entry) "edit"
            (gethash "id" journal-entry) item-id
            (gethash "item" journal-entry) (copy-json-like-value item)
            (gethash "date" journal-entry)
            (next-localhost-fedwiki-journal-date page-json))
      (setf (gethash "journal" page-json)
            (append journal (list journal-entry))))
    page-json))

(defun persist-localhost-fedwiki-story-item-text-edit-at-path (path item-id new-text
                                                               &key item-type)
  (ensure-localhost-fedwiki-editing-enabled)
  (let* ((page-json (read-localhost-fedwiki-page-json-file path))
         (updated (apply-story-item-text-edit-to-page-json
                   page-json item-id new-text :item-type item-type)))
    (write-localhost-fedwiki-page-json-file path updated)
    updated))

(defun persist-localhost-fedwiki-story-item-text-edit (page item new-text)
  (ensure-localhost-fedwiki-editing-enabled)
  (let ((path (probe-file (localhost-fedwiki-page-pathname page))))
    (unless path
      (error "No writable localhost FedWiki page file for ~A." (hb:title-of page)))
    (persist-localhost-fedwiki-story-item-text-edit-at-path
     path
     (id-of item)
     new-text
     :item-type (item-type-of item))
    (set-page-data page (read-localhost-fedwiki-page-json-file path))
    page))

(defun site-of (entry)
  (or (->> entry
           data-of
           (gethash "site"))
      (some->> entry
               data-of
               (gethash "attribution")
               (gethash "site"))))

(defun extract-context (journal)
  (let (remote-sites)
    (loop for entry across journal
          for site = (site-of entry)
          when site
          ;; This looks like pushnew, but it ensures that the order
          ;; of each site in the list corresponds to its most recent
          ;; occurence in the journal.
          do (setf remote-sites
                   (cons site
                         (remove site remote-sites :test #'equal))))
    (mapcar #'get-fedwiki remote-sites)))

;;
;; Views
;;

(views:defview 👀story (page fedwiki-page)
  (load-page page)
  (views:html-view :title "Story" :priority 2
                   (views:add-asset-path "/hyperbook/"
                                         (asdf:system-relative-pathname
                                          :hyperbook
                                          "assets/hyperbook/"))
                   (views:include-css "/hyperbook/css/hyperbook.css")
                   (views:html
                    (:div :class "hyperbook-page"
                          (:h1 (:img :src (wiki-url (-> page origin-of domain-name-of)
                                                    (-> page origin-of protocol-of)
                                                    "/favicon.png"))
                               (views:esc " ")
                               (views:esc (hb:title-of page)))
                          (loop for item across (story-of page)
                                do (views:html
                                    (:div :title (-> item item-type-of symbol-name str:downcase)
                                          (render-story-item (item-type-of item) item page))))))))

(defmethod hb:👀links ((page fedwiki-page))
  (load-page page)
  (when-let (links (hb:links-of page))
    (👀links links)))

;;
;; Title bar customization
;;

(defmethod views:title-bar-action-buttons ((page fedwiki-page))
  (let* ((wiki (hb:hyperbook-of page))
         (slug (origin-id-of page))
         (url (wiki-url (domain-name-of wiki)
                        (protocol-of wiki)
                        (str:concat "/" slug ".html"))))
    (views:html
     (views:action-button "Reload"
                          (views:thunk
                           (reload-page page)
                           t))
     " "
     (views:action-button html-inspector-views/standard:*icon-open-external*
                          (views:thunk
                           (when url
                             (clog:open-browser :url url)))
                          nil))))

(defmethod views:title-bar-action-buttons ((page remote-fedwiki-page))
  (views:action-button html-inspector-views/standard:*icon-open-external*
                       (views:thunk
                        (clog:open-browser :url (make-wiki-view-url page)))
                       nil))

(defgeneric make-wiki-view-url (page))

(defmethod make-wiki-view-url ((page fedwiki-page))
  (let ((wiki (hb:hyperbook-of page)))
    (format nil "~A://~A/~A.html"
            (protocol-of wiki)
            (domain-name-of wiki)
            (origin-id-of page))))

(defmethod make-wiki-view-url ((page remote-fedwiki-page))
  (let ((wiki (hb:hyperbook-of page))
        (origin (origin-of page)))
    (format nil "~A://~A/~A/~A"
            (protocol-of wiki)
            (domain-name-of wiki)
            (domain-name-of origin)
            (origin-id-of page))))
