;;;; Inspector views for Dreyeck's source-backed Git commit objects.

(in-package #:dreyeck/inspector/git)

(defun render-git-pre (string)
  (html-inspector-views:html
    (:pre :style "white-space: pre-wrap;"
          (html-inspector-views:esc string))))

(defun render-git-error (condition)
  (html-inspector-views:html
    (:pre :style "white-space: pre-wrap;"
          (html-inspector-views:esc (format nil "~A" condition)))))

(defmethod html-inspector-views:text-representation
    ((commit dreyeck/git:git-commit))
  (format nil "Git commit ~A"
          (subseq (dreyeck/git:git-commit-hash-of commit)
                  0
                  (min 12
                       (length (dreyeck/git:git-commit-hash-of commit))))))

(defmethod html-inspector-views:text-representation
    ((file dreyeck/git:git-file-at-commit))
  (format nil "~A @ ~A"
          (dreyeck/git:git-file-path-of file)
          (subseq
           (dreyeck/git:git-commit-hash-of
            (dreyeck/git:git-file-commit-of file))
           0
           12)))

(defmethod html-inspector-views:text-representation
    ((change dreyeck/git:git-commit-file-change))
  (format nil "~A ~A"
          (dreyeck/git:git-commit-file-change-status-of change)
          (dreyeck/git:git-commit-file-change-path-of change)))

(html-inspector-views:defview 👀commit (commit dreyeck/git:git-commit)
  (html-inspector-views:html-view :title "Commit" :priority 1
    (handler-case
        (render-git-pre
         (with-output-to-string (stream)
           (format stream "Repository: ~A~%"
                   (dreyeck/git:git-commit-repository-of commit))
           (format stream "Commit-ish: ~A~%"
                   (dreyeck/git:git-commit-ish-of commit))
           (format stream "Hash: ~A~%~%"
                   (dreyeck/git:git-commit-hash-of commit))
           (write-string
            (dreyeck/git:git-commit-one-line commit)
            stream)))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀metadata (commit dreyeck/git:git-commit)
  (html-inspector-views:html-view :title "Metadata" :priority 2
    (handler-case
        (render-git-pre
         (dreyeck/git:git-commit-metadata commit))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀stat (commit dreyeck/git:git-commit)
  (html-inspector-views:html-view :title "Stat" :priority 3
    (handler-case
        (render-git-pre
         (dreyeck/git:git-commit-stat commit))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀changed-files
    (commit dreyeck/git:git-commit)
  (html-inspector-views:html-view :title "Changed files" :priority 4
    (handler-case
        (html-inspector-views:html
          (:table :class "inspector-table"
                  (:tr
                   (:th (html-inspector-views:esc "Status"))
                   (:th (html-inspector-views:esc "File"))
                   (:th (html-inspector-views:esc "Previous path")))
                  (dolist (change
                            (dreyeck/git:git-commit-file-changes commit))
                    (html-inspector-views:html
                      (:tr
                       (:td
                        (:tt
                         (html-inspector-views:esc
                          (dreyeck/git:git-commit-file-change-status-of
                           change))))
                       (:td
                        (html-inspector-views:object-ref
                         (dreyeck/git:git-commit-file-change-file change)
                         :display
                         (dreyeck/git:git-commit-file-change-path-of
                          change)))
                       (:td
                        (let ((old-path
                                (dreyeck/git:git-commit-file-change-old-path-of
                                 change)))
                          (if old-path
                              (html-inspector-views:html
                                (:code
                                 (html-inspector-views:esc old-path)))
                              (html-inspector-views:esc "")))))))))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀patch (commit dreyeck/git:git-commit)
  (html-inspector-views:html-view :title "Patch" :priority 5
    (handler-case
        (render-git-pre
         (dreyeck/git:git-commit-patch commit))
      (condition (condition)
        (render-git-error condition)))))

(html-inspector-views:defview 👀overview
    (file dreyeck/git:git-file-at-commit)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (:tr
               (:td (html-inspector-views:esc "Commit"))
               (:td
                (html-inspector-views:object-ref
                 (dreyeck/git:git-file-commit-of file))))
              (:tr
               (:td (html-inspector-views:esc "Path"))
               (:td
                (:code
                 (html-inspector-views:esc
                  (dreyeck/git:git-file-path-of file)))))
              (:tr
               (:td (html-inspector-views:esc "Blob spec"))
               (:td
                (:code
                 (html-inspector-views:esc
                  (dreyeck/git:git-file-blob-spec file)))))))))

(defun git-file-path-type-string (file)
  (let ((type (pathname-type
               (pathname
                (dreyeck/git:git-file-path-of file)))))
    (and type
         (string-downcase type))))

(defun git-file-lisp-source-p (file)
  (member (git-file-path-type-string file)
          '("lisp" "asd" "cl" "lsp")
          :test #'string=))

(defun git-file-html-source-p (file)
  (member (git-file-path-type-string file)
          '("html" "htm")
          :test #'string=))

(defun git-file-content-code-view (file)
  (let ((contents
          (html-inspector-views:thunk
            (dreyeck/git:git-file-contents file))))
    (cond
      ((git-file-lisp-source-p file)
       (html-inspector-views:lisp-code-view
        contents
        :title "Blob contents"
        :priority 2))
      ((git-file-html-source-p file)
       (html-inspector-views:html-code-view
        contents
        :title "Blob contents"
        :priority 2))
      (t
       (html-inspector-views:html-view
        :title "Blob contents"
        :priority 2
        (html-inspector-views:html
          (:pre :style "white-space: pre-wrap;"
                (html-inspector-views:esc
                 (html-inspector-views:eval-thunk contents)))))))))

(html-inspector-views:defview 👀contents
    (file dreyeck/git:git-file-at-commit)
  (handler-case
      (html-inspector-views:rename
       (git-file-content-code-view file)
       :title "Contents"
       :priority 2)
    (condition (condition)
      (render-git-error condition))))
