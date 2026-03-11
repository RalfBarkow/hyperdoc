;;;; HyperDoc classes and associated views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

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
               (setf page (make-text-page hdoc file))
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
          when (typep page 'text-page)
            do (remhash title pages))
    ;; Add the current text page entries
    (loop for page being the hash-values of text-pages
          do (setf (gethash (title-of page) pages) page))))


(defun ensure-pages-loaded (hdoc)
  "Load the pages of HyperDoc HDOC unless they have already been loaded."
  (when (zerop (hash-table-count (text-pages-of hdoc)))
    ;; Load text pages a first time
    (reload-text-pages hdoc)
    ;; Load non-text pages, just once
    (loop for page being the hash-values of (pages-of hdoc)
          unless (typep page 'text-page)
            do (load-page page))))

;;
;; Look up a page in a HyperDoc
;;

(defmethod find-page ((hdoc hyperdoc) id &key signal-error?)
  "Look up ID in HyperDoc HDOC and return the page if found. If no page with
ID exists, return NIL if SIGNAL-ERROR? is NIL, otherwise signal
PAGE-LOOKUP-FAILURE."
  (unless hdoc
    (error 'page-lookup-failure :hyperbook hdoc :page-id id))
  (ensure-pages-loaded hdoc)
  (or (gethash id (pages-of hdoc))
      (and signal-error?
           (error 'page-lookup-failure :hyperbook hdoc :page-id id))))

;;
;; The inspector title bar for HyperDocs
;;

(defmethod views:title-bar-action-buttons ((hdoc hyperdoc))
  (when (writable-of hdoc)
    (views:action-button "Reload"
                         (views:thunk (reload-text-pages hdoc)
                           t))))

(defun asdf-system-source-file-truename (system)
  (ignore-errors
    (some-> system
            asdf:system-source-file
            truename)))

(defun validation-subsystem-p (system)
  (let ((name (asdf:component-name system)))
    (or (uiop:string-suffix-p name "/tests")
        (uiop:string-suffix-p name "/checks"))))

(defun asdf-system-role-label (system)
  (let ((name (asdf:component-name system)))
    (cond
      ((validation-subsystem-p system)
       "Test system")
      ((uiop:string-suffix-p name "/explorer")
       "Explorer subsystem")
      ((uiop:string-suffix-p name "/inspector")
       "Inspector subsystem")
      ((uiop:string-suffix-p name "/server")
       "Server subsystem")
      ((search "/" name)
       "Supporting subsystem")
      (t
       "Primary system"))))

(defun systems-defined-with (system)
  (let ((source-file (asdf-system-source-file-truename system)))
    (sort
     (remove-duplicates
      (cons system
            (loop for name in (asdf:registered-systems)
                  for candidate = (ignore-errors (asdf:find-system name))
                  when (and candidate
                            source-file
                            (equal source-file
                                   (asdf-system-source-file-truename candidate)))
                    collect candidate))
      :test #'string=
      :key #'asdf:component-name)
     #'string<
     :key #'asdf:component-name)))

(defun related-asdf-systems-for-hyperdoc (hd)
  (systems-defined-with (asdf-system-of hd)))

(defun supporting-systems-for-hyperdoc (hd)
  (let ((primary-name (asdf:component-name (asdf-system-of hd))))
    (sort
     (loop for system in (related-asdf-systems-for-hyperdoc hd)
           for name = (asdf:component-name system)
           unless (or (string= name primary-name)
                      (validation-subsystem-p system))
             collect system)
     #'string<
     :key #'asdf:component-name)))

(defun validation-subsystems-for-system (system)
  (let ((prefix (format nil "~A/" (asdf:component-name system))))
    (sort
     (loop for candidate in (systems-defined-with system)
           for candidate-name = (asdf:component-name candidate)
           when (and (not (string= candidate-name (asdf:component-name system)))
                     (validation-subsystem-p candidate)
                     (uiop:string-prefix-p prefix candidate-name))
             collect candidate)
     #'string<
     :key #'asdf:component-name)))

(defun render-object-ref-list (objects &key (empty "None"))
  (if objects
      (views:html
        (:ul
         (loop for object in objects
               do (views:html
                    (:li (views:object-ref object))))))
      (views:html (:span (views:esc empty)))))

(defun render-system-scope-table (systems)
  (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "System"))
                 (:th (views:esc "Role"))
                 (:th (views:esc "Source"))
                 (:th (views:esc "Examples")))
            (loop for system in systems
                  for example-count = (length
                                       (discover-example-checks
                                        :system (asdf:component-name system)))
                  for source-file = (ignore-errors (asdf:system-source-file system))
                  do (views:html
                       (:tr
                        (:td (views:object-ref system))
                        (:td (:tt (views:esc (asdf-system-role-label system))))
                        (:td (if source-file
                                 (views:object-ref source-file)
                                 (views:html (:tt (views:esc "n/a")))))
                        (:td (:tt (views:esc (format nil "~D" example-count))))))))))

(defun hyperdoc-pages (hd)
  (ensure-pages-loaded hd)
  (sort (alexandria:hash-table-values (pages-of hd))
        #'string<
        :key #'id-of))

(defmethod views:text-representation ((system asdf:system))
  (asdf:component-name system))

(views:defview hb::👀main-page (hd hyperdoc)
  (ensure-pages-loaded hd)
  (call-next-method))

;;
;; Views listing the text and code pages and the tools
;;

(views:defview 👀systems (hd hyperdoc)
  (let* ((primary-system (asdf-system-of hd))
         (supporting-systems (supporting-systems-for-hyperdoc hd))
         (validation-systems (validation-subsystems-for-system primary-system)))
    (views:html-view :title "Systems" :priority 2
      (views:html
        (:h3 "Systems relevant to this HyperDoc")
        (:p
         "This is the local system-scope surface for this HyperDoc. "
         "For the catalog-wide list of loaded and registered ASDF systems, see the "
         (views:object-ref hyperbook::*asdf-systems* :display "ASDF Systems")
         " HyperBook in the catalog.")
        (:p "Click a system name below to inspect the corresponding ASDF system object.")
        (:h4 "Primary system")
        (render-system-scope-table (list primary-system))
        (:h4 "Related systems")
        (if supporting-systems
            (render-system-scope-table supporting-systems)
            (views:html
              (:p "No related supporting systems are defined with this HyperDoc's primary system.")))
        (:h4 "Test systems")
        (if validation-systems
            (render-system-scope-table validation-systems)
            (views:html
              (:p "No dedicated test systems are defined for this HyperDoc.")))))))

(views:defview 👀pages (hd hyperdoc)
  (when-let (pages (hyperdoc-pages hd))
    (views:list-view pages :title "Pages" :priority 3)))

(views:defview 👀topics (hd hyperdoc)
  (declare (ignore hd))
  (-> *topics*
      views:👀items
      (views:rename :title "Topics" :priority 4)))

(views:defview 👀overview (system asdf:system)
  (let* ((system-name (asdf:component-name system))
         (source-file (ignore-errors (asdf:system-source-file system)))
         (example-count (length (discover-example-checks :system system-name)))
         (validation-systems (validation-subsystems-for-system system)))
    (views:html-view :title "Overview" :priority 1
      (views:html
        (:h3 (views:esc system-name))
        (:p (views:esc "ASDF systems are the primary exploration scope in HyperDoc. Examples, tests, and lower-level package archaeology hang off the system object."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Role"))
                     (:td (:tt (views:esc (asdf-system-role-label system)))))
                (:tr (:td (views:esc "Source file"))
                     (:td (if source-file
                              (views:object-ref source-file)
                              (views:html (:tt (views:esc "n/a"))))))
                (:tr (:td (views:esc "Examples"))
                     (:td (:tt (views:esc (format nil "~D" example-count)))))
                (:tr (:td (views:esc "Test systems"))
                     (:td (render-object-ref-list
                           validation-systems
                           :empty "No dedicated test system registered."))))))))

(views:defview 👀text-pages (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (text-pages (-> (text-pages-of hd)
                            alexandria:hash-table-values
                            (sort #'string< :key #'id-of)))
    (views:list-view text-pages :title "Text pages" :priority 9)))

(views:defview 👀tools (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (tools (tools-of hd))
    (-<> tools
      (mapcar #'get-tool <>)
      (views:list-view :title "Tool pages" :priority 10))))

(views:defview 👀code-pages (hd hyperdoc)
  (when-let (pages (code-pages-of hd))
    (views:enumerated-list-view pages
                                :title "Code pages"
                                :priority 11)))

(views:defview 👀data (hd hyperdoc)
  (when-let (data (data-of hd))
    (views:html-view :title "Data" :priority 12
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
    (views:rename :title "Files" :priority 14)))

;;
;; The source code repositories for the HyperDoc
;;

(views:defview 👀repository (hd hyperdoc)
  (-> (asdf-system-name-of hd)
    asdf:find-system
    👀repository
    (views:rename :title "Repository" :priority 8)))

;;
;; The title bar for HyperDoc text pages
;;

(defmethod views:title-bar-action-buttons ((page text-page))
  (when (writable-of (hyperbook-of page))
    (views:action-button "Reload"
                         (views:thunk
                           (load-page page)
                           t))))

;;
;; Source code view for text pages
;;

(views:defview 👀source (page text-page)
  (-> page
      file-of
      views:👀content
      (views:rename :title "Source" :priority 10)))
