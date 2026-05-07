;;;; Focused smoke tests for the DMX 919822 incident arc and guarded write boundary
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DMX-INCIDENT-ARC-SMOKE-TESTS"
                        :hyperdoc/tests)
                (intern "RUN-DMX-INCIDENT-GUARDED-WRITE-BOUNDARY-SMOKE-TEST"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun dmx-incident-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-dmx-incident-page (namestring)
  (uiop:read-file-string
   (dmx-incident-relative-path namestring)))

(defun normalize-whitespace-for-smoke (string)
  (with-output-to-string (stream)
    (loop with pending-space = nil
          with wrote-char = nil
          for char across string
          do (if (find char '(#\Space #\Tab #\Newline #\Return))
                 (setf pending-space t)
                 (progn
                   (when pending-space
                     (when wrote-char
                       (write-char #\Space stream))
                     (setf pending-space nil))
                   (write-char char stream)
                   (setf wrote-char t))))))

(defun assert-page-contains-all (page-source page-label needles)
  (let ((normalized-page-source
         (normalize-whitespace-for-smoke page-source)))
    (dolist (needle needles)
      (assert-true
       (search (normalize-whitespace-for-smoke needle)
               normalized-page-source
               :test #'char=)
       (format nil "~A must contain ~S" page-label needle)))))

(defun run-dmx-incident-documentation-pages-smoke-test ()
  (assert-page-contains-all
   (read-dmx-incident-page "hyperdoc/DMX topicmap 919822 repair runbook.html")
   "DMX topicmap 919822 repair runbook"
   '("NodeImpl#921471"
     "921404"
     "921471"
     "stale, external, or custom mutation"
     "generic DMX <tt>ViewProps</tt> endpoints can persist malformed"))
  (assert-page-contains-all
   (read-dmx-incident-page "hyperdoc/DMX FedWiki Write Model.html")
   "DMX FedWiki Write Model"
   '("valuable but untrusted persistence boundary"
     "dmx.topicmaps.x"
     "Forbidden short keys"
     "plan-topic-factory-snippet-dmx-write"
     "execute-topic-factory-snippet-dmx-write"
     "validated_dmx_write_dry_run"))
  (assert-page-contains-all
   (read-dmx-incident-page
    "hyperdoc/HyperDoc DMX architectural implications.html")
   "HyperDoc DMX architectural implications"
   '("generic DMX persistence boundaries cannot be assumed safe by default"
     "narrow typed normalized adapters"
     "Plan-first and dry-run-first behavior"
     "synchronizable/projected persistence"
     "shared blackboard"))
  (assert-page-contains-all
   (read-dmx-incident-page
    "hyperdoc/Localhost FedWiki page promotion workflow.html")
   "Localhost FedWiki page promotion workflow"
   '(":source-unavailable"
     "normalized topicmap view payload JSON"
     "synchronizable/projected"
     "guarded DMX boundary"
     "create_handover"))
  (assert-page-contains-all
   (read-dmx-incident-page
    "hyperdoc/DMX MCP server for shared workspace.html")
   "DMX MCP server for shared workspace"
   '("client -> DMX MCP server -> HyperDoc-side validated DMX adapter -> DMX backend"
     "workspace/context-window"
     "validated_dmx_write_dry_run"
     ".codex/config.toml"
     "Streamable HTTP"))
  (assert-page-contains-all
   (read-dmx-incident-page
    "hyperdoc/Context window workspace as shared blackboard.html")
   "Context window workspace as shared blackboard"
   '("shared blackboard"
     "topic 907120"
     "create_handover"
     "append_workspace_note"
     "simple durable history")))

(defun run-dmx-incident-topic-availability-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (entry '((hyperdoc::dmx-fedwiki-write-model-topic
                    "DMX FedWiki Write Model")
                   (hyperdoc::dmx-mcp-server-shared-workspace-topic
                    "DMX MCP server for shared workspace")
                   (hyperdoc::context-window-workspace-shared-blackboard-topic
                    "Context window workspace as shared blackboard")
                   (hyperdoc::dmx-topicmap-919822-repair-runbook-topic
                    "DMX topicmap 919822 repair runbook")
                   (hyperdoc::hyperdoc-dmx-architectural-implications-topic
                    "HyperDoc DMX architectural implications")
                   (hyperdoc::localhost-fedwiki-page-promotion-workflow-topic
                    "Localhost FedWiki page promotion workflow")
                   (hyperdoc::the-life-cycle-of-collective-knowledge-topic
                    "The Life Cycle of Collective Knowledge")
                   (hyperdoc::reproducible-devenv-as-knowledge-artifact-topic
                    "Reproducible DevEnv as Knowledge Artifact")))
    (destructuring-bind (symbol title) entry
      (assert-true (fboundp symbol)
                   (format nil "Missing topic function ~A" symbol))
      (let ((topic (funcall symbol)))
        (assert-equal title
                      (hyperbook:title-of topic)
                      (format nil "Topic ~A title" symbol))
        (assert-true
         (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
         (format nil "Missing Topics HyperBook page ~A" title)))))
  (dolist (page-title '("DMX topicmap 919822 repair runbook"
                        "DMX FedWiki Write Model"
                        "DMX MCP server for shared workspace"
                        "Context window workspace as shared blackboard"
                        "HyperDoc DMX architectural implications"
                        "Localhost FedWiki page promotion workflow"))
    (assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* page-title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" page-title))))

(defun dmx-incident-collective-knowledge-fixture-page-path ()
  (asdf:system-relative-pathname
   :hyperdoc
   "tools/testdata/collective-knowledge-slice/pages/the-life-cycle-of-collective-knowledge"))

(defun call-with-dmx-incident-collective-knowledge-source-fixture (thunk)
  (let* ((symbol
          'hyperdoc::the-life-cycle-of-collective-knowledge-page-pipeline-spec)
         (original (symbol-function symbol))
         (fixture-path (dmx-incident-collective-knowledge-fixture-page-path)))
    (assert-true
     (uiop:file-exists-p fixture-path)
     (format nil "Collective-knowledge fixture missing at ~A"
             fixture-path))
    (unwind-protect
         (progn
           (setf (symbol-function symbol)
                 (lambda ()
                   (let ((spec (funcall original)))
                     (setf (hyperdoc::localhost-fedwiki-page-pipeline-spec-page-reader
                            spec)
                           (lambda ()
                             (hyperdoc::article-allegation-read-json-file
                              fixture-path)))
                     spec)))
           (funcall thunk))
      (setf (symbol-function symbol) original))))

(defun run-dmx-incident-guarded-write-boundary-smoke-test ()
  (call-with-dmx-incident-collective-knowledge-source-fixture
   (lambda ()
     (let* ((healthy-plan
             (hyperdoc::reproducible-devenv-as-knowledge-artifact-promotion-plan))
            (summary
             (hyperdoc::localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary
              healthy-plan))
            (evidence
             (hyperdoc::localhost-fedwiki-page-promotion-plan-dmx-dry-run-evidence
              healthy-plan))
            (handover-summary
             (hyperdoc::localhost-fedwiki-page-promotion-handover-dmx-write-summary))
            (handover-evidence
             (hyperdoc::localhost-fedwiki-page-promotion-handover-dmx-write-evidence)))
       (assert-true (getf summary :available)
                    "Healthy promotion plan must keep DMX dry-run available")
       (assert-equal :canonical
                     (getf summary :view-props-validation-status)
                     "Healthy promotion plan must expose canonical view-props validation")
       (assert-equal nil
                     (getf summary :forbidden-short-keys)
                     "Healthy promotion plan must expose no forbidden short keys")
       (assert-true
        (search "\"dmx.topicmaps.x\"" (getf summary :normalized-view-props-json))
        "Healthy promotion plan must expose long-form x in the normalized payload")
       (assert-true
        (not (search "\"x\":" (getf summary :normalized-view-props-json)))
        "Healthy promotion plan must not expose forbidden short x in the normalized payload")
       (assert-true
        (search "TOPIC_FACTORY_SNIPPET_DMX_VIEW_VALIDATION status=CANONICAL"
                evidence)
        "Healthy promotion plan dry-run evidence must expose canonical validation")
       (assert-true
        (search "TOPIC_FACTORY_SNIPPET_DMX_VIEW_PAYLOAD {\"dmx.topicmaps.x\""
                evidence)
        "Healthy promotion plan dry-run evidence must expose the normalized long-form payload")
       (assert-true (getf handover-summary :available)
                    "Workflow handover DMX dry-run summary must remain available")
       (assert-equal :canonical
                     (getf handover-summary :view-props-validation-status)
                     "Workflow handover DMX dry-run summary must expose canonical validation")
       (assert-true
        (search "\"dmx.topicmaps.x\"" (getf handover-summary :normalized-view-props-json))
        "Workflow handover DMX dry-run summary must expose the normalized long-form payload")
       (assert-true
        (search "TOPIC_FACTORY_SNIPPET_DMX_VIEW_VALIDATION status=CANONICAL"
                handover-evidence)
        "Workflow handover DMX dry-run evidence must expose canonical validation")))))

(defun run-dmx-incident-arc-smoke-tests ()
  (run-dmx-incident-documentation-pages-smoke-test)
  (run-dmx-incident-topic-availability-smoke-test)
  (run-dmx-incident-guarded-write-boundary-smoke-test)
  (format t "~&DMX incident arc smoke tests passed.~%")
  t)
