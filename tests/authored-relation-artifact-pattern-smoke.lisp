;;;; Focused smoke tests for the reusable authored relation artifact pattern
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-AUTHORED-RELATION-ARTIFACT-PATTERN-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun authored-relation-pattern-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun authored-relation-pattern-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun authored-relation-pattern-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun authored-relation-pattern-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun authored-relation-pattern-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun make-authored-relation-pattern-fixture ()
  (let* ((role
           (hyperdoc::make-authored-relation-role
            :id "role/input"
            :title "Input evidence"
            :summary "Selected evidence entering the compiler pipeline."
            :kind :evidence
            :binding :input-evidence
            :participants '(:selected-mech-snippet :selected-javascript-snippet)))
         (semantic-relation
           (hyperdoc::make-authored-relation
            :id "rel/input-supports-unit"
            :title "Input supports transformation unit"
            :layer :semantic
            :subject :input-evidence
            :predicate :supports
            :object :transformation-unit))
         (behavior-relation
           (hyperdoc::make-authored-relation
            :id "rel/available-ready"
            :title "Available transitions to ready"
            :layer :behavior
            :subject :available
            :predicate :transition-to
            :object :ready
            :attributes '(:trigger :complete)))
         (layout-relation
           (hyperdoc::make-authored-relation
            :id "rel/comparison-center"
            :title "Comparison keeps shared evidence centered"
            :layer :layout
            :subject :comparison-pane
            :predicate :contains-center
            :object :shared-evidence))
         (artifact
           (hyperdoc::make-authored-relation-artifact
            :id "artifact/example-authored-relation"
            :title "Example authored relation artifact"
            :summary
            "Reusable authored artifact describing semantic, behavior, and layout relations."
            :workflow-role "Reusable graph-authored reconstruction point."
            :compiler-pipeline
            "authored relation artifact -> compiled behavior artifact + compiled layout artifact"
            :semantic-roles (list role)
            :semantic-relations (list semantic-relation)
            :behavior-relations (list behavior-relation)
            :layout-relations (list layout-relation)
            :relations (list semantic-relation behavior-relation layout-relation)
            :compiled-targets
            '("compiled-behavior-artifact" "compiled-layout-artifact")
            :findings
            '("The authored artifact remains distinct from compiled outputs.")))
         (available-state
           (make-instance 'hyperdoc::state-machine-state
                          :id :available
                          :title "Available"))
         (ready-state
           (make-instance 'hyperdoc::state-machine-state
                          :id :ready
                          :title "Ready"))
         (transition
           (make-instance 'hyperdoc::state-machine-transition
                          :id :complete
                          :title "Complete"
                          :from-state :available
                          :to-state :ready
                          :trigger :complete))
         (machine
           (hyperdoc::make-state-machine-definition
            :id "example_behavior_machine"
            :title "Example behavior machine"
            :summary "Minimal machine compiled from the example authored artifact."
            :states (list available-state ready-state)
            :transitions (list transition)
            :initial-state :available
            :events '(:complete)))
         (behavior-artifact
           (hyperdoc::make-compiled-behavior-artifact
            :id "artifact/example-compiled-behavior"
            :title "Example compiled behavior artifact"
            :summary "Compiled behavior artifact derived from the authored relation artifact."
            :artifact-kind :compiled-behavior-artifact
            :authored-artifact artifact
            :compiler-stage :behavior-compilation
            :compiler-inputs (list artifact)
            :relations (list behavior-relation)
            :primary-machine machine
            :primary-machine-scxml
            (hyperdoc::state-machine-definition-scxml-text machine)
            :findings '("Behavior remains a compiled artifact, not the authored source.")))
         (layout-artifact
           (hyperdoc::make-compiled-layout-artifact
            :id "artifact/example-compiled-layout"
            :title "Example compiled layout artifact"
            :summary "Compiled layout artifact derived from the authored relation artifact."
            :artifact-kind :compiled-layout-artifact
            :authored-artifact artifact
            :compiler-stage :layout-compilation
            :compiler-inputs (list artifact)
            :relations (list layout-relation)
            :pane-relations nil
            :comparison-relations (list layout-relation)
            :layout-spec
            '(:surface example-comparison
              :regions ((:center :region :shared :content :shared-evidence)))
            :findings '("Layout remains separate from behavior compilation."))))
    (list :artifact artifact
          :behavior-artifact behavior-artifact
          :layout-artifact layout-artifact)))

(defun authored-relation-pattern-smoke-make-snippet-session ()
  (let ((blocks
          (list
           (list :index 1
                 :line-number 1
                 :location-label "source line 1"
                 :open-tag "<pre><code class=\"language-mech\">"
                 :source (format nil
                                 "CLICK node~%CODE transform~%PREVIEW items"))
           (list :index 2
                 :line-number 10
                 :location-label "source line 10"
                 :open-tag "<pre><code class=\"language-javascript\">"
                 :source
                 (format nil
                         "export default function(state) {~%  const text = \"Quick Brown Fox\";~%  state.items = text.split(\"\").map((value) => value);~%  return state.items;~%}")))))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text (hyperdoc::snippet-playground-source-text-from-blocks blocks)
     :blocks blocks
     :origin-surface-kind "html-source"
     :provider-kind "source-v1"
     :source-label "Authored relation artifact pattern smoke")))

(defun run-authored-relation-artifact-pattern-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (destructuring-bind (&key artifact behavior-artifact layout-artifact)
      (make-authored-relation-pattern-fixture)
    (authored-relation-pattern-assert-typep
     'hyperdoc::authored-relation-artifact
     artifact
     "Generic authored relation artifact must be instantiable")
    (authored-relation-pattern-assert-typep
     'hyperdoc::compiled-behavior-artifact
     behavior-artifact
     "Generic compiled behavior artifact must be instantiable")
    (authored-relation-pattern-assert-typep
     'hyperdoc::compiled-layout-artifact
     layout-artifact
     "Generic compiled layout artifact must be instantiable")
    (authored-relation-pattern-assert-true
     (hyperdoc::compiled-artifact-derived-p behavior-artifact artifact)
     "Compiled behavior artifact must derive from the authored artifact")
    (authored-relation-pattern-assert-true
     (hyperdoc::compiled-artifact-derived-p layout-artifact artifact)
     "Compiled layout artifact must derive from the authored artifact")
    (authored-relation-pattern-assert-equal
     (list artifact)
     (hyperdoc::compiled-artifact-compiler-inputs-of behavior-artifact)
     "Compiled behavior artifact must keep explicit compiler inputs")
    (authored-relation-pattern-assert-equal
     (list artifact)
     (hyperdoc::compiled-artifact-compiler-inputs-of layout-artifact)
     "Compiled layout artifact must keep explicit compiler inputs")))

(defun run-authored-relation-artifact-pattern-rendering-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (destructuring-bind (&key artifact behavior-artifact layout-artifact)
      (make-authored-relation-pattern-fixture)
    (let ((artifact-views
            (authored-relation-pattern-load-inspector-views-for-object artifact))
          (behavior-views
            (authored-relation-pattern-load-inspector-views-for-object
             behavior-artifact))
          (layout-views
            (authored-relation-pattern-load-inspector-views-for-object
             layout-artifact)))
      (dolist (title '("Summary"
                       "Semantic roles"
                       "Behavior relations"
                       "Layout relations"))
        (authored-relation-pattern-assert-true
         (authored-relation-pattern-find-view-by-title artifact-views title)
         (format nil "Generic authored artifact must expose view ~A" title)))
      (dolist (title '("Summary" "Relations" "Behavior machine" "SCXML"))
        (authored-relation-pattern-assert-true
         (authored-relation-pattern-find-view-by-title behavior-views title)
         (format nil "Generic behavior artifact must expose view ~A" title)))
      (dolist (title '("Summary" "Relations" "Layout"))
        (authored-relation-pattern-assert-true
         (authored-relation-pattern-find-view-by-title layout-views title)
         (format nil "Generic layout artifact must expose view ~A" title))))))

(defun run-authored-relation-artifact-pattern-snippet-integration-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (authored-relation-pattern-smoke-make-snippet-session))
         (authored-artifact
           (hyperdoc::snippet-playground-session-authored-artifact-of session))
         (behavior-artifact
           (hyperdoc::snippet-playground-session-behavior-artifact-of session))
         (layout-artifact
           (hyperdoc::snippet-playground-session-layout-artifact-of session)))
    (authored-relation-pattern-assert-typep
     'hyperdoc::authored-relation-artifact
     authored-artifact
     "Snippet-playground authored artifact must sit on the generic artifact pattern")
    (authored-relation-pattern-assert-typep
     'hyperdoc::compiled-behavior-artifact
     behavior-artifact
     "Snippet-playground behavior artifact must sit on the generic compiled behavior pattern")
    (authored-relation-pattern-assert-typep
     'hyperdoc::compiled-layout-artifact
     layout-artifact
     "Snippet-playground layout artifact must sit on the generic compiled layout pattern")
    (authored-relation-pattern-assert-true
     (hyperdoc::compiled-artifact-derived-p behavior-artifact authored-artifact)
     "Snippet-playground behavior artifact must derive from the generic authored artifact path")
    (authored-relation-pattern-assert-true
     (hyperdoc::compiled-artifact-derived-p layout-artifact authored-artifact)
     "Snippet-playground layout artifact must derive from the generic authored artifact path")
    (authored-relation-pattern-assert-equal
     (list authored-artifact)
     (hyperdoc::compiled-artifact-compiler-inputs-of behavior-artifact)
     "Snippet-playground behavior artifact must retain explicit compiler inputs")
    (authored-relation-pattern-assert-equal
     (list authored-artifact)
     (hyperdoc::compiled-artifact-compiler-inputs-of layout-artifact)
     "Snippet-playground layout artifact must retain explicit compiler inputs")))

(defun run-authored-relation-artifact-pattern-smoke-tests ()
  (run-authored-relation-artifact-pattern-runtime-smoke-test)
  (run-authored-relation-artifact-pattern-rendering-smoke-test)
  (run-authored-relation-artifact-pattern-snippet-integration-smoke-test)
  (format t "~&Authored relation artifact pattern smoke tests passed.~%"))
