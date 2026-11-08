;;;; Mutants of the production domain against PR #33's own suite (K4), and corrections C1-C3 as compatibility checks.
;;;; Independent review of PR #33 at 7bc2fced4e970e813d870307162ec349380ca0aa (docs/defederation-consolidation/review/README.md).
;;;; Read-only with respect to the repository: plans only, no file is written, the domain and its tests are not changed.
;;;; From the repository root, with the project's ASDF registry (SBCL 2.4.10, SHOP3 ce53f9b, e.g. in `nix develop`):
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/mutants.lisp
;;;; Each mutant redefines DEFEDERATION-PREPARATION in this image only and restores it afterwards; nothing is written.
(require :asdf)
(asdf:load-asd (merge-pathnames "../../../../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:load-system "dreyeck/work/defederation-planning/tests")
(in-package #:dreyeck/work/defederation-planning)

(defparameter +original+
  (let ((*read-eval* nil) (*package* (find-package '#:dreyeck/work/defederation-planning)))
    (with-open-file (in (asdf:system-relative-pathname "dreyeck/work/defederation-planning" "dreyeck/work/defederation-planning.lisp"))
      (loop for form = (read in nil in) until (eq form in)
            when (and (consp form) (eq (first form) 'shop3:defdomain)) return (copy-tree (third form))))))
(defun install (items) (eval `(shop3:defdomain (defederation-preparation :noset t :silently t :redefine-ok t) ,items)))
(defun method* (items label) (or (find-if (lambda (i) (and (eq (first i) :method) (eq (third i) label))) items) (error "no ~S" label)))
(defun operator* (items name) (or (find-if (lambda (i) (and (eq (first i) :operator) (eq (first (second i)) name))) items) (error "no ~S" name)))
(defun axiom* (items name) (or (find-if (lambda (i) (and (eq (first i) :-) (eq (first (second i)) name))) items) (error "no ~S" name)))
(defun drop-branch (axiom label)
  (setf (cddr axiom) (loop for (l b) on (cddr axiom) by #'cddr unless (eq l label) append (list l b))))
(defun suite ()
  (let ((out (make-string-output-stream)))
    (handler-case (let ((*standard-output* out)) (run-tests) :survived)
      (error (c) (let ((m (substitute #\Space #\Newline (princ-to-string c)))) (format nil "KILLED: ~A" (subseq m 0 (min 100 (length m)))))))))
(defmacro mutant (id label &body body)
  `(let ((items (copy-tree +original+)))
     ,@body
     (install items)
     (format t "~&MUTANT ~A ~A: ~A~%" ,id ,label (suite))
     (install (copy-tree +original+))))

(mutant "M0" "identity" nil)
(mutant "M1" "fork METHOD without (not modeled-local-page)"
  (setf (fourth (method* items 'fork-proven-remote)) (remove '(not (modeled-local-page ?site ?slug)) (fourth (method* items 'fork-proven-remote)) :test #'equal)))
(mutant "M2" "fork OPERATOR without (not modeled-local-page)"
  (setf (third (operator* items '!simulate-fork)) (remove '(not (modeled-local-page ?site ?slug)) (third (operator* items '!simulate-fork)) :test #'equal)))
(mutant "M3" "both without (not modeled-local-page)"
  (setf (fourth (method* items 'fork-proven-remote)) (remove '(not (modeled-local-page ?site ?slug)) (fourth (method* items 'fork-proven-remote)) :test #'equal)
        (third (operator* items '!simulate-fork)) (remove '(not (modeled-local-page ?site ?slug)) (third (operator* items '!simulate-fork)) :test #'equal)))
(mutant "M4" "already-modeled removed" (setf items (remove (method* items 'already-modeled) items)))
(mutant "M5" "strict branch without remote-page" (let ((ax (axiom* items 'fork-source))) (setf (getf (cddr ax) 'remote-evidence) (butlast (getf (cddr ax) 'remote-evidence)))))
(mutant "M6" "cached branch without policy" (let ((ax (axiom* items 'fork-source))) (setf (getf (cddr ax) 'cached-copy) (rest (getf (cddr ax) 'cached-copy)))))
(mutant "M7" "policy-conflict branch removed" (drop-branch (axiom* items 'input-conflict) 'policy-conflict))
(mutant "M8" "remote-conflict branch removed" (drop-branch (axiom* items 'input-conflict) 'remote-conflict))
(mutant "M9" "snapshot-conflict branch removed" (drop-branch (axiom* items 'input-conflict) 'snapshot-conflict))
(mutant "M10" "operator without (not input-conflict)"
  (setf (third (operator* items '!simulate-fork)) (remove '(not (input-conflict ?site ?slug)) (third (operator* items '!simulate-fork)) :test #'equal)))
(mutant "M11" "markers back to site arity"
  (setf (fifth (operator* items '!prepare-local-links)) '((local-links-prepared ?site))
        (third (operator* items '!prepare-paragraph-rendering)) '((local-links-prepared ?site))
        (fifth (operator* items '!prepare-paragraph-rendering)) '((paragraph-rendering-prepared ?site))))
(mutant "M12" "target-ready without the simulated branch" (drop-branch (axiom* items 'target-ready) 'simulated))
(mutant "M13" "fork method and operator without local-page-absent"
  (setf (fourth (method* items 'fork-proven-remote)) (remove '(local-page-absent ?site ?slug) (fourth (method* items 'fork-proven-remote)) :test #'equal)
        (third (operator* items '!simulate-fork)) (remove '(local-page-absent ?site ?slug) (third (operator* items '!simulate-fork)) :test #'equal)))
(mutant "M14" "fork operator ALSO adds (local-page ?site ?slug)" (push '(local-page ?site ?slug) (fifth (operator* items '!simulate-fork))))
(mutant "M15" "already-modeled accepts modeled presence even when local-page-absent is missing AND fork-forbidden holds (no change: current behaviour)" nil)
;;; Proposed corrections, expected to SURVIVE (the suite stays green):
(mutant "C1" "correction: already-modeled requires the fork that produced the presence"
  (push '(modeled-fork ?site ?slug ?_remote ?_snapshot) (fourth (method* items 'already-modeled))))
(mutant "C2" "correction: paragraph step requires target-ready"
  (push '(target-ready ?site ?slug) (third (operator* items '!prepare-paragraph-rendering))))
(mutant "C3" "correction: ?snapshot renamed ?_snapshot in remote-conflict (no singleton warning)"
  (let ((ax (axiom* items 'input-conflict)))
    (setf (getf (cddr ax) 'remote-conflict) (subst '?_snapshot '?snapshot (getf (cddr ax) 'remote-conflict)))))
;;; Do the corrections close X1/F3.5? Probe the C1+C2 domain directly.
(let ((items (copy-tree +original+)))
  (push '(modeled-fork ?site ?slug ?_remote ?_snapshot) (fourth (method* items 'already-modeled)))
  (push '(target-ready ?site ?slug) (third (operator* items '!prepare-paragraph-rendering)))
  (install items)
  (flet ((plans (state tasks)
           (shop3:make-problem (list 'c-probe :domain 'defederation-preparation :silently t) state tasks)
           (prog1 (length (shop3:find-plans 'c-probe :which :all :verbose 0)) (shop3:delete-problem 'c-probe))))
    (format t "~&CORRECTED X1.1 bare modeled-local-page: ~D plans~%" (plans '((modeled-local-page :s :t)) '((prepare-defederation :s :t))))
    (format t "~&CORRECTED F3.5 primitive paragraph with supplied marker: ~D plans~%"
            (plans '((local-links-prepared :s :t) (local-page-absent :s :t)) '((!prepare-paragraph-rendering :s :t))))
    (let* ((b (scenario-state :b)) (r (plan-defederation b)) (final (shop3:state-atoms (first (dreyeck/shop3:final-states-of r)))))
      (format t "~&CORRECTED continuation from B's final state: ~D plans, forks ~D~%"
              (length (dreyeck/shop3:plans-of (plan-defederation final)))
              (count '!simulate-fork (first (dreyeck/shop3:plans-of (plan-defederation final))) :key #'first))))
  (install (copy-tree +original+)))
(format t "~&MUTANTS-DONE~%")
