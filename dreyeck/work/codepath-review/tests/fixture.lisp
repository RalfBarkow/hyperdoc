;;;; Fixture definitions with known paths, for the tests only. Their package is left out of every analysis unless a
;;;; test includes it.
(defpackage #:cpr-fixture (:use #:cl))
(in-package #:cpr-fixture)

(defun fx-open-sink (root)
  (let ((asdf:*central-registry* (cons root asdf:*central-registry*)))
    (asdf:find-system "cpr-fixture-nonexistent" nil)))

(defun fx-entry ()
  (fx-open-sink #p"/nonexistent/"))

(defun fx-guarded-sink (root)
  (when (dreyeck/page-attached-system-projection::execution-permitted-p)
    (let ((asdf:*central-registry* (cons root asdf:*central-registry*)))
      (asdf:find-system "cpr-fixture-nonexistent" nil))))

(defun fx-text-guarded-sink (root)
  (when (uiop:symbol-call :dreyeck/page-attached-system-projection :execution-permitted-p)
    (let ((asdf:*central-registry* (cons root asdf:*central-registry*)))
      (asdf:find-system "cpr-fixture-nonexistent" nil))))

(defun fx-protected-sink (path)
  (asdf:load-asd path))

(defun fx-guarded-caller (path)
  (when (dreyeck/page-attached-system-projection::execution-permitted-p)
    (fx-protected-sink path)))

(defun fx-lonely-sink (path)
  (asdf:load-asd path))

(defun fx-command-line (path)
  (list "sbcl" "--eval" (format nil "(asdf:load-asd ~S)" (namestring path))))

(defun fx-doc-mentioner ()
  "This used to call FX-LONELY-SINK; it no longer does."
  nil)
