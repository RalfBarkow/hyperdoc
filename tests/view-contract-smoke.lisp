;;;; Smoke tests for first-class inspector view contracts
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-VIEW-CONTRACT-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun view-contract-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun view-contract-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun view-contract-assert-external-symbol (name)
  (multiple-value-bind (symbol status)
      (find-symbol name :html-inspector-views)
    (declare (ignore symbol))
    (view-contract-assert-true
     (eq status :external)
     (format nil "html-inspector-views must export ~A" name))))

(defun view-contract-test-view ()
  (html-inspector-views:html-view
      :title "Ordinary Smoke View"
      :priority 42
    (html-inspector-views:html
      (:p "ordinary view body"))))

(defun view-contract-view-titles (object)
  (mapcar #'html-inspector-views:view-title
          (html-inspector-views:all-views object)))

(defun view-contract-source-section (source start-marker end-marker)
  (let* ((start (search start-marker source :test #'char=))
         (end (and start
                   (search end-marker source
                           :test #'char=
                           :start2 (+ start (length start-marker))))))
    (and start
         (subseq source start (or end (length source))))))

(defun view-contract-title-bar-scxml-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/inspector-title-bar-ui.scxml"))

(defun view-contract-scxml-state-ids (chart)
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun view-contract-scxml-find-state (chart state-id)
  (find state-id
        (hyperdoc/scxml:scxml-chart-states-of chart)
        :key #'hyperdoc/scxml:scxml-state-id-of
        :test #'string=))

(defun view-contract-scxml-transition-exists-p (chart source event target)
  (let ((state (view-contract-scxml-find-state chart source)))
    (and state
         (find-if
          (lambda (transition)
            (and (equal event
                        (hyperdoc/scxml:scxml-transition-event-of transition))
                 (equal target
                        (hyperdoc/scxml:scxml-transition-target-of transition))))
          (hyperdoc/scxml:scxml-state-transitions-of state)))))

(defun view-contract-scxml-error-findings (findings)
  (remove-if-not
   (lambda (finding)
     (eq :error
         (hyperdoc/scxml:scxml-validation-finding-severity-of finding)))
   findings))

(defun view-contract-assert-view-titles (object titles)
  (let ((actual (view-contract-view-titles object)))
    (dolist (title titles)
      (view-contract-assert-true
       (member title actual :test #'string=)
       (format nil "Missing view-contract inspector view ~S" title)))))

(defun run-view-contract-package-protocol-smoke-test ()
  (dolist (name '("INSPECTOR-VIEW-SPECIFICATION"
                  "VIEW-ID-OF"
                  "VIEW-TITLE-OF"
                  "SUBJECT-TYPE-OF"
                  "READER-QUESTION-OF"
                  "CONTENT-MODEL-OF"
                  "BOX-CONTRACT-OF"
                  "PRIORITY-POLICY-OF"
                  "ACTIONS-OF"
                  "EVIDENCE-OF"
                  "FAILURE-MODES-OF"
                  "VIEW-SPECIFICATION"
                  "VIEW-READER-QUESTION"
                  "VIEW-CONTENT-MODEL"
                  "VIEW-BOX-CONTRACT"
                  "VIEW-PRIORITY-POLICY"
                  "VIEW-FAILURE-MODES"))
    (view-contract-assert-external-symbol name))
  (let* ((view (view-contract-test-view))
         (subject '(:ordinary-subject))
         (spec (html-inspector-views:view-specification view subject)))
    (view-contract-assert-true
     (typep spec 'html-inspector-views:inspector-view-specification)
     "Ordinary views must produce an inspector-view-specification.")
    (view-contract-assert-equal
     "Ordinary Smoke View"
     (html-inspector-views:view-title-of spec)
     "Default view contract must preserve the view title.")
    (view-contract-assert-true
     (member '(:layout-snapshot :missing-evidence)
             (html-inspector-views:evidence-of spec)
             :test #'equal)
     "Default view contract evidence must include missing layout snapshot evidence.")
    (view-contract-assert-view-titles
     spec
     '("Summary"
       "Content model"
       "Box contract"
       "Priority policy"
       "Actions"
       "Evidence"
       "Failure modes"))
    (let* ((evidence-view
             (find "Evidence"
                   (html-inspector-views:all-views spec)
                   :key #'html-inspector-views:view-title
                   :test #'string=))
           (evidence-html
             (and evidence-view
                  (html-inspector-views:view-html evidence-view))))
      (view-contract-assert-true
       (and evidence-html
            (search "Missing evidence" evidence-html :test #'char=)
            (search "rendered layout snapshot" evidence-html :test #'char=))
       "Evidence view must explain missing rendered layout snapshot evidence."))))

(defun run-view-contract-hyperdoc-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  (let* ((view (view-contract-test-view))
         (subject '(:runtime-subject))
         (spec
           (clog-moldable-inspector::view-contract-for-view-and-subject
            view
            subject))
         (source
           (uiop:read-file-string
            (asdf:system-relative-pathname
             :hyperdoc
             "hyperbook-server/inspector-dom-association.lisp")))
         (create-tabs-source
           (view-contract-source-section
            source
            "(defun create-tabs"
            ";; Override only the Eval path"))
         (title-bar-source
            (view-contract-source-section
             source
             "(defun create-title-bar"
             "(hv:defview 👀title-bar"))
         (title-render-source
           (view-contract-source-section
            source
            "(defun inspector-title-bar-view"
            "(defun create-view-contract-title-bar-button"))
         (title-class-dom-source
           (and title-render-source
                (view-contract-source-section
                 title-render-source
                 ":class \"inspector-title-bar-class\""
                 "(:button :id (hv:inspect-id object)")))
         (title-object-dom-source
           (and title-render-source
                (view-contract-source-section
                 title-render-source
                 ":class \"inspector-title-bar-object\""
                 "(defun create-view-contract-title-bar-button")))
         (title-bar-spec-source
           (view-contract-source-section
            source
            "(hv:defview 👀title-bar"
            "(defun dom-association-class-present-p")))
    (view-contract-assert-true
     (typep spec 'html-inspector-views:inspector-view-specification)
     "HyperDoc runtime helper must return a view contract object.")
    (view-contract-assert-equal
     "Ordinary Smoke View"
     (html-inspector-views:view-title-of spec)
     "HyperDoc runtime helper must inspect the active view, not only the subject.")
    (view-contract-assert-equal
     (type-of subject)
     (html-inspector-views:subject-type-of spec)
     "HyperDoc runtime helper must preserve the pane subject type.")
    (view-contract-assert-true
     (member '(:layout-snapshot :missing-evidence)
             (html-inspector-views:evidence-of spec)
             :test #'equal)
     "HyperDoc runtime evidence must report missing layout snapshot explicitly.")
    (view-contract-assert-true
     (search "Inspect view contract" source :test #'char=)
     "Pane chrome source must expose the Inspect view contract label.")
    (view-contract-assert-true
     (search "view-contract-for-pane pane" source :test #'char=)
     "Pane chrome action must build a contract from the active view and pane subject.")
    (view-contract-assert-true
     (and create-tabs-source
          (not (search "hyperdoc-view-contract-action"
                       create-tabs-source
                       :test #'char=)))
     "Inspect view contract must not be created in the tab row.")
    (view-contract-assert-true
     (and title-bar-source
          (search "inspector-title-bar-action-buttons"
                  title-bar-source
                  :test #'char=)
          (search "create-view-contract-title-bar-button pane action"
                  title-bar-source
                  :test #'char=))
     "Inspect view contract must be created inside the title-bar action buttons.")
    (view-contract-assert-true
     (and (search "<svg class=\\\"hyperdoc-view-contract-icon\\\""
                  source
                  :test #'char=)
          (search "(clog:attribute button \"title\") +view-contract-action-label+"
                  source
                  :test #'char=)
          (search "(clog:attribute button \"aria-label\") +view-contract-action-label+"
                  source
                  :test #'char=))
     "Inspect view contract must be an SVG icon button with title and aria-label.")
    (view-contract-assert-true
     (and (search ":class \"inspector-title-bar-class\""
                  source
                  :test #'char=)
          (search ":data-title-bar-presentation \"class/type\""
                  source
                  :test #'char=)
          (search ":data-scxml-event \"class.invoke\""
                  source
                  :test #'char=)
          (search "(:i (hv:esc (inspector-title-bar-class-label object)))"
                  source
                  :test #'char=)
          (search ":class \"inspector-title-bar-object\""
                  source
                  :test #'char=)
          (search ":data-title-bar-presentation \"object/instance\""
                  source
                  :test #'char=)
          (search ":data-scxml-event \"object.invoke\""
                  source
                  :test #'char=))
     "Title bar must expose class/type and object/instance presentation buttons.")
    (view-contract-assert-true
     (and title-class-dom-source
          (search ":data-title-bar-presentation \"class/type\""
                  title-class-dom-source
                  :test #'char=)
          (search ":data-scxml-event \"class.invoke\""
                  title-class-dom-source
                  :test #'char=))
     "Title bar class presentation must be a visible class/type invocation button.")
    (view-contract-assert-true
     (and title-object-dom-source
          (search ":data-title-bar-presentation \"object/instance\""
                  title-object-dom-source
                  :test #'char=)
          (search ":data-scxml-event \"object.invoke\""
                  title-object-dom-source
                  :test #'char=)
          (search ":tabindex 0" title-object-dom-source :test #'char=))
     "Title bar object presentation must be a visible object/instance invocation button.")
    (view-contract-assert-true
     (and title-bar-spec-source
          (search "inspector-title-bar-box-contract"
                  title-bar-spec-source
                  :test #'char=)
          (search ":scope :pane-active-view"
                  source
                  :test #'char=)
          (search ":representation :svg-icon"
                  source
                  :test #'char=)
          (search ":visibility :default-visible"
                  source
                  :test #'char=)
          (search ":inspect-class/type-presentation"
                  source
                  :test #'char=)
          (search ":inspect-object/instance-presentation"
                  source
                  :test #'char=)
          (search "view-contract.invoke"
                  source
                  :test #'char=)
          (search "inspector-title-bar-ui.scxml"
                  source
                  :test #'char=)
          (search "inspector-title-bar-ui-state-contracts"
                  title-bar-spec-source
                  :test #'char=)
          (search "inspector-title-bar-ui-default-trace"
                  title-bar-spec-source
                  :test #'char=)
          (search "inspector-title-bar-ui-class-invoke-trace"
                  title-bar-spec-source
                  :test #'char=)
          (search "inspector-title-bar-ui-object-invoke-trace"
                  title-bar-spec-source
                  :test #'char=))
     "Title-bar specification view must document presentation contracts, pane-scoped action, SVG icon, SCXML state machine, and traces.")
    (view-contract-assert-true
     (not (member "View Contract"
                  (view-contract-view-titles subject)
                  :test #'string=))
     "View Contract must not be a permanent tab on ordinary domain objects.")))

(defun run-view-contract-title-bar-scxml-smoke-test ()
  (asdf:load-system :hyperdoc/scxml)
  (let* ((chart (hyperdoc/scxml:parse-scxml-file
                 (view-contract-title-bar-scxml-pathname)))
         (findings (hyperdoc/scxml:validate-scxml-chart chart))
         (error-findings (view-contract-scxml-error-findings findings))
         (state-ids (view-contract-scxml-state-ids chart)))
    (view-contract-assert-equal
     "inspector-title-bar"
     (hyperdoc/scxml:scxml-chart-name-of chart)
     "Title-bar UI SCXML must have the expected chart name.")
    (view-contract-assert-equal
     "constructing"
     (hyperdoc/scxml:scxml-chart-initial-state-of chart)
     "Title-bar UI SCXML must start while the pane is constructing.")
    (view-contract-assert-true
     (null error-findings)
     (format nil "Title-bar UI SCXML must validate without errors: ~S"
             (mapcar #'hyperdoc/scxml:scxml-validation-finding-code-of
                     error-findings)))
    (dolist (state '("constructing"
                     "ready"
                     "class-preview"
                     "class-focused"
                     "class-menu-open"
                     "class-invoking"
                     "object-preview"
                     "object-focused"
                     "object-menu-open"
                     "object-invoking"
                     "view-contract-invoking"))
      (view-contract-assert-true
       (member state state-ids :test #'string=)
       (format nil "Title-bar UI SCXML must include state ~A" state)))
    (dolist (transition
              '(("constructing" "titlebar.rendered" "ready")
                ("ready" "class.hover" "class-preview")
                ("ready" "class.focus" "class-focused")
                ("ready" "class.menu" "class-menu-open")
                ("ready" "class.invoke" "class-invoking")
                ("class-preview" "class.pointer.leave" "ready")
                ("class-preview" "class.focus" "class-focused")
                ("class-focused" "class.blur" "ready")
                ("class-focused" "class.menu" "class-menu-open")
                ("class-focused" "class.invoke" "class-invoking")
                ("class-menu-open" "class.menu.dismiss" "ready")
                ("class-menu-open" "class.command.inspect" "class-invoking")
                ("class-invoking" "class.invoked" "ready")
                ("ready" "object.hover" "object-preview")
                ("ready" "object.focus" "object-focused")
                ("ready" "object.menu" "object-menu-open")
                ("ready" "object.invoke" "object-invoking")
                ("object-preview" "object.pointer.leave" "ready")
                ("object-preview" "object.focus" "object-focused")
                ("object-focused" "object.blur" "ready")
                ("object-focused" "object.menu" "object-menu-open")
                ("object-focused" "object.invoke" "object-invoking")
                ("object-menu-open" "object.menu.dismiss" "ready")
                ("object-menu-open" "object.command.inspect" "object-invoking")
                ("object-invoking" "object.invoked" "ready")
                ("ready" "view-contract.invoke" "view-contract-invoking")
                ("view-contract-invoking" "view-contract.invoked" "ready")))
      (destructuring-bind (source event target) transition
        (view-contract-assert-true
         (view-contract-scxml-transition-exists-p chart source event target)
         (format nil "Title-bar UI SCXML must include transition ~A --~A--> ~A"
                 source event target)))))
  t)

(defun run-secondary-inspector-view-classification-smoke-test ()
  (let ((expected
          '("Topicmap"
            "Links"
            "Parse tree"
            "Connect source"
            "Source surface"
            "Backlinks"
            "Plain source"
            "Source strategies"
            "Source swap operations"
            "Lookup issues"
            "URL"
            "Slots"
            "Print"
            "Operations")))
    (view-contract-assert-equal
     expected
     clog-moldable-inspector::*secondary-inspector-view-titles*
     "Secondary inspector view titles must match the production contract exactly")
    (dolist (title expected)
      (view-contract-assert-true
       (not (null
             (clog-moldable-inspector::secondary-inspector-view-p title)))
       (format nil "Production contract must classify ~S as secondary" title)))
    (dolist (title '("Content" "Source" "links" "TOPICMAP"
                     "Unrecognized view"))
      (view-contract-assert-true
       (null (clog-moldable-inspector::secondary-inspector-view-p title))
       (format nil "Production contract must not classify ~S as secondary"
               title))))
  t)

(defun run-view-contract-smoke-tests ()
  (run-view-contract-package-protocol-smoke-test)
  (run-view-contract-hyperdoc-runtime-smoke-test)
  (run-secondary-inspector-view-classification-smoke-test)
  (run-view-contract-title-bar-scxml-smoke-test)
  (format t "~&View contract smoke tests passed.~%")
  t)
