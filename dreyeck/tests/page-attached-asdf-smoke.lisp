(in-package #:dreyeck/page-attached-asdf/tests)

(defparameter *fixture-system-names*
  '("page-attached-asdf-fixture"
    "page-attached-asdf-fixture/hyperdoc"
    "page-attached-asdf-fixture/tests"))

(defun fixture-asd-pathname ()
  (asdf:system-relative-pathname
   "dreyeck/page-attached-asdf/tests"
   "dreyeck/tests/fixtures/page-attached-asdf/page-attached-asdf-fixture.asd"))

(defun clear-fixture-systems ()
  (dolist
      (name
       '("page-attached-asdf-fixture/hyperdoc"
         "page-attached-asdf-fixture/tests"
         "page-attached-asdf-fixture"))
    (when (asdf:find-system name nil)
      (asdf:clear-system name))))

(defun run-page-attached-asdf-tests ()
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
                    asd)))

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
                   (asdf:system-source-file
                    (asdf:find-system name)))))
               *fixture-system-names*)))

           t)
      (clear-fixture-systems))))
