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

(defmethod views:text-representation
    ((run dreyeck-git-readiness-state-machine-run))
  (title-of run))

(defun namestring-or-na (pathname)
  (if pathname
      (namestring pathname)
      "n/a"))

(defun yes/no-label (value)
  (if value "yes" "no"))

(defun namestring-or-unknown (pathname)
  (if pathname
      (namestring pathname)
      "unknown"))

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

(views:defview 👀summary (run dreyeck-git-readiness-state-machine-run)
  (views:html-view :title "Summary" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of run)))
                    (:p (views:esc (summary-of run)))
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Current readiness state"))
                                 (:td (:tt (views:esc
                                            (dreyeck-git-readiness-state-label
                                             (intern (string-upcase
                                                      (state-machine-run-current-state-of run))
                                                     :keyword))))))
                            (:tr (:td (views:esc "Runtime origin"))
                                 (:td (:tt (views:esc
                                            (dreyeck-git-readiness-runtime-origin-label
                                             (dreyeck-git-readiness-runtime-origin-of run))))))
                            (:tr (:td (views:esc "Git executable available"))
                                 (:td (:tt (views:esc
                                            (yes/no-label
                                             (dreyeck-git-readiness-git-executable-available-p-of run))))))
                            (:tr (:td (views:esc "Requested program"))
                                 (:td (:tt (views:esc
                                            (or (dreyeck-git-readiness-requested-program-of run)
                                                "n/a")))))
                            (:tr (:td (views:esc "Resolved program"))
                                 (:td (:tt (views:esc
                                            (or (dreyeck-git-readiness-resolved-program-of run)
                                                "n/a")))))
                            (:tr (:td (views:esc "Effective repository root"))
                                 (:td (:tt (views:esc
                                            (namestring-or-na
                                             (dreyeck-git-readiness-effective-repository-root-of run))))))
                            (:tr (:td (views:esc "Repository root source"))
                                 (:td (:tt (views:esc
                                            (git-repository-root-source-label
                                             (dreyeck-git-readiness-repository-root-source-of run))))))
                            (:tr (:td (views:esc ".git metadata path"))
                                 (:td (:tt (views:esc
                                            (namestring-or-na
                                             (dreyeck-git-readiness-git-metadata-path-of run))))))
                            (:tr (:td (views:esc ".git metadata available"))
                                 (:td (:tt (views:esc
                                            (yes/no-label
                                             (dreyeck-git-readiness-git-metadata-present-p-of run))))))
                            (:tr (:td (views:esc "Upstream remote present"))
                                 (:td (:tt (views:esc
                                            (yes/no-label
                                             (dreyeck-git-readiness-upstream-remote-present-p-of run))))))
                            (:tr (:td (views:esc "Upstream remote URL"))
                                 (:td (:tt (views:esc
                                            (or (dreyeck-git-readiness-upstream-remote-url-of run)
                                                "n/a")))))
                            (:tr (:td (views:esc "upstream/main fetched"))
                                 (:td (:tt (views:esc
                                            (yes/no-label
                                             (dreyeck-git-readiness-upstream-main-fetched-p-of run))))))
                            (:tr (:td (views:esc "Host target"))
                                 (:td (views:object-ref
                                       (dreyeck-git-readiness-host-target-of run))))
                            (:tr (:td (views:esc "State machine"))
                                 (:td (views:object-ref
                                       (state-machine-run-machine-of run)
                                       :display "Overview"
                                       :select "Overview")))
                            (:tr (:td (views:esc "Blocking condition"))
                                 (:td (if-let (condition
                                               (dreyeck-git-readiness-blocking-condition-of run))
                                          (views:object-ref condition)
                                        (views:html (:tt "n/a"))))))
                    (:h4 "Explicit next operations")
                    (:ul
                     (:li (views:object-ref
                           (dreyeck-git-readiness-add-upstream-remote-operation-of run)
                           :display "Add upstream remote"
                           :select "Summary"))
                     (:li (views:object-ref
                           (dreyeck-git-readiness-fetch-upstream-main-operation-of run)
                           :display "Fetch upstream/main"
                           :select "Summary"))))))

(views:defview 👀operational-path (run dreyeck-git-readiness-state-machine-run)
  (views:html-view :title "Operational path" :priority 2
                   (let ((state (state-machine-run-current-state-of run)))
                     (views:html
                      (:p (views:esc
                           "These are explicit follow-up objects only. HyperDoc does not execute add-remote or fetch as a side effect of opening this readiness run."))
                      (:table :class "inspector-table"
                              (:tr (:td (views:esc "Current state"))
                                   (:td (:tt (views:esc state))))
                              (:tr (:td (views:esc "Host target"))
                                   (:td (views:object-ref
                                         (dreyeck-git-readiness-host-target-of run))))
                              (:tr (:td (views:esc "Add upstream remote"))
                                   (:td (views:object-ref
                                         (dreyeck-git-readiness-add-upstream-remote-operation-of run)
                                         :display "Materialization"
                                         :select "Materialization")))
                              (:tr (:td (views:esc "Fetch upstream/main"))
                                   (:td (views:object-ref
                                         (dreyeck-git-readiness-fetch-upstream-main-operation-of run)
                                         :display "Materialization"
                                         :select "Materialization"))))
                      (:h4 "Interpretation")
                      (:p (views:esc
                           (cond
                             ((string= state "live-checkout-no-upstream-remote")
                              "The runtime sees a live checkout, but it still needs the explicit add-remote step before Git-backed inspection can use upstream/main.")
                             ((string= state "upstream-remote-present-not-fetched")
                              "The upstream remote exists, but the runtime still needs the explicit fetch step before Git-backed inspection can use upstream/main.")
                             ((string= state "ready-for-git-backed-inspection")
                              "No repair operation is required. Rerunning the Git-backed example should use the normal inspection path.")
                             (t
                              "Inspect the blocking condition and explicit operations to decide the next bounded preparation step."))))))))

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
