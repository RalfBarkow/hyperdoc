(in-package #:dreyeck/page-attached-hyperdoc/tests)

(defparameter *fixture-id*
  "page-attached-hyperdoc-fixture")

(defparameter *fixture-core-system*
  "page-attached-hyperdoc-fixture")

(defparameter *fixture-presentation-system*
  "page-attached-hyperdoc-fixture/presentation")

(defun fixture-asd-pathname ()
  (asdf:system-relative-pathname
   "dreyeck/page-attached-hyperdoc/tests"
   "dreyeck/tests/fixtures/page-attached-hyperdoc/page-attached-hyperdoc-fixture.asd"))

(defun remove-fixture-hyperdoc ()
  (setf
   (hyperbook:hyperbooks-of hyperdoc:*catalog*)
   (remove
    *fixture-id*
    (hyperbook:hyperbooks-of hyperdoc:*catalog*)
    :key #'hyperbook:id-of
    :test #'string=)))

(defun clear-fixture-systems ()
  (dolist
      (name
       (list
        *fixture-presentation-system*
        *fixture-core-system*))
    (when (asdf:find-system name nil)
      (asdf:clear-system name))))

(defun run-page-attached-hyperdoc-tests ()
  (clear-fixture-systems)
  (remove-fixture-hyperdoc)

  (unwind-protect
       (progn
         (asdf:load-asd
          (truename
           (fixture-asd-pathname)))

         (assert
          (null
           (hyperbook:find-hyperbook
            *fixture-id*)))

         (let* ((observation
                  (dreyeck/page-attached-hyperdoc:load-system-and-observe-hyperdocs
                   *fixture-presentation-system*))
                (new
                  (getf
                   observation
                   :newly-registered-hyperdocs))
                (hyperdoc
                  (hyperbook:find-hyperbook
                   *fixture-id*)))

           (assert
            (string=
             *fixture-presentation-system*
             (getf observation :system)))

           (assert
            (= 1
               (length new)))

           (assert
            (eq hyperdoc
                (first new)))

           (assert
            (typep
             hyperdoc
             'hyperdoc:hyperdoc))

           (assert
            (string=
             *fixture-id*
             (hyperbook:id-of hyperdoc)))

           (assert
            (string=
             *fixture-core-system*
             (asdf:component-name
              (hyperdoc:asdf-system-of
               hyperdoc))))

           ;; Re-loading an already loaded presentation system must not
           ;; create another HyperDoc in the catalog.
           (let ((second-observation
                   (dreyeck/page-attached-hyperdoc:load-system-and-observe-hyperdocs
                    *fixture-presentation-system*)))
             (assert
              (null
               (getf
                second-observation
                :newly-registered-hyperdocs))))

           t))

    (remove-fixture-hyperdoc)
    (clear-fixture-systems)))


(defun current-lisp-executable ()
  "Return the executable for starting a fresh Lisp process."
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

(defun run-page-attached-hyperdoc-tests-in-fresh-process ()
  "Run the activation test outside the current ASDF operation.

The inner process first loads the test system.  Only after that LOAD-OP
has completed does it invoke RUN-PAGE-ATTACHED-HYPERDOC-TESTS, whose
subject deliberately calls ASDF:LOAD-SYSTEM."
  (let* ((root
           (asdf:system-source-directory
            "dreyeck/page-attached-hyperdoc/tests"))
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
            "(asdf:load-system \"dreyeck/page-attached-hyperdoc/tests\")"
            "--eval"
            "(unless (uiop:symbol-call :dreyeck/page-attached-hyperdoc/tests :run-page-attached-hyperdoc-tests) (uiop:quit 1))")))
    (uiop:run-program
     command
     :directory root
     :output *standard-output*
     :error-output *error-output*)
    t))
