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

(defun maybe-hyperdoc-json-encoder ()
  (let* ((package (find-package "HYPERDOC"))
         (symbol (and package (find-symbol "ENCODE-JSON-STRING" package))))
    (and symbol
         (fboundp symbol)
         (symbol-function symbol))))

(defun encode-json-string-for-browser (value)
  (or (when-let (encoder (maybe-hyperdoc-json-encoder))
        (funcall encoder value))
      (with-output-to-string (stream)
        (write-char #\" stream)
        (loop for char across (or value "")
              do (case char
                   (#\" (write-string "\\\"" stream))
                   (#\\ (write-string "\\\\" stream))
                   (#\Backspace (write-string "\\b" stream))
                   (#\Page (write-string "\\f" stream))
                   (#\Newline (write-string "\\n" stream))
                   (#\Return (write-string "\\r" stream))
                   (#\Tab (write-string "\\t" stream))
                   (otherwise
                    (let ((code (char-code char)))
                      (if (< code 32)
                          (format stream "\\u~4,'0X" code)
                          (write-char char stream))))))
        (write-char #\" stream))))

(defun maybe-log-inspector-performance (phase &rest kvs)
  (when (fboundp 'log-inspector-performance)
    (apply #'log-inspector-performance phase kvs)))

(defun maybe-attribute-value (element attribute-name)
  (let ((value (ignore-errors
                 (clog:attribute element attribute-name))))
    (and (stringp value)
         (> (length value) 0)
         value)))

(defun package-class-typep (object package-name class-name)
  (let ((package (find-package package-name)))
    (when package
      (multiple-value-bind (symbol status)
          (find-symbol class-name package)
        (and status
             (ignore-errors
               (typep object symbol)))))))

(defun authored-expression-reference-p (object)
  (package-class-typep object "HYPERDOC" "AUTHORED-EXPRESSION-REFERENCE"))

(defun authored-expression-issue-p (object)
  (package-class-typep object "HYPERDOC" "AUTHORED-EXPRESSION-EVALUATION-ISSUE"))

(defun git-runtime-unavailable-p (object)
  (package-class-typep object "HYPERDOC" "GIT-RUNTIME-UNAVAILABLE"))

(defun hover-label-for-element (element)
  (maybe-attribute-value element "title"))

(defun example-run-click-p (element)
  (let ((title (hover-label-for-element element)))
    (and title
         (search "Run example" title :test #'char-equal))))

(defun snippet-playground-click-p (element)
  (let ((title (hover-label-for-element element)))
    (and title
         (search "snippet playground" title :test #'char-equal))))

(defun pending-evaluation-click-p (element target)
  (or (example-run-click-p element)
      (snippet-playground-click-p element)
      (authored-expression-reference-p target)))

(defun pending-evaluation-title (element target)
  (declare (ignore target))
  (cond
    ((example-run-click-p element)
     "Running example...")
    ((snippet-playground-click-p element)
     "Building snippet playground...")
    (t
     "Evaluating...")))

(defun pending-evaluation-phase-label (phase)
  (case phase
    (:running-example "Running example...")
    (:evaluating "Evaluating...")
    (:collecting-input "Collecting input...")
    (:recognizing "Recognizing snippets...")
    (:pairing "Pairing snippets...")
    (:building-session "Building session...")
    (:waiting-for-git "Waiting for Git...")
    (:opening-result "Opening result...")
    (:failed "Failed")
    (t "Pending...")))

(defun pending-evaluation-phase-for-click (element target)
  (cond
    ((example-run-click-p element)
     :running-example)
    ((snippet-playground-click-p element)
     :collecting-input)
    ((authored-expression-reference-p target)
     :evaluating)
    (t
     :evaluating)))

(defparameter +minimum-pending-pane-visibility-ms+ 250)

(defvar *pending-evaluation-progress-hook* nil)
(defvar *pending-evaluation-origin-pane-id* nil)
(defvar *pending-evaluation-pane-id* nil)

(defun report-pending-evaluation-progress (phase message &key detail)
  (when *pending-evaluation-progress-hook*
    (funcall *pending-evaluation-progress-hook* phase message :detail detail)))

(defun pending-evaluation-origin-pane-id ()
  *pending-evaluation-origin-pane-id*)

(defun pending-evaluation-pane-id ()
  *pending-evaluation-pane-id*)

(defclass evaluation-pending-state ()
  ((request-id :reader evaluation-pending-request-id-of
               :initarg :request-id)
   (title :reader evaluation-pending-title-of
          :initarg :title)
   (started-at :reader evaluation-pending-started-at-of
               :initarg :started-at)
   (source-pane-object-summary :reader evaluation-pending-source-pane-object-summary-of
                               :initarg :source-pane-object-summary
                               :initform nil)
   (originating-expression :reader evaluation-pending-originating-expression-of
                           :initarg :originating-expression
                           :initform nil)
   (current-phase :accessor evaluation-pending-current-phase-of
                  :initarg :current-phase
                  :initform :evaluating)
   (stage-log :accessor evaluation-pending-stage-log-of
              :initarg :stage-log
              :initform nil)
   (final-result :accessor evaluation-pending-final-result-of
                 :initarg :final-result
                 :initform nil)
   (final-issue :accessor evaluation-pending-final-issue-of
                :initarg :final-issue
                :initform nil)))

(defclass deferred-evaluation-issue ()
  ((title :reader deferred-evaluation-issue-title-of
          :initarg :title
          :initform "Deferred evaluation failed")
   (summary :reader deferred-evaluation-issue-summary-of
            :initarg :summary
            :initform "The requested example or deferred expression failed while the pane path stayed intact.")
   (condition :reader deferred-evaluation-issue-condition-of
              :initarg :condition)
   (source-pane-object-summary :reader deferred-evaluation-issue-source-pane-object-summary-of
                               :initarg :source-pane-object-summary
                               :initform nil)
   (originating-expression :reader deferred-evaluation-issue-originating-expression-of
                           :initarg :originating-expression
                           :initform nil)
   (started-at :reader deferred-evaluation-issue-started-at-of
               :initarg :started-at
               :initform nil)))

(defmethod hv:text-representation ((state evaluation-pending-state))
  (evaluation-pending-title-of state))

(defmethod hv:text-representation ((issue deferred-evaluation-issue))
  (deferred-evaluation-issue-title-of issue))

(defun make-evaluation-pending-state (pane element target)
  (let* ((phase (pending-evaluation-phase-for-click element target))
         (message (pending-evaluation-phase-label phase))
         (started-at (maybe-current-time-millis))
         (source-summary (maybe-summarize-object-for-log (pane-object pane)))
         (originating-expression
          (or (hover-label-for-element element)
              (maybe-summarize-object-for-log target))))
    (make-instance
     'evaluation-pending-state
     :request-id (symbol-name (gensym "PENDING-EVAL-"))
     :title (pending-evaluation-title element target)
     :started-at started-at
     :source-pane-object-summary source-summary
     :originating-expression originating-expression
     :current-phase phase
     :stage-log (list (list :timestamp started-at
                            :phase phase
                            :message message)))))

(defun append-evaluation-pending-stage (state phase message &key detail)
  (setf (evaluation-pending-current-phase-of state) phase)
  (setf (evaluation-pending-stage-log-of state)
        (append (evaluation-pending-stage-log-of state)
                (list (list :timestamp (maybe-current-time-millis)
                            :phase phase
                            :message message
                            :detail detail))))
  state)

(defun pending-stage-relative-ms (state entry)
  (let ((timestamp (getf entry :timestamp))
        (started-at (evaluation-pending-started-at-of state)))
    (if (and (numberp timestamp)
             (numberp started-at))
        (max 0 (- timestamp started-at))
        0)))

(defun evaluation-pending-stage-log-text (state)
  (with-output-to-string (stream)
    (dolist (entry (evaluation-pending-stage-log-of state))
      (format stream "[+~Dms] ~A"
              (pending-stage-relative-ms state entry)
              (getf entry :message))
      (when-let (detail (getf entry :detail))
        (format stream " -- ~A" detail))
      (terpri stream))))

(defun pending-pane-dom-update-script (pane-id state)
  (let ((phase-text
         (string-downcase
          (symbol-name (evaluation-pending-current-phase-of state))))
        (status-text
         (pending-evaluation-phase-label
          (evaluation-pending-current-phase-of state)))
        (log-text (evaluation-pending-stage-log-text state)))
    (format nil
            "(function(){ var pane = document.getElementById(~A); if (!pane) { return; } var pendingNodes = pane.querySelectorAll('.hyperdoc-evaluation-pending'); pendingNodes.forEach(function(node){ node.setAttribute('data-hyperdoc-pending-phase', ~A); var status = node.querySelector('.hyperdoc-evaluation-pending-status'); if (status) { status.textContent = ~A; } }); var logNodes = pane.querySelectorAll('.hyperdoc-evaluation-stage-log pre'); logNodes.forEach(function(node){ node.textContent = ~A; }); })();"
            (encode-json-string-for-browser pane-id)
            (encode-json-string-for-browser phase-text)
            (encode-json-string-for-browser status-text)
            (encode-json-string-for-browser log-text))))

(defun update-pending-pane-dom-in-place (pane state)
  (when (and (live-pane-p pane)
             state)
    (when-let (pane-id (pane-runtime-id pane))
      (ignore-errors
        (clog:js-execute (clog-obj pane)
                         (pending-pane-dom-update-script pane-id state)))))
  pane)

(defun render-evaluation-pending-stage-log (state)
  (hv:html
   (:div :class "hyperdoc-evaluation-stage-log"
         :style "margin-top: 0.8em; border: 1px solid #ddd; background: #fafafa; padding: 0.6em;"
         (:div :style "font-weight: 600; margin-bottom: 0.4em;" "Console")
         (:pre :style "white-space: pre-wrap; margin: 0;"
               (hv:esc (evaluation-pending-stage-log-text state))))))

(hv:defview 👀summary (state evaluation-pending-state)
  (hv:html-view :title "Summary" :priority 1
                (hv:html
                 (:div :class "hyperdoc-evaluation-pending"
                       :data-hyperdoc-pending-pane "true"
                       :data-hyperdoc-pending-request-id
                       (hv:esc (evaluation-pending-request-id-of state))
                       :data-hyperdoc-pending-phase
                       (string-downcase
                        (symbol-name (evaluation-pending-current-phase-of state)))
                       (:h3 (hv:esc (evaluation-pending-title-of state)))
                       (:p :class "hyperdoc-evaluation-pending-status"
                           (hv:esc
                            (pending-evaluation-phase-label
                             (evaluation-pending-current-phase-of state))))
                       (:table :class "inspector-table"
                               (:tr (:td "Request id")
                                    (:td (:tt (hv:esc
                                               (evaluation-pending-request-id-of state)))))
                               (:tr (:td "Started at")
                                    (:td (:tt (hv:esc
                                               (format nil "~A"
                                                       (evaluation-pending-started-at-of state))))))
                               (:tr (:td "Source pane")
                                    (:td (:tt (hv:esc
                                               (or (evaluation-pending-source-pane-object-summary-of state)
                                                   "n/a")))))
                               (:tr (:td "Origin")
                                    (:td (:tt (hv:esc
                                               (or (evaluation-pending-originating-expression-of state)
                                                   "n/a"))))))
                       (render-evaluation-pending-stage-log state)))))

(hv:defview 👀log (state evaluation-pending-state)
  (hv:html-view :title "Log" :priority 2
                (render-evaluation-pending-stage-log state)))

(hv:defview 👀overview (issue deferred-evaluation-issue)
  (hv:html-view :title "Overview" :priority 1
                (hv:html
                 (:h3 (hv:esc (deferred-evaluation-issue-title-of issue)))
                 (:p (hv:esc (deferred-evaluation-issue-summary-of issue)))
                 (:table :class "inspector-table"
                         (:tr (:td "Origin")
                              (:td (:tt (hv:esc
                                         (or (deferred-evaluation-issue-originating-expression-of issue)
                                             "n/a")))))
                         (:tr (:td "Source pane")
                              (:td (:tt (hv:esc
                                         (or (deferred-evaluation-issue-source-pane-object-summary-of issue)
                                             "n/a")))))
                         (:tr (:td "Started at")
                              (:td (:tt (hv:esc
                                         (format nil "~A"
                                                 (deferred-evaluation-issue-started-at-of issue))))))
                         (:tr (:td "Condition")
                              (:td (hv:object-ref
                                    (deferred-evaluation-issue-condition-of issue))))))))

(hv:defview 👀condition (issue deferred-evaluation-issue)
  (hv:html-view :title "Condition" :priority 2
                (hv:html
                 (:p (hv:object-ref (deferred-evaluation-issue-condition-of issue))))))

(defun set-active-eval-button-state (element activep)
  (ignore-errors
    (if activep
        (progn
          (clog:remove-class element "inspector-action")
          (clog:add-class element "inspector-action-active"))
        (progn
          (clog:remove-class element "inspector-action-active")
          (clog:add-class element "inspector-action")))))

(defun live-pane-p (pane)
  (ignore-errors
    (and pane
         (clog-obj pane)
         (clog:connection-body (clog-obj pane))
         (not (string= (clog:html-id (clog-obj pane)) "undefined")))))

(defun pane-runtime-id (pane)
  (ignore-errors
    (and (live-pane-p pane)
         (clog:html-id (clog-obj pane)))))

(defun replace-pane-object-in-place (pane object &key select)
  (when (live-pane-p pane)
    (setf (pane-object pane) object)
    (refresh pane)
    (select-view pane (default-pane-selection pane select))
    (clog:focus (clog-obj pane))
    (clog:flush-connection-cache (clog-obj pane))
    pane))

(defun refresh-pending-pane (pane phase message &key detail)
  (when (and (live-pane-p pane)
             (typep (pane-object pane) 'evaluation-pending-state))
    (let ((state (pane-object pane)))
      (append-evaluation-pending-stage state phase message :detail detail)
      (update-pending-pane-dom-in-place pane state))))

(defun make-deferred-evaluation-issue (pane element condition)
  (make-instance
   'deferred-evaluation-issue
   :condition condition
   :source-pane-object-summary (maybe-summarize-object-for-log (pane-object pane))
   :originating-expression (or (hover-label-for-element element)
                               (maybe-summarize-object-for-log element))
   :started-at (maybe-current-time-millis)))

(defun failure-like-evaluation-result-p (result)
  (or (typep result 'deferred-evaluation-issue)
      (authored-expression-issue-p result)
      (git-runtime-unavailable-p result)
      (typep result 'condition)))

(defun maybe-git-runtime-unavailable-detail (result)
  (when (git-runtime-unavailable-p result)
    (ignore-errors
      (let ((package (find-package "HYPERDOC")))
        (when package
          (multiple-value-bind (symbol status)
              (find-symbol "REASON-OF" package)
            (when (and status
                       (fboundp symbol))
              (funcall (symbol-function symbol) result))))))))

(defun ensure-minimum-pending-pane-visibility (state)
  (let* ((started-at (evaluation-pending-started-at-of state))
         (elapsed (if (numberp started-at)
                      (max 0 (- (maybe-current-time-millis) started-at))
                      0))
         (remaining (- +minimum-pending-pane-visibility-ms+ elapsed)))
    (when (> remaining 0)
      (sleep (/ remaining 1000.0)))))

(defun start-pending-evaluation (pane element target &key select)
  (let* ((pending-state (make-evaluation-pending-state pane element target))
         (pending-pane (create-pane (inspector pane) pending-state :select "Summary")))
    (clog:flush-connection-cache (clog-obj pending-pane))
    (set-active-eval-button-state element t)
    (bordeaux-threads:make-thread
     (lambda ()
       (let ((result nil)
             (*pending-evaluation-progress-hook*
              (lambda (phase message &key detail)
                (clog:with-sync-event ((clog-obj pending-pane))
                  (refresh-pending-pane pending-pane phase message :detail detail))))
             (*pending-evaluation-origin-pane-id* (pane-runtime-id pane))
             (*pending-evaluation-pane-id* (pane-runtime-id pending-pane)))
         (handler-case
             (progn
               (clog:with-sync-event ((clog-obj pending-pane))
                 (refresh-pending-pane pending-pane :evaluating "Evaluating..."))
               (setf result (hv:eval-thunk target)))
           (error (condition)
             (setf result (make-deferred-evaluation-issue pane element condition))))
         (when (git-runtime-unavailable-p result)
           (clog:with-sync-event ((clog-obj pending-pane))
             (refresh-pending-pane pending-pane
                                   :waiting-for-git
                                   "Waiting for Git..."
                                   :detail (or (maybe-git-runtime-unavailable-detail result)
                                               "Git-backed inspection is unavailable in this runtime."))))
         (ensure-minimum-pending-pane-visibility pending-state)
         (clog:with-sync-event ((clog-obj pending-pane))
           (unwind-protect
                (if (failure-like-evaluation-result-p result)
                    (progn
                      (refresh-pending-pane pending-pane :failed "Failed")
                      (replace-pane-object-in-place pending-pane result))
                    (progn
                      (refresh-pending-pane pending-pane :opening-result "Opening result...")
                      (replace-pane-object-in-place pending-pane result
                                                    :select select)))
             (set-active-eval-button-state element nil)))))
     :name (format nil "hyperdoc-pending-eval-~A"
                   (evaluation-pending-request-id-of pending-state)))
    pending-pane))

(defun class-present-p (element class-name)
  (let ((classes (maybe-attribute-value element "class")))
    (and (stringp classes)
         (search class-name classes :test #'char-equal))))

(defun dom-association-submit-click-p (element)
  (loop for current = element then (ignore-errors (clog:parent current))
        while current
        thereis (or (maybe-attribute-value
                     current "data-dom-association-request-id")
                    (maybe-attribute-value
                     current "data-dom-association-transport")
                    (maybe-attribute-value
                     current "data-dom-connect-request-evidence-request-id")
                    (class-present-p current "hyperdoc-dom-connect-submit")
                    (class-present-p current "hyperdoc-dom-connect-evidence-submit"))))

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

(defun handle-inspector-reference-eval-click (pane obj target event &optional view-ref)
  (if (and (fboundp 'handle-inspector-eval-click)
           (dom-association-submit-click-p obj))
      (handle-inspector-eval-click pane obj target event)
      (with-slots (inspector clog-obj) pane
        (unless (getf event :shift-key)
          (close-panes-after inspector pane))
        (if (getf event :alt-key)
            (create-pane inspector target)
            (if (pending-evaluation-click-p obj target)
                (start-pending-evaluation pane obj target :select view-ref)
                (create-pane inspector
                             (eval-thunk-with-active-button clog-obj obj target)
                             :select view-ref))))))

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
                 (let ((view-ref nil))
                   (when (eql (length html-id-parts) 3)
                     (setf view-ref (hv:decode-base32 (third html-id-parts))))
                   (clog:set-on-mouse-click
                    ref-element
                    #'(lambda (obj event)
                        (handle-inspector-reference-eval-click pane obj target event view-ref))
                    :cancel-event t)
                   (setf (clog:attribute ref-element
                                         "data-hyperdoc-eval-bound")
                         "true"))))))))))
