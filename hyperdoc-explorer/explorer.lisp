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

(defmethod text-representation ((hdoc hyperdoc))
  (title hdoc))

(defmethod title-bar-action-buttons ((hdoc hyperdoc))
  (when *development-features*
    (action-button "Reload"
                   (thunk (load-pages hdoc)
                     t))))

;;
;; View showing the entry page
;;

(defview 👀entry (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (entry (entry hd))
    (when-let (entry-page (find-page hd entry))
      (👀content entry-page))))

;;
;; Views listing the text and code pages
;;

(defview 👀text-pages (hd hyperdoc)
  (ensure-pages-loaded hd)
  (-> hd
      pages
      alexandria:hash-table-values
      (list-view :title "Text pages" :priority 3)))

(defview 👀code-pages (hd hyperdoc)
  (-> hd
      code-files
      (enumerated-list-view :title "Code pages"
                            :priority 4
                            :display #'code-file-title)))

;;
;; The files in the HyperDocs's directory
;;

(defview 👀files (hd hyperdoc)
  (-> hd
      hyperdoc-directory
      👀items
      (rename :title "Files" :priority 6)))

;;
;; The source code repositories for the HyperDoc
;;

(defview 👀repository (hd hyperdoc)
  (-> hd
      asdf-system-name
      asdf:find-system
      👀repository
      (rename :title "Repository" :priority 7)))

;;
;; The title bar for HyperDoc page inspectors
;;

(defmethod title-bar-action-buttons ((page page))
  (when *development-features*
    (action-button "Reload"
                   (thunk (load-page page)
                     t))))

(defmethod text-representation ((page page))
  (page-title page))

;;
;; Source code view for pages
;;

(defview 👀source (page page)
  (-> page
    (slot-value 'file)
    👀content
    (rename :title "Source" :priority 3)))

