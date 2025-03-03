;;;; HyperDoc classes and associated views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The classes for HyperDocs and their pages, as well as the code
;; to create a HyperDoc, are in hyperdoc.
;;

(defmethod text-representation ((hdoc hyperdoc))
  (title hdoc))

(defmethod title-bar-action-buttons ((hdoc hyperdoc))
  (action-button "Reload"
                 (thunk (load-pages hdoc)
                        t)))

(defview 👀entry (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (entry (entry hd))
    (when-let (entry-page (find-page hd entry))
      (👀content entry-page))))

(defview 👀items (hd hyperdoc)
  (ensure-pages-loaded hd)
  (-> hd
      pages
      alexandria:hash-table-values
      (list-view :title "Pages" :priority 2)))

(defview 👀code (hd hyperdoc)
  (-> hd
      code-files
      (enumerated-list-view :title "Code"
                            :priority 3
                            :display #'code-file-title)))

(defview 👀files (hd hyperdoc)
  (-> hd
      hyperdoc-directory
      👀items
      (rename :title "Files" :priority 5)))

(defvar *current-page* nil)

(defmethod title-bar-action-buttons ((page page))
  (action-button "Reload"
                 (thunk (load-page page)
                        t)))

(defmethod text-representation ((page page))
  (page-title page))

(defview 👀source (page page)
  (-> page
    (slot-value 'file)
    👀content
    (rename :title "Source" :priority 3)))

;; Import a symbol that's useful in HyperDoc pages
(import 'html-inspector-views/standard:var-definition)
