;;;; Repair/overlay views for Git history path overlap.
;;;; Created from SLY MREPL; load after git-history-map-views.lisp.

(in-package :hyperdoc/inspector)

(defun render-history-overlap-error (condition)
  (html-inspector-views:html
    (:pre :style "white-space: pre-wrap;"
          (html-inspector-views:esc (format nil "~A" condition)))))

(defun render-history-overlap-row (label value)
  (html-inspector-views:html
    (:tr
     (:td (:b (html-inspector-views:esc label)))
     (:td (html-inspector-views:esc value)))))

(defun render-history-overlap-commit-table (commits)
  (html-inspector-views:html
    (:table :class "inspector-table"
            (:tr
             (:th (html-inspector-views:esc "Date"))
             (:th (html-inspector-views:esc "Commit"))
             (:th (html-inspector-views:esc "Subject")))
            (dolist (commit commits)
              (html-inspector-views:html
                (:tr
                 (:td
                  (html-inspector-views:esc
                   (hyperdoc::git-history-commit-date-of commit)))
                 (:td
                  (html-inspector-views:object-ref commit))
                 (:td
                  (html-inspector-views:esc
                   (hyperdoc::git-history-commit-subject-of commit)))))))))

(defmethod html-inspector-views:text-representation
    ((overlap hyperdoc::git-history-path-overlap))
  (hyperdoc::git-history-path-overlap-path-of overlap))

(html-inspector-views:defview 👀overlap
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:html-view :title "Overlap" :priority 4
    (handler-case
        (let ((overlaps
                (sort
                 (copy-list
                  (hyperdoc::git-history-map-path-overlaps history-map))
                 #'string<
                 :key #'hyperdoc::git-history-path-overlap-path-of)))
          (html-inspector-views:html
            (:h3 (html-inspector-views:esc "Exact path overlap"))
            (:p
             (html-inspector-views:esc
              "A path overlaps when Konrad changed that exact path on upstream/main and hauptsache also changed that exact path since the same merge base."))

            (:table :class "inspector-table"
                    (:tr
                     (:th (html-inspector-views:esc "Path"))
                     (:th (html-inspector-views:esc "Konrad commits"))
                     (:th (html-inspector-views:esc "Our commits")))
                    (dolist (overlap overlaps)
                      (html-inspector-views:html
                        (:tr
                         (:td
                          (html-inspector-views:object-ref overlap))
                         (:td
                          (html-inspector-views:esc
                           (format nil "~D"
                                   (length
                                    (hyperdoc::git-history-path-overlap-upstream-commits-of
                                     overlap)))))
                         (:td
                          (html-inspector-views:esc
                           (format nil "~D"
                                   (length
                                    (hyperdoc::git-history-path-overlap-hauptsache-commits-of
                                     overlap)))))))))))
      (condition (condition)
        (render-history-overlap-error condition)))))

(html-inspector-views:defview 👀overview
    (overlap hyperdoc::git-history-path-overlap)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (handler-case
        (html-inspector-views:html
          (:h3 (html-inspector-views:esc
                (hyperdoc::git-history-path-overlap-path-of overlap)))
          (:table :class "inspector-table"
                  (render-history-overlap-row
                   "Path"
                   (hyperdoc::git-history-path-overlap-path-of overlap))
                  (render-history-overlap-row
                   "Konrad commits touching this path"
                   (format nil "~D"
                           (length
                            (hyperdoc::git-history-path-overlap-upstream-commits-of
                             overlap))))
                  (render-history-overlap-row
                   "Our commits touching this path"
                   (format nil "~D"
                           (length
                            (hyperdoc::git-history-path-overlap-hauptsache-commits-of
                             overlap)))))
          (:p
           (html-inspector-views:esc
            "This is the one file that needs concrete file-level review before merging upstream/main.")))
      (condition (condition)
        (render-history-overlap-error condition)))))

(html-inspector-views:defview 👀konrad-commits
    (overlap hyperdoc::git-history-path-overlap)
  (html-inspector-views:html-view :title "Konrad commits" :priority 2
    (handler-case
        (render-history-overlap-commit-table
         (hyperdoc::git-history-path-overlap-upstream-commits-of overlap))
      (condition (condition)
        (render-history-overlap-error condition)))))

(html-inspector-views:defview 👀our-commits
    (overlap hyperdoc::git-history-path-overlap)
  (html-inspector-views:html-view :title "Our commits" :priority 3
    (handler-case
        (render-history-overlap-commit-table
         (hyperdoc::git-history-path-overlap-hauptsache-commits-of overlap))
      (condition (condition)
        (render-history-overlap-error condition)))))
