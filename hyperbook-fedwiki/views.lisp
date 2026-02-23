;;;; Views on wikis, pages, and plugins
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Views on wikis
;;

(views:defview 👀pages (wiki fedwiki)
  (wait-for-sitemap wiki)
  (unless (zerop (hash-table-count (pages-of wiki)))
    (-<> wiki
      pages-of
      alexandria:hash-table-values
      (remove-if #'(lambda (p) (typep p 'fedwiki-plugin-page)) <>)
      (sort #'string< :key #'hb:title-of)
      (views:list-view :title "Pages" :priority 5))))

(views:defview 👀plugins (wiki fedwiki)
  (views:list-view
   (views:thunk
     (wait-for-sitemap wiki)
     (-> wiki
       plugins-of
       alexandria:hash-table-values
       (sort #'string< :key #'name-of)))
   :title "Plugins" :priority 7))

;;
;; Title bar customization for wikis
;;

(defmethod views:title-bar-action-buttons ((wiki fedwiki))
  (views:action-button html-inspector-views/standard:*icon-open-external*
    (views:thunk
      (clog:open-browser :url (wiki-url (domain-name-of wiki) "/")))
    nil))

;;
;; Views on pages
;;

(defmethod views:text-representation ((entry journal-entry))
  (format nil "~A ~@[~A~]"
          (-> entry entry-type-of symbol-name str:downcase)
          (-> entry date-of)))

(views:defview 👀journal (page fedwiki-page)
  (load-page page)
  (views:multi-column-list-view
     (journal-of page)
     :title "Journal" :priority 3
     :display (list #'(lambda (entry)
                        (-> entry entry-type-of symbol-name str:downcase))
                    #'(lambda (entry)
                        (or (-> entry date-of)
                            "")))))

(views:defview 👀context (page fedwiki-page)
  (load-page page)
  (when-let (context (context-of page))
    (-> context
      views:👀items
      (views:rename :title "Context" :priority 4))))

;;
;; Title bar customization for pages
;;

(defmethod views:title-bar-action-buttons ((page fedwiki-page))
  (views:action-button html-inspector-views/standard:*icon-open-external*
    (let ((wiki (hb:hyperbook-of page))
          (slug (origin-id-of page)))
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

;;
;; Views on plugins
;;

(defmethod views:text-representation ((plugin fedwiki-plugin))
  (name-of plugin))

(views:defview 👀pages (plugin fedwiki-plugin)
  (views:list-view
   (views:thunk
     (load-plugin-pages plugin)
     (-> plugin
       pages-of
       alexandria:hash-table-values
       (sort #'string< :key #'hb:title-of)))
   :title "Pages" :priority 1))
