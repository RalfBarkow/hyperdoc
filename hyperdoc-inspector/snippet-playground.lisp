(in-package :hyperdoc)

(defparameter *snippet-playground-mech-ops*
  '("APPLY" "CLICK" "CODE" "DELTA" "EDGES" "EXTRACT" "GET" "NEIGHBORS"
    "PREVIEW" "PRINT" "PUT" "REVIEW" "SOLO" "WALK"))

;; Exploratory Parsing precedent (narrowed for snippet-playground source import):
;; explicit policy, incremental stats, discrepancy records with provenance,
;; and optional DOT structure artifacts. The parser stage is inspectable
;; import-cleanup, not a hidden extraction heuristic.
(defstruct snippet-source-expansion-policy
  (extract-html-pre-p t)
  (decode-html-entities-p t)
  (include-original-blocks-p t)
  (recognize-pre-without-language-p t)
  (collect-parser-stats-p t)
  (collect-incremental-stats-p nil)
  (stats-snapshot-period 10000)
  (generate-graphviz-dot-p nil)
  (graphviz-dot-snapshot-period 10000)
  (record-discrepancies-p t)
  (include-source-preview-p t)
  (parser-engine-kind :direct)
  (max-html-pre-blocks-per-source-block nil)
  (html-pre-language-attributes
    '("lang" "language" "data-lang" "data-language" "class"))
  (minimum-pre-character-count 1))

(defparameter *snippet-source-expansion-policy*
  (make-snippet-source-expansion-policy))

(defstruct snippet-source-expansion-report
  (original-block-count 0)
  (expanded-block-count 0)
  (synthetic-block-count 0)
  (synthetic-blocks nil)
  (html-like-block-count 0)
  (scanned-block-count 0)
  (accepted-candidate-count 0)
  (rejected-candidate-count 0)
  (html-like-blocks-scanned 0)
  (pre-regions-found 0)
  (pre-regions-accepted 0)
  (pre-regions-rejected 0)
  (rejection-reasons nil)
  (language-hints-observed nil)
  (decode-count 0)
  (warnings nil)
  (discrepancies nil)
  (parse-elapsed-millis nil)
  (incremental-stats-snapshots nil)
  (candidates nil)
  (graphviz-dot-text nil)
  (graphviz-dot-path nil)
  (graphviz-dot-snapshots nil)
  (parser-engine-kind :direct)
  (parser-engine-identity nil)
  (parser-engine-chart-name nil)
  (parser-engine-trace nil)
  (parser-engine-states-visited nil)
  (parser-engine-events nil)
  (policy-summary nil)
  (notes nil))

(defstruct snippet-source-parse-discrepancy
  severity
  kind
  fact-summary
  source-block-index
  source-block-id
  source-line-number
  character-offset
  evidence-value)

(defstruct snippet-source-parse-context
  policy
  input-blocks
  expanded-blocks
  current-block-index
  current-pre-index
  synthetic-blocks
  stats
  warnings
  trace
  report)

(defgeneric run-snippet-source-parser-engine (engine blocks policy))

(defclass direct-snippet-source-parser-engine ()
  ((identity :reader snippet-source-parser-engine-identity-of
             :initarg :identity
             :initform "snippet-source-parser/direct-html-pre-v1")))

(defclass scxml-snippet-source-parser-engine ()
  ((identity :reader snippet-source-parser-engine-identity-of
             :initarg :identity
             :initform "snippet-source-parser/scxml-html-pre-v1")
   (chart :reader chart-of
          :initarg :chart)
   (compiled-runner :reader compiled-runner-of
                    :initarg :compiled-runner
                    :initform nil)))

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
   (mech-execution-ir :reader snippet-comparison-surface-mech-execution-ir-of
                      :initarg :mech-execution-ir
                      :initform nil)
   (execution-input :reader snippet-comparison-surface-execution-input-of
                    :initarg :execution-input
                    :initform nil)
   (lefty-run-result :reader snippet-comparison-surface-lefty-run-result-of
                     :initarg :lefty-run-result
                     :initform nil)
   (rita-run-result :reader snippet-comparison-surface-rita-run-result-of
                    :initarg :rita-run-result
                    :initform nil)
   (equivalence-report :reader snippet-comparison-surface-equivalence-report-of
                       :initarg :equivalence-report
                       :initform nil)
   (transformation-ir :reader snippet-comparison-surface-transformation-ir-of
                      :initarg :transformation-ir
                      :initform nil)
   (mech-scxml-execution-chart
     :reader snippet-comparison-surface-mech-scxml-execution-chart-of
     :initarg :mech-scxml-execution-chart
     :initform nil)
   (scxml-run-result
     :reader snippet-comparison-surface-scxml-run-result-of
     :initarg :scxml-run-result
     :initform nil)
   (mech-lisp-scaffold-source
     :reader snippet-comparison-surface-mech-lisp-scaffold-source-of
     :initarg :mech-lisp-scaffold-source
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

(defclass mech-execution-input ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (selected-mech :reader mech-execution-input-selected-mech-of
                  :initarg :selected-mech
                  :initform nil)
   (selected-code :reader mech-execution-input-selected-code-of
                  :initarg :selected-code
                  :initform nil)
   (normalized-state :reader mech-execution-input-normalized-state-of
                     :initarg :normalized-state
                     :initform nil)
   (parsed-mech-operations :reader mech-execution-input-parsed-mech-operations-of
                           :initarg :parsed-mech-operations
                           :initform nil)
   (code-operation-name :reader mech-execution-input-code-operation-name-of
                        :initarg :code-operation-name
                        :initform nil)
   (code-operation-arguments
     :reader mech-execution-input-code-operation-arguments-of
     :initarg :code-operation-arguments
     :initform nil)
   (handoff-path :reader mech-execution-input-handoff-path-of
                 :initarg :handoff-path
                 :initform nil)
   (findings :reader mech-execution-input-findings-of
             :initarg :findings
             :initform nil)))

(defclass mech-run-result ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (engine :reader mech-run-result-engine-of
           :initarg :engine
           :initform :unsupported)
   (status :reader mech-run-result-status-of
           :initarg :status
           :initform :unsupported)
   (return-value :reader mech-run-result-return-value-of
                 :initarg :return-value
                 :initform nil)
   (final-state :reader mech-run-result-final-state-of
                :initarg :final-state
                :initform nil)
   (normalized-output :reader mech-run-result-normalized-output-of
                      :initarg :normalized-output
                      :initform nil)
   (trace :reader mech-run-result-trace-of
          :initarg :trace
          :initform nil)
   (diagnostics :reader mech-run-result-diagnostics-of
                :initarg :diagnostics
                :initform nil)
   (unsupported-constructs :reader mech-run-result-unsupported-constructs-of
                           :initarg :unsupported-constructs
                           :initform nil)
   (source-provenance :reader mech-run-result-source-provenance-of
                      :initarg :source-provenance
                      :initform nil)))

(defclass mech-equivalence-report ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (lefty-run-result :reader mech-equivalence-report-lefty-run-result-of
                     :initarg :lefty-run-result
                     :initform nil)
   (rita-run-result :reader mech-equivalence-report-rita-run-result-of
                    :initarg :rita-run-result
                    :initform nil)
   (normalized-comparison-value
     :reader mech-equivalence-report-normalized-comparison-value-of
     :initarg :normalized-comparison-value
     :initform nil)
   (equal-p :reader mech-equivalence-report-equal-p
            :initarg :equal-p
            :initform nil)
   (differences :reader mech-equivalence-report-differences-of
                :initarg :differences
                :initform nil)
   (unsupported-constructs
     :reader mech-equivalence-report-unsupported-constructs-of
     :initarg :unsupported-constructs
     :initform nil)
   (source-provenance :reader mech-equivalence-report-source-provenance-of
                      :initarg :source-provenance
                      :initform nil)
   (findings :reader mech-equivalence-report-findings-of
             :initarg :findings
             :initform nil)))

(defclass mech-state-items-ir ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (input-slots :reader mech-state-items-ir-input-slots-of
                :initarg :input-slots
                :initform nil)
   (output-path :reader mech-state-items-ir-output-path-of
                :initarg :output-path
                :initform nil)
   (function-name :reader mech-state-items-ir-function-name-of
                  :initarg :function-name
                  :initform nil)
   (function-arguments :reader mech-state-items-ir-function-arguments-of
                       :initarg :function-arguments
                       :initform nil)
   (helper-functions :reader mech-state-items-ir-helper-functions-of
                     :initarg :helper-functions
                     :initform nil)
   (operation-summary :reader mech-state-items-ir-operation-summary-of
                      :initarg :operation-summary
                      :initform nil)
   (equivalence-status :reader mech-state-items-ir-equivalence-status-of
                       :initarg :equivalence-status
                       :initform nil)
   (source-provenance :reader mech-state-items-ir-source-provenance-of
                      :initarg :source-provenance
                      :initform nil)
   (findings :reader mech-state-items-ir-findings-of
             :initarg :findings
             :initform nil)))

(defclass mech-execution-ir ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (source-mech :reader mech-execution-ir-source-mech-of
                :initarg :source-mech
                :initform nil)
   (ordered-operations :reader mech-execution-ir-ordered-operations-of
                       :initarg :ordered-operations
                       :initform nil)
   (click-groups :reader mech-execution-ir-click-groups-of
                 :initarg :click-groups
                 :initform nil)
   (required-inputs :reader mech-execution-ir-required-inputs-of
                    :initarg :required-inputs
                    :initform nil)
   (code-invocations :reader mech-execution-ir-code-invocations-of
                     :initarg :code-invocations
                     :initform nil)
   (preview-output-paths :reader mech-execution-ir-preview-output-paths-of
                         :initarg :preview-output-paths
                         :initform nil)
   (provenance :reader mech-execution-ir-provenance-of
               :initarg :provenance
               :initform nil)
   (unsupported-operations :reader mech-execution-ir-unsupported-operations-of
                           :initarg :unsupported-operations
                           :initform nil)
   (findings :reader mech-execution-ir-findings-of
             :initarg :findings
             :initform nil)))

(defclass mech-scxml-execution-chart ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (chart-name :reader mech-scxml-execution-chart-name-of
               :initarg :chart-name
               :initform nil)
   (initial-state :reader mech-scxml-execution-chart-initial-state-of
                  :initarg :initial-state
                  :initform nil)
   (terminal-states :reader mech-scxml-execution-chart-terminal-states-of
                    :initarg :terminal-states
                    :initform nil)
   (failure-states :reader mech-scxml-execution-chart-failure-states-of
                   :initarg :failure-states
                   :initform nil)
   (events :reader mech-scxml-execution-chart-events-of
           :initarg :events
           :initform nil)
   (execution-ir :reader mech-scxml-execution-chart-execution-ir-of
                 :initarg :execution-ir
                 :initform nil)
   (machine-definition :reader mech-scxml-execution-chart-machine-definition-of
                       :initarg :machine-definition
                       :initform nil)
   (chart :reader mech-scxml-execution-chart-chart-of
          :initarg :chart
          :initform nil)
   (scxml-text :reader mech-scxml-execution-chart-scxml-text-of
               :initarg :scxml-text
               :initform nil)
   (findings :reader mech-scxml-execution-chart-findings-of
             :initarg :findings
             :initform nil)))

(defclass mech-lisp-scaffold-source ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (source :reader mech-lisp-scaffold-source-source-of
           :initarg :source
           :initform nil)
   (execution-input :reader mech-lisp-scaffold-source-execution-input-of
                    :initarg :execution-input
                    :initform nil)
   (transformation-ir :reader mech-lisp-scaffold-source-transformation-ir-of
                      :initarg :transformation-ir
                      :initform nil)
   (scxml-execution-chart :reader mech-lisp-scaffold-source-scxml-execution-chart-of
                          :initarg :scxml-execution-chart
                          :initform nil)
   (scxml-run-result :reader mech-lisp-scaffold-source-scxml-run-result-of
                     :initarg :scxml-run-result
                     :initform nil)
   (equivalence-report :reader mech-lisp-scaffold-source-equivalence-report-of
                       :initarg :equivalence-report
                       :initform nil)
   (findings :reader mech-lisp-scaffold-source-findings-of
             :initarg :findings
             :initform nil)))

(defclass snippet-playground-authored-role (authored-relation-role) ())

(defclass snippet-playground-authored-relation (authored-relation) ())

(defclass snippet-playground-authored-artifact (authored-relation-artifact) ())

(defclass snippet-playground-behavior-artifact (compiled-behavior-artifact) ())

(defclass snippet-playground-layout-artifact (compiled-layout-artifact) ())

(defmethod authored-relation-artifact-derived-artifacts-of
    ((artifact snippet-playground-authored-artifact))
  (declare (ignore artifact))
  (list (snippet-playground-behavior-artifact)
        (snippet-comparison-layout-artifact)))

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
   (source-expansion-report
     :reader snippet-playground-session-source-expansion-report-of
     :initarg :source-expansion-report
     :initform nil)
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
   (mech-execution-ir
     :reader snippet-playground-session-mech-execution-ir-of
     :initarg :mech-execution-ir
     :initform nil)
   (mech-execution-input
     :reader snippet-playground-session-mech-execution-input-of
     :initarg :mech-execution-input
     :initform nil)
   (lefty-run-result
     :reader snippet-playground-session-lefty-run-result-of
     :initarg :lefty-run-result
     :initform nil)
   (rita-run-result
     :reader snippet-playground-session-rita-run-result-of
     :initarg :rita-run-result
     :initform nil)
   (equivalence-report
     :reader snippet-playground-session-equivalence-report-of
     :initarg :equivalence-report
     :initform nil)
   (transformation-ir
     :reader snippet-playground-session-transformation-ir-of
     :initarg :transformation-ir
     :initform nil)
   (mech-scxml-execution-chart
     :reader snippet-playground-session-mech-scxml-execution-chart-of
     :initarg :mech-scxml-execution-chart
     :initform nil)
   (scxml-run-result
     :reader snippet-playground-session-scxml-run-result-of
     :initarg :scxml-run-result
     :initform nil)
   (mech-lisp-scaffold-source
     :reader snippet-playground-session-mech-lisp-scaffold-source-of
     :initarg :mech-lisp-scaffold-source
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

(defmethod print-object ((object mech-execution-input) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object mech-run-result) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object mech-equivalence-report) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object mech-state-items-ir) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object mech-execution-ir) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object mech-scxml-execution-chart) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object mech-lisp-scaffold-source) stream)
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
    ((object mech-execution-input))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object mech-run-result))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object mech-equivalence-report))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object mech-state-items-ir))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object mech-execution-ir))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object mech-scxml-execution-chart))
  (title-of object))

(defmethod html-inspector-views:text-representation
    ((object mech-lisp-scaffold-source))
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

(defun snippet-playground-authored-relation-from-source-definition
    (definition)
  (make-snippet-playground-authored-relation
   :id (getf definition :id)
   :title (getf definition :title)
   :summary (getf definition :summary)
   :layer (getf definition :layer)
   :subject (getf definition :subject)
   :predicate (getf definition :predicate)
   :object (getf definition :object)
   :attributes (getf definition :attributes)))

(defun make-snippet-playground-authored-graph ()
  (mapcar #'snippet-playground-authored-relation-from-source-definition
          (authored-relation-artifact-source-relation-definitions-of
           (snippet-playground-authored-source-artifact))))

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

(defun snippet-playground-authored-role-from-source-definition
    (definition)
  (make-snippet-playground-authored-role
   :id (getf definition :id)
   :title (getf definition :title)
   :summary (getf definition :summary)
   :kind (getf definition :kind)
   :binding (getf definition :binding)
   :participants (getf definition :participants)
   :findings (getf definition :findings)))

(defun make-snippet-playground-authored-roles ()
  (mapcar #'snippet-playground-authored-role-from-source-definition
          (authored-relation-artifact-source-semantic-role-definitions-of
           (snippet-playground-authored-source-artifact))))

(defun snippet-playground-authored-artifact-findings ()
  (authored-relation-artifact-source-findings-of
   (snippet-playground-authored-source-artifact)))

(defun make-snippet-playground-authored-artifact ()
  (let* ((source (snippet-playground-authored-source-artifact))
         (relations (make-snippet-playground-authored-graph))
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
     :id (authored-relation-artifact-source-artifact-id-of source)
     :title (authored-relation-artifact-source-artifact-title-of source)
     :summary
     (authored-relation-artifact-source-artifact-summary-of source)
     :artifact-kind :authored-relation-artifact
     :workflow-role
     (authored-relation-artifact-source-workflow-role-of source)
     :compiler-pipeline
     (authored-relation-artifact-source-compiler-pipeline-of source)
     :semantic-roles (make-snippet-playground-authored-roles)
     :semantic-relations semantic-relations
     :behavior-relations behavior-relations
     :layout-relations layout-relations
     :relations relations
     :compiled-targets
     (authored-relation-artifact-source-compiled-targets-of source)
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
       mech-execution-ir mech-execution-input lefty-run-result rita-run-result
       equivalence-report transformation-ir mech-scxml-execution-chart
       scxml-run-result mech-lisp-scaffold-source
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
    :mech_execution_ir
    (snippet-playground-object-label mech-execution-ir)
    :mech_execution_input
    (snippet-playground-object-label mech-execution-input)
    :mech_scxml_execution_chart
    (snippet-playground-object-label mech-scxml-execution-chart)
    :scxml_run_result
    (snippet-playground-object-label scxml-run-result)
    :lefty_run_result
    (snippet-playground-object-label lefty-run-result)
    :rita_run_result
    (snippet-playground-object-label rita-run-result)
    :equivalence_report
    (snippet-playground-object-label equivalence-report)
    :transformation_ir
    (snippet-playground-object-label transformation-ir)
    :mech_lisp_scaffold_source
    (snippet-playground-object-label mech-lisp-scaffold-source)
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

(defun extract-html-code-block-candidates-with-discrepancies
    (source &key (decode-html-entities-p t))
  (loop with blocks = '()
        with discrepancies = '()
        with start-token = "<pre"
        with pre-end-token = "</pre>"
        with scan-start = 0
        with index = 0
        for open-start = (search start-token source
                                 :test #'char-equal
                                 :start2 scan-start)
        while open-start
        do (let* ((pre-end (position #\> source :start open-start))
                  (line-number (source-line-number-at-offset source open-start)))
             (cond
               ((null pre-end)
                (push (list :kind :malformed-pre
                            :line-number line-number
                            :character-offset open-start
                            :summary "Missing closing > for <pre tag.")
                      discrepancies)
                (setf scan-start (+ open-start (length start-token))))
               (t
                (let ((close-pre-start (search pre-end-token source
                                               :test #'char-equal
                                               :start2 (1+ pre-end))))
                  (if (null close-pre-start)
                      (progn
                        (push (list :kind :unterminated-html-region
                                    :line-number line-number
                                    :character-offset open-start
                                    :summary "Missing closing </pre> tag.")
                              discrepancies)
                        (setf scan-start (1+ pre-end)))
                      (let* ((code-start-candidate
                               (search "<code" source
                                       :test #'char-equal
                                       :start2 (1+ pre-end)))
                             (code-start (and code-start-candidate
                                              (< code-start-candidate
                                                 close-pre-start)
                                              code-start-candidate))
                             (code-end (and code-start
                                            (position #\> source
                                                      :start code-start)))
                             (close-code-start-candidate
                               (and code-end
                                    (search "</code>" source
                                            :test #'char-equal
                                            :start2 (1+ code-end))))
                             (close-code-start
                               (and close-code-start-candidate
                                    (< close-code-start-candidate
                                       close-pre-start)
                                    close-code-start-candidate))
                             (content-start (if code-end
                                                (1+ code-end)
                                                (1+ pre-end)))
                             (content-end (or close-code-start close-pre-start))
                             (open-tag (if code-end
                                           (subseq source open-start
                                                   (1+ code-end))
                                           (subseq source open-start
                                                   (1+ pre-end))))
                             (raw-source (subseq source content-start content-end))
                             (decoded-source
                               (if decode-html-entities-p
                                   (decode-html-code-block-text raw-source)
                                   raw-source)))
                        (incf index)
                        (push (list :index index
                                    :line-number line-number
                                    :character-offset open-start
                                    :open-tag open-tag
                                    :source (snippet-playground-trim-source
                                             decoded-source)
                                    :raw-source raw-source)
                              blocks)
                        (setf scan-start
                              (+ close-pre-start (length pre-end-token)))))))))
        finally (return (values (nreverse blocks)
                                (nreverse discrepancies)))))

(defun extract-html-code-blocks (source &key (decode-html-entities-p t))
  (nth-value 0
             (extract-html-code-block-candidates-with-discrepancies
              source
              :decode-html-entities-p decode-html-entities-p)))

(defun snippet-block-location-label (block)
  (or (getf block :location-label)
      (let ((line-number (getf block :line-number)))
        (if line-number
            (format nil "source line ~D" line-number)
            "source surface"))))

(defun snippet-playground-candidate-fedwiki-story-item-p (item)
  (member (hyperbook/fedwiki::item-type-of item)
          '(:code :mech :paragraph :markdown :reference :html)
          :test #'eq))

(defun extract-fedwiki-story-item-blocks (page)
  (loop with blocks = '()
        for item across (hyperbook/fedwiki::story-of page)
        for index from 1
        for item-type = (hyperbook/fedwiki::item-type-of item)
        for story-item-id = (ignore-errors (id-of item))
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
                         :provider-kind "fedwiki-v1"
                         :story-item-id story-item-id)
                   blocks)
        finally (return (nreverse blocks))))

(defun snippet-source-expansion-policy-summary (policy)
  (list
   :extract_html_pre_p
   (snippet-source-expansion-policy-extract-html-pre-p policy)
   :decode_html_entities_p
   (snippet-source-expansion-policy-decode-html-entities-p policy)
   :include_original_blocks_p
   (snippet-source-expansion-policy-include-original-blocks-p policy)
   :recognize_pre_without_language_p
   (snippet-source-expansion-policy-recognize-pre-without-language-p policy)
   :collect_parser_stats_p
   (snippet-source-expansion-policy-collect-parser-stats-p policy)
   :collect_incremental_stats_p
   (snippet-source-expansion-policy-collect-incremental-stats-p policy)
   :stats_snapshot_period
   (snippet-source-expansion-policy-stats-snapshot-period policy)
   :generate_graphviz_dot_p
   (snippet-source-expansion-policy-generate-graphviz-dot-p policy)
   :graphviz_dot_snapshot_period
   (snippet-source-expansion-policy-graphviz-dot-snapshot-period policy)
   :record_discrepancies_p
   (snippet-source-expansion-policy-record-discrepancies-p policy)
   :include_source_preview_p
   (snippet-source-expansion-policy-include-source-preview-p policy)
   :parser_engine_kind
   (snippet-source-expansion-policy-parser-engine-kind policy)
   :max_html_pre_blocks_per_source_block
   (snippet-source-expansion-policy-max-html-pre-blocks-per-source-block policy)
   :html_pre_language_attributes
   (copy-list
    (snippet-source-expansion-policy-html-pre-language-attributes policy))
   :minimum_pre_character_count
   (snippet-source-expansion-policy-minimum-pre-character-count policy)))

(defun snippet-playground-html-pre-source-block-p (block)
  (let* ((source (or (getf block :source) ""))
         (open-tag (or (getf block :open-tag) "")))
    (and (not (snippet-playground-empty-string-p source))
         (or (snippet-playground-string-contains-p source "<pre")
             (snippet-playground-string-contains-p open-tag "html")
             (snippet-playground-string-contains-p open-tag "markdown")))))

(defun snippet-playground-html-pre-synthetic-block-p (block)
  (eq (getf block :synthetic-kind) :html-pre))

(defun snippet-playground-open-tag-attribute-value (open-tag attribute-name)
  (when (and (stringp open-tag)
             (stringp attribute-name))
    (let* ((needle (format nil "~A=" attribute-name))
           (match (search needle open-tag :test #'char-equal)))
      (when match
        (let* ((start (+ match (length needle)))
               (cursor (or (position-if-not
                            (lambda (char)
                              (find char '(#\Space #\Tab)))
                            open-tag
                            :start start)
                           (length open-tag))))
          (when (< cursor (length open-tag))
            (let ((first-char (char open-tag cursor)))
              (if (or (char= first-char #\")
                      (char= first-char #\'))
                  (let ((end (position first-char open-tag :start (1+ cursor))))
                    (and end
                         (subseq open-tag (1+ cursor) end)))
                  (let ((end (or (position-if
                                  (lambda (char)
                                    (or (find char '(#\Space #\Tab #\>))
                                        (char= char #\/)))
                                  open-tag
                                  :start cursor)
                                 (length open-tag))))
                    (subseq open-tag cursor end))))))))))

(defun snippet-playground-html-pre-language-hints (open-tag policy)
  (let ((attributes
          (snippet-source-expansion-policy-html-pre-language-attributes
           policy)))
    (loop for attribute-name in attributes
          for value = (snippet-playground-open-tag-attribute-value
                       open-tag
                       attribute-name)
          when (and value
                    (not (snippet-playground-empty-string-p value)))
            collect (list :attribute (string-downcase attribute-name)
                          :value (string-downcase value)))))

(defun snippet-playground-html-pre-open-tag-from-hints (hints)
  (if hints
      (format nil "~{~A~^ ~}"
              (mapcar (lambda (hint)
                        (getf hint :value))
                      hints))
      "html-pre"))

(defun snippet-playground-synthetic-html-pre-labels-from-report (report)
  (loop for synthetic-block in
          (snippet-source-expansion-report-synthetic-blocks report)
        collect (getf synthetic-block :synthetic_id)))

(defun snippet-playground-recognized-synthetic-html-pre-labels (session)
  (loop for snippet in
          (snippet-playground-session-recognized-code-snippets-of session)
        for label = (snippet-location-label-of snippet)
        when (and label
                  (search "html-pre/" label :test #'char=))
          collect label))

(defun snippet-source-parse-discrepancy->plist (discrepancy)
  (list :severity
        (snippet-source-parse-discrepancy-severity discrepancy)
        :kind
        (snippet-source-parse-discrepancy-kind discrepancy)
        :fact_summary
        (snippet-source-parse-discrepancy-fact-summary discrepancy)
        :source_block_index
        (snippet-source-parse-discrepancy-source-block-index discrepancy)
        :source_block_id
        (snippet-source-parse-discrepancy-source-block-id discrepancy)
        :source_line_number
        (snippet-source-parse-discrepancy-source-line-number discrepancy)
        :character_offset
        (snippet-source-parse-discrepancy-character-offset discrepancy)
        :evidence_value
        (snippet-source-parse-discrepancy-evidence-value discrepancy)))

(defun snippet-source-parser-dot-escape-label (text)
  (let ((escaped (or text "")))
    (setf escaped
          (snippet-playground-replace-all escaped "\\" "\\\\"))
    (setf escaped
          (snippet-playground-replace-all escaped "\"" "\\\""))
    (setf escaped
          (snippet-playground-replace-all escaped
                                          (string #\Newline)
                                          "\\n"))
    escaped))

(defun snippet-source-parser-report-graphviz-dot-text (blocks candidates)
  (with-output-to-string (stream)
    (format stream "digraph snippet_source_parser {~%")
    (format stream "  rankdir=LR;~%")
    (format stream "  node [shape=box, fontsize=10];~%")
    (loop for block in blocks
          for block-index = (or (getf block :index) 0)
          for block-node = (format nil "source-block-~D" block-index)
          for block-label = (snippet-source-parser-dot-escape-label
                             (format nil "#~D ~A"
                                     block-index
                                     (or (snippet-block-location-label block)
                                         "source block")))
          do (format stream "  \"~A\" [label=\"~A\"];~%"
                     block-node
                     block-label))
    (dolist (candidate candidates)
      (let* ((parent-index (or (getf candidate :parent_block_index) 0))
             (pre-ordinal (or (getf candidate :pre_ordinal) 0))
             (candidate-node
               (format nil "candidate-html-pre-~D-~D"
                       parent-index
                       pre-ordinal))
             (candidate-label
               (snippet-source-parser-dot-escape-label
                (format nil "~A~%status=~A~%hint=~A~%lines=~A"
                        (or (getf candidate :synthetic_id)
                            candidate-node)
                        (or (getf candidate :status) :unknown)
                        (or (getf candidate :language_hint) "n/a")
                        (or (getf candidate :line_count) 0))))
             (parent-node (format nil "source-block-~D" parent-index))
             (edge-label
               (snippet-source-parser-dot-escape-label
                (or (getf candidate :reason) "candidate"))))
        (format stream "  \"~A\" [label=\"~A\", shape=note];~%"
                candidate-node
                candidate-label)
        (format stream "  \"~A\" -> \"~A\" [label=\"~A\"];~%"
                parent-node
                candidate-node
                edge-label)))
    (format stream "}~%")))

(defun snippet-playground-source-expansion-evidence (report)
  (let ((effective-report
          (or report
              (make-snippet-source-expansion-report))))
    (list
     :source_block_count
     (snippet-source-expansion-report-original-block-count effective-report)
     :expanded_source_block_count
     (snippet-source-expansion-report-expanded-block-count effective-report)
     :synthetic_html_pre_candidate_count
     (snippet-source-expansion-report-synthetic-block-count effective-report)
     :html_like_block_count
     (snippet-source-expansion-report-html-like-block-count effective-report)
     :scanned_block_count
     (snippet-source-expansion-report-scanned-block-count effective-report)
     :accepted_candidate_count
     (snippet-source-expansion-report-accepted-candidate-count effective-report)
     :rejected_candidate_count
     (snippet-source-expansion-report-rejected-candidate-count effective-report)
     :synthetic_html_pre_candidate_labels
     (snippet-playground-synthetic-html-pre-labels-from-report effective-report)
     :html_like_blocks_scanned
     (snippet-source-expansion-report-html-like-blocks-scanned effective-report)
     :pre_regions_found
     (snippet-source-expansion-report-pre-regions-found effective-report)
     :pre_regions_accepted
     (snippet-source-expansion-report-pre-regions-accepted effective-report)
     :pre_regions_rejected
     (snippet-source-expansion-report-pre-regions-rejected effective-report)
     :parse_elapsed_millis
     (snippet-source-expansion-report-parse-elapsed-millis effective-report)
     :source_expansion_policy
     (snippet-source-expansion-report-policy-summary effective-report)
     :source_expansion_rejection_reasons
     (snippet-source-expansion-report-rejection-reasons effective-report)
     :source_expansion_language_hints
     (snippet-source-expansion-report-language-hints-observed effective-report)
     :source_expansion_decode_count
     (snippet-source-expansion-report-decode-count effective-report)
     :source_expansion_candidates
     (snippet-source-expansion-report-candidates effective-report)
     :source_expansion_discrepancies
     (mapcar #'snippet-source-parse-discrepancy->plist
             (snippet-source-expansion-report-discrepancies effective-report))
     :source_expansion_incremental_stats_snapshots
     (snippet-source-expansion-report-incremental-stats-snapshots
      effective-report)
     :source_expansion_graphviz_dot_text
     (snippet-source-expansion-report-graphviz-dot-text effective-report)
     :source_expansion_warnings
     (snippet-source-expansion-report-warnings effective-report)
     :source_parser_engine_kind
     (snippet-source-expansion-report-parser-engine-kind effective-report)
     :source_parser_engine_identity
     (snippet-source-expansion-report-parser-engine-identity
      effective-report)
     :source_parser_engine_chart_name
     (snippet-source-expansion-report-parser-engine-chart-name
      effective-report)
     :source_parser_engine_states
     (snippet-source-expansion-report-parser-engine-states-visited
      effective-report)
     :source_parser_engine_events
     (snippet-source-expansion-report-parser-engine-events effective-report)
     :source_expansion_notes
     (snippet-source-expansion-report-notes effective-report))))

(defun parse-snippet-source-blocks-direct
    (blocks &key (policy *snippet-source-expansion-policy*))
  (let ((effective-policy (or policy *snippet-source-expansion-policy*))
        (parse-start (snippet-playground-current-millis))
        (expanded-blocks '())
        (accepted-synthetic-entries '())
        (candidate-entries '())
        (notes '())
        (warnings '())
        (discrepancies '())
        (rejection-reasons '())
        (language-hints-observed '())
        (html-like-block-count 0)
        (scanned-block-count 0)
        (pre-regions-found 0)
        (pre-regions-accepted 0)
        (pre-regions-rejected 0)
        (decode-count 0)
        (processed-node-count 0)
        (incremental-stats-snapshots '())
        (graphviz-dot-snapshots '())
        (expanded-index 0))
    (labels
        ((append-expanded-block (block)
           (let ((expanded-block (copy-list block)))
             (setf (getf expanded-block :index) (incf expanded-index))
             (push expanded-block expanded-blocks)))
         (note (message)
           (push message notes))
         (record-warning (message)
           (push message warnings))
         (incf-table-count (key table)
           (let ((entry (assoc key table :test #'equal)))
             (if entry
                 (incf (cdr entry))
                 (push (cons key 1) table))
             table))
         (record-discrepancy
             (severity kind fact-summary
              &key block source-line-number character-offset evidence-value)
           (when (snippet-source-expansion-policy-record-discrepancies-p
                  effective-policy)
             (push
              (make-snippet-source-parse-discrepancy
               :severity severity
               :kind kind
               :fact-summary fact-summary
               :source-block-index (and block (getf block :index))
               :source-block-id (and block (getf block :id))
               :source-line-number source-line-number
               :character-offset character-offset
               :evidence-value evidence-value)
              discrepancies)))
         (record-rejection
             (reason discrepancy-kind message
              &key block source-line-number character-offset evidence-value)
           (setf rejection-reasons
                 (incf-table-count reason rejection-reasons))
           (incf pre-regions-rejected)
           (record-discrepancy :warning
                               discrepancy-kind
                               message
                               :block block
                               :source-line-number source-line-number
                               :character-offset character-offset
                               :evidence-value evidence-value))
         (record-language-hints (hints)
           (dolist (hint hints)
             (let ((key (list :attribute (getf hint :attribute)
                              :value (getf hint :value))))
               (setf language-hints-observed
                     (incf-table-count key language-hints-observed)))))
         (maybe-record-incremental-snapshot (kind)
           (when (and (snippet-source-expansion-policy-collect-parser-stats-p
                       effective-policy)
                      (snippet-source-expansion-policy-collect-incremental-stats-p
                       effective-policy))
             (let ((period
                     (max 1
                          (or (snippet-source-expansion-policy-stats-snapshot-period
                               effective-policy)
                              1))))
               (when (or (= processed-node-count 1)
                         (zerop (mod processed-node-count period)))
                 (push (list :node_count processed-node-count
                             :kind kind
                             :original_block_count (length blocks)
                             :expanded_block_count expanded-index
                             :html_like_block_count html-like-block-count
                             :scanned_block_count scanned-block-count
                             :pre_regions_found pre-regions-found
                             :accepted_candidate_count pre-regions-accepted
                             :rejected_candidate_count pre-regions-rejected)
                       incremental-stats-snapshots)))))
         (maybe-record-graphviz-snapshot (kind)
           (when (snippet-source-expansion-policy-generate-graphviz-dot-p
                  effective-policy)
             (let ((period
                     (max 1
                          (or (snippet-source-expansion-policy-graphviz-dot-snapshot-period
                               effective-policy)
                              1))))
               (when (or (= processed-node-count 1)
                         (zerop (mod processed-node-count period)))
                 (push (list :node_count processed-node-count
                             :kind kind
                             :dot_text
                             (snippet-source-parser-report-graphviz-dot-text
                              blocks
                              (nreverse candidate-entries)))
                       graphviz-dot-snapshots)))))
         (touch-node (kind)
           (incf processed-node-count)
           (maybe-record-incremental-snapshot kind)
           (maybe-record-graphviz-snapshot kind))
         (candidate-preview (source)
           (when (snippet-source-expansion-policy-include-source-preview-p
                  effective-policy)
             (multiple-value-bind (preview)
                 (snippet-playground-bounded-source-text source :limit 120)
               preview)))
         (record-candidate-entry
             (parent-block parent-index parent-location-label pre-index
              pre-source pre-char-count hinted-language hints reason accepted-p
              pre-line-number pre-character-offset)
           (let* ((synthetic-id
                    (format nil "html-pre/~D/~D" parent-index pre-index))
                  (synthetic-location-label
                    (format nil "~A from ~A"
                            synthetic-id
                            parent-location-label))
                  (line-count
                    (max 1
                         (1+ (count #\Newline pre-source))))
                  (decoded-p
                    (snippet-source-expansion-policy-decode-html-entities-p
                     effective-policy))
                  (entry
                    (list
                     :synthetic_id synthetic-id
                     :location_label synthetic-location-label
                     :parent_block_id (getf parent-block :id)
                     :parent_story_item_id (getf parent-block :story-item-id)
                     :parent_block_index parent-index
                     :source_line_number pre-line-number
                     :character_offset pre-character-offset
                     :pre_ordinal pre-index
                     :source_kind :html-pre
                     :language_hint hinted-language
                     :language_hint_attributes hints
                     :accepted_p accepted-p
                     :status (if accepted-p :accepted :rejected)
                     :reason reason
                     :decoded_entities_p decoded-p
                     :character_count pre-char-count
                     :line_count line-count
                     :preview (candidate-preview pre-source)
                     :parent_location_label parent-location-label)))
             (push entry candidate-entries)
             (when accepted-p
               (push entry accepted-synthetic-entries)
               (incf pre-regions-accepted))
             entry)))
      (dolist (block blocks)
        (touch-node :source-block)
        (let* ((html-pre-source-block-p
                 (snippet-playground-html-pre-source-block-p block))
               (include-original-p
                 (or (not html-pre-source-block-p)
                     (snippet-source-expansion-policy-include-original-blocks-p
                      effective-policy))))
          (when html-pre-source-block-p
            (incf html-like-block-count))
          (when include-original-p
            (append-expanded-block block))
          (when (and html-pre-source-block-p
                     (not include-original-p))
            (note (format nil
                          "Skipped original HTML-like block #~D due to include_original_blocks_p = nil."
                          (getf block :index))))
          (cond
            ((not html-pre-source-block-p)
             nil)
            ((not (snippet-source-expansion-policy-extract-html-pre-p
                   effective-policy))
             (record-warning
              (format nil
                      "HTML <pre> parsing disabled by policy for block #~D."
                      (getf block :index))))
            (t
             (incf scanned-block-count)
             (let* ((parent-index (getf block :index))
                    (parent-line-number (or (getf block :line-number) 1))
                    (parent-location-label (snippet-block-location-label block))
                    (max-per-parent
                      (snippet-source-expansion-policy-max-html-pre-blocks-per-source-block
                       effective-policy))
                    (min-char-count
                      (max 0
                           (or (snippet-source-expansion-policy-minimum-pre-character-count
                                effective-policy)
                               0)))
                    (emitted-count 0)
                    (source (or (getf block :source) ""))
                    (pre-blocks '())
                    (scan-discrepancies '()))
               (multiple-value-setq (pre-blocks scan-discrepancies)
                 (extract-html-code-block-candidates-with-discrepancies
                  source
                  :decode-html-entities-p
                  (snippet-source-expansion-policy-decode-html-entities-p
                   effective-policy)))
               (incf pre-regions-found (length pre-blocks))
               (when (snippet-source-expansion-policy-decode-html-entities-p
                      effective-policy)
                 (incf decode-count (length pre-blocks)))
               (dolist (discrepancy scan-discrepancies)
                 (let ((kind (getf discrepancy :kind))
                       (line-number (+ parent-line-number
                                       (max 0
                                            (1- (or (getf discrepancy
                                                         :line-number)
                                                    1)))))
                       (character-offset (getf discrepancy :character-offset))
                       (summary (or (getf discrepancy :summary)
                                    "Exploratory parser discrepancy.")))
                   (record-warning
                    (format nil
                            "~A at block #~D line ~A offset ~A."
                            summary
                            (or parent-index "n/a")
                            (or line-number "n/a")
                            (or character-offset "n/a")))
                   (record-discrepancy :warning
                                       kind
                                       summary
                                       :block block
                                       :source-line-number line-number
                                       :character-offset character-offset
                                       :evidence-value discrepancy)))
               (loop for pre-block in pre-blocks
                     for pre-index from 1
                     for pre-line-number = (+ parent-line-number
                                              (max 0
                                                   (1- (or (getf pre-block
                                                                 :line-number)
                                                           1))))
                     for pre-character-offset = (getf pre-block
                                                      :character-offset)
                     for pre-source = (snippet-playground-trim-source
                                       (or (getf pre-block :source) ""))
                     for pre-char-count = (length pre-source)
                     for hints = (snippet-playground-html-pre-language-hints
                                  (getf pre-block :open-tag)
                                  effective-policy)
                     for hinted-language = (and hints
                                              (getf (first hints) :value))
                     for allow-without-language-p =
                       (snippet-source-expansion-policy-recognize-pre-without-language-p
                        effective-policy)
                     do (touch-node :pre-region)
                        (record-language-hints hints)
                        (cond
                          ((and max-per-parent
                                (>= emitted-count max-per-parent))
                           (record-candidate-entry
                            block
                            parent-index
                            parent-location-label
                            pre-index
                            pre-source
                            pre-char-count
                            hinted-language
                            hints
                            (format nil
                                    "Rejected by max_html_pre_blocks_per_source_block (~D)."
                                    max-per-parent)
                            nil
                            pre-line-number
                            pre-character-offset)
                           (record-rejection
                            :max-per-parent
                            :rejected-by-policy
                            (format nil
                                    "Rejected candidate ~D in block #~D by max_html_pre_blocks_per_source_block (~D)."
                                    pre-index
                                    parent-index
                                    max-per-parent)
                            :block block
                            :source-line-number pre-line-number
                            :character-offset pre-character-offset
                            :evidence-value max-per-parent))
                          ((< pre-char-count min-char-count)
                           (record-candidate-entry
                            block
                            parent-index
                            parent-location-label
                            pre-index
                            pre-source
                            pre-char-count
                            hinted-language
                            hints
                            (format nil
                                    "Rejected by minimum_pre_character_count (~D)."
                                    min-char-count)
                            nil
                            pre-line-number
                            pre-character-offset)
                           (record-rejection
                            :minimum-pre-character-count
                            (if (zerop pre-char-count)
                                :empty-pre
                                :rejected-by-policy)
                            (format nil
                                    "Rejected candidate ~D in block #~D by minimum_pre_character_count (~D): ~D chars."
                                    pre-index
                                    parent-index
                                    min-char-count
                                    pre-char-count)
                            :block block
                            :source-line-number pre-line-number
                            :character-offset pre-character-offset
                            :evidence-value pre-char-count))
                          ((and (null hints)
                                (not allow-without-language-p))
                           (record-candidate-entry
                            block
                            parent-index
                            parent-location-label
                            pre-index
                            pre-source
                            pre-char-count
                            hinted-language
                            hints
                            "Rejected because recognize_pre_without_language_p is nil and no policy-approved language hint was found."
                            nil
                            pre-line-number
                            pre-character-offset)
                           (record-rejection
                            :missing-language-hint
                            :ambiguous-language
                            (format nil
                                    "Rejected candidate ~D in block #~D because no policy-approved language hint was found."
                                    pre-index
                                    parent-index)
                            :block block
                            :source-line-number pre-line-number
                            :character-offset pre-character-offset))
                          (t
                           (incf emitted-count)
                           (let* ((reason
                                    (if hints
                                        (format nil
                                                "Accepted with policy-approved language hint (~{~A~^, ~})."
                                                (mapcar (lambda (hint)
                                                          (getf hint :attribute))
                                                        hints))
                                        "Accepted as exploratory HTML <pre> candidate without language hint."))
                                  (entry
                                    (record-candidate-entry
                                     block
                                     parent-index
                                     parent-location-label
                                     pre-index
                                     pre-source
                                     pre-char-count
                                     hinted-language
                                     hints
                                     reason
                                     t
                                     pre-line-number
                                     pre-character-offset))
                                  (synthetic-block
                                    (list
                                     :line-number
                                     pre-line-number
                                     :character-offset pre-character-offset
                                     :location-label (getf entry :location_label)
                                     :open-tag
                                     (snippet-playground-html-pre-open-tag-from-hints
                                      hints)
                                     :source pre-source
                                     :origin-surface-kind
                                     (or (getf block :origin-surface-kind)
                                         "html-source")
                                     :provider-kind
                                     (or (getf block :provider-kind)
                                         "source-v1")
                                     :synthetic-kind :html-pre
                                     :synthetic-id (getf entry :synthetic_id)
                                     :synthetic-parent-index parent-index
                                     :synthetic-parent-id (getf block :id)
                                     :synthetic-parent-story-item-id
                                     (getf block :story-item-id)
                                     :synthetic-parent-location-label
                                     parent-location-label
                                     :synthetic-source-line-number
                                     pre-line-number
                                     :synthetic-character-offset
                                     pre-character-offset
                                     :synthetic-language-hint hinted-language
                                     :synthetic-language-hint-attributes hints
                                     :synthetic-reason (getf entry :reason)
                                     :synthetic-decoded-entities-p
                                     (getf entry :decoded_entities_p)
                                     :synthetic-character-count pre-char-count
                                     :synthetic-line-count
                                     (getf entry :line_count)
                                     :synthetic-source-kind :html-pre
                                     :synthetic-preview (getf entry :preview))))
                             (append-expanded-block synthetic-block)))))))))))
      (let* ((final-expanded-blocks (nreverse expanded-blocks))
             (synthetic-blocks (nreverse accepted-synthetic-entries))
             (all-candidates (nreverse candidate-entries))
             (all-discrepancies (nreverse discrepancies))
             (report-notes (nreverse notes))
             (report-warnings (nreverse warnings))
             (collect-stats-p
               (snippet-source-expansion-policy-collect-parser-stats-p
                effective-policy))
             (elapsed
               (and collect-stats-p
                    (- (snippet-playground-current-millis) parse-start)))
             (dot-text
               (and (snippet-source-expansion-policy-generate-graphviz-dot-p
                     effective-policy)
                    (snippet-source-parser-report-graphviz-dot-text
                     blocks
                     all-candidates))))
        (values
         final-expanded-blocks
         (make-snippet-source-expansion-report
          :original-block-count (length blocks)
          :expanded-block-count (length final-expanded-blocks)
          :synthetic-block-count (length synthetic-blocks)
          :synthetic-blocks synthetic-blocks
          :html-like-block-count
          (if collect-stats-p html-like-block-count 0)
          :scanned-block-count
          (if collect-stats-p scanned-block-count 0)
          :accepted-candidate-count
          (if collect-stats-p pre-regions-accepted 0)
          :rejected-candidate-count
          (if collect-stats-p pre-regions-rejected 0)
          :html-like-blocks-scanned
          (if collect-stats-p scanned-block-count 0)
          :pre-regions-found
          (if collect-stats-p pre-regions-found 0)
          :pre-regions-accepted
          (if collect-stats-p pre-regions-accepted 0)
          :pre-regions-rejected
          (if collect-stats-p pre-regions-rejected 0)
          :rejection-reasons
          (if collect-stats-p
              (loop for (reason . count) in (nreverse rejection-reasons)
                    collect (list :reason reason :count count))
              nil)
          :language-hints-observed
          (if collect-stats-p
              (loop for (hint . count) in (nreverse language-hints-observed)
                    collect (list :attribute (getf hint :attribute)
                                  :value (getf hint :value)
                                  :count count))
              nil)
          :decode-count
          (if collect-stats-p decode-count 0)
          :warnings
          (if collect-stats-p report-warnings nil)
          :discrepancies
          (if collect-stats-p all-discrepancies nil)
          :parse-elapsed-millis elapsed
          :incremental-stats-snapshots
          (if collect-stats-p
              (nreverse incremental-stats-snapshots)
              nil)
          :candidates
          (if collect-stats-p all-candidates nil)
          :graphviz-dot-text dot-text
          :graphviz-dot-path nil
          :graphviz-dot-snapshots
          (if (and collect-stats-p
                   (snippet-source-expansion-policy-generate-graphviz-dot-p
                    effective-policy))
              (nreverse graphviz-dot-snapshots)
              nil)
          :policy-summary
          (snippet-source-expansion-policy-summary effective-policy)
          :notes report-notes)))))

(defparameter *snippet-source-parser-scxml-chart-string*
  (format nil
          "<scxml name=\"snippet-source-parser-html-pre-v1\" initial=\"initialize\">~%
  <state id=\"initialize\">~%
    <onentry><log label=\"initialize\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"scan-next-block\"/>~%
  </state>~%
  <state id=\"scan-next-block\">~%
    <onentry><log label=\"scan-next-block\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"classify-block\"/>~%
  </state>~%
  <state id=\"classify-block\">~%
    <onentry><log label=\"classify-block\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"scan-html-like-block\"/>~%
  </state>~%
  <state id=\"scan-html-like-block\">~%
    <onentry><log label=\"scan-html-like-block\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"extract-next-pre\"/>~%
  </state>~%
  <state id=\"extract-next-pre\">~%
    <onentry><log label=\"extract-next-pre\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"decode-entities\"/>~%
  </state>~%
  <state id=\"decode-entities\">~%
    <onentry><log label=\"decode-entities\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"apply-policy\"/>~%
  </state>~%
  <state id=\"apply-policy\">~%
    <onentry><log label=\"apply-policy\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"emit-synthetic-block\"/>~%
  </state>~%
  <state id=\"emit-synthetic-block\">~%
    <onentry><log label=\"emit-synthetic-block\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"record-rejection\"/>~%
  </state>~%
  <state id=\"record-rejection\">~%
    <onentry><log label=\"record-rejection\"/><raise event=\"next\"/></onentry>~%
    <transition event=\"next\" target=\"finalize-report\"/>~%
  </state>~%
  <state id=\"finalize-report\">~%
    <onentry><log label=\"finalize-report\"/><raise event=\"done\"/></onentry>~%
    <transition event=\"done\" target=\"done\"/>~%
  </state>~%
  <final id=\"done\"/>~%
</scxml>"))

(defparameter *snippet-source-parser-scxml-chart* nil)

(defun snippet-source-parser-scxml-chart ()
  (or *snippet-source-parser-scxml-chart*
      (setf *snippet-source-parser-scxml-chart*
            (hyperdoc/scxml:parse-scxml-string
             *snippet-source-parser-scxml-chart-string*))))

(defun snippet-source-parser-scxml-states-from-trace (trace)
  (loop for line in (or trace '())
        for marker = (search "Entering: " line :test #'char=)
        when marker
          collect (subseq line (+ marker (length "Entering: ")))))

(defun snippet-source-parser-scxml-events-from-trace (trace)
  (loop for line in (or trace '())
        for left = (search " --" line :test #'char=)
        for right = (and left
                         (search "--> " line :test #'char=
                                 :start2 (+ left 3)))
        when (and left right)
          collect (subseq line (+ left 3) right)))

(defun snippet-source-parser-engine-from-policy (policy)
  (case (snippet-source-expansion-policy-parser-engine-kind policy)
    (:scxml
     (make-instance 'scxml-snippet-source-parser-engine
                    :chart (snippet-source-parser-scxml-chart)))
    (t
     (make-instance 'direct-snippet-source-parser-engine))))

(defmethod run-snippet-source-parser-engine
    ((engine direct-snippet-source-parser-engine) blocks policy)
  (multiple-value-bind (expanded-blocks report)
      (parse-snippet-source-blocks-direct blocks :policy policy)
    (setf (snippet-source-expansion-report-parser-engine-kind report)
          :direct
          (snippet-source-expansion-report-parser-engine-identity report)
          (snippet-source-parser-engine-identity-of engine)
          (snippet-source-expansion-report-parser-engine-chart-name report)
          nil
          (snippet-source-expansion-report-parser-engine-trace report)
          nil
          (snippet-source-expansion-report-parser-engine-states-visited report)
          nil
          (snippet-source-expansion-report-parser-engine-events report)
          nil)
    (let ((context
            (make-snippet-source-parse-context
             :policy policy
             :input-blocks blocks
             :expanded-blocks expanded-blocks
             :synthetic-blocks
             (snippet-source-expansion-report-synthetic-blocks report)
             :stats (snippet-playground-source-expansion-evidence report)
             :warnings (snippet-source-expansion-report-warnings report)
             :trace nil
             :report report)))
      (declare (ignore context)))
    (values expanded-blocks report)))

(defmethod run-snippet-source-parser-engine
    ((engine scxml-snippet-source-parser-engine) blocks policy)
  (let ((scxml-run nil)
        (scxml-warning nil))
    (handler-case
        (setf scxml-run
              (hyperdoc/scxml:run-compiled-scxml-with-events
               (chart-of engine)
               nil
               :package-name "HYPERDOC/SCXML/GENERATED/SNIPPET-SOURCE-PARSER"
               :function-name "RUN-SNIPPET-SOURCE-PARSER"))
      (error (condition)
        (setf scxml-warning
              (format nil
                      "SCXML exploratory parser orchestration failed; falling back to direct parsing: ~A"
                      condition))))
    (multiple-value-bind (expanded-blocks report)
        (parse-snippet-source-blocks-direct blocks :policy policy)
      (let* ((trace (and scxml-run
                         (hyperdoc/scxml:generated-scxml-run-trace-of scxml-run)))
             (states (snippet-source-parser-scxml-states-from-trace trace))
             (events (snippet-source-parser-scxml-events-from-trace trace))
             (chart-name (and scxml-run
                              (hyperdoc/scxml:scxml-chart-name-of
                               (chart-of engine)))))
        (setf (snippet-source-expansion-report-parser-engine-kind report)
              (if scxml-run :scxml :scxml-fallback-direct)
              (snippet-source-expansion-report-parser-engine-identity report)
              (snippet-source-parser-engine-identity-of engine)
              (snippet-source-expansion-report-parser-engine-chart-name report)
              chart-name
              (snippet-source-expansion-report-parser-engine-trace report)
              trace
              (snippet-source-expansion-report-parser-engine-states-visited report)
              states
              (snippet-source-expansion-report-parser-engine-events report)
              events)
        (when scxml-warning
          (push scxml-warning
                (snippet-source-expansion-report-warnings report))
          (push scxml-warning
                (snippet-source-expansion-report-notes report)))
        (let ((context
                (make-snippet-source-parse-context
                 :policy policy
                 :input-blocks blocks
                 :expanded-blocks expanded-blocks
                 :synthetic-blocks
                 (snippet-source-expansion-report-synthetic-blocks report)
                 :stats (snippet-playground-source-expansion-evidence report)
                 :warnings (snippet-source-expansion-report-warnings report)
                 :trace trace
                 :report report)))
          (declare (ignore context)))
        (values expanded-blocks report)))))

(defun parse-snippet-source-blocks
    (blocks &key (policy *snippet-source-expansion-policy*))
  (let* ((effective-policy (or policy *snippet-source-expansion-policy*))
         (engine (snippet-source-parser-engine-from-policy effective-policy)))
    (run-snippet-source-parser-engine
     engine
     blocks
     effective-policy)))

(defun expand-snippet-playground-source-blocks
    (blocks &key (policy *snippet-source-expansion-policy*))
  (parse-snippet-source-blocks blocks :policy policy))

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

(defun snippet-playground-next-mech-block-index
    (selected-mech recognized-mech-snippets)
  (when selected-mech
    (let ((selected-mech-block-index
            (mech-snippet-block-index-of selected-mech))
          (next-mech-block-index nil))
      (dolist (mech-snippet recognized-mech-snippets next-mech-block-index)
        (let ((block-index (mech-snippet-block-index-of mech-snippet)))
          (when (and (> block-index selected-mech-block-index)
                     (or (null next-mech-block-index)
                         (< block-index next-mech-block-index)))
            (setf next-mech-block-index block-index)))))))

(defun snippet-playground-code-snippets-for-mech-slice
    (selected-mech recognized-mech-snippets recognized-code-snippets)
  (if (null selected-mech)
      nil
      (let* ((selected-mech-block-index
               (mech-snippet-block-index-of selected-mech))
             (next-mech-block-index
               (snippet-playground-next-mech-block-index
                selected-mech
                recognized-mech-snippets)))
        (loop for code-snippet in recognized-code-snippets
              for block-index = (code-snippet-block-index-of code-snippet)
              when (and (> block-index selected-mech-block-index)
                        (or (null next-mech-block-index)
                            (< block-index next-mech-block-index)))
                collect code-snippet))))

(defun snippet-playground-code-snippet-class (snippet)
  (if (typep snippet 'javascript-code-snippet)
      'javascript-code-snippet
      'unsupported-code-snippet))

(defun snippet-playground-story-item-kind-from-location-label (location-label)
  (when (and (stringp location-label)
             (search "story item " location-label :test #'char-equal))
    (let ((open (position #\( location-label :from-end t))
          (close (position #\) location-label :from-end t)))
      (when (and open close (< open close))
        (let ((kind-token
                (string-downcase
                 (subseq location-label (1+ open) close))))
          (cond
            ((string= kind-token "code") :code)
            ((string= kind-token "mech") :mech)
            ((string= kind-token "paragraph") :paragraph)
            ((string= kind-token "markdown") :markdown)
            ((string= kind-token "reference") :reference)
            ((string= kind-token "html") :html)
            (t nil)))))))

(defun snippet-playground-synthetic-html-pre-id-from-location-label
    (location-label)
  (when (and (stringp location-label)
             (search "html-pre/" location-label :test #'char=))
    (let ((start (search "html-pre/" location-label :test #'char=))
          (end (search " from " location-label :test #'char=)))
      (when start
        (subseq location-label start (or end (length location-label)))))))

(defun snippet-playground-synthetic-html-pre-snippet-p (snippet)
  (let ((location-label (snippet-location-label-of snippet)))
    (and (stringp location-label)
         (snippet-playground-synthetic-html-pre-id-from-location-label
          location-label))))

(defun snippet-playground-source-expansion-candidate-for-snippet (snippet report)
  (let* ((location-label (snippet-location-label-of snippet))
         (synthetic-id
           (snippet-playground-synthetic-html-pre-id-from-location-label
            location-label))
         (candidates
           (and report
                (snippet-source-expansion-report-candidates report))))
    (when candidates
      (or (and location-label
               (find location-label
                     candidates
                     :key (lambda (entry)
                            (getf entry :location_label))
                     :test #'string=))
          (and synthetic-id
               (find synthetic-id
                     candidates
                     :key (lambda (entry)
                            (getf entry :synthetic_id))
                     :test #'string=))))))

(defun snippet-playground-source-expansion-candidate-discrepancy-p
    (candidate report)
  (let ((discrepancies
          (and report
               (snippet-source-expansion-report-discrepancies report))))
    (when (and candidate discrepancies)
      (let ((parent-index (getf candidate :parent_block_index))
            (line-number (getf candidate :source_line_number))
            (character-offset (getf candidate :character_offset)))
        (some (lambda (discrepancy)
                (and (or (null parent-index)
                         (eql parent-index
                              (snippet-source-parse-discrepancy-source-block-index
                               discrepancy)))
                     (or (null line-number)
                         (eql line-number
                              (snippet-source-parse-discrepancy-source-line-number
                               discrepancy)))
                     (or (null character-offset)
                         (eql character-offset
                              (snippet-source-parse-discrepancy-character-offset
                               discrepancy)))))
              discrepancies)))))

(defun snippet-playground-explicit-fedwiki-code-snippet-p (snippet)
  (eq (snippet-playground-story-item-kind-from-location-label
       (snippet-location-label-of snippet))
      :code))

(defun snippet-playground-html-wrapper-source-p (source)
  (or (snippet-playground-string-contains-p source "<pre")
      (snippet-playground-string-contains-p source "</pre>")
      (snippet-playground-string-contains-p source "<code")
      (snippet-playground-string-contains-p source "</code>")
      (snippet-playground-string-contains-p source "<p>")
      (snippet-playground-string-contains-p source "</p>")))

(defun snippet-playground-elided-source-p (source)
  (or (snippet-playground-string-contains-p source "…")
      (snippet-playground-string-contains-p source "omitted-code")
      (snippet-playground-string-contains-p source "omitted code")
      (snippet-playground-string-contains-p source "elided")))

(defun snippet-playground-synthetic-html-pre-superseded-p
    (snippet slice-code-snippets)
  (and (snippet-playground-synthetic-html-pre-snippet-p snippet)
       (let ((snippet-block-index (code-snippet-block-index-of snippet)))
         (some (lambda (candidate)
                 (and (snippet-playground-explicit-fedwiki-code-snippet-p
                       candidate)
                      (> (code-snippet-block-index-of candidate)
                         snippet-block-index)))
               slice-code-snippets))))

(defun executable-code-snippet-for-bundle-p
    (snippet &key policy report slice-code-snippets)
  (let* ((source (or (code-snippet-source-of snippet) ""))
         (story-item-kind
           (snippet-playground-story-item-kind-from-location-label
            (snippet-location-label-of snippet)))
         (synthetic-html-pre-p
           (snippet-playground-synthetic-html-pre-snippet-p snippet))
         (candidate
           (and synthetic-html-pre-p
                (snippet-playground-source-expansion-candidate-for-snippet
                 snippet
                 report)))
         (candidate-accepted-p
           (or (null candidate)
               (eql (getf candidate :status) :accepted)
               (eq (getf candidate :accepted_p) t)))
         (candidate-discrepancy-p
           (and candidate
                (snippet-playground-source-expansion-candidate-discrepancy-p
                 candidate
                 report)))
         (superseded-p
           (snippet-playground-synthetic-html-pre-superseded-p
            snippet
            slice-code-snippets))
         (html-pre-policy-allowed-p
           (or (null policy)
               (snippet-source-expansion-policy-extract-html-pre-p policy))))
    (and (typep snippet 'javascript-code-snippet)
         (not (snippet-playground-empty-string-p source))
         (not (member story-item-kind
                      '(:paragraph :markdown :reference :mech)
                      :test #'eq))
         (not (snippet-playground-html-wrapper-source-p source))
         (not (snippet-playground-elided-source-p source))
         (or (not synthetic-html-pre-p)
             (and html-pre-policy-allowed-p
                  candidate-accepted-p
                  (not candidate-discrepancy-p)
                  (not superseded-p))))))

(defun snippet-playground-bundled-code-source (snippets)
  (with-output-to-string (stream)
    (loop for snippet in snippets
          for first = t then nil
          do (unless first
               (terpri stream)
               (terpri stream))
             (write-string (code-snippet-source-of snippet) stream))))

(defun make-snippet-playground-bundled-code-snippet
    (selected-mech entry-snippet ordered-slice-code-snippets)
  (let* ((bundle-count (length ordered-slice-code-snippets))
         (first-slice-snippet (first ordered-slice-code-snippets))
         (last-slice-snippet (car (last ordered-slice-code-snippets)))
         (selected-mech-block-index
           (mech-snippet-block-index-of selected-mech))
         (entry-block-index
           (code-snippet-block-index-of entry-snippet))
         (first-block-index
           (code-snippet-block-index-of first-slice-snippet))
         (last-block-index
           (code-snippet-block-index-of last-slice-snippet))
         (language-label
           (code-language-display-name
            (code-snippet-language-of entry-snippet)))
         (bundle-findings
           (append (copy-list (code-snippet-findings-of entry-snippet))
                   (list (format nil
                                 "Bundled ~D code snippets from the Mech slice after block #~D."
                                 bundle-count
                                 selected-mech-block-index)))))
    (make-instance
     (snippet-playground-code-snippet-class entry-snippet)
     :id (format nil "code-snippet-bundle/mech-~D/code-~D-~D"
                 selected-mech-block-index
                 first-block-index
                 last-block-index)
     :title (format nil "~A code bundle #~D"
                    language-label
                    entry-block-index)
     :summary
     (format nil
             "Bundled ~D ~A code blocks from the Mech slice after block #~D."
             bundle-count
             (string-downcase language-label)
             selected-mech-block-index)
     :block-index entry-block-index
     :line-number (code-snippet-line-number-of entry-snippet)
     :location-label
     (format nil "Mech slice after block #~D (blocks #~D-#~D)"
             selected-mech-block-index
             first-block-index
             last-block-index)
     :source
     (snippet-playground-bundled-code-source ordered-slice-code-snippets)
     :language (code-snippet-language-of entry-snippet)
     :output-path (code-snippet-output-path-of entry-snippet)
     :translation-mode (code-snippet-translation-mode-of entry-snippet)
     :score (code-snippet-score-of entry-snippet)
     :findings bundle-findings)))

(defun select-code-snippet-for-mech-slice
    (selected-mech recognized-mech-snippets recognized-code-snippets
     &key policy report)
  (let* ((slice-code-snippets
           (snippet-playground-code-snippets-for-mech-slice
            selected-mech
            recognized-mech-snippets
            recognized-code-snippets))
         (executable-snippets
           (remove-if-not
            (lambda (snippet)
              (executable-code-snippet-for-bundle-p
               snippet
               :policy policy
               :report report
               :slice-code-snippets slice-code-snippets))
            slice-code-snippets))
         (entry-snippet
           (select-best-snippet executable-snippets
                                #'code-snippet-score-of)))
    (if (and entry-snippet
             (> (length executable-snippets) 1))
        (make-snippet-playground-bundled-code-snippet
         selected-mech
         entry-snippet
         (sort (copy-list executable-snippets)
               #'<
               :key #'code-snippet-block-index-of))
        entry-snippet)))

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

(defun make-snippet-rita-projection
    (mech code execution-interface &key scaffold-source)
  (let ((effective-scaffold-source
          (or scaffold-source
              (and code
                   (snippet-playground-lisp-scaffold nil code)))))
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
     :lisp-scaffold-source effective-scaffold-source
     :findings
     (snippet-rita-projection-findings execution-interface
                                       effective-scaffold-source))))

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

(defun snippet-playground-mech-operation-entries (mech)
  (if mech
      (loop for step in (mech-snippet-steps-of mech)
            collect (list :operation (mech-snippet-step-operation-of step)
                          :arguments (copy-list
                                      (mech-snippet-step-arguments-of step))
                          :line-number (mech-snippet-step-line-number-of step)))
      nil))

(defun snippet-playground-mech-code-step (mech)
  (when mech
    (find "CODE"
          (mech-snippet-steps-of mech)
          :key #'mech-snippet-step-operation-of
          :test #'string=)))

(defun snippet-playground-parse-code-argument-value (argument)
  (if-let (number (and argument
                       (ignore-errors (parse-integer argument))))
    number
    argument))

(defun snippet-playground-mech-code-function-name (mech)
  (let ((code-step (snippet-playground-mech-code-step mech)))
    (and code-step
         (first (mech-snippet-step-arguments-of code-step)))))

(defun snippet-playground-mech-code-arguments (mech)
  (let* ((code-step (snippet-playground-mech-code-step mech))
         (args (and code-step (rest (mech-snippet-step-arguments-of code-step)))))
    (mapcar #'snippet-playground-parse-code-argument-value
            (or args '()))))

(defun snippet-playground-default-neighborhood-input ()
  (list
   (list :title "Alpha" :links '("Gamma" "Delta" "Gamma"))
   (list :title "Beta" :links '("Gamma" "Epsilon"))
   (list :title "Gamma" :links '("Delta" "Epsilon" "Gamma"))
   (list :title "Delta" :links '("Gamma"))))

(defun snippet-playground-neighborhood-links-from-page (page)
  (cond
    ((null page)
     nil)
    ((hash-table-p page)
     (copy-list (or (gethash "links" page)
                    (gethash :links page)
                    '())))
    ((and (listp page)
          (every #'consp page))
     (copy-list (or (cdr (assoc :links page))
                    (cdr (assoc "links" page :test #'string=))
                    '())))
    ((listp page)
     (copy-list (or (getf page :links)
                    (getf page "links")
                    '())))
    (t
     nil)))

(defun snippet-playground-neighborhood-title-from-page (page index)
  (cond
    ((null page)
     (format nil "page-~D" index))
    ((hash-table-p page)
     (or (gethash "title" page)
         (gethash :title page)
         (format nil "page-~D" index)))
    ((and (listp page)
          (every #'consp page))
     (or (cdr (assoc :title page))
         (cdr (assoc "title" page :test #'string=))
         (format nil "page-~D" index)))
    ((listp page)
     (or (getf page :title)
         (getf page "title")
         (format nil "page-~D" index)))
    (t
     (format nil "page-~D" index))))

(defun snippet-playground-normalize-neighborhood-input (neighborhood)
  (loop for page in (or neighborhood '())
        for index from 1
        for title = (snippet-playground-neighborhood-title-from-page page index)
        for links = (snippet-playground-neighborhood-links-from-page page)
        collect (list :title (format nil "~A" title)
                      :links (sort (mapcar (lambda (link-title)
                                             (format nil "~A" link-title))
                                           (or links '()))
                                   #'string<))))

(defun snippet-playground-plist-like-p (value)
  (and (listp value)
       (evenp (length value))
       (loop for (key nil) on value by #'cddr
             always (or (keywordp key)
                        (symbolp key)
                        (stringp key)))))

(defun snippet-playground-alist-like-p (value)
  (and (listp value)
       (every #'consp value)
       (loop for entry in value
             always (or (keywordp (car entry))
                        (symbolp (car entry))
                        (stringp (car entry))))))

(defun snippet-playground-object-key-string (key)
  (cond
    ((stringp key)
     key)
    ((keywordp key)
     (string-downcase (symbol-name key)))
    ((symbolp key)
     (string-downcase (symbol-name key)))
    (t
     (format nil "~A" key))))

(defun snippet-playground-normalize-object-entries (entries)
  (sort
   (loop for (key . value) in entries
         collect (cons (snippet-playground-object-key-string key)
                       (snippet-playground-normalize-runtime-value value)))
   #'string<
   :key #'car))

(defun snippet-playground-normalize-runtime-value (value)
  (cond
    ((null value)
     nil)
    ((or (stringp value)
         (numberp value)
         (characterp value)
         (eq value t))
     value)
    ((hash-table-p value)
     (list :object
           (snippet-playground-normalize-object-entries
            (loop for key being the hash-keys in value
                  collect (cons key (gethash key value))))))
    ((snippet-playground-plist-like-p value)
     (list :object
           (snippet-playground-normalize-object-entries
            (loop for (key raw-value) on value by #'cddr
                  collect (cons key raw-value)))))
    ((snippet-playground-alist-like-p value)
     (list :object
           (snippet-playground-normalize-object-entries value)))
    ((vectorp value)
     (list :array
           (loop for item across value
                 collect (snippet-playground-normalize-runtime-value item))))
    ((listp value)
     (list :array
           (mapcar #'snippet-playground-normalize-runtime-value value)))
    ((symbolp value)
     (string-downcase (symbol-name value)))
    (t
     (format nil "~A" value))))

(defun snippet-playground-mech-state-value-at-handoff-path (state handoff-path)
  (if (string= (or handoff-path "") "state.items")
      (or (getf state :items)
          (getf state "items"))
      nil))

(defun snippet-playground-popular-bundle-missing-constructs (code-source)
  (let ((checks '(("export function popular" . "popular(count) export")
                  ("function links" . "links helper")
                  ("function desc" . "desc helper")
                  ("function report" . "report helper")
                  ("class Bag" . "Bag class")
                  ("addAll" . "Bag.addAll helper method"))))
    (loop for (token . label) in checks
          unless (snippet-playground-string-contains-p code-source token)
            collect label)))

(defun snippet-playground-copy-execution-state (state)
  (copy-tree (or state '())))

(defun rita-links (bag page)
  (dolist (link-title (getf page :links))
    (incf (gethash link-title bag 0)))
  bag)

(defun rita-bag-add-all (bag pages)
  (dolist (page (or pages '()))
    (rita-links bag page))
  bag)

(defun rita-bag->tally-entries (bag)
  (loop for title being the hash-keys in bag
        using (hash-value count)
        collect (list :title title :count count)))

(defun rita-desc (left right)
  (let ((left-count (or (getf left :count) 0))
        (right-count (or (getf right :count) 0))
        (left-title (or (getf left :title) ""))
        (right-title (or (getf right :title) "")))
    (or (> left-count right-count)
        (and (= left-count right-count)
             (string< left-title right-title)))))

(defun rita-report (entry)
  (list :title (getf entry :title)
        :count (getf entry :count)))

(defun rita-popular (state count)
  (let* ((bag (make-hash-table :test #'equal))
         (neighborhood (or (getf state :neighborhood) '()))
         (trace (list "rita-popular: initialize bag"
                      "rita-popular: tally neighborhood links")))
    (rita-bag-add-all bag neighborhood)
    (let* ((tally (sort (rita-bag->tally-entries bag) #'rita-desc))
           (bounded-count (max 0 (or count 0)))
           (top (subseq tally 0 (min (length tally) bounded-count)))
           (items (mapcar #'rita-report top))
           (return-value (format nil "~D linked pages" (length tally))))
      (setf (getf state :items) items)
      (push "rita-popular: publish state.items and return summary" trace)
      (values return-value state (nreverse trace)))))

(defun lefty-links (bag page)
  (dolist (link-title (getf page :links))
    (incf (gethash link-title bag 0)))
  bag)

(defun lefty-bag-add-all (bag pages)
  (dolist (page (or pages '()))
    (lefty-links bag page))
  bag)

(defun lefty-bag->tally-entries (bag)
  (loop for title being the hash-keys in bag
        using (hash-value count)
        collect (list :title title :count count)))

(defun lefty-desc (left right)
  (let ((left-count (or (getf left :count) 0))
        (right-count (or (getf right :count) 0))
        (left-title (or (getf left :title) ""))
        (right-title (or (getf right :title) "")))
    (or (> left-count right-count)
        (and (= left-count right-count)
             (string< left-title right-title)))))

(defun lefty-report (entry)
  (list :title (getf entry :title)
        :count (getf entry :count)))

(defun lefty-popular (state count)
  (let* ((bag (make-hash-table :test #'equal))
         (neighborhood (or (getf state :neighborhood) '()))
         (trace (list "lefty-popular: initialize Bag"
                      "lefty-popular: Bag.addAll(neighborhood)"
                      "lefty-popular: tally.sort(desc).slice(0,count)"
                      "lefty-popular: items = top.map(report)")))
    (lefty-bag-add-all bag neighborhood)
    (let* ((tally (sort (lefty-bag->tally-entries bag) #'lefty-desc))
           (bounded-count (max 0 (or count 0)))
           (top (subseq tally 0 (min (length tally) bounded-count)))
           (items (mapcar #'lefty-report top))
           (return-value (format nil "~D linked pages" (length tally))))
      (setf (getf state :items) items)
      (values return-value state trace))))

(defun make-mech-run-result
    (&key engine status return-value final-state normalized-output trace
       diagnostics unsupported-constructs source-provenance)
  (make-instance
   'mech-run-result
   :id (format nil "mech-run-result/~(~A~)" engine)
   :title (format nil "~(~A~) run result" engine)
   :summary (format nil "~(~A~) execution status: ~(~A~)." engine status)
   :engine engine
   :status status
   :return-value return-value
   :final-state final-state
   :normalized-output normalized-output
   :trace trace
   :diagnostics diagnostics
   :unsupported-constructs unsupported-constructs
   :source-provenance source-provenance))

(defun run-lefty-mech-execution (execution-input)
  (let* ((code (mech-execution-input-selected-code-of execution-input))
         (code-source (and code (code-snippet-source-of code)))
         (operation-name
           (mech-execution-input-code-operation-name-of execution-input))
         (args (mech-execution-input-code-operation-arguments-of execution-input))
         (count-arg (first args))
         (handoff-path (mech-execution-input-handoff-path-of execution-input))
         (missing-constructs
           (snippet-playground-popular-bundle-missing-constructs
            (or code-source "")))
         (unsupported-constructs
           (append
            (unless (and operation-name
                         (string-equal operation-name "popular"))
              (list (format nil
                            "Unsupported CODE operation ~A; only popular is currently executable."
                            (or operation-name "n/a"))))
            (unless (string= (or handoff-path "") "state.items")
              (list (format nil
                            "Unsupported handoff path ~A; only state.items is currently executable."
                            (or handoff-path "n/a"))))
            (unless (integerp count-arg)
              (list (format nil
                            "Unsupported CODE argument ~S; popular currently requires an integer count."
                            count-arg)))
            (mapcar (lambda (item)
                      (format nil "Missing popular bundle construct: ~A" item))
                    missing-constructs))))
    (if unsupported-constructs
        (make-mech-run-result
         :engine :lefty
         :status :unsupported
         :diagnostics
         (list "Lefty execution stayed bounded; unsupported constructs were reported.")
         :unsupported-constructs unsupported-constructs
         :source-provenance
         (list :code_block (and code (code-snippet-block-index-of code))
               :code_location (and code (snippet-location-label-of code))))
        (handler-case
            (let ((state
                    (snippet-playground-copy-execution-state
                     (mech-execution-input-normalized-state-of execution-input))))
              (multiple-value-bind (return-value final-state trace)
                  (lefty-popular state count-arg)
                (let ((output
                        (snippet-playground-mech-state-value-at-handoff-path
                         final-state
                         handoff-path)))
                  (make-mech-run-result
                   :engine :lefty
                   :status :ok
                   :return-value (snippet-playground-normalize-runtime-value
                                  return-value)
                   :final-state (snippet-playground-normalize-runtime-value
                                 final-state)
                   :normalized-output
                   (snippet-playground-normalize-runtime-value output)
                   :trace trace
                   :diagnostics
                   (list "Lefty execution completed through the bounded popular(count) runner.")
                   :source-provenance
                   (list :code_block (and code (code-snippet-block-index-of code))
                         :code_location (and code (snippet-location-label-of
                                                   code))
                         :operation operation-name
                         :arguments args)))))
          (error (condition)
            (make-mech-run-result
             :engine :lefty
             :status :error
             :diagnostics
             (list (format nil "Lefty execution error: ~A" condition))
             :source-provenance
             (list :operation operation-name
                   :arguments args)))))))

(defun run-rita-mech-execution (execution-input)
  (let* ((operation-name
           (mech-execution-input-code-operation-name-of execution-input))
         (args (mech-execution-input-code-operation-arguments-of execution-input))
         (count-arg (first args))
         (handoff-path (mech-execution-input-handoff-path-of execution-input))
         (unsupported-constructs
           (append
            (unless (and operation-name
                         (string-equal operation-name "popular"))
              (list (format nil
                            "Rita currently implements only popular; got ~A."
                            (or operation-name "n/a"))))
            (unless (string= (or handoff-path "") "state.items")
              (list (format nil
                            "Rita currently supports only state.items handoff; got ~A."
                            (or handoff-path "n/a"))))
            (unless (integerp count-arg)
              (list (format nil
                            "Rita popular currently requires an integer count; got ~S."
                            count-arg))))))
    (if unsupported-constructs
        (make-mech-run-result
         :engine :rita
         :status :unsupported
         :diagnostics
         (list "Rita execution stayed bounded; unsupported constructs were reported.")
         :unsupported-constructs unsupported-constructs
         :source-provenance (list :operation operation-name :arguments args))
        (handler-case
            (let ((state
                    (snippet-playground-copy-execution-state
                     (mech-execution-input-normalized-state-of execution-input))))
              (multiple-value-bind (return-value final-state trace)
                  (rita-popular state count-arg)
                (let ((output
                        (snippet-playground-mech-state-value-at-handoff-path
                         final-state
                         handoff-path)))
                  (make-mech-run-result
                   :engine :rita
                   :status :ok
                   :return-value (snippet-playground-normalize-runtime-value
                                  return-value)
                   :final-state (snippet-playground-normalize-runtime-value
                                 final-state)
                   :normalized-output
                   (snippet-playground-normalize-runtime-value output)
                   :trace trace
                   :diagnostics
                   (list "Rita execution completed through hand-authored popular(count) helpers.")
                   :source-provenance
                   (list :operation operation-name
                         :arguments args)))))
          (error (condition)
            (make-mech-run-result
             :engine :rita
             :status :error
             :diagnostics
             (list (format nil "Rita execution error: ~A" condition))
             :source-provenance
             (list :operation operation-name
                   :arguments args)))))))

(defun make-mech-equivalence-differences (lefty-run-result rita-run-result)
  (let ((differences '()))
    (unless (eq (mech-run-result-status-of lefty-run-result)
                (mech-run-result-status-of rita-run-result))
      (push (list :kind :status-mismatch
                  :lefty (mech-run-result-status-of lefty-run-result)
                  :rita (mech-run-result-status-of rita-run-result))
            differences))
    (unless (equal (mech-run-result-normalized-output-of lefty-run-result)
                   (mech-run-result-normalized-output-of rita-run-result))
      (push (list :kind :output-mismatch
                  :lefty (mech-run-result-normalized-output-of lefty-run-result)
                  :rita (mech-run-result-normalized-output-of rita-run-result))
            differences))
    (unless (equal (mech-run-result-return-value-of lefty-run-result)
                   (mech-run-result-return-value-of rita-run-result))
      (push (list :kind :return-value-mismatch
                  :lefty (mech-run-result-return-value-of lefty-run-result)
                  :rita (mech-run-result-return-value-of rita-run-result))
            differences))
    (nreverse differences)))

(defun make-mech-equivalence-report (lefty-run-result rita-run-result)
  (let* ((unsupported-constructs
           (append (when lefty-run-result
                     (copy-list
                      (mech-run-result-unsupported-constructs-of
                       lefty-run-result)))
                   (when rita-run-result
                     (copy-list
                      (mech-run-result-unsupported-constructs-of
                       rita-run-result)))))
         (differences
           (if (and lefty-run-result rita-run-result)
               (make-mech-equivalence-differences
                lefty-run-result
                rita-run-result)
               (list (list :kind :missing-run-results))))
         (equal-p
           (and (null unsupported-constructs)
                (null differences)
                (eq (mech-run-result-status-of lefty-run-result) :ok)
                (eq (mech-run-result-status-of rita-run-result) :ok)))
         (comparison-value
           (list :lefty (and lefty-run-result
                             (mech-run-result-normalized-output-of
                              lefty-run-result))
                 :rita (and rita-run-result
                            (mech-run-result-normalized-output-of
                             rita-run-result)))))
    (make-instance
     'mech-equivalence-report
     :id "mech-equivalence-report/state.items"
     :title "Mech execution equivalence"
     :summary
     (if equal-p
         "Lefty and Rita agree on normalized state.items output."
         "Lefty and Rita do not currently prove normalized state.items equivalence.")
     :lefty-run-result lefty-run-result
     :rita-run-result rita-run-result
     :normalized-comparison-value comparison-value
     :equal-p equal-p
     :differences differences
     :unsupported-constructs unsupported-constructs
     :source-provenance
     (list :lefty (and lefty-run-result
                       (mech-run-result-source-provenance-of
                        lefty-run-result))
           :rita (and rita-run-result
                      (mech-run-result-source-provenance-of
                       rita-run-result)))
     :findings
     (if equal-p
         (list "Normalized state.items outputs match across Lefty and Rita.")
         (list "Equivalence is explicit and inspectable; unsupported or mismatched paths are reported without fake success.")))))

(defun snippet-playground-helper-function-labels (code-source)
  (remove nil
          (list (and (snippet-playground-string-contains-p
                      code-source
                      "function links")
                     "links")
                (and (snippet-playground-string-contains-p
                      code-source
                      "function desc")
                     "desc")
                (and (snippet-playground-string-contains-p
                      code-source
                      "function report")
                     "report")
                (and (snippet-playground-string-contains-p
                      code-source
                      "class Bag")
                     "Bag.addAll"))))

(defun make-mech-state-items-ir (execution-input equivalence-report)
  (let* ((code (mech-execution-input-selected-code-of execution-input))
         (code-source (or (and code (code-snippet-source-of code)) ""))
         (function-name
           (mech-execution-input-code-operation-name-of execution-input))
         (function-arguments
           (copy-list (mech-execution-input-code-operation-arguments-of
                       execution-input)))
         (output-path (mech-execution-input-handoff-path-of execution-input))
         (equivalence-status
           (cond
             ((null equivalence-report)
              :unavailable)
             ((mech-equivalence-report-equal-p equivalence-report)
              :equal)
             ((mech-equivalence-report-unsupported-constructs-of
               equivalence-report)
              :unsupported)
             (t
              :different))))
    (make-instance
     'mech-state-items-ir
     :id (format nil "mech-state-items-ir/~A/~A"
                 (or function-name "unknown")
                 (or output-path "unresolved"))
     :title "Mech state.items IR"
     :summary
     (format nil
             "Bounded semantic IR for ~A(~{~A~^, ~}) writing to ~A."
             (or function-name "unknown")
             function-arguments
             (or output-path "unresolved"))
     :input-slots '("neighborhood")
     :output-path output-path
     :function-name function-name
     :function-arguments function-arguments
     :helper-functions (snippet-playground-helper-function-labels code-source)
     :operation-summary
     "Tally neighborhood links, sort by descending count, report top N items, and publish to state.items."
     :equivalence-status equivalence-status
     :source-provenance
     (list :mech_block
           (and (mech-execution-input-selected-mech-of execution-input)
                (mech-snippet-block-index-of
                 (mech-execution-input-selected-mech-of execution-input)))
           :code_block
           (and code
                (code-snippet-block-index-of code))
           :code_location
           (and code
                (snippet-location-label-of code)))
     :findings
     (list "IR is semantic and bounded to the state.items popular(count) execution seam."))))

(defun make-mech-execution-input
    (selected-mech selected-code execution-interface
     &key neighborhood-input)
  (let* ((effective-neighborhood
           (snippet-playground-normalize-neighborhood-input
            (or neighborhood-input
                (snippet-playground-default-neighborhood-input))))
         (code-operation-name
           (snippet-playground-mech-code-function-name selected-mech))
         (code-operation-arguments
           (snippet-playground-mech-code-arguments selected-mech))
         (handoff-path
           (and execution-interface
                (snippet-execution-interface-handoff-path-of execution-interface))))
    (make-instance
     'mech-execution-input
     :id (format nil "mech-execution-input/~A/~A"
                 (or (and selected-mech
                          (mech-snippet-block-index-of selected-mech))
                     "mech")
                 (or (and selected-code
                          (code-snippet-block-index-of selected-code))
                     "code"))
     :title "Mech execution input"
     :summary
     (format nil
             "Normalized Mech/code execution input for ~A via ~A."
             (or code-operation-name "unknown")
             (or handoff-path "unresolved"))
     :selected-mech selected-mech
     :selected-code selected-code
     :normalized-state (list :neighborhood effective-neighborhood
                             :items nil)
     :parsed-mech-operations
     (snippet-playground-mech-operation-entries selected-mech)
     :code-operation-name code-operation-name
     :code-operation-arguments code-operation-arguments
     :handoff-path handoff-path
     :findings
     (list "Execution input keeps Mech/code evidence and normalized neighborhood state in one inspectable object."))))

(defun mech-ir-token-slug (token)
  (let ((text (string-downcase (format nil "~A" token))))
    (let ((slug
            (with-output-to-string (stream)
              (loop with emitted-p = nil
                    with pending-dash-p = nil
                    for char across text
                    do (cond
                         ((or (alphanumericp char)
                              (char= char #\_))
                          (when (and pending-dash-p emitted-p)
                            (write-char #\- stream))
                          (setf pending-dash-p nil)
                          (write-char char stream)
                          (setf emitted-p t))
                         (emitted-p
                          (setf pending-dash-p t)))))))
      (if (zerop (length slug))
          "token"
          slug))))

(defun mech-ir-operation-state-id (operation-entry click-index)
  (let* ((operation (string-upcase (or (getf operation-entry :operation) "")))
         (arguments (or (getf operation-entry :arguments) '()))
         (state-id
           (cond
             ((string= operation "CLICK")
              (format nil "click-~D" (max 1 click-index)))
             ((string= operation "NEIGHBORS")
              (if arguments
                  (format nil "load-neighborhood-~A"
                          (mech-ir-token-slug (format nil "~{~A~^-~}" arguments)))
                  "load-neighborhood"))
             ((string= operation "CODE")
              (format nil "run-code-~A"
                      (if arguments
                          (mech-ir-token-slug
                           (format nil "~{~A~^-~}" arguments))
                          "unknown")))
             ((string= operation "PREVIEW")
              (format nil "preview-~A"
                      (if arguments
                          (mech-ir-token-slug
                           (format nil "~{~A~^-~}" arguments))
                          "output")))
             (t
              (format nil "operation-~A-~D"
                      (mech-ir-token-slug operation)
                      (or (getf operation-entry :index) 0))))))
    state-id))

(defun mech-ir-click-groups-from-operations (operations)
  (let ((groups '()))
    (dolist (operation operations)
      (let ((group-index (getf operation :click-group)))
        (when group-index
          (let ((existing
                  (assoc group-index groups :test #'=)))
            (if existing
                (setf (cdr existing)
                      (append (cdr existing) (list operation)))
                (push (cons group-index (list operation)) groups))))))
    (mapcar (lambda (entry)
              (list :click-group (car entry)
                    :operations (cdr entry)))
            (sort groups #'< :key #'car))))

(defun mech-ir-required-inputs-from-operations (operations)
  (loop for operation in operations
        when (string= (string-upcase (or (getf operation :operation) ""))
                      "NEIGHBORS")
          collect (list :kind :neighbors
                        :source (format nil "~{~A~^ ~}"
                                        (or (getf operation :arguments) '()))
                        :state-id (getf operation :state-id)
                        :line-number (getf operation :line-number))))

(defun mech-ir-code-invocations-from-operations (operations)
  (loop for operation in operations
        when (string= (string-upcase (or (getf operation :operation) ""))
                      "CODE")
          collect (list :function-name (first (getf operation :arguments))
                        :arguments
                        (mapcar #'snippet-playground-parse-code-argument-value
                                (rest (or (getf operation :arguments) '())))
                        :state-id (getf operation :state-id)
                        :line-number (getf operation :line-number))))

(defun mech-ir-preview-output-paths-from-operations (operations)
  (loop for operation in operations
        when (string= (string-upcase (or (getf operation :operation) ""))
                      "PREVIEW")
          collect (list :path (format nil "~{~A~^ ~}"
                                      (or (getf operation :arguments) '()))
                        :state-id (getf operation :state-id)
                        :line-number (getf operation :line-number))))

(defun mech-ir-unsupported-operations-from-operations (operations)
  (remove nil
          (mapcar (lambda (operation)
                    (let ((token (string-upcase (or (getf operation :operation) ""))))
                      (unless (member token
                                      '("CLICK" "NEIGHBORS" "CODE" "PREVIEW")
                                      :test #'string=)
                        (list :operation token
                              :arguments (copy-list
                                          (or (getf operation :arguments) '()))
                              :line-number (getf operation :line-number)
                              :state-id (getf operation :state-id)))))
                  operations)))

(defun make-mech-execution-ir (execution-input)
  (let* ((source-mech (mech-execution-input-selected-mech-of execution-input))
         (raw-operations
           (copy-tree (or (mech-execution-input-parsed-mech-operations-of
                           execution-input)
                          '())))
         (click-index 0)
         (operations
           (loop for raw-operation in raw-operations
                 for operation-index from 1
                 for operation-token =
                   (string-upcase (or (getf raw-operation :operation) ""))
                 do (when (string= operation-token "CLICK")
                      (incf click-index))
                 collect
                 (let* ((state-click-index
                          (if (plusp click-index) click-index 1))
                        (entry
                          (list :index operation-index
                                :operation operation-token
                                :arguments
                                (copy-list (or (getf raw-operation :arguments)
                                               '()))
                                :line-number (getf raw-operation :line-number)
                                :click-group state-click-index)))
                   (setf (getf entry :state-id)
                         (mech-ir-operation-state-id
                          entry
                          state-click-index)
                         (getf entry :provenance)
                         (list :line-number (getf entry :line-number)
                               :operation (getf entry :operation)
                               :arguments (copy-list
                                           (getf entry :arguments))))
                   entry)))
         (click-groups (mech-ir-click-groups-from-operations operations))
         (required-inputs (mech-ir-required-inputs-from-operations operations))
         (code-invocations (mech-ir-code-invocations-from-operations operations))
         (preview-output-paths
           (mech-ir-preview-output-paths-from-operations operations))
         (unsupported-operations
           (mech-ir-unsupported-operations-from-operations operations)))
    (make-instance
     'mech-execution-ir
     :id (format nil "mech-execution-ir/~A"
                 (or (and source-mech
                          (mech-snippet-block-index-of source-mech))
                     "unknown"))
     :title "Mech execution IR"
     :summary
     (format nil
             "Parsed Mech execution IR with ~D operation~:P and ~D click group~:P."
             (length operations)
             (length click-groups))
     :source-mech source-mech
     :ordered-operations operations
     :click-groups click-groups
     :required-inputs required-inputs
     :code-invocations code-invocations
     :preview-output-paths preview-output-paths
     :provenance
     (list :mech_block
           (and source-mech
                (mech-snippet-block-index-of source-mech))
           :mech_location
           (and source-mech
                (snippet-location-label-of source-mech)))
     :unsupported-operations unsupported-operations
     :findings
     (append
      (list "Mech execution IR is derived directly from the selected Mech snippet operation sequence.")
      (when unsupported-operations
        (list "IR records unsupported Mech operations explicitly for chart/report propagation."))))))

(defun mech-ir-terminal-result-state-for-event (event)
  (cond
    ((string= event "result/ok")
     "done")
    ((string= event "result/different")
     "different")
    (t
     "unsupported")))

(defun mech-ir-to-state-machine-definition (ir)
  (let* ((operations (or (mech-execution-ir-ordered-operations-of ir) '()))
         (state-ids (mapcar (lambda (operation)
                              (getf operation :state-id))
                            operations))
         (operation-transitions
           (loop with chain = (append state-ids
                                      (list "compare-equivalence"))
                 for source in (cons "initial" chain)
                 for target in chain
                 for transition-index from 1
                 when target
                   collect
                   (make-state-machine-transition
                    :id (format nil "mech-ir/step-~D" transition-index)
                    :title (format nil "Step ~D" transition-index)
                    :from-state source
                    :to-state target
                    :trigger (format nil "step/~A" target)
                    :notes (format nil "Advance to ~A." target))))
         (result-transitions
           (list
            (make-state-machine-transition
             :id "mech-ir/result-ok"
             :title "Result ok"
             :from-state "compare-equivalence"
             :to-state "done"
             :trigger "result/ok")
            (make-state-machine-transition
             :id "mech-ir/result-different"
             :title "Result different"
             :from-state "compare-equivalence"
             :to-state "different"
             :trigger "result/different")
            (make-state-machine-transition
             :id "mech-ir/result-unsupported"
             :title "Result unsupported"
             :from-state "compare-equivalence"
             :to-state "unsupported"
             :trigger "result/unsupported")))
         (states
           (append
            (list
             (make-state-machine-state
              :id "initial"
              :title "Initial"
              :summary "Initial Mech execution state before operation sequencing."))
            (mapcar (lambda (operation)
                      (make-state-machine-state
                       :id (getf operation :state-id)
                       :title (format nil "~A ~{~A~^ ~}"
                                      (or (getf operation :operation) "OP")
                                      (or (getf operation :arguments) '()))
                       :summary
                       (format nil "Mech line ~A."
                               (or (getf operation :line-number) "n/a"))))
                    operations)
            (list
             (make-state-machine-state
              :id "compare-equivalence"
              :title "Compare equivalence"
              :summary "Compare normalized state.items output between Lefty and Rita.")
             (make-state-machine-state
              :id "done"
              :title "Done"
              :summary "SCXML Mech execution completed with equivalence.")
             (make-state-machine-state
              :id "different"
              :title "Different"
              :summary "SCXML Mech execution completed with differences.")
             (make-state-machine-state
              :id "unsupported"
              :title "Unsupported"
              :summary "SCXML Mech execution completed with unsupported constructs.")))))
    (make-state-machine-definition
     :id (format nil "state-machine-definition/mech-ir/~A"
                 (or (id-of ir) "unknown"))
     :title "Mech execution SCXML machine"
     :summary "State machine generated from parsed Mech execution IR."
     :states states
     :transitions (append operation-transitions result-transitions)
     :initial-state "initial"
     :terminal-states '("done" "different" "unsupported")
     :failure-states '("different" "unsupported")
     :events
     (append (mapcar (lambda (operation)
                       (format nil "step/~A" (getf operation :state-id)))
                     operations)
             (list "step/compare-equivalence"
                   "result/ok"
                   "result/different"
                   "result/unsupported"))
     :invariants
     (list
      (list :label "Mech operation order"
            :detail "SCXML transition sequence preserves parsed Mech operation order.")
      (list :label "Bounded semantic seam"
            :detail "CODE operation dispatch remains bounded to the state.items popular(count) seam."))
     :source-evidence
     (list
      (list :layer :semantic
            :reference "mech-execution-ir"
            :detail (summary-of ir))))))

(defun mech-ir-to-scxml-chart (ir)
  (let* ((machine (mech-ir-to-state-machine-definition ir))
         (scxml-text (state-machine-definition-scxml-text machine))
         (chart nil)
         (warning nil))
    (handler-case
        (setf chart (hyperdoc/scxml:parse-scxml-string scxml-text))
      (error (condition)
        (setf warning
              (format nil "Failed to parse generated Mech SCXML chart: ~A"
                      condition))))
    (make-instance
     'mech-scxml-execution-chart
     :id (format nil "mech-scxml-execution-chart/~A"
                 (or (id-of ir) "unknown"))
     :title "Mech-derived SCXML chart"
     :summary
     "Executable SCXML chart generated from parsed Mech execution IR."
     :chart-name
     (or (and chart
              (hyperdoc/scxml:scxml-chart-name-of chart))
         (id-of machine))
     :initial-state (state-machine-definition-initial-state-of machine)
     :terminal-states (copy-list
                       (state-machine-definition-terminal-states-of machine))
     :failure-states (copy-list
                      (state-machine-definition-failure-states-of machine))
     :events
     (copy-list (state-machine-definition-events-of machine))
     :execution-ir ir
     :machine-definition machine
     :chart chart
     :scxml-text scxml-text
     :findings
     (append
      (list "SCXML chart is generated from Mech IR operation states and transitions.")
      (when warning
        (list warning))))))

(defun mech-scxml-state-sequence-events (ir)
  (append
   (mapcar (lambda (operation)
             (format nil "step/~A" (getf operation :state-id)))
           (or (mech-execution-ir-ordered-operations-of ir) '()))
   (list "step/compare-equivalence")))

(defun mech-scxml-run-trace-states (trace)
  (loop for line in (or trace '())
        for marker = (search "Entering: " line :test #'char=)
        when marker
          collect (subseq line (+ marker (length "Entering: ")))))

(defun mech-scxml-result-event
    (lefty-run-result rita-run-result equivalence-report ir)
  (cond
    ((mech-execution-ir-unsupported-operations-of ir)
     "result/unsupported")
    ((or (eq (mech-run-result-status-of lefty-run-result) :unsupported)
         (eq (mech-run-result-status-of rita-run-result) :unsupported)
         (mech-equivalence-report-unsupported-constructs-of equivalence-report))
     "result/unsupported")
    ((mech-equivalence-report-equal-p equivalence-report)
     "result/ok")
    (t
     "result/different")))

(defun run-mech-ir-semantic-actions (ir execution-input)
  (let ((operations-by-state
          (make-hash-table :test #'equal))
        (semantic-trace '())
        (lefty-run-result nil)
        (rita-run-result nil))
    (dolist (operation (or (mech-execution-ir-ordered-operations-of ir) '()))
      (setf (gethash (getf operation :state-id) operations-by-state)
            operation))
    (labels
        ((dispatch-state-action (state-id)
           (let ((operation (gethash state-id operations-by-state)))
             (when operation
               (let ((token (string-upcase (or (getf operation :operation) ""))))
                 (push (format nil "mech-ir action: ~A (~A)"
                               token
                               state-id)
                       semantic-trace)
                 (cond
                   ((string= token "NEIGHBORS")
                    (push "loaded normalized neighborhood input"
                          semantic-trace))
                   ((string= token "CODE")
                    (setf lefty-run-result
                          (run-lefty-mech-execution execution-input)
                          rita-run-result
                          (run-rita-mech-execution execution-input))
                    (push "dispatched bounded Lefty and Rita CODE runners"
                          semantic-trace))
                   ((string= token "PREVIEW")
                    (push "preview operation consumed state.items handoff"
                          semantic-trace))
                   (t
                    (push (format nil "unsupported Mech operation ~A recorded"
                                  token)
                          semantic-trace))))))))
      (values
       (lambda (state-id)
         (dispatch-state-action state-id))
       (lambda ()
         (nreverse semantic-trace))
       (lambda ()
         (values lefty-run-result rita-run-result))))))

(defun run-mech-scxml-execution
    (scxml-chart execution-input ir lefty-run-result rita-run-result
     equivalence-report)
  (let* ((chart (and scxml-chart (mech-scxml-execution-chart-chart-of scxml-chart)))
         (chart-name
           (or (and scxml-chart
                    (mech-scxml-execution-chart-name-of scxml-chart))
               "mech-ir-chart"))
         (state-sequence-events (mech-scxml-state-sequence-events ir))
         (result-event
           (mech-scxml-result-event
            lefty-run-result
            rita-run-result
            equivalence-report
            ir))
         (events (append state-sequence-events (list result-event)))
         (generated-run nil)
         (warning nil))
    (if (null chart)
        (make-mech-run-result
         :engine :scxml
         :status :error
         :diagnostics
         (list "Generated Mech SCXML chart is unavailable; chart execution could not run.")
         :source-provenance (list :chart_name chart-name))
        (progn
          (handler-case
              (setf generated-run
                    (hyperdoc/scxml:run-compiled-scxml-with-events
                     chart
                     events
                     :package-name "HYPERDOC/SCXML/GENERATED/MECH-EXECUTION"
                     :function-name "RUN-MECH-EXECUTION-CHART"))
            (error (condition)
              (setf warning
                    (format nil "SCXML execution failed: ~A" condition))))
          (if (or warning (null generated-run))
              (make-mech-run-result
               :engine :scxml
               :status :error
               :diagnostics
               (list (or warning
                         "SCXML execution failed without a concrete condition."))
               :source-provenance
               (list :chart_name chart-name
                     :events events))
              (let* ((final-state
                       (hyperdoc/scxml:generated-scxml-run-final-state-of
                        generated-run))
                     (done-p
                       (hyperdoc/scxml:generated-scxml-run-done-p
                        generated-run))
                     (status
                       (cond
                         ((string= (or final-state "") "done")
                          :ok)
                         ((string= (or final-state "") "different")
                          :different)
                         ((string= (or final-state "") "unsupported")
                          :unsupported)
                         (t
                          :error))))
                (make-mech-run-result
                 :engine :scxml
                 :status status
                 :return-value result-event
                 :final-state
                 (list :initial-state
                       (and scxml-chart
                            (mech-scxml-execution-chart-initial-state-of
                             scxml-chart))
                       :final-state final-state
                       :done-p done-p)
                 :normalized-output
                 (and equivalence-report
                      (mech-equivalence-report-normalized-comparison-value-of
                       equivalence-report))
                 :trace (hyperdoc/scxml:generated-scxml-run-trace-of
                         generated-run)
                 :diagnostics
                 (list
                  (format nil
                          "SCXML chart ~A executed ~D event~:P and reached ~A."
                          chart-name
                          (length events)
                          final-state))
                 :unsupported-constructs
                 (and (eq status :unsupported)
                      (append (copy-list
                               (or (mech-execution-ir-unsupported-operations-of
                                    ir)
                                   '()))
                              (copy-list
                               (or (mech-equivalence-report-unsupported-constructs-of
                                    equivalence-report)
                                   '()))))
                 :source-provenance
                 (list :chart_name chart-name
                       :events events
                       :result_event result-event))))))))

(defun run-mech-scxml-equivalence-orchestration
    (execution-input ir scxml-chart)
  (let* ((chart (and scxml-chart (mech-scxml-execution-chart-chart-of scxml-chart)))
         (prefix-events (mech-scxml-state-sequence-events ir))
         (prefix-run nil)
         (prefix-warning nil)
         (dispatcher nil)
         (semantic-trace-reader nil)
         (results-reader nil)
         (lefty-run-result nil)
         (rita-run-result nil))
    (multiple-value-setq (dispatcher semantic-trace-reader results-reader)
      (run-mech-ir-semantic-actions ir execution-input))
    (when chart
      (handler-case
          (setf prefix-run
                (hyperdoc/scxml:run-compiled-scxml-with-events
                 chart
                 prefix-events
                 :package-name "HYPERDOC/SCXML/GENERATED/MECH-EXECUTION/PREFIX"
                 :function-name "RUN-MECH-EXECUTION-CHART-PREFIX"))
        (error (condition)
          (setf prefix-warning
                (format nil "SCXML prefix orchestration failed: ~A" condition)))))
    (dolist (state-id
             (if prefix-run
                 (mech-scxml-run-trace-states
                  (hyperdoc/scxml:generated-scxml-run-trace-of prefix-run))
                 (mapcar (lambda (operation)
                           (getf operation :state-id))
                         (or (mech-execution-ir-ordered-operations-of ir) '()))))
      (when dispatcher
        (funcall dispatcher state-id)))
    (multiple-value-setq (lefty-run-result rita-run-result)
      (if results-reader
          (funcall results-reader)
          (values nil nil)))
    (unless lefty-run-result
      (setf lefty-run-result
            (make-mech-run-result
             :engine :lefty
             :status :unsupported
             :diagnostics
             (list "No CODE operation was dispatched from Mech execution IR.")
             :unsupported-constructs (list "Missing CODE operation in Mech execution IR."))))
    (unless rita-run-result
      (setf rita-run-result
            (make-mech-run-result
             :engine :rita
             :status :unsupported
             :diagnostics
             (list "No CODE operation was dispatched from Mech execution IR.")
             :unsupported-constructs (list "Missing CODE operation in Mech execution IR."))))
    (let* ((equivalence-report
             (make-mech-equivalence-report
              lefty-run-result
              rita-run-result))
           (scxml-run-result
             (run-mech-scxml-execution
              scxml-chart
              execution-input
              ir
              lefty-run-result
              rita-run-result
              equivalence-report)))
      (when prefix-warning
        (setf scxml-run-result
              (make-mech-run-result
               :engine :scxml
               :status :error
               :return-value (mech-run-result-return-value-of scxml-run-result)
               :final-state (mech-run-result-final-state-of scxml-run-result)
               :normalized-output
               (mech-run-result-normalized-output-of scxml-run-result)
               :trace (mech-run-result-trace-of scxml-run-result)
               :diagnostics
               (append (list prefix-warning)
                       (copy-list
                        (or (mech-run-result-diagnostics-of scxml-run-result)
                            '())))
               :unsupported-constructs
               (mech-run-result-unsupported-constructs-of scxml-run-result)
               :source-provenance
               (mech-run-result-source-provenance-of scxml-run-result))))
      (let ((semantic-trace (and semantic-trace-reader
                                 (funcall semantic-trace-reader))))
        (when semantic-trace
          (setf scxml-run-result
                (make-mech-run-result
                 :engine :scxml
                 :status (mech-run-result-status-of scxml-run-result)
                 :return-value (mech-run-result-return-value-of scxml-run-result)
                 :final-state (mech-run-result-final-state-of scxml-run-result)
                 :normalized-output
                 (mech-run-result-normalized-output-of scxml-run-result)
                 :trace
                 (append (copy-list (or (mech-run-result-trace-of scxml-run-result)
                                        '()))
                         semantic-trace)
                 :diagnostics
                 (mech-run-result-diagnostics-of scxml-run-result)
                 :unsupported-constructs
                 (mech-run-result-unsupported-constructs-of scxml-run-result)
                 :source-provenance
                 (mech-run-result-source-provenance-of scxml-run-result)))))
      (values lefty-run-result
              rita-run-result
              equivalence-report
              scxml-run-result))))

(defun mech-lisp-scaffold-source-from-ir
    (ir execution-input scxml-chart scxml-run-result)
  (declare (ignore scxml-run-result))
  (let* ((operation-name
           (or (mech-execution-input-code-operation-name-of execution-input)
               "popular"))
         (count-value
           (or (first (mech-execution-input-code-operation-arguments-of
                       execution-input))
               0))
         (normalized-neighborhood
           (getf (mech-execution-input-normalized-state-of execution-input)
                 :neighborhood))
         (chart-name
           (or (and scxml-chart
                    (mech-scxml-execution-chart-name-of scxml-chart))
               "n/a"))
         (operations (or (mech-execution-ir-ordered-operations-of ir) '())))
    (with-output-to-string (stream)
      (format stream
              ";; Lisp scaffold derived from Mech execution IR + generated SCXML chart.~%")
      (dolist (operation operations)
        (format stream
                ";; Mech operation line ~A: ~A ~{~A~^ ~}~%"
                (or (getf operation :line-number) "n/a")
                (or (getf operation :operation) "OP")
                (or (getf operation :arguments) '())))
      (format stream
              ";; SCXML chart name: ~A~%"
              chart-name)
      (format stream
              "(let* ((session *)~%")
      (format stream
              "       (normalized-neighborhood ~S)~%"
              normalized-neighborhood)
      (format stream
              "       (count ~S))~%"
              count-value)
      (write-line "  (labels ((rita-links (bag page)" stream)
      (write-line "             (dolist (link-title (getf page :links))" stream)
      (write-line "               (incf (gethash link-title bag 0)))" stream)
      (write-line "             bag)" stream)
      (write-line "           (rita-bag-add-all (bag pages)" stream)
      (write-line "             (dolist (page (or pages '()))" stream)
      (write-line "               (rita-links bag page))" stream)
      (write-line "             bag)" stream)
      (write-line "           (rita-bag->tally-entries (bag)" stream)
      (write-line "             (loop for title being the hash-keys in bag" stream)
      (write-line "                   using (hash-value item-count)" stream)
      (write-line "                   collect (list :title title :count item-count)))" stream)
      (write-line "           (rita-desc (left right)" stream)
      (write-line "             (let ((left-count (or (getf left :count) 0))" stream)
      (write-line "                   (right-count (or (getf right :count) 0))" stream)
      (write-line "                   (left-title (or (getf left :title) \"\"))" stream)
      (write-line "                   (right-title (or (getf right :title) \"\")))" stream)
      (write-line "               (or (> left-count right-count)" stream)
      (write-line "                   (and (= left-count right-count)" stream)
      (write-line "                        (string< left-title right-title)))))" stream)
      (write-line "           (rita-report (entry)" stream)
      (write-line "             (list :title (getf entry :title)" stream)
      (write-line "                   :count (getf entry :count)))" stream)
      (write-line "           (rita-popular (state count)" stream)
      (write-line "             (let* ((bag (make-hash-table :test #'equal))" stream)
      (write-line "                    (neighborhood (or (getf state :neighborhood) '())))" stream)
      (write-line "               (rita-bag-add-all bag neighborhood)" stream)
      (write-line "               (let* ((tally (sort (rita-bag->tally-entries bag) #'rita-desc))" stream)
      (write-line "                      (bounded-count (max 0 (or count 0)))" stream)
      (write-line "                      (top (subseq tally 0 (min (length tally) bounded-count)))" stream)
      (write-line "                      (items (mapcar #'rita-report top))" stream)
      (write-line "                      (return-value (format nil \"~D linked pages\" (length tally))))" stream)
      (write-line "                 (setf (getf state :items) items)" stream)
      (write-line "                 (values return-value state items))))" stream)
      (write-line "           (run-rita-popular-mech (&key (neighborhood normalized-neighborhood) (count count))" stream)
      (write-line "             (let ((state (list :neighborhood (copy-tree neighborhood) :items nil)))" stream)
      (write-line "               (rita-popular state count))))" stream)
      (write-line "    (multiple-value-bind (return-value final-state state-items)" stream)
      (write-line "        (run-rita-popular-mech)" stream)
      (write-line "      (declare (ignore final-state))" stream)
      (write-line "      ;; SCXML runner orchestrates the same Mech execution path from IR-derived chart states." stream)
      (write-line "      (let* ((execution-input (hyperdoc::snippet-playground-session-mech-execution-input-of session))" stream)
      (write-line "             (execution-ir (hyperdoc::snippet-playground-session-mech-execution-ir-of session))" stream)
      (write-line "             (scxml-chart (hyperdoc::snippet-playground-session-mech-scxml-execution-chart-of session))" stream)
      (write-line "             (lefty-run (hyperdoc::run-lefty-mech-execution execution-input))" stream)
      (write-line "             (rita-run (hyperdoc::run-rita-mech-execution execution-input))" stream)
      (write-line "             (equivalence (hyperdoc::make-mech-equivalence-report lefty-run rita-run))" stream)
      (write-line "             (scxml-run (hyperdoc::run-mech-scxml-execution scxml-chart execution-input execution-ir lefty-run rita-run equivalence)))" stream)
      (write-line "        (setf (hyperdoc::snippet-playground-session-derived-items-of session) state-items)" stream)
      (format stream
              "        (list :operation ~S~%"
              operation-name)
      (write-line "              :output-path \"state.items\"" stream)
      (write-line "              :return-value return-value" stream)
      (write-line "              :state-items state-items" stream)
      (write-line "              :scxml-final-state (getf (hyperdoc::mech-run-result-final-state-of scxml-run) :final-state)" stream)
      (write-line "              :scxml-done-p (getf (hyperdoc::mech-run-result-final-state-of scxml-run) :done-p)" stream)
      (write-line "              :scxml-trace (hyperdoc::mech-run-result-trace-of scxml-run))))))" stream))))

(defun make-mech-lisp-scaffold-source
    (ir execution-input transformation-ir scxml-chart scxml-run-result
     equivalence-report code)
  (let* ((source
           (if (and execution-input
                    (string-equal
                     (or (mech-execution-input-code-operation-name-of
                          execution-input)
                         "")
                     "popular"))
               (mech-lisp-scaffold-source-from-ir
                ir
                execution-input
                scxml-chart
                scxml-run-result)
               (and code
                    (snippet-playground-lisp-scaffold nil code)))))
    (make-instance
     'mech-lisp-scaffold-source
     :id (format nil "mech-lisp-scaffold-source/~A"
                 (or (and execution-input (id-of execution-input))
                     "unknown"))
     :title "Mech-derived Lisp scaffold source"
     :summary
     "Lisp scaffold derived from Mech execution IR, generated SCXML chart, and Rita semantic functions."
     :source source
     :execution-input execution-input
     :transformation-ir transformation-ir
     :scxml-execution-chart scxml-chart
     :scxml-run-result scxml-run-result
     :equivalence-report equivalence-report
     :findings
     (list
      "Scaffold source is generated from Mech execution IR and SCXML orchestration, not a static JavaScript excerpt."
      "Rita semantic functions and a Mech runner are included in the scaffold source."))))

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
       transformation-unit mech-execution-ir execution-input lefty-run-result
       rita-run-result equivalence-report transformation-ir
       mech-scxml-execution-chart scxml-run-result mech-lisp-scaffold-source
       origin-pane-id pending-pane-id
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
     :mech-execution-ir mech-execution-ir
     :execution-input execution-input
     :lefty-run-result lefty-run-result
     :rita-run-result rita-run-result
     :equivalence-report equivalence-report
     :transformation-ir transformation-ir
     :mech-scxml-execution-chart mech-scxml-execution-chart
     :scxml-run-result scxml-run-result
     :mech-lisp-scaffold-source mech-lisp-scaffold-source
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
    (selected-mech selected-code execution-interface transformation-unit
     equivalence-report mech-execution-ir mech-scxml-execution-chart
     scxml-run-result mech-lisp-scaffold-source)
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
    (when mech-execution-ir
      (push "Parsed Mech snippet operations into a Mech execution IR with click-group and provenance tracking."
            findings))
    (when mech-scxml-execution-chart
      (push "Generated an executable SCXML chart from the Mech execution IR operation sequence."
            findings))
    (when scxml-run-result
      (push (format nil "SCXML orchestration run recorded explicit status ~A."
                    (mech-run-result-status-of scxml-run-result))
            findings))
    (when equivalence-report
      (push (if (mech-equivalence-report-equal-p equivalence-report)
                "Recorded a Lefty/Rita execution equivalence report for state.items."
                "Recorded a Lefty/Rita execution report with explicit mismatches or unsupported constructs.")
            findings))
    (when mech-lisp-scaffold-source
      (push "Lisp scaffold source is derived from Mech IR + generated SCXML chart + Rita semantic functions."
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
       blocks origin-surface-kind provider-kind source-label
       source-expansion-policy source-parser-policy
       execution-neighborhood-input)
  (let* ((resolved-source-label
           (or source-label
               (ignore-errors (title-of context-object))
               (and source-pathname
                    (file-namestring source-pathname))
               "Source"))
         (effective-source-expansion-policy
           (or source-parser-policy
               source-expansion-policy
               *snippet-source-expansion-policy*))
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
         (expanded-blocks nil)
         (source-expansion-report nil)
         (recognized-mech-snippets nil)
         (recognized-code-snippets nil)
         (selected-mech nil)
         (selected-code nil)
         (execution-interface nil)
         (mech-execution-ir nil)
         (transformation-unit nil)
         (mech-execution-input nil)
         (lefty-run-result nil)
         (rita-run-result nil)
         (equivalence-report nil)
         (transformation-ir nil)
         (mech-scxml-execution-chart nil)
         (scxml-run-result nil)
         (mech-lisp-scaffold-source nil)
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
                                 :mech-execution-ir mech-execution-ir
                                 :execution-input mech-execution-input
                                 :lefty-run-result lefty-run-result
                                 :rita-run-result rita-run-result
                                 :equivalence-report equivalence-report
                                 :transformation-ir transformation-ir
                                 :mech-scxml-execution-chart
                                 mech-scxml-execution-chart
                                 :scxml-run-result scxml-run-result
                                 :mech-lisp-scaffold-source
                                 mech-lisp-scaffold-source
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
                     :source-block-count
                     (or (and source-expansion-report
                              (snippet-source-expansion-report-expanded-block-count
                               source-expansion-report))
                         (length (or expanded-blocks blocks)))
                     :source-expansion-report source-expansion-report
                     :recognized-mech-snippets recognized-mech-snippets
                     :recognized-code-snippets recognized-code-snippets
                     :selected-mech selected-mech
                     :selected-code selected-code
                     :execution-interface execution-interface
                     :mech-execution-ir mech-execution-ir
                     :transformation-unit transformation-unit
                     :mech-execution-input mech-execution-input
                     :lefty-run-result lefty-run-result
                     :rita-run-result rita-run-result
                     :equivalence-report equivalence-report
                     :transformation-ir transformation-ir
                     :mech-scxml-execution-chart
                     mech-scxml-execution-chart
                     :scxml-run-result scxml-run-result
                     :mech-lisp-scaffold-source mech-lisp-scaffold-source
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
                                transformation-unit
                                equivalence-report
                                mech-execution-ir
                                mech-scxml-execution-chart
                                scxml-run-result
                                mech-lisp-scaffold-source)))
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
                     :mech-execution-ir mech-execution-ir
                     :transformation-unit transformation-unit
                     :mech-execution-input mech-execution-input
                     :lefty-run-result lefty-run-result
                     :rita-run-result rita-run-result
                     :equivalence-report equivalence-report
                     :transformation-ir transformation-ir
                     :mech-scxml-execution-chart
                     mech-scxml-execution-chart
                     :scxml-run-result scxml-run-result
                     :mech-lisp-scaffold-source mech-lisp-scaffold-source
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
            (multiple-value-setq (expanded-blocks source-expansion-report)
              (parse-snippet-source-blocks
               blocks
               :policy effective-source-expansion-policy))
            (note-evidence
             :collecting-input
             "Collected provider-specific snippet candidates."
             (append
              (snippet-playground-source-expansion-evidence
               source-expansion-report)
              (list :origin_surface_kind origin-surface-kind
                    :provider_kind provider-kind)))
            (advance :recognizing
                     :input-collected
                     (format nil "Recognizing snippet candidates from ~D collected inputs."
                             (length expanded-blocks))
                     :guard :input-extracted
                     :progress-phase :recognizing
                     :progress-message "Recognizing snippets...")
            (setf recognized-mech-snippets
                  (remove nil
                          (mapcar #'maybe-make-mech-snippet expanded-blocks)))
            (setf recognized-code-snippets
                  (recognized-code-snippets-from-blocks expanded-blocks))
            (note-evidence
             :recognizing
             "Recognition finished."
             (append
              (snippet-playground-source-expansion-evidence
               source-expansion-report)
              (list
               :recognized_mech_snippets
               (snippet-playground-snippet-labels recognized-mech-snippets)
               :recognized_code_snippets
               (snippet-playground-snippet-labels recognized-code-snippets))))
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
                  (select-code-snippet-for-mech-slice
                   selected-mech
                   recognized-mech-snippets
                   recognized-code-snippets
                   :policy effective-source-expansion-policy
                   :report source-expansion-report))
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
            (setf mech-execution-input
                  (make-mech-execution-input
                   selected-mech
                   selected-code
                   execution-interface
                   :neighborhood-input execution-neighborhood-input))
            (setf mech-execution-ir
                  (make-mech-execution-ir mech-execution-input))
            (setf mech-scxml-execution-chart
                  (mech-ir-to-scxml-chart mech-execution-ir))
            (multiple-value-setq (lefty-run-result
                                  rita-run-result
                                  equivalence-report
                                  scxml-run-result)
              (run-mech-scxml-equivalence-orchestration
               mech-execution-input
               mech-execution-ir
               mech-scxml-execution-chart))
            (setf transformation-ir
                  (make-mech-state-items-ir
                   mech-execution-input
                   equivalence-report))
            (setf mech-lisp-scaffold-source
                  (make-mech-lisp-scaffold-source
                   mech-execution-ir
                   mech-execution-input
                   transformation-ir
                   mech-scxml-execution-chart
                   scxml-run-result
                   equivalence-report
                   selected-code))
            (setf rita-projection
                  (make-snippet-rita-projection
                   selected-mech
                   selected-code
                   execution-interface
                   :scaffold-source
                   (and mech-lisp-scaffold-source
                        (mech-lisp-scaffold-source-source-of
                         mech-lisp-scaffold-source))))
            (setf transformation-unit
                  (make-snippet-transformation-unit
                   selected-mech
                   selected-code
                   execution-interface
                   lefty-projection
                   rita-projection))
            (note-evidence
             :building-session
             "Constructed Mech IR, generated SCXML chart, and chart-orchestrated Lefty/Rita execution equivalence evidence."
             (list
              :execution_interface
              (snippet-playground-object-label execution-interface)
              :mech_execution_ir
              (snippet-playground-object-label mech-execution-ir)
              :mech_scxml_execution_chart
              (snippet-playground-object-label mech-scxml-execution-chart)
              :scxml_status
              (and scxml-run-result
                   (mech-run-result-status-of scxml-run-result))
              :transformation_unit
              (snippet-playground-object-label transformation-unit)
              :mech_execution_input
              (snippet-playground-object-label mech-execution-input)
              :lefty_status
              (and lefty-run-result
                   (mech-run-result-status-of lefty-run-result))
              :rita_status
              (and rita-run-result
                   (mech-run-result-status-of rita-run-result))
              :equivalent_p
              (and equivalence-report
                   (mech-equivalence-report-equal-p equivalence-report))
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
    (&key context-object context-view-title source-pathname source-text
       source-expansion-policy source-parser-policy
       execution-neighborhood-input)
  (let ((trimmed-source (or source-text "")))
    (make-snippet-playground-result-from-blocks
     :context-object context-object
     :context-view-title context-view-title
     :source-pathname source-pathname
     :source-text trimmed-source
     :blocks (extract-html-code-blocks trimmed-source)
     :origin-surface-kind "html-source"
     :provider-kind "source-v1"
     :source-expansion-policy source-expansion-policy
     :source-parser-policy source-parser-policy
     :execution-neighborhood-input execution-neighborhood-input)))

(defun make-snippet-playground-session-from-fedwiki-page
    (&key context-object context-view-title page
       source-expansion-policy source-parser-policy
       execution-neighborhood-input)
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
     :source-label (and page (title-of page))
     :source-expansion-policy source-expansion-policy
     :source-parser-policy source-parser-policy
     :execution-neighborhood-input execution-neighborhood-input)))

(defun make-snippet-playground-session-target
    (&key context-object context-view-title source-pathname fedwiki-page
       provider-kind origin-surface-kind
       source-expansion-policy source-parser-policy
       execution-neighborhood-input)
  (cond
    ((or (string= (or provider-kind "") "fedwiki-v1")
         (string= (or origin-surface-kind "") "fedwiki-page")
         fedwiki-page)
     (make-snippet-playground-session-from-fedwiki-page
      :context-object context-object
      :context-view-title context-view-title
      :page fedwiki-page
      :source-expansion-policy source-expansion-policy
      :source-parser-policy source-parser-policy
      :execution-neighborhood-input execution-neighborhood-input))
    ((and source-pathname
          (probe-file source-pathname))
     (make-snippet-playground-session-from-source
      :context-object context-object
      :context-view-title context-view-title
      :source-pathname source-pathname
      :source-text (uiop:read-file-string source-pathname)
      :source-expansion-policy source-expansion-policy
      :source-parser-policy source-parser-policy
      :execution-neighborhood-input execution-neighborhood-input))
    (t
     (make-snippet-playground-session-from-source
      :context-object context-object
      :context-view-title context-view-title
      :source-pathname source-pathname
      :source-text ""
      :source-expansion-policy source-expansion-policy
      :source-parser-policy source-parser-policy
      :execution-neighborhood-input execution-neighborhood-input))))

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
                       :source-expansion-report
                       (snippet-playground-session-source-expansion-report-of
                        session)
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
                       :mech-execution-ir
                       (snippet-playground-session-mech-execution-ir-of session)
                       :transformation-unit
                       (snippet-playground-session-transformation-unit-of
                        session)
                       :mech-execution-input
                       (snippet-playground-session-mech-execution-input-of
                        session)
                       :lefty-run-result
                       (snippet-playground-session-lefty-run-result-of session)
                       :rita-run-result
                       (snippet-playground-session-rita-run-result-of session)
                       :equivalence-report
                       (snippet-playground-session-equivalence-report-of
                        session)
                       :transformation-ir
                       (snippet-playground-session-transformation-ir-of
                        session)
                       :mech-scxml-execution-chart
                       (snippet-playground-session-mech-scxml-execution-chart-of
                        session)
                       :scxml-run-result
                       (snippet-playground-session-scxml-run-result-of session)
                       :mech-lisp-scaffold-source
                       (snippet-playground-session-mech-lisp-scaffold-source-of
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

(defun snippet-playground-value-or-na (value)
  (if (null value)
      "n/a"
      (format nil "~S" value)))

(defun snippet-comparison-render-mech-run-result (label run-result)
  (html-inspector-views:html
    (:h4 (html-inspector-views:esc label))
    (if run-result
        (html-inspector-views:html
          (:table :class "inspector-table"
                  (snippet-playground-status-table-row
                   "Engine"
                   (mech-run-result-engine-of run-result))
                  (snippet-playground-status-table-row
                   "Status"
                   (mech-run-result-status-of run-result))
                  (snippet-playground-status-table-row
                   "Return value"
                   (snippet-playground-value-or-na
                    (mech-run-result-return-value-of run-result))))
          (:h5 "Normalized output")
          (snippet-source-pre
           (snippet-playground-value-or-na
            (mech-run-result-normalized-output-of run-result)))
          (:h5 "Diagnostics")
          (snippet-source-pre
           (snippet-playground-value-or-na
            (mech-run-result-diagnostics-of run-result)))
          (:h5 "Trace")
          (snippet-source-pre
           (snippet-playground-value-or-na
            (mech-run-result-trace-of run-result))))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "Run result is unavailable."))))))

(defun snippet-comparison-render-execution-equivalence (surface)
  (let ((execution-input
          (snippet-comparison-surface-execution-input-of surface))
        (mech-execution-ir
          (snippet-comparison-surface-mech-execution-ir-of surface))
        (mech-scxml-execution-chart
          (snippet-comparison-surface-mech-scxml-execution-chart-of surface))
        (scxml-run-result
          (snippet-comparison-surface-scxml-run-result-of surface))
        (lefty-run-result
          (snippet-comparison-surface-lefty-run-result-of surface))
        (rita-run-result
          (snippet-comparison-surface-rita-run-result-of surface))
        (equivalence-report
          (snippet-comparison-surface-equivalence-report-of surface))
        (transformation-ir
          (snippet-comparison-surface-transformation-ir-of surface))
        (mech-lisp-scaffold-source
          (snippet-comparison-surface-mech-lisp-scaffold-source-of surface)))
    (html-inspector-views:html
      (:div :class "hyperdoc-snippet-execution-equivalence"
            (:h3 "Execution equivalence")
            (:table :class "inspector-table"
                    (maybe-object-ref-row "Execution input" execution-input)
                    (maybe-object-ref-row "Mech execution IR" mech-execution-ir)
                    (maybe-object-ref-row "Generated SCXML chart"
                                          mech-scxml-execution-chart)
                    (maybe-object-ref-row "SCXML run result" scxml-run-result)
                    (maybe-object-ref-row "Lefty run result" lefty-run-result)
                    (maybe-object-ref-row "Rita run result" rita-run-result)
                    (maybe-object-ref-row "Equivalence report" equivalence-report)
                    (maybe-object-ref-row "Shared IR" transformation-ir)
                    (maybe-object-ref-row "Mech-derived Lisp scaffold source"
                                          mech-lisp-scaffold-source))
            (if mech-execution-ir
                (html-inspector-views:html
                  (:h4 "Parsed Mech operations")
                  (:table :class "inspector-table"
                          (snippet-playground-status-table-row
                           "Click groups"
                           (length
                            (or (mech-execution-ir-click-groups-of
                                 mech-execution-ir)
                                '())))
                          (snippet-playground-status-table-row
                           "Required inputs"
                           (length
                            (or (mech-execution-ir-required-inputs-of
                                 mech-execution-ir)
                                '())))
                          (snippet-playground-status-table-row
                           "Code invocations"
                           (length
                            (or (mech-execution-ir-code-invocations-of
                                 mech-execution-ir)
                                '())))
                          (snippet-playground-status-table-row
                           "Preview output paths"
                           (length
                            (or (mech-execution-ir-preview-output-paths-of
                                 mech-execution-ir)
                                '())))
                          (snippet-playground-status-table-row
                           "Unsupported operations"
                           (length
                            (or (mech-execution-ir-unsupported-operations-of
                                 mech-execution-ir)
                                '()))))
                  (:table :class "inspector-table"
                          (:tr (:th "Line")
                               (:th "Operation")
                               (:th "Arguments")
                               (:th "Click group")
                               (:th "State id"))
                          (dolist (operation
                                   (or (mech-execution-ir-ordered-operations-of
                                        mech-execution-ir)
                                       '()))
                            (html-inspector-views:html
                              (:tr
                               (:td (html-inspector-views:esc
                                     (format nil "~A"
                                             (or (getf operation :line-number)
                                                 "n/a"))))
                               (:td (html-inspector-views:esc
                                     (or (getf operation :operation) "")))
                               (:td (html-inspector-views:esc
                                     (format nil "~{~A~^ ~}"
                                             (or (getf operation :arguments)
                                                 '()))))
                               (:td (html-inspector-views:esc
                                     (format nil "~A"
                                             (or (getf operation :click-group)
                                                 "n/a"))))
                               (:td (html-inspector-views:esc
                                     (or (getf operation :state-id) ""))))))))
                (html-inspector-views:html
                  (:p (html-inspector-views:esc
                       "Mech execution IR is unavailable."))))
            (if mech-scxml-execution-chart
                (html-inspector-views:html
                  (:h4 "Generated SCXML chart")
                  (:table :class "inspector-table"
                          (snippet-playground-status-table-row
                           "Chart name"
                           (mech-scxml-execution-chart-name-of
                            mech-scxml-execution-chart))
                          (snippet-playground-status-table-row
                           "Initial state"
                           (mech-scxml-execution-chart-initial-state-of
                            mech-scxml-execution-chart))
                          (snippet-playground-status-table-row
                           "Terminal states"
                           (mech-scxml-execution-chart-terminal-states-of
                            mech-scxml-execution-chart))
                          (snippet-playground-status-table-row
                           "Failure states"
                           (mech-scxml-execution-chart-failure-states-of
                            mech-scxml-execution-chart))
                          (snippet-playground-status-table-row
                           "Events"
                           (mech-scxml-execution-chart-events-of
                            mech-scxml-execution-chart)))
                  (:h5 "SCXML source")
                  (snippet-source-pre
                   (snippet-playground-value-or-na
                    (mech-scxml-execution-chart-scxml-text-of
                     mech-scxml-execution-chart))))
                (html-inspector-views:html
                  (:p (html-inspector-views:esc
                       "Generated SCXML chart is unavailable."))))
            (if execution-input
                (html-inspector-views:html
                  (:h4 "Execution input")
                  (:table :class "inspector-table"
                          (snippet-playground-status-table-row
                           "Function"
                           (mech-execution-input-code-operation-name-of
                            execution-input))
                          (snippet-playground-status-table-row
                           "Arguments"
                           (mech-execution-input-code-operation-arguments-of
                            execution-input))
                          (snippet-playground-status-table-row
                           "Output path"
                           (mech-execution-input-handoff-path-of
                            execution-input)))
                  (:h5 "Normalized neighborhood state")
                  (snippet-source-pre
                   (snippet-playground-value-or-na
                    (mech-execution-input-normalized-state-of
                     execution-input))))
                (html-inspector-views:html
                  (:p (html-inspector-views:esc
                       "Execution input is unavailable."))))
            (snippet-comparison-render-mech-run-result
             "SCXML run"
             scxml-run-result)
            (snippet-comparison-render-mech-run-result
             "Lefty run"
             lefty-run-result)
            (snippet-comparison-render-mech-run-result
             "Rita run"
             rita-run-result)
            (if equivalence-report
                (html-inspector-views:html
                  (:h4 "Equivalence report")
                  (:table :class "inspector-table"
                          (snippet-playground-status-table-row
                           "equal-p"
                           (if (mech-equivalence-report-equal-p
                                equivalence-report)
                               "true"
                               "false"))
                          (snippet-playground-status-table-row
                           "Unsupported constructs"
                           (length
                            (or (mech-equivalence-report-unsupported-constructs-of
                                 equivalence-report)
                                '())))
                          (snippet-playground-status-table-row
                           "Differences"
                           (length
                            (or (mech-equivalence-report-differences-of
                                 equivalence-report)
                                '()))))
                  (:h5 "Normalized comparison value")
                  (snippet-source-pre
                   (snippet-playground-value-or-na
                    (mech-equivalence-report-normalized-comparison-value-of
                     equivalence-report)))
                  (:h5 "Differences")
                  (snippet-source-pre
                   (snippet-playground-value-or-na
                    (mech-equivalence-report-differences-of
                     equivalence-report)))
                  (:h5 "Unsupported constructs")
                  (snippet-source-pre
                   (snippet-playground-value-or-na
                    (mech-equivalence-report-unsupported-constructs-of
                     equivalence-report))))
                (html-inspector-views:html
                  (:p (html-inspector-views:esc
                       "Equivalence report is unavailable."))))
            (if transformation-ir
                (html-inspector-views:html
                  (:h4 "Shared IR")
                  (:table :class "inspector-table"
                          (snippet-playground-status-table-row
                           "Function"
                           (mech-state-items-ir-function-name-of
                            transformation-ir))
                          (snippet-playground-status-table-row
                           "Arguments"
                           (mech-state-items-ir-function-arguments-of
                            transformation-ir))
                          (snippet-playground-status-table-row
                           "Input slots"
                           (mech-state-items-ir-input-slots-of
                            transformation-ir))
                          (snippet-playground-status-table-row
                           "Output path"
                           (mech-state-items-ir-output-path-of
                            transformation-ir))
                          (snippet-playground-status-table-row
                           "Helpers"
                           (mech-state-items-ir-helper-functions-of
                            transformation-ir))
                          (snippet-playground-status-table-row
                           "Equivalence status"
                           (mech-state-items-ir-equivalence-status-of
                            transformation-ir)))
                  (:h5 "Operation summary")
                  (snippet-source-pre
                   (snippet-playground-value-or-na
                    (mech-state-items-ir-operation-summary-of
                     transformation-ir))))
                (html-inspector-views:html
                  (:p (html-inspector-views:esc
                       "Shared IR is unavailable."))))
            (if mech-lisp-scaffold-source
                (html-inspector-views:html
                  (:h4 "Mech-derived Lisp scaffold")
                  (snippet-source-pre
                   (or (mech-lisp-scaffold-source-source-of
                        mech-lisp-scaffold-source)
                       "")))
                (html-inspector-views:html
                  (:p (html-inspector-views:esc
                       "Mech-derived Lisp scaffold source is unavailable."))))))))

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
    (snippet-playground-log-comparison-render
     "EQUIVALENCE-START")
    (snippet-comparison-render-execution-equivalence surface)
    (snippet-playground-log-comparison-render
     "EQUIVALENCE-DONE")
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

(html-inspector-views:defview mech-execution-input-summary
    (input mech-execution-input)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of input)))
      (:table :class "inspector-table"
              (maybe-object-ref-row
               "Selected Mech"
               (mech-execution-input-selected-mech-of input))
              (maybe-object-ref-row
               "Selected code"
               (mech-execution-input-selected-code-of input))
              (snippet-playground-status-table-row
               "Function"
               (mech-execution-input-code-operation-name-of input))
              (snippet-playground-status-table-row
               "Arguments"
               (mech-execution-input-code-operation-arguments-of input))
              (snippet-playground-status-table-row
               "Output path"
               (mech-execution-input-handoff-path-of input)))
      (:h3 "Normalized state")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-execution-input-normalized-state-of input))))))

(html-inspector-views:defview mech-run-result-summary
    (result mech-run-result)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of result)))
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Engine"
               (mech-run-result-engine-of result))
              (snippet-playground-status-table-row
               "Status"
               (mech-run-result-status-of result))
              (snippet-playground-status-table-row
               "Unsupported constructs"
               (length (or (mech-run-result-unsupported-constructs-of result)
                           '()))))
      (:h3 "Return value")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-run-result-return-value-of result)))
      (:h3 "Normalized output")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-run-result-normalized-output-of result)))
      (:h3 "Diagnostics")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-run-result-diagnostics-of result))))))

(html-inspector-views:defview mech-equivalence-report-summary
    (report mech-equivalence-report)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of report)))
      (:table :class "inspector-table"
              (maybe-object-ref-row
               "Lefty run"
               (mech-equivalence-report-lefty-run-result-of report))
              (maybe-object-ref-row
               "Rita run"
               (mech-equivalence-report-rita-run-result-of report))
              (snippet-playground-status-table-row
               "equal-p"
               (if (mech-equivalence-report-equal-p report)
                   "true"
                   "false"))
              (snippet-playground-status-table-row
               "Differences"
               (length (or (mech-equivalence-report-differences-of report)
                           '()))))
      (:h3 "Comparison value")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-equivalence-report-normalized-comparison-value-of report)))
      (:h3 "Unsupported constructs")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-equivalence-report-unsupported-constructs-of report))))))

(html-inspector-views:defview mech-state-items-ir-summary
    (ir mech-state-items-ir)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of ir)))
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Function"
               (mech-state-items-ir-function-name-of ir))
              (snippet-playground-status-table-row
               "Arguments"
               (mech-state-items-ir-function-arguments-of ir))
              (snippet-playground-status-table-row
               "Input slots"
               (mech-state-items-ir-input-slots-of ir))
              (snippet-playground-status-table-row
               "Output path"
               (mech-state-items-ir-output-path-of ir))
              (snippet-playground-status-table-row
               "Helpers"
               (mech-state-items-ir-helper-functions-of ir))
              (snippet-playground-status-table-row
               "Equivalence status"
               (mech-state-items-ir-equivalence-status-of ir)))
      (:h3 "Operation summary")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-state-items-ir-operation-summary-of ir))))))

(html-inspector-views:defview mech-execution-ir-summary
    (ir mech-execution-ir)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of ir)))
      (:table :class "inspector-table"
              (maybe-object-ref-row
               "Source Mech snippet"
               (mech-execution-ir-source-mech-of ir))
              (snippet-playground-status-table-row
               "Operation count"
               (length (or (mech-execution-ir-ordered-operations-of ir) '())))
              (snippet-playground-status-table-row
               "Click groups"
               (length (or (mech-execution-ir-click-groups-of ir) '())))
              (snippet-playground-status-table-row
               "Required inputs"
               (mech-execution-ir-required-inputs-of ir))
              (snippet-playground-status-table-row
               "Code invocations"
               (mech-execution-ir-code-invocations-of ir))
              (snippet-playground-status-table-row
               "Preview output paths"
               (mech-execution-ir-preview-output-paths-of ir))
              (snippet-playground-status-table-row
               "Unsupported operations"
               (mech-execution-ir-unsupported-operations-of ir)))
      (:h3 "Ordered operations")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-execution-ir-ordered-operations-of ir))))))

(html-inspector-views:defview mech-scxml-execution-chart-summary
    (chart mech-scxml-execution-chart)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of chart)))
      (:table :class "inspector-table"
              (snippet-playground-status-table-row
               "Chart name"
               (mech-scxml-execution-chart-name-of chart))
              (snippet-playground-status-table-row
               "Initial state"
               (mech-scxml-execution-chart-initial-state-of chart))
              (snippet-playground-status-table-row
               "Terminal states"
               (mech-scxml-execution-chart-terminal-states-of chart))
              (snippet-playground-status-table-row
               "Failure states"
               (mech-scxml-execution-chart-failure-states-of chart))
              (snippet-playground-status-table-row
               "Events"
               (mech-scxml-execution-chart-events-of chart))
              (maybe-object-ref-row
               "Execution IR"
               (mech-scxml-execution-chart-execution-ir-of chart))
              (maybe-object-ref-row
               "Machine definition"
               (mech-scxml-execution-chart-machine-definition-of chart))
              (maybe-object-ref-row
               "Parsed SCXML chart"
               (mech-scxml-execution-chart-chart-of chart)))
      (:h3 "SCXML source")
      (snippet-source-pre
       (snippet-playground-value-or-na
        (mech-scxml-execution-chart-scxml-text-of chart))))))

(html-inspector-views:defview mech-lisp-scaffold-source-summary
    (source mech-lisp-scaffold-source)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:esc (summary-of source)))
      (:table :class "inspector-table"
              (maybe-object-ref-row
               "Execution input"
               (mech-lisp-scaffold-source-execution-input-of source))
              (maybe-object-ref-row
               "Transformation IR"
               (mech-lisp-scaffold-source-transformation-ir-of source))
              (maybe-object-ref-row
               "SCXML chart"
               (mech-lisp-scaffold-source-scxml-execution-chart-of source))
              (maybe-object-ref-row
               "SCXML run result"
               (mech-lisp-scaffold-source-scxml-run-result-of source))
              (maybe-object-ref-row
               "Equivalence report"
               (mech-lisp-scaffold-source-equivalence-report-of source)))
      (:h3 "Scaffold source")
      (snippet-source-pre
       (or (mech-lisp-scaffold-source-source-of source) "")))))

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
               (snippet-comparison-surface-right-code-region-of surface))
              (maybe-object-ref-row
               "Mech execution IR"
               (snippet-comparison-surface-mech-execution-ir-of surface))
              (maybe-object-ref-row
               "Mech SCXML chart"
               (snippet-comparison-surface-mech-scxml-execution-chart-of
                surface))
              (maybe-object-ref-row
               "SCXML run result"
               (snippet-comparison-surface-scxml-run-result-of surface))
              (maybe-object-ref-row
               "Mech-derived Lisp scaffold source"
               (snippet-comparison-surface-mech-lisp-scaffold-source-of
                surface)))
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
               "Mech execution IR"
               (snippet-playground-session-mech-execution-ir-of session))
              (maybe-object-ref-row
               "Transformation unit"
               (snippet-playground-session-transformation-unit-of session))
              (maybe-object-ref-row
               "Execution input"
               (snippet-playground-session-mech-execution-input-of session))
              (maybe-object-ref-row
               "Lefty run result"
               (snippet-playground-session-lefty-run-result-of session))
              (maybe-object-ref-row
               "Rita run result"
               (snippet-playground-session-rita-run-result-of session))
              (maybe-object-ref-row
               "Equivalence report"
               (snippet-playground-session-equivalence-report-of session))
              (maybe-object-ref-row
               "Shared IR"
               (snippet-playground-session-transformation-ir-of session))
              (maybe-object-ref-row
               "Mech SCXML chart"
               (snippet-playground-session-mech-scxml-execution-chart-of session))
              (maybe-object-ref-row
               "SCXML run result"
               (snippet-playground-session-scxml-run-result-of session))
              (maybe-object-ref-row
               "Mech-derived Lisp scaffold source"
               (snippet-playground-session-mech-lisp-scaffold-source-of session))
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
           (:li (html-inspector-views:esc note)))))
      (:h3 "Exploratory source parser")
      (if-let (report (snippet-playground-session-source-expansion-report-of
                       session))
        (html-inspector-views:html
          (:table :class "inspector-table"
                  (snippet-playground-status-table-row
                   "Parser engine kind"
                   (snippet-source-expansion-report-parser-engine-kind report))
                  (snippet-playground-status-table-row
                   "Parser engine identity"
                   (snippet-source-expansion-report-parser-engine-identity
                    report))
                  (snippet-playground-status-table-row
                   "Parser chart"
                   (snippet-source-expansion-report-parser-engine-chart-name
                    report))
                  (snippet-playground-status-table-row
                   "Original block count"
                   (snippet-source-expansion-report-original-block-count report))
                  (snippet-playground-status-table-row
                   "Expanded block count"
                   (snippet-source-expansion-report-expanded-block-count report))
                  (snippet-playground-status-table-row
                   "Synthetic block count"
                   (snippet-source-expansion-report-synthetic-block-count report))
                  (snippet-playground-status-table-row
                   "HTML-like block count"
                   (snippet-source-expansion-report-html-like-block-count report))
                  (snippet-playground-status-table-row
                   "Scanned block count"
                   (snippet-source-expansion-report-scanned-block-count report))
                  (snippet-playground-status-table-row
                   "Accepted candidate count"
                   (snippet-source-expansion-report-accepted-candidate-count
                    report))
                  (snippet-playground-status-table-row
                   "Rejected candidate count"
                   (snippet-source-expansion-report-rejected-candidate-count
                    report))
                  (snippet-playground-status-table-row
                   "HTML-like blocks scanned"
                   (snippet-source-expansion-report-html-like-blocks-scanned
                    report))
                  (snippet-playground-status-table-row
                   "<pre> regions found"
                   (snippet-source-expansion-report-pre-regions-found report))
                  (snippet-playground-status-table-row
                   "<pre> accepted"
                   (snippet-source-expansion-report-pre-regions-accepted report))
                  (snippet-playground-status-table-row
                   "<pre> rejected"
                   (snippet-source-expansion-report-pre-regions-rejected report))
                  (snippet-playground-status-table-row
                   "Entity decode count"
                   (snippet-source-expansion-report-decode-count report))
                  (snippet-playground-status-table-row
                   "Discrepancy count"
                   (length (snippet-source-expansion-report-discrepancies
                            report)))
                  (snippet-playground-status-table-row
                   "Incremental snapshots"
                   (length
                    (snippet-source-expansion-report-incremental-stats-snapshots
                     report)))
                  (snippet-playground-status-table-row
                   "Elapsed ms"
                   (snippet-source-expansion-report-parse-elapsed-millis report)))
          (:h4 "Policy")
          (:ul
           (loop for (key value) on
                   (snippet-source-expansion-report-policy-summary report)
                 by #'cddr
                 do (html-inspector-views:html
                      (:li (html-inspector-views:esc
                            (format nil "~A = ~S" key value))))))
          (:h4 "Candidates")
          (if (snippet-source-expansion-report-candidates report)
              (html-inspector-views:html
                (:ul
                 (dolist (entry (snippet-source-expansion-report-candidates
                                 report))
                   (html-inspector-views:html
                     (:li (html-inspector-views:esc
                           (format nil
                                   "~A (~A) parent #~A pre #~A hint=~A reason=~A"
                                   (or (getf entry :location_label)
                                       (getf entry :synthetic_id))
                                   (or (getf entry :status) :unknown)
                                   (or (getf entry :parent_block_index) "n/a")
                                   (or (getf entry :pre_ordinal) "n/a")
                                   (or (getf entry :language_hint) "n/a")
                                   (or (getf entry :reason) "n/a"))))))))
              (html-inspector-views:html
                (:p (html-inspector-views:esc
                     "No exploratory candidates were recorded for this run."))))
          (:h4 "Synthetic blocks entering code recognition")
          (let ((recognized-labels
                  (snippet-playground-recognized-synthetic-html-pre-labels
                   session)))
            (if recognized-labels
                (html-inspector-views:html
                  (:ul
                   (dolist (label recognized-labels)
                     (html-inspector-views:html
                       (:li (html-inspector-views:esc label))))))
                (html-inspector-views:html
                  (:p (html-inspector-views:esc
                       "No synthetic html-pre labels entered code recognition.")))))
          (:h4 "Discrepancies")
          (if (snippet-source-expansion-report-discrepancies report)
              (html-inspector-views:html
                (:ul
                 (dolist (discrepancy
                          (snippet-source-expansion-report-discrepancies report))
                   (html-inspector-views:html
                     (:li (html-inspector-views:esc
                           (format nil
                                   "~A/~A block=#~A id=~A line=~A offset=~A fact=~A evidence=~S"
                                   (or (snippet-source-parse-discrepancy-severity
                                        discrepancy)
                                       :unknown)
                                   (or (snippet-source-parse-discrepancy-kind
                                        discrepancy)
                                       :unknown)
                                   (or (snippet-source-parse-discrepancy-source-block-index
                                        discrepancy)
                                       "n/a")
                                   (or (snippet-source-parse-discrepancy-source-block-id
                                        discrepancy)
                                       "n/a")
                                   (or (snippet-source-parse-discrepancy-source-line-number
                                        discrepancy)
                                       "n/a")
                                   (or (snippet-source-parse-discrepancy-character-offset
                                        discrepancy)
                                       "n/a")
                                   (or (snippet-source-parse-discrepancy-fact-summary
                                        discrepancy)
                                       "n/a")
                                   (snippet-source-parse-discrepancy-evidence-value
                                    discrepancy))))))))
              (html-inspector-views:html
                (:p (html-inspector-views:esc
                     "No parser discrepancies were recorded."))))
          (:h4 "Graphviz DOT")
          (if (snippet-source-expansion-report-graphviz-dot-text report)
              (snippet-source-pre
               (snippet-source-expansion-report-graphviz-dot-text report))
              (html-inspector-views:html
                (:p (html-inspector-views:esc
                     "No Graphviz DOT artifact was recorded."))))
          (:h4 "SCXML parser trace")
          (if (snippet-source-expansion-report-parser-engine-trace report)
              (snippet-source-pre
               (format nil "~{~A~%~}"
                       (snippet-source-expansion-report-parser-engine-trace
                        report)))
              (html-inspector-views:html
                (:p (html-inspector-views:esc
                     "No SCXML parser trace was recorded."))))
          (:h4 "Warnings")
          (if (snippet-source-expansion-report-warnings report)
              (html-inspector-views:html
                (:ul
                 (dolist (warning
                          (snippet-source-expansion-report-warnings report))
                   (html-inspector-views:html
                     (:li (html-inspector-views:esc warning))))))
              (html-inspector-views:html
                (:p (html-inspector-views:esc
                     "No parser warnings recorded.")))))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No exploratory source parser report is available for this session.")))))))

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

(html-inspector-views:defview snippet-playground-session-execution-view
    (session snippet-playground-session)
  (html-inspector-views:html-view :title "Execution" :priority 12
    (html-inspector-views:html
      (if-let (surface (snippet-playground-session-comparison-surface-of session))
        (snippet-comparison-render-execution-equivalence surface)
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No execution/equivalence surface is available for this session.")))))))
