;;;; Lightweight view data helpers for Kioskbeerli objects
;;
;;;; Copyright (c) 2026

(in-package :kioskbeerli)

(defun kioskbeerli-dashboard-view-data
    (&optional (dashboard (kioskbeerli-dashboard)))
  (list :id (id-of dashboard)
        :title (title-of dashboard)
        :summary (summary-of dashboard)
        :status-vocabulary (status-vocabulary-of dashboard)
        :sections (mapcar (lambda (section)
                            (list :id (id-of section)
                                  :section (section-of section)
                                  :status (status-of section)
                                  :summary (summary-of section)))
                          (sections-of dashboard))
        :stations (stations-of dashboard)))

(defun kioskbeerli-plan-view-data (&optional (run (kioskbeerli-planner-run)))
  (list :id (id-of run)
        :execution-mode (execution-mode-of run)
        :dry-run-p (dry-run-p run)
        :tasks (mapcar (lambda (task)
                         (list :id (id-of task)
                               :dependencies (dependencies-of task)
                               :status (status-of task)
                               :evidence-paths (evidence-paths-of task)))
                       (tasks-of run))))

(defun kioskbeerli-trace-view-data
    (&optional (trace (kioskbeerli-project-trace)))
  (list :id (id-of trace)
        :title (title-of trace)
        :entries (mapcar (lambda (entry)
                           (list :id (id-of entry)
                                 :task-id (task-id-of entry)
                                 :from-state (from-state-of entry)
                                 :to-state (to-state-of entry)
                                 :scxml-event (scxml-event-of entry)
                                 :status (status-of entry)
                                 :note (note-of entry)))
                         (entries-of trace))))

(defmethod views:text-representation ((task kioskbeerli-plan-task))
  (format nil "~A: ~A" (id-of task) (status-of task)))

(defmethod views:text-representation ((run kioskbeerli-plan-run))
  (format nil "~A: ~A" (id-of run) (execution-mode-of run)))

(defmethod views:text-representation ((link kioskbeerli-task-state-link))
  (format nil "~A -> ~A"
          (or (scxml-event-of link) "initial")
          (scxml-state-of link)))

(defmethod views:text-representation ((dashboard kioskbeerli-topic-dashboard))
  (format nil "~A: ~A"
          (title-of dashboard)
          (status-of (first (sections-of dashboard)))))

(defmethod views:text-representation ((trace kioskbeerli-project-trace))
  (format nil "~A (~D entries)"
          (title-of trace)
          (length (entries-of trace))))

(defmethod views:text-representation
    ((manifest kioskbeerli-fedwiki-asset-manifest))
  (format nil "~A assets" (page-slug-of manifest)))

(defmethod views:text-representation ((store kioskbeerli-sqlite-store))
  (format nil "SQLite ~A: ~A"
          (sqlite-store-schema-status-of store)
          (sqlite-store-db-path-of store)))

(defun %render-kioskbeerli-string-list (items &optional (empty "None."))
  (if items
      (views:html
       (:ul
        (loop for item in items
              do (views:html
                  (:li (:tt (views:esc item)))))))
      (views:html
       (:p (views:esc empty)))))

(defun %kioskbeerli-dependency-chain
    (task &optional (run (kioskbeerli-task-plan task)))
  (labels ((walk (task-id seen)
             (if (member task-id seen :test #'string=)
                 nil
                 (let ((dependency-task
                         (kioskbeerli-lookup-plan-task task-id :run run)))
                   (when dependency-task
                     (append
                      (loop for dependency in (dependencies-of dependency-task)
                            append (walk dependency (cons task-id seen)))
                      (list dependency-task)))))))
    (remove-duplicates
     (loop for dependency in (dependencies-of task)
           append (walk dependency (list (id-of task))))
     :key #'id-of
     :test #'string=
     :from-end t)))

(defun %kioskbeerli-missing-evidence-items (task)
  (remove-if-not
   (lambda (path)
     (and (stringp path)
          (<= 8 (length path))
          (string= "missing:" path :end2 8)))
   (evidence-paths-of task)))

(defun %render-kioskbeerli-task-table-row (label value)
  (views:html
   (:tr (:td (views:esc label))
        (:td (:tt (views:esc (or value "")))))))

(defun %render-kioskbeerli-object-list (objects &optional (empty "None."))
  (if objects
      (views:html
       (:ul
        (loop for object in objects
              do (views:html
                  (:li (views:object-ref object))))))
      (views:html (:p (views:esc empty)))))

(views:defview 👀overview (dashboard kioskbeerli-topic-dashboard)
  (let ((plan (planner-run-of dashboard))
        (trace (project-trace-of dashboard)))
    (views:html-view
     :title "Dashboard"
     :priority 1
     (views:html
      (:h3 (views:esc (title-of dashboard)))
      (:p (views:esc (summary-of dashboard)))
      (:h4 "Status")
      (:table :class "inspector-table"
              (loop for section in (sections-of dashboard)
                    do (views:html
                        (:tr
                         (:td (views:esc (section-of section)))
                         (:td (:tt (views:esc (status-of section))))
                         (:td (views:esc (summary-of section)))))))
      (:h4 "Active plan")
      (:p (views:object-ref plan))
      (:h4 "Next executable steps")
      (%render-kioskbeerli-object-list
       (kioskbeerli-next-missing-evidence-tasks :run plan :trace trace)
       "No blocked or missing-evidence tasks.")
      (:h4 "Recent trace events")
      (%render-kioskbeerli-object-list
       (last (entries-of trace) (min 5 (length (entries-of trace))))
       "No trace entries recorded.")
      (:h4 "Asset links")
      (:ul
       (:li (:tt "http://localhost:3000/view/kioskbeerli"))
       (:li (:tt "http://localhost:3000/assets/pages/kioskbeerli/kioskbeerli.asd")))
      (:h4 "SQLite status")
      (:p "Optional. Use "
          (:tt "(kioskbeerli:open-or-create-sqlite-store ...)")
          " to create a local store.")))))

(views:defview 👀overview (run kioskbeerli-plan-run)
  (views:html-view
   :title "Plan"
   :priority 1
   (views:html
    (:h3 (views:esc (title-of run)))
    (:p (views:esc (summary-of run)))
    (:table :class "inspector-table"
            (%render-kioskbeerli-task-table-row
             "Execution mode"
             (princ-to-string (execution-mode-of run)))
            (%render-kioskbeerli-task-table-row
             "Planner kind"
             (princ-to-string (planner-kind-of run)))
            (%render-kioskbeerli-task-table-row
             "Dry run"
             (if (dry-run-p run) "true" "false")))
    (:h4 "Next executable steps")
    (%render-kioskbeerli-object-list
     (kioskbeerli-next-missing-evidence-tasks :run run)
     "No blocked or missing-evidence tasks.")
    (:h4 "Tasks")
    (%render-kioskbeerli-object-list (tasks-of run)))))

(views:defview 👀overview (trace kioskbeerli-project-trace)
  (views:html-view
   :title "Trace"
   :priority 1
   (views:html
    (:h3 (views:esc (title-of trace)))
    (:p (views:esc (summary-of trace)))
    (:h4 "Recent events")
    (if (entries-of trace)
        (views:html
         (:table :class "inspector-table"
                 (loop for entry in (entries-of trace)
                       do (views:html
                           (:tr
                            (:td (:tt (views:esc (id-of entry))))
                            (:td (:tt (views:esc (task-id-of entry))))
                            (:td (:tt (views:esc (status-of entry))))
                            (:td (views:esc (or (note-of entry) ""))))))))
        (views:html (:p "No trace entries recorded."))))))

(views:defview 👀overview (store kioskbeerli-sqlite-store)
  (views:html-view
   :title "SQLite Store"
   :priority 1
   (views:html
    (:h3 "SQLite store")
    (:table :class "inspector-table"
            (%render-kioskbeerli-task-table-row
             "Database"
             (namestring (sqlite-store-db-path-of store)))
            (%render-kioskbeerli-task-table-row
             "sqlite3"
             (sqlite-store-program-of store))
            (%render-kioskbeerli-task-table-row
             "Schema"
             (princ-to-string (sqlite-store-schema-status-of store))))
    (:p "SQLite is optional. Core Kioskbeerli objects remain available when this store is unavailable."))))

(views:defview 👀overview (manifest kioskbeerli-fedwiki-asset-manifest)
  (views:html-view
   :title "FedWiki Assets"
   :priority 1
   (views:html
    (:h3 "FedWiki page assets")
    (:table :class "inspector-table"
            (%render-kioskbeerli-task-table-row
             "Page"
             (page-url-of manifest))
            (%render-kioskbeerli-task-table-row
             "Asset prefix"
             (asset-url-prefix-of manifest))
            (%render-kioskbeerli-task-table-row
             "Root"
             (namestring (asset-root-of manifest))))
    (:h4 "Files")
    (%render-kioskbeerli-string-list (asset-files-of manifest)))))

(views:defview 👀overview (task kioskbeerli-plan-task)
  (let* ((run (kioskbeerli-task-plan task))
         (state-link (kioskbeerli-task-state-link task))
         (progress (kioskbeerli-task-progress task))
         (dependents (kioskbeerli-task-dependents task :run run))
         (missing-evidence (%kioskbeerli-missing-evidence-items task)))
    (views:html-view
     :title "Task state"
     :priority 1
     (views:html
      (:h3 (views:esc (title-of task)))
      (:table :class "inspector-table"
              (%render-kioskbeerli-task-table-row "Task id" (id-of task))
              (%render-kioskbeerli-task-table-row "Status" (status-of task))
              (%render-kioskbeerli-task-table-row
               "SCXML event"
               (and state-link (scxml-event-of state-link)))
              (%render-kioskbeerli-task-table-row
               "SCXML state"
               (and state-link (scxml-state-of state-link))))
      (:h4 "Parent plan/run")
      (:p (views:object-ref run))
      (:h4 "Dependency chain")
      (if (%kioskbeerli-dependency-chain task run)
          (views:html
           (:ol
            (loop for dependency in (%kioskbeerli-dependency-chain task run)
                  do (views:html
                      (:li (views:object-ref dependency))))))
          (views:html (:p "No upstream dependencies.")))
      (:h4 "Direct dependencies")
      (%render-kioskbeerli-string-list (dependencies-of task))
      (:h4 "Dependents / next tasks")
      (if dependents
          (views:html
           (:ul
            (loop for dependent in dependents
                  do (views:html
                      (:li (views:object-ref dependent))))))
          (views:html (:p "No direct dependents.")))
      (:h4 "Progress entries")
      (if progress
          (views:html
           (:ul
            (loop for entry in progress
                  do (views:html
                      (:li
                       (:tt (views:esc (id-of entry)))
                       " "
                       (:tt (views:esc (status-of entry)))
                       " "
                       (:tt (views:esc (or (scxml-event-of entry) "")))
                       " "
                       (views:esc (or (note-of entry) "")))))))
          (views:html (:p "No progress entries recorded for this task.")))
      (:h4 "Evidence status")
      (%render-kioskbeerli-string-list (evidence-paths-of task)
                                       "No evidence paths recorded.")
      (:h4 "Missing-evidence explanation")
      (if missing-evidence
          (%render-kioskbeerli-string-list missing-evidence)
          (views:html
           (:p "No missing-evidence marker remains on this task.")))))))
