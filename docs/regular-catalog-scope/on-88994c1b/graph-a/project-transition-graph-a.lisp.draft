;;;; A named, exact transition of the committed project CTM: Zettel 11359, Graph A (H4/H5)
(in-package #:dreyeck/work/project/tests)

;; Decision H5b: the Project Workspace is not admitted to the served regular Catalog within this scope. Graph A therefore
;;  - removes the dependency of p4 on p3 (p4 concerns the served Catalog application; with no served Workspace it needs nothing from p3),
;;  - removes the dependency of p5 on the precondition "admission of the Project Workspace to a served runtime" and retires that
;;    precondition (a decision outside the scope, not a condition the scope can wait for),
;;  - keeps p5 -> p4 (package content), p5 -> p1, and the other six dependencies, among them the Security Review gate of p6.
;; Like the transition of H6/H7 (project-transition-h6-h7.lisp), this one is exact and revision-scoped: it names its baseline commit and
;; the project CTM of that commit, and the one result CTM it admits; it excuses only what it names after verifying all of it, in both
;; directions; it states the complete Topic and Association delta, not only what the unchanged guard happens to report (the guard
;; reports 3 Topics and only the 3 derived Associations; the other 6 removed Associations are accounted for there by the changed source
;; page, which is why this specification lists all 9). Everything else stays under the unchanged guard.

(defun %transition-graph-a ()
  (list :kind :graph-a :id "graph-a-e766ee42"
        :baseline-commit "e766ee42956dcc940961af3fb3d2f60219e63835"
        :baseline-ctm-sha256 "6a54569f9ddbf01ae00e33715d605c0e8ade54b3b6c6d81305d3e68ae519a8b5"
        :result-ctm-sha256 "e7c4478cf1cab9e3555efbb359b19818f68ab4a0c51ed8850dd1519e545edd52"
        :source-page '("dreyeck/work/project" . "Implementation Assignments")
        :carrier-page '("dreyeck/work/project" . "Regular HyperDoc Catalog Scope Proposal")
        :removed-statements '(("tm-reg-p4" "tm-reg-p3") ("tm-reg-p5" "tm-reg-pre-admission"))
        :removed-precondition "tm-reg-pre-admission"
        :kept-dependencies '(("tm-reg-p2" "tm-reg-p1") ("tm-reg-p3" "tm-reg-p2") ("tm-reg-p5" "tm-reg-p1") ("tm-reg-p5" "tm-reg-p4")
                             ("tm-reg-p5" "tm-reg-pre-publish") ("tm-reg-p6" "tm-reg-p5")
                             ("tm-reg-p6" "tm-reg-pre-security-review") ("tm-reg-p6" "tm-reg-pre-production"))
        :topic-counts '(395 392)
        :association-counts '(779 770)
        :counts '(:declarations 72 :statements 77 :assignments 8 :gaps 45)))

(defun apply-transition-by-spec (spec old new differences)
  "Dispatch on the kind of SPEC; a specification without a kind is the one of H6/H7."
  (ecase (or (getf spec :kind) :h6-h7)
    (:h6-h7 (apply-transition spec old new differences))
    (:graph-a (apply-transition-graph-a spec old new differences))))

(defun %dep-statement-si (from to)
  (%o "statement" "dreyeck/work/project/implementation-assignments" from "work:relation/depends-on" to "1"))
(defun %graph-a-associations (spec)
  "The nine Associations that go with the two removed statements and the retired precondition, as signatures of the baseline."
  (let* ((source (%o-page (car (getf spec :source-page)) (cdr (getf spec :source-page))))
         (carrier (%o-page (car (getf spec :carrier-page)) (cdr (getf spec :carrier-page))))
         (pre (getf spec :removed-precondition)) (result nil))
    (push (%kind-signature pre "kind-precondition") result)
    (push (%o-signature (%o-schema "proposed-on") `((,(%o-schema "proposal") . ,(%o-work pre)) (,(%o-schema "source-page") . ,source))) result)
    (push (%carried-by-signature pre carrier) result)
    (dolist (edge (getf spec :removed-statements))
      (let ((si (%dep-statement-si (first edge) (second edge))))
        (push (%o-signature +type-instance+ `((,(concatenate 'string +psi+ "instance") . ,si) (,(concatenate 'string +psi+ "type") . ,(%o-schema "proposed-statement")))) result)
        (push (%o-signature (%o-schema "proposed-on") `((,(%o-schema "proposal") . ,si) (,(%o-schema "source-page") . ,source))) result)
        (push (%o-signature (%o-work "work:relation/depends-on")
                            `((,(%o-schema "role-work-relation-depends-on-source") . ,(%o-work (first edge)))
                              (,(%o-schema "role-work-relation-depends-on-target") . ,(%o-work (second edge))))
                            si)
              result)))
    (nreverse result)))
(defun %depends-edges (signatures)
  "The (from to) pairs of the scope's depends-on Associations in SIGNATURES."
  (let ((head (format nil "~A(" (%o-work "work:relation/depends-on"))) (src (format nil "~A: ~A" (%o-schema "role-work-relation-depends-on-source") (%o "work/topic/")))
        (tgt (format nil "~A: ~A" (%o-schema "role-work-relation-depends-on-target") (%o "work/topic/"))) (edges nil))
    (dolist (s signatures (nreverse edges))
      (when (eql 0 (search head s))
        (let* ((a (search src s)) (b (search tgt s)))
          (when (and a b)
            (let ((from (subseq s (+ a (length src)) (search ", " s :start2 a))) (to (subseq s (+ b (length tgt)) (or (position #\) s :start b) (length s)))))
              (when (and (eql 0 (search "tm-reg-" from)) (or (eql 0 (search "tm-reg-" to)))) (push (list from to) edges)))))))))

(defun apply-transition-graph-a (spec old new differences)
  "(values RESIDUAL PROBLEMS) as apply-transition: the guard's DIFFERENCES without exactly the 3 Topics and 3 derived Associations named,
and the problems found in the complete delta (3 Topics, 9 Associations, nothing added) and in what must stay."
  (let ((problems nil) (residual (copy-list differences))
        (old-sigs (%signatures old)) (new-sigs (%signatures new))
        (statements (mapcar (lambda (e) (%dep-statement-si (first e) (second e))) (getf spec :removed-statements)))
        (pre-si (%o-work (getf spec :removed-precondition))))
    (labels ((problem (kind &rest detail) (push (cons kind detail) problems))
             (drop (key items &key multiset)
               (setf (getf residual key)
                     (if multiset (%multiset-minus (getf residual key) items)
                         (remove-if (lambda (x) (member x items :test #'string=)) (getf residual key))))))
      ;; Identity in the baseline: two proposed depends-on statements and a proposed precondition, as named
      (dolist (edge (getf spec :removed-statements))
        (let* ((si (%dep-statement-si (first edge) (second edge))) (o (%topic-by-si old si)))
          (cond ((null o) (problem :expected-removal-absent si))
                (t (unless (member (format nil "name ~A depends-on ~A" (first edge) (second edge)) (%topic-content o) :test #'string=)
                     (problem :removed-statement-has-another-text si))
                   (when (%topic-by-si new si) (problem :removed-statement-still-in-the-result si))))))
      (let ((p (%topic-by-si old pre-si)))
        (cond ((null p) (problem :expected-removal-absent pre-si))
              (t (unless (member (%kind-signature (getf spec :removed-precondition) "kind-precondition") old-sigs :test #'string=)
                   (problem :retired-topic-is-no-precondition pre-si))
                 (when (%topic-by-si new pre-si) (problem :retired-precondition-still-in-the-result pre-si)))))
      ;; The complete delta: exactly these Topics and exactly these nine Associations are gone, and nothing is new
      (let ((expected (%graph-a-associations spec)) (gone (%multiset-minus old-sigs new-sigs)) (added (%multiset-minus new-sigs old-sigs)))
        (when (or (%multiset-minus gone expected) (%multiset-minus expected gone))
          (problem :association-delta-differs (list :unexpected-loss (%multiset-minus gone expected) :expected-loss-missing (%multiset-minus expected gone))))
        (when added (problem :association-added added))
        (unless (every (lambda (sig) (member sig old-sigs :test #'string=)) expected) (problem :expected-association-absent-in-the-baseline))
        (when (some (lambda (s) (or (search pre-si s) (some (lambda (st) (search st s)) statements))) new-sigs)
          (problem :a-retired-item-is-still-referenced))
        (let* ((old-topics (mapcar #'%si1 (topic-maps.tmdm:topic-map-topics old))) (new-topics (mapcar #'%si1 (topic-maps.tmdm:topic-map-topics new)))
               (lost (remove-if (lambda (si) (member si new-topics :test #'string=)) old-topics))
               (fresh (remove-if (lambda (si) (member si old-topics :test #'string=)) new-topics)))
          (unless (equal (sort (copy-list lost) #'string<) (sort (cons pre-si (copy-list statements)) #'string<)) (problem :topic-delta-differs lost))
          (when fresh (problem :topic-added fresh))
          (unless (equal (list (length old-topics) (length new-topics)) (getf spec :topic-counts)) (problem :topic-counts-differ (list (length old-topics) (length new-topics)))))
        (unless (equal (list (length old-sigs) (length new-sigs)) (getf spec :association-counts)) (problem :association-counts-differ (list (length old-sigs) (length new-sigs))))
        ;; What the guard sees of it: exactly the 3 Topics and the 3 derived Associations, taken from the residual only if present
        (let ((derived (remove-if-not (lambda (s) (member s (getf differences :lost-associations) :test #'string=)) expected)))
          (unless (member pre-si (getf differences :lost-topics) :test #'string=) (problem :expected-removal-absent pre-si))
          (dolist (st statements) (unless (member st (getf differences :lost-topics) :test #'string=) (problem :expected-removal-absent st)))
          (drop :lost-topics (cons pre-si statements))
          (drop :lost-associations derived :multiset t)))
      ;; What must stay: the eight other dependencies, exactly, among them p5->p4, p5->p1 and the Security Review gate of p6
      (let ((edges (%depends-edges new-sigs)) (kept (getf spec :kept-dependencies)))
        (when (or (set-difference edges kept :test #'equal) (set-difference kept edges :test #'equal))
          (problem :dependencies-differ edges))
        (unless (member '("tm-reg-p5" "tm-reg-p4") edges :test #'equal) (problem :retained-edge-missing "tm-reg-p5" "tm-reg-p4"))
        (unless (member '("tm-reg-p5" "tm-reg-p1") edges :test #'equal) (problem :retained-edge-missing "tm-reg-p5" "tm-reg-p1"))
        (unless (member '("tm-reg-p6" "tm-reg-pre-security-review") edges :test #'equal) (problem :review-gate-missing)))
      (let ((counts (%model-counts new)))
        (unless (equal counts (getf spec :counts)) (problem :model-counts-differ counts)))
      (values residual (nreverse problems)))))

;;; Controls

(defun run-transition-graph-a-tests ()
  "Graph A, with controls. It runs only while the working project CTM is the transition's result; otherwise it says NOT-RUN, which is not a pass."
  (let* ((spec (%transition-graph-a)) (*checks* 0)
         (working (uiop:read-file-string (p:project-ctm-pathname) :external-format :utf-8)))
    (unless (equal (getf spec :result-ctm-sha256) (%sha-of-text working))
      (format t "~&PROJECT-CTM-TRANSITION-GRAPH-A-NOT-RUN: the working project CTM is not the result of ~A (SHA-256 ~A); this is not a pass~%"
              (getf spec :id) (getf spec :result-ctm-sha256))
      (return-from run-transition-graph-a-tests 0))
    (let* ((items (p:sources-items (p:read-project-sources)))
           (old-text (%git-ctm-at (getf spec :baseline-commit)))
           (old (%read-ctm old-text "baseline")) (new (%read-ctm working "result"))
           (differences (preservation-differences old new items)))
      (check "graph-a:the-specification-agrees-with-its-commit" (equal (getf spec :baseline-ctm-sha256) (%sha-of-text old-text)))
      (check "graph-a:applies-to-the-named-baseline-and-the-named-result" (eq t (transition-applicable-p spec old-text working)))
      (check "graph-a:the-unchanged-guard-reports-exactly-three-topics"
             (equal (sort (copy-list (getf differences :lost-topics)) #'string<)
                    (sort (cons (%o-work (getf spec :removed-precondition)) (mapcar (lambda (e) (%dep-statement-si (first e) (second e))) (getf spec :removed-statements))) #'string<)))
      (check "graph-a:the-unchanged-guard-reports-only-the-three-derived-associations" (= 3 (length (getf differences :lost-associations))))
      (check "graph-a:the-unchanged-guard-reports-no-changed-topic-and-no-unattributed-addition"
             (and (null (getf differences :changed-topics)) (null (getf differences :unattributed-additions))))
      (check "graph-a:the-complete-delta-is-nine-associations-and-nothing-added"
             (and (= 9 (length (%multiset-minus (%signatures old) (%signatures new)))) (null (%multiset-minus (%signatures new) (%signatures old)))))
      (multiple-value-bind (residual problems) (apply-transition-graph-a spec old new differences)
        (check "graph-a:positive:no-problem-in-what-the-specification-names" (null problems))
        (check "graph-a:positive:nothing-remains-for-the-unchanged-guard" (%empty-residual-p residual)))
      (check "graph-a:positive:the-result-has-the-size-the-specification-says" (equal (getf spec :counts) (%model-counts new)))
      (check "graph-a:positive:the-model-of-the-sources-agrees-with-the-counts"
             (let ((model (p:build-project-model)))
               (equal (list :declarations (length (p:model-declarations model)) :statements (length (p:model-statements model))
                            :assignments (length (p:model-assignments model)) :gaps (length (p:model-gaps model)))
                      (getf spec :counts))))
      (check "graph-a:positive:the-eight-other-dependencies-remain-exactly"
             (null (set-difference (getf spec :kept-dependencies) (%depends-edges (%signatures new)) :test #'equal)))
      (check "graph-a:positive:the-security-review-gate-of-p6-remains"
             (member '("tm-reg-p6" "tm-reg-pre-security-review") (%depends-edges (%signatures new)) :test #'equal))
      (check "graph-a:positive:the-legitimate-work-item-deliverable-gap-remains"
             (%topic-by-si new (%gap-si "work-item-deliverable-unlinked" '("topic-maps-regular-hyperdoc" "tm-regular-catalog"))))
      ;; Negative controls: mutate the result text; apply the transition directly; each must fail for its own reason
      (flet ((evaluate (text &optional (baseline old))
               (let* ((mutant (%read-ctm text "mutant")) (d (preservation-differences baseline mutant items)))
                 (multiple-value-list (apply-transition-graph-a spec baseline mutant d))))
             (kinds (problems) (mapcar #'car problems))
             (drop-statement (text from to)
               (%drop-topic-and-associations text (%dep-statement-si from to))))
        ;; N1 an additional, unrelated Topic disappears
        (let* ((h6 (%transition-h6-h7)) (iri (%first-gap-iri-not-in working h6)) (r (evaluate (%drop-topic-and-associations working iri))))
          (check "graph-a:negative:an-unrelated-topic-disappears" (and iri (member iri (getf (first r) :lost-topics) :test #'string=)))
          (check "graph-a:negative:that-stays-with-the-unchanged-guard" (not (%empty-residual-p (first r)))))
        ;; N2 an unrelated Association disappears
        (let ((r (evaluate (%drop-first-line-starting working "s:reads-source("))))
          (check "graph-a:negative:an-unrelated-association-disappears" (getf (first r) :lost-associations))
          (check "graph-a:negative:it-is-reported-as-an-unexpected-loss" (member :association-delta-differs (kinds (second r)))))
        ;; N3 a required removal is absent: the baseline stands in for a result that removed nothing
        (let ((r (multiple-value-list (apply-transition-graph-a spec old old (preservation-differences old old items)))))
          (check "graph-a:negative:a-required-removal-is-absent" (member :expected-removal-absent (kinds (second r)))))
        ;; N4 a further dependency is removed: p5 -> p4
        (let ((r (evaluate (drop-statement working "tm-reg-p5" "tm-reg-p4"))))
          (check "graph-a:negative:a-further-dependency-is-removed" (member :association-delta-differs (kinds (second r))))
          (check "graph-a:negative:the-removed-dependency-is-lost-to-the-guard" (member (%dep-statement-si "tm-reg-p5" "tm-reg-p4") (getf (first r) :lost-topics) :test #'string=))
          (check "graph-a:negative:the-retained-edge-is-reported-missing" (member :retained-edge-missing (kinds (second r)))))
        ;; N5 the Security Review gate of p6 is removed
        (let ((r (evaluate (drop-statement working "tm-reg-p6" "tm-reg-pre-security-review"))))
          (check "graph-a:negative:the-security-review-gate-is-removed" (member :review-gate-missing (kinds (second r)))))
        ;; N6 p5 -> p1 is removed
        (let ((r (evaluate (drop-statement working "tm-reg-p5" "tm-reg-p1"))))
          (check "graph-a:negative:p5-to-p1-is-removed" (member :retained-edge-missing (kinds (second r))))))
      ;; Second line: another result CTM, or an unrelated revision compared with, is not covered at all
      (check "graph-a:negative:another-result-ctm-is-not-covered"
             (eq :result-ctm-differs (transition-applicable-p spec old-text (concatenate 'string working (string #\Newline) "# another CTM"))))
      (check "graph-a:negative:the-h6-h7-baseline-is-not-this-baseline"
             (eq :baseline-ctm-differs (transition-applicable-p spec (%git-ctm-at (getf (%transition-h6-h7) :baseline-commit)) working)))
      (check "graph-a:negative:an-unrelated-source-revision-is-not-covered"
             (eq :baseline-ctm-differs (transition-applicable-p spec (%git-ctm-at +baseline-commit+) working)))
      (format t "~&PROJECT-CTM-TRANSITION-GRAPH-A-PASS: ~D checks; the transition ~A is exact: baseline ~A, result CTM ~A, 3 Topics and 9 Associations, nothing else excused~%"
              *checks* (getf spec :id) (subseq (getf spec :baseline-commit) 0 8) (subseq (getf spec :result-ctm-sha256) 0 8))
      *checks*)))
