;;;; HyperDoc classes and associated views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/explorer)

;;
;; The classes for HyperDocs and their pages, as well as the code
;; to create a HyperDoc, are in system "hyperdoc".
;;

;;
;; Load text pages
;;

(defun reload-text-pages (hdoc)
  "(Re-)load the text pages of HyperDoc HDOC."
  ;; The simplest strategy would be to reconstruct the internal
  ;; representation of text pages completely. However, this would
  ;; invalidate page objects that the user has opened in an inspector.
  ;; Therefore we keep the in-memory object tree and only update what
  ;; must be updated.
  (with-slots (directory pages text-pages) hdoc
    (let (page-files)
      (dolist (file (uiop:directory-files directory))
        (cond
          ;; Pages can be HTML or Markdown files
          ((member (pathname-type file) '("html" "md") :test #'string=)
           (let ((page (gethash file text-pages)))
             (unless page
               (setf page (hd::make-text-page hdoc file))
               (setf (gethash file text-pages) page))
             (load-page page)
             (push file page-files)))))
      ;; Remove pages whose files have been deleted.
      (loop for file being the hash-keys in text-pages
            do (unless (member file page-files :test #'equal)
                 (remhash file text-pages))))
    ;; Remove the potentially stale text page entries
    (loop for title being the hash-keys of pages
            using (hash-value page)
          when (typep page 'hd::text-page)
            do (remhash title pages))
    ;; Add the current text page entries
    (loop for page being the hash-values of text-pages
          do (setf (gethash (title-of page) pages) page))))


(defun ensure-pages-loaded (hdoc)
  "Load the pages of HyperDoc HDOC unless they have already been loaded."
  (when (zerop (hash-table-count (hd::text-pages-of hdoc)))
    ;; Load text pages a first time
    (reload-text-pages hdoc)
    ;; Load non-text pages, just once
    (loop for page being the hash-values of (pages-of hdoc)
          unless (typep page 'hd::text-page)
            do (load-page page))))

;;
;; Look up a page in a HyperDoc
;;

(defmethod find-page ((hdoc hyperdoc) title &key signal-error?)
  "Look up TITLE in HyperDoc HDOC and return the page if found. If no page with
TITLE exists, return NIL if SIGNAL-ERROR is NIL, otherwise signal
PAGE-LOOKUP-FAILURE."
  (unless hdoc
    (error 'page-lookup-failure :hyperdoc hdoc :title title))
  (ensure-pages-loaded hdoc)
  (or (gethash title (pages-of hdoc))
      (and signal-error?
           (error 'page-lookup-failure :hyperdoc hdoc :title title))))

;;
;; The title bar of inspectors on HyperDocs
;;

(defmethod views:text-representation ((hdoc hyperdoc))
  (title-of hdoc))

(defmethod views:title-bar-action-buttons ((hdoc hyperdoc))
  (when (hd::writable-of hdoc)
    (views:action-button "Reload"
                         (views:thunk (reload-text-pages hdoc)
                           t))))

(views:defview hbe::👀main-page (hd hyperdoc)
  (ensure-pages-loaded hd)
  (call-next-method))

;;
;; Views listing the text and code pages and the tools
;;

(views:defview 👀text-pages (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (text-pages (-> (hd::text-pages-of hd)
                            alexandria:hash-table-values))
    (views:list-view text-pages :title "Text pages" :priority 3)))

(views:defview 👀tools (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (tools (hd::tools-of hd))
    (-<> tools
      (mapcar #'hd::get-tool <>)
      (views:list-view :title "Tool pages" :priority 4))))

(views:defview 👀code-pages (hd hyperdoc)
  (when-let (pages (hd::code-pages-of hd))
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
                  :inspect #'(lambda (p) (symbol-value (car p)))))))

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
  (-> (hd::asdf-system-name-of hd)
    asdf:find-system
    👀repository
    (views:rename :title "Repository" :priority 7)))

;;
;; The title bar for HyperDoc pages
;;

(defmethod views:text-representation ((page page))
  (title-of page))

(defmethod views:title-bar-action-buttons ((page hd::text-page))
  (when (hd::writable-of (hyperbook-of page))
    (views:action-button "Reload"
                         (views:thunk
                           (load-page page)
                           t))))

;;
;; Source code view for text pages
;;

(views:defview 👀source (page hd::text-page)
  (-> page
      file-of
      views:👀content
      (views:rename :title "Source" :priority 10)))


