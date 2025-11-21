;;;; Link and backlink views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Link view
;;

(views:defview 👀links (page page)
  (when-let (links (links-of page))
    (views:html-view :title "Links" :priority 5
      (when-let (local-pages (cdr (assoc :page links)))
        (views:html
          (:details :open t
                    (:summary "Local pages")
                    (views:html-table (mapcar #'second local-pages)))))
      (when-let (hyperdocs (cdr (assoc :hyperdoc links)))
        (views:html
          (:details :open t
                    (:summary "HyperDocs")
                    (views:html-table hyperdocs
                                      :display (list #'first)
                                      :inspect #'second))))
      (when-let (hyperdoc-pages (cdr (assoc :hyperdoc-page links)))
        (views:html
          (:details :open t
                    (:summary "HyperDoc pages")
                    (views:html-table hyperdoc-pages
                                      :columns '("HyperDoc" "Page")
                                      :display (list #'(lambda (spec)
                                                         (-> spec first first
                                                                  find-hyperdoc))
                                                     #'second)
                                      :inspect-items :by-column))))
      (when-let (exprs (cdr (assoc :expr links)))
        (views:html
          (:details :open t
                    (:summary "Expressions")
                    (views:html-table exprs
                                      :inspect #'second
                                      :columns '("Expr" "Package")
                                      :display (list #'caar #'cdar)))))
      (when-let (web-links (cdr (assoc :web links)))
        (views:html
          (:details :open t
                    (:summary "Web links")
                    (:table :class "inspector-table"
                      (dolist (link (mapcar #'first web-links))
                        (views:html
                          (:tr (:td (:a :href link :target "_blank"
                                        (views:esc link)))))))))))))
