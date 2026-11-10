(in-package #:dreyeck/work/welcome-development)

(defun development-topicmap (run)
  "A native projection retaining EQ links to records, invocation carriers and the result."
  (let* ((result (development-plan-result run))
         (topics (list (dreyeck/topicmap:make-topicmap-topic
                        :id "development" :type :development-run
                        :label "Welcome development — plan only" :object run
                        :view-properties '(:x 180 :y 60 :visible t))
                       (dreyeck/topicmap:make-topicmap-topic
                        :id "plans" :type :planning-result
                        :label "All next-action alternatives" :object result
                        :view-properties '(:x 660 :y 60 :visible t))))
         (edges (list (dreyeck/topicmap:make-topicmap-association
                       :id "planning" :type :planning :from "development" :to "plans"
                       :properties '(:epistemic-status :derived))))
         (counter 0))
    (labels ((add (object label kind status from)
               (let ((id (format nil "development-object-~D" (incf counter))))
                 (push (dreyeck/topicmap:make-topicmap-topic
                        :id id :type kind :label label :object object
                        :view-properties (list :x (if (eq kind :alternative) 660 180)
                                               :y (+ 140 (* 70 counter)) :visible t)) topics)
                 (push (dreyeck/topicmap:make-topicmap-association
                        :id (concatenate 'string "edge-" id) :type kind :from from :to id
                        :properties (list :epistemic-status status)) edges)
                 id)))
      (dolist (entry (development-records run))
        (let* ((record (observed-record-value entry))
               (id (add entry (format nil "~A" (if record (record-id record) "Checker invocation"))
                        :record (if (typep record 'dev-submission) :claimed
                                    (if (and record (eq :fixture (record-source record)))
                                        :hypothesized :observed)) "development")))
          (when (and record (not (eq entry record)))
            (add record (format nil "Returned record ~A" (record-id record)) :returned-record
                 (if (eq :fixture (record-source record)) :hypothesized :observed) id))))
      (dolist (alternative (development-next-action-view run))
        (add alternative (format nil "~S ~S" (getf alternative :classification)
                                  (getf alternative :step))
             :alternative :hypothesized "plans"))
      (dolist (validation (development-assignment-validations run))
        (add validation (format nil "Proposal validation: ~A" (record-id (getf validation :assignment)))
             :assignment-validation :derived "development")))
    (dreyeck/topicmap:make-topicmap-projection :source run :topics (nreverse topics)
                                             :associations (nreverse edges))))

(defmethod dreyeck/topicmap:topicmap-projection-of ((run development-run))
  (development-topicmap run))

(html-inspector-views:defview development-next-actions (run development-run)
  (html-inspector-views:html-view :title "Development next actions" :priority 0
    (html-inspector-views:html
      (:h2 "Welcome development — proposals only")
      (:p (html-inspector-views:esc
           (format nil "~S. ~D alternatives. This planning cycle has executed no action."
                   (development-outcome run) (length (development-next-action-view run)))))
      (:p (html-inspector-views:object-ref (development-plan-result run) :display "Native SHOP3 result")
          " · " (html-inspector-views:object-ref (development-initial-state run) :display "Record-derived initial state")
          " · " (html-inspector-views:object-ref (development-assignment-validations run)
                                                :display "Assignment proposal validations")
          " · " (html-inspector-views:object-ref (development-topicmap run) :display "Development Topicmap"))
      (dolist (entry (development-records run))
        (html-inspector-views:html
          (:p (html-inspector-views:object-ref entry)
              (let ((record (observed-record-value entry)))
                (when (and record (not (eq entry record)))
                  (html-inspector-views:html
                    " " (html-inspector-views:object-ref record :display "Returned record"))))
              (html-inspector-views:esc
               (let ((record (observed-record-value entry)))
                 (format nil " Provenance: ~S" (and record (record-source record))))))))
      (dolist (alternative (development-next-action-view run))
        (html-inspector-views:html
          (:p (html-inspector-views:esc
               (format nil "Alternative ~D — ~S: ~S"
                       (getf alternative :index) (getf alternative :classification)
                       (getf alternative :step)))
              " " (html-inspector-views:object-ref alternative :display "Inspect this alternative")))))))
