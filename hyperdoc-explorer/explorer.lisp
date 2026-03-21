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

(defun system-examples-target (system-designator)
  (etypecase system-designator
    (asdf:system
     system-designator)
    ((or string symbol)
     (asdf:find-system system-designator))))

(defun render-system-example-count (system example-count)
  (let ((display (format nil "~D" example-count)))
    (if (plusp example-count)
        (views:object-ref (system-examples-target system)
                          :display display
                          :select "examples")
        (views:html (:tt (views:esc display))))))

(defmethod views:text-representation ((target git-commit-target))
  (commit-hash-of target))

(defmethod views:text-representation ((surface canonical-route-discovery))
  (title-of surface))

(defmethod views:text-representation ((condition git-runtime-unavailable))
  (title-of condition))

(defmethod views:html-representation ((condition git-runtime-unavailable) &optional id)
  (views:html
    (:div :id id :class "inspector-error"
          (:strong (views:esc (title-of condition)))
          (:div :style "margin-top: 0.35em;"
                (views:esc (reason-of condition))))))

(views:defview 👀summary (condition git-runtime-unavailable)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of condition)))
      (:p (views:esc (summary-of condition)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Interpreted classification"))
                   (:td (:tt (views:esc
                              (git-runtime-classification-label
                               (classification-of condition))))))
              (:tr (:td (views:esc "Operation"))
                   (:td (:tt (views:esc (operation-of condition)))))
              (:tr (:td (views:esc "Command"))
                   (:td (:tt (views:esc
                              (or (command-of condition)
                                  "n/a")))))
              (:tr (:td (views:esc "Process exit code"))
                   (:td (:tt (views:esc
                              (if-let (exit-code (exit-code-of condition))
                                (format nil "~A" exit-code)
                                "n/a")))))
              (:tr (:td (views:esc "Working directory"))
                   (:td (:tt (views:esc
                              (or (and (working-directory-of condition)
                                       (namestring (working-directory-of condition)))
                                  "n/a")))))
              (:tr (:td (views:esc "Effective repository root"))
                   (:td (:tt (views:esc
                              (or (and (repository-root-of condition)
                                       (namestring (repository-root-of condition)))
                                  "n/a")))))
              (:tr (:td (views:esc "Repository root source"))
                   (:td (:tt (views:esc
                              (git-repository-root-source-label
                               (repository-root-source-of condition))))))
              (:tr (:td (views:esc "Repository root mode"))
                   (:td (:tt (views:esc
                              (git-repository-root-origin-label
                               (repository-root-of condition)
                               (repository-root-source-of condition))))))
              (:tr (:td (views:esc "Requested program"))
                   (:td (:tt (views:esc
                              (or (requested-program-of condition)
                                  "n/a")))))
              (:tr (:td (views:esc "Resolved program"))
                   (:td (:tt (views:esc
                              (or (resolved-program-of condition)
                                  "n/a")))))
              (:tr (:td (views:esc "Configuration source"))
                   (:td (:tt (views:esc
                              (format nil "~A"
                                      (configuration-source-of condition))))))
              (:tr (:td (views:esc "Reason"))
                   (:td (views:esc (reason-of condition))))
              (:tr (:td (views:esc "Detail"))
                   (:td (views:esc (or (detail-of condition) "n/a")))))
      (:h4 "Runtime policy")
      (:p (views:esc (runtime-policy-of condition)))
      (:h4 "Guidance")
      (if-let (guidance (guidance-of condition))
        (views:html
          (:ul
           (loop for item in guidance
                 do (views:html
                      (:li (views:esc item))))))
        (views:html
          (:p "No additional guidance recorded."))))))

(defun render-canonical-url-cell (url)
  (if url
      (views:html
        (:a :href url
            :target "_blank"
            (views:esc url)))
      (views:html
        (:span :style "opacity: 0.55;" "n/a"))))

(defun render-canonical-path-cell (path)
  (if path
      (views:html
        (:tt (views:esc path)))
      (views:html
        (:span :style "opacity: 0.55;" "n/a"))))

(views:defview 👀summary (surface canonical-route-discovery)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc (summary-of surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Chosen page"))
                   (:td (views:object-ref (page-of surface))))
              (:tr (:td (views:esc "Chosen inspectable object"))
                   (:td
                    (if-let (object (inspectable-object-of surface))
                      (views:object-ref object
                                        :display
                                        (or (inspectable-object-label-of surface)
                                            (views:text-representation object)))
                      (views:html
                        (:span :style "opacity: 0.55;" "n/a")))))
              (:tr (:td (views:esc "Runtime origin"))
                   (:td (:tt (views:esc (canonical-route-origin)))))
              (:tr (:td (views:esc "Canonical page path"))
                   (:td (render-canonical-path-cell
                         (canonical-page-path (page-of surface)))))
              (:tr (:td (views:esc "Canonical page URL"))
                   (:td (render-canonical-url-cell
                         (canonical-page-url (page-of surface)))))
              (:tr (:td (views:esc "Effective repository root"))
                   (:td (render-canonical-path-cell
                         (repository-root-of surface))))
              (:tr (:td (views:esc "Repository root source"))
                   (:td (:tt (views:esc
                              (if-let (repository-root-source
                                       (repository-root-source-of surface))
                                (git-repository-root-source-label
                                 repository-root-source)
                                "n/a")))))
              (:tr (:td (views:esc "Repository root mode"))
                   (:td (:tt (views:esc
                              (if-let (repository-root-source
                                       (repository-root-source-of surface))
                                (git-repository-root-origin-label
                                 (repository-root-of surface)
                                 repository-root-source)
                                "n/a")))))
              (:tr (:td (views:esc "Object renders in-process"))
                   (:td (:tt (views:esc
                              (if (inspectable-object-of surface)
                                  "yes"
                                  "n/a")))))
              (:tr (:td (views:esc "Canonical inspector path"))
                   (:td
                    (render-canonical-path-cell
                     (and (inspectable-object-of surface)
                          (canonical-inspector-path
                           (inspectable-object-of surface))))))
              (:tr (:td (views:esc "Canonical inspector URL"))
                   (:td
                    (render-canonical-url-cell
                     (and (inspectable-object-of surface)
                          (canonical-inspector-url
                           (inspectable-object-of surface))))))
              (:tr (:td (views:esc "Inspector URL status"))
                   (:td (views:esc
                         (if-let (object (inspectable-object-of surface))
                           (canonical-inspector-url-status object)
                           "No inspectable object recorded.")))))
      (when-let (notes (notes-of surface))
        (views:html
          (:h4 "Notes")
          (:ul
           (loop for note in notes
                 do (views:html
                      (:li (views:esc note))))))))))

(views:defview 👀route-discovery (surface canonical-route-discovery)
  (views:html-view :title "Route discovery" :priority 2
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc "Use the discovered page URL for HTTP smoke tests. Treat an absent inspector URL as an explicit routing boundary."))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Page URL"))
                   (:td (render-canonical-url-cell
                         (canonical-page-url (page-of surface)))))
              (:tr (:td (views:esc "Page path"))
                   (:td (render-canonical-path-cell
                         (canonical-page-path (page-of surface)))))
              (:tr (:td (views:esc "Git repository root"))
                   (:td (render-canonical-path-cell
                         (repository-root-of surface))))
              (:tr (:td (views:esc "Repository root mode"))
                   (:td (:tt (views:esc
                              (if-let (repository-root-source
                                       (repository-root-source-of surface))
                                (git-repository-root-origin-label
                                 (repository-root-of surface)
                                 repository-root-source)
                                "n/a")))))
              (:tr (:td (views:esc "Inspector object URL"))
                   (:td
                    (render-canonical-url-cell
                     (and (inspectable-object-of surface)
                          (canonical-inspector-url
                           (inspectable-object-of surface))))))
              (:tr (:td (views:esc "Inspector object status"))
                   (:td (views:esc
                         (if-let (object (inspectable-object-of surface))
                           (canonical-inspector-url-status object)
                           "No inspectable object recorded."))))))))

(views:defview 👀commit (target git-commit-target)
  (handler-case
      (views:html-view :title "Commit" :priority 1
        (views:html
          (:table :class "inspector-table"
                  (loop for (label . value) in (git-commit-metadata target)
                        do (views:html
                             (:tr (:td (views:esc label))
                                  (:td (:tt (views:esc value)))))))))
    (git-runtime-unavailable (condition)
      (views:html-view :title "Commit" :priority 1
        (views:html-representation condition)))))

(views:defview 👀patch (target git-commit-target)
  (handler-case
      (views:html-view :title "Patch" :priority 2
        (views:html
          (:pre (views:esc
                 (git-command-output
                  (repo-root-of target)
                  "show" "--stat" "--patch" "--no-color"
                  (commit-hash-of target))))))
    (git-runtime-unavailable (condition)
      (views:html-view :title "Patch" :priority 2
        (views:html-representation condition)))))

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
                        (:td (render-system-example-count system example-count))))))))

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
      (views:add-asset-path "/hyperbook/"
                            (asdf:system-relative-pathname
                             :hyperbook
                             "assets/hyperbook/"))
      (views:include-css "/hyperbook/css/hyperbook.css")
      (views:html
        (:h3 "Systems relevant to this HyperDoc")
        (:p
         "This is the local system-scope surface for this HyperDoc. "
         "For the catalog-wide list of loaded and registered ASDF systems, see the "
         (hb:render-hyperbook-or-page-link (id-of hyperbook::*asdf-systems*)
                                           nil
                                           "ASDF Systems")
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
  (views:html-view :title "Source" :priority 10
    (render-source-connect-surface page
                                   "Source"
                                   (file-of page))))
