;;;; Trusted maintenance/test producer. Not a dependency of the renderer.
(defpackage #:dreyeck/verified-example/fixture
  (:use #:cl)
  (:local-nicknames (#:ve #:dreyeck/verified-example)
                    (#:lp #:dreyeck/local-fedwiki-page))
  (:export #:prepare-fixture #:capture-fixture #:fixture-site-root))
(in-package #:dreyeck/verified-example/fixture)

(defun %root () (asdf:system-source-directory "dreyeck/verified-example/fixture"))
(defun fixture-site-root ()
  (merge-pathnames "dreyeck/tests/fixtures/verified-example-site/" (%root)))

(defun %fixture-asd ()
  (merge-pathnames "dreyeck/tests/fixtures/page-attached-hyperdoc/page-attached-hyperdoc-fixture.asd" (%root)))

(defun %inputs ()
  ;; This specific example uses CL only and has no ASDF dependencies. This is
  ;; an audited list, not a purported generic ASDF dependency analyzer. Platform
  ;; dependencies are pinned by flake.lock; approvals do not survive an image.
  (append (mapcar (lambda (path) (merge-pathnames path (%root)))
                 '("dreyeck/tests/fixtures/page-attached-hyperdoc/page-attached-hyperdoc-fixture.asd"
                   "dreyeck/tests/fixtures/page-attached-hyperdoc/src/package.lisp"
                   "dreyeck/tests/fixtures/page-attached-hyperdoc/src/core.lisp"
                   "dreyeck/tests/fixtures/page-attached-hyperdoc/pages/Fixture.html"
                   "dreyeck/src/verified-example.lisp"
                   "dreyeck/src/verified-example-fixture.lisp"
                   "dreyeck/tests/verified-example.lisp"
                   "dreyeck.asd" "flake.lock"))
          ;; POSIX-ARGV also names SBCL when RUNTIME-PATHNAME is a dynamic loader.
          (list sb-ext:*core-pathname* sb-ext:*runtime-pathname*
                (first sb-ext:*posix-argv*))))

(defvar *prepared-manifest* nil)

(defun prepare-fixture ()
  "Explicit trusted build step, only in a disposable test image or the owner's
SLY session. Review the fixed checkout first; this is NOT an untrusted-code
verifier or a sandbox. No page or browser controls the file or system loaded."
  (setf *prepared-manifest* nil)
  (let ((before (ve::%manifest (%inputs))))
    (dreyeck/page-attached-asdf:register-asd-systems
     (%fixture-asd) :name "page-attached-hyperdoc-fixture")
    (assert (null (asdf:system-depends-on
                   (asdf:registered-system "page-attached-hyperdoc-fixture"))))
    (dreyeck/page-attached-asdf:call-with-asd-source-authority
     (%fixture-asd)
     (lambda () (asdf:load-system "page-attached-hyperdoc-fixture" :force t)))
    (assert (ve::%manifest-current-p before))
    (setf *prepared-manifest* before)))

(defun %run-fixture ()
  (let ((value (uiop:symbol-call :page-attached-hyperdoc-fixture :fixture-value)))
    (assert (eq :fixture value))
    (with-standard-io-syntax (prin1-to-string value))))

(defun capture-fixture (site-root item-id)
  "Run the fixed, already prepared fixture and its oracle, recording failure.
Does not approve display. SITE-ROOT supplies page provenance, never code."
  (assert (and *prepared-manifest* (ve::%manifest-current-p *prepared-manifest*)))
  (let* ((source (lp:observe-local-fedwiki-page-source site-root "verified-fixture-value"))
         (started (get-universal-time))
         (status :passed) (failure nil)
         (result (handler-case (%run-fixture)
                   (error (condition)
                     (setf status :failed failure (princ-to-string condition))
                     ""))))
    (unless (ve::%manifest-current-p *prepared-manifest*)
      (setf status :failed failure "Source changed during capture; discard this run."))
    (make-instance 've:stored-example
     :page-source source :page-json (ve::%json-data (lp:page-source-json source))
     :item-id item-id
     :systems (list (list :name "page-attached-hyperdoc-fixture"
                          :version nil :asd (namestring (%fixture-asd))
                          :asd-sha256 (ve::%file-digest (%fixture-asd))
                          :dependencies nil :implementation (lisp-implementation-version)))
     :manifest (copy-tree *prepared-manifest*)
     :input (format nil "~A~%~%(page-attached-hyperdoc-fixture:fixture-value)"
                    (uiop:read-file-string
                     (merge-pathnames "src/core.lisp" (%fixture-asd)) :external-format :utf-8))
     :result result :status status :failure failure
     :started started :finished (get-universal-time))))
