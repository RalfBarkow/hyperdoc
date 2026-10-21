;;;; Replaying Mech on the Retained Pages

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "How Were Discourse Relations Collected?" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From WALK to TRAVERSE" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "Reading an Actual Discourse Graph" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "What Remains to Be Demonstrated?" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "What Did Ward Propose?" :hyperbook "dreyeck/traverse/reading"))

;;; The replay is a local execution, recorded once: the tested bundle ran the Mech items of four retained
;;; pages in Node, with every page served from the snapshot and the network disabled. Reading it runs
;;; nothing. It is not an observation of the production Wiki in a browser; none was supplied.

(defclass discourse-replay ()
  ((snapshot :initarg :snapshot :reader replay-snapshot)
   (value :initarg :value :reader replay-value)
   (cases :initform nil :accessor replay-cases)
   (edges :initform nil :accessor replay-edges))
  (:documentation "The recorded replay of Mech items of the retained pages, with its extracted edges."))

(defclass replay-case ()
  ((replay :initarg :replay :reader case-replay)
   (name :initarg :name :reader case-name)
   (page :initarg :page :reader case-page :documentation "The page that holds the Mech item; TRAVERSE's root.")
   (item :initarg :item :reader case-item :documentation "The Mech story item, or NIL for a constructed case.")
   (value :initarg :value :reader case-value)
   (outcome :initarg :outcome :reader case-outcome
            :documentation ":traversed, :no-relations, :selected (role WALK) or :constructed."))
  (:documentation "One Mech item replayed, or one computation constructed from the recorded edges."))

(defclass extracted-edge ()
  ((replay :initarg :replay :reader edge-replay)
   (from-id :initarg :from-id :reader edge-from-id)
   (to-id :initarg :to-id :reader edge-to-id)
   (role :initarg :role :reader edge-role)
   (value :initarg :value :reader edge-value)
   (resolution :initarg :resolution :reader edge-resolution :documentation "The recorded resolveEdges entry.")
   (origins :initarg :origins :reader edge-origins
            :documentation "Story items this reading finds behind the edge; EXTRACT itself does not record them."))
  (:documentation "An edge EXTRACT derived from a pagefold, as recorded by the replay."))

(defclass path-step ()
  ((name :initarg :name :reader step-name)
   (value :initarg :value :reader path-value)
   (source :initarg :source :initform nil :reader path-source)
   (status :initarg :status :reader path-status)
   (note :initarg :note :reader path-note))
  (:documentation "One step of a reading path from a story item to the SOLO batch."))

(defun target-status (edge) (gethash "status" (gethash "target" (edge-resolution edge))))
(defun page-id (page) (format nil "~A+~A" (page-site page) (page-slug page)))

(defun load-replay ()
  (let* ((snapshot (experiment-snapshot))
         (value (read-json "discourse/replay-run.json"))
         (replay (make-instance 'discourse-replay :snapshot snapshot :value value))
         (extracted (gethash "extracted" value))
         (bundle (getf (package-chain) :bundle)))
    (unless (and (zerop (gethash "networkAttempts" value))
                 (equal bundle (gethash "sha256" (gethash "bundle" value)))
                 (equal bundle (gethash "bundle" (gethash "replay" (snapshot-manifest snapshot)))))
      (error "The replay is not of the tested bundle, or it reached the network"))
    (setf (replay-edges replay)
          (loop for edge across (gethash "edges" extracted)
                for resolution across (gethash "resolved" extracted)
                collect (make-instance 'extracted-edge
                                       :replay replay :from-id (gethash "fromId" edge) :to-id (gethash "toId" edge)
                                       :role (gethash "role" edge) :value edge :resolution resolution
                                       :origins (edge-origin-items (gethash "fromId" edge) (gethash "role" edge)
                                                                   (gethash "toId" edge)))))
    (setf (replay-cases replay)
          (append
           (loop for run across (gethash "runs" value)
                 for page-json = (gethash "page" run)
                 for item = (wiki-item-of (gethash "site" page-json) (gethash "slug" page-json)
                                          (gethash "id" (gethash "item" run)))
                 do (unless (equal (item-text item) (gethash "text" (gethash "item" run)))
                      (error "The replayed program is not the retained item ~A" (item-id item)))
                    (unless (equal (gethash "sha256" extracted) (gethash "edgesSha256" (gethash "discourse" run)))
                      (error "Replay ~A extracted other edges" (gethash "name" run)))
                    (when (gethash "exported" run)
                      (unless (gethash "traverseAgrees" (gethash "exported" run))
                        (error "TRAVERSE and the exported traverse disagree in ~A" (gethash "name" run))))
                 collect (make-instance 'replay-case
                                        :replay replay :name (gethash "name" run) :page (item-page item)
                                        :item item :value run
                                        :outcome (cond ((and (gethash "traversal" run)
                                                             (plusp (length (gethash "edges" (gethash "traversal" run)))))
                                                        :traversed)
                                                       ((gethash "traversal" run) :no-relations)
                                                       (t :selected))))
           (let ((constructed (gethash "constructed" value)))
             (list (make-instance 'replay-case
                                  :replay replay :name (gethash "name" constructed)
                                  :page (wiki-page-of "discourse.dreyeck.ch" "zachs-lineup")
                                  :item nil :value constructed :outcome :constructed)))))
    replay))

(defvar *replay* nil)

(hyperdoc:defexample discourse-replay
  "Read the recorded replay of four Mech items on the retained pages; nothing is run."
  (or *replay* (setf *replay* (load-replay))))

(defun replay-case-named (name)
  (or (find name (replay-cases (discourse-replay)) :key #'case-name :test #'equal)
      (error "No replay case ~S" name)))

(hyperdoc:defexample failed-traversal
  "TRAVERSE from Discourse Graphs: the page has no question, claim, support or oppose fold, so no relation starts there."
  (replay-case-named "discourse-graphs TRAVERSE"))

(hyperdoc:defexample claim-traversal
  "TRAVERSE claim from Can a Wiki Page Represent a Claim?: one relation, resolved, handed to SOLO."
  (replay-case-named "can-a-wiki-page-represent-a-claim TRAVERSE"))

(hyperdoc:defexample role-walk-selection
  "The role WALK on Discourse Graphs: pages selected by role, each with its sitemap neighbors."
  (replay-case-named "discourse-graphs role WALK"))

(hyperdoc:defexample cross-site-question
  "Constructed from the recorded edges: question links from Zach's Lineup to another site stay unresolved."
  (replay-case-named "zachs-lineup question, exported functions"))

(defun case-statuses (case) (coerce (or (gethash "statuses" (case-value case)) (vector)) 'list))
(defun case-troubles (case)
  (map 'list (lambda (trouble) (gethash "message" trouble)) (or (gethash "troubles" (case-value case)) (vector))))
(defun case-traversal-edges (case)
  (let ((value (case-value case)))
    (coerce (or (if (eq :constructed (case-outcome case))
                    (gethash "edges" value)
                    (and (gethash "traversal" value) (gethash "edges" (gethash "traversal" value))))
                (vector))
            'list)))
(defun case-solo (case) (coerce (or (gethash "solo" (case-value case)) (vector)) 'list))

(defun edge-between (from-id role to-id)
  (or (find-if (lambda (edge) (and (equal from-id (edge-from-id edge)) (equal role (edge-role edge))
                                   (equal to-id (edge-to-id edge))))
               (replay-edges (discourse-replay)))
      (error "No extracted edge ~A ~A ~A" from-id role to-id)))

(defun edges-from (page)
  (remove-if-not (lambda (edge) (equal (page-id page) (edge-from-id edge))) (replay-edges (discourse-replay))))

(hyperdoc:defexample claim-reading-path
  "From the Claims pagefold and its story item, through the extracted edge, its resolution, TRAVERSE and SOLO."
  (let* ((case (claim-traversal))
         (question (case-page case))
         (fold (dg-item "can-a-wiki-page-represent-a-claim" "7324b5ac4d729ea7"))
         (link (dg-item "can-a-wiki-page-represent-a-claim" "c790b11985cb2099"))
         (edge (edge-between (page-id question) "claim" "discourse.dreyeck.ch+a-wiki-page-can-represent-a-claim"))
         (traversal (gethash "traversal" (case-value case)))
         (batch (first (case-solo case))))
    (list
     (make-instance 'path-step :name "Claims pagefold" :value fold :status :observed
                    :source (discourse-source "composition:canonicalize_fold")
                    :note "A pagefold whose text is \"Claims\"; normalize_fold and canonicalize_fold make it the role claim.")
     (make-instance 'path-step :name "story item with the link" :value link :status :observed-link
                    :source (discourse-source "composition:parse_links")
                    :note "The paragraph [[A Wiki Page Can Represent a Claim]] under that fold: an observed Wiki link.")
     (make-instance 'path-step :name "extracted edge" :value edge :status :derived-from-pagefold
                    :source (discourse-source "composition:extract_edges_from_story")
                    :note "EXTRACT's edge: page, role from the fold, target site+slug. It does not name the story item; the reading finds it.")
     (make-instance 'path-step :name "target resolution" :value (edge-resolution edge) :status :recorded-execution
                    :source (discourse-source "composition:resolveEdges")
                    :note "The target is listed in the sitemap of its declared site, so resolveEdges marks it resolved.")
     (make-instance 'path-step :name "TRAVERSE result" :value traversal :status :recorded-execution
                    :source (discourse-source "composition:traverse_emit")
                    :note "From the root, the page holding the Mech item, traverse follows claim edges: one relation, 2 nodes, 0 unresolved.")
     (make-instance 'path-step :name "presented graph" :value (gethash "graph" (gethash "exported" (case-value case)))
                    :status :recorded-execution :source (discourse-source "composition:presentGraph")
                    :note "Two WikiPage nodes named site/slug and one relation of type claim.")
     (make-instance 'path-step :name "SOLO batch" :value batch :status :recorded-execution
                    :source (discourse-source "upstream:solo_emit")
                    :note "The batch posted to /plugins/solo/dialog/#. What Solo draws from it is outside this record."))))

(defun survey-totals (replay which)
  (let ((probe (gethash "probe" (replay-value replay))))
    (gethash "totals" (gethash which probe))))

(hyperdoc:defexample collection-comparison
  "The survey stored on 2026-01-21, the probe applied to the snapshot, and EXTRACT on the snapshot, side by side."
  (let* ((replay (discourse-replay))
         (edges (replay-edges replay))
         (count (lambda (role) (count role edges :key #'edge-role :test #'equal))))
    (list :stored-survey (survey-totals replay "storedSurvey")
          :stored-survey-item (dg-item "claim-link-survey" (gethash "item" (gethash "storedSurvey" (gethash "probe" (replay-value replay)))))
          :probe-on-snapshot (survey-totals replay "onSnapshot")
          :extract-on-snapshot (list :pages (count "discourse.dreyeck.ch" (snapshot-pages (experiment-snapshot))
                                                   :key #'page-site :test #'equal)
                                     :edges (length edges)
                                     :question (funcall count "question") :claim (funcall count "claim")
                                     :support (funcall count "support") :oppose (funcall count "oppose"))
          :probe-reads (discourse-source "probe:extractLinksFromItem")
          :extract-reads (discourse-source "composition:parse_links")
          :probe-folds (discourse-source "probe:normalizeFoldName")
          :extract-folds (discourse-source "composition:normalize_fold"))))

;;; Views

(defmethod v:text-representation ((replay discourse-replay))
  "Recorded replay of Mech items on the retained Discourse Graph pages")

(defmethod v:text-representation ((case replay-case))
  (format nil "~A (~(~A~))" (case-name case) (case-outcome case)))

(defmethod v:text-representation ((edge extracted-edge))
  (format nil "~A —~A→ ~A (~A)" (edge-from-id edge) (edge-role edge) (edge-to-id edge) (target-status edge)))

(defmethod v:text-representation ((step path-step))
  (format nil "~A (~(~A~))" (step-name step) (path-status step)))

(v:defview replay-case-view (case replay-case)
  (v:html-view :title "Replay" :priority 0
    (let ((value (case-value case)))
      (v:html
        (:h3 (cl-who:esc (case-name case)))
        (:p (:strong "Outcome: ") (cl-who:esc (string-downcase (case-outcome case)))
            " · " (:strong "Root page: ") (v:object-ref (case-page case) :select "Wiki page" :display (page-title (case-page case))))
        (if (case-item case)
            (v:html (:p (:strong "Mech item: ") (v:object-ref (case-item case) :select "Story item" :display (item-id (case-item case))))
                    (:pre :style "white-space: pre-wrap" (cl-who:esc (item-text (case-item case)))))
            (v:html (:p (cl-who:esc (gethash "note" value)))))
        (:p "Recorded replay of the bundle " (:code "19b14c31…") " in Node on the retained pages, network disabled; "
            "a CLICK was replayed by calling the handler it registered. Read here, not re-run. "
            "No observation of the production Wiki in a browser was supplied.")
        (when (case-statuses case)
          (v:html (:h4 "Status lines") (:ul (dolist (line (case-statuses case)) (v:html (:li (:code (cl-who:esc line))))))))
        (when (case-troubles case)
          (v:html (:h4 "Troubles") (:ul (dolist (line (case-troubles case)) (v:html (:li (:code (cl-who:esc line))))))))
        (when (case-traversal-edges case)
          (v:html (:h4 "Traversed relations")
                  (:ul (dolist (edge (case-traversal-edges case))
                         (v:html (:li (cl-who:esc (format nil "~A —~A→ ~A (~A)" (gethash "fromId" edge) (gethash "role" edge)
                                                          (gethash "toId" edge) (gethash "status" (gethash "target" edge))))))))))
        (when (case-solo case)
          (v:html (:p (v:object-ref (first (case-solo case)) :display "The SOLO batch as captured"))))
        (:p (v:object-ref value :display "The whole recorded case"))
        (discourse-links)))))

(v:defview extracted-edge-view (edge extracted-edge)
  (v:html-view :title "Extracted edge" :priority 0
    (v:html
      (:h3 (cl-who:esc (format nil "~A —~A→ ~A" (edge-from-id edge) (edge-role edge) (edge-to-id edge))))
      (:p (:strong "Status: ") "derived from a pagefold by EXTRACT; target " (cl-who:esc (target-status edge)) " by resolveEdges")
      (:p (:strong "Story items behind it (found by this reading, not recorded by EXTRACT): "))
      (:ul (dolist (item (edge-origins edge))
             (v:html (:li (v:object-ref item :select "Story item" :display (format nil "~A under fold \"~A\"" (item-id item)
                                                                                 (item-text (item-fold item))))))))
      (:p (v:object-ref (edge-value edge) :display "The recorded edge")
          " · " (v:object-ref (edge-resolution edge) :display "Its recorded resolution"))
      (:p (v:object-ref (discourse-source "composition:extract_edges_from_story") :select "Source definition"
                        :display "Defined by extract_edges_from_story"))
      (discourse-links))))

(v:defview path-step-view (step path-step)
  (v:html-view :title "Path step" :priority 0
    (v:html
      (:h3 (cl-who:esc (step-name step)))
      (:p (:strong "Status: ") (cl-who:esc (string-downcase (path-status step))))
      (:p (cl-who:esc (path-note step)))
      (:p (v:object-ref (path-value step) :display "Inspect the object"))
      (when (path-source step)
        (v:html (:p (v:object-ref (path-source step) :select "Source definition"
                                  :display (format nil "Defined by ~A" (n:source-definition (path-source step)))))))
      (discourse-links))))
