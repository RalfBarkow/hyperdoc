;;;; Explorer view for Codex collaboration home topic

(in-package :hyperdoc)

(views:defview 👀home (home codex-home)
  (labels ((page-ref (title)
             (let ((page (find-page *hyperdoc* title :signal-error? nil)))
               (if page
                   (views:object-ref page :display title)
                   (views:html (views:esc title)))))
           (object-ref (object label)
             (views:object-ref object :display label))
           (command-item (command)
             (views:html
              (:li (:tt (views:esc command))))))
    (let ((context-window (codex-home-context-window-of home))
          (primary (codex-home-primary-review-object-of home))
          (related (codex-home-related-objects-of home))
          (commit-boundary (codex-home-commit-boundary-of home)))
      (views:html-view :title "Home" :priority 0
                       (views:add-asset-path "/hyperbook/"
                                             (asdf:system-relative-pathname
                                              :hyperbook
                                              "assets/hyperbook/"))
                       (views:include-css "/hyperbook/css/hyperbook.css")
                       (views:html
                        (:div :class "hyperbook-page"
                              (:h1 (views:esc (title-of home)))
                              (:p (views:esc (summary-of home)))
                              (:p (:b "Current slice: ")
                                  (views:esc
                                   (codex-home-current-slice-of home)))
                              (when commit-boundary
                                (views:html
                                 (:p (:b "Commit boundary: ")
                                     (views:esc commit-boundary))))
                              (:h2 "Review")
                              (:ul
                               (:li (object-ref context-window
                                                "Context window"))
                               (:li (object-ref primary
                                                "kioskberrli-dashboard"))
                               (:li (object-ref (first related)
                                                "kioskberrli-dashboard-status"))
                               (:li (object-ref (second related)
                                                "kioskberrli-current-blocker"))
                               (:li (object-ref (third related)
                                                "kioskberrli-build-evidence-status"))
                               (:li (object-ref (fourth related)
                                                "kioskberrli-dashboard-stations")))
                              (:h2 "Pages")
                              (:ul
                               (dolist (title (codex-home-relevant-pages-of home))
                                 (views:html
                                  (:li (page-ref title)))))
                              (:h2 "Validation commands")
                              (:ul
                               (dolist (command
                                         (codex-home-validation-commands-of home))
                                 (command-item command)))))))))

(views:defview 👀context (window codex-context-window)
  (labels ((text-list (items)
             (views:html
              (:ul
               (dolist (item items)
                 (views:html
                  (:li (views:esc item)))))))
           (command-list (commands)
             (views:html
              (:ul
               (dolist (command commands)
                 (views:html
                  (:li (:tt (views:esc command))))))))
           (object-list (objects labels)
             (views:html
              (:ul
               (loop for object in objects
                     for label in labels
                     do (views:html
                         (:li (views:object-ref object
                                                :display label)))))))
           (context-list (contexts)
             (views:html
              (:ul
               (dolist (context contexts)
                 (views:html
                  (:li (views:object-ref context
                                         :display (title-of context))))))))
           (entry-list (entries)
             (views:html
              (:ul
               (dolist (entry entries)
                 (views:html
                  (:li
                   (views:object-ref entry :display (title-of entry))
                   " "
                   (:small (views:esc
                            (codex-context-entry-role-of entry))))))))))
    (views:html-view :title "Context" :priority 0
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc (title-of window)))
                            (:p (:b "Source: ")
                                (views:esc
                                 (codex-context-window-source-of window)))
                            (:p (:b "Captured at: ")
                                (views:esc
                                 (codex-context-window-captured-at-of window)))
                            (:p (views:esc (summary-of window)))
                            (:p (:b "Depth: ")
                                (views:esc
                                 (format nil "~A / ~A"
                                         (codex-context-window-depth-of window)
                                         (codex-context-window-max-depth-of window))))
                            (let ((previous-context
                                    (codex-context-window-previous-context-window-of
                                     window)))
                              (when previous-context
                                (views:html
                                 (:h2 "Previous context")
                                 (:p
                                  (views:object-ref previous-context
                                                    :display
                                                    (title-of
                                                     previous-context))))))
                            (when (codex-context-window-nested-context-windows-of
                                   window)
                              (views:html
                               (:h2 "Snapshot contexts")
                               (context-list
                                (codex-context-window-nested-context-windows-of
                                 window))))
                            (:h2 "Structural proof")
                            (:p
                             (views:object-ref
                              (codex-context-window-nor-proof window)
                              :display "NOR structural proof"))
                            (:h2 "Entries")
                            (entry-list
                             (codex-context-window-entries-of window))
                            (:h2 "Open questions")
                            (text-list
                             (codex-context-window-open-questions-of window))
                            (:h2 "Proposed actions")
                            (text-list
                             (codex-context-window-proposed-actions-of window))
                            (:h2 "Related objects")
                            (object-list
                             (codex-context-window-related-objects-of window)
                             '("kioskberrli-dashboard"
                               "kioskberrli-dashboard-status"
                               "kioskberrli-current-blocker"
                               "kioskberrli-build-evidence-status"
                               "kioskberrli-dashboard-stations"))
                            (:h2 "Validation commands")
                            (command-list
                             (codex-context-window-validation-commands-of window))
                            (:h2 "Provenance")
                            (text-list
                             (codex-context-window-provenance-of window)))))))

(views:defview 👀raw (window codex-context-window)
  (let ((raw-text (codex-context-window-raw-text-of window)))
    (when raw-text
      (views:html-view :title "Raw" :priority 5
                       (views:add-asset-path "/hyperbook/"
                                             (asdf:system-relative-pathname
                                              :hyperbook
                                              "assets/hyperbook/"))
                       (views:include-css "/hyperbook/css/hyperbook.css")
                       (views:html
                        (:div :class "hyperbook-page"
                              (:h1 "Raw")
                              (:pre (views:esc raw-text))))))))

(views:defview 👀entry (entry codex-context-entry)
  (labels ((text-list (items)
             (views:html
              (:ul
               (dolist (item items)
                 (views:html
                  (:li (views:esc item)))))))
           (object-list (objects)
             (views:html
              (:ul
               (dolist (object objects)
                 (views:html
                  (:li (views:object-ref object))))))))
    (views:html-view :title "Entry" :priority 0
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc (title-of entry)))
                            (:p (:b "Role: ")
                                (views:esc
                                 (codex-context-entry-role-of entry)))
                            (:p (:b "Timestamp: ")
                                (views:esc
                                 (codex-context-entry-timestamp-of entry)))
                            (:p (views:esc
                                 (codex-context-entry-text-of entry)))
                            (:h2 "References")
                            (text-list
                             (codex-context-entry-references-of entry))
                            (:h2 "Derived objects")
                            (object-list
                             (codex-context-entry-derived-objects-of entry)))))))

(views:defview 👀proof (proof codex-context-window-structural-proof)
  (labels ((code-value (value)
             (views:html
              (:tt (views:esc (prin1-to-string value)))))
           (graph-summary (graph)
             (views:html
              (:ul
               (:li (:b "Nodes: ")
                    (views:esc
                     (write-to-string (length (getf graph :nodes)))))
               (:li (:b "Edges: ")
                    (views:esc
                     (write-to-string (length (getf graph :edges)))))
               (:li (:b "Limit: ")
                    (views:esc
                     (write-to-string (getf graph :limit))))
               (:li (:b "Terminal: ")
                    (code-value (getf graph :terminal)))
               (:li (:b "Truncated: ")
                    (views:esc
                     (if (getf graph :truncated-p) "true" "false"))))))
           (graph-nodes (graph)
             (views:html
              (:ul
               (dolist (node (getf graph :nodes))
                 (views:html
                  (:li
                   (views:esc (getf node :id))
                   " "
                   (:small
                    (views:esc
                     (format nil "depth ~A / ~A"
                             (getf node :depth)
                             (getf node :max-depth))))))))))
           (graph-edges (graph)
             (views:html
              (:ul
               (dolist (edge (getf graph :edges))
                 (views:html
                  (:li (code-value edge)))))))
           (violation-list (violations)
             (if violations
                 (views:html
                  (:ul
                   (dolist (violation violations)
                     (views:html
                      (:li (code-value violation))))))
                 (views:html
                  (:p "None")))))
    (let ((context-window
            (codex-context-window-structural-proof-context-window-of proof))
          (graph (codex-context-window-structural-proof-graph-of proof)))
      (views:html-view :title "Proof" :priority 0
                       (views:add-asset-path "/hyperbook/"
                                             (asdf:system-relative-pathname
                                              :hyperbook
                                              "assets/hyperbook/"))
                       (views:include-css "/hyperbook/css/hyperbook.css")
                       (views:html
                        (:div :class "hyperbook-page"
                              (:h1 (views:esc (title-of proof)))
                              (:p (:b "Result: ")
                                  (views:esc
                                   (if (codex-context-window-structural-proof-result-of
                                        proof)
                                       "true"
                                       "false")))
                              (:p
                               (views:esc
                                (codex-context-window-structural-proof-interpretation-of
                                 proof)))
                              (when context-window
                                (views:html
                                 (:p (:b "Context window: ")
                                     (views:object-ref context-window
                                                       :display
                                                       (title-of
                                                        context-window)))))
                              (:h2 "Graph summary")
                              (graph-summary graph)
                              (:h3 "Nodes")
                              (graph-nodes graph)
                              (:h3 "Edges")
                              (graph-edges graph)
                              (:h2 "NOR expression")
                              (:pre
                               (views:esc
                                (prin1-to-string
                                 (codex-context-window-structural-proof-expression-of
                                  proof))))
                              (:h2 "Violations")
                              (violation-list
                               (codex-context-window-structural-proof-violations-of
                                proof))))))))
