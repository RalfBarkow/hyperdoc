;;;; Reconstructed page-lookup issue authored and compiled artifacts
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass page-lookup-issue-authored-role (authored-relation-role) ())

(defclass page-lookup-issue-authored-relation (authored-relation) ())

(defclass page-lookup-issue-authored-artifact (authored-relation-artifact) ())

(defclass page-lookup-issue-behavior-artifact (compiled-behavior-artifact) ())

(defclass page-lookup-issue-layout-artifact (compiled-layout-artifact) ())

(defmethod authored-relation-artifact-derived-artifacts-of
    ((artifact page-lookup-issue-authored-artifact))
  (declare (ignore artifact))
  (list (page-lookup-issue-behavior-artifact)
        (page-lookup-issue-layout-artifact)))

(defvar *page-lookup-issue-authored-artifact* nil)
(defvar *page-lookup-issue-behavior-artifact* nil)
(defvar *page-lookup-issue-layout-artifact* nil)

(defgeneric page-lookup-issue-authored-artifact-for (issue))
(defgeneric page-lookup-issue-behavior-artifact-for (issue))
(defgeneric page-lookup-issue-layout-artifact-for (issue))

(defmethod page-lookup-issue-authored-artifact-for (issue)
  (declare (ignore issue))
  nil)

(defmethod page-lookup-issue-behavior-artifact-for (issue)
  (declare (ignore issue))
  nil)

(defmethod page-lookup-issue-layout-artifact-for (issue)
  (declare (ignore issue))
  nil)

(defun make-page-lookup-issue-authored-role
    (&key id title summary kind binding participants findings)
  (make-instance 'page-lookup-issue-authored-role
                 :id id
                 :title title
                 :summary summary
                 :kind kind
                 :binding binding
                 :participants participants
                 :findings findings))

(defun page-lookup-issue-authored-role-from-source-definition (definition)
  (make-page-lookup-issue-authored-role
   :id (getf definition :id)
   :title (getf definition :title)
   :summary (getf definition :summary)
   :kind (getf definition :kind)
   :binding (getf definition :binding)
   :participants (getf definition :participants)
   :findings (getf definition :findings)))

(defun make-page-lookup-issue-authored-roles ()
  (mapcar #'page-lookup-issue-authored-role-from-source-definition
          (authored-relation-artifact-source-semantic-role-definitions-of
           (page-lookup-issue-authored-source-artifact))))

(defun make-page-lookup-issue-authored-relation
    (&key id title summary layer subject predicate object attributes)
  (make-instance 'page-lookup-issue-authored-relation
                 :id id
                 :title title
                 :summary summary
                 :layer layer
                 :subject subject
                 :predicate predicate
                 :object object
                 :attributes attributes))

(defun page-lookup-issue-authored-relation-attribute (relation key)
  (getf (authored-relation-attributes-of relation) key))

(defun page-lookup-issue-authored-relation-from-source-definition
    (definition)
  (make-page-lookup-issue-authored-relation
   :id (getf definition :id)
   :title (getf definition :title)
   :summary (getf definition :summary)
   :layer (getf definition :layer)
   :subject (getf definition :subject)
   :predicate (getf definition :predicate)
   :object (getf definition :object)
   :attributes (getf definition :attributes)))

(defun make-page-lookup-issue-authored-relations ()
  (mapcar #'page-lookup-issue-authored-relation-from-source-definition
          (authored-relation-artifact-source-relation-definitions-of
           (page-lookup-issue-authored-source-artifact))))

(defun make-page-lookup-issue-authored-artifact ()
  (let* ((source (page-lookup-issue-authored-source-artifact))
         (relations (make-page-lookup-issue-authored-relations))
         (semantic-relations
           (remove-if-not
            (lambda (relation)
              (eq (authored-relation-layer-of relation) :semantic))
            relations))
         (behavior-relations
           (remove-if-not
            (lambda (relation)
              (eq (authored-relation-layer-of relation) :behavior))
            relations))
         (layout-relations
           (remove-if-not
            (lambda (relation)
              (eq (authored-relation-layer-of relation) :layout))
            relations)))
    (make-instance
     'page-lookup-issue-authored-artifact
     :id (authored-relation-artifact-source-artifact-id-of source)
     :title (authored-relation-artifact-source-artifact-title-of source)
     :summary
     (authored-relation-artifact-source-artifact-summary-of source)
     :artifact-kind :authored-relation-artifact
     :workflow-role
     (authored-relation-artifact-source-workflow-role-of source)
     :compiler-pipeline
     (authored-relation-artifact-source-compiler-pipeline-of source)
     :semantic-roles (make-page-lookup-issue-authored-roles)
     :semantic-relations semantic-relations
     :behavior-relations behavior-relations
     :layout-relations layout-relations
     :relations relations
     :compiled-targets
     (authored-relation-artifact-source-compiled-targets-of source)
     :findings (authored-relation-artifact-source-findings-of source))))

(defun page-lookup-issue-authored-artifact ()
  (or *page-lookup-issue-authored-artifact*
      (setf *page-lookup-issue-authored-artifact*
            (make-page-lookup-issue-authored-artifact))))

(defun page-lookup-issue-authored-relations
    (&optional (artifact (page-lookup-issue-authored-artifact)))
  (authored-relation-artifact-relations-of artifact))

(defun page-lookup-issue-relations-by-layer
    (layer &optional (artifact (page-lookup-issue-authored-artifact)))
  (authored-relation-artifact-relations-by-layer artifact layer))

(defun page-lookup-issue-machine-relations
    (machine-key predicate
     &optional (artifact (page-lookup-issue-authored-artifact)))
  (remove-if-not
   (lambda (relation)
     (and (eq (authored-relation-layer-of relation) :behavior)
          (eq (authored-relation-subject-of relation) machine-key)
          (eq (authored-relation-predicate-of relation) predicate)))
   (page-lookup-issue-authored-relations artifact)))

(defun page-lookup-issue-transition-relations
    (machine-key &optional (artifact (page-lookup-issue-authored-artifact)))
  (remove-if-not
   (lambda (relation)
     (and (eq (authored-relation-layer-of relation) :behavior)
          (eq (authored-relation-predicate-of relation) :transition-to)
          (eq (page-lookup-issue-authored-relation-attribute relation :machine)
              machine-key)))
   (page-lookup-issue-authored-relations artifact)))

(defun page-lookup-issue-machine-state-from-relation (relation)
  (make-state-machine-state
   :id (authored-relation-object-of relation)
   :title (or (page-lookup-issue-authored-relation-attribute relation :title)
              (string-downcase
               (string (authored-relation-object-of relation))))
   :summary
   (page-lookup-issue-authored-relation-attribute relation :summary)
   :role (page-lookup-issue-authored-relation-attribute relation :role)
   :notes (page-lookup-issue-authored-relation-attribute relation :notes)))

(defun page-lookup-issue-machine-transition-from-relation (relation)
  (make-state-machine-transition
   :id (or (page-lookup-issue-authored-relation-attribute relation :id)
           (id-of relation))
   :title (page-lookup-issue-authored-relation-attribute relation :title)
   :from-state (authored-relation-subject-of relation)
   :to-state (authored-relation-object-of relation)
   :trigger
   (page-lookup-issue-authored-relation-attribute relation :trigger)
   :guard (page-lookup-issue-authored-relation-attribute relation :guard)
   :notes (page-lookup-issue-authored-relation-attribute relation :notes)))

(defun page-lookup-issue-machine-items
    (machine-key predicate
     &optional (artifact (page-lookup-issue-authored-artifact)))
  (mapcar #'authored-relation-object-of
          (page-lookup-issue-machine-relations
           machine-key
           predicate
           artifact)))

(defun compile-page-lookup-issue-machine
    (&optional (artifact (page-lookup-issue-authored-artifact)))
  (make-state-machine-definition
   :id "page_lookup_issue_lifecycle"
   :title "Page lookup issue lifecycle"
   :summary
   "Small lifecycle for a bounded page-lookup failure and its target chunk."
   :states
   (mapcar #'page-lookup-issue-machine-state-from-relation
           (page-lookup-issue-machine-relations
            :page-lookup-issue-lifecycle
            :has-state
            artifact))
   :transitions
   (mapcar #'page-lookup-issue-machine-transition-from-relation
           (page-lookup-issue-transition-relations
            :page-lookup-issue-lifecycle
            artifact))
   :initial-state
   (first (page-lookup-issue-machine-items
           :page-lookup-issue-lifecycle
           :initial-state
           artifact))
   :terminal-states
   (page-lookup-issue-machine-items
    :page-lookup-issue-lifecycle
    :terminal-state
    artifact)
   :events
   (page-lookup-issue-machine-items
    :page-lookup-issue-lifecycle
    :has-event
    artifact)
   :source-evidence
   '((:layer :semantic :reference :page-lookup-issue)
     (:layer :semantic :reference :target-chunk))))

(defun page-lookup-issue-xml-escape (value)
  (let ((text (if value (format nil "~A" value) "")))
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

(defun page-lookup-issue-state-machine-scxml-text (machine)
  (with-output-to-string (stream)
    (format stream
            "<scxml name=\"~A\" initial=\"~A\" xmlns=\"http://www.w3.org/2005/07/scxml\">~%"
            (page-lookup-issue-xml-escape (id-of machine))
            (page-lookup-issue-xml-escape
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
                    (page-lookup-issue-xml-escape state-id))
            (progn
              (format stream "  <state id=\"~A\">~%"
                      (page-lookup-issue-xml-escape state-id))
              (dolist (transition outgoing)
                (format stream "    <transition")
                (when (state-machine-transition-trigger-of transition)
                  (format stream
                          " event=\"~A\""
                          (page-lookup-issue-xml-escape
                           (state-machine-transition-trigger-of transition))))
                (format stream
                        " target=\"~A\"/>~%"
                        (page-lookup-issue-xml-escape
                         (state-machine-transition-to-state-of transition))))
              (format stream "  </state>~%")))))
    (write-string "</scxml>" stream)))

(defun page-lookup-issue-layout-pane-relations (relations)
  (remove-if-not
   (lambda (relation)
     (member (authored-relation-predicate-of relation)
             '(:contains :after :opens-from)
             :test #'eq))
   relations))

(defun page-lookup-issue-layout-ordered-panes (relations)
  (let* ((contains
           (remove-if-not
            (lambda (relation)
              (and (eq (authored-relation-subject-of relation)
                       :lookup-issue-pane)
                   (eq (authored-relation-predicate-of relation) :contains)))
            relations))
         (contained-panes (mapcar #'authored-relation-object-of contains))
         (after-relations
           (remove-if-not
            (lambda (relation)
              (eq (authored-relation-predicate-of relation) :after))
            relations)))
    (labels ((after-p (pane)
               (find pane
                     after-relations
                     :key #'authored-relation-subject-of
                     :test #'eq)))
      (append (remove-if #'after-p contained-panes)
              (remove-if-not #'after-p contained-panes)))))

(defun compile-page-lookup-issue-layout-spec (relations)
  (list :surface 'page-lookup-issue
        :primary-pane :lookup-issue-pane
        :ordered-panes (page-lookup-issue-layout-ordered-panes relations)
        :relations
        (mapcar
         (lambda (relation)
           (list (authored-relation-predicate-of relation)
                 (authored-relation-subject-of relation)
                 (authored-relation-object-of relation)))
         relations)))

(defun page-lookup-issue-behavior-artifact ()
  (or *page-lookup-issue-behavior-artifact*
      (let* ((authored-artifact (page-lookup-issue-authored-artifact))
             (relations
               (authored-relation-artifact-behavior-relations-of
                authored-artifact))
             (machine (compile-page-lookup-issue-machine authored-artifact)))
        (setf *page-lookup-issue-behavior-artifact*
              (make-instance
               'page-lookup-issue-behavior-artifact
               :id "page-lookup-issue-behavior-artifact"
               :title "Page lookup issue behavior"
               :summary
               "Compiled lifecycle artifact for page-lookup issue diagnosis."
               :artifact-kind :compiled-behavior-artifact
               :authored-artifact authored-artifact
               :compiler-stage :behavior-compilation
               :compiler-inputs (list authored-artifact)
               :relations relations
               :primary-machine machine
               :primary-machine-scxml
               (page-lookup-issue-state-machine-scxml-text machine)
               :findings
               '("Behavior compiles from the page-lookup issue authored artifact."
                 "The lifecycle remains open -> needs-target-chunk -> fixed."))))))

(defun page-lookup-issue-layout-artifact ()
  (or *page-lookup-issue-layout-artifact*
      (let* ((authored-artifact (page-lookup-issue-authored-artifact))
             (relations
               (authored-relation-artifact-layout-relations-of
                authored-artifact))
             (pane-relations
               (page-lookup-issue-layout-pane-relations relations)))
        (setf *page-lookup-issue-layout-artifact*
              (make-instance
               'page-lookup-issue-layout-artifact
               :id "page-lookup-issue-layout-artifact"
               :title "Page lookup issue layout"
               :summary
               "Compiled layout artifact for the page-lookup issue pane surface."
               :artifact-kind :compiled-layout-artifact
               :authored-artifact authored-artifact
               :compiler-stage :layout-compilation
               :compiler-inputs (list authored-artifact)
               :relations relations
               :pane-relations pane-relations
               :layout-spec (compile-page-lookup-issue-layout-spec relations)
               :findings
               '("Layout compiles from the page-lookup issue authored artifact."
                 "Overview remains first and Repair remains secondary."))))))
