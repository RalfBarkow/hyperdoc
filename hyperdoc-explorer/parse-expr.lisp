;;;; Parse and evaluate expressions embedded in pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defun parse (string)
  "Parse STRING as Lisp code. If any error occurs, return the error condition."
  (handler-case
      (multiple-value-bind (object pos)
          (read-from-string string)
        (if (>= pos (length string))
            object
            (error (str:concat "Unprocessed part of expression: "
                               (str:substring pos (length string) string)))))
    (error (c) c)))

(defun parse-and-eval (string)
  "Parse STRING as Lisp code, evaluate it, and return the result.
If any error occurs, return the error condition."
  (let ((form (parse string)))
    (if (typep form 'condition)
        form
        (handler-case (eval form)
          (error (c) c)))))
