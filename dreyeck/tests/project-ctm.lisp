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

;;; An independent oracle: the Topic and Association identities the four source pages state, derived from their HTML with the identifier
;;; scheme the emitter documents in its header, and without the emitter's own functions. Compared with the read-back Topic Map in both
;;; directions and with multiplicity, and with the committed revision of the project CTM.

(defparameter +h+ "tag:dreyeck.ch,2026:hyperdoc/")
(defparameter +type-instance+ "http://psi.topicmaps.org/iso13250/model/type-instance")
(defparameter +derived-association-types+
  (list +type-instance+ (concatenate 'string +h+ "schema/contains-page") (concatenate 'string +h+ "schema/gap-concerns"))
  "Association types that no page states: the emitter derives them by rule (a type, a page's HyperBook, a gap).")
(defun %o-slug (title)
  (string-trim "-" (with-output-to-string (s)
                     (let ((gap nil))
                       (loop for c across (string-downcase title)
                             do (if (and (alphanumericp c) (< (char-code c) 128))
                                    (progn (when gap (write-char #\- s)) (setf gap nil) (write-char c s))
                                    (setf gap t)))))))
(defun %o (&rest parts) (format nil "~A~{~A~^/~}" +h+ parts))
(defun %o-work (id) (%o "work/topic" id))
(defun %o-schema (name) (%o "schema" name))
(defun %o-page (book title) (%o "page" book (%o-slug title)))
(defun %o-contract-p (relation) (and (> (length relation) 14) (string= "work:relation/" relation :end2 14)))
(defun %o-relation-type (relation)
  (if (%o-contract-p relation) (%o-work relation) (%o-schema (format nil "relation-word-~A" (%o-slug relation)))))
(defun %o-role (relation end)
  (%o-schema (format nil "role-~A-~(~A~)" (if (%o-contract-p relation) (%o-slug relation) (format nil "word-~A" (%o-slug relation))) end)))
(defun %o-path (path)
  "The Topic a path names: a page of the project's two HyperBooks if it is an .html file directly in their page directory, else a file."
  (loop for (directory . book) in '(("dreyeck/pages/work/" . "dreyeck/work/reading") ("dreyeck/pages/project/" . "dreyeck/work/project"))
        when (and (eql 0 (search directory path)) (> (length path) (+ (length directory) 5))
                  (string= ".html" path :start2 (- (length path) 5)) (not (find #\/ path :start (length directory))))
          do (return-from %o-path (%o-page book (subseq path (length directory) (- (length path) 5)))))
  (%o "file" path))
(defun %o-signature (type roles &optional reifier)
  (format nil "~A(~{~A~^, ~})~@[ ~~ ~A~]" type (sort (mapcar (lambda (r) (format nil "~A: ~A" (car r) (cdr r))) roles) #'string<) reifier))
(defun %field (node name &optional (tag "p"))
  (find name (plump:get-elements-by-tag-name node tag) :key (lambda (n) (plump:attribute n "data-field")) :test #'equal))

(defun source-oracle (items)
  "The Associations the source ITEMS state, as signatures (a list with repetitions), and the Topic identities they name."
  (let ((associations nil) (topics nil))
    (labels ((assoc! (type roles &optional reifier)
               (push (%o-signature type roles reifier) associations)
               (dolist (r roles) (push (cdr r) topics)) (when reifier (push reifier topics)))
             (s (name) (%o-schema name))
             (statements (dom page book title from-attr relation-attr to-attr provenance role)
               (let ((seen (make-hash-table :test #'equal)))
                 (dolist (li (remove-if-not (lambda (n) (plump:attribute n from-attr)) (plump:get-elements-by-tag-name dom "li")))
                   (let* ((from (plump:attribute li from-attr)) (rel (plump:attribute li relation-attr)) (to (plump:attribute li to-attr))
                          (n (incf (gethash (list from rel to) seen 0)))
                          (reifier (%o "statement" book (%o-slug title) from rel to (princ-to-string n))))
                     (assoc! (%o-relation-type rel) `((,(%o-role rel :source) . ,(%o-work from)) (,(%o-role rel :target) . ,(%o-work to))) reifier)
                     (when (%o-contract-p rel) (push (%o-relation-type rel) topics))
                     (assoc! (s provenance) `((,(s role) . ,reifier) (,(s "source-page") . ,page)))))))
             (declarations (dom page attribute provenance role)
               (dolist (a (remove-if-not (lambda (n) (plump:attribute n attribute)) (plump:get-elements-by-tag-name dom "a")))
                 (let ((topic (%o-work (plump:attribute a attribute))))
                   (assoc! (s provenance) `((,(s role) . ,topic) (,(s "source-page") . ,page)))
                   (assoc! (s "carried-by") `((,(s "carried") . ,topic)
                                              (,(s "carrier-page") . ,(%o-page (or (plump:attribute a "hyperbook") "dreyeck/work/reading") (plump:attribute a "page")))))))))
      (dolist (item items)
        (let* ((book (p::source-hyperbook-id item)) (title (p::source-title item)) (page (%o-page book title)) (dom (%dom (p::source-text item))))
          (push page topics)
          (ecase (p::source-kind item)
            (:work (declarations dom page "data-topic" "declared-on" "declaration")
                   (statements dom page book title "data-from" "data-relation" "data-to" "stated-on" "statement"))
            (:dictionary
             (dolist (section (remove-if-not (lambda (n) (plump:attribute n "data-wbs-entry")) (plump:get-elements-by-tag-name dom "section")))
               (let* ((id (plump:attribute section "data-wbs-entry")) (package (%o-work id)))
                 (assoc! (s "defined-in-dictionary") `((,(s "work-package") . ,package) (,(s "source-page") . ,page)))
                 (dolist (li (remove-if-not (lambda (n) (plump:attribute n "data-control")) (plump:get-elements-by-tag-name section "li")))
                   (let ((control (%o "control" id (plump:attribute li "data-control"))))
                     (assoc! (s "planned-control-of") `((,(s "work-package") . ,package) (,(s "control") . ,control)))
                     (when (plump:attribute li "data-test")
                       (assoc! (s "exercised-by") `((,(s "control") . ,control) (,(s "test-file") . ,(%o "file" (plump:attribute li "data-test")))))))))))
            (:assignments
             (declarations dom page "data-proposed-topic" "proposed-on" "proposal")
             (statements dom page book title "data-proposed-from" "data-proposed-relation" "data-proposed-to" "proposed-on" "proposal")
             (dolist (section (remove-if-not (lambda (n) (plump:attribute n "data-assignment")) (plump:get-elements-by-tag-name dom "section")))
               (let ((a (%o "assignment" (plump:attribute section "data-assignment"))))
                 (assoc! (s "declared-on") `((,(s "declaration") . ,a) (,(s "source-page") . ,page)))
                 (loop for (field type role) in '(("work-item" "assignment-for" "work-item") ("delivers" "assignment-delivers" "work-package"))
                       for node = (%field section field)
                       when (and node (plump:attribute node "data-ref"))
                         do (assoc! (s type) `((,(s "assignment") . ,a) (,(s role) . ,(%o-work (plump:attribute node "data-ref"))))))
                 (let ((list (%field section "source-authorities" "ul")))
                   (dolist (li (if list (coerce (plump:get-elements-by-tag-name list "li") 'list) nil))
                     (cond ((plump:attribute li "data-reads")
                            (assoc! (s "reads-source") `((,(s "assignment") . ,a) (,(s "source") . ,(%o-path (plump:attribute li "data-reads"))))))
                           ((plump:attribute li "data-changes")
                            (assoc! (s "changes-source") `((,(s "assignment") . ,a) (,(s "file") . ,(%o-path (plump:attribute li "data-changes")))))))))
                 (let ((list (%field section "evidence" "ul")))
                   (dolist (li (if list (coerce (plump:get-elements-by-tag-name list "li") 'list) nil))
                     (when (plump:attribute li "data-test")
                       (assoc! (s "evidenced-by-test") `((,(s "assignment") . ,a) (,(s "test-file") . ,(%o "file" (plump:attribute li "data-test")))))))))))))))
    (values associations (remove-duplicates topics :test #'string=))))

(defun %si1 (topic) (first (topic-maps.tmdm:topic-subject-identifiers (topic-maps.tmdm:canonical-topic topic))))
(defun %association-signature (a)
  (%o-signature (%si1 (topic-maps.tmdm:association-type a))
                (mapcar (lambda (r) (cons (%si1 (topic-maps.tmdm:association-role-type r)) (%si1 (topic-maps.tmdm:association-role-player r))))
                        (topic-maps.tmdm:association-roles a))
                (and (topic-maps.tmdm:item-reifier a) (%si1 (topic-maps.tmdm:item-reifier a)))))
(defun %multiset-minus (a b)
  "The elements of the list A that the list B does not account for, counting repetitions."
  (let ((counts (make-hash-table :test #'equal)) (out nil))
    (dolist (x b) (incf (gethash x counts 0)))
    (dolist (x a (nreverse out)) (if (plusp (gethash x counts 0)) (decf (gethash x counts)) (push x out)))))
(defun %stated-associations (map)
  "The signatures of the Associations of MAP whose types a page can state: all but the derived ones."
  (loop for a in (topic-maps.tmdm:topic-map-associations map)
        unless (member (%si1 (topic-maps.tmdm:association-type a)) +derived-association-types+ :test #'string=)
          collect (%association-signature a)))
(defun %named-topics (map)
  "The subject identifiers of MAP in the namespaces a page names: Work Topics, statements, assignments, controls, pages and files."
  (loop for topic in (topic-maps.tmdm:topic-map-topics map) for si = (%si1 topic)
        when (some (lambda (ns) (eql 0 (search (%o ns "") si))) '("work/topic" "statement" "assignment" "control" "page" "file"))
          collect si))

(defun oracle-differences (map items)
  "How MAP departs from what the source ITEMS state: (:missing signatures :unexpected signatures :missing-topics :unexpected-topics)."
  (multiple-value-bind (expected topics) (source-oracle items)
    (let ((actual (%stated-associations map)) (named (%named-topics map)))
      (list :missing (%multiset-minus expected actual) :unexpected (%multiset-minus actual expected)
            :missing-topics (set-difference topics named :test #'string=)
            :unexpected-topics (set-difference named topics :test #'string=)))))

(defun %topic-content (topic)
  "The names, Occurrences and types of TOPIC that its identity does not include, as sorted strings."
  (sort (append (mapcar (lambda (n) (format nil "name ~A" (topic-maps.tmdm:topic-name-value n))) (topic-maps.tmdm:topic-names topic))
                (mapcar (lambda (o) (format nil "occurrence ~A ~S~@[ ^^~A~]~@[ ~~ ~A~]" (%si1 (topic-maps.tmdm:occurrence-type o)) (topic-maps.tmdm:occurrence-value o)
                                            (topic-maps.tmdm:occurrence-datatype o) (and (topic-maps.tmdm:item-reifier o) (%si1 (topic-maps.tmdm:item-reifier o)))))
                        (topic-maps.tmdm:topic-occurrences topic)))
        #'string<))
(defun preservation-differences (old new items)
  "What NEW changes of the committed revision OLD that no source change accounts for:
:lost-topics, Topics of OLD that NEW lacks; :lost-associations, Associations of OLD that NEW lacks and the sources still state or that are
derived; :unattributed-additions, derived Associations of NEW that involve no new Topic; :changed-topics, Topics whose names or Occurrences
changed other than the digest of a source page whose text changed."
  (let* ((old-topics (mapcar #'%si1 (topic-maps.tmdm:topic-map-topics old)))
         (new-index (let ((h (make-hash-table :test #'equal))) (dolist (tp (topic-maps.tmdm:topic-map-topics new) h) (setf (gethash (%si1 tp) h) tp))))
         (old-index (let ((h (make-hash-table :test #'equal))) (dolist (tp (topic-maps.tmdm:topic-map-topics old) h) (setf (gethash (%si1 tp) h) tp))))
         (stated (source-oracle items))
         (old-all (mapcar #'%association-signature (topic-maps.tmdm:topic-map-associations old)))
         (new-all (mapcar #'%association-signature (topic-maps.tmdm:topic-map-associations new)))
         (source-pages (mapcar (lambda (i) (%o-page (p::source-hyperbook-id i) (p::source-title i))) items)))
    (flet ((derived-p (signature) (some (lambda (type) (eql 0 (search (format nil "~A(" type) signature))) +derived-association-types+)))
      (list :lost-topics (remove-if (lambda (si) (gethash si new-index)) old-topics)
            :lost-associations (remove-if (lambda (sig) (and (not (derived-p sig)) (not (member sig stated :test #'string=))))
                                          (%multiset-minus old-all new-all))
            :unattributed-additions (remove-if-not (lambda (sig) (and (derived-p sig) (notany (lambda (si) (and (search si sig) (not (gethash si old-index))))
                                                                                                (loop for si being the hash-keys of new-index collect si))))
                                                   (%multiset-minus new-all old-all))
            :changed-topics (loop for si in old-topics
                                  for o = (gethash si old-index) for n = (gethash si new-index)
                                  when (and n (not (equal (%topic-content o) (%topic-content n))))
                                    unless (and (member si source-pages :test #'string=)
                                                (every (lambda (line) (eql 0 (search (format nil "occurrence ~A" (%o-schema "source-sha256")) line)))
                                                       (append (set-difference (%topic-content o) (%topic-content n) :test #'string=)
                                                               (set-difference (%topic-content n) (%topic-content o) :test #'string=))))
                                      collect si)))))

(defparameter +exchange-review+ "cc-2026-10-20-ctm-exchange-review" "The assignment of the exchange review, whose invariants are checked.")
(defun exchange-review-problems (map items committed)
  "Where MAP breaks the exchange review's invariants, as sentences: it belongs to the Work Item its page names, records the references its
page names, delivers nothing, and changes no status or acceptance of pwc-wp-4 and pwc-wp-7 against the COMMITTED revision."
  (let* ((assignments (find :assignments items :key #'p::source-kind))
         (section (find +exchange-review+ (plump:get-elements-by-tag-name (%dom (p::source-text assignments)) "section")
                        :key (lambda (n) (plump:attribute n "data-assignment")) :test #'equal))
         (a (%o "assignment" +exchange-review+)) (signatures (mapcar #'%association-signature (topic-maps.tmdm:topic-map-associations map)))
         (problems nil))
    (flet ((problem (control &rest args) (push (apply #'format nil control args) problems))
           (with-assignment (type) (remove-if-not (lambda (sig) (and (eql 0 (search (format nil "~A(" (%o-schema type)) sig)) (search (format nil ": ~A" a) sig))) signatures)))
      (unless section (problem "the page has no section ~A" +exchange-review+))
      (when section
        (let ((work-item (plump:attribute (%field section "work-item") "data-ref")))
          (unless (equal work-item "project-work-ctm") (problem "the page names the Work Item ~S, not project-work-ctm" work-item))
          (unless (equal (with-assignment "assignment-for")
                         (list (%o-signature (%o-schema "assignment-for") `((,(%o-schema "assignment") . ,a) (,(%o-schema "work-item") . ,(%o-work "project-work-ctm"))))))
            (problem "assignment for is not exactly project-work-ctm")))
        (when (%field section "delivers") (problem "the page states a delivers field"))
        (dolist (path '("docs/exchange/2026-10-20-juergen-ctm-import-feedback.md" "docs/project-ctm-exchange-review.md"))
          (unless (member (%o-signature (%o-schema "changes-source") `((,(%o-schema "assignment") . ,a) (,(%o-schema "file") . ,(%o "file" path)))) signatures :test #'string=)
            (problem "no changes source to ~A" path))))
      (when (with-assignment "assignment-delivers") (problem "the assignment delivers ~A" (with-assignment "assignment-delivers")))
      (dolist (type '("acceptance-decision" "withdrawal" "acceptance-record" "withdrawal-record"))
        (when (or (find-if (lambda (sig) (search (%o-schema type) sig)) signatures)
                  (find (%o-schema type) (topic-maps.tmdm:topic-map-topics map) :key #'%si1 :test #'string=))
          (problem "the project CTM has ~A" type)))
      (dolist (wp '("pwc-wp-4" "pwc-wp-7"))
        (let ((now (find (%o-work wp) (topic-maps.tmdm:topic-map-topics map) :key #'%si1 :test #'string=))
              (then (find (%o-work wp) (topic-maps.tmdm:topic-map-topics committed) :key #'%si1 :test #'string=))
              (mine (lambda (m) (sort (remove-if-not (lambda (sig) (search (%o-work wp) sig)) (mapcar #'%association-signature (topic-maps.tmdm:topic-map-associations m))) #'string<))))
          (cond ((not (and now then)) (problem "~A is missing" wp))
                (t (unless (equal (%topic-content now) (%topic-content then)) (problem "~A's names or Occurrences changed" wp))
                   (when (find-if (lambda (line) (search (%o-schema "work-status") line)) (%topic-content now)) (problem "~A has a work status" wp))
                   (unless (equal (funcall mine map) (funcall mine committed)) (problem "~A's Associations changed" wp)))))))
    (nreverse problems)))

(defun %committed-ctm ()
  (uiop:run-program (list "git" "-C" (namestring (asdf:system-source-directory "dreyeck")) "show" "HEAD:dreyeck/work/project/hyperdoc-project.ctm")
                    :output :string))
(defun %read-ctm (text label)
  (let ((revision (p:ctm-revision-from-octets (sb-ext:string-to-octets text :external-format :utf-8) :label label)))
    (assert (p:revision-map revision) () "~A was refused: ~S" label (p:revision-refusal revision))
    (p:revision-map revision)))

(defun oracle-tests (map text)
  "The read-back MAP of the CTM TEXT against the source pages, the committed revision and the exchange review's invariants; then the same
comparisons on five mutations of TEXT, each of which they must detect."
  (let* ((items (p:sources-items (p:read-project-sources))) (committed (%read-ctm (%committed-ctm) "committed HEAD")))
    (let ((d (oracle-differences map items)))
      (check "oracle:every-stated-association-in-the-topic-map-once-per-statement" (null (getf d :missing)))
      (check "oracle:no-association-the-sources-do-not-state" (null (getf d :unexpected)))
      (check "oracle:every-named-topic-present" (null (getf d :missing-topics)))
      (check "oracle:no-named-topic-the-sources-do-not-name" (null (getf d :unexpected-topics))))
    (let ((d (preservation-differences committed map items)))
      (check "preserved:no-topic-of-the-committed-revision-lost" (null (getf d :lost-topics)))
      (check "preserved:no-association-or-reification-lost-that-the-sources-still-state" (null (getf d :lost-associations)))
      (check "preserved:every-derived-addition-involves-a-new-topic" (null (getf d :unattributed-additions)))
      (check "preserved:existing-topics-unchanged-but-for-source-digests" (null (getf d :changed-topics))))
    (check "exchange-review:invariants" (null (exchange-review-problems map items committed)))
    ;; Positive controls: each mutation of the CTM text, read back, must be reported.
    (flet ((mutant (label old new &optional append)
             (%read-ctm (if append (concatenate 'string text append) (%replace text old new)) label))
           (line (prefix) (let ((at (search (format nil "~%~A" prefix) text))) (subseq text (1+ at) (position #\Newline text :start (1+ at))))))
      (let* ((statement (line "<tag:dreyeck.ch,2026:hyperdoc/work/topic/work:relation/decomposes-into>("))
             (omitted (mutant "an authored Association omitted" (format nil "~A~%" statement) ""))
             (added (mutant "an Association added" nil nil (format nil "s:assignment-for(s:assignment: <~A>, s:work-item: w:ctm-plan-page-authoring)~%" (%o "assignment" "cc-2026-10-19-topic-maps-reader-scaling"))))
             (player (mutant "a Role player changed" statement (%replace statement "w:ctm-wp-1" "w:ctm-plan-p1")))
             (renamed (%read-ctm (%replace-all text "w:ctm-pre-content" "w:ctm-pre-content-renamed") "a subject identifier changed"))
             (delivers (mutant "an unauthorized delivers" nil nil (format nil "s:assignment-delivers(s:assignment: <~A>, s:work-package: w:pwc-wp-4)~%" (%o "assignment" +exchange-review+)))))
        (check "control:omitted-association-reported-missing" (getf (oracle-differences omitted items) :missing))
        (check "control:omitted-association-reported-lost" (getf (preservation-differences committed omitted items) :lost-associations))
        (check "control:added-association-reported-unexpected" (getf (oracle-differences added items) :unexpected))
        (check "control:changed-player-reported-missing-and-unexpected"
               (let ((d (oracle-differences player items))) (and (getf d :missing) (getf d :unexpected))))
        (check "control:changed-subject-identifier-reported" (and (getf (preservation-differences committed renamed items) :lost-topics)
                                                                  (getf (oracle-differences renamed items) :unexpected-topics)))
        (check "control:unauthorized-delivers-reported" (and (getf (oracle-differences delivers items) :unexpected)
                                                             (exchange-review-problems delivers items committed)))))))

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
    (check "pin:identity-names-its-kind" (member (getf identity :kind) '(:git-checkout :verified-nix-store-snapshot)))
    (check "pin:every-topic-maps-system-comes-from-the-one-root" (getf identity :one-root))
    (check "pin:the-commit-is-the-pinned-one" (equal (getf identity :commit) p::+topic-maps-revision+))
    ;; The pin can fail: a changed tree, another commit, an unidentified commit and two roots are each not the pin.
    (check "pin:negative:pinned-and-clean-and-one-root-is-pinned" (p::pinned-state-p p::+topic-maps-revision+ "" t))
    (check "pin:negative:a-changed-working-tree-is-not-pinned" (not (p::pinned-state-p p::+topic-maps-revision+ " M src/tmdm/merging.lisp" t)))
    (check "pin:negative:another-commit-is-not-pinned" (not (p::pinned-state-p "5a4a66850403cdfe2755c6c88083a8e31af89628" "" t)))
    (check "pin:negative:b2eecffa-is-not-pinned" (not (p::pinned-state-p "b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc" "" t)))
    (check "pin:negative:an-empty-commit-is-not-pinned" (not (p::pinned-state-p "" "" t)))
    (check "pin:negative:two-roots-are-not-pinned" (not (p::pinned-state-p p::+topic-maps-revision+ "" nil)))
    ;; A directory Git cannot identify and that is no /nix/store snapshot is never reported clean or pinned, and has no commit.
    (uiop:with-temporary-file (:pathname marker :type "txt" :keep nil)
      (let ((identity (p::topic-maps-source-identity (uiop:pathname-directory-pathname marker))))
        (check "pin:negative:unverifiable-directory-has-no-commit-and-is-not-clean-or-pinned"
               (and (eq :unverifiable (getf identity :kind)) (null (getf identity :commit))
                    (null (getf identity :clean)) (null (getf identity :pinned))))))
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
    (oracle-tests map text)
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
      ;; Topic Maps 5a4a668 refused `def t() end` as unsupported (:unsupported-keyword); b2eecffa and its descendants support
      ;; templates, so this runtime reads it as a map without Topics. Malformed input is still refused, with a code.
      (check "accept:template-definition-reads-as-an-empty-map" (and (p:revision-map template) (null (p:revision-refusal template))
                                                                      (null (topic-maps.tmdm:topic-map-topics (p:revision-map template)))))
      (check "refuse:not-utf-8" (eq :not-utf-8 (first (p:revision-refusal latin))))
      (let ((malformed (p:ctm-revision-from-octets (sb-ext:string-to-octets "a(r: b" :external-format :utf-8) :label "malformed")))
        (check "refuse:malformed-input-with-its-code" (eq :missing-association-close (first (p:revision-refusal malformed))))
        (check "refuse:no-topic-map-from-a-refusal" (and (null (p:revision-map malformed)) (null (p:revision-map latin))))))
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

;;; Work package, evidence and acceptance: requirements, observations and decisions stay apart

(defparameter +baseline-commit+ "d089efe8"
  "The commit whose project CTM the current one must preserve: every subject identifier and every Association line of it.")
(defun %fixture (name)
  (uiop:read-file-string (asdf:system-relative-pathname "dreyeck" (concatenate 'string "dreyeck/tests/fixtures/project-acceptance/" name)) :external-format :utf-8))
(defun %project-page (title)
  (uiop:read-file-string (asdf:system-relative-pathname "dreyeck" (format nil "dreyeck/pages/project/~A.html" title)) :external-format :utf-8))
(defun %extra (role title kind path text) (list :role role :book "fixture" :title title :kind kind :path path :text text))
(defun %fixture-texts (&optional (addition (%fixture "synthetic-assignments-addition.html")))
  (list (cons :assignments (concatenate 'string (%project-page "Implementation Assignments") addition))))
(defun %fixture-source (role title kind name text)
  (%extra role title kind (concatenate 'string "dreyeck/tests/fixtures/project-acceptance/" name) text))
(defun %scenario-extra (&key (dictionary "synthetic-dictionary-c2.html") dictionary-text (second (%fixture "synthetic-second-dictionary.html"))
                          (proposed t) (records "synthetic-records-s3.html") records-text)
  "The synthetic sources of one scenario: the Work fixture, two declared dictionaries, a draft one, and a records page (none if
RECORDS and RECORDS-TEXT are NIL). The records page always has the same title, so its records keep their identities."
  (remove nil (list (%fixture-source :fixture-work "Synthetic work" :work "synthetic-work.html" (%fixture "synthetic-work.html"))
                    (%fixture-source :fixture-dictionary "Synthetic dictionary" :dictionary dictionary (or dictionary-text (%fixture dictionary)))
                    (%fixture-source :fixture-second-dictionary "Synthetic second dictionary" :dictionary "synthetic-second-dictionary.html" second)
                    (and proposed (%fixture-source :fixture-proposed "Synthetic proposed dictionary" :proposed-dictionary "synthetic-proposed-dictionary.html"
                                                   (%fixture "synthetic-proposed-dictionary.html")))
                    (and (or records records-text)
                         (%fixture-source :fixture-records "Synthetic records" :acceptance-records (or records "synthetic-records.html")
                                          (or records-text (%fixture records)))))))
(defun %scenario (label &rest keys &key texts &allow-other-keys)
  (let ((keys (loop for (k v) on keys by #'cddr unless (eq k :texts) append (list k v))))
    (p:scenario-reading :texts (or texts (%fixture-texts)) :extra (apply #'%scenario-extra keys) :label label)))
(defun %refusal (&rest keys &key texts &allow-other-keys)
  "The reason the scenario of KEYS is refused, or NIL if it is not. A dictionary reader refusal counts as one."
  (let ((keys (loop for (k v) on keys by #'cddr unless (eq k :texts) append (list k v))))
    (handler-case (progn (p:build-project-model (p:read-project-sources :texts (or texts (%fixture-texts)) :extra (apply #'%scenario-extra keys))) nil)
      (error (c) (or (princ-to-string c) "refused")))))
(defun %draft-extra ()
  (list (list :role :exchange-dictionary :book "dreyeck/work/project" :title "Project Work Exchange WBS Dictionary" :kind :proposed-dictionary
              :path "dreyeck/pages/project/Project Work Exchange WBS Dictionary.html" :text (%project-page "Project Work Exchange WBS Dictionary"))
        (list :role :acceptance :book "dreyeck/work/project" :title "Acceptance Records" :kind :acceptance-records
              :path "dreyeck/pages/project/Acceptance Records.html" :text (%project-page "Acceptance Records"))))
(defun %schema-block (text name)
  "The Topic block of the schema Topic s:NAME in a CTM TEXT written by the emitter."
  (let ((start (search (format nil "~%s:~A~%" name) text)))
    (and start (subseq text (1+ start) (+ 2 (search (format nil " .~%") text :start2 start))))))
(defun %type-names (map topic) (mapcar #'p::%name (p::%types map topic)))
(defun %occ (topic name) (loop for o in (topic-maps.tmdm:topic-occurrences topic)
                               when (equal name (p::%name (topic-maps.tmdm:occurrence-type o))) collect o))
(defun %assocs (map type-name) (remove-if-not (lambda (a) (equal type-name (p::%name (topic-maps.tmdm:association-type a)))) (topic-maps.tmdm:topic-map-associations map)))
(defun %role-player (a role-name)
  (let ((r (find role-name (topic-maps.tmdm:association-roles a) :key (lambda (r) (p::%name (topic-maps.tmdm:association-role-type r))) :test #'equal)))
    (and r (topic-maps.tmdm:canonical-topic (topic-maps.tmdm:association-role-player r)))))
(defun %plays (map type-name role-name topic)
  (remove-if-not (lambda (a) (eq (%role-player a role-name) (topic-maps.tmdm:canonical-topic topic))) (%assocs map type-name)))

(defparameter +c1+ "SYNTHETIC acceptance criterion: the synthetic result is read within 30 s.")
(defparameter +c2+ "SYNTHETIC acceptance criterion: the synthetic result is read within 10 s.")
(defun %sha-text (text) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets text :external-format :utf-8))))
(defun %criterion (text) (p:criterion-iri "synthetic-wp-1" (format nil "sha256-~A" (%sha-text text))))

(defun %record-statements (text)
  "The Topic block of every record in the CTM TEXT and every Association line that names a record: what append-only keeps."
  (let ((prefix (format nil "<~A" (p::%namespace "acceptance"))) (out nil) (block nil))
    (dolist (line (uiop:split-string text :separator '(#\Newline)) (nreverse out))
      (cond (block (push line block)
                   (when (and (> (length line) 1) (string= " ." line :start2 (- (length line) 2)))
                     (push (format nil "~{~A~^~%~}" (reverse block)) out) (setf block nil)))
            ((and (eql 0 (search prefix line)) (not (find #\( line))) (setf block (list line)))
            ((and (plusp (length line)) (not (find (char line 0) "#% ")) (find #\( line) (search prefix line)) (push line out))))))
(defun %records-lost (old new)
  "What append-only forbids: a record statement of OLD that NEW does not have, unchanged."
  (set-difference (%record-statements old) (%record-statements new) :test #'string=))

(defun %count (needle text) (loop for start = (search needle text) then (search needle text :start2 (1+ start)) while start count t))
(defun %explain (reading id)
  (let ((map (p:revision-map (p:reading-document reading))))
    (p:explain-acceptance map (gethash (p:topic-iri id) (p::%index map)))))
(defun %explained (reading id)
  "The state of ID, its reason and the record keys in force or open, from the read-back Topic Map alone."
  (let ((x (%explain reading id)))
    (list (p::explanation-state x) (p::explanation-reason x)
          (mapcar (lambda (r) (p:topic-key (p::%si r))) (p::explanation-open x)))))
(defun %gap-rules (reading id)
  (loop for g in (p:model-gaps (p:reading-model reading))
        when (and (member (p:topic-iri id) (p:gap-subjects g) :test #'equal)
                  (member (p:gap-rule g) '("acceptance-not-recordable" "acceptance-not-recorded" "acceptance-records-in-conflict" "acceptance-withdrawn"
                                           "decision-under-retained-criterion" "acceptance-requires-declaration")
                          :test #'equal))
          collect (p:gap-rule g)))
(defun %agrees-p (reading)
  "The emitter's acceptance gaps and the explanation read from the Topic Map say the same about every declared dictionary entry."
  (every (lambda (entry)
           (let* ((id (plan::entry-element-id entry)) (x (%explain reading id))
                  (record (p::explanation-record x))
                  (current (and record (getf (p::record-explanation (p:revision-map (p:reading-document reading)) record) :criterion-current))))
             (equal (%gap-rules reading id)
                    (ecase (p::explanation-reason x)
                      (:no-record '("acceptance-not-recorded"))
                      (:conflict '("acceptance-records-in-conflict"))
                      (:withdrawn '("acceptance-withdrawn"))
                      (:in-force (if current nil (list "decision-under-retained-criterion")))))))
         (p::model-entries (p:reading-model reading))))
(defun %read-p (reading)
  "Read back through the topic-maps reader, canonicalized as CXTM, exported as the octets read, and traced against its sources."
  (let ((document (p:reading-document reading)))
    (and (p:revision-map document) (null (p:revision-refusal document)) (p:revision-cxtm document)
         (equalp (p:revision-export-octets document) (p:revision-octets document))
         (null (p:trace-project-map (p:revision-map document) (p:reading-model reading))))))
;; The Point panel as rendered: a section of the Workspace's Topicmap view, and its buttons pressed as a click evaluates them.
(defun %panel-section (ws marker)
  "The part of the rendered Point panel of WS from MARKER to the represented object, or NIL if the panel has no MARKER."
  (let* ((html (v:view-html (find "Topicmap" (v:all-views ws) :key #'v:view-title :test #'equal))) (at (search marker html)))
    (and at (subseq html at (search "Represented object" html :start2 at)))))
(defun %press (ws label)
  "Press the button LABEL of the rendered Point panel of WS: evaluate the thunk the view rendered under that button's id."
  (let* ((view (find "Topicmap" (v:all-views ws) :key #'v:view-title :test #'equal)) (html (v:view-html view))
         (at (search (format nil ">~A</button>" label) html))
         (start (and at (search "id='" html :from-end t :end2 at)))
         (id (and start (subseq html (+ start 4) (position #\' html :start (+ start 4)))))
         (reference (assoc id (v:view-references view) :test #'equal)))
    (assert reference () "no button ~S in the Point panel" label)
    (v:eval-thunk (cdr reference))))
(defun %neighbours (ws key)
  (dreyeck/topicmap:topicmap-workspace-go-to ws key)
  (mapcar (lambda (a) (dreyeck/topicmap::topicmap-association-other-topic-id ws a)) (dreyeck/topicmap::topicmap-associations-of-point ws)))

(defun acceptance-tests ()
  ;; 1. The project CTM as its sources state it now: no acceptance, every earlier identifier and Work relation kept.
  (let* ((reading (p:project-workspace)) (map (p:revision-map (p:reading-document reading))) (index (p::%index map))
         (text (p:model-text (p:reading-model reading)))
         (git (lambda (commit) (uiop:run-program (list "git" "-C" (namestring (asdf:system-source-directory "dreyeck")) "show"
                                                      (format nil "~A:dreyeck/work/project/hyperdoc-project.ctm" commit))
                                                :output :string)))
         (baseline (funcall git +baseline-commit+)) (head (funcall git "HEAD")))
    (check "productive:no-acceptance-record-or-vocabulary"
           (and (null (p:model-acceptance (p:reading-model reading))) (not (search "acceptance-decision" text)) (not (search "Acceptance record" text))
                (not (search "retained-wbs-acceptance-criterion" text)) (not (search "supersedes" text))))
    (check "productive:no-evidence-entry-or-criterion-revision"
           (and (null (p:model-evidence-entries (p:reading-model reading)))
                (not (search (p::%namespace "evidence") text)) (not (search (p::%namespace "criterion") text))
                (notany #'topic-maps.tmdm:item-reifier (loop for tp in (topic-maps.tmdm:topic-map-topics map) append (topic-maps.tmdm:topic-occurrences tp)))))
    (check "productive:existing-evidence-entries-are-not-retrofitted"
           (null (%with "li" "data-evidence" (%project-page "Implementation Assignments"))))
    (check "productive:pwc-wp-8-is-a-proposal-without-status-or-acceptance"
           (let ((wp (gethash (p:topic-iri "pwc-wp-8") index)))
             (and wp (null (%occ wp "work status")) (%plays map "proposed on" "proposal" wp) (null (%plays map "declared on" "declaration" wp)))))
    (check "productive:the-reader-assignment-records-no-acceptance"
           (equal (mapcar #'topic-maps.tmdm:occurrence-value (%occ (gethash (p::%iri "assignment" "cc-2026-10-19-topic-maps-reader-scaling") index) "acceptance"))
                  '("No acceptance by the user is recorded.")))
    (check "productive:no-draft-dictionary-requirements"
           (let ((wp (gethash (p:topic-iri "pwc-wp-8") index)))
             (and (null (%occ wp "WBS acceptance criterion")) (null (%occ wp "WBS evidence")) (null (%occ wp "WBS scope"))
                  (not (search "proposed-in-dictionary" text)) (not (search (p:schema-iri "wbs-criterion") text)) (not (search "s:wbs-criterion" text)))))
    ;; Each declared Work Topic's status is the data-status its Work page authors, read here from the HTML; it is a status, not acceptance.
    (check "productive:work-status-stays-a-status"
           (every (lambda (item)
                    (or (not (eq :work (p::source-kind item)))
                        (every (lambda (a)
                                 (let ((topic (gethash (%o-work (plump:attribute a "data-topic")) index)))
                                   (and topic (equal (mapcar #'topic-maps.tmdm:occurrence-value (%occ topic "work status"))
                                                     (and (plump:attribute a "data-status") (list (plump:attribute a "data-status")))))))
                               (%with "a" "data-topic" (p::source-text item)))))
                  (p:sources-items (p:read-project-sources))))
    (check "productive:occurrence-type-acceptance-criterion-as-at-the-baseline"
           (let ((blk (%schema-block text "acceptance-criterion"))) (and blk (equal blk (%schema-block baseline "acceptance-criterion")))))
    (check "productive:overview-says-no-acceptance-is-recorded"
           (search "No acceptance is recorded" (v:view-html (find "Project" (v:all-views reading) :key #'v:view-title :test #'equal))))
    (check "append-only:the-committed-ctm-has-no-record-so-nothing-to-keep"
           (and (null (%record-statements head)) (null (%records-lost head text))))
    (multiple-value-bind (old-subjects old-associations) (%written baseline)
      (multiple-value-bind (new-subjects new-associations) (%written text)
        (declare (ignore new-associations))
        (check "preserved:every-subject-identifier-of-the-baseline" (subsetp old-subjects new-subjects :test #'string=))
        (check "preserved:baseline-associations-were-counted" (plusp (length old-associations)))))
    (let ((new-lines (uiop:split-string text :separator '(#\Newline))))
      (check "preserved:every-association-line-of-the-baseline"
             ;; Association lines start in the first column; Topic blocks are indented.
             (every (lambda (line) (or (zerop (length line)) (find (char line 0) "#% ") (not (find #\( line))
                                       (member line new-lines :test #'string=)))
                    (uiop:split-string baseline :separator '(#\Newline))))))
  ;; 2. The drafts read as they would state it: requirements on the proposed package, no decision, no acceptance possible.
  (let* ((reading (p:scenario-reading :extra (%draft-extra) :label "drafts")) (map (p:revision-map (p:reading-document reading)))
         (index (p::%index map)) (wp (gethash (p:topic-iri "pwc-wp-8") index))
         (assignment (gethash (p::%iri "assignment" "cc-2026-10-19-topic-maps-reader-scaling") index)))
    (check "drafts:read" (%read-p reading))
    (check "drafts:pwc-wp-8-has-criterion-and-required-evidence"
           (and (= 1 (length (%occ wp "WBS acceptance criterion"))) (= 1 (length (%occ wp "WBS evidence")))))
    (check "drafts:the-criterion-is-the-users-own-condition"
           (equal (topic-maps.tmdm:occurrence-value (first (%occ wp "WBS acceptance criterion")))
                  "The full HyperDoc project CTM is read correctly, in practical time, without weakening TMDM semantics."))
    (check "drafts:required-evidence-is-not-observed-evidence"
           (and (null (%occ wp "evidence")) (null (%occ assignment "WBS evidence")) (%occ assignment "evidence")))
    (check "drafts:proposed-in-a-draft-dictionary-not-defined" (and (%plays map "proposed in dictionary" "work package" wp) (null (%plays map "defined in dictionary" "work package" wp))))
    (check "drafts:pwc-wp-8-stays-a-proposal" (and (%plays map "proposed on" "proposal" wp) (null (%occ wp "work status"))))
    (check "drafts:no-record-and-a-proposed-requirement-cannot-be-accepted"
           (and (null (p:acceptance-records (p:model-acceptance (p:reading-model reading))))
                (null (%assocs map "acceptance decision"))
                (gethash (p::%iri "gap" "acceptance-requires-declaration" "pwc-wp-8") index)
                (null (gethash (p::%iri "gap" "acceptance-not-recorded" "pwc-wp-8") index))
                (gethash (p::%iri "gap" "acceptance-not-recorded" "ctm-wp-1") index))))
  ;; 3. S1, S2, S3: an original decision, a changed criterion, a superseding decision. Each read back through CTM, TMDM and CXTM.
  (let* ((s1 (%scenario "S1" :dictionary "synthetic-dictionary-c1.html" :records "synthetic-records-s1.html"))
         (s2 (%scenario "S2" :dictionary "synthetic-dictionary-c2.html" :records "synthetic-records-s1.html"))
         (s3 (%scenario "S3" :dictionary "synthetic-dictionary-c2.html" :records "synthetic-records-s3.html"))
         (map1 (p:revision-map (p:reading-document s1))) (map2 (p:revision-map (p:reading-document s2))) (map3 (p:revision-map (p:reading-document s3))))
    (dolist (r (list s1 s2 s3))
      (check (format nil "scenario:~A:read-back-cxtm-export-traced" (p::revision-label (p:reading-document r))) (%read-p r))
      (check (format nil "scenario:~A:gaps-and-explanation-agree" (p::revision-label (p:reading-document r))) (%agrees-p r)))
    (flet ((topic (map iri) (gethash iri (p::%index map)))
           (applied (map record-id) (p::record-explanation map (gethash (p::%iri "acceptance" record-id) (p::%index map)))))
      ;; S1: the record names its revision; the revision Topic reifies the current criterion; its identifier is the digest of that text.
      (let* ((x (applied map1 "synthetic-record-1")) (criterion (getf x :criterion)))
        (check "S1:applied-revision-is-the-digest-of-the-read-back-text"
               (and criterion (equal (p::%si criterion) (%criterion +c1+)) (equal (getf x :criterion-text) +c1+)
                    (equal (p::%si criterion) (p:criterion-iri "synthetic-wp-1" (format nil "sha256-~A" (%sha-text (getf x :criterion-text)))))))
        (check "S1:the-revision-reifies-the-current-criterion" (getf x :criterion-current))
        (check "S1:accepted-by-record-1" (equal (%explained s1 "synthetic-wp-1") '("accepted" :in-force ("acceptance/synthetic-record-1")))))
      ;; S2: the criterion changed; record 1 still applies C1, now a retained occurrence; the package has one current criterion.
      (let* ((x (applied map2 "synthetic-record-1")) (wp (topic map2 (p:topic-iri "synthetic-wp-1"))))
        (check "S2:same-revision-identity" (equal (p::%si (getf x :criterion)) (%criterion +c1+)))
        (check "S2:same-applied-text-now-retained" (and (equal (getf x :criterion-text) +c1+) (not (getf x :criterion-current))))
        (check "S2:one-current-criterion-the-new-one"
               (and (equal (mapcar #'topic-maps.tmdm:occurrence-value (%occ wp "WBS acceptance criterion")) (list +c2+))
                    (equal (mapcar #'topic-maps.tmdm:occurrence-value (%occ wp "retained WBS acceptance criterion")) (list +c1+))))
        (check "S2:the-current-criterion-is-not-reified-when-no-record-applies-it"
               (null (topic-maps.tmdm:item-reifier (first (%occ wp "WBS acceptance criterion")))))
        (check "S2:decision-stays-in-force-under-the-retained-criterion"
               (and (equal (%explained s2 "synthetic-wp-1") '("accepted" :in-force ("acceptance/synthetic-record-1")))
                    (equal (%gap-rules s2 "synthetic-wp-1") '("decision-under-retained-criterion")))))
      ;; S3: record 2 rejects against C2 and supersedes record 1, which stays readable with what it applied and considered.
      (let ((x1 (applied map3 "synthetic-record-1")) (x2 (applied map3 "synthetic-record-2")))
        (check "S3:rejected-by-record-2-against-the-current-criterion"
               (and (equal (%explained s3 "synthetic-wp-1") '("rejected" :in-force ("acceptance/synthetic-record-2")))
                    (equal (p::%si (getf x2 :criterion)) (%criterion +c2+)) (getf x2 :criterion-current) (null (%gap-rules s3 "synthetic-wp-1"))))
        (check "S3:historical-decision-reconstructed"
               (and (equal (getf x1 :decision) "accepted") (equal (getf x1 :decided-at) "2000-01-01T12:00:00Z")
                    (equal (p::%si (getf x1 :criterion)) (%criterion +c1+)) (equal (getf x1 :criterion-text) +c1+) (not (getf x1 :criterion-current))
                    (equal (mapcar (lambda (e) (p:topic-key (p::%si e))) (getf x1 :evidence)) '("evidence/synthetic-assignment-1/synthetic-run-1"))
                    (equal (mapcar (lambda (r) (p:topic-key (p::%si r))) (getf x1 :superseded-by)) '("acceptance/synthetic-record-2"))))
        (check "S3:supersedes-record-1" (equal (mapcar (lambda (r) (p:topic-key (p::%si r))) (getf x2 :supersedes)) '("acceptance/synthetic-record-1")))
        (check "S3:two-revisions-two-topics-each-reifies-one-occurrence"
               (let ((r1 (topic map3 (%criterion +c1+))) (r2 (topic map3 (%criterion +c2+))))
                 (and r1 r2 (not (eq r1 r2))
                      (equal (p::%name (topic-maps.tmdm:occurrence-type (topic-maps.tmdm:topic-reified r1))) "retained WBS acceptance criterion")
                      (equal (p::%name (topic-maps.tmdm:occurrence-type (topic-maps.tmdm:topic-reified r2))) "WBS acceptance criterion")
                      (equal (%type-names map3 r1) '("WBS criterion")))))
        (check "S3:the-delivering-assignment-is-not-the-decision"
               (let ((a (topic map3 (p::%iri "assignment" "synthetic-assignment-1"))))
                 (and (null (%plays map3 "acceptance decision" "acceptance record" a)) (%plays map3 "assignment delivers" "assignment" a)))))
      ;; Identity preservation: the record statements of S1 are in S2 and S3 unchanged; a removed or edited record is detected.
      (let ((t1 (p:model-text (p:reading-model s1))) (t2 (p:model-text (p:reading-model s2))) (t3 (p:model-text (p:reading-model s3))))
        (check "append-only:record-statements-counted" (<= 8 (length (%record-statements t1))))
        (check "append-only:S1-kept-in-S2" (null (%records-lost t1 t2)))
        (check "append-only:S1-kept-in-S3" (null (%records-lost t1 t3)))
        (check "append-only:positive-control-removed-record"
               (let* ((page (%fixture "synthetic-records-s1.html")) (at (search "<section data-acceptance-record=\"synthetic-record-1\"" page))
                      (without (concatenate 'string (subseq page 0 at) (subseq page (+ (search "</section>" page :start2 at) 11)))))
                 (%records-lost t1 (p:model-text (p:build-project-model (p:read-project-sources :texts (%fixture-texts)
                                                                                                 :extra (%scenario-extra :dictionary "synthetic-dictionary-c1.html" :records-text without)))))))
        (check "append-only:positive-control-edited-record"
               (%records-lost t1 (p:model-text (p:build-project-model
                                                (p:read-project-sources :texts (%fixture-texts)
                                                                        :extra (%scenario-extra :dictionary "synthetic-dictionary-c1.html"
                                                                                                :records-text (%replace (%fixture "synthetic-records-s1.html") "data-decision=\"accepted\"" "data-decision=\"rejected\""))))))))
      ;; Evidence entries: reports and notes, identified by reification of the assignment's own evidence occurrences.
      (let* ((a (topic map3 (p::%iri "assignment" "synthetic-assignment-1")))
             (run-1 (topic map3 (p::%iri "evidence" "synthetic-assignment-1" "synthetic-run-1")))
             (run-2 (topic map3 (p::%iri "evidence" "synthetic-assignment-1" "synthetic-run-2")))
             (run-3 (topic map3 (p::%iri "evidence" "synthetic-assignment-1" "synthetic-run-3")))
             (note (topic map3 (p::%iri "evidence" "synthetic-assignment-1" "synthetic-note-1")))
             (file (topic map3 (p::%iri "file" "dreyeck/tests/project-ctm.lisp"))))
        (check "evidence:types" (and (equal (%type-names map3 run-1) '("Test execution report")) (equal (%type-names map3 note) '("Evidence entry"))
                                     (equal (%type-names map3 file) '("Repository file"))))
        (check "evidence:an-entry-reifies-its-assignments-evidence-occurrence"
               (let ((o (topic-maps.tmdm:topic-reified run-1)))
                 (and o (eq a (topic-maps.tmdm:canonical-topic (topic-maps.tmdm:occurrence-parent o)))
                      (equal (p::%name (topic-maps.tmdm:occurrence-type o)) "evidence")
                      (equal (topic-maps.tmdm:occurrence-value o) "SYNTHETIC: a run of the read-back test on a clean tree, as reported"))))
        (check "evidence:the-assignment-keeps-every-evidence-occurrence-unidentified-ones-unreified"
               (let ((os (%occ a "evidence")))
                 (and (= 6 (length os)) (= 4 (count-if #'topic-maps.tmdm:item-reifier os)))))
        (check "evidence:execution-facts-as-reported"
               (let ((ev (p::evidence-explanation map3 run-1)))
                 (and (equal (getf ev :source-repository) "codeberg.org/rgb/hyperdoc") (equal (getf ev :test-path) "dreyeck/tests/project-ctm.lisp")
                      (equal (getf ev :tested-revision) "0000000000000000000000000000000000000000") (equal (getf ev :tree-state) "clean")
                      (equal (getf ev :observation) "SYNTHETIC-PASS: the synthetic result was read in 20 s")
                      (equal (getf ev :observed-at) "2000-01-01T00:00:00Z") (equal (getf ev :reconstruction) "reconstructible from the tested revision"))))
        (check "evidence:modified-tree-without-content-reference-is-marked-not-reconstructible"
               (and (eql 0 (search "not fully reconstructible from the recorded revision" (getf (p::evidence-explanation map3 run-2) :reconstruction)))
                    (null (getf (p::evidence-explanation map3 run-2) :content-reference))))
        (check "evidence:modified-tree-with-content-reference"
               (eql 0 (search "reconstructible from the content reference" (getf (p::evidence-explanation map3 run-3) :reconstruction))))
        (check "evidence:the-test-file-is-the-program-not-the-report"
               (and (%plays map3 "reports execution of" "execution report" run-1) (eq file (%role-player (first (%plays map3 "reports execution of" "execution report" run-1)) "test file"))
                    (null (%plays map3 "considers evidence" "considered evidence" file)) (null (%occ file "observation"))))
        (check "evidence:another-repository-names-its-path-only" (and (null (%plays map3 "reports execution of" "execution report" run-3)) (%occ run-3 "test path")))
        (check "evidence:a-note-has-no-run-facts" (and (null (%occ note "observation")) (null (%occ note "tested revision"))))
        (check "evidence:a-record-considers-entries-only"
               (every (lambda (as) (member "evidence" (list (subseq (p:topic-key (p::%si (%role-player as "considered evidence"))) 0 8)) :test #'equal))
                      (%assocs map3 "considers evidence")))
        (check "evidence:second-dictionary-package-accepted-on-a-note"
               (and (equal (%explained s3 "synthetic-wp-3") '("accepted" :in-force ("acceptance/synthetic-record-3")))
                    (equal (mapcar (lambda (e) (p:topic-key (p::%si e))) (getf (applied map3 "synthetic-record-3") :evidence)) '("evidence/synthetic-assignment-1/synthetic-note-1"))
                    (equal (mapcar #'topic-maps.tmdm:occurrence-value (%occ (topic map3 (p:topic-iri "synthetic-wp-3")) "work status")) '("verified"))))
        (check "scope:one-records-page-two-declared-dictionaries"
               (let ((pages (loop for id in '("synthetic-wp-1" "synthetic-wp-3")
                                  collect (p::%si (%role-player (first (%plays map3 "defined in dictionary" "work package" (topic map3 (p:topic-iri id)))) "source page")))))
                 (and (= 2 (length (remove-duplicates pages :test #'equal))) (= 1 (length (remove-duplicates (loop for a in (%assocs map3 "declared on")
                                                                                  when (eql 0 (search "acceptance/" (p:topic-key (p::%si (%role-player a "declaration")))))
                                                                                    collect (%role-player a "source page")))))
                      (equal (%explained s3 "synthetic-wp-2") '("undecided" :no-record nil))))))
      ;; The native Workspace: from the package to its records, from a record to what it applied, considered and superseded.
      (let ((ws (p:reading-workspace s3)) (c1 (p:topic-key (%criterion +c1+))) (c2 (p:topic-key (%criterion +c2+))))
        (check "workspace:package-to-records-and-criterion-revisions"
               (every (lambda (k) (member k (%neighbours ws "synthetic-wp-1") :test #'equal))
                      (list "acceptance/synthetic-record-1" "acceptance/synthetic-record-2" c1 c2 "assignment/synthetic-assignment-1")))
        (check "workspace:record-to-criterion-authority-evidence-and-superseded"
               (every (lambda (k) (member k (%neighbours ws "acceptance/synthetic-record-2") :test #'equal))
                      (list c2 "authority/synthetic-authority" "evidence/synthetic-assignment-1/synthetic-run-1" "evidence/synthetic-assignment-1/synthetic-run-2"
                            "acceptance/synthetic-record-1" "synthetic-wp-1")))
        (check "workspace:historical-record-to-its-retained-criterion" (member c1 (%neighbours ws "acceptance/synthetic-record-1") :test #'equal))
        (check "workspace:evidence-entry-to-assignment-and-test-file"
               (every (lambda (k) (member k (%neighbours ws "evidence/synthetic-assignment-1/synthetic-run-1") :test #'equal))
                      '("assignment/synthetic-assignment-1" "file/dreyeck/tests/project-ctm.lisp" "acceptance/synthetic-record-1")))
        (check "workspace:history-keeps-the-walk"
               (<= 4 (length (dreyeck/topicmap::topicmap-workspace-history-of ws))))
        (dreyeck/topicmap:topicmap-workspace-go-to ws "synthetic-wp-1")
        (let ((html (v:view-html (find "Topicmap" (v:all-views ws) :key #'v:view-title :test #'equal))))
          (check "workspace:point-panel-explains-the-decision"
                 (and (search "rejected by" html) (search "Record, superseded" html) (search "not fully reconstructible" html))))
        (check "workspace:overview-explains-every-package"
               (let ((html (v:view-html (find "Project" (v:all-views s3) :key #'v:view-title :test #'equal))))
                 (and (search "rejected by SYNTHETIC synthetic-record-2, against criterion revision sha256-bd81f3b6" html)
                      (search "accepted by SYNTHETIC synthetic-record-3" html)
                      ;; Undecided for want of a record: the entries of the declared dictionaries that no record names, read from the HTML.
                      (let* ((items (p:sources-items (p::model-sources (p:reading-model s3))))
                             (entries (loop for i in items when (eq :dictionary (p::source-kind i))
                                            append (mapcar (lambda (n) (plump:attribute n "data-wbs-entry")) (%with "section" "data-wbs-entry" (p::source-text i)))))
                             (decided (loop for i in items when (eq :acceptance-records (p::source-kind i))
                                            append (loop for n in (%with "p" "data-ref" (p::source-text i))
                                                         when (equal "work-package" (plump:attribute n "data-field")) collect (plump:attribute n "data-ref"))))
                             (open (set-difference entries decided :test #'equal)))
                        (and open (= (length open) (%count "undecided: no record" html))
                             (every (lambda (id) (let ((at (search (format nil ">~A</button>" id) html)))
                                                   (and at (search "undecided: no record" html :start2 at :end2 (search "</li>" html :start2 at)))))
                                    open)))))))))
  ;; 3b. A criterion revision at Point: the occurrence it reifies, read with TOPIC-REIFIED and rendered in the Point panel.
  (let* ((s1 (%scenario "S1" :dictionary "synthetic-dictionary-c1.html" :records "synthetic-records-s1.html"))
         (s2 (%scenario "S2" :records "synthetic-records-s1.html"))
         (s3 (%scenario "S3"))
         (c1 (p:topic-key (%criterion +c1+))) (c2 (p:topic-key (%criterion +c2+))))
    (flet ((panel (reading key)
             (let ((ws (p:reading-workspace reading)))
               (dreyeck/topicmap:topicmap-workspace-go-to ws key)
               (%panel-section ws "<h4>WBS criterion revision")))
           (shows (panel &rest parts) (and panel (every (lambda (part) (search part panel)) parts))))
      (let ((s1-c1 (panel s1 c1)) (s2-c1 (panel s2 c1)) (s3-c1 (panel s3 c1)) (s3-c2 (panel s3 c2))
            (identifier (format nil "<code>~A</code>" (%criterion +c1+))))
        (check "criterion-point:S1:C1-current-30-s"
               (shows s1-c1 identifier "the occurrence WBS acceptance criterion of the work package below (current)"
                      (format nil "<td>Criterion text</td><td>~A</td>" +c1+) ">SYNTHETIC package one</button>" ">SYNTHETIC synthetic-record-1</button>"))
        (check "criterion-point:S2:C1-same-identity-and-text-retained"
               (shows s2-c1 identifier "the occurrence retained WBS acceptance criterion of the work package below (retained)"
                      (format nil "<td>Criterion text</td><td>~A</td>" +c1+) ">SYNTHETIC package one</button>"))
        (check "criterion-point:S3:C1-retained-its-own-text"
               (and (shows s3-c1 identifier "(retained)" (format nil "<td>Criterion text</td><td>~A</td>" +c1+) ">SYNTHETIC synthetic-record-1</button>")
                    (not (search +c2+ s3-c1)) (not (search "synthetic-record-2" s3-c1))))
        (check "criterion-point:S3:C2-current-its-own-text"
               (and (shows s3-c2 (format nil "<code>~A</code>" (%criterion +c2+)) "the occurrence WBS acceptance criterion of the work package below (current)"
                           (format nil "<td>Criterion text</td><td>~A</td>" +c2+) ">SYNTHETIC synthetic-record-2</button>")
                    (not (search +c1+ s3-c2))))
        (check "criterion-point:only-at-a-criterion-revision"
               (let ((ws (p:reading-workspace s3)))
                 (dreyeck/topicmap:topicmap-workspace-go-to ws "synthetic-wp-1")
                 (null (%panel-section ws "<h4>WBS criterion revision")))))
      ;; Pressing the panel's buttons moves the Point to the package and to a record; History keeps the walk in order.
      (let ((ws (p:reading-workspace s3)))
        (dreyeck/topicmap:topicmap-workspace-go-to ws c1)
        (%press ws "SYNTHETIC package one")
        (check "criterion-point:button-to-the-package" (equal "synthetic-wp-1" (dreyeck/topicmap::topicmap-workspace-point-of ws)))
        (dreyeck/topicmap:topicmap-workspace-go-to ws c1)
        (%press ws "SYNTHETIC synthetic-record-1")
        (check "criterion-point:button-to-the-record" (equal "acceptance/synthetic-record-1" (dreyeck/topicmap::topicmap-workspace-point-of ws)))
        (check "criterion-point:history-keeps-the-walk"
               (equal (subseq (dreyeck/topicmap::topicmap-workspace-history-of ws) 0 3) (list c1 "synthetic-wp-1" c1))))))
  ;; 4. Lifecycle without time: an earlier date decides nothing; a conflict and a withdrawal leave the package undecided.
  (let* ((earlier (%scenario "earlier" :records-text (%replace (%fixture "synthetic-records-s3.html") "data-datetime=\"2000-01-03T12:00:00Z\"" "data-datetime=\"1999-01-01T00:00:00Z\"")))
         (conflict (%scenario "conflict" :records "synthetic-records-conflict.html"))
         (withdrawn (%scenario "withdrawn" :records "synthetic-records-withdrawn.html"))
         (contested (%scenario "withdrawal conflict" :records "synthetic-records-withdrawal-conflict.html"))
         (none (%scenario "no record" :records-text (%fixture "synthetic-records-s1.html") :dictionary "synthetic-dictionary-c1.html")))
    (dolist (r (list earlier conflict withdrawn contested))
      (check (format nil "lifecycle:~A:read-back" (p::revision-label (p:reading-document r))) (%read-p r))
      (check (format nil "lifecycle:~A:gaps-and-explanation-agree" (p::revision-label (p:reading-document r))) (%agrees-p r)))
    (check "lifecycle:an-earlier-time-decides-nothing" (equal (%explained earlier "synthetic-wp-1") '("rejected" :in-force ("acceptance/synthetic-record-2"))))
    (check "lifecycle:conflict-no-decision-though-record-2-is-later"
           (and (equal (%explained conflict "synthetic-wp-1") '("undecided" :conflict ("acceptance/synthetic-record-1" "acceptance/synthetic-record-2")))
                (let ((g (find "acceptance-records-in-conflict" (p:model-gaps (p:reading-model conflict)) :key #'p:gap-rule :test #'equal)))
                  (and g (= 3 (length (p:gap-subjects g)))))))
    (check "lifecycle:one-withdrawal-no-decision"
           (and (equal (%explained withdrawn "synthetic-wp-1") '("undecided" :withdrawn ("acceptance/synthetic-withdrawal-1")))
                (equal (%gap-rules withdrawn "synthetic-wp-1") '("acceptance-withdrawn"))))
    (let* ((map (p:revision-map (p:reading-document withdrawn))) (w (gethash (p::%iri "acceptance" "synthetic-withdrawal-1") (p::%index map))))
      (check "lifecycle:a-withdrawal-judges-nothing"
             (and (equal (%type-names map w) '("Withdrawal record")) (null (%occ w "decision"))
                  (null (%plays map "acceptance decision" "acceptance record" w)) (null (%plays map "considers evidence" "acceptance record" w))
                  (%plays map "withdrawal" "withdrawal record" w) (%plays map "supersedes" "superseding record" w))))
    (check "lifecycle:a-withdrawal-and-a-judgment-unsuperseded-conflict"
           (and (equal (%explained contested "synthetic-wp-1") '("undecided" :conflict ("acceptance/synthetic-record-2" "acceptance/synthetic-withdrawal-1")))
                (equal (%gap-rules contested "synthetic-wp-1") '("acceptance-records-in-conflict"))))
    (check "lifecycle:append-only-across-all-scenarios"
           (let ((t1 (p:model-text (p:reading-model none))))
             (every (lambda (r) (null (%records-lost t1 (p:model-text (p:reading-model r))))) (list conflict withdrawn contested)))))
  ;; 5. Refused, never completed. Each case changes one thing of a scenario that is read.
  (let ((s3 (%fixture "synthetic-records-s3.html")) (c2 (%fixture "synthetic-dictionary-c2.html"))
        (addition (%fixture "synthetic-assignments-addition.html"))
        (r1-revision (format nil "data-revision=\"sha256-~A\"" (%sha-text +c1+))))
    (flet ((refused (label expected &rest keys)
             (let ((reason (apply #'%refusal keys)))
               (check (format nil "refused:~A" label) (and reason (search expected reason))))))
      (check "refused:none-for-the-scenario-itself" (null (%refusal)))
      ;; Criterion revisions
      (refused "criterion-changed-without-retention" "neither states nor retains"
               :records "synthetic-records-s1.html" :dictionary-text (%replace c2 (format nil "<ul data-field=\"retained-acceptance\"><li>~A</li></ul>~%" +c1+) ""))
      (refused "retained-equal-to-current" "retains its current acceptance criterion" :dictionary-text (%replace-all c2 (format nil "<li>~A</li>" +c1+) (format nil "<li>~A</li>" +c2+)))
      (refused "retained-twice" "retains one acceptance criterion twice" :dictionary-text (%replace c2 (format nil "<li>~A</li>" +c1+) (format nil "<li>~A</li><li>~A</li>" +c1+ +c1+)))
      (refused "no-explicit-revision" "has no criterion (data-revision)" :records-text (%replace s3 (format nil " ~A" r1-revision) ""))
      (refused "other-packages-criterion" "applies the criterion of" :records-text (%replace s3 "data-field=\"criterion\" data-ref=\"synthetic-wp-1\"" "data-field=\"criterion\" data-ref=\"synthetic-wp-2\""))
      ;; Declared packages only
      (refused "proposed-package" "proposed, not declared" :records-text (%replace s3 "data-acceptance-record=\"synthetic-record-3\">
<h3>SYNTHETIC synthetic-record-3</h3>
<p data-field=\"work-package\" data-ref=\"synthetic-wp-3\"" "data-acceptance-record=\"synthetic-record-3\">
<h3>SYNTHETIC synthetic-record-3</h3>
<p data-field=\"work-package\" data-ref=\"synthetic-wp-p\""))
      (refused "undeclared-package" "which no page declares" :records-text (%replace s3 "<p data-field=\"work-package\" data-ref=\"synthetic-wp-3\"" "<p data-field=\"work-package\" data-ref=\"synthetic-wp-none\""))
      (refused "entry-in-two-dictionaries" "two WBS Dictionary entries" :second (%replace-all (%fixture "synthetic-second-dictionary.html") "synthetic-wp-3" "synthetic-wp-2"))
      (refused "declared-dictionary-entry-for-a-proposal" "names no declared work package" :proposed nil
               :second (%replace-all (%fixture "synthetic-second-dictionary.html") "synthetic-wp-3" "synthetic-wp-p") :records nil)
      ;; Evidence
      (refused "whole-assignment-as-evidence" "whole assignment" :records-text (%replace s3 "<li data-evidence=\"synthetic-assignment-1/synthetic-note-1\"" "<li data-assignment=\"synthetic-assignment-1\""))
      (refused "test-file-as-evidence" "a program and not observed evidence" :records-text (%replace s3 "<li data-evidence=\"synthetic-assignment-1/synthetic-note-1\"" "<li data-test=\"dreyeck/tests/project-ctm.lisp\""))
      (refused "unknown-evidence-entry" "which no assignment identifies" :records-text (%replace s3 "synthetic-assignment-1/synthetic-note-1" "synthetic-assignment-1/synthetic-none"))
      (refused "unidentified-entry-with-run-facts" "has no data-evidence" :texts (%fixture-texts (%replace addition "<li data-test=\"dreyeck/tests/project-ctm.lisp\">" "<li data-test=\"dreyeck/tests/project-ctm.lisp\" data-tree=\"clean\">")))
      (refused "incomplete-execution-report" "has no data-tree" :texts (%fixture-texts (%replace addition " data-tree=\"clean\"" "")))
      (refused "unknown-tree-state" "not clean or modified" :texts (%fixture-texts (%replace addition "data-tree=\"clean\"" "data-tree=\"dirty\"")))
      (refused "content-reference-on-a-clean-tree" "content reference for a clean tree" :texts (%fixture-texts (%replace addition "data-tree=\"clean\"" "data-tree=\"clean\" data-content=\"sha256:00\"")))
      (refused "revision-not-a-commit" "not a commit" :texts (%fixture-texts (%replace addition "data-revision=\"2222222\"" "data-revision=\"main\"")))
      (refused "run-facts-without-a-test" "names no test" :texts (%fixture-texts (%replace addition "<li data-evidence=\"synthetic-note-1\">" "<li data-evidence=\"synthetic-note-1\" data-tree=\"clean\">")))
      (refused "two-entries-one-id" "two evidence entries" :texts (%fixture-texts (%replace addition "data-evidence=\"synthetic-note-1\"" "data-evidence=\"synthetic-run-1\"")))
      (refused "two-entries-one-text" "would be one occurrence" :texts (%fixture-texts (%replace addition "<li>SYNTHETIC: an evidence note without an ID</li>" "<li>SYNTHETIC: the synthetic note exists, as the executor writes</li>")))
      ;; Lifecycle
      (refused "supersedes-unknown" "which the page does not record" :records-text (%replace s3 "<li data-record=\"synthetic-record-1\">" "<li data-record=\"synthetic-record-none\">"))
      (refused "supersedes-itself" "supersedes itself" :records-text (%replace s3 "<li data-record=\"synthetic-record-1\">" "<li data-record=\"synthetic-record-2\">"))
      (refused "supersedes-a-later-record" "comes later on the page"
               :records-text (%replace s3 "<p data-field=\"authority\" data-ref=\"synthetic-authority\">SYNTHETIC.</p>
<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-assignment-1/synthetic-run-1\">SYNTHETIC: 20 s meets 30 s</li></ul>"
                                       "<p data-field=\"authority\" data-ref=\"synthetic-authority\">SYNTHETIC.</p>
<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-assignment-1/synthetic-run-1\">SYNTHETIC: 20 s meets 30 s</li></ul>
<ul data-field=\"supersedes\"><li data-record=\"synthetic-record-2\">SYNTHETIC</li></ul>"))
      (refused "supersedes-another-package" "a record on"
               :records-text (%replace s3 "<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-assignment-1/synthetic-note-1\">SYNTHETIC: the note exists</li></ul>"
                                       "<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-assignment-1/synthetic-note-1\">SYNTHETIC: the note exists</li></ul>
<ul data-field=\"supersedes\"><li data-record=\"synthetic-record-1\">SYNTHETIC</li></ul>"))
      (let ((w (%fixture "synthetic-records-withdrawn.html")))
        (refused "withdrawal-without-supersedes" "supersedes no earlier record" :records-text (%replace w "<ul data-field=\"supersedes\"><li data-record=\"synthetic-record-1\">SYNTHETIC: recorded in error</li></ul>" ""))
        (refused "withdrawal-with-criterion" "names a criterion"
                 :records-text (%replace w "<p data-field=\"disposition\"" (format nil "<p data-field=\"criterion\" data-ref=\"synthetic-wp-1\" ~A>x</p><p data-field=\"disposition\"" r1-revision)))
        (refused "withdrawal-with-evidence" "considers evidence"
                 :records-text (%replace w "<ul data-field=\"supersedes\">" "<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-assignment-1/synthetic-run-1\">x</li></ul><ul data-field=\"supersedes\">"))
        (refused "other-disposition" "the one disposition is withdrawn" :records-text (%replace w "data-disposition=\"withdrawn\"" "data-disposition=\"revoked\"")))
      (refused "decision-and-disposition" "both a decision and a disposition"
               :records-text (%replace s3 "<p data-field=\"decision\" data-decision=\"rejected\">" "<p data-field=\"disposition\" data-disposition=\"withdrawn\">x</p><p data-field=\"decision\" data-decision=\"rejected\">"))
      (refused "no-decision" "has no decision" :records-text (%replace s3 "<p data-field=\"decision\" data-decision=\"rejected\">SYNTHETIC decision, made by no one.</p>" ""))
      (refused "a-status-is-not-a-decision" "not one of" :records-text (%replace s3 "data-decision=\"rejected\"" "data-decision=\"verified\""))
      (refused "time-not-utc" "is not a UTC" :records-text (%replace s3 "2000-01-03T12:00:00Z" "2000-01-03"))
      (refused "record-twice" "states the record" :records-text (%replace s3 "synthetic-record-3\"" "synthetic-record-1\""))
      ;; Authority and source boundaries
      (refused "undeclared-authority" "is not declared on the Acceptance Records page" :records-text (%replace s3 "data-ref=\"synthetic-authority\">SYNTHETIC.</p>
<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-assignment-1/synthetic-note-1\"" "data-ref=\"synthetic-executor\">SYNTHETIC.</p>
<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-assignment-1/synthetic-note-1\""))
      (refused "authority-twice" "declares the authority" :records-text (%replace s3 "</a></li></ul>" "</a></li><li><a data-authority=\"synthetic-authority\">again</a></li></ul>"))
      (refused "record-on-the-assignments-page" "only an Acceptance Records page states a record"
               :texts (%fixture-texts (%replace addition "<p data-field=\"observed-state\">" "<p data-field=\"verdict\" data-decision=\"accepted\">SYNTHETIC: an executor's verdict</p><p data-field=\"observed-state\">")))
      (refused "record-in-a-dictionary" "only an Acceptance Records page states a record"
               :dictionary-text (%replace c2 "<h1>SYNTHETIC WBS Dictionary</h1>" "<h1>SYNTHETIC WBS Dictionary</h1><section data-acceptance-record=\"synthetic-x\"></section>")))))

(defun run-acceptance-tests ()
  (let ((*checks* 0) (before (%source-digests)) (ctm-before (%sha (p:project-ctm-pathname))))
    (acceptance-tests)
    (check "preserved:source-pages-unchanged" (equal before (%source-digests)))
    (check "preserved:retained-ctm-unchanged" (equal ctm-before (%sha (p:project-ctm-pathname))))
    (format t "~&PROJECT-CTM-ACCEPTANCE-PASS: ~D checks; no acceptance recorded in the project CTM; revisions, evidence entries, supersession, withdrawal and conflict shown on synthetic fixtures~%" *checks*)
    *checks*))

(defun run-tests () (+ (run-source-tests) (run-readback-tests) (run-acceptance-tests)))
