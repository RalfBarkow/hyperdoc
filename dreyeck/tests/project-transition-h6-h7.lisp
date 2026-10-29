;;;; A named, exact transition of the committed project CTM: Zettel 11359, H6 and H7
(in-package #:dreyeck/work/project/tests)

;; The preservation guard (preservation-differences, dreyeck/tests/project-ctm.lisp) compares the project CTM with the committed
;; revision and permits additions only. A correction that rewords two existing Topics and stops deriving two gaps is not an addition.
;; This file states that one correction as data, exactly, and checks it. It is not a general permission:
;;
;;  - it names its baseline commit and the SHA-256 of that commit's project CTM, and the SHA-256 of the one CTM it admits as the result;
;;    it applies only when the revision compared with is that baseline AND the CTM tested is that result. Any other revision, and any
;;    other CTM against that revision, is judged by the unchanged guard alone;
;;  - it removes from the guard's differences only the items it names, and reports a problem when a named item is absent, or when it
;;    has another content than the specification says;
;;  - what it admits must be verified in both directions: the removed gaps by their identity and roles in the baseline and by the
;;    reason they stopped being derived, the reworded Topics by their exact old and new lines, the relocated carriers by their exact
;;    old and new associations, and the replacement carrier page by its Topic and its HyperBook association;
;;  - everything the specification does not name stays under the unchanged guard.
;; Nothing here is derived from HEAD. After the correction is committed the transition no longer applies (the revision compared with
;; is then the result, not the baseline); the specification stays as the record of what that correction was allowed to change.

(defun %em-dash () (string (code-char 8212)))

(defun %transition-h6-h7 ()
  (let ((from-page (cons "dreyeck/work/project" "HyperDoc Project Workspace"))
        (to-page (cons "dreyeck/work/project" "Regular HyperDoc Catalog Scope Proposal")))
    (list :id "h6-h7-ebb44941"
          :baseline-commit "ebb44941b228cd5c3bb9434229b47ecb168444b4"
          :baseline-ctm-sha256 "346ae79206e291193e4e13a824a4d7c50fabd180a5328621e9ff4894cdd2b0f5"
          :result-ctm-sha256 "6a54569f9ddbf01ae00e33715d605c0e8ade54b3b6c6d81305d3e68ae519a8b5"
          ;; H7: two derived cross-pair gaps that came from two unrelated scopes sharing one carrier page, as (Work Item Deliverable)
          :gap-rule "work-item-deliverable-unlinked"
          :gap-rule-text "A Work Item and a Deliverable name the same carrier page, and no statement relates them. No Relation Contract defines that relation."
          :removed-gaps '(("project-work-ctm" "tm-regular-catalog") ("topic-maps-regular-hyperdoc" "project-work-ctm-exchange"))
          :retained-gap '("topic-maps-regular-hyperdoc" "tm-regular-catalog")
          ;; H6: Topic id, exact lines of its content in the baseline and in the result (the Topic content lines of %topic-content)
          :changed-topics
          (list (list "tm-reg-wp-1"
                      (list (%decl-line (format nil "1 Integrated Topic Maps Revision ~A the reviewed commit 6162ed68, its snapshot, manifest and pin, with the identity that HyperDoc checks." (%em-dash))))
                      (list (%decl-line (format nil "1 Integrated Topic Maps Revision ~A the reviewed Topic Maps revision 88994c1b (Task 1C, commit 6162ed68, and Task 1E), its snapshot, manifest and pin, with the identity that HyperDoc checks." (%em-dash)))))
                (list "tm-reg-p1"
                      (list (%decl-line (format nil "Integrate and verify Topic Maps 6162ed68 ~A fast-forward the Topic Maps line, pin the snapshot, verify it without .git and run the Topic Maps suite." (%em-dash)))
                            "name Integrate and verify Topic Maps 6162ed68")
                      (list (%decl-line (format nil "Integrate and verify Topic Maps 88994c1b ~A fast-forward the Topic Maps line, pin the snapshot, verify it without .git and run the Topic Maps suite." (%em-dash)))
                            "name Integrate and verify Topic Maps 88994c1b")))
          ;; H7: the carrier of these proposals moves from one page to another
          :relocation (list :from from-page :to to-page
                            :ids '("topic-maps-regular-hyperdoc" "tm-regular-catalog"
                                   "tm-reg-wp-1" "tm-reg-wp-2" "tm-reg-wp-3" "tm-reg-wp-4" "tm-reg-wp-5" "tm-reg-wp-6"
                                   "tm-reg-p1" "tm-reg-p2" "tm-reg-p3" "tm-reg-p4" "tm-reg-p5" "tm-reg-p6"
                                   "tm-reg-pre-admission" "tm-reg-pre-security-review" "tm-reg-pre-publish" "tm-reg-pre-production"))
          :hyperbook "dreyeck/work/project"
          ;; The model of the result, counted from its Topic Map: declarations (declared and proposed), statements, assignments, gaps
          :counts '(:declarations 73 :statements 79 :assignments 8 :gaps 45))))

(defun %decl-line (text)
  (format nil "occurrence ~A ~S ^^http://www.w3.org/2001/XMLSchema#string" (%o-schema "declaration-text") text))

(defparameter +preservation-transitions+ '(%transition-h6-h7 %transition-graph-a)
  "Functions returning the transition specifications the preservation guard knows. Each applies to exactly one revision pair.")

;;; Applicability: the revision compared with and the CTM tested are exactly the named ones

(defun %sha-of-text (text)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets text :external-format :utf-8))))
(defun %git-ctm-at (commit)
  (uiop:run-program (list "git" "-C" (namestring (asdf:system-source-directory "dreyeck")) "show"
                          (format nil "~A:dreyeck/work/project/hyperdoc-project.ctm" commit))
                    :output :string))

(defun transition-applicable-p (spec compared-text tested-text)
  "T when the revision compared with is the baseline of SPEC and the CTM tested is its result; else a keyword saying which is not.
The named commit's own project CTM must have the baseline digest, so the specification cannot drift from its commit."
  (cond ((not (equal (getf spec :baseline-ctm-sha256) (%sha-of-text (%git-ctm-at (getf spec :baseline-commit))))) :specification-differs-from-its-commit)
        ((not (equal (getf spec :baseline-ctm-sha256) (%sha-of-text compared-text))) :baseline-ctm-differs)
        ((not (equal (getf spec :result-ctm-sha256) (%sha-of-text tested-text))) :result-ctm-differs)
        (t t)))

(defun %applicable-transition (compared-text tested-text)
  (loop for name in +preservation-transitions+
        for spec = (funcall name)
        when (eq t (transition-applicable-p spec compared-text tested-text)) return spec))

;;; Facts about a Topic Map

(defun %signatures (map) (mapcar #'%association-signature (topic-maps.tmdm:topic-map-associations map)))
(defun %topic-by-si (map si) (find si (topic-maps.tmdm:topic-map-topics map) :key #'%si1 :test #'string=))
(defparameter +psi+ "http://psi.topicmaps.org/iso13250/model/")
(defun %kind-signature (id kind) (%o-signature +type-instance+ `((,(concatenate 'string +psi+ "instance") . ,(%o-work id))
                                                                  (,(concatenate 'string +psi+ "type") . ,(%o-schema kind)))))
(defun %gap-si (rule pair) (%o "gap" rule (format nil "~A/~A" (first pair) (second pair))))
(defun %gap-signatures (rule pair)
  "The three Associations that make a derived gap of a Work Item and a Deliverable: its type, and the two Topics it concerns."
  (let ((si (%gap-si rule pair)))
    (list (%o-signature +type-instance+ `((,(concatenate 'string +psi+ "instance") . ,si) (,(concatenate 'string +psi+ "type") . ,(%o-schema "plan-gap"))))
          (%o-signature (%o-schema "gap-concerns") `((,(%o-schema "gap") . ,si) (,(%o-schema "subject") . ,(%o-work (first pair)))))
          (%o-signature (%o-schema "gap-concerns") `((,(%o-schema "gap") . ,si) (,(%o-schema "subject") . ,(%o-work (second pair))))))))
(defun %carried-by-signature (id page) (%o-signature (%o-schema "carried-by") `((,(%o-schema "carried") . ,(%o-work id)) (,(%o-schema "carrier-page") . ,page))))
(defun %carriers (signatures id)
  "The pages that carry the Work Topic ID, from the signatures of a map."
  (let ((prefix (format nil "~A(~A: ~A, ~A: " (%o-schema "carried-by") (%o-schema "carried") (%o-work id) (%o-schema "carrier-page"))))
    (loop for s in signatures when (eql 0 (search prefix s)) collect (string-right-trim ")" (subseq s (length prefix))))))
(defun %count-in (signatures type needle)
  (count-if (lambda (s) (and (eql 0 (search (format nil "~A(" (%o-schema type)) s)) (search needle s))) signatures))
(defun %model-counts (map)
  "The size of the model a CTM states, counted from its Topic Map: declarations (declared or proposed), statements, assignments, gaps."
  (let ((s (%signatures map)))
    (list :declarations (+ (%count-in s "declared-on" (format nil "~A: ~A" (%o-schema "declaration") (%o "work/topic/")))
                           (%count-in s "proposed-on" (format nil "~A: ~A" (%o-schema "proposal") (%o "work/topic/"))))
          :statements (+ (%count-in s "stated-on" (format nil "~A: ~A" (%o-schema "statement") (%o "statement/")))
                         (%count-in s "proposed-on" (format nil "~A: ~A" (%o-schema "proposal") (%o "statement/"))))
          :assignments (%count-in s "declared-on" (format nil "~A: ~A" (%o-schema "declaration") (%o "assignment/")))
          :gaps (count-if (lambda (tp) (eql 0 (search (%o "gap/") (%si1 tp)))) (topic-maps.tmdm:topic-map-topics map)))))

;;; The transition applied to the guard's differences

(defun apply-transition (spec old new differences)
  "(values RESIDUAL PROBLEMS): DIFFERENCES, the result of preservation-differences of OLD (the baseline) and NEW, without exactly the items SPEC
names, and the problems found in what SPEC names. Nothing is removed unless it is verified; the residual must still be empty to pass."
  (let ((problems nil) (residual (copy-list differences))
        (old-sigs (%signatures old)) (new-sigs (%signatures new)) (rule (getf spec :gap-rule)))
    (labels ((problem (kind &rest detail) (push (cons kind detail) problems))
             (drop (key items &key (test #'equal) multiset)
               (setf (getf residual key) (if multiset (%multiset-minus (getf residual key) items) (remove-if (lambda (x) (member x items :test test)) (getf residual key))))))
      ;; H7, the removed gaps: identity and roles in the baseline, the reason in the result, and exactly the Topics and Associations of each
      (let ((lost-topics nil) (lost-associations nil))
        (dolist (pair (getf spec :removed-gaps))
          (let* ((si (%gap-si rule pair)) (expected (%gap-signatures rule pair)) (topic (%topic-by-si old si)))
            (cond ((null topic) (problem :removed-gap-not-in-the-baseline si))
                  (t (unless (find-if (lambda (line) (and (search (%o-schema "gap-rule") line) (search (getf spec :gap-rule-text) line))) (%topic-content topic))
                       (problem :removed-gap-has-another-rule si))
                     (unless (equal (sort (copy-list expected) #'string<) (sort (remove-if-not (lambda (s) (search si s)) (copy-list old-sigs)) #'string<))
                       (problem :removed-gap-has-other-associations-in-the-baseline si))
                     (unless (member (%kind-signature (first pair) "kind-work-item") old-sigs :test #'string=) (problem :gap-subject-is-no-work-item (first pair)))
                     (unless (member (%kind-signature (second pair) "kind-deliverable") old-sigs :test #'string=) (problem :gap-subject-is-no-deliverable (second pair)))))
            ;; why it stopped being derived: the two no longer name the same carrier page in the result
            (let ((a (%carriers new-sigs (first pair))) (b (%carriers new-sigs (second pair))))
              (when (or (null a) (null b) (intersection a b :test #'string=)) (problem :removed-gap-subjects-still-share-a-carrier pair)))
            (when (%topic-by-si new si) (problem :removed-gap-still-in-the-result si))
            (if (member si (getf differences :lost-topics) :test #'string=) (push si lost-topics) (problem :expected-removal-absent si))
            (dolist (sig expected)
              (if (member sig (getf differences :lost-associations) :test #'string=) (push sig lost-associations) (problem :expected-lost-association-absent sig)))))
        (drop :lost-topics lost-topics :test #'string=)
        (drop :lost-associations lost-associations :multiset t))
      ;; The gap that is legitimate stays, with all three of its Associations
      (let ((keep (getf spec :retained-gap)))
        (unless (and (%topic-by-si new (%gap-si rule keep)) (every (lambda (sig) (member sig new-sigs :test #'string=)) (%gap-signatures rule keep)))
          (problem :legitimate-gap-missing keep)))
      ;; H6: each reworded Topic changes by exactly the old and the new lines, and by nothing else
      (dolist (change (getf spec :changed-topics))
        (destructuring-bind (id old-lines new-lines) change
          (let* ((si (%o-work id)) (o (%topic-by-si old si)) (n (%topic-by-si new si)))
            (cond ((or (null o) (null n)) (problem :h6-topic-missing id))
                  ((not (member si (getf differences :changed-topics) :test #'string=)) (problem :h6-change-absent id))
                  ((and (equal (sort (copy-list old-lines) #'string<) (sort (set-difference (%topic-content o) (%topic-content n) :test #'string=) #'string<))
                        (equal (sort (copy-list new-lines) #'string<) (sort (set-difference (%topic-content n) (%topic-content o) :test #'string=) #'string<)))
                   (drop :changed-topics (list si) :test #'string=))
                  (t (problem :h6-change-unauthorized id))))))
      ;; H7: the carrier of exactly these proposals moves from one page to the other; the replacements are verified, not only the removals
      (let* ((reloc (getf spec :relocation))
             (from (%o-page (car (getf reloc :from)) (cdr (getf reloc :from)))) (to (%o-page (car (getf reloc :to)) (cdr (getf reloc :to))))
             (ids (getf reloc :ids)) (expected-removed nil) (expected-added nil))
        (dolist (id ids)
          (let ((was (%carried-by-signature id from)) (is (%carried-by-signature id to)))
            (cond ((not (member was old-sigs :test #'string=)) (problem :relocation-baseline-differs id))
                  ((member is new-sigs :test #'string=) (push was expected-removed) (push is expected-added))
                  ((member was new-sigs :test #'string=) (problem :relocation-absent id))
                  (t (problem :relocation-wrong-target id (%carriers new-sigs id))))))
        (let* ((cb (lambda (sigs) (remove-if-not (lambda (s) (eql 0 (search (format nil "~A(" (%o-schema "carried-by")) s))) sigs)))
               (removed (%multiset-minus (funcall cb old-sigs) (funcall cb new-sigs))) (added (%multiset-minus (funcall cb new-sigs) (funcall cb old-sigs))))
          (when (or (%multiset-minus removed expected-removed) (%multiset-minus added expected-added))
            (problem :carried-by-delta-has-extras (list (%multiset-minus removed expected-removed) (%multiset-minus added expected-added)))))
        ;; the replacement carrier page is a Topic of its HyperBook, and nothing else about it is stated
        (unless (and (%topic-by-si new to)
                     (member (%o-signature (%o-schema "contains-page") `((,(%o-schema "hyperbook-role") . ,(%o "hyperbook" (getf spec :hyperbook))) (,(%o-schema "page") . ,to)))
                             new-sigs :test #'string=))
          (problem :carrier-page-missing to)))
      ;; The model of the result is the size the specification says
      (let ((counts (%model-counts new)))
        (unless (equal counts (getf spec :counts)) (problem :model-counts-differ counts)))
      (values residual (nreverse problems)))))

(defun %empty-residual-p (residual)
  (loop for (nil value) on residual by #'cddr never value))


;;; The transition tested: positive and negative controls. Each negative control must fail for its own preservation reason.

(defun %replace-once (text old new)
  (let ((at (search old text)))
    (assert (and at (null (search old text :start2 (1+ at)))) () "~S occurs ~D times" (subseq old 0 (min 60 (length old))) (count-if (constantly t) (loop for s = (search old text) then (search old text :start2 (1+ s)) while s collect s)))
    (concatenate 'string (subseq text 0 at) new (subseq text (+ at (length old))))))
(defun %text-lines (text) (uiop:split-string text :separator '(#\Newline)))
(defun %join-lines (lines) (format nil "~{~A~^~%~}" lines))
(defun %drop-topic-and-associations (text iri)
  "TEXT without the Topic block of the Topic whose subject identifier is IRI and without every line that names it."
  (let* ((lines (%text-lines text)) (head (format nil "<~A>" iri)) (start (position head lines :test #'string=)))
    (assert start () "no block for ~A" iri)
    (let ((end (position-if (lambda (l) (and (>= (length l) 2) (string= " ." l :start2 (- (length l) 2)))) lines :start start)))
      (%join-lines (loop for l in lines for i from 0
                         unless (or (<= start i end) (and (> i end) (search iri l))) collect l)))))
(defun %drop-first-line-starting (text prefix)
  (let* ((lines (%text-lines text)) (at (position-if (lambda (l) (eql 0 (search prefix l))) lines)))
    (assert at () "no line starting ~A" prefix)
    (%join-lines (append (subseq lines 0 at) (subseq lines (1+ at))))))

(defun %first-gap-iri-not-in (text spec)
  "The subject identifier of a gap Topic of TEXT that the transition does not name."
  (let ((named (append (mapcar (lambda (p) (%gap-si (getf spec :gap-rule) p)) (getf spec :removed-gaps))
                       (list (%gap-si (getf spec :gap-rule) (getf spec :retained-gap))))))
    (loop for line in (%text-lines text)
          for iri = (and (eql 0 (search "<tag:dreyeck.ch,2026:hyperdoc/gap/" line)) (string-trim "<>" line))
          when (and iri (not (member iri named :test #'string=))) return iri)))

(defun run-transition-tests ()
  "The exact transition of Zettel 11359 H6/H7, with controls. It runs only while the working project CTM is the transition's result."
  (let* ((spec (%transition-h6-h7)) (*checks* 0)
         (working (uiop:read-file-string (p:project-ctm-pathname) :external-format :utf-8)))
    (unless (equal (getf spec :result-ctm-sha256) (%sha-of-text working))
      (format t "~&PROJECT-CTM-TRANSITION-NOT-RUN: the working project CTM is not the result of ~A (SHA-256 ~A); this is not a pass~%"
              (getf spec :id) (getf spec :result-ctm-sha256))
      (return-from run-transition-tests 0))
    (let* ((items (p:sources-items (p:read-project-sources)))
           (old-text (%git-ctm-at (getf spec :baseline-commit)))   ; the named commit, never HEAD
           (old (%read-ctm old-text "baseline")) (new (%read-ctm working "result"))
           (differences (preservation-differences old new items)))
      ;; The specification, its commit and the tested CTM
      (check "transition:the-specification-agrees-with-its-commit" (equal (getf spec :baseline-ctm-sha256) (%sha-of-text old-text)))
      (check "transition:applies-to-the-named-baseline-and-the-named-result" (eq t (transition-applicable-p spec old-text working)))
      ;; What the unchanged guard says about this correction: exactly the named items, nothing else
      (check "transition:the-unchanged-guard-reports-exactly-the-two-gaps-as-lost-topics"
             (equal (sort (copy-list (getf differences :lost-topics)) #'string<)
                    (sort (mapcar (lambda (p) (%gap-si (getf spec :gap-rule) p)) (getf spec :removed-gaps)) #'string<)))
      (check "transition:the-unchanged-guard-reports-exactly-their-six-associations"
             (and (= 6 (length (getf differences :lost-associations)))
                  (null (%multiset-minus (getf differences :lost-associations)
                                         (loop for p in (getf spec :removed-gaps) append (%gap-signatures (getf spec :gap-rule) p))))))
      (check "transition:the-unchanged-guard-reports-exactly-the-two-reworded-topics"
             (equal (sort (copy-list (getf differences :changed-topics)) #'string<)
                    (sort (mapcar (lambda (c) (%o-work (first c))) (getf spec :changed-topics)) #'string<)))
      (check "transition:the-unchanged-guard-reports-no-unattributed-addition" (null (getf differences :unattributed-additions)))
      (check "transition:the-18-relocated-carriers-are-no-loss-to-the-guard-but-an-exact-delta-here"
             (let* ((cb (lambda (m) (remove-if-not (lambda (s) (eql 0 (search (format nil "~A(" (%o-schema "carried-by")) s))) (%signatures m))))
                    (ids (getf (getf spec :relocation) :ids)))
               (and (= 18 (length ids))
                    (= 18 (length (%multiset-minus (funcall cb old) (funcall cb new))))
                    (= 18 (length (%multiset-minus (funcall cb new) (funcall cb old)))))))
      ;; Positive: the transition admits exactly this correction
      (multiple-value-bind (residual problems) (apply-transition spec old new differences)
        (check "transition:positive:no-problem-in-what-the-specification-names" (null problems))
        (check "transition:positive:nothing-remains-for-the-unchanged-guard" (%empty-residual-p residual)))
      (check "transition:positive:the-result-has-the-size-the-specification-says" (equal (getf spec :counts) (%model-counts new)))
      (check "transition:positive:the-model-of-the-sources-agrees-with-the-counts"
             (let ((model (p:build-project-model)))
               (equal (list :declarations (length (p:model-declarations model)) :statements (length (p:model-statements model))
                            :assignments (length (p:model-assignments model)) :gaps (length (p:model-gaps model)))
                      (getf spec :counts))))
      (check "transition:positive:the-legitimate-work-item-deliverable-gap-remains"
             (%topic-by-si new (%gap-si (getf spec :gap-rule) (getf spec :retained-gap))))
      (check "transition:positive:the-new-carrier-page-is-a-topic-of-its-hyperbook"
             (let ((to (%o-page (car (getf (getf spec :relocation) :to)) (cdr (getf (getf spec :relocation) :to)))))
               (and (%topic-by-si new to) (not (%topic-by-si old to)))))
      ;; Negative controls. Each mutates the result CTM text; the transition is applied directly, so that the check is the one under test
      ;; (the exact result digest would reject every mutant on its own, which is the second line, tested after them).
      (flet ((evaluate (mutant-text &optional (baseline old))
               (let* ((mutant (%read-ctm mutant-text "mutant")) (d (preservation-differences baseline mutant items)))
                 (multiple-value-list (apply-transition spec baseline mutant d))))
             (kinds (problems) (mapcar #'car problems)))
        (let ((wp1 (first (getf spec :changed-topics))) (relocation (getf spec :relocation)))
          ;; N1 an additional, unrelated Topic disappears
          (let* ((iri (%first-gap-iri-not-in working spec)) (result (evaluate (%drop-topic-and-associations working iri))))
            (check "transition:negative:an-unrelated-topic-disappears" (and iri (member iri (getf (first result) :lost-topics) :test #'string=)))
            (check "transition:negative:that-is-left-to-the-unchanged-guard-not-excused" (not (%empty-residual-p (first result)))))
          ;; N2 an unrelated Association disappears
          (let ((result (evaluate (%drop-first-line-starting working "s:reads-source("))))
            (check "transition:negative:an-unrelated-association-disappears" (getf (first result) :lost-associations))
            (check "transition:negative:the-lost-association-is-none-of-the-six-that-are-named"
                   (null (intersection (getf (first result) :lost-associations)
                                       (loop for p in (getf spec :removed-gaps) append (%gap-signatures (getf spec :gap-rule) p))
                                       :test #'string=))))
          ;; N3 a permitted Topic changes in an unauthorized way
          (let* ((new-line (first (third wp1))) (text (let ((s (subseq new-line (1+ (position #\" new-line)) (position #\" new-line :from-end t :end (position #\^ new-line)))))
                                                          (%replace-once working s (concatenate 'string s " (and one more thing)"))))
                 (result (evaluate text)))
            (check "transition:negative:a-permitted-topic-changes-otherwise" (member :h6-change-unauthorized (kinds (second result))))
            (check "transition:negative:that-change-stays-with-the-unchanged-guard" (member (%o-work (first wp1)) (getf (first result) :changed-topics) :test #'string=)))
          ;; N4 a required H6 change is absent
          (let* ((new-line (first (third wp1)))
                 (new-text (subseq new-line (1+ (position #\" new-line)) (position #\" new-line :from-end t :end (position #\^ new-line))))
                 (old-line (first (second wp1)))
                 (old-text* (subseq old-line (1+ (position #\" old-line)) (position #\" old-line :from-end t :end (position #\^ old-line))))
                 (result (evaluate (%replace-once working new-text old-text*))))
            (check "transition:negative:a-required-h6-change-is-absent" (member :h6-change-absent (kinds (second result)))))
          ;; N5 a required H7 relocation is absent: one proposal is still carried by the old page
          (let* ((id "tm-reg-wp-3") (from (%o-page (car (getf relocation :from)) (cdr (getf relocation :from)))) (to (%o-page (car (getf relocation :to)) (cdr (getf relocation :to))))
                 (result (evaluate (%replace-once working (format nil "s:carried-by(s:carried: w:~A, s:carrier-page: <~A>)" id to)
                                                  (format nil "s:carried-by(s:carried: w:~A, s:carrier-page: <~A>)" id from)))))
            (check "transition:negative:a-required-h7-relocation-is-absent" (member :relocation-absent (kinds (second result)))))
          ;; N6 the new carrier relation is wrong: another page carries the proposal
          (let* ((id "tm-reg-p2") (to (%o-page (car (getf relocation :to)) (cdr (getf relocation :to)))) (other (%o-page "dreyeck/work/project" "Implementation Assignments"))
                 (result (evaluate (%replace-once working (format nil "s:carried-by(s:carried: w:~A, s:carrier-page: <~A>)" id to)
                                                  (format nil "s:carried-by(s:carried: w:~A, s:carrier-page: <~A>)" id other)))))
            (check "transition:negative:a-new-carrier-relation-is-wrong" (member :relocation-wrong-target (kinds (second result)))))
          ;; N7 a relocation beyond the 18: an unrelated proposal moves to the new page too
          (let* ((id "project-work-ctm") (from (%o-page (car (getf relocation :from)) (cdr (getf relocation :from)))) (to (%o-page (car (getf relocation :to)) (cdr (getf relocation :to))))
                 (result (evaluate (%replace-once working (format nil "s:carried-by(s:carried: w:~A, s:carrier-page: <~A>)" id from)
                                                  (format nil "s:carried-by(s:carried: w:~A, s:carrier-page: <~A>)" id to)))))
            (check "transition:negative:a-further-relocation-is-not-admitted" (member :carried-by-delta-has-extras (kinds (second result)))))
          ;; N8 the replacement carrier page is not a Topic of its HyperBook
          (let ((result (evaluate (%drop-first-line-starting working (format nil "s:contains-page(s:hyperbook-role: <~A>, s:page: <~A>)"
                                                                           (%o "hyperbook" (getf spec :hyperbook))
                                                                           (%o-page (car (getf relocation :to)) (cdr (getf relocation :to))))))))
            (check "transition:negative:the-carrier-page-is-not-in-its-hyperbook" (member :carrier-page-missing (kinds (second result)))))))
      ;; Second line: another CTM than the named result, or another revision compared with, is not covered at all
      (check "transition:negative:another-result-ctm-is-not-covered"
             (eq :result-ctm-differs (transition-applicable-p spec old-text (concatenate 'string working (string #\Newline) "# another CTM"))))
      (check "transition:negative:an-unrelated-source-revision-is-not-covered"
             (eq :baseline-ctm-differs (transition-applicable-p spec (%git-ctm-at +baseline-commit+) working)))
      (check "transition:negative:applied-to-an-unrelated-revision-nothing-is-excused"
             (let* ((other (%read-ctm (%git-ctm-at +baseline-commit+) "unrelated revision"))
                    (d (preservation-differences other new items)))
               (multiple-value-bind (residual problems) (apply-transition spec other new d)
                 (declare (ignore residual))
                 (and problems (member :removed-gap-not-in-the-baseline (mapcar #'car problems))))))
      (format t "~&PROJECT-CTM-TRANSITION-PASS: ~D checks; the transition ~A is exact: its baseline ~A, its result CTM ~A, nothing else excused~%"
              *checks* (getf spec :id) (subseq (getf spec :baseline-commit) 0 8) (subseq (getf spec :result-ctm-sha256) 0 8))
      *checks*)))
