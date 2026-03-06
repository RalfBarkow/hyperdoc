;;;; Examples
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Add a play button before a top-level defexample form.
;;

(defmethod html-inspector-views/standard:render-toplevel-cst :around
    ((head (eql 'defexample)) cst source position)
  (views:eval-button "►"
                     (views:thunk
                       (-> cst cst:second cst:raw symbol-function funcall))
                     "Run example")
  (call-next-method))

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

(defmethod views:text-representation ((runbook sd-card-runbook))
  (format nil "Runbook: ~A" (title-of runbook)))

(defmethod views:text-representation ((section sd-card-runbook-section))
  (format nil "Section: ~A" (title-of section)))

(defmethod views:text-representation ((step sd-card-procedure-step))
  (format nil "Step: ~A" (title-of step)))

;; Keep link labels clean inside Summary lists while preserving explicit
;; pane titles from text-representation.
(defmethod views:html-representation ((section sd-card-runbook-section) &optional id)
  (declare (ignore id))
  (views:html (:span (views:esc (title-of section)))))

(defmethod views:html-representation ((step sd-card-procedure-step) &optional id)
  (declare (ignore id))
  (views:html (:span (views:esc (title-of step)))))

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
    (views:html (:pre (views:esc (format nil "~S" (raw-structure-of runbook)))))))

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
                  (:li (views:object-ref step))))))))

(views:defview 👀items (section sd-card-runbook-section)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:ul
       (loop for step in (steps-of section)
             do (views:html
                  (:li (views:object-ref step))))))))

(views:defview 👀raw-structure (section sd-card-runbook-section)
  (views:html-view :title "Raw Structure" :priority 90
    (views:html (:pre (views:esc (format nil "~S" (raw-structure-of section)))))))

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
          (views:html (maybe-object-ref (patch-target-of step)))
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
    (views:html (:pre (views:esc (format nil "~S" (raw-structure-of step)))))))
