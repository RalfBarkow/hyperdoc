(in-package #:dreyeck/fedwiki-hyperdoc/tests)

(defparameter *fixture-slug*
  "example-hyperdoc-page")

(defparameter *fixture-core-system*
  "example-hyperdoc-page")

(defparameter *fixture-presentation-system*
  "example-hyperdoc-page/presentation")

(defparameter *fixture-test-system*
  "example-hyperdoc-page/tests")

(defun fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/fedwiki-hyperdoc/tests"
   "dreyeck/tests/fixtures/fedwiki-hyperdoc-site/"))

(defun fixture-asd-pathname ()
  (merge-pathnames
   "assets/pages/example-hyperdoc-page/example-hyperdoc-page.asd"
   (fixture-site-root)))

(defun remove-fixture-hyperdoc ()
  (setf
   (hyperbook:hyperbooks-of hyperdoc:*catalog*)
   (remove
    *fixture-slug*
    (hyperbook:hyperbooks-of hyperdoc:*catalog*)
    :key #'hyperbook:id-of
    :test #'string=)))

(defun clear-fixture-systems ()
  (dolist
      (name
       (list
        *fixture-presentation-system*
        *fixture-test-system*
        *fixture-core-system*))
    (when (asdf:find-system name nil)
      (asdf:clear-system name))))

(defun run-local-page-fedwiki-hyperdoc-test ()
  (clear-fixture-systems)
  (remove-fixture-hyperdoc)

  (unwind-protect
       (progn
         (assert
          (dreyeck/fedwiki-hyperdoc:page-attached-asdf-under-assets-root-p
           (fixture-site-root)
           (fixture-asd-pathname)))

         (assert
          (not
           (dreyeck/fedwiki-hyperdoc:page-attached-asdf-under-assets-root-p
            (fixture-site-root)
            (asdf:system-source-file
             (asdf:find-system
              "dreyeck/fedwiki-hyperdoc")))))

         (let* ((observation
                  (dreyeck/fedwiki-hyperdoc:activate-local-fedwiki-page-hyperdoc
                   (fixture-site-root)
                   *fixture-slug*))
                (discovery
                  (getf observation :discovery))
                (registration
                  (getf observation :registration))
                (activation
                  (getf observation :activation))
                (runtime-hyperdoc
                  (getf observation :runtime-hyperdoc)))

           (assert
            (string=
             *fixture-slug*
             (getf observation :slug)))

           (assert
            (= 1
               (length
                (getf discovery :asdf-files))))

           (assert
            (equal
             (list
              *fixture-core-system*
              *fixture-presentation-system*
              *fixture-test-system*)
             (getf
              observation
              :systems-defined-by-asd)))

           (assert
            (equal
             (list *fixture-presentation-system*)
             (getf
              observation
              :presentation-candidates)))

           (assert
            (string=
             *fixture-presentation-system*
             (getf
              observation
              :selected-presentation-system)))

           (assert
             (member
              runtime-hyperdoc
              (getf
               activation
               :newly-registered-hyperdocs)
              :test #'eq))

           (assert
            (typep
             runtime-hyperdoc
             'hyperdoc:hyperdoc))

           (assert
            (string=
             *fixture-slug*
             (getf
              observation
              :runtime-hyperdoc-id)))

           (assert
            (string=
             *fixture-core-system*
             (getf
              observation
              :runtime-hyperdoc-core-system)))

           (assert
            (equal
             (list
              *fixture-core-system*
              *fixture-presentation-system*
              *fixture-test-system*)
             (getf
              registration
              :systems-after)))

           ;; The complete operation is idempotent in an already activated image.
           (let* ((second-observation
                    (dreyeck/fedwiki-hyperdoc:activate-local-fedwiki-page-hyperdoc
                     (fixture-site-root)
                     *fixture-slug*))
                  (second-activation
                    (getf
                     second-observation
                     :activation)))

             (assert
              (null
               (getf
                second-activation
                :newly-registered-hyperdocs)))

             (assert
              (eq
               runtime-hyperdoc
               (getf
                second-observation
                :runtime-hyperdoc))))

           t))

    (remove-fixture-hyperdoc)
    (clear-fixture-systems)))

(defun current-lisp-executable ()
  #+sbcl
  (or
   (and sb-ext:*runtime-pathname*
        (namestring sb-ext:*runtime-pathname*))
   (uiop:argv0)
   "sbcl")
  #-sbcl
  (or
   (uiop:argv0)
   "sbcl"))

(defun run-fedwiki-hyperdoc-tests-in-fresh-process ()
  "Run the end-to-end activation contract outside the enclosing ASDF TEST-OP."
  (let* ((root
           (asdf:system-source-directory
            "dreyeck/fedwiki-hyperdoc/tests"))
         (asd
           (truename
            (merge-pathnames
             "dreyeck.asd"
             root)))
         (command
           (list
            (current-lisp-executable)
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
            "(asdf:load-system \"dreyeck/fedwiki-hyperdoc/tests\")"
            "--eval"
            "(unless (uiop:symbol-call :dreyeck/fedwiki-hyperdoc/tests :run-fedwiki-hyperdoc-tests) (uiop:quit 1))")))
    (uiop:run-program
     command
     :directory root
     :output *standard-output*
     :error-output *error-output*)
    t))

(defun assets-only-fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/fedwiki-hyperdoc/tests"
   "dreyeck/tests/fixtures/fedwiki-hyperdoc-assets-only-site/"))

(defun assets-only-fixture-page-pathname ()
  (merge-pathnames
   "pages/example-hyperdoc-page"
   (assets-only-fixture-site-root)))

(defun assets-only-fixture-asd-pathname ()
  (merge-pathnames
   "assets/pages/example-hyperdoc-page/example-hyperdoc-page.asd"
   (assets-only-fixture-site-root)))

(defun run-assets-first-fedwiki-hyperdoc-test ()
  "Activate a page-attached HyperDoc from assets without a local FedWiki page."
  (clear-fixture-systems)
  (remove-fixture-hyperdoc)

  (unwind-protect
       (progn
         ;; This is the defining precondition of the assets-first fixture.
         (assert
          (null
           (probe-file
            (assets-only-fixture-page-pathname))))

         (assert
          (probe-file
           (assets-only-fixture-asd-pathname)))

         (let* ((observation
                  (dreyeck/fedwiki-hyperdoc:activate-page-attached-hyperdoc-from-assets
                   (assets-only-fixture-site-root)
                   *fixture-slug*
                   :system-name
                   *fixture-core-system*))
                (activation
                  (getf
                   observation
                   :activation))
                (runtime-hyperdoc
                  (getf
                   observation
                   :runtime-hyperdoc)))

           (assert
            (eq
             :assets
             (getf
              observation
              :route)))

           (assert
            (equal
             (truename
              (assets-only-fixture-asd-pathname))
             (getf
              observation
              :trusted-asd)))

           (assert
            (equal
             (list
              *fixture-core-system*
              *fixture-presentation-system*
              *fixture-test-system*)
             (getf
              observation
              :systems-defined-by-asd)))

           (assert
            (equal
             (list
              *fixture-presentation-system*)
             (getf
              observation
              :presentation-candidates)))

           (assert
            (string=
             *fixture-presentation-system*
             (getf
              observation
              :selected-presentation-system)))

           (assert
            (= 1
               (length
                (getf
                 activation
                 :newly-registered-hyperdocs))))

           (assert
            (typep
             runtime-hyperdoc
             'hyperdoc:hyperdoc))

           (assert
            (string=
             *fixture-slug*
             (getf
              observation
              :runtime-hyperdoc-id)))

           (assert
            (string=
             *fixture-core-system*
             (getf
              observation
              :runtime-hyperdoc-core-system)))

           ;; The local FedWiki page remains absent throughout.
           (assert
            (null
             (probe-file
              (assets-only-fixture-page-pathname))))

           ;; The same operation is idempotent in one live image.
           (let* ((second-observation
                    (dreyeck/fedwiki-hyperdoc:activate-page-attached-hyperdoc-from-assets
                     (assets-only-fixture-site-root)
                     *fixture-slug*
                     :system-name
                     *fixture-core-system*))
                  (second-activation
                    (getf
                     second-observation
                     :activation)))

             (assert
              (null
               (getf
                second-activation
                :newly-registered-hyperdocs)))

             (assert
              (eq
               runtime-hyperdoc
               (getf
                second-observation
                :runtime-hyperdoc))))

           t))

    (remove-fixture-hyperdoc)
    (clear-fixture-systems)))

(defun run-fedwiki-hyperdoc-tests ()
  (and
   (run-local-page-fedwiki-hyperdoc-test)
   (run-assets-first-fedwiki-hyperdoc-test)))
