;;; Independent probes of READ-CLAIM-TABLE, written by the reviewer. Loaded
;;; into a fresh process after the system of the worktree under test.
(defpackage #:a1-review (:use #:cl) (:local-nicknames (#:p #:dreyeck/lisp-critic/text-passage) (#:c #:dreyeck/lisp-critic/text-criticism)))
(in-package #:a1-review)
(defvar *effects* 0)
(defstruct probe-struct (slot (incf *effects*)))
(defun src (table &key (before "") (after "") (body "(copy-tree '~A)"))
  (format nil "~A~%(defun historical-claims ()~%  \"Claims.\"~%  ~?)~%~A" before body (list table) after))
(defun ground-truth (text)
  "What the standard reader sees at top level: only for texts without #. or #S."
  (let ((scratch (make-package (format nil "GT-~D" (random 1000000)) :use '(:cl))))
    (unwind-protect
         (handler-case
             (with-standard-io-syntax
               (let ((*read-eval* nil) (*package* scratch) (eof (list nil)))
                 (with-input-from-string (in text)
                   (loop for form = (read in nil eof) until (eq form eof)
                         collect (cond ((and (consp form) (eq 'defun (first form))
                                             (symbolp (second form)) (string= "HISTORICAL-CLAIMS" (symbol-name (second form))))
                                        :active-definition)
                                       ((consp form) :other-list) ((stringp form) :string)
                                       ((characterp form) :character) (t :atom))))))
           (error (e) (list :reader-error (type-of e))))
      (delete-package scratch))))
(defun probe (name text &key truth)
  (let ((before *effects*))
    (multiple-value-bind (table why)
        (handler-case (p:read-claim-table text)
          (error (e) (values :signalled (type-of e)))
          (sb-sys:interactive-interrupt () (values :interrupt nil)))
      (format t "~&PROBE ~32A table=~S why=~S effects=~D~@[ cl-reader=~S~]~%"
              name table why (- *effects* before) (and truth (ground-truth text))))))
(defun nest (n inner) (format nil "~A~A~A" (make-string n :initial-element #\() inner (make-string n :initial-element #\))))

