;;;; A refused PERSIST-IN leaves its authority as it found it, or says why
;;;; it could not.
(defpackage #:dreyeck/workflow/persist/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/workflow/authoring)
                    (#:wf #:dreyeck/workflow))
  (:export #:run-persist-tests))

(in-package #:dreyeck/workflow/persist/tests)

(defun %text (path) (uiop:read-file-string path :external-format :utf-8))

(defun call-with-system (function)
  "A disposable system that a fresh process can load, never a repository
authority."
  (let* ((root (merge-pathnames (format nil "persist-proof-~A/" (gensym))
                                (uiop:temporary-directory)))
         (asd (merge-pathnames "persist-proof.asd" root))
         (source (merge-pathnames "answer.lisp" root)))
    (ensure-directories-exist source)
    (unwind-protect
         (progn
           (html-inspector-views/standard::materialize-lisp-source
            asd '((asdf:defsystem "persist-proof"
                    :components ((:file "answer"))
                    :depends-on ("dreyeck/workflow"))))
           (html-inspector-views/standard::materialize-lisp-source
            source '((in-package :cl-user)
                     (defun cl-user::persist-proof-answer () 42)
                     (defun cl-user::persist-proof-neighbour () :unchanged)))
           (asdf:load-asd asd)
           (funcall function asd source))
      (ignore-errors (asdf:clear-system "persist-proof"))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun %answer-plan (body expectation)
  (wf:plan-definition "persist-proof" "answer" 'cl-user::persist-proof-answer
                      (list 'defun 'cl-user::persist-proof-answer '() body)
                      expectation))

(defun %refusal (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) condition)))

(defun %persist (plan)
  (wf:persist-in plan (a:make-authoring-environment)))

(defun %no-candidates-p (path)
  (null (remove-if-not (lambda (file)
                         (search "candidate" (or (pathname-type file) "")))
                       (directory (make-pathname :name :wild :type :wild
                                                 :defaults path)))))

;;; C0: refused before anything is written

(defun test-a-stale-plan-writes-nothing ()
  (call-with-system
   (lambda (asd source)
     (declare (ignore asd))
     (let ((plan (%answer-plan 43 '(= (cl-user::persist-proof-answer) 43))))
       (with-open-file (stream source :direction :output :if-exists :append
                                      :external-format :utf-8)
         (write-string ";; changed after the plan was made
" stream))
       (let ((changed (%text source))
             (refusal (%refusal (lambda () (%persist plan)))))
         (assert refusal)
         (assert (string= changed (%text source)))
         (assert (search "STALE" (princ-to-string refusal)))))))
  t)

;;; R: a candidate that reads back as something else is never installed

(defun test-a-misread-candidate-is-never-installed ()
  "The caller's *PACKAGE* makes the writer print a symbol bare, and the file
reads it back in CL-USER. Nothing about it needs the installed location to
be detected, so it must be refused while the authority is still A."
  (call-with-system
   (lambda (asd source)
     (declare (ignore asd))
     (let* ((observed (%text source))
            (plan (%answer-plan
                   (list 'quote 'dreyeck/workflow/authoring:make-authoring-environment)
                   t))
            (refusal (let ((*package* (find-package "DREYECK/WORKFLOW/AUTHORING")))
                       (%refusal (lambda () (%persist plan))))))
       (assert refusal)
       (assert (string= observed (%text source)))
       (assert (%no-candidates-p source))
       (assert (typep refusal 'a::persistence-candidate-rejected)))))
  t)

;;; W: installed, seen by a fresh process, failed, restored

(defun test-a-verification-failure-restores-the-observed-source ()
  "The expectation holds for the observed definition and fails for the
proposed one. So the failure itself proves that the fresh process loaded
what was installed, and the restoration is checked byte for byte."
  (call-with-system
   (lambda (asd source)
     (declare (ignore asd))
     (let* ((observed (%text source))
            (plan (%answer-plan 44 '(= (cl-user::persist-proof-answer) 42)))
            (refusal (%refusal (lambda () (%persist plan)))))
       (assert refusal)
       (assert (string= observed (%text source)))
       (assert (%no-candidates-p source))
       (assert (typep refusal 'a::persistence-restored))
       (assert (string= observed (a::persistence-observed-source refusal)))
       (assert (search " 44)" (a::persistence-installed-source refusal)))
       (assert (not (search " 44)" observed))))))
  t)

;;; D: a system definition that stops loading is put back

(defun test-a-broken-system-definition-is-restored ()
  (call-with-system
   (lambda (asd source)
     (declare (ignore source))
     (let* ((observed (%text asd))
            (plan (wf:plan-dependency "persist-proof"
                                      "persist-proof-deliberately-missing" t))
            (refusal (%refusal (lambda () (%persist plan)))))
       (assert refusal)
       (assert (string= observed (%text asd)))
       (assert (typep refusal 'a::persistence-restored))
       (assert (search "persist-proof-deliberately-missing"
                       (a::persistence-installed-source refusal)))
       ;; And the restored definition is one an ordinary consumer can load.
       (asdf:clear-system "persist-proof")
       (asdf:load-asd asd)
       (asdf:load-system "persist-proof")
       (assert (= 42 (funcall 'cl-user::persist-proof-answer))))))
  t)

;;; C: somebody else wrote while the fresh process was verifying

(defun test-a-foreign-change-is-never-overwritten ()
  "The expectation runs in the fresh process, which is a second writer: it
appends to the authority and then fails. The rollback must find something
other than what it installed and leave it alone."
  (call-with-system
   (lambda (asd source)
     (declare (ignore asd))
     (let* ((observed (%text source))
            (marker ";; written by another process")
            (plan (%answer-plan
                   44
                   `(progn
                      (with-open-file (stream ,(namestring source)
                                              :direction :output
                                              :if-exists :append)
                        (write-line ,marker stream))
                      nil)))
            (refusal (%refusal (lambda () (%persist plan))))
            (now (%text source)))
       (assert refusal)
       (assert (search marker now))
       (assert (search " 44)" now))
       (assert (not (string= observed now)))
       (assert (typep refusal 'a::persistence-not-restored))
       (assert (string= now (a::persistence-current-source refusal)))
       (assert (string= observed (a::persistence-observed-source refusal))))))
  t)

;;; The restoration check itself

(defun test-restoration-is-checked-byte-for-byte ()
  "A restoration that only reads the same has not restored the source.
The verifier is offered a copy that differs in a comment alone."
  (let* ((observed "(in-package :cl-user)

;; the observed comment
(defun cl-user::persist-proof-answer () 42)
")
         (respelled (let ((position (search "observed comment" observed)))
                      (concatenate 'string (subseq observed 0 position)
                                   "rewritten comment"
                                   (subseq observed (+ position 16))))))
    (assert (a::%verify-restored observed observed))
    (assert (%refusal (lambda () (a::%verify-restored observed respelled)))))
  t)

(defun run-persist-tests ()
  (test-a-stale-plan-writes-nothing)
  (test-a-misread-candidate-is-never-installed)
  (test-a-verification-failure-restores-the-observed-source)
  (test-a-broken-system-definition-is-restored)
  (test-a-foreign-change-is-never-overwritten)
  (test-restoration-is-checked-byte-for-byte)
  (format t "~&PERSIST-IN-RESTORATION-PASS: a stale plan writes nothing; a ~
misread candidate is refused before installation; a definition and a system ~
definition that fail fresh verification are restored byte for byte, and the ~
restored system loads again; a change by another writer during verification ~
is left in place and reported; a restoration that merely reads the same is ~
not accepted.~%")
  t)
