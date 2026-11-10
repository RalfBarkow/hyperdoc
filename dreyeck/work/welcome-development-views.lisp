(in-package #:dreyeck/work/welcome-development)

(defun development-topicmap (run)
  "A native projection retaining EQ links to records, invocation carriers and the result."
  (let* ((result (development-plan-result run))
         (topics (list (dreyeck/topicmap:make-topicmap-topic
                        :id "development" :type :development-run
                        :label "Welcome development — plan only" :object run
                        :view-properties (list :x 180 :y 60 :visible t
                                               :current-domain-version (development-current-domain-version run)))
                       (dreyeck/topicmap:make-topicmap-topic
                        :id "plans" :type :planning-result
                        :label "All next-action alternatives" :object result
                        :view-properties '(:x 660 :y 60 :visible t))))
         (edges (list (dreyeck/topicmap:make-topicmap-association
                       :id "planning" :type :planning :from "development" :to "plans"
                       :properties '(:epistemic-status :derived))))
         (counter 0) (version-topics (make-hash-table :test #'equal)))
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
      (maphash
       (lambda (id version)
         (let* ((observed (eq :observed (record-source (domain-version-record version))))
                (topic (add version (format nil "Domain version ~A" id) :domain-version
                            (if observed :observed :hypothesized) "development")))
           (setf (gethash id version-topics) topic)
           (when (domain-version-commit version)
             (add (domain-version-commit version) "Tagged Git commit" :git-commit :observed topic))))
       (development-domain-versions run))
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
        (let ((topic (add validation (format nil "Proposal validation: ~A" (record-id (getf validation :assignment)))
                          :assignment-validation :derived "development")))
          (push (dreyeck/topicmap:make-topicmap-association
                 :id (format nil "assignment-version-~D" counter) :type :uses-domain-version :from topic
                 :to (gethash (domain-version-identity (getf validation :domain-version)) version-topics)
                 :properties '(:epistemic-status :derived)) edges)))
      (dolist (check (development-submission-checks run))
        (let ((topic (add check "Submission proposal check" :submission-check :derived "development")))
          (push (dreyeck/topicmap:make-topicmap-association
                 :id (format nil "submission-version-~D" counter) :type :uses-domain-version :from topic
                 :to (gethash (domain-version-identity (getf check :domain-version)) version-topics)
                 :properties '(:epistemic-status :derived)) edges))))
    (dreyeck/topicmap:make-topicmap-projection :source run :topics (nreverse topics)
                                             :associations (nreverse edges))))

(defmethod dreyeck/topicmap:topicmap-projection-of ((run development-run))
  (development-topicmap run))

(html-inspector-views:defview development-next-actions (run development-run)
  (html-inspector-views:html-view :title "Development next actions" :priority 0
    (html-inspector-views:html
      (:h2 "Welcome development — proposals only")
      (:p "Planning domain replayed by version; record validation uses the current validator.")
      (:p (html-inspector-views:esc
           (format nil "Current domain version: ~A. Current version tagged: ~S."
                   (development-current-domain-version run) (development-current-version-tagged run))))
      (:p (html-inspector-views:object-ref (development-validator-source run) :display "Current validator source"))
      (maphash (lambda (id version)
                 (html-inspector-views:html
                   (:p (html-inspector-views:object-ref version :display (format nil "Domain version ~A" id))
                       " " (html-inspector-views:object-ref (domain-version-record version) :display "Version record")
                       " " (when (domain-version-commit version)
                              (html-inspector-views:object-ref (domain-version-commit version) :display "Tagged commit")))))
               (development-domain-versions run))
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

(html-inspector-views:defview development-domain-provenance (version development-domain-version)
  (html-inspector-views:html-view :title "Planning domain provenance" :priority 0
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc (domain-version-identity version)))
      (:p "Planning domain replayed by version; record validation uses the current validator.")
      (:p (html-inspector-views:object-ref (domain-version-record version) :display "Retained version record")
          " " (when (domain-version-commit version)
                 (html-inspector-views:object-ref (domain-version-commit version) :display "Tagged Git commit")))
      (:p (html-inspector-views:esc
           (format nil "~S; tag ~S; blob ~S; form SHA256 ~A; screen ~S; planner ~S. Tag signatures are not verified."
                   (if (eq :fixture (record-source (domain-version-record version))) :hypothesized :observed)
                   (domain-version-tag-provenance version) (domain-version-blob version)
                   (domain-version-form-digest version) (domain-version-screen version) (domain-version-planner version))))
      (:p (html-inspector-views:object-ref (domain-version-domain version) :display "Private SHOP3 domain")))))
