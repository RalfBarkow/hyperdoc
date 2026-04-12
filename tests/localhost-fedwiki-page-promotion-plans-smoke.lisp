;;;; Smoke tests for inspectable localhost FedWiki page promotion plans
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-LOCALHOST-FIRST-FEDWIKI-PUBLICATION-PLAN-SMOKE-TEST"
                        :hyperdoc/tests)
                (intern "RUN-LOCALHOST-FIRST-FEDWIKI-LIVE-PUBLICATION-SMOKE-TEST"
                        :hyperdoc/tests)
                (intern "RUN-LOCALHOST-FEDWIKI-PAGE-PROMOTION-PLANS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun localhost-fedwiki-page-promotion-workflow-relative-path ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/Localhost FedWiki page promotion workflow.html"))

(defun dmx-topicmap-919822-repair-runbook-relative-path ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/DMX topicmap 919822 repair runbook.html"))

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

(defun call-with-simulated-missing-reproducible-devenv-source (thunk)
  (let* ((symbol
           'hyperdoc::reproducible-devenv-as-knowledge-artifact-page-pipeline-spec)
         (original (symbol-function symbol))
         (missing-path
           (merge-pathnames
            (format nil "hyperdoc-missing-fedwiki-page-~A.json"
                    (gensym "REPRO-"))
            (uiop:temporary-directory))))
    (unwind-protect
        (progn
          (setf (symbol-function symbol)
                (lambda ()
                  (let ((spec (funcall original)))
                    (setf (hyperdoc::localhost-fedwiki-page-pipeline-spec-page-reader
                           spec)
                          (lambda ()
                            (hyperdoc::article-allegation-read-json-file
                             missing-path)))
                    spec)))
          (funcall thunk))
      (setf (symbol-function symbol) original))))

(defun real-localhost-fedwiki-page-promotion-plans ()
  (list (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan)
        (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan)))

(defun first-healthy-real-localhost-fedwiki-page-promotion-plan ()
  (find-if (lambda (plan)
             (null (hyperdoc::localhost-fedwiki-page-promotion-plan-source-issue
                    plan)))
           (real-localhost-fedwiki-page-promotion-plans)))

(defun publication-plan-test-copy-page (page)
  (copy-tree page))

(defun publication-plan-test-stale-target-page (page)
  (let ((page (publication-plan-test-copy-page page)))
    (setf (getf (second (getf page :story)) :text)
          "Link environment topics after publication so the remote copy catches up later.")
    (setf (getf page :journal)
          (butlast (copy-list (getf page :journal))))
    page))

(defun publication-plan-test-divergent-target-page (page)
  (let ((page (publication-plan-test-copy-page page)))
    (setf (getf page :title)
          "Reproducible DevEnv as Published Elsewhere")
    page))

(defun localhost-fedwiki-live-publication-smoke-root ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    "localhost-fedwiki-live-publication-smoke/"
    (uiop:temporary-directory))))

(defun run-localhost-first-fedwiki-publication-plan-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((seed-plan
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-localhost-first-publication-plan
            :target-page-reader
            (lambda (plan)
              (declare (ignore plan))
              (list :state :missing
                    :protocol "https"
                    :message "Seed reader for local-page discovery only."))))
         (local-state
           (hyperdoc::localhost-fedwiki-page-publication-plan-local-page-state
            seed-plan))
         (local-page (getf local-state :page))
         (remote-state
           (list :state :present
                 :protocol "https"
                 :page (publication-plan-test-stale-target-page local-page)))
         (plan
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-localhost-first-publication-plan
            :live-publication-writer nil
            :target-page-reader
            (lambda (ignored-plan)
              (declare (ignore ignored-plan))
              (copy-tree remote-state)))))
    (assert-true (getf local-state :available)
                 "The chosen localhost-first publication target must have a readable local page")
    (assert-true (getf local-state :json-syntax-valid-p)
                 "The chosen localhost-first publication target must pass local JSON syntax preflight")
    (assert-true (getf local-state :journal-valid-p)
                 "The chosen localhost-first publication target must pass the local journal gate before publication is considered")
    (let* ((summary
             (hyperdoc::localhost-fedwiki-page-publication-plan-dry-run-summary
              plan))
           (review
             (hyperdoc::review-localhost-fedwiki-page-publication-plan-dry-run
              plan))
           (views (load-inspector-views-for-object plan))
           (overview-html
             (html-inspector-views:view-html
              (smoke-find-view-by-title views "Overview")))
           (local-page-html
             (html-inspector-views:view-html
              (smoke-find-view-by-title views "Local page")))
           (target-page-html
             (html-inspector-views:view-html
              (smoke-find-view-by-title views "Target page")))
           (dry-run-html
             (html-inspector-views:view-html
              (smoke-find-view-by-title views "Dry-run")))
           (promotion-plan-overview-html
             (html-inspector-views:view-html
              (smoke-find-view-by-title
               (load-inspector-views-for-object
                (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
               "Overview")))
           (live-error
             (handler-case
                 (progn
                   (hyperdoc::execute-localhost-fedwiki-page-publication-plan-live
                    plan)
                   nil)
               (error (condition)
                 condition))))
      (assert-view-titles-present views
                                  '("Overview"
                                    "Local page"
                                    "Target page"
                                    "Dry-run")
                                  "Localhost-first publication plan")
      (assert-equal
       "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact"
       (getf summary :source-page-id)
       "The localhost-first publication plan must preserve the canonical source page id")
      (assert-equal
       "reproducible-devenv-as-knowledge-artifact"
       (getf summary :source-page-slug)
       "The localhost-first publication plan must preserve the canonical source slug")
      (assert-equal
       "wiki.ralfbarkow.ch"
       (getf summary :target-site)
       "The localhost-first publication plan must preserve the explicit target site")
      (assert-equal
       "reproducible-devenv-as-knowledge-artifact"
       (getf summary :target-slug)
       "The localhost-first publication plan must preserve the explicit target slug")
      (assert-equal
       :stale
       (getf summary :publication-status)
       "A lagging remote page with the same title but different story/journal must classify as stale")
      (assert-equal
       :yes
       (getf summary :target-exists-status)
       "A present remote target must classify as existing")
      (assert-equal
       '(:story :journal)
       (getf summary :divergent-fields)
       "The stale remote state must report story and journal drift without title drift")
      (assert-true
       (getf summary :local-json-syntax-valid-p)
       "The dry-run summary must preserve local JSON syntax preflight")
      (assert-true
       (getf summary :local-journal-valid-p)
       "The dry-run summary must preserve local journal preflight")
      (assert-equal
       :publish-fedwiki-page
       (getf (getf summary :planned-write) :action)
       "A stale remote page must plan a page-scoped publication write")
      (assert-true
       (not (getf summary :live-publication-configured-p))
       "The localhost-first publication plan must keep live publication disabled by default")
      (assert-true
       (search "Review publication plan" promotion-plan-overview-html :test #'char=)
       "The existing promotion plan overview must expose the localhost-first publication-plan handoff")
      (dolist (needle
               '("Publication status"
                 "stale"
                 "wiki.ralfbarkow.ch"
                 "reproducible-devenv-as-knowledge-artifact"
                 "Review publication dry-run"))
        (assert-true
         (search needle overview-html :test #'char-equal)
         (format nil "Publication-plan overview must expose ~A" needle)))
      (dolist (needle
               '("Source page id"
                 "reproducible-devenv-as-knowledge-artifact"
                 "JSON syntax valid"
                 "Journal gate valid"))
        (assert-true
         (search needle local-page-html :test #'char-equal)
         (format nil "Publication-plan local-page view must expose ~A" needle)))
      (dolist (needle
               '("Target site"
                 "wiki.ralfbarkow.ch"
                 "Publication status"
                 "stale"))
        (assert-true
         (search needle target-page-html :test #'char-equal)
         (format nil "Publication-plan target-page view must expose ~A" needle)))
      (dolist (needle
               '("Exact write action"
                 "publish local title/story/journal"
                 "execute-localhost-fedwiki-page-publication-plan-live"
                 "LOCALHOST_FEDWIKI_PUBLICATION_DRY_RUN"
                 "local-journal-gate=pass"))
        (assert-true
         (search needle dry-run-html :test #'char-equal)
         (format nil "Publication-plan dry-run view must expose ~A" needle)))
      (assert-equal
       :stale
       (getf (getf review :summary) :publication-status)
       "The dry-run review result must preserve the stale publication classification")
      (assert-true
       (search "planned-write-action=PUBLISH-FEDWIKI-PAGE"
               (getf review :evidence)
               :test #'char-equal)
       "Dry-run evidence must expose the exact page-scoped publication action")
      (assert-true live-error
                   "The explicit live publication entrypoint must remain present and refuse execution when no page-scoped writer is configured")
      (assert-true
       (search "Live publication is not configured"
               (princ-to-string live-error)
               :test #'char=)
       "The live publication refusal must explain that the writer boundary is still unconfigured"))
    (setf remote-state
          (list :state :present
                :protocol "https"
                :page (publication-plan-test-copy-page local-page)))
    (let* ((summary
             (hyperdoc::localhost-fedwiki-page-publication-plan-dry-run-summary
              plan))
           (overview-html
             (html-inspector-views:view-html
              (smoke-find-view-by-title
               (load-inspector-views-for-object plan)
               "Overview"))))
      (assert-equal
       :current
       (getf summary :publication-status)
       "The same localhost-first publication plan must refresh to current when the remote target matches the local page")
      (assert-equal
       nil
       (getf summary :divergent-fields)
       "A current remote target must clear divergent-field reporting")
      (assert-equal
       :none
       (getf (getf summary :planned-write) :action)
       "A current remote target must suppress publication writes")
      (assert-true
       (search "current" overview-html :test #'char-equal)
       "The refreshed overview must render the current publication state"))
    (setf remote-state
          (list :state :present
                :protocol "https"
                :page (publication-plan-test-divergent-target-page local-page)))
    (let ((summary
            (hyperdoc::localhost-fedwiki-page-publication-plan-dry-run-summary
             plan)))
      (assert-equal
       :divergent
       (getf summary :publication-status)
       "A target title drift on the same slug must classify as divergent rather than merely stale")
      (assert-true
       (member :title (getf summary :divergent-fields))
       "The divergent case must expose title drift explicitly"))
    (setf remote-state
          (list :state :missing
                :protocol "https"
                :message "Target slug is currently missing on the served site."))
    (let ((summary
            (hyperdoc::localhost-fedwiki-page-publication-plan-dry-run-summary
             plan)))
      (assert-equal
       :missing
       (getf summary :publication-status)
       "A missing remote target must classify as missing")
      (assert-equal
       :no
       (getf summary :target-exists-status)
       "A missing remote target must report non-existence explicitly"))))

(defun run-localhost-first-fedwiki-live-publication-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((root (localhost-fedwiki-live-publication-smoke-root))
         (pages-dir (merge-pathnames "pages/" root))
         (target-path
           (merge-pathnames
            "reproducible-devenv-as-knowledge-artifact"
            pages-dir)))
    (when (uiop:directory-exists-p root)
      (uiop:delete-directory-tree root
                                  :validate t
                                  :if-does-not-exist :ignore))
    (ensure-directories-exist pages-dir)
    (let ((hyperdoc::*localhost-fedwiki-page-publication-target-pages-directory-overrides*
            (list (cons "wiki.ralfbarkow.ch" pages-dir))))
      (let* ((plan
               (hyperdoc::reproducible-devenv-as-knowledge-artifact-localhost-first-publication-plan))
             (summary-before
               (hyperdoc::localhost-fedwiki-page-publication-plan-dry-run-summary
                plan))
             (views-before (load-inspector-views-for-object plan))
             (overview-before-html
               (html-inspector-views:view-html
                (smoke-find-view-by-title views-before "Overview")))
             (dry-run-before-html
               (html-inspector-views:view-html
                (smoke-find-view-by-title views-before "Dry-run")))
             (report
               (hyperdoc::execute-localhost-fedwiki-page-publication-plan-live
                plan))
             (written-page
               (hyperdoc::article-allegation-read-json-file target-path))
             (summary-after
               (hyperdoc::localhost-fedwiki-page-publication-plan-dry-run-summary
                plan))
             (views-after (load-inspector-views-for-object plan))
             (overview-after-html
               (html-inspector-views:view-html
                (smoke-find-view-by-title views-after "Overview")))
             (target-page-html
               (html-inspector-views:view-html
                (smoke-find-view-by-title views-after "Target page")))
             (dry-run-after-html
               (html-inspector-views:view-html
                (smoke-find-view-by-title views-after "Dry-run"))))
        (assert-view-titles-present views-before
                                    '("Overview"
                                      "Local page"
                                      "Target page"
                                      "Dry-run")
                                    "Live publication plan")
        (assert-equal
         :missing
         (getf summary-before :publication-status)
         "An empty disposable target page store must classify as missing before live publication")
        (assert-equal
         :no
         (getf summary-before :target-exists-status)
         "The disposable target page store must report no existing page before live publication")
        (assert-true
         (getf summary-before :live-publication-configured-p)
         "The single-page publication plan must attach an explicit live writer by default")
        (assert-equal
         (namestring target-path)
         (getf summary-before :target-page-path)
         "The dry-run summary must expose the exact page-store target path")
        (assert-equal
         :publish-fedwiki-page
         (getf (getf summary-before :planned-write) :action)
         "A missing disposable target must still plan a page-scoped publish action")
        (assert-equal
         (namestring target-path)
         (getf (getf summary-before :planned-write) :target-path)
         "The planned write must preserve the exact target file path")
        (dolist (needle
                 '("Execute live publication"
                   "Target page path"
                   "publish local title/story/journal"))
          (assert-true
           (search needle overview-before-html :test #'char-equal)
           (format nil "Live publication overview must expose ~A" needle)))
        (dolist (needle
                 '("Execute live publication"
                   "LOCALHOST_FEDWIKI_PUBLICATION_DRY_RUN"
                   "target-page-path="))
          (assert-true
           (search needle dry-run-before-html :test #'char-equal)
           (format nil "Live publication dry-run must expose ~A" needle)))
        (assert-equal
         :publish-fedwiki-page
         (getf report :action)
         "The live writer must report a page-scoped publication action")
        (assert-true
         (not (getf report :target-existed-before-p))
         "The disposable target page must start absent before the live write")
        (assert-true
         (getf report :write-succeeded-p)
         "The live writer must report a successful page-scoped write")
        (assert-equal
         '(:title :story :journal)
         (getf report :fields-written)
         "The live writer must report the exact fields it wrote")
        (assert-true
         (getf report :post-write-json-syntax-valid-p)
         "The written disposable target must pass JSON syntax validation")
        (assert-true
         (getf report :post-write-journal-valid-p)
         "The written disposable target must pass the journal gate")
        (assert-equal
         :current
         (getf report :post-write-publication-status)
         "The same publication plan object must refresh to current after the live write")
        (assert-true
         (eq report
             (hyperdoc::localhost-fedwiki-page-publication-plan-last-live-publication-report
              plan))
         "The plan must retain the exact last live publication report for later inspection")
        (assert-true
         (uiop:file-exists-p target-path)
         "The live writer must create the exact target page file in the disposable page store")
        (assert-string=
         "Reproducible DevEnv as Knowledge Artifact"
         (getf written-page :title)
         "The published disposable target must carry the local page title")
        (assert-true
         (hyperdoc::journalmatic-commit-gate-pass-p written-page)
         "The published disposable target must satisfy the journal gate")
        (assert-equal
         :current
         (getf summary-after :publication-status)
         "The same publication plan object must refresh to current after the write")
        (assert-equal
         :yes
         (getf summary-after :target-exists-status)
         "The disposable target page must report existence after the live write")
        (assert-equal
         nil
         (getf summary-after :divergent-fields)
         "The refreshed publication plan must clear drift reporting after the live write")
        (assert-equal
         :none
         (getf (getf summary-after :planned-write) :action)
         "Once the target matches, the same plan must suppress further writes")
        (assert-equal
         (getf summary-after :local-page-fingerprint)
         (getf summary-after :target-page-fingerprint)
         "The refreshed target fingerprint must match the local page fingerprint")
        (dolist (needle
                 '("current"
                   "success (current)"
                   "Target page path"))
          (assert-true
           (search needle overview-after-html :test #'char-equal)
           (format nil "Post-write overview must expose ~A" needle)))
        (dolist (needle
                 '("Target page path"
                   "current"))
          (assert-true
           (search needle target-page-html :test #'char-equal)
           (format nil "Post-write target-page view must expose ~A" needle)))
        (dolist (needle
                 '("Execute live publication"
                   "no write needed"))
          (assert-true
           (search needle dry-run-after-html :test #'char-equal)
           (format nil "Post-write dry-run must expose ~A" needle)))))
    (format t "~&Localhost-first live publication smoke test passed. target=~A~%"
            (namestring target-path))
    t))

(defun run-localhost-fedwiki-page-promotion-plan-view-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((surface (hyperdoc::current-localhost-fedwiki-page-promotion-surface))
         (collective (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan))
         (repro (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
         (surface-views (load-inspector-views-for-object surface))
         (surface-overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "Overview")))
         (surface-triage-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "Triage")))
         (surface-attention-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "Attention needed")))
         (surface-all-fresh-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "All fresh")))
         (surface-source-unavailable-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "Source unavailable")))
         (surface-stale-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "Stale")))
         (surface-missing-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views
                                      "Unknown missing envelope")))
         (surface-malformed-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views
                                      "Unknown malformed envelope")))
         (surface-mixed-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "Mixed states")))
         (surface-handover-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title surface-views "DMX handover")))
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
         (collective-source-page-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-views "Source page")))
         (repro-overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Overview")))
         (repro-freshness-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Source freshness")))
         (repro-source-page-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-views "Source page")))
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
            (smoke-find-view-by-title repro-views "DMX dry-run")))
         (collective-generated-page
           (hyperdoc::localhost-fedwiki-page-promotion-plan-generated-page
            collective
            :signal-error? t))
         (repro-generated-page
           (hyperdoc::localhost-fedwiki-page-promotion-plan-generated-page
            repro
            :signal-error? t)))
    (assert-view-titles-present surface-views
                                '("Overview"
                                  "Triage"
                                  "Attention needed"
                                  "All fresh"
                                  "Source unavailable"
                                  "Stale"
                                  "Unknown missing envelope"
                                  "Unknown malformed envelope"
                                  "Mixed states"
                                  "Plans")
                                "Promotion surface")
    (dolist (label '("All fresh"
                     "Source unavailable"
                     "Stale"
                     "Unknown missing envelope"
                     "Unknown malformed envelope"
                     "Mixed states"))
      (assert-true
       (search label surface-overview-html :test #'char=)
       (format nil "Promotion surface overview must expose the triage count label ~A" label)))
    (dolist (needle (list "DMX repair and guarded-write boundary."
                          "Topicmap 919822 was repaired live after the short-key-only topicmap-context defect on assocs 921404 and 921471."
                          "valuable but untrusted persistence boundary"
                          "Repair runbook page"
                          "Inspect repair runbook object"))
      (assert-true
       (search needle surface-overview-html :test #'char=)
       (format nil "Promotion surface overview must expose ~A" needle)))
    (dolist (needle (list "DMX repair and guarded-write boundary."
                          "Topicmap 919822 was repaired live after the short-key-only topicmap-context defect on assocs 921404 and 921471."
                          "valuable but untrusted persistence boundary"
                          "Repair runbook page"
                          "Inspect repair runbook object"))
      (assert-true
       (search needle surface-handover-html :test #'char=)
       (format nil "Promotion surface DMX handover must expose ~A" needle)))
    (assert-true
     (search "attention-needed promotion plans ahead of all-fresh plans"
             surface-triage-html
             :test #'char=)
     "Promotion surface triage view must explain attention-first ordering")
    (dolist (needle (list "The Life Cycle of Collective Knowledge promotion plan"
                          "Reproducible DevEnv as Knowledge Artifact promotion plan"
                          "the-life-cycle-of-collective-knowledge"
                          "reproducible-devenv-as-knowledge-artifact"
                          "source unavailable"
                          "No action needed"
                          "Inspect plan"
                          "Review freshness"
                          "Review no-action status"
                          "Review source issue"))
      (assert-true
       (search needle surface-triage-html :test #'char=)
       (format nil "Promotion surface triage view must expose ~A" needle)))
    (dolist (needle (list "The Life Cycle of Collective Knowledge promotion plan"
                          "source unavailable"
                          "Review source issue"))
      (assert-true
       (search needle surface-attention-html :test #'char=)
       (format nil "Attention-needed aggregate filter view must expose ~A" needle)))
    (dolist (needle (list "The Life Cycle of Collective Knowledge promotion plan"
                          "Inspect source-unavailable issue"
                          "source unavailable"))
      (assert-true
       (search needle surface-source-unavailable-html :test #'char=)
       (format nil "Source-unavailable aggregate filter view must expose ~A" needle)))
    (dolist (html (list surface-stale-html
                        surface-missing-html
                        surface-malformed-html
                        surface-mixed-html))
      (assert-true
       (search "No promotion plans match this scope." html :test #'char=)
       "Empty aggregate filter views must explain that no plans match the current scope"))
    (dolist (needle (list "Reproducible DevEnv as Knowledge Artifact promotion plan"
                          "No action needed"))
      (assert-true
       (search needle surface-all-fresh-html :test #'char=)
       (format nil "The all-fresh aggregate filter view must expose ~A" needle)))
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
     (search "Status and actions" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose the compact status-and-actions surface")
    (assert-true
     (search "fail-soft boundary" collective-overview-html :test #'char=)
     "Collective knowledge overview must explain the fail-soft source-unavailable boundary")
    (assert-true
     (search "source unavailable" collective-overview-html :test #'char-equal)
     "Collective knowledge overview must expose source-unavailable status")
    (assert-true
     (search "Inspect source-unavailable issue" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose the bounded source issue affordance")
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
     (search "Generated HyperDoc page" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose the generated HyperDoc page link")
    (assert-true
     (search "Review generated page" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose a human-facing generated-page review link")
    (assert-true
     (search "DMX dry-run summary available" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose DMX dry-run summary availability")
    (assert-true
     (search "Page recommended next action" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose page remediation guidance")
    (assert-true
     (search "Snippet recommended next action" collective-overview-html :test #'char=)
     "Collective knowledge overview must expose snippet remediation guidance")
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
     (search "Generated HyperDoc page" repro-overview-html :test #'char=)
     "Second real-page overview must expose the generated HyperDoc page link")
    (assert-true
     (search "Review generated page" repro-overview-html :test #'char=)
     "Second real-page overview must expose a human-facing generated-page review link")
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
     (search "source unavailable" collective-freshness-html :test #'char-equal)
     "Collective knowledge source freshness view must expose source-unavailable classification")
    (assert-true
     (search "Inspect source-unavailable issue"
             collective-freshness-html
             :test #'char=)
     "Collective knowledge source freshness view must expose source-unavailable remediation guidance")
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
    (dolist (html (list collective-source-page-html
                        repro-source-page-html))
      (assert-true
       (search "Generated HyperDoc page" html :test #'char=)
       "Source page view must expose a generated-page link")
      (assert-true
       (search "Open generated page" html :test #'char=)
       "Source page view must expose a human-facing generated-page entry point"))
    (assert-true
     (search "exact missing-file boundary" collective-source-page-html :test #'char=)
     "Collective knowledge source-page view must explain the degraded missing-file boundary")
    (assert-true
     (search "Inspect source-unavailable issue" collective-source-page-html :test #'char=)
     "Collective knowledge source-page view must expose the bounded source issue link")
    (assert-equal
     "The Life Cycle of Collective Knowledge"
     (hyperbook:title-of collective-generated-page)
     "Collective knowledge plan must resolve the correct durable HyperDoc page")
    (assert-equal
     "Reproducible DevEnv as Knowledge Artifact"
     (hyperbook:title-of repro-generated-page)
     "Second real-page plan must resolve the correct durable HyperDoc page")
    (assert-true
     (not (search "/Users/" collective-dmx-html :test #'char=))
     "Collective knowledge DMX dry-run view must not leak machine-local absolute paths")
    (assert-true
     (not (search "/Users/" repro-dmx-html :test #'char=))
     "Second real page DMX dry-run view must not leak machine-local absolute paths")))

(defun run-localhost-fedwiki-page-promotion-surface-triage-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((surface (hyperdoc::current-localhost-fedwiki-page-promotion-surface))
         (collective (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan))
         (repro (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
         (collective-id
           (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective))
         (repro-id
           (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro))
         (base-rows
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-rows surface))
         (base-counts
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-counts
            surface))
         (collective-row
           (find collective-id
                 base-rows
                 :key (lambda (row) (getf row :plan-id))
                 :test #'equal))
         (repro-row
           (find repro-id
                 base-rows
                 :key (lambda (row) (getf row :plan-id))
                 :test #'equal))
         (repro-status
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            repro))
         (count-attention-spec
           (hyperdoc::promotion-triage-count-drilldown-spec
            surface
            :attention-needed))
         (count-all-fresh-spec
           (hyperdoc::promotion-triage-count-drilldown-spec
            surface
            :all-fresh))
         (count-stale-spec
           (hyperdoc::promotion-triage-count-drilldown-spec
            surface
            :stale))
         (count-missing-spec
           (hyperdoc::promotion-triage-count-drilldown-spec
            surface
            :unknown-missing-envelope))
         (count-malformed-spec
           (hyperdoc::promotion-triage-count-drilldown-spec
            surface
            :unknown-malformed-envelope))
         (count-mixed-spec
           (hyperdoc::promotion-triage-count-drilldown-spec
            surface
            :mixed-states))
         (repro-page-rest
           (strip-artifact-envelope-line
            (uiop:read-file-string
             (hyperdoc::localhost-fedwiki-page-promotion-plan-composed-page-pathname
              repro))))
         (repro-snippet-rest
           (strip-artifact-envelope-line
            (uiop:read-file-string
             (hyperdoc::localhost-fedwiki-page-promotion-plan-topic-snippet-pathname
              repro))))
         (simulated-missing
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            repro
            :page-contents repro-page-rest
            :snippet-contents repro-snippet-rest))
         (simulated-stale
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            repro
            :current-source-snapshot
            (hyperdoc::plist-with-overrides
             (getf repro-status :current-source-snapshot)
             :fingerprint "fnv1a64:SIMULATEDSTALE"
             :summary
             "story-items=simulated; source snapshot intentionally stale for triage counts")) )
         (simulated-malformed
           (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status-report
            repro
            :page-contents
            (malformed-html-envelope-contents repro-page-rest)
            :snippet-contents
            (malformed-snippet-envelope-contents repro-snippet-rest)))
         (simulated-mixed
           (hyperdoc::plist-with-overrides
            repro-status
            :page-source-freshness-state :stale
            :page-source-freshness-reason
            "Current normalized source fingerprint fnv1a64:SIMULATEDSTALE differs from reflected snapshot fingerprint fnv1a64:D3A4A5482E15414D."
            :page-source-freshness-recommended-action :regenerate-artifact
            :page-source-freshness-recommended-action-label
            "Regenerate the page artifact to refresh its reflected source snapshot evidence."
            :page-source-freshness-recommended-operation
            'hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
            :page-source-freshness-known t
            :page-source-freshness-unknown-reason nil
            :page-source-fresh nil
            :snippet-source-freshness-state :fresh
            :snippet-source-freshness-reason
            "Current normalized source fingerprint fnv1a64:D3A4A5482E15414D matches reflected snapshot fingerprint fnv1a64:D3A4A5482E15414D."
            :snippet-source-freshness-recommended-action :no-regeneration-needed
            :snippet-source-freshness-recommended-action-label
            "No regeneration needed; the snippet artifact already reflects the current source snapshot."
            :snippet-source-freshness-recommended-operation nil
            :snippet-source-freshness-known t
            :snippet-source-freshness-unknown-reason nil
            :snippet-source-fresh t))
         (missing-row
           (hyperdoc::localhost-fedwiki-page-promotion-plan-triage-row
            collective
            :status simulated-missing))
         (stale-row
           (hyperdoc::localhost-fedwiki-page-promotion-plan-triage-row
            repro
            :status simulated-stale))
         (malformed-row
           (hyperdoc::localhost-fedwiki-page-promotion-plan-triage-row
            collective
            :status simulated-malformed))
         (mixed-row
           (hyperdoc::localhost-fedwiki-page-promotion-plan-triage-row
            repro
            :status simulated-mixed))
         (collective-inspect-spec
           (hyperdoc::promotion-triage-row-inspect-spec collective-row))
         (collective-freshness-spec
           (hyperdoc::promotion-triage-row-freshness-spec collective-row))
         (fresh-action-spec
           (hyperdoc::promotion-triage-row-action-review-spec repro-row))
         (collective-action-spec
           (hyperdoc::promotion-triage-row-action-review-spec collective-row))
         (stale-action-spec
           (hyperdoc::promotion-triage-row-action-review-spec stale-row))
         (missing-action-spec
           (hyperdoc::promotion-triage-row-action-review-spec missing-row))
         (malformed-action-spec
           (hyperdoc::promotion-triage-row-action-review-spec malformed-row))
         (mixed-action-spec
           (hyperdoc::promotion-triage-row-action-review-spec mixed-row))
         (ordered-rows
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-rows
            surface
            :status-overrides
            (list (cons collective-id simulated-malformed)
                  (cons repro-id simulated-mixed))))
         (missing-stale-counts
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-counts
            surface
            :status-overrides
            (list (cons collective-id simulated-missing)
                  (cons repro-id simulated-stale))))
         (malformed-mixed-counts
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-counts
            surface
            :status-overrides
            (list (cons collective-id simulated-malformed)
                  (cons repro-id simulated-mixed))))
         (attention-rows
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-rows
            surface
            :filter :attention-needed
            :status-overrides
            (list (cons collective-id simulated-malformed)
                  (cons repro-id simulated-mixed))))
         (missing-filter-rows
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-rows
            surface
            :filter :unknown-missing-envelope
            :status-overrides
            (list (cons collective-id simulated-missing)
                  (cons repro-id simulated-stale))))
         (stale-filter-rows
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-rows
            surface
            :filter :stale
            :status-overrides
            (list (cons collective-id simulated-missing)
                  (cons repro-id simulated-stale))))
         (mixed-filter-rows
           (hyperdoc::localhost-fedwiki-page-promotion-surface-triage-rows
            surface
            :filter :mixed-states
            :status-overrides
            (list (cons collective-id simulated-malformed)
                  (cons repro-id simulated-mixed)))))
    (assert-true collective-row
                 "Promotion surface triage rows must include the collective plan")
    (assert-true repro-row
                 "Promotion surface triage rows must include the reproducible-devenv plan")
    (assert-equal
     2
     (getf base-counts :plan-count)
     "Promotion surface base triage counts must expose both real plans")
    (assert-equal
     1
     (getf base-counts :all-fresh)
     "Promotion surface base triage counts must keep the healthy real plan in the all-fresh bucket")
    (assert-equal
     1
     (getf base-counts :attention-needed)
     "Promotion surface base triage counts must mark the source-unavailable plan as attention-needed")
    (assert-equal
     1
     (getf base-counts :source-unavailable)
     "Promotion surface base triage counts must classify the missing-source real plan as source-unavailable")
    (assert-true
     (eq surface (getf count-attention-spec :target))
     "Attention-needed count drill-down must keep the aggregate surface as its target")
    (assert-equal
     "Attention needed"
     (getf count-attention-spec :select)
     "Attention-needed count drill-down must select the attention-needed filtered scope")
    (assert-equal
     "All fresh"
     (getf count-all-fresh-spec :select)
     "All-fresh count drill-down must select the all-fresh filtered scope")
    (assert-equal
     "Stale"
     (getf count-stale-spec :select)
     "Stale count drill-down must select the stale filtered scope")
    (assert-equal
     "Unknown missing envelope"
     (getf count-missing-spec :select)
     "Missing-envelope count drill-down must select the missing-envelope filtered scope")
    (assert-equal
     "Unknown malformed envelope"
     (getf count-malformed-spec :select)
     "Malformed-envelope count drill-down must select the malformed-envelope filtered scope")
    (assert-equal
     "Mixed states"
     (getf count-mixed-spec :select)
     "Mixed-state count drill-down must select the mixed-states filtered scope")
    (assert-equal
     collective-id
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (getf collective-row :inspect-target))
     "Collective triage row inspect target must resolve to the correct plan object")
    (assert-equal
     repro-id
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (getf repro-row :inspect-target))
     "Reproducible-devenv triage row inspect target must resolve to the correct plan object")
    (assert-equal
     :source-unavailable
     (getf collective-row :attention-category)
     "Collective triage row must classify the current real-plan state as source-unavailable")
    (assert-equal
     :all-fresh
     (getf repro-row :attention-category)
     "Reproducible-devenv triage row must classify the current real-plan state as all fresh")
    (assert-equal
     "Overview"
     (getf collective-inspect-spec :select)
     "Row-level inspect drill-down must open the per-plan Overview view")
    (assert-equal
     "Source freshness"
     (getf collective-freshness-spec :select)
     "Row-level freshness drill-down must open the per-plan Source freshness view")
    (assert-equal
     "Source page"
     (getf collective-action-spec :select)
     "Source-unavailable row action drill-down must open the per-plan Source page view")
    (assert-equal
     "Review source issue"
     (getf collective-action-spec :label)
     "Source-unavailable row action drill-down must expose a source-issue label")
    (assert-equal
     "Overview"
     (getf fresh-action-spec :select)
     "Fresh row action drill-down must open the per-plan Overview view")
    (assert-equal
     "Review no-action status"
     (getf fresh-action-spec :label)
     "Fresh row action drill-down must expose a passive no-action label")
    (assert-true
     (string= (getf collective-row :recommended-next-action-summary)
              "Page: Inspect source-unavailable issue; Snippet: Inspect source-unavailable issue")
     "Collective triage row must summarize the source-unavailable next actions compactly")
    (assert-equal
     1
     (getf missing-stale-counts :unknown-missing-envelope)
     "Simulated counts must expose one unknown-missing-envelope plan")
    (assert-equal
     1
     (getf missing-stale-counts :stale)
     "Simulated counts must expose one stale plan")
    (assert-equal
     1
     (getf malformed-mixed-counts :unknown-malformed-envelope)
     "Simulated counts must expose one unknown-malformed-envelope plan")
    (assert-equal
     1
     (getf malformed-mixed-counts :mixed-states)
     "Simulated counts must expose one mixed-states plan")
    (assert-equal
     :unknown-missing-envelope
     (getf missing-row :attention-category)
     "Missing-envelope triage row must classify unknown missing state explicitly")
    (assert-equal
     :unknown-malformed-envelope
     (getf malformed-row :attention-category)
     "Malformed-envelope triage row must classify unknown malformed state explicitly")
    (assert-equal
     :mixed-states
     (getf mixed-row :attention-category)
     "Mixed triage row must classify differing page/snippet freshness states explicitly")
    (assert-equal
     :stale
     (getf mixed-row :page-freshness-state)
     "Mixed triage row must preserve the simulated stale page state")
    (assert-equal
     :fresh
     (getf mixed-row :snippet-freshness-state)
     "Mixed triage row must preserve the simulated fresh snippet state")
    (assert-equal
     "Overview"
     (getf stale-action-spec :select)
     "Stale row action drill-down must open the per-plan Overview action surface")
    (assert-equal
     "Review stale action"
     (getf stale-action-spec :label)
     "Stale row action drill-down must expose a stale-specific review label")
    (assert-equal
     "Source freshness"
     (getf missing-action-spec :select)
     "Missing-envelope row action drill-down must open the per-plan Source freshness view")
    (assert-equal
     "Review restore action"
     (getf missing-action-spec :label)
     "Missing-envelope row action drill-down must expose a restore-specific label")
    (assert-equal
     "Source freshness"
     (getf malformed-action-spec :select)
     "Malformed-envelope row action drill-down must open the per-plan Source freshness view")
    (assert-equal
     "Review repair action"
     (getf malformed-action-spec :label)
     "Malformed-envelope row action drill-down must expose a repair-specific label")
    (assert-equal
     "Source freshness"
     (getf mixed-action-spec :select)
     "Mixed row action drill-down must open the per-plan Source freshness view")
    (assert-equal
     "Review mixed action"
     (getf mixed-action-spec :label)
     "Mixed row action drill-down must expose a mixed-state label")
    (assert-equal
     collective-id
     (getf (first ordered-rows) :plan-id)
     "Malformed attention-needed triage rows must sort ahead of mixed stale rows")
    (assert-equal
     :unknown-malformed-envelope
     (getf (first ordered-rows) :attention-category)
     "The first ordered triage row must expose the highest-priority malformed state")
    (assert-equal
     repro-id
     (getf (second ordered-rows) :plan-id)
     "Mixed stale rows must sort after malformed rows when both need attention")
    (assert-equal
     2
     (length attention-rows)
     "Attention-needed filter must keep both simulated attention-needed rows")
    (assert-equal
     collective-id
     (getf (first missing-filter-rows) :plan-id)
     "Unknown-missing filter must keep only the matching plan")
    (assert-equal
     repro-id
     (getf (first stale-filter-rows) :plan-id)
     "Stale filter must keep only the matching plan")
    (assert-equal
     repro-id
     (getf (first mixed-filter-rows) :plan-id)
     "Mixed-states filter must keep only the matching plan")
    (assert-equal
     repro-id
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id
      (getf (first mixed-filter-rows) :inspect-target))
     "Filtered triage rows must keep direct inspect targets intact")
    (assert-true
     (string= (getf mixed-row :recommended-next-action-summary)
              "Page: Regenerate page artifact; Snippet: No action needed")
     "Mixed triage rows must summarize page/snippet next actions compactly")
    (assert-true
     (string= (getf missing-row :recommended-next-action-summary)
              "Page: Restore page snapshot evidence; Snippet: Restore snippet snapshot evidence")
     "Missing-envelope triage rows must summarize restore actions compactly")
    (assert-true
     (string= (getf malformed-row :recommended-next-action-summary)
              "Page: Repair page snapshot evidence; Snippet: Repair snippet snapshot evidence")
     "Malformed-envelope triage rows must summarize repair actions compactly")))

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
                                      "Promotion plan")))
         (collective-source-summary-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-source-views
                                      "Summary")))
         (repro-source-summary-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-source-views
                                      "Summary")))
         (collective-generated-page
           (hyperdoc::localhost-fedwiki-page-promotion-plan-generated-page
            collective-plan
            :signal-error? t))
         (repro-generated-page
           (hyperdoc::localhost-fedwiki-page-promotion-plan-generated-page
            repro-plan
            :signal-error? t))
         (collective-source-generated-page
           (hyperdoc::localhost-fedwiki-source-generated-page
            collective-source
            :signal-error? t))
         (repro-source-generated-page
           (hyperdoc::localhost-fedwiki-source-generated-page
            repro-source
            :signal-error? t)))
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
     (smoke-find-view-by-title collective-source-views "Summary")
     "Collective knowledge source object must keep its Summary view")
    (assert-true
     (smoke-find-view-by-title repro-source-views "Summary")
     "Second real-page source object must keep its Summary view")
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
     "Second real-page source entry point must preserve the canonical source page id")
    (dolist (html (list collective-source-summary-html
                        repro-source-summary-html))
      (assert-true
       (search "Generated HyperDoc page" html :test #'char=)
       "Normalized source summary must expose the generated HyperDoc page link")
      (assert-true
       (search "Open generated page" html :test #'char=)
       "Normalized source summary must expose a human-facing generated-page link"))
    (assert-equal
     "The Life Cycle of Collective Knowledge"
     (hyperbook:title-of collective-generated-page)
     "Collective knowledge plan must resolve the correct generated HyperDoc page")
    (assert-equal
     "Reproducible DevEnv as Knowledge Artifact"
     (hyperbook:title-of repro-generated-page)
     "Second real-page plan must resolve the correct generated HyperDoc page")
    (assert-equal
     "The Life Cycle of Collective Knowledge"
     (hyperbook:title-of collective-source-generated-page)
     "Collective knowledge source object must resolve the correct generated HyperDoc page")
    (assert-equal
     "Reproducible DevEnv as Knowledge Artifact"
     (hyperbook:title-of repro-source-generated-page)
     "Second real-page source object must resolve the correct generated HyperDoc page")))

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
  (let* ((workflow-page-source
           (uiop:read-file-string
            (localhost-fedwiki-page-promotion-workflow-relative-path)))
         (collective-page-source
           (uiop:read-file-string
            (asdf:system-relative-pathname
             :hyperdoc
             "hyperdoc/The Life Cycle of Collective Knowledge.html")))
         (repro-page-source
           (uiop:read-file-string
            (asdf:system-relative-pathname
             :hyperdoc
             "hyperdoc/Reproducible DevEnv as Knowledge Artifact.html")))
         (collective-page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "The Life Cycle of Collective Knowledge"
                                :signal-error? t))
         (repro-page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "Reproducible DevEnv as Knowledge Artifact"
                                :signal-error? t))
         (collective-page-views
           (load-inspector-views-for-object collective-page))
         (repro-page-views
           (load-inspector-views-for-object repro-page))
         (collective-content-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-page-views "Content")))
         (collective-status-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title collective-page-views "Workflow status")))
         (repro-content-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-page-views "Content")))
         (repro-status-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title repro-page-views "Workflow status")))
         (collective-plan
           (hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan))
         (repro-plan
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
         (collective-source
           (hyperdoc::the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk))
         (repro-source
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk))
         (collective-page-plan
           (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-generated-page
            collective-page
            :signal-error? t))
         (repro-page-plan
           (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-generated-page
            repro-page
            :signal-error? t)))
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
     "Workflow page must keep the optional live DMX write boundary explicit and separate")
    (dolist (page-view-html (list collective-content-html
                                  repro-content-html))
      (assert-true
       (search "Promotion workflow" page-view-html :test #'char=)
       "Generated page content view must expose the Promotion workflow section")
      (assert-true
       (search "Promotion plan overview" page-view-html :test #'char=)
       "Generated page content view must expose the promotion-plan back-link")
      (assert-true
       (search "Review source freshness" page-view-html :test #'char=)
       "Generated page content view must expose the source-freshness back-link")
      (assert-true
       (search "Normalized localhost source object" page-view-html :test #'char=)
       "Generated page content view must expose the normalized-source back-link"))
    (dolist (status-html (list collective-status-html
                               repro-status-html))
      (assert-true
       (search "Promotion plan id" status-html :test #'char=)
       "Generated page workflow-status view must expose the linked promotion plan id")
      (assert-true
       (search "Linked localhost source id" status-html :test #'char=)
       "Generated page workflow-status view must expose the linked localhost source id")
      (assert-true
       (search "Linked localhost source slug" status-html :test #'char=)
       "Generated page workflow-status view must expose the linked localhost source slug")
      (assert-true
       (search "Page source freshness" status-html :test #'char=)
       "Generated page workflow-status view must expose page freshness")
      (assert-true
       (search "Snippet source freshness" status-html :test #'char=)
       "Generated page workflow-status view must expose snippet freshness")
      (assert-true
       (search "Recommended next action summary" status-html :test #'char=)
       "Generated page workflow-status view must expose recommended next-action summary")
      (assert-true
       (search "Promotion plan overview" status-html :test #'char=)
       "Generated page workflow-status view must link to the promotion plan overview")
      (assert-true
       (search "Review source freshness" status-html :test #'char=)
       "Generated page workflow-status view must link to source freshness")
      (assert-true
       (search "Review source page" status-html :test #'char=)
       "Generated page workflow-status view must link to the source-page surface"))
    (assert-true
     (search "No action needed" collective-status-html :test #'char=)
     "Collective knowledge generated page workflow-status view must expose the fresh no-action summary")
    (assert-true
     (search "No action needed" repro-status-html :test #'char=)
     "Second real generated page workflow-status view must expose the fresh no-action summary")
    (dolist (needle
             '("expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan)\" view=\"Overview\""
               "expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan)\" view=\"Source freshness\""
               "expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-promotion-plan)\" view=\"Source page\""
               "expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk)\" view=\"Summary\""))
      (assert-true
       (search needle collective-page-source :test #'char=)
       (format nil "Collective knowledge generated page must contain authored navigation ~A"
               needle)))
    (dolist (needle
             '("expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan)\" view=\"Overview\""
               "expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan)\" view=\"Source freshness\""
               "expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan)\" view=\"Source page\""
               "expr=\"(hyperdoc::reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk)\" view=\"Summary\""))
      (assert-true
       (search needle repro-page-source :test #'char=)
       (format nil "Second real generated page must contain authored navigation ~A"
               needle)))
    (assert-equal
     "the-life-cycle-of-collective-knowledge-promotion-plan"
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective-plan)
     "Collective knowledge generated page must link back to the correct promotion plan object")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id collective-page-plan)
     "Collective knowledge generated page workflow-status surface must resolve to the correct promotion plan object")
    (assert-equal
     "reproducible-devenv-as-knowledge-artifact-promotion-plan"
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro-plan)
     "Second real generated page must link back to the correct promotion plan object")
    (assert-equal
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro-plan)
     (hyperdoc::localhost-fedwiki-page-promotion-plan-id repro-page-plan)
     "Second real generated page workflow-status surface must resolve to the correct promotion plan object")
    (assert-equal
     "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"
     (hyperdoc::fedwiki-page-id-of collective-source)
     "Collective knowledge generated page must link back to the correct normalized source object")
    (assert-equal
     "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact"
     (hyperdoc::fedwiki-page-id-of repro-source)
     "Second real generated page must link back to the correct normalized source object")
    (assert-true
     (search (hyperdoc::fedwiki-page-id-of collective-source)
             collective-status-html
             :test #'char=)
     "Collective knowledge generated page workflow-status surface must expose the canonical source id")
    (assert-true
     (search (hyperdoc::localhost-fedwiki-page-promotion-plan-source-page-slug
              collective-plan)
             collective-status-html
             :test #'char=)
     "Collective knowledge generated page workflow-status surface must expose the canonical source slug")
    (assert-true
     (search (hyperdoc::fedwiki-page-id-of repro-source)
             repro-status-html
             :test #'char=)
     "Second real generated page workflow-status surface must expose the canonical source id")
    (assert-true
     (search (hyperdoc::localhost-fedwiki-page-promotion-plan-source-page-slug
              repro-plan)
             repro-status-html
             :test #'char=)
     "Second real generated page workflow-status surface must expose the canonical source slug")))

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
     (not (hyperdoc::localhost-fedwiki-page-promotion-plan-page-source-fresh-p collective))
     "Collective knowledge page output must no longer report fresh while the localhost source file is unavailable")
    (assert-true
     (not (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-source-fresh-p collective))
     "Collective knowledge snippet output must no longer report fresh while the localhost source file is unavailable")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-page-source-fresh-p repro)
     "Second real-page output must stay fresh relative to the current source snapshot")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-plan-snippet-source-fresh-p repro)
     "Second real-page snippet output must stay fresh relative to the current source snapshot")))

(defun run-localhost-fedwiki-page-promotion-dmx-handover-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((surface (hyperdoc::current-localhost-fedwiki-page-promotion-surface))
         (views (load-inspector-views-for-object surface))
         (handover-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "DMX handover")))
         (runbook-page (hyperdoc::promotion-dmx-repair-runbook-page))
         (runbook-object (hyperdoc::promotion-dmx-repair-runbook-object))
         (definition
           (hyperdoc::localhost-fedwiki-page-promotion-handover-topic-definition-chunk
            surface))
         (summary
           (hyperdoc::localhost-fedwiki-page-promotion-handover-dmx-write-summary
            :surface surface))
         (evidence
           (hyperdoc::localhost-fedwiki-page-promotion-handover-dmx-write-evidence
            :surface surface))
         (plan
           (hyperdoc::localhost-fedwiki-page-promotion-handover-dmx-write-plan
            :surface surface))
         (payload (hyperdoc::topic-factory-snippet-dmx-write-plan-payload plan))
         (children (getf payload :children))
         (body (hyperdoc::snippet-text-of definition)))
    (assert-true
     (smoke-find-view-by-title views "DMX handover")
     "Promotion surface must expose the DMX handover view")
    (assert-true runbook-page
                 "DMX blocked-state note must resolve the repair runbook page")
    (assert-true runbook-object
                 "DMX blocked-state note must resolve the repair runbook object")
    (assert-equal "DMX topicmap 919822 repair runbook"
                  (hyperbook:title-of runbook-page)
                  "DMX blocked-state note must target the repair runbook page")
    (assert-equal "DMX topicmap 919822 repair runbook"
                  (hyperdoc::dmx-topicmap-repair-runbook-title runbook-object)
                  "DMX blocked-state note must target the repair runbook object")
    (assert-equal hyperdoc::*localhost-fedwiki-page-promotion-handover-topic-title*
                  (getf summary :topic-title)
                  "DMX handover summary must preserve the seed topic title")
    (assert-equal 919822
                  (getf summary :workspace-topicmap-id)
                  "DMX handover summary must target topicmap 919822")
    (assert-equal
     "https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/919822/topic/919822"
     (getf summary :workspace-topicmap-route)
     "DMX handover summary must preserve the explicit DMX topicmap route")
    (assert-equal :create
                  (getf summary :topic-action)
                  "DMX handover summary must start with CREATE on a fresh memory client")
    (assert-equal :add
                  (getf summary :topicmap-action)
                  "DMX handover summary must add the seed topic to the explicit workspace topicmap")
    (assert-equal :canonical
                  (getf summary :view-props-validation-status)
                  "DMX handover summary must expose canonical topicmap view-props validation status")
    (assert-equal nil
                  (getf summary :forbidden-short-keys)
                  "DMX handover summary must not preserve forbidden short keys")
    (assert-true
     (search "\"dmx.topicmaps.x\":160"
             (getf summary :normalized-view-props-json))
     "DMX handover summary must expose the normalized long-form topicmap payload")
    (assert-equal "hyperdoc/localhost-fedwiki-page-promotion-plans.lisp"
                  (getf summary :source-path)
                  "DMX handover summary must preserve the repo-relative source file path")
    (assert-equal "hyperdoc:topic-factory-snippet/hyperdoc-localhost-fedwiki-promotion-workflow-handover"
                  (getf summary :uri)
                  "DMX handover summary must preserve the stable topic URI")
    (assert-equal hyperdoc::*localhost-fedwiki-page-promotion-handover-dmx-topic-type-uri*
                  (getf summary :topic-type-uri)
                  "DMX handover summary must preserve the installed live-write topic type")
    (assert-equal hyperdoc::*localhost-fedwiki-page-promotion-handover-topic-title*
                  (getf payload :value)
                  "DMX handover payload must preserve the human-facing topic title")
    (assert-equal hyperdoc::*localhost-fedwiki-page-promotion-handover-dmx-topic-type-uri*
                  (getf payload :type-uri)
                  "DMX handover payload must use the installed live-write topic type")
    (assert-equal hyperdoc::*localhost-fedwiki-page-promotion-handover-topic-title*
                  (gethash hyperdoc::*dmx-notes-title-type-uri*
                           children)
                  "DMX handover payload must place the accepted handover title into the note title child")
    (assert-equal body
                  (gethash hyperdoc::*dmx-notes-text-type-uri*
                           children)
                  "DMX handover payload must place the accepted handover body into the note text child")
    (dolist (needle
             (list "Current status"
                   "Current boundaries"
                   "Proven real instances"
                   "Current workflow loop"
                   "Next DMX-oriented work"
                   "Identifiers and links"
                   "The Life Cycle of Collective Knowledge"
                   "Reproducible DevEnv as Knowledge Artifact"
                   "localhost-fedwiki-page-promotion-workflow"
                   "topicmap 919822"))
      (assert-true
       (search needle body :test #'char=)
       (format nil "DMX handover body must expose ~A" needle)))
    (dolist (needle
             (list "DMX handover"
                   "HyperDoc localhost FedWiki promotion workflow"
                   "topicmap/919822/topic/919822"
                   "Current status"
                   "Next DMX-oriented work"
                   "TOPIC_FACTORY_SNIPPET_DMX_TOPIC value=\"HyperDoc localhost FedWiki promotion workflow\""
                   "TOPIC_FACTORY_SNIPPET_DMX_TYPE uri=\"dmx.notes.note\""
                   "topic-action=CREATE"
                   "topicmap-action=ADD"
                   "TOPIC_FACTORY_SNIPPET_DMX_VIEW_VALIDATION status=CANONICAL"
                   "\"dmx.topicmaps.x\":160"
                   "workspace-topicmap-id=919822"
                   "source=hyperdoc/localhost-fedwiki-page-promotion-plans.lisp"
                   "DMX repair and guarded-write boundary."
                   "Topicmap 919822 was repaired live after the short-key-only topicmap-context defect on assocs 921404 and 921471."
                   "valuable but untrusted persistence boundary"
                   "Repair runbook page"
                   "Inspect repair runbook object"))
      (assert-true
       (or (search needle handover-html :test #'char=)
           (search needle evidence :test #'char=))
       (format nil "DMX handover inspector/evidence must expose ~A" needle)))
    (assert-true
     (not (search "/Users/" evidence))
     "DMX handover dry-run evidence must not preserve machine-local absolute paths")
    (assert-true
     (search "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"
             body)
     "DMX handover body must preserve the first canonical FedWiki page id")
    (assert-true
     (search "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact"
             body)
     "DMX handover body must preserve the second canonical FedWiki page id")
    (assert-true
     (search "https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/919822/topic/919822"
             body)
     "DMX handover body must preserve the explicit target topicmap route")
    (assert-true
     (not (search "/Users/" body))
     "DMX handover body must not preserve machine-local absolute paths")))

(defun run-localhost-fedwiki-page-promotion-guarded-dmx-dry-run-smoke-test ()
  (let* ((plan (first-healthy-real-localhost-fedwiki-page-promotion-plan))
         (summary
           (hyperdoc::localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary
            plan))
         (evidence
           (hyperdoc::localhost-fedwiki-page-promotion-plan-dmx-dry-run-evidence
            plan)))
    (assert-true plan
                 "A healthy real promotion plan must remain available for guarded DMX dry-run coverage")
    (assert-true
     (getf summary :available)
     "Real localhost FedWiki promotion plan must keep the DMX dry-run available through the guarded boundary")
    (assert-equal :canonical
                  (getf summary :view-props-validation-status)
                  "Real localhost FedWiki promotion plan must expose canonical topicmap view-props validation status")
    (assert-equal nil
                  (getf summary :forbidden-short-keys)
                  "Real localhost FedWiki promotion plan must not preserve forbidden short keys in the dry-run summary")
    (assert-true
     (search "\"dmx.topicmaps.x\":160"
             (getf summary :normalized-view-props-json))
     "Real localhost FedWiki promotion plan must expose the normalized long-form topicmap payload")
    (assert-true
     (search "TOPIC_FACTORY_SNIPPET_DMX_VIEW_VALIDATION status=CANONICAL"
             evidence)
     "Real localhost FedWiki promotion dry-run evidence must expose canonical topicmap view-props validation status")
    (assert-true
     (search "\"dmx.topicmaps.x\":160" evidence)
     "Real localhost FedWiki promotion dry-run evidence must expose the normalized long-form topicmap payload")))

(defun run-dmx-topicmap-919822-repair-runbook-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-source
           (uiop:read-file-string
            (dmx-topicmap-919822-repair-runbook-relative-path)))
         (page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "DMX topicmap 919822 repair runbook"
                                :signal-error? t))
         (topic-page
           (hyperbook:find-page hyperdoc::*topics*
                                "DMX topicmap 919822 repair runbook"
                                :signal-error? t))
         (runbook (hyperdoc::dmx-topicmap-919822-repair-runbook))
         (views (load-inspector-views-for-object runbook))
         (overview-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "Overview")))
         (healthy-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "Healthy specimen")))
         (broken-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "Broken assocs")))
         (evidence-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "Evidence")))
         (dry-run-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "Dry-run")))
         (unknowns-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "Unknowns")))
         (operations-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title views "Operations"))))
    (assert-true
     (fboundp 'hyperdoc::dmx-topicmap-919822-repair-runbook-topic)
     "Repair runbook topic function must be present")
    (assert-true page
                 "Repair runbook HyperDoc page must be browseable")
    (assert-true topic-page
                 "Repair runbook topic page must be browseable in Topics")
    (assert-view-titles-present
     views
     '("Overview"
       "Healthy specimen"
       "Broken assocs"
       "Evidence"
       "Candidate repairs"
       "Dry-run"
       "Unknowns"
       "Operations")
     "DMX topicmap 919822 repair runbook")
    (dolist (needle
             '("dmx-topicmap-919822-repair-runbook"
               "Healthy specimen"
               "Broken assocs"
               "Dry-run"
               "Unknowns"
               "Operations"
               "921404"
               "921471"
               "921494"
               "921503"
               "topicmaps/object/921352"
               "topicmaps/object/921464"
               "topicmaps/919822"
               "dmx.topicmaps.visibility"
               "dmx.topicmaps.x"
               "No POST, PUT, or DELETE is attached to this runbook object."
               "The public API does not expose the exact write payload for <tt>/topicmaps/919822/assoc/&lt;assoc-id&gt;</tt>."))
      (assert-true
       (search needle page-source :test #'char=)
       (format nil "Repair runbook page must expose ~A" needle)))
    (dolist (needle
             '("Topicmap id"
               "919822"
               "context-window"
               "Healthy comparison topic"
               "921494"
               "Healthy comparison assoc"
               "921503"
               "Broken assoc ids"
               "921404, 921471"
               "DMX writes enabled by default"
               "no"))
      (assert-true
       (search needle overview-html :test #'char=)
       (format nil "Repair runbook overview must expose ~A" needle)))
    (dolist (needle
             '("Topic 921494 is the accepted healthy comparison specimen"
               "921494"
               "921503"
               "dmx.topicmaps.topicmap_context"))
      (assert-true
       (search needle healthy-html :test #'char=)
       (format nil "Repair runbook healthy-specimen view must expose ~A"
               needle)))
    (dolist (needle
             '("921404"
               "921352"
               "921471"
               "921464"
               "dmx.topicmaps.topicmap_context"
               "topicmaps/object/921352 fails on missing dmx.topicmaps.visibility for assoc 921404"
               "topicmaps/object/921464 fails on missing dmx.topicmaps.visibility for assoc 921471"))
      (assert-true
       (search needle broken-html :test #'char=)
       (format nil "Repair runbook broken-assocs view must expose ~A" needle)))
    (dolist (needle
             '("/core/topic/921494?children=true&amp;assocChildren=true"
               "/topicmaps/object/921494"
               "/core/assoc/921404?children=true&amp;assocChildren=true"
               "/core/assoc/921471?children=true&amp;assocChildren=true"
               "/topicmaps/919822"))
      (assert-true
       (search needle evidence-html :test #'char=)
       (format nil "Repair runbook evidence view must expose ~A" needle)))
    (dolist (needle
             '("This checklist is read-only by default."
               "No POST, PUT, or DELETE is attached to this runbook object."
               "Returns 200 OK and exposes assoc 921503"
               "Returns 500 and names missing dmx.topicmaps.visibility for assoc 921404."
               "Returns 500 and names missing dmx.topicmaps.visibility for assoc 921471."
               "Post-repair verification"
               "Returns 200 OK with no missing-x failure before any DMX seeding work resumes."))
      (assert-true
       (search needle dry-run-html :test #'char=)
       (format nil "Repair runbook dry-run view must expose ~A" needle)))
    (dolist (needle
             '("HyperDoc-side writer changes are not justified"
               "public API proves the broken assoc ids"
               "does not expose the exact write payload"))
      (assert-true
       (search needle unknowns-html :test #'char-equal)
       (format nil "Repair runbook unknowns view must expose ~A" needle)))
    (dolist (needle
             '("Operations stay passive in this runbook."
               "Default mode"
               "read-only"
               "Writes enabled"
               "no"
               "/topicmaps/919822/assoc/921503"
               "921404, 921471"
               "The public API does not reveal the exact write payload for /topicmaps/919822/assoc/&lt;assoc-id&gt;."))
      (assert-true
       (search needle operations-html :test #'char=)
       (format nil "Repair runbook operations view must expose ~A" needle)))
    (assert-true
     (null (hyperdoc::dmx-topicmap-repair-runbook-write-enabled-p runbook))
     "Repair runbook must keep DMX writes disabled by default")
    (assert-equal
     :read-only
     (hyperdoc::dmx-topicmap-repair-runbook-default-operation-mode runbook)
     "Repair runbook must stay read-only by default")))

(defun explosive-localhost-fedwiki-page-promotion-plan ()
  (error "Unrelated promotion-plan constructor should not run while opening the DMX repair runbook topic page."))

(defun run-localhost-fedwiki-page-promotion-lookup-boundary-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((topic-page
           (hyperbook:find-page hyperdoc::*topics*
                                "DMX topicmap 919822 repair runbook"
                                :signal-error? t))
         (views
           (let ((hyperdoc::*localhost-fedwiki-page-promotion-plan-specs*
                   (list
                    (list :id "explosive-promotion-plan"
                          :related-topic-id "some-other-topic"
                          :source-page-id
                          "fedwiki:wiki.ralfbarkow.ch/some-other-topic"
                          :related-hyperdoc-page-title
                          "Some Other Topic"
                          :constructor
                          'explosive-localhost-fedwiki-page-promotion-plan))))
             (assert-equal
              nil
              (hyperdoc::find-localhost-fedwiki-page-promotion-plan-for-topic-page
               topic-page)
              "Unrelated promotion-plan constructors must not run while looking up the repair runbook topic page")
             (load-inspector-views-for-object topic-page))))
    (assert-true
     (smoke-find-view-by-title views "Content")
     "Repair runbook topic page must keep opening when unrelated promotion-plan constructors are present")
    (assert-true
     (null (smoke-find-view-by-title views "Promotion plan"))
     "Repair runbook topic page must not expose a promotion-plan entry point when no plan matches it")))

(defun run-localhost-fedwiki-page-promotion-missing-source-fail-soft-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((healthy-plan (first-healthy-real-localhost-fedwiki-page-promotion-plan))
         (healthy-title
           (and healthy-plan
                (hyperdoc::localhost-fedwiki-page-promotion-plan-title
                 healthy-plan)))
         (healthy-status
           (and healthy-plan
                (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status
                 healthy-plan)))
         (healthy-views
           (and healthy-plan
                (load-inspector-views-for-object healthy-plan)))
         (healthy-overview-html
           (and healthy-views
                (html-inspector-views:view-html
                 (smoke-find-view-by-title healthy-views "Overview"))))
         (healthy-freshness-html
           (and healthy-views
                (html-inspector-views:view-html
                 (smoke-find-view-by-title healthy-views "Source freshness"))))
         (healthy-surface (hyperdoc::current-localhost-fedwiki-page-promotion-surface))
         (healthy-surface-views (load-inspector-views-for-object healthy-surface))
         (healthy-surface-all-fresh-html
           (html-inspector-views:view-html
            (smoke-find-view-by-title healthy-surface-views "All fresh"))))
    (assert-true healthy-plan
                 "At least one real promotion plan must remain healthy outside the missing-source seam")
    (assert-true
     (null (hyperdoc::localhost-fedwiki-page-promotion-plan-source-issue
            healthy-plan))
     "Unaffected real promotion plans must keep their normal source state")
    (assert-equal
     :available
     (getf healthy-status :source-availability-state)
     "Unaffected real promotion plans must keep an available source state")
    (assert-equal
     :fresh
     (getf healthy-status :page-source-freshness-state)
     "Unaffected real promotion plans must keep a fresh page source state")
    (assert-equal
     :fresh
     (getf healthy-status :snippet-source-freshness-state)
     "Unaffected real promotion plans must keep a fresh snippet source state")
    (assert-true
     (search healthy-title healthy-surface-all-fresh-html :test #'char=)
     "Healthy real-plan proof must keep the unaffected plan in the all-fresh aggregate scope")
    (dolist (html (list healthy-overview-html
                        healthy-freshness-html))
      (assert-true
       (search "No action needed" html :test #'char=)
       "Healthy real-plan proof must preserve the passive no-action state"))
    (call-with-simulated-missing-reproducible-devenv-source
     (lambda ()
       (let* ((surface (hyperdoc::current-localhost-fedwiki-page-promotion-surface))
              (repro
                (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
              (issue
                (hyperdoc::localhost-fedwiki-page-promotion-plan-source-issue
                 repro))
              (status
                (hyperdoc::localhost-fedwiki-page-promotion-plan-sync-status
                 repro))
              (views (load-inspector-views-for-object repro))
              (issue-views (load-inspector-views-for-object issue))
              (surface-views (load-inspector-views-for-object surface))
              (overview-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title views "Overview")))
              (source-page-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title views "Source page")))
              (source-freshness-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title views "Source freshness")))
              (dmx-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title views "DMX dry-run")))
              (surface-source-unavailable-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title surface-views "Source unavailable")))
              (page-regeneration-result
                (hyperdoc::regenerate-localhost-fedwiki-page-promotion-plan-page-artifact
                 repro))
              (dmx-review-result
                (hyperdoc::review-localhost-fedwiki-page-promotion-plan-dmx-dry-run
                 repro))
              (canonical-page-id
                (format nil "fedwiki:~A/~A"
                        hyperdoc::*reproducible-devenv-as-knowledge-artifact-fedwiki-site*
                        hyperdoc::*reproducible-devenv-as-knowledge-artifact-fedwiki-slug*))
              (canonical-path
                (format nil "pages/~A"
                        hyperdoc::*reproducible-devenv-as-knowledge-artifact-fedwiki-slug*)))
         (assert-true issue
                      "Missing-source seam must still instantiate a bounded promotion-plan source issue")
         (assert-equal
          :source-unavailable
          (hyperdoc::localhost-fedwiki-page-promotion-source-unavailable-issue-classification
           issue)
          "Missing-source seam must classify the bounded issue as source-unavailable")
         (assert-equal
          :source-unavailable
          (getf status :source-availability-state)
          "Missing-source plan status must preserve a source-unavailable availability state")
         (assert-equal
          :source-unavailable
          (getf status :page-source-freshness-state)
          "Missing-source plan must classify page freshness as source-unavailable")
         (assert-equal
          :source-unavailable
          (getf status :snippet-source-freshness-state)
          "Missing-source plan must classify snippet freshness as source-unavailable")
         (assert-equal
          canonical-page-id
          (hyperdoc::localhost-fedwiki-page-promotion-plan-source-page-id repro)
          "Missing-source plan must preserve the canonical source page id")
         (assert-equal
          canonical-path
          (hyperdoc::localhost-fedwiki-page-promotion-plan-source-page-path repro)
          "Missing-source plan must preserve the canonical repo-relative source path")
         (assert-view-titles-present
          views
          '("Overview"
            "Source page"
            "Story items"
            "Fragments"
            "Promoted topics"
            "Page output"
            "Source freshness"
            "Snippet metadata"
            "DMX dry-run")
          "Missing-source promotion plan")
         (assert-view-titles-present
          issue-views
          '("Overview"
            "Condition")
          "Missing-source issue")
         (assert-true
          (search "Reproducible DevEnv as Knowledge Artifact promotion plan"
                  surface-source-unavailable-html
                  :test #'char=)
          "Source-unavailable surface filter must list the degraded real plan")
         (assert-true
          (search "source unavailable"
                  surface-source-unavailable-html
                  :test #'char-equal)
          "Source-unavailable surface filter must classify the degraded plan explicitly")
         (assert-true
          (typep page-regeneration-result
                 'hyperdoc::localhost-fedwiki-page-promotion-source-unavailable-issue)
          "Missing-source page regeneration must fail softly by returning the bounded issue")
         (assert-true
          (typep dmx-review-result
                 'hyperdoc::localhost-fedwiki-page-promotion-source-unavailable-issue)
          "Missing-source DMX review must fail softly by returning the bounded issue"))))))

(defun run-localhost-fedwiki-page-promotion-plans-smoke-tests ()
  (run-localhost-first-fedwiki-publication-plan-smoke-test)
  (run-localhost-first-fedwiki-live-publication-smoke-test)
  (run-localhost-fedwiki-page-promotion-plan-view-smoke-test)
  (run-localhost-fedwiki-page-promotion-surface-triage-smoke-test)
  (run-localhost-fedwiki-page-promotion-entry-point-smoke-test)
  (run-localhost-fedwiki-page-promotion-operations-smoke-test)
  (run-localhost-fedwiki-page-promotion-page-and-topic-smoke-test)
  (run-dmx-topicmap-919822-repair-runbook-smoke-test)
  (run-localhost-fedwiki-page-promotion-lookup-boundary-smoke-test)
  (run-localhost-fedwiki-page-promotion-missing-source-fail-soft-smoke-test)
  (run-localhost-fedwiki-page-promotion-dmx-handover-smoke-test)
  (run-localhost-fedwiki-page-promotion-guarded-dmx-dry-run-smoke-test)
  (run-localhost-fedwiki-page-promotion-output-sync-smoke-test)
  (format t "~&Localhost FedWiki page promotion plan smoke tests passed.~%")
  t)
