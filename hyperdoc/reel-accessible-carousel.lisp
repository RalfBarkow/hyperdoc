;;;; Inspector Reel/carousel documentation and inspection handles.

(in-package :hyperdoc)

(defparameter *reel-accessible-carousel-page-title*
  "The Reel as Accessible Carousel")

(eval-when (:load-toplevel :execute)
  (setf *topic-index-state* :stale))

(defclass reel-accessible-carousel-slice ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (page-title :reader reel-accessible-carousel-page-title-of
               :initarg :page-title)
   (page-pathname :reader reel-accessible-carousel-page-pathname-of
                  :initarg :page-pathname)
   (scxml-pathname :reader reel-accessible-carousel-slice-scxml-pathname-of
                   :initarg :scxml-pathname)
   (state-model :reader reel-accessible-carousel-slice-state-model-of
                :initarg :state-model)
   (plan :reader reel-accessible-carousel-slice-plan-of
         :initarg :plan)
   (goldberg-answers :reader reel-accessible-carousel-goldberg-answers-of
                     :initarg :goldberg-answers)
   (runtime-implementation-files
    :reader reel-accessible-carousel-runtime-implementation-files-of
    :initarg :runtime-implementation-files
    :initform nil)
   (smoke-test-functions
    :reader reel-accessible-carousel-smoke-test-functions-of
    :initarg :smoke-test-functions
    :initform nil)
   (playwright-spec-pathname
    :reader reel-accessible-carousel-playwright-spec-pathname-of
    :initarg :playwright-spec-pathname)))

(defclass reel-accessible-carousel-scxml-artifact ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (relative-path :reader relative-path-of :initarg :relative-path)
   (events :reader reel-accessible-carousel-scxml-events-of
           :initarg :events :initform nil)
   (invariants :reader reel-accessible-carousel-scxml-invariants-of
               :initarg :invariants :initform nil)))

(defclass reel-accessible-carousel-plan ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (shop3-task-form :reader reel-accessible-carousel-plan-shop3-task-form-of
                    :initarg :shop3-task-form)
   (tasks :reader reel-accessible-carousel-plan-tasks-of
          :initarg :tasks :initform nil)))

(defclass reel-accessible-carousel-plan-task ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (status :reader reel-accessible-carousel-plan-task-status-of
           :initarg :status)
   (implementation-evidence-path
    :reader reel-accessible-carousel-plan-task-implementation-evidence-path-of
    :initarg :implementation-evidence-path)
   (validation-evidence-path
    :reader reel-accessible-carousel-plan-task-validation-evidence-path-of
    :initarg :validation-evidence-path)))

(defmethod print-object ((slice reel-accessible-carousel-slice) stream)
  (print-unreadable-object (slice stream :type t :identity nil)
    (format stream "~A" (title-of slice))))

(defmethod print-object ((artifact reel-accessible-carousel-scxml-artifact) stream)
  (print-unreadable-object (artifact stream :type t :identity nil)
    (format stream "~A" (title-of artifact))))

(defmethod print-object ((plan reel-accessible-carousel-plan) stream)
  (print-unreadable-object (plan stream :type t :identity nil)
    (format stream "~A" (title-of plan))))

(defun reel-accessible-carousel-page-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/The Reel as Accessible Carousel.html"))

(defun reel-accessible-carousel-scxml-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/reel-accessible-carousel.scxml"))

(defun reel-accessible-carousel-playwright-spec-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "tests/playwright/reel-accessible-carousel.spec.js"))

(defun reel-accessible-carousel-page ()
  "Return the central documentation page for the inspector Reel slice."
  (asdf:load-system :hyperdoc/explorer)
  (find-page *hyperdoc*
             *reel-accessible-carousel-page-title*
             :signal-error? t))

(defun reel-accessible-carousel-scxml-source ()
  (uiop:read-file-string (reel-accessible-carousel-scxml-pathname)))

(defun reel-accessible-carousel-state-model ()
  (reel-accessible-carousel-scxml-artifact))

(defun reel-accessible-carousel-scxml-artifact ()
  (make-instance
   'reel-accessible-carousel-scxml-artifact
   :id "reel-accessible-carousel-scxml"
   :title "Reel progressive enhancement state model"
   :summary "SCXML sketch for the inspector Reel lifecycle from native horizontal scrolling to enhanced boundary buttons and pane inertness."
   :relative-path "hyperdoc/reel-accessible-carousel.scxml"
   :events '("dom.ready"
             "scroll"
             "intersection.changed"
             "done")
   :invariants '("no autoplay timer"
                 "buttons are hidden until JavaScript initializes"
                 "less-than-half-visible panes become inert when supported"
                 "native horizontal overflow remains usable")))

(defun make-reel-accessible-carousel-plan-task
    (id title status implementation-evidence-path validation-evidence-path
     &key summary)
  (make-instance
   'reel-accessible-carousel-plan-task
   :id id
   :title title
   :summary (or summary title)
   :status status
   :implementation-evidence-path implementation-evidence-path
   :validation-evidence-path validation-evidence-path))

(defun reel-accessible-carousel-shop3-task-form ()
  '(:task apply-the-reel-as-accessible-carousel
    :given
    ((hyperdoc-inspector-pane-surface exists)
     (browser-native-horizontal-overflow available)
     (gel-carousel-accessibility-contract available))
    :achieve
    ((inspector-panes-behave-as-accessible-reel)
     (keyboard-mouse-touch-navigation-supported)
     (offscreen-panes-do-not-trap-focus)
     (layout-behavior-is-test-covered))))

(defun reel-accessible-carousel-plan ()
  (make-instance
   'reel-accessible-carousel-plan
   :id "reel-accessible-carousel-plan"
   :title "Reel as Accessible Carousel plan"
   :summary "SHOP3-like implementation plan for applying the accessible Reel/carousel pattern to HyperDoc inspector panes."
   :shop3-task-form (reel-accessible-carousel-shop3-task-form)
   :tasks
   (list
    (make-reel-accessible-carousel-plan-task
     "css-dom-structure"
     "CSS and DOM structure"
     "done"
     "assets/hyperdoc/css/hyperdoc-reel.css"
     "tests/playwright/reel-accessible-carousel.spec.js")
    (make-reel-accessible-carousel-plan-task
     "javascript-behavior"
     "JavaScript behavior"
     "done"
     "assets/hyperdoc/js/hyperdoc-reel.js"
     "tests/playwright/reel-accessible-carousel.spec.js")
    (make-reel-accessible-carousel-plan-task
     "inspector-integration"
     "Inspector integration"
     "done"
     "hyperbook-server/inspector-performance.lisp"
     "tests/playwright/reel-accessible-carousel.spec.js")
    (make-reel-accessible-carousel-plan-task
     "tests-docs"
     "Tests and docs"
     "done"
     "hyperdoc/The Reel as Accessible Carousel.html"
     "tests/reel-accessible-carousel-smoke.lisp"))))

(defun reel-accessible-carousel-goldberg-answers ()
  '((:question "What is this component?"
     :answer "A user-controlled horizontal inspector pane Reel.")
    (:question "What problem does it solve?"
     :answer "It gives multiple inspector panes a perceivable, accessible horizontal navigation model.")
    (:question "What are its parts?"
     :answer "Group, buttons, scrollable viewport, pane list, pane items, inertness observer.")
    (:question "What happens without JavaScript?"
     :answer "Native horizontal scrolling remains usable.")
    (:question "What happens with JavaScript?"
     :answer "Buttons, inertness, and boundary disabling are added.")
    (:question "What must never happen?"
     :answer "Autoplay, focus traps in obscured panes, or a custom widget that suppresses native scrolling.")))

(defun reel-accessible-carousel-slice ()
  "Return the durable inspection object for the inspector Reel/carousel slice."
  (make-instance
   'reel-accessible-carousel-slice
   :id "reel-accessible-carousel-slice"
   :title "The Reel as Accessible Carousel"
   :summary
   "Durable documentation and validation slice for HyperDoc inspector panes as a browser-native accessible Reel."
   :page-title *reel-accessible-carousel-page-title*
   :page-pathname (reel-accessible-carousel-page-pathname)
   :scxml-pathname (reel-accessible-carousel-scxml-pathname)
   :state-model (reel-accessible-carousel-state-model)
   :plan (reel-accessible-carousel-plan)
   :goldberg-answers (reel-accessible-carousel-goldberg-answers)
   :runtime-implementation-files
   '("hyperbook-server/inspector-performance.lisp"
     "assets/hyperdoc/css/hyperdoc-reel.css"
     "assets/hyperdoc/js/hyperdoc-reel.js")
   :smoke-test-functions
   '("hyperdoc/tests:run-reel-accessible-carousel-smoke-tests")
   :playwright-spec-pathname (reel-accessible-carousel-playwright-spec-pathname)))

(defun run-reel-accessible-carousel-slice-checks ()
  "Load the test system and run the focused inspector Reel smoke tests."
  (asdf:load-system :hyperdoc/tests)
  (let* ((package (or (find-package :hyperdoc/tests)
                      (error "Package HYPERDOC/TESTS is not available.")))
         (symbol (find-symbol "RUN-REEL-ACCESSIBLE-CAROUSEL-SMOKE-TESTS"
                              package)))
    (unless (and symbol (fboundp symbol))
      (error "Reel accessible carousel smoke test function is not available."))
    (funcall symbol)))
