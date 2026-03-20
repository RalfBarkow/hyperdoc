;;;; Explorer views for Git commit equivalence proofs
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun render-proof-preformatted-lines (lines)
  (views:html
    (:pre :style "white-space: pre-wrap;"
          (views:esc (if lines
                         (format nil "~{~A~%~}" lines)
                         "")))))

(defun yes-no-label (flag)
  (if flag "yes" "no"))

(defun render-commit-reference-or-placeholder (object)
  (if object
      (views:object-ref object)
      (views:html (:tt "none"))))

(defmethod views:text-representation ((check git-commit-equivalence-check))
  (format nil "~A -> ~A"
          (short-git-commit-hash (commit-hash-of (source-commit-of check)))
          (target-branch-of check)))

(defmethod views:text-representation ((surface git-commit-equivalence-surface))
  (title-of surface))

(views:defview 👀summary (check git-commit-equivalence-check)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of check)))
      (:p (views:esc (summary-of check)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source commit"))
                   (:td (views:object-ref (source-commit-of check))))
              (:tr (:td (views:esc "Source branch"))
                   (:td (:tt (views:esc (source-branch-of check)))))
              (:tr (:td (views:esc "Target branch"))
                   (:td (:tt (views:esc (target-branch-of check)))))
              (:tr (:td (views:esc "Shared base"))
                   (:td (views:object-ref (shared-base-of check))))
              (:tr (:td (views:esc "Repository root"))
                   (:td (:tt (views:esc (namestring (repo-root-of check))))))
              (:tr (:td (views:esc "Repository root source"))
                   (:td (:tt (views:esc
                              (git-repository-root-source-label
                               (repository-root-source-of check))))))
              (:tr (:td (views:esc "Ancestry present?"))
                   (:td (:tt (views:esc
                              (yes-no-label (ancestry-present-p check))))))
              (:tr (:td (views:esc "Patch equivalent?"))
                   (:td (:tt (views:esc
                              (yes-no-label (patch-equivalent-p check))))))
              (:tr (:td (views:esc "Replayed equivalent commit"))
                   (:td (render-commit-reference-or-placeholder
                         (replayed-equivalent-commit-of check)))))
      (:h4 "Status")
      (:p (views:esc (status-summary-of check)))
      (:h4 "Interpretation")
      (:p (views:esc (merge-intent-interpretation-of check))))))

(views:defview 👀proof (check git-commit-equivalence-check)
  (views:html-view :title "Proof" :priority 2
    (views:html
      (:h4 "Commands used")
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Ancestry"))
                   (:td (:tt (views:esc (ancestry-command-of check)))))
              (:tr (:td (views:esc "Cherry"))
                   (:td (:tt (views:esc (cherry-command-of check)))))
              (:tr (:td (views:esc "Graph/history"))
                   (:td (:tt (views:esc (history-command-of check)))))
              (:tr (:td (views:esc "Range-diff"))
                   (:td (:tt (views:esc (range-diff-command-of check))))))
      (:h4 "Key outputs")
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Ancestry exit code"))
                   (:td (:tt (views:esc
                              (format nil "~D"
                                      (ancestry-exit-code-of check))))))
              (:tr (:td (views:esc "Readable decision"))
                   (:td (views:esc (status-summary-of check)))))
      (:h4 "Cherry output")
      (render-proof-preformatted-lines (cherry-output-of check))
      (:h4 "Interpretation")
      (:p (views:esc (merge-intent-interpretation-of check))))))

(views:defview 👀graph-history (check git-commit-equivalence-check)
  (views:html-view :title "Graph/History" :priority 3
    (views:html
      (:p "This view keeps the readable left/right history comparison and the cherry output together, so the operator can see what remains unique to the source branch after replay.")
      (:h4 "Left/right history")
      (render-proof-preformatted-lines (left-right-history-of check))
      (:h4 "Cherry output")
      (render-proof-preformatted-lines (cherry-output-of check)))))

(views:defview 👀range-diff (check git-commit-equivalence-check)
  (views:html-view :title "Range-diff" :priority 4
    (views:html
      (:p "Use an explicit shared base for this proof. That keeps the replay-equivalence claim stable even after remote refs move.")
      (render-proof-preformatted-lines (range-diff-summary-of check))
      (:p (views:esc (merge-intent-interpretation-of check))))))

(views:defview 👀merge-intent-interpretation (check git-commit-equivalence-check)
  (views:html-view :title "Merge intent interpretation" :priority 5
    (views:html
      (:p (views:esc (merge-intent-interpretation-of check)))
      (:ul
       (:li "Original commit identity is preserved on the source branch.")
       (:li "Patch/content equivalence is proven separately from ancestry.")
       (:li "The replayed equivalent hash on the target branch is made explicit when it can be resolved.")))))

(views:defview 👀summary (surface git-commit-equivalence-surface)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of surface)))
      (:p (views:esc (summary-of surface)))
      (:h4 "Checks")
      (:ul
       (loop for check in (checks-of surface)
             do (views:html
                  (:li (views:object-ref check)))))
      (:h4 "Notes")
      (:ul
       (loop for note in (notes-of surface)
             do (views:html
                  (:li (views:esc note))))))))

(views:defview 👀comparison (surface git-commit-equivalence-surface)
  (views:html-view :title "Comparison" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Check"))
                   (:th (views:esc "Source"))
                   (:th (views:esc "Target"))
                   (:th (views:esc "Ancestry"))
                   (:th (views:esc "Patch equivalence"))
                   (:th (views:esc "Replayed commit")))
              (loop for check in (checks-of surface)
                    do (views:html
                         (:tr
                          (:td (views:object-ref check))
                          (:td (:tt (views:esc
                                     (short-git-commit-hash
                                      (commit-hash-of (source-commit-of check))))))
                          (:td (:tt (views:esc (target-branch-of check))))
                          (:td (:tt (views:esc
                                     (yes-no-label (ancestry-present-p check)))))
                          (:td (:tt (views:esc
                                     (yes-no-label (patch-equivalent-p check)))))
                          (:td (render-commit-reference-or-placeholder
                                (replayed-equivalent-commit-of check)))))))
      (:p "A commit can stay outside target ancestry as an original hash while still being integrated as replayed content on the target branch."))))

(views:defview 👀worked-example (surface git-commit-equivalence-surface)
  (views:html-view :title "Worked example" :priority 3
    (let ((check (first (checks-of surface))))
      (views:html
        (:p "This surface includes the real static-route-observability replay proof from the merge-intent workflow, pinned to the preserved pre-merge hauptsache target branch.")
        (when check
          (views:html
            (:ul
             (:li "Original/source commit: "
                  (:tt (views:esc
                        (commit-hash-of (source-commit-of check)))))
             (:li "Preserved source branch: "
                  (:tt (views:esc (source-branch-of check))))
             (:li "Target branch: "
                  (:tt (views:esc (target-branch-of check))))
             (:li "Shared base: "
                  (:tt (views:esc
                        (commit-hash-of (shared-base-of check)))))
             (:li "Replayed equivalent commit: "
                  (render-commit-reference-or-placeholder
                   (replayed-equivalent-commit-of check)))
             (:li "Interpretation: "
                  (views:esc
                   (merge-intent-interpretation-of check))))))))))
