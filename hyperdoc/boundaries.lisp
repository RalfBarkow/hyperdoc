;;;; Generic boundary runtime objects for HyperDoc
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass boundary-definition ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (boundary-kind :reader boundary-definition-boundary-kind-of
                  :initarg :boundary-kind)
   (left-side :reader boundary-definition-left-side-of
              :initarg :left-side
              :initform nil)
   (right-side :reader boundary-definition-right-side-of
               :initarg :right-side
               :initform nil)
   (crossing-condition :reader boundary-definition-crossing-condition-of
                       :initarg :crossing-condition
                       :initform nil)
   (permitted-operations :reader boundary-definition-permitted-operations-of
                         :initarg :permitted-operations
                         :initform nil)
   (blocked-operations :reader boundary-definition-blocked-operations-of
                       :initarg :blocked-operations
                       :initform nil)
   (evidence-kinds :reader boundary-definition-evidence-kinds-of
                   :initarg :evidence-kinds
                   :initform nil)
   (failure-classifications :reader boundary-definition-failure-classifications-of
                            :initarg :failure-classifications
                            :initform nil)
   (adjacent-surfaces :reader boundary-definition-adjacent-surfaces-of
                      :initarg :adjacent-surfaces
                      :initform nil)
   (related-boundaries :reader boundary-definition-related-boundaries-of
                       :initarg :related-boundaries
                       :initform nil)
   (source-evidence :reader boundary-definition-source-evidence-of
                    :initarg :source-evidence
                    :initform nil)
   (notes :reader boundary-definition-notes-of
          :initarg :notes
          :initform nil)))

(defclass boundary-instance ()
  ((definition :reader boundary-instance-definition-of
     :initarg :definition)
   (subject :reader boundary-instance-subject-of
            :initarg :subject
            :initform nil)
   (title :reader title-of
          :initarg :title
          :initform nil)
   (status :reader boundary-instance-status-of
           :initarg :status
           :initform :observed)
   (last-reached-stage :reader boundary-instance-last-reached-stage-of
                       :initarg :last-reached-stage
                       :initform nil)
   (crossing-attempted-p :reader boundary-instance-crossing-attempted-p-of
                         :initarg :crossing-attempted-p
                         :initform nil)
   (crossing-succeeded-p :reader boundary-instance-crossing-succeeded-p-of
                         :initarg :crossing-succeeded-p
                         :initform nil)
   (failure-classification :reader boundary-instance-failure-classification-of
                           :initarg :failure-classification
                           :initform nil)
   (evidence :reader boundary-instance-evidence-of
             :initarg :evidence
             :initform nil)
   (auth-context :reader boundary-instance-auth-context-of
                 :initarg :auth-context
                 :initform nil)
   (adjacent-stages :reader boundary-instance-adjacent-stages-of
                    :initarg :adjacent-stages
                    :initform nil)
   (related-surfaces :reader boundary-instance-related-surfaces-of
                     :initarg :related-surfaces
                     :initform nil)
   (source-evidence :reader boundary-instance-source-evidence-of
                    :initarg :source-evidence
                    :initform nil)
   (notes :reader boundary-instance-notes-of
          :initarg :notes
          :initform nil)))

(defun make-boundary-definition
    (&key id title summary boundary-kind left-side right-side
       crossing-condition permitted-operations blocked-operations
       evidence-kinds failure-classifications adjacent-surfaces
       related-boundaries source-evidence notes)
  (make-instance 'boundary-definition
                 :id id
                 :title title
                 :summary summary
                 :boundary-kind boundary-kind
                 :left-side left-side
                 :right-side right-side
                 :crossing-condition crossing-condition
                 :permitted-operations permitted-operations
                 :blocked-operations blocked-operations
                 :evidence-kinds evidence-kinds
                 :failure-classifications failure-classifications
                 :adjacent-surfaces adjacent-surfaces
                 :related-boundaries related-boundaries
                 :source-evidence source-evidence
                 :notes notes))

(defun make-boundary-instance
    (&key definition subject title status last-reached-stage
       crossing-attempted-p crossing-succeeded-p failure-classification
       evidence auth-context adjacent-stages related-surfaces
       source-evidence notes)
  (make-instance 'boundary-instance
                 :definition definition
                 :subject subject
                 :title title
                 :status status
                 :last-reached-stage last-reached-stage
                 :crossing-attempted-p crossing-attempted-p
                 :crossing-succeeded-p crossing-succeeded-p
                 :failure-classification failure-classification
                 :evidence evidence
                 :auth-context auth-context
                 :adjacent-stages adjacent-stages
                 :related-surfaces related-surfaces
                 :source-evidence source-evidence
                 :notes notes))

(defmethod print-object ((object boundary-definition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object boundary-instance) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A"
            (or (title-of object)
                (title-of (boundary-instance-definition-of object))))))

(defun boundary-plist-p (item)
  (and (listp item)
       (loop for cursor on item by #'cddr
             always (and cursor
                         (or (keywordp (first cursor))
                             (symbolp (first cursor))
                             (stringp (first cursor)))))))

(defun boundary-item-value (item key)
  (cond
    ((null item) nil)
    ((hash-table-p item)
     (multiple-value-bind (value present-p)
         (gethash key item)
       (if present-p
           value
           (let ((string-key (string-downcase (string key))))
             (gethash string-key item)))))
    ((boundary-plist-p item)
     (or (getf item key)
         (let ((string-key (string-downcase (string key))))
           (getf item string-key))))
    ((and (listp item) (every #'consp item))
     (or (cdr (assoc key item :test #'equal))
         (let ((string-key (string-downcase (string key))))
           (cdr (assoc string-key item :test #'string=)))))
    (t nil)))

(defun boundary-known-kind-p (kind)
  (member kind
          '(:generic :contract :transition :authentication :read-write :report)
          :test #'equal))

(defun boundary-definition-findings (definition)
  (let ((findings '()))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (if (boundary-known-kind-p
           (boundary-definition-boundary-kind-of definition))
          (note-finding "Boundary kind"
                        :ok
                        (format nil "Boundary kind ~A is recognized."
                                (boundary-definition-boundary-kind-of definition)))
          (note-finding "Boundary kind"
                        :error
                        (format nil "Boundary kind ~A is not recognized."
                                (boundary-definition-boundary-kind-of definition))))
      (if (boundary-definition-left-side-of definition)
          (note-finding "Left side"
                        :ok
                        "Left-side contract or stage is declared.")
          (note-finding "Left side"
                        :error
                        "Boundary definition is missing its left side."))
      (if (boundary-definition-right-side-of definition)
          (note-finding "Right side"
                        :ok
                        "Right-side contract or stage is declared.")
          (note-finding "Right side"
                        :error
                        "Boundary definition is missing its right side."))
      (if (boundary-definition-crossing-condition-of definition)
          (note-finding "Crossing condition"
                        :ok
                        "Crossing condition is declared.")
          (note-finding "Crossing condition"
                        :error
                        "Boundary definition is missing its crossing condition."))
      (if (boundary-definition-permitted-operations-of definition)
          (note-finding "Permitted operations"
                        :ok
                        "Permitted operations are declared.")
          (note-finding "Permitted operations"
                        :warning
                        "No permitted operations are declared."))
      (if (boundary-definition-blocked-operations-of definition)
          (note-finding "Blocked operations"
                        :ok
                        "Blocked operations are declared.")
          (note-finding "Blocked operations"
                        :warning
                        "No blocked operations are declared."))
      (nreverse findings))))

(defun boundary-instance-findings (instance)
  (let* ((definition (boundary-instance-definition-of instance))
         (findings '()))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (if (typep definition 'boundary-definition)
          (note-finding "Definition binding"
                        :ok
                        "Boundary instance points to a boundary-definition.")
          (note-finding "Definition binding"
                        :error
                        "Boundary instance does not point to a boundary-definition."))
      (if (boundary-instance-last-reached-stage-of instance)
          (note-finding "Last reached stage"
                        :ok
                        "Last reached stage is recorded.")
          (note-finding "Last reached stage"
                        :warning
                        "No last reached stage is recorded."))
      (when (and (boundary-instance-crossing-succeeded-p-of instance)
                 (not (boundary-instance-crossing-attempted-p-of instance)))
        (note-finding "Crossing status"
                      :error
                      "Crossing cannot succeed if it was never attempted."))
      (when (and (eq (boundary-instance-status-of instance) :blocked)
                 (null (boundary-instance-failure-classification-of instance)))
        (note-finding "Failure classification"
                      :error
                      "Blocked boundary instance must declare a failure classification."))
      (unless findings
        (note-finding "Boundary instance"
                      :ok
                      "Boundary instance is internally consistent."))
      (nreverse findings))))

(defun example-boundary-source-evidence ()
  (list
   (list :layer "HyperDoc page"
         :reference "Operational definition: boundary, contract boundary, transition boundary, boundary report"
         :detail "Durable definition of the boundary-definition / boundary-instance split.")
   (list :layer "HyperDoc topic"
         :reference "Boundary"
         :detail "Stable semantic anchor for the generic boundary abstraction.")
   (list :layer "Lisp source"
         :reference "hyperdoc/boundaries.lisp"
         :detail "Runtime definition and instance objects for generic boundaries.")
   (list :layer "Test"
         :reference "tests/boundary-smoke.lisp"
         :detail "Smoke coverage for the generic boundary objects and worked examples.")))

(defun make-example-boundary-definition ()
  (make-boundary-definition
   :id "boundary-definition/example"
   :title "Example contract boundary"
   :summary
   "Small generic boundary definition that keeps two sides, crossing condition, and evidence distinct from any one DMX-specific use case."
   :boundary-kind :contract
   :left-side "Raw authored input"
   :right-side "Validated structured value"
   :crossing-condition
   "Input parses into the expected shape and passes the declared preflight checks."
   :permitted-operations
   (list
    (list :phase "before"
          :operation "Inspect raw input"
          :detail "Read the input bundle without claiming the structured form yet.")
    (list :phase "after"
          :operation "Produce structured value"
          :detail "Use the validated representation for downstream execution."))
   :blocked-operations
   (list
    (list :phase "before"
          :operation "Claim downstream structure"
          :detail "Do not treat raw input as if it already crossed the contract boundary.")
    (list :phase "after"
          :operation "Recover raw provenance implicitly"
          :detail "Crossing evidence should preserve the raw input reference explicitly."))
   :evidence-kinds
   '("preflight report" "validated value" "crossing trace")
   :failure-classifications
   (list
    (list :label "shape-mismatch"
          :detail "The input could not be normalized into the expected shape.")
    (list :label "missing-support"
          :detail "A required prerequisite was absent at the crossing attempt."))
   :adjacent-surfaces
   (list
    (list :surface "Diagnostic surface"
          :detail "Read-only surface that inspects the pre-crossing state.")
    (list :surface "Boundary report"
          :detail "Reporting object that summarizes unresolved crossings."))
   :related-boundaries
   (list
    (list :boundary "Transition boundary"
          :detail "A later stage crossing may depend on this contract being satisfied.")
    (list :boundary "Read-write boundary"
          :detail "A specialized contract boundary can distinguish stable read and write targets."))
   :source-evidence (example-boundary-source-evidence)
   :notes
   (list
    (list :label "Generic example"
          :detail "This definition is intentionally small so the generic views are inspectable immediately."))))

(defun make-example-boundary-instance ()
  (let ((definition (make-example-boundary-definition)))
    (make-boundary-instance
     :definition definition
     :subject (list (cons "input-id" "example-42")
                    (cons "representation" "validated-record"))
     :title "Example successful boundary crossing"
     :status :crossed
     :last-reached-stage "validated structured value"
     :crossing-attempted-p t
     :crossing-succeeded-p t
     :failure-classification nil
     :evidence
     (list
      (list :kind "preflight report"
            :detail "Input satisfied the declared shape check.")
      (list :kind "validated value"
            :detail "Structured record emitted for downstream use."))
     :auth-context
     (list
      (list :key "mode" :value "none")
      (list :key "detail"
            :value "Generic example boundary does not require authentication."))
     :adjacent-stages
     (list
      (list :stage "raw input"
            :detail "Pre-crossing authored state.")
      (list :stage "validated structured value"
            :detail "Post-crossing executable state."))
     :related-surfaces
     (list
      (list :surface "Diagnostic surface"
            :detail "Read-only explanation of the pre-crossing state.")
      (list :surface "Boundary report"
            :detail "Would summarize this boundary if the crossing had failed."))
     :source-evidence (example-boundary-source-evidence)
     :notes
     (list
      (list :label "Example run"
            :detail "Concrete successful crossing for the generic example boundary.")))))

(defun dmx-boundary-source-evidence ()
  (list
   (list :layer "HyperDoc page"
         :reference "DMX note read/write boundary"
         :detail "Stable parent-note contract boundary for note mutation.")
   (list :layer "HyperDoc page"
         :reference "DMX workspace journal model"
         :detail "Guarded journal preflight and companion-note semantics.")
   (list :layer "HyperDoc page"
         :reference "Using authenticated workspace assignment repair console"
         :detail "Explicit-auth mutation boundary for repair.")
   (list :layer "HyperDoc page"
         :reference "Diagnosing DMX workspace repair triage"
         :detail "Read-only diagnostic surface adjacent to the repair path.")
   (list :layer "Lisp source"
         :reference "hyperdoc/dmx-import.lisp"
         :detail "Explicit auth normalization and guarded DMX client construction.")
   (list :layer "Lisp source"
         :reference "hyperdoc/dmx-annotations.lisp"
         :detail "Workspace-journal preflight and continuation stage reporting.")
   (list :layer "Lisp source"
         :reference "hyperdoc/dmx-workspace-journal.lisp"
         :detail "Companion journal handling and journal-transition semantics.")
   (list :layer "Test"
         :reference "tests/dmx-shared-workspace-docs-smoke.lisp"
         :detail "Existing DMX documentation cluster coverage.")
   (list :layer "Test"
         :reference "tests/dmx-topic-proxy-smoke.lisp"
         :detail "Existing repair-console and workspace-diagnostics behavior coverage.")))

(defun make-dmx-note-read-write-boundary-definition ()
  (make-boundary-definition
   :id "boundary-definition/dmx-note-read-write"
   :title "DMX note read/write boundary definition"
   :summary
   "Contract boundary stating that note reads use the full parent-note projection while stable writes target the parent dmx.notes.note payload."
   :boundary-kind :read-write
   :left-side "Machine-readable parent-note projection with child text readout"
   :right-side "Stable parent-note write contract on dmx.notes.note"
   :crossing-condition
   "A write crosses this boundary only when HyperDoc updates the parent note payload and then rereads the parent note for verification."
   :permitted-operations
   (list
    (list :phase "before"
          :operation "Read /core/topic/<id>?children=true&assocChildren=true"
          :detail "Use the full parent-note projection for diagnosis and preflight.")
    (list :phase "after"
          :operation "Update dmx.notes.note"
          :detail "Write the note body through the parent note payload, then reread the parent note."))
   :blocked-operations
   (list
    (list :phase "before"
          :operation "Assume child-topic write stability"
          :detail "The visible dmx.notes.text child is not the stable mutation target.")
    (list :phase "after"
          :operation "Treat stale rereads as authoritative"
          :detail "Verification must use the parent note reread with cache-busting or equivalent freshness."))
   :evidence-kinds
   '("parent note projection" "note-update event" "post-write parent reread")
   :failure-classifications
   (list
    (list :label "wrong-target"
          :detail "A write attempted to treat the child text topic as the stable mutation target.")
    (list :label "stale-reread"
          :detail "Verification reread did not prove the live parent-note result.")
    (list :label "unresolved-note-key"
          :detail "The read surface could not resolve noteKey to an existing note."))
   :adjacent-surfaces
   (list
    (list :surface "DMX machine-readable read paths"
          :detail "Canonical JSON read routes adjacent to the write contract.")
    (list :surface "DMX workspace journal model"
          :detail "Journaled note-create/note-update semantics remain attached to the same parent-note boundary."))
   :related-boundaries
   (list
    (list :boundary "Contract boundary"
          :detail "This is a specialized contract boundary.")
    (list :boundary "Boundary report"
          :detail "A report can summarize unresolved write-target or verification failures."))
   :source-evidence (dmx-boundary-source-evidence)
   :notes
   (list
    (list :label "Worked example"
          :detail "This definition uses the stable DMX note parent/child contract as the generic read-write example."))))

(defun make-dmx-workspace-journal-preflight-boundary-definition ()
  (make-boundary-definition
   :id "boundary-definition/dmx-workspace-journal-preflight"
   :title "DMX workspace-journal preflight boundary definition"
   :summary
   "Transition boundary separating prepared journal-companion state from later topic upsert and reopen stages in a guarded annotation or repair run."
   :boundary-kind :transition
   :left-side "Planned continuation or repair before journal companion preflight"
   :right-side "Journal companion prepared so later topic mutation stages may proceed"
   :crossing-condition
   "The boundary is crossed only when the journal companion update or assignment succeeds under the guarded preflight semantics."
   :permitted-operations
   (list
    (list :phase "before"
          :operation "Dry-run plan inspection"
          :detail "Inspect the planned stages and journal-event preview without mutating DMX.")
    (list :phase "crossing"
          :operation "Guarded journal preflight"
          :detail "Update or repair the journal companion before the main topic write."))
   :blocked-operations
   (list
    (list :phase "before"
          :operation "Skip journal preflight"
          :detail "Later topic-upsert and reopen stages must not overtake the companion preflight.")
    (list :phase "crossing"
          :operation "Anonymous mutation of a protected companion topic"
          :detail "Preflight cannot cross if the effective client lacks write permission for the existing companion topic."))
   :evidence-kinds
   '("failureStage" "journal-event-preview" "transport diagnostics" "repair readback")
   :failure-classifications
   (list
    (list :label "auth-blocked"
          :detail "The effective client reached the boundary without permission to mutate the companion topic.")
    (list :label "stale-companion-state"
          :detail "The companion topic remains in stale or unassigned state and cannot be repaired through the ordinary path.")
    (list :label "recursive-repair-defect"
          :detail "A maintenance path tried to journal the journal companion itself."))
   :adjacent-surfaces
   (list
    (list :surface "Using authenticated workspace assignment repair console"
          :detail "Mutation surface that can attempt explicit-auth repair before the next live continuation.")
    (list :surface "Diagnosing DMX workspace repair triage"
          :detail "Read-only diagnostic surface adjacent to the same defect class.")
    (list :surface "DMX workspace journal model"
          :detail "The broader guarded journal semantics surrounding this transition boundary."))
   :related-boundaries
   (list
    (list :boundary "Authentication boundary"
          :detail "Repair-console auth can be a prerequisite for crossing the preflight boundary.")
    (list :boundary "Read-write boundary"
          :detail "The companion note still relies on an existing DMX write contract."))
   :source-evidence (dmx-boundary-source-evidence)
   :notes
   (list
    (list :label "Stage vocabulary"
          :detail "This definition is aligned with the staged continuation reporting around prepare-transition, topic-upsert, and later stages."))))

(defun make-dmx-repair-console-authentication-boundary-definition ()
  (make-boundary-definition
   :id "boundary-definition/dmx-repair-console-authentication"
   :title "DMX repair-console authentication boundary definition"
   :summary
   "Authentication boundary separating read-only diagnostics from explicit-auth guarded mutation in the repair console."
   :boundary-kind :authentication
   :left-side "Read-only diagnostics and repair triage"
   :right-side "Explicit-auth guarded mutation through the repair console"
   :crossing-condition
   "The operator selects a supported credential mode, provides valid credentials, and the repair console constructs an authenticated DMX client for the current action."
   :permitted-operations
   (list
    (list :phase "before"
          :operation "Inspect workspace diagnostics"
          :detail "Diagnosis and triage remain read-only without login.")
    (list :phase "crossing"
          :operation "Provide explicit ephemeral credentials"
          :detail "Username/password, full Authorization header, or bearer token can be used for the current action.")
    (list :phase "after"
          :operation "Run guarded repair"
          :detail "Dry-run or live repair uses the existing guarded executor with the ephemeral authenticated client."))
   :blocked-operations
   (list
    (list :phase "before"
          :operation "Persist credentials in topic content or long-lived service config"
          :detail "The repair console does not widen into a credential store.")
    (list :phase "crossing"
          :operation "Assume anonymous repair is enough"
          :detail "Explicit-auth mutation is required when the object-level ACL blocks the ordinary anonymous service boundary."))
   :evidence-kinds
   '("selected auth mode" "bootstrap request shape" "JSESSIONID aftermath" "sanitized repair result readback")
   :failure-classifications
   (list
    (list :label "missing-auth"
          :detail "No supported credential input was provided for the current action.")
    (list :label "bootstrap-failed"
          :detail "Credential bootstrap or authorization header validation failed.")
    (list :label "object-acl-denied"
          :detail "The authenticated request still lacked permission for the target object."))
   :adjacent-surfaces
   (list
    (list :surface "Using authenticated workspace assignment repair console"
          :detail "Primary worked example of this authentication boundary.")
    (list :surface "Inspectable authentication-path traces for repair console"
          :detail "Inspectable auth-path evidence adjacent to the same crossing requirement.")
    (list :surface "Diagnosing DMX workspace repair triage"
          :detail "Read-only backlog surface on the left side of this auth boundary."))
   :related-boundaries
   (list
    (list :boundary "Transition boundary"
          :detail "Crossing auth can be a prerequisite for later preflight stages.")
    (list :boundary "Boundary report"
          :detail "Blocked auth attempts can be summarized as a boundary report without widening the mutation surface."))
   :source-evidence (dmx-boundary-source-evidence)
   :notes
   (list
    (list :label "No widening"
          :detail "The repair console keeps diagnosis read-only and mutation explicit-auth guarded."))))

(defun make-dmx-repair-console-authentication-boundary-instance ()
  (let ((definition (make-dmx-repair-console-authentication-boundary-definition)))
    (make-boundary-instance
     :definition definition
     :subject (list (cons "entrypoint" "(make-operational-definition-note-proxy)")
                    (cons "tab" "Repair console"))
     :title "Repair console explicit-auth boundary requirement"
     :status :pending
     :last-reached-stage "credentials pending"
     :crossing-attempted-p nil
     :crossing-succeeded-p nil
     :failure-classification nil
     :evidence
     (list
      (list :kind "supported credential modes"
            :detail "username/password, authorization header, bearer token")
      (list :kind "guarded executor"
            :detail "repair_workspace_topic_assignment remains the same guarded mutation path after auth."))
     :auth-context
     (list
      (list :key "mode" :value "explicit-ephemeral")
      (list :key "service-auth-assumption" :value "none")
      (list :key "credential-persistence" :value "forbidden"))
     :adjacent-stages
     (list
      (list :stage "workspace diagnostics"
            :detail "Read-only diagnosis before auth crossing.")
      (list :stage "guarded repair action"
            :detail "Mutation is attempted only after crossing the auth boundary."))
     :related-surfaces
     (list
      (list :surface "Using authenticated workspace assignment repair console"
            :detail "Mutation surface instance set on the right side of this boundary.")
      (list :surface "Diagnosing DMX workspace repair triage"
            :detail "Read-only diagnostic surface on the left side of this boundary."))
     :source-evidence (dmx-boundary-source-evidence)
     :notes
     (list
      (list :label "Requirement"
            :detail "This instance models the explicit-auth crossing requirement without claiming a live successful bootstrap.")))))

(defun make-dmx-workspace-journal-preflight-blocked-boundary-instance ()
  (let ((definition (make-dmx-workspace-journal-preflight-boundary-definition)))
    (make-boundary-instance
     :definition definition
     :subject
     (list (cons "carrier-topic-id" 927558)
           (cons "journal-companion-topic-id" 927568)
           (cons "workspace-id" *dmx-context-window-workspace-id*)
           (cons "topicmap-id" *dmx-context-window-topicmap-id*))
     :title "Observed auth-blocked DMX workspace-journal preflight boundary"
     :status :blocked
     :last-reached-stage "prepare-transition"
     :crossing-attempted-p t
     :crossing-succeeded-p nil
     :failure-classification "auth-blocked"
     :evidence
     (list
      (list :kind "failureStage"
            :detail "prepare-transition")
      (list :kind "failing mutation"
            :detail "PUT /core/topic/927568")
      (list :kind "response"
            :detail "HTTP 401: user <anonymous> has no WRITE permission for object 927568")
      (list :kind "service auth boundary"
            :detail "hyperdoc-mcp.service exposed no loaded DMX auth mode in the non-privileged environment view")
      (list :kind "object state"
            :detail "topic 927568 appeared stale/unassigned compared to a healthy companion topic"))
     :auth-context
     (list
      (list :key "effective-mode" :value "anonymous / workspace-cookie-only")
      (list :key "required-next-step"
            :value "normal authenticated DMX service account or explicit repair-console auth")
      (list :key "possible-residual-blocker"
            :value "privileged/operator repair if the existing companion remains stale or unassigned"))
     :adjacent-stages
     (list
      (list :stage "prepare-transition"
            :detail "Last reached stage before the blocked journal preflight.")
      (list :stage "topic-upsert"
            :detail "Later stage that was not reached because the boundary stayed blocked.")
      (list :stage "workspace-assignment"
            :detail "Later repair/continuation stage that depends on crossing the preflight boundary."))
     :related-surfaces
     (list
      (list :surface "Using authenticated workspace assignment repair console"
            :detail "Adjacent explicit-auth mutation surface for repair.")
      (list :surface "Diagnosing DMX workspace repair triage"
            :detail "Adjacent read-only diagnostic surface.")
      (list :surface "DMX workspace journal model"
            :detail "Broader guarded journal surface that contains this preflight boundary."))
     :source-evidence (dmx-boundary-source-evidence)
     :notes
     (list
      (list :label "Observed boundary"
            :detail "This instance records a blocked boundary crossing rather than changing current guarded behavior.")))))
