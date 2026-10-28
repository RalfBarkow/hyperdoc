;;;; HyperDoc project work as a CTM Topic Map: the deterministic emitter
(defpackage #:dreyeck/work/project
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:plan #:dreyeck/work/ctm-page-authoring)
                    (#:tm #:dreyeck/topicmap)
                    (#:tmdm #:topic-maps.tmdm)
                    (#:ctm #:topic-maps.ctm)
                    (#:cxtm #:topic-maps.cxtm)
                    (#:native #:dreyeck/inspector/topicmap)
                    (#:snap #:dreyeck/source-snapshot)
                    (#:v #:html-inspector-views))
  (:export #:+base+ #:+document-iri+ #:+project-ctm-file+
           #:read-project-sources #:project-sources #:sources-items #:source-path #:source-sha256 #:source-page
           #:project-model #:build-project-model #:model-text #:model-declarations #:model-statements
           #:model-proposals #:model-gaps #:model-assignments #:materialize-project-ctm #:write-project-ctm
           #:project-ctm-pathname #:project-ctm-digest-pathname #:project-ctm-refused
           #:model-evidence-inputs #:evidence-path #:evidence-sha256
           #:declaration-id #:declaration-kind #:declaration-status #:declaration-page-iri #:declaration-label
           #:statement-from #:statement-relation #:statement-to #:statement-iri #:statement-page-iri
           #:topic-iri #:page-iri #:relation-type-iri #:role-type-iri #:schema-iri #:gap-rule #:gap-subjects
           ;; project-workspace.lisp
           #:ctm-revision #:observe-ctm-revision #:ctm-revision-from-octets #:revision-octets #:revision-sha256
           #:revision-observed-at #:revision-bom-offset #:revision-map #:revision-cxtm #:revision-refusal
           #:revision-export-octets #:compare-revisions #:trace-project-map
           #:project-reading #:project-workspace #:project-ctm-document #:reading-workspace #:reading-projection
           #:reading-model #:reading-document #:topic-key #:import-project-ctm-revision #:scenario-reading
           #:model-acceptance #:model-proposed-entries #:acceptance-records #:acceptance-authorities
           #:record-id #:record-package #:record-decision #:record-decided-at #:record-authority #:record-evidence
           #:record-revision #:record-supersedes #:record-withdrawal-p #:record-iri #:unsuperseded-records
           #:criterion-revision #:criterion-iri #:entry-revisions #:model-evidence-entries #:entry-iri #:entry-key
           #:acceptance-explanation #:explain-acceptance))
(in-package #:dreyeck/work/project)

(hyperdoc:see (hyperdoc:page "HyperDoc Project Workspace" :hyperbook "dreyeck/work/project"))
(hyperdoc:see (hyperdoc:page "Implementation Assignments" :hyperbook "dreyeck/work/project"))

;; The Work pages are the authority for their declarations, the WBS Dictionary for its entries, and the page Implementation
;; Assignments for assignments and proposals. This file reads those pages once each, with the existing readers where they
;; exist (WORK:PROJECT-WORK-BREAKDOWN, the dictionary reader of the CTM plan page), and writes their declarations as CTM
;; text. The text is a function of the octets read: the same pages give the same text. It is never read back into the pages.
;;
;; Identity. Every Topic gets a subject identifier under +BASE+, a tag: IRI (RFC 4151) that names and does not locate:
;;   work/topic/<data-topic>                 a declared Work Topic, or a proposal under the ID it would be declared with
;;   page/<hyperbook id>/<page slug>         a HyperDoc page; the slug is the page id in its HyperBook, lowercased
;;   hyperbook/<hyperbook id>                a HyperBook
;;   statement/<hyperbook>/<slug>/<from>/<relation>/<to>/<n>   an authored statement; N counts equal statements on that page
;;   control/<work package>/<control id>     a control of a WBS Dictionary entry
;;   file/<repository path>                  a repository file named as test or changed source
;;   assignment/<id>                         an implementation assignment
;;   evidence/<assignment>/<entry>           an evidence entry of an assignment, by its authored data-evidence
;;   acceptance/<id>                         a record of an Acceptance Records page: a judgment or a withdrawal
;;   authority/<id>                          an authority an Acceptance Records page declares
;;   criterion/<work package>/sha256-<hex>   a revision of a WBS acceptance criterion: the SHA-256 of its text's UTF-8 octets
;;   gap/<rule>/<subject>                    a gap this emitter derives from the sources
;;   schema/<name>                           a type, Role type or Occurrence type of this document
;; Names are names; no position, label or line number is part of an identifier.

(defparameter +base+ "tag:dreyeck.ch,2026:hyperdoc/")
(defparameter +document-iri+ "tag:dreyeck.ch,2026:hyperdoc/project.ctm"
  "The Document IRI every revision of the project CTM is read with. All Topics have subject identifiers, so it names no Topic;
it is fixed so that local identifiers of an external revision resolve the same way in every revision.")
(defparameter +emitter-version+ 2)
(defparameter +project-ctm-file+ "dreyeck/work/project/hyperdoc-project.ctm")
(defparameter +project-ctm-digest-file+ "dreyeck/work/project/hyperdoc-project.ctm.sha256"
  "The SHA-256 of the written CTM, kept beside it: a document cannot contain its own digest.")

(define-condition project-ctm-refused (error)
  ((reason :initarg :reason :reader project-ctm-refusal-reason))
  (:report (lambda (condition stream) (format stream "No project CTM: ~A" (project-ctm-refusal-reason condition)))))
(defun refuse (control &rest arguments) (error 'project-ctm-refused :reason (apply #'format nil control arguments)))

;;; Identifiers

(defun %identifier-part (part)
  (unless (and (stringp part) (plusp (length part))
               (every (lambda (c) (or (alphanumericp c) (find c "._:/-"))) part)
               (every (lambda (c) (< (char-code c) 128)) part))
    (refuse "the identifier part ~S has a character outside A-Z a-z 0-9 . _ : / -" part))
  part)
(defun %namespace (&rest parts) (format nil "~A~{~A/~}" +base+ (mapcar #'%identifier-part parts)))
(defun %iri (&rest parts) (format nil "~A~{~A~^/~}" +base+ (mapcar #'%identifier-part parts)))
(defun slug (title)
  "TITLE lowercased, each run of characters other than letters and digits one hyphen."
  (let ((out (with-output-to-string (s)
               (let ((gap nil))
                 (loop for c across (string-downcase title)
                       do (if (and (alphanumericp c) (< (char-code c) 128))
                              (progn (when gap (write-char #\- s)) (setf gap nil) (write-char c s))
                              (setf gap t)))))))
    (string-trim "-" out)))
(defun topic-iri (id) (%iri "work" "topic" id))
(defun hyperbook-iri (id) (%iri "hyperbook" id))
(defun page-iri (hyperbook-id title) (%iri "page" hyperbook-id (slug title)))
(defun file-iri (path) (%iri "file" path))
(defun schema-iri (name) (%iri "schema" name))
(defun %contract-p (relation)
  "Whether RELATION is a Relation Contract reference, work:relation/..., as the Work reader reads one."
  (let ((prefix "work:relation/")) (and (> (length relation) (length prefix)) (string= prefix relation :end2 (length prefix)))))
(defun relation-key (relation)
  (if (%contract-p relation) (slug relation) (format nil "word-~A" (slug relation))))
(defun relation-type-iri (relation)
  (if (%contract-p relation) (topic-iri relation) (schema-iri (format nil "relation-word-~A" (slug relation)))))
(defun role-type-iri (relation end) (schema-iri (format nil "role-~A-~(~A~)" (relation-key relation) end)))
(defun relation-label (relation) (subseq relation (1+ (or (position #\/ relation :from-end t) -1))))

;;; Sources

(defparameter +sources+
  '((:work-breakdown "dreyeck/work/reading" "Work Breakdown" :work)
    (:plan "dreyeck/work/reading" "Authoring the CTM Plan Page" :work)
    (:dictionary "dreyeck/work/reading" "CTM Plan Page WBS Dictionary" :dictionary)
    (:assignments "dreyeck/work/project" "Implementation Assignments" :assignments))
  "The pages the project CTM is derived from, in the order they are written. Each is the authority for what it declares.")

(defclass source-item ()
  ((role :initarg :role :reader source-role)
   (hyperbook-id :initarg :hyperbook-id :reader source-hyperbook-id)
   (title :initarg :title :reader source-title)
   (kind :initarg :kind :reader source-kind)
   (page :initarg :page :reader source-page)
   (path :initarg :path :reader source-path)
   (sha256 :initarg :sha256 :reader source-sha256)
   (text :initarg :text :reader source-text))
  (:documentation "One source page as read once: its repository path, the SHA-256 of the octets read and the text decoded from them."))
(defclass project-sources ()
  ((items :initarg :items :reader sources-items)
   (observed-at :initarg :observed-at :reader sources-observed-at))
  (:documentation "The source pages of one materialization, each read once."))
(defmethod v:text-representation ((s source-item)) (format nil "Source ~A" (source-path s)))
(defmethod v:text-representation ((s project-sources)) "The source pages of the project CTM")

(defun repository-root () (asdf:system-source-directory "dreyeck"))
(defun repository-path (pathname) (enough-namestring (truename pathname) (repository-root)))
(defun %octets (pathname)
  (with-open-file (in pathname :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (unless (= (length octets) (read-sequence octets in)) (refuse "the file ~A changed while it was read" pathname))
      octets)))
(defun %sha256 (octets) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))
(defun %utf8 (string) (sb-ext:string-to-octets string :external-format :utf-8))

(defun read-project-sources (&key texts extra)
  "Read each source page of +SOURCES+ once. TEXTS, an alist (ROLE . STRING), replaces a page's text (for tests); its digest is
then the digest of that text. EXTRA, a list of plists (:ROLE :BOOK :TITLE :KIND :PATH :TEXT), adds sources that are not sources of the
project CTM: a draft page read to show what it would state, or a synthetic test fixture. Reads only."
  (make-instance
   'project-sources
   :observed-at (get-universal-time)
   :items (append
           (loop for (role book title kind) in +sources+
                collect (let* ((page (hyperbook:find-page (hyperbook:find-hyperbook book :signal-error? t) title :signal-error? t))
                               (pathname (hyperdoc:file-of page))
                               (given (cdr (assoc role texts)))
                               (octets (if given (%utf8 given) (%octets pathname))))
                          (make-instance 'source-item :role role :hyperbook-id book :title title :kind kind :page page
                                                      :path (repository-path pathname) :sha256 (%sha256 octets)
                                                      :text (or given (sb-ext:octets-to-string octets :external-format :utf-8)))))
           (loop for item in extra
                 collect (let ((text (getf item :text)))
                           (make-instance 'source-item :role (getf item :role) :hyperbook-id (getf item :book) :title (getf item :title)
                                                       :kind (getf item :kind) :path (getf item :path) :sha256 (%sha256 (%utf8 text)) :text text
                                                       :page (let ((book (hyperbook:find-hyperbook (getf item :book))))
                                                               (and book (hyperbook:find-page book (getf item :title) :signal-error? nil)))))))))
(defun source (sources role) (find role (sources-items sources) :key #'source-role))
(defun source-page-iri (item) (page-iri (source-hyperbook-id item) (source-title item)))

;;; The model: what the sources declare, before it is written

(defclass work-declaration ()
  ((id :initarg :id :reader declaration-id)
   (label :initarg :label :reader declaration-label)
   (kind :initarg :kind :reader declaration-kind)
   (status :initarg :status :reader declaration-status)
   (text :initarg :text :reader declaration-text)
   (carrier :initarg :carrier :reader declaration-carrier)     ; (hyperbook-id . title)
   (source :initarg :source :reader declaration-source)        ; SOURCE-ITEM
   (occurrence :initarg :occurrence :initform nil :reader declaration-occurrence)
   (proposal :initarg :proposal :initform nil :reader declaration-proposal-p))
  (:documentation "A Work Topic declaration, or a proposal of one, on one source page."))
(defclass statement ()
  ((from :initarg :from :reader statement-from)
   (relation :initarg :relation :reader statement-relation)
   (to :initarg :to :reader statement-to)
   (number :initarg :number :reader statement-number)
   (source :initarg :source :reader statement-source)
   (occurrence :initarg :occurrence :initform nil :reader statement-occurrence)
   (proposal :initarg :proposal :initform nil :reader statement-proposal-p))
  (:documentation "An authored statement <li data-from data-relation data-to>, or a proposed one, on one source page."))
(defclass assignment ()
  ((id :initarg :id :reader assignment-id)
   (title :initarg :title :reader assignment-title)
   (fields :initarg :fields :reader assignment-fields)         ; alist name -> text
   (refs :initarg :refs :reader assignment-refs)               ; alist name -> data-ref
   (lists :initarg :lists :reader assignment-lists)            ; alist name -> list of (text . attributes plist)
   (source :initarg :source :reader assignment-source)))
(defclass gap ()
  ((rule :initarg :rule :reader gap-rule)
   (key :initarg :key :reader gap-key)
   (name :initarg :name :reader gap-name)
   (text :initarg :text :reader gap-text)
   (subjects :initarg :subjects :reader gap-subjects)))        ; subject IRIs
(defclass project-model ()
  ((sources :initarg :sources :reader model-sources)
   (declarations :initarg :declarations :reader model-declarations)
   (statements :initarg :statements :reader model-statements)
   (entries :initarg :entries :reader model-declared-entries)                                ; ((entry . source-item) ...)
   (assignments :initarg :assignments :reader model-assignments)
   (gaps :initarg :gaps :accessor model-gaps)
   (bridges :initarg :bridges :reader model-bridges)
   (evidence-inputs :initarg :evidence-inputs :reader model-evidence-inputs)
   (evidence-entries :initarg :evidence-entries :initform nil :reader model-evidence-entries)       ; identified, of all assignments
   (proposed-entries :initarg :proposed-entries :initform nil :reader model-proposed-entries) ; ((entry . source-item) ...)
   (acceptance :initarg :acceptance :initform nil :reader model-acceptance)                  ; acceptance-source or NIL
   (text :initarg :text :accessor model-text))
  (:documentation "What the source pages declare, read once, and the CTM text written from it."))

(defmethod v:text-representation ((d work-declaration))
  (format nil "~:[Declaration~;Proposal~] ~A (~A)" (declaration-proposal-p d) (declaration-id d) (declaration-kind d)))
(defmethod v:text-representation ((s statement))
  (format nil "~:[Statement~;Proposed statement~] ~A ~A ~A" (statement-proposal-p s) (statement-from s) (statement-relation s) (statement-to s)))
(defmethod v:text-representation ((m project-model)) "The declared project work, as read for the CTM")
(defun model-proposals (model) (remove-if-not #'declaration-proposal-p (model-declarations model)))
(defun model-entries (model)
  "The entries of the declared WBS Dictionaries, in source order."
  (mapcar #'car (model-declared-entries model)))

(defun declaration-page-iri (d) (source-page-iri (declaration-source d)))
(defun statement-page-iri (s) (source-page-iri (statement-source s)))
(defun statement-iri (s)
  (let ((item (statement-source s)))
    (%iri "statement" (source-hyperbook-id item) (slug (source-title item))
          (statement-from s) (statement-relation s) (statement-to s) (princ-to-string (statement-number s)))))

(defun %dom (text) (let ((plump:*tag-dispatchers* plump:*html-tags*)) (plump:parse text)))
(defun %squash (string)
  "STRING with each run of whitespace one space, trimmed: the text of an element as a reader sees it."
  (let ((out (with-output-to-string (s)
               (let ((space nil))
                 (loop for c across string
                       do (if (member c '(#\Space #\Tab #\Newline #\Return #\Page))
                              (setf space t)
                              (progn (when space (write-char #\Space s)) (setf space nil) (write-char c s))))))))
    (string-trim " " out)))
(defun %text (node) (%squash (plump:decode-entities (plump:text node))))
(defun %enclosing-text (node)
  "The text of the nearest enclosing li or p of NODE: the authored sentence a declaration stands in."
  (loop for parent = (plump:parent node) then (plump:parent parent)
        while (and parent (plump:element-p parent))
        when (member (plump:tag-name parent) '("li" "p") :test #'string-equal) return (%text parent)
        finally (return (%text node))))
(defun %anchors (text attribute)
  (remove-if-not (lambda (node) (plump:attribute node attribute)) (plump:get-elements-by-tag-name (%dom text) "a")))
(defun %items (text attribute)
  (remove-if-not (lambda (node) (plump:attribute node attribute)) (plump:get-elements-by-tag-name (%dom text) "li")))
(defun %carrier (node) (cons (or (plump:attribute node "hyperbook") "dreyeck/work/reading") (plump:attribute node "page")))

(defun %number-statements (statements)
  "Number equal statements of one page in authored order, so that two equal statements stay two."
  (let ((seen (make-hash-table :test #'equal)))
    (dolist (s statements statements)
      (setf (slot-value s 'number)
            (incf (gethash (list (statement-source s) (statement-from s) (statement-relation s) (statement-to s)) seen 0))))))

(defun %read-work-source (item)
  "The declarations and statements of one Work page, read with the ordinary Work reader; carriers and sentences from the same text.
A source that is no page of a HyperBook (a test fixture) has its carriers named, not looked up."
  (let* ((projection (apply #'work:project-work-breakdown (source-text item) :source (source-page item)
                            (unless (source-page item) (list :find-page (lambda (title book) (declare (ignore title book)) nil)))))
         (topics (tm:topicmap-projection-topics-of projection))
         (anchors (%anchors (source-text item) "data-topic"))
         (bridges (getf (tm:topicmap-projection-view-properties-of projection) :qualified-bridges)))
    (unless (and (= (length topics) (length anchors))
                 (every (lambda (topic node) (equal (tm:topicmap-topic-id-of topic) (plump:attribute node "data-topic"))) topics anchors))
      (refuse "the Work reader and the page text of ~A disagree about its declarations" (source-path item)))
    (values
     (loop for topic in topics for node in anchors
           for properties = (tm:topicmap-topic-view-properties-of topic)
           collect (make-instance 'work-declaration :id (tm:topicmap-topic-id-of topic) :label (tm:topicmap-topic-label-of topic)
                                               :kind (getf properties :kind) :status (getf properties :status)
                                               :text (%enclosing-text node) :carrier (%carrier node) :source item
                                               :occurrence (work:topic-source-occurrence topic)))
     (loop for association in (tm:topicmap-projection-associations-of projection)
           collect (make-instance 'statement :from (tm:topicmap-association-from-of association)
                                             :relation (tm:topicmap-association-type-of association)
                                             :to (tm:topicmap-association-to-of association) :source item
                                             :occurrence (getf (tm:topicmap-association-properties-of association) :source-occurrence)))
     bridges)))

(defparameter +entry-attributes+
  '("data-reads" "data-changes" "data-test" "data-evidence" "data-repository" "data-revision" "data-tree" "data-content"
    "data-observation" "data-observed-at")
  "The attributes of an assignment's list entry that are kept: a source authority it reads or changes, a test it names, and an
evidence entry's identity and the facts of the run it reports.")
(defun %read-assignments (item)
  "Proposals, proposed statements and assignments of the page Implementation Assignments."
  (let* ((text (source-text item)) (dom (%dom text)))
    (values
     (loop for node in (%anchors text "data-proposed-topic")
           collect (make-instance 'work-declaration :id (plump:attribute node "data-proposed-topic") :label (%text node)
                                               :kind (plump:attribute node "data-kind") :status nil :proposal t
                                               :text (%enclosing-text node) :carrier (%carrier node) :source item))
     (loop for node in (%items text "data-proposed-from")
           collect (make-instance 'statement :from (plump:attribute node "data-proposed-from")
                                             :relation (plump:attribute node "data-proposed-relation")
                                             :to (plump:attribute node "data-proposed-to") :source item :proposal t))
     (loop for section in (plump:get-elements-by-tag-name dom "section")
           for id = (plump:attribute section "data-assignment")
           when id
             collect (let ((fields nil) (refs nil) (lists nil))
                       (labels ((walk (node)
                                  (loop for child across (plump:children node)
                                        when (plump:element-p child)
                                          do (let ((field (plump:attribute child "data-field")))
                                               (cond ((and field (string-equal (plump:tag-name child) "ul"))
                                                      (push (cons field (loop for li across (plump:children child)
                                                                              when (and (plump:element-p li) (string-equal (plump:tag-name li) "li"))
                                                                                collect (cons (%text li)
                                                                                              (loop for a in +entry-attributes+
                                                                                                    when (plump:attribute li a)
                                                                                                      append (list (intern (string-upcase a) :keyword)
                                                                                                                   (plump:attribute li a))))))
                                                            lists))
                                                     (field (push (cons field (%text child)) fields)
                                                            (when (plump:attribute child "data-ref") (push (cons field (plump:attribute child "data-ref")) refs)))
                                                     (t (walk child)))))))
                         (walk section))
                       (make-instance 'assignment :id id :source item
                                                  :title (let ((h (first (plump:get-elements-by-tag-name section "h3")))) (if h (%text h) id))
                                                  :fields (nreverse fields) :refs (nreverse refs) :lists (nreverse lists)))))))

(defclass evidence-input ()
  ((path :initarg :path :reader evidence-path)
   (sha256 :initarg :sha256 :reader evidence-sha256)
   (text :initarg :text :reader evidence-text))
  (:documentation "A repository file the emitter reads besides the source pages: the test file a WBS Dictionary control names,
read once to derive whether it contains the control's marker. NIL digest and text: the file is absent."))
(defun read-evidence-inputs (entries)
  "The test files the controls of ENTRIES name, each read once, in dictionary order. These and the source pages are the only
files the emitter reads; a file an assignment merely names is never read."
  (let ((inputs nil))
    (dolist (entry entries (nreverse inputs))
      (dolist (control (plan::entry-controls entry))
        (let ((path (plan::control-test control)))
          (when (and path (not (find path inputs :key #'evidence-path :test #'equal)))
            (let* ((pathname (merge-pathnames path (repository-root)))
                   (octets (and (probe-file pathname) (%octets pathname))))
              (push (make-instance 'evidence-input :path path :sha256 (and octets (%sha256 octets))
                                                   :text (and octets (sb-ext:octets-to-string octets :external-format :utf-8)))
                    inputs))))))))

;;; Evidence entries: an assignment's evidence, identified so that a record can name it

(defparameter +repository+ "codeberg.org/rgb/hyperdoc"
  "This repository as an execution report names it in data-repository: a name, from which nothing is fetched.")
(defparameter +run-facts+ '(:data-repository :data-revision :data-tree :data-observation :data-observed-at)
  "What an execution report states of its run besides its test. data-content, an immutable content reference, is optional.")
(defparameter +tree-states+ '("clean" "modified"))
(defparameter +xsd-datetime+ "http://www.w3.org/2001/XMLSchema#dateTime")

(defclass evidence-entry ()
  ((id :initarg :id :reader entry-id)
   (assignment :initarg :assignment :reader entry-assignment)
   (text :initarg :text :reader entry-text)
   (attributes :initarg :attributes :reader entry-attributes))        ; the kept attributes of the entry, a plist
  (:documentation "One entry of an assignment's evidence that has an authored data-evidence, so that a record can name it. With
data-test it reports one run of that test as the executor reports it: the CTM states the report, not that the run happened, and the
test file stays a program. An entry without data-evidence stays an evidence note and cannot be named."))
(defmethod v:text-representation ((e evidence-entry)) (format nil "Evidence entry ~A" (entry-key e)))
(defun entry-key (e) (format nil "~A/~A" (assignment-id (entry-assignment e)) (entry-id e)))
(defun entry-iri (e) (%iri "evidence" (assignment-id (entry-assignment e)) (entry-id e)))
(defun entry-fact (e key) (getf (entry-attributes e) key))
(defun entry-execution-p (e) (and (entry-fact e :data-test) t))
(defun entry-reconstruction (e)
  "Whether the tested tree can be rebuilt from what the report records; derived from its tree state and content reference."
  (cond ((equal "clean" (entry-fact e :data-tree)) "reconstructible from the tested revision")
        ((entry-fact e :data-content) "reconstructible from the content reference, not from the tested revision alone")
        (t "not fully reconstructible from the recorded revision: the tree was modified and no immutable content reference is recorded")))
(defun %revision-p (string)
  (and (stringp string) (<= 7 (length string) 40) (every (lambda (c) (find c "0123456789abcdef")) string)))

(defun read-evidence-entries (assignment)
  "The identified evidence entries of ASSIGNMENT, in page order. Refused: facts of a run on an entry without data-evidence or without a
test, an incomplete execution report, and an ID or a text that two entries share (in TMDM equal entries are one occurrence)."
  (let ((evidence (cdr (assoc "evidence" (assignment-lists assignment) :test #'equal))) (id (assignment-id assignment)) (entries nil))
    (dolist (entry evidence (nreverse entries))
      (destructuring-bind (text . attributes) entry
        (let ((key (getf attributes :data-evidence))
              (facts (loop for k in (cons :data-content +run-facts+) when (getf attributes k) collect k)))
          (cond ((null key)
                 (when facts (refuse "assignment ~A: the evidence entry ~S states facts of a run and has no data-evidence" id text)))
                (t (when (find key entries :key #'entry-id :test #'equal) (refuse "assignment ~A has two evidence entries ~A" id key))
                   (when (< 1 (count text evidence :key #'car :test #'equal))
                     (refuse "assignment ~A: the evidence entry ~A has the text of another entry; in TMDM they would be one occurrence" id key))
                   (cond ((getf attributes :data-test)
                          (dolist (k +run-facts+)
                            (unless (getf attributes k) (refuse "assignment ~A: the execution report ~A has no ~(~A~)" id key k)))
                          (unless (member (getf attributes :data-tree) +tree-states+ :test #'equal)
                            (refuse "assignment ~A: the execution report ~A has the tree state ~S, not clean or modified" id key (getf attributes :data-tree)))
                          (when (and (equal "clean" (getf attributes :data-tree)) (getf attributes :data-content))
                            (refuse "assignment ~A: the execution report ~A names a content reference for a clean tree" id key))
                          (unless (%revision-p (getf attributes :data-revision))
                            (refuse "assignment ~A: the execution report ~A has the revision ~S, not a commit (7 to 40 lowercase hex digits)"
                                    id key (getf attributes :data-revision)))
                          (unless (%datetime-p (getf attributes :data-observed-at))
                            (refuse "assignment ~A: the execution report ~A: observed-at ~S is not a UTC xsd:dateTime YYYY-MM-DDThh:mm:ssZ"
                                    id key (getf attributes :data-observed-at))))
                         (facts (refuse "assignment ~A: the evidence entry ~A states facts of a run and names no test" id key)))
                   (push (make-instance 'evidence-entry :id (%identifier-part key) :assignment assignment :text text :attributes attributes)
                         entries))))))))

;;; Acceptance records: judgments and withdrawals on declared work packages, by an authority the records page declares

(defclass acceptance-source ()
  ((source :initarg :source :reader acceptance-source-item)
   (authorities :initarg :authorities :reader acceptance-authorities)  ; ((id . name) ...)
   (records :initarg :records :reader acceptance-records)))           ; in page order
(defclass acceptance-record ()
  ((id :initarg :id :reader record-id)
   (title :initarg :title :reader record-title)
   (package :initarg :package :reader record-package)
   (criterion :initarg :criterion :initform nil :reader record-criterion)   ; the data-ref of its criterion; NIL for a withdrawal
   (revision :initarg :revision :initform nil :reader record-revision)      ; "sha256-<hex>"; NIL for a withdrawal
   (decision :initarg :decision :reader record-decision)                    ; "accepted", "rejected", or "withdrawn" for a withdrawal
   (decided-at :initarg :decided-at :reader record-decided-at)
   (authority :initarg :authority :reader record-authority)
   (evidence :initarg :evidence :initform nil :reader record-evidence)      ; ("<assignment>/<entry>" ...)
   (supersedes :initarg :supersedes :initform nil :reader record-supersedes) ; record IDs
   (text :initarg :text :reader record-text))
  (:documentation "One record of an Acceptance Records page. A judgment, accepted or rejected, decides on one declared work package
against an explicitly named revision of its WBS Dictionary criterion, by a declared authority, at a time, on named evidence entries. A
withdrawal judges nothing: it supersedes earlier records of its package and names no criterion and no evidence. A record is never
changed; a correction supersedes. No test result or executor report makes one."))
(defparameter +decisions+ '("accepted" "rejected") "The judgments a record can state. Anything else is refused.")
(defun record-withdrawal-p (r) (equal "withdrawn" (record-decision r)))
(defun record-iri (r) (%iri "acceptance" (record-id r)))
(defun criterion-revision (text)
  "The revision of an acceptance criterion with the occurrence value TEXT: sha256- and the SHA-256 of its UTF-8 octets."
  (format nil "sha256-~A" (%sha256 (%utf8 text))))
(defun criterion-iri (package revision) (%iri "criterion" package revision))
(defun entry-revisions (entry)
  "The criterion revisions of the dictionary ENTRY, ((revision text current-p) ...): the current one, then the retained ones."
  (cons (list (criterion-revision (plan::entry-field entry "acceptance")) (plan::entry-field entry "acceptance") t)
        (mapcar (lambda (text) (list (criterion-revision text) text nil)) (plan::entry-retained-criteria entry))))

(defun %datetime-p (string)
  (and (stringp string) (= 20 (length string)) (char= #\T (char string 10)) (char= #\Z (char string 19))
       (every #'digit-char-p (remove-if (lambda (c) (find c "-:TZ")) string))))

(defun read-acceptance-records (item)
  "The authorities and records of the page ITEM. A record that lacks an explicit decision or disposition, time, authority, work package,
or, for a judgment, criterion revision or evidence is refused: no record is made of an incomplete statement. A whole assignment or a test
file named as considered evidence is refused: a record names evidence entries."
  (let* ((dom (%dom (source-text item)))
         (authorities (loop for node in (%anchors (source-text item) "data-authority")
                            collect (cons (plump:attribute node "data-authority") (%text node))))
         (records
           (loop for section in (plump:get-elements-by-tag-name dom "section")
                 for id = (plump:attribute section "data-acceptance-record")
                 when id
                   collect (let ((fields nil) (evidence nil) (supersedes nil))
                             (labels ((items (node) (loop for li across (plump:children node)
                                                          when (and (plump:element-p li) (string-equal (plump:tag-name li) "li")) collect li))
                                      (walk (node)
                                        (loop for child across (plump:children node)
                                              when (plump:element-p child)
                                                do (let ((field (plump:attribute child "data-field")))
                                                     (cond ((equal field "considered-evidence")
                                                            (dolist (li (items child))
                                                              (cond ((plump:attribute li "data-evidence") (push (plump:attribute li "data-evidence") evidence))
                                                                    ((plump:attribute li "data-assignment")
                                                                     (refuse "record ~A considers the whole assignment ~A; a record names evidence entries (data-evidence)"
                                                                             id (plump:attribute li "data-assignment")))
                                                                    ((plump:attribute li "data-test")
                                                                     (refuse "record ~A considers the test file ~A, a program and not observed evidence; a record names evidence entries (data-evidence)"
                                                                             id (plump:attribute li "data-test")))
                                                                    (t (refuse "record ~A names evidence without data-evidence" id)))))
                                                           ((equal field "supersedes")
                                                            (dolist (li (items child))
                                                              (push (or (plump:attribute li "data-record") (refuse "record ~A supersedes an entry without data-record" id))
                                                                    supersedes)))
                                                           (field (when (assoc field fields :test #'equal) (refuse "record ~A states ~A twice" id field))
                                                                  (push (cons field child) fields))
                                                           (t (walk child)))))))
                               (walk section))
                             (flet ((node (field) (cdr (assoc field fields :test #'equal)))
                                    (attribute (field name)
                                      (let ((node (cdr (assoc field fields :test #'equal))))
                                        (or (and node (plump:attribute node name))
                                            (refuse "record ~A has no ~A (~A)" id field name)))))
                               (let ((judgment (node "decision")) (disposition (node "disposition")))
                                 (when (and judgment disposition) (refuse "record ~A states both a decision and a disposition" id))
                                 (unless (or judgment disposition) (refuse "record ~A has no decision (decision, data-decision) and no disposition" id))
                                 (let ((decision (if judgment (attribute "decision" "data-decision") (attribute "disposition" "data-disposition")))
                                       (at (attribute "decided-at" "data-datetime")))
                                   (if judgment
                                       (unless (member decision +decisions+ :test #'equal)
                                         (refuse "record ~A states the decision ~S, not one of ~{~A~^, ~}" id decision +decisions+))
                                       (unless (equal decision "withdrawn")
                                         (refuse "record ~A states the disposition ~S; the one disposition is withdrawn" id decision)))
                                   (unless (%datetime-p at) (refuse "record ~A: decided-at ~S is not a UTC xsd:dateTime YYYY-MM-DDThh:mm:ssZ" id at))
                                   (if judgment
                                       (unless evidence (refuse "record ~A names no evidence" id))
                                       (progn (when (node "criterion") (refuse "record ~A withdraws and names a criterion; a withdrawal asserts no criterion satisfaction" id))
                                              (when evidence (refuse "record ~A withdraws and considers evidence; a withdrawal judges nothing" id))
                                              (unless supersedes (refuse "record ~A withdraws and supersedes no earlier record" id))))
                                   (make-instance 'acceptance-record
                                                  :id (%identifier-part id) :title (let ((h (first (plump:get-elements-by-tag-name section "h3")))) (if h (%text h) id))
                                                  :package (attribute "work-package" "data-ref")
                                                  :criterion (and judgment (attribute "criterion" "data-ref"))
                                                  :revision (and judgment (attribute "criterion" "data-revision"))
                                                  :decision decision :decided-at at :authority (attribute "authority" "data-ref")
                                                  :evidence (nreverse evidence) :supersedes (nreverse supersedes) :text (%text section)))))))))
    (loop for (pair . more) on authorities
          when (assoc (car pair) more :test #'equal) do (refuse "the Acceptance Records page declares the authority ~A twice" (car pair)))
    (make-instance 'acceptance-source :source item :authorities authorities :records records)))

(defun %declared-entry (model package)
  "The entry of PACKAGE in a declared WBS Dictionary, and the source item of that dictionary."
  (let ((pair (find package (model-declared-entries model) :key (lambda (e) (plan::entry-element-id (car e))) :test #'equal)))
    (values (car pair) (cdr pair))))
(defun model-evidence-entry (model key) (find key (model-evidence-entries model) :key #'entry-key :test #'equal))
(defun %elements (text)
  (let ((out nil))
    (labels ((walk (node) (loop for child across (plump:children node) when (plump:element-p child) do (push child out) (walk child))))
      (walk (%dom text)))
    out))

(defun check-acceptance-records (model)
  "Only an Acceptance Records page states records. Every record decides on a declared work package with an entry in a declared WBS
Dictionary, by an authority its page declares. A judgment applies a revision of that package's criterion that the entry states or
retains, and considers evidence entries an assignment identifies. Every record a record supersedes is an earlier record on the same
package; page order, not time, rules out cycles."
  (dolist (item (sources-items (model-sources model)))
    (unless (eq :acceptance-records (source-kind item))
      (let ((elements (%elements (source-text item))))
        (dolist (attribute '("data-acceptance-record" "data-decision" "data-disposition"))
          (when (find-if (lambda (node) (plump:attribute node attribute)) elements)
            (refuse "~A states ~A; only an Acceptance Records page states a record" (source-path item) attribute))))))
  (let ((acceptance (model-acceptance model)))
    (when acceptance
      (let ((records (acceptance-records acceptance)))
        (loop for (r . more) on records
              when (find (record-id r) more :key #'record-id :test #'equal) do (refuse "the page states the record ~A twice" (record-id r)))
        (loop for r in records for position from 0
              for package = (record-package r)
              for declarations = (%declared model package)
              do (cond ((null declarations) (refuse "record ~A decides on ~A, which no page declares" (record-id r) package))
                       ((every #'declaration-proposal-p declarations)
                        (refuse "record ~A decides on ~A, which is proposed, not declared; a proposed requirement cannot be accepted" (record-id r) package)))
                 (let ((entry (%declared-entry model package)))
                   (unless entry
                     (refuse "record ~A: ~A has no entry in a declared WBS Dictionary~:[~;; a draft dictionary only proposes requirements~]" (record-id r) package
                             (find package (model-proposed-entries model) :key (lambda (e) (plan::entry-element-id (car e))) :test #'equal)))
                   (unless (record-withdrawal-p r)
                     (unless (equal (record-criterion r) package)
                       (refuse "record ~A applies the criterion of ~A to ~A" (record-id r) (record-criterion r) package))
                     (unless (find (record-revision r) (entry-revisions entry) :key #'first :test #'equal)
                       (refuse "record ~A applies the criterion revision ~A of ~A, which its dictionary entry neither states nor retains"
                               (record-id r) (record-revision r) package))))
                 (unless (assoc (record-authority r) (acceptance-authorities acceptance) :test #'equal)
                   (refuse "record ~A: the authority ~A is not declared on the Acceptance Records page" (record-id r) (record-authority r)))
                 (dolist (key (record-evidence r))
                   (unless (model-evidence-entry model key)
                     (refuse "record ~A considers the evidence entry ~A, which no assignment identifies" (record-id r) key)))
                 (dolist (target (record-supersedes r))
                   (let ((at (position target records :key #'record-id :test #'equal)))
                     (cond ((null at) (refuse "record ~A supersedes ~A, which the page does not record" (record-id r) target))
                           ((= at position) (refuse "record ~A supersedes itself" (record-id r)))
                           ((> at position) (refuse "record ~A supersedes ~A, which comes later on the page" (record-id r) target))
                           ((not (equal package (record-package (nth at records))))
                            (refuse "record ~A on ~A supersedes ~A, a record on ~A" (record-id r) package target (record-package (nth at records))))))))))))

(defun unsuperseded-records (acceptance package)
  "The records on PACKAGE that no record supersedes, in page order. No time enters: precedence is only supersedes."
  (let* ((records (remove package (acceptance-records acceptance) :key #'record-package :test-not #'equal))
         (superseded (loop for r in records append (record-supersedes r))))
    (remove-if (lambda (r) (member (record-id r) superseded :test #'equal)) records)))

(defun build-project-model (&optional (sources (read-project-sources)))
  "Read the declarations of SOURCES and write the CTM text. Signals PROJECT-CTM-REFUSED, or a Work source error. Writes nothing."
  (let ((declarations nil) (statements nil) (bridges nil) (entries nil) (assignments nil) (proposed-entries nil) (acceptance nil))
    (dolist (item (sources-items sources))
      (ecase (source-kind item)
        (:proposed-dictionary (dolist (entry (plan::read-wbs-dictionary (source-text item)))
                                (setf proposed-entries (append proposed-entries (list (cons entry item))))))
        (:acceptance-records (when acceptance (refuse "two Acceptance Records sources"))
                             (setf acceptance (read-acceptance-records item)))
        (:work (multiple-value-bind (d s b) (%read-work-source item)
                 (setf declarations (append declarations d) statements (append statements s) bridges (append bridges b))))
        (:dictionary (dolist (entry (plan::read-wbs-dictionary (source-text item)))
                       (setf entries (append entries (list (cons entry item))))))
        (:assignments (multiple-value-bind (d s a) (%read-assignments item)
                        (setf declarations (append declarations d) statements (append statements s) assignments a)))))
    (%number-statements statements)
    ;; Every dictionary of kind :dictionary is declared, a draft one proposes; one work package has one entry among all of them.
    (loop for (id . more) on (mapcar (lambda (e) (plan::entry-element-id (car e))) (append entries proposed-entries))
          when (member id more :test #'equal) do (refuse "two WBS Dictionary entries for ~A" id))
    (let ((model (make-instance 'project-model :sources sources :declarations declarations :statements statements
                                               :entries entries :assignments assignments :bridges bridges
                                               :evidence-entries (loop for a in assignments append (read-evidence-entries a))
                                               :proposed-entries proposed-entries :acceptance acceptance
                                               :evidence-inputs (read-evidence-inputs (mapcar #'car (append entries proposed-entries))))))
      (check-acceptance-records model)
      (setf (model-gaps model) (derive-gaps model))
      (setf (model-text model) (write-model model))
      model)))

;;; Gaps: where the declarations do not say enough. Derived here, each with its rule; none adds a relation.

(defun %declared (model id &key (proposals t))
  (remove-if-not (lambda (d) (and (equal id (declaration-id d)) (or proposals (not (declaration-proposal-p d))))) (model-declarations model)))
(defun %relates-p (model a b)
  (find-if (lambda (s) (or (and (equal a (statement-from s)) (equal b (statement-to s)))
                           (and (equal b (statement-from s)) (equal a (statement-to s)))))
           (model-statements model)))
(defparameter +planning-contracts+ '("work:relation/decomposes-into" "work:relation/depends-on" "work:relation/produces"))

(defun derive-gaps (model)
  (let ((gaps nil) (declarations (model-declarations model)))
    (flet ((gap (rule key name text &rest subjects)
             (push (make-instance 'gap :rule rule :key key :name name :text text :subjects subjects) gaps)))
      (dolist (w (remove "work item" declarations :key #'declaration-kind :test-not #'equal))
        (let ((deliverables (remove-if-not (lambda (d) (and (equal "deliverable" (declaration-kind d))
                                                            (equal (declaration-carrier d) (declaration-carrier w))))
                                           declarations)))
          (dolist (d deliverables)
            (unless (%relates-p model (declaration-id w) (declaration-id d))
              (gap "work-item-deliverable-unlinked" (format nil "~A/~A" (declaration-id w) (declaration-id d))
                   (format nil "~A and ~A share only their carrier page" (declaration-id w) (declaration-id d))
                   "A Work Item and a Deliverable name the same carrier page, and no statement relates them. No Relation Contract defines that relation."
                   (topic-iri (declaration-id w)) (topic-iri (declaration-id d)))))
          (unless (or deliverables (declaration-proposal-p w)
                      (find-if (lambda (s) (and (member (statement-relation s) +planning-contracts+ :test #'equal)
                                                (member (declaration-id w) (list (statement-from s) (statement-to s)) :test #'equal)))
                               (model-statements model)))
            (gap "work-item-without-breakdown" (declaration-id w)
                 (format nil "~A has no declared breakdown or plan" (declaration-id w))
                 "No statement decomposes, plans or produces anything for this Work Item, and no Deliverable shares its carrier page."
                 (topic-iri (declaration-id w))))))
      (dolist (a (model-assignments model))
        (unless (cdr (assoc "plan-step" (assignment-refs a) :test #'equal))
          (gap "assignment-without-plan-step" (assignment-id a) (format nil "~A has no confirmed Plan Step" (assignment-id a))
               "The assignment names no confirmed Plan Step. Its own text cannot declare one."
               (%iri "assignment" (assignment-id a)))))
      (let ((used (remove-duplicates (mapcar #'statement-relation (remove-if #'statement-proposal-p (model-statements model))) :test #'equal)))
        (dolist (relation used)
          (if (%contract-p relation)
              (when (find "draft" (%declared model relation :proposals nil) :key #'declaration-status :test #'equal)
                (gap "draft-contract-in-use" relation (format nil "~A is draft and in use" relation)
                     "Statements use this Relation Contract while its declared status is draft."
                     (topic-iri relation)))
              (gap "uncontracted-relation-word" (format nil "word-~A" (slug relation))
                   (format nil "~A is a relation word without a contract" relation)
                   "Statements use this relation word, which no Relation Contract defines. Its source and target Roles carry no stated meaning."
                   (relation-type-iri relation)))))
      ;; Acceptance, per entry of a declared dictionary. Which record is in force follows only from supersedes, never from a time.
      (let ((acceptance (model-acceptance model)))
        (dolist (entry (model-entries model))
          (let* ((id (plan::entry-element-id entry)) (package (topic-iri id))
                 (open (and acceptance (unsuperseded-records acceptance id))) (record (first open)))
            (cond ((null acceptance)
                   (gap "acceptance-not-recordable" id
                        (format nil "~A: acceptance criterion without an acceptance record" id)
                        "The WBS Dictionary states an acceptance criterion for this work package. No page can record that the result was accepted; a work status is not an acceptance."
                        package))
                  ((null open)
                   (gap "acceptance-not-recorded" id
                        (format nil "~A: no acceptance recorded" id)
                        "A WBS Dictionary states an acceptance criterion for this work package, and the Acceptance Records page records no decision on it. Evidence of an assignment is not an acceptance."
                        package))
                  ((rest open)
                   (apply #'gap "acceptance-records-in-conflict" id
                          (format nil "~A: ~D acceptance records in conflict" id (length open))
                          "Two or more records on this work package are superseded by no record, so none of them is in force, whatever their times. A record that supersedes all of them resolves the conflict."
                          package (mapcar #'record-iri open)))
                  ((record-withdrawal-p record)
                   (gap "acceptance-withdrawn" id
                        (format nil "~A: acceptance withdrawn" id)
                        "The record in force on this work package is a withdrawal: it withdraws the records it supersedes and judges nothing. No decision is in force."
                        package (record-iri record)))
                  ((not (third (find (record-revision record) (entry-revisions entry) :key #'first :test #'equal)))
                   (gap "decision-under-retained-criterion" id
                        (format nil "~A: ~A under a retained criterion" id (record-decision record))
                        "The decision in force applied a revision of the acceptance criterion that the WBS Dictionary retains and no longer states as current. The decision stays in force; only a new record decides against the current criterion."
                        package (record-iri record) (criterion-iri id (record-revision record)))))))
        (loop for pair in (model-proposed-entries model)
              for id = (plan::entry-element-id (car pair))
              do (gap "acceptance-requires-declaration" id
                      (format nil "~A: proposed requirement" id)
                      "A draft WBS Dictionary proposes requirements for this proposed work package. No record can decide on it until it is declared and its entry is part of a declared WBS Dictionary."
                      (topic-iri id))))
      (dolist (p (model-proposals model))
        (when (%declared model (declaration-id p) :proposals nil)
          (gap "proposal-already-declared" (declaration-id p) (format nil "~A is proposed and declared" (declaration-id p))
               "A proposal names an ID that a Work page already declares. The declaration is authoritative; the proposal is stale."
               (topic-iri (declaration-id p)))))
      (when (model-bridges model)
        (gap "qualified-bridge-not-materialized" "work-breakdown" "Qualified addresses bridges are not materialized"
             "The Work Breakdown has qualified addresses bridges, which this emitter does not write."
             (source-page-iri (source (model-sources model) :work-breakdown)))))
    (nreverse gaps)))

;;; The CTM text

(defclass ctm-topic () ((iri :initarg :iri :reader ct-iri) (types :initform nil :accessor ct-types)
                        (names :initform nil :accessor ct-names) (occurrences :initform nil :accessor ct-occurrences)))
(defclass ctm-builder () ((topics :initform (make-hash-table :test #'equal) :reader b-topics)
                          (schema :initform nil :accessor b-schema) (order :initform nil :accessor b-order)
                          (paged :initform (make-hash-table :test #'equal) :reader b-paged)
                          (associations :initform nil :accessor b-associations)))

(defun %topic (b iri &key name type schema)
  (let ((topic (or (gethash iri (b-topics b))
                   (let ((new (make-instance 'ctm-topic :iri iri)))
                     (if schema (push new (b-schema b)) (push new (b-order b)))
                     (setf (gethash iri (b-topics b)) new)))))
    (when (and name (not (member name (ct-names topic) :test #'string=))) (setf (ct-names topic) (append (ct-names topic) (list name))))
    (when (and type (not (member type (ct-types topic) :test #'string=))) (setf (ct-types topic) (append (ct-types topic) (list type))))
    iri))
(defun %occurrence (b iri type value &optional datatype)
  "Add the occurrence TYPE VALUE to the Topic IRI, once. DATATYPE, if given, is written as ^^<DATATYPE>; otherwise a string."
  (when value
    (let ((topic (gethash iri (b-topics b))) (entry (list type (princ-to-string value) datatype nil)))
      (unless (member entry (ct-occurrences topic) :test (lambda (a b) (equal (subseq a 0 2) (subseq b 0 2))))
        (setf (ct-occurrences topic) (append (ct-occurrences topic) (list entry)))))))
(defun %reify-occurrence (b iri type reifier &optional value)
  "Let the Topic REIFIER reify the occurrence TYPE of the Topic IRI, with the value VALUE if given, of which there must be exactly one.
An occurrence has at most one reifier."
  (let ((entries (remove-if-not (lambda (o) (and (equal type (first o)) (or (null value) (equal value (second o)))))
                                (ct-occurrences (gethash iri (b-topics b))))))
    (unless (= 1 (length entries)) (refuse "~A has ~D occurrences of ~A to reify, not one" iri (length entries) type))
    (when (and (fourth (first entries)) (not (equal reifier (fourth (first entries)))))
      (refuse "an occurrence ~A of ~A would have two reifiers, ~A and ~A" type iri (fourth (first entries)) reifier))
    (setf (fourth (first entries)) reifier)))
(defun %association (b type roles &optional reifier)
  (push (list type roles reifier) (b-associations b)))

(defparameter +schema+
  ;; name label description
  '(("hyperbook" "HyperBook" "A HyperBook of the HyperDoc Catalog.")
    ("hyperdoc-page" "HyperDoc page" "A page of a HyperBook. Its id in the HyperBook is the occurrence page-id.")
    ("repository-file" "Repository file" "A file of the HyperDoc repository, named by its repository path.")
    ("authored-statement" "Authored statement" "One <li data-from data-relation data-to> on a Work page. It reifies the Association it states.")
    ("proposed-statement" "Proposed statement" "One proposed relation on the page Implementation Assignments. It is not declared.")
    ("planned-control" "Planned control" "A control a WBS Dictionary entry lists for its work package.")
    ("implementation-assignment" "Implementation assignment" "An assignment given to Claude Code, as recorded on the page Implementation Assignments.")
    ("plan-gap" "Plan gap" "Derived by the emitter from the sources by a stated rule: where the declarations do not say enough. A gap states no relation of the Work.")
    ("relation-word" "Relation word" "A relation written as a plain word, which no Relation Contract defines.")
    ("declared-on" "declared on" "The source page declares the Work Topic: a data-topic declaration. Provenance, not a Work relation.")
    ("proposed-on" "proposed on" "The page Implementation Assignments proposes the Topic or statement. Nothing is declared.")
    ("stated-on" "stated on" "The source page states the authored statement.")
    ("carried-by" "carried by" "The declaration names this page as its carrier (the attribute page). Not a Work relation.")
    ("contains-page" "contains page" "The HyperBook has the page.")
    ("defined-in-dictionary" "defined in dictionary" "The WBS Dictionary has an entry for the work package.")
    ("planned-control-of" "planned control of" "The WBS Dictionary entry of the work package lists the control.")
    ("exercised-by" "exercised by" "The control names a test file that exercises it (coverage existing).")
    ("gap-concerns" "gap concerns" "The derived gap concerns the Topic.")
    ("assignment-for" "assignment for" "The assignment names the Work Item it serves.")
    ("assignment-delivers" "assignment delivers" "The assignment names the work package it delivers.")
    ("reads-source" "reads source" "The assignment reads this source authority.")
    ("changes-source" "changes source" "The assignment adds or changes this file.")
    ("evidenced-by-test" "evidenced by test" "The assignment names this test as its evidence.")
    ("declaration" "declaration" nil) ("source-page" "source page" nil) ("proposal" "proposal" nil) ("statement" "statement" nil)
    ("carried" "carried" nil) ("carrier-page" "carrier page" nil) ("hyperbook-role" "hyperbook" nil) ("page" "page" nil)
    ("work-package" "work package" nil) ("control" "control" nil) ("test-file" "test file" nil) ("gap" "gap" nil)
    ("subject" "subject" nil) ("assignment" "assignment" nil) ("work-item" "work item" nil) ("source" "source" nil) ("file" "file" nil)
    ("description" "description" nil)
    ("work-status" "work status" "The data-status of the declaration, verbatim. Not a scope, not provenance, not an acceptance.")
    ("declaration-text" "declaration text" "The authored sentence the declaration stands in, whitespace squashed.")
    ("hyperbook-id" "HyperBook id" nil) ("page-id" "page id" "The page's id in its HyperBook.")
    ("repository-path" "repository path" "The path relative to the root of the HyperDoc repository.")
    ("source-sha256" "source SHA-256" "SHA-256 of the octets this materialization read.")
    ("statement-number" "statement number" "Which of the equal statements on its page this is, counted in authored order.")
    ("wbs-scope" "WBS scope" nil) ("wbs-acceptance-criterion" "WBS acceptance criterion" "A criterion. It records no acceptance.")
    ("wbs-authority" "WBS authority" nil) ("wbs-effect" "WBS effect" nil)
    ("wbs-evidence" "WBS evidence" "The evidence the entry requires. It is not itself an observation.")
    ("control-coverage" "control coverage" nil) ("test-marker" "test marker" nil)
    ("test-marker-found" "test marker found" "Derived: whether the named test file, read as listed in the header, contains the marker text.")
    ("issued" "issued" nil) ("goal" "goal" nil) ("precondition" "precondition" nil) ("acceptance-criterion" "acceptance criterion" nil)
    ("observed-state" "observed state" "What the executor reports. Not an acceptance.") ("acceptance" "acceptance" nil)
    ("plan-step-note" "plan step" nil) ("gap-rule" "gap rule" nil)
    ("source-authority-note" "source authority" "One authored entry of the assignment's source authorities, as written.")
    ("evidence-note" "evidence" "One authored entry of the assignment's evidence, as written. Evidence is not an acceptance."))
  "The types, Role types and Occurrence types this document uses, with the names and meanings written into it.")

(defparameter +acceptance-schema+
  '(("acceptance-record" "Acceptance record" "A judgment, accepted or rejected, on one declared work package against an explicitly named revision of its WBS Dictionary acceptance criterion, by a declared authority, at a time, on named evidence entries. Stated only by an Acceptance Records page and never changed; a correction supersedes it. A test result or an executor report is not one.")
    ("withdrawal-record" "Withdrawal record" "A corrective record of an Acceptance Records page: it withdraws the earlier records of its work package that it supersedes and judges nothing. It names no criterion and considers no evidence, so it asserts no criterion satisfaction.")
    ("authority" "Authority" "Whoever an Acceptance Records page declares may decide on acceptance: declared, not authenticated. Not the executor of an assignment.")
    ("wbs-criterion" "WBS criterion" "One revision of a WBS Dictionary acceptance criterion, identified by the SHA-256 of its text; it reifies the occurrence that states that text, current or retained. Not the occurrence type acceptance criterion of an assignment.")
    ("evidence-entry" "Evidence entry" "One entry of an assignment's evidence with an authored ID, as the executor wrote it; it reifies that evidence occurrence. A report, not an acceptance.")
    ("test-execution-report" "Test execution report" "An evidence entry that reports one run of a test: its repository, tested revision, tree state, observation and time, as the executor reports them. It states that the run was reported, not that it happened; the test file is a program, not this report.")
    ("acceptance-decision" "acceptance decision" "The record judges the work package against the applied criterion revision; the authority decides.")
    ("withdrawal" "withdrawal" "The withdrawal record concerns the work package; the authority withdraws.")
    ("considers-evidence" "considers evidence" "The record names this evidence entry as evidence it considered. Considering evidence is not the evidence deciding.")
    ("supersedes" "supersedes" "The superseding record replaces the superseded one, which stays as it was. Which record is in force follows from this Association alone, never from a time.")
    ("reports-execution-of" "reports execution of" "The execution report names this test file of this repository as the program it ran. The file is not the report.")
    ("proposed-in-dictionary" "proposed in dictionary" "A draft WBS Dictionary states requirements for the proposed work package. Nothing is declared.")
    ("acceptance-record-role" "acceptance record" nil) ("withdrawal-record-role" "withdrawal record" nil) ("applied-criterion" "applied criterion" nil)
    ("deciding-authority" "deciding authority" nil) ("considered-evidence" "considered evidence" nil)
    ("superseding-record" "superseding record" nil) ("superseded-record" "superseded record" nil) ("execution-report" "execution report" nil)
    ("decision" "decision" "accepted or rejected, as the record states it.")
    ("decided-at" "decided at" "When the record was decided, as it states it (xsd:dateTime, UTC). Information only: it decides no precedence.")
    ("retained-wbs-acceptance-criterion" "retained WBS acceptance criterion" "An acceptance criterion the WBS Dictionary entry stated before and keeps, so that a record that applied it stays readable. Not the current criterion; it records no acceptance.")
    ("source-repository" "source repository" "The repository of the tested tree, as the report names it.")
    ("test-path" "test path" "The path of the test in its repository.")
    ("tested-revision" "tested revision" "The commit the tested tree was at, as the report states it.")
    ("tree-state" "tree state" "clean, or modified against the tested revision, as the report states it.")
    ("content-reference" "content reference" "An immutable reference to the content of a modified tree, as the report states it.")
    ("observation" "observation" "The output the executor reports having observed, as written.")
    ("observed-at" "observed at" "When the executor observed it, as the report states it (xsd:dateTime, UTC).")
    ("reconstruction" "reconstruction" "Derived from tree state and content reference: whether the tested tree can be rebuilt from what the report records."))
  "The vocabulary of criterion revisions, identified evidence and acceptance. Written only when a source states something of it, so that
the project CTM states nothing about acceptance that its sources do not.")

(defun s (name)
  "The schema Topic NAME; it must be in +SCHEMA+ or +ACCEPTANCE-SCHEMA+."
  (unless (or (assoc name +schema+ :test #'equal) (assoc name +acceptance-schema+ :test #'equal)) (refuse "unknown schema name ~S" name))
  (schema-iri name))

(defun %schema-topics (b &optional (schema +schema+))
  (loop for (name label description) in schema
        do (%topic b (schema-iri name) :name label :schema t)
           (when description (%occurrence b (schema-iri name) (schema-iri "description") description))))

(defun %kind-type (b kind)
  (let ((iri (schema-iri (format nil "kind-~A" (slug kind)))))
    (%topic b iri :name kind :schema t)
    (%occurrence b iri (schema-iri "description") (format nil "A Topic declared with data-kind \"~A\"." kind))
    iri))
(defun %relation-type (b relation)
  (let ((iri (relation-type-iri relation)))
    (if (%contract-p relation)
        (%topic b iri)
        (progn (%topic b iri :name relation :type (s "relation-word") :schema t)
               (%occurrence b iri (s "description") (format nil "The relation word \"~A\", as authored." relation))))
    (dolist (end '(:source :target))
      (let ((role (role-type-iri relation end)))
        (%topic b role :name (format nil "~(~A~) of ~A" end (relation-label relation)) :schema t)
        (%occurrence b role (s "description")
                     (format nil "The Topic named by data-~:[to~;from~] of a statement ~A. What the ~(~A~) means is the text of ~A."
                             (eq end :source) relation end
                             (if (%contract-p relation) "its Relation Contract" "no contract (none exists)")))))
    iri))
(defun %hyperbook (b id)
  (let ((book (hyperbook:find-hyperbook id)))
    (%topic b (hyperbook-iri id) :name (if book (hyperbook:title-of book) id) :type (s "hyperbook"))
    (%occurrence b (hyperbook-iri id) (s "hyperbook-id") id)
    (hyperbook-iri id)))
(defun %page (b hyperbook-id title &optional item)
  (let ((iri (page-iri hyperbook-id title)))
    (%topic b iri :name title :type (s "hyperdoc-page"))
    (%occurrence b iri (s "hyperbook-id") hyperbook-id)
    (%occurrence b iri (s "page-id") title)
    (when item
      (%occurrence b iri (s "repository-path") (source-path item))
      (%occurrence b iri (s "source-sha256") (source-sha256 item)))
    (unless (gethash iri (b-paged b))
      (setf (gethash iri (b-paged b)) t)
      (%association b (s "contains-page") `((,(s "hyperbook-role") ,(%hyperbook b hyperbook-id)) (,(s "page") ,iri))))
    iri))
(defun %file (b path)
  "A repository file an assignment names. It is named, not read: no digest, and its existence changes nothing."
  (let ((iri (file-iri path)))
    (%topic b iri :name path :type (s "repository-file"))
    (%occurrence b iri (s "repository-path") path)
    iri))
(defun %evidence-file (b input)
  "A repository file the emitter read: its digest is the one the header lists."
  (let ((iri (%file b (evidence-path input))))
    (%occurrence b iri (s "source-sha256") (or (evidence-sha256 input) "absent"))
    iri))

(defparameter +page-directories+ '(("dreyeck/pages/work/" . "dreyeck/work/reading") ("dreyeck/pages/project/" . "dreyeck/work/project"))
  "Page directories of the HyperBooks whose pages an assignment may name, as written in their DEFHYPERDOC.")
(defun %path-topic (b path)
  "The Topic for the repository PATH: a page of a HyperBook of +PAGE-DIRECTORIES+ if the path names an .html file directly
in that directory, else the repository file. Decided from the path alone; no file is read or checked."
  (loop for (directory . book) in +page-directories+
        when (and (eql 0 (search directory path)) (> (length path) (+ (length directory) 5))
                  (string= ".html" path :start2 (- (length path) 5)) (not (find #\/ path :start (length directory))))
          do (return-from %path-topic (%page b book (subseq path (length directory) (- (length path) 5)))))
  (%file b path))

(defun write-model (model)
  (let ((b (make-instance 'ctm-builder)) (sources (model-sources model)))
    (%schema-topics b)
    (when (or (model-proposed-entries model) (model-acceptance model) (model-evidence-entries model)
              (some #'plan::entry-retained-criteria (model-entries model)))
      (%schema-topics b +acceptance-schema+))
    (%hyperbook b "dreyeck/work/reading")
    (dolist (item (sources-items sources)) (%page b (source-hyperbook-id item) (source-title item) item))
    ;; Declarations and proposals
    (dolist (d (model-declarations model))
      (let ((iri (topic-iri (declaration-id d))) (carrier (declaration-carrier d)))
        (%topic b iri :name (declaration-label d) :type (%kind-type b (declaration-kind d)))
        (%occurrence b iri (s "work-status") (declaration-status d))
        (%occurrence b iri (s "declaration-text") (declaration-text d))
        (if (declaration-proposal-p d)
            (%association b (s "proposed-on") `((,(s "proposal") ,iri) (,(s "source-page") ,(declaration-page-iri d))))
            (%association b (s "declared-on") `((,(s "declaration") ,iri) (,(s "source-page") ,(declaration-page-iri d)))))
        (%association b (s "carried-by") `((,(s "carried") ,iri) (,(s "carrier-page") ,(%page b (car carrier) (cdr carrier)))))))
    ;; Statements, each reified by the statement Topic that says where it is stated
    (dolist (st (model-statements model))
      (let* ((type (%relation-type b (statement-relation st))) (reifier (statement-iri st)))
        (%topic b reifier :name (format nil "~A ~A ~A" (statement-from st) (relation-label (statement-relation st)) (statement-to st))
                          :type (s (if (statement-proposal-p st) "proposed-statement" "authored-statement")))
        (%occurrence b reifier (s "statement-number") (statement-number st))
        (%association b (s (if (statement-proposal-p st) "proposed-on" "stated-on"))
                      `((,(s (if (statement-proposal-p st) "proposal" "statement")) ,reifier) (,(s "source-page") ,(statement-page-iri st))))
        (%association b type `((,(role-type-iri (statement-relation st) :source) ,(topic-iri (statement-from st)))
                               (,(role-type-iri (statement-relation st) :target) ,(topic-iri (statement-to st))))
                      reifier)))
    ;; WBS Dictionaries: the declared ones, then draft ones for proposed packages
    (flet ((dictionary-entry (entry page association)
        (let ((package (topic-iri (plan::entry-element-id entry))))
          (unless (gethash package (b-topics b)) (refuse "the dictionary entry ~A names no declared work package" (plan::entry-element-id entry)))
          (loop for (field . name) in '(("scope" . "wbs-scope") ("acceptance" . "wbs-acceptance-criterion") ("authority" . "wbs-authority")
                                        ("effect" . "wbs-effect") ("evidence" . "wbs-evidence"))
                do (%occurrence b package (s name) (plan::entry-field entry field)))
          (dolist (text (plan::entry-retained-criteria entry)) (%occurrence b package (s "retained-wbs-acceptance-criterion") text))
          (%association b (s association) `((,(s "work-package") ,package) (,(s "source-page") ,page)))
          (dolist (control (plan::entry-controls entry))
            (let ((iri (%iri "control" (plan::entry-element-id entry) (plan::control-id control))))
              (%topic b iri :name (plan::control-id control) :type (s "planned-control"))
              (%occurrence b iri (s "declaration-text") (%squash (plan::control-text control)))
              (%occurrence b iri (s "control-coverage") (plan::control-coverage control))
              (%occurrence b iri (s "test-marker") (plan::control-marker control))
              (%association b (s "planned-control-of") `((,(s "work-package") ,package) (,(s "control") ,iri)))
              (when (plan::control-test control)
                (let ((input (find (plan::control-test control) (model-evidence-inputs model) :key #'evidence-path :test #'equal)))
                  (%occurrence b iri (s "test-marker-found")
                               (if (and (evidence-text input) (plan::control-marker control) (search (plan::control-marker control) (evidence-text input)))
                                   "yes" "no"))
                  (%association b (s "exercised-by") `((,(s "control") ,iri) (,(s "test-file") ,(%evidence-file b input)))))))))))
      (loop for (entry . item) in (model-declared-entries model)
            for id = (plan::entry-element-id entry)
            do (unless (%declared model id :proposals nil)
                 (refuse "the dictionary entry ~A names no declared work package; a declared dictionary describes declared packages" id))
               (dictionary-entry entry (source-page-iri item) "defined-in-dictionary"))
      (loop for (entry . item) in (model-proposed-entries model)
            for id = (plan::entry-element-id entry)
            do (unless (find id (model-proposals model) :key #'declaration-id :test #'equal)
                 (refuse "the draft dictionary entry ~A names no proposed work package; a draft describes proposals only" id))
               (dictionary-entry entry (source-page-iri item) "proposed-in-dictionary")))
    ;; Assignments
    (dolist (a (model-assignments model))
      (let ((iri (%iri "assignment" (assignment-id a))) (page (source-page-iri (assignment-source a))))
        (%topic b iri :name (assignment-title a) :type (s "implementation-assignment"))
        (loop for (field . name) in '(("issued" . "issued") ("goal" . "goal") ("plan-step" . "plan-step-note")
                                      ("observed-state" . "observed-state") ("acceptance" . "acceptance"))
              do (%occurrence b iri (s name) (cdr (assoc field (assignment-fields a) :test #'equal))))
        (dolist (entry (cdr (assoc "preconditions" (assignment-lists a) :test #'equal))) (%occurrence b iri (s "precondition") (car entry)))
        (dolist (entry (cdr (assoc "acceptance-criteria" (assignment-lists a) :test #'equal))) (%occurrence b iri (s "acceptance-criterion") (car entry)))
        (%association b (s "declared-on") `((,(s "declaration") ,iri) (,(s "source-page") ,page)))
        (loop for (field . type) in '(("work-item" . "assignment-for") ("delivers" . "assignment-delivers"))
              for ref = (cdr (assoc field (assignment-refs a) :test #'equal))
              for role = (if (equal field "work-item") "work-item" "work-package")
              when ref do (%association b (s type) `((,(s "assignment") ,iri) (,(s role) ,(topic-iri ref)))))
        ;; Every entry's authored text is kept, whether or not it names a file of this repository.
        (dolist (entry (cdr (assoc "source-authorities" (assignment-lists a) :test #'equal))) (%occurrence b iri (s "source-authority-note") (car entry)))
        (dolist (entry (cdr (assoc "evidence" (assignment-lists a) :test #'equal))) (%occurrence b iri (s "evidence-note") (car entry)))
        (dolist (entry (cdr (assoc "source-authorities" (assignment-lists a) :test #'equal)))
          (let* ((reads (getf (cdr entry) :data-reads)) (changes (getf (cdr entry) :data-changes))
                 (item (and reads (find reads (sources-items sources) :key #'source-path :test #'equal))))
            (cond (item (%association b (s "reads-source") `((,(s "assignment") ,iri) (,(s "source") ,(source-page-iri item)))))
                  (reads (%association b (s "reads-source") `((,(s "assignment") ,iri) (,(s "source") ,(%path-topic b reads)))))
                  (changes (%association b (s "changes-source") `((,(s "assignment") ,iri) (,(s "file") ,(%path-topic b changes))))))))
        (dolist (entry (cdr (assoc "evidence" (assignment-lists a) :test #'equal)))
          (let ((test (getf (cdr entry) :data-test)))
            (when test (%association b (s "evidenced-by-test") `((,(s "assignment") ,iri) (,(s "test-file") ,(%file b test)))))))
        ;; Identified evidence entries: each reifies its evidence occurrence; an execution report states the facts of its run.
        (dolist (e (remove a (model-evidence-entries model) :key #'entry-assignment :test-not #'eq))
          (let ((entry (entry-iri e)))
            (%topic b entry :name (entry-key e) :type (s (if (entry-execution-p e) "test-execution-report" "evidence-entry")))
            (%reify-occurrence b iri (s "evidence-note") entry (entry-text e))
            (when (entry-execution-p e)
              (loop for (key . name) in '((:data-repository . "source-repository") (:data-test . "test-path") (:data-revision . "tested-revision")
                                          (:data-tree . "tree-state") (:data-content . "content-reference") (:data-observation . "observation"))
                    do (%occurrence b entry (s name) (entry-fact e key)))
              (%occurrence b entry (s "observed-at") (entry-fact e :data-observed-at) +xsd-datetime+)
              (%occurrence b entry (s "reconstruction") (entry-reconstruction e))
              (when (equal +repository+ (entry-fact e :data-repository))
                (%association b (s "reports-execution-of") `((,(s "execution-report") ,entry) (,(s "test-file") ,(%file b (entry-fact e :data-test)))))))))))
    ;; Acceptance: authorities and records, only from the Acceptance Records page
    (let ((acceptance (model-acceptance model)))
      (when acceptance
        (let ((page (source-page-iri (acceptance-source-item acceptance))))
          (loop for (id . name) in (acceptance-authorities acceptance)
                do (%topic b (%iri "authority" id) :name name :type (s "authority"))
                   (%association b (s "declared-on") `((,(s "declaration") ,(%iri "authority" id)) (,(s "source-page") ,page))))
          (dolist (r (acceptance-records acceptance))
            (let* ((iri (record-iri r)) (id (record-package r)) (package (topic-iri id)) (authority (%iri "authority" (record-authority r))))
              (%topic b iri :name (record-title r) :type (s (if (record-withdrawal-p r) "withdrawal-record" "acceptance-record")))
              (unless (record-withdrawal-p r) (%occurrence b iri (s "decision") (record-decision r)))
              (%occurrence b iri (s "decided-at") (record-decided-at r) +xsd-datetime+)
              (%occurrence b iri (s "declaration-text") (record-text r))
              (%association b (s "declared-on") `((,(s "declaration") ,iri) (,(s "source-page") ,page)))
              (if (record-withdrawal-p r)
                  (%association b (s "withdrawal") `((,(s "withdrawal-record-role") ,iri) (,(s "work-package") ,package) (,(s "deciding-authority") ,authority)))
                  ;; The applied revision is the one the record names, current or retained; it reifies the occurrence stating its text.
                  (destructuring-bind (revision text current-p)
                      (find (record-revision r) (entry-revisions (%declared-entry model id)) :key #'first :test #'equal)
                    (let ((criterion (criterion-iri id revision)))
                      (unless (gethash criterion (b-topics b))
                        (%topic b criterion :name (format nil "~A criterion ~A" id (subseq revision 0 19)) :type (s "wbs-criterion"))
                        (%reify-occurrence b package (s (if current-p "wbs-acceptance-criterion" "retained-wbs-acceptance-criterion")) criterion text))
                      (%association b (s "acceptance-decision") `((,(s "acceptance-record-role") ,iri) (,(s "work-package") ,package)
                                                                  (,(s "applied-criterion") ,criterion) (,(s "deciding-authority") ,authority)))
                      (dolist (key (record-evidence r))
                        (%association b (s "considers-evidence")
                                      `((,(s "acceptance-record-role") ,iri) (,(s "considered-evidence") ,(entry-iri (model-evidence-entry model key)))))))))
              (dolist (target (record-supersedes r))
                (%association b (s "supersedes") `((,(s "superseding-record") ,iri) (,(s "superseded-record") ,(%iri "acceptance" target))))))))))
    ;; Gaps
    (dolist (g (model-gaps model))
      (let ((iri (%iri "gap" (gap-rule g) (gap-key g))))
        (%topic b iri :name (gap-name g) :type (s "plan-gap"))
        (%occurrence b iri (s "gap-rule") (gap-text g))
        (dolist (subject (gap-subjects g))
          (%association b (s "gap-concerns") `((,(s "gap") ,iri) (,(s "subject") ,subject))))))
    (%render b sources (model-evidence-inputs model))))

;;; Writing

(defparameter +prefixes+ `(("s" . ,(%namespace "schema")) ("w" . ,(%namespace "work" "topic")))
  "Prefixes written for readability. A QName is written only where the local part is a plain CTM name.")
(defun %local-name-p (string)
  (and (plusp (length string)) (or (alpha-char-p (char string 0)) (char= (char string 0) #\_))
       (every (lambda (c) (or (alphanumericp c) (find c "_-"))) string)
       (every (lambda (c) (< (char-code c) 128)) string)))
(defun %ref (iri)
  (loop for (prefix . namespace) in +prefixes+
        when (and (> (length iri) (length namespace)) (string= namespace iri :end2 (length namespace))
                  (%local-name-p (subseq iri (length namespace))))
          do (return-from %ref (format nil "~A:~A" prefix (subseq iri (length namespace)))))
  (format nil "<~A>" iri))
(defun %string (value)
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for c across value
          do (case c (#\" (write-string "\\\"" out)) (#\\ (write-string "\\\\" out)) (#\Newline (write-string "\\n" out))
                 (#\Return (write-string "\\r" out)) (#\Tab (write-string "\\t" out)) (t (write-char c out))))
    (write-char #\" out)))
(defun %comment (out control &rest arguments)
  ;; A comment never contains "#(", which would open a block comment; the text is written after "# ".
  (let ((line (apply #'format nil control arguments)))
    (format out "# ~A~%" (substitute #\Space #\Newline line))))

(defun %render (b sources evidence-inputs)
  (with-output-to-string (out)
    (%comment out "HyperDoc project work: a CTM Topic Map derived from the HyperDoc Work pages.")
    (%comment out "Derived, not a source. The pages listed below stay authoritative for what they declare; a change belongs there.")
    (%comment out "Do not edit by hand. Regenerate with (dreyeck/work/project:write-project-ctm); emitter version ~D." +emitter-version+)
    (%comment out "Read it with the Document IRI ~A. Every Topic has a subject identifier, so no identity depends on it." +document-iri+)
    (%comment out "Sources, by repository path and the SHA-256 of the octets read:")
    (dolist (item (sources-items sources)) (%comment out "  ~A  ~A" (source-path item) (source-sha256 item)))
    (%comment out "Other files read: the test files WBS Dictionary controls name, to derive test marker found:")
    (dolist (input evidence-inputs) (%comment out "  ~A  ~A" (evidence-path input) (or (evidence-sha256 input) "absent")))
    (%comment out "No other file is read. A file an assignment names is written by its path only; this document holds no digest of itself.")
    (%comment out "Identity: tag: IRIs under ~A that name and do not locate; see dreyeck/work/project/project-ctm.lisp." +base+)
    (%comment out "Provenance is in declared-on, proposed-on and stated-on; work status is the occurrence work-status; no scope is used.")
    (terpri out)
    (loop for (prefix . namespace) in +prefixes+ do (format out "%prefix ~A <~A>~%" prefix namespace))
    (flet ((topic (topic)
             (format out "~%~A" (%ref (ct-iri topic)))
             (let ((tails (append (mapcar (lambda (type) (format nil "isa ~A" (%ref type))) (ct-types topic))
                                  (mapcar (lambda (name) (format nil "- ~A" (%string name))) (ct-names topic))
                                  (mapcar (lambda (o) (format nil "~A: ~A~@[^^<~A>~]~@[ ~~ ~A~]" (%ref (first o)) (%string (second o)) (third o)
                                                              (and (fourth o) (%ref (fourth o)))))
                                          (ct-occurrences topic)))))
               (format out "~{~%    ~A~^ ;~} .~%" tails))))
      (format out "~%# Schema: the types, Role types and Occurrence types of this document~%")
      (mapc #'topic (reverse (b-schema b)))
      (format out "~%# Topics~%")
      (mapc #'topic (reverse (b-order b))))
    (format out "~%# Associations~%")
    (loop for (type roles reifier) in (reverse (b-associations b))
          do (format out "~A(~{~A~^, ~})~@[ ~~ ~A~]~%" (%ref type)
                     (mapcar (lambda (role) (format nil "~A: ~A" (%ref (first role)) (%ref (second role)))) roles)
                     (and reifier (%ref reifier))))))

(defun materialize-project-ctm (&key texts) (model-text (build-project-model (read-project-sources :texts texts))))
(defun project-ctm-pathname () (merge-pathnames +project-ctm-file+ (repository-root)))
(defun write-project-ctm ()
  "Write the CTM text derived from the current source pages to +PROJECT-CTM-FILE+. The only writer of that file."
  (let ((octets (%utf8 (materialize-project-ctm))))
    (with-open-file (out (project-ctm-pathname) :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
      (write-sequence octets out))
    (with-open-file (out (project-ctm-digest-pathname) :direction :output :if-exists :supersede :external-format :utf-8)
      (format out "~A  ~A~%" (%sha256 octets) (file-namestring (project-ctm-pathname))))
    (values (project-ctm-pathname) (%sha256 octets))))
(defun project-ctm-digest-pathname () (merge-pathnames +project-ctm-digest-file+ (repository-root)))
