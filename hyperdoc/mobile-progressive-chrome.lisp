;;;; Mobile progressive chrome documentation/inspection reload boundary.

(in-package :hyperdoc)

(defparameter *mobile-progressive-chrome-system-name*
  "hyperdoc/mobile-progressive-chrome")

(defparameter *mobile-progressive-chrome-page-title*
  "Mobile progressive chrome in HyperDoc")

(eval-when (:load-toplevel :execute)
  (setf *topic-index-state* :stale))

(defclass mobile-progressive-chrome-system-slice ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (system-name :reader mobile-progressive-chrome-system-name-of
                :initarg :system-name)
   (page-title :reader mobile-progressive-chrome-page-title-of
               :initarg :page-title)
   (page-pathname :reader mobile-progressive-chrome-page-pathname-of
                  :initarg :page-pathname)
   (scxml-pathname :reader mobile-progressive-chrome-slice-scxml-pathname-of
                   :initarg :scxml-pathname)
   (state-model :reader mobile-progressive-chrome-slice-state-model-of
                :initarg :state-model)
   (plan :reader mobile-progressive-chrome-slice-plan-of
         :initarg :plan)
   (runtime-implementation-files
    :reader mobile-progressive-chrome-runtime-implementation-files-of
    :initarg :runtime-implementation-files
    :initform nil)
   (smoke-test-functions
    :reader mobile-progressive-chrome-smoke-test-functions-of
    :initarg :smoke-test-functions
    :initform nil)
   (playwright-spec-pathname
    :reader mobile-progressive-chrome-playwright-spec-pathname-of
    :initarg :playwright-spec-pathname)))

(defmethod print-object ((slice mobile-progressive-chrome-system-slice) stream)
  (print-unreadable-object (slice stream :type t :identity nil)
    (format stream "~A" (mobile-progressive-chrome-system-name-of slice))))

(defun mobile-progressive-chrome-page-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/Mobile progressive chrome in HyperDoc.html"))

(defun mobile-progressive-chrome-playwright-spec-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "tests/playwright/mobile-progressive-chrome.spec.js"))

(defun mobile-progressive-chrome-page ()
  "Return the central documentation page for the mobile chrome slice."
  (asdf:load-system :hyperdoc/explorer)
  (find-page *hyperdoc*
             *mobile-progressive-chrome-page-title*
             :signal-error? t))

(defun mobile-progressive-chrome-state-model ()
  "Return the Dock state model that owns the mobile layer semantics."
  (dock-presentation-model))

(defun mobile-progressive-chrome-system-slice ()
  "Return the narrow reload/inspection object for mobile progressive chrome."
  (make-instance
   'mobile-progressive-chrome-system-slice
   :id "mobile-progressive-chrome-system-slice"
   :title "Mobile progressive chrome ASDF reload boundary"
   :summary
   "Narrow ASDF reload and inspection boundary for the mobile progressive chrome documentation slice; runtime behavior remains in HyperDoc's main Dock and DOM annotation implementation."
   :system-name *mobile-progressive-chrome-system-name*
   :page-title *mobile-progressive-chrome-page-title*
   :page-pathname (mobile-progressive-chrome-page-pathname)
   :scxml-pathname (mobile-progressive-chrome-scxml-pathname)
   :state-model (mobile-progressive-chrome-state-model)
   :plan (mobile-progressive-chrome-plan)
   :runtime-implementation-files
   '("assets/hyperdoc/js/dom-annotation-connect.js"
     "assets/hyperdoc/css/dom-annotation-connect.css"
     "hyperdoc/dock.lisp"
     "hyperdoc/dom-annotations.lisp"
     "hyperdoc-explorer/dock.lisp"
     "hyperdoc-explorer/dom-annotations.lisp")
   :smoke-test-functions
   '("hyperdoc/tests:run-mobile-progressive-chrome-smoke-tests")
   :playwright-spec-pathname (mobile-progressive-chrome-playwright-spec-pathname)))

(defun reload-mobile-progressive-chrome-slice (&key (force? t))
  "Reload the narrow mobile progressive chrome ASDF slice and return its object."
  (asdf:load-system :hyperdoc/mobile-progressive-chrome :force force?)
  (mobile-progressive-chrome-system-slice))

(defun run-mobile-progressive-chrome-slice-checks ()
  "Load the test system and run the focused mobile progressive chrome smoke tests."
  (asdf:load-system :hyperdoc/tests)
  (let* ((package (or (find-package :hyperdoc/tests)
                      (error "Package HYPERDOC/TESTS is not available.")))
         (symbol (find-symbol "RUN-MOBILE-PROGRESSIVE-CHROME-SMOKE-TESTS"
                              package)))
    (unless (and symbol (fboundp symbol))
      (error "Mobile progressive chrome smoke test function is not available."))
    (funcall symbol)))
