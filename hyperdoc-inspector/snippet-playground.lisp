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
   (source-original-length
     :reader snippet-comparison-region-source-original-length-of
     :initarg :source-original-length
     :initform 0)
   (source-truncated-p
     :reader snippet-comparison-region-source-truncated-p
     :initarg :source-truncated-p
     :initform nil)
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
   (layout-artifact :reader snippet-comparison-surface-layout-artifact-of
                    :initarg :layout-artifact
                    :initform nil)
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

(defclass snippet-playground-authored-role (authored-relation-role) ())

(defclass snippet-playground-authored-relation (authored-relation) ())

(defclass snippet-playground-authored-artifact (authored-relation-artifact) ())

(defclass snippet-playground-behavior-artifact (compiled-behavior-artifact) ())

(defclass snippet-playground-layout-artifact (compiled-layout-artifact) ())

(defmacro define-snippet-playground-forwarding-reader (name target)
  `(defun ,name (object)
     (,target object)))

(define-snippet-playground-forwarding-reader
    snippet-playground-authored-role-kind-of
    authored-relation-role-kind-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-role-binding-of
    authored-relation-role-binding-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-role-participants-of
    authored-relation-role-participants-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-role-findings-of
    authored-relation-role-findings-of)

(define-snippet-playground-forwarding-reader
    snippet-playground-authored-relation-layer-of
    authored-relation-layer-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-relation-subject-of
    authored-relation-subject-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-relation-predicate-of
    authored-relation-predicate-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-relation-object-of
    authored-relation-object-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-relation-attributes-of
    authored-relation-attributes-of)

(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-kind-of
    authored-relation-artifact-kind-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-workflow-role-of
    authored-relation-artifact-workflow-role-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-compiler-pipeline-of
    authored-relation-artifact-compiler-pipeline-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-semantic-roles-of
    authored-relation-artifact-semantic-roles-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-semantic-relations-of
    authored-relation-artifact-semantic-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-behavior-relations-of
    authored-relation-artifact-behavior-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-layout-relations-of
    authored-relation-artifact-layout-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-relations-of
    authored-relation-artifact-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-compiled-targets-of
    authored-relation-artifact-compiled-targets-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-authored-artifact-findings-of
    authored-relation-artifact-findings-of)

(define-snippet-playground-forwarding-reader
    snippet-playground-behavior-artifact-authored-artifact-of
    compiled-artifact-authored-artifact-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-behavior-artifact-relations-of
    compiled-artifact-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-behavior-artifact-findings-of
    compiled-artifact-findings-of)

(define-snippet-playground-forwarding-reader
    snippet-playground-layout-artifact-authored-artifact-of
    compiled-artifact-authored-artifact-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-layout-artifact-relations-of
    compiled-artifact-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-layout-artifact-pane-relations-of
    compiled-layout-artifact-pane-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-layout-artifact-comparison-relations-of
    compiled-layout-artifact-comparison-relations-of)
(define-snippet-playground-forwarding-reader
    snippet-playground-layout-artifact-findings-of
    compiled-artifact-findings-of)

(defun snippet-playground-behavior-artifact-run-machine-of (artifact)
  (compiled-behavior-artifact-machine artifact :primary))

(defun snippet-playground-behavior-artifact-run-machine-scxml-of (artifact)
  (compiled-behavior-artifact-machine-scxml artifact :primary))

(defun snippet-playground-behavior-artifact-comparison-machine-of (artifact)
  (compiled-behavior-artifact-machine artifact :comparison-surface))

(defun snippet-playground-behavior-artifact-comparison-machine-scxml-of
    (artifact)
  (compiled-behavior-artifact-machine-scxml artifact :comparison-surface))

(defun snippet-playground-layout-artifact-comparison-layout-spec-of (artifact)
  (compiled-layout-artifact-layout-spec-of artifact))

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
   (authored-artifact
     :reader snippet-playground-session-authored-artifact-of
     :initarg :authored-artifact
     :initform nil)
   (behavior-artifact
     :reader snippet-playground-session-behavior-artifact-of
     :initarg :behavior-artifact
     :initform nil)
   (layout-artifact
     :reader snippet-playground-session-layout-artifact-of
     :initarg :layout-artifact
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

(defmethod print-object ((object snippet-playground-authored-role) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-playground-authored-relation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-playground-authored-artifact) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-playground-behavior-artifact) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object snippet-playground-layout-artifact) stream)
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
    ((object snippet-playground-authored-role))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-playground-authored-relation))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-playground-authored-artifact))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-playground-behavior-artifact))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object snippet-playground-layout-artifact))
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

(defvar *snippet-playground-authored-artifact* nil)
(defvar *snippet-playground-behavior-artifact* nil)
(defvar *snippet-playground-layout-artifact* nil)
(defparameter *snippet-playground-inline-source-render-limit* 4096)
(defparameter *snippet-playground-scaffold-source-excerpt-limit* 1024)

(defun make-snippet-playground-authored-relation
    (&key id title summary layer subject predicate object attributes)
  (make-instance
   'snippet-playground-authored-relation
   :id id
   :title title
   :summary summary
   :layer layer
   :subject subject
   :predicate predicate
   :object object
   :attributes attributes))

(defun snippet-playground-authored-relation-attribute (relation key)
  (getf (snippet-playground-authored-relation-attributes-of relation)
        key))

(defun make-snippet-playground-authored-graph ()
  (list
             (make-snippet-playground-authored-relation
              :id "semantic/evidence/mech"
              :title "Snippet evidence -> Mech"
              :summary "Snippet-playground gathers Mech evidence."
              :layer :semantic
              :subject :snippet-playground
              :predicate :uses-evidence
              :object :mech-snippet)
             (make-snippet-playground-authored-relation
              :id "semantic/evidence/code"
              :title "Snippet evidence -> Code"
              :summary "Snippet-playground gathers code evidence."
              :layer :semantic
              :subject :snippet-playground
              :predicate :uses-evidence
              :object :code-snippet)
             (make-snippet-playground-authored-relation
              :id "semantic/interface"
              :title "Snippet infers execution interface"
              :summary "Execution interface is inferred from Mech + code evidence."
              :layer :semantic
              :subject :snippet-playground
              :predicate :infers
              :object :snippet-execution-interface)
             (make-snippet-playground-authored-relation
              :id "semantic/transformation-unit"
              :title "Snippet constructs transformation unit"
              :summary "Transformation unit is the primary semantic artifact."
              :layer :semantic
              :subject :snippet-playground
              :predicate :constructs
              :object :snippet-transformation-unit)
             (make-snippet-playground-authored-relation
              :id "semantic/transformation-unit/lefty"
              :title "Transformation unit -> Lefty"
              :summary "Transformation unit exposes the Lefty projection."
              :layer :semantic
              :subject :snippet-transformation-unit
              :predicate :projects-to
              :object :lefty)
             (make-snippet-playground-authored-relation
              :id "semantic/transformation-unit/rita"
              :title "Transformation unit -> Rita"
              :summary "Transformation unit exposes the Rita projection."
              :layer :semantic
              :subject :snippet-transformation-unit
              :predicate :projects-to
              :object :rita)
             (make-snippet-playground-authored-relation
              :id "projection/behavior"
              :title "Compiled behavior projection"
              :summary "Authored snippet relations compile into a lifecycle machine."
              :layer :projection
              :subject :snippet-playground
              :predicate :projects-to
              :object :snippet_playground_run)
             (make-snippet-playground-authored-relation
              :id "projection/layout"
              :title "Compiled layout projection"
              :summary "Authored layout relations compile into a comparison layout spec."
              :layer :projection
              :subject :snippet-playground
              :predicate :projects-to
              :object :snippet-comparison-layout)
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/unavailable"
              :title "State unavailable"
              :summary "Snippet capability is hidden."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :unavailable
              :attributes
              '(:title "unavailable"
                :summary "Snippet capability is hidden because the current pane does not expose a snippet provider."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/available"
              :title "State available"
              :summary "Snippet capability is visible."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :available
              :attributes
              '(:title "available"
                :summary "Snippet capability is visible on the origin pane."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/invoked"
              :title "State invoked"
              :summary "Snippet was clicked."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :invoked
              :attributes
              '(:title "invoked"
                :summary "The user clicked Snippet on the origin pane."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/pending"
              :title "State pending"
              :summary "Pending pane is visible."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :pending
              :attributes
              '(:title "pending"
                :summary "A pending pane has opened to the right of the origin pane."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/collecting-input"
              :title "State collecting_input"
              :summary "Collecting provider input."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :collecting-input
              :attributes
              '(:title "collecting_input"
                :summary "Provider-specific snippet input is being collected."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/recognizing"
              :title "State recognizing"
              :summary "Recognizing snippets."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :recognizing
              :attributes
              '(:title "recognizing"
                :summary "Mech and code snippets are being recognized."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/pairing"
              :title "State pairing"
              :summary "Selecting evidential inputs."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :pairing
              :attributes
              '(:title "pairing"
                :summary "Recognized Mech/code evidence is being selected before semantic binding."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/building-session"
              :title "State building_session"
              :summary "Building the session."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :building-session
              :attributes
              '(:title "building_session"
                :summary "The inspectable snippet-playground session is being built."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/ready"
              :title "State ready"
              :summary "Ready pane replaced pending."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :ready
              :attributes
              '(:title "ready"
                :summary "Pending pane has been replaced in place by a ready snippet session."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/state/failed"
              :title "State failed"
              :summary "Failure replaced pending."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-state
              :object :failed
              :attributes
              '(:title "failed"
                :summary "Pending pane has been replaced by an inspectable failure object."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/initial"
              :title "Initial run state"
              :summary "State machine initial state."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :initial-state
              :object :unavailable)
             (make-snippet-playground-authored-relation
              :id "behavior/run/terminal/ready"
              :title "Terminal ready"
              :summary "Ready is terminal."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :terminal-state
              :object :ready)
             (make-snippet-playground-authored-relation
              :id "behavior/run/terminal/failed"
              :title "Terminal failed"
              :summary "Failed is terminal."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :terminal-state
              :object :failed)
             (make-snippet-playground-authored-relation
              :id "behavior/run/failure/failed"
              :title "Failure failed"
              :summary "Failed is a failure state."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :failure-state
              :object :failed)
             (make-snippet-playground-authored-relation
              :id "behavior/run/guard/provider"
              :title "Guard pane-supports-snippet-provider"
              :summary "Origin pane supports a snippet provider."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-guard
              :object :pane-supports-snippet-provider)
             (make-snippet-playground-authored-relation
              :id "behavior/run/guard/input"
              :title "Guard input-extracted"
              :summary "Input was extracted."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-guard
              :object :input-extracted)
             (make-snippet-playground-authored-relation
              :id "behavior/run/guard/candidates"
              :title "Guard candidates-found"
              :summary "Snippet candidates were recognized."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-guard
              :object :candidates-found)
             (make-snippet-playground-authored-relation
              :id "behavior/run/guard/valid-pair"
              :title "Guard valid-pair"
              :summary "Evidential Mech + code pair is valid."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-guard
              :object :valid-pair)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/snippet-click"
              :title "Event snippet-click"
              :summary "User clicked Snippet."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :snippet-click)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/open-pending-pane"
              :title "Event open-pending-pane"
              :summary "Pending pane was opened."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :open-pending-pane)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/pending-pane-opened"
              :title "Event pending-pane-opened"
              :summary "Pending pane is visible."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :pending-pane-opened)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/input-collected"
              :title "Event input-collected"
              :summary "Provider input was collected."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :input-collected)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/snippets-recognized"
              :title "Event snippets-recognized"
              :summary "Snippet candidates were recognized."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :snippets-recognized)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/pair-selected"
              :title "Event pair-selected"
              :summary "Mech + code evidence pair was selected."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :pair-selected)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/transformation-unit-built"
              :title "Event transformation-unit-built"
              :summary "Transformation unit was built into a session."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :transformation-unit-built)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/input-collection-failed"
              :title "Event input-collection-failed"
              :summary "Input collection failed."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :input-collection-failed)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/recognition-failed"
              :title "Event recognition-failed"
              :summary "Recognition failed."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :recognition-failed)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/pairing-failed"
              :title "Event pairing-failed"
              :summary "Pairing failed."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :pairing-failed)
             (make-snippet-playground-authored-relation
              :id "behavior/run/event/session-build-failed"
              :title "Event session-build-failed"
              :summary "Session build failed."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-event
              :object :session-build-failed)
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/unavailable-available"
              :title "Transition unavailable -> available"
              :summary "Snippet capability becomes visible."
              :layer :behavior
              :subject :unavailable
              :predicate :transition-to
              :object :available
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/unavailable->available"
                :guard :pane-supports-snippet-provider
                :side-effects
                "Show Snippet in the capability row for html-source and fedwiki-page surfaces."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/available-invoked"
              :title "Transition available -> invoked"
              :summary "Snippet is clicked."
              :layer :behavior
              :subject :available
              :predicate :transition-to
              :object :invoked
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/available->invoked"
                :trigger :snippet-click))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/invoked-pending"
              :title "Transition invoked -> pending"
              :summary "Pending pane opens."
              :layer :behavior
              :subject :invoked
              :predicate :transition-to
              :object :pending
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/invoked->pending"
                :trigger :open-pending-pane
                :side-effects
                "Open a pending pane to the right of the origin pane and retain the origin-pane placement invariant."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/pending-collecting"
              :title "Transition pending -> collecting-input"
              :summary "Pending pane is ready for collection."
              :layer :behavior
              :subject :pending
              :predicate :transition-to
              :object :collecting-input
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/pending->collecting-input"
                :trigger :pending-pane-opened))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/collecting-recognizing"
              :title "Transition collecting-input -> recognizing"
              :summary "Collected input moves into recognition."
              :layer :behavior
              :subject :collecting-input
              :predicate :transition-to
              :object :recognizing
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/collecting-input->recognizing"
                :trigger :input-collected
                :guard :input-extracted))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/recognizing-pairing"
              :title "Transition recognizing -> pairing"
              :summary "Recognized snippets move into pairing."
              :layer :behavior
              :subject :recognizing
              :predicate :transition-to
              :object :pairing
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/recognizing->pairing"
                :trigger :snippets-recognized
                :guard :candidates-found))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/pairing-building"
              :title "Transition pairing -> building-session"
              :summary "Selected evidence builds a session."
              :layer :behavior
              :subject :pairing
              :predicate :transition-to
              :object :building-session
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/pairing->building-session"
                :trigger :pair-selected
                :guard :valid-pair))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/building-ready"
              :title "Transition building-session -> ready"
              :summary "Transformation unit becomes a ready session."
              :layer :behavior
              :subject :building-session
              :predicate :transition-to
              :object :ready
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/building-session->ready"
                :trigger :transformation-unit-built))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/collecting-failed"
              :title "Transition collecting-input -> failed"
              :summary "Collection failure."
              :layer :behavior
              :subject :collecting-input
              :predicate :transition-to
              :object :failed
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/collecting-input->failed"
                :trigger :input-collection-failed))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/recognizing-failed"
              :title "Transition recognizing -> failed"
              :summary "Recognition failure."
              :layer :behavior
              :subject :recognizing
              :predicate :transition-to
              :object :failed
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/recognizing->failed"
                :trigger :recognition-failed))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/pairing-failed"
              :title "Transition pairing -> failed"
              :summary "Pairing failure."
              :layer :behavior
              :subject :pairing
              :predicate :transition-to
              :object :failed
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/pairing->failed"
                :trigger :pairing-failed))
             (make-snippet-playground-authored-relation
              :id "behavior/run/transition/building-failed"
              :title "Transition building-session -> failed"
              :summary "Session build failure."
              :layer :behavior
              :subject :building-session
              :predicate :transition-to
              :object :failed
              :attributes
              '(:machine :snippet-playground-run
                :id "snippet/building-session->failed"
                :trigger :session-build-failed))
             (make-snippet-playground-authored-relation
              :id "behavior/run/invariant/placement"
              :title "Invariant result pane placement"
              :summary "Result pane opens right-of the origin."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-invariant
              :object "Result pane placement"
              :attributes
              '(:detail "The result pane is always created to the right of the pane that initiated Snippet."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/invariant/shared-lifecycle"
              :title "Invariant shared lifecycle"
              :summary "Source and FedWiki share the same machine."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-invariant
              :object "Shared lifecycle"
              :attributes
              '(:detail "The same run states apply to html-source and fedwiki-page providers."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/invariant/failure"
              :title "Invariant inspectable failure"
              :summary "Failures are inspectable."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :has-invariant
              :object "Inspectable failure"
              :attributes
              '(:detail "Malformed or unsupported input resolves to an inspectable failure object rather than a silent failure."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/source-evidence/browser"
              :title "Browser source evidence"
              :summary "Browser capability wiring."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :source-evidence
              :object "assets/hyperdoc/js/dom-annotation-connect.js"
              :attributes
              '(:layer "browser"
                :detail "Capability visibility and invocation reuse the existing pane-shell submit bridge."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/source-evidence/server"
              :title "Server source evidence"
              :summary "Pending-pane replacement wiring."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :source-evidence
              :object "hyperbook-server/inspector-wiring.lisp"
              :attributes
              '(:layer "server"
                :detail "Pending panes open to the right of the origin pane and are replaced in place."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/source-evidence/provider"
              :title "Provider source evidence"
              :summary "Provider-aware target dispatch."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :source-evidence
              :object "hyperdoc-explorer/dom-annotations.lisp"
              :attributes
              '(:layer "provider"
                :detail "html-source and fedwiki-page surfaces both dispatch through provider-aware snippet targets."))
             (make-snippet-playground-authored-relation
              :id "behavior/run/source-evidence/session"
              :title "Session source evidence"
              :summary "Session construction logic."
              :layer :behavior
              :subject :snippet-playground-run
              :predicate :source-evidence
              :object "hyperdoc-inspector/snippet-playground.lisp"
              :attributes
              '(:layer "session"
                :detail "Recognition, evidence selection, session construction, and failure objects all share the same run definition."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/state/available"
              :title "Comparison state available"
              :summary "Comparison surface can be built."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-state
              :object :available
              :attributes
              '(:title "available"
                :summary "Comparison surface can be built from the selected snippet evidence."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/state/pending"
              :title "Comparison state pending"
              :summary "Comparison surface is pending."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-state
              :object :pending
              :attributes
              '(:title "pending"
                :summary "Pending pane is visible to the right of the origin pane."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/state/ready"
              :title "Comparison state ready"
              :summary "Comparison surface is ready."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-state
              :object :ready
              :attributes
              '(:title "ready"
                :summary "Pending pane was replaced in place by a ready comparison surface."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/state/failed"
              :title "Comparison state failed"
              :summary "Comparison surface failed."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-state
              :object :failed
              :attributes
              '(:title "failed"
                :summary "Pending pane was replaced in place by an inspectable failed comparison surface."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/initial"
              :title "Comparison initial state"
              :summary "Comparison machine initial state."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :initial-state
              :object :available)
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/terminal/ready"
              :title "Comparison terminal ready"
              :summary "Ready is terminal."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :terminal-state
              :object :ready)
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/terminal/failed"
              :title "Comparison terminal failed"
              :summary "Failed is terminal."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :terminal-state
              :object :failed)
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/failure/failed"
              :title "Comparison failure state"
              :summary "Failed is a failure state."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :failure-state
              :object :failed)
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/event/open-pending-pane"
              :title "Comparison event open-pending-pane"
              :summary "Comparison pending pane opens."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-event
              :object :open-pending-pane)
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/event/comparison-built"
              :title "Comparison event comparison-built"
              :summary "Comparison was built."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-event
              :object :comparison-built)
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/event/comparison-failed"
              :title "Comparison event comparison-failed"
              :summary "Comparison failed."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-event
              :object :comparison-failed)
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/transition/available-pending"
              :title "Comparison transition available -> pending"
              :summary "Comparison pending opens."
              :layer :behavior
              :subject :available
              :predicate :transition-to
              :object :pending
              :attributes
              '(:machine :snippet-comparison-surface
                :id "comparison/available->pending"
                :trigger :open-pending-pane
                :side-effects
                "Open a pending pane to the right of the origin pane."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/transition/pending-ready"
              :title "Comparison transition pending -> ready"
              :summary "Comparison replaces pending."
              :layer :behavior
              :subject :pending
              :predicate :transition-to
              :object :ready
              :attributes
              '(:machine :snippet-comparison-surface
                :id "comparison/pending->ready"
                :trigger :comparison-built
                :side-effects
                "Replace the pending pane in place with the ready comparison surface."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/transition/pending-failed"
              :title "Comparison transition pending -> failed"
              :summary "Failed comparison replaces pending."
              :layer :behavior
              :subject :pending
              :predicate :transition-to
              :object :failed
              :attributes
              '(:machine :snippet-comparison-surface
                :id "comparison/pending->failed"
                :trigger :comparison-failed
                :side-effects
                "Replace the pending pane in place with an inspectable failure surface."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/invariant/placement"
              :title "Comparison invariant placement"
              :summary "Comparison result remains right-of origin."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-invariant
              :object "Placement invariant"
              :attributes
              '(:detail "Result pane remains to the right of the pane that initiated Snippet."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/invariant/pending"
              :title "Comparison invariant pending replacement"
              :summary "Pending is replaced in place."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :has-invariant
              :object "Pending replacement"
              :attributes
              '(:detail "Ready and failed surfaces both replace the pending pane in place."))
             (make-snippet-playground-authored-relation
              :id "behavior/comparison/source-evidence/session"
              :title "Comparison source evidence"
              :summary "Comparison layout and lifecycle are session-backed."
              :layer :behavior
              :subject :snippet-comparison-surface
              :predicate :source-evidence
              :object "hyperdoc-inspector/snippet-playground.lisp"
              :attributes
              '(:layer "session"
                :detail "Comparison surface layout and lifecycle are carried separately from the primary snippet run state machine."))
             (make-snippet-playground-authored-relation
              :id "layout/result/right-of"
              :title "Result pane right-of origin pane"
              :summary "Result pane opens right-of the origin pane."
              :layer :layout
              :subject :result-pane
              :predicate :right-of
              :object :origin-pane)
             (make-snippet-playground-authored-relation
              :id "layout/ready/replaces"
              :title "Ready pane replaces pending pane"
              :summary "Ready pane replaces pending in place."
              :layer :layout
              :subject :ready-pane
              :predicate :replaces
              :object :pending-pane)
             (make-snippet-playground-authored-relation
              :id "layout/failed/replaces"
              :title "Failed pane replaces pending pane"
              :summary "Failed pane replaces pending in place."
              :layer :layout
              :subject :failed-pane
              :predicate :replaces
              :object :pending-pane)
             (make-snippet-playground-authored-relation
              :id "layout/comparison/left"
              :title "Comparison contains Lefty JavaScript"
              :summary "Comparison pane contains JavaScript on the left."
              :layer :layout
              :subject :comparison-pane
              :predicate :contains-left
              :object :lefty-javascript)
             (make-snippet-playground-authored-relation
              :id "layout/comparison/center"
              :title "Comparison contains shared Mech"
              :summary "Comparison pane contains shared Mech in the center."
              :layer :layout
              :subject :comparison-pane
              :predicate :contains-center
              :object :shared-mech)
             (make-snippet-playground-authored-relation
              :id "layout/comparison/right"
              :title "Comparison contains Rita Lisp"
              :summary "Comparison pane contains Lisp on the right."
              :layer :layout
              :subject :comparison-pane
              :predicate :contains-right
              :object :rita-lisp)
             (make-snippet-playground-authored-relation
              :id "layout/comparison/shared-mech-above-left"
              :title "Shared Mech above JavaScript"
              :summary "Shared Mech appears above the JavaScript region."
              :layer :layout
              :subject :shared-mech
              :predicate :above
              :object :lefty-javascript)
             (make-snippet-playground-authored-relation
              :id "layout/comparison/shared-mech-above-right"
              :title "Shared Mech above Lisp"
              :summary "Shared Mech appears above the Lisp region."
              :layer :layout
              :subject :shared-mech
              :predicate :above
              :object :rita-lisp)
             (make-snippet-playground-authored-relation
              :id "layout/comparison/show-once"
              :title "Comparison shows shared Mech once"
              :summary "Shared Mech renders once above the code comparison."
              :layer :layout
              :subject :comparison-pane
              :predicate :show-once
              :object :shared-mech)
             (make-snippet-playground-authored-relation
              :id "layout/projection/lefty"
              :title "Lefty renders JavaScript"
              :summary "Lefty projection renders JavaScript on the left."
              :layer :layout
              :subject :lefty-javascript
              :predicate :renders
              :object :javascript-code
              :attributes '(:title "JavaScript"
                            :region left-code-region
                            :placement :left))
             (make-snippet-playground-authored-relation
              :id "layout/projection/shared-mech"
              :title "Shared Mech renders once above the split"
              :summary "Shared Mech renders once above JavaScript and Lisp."
              :layer :layout
              :subject :shared-mech
              :predicate :renders
              :object :shared-mech
              :attributes '(:title "Mech"
                            :region shared-mech-region
                            :placement :center))
             (make-snippet-playground-authored-relation
              :id "layout/projection/rita"
              :title "Rita renders Lisp"
              :summary "Rita projection renders Lisp on the right."
              :layer :layout
              :subject :rita-lisp
              :predicate :renders
              :object :lisp-code
              :attributes '(:title "Lisp"
                            :region right-code-region
                            :placement :right))))

(defun make-snippet-playground-authored-role
    (&key id title summary kind binding participants findings)
  (make-instance
   'snippet-playground-authored-role
   :id id
   :title title
   :summary summary
   :kind kind
   :binding binding
   :participants participants
   :findings findings))

(defun make-snippet-playground-authored-roles ()
  (list
   (make-snippet-playground-authored-role
    :id "role/selected-mech-snippet"
    :title "Selected Mech snippet"
    :summary "Evidence input chosen from the origin surface."
    :kind :evidence-input
    :binding :selected-mech-snippet)
   (make-snippet-playground-authored-role
    :id "role/selected-javascript-snippet"
    :title "Selected JavaScript snippet"
    :summary "Executable evidence input chosen from the origin surface."
    :kind :evidence-input
    :binding :selected-javascript-snippet)
   (make-snippet-playground-authored-role
    :id "role/derived-lisp-snippet"
    :title "Derived Lisp snippet"
    :summary "Rita-side scaffold derived from the selected evidence and interface."
    :kind :derived-output
    :binding :derived-lisp-snippet)
   (make-snippet-playground-authored-role
    :id "role/transformation-unit"
    :title "Transformation unit"
    :summary "Primary semantic artifact that binds evidence to the execution interface."
    :kind :semantic-artifact
    :binding :transformation-unit)
   (make-snippet-playground-authored-role
    :id "role/execution-interface"
    :title "Execution interface"
    :summary "Operational handoff such as state.items."
    :kind :semantic-artifact
    :binding :execution-interface)
   (make-snippet-playground-authored-role
    :id "role/lefty-pair"
    :title "Lefty pair"
    :summary "Representational pair combining Mech with JavaScript."
    :kind :comparison-pair
    :binding :lefty-pair
    :participants '(:selected-mech-snippet :selected-javascript-snippet))
   (make-snippet-playground-authored-role
    :id "role/rita-pair"
    :title "Rita pair"
    :summary "Representational pair combining Mech with Lisp."
    :kind :comparison-pair
    :binding :rita-pair
    :participants '(:selected-mech-snippet :derived-lisp-snippet))))

(defun snippet-playground-authored-artifact-findings ()
  '("Authored relation artifact stays separate from compiler/runtime glue."
    "Behavior and layout compile independently from the same authored artifact."
    "Lefty/Rita remain representational pairs; transformation unit remains the primary semantic artifact."))

(defun make-snippet-playground-authored-artifact ()
  (let* ((relations (make-snippet-playground-authored-graph))
         (semantic-relations
           (remove-if-not
            (lambda (relation)
              (eq (snippet-playground-authored-relation-layer-of relation)
                  :semantic))
            relations))
         (behavior-relations
           (remove-if-not
            (lambda (relation)
              (eq (snippet-playground-authored-relation-layer-of relation)
                  :behavior))
            relations))
         (layout-relations
           (remove-if-not
            (lambda (relation)
              (eq (snippet-playground-authored-relation-layer-of relation)
                  :layout))
            relations)))
    (make-instance
     'snippet-playground-authored-artifact
     :id "snippet-playground-authored-artifact"
     :title "Snippet playground authored relation artifact"
     :summary
     "Authored relation artifact that compiles into snippet-playground behavior and layout artifacts."
     :artifact-kind :authored-relation-artifact
     :workflow-role
     "Graph-authored reconstruction surface for snippet-playground."
     :compiler-pipeline
     "authored relation artifact -> compiled behavior artifact + compiled layout artifact -> runtime snippet-playground UI"
     :semantic-roles (make-snippet-playground-authored-roles)
     :semantic-relations semantic-relations
     :behavior-relations behavior-relations
     :layout-relations layout-relations
     :relations relations
     :compiled-targets
     '("snippet-playground-behavior-artifact"
       "snippet-playground-layout-artifact")
     :findings (snippet-playground-authored-artifact-findings))))

(setf *snippet-playground-authored-artifact*
      (make-snippet-playground-authored-artifact))

(defun snippet-playground-authored-artifact ()
  *snippet-playground-authored-artifact*)

(defun snippet-playground-authored-relations
    (&optional (artifact (snippet-playground-authored-artifact)))
  (snippet-playground-authored-artifact-relations-of artifact))

(defun snippet-playground-authored-roles
    (&optional (artifact (snippet-playground-authored-artifact)))
  (snippet-playground-authored-artifact-semantic-roles-of artifact))

(defun snippet-playground-relations-by-layer
    (layer &optional (artifact (snippet-playground-authored-artifact)))
  (authored-relation-artifact-relations-by-layer artifact layer))

(defun snippet-playground-machine-relations
    (machine-key predicate &optional (artifact (snippet-playground-authored-artifact)))
  (remove-if-not
   (lambda (relation)
     (and (eq (snippet-playground-authored-relation-layer-of relation) :behavior)
          (eq (snippet-playground-authored-relation-subject-of relation)
              machine-key)
          (eq (snippet-playground-authored-relation-predicate-of relation)
              predicate)))
   (snippet-playground-authored-relations artifact)))

(defun snippet-playground-transition-relations
    (machine-key &optional (artifact (snippet-playground-authored-artifact)))
  (remove-if-not
   (lambda (relation)
     (and (eq (snippet-playground-authored-relation-layer-of relation) :behavior)
          (eq (snippet-playground-authored-relation-predicate-of relation)
              :transition-to)
          (eq (snippet-playground-authored-relation-attribute relation :machine)
              machine-key)))
   (snippet-playground-authored-relations artifact)))

(defun snippet-playground-layout-relation-p (relation)
  (eq (snippet-playground-authored-relation-layer-of relation) :layout))

(defun snippet-playground-machine-state-from-relation (relation)
  (make-state-machine-state
   :id (snippet-playground-authored-relation-object-of relation)
   :title (or (snippet-playground-authored-relation-attribute relation :title)
              (string-downcase
               (string (snippet-playground-authored-relation-object-of relation))))
   :summary (snippet-playground-authored-relation-attribute relation :summary)
   :role (snippet-playground-authored-relation-attribute relation :role)
   :entry-condition
   (snippet-playground-authored-relation-attribute relation :entry-condition)
   :exit-condition
   (snippet-playground-authored-relation-attribute relation :exit-condition)
   :notes (snippet-playground-authored-relation-attribute relation :notes)))

(defun snippet-playground-machine-transition-from-relation (relation)
  (make-state-machine-transition
   :id (or (snippet-playground-authored-relation-attribute relation :id)
           (id-of relation))
   :title (snippet-playground-authored-relation-attribute relation :title)
   :from-state (snippet-playground-authored-relation-subject-of relation)
   :to-state (snippet-playground-authored-relation-object-of relation)
   :trigger (snippet-playground-authored-relation-attribute relation :trigger)
   :guard (snippet-playground-authored-relation-attribute relation :guard)
   :emitted-evidence
   (snippet-playground-authored-relation-attribute relation :emitted-evidence)
   :side-effects
   (snippet-playground-authored-relation-attribute relation :side-effects)
   :reversible-p
   (snippet-playground-authored-relation-attribute relation :reversible-p)
   :notes (snippet-playground-authored-relation-attribute relation :notes)))

(defun snippet-playground-machine-items
    (machine-key predicate &optional (artifact (snippet-playground-authored-artifact)))
  (mapcar #'snippet-playground-authored-relation-object-of
          (snippet-playground-machine-relations machine-key predicate artifact)))

(defun snippet-playground-machine-source-evidence
    (machine-key &optional (artifact (snippet-playground-authored-artifact)))
  (mapcar
   (lambda (relation)
     (list :layer (snippet-playground-authored-relation-attribute relation :layer)
           :reference (snippet-playground-authored-relation-object-of relation)
           :detail (snippet-playground-authored-relation-attribute relation :detail)))
   (snippet-playground-machine-relations machine-key :source-evidence artifact)))

(defun snippet-playground-machine-invariants
    (machine-key &optional (artifact (snippet-playground-authored-artifact)))
  (mapcar
   (lambda (relation)
     (list :label (snippet-playground-authored-relation-object-of relation)
           :detail (snippet-playground-authored-relation-attribute relation :detail)))
   (snippet-playground-machine-relations machine-key :has-invariant artifact)))

(defun compile-snippet-playground-machine
    (artifact machine-key machine-id title summary)
  (make-state-machine-definition
   :id machine-id
   :title title
   :summary summary
   :states
   (mapcar #'snippet-playground-machine-state-from-relation
           (snippet-playground-machine-relations machine-key :has-state artifact))
   :transitions
   (mapcar #'snippet-playground-machine-transition-from-relation
           (snippet-playground-transition-relations machine-key artifact))
   :initial-state
   (first (snippet-playground-machine-items machine-key :initial-state artifact))
   :terminal-states
   (snippet-playground-machine-items machine-key :terminal-state artifact)
   :failure-states
   (snippet-playground-machine-items machine-key :failure-state artifact)
   :guards
   (snippet-playground-machine-items machine-key :has-guard artifact)
   :events
   (snippet-playground-machine-items machine-key :has-event artifact)
   :invariants
   (snippet-playground-machine-invariants machine-key artifact)
   :source-evidence
   (snippet-playground-machine-source-evidence machine-key artifact)))

(defun snippet-playground-xml-escape (value)
  (let ((text (format nil "~A" value)))
    (with-output-to-string (stream)
      (loop for char across text
            do (write-string
                (case char
                  (#\< "&lt;")
                  (#\> "&gt;")
                  (#\& "&amp;")
                  (#\" "&quot;")
                  (t (string char)))
                stream)))))

(defun state-machine-definition-scxml-text (machine)
  (with-output-to-string (stream)
    (format stream
            "<scxml name=\"~A\" initial=\"~A\" xmlns=\"http://www.w3.org/2005/07/scxml\">~%"
            (snippet-playground-xml-escape (id-of machine))
            (snippet-playground-xml-escape
             (state-machine-definition-initial-state-of machine)))
    (dolist (state (state-machine-definition-states-of machine))
      (let* ((state-id (id-of state))
             (outgoing (state-machine-transitions-from-state machine state-id))
             (terminal-p
               (member state-id
                       (state-machine-definition-terminal-states-of machine)
                       :test #'equal)))
        (if (and terminal-p (null outgoing))
            (format stream "  <final id=\"~A\"/>~%"
                    (snippet-playground-xml-escape state-id))
            (progn
              (format stream "  <state id=\"~A\">~%"
                      (snippet-playground-xml-escape state-id))
              (dolist (transition outgoing)
                (format stream "    <transition")
                (when (state-machine-transition-trigger-of transition)
                  (format stream
                          " event=\"~A\""
                          (snippet-playground-xml-escape
                           (state-machine-transition-trigger-of transition))))
                (when (state-machine-transition-guard-of transition)
                  (format stream
                          " cond=\"~A\""
                          (snippet-playground-xml-escape
                           (state-machine-transition-guard-of transition))))
                (format stream
                        " target=\"~A\"/>~%"
                        (snippet-playground-xml-escape
                         (state-machine-transition-to-state-of transition))))
              (format stream "  </state>~%")))))
    (write-string "</scxml>" stream)))

(defun snippet-playground-layout-artifact-findings (relations)
  (declare (ignore relations))
  '("Compiled pane placement and comparison layout now derive from authored snippet relations."
    "Comparison layout keeps JavaScript left, shared Mech center, and Lisp right without duplicating Mech."))

(defun snippet-playground-behavior-artifact-findings ()
  '("Behavior artifact compiles directly from the authored relation artifact."
    "Run lifecycle and comparison lifecycle remain separate machines with separate SCXML text."))

(defun compile-snippet-playground-layout-spec (relations)
  (let* ((comparison-relations
           (remove-if-not
            (lambda (relation)
              (member (snippet-playground-authored-relation-predicate-of relation)
                      '(:contains-left :contains-center :contains-right :show-once
                        :above :renders)
                      :test #'eq))
            relations))
         (render-relations
           (remove-if-not
            (lambda (relation)
              (eq (snippet-playground-authored-relation-predicate-of relation)
                  :renders))
            comparison-relations))
         (region-relations
           (remove-if-not
            (lambda (relation)
              (member (snippet-playground-authored-relation-predicate-of relation)
                      '(:contains-left :contains-center :contains-right)
                      :test #'eq))
            comparison-relations))
         (above-relations
           (remove-if-not
            (lambda (relation)
              (eq (snippet-playground-authored-relation-predicate-of relation)
                  :above))
            comparison-relations))
         (placement-order '(:contains-center :contains-left :contains-right))
         (regions
           (loop for predicate in placement-order
                 for relation = (find predicate
                                      region-relations
                                      :key
                                      #'snippet-playground-authored-relation-predicate-of
                                      :test #'eq)
                 for component = (and relation
                                      (snippet-playground-authored-relation-object-of
                                       relation))
                 for render = (and component
                                   (find component
                                         render-relations
                                         :key
                                         #'snippet-playground-authored-relation-subject-of
                                         :test #'eq))
                 for top-band-p = (and component
                                       (find component
                                             above-relations
                                             :key
                                             #'snippet-playground-authored-relation-subject-of
                                             :test #'eq))
                 when render
                   collect
                   (list (ecase predicate
                           (:contains-left :left)
                           (:contains-center :center)
                           (:contains-right :right))
                         :region
                         (snippet-playground-authored-relation-attribute
                          render
                          :region)
                         :content
                         (snippet-playground-authored-relation-object-of render)
                         :title
                         (snippet-playground-authored-relation-attribute
                          render
                          :title)
                         :row (if top-band-p 1 2)
                         :column (ecase predicate
                                   (:contains-left 1)
                                   (:contains-center 1)
                                   (:contains-right 2))
                         :column-span (if top-band-p 2 1))))
         (rules
           (loop for relation in comparison-relations
                 when (eq (snippet-playground-authored-relation-predicate-of relation)
                          :show-once)
                   collect
                   (list :show-once
                         (snippet-playground-authored-relation-object-of
                          relation)))))
    (list :surface 'snippet-comparison
          :regions regions
          :relations
          (mapcar
           (lambda (relation)
             (list (snippet-playground-authored-relation-predicate-of relation)
                   (snippet-playground-authored-relation-subject-of relation)
                   (snippet-playground-authored-relation-object-of relation)))
           comparison-relations)
          :rules rules)))

(defun snippet-comparison-layout-artifact ()
  (or *snippet-playground-layout-artifact*
      (let* ((authored-artifact (snippet-playground-authored-artifact))
             (relations
               (snippet-playground-authored-artifact-layout-relations-of
                authored-artifact))
             (pane-relations
               (remove-if-not
                (lambda (relation)
                  (member (snippet-playground-authored-relation-predicate-of relation)
                          '(:right-of :below :replaces)
                          :test #'eq))
                relations))
             (comparison-relations
               (remove-if-not
                (lambda (relation)
                  (member (snippet-playground-authored-relation-predicate-of relation)
                          '(:contains-left :contains-center :contains-right
                            :show-once :above :renders)
                          :test #'eq))
                relations)))
        (setf *snippet-playground-layout-artifact*
              (make-instance
               'snippet-playground-layout-artifact
               :id "snippet-playground-layout"
               :title "Snippet playground layout"
               :summary
               "Compiled pane-placement and comparison-layout artifact for snippet-playground."
               :artifact-kind :compiled-layout-artifact
               :authored-artifact authored-artifact
               :compiler-stage :layout-compilation
               :compiler-inputs (list authored-artifact)
               :relations relations
               :pane-relations pane-relations
               :comparison-relations comparison-relations
               :layout-spec
               (compile-snippet-playground-layout-spec relations)
               :findings
               (snippet-playground-layout-artifact-findings relations))))))

(defun snippet-comparison-layout-spec ()
  (snippet-playground-layout-artifact-comparison-layout-spec-of
   (snippet-comparison-layout-artifact)))

(defun snippet-playground-behavior-artifact ()
  (or *snippet-playground-behavior-artifact*
      (let* ((authored-artifact (snippet-playground-authored-artifact))
             (relations
               (snippet-playground-authored-artifact-behavior-relations-of
                authored-artifact))
             (run-machine
               (compile-snippet-playground-machine
                authored-artifact
                :snippet-playground-run
                "snippet_playground_run"
                "snippet_playground_run"
                "Origin-aware snippet-playground lifecycle shared by html-source and fedwiki-page providers."))
             (comparison-machine
               (compile-snippet-playground-machine
                authored-artifact
                :snippet-comparison-surface
                "snippet_comparison_surface"
                "snippet_comparison_surface"
                "Small lifecycle for the declarative snippet comparison surface.")))
        (setf *snippet-playground-behavior-artifact*
              (make-instance
               'snippet-playground-behavior-artifact
               :id "snippet-playground-behavior-artifact"
               :title "Snippet playground behavior"
               :summary
               "Compiled lifecycle artifact for snippet-playground and its comparison surface."
               :artifact-kind :compiled-behavior-artifact
               :authored-artifact authored-artifact
               :compiler-stage :behavior-compilation
               :compiler-inputs (list authored-artifact)
               :relations relations
               :primary-machine run-machine
               :primary-machine-scxml
               (state-machine-definition-scxml-text run-machine)
               :related-machines
               (list (cons :comparison-surface comparison-machine))
               :related-machine-scxml
               (list
                (cons :comparison-surface
                      (state-machine-definition-scxml-text comparison-machine)))
               :findings (snippet-playground-behavior-artifact-findings))))))

(defun snippet-playground-run-state-machine ()
  (snippet-playground-behavior-artifact-run-machine-of
   (snippet-playground-behavior-artifact)))

(defun snippet-playground-run-state-machine-scxml-text ()
  (snippet-playground-behavior-artifact-run-machine-scxml-of
   (snippet-playground-behavior-artifact)))

(defun snippet-comparison-surface-lifecycle-state-machine ()
  (snippet-playground-behavior-artifact-comparison-machine-of
   (snippet-playground-behavior-artifact)))

(defun snippet-comparison-surface-lifecycle-state-machine-scxml-text ()
  (snippet-playground-behavior-artifact-comparison-machine-scxml-of
   (snippet-playground-behavior-artifact)))

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
      :surface_layout (snippet-comparison-layout-spec))
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

(defun snippet-playground-bounded-source-text
    (source &key (limit *snippet-playground-inline-source-render-limit*))
  (let* ((text (or source ""))
         (bounded-limit (max 0 limit))
         (original-length (length text))
         (truncated-p (> original-length bounded-limit))
         (excerpt (if truncated-p
                      (subseq text 0 bounded-limit)
                      text)))
    (values excerpt original-length truncated-p)))

(defun snippet-playground-inline-truncation-note
    (shown-length original-length)
  (format nil
          "Inline source view truncated to ~D of ~D characters. Full source remains inspectable on the underlying object."
          shown-length
          original-length))

(defun snippet-playground-scaffold-truncation-note
    (shown-length original-length)
  (format nil
          "Embedded JavaScript excerpt truncated to ~D of ~D characters for scaffold safety."
          shown-length
          original-length))

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
  (multiple-value-bind (excerpt original-length truncated-p)
      (snippet-playground-bounded-source-text
       (code-snippet-source-of code)
       :limit *snippet-playground-scaffold-source-excerpt-limit*)
    (with-output-to-string (stream)
      (format stream ";; Translation scaffold for the recognized JavaScript CODE block.~%")
      (format stream ";; Full JavaScript remains inspectable on the selected code snippet.~%")
      (format stream ";; Original JavaScript length: ~D characters.~%" original-length)
      (when truncated-p
        (format stream ";; ~A~%"
                (snippet-playground-scaffold-truncation-note
                 (length excerpt)
                 original-length)))
      (format stream "(let* ((session *)~%")
      (format stream "       (original-javascript-excerpt ~S)~%" excerpt)
      (format stream "       (original-javascript-length ~D)~%" original-length)
      (format stream "       (original-javascript-excerpt-truncated-p ~S))~%"
              truncated-p)
      (format stream "  (declare (ignore original-javascript-excerpt~%")
      (format stream "                   original-javascript-length~%")
      (format stream "                   original-javascript-excerpt-truncated-p))~%")
      (format stream "  ;; Inspect (hyperdoc::snippet-playground-session-selected-code-of session) for the full JavaScript block.~%")
      (format stream "  ;; Unsupported JavaScript should surface an explicit translation error, not a fake rewrite.~%")
      (format stream "  (setf (hyperdoc::snippet-playground-session-derived-items-of session)~%")
      (format stream "        (list (list :type \"translation-error\"~%")
      (format stream "                    :report \"Unsupported JavaScript construct for the current snippet-playground translator.\"~%")
      (format stream "                    :source-length original-javascript-length~%")
      (format stream "                    :source-excerpt original-javascript-excerpt~%")
      (format stream "                    :source-excerpt-truncated-p original-javascript-excerpt-truncated-p)))~%")
      (format stream "  (hyperdoc::snippet-playground-session-derived-items-of session))~%"))))

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

(defun snippet-comparison-region-raw-source
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

(defun make-snippet-comparison-region-display-source
    (content-key mech code lisp-source)
  (snippet-playground-bounded-source-text
   (snippet-comparison-region-raw-source content-key mech code lisp-source)
   :limit *snippet-playground-inline-source-render-limit*))

(defun make-snippet-comparison-region
    (region-id placement content-key title mech code lisp-source)
  (multiple-value-bind (source-text original-length truncated-p)
      (make-snippet-comparison-region-display-source
       content-key
       mech
       code
       lisp-source)
    (make-instance
     'snippet-comparison-region
     :id (format nil "snippet-comparison-region/~A" region-id)
     :title title
     :summary (format nil "~A region of the snippet comparison surface." title)
     :placement placement
     :content-key content-key
     :source-text source-text
     :source-original-length original-length
     :source-truncated-p truncated-p
     :findings
     (append
      (list
       (format nil
               "Region ~A renders ~A on the comparison surface."
               title
               (string-downcase (string content-key))))
      (when truncated-p
        (list (snippet-playground-inline-truncation-note
               (length source-text)
               original-length)))))))

(defun snippet-comparison-surface-findings (execution-interface)
  (let ((findings '("Comparison surface renders shared Mech once above JavaScript left and Lisp right.")))
    (when execution-interface
      (push (format nil
                    "Execution interface ~A remains visible in the compact transformation-unit block."
                    (snippet-execution-interface-handoff-path-of
                     execution-interface))
            findings))
    (nreverse findings)))

(defparameter *snippet-comparison-supported-placements*
  '(:center :left :right))

(defun snippet-comparison-default-region-title (placement)
  (ecase placement
    (:center "Mech")
    (:left "JavaScript")
    (:right "Lisp")))

(defun snippet-comparison-default-content-key (placement)
  (ecase placement
    (:center 'shared-mech)
    (:left 'javascript-code)
    (:right 'lisp-code)))

(defun normalize-snippet-comparison-region-spec (region-spec)
  (let ((placement (first region-spec)))
    (list placement
          :region (or (snippet-comparison-layout-region-attribute region-spec
                                                                  :region)
                      (ecase placement
                        (:center 'shared-mech-region)
                        (:left 'left-code-region)
                        (:right 'right-code-region)))
          :content (or (snippet-comparison-layout-region-attribute region-spec
                                                                   :content)
                       (snippet-comparison-default-content-key placement))
          :title (or (snippet-comparison-layout-region-attribute region-spec
                                                                 :title)
                     (snippet-comparison-default-region-title placement))
          :row (ecase placement
                 (:center 1)
                 (:left 2)
                 (:right 2))
          :column (ecase placement
                    (:center 1)
                    (:left 1)
                    (:right 2))
          :column-span (ecase placement
                         (:center 2)
                         (:left 1)
                         (:right 1)))))

(defun normalize-snippet-comparison-layout-spec (layout-spec)
  (let* ((region-specs (snippet-comparison-layout-region-specs layout-spec))
         (normalized-regions
           (loop for placement in *snippet-comparison-supported-placements*
                 for match = (find placement
                                   region-specs
                                   :key #'car
                                   :test #'eq)
                 when match
                   collect (normalize-snippet-comparison-region-spec match)))
         (ignored-region-count
           (max 0 (- (length region-specs)
                     (length normalized-regions))))
         (findings '()))
    (when (> ignored-region-count 0)
      (push (format nil
                    "Comparison layout ignored ~D malformed or duplicate region entr~:@P and degraded to the supported center/left/right placements."
                    ignored-region-count)
            findings))
    (values
     (list :surface (getf layout-spec :surface)
           :regions normalized-regions
           :relations (getf layout-spec :relations)
           :rules (getf layout-spec :rules))
     (nreverse findings))))

(defun make-snippet-comparison-surface
    (&key status source-label mech code lisp-source execution-interface
       transformation-unit origin-pane-id pending-pane-id
       failure-classification)
  (let* ((layout-artifact (snippet-comparison-layout-artifact))
         (raw-layout-spec
           (snippet-playground-layout-artifact-comparison-layout-spec-of
            layout-artifact))
         (normalized-layout-spec nil)
         (layout-findings nil)
         (left-region
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
    (multiple-value-setq (normalized-layout-spec layout-findings)
      (normalize-snippet-comparison-layout-spec raw-layout-spec))
    (make-instance
     'snippet-comparison-surface
     :id (format nil "snippet-comparison-surface/~A"
                 (or source-label "surface"))
     :title "Snippet comparison"
     :summary
     "Three-region comparison surface with JavaScript, shared Mech, and Lisp."
     :layout-spec normalized-layout-spec
     :layout-artifact layout-artifact
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
     (append (snippet-comparison-surface-findings execution-interface)
             layout-findings))))

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
         (authored-artifact (snippet-playground-authored-artifact))
         (behavior-artifact (snippet-playground-behavior-artifact))
         (layout-artifact (snippet-comparison-layout-artifact))
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
                     :authored-artifact authored-artifact
                     :behavior-artifact behavior-artifact
                     :layout-artifact layout-artifact
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
                     :input-collected
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
                           :transformation-unit-built
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
                       :authored-artifact
                       (snippet-playground-session-authored-artifact-of session)
                       :behavior-artifact
                       (snippet-playground-session-behavior-artifact-of session)
                       :layout-artifact
                       (snippet-playground-session-layout-artifact-of session)
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

(defun snippet-source-pre
    (source
     &key
       (limit *snippet-playground-inline-source-render-limit*)
       original-length
       truncated-p)
  (multiple-value-bind (excerpt effective-original-length effective-truncated-p)
      (if (or original-length truncated-p)
          (values (or source "")
                  (or original-length (length (or source "")))
                  truncated-p)
          (snippet-playground-bounded-source-text source :limit limit))
    (html-inspector-views:html
      (:div :class "hyperdoc-snippet-source-view"
            (when effective-truncated-p
              (html-inspector-views:html
                (:p :class "hyperdoc-snippet-source-boundary"
                    (html-inspector-views:esc
                     (snippet-playground-inline-truncation-note
                      (length excerpt)
                      effective-original-length)))))
            (:pre :style "white-space: pre-wrap"
                  (html-inspector-views:esc excerpt))))))

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

(defun snippet-comparison-layout-region-attribute (region-spec key)
  (getf (rest region-spec) key))

(defun snippet-comparison-region-css-class (placement)
  (format nil
          "hyperdoc-snippet-comparison-region hyperdoc-snippet-comparison-~(~A~)"
          placement))

(defun snippet-playground-view-transformation-row (label value)
  (snippet-playground-status-table-row label value))

(defun snippet-comparison-render-region-style (region-spec)
  (format nil
          "min-width: 0; grid-row: ~D; grid-column: ~D / span ~D;"
          (or (snippet-comparison-layout-region-attribute region-spec :row) 1)
          (or (snippet-comparison-layout-region-attribute region-spec :column) 1)
          (or (snippet-comparison-layout-region-attribute region-spec :column-span)
              1)))

(defun snippet-comparison-render-region (region region-spec)
  (html-inspector-views:html
    (:div :class (snippet-comparison-region-css-class
                  (snippet-comparison-region-placement-of region))
          :style (snippet-comparison-render-region-style region-spec)
          (:h3 (html-inspector-views:esc (title-of region)))
          (snippet-source-pre
           (snippet-comparison-region-source-text-of region)
           :original-length
           (snippet-comparison-region-source-original-length-of region)
           :truncated-p
           (snippet-comparison-region-source-truncated-p region)))))

(defun snippet-comparison-layout-column-count (layout-spec)
  (loop for region-spec in (snippet-comparison-layout-region-specs layout-spec)
        maximize (+ (or (snippet-comparison-layout-region-attribute region-spec
                                                                    :column)
                        1)
                    (1- (or (snippet-comparison-layout-region-attribute region-spec
                                                                        :column-span)
                            1)))))

(defun snippet-comparison-visible-regions (surface)
  (let ((shown-content-keys '())
        (layout-spec (snippet-comparison-surface-layout-spec-of surface))
        (show-once-keys
          (snippet-comparison-layout-show-once-content-keys
           (snippet-comparison-surface-layout-spec-of surface)))
        (visible '()))
    (dolist (region-spec (snippet-comparison-layout-region-specs layout-spec)
                         (nreverse visible))
      (let* ((placement (first region-spec))
             (region
               (snippet-comparison-surface-region-for-placement
                surface
                placement))
             (content-key
               (and region
                    (snippet-comparison-region-content-key-of region))))
        (when (and region
                   (not (and (member content-key
                                     show-once-keys
                                     :test #'eq)
                             (member content-key
                                     shown-content-keys
                                     :test #'eq))))
          (push content-key shown-content-keys)
          (push (cons region region-spec) visible))))))

(defun snippet-comparison-layout-grid-column-count (layout-spec)
  (min 3
       (max 1
            (or (snippet-comparison-layout-column-count layout-spec)
                1))))

(defun snippet-playground-log-comparison-render (phase &rest pairs)
  (format *trace-output*
          "~&[SNIPPET-COMPARISON-PERF] ~A"
          phase)
  (loop for (key value) on pairs by #'cddr
        do (format *trace-output* " ~A=~S" key value))
  (terpri *trace-output*)
  (finish-output *trace-output*))

(defun snippet-playground-render-html-fragment-to-string-and-accumulator (thunk)
  (let ((accumulator (make-instance 'html-inspector-views::view-accumulator)))
    (values
     (with-output-to-string (stream)
       (let ((html-inspector-views::*html-stream* stream)
             (html-inspector-views::*view-accumulator* accumulator))
         (funcall thunk)))
     accumulator)))

(defun snippet-playground-render-html-fragment-to-string (thunk)
  (multiple-value-bind (html accumulator)
      (snippet-playground-render-html-fragment-to-string-and-accumulator thunk)
    (declare (ignore accumulator))
    html))

(defun snippet-playground-merge-rendered-html-into-current-render
    (html accumulator)
  (declare (ignore accumulator))
  (write-string html html-inspector-views::*html-stream*)
  html)

(defun snippet-comparison-layout-style (column-count)
  (format nil
          "display: grid; grid-template-columns: ~{~A~^ ~}; gap: 1rem; align-items: start;"
          (make-list column-count
                     :initial-element "minmax(0, 1fr)")))

(defun snippet-comparison-render-transformation-unit (surface)
  (html-inspector-views:html
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
                   "No transformation unit is available for this session.")))))))

(defun snippet-comparison-render-surface (surface)
  (let* ((layout-spec (snippet-comparison-surface-layout-spec-of surface))
         (visible-regions (snippet-comparison-visible-regions surface))
         (column-count
           (snippet-comparison-layout-grid-column-count layout-spec)))
    (write-string
     "<div class=\"hyperdoc-snippet-comparison\">"
     html-inspector-views::*html-stream*)
    (write-string
     (format nil
             "<div class=\"hyperdoc-snippet-comparison-layout\" style=\"~A\">"
             (snippet-comparison-layout-style column-count))
     html-inspector-views::*html-stream*)
    (dolist (entry visible-regions)
      (let* ((region (car entry))
             (placement (snippet-comparison-region-placement-of region)))
        (snippet-playground-log-comparison-render
         "REGION-START"
         :placement placement)
        (snippet-comparison-render-region
         region
         (cdr entry))
        (snippet-playground-log-comparison-render
         "REGION-DONE"
         :placement placement)))
    (write-string "</div>" html-inspector-views::*html-stream*)
    (snippet-playground-log-comparison-render
     "TRANSFORMATION-START")
    (snippet-comparison-render-transformation-unit surface)
    (snippet-playground-log-comparison-render
     "TRANSFORMATION-DONE")
    (write-string "</div>" html-inspector-views::*html-stream*)))

(defun snippet-playground-render-comparison-surface-into-current-view (surface)
  (let* ((layout-spec (snippet-comparison-surface-layout-spec-of surface))
         (visible-regions (snippet-comparison-visible-regions surface))
         (normalized-placements
           (mapcar #'first
                   (snippet-comparison-layout-region-specs layout-spec)))
         (visible-placements
           (mapcar (lambda (entry)
                     (snippet-comparison-region-placement-of (car entry)))
                   visible-regions))
         (column-count
           (snippet-comparison-layout-grid-column-count layout-spec)))
    (snippet-playground-log-comparison-render
     "MATERIALIZE-START"
     :visible-region-count (length visible-regions)
     :normalized-placements normalized-placements
     :visible-placements visible-placements
     :column-count column-count)
    (multiple-value-bind (html accumulator)
        (handler-case
            (snippet-playground-render-html-fragment-to-string-and-accumulator
             (lambda ()
               (snippet-comparison-render-surface surface)))
          (storage-condition (condition)
            (snippet-playground-log-comparison-render
             "MATERIALIZE-FAILED"
             :visible-region-count (length visible-regions)
             :normalized-placements normalized-placements
             :visible-placements visible-placements
             :column-count column-count
             :condition condition)
            (error condition)))
      (snippet-playground-log-comparison-render
       "MATERIALIZE-DONE"
       :visible-region-count (length visible-regions)
       :normalized-placements normalized-placements
       :visible-placements visible-placements
       :column-count column-count
       :html-length (length html))
      (handler-case
          (progn
            (snippet-playground-log-comparison-render
             "INSERT-START"
             :html-length (length html))
            (snippet-playground-merge-rendered-html-into-current-render
             html
             accumulator)
            (snippet-playground-log-comparison-render
             "INSERT-DONE"
             :html-length (length html)))
        (storage-condition (condition)
          (snippet-playground-log-comparison-render
           "INSERT-FAILED"
           :html-length (length html)
           :condition condition)
          (error condition))))))

(defun snippet-playground-authored-relation-line (relation)
  (format nil "~(~A~) ~(~A~) ~(~A~)"
          (snippet-playground-authored-relation-subject-of relation)
          (snippet-playground-authored-relation-predicate-of relation)
          (snippet-playground-authored-relation-object-of relation)))

(defun snippet-playground-layout-relation-lines (relations)
  (mapcar #'snippet-playground-authored-relation-line relations))

(html-inspector-views:defview snippet-playground-authored-role-summary
    (role snippet-playground-authored-role)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of role)))
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Kind"
               (snippet-playground-authored-role-kind-of role))
              (snippet-playground-status-table-row
               "Binding"
               (snippet-playground-authored-role-binding-of role))
              (snippet-playground-status-table-row
               "Participants"
               (or (snippet-playground-authored-role-participants-of role)
                   "n/a")))
      (when (snippet-playground-authored-role-findings-of role)
        (html-inspector-views:html
          (:h3 "Findings")
          (:ul
           (dolist (finding (snippet-playground-authored-role-findings-of role))
             (html-inspector-views:html
               (:li (html-inspector-views:esc finding))))))))))

(html-inspector-views:defview snippet-playground-authored-relation-summary
    (relation snippet-playground-authored-relation)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Layer"
               (snippet-playground-authored-relation-layer-of relation))
              (snippet-playground-status-table-row
               "Subject"
               (snippet-playground-authored-relation-subject-of relation))
              (snippet-playground-status-table-row
               "Predicate"
               (snippet-playground-authored-relation-predicate-of relation))
              (snippet-playground-status-table-row
               "Object"
               (snippet-playground-authored-relation-object-of relation)))
      (when (snippet-playground-authored-relation-attributes-of relation)
        (html-inspector-views:html
          (:h3 "Attributes")
          (:pre :style "white-space: pre-wrap"
                (html-inspector-views:esc
                 (format nil "~S"
                         (snippet-playground-authored-relation-attributes-of
                          relation)))))))))

(html-inspector-views:defview snippet-playground-authored-artifact-summary
    (artifact snippet-playground-authored-artifact)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:div :class "hyperdoc-snippet-authored-artifact"
            :data-hyperdoc-snippet-authored-artifact "true"
            (:p (html-inspector-views:esc (summary-of artifact)))
            (:table :class "inspector-table"
                    (snippet-playground-status-table-row
                     "Kind"
                     (snippet-playground-authored-artifact-kind-of artifact))
                    (snippet-playground-status-table-row
                     "Workflow role"
                     (snippet-playground-authored-artifact-workflow-role-of
                      artifact))
                    (snippet-playground-status-table-row
                     "Compiler pipeline"
                     (snippet-playground-authored-artifact-compiler-pipeline-of
                      artifact))
                    (snippet-playground-status-table-row
                     "Semantic roles"
                     (length
                      (snippet-playground-authored-artifact-semantic-roles-of
                       artifact)))
                    (snippet-playground-status-table-row
                     "Behavior relations"
                     (length
                      (snippet-playground-authored-artifact-behavior-relations-of
                       artifact)))
                    (snippet-playground-status-table-row
                     "Layout relations"
                     (length
                      (snippet-playground-authored-artifact-layout-relations-of
                       artifact))))
            (:h3 "Compiled targets")
            (:ul
             (dolist (target
                      (snippet-playground-authored-artifact-compiled-targets-of
                       artifact))
               (html-inspector-views:html
                 (:li (html-inspector-views:esc target)))))
            (:h3 "Findings")
            (:ul
             (dolist (finding
                      (snippet-playground-authored-artifact-findings-of artifact))
               (html-inspector-views:html
                 (:li (html-inspector-views:esc finding)))))))))

(html-inspector-views:defview snippet-playground-authored-artifact-semantic-roles
    (artifact snippet-playground-authored-artifact)
  (html-inspector-views:html-view :title "Semantic roles" :priority 2
    (html-inspector-views:html
      (:ul
       (dolist (role
                (snippet-playground-authored-artifact-semantic-roles-of artifact))
         (html-inspector-views:html
           (:li (html-inspector-views:object-ref role))))))))

(html-inspector-views:defview snippet-playground-authored-artifact-behavior-relations
    (artifact snippet-playground-authored-artifact)
  (html-inspector-views:html-view :title "Behavior relations" :priority 3
    (html-inspector-views:html
      (:ul
       (dolist (relation
                (snippet-playground-authored-artifact-behavior-relations-of
                 artifact))
         (html-inspector-views:html
           (:li (html-inspector-views:object-ref relation))))))))

(html-inspector-views:defview snippet-playground-authored-artifact-layout-relations
    (artifact snippet-playground-authored-artifact)
  (html-inspector-views:html-view :title "Layout relations" :priority 4
    (html-inspector-views:html
      (:ul
       (dolist (relation
                (snippet-playground-authored-artifact-layout-relations-of
                 artifact))
         (html-inspector-views:html
           (:li (html-inspector-views:object-ref relation))))))))

(html-inspector-views:defview snippet-playground-behavior-artifact-summary
    (artifact snippet-playground-behavior-artifact)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:div :class "hyperdoc-snippet-behavior-artifact"
            :data-hyperdoc-snippet-behavior-artifact "true"
            (:p (html-inspector-views:esc (summary-of artifact)))
            (:table :class "inspector-table"
                    (maybe-object-ref-row
                     "Authored artifact"
                     (snippet-playground-behavior-artifact-authored-artifact-of
                      artifact))
                    (maybe-object-ref-row
                     "Run machine"
                     (snippet-playground-behavior-artifact-run-machine-of
                      artifact))
                    (maybe-object-ref-row
                     "Comparison machine"
                     (snippet-playground-behavior-artifact-comparison-machine-of
                      artifact))
                    (snippet-playground-status-table-row
                     "Behavior relations"
                     (length
                      (snippet-playground-behavior-artifact-relations-of
                       artifact))))
            (:h3 "Findings")
            (:ul
             (dolist (finding
                      (snippet-playground-behavior-artifact-findings-of artifact))
               (html-inspector-views:html
                 (:li (html-inspector-views:esc finding)))))))))

(html-inspector-views:defview snippet-playground-behavior-artifact-relations
    (artifact snippet-playground-behavior-artifact)
  (html-inspector-views:html-view :title "Relations" :priority 2
    (html-inspector-views:html
      (:ul
       (dolist (relation (snippet-playground-behavior-artifact-relations-of
                          artifact))
         (html-inspector-views:html
           (:li (html-inspector-views:object-ref relation))))))))

(html-inspector-views:defview snippet-playground-behavior-artifact-scxml
    (artifact snippet-playground-behavior-artifact)
  (html-inspector-views:html-view :title "SCXML" :priority 3
    (html-inspector-views:html
      (:h3 "Run machine")
      (:pre :style "white-space: pre-wrap"
            :data-hyperdoc-snippet-machine-scxml "true"
            (html-inspector-views:esc
             (snippet-playground-behavior-artifact-run-machine-scxml-of
              artifact)))
      (:h3 "Comparison machine")
      (:pre :style "white-space: pre-wrap"
            :data-hyperdoc-snippet-comparison-machine-scxml "true"
            (html-inspector-views:esc
             (snippet-playground-behavior-artifact-comparison-machine-scxml-of
              artifact))))))

(html-inspector-views:defview snippet-playground-layout-artifact-summary
    (artifact snippet-playground-layout-artifact)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:div :class "hyperdoc-snippet-layout-artifact"
            :data-hyperdoc-snippet-layout-artifact "true"
            (:p (html-inspector-views:esc (summary-of artifact)))
            (:table :class "inspector-table"
                    (maybe-object-ref-row
                     "Authored artifact"
                     (snippet-playground-layout-artifact-authored-artifact-of
                      artifact))
                    (snippet-playground-status-table-row
                     "Pane relations"
                     (length
                      (snippet-playground-layout-artifact-pane-relations-of
                       artifact)))
                    (snippet-playground-status-table-row
                     "Comparison relations"
                     (length
                      (snippet-playground-layout-artifact-comparison-relations-of
                       artifact))))
            (:h3 "Relations")
            (:pre :style "white-space: pre-wrap"
                  (html-inspector-views:esc
                   (format nil
                           "~{~A~%~}"
                           (snippet-playground-layout-relation-lines
                            (snippet-playground-layout-artifact-relations-of
                             artifact)))))
            (:h3 "Compiled spec")
            (:pre :style "white-space: pre-wrap"
                  (html-inspector-views:esc
                   (format nil "~S"
                           (snippet-playground-layout-artifact-comparison-layout-spec-of
                            artifact))))))))

(html-inspector-views:defview snippet-playground-layout-artifact-details
    (artifact snippet-playground-layout-artifact)
    (html-inspector-views:html-view :title "Details" :priority 2
    (html-inspector-views:html
      (:table :class "inspector-table"
              (maybe-object-ref-row
               "Authored artifact"
               (snippet-playground-layout-artifact-authored-artifact-of
                artifact)))
      (:h3 "Pane placement")
      (:ul
       (dolist (relation
                (snippet-playground-layout-artifact-pane-relations-of artifact))
         (html-inspector-views:html
           (:li (html-inspector-views:object-ref relation)))))
      (:h3 "Comparison layout")
      (:ul
       (dolist (relation
                (snippet-playground-layout-artifact-comparison-relations-of
                 artifact))
         (html-inspector-views:html
           (:li (html-inspector-views:object-ref relation)))))
      (:h3 "Findings")
      (:ul
       (dolist (finding (snippet-playground-layout-artifact-findings-of artifact))
         (html-inspector-views:html
           (:li (html-inspector-views:esc finding))))))))

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
               (snippet-comparison-region-content-key-of region))
              (snippet-playground-status-table-row
               "Displayed characters"
               (length (snippet-comparison-region-source-text-of region)))
              (snippet-playground-status-table-row
               "Original characters"
               (snippet-comparison-region-source-original-length-of region))
              (snippet-playground-status-table-row
               "Truncated"
               (if (snippet-comparison-region-source-truncated-p region)
                   "yes"
                   "no")))
      (snippet-source-pre
       (snippet-comparison-region-source-text-of region)
       :original-length
       (snippet-comparison-region-source-original-length-of region)
       :truncated-p
       (snippet-comparison-region-source-truncated-p region)))))

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
               "Layout artifact"
               (snippet-comparison-surface-layout-artifact-of surface))
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

(html-inspector-views:defview snippet-playground-session-authored-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Authored" :priority 3
    (if-let (artifact (snippet-playground-session-authored-artifact-of session))
      (html-inspector-views:html
        (:div :class "hyperdoc-snippet-authored-artifact"
              :data-hyperdoc-snippet-authored-tab "true"
              (:table :class "inspector-table"
                      (maybe-object-ref-row "Authored artifact" artifact)
                      (maybe-object-ref-row
                       "Behavior artifact"
                       (snippet-playground-session-behavior-artifact-of
                        session))
                      (maybe-object-ref-row
                       "Layout artifact"
                       (snippet-playground-session-layout-artifact-of session))
                      (snippet-playground-status-table-row
                       "Semantic roles"
                       (length
                        (snippet-playground-authored-artifact-semantic-roles-of
                         artifact)))
                      (snippet-playground-status-table-row
                       "Behavior relations"
                       (length
                        (snippet-playground-authored-artifact-behavior-relations-of
                         artifact)))
                      (snippet-playground-status-table-row
                       "Layout relations"
                       (length
                        (snippet-playground-authored-artifact-layout-relations-of
                         artifact))))
              (:h3 "Semantic roles")
              (:ul
               (dolist (role
                        (snippet-playground-authored-artifact-semantic-roles-of
                         artifact))
                 (html-inspector-views:html
                   (:li (html-inspector-views:object-ref role)))))
              (:h3 "Behavior relations")
              (:pre :style "white-space: pre-wrap"
                    :data-hyperdoc-snippet-behavior-relations "true"
                    (html-inspector-views:esc
                     (format nil
                             "~{~A~%~}"
                             (snippet-playground-layout-relation-lines
                              (snippet-playground-authored-artifact-behavior-relations-of
                               artifact)))))
              (:h3 "Layout relations")
              (:pre :style "white-space: pre-wrap"
                    :data-hyperdoc-snippet-layout-relations "true"
                    (html-inspector-views:esc
                     (format nil
                             "~{~A~%~}"
                             (snippet-playground-layout-relation-lines
                              (snippet-playground-authored-artifact-layout-relations-of
                               artifact)))))))
      (html-inspector-views:html
        (:p (html-inspector-views:esc
             "No authored artifact is available for this session."))))))

(html-inspector-views:defview snippet-playground-session-behavior-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Behavior" :priority 4
    (let ((artifact (snippet-playground-session-behavior-artifact-of session))
          (run (snippet-playground-session-state-machine-run-of session)))
      (html-inspector-views:html
        (:div :class "hyperdoc-snippet-behavior-artifact"
              :data-hyperdoc-snippet-behavior-artifact "true"
              (:table :class "inspector-table"
                      (maybe-object-ref-row
                       "Behavior artifact"
                       artifact)
                      (maybe-object-ref-row
                       "Authored artifact"
                       (and artifact
                            (snippet-playground-behavior-artifact-authored-artifact-of
                             artifact)))
                      (maybe-object-ref-row
                       "Lifecycle machine"
                       (or (and run (state-machine-run-machine-of run))
                           (and artifact
                                (snippet-playground-behavior-artifact-run-machine-of
                                 artifact))))
                      (maybe-object-ref-row
                       "Lifecycle run"
                       run)
                      (maybe-object-ref-row
                       "Comparison surface machine"
                       (and artifact
                            (snippet-playground-behavior-artifact-comparison-machine-of
                             artifact))))
              (:p (html-inspector-views:esc
                   "Compiled lifecycle artifact shared by html-source and fedwiki-page providers."))
              (when artifact
                (html-inspector-views:html
                  (:pre :style "white-space: pre-wrap"
                        :data-hyperdoc-snippet-machine-scxml "true"
                        (html-inspector-views:esc
                         (snippet-playground-behavior-artifact-run-machine-scxml-of
                          artifact))))))))))

(html-inspector-views:defview snippet-playground-session-layout-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Layout" :priority 5
    (let ((artifact (snippet-playground-session-layout-artifact-of session)))
      (html-inspector-views:html
        (:div :class "hyperdoc-snippet-layout-artifact"
              :data-hyperdoc-snippet-layout-artifact "true"
              (:table :class "inspector-table"
                      (maybe-object-ref-row
                       "Layout artifact"
                       artifact)
                      (maybe-object-ref-row
                       "Comparison surface"
                       (snippet-playground-session-comparison-surface-of session)))
              (:p (html-inspector-views:esc
                   "Compiled layout artifact keeps result placement right-of the origin pane and comparison placement declarative."))
              (:pre :style "white-space: pre-wrap"
                    :data-hyperdoc-snippet-layout-relations "true"
                    (html-inspector-views:esc
                     (format nil "~{~A~%~}"
                             (snippet-playground-layout-relation-lines
                              (snippet-playground-layout-artifact-relations-of
                               artifact)))))
              (:pre :style "white-space: pre-wrap"
                    :data-hyperdoc-snippet-layout-spec "true"
                    (html-inspector-views:esc
                     (format nil "~S"
                             (snippet-playground-layout-artifact-comparison-layout-spec-of
                              artifact)))))))))

(html-inspector-views:defview snippet-playground-session-details-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Details" :priority 7
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
               "Authored artifact"
               (snippet-playground-session-authored-artifact-of session))
              (maybe-object-ref-row
               "Behavior artifact"
               (snippet-playground-session-behavior-artifact-of session))
              (maybe-object-ref-row
               "Layout artifact"
               (snippet-playground-session-layout-artifact-of session))
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
  (html-inspector-views:html-view :title "Evidence" :priority 6
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
  (html-inspector-views:html-view :title "Mech" :priority 8
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
  (html-inspector-views:html-view :title "Code" :priority 9
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
    (if-let (surface (snippet-playground-session-comparison-surface-of session))
      (snippet-playground-render-comparison-surface-into-current-view surface)
      (html-inspector-views:html
        (:p (html-inspector-views:esc
             "No comparison surface is available for this session."))))))

(html-inspector-views:defview snippet-playground-session-crosswalk-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Crosswalk" :priority 10
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
  (html-inspector-views:html-view :title "Lisp scaffold" :priority 11
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
