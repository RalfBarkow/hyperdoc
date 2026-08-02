;;;; Regression tests for stored FedWiki link lookup contracts

(defpackage :hyperbook/fedwiki/tests
  (:use :cl)
  (:export :run-wiki-link-slug-contract-test
           :run-wiki-link-slug-contract-tests))

(in-package :hyperbook/fedwiki/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments))))

(defun make-source-page ()
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                             :id "fedwiki:example.test")))
    (setf (hyperbook/fedwiki::status-of wiki) t)
    (hyperbook/fedwiki::make-fedwiki-page
     wiki "source-page" "Source Page")))

(defun call-without-plugin-page-lookup (thunk)
  (let* ((name 'hyperbook/fedwiki::get-plugin-page)
         (original (symbol-function name)))
    (unwind-protect
         (progn
           (setf (symbol-function name)
                 (lambda (wiki slug)
                   (declare (ignore wiki slug))
                   nil))
           (funcall thunk))
      (setf (symbol-function name) original))))

(defun run-wiki-link-slug-contract-test ()
  (let* ((source-page (make-source-page))
         (target-title "Missing Human Title")
         (target-slug "missing-human-title")
         (link (hyperbook/fedwiki::make-wiki-link
                source-page
                :target-title target-title
                :target-slug target-slug))
         (result
           (call-without-plugin-page-lookup
            (lambda ()
              (html-inspector-views:eval-thunk
               (hyperbook:thunk-of link))))))
    (check (typep result 'hyperbook/fedwiki::wiki-lookup-failure)
           "The stored Wiki-link thunk returned ~S instead of WIKI-LOOKUP-FAILURE."
           result)
    (check (equal target-title
                  (hyperbook/fedwiki::target-title-of link))
           "The Wiki link did not preserve TARGET-TITLE ~S."
           target-title)
    (check (equal target-slug
                  (hyperbook/fedwiki::target-slug-of link))
           "The Wiki link did not preserve TARGET-SLUG ~S."
           target-slug)
    (check (slot-boundp result 'hyperbook/fedwiki::slug)
           "The lookup failure has no SLUG evidence.")
    (check (equal target-slug
                  (slot-value result 'hyperbook/fedwiki::slug))
           "The lookup failure did not preserve missing slug ~S."
           target-slug)
    (let ((title-bound-p
            (slot-boundp result 'hyperbook/fedwiki::title)))
      (format t "Missing-target evidence: slug=~S title-bound=~S title=~S~%"
              (slot-value result 'hyperbook/fedwiki::slug)
              title-bound-p
              (and title-bound-p
                   (slot-value result 'hyperbook/fedwiki::title)))
      (check (not title-bound-p)
             "A slug-based Wiki-link lookup exposed TARGET-SLUG ~S as TITLE evidence."
             target-slug))
    (format t "Wiki-link slug contract test passed.~%")
    t))

(defun run-existing-wiki-link-slug-contract-test ()
  (let* ((source-page (make-source-page))
         (wiki (hyperbook:hyperbook-of source-page))
         (target-title "Stored Human Target")
         (target-slug "stored-human-target")
         (target-page
           (hyperbook/fedwiki::make-fedwiki-page
            wiki target-slug target-title))
         (link (hyperbook/fedwiki::make-wiki-link
                source-page
                :target-title target-title
                :target-slug target-slug)))
    (setf (gethash target-slug (hyperbook/fedwiki::pages-of wiki))
          target-page)
    (check (eq target-page
               (html-inspector-views:eval-thunk
                (hyperbook:thunk-of link)))
           "The stored Wiki-link thunk did not resolve its TARGET-SLUG.")
    (check (equal target-title
                  (hyperbook/fedwiki::target-title-of link))
           "Successful slug lookup changed TARGET-TITLE.")
    (check (equal target-slug
                  (hyperbook/fedwiki::target-slug-of link))
           "Successful slug lookup changed TARGET-SLUG.")
    t))

(defun call-with-counted-slug (thunk)
  (let* ((name 'hyperbook/fedwiki::slug)
         (original (symbol-function name))
         (call-count 0))
    (unwind-protect
         (progn
           (setf (symbol-function name)
                 (lambda (title)
                   (incf call-count)
                   (funcall original title)))
           (values (funcall thunk) call-count))
      (setf (symbol-function name) original))))

(defun run-title-lookup-contract-test ()
  (let* ((source-page (make-source-page))
         (wiki (hyperbook:hyperbook-of source-page))
         (target-title "Title Lookup Target")
         (target-slug "title-lookup-target")
         (target-page
           (hyperbook/fedwiki::make-fedwiki-page
            wiki target-slug target-title)))
    (setf (gethash target-slug (hyperbook/fedwiki::pages-of wiki))
          target-page)
    (multiple-value-bind (result slug-call-count)
        (call-with-counted-slug
         (lambda ()
           (hyperbook/fedwiki::find-target-by-title
            target-title source-page)))
      (check (eq target-page result)
             "FIND-TARGET-BY-TITLE did not resolve a genuine title.")
      (check (= 1 slug-call-count)
             "FIND-TARGET-BY-TITLE derived the slug ~D times instead of once."
             slug-call-count)
      t)))

(defun run-wiki-link-slug-contract-tests ()
  (run-wiki-link-slug-contract-test)
  (run-existing-wiki-link-slug-contract-test)
  (run-title-lookup-contract-test)
  (format t "All Wiki-link slug contract tests passed.~%")
  t)
