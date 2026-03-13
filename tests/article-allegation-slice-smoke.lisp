;;;; Smoke tests for article allegation slice scaffolding
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-ARTICLE-ALLEGATION-SLICE-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *article-allegation-example-input*
  (asdf:system-relative-pathname
   :hyperdoc
   "tools/testdata/article-allegation-slice/minab-example.lisp"))

(defun article-allegation-smoke-tempdir ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "article-allegation-slice-smoke-~D/" (get-universal-time))
    (uiop:temporary-directory))))

(defun assert-contains (needle haystack message)
  (assert-true (search needle haystack :test #'char=)
               (format nil "~A -- missing ~S" message needle)))

(defun assert-not-contains (needle haystack message)
  (assert-true (not (search needle haystack :test #'char=))
               (format nil "~A -- unexpected ~S" message needle)))

(defun find-bundle-entry (entries key value)
  (find value entries :key (lambda (entry) (getf entry key)) :test #'equal))

(defun run-article-allegation-slice-smoke-tests ()
  (let* ((dry-run-root (article-allegation-smoke-tempdir))
         (bundle (hyperdoc:render-article-allegation-slice-bundle
                  *article-allegation-example-input*
                  :dry-run-directory dry-run-root))
         (incident-file (find-bundle-entry (getf bundle :hyperdoc-files)
                                           :title
                                           "Minab school strike allegations"))
         (validation-commands (getf bundle :validation-commands))
         (daily-path (merge-pathnames "fedwiki-pages/2026-03-13" dry-run-root))
         (metadata-path (merge-pathnames "slice-metadata.lisp" dry-run-root))
         (incident-fedwiki-path
           (merge-pathnames "fedwiki-pages/minab-school-strike-allegations"
                            dry-run-root)))
    (assert-equal 7
                  (length (getf bundle :hyperdoc-files))
                  "Dry-run bundle should emit one incident page plus six concept pages")
    (assert-equal 6
                  (length (getf bundle :topic-definitions))
                  "Dry-run bundle should emit reusable concept topics only")
    (assert-equal 7
                  (length (getf bundle :fedwiki-files))
                  "Dry-run bundle should emit one incident twin plus six concept twins")
    (assert-true incident-file
                 "Bundle should contain the example incident page")
    (assert-contains
     "According to the cited account"
     (getf incident-file :content)
     "Incident page should preserve allegation-qualified language")
    (assert-contains
     "This scaffold does not emit flat legal conclusions"
     (getf incident-file :content)
     "Incident page should keep legal language guarded by default")
    (assert-contains
     "<h2>Open uncertainties</h2>"
     (getf incident-file :content)
     "Incident page should always keep the Open uncertainties section")
    (assert-not-contains
     "(defun minab-school-strike-allegations-topic"
     (getf bundle :topics-snippet)
     "Incident-specific topics should stay out of the generated topic snippet by default")
    (assert-true
     (every (lambda (command)
              (or (not (search "journal-gate.lisp" command :test #'char=))
                  (not (search "journal-gate.lisp --" command :test #'char=))))
            validation-commands)
     "Journal gate command must not include a literal -- separator pathname")
    (assert-equal "minab-school-strike"
                  (getf (getf bundle :slice-metadata) :slice-id)
                  "Bundle should derive a stable slice id")
    (assert-equal "minab-school-strike-allegations"
                  (getf (getf bundle :slice-metadata) :incident-fedwiki-slug)
                  "Bundle metadata should expose the derived incident FedWiki slug")
    (hyperdoc:write-article-allegation-slice-bundle bundle)
    (assert-true (uiop:file-exists-p (merge-pathnames "manifest.lisp" dry-run-root))
                 "Dry-run should write a manifest file")
    (assert-true (uiop:file-exists-p metadata-path)
                 "Dry-run should write a slice metadata file")
    (assert-true (uiop:file-exists-p incident-fedwiki-path)
                 "Dry-run should write the incident FedWiki twin")
    (assert-true (uiop:file-exists-p daily-path)
                 "Dry-run should write the daily anchor page")
    (let* ((incident-page (hyperdoc::article-allegation-read-json-file incident-fedwiki-path))
           (daily-page (hyperdoc::article-allegation-read-json-file daily-path)))
      (assert-equal "Minab school strike allegations"
                    (getf incident-page :title)
                    "Incident FedWiki twin title should match the incident page")
      (assert-true
       (search "Dry-run sample for the reusable article-allegation-slice scaffolding routine."
               (getf (first (getf daily-page :story)) :text)
               :test #'char=)
       "Daily anchor text should stay narrow and slice-specific")))
  (format t "~&Article allegation slice smoke tests passed.~%")
  t)
