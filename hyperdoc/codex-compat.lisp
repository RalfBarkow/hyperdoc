;;;; Temporary compatibility wrappers for Dreyeck-owned Codex

(in-package :hyperdoc)

(defun codex-context-provider-result (provider-symbol)
  "Compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-PROVIDER-RESULT."
  (dreyeck/codex:codex-context-provider-result provider-symbol))

(defun codex-context-window-entry (role title text
                                   &key timestamp references derived-objects)
  "Compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-WINDOW-ENTRY."
  (dreyeck/codex:codex-context-window-entry
   role title text
   :timestamp timestamp
   :references references
   :derived-objects derived-objects))

(defun codex-context-window-chain (window &key (limit 10))
  "Compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-WINDOW-CHAIN."
  (dreyeck/codex:codex-context-window-chain window :limit limit))

(defun codex-context-window-graph (window &key (limit 10))
  "Compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-WINDOW-GRAPH."
  (dreyeck/codex:codex-context-window-graph window :limit limit))

(defun codex-context-window-nor-expression ()
  "Compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-WINDOW-NOR-EXPRESSION."
  (dreyeck/codex:codex-context-window-nor-expression))

(defun codex-context-window-nor-proof-for-graph
    (graph &key context-window title interpretation)
  "Compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-WINDOW-NOR-PROOF-FOR-GRAPH."
  (dreyeck/codex:codex-context-window-nor-proof-for-graph
   graph
   :context-window context-window
   :title title
   :interpretation interpretation))

(defun codex-context-window-nor-proof (window &key (limit 10))
  "Compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-WINDOW-NOR-PROOF."
  (dreyeck/codex:codex-context-window-nor-proof window :limit limit))

(defun codex-context-window ()
  "Temporary compatibility wrapper for DREYECK/CODEX:CODEX-CONTEXT-WINDOW."
  (dreyeck/codex:codex-context-window))

(defun codex-recent-changes-neighborhood ()
  "Compatibility wrapper for DREYECK/CODEX:CODEX-RECENT-CHANGES-NEIGHBORHOOD."
  (dreyeck/codex:codex-recent-changes-neighborhood))

(defun codex-recent-changes ()
  "Temporary compatibility wrapper for DREYECK/CODEX:CODEX-RECENT-CHANGES."
  (dreyeck/codex:codex-recent-changes))

(defun codex-next-for-recent-changes (changes &key limit)
  "Compatibility wrapper for DREYECK/CODEX:CODEX-NEXT-FOR-RECENT-CHANGES."
  (dreyeck/codex:codex-next-for-recent-changes changes :limit limit))

(defun codex-next ()
  "Temporary compatibility wrapper for DREYECK/CODEX:CODEX-NEXT."
  (dreyeck/codex:codex-next))

(defun codex-dmx-learning-topics ()
  "Temporary compatibility wrapper for DREYECK/CODEX:CODEX-DMX-LEARNING-TOPICS."
  (dreyeck/codex:codex-dmx-learning-topics))

(defun codex-dmx-learning-topic-status ()
  "Temporary compatibility wrapper for DREYECK/CODEX:CODEX-DMX-LEARNING-TOPIC-STATUS."
  (dreyeck/codex:codex-dmx-learning-topic-status))

(defun codex ()
  "Temporary compatibility wrapper for DREYECK/CODEX:CODEX."
  (dreyeck/codex:codex))
