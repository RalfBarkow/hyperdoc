;;;; Reading a Collaborative Planning Case
(defpackage #:dreyeck/work/collaborative-planning
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:hubs #:dreyeck/work/hubs)
                    (#:tm #:dreyeck/topicmap)
                    (#:v #:html-inspector-views)))
(in-package #:dreyeck/work/collaborative-planning)
(hyperdoc:see (hyperdoc:page "Collaborative Planning with Codex and SHOP3" :hyperbook "dreyeck/work/reading"))

;; A bounded, read-only document case. None of these objects is an executable
;; plan, a principal, a permission, an authoring request or a P3 referent contract.
(defparameter +case-digest+ "8fa96d54a5bdc18791c403d6d7924073a42123805318e8a8357ac342d0643723")
(defparameter +submitted-documents+
  '(("codex-plan-v1-submitted.txt" "9f25b2776e75da4d121bcf2ea5b13ccbf84134acd3d123e736748b17d252504f")
    ("claude-review-submitted.txt" "3811f57a518689b359383b5d3895d35e184e6971769f15f5edc666075f9c9c3a")
    ("codex-plan-v2-submitted.txt" "be5458f54ac3a4bfb36fba6066cdc08c7333c70d60ca46202185458461662e59")))
(defparameter +document-files+
  '(("plan-v1" . "codex-plan-v1-submitted.txt") ("claude-review" . "claude-review-submitted.txt")
    ("plan-v2" . "codex-plan-v2-submitted.txt") ("chatgpt-recommendation" . "chatgpt-recommendation-excerpt.txt")
    ("user-clarification" . "user-clarification.txt") ("slice-1-authorization" . "slice-1-authorization.txt")))

(defclass planning-subject ()
  ((id :initarg :id :reader subject-id)
   (identity :initarg :identity :reader source-identity)
   (record :initarg :record :reader subject-record)))
(defclass planning-document-version (planning-subject)
  ((pathname :initarg :pathname :reader document-pathname)
   (text :initarg :text :reader document-text)))
(defclass planning-text-reading (planning-subject)
  ((document :initarg :document :reader reading-document)))
(defclass planning-interpretation (planning-text-reading) ())
(defclass planning-review-finding (planning-text-reading) ())
(defclass planning-procedure-state (planning-text-reading) ())
(defclass recorded-planning-case (planning-subject)
  ((subjects :initarg :subjects :reader case-subjects)
   (pathname :initarg :pathname :reader case-pathname)))
(defvar *planning-case* nil)
(defvar *planning-workspace* nil)

(defun evidence-directory ()
  (asdf:system-relative-pathname "dreyeck/work/reading" "dreyeck/work/collaborative-planning-evidence/"))
(defun file-digest (path)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
(defun required-field (record key predicate)
  (multiple-value-bind (value present) (gethash key record)
    (unless (and present (funcall predicate value))
      (error "Invalid planning evidence field ~S: ~S" key value))
    value))
(defun string-field (record key) (required-field record key #'stringp))
(defun record-label (subject) (string-field (subject-record subject) "label"))
(defmethod v:text-representation ((subject planning-subject)) (record-label subject))
(defmethod v:text-representation ((case recorded-planning-case)) "Collaborative planning revision case")

(defun unique-subject (subjects id)
  (let ((matches (remove id subjects :key #'subject-id :test-not #'equal)))
    (unless (= 1 (length matches)) (error "Planning subject ~S resolves ~D times" id (length matches)))
    (first matches)))

(defun checked-reading (record class documents)
  (let* ((id (string-field record "id"))
         (document (unique-subject documents (string-field record "document")))
         (text (document-text document))
         (start (required-field record "start" #'integerp))
         (end (required-field record "end" #'integerp))
         (quote (string-field record "quote")))
    (unless (and (equal "unicode-code-points/half-open/v1" (gethash "coordinates" record))
                 (<= 0 start end (length text)) (< start end)
                 (equal quote (subseq text start end)))
      (error "Invalid original-text span for ~A" id))
    (when (eq class 'planning-interpretation)
      (unless (and (equal "Codex" (gethash "proposedBy" record))
                   (equal "proposed, not a human approval" (gethash "status" record))
                   (equal "1" (gethash "version" record)))
        (error "Interpretation is not a separately versioned proposal: ~A" id)))
    (make-instance class :id id :record record :document document
      :identity (list "user-submitted:hyperdoc-planning/2026-10-14" id
                      (or (gethash "version" record) "1") (source-identity document) start end))))

(defun build-planning-case (record directory)
  "Validate retained data, never READ/EVAL documents or infer authorization."
  (unless (and (eql 1 (gethash "version" record))
               (equal "collaborative-planning-case" (gethash "id" record)))
    (error "Unsupported planning case identity/version"))
  (unless (equal (string-field record "manifestSha256") (file-digest (merge-pathnames "MANIFEST.txt" directory)))
    (error "Submitted planning manifest changed"))
  (dolist (entry +submitted-documents+)
    (unless (equal (second entry) (file-digest (merge-pathnames (first entry) directory)))
      (error "Submitted planning document changed: ~A" (first entry))))
  (let* ((documents
           (loop for item across (required-field record "documents" #'vectorp) collect
             (let* ((file (string-field item "file"))
                    (path (merge-pathnames file directory)))
               (unless (member file '("codex-plan-v1-submitted.txt" "claude-review-submitted.txt"
                                      "codex-plan-v2-submitted.txt" "chatgpt-recommendation-excerpt.txt"
                                      "user-clarification.txt" "slice-1-authorization.txt") :test #'equal)
                 (error "Unregistered planning document file: ~A" file))
               (unless (equal file (cdr (assoc (string-field item "id") +document-files+ :test #'equal)))
                 (error "Wrong document identity/file pairing: ~A" file))
               (unless (and (equal "user-submitted:hyperdoc-planning/2026-10-14" (gethash "authority" item))
                            (equal (string-field item "sha256") (file-digest path)))
                 (error "Wrong planning document authority/digest: ~A" file))
               (make-instance 'planning-document-version :id (string-field item "id") :record item
                 :pathname path :text (uiop:read-file-string path :external-format :utf-8)
                 :identity (list (gethash "authority" item) (gethash "id" item) (gethash "sha256" item))))))
         (subjects (copy-list documents)))
    (unless (= 6 (length documents)) (error "Expected six separately identified document sources"))
    (loop for (key class size) in '(("interpretations" planning-interpretation 2)
                                   ("findings" planning-review-finding 11)
                                   ("states" planning-procedure-state 2)) do
      (let ((items (required-field record key #'vectorp)))
        (unless (= size (length items)) (error "Incomplete planning evidence: ~A" key))
        (loop for item across items do (setf subjects (append subjects (list (checked-reading item class documents)))))))
    (dolist (subject subjects) (unique-subject subjects (subject-id subject)))
    (let ((pending (subject-record (unique-subject subjects "approval-pending")))
          (approved (subject-record (unique-subject subjects "slice-1-approved"))))
      (unless (and (equal "not-yet-granted" (gethash "status" pending))
                   (equal "user-clarification" (gethash "document" pending))
                   (equal "slice-1-only" (gethash "status" approved))
                   (equal "slice-1-authorization" (gethash "document" approved)))
        (error "Procedural evidence cannot become a user rejection or a general grant")))
    (let ((ids (append '("planning" "dogfooding" "collaborative-planning-case" "hub-investigation")
                       (mapcar #'subject-id subjects))) (edges nil))
      (loop for edge across (required-field record "relations" #'vectorp) do
        (dolist (key '("from" "to"))
          (unless (member (string-field edge key) ids :test #'equal) (error "Unknown planning relation endpoint")))
        (unique-subject subjects (string-field edge "source"))
        (unless (member (string-field edge "warrant") '("derived" "source-observed" "user-reported") :test #'equal)
          (error "Unsupported planning warrant"))
        (when (member (string-field edge "id") edges :test #'equal) (error "Duplicate planning relation"))
        (push (gethash "id" edge) edges)))
    (make-instance 'recorded-planning-case :id "collaborative-planning-case"
      :identity '("dreyeck/work/reading" "collaborative-planning-case" "1")
      :record record :subjects subjects :pathname (merge-pathnames "case.json" directory))))

(defun read-planning-case (&optional (directory (evidence-directory)))
  (let ((path (merge-pathnames "case.json" directory)))
    (unless (equal +case-digest+ (file-digest path)) (error "Planning case source changed; explicit version review required"))
    (build-planning-case (shasht:read-json (uiop:read-file-string path :external-format :utf-8)) directory)))
(defun planning-case ()
  ;; Revalidate disk evidence even after caching. Keep canonical subjects within
  ;; this runtime; a new runtime reconstructs their source keys, not their EQ.
  (let ((checked (read-planning-case)))
    (or *planning-case* (setf *planning-case* checked))))
(defun case-subject (id) (unique-subject (case-subjects (planning-case)) id))

(defun return-links ()
  (v:html
    (:p (v:object-ref (work:work-page "Collaborative Planning with Codex and SHOP3") :display "Return to collaborative planning reading" :select "Content")
        " / " (v:object-ref (planning-case) :display "Revision case" :select "Planning case")
        " / " (v:object-ref (collaborative-planning-workspace) :display "Planning Workspace" :select "Topicmap"))))

(v:defview planning-document-provenance (document planning-document-version)
  (v:html-view :title "Document provenance" :priority -1
    (v:html (:div :class "planning-reading"
      (:h2 (v:esc (record-label document)))
      (:p "User-submitted source text. Attribution is recorded provenance, not authenticated authorship or an execution instruction.")
      (:dl (dolist (key '("id" "kind" "authority" "attributedTo" "extent" "sha256"))
        (v:html (:dt (v:esc key)) (:dd (v:esc (string-field (subject-record document) key))))))
      (:p (v:object-ref document :display "Complete original text" :select "Original text")
          " / " (v:object-ref (document-pathname document) :display "Retained source file" :select "Text"))
      (when (equal "plan-v2" (subject-id document))
        (v:html (:p "The submitted Plan v2 remains byte-identical. Its missing-export condition and attribution of a user rejection are superseded by the separate user clarification; they are not current findings.")
                (:p (v:object-ref (case-subject "user-clarification") :display "User clarification" :select "Document provenance"))))
      (return-links)))))
(v:defview planning-document-text (document planning-document-version)
  (v:html-view :title "Original text" :priority 0
    (v:html (:h2 (v:esc (format nil "Original text — ~A" (record-label document))))
      (:p "Retained source bytes decoded as UTF-8 and escaped for display. This text is not evaluated.")
      (:pre (v:esc (document-text document)))
      (:p (v:object-ref document :display "Source identity and provenance" :select "Document provenance"))
      (return-links))))

(v:defview planning-text-reading-view (reading planning-text-reading)
  (v:html-view :title "Planning evidence" :priority -1
    (let* ((record (subject-record reading)) (document (reading-document reading))
           (start (gethash "start" record)) (end (gethash "end" record)))
      (v:html (:div :class "planning-reading"
        (:h2 (v:esc (record-label reading)))
        (:p (v:esc (cond ((typep reading 'planning-interpretation) "Codex interpretation proposed for inspection; not a human decision or executable step.")
                  ((typep reading 'planning-review-finding) "Finding stated in Claude's submitted review; not a SHOP3 assessment or an independent runtime result.")
                  (t "Recorded procedural state from the user message; not an authenticated principal or a reusable permission."))))
        (dolist (key '("summary" "status" "scope" "proposedBy" "version"))
          (when (gethash key record) (v:html (:p (v:esc (format nil "~A: ~A" key (gethash key record)))))))
        (:p "Original source: " (v:object-ref document :display (record-label document) :select "Original text"))
        (:p (v:esc (format nil "Unicode character span [~D, ~D), source lines ~D–~D; checked against the complete document SHA-256."
                         start end (1+ (count #\Newline (document-text document) :end start))
                         (1+ (count #\Newline (document-text document) :end (1- end))))))
        (:pre (v:esc (gethash "quote" record)))
        (:p (v:object-ref (source-identity reading) :display "Structured source identity"))
        (return-links))))))

(v:defview planning-case-view (case recorded-planning-case)
  (v:html-view :title "Planning case" :priority -1
    (v:html (:div :class "planning-reading"
      (:h2 "Collaborative planning — the documented revision case")
      (:p "Codex Plan v1 → Claude Review → implementation authorization not yet granted → Codex Plan v2 is a reading path, not an inferred browser event log or an assertion of a user rejection.")
      (:p "The historical pending state remains recorded. The subsequent user authorization permits local Slice 1 only. It does not authorize SHOP3 assessment, a P3 referent contract, Inspector confirmation or association writing.")
      (:ol (dolist (id '("plan-v1" "claude-review" "chatgpt-recommendation" "approval-pending" "plan-v2" "user-clarification" "slice-1-approved"))
        (let ((subject (unique-subject (case-subjects case) id)))
          (v:html (:li (v:object-ref subject :display (record-label subject)
                            :select (if (typep subject 'planning-document-version) "Document provenance" "Planning evidence")))))))
      (:h3 "Proposed interpretations")
      (:ul (dolist (id '("interpretation-v1" "interpretation-v2"))
        (v:html (:li (v:object-ref (case-subject id) :display (record-label (case-subject id)) :select "Planning evidence")))))
      (:h3 "Claude review findings")
      (:ul (loop for n from 1 to 11 for id = (format nil "F~D" n) do
        (v:html (:li (v:object-ref (case-subject id) :display (format nil "F~D" n) :select "Planning evidence")))))
      (:p (v:object-ref (work:work-page "Work Breakdown") :display "Work Breakdown" :select "Content")
          " / " (v:object-ref (work:work-page "Planning with SHOP3") :display "Planning / SHOP3" :select "Content")
          " / " (v:object-ref (work:work-page "HyperDoc Dogfooding") :display "HyperDoc Dogfooding" :select "Content"))
      (:p "Linked application, not planning authority: "
          (v:object-ref hubs::*hub-investigation-plan* :display "Ward hub selection investigation" :select "Investigation Plan"))
      (:p (v:object-ref (case-pathname case) :display "Case source and relation warrants" :select "Text")
          " / " (v:object-ref (merge-pathnames "MANIFEST.txt" (evidence-directory)) :display "Submitted SHA-256 manifest" :select "Text"))
      (:p (v:object-ref (subject-record case) :display "Archive, base revision and complete provenance record"))
      (return-links)))))

(defun collaborative-planning-projection ()
  "Project this case, reusing Work subjects and the existing application object.
The application Workspace and its 26/28 projection remain unchanged."
  (let* ((case (planning-case)) (work (work:work-projection)) (topics nil) (edges nil))
    (labels ((topic (id label object kind)
               (let ((i (length topics)))
                 (push (tm:make-topicmap-topic :id id :label label :object object :type :collaborative-planning
                         :view-properties (list :x (* 280 (mod i 4)) :y (* 110 (floor i 4)) :visible t :kind kind)) topics))))
      (dolist (id '("planning" "dogfooding" "collaborative-planning-case"))
        (let ((existing (tm:topicmap-projection-topic-by-id work id)))
          (unless existing (error "Missing declared Work subject: ~A" id))
          (topic id (tm:topicmap-topic-label-of existing) (tm:topicmap-topic-object-of existing)
                 (getf (tm:topicmap-topic-view-properties-of existing) :kind))))
      (topic "hub-investigation" "Ward hub selection investigation" hubs::*hub-investigation-plan* "linked application")
      (dolist (subject (case-subjects case))
        (topic (subject-id subject) (record-label subject) subject (type-of subject)))
      (dolist (id '("work:planning:contains:collaborative-planning-case" "work:dogfooding:current-work:collaborative-planning-case"))
        (let ((edge (find id (tm:topicmap-projection-associations-of work) :key #'tm:topicmap-association-id-of :test #'equal)))
          (unless edge (error "Missing source-backed Work relationship ~A" id))
          (push edge edges)))
      (loop for edge across (gethash "relations" (subject-record case)) do
        (push (tm:make-topicmap-association :id (gethash "id" edge) :from (gethash "from" edge) :to (gethash "to" edge)
               :type (gethash "relation" edge)
               :properties (list :planning-case case :warrant (gethash "warrant" edge)
                                 :source (unique-subject (case-subjects case) (gethash "source" edge)))) edges))
      (tm:make-topicmap-projection :source case :topics (nreverse topics) :associations (nreverse edges)
                                  :view-properties '(:width 1180 :height 880)))))

(hyperdoc:defexample collaborative-planning-workspace
  "Read retained documents into a native Workspace; never run a planner or writer."
  (or *planning-workspace*
      (setf *planning-workspace* (tm:make-topicmap-workspace (collaborative-planning-projection) "collaborative-planning-case"))))

(v:defview planning-association-evidence (edge tm:topicmap-association)
  (when (getf (tm:topicmap-association-properties-of edge) :planning-case)
    (v:html-view :title "Planning relation evidence" :priority -1
      (v:html (:h2 "Planning relation evidence")
        (:p (v:esc (format nil "~A → ~A → ~A" (tm:topicmap-association-from-of edge)
                     (tm:topicmap-association-type-of edge) (tm:topicmap-association-to-of edge))))
        (:p "Warrant: " (v:esc (getf (tm:topicmap-association-properties-of edge) :warrant)))
        (:p (v:object-ref (getf (tm:topicmap-association-properties-of edge) :source) :display "Source of this relation"))
        (:p "This association documents the case; it grants no execution permission.")
        (return-links)))))
