;;;; Lightweight view data helpers for Kioskberrli objects
;;
;;;; Copyright (c) 2026

(in-package :dreyeck/kioskbeerli)

(defun kioskbeerli-dashboard-view-data
    (&optional (dashboard (kioskberrli-dashboard)))
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
