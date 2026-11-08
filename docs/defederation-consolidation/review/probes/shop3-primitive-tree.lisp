;;;; Independent of PR #33 and of every dreyeck system: a top-level primitive task with :PLAN-TREE T in the pinned SHOP3 (K5).
;;;; Independent review of PR #33 at 7bc2fced4e970e813d870307162ec349380ca0aa (docs/defederation-consolidation/review/README.md).
;;;; Read-only with respect to the repository: plans only, no file is written, the domain and its tests are not changed.
;;;; From the repository root, with the project's ASDF registry (SBCL 2.4.10, SHOP3 ce53f9b, e.g. in `nix develop`):
;;;;   sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/shop3-primitive-tree.lisp
(require :asdf)
(asdf:load-system "shop3")
(defpackage #:primitive-tree (:use #:cl))
(in-package #:primitive-tree)
(shop3:defdomain (primitive-tree :noset t :silently t) ((:operator (!step) () () ((stepped))) (:method (wrapped) go () ((!step)))))
(dolist (case '(((!step) t) ((!step) nil) ((wrapped) t)))
  (shop3:make-problem (list 'p :domain 'primitive-tree :silently t) '((ready)) (list (first case)))
  (format t "~&PRIMITIVE-TREE task=~S plan-tree=~S -> ~A~%" (first case) (second case)
          (handler-case (format nil "raw=~S" (shop3:find-plans 'p :which :all :verbose 0 :plan-tree (second case)))
            (error (c) (format nil "ERROR ~S ~A" (type-of c) (substitute #\Space #\Newline (princ-to-string c)))))))
