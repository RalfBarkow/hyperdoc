;;;; Inspector performance overrides
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :clog-moldable-inspector)

(defvar *inspector-performance-logging* t)

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
    (loop for (key value) on kvs by #'cddr
          do (format *trace-output* " ~A=~S" key value))
    (terpri *trace-output*)
    (finish-output *trace-output*)))

(defun html-view-realized-p (view)
  (not (null (slot-value view 'html-inspector-views::html))))

(defun dom-node-count (element)
  (when (clog:connection-body element)
    (ignore-errors
      (parse-integer
       (or (clog:js-query
            element
            (format nil
                    "(function(){var el=document.getElementById(~S); return el ? String(el.querySelectorAll('*').length) : '0';})()"
                    (clog:html-id element)))
           "0")
       :junk-allowed t))))

;; Replace upstream create-pane to add timing logs while preserving the
;; original default selection behavior.
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
                                             :class "inspector-pane"
                                             :style style-attr))
      (setf (clog:attribute (clog-obj pane) "tabindex") "0")
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
      (let* ((resolved-select (or select 0))
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
  (let* ((html-start (current-time-millis))
         (html-cached? (html-view-realized-p view))
         (html (hv:view-html view))
         (references (hv:view-references view))
         (assets (hv:view-assets view))
         (html-ms (elapsed-millis html-start))
         (html-length (length html))
         (html-node-count (count #\< html))
         (insert-start (current-time-millis))
         (result (call-next-method))
         (post-insert-ms (elapsed-millis insert-start))
         (dom-nodes (dom-node-count parent-element)))
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
    result))

;; Override the local wiring once more to add timing logs for inspect clicks
;; while preserving the invalid-id guard.
(defun set-event-handlers (pane element references)
  (with-slots (object inspector clog-obj) pane
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
                        (declare (ignore obj))
                        (let ((click-start (current-time-millis)))
                          (log-inspector-performance :click/inspect
                                                     :pane-object (summarize-object-for-log object)
                                                     :target (summarize-object-for-log target)
                                                     :select view-ref
                                                     :alt? (getf event :alt-key)
                                                     :shift? (getf event :shift-key))
                          (when (getf event :alt-key)
                            (clog:jquery-trigger (clog:parent element) "click"))
                          (unless (getf event :alt-key)
                            (unless (getf event :shift-key)
                              (close-panes-after inspector pane))
                            (create-pane inspector target :select view-ref))
                          (log-inspector-performance :click/inspect-done
                                                     :target (summarize-object-for-log target)
                                                     :ms (elapsed-millis click-start))))
                    :cancel-event t)))
                ((string= ref-type "action")
                 (clog:set-on-mouse-click
                  ref-element
                  #'(lambda (obj event)
                      (if (getf event :alt-key)
                          (progn
                            (unless (getf event :shift-key)
                              (close-panes-after inspector pane))
                            (create-pane inspector target))
                          (when (eval-thunk-with-active-button clog-obj obj target)
                            (refresh pane))))
                  :cancel-event t))
                ((string= ref-type "eval")
                 (clog:set-on-mouse-click
                  ref-element
                  #'(lambda (obj event)
                      (unless (getf event :shift-key)
                        (close-panes-after inspector pane))
                      (if (getf event :alt-key)
                          (create-pane inspector target)
                          (create-pane inspector
                                       (eval-thunk-with-active-button clog-obj obj target))))
                  :cancel-event t)))))))))

(in-package #:html-inspector-views/standard)

(defun source-log (phase &rest kvs)
  (apply #'clog-moldable-inspector::log-inspector-performance phase kvs))

(defmethod parse-lisp-code :around ((input pathname) &optional package)
  (let ((start (clog-moldable-inspector::current-time-millis)))
    (prog1 (call-next-method)
      (source-log :class-source/parse
                  :pathname (namestring input)
                  :cache-hit? nil
                  :ms (clog-moldable-inspector::elapsed-millis start)))))

(defun source-html-node-count (html)
  (count #\< html))

(defun source-code-view (object &key in-file?)
  (let ((start (clog-moldable-inspector::current-time-millis)))
    (multiple-value-bind (pathname offset)
        (source-code-location object)
      (source-log :class-source/location
                  :object (or (ignore-errors (class-name object))
                              (type-of object))
                  :cache-hit? nil
                  :pathname (and pathname (namestring pathname))
                  :offset offset
                  :ms (clog-moldable-inspector::elapsed-millis start))
      (if in-file?
          (source-view pathname offset)
          (single-form-source-view pathname offset)))))

(defun render-as-html (code &key highlight-at-offset debug)
  (let ((start (clog-moldable-inspector::current-time-millis)))
    (let ((html
            (with-slots (source top-level-forms) code
              (when debug
                (html
                  (object-ref top-level-forms
                              :display #'(lambda (_) (declare (ignore _)) "Concrete syntax tree"))
                  (:hr)))
              (html
                (:pre :class "code-snippet"
                      (:code
                       (let ((position 0))
                         (dolist (toplevel top-level-forms)
                           (destructuring-bind (start . end) (cst:source (cst-of toplevel))
                             (esc (str:substring position start source))
                             (let ((highlight? (and highlight-at-offset
                                                    (>= highlight-at-offset start)
                                                    (< highlight-at-offset end)
                                                    t)))
                               (html
                                 (:lisp-toplevel :highlight highlight?
                                                 (setf position
                                                       (render-toplevel-cst nil (cst-of toplevel)
                                                                            source start)))))
                             (assert (eql position end))))
                         (esc (str:substring position nil source)))))))))
    (source-log :class-source/render
                :mode :file
                :html-length (length html)
                :html-node-count (source-html-node-count html)
                :ms (clog-moldable-inspector::elapsed-millis start))
      html)))

(defun render-one-form-as-html (code offset)
  (let ((start (clog-moldable-inspector::current-time-millis)))
    (let ((html
            (with-slots (source top-level-forms) code
              (html
                (:pre :class "code-snippet"
                      (:code
                       (dolist (toplevel top-level-forms)
                         (destructuring-bind (start . end) (cst:source (cst-of toplevel))
                           (when (and (>= offset start)
                                      (< offset end))
                             (html
                               (:lisp-toplevel (render-toplevel-cst nil (cst-of toplevel)
                                                                     source start))))))))))))
    (source-log :class-source/render
                :mode :single-form
                :offset offset
                :html-length (length html)
                :html-node-count (source-html-node-count html)
                :ms (clog-moldable-inspector::elapsed-millis start))
      html)))
