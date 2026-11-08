(in-package #:dreyeck/work/defederation-planning)

(defun %without-predicate (predicate state)
  (remove predicate state :key #'first))

(defun %check-result (label state expected-operators
                      &key (domain 'defederation-preparation))
  (let* ((before (copy-tree state))
         (result (plan-defederation state :domain domain))
         (plans (dreyeck/shop3:plans-of result))
         (expected-count (if expected-operators 1 0)))
    (assert (equal before state))
    (assert (typep result 'dreyeck/shop3:hyperdoc-htn-plan-result))
    (assert (eq :plan-only (dreyeck/shop3:execution-mode-of result)))
    (assert (realp (dreyeck/shop3:time-of result)))
    (assert (= expected-count (length plans)
               (length (dreyeck/shop3:raw-plans-of result))
               (length (dreyeck/shop3:plan-trees-of result))
               (length (dreyeck/shop3:final-states-of result))))
    (assert (eq (if expected-operators :planned :no-plan)
                (planning-outcome result)))
    (when expected-operators
      (let* ((plan (first plans))
             (tree (first (dreyeck/shop3:plan-trees-of result)))
             (atoms (shop3:state-atoms
                     (first (dreyeck/shop3:final-states-of result)))))
        (assert (equal expected-operators (mapcar #'first plan)))
        (assert (equal '(prepare-defederation :local-wiki :target-page)
                       (caar tree)))
        (assert (eq 'prepare-after-consistency-check (second (first tree))))
        (assert (subsetp before atoms :test #'equal))
        (assert (member '(local-links-prepared :local-wiki :target-page) atoms :test #'equal))
        (assert (member '(paragraph-rendering-prepared :local-wiki :target-page)
                        atoms :test #'equal))
        (if (member '!simulate-fork expected-operators)
            (progn
              (assert (equal '(!simulate-fork :local-wiki :target-page
                               :remote-wiki :snapshot-1) (first plan)))
              (assert (member '(modeled-local-page :local-wiki :target-page)
                              atoms :test #'equal))
              (assert (member '(modeled-fork :local-wiki :target-page
                                :remote-wiki :snapshot-1) atoms :test #'equal))
              (assert (eq 'fork-proven-remote
                          (second (first (third (first tree)))))))
            (progn
              (assert (member '(local-page :local-wiki :target-page)
                              atoms :test #'equal))
              (assert (notany (lambda (atom) (eq 'modeled-fork (first atom)))
                              atoms))))))
    (let ((*package* (find-package '#:dreyeck/work/defederation-planning)))
      (format t "~&DEFEDERATION ~A PASS: ~S; ~D plans/trees/states; :PLAN-ONLY; :NOT-EXECUTED~%  ~S~%"
              label (planning-outcome result) expected-count plans))
    result))

(defun %domain-with-extra-precondition (method-label)
  "Read our literal domain and compile a private mutant with SHOP3 itself.
Never mutate the installed production domain or introduce a second evaluator."
  (let* ((*package* (find-package '#:dreyeck/work/defederation-planning))
         (*read-eval* nil)
         (form
           (with-open-file
               (stream (asdf:system-relative-pathname
                        "dreyeck/work/defederation-planning"
                        "dreyeck/work/defederation-planning.lisp"))
             (loop for form = (read stream nil :eof)
                   until (eq :eof form)
                   when (and (consp form) (eq 'shop3:defdomain (first form)))
                     return form)))
         (method (find method-label (third form) :key #'third)))
    (assert form)
    (assert (eq :method (first method)))
    (push '(fork-reviewed ?site ?slug) (fourth method))
    (setf (second form) '(defederation-precondition-mutant :noset t :silently t))
    (eval form)
    'defederation-precondition-mutant))

(defun run-tests ()
  "Three scenarios plus falsification probes, enumerating ALL SHOP3 solutions."
  (let* ((local-steps '(!prepare-local-links !prepare-paragraph-rendering))
         (fork-steps (cons '!simulate-fork local-steps))
         (b (scenario-state :b)))
    (%check-result :a (scenario-state :a) local-steps)
    (%check-result :b b fork-steps)
    (%check-result :c (scenario-state :c) nil)

    ;; Unknown facts must not be replaced by observations of their opposite.
    (dolist (predicate '(fork-permitted remote-snapshot local-page-absent))
      (%check-result (list :missing predicate) (%without-predicate predicate b) nil))
    (%check-result :explicitly-forbidden
                   (cons '(fork-forbidden :local-wiki :target-page)
                         (scenario-state :c)) nil)
    (%check-result :snapshot-observed-unavailable
                   (cons '(snapshot-unavailable :local-wiki :target-page)
                         (%without-predicate 'remote-snapshot b)) nil)
    (%check-result :local-instead-of-absent
                   (cons '(local-page :local-wiki :target-page)
                         (%without-predicate 'local-page-absent b)) local-steps)
    (%check-result :local-even-if-fork-forbidden
                   '((local-page :local-wiki :target-page)
                     (fork-forbidden :local-wiki :target-page)) local-steps)

    ;; In particular, the local method must not rescue contradictory input.
    (dolist (opposite '((local-page :local-wiki :target-page)
                        (snapshot-unavailable :local-wiki :target-page)
                        (fork-forbidden :local-wiki :target-page)))
      (%check-result (list :contradiction (first opposite)) (cons opposite b) nil))

    ;; Isolate the method mutation: the operator remains unchanged. Search all
    ;; methods; then add exactly the missing fact to prove the mutant is usable.
    (let ((domain (%domain-with-extra-precondition 'fork-proven-remote)))
      (unwind-protect
           (progn
             (%check-result :changed-fork-method-no-alternative b nil :domain domain)
             (%check-result :changed-fork-method-local-still-works
                            (scenario-state :a) local-steps :domain domain)
             (%check-result :changed-fork-method-evidence-restored
                            (cons '(fork-reviewed :local-wiki :target-page) b)
                            fork-steps :domain domain))
        (shop3:delete-domain domain)))
    (let ((domain (%domain-with-extra-precondition 'already-local)))
      (unwind-protect
           (%check-result :changed-local-method-fork-cannot-bypass
                          (cons '(local-page :local-wiki :target-page)
                                (%without-predicate 'local-page-absent b))
                          nil :domain domain)
        (shop3:delete-domain domain)))
    ;; The unmodified domain remains usable after the adversarial searches.
    (%check-result :original-domain-intact b fork-steps)
    (let* ((context (defederation-experiment :b))
           (result (getf context :result)))
      (assert (typep result 'dreyeck/shop3:hyperdoc-htn-plan-result))
      (assert (getf context :problem))
      (assert (getf context :methods))
      (assert (eq :planned (getf context :outcome)))
      (assert (eq :not-executed (getf context :execution))))
    (run-consolidation-tests)
    (format t "~&DEFEDERATION-PLANNING-PASS: state-dependent methods; exhaustive alternatives; no execution.~%")
    t))

(defun run-consolidation-tests ()
  (let* ((b (scenario-state :b))
         (steps '(!simulate-fork !prepare-local-links !prepare-paragraph-rendering))
         (repeated (plan-defederation b :repeat 2))
         (plans (dreyeck/shop3:plans-of repeated))
         (atoms (shop3:state-atoms (first (dreyeck/shop3:final-states-of repeated)))))
    (assert (= 1 (length plans) (length (dreyeck/shop3:plan-trees-of repeated))
               (length (dreyeck/shop3:final-states-of repeated))))
    (assert (= 5 (length (first plans))))
    (assert (= 1 (count '!simulate-fork (first plans) :key #'first)))
    (assert (subsetp b atoms :test #'equal))
    (assert (member '(modeled-local-page :local-wiki :target-page) atoms :test #'equal))
    (assert (not (member '(local-page :local-wiki :target-page) atoms :test #'equal)))
    (assert (notany (lambda (fact) (and (member (first fact) '(local-links-prepared paragraph-rendering-prepared))
                                      (/= 3 (length fact)))) atoms))
    (assert (not (member '(local-links-prepared :local-wiki :other) atoms :test #'equal)))
    (let ((continued (plan-defederation atoms)))
      (assert (= 1 (length (dreyeck/shop3:plans-of continued))))
      (assert (not (find '!simulate-fork (first (dreyeck/shop3:plans-of continued)) :key #'first))))
    (format t "~&CONSOLIDATION REPEAT PASS: ~S; one fork, two target preparations; observations retained.~%" plans)
    (let ((local (plan-defederation (scenario-state :a) :repeat 2)))
      (assert (= 1 (length (dreyeck/shop3:plans-of local))))
      (assert (zerop (count '!simulate-fork (first (dreyeck/shop3:plans-of local)) :key #'first))))
    ;; A caller cannot bypass method guards by requesting the primitive twice.
    (shop3:make-problem '(primitive-repeat :domain defederation-preparation :silently t) b
                       '((!simulate-fork :local-wiki :target-page :remote-wiki :snapshot-1)
                         (!simulate-fork :local-wiki :target-page :remote-wiki :snapshot-1)))
    (assert (null (shop3:find-plans 'primitive-repeat :which :all :verbose 0 :plan-tree t :collect-state t)))
    (format t "~&CONSOLIDATION PRIMITIVE-REPEAT PASS: no alternative plan.~%")
    (%check-result :unrelated-contradiction
                   (append b '((local-page :local-wiki :other) (local-page-absent :local-wiki :other))) steps)
    (%check-result :missing-source-policy (%without-predicate 'fork-source-policy b) nil)
    (let ((strict (substitute '(fork-source-policy :local-wiki :target-page :require-remote-evidence)
                              '(fork-source-policy :local-wiki :target-page :cached-copy-sufficient) b :test #'equal)))
      (%check-result :strict-remote-unknown strict nil)
      (%check-result :strict-remote-negative (cons '(remote-page-absent :remote-wiki :target-page) strict) nil)
      (%check-result :strict-remote-positive (cons '(remote-page :remote-wiki :target-page) strict) steps)
      (%check-result :cached-copy-remote-negative (cons '(remote-page-absent :remote-wiki :target-page) b) steps)
      (%check-result :remote-contradiction
                     (append b '((remote-page :remote-wiki :target-page)
                                 (remote-page-absent :remote-wiki :target-page))) nil)
      (%check-result :policy-contradiction
                     (cons '(fork-source-policy :local-wiki :target-page :require-remote-evidence) b) nil))
    ;; More than one legitimate source: ALL must preserve both alternatives.
    (let* ((two (plan-defederation
                 (cons '(remote-snapshot :local-wiki :target-page :other-remote :snapshot-2) b)))
           (alternatives (dreyeck/shop3:plans-of two)))
      (assert (= 2 (length alternatives) (length (dreyeck/shop3:plan-trees-of two))
                 (length (dreyeck/shop3:final-states-of two))))
      (assert (every (lambda (p) (= 1 (count '!simulate-fork p :key #'first))) alternatives))
      (format t "~&CONSOLIDATION ALL-ALTERNATIVES PASS: ~S~%" alternatives)))
  t)
