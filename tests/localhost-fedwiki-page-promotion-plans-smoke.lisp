;;;; Smoke tests for inspectable localhost FedWiki page promotion plans
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-LOCALHOST-FEDWIKI-PAGE-PROMOTION-PLANS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun localhost-fedwiki-page-promotion-workflow-relative-path ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/Localhost FedWiki page promotion workflow.html"))

(defun assert-view-titles-present (views titles label)
  (dolist (title titles)
    (assert-true (smoke-find-view-by-title views title)
                 (format nil "~A must expose a ~A view" label title))))

(defun strip-artifact-envelope-line (contents)
  (nth-value 1 (hyperdoc::split-string-first-line contents)))

(defun malformed-html-envelope-contents (body)
  (format nil "<!-- ~A (:BROKEN~%~A"
          hyperdoc::+localhost-fedwiki-page-source-snapshot-envelope-tag+
          body))

(defun malformed-snippet-envelope-contents (body)
  (format nil ";; ~A (:BROKEN~%~A"
          hyperdoc::+localhost-fedwiki-page-source-snapshot-envelope-tag+
          body))

(defun run-localhost-fedwiki-page-promotion-plan-view-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((surface (hyperdoc::current-localhost-fedwiki-page-promotion-surface))
         (collective (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan))
         (repro (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
         (surface-views (load-inspector-views-for-object surface))
         (collective-views (load-inspector-views-for-object collective))
         (repro-views (load-inspector-views-for-object repro))
         (collective-promoted-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "Promoted topics")))
         (collective-overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "Overview")))
         (collective-freshness-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "Source freshness")))
         (repro-overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Overview")))
         (repro-freshness-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Source freshness")))
         (collective-story-items-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "Story items")))
         (collective-dmx-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "DMX dry-run")))
         (repro-promoted-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Promoted topics")))
         (repro-dmx-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "DMX dry-run"))))
    (assert-view-titles-present surface-views
                                '("Overview" "Plans")
                                "Promotion surface")
    (assert-view-titles-present collective-views
                                '("Overview"
                                  "Source page"
                                  "Story items"
                                  "Fragments"
                                  "Promoted topics"
                                  "Page output"
                                  "Source freshness"
                                  "Snippet metadata"
                                  "DMX dry-run")
                                "Collective knowledge promotion plan")
    (assert-view-titles-present repro-views
                                '("Overview"
                                  "Source page"
                                  "Story items"
                                  "Fragments"
                                  "Promoted topics"
                                  "Page output"
                                  "Source freshness"
                                  "Snippet metadata"
                                  "DMX dry-run")
                                "Reproducible DevEnv promotion plan")
    (assert-true
     (search "story-item-fragment" collective-promoted-html :test #'char=)
     "Collective knowledge promoted-topics view must expose fragment-derived provenance")
    (assert-true
     (search "story-item-id-and-journal" collective-promoted-html :test #'char=)
     "Collective knowledge promoted-topics view must expose provenance classification")
    (assert-true
     (search "story-item" collective-story-items-html :test #'char=)
     "Collective knowledge story-items view must preserve whole-item normalized provenance")
    (assert-true
     (search "Status and actions" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose the compact status-and-actions surface")
    (assert-true
     (search "Page synced" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose page sync status")
    (assert-true
     (search "Snippet synced" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose snippet sync status")
    (assert-true
     (search "Page source fresh" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose page source freshness")
    (assert-true
     (search "Snippet source fresh" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose snippet source freshness")
    (assert-true
     (search "Page reflected snapshot" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose page reflected-snapshot state")
    (assert-true
     (search "Snippet reflected snapshot" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose snippet reflected-snapshot state")
    (assert-true
     (search "Current source fingerprint" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose the current source fingerprint")
    (assert-true
     (search "Current source summary" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose the current source summary")
    (assert-true
     (search "fnv1a64:" collective-overview-html :test #'char-equal)
     "Collective knowledge overview must expose the normalized source fingerprint value")
    (assert-true
     (search "story-item-fragment" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose fragment-based provenance modes")
    (assert-true
     (search "DMX dry-run summary available" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose DMX dry-run summary availability")
    (assert-true
     (search "fresh, stale because the reflected fingerprint differs, or unknown because the reflected envelope is missing or malformed"
             collective-overview-html
             :test #'char=)
     "Collective knowledge overview must explain the concise freshness wording")
    (assert-true
     (search "Page recommended next action" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose page remediation guidance")
    (assert-true
     (search "Snippet recommended next action" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose snippet remediation guidance")
    (assert-true
     (search "No regeneration needed; the page artifact already reflects the current source snapshot."
             collective-overview-html
             :test #'char=)
     "Collective knowledge overview must surface the no-change page recommendation")
    (assert-true
     (search "No action needed" collective-overview-html :test #'char=)
     "Collective knowledge overview must surface a passive no-action affordance")
    (assert-true
     (search "No regeneration needed; the snippet artifact already reflects the current source snapshot."
             collective-overview-html
             :test #'char=)
     "Collective knowledge overview must surface the no-change snippet recommendation")
    (dolist (label '("Regenerate page artifact"
                     "Regenerate snippet artifact"
                     "Regenerate both artifacts"
                     "Review DMX dry-run"
                     "Inspect sync status"))
      (assert-true
       (search label collective-overview-html :test #'char=)
       (format nil "Collective knowledge overview must expose the human-facing action label ~A" label)))
    (assert-true
     (search "story-item" repro-promoted-html :test #'char=)
     "Second real page promoted-topics view must expose whole-item-derived subtopics")
    (assert-true
     (search "multi-item-derived" repro-promoted-html :test #'char=)
     "Second real page promoted-topics view must expose the multi-item-derived umbrella provenance")
    (assert-true
     (search "Status and actions" repro-overview-html :test #'char=)
     "Second real-page overview must expose the compact status-and-actions surface")
    (assert-true
     (search "Page synced" repro-overview-html :test #'char=)
     "Second real-page overview must expose page sync status")
    (assert-true
     (search "Snippet synced" repro-overview-html :test #'char=)
     "Second real-page overview must expose snippet sync status")
    (assert-true
     (search "Page source fresh" repro-overview-html :test #'char=)
     "Second real-page overview must expose page source freshness")
    (assert-true
     (search "Snippet source fresh" repro-overview-html :test #'char=)
     "Second real-page overview must expose snippet source freshness")
    (assert-true
     (search "Page reflected snapshot" repro-overview-html :test #'char=)
     "Second real-page overview must expose page reflected-snapshot state")
    (assert-true
     (search "Snippet reflected snapshot" repro-overview-html :test #'char=)
     "Second real-page overview must expose snippet reflected-snapshot state")
    (assert-true
     (search "Current source fingerprint" repro-overview-html :test #'char=)
     "Second real-page overview must expose the current source fingerprint")
    (assert-true
     (search "Current source summary" repro-overview-html :test #'char=)
     "Second real-page overview must expose the current source summary")
    (assert-true
     (search "fnv1a64:" repro-overview-html :test #'char-equal)
     "Second real-page overview must expose the normalized source fingerprint value")
    (assert-true
     (search "multi-item-derived" repro-overview-html :test #'char=)
     "Second real-page overview must expose multi-item provenance modes")
    (assert-true
     (search "DMX dry-run summary available" repro-overview-html :test #'char=)
     "Second real-page overview must expose DMX dry-run summary availability")
    (assert-true
     (search "fresh, stale because the reflected fingerprint differs, or unknown because the reflected envelope is missing or malformed"
             repro-overview-html
             :test #'char=)
     "Second real-page overview must explain the concise freshness wording")
    (assert-true
     (search "Page recommended next action" repro-overview-html :test #'char=)
     "Second real-page overview must expose page remediation guidance")
    (assert-true
     (search "Snippet recommended next action" repro-overview-html :test #'char=)
     "Second real-page overview must expose snippet remediation guidance")
    (assert-true
     (search "No regeneration needed; the page artifact already reflects the current source snapshot."
             repro-overview-html
             :test #'char=)
     "Second real-page overview must surface the no-change page recommendation")
    (assert-true
     (search "No action needed" repro-overview-html :test #'char=)
     "Second real-page overview must surface a passive no-action affordance")
    (assert-true
     (search "No regeneration needed; the snippet artifact already reflects the current source snapshot."
             repro-overview-html
             :test #'char=)
     "Second real-page overview must surface the no-change snippet recommendation")
    (dolist (label '("Regenerate page artifact"
                     "Regenerate snippet artifact"
                     "Regenerate both artifacts"
                     "Review DMX dry-run"
                     "Inspect sync status"))
      (assert-true
       (search label repro-overview-html :test #'char=)
       (format nil "Second real-page overview must expose the human-facing action label ~A" label)))
    (dolist (html (list collective-freshness-html
                        repro-freshness-html))
      (assert-true
       (search "Current source fingerprint" html :test #'char=)
       "Source freshness view must expose the current source fingerprint")
      (assert-true
       (search "Reflected snapshot fingerprint" html :test #'char=)
       "Source freshness view must expose the reflected snapshot fingerprint")
      (assert-true
       (search "Diagnostic reason" html :test #'char=)
       "Source freshness view must expose a human-facing diagnostic reason")
      (assert-true
       (search "Recommended next action" html :test #'char=)
       "Source freshness view must expose remediation guidance")
      (assert-true
       (search "fingerprint-based comparisons, not semantic diffs" html :test #'char=)
       "Source freshness view must state the conservative fingerprint-based diagnostic model"))
    (assert-true
     (search "matches reflected snapshot fingerprint" collective-freshness-html :test #'char=)
     "Collective knowledge source freshness view must explain the aligned no-change case")
    (assert-true
     (search "No regeneration needed; the page artifact already reflects the current source snapshot."
             collective-freshness-html
             :test #'char=)
     "Collective knowledge source freshness view must expose page remediation guidance")
    (assert-true
     (search "No action needed" collective-freshness-html :test #'char=)
     "Collective knowledge source freshness view must expose a passive no-action affordance")
    (assert-true
     (search "matches reflected snapshot fingerprint" repro-freshness-html :test #'char=)
     "Second real-page source freshness view must explain the aligned no-change case")
    (assert-true
     (search "No regeneration needed; the page artifact already reflects the current source snapshot."
             repro-freshness-html
             :test #'char=)
     "Second real-page source freshness view must expose page remediation guidance")
    (assert-true
     (search "No action needed" repro-freshness-html :test #'char=)
     "Second real-page source freshness view must expose a passive no-action affordance")
    (assert-true
     (search "assets/the-life-cycle-of-collective-knowledge-topic.lisp"
             collective-dmx-html
             :test #'char=)
     "Collective knowledge DMX dry-run view must keep repo-relative snippet source metadata")
    (assert-true
     (search "pages/the-life-cycle-of-collective-knowledge"
             collective-dmx-html
             :test #'char=)
     "Collective knowledge DMX dry-run view must keep repo-relative FedWiki provenance")
    (assert-true
     (not (search "/Users/" collective-dmx-html :test #'char=))
     "Collective knowledge DMX dry-run view must not leak machine-local absolute paths")
    (assert-true
     (search "pages/reproducible-devenv-as-knowledge-artifact"
             repro-dmx-html
             :test #'char=)
     "Second real page DMX dry-run view must keep repo-relative FedWiki provenance")
    (assert-true
     (not (search "/Users/" repro-dmx-html :test #'char=))
     "Second real page DMX dry-run view must not leak machine-local absolute paths")))

(defun run-localhost-fedwiki-page-promotion-entry-point-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((collective-plan
           (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan))
         (repro-plan
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
         (collective-topic-page
           (hyperbook:find-page hyperdoc::*topics*
                                "The Life Cycle of Collective Knowledge"
                                :signal-error? t))
         (repro-topic-page
           (hyperbook:find-page hyperdoc::*topics*
                                "Reproducible DevEnv as Knowledge Artifact"
                                :signal-error? t))
         (workflow-topic-page
           (hyperbook:find-page hyperdoc::*topics*
                                "Localhost FedWiki page promotion workflow"
                                :signal-error? t))
         (collective-topic (hyperdoc::the-life-cycle-of-collective-knowledge-topic))
         (repro-topic
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-topic))
         (workflow-topic
           (hyperdoc::localhost-fedwiki-page-promotion-workflow-topic))
         (collective-source
           (hyperdoc::localhost-fedwiki-page-promotion-plan-source collective-plan))
         (repro-source
           (hyperdoc::localhost-fedwiki-page-promotion-plan-source repro-plan))
         (collective-topic-page-views
           (load-inspector-views-for-object collective-topic-page))
         (repro-topic-page-views
           (load-inspector-views-for-object repro-topic-page))
         (workflow-topic-page-views
           (load-inspector-views-for-object workflow-topic-page))
         (collective-topic-views
           (load-inspector-views-for-object collective-topic))
         (repro-topic-views
           (load-inspector-views-for-object repro-topic))
         (workflow-topic-views
           (load-inspector-views-for-object workflow-topic))
         (collective-source-views
           (load-inspector-views-for-object collective-source))
         (repro-source-views
           (load-inspector-views-for-object repro-source))
         (collective-topic-page-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-topic-page-views
                                      "Promotion plan")))
         (repro-topic-page-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-topic-page-views
                                      "Promotion plan")))
         (collective-topic-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-topic-views
                                      "Promotion plan")))
         (repro-topic-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-topic-views
                                      "Promotion plan")))
         (collective-source-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-source-views
                                      "Promotion plan")))
         (repro-source-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-source-views
                                      "Promotion plan"))))
    (assert-true
     (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-topic-page
      collective-topic-page)
     "Collective knowledge topic page must resolve to a promotion plan")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-topic-page
       collective-topic-page))
     "Collective knowledge topic page must resolve to the correct promotion plan")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-topic-page
       repro-topic-page))
     "Second real-page topic page must resolve to the correct promotion plan")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-topic
       collective-topic))
     "Collective knowledge topic object must resolve to the correct promotion plan")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-topic
       repro-topic))
     "Second real-page topic object must resolve to the correct promotion plan")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-source
       collective-source))
     "Collective knowledge source page must resolve to the correct promotion plan")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-source
       repro-source))
     "Second real-page source page must resolve to the correct promotion plan")
    (assert-true
     (smoke-find-view-by-title collective-topic-page-views "Promotion plan")
     "Collective knowledge topic page must expose a Promotion plan entry point")
    (assert-true
     (smoke-find-view-by-title repro-topic-page-views "Promotion plan")
     "Second real-page topic page must expose a Promotion plan entry point")
    (assert-true
     (smoke-find-view-by-title collective-topic-views "Promotion plan")
     "Collective knowledge topic object must expose a Promotion plan entry point")
    (assert-true
     (smoke-find-view-by-title repro-topic-views "Promotion plan")
     "Second real-page topic object must expose a Promotion plan entry point")
    (assert-true
     (smoke-find-view-by-title collective-source-views "Promotion plan")
     "Collective knowledge source object must expose a Promotion plan entry point")
    (assert-true
     (smoke-find-view-by-title repro-source-views "Promotion plan")
     "Second real-page source object must expose a Promotion plan entry point")
    (assert-true
     (null (smoke-find-view-by-title workflow-topic-page-views "Promotion plan"))
     "Unrelated workflow topic page must not grow a promotion-plan entry point")
    (assert-true
     (null (smoke-find-view-by-title workflow-topic-views "Promotion plan"))
     "Unrelated workflow topic object must not grow a promotion-plan entry point")
    (dolist (html (list collective-topic-page-html
                        repro-topic-page-html
                        collective-topic-html
                        repro-topic-html
                        collective-source-html
                        repro-source-html))
      (assert-true
       (search "Promoted topics" html :test #'char=)
       "Each promotion-plan entry point must link to provenance review")
      (assert-true
       (search "Page output" html :test #'char=)
       "Each promotion-plan entry point must link to output-status review")
      (assert-true
       (search "DMX dry-run" html :test #'char=)
       "Each promotion-plan entry point must link to DMX dry-run evidence"))
    (assert-true
     (search (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective-plan)
             collective-topic-page-html
             :test #'char=)
     "Collective knowledge topic-page entry point must name the correct plan id")
    (assert-true
     (search (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro-plan)
             repro-topic-page-html
             :test #'char=)
     "Second real-page topic-page entry point must name the correct plan id")
    (assert-true
     (search (hyperdoc::localhost-fedwiki-page-promotion-plan-source-page-id
              collective-plan)
             collective-source-html
             :test #'char=)
     "Collective knowledge source entry point must preserve the canonical source page id")
    (assert-true
     (search (hyperdoc::localhost-fedwiki-page-promotion-plan-source-page-id
              repro-plan)
             repro-source-html
             :test #'char=)
     "Second real-page source entry point must preserve the canonical source page id")))

(defun run-localhost-fedwiki-page-promotion-operations-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((collective (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan))
         (repro (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
         (collective-views (load-inspector-views-for-object collective))
         (repro-views (load-inspector-views-for-object repro))
         (collective-overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "Overview")))
         (repro-overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Overview")))
         (collective-operations-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views
                                      "<span style=\"color: #666;\">Operations</span>")))
         (repro-operations-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views
                                      "<span style=\"color: #666;\">Operations</span>")))
         (collective-page-path
           (hyperdoc::localhost-fedwiki-page-promotion-plan-composed-page-pathname
            collective))
         (collective-snippet-path
           (hyperdoc::localhost-fedwiki-page-promotion-plan-topic-snippet-pathname
            collective))
         (repro-page-path
           (hyperdoc::localhost-fedwiki-page-promotion-plan-composed-page-pathname
            repro))
         (repro-snippet-path
           (hyperdoc::localhost-fedwiki-page-promotion-plan-topic-snippet-pathname
            repro))
         (collective-page-before (uiop:read-file-string collective-page-path))
         (collective-snippet-before (uiop:read-file-string collective-snippet-path))
         (repro-page-before (uiop:read-file-string repro-page-path))
         (repro-snippet-before (uiop:read-file-string repro-snippet-path))
         (collective-page-result
           (hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
            collective))
         (repro-snippet-result
           (hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-snippet-artifact
            repro))
         (collective-both-result
           (hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-artifacts
            collective))
         (repro-both-result
           (hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-artifacts
            repro))
         (collective-dmx-review
           (hyperdoc::review-localhost-fedwiki-page-promotion-plan-dmx-dry-run
            collective))
         (repro-dmx-review
           (hyperdoc::review-localhost-fedwiki-page-promotion-plan-dmx-dry-run
            repro))
         (collective-freshness-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "Source freshness")))
         (repro-freshness-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Source freshness")))
         (collective-status
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            collective))
         (repro-status
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            repro))
         (collective-page-rest
           (strip-artifact-envelope-line collective-page-before))
         (collective-snippet-rest
           (strip-artifact-envelope-line collective-snippet-before))
         (missing-envelope-status
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            collective
            :page-contents collective-page-rest
            :snippet-contents collective-snippet-rest))
         (malformed-envelope-status
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            collective
            :page-contents
            (malformed-html-envelope-contents collective-page-rest)
            :snippet-contents
            (malformed-snippet-envelope-contents collective-snippet-rest)))
         (collective-dmx-string (prin1-to-string collective-dmx-review))
         (repro-dmx-string (prin1-to-string repro-dmx-review))
         (simulated-out-of-sync
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            collective
            :page-contents "out-of-sync page"
            :snippet-contents "out-of-sync snippet"))
         (simulated-stale-source
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            collective
            :current-source-snapshot
            (hyperdoc::plist-with-overrides
             (getf collective-status :current-source-snapshot)
             :fingerprint "fnv1a64:SIMULATEDSTALE"
             :summary "story-items=simulated; source snapshot intentionally stale for smoke coverage")))
         (collective-page-fresh-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :page
            collective-status))
         (collective-snippet-fresh-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :snippet
            collective-status))
         (stale-page-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :page
            simulated-stale-source))
         (stale-snippet-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :snippet
            simulated-stale-source))
         (missing-page-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :page
            missing-envelope-status))
         (missing-snippet-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :snippet
            missing-envelope-status))
         (malformed-page-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :page
            malformed-envelope-status))
         (malformed-snippet-affordance
           (hyperdoc::promotion-source-freshness-affordance-spec
            :snippet
            malformed-envelope-status)))
    (dolist (html (list collective-overview-html
                        repro-overview-html))
      (assert-true
       (search "Status and actions" html :test #'char=)
       "Overview must keep the compact status-and-actions section")
      (assert-true
       (search "Regenerate both artifacts" html :test #'char=)
       "Overview must present human-facing regeneration actions")
      (assert-true
       (search "Review DMX dry-run" html :test #'char=)
       "Overview must present the human-facing DMX dry-run review action")
      (assert-true
       (search "Inspect sync status" html :test #'char=)
       "Overview must present the human-facing sync-status action"))
    (assert-true
     (getf collective-status :page-source-fresh)
     "Collective knowledge page artifact must be fresh relative to the current source snapshot")
    (assert-equal
     :present
     (getf collective-status :page-reflected-snapshot-status)
     "Collective knowledge page artifact must reflect a valid source snapshot envelope")
    (assert-equal
     :present
     (getf collective-status :snippet-reflected-snapshot-status)
     "Collective knowledge snippet artifact must reflect a valid source snapshot envelope")
    (assert-true
     (getf collective-status :page-reflected-snapshot-present)
     "Collective knowledge page artifact must report the reflected snapshot as present")
    (assert-true
     (not (getf collective-status :page-reflected-snapshot-malformed))
     "Collective knowledge page artifact must not report a malformed reflected snapshot")
    (assert-true
     (getf collective-status :snippet-reflected-snapshot-present)
     "Collective knowledge snippet artifact must report the reflected snapshot as present")
    (assert-true
     (not (getf collective-status :snippet-reflected-snapshot-malformed))
     "Collective knowledge snippet artifact must not report a malformed reflected snapshot")
    (assert-equal
     :fresh
     (getf collective-status :page-source-freshness-state)
     "Collective knowledge page artifact must classify source freshness as fresh when the envelope matches")
    (assert-equal
     (getf collective-status :current-source-fingerprint)
     (getf collective-status :page-reflected-snapshot-fingerprint)
     "Collective knowledge page artifact must align the current and reflected fingerprints in the no-change case")
    (assert-equal
     (getf collective-status :current-source-fingerprint)
     (getf collective-status :snippet-reflected-snapshot-fingerprint)
     "Collective knowledge snippet artifact must align the current and reflected fingerprints in the no-change case")
    (assert-true
     (search "matches reflected snapshot fingerprint"
             (or (getf collective-status :page-source-freshness-reason) "")
             :test #'char=)
     "Collective knowledge page artifact must explain the fresh result with an alignment reason")
    (assert-equal
     :no-regeneration-needed
     (getf collective-status :page-source-freshness-recommended-action)
     "Collective knowledge page artifact must recommend no regeneration in the no-change case")
    (assert-equal
     nil
     (getf collective-status :page-source-freshness-recommended-operation)
     "Collective knowledge page artifact must not expose a mutating recommended operation in the no-change case")
    (assert-equal
     "No regeneration needed; the page artifact already reflects the current source snapshot."
     (getf collective-status :page-source-freshness-recommended-action-label)
     "Collective knowledge page artifact must expose the no-change page recommendation")
    (assert-equal
     :fresh
     (getf collective-status :snippet-source-freshness-state)
     "Collective knowledge snippet artifact must classify source freshness as fresh when the envelope matches")
    (assert-equal
     :no-regeneration-needed
     (getf collective-status :snippet-source-freshness-recommended-action)
     "Collective knowledge snippet artifact must recommend no regeneration in the no-change case")
    (assert-equal
     nil
     (getf collective-status :snippet-source-freshness-recommended-operation)
     "Collective knowledge snippet artifact must not expose a mutating recommended operation in the no-change case")
    (assert-equal
     "No regeneration needed; the snippet artifact already reflects the current source snapshot."
     (getf collective-status :snippet-source-freshness-recommended-action-label)
     "Collective knowledge snippet artifact must expose the no-change snippet recommendation")
    (assert-true
     (getf collective-status :page-source-freshness-known)
     "Collective knowledge page artifact must report source freshness as known when the envelope is valid")
    (assert-true
     (getf collective-status :snippet-source-freshness-known)
     "Collective knowledge snippet artifact must report source freshness as known when the envelope is valid")
    (assert-true
     (getf collective-status :snippet-source-fresh)
     "Collective knowledge snippet artifact must be fresh relative to the current source snapshot")
    (assert-true
     (getf repro-status :page-source-fresh)
     "Second real-page artifact must be fresh relative to the current source snapshot")
    (assert-equal
     :present
     (getf repro-status :page-reflected-snapshot-status)
     "Second real-page artifact must reflect a valid source snapshot envelope")
    (assert-equal
     :present
     (getf repro-status :snippet-reflected-snapshot-status)
     "Second real-page snippet must reflect a valid source snapshot envelope")
    (assert-equal
     :fresh
     (getf repro-status :page-source-freshness-state)
     "Second real-page artifact must classify source freshness as fresh when the envelope matches")
    (assert-equal
     (getf repro-status :current-source-fingerprint)
     (getf repro-status :page-reflected-snapshot-fingerprint)
     "Second real-page artifact must align the current and reflected fingerprints in the no-change case")
    (assert-equal
     (getf repro-status :current-source-fingerprint)
     (getf repro-status :snippet-reflected-snapshot-fingerprint)
     "Second real-page snippet must align the current and reflected fingerprints in the no-change case")
    (assert-true
     (search "matches reflected snapshot fingerprint"
             (or (getf repro-status :page-source-freshness-reason) "")
             :test #'char=)
     "Second real-page artifact must explain the fresh result with an alignment reason")
    (assert-equal
     :no-regeneration-needed
     (getf repro-status :page-source-freshness-recommended-action)
     "Second real-page artifact must recommend no regeneration in the no-change case")
    (assert-equal
     nil
     (getf repro-status :page-source-freshness-recommended-operation)
     "Second real-page artifact must not expose a mutating recommended operation in the no-change case")
    (assert-equal
     "No regeneration needed; the page artifact already reflects the current source snapshot."
     (getf repro-status :page-source-freshness-recommended-action-label)
     "Second real-page artifact must expose the no-change page recommendation")
    (assert-equal
     :fresh
     (getf repro-status :snippet-source-freshness-state)
     "Second real-page snippet must classify source freshness as fresh when the envelope matches")
    (assert-equal
     :no-regeneration-needed
     (getf repro-status :snippet-source-freshness-recommended-action)
     "Second real-page snippet must recommend no regeneration in the no-change case")
    (assert-equal
     nil
     (getf repro-status :snippet-source-freshness-recommended-operation)
     "Second real-page snippet must not expose a mutating recommended operation in the no-change case")
    (assert-equal
     "No regeneration needed; the snippet artifact already reflects the current source snapshot."
     (getf repro-status :snippet-source-freshness-recommended-action-label)
     "Second real-page snippet must expose the no-change snippet recommendation")
    (assert-true
     (getf repro-status :page-source-freshness-known)
     "Second real-page artifact must report source freshness as known when the envelope is valid")
    (assert-true
     (getf repro-status :snippet-source-freshness-known)
     "Second real-page snippet must report source freshness as known when the envelope is valid")
    (assert-true
     (getf repro-status :snippet-source-fresh)
     "Second real-page snippet must be fresh relative to the current source snapshot")
    (assert-true
     (search "fnv1a64:" (or (getf collective-status :current-source-fingerprint) "")
             :test #'char-equal)
     "Collective knowledge status must expose the normalized source fingerprint")
    (assert-true
     (search "fnv1a64:" (or (getf repro-status :current-source-fingerprint) "")
             :test #'char-equal)
     "Second real-page status must expose the normalized source fingerprint")
    (dolist (html (list collective-operations-html repro-operations-html))
      (assert-true
       (search "REGENERATE-LOCALHOST-FEDWIKI-PAGE-PROMOTION-PLAN-PAGE-ARTIFACT"
               html
               :test #'char-equal)
       "Operations view must expose page-artifact regeneration")
      (assert-true
       (search "REGENERATE-LOCALHOST-FEDWIKI-PAGE-PROMOTION-PLAN-SNIPPET-ARTIFACT"
               html
               :test #'char-equal)
       "Operations view must expose snippet-artifact regeneration")
      (assert-true
       (search "REGENERATE-LOCALHOST-FEDWIKI-PAGE-PROMOTION-PLAN-ARTIFACTS"
               html
               :test #'char-equal)
       "Operations view must expose combined artifact regeneration")
      (assert-true
       (search "LOCALHOST-FEDWIKI-PAGE-PROMOTION-PLAN-SYNC-STATUS"
               html
               :test #'char-equal)
       "Operations view must expose sync-status reporting")
      (assert-true
       (search "REVIEW-LOCALHOST-FEDWIKI-PAGE-PROMOTION-PLAN-DMX-DRY-RUN"
               html
               :test #'char-equal)
       "Operations view must expose DMX dry-run review"))
    (assert-equal :page-artifact-regenerated
                  (getf collective-page-result :action)
                  "Page regeneration must report the correct action")
    (assert-equal :snippet-artifact-regenerated
                  (getf repro-snippet-result :action)
                  "Snippet regeneration must report the correct action")
    (assert-equal :all-artifacts-regenerated
                  (getf collective-both-result :action)
                  "Combined regeneration must report the correct action")
    (assert-equal :all-artifacts-regenerated
                  (getf repro-both-result :action)
                  "Combined regeneration must report the correct action for the second real page")
    (assert-true
     (getf collective-both-result :page-synced)
     "Collective knowledge artifacts must remain page-synced after regeneration")
    (assert-true
     (getf collective-both-result :snippet-synced)
     "Collective knowledge artifacts must remain snippet-synced after regeneration")
    (assert-true
     (getf repro-both-result :page-synced)
     "Second real-page artifacts must remain page-synced after regeneration")
    (assert-true
     (getf repro-both-result :snippet-synced)
     "Second real-page artifacts must remain snippet-synced after regeneration")
    (assert-equal collective-page-before
                  (uiop:read-file-string collective-page-path)
                  "Collective knowledge page bytes must stay stable after regeneration")
    (assert-equal collective-snippet-before
                  (uiop:read-file-string collective-snippet-path)
                  "Collective knowledge snippet bytes must stay stable after regeneration")
    (assert-equal repro-page-before
                  (uiop:read-file-string repro-page-path)
                  "Second real-page bytes must stay stable after regeneration")
    (assert-equal repro-snippet-before
                  (uiop:read-file-string repro-snippet-path)
                  "Second real-page snippet bytes must stay stable after regeneration")
    (assert-true (not (getf simulated-out-of-sync :page-synced))
                 "Test seam must surface out-of-sync page status")
    (assert-true (not (getf simulated-out-of-sync :snippet-synced))
                 "Test seam must surface out-of-sync snippet status")
    (assert-true
     (not (getf missing-envelope-status :page-reflected-snapshot-present))
     "Missing page envelopes must fail soft by reporting no reflected snapshot")
    (assert-true
     (not (getf missing-envelope-status :page-reflected-snapshot-malformed))
     "Missing page envelopes must not be misclassified as malformed")
    (assert-true
     (not (getf missing-envelope-status :page-source-freshness-known))
     "Missing page envelopes must classify source freshness as unknown")
    (assert-equal
     :unknown-missing-envelope
     (getf missing-envelope-status :page-source-freshness-state)
     "Missing page envelopes must classify source freshness as unknown because the envelope is missing")
    (assert-equal
     :missing-envelope
     (getf missing-envelope-status :page-source-freshness-unknown-reason)
     "Missing page envelopes must preserve the explicit unknown reason")
    (assert-equal
     "Reflected source snapshot envelope is missing."
     (getf missing-envelope-status :page-source-freshness-reason)
     "Missing page envelopes must keep a human-facing diagnostic reason")
    (assert-equal
     :regenerate-artifact
     (getf missing-envelope-status :page-source-freshness-recommended-action)
     "Missing page envelopes must recommend regeneration")
    (assert-equal
     "Regenerate the page artifact to restore reflected source snapshot evidence."
     (getf missing-envelope-status :page-source-freshness-recommended-action-label)
     "Missing page envelopes must recommend restoring reflected snapshot evidence")
    (assert-equal
     'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
     (getf missing-envelope-status :page-source-freshness-recommended-operation)
     "Missing page envelopes must map to the existing page-regeneration operation")
    (assert-true
     (not (getf missing-envelope-status :snippet-reflected-snapshot-present))
     "Missing snippet envelopes must fail soft by reporting no reflected snapshot")
    (assert-true
     (not (getf missing-envelope-status :snippet-reflected-snapshot-malformed))
     "Missing snippet envelopes must not be misclassified as malformed")
    (assert-true
     (not (getf missing-envelope-status :snippet-source-freshness-known))
     "Missing snippet envelopes must classify source freshness as unknown")
    (assert-equal
     :unknown-missing-envelope
     (getf missing-envelope-status :snippet-source-freshness-state)
     "Missing snippet envelopes must classify source freshness as unknown because the envelope is missing")
    (assert-equal
     :missing-envelope
     (getf missing-envelope-status :snippet-source-freshness-unknown-reason)
     "Missing snippet envelopes must preserve the explicit unknown reason")
    (assert-equal
     "Reflected source snapshot envelope is missing."
     (getf missing-envelope-status :snippet-source-freshness-reason)
     "Missing snippet envelopes must keep a human-facing diagnostic reason")
    (assert-equal
     :regenerate-artifact
     (getf missing-envelope-status :snippet-source-freshness-recommended-action)
     "Missing snippet envelopes must recommend regeneration")
    (assert-equal
     "Regenerate the snippet artifact to restore reflected source snapshot evidence."
     (getf missing-envelope-status :snippet-source-freshness-recommended-action-label)
     "Missing snippet envelopes must recommend restoring reflected snapshot evidence")
    (assert-equal
     'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-snippet-artifact
     (getf missing-envelope-status :snippet-source-freshness-recommended-operation)
     "Missing snippet envelopes must map to the existing snippet-regeneration operation")
    (assert-true
     (not (getf malformed-envelope-status :page-reflected-snapshot-present))
     "Malformed page envelopes must fail soft by reporting no valid reflected snapshot")
    (assert-true
     (getf malformed-envelope-status :page-reflected-snapshot-malformed)
     "Malformed page envelopes must preserve the malformed classification")
    (assert-true
     (not (getf malformed-envelope-status :page-source-freshness-known))
     "Malformed page envelopes must classify source freshness as unknown")
    (assert-equal
     :unknown-malformed-envelope
     (getf malformed-envelope-status :page-source-freshness-state)
     "Malformed page envelopes must classify source freshness as unknown because the envelope is malformed")
    (assert-equal
     :malformed-envelope
     (getf malformed-envelope-status :page-source-freshness-unknown-reason)
     "Malformed page envelopes must preserve the explicit malformed reason")
    (assert-true
     (search "malformed"
             (or (getf malformed-envelope-status :page-source-freshness-reason) "")
             :test #'char-equal)
     "Malformed page envelopes must keep a human-facing diagnostic reason")
    (assert-equal
     :regenerate-artifact
     (getf malformed-envelope-status :page-source-freshness-recommended-action)
     "Malformed page envelopes must recommend regeneration")
    (assert-equal
     "Regenerate the page artifact to repair reflected source snapshot evidence."
     (getf malformed-envelope-status :page-source-freshness-recommended-action-label)
     "Malformed page envelopes must recommend repairing reflected snapshot evidence")
    (assert-equal
     'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
     (getf malformed-envelope-status :page-source-freshness-recommended-operation)
     "Malformed page envelopes must map to the existing page-regeneration operation")
    (assert-true
     (not (getf malformed-envelope-status :snippet-reflected-snapshot-present))
     "Malformed snippet envelopes must fail soft by reporting no valid reflected snapshot")
    (assert-true
     (getf malformed-envelope-status :snippet-reflected-snapshot-malformed)
     "Malformed snippet envelopes must preserve the malformed classification")
    (assert-true
     (not (getf malformed-envelope-status :snippet-source-freshness-known))
     "Malformed snippet envelopes must classify source freshness as unknown")
    (assert-equal
     :unknown-malformed-envelope
     (getf malformed-envelope-status :snippet-source-freshness-state)
     "Malformed snippet envelopes must classify source freshness as unknown because the envelope is malformed")
    (assert-equal
     :malformed-envelope
     (getf malformed-envelope-status :snippet-source-freshness-unknown-reason)
     "Malformed snippet envelopes must preserve the explicit malformed reason")
    (assert-true
     (search "malformed"
             (or (getf malformed-envelope-status :snippet-source-freshness-reason) "")
             :test #'char-equal)
     "Malformed snippet envelopes must keep a human-facing diagnostic reason")
    (assert-equal
     :regenerate-artifact
     (getf malformed-envelope-status :snippet-source-freshness-recommended-action)
     "Malformed snippet envelopes must recommend regeneration")
    (assert-equal
     "Regenerate the snippet artifact to repair reflected source snapshot evidence."
     (getf malformed-envelope-status :snippet-source-freshness-recommended-action-label)
     "Malformed snippet envelopes must recommend repairing reflected snapshot evidence")
    (assert-equal
     'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-snippet-artifact
     (getf malformed-envelope-status :snippet-source-freshness-recommended-operation)
     "Malformed snippet envelopes must map to the existing snippet-regeneration operation")
    (assert-true
     (getf simulated-stale-source :page-synced)
     "Stale-source simulation must not require mutating the page artifact bytes")
    (assert-true
     (getf simulated-stale-source :snippet-synced)
     "Stale-source simulation must not require mutating the snippet artifact bytes")
    (assert-true
     (not (getf simulated-stale-source :page-source-fresh))
     "Test seam must surface stale page-source freshness without mutating the real FedWiki page")
    (assert-equal
     :stale
     (getf simulated-stale-source :page-source-freshness-state)
     "Stale-source simulation must classify page freshness as stale")
    (assert-true
     (search "differs from reflected snapshot fingerprint"
             (or (getf simulated-stale-source :page-source-freshness-reason) "")
             :test #'char=)
     "Stale-source simulation must explain the page mismatch with a fingerprint-difference reason")
    (assert-true
     (search "fnv1a64:SIMULATEDSTALE"
             (or (getf simulated-stale-source :page-source-freshness-reason) "")
             :test #'char-equal)
     "Stale-source simulation must expose the simulated current fingerprint in the page mismatch reason")
    (assert-equal
     :regenerate-artifact
     (getf simulated-stale-source :page-source-freshness-recommended-action)
     "Stale-source simulation must recommend page regeneration")
    (assert-equal
     "Regenerate the page artifact to refresh its reflected source snapshot evidence."
     (getf simulated-stale-source :page-source-freshness-recommended-action-label)
     "Stale-source simulation must recommend refreshing the page artifact evidence")
    (assert-equal
     'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
     (getf simulated-stale-source :page-source-freshness-recommended-operation)
     "Stale-source simulation must map to the existing page-regeneration operation")
    (assert-equal
     (getf collective-status :page-reflected-snapshot-fingerprint)
     (getf simulated-stale-source :page-reflected-snapshot-fingerprint)
     "Stale-source simulation must preserve the reflected page fingerprint for comparison")
    (assert-true
     (not (getf simulated-stale-source :snippet-source-fresh))
     "Test seam must surface stale snippet-source freshness without mutating the real FedWiki page")
    (assert-equal
     :stale
     (getf simulated-stale-source :snippet-source-freshness-state)
     "Stale-source simulation must classify snippet freshness as stale")
    (assert-true
     (search "differs from reflected snapshot fingerprint"
             (or (getf simulated-stale-source :snippet-source-freshness-reason) "")
             :test #'char=)
     "Stale-source simulation must explain the snippet mismatch with a fingerprint-difference reason")
    (assert-equal
     :regenerate-artifact
     (getf simulated-stale-source :snippet-source-freshness-recommended-action)
     "Stale-source simulation must recommend snippet regeneration")
    (assert-equal
     "Regenerate the snippet artifact to refresh its reflected source snapshot evidence."
     (getf simulated-stale-source :snippet-source-freshness-recommended-action-label)
     "Stale-source simulation must recommend refreshing the snippet artifact evidence")
    (assert-equal
     'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-snippet-artifact
     (getf simulated-stale-source :snippet-source-freshness-recommended-operation)
     "Stale-source simulation must map to the existing snippet-regeneration operation")
    (assert-equal
     :passive
     (getf collective-page-fresh-affordance :kind)
     "Fresh page status must render a passive affordance")
    (assert-equal
     "No action needed"
     (getf collective-page-fresh-affordance :label)
     "Fresh page status must render a no-action-needed affordance")
    (assert-equal
     nil
     (getf collective-page-fresh-affordance :operation)
     "Fresh page status must not surface a mutating affordance")
    (assert-equal
     :passive
     (getf collective-snippet-fresh-affordance :kind)
     "Fresh snippet status must render a passive affordance")
    (assert-equal
     :action
     (getf stale-page-affordance :kind)
     "Stale page status must render an action affordance")
    (assert-equal
     "Regenerate page artifact"
     (getf stale-page-affordance :label)
     "Stale page status must surface the regenerate affordance")
    (assert-equal
     'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
     (getf stale-page-affordance :operation)
     "Stale page affordance must resolve to the existing page-regeneration operation")
    (assert-equal
     :action
     (getf stale-snippet-affordance :kind)
     "Stale snippet status must render an action affordance")
    (assert-equal
     "Regenerate snippet artifact"
     (getf stale-snippet-affordance :label)
     "Stale snippet status must surface the regenerate affordance")
    (assert-equal
     :action
     (getf missing-page-affordance :kind)
     "Missing page-envelope status must render an action affordance")
    (assert-equal
     "Restore page snapshot evidence"
     (getf missing-page-affordance :label)
     "Missing page-envelope status must surface the restore affordance")
    (assert-equal
     :action
     (getf missing-snippet-affordance :kind)
     "Missing snippet-envelope status must render an action affordance")
    (assert-equal
     "Restore snippet snapshot evidence"
     (getf missing-snippet-affordance :label)
     "Missing snippet-envelope status must surface the restore affordance")
    (assert-equal
     :action
     (getf malformed-page-affordance :kind)
     "Malformed page-envelope status must render an action affordance")
    (assert-equal
     "Repair page snapshot evidence"
     (getf malformed-page-affordance :label)
     "Malformed page-envelope status must surface the repair affordance")
    (assert-equal
     :action
     (getf malformed-snippet-affordance :kind)
     "Malformed snippet-envelope status must render an action affordance")
    (assert-equal
     "Repair snippet snapshot evidence"
     (getf malformed-snippet-affordance :label)
     "Malformed snippet-envelope status must surface the repair affordance")
    (assert-equal
     (getf collective-status :snippet-reflected-snapshot-fingerprint)
     (getf simulated-stale-source :snippet-reflected-snapshot-fingerprint)
     "Stale-source simulation must preserve the reflected snippet fingerprint for comparison")
    (assert-true
     (search "Reflected snapshot fingerprint" collective-freshness-html :test #'char=)
     "Collective knowledge source freshness view must expose reflected snapshot fingerprint diagnostics")
    (assert-true
     (search "Reflected snapshot fingerprint" repro-freshness-html :test #'char=)
     "Second real-page source freshness view must expose reflected snapshot fingerprint diagnostics")
    (assert-true
     (search "Freshness result" collective-freshness-html :test #'char=)
     "Collective knowledge source freshness view must expose freshness result diagnostics")
    (assert-true
     (search "Freshness result" repro-freshness-html :test #'char=)
     "Second real-page source freshness view must expose freshness result diagnostics")
    (assert-true
     (search "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"
             collective-dmx-string
             :test #'char=)
     "DMX dry-run review must keep canonical source ids for collective knowledge")
    (assert-true
     (search "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact"
             repro-dmx-string
             :test #'char=)
     "DMX dry-run review must keep canonical source ids for the second real page")
    (assert-true
     (not (search "/Users/" collective-dmx-string :test #'char=))
     "DMX dry-run review must not leak absolute paths for collective knowledge")
    (assert-true
     (not (search "/Users/" repro-dmx-string :test #'char=))
     "DMX dry-run review must not leak absolute paths for the second real page")))

(defun run-localhost-fedwiki-page-promotion-page-and-topic-smoke-test ()
  (let ((workflow-page-source
          (uiop:read-file-string
           (localhost-fedwiki-page-promotion-workflow-relative-path))))
    (assert-true
     (fboundp 'hyperdoc::localhost-fedwiki-page-promotion-workflow-topic)
     "Workflow topic function must be present")
    (assert-true
     (hyperbook:find-page hyperdoc::*topics*
                          "Localhost FedWiki page promotion workflow"
                          :signal-error? t)
     "Workflow topic page must be browseable in Topics")
    (assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc*
                          "Localhost FedWiki page promotion workflow"
                          :signal-error? t)
     "Workflow HyperDoc page must be browseable")
    (assert-true
     (search "the-life-cycle-of-collective-knowledge-promotion-plan"
             workflow-page-source
             :test #'char=)
     "Workflow page must link to the collective knowledge promotion plan object")
    (assert-true
     (search "reproducible-devenv-as-knowledge-artifact-promotion-plan"
             workflow-page-source
             :test #'char=)
     "Workflow page must link to the second real-page promotion plan object")
    (assert-true
     (search "write-localhost-fedwiki-page-promotion-plan-artifacts"
             workflow-page-source
             :test #'char=)
     "Workflow page must document the explicit local artifact write boundary")
    (assert-true
     (search "execute-topic-factory-snippet-dmx-write ... :dry-run nil"
             workflow-page-source
             :test #'char=)
     "Workflow page must keep the optional live DMX write boundary explicit and separate")))

(defun run-localhost-fedwiki-page-promotion-output-sync-smoke-test ()
  (let ((collective (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan))
        (repro (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan)))
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-page-output-synced-p collective)
     "Collective knowledge page output must stay synced with the current artifact rendering")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-output-synced-p collective)
     "Collective knowledge snippet output must stay synced with the current artifact rendering")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-page-output-synced-p repro)
     "Second real-page output must stay synced with the current artifact rendering")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-output-synced-p repro)
     "Second real-page snippet output must stay synced with the current artifact rendering")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-page-source-fresh-p collective)
     "Collective knowledge page output must stay fresh relative to the current source snapshot")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-source-fresh-p collective)
     "Collective knowledge snippet output must stay fresh relative to the current source snapshot")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-page-source-fresh-p repro)
     "Second real-page output must stay fresh relative to the current source snapshot")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-source-fresh-p repro)
     "Second real-page snippet output must stay fresh relative to the current source snapshot")))

(defun run-localhost-fedwiki-page-promotion-plans-smoke-tests ()
  (run-localhost-fedwiki-page-promotion-plan-view-smoke-test)
  (run-localhost-fedwiki-page-promotion-entry-point-smoke-test)
  (run-localhost-fedwiki-page-promotion-operations-smoke-test)
  (run-localhost-fedwiki-page-promotion-page-and-topic-smoke-test)
  (run-localhost-fedwiki-page-promotion-output-sync-smoke-test)
  (format t "~&Localhost FedWiki page promotion plan smoke tests passed.~%")
  t)
