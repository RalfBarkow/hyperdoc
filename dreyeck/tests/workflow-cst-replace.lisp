;;;; What a targeted CST-source replacement must refuse, and what it must
;;;; leave exactly as it found it.
(defpackage #:dreyeck/workflow/cst-replace/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/workflow/authoring)
                    (#:wf #:dreyeck/workflow))
  (:export #:run-cst-replace-tests))

(in-package #:dreyeck/workflow/cst-replace/tests)

(defparameter +fixture-asd+
  "(defsystem \"cst-probe\" :components ((:file \"answer\")))
")

(defparameter +fixture-source+
  "(in-package :cl-user)

(defun probed ()
  ;; This comment explains why the value is seven.
  (let ((x 7))   ; trailing note
    x))

(defun untouched ()
  ;; A neighbour whose text must survive byte for byte.
  (list 1 2 3))
")

(defparameter +expected-source+
  "(in-package :cl-user)

(defun probed ()
  ;; This comment explains why the value is seven.
  (let ((x 8))   ; trailing note
    x))

(defun untouched ()
  ;; A neighbour whose text must survive byte for byte.
  (list 1 2 3))
"
  "Byte for byte, the fixture with one token changed and nothing else.")

(defun call-with-fixture (function &key (source +fixture-source+))
  (let* ((root (merge-pathnames (format nil "cst-replace-probe-~D-~D/"
                                        (get-universal-time) (random 100000))
                                (uiop:temporary-directory)))
         (asd (merge-pathnames "cst-probe.asd" root))
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
      (ignore-errors (asdf:clear-system "cst-probe"))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

(defun %signals (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

(defun %text (path) (uiop:read-file-string path :external-format :utf-8))

(defun %plan (path expected replacement value)
  (a::plan-cst-source-replacement
   "cst-probe" path '(:definition cl-user::probed) expected replacement value))

;;; The positive control, through the repository-level operation

(defun test-targeted-replacement-preserves-everything-else (environment)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan (%plan path 7 "8" 8)))
       (a::replace-owned-cst-source plan environment)
       (let ((after (%text path)))
         ;; One comparison covers comments, spelling and whitespace at once.
         (assert (string= +expected-source+ after))
         (assert (not (string= before after)))
         ;; Named individually as well, so a failure says which property.
         (assert (search "why the value is seven" after))
         (assert (search "; trailing note" after))
         (assert (search "(defun probed ()" after))
         (assert (search "whose text must survive byte for byte" after))
         (assert (search "(list 1 2 3)" after)))))))

;;; A. The target occurs more than once

(defun test-rejects-a-duplicate-target ()
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (message (%signals (lambda () (%plan path 7 "8" 8)))))
       (assert message)
       (assert (search "exactly once" message))
       (assert (string= before (%text path)))))
   :source "(in-package :cl-user)

(defun probed ()
  ;; Seven twice: the address is ambiguous and must not be guessed.
  (list 7 7))
"))

;;; B. The target is not there

(defun test-rejects-a-missing-target ()
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (message (%signals (lambda () (%plan path 9 "8" 8)))))
       (assert message)
       (assert (search "occurs 0 times" message))
       (assert (string= before (%text path)))))))

;;; C.-E. Collateral damage is caught by the byte comparison

(defun test-verification-catches-collateral-change (environment)
  (declare (ignore environment))
  (call-with-fixture
   (lambda (path)
     (let ((plan (%plan path 7 "8" 8)))
       ;; The honest result is accepted, so a rejection below is about the
       ;; damage rather than the checker being blind.
       (assert (a::verify-cst-source-replacement plan +expected-source+))
       (dolist (case (list
                      (list "internal comment removed"
                            (remove-comment +expected-source+
                                            "why the value is seven"))
                      (list "trailing comment removed"
                            (remove-comment +expected-source+
                                            "trailing note"))
                      (list "() respelled as NIL outside the target"
                            (replace-once +expected-source+
                                          "(defun probed ()"
                                          "(defun probed nil"))
                      (list "one byte of whitespace outside the target"
                            (replace-once +expected-source+
                                          "    x))" "     x))"))
                      (list "a neighbouring form's text changed"
                            (replace-once +expected-source+
                                          "(list 1 2 3)" "(list 1 2 4)"))))
         (destructuring-bind (label damaged) case
           (let ((message (%signals
                           (lambda ()
                             (a::verify-cst-source-replacement plan
                                                               damaged)))))
             (assert message)
             (assert (search "outside the targeted range" message)
                     () "~A was not rejected" label))))))))

(defun replace-once (text from to)
  (let ((pos (search from text)))
    (assert pos)
    (concatenate 'string (subseq text 0 pos) to
                 (subseq text (+ pos (length from))))))

(defun remove-comment (text fragment)
  "Drop the whole line carrying FRAGMENT, as a careless rewrite would."
  (let* ((pos (search fragment text))
         (start (1+ (or (position #\Newline text :from-end t :end pos) -1)))
         (end (1+ (or (position #\Newline text :start pos) (1- (length text))))))
    (concatenate 'string (subseq text 0 start) (subseq text end))))

;;; F. The replacement text is not valid source

(defun test-rejects-malformed-replacement (environment)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan (%plan path 7 "(((" 8))
            (message (%signals (lambda ()
                                 (a::replace-owned-cst-source plan
                                                              environment)))))
       (assert message)
       ;; The authority is exactly as it was, and no candidate is left.
       (assert (string= before (%text path)))
       (assert (null (remove-if-not
                      (lambda (file)
                        (search "candidate" (or (pathname-type file) "")))
                      (directory (make-pathname :name :wild :type :wild
                                                :defaults path)))))))))

;;; The replacement must read as what the caller said it would

(defun test-rejects-a-replacement-that-reads-as-something-else (environment)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan (%plan path 7 "9" 8))
            (message (%signals (lambda ()
                                 (a::replace-owned-cst-source plan
                                                              environment)))))
       (assert message)
       (assert (search "reads as" message))
       (assert (string= before (%text path)))))))

(defparameter +fixture-package+
  "(defpackage #:cst-probe-package
  ;; Why this package exists at all.
  (:use #:cl)
  (:local-nicknames (#:n #:cl))
  (:export
   ;; The first group, and the reason for it.
   #:alpha
   #:beta))

(in-package #:cl-user)

(defun probe-neighbour ()
  ;; A neighbour whose text must survive byte for byte.
  (list 1 2 3))
"
  "A package form carrying the kind of thing a reserializing write loses:
a reason for the package, a nickname list, and a comment inside the export
list explaining what the group is for.")

(defun test-a-package-key-survives-reparsing ()
  "Keys are compared with EQUAL, and #: designators never are.
This is why the key carries the designator's string and not the
designator, and it is the whole reason DEFPACKAGE could not simply be
keyed like DEFUN."
  (let* ((text "(defpackage #:cst-probe-package (:use #:cl))")
         (one (read-from-string text))
         (two (read-from-string text)))
    ;; Stability under reparsing is the property; the literal below only
    ;; pins which string it stabilises on.
    (assert (equal (wf:form-key one) (wf:form-key two)))
    (assert (equal '(:package "CST-PROBE-PACKAGE") (wf:form-key one)))
    ;; The obvious analogy, and the measurement that rejected it.
    (assert
     (not (equal (list :package (second one)) (list :package (second two)))))
    ;; FORM-EQUAL would have accepted it; key comparison does not use it.
    (assert
     (wf:form-equal (list :package (second one))
                    (list :package (second two)))))
  t)

(defun test-a-package-key-does-not-fold-case ()
  "#:probe and \"probe\" name different packages, and the key keeps them
apart. The :SYSTEM key downcases, which is right for ASDF names and wrong
for package names."
  (let ((upper (wf:form-key (read-from-string "(defpackage #:probe)")))
        (lower (wf:form-key (read-from-string "(defpackage \"probe\")"))))
    (assert (equal '(:package "PROBE") upper))
    (assert (equal '(:package "probe") lower))
    (assert (not (equal upper lower)))
    (assert
     (string= (string-downcase (second upper))
              (string-downcase (second lower)))))
  t)

(defun test-edits-an-export-clause-without-reserializing (environment)
  "The real shape of the operation: one clause of one package form.
Everything the package form says besides that clause -- its reason, its
:USE, its nicknames -- is outside the targeted range and therefore not
this operation's business."
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan
             (a::plan-cst-source-replacement "cst-probe" path
                                             '(:package "CST-PROBE-PACKAGE")
                                             (read-from-string
                                              "(:export #:alpha #:beta)")
                                             "(:export
   ;; The first group, and the reason for it.
   #:alpha
   #:beta
   #:gamma)"
                                             (read-from-string
                                              "(:export #:alpha #:beta #:gamma)"))))
       (a::replace-owned-cst-source plan environment)
       (let ((after (%text path)))
         (assert (not (string= before after)))
         (assert (search ";; Why this package exists at all." after))
         (assert (search "(:use #:cl)" after))
         (assert (search "(:local-nicknames (#:n #:cl))" after))
         (assert (search ";; A neighbour whose text must survive" after))
         (assert (search "(list 1 2 3)" after))
         (assert (search ";; The first group, and the reason for it." after))
         (assert (search "#:gamma" after))
         (let ((form (first (wf:source-forms path))))
           (assert (equal '(:package "CST-PROBE-PACKAGE") (wf:form-key form)))
           (assert
            (= 3
               (length
                (rest
                 (find-if
                  (lambda (clause)
                    (and (consp clause) (eq :export (first clause))))
                  (cddr form))))))))))
   :source +fixture-package+))

(defun test-refuses-zero-and-ambiguous-package-keys ()
  "An address that names no form, and one that names two."
  (call-with-fixture
   (lambda (path)
     (let ((before (%text path)))
       (let ((message
              (%signals
               (lambda ()
                 (a::plan-cst-source-replacement "cst-probe" path
                                                 '(:package "NOT-DEFINED-HERE")
                                                 (read-from-string
                                                  "(:export #:alpha #:beta)")
                                                 "(:export #:alpha)"
                                                 (read-from-string
                                                  "(:export #:alpha)"))))))
         (assert message)
         (assert (search "found 0" message)))
       (assert (string= before (%text path)))))
   :source +fixture-package+)
  (call-with-fixture
   (lambda (path)
     (let ((before (%text path)))
       (let ((message
              (%signals
               (lambda ()
                 (a::plan-cst-source-replacement "cst-probe" path
                                                 '(:package "TWICE")
                                                 (read-from-string
                                                  "(:use #:cl)")
                                                 "(:use)"
                                                 (read-from-string
                                                  "(:use)"))))))
         (assert message)
         (assert (search "found 2" message)))
       (assert (string= before (%text path)))))
   :source "(defpackage #:twice (:use #:cl))

(defpackage #:twice (:use #:cl))
")
  t)

(defun test-a-method-key-names-one-method ()
  "A method shares its name with its siblings, so the key carries what
tells them apart: qualifiers, and the specializers of the required
parameters, with T for an unspecialized one. &KEY and what follows do not
take part in dispatch and do not take part in the key."
  (let ((plain
         (wf:form-key
          (read-from-string "(defmethod cl-user::m ((x string) y &key z) x)")))
        (sibling
         (wf:form-key
          (read-from-string "(defmethod cl-user::m ((x integer) y) x)")))
        (around
         (wf:form-key
          (read-from-string
           "(defmethod cl-user::m :around ((x string) y) x)")))
        (again
         (wf:form-key
          (read-from-string "(defmethod cl-user::m ((x string) y &key z) x)"))))
    (assert
     (equal (list :method (intern "M" :cl-user) nil (list 'string t)) plain))
    (assert (equal plain again))
    (assert (not (equal plain sibling)))
    (assert
     (equal (list :method (intern "M" :cl-user) '(:around) (list 'string t))
            around))
    (assert (not (equal plain around))))
  t)

(defun test-an-example-key-names-one-example ()
  "A HyperDoc DEFEXAMPLE is recognised by its operator's name, as DEFSYSTEM
is, so the key needs no HyperDoc package to compute."
  (let ((key
         (wf:form-key
          (read-from-string
           "(cl-user::defexample cl-user::probe-example (list 1))"))))
    (assert (equal (list :example (intern "PROBE-EXAMPLE" :cl-user)) key))
    (assert
     (not
      (equal key
             (wf:form-key
              (read-from-string
               "(cl-user::defexample cl-user::other (list 1))"))))))
  t)

(defun test-a-class-key-names-one-class ()
  "A class is addressed by its name, as a function is."
  (let ((key
         (wf:form-key
          (read-from-string "(defclass cl-user::probe-class () ())"))))
    (assert (equal (list :class (intern "PROBE-CLASS" :cl-user)) key))
    (assert
     (not
      (equal key
             (wf:form-key
              (read-from-string "(defun cl-user::probe-class () 1)"))))))
  t)

(defun test-a-view-key-names-one-method ()
  "A view is one method of its view function, addressed by name and class."
  (let ((key
         (wf:form-key
          (read-from-string
           "(html-inspector-views:defview cl-user::probe-view (object cl-user::probe-class) nil)")))
        (sibling
         (wf:form-key
          (read-from-string
           "(html-inspector-views:defview cl-user::probe-view (object cl-user::other-class) nil)"))))
    (assert
     (equal
      (list :view (intern "PROBE-VIEW" :cl-user)
            (intern "PROBE-CLASS" :cl-user))
      key))
    (assert (not (equal key sibling)))
    (assert
     (not
      (equal key
             (wf:form-key
              (read-from-string "(defun cl-user::probe-view () 1)"))))))
  t)

(defun run-cst-replace-tests ()
  (let ((environment (a:make-authoring-environment)))
    (test-targeted-replacement-preserves-everything-else environment)
    (test-rejects-a-duplicate-target)
    (test-rejects-a-missing-target)
    (test-verification-catches-collateral-change environment)
    (test-rejects-malformed-replacement environment)
    (test-rejects-a-replacement-that-reads-as-something-else environment)
    (test-a-package-key-survives-reparsing)
    (test-a-package-key-does-not-fold-case)
    (test-edits-an-export-clause-without-reserializing environment)
    (test-refuses-zero-and-ambiguous-package-keys)
    (test-a-method-key-names-one-method)
    (test-an-example-key-names-one-example)
    (test-a-class-key-names-one-class)
    (test-a-view-key-names-one-method))
  (format t "~&CST-SOURCE-REPLACEMENT-PASS: one token changed and every other ~
byte kept; duplicate, missing and malformed targets refused with the ~
authority untouched; comment, spelling, whitespace and neighbour damage all ~
fail verification; a package form is addressed by its designator's ~
string, so one export clause can be edited while the package's reason, ~
:USE and nicknames are not; a method is addressed by its qualifiers ~
and specializers, apart from its siblings; a class and a HyperDoc ~
example by their names; and a view by its name and the class it is for.~%")
  t)
