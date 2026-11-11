;;;; Reproduce in a disposable SBCL, using an already prepared ASDF registry.
(require :asdf)
(require :sb-posix)
(let ((root (truename (merge-pathnames "../../../" (uiop:pathname-directory-pathname *load-truename*)))))
  (asdf:load-asd (merge-pathnames "dreyeck.asd" root))
  (asdf:load-asd (merge-pathnames "hyperbook.asd" root))
  (asdf:load-asd (merge-pathnames "hyperdoc.asd" root))
  (asdf:initialize-output-translations
   `(:output-translations
      (t ,(or (uiop:getenv "S1_FASL_CACHE")
              (namestring (merge-pathnames (format nil "s1-tree-fasls-~D/" (sb-posix:getpid))
                                           (uiop:temporary-directory)))))
      :ignore-inherited-configuration)))
(asdf:load-system "dreyeck/work/fedwiki-local-only")
(let ((catalog (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*))))
  (asdf:load-system "dreyeck/work/fedwiki-source-acquisition")
  (assert (equal catalog (hyperbook:hyperbooks-of hyperbook:*catalog*))))
(let* ((root (asdf:system-source-directory "dreyeck/work/fedwiki-source-acquisition"))
       (paths '("dreyeck.asd" "dreyeck/work/fedwiki-source-acquisition.lisp"
                "dreyeck/tests/fedwiki-source-acquisition.lisp"))
       (before (loop for path in paths collect
                 (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 (merge-pathnames path root)))))
       (mode (or (uiop:getenv "S1_TEST_MODE") "s1")))
  (format t "~&S1 TEST ENVIRONMENT: ~A ~A; ~A; ~A~%" (lisp-implementation-type)
          (lisp-implementation-version) (software-type) root)
  (loop for path in paths for digest in before do (format t "~&S1 TEST SOURCE ~A ~A~%" digest path))
  (cond
    ((equal mode "s1") (asdf:test-system "dreyeck/work/fedwiki-source-acquisition"))
    ((equal mode "regressions")
     (dolist (system '("hyperbook/fedwiki/tests" "dreyeck/fedwiki-journal/tests"
                       "dreyeck/work/fedwiki-local-only/tests"
                       "dreyeck/work/defederation-planning/tests"
                       "dreyeck/work/welcome-development/tests"))
       (format t "~&S1 REGRESSION START ~A~%" system)
       (asdf:test-system system)
       (format t "~&S1 REGRESSION PASS ~A~%" system)))
    ((equal mode "w2") (asdf:test-system "dreyeck/work/welcome-development/domain-version-tests"))
    (t (error "Unknown S1_TEST_MODE ~S" mode)))
  (loop for path in paths for digest in before do
    (assert (equal digest (ironclad:byte-array-to-hex-string
                          (ironclad:digest-file :sha256 (merge-pathnames path root))))))
  (format t "~&S1 RUN PASS ~A: source bytes unchanged; not independent verification or observed Ward acquisition.~%" mode))
