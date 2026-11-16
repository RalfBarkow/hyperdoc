;;;; Explicit disposable-image tests only; never a conformance executor.
(require :asdf)
(let ((root (truename (merge-pathnames "../../" (uiop:pathname-directory-pathname *load-truename*)))))
  (asdf:load-asd (merge-pathnames "dreyeck.asd" root))
  (asdf:load-asd (merge-pathnames "hyperbook.asd" root))
  (asdf:load-asd (merge-pathnames "hyperdoc.asd" root)))
(asdf:load-system "dreyeck/work/topic-maps-conformance-planning")
(let* ((root (asdf:system-source-directory "dreyeck/work/topic-maps-conformance-planning"))
       (paths '("dreyeck.asd" "dreyeck/work/topic-maps-conformance-planning.lisp"
                "dreyeck/tests/topic-maps-conformance-planning.lisp"
                "dreyeck/pages/topic-maps-conformance-planning/Planning Evidence-Based Investigations.html"))
       (before (loop for path in paths collect
                 (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 (merge-pathnames path root)))))
       (mode (or (uiop:getenv "CONFORMANCE_TEST_MODE") "focused")))
  (format t "~&INVESTIGATION TEST ENVIRONMENT ~A ~A; ~A; ~A~%"
          (lisp-implementation-type) (lisp-implementation-version) (software-type) root)
  (loop for path in paths for digest in before do (format t "~&INVESTIGATION SOURCE ~A ~A~%" digest path))
  (cond ((equal mode "focused") (asdf:test-system "dreyeck/work/topic-maps-conformance-planning"))
        ((equal mode "regressions")
         (dolist (system '("dreyeck/work/planning/tests" "dreyeck/work/defederation-planning/tests"
                           "dreyeck/work/remote-control-planning/tests"))
           (format t "~&INVESTIGATION REGRESSION START ~A~%" system)
           (asdf:test-system system)
           (format t "~&INVESTIGATION REGRESSION PASS ~A~%" system)))
        (t (error "Unknown CONFORMANCE_TEST_MODE ~S" mode)))
  (loop for path in paths for digest in before do
    (assert (equal digest (ironclad:byte-array-to-hex-string
                          (ironclad:digest-file :sha256 (merge-pathnames path root))))))
  (format t "~&INVESTIGATION RUN PASS ~A: source hashes unchanged; no conformance run or Topic Maps worktree edit.~%" mode))
