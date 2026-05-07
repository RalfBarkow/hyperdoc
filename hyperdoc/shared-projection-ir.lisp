;;;; Shared Projection IR and Behavior IR for HyperDoc
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *shared-projection-ir-schema-version* 1)

(defun shared-projection-json-object ()
  (make-hash-table :test #'equal))

(defun shared-projection-json-set (table key value)
  (setf (gethash key table) value)
  table)

(defun shared-projection-json-field (object &rest keys)
  (when (hash-table-p object)
    (loop for key in keys
          for value = (gethash key object)
          when (or value
                   (nth-value 1 (gethash key object)))
          do (return value))))

(defun shared-projection-list (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (list value))))

(defun shared-projection-string (value)
  (cond
    ((null value) nil)
    ((stringp value) value)
    ((keywordp value) (string-downcase (string value)))
    ((symbolp value) (string-downcase (string value)))
    (t (format nil "~A" value))))

(defun shared-projection-role-value (value)
  (cond
    ((keywordp value) value)
    ((symbolp value) (intern (string-upcase (string value)) :keyword))
    ((stringp value) (intern (string-upcase value) :keyword))
    (t value)))

(defun shared-projection-copy-json-value (value)
  (cond
    ((hash-table-p value)
     (let ((copy (shared-projection-json-object)))
       (maphash (lambda (key child)
                  (setf (gethash key copy)
                        (shared-projection-copy-json-value child)))
                value)
       copy))
    ((vectorp value)
     (map 'vector #'shared-projection-copy-json-value value))
    ((listp value)
     (mapcar #'shared-projection-copy-json-value value))
    (t value)))

(defun shared-projection-xml-escape (value)
  (let ((text (format nil "~A" value)))
    (with-output-to-string (stream)
      (loop for char across text
            do (write-string
                (case char
                  (#\< "&lt;")
                  (#\> "&gt;")
                  (#\& "&amp;")
                  (#\" "&quot;")
                  (t (string char)))
                stream)))))

(defun shared-projection-xml-unescape (value)
  (let ((text (or value "")))
    (labels ((replace-all (string needle replacement)
               (with-output-to-string (stream)
                 (loop with start = 0
                       for pos = (search needle string :start2 start :test #'char=)
                       do (if pos
                              (progn
                                (write-string string stream :start start :end pos)
                                (write-string replacement stream)
                                (setf start (+ pos (length needle))))
                              (progn
                                (write-string string stream :start start)
                                (return))))))
             (unescape (string)
               (-> string
                   (replace-all "&quot;" "\"")
                   (replace-all "&gt;" ">")
                   (replace-all "&lt;" "<")
                   (replace-all "&amp;" "&"))))
      (unescape text))))

(defun shared-projection-extract-xml-attribute (line attribute)
  (let* ((marker (format nil "~A=\"" attribute))
         (start (search marker line :test #'char=)))
    (when start
      (let* ((value-start (+ start (length marker)))
             (value-end (position #\" line :start value-start)))
        (when value-end
          (shared-projection-xml-unescape
           (subseq line value-start value-end)))))))

(defclass shared-projection-provenance ()
  ((id :reader id-of
       :initarg :id
       :initform nil)
   (title :reader title-of
          :initarg :title
          :initform "Shared projection provenance")
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (source-kind :reader shared-projection-provenance-source-kind-of
                :initarg :source-kind)
   (source-id :reader shared-projection-provenance-source-id-of
              :initarg :source-id)
   (derivation-kind :reader shared-projection-provenance-derivation-kind-of
                    :initarg :derivation-kind
                    :initform nil)
   (confidence :reader shared-projection-provenance-confidence-of
               :initarg :confidence
               :initform nil)
   (replay-hash :reader shared-projection-provenance-replay-hash-of
                :initarg :replay-hash
                :initform nil)))

(defclass shared-projection-workspace-assignment ()
  ((id :reader id-of
       :initarg :id
       :initform nil)
   (title :reader title-of
          :initarg :title
          :initform "Workspace assignment")
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (workspace-id :reader shared-projection-workspace-assignment-workspace-id-of
                 :initarg :workspace-id
                 :initform nil)
   (workspace-name :reader shared-projection-workspace-assignment-workspace-name-of
                   :initarg :workspace-name
                   :initform nil)
   (assignment-status :reader shared-projection-workspace-assignment-status-of
                      :initarg :assignment-status
                      :initform nil)))

(defclass shared-projection-topicmap-membership ()
  ((id :reader id-of
       :initarg :id
       :initform nil)
   (title :reader title-of
          :initarg :title
          :initform "Topicmap membership")
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (topicmap-id :reader shared-projection-topicmap-membership-topicmap-id-of
                :initarg :topicmap-id)
   (assoc-id :reader shared-projection-topicmap-membership-assoc-id-of
             :initarg :assoc-id
             :initform nil)
   (view-props :reader shared-projection-topicmap-membership-view-props-of
               :initarg :view-props
               :initform nil)))

(defclass shared-projection-role-binding ()
  ((role :reader shared-projection-role-binding-role-of
         :initarg :role)
   (entity-id :reader shared-projection-role-binding-entity-id-of
              :initarg :entity-id)))

(defclass shared-projection-entity ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (type :reader shared-projection-entity-type-of
         :initarg :type)
   (attrs :reader shared-projection-entity-attrs-of
          :initarg :attrs
          :initform nil)
   (owner-class :reader shared-projection-entity-owner-class-of
                :initarg :owner-class
                :initform nil)
   (workspace-assignment
    :reader shared-projection-entity-workspace-assignment-of
    :initarg :workspace-assignment
    :initform nil)
   (topicmap-memberships
    :reader shared-projection-entity-topicmap-memberships-of
    :initarg :topicmap-memberships
    :initform nil)
   (provenance :reader shared-projection-entity-provenance-of
               :initarg :provenance
               :initform nil)
   (journal-subject-key :reader shared-projection-entity-journal-subject-key-of
                        :initarg :journal-subject-key
                        :initform nil)))

(defclass shared-projection-relation ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title
          :initform nil)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (type :reader shared-projection-relation-type-of
         :initarg :type)
   (roles :reader shared-projection-relation-roles-of
          :initarg :roles
          :initform nil)
   (attrs :reader shared-projection-relation-attrs-of
          :initarg :attrs
          :initform nil)
   (provenance :reader shared-projection-relation-provenance-of
               :initarg :provenance
               :initform nil)))

(defclass shared-projection-journal-event ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title
          :initform "Shared projection journal event")
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (subject-key :reader shared-projection-journal-event-subject-key-of
                :initarg :subject-key)
   (timestamp :reader shared-projection-journal-event-timestamp-of
              :initarg :timestamp)
   (operation :reader shared-projection-journal-event-operation-of
              :initarg :operation)
   (target-id :reader shared-projection-journal-event-target-id-of
              :initarg :target-id
              :initform nil)
   (payload :reader shared-projection-journal-event-payload-of
            :initarg :payload
            :initform nil)
   (derivation-kind :reader shared-projection-journal-event-derivation-kind-of
                    :initarg :derivation-kind
                    :initform nil)
   (replay-status :reader shared-projection-journal-event-replay-status-of
                  :initarg :replay-status
                  :initform nil)))

(defclass behavior-guard ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title
          :initform nil)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (expression :reader behavior-guard-expression-of
               :initarg :expression
               :initform nil)))

(defclass behavior-event ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title
          :initform nil)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (payload-shape :reader behavior-event-payload-shape-of
                  :initarg :payload-shape
                  :initform nil)))

(defclass behavior-state (state-machine-state)
  ((region :reader behavior-state-region-of
           :initarg :region
           :initform nil)))

(defclass behavior-transition (state-machine-transition)
  ((event-id :reader behavior-transition-event-id-of
             :initarg :event-id
             :initform nil)
   (guard-id :reader behavior-transition-guard-id-of
             :initarg :guard-id
             :initform nil)
   (evidence-note :reader behavior-transition-evidence-note-of
                  :initarg :evidence-note
                  :initform nil)))

(defclass behavior-machine-definition (state-machine-definition)
  ((guard-objects :reader behavior-machine-definition-guard-objects-of
                  :initarg :guard-objects
                  :initform nil)
   (event-objects :reader behavior-machine-definition-event-objects-of
                  :initarg :event-objects
                  :initform nil)
   (regions :reader behavior-machine-definition-regions-of
            :initarg :regions
            :initform nil)
   (history-mode :reader behavior-machine-definition-history-mode-of
                 :initarg :history-mode
                 :initform nil)
   (scxml-text :accessor behavior-machine-definition-scxml-text-of
               :initarg :scxml-text
               :initform nil)))

(defclass behavior-trace-entry ()
  ((from-state :reader behavior-trace-entry-from-state-of
               :initarg :from-state
               :initform nil)
   (to-state :reader behavior-trace-entry-to-state-of
             :initarg :to-state
             :initform nil)
   (transition-id :reader behavior-trace-entry-transition-id-of
                  :initarg :transition-id
                  :initform nil)
   (timestamp :reader behavior-trace-entry-timestamp-of
              :initarg :timestamp
              :initform nil)
   (kind :reader behavior-trace-entry-kind-of
         :initarg :kind
         :initform :transition)
   (note :reader behavior-trace-entry-note-of
         :initarg :note
         :initform nil)
   (evidence :reader behavior-trace-entry-evidence-of
             :initarg :evidence
             :initform nil)))

(defclass behavior-trace ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title
          :initform "Behavior trace")
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (run-id :reader behavior-trace-run-id-of
           :initarg :run-id
           :initform nil)
   (entries :reader behavior-trace-entries-of
            :initarg :entries
            :initform nil)))

(defclass behavior-run (state-machine-run)
  ((machine-id :reader behavior-run-machine-id-of
               :initarg :machine-id
               :initform nil)
   (behavior-trace :reader behavior-run-trace-of
                   :initarg :behavior-trace
                   :initform nil)
   (started-at :reader behavior-run-started-at-of
               :initarg :started-at
               :initform nil)
   (ended-at :reader behavior-run-ended-at-of
             :initarg :ended-at
             :initform nil)))

(defclass shared-projection-context-window ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title
          :initform "Shared projection context window")
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (workspace-name :reader shared-projection-context-window-workspace-name-of
                   :initarg :workspace-name)
   (topicmap-id :reader shared-projection-context-window-topicmap-id-of
                :initarg :topicmap-id
                :initform nil)
   (focus-entity-ids
    :reader shared-projection-context-window-focus-entity-ids-of
    :initarg :focus-entity-ids
    :initform nil)
   (entity-ids :reader shared-projection-context-window-entity-ids-of
               :initarg :entity-ids
               :initform nil)
   (relation-ids :reader shared-projection-context-window-relation-ids-of
                 :initarg :relation-ids
                 :initform nil)
   (active-behavior-machine-ids
    :reader shared-projection-context-window-active-behavior-machine-ids-of
    :initarg :active-behavior-machine-ids
    :initform nil)
   (projection-status :reader shared-projection-context-window-projection-status-of
                      :initarg :projection-status
                      :initform nil)
   (source-endpoints :reader shared-projection-context-window-source-endpoints-of
                     :initarg :source-endpoints
                     :initform nil)
   (entities :reader shared-projection-context-window-entities-of
             :initarg :entities
             :initform nil)
   (relations :reader shared-projection-context-window-relations-of
              :initarg :relations
              :initform nil)
   (behavior-machines :reader shared-projection-context-window-behavior-machines-of
                      :initarg :behavior-machines
                      :initform nil)
   (behavior-runs :reader shared-projection-context-window-behavior-runs-of
                  :initarg :behavior-runs
                  :initform nil)
   (behavior-traces :reader shared-projection-context-window-behavior-traces-of
                    :initarg :behavior-traces
                    :initform nil)
   (journal-events :reader shared-projection-context-window-journal-events-of
                   :initarg :journal-events
                   :initform nil)))

(defun make-shared-projection-provenance
    (&key id title summary source-kind source-id derivation-kind confidence replay-hash)
  (make-instance 'shared-projection-provenance
                 :id id
                 :title title
                 :summary summary
                 :source-kind source-kind
                 :source-id source-id
                 :derivation-kind derivation-kind
                 :confidence confidence
                 :replay-hash replay-hash))

(defun make-shared-projection-workspace-assignment
    (&key id title summary workspace-id workspace-name assignment-status)
  (make-instance 'shared-projection-workspace-assignment
                 :id id
                 :title title
                 :summary summary
                 :workspace-id workspace-id
                 :workspace-name workspace-name
                 :assignment-status assignment-status))

(defun make-shared-projection-topicmap-membership
    (&key id title summary topicmap-id assoc-id view-props)
  (make-instance 'shared-projection-topicmap-membership
                 :id id
                 :title title
                 :summary summary
                 :topicmap-id topicmap-id
                 :assoc-id assoc-id
                 :view-props view-props))

(defun make-shared-projection-role-binding (&key role entity-id)
  (make-instance 'shared-projection-role-binding
                 :role role
                 :entity-id entity-id))

(defun make-shared-projection-entity
    (&key id title summary type attrs owner-class workspace-assignment
       topicmap-memberships provenance journal-subject-key)
  (make-instance 'shared-projection-entity
                 :id id
                 :title title
                 :summary summary
                 :type type
                 :attrs attrs
                 :owner-class owner-class
                 :workspace-assignment workspace-assignment
                 :topicmap-memberships topicmap-memberships
                 :provenance provenance
                 :journal-subject-key journal-subject-key))

(defun make-shared-projection-relation
    (&key id title summary type roles attrs provenance)
  (make-instance 'shared-projection-relation
                 :id id
                 :title title
                 :summary summary
                 :type type
                 :roles roles
                 :attrs attrs
                 :provenance provenance))

(defun make-shared-projection-journal-event
    (&key id title summary subject-key timestamp operation target-id payload
       derivation-kind replay-status)
  (make-instance 'shared-projection-journal-event
                 :id id
                 :title title
                 :summary summary
                 :subject-key subject-key
                 :timestamp timestamp
                 :operation operation
                 :target-id target-id
                 :payload payload
                 :derivation-kind derivation-kind
                 :replay-status replay-status))

(defun make-behavior-guard (&key id title summary expression)
  (make-instance 'behavior-guard
                 :id id
                 :title title
                 :summary summary
                 :expression expression))

(defun make-behavior-event (&key id title summary payload-shape)
  (make-instance 'behavior-event
                 :id id
                 :title title
                 :summary summary
                 :payload-shape payload-shape))

(defun make-behavior-state
    (&key id title summary role entry-condition exit-condition notes region)
  (make-instance 'behavior-state
                 :id id
                 :title title
                 :summary summary
                 :role role
                 :entry-condition entry-condition
                 :exit-condition exit-condition
                 :notes notes
                 :region region))

(defun make-behavior-transition
    (&key id title from-state to-state event-id guard-id emitted-evidence
       side-effects reversible-p notes)
  (make-instance 'behavior-transition
                 :id id
                 :title title
                 :from-state from-state
                 :to-state to-state
                 :trigger event-id
                 :guard guard-id
                 :event-id event-id
                 :guard-id guard-id
                 :emitted-evidence emitted-evidence
                 :evidence-note emitted-evidence
                 :side-effects side-effects
                 :reversible-p reversible-p
                 :notes notes))

(defun make-behavior-machine-definition
    (&key id title summary states transitions guard-objects event-objects
       initial-state final-states regions history-mode scxml-text
       source-evidence notes)
  (make-instance 'behavior-machine-definition
                 :id id
                 :title title
                 :summary summary
                 :states states
                 :transitions transitions
                 :guards (mapcar #'id-of guard-objects)
                 :events (mapcar #'id-of event-objects)
                 :guard-objects guard-objects
                 :event-objects event-objects
                 :initial-state initial-state
                 :terminal-states final-states
                 :failure-states
                 (loop for state in states
                       when (eq (state-machine-state-role-of state) :failure)
                       collect (id-of state))
                 :regions regions
                 :history-mode history-mode
                 :scxml-text scxml-text
                 :source-evidence source-evidence
                 :notes notes
                 :multi-initial-p nil
                 :multi-current-p nil
                 :allow-terminal-outgoing-p nil
                 :acyclic-p t))

(defun make-behavior-trace-entry
    (&key from-state to-state transition-id timestamp kind note evidence)
  (make-instance 'behavior-trace-entry
                 :from-state from-state
                 :to-state to-state
                 :transition-id transition-id
                 :timestamp timestamp
                 :kind kind
                 :note note
                 :evidence evidence))

(defun make-behavior-trace (&key id title summary run-id entries)
  (make-instance 'behavior-trace
                 :id id
                 :title title
                 :summary summary
                 :run-id run-id
                 :entries entries))

(defun behavior-trace-entry->state-machine-trace-entry (entry)
  (list :timestamp (behavior-trace-entry-timestamp-of entry)
        :kind (behavior-trace-entry-kind-of entry)
        :transition-id (behavior-trace-entry-transition-id-of entry)
        :from-state (behavior-trace-entry-from-state-of entry)
        :to-state (behavior-trace-entry-to-state-of entry)
        :detail (behavior-trace-entry-note-of entry)
        :evidence (behavior-trace-entry-evidence-of entry)))

(defun behavior-trace->state-machine-transition-trace (trace)
  (mapcar #'behavior-trace-entry->state-machine-trace-entry
          (behavior-trace-entries-of trace)))

(defun behavior-trace->state-machine-evidence-trace (trace)
  (loop for entry in (behavior-trace-entries-of trace)
        when (behavior-trace-entry-evidence-of entry)
        collect (list :timestamp (behavior-trace-entry-timestamp-of entry)
                      :kind :evidence
                      :transition-id (behavior-trace-entry-transition-id-of entry)
                      :from-state (behavior-trace-entry-from-state-of entry)
                      :to-state (behavior-trace-entry-to-state-of entry)
                      :evidence (behavior-trace-entry-evidence-of entry))))

(defun make-behavior-run
    (&key id title summary machine input current-state visited-states
       behavior-trace status failure-classification started-at ended-at notes)
  (make-instance 'behavior-run
                 :id id
                 :title title
                 :summary summary
                 :machine machine
                 :machine-id (and machine (id-of machine))
                 :input input
                 :current-state current-state
                 :visited-states visited-states
                 :transition-trace
                 (and behavior-trace
                      (behavior-trace->state-machine-transition-trace
                       behavior-trace))
                 :evidence-trace
                 (and behavior-trace
                      (behavior-trace->state-machine-evidence-trace
                       behavior-trace))
                 :status status
                 :failure-classification failure-classification
                 :behavior-trace behavior-trace
                 :started-at started-at
                 :ended-at ended-at
                 :start-time started-at
                 :end-time ended-at
                 :notes notes))

(defun make-shared-projection-context-window
    (&key id title summary workspace-name topicmap-id focus-entity-ids
       entity-ids relation-ids active-behavior-machine-ids projection-status
       source-endpoints entities relations behavior-machines behavior-runs
       behavior-traces journal-events)
  (make-instance 'shared-projection-context-window
                 :id id
                 :title title
                 :summary summary
                 :workspace-name workspace-name
                 :topicmap-id topicmap-id
                 :focus-entity-ids focus-entity-ids
                 :entity-ids entity-ids
                 :relation-ids relation-ids
                 :active-behavior-machine-ids active-behavior-machine-ids
                 :projection-status projection-status
                 :source-endpoints source-endpoints
                 :entities entities
                 :relations relations
                 :behavior-machines behavior-machines
                 :behavior-runs behavior-runs
                 :behavior-traces behavior-traces
                 :journal-events journal-events))

(defmethod print-object ((object shared-projection-provenance) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A"
            (or (shared-projection-provenance-source-id-of object)
                (shared-projection-provenance-source-kind-of object)))))

(defmethod print-object ((object shared-projection-entity) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object shared-projection-relation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (title-of object)
                            (shared-projection-relation-type-of object)))))

(defmethod print-object ((object shared-projection-context-window) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (title-of object)
                            (shared-projection-context-window-workspace-name-of object)))))

(defmethod print-object ((object behavior-guard) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (title-of object) (id-of object)))))

(defmethod print-object ((object behavior-event) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (title-of object) (id-of object)))))

(defmethod print-object ((object behavior-trace) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (title-of object) (id-of object)))))

(defun state-machine-definition->behavior-machine-definition (machine)
  (let* ((guard-objects
          (mapcar (lambda (guard-id)
                    (make-behavior-guard
                     :id (shared-projection-string guard-id)
                     :title (shared-projection-string guard-id)
                     :summary "Imported from the generic HyperDoc state-machine guard list."
                     :expression (shared-projection-string guard-id)))
                  (state-machine-definition-guards-of machine)))
         (event-objects
          (mapcar (lambda (event-id)
                    (make-behavior-event
                     :id (shared-projection-string event-id)
                     :title (shared-projection-string event-id)
                     :summary "Imported from the generic HyperDoc state-machine event list."))
                  (state-machine-definition-events-of machine))))
    (make-behavior-machine-definition
     :id (id-of machine)
     :title (title-of machine)
     :summary (summary-of machine)
     :states
     (mapcar (lambda (state)
               (make-behavior-state
                :id (id-of state)
                :title (title-of state)
                :summary (summary-of state)
                :role (state-machine-state-role-of state)
                :entry-condition (state-machine-state-entry-condition-of state)
                :exit-condition (state-machine-state-exit-condition-of state)
                :notes (state-machine-state-notes-of state)))
             (state-machine-definition-states-of machine))
     :transitions
     (mapcar (lambda (transition)
               (make-behavior-transition
                :id (id-of transition)
                :title (title-of transition)
                :from-state (state-machine-transition-from-state-of transition)
                :to-state (state-machine-transition-to-state-of transition)
                :event-id (state-machine-transition-trigger-of transition)
                :guard-id (state-machine-transition-guard-of transition)
                :emitted-evidence
                (state-machine-transition-emitted-evidence-of transition)
                :side-effects (state-machine-transition-side-effects-of transition)
                :reversible-p
                (state-machine-transition-reversible-p-of transition)
                :notes (state-machine-transition-notes-of transition)))
             (state-machine-definition-transitions-of machine))
     :guard-objects guard-objects
     :event-objects event-objects
     :initial-state (state-machine-definition-initial-state-of machine)
     :final-states (state-machine-definition-terminal-states-of machine)
     :regions nil
     :history-mode nil
     :scxml-text nil
     :source-evidence (state-machine-definition-source-evidence-of machine)
     :notes (state-machine-definition-notes-of machine))))

(defun behavior-machine-definition->state-machine-definition (machine)
  (make-state-machine-definition
   :id (id-of machine)
   :title (title-of machine)
   :summary (summary-of machine)
   :states
   (mapcar (lambda (state)
             (make-state-machine-state
              :id (id-of state)
              :title (title-of state)
              :summary (summary-of state)
              :role (state-machine-state-role-of state)
              :entry-condition (state-machine-state-entry-condition-of state)
              :exit-condition (state-machine-state-exit-condition-of state)
              :notes (state-machine-state-notes-of state)))
           (state-machine-definition-states-of machine))
   :transitions
   (mapcar (lambda (transition)
             (make-state-machine-transition
              :id (id-of transition)
              :title (title-of transition)
              :from-state (state-machine-transition-from-state-of transition)
              :to-state (state-machine-transition-to-state-of transition)
              :trigger (behavior-transition-event-id-of transition)
              :guard (behavior-transition-guard-id-of transition)
              :emitted-evidence
              (state-machine-transition-emitted-evidence-of transition)
              :side-effects (state-machine-transition-side-effects-of transition)
              :reversible-p (state-machine-transition-reversible-p-of transition)
              :notes (state-machine-transition-notes-of transition)))
           (state-machine-definition-transitions-of machine))
   :initial-state (state-machine-definition-initial-state-of machine)
   :terminal-states (state-machine-definition-terminal-states-of machine)
   :guards (mapcar #'id-of (behavior-machine-definition-guard-objects-of machine))
   :events (mapcar #'id-of (behavior-machine-definition-event-objects-of machine))
   :failure-states (state-machine-definition-failure-states-of machine)
   :source-evidence (state-machine-definition-source-evidence-of machine)
   :notes (state-machine-definition-notes-of machine)
   :multi-initial-p nil
   :multi-current-p nil
   :allow-terminal-outgoing-p nil
   :acyclic-p t))

(defun behavior-machine-definition->scxml (machine)
  (or (behavior-machine-definition-scxml-text-of machine)
      (setf (behavior-machine-definition-scxml-text-of machine)
            (with-output-to-string (stream)
              (format stream
                      "<scxml name=\"~A\" initial=\"~A\" xmlns=\"http://www.w3.org/2005/07/scxml\">~%"
                      (shared-projection-xml-escape (id-of machine))
                      (shared-projection-xml-escape
                       (state-machine-definition-initial-state-of machine)))
              (dolist (state (state-machine-definition-states-of machine))
                (let* ((state-id (id-of state))
                       (outgoing (state-machine-transitions-from-state machine state-id))
                       (terminal-p
                        (member state-id
                                (state-machine-definition-terminal-states-of machine)
                                :test #'equal)))
                  (if (and terminal-p (null outgoing))
                      (format stream "  <final id=\"~A\"/>~%"
                              (shared-projection-xml-escape state-id))
                      (progn
                        (format stream "  <state id=\"~A\">~%"
                                (shared-projection-xml-escape state-id))
                        (dolist (transition outgoing)
                          (format stream "    <transition")
                          (when (id-of transition)
                            (format stream
                                    " id=\"~A\""
                                    (shared-projection-xml-escape
                                     (id-of transition))))
                          (when (behavior-transition-event-id-of transition)
                            (format stream
                                    " event=\"~A\""
                                    (shared-projection-xml-escape
                                     (behavior-transition-event-id-of transition))))
                          (when (behavior-transition-guard-id-of transition)
                            (format stream
                                    " cond=\"~A\""
                                    (shared-projection-xml-escape
                                     (behavior-transition-guard-id-of transition))))
                          (format stream
                                  " target=\"~A\"/>~%"
                                  (shared-projection-xml-escape
                                   (state-machine-transition-to-state-of transition))))
                        (format stream "  </state>~%")))))
              (write-string "</scxml>" stream)))))

(defun scxml->behavior-machine-definition (text)
  (let ((lines (remove-if (lambda (line)
                            (string= "" (string-trim '(#\Space #\Tab) line)))
                          (uiop:split-string text :separator '(#\Newline)))))
    (let ((machine-id nil)
          (initial-state nil)
          (states '())
          (final-states '())
          (transitions '())
          (guard-ids '())
          (event-ids '())
          (current-state-id nil))
      (dolist (line lines)
        (let ((trimmed (string-trim '(#\Space #\Tab #\Return) line)))
          (cond
            ((search "<scxml" trimmed :test #'char=)
             (setf machine-id
                   (shared-projection-extract-xml-attribute trimmed "name")
                   initial-state
                   (shared-projection-extract-xml-attribute trimmed "initial")))
            ((search "<final" trimmed :test #'char=)
             (let ((state-id
                    (shared-projection-extract-xml-attribute trimmed "id")))
               (push (make-behavior-state
                      :id state-id
                      :title state-id
                      :summary "Parsed from SCXML final state."
                      :role :terminal)
                     states)
               (push state-id final-states)
               (setf current-state-id nil)))
            ((and (search "<state" trimmed :test #'char=)
                  (not (search "</state" trimmed :test #'char=)))
             (setf current-state-id
                   (shared-projection-extract-xml-attribute trimmed "id"))
             (push (make-behavior-state
                    :id current-state-id
                    :title current-state-id
                    :summary "Parsed from SCXML state.")
                   states))
            ((search "<transition" trimmed :test #'char=)
             (let ((transition-id
                    (shared-projection-extract-xml-attribute trimmed "id"))
                   (event-id
                    (shared-projection-extract-xml-attribute trimmed "event"))
                   (guard-id
                    (shared-projection-extract-xml-attribute trimmed "cond"))
                   (target-id
                    (shared-projection-extract-xml-attribute trimmed "target")))
               (push (make-behavior-transition
                      :id (or transition-id
                              (format nil "~A->~A" current-state-id target-id))
                      :title (format nil "~A -> ~A" current-state-id target-id)
                      :from-state current-state-id
                      :to-state target-id
                      :event-id event-id
                      :guard-id guard-id)
                     transitions)
               (when event-id
                 (pushnew event-id event-ids :test #'equal))
               (when guard-id
                 (pushnew guard-id guard-ids :test #'equal))))
            ((search "</state" trimmed :test #'char=)
             (setf current-state-id nil)))))
      (make-behavior-machine-definition
       :id machine-id
       :title (or machine-id "SCXML behavior machine")
       :summary "Behavior machine reconstructed from SCXML text."
       :states (nreverse states)
       :transitions (nreverse transitions)
       :guard-objects
       (mapcar (lambda (guard-id)
                 (make-behavior-guard
                  :id guard-id
                  :title guard-id
                  :summary "Parsed from SCXML cond attribute."
                  :expression guard-id))
               (nreverse guard-ids))
       :event-objects
       (mapcar (lambda (event-id)
                 (make-behavior-event
                  :id event-id
                  :title event-id
                  :summary "Parsed from SCXML event attribute."))
               (nreverse event-ids))
       :initial-state initial-state
       :final-states (nreverse final-states)
       :regions nil
       :history-mode nil
       :scxml-text text
       :source-evidence
       (list
        (list :layer "SCXML"
              :reference "Imported text"
              :detail "Machine definition rebuilt from SCXML."))))))

(defun dmx-topic-children->shared-projection-attrs (topic-json)
  (let ((children (shared-projection-json-field topic-json "children")))
    (cond
      ((hash-table-p children)
       (shared-projection-copy-json-value children))
      (t nil))))

(defun dmx-topic-json->shared-projection-entity
    (topic-json &key workspace-assignment topicmap-memberships provenance owner-class)
  (let ((topic-id (shared-projection-json-field topic-json "id"))
        (title (or (shared-projection-json-field topic-json "value")
                   (shared-projection-json-field topic-json "uri")
                   "DMX topic"))
        (type-uri (or (shared-projection-json-field topic-json "typeUri")
                      (shared-projection-json-field topic-json "uri")
                      "dmx.topic")))
    (make-shared-projection-entity
     :id (format nil "topic/~A" topic-id)
     :title title
     :summary "Entity normalized from machine-readable DMX topic JSON."
     :type type-uri
     :attrs (dmx-topic-children->shared-projection-attrs topic-json)
     :owner-class owner-class
     :workspace-assignment workspace-assignment
     :topicmap-memberships topicmap-memberships
     :provenance provenance
     :journal-subject-key (format nil "topic/~A" topic-id))))

(defun dmx-topicmap-membership-json->shared-projection-topicmap-membership
    (membership-json)
  (let* ((assoc (shared-projection-json-field membership-json "assoc"))
         (topicmap-id (shared-projection-json-field membership-json "id")))
    (make-shared-projection-topicmap-membership
     :id (format nil "topicmap-membership/~A/~A"
                 topicmap-id
                 (or (shared-projection-json-field assoc "id") "unknown"))
     :topicmap-id topicmap-id
     :assoc-id (shared-projection-json-field assoc "id")
     :view-props (shared-projection-copy-json-value
                  (shared-projection-json-field membership-json "viewProps")))))

(defun dmx-topicmap-membership->shared-projection-relation
    (topic-id membership &key provenance)
  (make-shared-projection-relation
   :id (format nil "relation/topicmap-membership/~A/~A"
               (shared-projection-topicmap-membership-topicmap-id-of membership)
               topic-id)
   :title "Topicmap placement"
   :summary "Projection relation that records topicmap placement distinctly from workspace assignment."
   :type "dmx.topicmaps.topicmap_context"
   :roles
   (list
    (make-shared-projection-role-binding
     :role "topicmap"
     :entity-id
     (format nil "topicmap/~A"
             (shared-projection-topicmap-membership-topicmap-id-of membership)))
    (make-shared-projection-role-binding
     :role "member"
     :entity-id topic-id))
   :attrs (shared-projection-topicmap-membership-view-props-of membership)
   :provenance provenance))

(defun dmx-topicmap-json->shared-projection-context-window
    (topicmap-json &key workspace-json topic-jsons topicmap-memberships active-behavior-machine-ids source-endpoints)
  (let* ((topicmap-topic (or (shared-projection-json-field topicmap-json "topic")
                             topicmap-json))
         (topicmap-id (shared-projection-json-field topicmap-topic "id"))
         (workspace-id (and workspace-json
                            (shared-projection-json-field workspace-json "id")))
         (workspace-name (or (and workspace-json
                                  (shared-projection-json-field workspace-json "value"))
                             (shared-projection-json-field topicmap-topic "value")
                             "context-window"))
         (memberships-by-topic
          (or topicmap-memberships
              (let ((table (make-hash-table :test #'equal)))
                (dolist (topic-entry
                          (shared-projection-list
                           (shared-projection-json-field topicmap-json "topics")))
                  (let* ((topic-id (shared-projection-json-field topic-entry "id"))
                         (membership
                          (make-shared-projection-topicmap-membership
                           :id (format nil "topicmap-membership/~A/~A"
                                       topicmap-id
                                       topic-id)
                           :topicmap-id topicmap-id
                           :assoc-id nil
                           :view-props
                           (shared-projection-copy-json-value
                            (shared-projection-json-field topic-entry "viewProps")))))
                    (setf (gethash topic-id table) (list membership))))
                table)))
         (entities
          (mapcar
           (lambda (topic-json)
             (let* ((topic-id (shared-projection-json-field topic-json "id"))
                    (memberships
                     (shared-projection-list
                      (gethash topic-id memberships-by-topic)))
                    (assignment
                     (and workspace-id
                          (make-shared-projection-workspace-assignment
                           :id (format nil "workspace-assignment/~A/~A"
                                       workspace-id topic-id)
                           :workspace-id workspace-id
                           :workspace-name workspace-name
                           :assignment-status "read-from-authoritative-workspace"))))
               (dmx-topic-json->shared-projection-entity
                topic-json
                :workspace-assignment assignment
                :topicmap-memberships memberships
                :owner-class nil
                :provenance
                (make-shared-projection-provenance
                 :id (format nil "provenance/topic/~A" topic-id)
                 :source-kind "dmx-read"
                 :source-id (format nil "topic/~A" topic-id)
                 :derivation-kind "normalized-topic-json"
                 :confidence 1.0
                 :replay-hash (format nil "topic/~A" topic-id)))))
           topic-jsons))
         (relations
          (loop for entity in entities
                append
                (mapcar
                 (lambda (membership)
                   (dmx-topicmap-membership->shared-projection-relation
                    (id-of entity)
                    membership
                    :provenance
                    (make-shared-projection-provenance
                     :source-kind "dmx-read"
                     :source-id (format nil "topicmap/~A"
                                        (shared-projection-topicmap-membership-topicmap-id-of
                                         membership))
                     :derivation-kind "normalized-topicmap-membership"
                     :confidence 1.0
                     :replay-hash
                     (format nil "topicmap-membership/~A/~A"
                             (shared-projection-topicmap-membership-topicmap-id-of
                              membership)
                             (shared-projection-topicmap-membership-assoc-id-of
                              membership)))))
                 (shared-projection-entity-topicmap-memberships-of entity)))))
    (make-shared-projection-context-window
     :id (format nil "context-window/~A" topicmap-id)
     :title (format nil "~A shared projection" workspace-name)
     :summary
     "Rebuildable shared projection derived from machine-readable DMX workspace/topicmap readouts."
     :workspace-name workspace-name
     :topicmap-id topicmap-id
     :focus-entity-ids (and entities (list (id-of (first entities))))
     :entity-ids (mapcar #'id-of entities)
     :relation-ids (mapcar #'id-of relations)
     :active-behavior-machine-ids active-behavior-machine-ids
     :projection-status "rebuildable-shared-projection"
     :source-endpoints
     (or source-endpoints
         (remove nil
                 (list (and workspace-id (format nil "workspace/~A" workspace-id))
                       (format nil "topicmap/~A" topicmap-id))))
     :entities entities
     :relations relations
     :behavior-machines nil
     :behavior-runs nil
     :behavior-traces nil
     :journal-events nil)))

(defun shared-projection-provenance->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "sharedProjectionProvenance")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set
     json "sourceKind" (shared-projection-provenance-source-kind-of object))
    (shared-projection-json-set
     json "sourceId" (shared-projection-provenance-source-id-of object))
    (shared-projection-json-set
     json "derivationKind" (shared-projection-provenance-derivation-kind-of object))
    (shared-projection-json-set
     json "confidence" (shared-projection-provenance-confidence-of object))
    (shared-projection-json-set
     json "replayHash" (shared-projection-provenance-replay-hash-of object))
    json))

(defun shared-projection-workspace-assignment->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "sharedProjectionWorkspaceAssignment")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set
     json "workspaceId" (shared-projection-workspace-assignment-workspace-id-of object))
    (shared-projection-json-set
     json "workspaceName"
     (shared-projection-workspace-assignment-workspace-name-of object))
    (shared-projection-json-set
     json "assignmentStatus"
     (shared-projection-workspace-assignment-status-of object))
    json))

(defun shared-projection-topicmap-membership->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "sharedProjectionTopicmapMembership")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set
     json "topicmapId" (shared-projection-topicmap-membership-topicmap-id-of object))
    (shared-projection-json-set
     json "assocId" (shared-projection-topicmap-membership-assoc-id-of object))
    (shared-projection-json-set
     json "viewProps"
     (shared-projection-copy-json-value
      (shared-projection-topicmap-membership-view-props-of object)))
    json))

(defun shared-projection-role-binding->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "role"
                                (shared-projection-role-binding-role-of object))
    (shared-projection-json-set json "entityId"
                                (shared-projection-role-binding-entity-id-of object))
    json))

(defun shared-projection-entity->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "sharedProjectionEntity")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "type" (shared-projection-entity-type-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "attrs"
                                (shared-projection-copy-json-value
                                 (shared-projection-entity-attrs-of object)))
    (shared-projection-json-set
     json "ownerClass" (shared-projection-entity-owner-class-of object))
    (shared-projection-json-set
     json "workspaceAssignment"
     (and (shared-projection-entity-workspace-assignment-of object)
          (shared-projection-workspace-assignment->json-object
           (shared-projection-entity-workspace-assignment-of object))))
    (shared-projection-json-set
     json "topicmapMemberships"
     (mapcar #'shared-projection-topicmap-membership->json-object
             (shared-projection-entity-topicmap-memberships-of object)))
    (shared-projection-json-set
     json "provenance"
     (and (shared-projection-entity-provenance-of object)
          (shared-projection-provenance->json-object
           (shared-projection-entity-provenance-of object))))
    (shared-projection-json-set
     json "journalSubjectKey"
     (shared-projection-entity-journal-subject-key-of object))
    json))

(defun shared-projection-relation->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "sharedProjectionRelation")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "type" (shared-projection-relation-type-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set
     json "roles"
     (mapcar #'shared-projection-role-binding->json-object
             (shared-projection-relation-roles-of object)))
    (shared-projection-json-set
     json "attrs"
     (shared-projection-copy-json-value (shared-projection-relation-attrs-of object)))
    (shared-projection-json-set
     json "provenance"
     (and (shared-projection-relation-provenance-of object)
          (shared-projection-provenance->json-object
           (shared-projection-relation-provenance-of object))))
    json))

(defun shared-projection-journal-event->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "sharedProjectionJournalEvent")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "subjectKey"
                                (shared-projection-journal-event-subject-key-of object))
    (shared-projection-json-set json "timestamp"
                                (shared-projection-journal-event-timestamp-of object))
    (shared-projection-json-set json "operation"
                                (shared-projection-journal-event-operation-of object))
    (shared-projection-json-set json "targetId"
                                (shared-projection-journal-event-target-id-of object))
    (shared-projection-json-set json "payload"
                                (shared-projection-copy-json-value
                                 (shared-projection-journal-event-payload-of object)))
    (shared-projection-json-set json "derivationKind"
                                (shared-projection-journal-event-derivation-kind-of object))
    (shared-projection-json-set json "replayStatus"
                                (shared-projection-journal-event-replay-status-of object))
    json))

(defun behavior-guard->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorGuard")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "expression" (behavior-guard-expression-of object))
    json))

(defun behavior-event->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorEvent")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "payloadShape"
                                (shared-projection-copy-json-value
                                 (behavior-event-payload-shape-of object)))
    json))

(defun behavior-state->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorState")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "role" (state-machine-state-role-of object))
    (shared-projection-json-set json "entryCondition"
                                (state-machine-state-entry-condition-of object))
    (shared-projection-json-set json "exitCondition"
                                (state-machine-state-exit-condition-of object))
    (shared-projection-json-set json "region" (behavior-state-region-of object))
    (shared-projection-json-set json "notes"
                                (shared-projection-copy-json-value
                                 (state-machine-state-notes-of object)))
    json))

(defun behavior-transition->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorTransition")
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "fromState"
                                (state-machine-transition-from-state-of object))
    (shared-projection-json-set json "toState"
                                (state-machine-transition-to-state-of object))
    (shared-projection-json-set json "event"
                                (behavior-transition-event-id-of object))
    (shared-projection-json-set json "guard"
                                (behavior-transition-guard-id-of object))
    (shared-projection-json-set json "evidence"
                                (state-machine-transition-emitted-evidence-of object))
    (shared-projection-json-set json "sideEffects"
                                (state-machine-transition-side-effects-of object))
    (shared-projection-json-set json "reversible"
                                (state-machine-transition-reversible-p-of object))
    (shared-projection-json-set json "notes"
                                (shared-projection-copy-json-value
                                 (state-machine-transition-notes-of object)))
    json))

(defun behavior-machine-definition->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorMachineDefinition")
    (shared-projection-json-set
     json "schemaVersion" *shared-projection-ir-schema-version*)
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "states"
                                (mapcar #'behavior-state->json-object
                                        (state-machine-definition-states-of object)))
    (shared-projection-json-set json "transitions"
                                (mapcar #'behavior-transition->json-object
                                        (state-machine-definition-transitions-of object)))
    (shared-projection-json-set json "guards"
                                (mapcar #'behavior-guard->json-object
                                        (behavior-machine-definition-guard-objects-of object)))
    (shared-projection-json-set json "events"
                                (mapcar #'behavior-event->json-object
                                        (behavior-machine-definition-event-objects-of object)))
    (shared-projection-json-set json "initialState"
                                (state-machine-definition-initial-state-of object))
    (shared-projection-json-set json "finalStates"
                                (state-machine-definition-terminal-states-of object))
    (shared-projection-json-set json "regions"
                                (shared-projection-copy-json-value
                                 (behavior-machine-definition-regions-of object)))
    (shared-projection-json-set json "historyMode"
                                (behavior-machine-definition-history-mode-of object))
    (shared-projection-json-set json "scxmlText"
                                (behavior-machine-definition->scxml object))
    json))

(defun behavior-trace-entry->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorTraceEntry")
    (shared-projection-json-set json "fromState"
                                (behavior-trace-entry-from-state-of object))
    (shared-projection-json-set json "toState"
                                (behavior-trace-entry-to-state-of object))
    (shared-projection-json-set json "transitionId"
                                (behavior-trace-entry-transition-id-of object))
    (shared-projection-json-set json "timestamp"
                                (behavior-trace-entry-timestamp-of object))
    (shared-projection-json-set json "kind"
                                (behavior-trace-entry-kind-of object))
    (shared-projection-json-set json "note"
                                (behavior-trace-entry-note-of object))
    (shared-projection-json-set json "evidence"
                                (behavior-trace-entry-evidence-of object))
    json))

(defun behavior-trace->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorTrace")
    (shared-projection-json-set
     json "schemaVersion" *shared-projection-ir-schema-version*)
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "runId" (behavior-trace-run-id-of object))
    (shared-projection-json-set json "entries"
                                (mapcar #'behavior-trace-entry->json-object
                                        (behavior-trace-entries-of object)))
    json))

(defun behavior-run->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "behaviorRun")
    (shared-projection-json-set
     json "schemaVersion" *shared-projection-ir-schema-version*)
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "machineId" (behavior-run-machine-id-of object))
    (shared-projection-json-set json "input"
                                (shared-projection-copy-json-value
                                 (state-machine-run-input-of object)))
    (shared-projection-json-set json "currentState"
                                (state-machine-run-current-state-of object))
    (shared-projection-json-set json "visitedStates"
                                (copy-list (state-machine-run-visited-states-of object)))
    (shared-projection-json-set json "transitionTrace"
                                (and (behavior-run-trace-of object)
                                     (behavior-trace->json-object
                                      (behavior-run-trace-of object))))
    (shared-projection-json-set json "status" (state-machine-run-status-of object))
    (shared-projection-json-set json "failureClassification"
                                (state-machine-run-failure-classification-of object))
    (shared-projection-json-set json "startedAt" (behavior-run-started-at-of object))
    (shared-projection-json-set json "endedAt" (behavior-run-ended-at-of object))
    json))

(defun shared-projection-context-window->json-object (object)
  (let ((json (shared-projection-json-object)))
    (shared-projection-json-set json "irClass" "sharedProjectionContextWindow")
    (shared-projection-json-set
     json "schemaVersion" *shared-projection-ir-schema-version*)
    (shared-projection-json-set json "id" (id-of object))
    (shared-projection-json-set json "title" (title-of object))
    (shared-projection-json-set json "summary" (summary-of object))
    (shared-projection-json-set json "workspaceName"
                                (shared-projection-context-window-workspace-name-of object))
    (shared-projection-json-set json "topicmapId"
                                (shared-projection-context-window-topicmap-id-of object))
    (shared-projection-json-set json "focusEntityIds"
                                (copy-list
                                 (shared-projection-context-window-focus-entity-ids-of object)))
    (shared-projection-json-set json "entityIds"
                                (copy-list
                                 (shared-projection-context-window-entity-ids-of object)))
    (shared-projection-json-set json "relationIds"
                                (copy-list
                                 (shared-projection-context-window-relation-ids-of object)))
    (shared-projection-json-set
     json "activeBehaviorMachineIds"
     (copy-list
      (shared-projection-context-window-active-behavior-machine-ids-of object)))
    (shared-projection-json-set json "projectionStatus"
                                (shared-projection-context-window-projection-status-of object))
    (shared-projection-json-set
     json "sourceEndpoints"
     (shared-projection-copy-json-value
      (shared-projection-context-window-source-endpoints-of object)))
    (shared-projection-json-set json "entities"
                                (mapcar #'shared-projection-entity->json-object
                                        (shared-projection-context-window-entities-of object)))
    (shared-projection-json-set json "relations"
                                (mapcar #'shared-projection-relation->json-object
                                        (shared-projection-context-window-relations-of object)))
    (shared-projection-json-set
     json "behaviorMachines"
     (mapcar #'behavior-machine-definition->json-object
             (shared-projection-context-window-behavior-machines-of object)))
    (shared-projection-json-set
     json "behaviorRuns"
     (mapcar #'behavior-run->json-object
             (shared-projection-context-window-behavior-runs-of object)))
    (shared-projection-json-set
     json "behaviorTraces"
     (mapcar #'behavior-trace->json-object
             (shared-projection-context-window-behavior-traces-of object)))
    (shared-projection-json-set
     json "journalEvents"
     (mapcar #'shared-projection-journal-event->json-object
             (shared-projection-context-window-journal-events-of object)))
    json))

(defun shared-projection-write-json-string (object)
  (with-output-to-string (stream)
    (shasht:write-json object stream)))

(defun shared-projection-context-window-json-string (object)
  (shared-projection-write-json-string
   (shared-projection-context-window->json-object object)))

(defun shared-projection-provenance-from-json (json)
  (make-shared-projection-provenance
   :id (shared-projection-json-field json "id")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :source-kind (shared-projection-json-field json "sourceKind")
   :source-id (shared-projection-json-field json "sourceId")
   :derivation-kind (shared-projection-json-field json "derivationKind")
   :confidence (shared-projection-json-field json "confidence")
   :replay-hash (shared-projection-json-field json "replayHash")))

(defun shared-projection-workspace-assignment-from-json (json)
  (make-shared-projection-workspace-assignment
   :id (shared-projection-json-field json "id")
   :workspace-id (shared-projection-json-field json "workspaceId")
   :workspace-name (shared-projection-json-field json "workspaceName")
   :assignment-status (shared-projection-json-field json "assignmentStatus")))

(defun shared-projection-topicmap-membership-from-json (json)
  (make-shared-projection-topicmap-membership
   :id (shared-projection-json-field json "id")
   :topicmap-id (shared-projection-json-field json "topicmapId")
   :assoc-id (shared-projection-json-field json "assocId")
   :view-props (shared-projection-copy-json-value
                (shared-projection-json-field json "viewProps"))))

(defun shared-projection-role-binding-from-json (json)
  (make-shared-projection-role-binding
   :role (shared-projection-json-field json "role")
   :entity-id (shared-projection-json-field json "entityId")))

(defun shared-projection-entity-from-json (json)
  (make-shared-projection-entity
   :id (shared-projection-json-field json "id")
   :type (shared-projection-json-field json "type")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :attrs (shared-projection-copy-json-value
           (shared-projection-json-field json "attrs"))
   :owner-class (shared-projection-json-field json "ownerClass")
   :workspace-assignment
   (when-let (assignment-json
              (shared-projection-json-field json "workspaceAssignment"))
     (shared-projection-workspace-assignment-from-json assignment-json))
   :topicmap-memberships
   (mapcar #'shared-projection-topicmap-membership-from-json
           (shared-projection-list
            (shared-projection-json-field json "topicmapMemberships")))
   :provenance
   (when-let (provenance-json (shared-projection-json-field json "provenance"))
     (shared-projection-provenance-from-json provenance-json))
   :journal-subject-key (shared-projection-json-field json "journalSubjectKey")))

(defun shared-projection-relation-from-json (json)
  (make-shared-projection-relation
   :id (shared-projection-json-field json "id")
   :type (shared-projection-json-field json "type")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :roles (mapcar #'shared-projection-role-binding-from-json
                  (shared-projection-list
                   (shared-projection-json-field json "roles")))
   :attrs (shared-projection-copy-json-value
           (shared-projection-json-field json "attrs"))
   :provenance
   (when-let (provenance-json (shared-projection-json-field json "provenance"))
     (shared-projection-provenance-from-json provenance-json))))

(defun shared-projection-journal-event-from-json (json)
  (make-shared-projection-journal-event
   :id (shared-projection-json-field json "id")
   :subject-key (shared-projection-json-field json "subjectKey")
   :timestamp (shared-projection-json-field json "timestamp")
   :operation (shared-projection-json-field json "operation")
   :target-id (shared-projection-json-field json "targetId")
   :payload (shared-projection-copy-json-value
             (shared-projection-json-field json "payload"))
   :derivation-kind (shared-projection-json-field json "derivationKind")
   :replay-status (shared-projection-json-field json "replayStatus")))

(defun behavior-guard-from-json (json)
  (make-behavior-guard
   :id (shared-projection-json-field json "id")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :expression (shared-projection-json-field json "expression")))

(defun behavior-event-from-json (json)
  (make-behavior-event
   :id (shared-projection-json-field json "id")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :payload-shape (shared-projection-copy-json-value
                   (shared-projection-json-field json "payloadShape"))))

(defun behavior-state-from-json (json)
  (make-behavior-state
   :id (shared-projection-json-field json "id")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :role (shared-projection-role-value
          (shared-projection-json-field json "role"))
   :entry-condition (shared-projection-json-field json "entryCondition")
   :exit-condition (shared-projection-json-field json "exitCondition")
   :region (shared-projection-json-field json "region")
   :notes (shared-projection-copy-json-value
           (shared-projection-json-field json "notes"))))

(defun behavior-transition-from-json (json)
  (make-behavior-transition
   :id (shared-projection-json-field json "id")
   :title (shared-projection-json-field json "title")
   :from-state (shared-projection-json-field json "fromState")
   :to-state (shared-projection-json-field json "toState")
   :event-id (shared-projection-json-field json "event")
   :guard-id (shared-projection-json-field json "guard")
   :emitted-evidence (shared-projection-json-field json "evidence")
   :side-effects (shared-projection-json-field json "sideEffects")
   :reversible-p (shared-projection-json-field json "reversible")
   :notes (shared-projection-copy-json-value
           (shared-projection-json-field json "notes"))))

(defun behavior-machine-definition-from-json (json)
  (let* ((states (mapcar #'behavior-state-from-json
                         (shared-projection-list
                          (shared-projection-json-field json "states"))))
         (transitions (mapcar #'behavior-transition-from-json
                              (shared-projection-list
                               (shared-projection-json-field json "transitions"))))
         (guards (mapcar #'behavior-guard-from-json
                         (shared-projection-list
                          (shared-projection-json-field json "guards"))))
         (events (mapcar #'behavior-event-from-json
                         (shared-projection-list
                          (shared-projection-json-field json "events")))))
    (make-behavior-machine-definition
     :id (shared-projection-json-field json "id")
     :title (shared-projection-json-field json "title")
     :summary (shared-projection-json-field json "summary")
     :states states
     :transitions transitions
     :guard-objects guards
     :event-objects events
     :initial-state (shared-projection-json-field json "initialState")
     :final-states
     (shared-projection-list (shared-projection-json-field json "finalStates"))
     :regions (shared-projection-copy-json-value
               (shared-projection-json-field json "regions"))
     :history-mode (shared-projection-json-field json "historyMode")
     :scxml-text (shared-projection-json-field json "scxmlText")
     :source-evidence
     (list
      (list :layer "JSON"
            :reference "behaviorMachineDefinition"
            :detail "Reconstructed from JSON/JS plain-object form.")))))

(defun behavior-trace-entry-from-json (json)
  (make-behavior-trace-entry
   :from-state (shared-projection-json-field json "fromState")
   :to-state (shared-projection-json-field json "toState")
   :transition-id (shared-projection-json-field json "transitionId")
   :timestamp (shared-projection-json-field json "timestamp")
   :kind (shared-projection-json-field json "kind")
   :note (shared-projection-json-field json "note")
   :evidence (shared-projection-json-field json "evidence")))

(defun behavior-trace-from-json (json)
  (make-behavior-trace
   :id (shared-projection-json-field json "id")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :run-id (shared-projection-json-field json "runId")
   :entries (mapcar #'behavior-trace-entry-from-json
                    (shared-projection-list
                     (shared-projection-json-field json "entries")))))

(defun behavior-run-from-json (json &key machine trace)
  (make-behavior-run
   :id (shared-projection-json-field json "id")
   :title (shared-projection-json-field json "title")
   :summary (shared-projection-json-field json "summary")
   :machine machine
   :input (shared-projection-copy-json-value
           (shared-projection-json-field json "input"))
   :current-state (shared-projection-json-field json "currentState")
   :visited-states
   (shared-projection-list (shared-projection-json-field json "visitedStates"))
   :behavior-trace trace
   :status (shared-projection-json-field json "status")
   :failure-classification
   (shared-projection-json-field json "failureClassification")
   :started-at (shared-projection-json-field json "startedAt")
   :ended-at (shared-projection-json-field json "endedAt")))

(defun shared-projection-context-window-from-json (json)
  (let* ((machines
          (mapcar #'behavior-machine-definition-from-json
                  (shared-projection-list
                   (shared-projection-json-field json "behaviorMachines"))))
         (traces
          (mapcar #'behavior-trace-from-json
                  (shared-projection-list
                   (shared-projection-json-field json "behaviorTraces"))))
         (trace-by-run-id (make-hash-table :test #'equal)))
    (dolist (trace traces)
      (setf (gethash (behavior-trace-run-id-of trace) trace-by-run-id) trace))
    (make-shared-projection-context-window
     :id (shared-projection-json-field json "id")
     :title (shared-projection-json-field json "title")
     :summary (shared-projection-json-field json "summary")
     :workspace-name (shared-projection-json-field json "workspaceName")
     :topicmap-id (shared-projection-json-field json "topicmapId")
     :focus-entity-ids
     (shared-projection-list (shared-projection-json-field json "focusEntityIds"))
     :entity-ids
     (shared-projection-list (shared-projection-json-field json "entityIds"))
     :relation-ids
     (shared-projection-list (shared-projection-json-field json "relationIds"))
     :active-behavior-machine-ids
     (shared-projection-list
      (shared-projection-json-field json "activeBehaviorMachineIds"))
     :projection-status (shared-projection-json-field json "projectionStatus")
     :source-endpoints (shared-projection-copy-json-value
                        (shared-projection-json-field json "sourceEndpoints"))
     :entities (mapcar #'shared-projection-entity-from-json
                       (shared-projection-list
                        (shared-projection-json-field json "entities")))
     :relations (mapcar #'shared-projection-relation-from-json
                        (shared-projection-list
                         (shared-projection-json-field json "relations")))
     :behavior-machines machines
     :behavior-runs
     (mapcar
      (lambda (run-json)
        (let* ((machine-id (shared-projection-json-field run-json "machineId"))
               (machine (find machine-id machines :key #'id-of :test #'equal))
               (run-id (shared-projection-json-field run-json "id"))
               (trace (or (when-let (trace-json
                                     (shared-projection-json-field
                                      run-json
                                      "transitionTrace"))
                            (behavior-trace-from-json trace-json))
                          (gethash run-id trace-by-run-id))))
          (behavior-run-from-json run-json :machine machine :trace trace)))
      (shared-projection-list (shared-projection-json-field json "behaviorRuns")))
     :behavior-traces traces
     :journal-events
     (mapcar #'shared-projection-journal-event-from-json
             (shared-projection-list
              (shared-projection-json-field json "journalEvents"))))))

(defun shared-projection-context-window-from-json-string (text)
  (shared-projection-context-window-from-json
   (shasht:read-json text)))

(defun shared-projection-context-window-primary-machine (window)
  (or (find (first (shared-projection-context-window-active-behavior-machine-ids-of
                    window))
            (shared-projection-context-window-behavior-machines-of window)
            :key #'id-of
            :test #'equal)
      (first (shared-projection-context-window-behavior-machines-of window))))

(defun shared-projection-context-window-primary-run (window)
  (first (shared-projection-context-window-behavior-runs-of window)))

(defun shared-projection-context-window-primary-trace (window)
  (or (and (shared-projection-context-window-primary-run window)
           (behavior-run-trace-of
            (shared-projection-context-window-primary-run window)))
      (first (shared-projection-context-window-behavior-traces-of window))))

(defun shared-projection-context-window-javascript-source (window)
  (let* ((machine (shared-projection-context-window-primary-machine window))
         (run (shared-projection-context-window-primary-run window))
         (trace (shared-projection-context-window-primary-trace window)))
    (format nil
            "const machine = ~A;~%~%const run = ~A;~%~%const trace = ~A;~%~%const contextWindow = ~A;"
            (shared-projection-write-json-string
             (behavior-machine-definition->json-object machine))
            (shared-projection-write-json-string
             (behavior-run->json-object run))
            (shared-projection-write-json-string
             (behavior-trace->json-object trace))
            (shared-projection-context-window-json-string window))))

(defun workspace-annotation-lifecycle-source-evidence ()
  (list
   (list :layer "HyperDoc"
         :reference "Shared Projection IR / Behavior IR slice"
         :detail "Worked example that keeps projection, behavior, and execution/backend layers distinct.")
   (list :layer "DMX boundary"
         :reference "Context window workspace as shared blackboard"
         :detail "Shared workspace remains a rebuildable projection rather than durable authority.")
   (list :layer "Lisp source"
         :reference "hyperdoc/shared-projection-ir.lisp"
         :detail "CLOS model, normalizers, serializers, and SCXML bridge.")))

(defun make-workspace-annotation-behavior-machine-definition ()
  (make-behavior-machine-definition
   :id "workspace_annotation_lifecycle"
   :title "Workspace annotation lifecycle"
   :summary
   "Behavior IR for validating and projecting one annotation into the shared context window without making the projection authoritative."
   :states
   (list
    (make-behavior-state
     :id "draft"
     :title "Draft"
     :summary "Authoritative annotation state before validation."
     :role :initial
     :entry-condition "Annotation exists in HyperDoc/journal authority."
     :region "authoring")
    (make-behavior-state
     :id "validated"
     :title "Validated"
     :summary "Annotation satisfies projection preconditions."
     :entry-condition "Ownership and placement distinctions are explicit."
     :region "authoring")
    (make-behavior-state
     :id "projected"
     :title "Projected"
     :summary "Shared projection was rebuilt successfully."
     :role :terminal
     :entry-condition "Projection write path remained typed and guarded."
     :region "projection")
    (make-behavior-state
     :id "failed"
     :title "Failed"
     :summary "Validation or projection stopped the run."
     :role :failure
     :entry-condition "Guarded projection requirements were not met."
     :region "projection"))
   :transitions
   (list
    (make-behavior-transition
     :id "validate"
     :title "Validate"
     :from-state "draft"
     :to-state "validated"
     :event-id "VALIDATE"
     :guard-id "ownership-and-placement-explicit"
     :emitted-evidence "validation-report")
    (make-behavior-transition
     :id "project"
     :title "Project"
     :from-state "validated"
     :to-state "projected"
     :event-id "PROJECT"
     :guard-id "projection-write-typed"
     :emitted-evidence "projection-rebuild-record")
    (make-behavior-transition
     :id "fail"
     :title "Fail"
     :from-state "draft"
     :to-state "failed"
     :event-id "ERROR"
     :guard-id "projection-guard-failed"
     :emitted-evidence "projection-failure-record"))
   :guard-objects
   (list
    (make-behavior-guard
     :id "ownership-and-placement-explicit"
     :title "Ownership and placement explicit"
     :summary "Validation requires ownership, workspace assignment, and topicmap placement to remain distinct."
     :expression "entity.ownerClass && entity.workspaceAssignment && entity.topicmapMemberships")
    (make-behavior-guard
     :id "projection-write-typed"
     :title "Projection write typed"
     :summary "Projection writes remain narrow and guarded."
     :expression "dryRun && guardedBoundary")
    (make-behavior-guard
     :id "projection-guard-failed"
     :title "Projection guard failed"
     :summary "Validation failed before projection."
     :expression "missingOwnership || missingPlacement"))
   :event-objects
   (list
    (make-behavior-event
     :id "VALIDATE"
     :title "Validate"
     :summary "Validate authoritative annotation state for projection.")
    (make-behavior-event
     :id "PROJECT"
     :title "Project"
     :summary "Rebuild shared projection from authoritative inputs.")
    (make-behavior-event
     :id "ERROR"
     :title "Error"
     :summary "Stop on explicit projection guard failure."))
   :initial-state "draft"
   :final-states '("projected")
   :regions '("authoring" "projection")
   :history-mode :none
   :source-evidence (workspace-annotation-lifecycle-source-evidence)))

(defun make-workspace-annotation-behavior-trace ()
  (make-behavior-trace
   :id "behavior-trace/workspace-annotation-lifecycle/example"
   :title "Workspace annotation lifecycle trace"
   :summary "Successful trace from authoritative annotation state to rebuildable shared projection."
   :run-id "behavior-run/workspace-annotation-lifecycle/example"
   :entries
   (list
    (make-behavior-trace-entry
     :timestamp 1
     :kind :transition
     :transition-id "validate"
     :from-state "draft"
     :to-state "validated"
     :note "Authoritative annotation state validated for projection."
     :evidence "workspaceAssignment and topicmapMemberships remained distinct.")
    (make-behavior-trace-entry
     :timestamp 2
     :kind :transition
     :transition-id "project"
     :from-state "validated"
     :to-state "projected"
     :note "Shared projection rebuilt from authoritative state."
     :evidence "projectionStatus stayed rebuildable-shared-projection."))))

(defun make-workspace-annotation-behavior-run
    (&optional (machine (make-workspace-annotation-behavior-machine-definition)))
  (let ((trace (make-workspace-annotation-behavior-trace)))
    (make-behavior-run
     :id "behavior-run/workspace-annotation-lifecycle/example"
     :title "Workspace annotation lifecycle run"
     :summary "Example successful behavior run for one annotation."
     :machine machine
     :input
     (let ((json (shared-projection-json-object)))
       (shared-projection-json-set json "annotationId" "annotation/123")
       (shared-projection-json-set json "workspaceId" 919815)
       (shared-projection-json-set json "topicmapId" 919822)
       json)
     :current-state "projected"
     :visited-states '("draft" "validated" "projected")
     :behavior-trace trace
     :status :success
     :failure-classification nil
     :started-at 1
     :ended-at 2
     :notes
     (list
      (list :label "Execution/backend boundary"
            :detail "Backend execution remains separate; this run records semantic behavior only.")))))

(defun make-workspace-annotation-shared-projection-example ()
  (let* ((machine (make-workspace-annotation-behavior-machine-definition))
         (run (make-workspace-annotation-behavior-run machine))
         (trace (behavior-run-trace-of run))
         (annotation-provenance
          (make-shared-projection-provenance
           :id "provenance/annotation/123"
           :source-kind "hyperdoc-journal"
           :source-id "annotation/123"
           :derivation-kind "authoritative-annotation-state"
           :confidence 1.0
           :replay-hash "sha256:annotation-123"))
         (machine-provenance
          (make-shared-projection-provenance
           :id "provenance/machine/workspace_annotation_lifecycle"
           :source-kind "hyperdoc-machine-definition"
           :source-id "workspace_annotation_lifecycle"
           :derivation-kind "behavior-definition"
           :confidence 1.0
           :replay-hash "sha256:workspace-annotation-lifecycle"))
         (annotation-membership
          (make-shared-projection-topicmap-membership
           :id "topicmap-membership/919822/annotation-123"
           :topicmap-id 919822
           :assoc-id 913483
           :view-props
           (let ((json (shared-projection-json-object)))
             (shared-projection-json-set json "dmx.topicmaps.x" 160)
             (shared-projection-json-set json "dmx.topicmaps.y" 120)
             (shared-projection-json-set json "dmx.topicmaps.visibility" t)
             (shared-projection-json-set json "dmx.topicmaps.pinned" nil)
             json)))
         (machine-membership
          (make-shared-projection-topicmap-membership
           :id "topicmap-membership/919822/machine-workspace-annotation-lifecycle"
           :topicmap-id 919822
           :assoc-id 913484
           :view-props
           (let ((json (shared-projection-json-object)))
             (shared-projection-json-set json "dmx.topicmaps.x" 420)
             (shared-projection-json-set json "dmx.topicmaps.y" 120)
             (shared-projection-json-set json "dmx.topicmaps.visibility" t)
             (shared-projection-json-set json "dmx.topicmaps.pinned" nil)
             json)))
         (workspace-assignment
          (make-shared-projection-workspace-assignment
           :id "workspace-assignment/919815/annotation-123"
           :workspace-id 919815
           :workspace-name "context-window"
           :assignment-status "authoritative-workspace-assignment"))
         (machine-assignment
          (make-shared-projection-workspace-assignment
           :id "workspace-assignment/919815/machine-workspace-annotation-lifecycle"
           :workspace-id 919815
           :workspace-name "context-window"
           :assignment-status "authoritative-workspace-assignment"))
         (annotation-entity
          (make-shared-projection-entity
           :id "annotation/123"
           :title "Annotation 123"
           :summary "Authoritative annotation entity projected into the shared context window."
           :type "hyperdoc.annotation"
           :attrs
           (let ((json (shared-projection-json-object)))
             (shared-projection-json-set json "text" "Workspace annotation example")
             (shared-projection-json-set json "authorityLayer" "hyperdoc-journal")
             json)
           :owner-class "hyperdoc-managed"
           :workspace-assignment workspace-assignment
           :topicmap-memberships (list annotation-membership)
           :provenance annotation-provenance
           :journal-subject-key "annotation/123"))
         (machine-entity
          (make-shared-projection-entity
           :id "machine/workspace_annotation_lifecycle"
           :title "workspace_annotation_lifecycle"
           :summary "Behavior machine entity linked into the shared projection."
           :type "hyperdoc.behavior.machine"
           :attrs
           (let ((json (shared-projection-json-object)))
             (shared-projection-json-set json "machineId" "workspace_annotation_lifecycle")
             (shared-projection-json-set json "layer" "behavior-ir")
             json)
           :owner-class "hyperdoc-managed"
           :workspace-assignment machine-assignment
           :topicmap-memberships (list machine-membership)
           :provenance machine-provenance
           :journal-subject-key "machine/workspace_annotation_lifecycle"))
         (relation
          (make-shared-projection-relation
           :id "rel/annotation-has-machine"
           :title "Annotation uses behavior machine"
           :summary "Projection-level relation linking the annotation to its behavior machine."
           :type "annotation-has-machine"
           :roles
           (list
            (make-shared-projection-role-binding
             :role "annotation"
             :entity-id "annotation/123")
            (make-shared-projection-role-binding
             :role "behavior-machine"
             :entity-id "machine/workspace_annotation_lifecycle"))
           :attrs
           (let ((json (shared-projection-json-object)))
             (shared-projection-json-set json "linkKind" "behavior-machine-binding")
             json)
           :provenance
           (make-shared-projection-provenance
            :id "provenance/rel/annotation-has-machine"
            :source-kind "hyperdoc-derived-link"
            :source-id "rel/annotation-has-machine"
            :derivation-kind "projection-link"
            :confidence 1.0
            :replay-hash "sha256:rel-annotation-has-machine")))
         (journal-event
          (make-shared-projection-journal-event
           :id "journal-event/annotation-123/project"
           :subject-key "annotation/123"
           :timestamp 2
           :operation "project-annotation"
           :target-id "annotation/123"
           :payload
           (let ((json (shared-projection-json-object)))
             (shared-projection-json-set json "projectionStatus"
                                         "rebuildable-shared-projection")
             (shared-projection-json-set json "topicmapId" 919822)
             json)
           :derivation-kind "projected-from-authoritative-state"
           :replay-status "replayable")))
    (make-shared-projection-context-window
     :id "context-window/919822"
     :title "Workspace annotation shared projection"
     :summary
     "Worked example of a rebuildable shared projection linked to a first-class behavior machine, run, and trace."
     :workspace-name "context-window"
     :topicmap-id 919822
     :focus-entity-ids '("annotation/123")
     :entity-ids '("annotation/123" "machine/workspace_annotation_lifecycle")
     :relation-ids '("rel/annotation-has-machine")
     :active-behavior-machine-ids '("workspace_annotation_lifecycle")
     :projection-status "rebuildable-shared-projection"
     :source-endpoints
     '("workspace/919815"
       "topicmap/919822"
       "journal/annotation/123"
       "machine/workspace_annotation_lifecycle")
     :entities (list annotation-entity machine-entity)
     :relations (list relation)
     :behavior-machines (list machine)
     :behavior-runs (list run)
     :behavior-traces (list trace)
     :journal-events (list journal-event))))
