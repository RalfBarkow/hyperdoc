;;;; Override playground object binding generation
;;;; Intentionally replaces HTML-INSPECTOR-VIEWS/STANDARD behavior so
;;;; Playground eval binds * to the inspected object.
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :html-inspector-views/standard)

(defun add-object-bindings (s-exp object package)
  (let ((star-symbol (intern "*" package)))
    `(let ((,star-symbol ',object))
       ,s-exp)))
