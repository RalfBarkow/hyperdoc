;;;; What Graphviz Does task-debt topics
;;;; Filed out to make parked evidence debt inspectable and callable.

(DEFPACKAGE #:HYPERDOC/WGD-TASK-DEBT
  (:USE #:CL)
  (:EXPORT #:*WGD-TASK-DEBT-TOPICS*
           #:*WGD-TASK-DEBT-ASSOCIATIONS*
           #:WGD-TASK-DEBT-TOPICS
           #:WGD-FIND-TASK-DEBT-TOPIC
           #:WGD-TASK-DEBT-TOPIC-MAP
           #:WGD-TASK-DEBT-NEXT-ACTIONS))

(IN-PACKAGE #:HYPERDOC/WGD-TASK-DEBT)

(DEFPARAMETER *WGD-TASK-DEBT-TOPICS*
  '((:TOPIC-ID "task-debt:wgd-evidence-descriptor-policy" :TITLE
     "WGD evidence descriptor policy review" :KIND :DEFERRED-TASK-TOPIC :STATUS
     :PARKED :COMMIT "c80ceb13" :COMMIT-MESSAGE
     "docs(fedwiki): park WGD evidence needing descriptor policy"
     :GOVERNING-PLAN
     "hyperdoc/what-graphviz-does-local-fork-materialization-plan.sexp"
     :SOURCE-TASK
     "(!DECIDE-EVIDENCE-DESCRIPTOR-POLICY-THEN-COMMIT-OR-REPAIR REPO HYPERDOC FILES WGD-EVIDENCE-NEEDING-DESCRIPTOR-POLICY)"
     :NEXT-TASK
     "(!DECIDE-EVIDENCE-DESCRIPTOR-POLICY REPO HYPERDOC TOPIC task-debt:wgd-evidence-descriptor-policy)"
     :PRIMARY-CALLABLE-FORM
     "(hyperdoc/wgd-task-debt:wgd-find-task-debt-topic \"task-debt:wgd-evidence-descriptor-policy\")"
     :INSPECTION-FORM
     "(hd-inspect (hyperdoc/wgd-task-debt:wgd-find-task-debt-topic \"task-debt:wgd-evidence-descriptor-policy\"))"
     :FILES
     ("hyperdoc/what-graphviz-does-remote-page-fetch.evidence.sexp"
      "hyperdoc/what-graphviz-does-fetch-retention-repair.evidence.sexp"
      "hyperdoc/what-graphviz-does-page-attached-asdf-home.evidence.sexp"
      "hyperdoc/what-graphviz-does-page-attached-asdf-home.clean.evidence.sexp")
     :MEANING
     "Evidence was preserved, but the descriptor policy for live-object renderings remains a first-class review topic.")
    (:TOPIC-ID "task-debt:asdf-writer-load-boundary-diagnostics" :TITLE
     "ASDF writer load-boundary diagnostic chain" :KIND :DEFERRED-TASK-TOPIC
     :STATUS :PARKED :COMMIT "6719a4b4" :COMMIT-MESSAGE
     "docs(fedwiki): record ASDF writer load-boundary diagnostics"
     :GOVERNING-BLOCKER "HYPERDOC-FEDWIKI-ASDF-ASSETS-LOAD-BOUNDARY"
     :ORIGINATING-GATE
     "(!LOAD-PAGE-ASDF-ASSET-WRITER-SYSTEM SYSTEM HYPERDOC/FEDWIKI-ASDF-ASSETS)"
     :COMPACT-BLOCKER "ASDF reports system hyperdoc is out of date." :NEXT-TASK
     "(!REVIEW-ASDF-WRITER-LOAD-BOUNDARY-DIAGNOSTIC-CHAIN REPO HYPERDOC TOPIC task-debt:asdf-writer-load-boundary-diagnostics)"
     :PRIMARY-CALLABLE-FORM
     "(hyperdoc/wgd-task-debt:wgd-find-task-debt-topic \"task-debt:asdf-writer-load-boundary-diagnostics\")"
     :INSPECTION-FORM
     "(hd-inspect (hyperdoc/wgd-task-debt:wgd-find-task-debt-topic \"task-debt:asdf-writer-load-boundary-diagnostics\"))"
     :FILES
     ("hyperdoc/what-graphviz-does-load-page-asdf-asset-writer-system.evidence.sexp"
      "hyperdoc/what-graphviz-does-repair-page-asdf-asset-writer-load-boundary.evidence.sexp"
      "hyperdoc/what-graphviz-does-page-attached-asdf-home.strict.evidence.sexp"
      "hyperdoc/zettel-9121-diagnose-page-asdf-asset-writer-load-boundary-failure.evidence.sexp"
      "hyperdoc/zettel-9122-clean-smoke-tail-inspection.evidence.sexp"
      "hyperdoc/zettel-9123-clean-smoke-tail-capture.evidence.sexp")
     :MEANING
     "Diagnostics were preserved as a separate load-boundary topic, not mixed into the WGD fork-materialization evidence path.")))

(DEFPARAMETER *WGD-TASK-DEBT-ASSOCIATIONS*
  '((:ASSOCIATION-ID
     "assoc:task-debt:wgd-descriptor-policy:governed-by:wgd-plan" :TYPE
     :GOVERNED-BY :FROM "task-debt:wgd-evidence-descriptor-policy" :TO
     "plan:what-graphviz-does-local-fork-materialization")
    (:ASSOCIATION-ID "assoc:task-debt:asdf-boundary:originates-in:asdf-gate"
     :TYPE :ORIGINATES-IN-GATE :FROM
     "task-debt:asdf-writer-load-boundary-diagnostics" :TO
     "gate:load-page-asdf-asset-writer-system")
    (:ASSOCIATION-ID
     "assoc:task-debt:wgd-descriptor-policy:separated-from:asdf-boundary" :TYPE
     :SEPARATED-FROM :FROM "task-debt:wgd-evidence-descriptor-policy" :TO
     "task-debt:asdf-writer-load-boundary-diagnostics")
    (:ASSOCIATION-ID "assoc:task-debt:both:return-to-primary-work" :TYPE
     :CLEARS-WORKING-TREE-FOR :FROM "topic-map:wgd-task-debt" :TO
     "task:return-to-primary-hyperdoc-work")))

(DEFUN WGD-TASK-DEBT-TOPICS () *WGD-TASK-DEBT-TOPICS*)

(DEFUN WGD-FIND-TASK-DEBT-TOPIC (TOPIC-ID)
  (FIND TOPIC-ID *WGD-TASK-DEBT-TOPICS* :KEY
        (LAMBDA (TOPIC) (GETF TOPIC :TOPIC-ID)) :TEST #'STRING=))

(DEFUN WGD-TASK-DEBT-TOPIC-MAP ()
  (LIST :TOPIC-MAP-ID "topic-map:wgd-task-debt" :TITLE
        "What Graphviz Does task debt" :TOPICS *WGD-TASK-DEBT-TOPICS*
        :ASSOCIATIONS *WGD-TASK-DEBT-ASSOCIATIONS*))

(DEFUN WGD-TASK-DEBT-NEXT-ACTIONS ()
  (LOOP FOR TOPIC IN *WGD-TASK-DEBT-TOPICS*
        COLLECT (LIST :TOPIC-ID (GETF TOPIC :TOPIC-ID) :TITLE
                      (GETF TOPIC :TITLE) :STATUS (GETF TOPIC :STATUS)
                      :NEXT-TASK (GETF TOPIC :NEXT-TASK) :INSPECTION-FORM
                      (GETF TOPIC :INSPECTION-FORM))))

