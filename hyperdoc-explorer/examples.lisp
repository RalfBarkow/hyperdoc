;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defmethod html-inspector-views/standard:render-toplevel-cst :around
    ((head (eql 'defexample)) cst source position)
  (eval-button "►"
               (thunk (-> cst cst:second cst:raw symbol-function funcall)))
  (call-next-method))
