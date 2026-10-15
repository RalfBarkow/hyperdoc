;;;; Reading the CTM Plan Page Authoring Plan
(defpackage #:dreyeck/work/ctm-page-authoring
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:v #:html-inspector-views))
  (:export #:read-ctm-authoring #:validate-ctm-authoring #:ctm-authoring-structure-error
           #:ctm-authoring-plan #:ctm-wbs #:ctm-authoring-workspace #:ctm-authoring-projection))
(in-package #:dreyeck/work/ctm-page-authoring)
(hyperdoc:see (hyperdoc:page "Authoring the CTM Plan Page" :hyperbook "dreyeck/work/reading"))
(hyperdoc:see (hyperdoc:page "CTM Plan Page WBS Dictionary" :hyperbook "dreyeck/work/reading"))

;; The plan page and its dictionary are the only sources. Every reading projects
;; the plan page again with the ordinary Work reader and reads the dictionary
;; beside it. Nothing here keeps a status, a dependency or an authorization of
;; its own, and nothing here writes.

(defparameter +plan-page+ "Authoring the CTM Plan Page")
(defparameter +dictionary-page+ "CTM Plan Page WBS Dictionary")
(defparameter +decomposes+ "work:relation/decomposes-into")
(defparameter +depends+ "work:relation/depends-on")
(defparameter +produces+ "work:relation/produces")
(defparameter +statuses+ '("open" "blocked" "verified"))
(defparameter +fields+ '("scope" "acceptance" "authority" "effect" "evidence"))
(defparameter +required-controls+
  '("site-root-slug-item" "exactly-one-item" "no-execution-without-authority"
    "stale-source-refused" "journal-continued" "other-items-unchanged" "fresh-reconstruction")
  "The controls the later concrete edit must have, whether an existing test
already exercises them or they are only planned.")

(define-condition ctm-authoring-structure-error (error)
  ((reason :initarg :reason :reader structure-error-reason))
  (:report (lambda (condition stream)
             (format stream "CTM plan page authoring refused: ~A" (structure-error-reason condition)))))
(defun %refuse (control &rest arguments)
  (error 'ctm-authoring-structure-error :reason (apply #'format nil control arguments)))

;;; Objects

(defclass ctm-authoring-reading ()
  ((projection :initarg :projection :reader reading-projection)
   (subjects :initarg :subjects :accessor reading-subjects)
   (entries :initarg :entries :reader reading-entries))
  (:documentation "One reading of the plan page and its dictionary: the plan
page's Work projection, one subject per declaration and the dictionary entries."))

(defclass ctm-subject ()
  ((topic :initarg :topic :reader subject-topic)
   (reading :initarg :reading :reader subject-reading))
  (:documentation "A declared WBS element, plan step or precondition. Its status
and label are those of its Work Topic declaration on the plan page."))
(defclass wbs-element (ctm-subject) ())
(defclass plan-step (ctm-subject) ())
(defclass plan-precondition (ctm-subject) ())

(defclass wbs-dictionary-entry ()
  ((element-id :initarg :element-id :reader entry-element-id)
   (title :initarg :title :reader entry-title)
   (fields :initarg :fields :reader entry-fields)
   (controls :initarg :controls :accessor entry-controls))
  (:documentation "One WBS Dictionary entry: scope, acceptance criterion,
authority, effect and evidence of one work package, with its planned controls."))

(defclass planned-control ()
  ((id :initarg :id :reader control-id)
   (coverage :initarg :coverage :reader control-coverage)
   (test :initarg :test :reader control-test)
   (marker :initarg :marker :reader control-marker)
   (text :initarg :text :reader control-text)
   (entry :initarg :entry :reader control-entry))
  (:documentation "A control the later edit must have. Coverage \"existing\"
names the test file and the exact text that already exercises it; \"planned\"
names none."))

(defclass step-authorization ()
  ((step :initarg :step :reader authorization-step))
  (:documentation "Which effect a plan step would perform and which authority
that needs. It records no grant: none exists, and a plan cannot make one."))

(defclass ctm-plan () ((reading :initarg :reading :reader view-reading)))
(defclass ctm-wbs () ((reading :initarg :reading :reader view-reading)))

(defun %property (topic key) (getf (tm:topicmap-topic-view-properties-of topic) key))
(defun subject-id (subject) (tm:topicmap-topic-id-of (subject-topic subject)))
(defun subject-label (subject) (tm:topicmap-topic-label-of (subject-topic subject)))
(defun subject-kind (subject) (%property (subject-topic subject) :kind))
(defun subject-status (subject) (%property (subject-topic subject) :status))
(defun entry-field (entry name) (cdr (assoc name (entry-fields entry) :test #'equal)))

(defmethod v:text-representation ((subject ctm-subject)) (subject-label subject))
(defmethod v:text-representation ((entry wbs-dictionary-entry))
  (format nil "WBS Dictionary: ~A" (entry-title entry)))
(defmethod v:text-representation ((control planned-control))
  (format nil "Planned control ~A" (control-id control)))
(defmethod v:text-representation ((authorization step-authorization))
  (format nil "Authorization of ~A" (subject-label (authorization-step authorization))))
(defmethod v:text-representation ((plan ctm-plan)) "CTM plan page authoring: plan")
(defmethod v:text-representation ((wbs ctm-wbs)) "CTM plan page authoring: WBS")

;;; Relations, read from the one projection

(defun %subject (reading id) (find id (reading-subjects reading) :key #'subject-id :test #'equal))
(defun %edges (reading relation)
  (remove relation (tm:topicmap-projection-associations-of (reading-projection reading))
          :key #'tm:topicmap-association-type-of :test-not #'equal))
(defun %targets (subject relation)
  (let ((reading (subject-reading subject)))
    (loop for edge in (%edges reading relation)
          when (equal (subject-id subject) (tm:topicmap-association-from-of edge))
            collect (%subject reading (tm:topicmap-association-to-of edge)))))
(defun %sources (subject relation)
  (let ((reading (subject-reading subject)))
    (loop for edge in (%edges reading relation)
          when (equal (subject-id subject) (tm:topicmap-association-to-of edge))
            collect (%subject reading (tm:topicmap-association-from-of edge)))))
(defun %of-kind (reading kind)
  (remove kind (reading-subjects reading) :key #'subject-kind :test-not #'equal))

(defun wbs-root (reading) (first (%of-kind reading "deliverable")))
(defun wbs-packages (reading) (%targets (wbs-root reading) +decomposes+))
(defun plan-steps (reading) (%of-kind reading "plan step"))
(defun step-result (step) (first (%targets step +produces+)))
(defun step-dependencies (step) (%targets step +depends+))
(defun step-unmet-preconditions (step)
  (remove-if-not (lambda (dependency) (and (typep dependency 'plan-precondition)
                                           (not (equal "verified" (subject-status dependency)))))
                 (step-dependencies step)))
(defun element-producer (element) (first (%sources element +produces+)))
(defun element-entry (element)
  (find (subject-id element) (reading-entries (subject-reading element))
        :key #'entry-element-id :test #'equal))
(defun precondition-dependents (precondition) (%sources precondition +depends+))
(defun step-authorization (step) (make-instance 'step-authorization :step step))
(defun authorization-entry (authorization) (element-entry (step-result (authorization-step authorization))))
(defun authorization-permitted-p (authorization)
  "Always false: no grant is recorded anywhere this reading looks."
  (declare (ignore authorization))
  nil)

;;; Reading

(defun %dom (source)
  (let ((plump:*tag-dispatchers* plump:*html-tags*)) (plump:parse source)))
(defun %descendants (node)
  (let ((result nil))
    (labels ((walk (parent)
               (loop for child across (plump:children parent)
                     when (plump:element-p child)
                       do (push child result) (walk child))))
      (walk node))
    (nreverse result)))
(defun %text (node)
  (string-trim '(#\Space #\Tab #\Newline #\Return) (plump:decode-entities (plump:text node))))

(defun read-wbs-dictionary (source)
  "The dictionary entries of SOURCE, the dictionary page's HTML, in page order."
  (loop for section in (plump:get-elements-by-tag-name (%dom source) "section")
        for id = (plump:attribute section "data-wbs-entry")
        when id
          collect
          (let* ((inner (%descendants section))
                 (named (remove-if-not (lambda (node) (plump:attribute node "data-field")) inner))
                 (heading (first (plump:get-elements-by-tag-name section "h2"))))
            (dolist (node named)
              (unless (member (plump:attribute node "data-field") (cons "controls" +fields+) :test #'equal)
                (%refuse "dictionary entry ~A has an unknown field ~S" id (plump:attribute node "data-field"))))
            (let* ((fields (loop for name in +fields+
                                 collect (let ((nodes (remove name named :key (lambda (node) (plump:attribute node "data-field"))
                                                                         :test-not #'equal)))
                                           (unless (= 1 (length nodes))
                                             (%refuse "dictionary entry ~A states ~A ~D times" id name (length nodes)))
                                           (let ((text (%text (first nodes))))
                                             (when (zerop (length text))
                                               (%refuse "dictionary entry ~A has an empty ~A" id name))
                                             (cons name text)))))
                   (lists (remove "controls" named :key (lambda (node) (plump:attribute node "data-field"))
                                                   :test-not #'equal))
                   (entry (make-instance 'wbs-dictionary-entry :element-id id :fields fields
                                         :title (if heading (%text heading) id))))
              (unless (= 1 (length lists)) (%refuse "dictionary entry ~A needs one list of controls" id))
              (setf (entry-controls entry)
                    (loop for item in (%descendants (first lists))
                          when (equal "li" (plump:tag-name item))
                            collect (make-instance 'planned-control
                                                   :id (plump:attribute item "data-control")
                                                   :coverage (plump:attribute item "data-coverage")
                                                   :test (plump:attribute item "data-test")
                                                   :marker (plump:attribute item "data-marker")
                                                   :text (%text item) :entry entry)))
              entry))))

(defun %page-source (title)
  (uiop:read-file-string (hyperdoc:file-of (work:work-page title)) :external-format :utf-8))

(defun read-ctm-authoring (&key (plan-source (%page-source +plan-page+))
                                (dictionary-source (%page-source +dictionary-page+)))
  "Read the plan page with the Work reader and its dictionary, then check them.
Signals CTM-AUTHORING-STRUCTURE-ERROR, or a Work source error, and writes nothing."
  (let* ((projection (work:project-work-breakdown plan-source :source (work:work-page +plan-page+)))
         (reading (make-instance 'ctm-authoring-reading :projection projection
                                 :entries (read-wbs-dictionary dictionary-source))))
    (setf (reading-subjects reading)
          (loop for topic in (tm:topicmap-projection-topics-of projection)
                for class = (cdr (assoc (%property topic :kind)
                                        '(("deliverable" . wbs-element) ("work package" . wbs-element)
                                          ("plan step" . plan-step) ("precondition" . plan-precondition))
                                        :test #'equal))
                when class collect (make-instance class :topic topic :reading reading)))
    (validate-ctm-authoring reading)))

;;; The four questions, checked apart

(defun %check-control (control)
  (let ((coverage (control-coverage control)))
    (cond ((equal coverage "planned")
           (when (or (control-test control) (control-marker control))
             (%refuse "planned control ~A names a test" (control-id control))))
          ((equal coverage "existing")
           (let ((path (and (control-test control)
                            (probe-file (asdf:system-relative-pathname "dreyeck/work/reading" (control-test control))))))
             (unless (and path (control-marker control)
                          (search (control-marker control) (uiop:read-file-string path :external-format :utf-8)))
               (%refuse "control ~A: ~S does not occur in ~A" (control-id control)
                        (control-marker control) (control-test control)))))
          (t (%refuse "control ~A has coverage ~S" (control-id control) coverage)))))

(defun %acyclic-p (steps)
  (let ((state (make-hash-table :test 'eq)))
    (labels ((visit (step)
               (case (gethash step state)
                 (:active nil)
                 (:done t)
                 (t (setf (gethash step state) :active)
                    (prog1 (every #'visit (remove-if-not (lambda (s) (typep s 'plan-step)) (step-dependencies step)))
                      (setf (gethash step state) :done))))))
      (every #'visit steps))))

(defun validate-ctm-authoring (reading)
  "READING, if its WBS, plan, statuses and dictionary hold together; otherwise a refusal."
  (let ((contracts (list +decomposes+ +depends+ +produces+))
        (packages (%of-kind reading "work package"))
        (steps (plan-steps reading))
        (entries (reading-entries reading)))
    ;; Work status: one vocabulary, nothing else.
    (dolist (subject (reading-subjects reading))
      (unless (member (subject-status subject) +statuses+ :test #'equal)
        (%refuse "~A has the status ~S, not one of ~{~A~^, ~}" (subject-id subject) (subject-status subject) +statuses+)))
    ;; Each relation joins the kinds its contract allows, and no other relation occurs.
    (dolist (edge (tm:topicmap-projection-associations-of (reading-projection reading)))
      (let* ((type (tm:topicmap-association-type-of edge))
             (from (%subject reading (tm:topicmap-association-from-of edge)))
             (to (%subject reading (tm:topicmap-association-to-of edge)))
             (kinds (list (and from (subject-kind from)) (and to (subject-kind to)))))
        (unless (member type contracts :test #'equal)
          (%refuse "the relation ~A is none of the plan page's three contracts" type))
        (unless (cond ((equal type +decomposes+) (equal kinds '("deliverable" "work package")))
                      ((equal type +produces+) (equal kinds '("plan step" "work package")))
                      (t (member kinds '(("plan step" "plan step") ("plan step" "precondition")) :test #'equal)))
          (%refuse "~A ~A ~A joins ~{a ~A and a ~A~}" (tm:topicmap-association-from-of edge) type
                   (tm:topicmap-association-to-of edge) kinds))))
    ;; WBS decomposition: one scope, decomposed once into every package.
    (unless (= 1 (length (%of-kind reading "deliverable"))) (%refuse "the WBS needs exactly one deliverable"))
    (dolist (package packages)
      (unless (= 1 (length (%sources package +decomposes+)))
        (%refuse "~A is not decomposed from the scope exactly once" (subject-id package))))
    ;; Plan: every step produces one package, every package has one step, no cycle.
    (dolist (step steps)
      (unless (= 1 (length (%targets step +produces+))) (%refuse "~A produces ~D packages" (subject-id step) (length (%targets step +produces+)))))
    (dolist (package packages)
      (unless (= 1 (length (%sources package +produces+))) (%refuse "~A is produced by ~D steps" (subject-id package) (length (%sources package +produces+)))))
    (unless (%acyclic-p steps) (%refuse "the plan's dependencies form a cycle"))
    ;; Status and dependency agree: blocked exactly while a precondition is unmet.
    (dolist (step steps)
      (let ((status (subject-status step)) (unmet (step-unmet-preconditions step)))
        (cond ((and (equal status "blocked") (null unmet))
               (%refuse "~A is blocked, but every precondition it depends on is verified" (subject-id step)))
              ((and (equal status "open") unmet)
               (%refuse "~A is open, but its precondition ~A is not verified" (subject-id step) (subject-id (first unmet))))
              ((and (equal status "verified")
                    (notevery (lambda (d) (equal "verified" (subject-status d))) (step-dependencies step)))
               (%refuse "~A is verified before everything it depends on" (subject-id step))))))
    ;; Dictionary: exactly one entry per package, every required control, each checked.
    (dolist (package packages)
      (unless (= 1 (count (subject-id package) entries :key #'entry-element-id :test #'equal))
        (%refuse "~A needs exactly one dictionary entry" (subject-id package))))
    (dolist (entry entries)
      (unless (find (entry-element-id entry) packages :key #'subject-id :test #'equal)
        (%refuse "the dictionary entry ~A names no work package" (entry-element-id entry))))
    (let ((controls (mapcan (lambda (entry) (copy-list (entry-controls entry))) entries)))
      (dolist (id +required-controls+)
        (unless (= 1 (count id controls :key #'control-id :test #'equal))
          (%refuse "the control ~A is planned ~D times" id (count id controls :key #'control-id :test #'equal))))
      (mapc #'%check-control controls))
    reading))

;;; Projections: the same Work Associations, with the subjects as Topic objects

(defun %projection (reading kinds relations source)
  (let* ((subjects (remove-if-not (lambda (s) (member (subject-kind s) kinds :test #'equal)) (reading-subjects reading)))
         (ids (mapcar #'subject-id subjects)))
    (tm:make-topicmap-projection
     :source source
     :topics (mapcar (lambda (subject)
                       (tm:make-topicmap-topic :id (subject-id subject) :label (subject-label subject)
                                               :object subject :type :ctm-page-authoring
                                               :view-properties (copy-list (tm:topicmap-topic-view-properties-of
                                                                            (subject-topic subject)))))
                     subjects)
     :associations (remove-if-not (lambda (edge)
                                    (and (member (tm:topicmap-association-type-of edge) relations :test #'equal)
                                         (member (tm:topicmap-association-from-of edge) ids :test #'equal)
                                         (member (tm:topicmap-association-to-of edge) ids :test #'equal)))
                                  (tm:topicmap-projection-associations-of (reading-projection reading)))
     :view-properties '(:width 1180 :height 760))))

(defun ctm-authoring-projection (reading)
  "WBS and plan together, as the native Workspace shows them."
  (%projection reading '("deliverable" "work package" "plan step" "precondition")
               (list +decomposes+ +depends+ +produces+) reading))
(defmethod tm:topicmap-projection-of ((reading ctm-authoring-reading)) (ctm-authoring-projection reading))
(defmethod tm:topicmap-projection-of ((wbs ctm-wbs))
  (%projection (view-reading wbs) '("deliverable" "work package") (list +decomposes+) wbs))
(defmethod tm:topicmap-projection-of ((plan ctm-plan))
  (%projection (view-reading plan) '("plan step" "precondition" "work package") (list +depends+ +produces+) plan))

(defun ctm-authoring-plan () (make-instance 'ctm-plan :reading (read-ctm-authoring)))
(defun ctm-wbs () (make-instance 'ctm-wbs :reading (read-ctm-authoring)))
(defvar *ctm-authoring-workspace* nil)
(hyperdoc:defexample ctm-authoring-workspace
  "Read the plan page and its dictionary into one native Workspace; nothing is written."
  (or *ctm-authoring-workspace*
      (setf *ctm-authoring-workspace*
            (tm:make-topicmap-workspace (ctm-authoring-projection (read-ctm-authoring)) "ctm-page-edit"))))

;;; Views

(defun %return-links (reading)
  (v:html
    (:p (v:object-ref (work:work-page +plan-page+) :display "Return to Authoring the CTM Plan Page" :select "Content")
        " / " (v:object-ref (make-instance 'ctm-plan :reading reading) :display "Plan" :select "Plan steps")
        " / " (v:object-ref (make-instance 'ctm-wbs :reading reading) :display "WBS" :select "WBS")
        " / " (v:object-ref (ctm-authoring-workspace) :display "Workspace" :select "Topicmap"))))
(defun %refs (subjects)
  (if subjects
      (v:html (loop for (subject . more) on subjects
                    do (v:html (v:object-ref subject :display (subject-label subject)) (when more (v:html ", ")))))
      (v:html "none")))

(v:defview ctm-plan-steps (plan ctm-plan)
  (v:html-view :title "Plan steps" :priority -1
    (let ((reading (view-reading plan)))
      (v:html
        (:p "Dependency, status and authorization are separate columns. A dependency orders the steps; a status says how far they are; neither permits an effect.")
        (:table :class "inspector-table"
          (:tr (:th "Step") (:th "Status") (:th "Produces") (:th "Depends on") (:th "Unmet preconditions") (:th "Authorization"))
          (dolist (step (plan-steps reading))
            (v:html
              (:tr (:td (v:object-ref step :display (subject-label step) :select "Plan step"))
                   (:td (:tt (v:esc (subject-status step))))
                   (:td (v:object-ref (step-result step) :display (subject-label (step-result step)) :select "WBS element"))
                   (:td (%refs (step-dependencies step)))
                   (:td (%refs (step-unmet-preconditions step)))
                   (:td (v:object-ref (step-authorization step) :display "none permitted" :select "Authorization"))))))
        (:h3 "Preconditions")
        (:ul (dolist (precondition (%of-kind reading "precondition"))
               (v:html (:li (v:object-ref precondition :display (subject-label precondition) :select "Precondition")
                            (v:esc (format nil " — ~A" (subject-status precondition)))))))
        (%return-links reading)))))

(v:defview ctm-wbs-view (wbs ctm-wbs)
  (v:html-view :title "WBS" :priority -1
    (let* ((reading (view-reading wbs)) (root (wbs-root reading)))
      (v:html
        (:p "Scope: " (v:object-ref root :display (subject-label root) :select "WBS element")
            (v:esc (format nil " — ~A" (subject-status root))))
        (:table :class "inspector-table"
          (:tr (:th "Work package") (:th "Status") (:th "Acceptance criterion") (:th "Authority") (:th "Produced by"))
          (dolist (package (wbs-packages reading))
            (let ((entry (element-entry package)))
              (v:html
                (:tr (:td (v:object-ref package :display (subject-label package) :select "WBS element"))
                     (:td (:tt (v:esc (subject-status package))))
                     (:td (v:esc (entry-field entry "acceptance")))
                     (:td (v:esc (entry-field entry "authority")))
                     (:td (v:object-ref (element-producer package) :display (subject-label (element-producer package)) :select "Plan step")))))))
        (:p (v:object-ref (work:work-page +dictionary-page+) :display "WBS Dictionary page" :select "Content"))
        (%return-links reading)))))

(v:defview wbs-element-view (element wbs-element)
  (v:html-view :title "WBS element" :priority -1
    (let ((entry (element-entry element)) (reading (subject-reading element)))
      (v:html
        (:h2 (v:esc (subject-label element)))
        (:p (v:esc (format nil "~A, status ~A, declared on the plan page." (subject-kind element) (subject-status element)))
            " " (v:object-ref (subject-topic element) :display "Inspect the Work Topic declaration"))
        (if entry
            (v:html
              (:table :class "inspector-table"
                (dolist (field +fields+)
                  (v:html (:tr (:td (v:esc field)) (:td (v:esc (entry-field entry field)))))))
              (:p "Planned controls: "
                  (if (entry-controls entry)
                      (v:html (loop for (control . more) on (entry-controls entry)
                                    do (v:html (v:object-ref control :display (control-id control) :select "Planned control")
                                               (when more (v:html ", ")))))
                      (v:html "none")))
              (:p "Produced by: " (v:object-ref (element-producer element) :display (subject-label (element-producer element)) :select "Plan step")))
            (v:html (:p "Decomposed into: " (%refs (wbs-packages reading)))))
        (%return-links reading)))))

(v:defview plan-step-view (step plan-step)
  (v:html-view :title "Plan step" :priority -1
    (v:html
      (:h2 (v:esc (subject-label step)))
      (:p (v:esc (format nil "Status ~A, declared on the plan page." (subject-status step)))
          " " (v:object-ref (subject-topic step) :display "Inspect the Work Topic declaration"))
      (:p "Produces: " (v:object-ref (step-result step) :display (subject-label (step-result step)) :select "WBS element"))
      (:p "Depends on: " (%refs (step-dependencies step)))
      (:p "Unmet preconditions: " (%refs (step-unmet-preconditions step)))
      (:p "Authorization: " (v:object-ref (step-authorization step) :display "none permitted" :select "Authorization"))
      (%return-links (subject-reading step)))))

(v:defview plan-precondition-view (precondition plan-precondition)
  (v:html-view :title "Precondition" :priority -1
    (v:html
      (:h2 (v:esc (subject-label precondition)))
      (:p (v:esc (format nil "Status ~A. A precondition is outside the WBS: this Work item does not produce it." (subject-status precondition))))
      (:p "Steps depending on it: " (%refs (precondition-dependents precondition)))
      (:p (v:object-ref (tm:topicmap-topic-object-of (subject-topic precondition)) :display "Carrier page" :select "Content")
          " / " (v:object-ref (subject-topic precondition) :display "Inspect the Work Topic declaration"))
      (%return-links (subject-reading precondition)))))

(v:defview step-authorization-view (authorization step-authorization)
  (v:html-view :title "Authorization" :priority -1
    (let* ((step (authorization-step authorization)) (entry (authorization-entry authorization))
           (package (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING"))
           (capability (and package (find-class (find-symbol "FEDWIKI-PAGE-AUTHORING-CAPABILITY" package) nil))))
      (v:html
        (:h2 (v:esc (format nil "Authorization of ~A" (subject-label step))))
        (:table :class "inspector-table"
          (:tr (:td "Effect") (:td (v:esc (entry-field entry "effect"))))
          (:tr (:td "Required authority") (:td (v:esc (entry-field entry "authority"))))
          (:tr (:td "Permitted now") (:td (:tt (v:esc (if (authorization-permitted-p authorization) "yes" "no"))))))
        (:p "No authorization is recorded. The plan's relations, the statuses and this object grant none; only the existing authoring path, holding a capability for the page and the Action, performs an effect.")
        (if capability
            (v:html (:p "Existing capability class in this image: " (v:object-ref capability)))
            (v:html (:p "The page-authoring capability class is not loaded in this image.")))
        (:p (v:object-ref step :display "Return to the plan step" :select "Plan step"))))))

(v:defview planned-control-view (control planned-control)
  (v:html-view :title "Planned control" :priority -1
    (v:html
      (:h2 (v:esc (control-id control)))
      (:p (v:esc (control-text control)))
      (:p (v:esc (format nil "Coverage: ~A." (control-coverage control))))
      (when (control-test control)
        (v:html (:p "Exercised by " (v:object-ref (asdf:system-relative-pathname "dreyeck/work/reading" (control-test control))
                                                 :display (control-test control) :select "Text")
                    " at " (:code (v:esc (control-marker control))))))
      (:p (v:object-ref (control-entry control) :display (entry-title (control-entry control)))))))

(v:defview wbs-dictionary-entry-view (entry wbs-dictionary-entry)
  (v:html-view :title "WBS Dictionary entry" :priority -1
    (v:html
      (:h2 (v:esc (entry-title entry)))
      (:table :class "inspector-table"
        (dolist (field +fields+)
          (v:html (:tr (:td (v:esc field)) (:td (v:esc (entry-field entry field)))))))
      (:p (v:object-ref (work:work-page +dictionary-page+) :display "WBS Dictionary page" :select "Content")))))
