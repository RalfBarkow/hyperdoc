;;;; Focused smoke tests for read-only FedWiki ASDF asset discovery.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-FEDWIKI-ASDF-DISCOVERY-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun fedwiki-asdf-discovery-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual))
  actual)

(defun fedwiki-asdf-discovery-assert-true (value message)
  (unless value
    (error "~A" message))
  value)

(defun fedwiki-asdf-discovery-temp-site-root ()
  (let ((root
          (merge-pathnames
           (format nil "hyperdoc-fedwiki-asdf-discovery-~D-~D/"
                   (get-universal-time)
                   (random 1000000))
           (uiop:temporary-directory))))
    (ensure-directories-exist (merge-pathnames "assets/.root" root))
    root))

(defmacro with-fedwiki-asdf-discovery-site-root ((root) &body body)
  `(let ((,root (fedwiki-asdf-discovery-temp-site-root)))
     (unwind-protect
          (progn ,@body)
       (uiop:delete-directory-tree
        ,root :validate t :if-does-not-exist :ignore))))

(defun fedwiki-asdf-discovery-story-item (type id text)
  (make-instance 'hyperbook/fedwiki::story-item
                 :item-type type
                 :id id
                 :text text
                 :data (make-hash-table :test #'equal)))

(defun fedwiki-asdf-discovery-page (slug title &rest story-items)
  (let* ((wiki
           (make-instance 'hyperbook/fedwiki::fedwiki
                          :id "fedwiki:wiki.example.test"))
         (page (hyperbook/fedwiki::make-fedwiki-page wiki slug title)))
    (setf (slot-value page 'hyperbook/fedwiki::story)
          (coerce story-items 'vector))
    page))

(defun fedwiki-asdf-discovery-assets-item (id text)
  (fedwiki-asdf-discovery-story-item :assets id text))

(defun fedwiki-asdf-discovery-asset-root (site-root reference)
  (merge-pathnames
   (uiop:ensure-directory-pathname reference)
   (merge-pathnames "assets/" site-root)))

(defun fedwiki-asdf-discovery-ensure-asset-root (site-root reference)
  (let ((root (fedwiki-asdf-discovery-asset-root site-root reference)))
    (ensure-directories-exist (merge-pathnames ".root" root))
    root))

(defun fedwiki-asdf-discovery-write-file (pathname contents)
  (ensure-directories-exist pathname)
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string contents stream))
  pathname)

(defun fedwiki-asdf-discovery-create-symbolic-link (target link)
  (require :sb-posix)
  (ensure-directories-exist link)
  (uiop:symbol-call :sb-posix :symlink
                    (uiop:native-namestring target)
                    (uiop:native-namestring link))
  link)

(defun fedwiki-asdf-discovery-single-item (result)
  (first (hyperdoc:fedwiki-asdf-asset-discovery-assets-items result)))

(defun fedwiki-asdf-discovery-candidate-pathnames (candidate)
  (mapcar (lambda (record) (getf record :pathname))
          (hyperdoc:fedwiki-asdf-asset-candidate-asd-candidates candidate)))

(defun fedwiki-asdf-discovery-discover (page site-root)
  (hyperdoc:discover-fedwiki-asdf-asset-candidates
   page :site-root site-root))

(defun run-fedwiki-asdf-discovery-no-assets-item-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((page
             (fedwiki-asdf-discovery-page
              "plain-page" "Plain page"
              (fedwiki-asdf-discovery-story-item
               :paragraph "paragraph-1" "No assets here.")))
           (result (fedwiki-asdf-discovery-discover page site-root)))
      (fedwiki-asdf-discovery-assert-equal
       :discovery-complete
       (hyperdoc:fedwiki-asdf-asset-discovery-completion-status result)
       "The story scan must complete")
      (fedwiki-asdf-discovery-assert-equal
       :no-assets-item
       (hyperdoc:fedwiki-asdf-asset-discovery-assets-item-cardinality result)
       "The page must retain the absence of Assets items")
      (fedwiki-asdf-discovery-assert-equal
       '(:not-observed :not-observed :not-observed)
       (list (hyperdoc:fedwiki-asdf-asset-discovery-reference-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-resolution-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result))
       "Later discovery dimensions must remain unobserved"))))

(defun run-fedwiki-asdf-discovery-missing-directory-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((reference "pages/separate-asset")
           (page
             (fedwiki-asdf-discovery-page
              "page-slug" "Page title"
              (fedwiki-asdf-discovery-assets-item
               "assets-1" " pages/separate-asset ")))
           (result (fedwiki-asdf-discovery-discover page site-root)))
      (fedwiki-asdf-discovery-assert-equal
       reference
       (hyperdoc:fedwiki-asdf-asset-discovery-asset-reference result)
       "The normalized reference must come from the story item")
      (fedwiki-asdf-discovery-assert-equal
       '(:valid-asset-reference :asset-root-missing :not-observed)
       (list (hyperdoc:fedwiki-asdf-asset-discovery-reference-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-resolution-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result))
       "Reference, resolution, and candidate states must remain separate")
      (fedwiki-asdf-discovery-assert-equal
       (fedwiki-asdf-discovery-asset-root site-root reference)
       (hyperdoc:fedwiki-asdf-asset-discovery-resolved-asset-root result)
       "The missing root must retain its deployment pathname"))))

(defun run-fedwiki-asdf-discovery-invalid-and-outside-reference-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((outside-root
             (fedwiki-asdf-discovery-ensure-asset-root
              site-root "../outside-assets"))
           (link
             (merge-pathnames "assets/pages/link-out" site-root)))
      (ensure-directories-exist (merge-pathnames "assets/pages/.root" site-root))
      (fedwiki-asdf-discovery-create-symbolic-link outside-root link)
      (let* ((page
               (fedwiki-asdf-discovery-page
                "page-slug" "Page title"
                (fedwiki-asdf-discovery-assets-item "assets-empty" "  ")
                (fedwiki-asdf-discovery-assets-item "assets-absolute" "/tmp/outside")
                (fedwiki-asdf-discovery-assets-item "assets-parent" "pages/../../outside")
                (fedwiki-asdf-discovery-assets-item "assets-link" "pages/link-out")))
             (result (fedwiki-asdf-discovery-discover page site-root))
             (items
               (hyperdoc:fedwiki-asdf-asset-discovery-assets-items result)))
        (fedwiki-asdf-discovery-assert-equal
         :multiple-assets-items
         (hyperdoc:fedwiki-asdf-asset-discovery-assets-item-cardinality result)
         "All rejected Assets items must remain separately observed")
        (fedwiki-asdf-discovery-assert-equal
         '(:invalid-asset-reference :invalid-asset-reference
           :invalid-asset-reference :valid-asset-reference)
         (mapcar #'hyperdoc:fedwiki-asdf-asset-candidate-reference-status items)
         "Syntactic validity must be separate from filesystem containment")
        (fedwiki-asdf-discovery-assert-equal
         '(:not-attempted :asset-reference-outside-site-root
           :asset-reference-outside-site-root
           :asset-reference-outside-site-root)
         (mapcar #'hyperdoc:fedwiki-asdf-asset-candidate-resolution-status items)
         "Absolute, parent traversal, and existing symlink escape must be rejected")
        (fedwiki-asdf-discovery-assert-true
         (every #'null
                (mapcar
                 #'hyperdoc:fedwiki-asdf-asset-candidate-resolved-asset-root
                 items))
         "Rejected references must not expose an accepted asset root")))))

(defun run-fedwiki-asdf-discovery-no-asd-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((asset-root
             (fedwiki-asdf-discovery-ensure-asset-root site-root "pages/no-asd")))
      (fedwiki-asdf-discovery-write-file
       (merge-pathnames "nested/ignored.asd" asset-root) "not read")
      (let* ((page
               (fedwiki-asdf-discovery-page
                "page-slug" "Page title"
                (fedwiki-asdf-discovery-assets-item "assets-1" "pages/no-asd")))
             (result (fedwiki-asdf-discovery-discover page site-root)))
        (fedwiki-asdf-discovery-assert-equal
         '(:asset-root-resolved :no-asd-candidate)
         (list (hyperdoc:fedwiki-asdf-asset-discovery-resolution-status result)
               (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result))
         "A nested .asd file must not count as an immediate candidate")
        (fedwiki-asdf-discovery-assert-equal
         nil
         (hyperdoc:fedwiki-asdf-asset-discovery-asd-candidates result)
         "Discovery must neither recurse nor derive an .asd pathname")))))

(defun run-fedwiki-asdf-discovery-single-asd-acceptance-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((reference "pages/the-art-of-the-interpreter")
           (asset-root
             (fedwiki-asdf-discovery-ensure-asset-root site-root reference))
           (asd
             (fedwiki-asdf-discovery-write-file
              (merge-pathnames "the-art-of-the-interpreter.asd" asset-root)
              "This file is intentionally not evaluated by discovery."))
           (page
             (fedwiki-asdf-discovery-page
              "the-art-of-the-interpreter" "The Art of the Interpreter"
              (fedwiki-asdf-discovery-assets-item "a240ec8eed8c4f4b" reference)))
           (result (fedwiki-asdf-discovery-discover page site-root)))
      (fedwiki-asdf-discovery-assert-equal
       '("wiki.example.test" "the-art-of-the-interpreter"
         "The Art of the Interpreter")
       (list (hyperdoc:fedwiki-asdf-asset-discovery-page-site result)
             (hyperdoc:fedwiki-asdf-asset-discovery-page-slug result)
             (hyperdoc:fedwiki-asdf-asset-discovery-page-title result))
       "Site, slug, and title must remain separate observations")
      (fedwiki-asdf-discovery-assert-equal
       (list reference asset-root (list asd))
       (list (hyperdoc:fedwiki-asdf-asset-discovery-asset-reference result)
             (hyperdoc:fedwiki-asdf-asset-discovery-resolved-asset-root result)
             (fedwiki-asdf-discovery-candidate-pathnames
              (fedwiki-asdf-discovery-single-item result)))
       "The acceptance fixture must retain reference, root, and candidate")
      (fedwiki-asdf-discovery-assert-equal
       '(:discovery-complete :single-assets-item :valid-asset-reference
         :asset-root-resolved :single-asd-candidate)
       (list (hyperdoc:fedwiki-asdf-asset-discovery-completion-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-assets-item-cardinality result)
             (hyperdoc:fedwiki-asdf-asset-discovery-reference-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-resolution-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result))
       "The acceptance fixture must retain all five discovery dimensions"))))

(defun run-fedwiki-asdf-discovery-multiple-asd-and-link-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((reference "pages/multiple-asd")
           (asset-root
             (fedwiki-asdf-discovery-ensure-asset-root site-root reference))
           (first-asd
             (fedwiki-asdf-discovery-write-file
              (merge-pathnames "first.asd" asset-root) "not read"))
           (outside-asd
             (fedwiki-asdf-discovery-write-file
              (merge-pathnames "outside/target.asd" site-root) "not read"))
           (linked-asd (merge-pathnames "linked.asd" asset-root)))
      (fedwiki-asdf-discovery-create-symbolic-link outside-asd linked-asd)
      (let* ((page
               (fedwiki-asdf-discovery-page
                "page-slug" "Page title"
                (fedwiki-asdf-discovery-assets-item "assets-1" reference)))
             (result (fedwiki-asdf-discovery-discover page site-root))
             (candidate (fedwiki-asdf-discovery-single-item result))
             (link-record
               (find linked-asd
                     (hyperdoc:fedwiki-asdf-asset-candidate-asd-candidates
                      candidate)
                     :key (lambda (record) (getf record :pathname))
                     :test #'uiop:pathname-equal)))
        (fedwiki-asdf-discovery-assert-equal
         :multiple-asd-candidates
         (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result)
         "Every immediate .asd directory entry must remain visible")
        (fedwiki-asdf-discovery-assert-equal
         (list first-asd linked-asd)
         (fedwiki-asdf-discovery-candidate-pathnames candidate)
         "Candidate order must be deterministic")
        (fedwiki-asdf-discovery-assert-equal
         (list :symbolic-link
               (uiop:resolve-symlinks outside-asd)
               :not-validated-for-activation)
         (list (getf link-record :file-kind)
               (getf link-record :link-target)
               (getf link-record :link-target-status))
         "A direct .asd symlink must expose its kind and unvalidated target")))))

(defun run-fedwiki-asdf-discovery-multiple-assets-items-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((page
             (fedwiki-asdf-discovery-page
              "page-slug" "Page title"
              (fedwiki-asdf-discovery-assets-item "assets-1" "pages/first-assets")
              (fedwiki-asdf-discovery-assets-item "assets-2" "pages/second-assets")))
           (result (fedwiki-asdf-discovery-discover page site-root)))
      (fedwiki-asdf-discovery-assert-equal
       '(:multiple-assets-items :per-assets-item :per-assets-item
         :per-assets-item)
       (list (hyperdoc:fedwiki-asdf-asset-discovery-assets-item-cardinality result)
             (hyperdoc:fedwiki-asdf-asset-discovery-reference-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-resolution-status result)
             (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result))
       "Page-level dimensions must defer to each observed Assets item")
      (fedwiki-asdf-discovery-assert-equal
       :all-assets-items-no-implicit-selection
       (hyperdoc:fedwiki-asdf-asset-discovery-selection-basis result)
       "Multiple Assets items must not imply a selection"))))

(defun run-fedwiki-asdf-discovery-reference-differs-from-page-slug-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((reference "pages/independent-asset-name")
           (asset-root
             (fedwiki-asdf-discovery-ensure-asset-root site-root reference))
           (asd
             (fedwiki-asdf-discovery-write-file
              (merge-pathnames "entrypoint.asd" asset-root) "not read"))
           (page
             (fedwiki-asdf-discovery-page
              "different-page-slug" "Page title"
              (fedwiki-asdf-discovery-assets-item "assets-1" reference)))
           (result (fedwiki-asdf-discovery-discover page site-root)))
      (fedwiki-asdf-discovery-assert-equal
       (list "different-page-slug" reference (list asd))
       (list (hyperdoc:fedwiki-asdf-asset-discovery-page-slug result)
             (hyperdoc:fedwiki-asdf-asset-discovery-asset-reference result)
             (fedwiki-asdf-discovery-candidate-pathnames
              (fedwiki-asdf-discovery-single-item result)))
       "Page slug, asset reference, and .asd basename must remain independent"))))

(defun run-fedwiki-asdf-discovery-convention-mark-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((reference "pages/convention-name")
           (asset-root
             (fedwiki-asdf-discovery-ensure-asset-root site-root reference)))
      (fedwiki-asdf-discovery-write-file
       (merge-pathnames "convention-name.asd" asset-root) "not read")
      (fedwiki-asdf-discovery-write-file
       (merge-pathnames "another-entrypoint.asd" asset-root) "not read")
      (let* ((page
               (fedwiki-asdf-discovery-page
                "unrelated-page-slug" "Page title"
                (fedwiki-asdf-discovery-assets-item "assets-1" reference)))
             (result (fedwiki-asdf-discovery-discover page site-root))
             (records
               (hyperdoc:fedwiki-asdf-asset-discovery-asd-candidates result)))
        (fedwiki-asdf-discovery-assert-true
         (find :convention-matching-candidate records
               :key (lambda (record) (getf record :convention-status)))
         "The reference-last-segment/.asd basename match must be marked")
        (fedwiki-asdf-discovery-assert-true
         (find :no-convention-match records
               :key (lambda (record) (getf record :convention-status)))
         "Convention marking must not hide another candidate")
        (fedwiki-asdf-discovery-assert-equal
         :multiple-asd-candidates
         (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result)
         "Convention marking must not authorize ambiguous activation")))))

(defun fedwiki-asdf-discovery-registered-systems-snapshot ()
  (sort (copy-list (asdf:registered-systems)) #'string<))

(defun fedwiki-asdf-discovery-packages-snapshot ()
  (sort (mapcar #'package-name (list-all-packages)) #'string<))

(defun run-fedwiki-asdf-discovery-registration-and-package-test ()
  (with-fedwiki-asdf-discovery-site-root (site-root)
    (let* ((reference "pages/must-not-activate")
           (asset-root
             (fedwiki-asdf-discovery-ensure-asset-root site-root reference))
           (asd
             (fedwiki-asdf-discovery-write-file
              (merge-pathnames "must-not-activate.asd" asset-root)
              "(error \"Discovery evaluated an unknown .asd file.\")
(defpackage :fedwiki-discovery-must-not-exist (:use :cl))"))
           (page
             (fedwiki-asdf-discovery-page
              "page-slug" "Page title"
              (fedwiki-asdf-discovery-assets-item "assets-1" reference)))
           (systems-before (fedwiki-asdf-discovery-registered-systems-snapshot))
           (packages-before (fedwiki-asdf-discovery-packages-snapshot))
           (result (fedwiki-asdf-discovery-discover page site-root)))
      (fedwiki-asdf-discovery-assert-equal
       (list asd)
       (fedwiki-asdf-discovery-candidate-pathnames
        (fedwiki-asdf-discovery-single-item result))
       "The explosive .asd fixture must be observed only as a directory entry")
      (fedwiki-asdf-discovery-assert-equal
       systems-before (fedwiki-asdf-discovery-registered-systems-snapshot)
       "Discovery must not change the registered-system snapshot")
      (fedwiki-asdf-discovery-assert-equal
       packages-before (fedwiki-asdf-discovery-packages-snapshot)
       "Discovery must not change the package snapshot"))))

(defun run-fedwiki-asdf-discovery-real-page-integration-test ()
  (let* ((domain "wiki.ralfbarkow.ch")
         (slug "the-art-of-the-interpreter")
         (pages-root
           (hyperbook/fedwiki::localhost-fedwiki-pages-directory domain))
         (site-root (uiop:pathname-parent-directory-pathname pages-root))
         (page-path
           (hyperbook/fedwiki::localhost-fedwiki-page-pathname-from-domain-and-slug
            domain slug))
         (wiki
           (make-instance 'hyperbook/fedwiki::fedwiki
                          :id (format nil "fedwiki:~A" domain)))
         (page (hyperbook/fedwiki::make-fedwiki-page wiki slug nil))
         (neighborhood (make-hash-table :test #'equal)))
    (fedwiki-asdf-discovery-assert-true
     (probe-file page-path)
     "The real FedWiki page JSON must exist in the configured pages store")
    ;; SET-PAGE-DATA reconstructs context through GET-FEDWIKI.  Supplying the
    ;; one site named in this page's journal prevents a network initialization.
    (setf (gethash "localhost:3000" neighborhood)
          (make-instance 'hyperbook/fedwiki::fedwiki
                         :id "fedwiki:localhost:3000"))
    (let ((hyperbook/fedwiki::*neighborhood* neighborhood))
      (hyperbook/fedwiki::set-page-data
       page
       (hyperbook/fedwiki::read-localhost-fedwiki-page-json-file page-path)))
    (let* ((assets-item
             (find :assets (hyperbook/fedwiki::story-of page)
                   :key #'hyperbook/fedwiki::item-type-of))
           (result (fedwiki-asdf-discovery-discover page site-root))
           (expected-root
             (merge-pathnames "assets/pages/the-art-of-the-interpreter/"
                              site-root))
           (expected-asd
             (merge-pathnames "the-art-of-the-interpreter.asd"
                              expected-root)))
      (fedwiki-asdf-discovery-assert-true
       (eq (class-of assets-item)
           (find-class 'hyperbook/fedwiki::story-item))
       "The existing parser must materialize Assets as the generic story-item class")
      (fedwiki-asdf-discovery-assert-equal
       '("a240ec8eed8c4f4b" "pages/the-art-of-the-interpreter")
       (list (hyperbook/fedwiki::id-of assets-item)
             (hyperbook/fedwiki::text-of assets-item))
       "The real JSON must retain its observed Assets item")
      (fedwiki-asdf-discovery-assert-equal
       (list "the-art-of-the-interpreter"
             "The Art of the Interpreter"
             "pages/the-art-of-the-interpreter"
             expected-root
             (list expected-asd)
             :single-asd-candidate)
       (list (hyperdoc:fedwiki-asdf-asset-discovery-page-slug result)
             (hyperdoc:fedwiki-asdf-asset-discovery-page-title result)
             (hyperdoc:fedwiki-asdf-asset-discovery-asset-reference result)
             (hyperdoc:fedwiki-asdf-asset-discovery-resolved-asset-root result)
             (fedwiki-asdf-discovery-candidate-pathnames
              (fedwiki-asdf-discovery-single-item result))
             (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality result))
       "Pages store, parser, page object, Assets item, and discovery must compose")
      (format t "~&Real page pipeline: ~A -> generic :ASSETS item -> ~A (~A).~%"
              page-path expected-asd
              (hyperdoc:fedwiki-asdf-asset-discovery-candidate-cardinality
               result)))))

(defun run-fedwiki-asdf-discovery-smoke-tests ()
  (run-fedwiki-asdf-discovery-no-assets-item-test)
  (run-fedwiki-asdf-discovery-missing-directory-test)
  (run-fedwiki-asdf-discovery-invalid-and-outside-reference-test)
  (run-fedwiki-asdf-discovery-no-asd-test)
  (run-fedwiki-asdf-discovery-single-asd-acceptance-test)
  (run-fedwiki-asdf-discovery-multiple-asd-and-link-test)
  (run-fedwiki-asdf-discovery-multiple-assets-items-test)
  (run-fedwiki-asdf-discovery-reference-differs-from-page-slug-test)
  (run-fedwiki-asdf-discovery-convention-mark-test)
  (run-fedwiki-asdf-discovery-registration-and-package-test)
  (run-fedwiki-asdf-discovery-real-page-integration-test)
  (format t "~&FedWiki ASDF discovery smoke tests passed (11 cases).~%")
  t)
