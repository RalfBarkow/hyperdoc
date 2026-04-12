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

(defun make-lisp-function-lookup-issue (hb page-id symbol condition)
  (make-function-lookup-issue
   condition
   :source-object hb
   :source-hyperbook (id-of hb)
   :source-page-title (title-of hb)
   :link-text page-id
   :target-hyperbook-id (id-of hb)
   :expected-page-id page-id
   :details (list :lookup-stage :symbol-function
                  :reference-kind :source-of-function
                  :expected-symbol symbol
                  :fboundp (fboundp symbol)
                  :condition-type (type-of condition))))

(defmethod find-page ((hb lisp-functions) page-id &key signal-error?)
  (let ((symbol (read-symbol page-id signal-error?)))
    (when symbol
      (handler-case
          (make-instance 'lisp-function-page
                         :hyperbook hb
                         :id page-id
                         :function (symbol-function symbol))
        (undefined-function (condition)
          (and signal-error?
               (make-lisp-function-lookup-issue hb page-id symbol condition)))))))

(defun read-symbol (string signal-error?)
  (let ((*package* (find-package "CL")))
    (handler-case
        (multiple-value-bind (object pos)
            (read-from-string string)
          (assert (typep object 'symbol))
          (if (>= pos (length string))
              object
              (and signal-error?
                   (error (str:concat "Unprocessed part of expression: \""
                                      (str:substring pos (length string) string)
                                      "\"")))))
      (error (c) (and signal-error?
                      (error c))))))

(views:defview 👀function-views (page lisp-function-page)
  (views:specific-views (function-of page)))

;;
;; Add an explanatory page
;;

(views:defview 👀overview (hb lisp-functions)
  (declare (ignore hb))
  (views:html-view :title "Overview" :priority 1
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:html
      (:div :class "hyperbook-page"
            (:h1 (views:esc "Lisp functions"))
            (:p (views:esc "This hyperbook contains one page for each symbol
in the Lisp image that has a function definition attached to it.
It is used for linking to Lisp code."))))))
