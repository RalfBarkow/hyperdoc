;;;; Explorer views for inspectable operational targets
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun render-shell-block (shell-text)
  (views:html
    (:pre :style "white-space: pre-wrap;"
          (views:esc shell-text))))

(defmethod views:text-representation ((host-target nixos-host-target))
  (format nil "~A@~A"
          (ssh-user-of host-target)
          (hostname-of host-target)))

(defmethod views:text-representation ((operation git-remote-operation))
  (title-of operation))

(defmethod views:text-representation ((resolution static-asset-path-resolution))
  (request-path-of resolution))

(defmethod views:text-representation ((surface static-asset-resolution-surface))
  (title-of surface))

(defun namestring-or-na (pathname)
  (if pathname
      (namestring pathname)
      "n/a"))

(defun yes/no-label (value)
  (if value "yes" "no"))

(views:defview 👀summary (host-target nixos-host-target)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of host-target)))
      (:p (views:esc (summary-of host-target)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Hostname"))
                   (:td (:tt (views:esc (hostname-of host-target)))))
              (:tr (:td (views:esc "SSH user"))
                   (:td (:tt (views:esc (ssh-user-of host-target)))))
              (:tr (:td (views:esc "Checkout root"))
                   (:td (:tt (views:esc
                              (namestring (checkout-root-of host-target))))))
              (:tr (:td (views:esc "Service name"))
                   (:td (:tt (views:esc (service-name-of host-target)))))
              (:tr (:td (views:esc "Deployment mode"))
                   (:td (:tt (views:esc
                              (deployment-mode-label
                               (deployment-mode-of host-target))))))))))

(views:defview 👀materialization (host-target nixos-host-target)
  (views:html-view :title "Materialization" :priority 2
    (views:html
      (:p "This host target renders a concrete shell block for inspecting the live service context without executing deployment changes.")
      (render-shell-block (materialization-shell-block host-target)))))

(views:defview 👀summary (operation git-remote-operation)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of operation)))
      (:p (views:esc (summary-of operation)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Host target"))
                   (:td (views:object-ref (host-target-of operation))))
              (:tr (:td (views:esc "Operation kind"))
                   (:td (:tt (views:esc
                              (git-remote-operation-kind-label
                               (operation-kind-of operation))))))
              (:tr (:td (views:esc "Remote name"))
                   (:td (:tt (views:esc (remote-name-of operation)))))
              (:tr (:td (views:esc "Remote URL"))
                   (:td (:tt (views:esc (remote-url-of operation)))))
              (:tr (:td (views:esc "Branch"))
                   (:td (:tt (views:esc (branch-of operation)))))))))

(views:defview 👀materialization (operation git-remote-operation)
  (views:html-view :title "Materialization" :priority 2
    (views:html
      (:p "This operation renders the exact host-aware shell block to run. It does not execute the remote command from inside HyperDoc.")
      (render-shell-block (materialization-shell-block operation)))))

(views:defview 👀summary (resolution static-asset-path-resolution)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of resolution)))
      (:p (views:esc (summary-of resolution)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Request path"))
                   (:td (:tt (views:esc (request-path-of resolution)))))
              (:tr (:td (views:esc "Asset family"))
                   (:td (:tt (views:esc
                              (static-asset-family-label
                               (asset-family-of resolution))))))
              (:tr (:td (views:esc "Owner layer"))
                   (:td (:tt (views:esc
                              (static-asset-owner-layer-label
                               (owner-layer-of resolution))))))
              (:tr (:td (views:esc "Status"))
                   (:td (views:esc (current-status-summary-of resolution))))))))

(views:defview 👀resolution (resolution static-asset-path-resolution)
  (views:html-view :title "Resolution" :priority 2
    (views:html
      (:p "This view shows the mounted root and the computed filesystem target for the request path. It does not make a live HTTP request.")
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Mounted root"))
                   (:td (:tt (views:esc
                              (namestring-or-na (mounted-root-of resolution))))))
              (:tr (:td (views:esc "Resolved filesystem path"))
                   (:td (:tt (views:esc
                              (namestring-or-na
                               (resolved-filesystem-path-of resolution))))))
              (:tr (:td (views:esc "Exists?"))
                   (:td (:tt (views:esc
                              (yes/no-label (exists-p-of resolution))))))))))

(views:defview 👀contract (resolution static-asset-path-resolution)
  (views:html-view :title "Contract" :priority 3
    (views:html
      (:p "This contract view explains which runtime layer is expected to own the request path.")
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Request path"))
                   (:td (:tt (views:esc (request-path-of resolution)))))
              (:tr (:td (views:esc "Owner layer"))
                   (:td (:tt (views:esc
                              (static-asset-owner-layer-label
                               (owner-layer-of resolution))))))
              (:tr (:td (views:esc "Expected HTTP contract"))
                   (:td (views:esc (expected-http-contract-of resolution))))))))

(views:defview 👀summary (surface static-asset-resolution-surface)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc (summary-of surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Computation mode"))
                   (:td (:tt (views:esc
                              (static-asset-computation-mode-label
                               (computation-mode-of surface))))))
              (:tr (:td (views:esc "Tracked request paths"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (entries-of surface))))))))
      (:ul
       (loop for resolution in (entries-of surface)
             do (views:html
                  (:li (views:object-ref resolution))))))))

(views:defview 👀comparison (surface static-asset-resolution-surface)
  (views:html-view :title "Comparison" :priority 2
    (views:html
      (:p "Side-by-side comparison of the four concrete request paths. This surface is based on static computation from the current mounted roots.")
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Request path"))
                    (:th (views:esc "Asset family"))
                    (:th (views:esc "Owner layer"))
                    (:th (views:esc "Mounted root"))
                    (:th (views:esc "Resolved path"))
                    (:th (views:esc "Exists?"))
                    (:th (views:esc "Status"))))
              (:tbody
               (loop for resolution in (entries-of surface)
                     do (views:html
                          (:tr
                           (:td (views:object-ref resolution))
                           (:td (:tt (views:esc
                                      (static-asset-family-label
                                       (asset-family-of resolution)))))
                           (:td (:tt (views:esc
                                      (static-asset-owner-layer-label
                                       (owner-layer-of resolution)))))
                           (:td (:tt (views:esc
                                      (namestring-or-na
                                       (mounted-root-of resolution)))))
                           (:td (:tt (views:esc
                                      (namestring-or-na
                                       (resolved-filesystem-path-of resolution)))))
                           (:td (:tt (views:esc
                                      (yes/no-label
                                       (exists-p-of resolution)))))
                           (:td (views:esc
                                 (current-status-summary-of resolution)))))))))))
