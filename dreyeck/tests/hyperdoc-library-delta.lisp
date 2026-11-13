(defpackage #:dreyeck/hyperdoc/library-tests
  (:use #:cl)
  (:export #:run-tests))

(in-package #:dreyeck/hyperdoc/library-tests)

(defparameter +upstream+ "bdad8d9b83952b2675294b97a50edf1d5a182405")

(defparameter +paths+
  '("hyperdoc" "hyperbook" "hyperdoc-explorer" "hyperbook-explorer"
    "inspector-hyperdoc" "hyperbook-fedwiki" "hyperbook-wikipedia"
    "hyperbook-server" "hyperbook-the-book" "hyperdoc.asd" "hyperbook.asd"
    "assets/hyperbook/css" "assets/hyperbook/icons" "assets/hyperbook-server"
    "assets/hyperdoc"))

(defparameter +retained-files+
  '(("hyperbook-fedwiki/pages.lisp" . "68ca0c587e25459b59c2cc246432207f2258975c")
    ("hyperbook-fedwiki/wiki-links.lisp" . "68ca0c587e25459b59c2cc246432207f2258975c")
    ("hyperbook-fedwiki/story-items.lisp" . "38fc35dc49b0b22c754761e98b83a30dbde23691")
    ("hyperbook-server/server.lisp" . "53732270d42177eb01a46dad7940e60244ec52a2")
    ("hyperdoc/defining.lisp" . "f3de505eb21f726e52e69786c522d50f990927e0"))
  "Reusable compatibility implementations pinned to their source commits.")

(defparameter +sitemap-retention+ "99521dc6a8df21fd56fc0e9da25302bfb7b87f3f")
(defparameter +code-directory+ "f3de505eb21f726e52e69786c522d50f990927e0")

(defun source-at (root revision path)
  (if revision
      (dreyeck/git:git-run-string root "show" (format nil "~A:~A" revision path))
      (uiop:read-file-string (merge-pathnames path root) :external-format :utf-8)))

(defun forms-at (root revision path)
  (let ((*package* (if (equal "asd" (pathname-type path)) (find-package :asdf) *package*)))
    (dreyeck/workflow:source-forms (source-at root revision path))))

(defun named-form-p (form name)
  (and (consp form) (symbolp (second form))
       (string-equal (second form) name)))

(defun remove-fedwiki-extra-dependencies (forms)
  (let ((fedwiki (find-if (lambda (form) (named-form-p form "hyperbook/fedwiki")) forms)))
    (setf (getf (cddr fedwiki) :depends-on)
          (remove-if (lambda (dependency)
                       (member dependency '("clog" "flexi-streams") :test #'string-equal))
                     (getf (cddr fedwiki) :depends-on))))
  forms)

(defun source-equal (a b)
  (cond
    ((and (consp a) (consp b))
     (and (source-equal (car a) (car b)) (source-equal (cdr a) (cdr b))))
    ((and (vectorp a) (vectorp b) (not (stringp a)) (not (stringp b)))
     (and (= (length a) (length b)) (every #'source-equal a b)))
    (t (dreyeck/workflow:form-equal a b))))

(defun check-library-file (root path)
  (flet ((matches (revision)
           (string= (string-right-trim '(#\Newline #\Return) (source-at root nil path))
                    (string-right-trim '(#\Newline #\Return) (source-at root revision path)))))
    (assert
     (or (matches +upstream+)
         (let ((retained (cdr (assoc path +retained-files+ :test #'string=))))
           (cond
             (retained (matches retained))
             ((string= path "hyperbook-fedwiki/fedwiki.lisp")
              (source-equal (forms-at root nil path)
                            (remove-if (lambda (form) (named-form-p form "sitemap-snapshot"))
                                       (forms-at root +sitemap-retention+ path))))
             ((string= path "hyperdoc/core.lisp")
              (flet ((extension-p (form)
                       (some (lambda (name) (named-form-p form name))
                             '("cl-source-file-components-under" "make-hyperdoc"))))
                (let ((current (forms-at root nil path)))
                  (and (source-equal (remove-if #'extension-p current)
                                     (remove-if #'extension-p (forms-at root +upstream+ path)))
                       (source-equal (remove-if-not #'extension-p current)
                                     (remove-if-not #'extension-p (forms-at root +code-directory+ path)))))))
             ((string= path "hyperbook.asd")
              (source-equal (remove-fedwiki-extra-dependencies (forms-at root nil path))
                            (forms-at root +upstream+ path)))
             (t nil))))
     () "Unaccounted library delta against ~A: ~A" +upstream+ path)))

(DEFUN CHECK-FEDWIKI-IMAGE-COMPATIBILITY ()
  (LET* ((WIKI
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::FEDWIKI :ID
                         "fedwiki:example.invalid:8443"))
         (PAGE
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::REMOTE-FEDWIKI-PAGE :ID "image"
                         :ORIGIN WIKI :ORIGIN-ID "image" :HYPERBOOK WIKI))
         (DATA (MAKE-HASH-TABLE :TEST #'EQUAL))
         (ITEM
          (MAKE-INSTANCE 'HYPERBOOK/FEDWIKI::STORY-ITEM :ITEM-TYPE :IMAGE :ID
                         "image" :TEXT "" :DATA DATA)))
    (ASSERT
     (STRING= "example.invalid:8443" (HYPERBOOK/FEDWIKI::DOMAIN-NAME-OF WIKI)))
    (SETF (GETHASH "url" DATA) "/assets/example.png"
          (GETHASH "width" DATA) 640
          (GETHASH "height" DATA) 480
          (GETHASH "size" DATA) "wide")
    (ASSERT
     (EQUAL '(640 480 "wide")
            (MULTIPLE-VALUE-LIST
             (HYPERBOOK/FEDWIKI::STORY-ITEM-IMAGE-PRESENTATION-HINTS ITEM))))
    (ASSERT
     (STRING= "https://example.invalid:8443/assets/example.png"
              (HYPERBOOK/FEDWIKI::RESOLVE-STORY-ITEM-URL "/assets/example.png"
                                                         PAGE)))
    (DOLIST
        (URL
         '("https://other.invalid/p.png" "//other.invalid/p.png" "image.png"))
      (ASSERT
       (EQUAL URL (HYPERBOOK/FEDWIKI::RESOLVE-STORY-ITEM-URL URL PAGE))))
    (LET* ((VIEW
            (HTML-INSPECTOR-VIEWS:HTML-VIEW :TITLE "Image contract"
                                            (HYPERBOOK/FEDWIKI::RENDER-STORY-ITEM
                                             :IMAGE ITEM PAGE)))
           (HTML (HTML-INSPECTOR-VIEWS:VIEW-HTML VIEW)))
      (DOLIST
          (MARKER
           '("https://example.invalid:8443/assets/example.png" "640" "480"
             "data-fedwiki-size" "max-width: 100%" "height: auto"
             "figcaption"))
        (ASSERT (SEARCH MARKER HTML))))
    (SETF (GETHASH "width" DATA) -1
          (GETHASH "height" DATA) "480"
          (GETHASH "size" DATA) "")
    (ASSERT
     (EQUAL '(NIL NIL NIL)
            (MULTIPLE-VALUE-LIST
             (HYPERBOOK/FEDWIKI::STORY-ITEM-IMAGE-PRESENTATION-HINTS ITEM)))))
  T)

(defun run-tests ()
  (let* ((root (asdf:system-source-directory "dreyeck"))
         (untracked (apply #'dreyeck/git:git-run-string root "ls-files"
                           "--others" "--exclude-standard" "--" +paths+))
         (changed (apply #'dreyeck/git:git-run-string root "diff"
                         "--name-only" "--no-renames" +upstream+ "--" +paths+)))
    (assert (zerop (length untracked)) () "Untracked library sources: ~A" untracked)
    (dolist (path (remove "" (uiop:split-string changed :separator '(#\Newline))
                          :test #'string=))
      (check-library-file root path)))
  (check-fedwiki-image-compatibility)
  (format t "~&HYPERDOC-LIBRARY-PASS: upstream source and retained compatibility verified.~%")
  t)
