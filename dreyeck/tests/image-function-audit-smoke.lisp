(defun dreyeck/image-audit/tests::run-image-function-audit-model-test ()
  (let* ((current '(("TEST-PACKAGE" "A") ("TEST-PACKAGE" "B")))
         (reconstructed '(("TEST-PACKAGE" "B")))
         (audit
          (dreyeck/image-audit:make-image-function-audit "TEST-PACKAGE"
                                                         '("test/system")
                                                         current
                                                         reconstructed))
         (image-only
          (dreyeck/image-audit:image-function-audit-image-only-function-coordinates-of
           audit)))
    (assert (typep audit 'dreyeck/image-audit:image-function-audit))
    (assert
     (string= "TEST-PACKAGE"
              (dreyeck/image-audit:image-function-audit-audited-package-of
               audit)))
    (assert
     (equal '("test/system")
            (dreyeck/image-audit:image-function-audit-reconstruction-systems-of
             audit)))
    (assert
     (equal current
            (dreyeck/image-audit:image-function-audit-current-function-coordinates-of
             audit)))
    (assert
     (equal reconstructed
            (dreyeck/image-audit:image-function-audit-reconstructed-function-coordinates-of
             audit)))
    (assert (= 1 (length image-only)))
    (assert (member '("TEST-PACKAGE" "A") image-only :test #'equal))
    (assert (not (member '("TEST-PACKAGE" "B") image-only :test #'equal)))
    t))

(defun dreyeck/image-audit/tests::run-image-function-audit-reconstruction-test
       ()
  (let* ((systems '("dreyeck/issue" "dreyeck/shop3"))
         (audit
          (dreyeck/image-audit:audit-package-functions "CL-USER" systems)))
    (assert (typep audit 'dreyeck/image-audit:image-function-audit))
    (assert
     (string= "CL-USER"
              (dreyeck/image-audit:image-function-audit-audited-package-of
               audit)))
    (assert
     (equal systems
            (dreyeck/image-audit:image-function-audit-reconstruction-systems-of
             audit)))
    (assert
     (null
      (dreyeck/image-audit:image-function-audit-current-function-coordinates-of
       audit)))
    (assert
     (null
      (dreyeck/image-audit:image-function-audit-reconstructed-function-coordinates-of
       audit)))
    (assert
     (null
      (dreyeck/image-audit:image-function-audit-image-only-function-coordinates-of
       audit)))
    (let* ((dreyeck/image-audit/tests::root
        (asdf/system:system-source-directory "dreyeck/image-audit/tests"))
       (dreyeck/image-audit/tests::prerequisite
        (merge-pathnames
         "dreyeck/tests/fixtures/image-audit-prerequisite/explicit-prerequisite.lisp"
         dreyeck/image-audit/tests::root))
       (dreyeck/image-audit/tests::system "image-audit-prerequisite-fixture")
       (dreyeck/image-audit/tests::coordinate
        (list (package-name (find-package "CL-USER"))
              "IMAGE-AUDIT-PREREQUISITE-FIXTURE-FUNCTION")))
  (assert
   (null (asdf/system:find-system dreyeck/image-audit/tests::system nil)))
  (let ((dreyeck/image-audit/tests::audit
         (dreyeck/image-audit:audit-package-functions "CL-USER"
                                                      (list
                                                       dreyeck/image-audit/tests::system)
                                                      :prerequisite-asd-pathnames
                                                      (list
                                                       dreyeck/image-audit/tests::prerequisite))))
    (assert
     (member dreyeck/image-audit/tests::coordinate
             (dreyeck/image-audit:image-function-audit-reconstructed-function-coordinates-of
              dreyeck/image-audit/tests::audit)
             :test #'equal)))
  t)))

(defun dreyeck/image-audit/tests:run-image-function-audit-tests ()
  (and (dreyeck/image-audit/tests::run-image-function-audit-model-test)
       (dreyeck/image-audit/tests::run-image-function-audit-reconstruction-test)))

(defun dreyeck/image-audit/tests:run-image-function-audit-tests-in-fresh-process
       ()
  "Run image function audit tests in a fresh Lisp process."
  (let* ((dreyeck/image-audit/tests::root
          (asdf/system:system-source-directory "dreyeck/image-audit/tests"))
         (dreyeck/image-audit/tests::asd
          (truename
           (merge-pathnames "dreyeck.asd" dreyeck/image-audit/tests::root)))
         (dreyeck/image-audit/tests::command
          (list (dreyeck/image-audit::current-lisp-executable) "--noinform"
                "--no-userinit" "--disable-debugger" "--non-interactive"
                "--eval" "(require :asdf)" "--eval"
                (format nil "(asdf:load-asd #P~S)"
                        (namestring dreyeck/image-audit/tests::asd))
                "--eval" "(asdf:load-system \"dreyeck/image-audit/tests\")"
                "--eval"
                "(unless (uiop:symbol-call :dreyeck/image-audit/tests :run-image-function-audit-tests) (uiop:quit 1))")))
    (uiop/run-program:run-program dreyeck/image-audit/tests::command :directory
                                  dreyeck/image-audit/tests::root :output
                                  *standard-output* :error-output
                                  *error-output*)
    t))
