;;;; FedWiki page-local ASDF asset materialization for Kioskbeerli.

(in-package :kioskbeerli)

(defparameter +kioskbeerli-default-fedwiki-asset-root+
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/")

(defparameter +kioskbeerli-source-files+
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
    "kioskbeerli.scxml"))

(defparameter +kioskbeerli-test-files+
  '("package.lisp"
    "smoke.lisp"))

(defclass kioskbeerli-fedwiki-asset-manifest ()
  ((id :reader id-of :initarg :id)
   (page-slug :reader page-slug-of :initarg :page-slug)
   (asset-root :reader asset-root-of :initarg :asset-root)
   (page-url :reader page-url-of :initarg :page-url)
   (asset-url-prefix :reader asset-url-prefix-of :initarg :asset-url-prefix)
   (files :reader asset-files-of :initarg :files)
   (write-report :reader write-report-of :initarg :write-report)))

(defmethod print-object ((manifest kioskbeerli-fedwiki-asset-manifest) stream)
  (print-unreadable-object (manifest stream :type t :identity nil)
    (format stream "~A -> ~A"
            (page-slug-of manifest)
            (asset-url-prefix-of manifest))))

(defun kioskbeerli-normalize-fedwiki-asset-root (root)
  (let ((directory (uiop:ensure-directory-pathname
                    (or root +kioskbeerli-default-fedwiki-asset-root+))))
    (cond
      ((probe-file (merge-pathnames "assets/pages/" directory))
       (merge-pathnames "assets/pages/" directory))
      (t directory))))

(defun kioskbeerli-system-source-pathname (relative-path)
  (or (probe-file
       (asdf:system-relative-pathname
        :kioskbeerli
        (format nil "kioskbeerli/~A" relative-path)))
      (probe-file
       (asdf:system-relative-pathname
        :kioskbeerli
        (format nil "src/~A" relative-path)))
      (probe-file
       (asdf:system-relative-pathname
        :kioskbeerli
        relative-path))
      (asdf:system-relative-pathname
       :kioskbeerli
       (format nil "kioskbeerli/~A" relative-path))))

(defun kioskbeerli-test-source-pathname (relative-path)
  (or (probe-file
       (asdf:system-relative-pathname
        :kioskbeerli
        (format nil "kioskbeerli/tests/~A" relative-path)))
      (probe-file
       (asdf:system-relative-pathname
        :kioskbeerli
        (format nil "tests/~A" relative-path)))
      (asdf:system-relative-pathname
       :kioskbeerli
       (format nil "kioskbeerli/tests/~A" relative-path))))

(defun kioskbeerli-asset-asd-content ()
  ";;;; Page-local ASDF system for FedWiki page asset kioskbeerli.

(asdf:defsystem #:kioskbeerli
  :description \"Kioskbeerli dashboard, planner, trace, SCXML, optional SQLite store, and FedWiki asset support.\"
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
  :in-order-to ((asdf:test-op (asdf:test-op \"kioskbeerli/tests\")))
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
     (:static-file \"kioskbeerli.scxml\")))
   (:module \"examples\"
    :components
    ((:static-file \"mrepl-session.lisp\")))
   (:module \"tests\"
    :components
    ((:static-file \"package.lisp\")
     (:static-file \"smoke.lisp\")))))

(asdf:defsystem #:kioskbeerli/tests
  :description \"Smoke tests for the Kioskbeerli page-local ASDF asset.\"
  :depends-on (#:kioskbeerli)
  :serial t
  :components
  ((:module \"tests\"
    :serial t
    :components
    ((:file \"package\")
     (:file \"smoke\"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :kioskbeerli/tests
                               :run-kioskbeerli-smoke-tests)))
")

(defun kioskbeerli-asset-readme-content ()
  (uiop:read-file-string (kioskbeerli-system-source-pathname "README.md")))

(defun kioskbeerli-asset-mrepl-session-content ()
  "(asdf:load-system :kioskbeerli)

(kioskbeerli:make-demo-dashboard)
(kioskbeerli:make-demo-plan)
(kioskbeerli:make-demo-trace)

(kioskbeerli:materialize-fedwiki-assets
 :slug \"kioskbeerli\"
 :root #p\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/\")
")

(defun kioskbeerli-asset-manifest-content (slug)
  (with-output-to-string (stream)
    (format stream "kioskbeerli.asd~%")
    (dolist (file +kioskbeerli-source-files+)
      (format stream "src/~A~%" file))
    (format stream "examples/mrepl-session.lisp~%")
    (dolist (file +kioskbeerli-test-files+)
      (format stream "tests/~A~%" file))
    (format stream "README.md~%")
    (format stream "MANIFEST.txt~%")
    (format stream "~%FedWiki page: http://localhost:3000/view/~A~%" slug)
    (format stream "Asset URL prefix: http://localhost:3000/assets/pages/~A/~%" slug)))

(defun kioskbeerli-asset-files (slug)
  (append
   (list (list :path "kioskbeerli.asd"
               :content (kioskbeerli-asset-asd-content)))
   (loop for file in +kioskbeerli-source-files+
         collect (list :path (format nil "src/~A" file)
                       :source (kioskbeerli-system-source-pathname file)))
   (list (list :path "examples/mrepl-session.lisp"
               :content (kioskbeerli-asset-mrepl-session-content)))
   (loop for file in +kioskbeerli-test-files+
         collect (list :path (format nil "tests/~A" file)
                       :source (kioskbeerli-test-source-pathname file)))
   (list (list :path "README.md"
               :content (kioskbeerli-asset-readme-content))
         (list :path "MANIFEST.txt"
               :content (kioskbeerli-asset-manifest-content slug)))))

(defun make-kioskbeerli-fedwiki-asset-spec
    (&key (slug "kioskbeerli")
       (root +kioskbeerli-default-fedwiki-asset-root+))
  (hyperdoc:make-page-asdf-asset-spec
   :system-name "kioskbeerli"
   :page-slug slug
   :page-title "Kioskbeerli"
   :asset-root (kioskbeerli-normalize-fedwiki-asset-root root)
   :source-topic-id nil
   :files (kioskbeerli-asset-files slug)
   :tests '(:asdf-test-system)
   :rendered-pages nil
   :zip-name "kioskbeerli-assets.zip"
   :package-name "kioskbeerli"))

(defun materialize-fedwiki-assets
    (&key (slug "kioskbeerli")
       (root +kioskbeerli-default-fedwiki-asset-root+)
       clean
       zip)
  "Materialize the page-local ASDF distribution tree for the FedWiki page.

ROOT is the local FedWiki assets/pages directory, or a wiki root containing
assets/pages/. The generated files are distribution artifacts; source-controlled
Lisp remains in the repository's kioskbeerli/ directory."
  (let* ((spec (make-kioskbeerli-fedwiki-asset-spec :slug slug :root root))
         (write-report (hyperdoc:write-page-asdf-system spec :clean clean))
         (zip-report (when zip
                       (hyperdoc:build-page-asdf-asset-zip spec)))
         (asset-root (hyperdoc:page-asdf-asset-spec-asset-root spec))
         (files (mapcar #'namestring
                        (getf write-report :written))))
    (make-instance 'kioskbeerli-fedwiki-asset-manifest
                   :id "kioskbeerli-fedwiki-asset-manifest"
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
