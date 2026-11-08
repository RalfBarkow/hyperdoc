;;;; Do PR #31 and PR #32 order the candidate sites identically? Reads ONLY the pure list functions of both PRs from their
;;;; source files (PR31_TREE, PR32_TREE = unmodified extractions of befce10 and e1ab2f5) with *READ-EVAL* NIL, defines them in
;;;; two private packages and compares them on 20 000 seeded random inputs. Loads no system, no SHOP3, no page code.
;;;;   PR #31: PROMOTE, CANDIDATE-CONTEXT          (dreyeck/work/link-resolution.lisp)
;;;;   PR #32: JAVA-PAGE-CONTEXT, JAVA-PANEL-CONTEXT, JAVA-LINK-CANDIDATES (dreyeck/work/fedwiki-link-resolution.lisp)
(require :asdf)
(defpackage #:order-pr31 (:use #:cl))
(defpackage #:order-pr32 (:use #:cl))
(defun read-defuns (tree relative package names)
  "Read each top-level (DEFUN name ...) of NAMES from the file's text as data; nothing else in the file is read."
  (let* ((path (merge-pathnames relative (uiop:ensure-directory-pathname tree)))
         (text (uiop:read-file-string path))
         (*read-eval* nil) (*package* (find-package package)))
    (loop for name in names
          for start = (or (search (format nil "~%(defun ~(~A~) " name) text) (error "No DEFUN ~A in ~A" name path))
          for form = (read-from-string text t nil :start (1+ start))
          do (assert (and (eq (first form) 'defun) (string-equal (symbol-name (second form)) name)))
             (eval form))))
(read-defuns (uiop:getenv "PR31_TREE") "dreyeck/work/link-resolution.lisp" '#:order-pr31 '("promote" "candidate-context"))
(read-defuns (uiop:getenv "PR32_TREE") "dreyeck/work/fedwiki-link-resolution.lisp" '#:order-pr32
             '("java-page-context" "java-panel-context" "java-link-candidates"))
(let ((*random-state* (sb-ext:seed-random-state 11560)) (sites '("o" "a" "b" "c" nil)) (diff 0) (n 20000))
  (dotimes (i n)
    (let* ((journal (loop repeat (random 7) collect (nth (random 5) sites)))
           (panel (nth (random 4) sites)) (item (nth (random 5) sites))
           (a (order-pr31::candidate-context "o" panel item journal))
           (b (mapcar #'car (order-pr32::java-link-candidates :origin "o" :panel-site panel :item-site item :journal-sites journal))))
      (unless (equal a b)
        (incf diff)
        (when (< diff 4) (format t "~&ORDER-DIFF journal=~S panel=~S item=~S pr31=~S pr32=~S~%" journal panel item a b)))))
  (format t "~&ORDER-EQUIVALENCE ~D random inputs, ~D differences~%" n diff))
