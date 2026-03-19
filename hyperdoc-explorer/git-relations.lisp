;;;; Explorer views for git history surfaces and merge-intent relations
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun branch-role-label (branch-ref)
  (ecase (branch-role-of branch-ref)
    (:local "local")
    (:upstream "upstream")))

(defun branch-resolution-label (status)
  (ecase status
    (:matches "matches anchor")
    (:drifted "drifted from anchor")
    (:missing "ref missing")))

(defun branch-aliases-display (branch-ref)
  (if-let (aliases (branch-aliases-of branch-ref))
    (format nil "~{~A~^, ~}" aliases)
    "none"))

(defun render-commit-summary (target)
  (let ((metadata (git-commit-metadata target)))
    (views:html
      (:div (:b (views:object-ref target
                                  :display (short-git-commit-hash
                                            (commit-hash-of target)))))
      (:div :style "font-size: 0.92em; opacity: 0.85;"
            (views:esc (or (cdr (assoc "Subject" metadata :test #'string=))
                           "")))
      (:div :style "font-size: 0.84em; opacity: 0.75;"
            (:tt
             (views:esc (or (cdr (assoc "Date" metadata :test #'string=))
                            "")))))))

(defun render-branch-anchor-card (branch-ref)
  (let ((status (git-branch-resolution-status branch-ref)))
    (views:html
      (:div (:b (views:object-ref branch-ref)))
      (:div :style "font-size: 0.92em; opacity: 0.85;"
            (:tt (views:esc (branch-role-label branch-ref))))
      (:div :style "margin-top: 0.3em;"
            (render-commit-summary (git-branch-target branch-ref)))
      (:div :style "font-size: 0.84em; opacity: 0.75; margin-top: 0.25em;"
            (views:esc (format nil "current ref: ~A"
                               (branch-resolution-label status)))))))

(defun render-commit-lane-cell (target)
  (if target
      (render-commit-summary target)
      (views:html (:span :style "opacity: 0.55;" "-"))))

(defun render-merge-intent-summary-table (relation)
  (views:html
    (:table :class "inspector-table"
            (:tr (:td (views:esc "Relation type"))
                 (:td (:tt (views:esc (relation-type-of relation)))))
            (:tr (:td (views:esc "Status"))
                 (:td (:tt (views:esc (status-of relation)))))
            (:tr (:td (views:esc "Source branch"))
                 (:td (views:object-ref (source-branch-of relation))))
            (:tr (:td (views:esc "Source anchor"))
                 (:td (views:object-ref (source-commit-of relation)
                                       :display
                                       (short-git-commit-hash
                                        (commit-hash-of
                                         (source-commit-of relation))))))
            (:tr (:td (views:esc "Target branch"))
                 (:td (views:object-ref (target-branch-of relation))))
            (:tr (:td (views:esc "Target anchor"))
                 (:td (views:object-ref (target-commit-of relation)
                                       :display
                                       (short-git-commit-hash
                                        (commit-hash-of
                                         (target-commit-of relation)))))))))

(defun render-relations-list (relations)
  (if relations
      (views:html
        (:ul
         (loop for relation in relations
               do (views:html
                    (:li (views:object-ref relation))))))
      (views:html
        (:span :style "opacity: 0.55;" "No relations."))))

(defmethod views:text-representation ((branch-ref git-branch-ref))
  (format nil "~A @ ~A"
          (branch-name-of branch-ref)
          (short-git-commit-hash (commit-hash-of branch-ref))))

(defmethod views:text-representation ((relation git-merge-intent))
  (title-of relation))

(defmethod views:text-representation ((surface git-history-surface))
  (title-of surface))

(views:defview 👀overview (branch-ref git-branch-ref)
  (views:html-view :title "Overview" :priority 1
    (let ((status (git-branch-resolution-status branch-ref))
          (current-target (git-branch-current-target branch-ref)))
      (views:html
        (:h3 (views:esc (branch-name-of branch-ref)))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Role"))
                     (:td (:tt (views:esc (branch-role-label branch-ref)))))
                (:tr (:td (views:esc "Anchored commit"))
                     (:td (views:object-ref (git-branch-target branch-ref))))
                (:tr (:td (views:esc "Current ref"))
                     (:td (:tt (views:esc (branch-resolution-label status)))))
                (:tr (:td (views:esc "Current target"))
                     (:td (if current-target
                              (views:object-ref current-target)
                              (views:html (:tt (views:esc "unresolved"))))))
                (:tr (:td (views:esc "Aliases"))
                     (:td (:tt (views:esc (branch-aliases-display branch-ref)))))
                (:tr (:td (views:esc "Repository root"))
                     (:td (:tt (views:esc (namestring (repo-root-of branch-ref)))))))))))

(views:defview 👀merge-intent (relation git-merge-intent)
  (views:html-view :title "Merge intent" :priority 1
    (views:html
      (:h3 (views:esc (title-of relation)))
      (:p (views:esc (summary-of relation)))
      (render-merge-intent-summary-table relation)
      (:h4 "Prompt")
      (:pre :style "white-space: pre-wrap"
            (views:esc (prompt-of relation)))
      (:h4 "Conflict policy")
      (:pre :style "white-space: pre-wrap"
            (views:esc (conflict-policy-of relation)))
      (:h4 "Success criteria")
      (:ul
       (loop for criterion in (success-criteria-of relation)
             do (views:html
                  (:li (views:esc criterion))))))))

(views:defview 👀git-history (surface git-history-surface)
  (let* ((local-branch (local-branch-of surface))
         (upstream-branch (upstream-branch-of surface))
         (relations (relations-of surface))
         (local-commits (git-history-local-commits surface))
         (upstream-commits (git-history-upstream-commits surface))
         (row-count (max (length local-commits)
                         (length upstream-commits))))
    (views:html-view :title "Git history" :priority 1
      (views:html
        (:h3 (views:esc (title-of surface)))
        (:p (views:esc (summary-of surface)))
        (:p "This first slice is lane-based and declarative: branch anchors and merge relations are durable objects, while the row list below stays intentionally narrower than a full DAG renderer.")
        (:h4 "Lane anchors")
        (:table :class "inspector-table"
                (:tr (:th (views:esc (branch-name-of local-branch)))
                     (:th (views:esc "Relation"))
                     (:th (views:esc (branch-name-of upstream-branch))))
                (:tr (:td (render-branch-anchor-card local-branch))
                     (:td (render-relations-list relations))
                     (:td (render-branch-anchor-card upstream-branch))))
        (:h4 "Recent branch-only commits")
        (if (plusp row-count)
            (views:html
              (:table :class "inspector-table"
                      (:tr (:th (views:esc (branch-name-of local-branch)))
                           (:th (views:esc (branch-name-of upstream-branch))))
                      (loop for index from 0 below row-count
                            for local-target = (nth index local-commits)
                            for upstream-target = (nth index upstream-commits)
                            do (views:html
                                 (:tr (:td (render-commit-lane-cell local-target))
                                      (:td (render-commit-lane-cell upstream-target)))))))
            (views:html
              (:p "Neither lane currently has branch-only commits beyond the anchored relation points.")))))))

(views:defview 👀merge-worklist (surface git-history-surface)
  (let* ((target-branch (local-branch-of surface))
         (relations (git-history-merge-worklist surface :target-branch target-branch)))
    (views:html-view :title "Merge worklist" :priority 2
      (views:html
        (:h3
         (views:esc
          (format nil "Merge worklist for ~A"
                  (branch-name-of target-branch))))
        (if relations
            (views:html
              (loop for relation in relations
                    do (views:html
                         (:div :style "margin-bottom: 1.5em;"
                               (:h4 (views:object-ref relation))
                               (render-merge-intent-summary-table relation)
                               (:h5 "Conflict policy")
                               (:pre :style "white-space: pre-wrap"
                                     (views:esc (conflict-policy-of relation)))
                               (:h5 "Checks to keep green")
                               (:ul
                                (loop for criterion in (success-criteria-of relation)
                                      do (views:html
                                           (:li (views:esc criterion)))))))))
            (views:html
              (:p "No merge-intent relations target this branch.")))))))
