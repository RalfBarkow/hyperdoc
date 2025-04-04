;;;; Parse and evaluate expressions embedded in pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defun parse (string)
  "Parse STRING as Lisp code. Return NIL if any error occurs."
  (handler-case
      (with-input-from-string (input string) (read input))
    (error (c) (declare (ignore c)) nil)))

(defun parse-and-eval (string)
  "Parse STRING as Lisp code, evaluate it, and return the result.
Return NIL if any error occurs during parsing."
  (let ((form (parse string)))
    (when form
      (eval form))))
