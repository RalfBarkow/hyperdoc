;;;; Investigating Ward's Hub Selection and Trail
(in-package #:dreyeck/work/hubs)
(hyperdoc:see (hyperdoc:page "From Two Hubs to One Trail" :hyperbook "dreyeck/work/reading"))

;; A bounded reading of retained artifacts, not Ward's implementation Plan or
;; an executor. All coordinates below identify observations within one capture.
(defparameter *hub-capture-digest*
  "739ea473cd67f800ee748ab25107d48d53d3cb57cb2224da7ba8cdd7df7289bf")
(defclass hub-investigation-plan () ())
(defclass hub-investigation-step ()
  ((id :initarg :id :reader investigation-step-id)
   (title :initarg :title :reader investigation-step-title)))
(defclass hub-investigation-finding ()
  ((step :initarg :step :reader finding-step)
   (record :initarg :record :reader finding-record)
   (sources :initarg :sources :reader finding-sources)))
(defmethod views:text-representation ((plan hub-investigation-plan))
  "Ward hub selection investigation plan")
(defmethod views:text-representation ((step hub-investigation-step))
  (format nil "~A investigation step" (investigation-step-id step)))
(defmethod views:text-representation ((finding hub-investigation-finding))
  (format nil "~A evidence finding" (investigation-step-id (finding-step finding))))
(defvar *hub-investigation-plan* (make-instance 'hub-investigation-plan))
(defvar *hub-investigation-steps*
  (loop for (id title) in '(("P1" "Identify the two selected hub aspects")
                            ("P2" "Identify the four selected nodes and their order")
                            ("P3" "Establish execution and source identity"))
        collect (make-instance 'hub-investigation-step :id id :title title)))
(defvar *hub-investigation-findings* (make-hash-table :test #'equal))

(defun hub-investigation-step (id)
  (or (find id *hub-investigation-steps* :key #'investigation-step-id :test #'equal)
      (error "No Hub investigation step: ~A" id)))
(defun hub-capture-item (id)
  (or (find id (gethash "story" (hub-page-capture)) :key (lambda (x) (gethash "id" x)) :test #'equal)
      (error "Missing retained Hub story item: ~A" id)))
(defun hub-saved-aspects ()
  (gethash "aspects" (hub-capture-item "61210638970208641024")))
(defun hub-node-coordinate (aspect-index node-index)
  "Identity within the captured Solo item, never a historical click or SVG ID."
  (let* ((aspect (aref (hub-saved-aspects) aspect-index))
         (node (aref (gethash "nodes" (gethash "graph" aspect)) node-index)))
    (alexandria:plist-hash-table
     (list "identity" (list *hub-capture-digest* "61210638970208641024" aspect-index node-index)
           "aspect-index" aspect-index "node-index" node-index "node" node
           "scope" "Array index local to the captured aspect; no explicit node id field") :test 'equal)))
(defun hub-trail-name-candidates ()
  "Name matches are candidates only; do not unify their source identities."
  (loop for node across (gethash "nodes" (gethash "graph" (aref (hub-saved-aspects) 2)))
        for index from 0 collect
          (list (hub-node-coordinate 2 index)
                (loop for aspect-index below 2 append
                  (loop for other across (gethash "nodes" (gethash "graph" (aref (hub-saved-aspects) aspect-index)))
                        for other-index from 0
                        when (equal (gethash "name" (gethash "props" node))
                                    (gethash "name" (gethash "props" other)))
                          collect (hub-node-coordinate aspect-index other-index))))))

(defun hub-investigation-finding (id)
  (or (gethash id *hub-investigation-findings*)
      (let* ((step (hub-investigation-step id))
             (aspects (hub-saved-aspects))
             (capture (hub-page-capture))
             (record (alexandria:plist-hash-table
                      (list "step" id "site" "ward.voices.ustawi.wiki"
                            "slug" "dewey-alexander-trail" "capture-sha256" *hub-capture-digest*
                            "confirmed-historical-selection" nil
                            "click-order" "unknown" "executed-mech-revision" "unknown"
                            "executed-solo-revision" "unknown") :test 'equal))
             (sources (list (cons "Original retained page JSON" capture)
                            (cons "Ward's separate author report" (ward-hub-report)))))
        (flet ((field (key value) (setf (gethash key record) value)))
          (cond
            ((equal id "P1")
             (field "observed" "Solo item 61210638970208641024 stores three aspects: hub 21 john-dewey (9 nodes, 11 relations), hub 4 christopher-alexander (6 nodes, 8 relations), New Trail (4 nodes, 3 Trail relations).")
             (field "inferred" "The first two names and graph shapes are candidates for WALK hubs output. Their number and names do not establish Ward's two selections.")
             (field "unsupported" "Actual two-hub selection history, WALK invocation, complete input neighborhood and ranking/hits at execution.")
             (field "needed" "A saved selected-aspect list or selection event record with source batch identity and the executed WALK inputs/revision.")
             (field "saved-aspects" aspects)
             (field "root-coordinates" (list (hub-node-coordinate 0 0) (hub-node-coordinate 1 0)))
             (field "slug-status" "Root properties store site and title, not slug. Aspect-name suffixes suggest slugs but are not independent page-identity evidence.")
             (push (cons "Selection semantics: seven synthetic cases, not Ward's run" (hub-selection)) sources)
             (push (cons "Checked original hubs source" (hub-function "hubs")) sources))
            ((equal id "P2")
             (field "observed" "New Trail stores Howard Becker, Donald Schön, Erin Kissane and Natural Order at local indices 0,1,2,3, with Trail relations 0→1→2→3. Those nodes retain name only, without site, slug, original-aspect coordinate or event timestamp.")
             (field "derived" "Saved relation order defines a directed path; it does not establish click order. Matching names in hub aspects identify candidates: aspect 0 indices 3 and 6; aspect 1 indices 1 and 5.")
             (field "unsupported" "Confirmed cross-aspect identity, composed node mapping, historical click order, and a rendered new Trail symbol.")
             (field "needed" "Pre-merge trail membership with aspect-local coordinates, composed-node mapping, ordered click events and the post-trail render capture.")
             (field "name-match-candidates" (hub-trail-name-candidates))
             (field "saved-path-relations" (gethash "rels" (gethash "graph" (aref aspects 2))))
             (field "render-boundary" "Graphviz item 94623848847186231296 stores text/DOT/SVG. DOT highlights 3,6,10,14 and contains no Trail edge label. SVG node ids and DOT indices are render coordinates, not captured click events or aspect-local identities.")
             (push (cons "Saved graphviz text, DOT and SVG" (hub-capture-item "94623848847186231296")) sources)
             (push (cons "Saved Solo item and graphs" (hub-capture-item "61210638970208641024")) sources))
            ((equal id "P3")
             (field "observed" "Paragraph 90799278607440248832 reports new Mech/Solo on localhost. The journal contains create, fork, fork from localhost:3000, and paragraph edit; no plugin version, module digest, input neighborhood or browser selection events are recorded.")
             (field "author-reported" "Ward reports a first end-to-end run; the transmitted message does not identify the loaded revisions.")
             (field "unsupported" "Exact historical Mech/Solo source, complete inputs, before/after execution state and continuity from our earlier controlled witnesses to Ward's new run.")
             (field "needed" "Historical loaded module URLs plus bytes/digests or build stamps, selected input batches/neighborhood and before/after trail state. A present-day replay would be a separate reconstruction.")
             (field "journal" (gethash "journal" capture))
             (field "historical-execution-identity" "unknown; retained comparison source revisions are not executed-runtime identities")
             (push (cons "Retained Mech comparison revision (not Ward's runtime)" *hub-revision*) sources)
             (push (cons "Existing Solo source references (not Ward's runtime)"
                         (reading::how-trails-sources
                          (hub-wiki-page "next.ward.dojo.fed.wiki" "how-trails-travel" "How Trails Travel"))) sources)
             (checked-hub-json "dreyeck/work/solo-trail-identity.json"
                               "912d7ab4c1b7ed062107a18890eff36f625c154fa9e46969f2fd5f1206d2ce84")
             (push (cons "Earlier controlled Solo execution, not Ward's new run" (reading::how-trails-execution)) sources))))
        (setf (gethash id *hub-investigation-findings*)
              (make-instance 'hub-investigation-finding :step step :record record :sources (nreverse sources))))))

(views:defview hub-investigation-plan-view (plan hub-investigation-plan)
  (declare (ignore plan))
  (views:html-view :title "Investigation Plan" :priority -1
    (views:html
      (:h2 "Identify Ward's Hub Selection and Trail")
      (:p "Open work: Which two hubs and which four nodes did Ward select, and which Mech/Solo execution produced the resulting trail? This is our investigation of retained evidence, separate from Ward's implementation Plan.")
      (:ol (dolist (step *hub-investigation-steps*)
        (views:html (:li (views:object-ref step :display (format nil "~A — ~A" (investigation-step-id step) (investigation-step-title step)) :select "Investigation step")))))
      (:p (views:object-ref (hub-and-trail-workspace) :display "Hub and Trail Workspace" :select "Topicmap"))
      (:p (views:object-ref (work:work-page "Work Breakdown") :display "Return to Work Breakdown" :select "Content"))
      (:p (views:object-ref (work:work-page "From Two Hubs to One Trail") :display "Return to From Two Hubs to One Trail" :select "Content")))))
(views:defview hub-investigation-step-view (step hub-investigation-step)
  (views:html-view :title "Investigation step" :priority -1
    (views:html
      (:h2 (views:esc (format nil "~A — ~A" (investigation-step-id step) (investigation-step-title step))))
      (:p "Read only retained artifacts. Candidate correspondence and missing evidence are findings, not confirmed selection history.")
      (:p (views:object-ref (hub-investigation-finding (investigation-step-id step)) :display "Evidence" :select "Investigation evidence"))
      (:p (views:object-ref *hub-investigation-plan* :display "Return to Investigation Plan" :select "Investigation Plan")))))
(views:defview hub-investigation-finding-view (finding hub-investigation-finding)
  (views:html-view :title "Investigation evidence" :priority -1
    (views:html
      (:h2 (views:esc (format nil "~A evidence" (investigation-step-id (finding-step finding)))))
      (:p "Source identity: ward.voices.ustawi.wiki / dewey-alexander-trail; retained JSON SHA-256 " (views:esc *hub-capture-digest*))
      (:dl (dolist (key '("observed" "derived" "inferred" "author-reported" "unsupported" "needed" "slug-status" "render-boundary" "historical-execution-identity"))
        (when (gethash key (finding-record finding))
          (views:html (:dt (views:esc key)) (:dd (views:esc (gethash key (finding-record finding))))))))
      (:p "Historical selection confirmation: open. Click order: unknown. Historical runtime revision: unknown.")
      (:p (views:object-ref (finding-record finding) :display "Structured finding and qualified coordinates"))
      (:ul (dolist (source (finding-sources finding))
        (views:html (:li (views:object-ref (cdr source) :display (car source))))))
      (:p (views:object-ref (hub-wiki-page "ward.voices.ustawi.wiki" "dewey-alexander-trail" "Dewey Alexander Trail") :display "Original site-qualified Wiki page" :select "Hub and trail reading"))
      (:p (views:object-ref (finding-step finding) :display "Return to investigation step" :select "Investigation step") " / "
          (views:object-ref *hub-investigation-plan* :display "Return to Investigation Plan" :select "Investigation Plan"))
      (:p (views:object-ref (work:work-page "From Two Hubs to One Trail") :display "Return to From Two Hubs to One Trail" :select "Content")))))

(defun hub-investigation-projection ()
  "Extend the same Workspace's learning projection; retain its original subjects."
  (let* ((base (hub-learning-projection))
         (topics (copy-list (tm:topicmap-projection-topics-of base)))
         (edges (copy-list (tm:topicmap-projection-associations-of base)))
         (work-item (find "ward-hub-trail-selection" (tm:topicmap-projection-topics-of (work:work-projection))
                          :key #'tm:topicmap-topic-id-of :test #'equal)))
    (assert work-item)
    (labels ((topic (id label object kind)
               (let ((index (length topics)))
                 (setf topics (append topics (list (tm:make-topicmap-topic :id id :label label :object object :type :hub-learning
                  :view-properties (list :x (* 280 (mod index 4)) :y (* 110 (floor index 4)) :visible t :kind kind)))))))
             (edge (from relation to source)
               (setf edges (append edges (list (tm:make-topicmap-association :id (format nil "hubs:~A:~A:~A" from relation to)
                    :type relation :from from :to to :properties (list :warrant :derived :source source)))))))
      (topic "ward-hub-trail-selection" "Identify Ward's Hub Selection and Trail" work-item "open work item")
      (topic "investigation-plan" "Our investigation plan" *hub-investigation-plan* "investigation plan")
      (edge "ward-hub-trail-selection" :contains "investigation-plan" work-item)
      (dolist (id '("P1" "P2" "P3"))
        (let ((evidence-id (format nil "~A-evidence" id)) (step (hub-investigation-step id)) (finding (hub-investigation-finding id)))
          (topic id (investigation-step-title step) step "investigation step")
          (topic evidence-id (format nil "~A retained evidence / open attribution" id) finding "evidence finding")
          (edge "investigation-plan" :contains id *hub-investigation-plan*)
          (edge id :references evidence-id step)
          (edge evidence-id :references "capture" finding)))
      (edge "P1-evidence" :compares-with "hubs" (hub-investigation-finding "P1"))
      (edge "P2-evidence" :references "solo-sources" (hub-investigation-finding "P2"))
      (edge "P3-evidence" :references "report" (hub-investigation-finding "P3"))
      (tm:make-topicmap-projection :source (tm:topicmap-projection-source-of base)
          :topics topics :associations edges :view-properties '(:width 1180 :height 880)))))
