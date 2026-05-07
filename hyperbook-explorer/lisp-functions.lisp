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

(defun make-lisp-function-page (hb page-id definition)
  (make-instance 'lisp-function-page
                 :hyperbook hb
                 :id page-id
                 :function definition))

(defun make-lisp-function-lookup-issue (hb page-id symbol condition)
  (make-function-lookup-issue
   condition
   :source-object hb
   :source-hyperbook (id-of hb)
   :source-page-title (title-of hb)
   :link-text page-id
   :target-hyperbook-id (id-of hb)
   :expected-page-id page-id
   :details (list :lookup-stage :fdefinition
                  :reference-kind :source-of-function
                  :expected-symbol symbol
                  :fboundp (fboundp symbol)
                  :condition-type (type-of condition))))

(defun lisp-function-definition (symbol)
  (when (fboundp symbol)
    (fdefinition symbol)))

(defun package-qualified-symbol-name (symbol)
  (let ((package (symbol-package symbol)))
    (when package
      (multiple-value-bind (found status)
          (find-symbol (symbol-name symbol) package)
        (when (and (eq found symbol)
                   (member status '(:external :internal)))
          (format nil "~A~A~A"
                  (package-name package)
                  (ecase status
                    (:external ":")
                    (:internal "::"))
                  (symbol-name symbol)))))))

(defun collect-lisp-function-pages (hb)
  (let (pages)
    (dolist (package (sort (copy-list (list-all-packages))
                           #'string<
                           :key #'package-name))
      (do-symbols (symbol package)
        (when (and (eq (symbol-package symbol) package)
                   (fboundp symbol))
          (when-let ((page-id (package-qualified-symbol-name symbol))
                     (definition (lisp-function-definition symbol)))
            (push (make-lisp-function-page hb page-id definition)
                  pages)))))
    (sort pages #'string< :key #'id-of)))

(defmethod find-page ((hb lisp-functions) page-id &key signal-error?)
  (let ((symbol (read-symbol page-id signal-error?)))
    (when symbol
      (if-let ((definition (lisp-function-definition symbol)))
          (make-lisp-function-page hb page-id definition)
        (and signal-error?
             (handler-case
                 (fdefinition symbol)
               (undefined-function (condition)
                 (make-lisp-function-lookup-issue hb page-id symbol condition))))))))

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

(views:defview 👀loaded-functions (hb lisp-functions)
  (views:list-view (collect-lisp-function-pages hb)
                   :title "Loaded functions"
                   :priority 2))

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
It is used for linking to Lisp code."))
                          (:p (views:esc "Use the Loaded functions view to browse the current Lisp image,
or open a page directly by its package-qualified symbol name."))))))
