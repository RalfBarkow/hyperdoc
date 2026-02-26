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
         (page-data (fetch-page-json (domain-name-of origin) id)))
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
;; Render story items as HTML
;;

(defparameter *url-regex* "(https:\\/\\/www\\.|http:\\/\\/www\\.|https:\\/\\/|http:\\/\\/)?[a-zA-Z0-9]{2,}(\\.[a-zA-Z0-9]{2,})(\\.[a-zA-Z0-9]{2,})?")

(defparameter *any-except-closing-bracket-regex* "(?:[^\\]]*)")

(defparameter *link-regex*
  (str:concat "\\["
              "(?:"
              ;; Wiki links
              "(?:\\[" *any-except-closing-bracket-regex* "\\])"
              "|"
              ;; external links
              "(?:" *url-regex* "\\s*" *any-except-closing-bracket-regex* ")"
              ")"
              "\\]"))

(defgeneric render-story-item (type item page)
  (:method ((type t) item page)
    (declare (ignore page))
    (views:html
      (:div (:i (:small (views:object-ref item
                                          :display (-> type symbol-name str:downcase)))))
      (:pre :style "background-color: #eee;"
       (views:esc (text-of item))))))

(defgeneric extract-links-from-story-item (type item page)
  ;; Default: no links
  (:method ((type t) item page)
    (declare (ignore type item page))
    nil))

(defun extract-links (page)
  (let (wiki-links web-links)
    (loop for item across (story-of page)
          do (loop for link in (extract-links-from-story-item (item-type-of item) item page)
                   do (typecase link
                        (wiki-link (pushnew link wiki-links
                                            :test #'equal
                                            :key #'target-slug-of))
                        (hb:web-link (pushnew link web-links
                                              :test #'equal
                                              :key #'hb:url-of)))))
    (make-instance 'fedwiki-links
                   :wiki-links (sort wiki-links #'string< :key #'target-slug-of)
                   :web-links (sort web-links #'string< :key #'hb:url-of))))

;; Paragraphs

(defmethod render-story-item ((type (eql :paragraph)) item page)
  (views:html
    (:p (render-wiki-text (text-of item) page))))

(defmethod extract-links-from-story-item ((type (eql :paragraph)) item page)
  (extract-links-from-wiki-text (text-of item) page))

(defmethod render-wiki-text (text page)
  (process-text-and-links text page
                          #'(lambda (chunk page)
                              (declare (ignore page))
                              (views:html (views:esc chunk)))
                          #'render-link))

(defmethod extract-links-from-wiki-text (text page)
  (process-text-and-links text page
                          #'(lambda (chunk page)
                              (declare (ignore chunk page))
                              nil)
                          #'collect-link))

(defun process-text-and-links (text page text-fn link-fn)
  (let ((link-positions (cl-ppcre:all-matches *link-regex* text)))
    (loop for (start end) on (cons 0 link-positions)
          for chunk = (str:substring start end text)
          for is-link? = nil then (not is-link?)
          if is-link?
            collect (funcall link-fn chunk page)
          else
            collect (funcall text-fn chunk page))))

(defun render-link (link-text page)
  (if (str:starts-with? "[[" link-text)
      (render-wiki-link (str:substring 2 -2 link-text) page)
      (let* ((parts (str:split " " (str:substring 1 -1 link-text)))
             (url (first parts))
             (text (str:join " " (rest parts))))
        (render-external-link url text page))))

(defun collect-link (link-text page)
  (if (str:starts-with? "[[" link-text)
      (let ((link (str:substring 2 -2 link-text)))
        (make-wiki-link page :target-title link :target-slug (slug link)))
      (let* ((parts (str:split " " (str:substring 1 -1 link-text)))
             (url (first parts)))
        (hb:make-web-link page url))))

(defun render-wiki-link (link-text page)
  (handler-case
      (let ((target (find-target-by-title link-text page)))
        (views:html
          (:span :class "hyperbook-reference"
                 :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                                (cl-who:escape-string (hb:title-of target))
                                (cl-who:escape-string
                                 (hb:title-of (hb:hyperbook-of target))))
                 (views:object-ref target :display link-text))))
    (hb:lookup-failure (c)
      (views:html
        (:span :class "hyperbook-reference hyperbook-error"
               (views:object-ref c :display link-text))))))

(defun render-external-link (url link-text page)
  (declare (ignore page))
  (views:html
    (:a :href url :target "_blank"
        (views:esc link-text))))

(defmethod render-story-item ((type (eql :reference)) item page)
  (let* ((data (data-of item))
         (site (gethash "site" data))
         (title (gethash "title" data))
         (slug (gethash "slug" data)))
    (views:html
      (:p
       (:span :class "hyperbook-reference"
              :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                             (cl-who:escape-string title)
                             (cl-who:escape-string (hb:title-of (hb:hyperbook-of page))))
              (views:object-ref
               (handler-case
                   (get-remote-page (hb:hyperbook-of page)
                                    (str:concat site "/" slug)
                                    title)
                 (error (c) c))))
       (views:esc " — ")
       (render-wiki-text (text-of item) page)))))

(defmethod extract-links-from-story-item ((type (eql :reference)) item page)
  (extract-links-from-wiki-text (text-of item) page))

(defmethod render-story-item ((type (eql :pagefold)) item page)
  (views:html
    (:div :style "top-margin: 5pt;"
          (:hr :style "color: gray;")
          (:span :style "color: gray;"
                 (views:esc (text-of item))))))

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
;; Title bar customization for pages
;;

(defmethod views:title-bar-action-buttons ((page fedwiki-page))
  (views:action-button html-inspector-views/standard:*icon-open-external*
    (let ((wiki (hb:hyperbook-of page))
          (slug (origin-id-of page)))
      (views:action-button "Reload"
                           (views:thunk (reload-page page)
                             t))
      (views:thunk
       (clog:open-browser :url (wiki-url (domain-name-of wiki)
                                         (str:concat "/" slug ".html")))))
    nil))

(defmethod views:title-bar-action-buttons ((page remote-fedwiki-page))
  (views:action-button html-inspector-views/standard:*icon-open-external*
    (views:thunk
      (clog:open-browser :url (make-wiki-view-url page)))
    nil))

(defgeneric make-wiki-view-url (page))

(defmethod make-wiki-view-url ((page fedwiki-page))
  (let ((wiki (hb:hyperbook-of page)))
    (format nil "http://~A/~A.html"
            (domain-name-of wiki)
            (origin-id-of page))))

(defmethod make-wiki-view-url ((page remote-fedwiki-page))
  (let ((wiki (hb:hyperbook-of page))
        (origin (origin-of page)))
    (format nil "http://~A/~A/~A"
            (domain-name-of wiki)
            (domain-name-of origin)
            (origin-id-of page))))
