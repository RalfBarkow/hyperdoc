;;;; Inspector integration for DOM association flow
;;
;;;; Copyright (c) 2026

(in-package :clog-moldable-inspector)

(defun dom-association-attribute-value (element attribute-name)
  (let ((value (ignore-errors
                 (clog:attribute element attribute-name))))
    (and (stringp value)
         (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) value)))
           (and (> (length trimmed) 0)
                (not (member trimmed '("undefined" "null") :test #'string=))
                trimmed)))))

(defun dom-association-json-present-p (value)
  (and (stringp value)
       (> (length value) 0)))

(defun dom-association-json-length (value)
  (if (stringp value)
      (length value)
      0))

(defun dom-association-active-view-title (pane)
  (with-slots (views active-view) pane
    (let ((view (nth active-view views)))
      (and view
           (ignore-errors
             (hv:view-title view))))))

(defparameter +view-contract-action-label+ "Inspect view contract")

(defparameter +view-contract-action-icon+
  "<svg class=\"hyperdoc-view-contract-icon\" viewBox=\"0 0 24 24\" aria-hidden=\"true\" focusable=\"false\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M6 3.75h8.25L18 7.5v12.75H6z\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linejoin=\"round\"/><path d=\"M14.25 3.75V7.5H18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linejoin=\"round\"/><path d=\"M8.75 10.25h6.5M8.75 13h6.5M8.75 15.75h3.5\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linecap=\"round\"/><circle cx=\"16.25\" cy=\"16.25\" r=\"2.15\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\"/><path d=\"m17.85 17.85 2.15 2.15\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linecap=\"round\"/></svg>")

(defun active-inspector-view-object (pane)
  (with-slots (views active-view) pane
    (nth (or active-view 0) views)))

(defun rendered-view-layout-snapshot-provider ()
  (loop for package-name in '(:hyperdoc/inspector
                              :hyperdoc
                              :hyperbook/server
                              :clog-moldable-inspector)
        for package = (find-package package-name)
        for symbol = (and package
                          (find-symbol "RENDERED-VIEW-LAYOUT-SNAPSHOT"
                                       package))
        when (and symbol (fboundp symbol))
          return symbol))

(defun view-contract-layout-evidence (view subject)
  (let ((provider (rendered-view-layout-snapshot-provider)))
    (if provider
        (handler-case
            (let ((snapshot (funcall provider view subject)))
              (if snapshot
                  (list (list :layout-snapshot snapshot))
                  '((:layout-snapshot :missing-evidence)
                    (:explanation
                     "A rendered-view-layout-snapshot provider exists, but it returned no snapshot for this view/subject."))))
          (error (condition)
            `((:layout-snapshot :missing-evidence)
              (:explanation
               ,(format nil
                        "The rendered-view-layout-snapshot provider failed: ~A"
                        condition)))))
        '((:layout-snapshot :missing-evidence)
          (:explanation
           "No rendered-view-layout-snapshot provider is loaded for this view/subject.")))))

(defun view-contract-evidence-with-layout (spec layout-evidence)
  (append layout-evidence
          (remove :layout-snapshot
                  (hv:evidence-of spec)
                  :key #'first)))

(defun view-contract-for-view-and-subject (view subject)
  (let ((spec (hv:view-specification view subject)))
    (setf (hv:evidence-of spec)
          (view-contract-evidence-with-layout
           spec
           (view-contract-layout-evidence view subject)))
    spec))

(defun view-contract-for-pane (pane)
  (with-slots (object) pane
    (let ((view (active-inspector-view-object pane)))
      (unless view
        (error "No active inspector view is available for this pane."))
      (view-contract-for-view-and-subject view object))))

(defun inspect-view-contract-for-pane (pane event)
  (declare (ignore event))
  (with-slots (inspector) pane
    (create-pane inspector (view-contract-for-pane pane))))

(defclass inspector-title-bar-ui-trace ()
  ((name :initarg :name :reader inspector-title-bar-ui-trace-name)
   (events :initarg :events :reader inspector-title-bar-ui-trace-events)
   (steps :initarg :steps :reader inspector-title-bar-ui-trace-steps)
   (current-state :initarg :current-state
                  :reader inspector-title-bar-ui-trace-current-state)
   (source-pathname :initarg :source-pathname
                    :reader inspector-title-bar-ui-trace-source-pathname)
   (notes :initarg :notes :reader inspector-title-bar-ui-trace-notes)))

(defmethod hv:text-representation ((trace inspector-title-bar-ui-trace))
  (format nil "~A -> ~A"
          (inspector-title-bar-ui-trace-name trace)
          (inspector-title-bar-ui-trace-current-state trace)))

(defun inspector-title-bar-ui-scxml-pathname ()
  (asdf:system-relative-pathname
   :hyperbook/server
   "hyperdoc/inspector-title-bar-ui.scxml"))

(defun inspector-title-bar-ui-scxml-function (name)
  (let* ((package (find-package :hyperdoc/scxml))
         (symbol (and package (find-symbol name package))))
    (and symbol (fboundp symbol) symbol)))

(defun inspector-title-bar-ui-call-scxml (name &rest arguments)
  (let ((function (inspector-title-bar-ui-scxml-function name)))
    (when function
      (apply function arguments))))

(defun inspector-title-bar-ui-chart ()
  (handler-case
      (inspector-title-bar-ui-call-scxml
       "PARSE-SCXML-FILE"
       (inspector-title-bar-ui-scxml-pathname))
    (error () nil)))

(defun inspector-title-bar-ui-chart-name (chart)
  (inspector-title-bar-ui-call-scxml "SCXML-CHART-NAME-OF" chart))

(defun inspector-title-bar-ui-chart-initial-state (chart)
  (inspector-title-bar-ui-call-scxml "SCXML-CHART-INITIAL-STATE-OF" chart))

(defun inspector-title-bar-ui-chart-states (chart)
  (inspector-title-bar-ui-call-scxml "SCXML-CHART-STATES-OF" chart))

(defun inspector-title-bar-ui-state-id (state)
  (inspector-title-bar-ui-call-scxml "SCXML-STATE-ID-OF" state))

(defun inspector-title-bar-ui-state-transitions (state)
  (inspector-title-bar-ui-call-scxml "SCXML-STATE-TRANSITIONS-OF" state))

(defun inspector-title-bar-ui-transition-event (transition)
  (inspector-title-bar-ui-call-scxml "SCXML-TRANSITION-EVENT-OF" transition))

(defun inspector-title-bar-ui-transition-target (transition)
  (inspector-title-bar-ui-call-scxml "SCXML-TRANSITION-TARGET-OF" transition))

(defun inspector-title-bar-ui-fallback-transition-target (state-id event)
  (cdr (assoc (list state-id event)
              '((("constructing" "titlebar.rendered") . "ready")
                (("ready" "class.hover") . "class-preview")
                (("ready" "class.focus") . "class-focused")
                (("ready" "class.menu") . "class-menu-open")
                (("ready" "class.invoke") . "class-invoking")
                (("class-preview" "class.pointer.leave") . "ready")
                (("class-preview" "class.focus") . "class-focused")
                (("class-focused" "class.blur") . "ready")
                (("class-focused" "class.menu") . "class-menu-open")
                (("class-focused" "class.invoke") . "class-invoking")
                (("class-menu-open" "class.menu.dismiss") . "ready")
                (("class-menu-open" "class.command.inspect") . "class-invoking")
                (("class-invoking" "class.invoked") . "ready")
                (("ready" "object.hover") . "object-preview")
                (("ready" "object.focus") . "object-focused")
                (("ready" "object.menu") . "object-menu-open")
                (("ready" "object.invoke") . "object-invoking")
                (("object-preview" "object.pointer.leave") . "ready")
                (("object-preview" "object.focus") . "object-focused")
                (("object-focused" "object.blur") . "ready")
                (("object-focused" "object.menu") . "object-menu-open")
                (("object-focused" "object.invoke") . "object-invoking")
                (("object-menu-open" "object.menu.dismiss") . "ready")
                (("object-menu-open" "object.command.inspect") . "object-invoking")
                (("object-invoking" "object.invoked") . "ready")
                (("ready" "view-contract.invoke") . "view-contract-invoking")
                (("view-contract-invoking" "view-contract.invoked") . "ready"))
              :test #'equal)))

(defun inspector-title-bar-ui-string-prefix-p (prefix string)
  (and (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun inspector-title-bar-ui-target-presentation (event target-state)
  (cond
    ((or (inspector-title-bar-ui-string-prefix-p "class." event)
         (inspector-title-bar-ui-string-prefix-p "class-" target-state))
     ".inspector-title-bar-class")
    ((or (inspector-title-bar-ui-string-prefix-p "object." event)
         (inspector-title-bar-ui-string-prefix-p "object-" target-state))
     ".inspector-title-bar-object")
    ((or (inspector-title-bar-ui-string-prefix-p "view-contract." event)
         (inspector-title-bar-ui-string-prefix-p "view-contract-" target-state))
     ".inspector-title-bar-action-buttons .hyperdoc-view-contract-action")
    (t ".inspector-title-bar")))

(defun inspector-title-bar-ui-command-for-event (event)
  (cond
    ((member event '("class.invoke" "class.command.inspect")
             :test #'string=)
     :inspect-class/type-presentation)
    ((member event '("object.invoke" "object.command.inspect")
             :test #'string=)
     :inspect-object/instance-presentation)
    ((string= event "view-contract.invoke")
     :inspect-active-view-contract-for-pane)
    ((or (string= event "class.menu")
         (string= event "object.menu"))
     :open-title-presentation-menu)
    ((or (string= event "class.hover")
         (string= event "object.hover"))
     :preview-title-presentation)
    ((or (string= event "class.focus")
         (string= event "object.focus"))
     :focus-title-presentation)
    (t :state-transition)))

(defun inspector-title-bar-ui-visible-boxes-for-state (state-id)
  (cond
    ((string= state-id "constructing") '())
    (t '(inspector-title-bar-class
         inspector-title-bar-object
         inspector-title-bar-action-buttons
         inspect-view-contract-icon))))

(defun inspector-title-bar-ui-enabled-actions-for-state (state-id)
  (cond
    ((string= state-id "constructing") '())
    ((string= state-id "class-menu-open")
     '(inspect-class inspect-class-contract inspect-applicable-views
       copy-class-name))
    ((string= state-id "object-menu-open")
     '(inspect-object inspect-slots inspect-print-representation
       copy-printed-representation))
    ((string= state-id "class-invoking")
     '(inspect-class/type-presentation))
    ((string= state-id "object-invoking")
     '(inspect-object/instance-presentation))
    ((string= state-id "view-contract-invoking")
     '(inspect-active-view-contract-for-pane))
    (t '(inspect-class/type-presentation
         inspect-object/instance-presentation
         inspect-active-view-contract-for-pane))))

(defun inspector-title-bar-ui-transition-target-for (chart state-id event)
  (or (and chart
           (loop for state in (inspector-title-bar-ui-chart-states chart)
                 when (string= state-id
                               (or (inspector-title-bar-ui-state-id state) ""))
                   return
                   (loop for transition
                           in (inspector-title-bar-ui-state-transitions state)
                         when (string= event
                                       (or (inspector-title-bar-ui-transition-event
                                            transition)
                                           ""))
                           return
                           (inspector-title-bar-ui-transition-target
                            transition))))
      (inspector-title-bar-ui-fallback-transition-target state-id event)))

(defun inspector-title-bar-ui-trace-for-events (events)
  (let* ((chart (inspector-title-bar-ui-chart))
         (initial (or (and chart
                           (inspector-title-bar-ui-chart-initial-state chart))
                      "constructing"))
         (current initial)
         (steps '())
         (notes '()))
    (dolist (event events)
      (let ((target (inspector-title-bar-ui-transition-target-for
                     chart
                     current
                     event)))
        (if target
            (progn
              (push (list :event event
                          :from current
                          :to target
                          :target-presentation
                          (inspector-title-bar-ui-target-presentation
                           event
                           target)
                          :command
                          (inspector-title-bar-ui-command-for-event event)
                          :visible-boxes
                          (inspector-title-bar-ui-visible-boxes-for-state
                           target)
                          :enabled-actions
                          (inspector-title-bar-ui-enabled-actions-for-state
                           target))
                    steps)
              (setf current target))
            (push (format nil "No SCXML transition for ~A in ~A"
                          event
                          current)
                  notes))))
    (make-instance 'inspector-title-bar-ui-trace
                   :name "inspector-title-bar-ui"
                   :events events
                   :steps (nreverse steps)
                   :current-state current
                   :source-pathname (inspector-title-bar-ui-scxml-pathname)
                   :notes (nreverse notes))))

(defun inspector-title-bar-ui-default-trace ()
  (inspector-title-bar-ui-trace-for-events '("titlebar.rendered")))

(defun inspector-title-bar-ui-view-contract-trace ()
  (inspector-title-bar-ui-trace-for-events
   '("titlebar.rendered" "view-contract.invoke" "view-contract.invoked")))

(defun inspector-title-bar-ui-class-invoke-trace ()
  (inspector-title-bar-ui-trace-for-events
   '("titlebar.rendered" "class.invoke" "class.invoked")))

(defun inspector-title-bar-ui-object-invoke-trace ()
  (inspector-title-bar-ui-trace-for-events
   '("titlebar.rendered" "object.invoke" "object.invoked")))

(defun inspector-title-bar-ui-state-contracts ()
  '((constructing
     :visible ()
     :enabled ()
     :after titlebar.rendered)
    (ready
     :visible (inspector-title-bar-class
               inspector-title-bar-object
               inspector-title-bar-action-buttons
               inspect-view-contract-icon)
     :enabled (inspect-class/type-presentation
               inspect-object/instance-presentation
               inspect-active-view-contract-for-pane)
     :presentations ((inspector-title-bar-class
                      :kind :class/type
                      :dom button
                      :event class.invoke
                      :command inspect-class/type-presentation)
                     (inspector-title-bar-object
                      :kind :object/instance
                      :dom button
                      :event object.invoke
                      :command inspect-object/instance-presentation)))
    (class-preview
     :target-presentation inspector-title-bar-class
     :command preview-title-presentation)
    (class-focused
     :target-presentation inspector-title-bar-class
     :command focus-title-presentation)
    (class-menu-open
     :target-presentation inspector-title-bar-class
     :enabled (inspect-class inspect-class-contract
               inspect-applicable-views copy-class-name))
    (class-invoking
     :target-presentation inspector-title-bar-class
     :command inspect-class/type-presentation)
    (object-preview
     :target-presentation inspector-title-bar-object
     :command preview-title-presentation)
    (object-focused
     :target-presentation inspector-title-bar-object
     :command focus-title-presentation)
    (object-menu-open
     :target-presentation inspector-title-bar-object
     :enabled (inspect-object inspect-slots inspect-print-representation
               copy-printed-representation))
    (object-invoking
     :target-presentation inspector-title-bar-object
     :command inspect-object/instance-presentation)
    (view-contract-invoking
     :action (:inspect-view-contract
              :scope :pane-active-view
              :uses (:pane-active-rendered-view :pane-inspected-subject)))))

(defun inspector-title-bar-class-label (object)
  (string-downcase (class-name (class-of object))))

(defun inspector-title-bar-view (object)
  (hv:make-html-view
   (hv:thunk
    (hv:html-and-references
     (hv:html
      (:button :id (hv:inspect-id (class-of object))
               :class "inspector-title-bar-class"
               :data-title-bar-presentation "class/type"
               :data-scxml-state "ready"
               :data-scxml-event "class.invoke"
               (:i (hv:esc (inspector-title-bar-class-label object))))
      (:button :id (hv:inspect-id object)
               :class "inspector-title-bar-object"
               :tabindex 0
               :data-title-bar-presentation "object/instance"
               :data-scxml-state "ready"
               :data-scxml-event "object.invoke"
               (hv:str (hv:title-bar-representation object))))))
   :priority 0
   :title "Title bar"))

(defun create-view-contract-title-bar-button (pane action-buttons)
  (let ((button (clog:create-button
                 action-buttons
                 :class "hyperdoc-view-contract-action inspector-button"
                 :content +view-contract-action-icon+
                 :html-id (gensym "view-contract-action"))))
    (setf (clog:attribute button "type") "button"
          (clog:attribute button "title") +view-contract-action-label+
          (clog:attribute button "aria-label") +view-contract-action-label+
          (clog:attribute button "data-hyperdoc-action")
          "inspect-view-contract"
          (clog:attribute button "data-hyperdoc-action-scope")
          "pane-active-view"
          (clog:attribute button "data-scxml-event")
          "view-contract.invoke")
    (clog:set-on-mouse-click
     button
     #'(lambda (obj event)
         (declare (ignore obj))
         (inspect-view-contract-for-pane pane event))
     :cancel-event t)
    button))

(defun inspector-title-bar-box-contract ()
  '((inspector-title-bar
     :role :pane-title-bar
     :contains (inspector-title-bar-class
                inspector-title-bar-object
                inspector-title-bar-action-buttons))
    (inspector-title-bar-class
     :role :class/type-presentation-button
     :represents :subject-type/class
     :visibility :visible-when-class/type-available
     :events (class.hover class.focus class.menu class.invoke)
     :default-command :inspect-class/type-presentation)
    (inspector-title-bar-object
     :role :object/instance-presentation-button
     :represents :inspected-object-instance
     :visibility :default-visible
     :events (object.hover object.focus object.menu object.invoke)
     :default-command :inspect-object/instance-presentation)
    (inspector-title-bar-action-buttons
     :role :pane-action-buttons
     :actions ((:inspect-view-contract
                :scope :pane-active-view
                :representation :svg-icon)))))

(defun inspector-title-bar-action-contract ()
  '((:inspect-class/type-presentation
     :event class.invoke
     :scope :title-bar-class/type-presentation
     :target :subject-type/class-object
     :presentation :inspector-title-bar-class
     :result :inspect-class/type-object)
    (:inspect-object/instance-presentation
     :event object.invoke
     :scope :title-bar-object/instance-presentation
     :target :pane-inspected-subject
     :presentation :inspector-title-bar-object
     :result :inspect-object/instance)
    (:inspect-view-contract
     :label "Inspect view contract"
     :event view-contract.invoke
     :scope :pane-active-view
     :subject :pane-inspected-subject
     :view :pane-active-rendered-view
     :representation :svg-icon
     :result :inspect-view-contract-object)))

;; Keep the upstream title-bar semantics: the class/type and object/instance
;; presentations are visible title-bar buttons. HyperDoc's view-contract
;; affordance is pane-scoped and therefore belongs in the pane title-bar action
;; buttons.
(defun create-title-bar (pane)
  (with-slots (clog-obj object inspector action-buttons) pane
    (let ((bar (clog:create-div clog-obj :class "inspector-title-bar")))
      (let* ((title-view (inspector-title-bar-view object))
             (title (clog:create-span bar :class "inspector-title")))
        (setf (clog:inner-html title) (hv:view-html title-view))
        (set-event-handlers pane title (hv:view-references title-view)))
      (clog:create-span bar :class "inspector-title-bar-separator")
      (let ((action (clog:create-span
                     bar
                     :class "inspector-title-bar-action-buttons")))
        (create-view-contract-title-bar-button pane action)
        (let ((object-actions
                (clog:create-span
                 action
                 :class "inspector-title-bar-object-actions")))
          (setf (clog:inner-html object-actions)
                (hv:view-html action-buttons))
          (set-event-handlers
           pane object-actions (hv:view-references action-buttons))))
      (create-title-bar-button bar *icon-refresh* (hv:thunk (refresh pane)))
      (create-title-bar-button bar *icon-maximize* (hv:thunk (maximize pane))
                               :classes "inspector-button inspector-maximize-button")
      (create-title-bar-button bar *icon-minimize* (hv:thunk (minimize pane))
                               :classes "inspector-button inspector-minimize-button")
      (create-title-bar-button bar *icon-close* (hv:thunk (close-pane inspector pane)))
      (clog:set-on-mouse-click bar
                               #'(lambda (obj event)
                                   (declare (ignore obj))
                                   (when (getf event :alt-key)
                                     (unless (getf event :shift-key)
                                       (close-panes-after inspector pane))
                                     (create-pane inspector pane))))
      bar)))

(hv:defview 👀summary (trace inspector-title-bar-ui-trace)
  (hv:html-view :title "Summary" :priority 1
    (hv:html
     (:h4 "Inspector title-bar UI trace")
     (:table :class "inspector-table"
             (:tr (:td "State machine")
                  (:td (hv:str (inspector-title-bar-ui-trace-name trace))))
             (:tr (:td "SCXML artifact")
                  (:td (:code
                        (hv:esc
                         (namestring
                          (inspector-title-bar-ui-trace-source-pathname
                           trace))))))
             (:tr (:td "Events")
                  (:td (:code
                        (hv:esc
                         (princ-to-string
                          (inspector-title-bar-ui-trace-events trace))))))
             (:tr (:td "Current state")
                  (:td (:code
                        (hv:esc
                         (inspector-title-bar-ui-trace-current-state
                          trace)))))))))

(hv:defview 👀trace (trace inspector-title-bar-ui-trace)
  (hv:html-view :title "Trace" :priority 2
    (hv:html
     (:h4 "Applied SCXML events")
     (:table :class "inspector-table"
             (:tr (:th "Event")
                  (:th "Source state")
                  (:th "Target state")
                  (:th "Target presentation")
                  (:th "Command")
                  (:th "Visible boxes")
                  (:th "Enabled actions"))
             (loop for step in (inspector-title-bar-ui-trace-steps trace)
                   do (hv:html
                       (:tr (:td (:code (hv:esc (getf step :event))))
                            (:td (:code (hv:esc (getf step :from))))
                            (:td (:code (hv:esc (getf step :to))))
                            (:td (:code
                                  (hv:esc
                                   (getf step :target-presentation))))
                            (:td (:code
                                  (hv:esc
                                   (princ-to-string
                                    (getf step :command)))))
                            (:td (:code
                                  (hv:esc
                                   (princ-to-string
                                    (getf step :visible-boxes)))))
                            (:td (:code
                                  (hv:esc
                                   (princ-to-string
                                    (getf step :enabled-actions)))))))))
     (when (inspector-title-bar-ui-trace-notes trace)
       (hv:html
        (:h4 "Notes")
        (:ul
         (loop for note in (inspector-title-bar-ui-trace-notes trace)
               do (hv:html (:li (hv:esc note))))))))))

(hv:defview 👀title-bar (pane pane)
  (with-slots (object action-buttons) pane
    (let* ((chart (inspector-title-bar-ui-chart))
           (default-trace (inspector-title-bar-ui-default-trace))
           (class-trace (inspector-title-bar-ui-class-invoke-trace))
           (object-trace (inspector-title-bar-ui-object-invoke-trace))
           (view-contract-trace (inspector-title-bar-ui-view-contract-trace)))
      (hv:html-view :title "Title bar" :priority 1
        (hv:html
         (:h4 "Inspector title-bar specification")
         (:table :class "inspector-table"
                 (:tr (:th "Box") (:th "Contract"))
                 (loop for (box . contract) in (inspector-title-bar-box-contract)
                       do (hv:html
                           (:tr (:td (:code (hv:esc (princ-to-string box))))
                                (:td (:code
                                      (hv:esc
                                       (princ-to-string contract))))))))
         (:h4 "SCXML state machine")
         (:table :class "inspector-table"
                 (:tr (:td "Artifact")
                      (:td (:code
                            (hv:esc
                             (namestring
                              (inspector-title-bar-ui-scxml-pathname))))))
                 (:tr (:td "Chart")
                      (:td (if chart
                               (hv:object-ref chart)
                               (hv:html
                                (:em "hyperdoc/scxml parser unavailable")))))
                 (:tr (:td "Name")
                      (:td (:code
                            (hv:esc
                             (or (and chart
                                      (inspector-title-bar-ui-chart-name chart))
                                 "inspector-title-bar")))))
                 (:tr (:td "Initial state")
                      (:td (:code
                            (hv:esc
                             (or (and chart
                                      (inspector-title-bar-ui-chart-initial-state
                                       chart))
                                 "constructing")))))
                 (:tr (:td "Default runtime trace")
                      (:td (hv:object-ref default-trace)))
                 (:tr (:td "Class/type invocation trace")
                      (:td (hv:object-ref class-trace)))
                 (:tr (:td "Object/instance invocation trace")
                      (:td (hv:object-ref object-trace)))
                 (:tr (:td "View-contract invocation trace")
                      (:td (hv:object-ref view-contract-trace))))
         (:h4 "State behavior contract")
         (:table :class "inspector-table"
                 (:tr (:th "State") (:th "Contract"))
                 (loop for (state . contract)
                         in (inspector-title-bar-ui-state-contracts)
                       do (hv:html
                           (:tr (:td (:code (hv:esc (princ-to-string state))))
                                (:td (:code
                                      (hv:esc
                                       (princ-to-string contract))))))))
         (:h4 "Action contract")
         (:table :class "inspector-table"
                 (:tr (:th "Action") (:th "Contract"))
                 (loop for (action . contract) in (inspector-title-bar-action-contract)
                       do (hv:html
                           (:tr (:td (:code (hv:esc (princ-to-string action))))
                                (:td (:code
                                      (hv:esc
                                       (princ-to-string contract))))))))
         (:h4 "Current title")
         (:table :class "inspector-table"
                 (:tr (:td "Class/type presentation")
                      (:td (:code
                            (hv:esc (inspector-title-bar-class-label object)))))
                 (:tr (:td "Class/type command")
                      (:td (:code ":inspect-class/type-presentation")))
                 (:tr (:td "Object/instance presentation")
                      (:td (hv:str (hv:title-bar-representation object))))
                 (:tr (:td "Object/instance command")
                      (:td (:code ":inspect-object/instance-presentation")))
                 (:tr (:td "Object action buttons")
                      (:td (let ((ab-html (hv:view-html action-buttons)))
                             (if (> (length ab-html) 0)
                                 (hv:html
                                  (:span :id (hv:inspect-id action-buttons)
                                         :class "inspector-inspect"
                                         (hv:str ab-html)))
                                 (hv:html (:em "None"))))))))))))

(defun dom-association-class-present-p (element class-name)
  (let ((classes (dom-association-attribute-value element "class")))
    (and (stringp classes)
         (search class-name classes :test #'char-equal))))

(defun dom-association-ancestor-matching (element predicate)
  (loop for current = element then (ignore-errors (clog:parent current))
        while current
        when (ignore-errors (funcall predicate current))
        return current))

(defun dom-association-control-container (element)
  (dom-association-ancestor-matching
   element
   (lambda (candidate)
     (dom-association-attribute-value candidate "data-source-input-id"))))

(defun dom-association-surface-element (element)
  (dom-association-ancestor-matching
   element
   (lambda (candidate)
     (dom-association-attribute-value candidate "data-context-object-id"))))

(defun dom-association-submit-wrapper (element)
  (dom-association-ancestor-matching
   element
   (lambda (candidate)
     (or (dom-association-class-present-p
          candidate "hyperdoc-dom-connect-submit")
         (dom-association-class-present-p
          candidate "hyperdoc-dom-connect-evidence-submit")))))

(defun dom-association-payload-bearing-element (element)
  (or (dom-association-ancestor-matching
       element
       (lambda (candidate)
         (or (dom-association-attribute-value
              candidate "data-dom-association-request-id")
             (dom-association-attribute-value
              candidate "data-dom-association-transport")
             (dom-association-attribute-value
              candidate "data-dom-association-context-object-id")
             (dom-association-attribute-value
              candidate "data-dom-association-context-view-title")
             (dom-association-attribute-value
              candidate "data-dom-association-source-json")
             (dom-association-attribute-value
              candidate "data-dom-connect-snapshot-json")
             (dom-association-attribute-value
              candidate "data-dom-connect-request-evidence-request-id"))))
      element))

(defun dom-association-control-field-id (element attribute-name
                                         &optional control-attribute-name)
  (or (dom-association-attribute-value element attribute-name)
      (let ((container (dom-association-control-container element)))
        (and container
             control-attribute-name
             (dom-association-attribute-value container
                                              control-attribute-name)))))

(defun dom-association-context-value (pane element attribute-name)
  (or (dom-association-attribute-value element attribute-name)
      (let ((surface (dom-association-surface-element element)))
        (and surface
             (dom-association-attribute-value surface attribute-name)))
      (and (string= attribute-name "data-dom-association-context-view-title")
           (dom-association-active-view-title pane))))

(defun dom-association-request-id-for-element (pane element)
  (let ((payload-element (dom-association-payload-bearing-element element)))
    (or (dom-association-attribute-value
         payload-element "data-dom-association-request-id")
        (dom-association-control-value
         pane
         (dom-association-control-field-id
          payload-element
          "data-dom-association-request-id-field-id"
          "data-request-id-input-id")))))

(defun inferred-dom-association-transport (element request-id)
  (or (dom-association-attribute-value
       element "data-dom-association-transport")
      (let ((wrapper (dom-association-submit-wrapper element)))
        (cond
          ((and wrapper
                (dom-association-class-present-p
                 wrapper "hyperdoc-dom-connect-evidence-submit"))
           "connect-request-evidence-v1")
          ((and wrapper
                (dom-association-class-present-p
                 wrapper "hyperdoc-dom-connect-submit"))
           "button-payload-v2")))
      (and request-id
           (uiop:string-prefix-p "connect-evidence-" request-id)
           "connect-request-evidence-v1")
      "legacy-eval-button"))

(defun dom-association-control-element (pane field-id)
  (when (and pane field-id)
    (ignore-errors
      (clog:attach-as-child (clog-obj pane) field-id))))

(defun dom-association-control-value (pane field-id)
  (let ((element (dom-association-control-element pane field-id)))
    (or (and element (ignore-errors (clog:value element)))
        (and element
             (ignore-errors
               (dom-association-attribute-value element "value"))))))

(defun dom-association-submit-payload (pane element)
  (let* ((payload-element (dom-association-payload-bearing-element element))
         (wrapper (dom-association-submit-wrapper payload-element))
         (container (dom-association-control-container payload-element))
         (source-field-id
          (dom-association-control-field-id
           payload-element
           "data-dom-association-source-field-id"
           "data-source-input-id"))
         (target-field-id
          (dom-association-control-field-id
           payload-element
           "data-dom-association-target-field-id"
           "data-target-input-id"))
         (snapshot-field-id
          (dom-association-control-field-id
           payload-element
           "data-dom-connect-snapshot-field-id"
           "data-snapshot-input-id"))
         (request-id-field-id
          (dom-association-control-field-id
           payload-element
           "data-dom-association-request-id-field-id"
           "data-request-id-input-id"))
         (browser-failure-kind-field-id
          (dom-association-control-field-id
           payload-element
           "data-dom-connect-browser-failure-kind-field-id"
           "data-browser-failure-kind-input-id"))
         (browser-message-field-id
          (dom-association-control-field-id
           payload-element
           "data-dom-connect-browser-message-field-id"
           "data-browser-message-input-id"))
         (browser-detail-field-id
          (dom-association-control-field-id
           payload-element
           "data-dom-connect-browser-detail-field-id"
           "data-browser-detail-input-id"))
         (request-id
          (or (dom-association-attribute-value
               payload-element "data-dom-association-request-id")
              (dom-association-control-value pane request-id-field-id))))
    (when (or wrapper
              container
              (dom-association-attribute-value
               payload-element "data-dom-association-request-id"))
      (list :request-id
            request-id
            :transport
            (inferred-dom-association-transport payload-element request-id)
            :context-object-id
            (dom-association-context-value
             pane payload-element "data-context-object-id")
            :context-view-title
            (or (dom-association-context-value
                 pane payload-element "data-context-view-title")
                (dom-association-context-value
                 pane payload-element "data-dom-association-context-view-title"))
            :source-field-id
            source-field-id
            :target-field-id
            target-field-id
            :snapshot-field-id
            snapshot-field-id
            :source-pane-id
            (dom-association-attribute-value
             payload-element "data-dom-association-source-pane-id")
            :target-pane-id
            (dom-association-attribute-value
             payload-element "data-dom-association-target-pane-id")
            :source-provider-kind
            (dom-association-attribute-value
             payload-element "data-dom-association-source-provider-kind")
            :target-provider-kind
            (dom-association-attribute-value
             payload-element "data-dom-association-target-provider-kind")
            :inspection-pane-id
            (or (dom-association-attribute-value
                 payload-element "data-dom-connect-inspection-pane-id")
                (dom-association-attribute-value
                 (clog-obj pane)
                 "data-hyperdoc-connect-pane-id"))
            :evidence-request-id
            (or (dom-association-attribute-value
                 payload-element "data-dom-connect-request-evidence-request-id")
                request-id)
            :browser-failure-kind
            (or (dom-association-attribute-value
                 payload-element "data-dom-connect-browser-failure-kind")
                (dom-association-control-value
                 pane browser-failure-kind-field-id))
            :browser-message
            (or (dom-association-attribute-value
                 payload-element "data-dom-connect-browser-message")
                (dom-association-control-value pane browser-message-field-id))
            :browser-detail
            (or (dom-association-attribute-value
                 payload-element "data-dom-connect-browser-detail")
                (dom-association-control-value pane browser-detail-field-id))
            :snapshot-json
            (or (dom-association-attribute-value
                 payload-element "data-dom-connect-snapshot-json")
                (dom-association-control-value pane snapshot-field-id))
            :source-json
            (or (dom-association-attribute-value
                 payload-element "data-dom-association-source-json")
                (dom-association-control-value pane source-field-id))
            :target-json
            (or (dom-association-attribute-value
                 payload-element "data-dom-association-target-json")
                (dom-association-control-value pane target-field-id))))))

(defun log-dom-association-submit-boundary (pane payload)
  (with-slots (object) pane
    (maybe-log-inspector-performance
     :dom-association/submit-boundary
     :pane-object (maybe-summarize-object-for-log object)
     :view (getf payload :context-view-title)
     :transport (getf payload :transport)
     :context-object-id (getf payload :context-object-id)
     :source-field-id (getf payload :source-field-id)
     :target-field-id (getf payload :target-field-id)
     :snapshot-field-id (getf payload :snapshot-field-id)
     :source-pane-id (getf payload :source-pane-id)
     :target-pane-id (getf payload :target-pane-id)
     :source-provider-kind (getf payload :source-provider-kind)
     :target-provider-kind (getf payload :target-provider-kind)
     :inspection-pane-id (getf payload :inspection-pane-id)
     :evidence-request-id (getf payload :evidence-request-id)
     :browser-failure-kind (getf payload :browser-failure-kind)
     :snapshot-present? (dom-association-json-present-p
                         (getf payload :snapshot-json))
     :snapshot-length (dom-association-json-length
                       (getf payload :snapshot-json))
     :source-present? (dom-association-json-present-p (getf payload :source-json))
     :source-length (dom-association-json-length (getf payload :source-json))
     :target-present? (dom-association-json-present-p (getf payload :target-json))
     :target-length (dom-association-json-length (getf payload :target-json)))))

(defun missing-dom-association-payload (pane payload field-label)
  (with-slots (object) pane
    (maybe-log-inspector-performance
     :dom-association/payload-missing
     :pane-object (maybe-summarize-object-for-log object)
     :view (getf payload :context-view-title)
     :transport (getf payload :transport)
     :missing field-label
     :source-field-id (getf payload :source-field-id)
     :target-field-id (getf payload :target-field-id)
     :snapshot-present? (dom-association-json-present-p (getf payload :snapshot-json))
     :source-present? (dom-association-json-present-p (getf payload :source-json))
     :target-present? (dom-association-json-present-p (getf payload :target-json))))
  (error "Missing ~A JSON." field-label))

(defun call-hyperdoc-dom-association-constructor (&rest arguments)
  (let* ((package (find-package :hyperdoc))
         (symbol (and package
                      (or (find-symbol "MAKE-ASSOCIATION-ANNOTATION-FROM-JSON"
                                       package)
                          (find-symbol "MAKE-DOM-RELATION-ANNOTATION-FROM-JSON"
                                       package)))))
    (unless (and symbol (fboundp symbol))
      (error "HyperDoc DOM association constructor is unavailable."))
    (apply (symbol-function symbol) arguments)))

(defun make-dom-association-from-submit-payload (pane payload)
  (with-slots (object) pane
    (call-hyperdoc-dom-association-constructor
     :context-object object
     :context-view-title (getf payload :context-view-title)
     :source-json (or (getf payload :source-json)
                      (missing-dom-association-payload pane payload "source"))
     :target-json (or (getf payload :target-json)
                      (missing-dom-association-payload pane payload "target")))))

(defun dom-connect-request-evidence-submit-payload-p (payload)
  (let ((transport (getf payload :transport)))
    (and (stringp transport)
         (string= transport "connect-request-evidence-v1"))))

(defun dom-connect-request-evidence-key (payload)
  (or (getf payload :evidence-request-id)
      (getf payload :request-id)))

(defun call-hyperdoc-dom-connect-request-evidence-runtime (symbol-name
                                                           &rest arguments)
  (let ((symbol (find-symbol symbol-name :hyperdoc)))
    (unless (and symbol (fboundp symbol))
      (error "HyperDoc Connect request evidence runtime ~A is unavailable."
             symbol-name))
    (apply (symbol-function symbol) arguments)))

(defun ensure-dom-connect-request-evidence-from-submit-payload (pane payload
                                                                request-id)
  (with-slots (object) pane
    (call-hyperdoc-dom-connect-request-evidence-runtime
     "ENSURE-DOM-CONNECT-REQUEST-EVIDENCE"
     :context-object object
     :context-view-title (getf payload :context-view-title)
     :request-id request-id
     :transport (getf payload :transport)
     :inspection-pane-id (getf payload :inspection-pane-id)
     :snapshot-json (getf payload :snapshot-json)
     :source-json (getf payload :source-json)
     :target-json (getf payload :target-json)
     :source-pane-id (getf payload :source-pane-id)
     :target-pane-id (getf payload :target-pane-id)
     :source-provider-kind (getf payload :source-provider-kind)
     :target-provider-kind (getf payload :target-provider-kind))))

(defun find-dom-connect-request-evidence (request-id)
  (call-hyperdoc-dom-connect-request-evidence-runtime
   "FIND-DOM-CONNECT-REQUEST-EVIDENCE"
   request-id))

(defun record-dom-connect-request-evidence-server-status (request-id status
                                                          &key message detail
                                                            acknowledged-p)
  (call-hyperdoc-dom-connect-request-evidence-runtime
   "RECORD-DOM-CONNECT-REQUEST-EVIDENCE-SERVER-STATUS"
   request-id status
   :message message
   :detail detail
   :acknowledged-p acknowledged-p))

(defun record-dom-connect-request-evidence-browser-failure (request-id payload)
  (call-hyperdoc-dom-connect-request-evidence-runtime
   "RECORD-DOM-CONNECT-REQUEST-EVIDENCE-BROWSER-FAILURE"
   request-id
   (getf payload :browser-failure-kind)
   :message (getf payload :browser-message)
   :detail (getf payload :browser-detail)))

(defun call-hyperdoc-connect-request-evidence-accessor (symbol-name evidence)
  (let ((symbol (find-symbol symbol-name :hyperdoc)))
    (when (and symbol (fboundp symbol))
      (ignore-errors
        (funcall (symbol-function symbol) evidence)))))

(defun call-hyperdoc-connect-snapshot-accessor (symbol-name snapshot)
  (let ((symbol (find-symbol symbol-name :hyperdoc)))
    (when (and symbol (fboundp symbol))
      (ignore-errors
        (funcall (symbol-function symbol) snapshot)))))

(defun call-hyperdoc-optional-accessor (symbol-name object)
  (let ((symbol (find-symbol symbol-name :hyperdoc)))
    (when (and symbol (fboundp symbol))
      (ignore-errors
        (funcall (symbol-function symbol) object)))))

(defun dom-association-present-string (value)
  (and (stringp value)
       (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) value)))
         (and (> (length trimmed) 0)
              (not (member trimmed '("undefined" "null") :test #'string=))
              trimmed))))

(defun hyperdoc-object-id (object)
  (call-hyperdoc-optional-accessor "ID-OF" object))

(defun stable-hyperdoc-object-id (object)
  (dom-association-present-string (hyperdoc-object-id object)))

(defun dock-annotation-object-p (object)
  (let ((dock-capability
         (call-hyperdoc-optional-accessor "DOCK-CAPABILITY-OF" object))
        (relation-kind
         (call-hyperdoc-optional-accessor "RELATION-KIND-OF" object)))
    (and (stringp dock-capability)
         (string= dock-capability "Annotation")
         (stringp relation-kind)
         (string= relation-kind "annotation"))))

(defun dom-connect-snapshot-object-p (object)
  (not (null
        (call-hyperdoc-connect-snapshot-accessor
         "CAPTURED-AT-LABEL-OF" object))))

(defun dom-connect-request-evidence-object-request-id (object)
  (call-hyperdoc-connect-request-evidence-accessor
   "REQUEST-ID-OF" object))

(defun set-connect-snapshot-pane-attribute (pane attribute-name value)
  (setf (clog:attribute (clog-obj pane) attribute-name)
        (or value "")))

(defun dom-connect-snapshot-pane-reuse-key (payload snapshot)
  (or (dom-association-present-string
       (getf payload :inspection-pane-id))
      (dom-association-present-string
       (call-hyperdoc-connect-snapshot-accessor "ORIGIN-PANE-ID-OF" snapshot))
      (dom-association-present-string
       (call-hyperdoc-connect-snapshot-accessor "SOURCE-PANE-ID-OF" snapshot))
      (dom-association-present-string
       (getf payload :source-pane-id))))

(defun mark-dom-connect-snapshot-pane (pane payload snapshot)
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-inspection" "true")
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-inspection-pane-id"
   (getf payload :inspection-pane-id))
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-reuse-key"
   (dom-connect-snapshot-pane-reuse-key payload snapshot))
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-session-id"
   (call-hyperdoc-connect-snapshot-accessor "SESSION-ID-OF" snapshot))
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-phase"
   (call-hyperdoc-connect-snapshot-accessor "PHASE-OF" snapshot))
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-origin-pane-id"
   (call-hyperdoc-connect-snapshot-accessor "ORIGIN-PANE-ID-OF" snapshot))
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-captured-at"
   (let ((captured-at
          (call-hyperdoc-connect-snapshot-accessor "CAPTURED-AT-OF" snapshot)))
     (and captured-at (format nil "~A" captured-at)))))

(defun mark-dom-connect-request-evidence-pane (pane request-id evidence)
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-request-evidence" "true")
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-request-id"
   request-id)
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-evidence-updated-at"
   (call-hyperdoc-connect-request-evidence-accessor
    "UPDATED-AT-LABEL-OF" evidence)))

(defun dom-connect-snapshot-pane-match-p (pane reuse-key)
  (let ((marked (dom-association-attribute-value
                 (clog-obj pane)
                 "data-hyperdoc-connect-inspection"))
        (pane-reuse-key (dom-association-attribute-value
                         (clog-obj pane)
                         "data-hyperdoc-connect-reuse-key")))
    (and (stringp reuse-key)
         (stringp marked)
         (stringp pane-reuse-key)
         (string= marked "true")
         (string= pane-reuse-key reuse-key))))

(defun find-reusable-dom-connect-snapshot-pane (inspector payload snapshot)
  (let ((reuse-key (dom-connect-snapshot-pane-reuse-key payload snapshot)))
    (when reuse-key
      (loop for candidate in (fset:convert 'list (inspector-panes inspector))
            when (dom-connect-snapshot-pane-match-p candidate reuse-key)
            return candidate))))

(defun dom-connect-request-evidence-pane-match-p (pane request-id)
  (let ((marked (dom-association-attribute-value
                 (clog-obj pane)
                 "data-hyperdoc-connect-request-evidence"))
        (pane-request-id (dom-association-attribute-value
                          (clog-obj pane)
                          "data-hyperdoc-connect-request-id")))
    (and (stringp request-id)
         (stringp marked)
         (stringp pane-request-id)
         (string= marked "true")
         (string= pane-request-id request-id))))

(defun find-reusable-dom-connect-request-evidence-pane (inspector request-id)
  (loop for candidate in (fset:convert 'list (inspector-panes inspector))
        when (dom-connect-request-evidence-pane-match-p candidate request-id)
        return candidate))

(defun open-dom-connect-snapshot-pane (inspector payload snapshot)
  (let ((existing-pane
         (find-reusable-dom-connect-snapshot-pane inspector payload snapshot)))
    (if existing-pane
        (progn
          (setf (pane-object existing-pane) snapshot)
          (refresh existing-pane)
          (mark-dom-connect-snapshot-pane existing-pane payload snapshot)
          (select-view existing-pane "Summary")
          (clog:focus (clog-obj existing-pane))
          existing-pane)
        (let ((pane (create-pane inspector snapshot)))
          (mark-dom-connect-snapshot-pane pane payload snapshot)
          pane))))

(defun open-dom-connect-request-evidence-pane (inspector request-id evidence)
  (let ((existing-pane
         (find-reusable-dom-connect-request-evidence-pane inspector request-id)))
    (if existing-pane
        (progn
          (setf (pane-object existing-pane) evidence)
          (refresh existing-pane)
          (mark-dom-connect-request-evidence-pane
           existing-pane request-id evidence)
          (select-view existing-pane "Summary")
          (clog:focus (clog-obj existing-pane))
          existing-pane)
        (let ((pane (create-pane inspector evidence)))
          (mark-dom-connect-request-evidence-pane pane request-id evidence)
          pane))))

(defun find-reusable-hyperdoc-object-pane (inspector object)
  (let ((object-id (stable-hyperdoc-object-id object)))
    (when object-id
      (loop for candidate in (fset:convert 'list (inspector-panes inspector))
            for pane-object = (pane-object candidate)
            when (string= (or (stable-hyperdoc-object-id pane-object) "")
                          object-id)
            return candidate))))

(defun open-hyperdoc-object-pane (inspector object &key (select nil))
  (let ((existing-pane (find-reusable-hyperdoc-object-pane inspector object)))
    (if existing-pane
        (progn
          (setf (pane-object existing-pane) object)
          (refresh existing-pane)
          (select-view existing-pane
                       (default-pane-selection existing-pane select))
          (clog:focus (clog-obj existing-pane))
          existing-pane)
        (create-pane inspector object :select select))))

(defun find-reusable-dock-annotation-pane (inspector annotation)
  (let ((annotation-id (stable-hyperdoc-object-id annotation)))
    (when (and (dock-annotation-object-p annotation)
               (stringp annotation-id))
      (loop for candidate in (fset:convert 'list (inspector-panes inspector))
            for pane-object = (pane-object candidate)
            when (and (dock-annotation-object-p pane-object)
                      (string= (or (stable-hyperdoc-object-id pane-object) "")
                               annotation-id))
            return candidate))))

(defun open-dock-annotation-pane (inspector annotation)
  (let ((existing-pane (find-reusable-dock-annotation-pane inspector annotation)))
    (if existing-pane
        (progn
          (setf (pane-object existing-pane) annotation)
          (refresh existing-pane)
          (select-view existing-pane "Overview")
          (clog:focus (clog-obj existing-pane))
          existing-pane)
        (create-pane inspector annotation))))

(defun dom-association-success-message (payload)
  (cond
    ((dom-connect-request-evidence-submit-payload-p payload)
     "Connect request evidence opened.")
    (t
     "Association pane opened.")))

(defun notify-dom-association-browser (element request-id status
                                       &key message detail)
  (when request-id
    (ignore-errors
      (clog:js-execute
       element
       (format nil
               "(function(){ if (window.hyperdocDomConnect && window.hyperdocDomConnect.notifyServerResult) { window.hyperdocDomConnect.notifyServerResult({requestId: ~A, status: ~A, message: ~A, detail: ~A}); } })();"
               (encode-json-string-for-browser request-id)
               (encode-json-string-for-browser
                (string-downcase (string status)))
               (if message
                   (encode-json-string-for-browser message)
                   "null")
               (if detail
                   (encode-json-string-for-browser detail)
                   "null"))))))

;; Extend the pane tab row with a dedicated slot for the pane-level Connect
;; control. The DOM overlay and anchor machinery remain in the rendered view.
(defun create-tabs (pane)
  (with-slots (clog-obj inspector views tab-ids) pane
    (let* ((view-titles (mapcar #'hv:view-title views))
           (chrome (clog:create-div clog-obj
                                    :class "hyperdoc-dom-connect-pane-chrome"))
           (tabs (clog:create-div chrome :class "inspector-tabs")))
      (loop for tab-text in view-titles
            for tab-id in tab-ids
            for view in views
            for index from 0
            do (let* ((tab (clog:create-button tabs
                                               :content tab-text
                                               :html-id tab-id))
                      (view* view)
                      (index* index))
                 (clog:set-on-mouse-click
                  tab
                  #'(lambda (obj event)
                      (declare (ignore obj))
                      (if (getf event :alt-key)
                          (progn
                            (unless (getf event :shift-key)
                              (close-panes-after inspector pane))
                            (create-pane inspector view* :select "Source code"))
                          (select-view pane index*))))))
      (clog:create-div chrome
                       :class "hyperdoc-dom-connect-pane-slot"
                       :content ""
                       :html-id (gensym "dom-connect-slot"))
      chrome)))

;; Override only the Eval path. The generic reference wiring stays in
;; inspector-wiring; this file owns the DOM-association-specific create/open
;; flow, browser notification, and request-id correlation.
(defun handle-inspector-eval-click (pane obj target event)
  (with-slots (object inspector clog-obj) pane
    (let* ((submit-payload (dom-association-submit-payload pane obj))
           (request-id (and submit-payload
                            (or (getf submit-payload :request-id)
                                (dom-association-request-id-for-element
                                 pane obj))))
           (association-request-p
            (and submit-payload
                 request-id
                 (not (dom-connect-request-evidence-submit-payload-p
                       submit-payload))))
           (*inspector-operation-id* request-id)
           (click-start (maybe-current-time-millis)))
      (when submit-payload
        (log-dom-association-submit-boundary pane submit-payload))
      (when association-request-p
        (ensure-dom-connect-request-evidence-from-submit-payload
         pane submit-payload request-id))
      (maybe-log-inspector-performance
       :dom-association/server-received
       :pane-object (maybe-summarize-object-for-log object)
       :target (maybe-summarize-object-for-log target)
       :transport (and submit-payload (getf submit-payload :transport))
       :source-pane-id (and submit-payload (getf submit-payload :source-pane-id))
       :target-pane-id (and submit-payload (getf submit-payload :target-pane-id))
       :source-provider-kind (and submit-payload
                                  (getf submit-payload :source-provider-kind))
       :target-provider-kind (and submit-payload
                                  (getf submit-payload :target-provider-kind))
       :source-present? (and submit-payload
                             (dom-association-json-present-p
                              (getf submit-payload :source-json)))
       :source-length (and submit-payload
                           (dom-association-json-length
                            (getf submit-payload :source-json)))
       :target-present? (and submit-payload
                             (dom-association-json-present-p
                              (getf submit-payload :target-json)))
       :target-length (and submit-payload
                           (dom-association-json-length
                            (getf submit-payload :target-json)))
       :alt? (getf event :alt-key)
       :shift? (getf event :shift-key))
      (when association-request-p
        (record-dom-connect-request-evidence-server-status
         request-id "server-received"))
      (handler-case
          (progn
            (unless (getf event :shift-key)
              (close-panes-after inspector pane))
            (cond
              ((getf event :alt-key)
               (maybe-log-inspector-performance
                :dom-association/pane-open-requested
                :mode :alt-target)
               (create-pane inspector target)
               (maybe-log-inspector-performance
                :dom-association/pane-open-succeeded
                :mode :alt-target
                :ms (maybe-elapsed-millis click-start))
               (notify-dom-association-browser
                obj request-id "pane-open-succeeded"
                :message (dom-association-success-message submit-payload)))
              ((dom-connect-request-evidence-submit-payload-p submit-payload)
               (let* ((evidence-request-id
                       (getf submit-payload :evidence-request-id))
                      (evidence (or (find-dom-connect-request-evidence
                                     evidence-request-id)
                                    (ensure-dom-connect-request-evidence-from-submit-payload
                                     pane submit-payload evidence-request-id))))
                 (when evidence-request-id
                   (record-dom-connect-request-evidence-browser-failure
                    evidence-request-id submit-payload))
                 (maybe-log-inspector-performance
                  :dom-association/object-created
                  :object (maybe-summarize-object-for-log evidence))
                 (maybe-log-inspector-performance
                  :dom-association/pane-open-requested
                  :mode :connect-request-evidence)
                 (open-dom-connect-request-evidence-pane
                  inspector evidence-request-id evidence)
                 (maybe-log-inspector-performance
                  :dom-association/pane-open-succeeded
                  :mode :connect-request-evidence
                  :object (maybe-summarize-object-for-log evidence)
                  :ms (maybe-elapsed-millis click-start))
                 (notify-dom-association-browser
                  obj request-id "pane-open-succeeded"
                  :message (dom-association-success-message
                            submit-payload))))
              (request-id
               (let ((association
                      (make-dom-association-from-submit-payload
                       pane submit-payload)))
                 (maybe-log-inspector-performance
                  :dom-association/object-created
                  :object (maybe-summarize-object-for-log association))
                 (when association-request-p
                   (record-dom-connect-request-evidence-server-status
                    request-id "object-created"))
                 (maybe-log-inspector-performance
                  :dom-association/pane-open-requested
                  :mode :evaluated-object)
                 (cond
                   ((dom-connect-snapshot-object-p association)
                    (open-dom-connect-snapshot-pane
                     inspector submit-payload association))
                   ((dom-connect-request-evidence-object-request-id
                     association)
                    (open-dom-connect-request-evidence-pane
                     inspector
                     (dom-connect-request-evidence-object-request-id association)
                     association))
                   ((dock-annotation-object-p association)
                    (open-dock-annotation-pane inspector association))
                   (t
                    (open-hyperdoc-object-pane inspector association)))
                 (maybe-log-inspector-performance
                  :dom-association/pane-open-succeeded
                  :mode :evaluated-object
                  :object (maybe-summarize-object-for-log association)
                  :ms (maybe-elapsed-millis click-start))
                 (when association-request-p
                   (record-dom-connect-request-evidence-server-status
                    request-id "pane-open-succeeded"
                    :message (dom-association-success-message submit-payload)
                    :acknowledged-p t))
                 (notify-dom-association-browser
                  obj request-id "pane-open-succeeded"
                  :message (dom-association-success-message
                            submit-payload))))
              (t
               (maybe-log-inspector-performance
                :dom-association/pane-open-requested
                :mode :pending-evaluated-object)
               (let ((pending-pane
                      (start-pending-evaluation pane obj target)))
                 (maybe-log-inspector-performance
                  :dom-association/pane-open-succeeded
                  :mode :pending-evaluated-object
                  :object (maybe-summarize-object-for-log
                           (pane-object pending-pane))
                  :ms (maybe-elapsed-millis click-start))))))
        (error (c)
          (let ((detail (princ-to-string c)))
            (maybe-log-inspector-performance
             :dom-association/failed
             :error detail
             :ms (maybe-elapsed-millis click-start))
            (when association-request-p
              (record-dom-connect-request-evidence-server-status
               request-id "failed"
               :message "Association could not be opened."
               :detail detail
               :acknowledged-p t))
            (notify-dom-association-browser
             obj request-id "failed"
             :message "Association could not be opened."
             :detail detail)))))))
