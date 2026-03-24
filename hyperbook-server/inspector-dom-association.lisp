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
          candidate "hyperdoc-dom-connect-inspect-submit")
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
                 wrapper "hyperdoc-dom-connect-inspect-submit"))
           "connect-snapshot-v1")
          ((and wrapper
                (dom-association-class-present-p
                 wrapper "hyperdoc-dom-connect-evidence-submit"))
           "connect-request-evidence-v1")
          ((and wrapper
                (dom-association-class-present-p
                 wrapper "hyperdoc-dom-connect-submit"))
           "button-payload-v2")))
      (and request-id
           (uiop:string-prefix-p "connect-inspect-" request-id)
           "connect-snapshot-v1")
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

(defun dom-association-success-message (payload)
  (cond
    ((dom-connect-request-evidence-submit-payload-p payload)
     "Connect request evidence opened.")
    ((dom-connect-snapshot-submit-payload-p payload)
     "Connect state opened.")
    (t
     "Association pane opened.")))

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
    (let* ((submit-payload (dom-association-submit-payload pane obj))
           (request-id (and submit-payload
                            (or (getf submit-payload :request-id)
                                (dom-association-request-id-for-element
                                 pane obj))))
           (association-request-p
             (and submit-payload
                  request-id
                  (not (dom-connect-snapshot-submit-payload-p submit-payload))
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
                (cond
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
                  (t
                   (let ((association
                           (cond
                             ((dom-connect-snapshot-submit-payload-p
                               submit-payload)
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
                         (dom-connect-request-evidence-object-request-id
                          association)
                         association))
                       (t
                        (create-pane inspector association)))
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
                                submit-payload)))))))
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
