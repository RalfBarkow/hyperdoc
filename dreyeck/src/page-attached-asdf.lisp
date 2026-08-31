;; Registration of trusted page-attached ASDF definitions

(in-package #:dreyeck/page-attached-asdf)

(defun asd-pathname-for-assets-reference
       (common-lisp-user::assets-root common-lisp-user::assets-reference)
  (let ((common-lisp-user::name
         (pathname-name (pathname common-lisp-user::assets-reference))))
    (truename
     (merge-pathnames
      (format nil "~A/~A.asd" common-lisp-user::assets-reference
              common-lisp-user::name)
      common-lisp-user::assets-root))))

(defun systems-defined-by-asd (asd-pathname)
  "Return systems currently registered from ASD-PATHNAME.

This operation observes ASDF's existing registration table only.
It deliberately uses ASDF:REGISTERED-SYSTEM rather than
ASDF:FIND-SYSTEM, because FIND-SYSTEM may re-resolve a same-named
system through the configured system-definition search machinery."
  (let ((asd
          (truename asd-pathname)))
    (sort
     (loop
       for name in (asdf:registered-systems)
       for system = (asdf:registered-system name)
       for source =
         (and system
              (ignore-errors
                (asdf:system-source-file system)))
       for existing-source =
         (and source
              (probe-file source))
       when
         (and existing-source
              (equal
               asd
               (truename existing-source)))
       collect name)
     #'string<)))

(defun call-with-asd-source-authority
    (asd-pathname function)
  "Call FUNCTION while ASD-PATHNAME's directory has ASDF search priority.

The binding is dynamic and limited to FUNCTION.  It prevents a
same-named system found elsewhere in the inherited ASDF source
configuration from displacing the explicitly selected page-attached ASD
during the materialization operation."
  (let* ((asd
           (truename asd-pathname))
         (directory
           (uiop:pathname-directory-pathname
            asd))
         (asdf:*central-registry*
           (cons
            directory
            asdf:*central-registry*)))
    (funcall function)))

(defun component-primary-asd-pathname
    (system)
  (let* ((root
           (asdf:component-pathname system))
         (primary-name
           (asdf/system:primary-system-name
            (asdf:component-name system))))
    (truename
     (merge-pathnames
      (make-pathname
       :name primary-name
       :type "asd")
      root))))

(defun register-asd-systems
    (asd-pathname &key name)
  "Evaluate trusted ASD-PATHNAME and return the systems it registers.

NAME, when supplied, is the expected primary ASDF system name.
The actual registration evidence is read directly from ASDF's
registration table and does not invoke FIND-SYSTEM."
  (let ((asd
          (truename asd-pathname)))
    (call-with-asd-source-authority
     asd
     (lambda ()
       (if name
           (asdf:load-asd
            asd
            :name name)
           (asdf:load-asd
            asd))

       (let ((systems
               (systems-defined-by-asd
                asd)))
         (when
             (and name
                  (not
                   (member
                    name
                    systems
                    :test #'string-equal)))
           (error
            "ASD ~A did not register expected primary system ~S. Registered systems from that ASD: ~S"
            asd
            name
            systems))
         systems)))))



(defun run-asd-test-system-in-fresh-process
    (asd-pathname primary-system-name test-system-name &key
 (prerequisite-asd-pathnames nil))
  "Run TEST-SYSTEM-NAME in a fresh SBCL process with ASD-PATHNAME authoritative."
  (let* ((asd
           (truename asd-pathname))
         (root
           (uiop:pathname-directory-pathname
            asd))
         (runtime
           (namestring
            sb-ext:*runtime-pathname*))
         (child-form
           `(let ((asdf:*central-registry*
                    (cons
                     ,root
                     asdf:*central-registry*)))
              (asdf:load-asd
               ,asd
               :name
               ,primary-system-name)
              (let* ((cl-user::system
                       (or
                        (asdf:registered-system
                         ,test-system-name)
                        (error
                         "ASDF system ~S was not registered by ~A."
                         ,test-system-name
                         ,asd)))
                     (cl-user::source
                       (asdf:system-source-file
                        cl-user::system)))
                (unless
                    (and
                     cl-user::source
                     (equal
                      ,asd
                      (truename
                       cl-user::source)))
                  (error
                   "System ~A resolved from ~A instead of ~A."
                   ,test-system-name
                   cl-user::source
                   ,asd))
                (asdf:test-system
                 cl-user::system)))))
    (uiop:run-program
     (append
 (list runtime "--noinform" "--no-userinit" "--disable-debugger"
       "--non-interactive" "--eval" "(require :asdf)")
 (mapcan
  (lambda (prerequisite-asd-pathname)
    (list "--eval"
          (format nil "(asdf:load-asd #P~S)"
                  (namestring (truename prerequisite-asd-pathname)))))
  prerequisite-asd-pathnames)
 (list "--eval" (prin1-to-string child-form)))
     :directory root
     :output *standard-output*
     :error-output *error-output*)
    t))
