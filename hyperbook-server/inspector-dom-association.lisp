;;;; Inspector integration for DOM association flow
;;
;;;; Copyright (c) 2026

(in-package :clog-moldable-inspector)

(defun dom-association-request-id-for-element (element)
  (dom-association-attribute-value element "data-dom-association-request-id"))

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

(defun dom-association-submit-payload (pane element)
  (list :transport
        (or (dom-association-attribute-value
             element "data-dom-association-transport")
            "legacy-eval-button")
        :context-object-id
        (dom-association-attribute-value
         element "data-dom-association-context-object-id")
        :context-view-title
        (or (dom-association-attribute-value
             element "data-dom-association-context-view-title")
            (dom-association-active-view-title pane))
        :source-field-id
        (dom-association-attribute-value
         element "data-dom-association-source-field-id")
        :target-field-id
        (dom-association-attribute-value
         element "data-dom-association-target-field-id")
        :source-pane-id
        (dom-association-attribute-value
         element "data-dom-association-source-pane-id")
        :target-pane-id
        (dom-association-attribute-value
         element "data-dom-association-target-pane-id")
        :source-provider-kind
        (dom-association-attribute-value
         element "data-dom-association-source-provider-kind")
        :target-provider-kind
        (dom-association-attribute-value
         element "data-dom-association-target-provider-kind")
        :inspection-pane-id
        (dom-association-attribute-value
         element "data-dom-connect-inspection-pane-id")
        :snapshot-json
        (dom-association-attribute-value
         element "data-dom-connect-snapshot-json")
        :source-json
        (dom-association-attribute-value
         element "data-dom-association-source-json")
        :target-json
        (dom-association-attribute-value
         element "data-dom-association-target-json")))

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
     :source-pane-id (getf payload :source-pane-id)
     :target-pane-id (getf payload :target-pane-id)
     :source-provider-kind (getf payload :source-provider-kind)
     :target-provider-kind (getf payload :target-provider-kind)
     :inspection-pane-id (getf payload :inspection-pane-id)
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

(defun call-hyperdoc-dom-connect-snapshot-constructor (&rest arguments)
  (let* ((package (find-package :hyperdoc))
         (symbol (and package
                      (find-symbol "MAKE-DOM-CONNECT-SESSION-SNAPSHOT-FROM-JSON"
                                   package))))
    (unless (and symbol (fboundp symbol))
      (error "HyperDoc Connect snapshot constructor is unavailable."))
    (apply (symbol-function symbol) arguments)))

(defun make-dom-connect-snapshot-from-submit-payload (pane payload)
  (with-slots (object) pane
    (call-hyperdoc-dom-connect-snapshot-constructor
     :context-object object
     :context-view-title (getf payload :context-view-title)
     :snapshot-json
     (or (getf payload :snapshot-json)
         (missing-dom-association-payload pane payload "Connect snapshot")))))

(defun dom-connect-snapshot-submit-payload-p (payload)
  (let ((transport (getf payload :transport)))
    (and (stringp transport)
         (string= transport "connect-snapshot-v1"))))

(defun call-hyperdoc-connect-snapshot-accessor (symbol-name snapshot)
  (let ((symbol (find-symbol symbol-name :hyperdoc)))
    (when (and symbol (fboundp symbol))
      (ignore-errors
        (funcall (symbol-function symbol) snapshot)))))

(defun set-connect-snapshot-pane-attribute (pane attribute-name value)
  (setf (clog:attribute (clog-obj pane) attribute-name)
        (or value "")))

(defun mark-dom-connect-snapshot-pane (pane payload snapshot)
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-inspection" "true")
  (set-connect-snapshot-pane-attribute
   pane "data-hyperdoc-connect-inspection-pane-id"
   (getf payload :inspection-pane-id))
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

(defun dom-connect-snapshot-pane-match-p (pane inspection-pane-id)
  (let ((marked (dom-association-attribute-value
                 (clog-obj pane)
                 "data-hyperdoc-connect-inspection"))
        (pane-id (dom-association-attribute-value
                  (clog-obj pane)
                  "data-hyperdoc-connect-inspection-pane-id")))
    (and (stringp inspection-pane-id)
         (stringp marked)
         (stringp pane-id)
         (string= marked "true")
         (string= pane-id inspection-pane-id))))

(defun find-reusable-dom-connect-snapshot-pane (inspector payload)
  (let ((inspection-pane-id (getf payload :inspection-pane-id)))
    (when inspection-pane-id
      (loop for candidate in (fset:convert 'list (inspector-panes inspector))
            when (dom-connect-snapshot-pane-match-p candidate inspection-pane-id)
              return candidate))))

(defun open-dom-connect-snapshot-pane (inspector payload snapshot)
  (let ((existing-pane (find-reusable-dom-connect-snapshot-pane inspector payload)))
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

(defun dom-association-success-message (payload)
  (if (dom-connect-snapshot-submit-payload-p payload)
      "Connect state opened."
      "Association pane opened."))

(defun notify-dom-association-browser (element request-id status
                                       &key message detail)
  (when request-id
    (ignore-errors
      (clog:js-execute
       element
       (format nil
               "(function(){ if (window.hyperdocDomConnect && window.hyperdocDomConnect.notifyServerResult) { window.hyperdocDomConnect.notifyServerResult({requestId: ~S, status: ~S, message: ~A, detail: ~A}); } })();"
               request-id
               status
               (if message
                   (format nil "~S" message)
                   "null")
               (if detail
                   (format nil "~S" detail)
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
    (let* ((request-id (dom-association-request-id-for-element obj))
           (submit-payload (and request-id
                                (dom-association-submit-payload pane obj)))
           (*inspector-operation-id* request-id)
           (click-start (maybe-current-time-millis)))
      (when submit-payload
        (log-dom-association-submit-boundary pane submit-payload))
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
      (handler-case
          (progn
            (unless (getf event :shift-key)
              (close-panes-after inspector pane))
            (if (getf event :alt-key)
                (progn
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
                (let ((association
                        (cond
                          ((and request-id
                                (dom-connect-snapshot-submit-payload-p
                                 submit-payload))
                           (make-dom-connect-snapshot-from-submit-payload
                            pane submit-payload))
                          (request-id
                           (make-dom-association-from-submit-payload
                            pane submit-payload))
                          (t
                           (eval-thunk-with-active-button
                            clog-obj obj target)))))
                  (maybe-log-inspector-performance
                   :dom-association/object-created
                   :object (maybe-summarize-object-for-log association))
                  (maybe-log-inspector-performance
                   :dom-association/pane-open-requested
                   :mode :evaluated-object)
                  (if (dom-connect-snapshot-submit-payload-p submit-payload)
                      (open-dom-connect-snapshot-pane
                       inspector submit-payload association)
                      (create-pane inspector association))
                  (maybe-log-inspector-performance
                   :dom-association/pane-open-succeeded
                   :mode :evaluated-object
                   :object (maybe-summarize-object-for-log association)
                   :ms (maybe-elapsed-millis click-start))
                  (notify-dom-association-browser
                   obj request-id "pane-open-succeeded"
                   :message (dom-association-success-message
                             submit-payload)))))
        (error (c)
          (let ((detail (princ-to-string c)))
            (maybe-log-inspector-performance
             :dom-association/failed
             :error detail
             :ms (maybe-elapsed-millis click-start))
            (notify-dom-association-browser
             obj request-id "failed"
             :message "Association could not be opened."
             :detail detail)))))))
