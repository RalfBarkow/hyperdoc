;;;; HyperDoc classes and associated views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The classes for HyperDocs and their pages, as well as the code
;; to create a HyperDoc, are in system "hyperdoc".
;;

;;
;; The title bar of inspectors on HyperDocs
;;

(defmethod views:text-representation ((hdoc hyperdoc))
  (title-of hdoc))

(defmethod views:title-bar-action-buttons ((hdoc hyperdoc))
  (when (writable-of hdoc)
    (views:action-button "Reload"
                         (views:thunk (reload-pages hdoc)
                           t))))

;;
;; View showing the entry page
;;

(views:defview 👀entry (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (entry (entry-of hd))
    (when-let (entry-page (find-page hd entry))
      (views:👀content entry-page))))

;;
;; Views listing the text and code pages and the tools
;;

(views:defview 👀text-pages (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (text-pages (-> (text-pages-of hd)
                            alexandria:hash-table-values))
    (views:list-view text-pages :title "Text pages" :priority 3)))

(views:defview 👀tools (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (tools (tools-of hd))
    (-<> tools
      (mapcar #'get-tool <>)
      (views:list-view :title "Tool pages" :priority 4))))

(views:defview 👀code-pages (hd hyperdoc)
  (when-let (pages (code-pages-of hd))
    (views:enumerated-list-view pages
                                :title "Code pages"
                                :priority 5)))

(views:defview 👀data (hd hyperdoc)
  (when-let (data (data-of hd))
    (views:html-view :title "Data" :priority 6
      (views:html-table data
                  :columns '("Title" "Value")
                  :display (list #'cdr
                                 #'(lambda (p) (symbol-value (car p))))
                  :inspect-items :by-column))))

;;
;; The files in the HyperDocs's directory
;;

(views:defview 👀files (hd hyperdoc)
  (-> (directory-of hd)
    views:👀items
    (views:rename :title "Files" :priority 10)))

;;
;; The source code repositories for the HyperDoc
;;

(views:defview 👀repository (hd hyperdoc)
  (-> (asdf-system-name-of hd)
    asdf:find-system
    👀repository
    (views:rename :title "Repository" :priority 7)))

;;
;; The title bar for HyperDoc pages
;;

(defmethod views:text-representation ((page page))
  (title-of page))

(defmethod views:title-bar-action-buttons ((page text-page))
  (when (writable-of (hyperdoc-of page))
    (views:action-button "Reload"
                         (views:thunk (load-page page)
                           t))))

;;
;; Source code view for text pages
;;

(views:defview 👀source (page text-page)
  (-> page
      file-of
      views:👀content
      (views:rename :title "Source" :priority 10)))

;;
;; Source code view for code pages
;;

(views:defview 👀source (page code-page)
  (-> page
      file-of
      views:👀source
      (views:rename :title "Source" :priority 10)))

