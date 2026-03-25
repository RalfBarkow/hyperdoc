;;;; Topic-to-Zotero enrichment route, plan, and report model
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass zotero-library-source-designator ()
  ((id :reader id-of
       :initarg :id
       :initform "zotero-library/default")
   (title :reader title-of
          :initarg :title
          :initform "Local Zotero library")
   (summary :reader summary-of
            :initarg :summary
            :initform
            "Read-only local Zotero library source designator that resolves through the existing default bridge wrapper.")
   (source-kind :reader topic-enrichment-source-kind-of
                :initarg :source-kind
                :initform :zotero-library)
   (bridge-provider :reader topic-enrichment-source-bridge-provider-of
                    :initarg :bridge-provider
                    :initform 'make-default-zotero-library-bridge)
   (notes :reader topic-enrichment-source-notes-of
          :initarg :notes
          :initform nil)))

(defclass topic-source-route ()
  ((topic :reader topic-source-route-topic-of
          :initarg :topic)
   (source-designator :reader topic-source-route-source-designator-of
                      :initarg :source-designator)
   (default-match-mode :reader topic-source-route-default-match-mode-of
                       :initarg :default-match-mode
                       :initform :exact)
   (annotation :reader topic-source-route-annotation-of
               :initarg :annotation
               :initform nil)
   (definition :reader topic-source-route-definition-of
               :initarg :definition
               :initform nil)))

(defclass topic-enrichment-query-plan ()
  ((route :reader topic-enrichment-plan-route-of
          :initarg :route)
   (source-topic :reader topic-enrichment-plan-source-topic-of
                 :initarg :source-topic)
   (source-designator :reader topic-enrichment-plan-source-designator-of
                      :initarg :source-designator)
   (query-text :reader topic-enrichment-plan-query-text-of
               :initarg :query-text)
   (match-mode :reader topic-enrichment-plan-match-mode-of
               :initarg :match-mode
               :initform :exact)
   (intended-bridge :reader topic-enrichment-plan-intended-bridge-of
                    :initarg :intended-bridge
                    :initform nil)
   (intended-backend :reader topic-enrichment-plan-intended-backend-of
                     :initarg :intended-backend
                     :initform "read-only Zotero title lookup")
   (expected-functions :reader topic-enrichment-plan-expected-functions-of
                       :initarg :expected-functions
                       :initform nil)
   (expected-objects :reader topic-enrichment-plan-expected-objects-of
                     :initarg :expected-objects
                     :initform nil)
   (execution-readiness :reader topic-enrichment-plan-execution-readiness-of
                        :initarg :execution-readiness
                        :initform :ready-to-attempt)
   (failure-classification
    :reader topic-enrichment-plan-failure-classification-of
    :initarg :failure-classification
    :initform nil)
   (repair-hint :reader topic-enrichment-plan-repair-hint-of
                :initarg :repair-hint
                :initform nil)
   (failure-evidence :reader topic-enrichment-plan-failure-evidence-of
                     :initarg :failure-evidence
                     :initform nil)
   (notes :reader topic-enrichment-plan-notes-of
          :initarg :notes
          :initform nil)))

(defclass topic-enrichment-editorial-consequence ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (kind :reader topic-enrichment-consequence-kind-of
         :initarg :kind
         :initform :note)
   (evidence :reader topic-enrichment-consequence-evidence-of
             :initarg :evidence
             :initform nil)))

(defclass topic-enrichment-report ()
  ((route :reader topic-enrichment-report-route-of
          :initarg :route)
   (plan :reader topic-enrichment-report-plan-of
         :initarg :plan)
   (source-topic :reader topic-enrichment-report-source-topic-of
                 :initarg :source-topic)
   (source-designator :reader topic-enrichment-report-source-designator-of
                      :initarg :source-designator)
   (query-text :reader topic-enrichment-report-query-text-of
               :initarg :query-text)
   (match-mode :reader topic-enrichment-report-match-mode-of
               :initarg :match-mode
               :initform :exact)
   (query-evidence :reader topic-enrichment-report-query-evidence-of
                   :initarg :query-evidence
                   :initform nil)
   (query-attempt :reader topic-enrichment-report-query-attempt-of
                  :initarg :query-attempt
                  :initform nil)
   (matched-items :reader topic-enrichment-report-matched-items-of
                  :initarg :matched-items
                  :initform nil)
   (candidate-signals :reader topic-enrichment-report-candidate-signals-of
                      :initarg :candidate-signals
                      :initform nil)
   (editorial-consequences
    :reader topic-enrichment-report-editorial-consequences-of
    :initarg :editorial-consequences
    :initform nil)
   (status :reader topic-enrichment-report-status-of
           :initarg :status
           :initform :blocked)
   (failure-classification
    :reader topic-enrichment-report-failure-classification-of
    :initarg :failure-classification
    :initform nil)
   (detail :reader topic-enrichment-report-detail-of
           :initarg :detail
           :initform nil)
   (generated-at :reader topic-enrichment-report-generated-at-of
                 :initarg :generated-at
                 :initform (get-universal-time))))

(defvar *topic-enrichment-latest-reports* (make-hash-table :test #'equal))
(defvar *topic-enrichment-latest-successful-reports*
  (make-hash-table :test #'equal))

(defmethod print-object ((object zotero-library-source-designator) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object topic-source-route) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object topic-enrichment-query-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object topic-enrichment-editorial-consequence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object topic-enrichment-report) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun topic-enrichment-match-mode-label (value)
  (string-downcase
   (substitute #\Space #\- (symbol-name value))))

(defun topic-enrichment-plan-readiness-label (value)
  (case value
    (:blocked "blocked")
    (:ready-to-attempt "ready-to-attempt")
    (otherwise
     (format nil "~A" value))))

(defun topic-enrichment-report-status-label (value)
  (string-downcase
   (substitute #\Space #\- (symbol-name value))))

(defun topic-enrichment-route-id (topic source-designator)
  (format nil "topic-source-route/~A/~A"
          (id-of topic)
          (id-of source-designator)))

(defmethod id-of ((route topic-source-route))
  (topic-enrichment-route-id
   (topic-source-route-topic-of route)
   (topic-source-route-source-designator-of route)))

(defmethod title-of ((route topic-source-route))
  (format nil "~A -> ~A"
          (title-of (topic-source-route-topic-of route))
          (title-of (topic-source-route-source-designator-of route))))

(defmethod summary-of ((route topic-source-route))
  (format nil
          "Durable relation object connecting topic ~A to source ~A before any live query runs."
          (title-of (topic-source-route-topic-of route))
          (title-of (topic-source-route-source-designator-of route))))

(defmethod id-of ((plan topic-enrichment-query-plan))
  (format nil "~A/plan/~A"
          (id-of (topic-enrichment-plan-route-of plan))
          (topic-enrichment-match-mode-label
           (topic-enrichment-plan-match-mode-of plan))))

(defmethod title-of ((plan topic-enrichment-query-plan))
  (format nil "Topic enrichment plan for ~A"
          (title-of (topic-enrichment-plan-source-topic-of plan))))

(defmethod summary-of ((plan topic-enrichment-query-plan))
  (format nil
          "Inspectable query plan for ~A through ~A using ~A title matching."
          (title-of (topic-enrichment-plan-source-topic-of plan))
          (title-of (topic-enrichment-plan-source-designator-of plan))
          (topic-enrichment-match-mode-label
           (topic-enrichment-plan-match-mode-of plan))))

(defmethod title-of ((report topic-enrichment-report))
  (format nil "Topic enrichment report for ~A"
          (title-of (topic-enrichment-report-source-topic-of report))))

(defmethod summary-of ((report topic-enrichment-report))
  (format nil
          "Inspectable report for ~A with status ~A."
          (title-of (topic-enrichment-report-source-topic-of report))
          (topic-enrichment-report-status-label
           (topic-enrichment-report-status-of report))))

(defun topic-enrichment-report-id (plan)
  (format nil "~A/report" (id-of plan)))

(defmethod id-of ((report topic-enrichment-report))
  (topic-enrichment-report-id
   (topic-enrichment-report-plan-of report)))

(defun topic-enrichment-route-key (route)
  (id-of route))

(defun make-zotero-library-source-designator
    (&key (id "zotero-library/default")
       (title "Local Zotero library")
       (summary
         "Read-only local Zotero library source designator that resolves through the existing default bridge wrapper.")
       (source-kind :zotero-library)
       (bridge-provider 'make-default-zotero-library-bridge)
       notes)
  (make-instance 'zotero-library-source-designator
                 :id id
                 :title title
                 :summary summary
                 :source-kind source-kind
                 :bridge-provider bridge-provider
                 :notes notes))

(defun default-topic-enrichment-source-designators ()
  (list (make-zotero-library-source-designator)))

(defun find-topic-enrichment-source-designator-by-id (id)
  (find id
        (default-topic-enrichment-source-designators)
        :key #'id-of
        :test #'string=))

(defclass topic-enrichment-route-definition ()
  ((id :reader topic-enrichment-route-definition-id-of
       :initarg :id)
   (topic :reader topic-enrichment-route-definition-topic-of
          :initarg :topic)
   (source-designator :reader topic-enrichment-route-definition-source-designator-of
                      :initarg :source-designator)
   (relation-kind :reader topic-enrichment-route-definition-relation-kind-of
                  :initarg :relation-kind)
   (notes :reader topic-enrichment-route-definition-notes-of
          :initarg :notes)))

(defmethod id-of ((definition topic-enrichment-route-definition))
  (topic-enrichment-route-definition-id-of definition))

(defmethod title-of ((definition topic-enrichment-route-definition))
  (format nil "~A -> ~A durable route definition"
          (title-of (topic-enrichment-route-definition-topic-of definition))
          (title-of
           (topic-enrichment-route-definition-source-designator-of definition))))

(defmethod summary-of ((definition topic-enrichment-route-definition))
  (format nil
          "Durable authored route-definition entry for topic ~A and source ~A."
          (title-of (topic-enrichment-route-definition-topic-of definition))
          (title-of
           (topic-enrichment-route-definition-source-designator-of definition))))

(defun make-topic-enrichment-route-definition (entry)
   (let* ((topic (find-topic-by-id (getf entry :topic-id) :signal-error? t))
         (source (or (find-topic-enrichment-source-designator-by-id
                      (getf entry :source-id))
                     (find-topic-enrichment-source-designator-by-id
                      (id-of (first (default-topic-enrichment-source-designators))))
                     (error "Unknown source designator ~S" (getf entry :source-id))))
        (notes (getf entry :notes))
        (relation-kind (or (getf entry :relation-kind)
                          "topic-enrichment-route")))
    (make-instance 'topic-enrichment-route-definition
                   :id (getf entry :id)
                   :topic topic
                   :source-designator source
                   :relation-kind relation-kind
                   :notes notes)))

(defun topic-enrichment-route-definitions ()
  (mapcar #'make-topic-enrichment-route-definition
          *topic-enrichment-route-definitions*))

(defun topic-enrichment-route-definitions-for-topic (topic)
  (let ((topic-id (typecase topic
                    (null nil)
                    (string topic)
                    (otherwise (id-of topic)))))
    (when topic-id
      (mapcar #'make-topic-enrichment-route-definition
              (topic-enrichment-route-definition-entries-for-topic-id
               topic-id)))))

(defun topic-source-route-from-definition (definition)
  (make-topic-source-route
   (topic-enrichment-route-definition-topic-of definition)
   (topic-enrichment-route-definition-source-designator-of definition)
   :annotation (topic-enrichment-route-annotation definition)
   :definition definition))

(defun topic-source-route-durable-routes-for-topic (topic)
  (mapcar #'topic-source-route-from-definition
          (topic-enrichment-route-definitions-for-topic topic)))

(defun topic-source-route-durable-route-for-topic-source
    (topic source-designator)
  (find (id-of source-designator)
        (topic-source-route-durable-routes-for-topic topic)
        :key (lambda (route)
               (id-of (topic-source-route-source-designator-of route)))
        :test #'string=))

(defun topic-enrichment-route-anchor (object provider-kind view-kind view-title)
  (make-instance 'dom-annotation-anchor
                 :provider-kind provider-kind
                 :view-kind view-kind
                 :view-title view-title
                 :context-object-id (id-of object)
                 :value (id-of object)))

(defun topic-enrichment-route-topic-anchor (definition)
  (topic-enrichment-route-anchor
   (topic-enrichment-route-definition-topic-of definition)
   "touch-fahrplan"
   "topic"
   (title-of (topic-enrichment-route-definition-topic-of definition))))

(defun topic-enrichment-route-source-anchor (definition)
  (topic-enrichment-route-anchor
   (topic-enrichment-route-definition-source-designator-of definition)
   "touch-fahrplan"
   "zotero-source"
   (title-of (topic-enrichment-route-definition-source-designator-of definition))))

(defun topic-enrichment-route-annotation (definition)
  (make-dom-relation-annotation
   :context-object (topic-enrichment-route-definition-topic-of definition)
   :context-view-title "Touch-Fahrplan route"
   :source-anchor (topic-enrichment-route-topic-anchor definition)
   :target-anchor (topic-enrichment-route-source-anchor definition)
   :relation-kind (topic-enrichment-route-definition-relation-kind-of definition)
   :note (topic-enrichment-route-definition-notes-of definition)))

(defun topic-enrichment-route-definition-topic-id-of (definition)
  (id-of (topic-enrichment-route-definition-topic-of definition)))

(defun topic-enrichment-route-definition-source-id-of (definition)
  (id-of (topic-enrichment-route-definition-source-designator-of definition)))

(defun topic-enrichment-route-definition-id-fragment (value)
  (string-downcase
   (substitute #\- #\/ value)))

(defun topic-enrichment-route-definition-entry-id (topic source-designator)
  (format nil "route/~A-~A"
          (topic-enrichment-route-definition-id-fragment (id-of topic))
          (topic-enrichment-route-definition-id-fragment
           (id-of source-designator))))

(defun make-topic-enrichment-route-definition-entry
    (topic source-designator &key notes relation-kind)
  (list :id (topic-enrichment-route-definition-entry-id topic source-designator)
        :topic-id (id-of topic)
        :source-id (id-of source-designator)
        :relation-kind (or relation-kind "topic-enrichment-route")
        :notes (or notes
                   (format nil
                           "Runtime-authored durable Touch-Fahrplan route for ~A."
                           (title-of topic)))))

(defun persist-topic-enrichment-route-definition!
    (topic source-designator &key notes relation-kind)
  (reload-topic-enrichment-route-definitions!)
  (let* ((topic-id (id-of topic))
         (source-id (id-of source-designator))
         (existing-entry
           (topic-enrichment-route-entry-for-topic-source topic-id source-id))
         (entry (or existing-entry
                    (make-topic-enrichment-route-definition-entry
                     topic
                     source-designator
                     :notes notes
                     :relation-kind relation-kind))))
    (unless existing-entry
      (write-topic-enrichment-route-definitions!
       (append *topic-enrichment-route-definitions*
               (list entry))))
    (make-topic-enrichment-route-definition entry)))

(defun create-durable-topic-source-route!
    (topic source-designator &key notes relation-kind)
  (topic-source-route-from-definition
   (persist-topic-enrichment-route-definition!
    topic
    source-designator
    :notes notes
    :relation-kind relation-kind)))

(defun resolve-topic-enrichment-source-bridge (source-designator)
  (let ((provider (topic-enrichment-source-bridge-provider-of source-designator)))
    (handler-case
        (cond
          ((and (symbolp provider)
                (fboundp provider))
           (funcall provider))
          ((functionp provider)
           (funcall provider))
          (t
           provider))
      (error (condition)
        (make-zotero-backend-unavailable
         "topic enrichment bridge resolution"
         :detail (princ-to-string condition))))))

(defun topic-enrichment-plan-classification-from-unavailable (object)
  (case (zotero-backend-unavailable-reason-of object)
    (:disabled-by-configuration
     "zotero-disabled-by-configuration")
    (:load-failed
     "zotero-backend-load-failed")
    (otherwise
     "zotero-backend-unavailable")))

(defun topic-enrichment-plan-repair-hint-from-unavailable (object)
  (or (zotero-backend-unavailable-message-of object)
      "Inspect the optional Zotero runtime boundary before attempting topic enrichment."))

(defun make-topic-source-route
    (topic source-designator &key (default-match-mode :exact)
           annotation definition)
  (make-instance 'topic-source-route
                 :topic topic
                 :source-designator source-designator
                 :default-match-mode default-match-mode
                 :annotation annotation
                 :definition definition))

(defun topic-source-route-default-plan (route)
  (make-topic-enrichment-query-plan
   route
   :match-mode (topic-source-route-default-match-mode-of route)))

(defun topic-source-route-explicit-loose-plan (route)
  (make-topic-enrichment-query-plan route :match-mode :loose))

(defun topic-source-route-latest-report (route)
  (gethash (topic-enrichment-route-key route)
           *topic-enrichment-latest-reports*))

(defun topic-source-route-latest-successful-report (route)
  (gethash (topic-enrichment-route-key route)
           *topic-enrichment-latest-successful-reports*))

(defun topic-enrichment-report-successful-p (report)
  (eq (topic-enrichment-report-status-of report) :matched))

(defun record-topic-enrichment-report (report)
  (let ((key (topic-enrichment-route-key
              (topic-enrichment-report-route-of report))))
    (setf (gethash key *topic-enrichment-latest-reports*) report)
    (when (topic-enrichment-report-successful-p report)
      (setf (gethash key *topic-enrichment-latest-successful-reports*)
            report)))
  report)

(defun make-topic-enrichment-query-plan
    (route &key (match-mode (topic-source-route-default-match-mode-of route)))
  (let* ((topic (topic-source-route-topic-of route))
         (source-designator (topic-source-route-source-designator-of route))
         (bridge (resolve-topic-enrichment-source-bridge source-designator))
         (blocked-p (zotero-backend-unavailable-p bridge)))
    (make-instance 'topic-enrichment-query-plan
                   :route route
                   :source-topic topic
                   :source-designator source-designator
                   :query-text (title-of topic)
                   :match-mode match-mode
                   :intended-bridge bridge
                   :expected-functions
                   (list (topic-enrichment-source-bridge-provider-of
                          source-designator)
                         'lookup-zotero-items-by-title
                         'execute-topic-enrichment-query-plan
                         'record-topic-enrichment-report)
                   :expected-objects
                   '(topic-source-route
                     topic-enrichment-query-plan
                     topic-enrichment-report)
                   :execution-readiness (if blocked-p
                                            :blocked
                                            :ready-to-attempt)
                   :failure-classification
                   (and blocked-p
                        (topic-enrichment-plan-classification-from-unavailable
                         bridge))
                   :repair-hint
                   (and blocked-p
                        (topic-enrichment-plan-repair-hint-from-unavailable
                         bridge))
                   :failure-evidence (and blocked-p bridge)
                   :notes
                   '("The plan is inspectable before any live Zotero query runs."
                     "Exact title matching is the conservative default."
                     "The explicit loose follow-up plan is opt-in and separately inspectable."))))

(defun make-topic-enrichment-editorial-consequence
    (&key id title summary kind evidence)
  (make-instance 'topic-enrichment-editorial-consequence
                 :id id
                 :title title
                 :summary summary
                 :kind kind
                 :evidence evidence))

(defun make-topic-enrichment-blocked-report
    (plan failure &key (status :blocked) detail)
  (make-instance 'topic-enrichment-report
                 :route (topic-enrichment-plan-route-of plan)
                 :plan plan
                 :source-topic (topic-enrichment-plan-source-topic-of plan)
                 :source-designator
                 (topic-enrichment-plan-source-designator-of plan)
                 :query-text (topic-enrichment-plan-query-text-of plan)
                 :match-mode (topic-enrichment-plan-match-mode-of plan)
                 :query-evidence nil
                 :query-attempt failure
                 :matched-items nil
                 :candidate-signals nil
                 :editorial-consequences
                 (list
                  (make-topic-enrichment-editorial-consequence
                   :id (format nil "~A/blocked"
                               (id-of (topic-enrichment-plan-route-of plan)))
                   :title "No editorial change yet"
                   :summary
                   "The route remains inspectable, but HyperDoc should not treat Zotero as editorial truth until the live query boundary is reachable."
                   :kind :no-change
                   :evidence (list failure plan)))
                 :status status
                 :failure-classification
                 (if (zotero-backend-unavailable-p failure)
                     (topic-enrichment-plan-classification-from-unavailable
                      failure)
                     "topic-enrichment-execution-blocked")
                 :detail
                 (or detail
                     (and (zotero-backend-unavailable-p failure)
                          (zotero-backend-unavailable-message-of failure))
                     "Topic enrichment execution is blocked before the live Zotero query step.")))

(defun run-topic-enrichment-query-plan (plan)
  (let* ((result (execute-topic-enrichment-query-plan plan))
         (report (cond
                   ((typep result 'topic-enrichment-report)
                    result)
                   ((zotero-backend-unavailable-p result)
                    (make-topic-enrichment-blocked-report plan result))
                   (t
                    (make-topic-enrichment-blocked-report
                     plan
                     (make-zotero-backend-unavailable
                      "topic enrichment execution"
                      :detail (format nil "Unexpected execution result: ~S"
                                      result))
                     :status :blocked
                     :detail
                     "Topic enrichment execution returned an unexpected non-report object.")))))
    (record-topic-enrichment-report report)))

(defun chunk-topic-source-route ()
  (make-topic-source-route
   (chunk-topic)
   (make-zotero-library-source-designator)))

(defun chunk-topic-enrichment-query-plan ()
  (topic-source-route-default-plan (chunk-topic-source-route)))

(defun chunk-topic-enrichment-report ()
  (run-topic-enrichment-query-plan
   (chunk-topic-enrichment-query-plan)))
