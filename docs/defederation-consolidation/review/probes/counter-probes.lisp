;;;; Counter-probes F2, X1, F3, F4, X2, X6 and R1 (findings K1, K2, K7, K8; properties that hold).
;;;; Independent review of PR #33 at 7bc2fced4e970e813d870307162ec349380ca0aa (docs/defederation-consolidation/review/README.md).
;;;; Read-only with respect to the repository: plans only, no file is written, the domain and its tests are not changed.
;;;; From the repository root, with the project's ASDF registry (SBCL 2.4.10, SHOP3 ce53f9b, e.g. in `nix develop`):
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/counter-probes.lisp
(require :asdf)
(asdf:load-asd (merge-pathnames "../../../../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:load-system "dreyeck/work/defederation-planning")
(in-package #:dreyeck/work/defederation-planning)

(load (merge-pathnames "harness.lisp" (uiop:pathname-directory-pathname *load-truename*)))

;;; F2 – repeated forks
(probe "F2.1" "prepare x3, one target" +b+ (list (prep) (prep) (prep)))
(let* ((first-run (probe "F2.2a" "fresh plan from B" +b+ (list (prep))))
       (final (shop3:state-atoms (first (dreyeck/shop3:final-states-of first-run)))))
  (probe "F2.2b" "continuation: plan again from B's simulated final state" final (list (prep)))
  (probe "F2.2c" "new plan from the unchanged initial B" +b+ (list (prep))))
(probe "F2.3" "prepare, then the primitive fork requested directly" +b+
       (list (prep) '(!simulate-fork :s :t :r :snap-1)))
(probe "F2.4" "primitive fork twice, two different snapshots" (with '(remote-snapshot :s :t :r2 :snap-2))
       '((!simulate-fork :s :t :r :snap-1) (!simulate-fork :s :t :r2 :snap-2)))
(probe "F2.5" "two snapshots, prepare x2" (with '(remote-snapshot :s :t :r2 :snap-2)) (list (prep) (prep)))
(probe "F2.6" "prepare, then ensure-local-target directly" +b+ (list (prep) '(ensure-local-target :s :t)))
(probe "F2.7" "input holds modeled-fork but no modeled-local-page (inconsistent continuation)"
       (with '(modeled-fork :s :t :r :snap-1)) (list (prep)))

;;; Unexpected already-modeled
(probe "X1.1" "only (modeled-local-page :s :t), nothing else" '((modeled-local-page :s :t)) (list (prep)))
(probe "X1.2" "modeled-local-page + local-page-absent + fork-forbidden, no snapshot, no policy"
       '((modeled-local-page :s :t) (local-page-absent :s :t) (fork-forbidden :s :t)) (list (prep)))
(probe "X1.3" "modeled-local-page + snapshot-unavailable + remote-page-absent, no fork evidence"
       '((modeled-local-page :s :t) (local-page-absent :s :t) (snapshot-unavailable :s :t) (remote-page-absent :r :t)) (list (prep)))

;;; F3 – scope
(probe "F3.1" "contradiction at another slug" (with '(local-page :s :other) '(local-page-absent :s :other)) (list (prep)))
(probe "F3.2" "two targets of the same site: t local, u forkable"
       (append '((local-page :s :u0)) '((local-page-absent :s :u) (remote-snapshot :s :u :r :snap-u) (fork-permitted :s :u)
                                        (fork-source-policy :s :u :cached-copy-sufficient)))
       (list (prep :u0) (prep :u)))
(probe "F3.3" "two targets, second contradictory: whole task list" (with '(local-page :s :u) '(local-page-absent :s :u))
       (list (prep) (prep :u)))
(probe "F3.4" "pre-existing markers: other slug, old site arity, target marker without readiness"
       '((local-links-prepared :s :other) (local-links-prepared :s) (paragraph-rendering-prepared :s)
         (local-links-prepared :s :t) (local-page-absent :s :t))
       (list (prep)))
(probe "F3.5" "primitive paragraph step with a supplied target marker, target not ready"
       '((local-links-prepared :s :t) (local-page-absent :s :t)) '((!prepare-paragraph-rendering :s :t)))
(dolist (conflict '((local-page :s :t) (snapshot-unavailable :s :t) (fork-forbidden :s :t)
                    (fork-source-policy :s :t :require-remote-evidence)))
  (probe "F3.6" (format nil "B + ~S at the target" conflict) (with conflict) (list (prep))))
(probe "F3.7" "B + remote-page and remote-page-absent for the snapshot's remote"
       (with '(remote-page :r :t) '(remote-page-absent :r :t)) (list (prep)))
(probe "F3.8" "observed local target + snapshot-unavailable (conflict at an already local target)"
       '((local-page :s :t) (remote-snapshot :s :t :r :snap-1) (snapshot-unavailable :s :t)) (list (prep)))

;;; F4 – source policy
(probe "F4.1" "cached: remote unknown" +b+ (list (prep)))
(probe "F4.2" "cached: remote explicitly absent" (with '(remote-page-absent :r :t)) (list (prep)))
(probe "F4.3" "strict: remote unknown" (strict) (list (prep)))
(probe "F4.4" "strict: remote explicitly absent" (strict '(remote-page-absent :r :t)) (list (prep)))
(probe "F4.5" "strict: remote positive" (strict '(remote-page :r :t)) (list (prep)))
(probe "F4.6" "strict: remote-page only for another remote than the snapshot's" (strict '(remote-page :r9 :t)) (list (prep)))
(probe "F4.7" "strict: two snapshots, remote evidence only for r2"
       (strict '(remote-snapshot :s :t :r2 :snap-2) '(remote-page :r2 :t)) (list (prep)))
(probe "F4.8" "strict: snap from r has positive evidence; r2 (also offered) is contradictory"
       (strict '(remote-page :r :t) '(remote-snapshot :s :t :r2 :snap-2) '(remote-page :r2 :t) '(remote-page-absent :r2 :t)) (list (prep)))
(probe "F4.9" "cached: contradictory evidence about an unrelated remote (no snapshot from it)"
       (with '(remote-page :r9 :t) '(remote-page-absent :r9 :t)) (list (prep)))
(probe "F4.10" "cached: same remote, two snapshots" (with '(remote-snapshot :s :t :r :snap-2)) (list (prep)))
(probe "F4.11" "unknown policy value" (substitute '(fork-source-policy :s :t :whatever) '(fork-source-policy :s :t :cached-copy-sufficient)
                                                    (copy-tree +b+) :test #'equal) (list (prep)))
(probe "F4.12" "policy for another slug only" (substitute '(fork-source-policy :s :other :cached-copy-sufficient)
                                                         '(fork-source-policy :s :t :cached-copy-sufficient) (copy-tree +b+) :test #'equal) (list (prep)))

;;; X2 – primitive fork without each piece of evidence
(dolist (missing '(local-page-absent remote-snapshot fork-permitted fork-source-policy))
  (probe "X2" (format nil "primitive fork without ~(~A~)" missing) (remove missing (copy-tree +b+) :key #'first)
         '((!simulate-fork :s :t :r :snap-1))))
(probe "X2" "primitive fork, strict policy, remote unknown" (strict) '((!simulate-fork :s :t :r :snap-1)))

;;; X6 – zero steps versus no solution
(probe "X6.1" "ensure-local-target on a local target, plan-tree T" '((local-page :s :t)) '((ensure-local-target :s :t)))
(probe "X6.2" "ensure-local-target on a local target, plan-tree NIL" '((local-page :s :t)) '((ensure-local-target :s :t)) :plan-tree nil)
(probe "X6.3" "scenario C (no permission): no solution" (scenario-state :c) (list (prep :target-page)))

;;; Registrations left by the public entry point
(let ((before (length shop3::*all-problems*)))
  (dotimes (i 5) (plan-defederation (scenario-state :b)))
  (format t "~&PROBE R1 plan-defederation x5: *all-problems* grew by ~D~%" (- (length shop3::*all-problems*) before)))
(format t "~&PROBES-DONE~%")
