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
     (when (zerop (hash-table-count (plugins-of wiki)))
       (fetch-plugin-data wiki))
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
      (let* ((raw (wiki-url (domain-name-of wiki) "/"))
             (uri (quri:uri raw))
             (scheme (or (quri:uri-scheme uri) "http"))
             (host (quri:uri-host uri))
             (path (or (quri:uri-path uri) "/"))
             (final-url (format nil "~A://~A~A" scheme host path)))
        (when (member scheme '("http" "https") :test #'string=)
          (clog:open-browser :url final-url))))
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
    (html-inspector-views:multi-column-list-view
     context
     :title "Context" :priority 4
     :columns '("Site" "Owner")
     :display (list #'identity
                    #'(lambda (wiki)
                        (or (get-site-owner wiki)
                            ""))))))

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
