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

(defun dmx-shared-workspace-docs-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun dmx-shared-workspace-docs-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

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
     "read_workspace_journal"
     "read_topic_journal"
     "list_workspace_topic_revisions"
     "restore_workspace_topic_revision"
     "restore_workspace_note_revision"
     "topicmap_context_upsert"
     "topicmap_context_remove"
     "Hard delete is limited by ownership checks"
     "journalTopicCount"
     "journal-event-preview"
     "synthesized-from-diff"
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
     "DMX workspace journal model"
     "How to work safely in topicmap context-window (919822)"
     "restore_workspace_note_revision"
     "synthesized-from-diff"
     "raw transcript archive"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/How to work safely in topicmap context-window (919822).html")
   "How to work safely in topicmap context-window (919822)"
   '("topicmap 919822"
     "context-window"
     "shared blackboard"
     "not a generic DMX mutation playground"
     "guarded shared-workspace boundary"
     "workspace assignment"
     "topicmap placement"
     "dry-run-first"
     "Do not treat topicmap visibility as ownership."
     "Do not treat the workspace as a raw transcript archive"
     "continue_workspace_annotation"
     "repair_workspace_topic_assignment"
     "922464"
     "922586"
     "922451"
     "DMX MCP server for shared workspace"
     "Using guarded workspace topic lifecycle tools"
     "Using authenticated workspace assignment repair console"))
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
     "note-create"
     "note-archive"
     "restore_workspace_note_revision"
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
     "read_workspace_journal"
     "synthesized-from-diff"
     "explicit action"
     "ownership-limited delete"
     "live topicmap unlink as unsupported"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX FedWiki Write Model.html")
   "DMX FedWiki Write Model"
   '("DMX note read/write boundary"
     "DMX machine-readable read paths"
     "DMX MCP server for shared workspace"
     "DMX workspace journal model"
     "topicmap_context_upsert"
     "delete_workspace_topic"
     "companion-workspace-note"
     "OPTIONS /core/topic/&lt;id&gt;"
     "No archive or tombstone mutation contract is claimed yet"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX workspace journal model.html")
   "DMX workspace journal model"
   '("companion-workspace-note"
     "hyperdoc:mcp/workspace-journal/"
     "archive-topic"
     "note-archive"
     "synthesized-from-diff"
     "read_workspace_journal"
     "read_topic_journal"
     "restore_workspace_topic_revision"
     "restore_workspace_note_revision"
     "not expose a raw \"write arbitrary journal event\" tool"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/FedWiki Journal Tools in HyperDoc.html")
   "FedWiki Journal Tools in HyperDoc"
   '("DMX workspace journal model"
     "companion-workspace-note"
     "synthesized-from-diff"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/Journalmatic Revision Replay.html")
   "Journalmatic Revision Replay"
   '("DMX workspace journal model"
     "restore_workspace_topic_revision"
     "restore_workspace_note_revision"
     "synthesized-from-diff"))
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
   '("continue_workspace_annotation"
     "repair_workspace_topic_assignment"
     "upsert_workspace_topic_factory_snippet"
     "Diagnosing DMX workspace assignment and topicmap placement"
     "How to work safely in topicmap context-window (919822)"
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
    "hyperdoc/Workspace-native annotations in a DMX workspace.html")
   "Workspace-native annotations in a DMX workspace"
   '("Compare with guarded workspace path"
     "How to work safely in topicmap context-window (919822)"
     "workspace assignment"
     "topicmap placement"
     "workspace-dock-annotation"))
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
     "919822"
     "HyperDoc three-mode DMX auth crosswalk"
     "DMX Credentials"
     "DMX AuthorizationMethod"
     "DMX session bootstrap and JSESSIONID"))
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
     "How to work safely in topicmap context-window (919822)"
     "Operational definition: chunk, chunk note, manifest note, content topic"
     "make-operational-definition-note-proxy"
     "username/password"
     "authorization header"
     "bearer token"
     "ephemeral"
     "HyperDoc three-mode DMX auth crosswalk"
     "DMX session bootstrap and JSESSIONID"
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
     "dmx-auth-path-example"
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
     "HyperDoc three-mode DMX auth crosswalk"
     "DMX Credentials"
     "DMX AuthorizationMethod"
     "DMX AnonymousAccessFilter"
     "DMX Authorization header to Credentials path"
     "DMX session bootstrap and JSESSIONID"
     "DMX webclient login trace"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX Credentials.html")
   "DMX Credentials"
   '("Credentials(String authHeader)"
     "dmx-auth-path-example"
     "username"
     "password"
     "methodName"
     "Basic YWxpY2U6ZXhhbXBsZS1wYXNzd29yZA=="
     "HyperDoc three-mode DMX auth crosswalk"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX AuthorizationMethod.html")
   "DMX AuthorizationMethod"
   '("checkCredentials(Credentials cred)"
     "non-Basic"
     "installation-dependent"
     "bearer token"
     "DMX backend contract"
     "HyperDoc three-mode DMX auth crosswalk"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX AnonymousAccessFilter.html")
   "DMX AnonymousAccessFilter"
   '("isAnonymousAccessAllowed(HttpServletRequest request)"
     "read-prefix and write-prefix settings"
     "guarded repair"
     "anonymous"
     "HyperDoc three-mode DMX auth crosswalk"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX Authorization header to Credentials path.html")
   "DMX Authorization header to Credentials path"
   '("Credentials(authHeader)"
     "AuthorizationMethod"
     "AnonymousAccessFilter"
     "attaches the username to the servlet session"
     "HyperDoc three-mode DMX auth crosswalk"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX session bootstrap and JSESSIONID.html")
   "DMX session bootstrap and JSESSIONID"
   '("POST /access-control/login"
     "dmx-auth-path-example"
     "JSESSIONID"
     "Cookie: JSESSIONID=&lt;session-id&gt;; dmx_workspace_id=919815"
     "not a fourth input mode"
     "HyperDoc three-mode DMX auth crosswalk"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/HyperDoc three-mode DMX auth crosswalk.html")
   "HyperDoc three-mode DMX auth crosswalk"
   '("username/password"
     "authorization header"
     "bearer token"
     "dmx-auth-path-example"
     "alice"
     "example-password"
     "Basic YWxpY2U6ZXhhbXBsZS1wYXNzd29yZA=="
     "eyJhbGciOi...example"
     "Operational definition: chunk, chunk note, manifest note, content topic"
     "Using authenticated workspace assignment repair console"
     "Inspectable authentication-path traces for repair console"
     "DMX MCP server for shared workspace"
     "Workspace-native annotations in a DMX workspace"))
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
                   (hyperdoc::how-to-work-safely-in-topicmap-context-window-919822-topic
                    "How to work safely in topicmap context-window (919822)")
                   (hyperdoc::dmx-workspace-journal-model-topic
                    "DMX workspace journal model")
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
                   (hyperdoc::dmx-credentials-topic
                    "DMX Credentials")
                   (hyperdoc::dmx-authorizationmethod-topic
                    "DMX AuthorizationMethod")
                   (hyperdoc::dmx-anonymousaccessfilter-topic
                    "DMX AnonymousAccessFilter")
                   (hyperdoc::dmx-authorization-header-to-credentials-path-topic
                    "DMX Authorization header to Credentials path")
                   (hyperdoc::dmx-session-bootstrap-and-jsessionid-topic
                    "DMX session bootstrap and JSESSIONID")
                   (hyperdoc::hyperdoc-three-mode-dmx-auth-crosswalk-topic
                    "HyperDoc three-mode DMX auth crosswalk")
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
                        "How to work safely in topicmap context-window (919822)"
                        "DMX workspace journal model"
                        "DMX note read/write boundary"
                        "DMX machine-readable read paths"
                        "Shared-workspace collaboration model"
                        "Using guarded workspace topic lifecycle tools"
                        "Diagnosing DMX workspace assignment and topicmap placement"
                        "Diagnosing DMX workspace repair triage"
                        "Using authenticated workspace assignment repair console"
                        "Operational definition: chunk, chunk note, manifest note, content topic"
                        "DMX Credentials"
                        "DMX AuthorizationMethod"
                        "DMX AnonymousAccessFilter"
                        "DMX Authorization header to Credentials path"
                        "DMX session bootstrap and JSESSIONID"
                        "HyperDoc three-mode DMX auth crosswalk"
                        "Inspectable authentication-path traces for repair console"))
    (assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* page-title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" page-title))))

(defun run-dmx-auth-crosswalk-render-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((crosswalk (hyperdoc::make-dmx-auth-crosswalk))
         (basic (hyperdoc::dmx-auth-crosswalk-username-password-example))
         (header (hyperdoc::dmx-auth-crosswalk-authorization-header-example))
         (token (hyperdoc::dmx-auth-crosswalk-bearer-token-example))
         (crosswalk-views
           (dmx-shared-workspace-docs-load-inspector-views-for-object crosswalk))
         (basic-views
           (dmx-shared-workspace-docs-load-inspector-views-for-object basic))
         (header-views
           (dmx-shared-workspace-docs-load-inspector-views-for-object header))
         (token-views
           (dmx-shared-workspace-docs-load-inspector-views-for-object token))
         (crosswalk-overview
           (dmx-shared-workspace-docs-find-view-by-title crosswalk-views "Overview"))
         (crosswalk-credentials
           (dmx-shared-workspace-docs-find-view-by-title
            crosswalk-views
            "Credentials crosswalk"))
         (basic-overview
           (dmx-shared-workspace-docs-find-view-by-title basic-views "Overview"))
         (basic-state-machine
           (dmx-shared-workspace-docs-find-view-by-title
            basic-views
            "State machine"))
         (basic-derived
           (dmx-shared-workspace-docs-find-view-by-title
            basic-views
            "Derived request shapes"))
         (basic-credentials
           (dmx-shared-workspace-docs-find-view-by-title
            basic-views
            "Credentials crosswalk"))
         (basic-contract-notes
           (dmx-shared-workspace-docs-find-view-by-title
            basic-views
            "DMX backend contract"))
         (basic-source
           (dmx-shared-workspace-docs-find-view-by-title
            basic-views
            "Source evidence / code path"))
         (header-overview
           (dmx-shared-workspace-docs-find-view-by-title header-views "Overview"))
         (token-contract-notes
           (dmx-shared-workspace-docs-find-view-by-title
            token-views
            "DMX backend contract")))
    (assert-type 'hyperdoc::dmx-auth-path-example
                 basic
                 "Username/password example must now be a first-class dmx-auth-path-example")
    (assert-type 'hyperdoc::dmx-auth-path-example
                 header
                 "Authorization-header example must now be a first-class dmx-auth-path-example")
    (assert-type 'hyperdoc::dmx-auth-path-example
                 token
                 "Bearer-token example must now be a first-class dmx-auth-path-example")
    (dolist (view (list crosswalk-overview
                        crosswalk-credentials
                        basic-overview
                        basic-state-machine
                        basic-derived
                        basic-credentials
                        basic-contract-notes
                        basic-source
                        header-overview
                        token-contract-notes))
      (assert-true view "DMX auth crosswalk render smoke must expose all expected views"))
    (assert-shared-workspace-page-contains-all
     (html-inspector-views:view-html crosswalk-overview)
     "DMX auth crosswalk overview view"
     '("username/password"
       "authorization header"
       "bearer token"))
    (assert-shared-workspace-page-contains-all
     (html-inspector-views:view-html basic-credentials)
     "DMX username/password example credentials crosswalk"
     '("Basic YWxpY2U6ZXhhbXBsZS1wYXNzd29yZA=="
       "alice"
       "example-password"))
    (assert-shared-workspace-page-contains-all
     (html-inspector-views:view-html basic-derived)
     "DMX username/password example derived request shapes"
     '("JSESSIONID"
       "dmx_workspace_id=919815"))
    (assert-shared-workspace-page-contains-all
     (html-inspector-views:view-html basic-overview)
     "DMX username/password example overview"
     '("Basic"
       "username/password"))
    (assert-shared-workspace-page-contains-all
     (html-inspector-views:view-html header-overview)
     "DMX authorization-header example overview"
     '("Basic"
       "authorization header"))
    (assert-shared-workspace-page-contains-all
     (html-inspector-views:view-html token-contract-notes)
     "DMX bearer-token example backend contract notes"
     '("Installation-dependent"
       "registered non-Basic AuthorizationMethod"))))

(defun run-dmx-shared-workspace-source-view-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    "Workspace-native annotations in a DMX workspace"
                                    :signal-error? t))
         (views (dmx-shared-workspace-docs-load-inspector-views-for-object page))
         (source-view (dmx-shared-workspace-docs-find-view-by-title views "Source"))
         (source-html (and source-view
                           (html-inspector-views:view-html source-view))))
    (assert-true source-view
                 "Workspace-native annotations page must expose a Source view")
    (assert (search "hyperdoc-source-connect-view" source-html :test #'char=)
            ()
            "HTML-page Source must use the shared source-surface wrapper")
    (assert (search "hyperdoc-source-connect-line-number" source-html :test #'char=)
            ()
            "HTML-page Source must render line numbers")
    (assert (search "&lt;h1&gt;Workspace-native annotations in a DMX workspace&lt;/h1&gt;"
                    source-html
                    :test #'char=)
            ()
            "HTML-page Source must render escaped source lines inside the shared source surface")))

(defun run-dmx-shared-workspace-docs-smoke-tests ()
  (run-dmx-shared-workspace-documentation-pages-smoke-test)
  (run-dmx-shared-workspace-topic-availability-smoke-test)
  (run-dmx-auth-crosswalk-render-smoke-test)
  (run-dmx-shared-workspace-source-view-smoke-test)
  (format t "~&DMX shared-workspace docs smoke tests passed.~%")
  t)
