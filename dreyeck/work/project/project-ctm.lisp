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
           #:reading-model #:reading-document #:topic-key #:import-project-ctm-revision))
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

(defun read-project-sources (&key texts)
  "Read each source page of +SOURCES+ once. TEXTS, an alist (ROLE . STRING), replaces a page's text (for tests); its digest is
then the digest of that text. Reads only."
  (make-instance
   'project-sources
   :observed-at (get-universal-time)
   :items (loop for (role book title kind) in +sources+
                collect (let* ((page (hyperbook:find-page (hyperbook:find-hyperbook book :signal-error? t) title :signal-error? t))
                               (pathname (hyperdoc:file-of page))
                               (given (cdr (assoc role texts)))
                               (octets (if given (%utf8 given) (%octets pathname))))
                          (make-instance 'source-item :role role :hyperbook-id book :title title :kind kind :page page
                                                      :path (repository-path pathname) :sha256 (%sha256 octets)
                                                      :text (or given (sb-ext:octets-to-string octets :external-format :utf-8)))))))
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
   (entries :initarg :entries :reader model-entries)
   (assignments :initarg :assignments :reader model-assignments)
   (gaps :initarg :gaps :accessor model-gaps)
   (bridges :initarg :bridges :reader model-bridges)
   (evidence-inputs :initarg :evidence-inputs :reader model-evidence-inputs)
   (text :initarg :text :accessor model-text))
  (:documentation "What the source pages declare, read once, and the CTM text written from it."))

(defmethod v:text-representation ((d work-declaration))
  (format nil "~:[Declaration~;Proposal~] ~A (~A)" (declaration-proposal-p d) (declaration-id d) (declaration-kind d)))
(defmethod v:text-representation ((s statement))
  (format nil "~:[Statement~;Proposed statement~] ~A ~A ~A" (statement-proposal-p s) (statement-from s) (statement-relation s) (statement-to s)))
(defmethod v:text-representation ((m project-model)) "The declared project work, as read for the CTM")
(defun model-proposals (model) (remove-if-not #'declaration-proposal-p (model-declarations model)))

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
  "The declarations and statements of one Work page, read with the ordinary Work reader; carriers and sentences from the same text."
  (let* ((projection (work:project-work-breakdown (source-text item) :source (source-page item)))
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
                                                                                              (loop for a in '("data-reads" "data-changes" "data-test")
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

(defun build-project-model (&optional (sources (read-project-sources)))
  "Read the declarations of SOURCES and write the CTM text. Signals PROJECT-CTM-REFUSED, or a Work source error. Writes nothing."
  (let ((declarations nil) (statements nil) (bridges nil) (entries nil) (assignments nil))
    (dolist (item (sources-items sources))
      (ecase (source-kind item)
        (:work (multiple-value-bind (d s b) (%read-work-source item)
                 (setf declarations (append declarations d) statements (append statements s) bridges (append bridges b))))
        (:dictionary (setf entries (plan::read-wbs-dictionary (source-text item))))
        (:assignments (multiple-value-bind (d s a) (%read-assignments item)
                        (setf declarations (append declarations d) statements (append statements s) assignments a)))))
    (%number-statements statements)
    (let ((model (make-instance 'project-model :sources sources :declarations declarations :statements statements
                                               :entries entries :assignments assignments :bridges bridges
                                               :evidence-inputs (read-evidence-inputs entries))))
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
      (dolist (entry (model-entries model))
        (gap "acceptance-not-recordable" (plan::entry-element-id entry)
             (format nil "~A: acceptance criterion without an acceptance record" (plan::entry-element-id entry))
             "The WBS Dictionary states an acceptance criterion for this work package. No page can record that the result was accepted; a work status is not an acceptance."
             (topic-iri (plan::entry-element-id entry))))
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
(defun %occurrence (b iri type value)
  (when value
    (let ((topic (gethash iri (b-topics b))) (entry (list type (princ-to-string value))))
      (unless (member entry (ct-occurrences topic) :test #'equal)
        (setf (ct-occurrences topic) (append (ct-occurrences topic) (list entry)))))))
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

(defun s (name)
  "The schema Topic NAME; it must be in +SCHEMA+."
  (unless (assoc name +schema+ :test #'equal) (refuse "unknown schema name ~S" name))
  (schema-iri name))

(defun %schema-topics (b)
  (loop for (name label description) in +schema+
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
    ;; WBS Dictionary
    (let ((dictionary (source (model-sources model) :dictionary)))
      (dolist (entry (model-entries model))
        (let ((package (topic-iri (plan::entry-element-id entry))))
          (unless (gethash package (b-topics b)) (refuse "the dictionary entry ~A names no declared work package" (plan::entry-element-id entry)))
          (loop for (field . name) in '(("scope" . "wbs-scope") ("acceptance" . "wbs-acceptance-criterion") ("authority" . "wbs-authority")
                                        ("effect" . "wbs-effect") ("evidence" . "wbs-evidence"))
                do (%occurrence b package (s name) (plan::entry-field entry field)))
          (%association b (s "defined-in-dictionary") `((,(s "work-package") ,package) (,(s "source-page") ,(source-page-iri dictionary))))
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
            (when test (%association b (s "evidenced-by-test") `((,(s "assignment") ,iri) (,(s "test-file") ,(%file b test)))))))))
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
                                  (mapcar (lambda (o) (format nil "~A: ~A" (%ref (first o)) (%string (second o)))) (ct-occurrences topic)))))
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
