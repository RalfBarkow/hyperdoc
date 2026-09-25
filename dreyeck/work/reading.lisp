;;;; Working on HyperDoc
(defpackage #:dreyeck/work/reading
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:authored #:dreyeck/topicmap/tala/authored))
  (:export #:work-page #:work-projection #:work-workspace
           #:connections-source #:connections-example #:work-layout-example
           #:project-work-breakdown #:relation-uses
           #:relation-contract-reference-error))
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

;;;; Relation Contracts
;;
;; A relation written "work:relation/..." is a reference, not a label. It names
;; one ordinary Topic of kind "relation" in Work Breakdown: that Topic's ID is
;; the contract's identity, its label is what readers see, and the page it
;; links to states the contract's meaning. The page title identifies only the
;; page. Other relations are still plain strings and mean only what they say.
;;
;; Whether retyping an Association replaces it or changes one stable
;; Association is open. The ID below still spells the relation, so a retyped
;; Association gets a new ID; nothing here depends on that being right.

(defparameter +relation-contract-prefix+ "work:relation/")

(defun relation-contract-reference-p (relation)
  (and (stringp relation)
       (eql 0 (search +relation-contract-prefix+ relation))))

(define-condition relation-contract-reference-error (error)
  ((association-id :initarg :association-id :reader association-id-of)
   (reference :initarg :reference :reader reference-of)
   (matches :initarg :matches :reader matches-of))
  (:report
   (lambda (condition stream)
     (format stream "Work Association ~S refers to relation contract ~S, ~
which names ~D Topic~:P~@[ of kind~{ ~S~^,~}~]; exactly one Topic of kind ~
\"relation\" is required."
             (association-id-of condition) (reference-of condition)
             (length (matches-of condition))
             (mapcar (lambda (topic)
                       (getf (tm:topicmap-topic-view-properties-of topic) :kind))
                     (matches-of condition))))))

(defun resolve-relation-contract (reference topics association-id)
  "The one Relation Contract Topic among TOPICS whose ID is REFERENCE, or an error."
  (let ((matches (remove reference topics :key #'tm:topicmap-topic-id-of
                                          :test-not #'equal)))
    (unless (and (= 1 (length matches))
                 (equal "relation" (getf (tm:topicmap-topic-view-properties-of
                                          (first matches))
                                         :kind)))
      (error 'relation-contract-reference-error
             :association-id association-id :reference reference
             :matches matches))
    (first matches)))

(defun relation-uses (projection reference)
  "The Associations of PROJECTION whose relation is REFERENCE, each kept distinct."
  (remove-if-not (lambda (association)
                   (equal reference (tm:topicmap-association-type-of association)))
                 (tm:topicmap-projection-associations-of projection)))

(defun project-work-breakdown (html &key source areas-only
                                         (find-page #'work-page))
  "Project Work Breakdown HTML (a pathname or a string). FIND-PAGE maps a page
title and HyperBook ID to the Topic's object."
  (let* (;; EXPR evaluation can inherit printer-only page tag dispatchers.
         ;; Read the authored anchors with the HTML parser, independently of that context.
         (dom (let ((plump:*tag-dispatchers* plump:*html-tags*))
                (plump:parse html)))
         ;; Every authored Topic, including those AREAS-ONLY leaves out, so a
         ;; contract reference is checked against the whole page either way.
         (all-topics
           (loop for node in (remove-if-not
                              (lambda (node) (plump:attribute node "data-topic"))
                              (plump:get-elements-by-tag-name dom "a"))
                 for index from 0
                 collect
                 (tm:make-topicmap-topic
                  :id (plump:attribute node "data-topic") :type :work-page
                  :label (plump:decode-entities (plump:text node))
                  :object (funcall find-page (plump:attribute node "page")
                                   (or (plump:attribute node "hyperbook")
                                       "dreyeck/work/reading"))
                  :view-properties
                  (list :x (* 285 (mod index 4)) :y (* 120 (floor index 4))
                        :visible t :kind (plump:attribute node "data-kind")
                        :status (plump:attribute node "data-status")))))
         (topics (if areas-only
                     (remove "area" all-topics
                             :key (lambda (topic)
                                    (getf (tm:topicmap-topic-view-properties-of topic)
                                          :kind))
                             :test-not #'equal)
                     all-topics))
         (ids (mapcar #'tm:topicmap-topic-id-of topics))
         (associations
           (loop for node in (plump:get-elements-by-tag-name dom "li")
                 for from = (plump:attribute node "data-from")
                 for to = (plump:attribute node "data-to")
                 for relation = (plump:attribute node "data-relation")
                 for id = (format nil "work:~A:~A:~A" from relation to)
                 when (and from (or (not areas-only)
                                    (and (member from ids :test #'equal)
                                         (member to ids :test #'equal))))
                 collect (tm:make-topicmap-association
                          :id id :type relation :from from :to to
                          ;; Derived while projecting, for presentation only.
                          ;; The reference in TYPE is the authored statement and
                          ;; the contract Topic owns the label.
                          :properties
                          (when (relation-contract-reference-p relation)
                            (list :relation-contract
                                  (resolve-relation-contract relation all-topics id)))))))
    (tm:make-topicmap-projection :source source :topics topics
                                 :associations associations)))

;; These are ordinary page links and relationship entries in Work Breakdown.
;; Reading this one page avoids a second authoritative WBS list in Lisp or D2.
(defun work-projection (&key areas-only)
  (let ((page (work-page "Work Breakdown")))
    (project-work-breakdown (hyperdoc:file-of page)
                            :source page :areas-only areas-only)))

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
