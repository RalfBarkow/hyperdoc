;;;; Disposable SBCL image; see docs/welcome-development/w2-implementation.md.
(require :asdf)
(let ((root (uiop:pathname-parent-directory-pathname
             (uiop:pathname-directory-pathname *load-truename*))))
  (pushnew root asdf:*central-registry* :test #'equal)
  (asdf:load-asd (merge-pathnames "dreyeck.asd" root)))
(asdf:load-system "dreyeck/shop3")
(let ((catalog (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*))))
  (asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")
  (assert (equal catalog (hyperbook:hyperbooks-of hyperbook:*catalog*))))
(let ((mode (uiop:getenv "W2_MODE")))
  (cond ((equal mode "identity")
         (uiop:symbol-call :dreyeck/work/welcome-development :w2-identity)
         (uiop:symbol-call :dreyeck/work/welcome-development :r1-canonical-identity))
        ((equal mode "fixture")
         (uiop:symbol-call :dreyeck/work/welcome-development :w2-test-transient)
         (uiop:symbol-call :dreyeck/work/welcome-development :w2-test-provenance
                          (uiop:symbol-call :dreyeck/work/welcome-development :welcome-development-demo :p2))
         (format t "~&A13 FIXTURE PASS: syscall/exec audit separately verifies no network/Git.~%"))
        ((equal mode "replay")
         (let* ((repository (make-instance 'dreyeck/git:git-repository-checkout
                                          :root (uiop:ensure-directory-pathname (uiop:getenv "W2_REPLAY_REPO")) :root-source :w2-disposable-test))
                (records (uiop:symbol-call :dreyeck/work/welcome-development :w2-observed-journal
                                          repository (uiop:getenv "W2_REPLAY_COMMIT"))))
           (uiop:symbol-call :dreyeck/work/welcome-development :w2-test-provenance
                            (uiop:symbol-call :dreyeck/work/welcome-development :development-workflow records) t)
           (format t "~&A5 REPLAY PASS: existing tags only; audit read-only Git and network syscalls separately.~%")))
        (t (asdf:test-system "dreyeck/work/welcome-development/domain-version-tests"))))
