;;;; Reading the CLOG Tutorial collection
;;;;
;;;; The book is the collection of tutorials CLOG ships with its source,
;;;; not any one of them. A tutorial is one item of it, read from CLOG's
;;;; own files; a route such as /clog-tutorial/01 is one running
;;;; projection of a tutorial on the server this image serves.
;;;;
;;;; Each tutorial in the book is a page and, where it needs one, a file
;;;; of its own next to this one. Adding a tutorial adds those and an
;;;; entry on the Overview; it does not change the book.
;;;;
;;;; What two tutorials were shown to share is here: a CLOG-ROUTE, read
;;;; from CLOG's table, with its source, handler, state and live page.
;;;; Tutorials 01 and 02 each have exactly these four relations. That a
;;;; route is not an instance holds for both as well: CLOG runs the
;;;; handler once per browser window that opens it, so each window has
;;;; its own elements and state. Nothing further is assumed of the rest
;;;; of CLOG's collection.

(defpackage #:dreyeck/clog-tutorial/reading
  (:use #:cl)
  (:local-nicknames (#:hv #:html-inspector-views)
                    (#:tut #:dreyeck/clog-tutorial))
  (:export #:clog-route #:route-path #:route-handler #:route-mounted-by
           #:route-state #:route-source #:route-relation
           #:tutorial-1-route #:tutorial-2-route))

(in-package #:dreyeck/clog-tutorial/reading)

(dreyeck/hyperdoc:defhyperdoc *clog-tutorial-reading*
  :id "dreyeck/clog-tutorial/reading" :title "CLOG Tutorial"
  :asdf-system-name "dreyeck/clog-tutorial/reading"
  :subdirectory "dreyeck/pages/clog-tutorial" :code-subdirectory "dreyeck/clog-tutorial"
  :main-page-id "Overview")

(hyperdoc:see (hyperdoc:page "Overview" :hyperbook "dreyeck/clog-tutorial/reading"))

;;; A CLOG-ROUTE is a path, the handler meant for it and the function
;;; that mounts it. Nothing about it is restated: whether CLOG dispatches
;;; the path to the handler is read from CLOG's own table each time the
;;; route is looked at, and the source is where the image says the
;;; handler was defined. The live page is reached the way HyperDoc
;;; already reaches a route on the server being read: the URL view of
;;; HYPERBOOK/SERVER sends the path, and the reader's browser puts its
;;; own origin in front of it. No host or port is known on the server
;;; side, and nothing is opened there.

(defclass clog-route ()
  ((path :initarg :path :reader route-path)
   (handler :initarg :handler :reader route-handler)
   (mounted-by :initarg :mounted-by :reader route-mounted-by))
  (:documentation "A path on the CLOG server of this image, the handler meant
for it, and the function that mounts it there. Whether it is mounted is
not stored: see ROUTE-STATE."))

(defmethod print-object ((route clog-route) stream)
  (print-unreadable-object (route stream :type t)
    (format stream "~A" (route-path route))))

(defun route-state (route)
  "Read from the table CLOG chooses window handlers from: :MOUNTED when it
holds ROUTE's handler at ROUTE's path, :OTHER-HANDLER when it holds
something else there, :NOT-MOUNTED when it holds nothing."
  (let ((dispatched (gethash (route-path route) clog::*url-to-on-new-window*)))
    (cond ((null dispatched) :not-mounted)
          ((eq dispatched (route-handler route)) :mounted)
          (t :other-handler))))

(defun route-source (route)
  "The file the image says ROUTE's handler was defined from."
  (sb-introspect:definition-source-pathname
   (sb-introspect:find-definition-source (fdefinition (route-handler route)))))

(defun %slug (route)
  (string-left-trim "/" (route-path route)))

(defun %mount-form (route)
  "The form a reader evaluates to mount ROUTE, as text."
  (let ((mount (route-mounted-by route)))
    (format nil "(~(~A:~A~))" (package-name (symbol-package mount)) (symbol-name mount))))

(hv:defview hyperbook/server::👀url (route clog-route)
  (when (eq :mounted (route-state route))
    (hyperbook/server::url-view-from-slug (%slug route))))

(hv:defview route-relation (route clog-route)
  (hv:html-view :title "Route" :priority 0
    (let ((handler (route-handler route))
          (state (route-state route)))
      (hv:html
        (:table :class "clog-route"
          (:tr (:th :style "text-align:left" "Tutorial source")
               (:td (:code (hv:esc (namestring (route-source route))))))
          (:tr (:th :style "text-align:left" "Handler")
               (:td (hv:object-ref (fdefinition handler)
                                   :display (prin1-to-string handler)
                                   :select "Source code")))
          (:tr (:th :style "text-align:left" "Route")
               (:td (:code (hv:esc (route-path route)))
                    (hv:esc (ecase state
                              (:mounted " — CLOG dispatches it to this handler.")
                              (:not-mounted " — not mounted on this server.")
                              (:other-handler " — CLOG dispatches it to another handler: ")))
                    (when (eq state :other-handler)
                      (hv:object-ref (gethash (route-path route)
                                              clog::*url-to-on-new-window*)))
                    (:br)
                    (hv:esc "Mounted by ")
                    (hv:object-ref (fdefinition (route-mounted-by route))
                                   :display (symbol-name (route-mounted-by route))
                                   :select "Source code")
                    (hv:esc ", which starts no server.")))
          (:tr (:th :style "text-align:left" "Live page")
               (:td (if (eq state :mounted)
                        (hv:transclusion (hyperbook/server::👀url route))
                        (hv:html
                          (hv:esc "None until mounted: evaluate ")
                          (:code (hv:esc (%mount-form route)))
                          (hv:esc " in this image."))))))))))
