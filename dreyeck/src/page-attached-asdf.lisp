;; Registration of trusted page-attached ASDF definitions

(in-package #:dreyeck/page-attached-asdf)

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

(defun asd-registration-observation
    (asd-pathname &key name)
  "Register ASD-PATHNAME and return before/after registry evidence."
  (let* ((asd
           (truename asd-pathname))
         (before
           (systems-defined-by-asd
            asd))
         (after
           (register-asd-systems
            asd
            :name name))
         (new
           (remove-if
            (lambda (system-name)
              (member
               system-name
               before
               :test #'string=))
            after)))
    (list
     :asd asd
     :requested-system-name name
     :systems-before before
     :systems-after after
     :newly-registered-systems new)))
