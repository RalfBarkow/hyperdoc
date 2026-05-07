;;;; Focused smoke tests for generic surface objects and docs
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-SURFACE-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun surface-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun surface-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun surface-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun surface-smoke-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-surface-page (namestring)
  (uiop:read-file-string
   (surface-smoke-relative-path namestring)))

(defun normalize-surface-smoke-whitespace (string)
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

(defun assert-surface-page-contains-all (page-source page-label needles)
  (let ((normalized
         (normalize-surface-smoke-whitespace page-source)))
    (dolist (needle needles)
      (surface-assert-true
       (search (normalize-surface-smoke-whitespace needle)
               normalized
               :test #'char=)
       (format nil "~A must contain ~S" page-label needle)))))

(defun surface-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun surface-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun run-surface-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((definition (hyperdoc::make-example-surface-definition))
         (instance (hyperdoc::make-example-surface-instance))
         (diagnostic-definition
          (hyperdoc::make-dmx-workspace-repair-diagnostic-surface-definition))
         (diagnostic-instance
          (hyperdoc::make-dmx-workspace-repair-diagnostic-surface-instance))
         (mutation-definition
          (hyperdoc::make-dmx-repair-console-mutation-surface-definition))
         (mutation-instance
          (hyperdoc::make-dmx-repair-console-mutation-surface-instance))
         (failure-definition
          (hyperdoc::make-dmx-workspace-journal-observed-failure-surface-definition))
         (failure-instance
          (hyperdoc::make-dmx-workspace-journal-observed-failure-surface-instance))
         (definition-views
          (surface-smoke-load-inspector-views-for-object definition))
         (instance-views
          (surface-smoke-load-inspector-views-for-object instance))
         (diagnostic-definition-views
          (surface-smoke-load-inspector-views-for-object diagnostic-definition))
         (diagnostic-instance-views
          (surface-smoke-load-inspector-views-for-object diagnostic-instance))
         (mutation-instance-views
          (surface-smoke-load-inspector-views-for-object mutation-instance))
         (failure-instance-views
          (surface-smoke-load-inspector-views-for-object failure-instance)))
    (surface-assert-typep
     'hyperdoc::surface-definition
     definition
     "Example surface definition must materialize as a surface-definition")
    (surface-assert-typep
     'hyperdoc::surface-instance
     instance
     "Example surface instance must materialize as a surface-instance")
    (surface-assert-typep
     'hyperdoc::surface-definition
     diagnostic-definition
     "DMX diagnostic example must materialize as a surface-definition")
    (surface-assert-typep
     'hyperdoc::surface-instance
     diagnostic-instance
     "DMX diagnostic example must materialize as a surface-instance")
    (surface-assert-typep
     'hyperdoc::surface-definition
     mutation-definition
     "DMX mutation example must materialize as a surface-definition")
    (surface-assert-typep
     'hyperdoc::surface-instance
     mutation-instance
     "DMX mutation example must materialize as a surface-instance")
    (surface-assert-typep
     'hyperdoc::surface-definition
     failure-definition
     "DMX failure example must materialize as a surface-definition")
    (surface-assert-typep
     'hyperdoc::surface-instance
     failure-instance
     "DMX failure example must materialize as a surface-instance")
    (dolist (title '("Overview"
                     "Classification"
                     "Capabilities"
                     "Inputs and outputs"
                     "Boundary rules"
                     "Related surfaces"
                     "Source evidence / code path"))
      (surface-assert-true
       (surface-smoke-find-view-by-title definition-views title)
       (format nil "Surface definition must expose view ~A" title)))
    (dolist (title '("Overview"
                     "Boundary state"
                     "Active capabilities"
                     "Evidence"
                     "Failure surfaces"
                     "Adjacent surfaces"
                     "Source evidence / code path"))
      (surface-assert-true
       (surface-smoke-find-view-by-title instance-views title)
       (format nil "Surface instance must expose view ~A" title)))
    (assert-surface-page-contains-all
     (html-inspector-views:view-html
      (surface-smoke-find-view-by-title diagnostic-definition-views
                                        "Classification"))
     "DMX diagnostic surface definition"
     '("diagnostic"
       "read-only"))
    (assert-surface-page-contains-all
     (html-inspector-views:view-html
      (surface-smoke-find-view-by-title diagnostic-instance-views
                                        "Boundary state"))
     "DMX diagnostic surface instance"
     '("read-only"
       "Diagnosis can inspect backlog"))
    (assert-surface-page-contains-all
     (html-inspector-views:view-html
      (surface-smoke-find-view-by-title mutation-instance-views
                                        "Active capabilities"))
     "DMX mutation surface instance"
     '("Repair selected topic"
       "Repair backlog"
       "Repair console tab"))
    (assert-surface-page-contains-all
     (html-inspector-views:view-html
      (surface-smoke-find-view-by-title failure-instance-views
                                        "Evidence"))
     "DMX failure surface instance"
     '("prepare-transition"
       "PUT /core/topic/927568"
       "HTTP 401"))
    (assert-surface-page-contains-all
     (html-inspector-views:view-html
      (surface-smoke-find-view-by-title failure-instance-views
                                        "Failure surfaces"))
     "DMX failure surface instance"
     '("Auth-blocked journal preflight"
       "Stale companion topic state"))))

(defun run-surface-documentation-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (spec '((hyperdoc::surface-topic . "Surface")
                  (hyperdoc::diagnostic-surface-topic . "Diagnostic surface")
                  (hyperdoc::mutation-surface-topic . "Mutation surface")
                  (hyperdoc::failure-surface-topic . "Failure surface")
                  (hyperdoc::surface-boundary-topic . "Surface boundary")))
    (let* ((symbol (car spec))
           (title (cdr spec))
           (topic (funcall symbol)))
      (surface-assert-true
       (fboundp symbol)
       (format nil "Missing topic function ~A" symbol))
      (surface-assert-equal title
                            (hyperbook:title-of topic)
                            (format nil "Topic ~A title" symbol))
      (surface-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Missing Topics HyperBook page ~A" title))))
  (dolist (page-title '("Surface"
                        "Diagnostic surface"
                        "Mutation surface"
                        "Failure surface"
                        "Surface boundary"
                        "Operational definition: surface, diagnostic surface, mutation surface, failure surface"))
    (surface-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* page-title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" page-title)))
  (assert-surface-page-contains-all
   (read-surface-page "hyperdoc/Surface.html")
   "Surface"
   '("Documentation Surfaces in HyperDoc"
     "Communication Surfaces Policy"
     "Surface and Artifact Answers"
     "Surface Answer"
     "HyperDoc Evaluation and Inspection Model"
     "Using authenticated workspace assignment repair console"
     "DMX workspace journal model"
     "DMX workspace journal reconcile call graph"
     "Diagnosing DMX workspace repair triage"
     "(make-dmx-repair-console-mutation-surface-instance)"
     "(make-dmx-workspace-repair-diagnostic-surface-instance)"
     "(make-dmx-workspace-journal-observed-failure-surface-instance)"))
  (assert-surface-page-contains-all
   (read-surface-page
    "hyperdoc/Operational definition: surface, diagnostic surface, mutation surface, failure surface.html")
   "Operational definition: surface, diagnostic surface, mutation surface, failure surface"
   '("A surface is a bounded operational interface"
     "its scope"
     "its permitted operations"
     "a reusable definition object"
     "a concrete surface instance"
     "Surface Answer"
     "DMX workspace journal reconcile call graph"))
  (assert-surface-page-contains-all
   (read-surface-page
    "hyperdoc/Using authenticated workspace assignment repair console.html")
   "Using authenticated workspace assignment repair console"
   '("Mutation surface"
     "Failure surface"
     "(make-dmx-repair-console-mutation-surface-instance)"))
  (assert-surface-page-contains-all
   (read-surface-page
    "hyperdoc/Diagnosing DMX workspace repair triage.html")
   "Diagnosing DMX workspace repair triage"
   '("Diagnostic surface"
     "Failure surface"
     "(make-dmx-workspace-repair-diagnostic-surface-instance)"
     "(make-dmx-workspace-journal-observed-failure-surface-instance)"))
  (assert-surface-page-contains-all
   (read-surface-page "hyperdoc/DMX workspace journal model.html")
   "DMX workspace journal model"
   '("Surface"
     "Surface boundary"
     "Failure surface"))
  (assert-surface-page-contains-all
   (read-surface-page "hyperdoc/DMX workspace journal reconcile call graph.html")
   "DMX workspace journal reconcile call graph"
   '("Surface"
     "Diagnostic surface"
     "Failure surface"))
  (assert-surface-page-contains-all
   (read-surface-page "hyperdoc/Surface and Artifact Answers.html")
   "Surface and Artifact Answers"
   '("Surface"
     "Surface Answer"))
  (assert-surface-page-contains-all
   (read-surface-page "hyperdoc/Documentation Surfaces in HyperDoc.html")
   "Documentation Surfaces in HyperDoc"
   '("Surface"
     "Surface boundary")))

(defun run-surface-smoke-tests ()
  (run-surface-runtime-smoke-test)
  (run-surface-documentation-smoke-test)
  (format t "~&Surface smoke tests passed.~%")
  t)
