;;;; Inspector views for source-backed Git commit objects.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc/inspector)

(defun render-git-pre (string)
  (html-inspector-views:html
    (:pre :style "white-space: pre-wrap;"
          (html-inspector-views:esc string))))

(defun render-git-error (condition)
  (html-inspector-views:html
    (:pre :style "white-space: pre-wrap;"
          (html-inspector-views:esc (format nil "~A" condition)))))

(defmethod html-inspector-views:text-representation
    ((commit hyperdoc::git-commit))
  (format nil "Git commit ~A"
          (subseq (hyperdoc::git-commit-hash-of commit)
                  0
                  (min 12
                       (length (hyperdoc::git-commit-hash-of commit))))))

(html-inspector-views:defview 👀commit (commit hyperdoc::git-commit)
  (html-inspector-views:html-view :title "Commit" :priority 1
    (handler-case
        (render-git-pre
         (with-output-to-string (s)
           (format s "Repository: ~A~%"
                   (hyperdoc::git-commit-repository-of commit))
           (format s "Commit-ish: ~A~%"
                   (hyperdoc::git-commit-ish-of commit))
           (format s "Hash: ~A~%~%"
                   (hyperdoc::git-commit-hash-of commit))
           (write-string
            (hyperdoc::git-commit-one-line commit)
            s)))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀metadata (commit hyperdoc::git-commit)
  (html-inspector-views:html-view :title "Metadata" :priority 2
    (handler-case
        (render-git-pre
         (hyperdoc::git-commit-metadata commit))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀stat (commit hyperdoc::git-commit)
  (html-inspector-views:html-view :title "Stat" :priority 3
    (handler-case
        (render-git-pre
         (hyperdoc::git-commit-stat commit))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀changed-files (commit hyperdoc::git-commit)
  (html-inspector-views:html-view :title "Changed files" :priority 4
    (handler-case
        (render-git-pre
         (format nil "~{~A~%~}"
                 (hyperdoc::git-commit-changed-files commit)))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀patch (commit hyperdoc::git-commit)
  (html-inspector-views:html-view :title "Patch" :priority 5
    (handler-case
        (render-git-pre
         (hyperdoc::git-commit-patch commit))
      (condition (condition)
        (render-git-error condition)))))
