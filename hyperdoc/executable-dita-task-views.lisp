;;;; Moldable inspector views for Executable DITA task contracts.

(in-package :hyperdoc)

(defun executable-dita-view-string (value)
  (cond
    ((null value) "none")
    ((stringp value) value)
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value) (string-downcase (symbol-name value)))
    ((pathnamep value) (namestring value))
    ((listp value)
     (format nil "~{~A~^, ~}" (mapcar #'executable-dita-view-string value)))
    (t
     (format nil "~A" value))))

(defun executable-dita-view-row (label value)
  (html-inspector-views:html
    (:tr
     (:th :scope "row" (html-inspector-views:esc label))
     (:td (html-inspector-views:esc (executable-dita-view-string value))))))

(defun executable-dita-view-code (value)
  (html-inspector-views:html
    (:pre (html-inspector-views:esc
           (if (stringp value)
               value
               (executable-dita-sexp-string value))))))

(defun executable-dita-view-db-path ()
  (executable-dita-default-sqlite-path))

(defmethod html-inspector-views:text-representation
    ((task executable-dita-task))
  (format nil "~A" (executable-dita-task-title task)))

(defmethod html-inspector-views:text-representation
    ((row executable-dita-sqlite-task-row))
  (format nil "SQLite task row ~A"
          (executable-dita-sqlite-task-row-id row)))

(defmethod html-inspector-views:text-representation
    ((row executable-dita-next-task-candidate-row))
  (format nil "~A score ~,2F"
          (executable-dita-next-task-candidate-row-id row)
          (or (executable-dita-next-task-candidate-row-score row) 0.0d0)))

(defmethod html-inspector-views:text-representation
    ((selection executable-dita-next-task-selection))
  (format nil "Executable DITA next-task selection for ~A"
          (executable-dita-next-task-selection-task-id selection)))

(html-inspector-views:defview 👀summary (task executable-dita-task)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (executable-dita-task-title task)))
      (:p (html-inspector-views:esc (executable-dita-task-summary task)))
      (:table :class "inspector-table"
              (executable-dita-view-row "Task id"
                                        (executable-dita-task-id task))
              (executable-dita-view-row "Context"
                                        (executable-dita-task-context task))
              (executable-dita-view-row "Planning boundary"
                                        "PDDL/SHOP3-shaped fields are inspectable data in this slice.")
              (executable-dita-view-row "Execution boundary"
                                        "Operators are read-only unless an explicit guarded execution path is added.")
              (executable-dita-view-row "SQLite evidence DB"
                                        (executable-dita-view-db-path))))))

(html-inspector-views:defview 👀sexp (task executable-dita-task)
  (html-inspector-views:html-view :title "S-expression" :priority 2
    (executable-dita-view-code
     (executable-dita-task->sexp task))))

(html-inspector-views:defview 👀dita (task executable-dita-task)
  (html-inspector-views:html-view :title "DITA XML" :priority 3
    (executable-dita-view-code
     (executable-dita-task->dita task))))

(html-inspector-views:defview 👀hyperdoc-html (task executable-dita-task)
  (html-inspector-views:html-view :title "HyperDoc HTML" :priority 4
    (executable-dita-view-code
     (executable-dita-task->hyperdoc-html task))))

(html-inspector-views:defview 👀scxml (task executable-dita-task)
  (html-inspector-views:html-view :title "SCXML" :priority 5
    (executable-dita-view-code
     (executable-dita-task->scxml task))))

(html-inspector-views:defview 👀sqlite-row (task executable-dita-task)
  (let ((row (read-executable-dita-task-row
              (executable-dita-task-id task)
              :db-path (executable-dita-view-db-path))))
    (html-inspector-views:html-view :title "SQLite row" :priority 6
      (html-inspector-views:html
        (if row
            (html-inspector-views:object-ref row)
            (html-inspector-views:html
              (:p (html-inspector-views:esc
                   "No persisted SQLite row found for this task."))))))))

(html-inspector-views:defview 👀next-tasks (task executable-dita-task)
  (html-inspector-views:html-view :title "Next tasks" :priority 7
    (html-inspector-views:html
      (html-inspector-views:object-ref
       (make-executable-dita-next-task-selection
        :task-id (executable-dita-task-id task)
        :db-path (executable-dita-view-db-path)
        :include-blocked-p t)))))

(html-inspector-views:defview 👀summary
    (row executable-dita-sqlite-task-row)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (executable-dita-view-row "Task id"
                                        (executable-dita-sqlite-task-row-id row))
              (executable-dita-view-row "Title"
                                        (executable-dita-sqlite-task-row-title row))
              (executable-dita-view-row "Status"
                                        (executable-dita-sqlite-task-row-status row))
              (executable-dita-view-row "Created at"
                                        (executable-dita-sqlite-task-row-created-at
                                         row))
              (executable-dita-view-row "Canonical S-expression bytes"
                                        (executable-dita-sqlite-task-row-sexp-size
                                         row))
              (executable-dita-view-row "DITA XML bytes"
                                        (executable-dita-sqlite-task-row-dita-size
                                         row))
              (executable-dita-view-row "HyperDoc HTML bytes"
                                        (executable-dita-sqlite-task-row-hyperdoc-html-size
                                         row))
              (executable-dita-view-row "SCXML bytes"
                                        (executable-dita-sqlite-task-row-scxml-size
                                         row)))
      (:h4 "Task object")
      (html-inspector-views:object-ref
       (executable-dita-sqlite-task-row-task row)))))

(html-inspector-views:defview 👀summary
    (row executable-dita-next-task-candidate-row)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (executable-dita-view-row "Candidate id"
                                        (executable-dita-next-task-candidate-row-id
                                         row))
              (executable-dita-view-row "Task id"
                                        (executable-dita-next-task-candidate-row-task-id
                                         row))
              (executable-dita-view-row "Cost"
                                        (executable-dita-next-task-candidate-row-cost
                                         row))
              (executable-dita-view-row "Risk"
                                        (executable-dita-next-task-candidate-row-risk
                                         row))
              (executable-dita-view-row "Expected value"
                                        (executable-dita-next-task-candidate-row-expected-value
                                         row))
              (executable-dita-view-row "Score"
                                        (executable-dita-next-task-candidate-row-score
                                         row))
              (executable-dita-view-row "Blocked"
                                        (if (executable-dita-next-task-candidate-row-blocked-p
                                             row)
                                            "yes"
                                            "no"))
              (executable-dita-view-row "Selected"
                                        (if (executable-dita-next-task-candidate-row-selected-p
                                             row)
                                            "yes"
                                            "no")))
      (:h4 "Candidate S-expression")
      (executable-dita-view-code
       (executable-dita-next-task-candidate-row-candidate row)))))

(html-inspector-views:defview 👀ranked-candidates
    (selection executable-dita-next-task-selection)
  (html-inspector-views:html-view :title "Ranked candidates" :priority 1
    (html-inspector-views:html
      (:table :class "inspector-table"
              (:thead
               (:tr
                (:th "Candidate")
                (:th "Cost")
                (:th "Risk")
                (:th "Expected value")
                (:th "Score")
                (:th "Blocked")
                (:th "Selected")))
              (:tbody
               (dolist (candidate
                         (executable-dita-next-task-selection-candidates
                          selection))
                 (html-inspector-views:html
                   (:tr
                    (:td (html-inspector-views:object-ref
                          candidate
                          :display
                          (executable-dita-next-task-candidate-row-id
                           candidate)))
                    (:td (html-inspector-views:esc
                          (executable-dita-view-string
                           (executable-dita-next-task-candidate-row-cost
                            candidate))))
                    (:td (html-inspector-views:esc
                          (executable-dita-view-string
                           (executable-dita-next-task-candidate-row-risk
                            candidate))))
                    (:td (html-inspector-views:esc
                          (executable-dita-view-string
                           (executable-dita-next-task-candidate-row-expected-value
                            candidate))))
                    (:td (html-inspector-views:esc
                          (format nil "~,2F"
                                  (or (executable-dita-next-task-candidate-row-score
                                       candidate)
                                      0.0d0))))
                    (:td (html-inspector-views:esc
                          (if (executable-dita-next-task-candidate-row-blocked-p
                               candidate)
                              "yes"
                              "no")))
                    (:td (html-inspector-views:esc
                          (if (executable-dita-next-task-candidate-row-selected-p
                               candidate)
                              "yes"
                              "no")))))))))))

(html-inspector-views:defview 👀selection
    (selection executable-dita-next-task-selection)
  (html-inspector-views:html-view :title "Selection" :priority 2
    (html-inspector-views:html
      (:table :class "inspector-table"
              (executable-dita-view-row
               "Task id"
               (executable-dita-next-task-selection-task-id selection))
              (executable-dita-view-row
               "Database"
               (executable-dita-next-task-selection-db-path selection))
              (executable-dita-view-row
               "Includes blocked candidates"
               (if (executable-dita-next-task-selection-include-blocked-p
                    selection)
                   "yes"
                   "no")))
      (:h4 "Selected candidate")
      (let ((candidate
              (executable-dita-next-task-selection-selected-candidate
               selection)))
        (if candidate
            (html-inspector-views:object-ref candidate)
            (html-inspector-views:html
              (:p (html-inspector-views:esc
                   "No selected or unblocked candidate is available."))))))))
