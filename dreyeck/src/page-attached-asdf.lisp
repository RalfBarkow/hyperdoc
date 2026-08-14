;; Registration of trusted page-attached ASDF definitions

(in-package #:dreyeck/page-attached-asdf)

(defun systems-defined-by-asd (asd-pathname)
  "Return registered ASDF systems whose source file is ASD-PATHNAME.

This operation does not load ASD-PATHNAME.  It observes the current
ASDF registry only."
  (let ((asd (truename asd-pathname)))
    (sort
     (loop
       for name in (asdf:registered-systems)
       for system = (asdf:find-system name nil)
       for source =
         (and system
              (ignore-errors
                (asdf:system-source-file system)))
       for existing-source =
         (and source
              (probe-file source))
       when
         (and existing-source
              (equal asd
                     (truename existing-source)))
       collect name)
     #'string<)))

(defun register-asd-systems (asd-pathname)
  "Evaluate ASD-PATHNAME and return the systems it registers.

ASDF files contain executable Lisp code.  This operation is therefore
effectful and must only be used for ASD files that are trusted for
evaluation."
  (let ((asd (truename asd-pathname)))
    (asdf:load-asd asd)
    (systems-defined-by-asd asd)))

(defun asd-registration-observation (asd-pathname)
  "Register ASD-PATHNAME and return before/after evidence.

The result distinguishes systems already registered before this
operation from systems newly registered by it."
  (let* ((asd
           (truename asd-pathname))
         (before
           (systems-defined-by-asd asd))
         (after
           (register-asd-systems asd))
         (new
           (remove-if
            (lambda (name)
              (member name before :test #'string=))
            after)))
    (list
     :asd asd
     :systems-before before
     :systems-after after
     :newly-registered-systems new)))
