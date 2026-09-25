;;;; Live evidence for the interactive TALA view, owned and checked by Lisp through CLOG.
;;;;
;;;; A browser (the ordinary one, or any other pointed at the port) shows a
;;;; real Inspector on the Work layout. Clicks are dispatched by script, so
;;;; every one has isTrusted=false; the test records that. A physical click
;;;; is not claimed.
(in-package #:dreyeck/work/tests)

(defvar *live-body* nil)
(defvar *live-inspector* nil)

(defun %live-await (predicate &key (timeout 30) (what "condition"))
  (loop repeat (* 10 timeout)
        when (funcall predicate) return t
        do (sleep 0.1)
        finally (error "Live Inspector: timed out waiting for ~A." what)))

(defun %live-js (expression)
  (clog:js-query *live-body* (format nil "(function(){~A})()" expression)))

(defun %live-panes ()
  (fset:convert 'list (clog-moldable-inspector::inspector-panes *live-inspector*)))

(defun %live-view (pane title)
  (clog-moldable-inspector::select-view pane title)
  (let ((view (find title (clog-moldable-inspector::pane-views pane)
                    :key #'views:view-title :test #'equal)))
    (assert view () "Pane has no ~S view." title)
    view))

(defun %live-reference-id (view object)
  (let ((ids (mapcar #'car (remove object (views:view-references view)
                                   :key #'cdr :test-not #'eq))))
    (assert (= 1 (length ids)))
    (first ids)))

(defun %live-click (id &optional (part ""))
  "Dispatch a synthetic click on element ID, or on its first PART descendant."
  (assert (equal "true"
                 (%live-js
                  (format nil "const g=document.getElementById('~A');if(!g)return 'missing';const e=~:[g.querySelector('~A')~;g~*~];e.dispatchEvent(new MouseEvent('click',{bubbles:true,button:0}));return 'true';"
                          id (equal part "") part)))))

(defun %live-open (pane view-title object &optional (part ""))
  "Click OBJECT's reference in PANE's view and return the pane that opens."
  (let* ((view (%live-view pane view-title))
         (id (%live-reference-id view object))
         (before (%live-panes)))
    (%live-click id part)
    (%live-await (lambda () (let ((last (car (last (%live-panes)))))
                              (and last (not (member last before))))))
    (car (last (%live-panes)))))

(defun start-interactive-tala-inspector (&key (port 18090) (open-browser t) (connect-timeout 120))
  "Serve an Inspector whose first pane shows the Work layout's interactive view."
  (let ((rendering (work:work-layout-example)))
    (setf *live-body* nil *live-inspector* nil)
    (clog:initialize
     (lambda (body)
       (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
       (let ((inspector (clog-moldable-inspector::create-inspector
                         body :pane-width "900px" :playground? nil)))
         (clog-moldable-inspector::create-pane inspector rendering
                                               :select "TALA (interactive)")
         (setf *live-inspector* inspector *live-body* body)))
     :port port :host "127.0.0.1")
    (when open-browser (clog:open-browser :url (format nil "http://127.0.0.1:~D/" port)))
    (%live-await (lambda () *live-inspector*) :timeout connect-timeout :what "a browser")
    rendering))

(defun run-live-interactive-tala-test (&key (port 18090) (open-browser t) (connect-timeout 120))
  (let* ((pages (work-page-sources))
         (rendering (start-interactive-tala-inspector :port port :open-browser open-browser
                                                      :connect-timeout connect-timeout))
         (projection (tala:tala-input-projection (tala:tala-rendering-input rendering)))
         (a1 (association-between projection "interaction" "operations"))
         (a2 (association-between projection "operations" "connect"))
         (interaction (tm:topicmap-projection-topic-by-id projection "interaction"))
         (contract (getf (tm:topicmap-association-properties-of a1) :relation-contract))
         (first-pane (first (%live-panes))))
    (%live-js "window.__clicks=[];document.addEventListener('click',e=>window.__clicks.push(e.isTrusted),true);return true;")
    ;; Two interactive views of one rendering in the page at once.
    (clog-moldable-inspector::create-pane *live-inspector* rendering :select "TALA (interactive)")
    (let ((tala-pane (car (last (%live-panes)))))
      (assert (not (eq tala-pane first-pane)))
      ;; Every ID inside either diagram occurs once in the whole page, and
      ;; each diagram's marker/mask references resolve inside that diagram.
      ;; The Inspector's own title-bar icons repeat IDs in every pane; that
      ;; is outside these diagrams and is reported, not asserted.
      (assert (equal "2:0:0"
                     (%live-js "const svgs=[...document.querySelectorAll('svg.d2-svg')];let shared=0,bad=0;svgs.forEach(s=>{s.querySelectorAll('[id]').forEach(e=>{if(document.querySelectorAll('[id=\"'+e.id+'\"]').length!==1)shared++;});s.querySelectorAll('[marker-end],[mask]').forEach(e=>{const v=e.getAttribute('marker-end')||e.getAttribute('mask');const id=v.slice(5,v.indexOf(')'));if(!s.querySelector('[id=\"'+id+'\"]'))bad++;});});return svgs.length+':'+shared+':'+bad;")))
      (format t "~&TWO-VIEWS-PASS: two inline TALA SVGs; no ID inside either occurs twice in the page; every marker/mask reference resolves inside its own SVG. Inspector icon IDs repeated outside the diagrams: ~A.~%"
              (%live-js "const ids=[...document.querySelectorAll('[id]')].filter(e=>!e.closest('svg.d2-svg')).map(e=>e.id);return ids.length-new Set(ids).size;"))
      ;; PRIMARY on label and on path of each informs edge.
      (loop for (association part) in (list (list a1 "text") (list a1 "path")
                                            (list a2 "text") (list a2 "path"))
            do (assert (eq association
                           (clog-moldable-inspector::pane-object
                            (%live-open tala-pane "TALA (interactive)" association part)))))
      (assert (not (eq a1 a2)))
      ;; A Topic shape opens its Topic, not an edge.
      (assert (eq interaction
                  (clog-moldable-inspector::pane-object
                   (%live-open tala-pane "TALA (interactive)" interaction "rect"))))
      (format t "~&PRIMARY-PASS: label and path of each informs edge open its own Association; a shape opens its Topic.~%")
      ;; Association -> properties -> contract Topic -> contract Page, by clicks.
      (dolist (association (list a1 a2))
        (let* ((association-pane (%live-open tala-pane "TALA (interactive)" association "text"))
               (properties (tm:topicmap-association-properties-of association))
               (properties-pane (%live-open association-pane
                                            (views:view-title
                                             (find "Slots" (clog-moldable-inspector::pane-views association-pane)
                                                   :key #'views:view-title :test #'search))
                                            properties))
               (topic-pane (%live-open properties-pane "Items" contract))
               (page-pane (%live-open topic-pane
                                      (views:view-title
                                       (find "Slots" (clog-moldable-inspector::pane-views topic-pane)
                                             :key #'views:view-title :test #'search))
                                      (tm:topicmap-topic-object-of contract))))
          (assert (eq contract (clog-moldable-inspector::pane-object topic-pane)))
          (assert (eq (work:work-page "Relation Contract: informs")
                      (clog-moldable-inspector::pane-object page-pane)))
          ;; The page's own link lists the Associations using the contract.
          (let* ((content (%live-view page-pane "Content"))
                 (uses (find-if #'consp (mapcar #'cdr (views:view-references content))))
                 (uses-pane (%live-open page-pane "Content" uses)))
            (assert (equal (list (tm:topicmap-association-id-of a1) (tm:topicmap-association-id-of a2))
                           (mapcar #'tm:topicmap-association-id-of
                                   (clog-moldable-inspector::pane-object uses-pane)))))))
      (format t "~&CONTRACT-PASS: both Associations reach the same contract Topic and Page by Inspector clicks; the Page lists both uses.~%")
      ;; Refresh: the old groups leave the page, the new ones map as before.
      (let ((old-id (%live-reference-id (%live-view tala-pane "TALA (interactive)") a1)))
        (clog-moldable-inspector::refresh tala-pane)
        (%live-await (lambda () (equal "gone" (%live-js (format nil "return document.getElementById('~A')?'present':'gone';" old-id))))
                     :what "the old group to leave the page")
        (let ((new-id (%live-reference-id (%live-view tala-pane "TALA (interactive)") a1)))
          (assert (not (equal old-id new-id)))
          (assert (eq a1 (clog-moldable-inspector::pane-object
                          (%live-open tala-pane "TALA (interactive)" a1 "text"))))))
      (format t "~&REFRESH-PASS: the old SVG group left the page; the new group opens the same Association.~%"))
    ;; Every click the page saw was dispatched by script.
    (assert (equal "synthetic"
                   (%live-js "return window.__clicks.length>0 && window.__clicks.every(t=>t===false) ? 'synthetic' : 'trusted-or-none';")))
    (assert (equal pages (work-page-sources)))
    (clog:close-connection (clog:window *live-body*))
    (format t "~&LIVE-INTERACTIVE-TALA-PASS (synthetic clicks, isTrusted=false; no physical click claimed).~%")
    t))

;;;; SECONDARY on an Association sign: Inspect relation contract

(defun %live-sign-attribute (id name)
  (%live-js (format nil "const g=document.getElementById('~A');return g?String(g.getAttribute('~A')):'missing';"
                    id name)))

(defun %live-pointers (id steps &optional (part "text"))
  "Dispatch STEPS -- (event button buttons dx) -- on ID's PART in one browser
turn. Explicitly synthetic: isTrusted is false for every one of them."
  (assert (equal "true"
                 (%live-js
                  (format nil "const g=document.getElementById('~A');const t=g.querySelector('~A');const r=t.getBoundingClientRect();[~{~A~^,~}].forEach(([n,b,bs,dx])=>t.dispatchEvent(new PointerEvent(n,{bubbles:true,pointerId:77,pointerType:'mouse',button:b,buttons:bs,clientX:r.x+r.width/2+dx,clientY:r.y+r.height/2})));return 'true';"
                          id part
                          (mapcar (lambda (step)
                                    (destructuring-bind (name button buttons dx) step
                                      (format nil "['~A',~D,~D,~D]" name button buttons dx)))
                                  steps))))))

(defun %live-visible-menus ()
  (%live-js "return [...document.querySelectorAll('.dreyeck-association-gesture-menu')].filter(e=>getComputedStyle(e).visibility==='visible').map(e=>e.textContent).join('|');"))

(defun %live-visited (window)
  "The states the window's current interaction passed through, from the reducer."
  (sm:state-machine-run-visited-states-of
   (dreyeck/gesture/transport:input-session-gesture-session
    (dreyeck/gesture/transport:witness-input (dreyeck/gesture/clog:gesture-window-witness window)))))

(defun %live-await-pane (before &key (what "a pane"))
  (%live-await (lambda () (let ((last (car (last (%live-panes)))))
                            (and last (not (member last before)))))
               :what what)
  (car (last (%live-panes))))

(defun run-live-association-gesture-test (&key (port 18091) (open-browser t) (connect-timeout 120))
  (let* ((pages (work-page-sources))
         (rendering (start-interactive-tala-inspector :port port :open-browser open-browser
                                                      :connect-timeout connect-timeout))
         (projection (tala:tala-input-projection (tala:tala-rendering-input rendering)))
         (a1 (association-between projection "interaction" "operations"))
         (a2 (association-between projection "operations" "connect"))
         (requires (association-between projection "operations" "state"))
         (contract (getf (tm:topicmap-association-properties-of a1) :relation-contract))
         (operation (w:inspect-relation-contract-operation))
         (tala-pane (first (%live-panes))))
    (flet ((id-of (association)
             (%live-reference-id (%live-view tala-pane "TALA (interactive)") association))
           (window-of (id)
             (%live-await (lambda () (m:association-sign-gesture-window *live-body* id))
                          :what "the Association sign's gesture window")
             (m:association-sign-gesture-window *live-body* id)))
      (%live-js "window.__events=[];['pointerdown','pointermove','pointerup','click'].forEach(k=>document.addEventListener(k,e=>window.__events.push(k+':'+e.isTrusted),true));return true;")
      ;; PRIMARY: never Gesture, always the exact Association.
      (dolist (association (list a1 a2))
        (let* ((id (id-of association)) (window (window-of id)))
          (%live-pointers id '(("pointerdown" 0 1 0)))
          (sleep 0.65)
          (%live-pointers id '(("pointerup" 0 0 0)))
          (dolist (part '("text" "path"))
            (assert (eq association (clog-moldable-inspector::pane-object
                                     (%live-open tala-pane "TALA (interactive)" association part)))))
          (assert (null (dreyeck/gesture/clog:gesture-window-log window)))
          (assert (equal "null" (%live-sign-attribute id "data-association-gesture-state")))))
      (format t "~&PRIMARY-PASS: label and path open the exact Association; a held PRIMARY enters no Gesture.~%")
      ;; Novice on A1: the menu appears only after the reveal delay and shows
      ;; this window's one Operation; releasing on it shows the contract.
      (let* ((id (id-of a1)) (window (window-of id)) (before (%live-panes))
             (clicks (%live-js "return String(window.__events.filter(e=>e.startsWith('click')).length);"))
             (start (get-internal-real-time)))
        (%live-pointers id '(("pointerdown" 2 2 0)))
        (assert (equal "" (%live-visible-menus)))
        (%live-await (lambda () (equal "true" (%live-sign-attribute id "data-association-gesture-menu-visible")))
                     :what "the visible menu")
        (let ((elapsed (/ (- (get-internal-real-time) start) internal-time-units-per-second)))
          (assert (>= elapsed 0.45) () "Menu appeared after ~,2Fs." elapsed))
        (assert (equal "Inspect relation contract" (%live-visible-menus)))
        (%live-pointers id '(("pointermove" -1 2 70) ("pointerup" 2 0 70)))
        (let ((pane (%live-await-pane before :what "the contract pane")))
          (assert (eq contract (clog-moldable-inspector::pane-object pane))))
        (assert (equal '(:idle :pressed :menu-visible :sector-selected :completed)
                       (%live-visited window)))
        (multiple-value-bind (binding target) (dreyeck/gesture/clog:gesture-window-selection window)
          (assert (equal "binding/radial-inspect-relation-contract" (w:gesture-binding-id binding)))
          (assert (eq operation (w:gesture-binding-operation binding)))
          (assert (eq a1 (getf target :association))))
        (assert (equal "shown" (%live-sign-attribute id "data-association-gesture-outcome")))
        (assert (equal clicks (%live-js "return String(window.__events.filter(e=>e.startsWith('click')).length);"))))
      (format t "~&NOVICE-PASS: menu after the reveal delay, showing only Inspect relation contract; release opened the contract Topic, target A1, no click.~%")
      ;; Expert on A1, then A2: marking before any menu, same Operation.
      (dolist (association (list a1 a2))
        (let* ((id (id-of association)) (window (window-of id)) (before (%live-panes)))
          (%live-pointers id '(("pointerdown" 2 2 0) ("pointermove" -1 2 70) ("pointerup" 2 0 70)))
          (let ((pane (%live-await-pane before :what "the contract pane")))
            (assert (eq contract (clog-moldable-inspector::pane-object pane))))
          (assert (equal '(:idle :pressed :marking :sector-selected :completed)
                         (%live-visited window)))
          (assert (notany (lambda (s) (getf s :menu-visible))
                          (dreyeck/gesture/clog:gesture-window-log window)))
          (multiple-value-bind (binding target) (dreyeck/gesture/clog:gesture-window-selection window)
            (assert (equal "binding/mark-inspect-relation-contract" (w:gesture-binding-id binding)))
            (assert (eq operation (w:gesture-binding-operation binding)))
            (assert (eq association (getf target :association))))))
      (assert (not (eq a1 a2)))
      (format t "~&EXPERT-PASS: A1 and A2 each marked without a menu, the same Operation, and each showed the same contract Topic.~%")
      ;; An Association without a contract: selected, refused, nothing opened.
      (let* ((id (id-of requires)) (before (%live-panes)))
        (%live-pointers id '(("pointerdown" 2 2 0) ("pointermove" -1 2 70) ("pointerup" 2 0 70)))
        (%live-await (lambda () (equal "not-applicable" (%live-sign-attribute id "data-association-gesture-outcome")))
                     :what "the refusal")
        (assert (search "refers to no Relation Contract"
                        (%live-sign-attribute id "data-association-gesture-refusal")))
        (sleep 0.5)
        (assert (equal before (%live-panes))))
      (format t "~&NOT-APPLICABLE-PASS: operations -> state completes the selection, is refused, and opens no pane.~%")
      ;; Refresh: the old sign leaves; the new one has its own window.
      (let* ((old-id (id-of a1)) (old-window (window-of old-id))
             (old-log (copy-list (dreyeck/gesture/clog:gesture-window-log old-window))))
        (clog-moldable-inspector::refresh tala-pane)
        (%live-await (lambda () (equal "missing" (%live-sign-attribute old-id "id")))
                     :what "the old sign to leave the page")
        (let* ((new-id (id-of a1)) (new-window (window-of new-id)) (before (%live-panes)))
          (assert (not (equal old-id new-id)))
          (assert (not (eq old-window new-window)))
          (%live-pointers new-id '(("pointerdown" 2 2 0) ("pointermove" -1 2 70) ("pointerup" 2 0 70)))
          (assert (eq contract (clog-moldable-inspector::pane-object
                                (%live-await-pane before :what "the contract pane"))))
          (assert (eq a1 (getf (nth-value 1 (dreyeck/gesture/clog:gesture-window-selection new-window))
                               :association)))
          (assert (equal old-log (dreyeck/gesture/clog:gesture-window-log old-window)))))
      (format t "~&REFRESH-PASS: the old sign left the page with its window idle; the new sign's own window selected A1.~%")
      (assert (equal "synthetic"
                     (%live-js "return window.__events.length>0 && window.__events.every(e=>e.endsWith(':false')) ? 'synthetic' : 'trusted-or-none';")))
      (assert (equal pages (work-page-sources)))
      (clog:close-connection (clog:window *live-body*))
      (format t "~&LIVE-ASSOCIATION-GESTURE-PASS (synthetic pointer and click events, isTrusted=false; no physical input claimed).~%")
      t)))
