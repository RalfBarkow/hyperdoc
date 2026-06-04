;;;; Inspector performance overrides
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :clog-moldable-inspector)

(defvar *inspector-performance-logging* t)
(defvar *inspector-operation-id* nil)

(defun current-time-millis ()
  (round (* 1000 (/ (get-internal-real-time)
                    internal-time-units-per-second))))

(defun elapsed-millis (start-millis)
  (- (current-time-millis) start-millis))

(defun summarize-object-for-log (object)
  (handler-case
      (typecase object
        (class
         (format nil "class ~A" (or (class-name object) "<anonymous-class>")))
        (hv:view
         (format nil "view ~A" (hv:view-title object)))
        (t
         (format nil "~A" (type-of object))))
    (error ()
      "<unprintable-object>")))

(defun log-inspector-performance (phase &rest kvs)
  (when *inspector-performance-logging*
    (format *trace-output* "~&[INSPECTOR-PERF] ~A" phase)
    (when *inspector-operation-id*
      (format *trace-output* " request-id=~S" *inspector-operation-id*))
    (loop for (key value) on kvs by #'cddr
          do (format *trace-output* " ~A=~S" key value))
    (terpri *trace-output*)
    (finish-output *trace-output*)))

(defun html-view-realized-p (view)
  (not (null (slot-value view 'html-inspector-views::html))))

(defun normalize-dom-html-id (html-id)
  (typecase html-id
    (string html-id)
    (symbol (symbol-name html-id))
    (character (string html-id))
    (t (princ-to-string html-id))))

(defun dom-node-count-query-script (html-id)
  (format nil
          "(function(){var el=document.getElementById(~S); return el ? String(el.querySelectorAll('*').length) : '0';})()"
          (normalize-dom-html-id html-id)))

(defun dom-node-count (element)
  (when (clog:connection-body element)
    (ignore-errors
      (parse-integer
       (or (clog:js-query
            element
            (dom-node-count-query-script (clog:html-id element)))
           "0")
       :junk-allowed t))))

(defun find-class-in-package (package-name class-name)
  (let ((package (find-package package-name)))
    (when package
      (multiple-value-bind (symbol status)
          (find-symbol class-name package)
        (when status
          (find-class symbol nil))))))

(defun html-page-object-p (object)
  (let ((hyperdoc-html-page (find-class-in-package :hyperdoc "HTML-PAGE"))
        (hyperbook-html-page (find-class-in-package :hyperbook "HTML-PAGE")))
    (or (and hyperdoc-html-page
             (typep object hyperdoc-html-page))
        (and hyperbook-html-page
             (typep object hyperbook-html-page)))))

(defun first-html-page-content-render-p (pane view)
  (and (string= (hv:view-title view) "Content")
       (not (html-view-realized-p view))
       (html-page-object-p (pane-object pane))))

(defclass html-page-content-render-event ()
  ((phase :initarg :phase
          :reader html-page-content-render-event-phase-of)
   (timestamp :initarg :timestamp
              :reader html-page-content-render-event-timestamp-of)
   (elapsed-ms :initarg :elapsed-ms
               :reader html-page-content-render-event-elapsed-ms-of)
   (message :initarg :message
            :initform nil
            :reader html-page-content-render-event-message-of)
   (details :initarg :details
            :initform nil
            :reader html-page-content-render-event-details-of)
   (completedp :initarg :completedp
               :initform t
               :reader html-page-content-render-event-completedp)))

(defclass html-page-content-render-report ()
  ((object :initarg :object
           :reader html-page-content-render-report-object-of)
   (object-summary :initarg :object-summary
                   :reader html-page-content-render-report-object-summary-of)
   (view-title :initarg :view-title
               :reader html-page-content-render-report-view-title-of)
   (start-timestamp :initarg :start-timestamp
                    :reader html-page-content-render-report-start-timestamp-of)
   (start-millis :initarg :start-millis
                 :reader html-page-content-render-report-start-millis-of)
   (events :initform nil
           :accessor html-page-content-render-report-events-of)
   (html-cache-hit? :initform nil
                    :accessor html-page-content-render-report-html-cache-hit?-of)
   (html-ms :initform nil
            :accessor html-page-content-render-report-html-ms-of)
   (reference-count :initform nil
                    :accessor html-page-content-render-report-reference-count-of)
   (asset-count :initform nil
                :accessor html-page-content-render-report-asset-count-of)
   (condition :initform nil
              :accessor html-page-content-render-report-condition-of)
   (condition-type :initform nil
                   :accessor html-page-content-render-report-condition-type-of)
   (condition-message :initform nil
                      :accessor html-page-content-render-report-condition-message-of)
   (last-completed-phase :initform nil
                         :accessor html-page-content-render-report-last-completed-phase-of)))

(defun make-html-page-content-render-report (object view)
  (make-instance 'html-page-content-render-report
                 :object object
                 :object-summary (summarize-object-for-log object)
                 :view-title (hv:view-title view)
                 :start-timestamp (get-universal-time)
                 :start-millis (current-time-millis)))

(defun record-html-page-content-render-event
    (report phase &key message details (completedp t))
  (let ((event (make-instance 'html-page-content-render-event
                              :phase phase
                              :timestamp (get-universal-time)
                              :elapsed-ms (elapsed-millis
                                           (html-page-content-render-report-start-millis-of
                                            report))
                              :message message
                              :details details
                              :completedp completedp)))
    (setf (html-page-content-render-report-events-of report)
          (append (html-page-content-render-report-events-of report)
                  (list event)))
    (when completedp
      (setf (html-page-content-render-report-last-completed-phase-of report)
            phase))
    event))

(defun record-html-page-content-render-condition (report condition)
  (setf (html-page-content-render-report-condition-of report) condition
        (html-page-content-render-report-condition-type-of report)
        (type-of condition)
        (html-page-content-render-report-condition-message-of report)
        (princ-to-string condition))
  report)

(defun render-debugger-value (value)
  (cond
    ((null value)
     (hv:html (:span :style "opacity: 0.55;" "-")))
    ((typep value 'condition)
     (hv:object-ref value))
    (t
     (hv:html (:tt (hv:esc (format nil "~A" value)))))))

(defun render-debugger-boolean (value)
  (hv:html (:tt (hv:esc (if value "true" "false")))))

(defun universal-time-label (universal-time)
  (multiple-value-bind (second minute hour date month year)
      (decode-universal-time universal-time)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
            year month date hour minute second)))

(defmethod hv:text-representation ((event html-page-content-render-event))
  (format nil "~A (~D ms)"
          (html-page-content-render-event-phase-of event)
          (html-page-content-render-event-elapsed-ms-of event)))

(defmethod hv:text-representation ((report html-page-content-render-report))
  (format nil "Content render report for ~A"
          (html-page-content-render-report-object-summary-of report)))

(hv:defview 👀overview (report html-page-content-render-report)
  (hv:html-view
   :title "Overview"
   :priority 1
   (hv:html
    (:h3 "Content Render Debugger")
    (:p "This report records html-page Content materialization phases for the browser-visible inspector pane.")
    (:table :class "inspector-table"
            (:tr (:td "Object")
                 (:td (hv:esc
                       (html-page-content-render-report-object-summary-of report))))
            (:tr (:td "View")
                 (:td (:tt (hv:esc
                            (html-page-content-render-report-view-title-of report)))))
            (:tr (:td "Started at")
                 (:td (:tt (hv:esc
                            (universal-time-label
                             (html-page-content-render-report-start-timestamp-of
                              report))))))
            (:tr (:td "HTML cache hit?")
                 (:td (render-debugger-boolean
                       (html-page-content-render-report-html-cache-hit?-of report))))
            (:tr (:td "HTML ms")
                 (:td (render-debugger-value
                       (html-page-content-render-report-html-ms-of report))))
            (:tr (:td "References")
                 (:td (render-debugger-value
                       (html-page-content-render-report-reference-count-of report))))
            (:tr (:td "Assets")
                 (:td (render-debugger-value
                       (html-page-content-render-report-asset-count-of report))))
            (:tr (:td "Last completed phase")
                 (:td (render-debugger-value
                       (html-page-content-render-report-last-completed-phase-of
                        report))))
            (:tr (:td "Condition")
                 (:td (render-debugger-value
                       (html-page-content-render-report-condition-of report))))))))

(hv:defview 👀events (report html-page-content-render-report)
  (hv:html-view
   :title "Events"
   :priority 2
   (hv:html
    (:table :class "inspector-table"
            (:tr (:th "Phase")
                 (:th "Elapsed ms")
                 (:th "Completed?")
                 (:th "Message")
                 (:th "Details"))
            (loop for event in (html-page-content-render-report-events-of report)
                  do (hv:html
                      (:tr
                       (:td (:tt (hv:esc
                                  (format nil "~A"
                                          (html-page-content-render-event-phase-of
                                           event)))))
                       (:td (hv:esc
                             (format nil "~D"
                                     (html-page-content-render-event-elapsed-ms-of
                                      event))))
                       (:td (hv:esc
                             (if (html-page-content-render-event-completedp event)
                                 "yes"
                                 "no")))
                       (:td (render-debugger-value
                             (html-page-content-render-event-message-of event)))
                       (:td (render-debugger-value
                             (html-page-content-render-event-details-of
                              event))))))))))

(hv:defview 👀condition (report html-page-content-render-report)
  (hv:html-view
   :title "Condition"
   :priority 3
   (hv:html
    (if (html-page-content-render-report-condition-of report)
        (hv:html
         (:h3 "Render condition")
         (:table :class "inspector-table"
                 (:tr (:td "Type")
                      (:td (:tt (hv:esc
                                 (format nil "~A"
                                         (html-page-content-render-report-condition-type-of
                                          report))))))
                 (:tr (:td "Message")
                      (:td (hv:esc
                            (html-page-content-render-report-condition-message-of
                             report))))
                 (:tr (:td "Condition object")
                      (:td (hv:object-ref
                            (html-page-content-render-report-condition-of report))))))
        (hv:html
         (:p "No render condition has been recorded."))))))

(hv:defview 👀page-object (report html-page-content-render-report)
  (hv:html-view
   :title "Page / Object"
   :priority 4
   (hv:html
    (:h3 "Rendered object")
    (:p (hv:object-ref
         (html-page-content-render-report-object-of report)
         :display (html-page-content-render-report-object-summary-of report))))))

(defun set-html-page-render-state (view-element state)
  (setf (clog:attribute view-element "data-hyperdoc-render-state") state
        (clog:attribute view-element "aria-busy")
        (if (member state '("ready" "error") :test #'string=)
            "false"
            "true")))

(defun show-html-page-render-debug-state
    (pane view-element report &key (state "debugging")
                               (message "Materializing html-page Content view."))
  (set-html-page-render-state view-element state)
  (multiple-value-bind (html references assets)
      (hv:html-and-references
       (:div :class "hyperdoc-html-page-render-debugger"
             :role "status"
             :aria-live "polite"
             :data-hyperdoc-content-render-debugger "true"
             (:h3 "Content render debugger")
             (:p (hv:esc message))
             (:table :class "inspector-table"
                     (:tr (:td "Object")
                          (:td (hv:esc
                                (html-page-content-render-report-object-summary-of
                                 report))))
                     (:tr (:td "View")
                          (:td (:tt (hv:esc
                                     (html-page-content-render-report-view-title-of
                                      report)))))
                     (:tr (:td "Last completed phase")
                          (:td (render-debugger-value
                                (html-page-content-render-report-last-completed-phase-of
                                 report))))
                     (:tr (:td "Condition")
                          (:td (render-debugger-value
                                (html-page-content-render-report-condition-of
                                 report)))))
             (:p (hv:object-ref report
                                :display "Inspect render report"
                                :select "Overview"))))
    (declare (ignore assets))
    (setf (clog:inner-html view-element) html)
    (set-event-handlers pane view-element references))
  report)

(defun default-pane-selection (pane select)
  (cond
    (select
     select)
    ((typep (pane-object pane) 'class)
     (or (and (find "Overview"
                    (pane-views pane)
                    :key #'hv:view-title
                    :test #'string=)
              "Overview")
         0))
    (t
     0)))

(defun inspector-pane-element-p (element)
  (let ((classes (or (clog:attribute element "class") "")))
    (or (search "inspector-pane" classes :test #'char=)
        (search "inspector-pane-maximized" classes :test #'char=))))

(defun inspector-pane-count (container)
  (count-if #'inspector-pane-element-p
            (child-elements container)))

(defun scroll-inspector-parent-to-active-edge (parent)
  ;; Upstream always scrolls to the right edge after creating a pane. That is
  ;; correct once multiple panes exist, but it clips the left gutter of the
  ;; first pane on narrow viewports by introducing a small positive scroll-left.
  (setf (clog:scroll-left parent)
        (if (> (inspector-pane-count parent) 1)
            (max 0 (- (clog:scroll-width parent)
                      (clog:client-width parent)))
            0)))

(defparameter +hyperdoc-reel-css-url+
  "/assets/hyperdoc/css/hyperdoc-reel.css")

(defparameter +hyperdoc-reel-js-url+
  "/assets/hyperdoc/js/hyperdoc-reel.js")

(defun versioned-reel-asset-url (asset-url asset-relative-path)
  (let* ((asset-file (asdf:system-relative-pathname
                      :hyperbook/server
                      asset-relative-path))
         (date (ignore-errors (file-write-date asset-file))))
    (if date
        (format nil "~A?date=~A" asset-url date)
        asset-url)))

(defun ensure-reel-asset-path ()
  (clog-connection:add-plugin-path
   "^/assets/"
   (uiop:ensure-directory-pathname
    (asdf:system-relative-pathname :hyperbook/server ""))))

(defun load-hyperdoc-reel-assets (body)
  (when (typep body 'clog:clog-body)
    (ensure-reel-asset-path)
    (let ((css-url (versioned-reel-asset-url
                    +hyperdoc-reel-css-url+
                    "assets/hyperdoc/css/hyperdoc-reel.css"))
          (js-url (versioned-reel-asset-url
                   +hyperdoc-reel-js-url+
                   "assets/hyperdoc/js/hyperdoc-reel.js")))
      (clog:js-execute
       body
       (format nil
               "(function(){var href=~S;var src=~S;if(!document.querySelector('link[data-hyperdoc-reel-css]')){var link=document.createElement('link');link.rel='stylesheet';link.href=href;link.dataset.hyperdocReelCss='true';document.head.appendChild(link);}if(!document.querySelector('script[data-hyperdoc-reel-js]')){var script=document.createElement('script');script.src=src;script.defer=true;script.dataset.hyperdocReelJs='true';document.head.appendChild(script);}else if(window.hyperdocReel){window.hyperdocReel.init(document);}})()"
               css-url
               js-url)))))

(defun make-reel-button (parent class label glyph)
  (let ((button (clog:create-button
                 parent
                 :class class
                 :content (format nil
                                  "<span class=\"hyperdoc-sr\">~A</span><span aria-hidden=\"true\">~A</span>"
                                  label
                                  glyph))))
    (setf (clog:attribute button "type") "button")
    (setf (clog:attribute button "aria-label") label)
    button))

(defun create-inspector (parent-obj &key (pane-width "600px") (playground? t))
  (let* ((reel (clog:create-section parent-obj :section
                                    :class "hyperdoc-reel"))
         (viewport (clog:create-div reel :class "hyperdoc-reel__viewport"))
         (buttons (clog:create-div viewport :class "hyperdoc-reel__buttons"))
         (scrollable (clog:create-div viewport
                                      :class "inspector hyperdoc-reel__scrollable hyperdoc-reel__list")))
    (setf (clog:attribute reel "role") "group")
    (setf (clog:attribute reel "aria-label") "Inspector views")
    (setf (clog:hiddenp buttons) t)
    (make-reel-button buttons "hyperdoc-reel__prev" "previous" "&lt;")
    (make-reel-button buttons "hyperdoc-reel__next" "next" "&gt;")
    (setf (clog:attribute scrollable "role") "list")
    (setf (clog:attribute scrollable "tabindex") "0")
    (make-instance 'inspector
                   :clog-obj scrollable
                   :pane-width pane-width
                   :playground? playground?)))

(defun create-dom (pane)
  (with-slots (clog-obj view-ids) pane
    (let* ((parent (clog:parent-element clog-obj))
           (title-bar (create-title-bar pane))
           (tab-bar (create-tabs pane))
           (body (clog:create-div clog-obj :class "inspector-body")))
      (declare (ignore title-bar tab-bar))
      (dolist (id view-ids)
        (clog:create-div body :html-id id :class "inspector-view"))
      (scroll-inspector-parent-to-active-edge parent))))

;; Replace upstream create-pane to log timings and to default class panes
;; to a cheap tab instead of the first source-heavy view.
(defun create-pane (inspector object &key (select nil))
  (let ((pane-start (current-time-millis)))
    (log-inspector-performance :create-pane/start
                               :object (summarize-object-for-log object)
                               :select select)
    (with-slots (panes) inspector
      (fset:do-seq (some-pane panes)
        (minimize some-pane)))
    (let* ((pane (make-instance 'pane
                                :inspector inspector
                                :object object))
           (style-attr (format nil "flex-basis: ~a; min-width: min(~a, 95%);"
                               (inspector-pane-width inspector)
                               (inspector-pane-width inspector)))
           (dom-start (current-time-millis)))
      (setf (clog-obj pane) (clog:create-div (clog-obj inspector)
                                             :class "inspector-pane hyperdoc-reel__item"
                                             :style style-attr))
      (setf (clog:attribute (clog-obj pane) "tabindex") "0")
      (setf (clog:attribute (clog-obj pane) "role") "listitem")
      (clog:focus (clog-obj pane))
      (let ((load-start (current-time-millis)))
        (load-views pane)
        (log-inspector-performance :create-pane/load-views
                                   :object (summarize-object-for-log object)
                                   :view-count (length (pane-views pane))
                                   :ms (elapsed-millis load-start)))
      (create-dom pane)
      (log-inspector-performance :create-pane/create-dom
                                 :object (summarize-object-for-log object)
                                 :ms (elapsed-millis dom-start))
      (add-pane inspector pane)
      (let* ((resolved-select (default-pane-selection pane select))
             (view-title (typecase resolved-select
                           (integer (hv:view-title (nth resolved-select
                                                        (pane-views pane))))
                           (hv:view (hv:view-title resolved-select))
                           (t resolved-select))))
        (log-inspector-performance :create-pane/select
                                   :object (summarize-object-for-log object)
                                   :resolved-select view-title)
        (select-view pane resolved-select))
      (log-inspector-performance :create-pane/done
                                 :object (summarize-object-for-log object)
                                 :ms (elapsed-millis pane-start))
      pane)))

(defun on-new-inspector (body &key (object *object*)
                                   (pane-width *pane-width*)
                                   (title "Inspector")
                                   (playground? t))
  (let ((sb (clog:create-style-block (clog:connection-body body))))
    (setf (clog:text sb) *css*))
  (when (typep body 'clog:clog-body)
    (let ((html-document (clog:html-document body)))
      (setf (clog:title html-document) title)))
  (let ((inspector (create-inspector body
                                     :pane-width pane-width
                                     :playground? playground?)))
    (load-hyperdoc-reel-assets body)
    (create-pane inspector object)))

(defmethod select-view ((pane pane) view-index-or-title)
  (let ((start (current-time-millis)))
    (log-inspector-performance :select-view/start
                               :object (summarize-object-for-log (pane-object pane))
                               :request view-index-or-title)
    (with-slots (clog-obj views tab-ids view-ids active-view) pane
      (let ((view-index 0))
        (if (numberp view-index-or-title)
            (setf view-index view-index-or-title)
            (loop for view in views
                  for index from 0
                  do (when (string= (hv:view-title view) view-index-or-title)
                       (setf view-index index))))
        (loop for view-id in view-ids
              for tab-id in tab-ids
              for index from 0
              do (let ((active? (equal index view-index))
                       (tab (clog:attach-as-child clog-obj tab-id)))
                   (if active?
                       (clog:add-class tab "active")
                       (clog:remove-class tab "active"))
                   (setf (clog:hiddenp (clog:attach-as-child clog-obj view-id))
                         (not active?))))
        (let ((view (nth view-index views))
              (view-element (clog:attach-as-child clog-obj (nth view-index view-ids))))
          (log-inspector-performance :select-view/active
                                     :object (summarize-object-for-log (pane-object pane))
                                     :view (hv:view-title view)
                                     :cached-body? (not (string= (-> view-element clog:first-child clog:html-id)
                                                                 "undefined")))
          (when (string= (-> view-element clog:first-child clog:html-id) "undefined")
            (create-view-element pane view-element view)))
        (setf active-view view-index)))
    (log-inspector-performance :select-view/done
                               :object (summarize-object-for-log (pane-object pane))
                               :active-index (pane-active-view pane)
                               :ms (elapsed-millis start))))

(defmethod create-view-element :around ((pane pane) parent-element (view hv:html-view))
  (let* ((debug-state? (first-html-page-content-render-p pane view))
         (report (and debug-state?
                      (make-html-page-content-render-report
                       (pane-object pane)
                       view))))
    (when debug-state?
      (record-html-page-content-render-event
       report
       :debugger-visible
       :message "Browser-visible Content render debugger inserted.")
      (show-html-page-render-debug-state pane parent-element report)
      (log-inspector-performance :view/loading
                                 :object (summarize-object-for-log (pane-object pane))
                                 :view (hv:view-title view)))
    (flet ((render-view ()
             (let* ((html-start (current-time-millis))
                    (html-cached? (html-view-realized-p view)))
               (when report
                 (setf (html-page-content-render-report-html-cache-hit?-of report)
                       html-cached?)
                 (record-html-page-content-render-event
                  report
                  :html-materialization-start
                  :message "Content view HTML materialization started."
                  :completedp nil))
               (let* ((html (hv:view-html view))
                      (references (hv:view-references view))
                      (assets (hv:view-assets view))
                      (html-ms (elapsed-millis html-start))
                      (html-length (length html))
                      (html-node-count (count #\< html))
                      (insert-start (current-time-millis)))
                 (when report
                   (setf (html-page-content-render-report-html-ms-of report)
                         html-ms
                         (html-page-content-render-report-reference-count-of report)
                         (length references)
                         (html-page-content-render-report-asset-count-of report)
                         (length assets))
                   (record-html-page-content-render-event
                    report
                    :html-materialized
                    :message "Content view HTML materialized."
                    :details (list :html-length html-length
                                   :html-node-count html-node-count
                                   :reference-count (length references)
                                   :asset-count (length assets))))
                 (let* ((result (call-next-method))
                        (post-insert-ms (elapsed-millis insert-start))
                        (dom-nodes (dom-node-count parent-element)))
                   (when report
                     (set-html-page-render-state parent-element "ready")
                     (record-html-page-content-render-event
                      report
                      :dom-inserted
                      :message "Rendered Content view replaced debugger placeholder."
                      :details (list :insert-ms post-insert-ms
                                     :dom-node-count dom-nodes)))
                   (log-inspector-performance :view/render
                                              :object (summarize-object-for-log (pane-object pane))
                                              :view (hv:view-title view)
                                              :html-cache-hit? html-cached?
                                              :html-ms html-ms
                                              :insert-ms post-insert-ms
                                              :html-length html-length
                                              :html-node-count html-node-count
                                              :reference-count (length references)
                                              :asset-count (length assets)
                                              :dom-node-count dom-nodes)
                   result)))))
      (if report
          (handler-case
              (render-view)
            (error (condition)
              (record-html-page-content-render-condition report condition)
              (record-html-page-content-render-event
               report
               :render-failed
               :message (princ-to-string condition)
               :details (list :condition-type (type-of condition))
               :completedp nil)
              (show-html-page-render-debug-state
               pane parent-element report
               :state "error"
               :message "Content rendering failed. Inspect the render report for the failing phase and condition.")
              (log-inspector-performance :view/render-error
                                         :object (summarize-object-for-log (pane-object pane))
                                         :view (hv:view-title view)
                                         :condition-type (type-of condition)
                                         :condition-message (princ-to-string condition)
                                         :last-completed-phase
                                         (html-page-content-render-report-last-completed-phase-of
                                          report))
              report))
          (render-view)))))

(in-package #:html-inspector-views/standard)

(defparameter *class-source-context-max-forms* 4)
(defparameter *class-source-context-max-lines* 160)
(defparameter *class-source-context-max-characters* 10000)

(defvar *class-source-location-cache* (make-hash-table :test #'eq))
(defvar *class-source-parse-cache* (make-hash-table :test #'equal))
(defvar *class-source-render-cache* (make-hash-table :test #'equal))

(defun source-log (phase &rest kvs)
  (apply #'clog-moldable-inspector::log-inspector-performance phase kvs))

(defun cached-class-source-location (class)
  (multiple-value-bind (cached foundp)
      (gethash class *class-source-location-cache*)
    (if foundp
        (progn
          (source-log :class-source/location
                      :class (or (class-name class) "<anonymous-class>")
                      :cache-hit? t
                      :pathname (and (consp cached)
                                     (first cached)
                                     (namestring (first cached)))
                      :offset (and (consp cached) (second cached))
                      :ms 0)
          (if (eq cached :missing)
              (values nil nil t)
              (values (first cached) (second cached) t)))
        (let* ((start (clog-moldable-inspector::current-time-millis))
               (location (multiple-value-list (source-code-location class)))
               (pathname (first location))
               (offset (second location)))
          (setf (gethash class *class-source-location-cache*)
                (if pathname
                    (list pathname offset)
                    :missing))
          (source-log :class-source/location
                      :class (or (class-name class) "<anonymous-class>")
                      :cache-hit? nil
                      :pathname (and pathname (namestring pathname))
                      :offset offset
                      :ms (clog-moldable-inspector::elapsed-millis start))
          (values pathname offset nil)))))

(defun cached-parse-lisp-code (pathname)
  (let* ((key (namestring pathname))
         (start (clog-moldable-inspector::current-time-millis)))
    (multiple-value-bind (code foundp)
        (gethash key *class-source-parse-cache*)
      (unless foundp
        (setf code (parse-lisp-code pathname)
              (gethash key *class-source-parse-cache*) code))
      (source-log :class-source/parse
                  :pathname key
                  :cache-hit? foundp
                  :ms (clog-moldable-inspector::elapsed-millis start))
      code)))

(defun top-level-form-range (form)
  (let ((source (cst:source (cst-of form))))
    (and source
         (values (car source) (cdr source)))))

(defun top-level-form-sexp (form)
  (ignore-errors (s-exp form)))

(defun top-level-form-head (form)
  (let ((sexp (top-level-form-sexp form)))
    (and (consp sexp) (car sexp))))

(defun top-level-form-second (form)
  (let ((sexp (top-level-form-sexp form)))
    (and (consp sexp) (second sexp))))

(defun cst-sexp (cst)
  (ignore-errors (s-exp cst)))

(defun class-definition-cst-in-form (form class-name)
  (let ((matches nil))
    (labels ((walk (node)
               (when (typep node 'cst:cons-cst)
                 (let ((sexp (cst-sexp node)))
                   (when (and (consp sexp)
                              (eq (car sexp) 'defclass)
                              (eql (second sexp) class-name))
                     (push node matches)))
                 (loop for item = node then (cst:rest item)
                       while (cst:consp item)
                       do (walk (cst:first item))))))
      (walk (cst-of form)))
    (first (nreverse matches))))

(defun cst-range (cst)
  (let ((source (cst:source cst)))
    (and source
         (values (car source) (cdr source)))))

(defun cst-text (code cst)
  (with-slots (source) code
    (multiple-value-bind (start end)
        (cst-range cst)
      (and start end
           (str:substring start end source)))))

(defun cst-line-count (code cst)
  (let ((text (cst-text code cst)))
    (if text
        (1+ (count #\Newline text))
        0)))

(defun cst-character-count (code cst)
  (length (or (cst-text code cst) "")))

(defun contains-symbol-p (tree symbol)
  (cond
    ((eql tree symbol) t)
    ((consp tree)
     (or (contains-symbol-p (car tree) symbol)
         (contains-symbol-p (cdr tree) symbol)))
    (t nil)))

(defun containing-form-index (forms offset)
  (loop for form in forms
        for idx from 0
        for range = (multiple-value-list (top-level-form-range form))
        for start = (first range)
        for end = (second range)
        when (and start
                  end
                  (>= offset start)
                  (< offset end))
        do (return idx)))

(defun exact-or-nearby-class-definition (forms class-name offset)
  (let ((containing (containing-form-index forms offset)))
    (labels ((class-form-cst (index)
               (and index
                    (<= 0 index)
                    (< index (length forms))
                    (class-definition-cst-in-form (nth index forms) class-name))))
      (cond
        ((class-form-cst containing)
         (values containing (class-form-cst containing) :exact-definition))
        ((loop for delta in '(1 -1 2 -2)
               for idx = (and containing (+ containing delta))
               for cst = (class-form-cst idx)
               when cst
               do (return (values idx cst :heuristic-nearby))))
        (containing
         (values containing nil :nearest-containing-form))
        (t
         (values nil nil :no-location))))))

(defun form-text (code index)
  (with-slots (source top-level-forms) code
    (let ((form (nth index top-level-forms)))
      (multiple-value-bind (start end)
          (top-level-form-range form)
        (and start end
             (str:substring start end source))))))

(defun form-line-count (code index)
  (let ((text (form-text code index)))
    (if text
        (1+ (count #\Newline text))
        0)))

(defun form-character-count (code index)
  (length (or (form-text code index) "")))

(defun capped-context-indices (code indices)
  (let ((result (copy-list indices)))
    (loop while (and (> (length result) 1)
                     (or (> (reduce #'+ result :key (lambda (index)
                                                      (form-line-count code index))
                                    :initial-value 0)
                            *class-source-context-max-lines*)
                         (> (reduce #'+ result :key (lambda (index)
                                                      (form-character-count code index))
                                    :initial-value 0)
                            *class-source-context-max-characters*)
                         (> (length result) *class-source-context-max-forms*)))
          do (setf result (butlast result)))
    result))

(defun context-form-indices (code forms target-index class-name)
  (let ((indices (list target-index)))
    (when (and (> target-index 0)
               (eq (top-level-form-head (nth (1- target-index) forms)) 'defclass))
      (push (1- target-index) indices))
    (loop for idx from (1+ target-index) below (length forms)
          while (< (length indices) *class-source-context-max-forms*)
          for sexp = (top-level-form-sexp (nth idx forms))
          when (or (and sexp (contains-symbol-p sexp class-name))
                   (and sexp (contains-symbol-p sexp 'change-class))
                   (eq (top-level-form-head (nth idx forms)) 'defclass))
          do (setf indices (append indices (list idx))))
    (capped-context-indices code (sort indices #'<))))

(defun render-form-indices-as-html (code indices)
  (with-slots (source top-level-forms) code
    (html
     (:pre :class "code-snippet"
           (:code
            (loop for idx in indices
                  for form = (nth idx top-level-forms)
                  for cst = (cst-of form)
                  for range = (cst:source cst)
                  for start = (and range (car range))
                  for last-index = (car (last indices))
                  do (when start
                       (html
                        (:lisp-toplevel
                         (render-toplevel-cst nil cst source start)))
                       (unless (eql idx last-index)
                         (str (format nil "~%~%"))))))))))

(defun render-cst-as-html (code cst)
  (with-slots (source) code
    (multiple-value-bind (start _end)
        (cst-range cst)
      (declare (ignore _end))
      (html
       (:pre :class "code-snippet"
             (:code
              (when start
                (render-cst cst source start))))))))

(defun source-metadata-bar (pathname locator-kind indices truncated?)
  (html
   (:div :class "inspector-index" :style "text-align:right;padding-right:10px"
         (:small
          (esc (format nil "~A | locator: ~A | forms: ~D~:[~; | truncated~]"
                       (file-namestring pathname)
                       locator-kind
                       (length indices)
                       truncated?))))))

(defun compact-source-fallback (class pathname locator-kind)
  (html
   (:div :class "inspector-index"
         (:small
          (esc (format nil "Precise definition source unavailable for ~A."
                       (or (class-name class) "<anonymous-class>")))))
   (:table :class "inspector-table"
           (:tr (:th "Pathname")
                (:td (esc (or (and pathname (namestring pathname))
                              "Unavailable"))))
           (:tr (:th "Locator")
                (:td (esc (princ-to-string locator-kind)))))
   (:p (:i "Use a source-aware editor or a richer source locator to recover a tighter definition excerpt."))))

(defun single-cst-metadata-bar (pathname locator-kind code cst)
  (html
   (:div :class "inspector-index" :style "text-align:right;padding-right:10px"
         (:small
          (esc (format nil "~A | locator: ~A | lines: ~D | chars: ~D"
                       (file-namestring pathname)
                       locator-kind
                       (cst-line-count code cst)
                       (cst-character-count code cst)))))))

(defun cached-class-source-render (class mode)
  (multiple-value-bind (pathname offset location-cache-hit?)
      (cached-class-source-location class)
    (declare (ignore location-cache-hit?))
    (let* ((class-name (class-name class))
           (cache-key (list mode
                            (and pathname (namestring pathname))
                            offset
                            class-name)))
      (multiple-value-bind (cached foundp)
          (gethash cache-key *class-source-render-cache*)
        (if foundp
            (progn
              (source-log :class-source/render-cache
                          :class class-name
                          :mode mode
                          :cache-hit? t
                          :pathname (and pathname (namestring pathname))
                          :offset offset)
              (values-list cached))
            (let ((render-start (clog-moldable-inspector::current-time-millis)))
              (multiple-value-bind (html references assets)
                  (cond
                    ((null pathname)
                     (html-and-references
                      (compact-source-fallback class pathname :no-pathname)))
                    (t
                     (let* ((code (cached-parse-lisp-code pathname))
                            (forms (slot-value code 'top-level-forms))
                            (target-index nil)
                            (definition-cst nil)
                            (locator-kind nil))
                       (multiple-value-setq (target-index definition-cst locator-kind)
                         (exact-or-nearby-class-definition forms class-name offset))
                       (if (null target-index)
                           (html-and-references
                            (compact-source-fallback class pathname locator-kind))
                           (ecase mode
                             (:definition
                              (if definition-cst
                                  (progn
                                    (source-log :class-source/excerpt
                                                :class class-name
                                                :mode mode
                                                :pathname (namestring pathname)
                                                :offset offset
                                                :locator-kind locator-kind
                                                :target-index target-index
                                                :indices (list target-index)
                                                :line-count (cst-line-count code definition-cst)
                                                :character-count (cst-character-count code definition-cst)
                                                :truncated? nil)
                                    (html-and-references
                                     (single-cst-metadata-bar pathname locator-kind code definition-cst)
                                     (render-cst-as-html code definition-cst)))
                                  (progn
                                    (source-log :class-source/excerpt
                                                :class class-name
                                                :mode mode
                                                :pathname (namestring pathname)
                                                :offset offset
                                                :locator-kind locator-kind
                                                :target-index target-index
                                                :indices (list target-index)
                                                :line-count (form-line-count code target-index)
                                                :character-count (form-character-count code target-index)
                                                :truncated? nil)
                                    (html-and-references
                                     (source-metadata-bar pathname locator-kind (list target-index) nil)
                                     (render-form-indices-as-html code (list target-index))))))
                             (:context
                              (let* ((raw-indices (context-form-indices code forms
                                                                        target-index
                                                                        class-name))
                                     (indices (capped-context-indices code raw-indices))
                                     (truncated? (< (length indices) (length raw-indices))))
                                (source-log :class-source/excerpt
                                            :class class-name
                                            :mode mode
                                            :pathname (namestring pathname)
                                            :offset offset
                                            :locator-kind locator-kind
                                            :target-index target-index
                                            :indices indices
                                            :line-count (reduce #'+ indices
                                                                :key (lambda (index)
                                                                       (form-line-count code index))
                                                                :initial-value 0)
                                            :character-count (reduce #'+ indices
                                                                     :key (lambda (index)
                                                                            (form-character-count code index))
                                                                     :initial-value 0)
                                            :truncated? truncated?)
                                (html-and-references
                                 (source-metadata-bar pathname locator-kind indices truncated?)
                                 (render-form-indices-as-html code indices)))))))))
                (source-log :class-source/render
                            :class class-name
                            :mode mode
                            :pathname (and pathname (namestring pathname))
                            :offset offset
                            :html-length (length html)
                            :html-node-count (count #\< html)
                            :reference-count (length references)
                            :asset-count (length assets)
                            :ms (clog-moldable-inspector::elapsed-millis render-start))
                (setf (gethash cache-key *class-source-render-cache*)
                      (list html references assets))
                (values html references assets))))))))

(defun class-source-html-view (class &key (mode :definition) (title "Source code") (priority 9))
  (let ((view (make-html-view (thunk (cached-class-source-render class mode))
                              :title title
                              :priority priority)))
    (setf (view-object view) class)
    view))

(defun class-overview-rows (class)
  (list (cons "Class"
              (let ((name (class-name class)))
                (if name
                    (with-standard-io-syntax
                      (let ((*package* (find-package 'common-lisp)))
                        (prin1-to-string name)))
                    "<anonymous-class>")))
        (cons "Metaclass"
              (let ((meta (class-of class)))
                (or (and (class-name meta) (string-downcase (symbol-name (class-name meta))))
                    (princ-to-string (type-of meta)))))
        (cons "Direct superclasses"
              (length (c2mop:class-direct-superclasses class)))
        (cons "Direct subclasses"
              (length (c2mop:class-direct-subclasses class)))
        (cons "Finalized?"
              (if (c2mop:class-finalized-p class) "yes" "no"))))

(defview 👀overview (class class)
  (html-view :title "Overview" :priority 1
             (html
              (:table :class "inspector-table"
                      (loop for (label . value) in (class-overview-rows class)
                            do (html
                                (:tr (:th (esc label))
                                     (:td (esc (princ-to-string value))))))))))

(defview 👀source (class class)
  (class-source-html-view class :mode :definition :title "Source code" :priority 9))

(defview 👀source-context (class class)
  (class-source-html-view class :mode :context :title "Source context" :priority 10))

(defview 👀slots (class class)
  (when (c2mop:class-finalized-p class)
    (list-view (thunk (c2mop:class-slots class))
               :title "Slots"
               :priority 2)))

(defview 👀superclasses (class class)
  (when (c2mop:class-direct-superclasses class)
    (-> (thunk (cons nil (cdr (superclass-tree class))))
        tree-view
        (rename :title "Superclasses"
                :priority 5))))

(defview 👀subclasses (class class)
  (when (c2mop:class-direct-subclasses class)
    (-> (thunk (cons nil (cdr (subclass-tree class))))
        tree-view
        (rename :title "Subclasses"
                :priority 6))))

(defview 👀specializing-methods (class class)
  (html-view :title "Methods" :priority 8
             (let ((specializers (let ((methods (find-specializers class)))
                                   (and methods
                                        (sort methods #'string<
                                              :key #'text-representation)))))
               (if specializers
                   (html
                    (:small :class "inspector-index"
                            (fmt "~a item(s)" (length specializers)))
                    (html-table specializers :display (list #'text-representation)))
                   (html
                    (:small :class "inspector-index"
                            (esc "No specializing methods found.")))))))
