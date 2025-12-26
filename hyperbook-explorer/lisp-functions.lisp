;;;; Lisp functions as a HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(defclass lisp-functions (hyperbook) ())

(defvar *lisp-functions* (make-instance 'lisp-functions :id "lisp-functions"))

(defmethod title-of ((hb lisp-functions))
  "Lisp Functions")

(eval-when (:load-toplevel)
  (register *lisp-functions*))

(defmethod find-page ((hb lisp-functions) page-id &key signal-error?)
  (let* ((*package* (find-package "CL-USER"))
         (symbol
           (handler-case
               (multiple-value-bind (object pos)
                   (read-from-string page-id)
                 (if (>= pos (length page-id))
                     object
                     (and signal-error?
                          (error (str:concat "Unprocessed part of expression: \""
                                             (str:substring pos (length page-id) page-id)
                                             "\"")))))
             (error (c) (and signal-error?
                             (error c))))))
    (symbol-function symbol)))
