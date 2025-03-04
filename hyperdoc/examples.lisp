;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Example functions
;;

(defmacro defexample (name &body body)
  `(defun ,name () ,@body))

; An example example function
(defexample the-answer
  "The answer to the question of life, the universe, and everything."
  42)
