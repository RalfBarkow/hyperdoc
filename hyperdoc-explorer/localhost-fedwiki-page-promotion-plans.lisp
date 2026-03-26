;;;; Explorer views for localhost FedWiki page promotion plans
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun promotion-yes/no-label (value)
  (if value "yes" "no"))

(defun promotion-list-string (values)
  (if values
      (format nil "~{~A~^, ~}" values)
      "none"))

(defun promotion-code-string (value)
  (cond
    ((null value) "n/a")
    ((stringp value) value)
    ((symbolp value) (symbol-name value))
    (t (princ-to-string value))))

(defun promotion-provenance-value (provenance key)
  (or (getf provenance key)
      "n/a"))

(defmethod views:text-representation ((surface localhost-fedwiki-page-promotion-surface))
  (localhost-fedwiki-page-promotion-surface-title surface))

(defmethod views:text-representation ((plan localhost-fedwiki-page-promotion-plan))
  (localhost-fedwiki-page-promotion-plan-title plan))

(defmethod views:text-representation ((source localhost-fedwiki-source-data))
  (localhost-fedwiki-source-data-fedwiki-page-id source))

(defmethod views:text-representation ((item localhost-fedwiki-item-data))
  (format nil "story item ~D (~A)"
          (localhost-fedwiki-item-data-item-index item)
          (localhost-fedwiki-item-data-item-type item)))

(defmethod views:text-representation ((fragment localhost-fedwiki-fragment-data))
  (format nil "fragment ~D (~A)"
          (localhost-fedwiki-fragment-data-fragment-index fragment)
          (or (localhost-fedwiki-fragment-data-section-key fragment)
              (localhost-fedwiki-fragment-data-fragment-anchor fragment))))

(defmethod views:text-representation ((topic localhost-fedwiki-promoted-topic-data))
  (localhost-fedwiki-promoted-topic-data-title topic))

(views:defview 👀promotion-plan (source localhost-fedwiki-source-data)
  (topic-localhost-fedwiki-promotion-plan-view
   (find-localhost-fedwiki-page-promotion-plan-for-source source)
   "This normalized localhost FedWiki source page can open its promotion plan directly so the inspect boundary stays separate from local artifact writes and DMX writes."))

(views:defview 👀overview (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc (localhost-fedwiki-page-promotion-surface-title surface)))
      (:p (views:esc (localhost-fedwiki-page-promotion-surface-summary surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Plan count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length
                                       (localhost-fedwiki-page-promotion-surface-plans
                                        surface)))))))))))

(views:defview 👀plans (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Plans" :priority 2
    (views:html
      (:p "Each plan stays inspectable as a separate localhost FedWiki page-promotion boundary.")
      (:ul
       (loop for plan in (localhost-fedwiki-page-promotion-surface-plans surface)
             do (views:html
                  (:li (views:object-ref plan))))))))

(views:defview 👀overview (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Overview" :priority 1
    (let ((source (localhost-fedwiki-page-promotion-plan-source plan))
          (status
            (localhost-fedwiki-page-promotion-plan-sync-status plan))
          (dmx-summary
            (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan)))
      (views:html
        (:h3 (views:esc (localhost-fedwiki-page-promotion-plan-title plan)))
        (:p (views:esc (localhost-fedwiki-page-promotion-plan-summary plan)))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source page id"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-page-id
                                 source)))))
                (:tr (:td (views:esc "Source slug"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-slug
                                 source)))))
                (:tr (:td (views:esc "Source path"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-relative-path
                                 source)))))
                (:tr (:td (views:esc "Story items"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (localhost-fedwiki-page-promotion-plan-story-item-count
                                         plan))))))
                (:tr (:td (views:esc "Fragments"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (localhost-fedwiki-page-promotion-plan-fragment-count
                                         plan))))))
                (:tr (:td (views:esc "Promoted topics"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (localhost-fedwiki-page-promotion-plan-topic-count
                                         plan))))))
                (:tr (:td (views:esc "Composed page target"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-page-promotion-plan-composed-page-target
                                 plan)))))
                (:tr (:td (views:esc "Snippet id"))
                     (:td (:tt (views:esc
                                (snippet-id-of
                                 (localhost-fedwiki-page-promotion-plan-topic-definition
                                  plan))))))
                (:tr (:td (views:esc "Page synced"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf status :page-synced))))))
                (:tr (:td (views:esc "Snippet synced"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf status :snippet-synced))))))
                (:tr (:td (views:esc "DMX dry-run"))
                     (:td (:tt (views:esc
                                (if (getf dmx-summary :available)
                                    (format nil "~A / ~A"
                                            (getf dmx-summary :topic-action)
                                            (getf dmx-summary :topicmap-action))
                                    "unavailable"))))))))))

(views:defview 👀source-page (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Source page" :priority 2
    (let* ((source (localhost-fedwiki-page-promotion-plan-source plan))
           (provenance (localhost-fedwiki-source-data-provenance source)))
      (views:html
        (:p "Normalized localhost FedWiki page source. This is the read boundary for promotion, before any local HyperDoc write or DMX write step.")
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Normalized source object"))
                     (:td (views:object-ref source)))
                (:tr (:td (views:esc "Page title"))
                     (:td (views:esc
                           (localhost-fedwiki-source-data-fedwiki-title source))))
                (:tr (:td (views:esc "Page id"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-page-id
                                 source)))))
                (:tr (:td (views:esc "Slug"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-slug
                                 source)))))
                (:tr (:td (views:esc "Repo-relative path"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-relative-path
                                 source)))))
                (:tr (:td (views:esc "HTML URL"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-url
                                 source)))))
                (:tr (:td (views:esc "Claim"))
                     (:td (views:esc
                           (localhost-fedwiki-source-data-claim source))))
                (:tr (:td (views:esc "Source provenance granularity"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-granularity)))))
                (:tr (:td (views:esc "Source provenance classification"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-classification))))))))))

(views:defview 👀summary (source localhost-fedwiki-source-data)
  (views:html-view :title "Summary" :priority 1
    (let ((provenance (localhost-fedwiki-source-data-provenance source)))
      (views:html
        (:h3 (views:esc (localhost-fedwiki-source-data-title source)))
        (:p (views:esc (localhost-fedwiki-source-data-summary source)))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Page id"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-page-id
                                 source)))))
                (:tr (:td (views:esc "Page path"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-relative-path
                                 source)))))
                (:tr (:td (views:esc "Story item count"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (length
                                         (localhost-fedwiki-source-data-story-items
                                          source)))))))
                (:tr (:td (views:esc "Provenance granularity"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-granularity))))))))))

(views:defview 👀story-items (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Story items" :priority 3
    (views:html
      (:p "Normalized story items preserve whole-item provenance even when later topic promotion splits one paragraph into fragment-derived topics.")
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Item"))
                    (:th (views:esc "Type"))
                    (:th (views:esc "Item id"))
                    (:th (views:esc "Fragments"))
                    (:th (views:esc "Granularity"))
                    (:th (views:esc "Classification"))
                    (:th (views:esc "Excerpt"))))
              (:tbody
               (loop for item in (localhost-fedwiki-page-promotion-plan-story-items plan)
                     for provenance = (localhost-fedwiki-item-data-provenance item)
                     do (views:html
                          (:tr
                           (:td (views:object-ref item))
                           (:td (:tt (views:esc
                                      (localhost-fedwiki-item-data-item-type item))))
                           (:td (:tt (views:esc
                                      (or (localhost-fedwiki-item-data-item-id item)
                                          "n/a"))))
                           (:td (:tt (views:esc
                                      (format nil "~D"
                                              (length
                                               (localhost-fedwiki-item-data-fragments
                                                item))))))
                           (:td (:tt (views:esc
                                      (promotion-provenance-value
                                       provenance
                                       :provenance-granularity))))
                           (:td (:tt (views:esc
                                      (promotion-provenance-value
                                       provenance
                                       :provenance-classification))))
                           (:td (views:esc
                                 (shorten-source-excerpt
                                  (localhost-fedwiki-item-data-text item)
                                  :max-length 96)))))))))))

(views:defview 👀summary (item localhost-fedwiki-item-data)
  (views:html-view :title "Summary" :priority 1
    (let ((provenance (localhost-fedwiki-item-data-provenance item)))
      (views:html
        (:h3 (views:esc (format nil "Story item ~D"
                                (localhost-fedwiki-item-data-item-index item))))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Type"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-item-data-item-type item)))))
                (:tr (:td (views:esc "Item id"))
                     (:td (:tt (views:esc
                                (or (localhost-fedwiki-item-data-item-id item)
                                    "n/a")))))
                (:tr (:td (views:esc "Fragments"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (length
                                         (localhost-fedwiki-item-data-fragments
                                          item)))))))
                (:tr (:td (views:esc "Granularity"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-granularity)))))
                (:tr (:td (views:esc "Classification"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-classification)))))
                (:tr (:td (views:esc "Source id"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-item-data-source-id item))))))))))

(views:defview 👀fragments (item localhost-fedwiki-item-data)
  (views:html-view :title "Fragments" :priority 2
    (views:html
      (:ul
       (loop for fragment in (localhost-fedwiki-item-data-fragments item)
             do (views:html
                  (:li (views:object-ref fragment))))))))

(views:defview 👀fragments (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Fragments" :priority 4
    (let ((fragments (localhost-fedwiki-page-promotion-plan-fragments plan)))
      (if fragments
          (views:html
            (:p "Normalized fragments record the finer-grained provenance used when promotion derives topics from sections or paragraph segments inside one story item.")
            (:table :class "inspector-table"
                    (:thead
                     (:tr (:th (views:esc "Fragment"))
                          (:th (views:esc "Item"))
                          (:th (views:esc "Anchor"))
                          (:th (views:esc "Section key"))
                          (:th (views:esc "Granularity"))
                          (:th (views:esc "Classification"))
                          (:th (views:esc "Excerpt"))))
                    (:tbody
                     (loop for fragment in fragments
                           for provenance = (localhost-fedwiki-fragment-data-provenance
                                             fragment)
                           do (views:html
                                (:tr
                                 (:td (views:object-ref fragment))
                                 (:td (:tt (views:esc
                                            (format nil "~D"
                                                    (localhost-fedwiki-fragment-data-item-index
                                                     fragment)))))
                                 (:td (:tt (views:esc
                                            (localhost-fedwiki-fragment-data-fragment-anchor
                                             fragment))))
                                 (:td (:tt (views:esc
                                            (or (localhost-fedwiki-fragment-data-section-key
                                                 fragment)
                                                "n/a"))))
                                 (:td (:tt (views:esc
                                            (promotion-provenance-value
                                             provenance
                                             :provenance-granularity))))
                                 (:td (:tt (views:esc
                                            (promotion-provenance-value
                                             provenance
                                             :provenance-classification))))
                                 (:td (views:esc
                                       (localhost-fedwiki-fragment-data-excerpt
                                        fragment)))))))))
          (views:html
            (:p "This plan does not expose fragment records."))))))

(views:defview 👀summary (fragment localhost-fedwiki-fragment-data)
  (views:html-view :title "Summary" :priority 1
    (let ((provenance (localhost-fedwiki-fragment-data-provenance fragment)))
      (views:html
        (:h3 (views:esc (format nil "Fragment ~D"
                                (localhost-fedwiki-fragment-data-fragment-index
                                 fragment))))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Item index"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (localhost-fedwiki-fragment-data-item-index
                                         fragment))))))
                (:tr (:td (views:esc "Anchor"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-fragment-data-fragment-anchor
                                 fragment)))))
                (:tr (:td (views:esc "Section key"))
                     (:td (:tt (views:esc
                                (or (localhost-fedwiki-fragment-data-section-key
                                     fragment)
                                    "n/a")))))
                (:tr (:td (views:esc "Granularity"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-granularity)))))
                (:tr (:td (views:esc "Classification"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-classification)))))
                (:tr (:td (views:esc "Excerpt"))
                     (:td (views:esc
                           (localhost-fedwiki-fragment-data-excerpt
                            fragment)))))))))

(views:defview 👀promoted-topics (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Promoted topics" :priority 5
    (views:html
      (:p "Promoted topic chunks carry the derivation granularity actually used for the promotion: whole story item, story-item fragment, multi-item grouping, or page-level fallback.")
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Topic"))
                    (:th (views:esc "Kind"))
                    (:th (views:esc "Granularity"))
                    (:th (views:esc "Classification"))
                    (:th (views:esc "Story item indexes"))
                    (:th (views:esc "Fragment ordinals"))))
              (:tbody
               (loop for row in (localhost-fedwiki-page-promotion-plan-provenance-rows plan)
                     for chunk in (localhost-fedwiki-page-promotion-plan-promoted-topic-chunks plan)
                     do (views:html
                          (:tr
                           (:td (views:object-ref chunk))
                           (:td (:tt (views:esc
                                      (promotion-code-string
                                       (getf row :kind)))))
                           (:td (:tt (views:esc
                                      (promotion-code-string
                                       (getf row :granularity)))))
                           (:td (:tt (views:esc
                                      (promotion-code-string
                                       (getf row :classification)))))
                           (:td (:tt (views:esc
                                      (promotion-list-string
                                       (or (getf row :story-item-indexes)
                                           (and (getf row :story-item-index)
                                                (list (getf row :story-item-index))))))))
                           (:td (:tt (views:esc
                                      (promotion-list-string
                                       (getf row :fragment-ordinals)))))))))))))

(views:defview 👀summary (topic localhost-fedwiki-promoted-topic-data)
  (views:html-view :title "Summary" :priority 1
    (let ((provenance (localhost-fedwiki-promoted-topic-data-provenance topic)))
      (views:html
        (:h3 (views:esc (localhost-fedwiki-promoted-topic-data-title topic)))
        (:p (views:esc (localhost-fedwiki-promoted-topic-data-summary topic)))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Kind"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (localhost-fedwiki-promoted-topic-data-topic-kind
                                  topic))))))
                (:tr (:td (views:esc "Source path"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-promoted-topic-data-source-path
                                 topic)))))
                (:tr (:td (views:esc "Granularity"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-granularity)))))
                (:tr (:td (views:esc "Classification"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-classification))))))))))

(views:defview 👀page-output (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Page output" :priority 6
    (views:html
      (:p "This boundary is still local and durable. The plan points at the authored HyperDoc page target and the explicit local writer entry point, without turning the page into a live DMX proxy.")
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Composed page target"))
                   (:td (:tt (views:esc
                              (localhost-fedwiki-page-promotion-plan-composed-page-target
                               plan)))))
              (:tr (:td (views:esc "Renderer"))
                   (:td (:tt (views:esc
                              (promotion-code-string
                               (localhost-fedwiki-page-promotion-plan-page-renderer
                                plan))))))
              (:tr (:td (views:esc "Local writer"))
                   (:td (:tt (views:esc
                              (promotion-code-string
                               (localhost-fedwiki-page-promotion-plan-local-artifact-writer
                                plan))))))
              (:tr (:td (views:esc "Committed page matches renderer"))
                   (:td (:tt (views:esc
                              (promotion-yes/no-label
                               (localhost-fedwiki-page-promotion-plan-page-output-synced-p
                                plan))))))
              (:tr (:td (views:esc "Committed snippet matches metadata"))
                   (:td (:tt (views:esc
                              (promotion-yes/no-label
                               (localhost-fedwiki-page-promotion-plan-snippet-output-synced-p
                                plan))))))))))

(views:defview 👀snippet-metadata (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Snippet metadata" :priority 7
    (let* ((metadata (localhost-fedwiki-page-promotion-plan-topic-factory-metadata
                      plan))
           (provenance (getf metadata :provenance)))
      (views:html
        (:p "Topic-factory snippet metadata stays separate from the local page output. It keeps canonical source identifiers and can be handed to the separate DMX snippet writer.")
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Topic definition"))
                     (:td (views:object-ref
                           (localhost-fedwiki-page-promotion-plan-topic-definition
                            plan))))
                (:tr (:td (views:esc "DMX snippet chunk"))
                     (:td (views:object-ref
                           (localhost-fedwiki-page-promotion-plan-dmx-snippet
                            plan))))
                (:tr (:td (views:esc "Snippet id"))
                     (:td (:tt (views:esc
                                (or (getf metadata :id) "n/a")))))
                (:tr (:td (views:esc "Source file"))
                     (:td (:tt (views:esc
                                (or (getf metadata :source-file) "n/a")))))
                (:tr (:td (views:esc "Source origin id"))
                     (:td (:tt (views:esc
                                (or (getf metadata :source-origin-id) "n/a")))))
                (:tr (:td (views:esc "Source origin path"))
                     (:td (:tt (views:esc
                                (or (getf metadata :source-origin-path) "n/a")))))
                (:tr (:td (views:esc "Related page"))
                     (:td (:tt (views:esc
                                (or (getf metadata :related-hyperdoc-page-title)
                                    "n/a")))))
                (:tr (:td (views:esc "Related topic id"))
                     (:td (:tt (views:esc
                                (or (getf metadata :related-topic-id) "n/a")))))
                (:tr (:td (views:esc "Related topic ids"))
                     (:td (:tt (views:esc
                                (promotion-list-string
                                 (getf metadata :related-topic-ids))))))
                (:tr (:td (views:esc "Granularity"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-granularity)))))
                (:tr (:td (views:esc "Classification"))
                     (:td (:tt (views:esc
                                (promotion-provenance-value
                                 provenance
                                 :provenance-classification))))))))))

(views:defview 👀dmx-dry-run (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "DMX dry-run" :priority 8
    (let* ((summary (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan))
           (provenance (getf summary :provenance))
           (evidence (localhost-fedwiki-page-promotion-plan-dmx-dry-run-evidence plan)))
      (views:html
        (:p "This view stays on the explicit dry-run boundary. It uses the separate topic-factory snippet DMX writer to show what would be created or updated in the requested workspace topicmap.")
        (if (getf summary :available)
            (views:html
              (:table :class "inspector-table"
                      (:tr (:td (views:esc "Snippet URI"))
                           (:td (:tt (views:esc (getf summary :uri)))))
                      (:tr (:td (views:esc "Workspace topicmap id"))
                           (:td (:tt (views:esc
                                      (format nil "~A"
                                              (getf summary :workspace-topicmap-id))))))
                      (:tr (:td (views:esc "Topic action"))
                           (:td (:tt (views:esc
                                      (promotion-code-string
                                       (getf summary :topic-action))))))
                      (:tr (:td (views:esc "Topicmap action"))
                           (:td (:tt (views:esc
                                      (promotion-code-string
                                       (getf summary :topicmap-action))))))
                      (:tr (:td (views:esc "Source file"))
                           (:td (:tt (views:esc
                                      (or (getf summary :source-path) "n/a")))))
                      (:tr (:td (views:esc "Related page"))
                           (:td (:tt (views:esc
                                      (or (getf summary :related-hyperdoc-page-title)
                                          "n/a")))))
                      (:tr (:td (views:esc "Related topic id"))
                           (:td (:tt (views:esc
                                      (or (getf summary :related-topic-id)
                                          "n/a")))))
                      (:tr (:td (views:esc "Source page id"))
                           (:td (:tt (views:esc
                                      (promotion-provenance-value
                                       provenance
                                       :source-page-id)))))
                      (:tr (:td (views:esc "Source page path"))
                           (:td (:tt (views:esc
                                      (promotion-provenance-value
                                       provenance
                                       :source-page-path)))))
                      (:tr (:td (views:esc "Granularity"))
                           (:td (:tt (views:esc
                                      (promotion-provenance-value
                                       provenance
                                       :provenance-granularity)))))
                      (:tr (:td (views:esc "Classification"))
                           (:td (:tt (views:esc
                                      (promotion-provenance-value
                                       provenance
                                       :provenance-classification)))))
                      (:tr (:td (views:esc "Story item indexes"))
                           (:td (:tt (views:esc
                                      (promotion-list-string
                                       (or (getf provenance :source-story-item-indexes)
                                           (and (getf provenance :source-story-item-index)
                                                (list (getf provenance :source-story-item-index))))))))
                      (:tr (:td (views:esc "Fragment ordinals"))
                           (:td (:tt (views:esc
                                      (promotion-list-string
                                       (getf provenance :source-fragment-ordinals)))))))
              (:h4 (views:esc "Dry-run evidence"))
              (:pre :style "white-space: pre-wrap;"
                    (views:esc evidence)))
            (views:html
              (:p (views:esc (getf summary :message))))))))))
