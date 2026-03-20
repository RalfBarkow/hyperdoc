;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defun maybe-object-ref (value &key (fallback-empty ""))
  (cond
    ((null value)
     (views:html (views:esc fallback-empty)))
    ((or (stringp value)
         (pathnamep value)
         (keywordp value)
         (numberp value))
     (views:html (:tt (views:esc (format nil "~A" value)))))
    (t
     (views:object-ref value))))

(defun raw-structure-value (object)
  (handler-case
      (raw-structure object)
    (error ()
      (ignore-errors (raw-structure-of object)))))

(defun section-step-ids (section)
  (mapcar #'id-of (steps-of section)))

(defun section-next-step-target (value)
  (typecase value
    (string
     (or (ignore-errors (official-rpi-tutorial-step value))
         value))
    (t
     value)))

(defun required-zstd-handoff-ids-present-p (ids)
  (every #'(lambda (id) (member id ids :test #'equal))
         '("official-download-prebuilt-image"
           "official-decompress-zstd-to-img"
           "official-flash-sd-card")))

(defun evaluate-invariant (name thunk)
  (handler-case
      (list :name name
            :status :pass
            :result (funcall thunk))
    (error (c)
      (list :name name
            :status :fail
            :result c))))

(defun section-invariant-rows (section)
  (let ((ids (section-step-ids section)))
    (if (required-zstd-handoff-ids-present-p ids)
        (list
         (evaluate-invariant
          "zstd-to-img handoff (download -> decompress)"
          #'(lambda ()
              (assert-step-handoff ids
                                   :step-id "official-decompress-zstd-to-img"
                                   :required-predecessor "official-download-prebuilt-image"
                                   :forbidden-predecessor "official-flash-sd-card")))
         (evaluate-invariant
          "flash predecessor (decompress -> flash; not download -> flash)"
          #'(lambda ()
              (list :required (assert-immediate-predecessor
                               ids
                               "official-flash-sd-card"
                               "official-decompress-zstd-to-img")
                    :forbidden (assert-not-immediate-predecessor
                                ids
                                "official-flash-sd-card"
                                "official-download-prebuilt-image"))))
         (evaluate-invariant
          "download -> decompress -> flash chain"
          #'(lambda ()
              (assert-step-chain
               ids
               "official-download-prebuilt-image"
               "official-decompress-zstd-to-img"
               "official-flash-sd-card")))
         (evaluate-invariant
          "successor checks (download->decompress, decompress->flash, download !-> flash)"
          #'(lambda ()
              (list :download-to-decompress (assert-immediate-successor
                                             ids
                                             "official-download-prebuilt-image"
                                             "official-decompress-zstd-to-img")
                    :decompress-to-flash (assert-immediate-successor
                                          ids
                                          "official-decompress-zstd-to-img"
                                          "official-flash-sd-card")
                    :download-not-flash (assert-not-immediate-successor
                                         ids
                                         "official-download-prebuilt-image"
                                         "official-flash-sd-card")))))
        (list (list :name "zstd-to-img handoff invariants"
                    :status :skip
                    :result (list :reason "section does not contain the official zstd->img->flash chain"
                                  :ids ids))))))

(defun runbook-invariant-rows (runbook)
  (loop for section in (sections-of runbook)
        append (loop for row in (section-invariant-rows section)
                     collect (list :section (id-of section)
                                   :name (getf row :name)
                                   :status (getf row :status)
                                   :result (getf row :result)))))

(defun invariant-status-label (status)
  (ecase status
    (:pass "pass")
    (:fail "fail")
    (:skip "skip")))

(defun patch-anchor-context (patch)
  (let ((defect (and patch (defect-of patch))))
    (list :defect defect
          :upstream (and defect (from-step-of defect))
          :downstream (and defect (to-step-of defect))
          :inserted (and patch (inserted-step-of patch)))))

(defun step-patch-role-label (step patch)
  (let* ((context (patch-anchor-context patch))
         (upstream (getf context :upstream))
         (downstream (getf context :downstream))
         (inserted (getf context :inserted)))
    (cond
      ((eq step upstream) "upstream anchor")
      ((eq step downstream) "downstream anchor")
      ((eq step inserted) "inserted step")
      (t "related step"))))

(defmethod views:text-representation ((runbook sd-card-runbook))
  (format nil "Runbook: ~A" (title-of runbook)))

(defmethod views:text-representation ((section sd-card-runbook-section))
  (title-of section))

(defmethod views:text-representation ((step sd-card-procedure-step))
  (title-of step))

(defmethod views:text-representation ((transcript sd-card-dry-run-transcript))
  (title-of transcript))

(defmethod views:text-representation ((defect sd-card-step-handoff-defect))
  (title-of defect))

(defmethod views:text-representation ((patch sd-card-step-handoff-patch-target))
  (title-of patch))

(views:defview 👀summary (runbook sd-card-runbook)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of runbook)))
      (:p (views:esc (summary-of runbook)))
      (:h4 "Sections")
      (:ol
       (loop for section in (sections-of runbook)
             do (views:html
                  (:li
                   (:b (views:object-ref section))
                   (when (summary-of section)
                     (views:html
                       (:div :style "font-size: 0.92em; opacity: 0.85;"
                             (views:esc (summary-of section))))))))))))

(views:defview 👀items (runbook sd-card-runbook)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:ul
       (loop for section in (sections-of runbook)
             do (views:html
                  (:li (views:object-ref section))))))))

(views:defview 👀raw-structure (runbook sd-card-runbook)
  (views:html-view :title "Raw Structure" :priority 90
    (views:html (:pre (views:esc (format nil "~S" (raw-structure-value runbook)))))))

(views:defview 👀invariants (runbook sd-card-runbook)
  (views:html-view :title "Invariants" :priority 20
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "section"))
                   (:th (views:esc "check"))
                   (:th (views:esc "status"))
                   (:th (views:esc "result")))
              (loop for row in (runbook-invariant-rows runbook)
                    do (views:html
                         (:tr (:td (:tt (views:esc (getf row :section))))
                              (:td (views:esc (getf row :name)))
                              (:td (:tt (views:esc (invariant-status-label (getf row :status)))))
                              (:td (views:object-ref (getf row :result))))))))))

(views:defview 👀summary (section sd-card-runbook-section)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of section)))
      (when (summary-of section)
        (views:html (:p (views:esc (summary-of section)))))
      (:h4 "Procedure steps")
      (:ol
       (loop for step in (steps-of section)
             do (views:html
                  (:li (views:object-ref step)))))
      (when (next-steps-of section)
        (views:html
          (:h4 "Next steps")
          (when (continuation-note-of section)
            (views:html (:p (views:esc (continuation-note-of section)))))
          (:ol
           (loop for target in (next-steps-of section)
                 do (views:html
                      (:li (maybe-object-ref (section-next-step-target target)))))))))))

(views:defview 👀items (section sd-card-runbook-section)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:h4 "Procedure steps")
      (:ul
       (loop for step in (steps-of section)
             do (views:html
                  (:li (views:object-ref step)))))
      (when (next-steps-of section)
        (views:html
          (:h4 "Next steps")
          (:ul
           (loop for target in (next-steps-of section)
                 do (views:html
                      (:li (maybe-object-ref (section-next-step-target target)))))))))))

(views:defview 👀raw-structure (section sd-card-runbook-section)
  (views:html-view :title "Raw Structure" :priority 90
    (views:html (:pre (views:esc (format nil "~S" (raw-structure-value section)))))))

(views:defview 👀invariants (section sd-card-runbook-section)
  (views:html-view :title "Invariants" :priority 20
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "check"))
                   (:th (views:esc "status"))
                   (:th (views:esc "result")))
              (loop for row in (section-invariant-rows section)
                    do (views:html
                         (:tr (:td (views:esc (getf row :name)))
                              (:td (:tt (views:esc (invariant-status-label (getf row :status)))))
                              (:td (views:object-ref (getf row :result))))))))))

(views:defview 👀summary (step sd-card-procedure-step)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of step)))
      (:p (views:esc (summary-of step)))
      (when (failure-capsule-of step)
        (views:html
          (:h4 "Failure capsule")
          (maybe-object-ref (failure-capsule-of step)))))))

(views:defview 👀diagnosis (step sd-card-procedure-step)
  (views:html-view :title "Diagnosis" :priority 2
    (views:html
      (if (diagnosis-of step)
          (views:html (:pre :style "white-space: pre-wrap"
                            (views:esc (diagnosis-of step))))
          (views:html (:p "No diagnosis details for this step."))))))

(views:defview 👀source (step sd-card-procedure-step)
  (views:html-view :title "Source" :priority 3
    (views:html
      (if (source-target-of step)
          (views:html (maybe-object-ref (source-target-of step)))
          (views:html (:p "No explicit source target for this step."))))))

(views:defview 👀edit (step sd-card-procedure-step)
  (views:html-view :title "Edit / Patch Target" :priority 4
    (views:html
      (if (patch-target-of step)
          (let* ((patch (patch-target-of step))
                 (context (patch-anchor-context patch)))
            (views:html
              (:p "Current patch-target context for this workflow gap.")
              (:table :class "inspector-table"
                      (:tr (:th "Current step role")
                           (:td (:tt (views:esc (step-patch-role-label step patch)))))
                      (:tr (:th "Upstream anchor")
                           (:td (maybe-object-ref (getf context :upstream))))
                      (:tr (:th "Downstream anchor")
                           (:td (maybe-object-ref (getf context :downstream))))
                      (:tr (:th "Intended inserted step")
                           (:td (maybe-object-ref (getf context :inserted))))
                      (:tr (:th "Missing-step defect")
                           (:td (maybe-object-ref (getf context :defect))))
                      (:tr (:th "Resulting patch target")
                           (:td (maybe-object-ref patch))))))
          (views:html (:p "No patch target for this step."))))))

(views:defview 👀verification (step sd-card-procedure-step)
  (views:html-view :title "Verification" :priority 5
    (views:html
      (if (verification-of step)
          (views:html
            (maybe-object-ref (verification-of step))
            (when (commands-of step)
              (views:html
                (:h4 "Verification commands")
                (:ul
                 (loop for command in (commands-of step)
                       do (views:html (:li (:tt (views:esc command)))))))))
          (views:html (:p "No verification notes for this step."))))))

(views:defview 👀merge (step sd-card-procedure-step)
  (views:html-view :title "Merge / Upstreaming Notes" :priority 6
    (views:html
      (if (merge-notes-of step)
          (views:html (:pre :style "white-space: pre-wrap"
                            (views:esc (merge-notes-of step))))
          (views:html (:p "No merge/upstreaming notes for this step."))))))

(views:defview 👀items (step sd-card-procedure-step)
  (views:html-view :title "Items" :priority 10
    (views:html
      (when (commands-of step)
        (views:html
          (:h4 "Commands")
          (:ul
           (loop for command in (commands-of step)
                 do (views:html (:li (:tt (views:esc command))))))))
      (when (failure-capsule-of step)
        (views:html
          (:h4 "Failure object")
          (maybe-object-ref (failure-capsule-of step))))
      (when (source-target-of step)
        (views:html
          (:h4 "Source target")
          (maybe-object-ref (source-target-of step))))
      (when (patch-target-of step)
        (views:html
          (:h4 "Patch target")
          (maybe-object-ref (patch-target-of step))))
      (when (verification-of step)
        (views:html
          (:h4 "Verification object")
          (maybe-object-ref (verification-of step)))))))

(views:defview 👀raw-structure (step sd-card-procedure-step)
  (views:html-view :title "Raw Structure" :priority 90
    (views:html (:pre (views:esc (format nil "~S" (raw-structure-value step)))))))

(views:defview 👀summary (transcript sd-card-dry-run-transcript)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of transcript)))
      (:pre :style "white-space: pre-wrap"
            (views:esc (transcript-of transcript))))))

(views:defview 👀items (transcript sd-card-dry-run-transcript)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:h4 "Runbook object")
      (views:object-ref (runbook-of transcript)))))

(views:defview 👀raw-structure (transcript sd-card-dry-run-transcript)
  (views:html-view :title "Raw Structure" :priority 90
    (views:html
      (:pre :style "white-space: pre-wrap"
            (views:esc (format nil "~S" (transcript-of transcript)))))))

(views:defview 👀summary (defect sd-card-step-handoff-defect)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of defect)))
      (:p (views:esc (summary-of defect)))
      (:p (:b "Produced artifact: ") (:tt (views:esc (produced-artifact-of defect))))
      (:p (:b "Required artifact: ") (:tt (views:esc (required-artifact-of defect))))
      (:p (:b "Missing transition: ") (:tt (views:esc (missing-transition-of defect)))))))

(views:defview 👀items (defect sd-card-step-handoff-defect)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:h4 "From step")
      (views:object-ref (from-step-of defect))
      (:h4 "To step")
      (views:object-ref (to-step-of defect)))))

(views:defview 👀summary (patch sd-card-step-handoff-patch-target)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of patch)))
      (:p (views:esc (summary-of patch)))
      (:p (:b "Verification: ") (views:esc (verification-note-of patch))))))

(views:defview 👀items (patch sd-card-step-handoff-patch-target)
  (views:html-view :title "Items" :priority 10
    (let* ((context (patch-anchor-context patch))
           (defect (getf context :defect)))
      (views:html
        (:h4 "Upstream anchor")
        (maybe-object-ref (getf context :upstream))
        (:h4 "Downstream anchor")
        (maybe-object-ref (getf context :downstream))
        (:h4 "Defect")
        (maybe-object-ref defect)
        (:h4 "Inserted step")
        (maybe-object-ref (getf context :inserted))))))
