;;;; Reusable inspectable code-path / call-graph objects
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defstruct code-path-graph
  id
  title
  summary
  entrypoints
  nodes
  edges
  trace-events
  focus-paths)

(defstruct (playground-stepper-code-path-graph
             (:include code-path-graph))
  package-name
  source-selection
  progress-label
  parse-error-p
  done-p)

(defstruct (dmx-workspace-journal-reconcile-call-graph
             (:include code-path-graph))
  workspace-id
  workspace-topicmap-id
  resolved-note-topic-id
  resolved-note-key
  resolved-topicmap-context-assoc-id
  companion-journal-topic-id
  failing-endpoints)

(defun code-path-graph-seq (items)
  (cond
    ((null items) '())
    ((listp items) items)
    ((vectorp items) (coerce items 'list))
    (t (list items))))

(defun code-path-graph-node-seq (graph)
  (code-path-graph-seq (code-path-graph-nodes graph)))

(defun code-path-graph-edge-seq (graph)
  (code-path-graph-seq (code-path-graph-edges graph)))

(defun code-path-graph-entrypoint-seq (graph)
  (code-path-graph-seq (code-path-graph-entrypoints graph)))

(defun code-path-graph-trace-event-seq (graph)
  (code-path-graph-seq (code-path-graph-trace-events graph)))

(defun code-path-graph-focus-path-seq (graph)
  (code-path-graph-seq (code-path-graph-focus-paths graph)))

(defun code-path-graph-human-label (value)
  (let ((text (cond
                ((null value) "")
                ((keywordp value) (symbol-name value))
                ((symbolp value) (symbol-name value))
                ((stringp value) value)
                (t (format nil "~A" value)))))
    (with-output-to-string (stream)
      (loop for char across text
            do (write-char
                (case char
                  ((#\- #\_) #\Space)
                  (otherwise (char-downcase char)))
                stream)))))

(defun code-path-graph-node-id (node)
  (getf node :id))

(defun code-path-graph-node (graph node-id)
  (find node-id
        (code-path-graph-node-seq graph)
        :test #'string=
        :key #'code-path-graph-node-id))

(defun code-path-graph-edge (graph from to)
  (find-if (lambda (edge)
             (and (string= from (getf edge :from))
                  (string= to (getf edge :to))))
           (code-path-graph-edge-seq graph)))

(defun code-path-graph-node-label (graph node-id)
  (or (getf (code-path-graph-node graph node-id) :label)
      node-id))

(defun code-path-graph-role-label (role)
  (case role
    (:read-entry "read entry")
    (:read-helper "read helper")
    (:diff-engine "diff engine")
    (:safe-read-edge "in-memory read edge")
    (:write-helper "write helper")
    (:write-entry "explicit write path")
    (:backend-target "backend target")
    (:runtime-entry "runtime entry")
    (:runtime-read "runtime read")
    (:runtime-step "runtime step")
    (:runtime-value "runtime value")
    (:runtime-error "runtime error")
    (:runtime-terminal "runtime terminal")
    (:runtime-input "runtime input")
    (otherwise
     (code-path-graph-human-label role))))

(defun code-path-graph-edge-kind-label (kind)
  (case kind
    (:read "read")
    (:read-diff "read diff")
    (:safe-read "safe read")
    (:suppressed-write "suppressed write")
    (:write "write")
    (:write-preflight "write preflight")
    (:backend-write "backend write")
    (:parse "parse")
    (:step "step")
    (:terminal "terminal")
    (:result "result")
    (otherwise
     (code-path-graph-human-label kind))))

(defun code-path-graph-edge-status-label (status)
  (case status
    (:active "active")
    (:suppressed "suppressed")
    (:write-path "explicit write path")
    (:completed "completed")
    (:current "current")
    (:pending "pending")
    (:error "error")
    (:parse-error "parse error")
    (otherwise
     (code-path-graph-human-label status))))

(defun code-path-graph-source-label (node)
  (let ((file (getf node :source-file))
        (function (getf node :source-function)))
    (cond
      ((and file function)
       (format nil "~A :: ~A" file function))
      (file file)
      (function function)
      (t nil))))

(defun code-path-graph-entrypoint-label (entrypoint)
  (cond
    ((and (listp entrypoint) (getf entrypoint :label))
     (getf entrypoint :label))
    ((stringp entrypoint) entrypoint)
    ((symbolp entrypoint) (code-path-graph-human-label entrypoint))
    (t (format nil "~A" entrypoint))))

(defun code-path-graph-entrypoint-summary (entrypoint)
  (and (listp entrypoint)
       (getf entrypoint :summary)))

(defun code-path-graph-focus-path-id (focus-path)
  (and (listp focus-path)
       (or (getf focus-path :id)
           (getf focus-path :label))))

(defun code-path-graph-focus-path-label (focus-path)
  (cond
    ((and (listp focus-path) (getf focus-path :label))
     (getf focus-path :label))
    ((and (listp focus-path) (getf focus-path :id))
     (code-path-graph-human-label (getf focus-path :id)))
    ((stringp focus-path) focus-path)
    (t (format nil "~A" focus-path))))

(defun code-path-graph-focus-path-summary (focus-path)
  (and (listp focus-path)
       (getf focus-path :summary)))

(defun code-path-graph-focus-path-node-ids (focus-path)
  (code-path-graph-seq
   (and (listp focus-path)
        (or (getf focus-path :node-ids)
            (getf focus-path :nodes)))))

(defun code-path-graph-focus-path-nodes (graph focus-path)
  (remove nil
          (mapcar (lambda (node-id)
                    (code-path-graph-node graph node-id))
                  (code-path-graph-focus-path-node-ids focus-path))))

(defun code-path-graph-focus-path-edges (graph focus-path)
  (let ((node-ids (code-path-graph-focus-path-node-ids focus-path)))
    (loop for remaining on node-ids
          for from = (first remaining)
          for to = (second remaining)
          while to
          for edge = (code-path-graph-edge graph from to)
          when edge
            collect edge)))

(defun code-path-graph-active-edges (graph)
  (remove-if-not (lambda (edge)
                   (eq (getf edge :status) :active))
                 (code-path-graph-edge-seq graph)))

(defun code-path-graph-write-capable-edges (graph)
  (remove-if-not (lambda (edge)
                   (getf edge :write-capable-p))
                 (code-path-graph-edge-seq graph)))

(defun code-path-graph-dot-escape (string)
  (with-output-to-string (stream)
    (loop for char across (or string "")
          do (case char
               (#\\ (write-string "\\\\" stream))
               (#\" (write-string "\\\"" stream))
               (#\Newline (write-string "\\n" stream))
               (otherwise (write-char char stream))))))

(defun code-path-graph-dot-quoted (string)
  (format nil "\"~A\"" (code-path-graph-dot-escape string)))

(defun code-path-graph-dot-node-label (node)
  (format nil "~{~A~^\\n~}"
          (remove nil
                  (list (or (getf node :label)
                            (getf node :id))
                        (when-let (role (getf node :role))
                          (code-path-graph-role-label role))
                        (when-let (kind (getf node :kind))
                          (code-path-graph-human-label kind))))))

(defun code-path-graph-dot-edge-label (edge)
  (let ((parts (remove nil
                       (list (when-let (kind (getf edge :kind))
                               (code-path-graph-edge-kind-label kind))
                             (let ((status (getf edge :status)))
                               (when (and status
                                          (not (eq status :active)))
                                 (code-path-graph-edge-status-label status)))))))
    (when parts
      (format nil "~{~A~^ / ~}" parts))))

(defun code-path-graph-dot-text (graph &key (rankdir "LR"))
  (with-output-to-string (stream)
    (format stream "digraph ~A {~%" (code-path-graph-dot-quoted
                                     (or (code-path-graph-id graph)
                                         (code-path-graph-title graph)
                                         "CodePathGraph")))
    (format stream "  rankdir=~A;~%" rankdir)
    (format stream "  node [shape=box, fontname=\"Helvetica\"];~%")
    (dolist (node (code-path-graph-node-seq graph))
      (format stream
              "  ~A [label=~A];~%"
              (code-path-graph-dot-quoted (or (getf node :id)
                                              (getf node :label)))
              (code-path-graph-dot-quoted
               (code-path-graph-dot-node-label node))))
    (when (code-path-graph-node-seq graph)
      (terpri stream))
    (dolist (edge (code-path-graph-edge-seq graph))
      (format stream "  ~A -> ~A"
              (code-path-graph-dot-quoted (getf edge :from))
              (code-path-graph-dot-quoted (getf edge :to)))
      (let ((attributes '()))
        (when-let (label (code-path-graph-dot-edge-label edge))
          (push (format nil "label=~A" (code-path-graph-dot-quoted label))
                attributes))
        (when (eq (getf edge :status) :suppressed)
          (push "style=dashed" attributes))
        (when (getf edge :write-capable-p)
          (push "color=\"firebrick\"" attributes))
        (when attributes
          (format stream " [~{~A~^, ~}]" (nreverse attributes))))
      (format stream ";~%"))
    (format stream "}~%")))

(defun dmx-workspace-journal-reconcile-call-graph ()
  (make-dmx-workspace-journal-reconcile-call-graph
   :id "dmx-workspace-journal-reconcile-call-graph"
   :title "DMX workspace journal reconcile call graph"
   :summary
   "Inspectable call graph for reconcile-on-read in workspace topicmap 919822, centered on companion journal note 924694 and the write-capable persistence edge that must stay suppressed during read reconciliation."
   :entrypoints
   (list
    (list :id "workspace-read"
          :label "read-dmx-workspace-journal"
          :summary
          "Workspace-wide read entrypoint for reconcile=true journal inspection.")
    (list :id "topic-read"
          :label "read-dmx-topic-journal"
          :summary
          "Single-subject read entrypoint that reuses the same reconcile-on-read boundary."))
   :focus-paths
   (list
    (list :id "workspace-reconcile-on-read"
          :label "Workspace reconcile-on-read"
          :summary
          "The active workspace-wide read path now keeps synthesized diff events in memory."
          :node-ids '("read-workspace-journal"
                      "reconcile-workspace"
                      "reconcile-subject"
                      "transition-events"
                      "apply-events-to-stream"))
    (list :id "topic-reconcile-on-read"
          :label "Topic reconcile-on-read"
          :summary
          "Single-topic journal reads route through the same side-effect-free reconcile path."
          :node-ids '("read-topic-journal"
                      "locate-stream"
                      "reconcile-workspace"
                      "reconcile-subject"
                      "transition-events"
                      "apply-events-to-stream"))
    (list :id "explicit-write-path"
          :label "Explicit write path"
          :summary
          "Guarded writes and restores still legitimately append and persist journal events."
          :node-ids '("record-transition"
                      "append-events"
                      "persist-stream"
                      "companion-journal-note")))
   :workspace-id 919815
   :workspace-topicmap-id 919822
   :resolved-note-topic-id 923609
   :resolved-note-key
   "handover-assist-with-assoc-by-assoc-proof-for-shared-workspace-boundary-3983920759"
   :resolved-topicmap-context-assoc-id 923622
   :companion-journal-topic-id 924694
   :failing-endpoints
   (list
    (list :surface "Live adapter reconcile read"
          :endpoint "/core/topic/924694"
          :status "500"
          :summary
          "Direct adapter-side failure observed while reconcile=true was traversing the companion journal note.")
    (list :surface "Authoritative nix-side reproduce"
          :endpoint "/topicmaps/919822/topic/924694"
          :status "500"
          :summary
          "Read reconciliation write-touched the companion note membership path before the read-only patch."))
   :nodes
   (list
    (list :id "read-workspace-journal"
          :label "read-dmx-workspace-journal"
          :role :read-entry
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "read-dmx-workspace-journal"
          :summary
          "Workspace-wide journal read entrypoint; when reconcile is true it now forces :persist-events-p nil.")
    (list :id "read-topic-journal"
          :label "read-dmx-topic-journal"
          :role :read-entry
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "read-dmx-topic-journal"
          :summary
          "Single-subject journal read entrypoint; it resolves one stream through the same reconcile-on-read boundary.")
    (list :id "locate-stream"
          :label "dmx-workspace-journal-locate-stream"
          :role :read-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-locate-stream"
          :summary
          "Selects a stream by subject key or topic id and routes reconcile=true reads through workspace reconciliation.")
    (list :id "reconcile-workspace"
          :label "dmx-workspace-journal-reconcile-workspace"
          :role :read-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-reconcile-workspace"
          :summary
          "Collects stored streams, derives live snapshots from topicmap 919822, and reconciles each subject.")
    (list :id "collect-streams"
          :label "dmx-workspace-journal-collect-streams"
          :role :read-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-collect-streams"
          :summary
          "Reads the hidden companion journal notes already present in topicmap 919822.")
    (list :id "live-topic-snapshots"
          :label "dmx-workspace-journal-live-topic-snapshots"
          :role :read-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-live-topic-snapshots"
          :summary
          "Builds the live snapshot table from the visible topicmap projection while skipping companion journal notes themselves.")
    (list :id "reconcile-subject"
          :label "dmx-workspace-journal-reconcile-subject"
          :role :read-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-reconcile-subject"
          :summary
          "Diffs the stored stream against the current live state and decides whether synthesized events stay in memory or are persisted.")
    (list :id "read-stream"
          :label "dmx-workspace-journal-read-stream"
          :role :read-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-read-stream"
          :summary
          "Reads the existing companion journal note stream or synthesizes an empty base stream.")
    (list :id "live-snapshot-from-stream"
          :label "dmx-workspace-journal-live-snapshot-from-stream"
          :role :read-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-live-snapshot-from-stream"
          :summary
          "Refreshes the current DMX state for one subject from the live backend.")
    (list :id "transition-events"
          :label "dmx-workspace-journal-transition-events"
          :role :diff-engine
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-transition-events"
          :summary
          "Synthesizes the event diff between stored and live snapshots, including topicmap membership and view-props changes.")
    (list :id "apply-events-to-stream"
          :label "dmx-workspace-journal-apply-events-to-stream"
          :role :safe-read-edge
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-apply-events-to-stream"
          :summary
          "Applies synthesized events to the in-memory stream only and updates currentRevision without touching DMX.")
    (list :id "append-events"
          :label "dmx-workspace-journal-append-events"
          :role :write-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-append-events"
          :summary
          "Shared append helper for real writes; it is legitimate on explicit write paths but must be suppressed during reconcile-on-read.")
    (list :id "persist-stream"
          :label "dmx-workspace-journal-persist-stream"
          :role :write-helper
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-persist-stream"
          :summary
          "Persists the companion journal note and reattaches it to topicmap 919822 if the membership probe thinks it is absent.")
    (list :id "prepare-transition"
          :label "dmx-workspace-journal-prepare-transition"
          :role :write-entry
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-prepare-transition"
          :summary
          "Explicit write preflight; it may reconcile first, but only to prepare a guarded write path.")
    (list :id "record-transition"
          :label "dmx-workspace-journal-record-transition"
          :role :write-entry
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "dmx-workspace-journal-record-transition"
          :summary
          "Explicit guarded write recorder; it persists journal events after a real topic or note mutation.")
    (list :id "restore-topic-revision"
          :label "restore-dmx-workspace-topic-revision"
          :role :write-entry
          :source-file "hyperdoc/dmx-workspace-journal.lisp"
          :source-function "restore-dmx-workspace-topic-revision"
          :summary
          "Explicit restore path; it may persist restore events after validating the live result.")
    (list :id "companion-journal-note"
          :label "Companion journal note 924694"
          :role :backend-target
          :summary
          "Hidden HyperDoc-owned workspace-journal note in topicmap 919822 that must not be mutated, reattached, or otherwise write-touched during reconcile-on-read."))
   :edges
   (list
    (list :from "read-workspace-journal"
          :to "reconcile-workspace"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "reconcile=true enters workspace reconciliation in read-only mode.")
    (list :from "read-topic-journal"
          :to "locate-stream"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "Single-subject reads resolve a stream before returning revisions and current state.")
    (list :from "locate-stream"
          :to "reconcile-workspace"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "reconcile=true topic reads reuse workspace reconciliation rather than bypassing it.")
    (list :from "reconcile-workspace"
          :to "collect-streams"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "Load the stored companion journal streams already present in topicmap 919822.")
    (list :from "reconcile-workspace"
          :to "live-topic-snapshots"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "Read the current visible topicmap projection and derive live snapshots.")
    (list :from "reconcile-workspace"
          :to "reconcile-subject"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "Every stored or newly discovered subject is reconciled against the live snapshot table.")
    (list :from "reconcile-subject"
          :to "read-stream"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "Open the companion note stream or synthesize an empty base stream.")
    (list :from "reconcile-subject"
          :to "live-snapshot-from-stream"
          :kind :read
          :status :active
          :write-capable-p nil
          :summary
          "Read the live DMX state for the subject currently being reconciled.")
    (list :from "reconcile-subject"
          :to "transition-events"
          :kind :read-diff
          :status :active
          :write-capable-p nil
          :summary
          "Derive synthesized events from the stored/live snapshot diff.")
    (list :from "reconcile-subject"
          :to "apply-events-to-stream"
          :kind :safe-read
          :status :active
          :write-capable-p nil
          :summary
          "The active reconcile-on-read edge: synthesized events are applied to the in-memory stream only.")
    (list :from "reconcile-subject"
          :to "append-events"
          :kind :suppressed-write
          :status :suppressed
          :write-capable-p t
          :summary
          "Previously used during reconcile-on-read; now suppressed unless the caller explicitly allows persistence.")
    (list :from "append-events"
          :to "persist-stream"
          :kind :write
          :status :write-path
          :write-capable-p t
          :summary
          "Legitimate write helper edge for explicit journal writes and restores.")
    (list :from "persist-stream"
          :to "companion-journal-note"
          :kind :backend-write
          :status :write-path
          :write-capable-p t
          :summary
          "Writes the hidden companion note payload and may call add-to-topicmap when membership appears absent.")
    (list :from "prepare-transition"
          :to "reconcile-subject"
          :kind :write-preflight
          :status :write-path
          :write-capable-p nil
          :summary
          "Allowed pre-write state sync before a guarded mutation preview.")
    (list :from "record-transition"
          :to "append-events"
          :kind :write
          :status :write-path
          :write-capable-p t
          :summary
          "Normal guarded write path that records in-band journal events after a real mutation.")
    (list :from "restore-topic-revision"
          :to "append-events"
          :kind :write
          :status :write-path
          :write-capable-p t
          :summary
          "Explicit restore path that persists restore events after validation."))))
