;;;; Codex collaboration home topic

(in-package :hyperdoc)

(defclass codex-home ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (current-slice :accessor codex-home-current-slice-of
                  :initarg :current-slice)
   (context-window :accessor codex-home-context-window-of
                   :initarg :context-window)
   (primary-review-object :accessor codex-home-primary-review-object-of
                          :initarg :primary-review-object)
   (related-objects :accessor codex-home-related-objects-of
                    :initarg :related-objects)
   (relevant-pages :accessor codex-home-relevant-pages-of
                   :initarg :relevant-pages)
   (validation-commands :accessor codex-home-validation-commands-of
                        :initarg :validation-commands)
   (commit-boundary :accessor codex-home-commit-boundary-of
                    :initarg :commit-boundary
                    :initform nil)))

(defmethod print-object ((object codex-home) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-context-window ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source :accessor codex-context-window-source-of
           :initarg :source)
   (captured-at :accessor codex-context-window-captured-at-of
                :initarg :captured-at)
   (summary :accessor summary-of :initarg :summary)
   (entries :accessor codex-context-window-entries-of
            :initarg :entries)
   (open-questions :accessor codex-context-window-open-questions-of
                   :initarg :open-questions)
   (proposed-actions :accessor codex-context-window-proposed-actions-of
                     :initarg :proposed-actions)
   (related-objects :accessor codex-context-window-related-objects-of
                    :initarg :related-objects)
   (validation-commands :accessor codex-context-window-validation-commands-of
                        :initarg :validation-commands)
   (provenance :accessor codex-context-window-provenance-of
               :initarg :provenance)
   (previous-context-window
    :accessor codex-context-window-previous-context-window-of
    :initarg :previous-context-window
    :initform nil)
   (nested-context-windows
    :accessor codex-context-window-nested-context-windows-of
    :initarg :nested-context-windows
    :initform nil)
   (depth :accessor codex-context-window-depth-of
          :initarg :depth
          :initform 0)
   (max-depth :accessor codex-context-window-max-depth-of
              :initarg :max-depth
              :initform 0)
   (raw-text :accessor codex-context-window-raw-text-of
             :initarg :raw-text
             :initform nil)))

(defmethod print-object ((object codex-context-window) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-context-entry ()
  ((role :accessor codex-context-entry-role-of
         :initarg :role)
   (title :accessor title-of :initarg :title)
   (timestamp :accessor codex-context-entry-timestamp-of
              :initarg :timestamp)
   (text :accessor codex-context-entry-text-of
         :initarg :text)
   (references :accessor codex-context-entry-references-of
               :initarg :references)
   (derived-objects :accessor codex-context-entry-derived-objects-of
                    :initarg :derived-objects)))

(defmethod print-object ((object codex-context-entry) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-context-window-structural-proof ()
  ((title :accessor title-of :initarg :title)
   (context-window
    :accessor codex-context-window-structural-proof-context-window-of
    :initarg :context-window
    :initform nil)
   (graph :accessor codex-context-window-structural-proof-graph-of
          :initarg :graph)
   (expression
    :accessor codex-context-window-structural-proof-expression-of
    :initarg :expression)
   (result :accessor codex-context-window-structural-proof-result-of
           :initarg :result)
   (violations
    :accessor codex-context-window-structural-proof-violations-of
    :initarg :violations)
   (interpretation
    :accessor codex-context-window-structural-proof-interpretation-of
    :initarg :interpretation)))

(defmethod print-object ((object codex-context-window-structural-proof)
                         stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun codex-context-window-entry (role title text
                                   &key timestamp references derived-objects)
  (make-instance 'codex-context-entry
                 :role role
                 :title title
                 :timestamp timestamp
                 :text text
                 :references references
                 :derived-objects derived-objects))

(defun codex-context-window-chain (window &key (limit 10))
  (loop with current = window
        repeat limit
        while current
        collect current
        do (setf current
                 (codex-context-window-previous-context-window-of current))))

(defun codex-context-window-graph-node (window index repeated-p)
  (list :id (id-of window)
        :title (title-of window)
        :index index
        :depth (codex-context-window-depth-of window)
        :max-depth (codex-context-window-max-depth-of window)
        :repeated-p repeated-p))

(defun codex-context-window-graph (window &key (limit 10))
  (let ((effective-limit (max 0 limit))
        (nodes nil)
        (edges nil)
        (seen-node-ids nil)
        (repeated-node-ids nil)
        (current window)
        (steps 0)
        (terminal :nil)
        (truncated-p nil))
    (loop while (and current (< steps effective-limit))
          for node-id = (id-of current)
          for repeated-p = (member node-id seen-node-ids :test #'equal)
          do (push (codex-context-window-graph-node current steps repeated-p)
                   nodes)
             (if repeated-p
                 (progn
                   (pushnew node-id repeated-node-ids :test #'equal)
                   (setf terminal :cycle
                         current nil))
                 (let ((previous
                         (codex-context-window-previous-context-window-of
                          current)))
                   (push node-id seen-node-ids)
                   (if previous
                       (progn
                         (push (list :previous node-id (id-of previous))
                               edges)
                         (setf current previous))
                       (setf current nil
                             terminal :nil))))
             (incf steps))
    (when current
      (setf terminal :limit
            truncated-p t))
    (list :nodes (nreverse nodes)
          :edges (nreverse edges)
          :truncated-p truncated-p
          :limit effective-limit
          :terminal terminal
          :repeated-node-ids (nreverse repeated-node-ids))))

(defun codex-context-window-nor-expression ()
  '(nor (:self-previous-edge)
        (:repeated-node-or-cycle)
        (:depth-exceeds-limit)
        (:traversal-truncated-before-nil)))

(defun codex-context-window-duplicate-node-ids (graph)
  (loop with seen = nil
        with repeated = nil
        for node in (getf graph :nodes)
        for node-id = (getf node :id)
        do (if (member node-id seen :test #'equal)
               (pushnew node-id repeated :test #'equal)
               (push node-id seen))
        finally (return (nreverse repeated))))

(defun codex-context-window-nor-violations (graph)
  (let ((limit (getf graph :limit)))
    (append
     (loop for edge in (getf graph :edges)
           when (and (eq (first edge) :previous)
                     (equal (second edge) (third edge)))
             collect (list :predicate :self-previous-edge
                           :edge edge))
     (loop for node-id in (remove-duplicates
                           (append (getf graph :repeated-node-ids)
                                   (codex-context-window-duplicate-node-ids
                                    graph))
                           :test #'equal)
           collect (list :predicate :repeated-node-or-cycle
                         :node-id node-id))
     (loop for node in (getf graph :nodes)
           for depth = (getf node :depth)
           when (and depth (> depth limit))
             collect (list :predicate :depth-exceeds-limit
                           :node-id (getf node :id)
                           :depth depth
                           :limit limit))
     (when (getf graph :truncated-p)
       (list
        (list :predicate :traversal-truncated-before-nil
              :limit limit
              :terminal (getf graph :terminal)))))))

(defun codex-context-window-nor-proof-for-graph
    (graph &key context-window title interpretation)
  (let* ((violations (codex-context-window-nor-violations graph))
         (result (null violations)))
    (make-instance
     'codex-context-window-structural-proof
     :title (or title "Codex Context Window NOR Structural Proof")
     :context-window context-window
     :graph graph
     :expression (codex-context-window-nor-expression)
     :result result
     :violations violations
     :interpretation
     (or interpretation
         (if result
             "NOR-style structural proof passed: none of the forbidden recursive predicates matched the finite witness graph."
             "NOR-style structural proof failed: at least one forbidden recursive predicate matched the finite witness graph.")))))

(defun codex-context-window-nor-proof (window &key (limit 10))
  (codex-context-window-nor-proof-for-graph
   (codex-context-window-graph window :limit limit)
   :context-window window))

(defun codex-context-window ()
  (let ((previous
          (make-instance
           'codex-context-window
           :id "codex-kioskberrli-previous-context-window"
           :title "Previous Kioskberrli Context"
           :source "Codex/User collaboration thread"
           :captured-at "2026-05-14 previous review snapshot"
           :summary
           "Previous context: Codex Home was accepted as the entry surface before adding the context-window object."
           :entries
           (list
            (codex-context-window-entry
             "user"
             "Codex home approved"
             "The Codex Home view is accepted as the entry surface. The next Codex slice adds an inspectable context-window object reachable from that home surface."
             :timestamp "2026-05-14"
             :references '("Codex" "hyperdoc/codex.lisp"
                           "hyperdoc-explorer/codex.lisp")
             :derived-objects nil))
           :open-questions nil
           :proposed-actions nil
           :related-objects nil
           :validation-commands nil
           :provenance '("Finite previous context snapshot.")
           :depth 0
           :max-depth 1)))
    (make-instance
     'codex-context-window
     :id "codex-kioskberrli-context-window"
     :title "Codex Context Window"
     :source "Codex/User collaboration thread"
     :captured-at "2026-05-14 review snapshot"
     :summary
     "Current collaboration context for Codex Home and the Kioskberrli mobile station-board view: source topic Kioskberrli, target topic Kioskberrli Cross-Host Build Failure, and five primary mobile dashboard topics."
     :entries
     (list
      (codex-context-window-entry
       "slice"
       "Kioskberrli station-board review"
       "The pending review target is the object view for (hyperdoc::kioskberrli-dashboard), not the authored Kioskberrli Dashboard HTML page."
       :timestamp "2026-05-14"
       :references '("Kioskberrli Dashboard"
                     "Kioskberrli"
                     "Kioskberrli Cross-Host Build Failure")
       :derived-objects (list (kioskberrli-dashboard)
                              (kioskberrli-dashboard-status)
                              (kioskberrli-current-blocker)
                              (kioskberrli-build-evidence-status)
                              (kioskberrli-dashboard-stations)))
      (codex-context-window-entry
       "design"
       "Mobile station-board grammar"
       "The desired first mobile viewport is source topic Kioskberrli, target topic Kioskberrli Cross-Host Build Failure, and the five visible dashboard topics: Current status, Build evidence, Flash / boot evidence, Public-display layout state, and Related topic board."
       :timestamp "2026-05-14"
       :references '("Touch-Fahrplan route language"
                     "Kioskberrli Cross-Host Build Failure")
       :derived-objects (list (kioskberrli-dashboard))))
     :open-questions
     '("Is this Codex context-window object useful as the first inspectable current-context surface?"
       "After approval, should the next slice add only the Station board view for (hyperdoc::kioskberrli-dashboard)?")
     :proposed-actions
     '("Inspect (hyperdoc::codex-context-window) from SLY/CLOG."
       "If accepted, keep the next Kioskberrli iteration scoped to the dashboard object view and avoid editing the authored HTML page.")
     :related-objects
     (list (kioskberrli-dashboard)
           (kioskberrli-dashboard-status)
           (kioskberrli-current-blocker)
           (kioskberrli-build-evidence-status)
           (kioskberrli-dashboard-stations))
     :validation-commands
     '("nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/codex/explorer)' --eval '(assert (fboundp (quote hyperdoc::codex)))' --eval '(assert (fboundp (quote hyperdoc::codex-context-window)))' --eval '(assert (hyperdoc::codex-context-window))' --eval '(uiop:quit)'"
       "nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/codex/explorer)' --eval '(let* ((object (hyperdoc::codex-context-window)) (pane (make-instance (find-symbol \"PANE\" \"CLOG-MOLDABLE-INSPECTOR\") :inspector nil :object object))) (funcall (find-symbol \"LOAD-VIEWS\" \"CLOG-MOLDABLE-INSPECTOR\") pane) (let ((titles (mapcar (find-symbol \"VIEW-TITLE\" \"HTML-INSPECTOR-VIEWS\") (slot-value pane (find-symbol \"VIEWS\" \"CLOG-MOLDABLE-INSPECTOR\"))))) (assert (member \"Context\" titles :test #'string=))))' --eval '(uiop:quit)'"
       "git diff --check")
     :provenance
     '("AGENTS.md read before implementation."
       "Codex topic systems :hyperdoc/codex and :hyperdoc/codex/explorer already existed."
       "This object stores validation commands as strings only; it does not execute forms in the user's live Lisp image."
       "No server, external service, browser automation, or deployment behavior is part of this slice.")
     :previous-context-window previous
     :nested-context-windows (list previous)
     :depth 1
     :max-depth 1
     :raw-text
     "Codex context window snapshot: Codex Home is approved; current slice is the Kioskberrli mobile station-board object view; source topic is Kioskberrli; target topic is Kioskberrli Cross-Host Build Failure; primary topics are Current status, Build evidence, Flash / boot evidence, Public-display layout state, and Related topic board.")))

(defun codex ()
  (make-instance 'codex-home
                 :id "codex-home"
                 :title "Codex"
                 :summary "Inspectable collaboration home surface for the current HyperDoc review slice."
                 :current-slice "Kioskberrli mobile station-board view"
                 :context-window (codex-context-window)
                 :primary-review-object (kioskberrli-dashboard)
                 :related-objects (list (kioskberrli-dashboard-status)
                                        (kioskberrli-current-blocker)
                                        (kioskberrli-build-evidence-status)
                                        (kioskberrli-dashboard-stations))
                 :relevant-pages '("Kioskberrli"
                                   "Kioskberrli Dashboard"
                                   "Kioskberrli Cross-Host Build Failure")
                 :validation-commands
                 '("nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/tests)'"
                   "nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/tests)' --eval '(hyperdoc/tests:run-kioskberrli-dashboard-smoke-tests)'"
                   "tools/validate-documentation-slice.sh --page 'hyperdoc/Kioskberrli Dashboard.html'"
                   "git diff --check")
                 :commit-boundary "Codex materializes collaboration/review records and links to the target topic or system. Implementation changes still belong to the relevant target subsystem."))
