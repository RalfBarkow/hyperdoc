(in-package :clog-moldable-inspector)

(defun valid-reference-id-p (id)
  (and (stringp id)
       (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) id)))
         (and (> (length trimmed) 0)
              (not (string= trimmed "#"))))))

(defun maybe-summarize-object-for-log (object)
  (if (fboundp 'summarize-object-for-log)
      (summarize-object-for-log object)
      (format nil "~A" object)))

(defun maybe-current-time-millis ()
  (if (fboundp 'current-time-millis)
      (current-time-millis)
      0))

(defun maybe-elapsed-millis (start)
  (if (fboundp 'elapsed-millis)
      (elapsed-millis start)
      0))

(defun maybe-log-inspector-performance (phase &rest kvs)
  (when (fboundp 'log-inspector-performance)
    (apply #'log-inspector-performance phase kvs)))

(defun handle-inspector-inspect-click (pane element target view-ref event)
  (with-slots (object inspector) pane
    (let ((click-start (maybe-current-time-millis)))
      (maybe-log-inspector-performance
       :click/inspect
       :pane-object (maybe-summarize-object-for-log object)
       :target (maybe-summarize-object-for-log target)
       :select view-ref
       :alt? (getf event :alt-key)
       :shift? (getf event :shift-key))
      (when (getf event :alt-key)
        (clog:jquery-trigger (clog:parent element) "click"))
      (unless (getf event :alt-key)
        (unless (getf event :shift-key)
          (close-panes-after inspector pane))
        (create-pane inspector target :select view-ref))
      (maybe-log-inspector-performance
       :click/inspect-done
       :target (maybe-summarize-object-for-log target)
       :ms (maybe-elapsed-millis click-start)))))

(defun handle-inspector-action-click (pane obj target event)
  (with-slots (inspector clog-obj) pane
    (if (getf event :alt-key)
        (progn
          (unless (getf event :shift-key)
            (close-panes-after inspector pane))
          (create-pane inspector target))
        (when (eval-thunk-with-active-button clog-obj obj target)
          (refresh pane)))))

(defun handle-inspector-eval-click (pane obj target event)
  (with-slots (inspector clog-obj) pane
    (unless (getf event :shift-key)
      (close-panes-after inspector pane))
    (if (getf event :alt-key)
        (create-pane inspector target)
        (create-pane inspector
                     (eval-thunk-with-active-button clog-obj obj target)))))

;; Override upstream wiring to ignore invalid reference ids that would
;; otherwise trigger jQuery selector errors for "#".
;; Load order matters: this file is loaded after CLOG-MOLDABLE-INSPECTOR
;; so this definition intentionally replaces the upstream one.
(defun set-event-handlers (pane element references)
  (with-slots (object) pane
    (dolist (ref references)
      (let* ((target (cdr ref))
             (html-id (car ref)))
        (if (not (valid-reference-id-p html-id))
            (progn
              (format *error-output*
                      "~&[INSPECTOR] dropped empty ref id for ~S~%"
                      object)
              (finish-output *error-output*))
            (let* ((html-id-parts (str:split "-" html-id))
                   (ref-type (first html-id-parts))
                   (ref-element (clog:attach-as-child element html-id)))
              (cond
                ((string= ref-type "inspect")
                 (let ((view-ref nil))
                   (when (eql (length html-id-parts) 3)
                     (setf view-ref (hv:decode-base32 (third html-id-parts))))
                   (clog:set-on-mouse-click
                    ref-element
                    #'(lambda (obj event)
                        (handle-inspector-inspect-click pane obj target view-ref event))
                    :cancel-event t)))
                ((string= ref-type "action")
                 (clog:set-on-mouse-click
                  ref-element
                  #'(lambda (obj event)
                      (handle-inspector-action-click pane obj target event))
                  :cancel-event t))
                ((string= ref-type "eval")
                 (clog:set-on-mouse-click
                  ref-element
                  #'(lambda (obj event)
                      (handle-inspector-eval-click pane obj target event))
                  :cancel-event t)
                 (setf (clog:attribute ref-element
                                       "data-hyperdoc-eval-bound")
                       "true")))))))))
