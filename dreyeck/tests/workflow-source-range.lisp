;;;; What a source-range replacement must refuse, and what it must leave
;;;; exactly as it found it.
(defpackage #:dreyeck/workflow/source-range/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/workflow/authoring)
                    (#:wf #:dreyeck/workflow))
  (:export #:run-source-range-tests))

(in-package #:dreyeck/workflow/source-range/tests)

(defparameter +fixture-asd+
  "(defsystem \"range-probe\" :components ((:file \"answer\")))
")

(defparameter +fixture-source+
  ";;;; Header explanation.

(in-package #:cl-user)

;;; Between explanation.

(defun kept ()
  ;; Inner comment, owned by the form.
  (list 1 2 3))

(defun also-kept () :second)

;;; Trailing explanation.
"
  "A comment in each of the three places no form owns, and one inside a
form, which belongs to the CST path and must be refused here.")

(defun call-with-fixture (function &key (source +fixture-source+))
  (let* ((root (merge-pathnames (format nil "range-probe-~D-~D/"
                                        (get-universal-time) (random 100000))
                                (uiop:temporary-directory)))
         (asd (merge-pathnames "range-probe.asd" root))
         (path (merge-pathnames "answer.lisp" root)))
    (ensure-directories-exist root)
    (unwind-protect
         (progn
           (uiop:with-output-file (stream asd :external-format :utf-8)
             (write-string +fixture-asd+ stream))
           (uiop:with-output-file (stream path :external-format :utf-8)
             (write-string source stream))
           (asdf:load-asd asd)
           (funcall function path))
      (ignore-errors (asdf:clear-system "range-probe"))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

(defun %text (path) (uiop:read-file-string path :external-format :utf-8))

(defun %range-of (source text)
  "Where the author observed TEXT. The operation itself never searches."
  (let ((start (search text source)))
    (assert start)
    (assert (null (search text source :start2 (1+ start))))
    (cons start (+ start (length text)))))

(defun %signals (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

(defun %forms (path) (wf:source-forms path))

(defun %plan (path expected replacement &key range)
  (a::plan-source-range-replacement
   "range-probe" path (or range (%range-of (%text path) expected))
   expected replacement))

(defun %no-candidates-p (path)
  (null (remove-if-not (lambda (file)
                         (search "candidate" (or (pathname-type file) "")))
                       (directory (make-pathname :name :wild :type :wild
                                                 :defaults path)))))

;;; The three places no form owns

(defun %replace-and-check (environment old new)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (forms (%forms path))
            (range (%range-of before old)))
       (a::replace-owned-source-range (%plan path old new) environment)
       (let ((after (%text path)))
         ;; Exactly the target, and nothing else, moved.
         (assert (string= after (concatenate 'string
                                             (subseq before 0 (car range))
                                             new
                                             (subseq before (cdr range)))))
         (assert (search new after))
         (assert (search ";; Inner comment, owned by the form." after))
         ;; Which forms there are, in order, is unchanged.
         (let ((later (%forms path)))
           (assert (= (length forms) (length later)))
           (assert (every #'wf:form-equal forms later)))
         (assert (%no-candidates-p path)))))))

(defun test-before-the-first-form (environment)
  (%replace-and-check environment "Header explanation."
                      "A longer header that moves every later offset."))

(defun test-between-two-forms (environment)
  (%replace-and-check environment ";;; Between explanation."
                      (format nil ";;; Between, first line.~%;;; And a second.")))

(defun test-after-the-last-form (environment)
  (%replace-and-check environment ";;; Trailing explanation." ""))

;;; The domain: text a form owns belongs to the CST path

(defun test-refuses-a-range-a-form-owns ()
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (message (%signals
                      (lambda ()
                        (%plan path ";; Inner comment, owned by the form."
                               ";; A comment the CST path should change.")))))
       (assert message)
       (assert (search "targeted CST-source replacement" message))
       (assert (string= before (%text path)))))
   :source +fixture-source+)
  ;; Straddling a form's first byte is ownership too.
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (start (search "(defun also-kept" before))
            (message (%signals
                      (lambda ()
                        (%plan path (subseq before (- start 2) (1+ start))
                               "X" :range (cons (- start 2) (1+ start)))))))
       (assert message)
       (assert (search "owned by a Lisp form" message)))))
  t)

;;; The address is the range; the bytes are only its witness

(defun test-refuses-wrong-bytes-and-a-shifted-range ()
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (range (%range-of before "Header explanation.")))
       (let ((message (%signals (lambda ()
                                  (%plan path "Something else entirely."
                                         "New." :range range)))))
         (assert (search "not at" message)))
       (let ((message (%signals
                       (lambda ()
                         (%plan path "Header explanation." "New."
                                :range (cons (1+ (car range))
                                             (1+ (cdr range))))))))
         (assert (search "not at" message)))
       (assert (string= before (%text path))))))
  t)

(defun test-refuses-a-stale-authority (environment)
  "Changed after planning, anywhere: refused as stale, before any candidate.
The reason is asserted as well as the refusal. Other checks would also
object here, later and for the wrong reason; stale must be named stale."
  (call-with-fixture
   (lambda (path)
     (let ((plan (%plan path "Header explanation." "New header.")))
       (with-open-file (stream path :direction :output :if-exists :append
                                    :external-format :utf-8)
         (write-string ";;; Written after the plan was made.
" stream))
       (let* ((changed (%text path))
              (message (%signals (lambda ()
                                   (a::replace-owned-source-range
                                    plan environment)))))
         (assert message)
         (assert (search "changed since it was observed" message))
         (assert (string= changed (%text path)))
         (assert (%no-candidates-p path))))))
  t)

;;; What the replacement text may not do

(defun %refused-by-verification (environment old new fragment)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan (%plan path old new))
            (message (%signals (lambda ()
                                 (a::replace-owned-source-range
                                  plan environment)))))
       (assert message)
       (assert (search fragment message) () "~S not refused for ~S: ~A"
               new fragment message)
       ;; The candidate was verified before installation, so the authority
       ;; never saw the attempt.
       (assert (string= before (%text path)))
       (assert (%no-candidates-p path))))))

(defun test-refuses-a-smuggled-form (environment)
  "The observed counterexample: it parses, and it has one form too many."
  (%refused-by-verification
   environment ";;; Between explanation."
   (format nil ";;; Between explanation.~%(defun smuggled () 42)")
   "top-level forms changed: 3 -> 4"))

(defun test-refuses-a-form-removed-indirectly (environment)
  "A feature expression in a gap makes the reader skip the next form."
  (%refused-by-verification
   environment ";;; Between explanation."
   (format nil ";;; Between explanation.~%#+(or)")
   "top-level forms changed: 3 -> 2"))

(defun test-refuses-a-form-changed-indirectly (environment)
  "One quote character in a gap, and the next form means something else."
  (%refused-by-verification
   environment ";;; Between explanation."
   (format nil ";;; Between explanation.~%'")
   "Top-level form 1 changed"))

(defun test-refuses-a-result-that-needs-recovery (environment)
  (%refused-by-verification
   environment ";;; Trailing explanation." "(unfinished"
   "reader recovery"))

(defun test-verification-catches-collateral-change ()
  (call-with-fixture
   (lambda (path)
     (let* ((plan (%plan path "Header explanation." "New header."))
            (range (a::range-plan-range plan))
            ;; Built independently of the operation's own splice.
            (honest (concatenate 'string (subseq (%text path) 0 (car range))
                                 "New header."
                                 (subseq (%text path) (cdr range))))
            (damaged (let ((position (search "(list 1 2 3)" honest)))
                       (concatenate 'string (subseq honest 0 position)
                                    "(list 1 2 4)"
                                    (subseq honest (+ position 12))))))
       ;; The honest result is accepted, so the rejection below is about
       ;; the damage and not a blind checker.
       (assert (a::verify-source-range-replacement plan honest))
       (let ((message (%signals (lambda ()
                                  (a::verify-source-range-replacement
                                   plan damaged)))))
         (assert (search "outside the targeted range" message))))))
  t)

(defun run-source-range-tests ()
  (let ((environment (a:make-authoring-environment)))
    (test-before-the-first-form environment)
    (test-between-two-forms environment)
    (test-after-the-last-form environment)
    (test-refuses-a-range-a-form-owns)
    (test-refuses-wrong-bytes-and-a-shifted-range)
    (test-refuses-a-stale-authority environment)
    (test-refuses-a-smuggled-form environment)
    (test-refuses-a-form-removed-indirectly environment)
    (test-refuses-a-form-changed-indirectly environment)
    (test-refuses-a-result-that-needs-recovery environment)
    (test-verification-catches-collateral-change))
  (format t "~&SOURCE-RANGE-REPLACEMENT-PASS: text before, between and after ~
forms replaced with every form unchanged and in order; a range a form owns ~
refused in favour of the CST path; wrong bytes, a shifted range and a stale ~
authority refused; a smuggled, a suppressed and a quoted form and a result ~
needing recovery all refused with the authority byte-identical.~%")
  t)
