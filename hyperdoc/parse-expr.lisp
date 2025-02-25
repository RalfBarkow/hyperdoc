;;;; Parse and evaluate expressions embedded in pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defun parse (string)
  (handler-case
      (with-input-from-string (input string) (read input))
    (error (c) (declare (ignore c)) nil)))

(defun parse-and-eval (string)
  (let ((form (parse string)))
    (when form
      (eval form))))
