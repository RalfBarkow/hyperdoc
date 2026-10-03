;;;; Tutorial 01 where it runs
;;;;
;;;; The page "Tutorial 01 — Hello World" shows one runtime relation:
;;;;
;;;;   tutorial source -> CLOG-TUT-1::ON-NEW-WINDOW -> /clog-tutorial/01 -> live page
;;;;
;;;; Each step is read through the collection's CLOG-ROUTE, defined in
;;;; the collection file because Tutorial 02 showed the same four
;;;; relations.

(in-package #:dreyeck/clog-tutorial/reading)

(hyperdoc:see (hyperdoc:page "Tutorial 01 — Hello World" :hyperbook "dreyeck/clog-tutorial/reading"))

;;; The page links the handler, so it must be defined. Loading Tutorial 1
;;; defines two functions and changes no server state; mounting stays the
;;; explicit step it was.
(tut:tutorial-1-handler)

(defun tutorial-1-route ()
  (make-instance 'clog-route :path "/clog-tutorial/01"
                             :handler (tut:tutorial-1-handler)
                             :mounted-by 'tut:install-tutorial-1-route))
