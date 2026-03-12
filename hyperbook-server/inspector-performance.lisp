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
