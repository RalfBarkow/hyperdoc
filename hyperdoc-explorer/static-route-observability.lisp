;;;; Explorer views for static route observability skill objects
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun render-static-asset-implemented-by (items)
  (if items
      (views:html
        (:ul
         (loop for item in items
               do (views:html
                    (:li (:tt (views:esc item)))))))
      (views:html
        (:p "No implementation anchors recorded."))))

(defun render-static-asset-resolution-row (resolution)
  (views:html
    (:tr (:td (:tt (views:esc (request-path-of resolution))))
         (:td (:tt (views:esc
                    (static-asset-owner-label
                     (owner-kind-of resolution)))))
         (:td (:tt (views:esc (mount-prefix-of resolution))))
         (:td (:tt (views:esc (namestring (resolved-path-of resolution))))))))

(defmethod views:text-representation ((resolution static-asset-path-resolution))
  (request-path-of resolution))

(defmethod views:text-representation ((surface static-asset-resolution-surface))
  (title-of surface))

(views:defview 👀summary (resolution static-asset-path-resolution)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of resolution)))
      (:p (views:esc (summary-of resolution)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Request path"))
                   (:td (:tt (views:esc (request-path-of resolution)))))
              (:tr (:td (views:esc "Owner"))
                   (:td (:tt (views:esc
                              (static-asset-owner-label
                               (owner-kind-of resolution))))))
              (:tr (:td (views:esc "Mount prefix"))
                   (:td (:tt (views:esc (mount-prefix-of resolution)))))
              (:tr (:td (views:esc "Evidence mode"))
                   (:td (:tt (views:esc
                              (observability-evidence-mode-label
                               (evidence-mode-of resolution))))))))))

(views:defview 👀resolution (resolution static-asset-path-resolution)
  (views:html-view :title "Resolution" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Root path"))
                   (:td (:tt (views:esc (namestring (root-path-of resolution))))))
              (:tr (:td (views:esc "Relative path"))
                   (:td (:tt (views:esc (relative-path-of resolution)))))
              (:tr (:td (views:esc "Resolved file"))
                   (:td (:tt (views:esc
                              (namestring (resolved-path-of resolution)))))))
      (:p "This view is a static ownership computation from the current server wiring; it does not prove the HTTP route is healthy by itself."))))

(views:defview 👀contract (resolution static-asset-path-resolution)
  (views:html-view :title "Contract" :priority 3
    (views:html
      (:p (views:esc (contract-of resolution)))
      (:h4 "Implemented by")
      (render-static-asset-implemented-by (implemented-by-of resolution))
      (:h4 "Worked example")
      (:p (views:esc (or (worked-example-of resolution)
                         "No worked example recorded."))))))

(views:defview 👀summary (surface static-asset-resolution-surface)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc (summary-of surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Evidence mode"))
                   (:td (:tt (views:esc
                              (observability-evidence-mode-label
                               (evidence-mode-of surface))))))
              (:tr (:td (views:esc "Asset count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (resolutions-of surface))))))))
      (:h4 "Asset resolutions")
      (:ul
       (loop for resolution in (resolutions-of surface)
             do (views:html
                  (:li (views:object-ref resolution)))))
      (:h4 "Notes")
      (:ul
       (loop for note in (notes-of surface)
             do (views:html
                  (:li (views:esc note))))))))

(views:defview 👀comparison (surface static-asset-resolution-surface)
  (views:html-view :title "Comparison" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Request path"))
                   (:th (views:esc "Owner"))
                   (:th (views:esc "Mount prefix"))
                   (:th (views:esc "Resolved file")))
              (loop for resolution in (resolutions-of surface)
                    do (render-static-asset-resolution-row resolution)))
      (:p "Use this comparison first: if the broken asset lives under /js/, inspect the CLOG static root; if it lives under /hyperbook-server/, inspect the explicit asset mount contract."))))
