(in-package #:dreyeck/wiki-assets-acceptance/tests)

(defparameter *wiki-assets-root* nil)

(defparameter *wiki-assets-root-environment-variable*
  "HYPERDOC_WIKI_ASSETS_ROOT")

(defun configured-wiki-assets-root ()
  "Return the explicitly configured external Wiki assets repository root."
  (let ((value
          (or *wiki-assets-root*
              (uiop:getenv
               *wiki-assets-root-environment-variable*))))
    (unless value
      (error
       "Set ~A to the Wiki assets repository root."
       *wiki-assets-root-environment-variable*))
    (let ((pathname
            (uiop:ensure-directory-pathname
             (pathname value))))
      (unless (probe-file pathname)
        (error
         "Wiki assets root does not exist: ~A"
         pathname))
      (truename pathname))))

(defun git-lines (directory &rest arguments)
  "Run Git in DIRECTORY and return its non-empty output lines."
  (remove-if
   (lambda (line)
     (zerop (length line)))
   (uiop:split-string
    (uiop:run-program
     (cons "git" arguments)
     :directory directory
     :output :string
     :error-output *error-output*)
    :separator '(#\Newline #\Return))))

(defun repository-root ()
  (asdf:system-source-directory
   "dreyeck/wiki-assets-acceptance/tests"))

(defun repository-root-asds (root)
  "Return tracked root-level ASD files from the HyperDoc repository."
  (loop
    for relative
      in (git-lines
          root
          "ls-files"
          "--"
          "*.asd")
    unless (find #\/ relative)
      collect
      (merge-pathnames
       relative
       root)))

(defun tracked-wiki-asds (assets-root)
  "Return all tracked ASD files from ASSETS-ROOT."
  (loop
    for relative
      in (git-lines
          assets-root
          "ls-files"
          "--"
          "*.asd")
    collect
    (merge-pathnames
     relative
     assets-root)))

(defun wiki-asd-form (repository-root wiki-asd)
  "Construct the isolated compile/test form for WIKI-ASD."
  (let ((root-asds
          (repository-root-asds
           repository-root)))
    `(progn
       (dolist
           (asd
            (list
             ,@(mapcar
                (lambda (pathname)
                  `(pathname
                    ,(namestring pathname)))
                root-asds)))
         (asdf:load-asd
          (truename asd)))

       (let ((wiki-asd
               (truename
                (pathname
                 ,(namestring wiki-asd)))))
         (format t
                 "~&[WIKI ASD] ~A~%"
                 wiki-asd)

         (asdf:load-asd wiki-asd)

         (let ((systems
                 (sort
                  (remove-duplicates
                   (loop
                     for name
                       in (asdf:registered-systems)
                     for system =
                       (asdf:registered-system name)
                     for source =
                       (and
                        system
                        (ignore-errors
                          (asdf:system-source-file
                           system)))
                     for true-source =
                       (and
                        source
                        (ignore-errors
                          (truename source)))
                     when
                       (and
                        true-source
                        (equal
                         true-source
                         wiki-asd))
                       collect name)
                   :test #'string=)
                  #'string<)))

           (when (null systems)
             (error
              "ASD ~A registered no systems."
              wiki-asd))

           (format t
                   "~&Systems: ~S~%"
                   systems)

           (dolist (name systems)
             (format t
                     "~&[COMPILE] ~A~%"
                     name)

             (asdf:operate
              'asdf:compile-op
              name
              :force t)

             (format t
                     "~&[TEST] ~A~%"
                     name)

             (asdf:test-system name)

             (format t
                     "~&[PASS] ~A~%"
                     name))

           (format t
                   "~&[WIKI ASD PASS] ~A~%"
                   wiki-asd)

           t)))))

(defun current-lisp-runtime-executable ()
  "Return the raw SBCL runtime for an isolated child process.

The caller already runs inside the HyperDoc Nix development environment.
Using the raw runtime preserves that environment without invoking the Nix
SBCL wrapper a second time and duplicating ASDF source-registry directives."
  #+sbcl
  (or
   (and
    sb-ext:*runtime-pathname*
    (namestring
     sb-ext:*runtime-pathname*))
   (error
    "SBCL runtime pathname is unavailable."))
  #-sbcl
  (error
   "Wiki-assets acceptance currently requires SBCL."))

(defun run-wiki-asd-in-fresh-process
    (assets-root repository-root wiki-asd)
  "Compile and test one page-attached ASD in its own Lisp process."
  (uiop:run-program
   (list
    (current-lisp-runtime-executable)
    "--noinform"
    "--no-userinit"
    "--disable-debugger"
    "--non-interactive"
    "--eval"
    "(require :asdf)"
    "--eval"
    (with-standard-io-syntax
      (let ((*package*
              (find-package
               :dreyeck/wiki-assets-acceptance/tests)))
        ;; Print lexical symbols from this package without a package prefix.
        ;; The child Lisp reads this form before this test package exists.
        (prin1-to-string
         (wiki-asd-form
          repository-root
          wiki-asd)))))
   :directory assets-root
   :output *standard-output*
   :error-output *error-output*))

(defun run-wiki-assets-acceptance-tests ()
  "Run every tracked Wiki asset ASD in an isolated Lisp process.

This function assumes that it already runs inside the HyperDoc Nix
development environment."
  (let* ((assets-root
           (configured-wiki-assets-root))
         (repository-root
           (repository-root))
         (asds
           (tracked-wiki-asds
            assets-root))
         (failures nil))

    (when (null asds)
      (error
       "No tracked ASD files found below ~A."
       assets-root))

    (format t
            "~&~%=== Wiki assets: ~D tracked ASD file~:P ===~%"
            (length asds))

    (dolist (asd asds)
      (format t
              "~&~%=== Testing ~A ===~%"
              asd)

      (handler-case
          (run-wiki-asd-in-fresh-process
           assets-root
           repository-root
           asd)

        (error (condition)
          (format
           *error-output*
           "~&[WIKI ASD FAIL] ~A~%  ~A~%"
           asd
           condition)

          (push asd failures))))

    (when failures
      (error
       "Wiki-assets failures: ~S"
       (nreverse failures)))

    (format t
            "~&~%=== WIKI ASSETS ALL PASS: ~D ASD file~:P ===~%"
            (length asds))

    t))

(defun run-wiki-assets-acceptance-tests-in-fresh-process ()
  "Run Wiki-assets acceptance from a fresh HyperDoc Nix/SBCL process."
  (let* ((repository-root
           (repository-root))
         (assets-root
           (configured-wiki-assets-root))
         (dreyeck-asd
           (truename
            (merge-pathnames
             "dreyeck.asd"
             repository-root)))
         (assets-setting
           (format nil
                   "~A=~A"
                   *wiki-assets-root-environment-variable*
                   (namestring assets-root)))
         (command
           (list
            "/usr/bin/env"
            "-u" "CL_SOURCE_REGISTRY"
            "-u" "ASDF_OUTPUT_TRANSLATIONS"
            "-u" "SBCL_HOME"
            "-u" "DEVELOPER_DIR"
            assets-setting
            "nix"
            "develop"
            (namestring repository-root)
            "-c"
            "sbcl"
            "--noinform"
            "--no-userinit"
            "--disable-debugger"
            "--non-interactive"
            "--eval"
            "(require :asdf)"
            "--eval"
            (format nil
                    "(asdf:load-asd #P~S)"
                    (namestring dreyeck-asd))
            "--eval"
            "(asdf:load-system \"dreyeck/wiki-assets-acceptance/tests\")"
            "--eval"
            "(unless (uiop:symbol-call :dreyeck/wiki-assets-acceptance/tests :run-wiki-assets-acceptance-tests) (uiop:quit 1))")))

    (uiop:run-program
     command
     :directory repository-root
     :output *standard-output*
     :error-output *error-output*)

    t))
