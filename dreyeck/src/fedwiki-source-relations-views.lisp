;;;; Inspector views for source-backed FedWiki component relations.

(in-package #:dreyeck/inspector/fedwiki-source-relations)

(defmethod html-inspector-views:text-representation
    ((observation
      dreyeck/fedwiki-source-relations:fedwiki-source-relations-observation))
  (format nil "FedWiki source relations @ ~A"
          (subseq
           (dreyeck/git:git-commit-hash-of
            (dreyeck/fedwiki-source-relations:fedwiki-source-relations-commit-of
             observation))
           0 12)))

(defmethod html-inspector-views:text-representation
    ((evidence dreyeck/fedwiki-source-relations:definition-evidence))
  (dreyeck/fedwiki-source-relations:definition-evidence-name-of evidence))

(defmethod html-inspector-views:text-representation
    ((fragment dreyeck/fedwiki-source-relations:source-fragment-evidence))
  (format nil "~A lines ~D-~D"
          (dreyeck/fedwiki-source-relations:source-fragment-definition-of
           fragment)
          (dreyeck/fedwiki-source-relations:source-fragment-start-line-of
           fragment)
          (dreyeck/fedwiki-source-relations:source-fragment-end-line-of
           fragment)))

(defmethod html-inspector-views:text-representation
    ((relation dreyeck/fedwiki-source-relations:typed-source-relation))
  (format nil "~S source relation"
          (dreyeck/fedwiki-source-relations:typed-source-relation-type-of
           relation)))

(defmethod html-inspector-views:text-representation
    ((hypothesis dreyeck/fedwiki-source-relations:refactoring-hypothesis))
  (dreyeck/fedwiki-source-relations:refactoring-hypothesis-title-of
   hypothesis))

(defun render-value (value &key object display)
  (if object
      (html-inspector-views:object-ref value :display display)
      (html-inspector-views:html
        (:code
         (html-inspector-views:esc
          (if (stringp value) value (prin1-to-string value)))))))

(defun render-row (label value &key object display)
  (html-inspector-views:html
    (:tr
     (:th :style "text-align:left;vertical-align:top;"
          (html-inspector-views:esc label))
     (:td (render-value value :object object :display display)))))

(defun render-object-list (objects)
  (html-inspector-views:html
    (:ul
     (dolist (object objects)
       (html-inspector-views:html
         (:li (html-inspector-views:object-ref object)))))))

(html-inspector-views:defview 👀source-fragment
    (fragment dreyeck/fedwiki-source-relations:source-fragment-evidence)
  (html-inspector-views:html-view :title "Source fragment" :priority 1
				  (html-inspector-views:html
				    (:table :class "inspector-table"
					    (render-row
					     "Git file"
					     (dreyeck/fedwiki-source-relations:source-fragment-file-of
					      fragment)
					     :object t)
					    (render-row
					     "Definition"
					     (dreyeck/fedwiki-source-relations:source-fragment-definition-of
					      fragment))
					    (render-row
					     "Kind"
					     (dreyeck/fedwiki-source-relations:source-fragment-kind-of
					      fragment))
					    (render-row
					     "Lines"
					     (format nil "~D-~D"
						     (dreyeck/fedwiki-source-relations:source-fragment-start-line-of
						      fragment)
						     (dreyeck/fedwiki-source-relations:source-fragment-end-line-of
						      fragment))))
				    (:pre :style "white-space:pre-wrap;"
					  (html-inspector-views:esc
					   (dreyeck/fedwiki-source-relations:source-fragment-text-of
					    fragment))))))

(html-inspector-views:defview 👀definition-evidence
    (evidence dreyeck/fedwiki-source-relations:definition-evidence)
  (html-inspector-views:html-view :title "Overview" :priority 1
				  (html-inspector-views:html
				    (:table :class "inspector-table"
					    (render-row
					     "ID"
					     (dreyeck/fedwiki-source-relations:definition-evidence-id-of
					      evidence))
					    (render-row
					     "Name"
					     (dreyeck/fedwiki-source-relations:definition-evidence-name-of
					      evidence))
					    (render-row
					     "Kind"
					     (dreyeck/fedwiki-source-relations:definition-evidence-kind-of
					      evidence))
					    (render-row
					     "Role"
					     (dreyeck/fedwiki-source-relations:definition-evidence-role-of evidence))
					    (render-row
					     "Git file"
					     (dreyeck/fedwiki-source-relations:definition-evidence-file-of
					      evidence)
					     :object t)
					    (render-row
					     "Authoritative fragment"
					     (dreyeck/fedwiki-source-relations:definition-evidence-fragment-of
					      evidence)
					     :object t)))))

(html-inspector-views:defview 👀source-relation
    (relation dreyeck/fedwiki-source-relations:typed-source-relation)
  (html-inspector-views:html-view :title "Overview" :priority 1
				  (html-inspector-views:html
				    (:table :class "inspector-table"
					    (render-row
					     "Relation type"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-type-of
					      relation))
					    (render-row
					     "Source"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-source-of
					      relation)
					     :object t)
					    (render-row
					     "Target"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-target-of
					      relation)
					     :object t)
					    (render-row
					     "Role"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-role-of
					      relation))
					    (render-row
					     "Phases"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-phases-of
					      relation))
					    (render-row
					     "Ordering constraint"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-constraint-of
					      relation))
					    (render-row
					     "Ordering basis"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-basis-of
					      relation))
					    (render-row
					     "Authoritative fragment"
					     (dreyeck/fedwiki-source-relations:typed-source-relation-fragment-of
					      relation)
					     :object t)
					    (when
						(dreyeck/fedwiki-source-relations:typed-source-relation-derived-from-of
						 relation)
					      (render-row
					       "Derived from"
					       (dreyeck/fedwiki-source-relations:typed-source-relation-derived-from-of
						relation)
					       :object t))))))

(html-inspector-views:defview 👀refactoring-hypothesis
    (hypothesis dreyeck/fedwiki-source-relations:refactoring-hypothesis)
  (html-inspector-views:html-view :title "Overview" :priority 1
				  (html-inspector-views:html
				    (:table :class "inspector-table"
					    (render-row
					     "Status"
					     (dreyeck/fedwiki-source-relations:refactoring-hypothesis-status-of
					      hypothesis))
					    (render-row
					     "Title"
					     (dreyeck/fedwiki-source-relations:refactoring-hypothesis-title-of
					      hypothesis))
					    (:tr
					     (:th (html-inspector-views:esc "Moved definitions"))
					     (:td
					      (render-object-list
					       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-moved-definitions-of
						hypothesis))))
					    (:tr
					     (:th (html-inspector-views:esc "Relations intended to change"))
					     (:td
					      (render-object-list
					       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-removed-relations-of
						hypothesis))))
					    (render-row
					     "Required regressions"
					     (dreyeck/fedwiki-source-relations:refactoring-hypothesis-required-tests-of
					      hypothesis))
					    (render-row
					     "Falsifier"
					     (dreyeck/fedwiki-source-relations:refactoring-hypothesis-falsifier-of
					      hypothesis))
					    (render-row
					     "Notes"
					     (dreyeck/fedwiki-source-relations:refactoring-hypothesis-notes-of
					      hypothesis))))))

(html-inspector-views:defview 👀overview
    (observation
     dreyeck/fedwiki-source-relations:fedwiki-source-relations-observation)
  (html-inspector-views:html-view :title "Overview" :priority 1
				  (html-inspector-views:html
				    (:table :class "inspector-table"
					    (render-row
					     "Observed merge commit"
					     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-commit-of
					      observation)
					     :object t)
					    (render-row
					     "ASDF system"
					     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-system-name-of
					      observation))
					    (:tr
					     (:th (html-inspector-views:esc "Observed Git files"))
					     (:td
					      (render-object-list
					       (dreyeck/fedwiki-source-relations:fedwiki-source-relations-files-of
						observation))))
					    (render-row
					     "Task"
					     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-task-of
					      observation))
					    (render-row
					     "Task location"
					     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-task-location-of
					      observation))
					    (render-row
					     "Existing routine"
					     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-existing-routine-of
					      observation))
					    (render-row
					     "Problem assessment"
					     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-problem-status-of
					      observation))
					    (render-row
					     "Assessment basis"
					     (dreyeck/fedwiki-source-relations:fedwiki-source-relations-problem-statement-of
					      observation))
					    (render-row
					     "Definitions"
					     (length
					      (dreyeck/fedwiki-source-relations:fedwiki-source-relations-definitions-of
					       observation)))
					    (render-row
					     "Relations"
					     (length
					      (dreyeck/fedwiki-source-relations:fedwiki-source-relations-relations-of
					       observation)))))))

(html-inspector-views:defview 👀component-order
    (observation
     dreyeck/fedwiki-source-relations:fedwiki-source-relations-observation)
  (html-inspector-views:html-view :title "Component order" :priority 2
				  (let ((fedwiki-file
					  (dreyeck/fedwiki-source-relations:fedwiki-source-relations-file
					   observation "hyperbook-fedwiki/fedwiki.lisp"))
					(story-file
					  (dreyeck/fedwiki-source-relations:fedwiki-source-relations-file
					   observation "hyperbook-fedwiki/story-items.lisp"))
					(loads-relation
					  (find :loads-before
						(dreyeck/fedwiki-source-relations:fedwiki-source-relations-relations-of
						 observation)
						:key
						#'dreyeck/fedwiki-source-relations:typed-source-relation-type-of)))
				    (html-inspector-views:html
				      (:p
				       (html-inspector-views:esc
					"The serial order supports complete compile/load/use. It does not remove mutual source use."))
				      (:table :class "inspector-table"
					      (:tr
					       (:th (html-inspector-views:esc "Position"))
					       (:th (html-inspector-views:esc "Component"))
					       (:th (html-inspector-views:esc "Inspectable file")))
					      (loop for component
						      in (dreyeck/fedwiki-source-relations:fedwiki-source-relations-component-order-of
							  observation)
						    for position from 1
						    do (html-inspector-views:html
							 (:tr
							  (:td (html-inspector-views:esc
								(princ-to-string position)))
							  (:td (:code (html-inspector-views:esc component)))
							  (:td
							   (cond
							     ((string= component "fedwiki")
							      (html-inspector-views:object-ref fedwiki-file))
							     ((string= component "story-items")
							      (html-inspector-views:object-ref story-file))
							     (t (html-inspector-views:esc "")))))))
					      (:p
					       (html-inspector-views:esc "Observed relation: ")
					       (html-inspector-views:object-ref
						loads-relation
						:display "fedwiki.lisp — :loads-before → story-items.lisp"))
					      (:h3 (html-inspector-views:esc "What this routine solves"))
					      (:ul
					       (dolist
						   (effect
						    (dreyeck/fedwiki-source-relations:fedwiki-source-relations-routine-effects-of
						     observation))
						 (html-inspector-views:html
						   (:li (html-inspector-views:esc effect)))))
					      (:p
					       (html-inspector-views:object-ref
						(dreyeck/fedwiki-source-relations:fedwiki-source-relations-component-fragment-of
						 observation)
						:display "Open the authoritative ASDF fragment")))))))

(defun endpoint-file (endpoint)
  (etypecase endpoint
    (dreyeck/git:git-file-at-commit endpoint)
    (dreyeck/fedwiki-source-relations:definition-evidence
     (dreyeck/fedwiki-source-relations:definition-evidence-file-of endpoint))))

(defun derived-file-relation (relation relations)
  (find relation relations
        :key
        #'dreyeck/fedwiki-source-relations:typed-source-relation-derived-from-of
        :test #'eq))

(html-inspector-views:defview 👀source-relations
    (observation
     dreyeck/fedwiki-source-relations:fedwiki-source-relations-observation)
  (html-inspector-views:html-view :title "Source relations" :priority 3
				  (let ((relations
					  (dreyeck/fedwiki-source-relations:fedwiki-source-relations-relations-of
					   observation)))
				    (html-inspector-views:html
				      (:p
				       (html-inspector-views:esc
					"Every row is backed by an exact unevaluated Git-blob fragment. :USES-DEFINITION-FROM rows are explicit file-level derivations."))
				      (:table :class "inspector-table"
					      (:tr
					       (:th (html-inspector-views:esc "Relation"))
					       (:th (html-inspector-views:esc "Source definition"))
					       (:th (html-inspector-views:esc "Source file"))
					       (:th (html-inspector-views:esc "Target definition"))
					       (:th (html-inspector-views:esc "Target file"))
					       (:th (html-inspector-views:esc "Role"))
					       (:th (html-inspector-views:esc "Phases"))
					       (:th (html-inspector-views:esc "Ordering constraint"))
					       (:th (html-inspector-views:esc "Ordering basis"))
					       (:th (html-inspector-views:esc "Source fragment"))
					       (:th (html-inspector-views:esc "Derived file relation")))
					      (dolist (relation relations)
						(let* ((source
							 (dreyeck/fedwiki-source-relations:typed-source-relation-source-of
							  relation))
						       (target
							 (dreyeck/fedwiki-source-relations:typed-source-relation-target-of
							  relation))
						       (derived
							 (or
							  (dreyeck/fedwiki-source-relations:typed-source-relation-derived-from-of
							   relation)
							  (derived-file-relation relation relations))))
						  (html-inspector-views:html
						    (:tr
						     (:td
						      (html-inspector-views:object-ref
						       relation
						       :display
						       (prin1-to-string
							(dreyeck/fedwiki-source-relations:typed-source-relation-type-of
							 relation))))
						     (:td (html-inspector-views:object-ref source))
						     (:td (html-inspector-views:object-ref
							   (endpoint-file source)))
						     (:td (html-inspector-views:object-ref target))
						     (:td (html-inspector-views:object-ref
							   (endpoint-file target)))
						     (:td (:code
							   (html-inspector-views:esc
							    (prin1-to-string
							     (dreyeck/fedwiki-source-relations:typed-source-relation-role-of
							      relation)))))
						     (:td
						      (:code
						       (html-inspector-views:esc
							(prin1-to-string
							 (dreyeck/fedwiki-source-relations:typed-source-relation-phases-of
							  relation)))))
						     (:td
						      (:code
						       (html-inspector-views:esc
							(prin1-to-string
							 (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-constraint-of
							  relation)))))
						     (:td
						      (:code
						       (html-inspector-views:esc
							(prin1-to-string
							 (dreyeck/fedwiki-source-relations:typed-source-relation-ordering-basis-of
							  relation)))))
						     (:td
						      (html-inspector-views:object-ref
						       (dreyeck/fedwiki-source-relations:typed-source-relation-fragment-of
							relation)))
						     (:td
						      (if derived
							  (html-inspector-views:object-ref derived)
							  (html-inspector-views:esc "—"))))))))))))

(html-inspector-views:defview 👀refactoring-hypotheses
    (observation
     dreyeck/fedwiki-source-relations:fedwiki-source-relations-observation)
  (html-inspector-views:html-view :title "Refactoring hypotheses" :priority 5
				  (html-inspector-views:html
				    (:p
				     (html-inspector-views:esc
				      "These hypotheses are :NOT-EXECUTED. No production source was moved."))
				    (dolist
					(hypothesis
					 (dreyeck/fedwiki-source-relations:fedwiki-source-relations-hypotheses-of
					  observation))
				      (html-inspector-views:html
					(:section
					 (:h3
					  (html-inspector-views:object-ref
					   hypothesis
					   :display
					   (dreyeck/fedwiki-source-relations:refactoring-hypothesis-title-of
					    hypothesis)))
					 (:p (:code
					      (html-inspector-views:esc
					       (prin1-to-string
						(dreyeck/fedwiki-source-relations:refactoring-hypothesis-status-of
						 hypothesis)))))
					 (:p
					  (html-inspector-views:esc
					   (dreyeck/fedwiki-source-relations:refactoring-hypothesis-notes-of
					    hypothesis)))
					 (:h4 (html-inspector-views:esc "Definitions that would move"))
					 (render-object-list
					  (dreyeck/fedwiki-source-relations:refactoring-hypothesis-moved-definitions-of
					   hypothesis))
					 (:h4 (html-inspector-views:esc "Relations intended to change"))
					 (render-object-list
					  (dreyeck/fedwiki-source-relations:refactoring-hypothesis-removed-relations-of
					   hypothesis))
					 (:h4 (html-inspector-views:esc "Required regression tests"))
					 (:ul
					  (dolist
					      (test
					       (dreyeck/fedwiki-source-relations:refactoring-hypothesis-required-tests-of
						hypothesis))
					    (html-inspector-views:html
					      (:li (html-inspector-views:esc test)))))
					 (:p
					  (:strong (html-inspector-views:esc "Falsified if: "))
					  (html-inspector-views:esc
					   (dreyeck/fedwiki-source-relations:refactoring-hypothesis-falsifier-of
					    hypothesis)))))))))
