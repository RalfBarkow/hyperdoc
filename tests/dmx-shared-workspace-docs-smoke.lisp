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
     "existing-topic-id"
     "topicmap_context_add"))
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
     "MCP server is the typed machine-facing boundary"))
  (assert-shared-workspace-page-contains-all
   (read-dmx-shared-workspace-page
    "hyperdoc/DMX FedWiki Write Model.html")
   "DMX FedWiki Write Model"
   '("DMX note read/write boundary"
     "DMX machine-readable read paths"
     "DMX MCP server for shared workspace"))
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
                    "Shared-workspace collaboration model")))
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
                        "Shared-workspace collaboration model"))
    (assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* page-title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" page-title))))

(defun run-dmx-shared-workspace-docs-smoke-tests ()
  (run-dmx-shared-workspace-documentation-pages-smoke-test)
  (run-dmx-shared-workspace-topic-availability-smoke-test)
  (format t "~&DMX shared-workspace docs smoke tests passed.~%")
  t)
