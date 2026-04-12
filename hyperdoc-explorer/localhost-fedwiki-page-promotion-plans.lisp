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

(defun promotion-dmx-live-write-label (value)
  (if value "configured" "not configured"))

(defun promotion-source-availability-label (state)
  (case state
    (:source-unavailable "source unavailable")
    (otherwise "available")))

(defun promotion-dmx-repair-runbook-page ()
  (let ((hyperdoc (and (boundp '*hyperdoc*)
                       (symbol-value '*hyperdoc*))))
    (when hyperdoc
      (find-page hyperdoc
                 "DMX topicmap 919822 repair runbook"))))

(defun promotion-dmx-repair-runbook-object ()
  (dmx-topicmap-919822-repair-runbook))

(defun promotion-generated-page-link-html (page &key (display "Review generated page"))
  (if page
      (views:object-ref page
                        :display display
                        :select "Content")
      (views:html
        (:span :style "color: #666;"
               (views:esc "unavailable")))))

(defun promotion-object-link-html
    (object &key display select (fallback "unavailable"))
  (if object
      (views:object-ref object
                        :display display
                        :select select)
      (views:html
        (:span :style "color: #666;"
               (views:esc fallback)))))

(defun promotion-dmx-backend-block-html ()
  (let ((page (promotion-dmx-repair-runbook-page))
        (runbook (promotion-dmx-repair-runbook-object)))
    (views:html
      (:div :style "margin: 0.85rem 0; padding: 0.8rem; border: 1px solid #7a9; background: #f4fbf6;"
            (:strong (views:esc "DMX repair and guarded-write boundary."))
            (:span (views:esc
                    " Topicmap 919822 was repaired live after the short-key-only topicmap-context defect on assocs 921404 and 921471. HyperDoc now keeps DMX writes behind explicit long-form payload validation and dry-run-first review. The original writer remains unproven, so DMX is treated as a valuable but untrusted persistence boundary."))
            (:div :style "margin-top: 0.45rem;"
                  (promotion-object-link-html
                   page
                   :display "Repair runbook page"
                   :select "Content")
                  (views:esc " · ")
                  (promotion-object-link-html
                   runbook
                   :display "Inspect repair runbook object"
                   :select "Overview"))))))

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
    (:source-unavailable "source unavailable")
    (:fresh "fresh")
    (:stale "stale")
    (:unknown-malformed-envelope "unknown (malformed envelope)")
    (otherwise "unknown (missing envelope)")))

(defun promotion-publication-status-label (status)
  (case status
    (:current "current")
    (:stale "stale")
    (:divergent "divergent")
    (:missing "missing")
    (:unreachable "unreachable")
    (:source-unavailable "source unavailable")
    (:invalid-local-json "invalid local JSON")
    (:blocked-local-validation "blocked by local journal validation")
    (otherwise (promotion-code-string status))))

(defun promotion-publication-target-exists-label (status)
  (case status
    (:yes "yes")
    (:no "no")
    (otherwise "unknown")))

(defun promotion-planned-write-label (planned-write)
  (let ((action (getf planned-write :action)))
    (case action
      (:publish-fedwiki-page "publish local title/story/journal")
      (:none "no write needed")
      (:blocked "blocked")
      (otherwise (promotion-code-string action)))))

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
             (:source-unavailable
              "Inspect source issue")
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
              :label (or button-label "No action needed")
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

(defun repair-runbook-mode-label (mode)
  (case mode
    (:read-only "read-only")
    (otherwise (promotion-code-string mode))))

(defun repair-runbook-candidate-status-label (status)
  (case status
    (:admin-required "admin required")
    (otherwise (promotion-code-string status))))

(defmethod views:text-representation ((runbook dmx-topicmap-repair-runbook))
  (format nil "Runbook: ~A" (dmx-topicmap-repair-runbook-title runbook)))

(views:defview 👀overview (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Overview" :priority 1
    (let* ((healthy (dmx-topicmap-repair-runbook-healthy-specimen runbook))
           (broken (dmx-topicmap-repair-runbook-broken-assocs runbook)))
      (views:html
        (:p (views:esc (dmx-topicmap-repair-runbook-summary runbook)))
        (:p (views:esc
             "This runbook is intentionally diagnostic and dry-run-first. It isolates the broken topicmap-context membership/view-props layer in topicmap 919822, preserves the bounded live repair, and now explains why HyperDoc keeps its own DMX writes behind a separate guarded long-form payload boundary while the original writer remains unknown."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Topicmap id"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (dmx-topicmap-repair-runbook-topicmap-id
                                         runbook))))))
                (:tr (:td (views:esc "Workspace/context"))
                     (:td (:tt (views:esc
                                (dmx-topicmap-repair-runbook-workspace-name
                                 runbook)))))
                (:tr (:td (views:esc "Topicmap route"))
                     (:td (:tt (views:esc
                                (dmx-topicmap-repair-runbook-topicmap-route
                                 runbook)))))
                (:tr (:td (views:esc "Healthy comparison topic"))
                     (:td (:tt (views:esc
                                (format nil "~D" (getf healthy :topic-id))))))
                (:tr (:td (views:esc "Healthy comparison assoc"))
                     (:td (:tt (views:esc
                                (format nil "~D" (getf healthy :assoc-id))))))
                (:tr (:td (views:esc "Broken assoc ids"))
                     (:td (:tt (views:esc
                                (format nil "~{~D~^, ~}"
                                        (loop for row in broken
                                              collect (getf row :assoc-id)))))))
                (:tr (:td (views:esc "Default operation mode"))
                     (:td (:tt (views:esc
                                (repair-runbook-mode-label
                                 (dmx-topicmap-repair-runbook-default-operation-mode
                                  runbook))))))
                (:tr (:td (views:esc "DMX writes enabled by default"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (dmx-topicmap-repair-runbook-write-enabled-p
                                  runbook))))))
                (:tr (:td (views:esc "Source file"))
                     (:td (:tt (views:esc
                                (dmx-topicmap-repair-runbook-source-file
                                 runbook))))))
        (:ul
         (:li (views:esc
               "The note topics themselves remain readable; the defect is at the topicmap-context membership/view-props layer."))
         (:li (views:esc
               "Topicmap 919822 should not receive further writes until backend/admin repair is complete."))
         (:li (views:esc
               "After repair, verify topicmaps/object/921352, topicmaps/object/921464, and topicmaps/919822 before resuming DMX seeding work.")))))))

(views:defview 👀healthy-specimen (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Healthy specimen" :priority 2
    (let ((healthy (dmx-topicmap-repair-runbook-healthy-specimen runbook)))
      (views:html
        (:p (views:esc
             "Topic 921494 is the accepted healthy comparison specimen inside topicmap 919822. It proves the assoc class and the membership shape without proving the hidden write payload."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Topic id"))
                     (:td (:tt (views:esc
                                (format nil "~D" (getf healthy :topic-id))))))
                (:tr (:td (views:esc "Assoc id"))
                     (:td (:tt (views:esc
                                (format nil "~D" (getf healthy :assoc-id))))))
                (:tr (:td (views:esc "Assoc type"))
                     (:td (:tt (views:esc
                                (getf healthy :assoc-type)))))
                (:tr (:td (views:esc "Topic readable"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf healthy :topic-readable-p))))))
                (:tr (:td (views:esc "Topicmap-object lookup readable"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf healthy :topicmap-object-readable-p))))))
                (:tr (:td (views:esc "Summary"))
                     (:td (views:esc (getf healthy :summary)))))))))

(views:defview 👀broken-assocs (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Broken assocs" :priority 3
    (views:html
      (:p (views:esc
           "These are the broken topicmap-context membership/view assocs currently blocking healthy lookup inside topicmap 919822."))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Assoc id"))
                    (:th (views:esc "Topic id"))
                    (:th (views:esc "Assoc type"))
                    (:th (views:esc "Topic readable"))
                    (:th (views:esc "Observed failure"))))
              (:tbody
               (loop for row in (dmx-topicmap-repair-runbook-broken-assocs runbook)
                     do (views:html
                          (:tr
                           (:td (:tt (views:esc
                                      (format nil "~D" (getf row :assoc-id)))))
                           (:td (:tt (views:esc
                                      (format nil "~D" (getf row :topic-id)))))
                           (:td (:tt (views:esc
                                      (getf row :assoc-type))))
                           (:td (:tt (views:esc
                                      (promotion-yes/no-label
                                       (getf row :topic-readable-p)))))
                           (:td (views:esc
                                 (or (getf row :topicmap-object-failure)
                                     (getf row :topicmap-failure)
                                     "n/a")))))))))))

(views:defview 👀evidence (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Evidence" :priority 4
    (views:html
      (:p (views:esc
           "This evidence table stays on the accepted read-only boundary. It records exactly which public reads succeed and which ones fail."))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Endpoint"))
                    (:th (views:esc "Observed result"))))
              (:tbody
               (loop for row in (dmx-topicmap-repair-runbook-evidence-rows runbook)
                     do (views:html
                          (:tr
                           (:td (:tt (views:esc (getf row :endpoint))))
                           (:td (views:esc (getf row :result)))))))))))

(views:defview 👀candidate-repairs (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Candidate repairs" :priority 5
    (views:html
      (:p (views:esc
           "These are the smallest plausible backend/admin repair targets. They are kept descriptive only; this runbook does not execute them."))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Candidate"))
                    (:th (views:esc "Status"))
                    (:th (views:esc "Summary"))))
              (:tbody
               (loop for row in (dmx-topicmap-repair-runbook-candidate-repairs runbook)
                     do (views:html
                          (:tr
                           (:td (:tt (views:esc (getf row :label))))
                           (:td (:tt (views:esc
                                      (repair-runbook-candidate-status-label
                                       (getf row :status)))))
                           (:td (views:esc (getf row :summary))))))))
      (:ul
       (:li (views:esc
             "Smallest likely repair target: add the missing topicmap-scoped assoc view props to 921404 and 921471."))
       (:li (views:esc
             "Fallback repair target: remove and correctly recreate those memberships through the real backend/admin route."))))))

(views:defview 👀dry-run (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Dry-run" :priority 6
    (views:html
      (:p (views:esc
           "This checklist is read-only by default. It exists to help an admin learn the current failure boundary before any repair write is attempted."))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Step"))
                    (:th (views:esc "Read-only command"))
                    (:th (views:esc "Expected observation"))))
              (:tbody
               (loop for row in (dmx-topicmap-repair-runbook-dry-run-checklist runbook)
                     do (views:html
                          (:tr
                           (:td (views:esc (getf row :step)))
                           (:td (:pre :style "white-space: pre-wrap; margin: 0;"
                                      (views:esc (getf row :command))))
                           (:td (views:esc (getf row :expected))))))))
      (:h4 (views:esc "Post-repair verification"))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Step"))
                    (:th (views:esc "Verification command"))
                    (:th (views:esc "Success condition"))))
              (:tbody
               (loop for row in (dmx-topicmap-repair-runbook-post-repair-checklist
                                 runbook)
                     do (views:html
                          (:tr
                           (:td (views:esc (getf row :step)))
                           (:td (:pre :style "white-space: pre-wrap; margin: 0;"
                                      (views:esc (getf row :command))))
                           (:td (views:esc (getf row :expected)))))))))))

(views:defview 👀unknowns (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Unknowns" :priority 7
    (views:html
      (:p (views:esc
           "These are the remaining backend uncertainties. They are why HyperDoc-side writer changes and speculative repair writes are out of scope for this slice."))
      (:ul
       (loop for item in (dmx-topicmap-repair-runbook-unknowns runbook)
             do (views:html
                  (:li (views:esc item))))))))

(views:defview 👀operations (runbook dmx-topicmap-repair-runbook)
  (views:html-view :title "Operations" :priority 8
    (views:html
      (:p (views:esc
           "Operations stay passive in this runbook. No DMX repair call is wired here by default."))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Default mode"))
                   (:td (:tt (views:esc
                              (repair-runbook-mode-label
                               (dmx-topicmap-repair-runbook-default-operation-mode
                                runbook))))))
              (:tr (:td (views:esc "Writes enabled"))
                   (:td (:tt (views:esc
                              (promotion-yes/no-label
                               (dmx-topicmap-repair-runbook-write-enabled-p
                                runbook))))))
              (:tr (:td (views:esc "Backend/admin inspect first"))
                   (:td (:tt (views:esc "/topicmaps/919822/assoc/921503"))))
              (:tr (:td (views:esc "Blocked repair targets"))
                   (:td (:tt (views:esc "921404, 921471"))))
              (:tr (:td (views:esc "Why no default writer trust"))
                   (:td (views:esc
                         "The public API does not reveal the original write payload for /topicmaps/919822/assoc/<assoc-id>, so HyperDoc now validates its own writes explicitly instead of assuming generic DMX view-prop writes are safe.")))))))

(views:defview 👀workflow-status (page html-page)
  (when-let ((plan (find-localhost-fedwiki-page-promotion-plan-for-generated-page
                    page)))
    (let* ((source (localhost-fedwiki-page-promotion-plan-source plan))
           (status (localhost-fedwiki-page-promotion-plan-sync-status plan)))
      (views:html-view :title "Workflow status" :priority 2
        (views:html
          (:p (views:esc
               "Current promotion workflow status for this generated page. These values are derived from the linked promotion plan so freshness and next-action guidance stay consistent with the source-side workflow surfaces."))
          (:table :class "inspector-table"
                  (:tr (:td (views:esc "Promotion plan"))
                       (:td
                        (promotion-object-link-html
                         plan
                         :display
                         (localhost-fedwiki-page-promotion-plan-title plan)
                         :select "Overview")))
                  (:tr (:td (views:esc "Promotion plan id"))
                       (:td (:tt (views:esc
                                  (localhost-fedwiki-page-promotion-plan-id
                                   plan)))))
                  (:tr (:td (views:esc "Linked localhost source"))
                       (:td
                        (promotion-object-link-html
                         source
                         :display "Open source object"
                         :select "Summary")))
                  (:tr (:td (views:esc "Linked localhost source id"))
                       (:td (:tt (views:esc
                                  (localhost-fedwiki-source-data-fedwiki-page-id
                                   source)))))
                  (:tr (:td (views:esc "Linked localhost source slug"))
                       (:td (:tt (views:esc
                                  (localhost-fedwiki-source-data-fedwiki-slug
                                   source)))))
                  (:tr (:td (views:esc "Page source freshness"))
                       (:td (:tt (views:esc
                                  (promotion-source-freshness-label
                                   (getf status
                                         :page-source-freshness-state))))))
                  (:tr (:td (views:esc "Snippet source freshness"))
                       (:td (:tt (views:esc
                                  (promotion-source-freshness-label
                                   (getf status
                                         :snippet-source-freshness-state))))))
                  (:tr (:td (views:esc "Recommended next action summary"))
                       (:td (views:esc
                             (localhost-fedwiki-page-promotion-plan-recommended-next-action-summary
                              status)))))
          (:ul
           (:li
            (promotion-object-link-html
             plan
             :display "Promotion plan overview"
             :select "Overview"))
           (:li
            (promotion-object-link-html
             plan
             :display "Review source freshness"
             :select "Source freshness"))
           (:li
            (promotion-object-link-html
             plan
             :display "Review source page"
             :select "Source page"))))))))

(defun promotion-triage-category-label (category)
  (case category
    (:all-fresh "all fresh")
    (:source-unavailable "source unavailable")
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
    (:source-unavailable "Source unavailable")
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
    (:source-unavailable
     "This scope keeps only plans whose configured localhost FedWiki source page file is currently unavailable.")
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

(defun promotion-triage-count-drilldown-spec (surface key)
  (let* ((filter
         (case key
             (:attention-needed :attention-needed)
             (:all-fresh :all-fresh)
             (:source-unavailable :source-unavailable)
             (:stale :stale)
             (:unknown-missing-envelope :unknown-missing-envelope)
             (:unknown-malformed-envelope :unknown-malformed-envelope)
             (:mixed-states :mixed-states)))
         (title (and filter
                     (promotion-triage-filter-title filter))))
    (when title
      (list :target surface
            :select title
            :label title))))

(defun promotion-triage-count-label-html (surface label key)
  (let ((spec (promotion-triage-count-drilldown-spec surface key)))
    (if spec
        (views:object-ref (getf spec :target)
                          :display label
                          :select (getf spec :select))
        (views:html
          (views:esc label)))))

(defun promotion-triage-counts-table-html (surface counts)
  (views:html
    (:table :class "inspector-table"
            (:tr (:td (views:esc "Plan count"))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts :plan-count)))))
            (:tr (:td (promotion-triage-count-label-html
                       surface
                       "Attention needed"
                       :attention-needed))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts
                                                          :attention-needed)))))
            (:tr (:td (promotion-triage-count-label-html
                       surface
                       "All fresh"
                       :all-fresh))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts :all-fresh)))))
            (:tr (:td (promotion-triage-count-label-html
                       surface
                       "Source unavailable"
                       :source-unavailable))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value
                             counts
                             :source-unavailable)))))
            (:tr (:td (promotion-triage-count-label-html
                       surface
                       "Stale"
                       :stale))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value counts :stale)))))
            (:tr (:td (promotion-triage-count-label-html
                       surface
                       "Unknown missing envelope"
                       :unknown-missing-envelope))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value
                             counts
                             :unknown-missing-envelope)))))
            (:tr (:td (promotion-triage-count-label-html
                       surface
                       "Unknown malformed envelope"
                       :unknown-malformed-envelope))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value
                             counts
                             :unknown-malformed-envelope)))))
            (:tr (:td (promotion-triage-count-label-html
                       surface
                       "Mixed states"
                       :mixed-states))
                 (:td (:tt (views:esc
                            (promotion-triage-count-value
                             counts
                             :mixed-states))))))))

(defun promotion-triage-row-inspect-spec (row)
  (list :target (getf row :inspect-target)
        :select "Overview"
        :label "Inspect plan"))

(defun promotion-triage-row-freshness-spec (row)
  (list :target (getf row :inspect-target)
        :select "Source freshness"
        :label "Review freshness"))

(defun promotion-triage-row-action-review-spec (row)
  (let ((target (getf row :inspect-target)))
    (case (getf row :attention-category)
      (:all-fresh
       (list :target target
             :select "Overview"
             :label "Review no-action status"))
      (:source-unavailable
       (list :target target
             :select "Source page"
             :label "Review source issue"))
      (:stale
       (list :target target
             :select "Overview"
             :label "Review stale action"))
      (:unknown-missing-envelope
       (list :target target
             :select "Source freshness"
             :label "Review restore action"))
      (:unknown-malformed-envelope
       (list :target target
             :select "Source freshness"
             :label "Review repair action"))
      (:mixed-states
       (list :target target
             :select "Source freshness"
             :label "Review mixed action"))
      (otherwise
       (list :target target
             :select "Overview"
             :label "Review action")))))

(defun promotion-triage-drilldown-html (spec)
  (views:object-ref (getf spec :target)
                    :display (getf spec :label)
                    :select (getf spec :select)))

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
                     (:th (views:esc "Inspect plan"))
                     (:th (views:esc "Review freshness"))
                     (:th (views:esc "Review action")))
                (loop for row in rows
                      for inspect-spec = (promotion-triage-row-inspect-spec row)
                      for freshness-spec = (promotion-triage-row-freshness-spec row)
                      for action-spec = (promotion-triage-row-action-review-spec row)
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
                            (:td
                             (views:esc
                              (getf row :recommended-next-action-summary)))
                            (:td
                             (promotion-triage-drilldown-html inspect-spec))
                            (:td
                             (promotion-triage-drilldown-html freshness-spec))
                            (:td
                             (promotion-triage-drilldown-html action-spec)))))))
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
      (promotion-triage-counts-table-html surface counts)
      (:h4 (views:esc (promotion-triage-filter-title filter)))
      (promotion-triage-rows-table-html rows))))

(defmethod views:text-representation ((surface localhost-fedwiki-page-promotion-surface))
  (localhost-fedwiki-page-promotion-surface-title surface))

(defmethod views:text-representation ((plan localhost-fedwiki-page-promotion-plan))
  (localhost-fedwiki-page-promotion-plan-title plan))

(defmethod views:text-representation ((plan localhost-fedwiki-page-publication-plan))
  (localhost-fedwiki-page-publication-plan-title plan))

(defmethod views:text-representation
    ((issue localhost-fedwiki-page-promotion-source-unavailable-issue))
  (title-of issue))

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

(views:defview 👀overview (issue localhost-fedwiki-page-promotion-source-unavailable-issue)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc (title-of issue)))
      (:p (views:esc (summary-of issue)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Classification"))
                   (:td (:tt (views:esc
                              (promotion-code-string
                               (localhost-fedwiki-page-promotion-source-unavailable-issue-classification
                                issue))))))
              (:tr (:td (views:esc "Plan id"))
                   (:td (:tt (views:esc
                              (localhost-fedwiki-page-promotion-source-unavailable-issue-plan-id
                               issue)))))
              (:tr (:td (views:esc "Source page id"))
                   (:td (:tt (views:esc
                              (localhost-fedwiki-page-promotion-source-unavailable-issue-source-page-id
                               issue)))))
              (:tr (:td (views:esc "Source slug"))
                   (:td (:tt (views:esc
                              (localhost-fedwiki-page-promotion-source-unavailable-issue-source-page-slug
                               issue)))))
              (:tr (:td (views:esc "Source path"))
                   (:td (:tt (views:esc
                              (localhost-fedwiki-page-promotion-source-unavailable-issue-source-page-path
                               issue)))))
              (:tr (:td (views:esc "Source title"))
                   (:td (:tt (views:esc
                              (localhost-fedwiki-page-promotion-source-unavailable-issue-source-page-title
                               issue)))))
              (:tr (:td (views:esc "Source URL"))
                   (:td (:tt (views:esc
                              (localhost-fedwiki-page-promotion-source-unavailable-issue-source-html-url
                               issue)))))
              (:tr (:td (views:esc "Observed missing pathname"))
                   (:td (:tt (views:esc
                              (or (localhost-fedwiki-page-promotion-source-unavailable-issue-missing-pathname
                                   issue)
                                  "n/a")))))
              (:tr (:td (views:esc "Condition type"))
                   (:td (:tt (views:esc
                              (promotion-code-string
                               (localhost-fedwiki-page-promotion-source-unavailable-issue-condition-type
                                issue))))))
              (:tr (:td (views:esc "Condition message"))
                   (:td (views:esc
                         (localhost-fedwiki-page-promotion-source-unavailable-issue-condition-message
                          issue))))))))

(views:defview 👀condition (issue localhost-fedwiki-page-promotion-source-unavailable-issue)
  (views:html-view :title "Condition" :priority 2
    (views:html
      (:pre :style "white-space: pre-wrap;"
            (views:esc
             (localhost-fedwiki-page-promotion-source-unavailable-reason
              issue))))))

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
        (promotion-dmx-backend-block-html)
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Plan count"))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value counts
                                                              :plan-count)))))
                (:tr (:td (promotion-triage-count-label-html
                           surface
                           "Attention needed"
                           :attention-needed))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :attention-needed)))))
                (:tr (:td (promotion-triage-count-label-html
                           surface
                           "All fresh"
                           :all-fresh))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value counts
                                                              :all-fresh)))))
                (:tr (:td (promotion-triage-count-label-html
                           surface
                           "Source unavailable"
                           :source-unavailable))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :source-unavailable)))))
                (:tr (:td (promotion-triage-count-label-html
                           surface
                           "Stale"
                           :stale))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value counts
                                                              :stale)))))
                (:tr (:td (promotion-triage-count-label-html
                           surface
                           "Unknown missing envelope"
                           :unknown-missing-envelope))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :unknown-missing-envelope)))))
                (:tr (:td (promotion-triage-count-label-html
                           surface
                           "Unknown malformed envelope"
                           :unknown-malformed-envelope))
                     (:td (:tt (views:esc
                                (promotion-triage-count-value
                                 counts
                                 :unknown-malformed-envelope)))))
                (:tr (:td (promotion-triage-count-label-html
                           surface
                           "Mixed states"
                           :mixed-states))
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

(views:defview 👀source-unavailable (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Source unavailable" :priority 5
    (promotion-triage-scope-html surface :source-unavailable)))

(views:defview 👀stale (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Stale" :priority 6
    (promotion-triage-scope-html surface :stale)))

(views:defview 👀unknown-missing-envelope (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Unknown missing envelope" :priority 7
    (promotion-triage-scope-html surface :unknown-missing-envelope)))

(views:defview 👀unknown-malformed-envelope (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Unknown malformed envelope" :priority 8
    (promotion-triage-scope-html surface :unknown-malformed-envelope)))

(views:defview 👀mixed-states (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Mixed states" :priority 9
    (promotion-triage-scope-html surface :mixed-states)))

(views:defview 👀dmx-handover (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "DMX handover" :priority 10
    (let* ((review
             (review-localhost-fedwiki-page-promotion-handover-dmx-dry-run
              surface))
           (summary (getf review :summary))
           (evidence (getf review :evidence)))
      (views:html
        (:p (views:esc
             "This one-topic DMX handover keeps HyperDoc as the richer diagnostic and authoring environment while seeding the explicit DMX target topicmap with the current workflow checkpoint. Live DMX write stays separate and conservative; this view shows the ready-to-execute topic payload plus canonical dry-run evidence."))
        (promotion-dmx-backend-block-html)
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Target topicmap id"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :workspace-topicmap-id))))))
                (:tr (:td (views:esc "Target topicmap route"))
                     (:td (:tt (views:esc
                                (or (getf summary :workspace-topicmap-route)
                                    "unavailable")))))
                (:tr (:td (views:esc "Topic title"))
                     (:td (:tt (views:esc
                                (or (getf summary :topic-title)
                                    "unavailable")))))
                (:tr (:td (views:esc "Snippet id"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :snippet-id))))))
                (:tr (:td (views:esc "Topic URI"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :uri))))))
                (:tr (:td (views:esc "Topic action"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :topic-action))))))
                (:tr (:td (views:esc "Topicmap action"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :topicmap-action))))))
                (:tr (:td (views:esc "View-props validation"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :view-props-validation-status))))))
                (:tr (:td (views:esc "Forbidden short keys"))
                     (:td (:tt (views:esc
                                (promotion-list-string
                                 (getf summary :forbidden-short-keys))))))
                (:tr (:td (views:esc "Related HyperDoc page"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :related-hyperdoc-page-title))))))
                (:tr (:td (views:esc "Related topic id"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :related-topic-id))))))
                (:tr (:td (views:esc "Live DMX write"))
                     (:td (:tt (views:esc
                                (promotion-dmx-live-write-label
                                 (getf summary :live-write-configured)))))))
        (:h4 (views:esc "Normalized topicmap view payload"))
        (:pre :style "white-space: pre-wrap;"
              (views:esc (or (getf summary :normalized-view-props-json)
                             "unavailable")))
        (:h4 (views:esc "Seed topic body"))
        (:pre :style "white-space: pre-wrap;"
              (views:esc (or (getf summary :topic-body)
                             (getf summary :message)
                             "unavailable")))
        (:h4 (views:esc "Dry-run evidence"))
        (:pre :style "white-space: pre-wrap;"
              (views:esc evidence))))))

(views:defview 👀plans (surface localhost-fedwiki-page-promotion-surface)
  (views:html-view :title "Plans" :priority 11
    (views:html
      (:p "Each plan stays inspectable as a separate localhost FedWiki page-promotion boundary.")
      (:ul
       (loop for plan in (localhost-fedwiki-page-promotion-surface-plans surface)
             do (views:html
                  (:li (views:object-ref plan))))))))

(views:defview 👀overview (plan localhost-fedwiki-page-promotion-plan)
  (views:html-view :title "Overview" :priority 1
    (let ((source (localhost-fedwiki-page-promotion-plan-source plan))
          (source-issue
            (localhost-fedwiki-page-promotion-plan-source-issue plan))
          (generated-page
            (localhost-fedwiki-page-promotion-plan-generated-page plan))
          (status
            (localhost-fedwiki-page-promotion-plan-sync-status plan))
          (provenance-modes
            (promotion-provenance-modes-present plan))
          (dmx-summary
            (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan))
          (publication-plan
            (localhost-fedwiki-page-promotion-plan-publication-plan plan)))
      (views:html
        (:h3 (views:esc (localhost-fedwiki-page-promotion-plan-title plan)))
        (:p (views:esc (localhost-fedwiki-page-promotion-plan-summary plan)))
        (when source-issue
          (views:html
            (:p (views:esc
                 "This plan stays open on a fail-soft boundary. The configured localhost FedWiki source page file is currently unavailable, so source-derived story items, promoted topics, and DMX dry-run stay degraded until that page file is restored."))
            (:p
             (promotion-object-link-html
              source-issue
              :display "Inspect source-unavailable issue"
              :select "Overview"))))
        (:h4 (views:esc "Status and actions"))
        (:p (views:esc
             "Use this compact surface to check whether the local artifacts are in sync, whether their embedded source snapshot is fresh, stale because the reflected fingerprint differs, or unknown because the reflected envelope is missing or malformed, see the next safe action for each artifact, confirm the provenance modes present in the promoted topics, and trigger explicit local regeneration or DMX dry-run review without switching to the raw Operations tab."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source availability"))
                     (:td (:tt (views:esc
                                (promotion-source-availability-label
                                 (getf status :source-availability-state))))))
                (:tr (:td (views:esc "Source issue"))
                     (:td
                      (promotion-object-link-html
                       source-issue
                       :display "Inspect source-unavailable issue"
                       :select "Overview"
                       :fallback "none")))
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
                (:tr (:td (views:esc "Source path"))
                     (:td (:tt (views:esc
                                (localhost-fedwiki-source-data-fedwiki-relative-path
                                 source)))))
                (:tr (:td (views:esc "Generated HyperDoc page"))
                     (:td
                      (promotion-generated-page-link-html
                       generated-page
                       :display "Review generated page")))
                (:tr (:td (views:esc "Publication plan"))
                     (:td
                      (promotion-object-link-html
                       publication-plan
                       :display "Review publication plan"
                       :select "Overview"
                       :fallback "none")))
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
         (when publication-plan
           (views:html
             (:li
              (promotion-object-link-html
               publication-plan
               :display "Review publication dry-run"
               :select "Dry-run"))))
         (:li
          (views:eval-button
           "Inspect sync status"
           (views:thunk
             (localhost-fedwiki-page-promotion-plan-sync-status plan))
           "Inspect the current page/snippet sync state for this promotion plan.")))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source availability"))
                     (:td (:tt (views:esc
                                (promotion-source-availability-label
                                 (getf status :source-availability-state))))))
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
                (:tr (:td (views:esc "Source issue"))
                     (:td
                      (promotion-object-link-html
                       source-issue
                       :display "Inspect source-unavailable issue"
                       :select "Overview"
                       :fallback "none")))
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
                (:tr (:td (views:esc "Generated HyperDoc page"))
                     (:td
                      (promotion-generated-page-link-html
                       generated-page
                       :display "Review generated page")))
                (:tr (:td (views:esc "Publication plan"))
                     (:td
                      (promotion-object-link-html
                       publication-plan
                       :display "Review publication plan"
                       :select "Overview"
                       :fallback "none")))
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
    (let ((status (localhost-fedwiki-page-promotion-plan-sync-status plan))
          (source-issue
            (localhost-fedwiki-page-promotion-plan-source-issue plan)))
      (views:html
        (:p "These diagnostics compare the current normalized localhost FedWiki source snapshot against the reflected snapshots embedded in the committed page and snippet artifacts. Stale reasons are fingerprint-based comparisons, not semantic diffs of the source text.")
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source availability"))
                     (:td (:tt (views:esc
                                (promotion-source-availability-label
                                 (getf status :source-availability-state))))))
                (:tr (:td (views:esc "Source issue"))
                     (:td
                      (promotion-object-link-html
                       source-issue
                       :display "Inspect source-unavailable issue"
                       :select "Overview"
                       :fallback "none")))
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
           (source-issue
             (localhost-fedwiki-page-promotion-plan-source-issue plan))
           (status
             (localhost-fedwiki-page-promotion-plan-sync-status plan))
           (generated-page
             (localhost-fedwiki-page-promotion-plan-generated-page plan))
           (provenance (localhost-fedwiki-source-data-provenance source)))
      (views:html
        (:p "Normalized localhost FedWiki page source. This is the read boundary for promotion, before any local HyperDoc write or DMX write step.")
        (when source-issue
          (views:html
            (:p (views:esc
                 "This Source page view is degraded on the exact missing-file boundary. HyperDoc keeps the canonical source identity and path inspectable while the localhost FedWiki page file itself is unavailable."))
            (:p
             (promotion-object-link-html
              source-issue
              :display "Inspect source-unavailable issue"
              :select "Overview"))))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source availability"))
                     (:td (:tt (views:esc
                                (promotion-source-availability-label
                                 (getf status :source-availability-state))))))
                (:tr (:td (views:esc "Source issue"))
                     (:td
                      (promotion-object-link-html
                       source-issue
                       :display "Inspect source-unavailable issue"
                       :select "Overview"
                       :fallback "none")))
                (:tr (:td (views:esc "Normalized source object"))
                     (:td (views:object-ref source)))
                (:tr (:td (views:esc "Generated HyperDoc page"))
                     (:td
                      (promotion-generated-page-link-html
                       generated-page
                       :display "Open generated page")))
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
    (let ((provenance (localhost-fedwiki-source-data-provenance source))
          (generated-page
            (localhost-fedwiki-source-generated-page source)))
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
                (:tr (:td (views:esc "Generated HyperDoc page"))
                     (:td
                      (promotion-generated-page-link-html
                       generated-page
                       :display "Open generated page")))
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
           (source-issue
             (localhost-fedwiki-page-promotion-plan-source-issue plan))
           (classification (getf summary :classification))
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
                      (:tr (:td (views:esc "View-props validation"))
                           (:td (:tt (views:esc
                                      (promotion-code-string
                                       (getf summary :view-props-validation-status))))))
                      (:tr (:td (views:esc "Forbidden short keys"))
                           (:td (:tt (views:esc
                                      (promotion-list-string
                                       (getf summary :forbidden-short-keys))))))
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
              (:h4 (views:esc "Normalized topicmap view payload"))
              (:pre :style "white-space: pre-wrap;"
                    (views:esc (or (getf summary :normalized-view-props-json)
                                   "unavailable")))
              (:h4 (views:esc "Dry-run evidence"))
              (:pre :style "white-space: pre-wrap;"
                    (views:esc evidence)))
            (if (eql classification :source-unavailable)
                (views:html
                  (:table :class "inspector-table"
                          (:tr (:td (views:esc "Classification"))
                               (:td (:tt (views:esc
                                          (promotion-code-string
                                           classification)))))
                          (:tr (:td (views:esc "Source page id"))
                               (:td (:tt (views:esc
                                          (or (getf summary :source-page-id)
                                              "n/a")))))
                          (:tr (:td (views:esc "Source page path"))
                               (:td (:tt (views:esc
                                          (or (getf summary :source-page-path)
                                              "n/a")))))
                          (:tr (:td (views:esc "Source issue"))
                               (:td
                                (promotion-object-link-html
                                 source-issue
                                 :display "Inspect source-unavailable issue"
                                 :select "Overview"
                                 :fallback "none"))))
                  (:p (views:esc (getf summary :message)))
                  (:h4 (views:esc "Dry-run evidence"))
                  (:pre :style "white-space: pre-wrap;"
                        (views:esc evidence)))
                (if (eql classification :payload-invalid)
                    (views:html
                      (:table :class "inspector-table"
                              (:tr (:td (views:esc "Classification"))
                                   (:td (:tt (views:esc
                                              (promotion-code-string
                                               classification)))))
                              (:tr (:td (views:esc "Workspace topicmap id"))
                                   (:td (:tt (views:esc
                                              (promotion-code-string
                                               (getf summary :workspace-topicmap-id))))))
                              (:tr (:td (views:esc "Missing long-form keys"))
                                   (:td (:tt (views:esc
                                              (promotion-list-string
                                               (getf summary :missing-long-keys))))))
                              (:tr (:td (views:esc "Forbidden short keys"))
                                   (:td (:tt (views:esc
                                              (promotion-list-string
                                               (getf summary :forbidden-short-keys))))))
                              (:tr (:td (views:esc "Validation error"))
                                   (:td
                                    (promotion-object-link-html
                                     (getf summary :validation-error)
                                     :display "Inspect validation error"
                                     :select "Condition"
                                     :fallback "none"))))
                      (:p (views:esc (getf summary :message)))
                      (:h4 (views:esc "Normalized topicmap view payload"))
                      (:pre :style "white-space: pre-wrap;"
                            (views:esc (or (getf summary :normalized-view-props-json)
                                           "unavailable")))
                      (:h4 (views:esc "Dry-run evidence"))
                      (:pre :style "white-space: pre-wrap;"
                            (views:esc evidence)))
                    (views:html
                      (:p (views:esc (getf summary :message))))))))))))

(views:defview 👀overview (plan localhost-fedwiki-page-publication-plan)
  (views:html-view :title "Overview" :priority 1
    (let* ((summary
             (localhost-fedwiki-page-publication-plan-dry-run-summary plan))
           (source-plan
             (localhost-fedwiki-page-publication-plan-source-plan plan))
           (planned-write (getf summary :planned-write)))
      (views:html
        (:h3 (views:esc (localhost-fedwiki-page-publication-plan-title plan)))
        (:p (views:esc (localhost-fedwiki-page-publication-plan-summary plan)))
        (:p (views:esc
             "This stays on the localhost-first, dry-run-first publication boundary. It reads the current local page, checks JSON and journal preflight, compares against the configured remote site and slug, and keeps any live publication step explicit and page-scoped."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source promotion plan"))
                     (:td
                      (promotion-object-link-html
                       source-plan
                       :display
                       (localhost-fedwiki-page-promotion-plan-title source-plan)
                       :select "Overview")))
                (:tr (:td (views:esc "Source page id"))
                     (:td (:tt (views:esc (getf summary :source-page-id)))))
                (:tr (:td (views:esc "Source path"))
                     (:td (:tt (views:esc (getf summary :source-page-path)))))
                (:tr (:td (views:esc "Target site"))
                     (:td (:tt (views:esc (getf summary :target-site)))))
                (:tr (:td (views:esc "Target slug"))
                     (:td (:tt (views:esc (getf summary :target-slug)))))
                (:tr (:td (views:esc "Publication status"))
                     (:td (:tt (views:esc
                                (promotion-publication-status-label
                                 (getf summary :publication-status))))))
                (:tr (:td (views:esc "Target exists"))
                     (:td (:tt (views:esc
                                (promotion-publication-target-exists-label
                                 (getf summary :target-exists-status))))))
                (:tr (:td (views:esc "Divergent fields"))
                     (:td (:tt (views:esc
                                (promotion-list-string
                                 (getf summary :divergent-fields))))))
                (:tr (:td (views:esc "Local JSON syntax"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf summary :local-json-syntax-valid-p))))))
                (:tr (:td (views:esc "Local journal gate"))
                     (:td (:tt (views:esc
                                (if (getf summary :local-journal-valid-p)
                                    "pass"
                                    "fail")))))
                (:tr (:td (views:esc "Planned write"))
                     (:td (:tt (views:esc
                                (promotion-planned-write-label
                                 planned-write)))))
                (:tr (:td (views:esc "Live publication configured"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf summary :live-publication-configured-p)))))))
        (:ul
         (:li
          (promotion-object-link-html
           source-plan
           :display "Review source promotion plan"
           :select "Overview"))
         (:li
          (views:eval-button
           "Review publication dry-run"
           (views:thunk
             (review-localhost-fedwiki-page-publication-plan-dry-run plan))
           "Recompute the current dry-run publication summary and inspect the exact bounded evidence."))
         (:li
          (promotion-object-link-html
           plan
           :display "Inspect local current page state"
           :select "Local page"))
         (:li
          (promotion-object-link-html
           plan
           :display "Inspect target remote state"
           :select "Target page")))
        (when-let (message (getf summary :message))
          (views:html
            (:p (views:esc message))))))))

(views:defview 👀local-page (plan localhost-fedwiki-page-publication-plan)
  (views:html-view :title "Local page" :priority 2
    (let* ((summary
             (localhost-fedwiki-page-publication-plan-dry-run-summary plan))
           (local-page (getf summary :local-page)))
      (views:html
        (:p (views:esc
             "This is the current local authored page state that would be considered for publication after JSON syntax and journal replay preflight."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source page id"))
                     (:td (:tt (views:esc (getf summary :source-page-id)))))
                (:tr (:td (views:esc "Source path"))
                     (:td (:tt (views:esc (getf summary :source-page-path)))))
                (:tr (:td (views:esc "Title"))
                     (:td (:tt (views:esc
                                (or (getf summary :source-page-title)
                                    "n/a")))))
                (:tr (:td (views:esc "Fingerprint"))
                     (:td (:tt (views:esc
                                (or (getf summary :local-page-fingerprint)
                                    "unavailable")))))
                (:tr (:td (views:esc "Summary"))
                     (:td (:tt (views:esc
                                (or (getf summary :local-page-summary)
                                    "unavailable")))))
                (:tr (:td (views:esc "JSON syntax valid"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf summary :local-json-syntax-valid-p))))))
                (:tr (:td (views:esc "Journal gate valid"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf summary :local-journal-valid-p))))))
                (:tr (:td (views:esc "Journal findings"))
                     (:td (:tt (views:esc
                                (format nil "~S"
                                        (or (getf summary :local-journal-findings)
                                            '())))))))
        (when local-page
          (views:html
            (:h4 (views:esc "Current page payload"))
            (:pre :style "white-space: pre-wrap;"
                  (views:esc
                   (with-standard-io-syntax
                     (let ((*print-pretty* t))
                       (prin1-to-string local-page)))))))))))

(views:defview 👀target-page (plan localhost-fedwiki-page-publication-plan)
  (views:html-view :title "Target page" :priority 3
    (let* ((summary
             (localhost-fedwiki-page-publication-plan-dry-run-summary plan))
           (target-page (getf summary :target-page)))
      (views:html
        (:p (views:esc
             "This is the current remote target observation for the configured site and slug. It stays descriptive; no live publication is executed from this view."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Target site"))
                     (:td (:tt (views:esc (getf summary :target-site)))))
                (:tr (:td (views:esc "Target slug"))
                     (:td (:tt (views:esc (getf summary :target-slug)))))
                (:tr (:td (views:esc "Target page id"))
                     (:td (:tt (views:esc (getf summary :target-page-id)))))
                (:tr (:td (views:esc "Protocol"))
                     (:td (:tt (views:esc (getf summary :target-protocol)))))
                (:tr (:td (views:esc "HTML URL"))
                     (:td (:tt (views:esc (getf summary :target-html-url)))))
                (:tr (:td (views:esc "JSON URL"))
                     (:td (:tt (views:esc (getf summary :target-json-url)))))
                (:tr (:td (views:esc "Target exists"))
                     (:td (:tt (views:esc
                                (promotion-publication-target-exists-label
                                 (getf summary :target-exists-status))))))
                (:tr (:td (views:esc "Publication status"))
                     (:td (:tt (views:esc
                                (promotion-publication-status-label
                                 (getf summary :publication-status))))))
                (:tr (:td (views:esc "Fingerprint"))
                     (:td (:tt (views:esc
                                (or (getf summary :target-page-fingerprint)
                                    "unavailable")))))
                (:tr (:td (views:esc "Summary"))
                     (:td (:tt (views:esc
                                (or (getf summary :target-page-summary)
                                    "unavailable")))))
                (:tr (:td (views:esc "Journal findings"))
                     (:td (:tt (views:esc
                                (format nil "~S"
                                        (or (getf summary :target-journal-findings)
                                            '())))))))
        (when-let (message (getf summary :message))
          (views:html
            (:p (views:esc message))))
        (when target-page
          (views:html
            (:h4 (views:esc "Observed target payload"))
            (:pre :style "white-space: pre-wrap;"
                  (views:esc
                   (with-standard-io-syntax
                     (let ((*print-pretty* t))
                       (prin1-to-string target-page)))))))))))

(views:defview 👀dry-run (plan localhost-fedwiki-page-publication-plan)
  (views:html-view :title "Dry-run" :priority 4
    (let* ((summary
             (localhost-fedwiki-page-publication-plan-dry-run-summary plan))
           (planned-write (getf summary :planned-write))
           (evidence
             (localhost-fedwiki-page-publication-plan-dry-run-evidence plan)))
      (views:html
        (:p (views:esc
             "This stays on the bounded dry-run publication seam. It reports the exact page-scoped write that would occur, but it does not execute any remote mutation."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Publication status"))
                     (:td (:tt (views:esc
                                (promotion-publication-status-label
                                 (getf summary :publication-status))))))
                (:tr (:td (views:esc "Target exists"))
                     (:td (:tt (views:esc
                                (promotion-publication-target-exists-label
                                 (getf summary :target-exists-status))))))
                (:tr (:td (views:esc "Exact write action"))
                     (:td (:tt (views:esc
                                (promotion-planned-write-label
                                 planned-write)))))
                (:tr (:td (views:esc "Exact write fields"))
                     (:td (:tt (views:esc
                                (promotion-list-string
                                 (getf planned-write :fields))))))
                (:tr (:td (views:esc "Live publication configured"))
                     (:td (:tt (views:esc
                                (promotion-yes/no-label
                                 (getf summary :live-publication-configured-p))))))
                (:tr (:td (views:esc "Live entrypoint"))
                     (:td (:tt (views:esc
                                (promotion-code-string
                                 (getf summary :live-publication-entrypoint)))))))
        (when-let (reason (getf planned-write :reason))
          (views:html
            (:p (views:esc reason))))
        (when-let (payload (getf planned-write :page))
          (views:html
            (:h4 (views:esc "Planned page payload"))
            (:pre :style "white-space: pre-wrap;"
                  (views:esc
                   (with-standard-io-syntax
                     (let ((*print-pretty* t))
                       (prin1-to-string payload)))))))
        (:h4 (views:esc "Dry-run evidence"))
        (:pre :style "white-space: pre-wrap;"
              (views:esc evidence))))))
