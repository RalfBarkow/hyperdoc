;;;; Shared probe harness: one fresh SHOP3 problem per probe, :WHICH :ALL, the existing HYPERDOC-HTN-PLAN-RESULT, then deleted.
;;;; Reports outcome, operator sequences, native plan-tree method labels, and the facts added to and removed from each final state.
;;;; Loaded by counter-probes.lisp and primitive-tasks.lisp after DREYECK/WORK/DEFEDERATION-PLANNING is loaded.
(in-package #:dreyeck/work/defederation-planning)
(defvar *n* 0)
(defun labels-of (tree)
  "Method labels in a native SHOP3 plan tree: nodes (TASK LABEL . CHILDREN) whose task is a list."
  (let ((out '()))
    (labels ((walk (x)
               (when (consp x)
                 (when (and (consp (first x)) (symbolp (first (first x))) (consp (rest x)) (symbolp (second x)) (second x)
                            (not (keywordp (second x))))
                   (push (second x) out))
                 (mapc #'walk x))))
      (walk tree))
    (nreverse out)))

(defun probe (id label state tasks &key (plan-tree t) (domain 'defederation-preparation))
  (let ((name (intern (format nil "PR33-PROBE-~D" (incf *n*)))) (before (copy-tree state)))
    (shop3:make-problem (list name :domain domain :silently t) (copy-tree state) tasks)
    (unwind-protect
         (let ((*print-pretty* nil) (*print-length* 30))
           (handler-case
               (multiple-value-bind (raw seconds trees states)
                   (shop3:find-plans name :which :all :verbose 0 :plan-tree plan-tree :collect-state t)
                 (let ((result (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                                              :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                                              :time seconds :plan-trees trees :final-states states :execution-mode :plan-only)))
                   (format t "~&PROBE ~A ~A: outcome=~S plans=~D trees=~D states=~D ops=~S~%"
                           id label (planning-outcome result) (length raw) (length trees) (length states)
                           (mapcar (lambda (p) (mapcar #'first p)) (dreyeck/shop3:plans-of result)))
                   (loop for tree in trees for st in states for i from 1
                         for atoms = (shop3:state-atoms st)
                         do (format t "~&PROBE ~A   plan ~D labels=~S~%" id i (labels-of tree))
                            (format t "~&PROBE ~A   plan ~D added=~S~%" id i (set-difference atoms before :test #'equal))
                            (format t "~&PROBE ~A   plan ~D removed=~S observations-kept=~S~%" id i
                                    (set-difference before atoms :test #'equal) (subsetp before atoms :test #'equal)))
                   result))
             (error (c) (format t "~&PROBE ~A ~A: ERROR ~S ~A~%" id label (type-of c)
                                (substitute #\Space #\Newline (princ-to-string c))))))
      (shop3:delete-problem name))))

(defun prep (&optional (slug :t)) `(prepare-defederation :s ,slug))
(defparameter +b+ '((local-page-absent :s :t) (remote-snapshot :s :t :r :snap-1) (fork-permitted :s :t)
                    (fork-source-policy :s :t :cached-copy-sufficient)))
(defun with (&rest facts) (append facts (copy-tree +b+)))
(defun strict (&rest facts)
  (append facts (substitute '(fork-source-policy :s :t :require-remote-evidence) '(fork-source-policy :s :t :cached-copy-sufficient)
                            (copy-tree +b+) :test #'equal)))

