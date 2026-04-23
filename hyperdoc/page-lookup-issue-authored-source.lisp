;;;; Repo-native authored source for the page-lookup issue relation artifact
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun page-lookup-issue-authored-source-role
    (&key id title summary kind binding participants findings)
  (list :id id
        :title title
        :summary summary
        :kind kind
        :binding binding
        :participants participants
        :findings findings))

(defun page-lookup-issue-authored-source-relation
    (&key id title summary layer subject predicate object attributes)
  (list :id id
        :title title
        :summary summary
        :layer layer
        :subject subject
        :predicate predicate
        :object object
        :attributes attributes))

(defun page-lookup-issue-authored-source-role-definitions ()
  (list
   (page-lookup-issue-authored-source-role
    :id "role/page-lookup-issue"
    :title "Page lookup issue"
    :summary "Inspectable bounded failure object produced for a missing page reference."
    :kind :inspectable-failure
    :binding :page-lookup-issue)
   (page-lookup-issue-authored-source-role
    :id "role/target-chunk"
    :title "Target chunk"
    :summary "Diagnostic chunk that carries the current page/topic lookup truth."
    :kind :diagnostic-chunk
    :binding :target-chunk)
   (page-lookup-issue-authored-source-role
    :id "role/overview-pane"
    :title "Overview pane"
    :summary "Existing compact overview surface for the lookup issue."
    :kind :pane
    :binding :overview-pane)
   (page-lookup-issue-authored-source-role
    :id "role/repair-pane"
    :title "Repair pane"
    :summary "Existing bounded repair surface for the lookup issue."
    :kind :pane
    :binding :repair-pane)))

(defun page-lookup-issue-authored-source-relation-definitions ()
  (list
   (page-lookup-issue-authored-source-relation
    :id "semantic/issue-targets-page"
    :title "Issue targets missing page"
    :summary "The issue records the missing page reference as evidence."
    :layer :semantic
    :subject :page-lookup-issue
    :predicate :targets
    :object :missing-page)
   (page-lookup-issue-authored-source-relation
    :id "semantic/issue-derives-target-chunk"
    :title "Issue derives target chunk"
    :summary "HyperDoc derives a target chunk instead of treating repair prose as authority."
    :layer :semantic
    :subject :page-lookup-issue
    :predicate :derives
    :object :target-chunk)
   (page-lookup-issue-authored-source-relation
    :id "semantic/chunk-provides-status"
    :title "Target chunk provides status"
    :summary "The target chunk provides current lookup status."
    :layer :semantic
    :subject :target-chunk
    :predicate :provides
    :object :lookup-status)
   (page-lookup-issue-authored-source-relation
    :id "semantic/chunk-provides-repair"
    :title "Target chunk provides repair guidance"
    :summary "The target chunk provides bounded repair guidance."
    :layer :semantic
    :subject :target-chunk
    :predicate :provides
    :object :repair-guidance)
   (page-lookup-issue-authored-source-relation
    :id "projection/behavior"
    :title "Compiled behavior projection"
    :summary "Page-lookup issue relations compile into a small lifecycle machine."
    :layer :projection
    :subject :page-lookup-issue
    :predicate :projects-to
    :object :page-lookup-issue-lifecycle)
   (page-lookup-issue-authored-source-relation
    :id "projection/layout"
    :title "Compiled layout projection"
    :summary "Page-lookup issue relations compile into the existing issue pane layout."
    :layer :projection
    :subject :page-lookup-issue
    :predicate :projects-to
    :object :page-lookup-issue-pane-layout)
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/state/open"
    :title "State open"
    :summary "The lookup issue exists and awaits current target diagnosis."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :has-state
    :object :open
    :attributes '(:title "open"
                  :role :initial
                  :summary "The issue has been created from a missing page reference."))
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/state/needs-target-chunk"
    :title "State needs_target_chunk"
    :summary "The issue is interpreted through its target chunk."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :has-state
    :object :needs-target-chunk
    :attributes '(:title "needs_target_chunk"
                  :summary "The target chunk supplies status and repair guidance."))
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/state/fixed"
    :title "State fixed"
    :summary "The referenced page now resolves."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :has-state
    :object :fixed
    :attributes '(:title "fixed"
                  :role :terminal
                  :summary "The missing page reference resolves."))
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/initial"
    :title "Initial lifecycle state"
    :summary "Page-lookup issues start open."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :initial-state
    :object :open)
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/terminal/fixed"
    :title "Terminal fixed state"
    :summary "Fixed is the successful terminal state."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :terminal-state
    :object :fixed)
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/event/issue-created"
    :title "Event issue_created"
    :summary "The bounded lookup issue object has been created."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :has-event
    :object :issue-created)
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/event/target-chunk-derived"
    :title "Event target_chunk_derived"
    :summary "The target diagnostic chunk is available."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :has-event
    :object :target-chunk-derived)
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/event/target-resolved"
    :title "Event target_resolved"
    :summary "The missing page target now resolves."
    :layer :behavior
    :subject :page-lookup-issue-lifecycle
    :predicate :has-event
    :object :target-resolved)
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/transition/open-needs-target"
    :title "Open -> needs_target_chunk"
    :summary "Deriving the target chunk moves the issue into diagnosis."
    :layer :behavior
    :subject :open
    :predicate :transition-to
    :object :needs-target-chunk
    :attributes '(:id "page-lookup/open->needs-target-chunk"
                  :machine :page-lookup-issue-lifecycle
                  :trigger :target-chunk-derived))
   (page-lookup-issue-authored-source-relation
    :id "behavior/page-lookup/transition/needs-target-fixed"
    :title "Needs target chunk -> fixed"
    :summary "A resolving target page closes the issue."
    :layer :behavior
    :subject :needs-target-chunk
    :predicate :transition-to
    :object :fixed
    :attributes '(:id "page-lookup/needs-target-chunk->fixed"
                  :machine :page-lookup-issue-lifecycle
                  :trigger :target-resolved))
   (page-lookup-issue-authored-source-relation
    :id "layout/page-lookup/contains-overview"
    :title "Issue pane contains overview"
    :summary "The existing page-lookup issue pane exposes a compact Overview tab."
    :layer :layout
    :subject :lookup-issue-pane
    :predicate :contains
    :object :overview-pane)
   (page-lookup-issue-authored-source-relation
    :id "layout/page-lookup/contains-repair"
    :title "Issue pane contains repair"
    :summary "The existing page-lookup issue pane exposes a bounded Repair tab."
    :layer :layout
    :subject :lookup-issue-pane
    :predicate :contains
    :object :repair-pane)
   (page-lookup-issue-authored-source-relation
    :id "layout/page-lookup/repair-after-overview"
    :title "Repair follows overview"
    :summary "Repair remains a secondary pane after Overview."
    :layer :layout
    :subject :repair-pane
    :predicate :after
    :object :overview-pane)
   (page-lookup-issue-authored-source-relation
    :id "layout/page-lookup/chunk-opens-from-repair"
    :title "Target chunk opens from repair"
    :summary "The target chunk is a bounded inspectable object opened from repair context."
    :layer :layout
    :subject :target-chunk-pane
    :predicate :opens-from
    :object :repair-pane)))

(defun make-page-lookup-issue-authored-source-artifact ()
  (make-authored-relation-artifact-source
   :id "source/page-lookup-issue-authored-artifact"
   :title "Page lookup issue authored source artifact"
   :summary
   "Repo-native authored source for the page-lookup issue relation artifact."
   :source-kind :repo-native-lisp
   :source-path "hyperdoc/page-lookup-issue-authored-source.lisp"
   :schema-version 1
   :artifact-id "page-lookup-issue-authored-artifact"
   :artifact-title "Page lookup issue authored relation artifact"
   :artifact-summary
   "Authored relation artifact that compiles into page-lookup issue behavior and layout artifacts."
   :workflow-role
   "Graph-authored reconstruction surface for the bounded page-lookup issue failure path."
   :compiler-pipeline
   "repo-native authored source -> authored relation artifact -> compiled behavior artifact + compiled layout artifact -> page-lookup issue inspector"
   :semantic-role-definitions
   (page-lookup-issue-authored-source-role-definitions)
   :relation-definitions
   (page-lookup-issue-authored-source-relation-definitions)
   :compiled-targets
   '("page-lookup-issue-behavior-artifact"
     "page-lookup-issue-layout-artifact")
   :findings
   '("Page lookup issue uses authored source as a reconstruction point."
     "Behavior remains a simple open/chunk-derived/fixed lifecycle."
     "Layout records existing Overview/Repair pane placement without changing UI.")))

(defparameter *page-lookup-issue-authored-source-artifact*
  (make-page-lookup-issue-authored-source-artifact))

(defun page-lookup-issue-authored-source-artifact ()
  *page-lookup-issue-authored-source-artifact*)
