;;;; Inspector views for page-as-ASDF-system reload boundaries.

(in-package :hyperdoc)

(defmethod views:text-representation ((system page-system))
  (page-system-title system))

(defmethod views:text-representation ((provider page-runtime-provider))
  (page-runtime-provider-id provider))

(defmethod views:text-representation ((report page-system-reload-report))
  (format nil "~A reload ~:[not ready~;ready~]"
          (page-system-reload-report-asdf-system-name report)
          (page-system-reload-report-display-ready-p report)))

(defmethod views:text-representation ((registry page-system-registry))
  (format nil "Page system registry (~D systems)"
          (length (page-system-registry-systems registry))))

(defun render-page-system-list (items)
  (if items
      (views:html
       (:ul
        (dolist (item items)
          (views:html
           (:li
            (if (typep item 'standard-object)
                (views:object-ref item)
                (views:esc (format nil "~A" item))))))))
      (views:html (:span "-"))))

(defun render-page-system-row (label value)
  (views:html
   (:tr
    (:th (views:esc label))
    (:td
     (cond
       ((and (listp value) (not (null value)))
        (render-page-system-list value))
       ((typep value 'standard-object)
        (views:object-ref value))
       (value
        (views:esc (format nil "~A" value)))
       (t
        (views:esc "-")))))))

(views:defview 👀overview (system page-system)
  (views:html-view
   :title "Overview"
   :priority 1
   (views:html
    (:h3 (views:esc (page-system-title system)))
    (:p (views:esc (or (page-system-description system)
                       "Page-system reload boundary.")))
    (:table :class "inspector-table"
            (render-page-system-row "Kind" (page-system-kind system))
            (render-page-system-row "ASDF system"
                                    (page-system-asdf-system-name system))
            (render-page-system-row "Page locator"
                                    (page-system-page-locator system))
            (render-page-system-row "Runtime systems"
                                    (page-system-runtime-systems system))
            (render-page-system-row "Runtime entry points"
                                    (page-system-runtime-entry-points system))
            (render-page-system-row "Display contract"
                                    (page-system-display-contract system))
            (render-page-system-row "Inspection entry points"
                                    (page-system-inspection-entry-points system))
            (render-page-system-row "Validation entry points"
                                    (page-system-validation-entry-points system)))
    (:h4 "Reload")
    (:pre (views:esc
           (format nil "(hyperdoc:page-system-reload (hyperdoc:find-page-system :~A) :force t)"
                   (page-system-asdf-system-name system)))))))

(views:defview 👀runtime (system page-system)
  (views:html-view
   :title "Runtime"
   :priority 2
   (views:html
    (:table :class "inspector-table"
            (:tr (:th "Provider")
                 (:th "Kind")
                 (:th "ASDF system")
                 (:th "Ensure")
                 (:th "Readiness")
                 (:th "Display notes"))
            (dolist (provider (page-system-runtime-providers system))
              (views:html
               (:tr
                (:td (views:object-ref provider))
                (:td (views:esc
                      (format nil "~A" (page-runtime-provider-kind provider))))
                (:td (views:esc
                      (page-runtime-provider-asdf-system-name provider)))
                (:td (views:esc
                      (or (page-runtime-provider-ensure-function provider)
                          "-")))
                (:td (views:esc
                      (or (page-runtime-provider-readiness-function provider)
                          "-")))
                (:td (views:esc
                      (or (page-runtime-provider-display-notes provider)
                          "-"))))))))))

(views:defview 👀sources (system page-system)
  (views:html-view
   :title "Sources"
   :priority 3
   (views:html
    (:h4 "Source files")
    (render-page-system-list (page-system-source-files system))
    (:h4 "Artifacts")
    (render-page-system-list (page-system-artifacts system)))))

(views:defview 👀overview (provider page-runtime-provider)
  (views:html-view
   :title "Overview"
   :priority 1
   (views:html
    (:h3 (views:esc (page-runtime-provider-id provider)))
    (:table :class "inspector-table"
            (render-page-system-row "Kind"
                                    (page-runtime-provider-kind provider))
            (render-page-system-row "ASDF system"
                                    (page-runtime-provider-asdf-system-name
                                     provider))
            (render-page-system-row "Ensure"
                                    (page-runtime-provider-ensure-function
                                     provider))
            (render-page-system-row "Readiness"
                                    (page-runtime-provider-readiness-function
                                     provider))
            (render-page-system-row "Display notes"
                                    (page-runtime-provider-display-notes
                                     provider))))))

(views:defview 👀overview (report page-system-reload-report)
  (views:html-view
   :title "Overview"
   :priority 1
   (views:html
    (:h3 (views:esc
          (page-system-reload-report-asdf-system-name report)))
    (:table :class "inspector-table"
            (render-page-system-row "Page system"
                                    (page-system-reload-report-page-system
                                     report))
            (render-page-system-row "Loaded"
                                    (page-system-reload-report-loaded-p report))
            (render-page-system-row "Display ready"
                                    (page-system-reload-report-display-ready-p
                                     report))
            (render-page-system-row "Warnings"
                                    (page-system-reload-report-warnings report))))))

(views:defview 👀overview (registry page-system-registry)
  (views:html-view
   :title "Overview"
   :priority 1
   (views:html
    (:h3 "Page system registry")
    (:table :class "inspector-table"
            (:tr (:th "Title")
                 (:th "Kind")
                 (:th "ASDF system")
                 (:th "Page locator")
                 (:th "Runtime systems"))
            (dolist (system (sort (copy-list (page-system-registry-systems registry))
                                  #'string<
                                  :key #'page-system-asdf-system-name))
              (views:html
               (:tr
                (:td (views:object-ref system))
                (:td (views:esc (format nil "~A" (page-system-kind system))))
                (:td (views:esc (page-system-asdf-system-name system)))
                (:td (views:esc (page-system-page-locator system)))
                (:td (render-page-system-list
                      (page-system-runtime-systems system))))))))))
