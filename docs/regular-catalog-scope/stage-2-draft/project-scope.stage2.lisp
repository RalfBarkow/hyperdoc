;;;; The scope Regular HyperDoc Catalog with a Navigable Project Topic Map (Zettel 11359), declared and not accepted
(in-package #:dreyeck/work/project/tests)

;; Every expectation here is derived from the pages: the Work item on the Work Breakdown, the Deliverable, work packages, plan steps and
;; preconditions on the page Regular HyperDoc Catalog, the Regular HyperDoc Catalog WBS Dictionary, the assignments, and the real
;; emitter. No Catalog-wide item count is written down. The scope's own IDs are topic-maps-regular-hyperdoc, tm-regular-catalog and
;; every ID that starts with tm-reg-.

(defparameter +scope-work-item+ "topic-maps-regular-hyperdoc")
(defparameter +scope-deliverable+ "tm-regular-catalog")
(defparameter +scope-relations+ '("work:relation/decomposes-into" "work:relation/produces" "work:relation/depends-on"))

(defun %scope-id-p (id)
  (or (equal id +scope-work-item+) (equal id +scope-deliverable+) (eql 0 (search "tm-reg-" id))))
(defun %assignments-text () (%project-page "Implementation Assignments"))
(defun %work-page (title)
  (uiop:read-file-string (asdf:system-relative-pathname "dreyeck" (format nil "dreyeck/pages/work/~A.html" title)) :external-format :utf-8))
(defun %scope-topics ()
  "((id . kind) ...) of the declared scope, in page order: the Work item on the Work Breakdown, the rest on the page Regular HyperDoc Catalog."
  (loop for text in (list (%work-page "Work Breakdown") (%work-page "Regular HyperDoc Catalog"))
        append (loop for node in (%with "a" "data-topic" text)
                     for id = (plump:attribute node "data-topic")
                     when (and (%scope-id-p id) (not (equal "relation" (plump:attribute node "data-kind"))))
                       collect (cons id (plump:attribute node "data-kind")))))
(defun %scope-statements ()
  "((from relation to) ...) of the statements of the page Regular HyperDoc Catalog, in page order."
  (loop for node in (%with "li" "data-from" (%work-page "Regular HyperDoc Catalog"))
        collect (list (plump:attribute node "data-from") (plump:attribute node "data-relation") (plump:attribute node "data-to"))))
(defun %scope-statuses ()
  (loop for text in (list (%work-page "Work Breakdown") (%work-page "Regular HyperDoc Catalog"))
        append (loop for node in (%with "a" "data-topic" text)
                     when (%scope-id-p (plump:attribute node "data-topic"))
                       collect (cons (plump:attribute node "data-topic") (plump:attribute node "data-status")))))
(defun %ids-of-kind (topics kind) (loop for (id . k) in topics when (equal k kind) collect id))
(defun %duplicates (list &key (test #'equal))
  (loop for (x . more) on list when (member x more :test test) collect x))
(defun %kind-of (topics id) (cdr (assoc id topics :test #'equal)))

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
  (let* ((topics (%scope-topics)) (ids (mapcar #'car topics)) (text (%assignments-text))
         (still-proposed (loop for node in (%with "a" "data-proposed-topic" text)
                               for id = (plump:attribute node "data-proposed-topic") when (%scope-id-p id) collect id))
         (model (p:build-project-model))
         (declared (loop for d in (p:model-declarations model) unless (p::declaration-proposal-p d) collect (cons (p:declaration-id d) (p:declaration-status d)))))
    (check "scope:has-ids" ids)
    (check "scope:each-id-is-declared-once" (null (%duplicates ids)))
    (check "scope:no-id-remains-proposed" (null still-proposed))
    (check "scope:no-proposal-of-the-scope-is-read" (notany (lambda (d) (and (p::declaration-proposal-p d) (%scope-id-p (p:declaration-id d)))) (p:model-declarations model)))
    (check "scope:every-id-is-declared-once-by-the-model-with-the-status-open"
           (every (lambda (id) (let ((all (remove id declared :key #'car :test-not #'equal)))
                                 (and (= 1 (length all)) (equal "open" (cdr (first all))))))
                  ids))
    (check "scope:the-model-declares-no-other-scope-id"
           (null (set-difference (remove-if-not #'%scope-id-p (mapcar #'car declared)) ids :test #'equal)))
    (check "scope:the-work-item-is-declared-on-the-work-breakdown"
           (search (format nil "data-topic=\"~A\"" +scope-work-item+) (p::source-text (%item (p:read-project-sources) :work-breakdown))))
    (check "scope:every-status-of-the-scope-is-open" (every (lambda (pair) (equal "open" (cdr pair))) (%scope-statuses)))
    (check "scope:exactly-one-work-item" (equal (list +scope-work-item+) (%ids-of-kind topics "work item")))
    (check "scope:exactly-one-deliverable" (equal (list +scope-deliverable+) (%ids-of-kind topics "deliverable")))
    (check "scope:work-packages-follow-the-naming" (every (lambda (id) (eql 0 (search "tm-reg-wp-" id))) (%ids-of-kind topics "work package")))
    (check "scope:plan-steps-follow-the-naming" (every (lambda (id) (eql 0 (search "tm-reg-p" id))) (%ids-of-kind topics "plan step")))
    (check "scope:preconditions-follow-the-naming" (every (lambda (id) (eql 0 (search "tm-reg-pre-" id))) (%ids-of-kind topics "precondition")))
    (check "scope:every-topic-has-a-known-kind"
           (every (lambda (kind) (member kind '("work item" "deliverable" "work package" "plan step" "precondition") :test #'equal))
                  (mapcar #'cdr topics)))
    (check "scope:one-plan-step-for-each-work-package"
           (= (length (%ids-of-kind topics "work package")) (length (%ids-of-kind topics "plan step"))))))

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
  (let* ((topics (%scope-topics)) (statements (%scope-statements))
         (packages (%ids-of-kind topics "work package")) (steps (%ids-of-kind topics "plan step")))
    (check "relations:the-scope-has-statements" statements)
    (check "relations:only-the-three-relation-words" (every (lambda (s) (member (second s) +scope-relations+ :test #'equal)) statements))
    (check "relations:closed-over-the-scope" (every (lambda (s) (and (%kind-of topics (first s)) (%kind-of topics (third s)))) statements))
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
             (every (lambda (s) (and (equal "plan step" (%kind-of topics (first s))) (equal "work package" (%kind-of topics (third s))))) produces))
      (check "relations:each-work-package-has-one-producer"
             (equal (sort (mapcar #'third produces) #'string<) (sort (copy-list packages) #'string<)))
      (check "relations:each-plan-step-produces-one-package"
             (equal (sort (mapcar #'first produces) #'string<) (sort (copy-list steps) #'string<)))
      ;; Execution dependencies: a plan step waits for another step or a precondition, never for a work package
      (check "relations:dependencies-lead-from-plan-steps"
             (every (lambda (s) (equal "plan step" (%kind-of topics (first s)))) depends))
      (check "relations:dependencies-wait-for-steps-or-preconditions"
             (every (lambda (s) (member (%kind-of topics (third s)) '("plan step" "precondition") :test #'equal)) depends))
      (check "relations:no-dependency-of-a-step-on-itself" (notany (lambda (s) (equal (first s) (third s))) depends))
      (check "relations:dependencies-are-acyclic" (%acyclic-p (mapcar (lambda (s) (cons (first s) (third s))) depends)))
      (check "relations:every-precondition-is-waited-for"
             (every (lambda (id) (find id depends :key #'third :test #'equal)) (%ids-of-kind topics "precondition")))
      ;; The three families are distinct: no pair of topics is in two of them, and the WBS has no execution order
      (check "relations:families-are-distinct"
             (null (intersection (mapcar (lambda (s) (list (first s) (third s))) decomposes)
                                 (append (mapcar (lambda (s) (list (first s) (third s))) produces)
                                         (mapcar (lambda (s) (list (first s) (third s))) depends))
                                 :test #'equal)))
      (check "relations:no-dependency-between-work-packages"
             (notany (lambda (s) (or (member (first s) packages :test #'equal) (member (third s) packages :test #'equal))) depends))
      ;; No relation contract between a Work Item and a Deliverable exists: none is invented
      (check "relations:the-work-item-has-no-statement"
             (notany (lambda (s) (member +scope-work-item+ (list (first s) (third s)) :test #'equal)) statements)))))

(defun %dictionary-entries-by-id (text)
  (mapcar (lambda (entry) (cons (dreyeck/work/ctm-page-authoring::entry-element-id entry) entry))
          (dreyeck/work/ctm-page-authoring::read-wbs-dictionary text)))

(defun scope-dictionary-tests ()
  (let* ((text (%work-page "Regular HyperDoc Catalog WBS Dictionary")) (topics (%scope-topics))
         (packages (%ids-of-kind topics "work package")) (entries (%dictionary-entries-by-id text))
         (root (asdf:system-source-directory "dreyeck")))
    (check "dictionary:has-entries" entries)
    (check "dictionary:one-entry-for-each-work-package"
           (equal (sort (mapcar #'car entries) #'string<) (sort (copy-list packages) #'string<)))
    (check "dictionary:no-package-has-two-entries" (null (%duplicates (mapcar #'car entries))))
    (check "dictionary:the-other-dictionaries-have-no-entry-for-a-scope-package"
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
    ;; Planned controls are stated, never counted as coverage
    (check "dictionary:some-control-is-planned"
           (loop for (nil . entry) in entries
                 thereis (find "planned" (dreyeck/work/ctm-page-authoring::entry-controls entry) :test #'equal
                                                                                                    :key (lambda (c) (string-downcase (princ-to-string (dreyeck/work/ctm-page-authoring::control-coverage c)))))))))

(defun scope-model-tests ()
  "The scope as the emitter reads it: the carrier page and the dictionary are sources, the proposals are retired."
  (let* ((topics (%scope-topics)) (packages (%ids-of-kind topics "work package")) (ids (mapcar #'car topics))
         (text (p:materialize-project-ctm)) (model (p:build-project-model))
         (dictionary "dreyeck/pages/work/Regular HyperDoc Catalog WBS Dictionary.html")
         (carrier "dreyeck/pages/work/Regular HyperDoc Catalog.html"))
    (check "model:the-dictionary-is-a-source-of-the-project-ctm"
           (find dictionary (p:sources-items (p:read-project-sources)) :key #'p:source-path :test #'equal))
    (check "model:the-carrier-page-is-a-source-of-the-project-ctm"
           (find carrier (p:sources-items (p:read-project-sources)) :key #'p:source-path :test #'equal))
    (check "model:the-declared-dictionary-describes-every-work-package-once"
           (equal (sort (loop for (entry . item) in (p::model-declared-entries model) when (equal dictionary (p:source-path item))
                              collect (dreyeck/work/ctm-page-authoring::entry-element-id entry))
                        #'string<)
                  (sort (copy-list packages) #'string<)))
    (check "model:no-draft-dictionary-entry-is-read" (null (p:model-proposed-entries model)))
    (dolist (id ids)
      (check (format nil "model:~A-is-declared-and-not-proposed" id)
             (and (search (format nil "s:declared-on(s:declaration: w:~A," id) text)
                  (not (search (format nil "s:proposed-on(s:proposal: w:~A," id) text))
                  (not (search (format nil "gap/proposal-already-declared/~A>" id) text)))))
    (dolist (id packages)
      (check (format nil "model:~A-is-defined-in-the-dictionary" id)
             (search (format nil "s:defined-in-dictionary(s:work-package: w:~A," id) text))
      (check (format nil "model:~A-has-no-acceptance-record" id)
             (search (format nil "~A: acceptance criterion without an acceptance record" id) text)))
    (check "model:the-declaration-adds-no-acceptance-record"
           (let ((acceptance (p:model-acceptance model))) (or (null acceptance) (null (p:acceptance-records acceptance)))))))

(defun %assignment-sections (text)
  (loop for node in (%with "section" "data-assignment" text) collect (cons (plump:attribute node "data-assignment") node)))
(defun %section-field (section name)
  (loop for child across (plump:children section)
        when (and (plump:element-p child) (equal name (plump:attribute child "data-field"))) return child
        do (when (plump:element-p child) (let ((found (%section-field child name))) (when found (return found))))))
(defun %text-of (node) (if node (plump:text node) ""))

(defun scope-assignment-tests ()
  (let* ((text (%assignments-text)) (topics (%scope-topics)) (packages (%ids-of-kind topics "work package"))
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
        (check (format nil "assignments:~A-no-longer-calls-the-work-item-proposed" id)
               (not (search "proposed Work Item" (%text-of (%section-field section "work-item")))))
        (when delivers
          (check (format nil "assignments:~A-delivers-a-declared-package-of-the-scope" id)
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
             (notany (lambda (id) (some (lambda (commit) (search (subseq commit 0 8) id)) commits)) (mapcar #'car topics))))
    ;; The productive page keeps its evidence as notes; identified evidence entries are for the user to introduce (see the acceptance tests).
    (check "assignments:the-scope-assignments-state-their-evidence"
           (every (lambda (pair) (plusp (length (plump:get-elements-by-tag-name (%section-field (cdr pair) "evidence") "li")))) scope-sections))
    (check "assignments:the-scope-assignments-keep-evidence-as-notes" (null (%with "li" "data-evidence" text)))
    (let ((model (p:build-project-model)))
      (check "assignments:no-acceptance-record-exists"
             (let ((acceptance (p:model-acceptance model))) (or (null acceptance) (null (p:acceptance-records acceptance))))))))

(defun scope-preservation-tests ()
  "The declaration changes no earlier assignment and keeps the earlier proposals."
  (let* ((text (%assignments-text)) (sections (%assignment-sections text)))
    (dolist (id '("cc-2026-10-18-project-work-ctm" "cc-2026-10-19-topic-maps-reader-scaling" "cc-2026-10-19-acceptance-model-draft"
                  "cc-2026-10-20-ctm-exchange-review"))
      (check (format nil "preserved:the-assignment-~A-is-still-there" id) (assoc id sections :test #'equal)))
    (check "preserved:the-earlier-proposals-are-still-proposed"
           (every (lambda (n) (search (format nil "data-proposed-topic=\"pwc-wp-~D\"" n) text)) '(1 2 3 4 5 6 7 8)))
    (check "preserved:no-scope-id-is-a-data-topic-on-the-assignments-page-or-the-plan-page"
           (let ((plan (p::source-text (%item (p:read-project-sources) :plan))))
             (notany (lambda (pair) (or (search (format nil "data-topic=\"~A\"" (car pair)) text)
                                        (search (format nil "data-topic=\"~A\"" (car pair)) plan)))
                     (%scope-topics))))))

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
  "The records form fits the declared packages: a SYNTHETIC record in memory is read, a wrong criterion revision is refused."
  (let* ((entry (cdr (assoc "tm-reg-wp-1" (%dictionary-entries-by-id (%work-page "Regular HyperDoc Catalog WBS Dictionary")) :test #'equal)))
         (revision (first (first (p:entry-revisions entry)))))
    (check "acceptance:a-synthetic-record-on-a-declared-package-is-read"
           (null (%scope-refusal (%scope-records-extra "tm-reg-wp-1" revision))))
    (check "acceptance:the-record-is-in-the-model-for-the-package"
           (let* ((model (p:build-project-model (%scope-sources (%scope-records-extra "tm-reg-wp-1" revision))))
                  (records (p:acceptance-records (p:model-acceptance model))))
             (and (= 1 (length records)) (equal "tm-reg-wp-1" (p:record-package (first records))))))
    (check "acceptance:a-record-with-another-revision-is-refused"
           (search "neither states nor retains" (or (%scope-refusal (%scope-records-extra "tm-reg-wp-1" "sha256-0000000000000000000000000000000000000000000000000000000000000000")) "")))
    (check "acceptance:a-record-on-an-undeclared-package-is-refused"
           (search "which no page declares" (or (%scope-refusal (%scope-records-extra "tm-reg-wp-99" revision)) "")))
    (check "acceptance:no-acceptance-record-is-in-the-repository"
           (let ((acceptance (p:model-acceptance (p:build-project-model)))) (or (null acceptance) (null (p:acceptance-records acceptance)))))))

(defun run-scope-tests ()
  "The declared scope of Zettel 11359. Source pages and the retained CTM are compared before and after; nothing is written."
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
    (format t "~&PROJECT-CTM-SCOPE-PASS: ~D checks; the scope is declared open, its proposals retired; no acceptance; derived from the page text; nothing written~%" *checks*)
    *checks*))
