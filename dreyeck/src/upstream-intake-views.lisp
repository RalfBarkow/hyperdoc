;;;; Inspector views for read-only upstream intake observations.

(in-package #:dreyeck/inspector/upstream-intake)

(defmethod html-inspector-views:text-representation
    ((reference dreyeck/upstream-intake:upstream-reference))
  (format nil "Upstream intake: ~A"
          (dreyeck/upstream-intake:upstream-reference-reference-of
           reference)))

(defun render-intake-value (value &key object display)
  (if object
      (html-inspector-views:object-ref value :display display)
      (html-inspector-views:html
        (:code
         (html-inspector-views:esc
          (if (stringp value)
              value
              (prin1-to-string value)))))))

(defun render-intake-row (label value &key object display)
  (html-inspector-views:html
    (:tr
     (:th :style "text-align: left; vertical-align: top;"
          (html-inspector-views:esc label))
     (:td (render-intake-value value :object object :display display)))))

(defun yes-no (value)
  (if value "yes" "no"))

(defun commit-display (commit)
  (dreyeck/git:trim-git-output
   (dreyeck/git:git-commit-one-line commit)))

(defun render-local-context (reference)
  (let ((context
          (dreyeck/upstream-intake:upstream-reference-local-context-of
           reference)))
    (html-inspector-views:html
      (render-intake-row
       "Repository"
       (namestring
        (dreyeck/git:git-repository-root-of
         (dreyeck/upstream-intake:upstream-local-context-repository-of
          context))))
      (render-intake-row
       "Branch"
       (or (dreyeck/upstream-intake:upstream-local-context-branch-of
            context)
           "detached HEAD"))
      (render-intake-row
       "Current HEAD"
       (dreyeck/upstream-intake:upstream-local-context-current-head-of
        context)
       :object t
       :display
       (commit-display
        (dreyeck/upstream-intake:upstream-local-context-current-head-of
         context))))))

(defun render-git-commit-intake (reference)
  (let ((upstream-commit
          (dreyeck/upstream-intake:git-commit-upstream-commit-of
           reference))
        (merge-base
          (dreyeck/upstream-intake:git-commit-upstream-merge-base-of
           reference)))
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc "Upstream Intake"))
      (:table :class "inspector-table"
              (render-intake-row "Kind" "Git commit")
              (render-intake-row
               "Origin"
               (dreyeck/upstream-intake:upstream-reference-origin-of
                reference))
              (if upstream-commit
                  (render-intake-row
                   "Commit"
                   upstream-commit
                   :object t
                   :display
                   (dreyeck/upstream-intake:upstream-reference-reference-of
                    reference))
                  (render-intake-row
                   "Commit"
                   (dreyeck/upstream-intake:upstream-reference-reference-of
                    reference)))
              (render-local-context reference)
              (render-intake-row
               "Object present"
               (yes-no
                (dreyeck/upstream-intake:git-commit-upstream-object-present-p
                 reference)))
              (render-intake-row
               "Ancestor of HEAD"
               (if upstream-commit
                   (yes-no
                    (dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p
                     reference))
                   "not applicable"))
              (if merge-base
                  (render-intake-row
                   "Merge base"
                   merge-base
                   :object t
                   :display (commit-display merge-base))
                  (render-intake-row "Merge base" "not available"))
              (render-intake-row
               "Refs containing commit"
               (dreyeck/upstream-intake:git-commit-upstream-refs-containing-of
                reference))
              (render-intake-row
               "Classification"
               (dreyeck/upstream-intake:git-commit-upstream-classification-of
                reference))))))

(defun render-component-local-subject (reference)
  (let ((subject
          (dreyeck/upstream-intake:component-upstream-local-subject-of
           reference)))
    (if (typep subject 'dreyeck/git:git-commit)
        (render-intake-row
         "Local subject"
         subject
         :object t
         :display (commit-display subject))
        (render-intake-row "Local subject" subject))))

(defun render-contract-observations (reference)
  (html-inspector-views:html
    (:h3 (html-inspector-views:esc "Contract observations"))
    (:table :class "inspector-table"
            (:tr
             (:th (html-inspector-views:esc "Contract"))
             (:th (html-inspector-views:esc "Status")))
            (dolist
                (contract
                  (dreyeck/upstream-intake:component-upstream-contracts-of
                   reference))
              (html-inspector-views:html
                (:tr
                 (:td
                  (:code
                   (html-inspector-views:esc
                    (string-downcase
                     (symbol-name
                      (dreyeck/upstream-intake:contract-observation-name-of
                       contract))))))
                 (:td
                  (:code
                   (html-inspector-views:esc
                    (string-upcase
                     (symbol-name
                      (dreyeck/upstream-intake:contract-observation-status-of
                       contract))))))))))))

(defun render-component-intake (reference)
  (html-inspector-views:html
    (:h2 (html-inspector-views:esc "Upstream Intake"))
    (:table :class "inspector-table"
            (render-intake-row "Kind" "Component")
            (render-intake-row
             "Origin"
             (dreyeck/upstream-intake:upstream-reference-origin-of
              reference))
            (render-component-local-subject reference)
            (render-intake-row
             "Upstream candidate"
             (dreyeck/upstream-intake:upstream-reference-reference-of
              reference))
            (render-intake-row
             "Component name"
             (dreyeck/upstream-intake:component-upstream-component-name-of
              reference))
            (when
                (dreyeck/upstream-intake:component-upstream-url-of
                 reference)
              (render-intake-row
               "Upstream reference"
               (dreyeck/upstream-intake:component-upstream-url-of
                reference)))
            (render-intake-row
             "Proposed relation"
             (dreyeck/upstream-intake:component-upstream-proposed-relation-of
              reference))
            (render-intake-row
             "Status"
             (dreyeck/upstream-intake:component-upstream-status-of
              reference)))
    (render-contract-observations reference)))

(html-inspector-views:defview upstream-intake-view
    (reference dreyeck/upstream-intake:upstream-reference)
  (html-inspector-views:html-view :title "Upstream Intake" :priority 1
    (etypecase reference
      (dreyeck/upstream-intake:git-commit-upstream-reference
       (render-git-commit-intake reference))
      (dreyeck/upstream-intake:component-upstream-reference
       (render-component-intake reference)))))
