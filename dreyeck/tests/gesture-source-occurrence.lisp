;;;; Exact occurrences, not namesakes. All changed authorities are temporary files.
(in-package #:dreyeck/gesture/operation-request/tests)

(defun %write-source (path source)
  (with-open-file (out path :direction :output :if-exists :supersede
                           :external-format :utf-8)
    (write-string source out)))

(defun %with-occurrence-page (source function)
  (uiop:with-temporary-file (:pathname path :stream out :type "lisp")
    (close out)
    (%write-source path source)
    (let ((r::*requests* (make-hash-table :test #'equal)))
      (funcall function
               (make-instance 'hyperdoc::code-page
                              :hyperbook (hyperbook:hyperbook-of (%page))
                              :id "Temporary occurrence witness"
                              :file (make-instance 'asdf:cl-source-file
                                                   :name "occurrence-probe"
                                                   :parent (asdf:find-system "dreyeck")
                                                   :pathname path))
               path))))

(defun %duplicate-source ()
  ;; Non-ASCII text makes a byte-offset implementation fail, even though an
  ;; ASCII-only fixture would accidentally pass. No source form is evaluated.
  (format nil "; äλ😀~%(in-package :cl-user)~%(defun occurrence-probe () 1)~%(defun occurrence-probe () 2)~%"))

(defun %refused (function)
  (handler-case (progn (funcall function) nil) (error () t)))

(defun %request-for (occurrence)
  (r:ensure-operation-request (w:insert-executable-defexample-operation) occurrence))

(defun %request-html (request)
  (views:view-html (find "Request" (views:all-views request)
                         :key #'views:view-title :test #'string=)))

(defun test-duplicate-occurrences ()
  (%with-occurrence-page
   (%duplicate-source)
   (lambda (page path)
     (let* ((before (alexandria:read-file-into-byte-vector path))
            (occurrences (r:page-occurrences page))
            (a (first occurrences)) (b (second occurrences))
            (ra (%request-for a)) (rb (%request-for b)))
       (assert (= 2 (length occurrences)))
       (assert (equal (r:occurrence-form-key a) (r:occurrence-form-key b)))
       (assert (not (equal (r:occurrence-range a) (r:occurrence-range b))))
       (assert (not (eq ra rb)))
       (assert (= 1 (fourth (html-inspector-views/standard:s-exp
                            (r:resolve-occurrence (r:operation-request-occurrence ra))))))
       (assert (= 2 (fourth (html-inspector-views/standard:s-exp
                            (r:resolve-occurrence (r:operation-request-occurrence rb))))))
       (assert (= (search "(defun" (%duplicate-source))
                  (car (r:occurrence-range a))))
       (dolist (occurrence occurrences)
         (let ((range (r:occurrence-range occurrence)))
           (assert (string= "(defun" (subseq (r:occurrence-source occurrence)
                                            (car range) (+ 6 (car range)))))
           (assert (char= #\) (char (r:occurrence-source occurrence) (1- (cdr range)))))))
       ;; A legacy page/key call must not silently choose the first duplicate.
       (assert (%refused (lambda () (r:ensure-operation-request
                                    (w:insert-executable-defexample-operation)
                                    page (r:occurrence-form-key a)))))
       (let ((again (r:page-occurrences page)))
         (assert (not (eq a (first again))))
         (assert (eq ra (%request-for (first again))))
         (assert (eq rb (%request-for (second again)))))
       (let ((html (%request-html rb)))
         (dolist (text '("character range" "CURRENT" "Executed" "no --"))
           (assert (search text html))))
       (assert (equalp before (alexandria:read-file-into-byte-vector path)))))))

(defun test-stale-occurrence ()
  (%with-occurrence-page
   (%duplicate-source)
   (lambda (page path)
     (let* ((a (first (r:page-occurrences page)))
            (request (%request-for a))
            ;; Even an unrelated comment invalidates this snapshot. The same
            ;; DEFUN remains at the same range with the same text.
            (changed (concatenate 'string (%duplicate-source) "; changed")))
       (%write-source path changed)
       (assert (eq :stale-authority (r:occurrence-status a)))
       (assert (handler-case (progn (r:resolve-occurrence a) nil)
                 (r:stale-source-occurrence () t)))
       (assert (handler-case (progn (%request-for a) nil)
                 (r:stale-source-occurrence () t)))
       (let ((html (%request-html request)))
         (assert (search "STALE-AUTHORITY" html))
         (assert (search "no --" html)))
       (let* ((b (first (r:page-occurrences page))) (new (%request-for b)))
         (assert (eq :current (r:occurrence-status b)))
         (assert (r:resolve-occurrence b))
         (assert (not (eq request new))))))))

(defun test-invalid-occurrence ()
  (%with-occurrence-page
   (%duplicate-source)
   (lambda (page path)
     (declare (ignore path))
     (let ((a (first (r:page-occurrences page))))
       (flet ((bad (range key)
                (make-instance 'r:source-occurrence :page page :form-key key
                               :source (r:occurrence-source a) :range range)))
         (dolist (range (list '(-1 . 5) '(0 . 999999) '(1 . 1)
                             (cons (1+ (car (r:occurrence-range a)))
                                   (cdr (r:occurrence-range a)))))
           (assert (%refused (lambda () (r:resolve-occurrence
                                        (bad range (r:occurrence-form-key a)))))))
         (assert (%refused (lambda () (r:resolve-occurrence
                                      (bad (r:occurrence-range a)
                                           '(:definition no-such-definition)))))))))))

(defvar *change-after-parse* nil)
(defvar *pathname-parse-count* 0)

(defmethod html-inspector-views/standard:parse-lisp-code :around
    ((input pathname) &optional package)
  (declare (ignore package))
  (if (and *change-after-parse* (equal input (first *change-after-parse*)))
      (progn
        (incf *pathname-parse-count*)
        (multiple-value-prog1 (call-next-method)
          (%write-source input (second *change-after-parse*))))
      (call-next-method)))

(defun test-one-observation ()
  "Deterministically change the file AFTER the parser captured A, BEFORE its
caller resumes. Rereading the path for the snapshot would mix A's ranges
with B's text; this must fail even if both files parse successfully."
  (%with-occurrence-page
   (%duplicate-source)
   (lambda (page path)
     (let* ((*change-after-parse* (list path (concatenate 'string (format nil "; shifted~%") (%duplicate-source))))
            (*pathname-parse-count* 0)
            (a (first (r:page-occurrences page))))
       (assert (= 1 *pathname-parse-count*))
       (assert (string= (%duplicate-source) (r:occurrence-source a)))
       (assert (= (search "(defun" (%duplicate-source)) (car (r:occurrence-range a))))
       (assert (eq :stale-authority (r:occurrence-status a)))))))

(defun %with-function (name replacement function)
  (let ((original (symbol-function name)))
    (unwind-protect (progn (setf (symbol-function name) replacement)
                          (funcall function))
      (setf (symbol-function name) original))))

(defun test-rendered-observation-sharing ()
  (let ((r::*requests* (make-hash-table :test #'equal))
        (captured nil)
        (original (symbol-function 'r:gesture-target-view)))
    (%with-function
     'r:gesture-target-view
     (lambda (occurrence) (push occurrence captured) (funcall original occurrence))
     (lambda ()
       (let* ((page (%page))
              (request (views:eval-thunk (%thunk-for page (%key "RACE-READING")))))
         (assert (member (r:operation-request-occurrence request) captured :test #'eq))
         (assert (eq request (r:request-through-binding
                              (%binding "binding/radial-insert-defexample")
                              (r:operation-request-occurrence request))))
         (assert (eq request (r:request-through-binding
                              (%binding "binding/mark-insert-defexample")
                              (r:operation-request-occurrence request)))))))))

(defun run-occurrence-mutation-controls ()
  "Mutations are process-local and restored, never edits to repository files."
  (flet ((killed (label name replacement test)
           (let ((caught (%with-function name replacement
                                          (lambda () (%refused test)))))
             (assert caught () "Mutation ~A survived." label)
             (format t "~&OCCURRENCE-MUTATION-~A-KILLED~%" label))))
    (let ((original (symbol-function 'r::%request-key)))
      (killed "A" 'r::%request-key
              (lambda (operation occurrence) (butlast (funcall original operation occurrence)))
              #'test-duplicate-occurrences))
    (let ((original (symbol-function 'r:resolve-occurrence)))
      (killed "B" 'r:resolve-occurrence
              (lambda (occurrence)
                (funcall original occurrence)
                (cdr (assoc (r:occurrence-form-key occurrence)
                            (r:page-definitions (r:occurrence-page occurrence)) :test #'equal)))
              #'test-duplicate-occurrences))
    ;; Keep the public status truthful, but bypass the mismatch refusal inside
    ;; resolution. The dedicated resolution assertion must still catch it.
    (let ((original (symbol-function 'r:resolve-occurrence)))
      (killed "C" 'r:resolve-occurrence
              (lambda (occurrence)
                (%with-function 'r:occurrence-status (constantly :current)
                                (lambda () (funcall original occurrence))))
              #'test-stale-occurrence))
    (let ((original (symbol-function 'r:page-occurrences)))
      (killed "D" 'r:page-occurrences
              (lambda (page)
                (let ((occurrences (funcall original page)))
                  (dolist (occurrence occurrences)
                    (setf (slot-value occurrence 'r::source) (r::%current-source occurrence)))
                  occurrences))
              #'test-one-observation))))

(defun run-source-occurrence-tests ()
  (test-duplicate-occurrences)
  (test-stale-occurrence)
  (test-invalid-occurrence)
  (test-one-observation)
  (test-rendered-observation-sharing)
  (run-occurrence-mutation-controls)
  (format t "~&SOURCE-OCCURRENCE-PASS: duplicates distinct; character offsets; rerender EQ; stale refused; one observation; four mutations killed.~%"))
