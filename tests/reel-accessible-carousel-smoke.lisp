;;;; Smoke tests for the inspector Reel/carousel artifacts.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-REEL-ACCESSIBLE-CAROUSEL-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun reel-carousel-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun reel-carousel-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun run-reel-accessible-carousel-slice-smoke-test ()
  (asdf:load-system :hyperdoc)
  (let ((slice (hyperdoc:reel-accessible-carousel-slice)))
    (reel-carousel-assert-equal
     "The Reel as Accessible Carousel"
     (hyperdoc::title-of slice)
     "Slice title must match the page/topic title")
    (dolist (pathname
             (list (hyperdoc::reel-accessible-carousel-page-pathname-of slice)
                   (hyperdoc::reel-accessible-carousel-slice-scxml-pathname-of
                    slice)
                   (hyperdoc::reel-accessible-carousel-playwright-spec-pathname-of
                    slice)))
      (reel-carousel-assert-true
       (uiop:file-exists-p pathname)
       (format nil "Slice pathname must exist: ~A" pathname)))
    (reel-carousel-assert-true
     (typep (hyperdoc::reel-accessible-carousel-slice-plan-of slice)
            'hyperdoc::reel-accessible-carousel-plan)
     "Slice object must expose the Reel plan object")
    (reel-carousel-assert-true
     (typep (hyperdoc::reel-accessible-carousel-slice-state-model-of slice)
            'hyperdoc::reel-accessible-carousel-scxml-artifact)
     "Slice object must expose the Reel SCXML artifact")
    (reel-carousel-assert-true
     (typep (hyperdoc:reel-accessible-carousel-page)
            'hyperdoc::html-page)
     "Slice helper must find the central HTML page")))

(defun run-reel-accessible-carousel-topic-smoke-test ()
  (dolist (title '("The Reel as Accessible Carousel"
                   "Inspector pane surface"
                   "Accessible Reel carousel contract"
                   "Reel progressive enhancement state model"
                   "Reel as Accessible Carousel plan"))
    (reel-carousel-assert-true
     (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
     (format nil "Topic cluster must include ~A" title))))

(defun run-reel-accessible-carousel-scxml-smoke-test ()
  (let* ((artifact (hyperdoc::reel-accessible-carousel-scxml-artifact))
         (source (hyperdoc::reel-accessible-carousel-scxml-source))
         (chart (hyperdoc/scxml:parse-scxml-file
                 (hyperdoc::reel-accessible-carousel-scxml-pathname)))
         (state-ids (mapcar #'hyperdoc/scxml:scxml-state-id-of
                            (hyperdoc/scxml:scxml-chart-states-of chart))))
    (reel-carousel-assert-equal
     "Reel progressive enhancement state model"
     (hyperdoc::title-of artifact)
     "SCXML artifact must be inspectable")
    (dolist (needle '("dom.ready"
                      "scroll"
                      "intersection.changed"
                      "updating-boundary-buttons"
                      "updating-pane-inertness"))
      (reel-carousel-assert-true
       (search needle source :test #'char=)
       (format nil "SCXML source must mention ~A" needle)))
    (dolist (state-id '("uninitialized"
                        "enhanced"
                        "updating-boundary-buttons"
                        "updating-pane-inertness"))
      (reel-carousel-assert-true
       (member state-id state-ids :test #'string=)
       (format nil "SCXML parse must include state ~A" state-id)))))

(defun run-reel-accessible-carousel-plan-smoke-test ()
  (let* ((plan (hyperdoc::reel-accessible-carousel-plan))
         (task-form
          (hyperdoc::reel-accessible-carousel-plan-shop3-task-form-of plan))
         (tasks (hyperdoc::reel-accessible-carousel-plan-tasks-of plan))
         (ids (mapcar #'hyperdoc::id-of tasks)))
    (reel-carousel-assert-equal
     'hyperdoc::apply-the-reel-as-accessible-carousel
     (second task-form)
     "Plan must expose the requested SHOP3 task name")
    (dolist (id '("css-dom-structure"
                  "javascript-behavior"
                  "inspector-integration"
                  "tests-docs"))
      (reel-carousel-assert-true
       (member id ids :test #'string=)
       (format nil "Plan must include task ~A" id)))
    (reel-carousel-assert-true
     (every #'hyperdoc::reel-accessible-carousel-plan-task-implementation-evidence-path-of
            tasks)
     "Each plan task must expose implementation evidence")
    (reel-carousel-assert-true
     (every #'hyperdoc::reel-accessible-carousel-plan-task-validation-evidence-path-of
            tasks)
     "Each plan task must expose validation evidence")))

(defun run-reel-accessible-carousel-doc-smoke-test ()
  (let ((page (hyperbook:find-page hyperdoc::*hyperdoc*
                                   "The Reel as Accessible Carousel"
                                   :signal-error? t)))
    (reel-carousel-assert-true
     (typep page 'hyperdoc::html-page)
     "Reel page must materialize as an HTML page")
    (let ((text (plump:text (hyperbook:dom-of page))))
      (dolist (needle '("Page genre: reference/contract"
                        "Inspector Contract"
                        "SHOP3 Task"
                        "SCXML Sketch"
                        "Goldberg Questions"
                        "Autoplay must never be introduced"))
        (reel-carousel-assert-true
         (search needle text :test #'char=)
         (format nil "Documentation page must contain ~S" needle))))))

(defun run-reel-accessible-carousel-smoke-tests ()
  (run-reel-accessible-carousel-slice-smoke-test)
  (run-reel-accessible-carousel-topic-smoke-test)
  (run-reel-accessible-carousel-scxml-smoke-test)
  (run-reel-accessible-carousel-plan-smoke-test)
  (run-reel-accessible-carousel-doc-smoke-test)
  (format t "~&Reel accessible carousel smoke tests passed.~%")
  t)
