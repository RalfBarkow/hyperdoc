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

(defun promotion-provenance-modes-present (plan)
  (sort
   (remove-duplicates
    (loop for row in (localhost-fedwiki-page-promotion-plan-provenance-rows plan)
          for granularity = (getf row :granularity)
          when granularity
            collect (string-downcase (promotion-code-string granularity)))
    :test #'string=)
   #'string<))

(defun promotion-dmx-summary-availability-label (summary)
  (if (getf summary :available)
      "available"
      "unavailable"))

(defun promotion-dmx-summary-label (summary)
  (if (getf summary :available)
      (format nil "~A / ~A"
              (getf summary :topic-action)
              (getf summary :topicmap-action))
      "unavailable"))

(defun promotion-current-source-fingerprint-label (status)
  (or (getf status :current-source-fingerprint)
      "unavailable"))

(defun promotion-current-source-summary-label (status)
  (or (getf status :current-source-summary)
      "unavailable"))

(defun promotion-reflected-snapshot-fingerprint-label (status key)
  (or (getf status key)
      "unavailable"))

(defun promotion-reflected-snapshot-summary-label (status key)
  (or (getf status key)
      "unavailable"))

(defun promotion-source-freshness-reason-label (status key)
  (or (getf status key)
      "unavailable"))

(defun promotion-source-freshness-recommendation-label (status key)
  (or (getf status key)
      "unavailable"))

(defun promotion-source-freshness-recommended-operation (status key)
  (getf status key))

(defun promotion-reflected-snapshot-error-label (status key)
  (or (getf status key)
      "none"))

(defun promotion-reflected-snapshot-status-label (status-key)
  (case status-key
    (:present "present")
    (:malformed "malformed")
    (otherwise "missing")))

(defun promotion-source-freshness-label (freshness-state)
  (case freshness-state
    (:fresh "fresh")
    (:stale "stale")
    (:unknown-malformed-envelope "unknown (malformed envelope)")
    (otherwise "unknown (missing envelope)")))

(defun promotion-source-freshness-affordance-spec (artifact status)
  (let* ((state-key
           (case artifact
             (:page :page-source-freshness-state)
             (:snippet :snippet-source-freshness-state)))
         (label-key
           (case artifact
             (:page :page-source-freshness-recommended-action-label)
             (:snippet :snippet-source-freshness-recommended-action-label)))
         (operation-key
           (case artifact
             (:page :page-source-freshness-recommended-operation)
             (:snippet :snippet-source-freshness-recommended-operation)))
         (state (getf status state-key))
         (description
           (promotion-source-freshness-recommendation-label status label-key))
         (operation
           (promotion-source-freshness-recommended-operation status operation-key))
         (button-label
           (case state
             (:stale
              (case artifact
                (:page "Regenerate page artifact")
                (:snippet "Regenerate snippet artifact")))
             (:unknown-missing-envelope
              (case artifact
                (:page "Restore page snapshot evidence")
                (:snippet "Restore snippet snapshot evidence")))
             (:unknown-malformed-envelope
              (case artifact
                (:page "Repair page snapshot evidence")
                (:snippet "Repair snippet snapshot evidence"))))))
    (if operation
        (list :kind :action
              :label button-label
              :description description
              :operation operation)
        (list :kind :passive
              :label "No action needed"
              :description description
              :operation nil))))

(defun promotion-source-freshness-affordance-html (plan artifact status)
  (let ((spec (promotion-source-freshness-affordance-spec artifact status)))
    (case (getf spec :kind)
      (:action
       (views:html
         (views:eval-button
          (getf spec :label)
          (views:thunk
            (funcall (getf spec :operation) plan))
          (getf spec :description))
         (:div :style "margin-top: 0.35rem;"
               (views:esc (getf spec :description)))))
      (otherwise
       (views:html
         (:span :style "color: #666;" (views:esc (getf spec :label)))
         (:div :style "margin-top: 0.35rem;"
               (views:esc (getf spec :description))))))))

(defun promotion-triage-category-label (category)
  (case category
    (:all-fresh "all fresh")
    (:stale "stale page and snippet")
    (:unknown-missing-envelope "unknown (missing envelope)")
    (:unknown-malformed-envelope "unknown (malformed envelope)")
    (otherwise "mixed page/snippet states")))

(defun promotion-attention-needed-count (rows)
  (count-if (lambda (row)
              (getf row :attention-needed))
            rows))

(defun promotion-triage-count-value (counts key)
  (format nil "~D"
          (or (getf counts key) 0)))

(defun promotion-triage-filter-title (filter)
  (case filter
    (:attention-needed "Attention needed")
    (:all-fresh "All fresh")
    (:stale "Stale")
    (:unknown-missing-envelope "Unknown missing envelope")
    (:unknown-malformed-envelope "Unknown malformed envelope")
    (:mixed-states "Mixed states")
    (otherwise "Triage")))

(defun promotion-triage-filter-description (filter)
  (case filter
    (:attention-needed
     "This scope keeps only plans that currently need attention, still ordered from malformed through missing and stale states.")
    (:all-fresh
     "This scope keeps only plans whose page and snippet artifacts are both currently fresh.")
    (:stale
     "This scope keeps only plans whose page and snippet artifacts are both currently stale.")
    (:unknown-missing-envelope
     "This scope keeps only plans whose reflected snapshot evidence is currently missing.")
    (:unknown-malformed-envelope
     "This scope keeps only plans whose reflected snapshot evidence is currently malformed.")
    (:mixed-states
     "This scope keeps only plans whose page and snippet freshness states currently differ.")
    (otherwise
     "This compact triage table keeps attention-needed promotion plans ahead of all-fresh plans and links each row back to the live plan object.")))

(defun promotion-triage-counts-table-html (counts)
  (views:html
    (:table :class "inspector-table"
            (:tr (:td (views:esc "Plan count"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts :plan-count)))))
            (:tr (:td (views:esc "Attention needed"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts
                                                          :attention-needed)))))
            (:tr (:td (views:esc "All fresh"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts :all-fresh)))))
            (:tr (:td (views:esc "Stale"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts :stale)))))
            (:tr (:td (views:esc "Unknown missing envelope"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value
                             counts
                             :unknown-missing-envelope)))))
            (:tr (:td (views:esc "Unknown malformed envelope"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value
                             counts
                             :unknown-malformed-envelope)))))
            (:tr (:td (views:esc "Mixed states"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value
                             counts
                             :mixed-states))))))))

(defun promotion-triage-rows-table-html (rows)
  (if rows
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Plan"))
                     (:th (views:esc "Source"))
                     (:th (views:esc "Page freshness"))
                     (:th (views:esc "Snippet freshness"))
                     (:th (views:esc "Attention state"))
                     (:th (views:esc "Recommended next action"))
                     (:th (views:esc "Inspect")))
                (loop for row in rows
                      do (views:html
                           (:tr
                            (:td
                             (views:esc (getf row :title))
                             (:div :style "margin-top: 0.35rem;"
                                   (:tt (views:esc (getf row :plan-id)))))
                            (:td
                             (:tt (views:esc (getf row :source-slug)))
                             (:div :style "margin-top: 0.35rem;"
                                   (:tt (views:esc (getf row :source-page-id)))))
                            (:td
                             (:tt (views:esc
                                   (promotion-source-freshness-label
                                    (getf row :page-freshness-state)))))
                            (:td
                             (:tt (views:esc
                                   (promotion-source-freshness-label
                                    (getf row :snippet-freshness-state)))))
                            (:td
                             (:tt (views:esc
                                   (promotion-triage-category-label
                                    (getf row :attention-category)))))
                            (:td (views:esc
                                  (getf row :recommended-next-action-summary)))
                            (:td (views:object-ref
                                  (getf row :inspect-target))))))))
      (views:html
        (:p "No promotion plans match this scope."))))

(defun promotion-triage-scope-html (surface filter)
  (let ((counts (localhost-fedwiki-page-promotion-surface-triage-counts surface))
        (rows (localhost-fedwiki-page-promotion-surface-triage-rows
               surface
               :filter filter)))
    (views:html
      (:p (views:esc (promotion-triage-filter-description filter)))
      (:h4 (views:esc "Counts"))
      (promotion-triage-counts-table-html counts)
      (:h4 (views:esc (promotion-triage-filter-title filter)))
      (promotion-triage-rows-table-html rows))))

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
    (let* ((rows (localhost-fedwiki-page-promotion-surface-triage-rows surface))
           (counts (localhost-fedwiki-page-promotion-surface-triage-counts surface))
           (top-row (first rows)))
      (views:html
        (:h3 (views:esc (localhost-fedwiki-page-promotion-surface-title surface)))
        (:p (views:esc (localhost-fedwiki-page-promotion-surface-summary surface)))
        (:p (views:esc
             "Use Triage to scan all known promotion plans by current freshness state. Attention-needed plans are ordered before all-fresh plans, with malformed and missing reflected snapshot evidence ahead of stale items. The filter-specific subviews keep the same ordering within each scope."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Plan count"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value counts
                                                              :plan-count)))))
                (:tr (:td (views:esc "Attention needed"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :attention-needed)))))
                (:tr (:td (views:esc "All fresh"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value counts
                                                              :all-fresh)))))
                (:tr (:td (views:esc "Stale"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value counts
                                                              :stale)))))
                (:tr (:td (views:esc "Unknown missing envelope"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :unknown-missing-envelope)))))
                (:tr (:td (views:esc "Unknown malformed envelope"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :unknown-malformed-envelope)))))
                (:tr (:td (views:esc "Mixed states"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :mixed-states)))))
                (:tr (:td (views:esc "Top triage state"))
                     (:td (:tt (views:esc
                                (if top-row
                                    (promotion-triage-category-label
                                     (getf top-row :attention-category))
                                    "none"))))))))))

(views:defview 👀triage (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Triage" :priority 2
    (promotion-triage-scope-html surface :all)))

(views:defview 👀attention-needed (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Attention needed" :priority 3
    (promotion-triage-scope-html surface :attention-needed)))

(views:defview 👀all-fresh (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "All fresh" :priority 4
    (promotion-triage-scope-html surface :all-fresh)))

(views:defview 👀stale (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Stale" :priority 5
    (promotion-triage-scope-html surface :stale)))

(views:defview 👀unknown-missing-envelope (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Unknown missing envelope" :priority 6
    (promotion-triage-scope-html surface :unknown-missing-envelope)))

(views:defview 👀unknown-malformed-envelope (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Unknown malformed envelope" :priority 7
    (promotion-triage-scope-html surface :unknown-malformed-envelope)))

(views:defview 👀mixed-states (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Mixed states" :priority 8
    (promotion-triage-scope-html surface :mixed-states)))

(views:defview 👀plans (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Plans" :priority 9
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
          (provenance-modes
            (promotion-provenance-modes-present plan))
          (dmx-summary
            (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan)))
      (views:html
        (:h3 (views:esc (localhost-fedwiki-page-promotion-plan-title plan)))
        (:p (views:esc (localhost-fedwiki-page-promotion-plan-summary plan)))
        (:h4 (views:esc "Status and actions"))
        (:p (views:esc
             "Use this compact surface to check whether the local artifacts are in sync, whether their embedded source snapshot is fresh, stale because the reflected fingerprint differs, or unknown because the reflected envelope is missing or malformed, see the next safe action for each artifact, confirm the provenance modes present in the promoted topics, and trigger explicit local regeneration or DMX dry-run review without switching to the raw Operations tab."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Page synced?"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf status :page-synced))))))
                (:tr (:td (views:esc "Snippet synced?"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf status :snippet-synced))))))
                (:tr (:td (views:esc "Page reflected snapshot"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :page-reflected-snapshot-status))))))
                (:tr (:td (views:esc "Snippet reflected snapshot"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :snippet-reflected-snapshot-status))))))
                (:tr (:td (views:esc "Page source fresh?"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :page-source-freshness-state))))))
                (:tr (:td (views:esc "Snippet source fresh?"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :snippet-source-freshness-state))))))
                (:tr (:td (views:esc "Page recommended next action"))
                     (:td
                      (promotion-source-freshness-affordance-html
                       plan
                       :page
                       status)))
                (:tr (:td (views:esc "Snippet recommended next action"))
                     (:td
                      (promotion-source-freshness-affordance-html
                       plan
                       :snippet
                       status)))
                (:tr (:td (views:esc "Source page id"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-page-id
                                 source)))))
                (:tr (:td (views:esc "Source slug"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-slug
                                 source)))))
                (:tr (:td (views:esc "Current source fingerprint"))
                     (:td (:tt (views:esc
                                (promotion-current-source-fingerprint-label
                                 status)))))
                (:tr (:td (views:esc "Current source summary"))
                     (:td (:tt (views:esc
                                (promotion-current-source-summary-label
                                 status)))))
                (:tr (:td (views:esc "Provenance modes present"))
                     (:td (:tt (views:esc
                                (promotion-list-string provenance-modes)))))
                (:tr (:td (views:esc "DMX dry-run summary available"))
                     (:td (:tt (views:esc
                                (promotion-dmx-summary-availability-label
                                 dmx-summary)))))
                (:tr (:td (views:esc "DMX dry-run summary"))
                     (:td (:tt (views:esc
                                (promotion-dmx-summary-label dmx-summary))))))
        (:ul
         (:li
          (views:eval-button
           "Regenerate page artifact"
           (views:thunk
             (regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
              plan))
           "Rewrite the composed HyperDoc page artifact for this promotion plan and inspect the result."))
         (:li
          (views:eval-button
           "Regenerate snippet artifact"
           (views:thunk
             (regenerate-localhost-fedwiki-page-promotion-plan-snippet-artifact
              plan))
           "Rewrite the topic-factory snippet artifact for this promotion plan and inspect the result."))
         (:li
          (views:eval-button
           "Regenerate both artifacts"
           (views:thunk
             (regenerate-localhost-fedwiki-page-promotion-plan-artifacts
              plan))
           "Rewrite both the composed page and topic-factory snippet artifacts for this promotion plan and inspect the result."))
         (:li
          (views:eval-button
           "Review DMX dry-run"
           (views:thunk
             (review-localhost-fedwiki-page-promotion-plan-dmx-dry-run
              plan))
           "Run the explicit DMX dry-run review for this promotion plan and inspect the canonical evidence."))
         (:li
          (views:eval-button
           "Inspect sync status"
           (views:thunk
             (localhost-fedwiki-page-promotion-plan-sync-status plan))
           "Inspect the current page/snippet sync state for this promotion plan.")))
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
                (:tr (:td (views:esc "Page source fresh"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :page-source-freshness-state))))))
                (:tr (:td (views:esc "Snippet source fresh"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :snippet-source-freshness-state))))))
                (:tr (:td (views:esc "Page reflected snapshot"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :page-reflected-snapshot-status))))))
                (:tr (:td (views:esc "Snippet reflected snapshot"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :snippet-reflected-snapshot-status))))))
                (:tr (:td (views:esc "Current source fingerprint"))
                     (:td (:tt (views:esc
                                (promotion-current-source-fingerprint-label
                                 status)))))
                (:tr (:td (views:esc "DMX dry-run"))
                     (:td (:tt (views:esc
                                (promotion-dmx-summary-label
                                 dmx-summary))))))))))

(views:defview 👀source-freshness (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Source freshness" :priority 7
    (let ((status (localhost-fedwiki-page-promotion-plan-sync-status plan)))
      (views:html
        (:p "These diagnostics compare the current normalized localhost FedWiki source snapshot against the reflected snapshots embedded in the committed page and snippet artifacts. Stale reasons are fingerprint-based comparisons, not semantic diffs of the source text.")
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Current source fingerprint"))
                     (:td (:tt (views:esc
                                (promotion-current-source-fingerprint-label
                                 status)))))
                (:tr (:td (views:esc "Current source summary"))
                     (:td (:tt (views:esc
                                (promotion-current-source-summary-label
                                 status))))))
        (:h4 (views:esc "Page artifact"))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Reflected snapshot status"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :page-reflected-snapshot-status))))))
                (:tr (:td (views:esc "Reflected snapshot fingerprint"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-fingerprint-label
                                 status
                                 :page-reflected-snapshot-fingerprint)))))
                (:tr (:td (views:esc "Reflected snapshot summary"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-summary-label
                                 status
                                 :page-reflected-snapshot-summary)))))
                (:tr (:td (views:esc "Freshness result"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :page-source-freshness-state))))))
                (:tr (:td (views:esc "Diagnostic reason"))
                     (:td (views:esc
                           (promotion-source-freshness-reason-label
                            status
                            :page-source-freshness-reason))))
                (:tr (:td (views:esc "Recommended next action"))
                     (:td
                      (promotion-source-freshness-affordance-html
                       plan
                       :page
                       status)))
                (:tr (:td (views:esc "Malformed detail"))
                     (:td (views:esc
                           (promotion-reflected-snapshot-error-label
                            status
                            :page-reflected-snapshot-error-message)))))
        (:h4 (views:esc "Snippet artifact"))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Reflected snapshot status"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :snippet-reflected-snapshot-status))))))
                (:tr (:td (views:esc "Reflected snapshot fingerprint"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-fingerprint-label
                                 status
                                 :snippet-reflected-snapshot-fingerprint)))))
                (:tr (:td (views:esc "Reflected snapshot summary"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-summary-label
                                 status
                                 :snippet-reflected-snapshot-summary)))))
                (:tr (:td (views:esc "Freshness result"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :snippet-source-freshness-state))))))
                (:tr (:td (views:esc "Diagnostic reason"))
                     (:td (views:esc
                           (promotion-source-freshness-reason-label
                            status
                            :snippet-source-freshness-reason))))
                (:tr (:td (views:esc "Recommended next action"))
                     (:td
                      (promotion-source-freshness-affordance-html
                       plan
                       :snippet
                       status)))
                (:tr (:td (views:esc "Malformed detail"))
                     (:td (views:esc
                           (promotion-reflected-snapshot-error-label
                            status
                            :snippet-reflected-snapshot-error-message)))))))))

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
    (let ((status (localhost-fedwiki-page-promotion-plan-sync-status plan)))
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
                                  plan))))))
                (:tr (:td (views:esc "Page source snapshot fresh"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :page-source-freshness-state))))))
                (:tr (:td (views:esc "Snippet source snapshot fresh"))
                     (:td (:tt (views:esc
                                (promotion-source-freshness-label
                                 (getf status :snippet-source-freshness-state))))))
                (:tr (:td (views:esc "Page reflected snapshot"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :page-reflected-snapshot-status))))))
                (:tr (:td (views:esc "Snippet reflected snapshot"))
                     (:td (:tt (views:esc
                                (promotion-reflected-snapshot-status-label
                                 (getf status :snippet-reflected-snapshot-status)))))))))))

(views:defview 👀snippet-metadata (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Snippet metadata" :priority 8
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
  (views:html-view :title "DMX dry-run" :priority 9
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
