(in-package :hyperdoc)

(defparameter *snippet-playground-mech-ops*
  '("APPLY" "CLICK" "CODE" "DELTA" "EDGES" "EXTRACT" "GET" "NEIGHBORS"
    "PREVIEW" "PRINT" "PUT" "REVIEW" "SOLO" "WALK"))

(defclass mech-snippet-step ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (line-number :reader mech-snippet-step-line-number-of
                :initarg :line-number)
   (raw-line :reader mech-snippet-step-raw-line-of
             :initarg :raw-line)
   (operation :reader mech-snippet-step-operation-of
              :initarg :operation)
   (arguments :reader mech-snippet-step-arguments-of
              :initarg :arguments
              :initform nil)))

(defclass mech-snippet ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (block-index :reader mech-snippet-block-index-of
                :initarg :block-index)
   (line-number :reader mech-snippet-line-number-of
                :initarg :line-number)
   (location-label :reader snippet-location-label-of
                   :initarg :location-label
                   :initform nil)
   (source :reader mech-snippet-source-of
           :initarg :source)
   (steps :reader mech-snippet-steps-of
          :initarg :steps
          :initform nil)
   (preview-mode :reader mech-snippet-preview-mode-of
                 :initarg :preview-mode
                 :initform nil)
   (score :reader mech-snippet-score-of
          :initarg :score
          :initform 0)
   (findings :reader mech-snippet-findings-of
             :initarg :findings
             :initform nil)))

(defclass code-snippet ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (block-index :reader code-snippet-block-index-of
                :initarg :block-index)
   (line-number :reader code-snippet-line-number-of
                :initarg :line-number)
   (location-label :reader snippet-location-label-of
                   :initarg :location-label
                   :initform nil)
   (source :reader code-snippet-source-of
           :initarg :source)
   (language :reader code-snippet-language-of
             :initarg :language
             :initform :unknown)
   (output-path :reader code-snippet-output-path-of
                :initarg :output-path
                :initform nil)
   (translation-mode :reader code-snippet-translation-mode-of
                     :initarg :translation-mode
                     :initform :generic)
   (score :reader code-snippet-score-of
          :initarg :score
          :initform 0)
   (findings :reader code-snippet-findings-of
             :initarg :findings
             :initform nil)))

(defclass javascript-code-snippet (code-snippet) ())

(defclass unsupported-code-snippet (code-snippet) ())

(defclass snippet-comparison-region ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (placement :reader snippet-comparison-region-placement-of
              :initarg :placement)
   (content-key :reader snippet-comparison-region-content-key-of
                :initarg :content-key)
   (source-text :reader snippet-comparison-region-source-text-of
                :initarg :source-text
                :initform "")
   (findings :reader snippet-comparison-region-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-comparison-surface ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (layout-spec :reader snippet-comparison-surface-layout-spec-of
                :initarg :layout-spec)
   (regions :reader snippet-comparison-surface-regions-of
            :initarg :regions
            :initform nil)
   (left-code-region :reader snippet-comparison-surface-left-code-region-of
                     :initarg :left-code-region
                     :initform nil)
   (shared-mech-region :reader snippet-comparison-surface-shared-mech-region-of
                       :initarg :shared-mech-region
                       :initform nil)
   (right-code-region :reader snippet-comparison-surface-right-code-region-of
                      :initarg :right-code-region
                      :initform nil)
   (execution-interface :reader snippet-comparison-surface-execution-interface-of
                        :initarg :execution-interface
                        :initform nil)
   (transformation-unit :reader snippet-comparison-surface-transformation-unit-of
                        :initarg :transformation-unit
                        :initform nil)
   (lifecycle-run :reader snippet-comparison-surface-lifecycle-run-of
                  :initarg :lifecycle-run
                  :initform nil)
   (findings :reader snippet-comparison-surface-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-execution-interface ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (handoff-path :reader snippet-execution-interface-handoff-path-of
                 :initarg :handoff-path
                 :initform nil)
   (preview-mode :reader snippet-execution-interface-preview-mode-of
                 :initarg :preview-mode
                 :initform nil)
   (output-channel :reader snippet-execution-interface-output-channel-of
                   :initarg :output-channel
                   :initform nil)
   (input-role-name :reader snippet-execution-interface-input-role-name-of
                    :initarg :input-role-name
                    :initform nil)
   (output-role-name :reader snippet-execution-interface-output-role-name-of
                     :initarg :output-role-name
                     :initform nil)
   (findings :reader snippet-execution-interface-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-lefty-projection ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (origin-surface-kind :reader snippet-lefty-projection-origin-surface-kind-of
                        :initarg :origin-surface-kind
                        :initform nil)
   (provider-kind :reader snippet-lefty-projection-provider-kind-of
                  :initarg :provider-kind
                  :initform nil)
   (origin-label :reader snippet-lefty-projection-origin-label-of
                 :initarg :origin-label
                 :initform nil)
   (context-view-title :reader snippet-lefty-projection-context-view-title-of
                       :initarg :context-view-title
                       :initform nil)
   (mech-snippet :reader snippet-lefty-projection-mech-snippet-of
                 :initarg :mech-snippet
                 :initform nil)
   (code-snippet :reader snippet-lefty-projection-code-snippet-of
                 :initarg :code-snippet
                 :initform nil)
   (findings :reader snippet-lefty-projection-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-rita-projection ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (mech-snippet :reader snippet-rita-projection-mech-snippet-of
                 :initarg :mech-snippet
                 :initform nil)
   (execution-interface :reader snippet-rita-projection-execution-interface-of
                        :initarg :execution-interface
                        :initform nil)
   (lisp-scaffold-source :reader snippet-rita-projection-lisp-scaffold-source-of
                         :initarg :lisp-scaffold-source
                         :initform nil)
   (findings :reader snippet-rita-projection-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-transformation-unit ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (mech-snippet :reader snippet-transformation-unit-mech-snippet-of
                 :initarg :mech-snippet
                 :initform nil)
   (code-snippet :reader snippet-transformation-unit-code-snippet-of
                 :initarg :code-snippet
                 :initform nil)
   (execution-interface :reader snippet-transformation-unit-execution-interface-of
                        :initarg :execution-interface
                        :initform nil)
   (preview-mode :reader snippet-transformation-unit-preview-mode-of
                 :initarg :preview-mode
                 :initform nil)
   (input-kind :reader snippet-transformation-unit-input-kind-of
               :initarg :input-kind
               :initform nil)
   (input-shape :reader snippet-transformation-unit-input-shape-of
                :initarg :input-shape
                :initform nil)
   (operation-kind :reader snippet-transformation-unit-operation-kind-of
                   :initarg :operation-kind
                   :initform nil)
   (operation-summary :reader snippet-transformation-unit-operation-summary-of
                      :initarg :operation-summary
                      :initform nil)
   (output-kind :reader snippet-transformation-unit-output-kind-of
                :initarg :output-kind
                :initform nil)
   (output-shape :reader snippet-transformation-unit-output-shape-of
                 :initarg :output-shape
                 :initform nil)
   (lefty-projection :reader snippet-transformation-unit-lefty-projection-of
                     :initarg :lefty-projection
                     :initform nil)
   (rita-projection :reader snippet-transformation-unit-rita-projection-of
                    :initarg :rita-projection
                    :initform nil)
   (findings :reader snippet-transformation-unit-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-playground-session ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (status :reader snippet-playground-session-status-of
           :initarg :status
           :initform :malformed)
   (context-object :reader snippet-playground-session-context-object-of
                   :initarg :context-object
                   :initform nil)
   (context-view-title :reader snippet-playground-session-context-view-title-of
                       :initarg :context-view-title
                       :initform nil)
   (origin-surface-kind
     :reader snippet-playground-session-origin-surface-kind-of
     :initarg :origin-surface-kind
     :initform "html-source")
   (provider-kind :reader snippet-playground-session-provider-kind-of
                  :initarg :provider-kind
                  :initform "source-v1")
   (source-label :reader snippet-playground-session-source-label-of
                 :initarg :source-label
                 :initform nil)
   (source-pathname :reader snippet-playground-session-source-pathname-of
                    :initarg :source-pathname
                    :initform nil)
   (source-text :reader snippet-playground-session-source-text-of
                :initarg :source-text
                :initform "")
   (source-block-count
     :reader snippet-playground-session-source-block-count-of
     :initarg :source-block-count
     :initform 0)
   (recognized-mech-snippets
     :reader snippet-playground-session-recognized-mech-snippets-of
     :initarg :recognized-mech-snippets
     :initform nil)
   (recognized-code-snippets
     :reader snippet-playground-session-recognized-code-snippets-of
     :initarg :recognized-code-snippets
     :initform nil)
   (selected-mech :reader snippet-playground-session-selected-mech-of
                  :initarg :selected-mech
                  :initform nil)
   (selected-code :reader snippet-playground-session-selected-code-of
                  :initarg :selected-code
                  :initform nil)
   (execution-interface
     :reader snippet-playground-session-execution-interface-of
     :initarg :execution-interface
     :initform nil)
   (transformation-unit
     :reader snippet-playground-session-transformation-unit-of
     :initarg :transformation-unit
     :initform nil)
   (comparison-surface
     :reader snippet-playground-session-comparison-surface-of
     :initarg :comparison-surface
     :initform nil)
   (crosswalk :reader snippet-playground-session-crosswalk-of
              :initarg :crosswalk
              :initform nil)
   (pairing-notes :reader snippet-playground-session-pairing-notes-of
                  :initarg :pairing-notes
                  :initform nil)
   (lisp-scaffold-source
     :reader snippet-playground-session-lisp-scaffold-source-of
     :initarg :lisp-scaffold-source
     :initform nil)
   (derived-items :accessor snippet-playground-session-derived-items-of
                  :initarg :derived-items
                  :initform nil)
   (last-run-object :accessor snippet-playground-session-last-run-object-of
                    :initarg :last-run-object
                    :initform nil)
   (state-machine-run
     :accessor snippet-playground-session-state-machine-run-of
     :initarg :state-machine-run
     :initform nil)
   (findings :reader snippet-playground-session-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-playground-failure (snippet-playground-session)
  ((failure-classification
     :reader snippet-playground-failure-classification-of
     :initarg :failure-classification
     :initform :failed)))

(defmethod print-object ((object mech-snippet-step) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object mech-snippet) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object code-snippet) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-comparison-region) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-comparison-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-execution-interface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-lefty-projection) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-rita-projection) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-transformation-unit) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-playground-session) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod html-inspector-views:text-representation ((object mech-snippet-step))
  (title-of object))

(defmethod html-inspector-views:text-representation ((object mech-snippet))
  (title-of object))

(defmethod html-inspector-views:text-representation ((object code-snippet))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-comparison-region))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-comparison-surface))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-execution-interface))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-lefty-projection))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-rita-projection))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-transformation-unit))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-playground-session))
  (title-of object))

(defun snippet-playground-current-millis ()
  (if (fboundp 'clog-moldable-inspector::maybe-current-time-millis)
      (clog-moldable-inspector::maybe-current-time-millis)
      (* 1000 (get-universal-time))))

(defun pending-evaluation-origin-pane-id ()
  (when (fboundp 'clog-moldable-inspector::pending-evaluation-origin-pane-id)
    (clog-moldable-inspector::pending-evaluation-origin-pane-id)))

(defun pending-evaluation-pane-id ()
  (when (fboundp 'clog-moldable-inspector::pending-evaluation-pane-id)
    (clog-moldable-inspector::pending-evaluation-pane-id)))

(defun snippet-playground-report-progress (phase message &key detail)
  (when (fboundp 'clog-moldable-inspector::report-pending-evaluation-progress)
    (clog-moldable-inspector::report-pending-evaluation-progress
     phase
     message
     :detail detail)))

(defvar *snippet-playground-run-state-machine* nil)

(defparameter *snippet-comparison-layout-spec*
  '(:surface snippet-comparison
    :regions ((:left :region left-code-region :content javascript-code
               :title "JavaScript")
              (:center :region shared-mech-region :content shared-mech
               :title "Mech")
              (:right :region right-code-region :content lisp-code
               :title "Lisp"))
    :rules ((:show-once shared-mech))))

(defvar *snippet-comparison-surface-lifecycle-state-machine* nil)

(defun snippet-playground-run-state-machine ()
  (or *snippet-playground-run-state-machine*
      (setf *snippet-playground-run-state-machine*
            (make-state-machine-definition
             :id "snippet_playground_run"
             :title "snippet_playground_run"
             :summary
             "Origin-aware snippet-playground lifecycle shared by html-source and fedwiki-page providers."
             :states
             (list
              (make-state-machine-state
               :id :unavailable
               :title "unavailable"
               :summary "Snippet capability is hidden because the current pane does not expose a snippet provider.")
              (make-state-machine-state
               :id :available
               :title "available"
               :summary "Snippet capability is visible on the origin pane.")
              (make-state-machine-state
               :id :invoked
               :title "invoked"
               :summary "The user clicked Snippet on the origin pane.")
              (make-state-machine-state
               :id :pending
               :title "pending"
               :summary "A pending pane has opened to the right of the origin pane.")
              (make-state-machine-state
               :id :collecting-input
               :title "collecting_input"
               :summary "Provider-specific snippet input is being collected.")
              (make-state-machine-state
               :id :recognizing
               :title "recognizing"
               :summary "Mech and code snippets are being recognized.")
              (make-state-machine-state
               :id :pairing
               :title "pairing"
               :summary "Recognized Mech/code evidence is being selected before semantic binding.")
              (make-state-machine-state
               :id :building-session
               :title "building_session"
               :summary "The inspectable snippet-playground session is being built.")
              (make-state-machine-state
               :id :ready
               :title "ready"
               :summary "Pending pane has been replaced in place by a ready snippet session.")
              (make-state-machine-state
               :id :failed
               :title "failed"
               :summary "Pending pane has been replaced by an inspectable failure object."))
             :transitions
             (list
              (make-state-machine-transition
               :id "snippet/unavailable->available"
               :from-state :unavailable
               :to-state :available
               :guard :pane-supports-snippet-provider
               :side-effects
               "Show Snippet in the capability row for html-source and fedwiki-page surfaces.")
              (make-state-machine-transition
               :id "snippet/available->invoked"
               :from-state :available
               :to-state :invoked
               :trigger :snippet-click)
              (make-state-machine-transition
               :id "snippet/invoked->pending"
               :from-state :invoked
               :to-state :pending
               :trigger :open-pending-pane
               :side-effects
               "Open a pending pane to the right of the origin pane and retain the origin-pane placement invariant.")
              (make-state-machine-transition
               :id "snippet/pending->collecting-input"
               :from-state :pending
               :to-state :collecting-input
               :trigger :pending-pane-opened)
              (make-state-machine-transition
               :id "snippet/collecting-input->recognizing"
               :from-state :collecting-input
               :to-state :recognizing
               :guard :input-extracted)
              (make-state-machine-transition
               :id "snippet/recognizing->pairing"
               :from-state :recognizing
               :to-state :pairing
               :guard :candidates-found)
              (make-state-machine-transition
               :id "snippet/pairing->building-session"
               :from-state :pairing
               :to-state :building-session
               :guard :valid-pair)
              (make-state-machine-transition
               :id "snippet/building-session->ready"
               :from-state :building-session
               :to-state :ready
               :trigger :session-built)
              (make-state-machine-transition
               :id "snippet/collecting-input->failed"
               :from-state :collecting-input
               :to-state :failed
               :trigger :input-collection-failed)
              (make-state-machine-transition
               :id "snippet/recognizing->failed"
               :from-state :recognizing
               :to-state :failed
               :trigger :recognition-failed)
              (make-state-machine-transition
               :id "snippet/pairing->failed"
               :from-state :pairing
               :to-state :failed
               :trigger :pairing-failed)
              (make-state-machine-transition
               :id "snippet/building-session->failed"
               :from-state :building-session
               :to-state :failed
               :trigger :session-build-failed))
             :initial-state :unavailable
             :terminal-states '(:ready :failed)
             :failure-states '(:failed)
             :guards
             '(:pane-supports-snippet-provider :input-extracted
               :candidates-found :valid-pair)
             :events
             '(:snippet-click :open-pending-pane :pending-pane-opened
               :input-collection-failed :recognition-failed :pairing-failed
               :session-build-failed :session-built)
             :invariants
             (list
              (list :label "Result pane placement"
                    :detail
                    "The result pane is always created to the right of the pane that initiated Snippet.")
              (list :label "Shared lifecycle"
                    :detail
                    "The same run states apply to html-source and fedwiki-page providers.")
              (list :label "Inspectable failure"
                    :detail
                    "Malformed or unsupported input resolves to an inspectable failure object rather than a silent failure."))
             :source-evidence
             (list
              (list :layer "browser"
                    :reference "assets/hyperdoc/js/dom-annotation-connect.js"
                    :detail
                    "Capability visibility and invocation reuse the existing pane-shell submit bridge.")
              (list :layer "server"
                    :reference "hyperbook-server/inspector-wiring.lisp"
                    :detail
                    "Pending panes open to the right of the origin pane and are replaced in place.")
              (list :layer "provider"
                    :reference "hyperdoc-explorer/dom-annotations.lisp"
                    :detail
                    "html-source and fedwiki-page surfaces both dispatch through provider-aware snippet targets.")
              (list :layer "session"
                    :reference "hyperdoc-inspector/snippet-playground.lisp"
                    :detail
                    "Recognition, evidence selection, session construction, and failure objects all share the same run definition."))))))

(defun snippet-comparison-surface-lifecycle-state-machine ()
  (or *snippet-comparison-surface-lifecycle-state-machine*
      (setf *snippet-comparison-surface-lifecycle-state-machine*
            (make-state-machine-definition
             :id "snippet_comparison_surface"
             :title "snippet_comparison_surface"
             :summary
             "Small lifecycle for the declarative snippet comparison surface."
             :states
             (list
              (make-state-machine-state
               :id :available
               :title "available"
               :summary
               "Comparison surface can be built from the selected snippet evidence.")
              (make-state-machine-state
               :id :pending
               :title "pending"
               :summary
               "Pending pane is visible to the right of the origin pane.")
              (make-state-machine-state
               :id :ready
               :title "ready"
               :summary
               "Pending pane was replaced in place by a ready comparison surface.")
              (make-state-machine-state
               :id :failed
               :title "failed"
               :summary
               "Pending pane was replaced in place by an inspectable failed comparison surface."))
             :transitions
             (list
              (make-state-machine-transition
               :id "comparison/available->pending"
               :from-state :available
               :to-state :pending
               :trigger :open-pending-pane
               :side-effects
               "Open a pending pane to the right of the origin pane.")
              (make-state-machine-transition
               :id "comparison/pending->ready"
               :from-state :pending
               :to-state :ready
               :trigger :comparison-built
               :side-effects
               "Replace the pending pane in place with the ready comparison surface.")
              (make-state-machine-transition
               :id "comparison/pending->failed"
               :from-state :pending
               :to-state :failed
               :trigger :comparison-failed
               :side-effects
               "Replace the pending pane in place with an inspectable failure surface."))
             :initial-state :available
             :terminal-states '(:ready :failed)
             :failure-states '(:failed)
             :events '(:open-pending-pane :comparison-built :comparison-failed)
             :invariants
             (list
              (list :label "Placement invariant"
                    :detail
                    "Result pane remains to the right of the pane that initiated Snippet.")
              (list :label "Pending replacement"
                    :detail
                    "Ready and failed surfaces both replace the pending pane in place."))
             :source-evidence
             (list
              (list :layer "session"
                    :reference "hyperdoc-inspector/snippet-playground.lisp"
                    :detail
                    "Comparison surface layout and lifecycle are carried separately from the primary snippet run state machine."))))))

(defun make-snippet-comparison-surface-lifecycle-run
    (&key status source-label origin-pane-id pending-pane-id
       failure-classification)
  (let* ((current-state (if (eq status :ready) :ready :failed))
         (transition-id (if (eq status :ready)
                            :comparison-built
                            :comparison-failed))
         (status-label (if (eq status :ready) :finished :failed))
         (end-time (snippet-playground-current-millis)))
    (make-state-machine-run
     :id (format nil "state-machine-run/snippet-comparison/~A"
                 (or pending-pane-id origin-pane-id source-label "surface"))
     :title (format nil "snippet_comparison_surface (~A)"
                    (or source-label "snippet"))
     :summary
     "Lifecycle for the three-region comparison surface."
     :machine (snippet-comparison-surface-lifecycle-state-machine)
     :input
     (list
      :origin_pane_id origin-pane-id
      :pending_pane_id pending-pane-id
      :surface_layout *snippet-comparison-layout-spec*)
     :current-state current-state
     :visited-states (if (eq status :ready)
                         '(:available :pending :ready)
                         '(:available :pending :failed))
     :transition-trace
     (list
      (snippet-playground-transition-entry
       :available
       :pending
       :open-pending-pane
       (format nil
               "Comparison surface pending pane ~A opened to the right of origin pane ~A."
               (or pending-pane-id "n/a")
               (or origin-pane-id "n/a")))
      (snippet-playground-transition-entry
       :pending
       current-state
       transition-id
       (if (eq status :ready)
           "Comparison surface replaced the pending pane in place."
           "Failed comparison surface replaced the pending pane in place.")))
     :evidence-trace nil
     :start-time end-time
     :end-time end-time
     :status status-label
     :failure-classification failure-classification
     :notes
     (list
      (list :label "Placement invariant"
            :detail
            (format nil
                    "Origin pane ~A determines right-of placement; pending pane ~A is replaced in place."
                    (or origin-pane-id "n/a")
                    (or pending-pane-id "n/a")))))))

(defun snippet-playground-object-label (object)
  (cond
    ((null object)
     nil)
    ((ignore-errors (title-of object)))
    (t
     (format nil "~A" object))))

(defun snippet-playground-snippet-labels (snippets)
  (mapcar #'snippet-playground-object-label snippets))

(defun snippet-playground-selected-evidence-summary (selected-mech selected-code)
  (when (or selected-mech selected-code)
    (list (cons :mech (snippet-playground-object-label selected-mech))
          (cons :code (snippet-playground-object-label selected-code)))))

(defun make-snippet-playground-state-machine-run
    (&key current-state visited-states transition-trace evidence-trace
       start-time end-time status failure-classification
       source-label origin-pane-id origin-surface-kind provider-kind
       pending-pane-id recognized-mech-snippets recognized-code-snippets
       selected-mech selected-code execution-interface transformation-unit
       result-object failure-object)
  (make-state-machine-run
   :id (format nil "state-machine-run/snippet-playground/~A"
               (or pending-pane-id origin-pane-id source-label "session"))
   :title (format nil "snippet_playground_run (~A)"
                  (or source-label origin-surface-kind "snippet"))
   :summary
   "Shared snippet-playground lifecycle from visible capability to ready session or inspectable failure."
   :machine (snippet-playground-run-state-machine)
   :input
   (list
    :origin_pane_id origin-pane-id
    :origin_surface_kind origin-surface-kind
    :provider_kind provider-kind
    :pending_pane_id pending-pane-id
    :recognized_mech_snippets
    (snippet-playground-snippet-labels recognized-mech-snippets)
    :recognized_code_snippets
    (snippet-playground-snippet-labels recognized-code-snippets)
    :selected_evidence
    (snippet-playground-selected-evidence-summary selected-mech selected-code)
    :execution_interface
    (snippet-playground-object-label execution-interface)
    :transformation_unit
    (snippet-playground-object-label transformation-unit)
    :result_object (snippet-playground-object-label result-object)
    :failure_object (snippet-playground-object-label failure-object))
   :current-state current-state
   :visited-states visited-states
   :transition-trace transition-trace
   :evidence-trace evidence-trace
   :start-time start-time
   :end-time end-time
   :status status
   :failure-classification failure-classification
   :notes
   (list
    (list :label "Placement invariant"
          :detail
          (format nil
                  "Origin pane ~A determines right-hand-pane placement; pending pane ~A is replaced in place."
                  (or origin-pane-id "n/a")
                  (or pending-pane-id "n/a")))
    (list :label "Origin surface"
          :detail
          (format nil "~A via provider ~A"
                  (or origin-surface-kind "unknown")
                  (or provider-kind "unknown"))))))

(defun snippet-playground-empty-string-p (value)
  (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return #\Page)
                              (or value "")))))

(defun snippet-playground-trim-source (value)
  (string-trim '(#\Space #\Tab #\Newline #\Return #\Page)
               (or value "")))

(defun snippet-playground-string-contains-p (haystack needle)
  (and (stringp haystack)
       (stringp needle)
       (search needle haystack :test #'char-equal)))

(defun snippet-playground-replace-all (text target replacement)
  (let ((target-length (length target)))
    (with-output-to-string (stream)
      (loop with scan-start = 0
            for match = (search target text :test #'char= :start2 scan-start)
            do (if match
                   (progn
                     (write-string text stream :start scan-start :end match)
                     (write-string replacement stream)
                     (setf scan-start (+ match target-length)))
                   (progn
                     (write-string text stream :start scan-start)
                     (loop-finish)))))))

(defun decode-html-code-block-text (text)
  (let ((decoded text))
    (dolist (pair '(("&lt;" . "<")
                    ("&gt;" . ">")
                    ("&quot;" . "\"")
                    ("&#39;" . "'")
                    ("&#x27;" . "'")
                    ("&#10;" . "
")
                    ("&amp;" . "&")))
      (setf decoded
            (snippet-playground-replace-all decoded
                                            (car pair)
                                            (cdr pair))))
    decoded))

(defun source-line-number-at-offset (source offset)
  (1+ (count #\Newline source :end (min (length source)
                                        (max 0 offset)))))

(defun extract-html-code-blocks (source)
  (loop with blocks = '()
        with start-token = "<pre"
        with end-token = "</code></pre>"
        with scan-start = 0
        for index from 1
        for open-start = (search start-token source
                                 :test #'char-equal
                                 :start2 scan-start)
        while open-start
        for pre-end = (position #\> source :start open-start)
        for code-start = (and pre-end
                              (search "<code" source
                                      :test #'char-equal
                                      :start2 (1+ pre-end)))
        for code-end = (and code-start
                            (position #\> source :start code-start))
        for close-start = (and code-end
                               (search end-token source
                                       :test #'char-equal
                                       :start2 (1+ code-end)))
        while close-start
        for open-tag = (subseq source open-start (1+ code-end))
        for raw-source = (subseq source (1+ code-end) close-start)
        for decoded-source = (decode-html-code-block-text raw-source)
        do (push (list :index index
                       :line-number (source-line-number-at-offset source open-start)
                       :open-tag open-tag
                 :source (snippet-playground-trim-source decoded-source))
                 blocks)
           (setf scan-start (+ close-start (length end-token)))
        finally (return (nreverse blocks))))

(defun snippet-block-location-label (block)
  (or (getf block :location-label)
      (let ((line-number (getf block :line-number)))
        (if line-number
            (format nil "source line ~D" line-number)
            "source surface"))))

(defun snippet-playground-candidate-fedwiki-story-item-p (item)
  (member (hyperbook/fedwiki::item-type-of item)
          '(:code :mech :paragraph :markdown :reference)
          :test #'eq))

(defun extract-fedwiki-story-item-blocks (page)
  (loop with blocks = '()
        for item across (hyperbook/fedwiki::story-of page)
        for index from 1
        for item-type = (hyperbook/fedwiki::item-type-of item)
        for source = (snippet-playground-trim-source
                      (hyperbook/fedwiki::text-of item))
        when (and (snippet-playground-candidate-fedwiki-story-item-p item)
                  (not (snippet-playground-empty-string-p source)))
          do (push (list :index index
                         :line-number index
                         :location-label
                         (format nil "story item ~D (~A)"
                                 index
                                 (string-downcase (string item-type)))
                         :open-tag (format nil "fedwiki-~(~A~)" item-type)
                         :source source
                         :origin-surface-kind "fedwiki-page"
                         :provider-kind "fedwiki-v1")
                   blocks)
        finally (return (nreverse blocks))))

(defun snippet-playground-source-text-from-blocks (blocks)
  (with-output-to-string (stream)
    (loop for block in blocks
          for first = t then nil
          do (unless first
               (terpri stream)
               (terpri stream))
             (format stream ";; ~A~%~A"
                     (snippet-block-location-label block)
                     (getf block :source)))))

(defun snippet-playground-language-hint (open-tag)
  (cond
    ((snippet-playground-string-contains-p open-tag "javascript") :javascript)
    ((snippet-playground-string-contains-p open-tag "language-js") :javascript)
    ((snippet-playground-string-contains-p open-tag "python") :python)
    (t nil)))

(defun mech-operation-token (line)
  (first (remove-if #'snippet-playground-empty-string-p
                    (uiop:split-string (snippet-playground-trim-source line)
                                       :separator '(#\Space #\Tab)))))

(defun uppercase-operation-token-p (token)
  (and (stringp token)
       (> (length token) 0)
       (string= token (string-upcase token))
       (some #'alpha-char-p token)))

(defun recognized-mech-operation-p (token)
  (and (uppercase-operation-token-p token)
       (or (member token *snippet-playground-mech-ops* :test #'string=)
           (> (length token) 2))))

(defun parse-mech-step (block-index line-number raw-line)
  (let* ((trimmed (snippet-playground-trim-source raw-line))
         (parts (remove-if #'snippet-playground-empty-string-p
                           (uiop:split-string trimmed
                                              :separator '(#\Space #\Tab))))
         (operation (or (first parts) "UNKNOWN"))
         (arguments (rest parts)))
    (make-instance 'mech-snippet-step
                   :id (format nil "mech-step/~D/~D" block-index line-number)
                   :title (format nil "~A ~{~A~^ ~}" operation arguments)
                   :summary (format nil "Mech line ~D with op ~A."
                                    line-number
                                    operation)
                   :line-number line-number
                   :raw-line raw-line
                   :operation operation
                   :arguments arguments)))

(defun mech-snippet-findings (steps)
  (let ((ops (mapcar #'mech-snippet-step-operation-of steps))
        (findings '()))
    (when (member "CODE" ops :test #'string=)
      (push "Recognized CODE as the page-local execution seam." findings))
    (when (member "PREVIEW" ops :test #'string=)
      (push "Recognized PREVIEW as the publication seam after CODE." findings))
    (when (member "CLICK" ops :test #'string=)
      (push "Recognized CLICK as a precondition stage before CODE." findings))
    (when (member "NEIGHBORS" ops :test #'string=)
      (push "Recognized NEIGHBORS as state-shaping input before CODE." findings))
    (nreverse findings)))

(defun mech-snippet-preview-mode (steps)
  (let ((preview-step
          (find "PREVIEW"
                steps
                :key #'mech-snippet-step-operation-of
                :test #'string=)))
    (when preview-step
      (format nil "~{~A~^ ~}" (mech-snippet-step-arguments-of preview-step)))))

(defun mech-snippet-score (steps)
  (let* ((ops (mapcar #'mech-snippet-step-operation-of steps))
         (score (* 2 (length ops))))
    (when (member "CODE" ops :test #'string=)
      (incf score 5))
    (when (member "PREVIEW" ops :test #'string=)
      (incf score 4))
    (when (member "CLICK" ops :test #'string=)
      (incf score 2))
    (when (member "NEIGHBORS" ops :test #'string=)
      (incf score 2))
    score))

(defun maybe-make-mech-snippet (block)
  (let* ((source (getf block :source))
         (lines (remove-if #'snippet-playground-empty-string-p
                           (uiop:split-string source
                                              :separator '(#\Newline #\Return))))
         (steps '()))
    (dolist (line lines)
      (let ((token (mech-operation-token line)))
        (unless (recognized-mech-operation-p token)
          (return-from maybe-make-mech-snippet nil))
        (push (parse-mech-step (getf block :index)
                               (+ (getf block :line-number)
                                  (length steps))
                               line)
              steps)))
    (when steps
      (let* ((ordered-steps (nreverse steps))
             (score (mech-snippet-score ordered-steps)))
        (when (>= score 6)
          (make-instance 'mech-snippet
                         :id (format nil "mech-snippet/~D"
                                     (getf block :index))
                         :title (format nil "Mech snippet #~D"
                                        (getf block :index))
                         :summary
                         (format nil "Recognized Mech block at ~A."
                                 (snippet-block-location-label block))
                         :block-index (getf block :index)
                         :line-number (getf block :line-number)
                         :location-label (snippet-block-location-label block)
                         :source source
                         :steps ordered-steps
                         :preview-mode (mech-snippet-preview-mode ordered-steps)
                         :score score
                         :findings (mech-snippet-findings ordered-steps)))))))

(defun javascript-snippet-score (source language-hint)
  (let ((score 0))
    (when (eq language-hint :javascript)
      (incf score 8))
    (when (snippet-playground-string-contains-p source "export default")
      (incf score 4))
    (when (snippet-playground-string-contains-p source "function")
      (incf score 3))
    (when (snippet-playground-string-contains-p source "=>")
      (incf score 3))
    (when (snippet-playground-string-contains-p source "const ")
      (incf score 2))
    (when (snippet-playground-string-contains-p source "this.items")
      (incf score 4))
    (when (snippet-playground-string-contains-p source "state.items")
      (incf score 4))
    (when (snippet-playground-string-contains-p source ".map(")
      (incf score 1))
    score))

(defun python-snippet-score (source language-hint)
  (let ((score 0))
    (when (eq language-hint :python)
      (incf score 8))
    (when (snippet-playground-string-contains-p source "def ")
      (incf score 3))
    (when (snippet-playground-string-contains-p source "import ")
      (incf score 2))
    score))

(defun detect-code-language (source open-tag)
  (let* ((hint (snippet-playground-language-hint open-tag))
         (js-score (javascript-snippet-score source hint))
         (python-score (python-snippet-score source hint)))
    (cond
      ((> js-score 0)
       (values :javascript js-score))
      ((> python-score 0)
       (values :python python-score))
      (t
       (values :unknown 0)))))

(defun code-output-path (source)
  (cond
    ((or (snippet-playground-string-contains-p source "this.items")
         (snippet-playground-string-contains-p source "state.items"))
     "state.items")
    ((or (snippet-playground-string-contains-p source "this.aspect")
         (snippet-playground-string-contains-p source "state.aspect"))
     "state.aspect")
    (t
     nil)))

(defun javascript-translation-mode (source output-path)
  (cond
    ((and (string= (or output-path "") "state.items")
          (snippet-playground-string-contains-p source "Quick Brown Fox")
          (snippet-playground-string-contains-p source ".split")
          (snippet-playground-string-contains-p source ".map"))
     :quick-brown-fox-state-items)
    ((string= (or output-path "") "state.items")
     :state-items-scaffold)
    (t
     :generic-scaffold)))

(defun code-snippet-findings (language output-path source)
  (let ((findings '()))
    (when (eq language :javascript)
      (push "Recognized JavaScript as the executable code language." findings))
    (when (string= (or output-path "") "state.items")
      (push "Recognized state.items as the publication handoff from CODE to PREVIEW." findings))
    (when (snippet-playground-string-contains-p source "export default")
      (push "Recognized an export default entrypoint in the JavaScript block." findings))
    (nreverse findings)))

(defun code-language-display-name (language)
  (case language
    (:javascript "JavaScript")
    (:python "Python")
    (:unknown "Unknown")
    (t
     (string-capitalize (string-downcase (string language))))))

(defun make-code-snippet-object (block language score)
  (let* ((source (getf block :source))
         (output-path (code-output-path source))
         (translation-mode
           (if (eq language :javascript)
               (javascript-translation-mode source output-path)
               :unsupported)))
    (make-instance (if (eq language :javascript)
                       'javascript-code-snippet
                       'unsupported-code-snippet)
                   :id (format nil "code-snippet/~D" (getf block :index))
                   :title (format nil "~A code snippet #~D"
                                  (code-language-display-name language)
                                  (getf block :index))
                   :summary
                   (format nil "Recognized ~A code block at ~A."
                           (string-downcase (string language))
                           (snippet-block-location-label block))
                   :block-index (getf block :index)
                   :line-number (getf block :line-number)
                   :location-label (snippet-block-location-label block)
                   :source source
                   :language language
                   :output-path output-path
                   :translation-mode translation-mode
                   :score score
                   :findings (code-snippet-findings language output-path source))))

(defun recognized-code-snippets-from-blocks (blocks)
  (loop for block in blocks
        unless (maybe-make-mech-snippet block)
          append
            (multiple-value-bind (language score)
                (detect-code-language (getf block :source)
                                      (getf block :open-tag))
              (cond
                ((eq language :javascript)
                 (list (make-code-snippet-object block language score)))
                ((and (not (eq language :unknown))
                      (> score 0))
                 (list (make-code-snippet-object block language score)))
                (t
                 nil)))))

(defun select-best-snippet (snippets score-reader)
  (car (sort (copy-list snippets) #'>
             :key score-reader)))

(defun snippet-playground-status-label (status)
  (ecase status
    (:ready "ready")
    (:unsupported "unsupported language")
    (:malformed "malformed or incomplete")))

(defun snippet-playground-session-ready-p (session)
  (eq (snippet-playground-session-status-of session) :ready))

(defun session-title-label (context-object source-pathname)
  (or (ignore-errors (title-of context-object))
      (and source-pathname
           (file-namestring source-pathname))
      "Source"))

(defun generic-state-items-scaffold (session code)
  (declare (ignore session))
  (with-output-to-string (stream)
    (format stream ";; Translation scaffold for the recognized JavaScript CODE block.~%")
    (format stream "(let* ((session *)~%")
    (format stream "       (original-javascript ~S))~%" (code-snippet-source-of code))
    (format stream "  (declare (ignore original-javascript))~%")
    (format stream "  ;; TODO: translate the JavaScript transformation into Lisp.~%")
    (format stream "  (setf (hyperdoc::snippet-playground-session-derived-items-of session)~%")
    (format stream "        (list (list :type \"draft\"~%")
    (format stream "                    :note \"TODO: replace this placeholder with translated state.items output.\")))~%")
    (format stream "  (hyperdoc::snippet-playground-session-derived-items-of session))~%")))

(defun quick-brown-fox-scaffold ()
  (with-output-to-string (stream)
    (write-line ";; Lisp scaffold for the Quick Brown Fox state.items transformation." stream)
    (write-line "(let* ((session *)" stream)
    (write-line "       (text \"Quick Brown Fox\")" stream)
    (write-line "       (edges" stream)
    (write-line "         (loop for index from 0 below (length text)" stream)
    (write-line "               for current = (string (char text index))" stream)
    (write-line "               for next = (if (< (1+ index) (length text))" stream)
    (write-line "                              (string (char text (1+ index)))" stream)
    (write-line "                              \".\")" stream)
    (write-line "               collect (format nil \"\\\"~A\\\"->\\\"~A\\\";\" current next)))" stream)
    (write-line "       (graphviz-text (format nil \"digraph {~%~{~A~%~}}\" edges))" stream)
    (write-line "       (items (list (list :type \"graphviz\" :text graphviz-text))))" stream)
    (write-line "  (setf (hyperdoc::snippet-playground-session-derived-items-of session) items)" stream)
    (write-line "  items)" stream)))

(defun snippet-playground-lisp-scaffold (session code)
  (case (code-snippet-translation-mode-of code)
    (:quick-brown-fox-state-items
     (quick-brown-fox-scaffold))
    (:state-items-scaffold
     (generic-state-items-scaffold session code))
    (t
     (with-output-to-string (stream)
       (format stream ";; No concrete Lisp scaffold is available for this code block yet.~%")
       (format stream "(values :unsupported ~S)~%"
               (code-snippet-language-of code))))))

(defun snippet-execution-interface-output-channel (handoff-path)
  (cond
    ((string= (or handoff-path "") "state.items")
     "items stream")
    ((string= (or handoff-path "") "state.aspect")
     "aspect channel")
    ((snippet-playground-empty-string-p handoff-path)
     "unresolved output channel")
    (t
     (format nil "channel ~A" handoff-path))))

(defun snippet-execution-interface-findings (mech code handoff-path preview-mode)
  (declare (ignore mech))
  (let ((findings '()))
    (when handoff-path
      (push (format nil "Inferred execution handoff through ~A." handoff-path)
            findings))
    (when preview-mode
      (push (format nil "Preview mode remains ~A on the Mech side."
                    preview-mode)
            findings))
    (when (and handoff-path
               (string= handoff-path "state.items"))
      (push "state.items is the current execution bridge between CODE and PREVIEW."
            findings))
    (when (and code
               (eq (code-snippet-language-of code) :javascript))
      (push "JavaScript is the concrete Lefty implementation for this slice."
            findings))
    (nreverse findings)))

(defun make-snippet-execution-interface (mech code)
  (let* ((handoff-path (or (and code (code-snippet-output-path-of code))
                           "unresolved"))
         (preview-mode (or (and mech (mech-snippet-preview-mode-of mech))
                           "items"))
         (output-channel (snippet-execution-interface-output-channel handoff-path)))
    (make-instance
     'snippet-execution-interface
     :id (format nil "snippet-execution-interface/~A/~A"
                 (or (and mech (mech-snippet-block-index-of mech)) "mech")
                 (or (and code (code-snippet-block-index-of code)) "code"))
     :title (format nil "Execution interface: ~A" handoff-path)
     :summary
     (format nil "Operational handoff from CODE to PREVIEW through ~A." handoff-path)
     :handoff-path handoff-path
     :preview-mode preview-mode
     :output-channel output-channel
     :input-role-name "current Mech state"
     :output-role-name (format nil "preview ~A" preview-mode)
     :findings
     (snippet-execution-interface-findings mech code handoff-path preview-mode))))

(defun snippet-lefty-projection-findings (origin-surface-kind provider-kind)
  (list (format nil "Lefty remains anchored in ~A via provider ~A."
                (or origin-surface-kind "unknown")
                (or provider-kind "unknown"))))

(defun make-snippet-lefty-projection
    (mech code &key origin-surface-kind provider-kind source-label
       context-view-title)
  (make-instance
   'snippet-lefty-projection
   :id (format nil "snippet-lefty/~A/~A"
               (or origin-surface-kind "surface")
               (or source-label "origin"))
   :title (format nil "Lefty projection: ~A"
                  (or source-label "origin"))
   :summary
   (format nil "Concrete source-side projection binding ~A with ~A."
           (and mech (title-of mech))
           (and code (title-of code)))
   :origin-surface-kind origin-surface-kind
   :provider-kind provider-kind
   :origin-label source-label
   :context-view-title context-view-title
   :mech-snippet mech
   :code-snippet code
   :findings
   (snippet-lefty-projection-findings origin-surface-kind provider-kind)))

(defun snippet-rita-projection-findings (execution-interface scaffold-source)
  (let ((findings '()))
    (when execution-interface
      (push (format nil "Rita rewrites the slice against execution interface ~A."
                    (snippet-execution-interface-handoff-path-of
                     execution-interface))
            findings))
    (when (and scaffold-source
               (not (snippet-playground-empty-string-p scaffold-source)))
      (push "Rita carries an inspectable Lisp scaffold for the current slice."
            findings))
    (nreverse findings)))

(defun make-snippet-rita-projection (mech code execution-interface)
  (let ((scaffold-source (and code
                              (snippet-playground-lisp-scaffold nil code))))
    (make-instance
     'snippet-rita-projection
     :id (format nil "snippet-rita/~A/~A"
                 (or (and mech (mech-snippet-block-index-of mech)) "mech")
                 (or (and code (code-snippet-block-index-of code)) "code"))
     :title "Rita projection"
     :summary
     (format nil "Inspectable Lisp-side rewrite around ~A."
             (and execution-interface
                  (snippet-execution-interface-handoff-path-of
                   execution-interface)))
     :mech-snippet mech
     :execution-interface execution-interface
     :lisp-scaffold-source scaffold-source
     :findings
     (snippet-rita-projection-findings execution-interface scaffold-source))))

(defun snippet-transformation-normal-form (code execution-interface)
  (let ((translation-mode (and code (code-snippet-translation-mode-of code))))
    (cond
      ((eq translation-mode :quick-brown-fox-state-items)
       (list
        :input-kind :text
        :input-shape "text string"
        :operation-kind :adjacency-extraction
        :operation-summary
        "Extract adjacent character pairs from text and publish them as graph-like items."
        :output-kind :items
        :output-shape "items stream carrying graph-like structure"))
      ((and execution-interface
            (string= (snippet-execution-interface-handoff-path-of execution-interface)
                     "state.items"))
       (list
        :input-kind :mech-state
        :input-shape "current Mech state"
        :operation-kind :state-items-transformation
        :operation-summary
        "Transform the current Mech state into preview items through the inferred interface."
        :output-kind :items
        :output-shape "items stream prepared for preview"))
      (t
       (list
        :input-kind :snippet-state
        :input-shape "current snippet execution state"
        :operation-kind :code-driven-transformation
        :operation-summary
        "Execute the selected CODE block and publish its result through the inferred interface."
        :output-kind :preview-output
        :output-shape
        (or (and execution-interface
                 (snippet-execution-interface-output-channel-of
                  execution-interface))
            "preview output"))))))

(defun snippet-transformation-unit-summary-text (normal-form execution-interface)
  (format nil "Transformation unit normal form: ~A -> ~A -> ~A via ~A."
          (getf normal-form :input-shape)
          (snippet-playground-display-value
           (getf normal-form :operation-kind))
          (getf normal-form :output-shape)
          (and execution-interface
               (snippet-execution-interface-handoff-path-of execution-interface))))

(defun snippet-transformation-unit-findings (execution-interface normal-form)
  (let ((findings '()))
    (when execution-interface
      (push (format nil "The transformation unit stores its normal form around execution interface ~A."
                    (snippet-execution-interface-handoff-path-of
                     execution-interface))
            findings))
    (when normal-form
      (push (format nil "Normal form captures ~A as a language-neutral operation."
                    (snippet-playground-display-value
                     (getf normal-form :operation-kind)))
            findings))
    (nreverse findings)))

(defun make-snippet-transformation-unit
    (mech code execution-interface lefty-projection rita-projection)
  (let* ((normal-form (snippet-transformation-normal-form
                       code
                       execution-interface))
         (preview-mode
           (and execution-interface
                (snippet-execution-interface-preview-mode-of
                 execution-interface)))
         (input-kind (getf normal-form :input-kind))
         (input-shape (getf normal-form :input-shape))
         (operation-kind (getf normal-form :operation-kind))
         (operation-summary (getf normal-form :operation-summary))
         (output-kind (getf normal-form :output-kind))
         (output-shape (getf normal-form :output-shape)))
    (make-instance
     'snippet-transformation-unit
     :id (format nil "snippet-transformation-unit/~A/~A"
                 (or (and mech (mech-snippet-block-index-of mech)) "mech")
                 (or (and code (code-snippet-block-index-of code)) "code"))
     :title (format nil "Transformation unit: ~A"
                    (snippet-playground-display-value operation-kind))
     :summary (snippet-transformation-unit-summary-text
               normal-form
               execution-interface)
     :mech-snippet mech
     :code-snippet code
     :execution-interface execution-interface
     :preview-mode preview-mode
     :input-kind input-kind
     :input-shape input-shape
     :operation-kind operation-kind
     :operation-summary operation-summary
     :output-kind output-kind
     :output-shape output-shape
     :lefty-projection lefty-projection
     :rita-projection rita-projection
     :findings
     (snippet-transformation-unit-findings
      execution-interface
      normal-form))))

(defun snippet-comparison-region-source
    (content-key mech code lisp-source)
  (ecase content-key
    (shared-mech
     (if mech
         (mech-snippet-source-of mech)
         "No Mech snippet is available for this session."))
    (javascript-code
     (if code
         (code-snippet-source-of code)
         "No JavaScript snippet is available for this session."))
    (lisp-code
     (if (and (stringp lisp-source)
              (> (length lisp-source) 0))
         lisp-source
         "No Lisp scaffold is available for this session."))))

(defun make-snippet-comparison-region
    (region-id placement content-key title mech code lisp-source)
  (make-instance
   'snippet-comparison-region
   :id (format nil "snippet-comparison-region/~A" region-id)
   :title title
   :summary (format nil "~A region of the snippet comparison surface." title)
   :placement placement
   :content-key content-key
   :source-text (snippet-comparison-region-source
                 content-key
                 mech
                 code
                 lisp-source)
   :findings
   (list
    (format nil
            "Region ~A renders ~A on the comparison surface."
            title
            (string-downcase (string content-key))))))

(defun snippet-comparison-surface-findings (execution-interface)
  (let ((findings '("Comparison surface renders JavaScript left, shared Mech center, and Lisp right.")))
    (when execution-interface
      (push (format nil
                    "Execution interface ~A remains visible in the compact transformation-unit block."
                    (snippet-execution-interface-handoff-path-of
                     execution-interface))
            findings))
    (nreverse findings)))

(defun make-snippet-comparison-surface
    (&key status source-label mech code lisp-source execution-interface
       transformation-unit origin-pane-id pending-pane-id
       failure-classification)
  (let* ((left-region
           (make-snippet-comparison-region
            "left-code-region"
            :left
            'javascript-code
            "JavaScript"
            mech
            code
            lisp-source))
         (center-region
           (make-snippet-comparison-region
            "shared-mech-region"
            :center
            'shared-mech
            "Mech"
            mech
            code
            lisp-source))
         (right-region
           (make-snippet-comparison-region
            "right-code-region"
            :right
            'lisp-code
            "Lisp"
            mech
            code
            lisp-source)))
    (make-instance
     'snippet-comparison-surface
     :id (format nil "snippet-comparison-surface/~A"
                 (or source-label "surface"))
     :title "Snippet comparison"
     :summary
     "Three-region comparison surface with JavaScript, shared Mech, and Lisp."
     :layout-spec *snippet-comparison-layout-spec*
     :regions (list left-region center-region right-region)
     :left-code-region left-region
     :shared-mech-region center-region
     :right-code-region right-region
     :execution-interface execution-interface
     :transformation-unit transformation-unit
     :lifecycle-run
     (make-snippet-comparison-surface-lifecycle-run
      :status status
      :source-label source-label
      :origin-pane-id origin-pane-id
      :pending-pane-id pending-pane-id
      :failure-classification failure-classification)
     :findings
     (snippet-comparison-surface-findings execution-interface))))

(defun snippet-playground-crosswalk (mech code)
  (let* ((preview-mode (or (mech-snippet-preview-mode-of mech)
                           "items"))
         (output-path (or (code-snippet-output-path-of code)
                          "state.items (expected)"))
         (precondition
           (cond
             ((or (find "CLICK"
                        (mech-snippet-steps-of mech)
                        :key #'mech-snippet-step-operation-of
                        :test #'string=)
                  (find "NEIGHBORS"
                        (mech-snippet-steps-of mech)
                        :key #'mech-snippet-step-operation-of
                        :test #'string=))
              "CLICK / NEIGHBORS from the selected Mech snippet")
             (t
              "CLICK / NEIGHBORS next remains the upstream precondition before CODE."))))
    (list
     (list :stage "Precondition"
           :mech precondition
           :javascript "JavaScript receives the current Mech state proxy."
           :lisp "The session object stands in for that handoff during translation."
           :detail "This slice does not reimplement the broader Mech traversal stack.")
     (list :stage "Execution seam"
           :mech "CODE"
           :javascript "Execute page-local JavaScript against the current Mech state."
           :lisp "Evaluate the scaffold with * bound to the snippet-playground session."
           :detail "This keeps execution inspectable in the existing Lisp-first stepper/debug path.")
     (list :stage "Output path"
           :mech (format nil "PREVIEW ~A" preview-mode)
           :javascript output-path
           :lisp "hyperdoc::snippet-playground-session-derived-items-of"
           :detail "The scaffold stores the translated publication payload on the session.")
     (list :stage "Publication"
           :mech (format nil "PREVIEW ~A" preview-mode)
           :javascript "Preview consumes the prepared state.items payload."
           :lisp "Inspect the derived items directly or step through their construction."
           :detail "The narrow slice stays on the state.items seam rather than implementing a full Mech runtime."))))

(defun snippet-playground-findings
    (selected-mech selected-code execution-interface transformation-unit)
  (let ((findings '()))
    (unless selected-mech
      (push "No Mech snippet was recognized in the current origin surface." findings))
    (unless selected-code
      (push "No supported code snippet was recognized in the current origin surface." findings))
    (when (and selected-code
               (typep selected-code 'unsupported-code-snippet))
      (push (format nil "Recognized ~A, but only JavaScript is supported in this slice."
                    (string-downcase (string (code-snippet-language-of selected-code))))
            findings))
    (when execution-interface
      (push (format nil "Execution interface ~A is now the primary semantic bridge."
                    (snippet-execution-interface-handoff-path-of
                     execution-interface))
            findings))
    (when transformation-unit
      (push "Constructed a snippet transformation unit as the durable inspectable artifact."
            findings))
    (nreverse findings)))

(defun snippet-playground-evidence-notes
    (selected-mech selected-code execution-interface)
  (let ((notes '()))
    (when selected-mech
      (push (format nil "Selected Mech block #~D at ~A."
                    (mech-snippet-block-index-of selected-mech)
                    (or (snippet-location-label-of selected-mech)
                        (format nil "line ~D"
                                (mech-snippet-line-number-of selected-mech))))
            notes))
    (when selected-code
      (push (format nil "Selected ~A block #~D at ~A."
                    (string-downcase (string (code-snippet-language-of selected-code)))
                    (code-snippet-block-index-of selected-code)
                    (or (snippet-location-label-of selected-code)
                        (format nil "line ~D"
                                (code-snippet-line-number-of selected-code))))
            notes))
    (when execution-interface
      (push (format nil "Bound the selected evidence through execution interface ~A."
                    (snippet-execution-interface-handoff-path-of
                     execution-interface))
            notes))
    (nreverse notes)))

(defun mech-snippet-short-label (snippet)
  (if snippet
      (format nil "Mech #~D" (mech-snippet-block-index-of snippet))
      "Mech"))

(defun code-snippet-short-label (snippet)
  (if snippet
      (format nil "~A #~D"
              (code-language-display-name
               (code-snippet-language-of snippet))
              (code-snippet-block-index-of snippet))
      "Code"))

(defun snippet-playground-session-summary
    (status selected-mech selected-code execution-interface transformation-unit)
  (cond
    ((and transformation-unit execution-interface
          selected-mech selected-code)
     (format nil
             "Constructed transformation unit from ~A and ~A."
             (mech-snippet-short-label selected-mech)
             (code-snippet-short-label selected-code)))
    ((eq status :unsupported)
     "Unsupported snippet input: only JavaScript currently gets a concrete Rita scaffold.")
    (t
     "Malformed or incomplete snippet input: the current origin surface does not expose enough evidence to construct a transformation unit yet.")))

(defun snippet-playground-session-status (selected-mech selected-code)
  (cond
    ((and selected-mech
          selected-code
          (typep selected-code 'javascript-code-snippet))
     :ready)
    ((and selected-mech selected-code)
     :unsupported)
    (t
     :malformed)))

(defun snippet-playground-transition-entry (from-state to-state trigger detail
                                            &key guard)
  (list :timestamp (snippet-playground-current-millis)
        :kind :transition
        :transition-id
        (format nil "~(~A~)->~(~A~)/~(~A~)"
                from-state
                to-state
                trigger)
        :from-state from-state
        :to-state to-state
        :detail (if guard
                    (format nil "~A Guard: ~A." detail guard)
                    detail)))

(defun snippet-playground-evidence-entry (state detail evidence)
  (list :timestamp (snippet-playground-current-millis)
        :kind :evidence
        :from-state state
        :to-state state
        :detail detail
        :evidence evidence))

(defun snippet-playground-session-id (origin-surface-kind source-label source-pathname)
  (format nil "snippet-playground/~A/~A"
          (or origin-surface-kind "surface")
          (or (and source-pathname
                   (namestring source-pathname))
              source-label
              "session")))

(defun snippet-playground-session-title
    (context-object source-label source-pathname)
  (format nil "Snippet playground: ~A"
          (or source-label
              (session-title-label context-object source-pathname))))

(defun make-snippet-playground-result-from-blocks
    (&key context-object context-view-title source-pathname source-text
       blocks origin-surface-kind provider-kind source-label)
  (let* ((resolved-source-label
           (or source-label
               (ignore-errors (title-of context-object))
               (and source-pathname
                    (file-namestring source-pathname))
               "Source"))
         (origin-pane-id (pending-evaluation-origin-pane-id))
         (pending-pane-id (pending-evaluation-pane-id))
         (start-time (snippet-playground-current-millis))
         (current-state :available)
         (visited-states (list :available))
         (transition-trace '())
         (evidence-trace '())
         (recognized-mech-snippets nil)
         (recognized-code-snippets nil)
         (selected-mech nil)
         (selected-code nil)
         (execution-interface nil)
         (transformation-unit nil)
         (comparison-surface nil)
         (lefty-projection nil)
         (rita-projection nil)
         (result-object nil)
         (failure-object nil)
         (failure-classification nil))
    (labels
        ((advance (to-state trigger detail &key guard progress-phase progress-message)
           (push (snippet-playground-transition-entry
                  current-state
                  to-state
                  trigger
                  detail
                  :guard guard)
                 transition-trace)
           (setf current-state to-state)
           (unless (equal (car visited-states) to-state)
             (push to-state visited-states))
           (when progress-message
             (snippet-playground-report-progress
              progress-phase
              progress-message
              :detail detail)))
         (note-evidence (state detail evidence)
           (push (snippet-playground-evidence-entry
                  state
                  detail
                  evidence)
                 evidence-trace))
         (make-result (status &key failure-classification)
           (let* ((title (snippet-playground-session-title
                          context-object
                          resolved-source-label
                          source-pathname))
                  (summary (snippet-playground-session-summary
                            status
                            selected-mech
                            selected-code
                            execution-interface
                            transformation-unit))
                  (comparison
                    (or comparison-surface
                        (when (or selected-mech
                                  selected-code
                                  transformation-unit)
                          (setf comparison-surface
                                (make-snippet-comparison-surface
                                 :status status
                                 :source-label resolved-source-label
                                 :mech selected-mech
                                 :code selected-code
                                 :lisp-source
                                 (and rita-projection
                                      (snippet-rita-projection-lisp-scaffold-source-of
                                       rita-projection))
                                 :execution-interface execution-interface
                                 :transformation-unit transformation-unit
                                 :origin-pane-id origin-pane-id
                                 :pending-pane-id pending-pane-id
                                 :failure-classification failure-classification)))))
                  (class (if (eq status :ready)
                             'snippet-playground-session
                             'snippet-playground-failure))
                  (initargs
                    (list
                     :id (snippet-playground-session-id
                          origin-surface-kind
                          resolved-source-label
                          source-pathname)
                     :title title
                     :summary summary
                     :status status
                     :context-object context-object
                     :context-view-title context-view-title
                     :origin-surface-kind origin-surface-kind
                     :provider-kind provider-kind
                     :source-label resolved-source-label
                     :source-pathname source-pathname
                     :source-text (or source-text "")
                     :source-block-count (length blocks)
                     :recognized-mech-snippets recognized-mech-snippets
                     :recognized-code-snippets recognized-code-snippets
                     :selected-mech selected-mech
                     :selected-code selected-code
                     :execution-interface execution-interface
                     :transformation-unit transformation-unit
                     :comparison-surface comparison
                     :crosswalk (and selected-mech
                                     selected-code
                                     (snippet-playground-crosswalk
                                      selected-mech
                                      selected-code))
                     :pairing-notes (snippet-playground-evidence-notes
                                     selected-mech
                                     selected-code
                                     execution-interface)
                     :lisp-scaffold-source
                     (and rita-projection
                          (snippet-rita-projection-lisp-scaffold-source-of
                           rita-projection))
                     :findings (snippet-playground-findings
                                selected-mech
                                selected-code
                                execution-interface
                                transformation-unit)))
                  (object
                    (apply #'make-instance
                           class
                           (if (eq class 'snippet-playground-failure)
                               (append initargs
                                       (list :failure-classification
                                             failure-classification))
                               initargs))))
             (let ((run
                     (make-snippet-playground-state-machine-run
                      :current-state current-state
                      :visited-states (nreverse visited-states)
                      :transition-trace (nreverse transition-trace)
                      :evidence-trace (nreverse evidence-trace)
                      :start-time start-time
                      :end-time (snippet-playground-current-millis)
                      :status (if (eq status :ready) :finished :failed)
                      :failure-classification failure-classification
                      :source-label resolved-source-label
                      :origin-pane-id origin-pane-id
                      :origin-surface-kind origin-surface-kind
                      :provider-kind provider-kind
                      :pending-pane-id pending-pane-id
                      :recognized-mech-snippets recognized-mech-snippets
                      :recognized-code-snippets recognized-code-snippets
                      :selected-mech selected-mech
                      :selected-code selected-code
                      :execution-interface execution-interface
                      :transformation-unit transformation-unit
                      :result-object (and (eq status :ready) object)
                      :failure-object (unless (eq status :ready) object))))
               (setf (snippet-playground-session-state-machine-run-of object)
                     run))
             object)))
      (handler-case
          (progn
            (advance :invoked
                     :snippet-click
                     "Snippet capability invoked from the origin pane.")
            (advance :pending
                     :open-pending-pane
                     (format nil
                             "Pending pane ~A opened to the right of origin pane ~A."
                             (or pending-pane-id "n/a")
                             (or origin-pane-id "n/a")))
            (note-evidence
             :pending
             "Captured origin and pending-pane placement context."
             (list :origin_pane_id origin-pane-id
                   :origin_surface_kind origin-surface-kind
                   :provider_kind provider-kind
                   :pending_pane_id pending-pane-id))
            (advance :collecting-input
                     :pending-pane-opened
                     (format nil "Collecting snippet input from ~A."
                             resolved-source-label)
                     :progress-phase :collecting-input
                     :progress-message "Collecting input...")
            (unless blocks
              (setf failure-classification :no-input)
              (advance :failed
                       :input-collection-failed
                       "No snippet candidates could be extracted from the origin surface."
                       :progress-phase :failed
                       :progress-message "Failed")
              (setf failure-object
                    (make-result :malformed
                                 :failure-classification failure-classification))
              (return-from make-snippet-playground-result-from-blocks
                failure-object))
            (note-evidence
             :collecting-input
             "Collected provider-specific snippet candidates."
             (list :source_block_count (length blocks)
                   :origin_surface_kind origin-surface-kind
                   :provider_kind provider-kind))
            (advance :recognizing
                     :input-extracted
                     (format nil "Recognizing snippet candidates from ~D collected inputs."
                             (length blocks))
                     :guard :input-extracted
                     :progress-phase :recognizing
                     :progress-message "Recognizing snippets...")
            (setf recognized-mech-snippets
                  (remove nil
                          (mapcar #'maybe-make-mech-snippet blocks)))
            (setf recognized-code-snippets
                  (recognized-code-snippets-from-blocks blocks))
            (note-evidence
             :recognizing
             "Recognition finished."
             (list
              :recognized_mech_snippets
              (snippet-playground-snippet-labels recognized-mech-snippets)
              :recognized_code_snippets
              (snippet-playground-snippet-labels recognized-code-snippets)))
            (unless (or recognized-mech-snippets
                        recognized-code-snippets)
              (setf failure-classification :no-candidates)
              (advance :failed
                       :recognition-failed
                       "No recognizable Mech or code snippets were found."
                       :progress-phase :failed
                       :progress-message "Failed")
              (setf failure-object
                    (make-result :malformed
                                 :failure-classification failure-classification))
              (return-from make-snippet-playground-result-from-blocks
                failure-object))
            (advance :pairing
                     :snippets-recognized
                     "Selecting evidential Mech/code inputs from the recognized candidates."
                     :guard :candidates-found
                     :progress-phase :pairing
                     :progress-message "Selecting evidence...")
            (setf selected-mech
                  (select-best-snippet recognized-mech-snippets
                                       #'mech-snippet-score-of))
            (setf selected-code
                  (select-best-snippet recognized-code-snippets
                                       #'code-snippet-score-of))
            (note-evidence
             :pairing
             "Selected evidential Mech/code inputs."
             (snippet-playground-selected-evidence-summary
              selected-mech
              selected-code))
            (unless (and selected-mech selected-code)
              (setf failure-classification :pairing-failed)
              (advance :failed
                       :pairing-failed
                       "The collected snippets did not yield enough evidence to construct a transformation unit."
                       :progress-phase :failed
                       :progress-message "Failed")
              (setf failure-object
                    (make-result :malformed
                                 :failure-classification failure-classification))
              (return-from make-snippet-playground-result-from-blocks
                failure-object))
            (advance :building-session
                     :pair-selected
                     "Building the snippet-playground session object."
                     :guard :valid-pair
                     :progress-phase :building-session
                     :progress-message "Building session...")
            (setf execution-interface
                  (make-snippet-execution-interface selected-mech selected-code))
            (setf lefty-projection
                  (make-snippet-lefty-projection
                   selected-mech
                   selected-code
                   :origin-surface-kind origin-surface-kind
                   :provider-kind provider-kind
                   :source-label resolved-source-label
                   :context-view-title context-view-title))
            (setf rita-projection
                  (make-snippet-rita-projection
                   selected-mech
                   selected-code
                   execution-interface))
            (setf transformation-unit
                  (make-snippet-transformation-unit
                   selected-mech
                   selected-code
                   execution-interface
                   lefty-projection
                   rita-projection))
            (note-evidence
             :building-session
             "Constructed execution interface and transformation unit."
             (list
              :execution_interface
              (snippet-playground-object-label execution-interface)
              :transformation_unit
              (snippet-playground-object-label transformation-unit)
              :handoff_path
              (and execution-interface
                   (snippet-execution-interface-handoff-path-of
                    execution-interface))
              :preview_mode
              (and execution-interface
                   (snippet-execution-interface-preview-mode-of
                    execution-interface))))
            (if (typep selected-code 'javascript-code-snippet)
                (progn
                  (advance :ready
                           :session-built
                           "Built a ready snippet-playground session around the constructed transformation unit.")
                  (setf result-object
                        (make-result :ready)))
                (progn
                  (setf failure-classification :unsupported-language)
                  (advance :failed
                           :session-build-failed
                           "Recognized the evidential inputs, but only JavaScript is supported in this slice."
                           :progress-phase :failed
                           :progress-message "Failed")
                  (setf failure-object
                        (make-result :unsupported
                                     :failure-classification
                                     failure-classification))))
            (or result-object failure-object))
        (error (condition)
          (setf failure-classification :session-build-error)
          (unless (eq current-state :failed)
            (advance :failed
                     :session-build-failed
                     (format nil "Snippet playground build failed: ~A" condition)
                     :progress-phase :failed
                     :progress-message "Failed"))
          (note-evidence
           :failed
           "Caught a condition while building the snippet-playground result."
           (princ-to-string condition))
          (setf failure-object
                (make-result :malformed
                             :failure-classification failure-classification))
          failure-object)))))

(defun make-snippet-playground-session-from-source
    (&key context-object context-view-title source-pathname source-text)
  (let ((trimmed-source (or source-text "")))
    (make-snippet-playground-result-from-blocks
     :context-object context-object
     :context-view-title context-view-title
     :source-pathname source-pathname
     :source-text trimmed-source
     :blocks (extract-html-code-blocks trimmed-source)
     :origin-surface-kind "html-source"
     :provider-kind "source-v1")))

(defun make-snippet-playground-session-from-fedwiki-page
    (&key context-object context-view-title page)
  (when page
    (hyperbook/fedwiki::load-page page))
  (let ((blocks (if page
                    (extract-fedwiki-story-item-blocks page)
                    nil)))
    (make-snippet-playground-result-from-blocks
     :context-object (or context-object page)
     :context-view-title context-view-title
     :source-text (snippet-playground-source-text-from-blocks blocks)
     :blocks blocks
     :origin-surface-kind "fedwiki-page"
     :provider-kind "fedwiki-v1"
     :source-label (and page (title-of page)))))

(defun make-snippet-playground-session-target
    (&key context-object context-view-title source-pathname fedwiki-page
       provider-kind origin-surface-kind)
  (cond
    ((or (string= (or provider-kind "") "fedwiki-v1")
         (string= (or origin-surface-kind "") "fedwiki-page")
         fedwiki-page)
     (make-snippet-playground-session-from-fedwiki-page
      :context-object context-object
      :context-view-title context-view-title
      :page fedwiki-page))
    ((and source-pathname
          (probe-file source-pathname))
     (make-snippet-playground-session-from-source
      :context-object context-object
      :context-view-title context-view-title
      :source-pathname source-pathname
      :source-text (uiop:read-file-string source-pathname)))
    (t
     (make-snippet-playground-session-from-source
      :context-object context-object
      :context-view-title context-view-title
      :source-pathname source-pathname
      :source-text ""))))

(defun snippet-playground-run-scaffold (session)
  (let ((source (snippet-playground-session-lisp-scaffold-source-of session)))
    (if (snippet-playground-empty-string-p source)
        (make-instance 'snippet-playground-failure
                       :id (id-of session)
                       :title (title-of session)
                       :summary (summary-of session)
                       :status :malformed
                       :context-object
                       (snippet-playground-session-context-object-of session)
                       :context-view-title
                       (snippet-playground-session-context-view-title-of session)
                       :origin-surface-kind
                       (snippet-playground-session-origin-surface-kind-of session)
                       :provider-kind
                       (snippet-playground-session-provider-kind-of session)
                       :source-label
                       (snippet-playground-session-source-label-of session)
                       :source-pathname
                       (snippet-playground-session-source-pathname-of session)
                       :source-text
                       (snippet-playground-session-source-text-of session)
                       :source-block-count
                       (snippet-playground-session-source-block-count-of session)
                       :recognized-mech-snippets
                       (snippet-playground-session-recognized-mech-snippets-of session)
                       :recognized-code-snippets
                       (snippet-playground-session-recognized-code-snippets-of session)
                       :selected-mech
                       (snippet-playground-session-selected-mech-of session)
                       :selected-code
                       (snippet-playground-session-selected-code-of session)
                       :execution-interface
                       (snippet-playground-session-execution-interface-of session)
                       :transformation-unit
                       (snippet-playground-session-transformation-unit-of
                        session)
                       :comparison-surface
                       (snippet-playground-session-comparison-surface-of
                        session)
                       :crosswalk
                       (snippet-playground-session-crosswalk-of session)
                       :pairing-notes
                       (snippet-playground-session-pairing-notes-of session)
                       :lisp-scaffold-source source
                       :state-machine-run
                       (snippet-playground-session-state-machine-run-of session)
                       :findings
                       (append (snippet-playground-session-findings-of session)
                               (list "No Lisp scaffold is available for this session."))
                       :failure-classification
                       :missing-lisp-scaffold)
        (handler-case
            (let ((result (clog-moldable-inspector::playground-eval-source
                           session
                           source)))
              (if (clog-moldable-inspector::playground-eval-error-p result)
                  (clog-moldable-inspector::make-playground-debug-report-from-eval-error
                   result
                   source
                   :retry (clog-moldable-inspector::make-playground-retry
                           session
                           source))
                  result))
          (error (condition)
            (clog-moldable-inspector::make-playground-debug-report
             condition
             source
             :retry (clog-moldable-inspector::make-playground-retry
                     session
                     source)))))))

(defun snippet-playground-display-value (value)
  (cond
    ((null value)
     "n/a")
    ((keywordp value)
     (string-downcase (string value)))
    ((symbolp value)
     (string-downcase (string value)))
    ((listp value)
     (format nil "~{~A~^, ~}" value))
    (t
     (format nil "~A" value))))

(defun snippet-playground-status-table-row (label value)
  (html-inspector-views:html
    (:tr (:td (html-inspector-views:esc label))
         (:td (html-inspector-views:esc
               (snippet-playground-display-value value))))))

(defun maybe-object-ref-row (label object)
  (html-inspector-views:html
    (:tr (:td (html-inspector-views:esc label))
         (:td (if object
                  (html-inspector-views:object-ref object)
                  (html-inspector-views:esc "n/a"))))))

(defun snippet-source-pre (source)
  (html-inspector-views:html
    (:pre :style "white-space: pre-wrap"
          (html-inspector-views:esc (or source "")))))

(defun snippet-playground-view-interface-text (session)
  (or (and (snippet-playground-session-execution-interface-of session)
           (snippet-execution-interface-handoff-path-of
            (snippet-playground-session-execution-interface-of session)))
      "n/a"))

(defun snippet-playground-view-lisp-source (session)
  (or (snippet-playground-session-lisp-scaffold-source-of session)
      "No Lisp scaffold is available for this session."))

(defun snippet-comparison-layout-region-specs (layout-spec)
  (getf layout-spec :regions))

(defun snippet-comparison-layout-show-once-content-keys (layout-spec)
  (loop for rule in (getf layout-spec :rules)
        when (eq (first rule) :show-once)
          collect (second rule)))

(defun snippet-comparison-surface-region-for-placement (surface placement)
  (find placement
        (snippet-comparison-surface-regions-of surface)
        :key #'snippet-comparison-region-placement-of
        :test #'eq))

(defun snippet-comparison-region-css-class (placement)
  (format nil
          "hyperdoc-snippet-comparison-region hyperdoc-snippet-comparison-~(~A~)"
          placement))

(defun snippet-playground-view-transformation-row (label value)
  (snippet-playground-status-table-row label value))

(defun snippet-comparison-render-region (region)
  (html-inspector-views:html
    (:div :class (snippet-comparison-region-css-class
                  (snippet-comparison-region-placement-of region))
          :style "min-width: 0;"
          (:h3 (html-inspector-views:esc (title-of region)))
          (snippet-source-pre
           (snippet-comparison-region-source-text-of region)))))

(defun snippet-comparison-render-surface (surface)
  (let ((shown-content-keys '())
        (show-once-keys
          (snippet-comparison-layout-show-once-content-keys
           (snippet-comparison-surface-layout-spec-of surface))))
    (html-inspector-views:html
      (:div :class "hyperdoc-snippet-comparison"
            (:div :class "hyperdoc-snippet-comparison-layout"
                  :style
                  "display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 0.9fr) minmax(0, 1fr); gap: 1rem; align-items: start;"
                  (dolist (region-spec
                           (snippet-comparison-layout-region-specs
                            (snippet-comparison-surface-layout-spec-of surface)))
                    (let* ((placement (first region-spec))
                           (region
                             (snippet-comparison-surface-region-for-placement
                              surface
                              placement))
                           (content-key
                             (and region
                                  (snippet-comparison-region-content-key-of
                                   region))))
                      (when (and region
                                 (not (and (member content-key
                                                   show-once-keys
                                                   :test #'eq)
                                           (member content-key
                                                   shown-content-keys
                                                   :test #'eq))))
                        (push content-key shown-content-keys)
                        (snippet-comparison-render-region region)))))
            (:div :class "hyperdoc-snippet-transformation-unit"
                  (:h3 "Transformation unit")
                  (if-let (unit
                           (snippet-comparison-surface-transformation-unit-of
                            surface))
                    (html-inspector-views:html
                      (:table :class "inspector-table"
                              (snippet-playground-view-transformation-row
                               "Interface"
                               (and (snippet-transformation-unit-execution-interface-of
                                     unit)
                                    (snippet-execution-interface-handoff-path-of
                                     (snippet-transformation-unit-execution-interface-of
                                      unit))))
                              (snippet-playground-view-transformation-row
                               "Operation"
                               (or (snippet-transformation-unit-operation-summary-of
                                    unit)
                                   (snippet-transformation-unit-operation-kind-of
                                    unit)))
                              (snippet-playground-view-transformation-row
                               "Output"
                               (snippet-transformation-unit-output-shape-of unit))
                              (snippet-playground-view-transformation-row
                               "Preview"
                               (snippet-transformation-unit-preview-mode-of unit))))
                    (html-inspector-views:html
                      (:p (html-inspector-views:esc
                           "No transformation unit is available for this session.")))))))))

(html-inspector-views:defview snippet-playground-step-summary
    (step mech-snippet-step)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Line"
               (format nil "~D" (mech-snippet-step-line-number-of step)))
              (snippet-playground-status-table-row
               "Operation"
               (mech-snippet-step-operation-of step))
              (snippet-playground-status-table-row
               "Arguments"
               (format nil "~{~A~^ ~}"
                       (mech-snippet-step-arguments-of step))))
      (:h3 "Raw line")
      (snippet-source-pre (mech-snippet-step-raw-line-of step)))))

(html-inspector-views:defview snippet-playground-mech-summary
    (snippet mech-snippet)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Block"
               (format nil "#~D" (mech-snippet-block-index-of snippet)))
              (snippet-playground-status-table-row
               "Source line"
               (format nil "~D" (mech-snippet-line-number-of snippet)))
              (snippet-playground-status-table-row
               "Preview mode"
               (mech-snippet-preview-mode-of snippet))
              (snippet-playground-status-table-row
               "Recognized steps"
               (format nil "~D" (length (mech-snippet-steps-of snippet)))))
      (:h3 "Findings")
      (:ul
       (dolist (finding (mech-snippet-findings-of snippet))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding)))))
      (:h3 "Source")
      (snippet-source-pre (mech-snippet-source-of snippet)))))

(html-inspector-views:defview snippet-playground-mech-steps
    (snippet mech-snippet)
  (html-inspector-views:html-view :title "Steps" :priority 2
    (html-inspector-views:html
      (:table :class "inspector-table"
              (:tr (:th "Line")
                   (:th "Op")
                   (:th "Arguments")
                   (:th "Inspectable step"))
              (dolist (step (mech-snippet-steps-of snippet))
                (html-inspector-views:html
                  (:tr (:td (html-inspector-views:esc
                             (format nil "~D"
                                     (mech-snippet-step-line-number-of step))))
                       (:td (html-inspector-views:esc
                             (mech-snippet-step-operation-of step)))
                       (:td (html-inspector-views:esc
                             (format nil "~{~A~^ ~}"
                                     (mech-snippet-step-arguments-of step))))
                       (:td (html-inspector-views:object-ref step)))))))))

(html-inspector-views:defview snippet-playground-code-summary
    (snippet code-snippet)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Block"
               (format nil "#~D" (code-snippet-block-index-of snippet)))
              (snippet-playground-status-table-row
               "Source line"
               (format nil "~D" (code-snippet-line-number-of snippet)))
              (snippet-playground-status-table-row
               "Language"
               (string-downcase (string (code-snippet-language-of snippet))))
              (snippet-playground-status-table-row
               "Output path"
               (code-snippet-output-path-of snippet))
              (snippet-playground-status-table-row
               "Translation mode"
               (string-downcase (string (code-snippet-translation-mode-of snippet)))))
      (:h3 "Findings")
      (:ul
       (dolist (finding (code-snippet-findings-of snippet))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding)))))
      (:h3 "Source")
      (snippet-source-pre (code-snippet-source-of snippet)))))

(html-inspector-views:defview snippet-execution-interface-summary
    (interface snippet-execution-interface)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of interface)))
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Handoff path"
               (snippet-execution-interface-handoff-path-of interface))
              (snippet-playground-status-table-row
               "Preview mode"
               (snippet-execution-interface-preview-mode-of interface))
              (snippet-playground-status-table-row
               "Output channel"
               (snippet-execution-interface-output-channel-of interface))
              (snippet-playground-status-table-row
               "Input role"
               (snippet-execution-interface-input-role-name-of interface))
              (snippet-playground-status-table-row
               "Output role"
               (snippet-execution-interface-output-role-name-of interface)))
      (:h3 "Findings")
      (:ul
       (dolist (finding (snippet-execution-interface-findings-of interface))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding))))))))

(html-inspector-views:defview snippet-lefty-projection-summary
    (projection snippet-lefty-projection)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of projection)))
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Origin surface"
               (snippet-lefty-projection-origin-surface-kind-of projection))
              (snippet-playground-status-table-row
               "Provider kind"
               (snippet-lefty-projection-provider-kind-of projection))
              (snippet-playground-status-table-row
               "Origin label"
               (snippet-lefty-projection-origin-label-of projection))
              (snippet-playground-status-table-row
               "Context view"
               (snippet-lefty-projection-context-view-title-of projection))
              (maybe-object-ref-row
               "Mech evidence"
               (snippet-lefty-projection-mech-snippet-of projection))
              (maybe-object-ref-row
               "JavaScript evidence"
               (snippet-lefty-projection-code-snippet-of projection)))
      (:h3 "Findings")
      (:ul
       (dolist (finding (snippet-lefty-projection-findings-of projection))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding))))))))

(html-inspector-views:defview snippet-rita-projection-summary
    (projection snippet-rita-projection)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of projection)))
      (:table :class "inspector-table"
              (maybe-object-ref-row
               "Mech evidence"
               (snippet-rita-projection-mech-snippet-of projection))
              (maybe-object-ref-row
               "Execution interface"
               (snippet-rita-projection-execution-interface-of projection))
              (snippet-playground-status-table-row
               "Scaffold available"
               (if (snippet-playground-empty-string-p
                    (snippet-rita-projection-lisp-scaffold-source-of projection))
                   "no"
                   "yes")))
      (:h3 "Findings")
      (:ul
       (dolist (finding (snippet-rita-projection-findings-of projection))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding)))))
      (:h3 "Lisp scaffold")
      (snippet-source-pre
       (snippet-rita-projection-lisp-scaffold-source-of projection)))))

(html-inspector-views:defview snippet-transformation-unit-summary
    (unit snippet-transformation-unit)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of unit)))
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Input kind"
               (snippet-transformation-unit-input-kind-of unit))
              (snippet-playground-status-table-row
               "Input shape"
               (snippet-transformation-unit-input-shape-of unit))
              (snippet-playground-status-table-row
               "Operation kind"
               (snippet-transformation-unit-operation-kind-of unit))
              (snippet-playground-status-table-row
               "Operation summary"
               (snippet-transformation-unit-operation-summary-of unit))
              (snippet-playground-status-table-row
               "Preview mode"
               (snippet-transformation-unit-preview-mode-of unit))
              (snippet-playground-status-table-row
               "Output kind"
               (snippet-transformation-unit-output-kind-of unit))
              (snippet-playground-status-table-row
               "Output shape"
               (snippet-transformation-unit-output-shape-of unit))
              (maybe-object-ref-row
               "Execution interface"
               (snippet-transformation-unit-execution-interface-of unit))
              (maybe-object-ref-row
               "Lefty projection"
               (snippet-transformation-unit-lefty-projection-of unit))
              (maybe-object-ref-row
               "Rita projection"
               (snippet-transformation-unit-rita-projection-of unit)))
      (:h3 "Findings")
      (:ul
       (dolist (finding (snippet-transformation-unit-findings-of unit))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding))))))))

(html-inspector-views:defview snippet-comparison-region-summary
    (region snippet-comparison-region)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Placement"
               (snippet-comparison-region-placement-of region))
              (snippet-playground-status-table-row
               "Content"
               (snippet-comparison-region-content-key-of region)))
      (snippet-source-pre
       (snippet-comparison-region-source-text-of region)))))

(html-inspector-views:defview snippet-comparison-surface-summary
    (surface snippet-comparison-surface)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (snippet-comparison-render-surface surface)))

(html-inspector-views:defview snippet-comparison-surface-details
    (surface snippet-comparison-surface)
  (html-inspector-views:html-view :title "Details" :priority 2
    (html-inspector-views:html
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Layout"
               (getf (snippet-comparison-surface-layout-spec-of surface)
                     :surface))
              (snippet-playground-status-table-row
               "Rules"
               (getf (snippet-comparison-surface-layout-spec-of surface)
                     :rules))
              (maybe-object-ref-row
               "Lifecycle run"
               (snippet-comparison-surface-lifecycle-run-of surface))
              (maybe-object-ref-row
               "Shared Mech region"
               (snippet-comparison-surface-shared-mech-region-of surface))
              (maybe-object-ref-row
               "Left code region"
               (snippet-comparison-surface-left-code-region-of surface))
              (maybe-object-ref-row
               "Right code region"
               (snippet-comparison-surface-right-code-region-of surface)))
      (:h3 "Findings")
      (:ul
       (dolist (finding (snippet-comparison-surface-findings-of surface))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding))))))))

(html-inspector-views:defview snippet-playground-session-summary-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:div :class "hyperdoc-snippet-summary-minimal"
            (:p :class "hyperdoc-snippet-summary-sentence"
                (html-inspector-views:esc (summary-of session)))
            (:p :class "hyperdoc-snippet-summary-interface"
                (:strong "Interface:")
                " "
                (html-inspector-views:esc
                 (snippet-playground-view-interface-text session)))))))

(html-inspector-views:defview snippet-playground-session-details-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Details" :priority 3
    (html-inspector-views:html
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Status"
               (snippet-playground-status-label
                (snippet-playground-session-status-of session)))
              (snippet-playground-status-table-row
               "Context view"
               (snippet-playground-session-context-view-title-of session))
              (snippet-playground-status-table-row
               "Origin surface"
               (snippet-playground-session-origin-surface-kind-of session))
              (snippet-playground-status-table-row
               "Provider kind"
               (snippet-playground-session-provider-kind-of session))
              (snippet-playground-status-table-row
               "Source label"
               (snippet-playground-session-source-label-of session))
              (snippet-playground-status-table-row
               "Source file"
               (and (snippet-playground-session-source-pathname-of session)
                    (namestring
                     (snippet-playground-session-source-pathname-of session))))
              (maybe-object-ref-row
               "Execution interface"
               (snippet-playground-session-execution-interface-of session))
              (maybe-object-ref-row
               "Transformation unit"
               (snippet-playground-session-transformation-unit-of session))
              (maybe-object-ref-row
               "Comparison surface"
               (snippet-playground-session-comparison-surface-of session))
              (maybe-object-ref-row
               "Lefty projection"
               (and (snippet-playground-session-transformation-unit-of session)
                    (snippet-transformation-unit-lefty-projection-of
                     (snippet-playground-session-transformation-unit-of session))))
              (maybe-object-ref-row
               "Rita projection"
               (and (snippet-playground-session-transformation-unit-of session)
                    (snippet-transformation-unit-rita-projection-of
                     (snippet-playground-session-transformation-unit-of session))))
              (snippet-playground-status-table-row
               "Transformation input kind"
               (and (snippet-playground-session-transformation-unit-of session)
                    (snippet-transformation-unit-input-kind-of
                     (snippet-playground-session-transformation-unit-of
                      session))))
              (snippet-playground-status-table-row
               "Transformation operation"
               (and (snippet-playground-session-transformation-unit-of session)
                    (snippet-transformation-unit-operation-kind-of
                     (snippet-playground-session-transformation-unit-of
                      session))))
              (snippet-playground-status-table-row
               "Transformation output kind"
               (and (snippet-playground-session-transformation-unit-of session)
                    (snippet-transformation-unit-output-kind-of
                     (snippet-playground-session-transformation-unit-of
                      session))))
              (snippet-playground-status-table-row
               "Collected inputs"
               (format nil "~D"
                       (snippet-playground-session-source-block-count-of
                        session)))
              (snippet-playground-status-table-row
               "Recognized Mech snippets"
               (format nil "~D"
                       (length
                        (snippet-playground-session-recognized-mech-snippets-of
                         session))))
              (snippet-playground-status-table-row
               "Recognized code snippets"
               (format nil "~D"
                       (length
                        (snippet-playground-session-recognized-code-snippets-of
                         session))))
              (maybe-object-ref-row
               "Selected Mech evidence"
               (snippet-playground-session-selected-mech-of session))
              (maybe-object-ref-row
               "Selected code evidence"
               (snippet-playground-session-selected-code-of session))
              (snippet-playground-status-table-row
               "Detected code language"
               (and (snippet-playground-session-selected-code-of session)
                    (code-language-display-name
                     (code-snippet-language-of
                      (snippet-playground-session-selected-code-of session)))))
              (maybe-object-ref-row
               "Run"
               (snippet-playground-session-state-machine-run-of session))
              (when (typep session 'snippet-playground-failure)
                (snippet-playground-status-table-row
                 "Failure classification"
                 (string-downcase
                  (string
                   (snippet-playground-failure-classification-of session))))))
      (:h3 "Findings")
      (if (snippet-playground-session-findings-of session)
          (html-inspector-views:html
            (:ul
             (dolist (finding (snippet-playground-session-findings-of session))
               (html-inspector-views:html
                 (:li (html-inspector-views:esc finding))))))
          (html-inspector-views:html
            (:p (html-inspector-views:esc
                 "Constructed execution interface and transformation unit for the current slice."))))
      (:h3 "Evidence inputs")
      (:ul
       (dolist (note (snippet-playground-session-pairing-notes-of session))
         (html-inspector-views:html
           (:li (html-inspector-views:esc note))))))))

(html-inspector-views:defview snippet-playground-session-source-pair
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Evidence" :priority 4
    (html-inspector-views:html
      (:h3 "Mech evidence")
      (if-let (mech (snippet-playground-session-selected-mech-of session))
        (snippet-source-pre (mech-snippet-source-of mech))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No Mech snippet was selected from the current origin surface."))))
      (:h3 "Code evidence")
      (if-let (code (snippet-playground-session-selected-code-of session))
        (snippet-source-pre (code-snippet-source-of code))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No supported code snippet was selected from the current origin surface.")))))))

(html-inspector-views:defview snippet-playground-session-mech
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Mech" :priority 5
    (html-inspector-views:html
      (if-let (mech (snippet-playground-session-selected-mech-of session))
        (html-inspector-views:html
          (:table :class "inspector-table"
                  (snippet-playground-status-table-row
                   "Preview mode"
                   (mech-snippet-preview-mode-of mech))
                  (snippet-playground-status-table-row
                   "Recognized steps"
                   (format nil "~D"
                           (length (mech-snippet-steps-of mech)))))
          (:ul
           (dolist (step (mech-snippet-steps-of mech))
             (html-inspector-views:html
               (:li (html-inspector-views:object-ref step
                                                     :display
                                                     (title-of step)))))))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No Mech snippet is available for this session.")))))))

(html-inspector-views:defview snippet-playground-session-code
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Code" :priority 6
    (html-inspector-views:html
      (if-let (code (snippet-playground-session-selected-code-of session))
        (html-inspector-views:html
          (:table :class "inspector-table"
                  (snippet-playground-status-table-row
                   "Language"
                   (string-downcase (string (code-snippet-language-of code))))
                  (snippet-playground-status-table-row
                   "Output path"
                   (code-snippet-output-path-of code))
                  (snippet-playground-status-table-row
                   "Translation mode"
                   (string-downcase
                    (string (code-snippet-translation-mode-of code)))))
          (:h3 "Source")
          (snippet-source-pre (code-snippet-source-of code)))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No supported code snippet is available for this session.")))))))

(html-inspector-views:defview snippet-playground-session-comparison-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Comparison" :priority 2
    (html-inspector-views:html
      (if-let (surface (snippet-playground-session-comparison-surface-of session))
        (snippet-comparison-render-surface surface)
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No comparison surface is available for this session.")))))))

(html-inspector-views:defview snippet-playground-session-crosswalk-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Crosswalk" :priority 7
    (html-inspector-views:html
      (if (snippet-playground-session-crosswalk-of session)
          (html-inspector-views:html
            (:table :class "inspector-table"
                    (:tr (:th "Stage")
                         (:th "Mech")
                         (:th "JavaScript")
                         (:th "Lisp")
                         (:th "Detail"))
                    (dolist (entry (snippet-playground-session-crosswalk-of
                                    session))
                      (html-inspector-views:html
                        (:tr
                         (:td (html-inspector-views:esc (getf entry :stage)))
                         (:td (html-inspector-views:esc (getf entry :mech)))
                         (:td (html-inspector-views:esc (getf entry :javascript)))
                         (:td (html-inspector-views:esc (getf entry :lisp)))
                         (:td (html-inspector-views:esc (getf entry :detail)))))))
          (html-inspector-views:html
            (:p (html-inspector-views:esc
                 "Crosswalk is unavailable until both a Mech snippet and a code snippet are recognized.")))))))
  )

(html-inspector-views:defview snippet-playground-session-lisp-scaffold-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Lisp scaffold" :priority 8
    (html-inspector-views:html
      (if (snippet-playground-session-ready-p session)
          (html-inspector-views:html
            (:p
             (html-inspector-views:action-button
              "Run scaffold"
              (html-inspector-views:thunk
                (setf (snippet-playground-session-last-run-object-of session)
                      (snippet-playground-run-scaffold session))
                t)
              "Evaluate the scaffold in-place and keep the result inspectable on the session.")
             " "
             (html-inspector-views:eval-button
              "Step scaffold"
              (html-inspector-views:thunk
                (clog-moldable-inspector::make-playground-stepper
                 session
                 (snippet-playground-session-lisp-scaffold-source-of session)))
              "Open the generated Lisp scaffold in the existing stepper surface."))
            (:h3 "Scaffold source")
            (snippet-source-pre
             (snippet-playground-session-lisp-scaffold-source-of session))
            (when (snippet-playground-session-last-run-object-of session)
              (html-inspector-views:html
                (:h3 "Last run object")
                (:p (html-inspector-views:object-ref
                     (snippet-playground-session-last-run-object-of session)))
                (:h3 "Derived items")
                (snippet-source-pre
                 (format nil "~S"
                         (snippet-playground-session-derived-items-of
                          session))))))
          (html-inspector-views:html
            (:p (html-inspector-views:esc
                 "No runnable Lisp scaffold is available for this session.")))))))
