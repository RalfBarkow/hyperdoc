;;;; CLOG Tutorials 1 and 2, mounted on the CLOG server HyperDoc already runs.
;;;;
;;;; Upstream, a tutorial owns the server: CLOG-TUT-1:START-TUTORIAL calls
;;;; CLOG:INITIALIZE with its own handler, then opens a browser. Inside a
;;;; running HyperDoc image that call is not harmless. CLOG keeps one
;;;; server per image, and INITIALIZE on a running server sets the "/"
;;;; handler and resets *EXTENDED-ROUTING*: the Catalog root would become
;;;; the tutorial, and /<slug>/<page> would stop reaching its HyperBook.
;;;;
;;;; So the tutorial's definitions are loaded and START-TUTORIAL is never
;;;; called. Its window handler is added as one more route, by
;;;; CLOG:SET-ON-NEW-WINDOW with :PATH, the way CLOG Tutorial 12 adds
;;;; pages to a server that is already up.
;;;;
;;;;   running HyperDoc image
;;;;     `-- its CLOG server (started by HYPERBOOK/SERVER:SERVE-HYPERBOOKS)
;;;;           |-- /, /<slug>, /view, /gesture, /inspector ...
;;;;           |-- /clog-tutorial/01 -> CLOG-TUT-1::ON-NEW-WINDOW
;;;;           `-- /clog-tutorial/02 -> CLOG-TUT-2::ON-NEW-WINDOW
;;;;
;;;; Nothing here starts, stops or reconfigures that server.

(defpackage #:dreyeck/clog-tutorial
  (:use #:cl)
  (:export #:tutorial-1-source #:tutorial-1-handler
           #:install-tutorial-1-route
           #:tutorial-2-source #:tutorial-2-handler
           #:install-tutorial-2-route))

(in-package #:dreyeck/clog-tutorial)

(defun tutorial-1-source ()
  "Tutorial 1 as shipped by the CLOG this image loaded, read in place.
CLOG:CLOG-INSTALL-DIR is that system's ASDF source directory, so there
is no second copy and no second version of CLOG."
  (merge-pathnames "tutorial/01-tutorial.lisp" (clog:clog-install-dir)))

(defun tutorial-1-handler ()
  "Return the symbol CLOG-TUT-1::ON-NEW-WINDOW, loading Tutorial 1 the
first time. Loading defines the package and its two functions and
touches no server state; START-TUTORIAL is defined but not called.

A loaded tutorial is not loaded again: a reload would only redefine the
same functions from the same read-only file. The symbol, not the
function, is what gets registered, as the tutorial itself recommends
for development, so a deliberate redefinition still reaches new
windows."
  (let ((package (find-package "CLOG-TUT-1")))
    (unless (and package (fboundp (find-symbol "ON-NEW-WINDOW" package)))
      (load (tutorial-1-source))))
  (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-1"))

(defun install-tutorial-1-route (&key (path "/clog-tutorial/01"))
  "Serve Tutorial 1 at PATH from the CLOG server that is already running.
Starts none: without a running server this signals an error instead of
leaving a route behind for whoever starts one later. Installing again
sets the same handler for the same PATH, which leaves CLOG's routes as
they were."
  (unless (clog:is-running-p)
    (error "CLOG is not running; start HyperDoc's server before mounting ~A."
           path))
  (clog:set-on-new-window (tutorial-1-handler) :path path)
  path)

;;; Tutorial 2 is mounted by the same three steps, read off its source
;;; rather than assumed: a package CLOG-TUT-2 that only defines, an
;;; internal ON-NEW-WINDOW of one BODY argument, and a START-TUTORIAL that
;;; would call CLOG:INITIALIZE and open a browser. The steps are spelled
;;; out again instead of being shared: two tutorials show what they have
;;; in common, not what the rest of CLOG's collection has.

(defun tutorial-2-source ()
  "Tutorial 2 as shipped by the CLOG this image loaded, read in place."
  (merge-pathnames "tutorial/02-tutorial.lisp" (clog:clog-install-dir)))

(defun tutorial-2-handler ()
  "Return the symbol CLOG-TUT-2::ON-NEW-WINDOW, loading Tutorial 2 the
first time. As with Tutorial 1, loading defines and touches no server
state, and START-TUTORIAL is not called."
  (let ((package (find-package "CLOG-TUT-2")))
    (unless (and package (fboundp (find-symbol "ON-NEW-WINDOW" package)))
      (load (tutorial-2-source))))
  (find-symbol "ON-NEW-WINDOW" "CLOG-TUT-2"))

(defun install-tutorial-2-route (&key (path "/clog-tutorial/02"))
  "Serve Tutorial 2 at PATH from the CLOG server that is already running.
Starts none, refuses without one, and installing again changes nothing."
  (unless (clog:is-running-p)
    (error "CLOG is not running; start HyperDoc's server before mounting ~A."
           path))
  (clog:set-on-new-window (tutorial-2-handler) :path path)
  path)
