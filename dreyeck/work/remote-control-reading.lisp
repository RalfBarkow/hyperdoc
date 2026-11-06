(in-package #:dreyeck/work/remote-control-planning)

(hyperdoc:defhyperdoc *remote-control-reading*
  :id "dreyeck/work/remote-control-planning"
  :title "Planning Remote Control for the Zettelkasten App with SHOP3"
  :asdf-system-name "dreyeck/work/remote-control-planning/reading"
  :subdirectory "dreyeck/pages/remote-control-planning"
  :main-page-id "Planning Remote Control for the Zettelkasten App with SHOP3")

;; Book-local assets, following the CCNx reading's inherited asset contract.
(defmethod hyperbook:html-page-assets-of ((book (eql *remote-control-reading*)))
  ;; Resolve the inherited assets when rendering, not while loading the book:
  ;; HyperDoc's tag-dispatch assets are owned by the optional explorer system.
  (make-instance 'hyperbook:html-page-assets
    :inherit (call-next-method)
    :paths (list (cons "/remote-control-reading/"
                       (asdf:system-relative-pathname
                        "dreyeck/work/remote-control-planning/reading"
                        "dreyeck/remote-control-planning/assets/remote-control-reading/")))
    :css '("/remote-control-reading/css/reading.css")))

;; Keep links on different pages attached to the same observation. No plan is
;; copied or reconstructed for presentation; each case is computed once on demand.
;; Reloading this optional reading starts a fresh set of observations.
(defparameter *reading-observations* (make-hash-table))

(defun reading-case (case)
  (or (gethash case *reading-observations*)
      (setf (gethash case *reading-observations*)
            (remote-control-experiment case))))

(defun reading-result (case)
  (getf (reading-case case) :result))

(defun reading-alternative (route part)
  "Return an actual Case C result component by route, independent of plan order."
  (let* ((result (reading-result :c))
         (operator (ecase route
                     (:agent '!model-agent-route)
                     (:direct '!model-direct-route)))
         (index (position operator (dreyeck/shop3:plans-of result)
                          :key #'caar)))
    (unless index (error "No computed alternative for ~S" route))
    (nth index (ecase part
                 (:plan (dreyeck/shop3:plans-of result))
                 (:tree (dreyeck/shop3:plan-trees-of result))
                 (:state (dreyeck/shop3:final-states-of result))))))
