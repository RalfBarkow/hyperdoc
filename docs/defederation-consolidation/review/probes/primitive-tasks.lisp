;;;; Direct primitive SHOP3 tasks: F3.5b (K3) and the plan-tree defect inside this domain (S1/S2, K5).
;;;; Independent review of PR #33 at 7bc2fced4e970e813d870307162ec349380ca0aa (docs/defederation-consolidation/review/README.md).
;;;; Read-only with respect to the repository: plans only, no file is written, the domain and its tests are not changed.
;;;; From the repository root, with the project's ASDF registry (SBCL 2.4.10, SHOP3 ce53f9b, e.g. in `nix develop`):
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/primitive-tasks.lisp
(require :asdf)
(asdf:load-asd (merge-pathnames "../../../../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:load-system "dreyeck/work/defederation-planning")
(in-package #:dreyeck/work/defederation-planning)
(load (merge-pathnames "harness.lisp" (uiop:pathname-directory-pathname *load-truename*)))
(probe "F3.5b" "primitive paragraph step with a supplied target marker, target not ready, plan-tree NIL"
       '((local-links-prepared :s :t) (local-page-absent :s :t)) '((!prepare-paragraph-rendering :s :t)) :plan-tree nil)
(probe "S1" "valid primitive top-level task (local target), plan-tree T" '((local-page :s :t)) '((!prepare-local-links :s :t)))
(probe "S2" "same, plan-tree NIL" '((local-page :s :t)) '((!prepare-local-links :s :t)) :plan-tree nil)
(format t "~&PROBES-DONE~%")
