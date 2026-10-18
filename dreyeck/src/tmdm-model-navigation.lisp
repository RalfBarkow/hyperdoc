;;;; Semantic Inspector views over the independent TMDM objects.
(defpackage #:dreyeck/inspector/tmdm
  (:use #:cl)
  (:local-nicknames (#:m #:topic-maps.tmdm) (#:v #:html-inspector-views) (#:ev #:dreyeck/evaluation-record))
  (:export #:model-map-of #:register-execution #:executions-of #:model-state))
(in-package #:dreyeck/inspector/tmdm)

;; Runtime provenance only. No new Topic identity, model slots or persisted graph.
(defvar *executions-by-map* (make-hash-table :test #'eq))
(defun model-map-of (object)
  (typecase object
    (m:topic-map object)
    (m:topic (m:topic-parent object))
    (m:topic-name (m:topic-parent (m:topic-name-parent object)))))
(defun register-execution (map record)
  (check-type map m:topic-map)
  (unless (eq map (ev:evaluation-result-of record))
    (error "Execution result does not designate this Map; provenance binding refused."))
  (pushnew record (gethash map *executions-by-map*) :test #'eq)
  record)
(defun executions-of (object)
  (copy-list (gethash (model-map-of object) *executions-by-map*)))
(defun model-state (map)
  "Snapshot public properties/references to qualify a dated observation.
This is execution metadata, not another information-item model."
  (list
   (loop for topic in (m:topic-map-topics map) collect
     (list topic (mapcar #'copy-seq (m:topic-item-identifiers topic))
           (mapcar #'copy-seq (m:topic-subject-identifiers topic))
           (mapcar #'copy-seq (m:topic-subject-locators topic))
           (loop for name in (m:topic-names topic) collect
             (list name (m:topic-name-parent name) (m:topic-name-type name) (copy-seq (m:topic-name-value name))))
           (loop for occurrence in (m:topic-occurrences topic) collect
             (list occurrence (m:occurrence-parent occurrence) (m:occurrence-type occurrence)
                   (copy-seq (m:occurrence-value occurrence)) (copy-seq (m:occurrence-datatype occurrence))
                   (mapcar #'copy-seq (m:occurrence-item-identifiers occurrence))))))
   (loop for association in (m:topic-map-associations map) collect
     (list association (m:association-parent association) (m:association-type association)
           (loop for role in (m:association-roles association) collect
             (list role (m:association-role-parent role) (m:association-role-type role) (m:association-role-player role)))))))

(defun topic-label (topic)
  (let ((current (m:canonical-topic topic)))
    (cond ((member (m:default-name-type-identifier) (m:topic-subject-identifiers current) :test #'string=)
           "Default name type")
          (t (let* ((id (or (first (m:topic-item-identifiers current))
                           (first (m:topic-subject-identifiers current))
                           (first (m:topic-subject-locators current))))
                   (fragment (and id (position #\# id :from-end t))))
               (format nil "Topic ~A" (if fragment (subseq id fragment) (or id "(unidentified)"))))))))
(defmethod v:text-representation ((map m:topic-map))
  (format nil "TMDM Topic Map (~D Topics)" (length (m:topic-map-topics map))))
(defmethod v:text-representation ((topic m:topic)) (topic-label topic))
(defmethod v:text-representation ((name m:topic-name))
  (format nil "Topic Name ~S" (copy-seq (m:topic-name-value name))))

(defun refs (objects &optional select)
  (v:html (:ul (dolist (object objects)
                 (v:html (:li (v:object-ref object :select select)))))))
(v:defview tmdm-model (map m:topic-map)
  (v:html-view :title "Topics" :priority -10
    (v:html (:h2 "TMDM Topic Map")
      (:p "Actual Topic objects; labels are display text, not additional identifiers.")
      (refs (m:topic-map-topics map) "Topic")
      (:p "Associations: " (v:object-ref (m:topic-map-associations map) :display "Association objects")))))
(v:defview tmdm-model (topic m:topic)
  (v:html-view :title "Topic" :priority -10
    (let ((current (m:canonical-topic topic)))
      (v:html (:h2 (v:esc (topic-label current)))
        (unless (eq topic current)
          (v:html (:p "Retained handle: these properties describe its current representative. "
                       (v:object-ref current :display "Canonical Topic" :select "Topic"))))
        (:p (v:object-ref (m:topic-parent current) :display "Parent Topic Map" :select "Topics"))
        (:table :class "inspector-table"
          (:tr (:th "Identity property") (:th "Locators"))
          (:tr (:td "Item Identifiers") (:td (refs (m:topic-item-identifiers current))))
          (:tr (:td "Subject Identifiers") (:td (refs (m:topic-subject-identifiers current))))
          (:tr (:td "Subject Locators") (:td (refs (m:topic-subject-locators current)))))
        (:h3 "Topic Names") (refs (m:topic-names current) "Name")
        (:p "Occurrences: " (v:object-ref (m:topic-occurrences current) :display "Occurrence objects"))
        (:p "Roles played: " (v:object-ref (m:topic-roles-played current) :display "Role objects"))))))
(v:defview tmdm-model (name m:topic-name)
  (v:html-view :title "Name" :priority -10
    (let ((current (m:canonical-topic-name name)))
      (v:html (:h2 "TMDM Topic Name")
        (unless (eq name current)
          (v:html (:p "Retained handle: these properties describe its current representative. "
                       (v:object-ref current :display "Canonical Name" :select "Name"))))
        (:table :class "inspector-table"
          (:tr (:td "Value") (:td (v:object-ref (m:topic-name-value current))))
          (:tr (:td "Parent Topic") (:td (v:object-ref (m:topic-name-parent current) :select "Topic")))
          (:tr (:td "Type Topic") (:td (v:object-ref (m:topic-name-type current) :select "Topic"))))
        (:p "Type is an existing Topic object. It is not a datatype locator or a new HyperDoc subject.")))))

(v:defview tmdm-definitions (object structure-object)
  (when (model-map-of object)
    (v:html-view :title "Definitions" :priority 10
      (let ((functions (typecase object
                         (m:topic-map '(m:make-topic-map m:topic-map-topics m:normalize-topic-map))
                         (m:topic '(m:intern-topic m:canonical-topic m:merge-topics m:topic-names))
                         (m:topic-name '(m:add-name m:canonical-topic-name m:topic-name-parent m:topic-name-type m:topic-name-value)))))
        (v:html (:h2 "Loaded Lisp definitions")
          (:p "These references inspect the actual loaded class and function objects. Source views describe loaded definitions; a Git file is separate revision evidence.")
          (:p (v:object-ref (class-of object) :display "Information-item class" :select "Source code"))
          (dolist (symbol functions)
            (v:html (:p (v:object-ref (symbol-function symbol) :display (string-downcase (symbol-name symbol)) :select "Source code"))))
          (:p (v:object-ref (asdf:find-system "topic-maps/tmdm") :display "TMDM ASDF system")))))))
(v:defview tmdm-evidence (object structure-object)
  (when (model-map-of object)
    (v:html-view :title "Evidence" :priority 20
      (v:html (:h2 "Execution provenance")
        (:p "Map-level execution contexts, not item-level source spans. Items added later are not thereby attributed to the CTM source.")
        (let ((records (executions-of object)))
          (if records
              (refs records)
              (v:html (:p "No CTM source or execution has been registered for this object. Its model properties remain inspectable."))))))))
