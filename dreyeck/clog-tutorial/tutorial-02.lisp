;;;; Tutorial 02's existing execution transport. OBSERVATIONS retains its
;;;; original body and paragraphs and records X transitions from output;
;;;; it does not access the lexical cell inside the original closure.

(in-package #:dreyeck/clog-tutorial/reading)

(hyperdoc:see (hyperdoc:page "Tutorial 02 — Closures in CLOG" :hyperbook "dreyeck/clog-tutorial/reading"))

;;; As for Tutorial 01: defining only, no server state, no START-TUTORIAL.
(tut:tutorial-2-handler)

(defun tutorial-2-route ()
  (make-instance 'clog-route :path "/clog-tutorial/02"
                             :handler (tut:tutorial-2-handler)
                             :mounted-by 'tut:install-tutorial-2-route
                             :example 'mount-tutorial-02))

;;; The part of (CLOG:RUN-TUTORIAL 2) that applies in HyperDoc. It changes
;;; the running server, so it has no operation contract: a served Catalog
;;; shows why it is not run, and a development server runs it.
(hyperdoc:defexample mount-tutorial-02
  "Mount Tutorial 02 on the CLOG server this image already runs, and return
its route. No server is started and no browser is opened; the route's
Live page is then a link, followed in the reader's own browser."
  (tut:install-tutorial-2-route)
  (tutorial-2-route))
