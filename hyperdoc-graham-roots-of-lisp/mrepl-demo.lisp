;;;; Evaluate this file after installing the ASDF system in the HyperDoc repo.

(asdf:load-system :hyperdoc-graham-roots-of-lisp)

(let ((report
        (hyperdoc-graham-roots-of-lisp:roots-surprise-report
         :event-limit 5000)))
  (let* ((package (find-package "CLOG-MOLDABLE-INSPECTOR"))
         (symbol (and package (find-symbol "CLOG-INSPECT" package))))
    (when (and symbol (fboundp symbol))
      (funcall (symbol-function symbol) :object report)))
  report)
