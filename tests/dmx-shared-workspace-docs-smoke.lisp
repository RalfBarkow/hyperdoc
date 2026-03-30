;;;; Focused smoke tests for the DMX shared-workspace documentation cluster
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DMX-SHARED-WORKSPACE-DOCS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun dmx-shared-workspace-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-dmx-shared-workspace-page (namestring)
  (uiop:read-file-string
   (dmx-shared-workspace-relative-path namestring)))

(defun normalize-dmx-shared-workspace-smoke-whitespace (string)
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

(defun assert-shared-workspace-page-contains-all (page-source page-label needles)
  (let ((normalized-page-source
          (normalize-dmx-shared-workspace-smoke-whitespace page-source)))
    (dolist (needle needles)
      (assert-true
       (search (normalize-dmx-shared-workspace-smoke-whitespace needle)
               normalized-page-source
               :test #'char=)
       (format nil "~A must contain ~S" page-label needle)))))

(defun run-dmx-shared-workspace-documentation-pages-smoke-test ()
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX MCP server for shared workspace.html")
   "DMX MCP server for shared workspace"
   '("workspace/context-window"
     "read_dmx_topicmap"
     "read_dmx_topic"
     "resolve_workspace_note"
     "append_workspace_note"
     "update_workspace_note"
     "delete_workspace_note"
     "delete_workspace_topic"
     "upsert_workspace_topicmap_context"
     "remove_workspace_topic_from_topicmap"
     "upsert_workspace_topic_factory_snippet"
     "topicmap_context_upsert"
     "topicmap_context_remove"
     "Hard delete is limited by ownership checks"
     "live HTTP unlink remains intentionally unsupported"
     "remote HTTPS"
     "developer mode"
     "publish or refresh a custom app/connector"
     "create_handover"
     "generic raw DMX JSON write"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Context window workspace as shared blackboard.html")
   "Context window workspace as shared blackboard"
   '("topicmap 919822"
     "context-window"
     "me, ChatGPT, and Codex"
     "raw transcript archive"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX note read-write boundary.html")
   "DMX note read/write boundary"
   '("dmx.notes.note"
     "dmx.notes.text"
     "The text child is replaced"
     "cache-busting or no-cache semantics"
     "append_workspace_note"
     "delete_workspace_note"
     "/core/topic/&lt;id&gt;"
     "existing-topic-id"
     "HyperDoc-created notes whose preserved URI"
     "uri=\"\""
     "topicmap_context_add"
     "topicmap_context_upsert"
     "topicmap_context_remove"
     "Live HTTP unlink is still intentionally unsupported"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX machine-readable read paths.html")
   "DMX machine-readable read paths"
   '("/core/topic/&lt;id&gt;?children=true&amp;assocChildren=true"
     "/topicmaps/&lt;id&gt;?children=true"
     "webclient hash routes"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Shared-workspace collaboration model.html")
   "Shared-workspace collaboration model"
   '("me, ChatGPT, and Codex"
     "curated shared blackboard"
     "HyperDoc remains the durable reference"
     "MCP server is the typed machine-facing boundary"
     "ownership-limited delete"
     "live topicmap unlink as unsupported"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX FedWiki Write Model.html")
   "DMX FedWiki Write Model"
   '("DMX note read/write boundary"
     "DMX machine-readable read paths"
     "DMX MCP server for shared workspace"
     "topicmap_context_upsert"
     "delete_workspace_topic"
     "OPTIONS /core/topic/&lt;id&gt;"
     "No archive or tombstone mutation contract is claimed yet"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX topicmap 919822 repair runbook.html")
   "DMX topicmap 919822 repair runbook"
   '("OPTIONS /core/topic/&lt;id&gt;"
     "DELETE /topicmaps/&lt;topicmap&gt;/topic/&lt;topic&gt;"
     "dry-run-first and non-live over HTTP"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Using guarded workspace topic lifecycle tools.html")
   "Using guarded workspace topic lifecycle tools"
   '("upsert_workspace_topic_factory_snippet"
     "Diagnosing DMX workspace assignment and topicmap placement"
     "upsert_workspace_topicmap_context"
     "remove_workspace_topic_from_topicmap"
     "delete_workspace_note"
     "delete_workspace_topic"
     "validated_dmx_write_dry_run"
     "read_dmx_topicmap"
     "read_dmx_topic"
     "dry-run-first"
     "HyperDoc-owned workspace notes, handovers, and topic-factory snippet twins"
     "topicmapId = 919822"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Operational definition: chunk, chunk note, manifest note, content topic.html")
   "Operational definition: chunk, chunk note, manifest note, content topic"
   '("make-operational-definition-note-proxy"
     "Workspace diagnostics"
     "Repair console"
     "922980"
     "reminder note"
     "922464"
     "919822"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Diagnosing DMX workspace assignment and topicmap placement.html")
   "Diagnosing DMX workspace assignment and topicmap placement"
   '("Workspace diagnostics"
     "make-operational-definition-note-proxy"
     "Diagnosing DMX workspace repair triage"
     "Using authenticated workspace assignment repair console"
     "workspace assignment"
     "topicmap placement"
     "919815"
     "919822"
     "922464"
     "922586"
     "922451"
      "repair_workspace_topic_assignment"
     "Diagnosis remains read-only and needs no login"
     "Repair console"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Diagnosing DMX workspace repair triage.html")
   "Diagnosing DMX workspace repair triage"
   '("Repair triage"
     "/topicmaps/919822?children=true"
     "HyperDoc-owned"
     "workspace assignment missing"
     "922464"
     "922479"
     "922500"
     "922515"
     "922532"
     "922565"
     "922586"
     "922451"
      "read-only"
     "make-dmx-shared-workspace-repair-triage"
     "Repair console"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Using authenticated workspace assignment repair console.html")
   "Using authenticated workspace assignment repair console"
   '("Repair console"
     "Operational definition: chunk, chunk note, manifest note, content topic"
     "make-operational-definition-note-proxy"
     "username/password"
     "authorization header"
     "bearer token"
     "ephemeral"
     "919815"
     "919822"
     "922464"
     "922586"
     "922451"
     "selected topic"
     "backlog"
     "execute-dmx-workspace-topic-workspace-assignment-repair"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Inspectable authentication-path traces for repair console.html")
   "Inspectable authentication-path traces for repair console"
   '("Authentication state machine"
     "make-operational-definition-note-proxy"
     "POST /access-control/login"
     "JSESSIONID"
     "PUT /workspaces/919815/object/922464"
     "username/password"
     "authorization header"
     "bearer token"
     "result readback refreshed"
     "922464"
     "922586"
     "http://127.0.0.1:8080/boot.html"
     "401"
     "same credentials succeed anywhere else"
     "DMX webclient login trace"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/HyperDoc DMX architectural implications.html")
   "HyperDoc DMX architectural implications"
   '("Context window workspace as shared blackboard"
     "Shared-workspace collaboration model"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Localhost FedWiki page promotion workflow.html")
   "Localhost FedWiki page promotion workflow"
   '("DMX MCP server for shared workspace"
     "Context window workspace as shared blackboard"
     "DMX note read/write boundary")))

(defun run-dmx-shared-workspace-topic-availability-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (entry '((hyperdoc::dmx-mcp-server-for-shared-workspace-topic
                    "DMX MCP server for shared workspace")
                   (hyperdoc::context-window-workspace-as-shared-blackboard-topic
                    "Context window workspace as shared blackboard")
                   (hyperdoc::dmx-note-read-write-boundary-topic
                   "DMX note read/write boundary")
                   (hyperdoc::dmx-machine-readable-read-paths-topic
                   "DMX machine-readable read paths")
                   (hyperdoc::shared-workspace-collaboration-model-topic
                   "Shared-workspace collaboration model")
                   (hyperdoc::using-guarded-workspace-topic-lifecycle-tools-topic
                    "Using guarded workspace topic lifecycle tools")
                   (hyperdoc::diagnosing-dmx-workspace-assignment-and-topicmap-placement-topic
                    "Diagnosing DMX workspace assignment and topicmap placement")
                   (hyperdoc::diagnosing-dmx-workspace-repair-triage-topic
                    "Diagnosing DMX workspace repair triage")
                   (hyperdoc::using-authenticated-workspace-assignment-repair-console-topic
                    "Using authenticated workspace assignment repair console")
                   (hyperdoc::operational-definition-chunk-chunk-note-manifest-note-content-topic
                    "Operational definition: chunk, chunk note, manifest note, content topic")
                   (hyperdoc::inspectable-authentication-path-traces-for-repair-console-topic
                    "Inspectable authentication-path traces for repair console")))
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
  (dolist (page-title '("DMX MCP server for shared workspace"
                        "Context window workspace as shared blackboard"
                        "DMX note read/write boundary"
                        "DMX machine-readable read paths"
                        "Shared-workspace collaboration model"
                        "Using guarded workspace topic lifecycle tools"
                        "Diagnosing DMX workspace assignment and topicmap placement"
                        "Diagnosing DMX workspace repair triage"
                        "Using authenticated workspace assignment repair console"
                        "Operational definition: chunk, chunk note, manifest note, content topic"
                        "Inspectable authentication-path traces for repair console"))
    (assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* page-title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" page-title))))

(defun run-dmx-shared-workspace-docs-smoke-tests ()
  (run-dmx-shared-workspace-documentation-pages-smoke-test)
  (run-dmx-shared-workspace-topic-availability-smoke-test)
  (format t "~&DMX shared-workspace docs smoke tests passed.~%")
  t)
