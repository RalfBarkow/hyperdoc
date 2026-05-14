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
    (let ((primary (codex-home-primary-review-object-of home))
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
