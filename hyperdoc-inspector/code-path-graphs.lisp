;;;; Generic inspector views for reusable code-path graphs
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defgeneric code-path-graph-overview-extra-html (graph))

(defmethod code-path-graph-overview-extra-html
    ((graph hyperdoc::code-path-graph))
  nil)

(defgeneric code-path-graph-source-references-extra-html (graph))

(defmethod code-path-graph-source-references-extra-html
    ((graph hyperdoc::code-path-graph))
  nil)

(defun render-code-path-graph-maybe-code (value)
  (if value
      (views:html (:code (views:esc (format nil "~A" value))))
      (views:html (:span :style "opacity: 0.55;" "n/a"))))

(defun truncate-code-path-graph-text (text &key (limit 96))
  (let ((source (or text "")))
    (if (> (length source) limit)
        (format nil "~A..." (subseq source 0 limit))
        source)))

(defun render-code-path-graph-source (node)
  (if-let (label (hyperdoc::code-path-graph-source-label node))
    (views:html
      (:code (views:esc label)))
    (views:html
      (:span :style "opacity: 0.55;" "runtime target"))))

(defun code-path-graph-node-anchor-object (node)
  (or (getf node :object)
      (when-let (topic-id (getf node :topic-id))
        (ignore-errors
          (hyperdoc::find-topic-by-id topic-id :signal-error? t)))))

(defun render-code-path-graph-node-anchor (node)
  (if-let (object (code-path-graph-node-anchor-object node))
    (views:object-ref object
                      :display (or (getf node :anchor-label)
                                   (getf node :label)))
    (if-let (expr (getf node :expr))
      (views:html (:code (views:esc expr)))
      (views:html (:span :style "opacity: 0.55;" "n/a")))))

(defun render-code-path-graph-entrypoints (graph)
  (let ((entrypoints (hyperdoc::code-path-graph-entrypoint-seq graph)))
    (when entrypoints
      (views:html
        (:h4 "Entrypoints")
        (:table :class "inspector-table"
                (:thead
                 (:tr (:th (views:esc "Entrypoint"))
                      (:th (views:esc "Summary"))))
                (:tbody
                 (dolist (entrypoint entrypoints)
                   (let ((label
                           (hyperdoc::code-path-graph-entrypoint-label
                            entrypoint))
                         (summary
                           (or (hyperdoc::code-path-graph-entrypoint-summary
                                entrypoint)
                               "")))
                     (views:html
                       (:tr
                        (:td (:tt (views:esc label)))
                        (:td (views:esc summary))))))))))))

(defun render-code-path-graph-focus-path-list (graph)
  (let ((paths (hyperdoc::code-path-graph-focus-path-seq graph)))
    (when paths
      (views:html
        (:h4 "Focused paths")
        (:table :class "inspector-table"
                (:thead
                 (:tr (:th (views:esc "Path"))
                      (:th (views:esc "Summary"))
                      (:th (views:esc "Nodes"))))
                (:tbody
                 (dolist (focus-path paths)
                   (let ((label
                           (hyperdoc::code-path-graph-focus-path-label
                            focus-path))
                         (summary
                           (or (hyperdoc::code-path-graph-focus-path-summary
                                focus-path)
                               "")))
                     (views:html
                       (:tr
                        (:td (:tt (views:esc label)))
                        (:td (views:esc summary))
                        (:td (render-code-path-graph-maybe-code
                              (length
                               (hyperdoc::code-path-graph-focus-path-nodes
                                graph
                                focus-path))))))))))))))

(defmethod views:text-representation ((graph hyperdoc::code-path-graph))
  (or (hyperdoc::code-path-graph-title graph)
      (hyperdoc::code-path-graph-id graph)
      "Code path graph"))

(views:defview 👀overview (graph hyperdoc::code-path-graph)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:p (views:esc
           (or (hyperdoc::code-path-graph-summary graph)
               "Inspectable code-path graph.")))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Graph id"))
                   (:td (render-code-path-graph-maybe-code
                         (hyperdoc::code-path-graph-id graph))))
              (:tr (:td (views:esc "Nodes"))
                   (:td (render-code-path-graph-maybe-code
                         (length (hyperdoc::code-path-graph-node-seq graph)))))
              (:tr (:td (views:esc "Edges"))
                   (:td (render-code-path-graph-maybe-code
                         (length (hyperdoc::code-path-graph-edge-seq graph)))))
              (:tr (:td (views:esc "Focused paths"))
                   (:td (render-code-path-graph-maybe-code
                         (length
                          (hyperdoc::code-path-graph-focus-path-seq graph)))))
              (:tr (:td (views:esc "Trace events"))
                   (:td (render-code-path-graph-maybe-code
                         (length
                          (hyperdoc::code-path-graph-trace-event-seq graph))))))
      (render-code-path-graph-entrypoints graph)
      (render-code-path-graph-focus-path-list graph)
      (when-let (extra (code-path-graph-overview-extra-html graph))
        extra))))

(views:defview 👀nodes (graph hyperdoc::code-path-graph)
  (views:html-view :title "Nodes" :priority 4
    (views:html
      (:p (views:esc
           "Meaningful code-path nodes. Each node can carry source anchors plus an optional runtime or topic object anchor."))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Node"))
                    (:th (views:esc "Role"))
                    (:th (views:esc "Anchor"))
                    (:th (views:esc "Source"))
                    (:th (views:esc "Summary"))))
              (:tbody
               (dolist (node (hyperdoc::code-path-graph-node-seq graph))
                 (let ((label (or (getf node :label)
                                  (getf node :id)))
                       (role-label
                         (hyperdoc::code-path-graph-role-label
                          (or (getf node :role)
                              (getf node :kind)))))
                   (views:html
                     (:tr
                      (:td (:tt (views:esc label)))
                      (:td (:tt (views:esc role-label)))
                      (:td (render-code-path-graph-node-anchor node))
                      (:td (render-code-path-graph-source node))
                      (:td (views:esc (or (getf node :summary) ""))))))))))))

(views:defview 👀edges (graph hyperdoc::code-path-graph)
  (views:html-view :title "Edges" :priority 5
    (views:html
      (:p (views:esc
           "Typed edges between graph nodes. These can describe reads, writes, runtime steps, or suppressed transitions."))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "From"))
                    (:th (views:esc "To"))
                    (:th (views:esc "Kind"))
                    (:th (views:esc "Status"))
                    (:th (views:esc "Write-capable"))
                    (:th (views:esc "Summary"))))
              (:tbody
               (dolist (edge (hyperdoc::code-path-graph-edge-seq graph))
                 (let ((from-label
                         (hyperdoc::code-path-graph-node-label
                          graph
                          (getf edge :from)))
                       (to-label
                         (hyperdoc::code-path-graph-node-label
                          graph
                          (getf edge :to))))
                   (views:html
                     (:tr
                      (:td (:tt (views:esc from-label)))
                      (:td (:tt (views:esc to-label)))
                      (:td (:tt (views:esc
                                 (hyperdoc::code-path-graph-edge-kind-label
                                  (getf edge :kind)))))
                      (:td (:tt (views:esc
                                 (hyperdoc::code-path-graph-edge-status-label
                                  (getf edge :status)))))
                      (:td (:tt (views:esc
                                 (if (getf edge :write-capable-p)
                                     "yes"
                                     "no"))))
                      (:td (views:esc (or (getf edge :summary) ""))))))))))))

(views:defview 👀focused-paths (graph hyperdoc::code-path-graph)
  (views:html-view :title "Focused paths" :priority 6
    (let ((paths (hyperdoc::code-path-graph-focus-path-seq graph)))
      (if paths
          (views:html
            (:p (views:esc
                 "Curated or traced paths through the graph. These make the abstraction useful before any exhaustive static call graph exists."))
            (dolist (focus-path paths)
              (views:html
                (:h4 (views:esc
                      (hyperdoc::code-path-graph-focus-path-label focus-path)))
                (when-let (summary
                             (hyperdoc::code-path-graph-focus-path-summary
                              focus-path))
                  (views:html
                    (:p (views:esc summary))))
                (:table :class "inspector-table"
                        (:thead
                         (:tr (:th (views:esc "Node"))
                              (:th (views:esc "Role"))
                              (:th (views:esc "Summary"))))
                        (:tbody
                         (dolist (node
                                   (hyperdoc::code-path-graph-focus-path-nodes
                                    graph
                                    focus-path))
                           (let ((label (or (getf node :label)
                                            (getf node :id)))
                                 (role-label
                                   (hyperdoc::code-path-graph-role-label
                                    (or (getf node :role)
                                        (getf node :kind)))))
                             (views:html
                               (:tr
                                (:td (:tt (views:esc label)))
                                (:td (:tt (views:esc role-label)))
                                (:td (views:esc (or (getf node :summary)
                                                    ""))))))))
                (when-let (edges
                             (hyperdoc::code-path-graph-focus-path-edges
                              graph
                              focus-path))
                  (views:html
                    (:table :class "inspector-table"
                            (:thead
                             (:tr (:th (views:esc "Edge"))
                                  (:th (views:esc "Status"))
                                  (:th (views:esc "Summary"))))
                            (:tbody
                             (dolist (edge edges)
                               (let ((edge-label
                                       (format nil "~A -> ~A"
                                               (hyperdoc::code-path-graph-node-label
                                                graph
                                                (getf edge :from))
                                               (hyperdoc::code-path-graph-node-label
                                                graph
                                                (getf edge :to)))))
                                 (views:html
                                   (:tr
                                    (:td (:tt (views:esc edge-label)))
                                    (:td (:tt (views:esc
                                               (hyperdoc::code-path-graph-edge-status-label
                                                (getf edge :status)))))
                                    (:td (views:esc
                                          (or (getf edge :summary)
                                              "")))))))))))))
          (views:html
            (:p (views:esc
                 "No focused paths are currently attached to this graph.")))))))))

(views:defview 👀source-references (graph hyperdoc::code-path-graph)
  (views:html-view :title "Source references" :priority 7
    (views:html
      (:p (views:esc
           "Source-backed reference table for the current graph. This keeps curated architecture diagrams and traced runtime paths attached to concrete code anchors."))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th (views:esc "Function or target"))
                    (:th (views:esc "Role"))
                    (:th (views:esc "Anchor"))
                    (:th (views:esc "Source"))
                    (:th (views:esc "Why it matters"))))
              (:tbody
               (dolist (node (hyperdoc::code-path-graph-node-seq graph))
                 (let ((label (or (getf node :label)
                                  (getf node :id)))
                       (role-label
                         (hyperdoc::code-path-graph-role-label
                          (or (getf node :role)
                              (getf node :kind)))))
                   (views:html
                     (:tr
                      (:td (:tt (views:esc label)))
                      (:td (:tt (views:esc role-label)))
                      (:td (render-code-path-graph-node-anchor node))
                      (:td (render-code-path-graph-source node))
                      (:td (views:esc (or (getf node :summary)
                                          "")))))))))
      (when-let (extra (code-path-graph-source-references-extra-html graph))
        extra))))

(views:defview 👀graphviz (graph hyperdoc::code-path-graph)
  (views:html-view :title "Graphviz" :priority 8
    (views:html
      (:p (views:esc
           "Browser-rendered Graphviz view for the current graph object. The graph remains the source of truth; DOT is a derived rendering format for SVG rendering and inspection."))
      (views:graphviz-snippet
       (hyperdoc::code-path-graph-dot-text graph)))))

(views:defview 👀dot-export (graph hyperdoc::code-path-graph)
  (views:html-view :title "DOT export" :priority 9
    (views:html
      (:p (views:esc
           "Graphviz DOT export for the current graph object. The graph remains the source of truth; DOT is a derived rendering format."))
      (:pre :style "white-space: pre-wrap;"
            (views:esc (hyperdoc::code-path-graph-dot-text graph))))))

(defmethod code-path-graph-overview-extra-html
    ((graph hyperdoc::playground-stepper-code-path-graph))
  (views:html
    (:h4 "Runtime state")
    (:table :class "inspector-table"
            (:tr (:td (views:esc "Package"))
                 (:td (render-code-path-graph-maybe-code
                       (hyperdoc::playground-stepper-code-path-graph-package-name
                        graph))))
            (:tr (:td (views:esc "Progress"))
                 (:td (views:esc
                       (or (hyperdoc::playground-stepper-code-path-graph-progress-label
                            graph)
                           ""))))
            (:tr (:td (views:esc "Done"))
                 (:td (:tt (views:esc
                            (if (hyperdoc::playground-stepper-code-path-graph-done-p
                                 graph)
                                "yes"
                                "no")))))
            (:tr (:td (views:esc "Parse error"))
                 (:td (:tt (views:esc
                            (if (hyperdoc::playground-stepper-code-path-graph-parse-error-p
                                 graph)
                                "yes"
                                "no")))))
    (:h4 "Source selection")
    (:pre :style "white-space: pre-wrap;"
          (views:esc
           (or (hyperdoc::playground-stepper-code-path-graph-source-selection
                graph)
               ""))))))

(defun playground-stepper-form-status (stepper position)
  (let ((current-index
          (clog-moldable-inspector::playground-stepper-index stepper))
        (last-error
          (clog-moldable-inspector::playground-stepper-last-error stepper))
        (parse-report
          (clog-moldable-inspector::playground-stepper-parse-report stepper)))
    (cond
      (parse-report :parse-error)
      ((< position current-index) :completed)
      ((and last-error (= position current-index)) :error)
      ((= position current-index) :current)
      (t :pending))))

(defun playground-stepper-runtime-trace-events (stepper)
  (let ((forms (clog-moldable-inspector::playground-stepper-forms stepper)))
    (if-let (parse-report
               (clog-moldable-inspector::playground-stepper-parse-report stepper))
      (list
       (list :id "parse-error"
             :label "Parse error"
             :status :parse-error
             :summary
             (truncate-code-path-graph-text
              (format nil "~A" parse-report))))
      (loop for form in forms
            for index from 0
            collect
            (list :id (format nil "form-~D" (1+ index))
                  :label (format nil "Form ~D" (1+ index))
                  :status (playground-stepper-form-status stepper index)
                  :summary
                  (truncate-code-path-graph-text
                   (prin1-to-string form)))))))

(defun playground-stepper-terminal-node (stepper)
  (cond
    ((when-let (parse-report
                 (clog-moldable-inspector::playground-stepper-parse-report
                  stepper))
       (list :id "parse-error"
             :label "Parse error"
             :role :runtime-error
             :source-file "hyperbook-server/playground-stepper.lisp"
             :source-function "make-playground-stepper"
             :object parse-report
             :anchor-label "Inspect parse error"
             :summary
             "Reader failure captured before evaluation begins.")))
    ((when-let (last-error
                 (clog-moldable-inspector::playground-stepper-last-error
                  stepper))
       (list :id "runtime-error"
             :label "Runtime error"
             :role :runtime-error
             :source-file "hyperbook-server/playground-stepper.lisp"
             :source-function "playground-stepper-step"
             :object last-error
             :anchor-label "Inspect runtime error"
             :summary
             "The traced run stopped on the current form with a captured error report.")))
    ((when (clog-moldable-inspector::playground-stepper-done? stepper)
       (list :id "done"
             :label "Done"
             :role :runtime-terminal
             :source-file "hyperbook-server/playground-stepper.lisp"
             :source-function "playground-stepper-run"
             :object (clog-moldable-inspector::playground-stepper-last-value
                      stepper)
             :anchor-label "Inspect last value"
             :summary
             "The current stepped run finished without a captured error.")))))

(defun playground-stepper-code-path-nodes (stepper)
  (let* ((forms (clog-moldable-inspector::playground-stepper-forms stepper))
         (terminal-node (playground-stepper-terminal-node stepper))
         (form-nodes
           (loop for form in forms
                 for index from 0
                 collect
                 (list :id (format nil "form-~D" (1+ index))
                       :label (format nil "Form ~D" (1+ index))
                       :role :runtime-step
                       :source-file "hyperbook-server/playground-stepper.lisp"
                       :source-function "playground-stepper-step"
                       :status (playground-stepper-form-status stepper index)
                       :summary
                       (truncate-code-path-graph-text
                        (prin1-to-string form))))))
    (append
     (list
      (list :id "source-selection"
            :label "Source selection"
            :role :runtime-input
            :source-file "hyperbook-server/playground-stepper.lisp"
            :source-function "make-playground-stepper"
            :summary
            "The current Playground source selection wrapped into a stepper object.")
      (list :id "parse-source"
            :label "Read all forms"
            :role :runtime-read
            :source-file "hyperbook-server/playground-stepper.lisp"
            :source-function "read-all-forms"
            :summary
            "Reader pass that turns the selection into top-level forms before stepping."))
     form-nodes
     (when terminal-node
       (list terminal-node)))))

(defun playground-stepper-code-path-edges (stepper)
  (let* ((forms (clog-moldable-inspector::playground-stepper-forms stepper))
         (last-form-index (max 0 (1- (length forms))))
         (current-index (clog-moldable-inspector::playground-stepper-index stepper))
         (parse-report (clog-moldable-inspector::playground-stepper-parse-report
                        stepper))
         (last-error (clog-moldable-inspector::playground-stepper-last-error
                      stepper))
         (edges
           (list
            (list :from "source-selection"
                  :to "parse-source"
                  :kind :parse
                  :status (if parse-report :parse-error :completed)
                  :summary
                  "Create the stepper and parse the selected source into top-level forms."))))
    (when forms
      (push
       (list :from "parse-source"
             :to "form-1"
             :kind :step
             :status (if parse-report
                         :parse-error
                         (if (zerop current-index) :active :completed))
             :summary
             "First runnable top-level form derived from the source selection.")
       edges)
      (loop for index from 0 below (1- (length forms))
            do (push
                (list :from (format nil "form-~D" (1+ index))
                      :to (format nil "form-~D" (+ index 2))
                      :kind :step
                      :status (cond
                                ((> current-index (1+ index)) :completed)
                                ((= current-index (1+ index)) :active)
                                (t :pending))
                      :summary
                      "Step to the next top-level form in the selected source.")
                edges)))
    (cond
      (parse-report
       (push (list :from "parse-source"
                   :to "parse-error"
                   :kind :terminal
                   :status :parse-error
                   :summary
                   "Reader failure stops the run before any top-level form executes.")
             edges))
      (last-error
       (push (list :from (format nil "form-~D" (1+ current-index))
                   :to "runtime-error"
                   :kind :terminal
                   :status :error
                   :summary
                   "The current top-level form raised an error and ended the run.")
             edges))
      ((and forms
            (clog-moldable-inspector::playground-stepper-done? stepper))
       (push (list :from (format nil "form-~D" (1+ last-form-index))
                   :to "done"
                   :kind :result
                   :status :completed
                   :summary
                   "The final stepped form completed and the run finished.")
             edges)))
    (nreverse edges)))

(defun playground-stepper-code-path-focus-paths (stepper)
  (let* ((forms (clog-moldable-inspector::playground-stepper-forms stepper))
         (node-ids (append (list "source-selection" "parse-source")
                           (loop for index from 0 below (length forms)
                                 collect (format nil "form-~D" (1+ index)))
                           (cond
                             ((clog-moldable-inspector::playground-stepper-parse-report
                               stepper)
                              (list "parse-error"))
                             ((clog-moldable-inspector::playground-stepper-last-error
                               stepper)
                              (list "runtime-error"))
                             ((clog-moldable-inspector::playground-stepper-done? stepper)
                              (list "done"))
                             (t '())))))
    (list
     (list :id "current-stepped-run"
           :label "Current stepped run"
           :summary
           "Runtime path derived from the current stepper state and selected top-level forms."
           :node-ids node-ids))))

(defun playground-stepper-code-path-graph (stepper)
  (let* ((forms (clog-moldable-inspector::playground-stepper-forms stepper))
         (package (clog-moldable-inspector::playground-stepper-package stepper)))
    (hyperdoc::make-playground-stepper-code-path-graph
     :id "playground-stepper-code-path-graph"
     :title "Playground stepper code path"
     :summary
     "Runtime code-path graph derived from the current Playground stepper state."
     :entrypoints
     (list
      (list :id "stepper-entry"
            :label "make-playground-stepper"
            :summary
            "Build the traced runtime object from a source selection before stepping.")
      (list :id "stepper-step"
            :label "playground-stepper-step"
            :summary
            "Advance one top-level form at a time while keeping the result inspectable."))
     :nodes (playground-stepper-code-path-nodes stepper)
     :edges (playground-stepper-code-path-edges stepper)
     :trace-events (playground-stepper-runtime-trace-events stepper)
     :focus-paths (playground-stepper-code-path-focus-paths stepper)
     :package-name (and package (package-name package))
     :source-selection (clog-moldable-inspector::playground-stepper-source stepper)
     :progress-label
     (format nil "~D / ~D"
             (clog-moldable-inspector::playground-stepper-index stepper)
             (length forms))
     :parse-error-p
     (not (null (clog-moldable-inspector::playground-stepper-parse-report
                 stepper)))
     :done-p (clog-moldable-inspector::playground-stepper-done? stepper))))

(views:defview 👀code-path-graph
    (stepper clog-moldable-inspector::playground-stepper)
  (views:html-view :title "Code path graph" :priority 2
    (let ((graph (playground-stepper-code-path-graph stepper)))
      (views:html
        (:p (views:esc
             "Derived runtime code-path graph for the current stepped selection. It reuses the same inspectable graph abstraction as curated architectural call graphs."))
        (:ul
         (:li
          (views:object-ref graph
                            :display "Open code-path overview"
                            :select "Overview"))
         (:li
          (views:object-ref graph
                            :display "Open focused paths"
                            :select "Focused paths"))
         (:li
          (views:object-ref graph
                            :display "Open DOT export"
                            :select "DOT export")))))))
