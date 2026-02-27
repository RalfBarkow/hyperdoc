;;;; Override playground object binding generation
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :html-inspector-views/standard)

(defun add-object-bindings (s-exp object package)
  (let ((star-symbol (intern "*" package)))
    `(let ((,star-symbol ',object))
       ,s-exp)))
