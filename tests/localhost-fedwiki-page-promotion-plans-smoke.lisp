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
     (search "story-item" repro-promoted-html :test #'char=)
     "Second real page promoted-topics view must expose whole-item-derived subtopics")
    (assert-true
     (search "multi-item-derived" repro-promoted-html :test #'char=)
     "Second real page promoted-topics view must expose the multi-item-derived umbrella provenance")
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
  (run-localhost-fedwiki-page-promotion-page-and-topic-smoke-test)
  (run-localhost-fedwiki-page-promotion-output-sync-smoke-test)
  (format t "~&Localhost FedWiki page promotion plan smoke tests passed.~%")
  t)
