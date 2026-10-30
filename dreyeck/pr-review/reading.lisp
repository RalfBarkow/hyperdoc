(in-package #:dreyeck/pull-request-review)

(defvar *local-reading* nil)
(defun local-reading ()
  (or *local-reading* (error "Explicitly prepare a local review snapshot first")))
(defun prepare-example-reading ()
  "Explicit local import. Returns Reading and an unregistered HyperBook; no server."
  (setf *local-reading* (example-reading))
  (values *local-reading* (make-reading-book)))
(defun make-reading-book ()
  "Does not register with any Catalog. Admission remains a separate decision."
  (dreyeck/hyperdoc:make-hyperdoc
   :id "dreyeck/pull-request-review/reading" :title "Pull Request Review"
   :asdf-system-name "dreyeck/pull-request-review/reading"
   :subdirectory "dreyeck/pages/pr-review" :code-subdirectory "dreyeck/pr-review"
   :main-page-id "Pull Request Review"))

(defmethod html-inspector-views:text-representation ((object review-reading))
  (format nil "PR Review: ~A, ~D observed PRs" (snapshot-status (reading-snapshot object))
          (length (snapshot-prs (reading-snapshot object)))))
(defmethod html-inspector-views:text-representation ((object pull-request-observation))
  (format nil "PR #~D: ~A" (pr-number object) (pr-title object)))
(defmethod html-inspector-views:text-representation ((object pull-request-review))
  (html-inspector-views:text-representation (review-pr object)))
(defmethod html-inspector-views:text-representation ((object github-commit))
  (format nil "Commit ~A" (subseq (commit-sha object) 0 12)))
(defmethod html-inspector-views:text-representation ((object github-issue))
  (format nil "Issue #~D: ~A" (issue-number object) (issue-title object)))
(defmethod html-inspector-views:text-representation ((object source-mark)) (mark-label object))
(defmethod html-inspector-views:text-representation ((object relationship-claim))
  (format nil "~A: PR #~D → ~D (~A)" (claim-type object) (claim-from object) (claim-to object) (claim-level object)))
(defmethod html-inspector-views:text-representation ((object source-document))
  (format nil "Observed source: ~A" (document-url object)))
(defmethod html-inspector-views:text-representation ((object human-review-note))
  (format nil "Review note by ~A for PR #~D @ ~A" (note-author object) (note-pr object) (note-head object)))

;; These views contain inspect references and escaped data; no action/eval widgets.
(defun render-text (value)
  (html-inspector-views:html (html-inspector-views:esc (princ-to-string value))))
(defun render-link (url label)
  (html-inspector-views:html (:a :href url :target "_blank" :rel "noopener noreferrer"
                                (render-text label))))
(defun render-marks (item kind)
  (dolist (mark (review-marks item))
    (when (and (eq kind (mark-kind mark)) (eq :supported (mark-status (review-snapshot item) mark)))
      (html-inspector-views:html (:p (html-inspector-views:object-ref mark))))))

(html-inspector-views:defview review-table (reading review-reading)
  (html-inspector-views:html-view :title "Pull requests" :priority 0
    (let ((snapshot (reading-snapshot reading)))
      (html-inspector-views:html
        (:p (html-inspector-views:object-ref snapshot :display "Snapshot provenance") " · "
            (render-text (snapshot-age-status snapshot)))
        (:p "Reported verification is not human acceptance. Relations describe source use, not merge order.")
        (if (eq :unavailable (snapshot-status snapshot))
            (html-inspector-views:html (:p "GitHub data unavailable; this is not an empty PR list."))
            (html-inspector-views:html
             (:p (render-text (format nil "~D PRs observed at ~A; no live refresh."
                                                (length (reading-items reading)) (snapshot-observed-at snapshot))))
             (:table :class "inspector-table"
               (:tr (:th "Pull request") (:th "Branch / base") (:th "Observed head")
                    (:th "Draft / state") (:th "Reported evidence") (:th "Reported open decisions"))
               (dolist (item (reading-items reading))
                 (let ((pr (review-pr item)))
                   (html-inspector-views:html
                    (:tr (:td (html-inspector-views:object-ref item))
                         (:td (render-text (format nil "~A → ~A" (pr-head-ref pr) (pr-base-ref pr))))
                         (:td (html-inspector-views:object-ref (pr-head pr)))
                         (:td (render-text (format nil "draft=~A / ~A" (pr-draft pr) (pr-state pr))))
                         (:td (render-marks item :reported-evidence))
                         (:td (render-marks item :reported-question)))))))))))))

(html-inspector-views:defview snapshot-provenance (snapshot review-snapshot)
  (html-inspector-views:html-view :title "Snapshot provenance" :priority 0
    (html-inspector-views:html
      (:p (render-text (snapshot-repository snapshot)))
      (:p (render-text (format nil "Repository id ~A · ~A · ~A" (snapshot-repository-id snapshot)
                                             (snapshot-observed-at snapshot) (snapshot-status snapshot))))
      (:p "Document SHA-256: " (render-text (snapshot-digest snapshot)))
      (:p "Snapshot age status: " (render-text (snapshot-age-status snapshot)))
      (:p "Observation is not a claim of current remote state; capture is non-atomic across requests.")
      (when (snapshot-reason snapshot) (html-inspector-views:html (:p (render-text (snapshot-reason snapshot)))))
      (unless (zerop (length (snapshot-url snapshot))) (render-link (snapshot-url snapshot) "GitHub API source")))))

(html-inspector-views:defview observed-pr (pr pull-request-observation)
  (html-inspector-views:html-view :title "Observed metadata" :priority 0
    (html-inspector-views:html
      (:p (render-text (format nil "PR #~D: ~A" (pr-number pr) (pr-title pr))))
      (:p (render-text (pr-repository pr)))
      (:p "Base: " (html-inspector-views:object-ref (pr-base pr)) " · Head: " (html-inspector-views:object-ref (pr-head pr)))
      (:p (render-text (format nil "~A → ~A · ~A · draft=~A · observed ~A"
                                             (pr-head-ref pr) (pr-base-ref pr) (pr-state pr) (pr-draft pr) (pr-observed-at pr))))
      (:p (html-inspector-views:object-ref (pr-source pr) :display "Observed PR description (inert source text)"))
      (render-link (pr-url pr) "GitHub pull request")
      (:h3 "Observed commits")
      (dolist (commit (pr-commits pr)) (html-inspector-views:html (:p (html-inspector-views:object-ref commit)))))))

(html-inspector-views:defview individual-review (item pull-request-review)
  (html-inspector-views:html-view :title "Review" :priority 0
    (html-inspector-views:html
      (:p (html-inspector-views:object-ref (review-pr item) :display "Observed metadata and commits"))
      (:p (html-inspector-views:object-ref (review-snapshot item) :display "Snapshot provenance"))
      (:h3 "Reported evidence") (render-marks item :reported-evidence)
      (:h3 "Reported open decisions") (render-marks item :reported-question)
      (:h3 "Source relationships (not merge dependencies)")
      (dolist (claim (review-claims item))
        (html-inspector-views:html
          (:p (html-inspector-views:object-ref claim) " · "
              (render-text (claim-status (review-snapshot item) claim))))
        (when (eq :supported (claim-status (review-snapshot item) claim))
          (let ((target (if (eq :separate-investigation (claim-type claim))
                            (find (claim-to claim) (snapshot-issues (review-snapshot item)) :key #'issue-number)
                            (find-pr (review-snapshot item)
                                     (if (= (pr-number (review-pr item)) (claim-from claim))
                                         (claim-to claim) (claim-from claim))))))
            (html-inspector-views:html (:p (html-inspector-views:object-ref target :display "Related source object"))))))
      (:h3 "All source annotations, including quarantined ones")
      (dolist (mark (review-marks item))
        (html-inspector-views:html (:p (html-inspector-views:object-ref mark) " · "
                                     (render-text (mark-status (review-snapshot item) mark)))))
      (:h3 "Separate human notes")
      (dolist (note (review-notes item))
        (html-inspector-views:html (:p (html-inspector-views:object-ref note) " · "
                                     (render-text (note-status (review-snapshot item) note))))))))

(html-inspector-views:defview claim-warrant (claim relationship-claim)
  (html-inspector-views:html-view :title "Warrant" :priority 0
    (html-inspector-views:html
      (:p (render-text (format nil "~A; epistemic status ~A" (claim-type claim) (claim-level claim))))
      (:p "Curated textual warrant. Exact quote/head checks support traceability, not automatic semantic entailment or human acceptance.")
      (:p "Source body SHA-256: " (render-text (claim-body-digest claim)))
      (:pre :style "white-space: pre-wrap;" (render-text (claim-quote claim)))
      (render-link (%web (format nil "pull/~D" (claim-source-pr claim))) "Source PR"))))

(html-inspector-views:defview source-observation (source source-document)
  (html-inspector-views:html-view :title "Observed source" :priority 0
    (html-inspector-views:html
      (:p (render-text (document-observed-at source)))
      (:p (render-text (document-digest source)))
      (:pre :style "white-space: pre-wrap;" (render-text (document-text source)))
      (render-link (document-url source) "GitHub source"))))
(html-inspector-views:defview source-mark-view (mark source-mark)
  (html-inspector-views:html-view :title "Reported evidence or question" :priority 0
    (html-inspector-views:html
      (:p (render-text (mark-label mark)))
      (:p "Observed report text; this Reading did not execute its tests or settle its question.")
      (:p (render-text (mark-head mark)))
      (:p (render-text (mark-body-digest mark)))
      (:pre :style "white-space: pre-wrap;" (render-text (mark-quote mark)))
      (render-link (mark-url mark) "Source document"))))
(html-inspector-views:defview commit-view (commit github-commit)
  (html-inspector-views:html-view :title "Commit" :priority 0
    (html-inspector-views:html
      (:p (render-text (commit-repository commit)))
      (:p (render-text (commit-sha commit)))
      (:pre :style "white-space: pre-wrap;" (render-text (commit-message commit)))
      (render-link (commit-url commit) "GitHub commit"))))
(html-inspector-views:defview issue-view (issue github-issue)
  (html-inspector-views:html-view :title "Issue" :priority 0
    (html-inspector-views:html
      (:p (render-text (issue-title issue)))
      (:p (render-text (issue-state issue)))
      (:p (html-inspector-views:object-ref (issue-source issue)))
      (render-link (issue-url issue) "GitHub issue"))))
(html-inspector-views:defview human-note-view (note human-review-note)
  (html-inspector-views:html-view :title "Human review note" :priority 0
    (html-inspector-views:html
      (:p "Separate reviewer input, not GitHub source data or an Acceptance Record.")
      (:p (render-text (format nil "~A · ~A · PR #~D @ ~A" (note-author note)
                                             (note-recorded-at note) (note-pr note) (note-head note))))
      (:pre :style "white-space: pre-wrap;" (render-text (note-text note))))))
(html-inspector-views:defview reading-warrants (reading review-reading)
  (html-inspector-views:html-view :title "Warrants and notes" :priority 1
    (html-inspector-views:html
      (:p "Separate curated annotation document SHA-256: "
          (render-text (reading-annotation-digest reading)))
      (dolist (claim (reading-claims reading))
        (html-inspector-views:html (:p (html-inspector-views:object-ref claim) " · "
                                     (render-text (claim-status (reading-snapshot reading) claim)))))
      (dolist (note (reading-notes reading))
        (html-inspector-views:html (:p (html-inspector-views:object-ref note) " · "
                                     (render-text (note-status (reading-snapshot reading) note))))))))
