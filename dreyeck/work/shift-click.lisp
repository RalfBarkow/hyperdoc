;;;; Shift-click Evidence
;;;;
;;;; The objects behind "Shift-click Is Pane Policy". Nothing here adds
;;;; interaction behaviour. Each function reads, renders or runs existing
;;;; production code, and the Topicmap names the objects themselves. The
;;;; pinned Inspector's click handler is linked, not copied. Mech is not Lisp
;;;; and not in this repository, so its pinned source is kept as excerpts with
;;;; the provenance the Trails Rendered reading already records.

(defpackage #:dreyeck/work/shift-click
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/work/trails-rendered-reading)
                    (#:m #:dreyeck/inspector/topicmap)
                    (#:tm #:dreyeck/topicmap)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:g #:dreyeck/gesture/clog)
                    (#:tp #:dreyeck/gesture/transport)
                    (#:views #:html-inspector-views))
  (:export #:+followable-topic+ #:context-sign-reference #:primary-composition
           #:follow-identity #:topic-primary-activation #:secondary-modifier-transport
           #:mech-excerpt #:mech-excerpt-view #:shift-click-topicmap))
(in-package #:dreyeck/work/shift-click)

(hyperdoc:see (hyperdoc:page "Shift-click Is Pane Policy" :hyperbook "dreyeck/work/reading"))

;;; A followable Topic of the federated context. A fresh context has its Point
;;; at Jan / John Dewey, so activating this sign moves Point.
(defparameter +followable-topic+ "fedwiki:thompson.voices.ustawi.wiki/how-we-think")

(defun context-sign-reference (context topic-id &optional update-view)
  "TOPIC-ID's sign reference in CONTEXT's Topicmap view and its occurrence,
associated as the Inspector associates them after rendering. Returns the
reference, the occurrence, the view and the reference's id. Only the browser
element is absent, and nothing is clicked. UPDATE-VIEW is the Point
presentation callback that the Inspector supplies."
  (let* ((view (find "Topicmap" (views:all-views context) :key #'views:view-title :test #'equal))
         (entries (progn (views:view-html view)
                         (remove-if-not
                          (lambda (entry)
                            (and (uiop:string-prefix-p "eval-" (car entry))
                                 (typep (cdr entry) 'r::context-point-action)
                                 (equal topic-id (tm:topicmap-topic-id-of (m::action-topic (cdr entry))))))
                          (views:view-references view)))))
    (assert (= 1 (length entries)) () "~D EVAL sign references for ~A." (length entries) topic-id)
    (let ((occurrence (make-instance 'm:workspace-action-sign-occurrence
                                     :reference (cdar entries) :element nil :pane nil :view view)))
      (r::bind-context-point-actions view update-view (list occurrence))
      (values (cdar entries) occurrence view (caar entries)))))

(defun primary-composition ()
  "Topic PRIMARY on a followable context sign: Point, its presentation, then Follow."
  (find-method #'views:eval-thunk '(:around) (list (find-class 'r::context-point-action))))

(hyperdoc:defexample follow-identity
  "The Follow identity, the two SECONDARY Bindings that reference it, and the
PRIMARY composition whose source names it."
  (let ((bindings r::*context-topic-follow-bindings*))
    (list :operation (w:follow-operation)
          :radial-menu (find :radial-menu bindings :key #'w:gesture-binding-kind)
          :learned-mark (find :learned-mark bindings :key #'w:gesture-binding-kind)
          :bindings-reference-it
          (every (lambda (binding) (eq (w:follow-operation) (w:gesture-binding-operation binding)))
                 bindings)
          :primary-composition (primary-composition))))

(hyperdoc:defexample topic-primary-activation
  "Topic PRIMARY on Thompson / How We Think, in a fresh federated context whose
Point is Jan / John Dewey. It runs the sign reference's thunk, which is what the
Inspector's eval handler runs after deciding from Shift whether to close the
panes to the right."
  (let* ((context (r:federated-context))
         (workspace (r::context-current-workspace context))
         (before (tm:topicmap-workspace-point-of workspace))
         (presented nil))
    (multiple-value-bind (reference occurrence)
        (context-sign-reference context +followable-topic+
                                (lambda () (push (tm:topicmap-workspace-point-of workspace) presented)))
      (let ((result (views:eval-thunk reference))
            (object (m:occurrence-inspectable-object occurrence)))
        (list :target-topic (m:occurrence-topic occurrence)
              :represented-object object
              :point-before before
              :point-after (tm:topicmap-workspace-point-of workspace)
              :history (copy-list (tm:topicmap-workspace-history-of workspace))
              :point-presented (reverse presented)
              :composition (primary-composition)
              :follow-operation (w:follow-operation)
              :follow-target (r::point-action-operation-target reference)
              :follow-result result
              :result-is-represented-object (eq result object))))))

(defun %forwarded (kind y buttons sequence shift)
  "One event as a sign's gesture script forwards it: KIND|TRUST|CLOG pointer fields."
  (format nil "~A|untrusted|100:~D:0:0:~D:false:false:~:[false~;true~]:false:100:~D:100:~D:~D:~D"
          kind y (if (member kind '("pointerdown" "pointerup") :test #'string=) 3 0)
          shift y y buttons sequence))

(defun %follow-mark (occurrence shift)
  "A learned mark straight down, at 90 degrees in Follow's sector, on OCCURRENCE. It
is fed through the production transport into a window holding OCCURRENCE's own
Bindings, then recognized and selected but never executed: the window has no
projection."
  (let ((window (g:make-gesture-window :bindings (m:workspace-action-sign-bindings occurrence)))
        (target (list :type :workspace-action-sign-occurrence :occurrence occurrence)))
    (loop for (kind y buttons) in '(("pointerdown" 100 2) ("pointermove" 140 2)
                                    ("pointermove" 180 2) ("pointerup" 180 0))
          for sequence from 1
          do (m::%forward-topic-gesture window target (%forwarded kind y buttons sequence shift)))
    (let ((binding (g:gesture-window-selection window)))
      (list :modifiers (mapcar #'w:gesture-input-sample-modifiers
                               (reverse (tp:input-session-prefix
                                         (tp:witness-input (g:gesture-window-witness window)))))
            :binding binding
            :operation (and binding (w:gesture-binding-operation binding))))))

(hyperdoc:defexample secondary-modifier-transport
  "The same learned Follow mark on Thompson / How We Think, made without and with
Shift. The transport carries :SHIFT into every sample, and the reducer selects
the same Binding and Operation either way, since a GESTURE-BINDING has no
modifier slot."
  (let* ((occurrence (nth-value 1 (context-sign-reference (r:federated-context) +followable-topic+)))
         (plain (%follow-mark occurrence nil))
         (shift (%follow-mark occurrence t)))
    (list :without-shift plain
          :with-shift shift
          :same-binding (eq (getf plain :binding) (getf shift :binding))
          :same-operation (eq (getf plain :operation) (getf shift :operation))
          :gesture-binding-slots (mapcar #'sb-mop:slot-definition-name
                                         (sb-mop:class-slots (find-class 'w:gesture-binding))))))

;;; Mech's Shift-click, from its pinned source
;;;
;;; The revision is the one the Trails Rendered reading already records for
;;; MECH; the excerpts were read from that revision's file. Ward's current,
;;; unpublished implementation, shown in his screenshot, is not represented.

(defparameter +mech-file+
  (list :plugin (getf (gethash :public-plugins r::*provenance*) :mech)
        :path "src/client/blocks.js"
        :sha256 "388ee024299ce3674c607b83ec671f8d3df0cb9ba9e584960768fd359fff6d9d"
        :read-by "git show at the revision under :PLUGIN, in a clean clone of its public repository, 2026-10-06"
        :not-read "Ward's current Mech, reported with a screenshot; unpublished and not inspected"))

(defparameter +mech-excerpts+
  (list
   (list :name :click :file +mech-file+ :lines '(245 252)
         :sha256 "061ebbb743d0dc971c260a7b1396cc4037973bd667b8c054df95448b3654af08"
         :text "function click_emit({ elem, body, state }) {
  if (!body?.length) return state.api.trouble(elem, `CLICK expects indented blocks to follow.`)
  state.api.button(elem, '▶', event => {
    state.api.reset(elem)
    state.debug = event.shiftKey
    run(body, state, 'click')
  })
}")
   (list :name :inspect :file +mech-file+ :lines '(42 66)
         :sha256 "5928a2d918ccd1ad54cd04b317bc0f707a5f2ee3e624df43ef1b2d1767006059"
         :text "export function inspect(elem, key, state) {
  const div = elem.previousElementSibling
  if (state.debug) {
    elem['sample-' + key] = state[key] // proper lifetime and indirection
    let look = div.querySelector(`.look[data-key=\"${key}\"]`)
    if (!look) {
      look = document.createElement('div')
      look.classList.add('look')
      look.dataset.key = key
      look.innerHTML = `<font color=gray size=small>${key} ⇒</font>`
      div.insertAdjacentElement('beforeend', look)
      look.querySelector('font').addEventListener('click', event => {
        let see = look.querySelector('.see')
        if (!see) {
          see = document.createElement('div')
          see.classList.add('see')
          look.insertAdjacentElement('beforeend', see)
          see.innerText = JSON.stringify(elem['sample-' + key]).substring(0, 400) + ' ...'
        } else {
          see.remove()
        }
      })
    }
  }
}")
   (list :name :solo :file +mech-file+ :lines '(930 941)
         :sha256 "4099c6978acfad3af153d0f57ef33bbb7f804fe65179fe9ecfb7c27925840e88"
         :text "async function solo_emit({ elem, command, state }) {
  if (!('aspect' in state)) return state.api.trouble(elem, `\"SOLO\" expects \"aspect\" state, like from \"WALK\".`)
  inspect(elem, 'aspect', state)
  // elem.innerHTML = command
  state.api.status(elem, command, '')
  const todo = state.aspect.map(each => ({
    source: each.source || each.id,
    aspects: each.result,
  }))
  const aspects = todo.reduce((sum, each) => sum + each.aspects.length, 0)
  // elem.innerHTML += ` ⇒ ${todo.length} sources, ${aspects} aspects`
  state.api.status(elem, command, ` ⇒ ${todo.length} sources, ${aspects} aspects`)")
   (list :name :report :file +mech-file+ :lines '(305 314)
         :sha256 "6c4d896484220440dd9e7d5e51ba24a652643fbefd4d7cc39b90a7bd7d5fd1f0"
         :text "function report_emit({ elem, command, args, state }) {
  const key = args[0] || 'temperature'
  if (!(key in state)) return state.api.trouble(elem, `Expect \"${key}\" in state`)
  const value = state[key]
  const type = typeof value
  if (!['string', 'number'].includes(type))
    return state.api.trouble(elem, `Expect state.${key} to be a string or number`)
  state.api.inspect(elem, key, state)
  state.api.report(elem, command, `<div class=report>${value}</div>`)
}"))
  "Pinned lines of Mech's blocks.js, each read from the file under +MECH-FILE+.")

(defun mech-excerpt (name)
  (or (find name +mech-excerpts+ :key (lambda (excerpt) (getf excerpt :name)))
      (error "No pinned Mech excerpt ~S." name)))

(defun mech-excerpt-view (name)
  "One pinned Mech excerpt, to transclude: where it comes from, then its lines."
  (let* ((excerpt (mech-excerpt name))
         (file (getf excerpt :file))
         (plugin (getf file :plugin)))
    (views:html-view :title "Pinned Mech source" :priority 0
      (views:html
        (:p (views:esc (format nil "~A at ~A, ~A lines ~{~D–~D~} [excerpt SHA-256 ~A]"
                               (getf plugin :repository) (subseq (getf plugin :revision) 0 8)
                               (getf file :path) (getf excerpt :lines) (getf excerpt :sha256))))
        (:pre (views:esc (getf excerpt :text)))))))

;;; The reading as a Topicmap. Each Topic is the object it names, and Shift-click
;;; is the one concept with no Lisp object. The relation types and epistemic
;;; statuses are ones other dreyeck Topicmaps already use. The initial Point is
;;; Shift-click, so its reader and its carrier are the first associations a
;;; reader sees. The coordinates are authored here; no layout is derived.

(defun shift-click-topicmap ()
  (flet ((topic (id label type kind object x y)
           (tm:make-topicmap-topic :id id :type type :label label :object object
                                   :view-properties (list :x x :y y :visible t :kind kind))))
    (let* ((bindings r::*context-topic-follow-bindings*)
           (topics
             (list (topic "shift-click" "Shift-click" :concept "browser input modifier" nil 690 340)
                   (topic "set-event-handlers" "Inspector click handler" :lisp-function
                          "pinned Inspector function" #'clog-moldable-inspector::set-event-handlers 430 340)
                   (topic "topic-primary" "Topic PRIMARY" :lisp-method "make current, then Follow"
                          (primary-composition) 170 340)
                   (topic "topicmap-workspace-go-to" "Workspace Point (GO-TO)" :lisp-function
                          "Point movement" #'tm:topicmap-workspace-go-to 170 190)
                   (topic "operation/follow" "Follow" :opaque-operation-identity
                          "semantic operation identity" (w:follow-operation) 170 490)
                   (topic "close-panes-after" "CLOSE-PANES-AFTER" :lisp-generic-function
                          "pinned Inspector pane policy" #'clog-moldable-inspector::close-panes-after 430 640)
                   (topic "binding/learned-mark-follow" "Learned-mark Binding" :binding "SECONDARY invocation"
                          (find :learned-mark bindings :key #'w:gesture-binding-kind) 690 490)
                   (topic "binding/radial-menu-follow" "Radial-menu Binding" :binding "SECONDARY invocation"
                          (find :radial-menu bindings :key #'w:gesture-binding-kind) 950 640)
                   (topic "gesture-input-sample" "GESTURE-INPUT-SAMPLE" :lisp-class "transient input record"
                          (find-class 'w:gesture-input-sample) 950 340)
                   (topic "run-gesture-trace" "RUN-GESTURE-TRACE" :lisp-function "gesture reducer"
                          #'w:run-gesture-trace 1210 340)
                   (topic "topic-secondary" "Topic SECONDARY" :lisp-function "after a completed gesture"
                          #'m::%show-topic-selection 1470 340)
                   (topic "workspace-action-sign-occurrence" "Gesture target" :lisp-class "transient target"
                          (find-class 'm:workspace-action-sign-occurrence) 1470 190)
                   (topic "%open-beside" "%OPEN-BESIDE" :lisp-function "SECONDARY pane opening"
                          #'m::%open-beside 1470 490)
                   (topic "mech-click" "Mech CLICK, a028b4bb" :source "pinned Mech excerpt"
                          (mech-excerpt :click) 690 40)
                   (topic "mech-inspect" "Mech inspect, a028b4bb" :source "pinned Mech excerpt"
                          (mech-excerpt :inspect) 950 40)))
           (associations
             (loop for (id from to type status warrant)
                     in '(("reads-shift" "set-event-handlers" "shift-click" :reads :directly-observed
                           "Its inspect- and eval- branches read :SHIFT-KEY from CLOG's parsed mouse event. The Shift regression runs the pinned handler.")
                          ("closes-unless-shift" "set-event-handlers" "close-panes-after" :calls :directly-observed
                           "(unless (getf event :shift-key) (close-panes-after inspector pane)), before the reference runs. Regression: one call without Shift, none with it. A plain action- reference never calls it.")
                          ("runs-primary" "set-event-handlers" "topic-primary" :calls :directly-observed
                           "The eval- branch hands a followable context sign's reference to EVAL-THUNK-WITH-ACTIVE-BUTTON, which dispatches to this method. Regression: the same Follow and result with and without Shift.")
                          ("moves-point" "topic-primary" "topicmap-workspace-go-to" :calls :directly-observed
                           "CALL-NEXT-METHOD runs the sign's thunk, which calls TOPICMAP-WORKSPACE-GO-TO: Point A to B, history (A). See TOPIC-PRIMARY-ACTIVATION.")
                          ("primary-follows" "topic-primary" "operation/follow" :references :directly-observed
                           "After Point and its presentation, the method passes this identity and the sign's occurrence to OPERATION-INSPECTABLE-OBJECT. The federated-context Topic-operations test records it EQ.")
                          ("mark-follows" "binding/learned-mark-follow" "operation/follow" :references :directly-observed
                           "GESTURE-BINDING-OPERATION is EQ to it; see FOLLOW-IDENTITY.")
                          ("radial-follows" "binding/radial-menu-follow" "operation/follow" :references :directly-observed
                           "GESTURE-BINDING-OPERATION is EQ to it; see FOLLOW-IDENTITY.")
                          ("reducer-reads-samples" "run-gesture-trace" "gesture-input-sample" :reads :source-observed
                           "It reads each sample's kind, button and coordinates. No selection or execution code reads a sample's MODIFIERS.")
                          ("reducer-selects-mark" "run-gesture-trace" "binding/learned-mark-follow" :selects :directly-observed
                           "This is the learned-mark path. SECONDARY-MODIFIER-TRANSPORT shows it selecting this Binding with and without :SHIFT.")
                          ("reducer-selects-radial" "run-gesture-trace" "binding/radial-menu-follow" :selects :source-observed
                           "This is the visible-menu path. %BINDING-AT matches kind, target type and sector, and GESTURE-BINDING has no modifier slot.")
                          ("secondary-reads-selection" "topic-secondary" "run-gesture-trace" :reads :source-observed
                           "WORKSPACE-ACTION-SIGN-SELECTED-OBJECT reads GESTURE-WINDOW-SELECTION, the Binding the reduced gesture completed with.")
                          ("secondary-target" "topic-secondary" "workspace-action-sign-occurrence" :reads :directly-observed
                           "The selection's target carries the exact occurrence. Workspace Point stays where it was: the federated-context Topic-operations test checks Point, history and time.")
                          ("secondary-opens-beside" "topic-secondary" "%open-beside" :calls :source-observed
                           "Opens what the Operation shows beside the occurrence's pane. A refusal opens nothing.")
                          ("beside-closes" "%open-beside" "close-panes-after" :calls :source-observed
                           "Unconditionally. No click event reaches %OPEN-BESIDE, so Shift cannot keep the panes to the right here.")
                          ("sample-carries-shift" "gesture-input-sample" "shift-click" :contains :directly-observed
                           "%ENVELOPE-FROM puts :SHIFT into MODIFIERS when the forwarded event's shiftKey is true. SECONDARY-MODIFIER-TRANSPORT shows it in every sample.")
                          ("compared-with-mech" "set-event-handlers" "mech-click" :conceptual-comparison :design-inference
                           "Compared, not identical. Both read Shift when an invocation starts and leave what runs unchanged. The Inspector keeps panes and Mech reports. They share no implementation.")
                          ("inspect-reads-debug" "mech-inspect" "mech-click" :reads :source-observed
                           "inspect writes its key label only if state.debug is set. CLICK sets state.debug from event.shiftKey before the same run (pinned excerpts)."))
                   collect (tm:make-topicmap-association
                            :id id :type type :from from :to to
                            :properties (list :presentation :relation
                                              :epistemic-status status :warrant warrant)))))
      (tm:make-topicmap-workspace
       (tm:make-topicmap-projection :source "Shift-click Is Pane Policy"
                                    :topics topics :associations associations
                                    :view-properties '(:width 1800 :height 760))
       "shift-click"))))
