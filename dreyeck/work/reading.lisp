;;;; Working on HyperDoc
(defpackage #:dreyeck/work/reading
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:authored #:dreyeck/topicmap/tala/authored)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:views #:html-inspector-views))
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
           #:stale-work-relationship-occurrence #:stale-relationship-occurrence
           #:work-topic #:topic-source-occurrence
           #:work-topic-source-occurrence #:scan-work-topics
           #:topic-occurrence-page #:topic-occurrence-snapshot
           #:topic-occurrence-element-range #:topic-occurrence-start-tag-range
           #:topic-occurrence-topic-range #:topic-occurrence-ordinal #:topic-occurrence-topic
           #:work-topic-source-error #:resolve-work-topic-occurrence
           #:stale-work-topic-occurrence #:stale-topic-occurrence
           #:duplicate-work-topic-declaration #:duplicate-declaration-topic
           #:duplicate-declaration-occurrences
           #:relation-change-request #:request-relation-change
           #:relation-change-operation #:relation-change-association
           #:relation-change-occurrence #:relation-change-observed-relation
           #:relation-change-observed-contract #:relation-change-proposed-contract
           #:relation-change-proposed-relation
           #:relation-change-refused #:relation-change-refused-reason
           #:relation-change-refused-cause
           #:work-status-change-request #:request-work-status-change #:work-status-change-selection
           #:work-status-change-operation #:work-status-change-topic
           #:work-status-change-occurrence #:work-status-change-observed-status
           #:work-status-change-proposed-status
           #:work-status-change-refused #:refused-work-status-change-topic
           #:work-status-change-refused-reason #:work-status-change-refused-cause
           #:work-relationship-creation-request #:request-work-relationship-creation
           #:work-relationship-creation-operation #:work-relationship-creation-selection
           #:work-relationship-creation-from-occurrence #:work-relationship-creation-to-occurrence
           #:work-relationship-creation-relation #:work-relationship-creation-authority-page
           #:work-relationship-creation-authority-snapshot
           #:work-relationship-creation-refused #:work-relationship-creation-refused-reason
           #:work-relationship-creation-refused-cause
           #:work-fedwiki-item-observation #:observe-work-fedwiki-item
           #:fedwiki-item-observation-site #:fedwiki-item-observation-slug
           #:fedwiki-item-observation-item-id #:fedwiki-item-observation-item
           #:resolve-work-fedwiki-item-observation #:project-fedwiki-work))
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

(defparameter *source-error* 'work-relationship-source-error
  "The condition a Work source refusal signals, named for the authored form
being read.")

(defun %refuse-source (position format-control &rest arguments)
  (error *source-error*
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

(defun %scan-tags (snapshot start-tag end-tag)
  "Read SNAPSHOT's markup in source order, calling START-TAG with the position,
name, attributes and end of each start tag, and END-TAG with the positions of
the < and > of each end tag. Comments and declarations are passed over; what
no Work source accepts is refused."
  (dolist (tag '("<script" "<style" "<textarea" "<title" "<![CDATA["))
    (let ((position (search tag snapshot :test #'char-equal)))
      (when position (%refuse-source position "~A is outside the Work source syntax" tag))))
  (let ((length (length snapshot)) (i 0))
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
             (when (char= #\/ (char snapshot (1+ position)))
               (funcall end-tag position end))
             (setf i (1+ end))))
          ((and (< (1+ position) length) (alpha-char-p (char snapshot (1+ position))))
           (multiple-value-bind (name attributes end) (%start-tag snapshot position)
             (funcall start-tag position name attributes end)
             (setf i end)))
          (t (setf i (1+ position))))))))

(defun %end-tag-p (snapshot position end name)
  "Whether the end tag from POSITION to END closes NAME."
  (string= (format nil "</~A" name)
           (string-right-trim '(#\Space #\Tab #\Newline #\Return) (subseq snapshot position end))))

(defun scan-work-relationships (snapshot page)
  "Every authored Work relationship <li> in SNAPSHOT, in source order."
  (let ((ordinal 0) (occurrences nil) (open nil))
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
      (%scan-tags snapshot
                  (lambda (position name attributes end)
                    (when (member name '("li" "ul" "ol") :test #'string-equal)
                      (when open
                        (%refuse-source (first open) "relationship <li> is not closed by </li> before ~A"
                                        (format nil "<~A>" name)))
                      (when (string= name "li")
                        (let ((entries (%relationship-attributes position attributes)))
                          (when entries
                            (setf open (list position end
                                             (cons (third (third entries)) (fourth (third entries)))
                                             entries)))))))
                  (lambda (position end)
                    (when (and open (%end-tag-p snapshot position end "li"))
                      (close-open (1+ end)))))
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

;;;; Work Topic source occurrences
;;
;; A projected Work Topic says what a Topic is; it does not say which
;; authored <a data-topic> declared it. Four things stay apart: the Topic ID;
;; the declaration, on the page being projected; the carrier page the
;; declaration names in page=, which is the Topic's object; and any passage
;; on the carrier that explains the Topic, which nothing here models. A Work
;; Topic source occurrence names one declaration: the exact page source a
;; projection read, the ranges of the <a> in it, and the range of its
;; data-topic value. Those are the address. The ordinal and the recorded
;; Topic ID are evidence, checked and never used to find a declaration
;; again; label and carrier are read from the same bytes. A source that
;; differs at all makes the occurrence stale.
;;
;; One Topic ID names one Topic in a projection, since Associations name
;; their endpoints by it. Two declarations of one ID are therefore refused,
;; naming both occurrences, rather than projected as two Topics.
;;
;; Accepted Work Topic declaration syntax, within the Work source syntax
;; above:
;;   - a declaration is an <a> start tag, tag name in lower case, carrying
;;     data-topic exactly once, in lower case, its value in double quotes
;;     with no & in it;
;;   - it is closed by </a> before the next <a>; content between may
;;     contain other tags.

(define-condition work-topic-source-error (error)
  ((position :initarg :position :reader source-error-position)
   (reason :initarg :reason :reader source-error-reason))
  (:report (lambda (condition stream)
             (format stream "Work Topic declaration source at character ~D: ~A"
                     (source-error-position condition) (source-error-reason condition)))))

(defclass work-topic-source-occurrence ()
  ((page :initarg :page :reader topic-occurrence-page)
   (snapshot :initarg :snapshot :reader topic-occurrence-snapshot)
   (element-range :initarg :element-range :reader topic-occurrence-element-range)
   (start-tag-range :initarg :start-tag-range :reader topic-occurrence-start-tag-range)
   (topic-range :initarg :topic-range :reader topic-occurrence-topic-range)
   (ordinal :initarg :ordinal :reader topic-occurrence-ordinal)
   (topic :initarg :topic :reader topic-occurrence-topic))
  (:documentation "One authored Work Topic declaration <a> in one observed page
source. PAGE is the page the declaration is on, not the carrier page it
names. Ranges are half-open (START . END) character offsets into SNAPSHOT:
the element, its start tag, and the data-topic value between its quotes.
The ordinal and the recorded Topic ID are evidence, not an address."))

(defmethod print-object ((occurrence work-topic-source-occurrence) stream)
  (print-unreadable-object (occurrence stream :type t)
    (format stream "~D ~A at ~S" (topic-occurrence-ordinal occurrence)
            (topic-occurrence-topic occurrence) (topic-occurrence-element-range occurrence))))

(defun %topic-attribute (position attributes)
  "The data-topic attribute entry of a declaring <a>, NIL for any other <a>,
or a refusal."
  (let ((present (remove "data-topic" attributes :key #'first :test-not #'string-equal)))
    (when present
      (dolist (a present)
        (unless (string= "data-topic" (first a))
          (%refuse-source position "Topic attribute ~S is not in lower case" (first a))))
      (when (rest present)
        (%refuse-source position "data-topic appears more than once"))
      (let ((entry (first present)))
        (unless (eql #\" (fifth entry))
          (%refuse-source position "data-topic is not in double quotes"))
        (when (find #\& (second entry))
          (%refuse-source position "data-topic contains an entity reference"))
        entry))))

(defun scan-work-topics (snapshot page)
  "Every authored Work Topic declaration <a> in SNAPSHOT, in source order."
  (let ((*source-error* 'work-topic-source-error) (ordinal 0) (occurrences nil) (open nil))
    (%scan-tags snapshot
                (lambda (position name attributes end)
                  (when (string-equal name "a")
                    (when open
                      (%refuse-source (first open) "Topic declaration <a> is not closed by </a> before <a>"))
                    (when (string= name "a")
                      (let ((entry (%topic-attribute position attributes)))
                        (when entry
                          (setf open (list position end (cons (third entry) (fourth entry))
                                           (second entry))))))))
                (lambda (position end)
                  (when (and open (%end-tag-p snapshot position end "a"))
                    (destructuring-bind (start tag-end topic-range topic) open
                      (push (make-instance 'work-topic-source-occurrence
                                           :page page :snapshot snapshot
                                           :element-range (cons start (1+ end))
                                           :start-tag-range (cons start tag-end)
                                           :topic-range topic-range
                                           :ordinal (incf ordinal) :topic topic)
                            occurrences))
                    (setf open nil))))
    (when open (%refuse-source (first open) "Topic declaration <a> is not closed by </a>"))
    (nreverse occurrences)))

(defun %align-topics (occurrences nodes snapshot)
  "Refuse unless the scanned OCCURRENCES and plump's declaring NODES agree,
ordinal by ordinal. Nothing is skipped, searched for or reordered."
  (let ((*source-error* 'work-topic-source-error))
    (unless (= (length occurrences) (length nodes))
      (%refuse-source (length snapshot) "~D Topic declarations in the source, ~D in the parsed page"
                      (length occurrences) (length nodes)))
    (loop for occurrence in occurrences for node in nodes
          for parsed = (plump:attribute node "data-topic")
          unless (equal parsed (topic-occurrence-topic occurrence))
            do (%refuse-source (car (topic-occurrence-element-range occurrence))
                               "Topic declaration ~D reads ~S in the source but ~S when parsed"
                               (topic-occurrence-ordinal occurrence)
                               (topic-occurrence-topic occurrence) parsed))))

(define-condition stale-work-topic-occurrence (error)
  ((occurrence :initarg :occurrence :reader stale-topic-occurrence)
   (reason :initarg :reason :reader stale-topic-reason))
  (:report (lambda (condition stream)
             (format stream "Stale Work Topic occurrence ~A: ~A. Observe its page again."
                     (stale-topic-occurrence condition)
                     (stale-topic-reason condition)))))

(defun resolve-work-topic-occurrence
    (occurrence &key (current (uiop:read-file-string
                               (hyperdoc:file-of (topic-occurrence-page occurrence)))))
  "OCCURRENCE, if CURRENT -- by default the declaring page's source now -- is
exactly its snapshot and its ranges still denote the recorded declaration.
Otherwise STALE-WORK-TOPIC-OCCURRENCE. Nothing is relocated, by Topic ID or
otherwise."
  (flet ((stale (reason) (error 'stale-work-topic-occurrence
                                :occurrence occurrence :reason reason)))
    (unless (string= current (topic-occurrence-snapshot occurrence))
      (stale "the page source is not the recorded snapshot"))
    (let* ((element (topic-occurrence-element-range occurrence))
           (tag (topic-occurrence-start-tag-range occurrence))
           (topic (topic-occurrence-topic-range occurrence))
           (here (find (car element) (scan-work-topics current (topic-occurrence-page occurrence))
                       :key (lambda (o) (car (topic-occurrence-element-range o))))))
      (unless (and here
                   (equal element (topic-occurrence-element-range here))
                   (equal tag (topic-occurrence-start-tag-range here))
                   (equal topic (topic-occurrence-topic-range here))
                   (<= (car tag) (car topic) (cdr topic) (cdr tag) (cdr element))
                   (string= (topic-occurrence-topic occurrence) current
                            :start2 (car topic) :end2 (cdr topic))
                   (equal (topic-occurrence-topic here) (topic-occurrence-topic occurrence)))
        (stale "its ranges no longer denote the recorded declaration"))
      occurrence)))

;;;; FedWiki Work item observations
;;
;; Work can also be authored as structured Federated Wiki Items on one page:
;; a work-topic Item for each Topic, Relation Contracts included, and a
;; work-relationship Item for each relationship statement. FedWiki keeps an
;; Item as opaque JSON and edits it by item id, so an Item keeps its id when
;; it is edited, moved or reordered, where an HTML range goes stale at any
;; changed byte. This section only reads such pages. Work Breakdown.html
;; remains the source WORK-PROJECTION reads; nothing here fetches or writes.
;;
;; A FedWiki item observation names one authored Item as a source occurrence
;; names one <li>. Its address is (site, slug, item-id): item ids are random
;; and unique only within a page, and a fork or copy carries them to another
;; site or page. The observed Item is evidence, compared whole; a page whose
;; Item differs at all makes the observation stale.
;;
;; Pages are taken parsed: a JSON object is an EQUAL hash table, an array a
;; vector or list, as HyperBook's FedWiki reader returns them.

(defclass work-fedwiki-item-observation ()
  ((site :initarg :site :reader fedwiki-item-observation-site)
   (slug :initarg :slug :reader fedwiki-item-observation-slug)
   (item-id :initarg :item-id :reader fedwiki-item-observation-item-id)
   (item :initarg :item :reader fedwiki-item-observation-item))
  (:documentation "One authored Work Item on one Federated Wiki page, as observed.
SITE, SLUG and ITEM-ID are the address. An item id alone identifies nothing:
it is unique only within one page, and a fork or copy carries it to another
site or page. ITEM is a copy of the whole Item as read; it is evidence,
compared whole, never used to find the Item again."))

(defmethod print-object ((observation work-fedwiki-item-observation) stream)
  (print-unreadable-object (observation stream :type t)
    (format stream "~A ~A item ~A" (fedwiki-item-observation-site observation)
            (fedwiki-item-observation-slug observation)
            (fedwiki-item-observation-item-id observation))))

(defun %json-field (object name)
  "The value of NAME in the parsed JSON OBJECT, or NIL if it is absent or null."
  (multiple-value-bind (value present) (gethash name object)
    (and present (not (eq value :null)) value)))

(defun %json-array-p (value)
  (or (consp value) (and (vectorp value) (not (stringp value)))))

(defun %copy-json (value)
  "A copy of the parsed JSON VALUE sharing no object or array with it."
  (cond ((hash-table-p value)
         (let ((copy (make-hash-table :test (hash-table-test value))))
           (maphash (lambda (key item) (setf (gethash key copy) (%copy-json item))) value)
           copy))
        ((%json-array-p value) (map (if (listp value) 'list 'vector) #'%copy-json value))
        (t value)))

(defun %json-equal (a b)
  "Whether the parsed JSON values A and B are equal: objects key by key, in
any order, arrays element by element, anything else by EQUAL."
  (cond ((and (hash-table-p a) (hash-table-p b))
         (and (= (hash-table-count a) (hash-table-count b))
              (loop for key being the hash-keys of a using (hash-value value)
                    always (multiple-value-bind (other present) (gethash key b)
                             (and present (%json-equal value other))))))
        ((and (%json-array-p a) (%json-array-p b))
         (and (= (length a) (length b)) (every #'%json-equal a b)))
        (t (equal a b))))

(defun %fedwiki-story (page)
  "The Items of the parsed FedWiki PAGE, in story order."
  (coerce (or (%json-field page "story") '()) 'list))

(defun %fedwiki-item-string (item name)
  "The string NAME of ITEM, or an error naming the Item."
  (let ((value (%json-field item name)))
    (unless (stringp value)
      (error "FedWiki ~A Item ~S has no string ~S." (%json-field item "type")
             (%json-field item "id") name))
    value))

(defun observe-work-fedwiki-item (site slug item)
  "An observation of ITEM, as read from the page SLUG at SITE."
  (check-type site string)
  (check-type slug string)
  (make-instance 'work-fedwiki-item-observation
                 :site site :slug slug :item-id (%fedwiki-item-string item "id")
                 :item (%copy-json item)))

(defun resolve-work-fedwiki-item-observation (observation page)
  "OBSERVATION, if PAGE -- the page now at its site and slug, parsed; the JSON
names neither -- holds its item id exactly once and that Item equals the
observed Item. Otherwise STALE-WORK-RELATIONSHIP-OCCURRENCE. Nothing is
relocated."
  (let ((matches (remove (fedwiki-item-observation-item-id observation) (%fedwiki-story page)
                         :key (lambda (item) (%json-field item "id")) :test-not #'equal)))
    (flet ((stale (reason) (error 'stale-work-relationship-occurrence
                                  :occurrence observation :reason reason)))
      (unless (= 1 (length matches))
        (stale (format nil "its item id occurs ~D times on the page" (length matches))))
      (unless (%json-equal (first matches) (fedwiki-item-observation-item observation))
        (stale "the Item on the page is not the observed Item"))
      observation)))

;;;; Work projections
;;
;; One set of rules for every authored representation of Work: Topics in
;; authored order, with positions from that order; relationship statements
;; as Associations whose ID spells from, relation and to; a contract
;; reference resolved against every Topic of the page. Only the occurrence
;; each Association keeps differs between representations.
;;
;; Open: two authored statements of one relationship are two occurrences,
;; distinct by range or by item id, yet their Associations get one derived
;; ID, and TALA refuses such a projection. That is a question of Association
;; identity, not of either representation, and it is not decided here.

(defclass work-topic (tm:topicmap-topic)
  ((source-occurrence :initarg :source-occurrence :initform nil
                      :reader topic-source-occurrence))
  (:documentation "A Work Topic and the authored declaration it was projected
from, where its representation keeps one. The declaration is on the page
projected; the Topic's object is the carrier page the declaration names."))

(defun %work-topic (index id label kind status object &optional source-occurrence)
  "The Work Topic authored INDEXth among a page's Topics."
  (check-type id string)
  (check-type label string)
  (make-instance 'work-topic
                 :id id :type :work-page :label label :object object
                 :source-occurrence source-occurrence
                 :view-properties (list :x (* 285 (mod index 4)) :y (* 120 (floor index 4))
                                        :visible t :kind kind :status status)))

(define-condition duplicate-work-topic-declaration (error)
  ((topic :initarg :topic :reader duplicate-declaration-topic)
   (occurrences :initarg :occurrences :reader duplicate-declaration-occurrences))
  (:report (lambda (condition stream)
             (format stream "Topic ID ~S is declared ~D times: ~{~A~^, ~}. One Topic ID names one Topic."
                     (duplicate-declaration-topic condition)
                     (length (duplicate-declaration-occurrences condition))
                     (duplicate-declaration-occurrences condition)))))

(defun %refuse-duplicate-declarations (topics)
  "Refuse a Topic ID that two declared TOPICS share, naming every declaration of it."
  (loop for (topic . rest) on topics
        for id = (tm:topicmap-topic-id-of topic)
        when (and (topic-source-occurrence topic)
                  (find id rest :key #'tm:topicmap-topic-id-of :test #'string=))
          do (error 'duplicate-work-topic-declaration
                    :topic id
                    :occurrences (loop for other in topics
                                       when (string= id (tm:topicmap-topic-id-of other))
                                         collect (topic-source-occurrence other)))))

(defun %work-projection (all-topics statements &key source areas-only)
  "The Work projection of ALL-TOPICS and STATEMENTS, each (FROM RELATION TO
OCCURRENCE), both in authored order. AREAS-ONLY keeps the area Topics and
the Associations between them; a contract reference is resolved against
ALL-TOPICS either way."
  (let* ((topics (if areas-only
                     (remove "area" all-topics
                             :key (lambda (topic)
                                    (getf (tm:topicmap-topic-view-properties-of topic) :kind))
                             :test-not #'equal)
                     all-topics))
         (ids (mapcar #'tm:topicmap-topic-id-of topics))
         (associations
           (loop for (from relation to occurrence) in statements
                 for id = (format nil "work:~A:~A:~A" from relation to)
                 when (or (not areas-only)
                          (and (member from ids :test #'equal)
                               (member to ids :test #'equal)))
                   collect (tm:make-topicmap-association
                            :id id :type relation :from from :to to
                            ;; Derived while projecting, and part of no identity.
                            ;; The reference in TYPE is the authored statement and
                            ;; the contract Topic owns the label; the occurrence
                            ;; says which authored statement this Association came from.
                            :properties
                            (list* :source-occurrence occurrence
                                   (when (relation-contract-reference-p relation)
                                     (list :relation-contract
                                           (resolve-relation-contract relation all-topics id))))))))
    ;; Checked against every declaration, as contract references are.
    (%refuse-duplicate-declarations all-topics)
    (tm:make-topicmap-projection :source source :topics topics
                                 :associations associations)))

(defun project-fedwiki-work (page &key site slug source areas-only
                                       (find-page #'work-page))
  "Project the work-topic and work-relationship Items of PAGE, the parsed
FedWiki page SLUG at SITE, by the rules PROJECT-WORK-BREAKDOWN uses. Each
Association's source occurrence observes its Item. Reads nothing: PAGE is
given."
  (check-type site string)
  (check-type slug string)
  (flet ((items (type)
           (remove type (%fedwiki-story page)
                   :key (lambda (item) (%json-field item "type")) :test-not #'equal)))
    (%work-projection
     (loop for item in (items "work-topic")
           for index from 0
           collect (%work-topic index (%fedwiki-item-string item "topic")
                                (%fedwiki-item-string item "label")
                                (%json-field item "kind") (%json-field item "status")
                                (funcall find-page (%fedwiki-item-string item "page")
                                         (or (%json-field item "hyperbook")
                                             "dreyeck/work/reading"))))
     (loop for item in (items "work-relationship")
           collect (list (%fedwiki-item-string item "from")
                         (%fedwiki-item-string item "relation")
                         (%fedwiki-item-string item "to")
                         (observe-work-fedwiki-item site slug item)))
     :source source :areas-only areas-only)))

(defun project-work-breakdown (html &key source areas-only
                                         (find-page #'work-page))
  "Project Work Breakdown HTML (a pathname, read once, or a string). FIND-PAGE
maps a page title and HyperBook ID to the Topic's object. The one source
string is parsed, scanned for Topic declarations and relationship
occurrences, and kept by each."
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
         (topic-nodes (remove-if-not (lambda (node) (plump:attribute node "data-topic"))
                                     (plump:get-elements-by-tag-name dom "a")))
         (declarations (let ((declarations (scan-work-topics snapshot source)))
                         (%align-topics declarations topic-nodes snapshot)
                         declarations)))
    (%work-projection
     ;; Every authored Topic, including those AREAS-ONLY leaves out, so a
     ;; contract reference is checked against the whole page either way.
     (loop for node in topic-nodes
           for declaration in declarations
           for index from 0
           collect (%work-topic index (plump:attribute node "data-topic")
                                (plump:decode-entities (plump:text node))
                                (plump:attribute node "data-kind")
                                (plump:attribute node "data-status")
                                (funcall find-page (plump:attribute node "page")
                                         (or (plump:attribute node "hyperbook")
                                             "dreyeck/work/reading"))
                                declaration))
     (loop for node in relationship-nodes
           for occurrence in occurrences
           collect (list (plump:attribute node "data-from")
                         (plump:attribute node "data-relation")
                         (plump:attribute node "data-to")
                         occurrence))
     :source source :areas-only areas-only)))

;; These are ordinary page links and relationship entries in Work Breakdown.
;; Reading this one page avoids a second authoritative WBS list in Lisp or D2.
(defun work-projection (&key areas-only (page (work-page "Work Breakdown")))
  "Read PAGE's current file, independently of its cached DOM."
  (project-work-breakdown (uiop:read-file-string (hyperdoc:file-of page))
                          :source page :areas-only areas-only))

;;;; Relation change requests
;;
;; A request to change which Relation Contract one authored relationship
;; statement uses. It names the authored relationship statement by its
;; source occurrence, not by the semantic triple, so of two statements of
;; the same relationship it names one. The occurrence is an HTML source
;; occurrence or a FedWiki item observation; the request holds it and
;; copies nothing out of it. Making a request observes and writes nothing;
;; it grants no permission and holds no executor. Translating it into a
;; change to one representation belongs to a later writer. Whether a
;; changed relation makes the same Association or another one is not
;; decided here: the request concerns the authored statement.

(define-condition relation-change-refused (error)
  ((association :initarg :association :reader refused-relation-change-association)
   (reason :initarg :reason :reader relation-change-refused-reason)
   (cause :initarg :cause :initform nil :reader relation-change-refused-cause))
  (:report (lambda (condition stream)
             (format stream "No relation change request: ~A"
                     (relation-change-refused-reason condition))))
  (:documentation "Nothing was requested and nothing was written. CAUSE, if
any, is the condition that showed why."))

(defclass relation-change-request ()
  ((operation :initarg :operation :reader relation-change-operation)
   (association :initarg :association :reader relation-change-association)
   (occurrence :initarg :occurrence :reader relation-change-occurrence)
   (observed-relation :initarg :observed-relation :reader relation-change-observed-relation)
   (observed-contract :initarg :observed-contract :reader relation-change-observed-contract)
   (proposed-contract :initarg :proposed-contract :reader relation-change-proposed-contract))
  (:documentation "Change relation for one exact authored Work relationship:
the projected Association, the source occurrence of its authored statement,
the relation observed there and the Relation Contract Topic proposed in its
place. Intent and evidence only; no executor, no permission."))

(defun relation-change-proposed-relation (request)
  "The proposed relation reference: the Relation Contract Topic ID."
  (tm:topicmap-topic-id-of (relation-change-proposed-contract request)))

;; What a request needs from its occurrence, for each of the two forms an
;; authored relationship statement is observed in: a short name, the
;; relation it records, the authored source now, whether that source still
;; holds it, the Topics that source authors, and its evidence for the view.
;; Each is one function over the two concrete classes; there is no common
;; occurrence class.

(defun %occurrence-label (occurrence)
  "A short name for OCCURRENCE among its page's statements."
  (etypecase occurrence
    (work-relationship-source-occurrence
     (format nil "occurrence ~D" (relationship-occurrence-ordinal occurrence)))
    (work-fedwiki-item-observation
     (format nil "item ~A" (fedwiki-item-observation-item-id occurrence)))))

(defun %occurrence-relation (occurrence)
  "The relation the authored statement at OCCURRENCE records."
  (etypecase occurrence
    (work-relationship-source-occurrence (relationship-occurrence-relation occurrence))
    (work-fedwiki-item-observation
     (%json-field (fedwiki-item-observation-item occurrence) "relation"))))

(defun %current-authored-source (occurrence)
  "OCCURRENCE's authored source as it is now, or NIL for a FedWiki page, which
is not fetched here: its reader supplies it."
  (etypecase occurrence
    (work-relationship-source-occurrence
     (uiop:read-file-string (hyperdoc:file-of (relationship-occurrence-page occurrence))))
    (work-fedwiki-item-observation nil)))

(defun %resolve-occurrence (occurrence current)
  "OCCURRENCE, if CURRENT, its authored source now, still holds it; otherwise
STALE-WORK-RELATIONSHIP-OCCURRENCE."
  (etypecase occurrence
    (work-relationship-source-occurrence
     (resolve-work-relationship-occurrence occurrence :current current))
    (work-fedwiki-item-observation
     (resolve-work-fedwiki-item-observation occurrence current))))

(defun %current-work-topics (occurrence current)
  "Every Work Topic that CURRENT, OCCURRENCE's authored source now, authors."
  (tm:topicmap-projection-topics-of
   (etypecase occurrence
     (work-relationship-source-occurrence
      (project-work-breakdown current :source (relationship-occurrence-page occurrence)))
     (work-fedwiki-item-observation
      (project-fedwiki-work current :site (fedwiki-item-observation-site occurrence)
                                    :slug (fedwiki-item-observation-slug occurrence))))))

(defun %render-occurrence-evidence (occurrence)
  "The authored evidence OCCURRENCE holds, in a request's view."
  (etypecase occurrence
    (work-relationship-source-occurrence
     (let ((page (relationship-occurrence-page occurrence))
           (element (relationship-occurrence-element-range occurrence)))
       (views:html
         (:table :class "inspector-table"
           (:tr (:td "Source occurrence") (:td (views:object-ref occurrence)))
           (:tr (:td "Source page")
                (:td (if (typep page 'hyperbook:page)
                         (views:object-ref page)
                         (views:html (:tt (views:esc (prin1-to-string page))))))))
         (:p "Authored statement, as observed in the page source:")
         (:pre (views:esc (subseq (relationship-occurrence-snapshot occurrence)
                                  (car element) (cdr element)))))))
    (work-fedwiki-item-observation
     (views:html
       (:table :class "inspector-table"
         (:tr (:td "Source occurrence") (:td (views:object-ref occurrence)))
         (:tr (:td "Site") (:td (:tt (views:esc (fedwiki-item-observation-site occurrence)))))
         (:tr (:td "Page slug") (:td (:tt (views:esc (fedwiki-item-observation-slug occurrence)))))
         (:tr (:td "Item id") (:td (:tt (views:esc (fedwiki-item-observation-item-id occurrence))))))
       (:p "Authored Item, as observed on the page:")
       (:table :class "inspector-table"
         (maphash (lambda (field value)
                    (views:html
                      (:tr (:td (:tt (views:esc field)))
                           (:td (:tt (views:esc (princ-to-string value)))))))
                  (fedwiki-item-observation-item occurrence)))))))

(defmethod print-object ((request relation-change-request) stream)
  (print-unreadable-object (request stream :type t)
    (format stream "~A -> ~A, ~A" (relation-change-observed-relation request)
            (relation-change-proposed-relation request)
            (%occurrence-label (relation-change-occurrence request)))))

(defun request-relation-change (association proposed &key (current nil current-p))
  "A request to make the authored relationship statement behind ASSOCIATION
use the Relation Contract whose Topic ID is PROPOSED. CURRENT is the
authored source now: for an HTML source occurrence the page source, read
from its page unless given; for a FedWiki item observation the parsed page,
which must be given. Observes, writes nothing, and signals
RELATION-CHANGE-REFUSED unless every check holds."
  (flet ((refuse (reason &optional cause)
           (error 'relation-change-refused :association association :reason reason :cause cause)))
    (unless (typep association 'tm:topicmap-association)
      (refuse (format nil "~S is not a Topicmap Association" association)))
    (let ((occurrence (getf (tm:topicmap-association-properties-of association) :source-occurrence)))
      (unless (typep occurrence '(or work-relationship-source-occurrence
                                     work-fedwiki-item-observation))
        (refuse (format nil "Association ~A has no Work source occurrence"
                        (tm:topicmap-association-id-of association))))
      (let ((current (if current-p current (%current-authored-source occurrence))))
        (unless current
          (refuse (format nil "the current page of ~A was not given; no page is fetched here"
                          occurrence)))
        (handler-case (%resolve-occurrence occurrence current)
          (stale-work-relationship-occurrence (condition)
            (refuse "its source occurrence is stale" condition)))
        ;; The occurrence resolved in the current source. What remains is
        ;; whether the projected Association agrees with the authored
        ;; statement it was projected from.
        (let ((observed (tm:topicmap-association-type-of association)))
          (unless (equal observed (%occurrence-relation occurrence))
            (refuse (format nil "the Association says ~S but its source occurrence records ~S"
                            observed (%occurrence-relation occurrence))))
          (unless (stringp proposed)
            (refuse (format nil "~S is not a Relation Contract Topic ID" proposed)))
          (when (equal proposed observed)
            (refuse (format nil "it already uses ~A" observed)))
          (let ((contract
                  (handler-case
                      (resolve-relation-contract
                       proposed (%current-work-topics occurrence current)
                       (tm:topicmap-association-id-of association))
                    (relation-contract-reference-error (condition)
                      (refuse (format nil "~A is not a Relation Contract in this page" proposed)
                              condition)))))
            (make-instance 'relation-change-request
                           :operation (w:change-relation-operation)
                           :association association :occurrence occurrence
                           :observed-relation observed
                           :observed-contract (getf (tm:topicmap-association-properties-of association)
                                                    :relation-contract)
                           :proposed-contract contract)))))))

(views:defview relation-change-request-overview (request relation-change-request)
  (views:html-view :title "Relation change request" :priority 1
    (let ((observed (relation-change-observed-contract request))
          (proposed (relation-change-proposed-contract request)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Operation")
               (:td (:tt (views:esc (w:semantic-operation-identity-id (relation-change-operation request))))))
          (:tr (:td "Projected Association") (:td (views:object-ref (relation-change-association request))))
          (:tr (:td "Observed relation") (:td (:tt (views:esc (relation-change-observed-relation request)))))
          (:tr (:td "Observed Relation Contract")
               (:td (if observed
                        (views:object-ref observed :display (tm:topicmap-topic-id-of observed))
                        (views:html "none: a plain relation"))))
          (:tr (:td "Proposed Relation Contract")
               (:td (views:object-ref proposed :display (tm:topicmap-topic-id-of proposed))))
          (:tr (:td "Executed") (:td "no -- a request holds no writer and grants no permission")))
        (:p "Proposed change: "
            (:tt (views:esc (relation-change-observed-relation request))) " → "
            (:tt (views:esc (relation-change-proposed-relation request))))
        (:h4 "Authored source occurrence")
        (%render-occurrence-evidence (relation-change-occurrence request))))))

;;;; Work status change requests
;;
;; A request to change the work status one authored Work Topic declaration
;; states. It completes the operation request selected on that declaration,
;; and refers to it. It names the declaration by its Work Topic source
;; occurrence: the <a data-topic> on the page projected, not the carrier page
;; the declaration names and not any passage there. The request holds the Topic
;; and the occurrence and copies nothing out of them; their ranges stay the
;; occurrence's evidence. Making a request observes and writes nothing; it
;; grants no permission and holds no executor. Work statuses are
;; descriptive: any stated status may be proposed for another, and no
;; lifecycle is checked. The projection reads a declaration without
;; data-status as stating no status, so there is none to change, and such a
;; request is refused rather than given a default.

(define-condition work-status-change-refused (error)
  ((topic :initarg :topic :reader refused-work-status-change-topic)
   (reason :initarg :reason :reader work-status-change-refused-reason)
   (cause :initarg :cause :initform nil :reader work-status-change-refused-cause))
  (:report (lambda (condition stream)
             (format stream "No work status change request: ~A"
                     (work-status-change-refused-reason condition))))
  (:documentation "Nothing was requested and nothing was written. CAUSE, if
any, is the condition that showed why."))

(defclass work-status-change-request ()
  ((operation :initarg :operation :reader work-status-change-operation)
   (selection :initarg :selection :reader work-status-change-selection)
   (topic :initarg :topic :reader work-status-change-topic)
   (occurrence :initarg :occurrence :reader work-status-change-occurrence)
   (observed-status :initarg :observed-status :reader work-status-change-observed-status)
   (proposed-status :initarg :proposed-status :reader work-status-change-proposed-status))
  (:documentation "Change work status for one exact authored Work Topic
declaration: the operation request it completes, the projected Work Topic,
the source occurrence of its declaration, the status observed there and the
status proposed in its place. Intent and evidence only; no executor, no
permission, no edit."))

(defmethod print-object ((request work-status-change-request) stream)
  (print-unreadable-object (request stream :type t)
    (format stream "~A: ~S -> ~S, declaration ~D"
            (tm:topicmap-topic-id-of (work-status-change-topic request))
            (work-status-change-observed-status request)
            (work-status-change-proposed-status request)
            (topic-occurrence-ordinal (work-status-change-occurrence request)))))

(defun %same-declaration-p (a b)
  "Whether the Work Topic source occurrences A and B observe one declaration:
the same page, snapshot and element."
  (and (eq (topic-occurrence-page a) (topic-occurrence-page b))
       (string= (topic-occurrence-snapshot a) (topic-occurrence-snapshot b))
       (equal (topic-occurrence-element-range a) (topic-occurrence-element-range b))))

(defun request-work-status-change (selection topic proposed &key (current nil current-p))
  "A request completing SELECTION -- Change work status selected on the
declaration of the Work TOPIC -- with the work status PROPOSED. CURRENT is
the declaring page's source now, read from its page unless given. Observes,
writes nothing, and signals WORK-STATUS-CHANGE-REFUSED unless every check
holds."
  (flet ((refuse (reason &optional cause)
           (error 'work-status-change-refused :topic topic :reason reason :cause cause)))
    (unless (typep topic 'tm:topicmap-topic)
      (refuse (format nil "~S is not a Topicmap Topic" topic)))
    (let ((id (tm:topicmap-topic-id-of topic))
          (occurrence (and (typep topic 'work-topic) (topic-source-occurrence topic))))
      (unless (typep occurrence 'work-topic-source-occurrence)
        (refuse (format nil "Topic ~A has no Work Topic source occurrence" id)))
      (let ((selected (and (typep selection 'r:operation-request)
                           (r:operation-request-occurrence selection))))
        (unless (and selected
                     (eq (w:change-work-status-operation) (r:operation-request-operation selection))
                     (typep selected 'work-topic-source-occurrence)
                     (%same-declaration-p selected occurrence))
          (refuse (format nil "~S is not Change work status selected on the declaration of ~A"
                          selection id))))
      (let ((current (if current-p
                         current
                         (uiop:read-file-string (hyperdoc:file-of (topic-occurrence-page occurrence))))))
        (handler-case (resolve-work-topic-occurrence occurrence :current current)
          (stale-work-topic-occurrence (condition)
            (refuse "its source occurrence is stale" condition)))
        (unless (equal id (topic-occurrence-topic occurrence))
          (refuse (format nil "Topic ~A holds the source occurrence of ~A"
                          id (topic-occurrence-topic occurrence))))
        ;; The occurrence resolved. What remains is whether the projected
        ;; Topic agrees with its declaration as the current page projects it,
        ;; under every rule a projection checks.
        (let* ((start (car (topic-occurrence-element-range occurrence)))
               (declared
                 (find start
                       (tm:topicmap-projection-topics-of
                        (handler-case
                            (project-work-breakdown current :source (topic-occurrence-page occurrence))
                          (error (condition)
                            (refuse "the declaring page does not project" condition))))
                       :key (lambda (other)
                              (car (topic-occurrence-element-range (topic-source-occurrence other))))))
               (observed (and declared
                              (getf (tm:topicmap-topic-view-properties-of declared) :status)))
               (projected (getf (tm:topicmap-topic-view-properties-of topic) :status)))
          (unless (and declared (equal id (tm:topicmap-topic-id-of declared)))
            (refuse (format nil "the declaring page does not declare ~A at its occurrence" id)))
          (unless observed
            (refuse (format nil "the declaration of ~A states no work status, so there is none to change"
                            id)))
          (unless (equal projected observed)
            (refuse (format nil "Topic ~A says ~S but its declaration states ~S" id projected observed)))
          (unless (and (stringp proposed)
                       (string/= "" (string-trim '(#\Space #\Tab #\Newline) proposed)))
            (refuse (format nil "~S is not a work status" proposed)))
          (when (equal proposed observed)
            (refuse (format nil "it already states ~S" observed)))
          (make-instance 'work-status-change-request
                         :operation (w:change-work-status-operation) :selection selection
                         :topic topic :occurrence occurrence
                         :observed-status observed :proposed-status proposed))))))

(views:defview work-status-change-request-overview (request work-status-change-request)
  (views:html-view :title "Work status change request" :priority 1
    (let* ((topic (work-status-change-topic request))
           (occurrence (work-status-change-occurrence request))
           (page (topic-occurrence-page occurrence))
           (carrier (tm:topicmap-topic-object-of topic)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Operation")
               (:td (:tt (views:esc (w:semantic-operation-identity-id (work-status-change-operation request))))))
          (:tr (:td "Selection") (:td (views:object-ref (work-status-change-selection request))))
          (:tr (:td "Work Topic")
               (:td (views:object-ref topic :display (tm:topicmap-topic-id-of topic))))
          (:tr (:td "Declaring page")
               (:td (if (typep page 'hyperbook:page)
                        (views:object-ref page)
                        (views:html (:tt (views:esc (prin1-to-string page)))))))
          (:tr (:td "Source occurrence")
               (:td (views:object-ref occurrence
                                      :display (format nil "declaration ~D of ~A"
                                                       (topic-occurrence-ordinal occurrence)
                                                       (topic-occurrence-topic occurrence)))))
          (:tr (:td "Observed work status")
               (:td (:tt (views:esc (work-status-change-observed-status request)))))
          (:tr (:td "Proposed work status")
               (:td (:tt (views:esc (work-status-change-proposed-status request)))))
          (:tr (:td "Executed") (:td "no -- a request holds no writer and grants no permission")))
        (:p "The request concerns the declaration on the declaring page. The Topic's carrier page, "
            (if carrier (views:object-ref carrier) (views:html "none"))
            ", is not its target.")))))

;;;; Work relationship creation requests
;;
;; A request to create one authored Work relationship statement. Changing
;; an existing declaration can take its source occurrence as both target
;; and authority. Creating one cannot: the statement's occurrence exists
;; only after an effect. So three things stay apart. The selection is the
;; operation request on the source endpoint's Topic declaration, where the
;; interaction began. The destination Topic and the relation are arguments.
;; The authority is the observed declaring page and its exact snapshot,
;; which both endpoint declarations must belong to. The request holds no
;; relationship occurrence, writes nothing, grants no permission and holds
;; no executor; where a new statement would go is a later plan's concern.
;;
;; Create relationship does not author a second statement of a relationship
;; the snapshot already states: an authored statement read as the same
;; from, relation and to refuses the request. That is this operation's
;; contract. It does not decide whether two statements of one relationship
;; are one Association, which the reading model leaves open.

(define-condition work-relationship-creation-refused (error)
  ((reason :initarg :reason :reader work-relationship-creation-refused-reason)
   (cause :initarg :cause :initform nil :reader work-relationship-creation-refused-cause))
  (:report (lambda (condition stream)
             (format stream "No relationship creation request: ~A"
                     (work-relationship-creation-refused-reason condition))))
  (:documentation "Nothing was requested and nothing was written. CAUSE, if
any, is the condition that showed why."))

(defclass work-relationship-creation-request ()
  ((operation :initarg :operation :reader work-relationship-creation-operation)
   (selection :initarg :selection :reader work-relationship-creation-selection)
   (from-occurrence :initarg :from-occurrence :reader work-relationship-creation-from-occurrence)
   (to-occurrence :initarg :to-occurrence :reader work-relationship-creation-to-occurrence)
   (relation :initarg :relation :reader work-relationship-creation-relation)
   (authority-page :initarg :authority-page :reader work-relationship-creation-authority-page)
   (authority-snapshot :initarg :authority-snapshot :reader work-relationship-creation-authority-snapshot))
  (:documentation "Create relationship: the operation request selected on the
source Topic's declaration, both endpoint declarations, the relation, and the
observed page and exact snapshot it is to be created in. Intent and evidence
only; the relationship has no occurrence until an effect creates one."))

(defmethod print-object ((request work-relationship-creation-request) stream)
  (print-unreadable-object (request stream :type t)
    (format stream "~A -~A-> ~A"
            (topic-occurrence-topic (work-relationship-creation-from-occurrence request))
            (work-relationship-creation-relation request)
            (topic-occurrence-topic (work-relationship-creation-to-occurrence request)))))

(defun request-work-relationship-creation (selection to-topic relation &key (current nil current-p))
  "A request to create the relationship RELATION from the Work Topic whose
declaration SELECTION was selected on, to the Work Topic TO-TOPIC. CURRENT is
the declaring page's source now, read from its page unless given; both
declarations must belong to it, exactly as observed. Observes, writes nothing,
and signals WORK-RELATIONSHIP-CREATION-REFUSED unless every check holds."
  (flet ((refuse (reason &optional cause)
           (error 'work-relationship-creation-refused :reason reason :cause cause)))
    (let ((operation (w:create-relationship-operation))
          (from (and (typep selection 'r:operation-request)
                     (r:operation-request-occurrence selection))))
      (unless (and from
                   (eq operation (r:operation-request-operation selection))
                   (typep from 'work-topic-source-occurrence))
        (refuse (format nil "~S is not Create relationship selected on a Work Topic declaration" selection)))
      (let ((to (and (typep to-topic 'work-topic) (topic-source-occurrence to-topic)))
            (page (topic-occurrence-page from))
            (snapshot (topic-occurrence-snapshot from)))
        (unless to
          (refuse (format nil "~S is no Work Topic declared in HTML" to-topic)))
        ;; One authority: the page both declarations were observed on, as it was.
        (unless (and (eq page (topic-occurrence-page to))
                     (string= snapshot (topic-occurrence-snapshot to)))
          (refuse "the two declarations do not belong to the same observed page snapshot"))
        (let ((current (if current-p current (uiop:read-file-string (hyperdoc:file-of page)))))
          (handler-case (progn (resolve-work-topic-occurrence from :current current)
                               (resolve-work-topic-occurrence to :current current))
            (stale-work-topic-occurrence (condition)
              (refuse "the observed page snapshot is stale" condition)))
          (unless (and (stringp relation)
                       (string/= "" (string-trim '(#\Space #\Tab #\Newline) relation)))
            (refuse (format nil "~S is not a relation" relation)))
          (when (relation-contract-reference-p relation)
            (handler-case
                (resolve-relation-contract
                 relation (tm:topicmap-projection-topics-of (project-work-breakdown current :source page))
                 (format nil "work:~A:~A:~A" (topic-occurrence-topic from) relation (topic-occurrence-topic to)))
              (relation-contract-reference-error (condition)
                (refuse (format nil "~A is not a Relation Contract in this page" relation) condition))))
          (let ((stated (find (list (topic-occurrence-topic from) relation (topic-occurrence-topic to))
                              (scan-work-relationships current page)
                              :key (lambda (occurrence)
                                     (list (relationship-occurrence-from occurrence)
                                           (relationship-occurrence-relation occurrence)
                                           (relationship-occurrence-to occurrence)))
                              :test #'equal)))
            (when stated
              (refuse (format nil "the observed page already states ~A -~A-> ~A, as its relationship statement ~D"
                              (topic-occurrence-topic from) relation (topic-occurrence-topic to)
                              (relationship-occurrence-ordinal stated)))))
          (make-instance 'work-relationship-creation-request
                         :operation operation :selection selection
                         :from-occurrence from :to-occurrence to :relation relation
                         :authority-page page :authority-snapshot snapshot))))))

(views:defview work-relationship-creation-request-overview (request work-relationship-creation-request)
  (views:html-view :title "Relationship creation request" :priority 1
    (let ((page (work-relationship-creation-authority-page request))
          (from (work-relationship-creation-from-occurrence request))
          (to (work-relationship-creation-to-occurrence request)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Operation")
               (:td (:tt (views:esc (w:semantic-operation-identity-id
                                     (work-relationship-creation-operation request))))))
          (:tr (:td "Selection") (:td (views:object-ref (work-relationship-creation-selection request))))
          (:tr (:td "From") (:td (views:object-ref from :display (topic-occurrence-topic from))))
          (:tr (:td "Relation") (:td (:tt (views:esc (work-relationship-creation-relation request)))))
          (:tr (:td "To") (:td (views:object-ref to :display (topic-occurrence-topic to))))
          (:tr (:td "Authority")
               (:td (if (typep page 'hyperbook:page)
                        (views:object-ref page)
                        (views:html (:tt (views:esc (prin1-to-string page)))))
                    (views:esc (format nil ", as observed: ~D characters"
                                       (length (work-relationship-creation-authority-snapshot request))))))
          (:tr (:td "Relationship occurrence") (:td "none yet -- it exists only after an effect creates it"))
          (:tr (:td "Executed") (:td "no -- a request holds no writer and grants no permission")))))))

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
