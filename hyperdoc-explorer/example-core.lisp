;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Add a play button before a top-level defexample form.
;;

(defun source-example-entry (function-symbol)
  "Return the registered example entry for FUNCTION-SYMBOL, if any."
  (when-let (registration
             (gethash function-symbol *example-registrations*))
    (make-example-entry-from-registration registration)))

(defmethod html-inspector-views/standard:render-toplevel-cst :around
    ((head (eql 'defexample)) cst source position)
  (let* ((function-symbol (-> cst cst:second cst:raw))
         (entry (source-example-entry function-symbol)))
    (views:eval-button "►"
                       (views:thunk
                        (if entry
                            (run-example-entry entry)
                            (funcall (symbol-function function-symbol))))
                       "Run example"))
  (call-next-method))
