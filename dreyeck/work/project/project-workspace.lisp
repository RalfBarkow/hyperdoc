;;;; HyperDoc project work: CTM revisions, their comparison, and the Project Workspace
(in-package #:dreyeck/work/project)

;; A CTM revision is a file read once. Its octets are the snapshot: the reader, the CXTM canonicalization and the export all use
;; them, and nothing reads the file again except an explicit new observation. The export is exactly the observed octets.
;;
;; Four things are kept apart: equal octets (two snapshots), equal CXTM (two Topic Maps with the same TMDM content, read with the
;; same Document IRI), the same Lisp object (one reading), and the same Workspace sign (one rendering). Each check below says which.

;;; The reader this reading depends on

(defparameter +topic-maps-revision+ "88994c1b9e1edbf13e665e984a5c9c3b2cdf7575"
  "The topic-maps commit this system is tested with: b2eecffa (Slice 22U) plus the indexed Topic merge search of Task 1C
(6162ed68) plus the indexed Association merge search of Task 1E (88994c1b; branch codex/project-work-slice-22u). The unchanged
b2eecffa reads the project CTM correctly but not in practical time; 6162ed68 was the pin until the Task 1E integration.
Before the integration of 2026-10-28 this was 5a4a668, a sibling lineage (963f2a0 plus an indexed search); its recovery
evidence stays in topic-maps-5a4a668-recovery.txt.")

(defparameter +one-root-systems+ '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm")
  "The Topic Maps systems the Project Workspace loads; they must all come from the one checked root.")

(defun pinned-state-p (commit changes one-root)
  "Whether a checkout is the pin: the pinned commit, no change in its working tree, one root for every Topic Maps system."
  (and one-root (equal commit +topic-maps-revision+) (zerop (length changes))))

(defun topic-maps-source-identity (&optional (root (asdf:system-source-directory "topic-maps/ctm")))
  "What the loaded topic-maps reader is, observed now, as a plist: :DIRECTORY; :KIND, one of :GIT-CHECKOUT,
:VERIFIED-NIX-STORE-SNAPSHOT (a /nix/store tree without .git whose files hash, as Git hashes them, to the pinned commit:
dreyeck/source-snapshot), :UNVERIFIED-NIX-STORE-SNAPSHOT (a store tree that does not) or :UNVERIFIABLE (anything else);
:COMMIT, the Git commit of a checkout, or the verified pinned commit of a snapshot, else NIL; :CLEAN; :ONE-ROOT, whether
topic-maps, /tmdm, /ctm and /cxtm all come from ROOT; :PINNED; and :REASON where a snapshot was refused. A directory that Git
cannot identify is never reported clean and never pinned."
  (let* ((directory (namestring root))
         (one-root (every (lambda (name)
                            (let ((other (ignore-errors (asdf:system-source-directory name))))
                              (and other (equal (truename root) (truename other)))))
                          +one-root-systems+)))
    (flet ((git (&rest arguments)
             (string-trim '(#\Newline) (uiop:run-program (list* "git" "-C" directory arguments) :output :string :ignore-error-status t))))
      (ecase (snap:source-kind root)
        (:git-checkout
         (let ((commit (git "rev-parse" "HEAD")) (changes (git "status" "--porcelain")))
           (list :directory directory :kind :git-checkout :commit (and (plusp (length commit)) commit)
                 :clean (and (plusp (length commit)) (zerop (length changes))) :one-root one-root
                 :pinned (pinned-state-p commit changes one-root))))
        (:nix-store-snapshot
         (handler-case
             (let ((verification (snap:verify-store-snapshot root +topic-maps-revision+)))
               (list :directory directory :kind :verified-nix-store-snapshot :commit +topic-maps-revision+ :clean t :one-root one-root
                     :pinned (and one-root t) :checks (snap:verification-checks verification)))
           (snap:snapshot-refused (condition)
             (list :directory directory :kind :unverified-nix-store-snapshot :commit nil :clean nil :one-root one-root :pinned nil
                   :reason (snap:snapshot-refused-reason condition)))))
        (:unverifiable
         (list :directory directory :kind :unverifiable :commit nil :clean nil :one-root one-root :pinned nil))))))

;;; Revisions

(defclass ctm-revision ()
  ((label :initarg :label :reader revision-label)
   (path :initarg :path :initform nil :reader revision-path)
   (octets :initarg :octets :reader revision-octets)
   (sha256 :initarg :sha256 :reader revision-sha256)
   (observed-at :initarg :observed-at :reader revision-observed-at)
   (bom-offset :initform 0 :accessor revision-bom-offset)
   (map :initform nil :accessor revision-map)
   (cxtm :initform nil :accessor revision-cxtm)
   (refusal :initform nil :accessor revision-refusal))
  (:documentation "One CTM document read once: its octets, their SHA-256 and time, and what the topic-maps reader made of them, or
why it refused. Reading never changes the file; the export is the octets."))
(defmethod v:text-representation ((r ctm-revision)) (format nil "CTM revision ~A (~A…)" (revision-label r) (subseq (revision-sha256 r) 0 12)))

(defun %read-revision (revision)
  "Read REVISION's octets: one leading UTF-8 BOM is not part of the text, the rest must be UTF-8, and the reader and CXTM get the
text. A refusal is kept as data: (CODE MESSAGE LINE COLUMN)."
  (let* ((octets (revision-octets revision))
         (offset (if (and (>= (length octets) 3) (= (aref octets 0) #xef) (= (aref octets 1) #xbb) (= (aref octets 2) #xbf)) 3 0)))
    (setf (revision-bom-offset revision) offset)
    (handler-case
        (let* ((text (handler-case (sb-ext:octets-to-string octets :external-format :utf-8 :start offset)
                       (sb-int:character-decoding-error () (error 'project-ctm-refused :reason "not UTF-8: refused before the CTM reader"))))
               (map (ctm:deserialize-string text :document-iri +document-iri+ :source-name (revision-label revision))))
          (setf (revision-map revision) map
                (revision-cxtm revision) (cxtm:canonicalize-octets map :base-locator +document-iri+)))
      (ctm:ctm-error (c)
        (setf (revision-refusal revision) (list (ctm:error-code c) (princ-to-string c) (ctm:error-line c) (ctm:error-column c))))
      (cxtm:cxtm-error (c) (setf (revision-refusal revision) (list (cxtm:error-code c) (princ-to-string c) nil nil)))
      (project-ctm-refused (c) (setf (revision-refusal revision) (list :not-utf-8 (project-ctm-refusal-reason c) nil nil))))
    revision))

(defun ctm-revision-from-octets (octets &key (label "given octets") path)
  (let ((copy (make-array (length octets) :element-type '(unsigned-byte 8) :initial-contents octets)))
    (%read-revision (make-instance 'ctm-revision :label label :path path :octets copy :sha256 (%sha256 copy)
                                                 :observed-at (get-universal-time)))))
(defun observe-ctm-revision (pathname &key label)
  "Read the CTM file PATHNAME once. The file must have the type ctm."
  (unless (equalp "ctm" (pathname-type pathname)) (refuse "~A is not a .ctm file" pathname))
  (ctm-revision-from-octets (%octets pathname) :label (or label (file-namestring pathname)) :path (namestring (truename pathname))))
(defun revision-export-octets (revision)
  "The export: exactly the observed octets, BOM included. Nothing is serialized."
  (copy-seq (revision-octets revision)))
(defun revision-current-p (revision)
  "Whether the file still has the observed octets. An observation now, shown as information; it gates nothing."
  (and (revision-path revision) (probe-file (revision-path revision))
       (equal (revision-sha256 revision) (%sha256 (%octets (revision-path revision))))))

;;; Reading a Topic Map: subject identifiers, types, roles

(defparameter +type-instance+ "http://psi.topicmaps.org/iso13250/model/type-instance")
(defparameter +type-role+ "http://psi.topicmaps.org/iso13250/model/type")
(defparameter +instance-role+ "http://psi.topicmaps.org/iso13250/model/instance")
(defun %si (topic) (first (tmdm:topic-subject-identifiers topic)))
(defun %signature (topic)
  (format nil "~{~A~^ ~}" (sort (append (tmdm:topic-subject-identifiers topic) (mapcar (lambda (l) (concatenate 'string "=" l)) (tmdm:topic-subject-locators topic))
                                        (mapcar (lambda (l) (concatenate 'string "^" l)) (tmdm:topic-item-identifiers topic)))
                                #'string<)))
(defun %roles (association)
  (mapcar (lambda (role) (cons (%si (tmdm:association-role-type role)) (tmdm:association-role-player role))) (tmdm:association-roles association)))
(defun %player (association role-iri) (cdr (assoc role-iri (%roles association) :test #'equal)))
(defun %of-type (map type-iri)
  (remove type-iri (tmdm:topic-map-associations map) :key (lambda (a) (%si (tmdm:association-type a))) :test-not #'equal))
(defun %types (map topic)
  (loop for a in (%of-type map +type-instance+)
        when (eq (tmdm:canonical-topic (%player a +instance-role+)) (tmdm:canonical-topic topic))
          collect (%player a +type-role+)))
(defun %occurrences (topic type-iri)
  (loop for o in (tmdm:topic-occurrences topic) when (equal type-iri (%si (tmdm:occurrence-type o))) collect (tmdm:occurrence-value o)))
(defun %name (topic) (let ((name (first (tmdm:topic-names topic)))) (if name (tmdm:topic-name-value name) (or (%si topic) "(unnamed)"))))
(defun %index (map)
  (let ((index (make-hash-table :test #'equal)))
    (dolist (topic (tmdm:topic-map-topics map) index)
      (dolist (si (tmdm:topic-subject-identifiers topic)) (setf (gethash si index) topic)))))

(defun compare-revisions (a b)
  "How two read revisions differ. :OCTETS-EQUAL compares snapshots, :CXTM-EQUAL their TMDM content (same Document IRI); the lists
name the Topics and Associations only one side has, by their identifiers. NIL lists where a side was refused."
  (flet ((topics (r) (and (revision-map r) (mapcar #'%signature (tmdm:topic-map-topics (revision-map r)))))
         (associations (r)
           (and (revision-map r)
                (mapcar (lambda (a) (format nil "~A(~{~A~^, ~})~@[ ~~ ~A~]" (%si (tmdm:association-type a))
                                            (sort (mapcar (lambda (role) (format nil "~A: ~A" (car role) (%signature (cdr role)))) (%roles a)) #'string<)
                                            (and (tmdm:item-reifier a) (%signature (tmdm:item-reifier a)))))
                        (tmdm:topic-map-associations (revision-map r))))))
    (list :octets-equal (equalp (revision-octets a) (revision-octets b))
          :cxtm-equal (and (revision-cxtm a) (revision-cxtm b) (equalp (revision-cxtm a) (revision-cxtm b)) t)
          :only-first-topics (set-difference (topics a) (topics b) :test #'equal)
          :only-second-topics (set-difference (topics b) (topics a) :test #'equal)
          :only-first-associations (set-difference (associations a) (associations b) :test #'equal)
          :only-second-associations (set-difference (associations b) (associations a) :test #'equal))))

;;; Tracing a Topic Map back to the declarations it was derived from

(defun trace-project-map (map model)
  "Every disagreement between the Topic Map MAP and the declarations of MODEL, as sentences; NIL if each declaration, proposal and
statement is in MAP as declared and MAP has no Work Topic, declaration or statement that the sources do not have."
  (let ((index (%index map)) (problems nil))
    (flet ((problem (control &rest arguments) (push (apply #'format nil control arguments) problems))
           (topic (iri) (gethash iri index))
           (has-association-p (type roles)
             (find-if (lambda (a) (every (lambda (role) (eq (tmdm:canonical-topic (or (%player a (car role)) (return-from has-association-p nil)))
                                                           (tmdm:canonical-topic (cdr role))))
                                         roles))
                      (%of-type map type))))
      (dolist (d (model-declarations model))
        (let ((topic (topic (topic-iri (declaration-id d)))) (page (topic (declaration-page-iri d))))
          (cond ((null topic) (problem "~A is ~:[declared~;proposed~] on ~A and missing from the Topic Map" (declaration-id d) (declaration-proposal-p d) (declaration-page-iri d)))
                ((null page) (problem "the source page ~A of ~A is missing" (declaration-page-iri d) (declaration-id d)))
                (t (unless (member (schema-iri (format nil "kind-~A" (slug (declaration-kind d)))) (mapcar #'%si (%types map topic)) :test #'equal)
                     (problem "~A is not typed by its kind ~S" (declaration-id d) (declaration-kind d)))
                   (unless (or (declaration-proposal-p d) (member (declaration-status d) (%occurrences topic (schema-iri "work-status")) :test #'equal))
                     (problem "~A does not carry its declared status ~S" (declaration-id d) (declaration-status d)))
                   (unless (has-association-p (schema-iri (if (declaration-proposal-p d) "proposed-on" "declared-on"))
                                              (list (cons (schema-iri (if (declaration-proposal-p d) "proposal" "declaration")) topic)
                                                    (cons (schema-iri "source-page") page)))
                     (problem "~A has no ~:[declared-on~;proposed-on~] Association to ~A" (declaration-id d) (declaration-proposal-p d) (declaration-page-iri d)))))))
      (dolist (st (model-statements model))
        (let* ((reifier (topic (statement-iri st)))
               (association (and reifier (find-if (lambda (a) (eq (tmdm:item-reifier a) reifier)) (tmdm:topic-map-associations map)))))
          (cond ((null association) (problem "the statement ~A ~A ~A on ~A is missing" (statement-from st) (statement-relation st) (statement-to st) (statement-page-iri st)))
                (t (unless (equal (%si (tmdm:association-type association)) (relation-type-iri (statement-relation st)))
                     (problem "the statement ~A has the type ~A" (statement-iri st) (%si (tmdm:association-type association))))
                   (unless (and (eq (tmdm:canonical-topic (or (%player association (role-type-iri (statement-relation st) :source)) reifier))
                                    (tmdm:canonical-topic (or (topic (topic-iri (statement-from st))) reifier)))
                                (eq (tmdm:canonical-topic (or (%player association (role-type-iri (statement-relation st) :target)) reifier))
                                    (tmdm:canonical-topic (or (topic (topic-iri (statement-to st))) reifier))))
                     (problem "the statement ~A does not have ~A as source and ~A as target" (statement-iri st) (statement-from st) (statement-to st)))))))
      ;; The other direction: nothing in the Topic Map that the sources do not declare.
      (let ((declared (mapcar (lambda (d) (list (topic-iri (declaration-id d)) (declaration-page-iri d) (declaration-proposal-p d))) (model-declarations model)))
            (stated (mapcar #'statement-iri (model-statements model)))
            (work-prefix (%namespace "work" "topic")))
        (loop for (type role proposal) in '(("declared-on" "declaration" nil) ("proposed-on" "proposal" t))
              do (dolist (a (%of-type map (schema-iri type)))
                   (let ((subject (%player a (schema-iri role))) (page (%player a (schema-iri "source-page"))))
                     (when (and subject page (eql 0 (search work-prefix (%si subject)))
                                (not (member (list (%si subject) (%si page) proposal) declared :test #'equal)))
                       (problem "~A ~A ~A, and no source says so" (%si subject) type (%si page))))))
        (dolist (a (tmdm:topic-map-associations map))
          (let ((reifier (tmdm:item-reifier a)))
            (when (and reifier (member (schema-iri "authored-statement") (mapcar #'%si (%types map reifier)) :test #'equal)
                       (not (member (%si reifier) stated :test #'equal)))
              (problem "the statement ~A is in the Topic Map and on no source page" (%si reifier)))))
        (dolist (topic (tmdm:topic-map-topics map))
          (let ((si (%si topic)))
            (when (and si (eql 0 (search work-prefix si)) (not (find si declared :key #'first :test #'equal)))
              (problem "the Work Topic ~A is in the Topic Map and declared nowhere" si))))))
    (nreverse problems)))

;;; Acceptance, explained from a Topic Map: the records on a work package, the one in force, its criterion revision and evidence

(defclass acceptance-explanation ()
  ((package :initarg :package :reader explanation-package)       ; the TMDM Topic of the work package
   (state :initarg :state :reader explanation-state)             ; "accepted", "rejected" or "undecided"
   (reason :initarg :reason :reader explanation-reason)          ; :in-force, :no-record, :withdrawn or :conflict
   (records :initarg :records :reader explanation-records)       ; every record on the package
   (open :initarg :open :reader explanation-open)                ; the records no record supersedes
   (record :initarg :record :reader explanation-record))         ; the judgment in force, or NIL
  (:documentation "Why a work package is accepted, rejected or undecided, read from a Topic Map alone: its records, the ones no record
supersedes, and the judgment in force if exactly one record is unsuperseded and it is a judgment. No time enters. What a record applied
and considered is RECORD-EXPLANATION."))
(defmethod v:text-representation ((x acceptance-explanation))
  (format nil "Acceptance of ~A: ~A" (%name (explanation-package x)) (explanation-state x)))

(defun %eq (a b) (and a b (eq (tmdm:canonical-topic a) (tmdm:canonical-topic b))))
(defun %players (map type role-of role-in topic)
  "The players of ROLE-OF in the Associations of TYPE in which TOPIC plays ROLE-IN."
  (loop for a in (%of-type map (schema-iri type))
        when (%eq (%player a (schema-iri role-in)) topic) collect (tmdm:canonical-topic (%player a (schema-iri role-of)))))
(defun %withdrawal-p (map record) (member (schema-iri "withdrawal-record") (mapcar #'%si (%types map record)) :test #'equal))

(defun explain-acceptance (map package)
  "The ACCEPTANCE-EXPLANATION of the work package PACKAGE, a Topic of MAP."
  (let* ((package (tmdm:canonical-topic package))
         (records (sort (remove-duplicates (append (%players map "acceptance-decision" "acceptance-record-role" "work-package" package)
                                                   (%players map "withdrawal" "withdrawal-record-role" "work-package" package)))
                        #'string< :key #'%si))
         (superseded (mapcar (lambda (a) (tmdm:canonical-topic (%player a (schema-iri "superseded-record")))) (%of-type map (schema-iri "supersedes"))))
         (open (remove-if (lambda (r) (member r superseded)) records))
         (judgment (and open (null (rest open)) (not (%withdrawal-p map (first open))) (first open))))
    (make-instance 'acceptance-explanation :package package :records records :open open :record judgment
                   :state (if judgment (first (%occurrences judgment (schema-iri "decision"))) "undecided")
                   :reason (cond ((null records) :no-record) ((rest open) :conflict) (judgment :in-force) (t :withdrawn)))))

(defun record-explanation (map record)
  "What the record RECORD states, read from MAP, as a plist: :decision (accepted, rejected or withdrawn), :decided-at, :package,
:authority, :criterion (the revision Topic), :criterion-text and :criterion-current (the occurrence the revision reifies, current or
retained), :evidence (evidence entry Topics), :supersedes and :superseded-by (record Topics)."
  (let* ((record (tmdm:canonical-topic record))
         (withdrawal (%withdrawal-p map record))
         (from (if withdrawal '("withdrawal" "withdrawal-record-role") '("acceptance-decision" "acceptance-record-role")))
         (package (first (%players map (first from) "work-package" (second from) record)))
         (criterion (first (%players map "acceptance-decision" "applied-criterion" "acceptance-record-role" record)))
         (stated (and criterion package
                      (find-if (lambda (o) (%eq (tmdm:item-reifier o) criterion)) (tmdm:topic-occurrences package)))))
    (list :decision (if withdrawal "withdrawn" (first (%occurrences record (schema-iri "decision"))))
          :decided-at (first (%occurrences record (schema-iri "decided-at")))
          :package package
          :authority (first (%players map (first from) "deciding-authority" (second from) record))
          :criterion criterion
          :criterion-text (and stated (tmdm:occurrence-value stated))
          :criterion-current (and stated (equal (%si (tmdm:occurrence-type stated)) (schema-iri "wbs-acceptance-criterion")))
          :evidence (%players map "considers-evidence" "considered-evidence" "acceptance-record-role" record)
          :supersedes (%players map "supersedes" "superseded-record" "superseding-record" record)
          :superseded-by (%players map "supersedes" "superseding-record" "superseded-record" record))))

(defun evidence-explanation (map entry)
  "What the evidence entry ENTRY reports, read from MAP, as a plist: :assignment and :text (the evidence occurrence it reifies), and for
an execution report the facts of its run as the report states them."
  (declare (ignore map))
  (let ((stated (tmdm:topic-reified (tmdm:canonical-topic entry))))
    (list* :assignment (and stated (tmdm:canonical-topic (tmdm:occurrence-parent stated)))
           :text (and stated (tmdm:occurrence-value stated))
           (loop for name in '("source-repository" "test-path" "tested-revision" "tree-state" "content-reference" "observation" "observed-at" "reconstruction")
                 append (list (intern (string-upcase name) :keyword) (first (%occurrences entry (schema-iri name))))))))

(defun %explanation-sentence (map x)
  (let ((record (explanation-record x)))
    (ecase (explanation-reason x)
      (:in-force (let ((r (record-explanation map record)))
                   (format nil "~A by ~A, against criterion revision ~A (~:[retained~;current~])" (explanation-state x) (%name record)
                           (subseq (topic-key (%si (getf r :criterion))) (1+ (position #\/ (topic-key (%si (getf r :criterion))) :from-end t)))
                           (getf r :criterion-current))))
      (:no-record "undecided: no record")
      (:withdrawn (format nil "undecided: withdrawn by ~A" (%name (first (explanation-open x)))))
      (:conflict (format nil "undecided: ~D records in conflict (~{~A~^, ~})" (length (explanation-open x)) (mapcar #'%name (explanation-open x)))))))

;;; The projection into a native Topicmap

(defclass project-topic (tm:topicmap-topic)
  ((reading :initarg :reading :reader project-topic-reading)
   (class :initarg :class :reader project-topic-class))
  (:documentation "A Topic of the Project Workspace. Its object is the TMDM Topic of the project CTM it stands for; its key is that
Topic's subject identifier without +BASE+ (and without work/topic/ for a Work Topic). The sign and the Point are presentation."))

(defun topic-key (si)
  (let ((rest (subseq si (length +base+))) (work "work/topic/"))
    (if (eql 0 (search work rest)) (subseq rest (length work)) rest)))
(defun %drawn-p (topic)
  (let ((si (%si topic)))
    (and si (eql 0 (search +base+ si))
         (not (eql 0 (search "schema/" (subseq si (length +base+)))))
         (not (eql 0 (search "statement/" (subseq si (length +base+))))))))

(defparameter +from-roles+
  '(("contains-page" . "hyperbook-role") ("declared-on" . "source-page") ("proposed-on" . "source-page")
    ("carried-by" . "carried") ("defined-in-dictionary" . "work-package") ("planned-control-of" . "work-package")
    ("exercised-by" . "control") ("gap-concerns" . "subject") ("assignment-for" . "assignment") ("assignment-delivers" . "assignment")
    ("reads-source" . "assignment") ("changes-source" . "assignment") ("evidenced-by-test" . "assignment")
    ("proposed-in-dictionary" . "work-package") ("acceptance-decision" . "acceptance-record-role") ("considers-evidence" . "acceptance-record-role")
    ("withdrawal" . "withdrawal-record-role") ("supersedes" . "superseding-record") ("reports-execution-of" . "execution-report"))
  "Which Role an edge starts from, by Association type. A statement starts from its source Role. Direction is presentation: in TMDM
a Role has none.")
(defparameter +layers+
  '("HyperBook" "HyperDoc page" "area" "work item" "deliverable" "work package" "plan step" "precondition" "Implementation assignment"
    "Acceptance record" "Withdrawal record" "WBS criterion" "Authority" "Evidence entry" "Test execution report" "Planned control"
    "Repository file" "relation" "concept" "Plan gap")
  "Rows of the derived layout, by kind. A derived grid; no authored coordinates exist.")

(defun %from-role (map association)
  (let* ((type (%si (tmdm:association-type association))) (local (and (eql 0 (search (%namespace "schema") type)) (subseq type (length (%namespace "schema"))))))
    (cond ((and local (assoc local +from-roles+ :test #'equal)) (schema-iri (cdr (assoc local +from-roles+ :test #'equal))))
          (t (let ((source (find-if (lambda (role) (let ((r (car role))) (and r (> (length r) 7) (string= "-source" r :start2 (- (length r) 7)))))
                                    (%roles association))))
               (if source (car source) (progn map nil)))))))

(defun build-workspace-projection (map reading)
  (let* ((drawn (remove-if-not #'%drawn-p (tmdm:topic-map-topics map)))
         (kind-of (lambda (topic) (let ((type (first (%types map topic)))) (if type (%name type) "untyped"))))
         (rows (make-hash-table :test #'equal)) (topics nil) (edges nil) (y 0) (ids (make-hash-table :test #'eq)))
    (dolist (topic drawn) (push topic (gethash (funcall kind-of topic) rows)))
    (let ((layers (append +layers+ (sort (set-difference (loop for k being the hash-keys of rows collect k) +layers+ :test #'equal) #'string<))))
      (dolist (layer layers)
        (let ((row (reverse (gethash layer rows))))
          (loop for topic in row for i from 0
                for key = (topic-key (%si topic))
                do (setf (gethash topic ids) key)
                   (push (make-instance 'project-topic :id key :label (%name topic) :type :tmdm-topic :object topic :reading reading
                                                       :class (cond ((%of-role map topic "proposed-on" "proposal") "proposed")
                                                                    ((%of-role map topic "declared-on" "declaration") "declared")
                                                                    ((equal layer "Plan gap") "derived")
                                                                    (t "source"))
                                                       :view-properties (list :kind layer :status (first (%occurrences topic (schema-iri "work-status")))
                                                                              :visible t :x (* 285 (mod i 8)) :y (+ y (* 120 (floor i 8)))))
                         topics))
          (when row (incf y (* 120 (1+ (floor (1- (length row)) 8))))))))
    (dolist (association (tmdm:topic-map-associations map))
      (let ((roles (%roles association)))
        (when (and (>= (length roles) 2) (every (lambda (role) (gethash (tmdm:canonical-topic (cdr role)) ids)) roles)
                   (or (= 2 (length roles)) (%from-role map association)))
          ;; Two Roles: one edge. More Roles: one edge from the Role the direction rule names to each other Role.
          (let* ((from-role (or (%from-role map association) (car (first roles))))
                 (from (cdr (or (assoc from-role roles :test #'equal) (first roles))))
                 (from-id (gethash (tmdm:canonical-topic from) ids)))
            (dolist (other (remove from roles :key #'cdr :test #'eq))
              (let ((to-id (gethash (tmdm:canonical-topic (cdr other)) ids)))
                (push (tm:make-topicmap-association
                       :id (format nil "~A:~A:~A:~D" (%name (tmdm:association-type association)) from-id to-id (length edges))
                       :type (if (= 2 (length roles)) (%name (tmdm:association-type association))
                                 (format nil "~A (~A)" (%name (tmdm:association-type association)) (%name (gethash (car other) (%index map)))))
                       :from from-id :to to-id
                       :properties (list :tmdm-association association
                                         :tmdm-role (find from (tmdm:association-roles association) :key #'tmdm:association-role-player :test #'eq)
                                         :reifier (tmdm:item-reifier association)))
                      edges)))))))
    ;; A Topic that reifies an occurrence of a drawn Topic: one edge from the reifier to that Topic. Presentation of TMDM reification
    ;; (a criterion revision and its work package, an evidence entry and its assignment), not an Association of the map.
    (dolist (topic drawn)
      (dolist (o (tmdm:topic-occurrences topic))
        (let* ((reifier (tmdm:item-reifier o)) (from-id (and reifier (gethash (tmdm:canonical-topic reifier) ids))) (to-id (gethash topic ids)))
          (when (and from-id to-id)
            (push (tm:make-topicmap-association
                   :id (format nil "reifies:~A:~A:~D" from-id to-id (length edges))
                   :type (format nil "reifies (~A)" (%name (tmdm:occurrence-type o))) :from from-id :to to-id
                   :properties (list :tmdm-occurrence o :reifier reifier))
                  edges)))))
    (tm:make-topicmap-projection :source reading :topics (nreverse topics) :associations (nreverse edges)
                                 :view-properties (list :width 2400 :height (max 720 (+ y 120))))))

(defun %of-role (map topic type role)
  (find-if (lambda (a) (eq (tmdm:canonical-topic (or (%player a (schema-iri role)) (return-from %of-role nil))) (tmdm:canonical-topic topic)))
           (%of-type map (schema-iri type))))

;;; The reading: sources, model, the CTM document, the Workspace

(defclass project-reading ()
  ((model :initarg :model :reader reading-model)
   (document :initarg :document :reader reading-document)
   (fresh :initform nil :accessor %fresh)
   (projection :initform nil :accessor %projection)
   (workspace :initform nil :accessor %workspace)
   (revisions :initform nil :accessor reading-revisions))
  (:documentation "One reading of the project: the declarations of the source pages (MODEL), the retained CTM file read once
(DOCUMENT), the CTM materialized from the sources now (FRESH, a revision of its octets), and the Workspace of DOCUMENT's Topic Map."))
(defmethod v:text-representation ((r project-reading)) "HyperDoc Project Workspace")

(defun reading-fresh (reading)
  "The CTM materialized from the sources of READING, read as a revision of its own; made when first asked for."
  (or (%fresh reading)
      (setf (%fresh reading) (ctm-revision-from-octets (%utf8 (model-text (reading-model reading))) :label "materialized now"))))
(defun reading-projection (reading)
  (or (%projection reading)
      (setf (%projection reading)
            (let ((map (revision-map (reading-document reading))))
              (unless map (refuse "the project CTM was refused: ~A" (second (revision-refusal (reading-document reading)))))
              (build-workspace-projection map reading)))))
(defun reading-workspace (reading)
  (or (%workspace reading)
      (setf (%workspace reading) (tm:make-topicmap-workspace (reading-projection reading) "hyperbook/dreyeck/work/reading"))))

(defvar *reading* nil "The last reading, kept while its sources and its CTM file are unchanged, so the Workspace keeps its Point.")
(defun project-ctm-document (&optional (pathname (project-ctm-pathname)))
  "The retained project CTM file, read once now."
  (observe-ctm-revision pathname :label "hyperdoc-project.ctm"))
(defun project-workspace (&key (pathname (project-ctm-pathname)) texts)
  "The Project Workspace reading. Reads the source pages and the CTM file; writes nothing."
  (let* ((model (build-project-model (read-project-sources :texts texts)))
         (document (project-ctm-document pathname)))
    (if (and *reading* (null texts)
             (equal (revision-sha256 document) (revision-sha256 (reading-document *reading*)))
             (equal (model-text model) (model-text (reading-model *reading*))))
        *reading*
        (let ((reading (make-instance 'project-reading :model model :document document)))
          (if texts reading (setf *reading* reading))))))
(defun scenario-reading (&key texts extra (label "scenario"))
  "A reading of the CTM materialized now from the sources with TEXTS and EXTRA (see READ-PROJECT-SOURCES): a draft page shown as it
would read, or a synthetic fixture. Its document is that materialization read once; no file is read or written."
  (let ((model (build-project-model (read-project-sources :texts texts :extra extra))))
    (make-instance 'project-reading :model model :document (ctm-revision-from-octets (%utf8 (model-text model)) :label label))))

(defun import-project-ctm-revision (pathname &optional (reading (project-workspace)))
  "Read the CTM file PATHNAME once as a revision of its own, beside READING. Nothing is written back to any page."
  (let ((revision (observe-ctm-revision (pathname pathname))))
    (push revision (reading-revisions reading))
    revision))

;;; Inspection

(defun ref (object &optional label select)
  (v:html (v:object-ref object :display (or label (v:text-representation object)) :select select)))
(defun %yes (x) (if x "yes" "no"))

(defun %download (revision)
  (v:html (:a :download (if (revision-path revision) (file-namestring (revision-path revision)) "revision.ctm")
              :href (format nil "data:application/octet-stream;base64,~A" (cl-base64:usb8-array-to-base64-string (revision-export-octets revision)))
              :class "project-ctm-download"
              (v:esc (format nil "Download ~A (~D octets)" (if (revision-path revision) (file-namestring (revision-path revision)) "the revision")
                             (length (revision-octets revision)))))))

(defun %go-to (workspace key label)
  (v:eval-button label (v:thunk (tm:topicmap-workspace-go-to workspace key) workspace)))

(v:defview project-overview (reading project-reading)
  (v:html-view :title "Project" :priority -10
    (let* ((model (reading-model reading)) (workspace (reading-workspace reading))
           (declarations (remove-if #'declaration-proposal-p (model-declarations model))))
      (flet ((of-kind (kind) (remove kind declarations :key #'declaration-kind :test-not #'equal)))
        (v:html
          (:h2 "HyperDoc Project Workspace")
          (:p "HyperDoc's declared project work, read from the Work pages, written as the CTM document below, read back with the topic-maps reader and drawn with the native Topicmap renderer. "
              "The Work pages stay authoritative; the CTM is derived from them and changes nothing on them.")
          (:p (ref workspace "Open the Project Workspace (native Topicmap, Point and History)" "Topicmap") " / "
              (ref (reading-document reading) "The project CTM document: open and download" "CTM document") " / "
              (ref reading "Roundtrip and traceability" "Roundtrip"))
          (:h3 "Project")
          (:p (%go-to workspace "hyperbook/dreyeck/work/reading" "Working on HyperDoc") " — the HyperBook whose main page, the Work Breakdown, is the current work map of HyperDoc.")
          (:h3 "Work Areas")
          (:ul (dolist (d (of-kind "area")) (v:html (:li (%go-to workspace (declaration-id d) (declaration-label d)) (v:esc (format nil " — ~A" (declaration-status d)))))))
          (:h3 "Work Items")
          (:ul (dolist (d (of-kind "work item")) (v:html (:li (%go-to workspace (declaration-id d) (declaration-label d)) (v:esc (format nil " — ~A" (declaration-status d)))))))
          (:h3 "Implementation assignments")
          (:ul (dolist (a (model-assignments model))
                 (v:html (:li (%go-to workspace (format nil "assignment/~A" (assignment-id a)) (assignment-title a))))))
          (:h3 "Acceptance")
          (if (null (model-acceptance model))
              (v:html (:p (v:esc "No acceptance is recorded: no source of this project CTM is an Acceptance Records page. An assignment's evidence is not an acceptance.")))
              (let* ((map (revision-map (reading-document reading))) (index (%index map)))
                (v:html (:p "Each work package with an entry in a declared WBS Dictionary, as the Topic Map states it: the record in force is the one record no record supersedes. "
                            "A time decides nothing; a withdrawal or two unsuperseded records leave the package undecided.")
                        (:ul (dolist (entry (model-entries model))
                               (let ((id (plan::entry-element-id entry)))
                                 (v:html (:li (%go-to workspace id id)
                                              (v:esc (format nil " — ~A" (%explanation-sentence map (explain-acceptance map (gethash (topic-iri id) index)))))))))))
                (when (acceptance-records (model-acceptance model))
                  (v:html (:p "Records, in page order:")
                          (:ul (dolist (r (acceptance-records (model-acceptance model)))
                                 (v:html (:li (%go-to workspace (format nil "acceptance/~A" (record-id r)) (record-title r))
                                              (v:esc (format nil " — ~A ~A, ~A~@[, supersedes ~{~A~^, ~}~]" (record-decision r) (record-package r)
                                                             (record-decided-at r) (record-supersedes r)))))))))))
          (:h3 "Proposals")
          (:p "Not declared: proposed on the page Implementation Assignments, without status.")
          (:ul (dolist (d (model-proposals model)) (v:html (:li (%go-to workspace (declaration-id d) (declaration-label d)) (v:esc (format nil " (~A)" (declaration-kind d)))))))
          (:h3 "Gaps")
          (:p "Derived from the sources by stated rules: where the declarations do not say enough. A gap adds no relation.")
          (:ul (dolist (g (model-gaps model))
                 (v:html (:li (%go-to workspace (format nil "gap/~A/~A" (gap-rule g) (gap-key g)) (gap-name g))))))
          (:h3 "Sources")
          (:table :class "inspector-table"
            (:tr (:th "Page") (:th "Repository path") (:th "SHA-256 read"))
            (dolist (item (sources-items (model-sources model)))
              (v:html (:tr (:td (ref (source-page item) (source-title item))) (:td (:code (v:esc (source-path item)))) (:td (:code (v:esc (source-sha256 item)))))))))))))

(v:defview project-roundtrip (reading project-reading)
  (v:html-view :title "Roundtrip" :priority -5
    (let* ((document (reading-document reading)) (fresh (reading-fresh reading))
           (exported (ctm-revision-from-octets (revision-export-octets document) :label "export of the document"))
           (comparison (compare-revisions document fresh))
           (problems (and (revision-map document) (trace-project-map (revision-map document) (reading-model reading)))))
      (v:html
        (:h2 "Roundtrip and traceability")
        (let ((identity (topic-maps-source-identity)))
          (v:html (:p "Reader: topic-maps at " (:code (v:esc (getf identity :directory))) ", "
                      (ecase (getf identity :kind)
                        (:git-checkout (v:html "Git checkout, commit " (:code (v:esc (or (getf identity :commit) "unknown")))))
                        (:verified-nix-store-snapshot (v:html "/nix/store snapshot without .git, verified against commit " (:code (v:esc (getf identity :commit)))))
                        (:unverified-nix-store-snapshot (v:html "/nix/store snapshot that does not verify: " (v:esc (getf identity :reason))))
                        (:unverifiable (v:html "a directory that Git cannot identify and that is no verified snapshot")))
                      (v:esc (format nil " — ~:[not clean or not identified~;clean~]; ~:[NOT the pinned ~A~;the pinned revision~*~]."
                                     (getf identity :clean) (getf identity :pinned) +topic-maps-revision+)))))
        (:table :class "inspector-table"
          (:tr (:th "Check") (:th "Compares") (:th "Result"))
          (:tr (:td "The CTM file was read") (:td "topic-maps reader, Document IRI " (:code (v:esc +document-iri+)))
               (:td (v:esc (if (revision-map document) (format nil "yes: ~D Topics, ~D Associations" (length (tmdm:topic-map-topics (revision-map document)))
                                                                (length (tmdm:topic-map-associations (revision-map document))))
                               (format nil "refused: ~A" (second (revision-refusal document))))))))
          (:tr (:td "Export of the unchanged import") (:td "octets") (:td (v:esc (%yes (equalp (revision-octets exported) (revision-octets document))))))
          (:tr (:td "The file is what the sources give now") (:td "octets") (:td (v:esc (%yes (getf comparison :octets-equal)))))
          (:tr (:td "The file and the sources mean the same") (:td "CXTM") (:td (v:esc (%yes (getf comparison :cxtm-equal)))))
          (:tr (:td "Every Topic and statement traced to its declaration") (:td "TMDM against the source pages")
               (:td (v:esc (if problems (format nil "no: ~D disagreements" (length problems)) "yes")))))
        (when problems (v:html (:ul (dolist (p problems) (v:html (:li (v:esc p))))))
        (:p "Equal octets, equal CXTM, the same Lisp object and the same Workspace sign are four different things; each row says which it compares.")
        (:p (ref fresh "The CTM materialized from the sources now" "CTM document"))))))

(v:defview project-import (reading project-reading)
  (v:html-view :title "Import a revision" :priority 0
    (v:html
      (:h2 "Import a CTM revision")
      (:p "A CTM file, for example one an exchange partner changed, is read once as a revision of its own and compared with the project CTM. "
          "Nothing is written back to the Work pages.")
      (:p "Path of a .ctm file:")
      (let ((cell (html-inspector-views/reactive:input :initial-value "" :size "100")))
        (v:html (:p (v:eval-button "Import revision" (v:thunk (import-project-ctm-revision (lwcells:cell-ref cell) reading))))))
      (:h3 "Imported")
      (:ul (dolist (r (reading-revisions reading)) (v:html (:li (ref r))))))))

(v:defview ctm-revision-document (revision ctm-revision)
  (v:html-view :title "CTM document" :priority -10
    (v:html
      (:h2 (v:esc (revision-label revision)))
      (:table :class "inspector-table"
        (:tr (:td "File") (:td (:code (v:esc (or (revision-path revision) "(no file)")))))
        (:tr (:td "SHA-256 of the octets read") (:td (:code (v:esc (revision-sha256 revision)))))
        (:tr (:td "Octets") (:td (v:esc (princ-to-string (length (revision-octets revision))))))
        (:tr (:td "Observed") (:td (v:esc (multiple-value-bind (s mi h d mo y) (decode-universal-time (revision-observed-at revision) 0)
                                            (format nil "~D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC" y mo d h mi s)))))
        (:tr (:td "Leading BOM") (:td (v:esc (if (= 3 (revision-bom-offset revision)) "yes; not part of the text read, part of the export" "no"))))
        (:tr (:td "The file is unchanged now") (:td (v:esc (if (revision-path revision) (%yes (revision-current-p revision)) "no file"))
                                                    " — information only; the export is the observed octets either way"))
        (:tr (:td "Read") (:td (v:esc (if (revision-map revision) "yes, by the topic-maps reader"
                                          (destructuring-bind (code message line column) (revision-refusal revision)
                                            (format nil "refused: ~A ~A~@[ at line ~D~]~@[, column ~D~]" code message line column)))))))
      (:p (%download revision) " — exactly the observed octets; nothing was serialized.")
      (when (revision-map revision) (v:html (:p (ref (revision-map revision) "The TMDM Topic Map" "Topics"))))
      (:h3 "Text")
      (:pre (v:esc (handler-case (sb-ext:octets-to-string (revision-octets revision) :external-format :utf-8 :start (revision-bom-offset revision))
                     (error () "(not UTF-8)")))))))

(v:defview ctm-revision-comparison (revision ctm-revision)
  (when *reading*
    (v:html-view :title "Comparison" :priority -5
      (let ((c (compare-revisions (reading-document *reading*) revision)))
        (v:html
          (:h2 "Compared with the project CTM")
          (:table :class "inspector-table"
            (:tr (:td "Equal octets") (:td (v:esc (%yes (getf c :octets-equal)))))
            (:tr (:td "Equal CXTM (same Document IRI)") (:td (v:esc (%yes (getf c :cxtm-equal))))))
          (loop for (key title) in '((:only-first-topics "Topics only in the project CTM") (:only-second-topics "Topics only in this revision")
                                     (:only-first-associations "Associations only in the project CTM") (:only-second-associations "Associations only in this revision"))
                when (getf c key)
                  do (v:html (:h3 (v:esc title)) (:ul (dolist (x (getf c key)) (v:html (:li (:code (v:esc x)))))))))))))

;;; The Point panel: what the Topic at Point is, where it is declared, and the objects of its source

(defun %source-objects (topic)
  "The HyperDoc objects behind TOPIC: the Work reader's declaration occurrences, the pages, the repository files."
  (let* ((reading (project-topic-reading topic)) (key (tm:topicmap-topic-id-of topic)) (model (reading-model reading)))
    (append (loop for d in (model-declarations model)
                  when (equal key (declaration-id d))
                    collect (list (if (declaration-proposal-p d) "Proposed on" "Declared on") (source-page (declaration-source d)) (declaration-occurrence d)))
            (loop for item in (sources-items (model-sources model))
                  when (equal key (topic-key (source-page-iri item))) collect (list "Source page" (source-page item) nil))
            (let ((rest (and (eql 0 (search "file/" key)) (subseq key 5))))
              (when rest (list (list "Repository file" (merge-pathnames rest (repository-root)) nil))))
            (let ((acceptance (model-acceptance model)))
              (when (and acceptance (or (eql 0 (search "acceptance/" key)) (eql 0 (search "authority/" key)))
                         (source-page (acceptance-source-item acceptance)))
                (list (list "Declared on" (source-page (acceptance-source-item acceptance)) nil))))
            (let ((entry (find key (model-evidence-entries model) :key (lambda (e) (topic-key (entry-iri e))) :test #'equal)))
              (when (and entry (source-page (assignment-source (entry-assignment entry))))
                (list (list "Reported on" (source-page (assignment-source (entry-assignment entry))) nil)))))))

(defmethod native::render-workspace-point-editor ((workspace tm:topicmap-workspace) (topic project-topic))
  (let ((tmdm-topic (tm:topicmap-topic-object-of topic)))
    (v:html
      (:p (v:esc (format nil "~A, ~A~@[, status ~A~]" (getf (tm:topicmap-topic-view-properties-of topic) :kind) (project-topic-class topic)
                         (getf (tm:topicmap-topic-view-properties-of topic) :status))))
      (:table :class "inspector-table"
        (dolist (source (%source-objects topic))
          (v:html (:tr (:td (v:esc (first source))) (:td (ref (second source)) (when (third source) (v:html " " (ref (third source) "the declaration in the page source"))))))))
      (:table :class "inspector-table"
        (dolist (o (tmdm:topic-occurrences tmdm-topic))
          (v:html (:tr (:td (v:esc (%name (tmdm:occurrence-type o)))) (:td (v:esc (tmdm:occurrence-value o))))))))
    (%render-acceptance-point workspace topic tmdm-topic)))

(defun %render-acceptance-point (workspace topic tmdm-topic)
  "For a work package of a reading with an Acceptance Records source: why it is accepted, rejected or undecided. For a record: what it
applied, considered and supersedes. For a criterion revision or an evidence entry: the occurrence it reifies. All read from the Topic
Map; buttons move the Point."
  (let* ((reading (project-topic-reading topic)) (model (reading-model reading)) (map (revision-map (reading-document reading)))
         (key (tm:topicmap-topic-id-of topic)))
    (labels ((link (other) (%go-to workspace (topic-key (%si other)) (%name other)))
             (record-rows (r)
               (let ((x (record-explanation map r)))
                 (v:html (:tr (:td "Decision") (:td (v:esc (format nil "~A, at ~A" (getf x :decision) (getf x :decided-at)))))
                         (:tr (:td "Deciding authority") (:td (when (getf x :authority) (link (getf x :authority))) " (declared, not authenticated)"))
                         (when (getf x :criterion)
                           (v:html (:tr (:td "Applied criterion") (:td (link (getf x :criterion))
                                                                       (v:esc (format nil " (~:[retained~;current~]): ~A" (getf x :criterion-current) (getf x :criterion-text)))))))
                         (dolist (e (getf x :evidence))
                           (let ((ev (evidence-explanation map e)))
                             (v:html (:tr (:td "Considered evidence")
                                          (:td (link e) (v:esc (format nil ": ~A~@[ — observed: ~A~]~@[; revision ~A~]~@[, tree ~A~]~@[; ~A~]" (getf ev :text) (getf ev :observation)
                                                                     (getf ev :tested-revision) (getf ev :tree-state) (getf ev :reconstruction))))))))
                         (dolist (other (getf x :supersedes)) (v:html (:tr (:td "Supersedes") (:td (link other)))))
                         (dolist (other (getf x :superseded-by)) (v:html (:tr (:td "Superseded by") (:td (link other)))))))))
      (cond ((and (model-acceptance model) (find key (model-entries model) :key #'plan::entry-element-id :test #'equal))
             (let ((x (explain-acceptance map tmdm-topic)))
               (v:html (:h4 "Acceptance")
                       (:p (v:esc (%explanation-sentence map x)))
                       (:table :class "inspector-table"
                         (when (explanation-record x) (record-rows (explanation-record x)))
                         (dolist (r (explanation-records x))
                           (v:html (:tr (:td (v:esc (if (member r (explanation-open x)) "Record, unsuperseded" "Record, superseded")))
                                        (:td (link r) (v:esc (format nil " — ~A" (getf (record-explanation map r) :decision)))))))))))
            ((eql 0 (search "acceptance/" key))
             (v:html (:h4 "Record") (:table :class "inspector-table" (record-rows tmdm-topic))))
            ((eql 0 (search "criterion/" key))
             ;; The text of a revision is the value of the occurrence it reifies (TMDM 5.3.5), current or retained on its package.
             (let* ((stated (tmdm:topic-reified tmdm-topic))
                    (package (and stated (tmdm:canonical-topic (tmdm:occurrence-parent stated))))
                    (current (and stated (equal (%si (tmdm:occurrence-type stated)) (schema-iri "wbs-acceptance-criterion")))))
               (v:html (:h4 "WBS criterion revision")
                       (:table :class "inspector-table"
                         (:tr (:td "Subject identifier") (:td (:code (v:esc (%si tmdm-topic)))))
                         (:tr (:td "Reifies")
                              (:td (v:esc (if stated
                                              (format nil "the occurrence ~A of the work package below (~:[retained~;current~])"
                                                      (%name (tmdm:occurrence-type stated)) current)
                                              "no occurrence"))))
                         (when package (v:html (:tr (:td "Stated on") (:td (link package)))))
                         (when stated (v:html (:tr (:td "Criterion text") (:td (v:esc (tmdm:occurrence-value stated))))))
                         (dolist (r (%players map "acceptance-decision" "acceptance-record-role" "applied-criterion" tmdm-topic))
                           (v:html (:tr (:td "Applied by") (:td (link r) (v:esc (format nil " — ~A" (getf (record-explanation map r) :decision)))))))))))
            ((eql 0 (search "evidence/" key))
             (let ((ev (evidence-explanation map tmdm-topic)))
               (v:html (:h4 "Evidence entry")
                       (:p "Reported by the executor on " (when (getf ev :assignment) (link (getf ev :assignment)))
                           (v:esc (format nil ": ~A. A report, not an acceptance~:[~;; it states that a run was reported, not that it happened~]."
                                          (getf ev :text) (getf ev :observation)))))))))))

(hyperdoc:defhyperdoc *project-hyperdoc*
  :id "dreyeck/work/project" :title "HyperDoc Project Workspace"
  :asdf-system-name "dreyeck/work/project"
  :subdirectory "dreyeck/pages/project" :code-subdirectory "dreyeck/work/project"
  :main-page-id "HyperDoc Project Workspace")
