;;;; Run from this checkout in the prepared project environment.
;;;; nix develop -c sbcl --noinform --no-sysinit --no-userinit --non-interactive \
;;;;   --load scripts/test-welcome-development.lisp
(require :asdf)
(when (uiop:getenv "CL_SOURCE_REGISTRY")
  (asdf:initialize-source-registry
   `(:source-registry
     ,@(loop for path in (uiop:split-string (uiop:getenv "CL_SOURCE_REGISTRY") :separator ":")
             unless (zerop (length path))
               collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
     :ignore-inherited-configuration)))
(let ((root (uiop:pathname-parent-directory-pathname
             (uiop:pathname-directory-pathname *load-truename*))))
  (pushnew root asdf:*central-registry* :test #'equal)
  (asdf:load-asd (merge-pathnames "dreyeck.asd" root)))
(asdf:load-system "dreyeck/shop3")
(let ((catalog (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*))))
  (asdf:test-system "dreyeck/work/welcome-development")
  (assert (equal catalog (hyperbook:hyperbooks-of hyperbook:*catalog*)))
  (format t "~&WELCOME CATALOG PASS: opt-in load/test adds no Catalog member.~%"))
(dolist (system '("dreyeck/work/defederation-planning/tests"
                  "dreyeck/work/fedwiki-local-only/tests"))
  (format t "~&WELCOME REGRESSION ORIGIN ~A: ~A~%" system (asdf:system-source-file system))
  (asdf:test-system system)
  (format t "~&WELCOME REGRESSION PASS: ~A~%" system))
(format t "~&WELCOME-ALL-PASS: W1 only; no development action executed.~%")
