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
         (progn
           (assert
            (null
             (dreyeck/page-attached-asdf:systems-defined-by-asd
              asd)))

           (let ((observation
                   (dreyeck/page-attached-asdf:asd-registration-observation
                    asd
                    :name "page-attached-asdf-fixture")))

             (assert
              (null
               (getf observation :systems-before)))

             (assert
              (equal
               *fixture-system-names*
               (getf observation :systems-after)))

             (assert
              (equal
               *fixture-system-names*
               (getf observation :newly-registered-systems)))

             (assert
              (every
               (lambda (name)
                 (equal
                  (truename asd)
                  (truename
                   (registered-system-source name))))
               *fixture-system-names*)))

           t)

      (clear-fixture-systems))))

(defun run-source-authority-test ()
  (let* ((target
           (truename
            (fixture-asd-pathname)))
         (decoy
           (truename
            (decoy-asd-pathname)))
         (decoy-directory
           (uiop:pathname-directory-pathname
            decoy)))

    (clear-fixture-systems)

    (unwind-protect
         (progn

           ;; Establish the deliberately wrong source authority first.
           (let ((asdf:*central-registry*
                   (cons
                    decoy-directory
                    asdf:*central-registry*)))

             (asdf:load-asd
              decoy
              :name "page-attached-asdf-fixture"))

           (assert
            (equal
             decoy
             (truename
              (registered-system-source
               "page-attached-asdf-fixture"))))

           ;; The explicitly selected target ASD must now take authority.
           (let ((observation
                   (dreyeck/page-attached-asdf:asd-registration-observation
                    target
                    :name "page-attached-asdf-fixture")))

             (assert
              (equal
               *fixture-system-names*
               (getf observation :systems-after)))

             (assert
              (every
               (lambda (name)
                 (equal
                  target
                  (truename
                   (registered-system-source name))))
               *fixture-system-names*)))

           ;; FIND-SYSTEM must also resolve to the target while inside
           ;; the explicit page-attached source-authority boundary.
           (dreyeck/page-attached-asdf:call-with-asd-source-authority
            target
            (lambda ()
              (assert
               (every
                (lambda (name)
                  (equal
                   target
                   (truename
                    (asdf:system-source-file
                     (asdf:find-system name)))))
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

(defun run-page-attached-asdf-tests
    ()
  (and
   (run-basic-registration-test)
   (run-source-authority-test)
   (run-component-primary-asd-pathname-test)
   (dreyeck/page-attached-asdf:run-asd-test-system-in-fresh-process
    (fixture-asd-pathname)
    "page-attached-asdf-fixture"
    "page-attached-asdf-fixture/tests")))




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
