;;;; Inspector views for the LISP-CRITIC review integration plan.

(in-package :hyperdoc/inspector)

(defun lisp-critic-review-view-string (value)
  (cond
    ((null value) "none")
    ((typep value 'hyperdoc::hyperdoc-plan)
     (hyperdoc::hyperdoc-plan-title-of value))
    ((typep value 'hyperdoc::hyperdoc-task-topic)
     (hyperdoc::hyperdoc-task-topic-id-of value))
    ((keywordp value)
     (string-downcase (symbol-name value)))
    ((symbolp value)
     (string-downcase (symbol-name value)))
    ((stringp value)
     value)
    ((consp value)
     (format nil "~{~A~^, ~}"
             (mapcar #'lisp-critic-review-view-string value)))
    (t
     (format nil "~A" value))))

(defun lisp-critic-review-row (label value)
  (html-inspector-views:html
    (:tr
     (:th :scope "row" (html-inspector-views:esc label))
     (:td (html-inspector-views:esc
           (lisp-critic-review-view-string value))))))

(defun lisp-critic-review-bullets (values)
  (html-inspector-views:html
    (:ul
     (if values
         (dolist (value values)
           (html-inspector-views:html
             (:li (html-inspector-views:esc
                   (lisp-critic-review-view-string value)))))
         (html-inspector-views:html
           (:li (html-inspector-views:esc "none")))))))

(defun lisp-critic-review-source-station-row (source-station)
  (destructuring-bind (kind &key site page asset-root &allow-other-keys)
      source-station
    (html-inspector-views:html
      (:tr
       (:td (html-inspector-views:esc
             (lisp-critic-review-view-string kind)))
       (:td (html-inspector-views:esc site))
       (:td (html-inspector-views:esc page))
       (:td (:code (html-inspector-views:esc asset-root)))))))

(defun lisp-critic-review-ordered-relations (plan)
  (sort (copy-list (hyperdoc::hyperdoc-plan-task-relations-of plan))
        #'<
        :key #'hyperdoc::hyperdoc-plan-task-relation-ordinal-of))

(defmethod html-inspector-views:text-representation
    ((plan hyperdoc::hyperdoc-plan))
  (hyperdoc::hyperdoc-plan-title-of plan))

(defmethod html-inspector-views:text-representation
    ((task hyperdoc::hyperdoc-task-topic))
  (hyperdoc::hyperdoc-task-topic-title-of task))

(defmethod html-inspector-views:text-representation
    ((relation hyperdoc::hyperdoc-plan-task-relation))
  (hyperdoc::title-of relation))

(html-inspector-views:defview 👀summary
    (plan hyperdoc::hyperdoc-plan)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc
            (hyperdoc::hyperdoc-plan-title-of plan)))
      (:table :class "inspector-table"
              (lisp-critic-review-row
               "Plan id"
               (hyperdoc::hyperdoc-plan-id-of plan))
              (lisp-critic-review-row
               "Goal"
               (hyperdoc::hyperdoc-plan-goal-of plan))
              (lisp-critic-review-row
               "Status"
               (hyperdoc::hyperdoc-plan-status-of plan))
              (lisp-critic-review-row
               "Contracts"
               (hyperdoc::hyperdoc-plan-contracts-of plan)))

      (:h3 (html-inspector-views:esc "Source stations"))
      (:table :class "inspector-table"
              (:thead
               (:tr
                (:th (html-inspector-views:esc "Kind"))
                (:th (html-inspector-views:esc "Site"))
                (:th (html-inspector-views:esc "Page"))
                (:th (html-inspector-views:esc "Asset root"))))
              (:tbody
               (dolist (source-station
                         (hyperdoc::hyperdoc-plan-source-stations-of plan))
                 (lisp-critic-review-source-station-row source-station))))

      (:h3 (html-inspector-views:esc "Ordered task decomposition"))
      (:table :class "inspector-table"
              (:thead
               (:tr
                (:th (html-inspector-views:esc "Order"))
                (:th (html-inspector-views:esc "Task"))
                (:th (html-inspector-views:esc "Relation"))
                (:th (html-inspector-views:esc "Produces"))))
              (:tbody
               (dolist (relation
                         (lisp-critic-review-ordered-relations plan))
                 (let ((task
                         (hyperdoc::hyperdoc-plan-task-relation-task-of
                          relation)))
                   (html-inspector-views:html
                     (:tr
                      (:td (html-inspector-views:esc
                            (princ-to-string
                             (hyperdoc::hyperdoc-plan-task-relation-ordinal-of
                              relation))))
                      (:td (html-inspector-views:object-ref task))
                      (:td (html-inspector-views:esc
                            (lisp-critic-review-view-string
                             (hyperdoc::hyperdoc-plan-task-relation-relation-type-of
                              relation))))
                      (:td (html-inspector-views:esc
                            (lisp-critic-review-view-string
                             (hyperdoc::hyperdoc-plan-task-relation-produces-of
                              relation)))))))))))))

(html-inspector-views:defview 👀goldberg-coverage
    (plan hyperdoc::hyperdoc-plan)
  (html-inspector-views:html-view :title "Goldberg coverage" :priority 2
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc "Goldberg coverage"))
      (:p
       (html-inspector-views:esc
        "Coverage links Goldberg Programmer-as-Reader question ids to the task topics and artifacts that answer them."))
      (:table :class "inspector-table"
              (:thead
               (:tr
                (:th (html-inspector-views:esc "Question id"))
                (:th (html-inspector-views:esc "Task topics"))
                (:th (html-inspector-views:esc "Evidence/artifacts"))))
              (:tbody
               (dolist (entry
                         (hyperdoc::lisp-critic-review-goldberg-coverage
                          plan))
                 (html-inspector-views:html
                   (:tr
                    (:td (html-inspector-views:esc
                          (lisp-critic-review-view-string
                           (getf entry :question-id))))
                    (:td
                     (dolist (task (getf entry :task-topics))
                       (html-inspector-views:html
                         (:div (html-inspector-views:object-ref task)))))
                    (:td (html-inspector-views:esc
                          (lisp-critic-review-view-string
                           (getf entry :evidence-artifacts))))))))))))

(html-inspector-views:defview 👀relations-to-plans
    (task hyperdoc::hyperdoc-task-topic)
  (html-inspector-views:html-view :title "Relations to plans" :priority 1
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc
            (hyperdoc::hyperdoc-task-topic-title-of task)))
      (:p (html-inspector-views:esc
           (hyperdoc::hyperdoc-task-topic-shortdesc-of task)))
      (:table :class "inspector-table"
              (lisp-critic-review-row
               "Task id"
               (hyperdoc::hyperdoc-task-topic-id-of task))
              (lisp-critic-review-row
               "Context"
               (hyperdoc::hyperdoc-task-topic-context-of task))
              (lisp-critic-review-row
               "Prerequisites"
               (hyperdoc::hyperdoc-task-topic-prerequisites-of task))
              (lisp-critic-review-row
               "Steps"
               (hyperdoc::hyperdoc-task-topic-steps-of task))
              (lisp-critic-review-row
               "Expected result"
               (hyperdoc::hyperdoc-task-topic-expected-result-of task))
              (lisp-critic-review-row
               "Evidence"
               (hyperdoc::hyperdoc-task-topic-evidence-of task)))
      (:h3 (html-inspector-views:esc "Relations to plans"))
      (:table :class "inspector-table"
              (:thead
               (:tr
                (:th (html-inspector-views:esc "Plan"))
                (:th (html-inspector-views:esc "Relation type"))
                (:th (html-inspector-views:esc "Order"))
                (:th (html-inspector-views:esc "Dependencies"))
                (:th (html-inspector-views:esc "Produced artifacts"))
                (:th (html-inspector-views:esc "Validated checks"))
                (:th (html-inspector-views:esc "Goldberg questions"))))
              (:tbody
               (dolist (relation
                         (hyperdoc::lisp-critic-review-relations-for-task
                          task))
                 (html-inspector-views:html
                   (:tr
                    (:td
                     (html-inspector-views:object-ref
                      (hyperdoc::hyperdoc-plan-task-relation-plan-of
                       relation)))
                    (:td (html-inspector-views:esc
                          (lisp-critic-review-view-string
                           (hyperdoc::hyperdoc-plan-task-relation-relation-type-of
                            relation))))
                    (:td (html-inspector-views:esc
                          (princ-to-string
                           (hyperdoc::hyperdoc-plan-task-relation-ordinal-of
                            relation))))
                    (:td (html-inspector-views:esc
                          (lisp-critic-review-view-string
                           (hyperdoc::hyperdoc-plan-task-relation-depends-on-of
                            relation))))
                    (:td (html-inspector-views:esc
                          (lisp-critic-review-view-string
                           (hyperdoc::hyperdoc-plan-task-relation-produces-of
                            relation))))
                    (:td (html-inspector-views:esc
                          (lisp-critic-review-view-string
                           (hyperdoc::hyperdoc-plan-task-relation-validates-of
                            relation))))
                    (:td (html-inspector-views:esc
                          (lisp-critic-review-view-string
                           (hyperdoc::hyperdoc-plan-task-relation-answers-of
                            relation))))))))))))
