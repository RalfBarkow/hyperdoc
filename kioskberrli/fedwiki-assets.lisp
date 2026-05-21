;;;; FedWiki page-local ASDF asset materialization for Kioskberrli.

(in-package :kioskberrli)

(defparameter +kioskberrli-default-fedwiki-asset-root+
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/")

(defparameter +kioskberrli-source-files+
  '("package.lisp"
    "dashboard.lisp"
    "topics.lisp"
    "planner.lisp"
    "behavior.lisp"
    "trace.lisp"
    "examples.lisp"
    "task-topics.lisp"
    "sqlite-store.lisp"
    "fedwiki-assets.lisp"
    "core.lisp"
    "views.lisp"
    "kioskberrli.scxml"))

(defparameter +kioskberrli-test-files+
  '("package.lisp"
    "smoke.lisp"))

(defclass kioskberrli-fedwiki-asset-manifest ()
  ((id :reader id-of :initarg :id)
   (page-slug :reader page-slug-of :initarg :page-slug)
   (asset-root :reader asset-root-of :initarg :asset-root)
   (page-url :reader page-url-of :initarg :page-url)
   (asset-url-prefix :reader asset-url-prefix-of :initarg :asset-url-prefix)
   (files :reader asset-files-of :initarg :files)
   (write-report :reader write-report-of :initarg :write-report)))

(defmethod print-object ((manifest kioskberrli-fedwiki-asset-manifest) stream)
  (print-unreadable-object (manifest stream :type t :identity nil)
    (format stream "~A -> ~A"
            (page-slug-of manifest)
            (asset-url-prefix-of manifest))))

(defun kioskberrli-normalize-fedwiki-asset-root (root)
  (let ((directory (uiop:ensure-directory-pathname
                    (or root +kioskberrli-default-fedwiki-asset-root+))))
    (cond
      ((probe-file (merge-pathnames "assets/pages/" directory))
       (merge-pathnames "assets/pages/" directory))
      (t directory))))

(defun kioskberrli-system-source-pathname (relative-path)
  (or (probe-file
       (asdf:system-relative-pathname
        :kioskberrli
        (format nil "kioskberrli/~A" relative-path)))
      (probe-file
       (asdf:system-relative-pathname
        :kioskberrli
        (format nil "src/~A" relative-path)))
      (probe-file
       (asdf:system-relative-pathname
        :kioskberrli
        relative-path))
      (asdf:system-relative-pathname
       :kioskberrli
       (format nil "kioskberrli/~A" relative-path))))

(defun kioskberrli-test-source-pathname (relative-path)
  (or (probe-file
       (asdf:system-relative-pathname
        :kioskberrli
        (format nil "kioskberrli/tests/~A" relative-path)))
      (probe-file
       (asdf:system-relative-pathname
        :kioskberrli
        (format nil "tests/~A" relative-path)))
      (asdf:system-relative-pathname
       :kioskberrli
       (format nil "kioskberrli/tests/~A" relative-path))))

(defun kioskberrli-asset-asd-content ()
  ";;;; Page-local ASDF system for FedWiki page asset kioskberrli.

(asdf:defsystem #:kioskberrli
  :description \"Kioskberrli dashboard, planner, trace, SCXML, optional SQLite store, and FedWiki asset support.\"
  :author \"Ralf Barkow\"
  :license \"BSD\"
  :version \"0.1.0\"
  :serial t
  :depends-on (#:hyperdoc
               #:hyperdoc/topics
               #:hyperdoc/shop3
               #:hyperdoc/scxml
               #:hyperdoc/scxml-workflows
               #:hyperdoc/fedwiki-asdf-assets
               #:html-inspector-views)
  :in-order-to ((asdf:test-op (asdf:test-op \"kioskberrli/tests\")))
  :components
  ((:module \"src\"
    :serial t
    :components
    ((:file \"package\")
     (:file \"dashboard\")
     (:file \"topics\")
     (:file \"planner\")
     (:file \"behavior\")
     (:file \"trace\")
     (:file \"examples\")
     (:file \"task-topics\")
     (:file \"sqlite-store\")
     (:file \"fedwiki-assets\")
     (:file \"core\")
     (:file \"views\")
     (:static-file \"kioskberrli.scxml\")))
   (:module \"examples\"
    :components
    ((:static-file \"mrepl-session.lisp\")))
   (:module \"tests\"
    :components
    ((:static-file \"package.lisp\")
     (:static-file \"smoke.lisp\")))))

(asdf:defsystem #:kioskberrli/tests
  :description \"Smoke tests for the Kioskberrli page-local ASDF asset.\"
  :depends-on (#:kioskberrli)
  :serial t
  :components
  ((:module \"tests\"
    :serial t
    :components
    ((:file \"package\")
     (:file \"smoke\"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :kioskberrli/tests
                               :run-kioskberrli-smoke-tests)))
")

(defun kioskberrli-asset-readme-content ()
  (uiop:read-file-string (kioskberrli-system-source-pathname "README.md")))

(defun kioskberrli-asset-mrepl-session-content ()
  "(asdf:load-system :kioskberrli)

(kioskberrli:make-demo-dashboard)
(kioskberrli:make-demo-plan)
(kioskberrli:make-demo-trace)

(kioskberrli:materialize-fedwiki-assets
 :slug \"kioskberrli\"
 :root #p\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/\")
")

(defun kioskberrli-asset-manifest-content (slug)
  (with-output-to-string (stream)
    (format stream "kioskberrli.asd~%")
    (dolist (file +kioskberrli-source-files+)
      (format stream "src/~A~%" file))
    (format stream "examples/mrepl-session.lisp~%")
    (dolist (file +kioskberrli-test-files+)
      (format stream "tests/~A~%" file))
    (format stream "README.md~%")
    (format stream "MANIFEST.txt~%")
    (format stream "~%FedWiki page: http://localhost:3000/view/~A~%" slug)
    (format stream "Asset URL prefix: http://localhost:3000/assets/pages/~A/~%" slug)))

(defun kioskberrli-asset-files (slug)
  (append
   (list (list :path "kioskberrli.asd"
               :content (kioskberrli-asset-asd-content)))
   (loop for file in +kioskberrli-source-files+
         collect (list :path (format nil "src/~A" file)
                       :source (kioskberrli-system-source-pathname file)))
   (list (list :path "examples/mrepl-session.lisp"
               :content (kioskberrli-asset-mrepl-session-content)))
   (loop for file in +kioskberrli-test-files+
         collect (list :path (format nil "tests/~A" file)
                       :source (kioskberrli-test-source-pathname file)))
   (list (list :path "README.md"
               :content (kioskberrli-asset-readme-content))
         (list :path "MANIFEST.txt"
               :content (kioskberrli-asset-manifest-content slug)))))

(defun make-kioskberrli-fedwiki-asset-spec
    (&key (slug "kioskberrli")
       (root +kioskberrli-default-fedwiki-asset-root+))
  (hyperdoc:make-page-asdf-asset-spec
   :system-name "kioskberrli"
   :page-slug slug
   :page-title "Kioskberrli"
   :asset-root (kioskberrli-normalize-fedwiki-asset-root root)
   :source-topic-id nil
   :files (kioskberrli-asset-files slug)
   :tests '(:asdf-test-system)
   :rendered-pages nil
   :zip-name "kioskberrli-assets.zip"
   :package-name "kioskberrli"))

(defun materialize-fedwiki-assets
    (&key (slug "kioskberrli")
       (root +kioskberrli-default-fedwiki-asset-root+)
       clean
       zip)
  "Materialize the page-local ASDF distribution tree for the FedWiki page.

ROOT is the local FedWiki assets/pages directory, or a wiki root containing
assets/pages/. The generated files are distribution artifacts; source-controlled
Lisp remains in the repository's kioskberrli/ directory."
  (let* ((spec (make-kioskberrli-fedwiki-asset-spec :slug slug :root root))
         (write-report (hyperdoc:write-page-asdf-system spec :clean clean))
         (zip-report (when zip
                       (hyperdoc:build-page-asdf-asset-zip spec)))
         (asset-root (hyperdoc:page-asdf-asset-spec-asset-root spec))
         (files (mapcar #'namestring
                        (getf write-report :written))))
    (make-instance 'kioskberrli-fedwiki-asset-manifest
                   :id "kioskberrli-fedwiki-asset-manifest"
                   :page-slug slug
                   :asset-root asset-root
                   :page-url (format nil "http://localhost:3000/view/~A" slug)
                   :asset-url-prefix
                   (format nil "http://localhost:3000/assets/pages/~A/" slug)
                   :files (if zip-report
                              (append files
                                      (list (namestring (getf zip-report :zip))))
                              files)
                   :write-report write-report)))
