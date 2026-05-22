;;;; Smoke tests for FedWiki-attached ASDF system homes.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-FEDWIKI-ATTACHED-ASDF-SYSTEM-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun fedwiki-attached-asdf-assert-true (condition message)
  (unless condition
    (error "~A" message))
  condition)

(defun fedwiki-attached-asdf-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun fedwiki-attached-asdf-assert-contains (needle haystack message)
  (fedwiki-attached-asdf-assert-true
   (and haystack (search needle haystack :test #'char-equal))
   (format nil "~A -- missing ~S" message needle)))

(defun fedwiki-attached-asdf-assert-not-contains (needle haystack message)
  (when (and haystack (search needle haystack :test #'char-equal))
    (error "~A -- unexpected ~S" message needle)))

(defun fedwiki-attached-asdf-temp-site-root ()
  (merge-pathnames
   (format nil "hyperdoc-fedwiki-attached-asdf-smoke-~D-~D/wiki.ralfbarkow.ch/"
           (get-universal-time)
           (random 1000000))
   (uiop:temporary-directory)))

(defun fedwiki-attached-asdf-write-file (pathname contents)
  (ensure-directories-exist pathname)
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string contents stream))
  pathname)

(defun fedwiki-attached-asdf-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun fedwiki-attached-asdf-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun fedwiki-attached-asdf-render-view (object title)
  (let* ((views (fedwiki-attached-asdf-load-inspector-views-for-object object))
         (view (fedwiki-attached-asdf-find-view-by-title views title)))
    (unless view
      (error "Missing inspector view ~S in ~S"
             title
             (mapcar #'html-inspector-views:view-title views)))
    (html-inspector-views:view-html view)))

(defun fedwiki-attached-asdf-kiosk-home (&key site-root)
  (hyperdoc:make-fedwiki-attached-asdf-system
   :slug "kioskberrli"
   :site-root (or site-root
                  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/")
   :system :kioskberrli
   :system-file "kioskberrli"
   :test-system :kioskberrli/tests))

(defun run-fedwiki-attached-asdf-construction-smoke-test ()
  (let* ((site-root (fedwiki-attached-asdf-temp-site-root))
         (home (fedwiki-attached-asdf-kiosk-home :site-root site-root))
         (asset-root (hyperdoc:fedwiki-page-asset-root home))
         (entrypoint (hyperdoc:fedwiki-page-asdf-entrypoint home))
         (home-model (hyperdoc:asdf-system-home-page-of home))
         (home-text
           (hyperdoc:fedwiki-attached-asdf-system-home-page-text home)))
    (fedwiki-attached-asdf-assert-true
     (typep home 'hyperdoc:fedwiki-attached-asdf-system)
     "Constructor must return a fedwiki-attached-asdf-system object")
    (fedwiki-attached-asdf-assert-equal
     (merge-pathnames "assets/pages/kioskberrli/" site-root)
     asset-root
     "Asset root must be derived from site root, assets/pages, and slug")
    (fedwiki-attached-asdf-assert-equal
     (merge-pathnames "kioskberrli.asd" asset-root)
     entrypoint
     "ASDF entrypoint must be the flat page-local kioskberrli.asd")
    (fedwiki-attached-asdf-assert-equal
     :fedwiki-attached-asdf-system-home-page
     (getf home-model :kind)
     "ASDF system home page must return a structured view model")
    (dolist (label '("How do I invoke response?"
                     "What specifically can I do now?"
                     "What is needed to do a specific function?"
                     "What is that?"
                     "Where is it?"
                     "Does any part of the system do this?"
                     "What part of the system knows about that?"
                     "How did I get here? What has been happening?"
                     "How can I get back?"
                     "What is the current state of the system?"
                     "Why did that happen?"
                     "Why didn't that happen?"))
      (fedwiki-attached-asdf-assert-contains
       label
       home-text
       "Home-page text must expose Goldberg reading question labels"))
    (dolist (needle '("Page identity: kioskberrli"
                      "Asset root:"
                      "ASDF entrypoint:"
                      "System: :KIOSKBERRLI"
                      "kioskberrli.asd"))
      (fedwiki-attached-asdf-assert-contains
       needle
       home-text
       "Home-page text must expose the kioskberrli identity chain"))
    (fedwiki-attached-asdf-assert-not-contains
     "chatgpt-hyperdoc"
     home-text
     "FedWiki-attached ASDF home page must not depend on chatgpt-hyperdoc")))

(defun run-fedwiki-attached-asdf-inspector-smoke-test ()
  (let* ((site-root (fedwiki-attached-asdf-temp-site-root))
         (home (fedwiki-attached-asdf-kiosk-home :site-root site-root))
         (html (fedwiki-attached-asdf-render-view home "Overview")))
    (dolist (needle '("FedWiki-attached ASDF system home page"
                      "The FedWiki client URL names the page identity only"
                      "Page identity"
                      "kioskberrli"
                      "Available actions"
                      "Reading questions"
                      "How do I invoke response?"
                      "Why didn&#039;t that happen?"))
      (fedwiki-attached-asdf-assert-contains
       needle
       html
       "Inspector Overview must render a comprehension-first system home page"))))

(defun fedwiki-attached-asdf-write-fixture (site-root)
  (let* ((asset-root (merge-pathnames "assets/pages/kioskberrli/" site-root))
         (asd (merge-pathnames "fedwiki-attached-smoke.asd" asset-root)))
    (fedwiki-attached-asdf-write-file
     asd
     ";;;; Page-local smoke ASDF system.

(asdf:defsystem #:fedwiki-attached-smoke
  :serial t
  :in-order-to ((asdf:test-op (asdf:test-op \"fedwiki-attached-smoke/tests\")))
  :components ((:file \"package\")
               (:file \"core\")))

(asdf:defsystem #:fedwiki-attached-smoke/tests
  :depends-on (#:fedwiki-attached-smoke)
  :serial t
  :components ((:module \"tests\"
                :serial t
                :components ((:file \"package\")
                             (:file \"smoke\"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :fedwiki-attached-smoke/tests
                               :run-fedwiki-attached-smoke-tests)))
")
    (fedwiki-attached-asdf-write-file
     (merge-pathnames "package.lisp" asset-root)
     "(defpackage :fedwiki-attached-smoke
  (:use :cl)
  (:export #:fedwiki-attached-smoke-ping))

(in-package :fedwiki-attached-smoke)
")
    (fedwiki-attached-asdf-write-file
     (merge-pathnames "core.lisp" asset-root)
     "(in-package :fedwiki-attached-smoke)

(defun fedwiki-attached-smoke-ping ()
  :ok)
")
    (fedwiki-attached-asdf-write-file
     (merge-pathnames "tests/package.lisp" asset-root)
     "(defpackage :fedwiki-attached-smoke/tests
  (:use :cl :fedwiki-attached-smoke)
  (:export #:run-fedwiki-attached-smoke-tests))
")
    (fedwiki-attached-asdf-write-file
     (merge-pathnames "tests/smoke.lisp" asset-root)
     "(in-package :fedwiki-attached-smoke/tests)

(defun run-fedwiki-attached-smoke-tests ()
  (unless (eq (fedwiki-attached-smoke-ping) :ok)
    (error \"Smoke fixture failed.\"))
  t)
")
    asd))

(defun run-fedwiki-attached-asdf-load-smoke-test ()
  (let* ((site-root (fedwiki-attached-asdf-temp-site-root))
         (asd (fedwiki-attached-asdf-write-fixture site-root))
         (home (hyperdoc:make-fedwiki-attached-asdf-system
                :slug "kioskberrli"
                :site-root site-root
                :system :fedwiki-attached-smoke
                :system-file "fedwiki-attached-smoke"
                :test-system :fedwiki-attached-smoke/tests
                :package-name "FEDWIKI-ATTACHED-SMOKE"))
         (loaded (hyperdoc:load-fedwiki-attached-asdf-system home :force t)))
    (fedwiki-attached-asdf-assert-equal
     asd
     (hyperdoc:fedwiki-page-asdf-entrypoint home)
     "Fixture home must load the exact local page-attached .asd")
    (fedwiki-attached-asdf-assert-true
     (typep loaded 'asdf:system)
     "Loading an explicit local page-attached .asd must return an ASDF system")
    (fedwiki-attached-asdf-assert-true
     (find-package :fedwiki-attached-smoke)
     "Loading the page-attached system must create its package")
    (asdf:load-system :fedwiki-attached-smoke/tests :force t)
    (fedwiki-attached-asdf-assert-true
     (uiop:symbol-call :fedwiki-attached-smoke/tests
                       :run-fedwiki-attached-smoke-tests)
     "Fixture test system must load and run through ASDF")))

(defun run-fedwiki-attached-asdf-lookup-failure-smoke-test ()
  (let* ((site-root (fedwiki-attached-asdf-temp-site-root))
         (home (fedwiki-attached-asdf-kiosk-home :site-root site-root))
         (failure (hyperdoc:load-fedwiki-attached-asdf-system home))
         (text (hyperdoc:fedwiki-asdf-lookup-failure-text failure))
         (html (fedwiki-attached-asdf-render-view failure "Overview")))
    (fedwiki-attached-asdf-assert-true
     (typep failure 'hyperdoc:fedwiki-asdf-system-lookup-failure)
     "Missing page-attached .asd must produce an inspectable lookup-failure object")
    (dolist (needle '("local FedWiki page asset .asd"
                      "workspace source .asd"
                      "compatibility ASDF route"
                      "/Users/rgb/workspace/hyperdoc/kioskberrli.asd"
                      "dreyeck/kioskbeerli"
                      "kioskberrli:"
                      "package does not exist"
                      "reader forms"))
      (fedwiki-attached-asdf-assert-contains
       needle
       text
       "Lookup-failure text must expose route candidates and package-reader consequence"))
    (dolist (needle '("Candidate routes"
                      "local FedWiki page asset .asd"
                      "workspace source .asd"
                      "compatibility ASDF route"
                      "Package-reader consequence"
                      "kioskberrli:"))
      (fedwiki-attached-asdf-assert-contains
       needle
       html
       "Lookup-failure Overview must render route candidates"))))

(defun run-fedwiki-attached-asdf-documentation-smoke-test ()
  (let ((page (hyperbook:find-page hyperdoc:*hyperdoc*
                                   "FedWiki-attached ASDF system"
                                   :signal-error? t))
        (topic (hyperbook:find-page hyperdoc::*topics*
                                    "FedWiki-attached ASDF system"
                                    :signal-error? t)))
    (fedwiki-attached-asdf-assert-true
     page
     "HyperDoc must include the FedWiki-attached ASDF system page")
    (fedwiki-attached-asdf-assert-true
     topic
     "Topics HyperBook must expose the FedWiki-attached ASDF system topic")
    (let ((text (plump:text (hyperbook:dom-of page))))
      (dolist (needle '("FedWiki client URL is an identity name"
                        "local file-backed assets"
                        "make-fedwiki-attached-asdf-system"
                        "load-fedwiki-attached-asdf-system"
                        "kioskberrli.asd"))
        (fedwiki-attached-asdf-assert-contains
         needle
         text
         "Documentation must state the local file-backed workflow boundary")))))

(defun run-fedwiki-attached-asdf-existing-overview-smoke-test ()
  (let* ((system (asdf:find-system :kioskberrli))
         (html (fedwiki-attached-asdf-render-view system "Overview")))
    (dolist (needle '("ASDF systems are the primary exploration scope"
                      "Source file"
                      "Examples"
                      "Test systems"))
      (fedwiki-attached-asdf-assert-contains
       needle
       html
       "Existing ASDF system Overview view must continue to render"))))

(defun run-fedwiki-attached-asdf-kioskberrli-smoke-test ()
  (asdf:load-system :kioskberrli)
  (asdf:load-system :kioskberrli/tests :force t)
  (fedwiki-attached-asdf-assert-true
   (uiop:symbol-call :kioskberrli/tests :run-kioskberrli-smoke-tests)
   "Existing Kioskberrli smoke tests must still pass"))

(defun run-fedwiki-attached-asdf-system-smoke-tests ()
  (run-fedwiki-attached-asdf-construction-smoke-test)
  (run-fedwiki-attached-asdf-inspector-smoke-test)
  (run-fedwiki-attached-asdf-load-smoke-test)
  (run-fedwiki-attached-asdf-lookup-failure-smoke-test)
  (run-fedwiki-attached-asdf-documentation-smoke-test)
  (run-fedwiki-attached-asdf-existing-overview-smoke-test)
  (run-fedwiki-attached-asdf-kioskberrli-smoke-test)
  (format t "~&FedWiki-attached ASDF system smoke tests passed.~%")
  t)
