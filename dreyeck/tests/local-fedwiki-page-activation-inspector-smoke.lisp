(in-package #:dreyeck/local-fedwiki-page/activation-inspector/tests)

(defparameter *fixture-slug*
  "example-hyperdoc-page")

(defparameter *fixture-system-names*
  '("example-hyperdoc-page"
    "example-hyperdoc-page/presentation"
    "example-hyperdoc-page/tests"))

(defun fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/local-fedwiki-page/activation-inspector/tests"
   "dreyeck/tests/fixtures/fedwiki-hyperdoc-site/"))

(defun clear-fixture-systems ()
  (dolist (name *fixture-system-names*)
    (when (asdf:registered-system name)
      (asdf:clear-system name))))

(defun fixture-systems-registered-p ()
  (some
   #'asdf:registered-system
   *fixture-system-names*))

(defun all-fixture-systems-registered-p ()
  (every
   #'asdf:registered-system
   *fixture-system-names*))

(defun assert-activation-observation (observation)
  (assert
   (string=
    *fixture-slug*
    (getf observation :slug)))

  (assert
   (string=
    "example-hyperdoc-page/presentation"
    (getf observation :selected-presentation-system)))

  (assert
   (string=
    *fixture-slug*
    (getf observation :runtime-hyperdoc-id)))

  (assert
   (string=
    *fixture-slug*
    (getf observation :runtime-hyperdoc-core-system)))

  observation)

(defun run-local-fedwiki-page-activation-inspector-tests ()
  (clear-fixture-systems)

  (let* ((wiki
           (make-instance
            'hyperbook/fedwiki::fedwiki
            :id "fedwiki:local-fixture.invalid"))
         (page
           (dreyeck/local-fedwiki-page:make-local-fedwiki-page
            (fixture-site-root)
            wiki
            *fixture-slug*)))

    ;; Merely constructing the local page must remain read-only.
    (assert
     (not
      (fixture-systems-registered-p)))

    (assert
     (null
      (hyperbook:find-hyperbook
       *fixture-slug*)))

    ;; Rendering the object-specific action bar must not activate anything.
    (let* ((actions
             (html-inspector-views:title-bar-action-buttons
              page))
           (html
             (html-inspector-views:view-html
              actions)))

      (assert
       (search
        "Activate page-attached HyperDoc"
        html
        :test #'char-equal))

      ;; LOCAL-FEDWIKI-PAGE must not inherit FEDWIKI-PAGE's network reload.
      (assert
       (null
        (search
         "Reload"
         html
         :test #'char-equal))))

    (assert
     (not
      (fixture-systems-registered-p)))

    (assert
     (null
      (hyperbook:find-hyperbook
       *fixture-slug*)))

    ;; First explicit activation crosses the C.1 trust/effect boundary.
    (let ((first
            (dreyeck/local-fedwiki-page/inspector::activate-page-attached-hyperdoc
             page)))

      (assert-activation-observation
       first)

      (assert
       (all-fixture-systems-registered-p))

      (let ((hyperdoc
	       (hyperbook:find-hyperbook
		*fixture-slug*)))

	 (assert hyperdoc)

	 (assert
	  (typep
	   hyperdoc
	   'hyperdoc:hyperdoc))

	 (assert
	  (string=
	   *fixture-slug*
	   (hyperbook:id-of hyperdoc)))

	 ;; The presentation system must bring in enough of the HyperDoc
	 ;; runtime for its main page to be resolved without an additional
	 ;; manual LOAD-SYSTEM of HYPERDOC/EXPLORER.
	 (let* ((main-page-id
		  (hyperbook:main-page-id-of
		   hyperdoc))
		(main-page
		  (hyperbook:find-page
		   hyperdoc
		   main-page-id)))

	   (assert
	    (string=
	     "Example HyperDoc Page"
	     main-page-id))

	   (assert main-page)

	   (assert
	    (typep
	     main-page
	     'hyperdoc::page)))

	 ;; Constructing the Inspector view set must likewise succeed from
	 ;; the declared presentation-system runtime closure.
	 (assert
	  (html-inspector-views:all-views
	   hyperdoc)))

      ;; A second explicit activation must remain valid and identify the
      ;; same logical page-attached HyperDoc.
      (let ((second
              (dreyeck/local-fedwiki-page/inspector::activate-page-attached-hyperdoc
               page)))

        (assert-activation-observation
         second)

        (assert
         (string=
          (getf first :runtime-hyperdoc-id)
          (getf second :runtime-hyperdoc-id)))

        (assert
         (string=
          (getf first :selected-presentation-system)
          (getf second :selected-presentation-system)))

        (assert
         (string=
          (getf first :runtime-hyperdoc-core-system)
          (getf second :runtime-hyperdoc-core-system)))

        (assert
         (hyperbook:find-hyperbook
          *fixture-slug*))))

    t))

(defun current-lisp-executable ()
  #+sbcl
  (or
   (and
    sb-ext:*runtime-pathname*
    (namestring
     sb-ext:*runtime-pathname*))
   (uiop:argv0)
   "sbcl")
  #-sbcl
  (or
   (uiop:argv0)
   "sbcl"))

(defun run-local-fedwiki-page-activation-inspector-tests-in-fresh-process ()
  "Run the explicit local FedWiki HyperDoc activation contract in a fresh Lisp."
  (let* ((root
           (asdf:system-source-directory
            "dreyeck/local-fedwiki-page/activation-inspector/tests"))
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
            "(asdf:load-system \"dreyeck/local-fedwiki-page/activation-inspector/tests\")"
            "--eval"
            "(unless (uiop:symbol-call :dreyeck/local-fedwiki-page/activation-inspector/tests :run-local-fedwiki-page-activation-inspector-tests) (uiop:quit 1))")))

    (uiop:run-program
     command
     :directory root
     :output *standard-output*
     :error-output *error-output*)

    t))
