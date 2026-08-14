(in-package #:hyperdoc/tests)

(defun run-code-subdirectory-test ()
  (let ((fixture-asd
          (asdf:system-relative-pathname
           "hyperdoc"
           "tests/hyperdoc/code-subdirectory-fixture/hyperdoc-code-subdirectory-fixture.asd")))
    (asdf:load-asd (truename fixture-asd)))

  (let* ((system
           (asdf:find-system
            "hyperdoc-code-subdirectory-fixture"))
         (src-component
           (asdf:find-component system "src"))
         (source-components
           (hyperdoc::cl-source-file-components-under
            src-component))
         (hyperdoc
           (hyperdoc:make-hyperdoc
            :id "code-subdirectory-test"
            :title "Code subdirectory test"
            :asdf-system-name
            "hyperdoc-code-subdirectory-fixture"
            :subdirectory "pages"
            :code-subdirectory "src"
            :main-page-id "Main")))

    ;; Recursive ASDF source discovery.
    (assert (= 2 (length source-components)))

    (assert
     (find "package.lisp"
           source-components
           :key
           (lambda (component)
             (file-namestring
              (asdf:component-pathname component)))
           :test #'string=))

    (assert
     (find "example.lisp"
           source-components
           :key
           (lambda (component)
             (file-namestring
              (asdf:component-pathname component)))
           :test #'string=))

    ;; MAKE-HYPERDOC must use the source components as code pages.
    (assert
     (= 2
        (length
         (hyperdoc::code-pages-of hyperdoc))))

    ;; SUBDIRECTORY still denotes the independent text-page directory.
    (assert
     (equal
      (truename
       (asdf:system-relative-pathname
        "hyperdoc-code-subdirectory-fixture"
        "pages/"))
      (truename
       (hyperdoc::directory-of hyperdoc))))

    t))

(defun run-tests ()
  (run-code-subdirectory-test)
  t)
