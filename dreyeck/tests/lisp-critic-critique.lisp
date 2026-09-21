(defpackage #:dreyeck/lisp-critic/critique/tests
  (:use #:cl)
  (:local-nicknames (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:views #:html-inspector-views))
  (:export #:run-tests #:run-current-tests #:run-snapshot-roundtrip-tests))
(in-package #:dreyeck/lisp-critic/critique/tests)

(defun assert-link (object destination)
  (let ((view (find "Critic relations" (views:all-views object)
                    :key #'views:view-title :test #'equal)))
    (assert view)
    (views:view-html view)
    (assert (find destination (views:view-references view) :key #'cdr :test #'eq))))

(defun run-current-tests ()
  (let* ((target (critic:car-cdr-critique-example))
         (record (first (critic:target-runs-of target)))
         (rule (critic:rule-of record))
         (finding (first (critic:critiques-of record))))
    ;; Missing external sources must fail this real-engine proof, never skip it.
    (assert (eq :completed (er:evaluation-status-of record)) ()
            "Real Critic run failed: ~A" (er:evaluation-failure-of record))
    (assert (typep record 'critic:lisp-critic-run-record))
    (assert (typep rule 'critic:critic-rule))
    (assert (typep finding 'critic:critique))
    (assert (not (typep finding 'critic:lisp-critic-run-record)))
    (assert (eq target (er:evaluation-input-of record)))
    (assert (equal (list finding) (er:evaluation-result-of record)))
    (assert (eq record (critic:critique-record-of finding)))
    (assert (eq target (critic:target-of finding)))
    (assert (eq rule (critic:rule-of finding)))
    (assert (equal (list finding) (critic:critiques-of rule)))
    (assert (equal '(car (cdr critic::items)) (critic:target-form-of target)))
    (assert (equal (critic:target-form-of target)
                   (uiop:symbol-call :lisp-critic :critique-code
                                     (critic:critique-evidence-of finding))))
    (assert (eq (critic:rule-name-of rule)
                (uiop:symbol-call :lisp-critic :critique-name
                                  (critic:critique-evidence-of finding))))
    (assert (probe-file (getf (critic:rule-source-of rule) :pathname)))
    (assert (search "CADR" (critic:critique-explanation-of finding)))
    (assert (search "CADR" (critic:lisp-critic-run-record-raw-output record)))
    (assert (getf (er:evaluation-evidence-of record) :invocation-form))
    (assert (null (er:evaluation-failure-of record)))
    ;; The complete requested navigation path is present in rendered references.
    (assert-link target record)
    (assert-link record rule)
    (assert-link rule finding)
    (assert-link finding target)
    (assert-link finding record)
    (assert-link finding (critic:critique-explanation-of finding))
    (let* ((contract (critic:lisp-critic-run-record-contract-of record))
           (negative (make-instance 'critic:critic-target :form '(second items)))
           (no-match (critic:run-critic-rule contract "CAR-CDR" negative))
           (failure (critic:run-critic-rule contract "NO-SUCH-CRITIC-RULE" negative)))
      (assert (eq :completed (er:evaluation-status-of no-match)))
      (assert (null (er:evaluation-result-of no-match)))
      (assert (eq :failed (er:evaluation-status-of failure)))
      (assert (er:evaluation-failure-of failure))
      (assert (null (er:evaluation-result-of failure)))
      (assert (equal (list finding) (critic:critiques-of rule))))
    (format t "~&REAL-CRITIC-PASS: CAR-CDR, completed record, one separate critique; negative/failure and Inspector links verified.~%")
    t))

(defun run-snapshot-roundtrip-tests ()
  "A run must survive as data into an image that cannot run it.

Run here, write inert JSON, and read it back in a fresh process that
has never loaded the engine. What is checked is not that the Lisp graph
comes back identical — it does not, and need not — but that the same
finding is visible: the same input, rule, recommendation, evidence and
evaluation identity.

The measurement matters as much as the rendering. The rule name and the
match pattern are symbols from LISP-CRITIC-USER and EXTEND-MATCH, so a
format that read them back as symbols would have to create those
packages. JSON cannot, and the fresh process asserts that none
appeared."
  (let* ((target (critic:car-cdr-critique-example))
         (json (critic:critic-run-snapshot-string target))
         (file (uiop:tmpize-pathname
                (merge-pathnames "critic-snapshot.json"
                                 (uiop:temporary-directory)))))
    (unwind-protect
         (progn
           (with-open-file (out file :direction :output :if-exists :supersede)
             (write-string json out))
           ;; Same image: the data carries the finding.
           (let* ((snapshot (with-open-file (in file)
                              (critic:read-critic-run-snapshot in)))
                  (replayed (critic:reconstitute-critic-run snapshot))
                  (record (first (critic:target-runs-of replayed))))
             (assert (equal (princ-to-string (critic:target-form-of target))
                            (critic:target-form-of replayed)))
             (assert (equal (critic:lisp-critic-run-record-id-of
                             (first (critic:target-runs-of target)))
                            (critic:lisp-critic-run-record-id-of record)))
             (assert (= 1 (length (critic:critiques-of record))))
             (assert (equal (critic:critique-explanation-of
                             (first (critic:critiques-of
                                     (first (critic:target-runs-of target)))))
                            (critic:critique-explanation-of
                             (first (critic:critiques-of record))))))
           ;; Fresh process: the engine was never here, and must not
           ;; arrive because a snapshot was read.
           (uiop:run-program
            (list (namestring sb-ext:*runtime-pathname*)
                  "--no-userinit" "--non-interactive"
                  "--eval" "(require :asdf)"
                  "--eval" (format nil "(asdf:load-asd ~S)"
                                   (asdf:system-source-file "dreyeck"))
                  "--eval" "(asdf:load-system \"dreyeck/inspector/lisp-critic\")"
                  "--eval"
                  (format nil
                          "(let ((before (length (list-all-packages))) ~
(systems (length (asdf:registered-systems)))) ~
(assert (null (find-package :lisp-critic))) ~
(assert (null (find-package :lisp-critic-user))) ~
(assert (null (find-package :extend-match))) ~
(let* ((target (with-open-file (in ~S) ~
(dreyeck/lisp-critic:reconstitute-critic-run ~
(dreyeck/lisp-critic:read-critic-run-snapshot in)))) ~
(html (with-output-to-string (s) ~
(dolist (v (html-inspector-views:all-views target)) ~
(write-string (html-inspector-views:view-html v) s))))) ~
(assert (search \"CAR (CDR ITEMS)\" html)) ~
(assert (null (find-package :lisp-critic))) ~
(assert (null (find-package :lisp-critic-user))) ~
(assert (null (find-package :extend-match))) ~
(assert (= before (length (list-all-packages)))) ~
(assert (= systems (length (asdf:registered-systems)))) ~
(format t \"~~&SNAPSHOT-FRESH-IMAGE-PASS: the finding rendered where ~
the engine has never been.~~%\")))"
                          (namestring file)))
            :output *standard-output* :error-output *error-output*))
      (ignore-errors (delete-file file))))
  (format t "~&SNAPSHOT-ROUNDTRIP-PASS: a run survives as data into an image ~
that cannot run it.~%")
  t)

(defun run-tests ()
  (run-current-tests)
  (format t "~&CURRENT-IMAGE-CRITIC-PASS~%")
  (uiop:run-program
   (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
         "--eval" "(require :asdf)"
         "--eval" (format nil "(asdf:load-asd ~S)" (asdf:system-source-file "dreyeck"))
         "--eval" "(asdf:load-system \"dreyeck/lisp-critic/critique/tests\")"
         "--eval" "(dreyeck/lisp-critic/critique/tests:run-current-tests)")
   :output *standard-output* :error-output *error-output*)
  (format t "~&FRESH-PROCESS-CRITIC-PASS~%")
  (run-snapshot-roundtrip-tests)
  t)
