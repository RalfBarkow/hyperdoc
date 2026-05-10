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

(defmethod html-inspector-views:text-representation
    ((file hyperdoc::git-file-at-commit))
  (format nil "~A @ ~A"
          (hyperdoc::git-file-path-of file)
          (subseq
           (hyperdoc::git-commit-hash-of
            (hyperdoc::git-file-commit-of file))
           0
           12)))

(defmethod html-inspector-views:text-representation
    ((change hyperdoc::git-commit-file-change))
  (format nil "~A ~A"
          (hyperdoc::git-commit-file-change-status-of change)
          (hyperdoc::git-commit-file-change-path-of change)))

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
        (html-inspector-views:html
          (:table :class "inspector-table"
                  (:tr
                   (:th (html-inspector-views:esc "Status"))
                   (:th (html-inspector-views:esc "File"))
                   (:th (html-inspector-views:esc "Previous path")))
                  (dolist (change
                            (hyperdoc::git-commit-file-changes commit))
                    (html-inspector-views:html
                      (:tr
                       (:td
                        (:tt
                         (html-inspector-views:esc
                          (hyperdoc::git-commit-file-change-status-of
                           change))))
                       (:td
                        (html-inspector-views:object-ref
                         (hyperdoc::git-commit-file-change-file change)
                         :display
                         (hyperdoc::git-commit-file-change-path-of
                          change)))
                       (:td
                        (let ((old-path
                                (hyperdoc::git-commit-file-change-old-path-of
                                 change)))
                          (if old-path
                              (html-inspector-views:html
                                (:code
                                 (html-inspector-views:esc old-path)))
                              (html-inspector-views:esc "")))))))))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀patch (commit hyperdoc::git-commit)
  (html-inspector-views:html-view :title "Patch" :priority 5
    (handler-case
        (render-git-pre
         (hyperdoc::git-commit-patch commit))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀overview (file hyperdoc::git-file-at-commit)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (:tr
               (:td (html-inspector-views:esc "Commit"))
               (:td
                (html-inspector-views:object-ref
                 (hyperdoc::git-file-commit-of file))))
              (:tr
               (:td (html-inspector-views:esc "Path"))
               (:td
                (:code
                 (html-inspector-views:esc
                  (hyperdoc::git-file-path-of file)))))
              (:tr
               (:td (html-inspector-views:esc "Blob spec"))
               (:td
                (:code
                 (html-inspector-views:esc
                  (hyperdoc::git-file-blob-spec file)))))))))

(html-inspector-views:defview 👀contents (file hyperdoc::git-file-at-commit)
  (html-inspector-views:html-view :title "Contents" :priority 2
    (handler-case
        (render-git-pre
         (hyperdoc::git-file-contents file))
      (condition (condition)
        (render-git-error condition)))))
