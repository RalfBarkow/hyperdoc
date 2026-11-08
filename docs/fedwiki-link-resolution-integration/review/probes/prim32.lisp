;;;; PR #32: the primitive operators that PLAN-LINK-RESOLUTION lets through (X2, X3, X5 in probes32.lisp end in the
;;;; pinned SHOP3 empty-tree TYPE-ERROR), searched here directly with :PLAN-TREE NIL to see what they would plan.
;;;; PR_TREE = an unmodified extraction of e1ab2f570ee793e301c5af706cbcf2fc984c02a9. Prints lines prefixed P32P.
(require :asdf)
(asdf:load-asd (merge-pathnames "dreyeck.asd" (uiop:ensure-directory-pathname (uiop:getenv "PR_TREE"))))
(asdf:load-system "dreyeck/work/fedwiki-link-resolution")
(in-package #:dreyeck/work/fedwiki-link-resolution)
(setf *print-pretty* nil)
(defun prim (id state tasks)
  (shop3:make-problem (list 'p32 :domain 'fedwiki-link-resolution :silently t) state tasks)
  (format t "~&P32P ~A: ~S~%" id (mapcar #'shop3:shorter-plan (shop3:find-plans 'p32 :which :all :verbose 0 :plan-tree nil)))
  (shop3:delete-problem 'p32))
(prim "X2 conclude-unresolved, no evidence" '((origin :origin)) '((!conclude-unresolved :l :target local-only)))
(prim "X3 request remote" '((origin :origin)) '((!request :l :a :target :journal)))
(prim "X5 open-panel at conflicting origin" '((origin :origin) (page-available :origin :target) (page-unavailable :origin :target 404)) '((!open-panel :l :origin :target origin)))
(prim "X6 use-modeled-page at remote, imported" '((origin :origin) (modeled-local-page :a :target)) '((!use-modeled-page :l :a :target)))
