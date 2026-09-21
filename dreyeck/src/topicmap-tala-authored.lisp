;;;; D2 someone wrote, rendered as what it is.
;;
;; The other half of the layout boundary, and the smaller one. A
;; generated diagram is a projection of a Topicmap and answers to it:
;; every node names a Topic, and the rendering is held to that. Authored
;; D2 answers to nobody. It is text a reader wrote, and the only claim
;; made about it is that this is what the renderer was given.
;;
;;     generated    Topicmap -> keys -> D2 -> TALA -> SVG, validated
;;     authored     text -----------------> TALA -> SVG
;;
;; Both go through RUN-D2-TALA, so there is one place where the tool is
;; invoked and one pinned version to report. They part company at
;; validation, because VALIDATE-TALA-SVG checks a rendering against the
;; projection that produced it, and there is no projection here. Adding
;; identity to authored text would be a different capability with its
;; own contract; this slice deliberately does not have it.
;;
;; The source lives in the page. Not in a Lisp string that the page
;; happens to display: the page's own text is the authoritative payload,
;; and the SVG is derived from it. That is the shape a FedWiki item
;; would have, where the item's text is the diagram and everything else
;; is rendering.

(defpackage #:dreyeck/topicmap/tala/authored
  (:use #:cl)
  (:local-nicknames (#:tala #:dreyeck/topicmap/tala)
                    (#:views #:html-inspector-views))
  (:export #:authored-d2 #:authored-d2-source #:authored-d2-svg
           #:authored-d2-version #:render-authored-d2
           #:page-authored-d2-source
           #:authored-d2-example #:authored-d2-source-example
           #:authored-d2-renderer-status-example))

(in-package #:dreyeck/topicmap/tala/authored)

(hyperdoc:see
  (hyperdoc:page "Writing D2 by Hand"))

(defclass authored-d2 ()
  ((source :reader authored-d2-source :initarg :source)
   (svg :reader authored-d2-svg :initarg :svg)
   (version :reader authored-d2-version :initarg :version))
  (:documentation
   "D2 text and the SVG a pinned renderer made from it.

The source is the object; the SVG is a reading of it. They are kept in
one place so that a picture can always be asked which text it came
from."))

(defmethod print-object ((object authored-d2) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~D characters of D2" (length (authored-d2-source object)))))

(defun render-authored-d2 (source &key (seed 44))
  "Lay SOURCE out with TALA.

No projection, so nothing is validated beyond the renderer accepting the
text: with no Topicmap there is no expectation to hold the SVG to, and
inventing one would only assert that D2 does what D2 does."
  (multiple-value-bind (svg version) (tala:run-d2-tala source :seed seed)
    (make-instance 'authored-d2 :source source :svg svg :version version)))

;;
;; The page is where the text lives
;;

(defparameter +authored-d2-page+ "Writing D2 by Hand")

(defun page-authored-d2-source (&optional (title +authored-d2-page+))
  "Read the D2 written on the page, as text.

The page file is parsed for the block marked as D2 and its characters
are returned unchanged. Nothing here understands D2; it is carried, not
interpreted, which is what makes the page and not this function the
place the diagram is written."
  (let* ((book (hyperbook:find-hyperbook "dreyeck/topicmap/tala/reading"
                                         :signal-error? t))
         (page (hyperbook:find-page book title :signal-error? t))
         (dom (plump:parse (hyperdoc:file-of page)))
         (block (find-if (lambda (node)
                           (equal "d2-source" (plump:attribute node "class")))
                         (plump:get-elements-by-tag-name dom "pre"))))
    (unless block
      (error "The page ~S carries no D2 source block." title))
    (plump:decode-entities (plump:text block))))

;;
;; Reading
;;

(hyperdoc:defexample authored-d2-source-example
  "The D2 written on this page, as text and nothing else."
  (page-authored-d2-source))

(hyperdoc:defexample authored-d2-example
  "The D2 written on this page, laid out by TALA.

Ordinary D2 by an author, with no Topic behind any node and no identity
claimed for one. When the pinned renderer is absent this says so rather
than signalling, because a reading page should report a missing tool and
not fail."
  (let ((dependency (tala:tala-dependency-status)))
    (if (eq :available (getf dependency :status))
        (render-authored-d2 (page-authored-d2-source))
        (list :kind :tala-unavailable
              :source (page-authored-d2-source)
              :dependency dependency
              :remedy "nix develop .#tala"
              :evidence-status :observed))))

(hyperdoc:defexample authored-d2-renderer-status-example
  "Which renderer and which layout engine this runtime would use."
  (tala:tala-dependency-status))

;;
;; Views
;;

(views:defview authored-d2-view (authored authored-d2)
  (views:html-view :title "Authored D2" :priority 1
    (views:html
      (:p (views:esc "The source is the object. The image below is derived from it, and from nothing else: no Topicmap, no identity, no navigation."))
      (:p "D2 " (views:esc (authored-d2-version authored))
          (views:esc " · layout tala · non-interactive"))
      (:h3 "Source")
      (:pre (views:esc (authored-d2-source authored)))
      (:h3 "Rendered")
      (views:str
       (format nil "<img alt='D2 diagram (non-interactive)' style='max-width:100%' src='data:image/svg+xml;base64,~A'>"
               (cl-base64:usb8-array-to-base64-string
                (babel:string-to-octets (authored-d2-svg authored)
                                        :encoding :utf-8)))))))
