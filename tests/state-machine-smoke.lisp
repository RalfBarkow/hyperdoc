;;;; Focused smoke tests for generic state-machine objects and docs
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-STATE-MACHINE-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun state-machine-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun state-machine-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun state-machine-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun state-machine-assert-contains (substring string message)
  (unless (search substring string :test #'char=)
    (error "~A -- missing substring: ~S" message substring)))

(defun state-machine-smoke-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-state-machine-page (namestring)
  (uiop:read-file-string
   (state-machine-smoke-relative-path namestring)))

(defun normalize-state-machine-smoke-whitespace (string)
  (with-output-to-string (stream)
    (loop with pending-space = nil
          with wrote-char = nil
          for char across string
          do (if (find char '(#\Space #\Tab #\Newline #\Return))
                 (setf pending-space t)
                 (progn
                   (when pending-space
                     (when wrote-char
                       (write-char #\Space stream))
                     (setf pending-space nil))
                   (write-char char stream)
                   (setf wrote-char t))))))

(defun assert-state-machine-page-contains-all (page-source page-label needles)
  (let ((normalized
          (normalize-state-machine-smoke-whitespace page-source)))
    (dolist (needle needles)
      (state-machine-assert-true
       (search (normalize-state-machine-smoke-whitespace needle)
               normalized
               :test #'char=)
       (format nil "~A must contain ~S" page-label needle)))))

(defun state-machine-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun state-machine-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun run-state-machine-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((machine (hyperdoc::make-example-state-machine-definition))
         (run (hyperdoc::make-example-state-machine-run))
         (auth (hyperdoc::dmx-auth-crosswalk-username-password-example))
         (machine-views
           (state-machine-smoke-load-inspector-views-for-object machine))
         (run-views
           (state-machine-smoke-load-inspector-views-for-object run))
         (auth-views
           (state-machine-smoke-load-inspector-views-for-object auth)))
    (state-machine-assert-typep
     'hyperdoc::state-machine-definition
     machine
     "Example machine must materialize as a state-machine-definition")
    (state-machine-assert-typep
     'hyperdoc::state-machine-run
     run
     "Example run must materialize as a state-machine-run")
    (state-machine-assert-typep
     'hyperdoc::state-machine-run
     auth
     "DMX auth example must now also be a state-machine-run")
    (state-machine-assert-typep
     'hyperdoc::dmx-auth-path-example
     auth
     "DMX auth example must keep its specialized teaching class")
    (dolist (title '("Overview"
                     "States"
                     "Transitions"
                     "State machine"
                     "Invariants / constraints"
                     "Source evidence / code path"
                     "Directed graph"
                     "Graphviz"
                     "Transition matrix"))
      (state-machine-assert-true
       (state-machine-smoke-find-view-by-title machine-views title)
       (format nil "Machine definition must expose view ~A" title)))
    (dolist (title '("Overview"
                     "Trace"
                     "Timeline"
                     "Evidence"
                     "Failure analysis"
                     "Source evidence / code path"))
      (state-machine-assert-true
       (state-machine-smoke-find-view-by-title run-views title)
       (format nil "Machine run must expose view ~A" title)))
    (dolist (title '("Trace"
                     "Timeline"
                     "Evidence"
                     "Failure analysis"))
      (state-machine-assert-true
       (state-machine-smoke-find-view-by-title auth-views title)
       (format nil "DMX auth example must expose generic run view ~A" title)))
    (assert-state-machine-page-contains-all
     (html-inspector-views:view-html
      (state-machine-smoke-find-view-by-title machine-views "Overview"))
     "State machine example Overview"
     '("Example evidence-bearing state machine"
       "State count"
       "Transition count"))
    (assert-state-machine-page-contains-all
     (html-inspector-views:view-html
      (state-machine-smoke-find-view-by-title run-views "Trace"))
     "State machine example Trace"
     '("captured"
       "validated"
       "committed"))
    (assert-state-machine-page-contains-all
     (html-inspector-views:view-html
      (state-machine-smoke-find-view-by-title auth-views "Trace"))
     "DMX auth example Trace"
     '("input-captured"
       "guarded-request-shaped"))
    (assert-state-machine-page-contains-all
     (html-inspector-views:view-html
      (state-machine-smoke-find-view-by-title auth-views "Evidence"))
     "DMX auth example Evidence"
     '("JSESSIONID"
       "Later guarded request shape"))))

(defun run-state-machine-graphviz-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((machine (hyperdoc::make-example-state-machine-definition))
         (dot (hyperdoc::state-machine-definition-dot-text machine))
         (views (state-machine-smoke-load-inspector-views-for-object machine))
         (graphviz-view
           (state-machine-smoke-find-view-by-title views "Graphviz"))
         (directed-graph-view
           (state-machine-smoke-find-view-by-title views "Directed graph")))
    (state-machine-assert-contains "digraph \"state-machine-definition/example\""
                                   dot
                                   "State-machine DOT export must use the machine id")
    (state-machine-assert-contains "__start__ -> \"captured\""
                                   dot
                                   "State-machine DOT export must include the initial-state arrow")
    (state-machine-assert-contains "Captured\\\\n(Initial)"
                                   dot
                                   "State-machine DOT export must label the initial state")
    (state-machine-assert-contains "validate / support-available"
                                   dot
                                   "State-machine DOT export must label transition event/guard pairs")
    (state-machine-assert-true graphviz-view
                               "Machine definition must expose a Graphviz view")
    (state-machine-assert-true directed-graph-view
                               "Machine definition must keep the Directed graph view")
    (assert-state-machine-page-contains-all
     (html-inspector-views:view-html graphviz-view)
     "State-machine Graphviz view"
     '("Browser-rendered Graphviz view"
       "data-inspector-graphviz"
       "Directed graph remains the teaching-oriented text view"
       "Derived DOT source"))))

(defun run-state-machine-documentation-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (spec '((hyperdoc::path-topic . "Path")
                  (hyperdoc::state-machine-topic . "State machine")
                  (hyperdoc::state-topic . "State")
                  (hyperdoc::transition-topic . "Transition")
                  (hyperdoc::guard-topic . "Guard")
                  (hyperdoc::event-topic . "Event")
                  (hyperdoc::terminal-state-topic . "Terminal state")
                  (hyperdoc::failure-state-topic . "Failure state")
                  (hyperdoc::state-machine-run-topic . "State-machine run")
                  (hyperdoc::state-machine-trace-topic . "State-machine trace")
                  (hyperdoc::state-machine-visualization-topic
                   . "State-machine visualization")
                  (hyperdoc::operational-definition-state-machine-state-transition-guard-run-trace-topic
                   . "Operational definition: state machine, state, transition, guard, run trace")))
    (let* ((symbol (car spec))
           (title (cdr spec))
           (topic (funcall symbol)))
      (state-machine-assert-true
       (fboundp symbol)
       (format nil "Missing topic function ~A" symbol))
      (state-machine-assert-equal title
                                  (hyperbook:title-of topic)
                                  (format nil "Topic ~A title" symbol))
      (state-machine-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Missing Topics HyperBook page ~A" title))))
  (dolist (page-title '("Path"
                        "State machine"
                        "State"
                        "Transition"
                        "Guard"
                        "Event"
                        "Terminal state"
                        "Failure state"
                        "State-machine run"
                        "State-machine trace"
                        "State-machine visualization"
                        "Operational definition: state machine, state, transition, guard, run trace"))
    (state-machine-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* page-title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" page-title)))
  (assert-state-machine-page-contains-all
   (read-state-machine-page "hyperdoc/State machine.html")
   "State machine"
   '("HyperDoc Evaluation and Inspection Model"
     "A framework for maintaining the coherence of a running Lisp"
     "McDermott Running Image Coherence Crosswalk"
     "(make-example-state-machine-definition)"
     "view=\"Graphviz\""
     "(make-example-state-machine-run)"
     "(make-dmx-auth-state-machine-definition)"))
  (assert-state-machine-page-contains-all
   (read-state-machine-page "hyperdoc/State-machine visualization.html")
   "State-machine visualization"
   '("view=\"Graphviz\""
     "Directed graph"
     "Transition matrix"
     "machine definition as the canonical source"))
  (assert-state-machine-page-contains-all
   (read-state-machine-page
    "hyperdoc/Operational definition: state machine, state, transition, guard, run trace.html")
   "Operational definition: state machine, state, transition, guard, run trace"
   '("A state machine is a bounded transition object"
     "a reusable definition object"
     "a concrete run object"
     "Inspectable authentication-path traces for repair console"))
  (assert-state-machine-page-contains-all
   (read-state-machine-page "hyperdoc/HyperDoc three-mode DMX auth crosswalk.html")
   "HyperDoc three-mode DMX auth crosswalk"
   '("This crosswalk is now one worked example of the generic"
     "State machine"
     "Path"))
  (assert-state-machine-page-contains-all
   (read-state-machine-page
    "hyperdoc/Inspectable authentication-path traces for repair console.html")
   "Inspectable authentication-path traces for repair console"
   '("one worked example of the generic"
     "State machine"
     "Path")))

(defun run-state-machine-smoke-tests ()
  (run-state-machine-runtime-smoke-test)
  (run-state-machine-graphviz-smoke-test)
  (run-state-machine-documentation-smoke-test)
  (format t "~&State-machine smoke tests passed.~%")
  t)
