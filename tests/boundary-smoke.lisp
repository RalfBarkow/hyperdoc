;;;; Focused smoke tests for generic boundary objects and docs
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-BOUNDARY-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun boundary-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun boundary-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun boundary-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun boundary-smoke-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun read-boundary-page (namestring)
  (uiop:read-file-string
   (boundary-smoke-relative-path namestring)))

(defun normalize-boundary-smoke-whitespace (string)
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

(defun assert-boundary-page-contains-all (page-source page-label needles)
  (let ((normalized
          (normalize-boundary-smoke-whitespace page-source)))
    (dolist (needle needles)
      (boundary-assert-true
       (search (normalize-boundary-smoke-whitespace needle)
               normalized
               :test #'char=)
       (format nil "~A must contain ~S" page-label needle)))))

(defun boundary-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun boundary-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun run-boundary-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((definition (hyperdoc::make-example-boundary-definition))
         (instance (hyperdoc::make-example-boundary-instance))
         (dmx-note (hyperdoc::make-dmx-note-read-write-boundary-definition))
         (dmx-transition
           (hyperdoc::make-dmx-workspace-journal-preflight-boundary-definition))
         (dmx-auth
           (hyperdoc::make-dmx-repair-console-authentication-boundary-definition))
         (dmx-blocked
           (hyperdoc::make-dmx-workspace-journal-preflight-blocked-boundary-instance))
         (definition-views
           (boundary-smoke-load-inspector-views-for-object definition))
         (instance-views
           (boundary-smoke-load-inspector-views-for-object instance))
         (dmx-note-views
           (boundary-smoke-load-inspector-views-for-object dmx-note))
         (dmx-transition-views
           (boundary-smoke-load-inspector-views-for-object dmx-transition))
         (dmx-auth-views
           (boundary-smoke-load-inspector-views-for-object dmx-auth))
         (dmx-blocked-views
           (boundary-smoke-load-inspector-views-for-object dmx-blocked)))
    (boundary-assert-typep
     'hyperdoc::boundary-definition
     definition
     "Example boundary definition must materialize as a boundary-definition")
    (boundary-assert-typep
     'hyperdoc::boundary-instance
     instance
     "Example boundary instance must materialize as a boundary-instance")
    (boundary-assert-typep
     'hyperdoc::boundary-definition
     dmx-note
     "DMX note worked example must materialize as a boundary-definition")
    (boundary-assert-typep
     'hyperdoc::boundary-definition
     dmx-transition
     "DMX workspace-journal preflight example must materialize as a boundary-definition")
    (boundary-assert-typep
     'hyperdoc::boundary-definition
     dmx-auth
     "DMX repair-console auth example must materialize as a boundary-definition")
    (boundary-assert-typep
     'hyperdoc::boundary-instance
     dmx-blocked
     "Blocked DMX preflight must materialize as a boundary-instance")
    (dolist (title '("Overview"
                     "Sides and crossing condition"
                     "Permitted and blocked operations"
                     "Failure classifications"
                     "Adjacent surfaces and stages"
                     "Related boundaries"
                     "Source evidence / code path"))
      (boundary-assert-true
       (boundary-smoke-find-view-by-title definition-views title)
       (format nil "Boundary definition must expose view ~A" title)))
    (dolist (title '("Overview"
                     "Boundary state"
                     "Crossing attempt"
                     "Evidence"
                     "Failure analysis"
                     "Adjacent stages and surfaces"
                     "Source evidence / code path"))
      (boundary-assert-true
       (boundary-smoke-find-view-by-title instance-views title)
       (format nil "Boundary instance must expose view ~A" title)))
    (assert-boundary-page-contains-all
     (html-inspector-views:view-html
      (boundary-smoke-find-view-by-title dmx-note-views
                                         "Sides and crossing condition"))
     "DMX note boundary definition"
     '("dmx.notes.note"
       "parent note"))
    (assert-boundary-page-contains-all
     (html-inspector-views:view-html
      (boundary-smoke-find-view-by-title dmx-transition-views "Overview"))
     "DMX transition boundary definition"
     '("transition"
       "Failure classifications"))
    (assert-boundary-page-contains-all
     (html-inspector-views:view-html
      (boundary-smoke-find-view-by-title dmx-auth-views
                                         "Permitted and blocked operations"))
     "DMX auth boundary definition"
     '("Username"
       "credential"))
    (assert-boundary-page-contains-all
     (html-inspector-views:view-html
      (boundary-smoke-find-view-by-title dmx-blocked-views "Evidence"))
     "DMX blocked boundary instance"
     '("prepare-transition"
       "PUT /core/topic/927568"
       "HTTP 401"))
    (assert-boundary-page-contains-all
     (html-inspector-views:view-html
      (boundary-smoke-find-view-by-title dmx-blocked-views
                                         "Failure analysis"))
     "DMX blocked boundary failure analysis"
     '("auth-blocked"
       "Boundary instance"))))

(defun run-boundary-documentation-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (spec '((hyperdoc::boundary-topic . "Boundary")
                  (hyperdoc::contract-boundary-topic . "Contract boundary")
                  (hyperdoc::transition-boundary-topic . "Transition boundary")
                  (hyperdoc::authentication-boundary-topic
                   . "Authentication boundary")
                  (hyperdoc::read-write-boundary-topic . "Read-write boundary")
                  (hyperdoc::boundary-report-topic . "Boundary report")))
    (let* ((symbol (car spec))
           (title (cdr spec))
           (topic (funcall symbol)))
      (boundary-assert-true
       (fboundp symbol)
       (format nil "Missing topic function ~A" symbol))
      (boundary-assert-equal title
                             (hyperbook:title-of topic)
                             (format nil "Topic ~A title" symbol))
      (boundary-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Missing Topics HyperBook page ~A" title))))
  (dolist (page-title '("Boundary"
                        "Contract boundary"
                        "Transition boundary"
                        "Authentication boundary"
                        "Read-write boundary"
                        "Boundary report"
                        "Operational definition: boundary, contract boundary, transition boundary, boundary report"))
    (boundary-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* page-title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" page-title)))
  (assert-boundary-page-contains-all
   (read-boundary-page "hyperdoc/Boundary.html")
   "Boundary"
   '("Runtime Dispatch Seams in HyperDoc"
     "DMX note read/write boundary"
     "DMX workspace journal model"
     "Documentation Surfaces in HyperDoc"
     "HyperDoc surface boundaries"))
  (assert-boundary-page-contains-all
   (read-boundary-page
    "hyperdoc/Operational definition: boundary, contract boundary, transition boundary, boundary report.html")
   "Operational definition: boundary, contract boundary, transition boundary, boundary report"
   '("A boundary is a bounded transition or contract edge"
     "the two sides it relates"
     "contract boundary"
     "transition boundary"
     "a reusable definition object"
     "a concrete boundary instance"))
  (assert-boundary-page-contains-all
   (read-boundary-page "hyperdoc/Boundary report.html")
   "Boundary report"
   '("Execution evidence object"
     "Runtime provenance"
     "Runtime Dispatch Seams in HyperDoc"))
  (assert-boundary-page-contains-all
   (read-boundary-page "hyperdoc/DMX note read-write boundary.html")
   "DMX note read/write boundary"
   '("Read-write boundary"
     "Contract boundary"))
  (assert-boundary-page-contains-all
   (read-boundary-page "hyperdoc/Using authenticated workspace assignment repair console.html")
   "Using authenticated workspace assignment repair console"
   '("Authentication boundary"
     "Transition boundary"))
  (assert-boundary-page-contains-all
   (read-boundary-page "hyperdoc/DMX workspace journal model.html")
   "DMX workspace journal model"
   '("Transition boundary"
     "Boundary"))
  (assert-boundary-page-contains-all
   (read-boundary-page "hyperdoc/Runtime Dispatch Seams in HyperDoc.html")
   "Runtime Dispatch Seams in HyperDoc"
   '("Boundary"
     "Transition boundary"
     "Boundary report")))

(defun run-boundary-smoke-tests ()
  (run-boundary-runtime-smoke-test)
  (run-boundary-documentation-smoke-test)
  (format t "~&Boundary smoke tests passed.~%")
  t)
