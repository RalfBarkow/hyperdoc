;;;; Working on HyperDoc
(defpackage #:dreyeck/work/reading
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:authored #:dreyeck/topicmap/tala/authored))
  (:export #:work-page #:work-projection #:work-workspace
           #:connections-source #:connections-example #:work-layout-example))
(in-package #:dreyeck/work/reading)

(hyperdoc:see (hyperdoc:page "D2 Connections"))

(defun work-page (title &optional (book-id "dreyeck/work/reading"))
  (hyperbook:find-page (hyperbook:find-hyperbook book-id :signal-error? t)
                       title :signal-error? t))

(defun connections-source ()
  "The original D2 block on the Text Page is the sole authored source."
  (let* ((dom (plump:parse (hyperdoc:file-of (work-page "D2 Connections"))))
         (block (find "d2-source" (plump:get-elements-by-tag-name dom "pre")
                      :key (lambda (node) (plump:attribute node "class"))
                      :test #'equal)))
    (unless block (error "D2 Connections has no D2 source block."))
    (plump:decode-entities (plump:text block))))

(hyperdoc:defexample connections-example
  "Render the page's one Connections example; inspect source, SVG and version."
  (let ((dependency (tala:tala-dependency-status)))
    (if (eq :available (getf dependency :status))
        (authored:render-authored-d2 (connections-source))
        (list :status :unavailable :source (connections-source)
              :dependency dependency :remedy "nix develop .#tala"))))

;; These are ordinary page links and relationship entries in Work Breakdown.
;; Reading this one page avoids a second authoritative WBS list in Lisp or D2.
(defun work-projection (&key areas-only)
  (let* ((page (work-page "Work Breakdown"))
         ;; EXPR evaluation can inherit printer-only page tag dispatchers.
         ;; Read the authored anchors with the HTML parser, independently of that context.
         (dom (let ((plump:*tag-dispatchers* plump:*html-tags*))
                (plump:parse (hyperdoc:file-of page))))
         (links (remove-if-not
                 (lambda (node)
                   (and (plump:attribute node "data-topic")
                        (or (not areas-only)
                            (equal "area" (plump:attribute node "data-kind")))))
                 (plump:get-elements-by-tag-name dom "a")))
         (topics
           (loop for node in links for index from 0
                 collect
                 (tm:make-topicmap-topic
                  :id (plump:attribute node "data-topic") :type :work-page
                  :label (plump:decode-entities (plump:text node))
                  :object (work-page (plump:attribute node "page")
                                    (or (plump:attribute node "hyperbook")
                                        "dreyeck/work/reading"))
                  :view-properties
                  (list :x (* 285 (mod index 4)) :y (* 120 (floor index 4))
                        :visible t :kind (plump:attribute node "data-kind")
                        :status (plump:attribute node "data-status")))))
         (ids (mapcar #'tm:topicmap-topic-id-of topics))
         (associations
           (loop for node in (plump:get-elements-by-tag-name dom "li")
                 for from = (plump:attribute node "data-from")
                 for to = (plump:attribute node "data-to")
                 when (and from (or (not areas-only)
                                    (and (member from ids :test #'equal)
                                         (member to ids :test #'equal))))
                 collect (tm:make-topicmap-association
                          :id (format nil "work:~A:~A:~A" from
                                      (plump:attribute node "data-relation") to)
                          :type (plump:attribute node "data-relation")
                          :from from :to to))))
    (tm:make-topicmap-projection :source page :topics topics
                                 :associations associations)))

(hyperdoc:defexample work-workspace
  "Navigate the documented work and its concepts with native Workspace actions."
  (tm:make-topicmap-workspace (work-projection) "connections-example"))

(hyperdoc:defexample work-layout-example
  "A derived seven-area D2 projection; the page remains authoritative."
  (let* ((input (tala:projection-tala-input (work-projection :areas-only t)))
         (dependency (tala:tala-dependency-status)))
    (if (eq :available (getf dependency :status))
        (tala:run-tala input)
        (list :status :unavailable :input input :dependency dependency
              :remedy "nix develop .#tala"))))

(hyperdoc:defhyperdoc *work-reading*
  :id "dreyeck/work/reading" :title "Working on HyperDoc"
  :asdf-system-name "dreyeck/work/reading"
  :subdirectory "dreyeck/pages/work" :code-subdirectory "dreyeck/work"
  :main-page-id "Work Breakdown")
