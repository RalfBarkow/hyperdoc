;;;; Inspector views for generic authored relation artifacts
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun authored-artifact-string (value)
  (cond
    ((null value) "n/a")
    ((stringp value) value)
    ((keywordp value) (string-downcase (string value)))
    ((symbolp value) (string-downcase (string value)))
    ((listp value) (format nil "~{~A~^, ~}" value))
    (t (format nil "~A" value))))

(defun authored-artifact-lines-html (lines)
  (views:html
    (:pre (views:esc (format nil "~{~A~%~}" lines)))))

(defun authored-artifact-render-object-ref (object)
  (if object
      (views:object-ref object)
      (views:html (:span :style "opacity: 0.55;" "n/a"))))

(defun authored-artifact-table-row (label value)
  (views:html
    (:tr
     (:th :style "text-align: left; padding-right: 0.75rem;"
          (views:esc label))
     (:td value))))

(defun authored-artifact-maybe-object-row (label object)
  (authored-artifact-table-row label
                               (authored-artifact-render-object-ref object)))

(defun authored-relation-artifact-relation-line (relation)
  (format nil "~A ~A ~A"
          (hyperdoc::authored-relation-subject-of relation)
          (hyperdoc::authored-relation-predicate-of relation)
          (hyperdoc::authored-relation-object-of relation)))

(defun compiled-behavior-artifact-machine-lines (artifact)
  (append
   (list
    (format nil "Primary machine: ~A"
            (if-let (machine
                      (hyperdoc::compiled-behavior-artifact-primary-machine-of
                       artifact))
              (hyperdoc::title-of machine)
              "n/a")))
   (if (hyperdoc::compiled-behavior-artifact-related-machines-of artifact)
       (loop for (key . machine)
               in (hyperdoc::compiled-behavior-artifact-related-machines-of
                   artifact)
             collect (format nil "~A: ~A"
                             key
                             (if machine
                                 (hyperdoc::title-of machine)
                                 "n/a")))
       (list "Related machines: none"))))

(defun compiled-behavior-artifact-scxml-lines (artifact)
  (append
   (list "Primary machine SCXML:"
         (or (hyperdoc::compiled-behavior-artifact-primary-machine-scxml-of
              artifact)
             "n/a"))
   (loop for (key . scxml)
           in (hyperdoc::compiled-behavior-artifact-related-machine-scxml-of
               artifact)
         append
         (list "" (format nil "~A SCXML:" key) (or scxml "n/a")))))

(defun compiled-layout-artifact-lines (artifact)
  (append
   (list
    (format nil "Pane relations: ~D"
            (length (hyperdoc::compiled-layout-artifact-pane-relations-of
                     artifact)))
    (format nil "Comparison relations: ~D"
            (length
             (hyperdoc::compiled-layout-artifact-comparison-relations-of
              artifact)))
    ""
    "Layout spec:")
   (list (format nil "~S"
                 (hyperdoc::compiled-layout-artifact-layout-spec-of artifact)))))

(defmethod views:text-representation
    ((object hyperdoc::authored-relation-role))
  (hyperdoc::title-of object))

(defmethod views:text-representation
    ((object hyperdoc::authored-relation))
  (hyperdoc::title-of object))

(defmethod views:text-representation
    ((object hyperdoc::authored-relation-artifact))
  (hyperdoc::title-of object))

(defmethod views:text-representation
    ((object hyperdoc::compiled-artifact))
  (hyperdoc::title-of object))

(views:defview authored-relation-role-summary
    (role hyperdoc::authored-relation-role)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:table :class "inspector-table"
              (authored-artifact-table-row
               "Kind"
               (views:esc
                (authored-artifact-string
                 (hyperdoc::authored-relation-role-kind-of role))))
              (authored-artifact-table-row
               "Binding"
               (views:esc
                (authored-artifact-string
                 (hyperdoc::authored-relation-role-binding-of role))))
              (authored-artifact-table-row
               "Participants"
               (views:esc
                (authored-artifact-string
                 (hyperdoc::authored-relation-role-participants-of role)))))
      (when (hyperdoc::authored-relation-role-findings-of role)
        (views:html
          (:h3 "Findings")
          (:ul
           (dolist (finding
                    (hyperdoc::authored-relation-role-findings-of role))
             (views:html
               (:li (views:esc finding))))))))))

(views:defview authored-relation-summary
    (relation hyperdoc::authored-relation)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:table :class "inspector-table"
              (authored-artifact-table-row
               "Layer"
               (views:esc
                (authored-artifact-string
                 (hyperdoc::authored-relation-layer-of relation))))
              (authored-artifact-table-row
               "Subject"
               (views:esc
                (authored-artifact-string
                 (hyperdoc::authored-relation-subject-of relation))))
              (authored-artifact-table-row
               "Predicate"
               (views:esc
                (authored-artifact-string
                 (hyperdoc::authored-relation-predicate-of relation))))
              (authored-artifact-table-row
               "Object"
               (views:esc
                (authored-artifact-string
                 (hyperdoc::authored-relation-object-of relation)))))
      (when (hyperdoc::authored-relation-attributes-of relation)
        (views:html
          (:h3 "Attributes")
          (:pre (views:esc
                 (format nil "~S"
                         (hyperdoc::authored-relation-attributes-of
                          relation)))))))))

(views:defview authored-relation-artifact-summary
    (artifact hyperdoc::authored-relation-artifact)
  (views:html-view :title "Summary" :priority 20
    (views:html
      (:div :class "hyperdoc-authored-relation-artifact"
            :data-hyperdoc-authored-relation-artifact "true"
            (:p (views:esc (hyperdoc::summary-of artifact)))
            (:table :class "inspector-table"
                    (authored-artifact-table-row
                     "Kind"
                     (views:esc
                      (authored-artifact-string
                       (hyperdoc::authored-relation-artifact-kind-of
                        artifact))))
                    (authored-artifact-table-row
                     "Workflow role"
                     (views:esc
                      (authored-artifact-string
                       (hyperdoc::authored-relation-artifact-workflow-role-of
                        artifact))))
                    (authored-artifact-table-row
                     "Compiler pipeline"
                     (views:esc
                      (authored-artifact-string
                       (hyperdoc::authored-relation-artifact-compiler-pipeline-of
                        artifact))))
                    (authored-artifact-table-row
                     "Semantic roles"
                     (views:esc
                      (format nil "~D"
                              (length
                               (hyperdoc::authored-relation-artifact-semantic-roles-of
                                artifact)))))
                    (authored-artifact-table-row
                     "Behavior relations"
                     (views:esc
                      (format nil "~D"
                              (length
                               (hyperdoc::authored-relation-artifact-behavior-relations-of
                                artifact)))))
                    (authored-artifact-table-row
                     "Layout relations"
                     (views:esc
                      (format nil "~D"
                              (length
                               (hyperdoc::authored-relation-artifact-layout-relations-of
                                artifact))))))
            (:h3 "Compiled targets")
            (:ul
             (dolist (target
                      (hyperdoc::authored-relation-artifact-compiled-targets-of
                       artifact))
               (views:html
                 (:li (views:esc (authored-artifact-string target))))))
            (when (hyperdoc::authored-relation-artifact-findings-of artifact)
              (views:html
                (:h3 "Findings")
                (:ul
                 (dolist
                     (finding
                      (hyperdoc::authored-relation-artifact-findings-of
                       artifact))
                   (views:html
                     (:li (views:esc finding)))))))))))

(views:defview authored-relation-artifact-semantic-roles
    (artifact hyperdoc::authored-relation-artifact)
  (views:html-view :title "Semantic roles" :priority 21
    (views:html
      (:ul
       (dolist (role
                (hyperdoc::authored-relation-artifact-semantic-roles-of
                 artifact))
         (views:html
           (:li (views:object-ref role))))))))

(views:defview authored-relation-artifact-behavior-relations
    (artifact hyperdoc::authored-relation-artifact)
  (views:html-view :title "Behavior relations" :priority 22
    (views:html
      (:ul
       (dolist (relation
                (hyperdoc::authored-relation-artifact-behavior-relations-of
                 artifact))
         (views:html
           (:li (views:object-ref relation)
                " "
                (:span :style "opacity: 0.6;"
                       (views:esc
                        (authored-relation-artifact-relation-line
                         relation))))))))))

(views:defview authored-relation-artifact-layout-relations
    (artifact hyperdoc::authored-relation-artifact)
  (views:html-view :title "Layout relations" :priority 23
    (views:html
      (:ul
       (dolist (relation
                (hyperdoc::authored-relation-artifact-layout-relations-of
                 artifact))
         (views:html
           (:li (views:object-ref relation)
                " "
                (:span :style "opacity: 0.6;"
                       (views:esc
                        (authored-relation-artifact-relation-line
                         relation))))))))))

(views:defview compiled-artifact-summary
    (artifact hyperdoc::compiled-artifact)
  (views:html-view :title "Summary" :priority 20
    (views:html
      (:div :class "hyperdoc-compiled-artifact"
            :data-hyperdoc-compiled-artifact "true"
            (:p (views:esc (hyperdoc::summary-of artifact)))
            (:table :class "inspector-table"
                    (authored-artifact-table-row
                     "Kind"
                     (views:esc
                      (authored-artifact-string
                       (hyperdoc::compiled-artifact-kind-of artifact))))
                    (authored-artifact-table-row
                     "Compiler stage"
                     (views:esc
                      (authored-artifact-string
                       (hyperdoc::compiled-artifact-compiler-stage-of
                        artifact))))
                    (authored-artifact-maybe-object-row
                     "Authored artifact"
                     (hyperdoc::compiled-artifact-authored-artifact-of artifact))
                    (authored-artifact-table-row
                     "Compiler inputs"
                     (views:esc
                      (format nil "~D"
                              (length
                               (hyperdoc::compiled-artifact-compiler-inputs-of
                                artifact)))))
                    (authored-artifact-table-row
                     "Relations"
                     (views:esc
                      (format nil "~D"
                              (length
                               (hyperdoc::compiled-artifact-relations-of
                                artifact))))))
            (when (hyperdoc::compiled-artifact-findings-of artifact)
              (views:html
                (:h3 "Findings")
                (:ul
                 (dolist (finding
                          (hyperdoc::compiled-artifact-findings-of artifact))
                   (views:html
                     (:li (views:esc finding)))))))))))

(views:defview compiled-artifact-relations
    (artifact hyperdoc::compiled-artifact)
  (views:html-view :title "Relations" :priority 21
    (views:html
      (:ul
       (dolist (relation (hyperdoc::compiled-artifact-relations-of artifact))
         (views:html
           (:li (views:object-ref relation))))))))

(views:defview compiled-behavior-artifact-machines
    (artifact hyperdoc::compiled-behavior-artifact)
  (views:html-view :title "Behavior machine" :priority 22
    (authored-artifact-lines-html
     (compiled-behavior-artifact-machine-lines artifact))))

(views:defview compiled-behavior-artifact-scxml
    (artifact hyperdoc::compiled-behavior-artifact)
  (views:html-view :title "SCXML" :priority 23
    (authored-artifact-lines-html
     (compiled-behavior-artifact-scxml-lines artifact))))

(views:defview compiled-layout-artifact-layout
    (artifact hyperdoc::compiled-layout-artifact)
  (views:html-view :title "Layout" :priority 22
    (authored-artifact-lines-html
     (compiled-layout-artifact-lines artifact))))
