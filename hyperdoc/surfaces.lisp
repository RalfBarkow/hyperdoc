;;;; Generic surface runtime objects for HyperDoc
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass surface-definition ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (surface-kind :reader surface-definition-surface-kind-of
                 :initarg :surface-kind
                 :initform :generic)
   (layer :reader surface-definition-layer-of
          :initarg :layer
          :initform :mixed)
   (audience :reader surface-definition-audience-of
             :initarg :audience
             :initform nil)
   (scope :reader surface-definition-scope-of
          :initarg :scope
          :initform nil)
   (access-mode :reader surface-definition-access-mode-of
                :initarg :access-mode
                :initform :mixed)
   (capabilities :reader surface-definition-capabilities-of
                 :initarg :capabilities
                 :initform nil)
   (inputs :reader surface-definition-inputs-of
           :initarg :inputs
           :initform nil)
   (outputs :reader surface-definition-outputs-of
            :initarg :outputs
            :initform nil)
   (evidence-kinds :reader surface-definition-evidence-kinds-of
                   :initarg :evidence-kinds
                   :initform nil)
   (boundary-rules :reader surface-definition-boundary-rules-of
                   :initarg :boundary-rules
                   :initform nil)
   (related-surfaces :reader surface-definition-related-surfaces-of
                     :initarg :related-surfaces
                     :initform nil)
   (source-evidence :reader surface-definition-source-evidence-of
                    :initarg :source-evidence
                    :initform nil)
   (notes :reader surface-definition-notes-of
          :initarg :notes
          :initform nil)))

(defclass surface-instance ()
  ((definition :reader surface-instance-definition-of
               :initarg :definition)
   (subject :reader surface-instance-subject-of
            :initarg :subject
            :initform nil)
   (title :reader title-of
          :initarg :title
          :initform nil)
   (status :reader surface-instance-status-of
           :initarg :status
           :initform :available)
   (current-boundary-state :reader surface-instance-current-boundary-state-of
                           :initarg :current-boundary-state
                           :initform nil)
   (active-capabilities :reader surface-instance-active-capabilities-of
                        :initarg :active-capabilities
                        :initform nil)
   (visible-evidence :reader surface-instance-visible-evidence-of
                     :initarg :visible-evidence
                     :initform nil)
   (entrypoints :reader surface-instance-entrypoints-of
                :initarg :entrypoints
                :initform nil)
   (adjacent-surfaces :reader surface-instance-adjacent-surfaces-of
                      :initarg :adjacent-surfaces
                      :initform nil)
   (failure-surfaces :reader surface-instance-failure-surfaces-of
                     :initarg :failure-surfaces
                     :initform nil)
   (auth-requirements :reader surface-instance-auth-requirements-of
                      :initarg :auth-requirements
                      :initform nil)
   (source-evidence :reader surface-instance-source-evidence-of
                    :initarg :source-evidence
                    :initform nil)
   (notes :reader surface-instance-notes-of
          :initarg :notes
          :initform nil)))

(defun make-surface-definition
    (&key id title summary surface-kind layer audience scope access-mode
       capabilities inputs outputs evidence-kinds boundary-rules
       related-surfaces source-evidence notes)
  (make-instance 'surface-definition
                 :id id
                 :title title
                 :summary summary
                 :surface-kind surface-kind
                 :layer layer
                 :audience audience
                 :scope scope
                 :access-mode access-mode
                 :capabilities capabilities
                 :inputs inputs
                 :outputs outputs
                 :evidence-kinds evidence-kinds
                 :boundary-rules boundary-rules
                 :related-surfaces related-surfaces
                 :source-evidence source-evidence
                 :notes notes))

(defun make-surface-instance
    (&key definition subject title status current-boundary-state
       active-capabilities visible-evidence entrypoints adjacent-surfaces
       failure-surfaces auth-requirements source-evidence notes)
  (make-instance 'surface-instance
                 :definition definition
                 :subject subject
                 :title title
                 :status status
                 :current-boundary-state current-boundary-state
                 :active-capabilities active-capabilities
                 :visible-evidence visible-evidence
                 :entrypoints entrypoints
                 :adjacent-surfaces adjacent-surfaces
                 :failure-surfaces failure-surfaces
                 :auth-requirements auth-requirements
                 :source-evidence source-evidence
                 :notes notes))

(defmethod print-object ((object surface-definition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object surface-instance) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A"
            (or (title-of object)
                (title-of (surface-instance-definition-of object))))))

(defun surface-plist-p (item)
  (and (listp item)
       (loop for cursor on item by #'cddr
             always (and cursor
                         (or (keywordp (first cursor))
                             (symbolp (first cursor))
                             (stringp (first cursor)))))))

(defun surface-item-value (item key)
  (cond
    ((null item) nil)
    ((hash-table-p item)
     (multiple-value-bind (value present-p)
         (gethash key item)
       (if present-p
           value
           (let ((string-key (string-downcase (string key))))
             (gethash string-key item)))))
    ((surface-plist-p item)
     (or (getf item key)
         (let ((string-key (string-downcase (string key))))
           (getf item string-key))))
    ((and (listp item) (every #'consp item))
     (or (cdr (assoc key item :test #'equal))
         (let ((string-key (string-downcase (string key))))
           (cdr (assoc string-key item :test #'string=)))))
    (t nil)))

(defun surface-known-kind-p (kind)
  (member kind
          '(:generic :diagnostic :mutation :failure :publication :documentation)
          :test #'equal))

(defun surface-known-layer-p (layer)
  (member layer
          '(:durable :runtime :topic :fedwiki :mixed)
          :test #'equal))

(defun surface-known-access-mode-p (mode)
  (member mode '(:read-only :action-bearing :mixed) :test #'equal))

(defun surface-definition-findings (definition)
  (let ((findings '()))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (if (surface-known-kind-p
           (surface-definition-surface-kind-of definition))
          (note-finding "Surface kind"
                        :ok
                        (format nil "Surface kind ~A is recognized."
                                (surface-definition-surface-kind-of definition)))
          (note-finding "Surface kind"
                        :error
                        (format nil "Surface kind ~A is not recognized."
                                (surface-definition-surface-kind-of definition))))
      (if (surface-known-layer-p (surface-definition-layer-of definition))
          (note-finding "Layer"
                        :ok
                        (format nil "Layer ~A is recognized."
                                (surface-definition-layer-of definition)))
          (note-finding "Layer"
                        :error
                        (format nil "Layer ~A is not recognized."
                                (surface-definition-layer-of definition))))
      (if (surface-known-access-mode-p
           (surface-definition-access-mode-of definition))
          (note-finding "Access mode"
                        :ok
                        (format nil "Access mode ~A is declared."
                                (surface-definition-access-mode-of definition)))
          (note-finding "Access mode"
                        :error
                        (format nil "Access mode ~A is not recognized."
                                (surface-definition-access-mode-of definition))))
      (if (surface-definition-scope-of definition)
          (note-finding "Scope"
                        :ok
                        "Surface definition declares its scope.")
          (note-finding "Scope"
                        :warning
                        "Surface definition does not declare a scope."))
      (if (surface-definition-boundary-rules-of definition)
          (note-finding "Boundary rules"
                        :ok
                        "Surface definition declares explicit boundary rules.")
          (note-finding "Boundary rules"
                        :error
                        "Surface definition is missing its boundary rules."))
      (if (surface-definition-capabilities-of definition)
          (note-finding "Capabilities"
                        :ok
                        "Surface definition declares capabilities.")
          (note-finding "Capabilities"
                        :warning
                        "Surface definition declares no capabilities."))
      (nreverse findings))))

(defun surface-instance-findings (instance)
  (let ((findings '()))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (if (typep (surface-instance-definition-of instance) 'surface-definition)
          (note-finding "Definition binding"
                        :ok
                        "Surface instance points to a surface-definition.")
          (note-finding "Definition binding"
                        :error
                        "Surface instance does not point to a surface-definition."))
      (if (surface-instance-current-boundary-state-of instance)
          (note-finding "Boundary state"
                        :ok
                        "Surface instance records its current boundary state.")
          (note-finding "Boundary state"
                        :warning
                        "Surface instance does not record a current boundary state."))
      (when (and (eq (surface-instance-status-of instance) :blocked)
                 (null (surface-instance-failure-surfaces-of instance)))
        (note-finding "Failure surfaces"
                      :warning
                      "Blocked surface instance should record one or more failure surfaces."))
      (when (and (eq (surface-definition-access-mode-of
                      (surface-instance-definition-of instance))
                     :action-bearing)
                 (null (surface-instance-auth-requirements-of instance)))
        (note-finding "Auth requirements"
                      :warning
                      "Action-bearing surface instance should declare auth requirements."))
      (nreverse findings))))

(defun make-example-surface-definition ()
  (make-surface-definition
   :id "example-operational-surface"
   :title "Example operational surface"
   :summary "Reusable example surface showing scope, capabilities, evidence, and explicit boundary rules."
   :surface-kind :generic
   :layer :runtime
   :audience '("user" "robot")
   :scope "Inspect one bounded object and perform one bounded follow-up action without leaving the current context."
   :access-mode :mixed
   :capabilities '((:capability "Inspect selected object"
                     :mode "read-only"
                     :detail "Expose a stable runtime object and its views.")
                    (:capability "Submit bounded action"
                     :mode "action-bearing"
                     :detail "Run one scoped action with explicit confirmation."))
   :inputs '((:input "Selected object"
              :detail "The object or page/tab that the user has opened.")
             (:input "Optional action parameters"
              :detail "Extra values only when the action-bearing capability is used."))
   :outputs '((:output "Inspectable runtime object"
               :detail "The opened surface can be inspected directly.")
              (:output "Bounded action result"
               :detail "The action returns evidence without changing adjacent surfaces implicitly."))
   :evidence-kinds '("view render" "result summary" "adjacent-surface pointer")
   :boundary-rules '((:rule "Scope stays bounded"
                       :detail "The surface does not silently widen into adjacent tools.")
                     (:rule "Evidence remains visible"
                       :detail "The surface must expose the evidence forms it relies on."))
   :related-surfaces '((:surface "Surface and Artifact Answers"
                         :detail "Answer surfaces are one narrower family inside the broader surface vocabulary.")
                       (:surface "Documentation Surfaces in HyperDoc"
                         :detail "Durable pages, topics, inspectable handles, and FedWiki twins are explicit authored surface classes."))
   :source-evidence '((:layer "HyperDoc page"
                        :reference "Surface"
                        :detail "Generic operational definition and worked examples.")
                      (:layer "HyperDoc page"
                        :reference "HyperDoc Evaluation and Inspection Model"
                        :detail "Evaluation produces values; inspection renders views for the resulting object."))
   :notes '((:label "Example"
             :detail "This is a generic teaching object rather than a DMX-specific contract."))))

(defun make-example-surface-instance ()
  (make-surface-instance
   :definition (make-example-surface-definition)
   :subject '((:key "example-object")
              (:value "alpha-42"))
   :title "Example operational surface instance"
   :status :available
   :current-boundary-state '((:label "Current edge"
                               :detail "The object is open and inspection is active.")
                             (:label "Access mode"
                               :detail "mixed"))
   :active-capabilities '((:capability "Inspect selected object"
                            :detail "Overview and evidence views are available.")
                           (:capability "Submit bounded action"
                            :detail "One explicit action is available without leaving the surface."))
   :visible-evidence '((:kind "view render"
                         :detail "The opened object is visible through runtime views.")
                       (:kind "result summary"
                         :detail "The last action result remains attached to the same surface."))
   :entrypoints '((:entrypoint "Open page"
                    :detail "Enter through the authored page that names the surface.")
                  (:entrypoint "Inspect runtime object"
                    :detail "Enter directly through an expr-backed handle."))
   :adjacent-surfaces '((:surface "Durable page"
                          :detail "Narrative explanation stays adjacent, not collapsed into the runtime object.")
                        (:surface "Artifact answer"
                          :detail "Durable reconstruction is adjacent rather than identical."))
   :failure-surfaces '((:surface "Blocked action summary"
                         :detail "If the bounded action fails, the failure remains visible as evidence on the same surface family."))
   :auth-requirements '((:requirement "None for inspection"
                          :detail "The read portion of the example is open.")
                        (:requirement "Explicit confirmation for action"
                          :detail "The bounded action remains opt-in."))
   :source-evidence '((:layer "HyperDoc page"
                        :reference "Surface"
                        :detail "Worked example for the generic abstraction."))
   :notes '((:label "Example"
             :detail "Surface instances record the realized/opened case, not only the durable concept."))))

(defun make-dmx-workspace-repair-diagnostic-surface-definition ()
  (make-surface-definition
   :id "dmx-workspace-repair-diagnostic-surface"
   :title "DMX workspace repair diagnostic surface"
   :summary "Read-only diagnostic surface for shared-workspace objects that are visible in topicmap 919822 but still missing workspace assignment."
   :surface-kind :diagnostic
   :layer :runtime
   :audience '("operator" "maintainer" "robot")
   :scope "Inspect the current repair backlog and raw projection evidence for workspace 919815 and topicmap 919822 without performing mutation."
   :access-mode :read-only
   :capabilities '((:capability "Inspect repair triage"
                     :mode "read-only"
                     :detail "Show HyperDoc-owned candidates missing workspace assignment.")
                    (:capability "Inspect raw projection"
                     :mode "read-only"
                     :detail "Expose the source topicmap projection and enumerated topic ids.")
                    (:capability "Inspect per-topic diagnostics"
                     :mode "read-only"
                     :detail "Preserve workspace assignment and topicmap placement as distinct columns."))
   :inputs '((:input "Topicmap projection 919822"
              :detail "Read-only DMX projection used to derive the backlog.")
             (:input "Per-topic diagnostic classification"
              :detail "Ownership, topicmap presence, workspace assignment, and derived status."))
   :outputs '((:output "Repair triage table"
               :detail "Inspectable backlog view for the current defect class.")
              (:output "Raw projection evidence"
               :detail "Inspectable source payload and enumerated ids."))
   :evidence-kinds '("topicmap projection" "per-topic status row" "raw projection view")
   :boundary-rules '((:rule "Diagnosis stays read-only"
                       :detail "The diagnostic surface does not mutate DMX objects.")
                     (:rule "Workspace assignment stays distinct from topicmap placement"
                       :detail "The same object can be visible in topicmap 919822 while still missing workspace assignment."))
   :related-surfaces '((:surface "Using authenticated workspace assignment repair console"
                         :detail "Adjacent mutation surface for explicit-auth repair.")
                       (:surface "DMX workspace journal observed failure surface"
                         :detail "Failure surface that preserves blocked journal-preflight evidence.")
                       (:surface "DMX workspace journal model"
                         :detail "Journal/runtime context that the diagnostic surface helps explain."))
   :source-evidence '((:layer "HyperDoc page"
                        :reference "Diagnosing DMX workspace repair triage"
                        :detail "Read-only batch diagnostic surface for the shared workspace.")
                      (:layer "HyperDoc page"
                        :reference "Using authenticated workspace assignment repair console"
                        :detail "Explicitly separates diagnosis from mutation."))))

(defun make-dmx-workspace-repair-diagnostic-surface-instance ()
  (make-surface-instance
   :definition (make-dmx-workspace-repair-diagnostic-surface-definition)
   :subject '((:page "Diagnosing DMX workspace repair triage")
              (:workspace-id 919815)
              (:topicmap-id 919822))
   :title "DMX workspace repair diagnostic surface"
   :status :available
   :current-boundary-state '((:label "Access mode"
                               :detail "read-only")
                             (:label "Current boundary state"
                               :detail "Diagnosis can inspect backlog and raw projection but cannot run repair."))
   :active-capabilities '((:capability "Inspect repair triage"
                            :detail "Shows HyperDoc-owned candidates missing workspace assignment.")
                           (:capability "Inspect raw projection"
                            :detail "Shows the source projection and topic ids used for triage."))
   :visible-evidence '((:kind "repair candidate row"
                         :detail "Each row exposes topic id, title, ownership, topicmap presence, workspace assignment, and derived status.")
                       (:kind "raw projection"
                         :detail "The Raw projection tab preserves the source payload behind the triage."))
   :entrypoints '((:entrypoint "(make-dmx-workspace-repair-triage :topicmap-id 919822)"
                    :detail "Generic batch triage helper.")
                  (:entrypoint "(make-dmx-shared-workspace-repair-triage)"
                    :detail "Convenience entrypoint for the shared blackboard workspace."))
   :adjacent-surfaces '((:surface "Using authenticated workspace assignment repair console"
                          :detail "The separate mutation tab uses the same filtered backlog but adds explicit auth.")
                        (:surface "DMX workspace journal observed failure surface"
                          :detail "Blocked or lossy cases remain visible as adjacent failure surfaces."))
   :failure-surfaces '((:surface "DMX workspace journal observed failure surface"
                         :detail "Blocked journal preflight and auth failure evidence are inspectable without widening the diagnostic surface into mutation."))
   :auth-requirements '((:requirement "No live mutation credentials required"
                          :detail "Diagnosis is available without repair credentials."))
   :source-evidence '((:layer "HyperDoc page"
                        :reference "Diagnosing DMX workspace repair triage"
                        :detail "Defines the read-only batch companion surface.")
                      (:layer "HyperDoc page"
                        :reference "DMX workspace journal model"
                        :detail "Explains the journal/runtime context behind the same defect class."))))

(defun make-dmx-repair-console-mutation-surface-definition ()
  (make-surface-definition
   :id "dmx-repair-console-mutation-surface"
   :title "DMX repair console mutation surface"
   :summary "Explicit-auth mutation surface for guarded workspace-assignment repair of one selected topic or the current backlog."
   :surface-kind :mutation
   :layer :runtime
   :audience '("operator" "maintainer")
   :scope "Perform dry-run or live guarded workspace-assignment repair for workspace 919815 and topicmap 919822 without widening into a general DMX mutation shell."
   :access-mode :action-bearing
   :capabilities '((:capability "Dry-run selected topic"
                     :mode "action-bearing"
                     :detail "Preview guarded repair without live mutation.")
                    (:capability "Repair selected topic"
                     :mode "action-bearing"
                     :detail "Run one guarded live repair with explicit credentials.")
                    (:capability "Dry-run backlog"
                     :mode "action-bearing"
                     :detail "Preview the current filtered backlog.")
                    (:capability "Repair backlog"
                     :mode "action-bearing"
                     :detail "Run the guarded repair executor over the current backlog."))
   :inputs '((:input "Selected topic or current backlog"
              :detail "The repair target chosen from the adjacent diagnostic surface.")
             (:input "Credential mode"
              :detail "username/password, authorization header, or bearer token.")
             (:input "Explicit ephemeral credentials"
              :detail "Credentials are entered at action time and not retained as durable topic content."))
   :outputs '((:output "Guarded dry-run report"
               :detail "Preview of readiness or blocked state without mutation.")
              (:output "Sanitized live result readback"
               :detail "Per-topic live result table with status and error summary.")
              (:output "Same guarded executor outcome"
               :detail "The surface reuses the existing guarded repair executor rather than inventing a second path."))
   :evidence-kinds '("credential mode summary" "dry-run result" "live result readback" "guarded error report")
   :boundary-rules '((:rule "Explicit auth required"
                       :detail "Live mutation depends on credentials supplied at action time.")
                     (:rule "Diagnosis remains adjacent and read-only"
                       :detail "The repair console does not absorb the triage surface.")
                     (:rule "Guarded executor unchanged"
                       :detail "The surface uses the same guarded workspace-assignment repair executor already used elsewhere."))
   :related-surfaces '((:surface "Diagnosing DMX workspace repair triage"
                         :detail "Adjacent read-only backlog and projection surface.")
                       (:surface "Inspectable authentication-path traces for repair console"
                         :detail "Teachable auth-path evidence surface for the credential modes.")
                       (:surface "DMX workspace journal observed failure surface"
                         :detail "Blocked journal preflight remains visible as a separate failure surface."))
   :source-evidence '((:layer "HyperDoc page"
                        :reference "Using authenticated workspace assignment repair console"
                        :detail "Defines the explicit-auth mutation surface.")
                      (:layer "HyperDoc page"
                        :reference "HyperDoc three-mode DMX auth crosswalk"
                        :detail "Keeps the credential-mode learning surface inspectable without widening live behavior."))))

(defun make-dmx-repair-console-mutation-surface-instance ()
  (make-surface-instance
   :definition (make-dmx-repair-console-mutation-surface-definition)
   :subject '((:page "Using authenticated workspace assignment repair console")
              (:workspace-id 919815)
              (:topicmap-id 919822)
              (:tab "Repair console"))
   :title "DMX repair console mutation surface"
   :status :guarded-available
   :current-boundary-state '((:label "Current boundary state"
                               :detail "The repair console is available, but live mutation remains guarded behind explicit auth.")
                             (:label "Access mode"
                               :detail "action-bearing"))
   :active-capabilities '((:capability "Dry-run selected topic"
                            :detail "Preview one candidate without mutation.")
                           (:capability "Repair selected topic"
                            :detail "Run the guarded live repair for one candidate.")
                           (:capability "Repair backlog"
                            :detail "Run the guarded live repair for the current filtered backlog."))
   :visible-evidence '((:kind "credential mode selector"
                         :detail "username/password, authorization header, and bearer token remain explicit and inspectable.")
                       (:kind "result readback"
                         :detail "The same console shows sanitized per-topic live result readback after the action.")
                       (:kind "guarded error report"
                         :detail "Failed actions preserve status and error message instead of silently widening into raw DMX mutation."))
   :entrypoints '((:entrypoint "Repair console tab on (make-operational-definition-note-proxy)"
                    :detail "Single-topic entrypoint.")
                  (:entrypoint "Repair console tab on (make-dmx-shared-workspace-repair-triage)"
                    :detail "Backlog entrypoint."))
   :adjacent-surfaces '((:surface "Diagnosing DMX workspace repair triage"
                          :detail "Read-only triage/backlog companion surface.")
                        (:surface "Inspectable authentication-path traces for repair console"
                          :detail "Auth-path teaching surface for the same credential modes.")
                        (:surface "DMX workspace journal observed failure surface"
                          :detail "Blocked preflight evidence remains visible as a separate failure surface."))
   :failure-surfaces '((:surface "DMX workspace journal observed failure surface"
                         :detail "The current blocked case remains at prepare-transition when journal preflight fails before later mutation stages."))
   :auth-requirements '((:requirement "Explicit credential mode selection"
                          :detail "One of username/password, authorization header, or bearer token must be chosen.")
                        (:requirement "Ephemeral credentials"
                          :detail "Credentials are used at action time and then discarded with the console refresh.")
                        (:requirement "Valid DMX write authority"
                          :detail "The console does not widen permissions beyond the supplied authenticated client."))
   :source-evidence '((:layer "HyperDoc page"
                        :reference "Using authenticated workspace assignment repair console"
                        :detail "Documents the mutation tab and its guarded behavior.")
                      (:layer "HyperDoc page"
                        :reference "Inspectable authentication-path traces for repair console"
                        :detail "Explains the auth-path evidence and credential-mode distinctions."))))

(defun make-dmx-workspace-journal-observed-failure-surface-definition ()
  (make-surface-definition
   :id "dmx-workspace-journal-observed-failure-surface"
   :title "DMX workspace journal observed failure surface"
   :summary "Failure surface for blocked workspace-journal preflight and related repair evidence around carrier 927558 and companion 927568."
   :surface-kind :failure
   :layer :runtime
   :audience '("operator" "maintainer" "robot")
   :scope "Preserve blocked journal-preflight evidence, the last reached stage, and the adjacent diagnostic and mutation surfaces without widening live behavior."
   :access-mode :read-only
   :capabilities '((:capability "Inspect last reached boundary state"
                     :mode "read-only"
                     :detail "Show the blocked stage and failing mutation attempt.")
                    (:capability "Inspect adjacent recovery surfaces"
                     :mode "read-only"
                     :detail "Point to the diagnostic and mutation surfaces that can act on the same case.")
                    (:capability "Inspect auth and object-state evidence"
                     :mode "read-only"
                     :detail "Preserve the 401/auth context and stale-companion observations as evidence, not as implicit repair."))
   :inputs '((:input "Blocked run evidence"
              :detail "prepare-transition stop, failing PUT, auth context, and object-state observations.")
             (:input "Adjacent repair-surface context"
              :detail "The diagnostic and mutation surfaces connected to the same case."))
   :outputs '((:output "Failure-surface summary"
               :detail "First-class blocked-surface object rather than prose alone.")
              (:output "Adjacent next-step surfaces"
               :detail "The surface names the diagnostic and mutation surfaces that remain relevant."))
   :evidence-kinds '("last reached stage" "HTTP failure" "auth summary" "object-state observation")
   :boundary-rules '((:rule "Failure surface remains read-only"
                       :detail "It does not attempt repair directly.")
                     (:rule "Blocked evidence stays attached"
                       :detail "The surface preserves the failing stage, mutation, and auth evidence as inspectable data.")
                     (:rule "Adjacent surfaces stay explicit"
                       :detail "The diagnostic and mutation surfaces remain separate rather than being collapsed into the failure surface."))
   :related-surfaces '((:surface "Diagnosing DMX workspace repair triage"
                         :detail "Read-only diagnostic companion for the same defect class.")
                       (:surface "Using authenticated workspace assignment repair console"
                         :detail "Explicit-auth mutation companion.")
                       (:surface "DMX workspace journal model"
                         :detail "Explains the journal/runtime context of the blocked preflight.")
                       (:surface "DMX workspace journal reconcile call graph"
                         :detail "Shows related read/write-capable edges and suppressed write paths."))
   :source-evidence '((:layer "HyperDoc page"
                        :reference "Diagnosing DMX workspace repair triage"
                        :detail "Read-only diagnostic surface adjacent to the same failure class.")
                      (:layer "HyperDoc page"
                        :reference "Using authenticated workspace assignment repair console"
                        :detail "Explicit-auth mutation surface adjacent to the same failure class.")
                      (:layer "HyperDoc page"
                        :reference "DMX workspace journal model"
                        :detail "Defines the journal preflight context that later blocks."))
   :notes '((:label "Behavior"
             :detail "This surface preserves current guarded behavior and does not widen write permissions."))))

(defun make-dmx-workspace-journal-observed-failure-surface-instance ()
  (make-surface-instance
   :definition (make-dmx-workspace-journal-observed-failure-surface-definition)
   :subject '((:carrier-topic-id 927558)
              (:journal-companion-topic-id 927568)
              (:workspace-id 919815)
              (:workspace-topicmap-id 919822))
   :title "DMX workspace journal observed failure surface"
   :status :blocked
   :current-boundary-state '((:label "Last reached stage"
                               :detail "prepare-transition")
                             (:label "Attempted mutation"
                               :detail "PUT /core/topic/927568")
                             (:label "Crossing result"
                               :detail "blocked"))
   :active-capabilities '((:capability "Inspect blocked preflight evidence"
                            :detail "Show the 401 failure, auth context, and object-state observations.")
                           (:capability "Open adjacent repair surfaces"
                            :detail "Point to diagnostic and mutation companions without repairing from inside the failure surface."))
   :visible-evidence '((:kind "failure stage"
                         :detail "prepare-transition")
                       (:kind "failing mutation"
                         :detail "PUT /core/topic/927568")
                       (:kind "HTTP result"
                         :detail "HTTP 401: user <anonymous> has no WRITE permission for object 927568")
                       (:kind "service auth state"
                         :detail "hyperdoc-mcp.service exposed no loaded DMX auth mode in the non-privileged environment view.")
                       (:kind "object-state observation"
                         :detail "Topic 927568 appeared stale or unassigned compared with the healthy companion note path."))
   :entrypoints '((:entrypoint "Diagnosing DMX workspace repair triage"
                    :detail "Read-only diagnosis and backlog view.")
                  (:entrypoint "Using authenticated workspace assignment repair console"
                    :detail "Explicit-auth mutation surface for bounded repair attempts."))
   :adjacent-surfaces '((:surface "Diagnosing DMX workspace repair triage"
                          :detail "Read-only diagnostic surface adjacent to the failure case.")
                        (:surface "Using authenticated workspace assignment repair console"
                          :detail "Mutation surface that can attempt bounded repair once valid credentials are supplied.")
                        (:surface "DMX workspace journal model"
                          :detail "Journal/runtime surface that explains the guarded preflight stage."))
   :failure-surfaces '((:surface "Auth-blocked journal preflight"
                         :detail "The concrete block occurred at prepare-transition before later stages could run.")
                       (:surface "Stale companion topic state"
                         :detail "Companion topic 927568 may still need privileged/operator repair even after auth becomes available."))
   :auth-requirements '((:requirement "No mutation from the failure surface itself"
                          :detail "This surface remains read-only.")
                        (:requirement "Adjacent mutation surface needs valid DMX credentials"
                          :detail "The repair console remains explicit-auth and guarded.")
                        (:requirement "Privileged/operator repair may still be required"
                          :detail "If 927568 remains stale or unassigned after auth is present, ordinary authenticated repair may still be insufficient."))
   :source-evidence '((:layer "Live replay"
                        :reference "continue_workspace_annotation"
                        :detail "The live continuation stopped at prepare-transition.")
                      (:layer "Live replay"
                        :reference "repair_workspace_topic_assignment"
                        :detail "The dry-run was coherent, but live repair required authenticated DMX mutation.")
                      (:layer "HyperDoc page"
                        :reference "Using authenticated workspace assignment repair console"
                        :detail "Mutation remains explicit-auth and guarded."))))
