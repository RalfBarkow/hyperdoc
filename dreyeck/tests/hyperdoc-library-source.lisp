(defpackage #:dreyeck/hyperdoc/library-source-tests
  (:use #:cl)
  (:local-nicknames (#:src #:dreyeck/asdf-source))
  (:export #:run-tests))

(in-package #:dreyeck/hyperdoc/library-source-tests)

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

(defun source-nodes (root revision path)
  (multiple-value-bind (nodes issues)
      (src:scan-asdf-source (source-at root revision path))
    (when issues
      (error "Cannot scan ~A at ~A: ~S" path (or revision :worktree) issues))
    nodes))

(defun source-tree (node)
  (if (eq :list (src:asdf-source-node-kind node))
      (mapcar #'source-tree (src:asdf-source-node-children node))
      (src:asdf-source-node-raw node)))

(defun named-form-p (node head name)
  (let ((children (src:asdf-source-node-children node)))
    (and (second children)
         (equal head (src:simple-asdf-designator-name (first children)))
         (equal name (src:simple-asdf-designator-name (second children))))))

(defun code-directory-form-p (node)
  (or (named-form-p node "defun" "cl-source-file-components-under")
      (named-form-p node "defun" "make-hyperdoc")))

(defun fedwiki-dependency-trees (node)
  (mapcar
   (lambda (child)
     (if (eq child (src:depends-on-node node))
         (let ((dependencies (src:asdf-source-node-children child))
               (compatibility-dependencies '("#:clog" "#:flexi-streams")))
           (dolist (name compatibility-dependencies)
             (assert (= 1 (count name dependencies :test #'equal
                                 :key #'src:asdf-source-node-raw))))
           (mapcar #'source-tree
                   (remove-if (lambda (dependency)
                                (member (src:asdf-source-node-raw dependency)
                                        compatibility-dependencies :test #'equal))
                              dependencies)))
         (source-tree child)))
   (src:asdf-source-node-children node)))

(defun library-asd-tree (nodes)
  (mapcar (lambda (node)
            (if (named-form-p node "defsystem" "hyperbook/fedwiki")
                (fedwiki-dependency-trees node)
                (source-tree node)))
          nodes))

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
              (equal (mapcar #'source-tree (source-nodes root nil path))
                     (mapcar #'source-tree
                             (remove-if (lambda (node)
                                          (named-form-p node "defun" "sitemap-snapshot"))
                                        (source-nodes root +sitemap-retention+ path)))))
             ((string= path "hyperdoc/core.lisp")
              (let ((current (source-nodes root nil path)))
                (and (equal (mapcar #'source-tree (remove-if #'code-directory-form-p current))
                            (mapcar #'source-tree
                                    (remove-if #'code-directory-form-p
                                               (source-nodes root +upstream+ path))))
                     (equal (mapcar #'source-tree (remove-if-not #'code-directory-form-p current))
                            (mapcar #'source-tree
                                    (remove-if-not #'code-directory-form-p
                                                   (source-nodes root +code-directory+ path)))))))
             ((string= path "hyperbook.asd")
              (equal (library-asd-tree (source-nodes root nil path))
                     (mapcar #'source-tree (source-nodes root +upstream+ path))))
             (t nil))))
     () "Unaccounted library delta against ~A: ~A" +upstream+ path)))

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
  (format t "~&HYPERDOC-LIBRARY-SOURCE-PASS: upstream source and retained compatibility verified.~%")
  t)
