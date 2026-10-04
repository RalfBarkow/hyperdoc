;;;; Tutorial 01's existing execution transport. Its Inspector mechanism
;;;; retains the original heading and click closures in OBSERVATIONS.

(in-package #:dreyeck/clog-tutorial/reading)

(hyperdoc:see (hyperdoc:page "Tutorial 01 — Hello World" :hyperbook "dreyeck/clog-tutorial/reading"))

;;; The page links the handler, so it must be defined. Loading Tutorial 1
;;; defines two functions and changes no server state; mounting stays the
;;; explicit step it was.
(tut:tutorial-1-handler)

(defun tutorial-1-route ()
  (make-instance 'clog-route :path "/clog-tutorial/01"
                             :handler (tut:tutorial-1-handler)
                             :mounted-by 'tut:install-tutorial-1-route
                             :example 'mount-tutorial-01))

;;; The part of (CLOG:RUN-TUTORIAL 1) that applies in HyperDoc. It changes
;;; the running server, so it has no operation contract: a served Catalog
;;; shows why it is not run, and a development server runs it.
(hyperdoc:defexample mount-tutorial-01
  "Mount Tutorial 01 on the CLOG server this image already runs, and return
its route. No server is started and no browser is opened; the route's
Live page is then a link, followed in the reader's own browser."
  (tut:install-tutorial-1-route)
  (tutorial-1-route))
