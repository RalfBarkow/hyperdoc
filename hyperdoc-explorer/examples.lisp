;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Add a play button before a top-level defexample form.
;;

(defmethod html-inspector-views/standard:render-toplevel-cst :around
    ((head (eql 'defexample)) cst source position)
  (views:eval-button "►"
                     (views:thunk
                       (-> cst cst:second cst:raw symbol-function funcall))
                     "Run example")
  (call-next-method))
