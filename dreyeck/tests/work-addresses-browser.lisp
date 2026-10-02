;;;; Live browser witness is started explicitly, never by TEST-OP.
(in-package #:dreyeck/work/addresses/tests)

(defun %browser-execute-addresses (plan-pane)
  ;; Diagnose an inspectable refusal/unverified outcome immediately rather than
  ;; hiding it behind a timeout waiting for a successful Workspace.
  (let ((before (tst::%witness-panes)))
    (assert (equal "clicked" (tst::%witness-click plan-pane "button.inspector-action" "Execute request after revalidation")))
    (tst::%witness-await "addresses execution result"
      (lambda () (not (member (ed::%browser-last-pane) before :test #'eq))))
    (let* ((pane (ed::%browser-last-pane)) (object (clog-moldable-inspector::pane-object pane)))
      (unless (typep object 'tm:topicmap-workspace)
        (error "Unexpected addresses execution result ~S; cause ~A; rendered ~A"
               object (if (typep object 'a:work-relationship-creation-outcome)
                          (a:work-relationship-creation-outcome-cause object) object)
               (tst::%witness-pane-text pane)))
      pane)))

(defun %browser-create-addresses (pane workspace)
  (let* ((topic-pane (ed::%browser-open pane ".inspector-inspect [id]" "Open Work Topic" 'a::work-editor-context))
         (selection-pane (progn (ed::%browser-tab topic-pane "Work Operations" "Create relationship")
                                (ed::%browser-open topic-pane "button.inspector-action" "Create relationship" 'a::work-editor-context)))
         (target-pane (progn (ed::%browser-tab selection-pane "Create relationship" "Inspect foreign Constraint")
                             (ed::%browser-open selection-pane "button.inspector-action"
                                               "Inspect foreign Constraint: Serialized verified effect" 'a::inspected-addresses-target)))
         (target (clog-moldable-inspector::pane-object target-pane)))
    (ed::%browser-tab target-pane "Inspected foreign target" "Use inspected target")
    ;; Inspect the actual foreign Topic, not its carrier or semantic-ID proxy.
    (let ((raw-pane (ed::%browser-open target-pane ".inspector-inspect [id]"
                                     "Serialized verified effect" 'work:work-topic)))
      (assert (eq (clog-moldable-inspector::pane-object raw-pane) (a::inspected-target-topic target))))
    (let* ((choice-pane (ed::%browser-open target-pane "button.inspector-action" "Use inspected target" 'views:view))
           (request-pane (progn (ed::%browser-tab choice-pane "View" "Use relation: addresses")
                                (ed::%browser-open choice-pane "button.inspector-action" "Use relation: addresses" 'work:addresses-creation-request)))
           (r (clog-moldable-inspector::pane-object request-pane)))
      (assert (eq workspace (a::editor-workspace (a::%editor-context r))))
      (assert (eq target (a::editor-target-context (a::%editor-context r))))
      (assert (eq (work:work-relationship-creation-to-occurrence r) (work:topic-source-occurrence (a::inspected-target-topic target))))
      (ed::%browser-tab request-pane "Addresses read set" "full observed snapshot")
      (ed::%browser-tab request-pane "Work request" "Preview plan")
      (let* ((plan-pane (ed::%browser-open request-pane "button.inspector-action" "Preview plan" 'a::addresses-creation-plan))
             (fresh-pane (progn (ed::%browser-tab plan-pane "Work plan" "Execute request after revalidation")
                                (%browser-execute-addresses plan-pane)))
             (fresh (clog-moldable-inspector::pane-object fresh-pane)))
        (ed::%browser-tab fresh-pane "Work Breakdown" "Applied")
        (assert (eq :applied (a:work-relationship-creation-outcome-status (ed::outcome fresh))))
        (assert (equal (tm:topicmap-workspace-point-of workspace) (tm:topicmap-workspace-point-of fresh)))
        (values fresh-pane fresh selection-pane r)))))

(defun run-live-addresses-witness (&key (port 18092) done-file (linger 30))
  "The complete first bridge and independent append, using real CLOG/DOM
synthetic browser clicks. Temporary copies of both authorities only."
  (let ((before (tst::work-page-sources)))
    (tst::call-with-work-breakdown-fixture
     (lambda (page path)
       (declare (ignore path))
       (let ((ws (tm:make-topicmap-workspace (work:work-projection :page page) "fedwiki-item-authoring")))
         (setf tst::*witness-signal* (sb-thread:make-semaphore) tst::*witness-body* nil
               tst::*witness-inspector* nil tst::*witness-pane* nil)
         (unwind-protect
              (progn
                (clog:initialize
                 (lambda (body)
                   (setf tst::*witness-body* body)
                   (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
                   (setf tst::*witness-inspector* (clog-moldable-inspector::create-inspector body :pane-width "900px" :playground? nil))
                   (setf tst::*witness-pane* (clog-moldable-inspector::create-pane tst::*witness-inspector* ws :select "Topicmap"))
                   (sb-thread:signal-semaphore tst::*witness-signal*))
                 :host "127.0.0.1" :port port)
                (format t "~&ADDRESSES-WITNESS-LISTENING http://127.0.0.1:~D/~%" port) (finish-output)
                (tst::%witness-await "browser connection" (lambda () tst::*witness-pane*) :seconds 600)
                (multiple-value-bind (fresh-pane fresh old-selection r) (%browser-create-addresses tst::*witness-pane* ws)
                  (let ((bridge-a (first (work:qualified-bridges (tm:topicmap-workspace-projection-of fresh)))))
                    (let* ((evidence-pane (ed::%browser-open fresh-pane "button.inspector-action" "Inspect Evidence neighborhood" 'tm:topicmap-projection))
                           (evidence (clog-moldable-inspector::pane-object evidence-pane)))
                      (assert (= 3 (length (tm:topicmap-projection-topics-of evidence))))
                      (assert (= 2 (length (tm:topicmap-projection-associations-of evidence))))
                      (ed::%browser-tab evidence-pane "Qualified bridges" "Inspect qualified addresses bridge")
                      (let ((bridge-pane (ed::%browser-open evidence-pane ".inspector-inspect [id]" "Inspect qualified addresses bridge" 'work:qualified-addresses-bridge)))
                        (ed::%browser-tab bridge-pane "Qualified addresses bridge" "Currentness result")
                        (assert-current (clog-moldable-inspector::pane-object bridge-pane))))
                    (format t "~&ADDRESSES-BROWSER-FIRST-PASS: explicit foreign Topic/Workspace -> existing Create relationship -> complete full-read-set request -> preview -> executor -> fresh local Workspace -> Evidence -> qualified warrant inspection.~%")
                    ;; Navigate and append B through the identical human UI path.
                    (ed::%browser-primary fresh-pane fresh "hyperdoc-page-authoring")
                    (multiple-value-bind (b-pane b-workspace) (%browser-create-addresses fresh-pane fresh)
                      (assert-current bridge-a)
                      (let ((records (work:qualified-bridges (tm:topicmap-workspace-projection-of b-workspace))))
                        (assert (= 2 (length records))) (mapc #'assert-current records))
                      (let* ((evidence-pane (ed::%browser-open b-pane "button.inspector-action" "Inspect Evidence neighborhood" 'tm:topicmap-projection))
                             (evidence (clog-moldable-inspector::pane-object evidence-pane)))
                        (assert (= 3 (length (tm:topicmap-projection-associations-of evidence))))))
                    (format t "~&ADDRESSES-BROWSER-TWO-BRIDGES-PASS: bridge A and independently authored B both current after second write.~%")
                    ;; The old snapshot-bound selection still refuses; no ID repair.
                    (let* ((refusal-pane (ed::%browser-open old-selection "button.inspector-action"
                                                          "Inspect foreign Constraint: Serialized verified effect" 'a::inspected-addresses-target))
                           (choice-pane (progn (ed::%browser-tab refusal-pane "Inspected foreign target" "Use inspected target")
                                               (ed::%browser-open refusal-pane "button.inspector-action" "Use inspected target" 'views:view))))
                      (ed::%browser-tab choice-pane "View" "Target:")
                      (assert (not (search "Use relation: addresses" (tst::%witness-pane-text choice-pane)))))
                    (assert (eq :refused (a:work-relationship-creation-outcome-status
                                         (a:execute-work-relationship-creation r (dreyeck/workflow/authoring:make-authoring-environment)))))
                    (format t "~&ADDRESSES-BROWSER-STALE-PASS: old selection offers no executable addresses relation; old request refuses, while durable bridge A remains current.~%")))
                (assert (notany (lambda (pane) (typep (clog-moldable-inspector::pane-object pane) 'hyperbook:lookup-failure)) (tst::%witness-panes)))
                (assert (equal before (tst::work-page-sources)))
                (format t "~&LIVE-ADDRESSES-WITNESS-PASS (real browser/CLOG, synthetic input, temporary authorities, no D2 requirement).~%") (finish-output)
                (loop repeat (* 5 linger) until (and done-file (probe-file done-file)) do (sleep 0.2)))
           (ignore-errors (clog:shutdown))))))
    (assert (equal before (tst::work-page-sources)))) t)
