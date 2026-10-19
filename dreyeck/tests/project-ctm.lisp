;;;; The project CTM: tests that need no CTM read-back
(defpackage #:dreyeck/work/project/tests
  (:use #:cl)
  (:local-nicknames (#:p #:dreyeck/work/project) (#:work #:dreyeck/work/reading) (#:plan #:dreyeck/work/ctm-page-authoring)
                    (#:v #:html-inspector-views))
  (:export #:run-tests #:run-source-tests))
(in-package #:dreyeck/work/project/tests)

;; These tests check the emitter against the authoritative pages. None of them reads the CTM back into TMDM, so none of
;; them shows that the CTM means what the pages declare: that needs the read-back and the CXTM comparison, which wait for a
;; topic-maps reader that reads the whole document (see the report of the reader-scaling assignment). Expected sets come
;; from the pages, read here directly with an HTML parser, and from the existing Work reader; no count is written down.

(defvar *checks* 0)
(defmacro check (label form) `(progn (incf *checks*) (unless ,form (error "Check failed: ~A" ,label))))

(defun %dom (text) (let ((plump:*tag-dispatchers* plump:*html-tags*)) (plump:parse text)))
(defun %with (tag attribute text)
  (remove-if-not (lambda (node) (plump:attribute node attribute)) (plump:get-elements-by-tag-name (%dom text) tag)))
(defun %item (sources role) (find role (p:sources-items sources) :key #'p::source-role))
(defun %sha (pathname) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 pathname)))
(defun %source-digests () (mapcar (lambda (item) (%sha (merge-pathnames (p:source-path item) (p::repository-root))))
                                  (p:sources-items (p:read-project-sources))))
(defun %replace-all (text old new)
  (with-output-to-string (out)
    (loop with start = 0 for at = (search old text :start2 start)
          do (write-string text out :start start :end (or at (length text)))
          while at do (write-string new out) (setf start (+ at (length old))))))
(defun %replace (text old new)
  (let ((at (search old text))) (assert at () "~S not in the page" old) (concatenate 'string (subseq text 0 at) new (subseq text (+ at (length old))))))

;;; Determinism and the retained file

(defun determinism-tests ()
  (let ((a (p:materialize-project-ctm)) (b (p:materialize-project-ctm))
        (retained (uiop:read-file-string (p:project-ctm-pathname) :external-format :utf-8)))
    (check "deterministic:two-materializations-equal" (string= a b))
    (check "deterministic:retained-file-is-what-the-pages-give-now" (string= a retained))
    (check "deterministic:digest-kept-beside-the-file-not-in-it"
           (let ((line (uiop:read-file-line (p:project-ctm-digest-pathname))))
             (and (string= (subseq line 0 64) (%sha (p:project-ctm-pathname))) (not (search (subseq line 0 64) retained)))))))

;;; Inputs: the source pages and the control test files are read; nothing else

(defun input-tests (model)
  (let* ((text (p:model-text model)) (inputs (p:model-evidence-inputs model))
         (read-paths (append (mapcar #'p:source-path (p:sources-items (p::model-sources model))) (mapcar #'p:evidence-path inputs))))
    (dolist (item (p:sources-items (p::model-sources model)))
      (check (format nil "inputs:header-lists-source:~A" (p:source-path item))
             (search (format nil "#   ~A  ~A" (p:source-path item) (p:source-sha256 item)) text)))
    (dolist (input inputs)
      (check (format nil "inputs:header-lists-evidence:~A" (p:evidence-path input))
             (search (format nil "#   ~A  ~A" (p:evidence-path input) (p:evidence-sha256 input)) text))
      (check (format nil "inputs:evidence-digest-is-the-file:~A" (p:evidence-path input))
             (equal (p:evidence-sha256 input) (%sha (merge-pathnames (p:evidence-path input) (p::repository-root))))))
    ;; Every digest in the document belongs to a file that was read.
    (let ((digests (loop for start = (search "source-sha256: \"" text) then (search "source-sha256: \"" text :start2 (1+ start))
                         while start collect (subseq text (+ start 16) (+ start 80)))))
      (check "inputs:every-digest-is-of-a-file-read"
             (every (lambda (d) (member d (append (mapcar #'p:source-sha256 (p:sources-items (p::model-sources model))) (mapcar #'p:evidence-sha256 inputs))
                                        :test #'equal))
                    digests))
      (check "inputs:no-digest-of-the-document-itself" (not (member (%sha (p:project-ctm-pathname)) digests :test #'equal))))
    (check "inputs:no-file-read-is-a-named-only-file" (= (length read-paths) (length (remove-duplicates read-paths :test #'equal))))
    ;; Control: naming an existing file and naming an absent one write the same block, but for the path.
    (let* ((page (p::source-text (%item (p::model-sources model) :assignments)))
           (existing "dreyeck/work/project/project-ctm.lisp") (absent "dreyeck/work/project/no-such-file.lisp")
           (block (lambda (named)
                    (let* ((m (p:build-project-model (p:read-project-sources :texts (list (cons :assignments (%replace page (format nil "data-changes=\"~A\"" existing) (format nil "data-changes=\"~A\"" named)))))))
                           (t2 (p:model-text m)) (ref (p::%ref (p::file-iri named))) (start (search (format nil "~%~A~%" ref) t2)))
                      (%replace-all (subseq t2 start (search (format nil " .~%") t2 :start2 start)) named "PATH")))))
      (check "inputs:an-existing-and-an-absent-named-file-write-the-same-block"
             (string= (funcall block existing) (funcall block absent))))))

;;; Correspondence with the declarations, read independently of the emitter

(defun correspondence-tests (model)
  (let ((sources (p::model-sources model)) (declared (remove-if #'p::declaration-proposal-p (p:model-declarations model))))
    ;; 1. The HTML of each Work page, read directly.
    (dolist (role '(:work-breakdown :plan))
      (let* ((item (%item sources role)) (text (p::source-text item))
             (anchors (%with "a" "data-topic" text)) (statements (%with "li" "data-from" text))
             (mine (remove item declared :key #'p::declaration-source :test-not #'eq))
             (my-statements (remove item (p:model-statements model) :key #'p::statement-source :test-not #'eq)))
        (check (format nil "correspond:~(~A~):same-declarations-in-page-order" role)
               (equal (mapcar (lambda (n) (plump:attribute n "data-topic")) anchors) (mapcar #'p:declaration-id mine)))
        (check (format nil "correspond:~(~A~):same-kinds-and-statuses" role)
               (equal (mapcar (lambda (n) (list (plump:attribute n "data-kind") (plump:attribute n "data-status"))) anchors)
                      (mapcar (lambda (d) (list (p:declaration-kind d) (p:declaration-status d))) mine)))
        (check (format nil "correspond:~(~A~):same-statements-in-page-order" role)
               (equal (mapcar (lambda (n) (list (plump:attribute n "data-from") (plump:attribute n "data-relation") (plump:attribute n "data-to"))) statements)
                      (mapcar (lambda (s) (list (p:statement-from s) (p:statement-relation s) (p:statement-to s))) my-statements)))))
    ;; 2. The existing Work reader of the Work Breakdown and the reading of the CTM plan page.
    (let ((projection (work:work-projection)))
      (check "correspond:work-reader:every-work-breakdown-topic"
             (null (set-exclusive-or (mapcar #'dreyeck/topicmap:topicmap-topic-id-of (dreyeck/topicmap:topicmap-projection-topics-of projection))
                                     (mapcar #'p:declaration-id (remove (%item sources :work-breakdown) declared :key #'p::declaration-source :test-not #'eq))
                                     :test #'equal))))
    (let ((reading (plan:read-ctm-authoring)))
      (check "correspond:plan-reader:every-wbs-element-step-and-precondition"
             (every (lambda (subject) (find (plan::subject-id subject) declared :key #'p:declaration-id :test #'equal)) (plan::reading-subjects reading)))
      (check "correspond:plan-reader:every-dictionary-entry"
             (equal (mapcar #'plan::entry-element-id (plan::reading-entries reading)) (mapcar #'plan::entry-element-id (p::model-entries model)))))
    t))

;;; Provenance: every declaration, proposal and statement written with the page that declares, proposes or states it

(defun provenance-tests (model)
    (let ((text (p:model-text model)))
      (dolist (d (p:model-declarations model))
        (check (format nil "provenance:~A:declared-or-proposed-on-its-page" (p:declaration-id d))
               (search (format nil "~A(~A: ~A, ~A: ~A)" (p::%ref (p:schema-iri (if (p::declaration-proposal-p d) "proposed-on" "declared-on")))
                               (p::%ref (p:schema-iri (if (p::declaration-proposal-p d) "proposal" "declaration"))) (p::%ref (p:topic-iri (p:declaration-id d)))
                               (p::%ref (p:schema-iri "source-page")) (p::%ref (p:declaration-page-iri d)))
                       text)))
      (dolist (s (p:model-statements model))
        (check (format nil "provenance:~A:stated-or-proposed-on-its-page" (p:statement-iri s))
               (search (format nil "~A(~A: ~A, ~A: ~A)" (p::%ref (p:schema-iri (if (p::statement-proposal-p s) "proposed-on" "stated-on")))
                               (p::%ref (p:schema-iri (if (p::statement-proposal-p s) "proposal" "statement"))) (p::%ref (p:statement-iri s))
                               (p::%ref (p:schema-iri "source-page")) (p::%ref (p:statement-page-iri s)))
                       text))
        (check (format nil "provenance:~A:typed-with-source-and-target-roles-and-reified" (p:statement-iri s))
               (search (format nil "~A(~A: ~A, ~A: ~A) ~~ ~A" (p::%ref (p:relation-type-iri (p:statement-relation s)))
                               (p::%ref (p:role-type-iri (p:statement-relation s) :source)) (p::%ref (p:topic-iri (p:statement-from s)))
                               (p::%ref (p:role-type-iri (p:statement-relation s) :target)) (p::%ref (p:topic-iri (p:statement-to s)))
                               (p::%ref (p:statement-iri s)))
                       text)))))

;;; Identity: from authored IDs, not from names or positions

(defun identity-tests (model)
  (dolist (d (p:model-declarations model))
    (check (format nil "identity:~A:subject-identifier-from-its-id" (p:declaration-id d))
           (string= (p:topic-iri (p:declaration-id d)) (concatenate 'string p:+base+ "work/topic/" (p:declaration-id d)))))
  (let* ((plan-text (p::source-text (%item (p::model-sources model) :plan)))
         ;; Rename a label, and swap the order of two declarations on the page.
         (renamed (%replace plan-text ">Verified page source<" ">A renamed label<"))
         (first (search "<li><a page=\"CTM Plan Page WBS Dictionary\" data-topic=\"ctm-wp-1\"" renamed))
         (end1 (search "</li>" renamed :start2 first)) (end2 (search "</li>" renamed :start2 (+ end1 5)))
         (swapped (concatenate 'string (subseq renamed 0 first) (subseq renamed (+ end1 5) (+ end2 5)) (subseq renamed first (+ end1 5)) (subseq renamed (+ end2 5))))
         (changed (p:build-project-model (p:read-project-sources :texts (list (cons :plan swapped)))))
         (iris (lambda (m) (sort (mapcar (lambda (d) (p:topic-iri (p:declaration-id d))) (p:model-declarations m)) #'string<)))
         ;; Positive control: the same precondition under another ID, in its declaration and in the statements naming it.
         (control (p:build-project-model (p:read-project-sources :texts (list (cons :plan (%replace-all plan-text "\"ctm-pre-content\"" "\"ctm-pre-content-renamed\"")))))))
    (check "identity:names-and-positions-do-not-change-identifiers" (equal (funcall iris model) (funcall iris changed)))
    (check "identity:a-renamed-label-is-only-a-name" (find "A renamed label" (p:model-declarations changed) :key #'p:declaration-label :test #'equal))
    (check "identity:positive-control-a-changed-id-changes-the-identifier"
           (null (set-exclusive-or (set-exclusive-or (funcall iris model) (funcall iris control) :test #'string=)
                                   (list (p:topic-iri "ctm-pre-content-renamed") (p:topic-iri "ctm-pre-content")) :test #'string=)))))

;;; WBS decomposition, plan dependency, result and evidence stay apart

(defun separation-tests (model)
  (let ((kinds (make-hash-table :test #'equal)))
    (dolist (d (p:model-declarations model)) (setf (gethash (p:declaration-id d) kinds) (p:declaration-kind d)))
    (flet ((statements (relation) (remove relation (p:model-statements model) :key #'p:statement-relation :test-not #'equal))
           (kind (id) (gethash id kinds)))
      (check "separate:decomposes-into:deliverable-to-work-package"
             (every (lambda (s) (and (equal "deliverable" (kind (p:statement-from s))) (equal "work package" (kind (p:statement-to s)))))
                    (statements "work:relation/decomposes-into")))
      (check "separate:produces:plan-step-to-work-package"
             (every (lambda (s) (and (equal "plan step" (kind (p:statement-from s))) (equal "work package" (kind (p:statement-to s)))))
                    (statements "work:relation/produces")))
      (check "separate:depends-on:plan-step-to-step-or-precondition"
             (every (lambda (s) (and (equal "plan step" (kind (p:statement-from s))) (member (kind (p:statement-to s)) '("plan step" "precondition") :test #'equal)))
                    (statements "work:relation/depends-on")))
      (check "separate:three-distinct-association-types"
             (= 3 (length (remove-duplicates (mapcar #'p:relation-type-iri '("work:relation/decomposes-into" "work:relation/depends-on" "work:relation/produces")) :test #'equal))))
      (check "separate:role-types-belong-to-their-association-type"
             (= 6 (length (remove-duplicates (loop for r in '("work:relation/decomposes-into" "work:relation/depends-on" "work:relation/produces")
                                                   append (list (p:role-type-iri r :source) (p:role-type-iri r :target)))
                                             :test #'equal))))
      ;; Evidence is never a plan relation: controls and tests appear only through the dictionary's own Associations.
      (let ((text (p:model-text model)))
        (check "separate:evidence-only-through-controls"
               (and (search (p::%ref (p:schema-iri "planned-control-of")) text) (search (p::%ref (p:schema-iri "exercised-by")) text)
                    (notany (lambda (s) (search "control/" (p:statement-to s))) (p:model-statements model))))
        (check "separate:status-is-an-occurrence-and-no-scope-is-written"
               (and (search (p::%ref (p:schema-iri "work-status")) text) (not (search ") @" text))))))))

;;; Nothing invented

(defun invention-tests (model)
  (let* ((text (p:model-text model)) (known (mapcar (lambda (d) (p:topic-iri (p:declaration-id d))) (p:model-declarations model)))
         (namespace (concatenate 'string p:+base+ "work/topic/")) (written nil))
    ;; Every Work Topic identifier the text writes, whether as w:local or as <IRI>.
    (loop for start = (search "w:" text) then (search "w:" text :start2 (1+ start)) while start
          do (when (and (plusp start) (find (char text (1- start)) '(#\Space #\Newline #\()))
               (let ((end (position-if-not (lambda (c) (or (alphanumericp c) (find c "_-"))) text :start (+ start 2))))
                 (push (concatenate 'string namespace (subseq text (+ start 2) end)) written))))
    (loop for start = (search (concatenate 'string "<" namespace) text) then (search (concatenate 'string "<" namespace) text :start2 (1+ start))
          while start do (let ((iri (subseq text (1+ start) (position #\> text :start start))))
                           ;; The %prefix directive names the namespace itself, which is no Topic.
                           (unless (string= iri namespace) (push iri written))))
    (check "invented:every-work-topic-written-is-declared-or-proposed"
           (every (lambda (iri) (member iri known :test #'string=)) (remove-duplicates written :test #'string=)))
    (check "invented:proposals-carry-no-work-status"
           (every (lambda (d) (null (p:declaration-status d))) (p:model-proposals model)))
    (check "invented:proposals-are-never-declared-on-a-work-page"
           (notany (lambda (d) (member (p::source-role (p::declaration-source d)) '(:work-breakdown :plan))) (p:model-proposals model)))
    (check "invented:every-planning-association-is-an-authored-or-proposed-statement"
           (loop for relation in '("work:relation/decomposes-into" "work:relation/depends-on" "work:relation/produces")
                 always (= (count relation (p:model-statements model) :key #'p:statement-relation :test #'equal)
                           (loop for start = (search (format nil "~A(" (p::%ref (p:relation-type-iri relation))) text)
                                   then (search (format nil "~A(" (p::%ref (p:relation-type-iri relation))) text :start2 (1+ start))
                                 while start count t))))
    (check "invented:gaps-state-no-work-relation"
           (notany (lambda (s) (search "gap/" (p:statement-from s))) (p:model-statements model)))))

(defun run-source-tests ()
  "The tests that need no CTM read-back. Source pages are compared before and after; nothing is written."
  (let ((*checks* 0) (before (%source-digests)) (ctm-before (%sha (p:project-ctm-pathname))))
    (let ((model (p:build-project-model)))
      (determinism-tests)
      (correspondence-tests model)
      (provenance-tests model)
      (input-tests model)
      (identity-tests model)
      (separation-tests model)
      (invention-tests model))
    (check "preserved:source-pages-unchanged" (equal before (%source-digests)))
    (check "preserved:retained-ctm-unchanged" (equal ctm-before (%sha (p:project-ctm-pathname))))
    (format t "~&PROJECT-CTM-SOURCE-PASS: ~D checks; no CTM read-back (not semantically validated)~%" *checks*)
    *checks*))

;;; Read-back: the complete CTM through the pinned topic-maps reader, into TMDM, the Workspace and the export

(defun %expand (ref)
  "The IRI a reference written by the emitter names: s:local, w:local or <IRI>."
  (cond ((char= #\< (char ref 0)) (subseq ref 1 (1- (length ref))))
        ((eql 0 (search "s:" ref)) (concatenate 'string (p::%namespace "schema") (subseq ref 2)))
        ((eql 0 (search "w:" ref)) (concatenate 'string (p::%namespace "work" "topic") (subseq ref 2)))
        (t (error "Unknown reference ~S" ref))))
(defun %written (text)
  "What the text writes: the subject of every Topic block, every Association line by its type, and every isa."
  (let ((lines (uiop:split-string text :separator '(#\Newline))) (subjects nil) (associations nil) (isa 0))
    (loop for (line next) on lines
          do (cond ((and next (plusp (length line)) (not (find (char line 0) "#% ")) (not (find #\( line)) (eql 0 (search "    " next)))
                    (push (%expand line) subjects))
                   ((and (plusp (length line)) (not (find (char line 0) "#% ")) (find #\( line))
                    (push (%expand (subseq line 0 (position #\( line))) associations)))
             (when (eql 0 (search "    isa " line)) (incf isa)))
    (values subjects associations isa)))

(defun readback-tests ()
  (let* ((identity (p::topic-maps-source-identity)) (start (get-internal-real-time))
         (reading (p:project-workspace)) (seconds (/ (- (get-internal-real-time) start) internal-time-units-per-second))
         (model (p:reading-model reading)) (document (p:reading-document reading)) (map (p:revision-map document))
         (text (p:model-text model)) (index (p::%index map)))
    (check "pin:loaded-reader-is-the-pinned-clean-revision" (getf identity :pinned))
    (check "read:complete-ctm-read-without-refusal" (and map (null (p:revision-refusal document))))
    (check "read:within-90-seconds-with-the-model" (< seconds 90))
    ;; Topics: every subject the text writes is one Topic with that subject identifier; nothing else but TMDM's own.
    (multiple-value-bind (subjects associations isa) (%written text)
      (let ((written (remove-duplicates subjects :test #'string=)))
        (check "topics:every-written-subject-is-a-topic" (every (lambda (iri) (gethash iri index)) written))
        (check "topics:no-two-written-subjects-merged" (= (length written) (length (remove-duplicates (mapcar (lambda (iri) (gethash iri index)) written)))))
        (check "topics:each-topic-has-exactly-one-subject-identifier"
               (every (lambda (topic) (= 1 (length (topic-maps.tmdm:topic-subject-identifiers topic)))) (topic-maps.tmdm:topic-map-topics map)))
        (check "topics:only-tmdm-core-and-default-name-type-besides"
               (every (lambda (topic) (let ((si (first (topic-maps.tmdm:topic-subject-identifiers topic))))
                                        (or (member si written :test #'string=)
                                            (eql 0 (search "http://psi.topicmaps.org/iso13250/model/" si)))))
                      (topic-maps.tmdm:topic-map-topics map))))
      ;; Associations: every line and every isa is one Association, by type.
      (check "associations:count-is-lines-plus-isa" (= (+ (length associations) isa) (length (topic-maps.tmdm:topic-map-associations map))))
      (dolist (type (remove-duplicates associations :test #'string=))
        (check (format nil "associations:~A:count" type)
               (= (count type associations :test #'string=) (length (p::%of-type map type)))))
      (check "associations:isa-are-type-instance" (= isa (length (p::%of-type map p::+type-instance+)))))
    ;; Roles: every statement has its two Roles, typed by its relation, and its reifier.
    (dolist (st (p:model-statements model))
      (let* ((reifier (gethash (p:statement-iri st) index))
             (association (find reifier (topic-maps.tmdm:topic-map-associations map) :key #'topic-maps.tmdm:item-reifier)))
        (check (format nil "roles:~A" (p:statement-iri st))
               (and association (= 2 (length (topic-maps.tmdm:association-roles association)))
                    (eq (p::%player association (p:role-type-iri (p:statement-relation st) :source)) (gethash (p:topic-iri (p:statement-from st)) index))
                    (eq (p::%player association (p:role-type-iri (p:statement-relation st) :target)) (gethash (p:topic-iri (p:statement-to st)) index))))))
    ;; Against the authoritative pages: declarations, statements, provenance, dictionary, assignments.
    (check "trace:topic-map-equals-the-declarations-of-the-pages" (null (p:trace-project-map map model)))
    (dolist (entry (p::model-entries model))
      (let ((package (gethash (p:topic-iri (plan::entry-element-id entry)) index)))
        (loop for (field . name) in '(("scope" . "wbs-scope") ("acceptance" . "wbs-acceptance-criterion") ("authority" . "wbs-authority") ("effect" . "wbs-effect") ("evidence" . "wbs-evidence"))
              do (check (format nil "dictionary:~A:~A" (plan::entry-element-id entry) field)
                        (equal (list (plan::entry-field entry field)) (p::%occurrences package (p:schema-iri name)))))))
    (dolist (a (p:model-assignments model))
      (let ((topic (gethash (p::%iri "assignment" (p::assignment-id a)) index)))
        (check (format nil "assignment:~A:goal" (p::assignment-id a))
               (equal (list (cdr (assoc "goal" (p::assignment-fields a) :test #'equal))) (p::%occurrences topic (p:schema-iri "goal"))))
        (check (format nil "assignment:~A:evidence-entries" (p::assignment-id a))
               (equal (sort (mapcar #'car (cdr (assoc "evidence" (p::assignment-lists a) :test #'equal))) #'string<)
                      (sort (copy-list (p::%occurrences topic (p:schema-iri "evidence-note"))) #'string<)))
        (check (format nil "assignment:~A:no-acceptance-recorded" (p::assignment-id a))
               (equal (p::%occurrences topic (p:schema-iri "acceptance")) (list "No acceptance by the user is recorded.")))))
    ;; CXTM: the file and a materialization now mean the same; a changed status does not.
    (let ((c (p:compare-revisions document (p::reading-fresh reading))))
      (check "cxtm:file-and-sources-equal" (and (getf c :octets-equal) (getf c :cxtm-equal))))
    (let* ((changed (p:ctm-revision-from-octets (sb-ext:string-to-octets (%replace text "s:work-status: \"open\"" "s:work-status: \"closed\"") :external-format :utf-8)
                                                :label "changed status"))
           (c (p:compare-revisions document changed)))
      (check "cxtm:positive-control-changed-status-detected" (and (not (getf c :octets-equal)) (not (getf c :cxtm-equal))))
      (check "trace:positive-control-changed-status-reported" (p:trace-project-map (p:revision-map changed) model)))
    ;; Export: exactly the observed octets, also as offered by the rendered download link.
    (let ((octets (with-open-file (in (p:project-ctm-pathname) :element-type '(unsigned-byte 8))
                    (let ((v (make-array (file-length in) :element-type '(unsigned-byte 8)))) (read-sequence v in) v))))
      (check "export:octets-equal-the-file" (equalp octets (p:revision-export-octets document)))
      (let* ((html (v:view-html (find "CTM document" (v:all-views document) :key #'v:view-title :test #'equal)))
             (start (+ (search "base64," html) 7)) (end (position-if (lambda (c) (find c "'\"")) html :start start)))
        (check "export:rendered-download-link-decodes-to-the-file" (equalp octets (cl-base64:base64-string-to-usb8-array (subseq html start end))))))
    ;; Import of revisions: an unchanged copy and a changed one; refusals kept as data.
    (uiop:with-temporary-file (:pathname copy :type "ctm" :keep nil)
      (uiop:copy-file (p:project-ctm-pathname) copy)
      (let* ((revision (p:import-project-ctm-revision copy reading)) (c (p:compare-revisions document revision)))
        (check "import:unchanged-copy-equal-octets-and-cxtm" (and (getf c :octets-equal) (getf c :cxtm-equal)))))
    (let* ((template (p:ctm-revision-from-octets (sb-ext:string-to-octets "def t() end" :external-format :utf-8) :label "template"))
           (latin (p:ctm-revision-from-octets (coerce #(97 32 45 32 34 233 34 32 46) '(vector (unsigned-byte 8))) :label "latin-1")))
      (check "refuse:template-unsupported" (eq :unsupported-keyword (first (p:revision-refusal template))))
      (check "refuse:not-utf-8" (eq :not-utf-8 (first (p:revision-refusal latin))))
      (check "refuse:no-topic-map-from-a-refusal" (and (null (p:revision-map template)) (null (p:revision-map latin)))))
    ;; The native Workspace: from the project to a precondition, and from the assignment to its evidence; back along History.
    (let ((ws (p:reading-workspace reading)))
      (flet ((walk (path)
               (dolist (key path t)
                 (unless (member key (mapcar (lambda (a) (dreyeck/topicmap::topicmap-association-other-topic-id ws a))
                                             (dreyeck/topicmap::topicmap-associations-of-point ws)) :test #'equal)
                   (return nil))
                 (dreyeck/topicmap:topicmap-workspace-go-to ws key))))
        (dreyeck/topicmap:topicmap-workspace-go-to ws "hyperbook/dreyeck/work/reading")
        (check "workspace:project-work-item-package-step-precondition"
               (walk '("page/dreyeck/work/reading/work-breakdown" "ctm-plan-page-authoring" "page/dreyeck/work/reading/authoring-the-ctm-plan-page"
                       "ctm-page-edit" "ctm-wp-2" "ctm-plan-p2" "ctm-pre-content")))
        (check "workspace:history-leads-back"
               (equal (subseq (dreyeck/topicmap:topicmap-workspace-history-of ws) 0 2) '("ctm-plan-p2" "ctm-wp-2")))
        (dreyeck/topicmap:topicmap-workspace-go-to ws "ctm-wp-3")
        (check "workspace:package-to-control-to-test-evidence"
               (walk '("control/ctm-wp-3/journal-continued" "file/dreyeck/tests/fedwiki-page-authoring.lisp")))
        (dreyeck/topicmap:topicmap-workspace-go-to ws "page/dreyeck/work/project/implementation-assignments")
        (check "workspace:assignments-page-to-assignment-to-evidence"
               (walk '("assignment/cc-2026-10-19-topic-maps-reader-scaling" "file/dreyeck/tests/project-ctm.lisp")))
        (check "workspace:assignment-to-proposed-work-item"
               (walk '("assignment/cc-2026-10-19-topic-maps-reader-scaling" "project-work-ctm")))
        (dreyeck/topicmap:topicmap-workspace-go-to ws "hyperbook/dreyeck/work/reading")))
    ;; Inspector: every view renders; a declared Topic links its page, its declaration occurrence and its TMDM Topic.
    (let ((errors 0))
      (dolist (object (list* reading document (p:reading-workspace reading) (dreyeck/topicmap:topicmap-projection-topics-of (p:reading-projection reading))))
        (dolist (view (v:all-views object))
          (when (typep view 'v::html-view) (handler-case (v:view-html view) (error () (incf errors))))))
      (check "inspector:every-view-of-reading-document-workspace-and-topics-renders" (zerop errors)))
    (let* ((ws (p:reading-workspace reading)) (topic (dreyeck/topicmap:topicmap-projection-topic-by-id (p:reading-projection reading) "ctm-wp-2"))
           (html (dreyeck/topicmap:topicmap-workspace-go-to ws "ctm-wp-2"))
           (view (find "Topicmap" (v:all-views ws) :key #'v:view-title :test #'equal))
           (refs (progn (v:view-html view) (mapcar #'cdr (v:view-references view)))))
      (declare (ignore html))
      (check "inspector:point-panel-links-the-declaration-in-its-page-source" (find-if (lambda (r) (typep r 'work:work-topic-source-occurrence)) refs))
      (check "inspector:point-panel-links-the-represented-tmdm-topic" (member (dreyeck/topicmap:topicmap-topic-object-of topic) refs))
      (check "inspector:point-panel-links-the-hyperdoc-page" (find-if (lambda (r) (typep r 'hyperbook:page)) refs)))
    (let ((overview (v:view-html (find "Project" (v:all-views reading) :key #'v:view-title :test #'equal))))
      (dolist (a (p:model-assignments model))
        (check (format nil "inspector:project-view-offers-~A" (p::assignment-id a)) (search (p::assignment-title a) overview)))
      (check "inspector:project-view-offers-the-ctm-document" (search "The project CTM document" overview)))
    (check "nothing-written:no-page-authoring-writer-loaded" (null (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
    seconds))

(defun run-readback-tests ()
  (let ((*checks* 0) (before (%source-digests)) (ctm-before (%sha (p:project-ctm-pathname))))
    (let ((seconds (readback-tests)))
      (check "preserved:source-pages-unchanged" (equal before (%source-digests)))
      (check "preserved:retained-ctm-unchanged" (equal ctm-before (%sha (p:project-ctm-pathname))))
      (format t "~&PROJECT-CTM-READBACK-PASS: ~D checks; complete CTM read with topic-maps ~A in ~,1Fs with the model~%"
              *checks* (subseq (getf (p::topic-maps-source-identity) :commit) 0 7) seconds))
    *checks*))

(defun run-tests () (+ (run-source-tests) (run-readback-tests)))
