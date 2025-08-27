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
  (title hdoc))

(defmethod views:title-bar-action-buttons ((hdoc hyperdoc))
  (when *development-features*
    (views:action-button "Reload"
                         (views:thunk (load-pages hdoc)
                           t))))

;;
;; View showing the entry page
;;

(views:defview 👀entry (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (entry (entry hd))
    (when-let (entry-page (find-page hd entry))
      (views:👀content entry-page))))

;;
;; Views listing the text and code pages and the tools
;;

(views:defview 👀text-pages (hd hyperdoc)
  (ensure-pages-loaded hd)
  (-> hd
    pages
    alexandria:hash-table-values
    (views:list-view :title "Text pages" :priority 3)))

(views:defview 👀tools (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (tools (tools hd))
    (-<> tools
      (mapcar #'get-tool <>)
      (views:list-view :title "Tools" :priority 4))))

(views:defview 👀code-pages (hd hyperdoc)
  (-> hd
    code-files
    (views:enumerated-list-view :title "Code pages"
                                :priority 5
                                :display #'code-file-title)))

;;
;; The files in the HyperDocs's directory
;;

(views:defview 👀files (hd hyperdoc)
  (-> hd
    hyperdoc-directory
    views:👀items
    (views:rename :title "Files" :priority 6)))

;;
;; The source code repositories for the HyperDoc
;;

(views:defview 👀repository (hd hyperdoc)
  (-> hd
    asdf-system-name
    asdf:find-system
    👀repository
    (views:rename :title "Repository" :priority 7)))

;;
;; The title bar for HyperDoc page inspectors
;;

(defmethod views:title-bar-action-buttons ((page page))
  (when *development-features*
    (views:action-button "Reload"
                         (views:thunk (load-page page)
                           t))))

(defmethod views:text-representation ((page page))
  (page-title page))

;;
;; Source code view for pages
;;

(views:defview 👀source (page page)
  (-> page
    (slot-value 'file)
    views:👀content
    (views:rename :title "Source" :priority 3)))

