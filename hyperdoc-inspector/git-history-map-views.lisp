;;;; Inspector views for Git history maps.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc/inspector)

(defun render-history-row (label value)
  (html-inspector-views:html
    (:tr
     (:td (:b (html-inspector-views:esc label)))
     (:td (html-inspector-views:esc value)))))

(defun render-history-commit-table (commits)
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
    ((history-map hyperdoc::git-history-map))
  (format nil "History map ~A ... ~A"
          (hyperdoc::git-history-map-left-ref-of history-map)
          (hyperdoc::git-history-map-right-ref-of history-map)))

(defmethod html-inspector-views:text-representation
    ((commit hyperdoc::git-history-commit))
  (format nil "~A ~A"
          (hyperdoc::git-history-commit-short-hash commit)
          (hyperdoc::git-history-commit-subject-of commit)))

(html-inspector-views:defview 👀situation
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:html-view :title "Situation" :priority 1
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc "Konrad upstream/main vs hauptsache history"))

      (:table :class "inspector-table"
              (render-history-row
               "Konrad commits"
               (format nil "~D total, ~D shown"
                       (hyperdoc::git-history-map-left-count-of history-map)
                       (length
                        (hyperdoc::git-history-map-left-commits-of history-map))))
              (render-history-row
               "Our commits"
               (format nil "~D total, ~D shown"
                       (hyperdoc::git-history-map-right-count-of history-map)
                       (length
                        (hyperdoc::git-history-map-right-commits-of history-map))))
              (render-history-row
               "Merge base"
               (hyperdoc::git-history-short-hash
                (hyperdoc::git-history-map-merge-base-of history-map)))
              (render-history-row
               "Truncated"
               (if (hyperdoc::git-history-map-truncated-p history-map)
                   "yes"
                   "no")))

      (:p
       (html-inspector-views:esc
        "This is a commit-history orientation map. It does not compute path overlap yet.")))))

(html-inspector-views:defview 👀konrad
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:html-view :title "Konrad's work" :priority 2
    (html-inspector-views:html
      (:p
       (html-inspector-views:esc
        "Recent commits reachable from upstream/main but not from HEAD, ignoring patch-equivalent cherry-picks."))

      (render-history-commit-table
       (hyperdoc::git-history-map-left-commits-of history-map)))))

(html-inspector-views:defview 👀ours
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:html-view :title "Our work" :priority 3
    (html-inspector-views:html
      (:p
       (html-inspector-views:esc
        "Recent commits reachable from HEAD but not from upstream/main, ignoring patch-equivalent cherry-picks."))

      (render-history-commit-table
       (hyperdoc::git-history-map-right-commits-of history-map)))))

(html-inspector-views:defview 👀next
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:html-view :title "Next" :priority 4
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc "Next object"))

      (:table :class "inspector-table"
              (render-history-row
               "Build"
               "git-tree-comparison")
              (render-history-row
               "Purpose"
               "Compute path overlap after we understand both commit histories.")
              (render-history-row
               "Command"
               (format nil "git diff --name-status ~A...~A"
                       (hyperdoc::git-history-map-left-ref-of history-map)
                       (hyperdoc::git-history-map-right-ref-of history-map)))))))

(html-inspector-views:defview 👀commit
    (commit hyperdoc::git-history-commit)
  (html-inspector-views:html-view :title "Commit" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-history-row
               "Hash"
               (hyperdoc::git-history-commit-hash-of commit))
              (render-history-row
               "Date"
               (hyperdoc::git-history-commit-date-of commit))
              (render-history-row
               "Side"
               (format nil "~(~A~)"
                       (hyperdoc::git-history-commit-side-of commit)))
              (render-history-row
               "Subject"
               (hyperdoc::git-history-commit-subject-of commit))))))

(html-inspector-views:defview 👀paths
    (commit hyperdoc::git-history-commit)
  (html-inspector-views:html-view :title "Touched paths" :priority 2
    (html-inspector-views:html
      (:p
       (html-inspector-views:esc
        "Paths are loaded lazily for this one commit only."))

      (:table :class "inspector-table"
              (dolist (path
                        (sort
                         (copy-list
                          (hyperdoc::git-history-commit-paths commit))
                         #'string<))
                (html-inspector-views:html
                  (:tr
                   (:td
                    (:code
                     (html-inspector-views:esc path))))))))))
