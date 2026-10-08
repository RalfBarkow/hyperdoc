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

(defun git-inspection-commit (object)
  (etypecase object
    (dreyeck/git:git-commit object)
    (dreyeck/git:git-file-at-commit (dreyeck/git:git-file-commit-of object))))

(defun render-git-unavailable (object status)
  (let ((commit (git-inspection-commit object)))
    (html-inspector-views:html
      (:p
       (cl-who:esc
        (ecase status
          (:checkout-unavailable
           "Local Git inspection is unavailable: this runtime has no usable checkout for this revision.")
          (:commit-unavailable
           "Local Git inspection is unavailable: the exact commit object is absent from this checkout.")
          (:blob-unavailable
           "Local Git inspection is unavailable: the exact file blob is absent from this checkout."))))
      (:p "Full OID: "
       (:code (cl-who:esc (dreyeck/git:git-commit-hash-of commit))))
      (when (typep commit 'dreyeck/git:git-revision-reference)
        (html-inspector-views:html
          (:p "Repository authority: "
           (cl-who:esc (dreyeck/git:git-revision-authority-of commit)))
          (:p
           (html-inspector-views:object-ref commit :display
                                            "Evidence revision and retained source locations"
                                            :select "Evidence revision"))
          (:p
           "Retained excerpts remain evidence at their recorded ranges; they are not a newly read complete Git blob.")
          (when (dreyeck/git:git-revision-web-url-of commit)
            (html-inspector-views:html
              (:p
               (:a :href (dreyeck/git:git-revision-web-url-of commit) :target
                "_blank" "External repository commit")))))))))

(defun call-with-available-git-object (object function)
  (handler-case
   (let ((status (dreyeck/git:git-local-object-status object)))
     (if (eq :available status)
         (funcall function)
         (render-git-unavailable object status)))
   (dreyeck/git:git-command-failed (condition)
    (html-inspector-views:html
      (:p "Git inspection failed; this is not an absent-checkout result.")
      (render-git-error condition)))))

(defmacro with-available-git-object ((object) &body body)
  (eclector.reader:quasiquote
   (call-with-available-git-object (eclector.reader:unquote object)
                                   (lambda ()
                                     (eclector.reader:unquote-splicing body)))))

(defun render-git-local-status (object)
  (handler-case
   (html-inspector-views:html
     (cl-who:esc
      (format nil "~A" (dreyeck/git:git-local-object-status object))))
   (dreyeck/git:git-command-failed (condition) (render-git-error condition))))

(html-inspector-views:defview checkout-resource-view
                              (repository dreyeck/git:git-repository-checkout)
                              (html-inspector-views:html-view :title
                                                              "Local checkout"
                                                              :priority 0
                                                              (html-inspector-views:html
                                                               (:p
                                                                "Runtime resource path: "
                                                                (:code
                                                                 (cl-who:esc
                                                                  (namestring
                                                                   (dreyeck/git:git-repository-root-of
                                                                    repository)))))
                                                               (:p
                                                                (cl-who:esc
                                                                 (if (eq
                                                                      :available
                                                                      (dreyeck/git:git-local-object-status
                                                                       repository))
                                                                  "A checkout resource is present. Commit and blob availability are checked independently by their inspection views."
                                                                  "This runtime has no usable checkout at this path. Repository Topicmap and live Git objects are unavailable; retained revision evidence is independent of this resource."))))))

(html-inspector-views:defview 👀commit (commit dreyeck/git:git-commit)
                              (html-inspector-views:html-view :title "Commit"
                                                              :priority 1
                                                              (with-available-git-object (commit)
                                                               (handler-case
                                                                (render-git-pre
                                                                 (with-output-to-string
                                                                  (stream)
                                                                  (format
                                                                   stream
                                                                   "Repository: ~A~%"
                                                                   (dreyeck/git:git-commit-repository-of
                                                                    commit))
                                                                  (format
                                                                   stream
                                                                   "Commit-ish: ~A~%"
                                                                   (dreyeck/git:git-commit-ish-of
                                                                    commit))
                                                                  (format
                                                                   stream
                                                                   "Hash: ~A~%~%"
                                                                   (dreyeck/git:git-commit-hash-of
                                                                    commit))
                                                                  (write-string
                                                                   (dreyeck/git:git-commit-one-line
                                                                    commit)
                                                                   stream)))
                                                                (condition
                                                                 (condition)
                                                                 (render-git-error
                                                                  condition))))))

(html-inspector-views:defview 👀metadata (commit dreyeck/git:git-commit)
                              (html-inspector-views:html-view :title "Metadata"
                                                              :priority 2
                                                              (with-available-git-object (commit)
                                                               (handler-case
                                                                (render-git-pre
                                                                 (dreyeck/git:git-commit-metadata
                                                                  commit))
                                                                (condition
                                                                 (condition)
                                                                 (render-git-error
                                                                  condition))))))

(html-inspector-views:defview 👀stat (commit dreyeck/git:git-commit)
                              (html-inspector-views:html-view :title "Stat"
                                                              :priority 3
                                                              (with-available-git-object (commit)
                                                               (handler-case
                                                                (render-git-pre
                                                                 (dreyeck/git:git-commit-stat
                                                                  commit))
                                                                (condition
                                                                 (condition)
                                                                 (render-git-error
                                                                  condition))))))

(html-inspector-views:defview 👀changed-files (commit dreyeck/git:git-commit)
                              (html-inspector-views:html-view :title
                                                              "Changed files"
                                                              :priority 4
                                                              (with-available-git-object (commit)
                                                               (handler-case
                                                                (html-inspector-views:html
                                                                 (:table
                                                                  :class
                                                                  "inspector-table"
                                                                  (:tr
                                                                   (:th
                                                                    (cl-who:esc
                                                                     "Status"))
                                                                   (:th
                                                                    (cl-who:esc
                                                                     "File"))
                                                                   (:th
                                                                    (cl-who:esc
                                                                     "Previous path")))
                                                                  (dolist
                                                                   (change
                                                                    (dreyeck/git:git-commit-file-changes
                                                                     commit))
                                                                   (html-inspector-views:html
                                                                    (:tr
                                                                     (:td
                                                                      (:tt
                                                                       (cl-who:esc
                                                                        (dreyeck/git:git-commit-file-change-status-of
                                                                         change))))
                                                                     (:td
                                                                      (html-inspector-views:object-ref
                                                                       (dreyeck/git:git-commit-file-change-file
                                                                        change)
                                                                       :display
                                                                       (dreyeck/git:git-commit-file-change-path-of
                                                                        change)))
                                                                     (:td
                                                                      (let
                                                                       ((old-path
                                                                         (dreyeck/git:git-commit-file-change-old-path-of
                                                                          change)))
                                                                       (if old-path
                                                                        (html-inspector-views:html
                                                                         (:code
                                                                          (cl-who:esc
                                                                           old-path)))
                                                                        (cl-who:esc
                                                                         "")))))))))
                                                                (condition
                                                                 (condition)
                                                                 (render-git-error
                                                                  condition))))))

(html-inspector-views:defview 👀patch (commit dreyeck/git:git-commit)
                              (html-inspector-views:html-view :title "Patch"
                                                              :priority 5
                                                              (with-available-git-object (commit)
                                                               (handler-case
                                                                (render-git-pre
                                                                 (dreyeck/git:git-commit-patch
                                                                  commit))
                                                                (condition
                                                                 (condition)
                                                                 (render-git-error
                                                                  condition))))))

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
  (html-inspector-views:html-view :title "Blob contents" :priority 2
                                  (with-available-git-object (file)
                                    (let ((contents
                                           (dreyeck/git:git-file-contents
                                            file)))
                                      (cond
                                       ((git-file-lisp-source-p file)
                                        (html-inspector-views:lisp-snippet
                                         contents))
                                       ((git-file-html-source-p file)
                                        (html-inspector-views:html-snippet
                                         contents))
                                       (t (render-git-pre contents)))))))

(html-inspector-views:defview 👀contents
    (file dreyeck/git:git-file-at-commit)
  (handler-case
      (html-inspector-views:rename
       (git-file-content-code-view file)
       :title "Contents"
       :priority 2)
    (condition (condition)
      (render-git-error condition))))
