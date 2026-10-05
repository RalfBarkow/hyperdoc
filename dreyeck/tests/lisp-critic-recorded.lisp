;;;; Recorded Critic evaluations: read without the engine, and reproduced with it.

(defpackage #:dreyeck/lisp-critic/recorded/tests
  (:use #:cl)
  (:local-nicknames (#:rec #:dreyeck/lisp-critic/recorded)
                    (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:views #:html-inspector-views))
  (:export #:run-tests))

(in-package #:dreyeck/lisp-critic/recorded/tests)

(defun %engine-untouched-p ()
  "Neither the engine's package nor its page-attached wrapper is in this image."
  (and (null (find-package :lisp-critic))
       (null (asdf:registered-system "a-critic-for-lisp"))))

(defun %only-match (evaluation)
  (let ((matches (rec:recorded-matches-of evaluation)))
    (assert (= 1 (length matches)))
    (first matches)))

(defun %check-common (evaluation rule-name)
  (let ((record (rec:recorded-record-of evaluation))
        (match (%only-match evaluation)))
    ;; The example the record names is the one this runtime's source declares.
    (assert (member (rec:occurrence-status-of evaluation) '(:recorded-snapshot :form-unchanged)))
    (assert (typep (rec:current-occurrence-of evaluation) 'r:source-occurrence))
    ;; The recorded Evaluation Record: completed, and its result is the Critiques.
    (assert (equal "COMPLETED" (er:evaluation-status-of record)))
    (assert (equal (list (getf match :critique)) (er:evaluation-result-of record)))
    (assert (string= rule-name (critic:rule-name-of (critic:rule-of record))))
    (assert (eq (critic:rule-of record) (critic:rule-of (getf match :critique))))
    ;; The match is located in the example as it reads now.
    (assert (getf match :located-p))
    ;; The engine that produced it is identified by its files.
    (assert (every (lambda (file) (= 64 (length (gethash "sha256" file))))
                   (coerce (gethash "files" (rec:recorded-engine-of evaluation)) 'list)))
    ;; The Inspector says what it is, and reaches every part of it.
    (let ((view (find "Recorded evaluation" (views:all-views evaluation)
                      :key #'views:view-title :test #'string=)))
      (assert view)
      (let ((html (views:view-html view)))
        (dolist (needle '("Recorded evaluation." "does not execute that engine" "sha256"))
          (assert (search needle html) () "The view does not say ~S." needle)))
      (dolist (object (list (rec:current-occurrence-of evaluation) record (critic:rule-of record)
                            (getf match :critique)))
        (assert (find object (views:view-references view) :key #'cdr :test #'eq))))
    match))

(defun check-reading-recorded-evaluations ()
  "Both recorded cases, read in an image that never loads the engine."
  (assert (%engine-untouched-p))
  (let* ((constructive (rec:setf-push-recorded-example))
         (questionable (rec:x-plus-1-recorded-example))
         (push-match (%check-common constructive "SETF-PUSH"))
         (plus-match (%check-common questionable "X-PLUS-1")))
    ;; A: SETF-PUSH matched code, and recommends PUSH.
    (assert (null (getf push-match :quoted-p)))
    (assert (search "PUSH" (critic:critique-explanation-of (getf push-match :critique))))
    ;; B: X-PLUS-1 matched (+ X 1) where it is quoted data.
    (assert (eq t (getf plus-match :quoted-p)))
    (assert (string= "(+ X 1)" (getf plus-match :matched)))
    (assert (search "1+" (critic:critique-explanation-of (getf plus-match :critique))))
    (assert (%engine-untouched-p))
    (list constructive questionable)))

(defun %behaviour (data)
  "What a record says the engine did: the rule as the engine defines it,
recommendations, matches, and the engine's files."
  (flet ((get-in (table &rest keys)
           (reduce (lambda (value key) (gethash key value)) keys :initial-value table)))
    (list (get-in data "run" "rule" "name")
          (get-in data "run" "rule" "pattern")
          (coerce (get-in data "run" "rule" "response") 'list)
          (map 'list (lambda (critique) (gethash "explanation" critique)) (get-in data "run" "critiques"))
          (map 'list (lambda (match) (list (gethash "matched" match) (coerce (gethash "path" match) 'list)))
               (gethash "matches" data))
          (map 'list (lambda (file) (gethash "sha256" file)) (get-in data "engine" "files")))))

(defun %read-json (pathname)
  (with-open-file (stream pathname :external-format :utf-8) (critic:read-critic-run-snapshot stream)))

(defun check-records-reproduce ()
  "Run the engine again on the same examples: the rule, recommendation,
match and engine files are what the committed records say. Missing external
sources must fail this real-engine proof, never skip it."
  (let ((directory (uiop:ensure-directory-pathname
                    (merge-pathnames (format nil "recorded-critic-~D/" (random 1000000))
                                     (uiop:temporary-directory)))))
    (ensure-directories-exist directory)
    (unwind-protect
         (progn
           (rec:record-demonstration-evaluations directory)
           (dolist (case rec:+recorded-cases+)
             (let ((fresh (%read-json (merge-pathnames (first case) directory)))
                   (committed (%read-json (asdf:system-relative-pathname
                                           "dreyeck" (concatenate 'string "dreyeck/pages/lisp-critic/evaluations/"
                                                                  (first case))))))
               (assert (equal (%behaviour committed) (%behaviour fresh)) ()
                       "~A: the engine no longer does what its record says." (first case)))))
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore)))
  t)

(defun run-tests ()
  (destructuring-bind (constructive questionable) (check-reading-recorded-evaluations)
    (check-records-reproduce)
    (format t "~&LISP-CRITIC-RECORDED-PASS: ~A and ~A read from their records without the engine; ~
the X-PLUS-1 match is quoted data; run again, the 2004 engine reproduces both records.~%"
            constructive questionable))
  t)
