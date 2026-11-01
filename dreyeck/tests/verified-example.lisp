(defpackage #:dreyeck/verified-example/tests
  (:use #:cl)
  (:local-nicknames (#:ve #:dreyeck/verified-example)
                    (#:fx #:dreyeck/verified-example/fixture)
                    (#:lp #:dreyeck/local-fedwiki-page)
                    (#:ev #:dreyeck/evaluation-record)
                    (#:ap #:dreyeck/authority-policy)
                    (#:v #:html-inspector-views)
                    (#:fw #:hyperbook/fedwiki))
  (:export #:run-tests #:run-tests-in-fresh-process))
(in-package #:dreyeck/verified-example/tests)

(defun run-tests-in-fresh-process ()
  "Like the existing page-attached activation tests, finish ASDF's LOAD-OP
before the test deliberately force-loads its fixture. Use SBCL on PATH so the
configured runtime wrapper is preserved (RUNTIME-PATHNAME may be ld.so)."
  (let ((root (asdf:system-source-directory "dreyeck/verified-example/tests")))
    (uiop:run-program
     (list "sbcl" "--noinform" "--no-sysinit" "--no-userinit" "--non-interactive"
           "--eval" "(require :asdf)"
           "--eval" (format nil "(asdf:load-asd ~S)" (merge-pathnames "dreyeck.asd" root))
           "--eval" "(asdf:load-system \"dreyeck/verified-example/tests\")"
           "--eval" "(dreyeck/verified-example/tests:run-tests)")
     :directory root :output *standard-output* :error-output *error-output*))
  t)

(defun %page (root &optional (slug "verified-fixture-value"))
  (lp:make-local-fedwiki-page root (lp:make-local-fedwiki root "verified-fixture-test") slug))
(defun %item (page) (aref (fw::story-of page) 0))
(defun %html (page)
  (v:view-html (v:html-view :title "Test"
                (fw::render-story-item :code (%item page) page))))
(defun %write (path text)
  (with-open-file (s path :direction :output :if-exists :supersede
                          :if-does-not-exist :create :external-format :utf-8)
    (write-string text s)))
(defun %denied (page reason)
  (multiple-value-bind (allowed actual) (ve:display-decision "local/fixture-value" page (%item page))
    (assert (not allowed)) (assert (eq reason actual)))
  (assert (not (search ":FIXTURE" (%html page)))))

(defun %without-execution (function)
  ;; A rejection must happen before even a discovery/registration attempt.
  ;; These definitions are restored under UNWIND-PROTECT; no production image.
  (let* ((names (append '(asdf:find-system asdf:load-system asdf:load-asd uiop:run-program)
                        (let ((symbol (find-symbol "FIXTURE-VALUE" :page-attached-hyperdoc-fixture)))
                          (when symbol (list symbol)))))
         (saved (mapcar #'fdefinition names)) (calls nil))
    (unwind-protect
         (progn
           (dolist (name names)
             (let ((name name))
               (setf (fdefinition name)
                     (lambda (&rest arguments)
                       (declare (ignore arguments))
                       (push name calls) (error "Forbidden rendering operation: ~A" name)))))
           (funcall function)
           (assert (null calls)))
      (loop for name in names for definition in saved do (setf (fdefinition name) definition)))))

(defun run-tests ()
  (let* ((ap::*contracts* (make-hash-table :test #'equal))
         (root (merge-pathnames (format nil "hyperdoc-verified-~A/" (symbol-name (gensym)))
                                (uiop:temporary-directory)))
         (path (merge-pathnames "pages/verified-fixture-value" root))
         (original (uiop:read-file-string
                    (merge-pathnames "pages/verified-fixture-value" (fx:fixture-site-root))
                    :external-format :utf-8))
         (catalog-before (copy-list (hyperbook:hyperbooks-of hyperbook:*catalog*))))
    (ensure-directories-exist path)
    (unwind-protect
         (progn
           (%write path original)
           (fx:prepare-fixture)
           (let* ((record (fx:capture-fixture root "fixture-value")) (page (%page root)))
             (assert (eq :passed (ev:evaluation-status-of record)))
             (assert (equal ":FIXTURE" (ev:evaluation-result-of record)))
             (assert (null (ev:evaluation-failure-of record)))
             (%without-execution (lambda () (%denied page :not-approved)))
             (let ((grant (ve:approve-display "local/fixture-value" record "local test reviewer")))
               (assert (equal (ve:example-digest record) (ap:contract-audit-provenance grant))))
             (%without-execution
              (lambda ()
                (assert (ve:display-decision "local/fixture-value" page (%item page)))
                (assert (search ":FIXTURE" (%html page)))
                (assert (not (search "<button" (%html page))))
                (let ((view (ve:example-view "local/fixture-value" page (%item page))))
                  (v:view-html view)
                  (assert (null (v:view-assets view)))
                  (assert (null (v:view-references view))))
                (dolist (id '("local/fixture-value" "unknown" "(loop)" nil))
                  (assert (equal '(:status :refused :reason :execution-unavailable :executed-p nil)
                                 (ve:request-play id))))))
             ;; A page edit invalidates a retained, previously hydrated object too.
             (%write path (concatenate 'string original " "))
             (%without-execution (lambda () (%denied page :page-revision-changed)))
             (%write path original)
             ;; A copied page in another site has identical bytes, no authority.
             (let* ((other (merge-pathnames "copy/" root))
                    (other-file (merge-pathnames "pages/verified-fixture-value" other)))
               (ensure-directories-exist other-file) (%write other-file original)
               (let ((copied (%page other)))
                 (%without-execution (lambda () (%denied copied :page-or-item-changed)))))
             ;; A different slug at the same site cannot inherit the grant.
             (%write (merge-pathnames "pages/copied-example" root) original)
             (let ((copied (%page root "copied-example")))
               (%without-execution (lambda () (%denied copied :page-or-item-changed))))
             (let ((remote (make-instance 'fw::fedwiki-page :id "verified-fixture-value")))
               (%without-execution
                (lambda ()
                  (multiple-value-bind (allowed reason)
                      (ve:display-decision "local/fixture-value" remote (%item page))
                    (assert (null allowed)) (assert (eq :foreign-page reason))))))
             ;; Forged trusted field and adversarial text are data, never authority.
             (let ((forged (%page root)))
               (setf (gethash "trusted" (fw::data-of (%item forged))) t)
               (%without-execution (lambda () (%denied forged :page-or-item-changed))))
             (let ((forged (%page root)))
               (setf (gethash "hyperdocExample" (fw::data-of (%item forged))) "unknown"
                     (slot-value (%item forged) 'fw::text) "#.(progn (loop))<script>alert(1)</script>")
               (%without-execution
                (lambda ()
                  (assert (search "NOT-APPROVED" (%html forged)))
                  (assert (not (search "<script" (%html forged)))))))
             ;; Passive ordinary Code is escaped; no MarkDown/DITA/transclusion.
             (let ((passive (%page root)))
               (remhash "hyperdocExample" (fw::data-of (%item passive)))
               (setf (slot-value (%item passive) 'fw::text) "<script>(loop)</script>")
               (%without-execution
                (lambda ()
                  (assert (search "&lt;script&gt;" (%html passive)))
                  (assert (not (search "<script>" (%html passive)))))))
             ;; Tampered output invalidates the digest, including case-only edits.
             (setf (slot-value record 've::result) ":fixture")
             (%without-execution (lambda () (%denied page :artifact-changed)))
             (setf (slot-value record 've::result) ":FIXTURE")
             ;; Even explicitly disclosed stored output must be escaped as data.
             (setf (slot-value record 've::result) "<script>alert(1)</script>")
             (ve:approve-display "local/fixture-value" record "escaping test reviewer")
             (%without-execution
              (lambda ()
                (assert (search "&lt;script&gt;" (%html page)))
                (assert (not (search "<script>" (%html page))))))
             (setf (slot-value record 've::result) ":FIXTURE")
             ;; Revocation rechecks the current registry, not a saved contract.
             (ve:revoke-display "local/fixture-value" "review withdrawn")
             (%without-execution (lambda () (%denied page :revoked)))
             (ve:approve-display "local/fixture-value" record "local test reviewer")
             (let ((destination (uiop:getenv "HYPERDOC_VERIFIED_EXAMPLE_HTML")))
               (when destination (%write destination (%html page))))
             ;; Source/dependency changes, and missing input files, fail closed.
             ;; Use a temporary declared input, never edit the checkout's source.
             (let ((manifest (copy-tree (ve:example-manifest record))))
               (dolist (name '("source.lisp" "dependency.lisp"))
                 (let ((dependency (merge-pathnames name root)))
                   (%write dependency "revision one")
                   (setf (slot-value record 've::manifest)
                         (cons (list (namestring dependency) (ve::%file-digest dependency)) manifest))
                   (ve:approve-display "local/fixture-value" record "local test reviewer")
                   (%write dependency "revision two")
                   (%without-execution (lambda () (%denied page :source-revision-changed)))
                   (delete-file dependency)
                   (%without-execution (lambda () (%denied page :unavailable-or-malformed))))))
             ;; Actual failing execution of the fixed fixture is recorded, not passed.
             (let* ((symbol (find-symbol "FIXTURE-VALUE" :page-attached-hyperdoc-fixture))
                    (original-function (symbol-function symbol)))
               (unwind-protect
                    (progn
                      (setf (symbol-function symbol) (lambda () (error "fixture failure <script>")))
                      (let ((failed (fx:capture-fixture root "fixture-value")))
                        (assert (eq :failed (ev:evaluation-status-of failed)))
                        (assert (search "fixture failure" (ev:evaluation-failure-of failed)))
                        (assert (handler-case (progn (ve:approve-display "failed" failed "reviewer") nil)
                                  (error () t)))))
                 (setf (symbol-function symbol) original-function)))
             ;; No fixed Catalog cardinality, and no registration by rendering.
             (assert (equal catalog-before (hyperbook:hyperbooks-of hyperbook:*catalog*)))
             (let ((hyperbook:*catalog* (make-instance 'hyperbook:catalog)))
               (%without-execution (lambda () (ve:request-play "local/fixture-value")))
               (assert (null (hyperbook:hyperbooks-of hyperbook:*catalog*)))
               (setf (hyperbook:hyperbooks-of hyperbook:*catalog*) (list (lp:make-local-fedwiki root "extra")))
               (%without-execution (lambda () (ve:request-play "local/fixture-value")))
               (assert (equal "extra" (hyperbook:id-of (first (hyperbook:hyperbooks-of hyperbook:*catalog*)))))))
           (format t "~&Verified example tests passed: display, denial-before-load, revision, copy, forgery, escaping, revocation, dependency, failure, Catalog independence.~%")
           t)
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))
