;;;; Small public MREPL entrypoints for Kioskbeerli.

(in-package :kioskbeerli)

(defun make-demo-dashboard ()
  "Return the canonical Kioskbeerli dashboard object."
  (kioskbeerli-dashboard))

(defun make-demo-plan ()
  "Return the canonical Kioskbeerli plan-only workflow object."
  (kioskbeerli-planner-run))

(defun make-demo-trace ()
  "Return the canonical in-memory Kioskbeerli project trace."
  (kioskbeerli-project-trace))

(defun inspect-demo-dashboard ()
  "Open the demo dashboard in the CLOG moldable inspector when available."
  (%clog-inspect (make-demo-dashboard)))

(defun record-trace-event
    (&key (trace (make-demo-trace))
       store
       id
       (timestamp "stable-placeholder")
       (actor "codex")
       task-id
       from-state
       to-state
       scxml-event
       (status "unknown")
       evidence-paths
       note
       payload
       source-fedwiki-slug
       source-asset-reference
       source-hyperdoc-reference)
  "Record a local trace event, optionally persisting it to a SQLite store."
  (let* ((updated-trace
           (record-kioskbeerli-progress
            :trace trace
            :id id
            :timestamp timestamp
            :actor actor
            :task-id task-id
            :from-state from-state
            :to-state to-state
            :scxml-event scxml-event
            :status status
            :evidence-paths evidence-paths
            :note note))
         (entry (kioskbeerli-latest-progress updated-trace)))
    (when store
      (persist-trace-event store
                           entry
                           :payload payload
                           :trace-id (id-of updated-trace)
                           :source-fedwiki-slug source-fedwiki-slug
                           :source-asset-reference source-asset-reference
                           :source-hyperdoc-reference source-hyperdoc-reference))
    entry))
