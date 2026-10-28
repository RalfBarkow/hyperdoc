;;;; The proposed scope Regular HyperDoc Catalog with a Navigable Project Topic Map (Zettel 11359), read from the page text
(in-package #:dreyeck/work/project/tests)

;; Every expectation here is derived from the pages: the proposals of Implementation Assignments, the draft Regular Catalog WBS
;; Dictionary, the Work pages and the real emitter. No Catalog-wide item count is written down. The scope's own IDs are the proposals
;; whose ID is topic-maps-regular-hyperdoc, tm-regular-catalog or starts with tm-reg-.

(defparameter +scope-work-item+ "topic-maps-regular-hyperdoc")
(defparameter +scope-deliverable+ "tm-regular-catalog")
(defparameter +scope-relations+ '("work:relation/decomposes-into" "work:relation/produces" "work:relation/depends-on"))

(defun %scope-id-p (id)
  (or (equal id +scope-work-item+) (equal id +scope-deliverable+) (eql 0 (search "tm-reg-" id))))
(defun %assignments-text () (%project-page "Implementation Assignments"))
(defun %scope-proposals (text)
  "((id . kind) ...) of the proposals of the scope, in page order."
  (loop for node in (%with "a" "data-proposed-topic" text)
        for id = (plump:attribute node "data-proposed-topic")
        when (%scope-id-p id) collect (cons id (plump:attribute node "data-kind"))))
(defun %scope-statements (text)
  "((from relation to) ...) of the proposed statements that touch the scope, in page order."
  (loop for node in (%with "li" "data-proposed-from" text)
        for statement = (list (plump:attribute node "data-proposed-from") (plump:attribute node "data-proposed-relation")
                              (plump:attribute node "data-proposed-to"))
        when (or (%scope-id-p (first statement)) (%scope-id-p (third statement))) collect statement))
(defun %ids-of-kind (proposals kind) (loop for (id . k) in proposals when (equal k kind) collect id))
(defun %duplicates (list &key (test #'equal))
  (loop for (x . more) on list when (member x more :test test) collect x))
(defun %kind-of (proposals id) (cdr (assoc id proposals :test #'equal)))

(defun %acyclic-p (edges)
  "Whether the directed EDGES ((from . to) ...) contain no cycle."
  (let ((state (make-hash-table :test #'equal)))
    (labels ((visit (node)
               (case (gethash node state)
                 (:done t)
                 (:active nil)
                 (t (setf (gethash node state) :active)
                    (prog1 (every #'visit (loop for (from . to) in edges when (equal from node) collect to))
                      (setf (gethash node state) :done))))))
      (every #'visit (remove-duplicates (mapcar #'car edges) :test #'equal)))))

(defun scope-identity-tests ()
  (let* ((text (%assignments-text)) (proposals (%scope-proposals text)) (ids (mapcar #'car proposals))
         (all-proposed (loop for node in (%with "a" "data-proposed-topic" text) collect (plump:attribute node "data-proposed-topic")))
         (model (p:build-project-model))
         (declared (loop for d in (p:model-declarations model) unless (p::declaration-proposal-p d) collect (p:declaration-id d))))
    (check "scope:has-ids" ids)
    (check "scope:each-id-proposed-once" (null (%duplicates all-proposed)))
    (check "scope:no-id-is-declared" (notany (lambda (id) (member id declared :test #'equal)) ids))
    (check "scope:no-id-is-on-a-work-page"
           (let ((sources (p:read-project-sources)))
             (notany (lambda (id) (some (lambda (role) (search (format nil "data-topic=\"~A\"" id) (p::source-text (%item sources role))))
                                        '(:work-breakdown :plan)))
                     ids)))
    (check "scope:exactly-one-work-item" (equal (list +scope-work-item+) (%ids-of-kind proposals "work item")))
    (check "scope:exactly-one-deliverable" (equal (list +scope-deliverable+) (%ids-of-kind proposals "deliverable")))
    (check "scope:work-packages-follow-the-naming" (every (lambda (id) (eql 0 (search "tm-reg-wp-" id))) (%ids-of-kind proposals "work package")))
    (check "scope:plan-steps-follow-the-naming" (every (lambda (id) (eql 0 (search "tm-reg-p" id))) (%ids-of-kind proposals "plan step")))
    (check "scope:preconditions-follow-the-naming" (every (lambda (id) (eql 0 (search "tm-reg-pre-" id))) (%ids-of-kind proposals "precondition")))
    (check "scope:every-proposal-has-a-known-kind"
           (every (lambda (kind) (member kind '("work item" "deliverable" "work package" "plan step" "precondition") :test #'equal))
                  (mapcar #'cdr proposals)))
    (check "scope:one-plan-step-for-each-work-package"
           (= (length (%ids-of-kind proposals "work package")) (length (%ids-of-kind proposals "plan step"))))
    ;; The model reads the same proposals, as proposals.
    (let ((read (loop for d in (p:model-declarations model) when (and (p::declaration-proposal-p d) (%scope-id-p (p:declaration-id d)))
                      collect (p:declaration-id d))))
      (check "scope:model-reads-every-proposal" (equal (sort (copy-list read) #'string<) (sort (copy-list ids) #'string<)))
      (check "scope:model-gives-no-status"
             (every (lambda (d) (null (p:declaration-status d)))
                    (remove-if-not (lambda (d) (%scope-id-p (p:declaration-id d))) (p:model-declarations model)))))))

;; A written association line that equals another is, in TMDM, the same Association: the read-back would have one fewer than the lines.
(defun %association-lines (text)
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        when (and (plusp (length line)) (alpha-char-p (char line 0)) (find #\( line) (find #\: line :end (position #\( line)))
          collect (let ((tilde (search " ~ " line))) (if tilde (subseq line 0 tilde) line))))

(defun scope-association-tests ()
  (let ((lines (%association-lines (p:materialize-project-ctm))))
    (check "associations:the-ctm-has-association-lines" lines)
    (check "associations:no-two-written-association-lines-are-equal" (null (%duplicates lines :test #'string=)))
    ;; Positive control: the check sees a line that is written twice.
    (check "associations:control-a-repeated-line-is-detected" (%duplicates (append lines (list (first lines))) :test #'string=))))

(defun scope-relation-tests ()
  (let* ((text (%assignments-text)) (proposals (%scope-proposals text)) (statements (%scope-statements text))
         (packages (%ids-of-kind proposals "work package")) (steps (%ids-of-kind proposals "plan step")))
    (check "relations:the-scope-has-statements" statements)
    (check "relations:only-the-three-relation-words" (every (lambda (s) (member (second s) +scope-relations+ :test #'equal)) statements))
    (check "relations:closed-over-the-scope" (every (lambda (s) (and (%scope-id-p (first s)) (%scope-id-p (third s)))) statements))
    (check "relations:no-statement-twice" (null (%duplicates statements)))
    (check "relations:one-relation-between-two-topics"
           (null (%duplicates (mapcar (lambda (s) (list (first s) (third s))) statements))))
    (let ((decomposes (remove "work:relation/decomposes-into" statements :key #'second :test-not #'equal))
          (produces (remove "work:relation/produces" statements :key #'second :test-not #'equal))
          (depends (remove "work:relation/depends-on" statements :key #'second :test-not #'equal)))
      ;; WBS decomposition: from the Deliverable to its work packages, each once
      (check "relations:decomposition-leads-from-the-deliverable"
             (every (lambda (s) (equal +scope-deliverable+ (first s))) decomposes))
      (check "relations:decomposition-covers-each-work-package-once"
             (equal (sort (mapcar #'third decomposes) #'string<) (sort (copy-list packages) #'string<)))
      ;; Products: a plan step produces a work package, each package has one producer
      (check "relations:products-lead-from-plan-steps-to-work-packages"
             (every (lambda (s) (and (equal "plan step" (%kind-of proposals (first s))) (equal "work package" (%kind-of proposals (third s))))) produces))
      (check "relations:each-work-package-has-one-producer"
             (equal (sort (mapcar #'third produces) #'string<) (sort (copy-list packages) #'string<)))
      (check "relations:each-plan-step-produces-one-package"
             (equal (sort (mapcar #'first produces) #'string<) (sort (copy-list steps) #'string<)))
      ;; Execution dependencies: a plan step waits for another step or a precondition, never for a work package
      (check "relations:dependencies-lead-from-plan-steps"
             (every (lambda (s) (equal "plan step" (%kind-of proposals (first s)))) depends))
      (check "relations:dependencies-wait-for-steps-or-preconditions"
             (every (lambda (s) (member (%kind-of proposals (third s)) '("plan step" "precondition") :test #'equal)) depends))
      (check "relations:no-dependency-of-a-step-on-itself" (notany (lambda (s) (equal (first s) (third s))) depends))
      (check "relations:dependencies-are-acyclic" (%acyclic-p (mapcar (lambda (s) (cons (first s) (third s))) depends)))
      (check "relations:every-precondition-is-waited-for"
             (every (lambda (id) (find id depends :key #'third :test #'equal)) (%ids-of-kind proposals "precondition")))
      ;; The three families are distinct: no pair of topics is in two of them, and the WBS has no execution order
      (check "relations:families-are-distinct"
             (null (intersection (mapcar (lambda (s) (list (first s) (third s))) decomposes)
                                 (append (mapcar (lambda (s) (list (first s) (third s))) produces)
                                         (mapcar (lambda (s) (list (first s) (third s))) depends))
                                 :test #'equal)))
      (check "relations:no-dependency-between-work-packages"
             (notany (lambda (s) (or (member (first s) packages :test #'equal) (member (third s) packages :test #'equal))) depends))
      ;; No relation contract between a Work Item and a Deliverable exists: none is invented
      (check "relations:none-is-invented-between-work-item-and-deliverable"
             (notany (lambda (s) (and (member +scope-work-item+ (list (first s) (third s)) :test #'equal)
                                      (member +scope-deliverable+ (list (first s) (third s)) :test #'equal)))
                     statements))
      (check "relations:the-work-item-has-no-statement"
             (notany (lambda (s) (member +scope-work-item+ (list (first s) (third s)) :test #'equal)) statements)))))

(defun %dictionary-entries-by-id (text)
  (mapcar (lambda (entry) (cons (dreyeck/work/ctm-page-authoring::entry-element-id entry) entry))
          (dreyeck/work/ctm-page-authoring::read-wbs-dictionary text)))

(defun scope-dictionary-tests ()
  (let* ((text (%project-page "Regular Catalog WBS Dictionary")) (proposals (%scope-proposals (%assignments-text)))
         (packages (%ids-of-kind proposals "work package")) (entries (%dictionary-entries-by-id text))
         (root (asdf:system-source-directory "dreyeck")))
    (check "dictionary:has-entries" entries)
    (check "dictionary:one-entry-for-each-work-package"
           (equal (sort (mapcar #'car entries) #'string<) (sort (copy-list packages) #'string<)))
    (check "dictionary:no-package-has-two-entries" (null (%duplicates (mapcar #'car entries))))
    (check "dictionary:no-entry-describes-another-scope's-package"
           (every (lambda (id) (member id packages :test #'equal)) (mapcar #'car entries)))
    (check "dictionary:the-existing-dictionaries-have-no-entry-for-a-scope-package"
           (let ((others (append (dreyeck/work/ctm-page-authoring::read-wbs-dictionary (%project-page "Project Work Exchange WBS Dictionary"))
                                 (dreyeck/work/ctm-page-authoring::read-wbs-dictionary
                                  (p::source-text (%item (p:read-project-sources) :dictionary))))))
             (notany (lambda (e) (member (dreyeck/work/ctm-page-authoring::entry-element-id e) packages :test #'equal)) others)))
    (dolist (entry (mapcar #'cdr entries))
      (let ((id (dreyeck/work/ctm-page-authoring::entry-element-id entry)))
        (dolist (field '("scope" "acceptance" "authority" "effect" "evidence"))
          (check (format nil "dictionary:~A-states-~A" id field)
                 (let ((value (dreyeck/work/ctm-page-authoring::entry-field entry field)))
                   (and value (plusp (length (string-trim " " (princ-to-string value))))))))
        (check (format nil "dictionary:~A-names-what-it-excludes" id)
               (search "Excluded" (princ-to-string (dreyeck/work/ctm-page-authoring::entry-field entry "scope"))))
        (check (format nil "dictionary:~A-has-controls" id) (dreyeck/work/ctm-page-authoring::entry-controls entry))
        (dolist (control (dreyeck/work/ctm-page-authoring::entry-controls entry))
          (let ((coverage (string-downcase (princ-to-string (dreyeck/work/ctm-page-authoring::control-coverage control))))
                (test (dreyeck/work/ctm-page-authoring::control-test control))
                (marker (dreyeck/work/ctm-page-authoring::control-marker control))
                (control-id (dreyeck/work/ctm-page-authoring::control-id control)))
            (check (format nil "dictionary:~A:~A-coverage-is-known" id control-id) (member coverage '("existing" "planned" "external") :test #'equal))
            (cond ((equal coverage "existing")
                   ;; A control declared existing names a test file in this repository that contains its marker
                   (check (format nil "dictionary:~A:~A-test-exists" id control-id) (and test (probe-file (merge-pathnames test root))))
                   (check (format nil "dictionary:~A:~A-marker-is-in-the-test" id control-id)
                          (and marker (search marker (uiop:read-file-string (merge-pathnames test root) :external-format :utf-8)))))
                  (t (check (format nil "dictionary:~A:~A-names-no-test-yet" id control-id) (null test))))))))
    ;; The packages the user can read the controls of: planned controls are stated, never counted as coverage
    (check "dictionary:some-control-is-planned"
           (loop for (nil . entry) in entries
                 thereis (find "planned" (dreyeck/work/ctm-page-authoring::entry-controls entry) :test #'equal
                                                                                                    :key (lambda (c) (string-downcase (princ-to-string (dreyeck/work/ctm-page-authoring::control-coverage c)))))))))

(defun scope-model-tests ()
  "The draft dictionary read as the emitter reads a draft: for the proposed packages, declaring nothing."
  (let* ((proposals (%scope-proposals (%assignments-text))) (packages (%ids-of-kind proposals "work package"))
         (retained (p:materialize-project-ctm))
         (draft (list :role :regular-catalog-dictionary :book "dreyeck/work/project" :title "Regular Catalog WBS Dictionary" :kind :proposed-dictionary
                      :path "dreyeck/pages/project/Regular Catalog WBS Dictionary.html" :text (%project-page "Regular Catalog WBS Dictionary")))
         (model (p:build-project-model (p:read-project-sources :extra (list draft))))
         (with-draft (p:model-text model)))
    (check "model:the-draft-is-not-a-source-of-the-project-ctm"
           (notany (lambda (item) (search "Regular Catalog" (p:source-path item))) (p:sources-items (p:read-project-sources))))
    (check "model:the-retained-ctm-states-no-draft-dictionary-entry"
           (notany (lambda (id) (search (format nil "s:proposed-in-dictionary(s:work-package: w:~A," id) retained)) packages))
    (check "model:the-emitter-reads-the-draft-for-every-proposed-package"
           (equal (sort (mapcar (lambda (pair) (dreyeck/work/ctm-page-authoring::entry-element-id (car pair))) (p:model-proposed-entries model)) #'string<)
                  (sort (copy-list packages) #'string<)))
    (dolist (id packages)
      (check (format nil "model:~A-is-proposed-on-the-assignments-page" id)
             (search (format nil "s:proposed-on(s:proposal: w:~A," id) retained))
      (check (format nil "model:~A-is-not-declared" id)
             (not (search (format nil "s:declared-on(s:declaration: w:~A," id) retained)))
      (check (format nil "model:~A-has-a-draft-entry-when-the-draft-is-read" id)
             (search (format nil "s:proposed-in-dictionary(s:work-package: w:~A," id) with-draft)))
    (check "model:reading-the-draft-adds-no-declaration"
           (= (count-if-not #'p::declaration-proposal-p (p:model-declarations model))
              (count-if-not #'p::declaration-proposal-p (p:model-declarations (p:build-project-model)))))
    (check "model:reading-the-draft-adds-no-acceptance-record"
           (let ((acceptance (p:model-acceptance model))) (or (null acceptance) (null (p:acceptance-records acceptance)))))))

(defun %assignment-sections (text)
  (loop for node in (%with "section" "data-assignment" text) collect (cons (plump:attribute node "data-assignment") node)))
(defun %section-field (section name)
  (loop for child across (plump:children section)
        when (and (plump:element-p child) (equal name (plump:attribute child "data-field"))) return child
        do (when (plump:element-p child) (let ((found (%section-field child name))) (when found (return found))))))
(defun %text-of (node) (if node (plump:text node) ""))

(defun scope-assignment-tests ()
  (let* ((text (%assignments-text)) (proposals (%scope-proposals text)) (packages (%ids-of-kind proposals "work package"))
         (sections (%assignment-sections text))
         (scope-sections (remove-if-not (lambda (pair) (let ((item (%section-field (cdr pair) "work-item")))
                                                         (and item (equal +scope-work-item+ (plump:attribute item "data-ref")))))
                                        sections))
         (assignment-ids (mapcar #'car sections)))
    (check "assignments:each-assignment-id-is-unique" (null (%duplicates assignment-ids)))
    (check "assignments:the-scope-modeling-assignment-has-its-own-id" (assoc "cc-2026-10-28-regular-catalog-scope" sections :test #'equal))
    (check "assignments:scope-assignments-exist" (< 1 (length scope-sections)))
    (dolist (pair scope-sections)
      (let* ((id (car pair)) (section (cdr pair)) (delivers (%section-field section "delivers")))
        (check (format nil "assignments:~A-names-an-acceptance-state" id)
               (search "No acceptance by the user is recorded." (%text-of (%section-field section "acceptance"))))
        (check (format nil "assignments:~A-reports-without-accepting" id)
               (search "This report is not an acceptance." (%text-of (%section-field section "observed-state"))))
        (check (format nil "assignments:~A-confirms-no-plan-step" id)
               (search "No Plan Step is confirmed" (%text-of (%section-field section "plan-step"))))
        (when delivers
          (check (format nil "assignments:~A-delivers-a-proposed-package-of-the-scope" id)
                 (member (plump:attribute delivers "data-ref") packages :test #'equal)))))
    ;; Each package in the scope that an assignment delivers is delivered by exactly one assignment here
    (let ((delivered (loop for (nil . section) in scope-sections for d = (%section-field section "delivers") when d collect (plump:attribute d "data-ref"))))
      (check "assignments:no-package-is-delivered-twice" (null (%duplicates delivered)))
      (check "assignments:delivered-packages-are-the-first-three" (every (lambda (id) (member id '("tm-reg-wp-1" "tm-reg-wp-2" "tm-reg-wp-3") :test #'equal)) delivered)))
    ;; The four local commits are attached as evidence, to the packages, never as work packages of their own
    (let ((commits '("a55c4a0b7d984cab1f2fd429be26e4ceb0c1b60b" "df5cf16ebf53944325f737313cceae30a7ea2513"
                     "c50cf5f7c26504e3ad34f701edcb8b3969b5879c" "909bcab342c8107f3b2ed2d052f72307b43a9c7f")))
      (dolist (commit commits)
        (check (format nil "assignments:commit-~A-is-evidence-of-a-scope-assignment" (subseq commit 0 8))
               (loop for (nil . section) in scope-sections
                     thereis (search commit (%text-of (%section-field section "evidence"))))))
      (check "assignments:the-commits-are-not-work-packages"
             (notany (lambda (id) (some (lambda (commit) (search (subseq commit 0 8) id)) commits)) (mapcar #'car proposals))))
    ;; An execution report is a report: the emitter requires its facts; a run on a modified tree says it is not reconstructible
    ;; The productive page keeps its evidence as notes; identified evidence entries are for the user to introduce (see the acceptance tests).
    (check "assignments:the-scope-assignments-state-their-evidence"
           (every (lambda (pair) (plusp (length (plump:get-elements-by-tag-name (%section-field (cdr pair) "evidence") "li")))) scope-sections))
    (check "assignments:the-scope-assignments-keep-evidence-as-notes" (null (%with "li" "data-evidence" text)))
    (let ((model (p:build-project-model)))
      (check "assignments:no-acceptance-record-exists"
             (let ((acceptance (p:model-acceptance model))) (or (null acceptance) (null (p:acceptance-records acceptance))))))))

(defun scope-preservation-tests ()
  "The scope changes no historical assignment and no declaration."
  (let* ((text (%assignments-text)) (sections (%assignment-sections text)))
    (dolist (id '("cc-2026-10-18-project-work-ctm" "cc-2026-10-19-topic-maps-reader-scaling" "cc-2026-10-19-acceptance-model-draft"
                  "cc-2026-10-20-ctm-exchange-review"))
      (check (format nil "preserved:the-assignment-~A-is-still-there" id) (assoc id sections :test #'equal)))
    (check "preserved:the-earlier-proposals-are-still-proposed"
           (every (lambda (n) (search (format nil "data-proposed-topic=\"pwc-wp-~D\"" n) text)) '(1 2 3 4 5 6 7 8)))
    (check "preserved:no-scope-id-is-a-data-topic-on-the-assignments-page"
           (notany (lambda (pair) (search (format nil "data-topic=\"~A\"" (car pair)) text)) (%scope-proposals text)))
    (check "preserved:no-work-status-is-given-to-the-scope"
           (notany (lambda (id) (search (format nil "data-topic=\"~A\"" id) (p::source-text (%item (p:read-project-sources) :work-breakdown))))
                   (mapcar #'car (%scope-proposals text))))))

(defun %synthetic-scope-records (package revision)
  "A records page of one SYNTHETIC record on PACKAGE. It exists in memory for a test only: no page of the repository states it."
  (format nil "<h1>SYNTHETIC Acceptance Records</h1><p>A test fixture. Nothing here was decided by anyone.</p><ul><li><a data-authority=\"synthetic-authority\">SYNTHETIC authority</a></li></ul>
<section data-acceptance-record=\"synthetic-scope-record-1\"><h3>SYNTHETIC synthetic-scope-record-1</h3>
<p data-field=\"work-package\" data-ref=\"~A\">SYNTHETIC.</p>
<p data-field=\"criterion\" data-ref=\"~A\" data-revision=\"~A\">SYNTHETIC: the criterion revision applied.</p>
<p data-field=\"decision\" data-decision=\"accepted\">SYNTHETIC decision, made by no one.</p>
<p data-field=\"decided-at\" data-datetime=\"2000-01-01T12:00:00Z\">SYNTHETIC.</p>
<p data-field=\"authority\" data-ref=\"synthetic-authority\">SYNTHETIC.</p>
<ul data-field=\"considered-evidence\"><li data-evidence=\"synthetic-scope-assignment/synthetic-scope-note\">SYNTHETIC: the note exists</li></ul></section>" package package revision))
(defun %scope-records-extra (package revision)
  (%extra :scope-records "Synthetic scope records" :acceptance-records "dreyeck/tests/fixtures/project-acceptance/synthetic-scope-records.html"
          (%synthetic-scope-records package revision)))
(defun %synthetic-scope-assignment ()
  "A SYNTHETIC assignment appended in memory to the text of the assignments page, with one note the SYNTHETIC record can consider."
  "<section data-assignment=\"synthetic-scope-assignment\"><h3>SYNTHETIC assignment</h3>
<p data-field=\"issued\">Not issued by anyone; a test fixture.</p><p data-field=\"goal\">SYNTHETIC goal.</p>
<p data-field=\"work-item\" data-ref=\"topic-maps-regular-hyperdoc\">SYNTHETIC.</p><p data-field=\"plan-step\">No Plan Step.</p>
<ul data-field=\"source-authorities\"><li>SYNTHETIC source authority</li></ul><ul data-field=\"preconditions\"><li>SYNTHETIC precondition</li></ul>
<ul data-field=\"acceptance-criteria\"><li>SYNTHETIC criterion</li></ul>
<ul data-field=\"evidence\"><li data-evidence=\"synthetic-scope-note\">SYNTHETIC: the note exists</li></ul>
<p data-field=\"observed-state\">SYNTHETIC. A report is not an acceptance.</p><p data-field=\"acceptance\">No acceptance by the user is recorded.</p></section>")
(defun %scope-sources (&rest extra)
  (p:read-project-sources :texts (list (cons :assignments (concatenate 'string (%assignments-text) (%synthetic-scope-assignment)))) :extra extra))
(defun %scope-refusal (&rest extra)
  (handler-case (progn (p:build-project-model (apply #'%scope-sources extra)) nil) (error (c) (or (princ-to-string c) "refused"))))

(defun scope-acceptance-tests ()
  "A record on a proposed package is refused; the records form fits the packages once they are declared (see the declaration patch)."
  (let* ((text (%project-page "Regular Catalog WBS Dictionary")) (entry (cdr (assoc "tm-reg-wp-1" (%dictionary-entries-by-id text) :test #'equal)))
         (revision (first (first (p:entry-revisions entry))))
         (draft (list :role :scope-draft :book "dreyeck/work/project" :title "Regular Catalog WBS Dictionary" :kind :proposed-dictionary
                      :path "dreyeck/pages/project/Regular Catalog WBS Dictionary.html" :text text)))
    (check "acceptance:the-draft-alone-builds" (null (%scope-refusal draft)))
    (check "acceptance:a-record-on-a-proposed-package-is-refused"
           (search "which is proposed, not declared; a proposed requirement cannot be accepted"
                   (or (%scope-refusal draft (%scope-records-extra "tm-reg-wp-1" revision)) "")))
    (check "acceptance:the-refusal-names-the-record-and-the-package"
           (let ((reason (or (%scope-refusal draft (%scope-records-extra "tm-reg-wp-1" revision)) "")))
             (and (search "synthetic-scope-record-1" reason) (search "tm-reg-wp-1" reason))))
    (check "acceptance:no-acceptance-record-is-in-the-repository"
           (let ((acceptance (p:model-acceptance (p:build-project-model)))) (or (null acceptance) (null (p:acceptance-records acceptance)))))))

(defun run-scope-tests ()
  "The proposed scope of Zettel 11359. Source pages and the retained CTM are compared before and after; nothing is written."
  (let ((*checks* 0) (before (%source-digests)) (ctm-before (%sha (p:project-ctm-pathname))))
    (scope-identity-tests)
    (scope-association-tests)
    (scope-relation-tests)
    (scope-dictionary-tests)
    (scope-model-tests)
    (scope-assignment-tests)
    (scope-preservation-tests)
    (scope-acceptance-tests)
    (check "preserved:source-pages-unchanged" (equal before (%source-digests)))
    (check "preserved:retained-ctm-unchanged" (equal ctm-before (%sha (p:project-ctm-pathname))))
    (format t "~&PROJECT-CTM-SCOPE-PASS: ~D checks; the scope is proposed, not declared; derived from the page text; nothing written~%" *checks*)
    *checks*))
