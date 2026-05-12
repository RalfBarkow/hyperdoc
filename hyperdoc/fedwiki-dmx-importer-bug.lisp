;;;; Shared surface for the FedWiki-to-DMX importer workspace assignment bug.
;;;;
;;;; This file backs the expression links in
;;;; hyperdoc/FedWiki-to-DMX importer workspace assignment bug.html.

(in-package :hyperdoc)

(defparameter *fedwiki-dmx-importer-bug-page-title*
  "FedWiki-to-DMX importer workspace assignment bug")

(defparameter *fedwiki-dmx-importer-bug-page-relative-path*
  "hyperdoc/FedWiki-to-DMX importer workspace assignment bug.html")

(defparameter *fedwiki-dmx-importer-bug-observed-topic-id* 971853)
(defparameter *fedwiki-dmx-importer-bug-related-topic-id* 961552)
(defparameter *fedwiki-dmx-importer-bug-default-workspace-id* 919815)
(defparameter *fedwiki-dmx-importer-bug-default-topicmap-id* 919822)

(defparameter *fedwiki-dmx-importer-bug-current-coordinate* :p0)

(defparameter *fedwiki-dmx-importer-bug-steps*
  '((:id :p0
     :title "Bootstrap shared bug surface"
     :status :active
     :purpose "Create this page before changing importer code."
     :artifact "hyperdoc/FedWiki-to-DMX importer workspace assignment bug.html")
    (:id :p1
     :title "Confirm failure path"
     :status :pending
     :purpose "Show that raw topic creation can produce Workspace n/a."
     :artifact "topic 971853")
    (:id :p2
     :title "Define invariant"
     :status :pending
     :purpose "Importer-visible topic creation must assign workspace and place the topic in the context-window topicmap."
     :artifact "importer write contract")
    (:id :p3
     :title "Refactor raw topic creation"
     :status :pending
     :purpose "Guard or rename dmx-import-create-topic so ordinary importer code cannot create orphan topics."
     :artifact "hyperdoc/dmx-import.lisp")
    (:id :p4
     :title "Add workspace-aware create primitive"
     :status :pending
     :purpose "Create topic, assign workspace, add topicmap placement, then return success."
     :artifact "dmx-import-create-workspace-topic")
    (:id :p5
     :title "Refactor FedWiki importer execution"
     :status :pending
     :purpose "Make execute-dmx-import-plan use the workspace-aware primitive for all :create actions."
     :artifact "execute-dmx-import-plan")
    (:id :p6
     :title "Regression test"
     :status :pending
     :purpose "Prove that importer creation cannot return an unassigned topic."
     :artifact "tests/fedwiki-site-dmx-import.lisp")))

(defun fedwiki-dmx-importer-bug-root-path (relative)
  (asdf:system-relative-pathname :hyperdoc relative))

(defun fedwiki-dmx-importer-bug-page-path ()
  (fedwiki-dmx-importer-bug-root-path
   *fedwiki-dmx-importer-bug-page-relative-path*))

(defun fedwiki-dmx-importer-bug-current-coordinate ()
  (find *fedwiki-dmx-importer-bug-current-coordinate*
        *fedwiki-dmx-importer-bug-steps*
        :key (lambda (step) (getf step :id))))

(defun fedwiki-dmx-importer-bug-page-object (&key (signal-error? nil))
  "Return the HyperDoc HTML page object for the importer bug surface."
  (when (and (boundp '*hyperdoc*) *hyperdoc*)
    (find-page *hyperdoc*
               *fedwiki-dmx-importer-bug-page-title*
               :signal-error? signal-error?)))

(defun fedwiki-dmx-importer-bug-resolve-artifact (artifact)
  (cond
    ((null artifact)
     nil)
    ((and (stringp artifact)
          (string= artifact *fedwiki-dmx-importer-bug-page-relative-path*))
     (or (fedwiki-dmx-importer-bug-page-object :signal-error? nil)
         (fedwiki-dmx-importer-bug-page-path)))
    ((and (stringp artifact)
          (string= artifact "topic 971853"))
     (list :dmx-topic-id *fedwiki-dmx-importer-bug-observed-topic-id*
           :role :observed-unassigned-topic))
    ((stringp artifact)
     (let ((path (fedwiki-dmx-importer-bug-root-path artifact)))
       (or (probe-file path) artifact)))
    (t
     artifact)))

(defun fedwiki-dmx-importer-bug-status ()
  "Return the current inspectable status for the importer bug-fix surface."
  (let* ((coordinate (fedwiki-dmx-importer-bug-current-coordinate))
         (artifact-label (getf coordinate :artifact)))
    (list :coordinate *fedwiki-dmx-importer-bug-current-coordinate*
          :title (getf coordinate :title)
          :status (getf coordinate :status)
          :purpose (getf coordinate :purpose)
          :artifact (fedwiki-dmx-importer-bug-resolve-artifact artifact-label)
          :artifact-label artifact-label
          :page-path (fedwiki-dmx-importer-bug-page-path)
          :observed-topic-id *fedwiki-dmx-importer-bug-observed-topic-id*
          :related-topic-id *fedwiki-dmx-importer-bug-related-topic-id*
          :default-workspace-id *fedwiki-dmx-importer-bug-default-workspace-id*
          :default-topicmap-id *fedwiki-dmx-importer-bug-default-topicmap-id*
          :next-action
          (case *fedwiki-dmx-importer-bug-current-coordinate*
            (:p0 "Inspect the shared bug surface page object.")
            (:p1 "Confirm the raw create path that produced Workspace n/a.")
            (:p2 "State the importer invariant as a write-boundary contract.")
            (:p3 "Refactor raw topic creation into a non-importer-visible primitive.")
            (:p4 "Add the workspace-aware create primitive.")
            (:p5 "Route FedWiki import :create actions through the guarded primitive.")
            (:p6 "Add a regression test for importer-created workspace assignment.")
            (otherwise "Inspect the bug-fix plan.")))))

(defun fedwiki-dmx-importer-bug-plan ()
  "Return the inspectable plan for the FedWiki-to-DMX importer bug fix."
  (list :title *fedwiki-dmx-importer-bug-page-title*
        :current-coordinate *fedwiki-dmx-importer-bug-current-coordinate*
        :observed-topic-id *fedwiki-dmx-importer-bug-observed-topic-id*
        :related-topic-id *fedwiki-dmx-importer-bug-related-topic-id*
        :default-workspace-id *fedwiki-dmx-importer-bug-default-workspace-id*
        :default-topicmap-id *fedwiki-dmx-importer-bug-default-topicmap-id*
        :default-mode :non-mutating
        :mutation-allowed nil
        :working-rule
        "Importer-level topic creation must create, assign workspace, place in topicmap, and only then report success."
        :steps *fedwiki-dmx-importer-bug-steps*))
