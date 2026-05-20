;;;; Smoke tests for native generic topicmap projection views.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-TOPICMAP-VIEW-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun topicmap-view-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun topicmap-view-assert-false (condition message)
  (when condition
    (error "~A" message)))

(defun topicmap-view-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun topicmap-view-assert-contains (needle haystack message)
  (unless (and haystack (search needle haystack :test #'char=))
    (error "~A -- missing substring: ~S" message needle)))

(defun topicmap-view-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun topicmap-view-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun topicmap-view-title-position (views title)
  (position title
            views
            :key #'html-inspector-views:view-title
            :test #'string=))

(defun topicmap-view-rendered-view-html (object title)
  (let* ((views (topicmap-view-load-inspector-views-for-object object))
         (view (topicmap-view-find-view-by-title views title)))
    (unless view
      (error "Missing inspector view ~S in ~S"
             title
             (mapcar #'html-inspector-views:view-title views)))
    (html-inspector-views:view-html view)))

(defun topicmap-view-readme-pathname ()
  (asdf:system-relative-pathname :hyperdoc "README.md"))

(defun assert-dm6-inline-topicmap-island (html message-prefix)
  (dolist (needle '("dm6-hyperdoc-map"
                    "dm6-island"
                    "dm6-canvas"
                    "dm6-stage"
                    "dm6-stored"))
    (topicmap-view-assert-contains
     needle
     html
     (format nil "~A must contain the DM6 inline topicmap island marker"
             message-prefix))))

(defun run-topicmap-view-rendering-smoke-test ()
  (let* ((pathname (topicmap-view-readme-pathname))
         (projection (hyperdoc:topicmap-projection-of pathname))
         (html (hyperdoc:render-topicmap-view-of-object-html pathname)))
    (topicmap-view-assert-typep
     'hyperdoc:topicmap-projection
     projection
     "Existing source pathname must produce a native topicmap projection")
    (assert-dm6-inline-topicmap-island
     html
     "Rendered pathname topicmap view")
    (topicmap-view-assert-contains
     "hyperdoc-dm6-inline.css"
     html
     "Standalone renderer must include the existing DM6 inline CSS asset")
    (topicmap-view-assert-contains
     "hyperdoc-dm6-inline.js"
     html
     "Standalone renderer must include the existing DM6 inline JS asset")
    (topicmap-view-assert-contains
     "native-topicmap-projection-v1"
     html
     "Rendered topicmap view must identify the native projection seed")))

(defun run-topicmap-view-inspector-content-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((projection (hyperdoc:topicmap-projection-of
                      (topicmap-view-readme-pathname)))
         (views (topicmap-view-load-inspector-views-for-object projection))
         (content (topicmap-view-find-view-by-title views "Content"))
         (slots-index (topicmap-view-title-position views "Slots")))
    (topicmap-view-assert-true
     content
     "topicmap-projection inspector dispatch must expose Content")
    (when slots-index
      (topicmap-view-assert-true
       (< (topicmap-view-title-position views "Content") slots-index)
       "Content must appear before Slots for topicmap-projection objects"))
    (assert-dm6-inline-topicmap-island
     (html-inspector-views:view-html content)
     "topicmap-projection Content view")))

(defun run-topicmap-view-artifact-dispatch-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((artifact (hyperdoc:make-file-artifact "README.md"))
         (views (topicmap-view-load-inspector-views-for-object artifact))
         (topicmap (topicmap-view-find-view-by-title views "Topicmap")))
    (topicmap-view-assert-true
     topicmap
     "file-artifact inspector dispatch must expose Topicmap when projection succeeds")
    (assert-dm6-inline-topicmap-island
     (html-inspector-views:view-html topicmap)
     "file-artifact Topicmap view")))

(defun run-topicmap-view-no-fallback-tab-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let ((views (topicmap-view-load-inspector-views-for-object
                (list :not-a-source-artifact))))
    (topicmap-view-assert-false
     (topicmap-view-find-view-by-title views "Topicmap")
     "Generic fallback must not add Topicmap when no meaningful projection exists")
    (topicmap-view-assert-false
     (hyperdoc:topicmap-projection-of (list :not-a-source-artifact))
     "Generic topicmap-projection-of fallback must return NIL")))

(defun run-topicmap-view-public-entrypoint-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (multiple-value-bind (symbol status)
      (find-symbol "INSPECT-TOPICMAP-VIEW" :hyperdoc/inspector)
    (topicmap-view-assert-true
     (eq status :external)
     "HYPERDOC/INSPECTOR must export INSPECT-TOPICMAP-VIEW")
    (topicmap-view-assert-true
     (fboundp symbol)
     "HYPERDOC/INSPECTOR:INSPECT-TOPICMAP-VIEW must be fbound"))
  (let* ((artifact (hyperdoc:make-file-artifact "README.md"))
         (projection-target
           (hyperdoc/inspector::topicmap-inspection-target artifact))
         (fallback-object (list :not-a-source-artifact))
         (fallback-target
           (hyperdoc/inspector::topicmap-inspection-target fallback-object)))
    (topicmap-view-assert-typep
     'hyperdoc:topicmap-projection
     projection-target
     "Public inspector entrypoint must target a projection when one exists")
    (topicmap-view-assert-true
     (eq fallback-object fallback-target)
     "Public inspector entrypoint target helper must fall back to original object"))
  (let ((captured-target nil)
        (return-target nil))
    (let ((hyperdoc/inspector::*topicmap-inspector-invoker*
            (lambda (target)
              (setf captured-target target)
              :mock-inspected)))
      (setf return-target
            (hyperdoc/inspector:inspect-topicmap-view
             (hyperdoc:make-file-artifact "README.md"))))
    (topicmap-view-assert-typep
     'hyperdoc:topicmap-projection
     captured-target
     "Public inspector entrypoint must inspect the projected target")
    (topicmap-view-assert-true
     (eq captured-target return-target)
     "Public inspector entrypoint must return the inspected target")))

(defun run-topicmap-view-overlay-contract-smoke-test ()
  (let ((asset (uiop:read-file-string
                (asdf:system-relative-pathname
                 :hyperdoc
                 "assets/dm6-elm/hyperdoc-dm6-inline.js")))
        (html (hyperdoc:render-topicmap-view-of-object-html
               (topicmap-view-readme-pathname))))
    (topicmap-view-assert-contains
     "hyperdoc-embedded-app-focus"
     asset
     "Existing DM6 inline JS must own embedded-app focus state")
    (topicmap-view-assert-contains
     "HyperDoc overlays paused inside embedded app"
     asset
     "Existing DM6 inline JS must expose the overlay pause marker")
    (topicmap-view-assert-contains
     "dm6-hyperdoc-state"
     html
     "Generic topicmap view must reuse the state marker consumed by DM6 inline JS")
    (topicmap-view-assert-contains
     "hyperdoc-dm6-inline.js"
     html
     "Generic topicmap view must load the existing DM6 inline JS")))

(defun run-topicmap-view-dm6-proof-contract-smoke-test ()
  (let ((source (uiop:read-file-string
                 (asdf:system-relative-pathname
                  :hyperdoc
                  "hyperdoc/DM6 AppEmbed HyperDoc Inline Proof.html"))))
    (topicmap-view-assert-contains
     "dm6-hyperdoc-map dm6-island"
     source
     "Existing DM6 AppEmbed proof must keep the inline island contract")
    (topicmap-view-assert-contains
     "hyperdoc-dm6-inline.js"
     source
     "Existing DM6 AppEmbed proof must still load the shared inline JS")))

(defun run-topicmap-view-smoke-tests ()
  (run-topicmap-view-rendering-smoke-test)
  (run-topicmap-view-inspector-content-smoke-test)
  (run-topicmap-view-artifact-dispatch-smoke-test)
  (run-topicmap-view-no-fallback-tab-smoke-test)
  (run-topicmap-view-public-entrypoint-smoke-test)
  (run-topicmap-view-overlay-contract-smoke-test)
  (run-topicmap-view-dm6-proof-contract-smoke-test)
  (format t "~&Topicmap view smoke tests passed.~%")
  t)
