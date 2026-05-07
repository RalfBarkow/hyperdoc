;;;; Inspector views for FedWiki materialization plans
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/inspector)

(defun materialization-entry-row (entry)
  (list (hyperdoc::fedwiki-materialization-entry-action-of entry)
        (hyperdoc::fedwiki-materialization-entry-slug-of entry)
        (hyperdoc::fedwiki-materialization-entry-title-of entry)
        (hyperdoc::fedwiki-materialization-entry-source-kind-of entry)
        (namestring (hyperdoc::fedwiki-materialization-entry-target-path-of entry))))

(defmethod views:text-representation ((plan hyperdoc::fedwiki-materialization-plan))
  (let ((summary (hyperdoc::fedwiki-materialization-plan-summary plan)))
    (format nil "FedWiki materialization ~A ~A (~D create, ~D append, ~D present)"
            (string-downcase (symbol-name (hyperdoc::fedwiki-materialization-mode-of plan)))
            (hyperdoc::fedwiki-materialization-selector-of plan)
            (getf summary :creates)
            (getf summary :appends)
            (getf summary :already-present))))

(defmethod views:title-bar-action-buttons ((plan hyperdoc::fedwiki-materialization-plan))
  (views:html
   (views:action-button
    "Materialize"
    (views:thunk
     (hyperdoc:materialize-fedwiki-materialization-plan plan)
     plan)
    "Write only the planned FedWiki page files into the live pages repo after branch checks and JSON/journal validation.")))

(views:defview 👀overview (plan hyperdoc::fedwiki-materialization-plan)
  (let ((summary (hyperdoc::fedwiki-materialization-plan-summary plan)))
    (views:html-view :title "Overview" :priority 1
                     (views:html
                      (:table :class "inspector-table"
                              (:tr (:td (views:esc "Mode"))
                                   (:td (views:object-ref
                                         (hyperdoc::fedwiki-materialization-mode-of plan))))
                              (:tr (:td (views:esc "Selector"))
                                   (:td (views:object-ref
                                         (hyperdoc::fedwiki-materialization-selector-of plan))))
                              (:tr (:td (views:esc "Description"))
                                   (:td (views:esc
                                         (hyperdoc::fedwiki-materialization-description-of plan))))
                              (:tr (:td (views:esc "HyperDoc branch"))
                                   (:td (views:esc
                                         (hyperdoc::fedwiki-materialization-expected-hyperdoc-branch-of plan))))
                              (:tr (:td (views:esc "FedWiki branch"))
                                   (:td (views:esc
                                         (hyperdoc::fedwiki-materialization-expected-fedwiki-branch-of plan))))
                              (:tr (:td (views:esc "Pages directory"))
                                   (:td (:code
                                         (views:esc
                                          (namestring
                                           (hyperdoc::fedwiki-materialization-fedwiki-pages-directory-of plan))))))
                              (:tr (:td (views:esc "Creates"))
                                   (:td (views:object-ref (getf summary :creates))))
                              (:tr (:td (views:esc "Appends"))
                                   (:td (views:object-ref (getf summary :appends))))
                              (:tr (:td (views:esc "Already present"))
                                   (:td (views:object-ref (getf summary :already-present))))
                              (:tr (:td (views:esc "Execution report"))
                                   (:td (views:object-ref
                                         (or (hyperdoc::fedwiki-materialization-execution-report-of plan)
                                             "not materialized yet")))))))))

(views:defview 👀entries (plan hyperdoc::fedwiki-materialization-plan)
  (views:html-view :title "Entries" :priority 2
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th (views:esc "Action"))
                                 (:th (views:esc "Slug"))
                                 (:th (views:esc "Title"))
                                 (:th (views:esc "Source"))
                                 (:th (views:esc "Target")))
                            (dolist (entry (hyperdoc::fedwiki-materialization-entries-of plan))
                              (destructuring-bind (action slug title source target)
                                  (materialization-entry-row entry)
                                (views:html
                                 (:tr (:td (views:esc
                                            (string-downcase (symbol-name action))))
                                      (:td (views:esc slug))
                                      (:td (views:esc title))
                                      (:td (views:esc
                                            (string-downcase (symbol-name source))))
                                      (:td (:code (views:esc target)))))))))))

(views:defview 👀execution-report (plan hyperdoc::fedwiki-materialization-plan)
  (views:html-view :title "Execution report" :priority 3
                   (let ((report (hyperdoc::fedwiki-materialization-execution-report-of plan)))
                     (if report
                         (views:html
                          (:table :class "inspector-table"
                                  (:tr (:th (views:esc "Action"))
                                       (:th (views:esc "Slug"))
                                       (:th (views:esc "Target")))
                                  (dolist (entry report)
                                    (views:html
                                     (:tr (:td (views:esc
                                                (string-downcase
                                                 (symbol-name (getf entry :action)))))
                                          (:td (views:esc (getf entry :slug)))
                                          (:td (:code
                                                (views:esc
                                                 (namestring (getf entry :target-path))))))))))
                         (views:html
                          (:p (views:esc "Materialize the plan to populate an execution report.")))))))
