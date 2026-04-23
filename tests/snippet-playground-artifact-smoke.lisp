;;;; Focused smoke tests for snippet-playground authored/compiled artifacts
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-SNIPPET-PLAYGROUND-ARTIFACT-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun snippet-playground-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun snippet-playground-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun snippet-playground-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun snippet-playground-assert-contains (substring string message)
  (unless (search substring string :test #'char=)
    (error "~A -- missing substring: ~S" message substring)))

(defun snippet-playground-assert-not-contains (substring string message)
  (when (search substring string :test #'char=)
    (error "~A -- unexpected substring: ~S" message substring)))

(defun snippet-playground-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun snippet-playground-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun snippet-playground-smoke-region-spec (layout-spec placement)
  (find placement
        (getf layout-spec :regions)
        :key #'car
        :test #'eq))

(defun snippet-playground-smoke-region-attribute (region-spec key)
  (getf (rest region-spec) key))

(defun snippet-playground-smoke-make-blocks ()
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
                 "export default function(state) {~%  const text = \"Quick Brown Fox\";~%  state.items = text.split(\"\").map((value) => value);~%  return state.items;~%}"))))

(defun make-snippet-playground-artifact-smoke-session ()
  (let* ((blocks (snippet-playground-smoke-make-blocks))
         (source-text (hyperdoc::snippet-playground-source-text-from-blocks
                       blocks)))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text source-text
     :blocks blocks
     :origin-surface-kind "html-source"
     :provider-kind "source-v1"
     :source-label "Snippet playground artifact smoke")))

(defun run-snippet-playground-artifact-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-artifact-smoke-session))
         (authored-source
           (hyperdoc::snippet-playground-authored-source-artifact))
         (authored-artifact
           (hyperdoc::snippet-playground-session-authored-artifact-of session))
         (behavior-artifact
           (hyperdoc::snippet-playground-session-behavior-artifact-of session))
         (layout-artifact
           (hyperdoc::snippet-playground-session-layout-artifact-of session))
         (layout-spec
           (hyperdoc::snippet-playground-layout-artifact-comparison-layout-spec-of
            layout-artifact))
         (center-region
           (snippet-playground-smoke-region-spec layout-spec :center))
         (left-region
           (snippet-playground-smoke-region-spec layout-spec :left))
         (right-region
           (snippet-playground-smoke-region-spec layout-spec :right))
         (run-machine
           (hyperdoc::snippet-playground-behavior-artifact-run-machine-of
            behavior-artifact))
         (comparison-machine
           (hyperdoc::snippet-playground-behavior-artifact-comparison-machine-of
            behavior-artifact))
         (run-state-ids
           (mapcar #'hyperdoc::id-of
                   (hyperdoc::state-machine-definition-states-of run-machine)))
         (comparison-state-ids
           (mapcar #'hyperdoc::id-of
                   (hyperdoc::state-machine-definition-states-of
                    comparison-machine)))
         (run-events (hyperdoc::state-machine-definition-events-of run-machine)))
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-session
     session
     "Worked example must materialize as a ready snippet-playground session")
    (snippet-playground-assert-typep
     'hyperdoc::authored-relation-artifact-source
     authored-source
     "Snippet-playground must expose a repo-native authored source artifact")
    (snippet-playground-assert-equal
     :repo-native-lisp
     (hyperdoc::authored-relation-artifact-source-kind-of authored-source)
     "Authored source must be repo-native Lisp")
    (snippet-playground-assert-true
     (uiop:file-exists-p
      (merge-pathnames
       (hyperdoc::authored-relation-artifact-source-path-of authored-source)
       (uiop:getcwd)))
     "External authored source file must exist in the repo")
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of session)
     "Worked example must stay in the ready lifecycle state")
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-authored-artifact
     authored-artifact
     "Authored artifact must materialize as a first-class object")
    (snippet-playground-assert-equal
     (hyperdoc::authored-relation-artifact-source-artifact-id-of
      authored-source)
     (hyperdoc::id-of authored-artifact)
     "Authored artifact id must be reconstructed from the source artifact")
    (snippet-playground-assert-equal
     (hyperdoc::authored-relation-artifact-source-role-count
      authored-source)
     (length
      (hyperdoc::snippet-playground-authored-artifact-semantic-roles-of
       authored-artifact))
     "Reconstructed authored artifact must preserve source semantic roles")
    (snippet-playground-assert-equal
     (hyperdoc::authored-relation-artifact-source-relation-count
      authored-source)
     (length
      (hyperdoc::snippet-playground-authored-artifact-relations-of
       authored-artifact))
     "Reconstructed authored artifact must preserve source relations")
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-behavior-artifact
     behavior-artifact
     "Behavior artifact must materialize as a first-class object")
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-layout-artifact
     layout-artifact
     "Layout artifact must materialize as a first-class object")
    (snippet-playground-assert-true
     (eq authored-artifact
         (hyperdoc::snippet-playground-behavior-artifact-authored-artifact-of
          behavior-artifact))
     "Behavior artifact must be compiled from the authored artifact")
    (snippet-playground-assert-true
     (eq authored-artifact
         (hyperdoc::snippet-playground-layout-artifact-authored-artifact-of
          layout-artifact))
     "Layout artifact must be compiled from the authored artifact")
    (snippet-playground-assert-equal
     3
     (length (getf layout-spec :regions))
     "Compiled layout must keep one center, one left, and one right region")
    (snippet-playground-assert-true
     center-region
     "Compiled layout must keep a center region")
    (snippet-playground-assert-true
     left-region
     "Compiled layout must keep a left region")
    (snippet-playground-assert-true
     right-region
     "Compiled layout must keep a right region")
    (snippet-playground-assert-equal
     :shared-mech
     (snippet-playground-smoke-region-attribute center-region :content)
     "Shared Mech must remain bound only to the center region")
    (snippet-playground-assert-equal
     1
     (snippet-playground-smoke-region-attribute center-region :row)
     "Shared Mech must remain in the top row")
    (snippet-playground-assert-equal
     2
     (snippet-playground-smoke-region-attribute center-region :column-span)
     "Shared Mech must continue spanning the comparison split")
    (snippet-playground-assert-equal
     :javascript-code
     (snippet-playground-smoke-region-attribute left-region :content)
     "JavaScript must remain bound only to the left region")
    (snippet-playground-assert-equal
     :lisp-code
     (snippet-playground-smoke-region-attribute right-region :content)
     "Lisp must remain bound only to the right region")
    (dolist (state '(:available :pending :ready :failed))
      (snippet-playground-assert-true
       (member state run-state-ids :test #'eq)
       (format nil "Run machine must keep lifecycle state ~S" state)))
    (dolist (state '(:available :pending :ready :failed))
      (snippet-playground-assert-true
       (member state comparison-state-ids :test #'eq)
       (format nil "Comparison machine must keep lifecycle state ~S" state)))
    (dolist (event '(:snippet-click
                     :open-pending-pane
                     :pair-selected
                     :transformation-unit-built))
      (snippet-playground-assert-true
       (member event run-events :test #'eq)
       (format nil "Run machine must keep lifecycle event ~S" event)))))

(defun run-snippet-playground-artifact-rendering-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-artifact-smoke-session))
         (authored-source
           (hyperdoc::snippet-playground-authored-source-artifact))
         (authored-artifact
           (hyperdoc::snippet-playground-session-authored-artifact-of session))
         (session-views
           (snippet-playground-smoke-load-inspector-views-for-object session))
         (artifact-views
           (snippet-playground-smoke-load-inspector-views-for-object
            authored-artifact))
         (source-views
           (snippet-playground-smoke-load-inspector-views-for-object
            authored-source))
         (summary-view
           (snippet-playground-smoke-find-view-by-title session-views
                                                        "Summary"))
         (authored-view
           (snippet-playground-smoke-find-view-by-title session-views
                                                        "Authored")))
    (dolist (title '("Summary"
                     "Comparison"
                     "Authored"
                     "Behavior"
                     "Layout"))
      (snippet-playground-assert-true
       (snippet-playground-smoke-find-view-by-title session-views title)
       (format nil "Snippet-playground session must expose view ~A" title)))
    (dolist (title '("Summary"
                     "Semantic roles"
                     "Behavior relations"
                     "Layout relations"
                     "Relation graph"))
      (snippet-playground-assert-true
       (snippet-playground-smoke-find-view-by-title artifact-views title)
       (format nil "Authored artifact must expose view ~A" title)))
    (dolist (title '("Summary"
                     "Role definitions"
                     "Relation definitions"))
      (snippet-playground-assert-true
       (snippet-playground-smoke-find-view-by-title source-views title)
       (format nil "Authored source artifact must expose view ~A" title)))
    (snippet-playground-assert-contains
     "Constructed transformation unit"
     (html-inspector-views:view-html summary-view)
     "Summary must stay sparse and keep the short sentence")
    (snippet-playground-assert-contains
     "Interface:"
     (html-inspector-views:view-html summary-view)
     "Summary must keep the explicit interface line")
    (snippet-playground-assert-not-contains
     "Behavior relations"
     (html-inspector-views:view-html summary-view)
     "Summary must not grow into the authored-artifact surface")
    (snippet-playground-assert-contains
     "Selected Mech snippet"
     (html-inspector-views:view-html authored-view)
     "Authored tab must surface semantic roles")
    (snippet-playground-assert-contains
     "comparison-pane contains-center shared-mech"
     (html-inspector-views:view-html authored-view)
     "Authored tab must surface layout relations directly")
    (let ((relation-graph-view
            (snippet-playground-smoke-find-view-by-title
             artifact-views
             "Relation graph")))
      (let ((relation-graph-html
              (html-inspector-views:view-html relation-graph-view)))
      (snippet-playground-assert-contains
       "data-hyperdoc-authored-relation-graph"
       relation-graph-html
       "Authored artifact relation graph view must render with the graph marker")
      (snippet-playground-assert-contains
       "snippet-playground-behavior-artifact"
       relation-graph-html
       "Authored artifact relation graph must mention the compiled behavior artifact target")
      (snippet-playground-assert-contains
       "snippet-playground-layout-artifact"
       relation-graph-html
       "Authored artifact relation graph must mention the compiled layout artifact target")
      (snippet-playground-assert-contains
       "compiled-from"
       relation-graph-html
       "Authored artifact relation graph must expose compiled-from derivation edges")))
    (snippet-playground-assert-contains
     "data-hyperdoc-snippet-authored-artifact"
     (html-inspector-views:view-html
      (snippet-playground-smoke-find-view-by-title artifact-views "Summary"))
     "Authored artifact summary must remain directly inspectable")))

(defun run-snippet-playground-artifact-smoke-tests ()
  (run-snippet-playground-artifact-runtime-smoke-test)
  (run-snippet-playground-artifact-rendering-smoke-test)
  (format t "~&Snippet-playground artifact smoke tests passed.~%"))
