;;;; Editing the existing Work graph through its source-authoritative requests.
(in-package #:dreyeck/work/authoring)

;; A concrete Inspector selection owns navigation context. Its registered
;; selection is still the one existing OPERATION-REQUEST, never a UI registry.
(defclass work-editor-context ()
  ((topic :initarg :topic :reader editor-topic)
   (workspace :initarg :workspace :reader editor-workspace)
   (projection :initarg :projection :reader editor-projection)
   (selection :initarg :selection :initform nil :reader editor-selection)
   (target-context :initarg :target-context :initform nil :reader editor-target-context)))

;; Only complete requests and their plans have entries here. They are fresh
;; objects belonging to one callback chain; shared Topics/selections never do.
(defvar *work-editor-contexts* (make-hash-table :test 'eq :weakness :key))
(defvar *work-editor-outcomes* (make-hash-table :test 'eq :weakness :key))

(defun %editor-context (object) (gethash object *work-editor-contexts*))
(defun %remember-editor-context (object context)
  (assert (typep object '(or work:work-status-change-request
                            work:work-relationship-creation-request
                            work-status-change-plan work-relationship-creation-plan)))
  (setf (gethash object *work-editor-contexts*) context)
  object)

(defun %topic-workspace (topic)
  ;; A directly inspected Topic has no pane context. Use only its recorded
  ;; snapshot, never current source or a stable-ID relocation.
  (let* ((occurrence (work:topic-source-occurrence topic))
         (projection (work:project-work-breakdown
                      (work:topic-occurrence-snapshot occurrence)
                      :source (work:topic-occurrence-page occurrence))))
    (tm:make-topicmap-workspace projection (tm:topicmap-topic-id-of topic))))

(defmethod m::render-workspace-point-editor ((workspace tm:topicmap-workspace)
                                            (topic work:work-topic))
  (when (work:topic-source-occurrence topic)
    (views:html
      (:p (views:object-ref
           (make-instance 'work-editor-context :topic topic :workspace workspace
                          :projection (tm:topicmap-workspace-projection-of workspace))
           :display "Open Work Topic")))))

(defun select-work-operation (operation topic &optional (workspace (%topic-workspace topic))
                                                      (projection (tm:topicmap-workspace-projection-of workspace)))
  "Bind this UI selection to its observation, referencing the shared request."
  (make-instance 'work-editor-context :topic topic :workspace workspace :projection projection
                 :selection (ops:work-topic-operation-request operation topic)))

(defun %work-operations (topic workspace projection)
  (views:html-view :title "Work Operations" :priority 1
    (views:html
      (:p (views:object-ref topic :display (tm:topicmap-topic-label-of topic)))
      (dolist (operation (list (w:change-work-status-operation) (w:create-relationship-operation)))
        (let ((selected operation))
          (views:eval-button (w:semantic-operation-identity-title selected)
                            (views:thunk
                              (handler-case (select-work-operation selected topic workspace projection)
                                (error (condition) condition)))))))))

(views:defview contextual-work-operations (context work-editor-context)
  (unless (editor-selection context)
    (%work-operations (editor-topic context) (editor-workspace context) (editor-projection context))))

(views:defview work-operations (topic work:work-topic)
  (when (work:topic-source-occurrence topic)
    (let ((workspace (%topic-workspace topic)))
      (%work-operations topic workspace (tm:topicmap-workspace-projection-of workspace)))))

(defun %selection-context (selection)
  (etypecase selection
    (work-editor-context selection)
    (r:operation-request
     (let* ((topic (ops:declared-work-topic (r:operation-request-occurrence selection)))
            (workspace (%topic-workspace topic)))
       (make-instance 'work-editor-context :topic topic :workspace workspace
                      :projection (tm:topicmap-workspace-projection-of workspace)
                      :selection selection)))))

(defun complete-editor-status (selection proposed)
  "Complete the shared selection, retaining only this callback's UI context."
  (handler-case
      (let* ((context (%selection-context selection))
             (request (work:request-work-status-change
                       (editor-selection context) (editor-topic context) proposed)))
        (%remember-editor-context request context))
    (error (condition) condition)))

(views:defview contextual-status-arguments (context work-editor-context)
  (when (and (editor-selection context)
             (eq (r:operation-request-operation (editor-selection context)) (w:change-work-status-operation)))
    (views:html-view :title "Change work status" :priority 0
      (views:html (:p (views:object-ref (editor-selection context) :display "Inspect registered selection"))
                  (%render-status-actions (editor-topic context) context)))))

(defun complete-editor-relationship (selection target relation)
  "Keep this callback's target occurrence and authored relation identity."
  (handler-case
      (let ((context (%selection-context selection)))
        (%remember-editor-context
         (work:request-work-relationship-creation (editor-selection context) target relation)
         context))
    (error (condition) condition)))

(defun %relationship-choices (selection target)
  (let* ((context (%selection-context selection))
         (associations (tm:topicmap-projection-associations-of (editor-projection context)))
         (foreign (not (eq (work:topic-occurrence-page (work:topic-source-occurrence (editor-topic context)))
                            (work:topic-occurrence-page (work:topic-source-occurrence target)))))
         (relations (if foreign
                        (handler-case (progn (work::request-addresses-bridge (editor-selection context) target)
                                             (list "work:relation/addresses"))
                          (error () nil))
                        (remove-duplicates (mapcar #'tm:topicmap-association-type-of associations)
                                      :test #'equal :from-end t))))
    (views:html-view :title "Choose relation" :priority 1
      (views:html
        (:p "Target: " (views:object-ref target :display (tm:topicmap-topic-label-of target)))
        (dolist (relation relations)
          (let* ((value relation)
                 (association (find value associations :key #'tm:topicmap-association-type-of :test #'equal))
                 (label (if association (or (tm:topicmap-association-relation-label association) value) "addresses")))
            (views:eval-button (format nil "Use relation: ~A" label)
                              (views:thunk (complete-editor-relationship context target value)))))))))

(defun %relationship-arguments (context)
  (let ((selection (editor-selection context)))
    (when (and selection
               (eq (r:operation-request-operation selection) (w:create-relationship-operation))
               (typep (r:operation-request-occurrence selection) 'work:work-topic-source-occurrence))
      (views:html-view :title "Create relationship" :priority 0
        (views:html
          (:p (views:object-ref selection :display "Inspect registered selection"))
          (:p "Choose an existing target from the selected Work projection.")
          (when (and (equal "work item" (getf (tm:topicmap-topic-view-properties-of (editor-topic context)) :kind))
                     (tm:topicmap-projection-topic-by-id (editor-projection context) "work:relation/addresses"))
            (views:eval-button "Inspect foreign Constraint: Serialized verified effect"
                              (views:thunk (inspect-addresses-target context))))
          (dolist (topic (tm:topicmap-projection-topics-of (editor-projection context)))
            (let ((target topic))
              (views:eval-button (format nil "Target: ~A" (tm:topicmap-topic-label-of target))
                                (views:thunk (%relationship-choices context target))))))))))

(views:defview contextual-relationship-arguments (context work-editor-context)
  (%relationship-arguments context))

(views:defview relationship-arguments (selection r:operation-request)
  (when (and (eq (r:operation-request-operation selection) (w:create-relationship-operation))
             (typep (r:operation-request-occurrence selection) 'work:work-topic-source-occurrence))
    (%relationship-arguments (%selection-context selection))))

(defun preview-work-request (request)
  "Construct the existing plan for inspection. A plan writes nothing."
  (handler-case
      (%remember-editor-context
       (etypecase request
         (work:work-status-change-request (plan-work-status-change request))
         (work:work-relationship-creation-request (plan-work-relationship-creation request)))
       (%editor-context request))
    (error (condition) condition)))

(defun %request-page (request)
  (etypecase request
    (work:work-status-change-request
     (work:topic-occurrence-page (work:work-status-change-occurrence request)))
    (work:work-relationship-creation-request
     (work:work-relationship-creation-authority-page request))))

(defun %request-point (request)
  (let ((context (%editor-context request)))
    (if context (tm:topicmap-workspace-point-of (editor-workspace context))
        (etypecase request
          (work:work-status-change-request
           (tm:topicmap-topic-id-of (work:work-status-change-topic request)))
          (work:work-relationship-creation-request
           (work:topic-occurrence-topic (work:work-relationship-creation-from-occurrence request)))))))

(defun %editor-environment ()
  (handler-case (dreyeck/workflow/authoring:make-authoring-environment)
    (error () nil)))

(defun execute-work-request (request &optional (environment (%editor-environment)))
  "Execute the request through the existing executor, which replans it.
After applied or unverified, read the actual file through WORK-PROJECTION;
return a new Workspace with an inspectable outcome, or the refusal outcome."
  (let* ((point (%request-point request))
         (outcome (etypecase request
                    (work:work-status-change-request (execute-work-status-change request environment))
                    (work:work-relationship-creation-request (execute-work-relationship-creation request environment))))
         (status (etypecase outcome
                   (work-status-change-outcome (work-status-change-outcome-status outcome))
                   (work-relationship-creation-outcome (work-relationship-creation-outcome-status outcome)))))
    (if (member status '(:applied :unverified))
        (handler-case
            (let* ((projection (work:work-projection :page (%request-page request)))
                   (retained (tm:topicmap-projection-topic-by-id projection point))
                   (workspace (tm:make-topicmap-workspace
                               projection (if retained point
                                              (tm:topicmap-topic-id-of
                                               (first (tm:topicmap-projection-topics-of projection)))))))
              (setf (gethash workspace *work-editor-outcomes*) outcome)
              workspace)
          (error (condition)
            ;; The effect has already happened. Keep its outcome inspectable
            ;; and report that reopening the graph failed; never retry it.
            (setf (gethash outcome *work-editor-outcomes*) condition)
            outcome))
        outcome)))

(defun %render-request-preview (request)
  (views:html
    (views:eval-button "Preview plan" (views:thunk (preview-work-request request)))))

(views:defview status-request-editor (request work:work-status-change-request)
  (views:html-view :title "Work request" :priority 0
    (views:html (views:transclusion (work::work-status-change-request-overview request))
                (%render-request-preview request))))

(views:defview relationship-request-editor (request work:work-relationship-creation-request)
  (views:html-view :title "Work request" :priority 0
    (views:html (views:transclusion (work::work-relationship-creation-request-overview request))
                (%render-request-preview request))))

(defun %render-request-execution (request)
  (views:html
    (:p "Execution revalidates the request against current source and constructs a new plan.")
    (views:eval-button "Execute request after revalidation"
                      (views:thunk (execute-work-request request)))))

(views:defview status-plan-editor (plan work-status-change-plan)
  (views:html-view :title "Work plan" :priority 0
    (views:html (views:transclusion (work-status-change-plan-overview plan))
                (%render-request-execution (work-status-change-plan-request plan)))))

(views:defview relationship-plan-editor (plan work-relationship-creation-plan)
  (views:html-view :title "Work plan" :priority 0
    (views:html (views:transclusion (work-relationship-creation-plan-overview plan))
                (%render-request-execution (work-relationship-creation-plan-request plan)))))

(views:defview editor-work-breakdown (workspace tm:topicmap-workspace)
  (let ((outcome (gethash workspace *work-editor-outcomes*)))
    (when outcome
      (let ((status (etypecase outcome
                      (work-status-change-outcome (work-status-change-outcome-status outcome))
                      (work-relationship-creation-outcome (work-relationship-creation-outcome-status outcome)))))
        (views:html-view :title "Work Breakdown" :priority 1
          (views:html
            (:p (views:esc (if (eq status :applied) "Applied. Work Breakdown reread from source."
                               "Unverified effect. Current source reread; the requested change is not verified.")))
            (:p (views:object-ref outcome :display "Inspect execution outcome"))
            (views:eval-button "Inspect Evidence neighborhood"
                              (views:thunk (%inspect-evidence-neighborhood :page (%request-page
                                  (etypecase outcome
                                    (work-status-change-outcome (work-status-change-outcome-request outcome))
                                    (work-relationship-creation-outcome (work-relationship-creation-outcome-request outcome)))))))
            (views:transclusion (m::👀topicmap workspace))))))))

(defun %render-reopening-failure (outcome)
  (let ((condition (gethash outcome *work-editor-outcomes*)))
    (when condition
      (views:html-view :title "Work Breakdown reread failed" :priority 0
        (views:html (:p "The execution outcome exists, but opening a fresh Work Breakdown failed.")
                    (:p (views:object-ref condition)))))))

(views:defview status-reread-failure (outcome work-status-change-outcome)
  (%render-reopening-failure outcome))
(views:defview relationship-reread-failure (outcome work-relationship-creation-outcome)
  (%render-reopening-failure outcome))


;; An explicit foreign inspection retains BOTH concrete Workspace chains.
;; No target Topic/selection is entered in a shared UI registry.
(defclass inspected-addresses-target ()
  ((source :initarg :source :reader inspected-target-source)
   (topic :initarg :topic :reader inspected-target-topic)
   (workspace :initarg :workspace :reader inspected-target-workspace)))
(defun inspect-addresses-target (context)
  (handler-case
      (let* ((owner (work:topic-occurrence-page (work:topic-source-occurrence (editor-topic context))))
             (book (hyperbook:hyperbook-of owner))
             (page (hyperbook:find-page book "Deriving HyperDoc Authoring Constraints" :signal-error? t))
             (projection (work:project-work-breakdown
                          (uiop:read-file-string (work::%page-path page) :external-format :utf-8) :source page
                          :find-page (lambda (title book-id)
                                       (work:work-page title (if (equal book-id "dreyeck/work/reading")
                                                                (hyperbook:id-of book) book-id)))))
             (topic (tm:topicmap-projection-topic-by-id projection "serialized-verified-effect")))
        (unless topic (error "The bounded Constraint is not declared"))
        (make-instance 'inspected-addresses-target :source context :topic topic
                       :workspace (tm:make-topicmap-workspace projection "serialized-verified-effect")))
    (error (c) c)))
(views:defview inspected-foreign-addresses-target (target inspected-addresses-target)
  (views:html-view :title "Inspected foreign target" :priority 0
    (views:html
      (:p "Exact foreign Constraint: " (views:object-ref (inspected-target-topic target)
                                                       :display (tm:topicmap-topic-label-of (inspected-target-topic target))))
      (:p "Foreign Workspace: " (views:object-ref (inspected-target-workspace target)))
      (:p "Source Workspace: " (views:object-ref (editor-workspace (inspected-target-source target))))
      (views:eval-button "Use inspected target"
        (views:thunk
          (let* ((source (inspected-target-source target))
                 (context (make-instance 'work-editor-context :topic (editor-topic source)
                            :workspace (editor-workspace source) :projection (editor-projection source)
                            :selection (editor-selection source) :target-context target)))
            (%relationship-choices context (inspected-target-topic target))))))))

(defun %inspect-evidence-neighborhood (&key page)
  (handler-case (work:evidence-neighborhood :page page) (error (c) c)))
