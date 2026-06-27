;;;; Explorer view for Codex collaboration home topic

(eval-when (:compile-toplevel :load-toplevel :execute)
  (trivial-package-local-nicknames:add-package-local-nickname
   :views :html-inspector-views :dreyeck/codex))

(in-package :dreyeck/codex)

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
          (recent-changes (codex-home-recent-changes-of home))
          (next (codex-home-next-of home))
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
                               (:li (object-ref recent-changes
                                                "Recent Changes"))
                               (:li (object-ref next
                                                "Next"))
                               (:li (object-ref primary
                                                "kioskbeerli-dashboard"))
                               (:li (object-ref (first related)
                                                "kioskbeerli-dashboard-status"))
                               (:li (object-ref (second related)
                                                "kioskbeerli-current-blocker"))
                               (:li (object-ref (third related)
                                                "kioskbeerli-build-evidence-status"))
                               (:li (object-ref (fourth related)
                                                "kioskbeerli-dashboard-stations")))
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
                             '("kioskbeerli-dashboard"
                               "kioskbeerli-dashboard-status"
                               "kioskbeerli-current-blocker"
                               "kioskbeerli-build-evidence-status"
                               "kioskbeerli-dashboard-stations"))
                            (:h2 "Validation commands")
                            (command-list
                             (codex-context-window-validation-commands-of window))
                            (:h2 "Provenance")
                            (text-list
                             (codex-context-window-provenance-of window)))))))

(views:defview 👀recent-changes (changes codex-recent-changes)
  (labels ((text-list (items)
             (if items
                 (views:html
                  (:ul
                   (dolist (item items)
                     (views:html
                      (:li (views:esc item))))))
                 (views:html
                  (:p "None"))))
           (entry-list (entries)
             (views:html
              (:ul
               (dolist (entry entries)
                 (views:html
                  (:li
                   (views:object-ref entry :display (title-of entry))
                   " "
                   (:small
                    (views:esc
                     (prin1-to-string
                      (codex-recent-change-kind-of entry)))))))))))
    (views:html-view :title "Recent Changes" :priority 0
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc (title-of changes)))
                            (:p (:b "Source: ")
                                (views:esc
                                 (codex-recent-changes-source-of changes)))
                            (:p (:b "Captured at: ")
                                (views:esc
                                 (codex-recent-changes-captured-at-of changes)))
                            (:p (:b "Scope: ")
                                (views:esc
                                 (codex-recent-changes-scope-of changes)))
                            (:p (views:esc (summary-of changes)))
                            (:h2 "Neighborhood")
                            (text-list
                             (codex-recent-changes-neighborhood-of changes))
                            (:h2 "Entries")
                            (entry-list
                             (codex-recent-changes-entries-of changes))
                            (:h2 "Next")
                            (:p
                             (views:object-ref
                              (codex-next-for-recent-changes
                               changes
                               :limit
                               (codex-recent-changes-limit-of changes))
                              :display "Next routes from this snapshot"))
                            (:h2 "Provenance")
                            (text-list
                             (codex-recent-changes-provenance-of changes)))))))

(views:defview 👀change (change codex-recent-change)
  (labels ((text-list (items)
             (if items
                 (views:html
                  (:ul
                   (dolist (item items)
                     (views:html
                      (:li (views:esc item))))))
                 (views:html
                  (:p "None"))))
           (maybe-object (label object)
             (when object
               (views:html
                (:p (:b (views:esc label))
                    ": "
                    (views:object-ref
                     object
                     :display (or (ignore-errors (title-of object))
                                  (prin1-to-string object))))))))
    (views:html-view :title "Change" :priority 0
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc (title-of change)))
                            (:p (:b "Kind: ")
                                (views:esc
                                 (prin1-to-string
                                  (codex-recent-change-kind-of change))))
                            (:p (:b "Changed at: ")
                                (views:esc
                                 (codex-recent-change-changed-at-of change)))
                            (:p (:b "Actor: ")
                                (views:esc
                                 (codex-recent-change-actor-of change)))
                            (:p (views:esc (summary-of change)))
                            (maybe-object
                             "Source object"
                             (codex-recent-change-source-object-of change))
                            (maybe-object
                             "Target object"
                             (codex-recent-change-target-object-of change))
                            (:h2 "Affected files")
                            (text-list
                             (codex-recent-change-affected-files-of change))
                            (:h2 "Affected pages")
                            (text-list
                             (codex-recent-change-affected-pages-of change))
                            (:h2 "Evidence")
                            (text-list
                             (codex-recent-change-evidence-of change))
                            (:h2 "Route hints")
                            (text-list
                             (codex-recent-change-route-hints-of change)))))))

(views:defview 👀next (next codex-next)
  (labels ((text-list (items)
             (if items
                 (views:html
                  (:ul
                   (dolist (item items)
                     (views:html
                      (:li (views:esc item))))))
                 (views:html
                  (:p "None"))))
           (value-ref (value)
             (cond
               ((null value)
                (views:html "None"))
               ((stringp value)
                (views:html (views:esc value)))
               ((or (symbolp value) (numberp value))
                (views:html (views:esc (prin1-to-string value))))
               (t
                (views:object-ref
                 value
                 :display (or (ignore-errors (title-of value))
                              (prin1-to-string value))))))
           (route-label (route)
             (format nil "~A -> ~A / ~A"
                     (codex-next-route-source-topic-of route)
                     (or (codex-next-route-target-topic-of route)
                         "operation")
                     (codex-next-route-target-operation-of route)))
           (route-list (routes)
             (views:html
              (:ul
               (loop for route in routes
                     repeat 5
                     do (views:html
                         (:li
                          (views:object-ref route
                                            :display (route-label route)))))))))
    (views:html-view :title "Next" :priority 0
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc (title-of next)))
                            (:p (:b "Source: ")
                                (value-ref (codex-next-source-of next)))
                            (:p (:b "Generated at: ")
                                (views:esc
                                 (codex-next-generated-at-of next)))
                            (:p (views:esc (summary-of next)))
                            (:h2 "Primary routes")
                            (route-list (codex-next-routes-of next))
                            (:h2 "Provenance")
                            (text-list
                             (codex-next-provenance-of next)))))))

(views:defview 👀route (route codex-next-route)
  (labels ((text-list (items)
             (if items
                 (views:html
                  (:ul
                   (dolist (item items)
                     (views:html
                      (:li (views:esc item))))))
                 (views:html
                 (:p "None"))))
           (value-string (value)
             (cond
               ((null value) "None")
               ((stringp value) value)
               ((or (symbolp value) (numberp value))
                (prin1-to-string value))
               (t (princ-to-string value))))
           (value-row (label value)
             (views:html
              (:p (:b (views:esc label))
                  ": "
                  (views:esc (value-string value)))))
           (object-list (objects)
             (if objects
                 (views:html
                  (:ul
                   (dolist (object objects)
                     (views:html
                      (:li
                       (views:object-ref
                        object
                        :display (or (ignore-errors (title-of object))
                                     (prin1-to-string object))))))))
                 (views:html
                  (:p "None"))))
           (derived-change (change)
             (if change
                 (views:object-ref change :display (title-of change))
                 (views:html "None"))))
    (views:html-view :title "Route" :priority 0
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc (title-of route)))
                            (:p (:b "Route: ")
                                (views:esc
                                 (format nil "~A -> ~A / ~A"
                                         (codex-next-route-source-topic-of
                                          route)
                                         (or
                                          (codex-next-route-target-topic-of
                                           route)
                                          "operation")
                                         (codex-next-route-target-operation-of
                                          route))))
                            (value-row
                             "Source topic"
                             (codex-next-route-source-topic-of route))
                            (value-row
                             "Target topic"
                             (codex-next-route-target-topic-of route))
                            (value-row
                             "Target operation"
                             (codex-next-route-target-operation-of route))
                            (:p (:b "Reason: ")
                                (views:esc
                                 (codex-next-route-reason-of route)))
                            (:p (:b "Derived from: ")
                                (derived-change
                                 (codex-next-route-derived-from-of route)))
                            (value-row
                             "Priority"
                             (codex-next-route-priority-of route))
                            (value-row
                             "Safety level"
                             (codex-next-route-safety-level-of route))
                            (value-row
                             "Status"
                             (codex-next-route-status-of route))
                            (value-row
                             "Action label"
                             (codex-next-route-action-label-of route))
                            (:h2 "Evidence")
                            (text-list
                             (codex-next-route-evidence-of route))
                            (:h2 "Related objects")
                            (object-list
                             (codex-next-route-related-objects-of route)))))))

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
