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
                                 :status (status-of entry)
                                 :note (note-of entry)))
                         (entries-of trace))))
