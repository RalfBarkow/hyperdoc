;;;; Source pane layout evidence views
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun source-pane-layout-pathname (object-or-path)
  (let ((relative-path
         (typecase object-or-path
           (source-pane-layout-evidence (relative-path-of object-or-path))
           (source-pane-file-target (relative-path-of object-or-path))
           (string object-or-path)
           (t nil))))
    (and relative-path
         (ignore-errors
           (asdf:system-relative-pathname :hyperdoc relative-path)))))

(defun source-pane-layout-path-status (object-or-path)
  (if-let (pathname (source-pane-layout-pathname object-or-path))
      (if (probe-file pathname) "present" "missing")
    "missing"))

(defun source-pane-layout-current-hyperdoc ()
  (when (and (boundp 'hyperbook::*current-page*)
             hyperbook::*current-page*)
    (let ((hyperbook (hyperbook:hyperbook-of hyperbook::*current-page*)))
      (when (typep hyperbook 'hyperdoc)
        hyperbook))))

(defun source-pane-layout-normalized-pathname (path-designator)
  (when path-designator
    (let ((pathname (pathname path-designator)))
      (or (ignore-errors (truename pathname))
          pathname))))

(defun source-pane-layout-canonical-path-string (path-designator)
  (when-let (pathname (source-pane-layout-normalized-pathname path-designator))
    (string-downcase
     (substitute #\/ #\\ (namestring pathname)))))

(defun source-pane-layout-source-path-strings (relative-path)
  (let ((pathname (source-pane-layout-pathname relative-path)))
    (remove nil
            (remove-duplicates
             (list (and pathname
                        (source-pane-layout-canonical-path-string pathname))
                   (source-pane-layout-canonical-path-string relative-path))
             :test #'string=))))

(defun source-pane-layout-code-page-path-strings (hyperdoc page)
  (let* ((source-path
          (source-pane-layout-normalized-pathname
           (asdf:component-pathname (file-of page))))
         (system-root
          (source-pane-layout-normalized-pathname
           (ignore-errors
             (asdf:system-source-directory (asdf-system-of hyperdoc)))))
         (hyperdoc-root
          (source-pane-layout-normalized-pathname
           (directory-of hyperdoc))))
    (remove nil
            (remove-duplicates
             (list (source-pane-layout-canonical-path-string source-path)
                   (and source-path
                        system-root
                        (source-pane-layout-canonical-path-string
                         (enough-namestring source-path system-root)))
                   (and source-path
                        hyperdoc-root
                        (source-pane-layout-canonical-path-string
                         (enough-namestring source-path hyperdoc-root))))
             :test #'string=))))

(defun source-pane-layout-source-page-in-hyperdoc (hyperdoc relative-path)
  (when-let (source-paths (source-pane-layout-source-path-strings relative-path))
    (loop for page being the hash-values of (pages-of hyperdoc)
          when (and (typep page 'code-page)
                    (intersection source-paths
                                  (source-pane-layout-code-page-path-strings
                                   hyperdoc
                                   page)
                                  :test #'string=))
          do (return page))))

(defun source-pane-layout-find-source-component-in-tree (component source-paths)
  (or (and (typep component 'asdf:source-file)
           (when-let (component-path
                      (source-pane-layout-canonical-path-string
                       (ignore-errors (asdf:component-pathname component))))
             (and (member component-path source-paths :test #'string=)
                  component)))
      (loop for child in (ignore-errors (asdf:component-children component))
            for match =
            (source-pane-layout-find-source-component-in-tree child source-paths)
            when match
            do (return match))))

(defun source-pane-layout-source-component (relative-path)
  (when-let (source-paths (source-pane-layout-source-path-strings relative-path))
    (loop for system-name in (sort (copy-list (asdf:registered-systems))
                                   #'string<)
          for system = (ignore-errors (asdf:find-system system-name))
          when system
          do (when-let (component
                        (source-pane-layout-find-source-component-in-tree
                         system
                         source-paths))
               (return component)))))

(defun source-pane-layout-default-hyperdoc ()
  (or (source-pane-layout-current-hyperdoc)
      (and (boundp '*hyperdoc*)
           (typep *hyperdoc* 'hyperdoc)
           *hyperdoc*)
      (loop for hyperbook in (hyperbook:hyperbooks-of hyperbook:*catalog*)
            when (typep hyperbook 'hyperdoc)
            do (return hyperbook))))

(defun source-pane-layout-source-page (relative-path)
  (let ((current-hyperdoc (source-pane-layout-current-hyperdoc)))
    (or (and current-hyperdoc
             (source-pane-layout-source-page-in-hyperdoc
              current-hyperdoc
              relative-path))
        (loop for hyperbook in (hyperbook:hyperbooks-of hyperbook:*catalog*)
              unless (or (eq hyperbook current-hyperdoc)
                         (not (typep hyperbook 'hyperdoc)))
              do (when-let (page
                            (source-pane-layout-source-page-in-hyperdoc
                             hyperbook
                             relative-path))
                   (return page)))
        (when-let (component (source-pane-layout-source-component relative-path))
          (when-let (hyperdoc (source-pane-layout-default-hyperdoc))
            (make-code-page hyperdoc component))))))

(defun source-pane-layout-source-target (relative-path)
  (or (source-pane-layout-source-page relative-path)
      (and (source-pane-layout-pathname relative-path)
           (make-source-pane-file-target relative-path))))

(defun source-pane-layout-model-evidence-by-id (model evidence-id)
  (find evidence-id
        (evidence-of model)
        :key #'id-of
        :test #'string=))

(defun source-pane-layout-render-source-file-ref (relative-path)
  (if-let (target (source-pane-layout-source-target relative-path))
      (views:object-ref target
                        :display relative-path
                        :select "Source")
    (views:html (:tt (views:esc (or relative-path "-"))))))

(defun source-pane-layout-render-value (value)
  (cond
    ((null value)
     (views:html (:span :style "opacity: 0.55;" "-")))
    ((listp value)
     (views:html
      (:ul
       (loop for item in value
             do (views:html
                 (:li (source-pane-layout-render-value item)))))))
    ((and (stringp value)
          (source-pane-layout-pathname value)
          (probe-file (source-pane-layout-pathname value)))
     (source-pane-layout-render-source-file-ref value))
    (t
     (maybe-dom-object-ref value :fallback-empty "-"))))

(defun source-pane-layout-render-detail-table (columns rows)
  (views:html
   (:table :class "inspector-table"
           (:tr
            (loop for column in columns
                  for label = (car column)
                  do (views:html
                      (:th (views:esc label)))))
           (loop for row in rows
                 do (views:html
                     (:tr
                      (loop for column in columns
                            for key = (cdr column)
                            do (views:html
                                (:td (source-pane-layout-render-value
                                      (getf row key)))))))))))

(defmethod views:text-representation ((model source-pane-layout-model))
  (shorten-dom-association-label (title-of model)))

(defmethod views:text-representation ((evidence source-pane-layout-evidence))
  (shorten-dom-association-label (title-of evidence)))

(defmethod views:text-representation ((target source-pane-file-target))
  (shorten-dom-association-label (title-of target)))

(defmethod views:title-bar-action-buttons ((evidence source-pane-layout-evidence))
  (when-let (pathname (source-pane-layout-pathname evidence))
    (views:html
     (views:eval-button
      "Open pathname"
      (views:thunk pathname)
      "Open the repo pathname captured as source-pane evidence."))))

(defmethod views:title-bar-action-buttons ((target source-pane-file-target))
  (when-let (pathname (source-pane-layout-pathname target))
    (views:html
     (views:eval-button
      "Open pathname"
      (views:thunk pathname)
      "Open the repo pathname for this source-backed target."))))

(views:defview 👀overview (model source-pane-layout-model)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of model)))
                    (:p (views:esc (summary-of model)))
                    (:table :class "inspector-table"
                            (render-connect-field-row "Evidence layers"
                                                      (length (evidence-of model)))
                            (render-connect-field-row "Representative runtime snapshot"
                                                      (runtime-snapshot-of model))
                            (render-connect-field-row "Dispatch seam"
                                                      (source-pane-layout-model-evidence-by-id
                                                       model
                                                       "source-pane-layout/dispatch"))))))

(views:defview 👀evidence (model source-pane-layout-model)
  (views:html-view :title "Evidence" :priority 2
                   (let ((runtime-snapshot (runtime-snapshot-of model)))
                     (views:html
                      (:p
                       "This evidence table links the current html/markdown Source contract from plain dispatch to the explicit Connect source surface, shared line renderer, CSS, JS, and representative runtime state.")
                      (:table :class "inspector-table"
                              (:tr (:th "Layer")
                                   (:th "Role")
                                   (:th "Inspectable target")
                                   (:th "Source file")
                                   (:th "Why it matters"))
                              (loop for evidence in (evidence-of model)
                                    do (views:html
                                        (:tr
                                         (:td (views:esc (layer-of evidence)))
                                         (:td (views:esc (role-of evidence)))
                                         (:td (views:object-ref evidence))
                                         (:td (source-pane-layout-render-source-file-ref
                                               (relative-path-of evidence)))
                                         (:td (views:esc
                                               (or (why-it-matters-of evidence)
                                                   ""))))))
                              (:tr (:td "Runtime")
                                   (:td "Representative Source-pane state")
                                   (:td (views:object-ref runtime-snapshot))
                                   (:td (source-pane-layout-render-source-file-ref
                                         "hyperdoc/dom-annotations.lisp"))
                                   (:td
                                    (views:esc
                                     "Makes the current Connect source pane-state contract inspectable through the existing pane-state snapshot seam."))))))))

(views:defview 👀dispatch (model source-pane-layout-model)
  (views:html-view :title "Dispatch" :priority 3
                   (let ((dispatch-evidence
                          (source-pane-layout-model-evidence-by-id
                           model
                           "source-pane-layout/dispatch")))
                     (views:html
                      (:p
                       "html-page and markdown-page now use plain Source for reading while the explicit Connect source view keeps source-line anchoring available.")
                      (when dispatch-evidence
                        (source-pane-layout-render-detail-table
                         (detail-columns-of dispatch-evidence)
                         (detail-rows-of dispatch-evidence)))))))

(views:defview 👀runtime (model source-pane-layout-model)
  (views:html-view :title "Runtime" :priority 4
                   (let ((snapshot (runtime-snapshot-of model)))
                     (views:html
                      (:p
                       "The representative runtime state keeps the Connect source pane explicitly connectable: provider kind source-v1, dormant Dock presentation, and compact Connect/Annotation/Guide capability access.")
                      (:table :class "inspector-table"
                              (render-connect-field-row "Snapshot"
                                                        snapshot)
                              (render-connect-field-row "Provider kind"
                                                        (provider-kind-of snapshot))
                              (render-connect-field-row "Active tab"
                                                        (active-tab-of snapshot))
                              (render-connect-field-row "Presentation state"
                                                        (presentation-state-of snapshot))
                              (render-connect-rich-field-row "Compact capabilities"
                                                             (compact-capabilities-of snapshot)))))))

(views:defview 👀overview (evidence source-pane-layout-evidence)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of evidence)))
                    (:p (views:esc (summary-of evidence)))
                    (:table :class "inspector-table"
                            (render-connect-field-row "Layer" (layer-of evidence))
                            (render-connect-field-row "Role" (role-of evidence))
                            (render-connect-field-row "Source file"
                                                      (and (relative-path-of evidence)
                                                           (source-pane-layout-source-target
                                                            (relative-path-of evidence))))
                            (render-connect-field-row "Path status"
                                                      (source-pane-layout-path-status evidence))
                            (render-connect-field-row "Why it matters"
                                                      (why-it-matters-of evidence))))))

(views:defview 👀details (evidence source-pane-layout-evidence)
  (views:html-view :title "Details" :priority 2
                   (if (detail-rows-of evidence)
                       (source-pane-layout-render-detail-table
                        (detail-columns-of evidence)
                        (detail-rows-of evidence))
                       (views:html
                        (:p :style "opacity: 0.7;" "No detail rows recorded.")))))

(views:defview 👀path (evidence source-pane-layout-evidence)
  (views:html-view :title "Path" :priority 3
                   (let ((pathname (source-pane-layout-pathname evidence)))
                     (views:html
                      (:table :class "inspector-table"
                              (render-connect-field-row "Relative path"
                                                        (relative-path-of evidence))
                              (render-connect-field-row "Absolute pathname"
                                                        (and pathname
                                                             (namestring pathname)))
                              (render-connect-field-row "Source target"
                                                        (and (relative-path-of evidence)
                                                             (source-pane-layout-source-target
                                                              (relative-path-of evidence))))
                              (render-connect-field-row "Exists"
                                                        (dom-connect-bool-label
                                                         (and pathname
                                                              (probe-file pathname)))))))))

(views:defview 👀overview (target source-pane-file-target)
  (views:html-view :title "Overview" :priority 1
                   (let ((pathname (source-pane-layout-pathname target)))
                     (views:html
                      (:h3 (views:esc (title-of target)))
                      (:p (views:esc (summary-of target)))
                      (:table :class "inspector-table"
                              (render-connect-field-row "Relative path"
                                                        (relative-path-of target))
                              (render-connect-field-row "Absolute pathname"
                                                        (and pathname
                                                             (namestring pathname)))
                              (render-connect-field-row "Path status"
                                                        (source-pane-layout-path-status
                                                         target)))))))

(views:defview 👀source (target source-pane-file-target)
  (views:html-view :title "Source" :priority 2
                   (if-let (pathname (source-pane-layout-pathname target))
                       (hb:render-file-source-surface pathname)
                     (views:html
                      (:p :style "opacity: 0.7;" "Source pathname unavailable.")))))
