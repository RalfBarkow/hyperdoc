;;;; Inspector views for historical ASDF declaration and resolution objects.

(in-package #:dreyeck/inspector/git)

(defmethod html-inspector-views:text-representation
    ((declaration dreyeck/git:historical-asdf-system-declaration))
  (format nil "Historical ASDF system ~A"
          (dreyeck/git:historical-asdf-system-declaration-canonical-name-of
           declaration)))

(defmethod html-inspector-views:text-representation
    ((reference dreyeck/git:historical-asdf-dependency-reference))
  (format nil "Historical ASDF dependency ~A"
          (or
           (dreyeck/git:historical-asdf-dependency-reference-canonical-name-of
            reference)
           (dreyeck/git:historical-asdf-dependency-reference-source-designator-of
            reference))))

(defmethod html-inspector-views:text-representation
    ((resolution dreyeck/git:current-asdf-dependency-resolution))
  (format nil "~:(~A~) in current Lisp image"
          (dreyeck/git:current-asdf-dependency-resolution-status-of
           resolution)))

(defmethod html-inspector-views:text-representation
    ((issue dreyeck/git:historical-asdf-parse-issue))
  (format nil "Historical ASDF parse issue at ~D"
          (dreyeck/git:historical-asdf-parse-issue-position-of issue)))

(defun render-asdf-reference-row (label value &key object display)
  (html-inspector-views:html
    (:tr
     (:th :style "text-align:left;vertical-align:top;"
          (html-inspector-views:esc label))
     (:td
      (if object
          (html-inspector-views:object-ref value :display display)
          (html-inspector-views:html
            (:code
             (html-inspector-views:esc
              (if (stringp value) value (prin1-to-string value))))))))))

(html-inspector-views:defview 👀historical-asdf-declaration
    (declaration dreyeck/git:historical-asdf-system-declaration)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-asdf-reference-row
               "Historical file"
               (dreyeck/git:historical-asdf-system-declaration-file-of
                declaration)
               :object t)
              (render-asdf-reference-row
               "Source designator"
               (dreyeck/git:historical-asdf-system-declaration-source-designator-of
                declaration))
              (render-asdf-reference-row
               "Canonical ASDF name"
               (dreyeck/git:historical-asdf-system-declaration-canonical-name-of
                declaration))
              (render-asdf-reference-row
               "Dependency references"
               (dreyeck/git:historical-asdf-system-declaration-dependencies-of
                declaration)
               :object t)))))

(html-inspector-views:defview 👀historical-asdf-reference
    (reference dreyeck/git:historical-asdf-dependency-reference)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (let ((resolution
            (dreyeck/git:historical-asdf-dependency-resolution reference)))
      (html-inspector-views:html
        (:table :class "inspector-table"
                (render-asdf-reference-row
                 "Historical file"
                 (dreyeck/git:historical-asdf-dependency-reference-file-of
                  reference)
                 :object t)
                (render-asdf-reference-row
                 "Historical system declaration"
                 (dreyeck/git:historical-asdf-dependency-reference-declaration-of
                  reference)
                 :object t)
                (render-asdf-reference-row
                 "Relation"
                 (dreyeck/git:historical-asdf-dependency-reference-relation-of
                  reference))
                (render-asdf-reference-row
                 "Source designator"
                 (dreyeck/git:historical-asdf-dependency-reference-source-designator-of
                  reference))
                (render-asdf-reference-row
                 "Canonical ASDF name"
                 (or
                  (dreyeck/git:historical-asdf-dependency-reference-canonical-name-of
                   reference)
                  "Unsupported complex designator"))
                (render-asdf-reference-row
                 "Current-image resolution"
                 resolution
                 :object t))))))

(html-inspector-views:defview 👀current-asdf-resolution
    (resolution dreyeck/git:current-asdf-dependency-resolution)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-asdf-reference-row
               "Historical reference"
               (dreyeck/git:current-asdf-dependency-resolution-reference-of
                resolution)
               :object t)
              (render-asdf-reference-row
               "Status"
               (dreyeck/git:current-asdf-dependency-resolution-status-of
                resolution))
              (render-asdf-reference-row
               "Observed in"
               (dreyeck/git:current-asdf-dependency-resolution-observed-in-of
                resolution))
              (when
                  (dreyeck/git:current-asdf-dependency-resolution-target-of
                   resolution)
                (render-asdf-reference-row
                 "Registered ASDF target"
                 (dreyeck/git:current-asdf-dependency-resolution-target-of
                  resolution)
                 :object t))))))

(html-inspector-views:defview 👀historical-asdf-parse-issue
    (issue dreyeck/git:historical-asdf-parse-issue)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-asdf-reference-row
               "Historical file"
               (dreyeck/git:historical-asdf-parse-issue-file-of issue)
               :object t)
              (render-asdf-reference-row
               "Source position"
               (dreyeck/git:historical-asdf-parse-issue-position-of issue))
              (render-asdf-reference-row
               "Parse issue"
               (dreyeck/git:historical-asdf-parse-issue-message-of issue))))))

(defun render-current-image-resolution (reference)
  (let* ((resolution
           (dreyeck/git:historical-asdf-dependency-resolution reference))
         (target
           (dreyeck/git:current-asdf-dependency-resolution-target-of
            resolution)))
    (if target
        (html-inspector-views:object-ref
         target
         :display
         (format nil "ASDF:SYSTEM ~A"
                 (dreyeck/git:historical-asdf-dependency-reference-canonical-name-of
                  reference)))
        (html-inspector-views:object-ref
         resolution
         :display
         (case
             (dreyeck/git:current-asdf-dependency-resolution-status-of
              resolution)
           (:unresolved "Unresolved in current image")
           (:unsupported "Unsupported dependency specification")
           (otherwise "Current-image resolution"))))))

(html-inspector-views:defview 👀asdf-references
    (file dreyeck/git:git-file-at-commit)
  (let ((projection
          (dreyeck/git:git-file-asdf-reference-projection file)))
    (when projection
      (html-inspector-views:html-view :title "ASDF references" :priority 3
        (html-inspector-views:html
          (:p
           (html-inspector-views:esc
            "Historical declarations are extracted from this Git blob. Current-image targets are resolved separately from ASDF's already registered systems."))
          (:table :class "inspector-table"
                  (:tr
                   (:th (html-inspector-views:esc "Historical system"))
                   (:th (html-inspector-views:esc "Relation"))
                   (:th (html-inspector-views:esc "Source designator"))
                   (:th (html-inspector-views:esc "Canonical ASDF name"))
                   (:th (html-inspector-views:esc "Current image")))
                  (dolist
                      (declaration
                        (dreyeck/git:historical-asdf-file-projection-declarations-of
                         projection))
                    (dolist
                        (reference
                          (dreyeck/git:historical-asdf-system-declaration-dependencies-of
                           declaration))
                      (html-inspector-views:html
                        (:tr
                         (:td
                          (html-inspector-views:object-ref
                           declaration
                           :display
                           (dreyeck/git:historical-asdf-system-declaration-canonical-name-of
                            declaration)))
                         (:td (:code
                               (html-inspector-views:esc
                                (prin1-to-string
                                 (dreyeck/git:historical-asdf-dependency-reference-relation-of
                                  reference)))))
                         (:td
                          (html-inspector-views:object-ref
                           reference
                           :display
                           (dreyeck/git:historical-asdf-dependency-reference-source-designator-of
                            reference)))
                         (:td (:code
                               (html-inspector-views:esc
                                (let ((canonical-name
                                        (dreyeck/git:historical-asdf-dependency-reference-canonical-name-of
                                         reference)))
                                  (if canonical-name
                                      (prin1-to-string canonical-name)
                                      "unsupported")))))
                         (:td (render-current-image-resolution reference))))))
          (when
              (dreyeck/git:historical-asdf-file-projection-issues-of
               projection)
            (html-inspector-views:html
              (:h3 (html-inspector-views:esc "Parse issues"))
              (:ul
               (dolist
                   (issue
                     (dreyeck/git:historical-asdf-file-projection-issues-of
                      projection))
                 (html-inspector-views:html
                   (:li
                    (html-inspector-views:object-ref issue)))))))))))))
