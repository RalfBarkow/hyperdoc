(in-package #:dreyeck/shop3)

(defmethod print-object ((result hyperdoc-htn-plan-result) stream)
  (print-unreadable-object (result stream :type t)
    (format stream "~S ~D plan~:P mode ~S" (problem-name-of result)
            (length (plans-of result)) (execution-mode-of result))))

(defun render-plan-term (term)
  "Keep the original Lisp value behind its readable label."
  (let ((*print-length* nil)
        (*print-level* nil)
        (*print-pretty* nil)
        (*package* (if (and (symbolp term) (symbol-package term))
                       (symbol-package term)
                       *package*)))
    (html-inspector-views:object-ref term :display (prin1-to-string term))))

(defun render-plan-task (task)
  "Expose the operator/predicate and each argument separately."
  (html-inspector-views:html
    (:code
     (html-inspector-views:esc "(")
     (render-plan-term (first task))
     (dolist (argument (rest task))
       (html-inspector-views:html
         (html-inspector-views:esc " ")
         (render-plan-term argument)))
     (html-inspector-views:esc ")"))))

(defun render-plan-facts (facts)
  (if facts
      (html-inspector-views:html
        (:ul (dolist (fact facts)
               (html-inspector-views:html (:li (render-plan-task fact))))))
      (html-inspector-views:html (:p "None."))))

(defun visible-plan-steps-by-position (raw-plan)
  "Map each native tree position to its visible step number and task."
  (let ((number 0))
    (coerce (loop for (task cost) on raw-plan by #'cddr
                  collect (unless (shop3:internal-operator-p (first task))
                            (cons (incf number) task)))
            'vector)))

(defun render-plan-tree-node (node visible-steps)
  ;; Native FIND-PLANS trees are forests of SHOP3 list-backed nodes, distinct
  ;; from PLAN-TREE's CLOS representation. Never destructure their storage.
  (cond
    ((shop3:primitive-node-p node)
     (let* ((position (shop3:primitive-node-position node))
            (task (shop3:primitive-node-task node))
            (step (when (< -1 position (length visible-steps))
                    (aref visible-steps position))))
       (unless (shop3:internal-operator-p (first task))
         (html-inspector-views:html
           (:li :class "plan-leaf"
            (if (and step (equal task (cdr step)))
                (html-inspector-views:html
                  (:span :class "plan-step-number"
                         (html-inspector-views:esc
                          (format nil "Step ~D: " (car step)))))
                (html-inspector-views:html
                  (:span "Step number unavailable: ")))
            (render-plan-task task))))))
    ((and node (shop3:complex-node-p node))
     (html-inspector-views:html
       (:li
        (:details :open t
         (:summary
          (render-plan-task (shop3:complex-node-task node))
          " — Method: "
          (render-plan-term (shop3:complex-node-reduction-label node)))
         (:ul (dolist (child (shop3:complex-node-children node))
                (render-plan-tree-node child visible-steps)))))))
    (t
     (html-inspector-views:html
       (:li "Task decomposition unavailable for this representation. "
            (render-plan-term node))))))

(defun render-plan-state-changes (result index)
  (let* ((state (nth index (final-states-of result)))
         (final-facts (when state (shop3:state-atoms state)))
         (initial-facts (initial-facts-of result))
         (diff-available (and state (not (eq initial-facts :unavailable)))))
    (html-inspector-views:html
      (:h3 "Modeled State Changes")
      (:p "These are modeled facts, not evidence of real execution.")
      (unless diff-available
        (html-inspector-views:html
          (:p "Difference unavailable: initial facts or final state were not recorded.")))
      (:h4 "Added Facts")
      (if diff-available
          (render-plan-facts (set-difference final-facts initial-facts :test #'equal))
          (html-inspector-views:html (:p "Unavailable.")))
      (:h4 "Removed Facts")
      (if diff-available
          (render-plan-facts (set-difference initial-facts final-facts :test #'equal))
          (html-inspector-views:html (:p "Unavailable.")))
      (:details
       (:summary "Modeled Final State")
       (if state
           (progn
             (html-inspector-views:html
               (:p (html-inspector-views:object-ref state
                      :display "Inspect final state")))
             (render-plan-facts final-facts))
           (html-inspector-views:html (:p "Final state unavailable.")))))))

(html-inspector-views:defview read-the-plan-view (result hyperdoc-htn-plan-result)
  (html-inspector-views:html-view :title "Read the Plan" :priority 1
    (html-inspector-views:html
      (:div :class "read-the-plan" :lang "en"
            :style "line-height: 1.5; white-space: normal; overflow-wrap: anywhere;"
       (:h2 "Read the Plan")
       (:p "Problem: " (render-plan-term (problem-name-of result)))
       (:p "Execution mode: " (render-plan-term (execution-mode-of result)))
       (if (null (raw-plans-of result))
           (html-inspector-views:html (:p "No plan found."))
           (loop for plan in (plans-of result)
                 for raw-plan in (raw-plans-of result)
                 for visible-steps = (visible-plan-steps-by-position raw-plan)
                 for index from 0
                 for tree = (nth index (plan-trees-of result))
                 do
                    (html-inspector-views:html
                      (:section :class "plan-alternative"
                       (:h2 (html-inspector-views:esc
                             (format nil "Alternative ~D" (1+ index))))
                       (:h3 "Steps")
                       (if plan
                           (html-inspector-views:html
                             (:ol (dolist (step plan)
                                    (html-inspector-views:html
                                      (:li (render-plan-task step))))))
                           (html-inspector-views:html
                             (:p "Plan found with no primitive steps.")))
                       (:h3 "Task Decomposition")
                       (cond
                         ((null tree)
                          (html-inspector-views:html
                            (:p "Task decomposition unavailable.")))
                         ((listp tree)
                          (html-inspector-views:html
                            (:ul (dolist (node tree)
                                   (render-plan-tree-node node visible-steps)))))
                         (t
                          (html-inspector-views:html
                            (:p "Task decomposition unavailable for this representation. "
                                (render-plan-term tree)))))
                       (render-plan-state-changes result index)))))))))
