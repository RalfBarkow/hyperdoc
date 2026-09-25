;;;; Working on HyperDoc
(defpackage #:dreyeck/work/reading
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:authored #:dreyeck/topicmap/tala/authored))
  (:export #:work-page #:work-projection #:work-workspace
           #:connections-source #:connections-example #:work-layout-example
           #:project-work-breakdown #:relation-uses
           #:relation-contract-reference-error
           #:work-relationship-source-occurrence #:scan-work-relationships
           #:relationship-occurrence-page #:relationship-occurrence-snapshot
           #:relationship-occurrence-element-range #:relationship-occurrence-start-tag-range
           #:relationship-occurrence-relation-range #:relationship-occurrence-ordinal
           #:relationship-occurrence-from #:relationship-occurrence-relation
           #:relationship-occurrence-to
           #:work-relationship-source-error #:source-error-position #:source-error-reason
           #:resolve-work-relationship-occurrence
           #:stale-work-relationship-occurrence #:stale-relationship-occurrence))
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

;;;; Work relationship source occurrences
;;
;; A projected Association says what a relationship means; it does not say
;; which authored <li> stated it. Two <li>s can state the same from, relation
;; and to. A Work relationship source occurrence names one of them: the exact
;; page source a projection read, the ranges of the <li> in it, and the range
;; of its data-relation value. Those are the address. The ordinal and the
;; recorded from/relation/to are evidence, checked and never used to find an
;; occurrence again. A source that differs at all makes the occurrence stale.
;;
;; The scanner reads the authored Work relationship form and nothing more. It
;; is not an HTML parser; plump is. Both read the same snapshot, and they must
;; agree on every relationship, in order, or the projection is refused.
;;
;; Accepted Work relationship source syntax:
;;   - a relationship is an <li> start tag, tag name in lower case, carrying
;;     data-from, data-to and data-relation, each exactly once, in lower case,
;;     in any order, each value in double quotes with no & in it;
;;   - attributes may be separated by spaces, tabs or line breaks; other
;;     attributes may appear, with double or single quotes or none;
;;   - the <li> is closed by </li> before the next <li>, <ul> or <ol>;
;;     content between may contain other tags;
;;   - elsewhere: comments, end tags, <!...> declarations and start tags whose
;;     quoted values may contain < and >; a < not followed by a letter, /, !
;;     or ? is text.
;; Refused: <script>, <style>, <textarea>, <title> and CDATA anywhere; an
;; unterminated comment, tag or quoted value; and on an <li>, any departure
;; from the relationship form above, including relationship attributes
;; without data-from.

(define-condition work-relationship-source-error (error)
  ((position :initarg :position :reader source-error-position)
   (reason :initarg :reason :reader source-error-reason))
  (:report (lambda (condition stream)
             (format stream "Work relationship source at character ~D: ~A"
                     (source-error-position condition) (source-error-reason condition)))))

(defun %refuse-source (position format-control &rest arguments)
  (error 'work-relationship-source-error
         :position position :reason (apply #'format nil format-control arguments)))

(defclass work-relationship-source-occurrence ()
  ((page :initarg :page :reader relationship-occurrence-page)
   (snapshot :initarg :snapshot :reader relationship-occurrence-snapshot)
   (element-range :initarg :element-range :reader relationship-occurrence-element-range)
   (start-tag-range :initarg :start-tag-range :reader relationship-occurrence-start-tag-range)
   (relation-range :initarg :relation-range :reader relationship-occurrence-relation-range)
   (ordinal :initarg :ordinal :reader relationship-occurrence-ordinal)
   (from :initarg :from :reader relationship-occurrence-from)
   (relation :initarg :relation :reader relationship-occurrence-relation)
   (to :initarg :to :reader relationship-occurrence-to))
  (:documentation "One authored Work relationship <li> in one observed page source.
Ranges are half-open (START . END) character offsets into SNAPSHOT: the
element, its start tag, and the data-relation value between its quotes.
The ordinal and the recorded from/relation/to are evidence, not an address."))

(defmethod print-object ((occurrence work-relationship-source-occurrence) stream)
  (print-unreadable-object (occurrence stream :type t)
    (format stream "~D ~A ~A ~A at ~S" (relationship-occurrence-ordinal occurrence)
            (relationship-occurrence-from occurrence) (relationship-occurrence-relation occurrence)
            (relationship-occurrence-to occurrence) (relationship-occurrence-element-range occurrence))))

(defun %space-p (character) (member character '(#\Space #\Tab #\Newline #\Return #\Page)))

(defun %start-tag (source position)
  "The tag name, attributes (name value start end quote) and end of the start
tag at POSITION."
  (let ((length (length source)) (j (1+ position)) (attributes nil))
    (loop while (and (< j length) (or (alphanumericp (char source j)) (char= #\- (char source j))))
          do (incf j))
    (let ((name (subseq source (1+ position) j)))
      (flet ((skip () (loop while (and (< j length) (%space-p (char source j))) do (incf j))))
        (loop
          (skip)
          (when (>= j length) (%refuse-source position "unterminated start tag"))
          (let ((character (char source j)))
            (cond
              ((char= character #\>) (return (values name (nreverse attributes) (1+ j))))
              ((and (char= character #\/) (< (1+ j) length) (char= #\> (char source (1+ j))))
               (return (values name (nreverse attributes) (+ j 2))))
              (t
               (let ((name-start j))
                 (loop while (and (< j length) (not (%space-p (char source j)))
                                  (not (member (char source j) '(#\= #\> #\" #\' #\< #\/))))
                       do (incf j))
                 (when (= name-start j)
                   (%refuse-source j "unexpected ~S in a start tag" (char source j)))
                 (let ((attribute (subseq source name-start j)) value start end quote (k j))
                   (loop while (and (< k length) (%space-p (char source k))) do (incf k))
                   (when (and (< k length) (char= #\= (char source k)))
                     (setf j (1+ k))
                     (skip)
                     (when (>= j length) (%refuse-source name-start "unterminated attribute"))
                     (let ((opening (char source j)))
                       (if (member opening '(#\" #\'))
                           (let ((closing (position opening source :start (1+ j))))
                             (unless closing (%refuse-source j "unterminated quoted value"))
                             (setf quote opening start (1+ j) end closing
                                   value (subseq source start end) j (1+ closing)))
                           (progn
                             (setf start j)
                             (loop while (and (< j length) (not (%space-p (char source j)))
                                              (char/= #\> (char source j)))
                                   do (incf j))
                             (setf end j value (subseq source start end))))))
                   (push (list attribute value start end quote) attributes)))))))))))

(defparameter +relationship-attributes+ '("data-from" "data-to" "data-relation"))

(defun %relationship-attributes (position attributes)
  "The data-from, data-to and data-relation attribute entries of a
relationship <li>, NIL for any other <li>, or a refusal."
  (let ((present (remove-if-not (lambda (a) (member (first a) +relationship-attributes+
                                                    :test #'string-equal))
                                attributes)))
    (when present
      (dolist (a present)
        (unless (member (first a) +relationship-attributes+ :test #'string=)
          (%refuse-source position "relationship attribute ~S is not in lower case" (first a))))
      (unless (= (length present)
                 (length (remove-duplicates present :key #'first :test #'string=)))
        (%refuse-source position "a relationship attribute appears more than once"))
      (let ((entries (mapcar (lambda (name) (find name present :key #'first :test #'string=))
                             +relationship-attributes+)))
        (unless (every #'identity entries)
          (%refuse-source position "a relationship needs data-from, data-to and data-relation"))
        (dolist (a entries)
          (unless (eql #\" (fifth a))
            (%refuse-source position "~A is not in double quotes" (first a)))
          (when (find #\& (second a))
            (%refuse-source position "~A contains an entity reference" (first a))))
        entries))))

(defun scan-work-relationships (snapshot page)
  "Every authored Work relationship <li> in SNAPSHOT, in source order."
  (dolist (tag '("<script" "<style" "<textarea" "<title" "<![CDATA["))
    (let ((position (search tag snapshot :test #'char-equal)))
      (when position (%refuse-source position "~A is outside the Work relationship syntax" tag))))
  (let ((length (length snapshot)) (i 0) (ordinal 0) (occurrences nil) (open nil))
    (flet ((close-open (end)
             (destructuring-bind (start tag-end relation-range entries) open
               (push (make-instance 'work-relationship-source-occurrence
                                    :page page :snapshot snapshot
                                    :element-range (cons start end)
                                    :start-tag-range (cons start tag-end)
                                    :relation-range relation-range
                                    :ordinal (incf ordinal)
                                    :from (second (first entries))
                                    :to (second (second entries))
                                    :relation (second (third entries)))
                     occurrences)
               (setf open nil))))
      (loop
        (let ((position (position #\< snapshot :start i)))
          (unless position (return))
          (cond
            ((and (<= (+ position 4) length)
                  (string= "<!--" snapshot :start2 position :end2 (+ position 4)))
             (let ((end (search "-->" snapshot :start2 (+ position 4))))
               (unless end (%refuse-source position "unterminated comment"))
               (setf i (+ end 3))))
            ((and (< (1+ position) length) (member (char snapshot (1+ position)) '(#\/ #\! #\?)))
             (let ((end (position #\> snapshot :start position)))
               (unless end (%refuse-source position "unterminated tag"))
               (when (and open (string= "</li" (string-right-trim
                                                 '(#\Space #\Tab #\Newline #\Return)
                                                 (subseq snapshot position end))))
                 (close-open (1+ end)))
               (setf i (1+ end))))
            ((and (< (1+ position) length) (alpha-char-p (char snapshot (1+ position))))
             (multiple-value-bind (name attributes end) (%start-tag snapshot position)
               (when (member name '("li" "ul" "ol") :test #'string-equal)
                 (when open
                   (%refuse-source (first open) "relationship <li> is not closed by </li> before ~A"
                                   (format nil "<~A>" name)))
                 (when (string= name "li")
                   (let ((entries (%relationship-attributes position attributes)))
                     (when entries
                       (setf open (list position end
                                        (cons (third (third entries)) (fourth (third entries)))
                                        entries))))))
               (setf i end)))
            (t (setf i (1+ position))))))
      (when open (%refuse-source (first open) "relationship <li> is not closed by </li>")))
    (nreverse occurrences)))

(defun %align-relationships (occurrences nodes snapshot)
  "Refuse unless the scanned OCCURRENCES and plump's relationship NODES agree,
ordinal by ordinal. Nothing is skipped, searched for or reordered."
  (unless (= (length occurrences) (length nodes))
    (%refuse-source (length snapshot) "~D relationship <li>s in the source, ~D in the parsed page"
                    (length occurrences) (length nodes)))
  (loop for occurrence in occurrences for node in nodes
        for parsed = (list (plump:attribute node "data-from") (plump:attribute node "data-relation")
                           (plump:attribute node "data-to"))
        unless (equal parsed (list (relationship-occurrence-from occurrence)
                                   (relationship-occurrence-relation occurrence)
                                   (relationship-occurrence-to occurrence)))
          do (%refuse-source (car (relationship-occurrence-element-range occurrence))
                             "relationship ~D reads ~S in the source but ~S when parsed"
                             (relationship-occurrence-ordinal occurrence)
                             (list (relationship-occurrence-from occurrence)
                                   (relationship-occurrence-relation occurrence)
                                   (relationship-occurrence-to occurrence))
                             parsed)))

(define-condition stale-work-relationship-occurrence (error)
  ((occurrence :initarg :occurrence :reader stale-relationship-occurrence)
   (reason :initarg :reason :reader stale-relationship-reason))
  (:report (lambda (condition stream)
             (format stream "Stale Work relationship occurrence ~A: ~A. Observe Work Breakdown again."
                     (stale-relationship-occurrence condition)
                     (stale-relationship-reason condition)))))

(defun resolve-work-relationship-occurrence
    (occurrence &key (current (uiop:read-file-string
                               (hyperdoc:file-of (relationship-occurrence-page occurrence)))))
  "OCCURRENCE, if CURRENT -- by default the page's source now -- is exactly its
snapshot and its ranges still denote the recorded relationship. Otherwise
STALE-WORK-RELATIONSHIP-OCCURRENCE. Nothing is relocated."
  (flet ((stale (reason) (error 'stale-work-relationship-occurrence
                                :occurrence occurrence :reason reason)))
    (unless (string= current (relationship-occurrence-snapshot occurrence))
      (stale "the page source is not the recorded snapshot"))
    (let* ((element (relationship-occurrence-element-range occurrence))
           (tag (relationship-occurrence-start-tag-range occurrence))
           (relation (relationship-occurrence-relation-range occurrence))
           (here (find (car element) (scan-work-relationships current (relationship-occurrence-page occurrence))
                       :key (lambda (o) (car (relationship-occurrence-element-range o))))))
      (unless (and here
                   (equal element (relationship-occurrence-element-range here))
                   (equal tag (relationship-occurrence-start-tag-range here))
                   (equal relation (relationship-occurrence-relation-range here))
                   (<= (car tag) (car relation) (cdr relation) (cdr tag) (cdr element))
                   (string= (relationship-occurrence-relation occurrence) current
                            :start2 (car relation) :end2 (cdr relation))
                   (equal (list (relationship-occurrence-from here) (relationship-occurrence-relation here)
                                (relationship-occurrence-to here))
                          (list (relationship-occurrence-from occurrence)
                                (relationship-occurrence-relation occurrence)
                                (relationship-occurrence-to occurrence))))
        (stale "its ranges no longer denote the recorded relationship"))
      occurrence)))

(defun project-work-breakdown (html &key source areas-only
                                         (find-page #'work-page))
  "Project Work Breakdown HTML (a pathname, read once, or a string). FIND-PAGE
maps a page title and HyperBook ID to the Topic's object. The one source
string is parsed, scanned for relationship occurrences and kept by each."
  (let* ((snapshot (if (stringp html) html (uiop:read-file-string html)))
         ;; EXPR evaluation can inherit printer-only page tag dispatchers.
         ;; Read the authored anchors with the HTML parser, independently of that context.
         (dom (let ((plump:*tag-dispatchers* plump:*html-tags*))
                (plump:parse snapshot)))
         (relationship-nodes (remove-if-not (lambda (node) (plump:attribute node "data-from"))
                                            (plump:get-elements-by-tag-name dom "li")))
         (occurrences (let ((occurrences (scan-work-relationships snapshot source)))
                        (%align-relationships occurrences relationship-nodes snapshot)
                        occurrences))
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
           (loop for node in relationship-nodes
                 for occurrence in occurrences
                 for from = (plump:attribute node "data-from")
                 for to = (plump:attribute node "data-to")
                 for relation = (plump:attribute node "data-relation")
                 for id = (format nil "work:~A:~A:~A" from relation to)
                 when (and from (or (not areas-only)
                                    (and (member from ids :test #'equal)
                                         (member to ids :test #'equal))))
                 collect (tm:make-topicmap-association
                          :id id :type relation :from from :to to
                          ;; Derived while projecting, and part of no identity.
                          ;; The reference in TYPE is the authored statement and
                          ;; the contract Topic owns the label; the occurrence
                          ;; says which authored <li> this Association came from.
                          :properties
                          (list* :source-occurrence occurrence
                                 (when (relation-contract-reference-p relation)
                                   (list :relation-contract
                                         (resolve-relation-contract relation all-topics id))))))))
    (tm:make-topicmap-projection :source source :topics topics
                                 :associations associations)))

;; These are ordinary page links and relationship entries in Work Breakdown.
;; Reading this one page avoids a second authoritative WBS list in Lisp or D2.
(defun work-projection (&key areas-only)
  (let ((page (work-page "Work Breakdown")))
    (project-work-breakdown (uiop:read-file-string (hyperdoc:file-of page))
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
