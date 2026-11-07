;;;; Fresh fixture process; use the project's prepared ASDF dependency registry.
;;;; nix develop -c sbcl --noinform --no-sysinit --no-userinit --non-interactive \
;;;;   --load scripts/test-defederation-planning.lisp
(require :asdf)

;; Match the repository's executable convention for Nix's colon-form registry.
(when (uiop:getenv "CL_SOURCE_REGISTRY")
  (asdf:initialize-source-registry
   `(:source-registry
     ,@(loop for path in (uiop:split-string (uiop:getenv "CL_SOURCE_REGISTRY")
                                          :separator ":")
             unless (zerop (length path))
               collect `(:tree ,(uiop:ensure-directory-pathname
                                (string-right-trim "/" path))))
     :ignore-inherited-configuration)))

(let ((root (uiop:pathname-parent-directory-pathname
             (uiop:pathname-directory-pathname *load-truename*))))
  (pushnew root asdf:*central-registry* :test #'equal)
  (asdf:load-asd (merge-pathnames "dreyeck.asd" root)))

(asdf:load-system "dreyeck/shop3")
(let ((catalog-before (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*))))
  (asdf:test-system "dreyeck/work/defederation-planning")
  (assert (equal catalog-before (hyperbook:hyperbooks-of hyperbook:*catalog*)))
  (format t "~&DEFEDERATION-CATALOG-PASS: opt-in load/test adds no Catalog member.~%"))

(dolist (system '("dreyeck/work/planning/tests"
                  "dreyeck/work/remote-control-planning/tests"
                  "dreyeck/wiki-link/tests"))
  (asdf:test-system system)
  (format t "~&DEFEDERATION-REGRESSION-PASS: ~A~%" system))

(format t "~&DEFEDERATION-ALL-PASS: planning only; no planned action executed.~%")
