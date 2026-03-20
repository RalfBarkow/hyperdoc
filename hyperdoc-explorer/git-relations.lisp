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
  (handler-case
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
                                ""))))))
    (git-runtime-unavailable (condition)
      (views:html
        (:div (views:object-ref condition))))))

(defun render-branch-anchor-card (branch-ref)
  (handler-case
      (let ((status (git-branch-resolution-status branch-ref)))
        (views:html
          (:div (:b (views:object-ref branch-ref)))
          (:div :style "font-size: 0.92em; opacity: 0.85;"
                (:tt (views:esc (branch-role-label branch-ref))))
          (:div :style "font-size: 0.84em; opacity: 0.75; margin-top: 0.25em;"
                (views:esc
                 (format nil "repo root mode: ~A"
                         (git-repository-root-origin-label
                          (repo-root-of branch-ref)
                          (repository-root-source-of branch-ref)))))
          (:div :style "margin-top: 0.3em;"
                (render-commit-summary (git-branch-target branch-ref)))
          (:div :style "font-size: 0.84em; opacity: 0.75; margin-top: 0.25em;"
                (views:esc (format nil "current ref: ~A"
                                   (branch-resolution-label status))))))
    (git-runtime-unavailable (condition)
      (views:html
        (:div (views:object-ref condition))))))

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

(defun maybe-path-annotation-ref (annotation &key display)
  (if annotation
      (views:object-ref annotation :display (or display (short-label-of annotation)))
      (views:html (:span :style "opacity: 0.55;" "-"))))

(defun include-git-path-context-menu-assets ()
  (views:add-asset-path "/hyperdoc/"
                        (asdf:system-relative-pathname
                         :hyperdoc
                         "assets/hyperdoc/"))
  (views:include-css "/hyperdoc/css/git-path-context-menu.css")
  (views:include-js "/hyperdoc/js/git-path-context-menu.js")
  (views:include-script
   "window.hyperdocGitPathContextMenu && window.hyperdocGitPathContextMenu.init()"))

(defun render-path-context-action (command label &key target select disabledp)
  (views:html
    (:span :class "git-path-context-action"
           :data-command command
           :data-label label
           :data-disabled (if disabledp "true" "false")
           (cond
             (disabledp
              (views:esc label))
             (target
              (if select
                  (views:object-ref target :display label :select select)
                  (views:object-ref target :display label)))
             (t
              (views:esc label))))))

(defun git-forecast-path-context-action-specs (path-item &key forecast path-set)
  (let* ((relative-path (relative-path-of path-item))
         (annotation (and forecast
                          (git-path-annotation-for-path forecast relative-path)))
         (annotation-target (and forecast
                                 (git-openable-path-annotation-for-path
                                  forecast relative-path :path-set path-set)))
         (related-decisions (and forecast
                                 (git-related-path-decisions-for-path
                                  forecast relative-path))))
    (list
     (list :command "details"
           :label "Details"
           :target path-item)
     (list :command "add-annotation"
           :label "Add annotation"
           :target annotation-target)
     (list :command "edit-annotation"
           :label "Edit annotation"
           :target annotation
           :disabledp (null annotation))
     (list :command "related-decisions"
           :label "Related decisions"
           :target path-item
           :select "Related decisions"
           :disabledp (null related-decisions)))))

(defun render-path-context-actions (path-item &key forecast path-set)
  (views:html
    (:span :class "git-path-context-actions" :hidden "hidden"
           (loop for spec in (git-forecast-path-context-action-specs
                              path-item :forecast forecast :path-set path-set)
                 do (views:html
                      (render-path-context-action
                       (getf spec :command)
                       (getf spec :label)
                       :target (getf spec :target)
                       :select (getf spec :select)
                       :disabledp (getf spec :disabledp)))))))

(defun render-path-context-command-target (action)
  (cond
    ((and (getf action :target)
          (getf action :select))
     (views:object-ref (getf action :target)
                       :display (or (getf action :label)
                                    "target")
                       :select (getf action :select)))
    ((getf action :target)
     (views:object-ref (getf action :target)
                       :display (or (getf action :label)
                                    "target")))
    (t
     (views:html
       (:span :style "opacity: 0.55;" "-")))))

(defun render-path-context-command-row (action)
  (views:html
    (:tr
     (:td (views:esc (getf action :label)))
     (:td (:tt (views:esc
                (if (getf action :disabledp)
                    "no"
                    "yes"))))
     (:td (render-path-context-command-target action)))))

(defun render-path-item (path &key forecast path-set)
  (let* ((path-item (and forecast
                         (git-forecast-path-item-for-path
                          forecast path :path-set path-set)))
         (annotation (and forecast
                          (git-path-annotation-for-path forecast path))))
    (views:html
      (:span :class "git-path-item"
             :data-relative-path path
             :data-path-set (or path-set "")
             (:tt (if path-item
                      (views:object-ref path-item :display path)
                      (views:esc path)))
             (when annotation
               (views:html
                 (:span :class "git-path-annotation-badge"
                        (views:esc (short-label-of annotation)))))
             (when path-item
               (render-path-context-actions path-item
                                            :forecast forecast
                                            :path-set path-set))))))

(defun render-path-list (paths empty-message &key forecast path-set)
  (if paths
      (views:html
        (:ul
         (loop for path in paths
               do (views:html
                    (:li (render-path-item path
                                           :forecast forecast
                                           :path-set path-set))))))
      (views:html
        (:p (views:esc empty-message)))))

(defun render-preparation-notes (notes)
  (if notes
      (views:html
        (:ul
         (loop for note in notes
               do (views:html
                    (:li
                     (views:object-ref note)
                     (:div :style "font-size: 0.92em; opacity: 0.85;"
                           (views:esc (summary-of note))))))))
      (views:html
        (:p "No relation-linked preparation notes."))))

(defun maybe-linked-note-ref (object)
  (if object
      (views:object-ref object)
      (views:html (:span :style "opacity: 0.55;" "-"))))

(defun render-path-decision-table (decisions empty-message)
  (if decisions
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Path"))
                     (:th (views:esc "Classification"))
                     (:th (views:esc "Rationale"))
                     (:th (views:esc "Note")))
                (loop for decision in decisions
                      do (views:html
                           (:tr (:td (render-path-item
                                      (path-of decision)
                                      :forecast (git-merge-forecast-from-relation
                                                 (relation-of decision))
                                      :path-set (path-set-of decision)))
                                (:td (:tt (views:esc (classification-of decision))))
                                (:td (views:esc (rationale-of decision)))
                                (:td (maybe-linked-note-ref (linked-note-of decision))))))))
      (views:html
        (:p (views:esc empty-message)))))

(defun render-dreyeck-bucket-card (bucket)
  (views:html
    (:div :style "margin-bottom: 1.5em;"
          (:h4 (views:object-ref bucket))
          (:p (views:esc (summary-of bucket)))
          (:table :class "inspector-table"
                  (:tr (:td (views:esc "Bucket type"))
                       (:td (:tt (views:esc (bucket-type-of bucket)))))
                  (:tr (:td (views:esc "Why not upstream core"))
                       (:td (views:esc (why-not-upstream-core-of bucket))))
                  (:tr (:td (views:esc "Expected ASDF placement"))
                       (:td (:tt (views:esc (expected-asdf-placement-of bucket)))))
                  (:tr (:td (views:esc "Dependency direction"))
                       (:td (:tt (views:esc (expected-dependency-direction-of bucket)))))
                  (:tr (:td (views:esc "Adaptation mode"))
                       (:td (:tt (views:esc (adaptation-mode-of bucket))))))
          (render-path-list (paths-of bucket)
                            "This bucket does not currently hold any paths."
                            :forecast (forecast-of bucket)))))

(defun render-validation-proof-list (items)
  (if items
      (views:html
        (:ul
         (loop for item in items
               do (views:html
                    (:li (views:esc item))))))
      (views:html
        (:p "No validation proof recorded."))))

(defun render-transition-bucket-card (bucket)
  (views:html
    (:div :style "margin-bottom: 1.5em;"
          (:h4 (views:object-ref bucket))
          (:p (views:esc (summary-of bucket)))
          (:table :class "inspector-table"
                  (:tr (:td (views:esc "Bucket type"))
                       (:td (:tt (views:esc (bucket-type-of bucket)))))
                  (:tr (:td (views:esc "Extraction bucket"))
                       (:td (views:object-ref (extraction-bucket-of bucket))))
                  (:tr (:td (views:esc "Target destination"))
                       (:td (:tt (views:esc (target-destination-of bucket)))))
                  (:tr (:td (views:esc "Dependency direction"))
                       (:td (:tt (views:esc (dependency-direction-of bucket)))))
                  (:tr (:td (views:esc "Transition mode"))
                       (:td (:tt (views:esc (transition-mode-of bucket))))))
          (:h5 "Core continuation")
          (:pre :style "white-space: pre-wrap"
                (views:esc (core-continuation-of bucket)))
          (:h5 "Validation proof")
          (render-validation-proof-list (validation-proof-of bucket))
          (:h5 "Paths")
          (render-path-list (paths-of bucket)
                            "This transition bucket does not currently hold any paths."
                            :forecast (forecast-of bucket)))))

(defun render-manual-conflict-table (conflicts empty-message)
  (if conflicts
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Path"))
                     (:th (views:esc "Reason"))
                     (:th (views:esc "Preferred resolution"))
                     (:th (views:esc "Result placement")))
                (loop for conflict in conflicts
                      do (views:html
                           (:tr (:td (views:object-ref conflict
                                                      :display
                                                      (format nil "~A"
                                                              (path-of conflict))))
                                (:td (views:esc (reason-of conflict)))
                                (:td (views:esc (preferred-resolution-of conflict)))
                                (:td (:tt (views:esc (result-placement-of conflict)))))))))
      (views:html
        (:p (views:esc empty-message)))))

(defun render-resolution-proposal-table (proposals empty-message)
  (if proposals
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Path"))
                     (:th (views:esc "Conflict shape"))
                     (:th (views:esc "Preferred merged form"))
                     (:th (views:esc "Result placement")))
                (loop for proposal in proposals
                      do (views:html
                           (:tr (:td (views:object-ref proposal
                                                      :display
                                                      (format nil "~A"
                                                              (path-of proposal))))
                                (:td (views:esc (conflict-shape-of proposal)))
                                (:td (views:esc (preferred-merged-form-of proposal)))
                                (:td (:tt (views:esc (result-placement-of proposal)))))))))
      (views:html
        (:p (views:esc empty-message)))))

(defun render-code-list (items empty-message)
  (if items
      (views:html
        (:ul
         (loop for item in items
               do (views:html
                    (:li (:tt (views:esc item)))))))
      (views:html
        (:p (views:esc empty-message)))))

(defun render-protocol-seam-card (seam)
  (views:html
    (:div :style "margin-bottom: 1.5em;"
          (:h4 (views:object-ref seam))
          (:p (views:esc (summary-of seam)))
          (:table :class "inspector-table"
                  (:tr (:td (views:esc "Seam type"))
                       (:td (:tt (views:esc (seam-type-of seam)))))
                  (:tr (:td (views:esc "Consumer system"))
                       (:td (:tt (views:esc (consumer-system-of seam)))))
                  (:tr (:td (views:esc "Scaffold"))
                       (:td (views:object-ref (scaffold-of seam)))))
          (:h5 "Core call surface")
          (:pre :style "white-space: pre-wrap"
                (views:esc (core-call-surface-of seam)))
          (:h5 "Behavior")
          (:pre :style "white-space: pre-wrap"
                (views:esc (behavior-of seam)))
          (:h5 "Core paths")
          (render-code-list (core-paths-of seam)
                            "No core paths recorded for this seam.")
          (:h5 "Downstream paths")
          (render-code-list (downstream-paths-of seam)
                            "No downstream paths recorded for this seam.")
          (:h5 "Symbols")
          (render-code-list (symbol-names-of seam)
                            "No symbols recorded for this seam.")
          (:h5 "Related proposals")
          (render-object-ref-list (realized-proposals-of seam)
                                  :empty "No related resolution proposals recorded.")
          (:h5 "Validation proof")
          (render-validation-proof-list (validation-proof-of seam)))))

(defun boolean-label (flag)
  (if flag "yes" "no"))

(defun render-rehearsal-summary-table (rehearsal)
  (let* ((manual-raw-results (git-typed-manual-raw-conflict-results rehearsal))
         (extra-conflicts (git-extra-raw-conflicts rehearsal))
         (remainder (git-rehearsal-untyped-raw-conflict-paths rehearsal)))
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Mechanism"))
                   (:td (:tt (views:esc (mechanism-of rehearsal)))))
              (:tr (:td (views:esc "Merge base"))
                   (:td (views:object-ref (merge-base-commit-of rehearsal))))
              (:tr (:td (views:esc "Virtual merge tree"))
                   (:td (:tt (views:esc (virtual-merge-tree-hash-of rehearsal)))))
              (:tr (:td (views:esc "Raw conflict paths"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (raw-conflict-paths-of rehearsal)))))))
              (:tr (:td (views:esc "Typed manual raw conflicts"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length manual-raw-results))))))
              (:tr (:td (views:esc "Typed extra raw conflicts"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length extra-conflicts))))))
              (:tr (:td (views:esc "Typed raw frontier total"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (git-typed-raw-conflict-frontier-count
                                       rehearsal))))))
              (:tr (:td (views:esc "Still-untyped raw conflicts"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length remainder))))))
              (:tr (:td (views:esc "Scaffold sufficient"))
                   (:td (:tt (views:esc
                              (boolean-label
                               (scaffold-sufficient-p-of rehearsal))))))
              (:tr (:td (views:esc "Scaffold status"))
                   (:td (:tt (views:esc (scaffold-direction-status-of rehearsal)))))))))

(defun render-rehearsal-result-table (results empty-message)
  (if results
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Path"))
                     (:th (views:esc "Merge-tree status"))
                     (:th (views:esc "Clean in principle"))
                     (:th (views:esc "Proposal readiness"))
                     (:th (views:esc "Scaffold sufficiency")))
                (loop for result in results
                      do (views:html
                           (:tr
                            (:td (views:object-ref result
                                                   :display
                                                   (format nil "~A"
                                                           (path-of result))))
                            (:td (:tt (views:esc
                                       (if-let (kind (conflict-kind-of result))
                                         (format nil "~A (~A)"
                                                 (merge-tree-status-of result)
                                                 kind)
                                         (merge-tree-status-of result)))))
                            (:td (:tt (views:esc
                                       (boolean-label
                                        (clean-in-principle-p-of result)))))
                            (:td (views:esc (proposal-readiness-of result)))
                            (:td (views:esc (scaffold-sufficiency-of result))))))))
      (views:html
        (:p (views:esc empty-message)))))

(defun render-extra-raw-conflict-table (conflicts empty-message)
  (if conflicts
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Path"))
                     (:th (views:esc "Conflict kind"))
                     (:th (views:esc "Looks like"))
                     (:th (views:esc "Promote"))
                     (:th (views:esc "Preliminary handling")))
                (loop for conflict in conflicts
                      do (views:html
                           (:tr
                            (:td (views:object-ref conflict
                                                   :display
                                                   (format nil "~A"
                                                           (path-of conflict))))
                            (:td (:tt (views:esc
                                       (or (conflict-kind-of conflict)
                                           "unknown"))))
                            (:td (:tt (views:esc (looks-like-of conflict))))
                            (:td (:tt (views:esc
                                       (boolean-label
                                        (promote-to-manual-dossier-p-of conflict)))))
                            (:td (views:esc
                                  (preliminary-preferred-handling-of conflict))))))))
      (views:html
        (:p (views:esc empty-message)))))

(defun render-merge-forecast-summary-table (forecast)
  (let* ((relation (relation-of forecast))
         (source-branch (source-branch-of relation))
         (target-branch (target-branch-of relation))
         (overlap-decisions (git-overlapping-path-decisions forecast))
         (manual-decisions (git-manual-overlapping-path-decisions forecast))
         (manual-conflicts (git-manual-conflicts forecast))
         (dreyeck-plan (git-dreyeck-extraction-plan-from-forecast forecast))
         (transition-plan (git-dreyeck-transition-plan-from-forecast forecast))
         (resolution-proposals
           (git-conflict-resolution-proposal-surface-from-forecast forecast))
         (dreyeck-candidates (git-hauptsache-dreyeck-candidate-decisions forecast))
         (unknown-paths (git-hauptsache-unknown-path-decisions forecast)))
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Relation"))
                   (:td (views:object-ref relation)))
              (:tr (:td (views:esc "Merge base"))
                   (:td (views:object-ref (merge-base-commit-of forecast)
                                         :display
                                         (short-git-commit-hash
                                          (commit-hash-of
                                           (merge-base-commit-of forecast))))))
              (:tr (:td (views:esc (format nil "~A-only paths"
                                           (branch-name-of source-branch))))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (upstream-only-paths-of forecast)))))))
              (:tr (:td (views:esc (format nil "~A-only paths"
                                           (branch-name-of target-branch))))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (hauptsache-only-paths-of forecast)))))))
              (:tr (:td (views:esc "Overlapping paths"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (overlapping-paths-of forecast)))))))
              (:tr (:td (views:esc "Overlapping decisions"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length overlap-decisions))))))
              (:tr (:td (views:esc "Manual overlapping paths"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length manual-decisions))))))
              (:tr (:td (views:esc "Hauptsache dreyeck candidates"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length dreyeck-candidates))))))
              (:tr (:td (views:esc "Hauptsache unknown paths"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length unknown-paths))))))
              (:tr (:td (views:esc "Extraction plan buckets"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (buckets-of dreyeck-plan)))))))
              (:tr (:td (views:esc "Transition plan buckets"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (bucket-transitions-of transition-plan)))))))
              (:tr (:td (views:esc "Manual conflict dossier items"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length manual-conflicts))))))
              (:tr (:td (views:esc "Resolution proposals"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (proposals-of resolution-proposals)))))))
              (:tr (:td (views:esc "Dreyeck notes"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (notes-of forecast)))))))
              (:tr (:td (views:esc "Blocker summary"))
                   (:td (views:esc (blocker-summary-of forecast))))))))

(defmethod views:text-representation ((branch-ref git-branch-ref))
  (format nil "~A @ ~A"
          (branch-name-of branch-ref)
          (short-git-commit-hash (commit-hash-of branch-ref))))

(defmethod views:text-representation ((relation git-merge-intent))
  (title-of relation))

(defmethod views:text-representation ((note git-merge-preparation-note))
  (title-of note))

(defmethod views:text-representation ((forecast git-merge-forecast))
  (title-of forecast))

(defmethod views:text-representation ((decision git-path-decision))
  (format nil "~A [~A]"
          (path-of decision)
          (classification-of decision)))

(defmethod views:text-representation ((annotation git-path-annotation))
  (format nil "~A [~A]"
          (relative-path-of annotation)
          (short-label-of annotation)))

(defmethod views:text-representation ((path-item git-forecast-path-item))
  (relative-path-of path-item))

(defmethod views:text-representation ((surface git-forecast-path-context-surface))
  (worked-example-path-of surface))

(defmethod views:text-representation ((plan git-dreyeck-extraction-plan))
  (title-of plan))

(defmethod views:text-representation ((bucket git-dreyeck-extraction-bucket))
  (title-of bucket))

(defmethod views:text-representation ((plan git-dreyeck-transition-plan))
  (title-of plan))

(defmethod views:text-representation ((bucket git-dreyeck-transition-bucket))
  (title-of bucket))

(defmethod views:text-representation ((conflict git-manual-conflict))
  (format nil "~A [manual]"
          (path-of conflict)))

(defmethod views:text-representation ((dossier git-manual-conflict-dossier))
  (title-of dossier))

(defmethod views:text-representation ((proposal git-conflict-resolution-proposal))
  (format nil "~A [proposal]"
          (path-of proposal)))

(defmethod views:text-representation ((surface git-conflict-resolution-proposal-surface))
  (title-of surface))

(defmethod views:text-representation ((scaffold git-dreyeck-executable-scaffold))
  (title-of scaffold))

(defmethod views:text-representation ((seam git-protocol-seam))
  (title-of seam))

(defmethod views:text-representation ((surface git-protocol-seam-surface))
  (title-of surface))

(defmethod views:text-representation ((rehearsal git-merge-rehearsal))
  (title-of rehearsal))

(defmethod views:text-representation ((result git-rehearsal-result))
  (format nil "~A [~:[needs work~;clean in principle~]]"
          (path-of result)
          (clean-in-principle-p-of result)))

(defmethod views:text-representation ((conflict git-extra-raw-conflict))
  (format nil "~A [~A]"
          (path-of conflict)
          (or (conflict-kind-of conflict)
              "unknown")))

(defmethod views:text-representation ((surface git-raw-conflict-surface))
  (title-of surface))

(defmethod views:text-representation ((surface git-path-decision-surface))
  (title-of surface))

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
                     (:td (:tt (views:esc (namestring (repo-root-of branch-ref))))))
                (:tr (:td (views:esc "Repository root source"))
                     (:td (:tt (views:esc
                                (git-repository-root-source-label
                                 (repository-root-source-of branch-ref))))))
                (:tr (:td (views:esc "Repository root mode"))
                     (:td (:tt (views:esc
                                (git-repository-root-origin-label
                                 (repo-root-of branch-ref)
                                 (repository-root-source-of branch-ref)))))))))))

(views:defview 👀merge-intent (relation git-merge-intent)
  (let ((forecast (git-merge-forecast-from-relation relation))
        (notes (notes-of relation)))
    (views:html-view :title "Merge intent" :priority 1
      (let ((rehearsal (git-merge-rehearsal-from-forecast forecast)))
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
        (:h4 "Preparation forecast")
        (views:object-ref forecast)
        (render-merge-forecast-summary-table forecast)
        (:h4 "Dry-run rehearsal")
        (views:object-ref rehearsal)
        (:h4 "Dreyeck extraction candidates")
        (render-preparation-notes notes)
        (:h4 "Success criteria")
        (:ul
         (loop for criterion in (success-criteria-of relation)
               do (views:html
                    (:li (views:esc criterion))))))))))

(views:defview 👀summary (note git-merge-preparation-note)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of note)))
      (:p (views:esc (summary-of note)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Relation"))
                   (:td (views:object-ref (relation-of note))))
              (:tr (:td (views:esc "Note type"))
                   (:td (:tt (views:esc (note-type-of note)))))
              (:tr (:td (views:esc "Status"))
                   (:td (:tt (views:esc (status-of note))))))
      (:h4 "Recommendation")
      (:pre :style "white-space: pre-wrap"
            (views:esc (recommendation-of note))))))

(views:defview 👀paths (note git-merge-preparation-note)
  (views:html-view :title "Paths" :priority 2
    (views:html
      (:h3 (views:esc (title-of note)))
      (render-path-list (paths-of note)
                        "This note does not currently name any paths."))))

(views:defview 👀merge-forecast (forecast git-merge-forecast)
  (views:html-view :title "Merge forecast" :priority 1
    (views:html
      (:h3 (views:esc (title-of forecast)))
      (:p (views:esc (summary-of forecast)))
      (render-merge-forecast-summary-table forecast)
      (:h4 "Decision surfaces")
      (:ul
       (:li (views:object-ref (git-overlapping-path-decision-surface forecast)))
       (:li (views:object-ref (git-dreyeck-candidate-path-surface forecast)))
       (:li (views:object-ref (git-unresolved-manual-path-surface forecast)))
       (:li (views:object-ref (git-dreyeck-extraction-plan-from-forecast forecast)))
       (:li (views:object-ref (git-dreyeck-transition-plan-from-forecast forecast)))
       (:li (views:object-ref (git-manual-conflict-dossier-from-forecast forecast)))
       (:li (views:object-ref (git-conflict-resolution-proposal-surface-from-forecast forecast)))
       (:li (views:object-ref (git-dreyeck-executable-scaffold-from-forecast forecast)))
       (:li (views:object-ref (git-protocol-seam-surface-from-forecast forecast)))
       (:li (views:object-ref (git-raw-conflict-surface-from-forecast forecast)))
       (:li (views:object-ref (git-merge-rehearsal-from-forecast forecast))))
      (:h4 "Attached notes")
      (render-preparation-notes (notes-of forecast)))))

(views:defview 👀upstream-only-files (forecast git-merge-forecast)
  (let ((source-branch (source-branch-of (relation-of forecast))))
    (views:html-view :title "Upstream-only files" :priority 2
      (include-git-path-context-menu-assets)
      (views:html
        (:h3 (views:esc
              (format nil "~A-only paths"
                      (branch-name-of source-branch))))
        (render-path-list
         (upstream-only-paths-of forecast)
         (format nil "No ~A-only paths at the anchored commits."
                 (branch-name-of source-branch))
         :forecast forecast
         :path-set "upstream-only")))))

(views:defview 👀hauptsache-only-files (forecast git-merge-forecast)
  (let ((target-branch (target-branch-of (relation-of forecast))))
    (views:html-view :title "Hauptsache-only files" :priority 3
      (include-git-path-context-menu-assets)
      (views:html
        (:h3 (views:esc
              (format nil "~A-only paths"
                      (branch-name-of target-branch))))
        (render-path-list
         (hauptsache-only-paths-of forecast)
         (format nil "No ~A-only paths at the anchored commits."
                 (branch-name-of target-branch))
         :forecast forecast
         :path-set "hauptsache-only")))))

(views:defview 👀overlapping-paths (forecast git-merge-forecast)
  (views:html-view :title "Overlapping paths" :priority 4
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 "Overlapping paths")
      (:p (views:esc (blocker-summary-of forecast)))
      (render-path-list
       (overlapping-paths-of forecast)
       "No overlapping paths at the anchored commits."
       :forecast forecast
       :path-set "overlapping"))))

(views:defview 👀overlapping-path-decisions (forecast git-merge-forecast)
  (views:html-view :title "Overlapping path decisions" :priority 5
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 "Overlapping path decisions")
      (render-path-decision-table
       (git-overlapping-path-decisions forecast)
       "No overlapping path decisions are available."))))

(views:defview 👀hauptsache-path-decisions (forecast git-merge-forecast)
  (views:html-view :title "Hauptsache path decisions" :priority 6
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 "Hauptsache-only path classifications")
      (render-path-decision-table
       (git-hauptsache-only-path-decisions forecast)
       "No hauptsache-only path classifications are available."))))

(views:defview 👀dreyeck-candidate-paths (forecast git-merge-forecast)
  (views:html-view :title "Dreyeck candidate paths" :priority 7
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 "Dreyeck candidate paths")
      (render-path-decision-table
       (git-hauptsache-dreyeck-candidate-decisions forecast)
       "No hauptsache-only paths are currently tagged as dreyeck candidates."))))

(views:defview 👀unresolved-manual-paths (forecast git-merge-forecast)
  (views:html-view :title "Unresolved manual paths" :priority 8
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 "Unresolved manual overlapping paths")
      (render-path-decision-table
       (git-manual-overlapping-path-decisions forecast)
       "No overlapping paths currently require manual merge decisions."))))

(views:defview 👀summary (decision git-path-decision)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (:tt (views:esc (path-of decision))))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Path set"))
                   (:td (:tt (views:esc (path-set-of decision)))))
              (:tr (:td (views:esc "Classification"))
                   (:td (:tt (views:esc (classification-of decision)))))
              (:tr (:td (views:esc "Relation"))
                   (:td (views:object-ref (relation-of decision))))
              (:tr (:td (views:esc "Annotation"))
                   (:td (maybe-path-annotation-ref
                         (git-path-annotation-for-decision decision)
                         :display "Path annotation")))
              (:tr (:td (views:esc "Linked note"))
                   (:td (maybe-linked-note-ref (linked-note-of decision)))))
      (:h4 "Rationale")
      (:pre :style "white-space: pre-wrap"
            (views:esc (rationale-of decision))))))

(views:defview 👀summary (annotation git-path-annotation)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (:tt (views:esc (relative-path-of annotation))))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of annotation))))
              (:tr (:td (views:esc "Bucket"))
                   (:td (:tt (views:esc (bucket-of annotation)))))
              (:tr (:td (views:esc "Owner"))
                   (:td (:tt (views:esc (owner-of annotation)))))
              (:tr (:td (views:esc "Label"))
                   (:td (views:esc (short-label-of annotation))))
              (:tr (:td (views:esc "Related paths"))
                   (:td (if (related-paths-of annotation)
                            (views:html
                              (:ul
                               (loop for path in (related-paths-of annotation)
                                     do (views:html
                                          (:li (:tt (views:esc path)))))))
                            (views:html
                              (:span :style "opacity: 0.55;" "-")))))))))

(views:defview 👀rationale (annotation git-path-annotation)
  (views:html-view :title "Rationale" :priority 2
    (views:html
      (:h3 (views:esc (short-label-of annotation)))
      (:pre :style "white-space: pre-wrap"
            (views:esc (long-rationale-of annotation))))))

(views:defview 👀path-decision (annotation git-path-annotation)
  (views:html-view :title "Path decision" :priority 3
    (views:html
      (:h3 (:tt (views:esc (relative-path-of annotation))))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Bucket"))
                   (:td (:tt (views:esc (bucket-of annotation)))))
              (:tr (:td (views:esc "Owner"))
                   (:td (:tt (views:esc (owner-of annotation)))))
              (:tr (:td (views:esc "Merge policy"))
                   (:td (:pre :style "white-space: pre-wrap; margin: 0;"
                              (views:esc (merge-policy-of annotation)))))))))

(views:defview 👀summary (path-item git-forecast-path-item)
  (views:html-view :title "Summary" :priority 1
    (let* ((forecast (forecast-of path-item))
           (annotation (git-path-annotation-for-path forecast
                                                     (relative-path-of path-item)))
           (related-decisions (git-related-path-decisions path-item)))
      (views:html
        (:h3 (:tt (views:esc (relative-path-of path-item))))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Forecast"))
                     (:td (views:object-ref forecast)))
                (:tr (:td (views:esc "Path set"))
                     (:td (:tt (views:esc (or (path-set-of path-item)
                                              "n/a")))))
                (:tr (:td (views:esc "Annotation"))
                     (:td (if annotation
                              (views:object-ref annotation)
                              (views:object-ref
                               (git-openable-path-annotation-for-path
                                forecast
                                (relative-path-of path-item)
                                :path-set (path-set-of path-item))
                               :display "Draft annotation"))))
                (:tr (:td (views:esc "Related decisions"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (length related-decisions)))))))))))

(views:defview 👀summary (surface git-forecast-path-context-surface)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (:tt (views:esc (worked-example-path-of surface))))
      (:p (views:esc (summary-of surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of surface))))
              (:tr (:td (views:esc "Path item"))
                   (:td (views:object-ref (path-item-of surface))))
              (:tr (:td (views:esc "Annotation target"))
                   (:td (views:object-ref (annotation-target-of surface))))
              (:tr (:td (views:esc "Path set"))
                   (:td (:tt (views:esc (or (path-set-of surface) "n/a")))))
              (:tr (:td (views:esc "Worked example"))
                   (:td (:tt (views:esc (worked-example-path-of surface)))))))))

(views:defview 👀commands (surface git-forecast-path-context-surface)
  (views:html-view :title "Commands" :priority 2
    (let* ((path-item (path-item-of surface))
           (actions (git-forecast-path-context-action-specs
                     path-item
                     :forecast (forecast-of surface)
                     :path-set (path-set-of surface))))
      (views:html
        (:h3 "Context commands")
        (:table :class "inspector-table"
                (:tr (:th "Command")
                     (:th "Enabled")
                     (:th "Target"))
                (loop for action in actions
                      do (render-path-context-command-row action)))))))

(views:defview 👀implementation (surface git-forecast-path-context-surface)
  (views:html-view :title "Implementation" :priority 3
    (views:html
      (:h3 "Current implementation contract")
      (:ul
       (:li "Inspectable row targets are "
            (:tt "git-forecast-path-item")
            " objects rendered by the merge-forecast views.")
       (:li "Context actions are hidden "
            (:tt "views:object-ref")
            " links inside "
            (:tt ".git-path-context-actions")
            ".")
       (:li "The menu shell is custom client code from "
            (:tt "assets/hyperdoc/js/git-path-context-menu.js")
            " plus "
            (:tt "assets/hyperdoc/css/git-path-context-menu.css")
            ".")
       (:li "Action transport stays object-ref based: the custom menu dispatches a click to the hidden anchor instead of inventing a second command transport.")
       (:li "This is the current HyperDoc implementation pattern, not a generic DMX port.")))))

(views:defview 👀related-decisions (path-item git-forecast-path-item)
  (views:html-view :title "Related decisions" :priority 2
    (let ((related-decisions (git-related-path-decisions path-item)))
      (include-git-path-context-menu-assets)
      (views:html
        (:h3 (:tt (views:esc (relative-path-of path-item))))
        (if related-decisions
            (render-path-decision-table
             related-decisions
             "No related decisions are recorded for this path.")
            (views:html
              (:p "No related decisions are recorded for this path.")))))))

(views:defview 👀summary (plan git-dreyeck-extraction-plan)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of plan)))
      (:p (views:esc (summary-of plan)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of plan))))
              (:tr (:td (views:esc "Bucket count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (buckets-of plan)))))))
              (:tr (:td (views:esc "Candidate paths"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (reduce #'+ (mapcar (lambda (bucket)
                                                            (length (paths-of bucket)))
                                                          (buckets-of plan))
                                              :initial-value 0))))))))))

(views:defview 👀dreyeck-extraction-plan (plan git-dreyeck-extraction-plan)
  (views:html-view :title "Dreyeck extraction plan" :priority 2
    (views:html
      (:h3 (views:esc (title-of plan)))
      (loop for bucket in (buckets-of plan)
            do (render-dreyeck-bucket-card bucket)))))

(views:defview 👀summary (bucket git-dreyeck-extraction-bucket)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of bucket)))
      (:p (views:esc (summary-of bucket)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Bucket type"))
                   (:td (:tt (views:esc (bucket-type-of bucket)))))
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of bucket))))
              (:tr (:td (views:esc "Expected ASDF placement"))
                   (:td (:tt (views:esc (expected-asdf-placement-of bucket)))))
              (:tr (:td (views:esc "Dependency direction"))
                   (:td (:tt (views:esc (expected-dependency-direction-of bucket)))))
              (:tr (:td (views:esc "Adaptation mode"))
                   (:td (:tt (views:esc (adaptation-mode-of bucket))))))
      (:h4 "Why not upstream core")
      (:pre :style "white-space: pre-wrap"
            (views:esc (why-not-upstream-core-of bucket))))))

(views:defview 👀paths (bucket git-dreyeck-extraction-bucket)
  (views:html-view :title "Paths" :priority 2
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 (views:esc (title-of bucket)))
      (render-path-list (paths-of bucket)
                        "This bucket does not currently hold any paths."
                        :forecast (forecast-of bucket)))))

(views:defview 👀summary (plan git-dreyeck-transition-plan)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of plan)))
      (:p (views:esc (summary-of plan)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of plan))))
              (:tr (:td (views:esc "Extraction plan"))
                   (:td (views:object-ref (extraction-plan-of plan))))
              (:tr (:td (views:esc "Bucket transitions"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (bucket-transitions-of plan)))))))))))

(views:defview 👀dreyeck-transition-plan (plan git-dreyeck-transition-plan)
  (views:html-view :title "Dreyeck transition plan" :priority 2
    (views:html
      (:h3 (views:esc (title-of plan)))
      (loop for bucket in (bucket-transitions-of plan)
            do (render-transition-bucket-card bucket)))))

(views:defview 👀summary (bucket git-dreyeck-transition-bucket)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of bucket)))
      (:p (views:esc (summary-of bucket)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Extraction bucket"))
                   (:td (views:object-ref (extraction-bucket-of bucket))))
              (:tr (:td (views:esc "Target destination"))
                   (:td (:tt (views:esc (target-destination-of bucket)))))
              (:tr (:td (views:esc "Dependency direction"))
                   (:td (:tt (views:esc (dependency-direction-of bucket)))))
              (:tr (:td (views:esc "Transition mode"))
                   (:td (:tt (views:esc (transition-mode-of bucket))))))
      (:h4 "Core continuation")
      (:pre :style "white-space: pre-wrap"
            (views:esc (core-continuation-of bucket)))
      (:h4 "Validation proof")
      (render-validation-proof-list (validation-proof-of bucket)))))

(views:defview 👀paths (bucket git-dreyeck-transition-bucket)
  (views:html-view :title "Paths" :priority 2
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 (views:esc (title-of bucket)))
      (render-path-list (paths-of bucket)
                        "This transition bucket does not currently hold any paths."
                        :forecast (forecast-of bucket)))))

(views:defview 👀summary (conflict git-manual-conflict)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (:tt (views:esc (path-of conflict))))
      (:p (views:esc (summary-of conflict)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source branch"))
                   (:td (views:object-ref (source-branch-of conflict))))
              (:tr (:td (views:esc "Target branch"))
                   (:td (views:object-ref (target-branch-of conflict))))
              (:tr (:td (views:esc "Decision"))
                   (:td (views:object-ref (decision-of conflict))))
              (:tr (:td (views:esc "Result placement"))
                   (:td (:tt (views:esc (result-placement-of conflict))))))
      (:h4 "Reason")
      (:pre :style "white-space: pre-wrap"
            (views:esc (reason-of conflict)))
      (:h4 "Preferred resolution")
      (:pre :style "white-space: pre-wrap"
            (views:esc (preferred-resolution-of conflict))))))

(views:defview 👀summary (dossier git-manual-conflict-dossier)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of dossier)))
      (:p (views:esc (summary-of dossier)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of dossier))))
              (:tr (:td (views:esc "Conflict count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (conflicts-of dossier)))))))))))

(views:defview 👀manual-conflicts (dossier git-manual-conflict-dossier)
  (views:html-view :title "Manual conflicts" :priority 2
    (views:html
      (:h3 (views:esc (title-of dossier)))
      (render-manual-conflict-table
       (conflicts-of dossier)
       "No manual conflicts remain in this dossier."))))

(views:defview 👀summary (proposal git-conflict-resolution-proposal)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (:tt (views:esc (path-of proposal))))
      (:p (views:esc (summary-of proposal)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source branch"))
                   (:td (views:object-ref (source-branch-of proposal))))
              (:tr (:td (views:esc "Target branch"))
                   (:td (views:object-ref (target-branch-of proposal))))
              (:tr (:td (views:esc "Manual conflict"))
                   (:td (views:object-ref (conflict-of proposal))))
              (:tr (:td (views:esc "Result placement"))
                   (:td (:tt (views:esc (result-placement-of proposal))))))
      (:h4 "Conflict shape")
      (:pre :style "white-space: pre-wrap"
            (views:esc (conflict-shape-of proposal)))
      (:h4 "Preferred merged form")
      (:pre :style "white-space: pre-wrap"
            (views:esc (preferred-merged-form-of proposal)))
      (:h4 "Patch sketch")
      (:pre :style "white-space: pre-wrap"
            (views:esc (patch-sketch-of proposal))))))

(views:defview 👀summary (surface git-conflict-resolution-proposal-surface)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc (summary-of surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of surface))))
              (:tr (:td (views:esc "Manual dossier"))
                   (:td (views:object-ref (manual-dossier-of surface))))
              (:tr (:td (views:esc "Proposal count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (proposals-of surface)))))))))))

(views:defview 👀resolution-proposals (surface git-conflict-resolution-proposal-surface)
  (views:html-view :title "Resolution proposals" :priority 2
    (views:html
      (:h3 (views:esc (title-of surface)))
      (render-resolution-proposal-table
       (proposals-of surface)
       "No resolution proposals are recorded."))))

(views:defview 👀summary (scaffold git-dreyeck-executable-scaffold)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of scaffold)))
      (:p (views:esc (summary-of scaffold)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of scaffold))))
              (:tr (:td (views:esc "Transition plan"))
                   (:td (views:object-ref (transition-plan-of scaffold))))
              (:tr (:td (views:esc "Proposal surface"))
                   (:td (views:object-ref (proposal-surface-of scaffold))))
              (:tr (:td (views:esc "System count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (system-names-of scaffold)))))))
              (:tr (:td (views:esc "Realized proposals"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (realized-proposals-of scaffold)))))))))))

(views:defview 👀dreyeck-executable-scaffold (scaffold git-dreyeck-executable-scaffold)
  (views:html-view :title "Dreyeck executable scaffold" :priority 2
    (views:html
      (:h3 (views:esc (title-of scaffold)))
      (:p (views:esc (summary-of scaffold)))
      (:h4 "Systems")
      (render-code-list (system-names-of scaffold)
                        "No system names recorded for the scaffold.")
      (:h4 "Packages")
      (render-code-list (package-names-of scaffold)
                        "No package names recorded for the scaffold.")
      (:h4 "Components")
      (render-code-list (component-paths-of scaffold)
                        "No component paths recorded for the scaffold.")
      (:h4 "Realized resolution proposals")
      (render-object-ref-list (realized-proposals-of scaffold)
                              :empty "No realized proposals recorded for the scaffold.")
      (:h4 "Validation commands")
      (render-code-list (validation-commands-of scaffold)
                        "No validation commands recorded for the scaffold.")
      (:h4 "Protocol seams")
      (views:object-ref (git-protocol-seam-surface-from-forecast
                         (forecast-of scaffold))))))

(views:defview 👀summary (seam git-protocol-seam)
  (views:html-view :title "Summary" :priority 1
    (render-protocol-seam-card seam)))

(views:defview 👀summary (surface git-protocol-seam-surface)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc (summary-of surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Scaffold"))
                   (:td (views:object-ref (scaffold-of surface))))
              (:tr (:td (views:esc "Seam count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (seams-of surface)))))))))))

(views:defview 👀protocol-seams (surface git-protocol-seam-surface)
  (views:html-view :title "Protocol seams" :priority 2
    (views:html
      (:h3 (views:esc (title-of surface)))
      (loop for seam in (seams-of surface)
            do (render-protocol-seam-card seam)))))

(views:defview 👀summary (rehearsal git-merge-rehearsal)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of rehearsal)))
      (:p (views:esc (summary-of rehearsal)))
      (render-rehearsal-summary-table rehearsal))))

(views:defview 👀merge-rehearsal (rehearsal git-merge-rehearsal)
  (views:html-view :title "Merge rehearsal" :priority 2
    (let ((raw-conflict-surface
            (git-raw-conflict-surface-from-forecast
             (forecast-of rehearsal))))
      (views:html
        (:h3 (views:esc (title-of rehearsal)))
        (:p (views:esc (summary-of rehearsal)))
        (render-rehearsal-summary-table rehearsal)
        (:h4 "Linked objects")
        (:ul
         (:li (views:object-ref (forecast-of rehearsal)))
         (:li (views:object-ref (scaffold-of rehearsal)))
         (:li (views:object-ref (proposal-surface-of rehearsal)))
         (:li (views:object-ref raw-conflict-surface)))
        (:h4 "Typed manual-dossier results on the raw frontier")
        (render-rehearsal-result-table
         (typed-manual-results-of raw-conflict-surface)
         "No manual-dossier results remain on the current raw conflict frontier.")
        (:h4 "Typed extra raw conflicts outside the current manual dossier")
        (render-extra-raw-conflict-table
         (extra-conflicts-of raw-conflict-surface)
         "No extra raw conflicts remain outside the current manual dossier.")
        (:h4 "Still-untyped raw conflict remainder")
        (render-path-list
         (remainder-paths-of raw-conflict-surface)
         "No raw merge-tree conflicts remain outside the typed manual plus extra conflict frontier.")
        (:h4 "Scaffold evidence")
        (render-validation-proof-list (scaffold-evidence-of rehearsal))
        (:h4 "Manual-conflict rehearsal results")
        (render-rehearsal-result-table
         (rehearsal-results-of rehearsal)
         "No rehearsal results are recorded.")))))

(views:defview 👀rehearsal-results (rehearsal git-merge-rehearsal)
  (views:html-view :title "Rehearsal results" :priority 3
    (let ((raw-conflict-surface
            (git-raw-conflict-surface-from-forecast
             (forecast-of rehearsal))))
      (views:html
        (:h3 (views:esc (title-of rehearsal)))
        (:h4 "Typed manual-dossier results")
        (render-rehearsal-result-table
         (rehearsal-results-of rehearsal)
         "No rehearsal results are recorded.")
        (:h4 "Typed extra raw conflicts")
        (render-extra-raw-conflict-table
         (extra-conflicts-of raw-conflict-surface)
         "No extra raw conflicts remain outside the current manual dossier.")
        (:h4 "Still-untyped raw conflict remainder")
        (render-path-list
         (remainder-paths-of raw-conflict-surface)
         "No raw merge-tree conflicts remain outside the typed manual plus extra conflict frontier.")))))

(views:defview 👀summary (result git-rehearsal-result)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (:tt (views:esc (path-of result))))
      (:p (views:esc (summary-of result)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Rehearsal"))
                   (:td (views:object-ref (rehearsal-of result))))
              (:tr (:td (views:esc "Manual conflict"))
                   (:td (views:object-ref (conflict-of result))))
              (:tr (:td (views:esc "Proposal"))
                   (:td (views:object-ref (proposal-of result))))
              (:tr (:td (views:esc "Merge-tree status"))
                   (:td (:tt (views:esc
                              (if-let (kind (conflict-kind-of result))
                                (format nil "~A (~A)"
                                        (merge-tree-status-of result)
                                        kind)
                                (merge-tree-status-of result))))))
              (:tr (:td (views:esc "Clean in principle"))
                   (:td (:tt (views:esc
                              (boolean-label
                               (clean-in-principle-p-of result))))))
              (:tr (:td (views:esc "Proposal readiness"))
                   (:td (views:esc (proposal-readiness-of result))))
              (:tr (:td (views:esc "Scaffold sufficiency"))
                   (:td (views:esc (scaffold-sufficiency-of result)))))
      (:h4 "Rationale")
      (:pre :style "white-space: pre-wrap"
            (views:esc (rationale-of result)))
      (:h4 "Evidence")
      (render-validation-proof-list (evidence-of result)))))

(views:defview 👀summary (conflict git-extra-raw-conflict)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (:tt (views:esc (path-of conflict))))
      (:p (views:esc (summary-of conflict)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Rehearsal"))
                   (:td (views:object-ref (rehearsal-of conflict))))
              (:tr (:td (views:esc "Conflict kind"))
                   (:td (:tt (views:esc
                              (or (conflict-kind-of conflict)
                                  "unknown")))))
              (:tr (:td (views:esc "Looks like"))
                   (:td (:tt (views:esc (looks-like-of conflict)))))
              (:tr (:td (views:esc "Promote into manual dossier"))
                   (:td (:tt (views:esc
                              (boolean-label
                               (promote-to-manual-dossier-p-of conflict)))))))
      (:h4 "Preliminary preferred handling")
      (:pre :style "white-space: pre-wrap"
            (views:esc (preliminary-preferred-handling-of conflict))))))

(views:defview 👀summary (surface git-raw-conflict-surface)
  (views:html-view :title "Summary" :priority 1
    (let ((typed-manual-count (length (typed-manual-results-of surface)))
          (extra-count (length (extra-conflicts-of surface)))
          (remainder-count (length (remainder-paths-of surface))))
      (views:html
        (:h3 (views:esc (title-of surface)))
        (:p (views:esc (summary-of surface)))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Rehearsal"))
                     (:td (views:object-ref (rehearsal-of surface))))
                (:tr (:td (views:esc "Typed manual raw conflicts"))
                     (:td (:tt (views:esc
                                (format nil "~D" typed-manual-count)))))
                (:tr (:td (views:esc "Typed extra raw conflicts"))
                     (:td (:tt (views:esc
                                (format nil "~D" extra-count)))))
                (:tr (:td (views:esc "Typed raw frontier total"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (+ typed-manual-count extra-count))))))
                (:tr (:td (views:esc "Still-untyped raw conflicts"))
                     (:td (:tt (views:esc
                                (format nil "~D" remainder-count))))))))))

(views:defview 👀raw-conflicts (surface git-raw-conflict-surface)
  (views:html-view :title "Raw conflicts" :priority 2
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:h4 "Typed manual-dossier results on the raw frontier")
      (render-rehearsal-result-table
       (typed-manual-results-of surface)
       "No manual-dossier results remain on the raw conflict frontier.")
      (:h4 "Typed extra raw conflicts")
      (render-extra-raw-conflict-table
       (extra-conflicts-of surface)
       "No extra raw conflicts remain outside the current manual dossier.")
      (:h4 "Still-untyped raw conflict remainder")
      (render-path-list
       (remainder-paths-of surface)
       "No raw merge-tree conflicts remain outside the typed manual plus extra conflict frontier."
       :forecast (forecast-of surface)))))

(views:defview 👀summary (surface git-path-decision-surface)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc (summary-of surface)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Forecast"))
                   (:td (views:object-ref (forecast-of surface))))
              (:tr (:td (views:esc "Decision count"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (length (decisions-of surface)))))))))))

(views:defview 👀path-decisions (surface git-path-decision-surface)
  (views:html-view :title "Path decisions" :priority 2
    (include-git-path-context-menu-assets)
    (views:html
      (:h3 (views:esc (title-of surface)))
      (render-path-decision-table
       (decisions-of surface)
       "No path decisions are available on this surface."))))

(views:defview 👀git-history (surface git-history-surface)
  (let* ((local-branch (local-branch-of surface))
         (upstream-branch (upstream-branch-of surface))
         (relations (relations-of surface))
         (forecasts (git-history-merge-forecasts surface))
         (local-commits (git-history-local-commits surface))
         (upstream-commits (git-history-upstream-commits surface))
         (row-count (max (length local-commits)
                         (length upstream-commits))))
    (views:html-view :title "Git history" :priority 1
      (views:html
        (:h3 (views:esc (title-of surface)))
        (:p (views:esc (summary-of surface)))
        (:p "This first slice is lane-based and declarative: branch anchors and merge relations are durable objects, while the row list below stays intentionally narrower than a full DAG renderer.")
        (:h4 "Repository root")
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Effective root"))
                     (:td (:tt (views:esc (namestring (repo-root-of surface))))))
                (:tr (:td (views:esc "Root source"))
                     (:td (:tt (views:esc
                                (git-repository-root-source-label
                                 (repository-root-source-of surface))))))
                (:tr (:td (views:esc "Root mode"))
                     (:td (:tt (views:esc
                                (git-repository-root-origin-label
                                 (repo-root-of surface)
                                 (repository-root-source-of surface)))))))
        (:h4 "Lane anchors")
        (:table :class "inspector-table"
                (:tr (:th (views:esc (branch-name-of local-branch)))
                     (:th (views:esc "Relation"))
                     (:th (views:esc (branch-name-of upstream-branch))))
                (:tr (:td (render-branch-anchor-card local-branch))
                     (:td (render-relations-list relations))
                     (:td (render-branch-anchor-card upstream-branch))))
        (:h4 "Merge preparation")
        (if forecasts
            (views:html
              (loop for forecast in forecasts
                    do (views:html
                         (:div :style "margin-bottom: 1.5em;"
                               (:h5 (views:object-ref forecast))
                               (render-merge-forecast-summary-table forecast)))))
            (views:html
              (:p "No merge forecasts are available for the current relations.")))
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
                    for forecast = (git-merge-forecast-from-relation relation)
                    for scaffold = (git-dreyeck-executable-scaffold-from-forecast forecast)
                    for seam-surface = (git-protocol-seam-surface-from-forecast forecast)
                    for rehearsal = (git-merge-rehearsal-from-forecast forecast)
                    do (views:html
                         (:div :style "margin-bottom: 1.5em;"
                               (:h4 (views:object-ref relation))
                               (render-merge-intent-summary-table relation)
                               (:h5 "Forecast")
                               (views:object-ref forecast)
                               (render-merge-forecast-summary-table forecast)
                               (:h5 "Executable scaffold")
                               (views:object-ref scaffold)
                               (:h5 "Protocol seams")
                               (views:object-ref seam-surface)
                               (:h5 "Dry-run rehearsal")
                               (views:object-ref rehearsal)
                               (:h5 "Dreyeck extraction candidates")
                               (render-preparation-notes (notes-of relation))
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
