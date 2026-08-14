(in-package #:dreyeck/local-fedwiki-page/tests)

(defparameter *fixture-slug*
  "example-hyperdoc-page")

(defparameter *fixture-system-names*
  '("example-hyperdoc-page"
    "example-hyperdoc-page/presentation"
    "example-hyperdoc-page/tests"))

(defun fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/local-fedwiki-page/tests"
   "dreyeck/tests/fixtures/fedwiki-hyperdoc-site/"))

(defun clear-fixture-systems ()
  (dolist (name *fixture-system-names*)
    (when (asdf:registered-system name)
      (asdf:clear-system name))))

(defun fixture-systems-registered-p ()
  (some
   #'asdf:registered-system
   *fixture-system-names*))

(defun run-local-fedwiki-page-tests ()
  (clear-fixture-systems)

  (unwind-protect
       (let* ((wiki
                (make-instance
                 'hyperbook/fedwiki::fedwiki
                 :id "fedwiki:local-fixture.invalid"))
              (page
                (dreyeck/local-fedwiki-page:make-local-fedwiki-page
                 (fixture-site-root)
                 wiki
                 *fixture-slug*))
              (discovery
                (dreyeck/local-fedwiki-page:local-fedwiki-page-asdf-discovery
                 page)))

         (assert
          (typep
           page
           'dreyeck/local-fedwiki-page:local-fedwiki-page))

         (assert
          (typep
           page
           'hyperbook/fedwiki::fedwiki-page))

         (assert
          (equal
           (truename
            (fixture-site-root))
           (dreyeck/local-fedwiki-page:local-fedwiki-page-site-root-of
            page)))

         (assert
          (string=
           *fixture-slug*
           (hyperbook:id-of page)))

         (assert
          (string=
           "Example HyperDoc Page"
           (hyperbook:title-of page)))

         (assert
          (equal
           '(:paragraph :assets)
           (map
            'list
            #'hyperbook/fedwiki::item-type-of
            (hyperbook/fedwiki::story-of page))))

         (assert
          (equal
           '("pages/example-hyperdoc-page")
           (getf discovery :assets-references)))

         (assert
          (= 1
             (length
              (getf discovery :asdf-files))))

         ;; Discovery alone must not register the page-attached ASD systems.
         (assert
          (not
           (fixture-systems-registered-p)))

         ;; The ordinary inherited FedWiki Story view remains usable.
         (let* ((story-view
                  (hyperbook/fedwiki::👀story page))
                (story-html
                  (html-inspector-views:view-html
                   story-view)))
           (assert
            (plusp
             (length story-html)))
           (assert
            (search
             "Example HyperDoc Page"
             story-html
             :test #'char-equal))
           (assert
            (search
             "End-to-end FedWiki HyperDoc fixture."
             story-html
             :test #'char-equal)))

         ;; The Dreyeck extension is also renderable.
         (let* ((view
                  (dreyeck/local-fedwiki-page/inspector::👀page-attached-asdf
                   page))
                (html
                  (html-inspector-views:view-html
                   view)))
           (assert
            (plusp
             (length html)))
           (assert
            (search
             "example-hyperdoc-page.asd"
             html
             :test #'char-equal))
           (assert
            (search
             "Not performed by this view; discovery is read-only."
             html
             :test #'char-equal)))

         ;; Rendering the inspector view must still not evaluate the ASD.
         (assert
          (not
           (fixture-systems-registered-p)))

         t)

    (clear-fixture-systems)))

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

(defun run-local-fedwiki-page-tests-in-fresh-process ()
  "Run the local FedWiki provenance and inspector contract in a fresh Lisp."
  (let* ((root
           (asdf:system-source-directory
            "dreyeck/local-fedwiki-page/tests"))
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
            "(asdf:load-system \"dreyeck/local-fedwiki-page/tests\")"
            "--eval"
            "(unless (uiop:symbol-call :dreyeck/local-fedwiki-page/tests :run-local-fedwiki-page-tests) (uiop:quit 1))")))
    (uiop:run-program
     command
     :directory root
     :output *standard-output*
     :error-output *error-output*)
    t))
