;;;; Error conditions
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Error conditions for various lookup failures
;;

(define-condition lookup-failure (error)
  ())

(define-condition page-lookup-failure (lookup-failure)
  ((hyperdoc :initarg :hyperdoc)
   (page-title :initarg :title)))

(define-condition hyperdoc-lookup-failure (lookup-failure)
  ((hyperdoc-title :initarg :title)))

(define-condition directory-lookup-failure (lookup-failure)
  ((catalog :initarg :catalog)
   (pathname :initarg :pathname)))
