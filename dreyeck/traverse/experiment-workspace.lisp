;;;; Experiment and Implementation Projections

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "What Did Ward Propose?" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "How Were Discourse Relations Collected?" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From WALK to TRAVERSE" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "Reading an Actual Discourse Graph" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "What Remains to Be Demonstrated?" :hyperbook "dreyeck/traverse/reading"))

(defparameter +discourse-statuses+
  '(:observed :observed-link :documented-history :derived-from-pagefold :recorded-execution
    :asserted-unverified :not-demonstrated)
  "Warrant statuses of the experiment's projections. :observed — present in a retained page or source;
:observed-link — a Wiki link written in a retained story item; :documented-history — a journal entry of a
retained page; :derived-from-pagefold — an edge EXTRACT computed from a fold label; :recorded-execution —
recorded by the replay; :asserted-unverified — a claim about the subject matter that nothing here checks;
:not-demonstrated — asked for, and not shown by anything retained.")

(defclass open-statement ()
  ((statement :initarg :statement :reader statement-text)
   (status :initarg :status :reader statement-status)
   (basis :initarg :basis :reader statement-basis)
   (evidence :initarg :evidence :reader statement-evidence))
  (:documentation "A statement the reading keeps visible without treating it as established."))

(defun first-step-with (item token)
  "The first journal entry of ITEM whose text contains TOKEN."
  (or (find-if (lambda (step) (and (step-text step) (search token (step-text step)))) (item-steps item))
      (error "No journal entry of ~A contains ~S" (item-id item) token)))

(defun discourse-projection (source topics relations)
  "PROJECTION of the technical reading, held to this reading's warrant statuses."
  (let ((+statuses+ +discourse-statuses+))
    (projection source topics relations)))

(defvar *answer* nil)
(defvar *federation* nil)

(defun answer-assertion ()
  (or *answer*
      (setf *answer*
            (make-instance 'open-statement
                           :statement "A Wiki Page Can Represent a Claim answers the question Can a Wiki Page Represent a Claim?"
                           :status :asserted-unverified
                           :basis "The claim page says a page can serve as a proposed answer; the link under Claims places it. Whether it answers the question is not checked here."
                           :evidence (dg-item "a-wiki-page-can-represent-a-claim" "d990cc896d52c726")))))

(defun federation-gap ()
  (or *federation*
      (setf *federation*
            (make-instance 'open-statement
                           :statement "Discourse relations are processed across cooperating federated Wiki sites."
                           :status :not-demonstrated
                           :basis "Every replay ran in one neighborhood, discourse.dreyeck.ch. Links from Zach's Lineup name another site and stay unresolved; NEIGHBORS discourse keeps only domains containing \"discourse\"."
                           :evidence (cross-site-question)))))

(defun experiment-projection ()
  (let* ((ward (wiki-page-of "ward.dojo.fed.wiki" "discourse-graphs"))
         (w (lambda (id) (wiki-item-of "ward.dojo.fed.wiki" "discourse-graphs" id)))
         (p (lambda (slug) (wiki-page-of "discourse.dreyeck.ch" slug)))
         (dg (funcall p "discourse-graphs"))
         (walk (dg-item "discourse-graphs" "44fac82ef4111fc2"))
         (trav (dg-item "discourse-graphs" "268693278cf3e65b"))
         (fork (find "ward.dojo.fed.wiki" (page-forks dg) :key #'step-site :test #'equal))
         (s-ward (first-step-with walk "ClaimLinkSurvey"))
         (s-extract (first-step-with walk "EXTRACT"))
         (s-edges (first-step-with walk "EDGES"))
         (s-survey (first-step-with walk "Claim Link Survey"))
         (s-traverse (first-step-with trav "TRAVERSE"))
         (claim-edge (edge-between "discourse.dreyeck.ch+can-a-wiki-page-represent-a-claim" "claim"
                                   "discourse.dreyeck.ch+a-wiki-page-can-represent-a-claim"))
         (survey-edge (edge-between "discourse.dreyeck.ch+how-i-use-my-wiki" "claim" "discourse.dreyeck.ch+claim-link-survey")))
    (discourse-projection
     (experiment-snapshot)
     (list (list "ward:page" "Ward: Discourse Graphs" ward :observed)
           (list "ward:proposal" "distributed graph across federated sites" (funcall w "31bd93ad173f651c") :observed)
           (list "ward:survey" "ClaimLinkSurvey proposal" (funcall w "12bff3a6dc2858a9") :observed)
           (list "ward:walk" "WALK extension proposal" (funcall w "79996e4ee54798bc") :observed)
           (list "ward:mech" "Mech program by Ward" (funcall w "44fac82ef4111fc2") :observed)
           (list "ward:stage-two" "stage two: the probe" (funcall w "8e619a6f86d55cd5") :observed)
           (list "ward:stage-three" "stage three: WALK functions" (funcall w "688d96db5d86ef13") :observed)
           (list "dg:page" "discourse.dreyeck.ch: Discourse Graphs" dg :observed)
           (list "dg:fork" "fork from ward.dojo.fed.wiki" fork :documented-history)
           (list "dg:roster" "roster" (dg-item "discourse-graphs" "bbaf2c391987718a") :observed)
           (list "step:walk-ward" "program as Ward wrote it" s-ward :documented-history)
           (list "step:walk-extract" "EXTRACT added" s-extract :documented-history)
           (list "step:walk-edges" "EDGES added" s-edges :documented-history)
           (list "step:walk-survey" "Claim Link Survey under NEIGHBORS" s-survey :documented-history)
           (list "dg:mech-walk" "role-WALK program now" walk :observed)
           (list "step:traverse-added" "TRAVERSE program written" s-traverse :documented-history)
           (list "dg:mech-traverse" "TRAVERSE program now" trav :observed)
           (list "tpl:page" "Claim Template" (funcall p "claim-template") :observed)
           (list "tpl:claim-fold" "template fold claim" (dg-item "claim-template" "29c28902048db774") :observed)
           (list "probe:page" "Claim Link Survey Probe" (funcall p "claim-link-survey-probe") :observed)
           (list "probe:frame" "probe launch frame" (dg-item "claim-link-survey-probe" "9454d527598e4c32") :observed)
           (list "probe:remark" "WALK as selector (z8099)" (dg-item "claim-link-survey-probe" "02516bef95b6c7ac") :observed)
           (list "survey:page" "Claim Link Survey" (funcall p "claim-link-survey") :observed)
           (list "survey:frame" "stored survey" (dg-item "claim-link-survey" "99228553003555422208") :observed)
           (list "hiumw:page" "How I Use My Wiki" (funcall p "how-i-use-my-wiki") :observed)
           (list "hiumw:claim-fold" "fold claim" (dg-item "how-i-use-my-wiki" "29c28902048db774") :observed)
           (list "hiumw:survey-link" "[[Claim Link Survey]]" (dg-item "how-i-use-my-wiki" "adc19b81ea613b59") :observed)
           (list "q:page" "Can a Wiki Page Represent a Claim?" (funcall p "can-a-wiki-page-represent-a-claim") :observed)
           (list "q:fold" "pagefold Claims" (dg-item "can-a-wiki-page-represent-a-claim" "7324b5ac4d729ea7") :observed)
           (list "q:link" "[[A Wiki Page Can Represent a Claim]]" (dg-item "can-a-wiki-page-represent-a-claim" "c790b11985cb2099") :observed)
           (list "q:mech" "TRAVERSE claim program" (dg-item "can-a-wiki-page-represent-a-claim" "fef098721ab66a3c") :observed)
           (list "c:page" "A Wiki Page Can Represent a Claim" (funcall p "a-wiki-page-can-represent-a-claim") :observed)
           (list "c:statement" "paragraph of the claim" (dg-item "a-wiki-page-can-represent-a-claim" "d990cc896d52c726") :observed)
           (list "assert:answer" "answers the question (unverified)" (answer-assertion) :asserted-unverified)
           (list "fed:open" "processing across sites (not demonstrated)" (federation-gap) :not-demonstrated))
     (list (list "ward:page" "ward:proposal" "contains" :observed "story item 31bd93ad173f651c" ward)
           (list "ward:page" "ward:survey" "contains" :observed "story item 12bff3a6dc2858a9" ward)
           (list "ward:page" "ward:walk" "contains" :observed "story item 79996e4ee54798bc" ward)
           (list "ward:page" "ward:mech" "contains" :observed "story item 44fac82ef4111fc2" ward)
           (list "ward:page" "ward:stage-two" "contains" :observed "story item 8e619a6f86d55cd5" ward)
           (list "ward:page" "ward:stage-three" "contains" :observed "story item 688d96db5d86ef13" ward)
           (list "dg:page" "dg:fork" "journal entry" :documented-history "a fork entry of the page's journal" fork)
           (list "dg:fork" "ward:page" "forked from" :documented-history "fork from ward.dojo.fed.wiki, 2025-11-26" fork)
           (list "ward:mech" "step:walk-ward" "same item id, first text" :documented-history "item 44fac82ef4111fc2 keeps its id; the journal holds Ward's text" s-ward)
           (list "step:walk-ward" "step:walk-extract" "edited to" :documented-history "journal edit of item 44fac82ef4111fc2" s-extract)
           (list "step:walk-extract" "step:walk-edges" "edited to" :documented-history "journal edit of item 44fac82ef4111fc2" s-edges)
           (list "step:walk-edges" "step:walk-survey" "edited to" :documented-history "journal edit of item 44fac82ef4111fc2" s-survey)
           (list "step:walk-survey" "dg:mech-walk" "edited to the current text" :documented-history "later edits of the same item" walk)
           (list "dg:page" "dg:mech-walk" "contains" :observed "story item 44fac82ef4111fc2" dg)
           (list "dg:page" "dg:roster" "contains" :observed "story item bbaf2c391987718a" dg)
           (list "dg:page" "dg:mech-traverse" "contains" :observed "story item 268693278cf3e65b" dg)
           (list "step:traverse-added" "dg:mech-traverse" "written as" :documented-history "journal edit, 2026-10-20" s-traverse)
           (list "dg:page" "tpl:page" "links to" :observed-link "[[Claim Template]] in story item 31bd93ad173f651c" (dg-item "discourse-graphs" "31bd93ad173f651c"))
           (list "dg:page" "probe:page" "links to" :observed-link "[[Claim Link Survey Probe]] in story item e8f376c3cf5f1221" (dg-item "discourse-graphs" "e8f376c3cf5f1221"))
           (list "tpl:page" "tpl:claim-fold" "contains" :observed "story item 29c28902048db774" (funcall p "claim-template"))
           (list "hiumw:claim-fold" "tpl:claim-fold" "same item id as" :observed "item id 29c28902048db774 occurs on both pages" (dg-item "how-i-use-my-wiki" "29c28902048db774"))
           (list "hiumw:page" "hiumw:claim-fold" "contains" :observed "story item 29c28902048db774" (funcall p "how-i-use-my-wiki"))
           (list "hiumw:page" "hiumw:survey-link" "contains" :observed "story item adc19b81ea613b59 under the fold claim" (funcall p "how-i-use-my-wiki"))
           (list "hiumw:survey-link" "survey:page" "links to" :observed-link "[[Claim Link Survey]]" (dg-item "how-i-use-my-wiki" "adc19b81ea613b59"))
           (list "hiumw:page" "survey:page" "claim" :derived-from-pagefold "EXTRACT edge with the role of the fold claim" survey-edge)
           (list "probe:page" "probe:frame" "contains" :observed "story item 9454d527598e4c32" (funcall p "claim-link-survey-probe"))
           (list "probe:page" "probe:remark" "contains" :observed "story item 02516bef95b6c7ac" (funcall p "claim-link-survey-probe"))
           (list "probe:page" "survey:page" "links to" :observed-link "[[Claim Link Survey]] in story item 955c2422f1c17bea" (dg-item "claim-link-survey-probe" "955c2422f1c17bea"))
           (list "survey:page" "survey:frame" "contains" :observed "frame item with the stored survey array" (funcall p "claim-link-survey"))
           (list "survey:frame" "probe:frame" "names the probe of" :observed "update.html?probe=ClaimLinkSurveyProbe&version=1" (dg-item "claim-link-survey" "99228553003555422208"))
           (list "dg:mech-walk" "survey:page" "reads the survey of" :observed "NEIGHBORS discourse with the body Claim Link Survey" walk)
           (list "q:page" "q:fold" "contains" :observed "story item 7324b5ac4d729ea7" (funcall p "can-a-wiki-page-represent-a-claim"))
           (list "q:page" "q:link" "contains" :observed "story item c790b11985cb2099 after the fold" (funcall p "can-a-wiki-page-represent-a-claim"))
           (list "q:page" "q:mech" "contains" :observed "story item fef098721ab66a3c" (funcall p "can-a-wiki-page-represent-a-claim"))
           (list "q:link" "c:page" "links to" :observed-link "[[A Wiki Page Can Represent a Claim]]" (dg-item "can-a-wiki-page-represent-a-claim" "c790b11985cb2099"))
           (list "q:page" "c:page" "claim" :derived-from-pagefold "EXTRACT edge with the role of the fold Claims" claim-edge)
           (list "c:page" "c:statement" "contains" :observed "story item d990cc896d52c726" (funcall p "a-wiki-page-can-represent-a-claim"))
           (list "c:statement" "assert:answer" "states" :asserted-unverified "the paragraph's own claim; not checked" (answer-assertion))
           (list "assert:answer" "q:page" "would answer" :asserted-unverified "a claim about the subject matter, not a relation the software computes" (answer-assertion))
           (list "ward:proposal" "fed:open" "asks for" :not-demonstrated "cooperating federated sites; no retained run crossed sites" (federation-gap))
           (list "dg:roster" "fed:open" "lists a second site for" :not-demonstrated "the roster names wow.dreyeck.ch; NEIGHBORS discourse drops it" (discourse-source "upstream:neighborhood"))))))

(defun implementation-projection ()
  (let* ((s (lambda (key) (discourse-source key)))
         (p (lambda (slug) (wiki-page-of "discourse.dreyeck.ch" slug)))
         (claim (claim-traversal))
         (failed (failed-traversal))
         (walk (role-walk-selection))
         (cross (cross-site-question))
         (edge (edge-between "discourse.dreyeck.ch+can-a-wiki-page-represent-a-claim" "claim"
                             "discourse.dreyeck.ch+a-wiki-page-can-represent-a-claim"))
         (graph (gethash "graph" (gethash "exported" (case-value claim))))
         (batch (first (case-solo claim))))
    (discourse-projection
     (discourse-replay)
     (list (list "q:page" "Can a Wiki Page Represent a Claim?" (funcall p "can-a-wiki-page-represent-a-claim") :observed)
           (list "q:fold" "pagefold Claims" (dg-item "can-a-wiki-page-represent-a-claim" "7324b5ac4d729ea7") :observed)
           (list "q:link" "[[A Wiki Page Can Represent a Claim]]" (dg-item "can-a-wiki-page-represent-a-claim" "c790b11985cb2099") :observed)
           (list "q:mech" "TRAVERSE claim program" (dg-item "can-a-wiki-page-represent-a-claim" "fef098721ab66a3c") :observed)
           (list "c:page" "A Wiki Page Can Represent a Claim" (funcall p "a-wiki-page-can-represent-a-claim") :observed)
           (list "dg:page" "discourse.dreyeck.ch: Discourse Graphs" (funcall p "discourse-graphs") :observed)
           (list "dg:mech-walk" "role-WALK program now" (dg-item "discourse-graphs" "44fac82ef4111fc2") :observed)
           (list "dg:mech-traverse" "TRAVERSE program now" (dg-item "discourse-graphs" "268693278cf3e65b") :observed)
           (list "survey:page" "Claim Link Survey" (funcall p "claim-link-survey") :observed)
           (list "src:click" "click_emit" (funcall s "upstream:click_emit") :observed)
           (list "src:neighborhood" "neighborhood(want)" (funcall s "upstream:neighborhood") :observed)
           (list "src:neighbors" "neighbors_emit" (funcall s "upstream:neighbors_emit") :observed)
           (list "src:extract-emit" "extract_emit" (funcall s "composition:extract_emit") :observed)
           (list "src:extract" "extract_edges_from_story" (funcall s "composition:extract_edges_from_story") :observed)
           (list "src:links" "parse_links" (funcall s "composition:parse_links") :observed)
           (list "src:fold" "canonicalize_fold" (funcall s "composition:canonicalize_fold") :observed)
           (list "src:walk" "walk_emit (upstream)" (funcall s "upstream:walk_emit") :observed)
           (list "src:role-walk" "role_walk_emit" (funcall s "composition:role_walk_emit") :observed)
           (list "src:install" "installDiscourse" (funcall s "composition:installDiscourse") :observed)
           (list "src:traverse-emit" "traverse_emit" (funcall s "composition:traverse_emit") :observed)
           (list "src:root" "rootOf" (funcall s "composition:rootOf") :observed)
           (list "src:resolve" "resolveEdges" (funcall s "composition:resolveEdges") :observed)
           (list "src:traverse" "traverse" (funcall s "composition:traverse") :observed)
           (list "src:present" "presentGraph" (funcall s "composition:presentGraph") :observed)
           (list "src:solo" "solo_emit" (funcall s "upstream:solo_emit") :observed)
           (list "src:probe" "probe analysePage" (funcall s "probe:analysePage") :observed)
           (list "run:claim" "replay: TRAVERSE claim" claim :recorded-execution)
           (list "run:failed" "replay: TRAVERSE on Discourse Graphs" failed :recorded-execution)
           (list "run:walk" "replay: role WALK" walk :recorded-execution)
           (list "run:cross" "constructed: zachs-lineup" cross :recorded-execution)
           (list "edge:claim" "extracted edge claim" edge :derived-from-pagefold)
           (list "res:claim" "target resolution" (edge-resolution edge) :recorded-execution)
           (list "graph:claim" "presented graph" graph :recorded-execution)
           (list "solo:claim" "SOLO batch" batch :recorded-execution)
           (list "cmp:collection" "survey, probe and EXTRACT compared" (collection-comparison) :recorded-execution)
           (list "fed:open" "processing across sites (not demonstrated)" (federation-gap) :not-demonstrated))
     (list (list "q:page" "q:mech" "contains" :observed "story item fef098721ab66a3c" (funcall p "can-a-wiki-page-represent-a-claim"))
           (list "q:mech" "run:claim" "replayed as" :recorded-execution "the item's program, replayed with the tested bundle" claim)
           (list "src:click" "run:claim" "runs the indented blocks of" :observed "click_emit registers a handler that runs its body" (funcall s "upstream:click_emit"))
           (list "src:neighborhood" "src:neighbors" "called by" :observed "state.api.neighborhood(args[0])" (funcall s "upstream:neighbors_emit"))
           (list "src:neighbors" "run:claim" "selects the neighborhood of" :recorded-execution "NEIGHBORS discourse ⇒ 110 pages, 1 sites" claim)
           (list "src:extract-emit" "src:extract" "calls" :observed "extract_emit fetches each page and extracts its edges" (funcall s "composition:extract_emit"))
           (list "q:fold" "edge:claim" "role from fold label" :derived-from-pagefold "Claims canonicalized to claim" (funcall s "composition:canonicalize_fold"))
           (list "q:link" "edge:claim" "read by" :derived-from-pagefold "parse_links reads [[A Wiki Page Can Represent a Claim]]" (funcall s "composition:parse_links"))
           (list "src:fold" "edge:claim" "defines the role of" :observed "canonicalize_fold" (funcall s "composition:canonicalize_fold"))
           (list "src:links" "edge:claim" "defines the target of" :observed "parse_links" (funcall s "composition:parse_links"))
           (list "src:extract" "edge:claim" "defines" :observed "extract_edges_from_story" (funcall s "composition:extract_edges_from_story"))
           (list "edge:claim" "res:claim" "resolved as" :recorded-execution "the target is listed in the sitemap of its declared site" claim)
           (list "src:resolve" "res:claim" "defines" :observed "resolveEdges" (funcall s "composition:resolveEdges"))
           (list "res:claim" "run:claim" "traversed in" :recorded-execution "TRAVERSE claim ⇒ 1 relations, 2 nodes, 0 unresolved" claim)
           (list "src:traverse-emit" "run:claim" "defines TRAVERSE of" :observed "traverse_emit" (funcall s "composition:traverse_emit"))
           (list "src:root" "run:claim" "names the root of" :observed "the page that holds the Mech item" (funcall s "composition:rootOf"))
           (list "src:traverse" "run:claim" "defines the traversal of" :observed "traverse, breadth-first over listed roles" (funcall s "composition:traverse"))
           (list "run:claim" "graph:claim" "presents" :recorded-execution "the exported presentGraph agrees with the block's aspect" claim)
           (list "src:present" "graph:claim" "defines" :observed "presentGraph" (funcall s "composition:presentGraph"))
           (list "graph:claim" "c:page" "has a node for" :recorded-execution "WikiPage discourse.dreyeck.ch/a-wiki-page-can-represent-a-claim" claim)
           (list "graph:claim" "solo:claim" "handed over as" :recorded-execution "the batch carries the TRAVERSE aspect" claim)
           (list "src:solo" "solo:claim" "defines" :observed "solo_emit posts the batch" (funcall s "upstream:solo_emit"))
           (list "dg:page" "dg:mech-traverse" "contains" :observed "story item 268693278cf3e65b" (funcall p "discourse-graphs"))
           (list "dg:mech-traverse" "run:failed" "replayed as" :recorded-execution "the item's program, replayed with the tested bundle" failed)
           (list "dg:page" "run:failed" "is a root without typed edges in" :recorded-execution "no question, claim, support or oppose fold on the page" failed)
           (list "src:root" "run:failed" "names the root of" :observed "the page that holds the Mech item" (funcall s "composition:rootOf"))
           (list "dg:page" "dg:mech-walk" "contains" :observed "story item 44fac82ef4111fc2" (funcall p "discourse-graphs"))
           (list "dg:mech-walk" "run:walk" "replayed as" :recorded-execution "the item's program, replayed with the tested bundle" walk)
           (list "src:install" "src:role-walk" "routes role ways to" :observed "installDiscourse wraps WALK" (funcall s "composition:installDiscourse"))
           (list "src:install" "src:walk" "keeps for other ways" :observed "originalWalk for steps, days, hubs and the other ways" (funcall s "composition:installDiscourse"))
           (list "src:role-walk" "run:walk" "defines" :observed "role_walk_emit and walks" (funcall s "composition:role_walk_emit"))
           (list "survey:page" "run:walk" "survey fields merged by NEIGHBORS in" :recorded-execution "102 neighborhood pages received survey fields" walk)
           (list "survey:page" "src:probe" "names the probe" :observed "update.html?probe=ClaimLinkSurveyProbe&version=1" (dg-item "claim-link-survey" "99228553003555422208"))
           (list "survey:page" "cmp:collection" "stored survey compared in" :recorded-execution "totals of the survey stored on 2026-01-21" (collection-comparison))
           (list "src:probe" "cmp:collection" "applied to the snapshot in" :recorded-execution "the served probe over the 110 retained pages" (collection-comparison))
           (list "src:extract" "cmp:collection" "applied to the snapshot in" :recorded-execution "EXTRACT's recorded edges" (collection-comparison))
           (list "run:cross" "fed:open" "leaves unresolved" :not-demonstrated "question targets on wiki.planetnineisaspaceship.com stay unresolved" cross)
           (list "src:neighborhood" "fed:open" "keeps only matching domains for" :not-demonstrated "domain.includes(want): NEIGHBORS discourse drops every site without \"discourse\" in its domain" (funcall s "upstream:neighborhood"))))))

(defun discourse-workspace (&optional (mode :experiment))
  (ecase mode
    (:experiment (tm:make-topicmap-workspace (experiment-projection) "ward:proposal"))
    (:implementation (tm:make-topicmap-workspace (implementation-projection) "q:link"))))

(defun switch-discourse-projection (workspace mode)
  "Reproject the same Workspace; Point and history are kept. Shared ids name the same objects in both."
  (tm:topicmap-workspace-reproject
   workspace
   (ecase mode
     (:experiment (experiment-projection))
     (:implementation (implementation-projection))))
  workspace)

(hyperdoc:defexample experiment-workspace
  "Experiment/History: Ward's proposal, the Wiki pages, their story items and documented development steps."
  (discourse-workspace :experiment))

(hyperdoc:defexample implementation-workspace
  "Implementation/Execution: JavaScript definitions, Mech operations, extracted edges, traversal and SOLO output."
  (discourse-workspace :implementation))

(defmethod v:text-representation ((statement open-statement))
  (format nil "~A (~(~A~))" (statement-text statement) (statement-status statement)))

(v:defview open-statement-view (statement open-statement)
  (v:html-view :title "Open statement" :priority 0
    (v:html
      (:h3 (cl-who:esc (statement-text statement)))
      (:p (:strong "Status: ") (cl-who:esc (string-downcase (statement-status statement))))
      (:p (cl-who:esc (statement-basis statement)))
      (:p (v:object-ref (statement-evidence statement) :display "What the reading has instead"))
      (discourse-links))))

(dolist (name '(experiment-snapshot discourse-replay failed-traversal claim-traversal role-walk-selection
                cross-site-question claim-reading-path collection-comparison
                experiment-workspace implementation-workspace))
  (dreyeck/authority-policy:register-operation-contract
   :identity (format nil "traverse/~(~A~)" name)
   :operation (format nil "DREYECK/TRAVERSE::~A" name)
   :applicability :example
   :status :contracted
   :effect-classes '(:observational)
   :effect-extent "Read hash-verified retained Wiki pages, assets and the recorded replay; allocate page, item, edge and Workspace objects."
   :authority "Wiki pages retained on 2026-10-21; a replay recorded with the tested bundle"
   :preconditions "dreyeck/traverse/reading loaded"
   :postconditions "No process, network request, Wiki or server is touched"
   :verification-evidence "dreyeck/traverse/reading/tests"
   :replay-semantics "Fresh Lisp inspection; no Mech execution, no fetch"
   :audit-provenance "Discourse Graph experiment reading, 2026-10-21"))
