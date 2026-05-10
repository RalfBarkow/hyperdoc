;;;; Evolution-story views for Git history maps.
;;;; Created from SLY MREPL; load after git-history-map.lisp.

(in-package :hyperdoc/inspector)

(defun git-evolution-run (repository-root &rest args)
  (multiple-value-bind (stdout stderr code)
      (uiop:run-program
       (cons "git" args)
       :directory repository-root
       :output :string
       :error-output :string
       :ignore-error-status t)
    (unless (zerop code)
      (error "git ~{~A~^ ~} failed with code ~D~%~A"
             args code stderr))
    stdout))

(defun git-evolution-native-graph (history-map)
  (git-evolution-run
   (hyperdoc::git-history-map-repository-root-of history-map)
   "log"
   "--graph"
   "--left-right"
   "--cherry-mark"
   "--decorate"
   "--oneline"
   "--boundary"
   (format nil "~A...~A"
           (hyperdoc::git-history-map-left-ref-of history-map)
           (hyperdoc::git-history-map-right-ref-of history-map))))

(defun git-evolution-commit-label (commit)
  (format nil "~A~%~A"
          (hyperdoc::git-history-commit-short-hash commit)
          (hyperdoc::git-history-commit-subject-of commit)))

(defun git-evolution-overlap-label (overlap)
  (format nil "overlap~%~A"
          (hyperdoc::git-history-path-overlap-path-of overlap)))

(defun git-evolution-dot-text (history-map)
  (let* ((upstream-commits
           (reverse
            (copy-list
             (hyperdoc::git-history-map-left-commits-of history-map))))
         (overlaps
           (hyperdoc::git-history-map-path-overlaps history-map))
         (base-short
           (hyperdoc::git-history-short-hash
            (hyperdoc::git-history-map-merge-base-of history-map)))
         (right-count
           (hyperdoc::git-history-map-right-count-of history-map)))
    (with-output-to-string (stream)
      (format stream "digraph git_evolution {~%")
      (format stream "  rankdir=LR;~%")
      (format stream "  node [fontname=~S];~%" "Helvetica")
      (format stream "  edge [fontname=~S];~%" "Helvetica")

      (format stream "  base [label=~S shape=ellipse];~%"
              (format nil "merge base~%~A" base-short))

      (let ((previous "base")
            (upstream-tip nil))
        (loop for commit in upstream-commits
              for index from 0
              do (let ((node (format nil "u~D" index)))
                   (format stream "  ~A [label=~S shape=box];~%"
                           node
                           (git-evolution-commit-label commit))
                   (format stream "  ~A -> ~A [label=~S];~%"
                           previous node "Konrad")
                   (setf previous node)
                   (setf upstream-tip node)))
        (unless upstream-tip
          (setf upstream-tip "base"))

        (format stream "  ours [label=~S shape=box style=rounded];~%"
                (format nil "hauptsache / HEAD~%~D local commits" right-count))
        (format stream "  base -> ours [label=~S];~%" "hauptsache")

        (loop for overlap in overlaps
              for index from 0
              for node = (format nil "o~D" index)
              do (progn
                   (format stream "  ~A [label=~S shape=note];~%"
                           node
                           (git-evolution-overlap-label overlap))
                   (format stream "  ~A -> ~A [style=dashed label=~S];~%"
                           upstream-tip node "touches")
                   (format stream "  ours -> ~A [style=dashed label=~S];~%"
                           node "also touched"))))

      (format stream "}~%"))))

(defun render-evolution-row (label value)
  (html-inspector-views:html
    (:tr
     (:td (:b (html-inspector-views:esc label)))
     (:td (html-inspector-views:esc value)))))

(defun render-evolution-commit-row (label commit)
  (html-inspector-views:html
    (:tr
     (:td (:b (html-inspector-views:esc label)))
     (:td
      (if commit
          (html-inspector-views:object-ref commit)
          (html-inspector-views:esc "none"))))))

(defun render-evolution-overlap-table (overlaps)
  (html-inspector-views:html
    (:table :class "inspector-table"
            (:tr
             (:th (html-inspector-views:esc "Path"))
             (:th (html-inspector-views:esc "Konrad commits"))
             (:th (html-inspector-views:esc "Our commits")))
            (dolist (overlap overlaps)
              (html-inspector-views:html
                (:tr
                 (:td (html-inspector-views:object-ref overlap))
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

(html-inspector-views:defview 👀evolution-story
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:html-view :title "Evolution story" :priority 0
    (let* ((konrad-commits
             (hyperdoc::git-history-map-left-commits-of history-map))
           (latest-konrad
             (first konrad-commits))
           (overlaps
             (hyperdoc::git-history-map-path-overlaps history-map)))
      (html-inspector-views:html
        (:h2 (html-inspector-views:esc "Konrad upstream/main → hauptsache"))

        (:table :class "inspector-table"
                (render-evolution-row
                 "Merge base"
                 (hyperdoc::git-history-short-hash
                  (hyperdoc::git-history-map-merge-base-of history-map)))
                (render-evolution-row
                 "Konrad branch"
                 (format nil "~D upstream-only commits"
                         (hyperdoc::git-history-map-left-count-of history-map)))
                (render-evolution-row
                 "Our branch"
                 (format nil "~D hauptsache-only commits"
                         (hyperdoc::git-history-map-right-count-of history-map)))
                (render-evolution-commit-row
                 "Konrad current tip"
                 latest-konrad)
                (render-evolution-row
                 "Exact path overlaps"
                 (format nil "~D" (length overlaps))))

        (:h3 (html-inspector-views:esc "Narrative"))
        (:ol
         (:li
          (html-inspector-views:esc
           "Konrad's upstream/main has advanced by a small number of focused FedWiki/story-item commits."))

         (:li
          (html-inspector-views:esc
           "hauptsache has a much larger local history: deployment, documentation, inspector/debugging, DMX/Zotero/SCXML/topic tooling, and local HyperDoc surfaces."))

         (:li
          (html-inspector-views:esc
           "The two histories currently collide on one exact file path: hyperbook-fedwiki/story-items.lisp."))

         (:li
          (html-inspector-views:esc
           "The graphviz story-item payload is already represented as a semantic assimilation case. The current open question is the latest upstream HTML story-item behavior.")))

        (:h3 (html-inspector-views:esc "Current decision focus"))
        (if overlaps
            (render-evolution-overlap-table overlaps)
            (html-inspector-views:html
              (:p (html-inspector-views:esc "No exact path overlaps."))))))))

(html-inspector-views:defview 👀topology
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:graphviz-view
   (html-inspector-views:thunk
     (git-evolution-dot-text history-map))
   :title "Topology"
   :priority 1
   :engine "dot"
   :fallback-title "Git evolution DOT"))

(html-inspector-views:defview 👀git-log-graph
    (history-map hyperdoc::git-history-map)
  (html-inspector-views:html-view :title "Git log graph" :priority 2
    (html-inspector-views:html
      (:p
       (html-inspector-views:esc
        "Native git log --graph view of upstream/main...HEAD."))

      (:pre :style "white-space: pre-wrap;"
            (html-inspector-views:esc
             (git-evolution-native-graph history-map))))))
