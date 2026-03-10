;;;; Improved plan view for ASDF systems
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :html-inspector-views/standard)

(defstruct plan-action-row
  index
  operation
  system
  module-components
  leaf-component
  raw-target
  component-class)

(defun component-lineage (component)
  (loop for current = component then (ignore-errors (asdf:component-parent current))
        while current
        collect current))

(defun component-root-system (component)
  (find-if (lambda (entry)
             (typep entry 'asdf/system:system))
           (component-lineage component)))

(defun component-module-components (component)
  (let ((root-to-leaf (reverse (component-lineage component))))
    (if (> (length root-to-leaf) 2)
        (subseq root-to-leaf 1 (1- (length root-to-leaf)))
        '())))

(defun component-class-label (component)
  (let ((name (class-name (class-of component))))
    (string-downcase
     (if (symbolp name)
         (symbol-name name)
         (princ-to-string name)))))

(defun plan-action-row-from-action (action index)
  (let ((component (asdf/action:action-component action)))
    (make-plan-action-row
     :index index
     :operation (asdf/action:action-operation action)
     :system (component-root-system component)
     :module-components (component-module-components component)
     :leaf-component component
     :raw-target (text-representation component)
     :component-class (component-class-label component))))

(defun plan-action-rows (plan)
  (loop for action in (asdf/plan:plan-actions plan)
        for index from 0
        collect (plan-action-row-from-action action index)))

(defun module-path-string (module-components)
  (if module-components
      (format nil "~{~A~^/~}" (mapcar #'asdf:component-name module-components))
      ""))

(defun distinct-non-empty-strings (strings)
  (remove-duplicates (remove "" strings :test #'string=)
                     :test #'string=))

(defun render-object-cell (object &key (align "left"))
  (html
    (:td :align align
         (if object
             (object-ref object)
             (html
               (:tt (esc "n/a")))))))

(defun render-module-path-cell (module-components)
  (html
    (:td
     (if module-components
         (loop for component in module-components
               for first = t then nil
               do (unless first
                    (html (:span " / ")))
                  (html (object-ref component)))
         (html
           (:small :class "inspector-index" (esc "root")))))))

(defun render-raw-target-cell (raw-target)
  (html
    (:td (:tt (esc raw-target)))))

(defun render-plan-action-row (row)
  (html
    (:tr
     (:td :align "right"
          (:small :class "inspector-index"
                  (fmt "~D" (1+ (plan-action-row-index row)))))
     (render-object-cell (plan-action-row-operation row))
     (render-object-cell (plan-action-row-system row))
     (render-module-path-cell (plan-action-row-module-components row))
     (render-object-cell (plan-action-row-leaf-component row))
     (:td (:tt (esc (plan-action-row-component-class row))))
     (render-raw-target-cell (plan-action-row-raw-target row)))))

(defview 👀actions (plan asdf/plan:plan)
  (html-view :title "Actions" :priority 1
    (let* ((rows (plan-action-rows plan))
           (system-count (length
                          (remove-duplicates
                           (remove nil
                                   (mapcar (lambda (row)
                                             (and (plan-action-row-system row)
                                                  (asdf:component-name
                                                   (plan-action-row-system row))))
                                           rows))
                           :test #'string=)))
           (module-count (length
                          (distinct-non-empty-strings
                           (mapcar (lambda (row)
                                     (module-path-string
                                      (plan-action-row-module-components row)))
                                   rows))))
           (leaf-count (length
                        (remove-duplicates
                         (mapcar #'plan-action-row-raw-target rows)
                         :test #'string=))))
      (html
        (:small :class "inspector-index"
                (fmt "~D action(s), ~D system(s), ~D module path(s), ~D leaf component(s)"
                     (length rows)
                     system-count
                     module-count
                     leaf-count))
        (:table :class "inspector-table"
                (:tr (:th (esc "Order"))
                     (:th (esc "Operation"))
                     (:th (esc "System"))
                     (:th (esc "Module path"))
                     (:th (esc "Component / file"))
                     (:th (esc "Component class"))
                     (:th (esc "Raw target")))
                (loop for row in rows
                      do (html
                           (render-plan-action-row row))))))))
