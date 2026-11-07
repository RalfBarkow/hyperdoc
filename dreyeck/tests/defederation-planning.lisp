(defpackage #:dreyeck/work/defederation-planning/tests
  (:use #:cl)
  (:local-nicknames (#:d #:dreyeck/work/defederation-planning)
                    (#:r #:dreyeck/shop3))
  (:export #:run-tests))
(in-package #:dreyeck/work/defederation-planning/tests)

(defun search-state (state &key (domain 'd::prepare-wiki-defederation)
                               (plan-tree t)
                               (tasks '((d::prepare-defederation d::local-wiki
                                         d::remote-wiki d::target-page))))
  "Use SHOP3 itself for counterexamples, without redefining the three fixtures."
  (let ((name (gensym "DEFEDERATION-PROBE-"))
        (before (copy-tree state)))
    (unwind-protect
         (progn
           (shop3:make-problem (list name :domain domain :silently t) state tasks)
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans name :which :all :verbose 0
                                 :plan-tree plan-tree :collect-state t)
             (assert (equal before state))
             (make-instance 'r:hyperdoc-htn-plan-result
                            :problem-name name :raw-plans raw
                            :plans (mapcar #'shop3:shorter-plan raw)
                            :time seconds :plan-trees trees :final-states states
                            :execution-mode :plan-only)))
      (shop3:delete-problem name))))

(defun tree-contains-p (value tree)
  (or (equal value tree)
      (and (consp tree)
           (or (tree-contains-p value (car tree))
               (tree-contains-p value (cdr tree))))))

(defun check-result (label result count &optional operators method)
  (assert (typep result 'r:hyperdoc-htn-plan-result))
  (assert (eq :plan-only (r:execution-mode-of result)))
  (assert (= count (length (r:raw-plans-of result))
                  (length (r:plans-of result))
                  (length (r:plan-trees-of result))
                  (length (r:final-states-of result))))
  (when (zerop count) (assert (null (r:raw-plans-of result))))
  (loop for plan in (r:plans-of result)
        for tree in (r:plan-trees-of result)
        for state in (r:final-states-of result)
        for atoms = (shop3:state-atoms state)
        do (assert (equal operators (mapcar #'first plan)))
           (assert (equal '(d::prepare-defederation d::local-wiki
                           d::remote-wiki d::target-page) (caar tree)))
           ;; The recursive SHOP3 planner drops the method label of an empty
           ;; decomposition. Assert its actual empty node plus the plan/state.
           (assert (tree-contains-p
                    (if (eq method 'd::already-local)
                        '((d::ensure-local-target d::local-wiki d::remote-wiki
                           d::target-page) nil nil)
                        method)
                    tree))
           (assert (not (tree-contains-p
                         (ecase method
                           (d::already-local 'd::fork-supported)
                           (d::fork-supported 'd::already-local)) tree)))
           (assert (member '(d::local-page d::local-wiki d::target-page)
                           atoms :test #'equal))
           (assert (not (member '(d::local-page-absent d::local-wiki d::target-page)
                                atoms :test #'equal)))
           (assert (member '(d::resolution-prepared d::local-wiki d::local-only)
                           atoms :test #'equal))
           (assert (member '(d::rendering-prepared d::local-wiki d::paragraph-only)
                           atoms :test #'equal))
           (assert (eq (not (null (member '(d::fork-prepared d::local-wiki
                                           d::remote-wiki d::target-page)
                                         atoms :test #'equal)))
                       (eq method 'd::fork-supported))))
  (let ((*package* (find-package :dreyeck/work/defederation-planning)))
    (format t "~&DEFEDERATION ~A PASS: ~D plans / ~D trees / ~D states; ~A; NOT-EXECUTED~%  ~S~%"
            label count (length (r:plan-trees-of result))
            (length (r:final-states-of result))
            (if (r:raw-plans-of result) :planned :no-plan) (r:plans-of result)))
  result)

(defun with-mutated-fork-method (change test)
  "Read the actual domain definition; mutate a copy in a disposable SHOP3 domain."
  (let* ((*package* (find-package :dreyeck/work/defederation-planning))
         (*read-eval* nil)
         (items (with-open-file
                    (stream (asdf:system-relative-pathname
                             "dreyeck/work/defederation-planning"
                             "dreyeck/work/defederation-planning.lisp"))
                  (loop for form = (read stream nil :eof)
                        until (eq form :eof)
                        when (and (consp form) (eq (car form) 'shop3:defdomain))
                          return (copy-tree (third form)))))
         (method (find 'd::fork-supported items :key #'third))
         (name (gensym "DEFEDERATION-MUTANT-")))
    (assert method)
    (funcall change method)
    (unwind-protect
         (let ((shop3:*domain* shop3:*domain*))
           (eval `(shop3:defdomain (,name :silently t :noset t) ,items))
           (funcall test name))
      (shop3:delete-domain name))))

(defun run-tests ()
  (let ((local-operators '(d::!prepare-local-resolution d::!prepare-paragraph-rendering))
        (fork-operators '(d::!simulate-fork d::!prepare-local-resolution
                          d::!prepare-paragraph-rendering)))
    ;; Actual public runners and problem objects, not expectations substituted
    ;; for a planning call. Inspect both the chosen method and resulting state.
    (loop for case in '(:a :b :c)
          for expected in '(1 1 0)
          for operators in (list local-operators fork-operators nil)
          for method in '(d::already-local d::fork-supported nil)
          for before = (d:scenario-state case)
          for context = (d:defederation-experiment case)
          do (check-result case (getf context :result) expected operators method)
             (assert (getf context :problem))
             (assert (getf context :methods))
             (assert (equal before (d:scenario-state case)))
             (assert (equal before (getf context :initial-state)))
             (assert (eq (if (zerop expected) :no-plan :planned)
                         (getf context :outcome)))
             (assert (eq :not-executed (getf context :execution-status))))
    (assert (= 2 (length (shop3:methods 'd::prepare-wiki-defederation
                                       'd::ensure-local-target))))

    ;; Remove each required report. In particular, missing local presence is
    ;; not sufficient evidence of local absence, even with a remote snapshot.
    (dolist (fact (d:scenario-state :b))
      (check-result (list :remove (first fact))
                    (search-state (remove fact (d:scenario-state :b) :test #'equal)) 0))
    (check-result :entirely-unknown (search-state nil) 0)

    ;; Turn B into local presence without retaining a contradictory absence.
    (let ((local (cons '(d::local-page d::local-wiki d::target-page)
                       (remove '(d::local-page-absent d::local-wiki d::target-page)
                               (d:scenario-state :b) :test #'equal))))
      (check-result :target-now-local (search-state local) 1 local-operators 'd::already-local)
      (check-result :local-with-fork-forbidden
                    (search-state
                     (cons '(d::fork-forbidden d::local-wiki d::remote-wiki d::target-page)
                           (remove '(d::fork-permitted d::local-wiki d::remote-wiki d::target-page)
                                   local :test #'equal)))
                    1 local-operators 'd::already-local))

    ;; Unknown and negative reports are different input states; neither enables
    ;; the fork. Then exercise every supported contradiction independently.
    (loop for positive in (d:scenario-state :b)
          for negative in '((d::local-page d::local-wiki d::target-page)
                            (d::remote-page-absent d::remote-wiki d::target-page)
                            (d::snapshot-unavailable d::remote-wiki d::target-page)
                            (d::fork-forbidden d::local-wiki d::remote-wiki d::target-page))
          do (unless (eq (car positive) 'd::local-page-absent)
               (check-result (list :negative (first negative))
                             (search-state (cons negative
                                                 (remove positive (d:scenario-state :b)
                                                         :test #'equal))) 0))
             (check-result (list :contradiction (first negative))
                           (search-state (cons negative (d:scenario-state :b))) 0))

    ;; Target a method precondition, keeping its primitive operator unchanged.
    ;; Exhaustive search must not escape through ALREADY-LOCAL. A positive
    ;; control supplies the new fact and restores the fork solution.
    (with-mutated-fork-method
     (lambda (method) (push '(d::review-confirmed) (fourth method)))
     (lambda (domain)
       (check-result :method-tightened-no-alternative
                     (search-state (d:scenario-state :b) :domain domain) 0)
       (check-result :method-tightened-local-still-works
                     (search-state (d:scenario-state :a) :domain domain)
                     1 local-operators 'd::already-local)
       (check-result :method-new-evidence-restores-plan
                     (search-state (cons '(d::review-confirmed) (d:scenario-state :b))
                                   :domain domain)
                     1 fork-operators 'd::fork-supported)))

    ;; Weakening the method alone must not bypass the primitive's fork guard.
    (with-mutated-fork-method
     (lambda (method)
       (assert (find 'd::fork-permitted (fourth method) :key #'car))
       (setf (fourth method)
             (remove 'd::fork-permitted (fourth method) :key #'car)))
     (lambda (domain)
       (check-result :method-weakened-operator-refuses
                     (search-state (d:scenario-state :c) :domain domain) 0)))

    ;; Preserve the result contract's distinction between zero plans and a
    ;; successful empty plan: ensuring an already local target needs no action.
    ;; The pinned recursive planner's tree extraction fails for zero actions;
    ;; this boundary probe therefore requests no tree (see the evidence report).
    (let ((empty (search-state (d:scenario-state :a)
                               :plan-tree nil
                               :tasks '((d::ensure-local-target d::local-wiki
                                         d::remote-wiki d::target-page)))))
      (assert (r:raw-plans-of empty))
      (assert (equal '(nil) (r:plans-of empty)))
      (format t "~&DEFEDERATION EMPTY-LOCAL-SUBTASK PASS: successful empty plan, not NO-PLAN~%"))
    ;; Mutation probes must leave the production domain and fixtures intact.
    (check-result :production-after-mutations (d:defederation-plan :b)
                  1 fork-operators 'd::fork-supported))
  (format t "~&DEFEDERATION-TESTS-PASS: exhaustive SHOP3 searches; simulated effects only.~%")
  t)
