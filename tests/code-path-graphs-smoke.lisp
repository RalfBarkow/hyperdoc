;;;; Focused smoke tests for reusable code-path graphs
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-CODE-PATH-GRAPHS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun code-path-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun code-path-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun code-path-assert-contains (substring string message)
  (unless (search substring string)
    (error "~A -- missing substring: ~S" message substring)))

(defun code-path-assert-not-contains (substring string message)
  (when (search substring string)
    (error "~A -- unexpected substring: ~S" message substring)))

(defun code-path-graphs-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-code-path-graphs-page (namestring)
  (uiop:read-file-string
   (code-path-graphs-relative-path namestring)))

(defparameter *code-path-graphs-smoke-workspace-topicmap-id* 919822)

(defun make-code-path-graph-test-dock-annotation (&key note
                                                       (context-view-title
                                                         "Main page")
                                                       (source-label
                                                         "Text pages")
                                                       (source-value
                                                         "list-item:main-page/text-pages"))
  (let* ((hyperdoc-page (hyperdoc::find-page hyperdoc::*hyperdoc*
                                             "HyperDoc"
                                             :signal-error? t))
         (annotation-from-connect
           (hyperdoc::make-association-annotation-from-json
            :context-object hyperdoc-page
            :context-view-title context-view-title
            :source-json (dock-annotation-source-json "HYPERDOC"
                                                      source-label
                                                      source-value)
            :target-json (dock-annotation-target-json "HYPERDOC"))))
    (hyperdoc::make-dock-annotation
     :context-object hyperdoc-page
     :context-view-title context-view-title
     :source-anchor (hyperdoc::source-anchor-of annotation-from-connect)
     :source-object (hyperdoc::source-object-of annotation-from-connect)
     :target-anchor (hyperdoc::target-anchor-of annotation-from-connect)
     :relation-kind (hyperdoc::relation-kind-of annotation-from-connect)
     :note (or note
               (hyperdoc::note-of annotation-from-connect)))))

(defun normalize-code-path-graphs-smoke-whitespace (string)
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

(defun assert-code-path-graph-page-contains-all (page-source page-label needles)
  (let ((normalized-page-source
          (normalize-code-path-graphs-smoke-whitespace page-source)))
    (dolist (needle needles)
      (code-path-assert-true
       (search (normalize-code-path-graphs-smoke-whitespace needle)
               normalized-page-source
               :test #'char=)
       (format nil "~A must contain ~S" page-label needle)))))

(defun make-code-path-graph-smoke-graph ()
  (hyperdoc::make-code-path-graph
   :id "example-code-path"
   :title "Example code path"
   :summary "Example graph for DOT export regression coverage."
   :entrypoints
   (list (list :id "entry"
               :label "example-entry"
               :summary "Starts the example graph."))
   :nodes
   (list
    (list :id "entry"
          :label "entry"
          :role :read-entry
          :source-file "hyperdoc/example.lisp"
          :source-function "example-entry"
          :summary "Entry node.")
    (list :id "apply"
          :label "apply"
          :role :safe-read-edge
          :summary "In-memory apply helper.")
    (list :id "persist"
          :label "persist"
          :role :write-helper
          :summary "Explicit persistence helper."))
   :edges
   (list
    (list :from "entry"
          :to "apply"
          :kind :safe-read
          :status :active
          :summary "Stay in memory.")
    (list :from "apply"
          :to "persist"
          :kind :suppressed-write
          :status :suppressed
          :write-capable-p t
          :summary "Suppressed on read."))
   :focus-paths
   (list
    (list :id "main-path"
          :label "Main path"
          :summary "Simple focused path."
          :node-ids '("entry" "apply" "persist")))))

(defun make-code-path-graph-entity-transport-smoke-graph ()
  (hyperdoc::make-code-path-graph
   :id "entity-transport-graph"
   :title "Entity transport graph"
   :summary "Regression graph for quote/ampersand-safe Graphviz transport."
   :nodes
   (list
    (list :id "source"
          :label "Source \"quoted\" & routed"
          :role :read-entry
          :summary "Produces DOT with quotes and ampersands.")
    (list :id "target"
          :label "Target"
          :role :write-helper
          :summary "Terminal target."))
   :edges
   (list
    (list :from "source"
          :to "target"
          :kind :safe-read
          :status :active
          :summary "Carries \"quoted\" & joined text."))))

(defun make-source-linked-code-path-graph-smoke-graph ()
  (hyperdoc::make-code-path-graph
   :id "source-linked-graph"
   :title "Source-linked graph"
   :summary "Regression graph for clickable source-backed references."
   :nodes
   (list
    (list :id "workspace-read"
          :label "workspace read"
          :role :read-entry
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "read-dmx-workspace-journal"
          :summary "Reads the workspace journal."))))

(defun make-source-file-only-code-path-graph-smoke-graph ()
  (hyperdoc::make-code-path-graph
   :id "source-file-only-graph"
   :title "Source file-only graph"
   :summary "Regression graph for clickable source references without function landing context."
   :nodes
   (list
    (list :id "workspace-file"
          :label "workspace file"
          :role :read-entry
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :summary "Reads the workspace journal file."))))

(defun code-path-graph-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun code-path-graph-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun run-code-path-graph-dot-export-smoke-test ()
  (let* ((graph (make-code-path-graph-smoke-graph))
         (dot (hyperdoc::code-path-graph-dot-text graph)))
    (code-path-assert-contains "digraph \"example-code-path\"" dot
                               "DOT export must use the graph id")
    (code-path-assert-contains "rankdir=LR" dot
                               "DOT export must expose the default rankdir")
    (code-path-assert-contains "read entry" dot
                               "DOT export must include node role labels")
    (code-path-assert-contains "safe read" dot
                               "DOT export must label safe-read edges")
    (code-path-assert-contains "style=dashed" dot
                               "DOT export must distinguish suppressed edges")
    (code-path-assert-contains "color=\"firebrick\"" dot
                               "DOT export must mark write-capable edges")))

(defun run-code-path-graph-rendered-view-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((graph (make-code-path-graph-smoke-graph))
         (views (code-path-graph-smoke-load-inspector-views-for-object graph))
         (graphviz-view
           (code-path-graph-smoke-find-view-by-title views "Graphviz"))
         (dot-view
           (code-path-graph-smoke-find-view-by-title views "DOT export")))
    (code-path-assert-true graphviz-view
                           "Code-path graph must expose a Graphviz view")
    (code-path-assert-true dot-view
                           "Code-path graph must keep the DOT export view")
    (assert-code-path-graph-page-contains-all
     (html-inspector-views:view-html graphviz-view)
     "Code-path graph Graphviz view"
     '("Browser-rendered Graphviz view"
       "data-inspector-graphviz"
       "data-inspector-graphviz-dot"
       "Derived DOT source"))
    (assert-code-path-graph-page-contains-all
     (html-inspector-views:view-html dot-view)
     "Code-path graph DOT export view"
     '("Graphviz DOT export for the current graph object"
       "example-code-path"))))

(defun run-code-path-graph-source-reference-link-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((graph (make-source-linked-code-path-graph-smoke-graph))
         (node (first (hyperdoc::code-path-graph-node-seq graph)))
         (expected-source-label
           "hyperdoc/dmx-workspace-journal.lisp :: read-dmx-workspace-journal")
         (page (hyperdoc/inspector::code-path-graph-source-page node))
         (target (hyperdoc/inspector::code-path-graph-source-target node))
         (views (code-path-graph-smoke-load-inspector-views-for-object graph))
         (source-view
           (code-path-graph-smoke-find-view-by-title views "Source references"))
         (source-html (html-inspector-views:view-html source-view))
         (target-views
           (code-path-graph-smoke-load-inspector-views-for-object target))
         (target-source-view
           (code-path-graph-smoke-find-view-by-title target-views "Source"))
         (target-source-html (html-inspector-views:view-html target-source-view)))
    (code-path-assert-true page
                           "Source-backed graph node must resolve to a source page")
    (code-path-assert-true (typep page 'hyperdoc::code-page)
                           "Resolved source target must be a code page")
    (code-path-assert-true target
                           "Source-backed graph node must resolve to an inspectable source target")
    (code-path-assert-true
     (typep target 'hyperdoc::code-page-source-navigation)
     "Source-backed graph node with :source-function must wrap the code page with source navigation context")
    (code-path-assert-contains "dmx-workspace-journal.lisp"
                               (namestring (asdf:component-pathname
                                            (hyperdoc:file-of page)))
                               "Resolved source page must point at the DMX journal file")
    (code-path-assert-contains expected-source-label
                               source-html
                               "Source references view must keep the source label visible")
    (code-path-assert-contains "inspector-inspect"
                               source-html
                               "Source references view must render the source label as an inspectable object reference")
    (code-path-assert-not-contains
     (format nil "~A&lt;/code&gt;" expected-source-label)
     source-html
     "Source references view must not leak an escaped closing code tag into the visible source label")
    (code-path-assert-not-contains
     (format nil "~A</code>" expected-source-label)
     source-html
     "Source references view must not concatenate a raw closing code tag into the source label text")
    (code-path-assert-contains "hyperdoc-source-navigation-view"
                               target-source-html
                               "Navigation-aware source pages must render the dedicated source-layout wrapper")
    (code-path-assert-contains "hyperdoc-source-navigation-source"
                               target-source-html
                               "Navigation-aware source pages must keep the source surface inside the dedicated primary wrapper")
    (code-path-assert-contains "hyperdoc-source-navigation-context"
                               target-source-html
                               "Navigation-aware source pages must keep the requested-function context visible")
    (code-path-assert-contains "Requested function"
                               target-source-html
                               "Source view must surface the requested function as navigation context")
    (code-path-assert-contains "read-dmx-workspace-journal"
                               target-source-html
                               "Source view must keep the requested function name visible")
    (code-path-assert-contains "data-hyperdoc-source-focus"
                               target-source-html
                               "Source view must mark the focused source lines for best-effort landing")
    (code-path-assert-contains "hyperdoc-source-connect-line-focus"
                               target-source-html
                               "Source view must highlight the best-effort landing lines when a function match is found")))

(defun run-code-path-graph-source-reference-file-only-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((graph (make-source-file-only-code-path-graph-smoke-graph))
         (node (first (hyperdoc::code-path-graph-node-seq graph)))
         (expected-source-label "hyperdoc/dmx-workspace-journal.lisp")
         (target (hyperdoc/inspector::code-path-graph-source-target node))
         (source-target-views
           (code-path-graph-smoke-load-inspector-views-for-object target))
         (target-source-view
           (code-path-graph-smoke-find-view-by-title source-target-views "Source"))
         (target-source-html (html-inspector-views:view-html target-source-view))
         (graph-views (code-path-graph-smoke-load-inspector-views-for-object graph))
         (source-view
           (code-path-graph-smoke-find-view-by-title graph-views "Source references"))
         (source-html (html-inspector-views:view-html source-view)))
    (code-path-assert-true target
                           "File-backed graph node must still resolve to an inspectable source target")
    (code-path-assert-true (typep target 'hyperdoc::code-page)
                           "File-backed graph node without :source-function must still resolve to a code page")
    (code-path-assert-true (not (typep target 'hyperdoc::code-page-source-navigation))
                           "File-backed graph node without :source-function must not add navigation wrapper state")
    (code-path-assert-contains expected-source-label
                               source-html
                               "File-backed source references must remain clickable and visible without a function name")
    (code-path-assert-not-contains
     (format nil "~A&lt;/code&gt;" expected-source-label)
     source-html
     "File-backed source references must not leak escaped closing code-tag text")
    (code-path-assert-not-contains
     (format nil "~A</code>" expected-source-label)
     source-html
     "File-backed source references must not leak raw closing code-tag text into the label")
    (code-path-assert-not-contains "Requested function:"
                                   target-source-html
                                   "Plain file-backed source pages must keep the existing Source view without navigation caption")))

(defun run-graphviz-transport-entity-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((graph (make-code-path-graph-entity-transport-smoke-graph))
         (dot (hyperdoc::code-path-graph-dot-text graph))
         (views (code-path-graph-smoke-load-inspector-views-for-object graph))
         (graphviz-view
           (code-path-graph-smoke-find-view-by-title views "Graphviz"))
         (graphviz-html (html-inspector-views:view-html graphviz-view)))
    (code-path-assert-contains "\\\"quoted\\\" & routed" dot
                               "Regression DOT must include quote and ampersand text")
    (code-path-assert-contains "data-inspector-graphviz-dot="
                               graphviz-html
                               "Graphviz helper must transport DOT through a decoded-safe data attribute")
    (code-path-assert-not-contains "<graphviz-element"
                                   graphviz-html
                                   "Graphviz helper must no longer use the legacy graphviz-element transport")
    (code-path-assert-contains "Derived DOT source"
                               graphviz-html
                               "Graphviz helper must keep the raw DOT fallback visible")))

(defun run-dmx-journal-code-path-graph-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((graph (hyperdoc::dmx-workspace-journal-reconcile-call-graph))
         (dot (hyperdoc::code-path-graph-dot-text graph))
         (paths (hyperdoc::code-path-graph-focus-path-seq graph)))
    (code-path-assert-true (typep graph 'hyperdoc::code-path-graph)
                           "DMX journal graph must now be a reusable code-path graph")
    (code-path-assert-equal 3 (length paths)
                            "DMX journal graph must expose focused paths")
    (code-path-assert-contains "read-dmx-workspace-journal" dot
                               "DMX journal graph DOT export must include the workspace read entrypoint")
    (code-path-assert-contains "dmx-workspace-journal-append-events" dot
                               "DMX journal graph DOT export must include the explicit append helper")))

(defun run-workspace-annotation-path-diff-graph-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 9520))
         (annotation (make-code-path-graph-test-dock-annotation
                      :note "Path diff graph smoke"))
         (comparison
           (hyperdoc::compare-dock-annotation-with-guarded-workspace-path
            annotation
            :workspace-topicmap-id
            *code-path-graphs-smoke-workspace-topicmap-id*
            :client client))
         (graph (hyperdoc::workspace-annotation-path-diff-graph comparison))
         (dot (hyperdoc::code-path-graph-dot-text graph))
         (focus-paths (hyperdoc::code-path-graph-focus-path-seq graph))
         (focus-labels (mapcar #'hyperdoc::code-path-graph-focus-path-label
                               focus-paths)))
    (code-path-assert-true
     (typep graph 'hyperdoc::code-path-graph)
     "Workspace annotation path diff graph must reuse the generic code-path graph object")
    (code-path-assert-true
     (member "Main annotation persist path" focus-labels :test #'string=)
     "Workspace annotation path diff graph must expose the main annotation persist focused path")
    (code-path-assert-true
     (member "Guarded continuation path" focus-labels :test #'string=)
     "Workspace annotation path diff graph must expose the guarded continuation focused path")
    (code-path-assert-contains "workspace-assignment auth boundary" dot
                               "Workspace annotation path diff DOT must expose the explicit auth-boundary divergence node")
    (code-path-assert-contains "raw pending-auth stop" dot
                               "Workspace annotation path diff DOT must expose the raw pending-auth stop branch")
    (code-path-assert-contains "guarded explicit-auth continuation" dot
                               "Workspace annotation path diff DOT must expose the guarded explicit-auth continuation branch")))

(defun run-playground-stepper-code-path-graph-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((stepper
           (clog-moldable-inspector::make-playground-stepper
            '(alpha beta gamma)
            "(car *)\n(length *)"))
         (_ (clog-moldable-inspector::playground-stepper-step stepper))
         (graph (hyperdoc/inspector::playground-stepper-code-path-graph stepper))
         (dot (hyperdoc::code-path-graph-dot-text graph))
         (events (hyperdoc::code-path-graph-trace-event-seq graph)))
    (declare (ignore _))
    (code-path-assert-true
     (typep graph 'hyperdoc::playground-stepper-code-path-graph)
     "Stepper runtime graph must use the dedicated runtime graph subtype")
    (code-path-assert-true
     (typep graph 'hyperdoc::code-path-graph)
     "Stepper runtime graph must share the generic code-path graph base")
    (code-path-assert-equal :completed
                            (getf (first events) :status)
                            "First stepped form must become completed after one step")
    (code-path-assert-equal :current
                            (getf (second events) :status)
                            "Second stepped form must become current after one step")
    (code-path-assert-contains "Source selection" dot
                               "Runtime DOT export must include the source selection node")
    (code-path-assert-contains "Form 1" dot
                               "Runtime DOT export must include stepped form nodes")))

(defun run-code-path-graphs-documentation-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (assert-code-path-graph-page-contains-all
   (read-code-path-graphs-page "hyperdoc/Code path graphs in HyperDoc.html")
   "Code path graphs in HyperDoc"
   '("code-path-graph"
     "DMX workspace journal reconcile call graph"
     "Diagramming Debugger Surface"
     "playground-stepper-code-path-graph"
     "view=\"Graphviz\""
     "Graphviz DOT export"
     "does not introduce a generic raw graph persistence layer"))
  (code-path-assert-true
   (fboundp 'hyperdoc::code-path-graphs-in-hyperdoc-topic)
   "Missing topic function hyperdoc::code-path-graphs-in-hyperdoc-topic")
  (let ((topic (hyperdoc::code-path-graphs-in-hyperdoc-topic)))
    (code-path-assert-equal "Code path graphs in HyperDoc"
                            (hyperbook:title-of topic)
                            "Code path graphs topic title"))
  (code-path-assert-true
   (hyperbook:find-page hyperdoc::*hyperdoc*
                        "Code path graphs in HyperDoc"
                        :signal-error? t)
   "Missing HyperDoc page Code path graphs in HyperDoc")
  (code-path-assert-true
   (hyperbook:find-page hyperdoc::*topics*
                        "Code path graphs in HyperDoc"
                        :signal-error? t)
   "Missing Topics page Code path graphs in HyperDoc"))

(defun run-code-path-graphs-smoke-tests ()
  (run-code-path-graph-dot-export-smoke-test)
  (run-code-path-graph-rendered-view-smoke-test)
  (run-code-path-graph-source-reference-link-smoke-test)
  (run-code-path-graph-source-reference-file-only-smoke-test)
  (run-graphviz-transport-entity-smoke-test)
  (run-dmx-journal-code-path-graph-smoke-test)
  (run-workspace-annotation-path-diff-graph-smoke-test)
  (run-playground-stepper-code-path-graph-smoke-test)
  (run-code-path-graphs-documentation-smoke-test)
  (format t "~&Code path graph smoke tests passed.~%")
  t)
