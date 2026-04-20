;;;; Lisp classes as a HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; The "Lisp Classes" hyperbook
;;

(defclass lisp-classes (hyperbook) ())

(defvar *lisp-classes* (make-instance 'lisp-classes :id "lisp-classes"))

(defmethod title-of ((hb lisp-classes))
  "Lisp Classes")

(eval-when (:load-toplevel)
  (register *lisp-classes*))

;;
;; Pages for Lisp classes
;;

(defclass lisp-class-page (page)
  ((class :reader class-object-of :initarg :class :type class)))

(defun make-lisp-class-page (hb page-id class)
  (make-instance 'lisp-class-page
                 :hyperbook hb
                 :id page-id
                 :class class))

(defun make-lisp-class-lookup-issue (hb page-id symbol condition)
  (make-page-lookup-issue
   condition
   :source-object hb
   :source-hyperbook (id-of hb)
   :source-page-title (title-of hb)
   :link-text page-id
   :target-hyperbook-id (id-of hb)
   :expected-page-id page-id
   :target-kind :lisp-class-page
   :classification :missing-lisp-class-definition
   :details (list :lookup-stage :find-class
                  :expected-symbol symbol
                  :classp (not (null (find-class symbol nil)))
                  :condition-type (type-of condition))))

(defun lisp-class-definition (symbol)
  (find-class symbol nil))

(defun collect-lisp-class-pages (hb)
  (let (pages)
    (dolist (package (sort (copy-list (list-all-packages))
                           #'string<
                           :key #'package-name))
      (do-symbols (symbol package)
        (when (and (eq (symbol-package symbol) package)
                   (lisp-class-definition symbol))
          (when-let ((page-id (package-qualified-symbol-name symbol))
                     (class (lisp-class-definition symbol)))
            (push (make-lisp-class-page hb page-id class)
                  pages)))))
    (sort pages #'string< :key #'id-of)))

(defmethod find-page ((hb lisp-classes) page-id &key signal-error?)
  (let ((symbol (read-symbol page-id signal-error?)))
    (when symbol
      (if-let ((class (lisp-class-definition symbol)))
        (make-lisp-class-page hb page-id class)
        (and signal-error?
             (handler-case
                 (find-class symbol)
               (error (condition)
                 (make-lisp-class-lookup-issue hb page-id symbol condition))))))))

(defmethod dom-of ((page lisp-class-page))
  (plump:make-root))

(views:defview 👀class-views (page lisp-class-page)
  (views:specific-views (class-object-of page)))

(views:defview 👀loaded-classes (hb lisp-classes)
  (views:list-view (collect-lisp-class-pages hb)
                   :title "Loaded classes"
                   :priority 2))

;;
;; Add an explanatory page
;;

(views:defview 👀overview (hb lisp-classes)
  (declare (ignore hb))
  (views:html-view :title "Overview" :priority 1
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:html
      (:div :class "hyperbook-page"
            (:h1 (views:esc "Lisp classes"))
            (:p (views:esc "This hyperbook contains one page for each symbol
in the Lisp image that has a class definition attached to it.
It is used for linking to Lisp code."))
            (:p (views:esc "Use the Loaded classes view to browse the current Lisp image,
or open a page directly by its package-qualified class name."))))))
