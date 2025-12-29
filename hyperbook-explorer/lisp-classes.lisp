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
  ((class :initarg :class :type class)))

(defmethod find-page ((hb lisp-classes) page-id &key signal-error?)
  (make-instance 'lisp-class-page
                 :hyperbook hb
                 :id page-id
                 :class (find-class (read-symbol page-id signal-error?))))

(defmethod dom-of ((page lisp-class-page))
  (plump:make-root))

(views:defview 👀class-views (page lisp-class-page)
  (views:specific-views (slot-value page 'class)))

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
It is used for linking to Lisp code."))))))
