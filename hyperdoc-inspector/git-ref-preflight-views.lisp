;;;; Inspector views for Git ref preflight interpretations.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc/inspector)

(defun git-preflight-value-label (probe)
  (cond
    ((null probe)
     "n/a")
    ((hyperdoc::git-probe-result-ok-p probe)
     (let ((value (or (hyperdoc::git-probe-result-value-of probe) "")))
       (if (string= value "")
           "ok, no output"
           value)))
    (t
     (format nil "failed, exit ~D"
             (hyperdoc::git-probe-result-exit-code-of probe)))))

(defun git-preflight-ok-label (probe)
  (if (and probe (hyperdoc::git-probe-result-ok-p probe))
      "ok"
      "failed"))

(defun git-preflight-command-label (probe)
  (format nil "git ~{~A~^ ~}"
          (hyperdoc::git-probe-result-args-of probe)))

(defun render-git-preflight-code (string)
  (html-inspector-views:html
    (:pre :style "white-space: pre-wrap;"
          (html-inspector-views:esc string))))

(defun render-git-preflight-kv (label value)
  (html-inspector-views:html
    (:tr
     (:td (:b (html-inspector-views:esc label)))
     (:td (html-inspector-views:esc value)))))

(defun render-git-preflight-probe-row (label probe meaning)
  (html-inspector-views:html
    (:tr
     (:td (:b (html-inspector-views:esc label)))
     (:td (:tt (html-inspector-views:esc
                (git-preflight-value-label probe))))
     (:td (html-inspector-views:esc meaning))
     (:td (html-inspector-views:object-ref probe)))))

(defun render-git-preflight-problem-table (preflight)
  (let ((problems (hyperdoc::git-ref-preflight-problems preflight)))
    (if problems
        (html-inspector-views:html
          (:table :class "inspector-table"
                  (:tr
                   (:th (html-inspector-views:esc "Severity"))
                   (:th (html-inspector-views:esc "Problem"))
                   (:th (html-inspector-views:esc "Evidence")))
                  (dolist (problem problems)
                    (html-inspector-views:html
                      (:tr
                       (:td (:tt
                             (html-inspector-views:esc
                              (format nil "~(~A~)"
                                      (hyperdoc::git-preflight-problem-severity-of
                                       problem)))))
                       (:td
                        (html-inspector-views:esc
                         (hyperdoc::git-preflight-problem-message-of problem)))
                       (:td
                        (let ((probe
                                (hyperdoc::git-preflight-problem-probe-of
                                 problem)))
                          (if probe
                              (html-inspector-views:object-ref probe)
                              (html-inspector-views:esc "")))))))))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               "No blocking problems were detected."))))))

(defun git-preflight-comparison-command (preflight)
  (format nil "git diff --name-status ~A...~A"
          (hyperdoc::git-ref-preflight-left-ref-of preflight)
          (hyperdoc::git-ref-preflight-right-ref-of preflight)))

(defun git-preflight-ready-heading (preflight)
  (if (hyperdoc::git-ref-preflight-ready-p preflight)
      "Ready: the live refs resolve and a merge base exists."
      "Blocked: the comparison is not ready yet."))

(defun git-preflight-readiness-lines (preflight)
  (if (hyperdoc::git-ref-preflight-ready-p preflight)
      (list
       "This object has answered the preflight question: the comparison can be built."
       (format nil "Use ~A for the path-level comparison."
               (git-preflight-comparison-command preflight))
       (format nil "The merge base is ~A. That is the fork point for the three-dot comparison."
               (git-preflight-value-label
                (hyperdoc::git-ref-preflight-merge-base-short-of preflight)))
       "No merge, checkout, staging, rebase, or cherry-pick has been performed.")
      (cons
       "Do not build the comparison object yet."
       (mapcar #'hyperdoc::git-preflight-problem-message-of
               (hyperdoc::git-ref-preflight-problems preflight)))))

(defmethod html-inspector-views:text-representation
    ((probe hyperdoc::git-probe-result))
  (format nil "~A — ~A"
          (git-preflight-ok-label probe)
          (git-preflight-command-label probe)))

(defmethod html-inspector-views:text-representation
    ((problem hyperdoc::git-preflight-problem))
  (format nil "~A: ~A"
          (hyperdoc::git-preflight-problem-severity-of problem)
          (hyperdoc::git-preflight-problem-message-of problem)))

(defmethod html-inspector-views:text-representation
    ((preflight hyperdoc::git-ref-preflight))
  (format nil "Git preflight ~A ... ~A"
          (hyperdoc::git-ref-preflight-left-ref-of preflight)
          (hyperdoc::git-ref-preflight-right-ref-of preflight)))

(html-inspector-views:defview 👀interpretation
    (preflight hyperdoc::git-ref-preflight)
  (html-inspector-views:html-view :title "Readiness" :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc
            (git-preflight-ready-heading preflight)))
      (:p
       (html-inspector-views:esc
        "This view tells us whether it is safe to proceed to an inspectable branch comparison object."))

      (:table :class "inspector-table"
              (render-git-preflight-kv
               "Can compare?"
               (if (hyperdoc::git-ref-preflight-ready-p preflight)
                   "yes"
                   "no"))
              (render-git-preflight-kv
               "Comparison command"
               (git-preflight-comparison-command preflight))
              (render-git-preflight-kv
               "Left side"
               (hyperdoc::git-ref-preflight-left-ref-of preflight))
              (render-git-preflight-kv
               "Right side"
               (hyperdoc::git-ref-preflight-right-ref-of preflight))
              (render-git-preflight-kv
               "Repository"
               (namestring
                (hyperdoc::git-ref-preflight-repository-root-of preflight))))

      (:h4 (html-inspector-views:esc "Interpretation"))
      (:ul
       (dolist (line (git-preflight-readiness-lines preflight))
         (html-inspector-views:html
           (:li (html-inspector-views:esc line)))))

      (:h4 (html-inspector-views:esc "Problems"))
      (render-git-preflight-problem-table preflight))))

(html-inspector-views:defview 👀facts
    (preflight hyperdoc::git-ref-preflight)
  (html-inspector-views:html-view :title "Comparison basis" :priority 2
    (html-inspector-views:html
      (:p
       (html-inspector-views:esc
        "These are the facts that define the comparison. Each Evidence cell opens the underlying Git probe."))

      (:table :class "inspector-table"
              (:tr
               (:th (html-inspector-views:esc "Fact"))
               (:th (html-inspector-views:esc "Value"))
               (:th (html-inspector-views:esc "Meaning"))
               (:th (html-inspector-views:esc "Evidence")))

              (render-git-preflight-probe-row
               "Current branch"
               (hyperdoc::git-ref-preflight-current-branch-of preflight)
               "Should normally be hauptsache for this workflow.")

              (render-git-preflight-probe-row
               "HEAD"
               (hyperdoc::git-ref-preflight-head-of preflight)
               "The commit currently checked out in this worktree.")

              (render-git-preflight-probe-row
               "upstream/main"
               (hyperdoc::git-ref-preflight-left-of preflight)
               "Konrad's upstream branch tip as known locally.")

              (render-git-preflight-probe-row
               "hauptsache"
               (hyperdoc::git-ref-preflight-hauptsache-of preflight)
               "Your branch name as a local ref, useful even when right side is HEAD.")

              (render-git-preflight-probe-row
               "Merge base"
               (hyperdoc::git-ref-preflight-merge-base-short-of preflight)
               "The fork point used by upstream/main...HEAD.")))))

(html-inspector-views:defview 👀probes
    (preflight hyperdoc::git-ref-preflight)
  (html-inspector-views:html-view :title "Command evidence" :priority 3
    (html-inspector-views:html
      (:p
       (html-inspector-views:esc
        "This is the raw Git evidence. It is for debugging the preflight itself, not for deciding the merge."))

      (:table :class "inspector-table"
              (:tr
               (:th (html-inspector-views:esc "Result"))
               (:th (html-inspector-views:esc "Value"))
               (:th (html-inspector-views:esc "Command object")))
              (dolist (probe (hyperdoc::git-ref-preflight-probes preflight))
                (html-inspector-views:html
                  (:tr
                   (:td (:tt
                         (html-inspector-views:esc
                          (git-preflight-ok-label probe))))
                   (:td (:tt
                         (html-inspector-views:esc
                          (git-preflight-value-label probe))))
                   (:td
                    (html-inspector-views:object-ref probe)))))))))

(html-inspector-views:defview 👀next-actions
    (preflight hyperdoc::git-ref-preflight)
  (html-inspector-views:html-view :title "Next step" :priority 4
    (html-inspector-views:html
      (:h3
       (html-inspector-views:esc
        (if (hyperdoc::git-ref-preflight-ready-p preflight)
            "Build the branch comparison object next."
            "Repair readiness first.")))

      (if (hyperdoc::git-ref-preflight-ready-p preflight)
          (html-inspector-views:html
            (:p
             (html-inspector-views:esc
              "The next object should group paths from the live three-dot comparison into upstream-only, hauptsache-only, and overlapping path deltas."))

            (:table :class "inspector-table"
                    (render-git-preflight-kv
                     "Next object"
                     "git-tree-comparison")
                    (render-git-preflight-kv
                     "Command basis"
                     (git-preflight-comparison-command preflight))
                    (render-git-preflight-kv
                     "First useful views"
                     "Overview, Upstream-only, Hauptsache-only, Overlapping paths"))

            (:p
             (html-inspector-views:esc
              "After that, individual path rows should open file/path-delta objects, not just strings.")))
          (html-inspector-views:html
            (:p
             (html-inspector-views:esc
              "The preflight has errors. Open the Problems section in Readiness or the failed probe object in Command evidence.")))))))

(html-inspector-views:defview 👀overview
    (probe hyperdoc::git-probe-result)
  (html-inspector-views:html-view :title "Overview" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (render-git-preflight-kv
               "Result"
               (git-preflight-ok-label probe))
              (render-git-preflight-kv
               "Exit code"
               (format nil "~D"
                       (hyperdoc::git-probe-result-exit-code-of probe)))
              (render-git-preflight-kv
               "Command"
               (git-preflight-command-label probe))
              (render-git-preflight-kv
               "Value"
               (git-preflight-value-label probe))))))

(html-inspector-views:defview 👀stdout
    (probe hyperdoc::git-probe-result)
  (html-inspector-views:html-view :title "stdout" :priority 2
    (render-git-preflight-code
     (hyperdoc::git-probe-result-stdout-of probe))))

(html-inspector-views:defview 👀stderr
    (probe hyperdoc::git-probe-result)
  (html-inspector-views:html-view :title "stderr" :priority 3
    (render-git-preflight-code
     (hyperdoc::git-probe-result-stderr-of probe))))
