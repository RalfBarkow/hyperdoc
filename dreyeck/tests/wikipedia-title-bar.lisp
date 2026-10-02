;;;; The temporary Wikipedia title-bar adapter: an ordinary link, safely written,
;;;; for as long as the pinned upstream method still needs replacing.

(defpackage #:dreyeck/wikipedia-title-bar/tests
  (:use #:cl)
  (:export #:run-tests))

(in-package #:dreyeck/wikipedia-title-bar/tests)

(defun %page (title)
  "An unregistered Wikipedia page, as GET-PAGE makes one: nothing is fetched."
  (make-instance 'hyperbook/wikipedia::wikipedia-page
                 :hyperbook (hyperbook/wikipedia::make-wikipedia "en" "Wikipedia" "Main Page")
                 :id title :title title))

(defun %elements (node)
  "Every element under NODE, depth first."
  (loop for child across (plump:children node)
        when (plump:element-p child) collect child
        when (plump:nesting-node-p child) append (%elements child)))

(defun %counting-open-browser (thunk)
  "THUNK's value, and how often it called CLOG:OPEN-BROWSER, stubbed meanwhile."
  (let ((original (symbol-function 'clog:open-browser))
        (calls 0))
    (unwind-protect
         (progn
           (setf (symbol-function 'clog:open-browser)
                 (lambda (&rest arguments) (declare (ignore arguments)) (incf calls) nil))
           (values (funcall thunk) calls))
      (setf (symbol-function 'clog:open-browser) original))))

(defun check-title-bar-link (title)
  "The title bar of a page titled TITLE is one link to PAGE-URL and nothing else:
no reference for the Inspector to invoke, and no element or attribute that the
title's quotes or markup could add. Every reference is clicked first, as the
Inspector would, so that an action shows up in CLOG:OPEN-BROWSER's count."
  (let* ((page (%page title))
         (view (html-inspector-views:title-bar-action-buttons page))
         (html (html-inspector-views:view-html view))
         (elements (%elements (plump:parse html)))
         (link (first elements))
         (url (hyperbook/wikipedia::page-url page))
         (href (plump:attribute link "href")))
    (dolist (reference (html-inspector-views:view-references view))
      (html-inspector-views:eval-thunk (cdr reference)))
    (assert (null (html-inspector-views:view-references view)) ()
            "~S: the title bar offers ~S." title (html-inspector-views:view-references view))
    (assert (and (= 1 (length elements)) (string= "a" (plump:tag-name link))) ()
            "~S: the title bar is ~S." title html)
    (assert (equal '("class" "href" "target")
                   (sort (loop for key being the hash-keys of (plump:attributes link) collect key)
                         #'string<))
            () "~S: the link has the attributes of ~S." title html)
    (assert (string= url (plump:decode-entities href)) ()
            "~S: the href reads back as ~S, not ~S." title (plump:decode-entities href) url)
    (assert (string= "_blank" (plump:attribute link "target")))
    (assert (string= "inspector-action" (plump:attribute link "class")))
    (assert (string= "Open in browser" (plump:text link)))
    url))

(defun check-titles ()
  (multiple-value-bind (urls calls)
      (%counting-open-browser
       (lambda ()
         (mapcar #'check-title-bar-link
                 '("Blog" "Schrödinger's cat" "a\"b<c>&d" "Schr%C3%B6dinger%27s cat"))))
    (assert (string= "https://en.wikipedia.org/wiki/Blog" (first urls)))
    ;; A title taken from Wikipedia's own links arrives percent-encoded and
    ;; leaves as it came: no second encoding.
    (assert (string= "https://en.wikipedia.org/wiki/Schr%C3%B6dinger%27s_cat" (fourth urls)))
    (assert (notany (lambda (url) (search "%25" url)) urls))
    (assert (zerop calls) () "CLOG:OPEN-BROWSER was called ~D time(s)." calls))
  t)

;;; When the adapter becomes obsolete

(defparameter +replaced-upstream-method+
  "(defmethod views:title-bar-action-buttons ((page wikipedia-page))
  (views:action-button \"Open in browser\"
                       (views:thunk (clog:open-browser :url (page-url page))
                         nil)))"
  "Upstream's method as of 8a114919, verbatim: the one the adapter replaces.")

(defparameter +linked-upstream-method+
  "(defmethod views:title-bar-action-buttons ((page wikipedia-page))
  (views:html
    (:a :href (cl-who:escape-string (page-url page))
        :target \"_blank\" :class \"inspector-action\"
        \"Open in browser\")))"
  "The same method as a link, as upstream might adopt it.")

(defun %method-form (text)
  "TEXT, one method as upstream's file holds it, read as the library-boundary
test reads that file: after the file's IN-PACKAGE."
  (second (dreyeck/workflow:source-forms
           (format nil "(in-package :hyperbook/wikipedia)~%~A" text))))

(defun upstream-still-replaced-p (source)
  "Whether SOURCE, the text of hyperbook-wikipedia/wikipedia.lisp, defines the
method the adapter replaces exactly once and exactly as it was. Compared as a
form, so layout and the rest of the file do not matter."
  (let* ((replaced (%method-form +replaced-upstream-method+))
         (key (dreyeck/workflow:form-key replaced))
         (defining (remove key (dreyeck/workflow:source-forms source)
                           :key #'dreyeck/workflow:form-key :test-not #'equal)))
    (and (= 1 (length defining))
         (dreyeck/workflow:form-equal replaced (first defining)))))

(defun check-upstream-still-needs-the-adapter ()
  "The pinned upstream method is still the server-side action button the
adapter replaces. When this fails, read that method: if it navigates in the
client, delete the adapter."
  (let* ((pinned (asdf:system-relative-pathname "hyperbook/wikipedia"
                                                "hyperbook-wikipedia/wikipedia.lisp"))
         (source (uiop:read-file-string pinned))
         (start (search +replaced-upstream-method+ source))
         (end (and start (+ start (length +replaced-upstream-method+)))))
    (assert (upstream-still-replaced-p source) ()
            "The downstream Wikipedia navigation adapter may now be obsolete; inspect the pinned ~
upstream implementation of TITLE-BAR-ACTION-BUTTONS for WIKIPEDIA-PAGE in ~A." pinned)
    ;; The comparison sees that one method change, and only that.
    (assert start)
    (assert (not (upstream-still-replaced-p
                  (concatenate 'string (subseq source 0 start) +linked-upstream-method+ (subseq source end)))))
    (assert (upstream-still-replaced-p
             (concatenate 'string (subseq source 0 start)
                          (substitute #\Space #\Newline +replaced-upstream-method+)
                          (subseq source end)))))
  t)

(defun run-tests ()
  (check-titles)
  (check-upstream-still-needs-the-adapter)
  (format t "~&WIKIPEDIA-TITLE-BAR-PASS: one ordinary link to PAGE-URL in a new tab, no reference to invoke, ~
CLOG:OPEN-BROWSER never called; quoted, marked-up and percent-encoded titles read back exactly; the pinned ~
upstream method is still the action button the adapter replaces.~%")
  t)
