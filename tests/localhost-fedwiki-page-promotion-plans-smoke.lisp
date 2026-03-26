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
         (repro-overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Overview")))
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
     (search "story-item-fragment" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose fragment-based provenance modes")
    (assert-true
     (search "DMX dry-run summary available" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose DMX dry-run summary availability")
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
     (search "multi-item-derived" repro-overview-html :test #'char=)
     "Second real-page overview must expose multi-item provenance modes")
    (assert-true
     (search "DMX dry-run summary available" repro-overview-html :test #'char=)
     "Second real-page overview must expose DMX dry-run summary availability")
    (dolist (label '("Regenerate page artifact"
                     "Regenerate snippet artifact"
                     "Regenerate both artifacts"
                     "Review DMX dry-run"
                     "Inspect sync status"))
      (assert-true
       (search label repro-overview-html :test #'char=)
       (format nil "Second real-page overview must expose the human-facing action label ~A" label)))
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
         (collective-dmx-string (prin1-to-string collective-dmx-review))
         (repro-dmx-string (prin1-to-string repro-dmx-review))
         (simulated-out-of-sync
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            collective
            :page-contents "out-of-sync page"
            :snippet-contents "out-of-sync snippet")))
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
     "Collective knowledge page output must stay unchanged after adding inspectable plans")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-output-synced-p collective)
     "Collective knowledge snippet output must stay unchanged after adding inspectable plans")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-page-output-synced-p repro)
     "Second real-page output must stay unchanged after adding inspectable plans")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-output-synced-p repro)
     "Second real-page snippet output must stay unchanged after adding inspectable plans")))

(defun run-localhost-fedwiki-page-promotion-plans-smoke-tests ()
  (run-localhost-fedwiki-page-promotion-plan-view-smoke-test)
  (run-localhost-fedwiki-page-promotion-entry-point-smoke-test)
  (run-localhost-fedwiki-page-promotion-operations-smoke-test)
  (run-localhost-fedwiki-page-promotion-page-and-topic-smoke-test)
  (run-localhost-fedwiki-page-promotion-output-sync-smoke-test)
  (format t "~&Localhost FedWiki page promotion plan smoke tests passed.~%")
  t)
