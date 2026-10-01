;;;; Real CLOG browser witness on loopback, over the existing temporary fixture.
;;;; Events are explicitly synthetic; no physical-input claim is made.
(in-package #:dreyeck/work/editor/tests)

(defun %browser-last-pane () (car (last (tst::%witness-panes))))
(defun %browser-open (pane selector label type)
  (let ((before (tst::%witness-panes)))
    (tst::%witness-await label
      (lambda () (equal "clicked" (tst::%witness-click pane selector label))))
    (tst::%witness-await label
      (lambda ()
        (assert (notany (lambda (pane)
                          (typep (clog-moldable-inspector::pane-object pane)
                                 'hyperbook:lookup-failure)) (tst::%witness-panes)))
        (and (not (member (%browser-last-pane) before :test #'eq))
             (typep (tst::%witness-last-object) type))))
    (%browser-last-pane)))
(defun %browser-tab (pane title needle)
  (assert (equal "clicked" (tst::%witness-click pane ".inspector-tabs button" title)))
  (tst::%witness-await title (lambda () (search needle (tst::%witness-pane-text pane))))
  pane)
(defun %browser-primary (pane ws id)
  (assert (equal "clicked"
                 (tst::%witness-js
                  (format nil "(function(){const p=document.getElementById('~A');const e=[...p.querySelectorAll('.dreyeck-topicmap-workspace-action')].find(x=>x.dataset.topicId===~S);if(!e)return 'missing';e.dispatchEvent(new MouseEvent('click',{bubbles:true,button:0}));return 'clicked';})()"
                          (clog:html-id (clog-moldable-inspector::clog-obj pane)) id))))
  (tst::%witness-await "PRIMARY Point navigation"
    (lambda () (equal id (tm:topicmap-workspace-point-of ws))))
  (tst::%witness-await "refreshed native Point"
    (lambda ()
      (equal "true"
             (tst::%witness-js
              (format nil "(function(){const p=document.getElementById('~A');const h=[...p.querySelectorAll('h3')].find(x=>x.textContent==='Point');if(!h)return false;const entries=[];for(let e=h.nextElementSibling;e&&e.tagName!=='H3';e=e.nextElementSibling)entries.push(e);const labels=entries.map(e=>e.textContent.trim());return labels.length===3&&labels[0]===~S&&labels[1]==='Open Work Topic'&&labels[2]===~S&&entries.every(e=>e.querySelectorAll('.inspector-inspect [id]').length===1);})()"
                      (clog:html-id (clog-moldable-inspector::clog-obj pane))
                      (tm:topicmap-topic-label-of (tm:topicmap-workspace-current-topic ws))
                      (format nil "Carrier page: ~A"
                              (hyperbook:title-of
                               (tm:topicmap-topic-object-of (tm:topicmap-workspace-current-topic ws))))))))))

(defun run-human-editor-demo (&key (port 18091))
  "The browser witness's authoring-capable fixture, without synthetic clicks.
Enter on the terminal stops the loopback listener and removes the fixture."
  (assert (typep (dreyeck/workflow/authoring:make-authoring-environment)
                 'dreyeck/workflow/authoring::authoring-environment))
  (tst::call-with-work-breakdown-fixture
   (lambda (page path)
     (let ((ws (workspace page)))
       (unwind-protect
            (progn
              (clog:initialize
               (lambda (body)
                 (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
                 (let ((inspector (clog-moldable-inspector::create-inspector
                                   body :pane-width "900px" :playground? nil)))
                   (clog-moldable-inspector::create-pane inspector ws :select "Topicmap")))
               :host "127.0.0.1" :port port)
              (format t "~&Demo: http://127.0.0.1:~D/~%Temporary source: ~A~%Press Enter to stop and remove the fixture.~%" port path)
              (finish-output)
              (read-line *query-io*))
         (clog:shutdown))))))

(defun run-live-editor-witness (&key (port 18091) done-file (linger 300))
  "Serve a fresh authoring image's Inspector only on loopback. A connected
browser follows status and relationship edits, with complete request and plan
inspection, then witnesses refusal of a pre-effect selection. Every effect
is on the temporary Work Breakdown copy; TEST-OP never starts this server."
  (let ((pages (tst::work-page-sources)))
    (tst::call-with-work-breakdown-fixture
     (lambda (page path)
       (let* ((ws (workspace page)) (original (tst::%read path)))
         ;; Start away from the edited Topic to witness ordinary PRIMARY.
         (tm:topicmap-workspace-go-to ws "lisp-source-authoring")
         (setf tst::*witness-signal* (sb-thread:make-semaphore)
               tst::*witness-body* nil tst::*witness-inspector* nil tst::*witness-pane* nil)
         (unwind-protect
              (progn
                (clog:initialize
                 (lambda (body)
                   (setf tst::*witness-body* body)
                   (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
                   (setf tst::*witness-inspector*
                         (clog-moldable-inspector::create-inspector body :pane-width "900px" :playground? nil))
                   (setf tst::*witness-pane*
                         (clog-moldable-inspector::create-pane tst::*witness-inspector* ws :select "Topicmap"))
                   (sb-thread:signal-semaphore tst::*witness-signal*))
                 :port port :host "127.0.0.1")
                (format t "~&EDITOR-WITNESS-LISTENING http://127.0.0.1:~D/~%" port)
                (finish-output)
                (tst::%witness-await "browser" (lambda () tst::*witness-pane*) :seconds 600)
                (%browser-primary tst::*witness-pane* ws "hyperdoc-page-authoring")
                ;; All Point references retain their distinct exact targets.
                (let* ((topic (tm:topicmap-workspace-current-topic ws))
                       (raw-pane (%browser-open tst::*witness-pane* ".inspector-inspect [id]"
                                                "Structural HyperDoc Page Authoring" 'work:work-topic)))
                  (assert (eq topic (clog-moldable-inspector::pane-object raw-pane)))
                  (let ((carrier-pane (%browser-open tst::*witness-pane* ".inspector-inspect [id]"
                                                      "Operations and Change" 'hyperbook:page)))
                    (assert (eq (tm:topicmap-topic-object-of topic)
                                (clog-moldable-inspector::pane-object carrier-pane)))
                    (%browser-tab carrier-pane "Content" "Operations")))
                (let* ((topic-pane (%browser-open tst::*witness-pane* ".inspector-inspect [id]" "Open Work Topic" 'a::work-editor-context))
                       (topic (a::editor-topic (clog-moldable-inspector::pane-object topic-pane))))
                  (assert (eq topic (tm:topicmap-workspace-current-topic ws)))
                  (assert (eq page (work:topic-occurrence-page (work:topic-source-occurrence topic))))
                  (%browser-tab topic-pane "Work Operations" "Create relationship")
                  (let* ((selection-pane (%browser-open topic-pane "button.inspector-action" "Change work status" 'a::work-editor-context))
                         (selection (clog-moldable-inspector::pane-object selection-pane)))
                    (assert (eq (work:topic-source-occurrence topic) (r:operation-request-occurrence (a::editor-selection selection))))
                    (%browser-tab selection-pane "Change work status" "in progress")
                    ;; The human failure path: declaring page -> authored link.
                    ;; Page Content resolves relative links against the fixture,
                    ;; not against dreyeck/work/reading or an error condition.
                    (let ((page-pane (%browser-open selection-pane ".inspector-inspect [id]"
                                                    "Work Breakdown" 'hyperbook:page)))
                      (assert (eq page (clog-moldable-inspector::pane-object page-pane)))
                      (%browser-tab page-pane "Content" "Structural HyperDoc Page Authoring")
                      (assert (equal "0" (tst::%witness-js
                                           (format nil "document.getElementById('~A').querySelectorAll('.hyperbook-error').length"
                                                   (clog:html-id (clog-moldable-inspector::clog-obj page-pane))))))
                      (dolist (navigation '(("Structural HyperDoc Page Authoring" "Operations and Change")
                                            ("Lisp Code Page and executable examples" "Working on HyperDoc")))
                        (let* ((target-pane (%browser-open page-pane ".inspector-inspect [id]"
                                                           (first navigation) 'hyperbook:page))
                               (target (clog-moldable-inspector::pane-object target-pane)))
                          (assert (eq target (hyperbook:find-page "work-authoring-probe" (second navigation)
                                                                 :signal-error? t)))
                          (assert (eq (hyperbook:hyperbook-of page) (hyperbook:hyperbook-of target)))
                          (assert (not (eq target (work:work-page (second navigation))))))))
                    (format t "~&EDITOR-BROWSER-NAVIGATION-PASS: Point Topic, editor context and original carrier retained; declaring-page Content links open fixture text/code pages, no lookup-failure pane.~%")
                    (let* ((request-pane (%browser-open selection-pane "button.inspector-action" "Change work status to \"in progress\"" 'work:work-status-change-request))
                           (request (clog-moldable-inspector::pane-object request-pane)))
                      (%browser-tab request-pane "Work request" "Preview plan")
                      (assert (string= original (tst::%read path)))
                      (let* ((plan-pane (%browser-open request-pane "button.inspector-action" "Preview plan" 'a:work-status-change-plan))
                             (preview (clog-moldable-inspector::pane-object plan-pane)))
                        (%browser-tab plan-pane "Work plan" "Execute request after revalidation")
                        (assert (string= original (tst::%read path)))
                        (let* ((fresh-pane (%browser-open plan-pane "button.inspector-action" "Execute request after revalidation" 'tm:topicmap-workspace))
                               (fresh (clog-moldable-inspector::pane-object fresh-pane))
                               (written (tst::%read path)))
                          (%browser-tab fresh-pane "Work Breakdown" "Applied")
                          (assert (eq :applied (a:work-status-change-outcome-status (outcome fresh))))
                          (assert (not (eq preview (a:work-status-change-outcome-plan (outcome fresh)))))
                          (assert (eq request (a:work-status-change-outcome-request (outcome fresh))))
                          (assert (not (eq topic (tm:topicmap-workspace-current-topic fresh))))
                          (assert (equal "in progress" (tst::%status (tm:topicmap-workspace-projection-of fresh) "hyperdoc-page-authoring")))
                          (format t "~&EDITOR-BROWSER-STATUS-PASS: PRIMARY -> exact Topic -> selection -> request -> plan -> Execute -> fresh Workspace, new source occurrence, retained Point.~%")
                          ;; A relationship from the fresh graph, same chain.
                          (%browser-primary fresh-pane fresh "lisp-source-authoring")
                          (let* ((from-pane (%browser-open fresh-pane ".inspector-inspect [id]" "Open Work Topic" 'a::work-editor-context))
                                 (from (a::editor-topic (clog-moldable-inspector::pane-object from-pane))))
                            (assert (eq from (tm:topicmap-workspace-current-topic fresh)))
                            (%browser-tab from-pane "Work Operations" "Create relationship")
                            (let* ((relation-selection-pane (%browser-open from-pane "button.inspector-action" "Create relationship" 'a::work-editor-context))
                                   (target (tm:topicmap-projection-topic-by-id (tm:topicmap-workspace-projection-of fresh) "running-image-authoring")))
                              (%browser-tab relation-selection-pane "Create relationship" "Target:")
                              (let* ((choice-pane (%browser-open relation-selection-pane "button.inspector-action"
                                                                (format nil "Target: ~A" (tm:topicmap-topic-label-of target)) 'views:view))
                                     (relation-request-pane (progn
                                                              (%browser-tab choice-pane "View" "Use relation: informs")
                                                              (%browser-open choice-pane "button.inspector-action" "Use relation: informs" 'work:work-relationship-creation-request)))
                                     (relation-request (clog-moldable-inspector::pane-object relation-request-pane)))
                                (assert (eq (work:topic-source-occurrence target) (work:work-relationship-creation-to-occurrence relation-request)))
                                (assert (equal "work:relation/informs" (work:work-relationship-creation-relation relation-request)))
                                (%browser-tab relation-request-pane "Work request" "Preview plan")
                                (assert (string= written (tst::%read path)))
                                (let* ((relation-plan-pane (%browser-open relation-request-pane "button.inspector-action" "Preview plan" 'a:work-relationship-creation-plan))
                                       (relation-fresh-pane (progn
                                                              (%browser-tab relation-plan-pane "Work plan" "Execute request after revalidation")
                                                              (assert (string= written (tst::%read path)))
                                                              (%browser-open relation-plan-pane "button.inspector-action" "Execute request after revalidation" 'tm:topicmap-workspace)))
                                       (now (clog-moldable-inspector::pane-object relation-fresh-pane)))
                                  (%browser-tab relation-fresh-pane "Work Breakdown" "Applied")
                                  (assert (eq :applied (a:work-relationship-creation-outcome-status (outcome now))))
                                  (assert (= 23 (length (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of now)))))
                                  (assert (equal "lisp-source-authoring" (tm:topicmap-workspace-point-of now)))
                                  (format t "~&EDITOR-BROWSER-RELATIONSHIP-PASS: exact target from observed projection, work:relation/informs preserved, request -> plan -> Execute -> fresh 22/23 Workspace.~%")
                                  ;; Branch from the pre-effect selection last:
                                  ;; Inspector navigation closes panes to its right.
                                  (let* ((current (tst::%read path))
                                         (refusal-pane (%browser-open selection-pane "button.inspector-action"
                                                                     "Change work status to \"in progress\"" 'work:work-status-change-refused)))
                                    (tst::%witness-await "visible stale refusal"
                                      (lambda () (search "stale" (tst::%witness-pane-text refusal-pane))))
                                    (assert (string= current (tst::%read path)))
                                    (format t "~&EDITOR-BROWSER-STALE-PASS: pre-effect selection refused, source unchanged, no ID relocation.~%")))))))))))
                (assert (equal pages (tst::work-page-sources)))
                (format t "~&LIVE-WORK-EDITOR-WITNESS-PASS (real browser/CLOG, synthetic input, temporary source authority).~%")
                (finish-output)
                (loop repeat (* 5 linger) until (and done-file (probe-file done-file)) do (sleep 0.2)))
           (ignore-errors (clog:shutdown))))))
    (assert (equal pages (tst::work-page-sources))))
  t)
