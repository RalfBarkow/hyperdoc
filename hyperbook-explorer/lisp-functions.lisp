;;;; Lisp functions as a HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; The "Lisp Functions" hyperbook
;;

(defclass lisp-functions (hyperbook) ())

(defvar *lisp-functions* (make-instance 'lisp-functions :id "lisp-functions"))

(defmethod title-of ((hb lisp-functions))
  "Lisp Functions")

(eval-when (:load-toplevel)
  (register *lisp-functions*))

;;
;; Pages for Lisp functions
;;

(defclass lisp-function-page (page)
  ((function :reader function-of :initarg :function :type function)))

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
    (make-instance 'lisp-function-page
                   :hyperbook hb
                   :id page-id
                   :function (symbol-function symbol))))

(defmethod dom-of ((page lisp-function-page))
  (plump:make-root))

(defmethod links-of ((page lisp-function-page))
  (declare (ignore page))
  nil)

(defmethod find-link-sources ((hb lisp-functions) hyperbook-id page-id)
  (declare (ignore hb))
  nil)

(views:defview 👀function-views (page lisp-function-page)
  (views:specific-views (function-of page)))

;;
;; Remove the "content" views of hyperbooks and pages
;;

(views:defview views:👀content (hb lisp-functions)
  (declare (ignore hb))
  nil)

(views:defview views:👀content (page lisp-function-page)
  (declare (ignore page))
  nil)
