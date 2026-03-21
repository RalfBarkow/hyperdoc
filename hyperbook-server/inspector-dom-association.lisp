;;;; Inspector integration for DOM association flow
;;
;;;; Copyright (c) 2026

(in-package :clog-moldable-inspector)

(defun dom-association-request-id-for-element (element)
  (let ((value (ignore-errors
                 (clog:attribute element "data-dom-association-request-id"))))
    (and (stringp value)
         (> (length (string-trim '(#\Space #\Tab #\Newline #\Return) value)) 0)
         value)))

(defun notify-dom-association-browser (element request-id status
                                       &key message detail)
  (when request-id
    (ignore-errors
      (clog:js-execute
       element
       (format nil
               "(function(){ if (window.hyperdocDomConnect && window.hyperdocDomConnect.notifyServerResult) { window.hyperdocDomConnect.notifyServerResult({requestId: ~S, status: ~S, message: ~S, detail: ~S}); } })();"
               request-id
               status
               message
               detail)))))

;; Extend the pane tab row with a dedicated slot for the pane-level Connect
;; control. The DOM overlay and anchor machinery remain in the rendered view.
(defun create-tabs (pane)
  (with-slots (clog-obj inspector views tab-ids) pane
    (let ((view-titles (mapcar #'hv:view-title views))
          (tabs (clog:create-div clog-obj :class "inspector-tabs")))
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
      (clog:create-div tabs
                       :class "hyperdoc-dom-connect-pane-slot"
                       :content ""
                       :html-id (gensym "dom-connect-slot"))
      tabs)))

;; Override only the Eval path. The generic reference wiring stays in
;; inspector-wiring; this file owns the DOM-association-specific create/open
;; flow, browser notification, and request-id correlation.
(defun handle-inspector-eval-click (pane obj target event)
  (with-slots (object inspector clog-obj) pane
    (let* ((request-id (dom-association-request-id-for-element obj))
           (*inspector-operation-id* request-id)
           (click-start (maybe-current-time-millis)))
      (maybe-log-inspector-performance
       :dom-association/server-received
       :pane-object (maybe-summarize-object-for-log object)
       :target (maybe-summarize-object-for-log target)
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
                   :message "Association pane opened."))
                (let ((association
                        (eval-thunk-with-active-button
                         clog-obj obj target)))
                  (maybe-log-inspector-performance
                   :dom-association/object-created
                   :object (maybe-summarize-object-for-log association))
                  (maybe-log-inspector-performance
                   :dom-association/pane-open-requested
                   :mode :evaluated-object)
                  (create-pane inspector association)
                  (maybe-log-inspector-performance
                   :dom-association/pane-open-succeeded
                   :mode :evaluated-object
                   :object (maybe-summarize-object-for-log association)
                   :ms (maybe-elapsed-millis click-start))
                  (notify-dom-association-browser
                   obj request-id "pane-open-succeeded"
                   :message "Association pane opened."))))
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
