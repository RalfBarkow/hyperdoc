(defpackage #:dreyeck/ctm-page-authoring-documentation/tests
  (:use #:cl)
  (:export #:run-tests))
(in-package #:dreyeck/ctm-page-authoring-documentation/tests)

;; The documentation says what the code is. Here the links it makes are followed: each expression behind a
;; link must evaluate in its page's package to an object, each link to a page must name a page that exists,
;; and the pages must reach one another. Identities and reachability are checked, not how many there are.

(defvar *checks* 0)
(defmacro check (form) `(progn (incf *checks*) (assert ,form)))

(defparameter +pages+ '("Item Edit Path in HyperDoc" "Authoring the CTM Plan Page" "CTM Plan Page WBS Dictionary"))

(defun page-source (title)
  (uiop:read-file-string (asdf:system-relative-pathname "dreyeck/work/reading" (format nil "dreyeck/pages/work/~A.html" title))
                         :external-format :utf-8))

(defun unescape (string)
  (let ((string (ppcre-free-replace string "&quot;" "\"")))
    (ppcre-free-replace (ppcre-free-replace string "&lt;" "<") "&amp;" "&")))

(defun ppcre-free-replace (string from to)
  (with-output-to-string (out)
    (loop with start = 0
          for at = (search from string :start2 start)
          do (write-string string out :start start :end (or at (length string)))
             (if at (progn (write-string to out) (setf start (+ at (length from)))) (return)))))

(defun attribute-values (source attribute)
  "The values of ATTRIBUTE=\"...\" or ATTRIBUTE='...' in SOURCE."
  (let ((marker (format nil " ~A=" attribute)) (values nil) (start 0))
    (loop for at = (search marker source :start2 start)
          while at
          do (let* ((open (+ at (length marker))) (quote (char source open))
                    (close (position quote source :start (1+ open))))
               (push (unescape (subseq source (1+ open) close)) values)
               (setf start close)))
    (nreverse values)))

(defun page-package (source)
  (let* ((open (search "<in-package>" source)) (close (search "</in-package>" source)))
    (find-package (string-upcase (subseq source (+ open (length "<in-package>")) close)))))

(defun check-expressions (title)
  (let* ((source (page-source title)) (package (page-package source)))
    (check package)
    (dolist (text (attribute-values source "expr"))
      (let ((value (let ((*package* package)) (eval (read-from-string text)))))
        (check value)))))

(defun check-pages ()
  (let ((titles (mapcar (lambda (file) (subseq (file-namestring file) 0 (- (length (file-namestring file)) (length ".html"))))
                        (remove "html" (uiop:directory-files (asdf:system-relative-pathname "dreyeck/work/reading" "dreyeck/pages/work/"))
                                :key #'pathname-type :test-not #'equal))))
    (check (member "Item Edit Path in HyperDoc" titles :test #'equal))
    (dolist (title '("Item Edit Path in HyperDoc" "CTM Plan Page WBS Dictionary"))
      (dolist (target (attribute-values (page-source title) "page"))
        (check (member target titles :test #'equal))))))

(defun check-reachability ()
  (let ((new "Item Edit Path in HyperDoc"))
    (dolist (from '("Authoring the CTM Plan Page" "Work Breakdown" "Deriving HyperDoc Authoring Constraints"))
      (check (member new (attribute-values (page-source from) "page") :test #'equal)))
    ;; and back to the pages it describes
    (check (member "Authoring the CTM Plan Page" (attribute-values (page-source new) "page") :test #'equal))
    (check (member "Work Breakdown" (attribute-values (page-source new) "page") :test #'equal))))

(defun check-optional-objects ()
  ;; Where the system is loaded the link is the real object; where it is not, it is an explanation and no condition.
  (let ((optional (find-symbol "OPTIONAL-OBJECT" "DREYECK/WORK/CTM-PAGE-AUTHORING")))
    (check (typep (funcall optional :class "dreyeck/fedwiki-item-edit-execution" "item-edit-completion" "x") 'class))
    (check (functionp (funcall optional :function "dreyeck/fedwiki-item-edit-execution" "execute-completed-edit" "x")))
    (let ((absent (funcall optional :class "dreyeck/not-a-package" "something" "dreyeck/some-system")))
      (check (stringp absent))
      (check (search "dreyeck/some-system" absent))
      (check (not (typep absent 'condition))))
    ;; every optional link of the pages names a package that this system loads, so locally none falls back
    (dolist (title +pages+)
      (let ((source (page-source title)))
        (dolist (text (attribute-values source "expr"))
          (when (search "(optional-object" text)
            (check (not (stringp (let ((*package* (find-package "DREYECK/WORK/CTM-PAGE-AUTHORING"))) (eval (read-from-string text))))))))))))

(defun check-states-are-kept-apart ()
  ;; The implementation state names the six statements and does not let one stand for another.
  (let ((source (page-source "Authoring the CTM Plan Page")))
    (dolist (statement '("Integrated in source" "Locally executable" "Tested on temporary copies"
                         "Read in the local Inspector" "Served on dreyeck.ch" "Accepted"))
      (check (search statement source)))))

(defun run-tests ()
  (let ((*checks* 0))
    (dolist (title +pages+) (check-expressions title))
    (check-pages)
    (check-reachability)
    (check-optional-objects)
    (check-states-are-kept-apart)
    (format t "~&CTM-PAGE-AUTHORING-DOCUMENTATION-PASS: ~D checks; every expression link of the three pages evaluates to an object in its package, every page link names a page, the new page is reachable from the Work item, the Item page and the derivation, and the six statements of the implementation state are named.~%" *checks*)
    t))
