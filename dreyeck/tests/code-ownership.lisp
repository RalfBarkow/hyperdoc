;;;; The code ownership inventory: against a synthetic upstream and fork, and against this checkout. The check needs no Git: it compares the fork's files with a manifest
;;;; and an inventory that are plain data, so it can run on a source snapshot (a Nix build has no history).
(defpackage #:dreyeck/code-ownership/tests
  (:use #:cl)
  (:local-nicknames (#:co #:dreyeck/code-ownership) (#:ua #:dreyeck/upstream-assessment))
  (:export #:run-tests))
(in-package #:dreyeck/code-ownership/tests)

(defun git (directory &rest arguments)
  (string-trim '(#\Newline #\Space)
               (uiop:run-program (list* "git" "-C" (namestring directory) "-c" "user.name=Fixture" "-c" "user.email=fixture@example.invalid" "-c" "commit.gpgsign=false" arguments)
                                 :output :string :error-output :string)))

(defun write-file (root path text)
  (let ((file (merge-pathnames path root)))
    (ensure-directories-exist file)
    (with-open-file (out file :direction :output :if-exists :supersede :external-format :utf-8) (write-string text out))))

(defparameter +lib-0+ "(defun alpha (x) (+ x 1))
(defun beta (x) (* x 2))
(defparameter *gamma* 3)")
(defparameter +asd-0+ "(defsystem \"iaf-lib\" :depends-on (\"alexandria\") :components ((:file \"lib/core\")))")

(defvar *root*) (defvar *base-sha*)

(defmacro with-fork ((&optional (name '*root*)) &body body)
  `(let* ((base (uiop:ensure-directory-pathname (merge-pathnames (format nil "co-fixture-~D/" (random 1000000 (make-random-state t))) (uiop:temporary-directory))))
          (,name base))
     (ensure-directories-exist base)
     (unwind-protect
          (progn (git base "init" "-q" "-b" "main")
                 (write-file base "lib/core.lisp" +lib-0+) (write-file base "iaf.asd" +asd-0+) (write-file base "ext/own.lisp" "(defun own () 1)")
                 (git base "add" "-A") (git base "commit" "-q" "-m" "upstream")
                 (let ((*base-sha* (git base "rev-parse" "HEAD"))) ,@body))
       (uiop:delete-directory-tree base :validate t :if-does-not-exist :ignore))))

(defun manifest-of (root) (co:build-manifest (ua:open-repository root) *base-sha* '("lib" "iaf.asd")))
(defun deviations-of (root manifest) (co:current-deviations root manifest))
(defun problem-kinds (report) (mapcar #'first (co:inventory-report-problems report)))

(defun entry-for (deviation &rest extra)
  (append (list :path (co:deviation-path deviation) :key (co:deviation-key deviation) :kind (co:deviation-kind deviation)
                :upstream-digest (co:deviation-upstream-digest deviation) :current-digest (co:deviation-current-digest deviation)
                :category :reusable-extension :owner-now '("iaf-lib") :basis '("fixture"))
          extra))

(defun pending (deviation) (entry-for deviation :status :pending :origin-commit "abc" :proposed-target "upstream" :plan "contribute" :priority 3))
(defun accepted (deviation) (entry-for deviation :status :accepted :justification "documented" :origin-commit "abc" :target-system "iaf-lib"))
(defun inventory (manifest &rest entries) (list :library-inventory :version 1 :reference (co:manifest-reference manifest) :entries entries))

(defun check-fixture ()
  (with-fork ()
    (let ((manifest (manifest-of *root*)))
      (assert (equal *base-sha* (co:manifest-reference manifest)))
      ;; a fork equal to upstream has no difference, and needs no inventory
      (assert (null (deviations-of *root* manifest)))
      (assert (co:inventory-report-clean-p (co:check-library-inventory *root* manifest (inventory manifest))))
      ;; the fork changes one definition and adds one; formatting and comments are not differences
      (write-file *root* "lib/core.lisp" (format nil ";; a comment~%(defun alpha (x)~%  (+ x 1))~%(defun beta (x) (* x 3))~%(defparameter *gamma* 3)~%(defun delta () 4)"))
      (let* ((deviations (deviations-of *root* manifest)) (keys (mapcar #'co:deviation-key deviations)))
        (assert (equal '("function:beta" "function:delta") keys) () "~S" keys)
        (assert (equal '(:changed :added) (mapcar #'co:deviation-kind deviations)))
        ;; nothing is inventoried: both are failures
        (let ((report (co:check-library-inventory *root* manifest (inventory manifest))))
          (assert (equal '(:uninventoried :uninventoried) (problem-kinds report))) (assert (not (co:inventory-report-ok-p report))))
        ;; one inventoried as pending, one not: the other is still a failure
        (let ((report (co:check-library-inventory *root* manifest (inventory manifest (pending (first deviations))))))
          (assert (equal '(:uninventoried) (problem-kinds report))))
        ;; both pending: consistent, and reported as not accepted
        (let ((report (co:check-library-inventory *root* manifest (inventory manifest (pending (first deviations)) (pending (second deviations))))))
          (assert (co:inventory-report-ok-p report)) (assert (not (co:inventory-report-clean-p report)))
          (assert (= 2 (getf (co:inventory-report-counts report) :pending))) (assert (zerop (getf (co:inventory-report-counts report) :accepted))))
        ;; accepted with its justification
        (let ((report (co:check-library-inventory *root* manifest (inventory manifest (accepted (first deviations)) (accepted (second deviations))))))
          (assert (co:inventory-report-clean-p report)) (assert (= 2 (getf (co:inventory-report-counts report) :accepted))))
        ;; an entry without what its status needs
        (let ((report (co:check-library-inventory *root* manifest (inventory manifest (entry-for (first deviations) :status :accepted) (pending (second deviations))))))
          (assert (equal '(:incomplete) (problem-kinds report))))
        ;; the reference of the inventory is the manifest's
        (assert (member :reference (problem-kinds (co:check-library-inventory *root* manifest (list :library-inventory :version 1 :reference "0000" :entries nil)))))
        ;; accepted, then the definition changes again: the acceptance was of another form
        (let ((inv (inventory manifest (accepted (first deviations)) (accepted (second deviations)))))
          (write-file *root* "lib/core.lisp" (format nil "(defun alpha (x) (+ x 1))~%(defun beta (x) (* x 4))~%(defparameter *gamma* 3)~%(defun delta () 4)"))
          (assert (equal '(:stale) (problem-kinds (co:check-library-inventory *root* manifest inv))) () "a changed form is not the one accepted"))
        ;; a new difference after the inventory was made is found
        (write-file *root* "lib/core.lisp" (format nil "(defun alpha (x) (+ x 1))~%(defun beta (x) (* x 3))~%(defparameter *gamma* 4)~%(defun delta () 4)"))
        (let ((report (co:check-library-inventory *root* manifest (inventory manifest (accepted (first deviations)) (accepted (second deviations))))))
          (assert (equal '(:uninventoried) (problem-kinds report))) (assert (search "*gamma*" (format nil "~{~A~}" (co:inventory-report-lines report)))))
        ;; an entry whose difference is gone is stale, not silently kept
        (write-file *root* "lib/core.lisp" +lib-0+)
        (assert (equal '(:stale :stale) (problem-kinds (co:check-library-inventory *root* manifest (inventory manifest (pending (first deviations)) (pending (second deviations))))))))
      ;; removed definitions and removed files are differences too
      (write-file *root* "lib/core.lisp" "(defun alpha (x) (+ x 1))
(defparameter *gamma* 3)")
      (assert (equal '((:removed "function:beta")) (mapcar (lambda (d) (list (co:deviation-kind d) (co:deviation-key d))) (deviations-of *root* manifest))))
      (delete-file (merge-pathnames "lib/core.lisp" *root*))
      (assert (= 3 (length (deviations-of *root* manifest))) () "every definition of a removed file is removed")
      ;; an ASDF difference is a difference of its system definition
      (write-file *root* "lib/core.lisp" +lib-0+)
      (write-file *root* "iaf.asd" "(defsystem \"iaf-lib\" :depends-on (\"alexandria\" \"cl-base64\") :components ((:file \"lib/core\")))")
      (assert (equal '("system:iaf-lib") (mapcar #'co:deviation-key (deviations-of *root* manifest))))))
  t)

(defun check-migration ()
  "A definition the fork added to a library path and then moved out is verified at its new place; a move that did not happen, or a form that changed on the way, is a problem."
  (with-fork ()
    (let ((manifest (manifest-of *root*)))
      ;; the fork adds DELTA to the library: a difference
      (write-file *root* "lib/core.lisp" (format nil "~A~%(defun delta () 4)" +lib-0+))
      (let* ((deviation (first (deviations-of *root* manifest)))
             (moved (lambda (&rest extra) (append (entry-for deviation :status :migrated :category :dreyeck-owned :justification "moved")
                                                  (list :moved-to (append (list :path "ext/own.lisp" :key "function:delta") extra))))))
        (assert (equal "function:delta" (co:deviation-key deviation)))
        ;; recorded as migrated while it still stands in the library
        (assert (member :migration (problem-kinds (co:check-library-inventory *root* manifest (inventory manifest (funcall moved)))))
                () "a migrated definition that still differs in the library is a problem")
        ;; it leaves the library, but is not at its new place
        (write-file *root* "lib/core.lisp" +lib-0+)
        (assert (equal '(:migration) (problem-kinds (co:check-library-inventory *root* manifest (inventory manifest (funcall moved))))))
        ;; there, with the digest that was migrated
        (write-file *root* "ext/own.lisp" "(defun own () 1)
(defun delta () 4)")
        (let* ((digest (ua:source-definition-digest (co:definition-at-path *root* "ext/own.lisp" "function:delta")))
               (report (co:check-library-inventory *root* manifest (inventory manifest (funcall moved :digest digest)))))
          (assert (co:inventory-report-clean-p report)) (assert (= 1 (getf (co:inventory-report-counts report) :migrated))))
        ;; there, but changed on the way
        (assert (equal '(:migration) (problem-kinds (co:check-library-inventory *root* manifest (inventory manifest (funcall moved :digest "0000"))))))
        ;; the library is upstream's again: no difference is left, and the pending entry it had before is stale
        (assert (equal '(:stale) (problem-kinds (co:check-library-inventory *root* manifest (inventory manifest (pending deviation)))))))))
  t)

(defun check-without-git ()
  "The same answers on a copy of the work tree that has no .git at all, as in a source snapshot."
  (with-fork ()
    (let ((manifest (manifest-of *root*)))
      (write-file *root* "lib/core.lisp" "(defun alpha (x) (+ x 1))
(defun beta (x) (* x 3))
(defparameter *gamma* 3)")
      (let* ((deviation (first (deviations-of *root* manifest))) (inv (inventory manifest (pending deviation)))
             (copy (uiop:ensure-directory-pathname (merge-pathnames (format nil "co-snapshot-~D/" (random 1000000 (make-random-state t))) (uiop:temporary-directory)))))
        (unwind-protect
             (progn (uiop:run-program (list "cp" "-r" (string-right-trim "/" (namestring *root*)) (string-right-trim "/" (namestring copy))))
                    (uiop:delete-directory-tree (merge-pathnames ".git/" copy) :validate t)
                    (assert (not (probe-file (merge-pathnames ".git/" copy))))
                    (let ((report (co:check-library-inventory copy manifest inv)))
                      (assert (co:inventory-report-ok-p report)) (assert (= 1 (getf (co:inventory-report-counts report) :pending))))
                    (assert (equal '(:uninventoried) (problem-kinds (co:check-library-inventory copy manifest (inventory manifest))))))
          (uiop:delete-directory-tree copy :validate t :if-does-not-exist :ignore)))))
  t)

(defun check-nothing-loaded-or-written ()
  (with-fork ()
    (let ((manifest (manifest-of *root*)))
      (write-file *root* "lib/core.lisp" "(setf (get 'iaf-canary 'ran) t) #.(setf (get 'iaf-canary 'evaluated) t)
(defun alpha (x) (+ x 2))")
      (let ((before (list (git *root* "status" "--porcelain") (git *root* "for-each-ref") (git *root* "count-objects" "-v"))))
        (setf (get 'iaf-canary 'ran) nil (get 'iaf-canary 'evaluated) nil)
        (co:check-library-inventory *root* manifest (inventory manifest))
        (assert (null (get 'iaf-canary 'ran))) (assert (null (get 'iaf-canary 'evaluated)))
        (assert (equal before (list (git *root* "status" "--porcelain") (git *root* "for-each-ref") (git *root* "count-objects" "-v")))))))
  t)

;;; This checkout

(defun checkout-root () (asdf:system-relative-pathname :dreyeck ""))

(defun check-this-checkout ()
  (let* ((root (checkout-root)) (dir (merge-pathnames "docs/code-ownership/" root))
         (manifest (co:read-manifest (merge-pathnames "manifest.lisp-data" dir))) (inventory (co:read-inventory (merge-pathnames "inventory.lisp-data" dir)))
         (report (co:check-library-inventory root manifest inventory)))
    ;; the reference is the one of the existing contract, and it is not moved
    (assert (equal "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8" (co:manifest-reference manifest)))
    (let ((contract (uiop:read-file-string (merge-pathnames "dreyeck/tests/hyperdoc-library-delta.lisp" root))))
      (assert (search "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8" contract)) (assert (search "401953522ec503cf78764bddc5534f7a9f16fd22" contract)))
    (assert (co:inventory-report-ok-p report) () "~S" (co:inventory-report-problems report))
    ;; nothing is accepted by this file; what is open is open
    (assert (zerop (getf (co:inventory-report-counts report) :accepted)))
    (assert (zerop (getf (co:inventory-report-counts report) :uninventoried)))
    (assert (every (lambda (e) (member (getf e :status) '(:pending :accepted :migrated))) (co:inventory-entries inventory)))
    (assert (every (lambda (e) (and (getf e :plan) (getf e :origin-commit) (getf e :priority))) (co:inventory-entries inventory)) () "every open entry has a plan, an origin and a priority"))
  t)

(defun check-first-migration-slice ()
  "hyperbook/fedwiki/tests no longer stands in hyperbook.asd: it is a dreyeck test system with the same dependencies, files in the same order and the same entry point."
  (let* ((root (checkout-root)) (library (uiop:read-file-string (merge-pathnames "hyperbook.asd" root))) (dreyeck (uiop:read-file-string (merge-pathnames "dreyeck.asd" root))))
    (assert (not (search "hyperbook/fedwiki/tests" library)))
    (assert (search "\"dreyeck/fedwiki-mech/tests\"" dreyeck))
    (assert (not (asdf:find-system "hyperbook/fedwiki/tests" nil)) () "the old system name is retired")
    (let ((system (asdf:find-system "dreyeck/fedwiki-mech/tests")))
      (assert (equal '("hyperbook/fedwiki" "clog-moldable-inspector") (asdf:system-depends-on system)))
      (assert (equal '("dreyeck/tests/fedwiki-mech-story" "dreyeck/tests/fedwiki-mech-sitemaps" "dreyeck/tests/fedwiki-mech-topics" "dreyeck/tests/fedwiki-mech-dialog")
                     (mapcar #'asdf:component-name (asdf:component-children system))))))
  t)

(defun run-tests ()
  (check-fixture)
  (check-migration)
  (check-without-git)
  (check-nothing-loaded-or-written)
  (check-this-checkout)
  (check-first-migration-slice)
  (format t "~&CODE-OWNERSHIP-PASS: differences by definition, pending is not accepted, new and stale found, migration verified at its new place, no Git needed, nothing loaded, this checkout's inventory and the first migrated test system.~%")
  t)
