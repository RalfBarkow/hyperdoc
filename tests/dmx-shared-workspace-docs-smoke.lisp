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

(defun run-dmx-mcp-server-shared-workspace-doc-smoke-test ()
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
     "public workspace/topicmap projection shape"
     "journal-event-preview"
     "synthesized-from-diff"
     "live HTTP unlink remains intentionally unsupported"
     "remote HTTPS"
     "developer mode"
     "publish or refresh a custom app/connector"
     "create_handover"
     "generic raw DMX JSON write")))

(defun run-dmx-shared-workspace-documentation-pages-smoke-test ()
  (run-dmx-mcp-server-shared-workspace-doc-smoke-test)
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
     "Resolution section"
     "operational absences"
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
     "in-topicmap-but-unassigned"
     "credentials-pending"
     "workspace-annotation/"
     "workspace-journal/"
     "401"
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
     "healthy"
     "foreign-no-action"
     "in-topicmap-but-unassigned"
     "credentials-pending"
     "repair-succeeded"
     "repair-failed-non-auth"
     "workspace-annotation/"
     "workspace-journal/"
     "401"
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
     "in-topicmap-but-unassigned"
     "primary live repair boundary"
     "credentials-pending"
     "401"
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
     "in-topicmap-but-unassigned"
     "credentials-pending"
     "401"
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

(defun assert-connectable-page-source-view (page-title expected-source-snippet)
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (strategy (hyperdoc::source-surface-strategy-for page))
         (effective-strategy
           (hyperdoc::effective-source-surface-strategy-for page))
         (views (dmx-shared-workspace-docs-load-inspector-views-for-object page))
         (source-view (dmx-shared-workspace-docs-find-view-by-title views "Source"))
         (source-html (and source-view
                           (html-inspector-views:view-html source-view))))
    (assert-type 'hyperdoc::connect-source-surface-strategy
                 strategy
                 (format nil "~A must keep the connect Source strategy"
                         page-title))
    (assert-type 'hyperdoc::connect-source-surface-strategy
                 effective-strategy
                 (format nil "~A effective Source strategy must stay connect"
                         page-title))
    (assert-true (hyperdoc::source-surface-connect-capable-p strategy)
                 (format nil "~A Source strategy must stay connect-capable"
                         page-title))
    (assert-true (hyperdoc::source-surface-connect-capable-p effective-strategy)
                 (format nil "~A effective Source strategy must stay connect-capable"
                         page-title))
    (assert-true source-view
                 (format nil "~A must expose a Source view" page-title))
    (assert (search "hyperdoc-dom-connect-surface" source-html :test #'char=)
            ()
            (format nil "~A Source must render the connectable surface shell"
                    page-title))
    (assert (search "hyperdoc-connect-provider-surface" source-html :test #'char=)
            ()
            (format nil "~A Source must expose the connect-provider surface"
                    page-title))
    (assert (search "hyperdoc-source-pane" source-html :test #'char=)
            ()
            (format nil "~A Source must render the source-pane body wrapper"
                    page-title))
    (assert (search "hyperdoc-source-connect-view" source-html :test #'char=)
            ()
            (format nil "~A Source must render the source-connect view"
                    page-title))
    (assert (search "hyperdoc-source-connect-line-number" source-html :test #'char=)
            ()
            (format nil "~A Source must render source line numbers"
                    page-title))
    (assert (search "data-hyperdoc-connect-source-anchor"
                    source-html
                    :test #'char=)
            ()
            (format nil "~A Source must render source anchor lines"
                    page-title))
    (assert (search expected-source-snippet source-html :test #'char=)
            ()
            (format nil "~A Source must render escaped source text"
                    page-title))
    (assert (search "data-hyperdoc-connect-provider-kind='source-v1'"
                    source-html
                    :test #'char=)
            ()
            (format nil "~A Source must keep source-v1 provider metadata"
                    page-title))))

(defun run-dmx-shared-workspace-source-view-smoke-test ()
  (assert-connectable-page-source-view
   "Workspace-native annotations in a DMX workspace"
   "&lt;h1&gt;Workspace-native annotations in a DMX workspace&lt;/h1&gt;")
  (assert-connectable-page-source-view
   "A DOM-annotation connect gesture"
   "# A DOM-annotation connect gesture"))

(defun run-source-surface-strategy-override-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (expected-source-snippet
           "&lt;h1&gt;Workspace-native annotations in a DMX workspace&lt;/h1&gt;")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (default-strategy
           (hyperdoc::effective-source-surface-strategy-for page)))
    (assert-type 'hyperdoc::connect-source-surface-strategy
                 default-strategy
                 (format nil "~A default effective strategy must stay connect"
                         page-title))
    (assert-true (hyperdoc::source-surface-connect-capable-p default-strategy)
                 (format nil "~A default effective strategy must stay connect-capable"
                         page-title))
    (hyperdoc::with-source-surface-strategy-override (:plain)
      (let* ((override-strategy
               (hyperdoc::effective-source-surface-strategy-for page))
             (source-view (hyperdoc::render-source-surface-for-page page))
             (source-html (html-inspector-views:view-html source-view)))
        (assert-type 'hyperdoc::plain-source-surface-strategy
                     override-strategy
                     (format nil "~A override must select the plain strategy"
                             page-title))
        (assert-true (not (hyperdoc::source-surface-connect-capable-p
                           override-strategy))
                     (format nil "~A plain override must not be connect-capable"
                             page-title))
        (assert-true (search "hyperdoc-source-pane" source-html :test #'char=)
                     (format nil "~A plain override must still render the source pane"
                             page-title))
        (assert-true (search "hyperdoc-source-pane-line-number"
                             source-html
                             :test #'char=)
                     (format nil "~A plain override must render numbered source lines"
                             page-title))
        (assert-true (search expected-source-snippet source-html :test #'char=)
                     (format nil "~A plain override must still render escaped source text"
                             page-title))
        (assert-true (null (search "hyperdoc-connect-provider-surface"
                                   source-html
                                   :test #'char=))
                     (format nil "~A plain override must suppress the connect-provider surface"
                             page-title))
        (assert-true
         (null (search "data-hyperdoc-connect-provider-kind='source-v1'"
                       source-html
                       :test #'char=))
         (format nil "~A plain override must suppress source-v1 provider metadata"
                 page-title))))))

(defun run-source-surface-strategy-class-policy-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (default-strategy
           (hyperdoc::effective-source-surface-strategy-for page)))
    (assert-type 'hyperdoc::connect-source-surface-strategy
                 default-strategy
                 (format nil "~A default effective strategy must stay connect"
                         page-title))
    (hyperdoc::with-source-surface-strategy-class-policy
        ('hyperdoc::text-page :plain)
      (let ((policy-strategy
              (hyperdoc::effective-source-surface-strategy-for page)))
        (assert-type 'hyperdoc::plain-source-surface-strategy
                     policy-strategy
                     (format nil "~A class policy must select the plain strategy"
                             page-title))
        (hyperdoc::with-source-surface-strategy-override (:connect)
          (let ((override-strategy
                  (hyperdoc::effective-source-surface-strategy-for page)))
            (assert-type 'hyperdoc::connect-source-surface-strategy
                         override-strategy
                         (format nil "~A dynamic override must win over class policy"
                                 page-title))
            (assert-true
             (hyperdoc::source-surface-connect-capable-p override-strategy)
             (format nil "~A connect override must remain connect-capable"
                     page-title))))))))

(defun run-source-surface-resolution-report-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (default-report
           (hyperdoc::source-surface-resolution-report-for page)))
    (assert-true (eq (getf default-report :target-class)
                     (class-name (class-of page)))
                 (format nil "~A report must expose the target class"
                         page-title))
    (assert-true (eq (getf default-report :winner) :default)
                 (format nil "~A default report must resolve through :default"
                         page-title))
    (assert-true (not (getf default-report :override-present-p))
                 (format nil "~A default report must not expose an override"
                         page-title))
    (assert-true (not (getf default-report :class-policy-matched-p))
                 (format nil "~A default report must not expose a class policy"
                         page-title))
    (assert-type 'hyperdoc::connect-source-surface-strategy
                 (getf default-report :default-strategy)
                 (format nil "~A default report must expose the connect default"
                         page-title))
    (assert-type 'hyperdoc::connect-source-surface-strategy
                 (getf default-report :effective-strategy)
                 (format nil "~A default report must expose the connect effective strategy"
                         page-title))
    (hyperdoc::with-source-surface-strategy-class-policy
        ('hyperdoc::text-page :plain)
      (let ((policy-report
              (hyperdoc::source-surface-resolution-report-for page)))
        (assert-true (eq (getf policy-report :winner) :class-policy)
                     (format nil "~A class policy report must resolve through :class-policy"
                             page-title))
        (assert-true (getf policy-report :class-policy-matched-p)
                     (format nil "~A class policy report must expose the class match"
                             page-title))
        (assert-true (eq (getf policy-report :class-policy-class)
                         'hyperdoc::text-page)
                     (format nil "~A class policy report must expose the matched class"
                             page-title))
        (assert-type 'hyperdoc::plain-source-surface-strategy
                     (getf policy-report :class-policy-strategy)
                     (format nil "~A class policy report must expose the plain strategy"
                             page-title))
        (assert-type 'hyperdoc::plain-source-surface-strategy
                     (getf policy-report :effective-strategy)
                     (format nil "~A class policy report must expose the plain effective strategy"
                             page-title))
        (hyperdoc::with-source-surface-strategy-override (:connect)
          (let ((override-report
                  (hyperdoc::source-surface-resolution-report-for page)))
            (assert-true (eq (getf override-report :winner) :override)
                         (format nil "~A override report must resolve through :override"
                                 page-title))
            (assert-true (getf override-report :override-present-p)
                         (format nil "~A override report must expose override presence"
                                 page-title))
            (assert-true (getf override-report :class-policy-matched-p)
                         (format nil "~A override report must still expose the matched class policy"
                                 page-title))
            (assert-type 'hyperdoc::connect-source-surface-strategy
                         (getf override-report :override-strategy)
                         (format nil "~A override report must expose the connect override"
                                 page-title))
            (assert-type 'hyperdoc::connect-source-surface-strategy
                         (getf override-report :effective-strategy)
                         (format nil "~A override report must expose the connect effective strategy"
                                 page-title))))))))

(defun run-source-surface-strategy-identity-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (default-report
           (hyperdoc::source-surface-resolution-report-for page)))
    (assert-equal :connect
                  (getf default-report :default-strategy-id)
                  (format nil "~A default report must expose the connect default id"
                          page-title))
    (assert-equal "Connect source"
                  (getf default-report :default-strategy-label)
                  (format nil "~A default report must expose the connect default label"
                          page-title))
    (assert-equal :connect
                  (getf default-report :effective-strategy-id)
                  (format nil "~A default report must expose the connect effective id"
                          page-title))
    (assert-equal "Connect source"
                  (getf default-report :effective-strategy-label)
                  (format nil "~A default report must expose the connect effective label"
                          page-title))
    (hyperdoc::with-source-surface-strategy-class-policy
        ('hyperdoc::text-page :plain)
      (let ((policy-report
              (hyperdoc::source-surface-resolution-report-for page)))
        (assert-equal :plain
                      (getf policy-report :class-policy-strategy-id)
                      (format nil "~A class policy report must expose the plain strategy id"
                              page-title))
        (assert-equal "Plain source"
                      (getf policy-report :class-policy-strategy-label)
                      (format nil "~A class policy report must expose the plain strategy label"
                              page-title))
        (assert-equal :plain
                      (getf policy-report :effective-strategy-id)
                      (format nil "~A class policy report must expose the plain effective id"
                              page-title))
        (assert-equal "Plain source"
                      (getf policy-report :effective-strategy-label)
                      (format nil "~A class policy report must expose the plain effective label"
                              page-title))
        (hyperdoc::with-source-surface-strategy-override (:connect)
          (let ((override-report
                  (hyperdoc::source-surface-resolution-report-for page)))
            (assert-equal :connect
                          (getf override-report :override-strategy-id)
                          (format nil "~A override report must expose the connect override id"
                                  page-title))
            (assert-equal "Connect source"
                          (getf override-report :override-strategy-label)
                          (format nil "~A override report must expose the connect override label"
                                  page-title))
            (assert-equal :plain
                          (getf override-report :class-policy-strategy-id)
                          (format nil "~A override report must still expose the plain class policy id"
                                  page-title))
            (assert-equal "Plain source"
                          (getf override-report :class-policy-strategy-label)
                          (format nil "~A override report must still expose the plain class policy label"
                                  page-title))
            (assert-equal :connect
                          (getf override-report :effective-strategy-id)
                          (format nil "~A override report must expose the connect effective id"
                                  page-title))
            (assert-equal "Connect source"
                          (getf override-report :effective-strategy-label)
                          (format nil "~A override report must expose the connect effective label"
                                  page-title))))))))

(defun run-source-surface-strategy-catalog-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((catalog (hyperdoc::source-surface-strategy-catalog))
         (connect-entry
           (find :connect catalog :key (lambda (entry) (getf entry :id))))
         (plain-entry
           (find :plain catalog :key (lambda (entry) (getf entry :id))))
         (page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (views (dmx-shared-workspace-docs-load-inspector-views-for-object page))
         (catalog-view
           (dmx-shared-workspace-docs-find-view-by-title views "Source strategies"))
         (catalog-html (and catalog-view
                            (html-inspector-views:view-html catalog-view))))
    (assert-true connect-entry
                 "Source strategy catalog must include the connect strategy")
    (assert-true plain-entry
                 "Source strategy catalog must include the plain strategy")
    (assert-equal "Connect source"
                  (getf connect-entry :label)
                  "Source strategy catalog must expose the connect label")
    (assert-equal t
                  (getf connect-entry :connect-capable-p)
                  "Source strategy catalog must expose connect as connect-capable")
    (assert-equal :connect
                  (getf connect-entry :designator)
                  "Source strategy catalog must expose the connect designator")
    (assert-equal "Plain source"
                  (getf plain-entry :label)
                  "Source strategy catalog must expose the plain label")
    (assert-equal nil
                  (getf plain-entry :connect-capable-p)
                  "Source strategy catalog must expose plain as non-connect-capable")
    (assert-equal :plain
                  (getf plain-entry :designator)
                  "Source strategy catalog must expose the plain designator")
    (assert-true catalog-view
                 (format nil "~A must expose a Source strategies view" page-title))
    (assert-shared-workspace-page-contains-all
     catalog-html
     (format nil "~A Source strategies view" page-title)
     '("Strategy id"
       "Label"
       "Connect-capable"
       "Designator"
       "connect"
       "plain"
       "Connect source"
       "Plain source"
       "yes"
       "no"))))

(defun run-source-surface-designator-rendering-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (connect-strategy
           (hyperdoc::source-surface-strategy-for-stable-designator :connect))
         (plain-symbol-strategy
           (hyperdoc::source-surface-strategy-for-stable-designator 'plain))
         (plain-strategy
           (hyperdoc::source-surface-strategy-for-stable-designator :plain))
         (connect-view
           (hyperdoc::render-source-surface-for-page-with-designator
            page
            :connect))
         (plain-view
           (hyperdoc::render-source-surface-for-page-with-designator
            page
            :plain))
         (connect-html (html-inspector-views:view-html connect-view))
         (plain-html (html-inspector-views:view-html plain-view)))
    (assert-true
     (hyperdoc::source-surface-designator-supported-p :connect)
     "Connect designator must be supported.")
    (assert-true
     (hyperdoc::source-surface-designator-supported-p :plain)
     "Plain designator must be supported.")
    (assert-true
     (hyperdoc::source-surface-designator-supported-p 'plain)
     "Symbolic plain designator must normalize to the supported plain path.")
    (assert-true
     (null (hyperdoc::source-surface-designator-supported-p :bogus))
     "Unknown Source designator must not be treated as supported.")
    (assert-type 'hyperdoc::connect-source-surface-strategy
                 connect-strategy
                 "Connect designator must resolve to the connect strategy.")
    (assert-type 'hyperdoc::plain-source-surface-strategy
                 plain-symbol-strategy
                 "Symbolic plain designator must resolve to the plain strategy.")
    (assert-type 'hyperdoc::plain-source-surface-strategy
                 plain-strategy
                 "Plain designator must resolve to the plain strategy.")
    (handler-case
        (progn
          (hyperdoc::source-surface-strategy-for-stable-designator :bogus)
          (error "Unknown Source designator must signal an error."))
      (error (condition)
        (assert-true
         (search "Unsupported Source surface designator"
                 (princ-to-string condition)
                 :test #'char=)
         "Unknown Source designator error must be explicit.")))
    (assert-true
     (search "source-v1" connect-html :test #'char=)
     "Connect designator rendering must use the connect path.")
    (assert-true
     (null (search "source-provider" plain-html :test #'char=))
     "Plain designator rendering must not expose connect provider metadata.")
    (assert-true
     (null (search "source-v1" plain-html :test #'char=))
     "Plain designator rendering must not expose the connect runtime contract.")))

(defun run-source-surface-swap-preview-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (preview (hyperdoc::make-source-surface-swap-preview page :plain))
         (plain-symbol-preview
           (hyperdoc::make-source-surface-swap-preview page 'plain))
         (unsupported-preview
           (hyperdoc::make-source-surface-swap-preview page :bogus))
         (views (dmx-shared-workspace-docs-load-inspector-views-for-object preview))
         (overview-view
           (dmx-shared-workspace-docs-find-view-by-title views "Overview"))
         (compare-view
           (dmx-shared-workspace-docs-find-view-by-title views "Compare"))
         (current-view
           (dmx-shared-workspace-docs-find-view-by-title views "Current Source"))
         (alternate-view
           (dmx-shared-workspace-docs-find-view-by-title views "Alternate Source"))
         (overview-html (and overview-view
                             (html-inspector-views:view-html overview-view)))
         (compare-html (and compare-view
                            (html-inspector-views:view-html compare-view)))
         (current-html (and current-view
                            (html-inspector-views:view-html current-view)))
         (alternate-html (and alternate-view
                              (html-inspector-views:view-html alternate-view)))
         (expected-alternate-html
           (html-inspector-views:view-html
            (hyperdoc::👀plain-source page))))
    (assert-type 'hyperdoc::source-surface-swap-preview
                 preview
                 "Swap preview must materialize as an inspectable object.")
    (assert-type 'hyperdoc::source-surface-swap-preview
                 plain-symbol-preview
                 "Symbolic plain swap preview must materialize as an inspectable object.")
    (assert-equal :connect
                  (hyperdoc::source-surface-swap-preview-current-designator-of
                   preview)
                  "Swap preview must snapshot the current connect designator.")
    (assert-equal :default
                  (getf (hyperdoc::source-surface-swap-preview-current-report-of
                         preview)
                        :winner)
                  "Swap preview must preserve the current default-resolution winner.")
    (assert-equal :plain
                  (hyperdoc::source-surface-swap-preview-alternate-designator-of
                   preview)
                  "Swap preview must retain the requested alternate designator.")
    (assert-equal :plain
                  (hyperdoc::source-surface-swap-preview-alternate-designator-of
                   plain-symbol-preview)
                  "Swap preview must normalize symbolic plain to the plain designator.")
    (assert-true
     (hyperdoc::source-surface-swap-preview-alternate-supported-p preview)
     "Plain alternate designator must be supported for swap preview.")
    (assert-true
     (hyperdoc::source-surface-swap-preview-alternate-supported-p
      plain-symbol-preview)
     "Symbolic plain alternate designator must stay supported for swap preview.")
    (assert-true
     (not (hyperdoc::source-surface-swap-preview-alternate-supported-p
           unsupported-preview))
     "Unsupported alternate designators must remain explicit on swap preview objects.")
    (dolist (view (list overview-view compare-view current-view alternate-view))
      (assert-true view
                   "Swap preview must expose overview, compare, current, and alternate views."))
    (assert-shared-workspace-page-contains-all
     overview-html
     (format nil "~A swap preview overview" page-title)
     '("Current winner"
       "Current Source path"
       "Requested alternate"
       "Alternate supported"
       "connect"
       "plain"
       "yes"))
    (assert-shared-workspace-page-contains-all
     compare-html
     (format nil "~A swap preview comparison" page-title)
     '("Path"
       "Current"
       "Alternate"
       "Connect source"
       "Plain source"
       "yes"
       "no"))
    (assert-true
     (search "data-hyperdoc-connect-provider-kind='source-v1'"
             current-html
             :test #'char=)
     "Swap preview current Source must keep the connect runtime contract.")
    (assert-true
     (string= alternate-html expected-alternate-html)
     "Swap preview alternate Source must render the actual text-page Plain source definition.")
    (assert-true
     (not (string= current-html alternate-html))
     "Swap preview current and alternate Source views must remain different renderings of the same page.")
    (assert-true
     (search "hyperdoc-source-pane" alternate-html :test #'char=)
     "Swap preview alternate Source must render the plain source pane.")
    (assert-true
     (search "hyperdoc-source-pane-line-number" alternate-html :test #'char=)
     "Swap preview alternate Source must render line-numbered plain source content.")
    (assert-true
     (null (search "data-hyperdoc-connect-provider-kind='source-v1'"
                   alternate-html
                   :test #'char=))
     "Swap preview alternate Source must suppress the connect runtime contract.")
    (assert-true
     (null (search "hyperdoc-connect-provider" alternate-html :test #'char=))
     "Swap preview alternate Source must suppress connect-provider metadata.")
    (handler-case
        (progn
          (hyperdoc::render-source-surface-for-page-with-designator page :bogus)
          (error "Unsupported swap designator must signal explicitly."))
      (error (condition)
        (assert-true
         (search "Unsupported Source surface designator"
                 (princ-to-string condition)
                 :test #'char=)
         "Unsupported swap designator error must be explicit.")))
    (handler-case
        (progn
          (dmx-shared-workspace-docs-load-inspector-views-for-object
           unsupported-preview)
          (error
           "Unsupported alternate swap preview must signal explicitly when rendered."))
      (error (condition)
        (assert-true
         (search "Unsupported Source surface designator"
                 (princ-to-string condition)
                 :test #'char=)
         "Unsupported alternate swap preview render must stay explicit.")))))

(defun run-source-surface-page-level-swap-operations-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (report (hyperdoc::source-surface-resolution-report-for page))
         (candidates (hyperdoc::source-surface-swap-preview-candidates-for-page
                      page))
         (plain-candidate
           (find :plain candidates
                 :key (lambda (candidate) (getf candidate :designator))))
         (plain-preview (and plain-candidate
                             (getf plain-candidate :preview)))
         (page-views (dmx-shared-workspace-docs-load-inspector-views-for-object page))
         (operations-view
           (dmx-shared-workspace-docs-find-view-by-title
            page-views
            "Source swap operations"))
         (operations-html (and operations-view
                               (html-inspector-views:view-html operations-view)))
         (preview-views (and plain-preview
                             (dmx-shared-workspace-docs-load-inspector-views-for-object
                              plain-preview)))
         (preview-overview
           (and preview-views
                (dmx-shared-workspace-docs-find-view-by-title
                 preview-views
                 "Overview")))
         (preview-alternate
           (and preview-views
                (dmx-shared-workspace-docs-find-view-by-title
                 preview-views
                 "Alternate Source")))
         (preview-overview-html
           (and preview-overview
                (html-inspector-views:view-html preview-overview)))
         (preview-alternate-html
           (and preview-alternate
                (html-inspector-views:view-html preview-alternate))))
    (assert-equal :connect
                  (getf report :effective-strategy-id)
                  (format nil "~A current effective Source path must stay connect by default"
                          page-title))
    (assert-true operations-view
                 (format nil "~A must expose a Source swap operations view"
                         page-title))
    (assert-true candidates
                 (format nil "~A must expose at least one Source swap preview candidate"
                         page-title))
    (assert-true plain-candidate
                 (format nil "~A must expose a plain Source swap preview candidate"
                         page-title))
    (assert-true
     (every (lambda (candidate)
              (typep (getf candidate :preview)
                     'hyperdoc::source-surface-swap-preview))
            candidates)
     (format nil "~A page-level swap candidates must materialize as inspectable preview objects"
             page-title))
    (assert-type 'hyperdoc::source-surface-swap-preview
                 plain-preview
                 (format nil "~A plain candidate must materialize as a swap preview object"
                         page-title))
    (assert-shared-workspace-page-contains-all
     operations-html
     (format nil "~A Source swap operations view" page-title)
     '("Current winner"
       "Current Source path"
       "Alternate designator"
       "Label"
       "Connect-capable"
       "Preview"
       "connect"
       "Plain source"
       "plain"
       "no"))
    (assert-true preview-overview
                 "Plain preview reached from the page-level view must expose Overview.")
    (assert-true preview-alternate
                 "Plain preview reached from the page-level view must expose Alternate Source.")
    (assert-shared-workspace-page-contains-all
     preview-overview-html
     (format nil "~A plain swap preview overview" page-title)
     '("Current winner"
       "Current Source path"
       "Requested alternate"
       "Alternate supported"
       "connect"
       "plain"))
    (assert-true
     (search "hyperdoc-source-pane" preview-alternate-html :test #'char=)
     "Plain preview reached from the page-level view must render the alternate source pane.")
    (assert-true
     (null (search "data-hyperdoc-connect-provider-kind='source-v1'"
                   preview-alternate-html
                   :test #'char=))
     "Plain preview reached from the page-level view must suppress the connect runtime contract.")))

(defun run-source-surface-resolution-view-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (views (dmx-shared-workspace-docs-load-inspector-views-for-object page))
         (resolution-view
           (dmx-shared-workspace-docs-find-view-by-title views "Source surface"))
         (resolution-html (and resolution-view
                               (html-inspector-views:view-html resolution-view))))
    (assert-true resolution-view
                 (format nil "~A must expose a Source surface diagnostic view"
                         page-title))
    (assert-shared-workspace-page-contains-all
     resolution-html
     (format nil "~A Source surface diagnostic view" page-title)
     '("Target class"
       "Winner"
       "Effective strategy"
       "Default strategy"
       "Override present"
       "Class policy matched"
       "Connect source"
       "default"
       "connect"))))

(defun run-plain-source-view-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page-title "Workspace-native annotations in a DMX workspace")
         (expected-source-snippet
           "&lt;h1&gt;Workspace-native annotations in a DMX workspace&lt;/h1&gt;")
         (page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    page-title
                                    :signal-error? t))
         (views (dmx-shared-workspace-docs-load-inspector-views-for-object page))
         (source-view (dmx-shared-workspace-docs-find-view-by-title views "Source"))
         (plain-view
           (dmx-shared-workspace-docs-find-view-by-title views "Plain source"))
         (plain-source-code-view
           (html-inspector-views/standard:source-code-view
            #'hyperdoc::👀plain-source
            :in-file? nil))
         (source-html (and source-view
                           (html-inspector-views:view-html source-view)))
         (plain-html (and plain-view
                          (html-inspector-views:view-html plain-view)))
         (plain-source-code-html
           (and plain-source-code-view
                (html-inspector-views:view-html plain-source-code-view))))
    (assert-true plain-view
                 (format nil "~A must expose a Plain source view" page-title))
    (assert-true source-view
                 (format nil "~A must still expose the Source view" page-title))
    (assert-true plain-source-code-view
                 "The text-page Plain source definition must expose a Source code view.")
    (assert-true (search "data-hyperdoc-connect-provider-kind='source-v1'"
                         source-html
                         :test #'char=)
                 (format nil "~A Source view must remain connect-enabled"
                         page-title))
    (assert-true (search "hyperdoc-source-pane" plain-html :test #'char=)
                 (format nil "~A Plain source view must render the source pane"
                         page-title))
    (assert-true (search "hyperdoc-source-pane-line-number"
                         plain-html
                         :test #'char=)
                 (format nil "~A Plain source view must render numbered lines"
                         page-title))
    (assert-true (search expected-source-snippet plain-html :test #'char=)
                 (format nil "~A Plain source view must render escaped source text"
                         page-title))
    (assert-true (null (search "hyperdoc-connect-provider-surface"
                               plain-html
                               :test #'char=))
                 (format nil "~A Plain source view must suppress the connect-provider surface"
                         page-title))
    (assert-true
     (null (search "data-hyperdoc-connect-provider-kind='source-v1'"
                   plain-html
                   :test #'char=))
     (format nil "~A Plain source view must suppress source-v1 provider metadata"
             page-title))
    (assert-true
     (search "render-file-source-surface"
             plain-source-code-html
             :test #'char-equal)
     "The text-page Plain source definition must expose the historical file/content path directly.")
    (assert-true
     (null (search "render-plain-source-surface-for-page"
                   plain-source-code-html
                   :test #'char-equal))
     "The text-page Plain source definition must no longer read as the plain strategy wrapper.")))

(defun run-source-pane-layout-evidence-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page (hyperbook:find-page hyperdoc::*hyperdoc*
                                    "Source pane layout evidence"
                                    :signal-error? t))
         (model (hyperdoc::chunk-source-pane-layout-evidence))
         (views (dmx-shared-workspace-docs-load-inspector-views-for-object model))
         (overview (dmx-shared-workspace-docs-find-view-by-title views "Overview"))
         (evidence-view (dmx-shared-workspace-docs-find-view-by-title views "Evidence"))
         (dispatch-view (dmx-shared-workspace-docs-find-view-by-title views "Dispatch"))
         (runtime-view (dmx-shared-workspace-docs-find-view-by-title views "Runtime"))
         (evidence-html (and evidence-view
                             (html-inspector-views:view-html evidence-view)))
         (dispatch-html (and dispatch-view
                             (html-inspector-views:view-html dispatch-view)))
         (runtime-html (and runtime-view
                            (html-inspector-views:view-html runtime-view))))
    (assert-type 'hyperdoc::html-page
                 page
                 "Source pane layout evidence page must materialize as a HyperDoc page")
    (assert-type 'hyperdoc::source-pane-layout-model
                 model
                 "Source pane layout entrypoint must materialize a first-class evidence model")
    (dolist (view (list overview evidence-view dispatch-view runtime-view))
      (assert-true view
                   "Source pane layout evidence model must expose overview, evidence, dispatch, and runtime views"))
    (assert-shared-workspace-page-contains-all
     (read-dmx-shared-workspace-page
      "hyperdoc/Source pane layout evidence.html")
     "Source pane layout evidence page"
     '("(chunk-source-pane-layout-evidence)"
       "Workspace-native annotations in a DMX workspace"
       "A DOM-annotation connect gesture"))
    (assert-shared-workspace-page-contains-all
     evidence-html
     "Source pane layout evidence table"
     '("HTML/Markdown Source dispatch"
       "Pane chrome and slot shell"
       "Server-side source/connect composition"
       "Shared and plain file-source rendering"
       "Source-pane layout CSS"
       "Pane-slot and source-surface runtime handshake"
       "hyperdoc-explorer/html-pages.lisp"
       "hyperdoc-explorer/dom-annotations.lisp"
       "hyperbook-explorer/html-books.lisp"
       "hyperbook-server/inspector-dom-association.lisp"
       "assets/hyperdoc/css/dom-annotation-connect.css"
       "assets/hyperdoc/js/dom-annotation-connect.js"
       "Representative Source-pane state"))
    (assert-shared-workspace-page-contains-all
     dispatch-html
     "Source pane layout dispatch view"
     '("html-page"
       "markdown-page"
       "text-page"
       "render-source-connect-surface"
       "hyperdoc-explorer/explorer.lisp"
       "hyperbook-explorer/html-books.lisp"))
    (assert-shared-workspace-page-contains-all
     runtime-html
     "Source pane layout runtime view"
     '("source-v1"
       "Source"
       "latent"
       "Connect"
       "Annotation"
       "Guide"))
    (dolist (relative-path '("assets/hyperdoc/css/dom-annotation-connect.css"
                             "assets/hyperdoc/js/dom-annotation-connect.js"))
      (let* ((target (hyperdoc::source-pane-layout-source-target relative-path))
             (target-views
               (dmx-shared-workspace-docs-load-inspector-views-for-object target))
             (source-view
               (dmx-shared-workspace-docs-find-view-by-title target-views "Source")))
        (assert-true target
                     (format nil "Evidence path ~A must resolve to an inspectable target"
                             relative-path))
        (assert-true source-view
                     (format nil "Evidence target ~A must expose a Source view"
                             relative-path))))))

(defun run-dmx-shared-workspace-docs-smoke-tests ()
  (run-dmx-shared-workspace-documentation-pages-smoke-test)
  (run-dmx-shared-workspace-topic-availability-smoke-test)
  (run-dmx-auth-crosswalk-render-smoke-test)
  (run-dmx-shared-workspace-source-view-smoke-test)
  (run-plain-source-view-smoke-test)
  (run-source-surface-strategy-catalog-smoke-test)
  (run-source-surface-designator-rendering-smoke-test)
  (run-source-surface-swap-preview-smoke-test)
  (run-source-surface-page-level-swap-operations-smoke-test)
  (run-source-surface-strategy-identity-smoke-test)
  (run-source-surface-resolution-view-smoke-test)
  (run-source-surface-resolution-report-smoke-test)
  (run-source-surface-strategy-class-policy-smoke-test)
  (run-source-surface-strategy-override-smoke-test)
  (run-source-pane-layout-evidence-smoke-test)
  (format t "~&DMX shared-workspace docs smoke tests passed.~%")
  t)
