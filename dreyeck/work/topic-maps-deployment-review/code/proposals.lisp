;;;; Proposed Project Work: the Deployment's WBS, Dictionary and Plan, Read from Their Proposals
(in-package #:topic-maps-deployment-review)

(hyperdoc:see (hyperdoc:page "The Proposed Deployment WBS" :hyperbook "topic-maps-deployment-review"))
(hyperdoc:see #'dreyeck/work/ctm-page-authoring::read-wbs-dictionary)

;;; The deployment's WBS, its WBS Dictionary and its plan exist only as proposals, in two files of this reading written in
;;; forms the project already has: an addition to the page Implementation Assignments (data-proposed-topic,
;;; data-proposed-relation, assignments with evidence entries) and a draft WBS Dictionary (data-wbs-entry). This file reads
;;; them and states nothing about the project of its own. The draft dictionary is read by the WBS Dictionary reader of the
;;; CTM plan page; the addition by a reader that follows the project CTM emitter's, whose system, dreyeck/work/project, is
;;; bound to another Topic Maps revision and cannot be loaded in this image. That both read what the emitter reads is checked
;;; against the emitter's own reading, recorded by proposals/emitter-crosscheck.lisp in a process of its own.

;;; The proposal files, each read once

(defclass proposal-source ()
  ((key :initarg :key :reader proposal-source-key)
   (title :initarg :title :reader proposal-source-title)
   (path :initarg :path :reader proposal-source-path :documentation "Repository path of the file.")
   (promotion :initarg :promotion :reader proposal-source-promotion :documentation "Where promotion would put its text.")
   (text :initarg :text :reader proposal-source-text)
   (sha256 :initarg :sha256 :reader proposal-source-sha256 :documentation "Of the octets read."))
  (:documentation "One proposal file of this reading as read once: its text and the SHA-256 of the octets read."))
(defmethod v:text-representation ((s proposal-source)) (proposal-source-title s))

(defparameter +proposal-files+
  '((:addition "Addition to Implementation Assignments"
     "dreyeck/work/topic-maps-deployment-review/proposals/implementation-assignments-addition.html"
     "appended, unchanged, to dreyeck/pages/project/Implementation Assignments.html")
    (:draft-dictionary "Topic Maps Deployment WBS Dictionary (draft)"
     "dreyeck/work/topic-maps-deployment-review/proposals/topic-maps-deployment-wbs-dictionary.html"
     "moved to dreyeck/pages/project/Topic Maps Deployment WBS Dictionary.html, a draft page of the HyperBook dreyeck/work/project")))
(defvar *proposal-sources* nil)
(defun proposal-sources ()
  (or *proposal-sources*
      (setf *proposal-sources*
            (loop for (key title path promotion) in +proposal-files+
                  collect (let ((octets (octets-of (root-path path))))
                            (make-instance 'proposal-source :key key :title title :path path :promotion promotion
                                                            :text (sb-ext:octets-to-string octets :external-format :utf-8)
                                                            :sha256 (sha256-hex octets)))))))
(defun proposal-source (key) (or (find key (proposal-sources) :key #'proposal-source-key) (error "No proposal source ~S." key)))
(defun proposal-source-sha256-now (source)
  (let ((pathname (root-path (proposal-source-path source)))) (and (probe-file pathname) (sha256-hex (octets-of pathname)))))

;;; The addition, read as the emitter reads the page it would be appended to

(defun %proposal-dom (text) (let ((plump:*tag-dispatchers* plump:*html-tags*)) (plump:parse text)))
(defun %squash (string)
  "STRING with each run of whitespace one space, trimmed, as the emitter's reader sees an element's text."
  (let ((out (with-output-to-string (s)
               (let ((space nil))
                 (loop for c across string
                       do (if (member c '(#\Space #\Tab #\Newline #\Return #\Page))
                              (setf space t)
                              (progn (when space (write-char #\Space s)) (setf space nil) (write-char c s))))))))
    (string-trim " " out)))
(defun %node-text (node) (%squash (plump:decode-entities (plump:text node))))
(defun %enclosing-text (node)
  (loop for parent = (plump:parent node) then (plump:parent parent)
        while (and parent (plump:element-p parent))
        when (member (plump:tag-name parent) '("li" "p") :test #'string-equal) return (%node-text parent)
        finally (return (%node-text node))))
(defun %elements-with (dom tag attribute)
  (remove-if-not (lambda (node) (plump:attribute node attribute)) (plump:get-elements-by-tag-name dom tag)))

(defclass proposed-topic ()
  ((id :initarg :id :reader proposal-id) (kind :initarg :kind :reader proposal-kind) (label :initarg :label :reader proposal-label)
   (text :initarg :text :reader proposal-text :documentation "The authored sentence the proposal stands in.")
   (source :initarg :source :reader proposal-source-of))
  (:documentation "A proposed Work Topic: an anchor with data-proposed-topic. It has no work status; the ordinary Work reader
does not read it as a declaration."))
(defmethod v:text-representation ((p proposed-topic)) (format nil "~A (proposed ~A)" (proposal-label p) (proposal-kind p)))

(defclass proposed-statement ()
  ((from :initarg :from :reader statement-from) (relation :initarg :relation :reader statement-relation)
   (to :initarg :to :reader statement-to) (text :initarg :text :reader proposal-text) (source :initarg :source :reader proposal-source-of))
  (:documentation "A proposed statement: an item with data-proposed-from, data-proposed-relation and data-proposed-to."))
(defmethod v:text-representation ((s proposed-statement))
  (format nil "~A ~A ~A (proposed)" (statement-from s) (relation-name (statement-relation s)) (statement-to s)))
(defun relation-name (relation) (substitute #\Space #\- (subseq relation (1+ (or (position #\/ relation :from-end t) -1)))))

(defclass proposal-assignment ()
  ((id :initarg :id :reader assignment-id) (title :initarg :title :reader assignment-title)
   (fields :initarg :fields :reader assignment-fields) (refs :initarg :refs :reader assignment-refs)
   (lists :initarg :lists :reader assignment-lists) (source :initarg :source :reader proposal-source-of))
  (:documentation "An implementation assignment of the addition, as the page records one: what was asked, what the executor reports."))
(defmethod v:text-representation ((a proposal-assignment)) (assignment-title a))
(defun assignment-field (assignment name) (cdr (assoc name (assignment-fields assignment) :test #'equal)))
(defun assignment-ref (assignment name) (cdr (assoc name (assignment-refs assignment) :test #'equal)))
(defun assignment-list (assignment name) (cdr (assoc name (assignment-lists assignment) :test #'equal)))

(defclass assignment-evidence ()
  ((id :initarg :id :reader evidence-id) (assignment :initarg :assignment :reader evidence-assignment)
   (text :initarg :text :reader proposal-text) (attributes :initarg :attributes :reader evidence-attributes))
  (:documentation "An identified evidence entry of an assignment. With data-test it reports one run of that test as the executor
reports it; it is evidence, never an acceptance."))
(defmethod v:text-representation ((e assignment-evidence)) (format nil "Evidence entry ~A" (evidence-id e)))
(defun evidence-fact (e key) (getf (evidence-attributes e) key))
(defun execution-report-p (e) (and (evidence-fact e :data-test) t))
(defun evidence-key (e) (format nil "~A/~A" (assignment-id (evidence-assignment e)) (evidence-id e)))

(defparameter +entry-attributes+
  '("data-reads" "data-changes" "data-test" "data-evidence" "data-repository" "data-revision" "data-tree" "data-content"
    "data-observation" "data-observed-at")
  "The attributes of an assignment's list entry the emitter keeps.")

(defun read-addition (source)
  "The proposed Topics, proposed statements and assignments of the addition SOURCE, in page order."
  (let ((dom (%proposal-dom (proposal-source-text source))))
    (values
     (loop for node in (%elements-with dom "a" "data-proposed-topic")
           collect (make-instance 'proposed-topic :id (plump:attribute node "data-proposed-topic") :kind (plump:attribute node "data-kind")
                                                  :label (%node-text node) :text (%enclosing-text node) :source source))
     (loop for node in (%elements-with dom "li" "data-proposed-from")
           collect (make-instance 'proposed-statement :from (plump:attribute node "data-proposed-from")
                                                      :relation (plump:attribute node "data-proposed-relation")
                                                      :to (plump:attribute node "data-proposed-to") :text (%node-text node) :source source))
     (loop for section in (%elements-with dom "section" "data-assignment")
           collect (let ((fields nil) (refs nil) (lists nil))
                     (labels ((walk (node)
                                (loop for child across (plump:children node)
                                      when (plump:element-p child)
                                        do (let ((field (plump:attribute child "data-field")))
                                             (cond ((and field (string-equal (plump:tag-name child) "ul"))
                                                    (push (cons field (loop for li across (plump:children child)
                                                                            when (and (plump:element-p li) (string-equal (plump:tag-name li) "li"))
                                                                              collect (cons (%node-text li)
                                                                                            (loop for a in +entry-attributes+
                                                                                                  when (plump:attribute li a)
                                                                                                    append (list (intern (string-upcase a) :keyword) (plump:attribute li a))))))
                                                          lists))
                                                   (field (push (cons field (%node-text child)) fields)
                                                          (when (plump:attribute child "data-ref") (push (cons field (plump:attribute child "data-ref")) refs)))
                                                   (t (walk child)))))))
                       (walk section))
                     (make-instance 'proposal-assignment :id (plump:attribute section "data-assignment") :source source
                                                         :title (let ((h (first (plump:get-elements-by-tag-name section "h3")))) (if h (%node-text h) ""))
                                                         :fields (nreverse fields) :refs (nreverse refs) :lists (nreverse lists)))))))

;;; The draft dictionary, read by the WBS Dictionary reader of the CTM plan page

(defclass proposed-entry ()
  ((entry :initarg :entry :reader proposed-entry-entry :documentation "The reader's wbs-dictionary-entry.")
   (source :initarg :source :reader proposal-source-of))
  (:documentation "The entry of the draft WBS Dictionary for one proposed work package. Its evidence field states what evidence
the package requires; it is not an observation."))
(defmethod v:text-representation ((e proposed-entry)) (format nil "Draft entry ~A" (entry-id e)))
(defun entry-id (e) (dreyeck/work/ctm-page-authoring::entry-element-id (proposed-entry-entry e)))
(defun entry-field (e name) (cdr (assoc name (dreyeck/work/ctm-page-authoring::entry-fields (proposed-entry-entry e)) :test #'equal)))
(defun entry-controls (e) (dreyeck/work/ctm-page-authoring::entry-controls (proposed-entry-entry e)))
(defun control-id (c) (dreyeck/work/ctm-page-authoring::control-id c))
(defun control-coverage (c) (dreyeck/work/ctm-page-authoring::control-coverage c))
(defun control-test (c) (dreyeck/work/ctm-page-authoring::control-test c))
(defun control-marker (c) (dreyeck/work/ctm-page-authoring::control-marker c))
(defun control-text (c) (dreyeck/work/ctm-page-authoring::control-text c))
(defun entry-effect-paths (e)
  "The repository paths the entry's effect field names, each in a code element: the package's implementation objects."
  (let* ((dom (%proposal-dom (proposal-source-text (proposal-source-of e))))
         (section (find (entry-id e) (%elements-with dom "section" "data-wbs-entry") :key (lambda (s) (plump:attribute s "data-wbs-entry")) :test #'equal))
         (effect (find "effect" (%elements-with section "p" "data-field") :key (lambda (n) (plump:attribute n "data-field")) :test #'equal)))
    (remove-duplicates (mapcar #'%node-text (plump:get-elements-by-tag-name effect "code")) :test #'string= :from-end t)))
(defun control-marker-present-p (control)
  "Whether the control's marker occurs in its test file now: derived as the emitter derives it, by reading the file."
  (let ((pathname (and (control-test control) (root-path (control-test control)))))
    (and pathname (probe-file pathname) (control-marker control)
         (search (control-marker control) (uiop:read-file-string pathname :external-format :utf-8)) t)))

;;; All of it, read once

(defclass deployment-proposals ()
  ((topics :initarg :topics :reader proposals-topics) (statements :initarg :statements :reader proposals-statements)
   (assignments :initarg :assignments :reader proposals-assignments) (entries :initarg :entries :reader proposals-entries)
   (evidence :initarg :evidence :reader proposals-evidence))
  (:documentation "The proposed project work of the deployment, as read from its two proposal files."))
(defmethod v:text-representation ((p deployment-proposals)) "Proposed project work: Deploying Topic Maps with HyperDoc")
(defvar *proposals* nil)
(defun the-proposals ()
  (or *proposals*
      (setf *proposals*
            (multiple-value-bind (topics statements assignments) (read-addition (proposal-source :addition))
              (let ((dictionary (proposal-source :draft-dictionary)))
                (make-instance 'deployment-proposals
                               :topics topics :statements statements :assignments assignments
                               :entries (mapcar (lambda (entry) (make-instance 'proposed-entry :entry entry :source dictionary))
                                                (dreyeck/work/ctm-page-authoring::read-wbs-dictionary (proposal-source-text dictionary)))
                               :evidence (loop for a in assignments
                                               append (loop for (text . attributes) in (assignment-list a "evidence")
                                                            when (getf attributes :data-evidence)
                                                              collect (make-instance 'assignment-evidence :id (getf attributes :data-evidence)
                                                                                                          :assignment a :text text :attributes attributes)))))))))
(defun proposed-topic (id) (or (find id (proposals-topics (the-proposals)) :key #'proposal-id :test #'equal) (error "No proposed Topic ~S." id)))
(defun proposed-entry (id) (find id (proposals-entries (the-proposals)) :key #'entry-id :test #'equal))
(defun proposal-assignment (id) (or (find id (proposals-assignments (the-proposals)) :key #'assignment-id :test #'equal) (error "No assignment ~S." id)))
(defun assignment-evidence (id) (or (find id (proposals-evidence (the-proposals)) :key #'evidence-id :test #'equal) (error "No evidence entry ~S." id)))
(defun proposed-statement (from relation to)
  (or (find-if (lambda (s) (and (equal from (statement-from s)) (equal to (statement-to s)) (search relation (statement-relation s))))
               (proposals-statements (the-proposals)))
      (error "No proposed statement ~A ~A ~A." from relation to)))

;;; What the statements say, kept apart: WBS decomposition, plan production, plan dependency

(defun statements-of (relation &key from to)
  (remove-if-not (lambda (s) (and (string= relation (relation-name (statement-relation s)))
                                  (or (null from) (equal from (statement-from s))) (or (null to) (equal to (statement-to s)))))
                 (proposals-statements (the-proposals))))
(defun wbs-parent (id) (let ((s (first (statements-of "decomposes into" :to id)))) (and s (proposed-topic (statement-from s)))))
(defun wbs-children (id) (mapcar (lambda (s) (proposed-topic (statement-to s))) (statements-of "decomposes into" :from id)))
(defun produced-by (id) (mapcar (lambda (s) (proposed-topic (statement-from s))) (statements-of "produces" :to id)))
(defun step-products (id) (mapcar (lambda (s) (proposed-topic (statement-to s))) (statements-of "produces" :from id)))
(defun step-dependencies (id) (mapcar (lambda (s) (proposed-topic (statement-to s))) (statements-of "depends on" :from id)))
(defun step-dependents (id) (mapcar (lambda (s) (proposed-topic (statement-from s))) (statements-of "depends on" :to id)))
(defun assignments-delivering (id) (remove id (proposals-assignments (the-proposals)) :key (lambda (a) (assignment-ref a "delivers")) :test-not #'equal))

;;; Derived joins, each named as derived where it is shown

(defclass repository-path ()
  ((path :initarg :path :reader repository-path-path))
  (:documentation "A path of the HyperDoc repository that is not a candidate file, asked about when shown."))
(defmethod v:text-representation ((p repository-path)) (repository-path-path p))
(defvar *repository-paths* (make-hash-table :test #'equal))
(defun path-object (path)
  "The candidate file at PATH, or else the one repository-path object for it."
  (or (find path (candidate-files (the-candidate)) :key #'file-path :test #'string=)
      (or (gethash path *repository-paths*) (setf (gethash path *repository-paths*) (make-instance 'repository-path :path path)))))
(defun entry-implementation-objects (e) (mapcar #'path-object (entry-effect-paths e)))
(defun reported-runs (e)
  "The execution reports of the assignments whose test is the test of one of the entry's controls: derived by the file path."
  (let ((tests (remove nil (mapcar #'control-test (entry-controls e)))))
    (remove-if-not (lambda (r) (and (execution-report-p r) (member (evidence-fact r :data-test) tests :test #'string=)))
                   (proposals-evidence (the-proposals)))))
(defun content-naming-runs (e)
  "The execution reports whose content reference names one of the entry's implementation objects: derived by the path."
  (let ((paths (entry-effect-paths e)))
    (remove-if-not (lambda (r) (let ((content (evidence-fact r :data-content)))
                                 (and content (some (lambda (path) (search (concatenate 'string " of " path) content)) paths))))
                   (proposals-evidence (the-proposals)))))
(defun delivering-evidence (id)
  "The evidence entries of the assignments whose delivers field names ID: by the model's own reference."
  (loop for a in (assignments-delivering id) append (remove a (proposals-evidence (the-proposals)) :key #'evidence-assignment :test-not #'eq)))
(defun evidence-records (e)
  "The records an evidence entry names in its text: the reading's record objects for the candidate's evidence files, the probe's
record for the collision probe, otherwise the named path."
  (let ((text (proposal-text e)) (records nil))
    (dolist (r (all-evidence))
      (when (search (concatenate 'string "docs/topic-maps-deployment/evidence/" (evidence-file r)) text) (push r records)))
    (let ((finding (find-symbol "ASDF-COLLISION-FINDING" :topic-maps-deployment-review)))
      (when (and (search "asdf-collision/evidence/with-guard.sexp" text) finding (fboundp finding)) (push (funcall finding) records)))
    (when (and (null records) (search "docs/topic-maps-deployment/phase-a-design.md" text))
      (push (file-named "docs/topic-maps-deployment/phase-a-design.md") records))
    (when (and (null records) (search "proposals/evidence/emitter-crosscheck.sexp" text)) (push (the-emitter-crosscheck) records))
    (reverse records)))
(defun topic-decisions (topic)
  "The Phase A decisions D1 to D5 a proposal's sentence names, as this reading's decision records."
  (the-workspace)
  (remove-if-not (lambda (d) (search (format nil "decision ~A" (decision-id d)) (proposal-text topic))) (getf *subjects* :decisions)))

;;; The emitter's own reading of the proposals, recorded in a process with the Topic Maps revision it is bound to

(defclass emitter-crosscheck () ()
  (:documentation "The record of the project CTM emitter reading the page with the addition and the draft dictionary."))
(defmethod v:text-representation ((c emitter-crosscheck)) "The emitter's reading of the proposals (recorded)")
(defvar *emitter-crosscheck* (make-instance 'emitter-crosscheck))
(defun the-emitter-crosscheck () *emitter-crosscheck*)
(defun crosscheck-pathname () (root-path "dreyeck/work/topic-maps-deployment-review/proposals/evidence/emitter-crosscheck.sexp"))
(defun crosscheck-record ()
  (with-open-file (in (crosscheck-pathname) :external-format :utf-8)
    (with-standard-io-syntax (let ((*read-eval* nil) (*package* (find-package :keyword))) (read in)))))
(defun crosscheck-of-these-files-p (&optional (record (crosscheck-record)))
  "Whether the record is of the proposal files as this image read them."
  (let ((inputs (getf record :inputs)))
    (and (equal (getf inputs :addition-sha256) (proposal-source-sha256 (proposal-source :addition)))
         (equal (getf inputs :dictionary-sha256) (proposal-source-sha256 (proposal-source :draft-dictionary))))))
(defun this-reading (aspect)
  "What this image's readers read, in the form of the record's ASPECT."
  (let ((p (the-proposals)))
    (ecase aspect
      (:proposals (mapcar (lambda (x) (list (proposal-id x) (proposal-kind x) (proposal-label x))) (proposals-topics p)))
      (:proposed-statements (mapcar (lambda (s) (list (statement-from s) (statement-relation s) (statement-to s))) (proposals-statements p)))
      (:assignments (mapcar (lambda (a) (list (assignment-id a) (assignment-title a) (loop for (f . r) in (assignment-refs a) collect (list f r))))
                            (proposals-assignments p)))
      (:evidence-entries (mapcar (lambda (e) (list (evidence-key e) (if (execution-report-p e) :execution-report :evidence-note))) (proposals-evidence p)))
      (:proposed-entries (mapcar (lambda (e) (list (entry-id e) (mapcar #'control-id (entry-controls e)))) (proposals-entries p))))))
(defparameter +agreement-aspects+ '(:proposals :proposed-statements :assignments :evidence-entries :proposed-entries))
(defun reader-agreement (&optional (record (crosscheck-record)))
  "For each aspect, whether this image's readers read what the emitter read: (aspect agrees count)."
  (let ((emitter (getf record :with-proposals)))
    (mapcar (lambda (aspect) (list aspect (equal (getf emitter aspect) (this-reading aspect)) (length (this-reading aspect)))) +agreement-aspects+)))

;;; The existing model's own text, where a decision meets it: excerpts of files this image does not load

(defvar *model-excerpts* nil)
(defun model-excerpts ()
  (or *model-excerpts*
      (setf *model-excerpts*
            (list
             (hyperdoc-excerpt "ia:proposal-rule" "Implementation Assignments: what a proposal is" "dreyeck/pages/project/Implementation Assignments.html"
                               "A proposal below uses" "under the same ID.</p>")
             (hyperdoc-excerpt "emitter:sources" "The emitter: the four source pages of the project CTM" "dreyeck/work/project/project-ctm.lisp"
                               "(defparameter +sources+" "Each is the authority for what it declares.\")")
             (hyperdoc-excerpt "emitter:texts-extra" "The emitter: reading an addition in memory, and a draft page" "dreyeck/work/project/project-ctm.lisp"
                               "(defun read-project-sources (&key texts extra)" "a synthetic test fixture. Reads only.\"")
             (hyperdoc-excerpt "tests:determinism" "The project tests: the retained CTM is what the pages give now" "dreyeck/tests/project-ctm.lisp"
                               "(defun determinism-tests ()" "(string= a retained))")
             (hyperdoc-excerpt "asd:project-pages" "dreyeck.asd: the pages of the HyperBook dreyeck/work/project, drafts included" "dreyeck.asd"
                               "(:module \"dreyeck/pages/project\"" "(:static-file \"Acceptance Records.html\"))))")
             (hyperdoc-excerpt "emitter:identifier-part" "The emitter: what an identifier part may contain" "dreyeck/work/project/project-ctm.lisp"
                               "(defun %identifier-part (part)" "outside A-Z a-z 0-9 . _ : / -\" part))")
             (hyperdoc-excerpt "emitter:path-topic" "The emitter: a named path becomes a page Topic or a file Topic" "dreyeck/work/project/project-ctm.lisp"
                               "(defun %path-topic (b path)" "(%file b path))")
             (hyperdoc-excerpt "emitter:delivers" "The emitter: an assignment's work item and the one package it delivers" "dreyeck/work/project/project-ctm.lisp"
                               "(loop for (field . type) in '((\"work-item\" . \"assignment-for\")" "(,(s role) ,(topic-iri ref)))))")
             (hyperdoc-excerpt "emitter:status-gaps" "The emitter: proposed requirements and stale proposals" "dreyeck/work/project/project-ctm.lisp"
                               "        (loop for pair in (model-proposed-entries model)" "(topic-iri (declaration-id p)))))")
             (hyperdoc-excerpt "acceptance:d5" "The acceptance model, D5: declared work packages only" "docs/project-acceptance-model.md"
                               "## D5. Declared work packages only" "A declared dictionary's entry must itself name a declared package.")))))
(defun model-excerpt (key) (or (find key (model-excerpts) :key #'excerpt-key :test #'string=) (error "No model excerpt ~S." key)))

;;; The ordinary Work reader on the addition: a proposal is not a declaration

(defclass work-reader-check () ()
  (:documentation "What the ordinary Work reader reads from the addition and, as a positive control, from the CTM plan page; asked when shown."))
(defmethod v:text-representation ((c work-reader-check)) "The Work reader on the proposals")
(defvar *work-reader-check* (make-instance 'work-reader-check))
(defun work-reader-check () *work-reader-check*)
(defun work-topics-read (html) (tm:topicmap-projection-topics-of (dreyeck/work/reading:project-work-breakdown html)))
(defun plan-page-text () (uiop:read-file-string (root-path "dreyeck/pages/work/Authoring the CTM Plan Page.html") :external-format :utf-8))

;;; Views

(defun proposal-links ()
  (v:html (:p "Proposed project work: " (v:object-ref (the-proposals) :select "Proposed work" :display "overview")
              " · " (v:object-ref (the-proposal-workspace) :select "Topicmap" :display "Workspace")
              " · " (v:object-ref (review-page "The Six Open Decisions") :select "Content" :display "the six open decisions")
              " · " (v:object-ref (review-page "Promoting the Proposals") :select "Content" :display "promotion"))
          (reading-links)))
(defun topic-ref (topic) (v:object-ref topic :select "Proposal" :display (format nil "~A (~A)" (proposal-label topic) (proposal-id topic))))
(defun topic-refs (topics) (if topics (v:html (dolist (x topics) (v:html (topic-ref x) (:br)))) (v:html (v:esc "none"))))
(defun standing-note ()
  (v:html (:p (:strong "Proposed. ") "Stated by the addition to Implementation Assignments, which is not appended to the page. A proposal has no work status, and the ordinary Work reader does not read it as a declaration.")))
(defun acceptance-note (topic)
  (v:html (:h3 "Acceptance")
          (:p (v:esc (format nil "No acceptance record. ~:[Only a work package can be accepted.~;A proposed work package cannot be accepted: acceptance requires a declared package with an entry in a declared WBS Dictionary (decision D5 of the acceptance model), and the emitter derives the gap acceptance-requires-declaration for ~:*~A.~] Neither a passed test nor an executor's report is an acceptance."
                             (and (equal "work package" (proposal-kind topic)) (proposal-id topic)))))))

(defun run-row (r)
  (v:html (:tr (:td (v:object-ref r :select "Evidence entry" :display (evidence-id r)))
               (:td (v:object-ref (evidence-assignment r) :select "Assignment" :display (assignment-id (evidence-assignment r))))
               (:td (:code (v:esc (or (evidence-fact r :data-test) "—"))))
               (:td (v:esc (or (evidence-fact r :data-observed-at) "no run time")))
               (:td (v:esc (or (evidence-fact r :data-observation) "—"))))))
(defun runs-table (runs)
  (if runs
      (v:html (:table :class "inspector-table" (:tr (:th "Entry") (:th "Assignment") (:th "Test") (:th "Observed at") (:th "Observation, as reported"))
                      (dolist (r runs) (run-row r))))
      (v:html (:p "None."))))

(defun proposal-sections (topic)
  "The four questions about a proposed Topic, each answered by its own statements or records."
  (let ((id (proposal-id topic)) (entry (proposed-entry (proposal-id topic))))
    (v:html
      (:h3 "WBS decomposition")
      (:p "Part of: " (let ((parent (wbs-parent id))) (if parent (topic-ref parent) (v:esc "nothing"))))
      (:p "Decomposes into: " (topic-refs (wbs-children id)))
      (:h3 "Plan")
      (cond ((equal "plan step" (proposal-kind topic))
             (v:html (:p "Produces: " (topic-refs (step-products id))) (:p "Depends on: " (topic-refs (step-dependencies id)))
                     (:p "Steps depending on it: " (topic-refs (step-dependents id)))))
            ((equal "precondition" (proposal-kind topic))
             (v:html (:p "Steps waiting on it: " (topic-refs (step-dependents id)))
                     (let ((decisions (topic-decisions topic)))
                       (when decisions (v:html (:p "The decision it names: " (dolist (d decisions) (v:html (v:object-ref d :select "Decision") " "))))))))
            (t (v:html (:p "Produced by the steps: " (topic-refs (produced-by id))))))
      (when (member (proposal-kind topic) '("work package" "deliverable") :test #'equal)
        (v:html
          (:h3 "Scope, criterion and implementation objects")
          (if entry
              (v:html (:p (v:object-ref entry :select "Dictionary entry" :display (format nil "Its draft dictionary entry ~A" id)))
                      (:p (:strong "Scope: ") (v:esc (entry-field entry "scope")))
                      (:p (:strong "Acceptance criterion: ") (v:esc (entry-field entry "acceptance")))
                      (:p (:strong "Implementation objects, the paths its effect names: ")
                          (let ((objects (entry-implementation-objects entry)))
                            (if objects (dolist (o objects) (v:html (v:object-ref o) " ")) (v:esc "none: it changes no file of the repository")))))
              (v:html (:p (v:esc (if (wbs-children id) "A summary element: its work packages have the entries." "No dictionary entry.")))))))
      (:h3 "Evidence reported by assignments")
      (:p "An assignment's evidence is what its executor reports; it bears on a criterion and decides nothing.")
      (let ((delivering (assignments-delivering id)))
        (when delivering
          (v:html (:p "Assignments delivering it, by their delivers field: " (dolist (a delivering) (v:html (v:object-ref a :select "Assignment") " ")))
                  (runs-table (delivering-evidence id)))))
      (when entry
        (v:html (:p (:em "Derived: ") "the execution reports whose test is the test of one of its controls.") (runs-table (reported-runs entry))
                (:p (:em "Derived: ") "the execution reports whose content reference names one of its implementation objects.")
                (runs-table (content-naming-runs entry))))
      (acceptance-note topic))))

(v:defview proposed-topic-view (topic proposed-topic)
  (v:html-view :title "Proposal" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (format nil "~A" (proposal-label topic))))
       (:p (v:esc (format nil "Proposed ~A ~A." (proposal-kind topic) (proposal-id topic))))
       (standing-note)
       (:blockquote (v:esc (proposal-text topic)))
       (proposal-sections topic)
       (:p "In the " (v:object-ref (the-proposal-workspace) :select "Topicmap" :display "proposal Workspace")
           (v:esc (format nil ", Go to ~A." (proposal-id topic))))
       (proposal-links)))))

(v:defview proposed-statement-view (s proposed-statement)
  (v:html-view :title "Statement" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (proposal-text s)))
       (:p (v:esc (format nil "~A, a ~A." (statement-relation s)
                          (cond ((search "decomposes" (statement-relation s)) "WBS decomposition: scope membership only, no order, dependency, status or authority")
                                ((search "produces" (statement-relation s)) "plan statement: what a step is for, not that it may be performed")
                                (t "plan dependency: an ordering condition only")))))
       (:p "From " (topic-ref (proposed-topic (statement-from s))) " to " (topic-ref (proposed-topic (statement-to s))))
       (standing-note)
       (proposal-links)))))

(v:defview proposed-entry-view (e proposed-entry)
  (v:html-view :title "Dictionary entry" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (dreyeck/work/ctm-page-authoring::entry-title (proposed-entry-entry e))))
       (:p "Of the proposed work package " (topic-ref (proposed-topic (entry-id e))) ", in the draft "
           (v:object-ref (proposal-of e) :select "Proposal source") ". Read by "
           (v:object-ref #'dreyeck/work/ctm-page-authoring::read-wbs-dictionary :select "Source code" :display "read-wbs-dictionary") ".")
       (:table :class "inspector-table"
        (dolist (name '("scope" "acceptance" "authority" "effect" "evidence"))
          (v:html (:tr (:th (v:esc (if (string= name "evidence") "evidence required" name))) (:td (v:esc (entry-field e name)))))))
       (:p "The evidence field states what the package requires. It is not an observation.")
       (:h3 "Implementation objects: the paths the effect field names")
       (let ((objects (entry-implementation-objects e)))
         (if objects
             (v:html (:ul (dolist (o objects) (v:html (:li (v:object-ref o) (v:esc (path-state-text o)))))))
             (v:html (:p "None: the package changes no file of the repository."))))
       (:h3 "Controls")
       (:table :class "inspector-table"
        (:tr (:th "Control") (:th "Coverage") (:th "Test") (:th "Marker") (:th "Marker in the test file now"))
        (dolist (c (entry-controls e))
          (v:html (:tr (:td (v:esc (control-id c)) (:br) (v:esc (control-text c))) (:td (v:esc (control-coverage c)))
                       (:td (if (control-test c) (v:object-ref (path-object (control-test c))) (v:esc "—")))
                       (:td (:code (v:esc (or (control-marker c) "—"))))
                       (:td (v:esc (cond ((not (control-test c)) "planned: no test yet") ((control-marker-present-p c) "present (derived)") (t "absent (derived)"))))))))
       (:h3 "Execution reports of these tests")
       (:p (:em "Derived by the test file path. ") "Reported by the executors of assignments; evidence, not an acceptance.")
       (runs-table (reported-runs e))
       (:p (:em "Derived by the content reference: ") "execution reports of a tree whose named file is one of its implementation objects.")
       (runs-table (content-naming-runs e))
       (acceptance-note (proposed-topic (entry-id e)))
       (proposal-links)))))
(defun proposal-of (object) (proposal-source-of object))
(defun path-state-text (object)
  (if (typep object 'candidate-file)
      (format nil " — candidate file, ~A~@[, ~A~]" (state-text (file-state object))
              (and (file-tested-sha256 object) (if (file-matches-tested-p object) "same bytes as tested" "changed since the tests ran")))
      (format nil " — ~A" (repository-path-text object))))
(defun repository-path-text (p)
  (let ((pathname (root-path (repository-path-path p))))
    (cond ((not (probe-file pathname)) "absent")
          ((review-reading-path-p (repository-path-path p)) "this reading's own, untracked")
          (t "a repository path outside the candidate"))))

(v:defview repository-path-view (p repository-path)
  (v:html-view :title "Repository path" :priority -10
    (let* ((path (repository-path-path p)) (pathname (root-path path)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 (:code (v:esc path)))
         (:p (v:esc (format nil "Asked when shown: ~A~:[~;; SHA-256 now ~:*~A~]." (repository-path-text p)
                            (and (probe-file pathname) (not (uiop:directory-pathname-p (probe-file pathname))) (sha256-hex (octets-of pathname))))))
         (proposal-links))))))

(v:defview proposal-assignment-view (a proposal-assignment)
  (v:html-view :title "Assignment" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (assignment-title a)))
       (:p (v:esc (format nil "Assignment ~A, in the addition to Implementation Assignments. It records that the assignment was given, what it asks for, and what its executor reports." (assignment-id a))))
       (:table :class "inspector-table"
        (dolist (name '("issued" "goal" "plan-step" "observed-state" "acceptance"))
          (v:html (:tr (:th (v:esc name)) (:td (v:esc (or (assignment-field a name) "—"))))))
        (:tr (:th "work item") (:td (let ((ref (assignment-ref a "work-item"))) (if ref (topic-ref (proposed-topic ref)) (v:esc "—")))))
        (:tr (:th "delivers") (:td (let ((ref (assignment-ref a "delivers"))) (if ref (topic-ref (proposed-topic ref)) (v:esc "no package named"))))))
       (dolist (name '("source-authorities" "preconditions" "acceptance-criteria"))
         (v:html (:h3 (v:esc name))
                 (:ul (dolist (entry (assignment-list a name))
                        (destructuring-bind (text . attributes) entry
                          (let ((path (or (getf attributes :data-changes) (getf attributes :data-reads))))
                            (v:html (:li (v:esc text) (when path (v:html " — " (:em (v:esc (if (getf attributes :data-changes) "changes " "reads "))) (v:object-ref (path-object path))))))))))))
       (:p "The acceptance criteria are the assignment's, as the user gave them; the executor's report is not an acceptance of them.")
       (:h3 "Evidence")
       (:ul (dolist (entry (assignment-list a "evidence"))
              (destructuring-bind (text . attributes) entry
                (let ((id (getf attributes :data-evidence)))
                  (v:html (:li (if id (v:object-ref (assignment-evidence id) :select "Evidence entry" :display id) (v:esc "unidentified note"))
                               (v:esc (format nil " — ~A" text))))))))
       (proposal-links)))))

(v:defview assignment-evidence-view (e assignment-evidence)
  (v:html-view :title "Evidence entry" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (evidence-key e)))
       (:p (v:esc (proposal-text e)))
       (:p (:strong (v:esc (if (execution-report-p e) "An execution report: " "An evidence note: ")))
           (v:esc (if (execution-report-p e)
                      "the facts of one run of a test, as the executor reports them. It is evidence bearing on a criterion; it decides nothing."
                      "what the executor writes, without the facts of a run.")))
       (when (execution-report-p e)
         (v:html (:table :class "inspector-table"
                  (dolist (key '(:data-test :data-repository :data-revision :data-tree :data-content :data-observation :data-observed-at))
                    (v:html (:tr (:th (v:esc (string-downcase (subseq (symbol-name key) 5))))
                                 (:td (if (eq key :data-test) (v:object-ref (path-object (evidence-fact e key))) (v:esc (or (evidence-fact e key) "—"))))))))))
       (:p "Of the assignment " (v:object-ref (evidence-assignment e) :select "Assignment") ".")
       (let ((records (evidence-records e)))
         (when records (v:html (:p "The record it names: " (dolist (r records) (v:html (v:object-ref r) " "))))))
       (let ((entries (remove-if-not (lambda (x) (member e (reported-runs x))) (proposals-entries (the-proposals))))
             (named (remove-if-not (lambda (x) (member e (content-naming-runs x))) (proposals-entries (the-proposals)))))
         (when entries
           (v:html (:p (:em "Derived: ") "its test is a control of " (dolist (x entries) (v:html (v:object-ref x :select "Dictionary entry") " ")))))
         (when named
           (v:html (:p (:em "Derived: ") "its content reference names an implementation object of "
                       (dolist (x named) (v:html (v:object-ref x :select "Dictionary entry") " "))))))
       (proposal-links)))))

(v:defview proposal-source-view (s proposal-source)
  (v:html-view :title "Proposal source" :priority -10
    (let ((now (proposal-source-sha256-now s)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 (v:esc (proposal-source-title s)))
         (:p (:code (v:esc (proposal-source-path s))) (v:esc (format nil ", read once by this image: SHA-256 ~A; ~:[changed since: this image shows the text it read~;unchanged now~]."
                                                                    (proposal-source-sha256 s) (equal now (proposal-source-sha256 s)))))
         (:p (v:esc (format nil "Promotion: ~A." (proposal-source-promotion s))))
         (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:40em;overflow:auto" (v:esc (proposal-source-text s)))
         (proposal-links))))))

(v:defview deployment-proposals-view (p deployment-proposals)
  (v:html-view :title "Proposed work" :priority -10
    (flet ((kind (k) (remove k (proposals-topics p) :key #'proposal-kind :test-not #'equal)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 "Deploying Topic Maps with HyperDoc on dreyeck.ch: the proposed project work")
         (standing-note)
         (:p "Read from " (v:object-ref (proposal-source :addition) :select "Proposal source") " and "
             (v:object-ref (proposal-source :draft-dictionary) :select "Proposal source") ".")
         (:h3 "WBS: deliverables and work packages")
         (labels ((tree (topic)
                    (v:html (:li (topic-ref topic) (v:esc (format nil " — ~A" (proposal-kind topic)))
                                 (let ((children (wbs-children (proposal-id topic))))
                                   (when children (v:html (:ul (dolist (c children) (tree c))))))))))
           (v:html (:ul (dolist (root (remove-if (lambda (d) (wbs-parent (proposal-id d))) (kind "deliverable"))) (tree root)))))
         (:p "Work item: " (topic-refs (kind "work item")))
         (:h3 "Plan: steps and preconditions")
         (:table :class "inspector-table"
          (:tr (:th "Plan step") (:th "Produces") (:th "Depends on"))
          (dolist (s (kind "plan step"))
            (v:html (:tr (:td (topic-ref s)) (:td (topic-refs (step-products (proposal-id s)))) (:td (topic-refs (step-dependencies (proposal-id s))))))))
         (:p "Preconditions: " (topic-refs (kind "precondition")))
         (:h3 "Draft WBS Dictionary")
         (:ul (dolist (e (proposals-entries p)) (v:html (:li (v:object-ref e :select "Dictionary entry")))))
         (:h3 "Assignments and their reported evidence")
         (:ul (dolist (a (proposals-assignments p))
                (v:html (:li (v:object-ref a :select "Assignment")
                             (v:esc (format nil " — ~D evidence entries, ~D of them execution reports"
                                            (count a (proposals-evidence p) :key #'evidence-assignment)
                                            (count-if (lambda (e) (and (eq a (evidence-assignment e)) (execution-report-p e))) (proposals-evidence p))))))))
         (:h3 "Acceptance")
         (:p "No Acceptance Records page is a source of this reading, and none records a decision on any of these packages. A proposed package cannot be accepted until it is declared.")
         (:p "The emitter's own reading of all this: " (v:object-ref (the-emitter-crosscheck) :select "Cross-check") ".")
         (proposal-links))))))

(v:defview work-reader-check-view (c work-reader-check)
  (v:html-view :title "Work reader" :priority -10
    (let ((from-addition (work-topics-read (proposal-source-text (proposal-source :addition))))
          (from-plan-page (work-topics-read (plan-page-text))))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 "The ordinary Work reader reads none of the proposals as a declaration")
         (:p "Asked when shown, with " (v:object-ref #'dreyeck/work/reading:project-work-breakdown :select "Source code" :display "project-work-breakdown")
             ", the reader of every Work page:")
         (:ul (:li (v:esc (format nil "from the addition: ~D Work Topics" (length from-addition))))
              (:li (v:esc (format nil "from the page Authoring the CTM Plan Page, the positive control: ~D Work Topics" (length from-plan-page)))))
         (:p "It reads data-topic, never data-proposed-topic. The emitter reads the proposals separately, as proposals.")
         (proposal-links))))))

(v:defview emitter-crosscheck-view (c emitter-crosscheck)
  (v:html-view :title "Cross-check" :priority -10
    (let* ((record (crosscheck-record)) (emitter (getf record :with-proposals)) (identity (getf record :topic-maps)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 "The project CTM emitter's reading of the proposals")
         (:p (:strong "Recorded run. ") (v:esc (format nil "~A to ~A, ~A, ASDF ~A, Topic Maps ~A from ~A (~:[not pinned~;the pinned revision, clean~]). Showing this record runs nothing."
                                                       (getf record :started-at) (getf record :finished-at) (getf record :lisp) (getf record :asdf)
                                                       (getf identity :commit) (getf identity :directory) (getf identity :pinned))))
         (:p (v:esc (getf record :purpose)))
         (:p "The procedure: " (v:object-ref (path-object "dreyeck/work/topic-maps-deployment-review/proposals/emitter-crosscheck.lisp"))
             ", started by " (v:object-ref (path-object "dreyeck/work/topic-maps-deployment-review/proposals/run-emitter-crosscheck.sh")) ".")
         (:p (v:esc (format nil "~:[The record is of other proposal files than this image read: run the cross-check again.~;The record is of the proposal files this image read.~]" (crosscheck-of-these-files-p record))))
         (:h3 "What the emitter read")
         (:p (v:esc (if (getf emitter :refused)
                        (format nil "It refused: ~A" (getf emitter :refused))
                        (format nil "No refusal: ~D proposed Topics, ~D proposed statements, ~D assignments with ~D evidence entries, ~D draft dictionary entries; none of them declared."
                                (length (getf emitter :proposals)) (length (getf emitter :proposed-statements)) (length (getf emitter :assignments))
                                (length (getf emitter :evidence-entries)) (length (getf emitter :proposed-entries))))))
         (:table :class "inspector-table"
          (:tr (:th "Aspect") (:th "This image's readers read the same") (:th "Items"))
          (dolist (row (reader-agreement record))
            (v:html (:tr (:td (v:esc (string-downcase (first row)))) (:td (v:esc (if (second row) "yes" "no"))) (:td (v:esc (princ-to-string (third row))))))))
         (:h3 "The gaps the emitter derives for them")
         (:ul (dolist (gap (getf emitter :gaps)) (v:html (:li (:code (v:esc (first gap))) (v:esc (format nil " — ~A" (second gap)))))))
         (:h3 "What it would do to the derived project CTM")
         (:p (v:esc (format nil "Without the addition the pages give exactly the retained CTM: ~:[no~;yes~] (SHA-256 ~A). With it the CTM would be ~D characters, ~D of its lines naming the proposals, and differ from the retained one: ~:[yes~;no~]."
                            (getf (getf record :baseline) :ctm-equals-retained) (getf (getf record :baseline) :ctm-sha256)
                            (getf emitter :ctm-characters) (getf emitter :ctm-lines-naming-tmd) (getf emitter :ctm-equals-retained))))
         (:p (v:esc (format nil "Unchanged by the run: the working tree ~:[no~;yes~], the retained CTM ~:[no~;yes~], the source pages ~:[no~;yes~]."
                            (getf (getf record :unchanged) :tree) (getf (getf record :unchanged) :retained-ctm) (getf (getf record :unchanged) :source-pages))))
         (:details (:summary "The whole record") (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:40em;overflow:auto"
                                                       (v:esc (uiop:read-file-string (crosscheck-pathname) :external-format :utf-8))))
         (proposal-links))))))

;;; The proposals as a Workspace: proposed Topics and statements, and the assignments with what they name

(defclass proposal-association (tm:topicmap-association)
  ((statement :initarg :statement :reader association-statement :documentation "The proposed statement, or the assignment that names it.")
   (standing :initarg :standing :reader association-standing :documentation ":proposed, or :reported for an assignment's reference."))
  (:documentation "A relation of the proposal Workspace and the authored element that states it."))
(defmethod v:text-representation ((a proposal-association))
  (format nil "~A ~A ~A" (tm:topicmap-association-from-of a) (tm:topicmap-association-type-of a) (tm:topicmap-association-to-of a)))

(defclass proposal-workspace (tm:topicmap-workspace) ()
  (:documentation "The proposed project work as Topics with their objects; at Point, the four questions kept apart."))

(defparameter +proposal-coordinates+
  '(("cc-2026-10-26-topic-maps-deployment-design" 200 40) ("cc-2026-10-26-topic-maps-local-packaging" 560 110) ("tmd" 1000 40)
    ("cc-2026-10-27-topic-maps-deployment-review" 1440 110) ("cc-2026-10-27-topic-maps-deployment-wbs-proposal" 1800 40)
    ("tmd-deployment" 1000 170)
    ("tmd-wp-1" 160 290) ("tmd-2" 640 290) ("tmd-wp-3" 1100 290) ("tmd-wp-4" 1480 290) ("tmd-wp-5" 1860 290)
    ("tmd-wp-2-1" 420 420) ("tmd-wp-2-2" 640 490) ("tmd-wp-2-3" 860 420)
    ("tmd-p1" 100 610) ("tmd-p2" 420 610) ("tmd-p3" 600 690) ("tmd-p4" 800 610) ("tmd-p5" 960 690) ("tmd-p6" 1100 610)
    ("tmd-p7" 1290 690) ("tmd-p8" 1480 610) ("tmd-p9" 1860 610)
    ("tmd-pre-change" 960 830) ("tmd-pre-commit" 1180 910) ("tmd-pre-push" 1340 830) ("tmd-pre-archive" 1500 910)
    ("tmd-pre-builder" 1640 830) ("tmd-pre-server" 1780 910) ("tmd-pre-exposure" 1920 830) ("tmd-pre-activation" 2040 910))
  "Authored for this reading: the assignments beside the Work Item they are for, the WBS under it, the plan below the WBS,
preconditions under the steps that wait on them.")

(defvar *proposal-workspace* nil)
(defun build-proposal-workspace ()
  (let ((p (the-proposals)) (topics nil) (associations nil) (counter 0))
    (flet ((place (id) (or (rest (assoc id +proposal-coordinates+ :test #'equal)) (error "No authored position for ~A." id)))
           (relate (from type to statement standing)
             (push (make-instance 'proposal-association :id (format nil "p~3,'0D" (incf counter)) :type type :from from :to to
                                                        :properties nil :statement statement :standing standing)
                   associations)))
      (dolist (topic (proposals-topics p))
        (destructuring-bind (x y) (place (proposal-id topic))
          (push (tm:make-topicmap-topic :id (proposal-id topic) :type (proposal-kind topic) :label (proposal-label topic) :object topic
                                        :view-properties (list :x x :y y :visible t :pinned t :kind (proposal-kind topic) :status "proposed"))
                topics)))
      (dolist (a (proposals-assignments p))
        (destructuring-bind (x y) (place (assignment-id a))
          (push (tm:make-topicmap-topic :id (assignment-id a) :type "assignment" :label (string-left-trim "c-" (assignment-id a)) :object a
                                        :view-properties (list :x x :y y :visible t :pinned t :kind "assignment" :status "reported"))
                topics)))
      (dolist (s (proposals-statements p)) (relate (statement-from s) (relation-name (statement-relation s)) (statement-to s) s :proposed))
      (dolist (a (proposals-assignments p))
        (loop for (field . ref) in (assignment-refs a)
              do (relate (assignment-id a) (if (equal field "delivers") "delivers" "is for") ref a :reported))))
    (make-instance 'proposal-workspace
                   :projection (tm:make-topicmap-projection :topics (reverse topics) :associations (reverse associations)
                                                            :view-properties '(:width 2240 :height 1000))
                   :point "tmd-deployment")))
(defun the-proposal-workspace () (or *proposal-workspace* (setf *proposal-workspace* (build-proposal-workspace))))

(defmethod tmi::render-workspace-point-editor ((workspace proposal-workspace) topic)
  ;; At Point: the object's own answers to the four questions. Navigation stays the generic Workspace's.
  (let ((object (tm:topicmap-topic-object-of topic)))
    (v:html
      (:h3 (v:esc (format nil "At Point: ~A" (v:text-representation object))))
      (if (typep object 'proposed-topic)
          (v:html (standing-note) (proposal-sections object))
          (v:html (:p (v:object-ref object :select "Assignment" :display "The assignment") ": what was asked and what its executor reports.")
                  (:p (v:esc (or (assignment-field object "observed-state") ""))))))))

(v:defview proposal-workspace-relations (workspace proposal-workspace)
  (v:html-view :title "Proposed relations" :priority 5
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Every relation of the proposal Workspace and what states it")
       (:table :class "inspector-table"
        (:tr (:th "From") (:th "Relation") (:th "To") (:th "Stated by") (:th "Standing"))
        (dolist (a (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of workspace)))
          (v:html (:tr :class "topic-maps-deployment-review-proposal-relation"
                       (:td (v:esc (tm:topicmap-association-from-of a))) (:td (v:esc (tm:topicmap-association-type-of a)))
                       (:td (v:esc (tm:topicmap-association-to-of a)))
                       (:td (v:object-ref (association-statement a) :select (if (eq :proposed (association-standing a)) "Statement" "Assignment")))
                       (:td (v:esc (if (eq :proposed (association-standing a)) "proposed by the addition" "an assignment's reference, as recorded")))))))
       (proposal-links)))))

(v:defview proposal-association-view (a proposal-association)
  (v:html-view :title "Relation" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (v:text-representation a)))
       (:p "Stated by " (v:object-ref (association-statement a)) ".")
       (proposal-links)))))
