;; Inspector views for local Federated Wiki pages

(in-package #:dreyeck/local-fedwiki-page/inspector)

(html-inspector-views:defview 👀page-attached-asdf
    (page dreyeck/local-fedwiki-page:local-fedwiki-page)

  (let* ((observation
           (dreyeck/local-fedwiki-page:local-fedwiki-page-asdf-discovery
            page))
         (assets-items
           (loop
             for item across
               (hyperbook/fedwiki::story-of page)
             when
               (eq
                :assets
                (hyperbook/fedwiki::item-type-of item))
             collect item)))

    (html-inspector-views:html-view
     :title "Page-attached ASDF"
     :priority 5

     (html-inspector-views:html

      (:p
       (html-inspector-views:esc
        "Read-only discovery from this local Federated Wiki page through its assets story items."))

      (:table
       :class "inspector-table"

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "FedWiki page")))
        (:td
         (html-inspector-views:object-ref
          page)))

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "Local site root")))
        (:td
         (html-inspector-views:object-ref
          (dreyeck/local-fedwiki-page:local-fedwiki-page-site-root-of
           page))))

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "Page file")))
        (:td
         (html-inspector-views:object-ref
          (getf observation :page-file))))

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "Assets story items")))
        (:td
         (:ul
          (dolist (item assets-items)
            (html-inspector-views:html
             (:li
              (html-inspector-views:object-ref
               item)))))))

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "Assets references")))
        (:td
         (html-inspector-views:object-ref
          (getf observation :assets-references))))

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "Assets directories")))
        (:td
         (html-inspector-views:object-ref
          (getf observation :assets-directories))))

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "ASDF files")))
        (:td
         (html-inspector-views:object-ref
          (getf observation :asdf-files))))

       (:tr
        (:td
         (:b
          (html-inspector-views:esc
           "Activation")))
        (:td
         (html-inspector-views:esc
          "Not performed by this view; discovery is read-only."))))))))
