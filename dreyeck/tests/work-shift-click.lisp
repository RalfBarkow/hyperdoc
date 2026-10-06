;;;; Shift-click Is Pane Policy: the reading's claims, and Shift through the pinned handler.
(defpackage #:dreyeck/work/shift-click/tests
  (:use #:cl)
  (:local-nicknames (#:sc #:dreyeck/work/shift-click)
                    (#:r #:dreyeck/work/trails-rendered-reading)
                    (#:m #:dreyeck/inspector/topicmap)
                    (#:tm #:dreyeck/topicmap)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:views #:html-inspector-views)
                    (#:cmi #:clog-moldable-inspector))
  (:export #:run-tests))
(in-package #:dreyeck/work/shift-click/tests)

(defparameter +point-a+ "fedwiki:jan.voices.ustawi.wiki/john-dewey")

;;; The pinned click handler, without a browser
;;;
;;; SET-EVENT-HANDLERS runs unchanged on a context's own view references. A
;;; CAPTURED-ELEMENT keeps the handler it installs instead of sending it to a
;;; page. The element's browser calls are the gesture test element's no-ops, and
;;; DESTROY is only recorded. The real CLOSE-PANES-AFTER runs. CREATE-PANE is
;;; recorded instead of building DOM, and REFRESH would be recorded as well.

(defclass captured-element (dreyeck/topicmap/gesture/tests::test-element) ())

(defvar *handlers*)

(defmethod clog:attach-as-child ((element captured-element) html-id &key clog-type new-id)
  (declare (ignore clog-type new-id))
  (make-instance 'captured-element :html-id html-id :connection-id "shift-click-test"))

(defmethod clog:set-on-mouse-click ((element captured-element) handler &key one-time cancel-event)
  (declare (ignore one-time cancel-event))
  (setf (gethash (clog:html-id element) *handlers*) (cons element handler)))

(defmethod clog:destroy ((element captured-element))
  nil)

(defun %element (name)
  (make-instance 'captured-element :html-id (symbol-name (gensym name)) :connection-id "shift-click-test"))

(defun %pane (inspector object)
  (let ((pane (make-instance 'cmi::pane :inspector inspector :object object)))
    (setf (cmi::clog-obj pane) (%element "pane-"))
    (cmi::add-pane inspector pane)
    pane))

(defparameter +plain+ "10:10:0:0:1:false:false:false:false:10:10:10:10"
  "A click as CLOG's mouse-event script reports it: no modifier.")
(defparameter +shift+ "10:10:0:0:1:false:false:true:false:10:10:10:10")
(defparameter +alt+ "10:10:0:0:1:true:false:false:false:10:10:10:10")

(defun %reference (view kind sign-id)
  "The reference a click lands on. :SIGN is the followable Topic's eval- sign,
:INSPECT the view's first inspect- reference and :ACTION its first relation
endpoint, an action- reference that only moves Point."
  (let ((references (views:view-references view)))
    (ecase kind
      (:sign (assoc sign-id references :test #'equal))
      (:inspect (find-if (lambda (entry) (uiop:string-prefix-p "inspect-" (car entry))) references))
      (:action (find-if (lambda (entry)
                          (and (uiop:string-prefix-p "action-" (car entry))
                               (typep (cdr entry) 'r::context-point-action)))
                        references)))))

(defun %click (data &optional (kind :sign))
  "One click with CLOG's mouse-event DATA on a fresh federated context: Point at
Jan / John Dewey, its pane followed by one trailing pane. The click goes through
the handler that the pinned SET-EVENT-HANDLERS installs for the reference."
  (let ((context (r:federated-context))
        (closed 0) (refreshed 0) (opened nil) (operations nil))
    (multiple-value-bind (sign occurrence view sign-id)
        (sc:context-sign-reference context sc:+followable-topic+)
      (declare (ignore sign))
      (let* ((workspace (r::context-current-workspace context))
             (inspector (make-instance 'cmi::inspector :clog-obj (%element "inspector-")
                                                       :pane-width "600px" :playground? nil))
             (source (%pane inspector context))
             (trailing (%pane inspector "trailing pane"))
             (entry (%reference view kind sign-id))
             (before (tm:topicmap-workspace-point-of workspace))
             (*handlers* (make-hash-table :test 'equal)))
        (assert entry () "No ~S reference in the context's Topicmap view." kind)
        (cmi::set-event-handlers source (%element "view-") (views:view-references view))
        (sb-int:encapsulate 'cmi::close-panes-after 'shift-click-test
                            (lambda (function &rest arguments) (incf closed) (apply function arguments)))
        (sb-int:encapsulate 'cmi::create-pane 'shift-click-test
                            (lambda (function inspector object &rest arguments)
                              (declare (ignore function arguments))
                              (push (cons object (mapcar #'cmi::pane-object
                                                         (fset:convert 'list (cmi::inspector-panes inspector))))
                                    opened)
                              nil))
        (sb-int:encapsulate 'cmi::refresh 'shift-click-test
                            (lambda (function pane) (declare (ignore function pane)) (incf refreshed)))
        (sb-int:encapsulate 'm:operation-inspectable-object 'shift-click-test
                            (lambda (function operation target)
                              (push operation operations)
                              (funcall function operation target)))
        (unwind-protect
             (destructuring-bind (element . handler) (gethash (car entry) *handlers*)
               (funcall handler element (clog::parse-mouse-event data)))
          (dolist (name '(cmi::close-panes-after cmi::create-pane cmi::refresh m:operation-inspectable-object))
            (sb-int:unencapsulate name 'shift-click-test)))
        (assert (<= (length opened) 1))
        (list :closed closed :refreshed refreshed
              :opened (car (first opened))
              :panes-at-open (and opened
                                  (mapcar (lambda (object)
                                            (cond ((eq object context) :source)
                                                  ((eq object (cmi::pane-object trailing)) :trailing)
                                                  (t object)))
                                          (cdr (first opened))))
              :target (cdr entry)
              :represented-object (m:occurrence-inspectable-object occurrence)
              :operations operations
              :point-before before
              :point-after (tm:topicmap-workspace-point-of workspace)
              :history (copy-list (tm:topicmap-workspace-history-of workspace)))))))

(defun check-shift-pane-policy ()
  "Shift-PRIMARY on a followable sign differs from PRIMARY only in the panes to the
right. Alt is the control: the same harness sees a modifier that changes the result."
  (let ((plain (%click +plain+))
        (shift (%click +shift+))
        (alt (%click +alt+)))
    (assert (= 1 (getf plain :closed)))
    (assert (= 0 (getf shift :closed)))
    (assert (equal '(:source) (getf plain :panes-at-open)))
    (assert (equal '(:source :trailing) (getf shift :panes-at-open)))
    (dolist (run (list plain shift))
      (assert (equal +point-a+ (getf run :point-before)))
      (assert (equal sc:+followable-topic+ (getf run :point-after)))
      (assert (equal (list +point-a+) (getf run :history)))
      (assert (equal (list (w:follow-operation)) (getf run :operations)))
      (assert (eq (getf run :represented-object) (getf run :opened)))
      (assert (zerop (getf run :refreshed))))
    (assert (= 1 (getf alt :closed)))
    (assert (eq (getf alt :target) (getf alt :opened)))
    (assert (null (getf alt :operations)))
    (assert (equal +point-a+ (getf alt :point-after)))
    (assert (null (getf alt :history))))
  (let ((plain (%click +plain+ :inspect))
        (shift (%click +shift+ :inspect)))
    (assert (= 1 (getf plain :closed)))
    (assert (= 0 (getf shift :closed)))
    (dolist (run (list plain shift))
      (assert (eq (getf run :target) (getf run :opened)))
      (assert (equal +point-a+ (getf run :point-after)))))
  (let ((plain (%click +plain+ :action))
        (shift (%click +shift+ :action)))
    (dolist (run (list plain shift))
      (assert (zerop (getf run :closed)))
      (assert (null (getf run :opened)))
      (assert (zerop (getf run :refreshed)))
      (assert (null (getf run :operations)))
      (assert (not (equal +point-a+ (getf run :point-after))))
      (assert (equal (list +point-a+) (getf run :history))))
    (assert (equal (getf plain :point-after) (getf shift :point-after))))
  t)

;;; The reading

(defun %squeeze (text)
  (format nil "~{~A~^ ~}" (remove "" (uiop:split-string text :separator '(#\Space #\Newline #\Tab))
                                  :test #'string=)))

(defun %content (page)
  (let ((view (find "Content" (views:all-views page) :key #'views:view-title :test #'equal)))
    (values (views:view-html view) (views:view-references view))))

(defun %thunks (view)
  (views:view-html view)
  (remove-if-not (lambda (entry) (typep (cdr entry) 'views:thunk)) (views:view-references view)))

(defun %sha256 (text)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets text :external-format :utf-8))))

(defun check-pages ()
  "The page and its Code Page load. Every link and transclusion resolves to the
object it names, and the three examples are the page's only run widgets."
  (let* ((book (hyperbook:find-hyperbook "dreyeck/work/reading" :signal-error? t))
         (page (hyperbook:find-page book "Shift-click Is Pane Policy" :signal-error? t))
         (code (hyperbook:find-page book "Shift-click Evidence" :signal-error? t)))
    (assert (typep page 'hyperdoc::html-page))
    (assert (typep code 'hyperdoc::code-page))
    (assert (find book (hyperbook:hyperbooks-of hyperbook:*catalog*) :test #'eq))
    (multiple-value-bind (html entries) (%content page)
      (let ((references (mapcar #'cdr entries))
            (text (%squeeze html)))
        (assert (notany (lambda (reference) (typep reference 'condition)) references))
        (dolist (object (list #'clog-moldable-inspector::set-event-handlers
                              #'clog-moldable-inspector::close-panes-after
                              (sc:primary-composition) (w:follow-operation)
                              #'r::follow-context-object #'r::context-topic-primary-reference
                              #'m::%show-topic-selection #'m::%open-beside
                              (find-class 'w:gesture-input-sample) (find-class 'w:gesture-binding)
                              (sc:mech-excerpt :solo) (sc:mech-excerpt :report)
                              (hyperbook:find-page book "Interaction" :signal-error? t)
                              (hyperbook:find-page book "Work Breakdown" :signal-error? t)))
          (assert (member object references :test #'eq) () "The page does not refer to ~S." object))
        (assert (find-if (lambda (reference)
                           (and (typep reference 'tm:topicmap-workspace)
                                (equal "shift-click" (tm:topicmap-workspace-point-of reference))))
                         references))
        (let* ((widgets (remove-if-not (lambda (reference) (typep reference 'views:view)) references))
               (runs (mapcan (lambda (widget) (mapcar #'cdr (%thunks widget))) widgets))
               (excerpts (remove-if-not (lambda (widget) (equal "Pinned Mech source" (views:view-title widget)))
                                        widgets)))
          (assert (= 5 (length widgets)))
          (assert (= 2 (length excerpts)))
          (assert (= 3 (length runs)))
          ;; Run the page's own widgets, not only the functions behind them.
          (let ((results (mapcar #'views:eval-thunk runs)))
            (assert (= 3 (count-if #'consp results)))
            (assert (find-if (lambda (result) (getf result :bindings-reference-it)) results))
            (assert (find-if (lambda (result) (getf result :result-is-represented-object)) results))
            (assert (find-if (lambda (result) (getf result :same-binding)) results))))
        (dolist (phrase '("does not select an operation"
                          "(unless (getf event :shift-key) (close-panes-after inspector pane))"
                          "His current, unpublished implementation was not inspected"
                          "Interpretation, not observation"
                          "this reading does not add one"
                          "Nothing in this reading changes it"))
          (assert (search phrase text) () "The page does not say ~S." phrase))))
    ;; Interaction, the closest Work page on PRIMARY and SECONDARY, leads here.
    (assert (member page (mapcar #'cdr (nth-value 1 (%content (hyperbook:find-page book "Interaction"
                                                                                   :signal-error? t))))))
    ;; The Code Page leads back to the page. Its links are read when it loads.
    (hyperdoc:load-page code)
    (assert (find "Shift-click Is Pane Policy" (hyperbook::page-links-of (hyperbook:links-of code))
                  :key #'hyperbook::target-page-of :test #'equal)))
  t)

(defun check-examples ()
  (let ((identity (sc:follow-identity)))
    (assert (eq (w:follow-operation) (getf identity :operation)))
    (assert (getf identity :bindings-reference-it))
    (dolist (kind '(:radial-menu :learned-mark))
      (assert (eq (w:follow-operation) (w:gesture-binding-operation (getf identity kind)))))
    (assert (eq (sc:primary-composition) (getf identity :primary-composition))))
  (let ((activation (sc:topic-primary-activation)))
    (assert (equal +point-a+ (getf activation :point-before)))
    (assert (equal sc:+followable-topic+ (getf activation :point-after)))
    (assert (equal (list +point-a+) (getf activation :history)))
    (assert (equal (list sc:+followable-topic+) (getf activation :point-presented)))
    (assert (getf activation :result-is-represented-object))
    (assert (typep (getf activation :follow-result) 'hyperbook/fedwiki::fedwiki-page))
    (assert (eq (getf activation :target-topic)
                (m:occurrence-topic (getf (getf activation :follow-target) :occurrence)))))
  (let* ((transport (sc:secondary-modifier-transport))
         (plain (getf transport :without-shift))
         (shift (getf transport :with-shift))
         (sample-slots (mapcar #'sb-mop:slot-definition-name
                               (sb-mop:class-slots (find-class 'w:gesture-input-sample)))))
    (assert (= 4 (length (getf plain :modifiers)) (length (getf shift :modifiers))))
    (assert (every #'null (getf plain :modifiers)))
    (assert (every (lambda (modifiers) (equal '(:shift) modifiers)) (getf shift :modifiers)))
    (assert (equal "binding/learned-mark-follow" (w:gesture-binding-id (getf shift :binding))))
    (assert (eq (w:follow-operation) (getf shift :operation)))
    (assert (getf transport :same-binding))
    (assert (getf transport :same-operation))
    ;; The sample has a modifier slot, so this search can find one; the Binding has none.
    (assert (find "MODIFIERS" sample-slots :key #'symbol-name :test #'string=))
    (assert (notany (lambda (slot) (search "MODIFIER" (symbol-name slot)))
                    (getf transport :gesture-binding-slots))))
  t)

(defun check-topicmap ()
  "Each Topic is the object it names. Every Association resolves, with a status
other dreyeck Topicmaps use and a warrant. Only the handler reads Shift-click, the
sample carries it and Mech is only compared with it."
  (let* ((workspace (sc:shift-click-topicmap))
         (projection (tm:topicmap-workspace-projection-of workspace))
         (topics (tm:topicmap-projection-topics-of projection))
         (associations (tm:topicmap-projection-associations-of projection))
         (ids (mapcar #'tm:topicmap-topic-id-of topics))
         (bindings r::*context-topic-follow-bindings*))
    (flet ((object (id) (tm:topicmap-topic-object-of (tm:topicmap-projection-topic-by-id projection id)))
           (ends (id) (loop for association in associations
                            when (string= id (tm:topicmap-association-to-of association))
                              collect (list (tm:topicmap-association-type-of association)
                                            (tm:topicmap-association-from-of association)))))
      (assert (= 15 (length ids) (length (remove-duplicates ids :test #'string=))))
      (dolist (association associations)
        (let ((properties (tm:topicmap-association-properties-of association)))
          (assert (member (tm:topicmap-association-from-of association) ids :test #'string=))
          (assert (member (tm:topicmap-association-to-of association) ids :test #'string=))
          (assert (member (getf properties :epistemic-status)
                          '(:source-observed :directly-observed :design-inference)))
          (assert (stringp (getf properties :warrant)))
          (assert (member (tm:topicmap-association-type-of association)
                          '(:reads :calls :references :selects :contains :conceptual-comparison)))))
      (loop for (id expected)
              in (list (list "set-event-handlers" #'clog-moldable-inspector::set-event-handlers)
                       (list "close-panes-after" #'clog-moldable-inspector::close-panes-after)
                       (list "topic-primary" (sc:primary-composition))
                       (list "topicmap-workspace-go-to" #'tm:topicmap-workspace-go-to)
                       (list "operation/follow" (w:follow-operation))
                       (list "binding/learned-mark-follow" (find :learned-mark bindings :key #'w:gesture-binding-kind))
                       (list "binding/radial-menu-follow" (find :radial-menu bindings :key #'w:gesture-binding-kind))
                       (list "gesture-input-sample" (find-class 'w:gesture-input-sample))
                       (list "run-gesture-trace" #'w:run-gesture-trace)
                       (list "topic-secondary" #'m::%show-topic-selection)
                       (list "workspace-action-sign-occurrence" (find-class 'm:workspace-action-sign-occurrence))
                       (list "%open-beside" #'m::%open-beside)
                       (list "mech-click" (sc:mech-excerpt :click))
                       (list "mech-inspect" (sc:mech-excerpt :inspect)))
            do (assert expected () "~A has no object to compare." id)
               (assert (eq expected (object id)) () "~A does not carry its object." id))
      (assert (null (object "shift-click")))
      ;; A Binding Topic's ID is the Binding's own.
      (dolist (id '("binding/learned-mark-follow" "binding/radial-menu-follow"))
        (assert (equal id (w:gesture-binding-id (object id)))))
      (assert (equal '((:contains "gesture-input-sample") (:reads "set-event-handlers"))
                     (sort (ends "shift-click") #'string< :key (lambda (end) (symbol-name (first end))))))
      (assert (equal '((:references "topic-primary") (:references "binding/learned-mark-follow")
                       (:references "binding/radial-menu-follow"))
                     (ends "operation/follow")))
      (assert (equal '((:calls "set-event-handlers") (:calls "%open-beside")) (ends "close-panes-after")))
      ;; The one interpreted relation compares the two readers of Shift, the
      ;; Inspector's handler and Mech's CLICK; it is not a relation of the modifier.
      (assert (equal '(("set-event-handlers" "mech-click" :design-inference))
                     (loop for association in associations
                           when (eq :conceptual-comparison (tm:topicmap-association-type-of association))
                             collect (list (tm:topicmap-association-from-of association)
                                           (tm:topicmap-association-to-of association)
                                           (getf (tm:topicmap-association-properties-of association)
                                                 :epistemic-status)))))
      (assert (equal "shift-click" (tm:topicmap-workspace-point-of workspace)))
      (let ((view (find "Topicmap" (views:all-views workspace) :key #'views:view-title :test #'equal)))
        (assert view)
        (let ((html (views:view-html view)))
          (dolist (id ids)
            (assert (search (format nil "data-topic-id='~A'" id) html) () "~A is not rendered." id))))))
  t)

(defun check-mech-excerpts ()
  "The excerpts carry the Trails Rendered provenance itself and are the pinned lines."
  (let ((plugin (getf (gethash :public-plugins r::*provenance*) :mech)))
    (dolist (name '(:click :inspect :solo :report))
      (let* ((excerpt (sc:mech-excerpt name))
             (text (getf excerpt :text))
             (lines (getf excerpt :lines)))
        (assert (eq plugin (getf (getf excerpt :file) :plugin)))
        (assert (equal (getf excerpt :sha256) (%sha256 text)) () "~S is not the recorded excerpt." name)
        (assert (= (- (second lines) (first lines)) (count #\Newline text)))))
    (flet ((text (name) (getf (sc:mech-excerpt name) :text)))
      (assert (search "state.debug = event.shiftKey" (text :click)))
      (assert (< (search "state.debug = event.shiftKey" (text :click)) (search "run(body, state, 'click')" (text :click))))
      (assert (search "if (state.debug) {" (text :inspect)))
      (assert (search "${key} ⇒" (text :inspect)))
      (assert (search "inspect(elem, 'aspect', state)" (text :solo)))
      (assert (search " ⇒ ${todo.length} sources, ${aspects} aspects" (text :solo)))
      (assert (search "state.api.inspect(elem, key, state)" (text :report)))))
  t)

(defun check-no-interaction-change ()
  "The reading only reads, renders and runs. Its Code Page defines no method,
generic function, encapsulation or global function replacement."
  (let ((*package* (find-package '#:dreyeck/work/shift-click))
        (heads nil))
    (with-open-file (stream (asdf:system-relative-pathname "dreyeck/work/reading" "dreyeck/work/shift-click.lisp")
                            :external-format :utf-8)
      (loop for form = (read stream nil stream)
            until (eq form stream)
            do (push (first form) heads)
               (when (eq 'in-package (first form))
                 (setf *package* (find-package (second form))))))
    (assert (subsetp heads '(defpackage in-package hyperdoc:see defparameter defun hyperdoc:defexample)))
    (assert (member 'hyperdoc:defexample heads)))
  t)

(defun run-tests ()
  (check-shift-pane-policy)
  (check-examples)
  (check-topicmap)
  (check-mech-excerpts)
  (check-no-interaction-change)
  (check-pages)
  (format t "~&SHIFT-CLICK-READING-PASS: the pinned handler skips only CLOSE-PANES-AFTER under Shift ~
for eval- and inspect- references (same Point, history, Follow identity and opened object), ~
opens nothing for action- references, and Alt changes the result; Follow is one identity for ~
PRIMARY and both Bindings; SECONDARY carries :SHIFT and selects the same Binding; the Topicmap ~
carries the objects themselves; the pinned Mech excerpts match their hashes; the reading defines no ~
interaction behaviour, and its page resolves every reference and runs its three examples.~%")
  t)
