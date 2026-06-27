;;;; Inspectable Codex context-window examples

(in-package :dreyeck/codex)

(defun codex-context-window-example ()
  (make-instance
   'codex-context-window
   :id "codex-context-window-example"
   :title "Codex Context Window Example"
   :source "Codex/User collaboration thread"
   :captured-at "2026-05-14 example snapshot"
   :summary
   "Single inspectable Codex context-window example with no parent or nested snapshots."
   :entries
   (list
    (codex-context-window-entry
     "example"
     "Single context snapshot"
     "This example proves the context-window object can stand alone without recursively materializing Codex Home."
     :timestamp "2026-05-14"
     :references '("Codex")
     :derived-objects nil))
   :open-questions nil
   :proposed-actions '("Inspect the context-window object from SLY/CLOG.")
   :related-objects nil
   :validation-commands
   '("nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/codex/examples)' --eval '(assert (dreyeck/codex:codex-context-window-example))' --eval '(uiop:quit)'")
   :provenance
   '("Deterministic example."
     "No external services, mutation, server startup, or eval bridge.")
   :depth 0
   :max-depth 0
   :raw-text nil))

(defun codex-kioskbeerli-context-window-example ()
  (codex-context-window))

(defun codex-recursive-context-window-example ()
  (let* ((initial
           (make-instance
            'codex-context-window
            :id "codex-context-initial"
            :title "Initial Codex Context"
            :source "Codex/User collaboration thread"
            :captured-at "2026-05-14 initial snapshot"
            :summary "Initial bounded context snapshot."
            :entries
            (list
             (codex-context-window-entry
              "initial"
              "Initial snapshot"
              "The chain starts here and has no previous context."
              :timestamp "2026-05-14"))
            :open-questions nil
            :proposed-actions nil
            :related-objects nil
            :validation-commands nil
            :provenance '("Finite recursive example.")
            :depth 0
            :max-depth 2))
         (previous
           (make-instance
            'codex-context-window
            :id "codex-context-previous"
            :title "Previous Codex Context"
            :source "Codex/User collaboration thread"
            :captured-at "2026-05-14 previous snapshot"
            :summary "Previous bounded context snapshot."
            :entries
            (list
             (codex-context-window-entry
              "previous"
              "Previous snapshot"
              "This snapshot points to the initial snapshot and stops there."
              :timestamp "2026-05-14"))
            :open-questions nil
            :proposed-actions nil
            :related-objects nil
            :validation-commands nil
            :provenance '("Finite recursive example.")
            :previous-context-window initial
            :nested-context-windows (list initial)
            :depth 1
            :max-depth 2)))
    (make-instance
     'codex-context-window
     :id "codex-context-current"
     :title "Current Codex Context"
     :source "Codex/User collaboration thread"
     :captured-at "2026-05-14 current snapshot"
     :summary "Current bounded context snapshot with a finite previous-context chain."
     :entries
     (list
      (codex-context-window-entry
       "current"
       "Current snapshot"
       "This snapshot points to previous, which points to initial; traversal is finite and bounded."
       :timestamp "2026-05-14"))
     :open-questions nil
     :proposed-actions '("Inspect each context-window level as an object link.")
     :related-objects nil
     :validation-commands
     '("nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/codex/examples)' --eval '(assert (= 3 (length (dreyeck/codex:codex-context-window-chain (dreyeck/codex:codex-recursive-context-window-example) :limit 10))))' --eval '(uiop:quit)'")
     :provenance '("Finite recursive example.")
     :previous-context-window previous
     :nested-context-windows (list previous initial)
     :depth 2
     :max-depth 2)))

(defun codex-recursive-context-window-graph-example ()
  (codex-context-window-graph
   (codex-recursive-context-window-example)
   :limit 10))

(defun codex-recursive-context-window-nor-proof-example ()
  (codex-context-window-nor-proof
   (codex-recursive-context-window-example)
   :limit 10))

(defun codex-cyclic-context-window-graph-example ()
  (list :nodes '((:id "cyclic-current"
                  :title "Synthetic Cyclic Context"
                  :index 0
                  :depth 0
                  :max-depth 1
                  :repeated-p nil)
                 (:id "cyclic-current"
                  :title "Synthetic Cyclic Context"
                  :index 1
                  :depth 1
                  :max-depth 1
                  :repeated-p t))
        :edges '((:previous "cyclic-current" "cyclic-current"))
        :truncated-p nil
        :limit 10
        :terminal :cycle
        :repeated-node-ids '("cyclic-current")))

(defun codex-cyclic-context-window-graph-proof-example ()
  (codex-context-window-nor-proof-for-graph
   (codex-cyclic-context-window-graph-example)
   :title "Synthetic Cyclic Codex Context NOR Structural Proof"
   :interpretation
   "NOR-style structural proof failed as expected: the synthetic witness graph contains forbidden cyclic previous-context structure without creating a live cyclic Lisp object."))

(defun codex-recent-changes-example ()
  (codex-recent-changes))

(defun codex-next-example ()
  (codex-next))

(defun codex-next-for-kioskbeerli-pending-work-example ()
  (let ((changes
          (make-instance
           'codex-recent-changes
           :id "codex-kioskbeerli-pending-recent-changes"
           :title "Kioskbeerli Pending Recent Changes"
           :source "Deterministic Codex example"
           :captured-at "2026-05-15 example snapshot"
           :scope "Only the pending Kioskbeerli boundary entry."
           :summary
           "Example recent-changes object focused on pending Kioskbeerli station-board work."
           :entries (list (codex--kioskbeerli-pending-change))
           :neighborhood '("Codex" "Kioskbeerli Dashboard")
           :provenance
           '("Deterministic example."
             "No external services, git, validation, server startup, or file mutation.")
           :limit 2)))
    (codex-next-for-recent-changes changes :limit 2)))
