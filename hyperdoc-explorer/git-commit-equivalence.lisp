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

(defun render-string-list-or-placeholder (items &key (placeholder "None recorded."))
  (if items
      (views:html
       (:ul
        (loop for item in items
              do (views:html
                  (:li (:tt (views:esc item)))))))
      (views:html
       (:p (views:esc placeholder)))))

(defun render-assimilation-page-evidence (page-evidence)
  (let ((status (getf page-evidence :status :unavailable))
        (page-id (getf page-evidence :page-id)))
    (views:html
     (:li
      (:tt (views:esc page-id))
      ": "
      (:tt (views:esc (corpus-evidence-status-label status)))
      (case status
        (:resolved
         (views:html
          " ("
          (views:object-ref (getf page-evidence :page))
          ")"))
        (:lookup-issue
         (views:html
          " ("
          (views:object-ref (getf page-evidence :issue))
          ")"))
        (otherwise
         (views:html
          " ("
          (views:esc
           (or (getf page-evidence :reason)
               (when-let (condition (getf page-evidence :condition))
                 (princ-to-string condition))
               "No corpus lookup path available."))
          ")")))))))

(defun render-unavailable-table-cell (&optional (text "n/a"))
  (views:html
   (:tt :style "opacity: 0.65;" (views:esc text))))

(defun render-upstream-assimilation-comparison-row (check)
  (typecase check
    (git-upstream-commit-assimilation-check
     (views:html
      (:tr
       (:td (views:object-ref check))
       (:td (:tt (views:esc
                  (short-git-commit-hash
                   (commit-hash-of (source-commit-of check))))))
       (:td (:tt (views:esc (target-branch-of check))))
       (:td (:tt (views:esc
                  (upstream-commit-assimilation-decision-label
                   (final-decision-of check)))))
       (:td (:tt (views:esc
                  (yes-no-label (ancestry-present-p check)))))
       (:td (:tt (views:esc
                  (yes-no-label (patch-equivalent-p check)))))
       (:td (:tt (views:esc
                  (semantic-effect-status-label
                   (semantic-effect-status-of check)))))
       (:td (:tt (views:esc
                  (validation-status-label
                   (validation-status-of check))))))))
    (git-runtime-unavailable
     (views:html
      (:tr
       (:td (views:object-ref check))
       (:td (render-unavailable-table-cell "unavailable"))
       (:td (render-unavailable-table-cell "n/a"))
       (:td (render-unavailable-table-cell "unavailable"))
       (:td (render-unavailable-table-cell "n/a"))
       (:td (render-unavailable-table-cell "n/a"))
       (:td (render-unavailable-table-cell "unavailable"))
       (:td (views:object-ref check :display "Runtime issue")))))
    (t
     (views:html
      (:tr
       (:td (views:object-ref check))
       (:td (render-unavailable-table-cell))
       (:td (render-unavailable-table-cell))
       (:td (render-unavailable-table-cell "inconclusive"))
       (:td (render-unavailable-table-cell))
       (:td (render-unavailable-table-cell))
       (:td (render-unavailable-table-cell))
       (:td (render-unavailable-table-cell "unexpected result")))))))

(defun render-upstream-assimilation-worked-example-entry (check)
  (typecase check
    (git-upstream-commit-assimilation-check
     (views:html
      (:li
       (views:object-ref check)
       " — "
       (views:esc (summary-of check))
       (:ul
        (:li "Open summary: "
             (views:object-ref check
                               :display "Summary"
                               :select "Summary"))
        (:li "Open graph/history proof: "
             (views:object-ref check
                               :display "Graph/History proof"
                               :select "Graph/History proof"))
        (:li "Open semantic evidence: "
             (views:object-ref check
                               :display "Semantic evidence"
                               :select "Semantic evidence"))
        (:li "Open validation: "
             (views:object-ref check
                               :display "Validation"
                               :select "Validation"))
        (:li "Open final decision: "
             (views:object-ref check
                               :display "Decision rationale"
                               :select "Decision rationale"))))))
    (git-runtime-unavailable
     (views:html
      (:li
       (views:object-ref check)
       " — "
       (views:esc (summary-of check))
       (:ul
        (:li "Open runtime summary: "
             (views:object-ref check :display "Summary" :select "Summary"))))))
    (t
     (views:html
      (:li
       (views:object-ref check)
       " — unexpected assimilation result type.")))))

(defmethod views:text-representation ((check git-commit-equivalence-check))
  (format nil "~A -> ~A"
          (short-git-commit-hash (commit-hash-of (source-commit-of check)))
          (target-branch-of check)))

(defmethod views:text-representation ((surface git-commit-equivalence-surface))
  (title-of surface))

(defmethod views:text-representation ((check git-upstream-commit-assimilation-check))
  (format nil "~A assimilation -> ~A"
          (short-git-commit-hash (commit-hash-of (source-commit-of check)))
          (target-branch-of check)))

(defmethod views:text-representation ((surface git-upstream-commit-assimilation-surface))
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

(views:defview 👀summary (check git-upstream-commit-assimilation-check)
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
                            (:tr (:td (views:esc "Graph/history proof"))
                                 (:td (views:object-ref (equivalence-check-of check))))
                            (:tr (:td (views:esc "Superseding local commit"))
                                 (:td (render-commit-reference-or-placeholder
                                       (superseding-local-commit-of check))))
                            (:tr (:td (views:esc "Final decision"))
                                 (:td (:tt (views:esc
                                            (upstream-commit-assimilation-decision-label
                                             (final-decision-of check)))))))
                    (:h4 "Interpretation")
                    (:p (views:esc (final-interpretation-of check))))))

(views:defview 👀graph-history-proof (check git-upstream-commit-assimilation-check)
  (views:html-view :title "Graph/History proof" :priority 2
                   (let ((proof (equivalence-check-of check)))
                     (views:html
                      (:p "This view stays deliberately narrow: it shows the reused commit-equivalence proof object without collapsing semantic assimilation into graph/history evidence.")
                      (:table :class "inspector-table"
                              (:tr (:td (views:esc "Proof object"))
                                   (:td (views:object-ref proof)))
                              (:tr (:td (views:esc "Ancestry present?"))
                                   (:td (:tt (views:esc
                                              (yes-no-label (ancestry-present-p check))))))
                              (:tr (:td (views:esc "Patch equivalent?"))
                                   (:td (:tt (views:esc
                                              (yes-no-label (patch-equivalent-p check))))))
                              (:tr (:td (views:esc "Replayed equivalent commit"))
                                   (:td (render-commit-reference-or-placeholder
                                         (replayed-equivalent-commit-of check)))))
                      (:h4 "Open the underlying proof")
                      (:ul
                       (:li (views:object-ref proof :display "Summary" :select "Summary"))
                       (:li (views:object-ref proof :display "Proof" :select "Proof"))
                       (:li (views:object-ref proof :display "Graph/History" :select "Graph/History"))
                       (:li (views:object-ref proof :display "Range-diff" :select "Range-diff")))))))

(views:defview 👀payload-scope (check git-upstream-commit-assimilation-check)
  (views:html-view :title "Payload scope" :priority 3
                   (views:html
                    (:p "This view makes the exact upstream payload scope explicit before semantic interpretation. It remains a source-commit scope report, not a semantic proof by itself.")
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Payload command"))
                                 (:td (:tt (views:esc (payload-command-of check)))))
                            (:tr (:td (views:esc "Path count"))
                                 (:td (:tt (views:esc
                                            (format nil "~D"
                                                    (length (payload-paths-of check))))))))
                    (:h4 "Touched paths")
                    (render-string-list-or-placeholder
                     (payload-paths-of check)
                     :placeholder "No payload paths recorded."))))

(views:defview 👀semantic-evidence (check git-upstream-commit-assimilation-check)
  (views:html-view :title "Semantic evidence" :priority 4
                   (views:html
                    (:p "This view is the higher-layer semantic evidence. It cites constructor, corpus, and runtime-shape compatibility without claiming that graph/history proof alone settles assimilation.")
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Corpus evidence"))
                                 (:td (:tt (views:esc
                                            (corpus-evidence-status-label
                                             (corpus-evidence-status-of check))))))
                            (:tr (:td (views:esc "Semantic evidence"))
                                 (:td (:tt (views:esc
                                            (semantic-evidence-availability-label
                                             (semantic-evidence-availability-of check))))))
                            (:tr (:td (views:esc "Semantic effect"))
                                 (:td (:tt (views:esc
                                            (semantic-effect-status-label
                                             (semantic-effect-status-of check))))))
                            (:tr (:td (views:esc "Semantic compatibility"))
                                 (:td (:tt (views:esc
                                            (semantic-compatibility-status-label
                                             (semantic-compatibility-status-of check))))))
                            (:tr (:td (views:esc "Superseding local commit"))
                                 (:td (render-commit-reference-or-placeholder
                                       (superseding-local-commit-of check)))))
                    (:h4 "Corpus pages")
                    (if (corpus-page-evidence-of check)
                        (views:html
                         (:ul
                          (loop for page-evidence in (corpus-page-evidence-of check)
                                do (render-assimilation-page-evidence page-evidence))))
                        (views:html
                         (:p "No corpus page evidence recorded.")))
                    (:h4 "Summary")
                    (:p (views:esc (semantic-compatibility-summary-of check)))
                    (:h4 "Notes")
                    (render-string-list-or-placeholder
                     (semantic-compatibility-notes-of check)
                     :placeholder "No semantic notes recorded."))))

(views:defview 👀validation (check git-upstream-commit-assimilation-check)
  (views:html-view :title "Validation" :priority 5
                   (views:html
                    (:p "Focused validation is kept separate from both the graph/history proof and the semantic notes, so the operator can see exactly what narrow runtime check backed the final classification.")
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Validation status"))
                                 (:td (:tt (views:esc
                                            (validation-status-label
                                             (validation-status-of check)))))))
                    (:h4 "Summary")
                    (:p (views:esc (validation-summary-of check)))
                    (:h4 "Notes")
                    (render-string-list-or-placeholder
                     (validation-notes-of check)
                     :placeholder "No validation notes recorded."))))

(views:defview 👀decision-rationale (check git-upstream-commit-assimilation-check)
  (views:html-view :title "Decision rationale" :priority 6
                   (views:html
                    (:p "This final decision is intentionally downstream of the other views. Read graph/history proof, payload scope, semantic evidence, and focused validation separately before using the classification.")
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Final decision"))
                                 (:td (:tt (views:esc
                                            (upstream-commit-assimilation-decision-label
                                             (final-decision-of check)))))))
                    (:h4 "Readable interpretation")
                    (:p (views:esc (final-interpretation-of check))))))

(views:defview 👀summary (surface git-upstream-commit-assimilation-surface)
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

(views:defview 👀comparison (surface git-upstream-commit-assimilation-surface)
  (views:html-view :title "Comparison" :priority 2
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th (views:esc "Check"))
                                 (:th (views:esc "Source"))
                                 (:th (views:esc "Target"))
                                 (:th (views:esc "Decision"))
                                 (:th (views:esc "Ancestry"))
                                 (:th (views:esc "Patch equivalence"))
                                 (:th (views:esc "Semantic effect"))
                                 (:th (views:esc "Validation")))
                            (loop for check in (checks-of surface)
                                  do (render-upstream-assimilation-comparison-row check)))
                    (:p "This surface keeps the higher-layer classification visibly downstream of the reused graph/history proof."))))

(views:defview 👀worked-example (surface git-upstream-commit-assimilation-surface)
  (views:html-view :title "Worked example" :priority 3
                   (views:html
                    (:p "This surface keeps named worked examples at the higher assimilation layer. Each one reuses the graph/history proof object underneath, but the operator can still inspect semantic evidence and focused validation separately before trusting the final decision.")
                    (:ul
                     (loop for check in (checks-of surface)
                           do (render-upstream-assimilation-worked-example-entry check))))))
