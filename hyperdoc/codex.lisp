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
   (recent-changes :accessor codex-home-recent-changes-of
                   :initarg :recent-changes)
   (next :accessor codex-home-next-of
         :initarg :next)
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

(defclass codex-recent-changes ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source :accessor codex-recent-changes-source-of
           :initarg :source)
   (captured-at :accessor codex-recent-changes-captured-at-of
                :initarg :captured-at)
   (scope :accessor codex-recent-changes-scope-of
          :initarg :scope)
   (summary :accessor summary-of :initarg :summary)
   (entries :accessor codex-recent-changes-entries-of
            :initarg :entries)
   (neighborhood :accessor codex-recent-changes-neighborhood-of
                 :initarg :neighborhood)
   (provenance :accessor codex-recent-changes-provenance-of
               :initarg :provenance)
   (limit :accessor codex-recent-changes-limit-of
          :initarg :limit)))

(defmethod print-object ((object codex-recent-changes) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-recent-change ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (kind :accessor codex-recent-change-kind-of
         :initarg :kind)
   (changed-at :accessor codex-recent-change-changed-at-of
               :initarg :changed-at)
   (actor :accessor codex-recent-change-actor-of
          :initarg :actor)
   (summary :accessor summary-of :initarg :summary)
   (source-object :accessor codex-recent-change-source-object-of
                  :initarg :source-object
                  :initform nil)
   (target-object :accessor codex-recent-change-target-object-of
                  :initarg :target-object
                  :initform nil)
   (affected-files :accessor codex-recent-change-affected-files-of
                   :initarg :affected-files
                   :initform nil)
   (affected-pages :accessor codex-recent-change-affected-pages-of
                   :initarg :affected-pages
                   :initform nil)
   (evidence :accessor codex-recent-change-evidence-of
             :initarg :evidence
             :initform nil)
   (route-hints :accessor codex-recent-change-route-hints-of
                :initarg :route-hints
                :initform nil)))

(defmethod print-object ((object codex-recent-change) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-next ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source :accessor codex-next-source-of
           :initarg :source)
   (changes :accessor codex-next-changes-of
            :initarg :changes)
   (routes :accessor codex-next-routes-of
           :initarg :routes)
   (summary :accessor summary-of :initarg :summary)
   (generated-at :accessor codex-next-generated-at-of
                 :initarg :generated-at)
   (provenance :accessor codex-next-provenance-of
               :initarg :provenance)))

(defmethod print-object ((object codex-next) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-next-route ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source-topic :accessor codex-next-route-source-topic-of
                 :initarg :source-topic)
   (target-topic :accessor codex-next-route-target-topic-of
                 :initarg :target-topic
                 :initform nil)
   (target-operation :accessor codex-next-route-target-operation-of
                     :initarg :target-operation)
   (reason :accessor codex-next-route-reason-of
           :initarg :reason)
   (derived-from :accessor codex-next-route-derived-from-of
                 :initarg :derived-from)
   (priority :accessor codex-next-route-priority-of
             :initarg :priority)
   (safety-level :accessor codex-next-route-safety-level-of
                 :initarg :safety-level)
   (status :accessor codex-next-route-status-of
           :initarg :status)
   (action-label :accessor codex-next-route-action-label-of
                 :initarg :action-label)
   (evidence :accessor codex-next-route-evidence-of
             :initarg :evidence
             :initform nil)
   (related-objects :accessor codex-next-route-related-objects-of
                    :initarg :related-objects
                    :initform nil)))

(defmethod print-object ((object codex-next-route) stream)
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

(defun codex-recent-changes-neighborhood ()
  '("Codex"
    "Codex context window"
    "Codex examples"
    "Recursive context-window structural proof"
    "Kioskberrli station-board pending work"))

(defun codex--recent-change (id title kind summary
                             &key changed-at actor source-object
                               target-object affected-files affected-pages
                               evidence route-hints)
  (make-instance 'codex-recent-change
                 :id id
                 :title title
                 :kind kind
                 :changed-at changed-at
                 :actor actor
                 :summary summary
                 :source-object source-object
                 :target-object target-object
                 :affected-files affected-files
                 :affected-pages affected-pages
                 :evidence evidence
                 :route-hints route-hints))

(defun codex--kioskberrli-pending-change ()
  (codex--recent-change
   "kioskberrli-station-board-pending"
   "Kioskberrli station-board work pending"
   :working-tree
   "Uncommitted Kioskberrli station-board/page/test work remains pending and should stay out of this Codex topic-system slice."
   :changed-at "2026-05-15 pending workspace state"
   :actor "user workspace"
   :target-object (kioskberrli-dashboard)
   :affected-files '("hyperdoc/Kioskberrli Dashboard.html"
                     "hyperdoc/Kioskberrli.html"
                     "tests/kioskberrli-dashboard-smoke.lisp"
                     "tests/package.lisp")
   :affected-pages '("Kioskberrli Dashboard" "Kioskberrli")
   :evidence '("Observed as pre-existing dirty workspace state before this slice."
               "This deterministic model entry records the boundary; it does not query git.")
   :route-hints '("Continue only after inspecting live CLOG rendering."
                  "Choose whether the next change belongs to an authored page or an inspector object view.")))

(defun codex--default-recent-change-entries ()
  (list
   (codex--recent-change
    "codex-home-added"
    "Codex home object added"
    :topic
    "Codex became the shared inspectable home object for collaboration review state."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :affected-files '("hyperdoc/codex.lisp"
                      "hyperdoc-explorer/codex.lisp")
    :affected-pages '("Codex")
    :evidence '("Committed slice d6ee511 introduced the Codex topic ASDF coordinate."
                "(hyperdoc::codex) is the shared inspectable home object.")
    :route-hints '("Keep the home compact."
                   "Link to derived objects instead of inlining them."))
   (codex--recent-change
    "codex-context-window-added"
    "Codex context window added"
    :context-window
    "The Codex context-window object became reachable from Codex Home as the bounded current-context surface."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :target-object (codex-context-window)
    :affected-files '("hyperdoc/codex.lisp"
                      "hyperdoc-explorer/codex.lisp")
    :affected-pages '("Codex")
    :evidence '("(hyperdoc::codex-context-window) loads through :hyperdoc/codex."
                "Codex Home links to the context-window object.")
    :route-hints '("Inspect the context window before broadening the slice."))
   (codex--recent-change
    "codex-examples-coordinate-added"
    "Codex examples ASDF coordinate added"
    :example
    "The :hyperdoc/codex/examples system provides deterministic inspectable Codex examples."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :affected-files '("hyperdoc.asd"
                      "hyperdoc/codex-examples.lisp")
    :evidence '(":hyperdoc/codex/examples loads deterministic examples."
                "Examples do not call services, run validation, or mutate files.")
    :route-hints '("Use examples as the first proof objects for new Codex concepts."))
   (codex--recent-change
    "codex-recursive-structural-proof-added"
    "Recursive context-window structural proof added"
    :proof
    "A NOR-style structural proof checks finite context-window traversal for forbidden recursive shapes."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :affected-files '("hyperdoc/codex.lisp"
                      "hyperdoc/codex-examples.lisp"
                      "hyperdoc-explorer/codex.lisp")
    :evidence '("codex-context-window-nor-proof returns an inspectable proof object."
                "Recursive examples expose finite and cyclic witness graphs.")
    :route-hints '("Inspect proof examples as route evidence before adding live adapters."))
   (codex--kioskberrli-pending-change)))

(defun codex-recent-changes ()
  (make-instance
   'codex-recent-changes
   :id "codex-recent-changes"
   :title "Recent Changes"
   :source "Deterministic Codex collaboration snapshot"
   :captured-at "2026-05-15 bounded model snapshot"
   :scope "Current Codex collaboration neighborhood; no live federation, git, MCP, or remote queries."
   :summary "What changed recently in this collaboration neighborhood."
   :entries (codex--default-recent-change-entries)
   :neighborhood (codex-recent-changes-neighborhood)
   :provenance '("Motivated by Federated Wiki's recent changes here and nearby idea."
                 "Encoded as deterministic inspectable model data for this slice."
                 "No external services, git discovery, MCP queries, or mutation.")
   :limit 5))

(defun codex--recent-change-by-id (changes id)
  (find id (codex-recent-changes-entries-of changes)
        :key #'id-of
        :test #'equal))

(defun codex--next-route (id title source-topic target-topic
                          target-operation reason derived-from priority
                          safety-level status action-label
                          &key evidence related-objects)
  (make-instance 'codex-next-route
                 :id id
                 :title title
                 :source-topic source-topic
                 :target-topic target-topic
                 :target-operation target-operation
                 :reason reason
                 :derived-from derived-from
                 :priority priority
                 :safety-level safety-level
                 :status status
                 :action-label action-label
                 :evidence evidence
                 :related-objects related-objects))

(defun codex--next-routes-for-recent-changes (changes)
  (let ((context-change
          (codex--recent-change-by-id changes "codex-context-window-added"))
        (proof-change
          (codex--recent-change-by-id
           changes "codex-recursive-structural-proof-added"))
        (kioskberrli-change
          (codex--recent-change-by-id
           changes "kioskberrli-station-board-pending")))
    (append
     (when context-change
       (list
        (codex--next-route
         "inspect-codex-context-window"
         "Inspect context window"
         "Codex"
         "Codex context window"
         "inspect current context"
         "The recent change made the bounded context-window object reachable from Codex Home."
         context-change
         1
         :inspect
         :available
         "Inspect"
         :evidence '("(hyperdoc::codex-context-window) is deterministic and inspectable.")
         :related-objects (list (codex-context-window)))))
     (when proof-change
       (list
        (codex--next-route
         "inspect-structural-proof-examples"
         "Inspect structural proof"
         "Codex"
         "recursive context-window NOR proof"
         "inspect proof examples"
         "The proof recent change supplies deterministic evidence for bounded recursive context-window traversal."
         proof-change
         2
         :inspect
         :available
         "Inspect"
         :evidence '("Use codex-recursive-context-window-nor-proof-example after loading :hyperdoc/codex/examples."))))
     (when kioskberrli-change
       (list
        (codex--next-route
         "continue-kioskberrli-station-board-view"
         "Continue station-board view"
         "Codex"
         "Kioskberrli Dashboard / Kioskberrli mobile station-board"
         "inspect pending station-board work"
         "Pending Kioskberrli work is visible in the collaboration neighborhood but needs live-rendering evidence before continuation."
         kioskberrli-change
         3
         :dry-run
         :needs-evidence
         "Inspect"
         :evidence '("Pre-existing workspace state says Kioskberrli page/test work remains pending.")
         :related-objects (list (kioskberrli-dashboard)))
        (codex--next-route
         "decide-kioskberrli-page-vs-object-view"
         "Decide page vs object view"
         "Kioskberrli Dashboard"
         "Kioskberrli mobile station-board"
         "choose authored-page path or inspector-view path"
         "The pending work can plausibly continue as authored HyperDoc page work or as an inspector object-view change; the boundary needs confirmation."
         kioskberrli-change
         4
         :confirm
         :needs-evidence
         "Decide"
         :evidence '("The current slice must not mix Kioskberrli page/test edits into Codex topic-system work.")
         :related-objects (list (kioskberrli-dashboard)))))
     (when context-change
       (list
        (codex--next-route
         "plan-mcp-context-window-refresh"
         "Plan MCP refresh"
         "Codex context window"
         "DMX / MCP shared workspace"
         "plan context-window refresh adapter"
         "A later adapter can refresh Codex context from MCP or DMX once the deterministic object shape is accepted."
         context-change
         5
         :dry-run
         :deferred
         "Plan"
         :evidence '("This slice intentionally does not query MCP, DMX, git, or remote sites.")))))))

(defun codex-next-for-recent-changes (changes &key limit)
  (let* ((effective-limit (max 0 (or limit 5)))
         (routes (codex--next-routes-for-recent-changes changes))
         (primary-routes (subseq routes 0 (min effective-limit
                                                (length routes)))))
    (make-instance
     'codex-next
     :id "codex-next"
     :title "Next"
     :source changes
     :changes changes
     :routes primary-routes
     :summary "Given these recent changes, plausible source-to-target operation routes for the next Codex move."
     :generated-at "2026-05-15 deterministic route derivation"
     :provenance '("Derived from codex-recent-changes entries."
                   "At most five primary routes are generated by default."
                   "No external services, git discovery, MCP queries, validation runs, or mutation."))))

(defun codex-next ()
  (codex-next-for-recent-changes (codex-recent-changes)))

(defun codex ()
  (make-instance 'codex-home
                 :id "codex-home"
                 :title "Codex"
                 :summary "Inspectable collaboration home surface for the current HyperDoc review slice."
                 :current-slice "Kioskberrli mobile station-board view"
                 :context-window (codex-context-window)
                 :recent-changes (codex-recent-changes)
                 :next (codex-next)
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
