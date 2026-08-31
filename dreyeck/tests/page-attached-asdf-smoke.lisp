(in-package #:dreyeck/page-attached-asdf/tests)

(defparameter *fixture-system-names*
  '("page-attached-asdf-fixture"
    "page-attached-asdf-fixture/hyperdoc"
    "page-attached-asdf-fixture/tests"))

(defun fixture-asd-pathname ()
  (asdf:system-relative-pathname
   "dreyeck/page-attached-asdf/tests"
   "dreyeck/tests/fixtures/page-attached-asdf/page-attached-asdf-fixture.asd"))

(defun decoy-asd-pathname ()
  (asdf:system-relative-pathname
   "dreyeck/page-attached-asdf/tests"
   "dreyeck/tests/fixtures/page-attached-asdf-decoy/page-attached-asdf-fixture.asd"))

(defun clear-fixture-systems ()
  (dolist
      (name
       '("page-attached-asdf-fixture/hyperdoc"
         "page-attached-asdf-fixture/tests"
         "page-attached-asdf-fixture"))
    (when
        (asdf:registered-system name)
      (asdf:clear-system name))))

(defun registered-system-source (name)
  (let ((system
          (asdf:registered-system name)))
    (and
     system
     (asdf:system-source-file system))))

(defun run-basic-registration-test ()
  (let ((asd
          (fixture-asd-pathname)))
    (clear-fixture-systems)
    (unwind-protect
        (let ((before
                (dreyeck/page-attached-asdf:systems-defined-by-asd
                 asd)))
          (assert
           (null before))
          (let* ((after
                   (dreyeck/page-attached-asdf:register-asd-systems
                    asd
                    :name
                    "page-attached-asdf-fixture"))
                 (new
                   (remove-if
                    (lambda (system-name)
                      (member
                       system-name
                       before
                       :test #'string=))
                    after)))
            (assert
             (equal
              *fixture-system-names*
              after))
            (assert
             (equal
              *fixture-system-names*
              new))
            (assert
             (every
              (lambda (name)
                (equal
                 (truename asd)
                 (truename
                  (registered-system-source
                   name))))
              *fixture-system-names*))
            t))
      (clear-fixture-systems))))

(defun run-source-authority-test ()
  (let* ((target
           (truename
            (fixture-asd-pathname)))
         (decoy
           (truename
            (decoy-asd-pathname)))
         (decoy-directory
           (uiop/pathname:pathname-directory-pathname
            decoy)))
    (clear-fixture-systems)
    (unwind-protect
        (progn
          (let ((asdf/system-registry:*central-registry*
                  (cons
                   decoy-directory
                   asdf/system-registry:*central-registry*)))
            (asdf/find-system:load-asd
             decoy
             :name
             "page-attached-asdf-fixture"))
          (assert
           (equal
            decoy
            (truename
             (registered-system-source
              "page-attached-asdf-fixture"))))
          (let ((systems-after
                  (dreyeck/page-attached-asdf:register-asd-systems
                   target
                   :name
                   "page-attached-asdf-fixture")))
            (assert
             (equal
              *fixture-system-names*
              systems-after))
            (assert
             (every
              (lambda (name)
                (equal
                 target
                 (truename
                  (registered-system-source
                   name))))
              *fixture-system-names*)))
          (dreyeck/page-attached-asdf:call-with-asd-source-authority
           target
           (lambda ()
             (assert
              (every
               (lambda (name)
                 (equal
                  target
                  (truename
                   (asdf/system:system-source-file
                    (asdf/system:find-system
                     name)))))
               *fixture-system-names*))))
          t)
      (clear-fixture-systems))))

(defun run-component-primary-asd-pathname-test ()
  (let ((target
          (truename
           (fixture-asd-pathname))))
    (clear-fixture-systems)
    (unwind-protect
        (progn
          (dreyeck/page-attached-asdf:register-asd-systems
           target
           :name
           "page-attached-asdf-fixture")
          (assert
           (every
            (lambda (name)
              (let ((system
                      (asdf:registered-system name)))
                (and
                 system
                 (equal
                  target
                  (dreyeck/page-attached-asdf:component-primary-asd-pathname
                   system)))))
            *fixture-system-names*))
          t)
      (clear-fixture-systems))))

(defun run-assets-reference-asd-pathname-test ()
  (let* ((assets-root
          (asdf/system:system-relative-pathname
           "dreyeck/page-attached-asdf/tests"
           "dreyeck/tests/fixtures/fedwiki-assets-site/assets/"))
         (expected
          (truename
           (merge-pathnames "pages/example-page/example-page.asd"
                            assets-root)))
         (actual
          (dreyeck/page-attached-asdf::asd-pathname-for-assets-reference
           assets-root "pages/example-page")))
    (assert (equal expected actual))
    t))

(DEFUN RUN-PAGE-ATTACHED-ASDF-TESTS ()
  (AND (RUN-BASIC-REGISTRATION-TEST) (RUN-SOURCE-AUTHORITY-TEST)
       (RUN-COMPONENT-PRIMARY-ASD-PATHNAME-TEST)
       (RUN-ASSETS-REFERENCE-ASD-PATHNAME-TEST)
       (AND
        (LET ((ROOT
               (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY
                "dreyeck/page-attached-asdf/tests")))
          (DREYECK/PAGE-ATTACHED-ASDF:RUN-ASD-TEST-SYSTEM-IN-FRESH-PROCESS
           (MERGE-PATHNAMES
            "dreyeck/tests/fixtures/page-attached-asdf/page-attached-asdf-prerequisite-target.asd"
            ROOT)
           "page-attached-asdf-prerequisite-target"
           "page-attached-asdf-prerequisite-target/tests"
           :PREREQUISITE-ASD-PATHNAMES
           (LIST
            (MERGE-PATHNAMES
             "dreyeck/tests/fixtures/page-attached-asdf-prerequisite/explicit-prerequisite.lisp"
             ROOT))))
        (DREYECK/PAGE-ATTACHED-ASDF:RUN-ASD-TEST-SYSTEM-IN-FRESH-PROCESS
         (FIXTURE-ASD-PATHNAME) "page-attached-asdf-fixture"
         "page-attached-asdf-fixture/tests"))))




(defun run-page-attached-asdf-tests-in-fresh-process
    ()
  "Run source-authority tests outside the enclosing ASDF TEST-OP."
  (let* ((root
           (asdf:system-source-directory
            "dreyeck/page-attached-asdf/tests"))
         (asd
           (truename
            (merge-pathnames
             "dreyeck.asd"
             root)))
         (runtime
           (namestring
            sb-ext:*runtime-pathname*))
         (command
           (list
            runtime
            "--noinform"
            "--no-userinit"
            "--disable-debugger"
            "--non-interactive"
            "--eval"
            "(require :asdf)"
            "--eval"
            (format
             nil
             "(asdf:load-asd #P~S)"
             (namestring asd))
            "--eval"
            "(asdf:load-system \"dreyeck/page-attached-asdf/tests\")"
            "--eval"
            "(unless (uiop:symbol-call :dreyeck/page-attached-asdf/tests :run-page-attached-asdf-tests) (uiop:quit 1))")))
    (uiop:run-program
     command
     :directory root
     :output *standard-output*
     :error-output *error-output*)
    t))
