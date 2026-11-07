;;;; Federated Wiki link resolution as observed in fedwiki-java b58fb43 (Main.java), modeled with SHOP3.
;;;; Zettel 11483 and 11560. Two policies: COLLABORATIVE (the Java candidate order) and LOCAL-ONLY (Ward's
;;;; defederation: the own site only). SHOP3 plans requests and preparation; nothing here performs HTTP,
;;;; forks or writes. Simulated effects never become observations: a planned fork adds MODELED-LOCAL-PAGE,
;;;; never PAGE-AVAILABLE.

(defpackage #:dreyeck/work/fedwiki-link-resolution
  (:use #:cl)
  (:export #:+reference-revision+ #:java-page-context #:java-panel-context #:java-link-candidates
           #:candidate-facts #:plan-link-resolution #:plan-outcomes #:diagnose-no-plan
           #:load-scenarios #:load-observations #:scenario-link-state #:scenario-plan
           #:link-resolution-experiment #:rule-trace))
(in-package #:dreyeck/work/fedwiki-link-resolution)

(defparameter +reference-revision+ "b58fb43e7ffbbbda66685363dcda1facbd2a46a1")

(defun reference-url (lines)
  (format nil "https://github.com/RalfBarkow/fedwiki-java/blob/~A/Main.java#~A" +reference-revision+ lines))

;;; The candidate order, mirroring Main.java statement by statement. Pure list functions; no I/O.

(defun java-page-context (journal-sites)
  "Page.context(), Main.java L289-L295. JOURNAL-SITES: each journal action's SITE field (or NIL), oldest first.
Walks newest to oldest and keeps the first occurrence of each site. Attribution sites are not read."
  (let ((sites '()))
    (dolist (site (reverse journal-sites) (nreverse sites))
      (when (and site (not (member site sites :test #'equal)))
        (push site sites)))))

(defun java-panel-context (panel-site origin journal-sites)
  "Panel.context(), Main.java L266-L273: a panel from a site other than the origin puts that site first."
  (let ((context (java-page-context journal-sites)))
    (if (equal panel-site origin)
        context
        (cons panel-site (remove panel-site context :test #'equal)))))

(defun java-link-candidates (&key origin panel-site item-site journal-sites)
  "Panel.load(Panel from, String slug), Main.java L225-L255: the origin first, then the item's site, then the panel
context. Returns ((SITE . SOURCE) ...) in request order; SOURCE is :ORIGIN, :ITEM, :PANEL or :JOURNAL, the reason for
the position. The origin is not removed from the context, so it can occur twice (observed: origin-in-context)."
  (let ((context (java-panel-context panel-site origin journal-sites)))
    (when item-site
      (setf context (cons item-site (remove item-site context :test #'equal))))
    (cons (cons origin :origin)
          (mapcar (lambda (site)
                    (cons site (cond ((equal site item-site) :item)
                                     ((and (equal site panel-site) (not (equal panel-site origin))) :panel)
                                     (t :journal))))
                  context))))

(defun candidate-facts (request candidates)
  "SHOP3 facts for CANDIDATES of REQUEST: (CANDIDATE request position site source), the successor relation, the end."
  (append (loop for (site . source) in candidates
                for position from 0
                collect `(candidate ,request ,position ,site ,source)
                collect `(candidate-after ,request ,position ,(1+ position)))
          `((candidates-end ,request ,(length candidates)))))

;;; The domain. Observations: PAGE-AVAILABLE (HTTP 200), PAGE-UNAVAILABLE with its status (any other status),
;;; REQUEST-ERROR (no HTTP answer). A missing observation is unknown and no method treats it as absence.
;;; Every alternative is its own :METHOD, so :WHICH :ALL would expose overlapping alternatives.

(shop3:defdomain (fedwiki-link-resolution :noset t)
  ((:- (availability-conflict ?site ?slug)
    available-and-unavailable ((page-available ?site ?slug) (page-unavailable ?site ?slug ?_status))
    available-and-error ((page-available ?site ?slug) (request-error ?site ?slug))
    unavailable-and-error ((page-unavailable ?site ?slug ?_status) (request-error ?site ?slug)))

   ;; Open model decision, given as an explicit fact: what may serve as the source of a fork.
   (:- (fork-source-ok ?remote ?slug verified-copy ?copy)
    ((fork-source-policy verified-copy-suffices) (verified-copy ?copy ?remote ?slug)))
   (:- (fork-source-ok ?remote ?slug confirmed-remote ?remote)
    ((fork-source-policy require-remote-confirmation) (page-available ?remote ?slug)))

   ;; Primitive steps: planned, never performed.
   (:operator (!request ?request ?site ?slug ?source)
    () () ((planned-request ?request ?site ?slug ?source)))
   (:operator (!open-panel ?request ?site ?slug ?source)
    ((page-available ?site ?slug))
    () ((planned-panel ?request ?site ?slug ?source)))
   (:operator (!use-modeled-page ?request ?site ?slug)
    ((modeled-local-page ?site ?slug))
    () ((planned-hypothetical-panel ?request ?site ?slug)))
   (:operator (!conclude-unresolved ?request ?slug ?policy)
    () () ((planned-unresolved ?request ?slug ?policy)))
   (:operator (!abort-resolution ?request ?site ?slug)
    ((request-error ?site ?slug))
    () ((planned-abort ?request ?site ?slug)))
   (:operator (!plan-fork ?own ?slug ?remote ?kind ?source)
    ((origin ?own) (page-unavailable ?own ?slug ?_status)
     (not (page-available ?own ?slug)) (not (modeled-local-page ?own ?slug))
     (fork-permitted ?own ?remote ?slug) (not (fork-forbidden ?own ?remote ?slug))
     (fork-source-ok ?remote ?slug ?kind ?source))
    () ((modeled-local-page ?own ?slug) (planned-fork ?own ?slug ?remote ?kind ?source)))

   ;; A. Collaborative resolution: walk the candidates in Main.java's order.
   (:method (resolve ?request ?slug collaborative)
    walk-candidates ((candidate ?request 0 ?_site ?_source))
    ((try-candidate ?request ?slug 0)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-has-modeled-page
    ((candidate ?request ?position ?site ?_source) (modeled-local-page ?site ?slug) (not (page-available ?site ?slug)))
    ((!use-modeled-page ?request ?site ?slug)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-available
    ((candidate ?request ?position ?site ?source) (page-available ?site ?slug) (not (availability-conflict ?site ?slug)))
    ((!request ?request ?site ?slug ?source) (!open-panel ?request ?site ?slug ?source)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-unavailable-next
    ((candidate ?request ?position ?site ?source) (page-unavailable ?site ?slug ?_status)
     (not (modeled-local-page ?site ?slug)) (not (availability-conflict ?site ?slug))
     (candidate-after ?request ?position ?next))
    ((!request ?request ?site ?slug ?source) (try-candidate ?request ?slug ?next)))
   (:method (try-candidate ?request ?slug ?position)
    candidate-request-error
    ((candidate ?request ?position ?site ?source) (request-error ?site ?slug) (not (availability-conflict ?site ?slug)))
    ((!request ?request ?site ?slug ?source) (!abort-resolution ?request ?site ?slug)))
   (:method (try-candidate ?request ?slug ?position)
    candidates-exhausted
    ((candidates-end ?request ?position))
    ((!conclude-unresolved ?request ?slug collaborative)))

   ;; B. Local-only resolution: the own site and nothing else; no method reaches TRY-CANDIDATE.
   (:method (resolve ?request ?slug local-only)
    own-site-only ((origin ?own))
    ((try-own-site ?request ?own ?slug)))
   (:method (try-own-site ?request ?own ?slug)
    observed-local
    ((page-available ?own ?slug) (not (availability-conflict ?own ?slug)))
    ((!request ?request ?own ?slug origin) (!open-panel ?request ?own ?slug origin)))
   (:method (try-own-site ?request ?own ?slug)
    modeled-local
    ((modeled-local-page ?own ?slug) (not (page-available ?own ?slug)))
    ((!use-modeled-page ?request ?own ?slug)))
   (:method (try-own-site ?request ?own ?slug)
    missing-locally
    ((page-unavailable ?own ?slug ?_status) (not (modeled-local-page ?own ?slug)) (not (availability-conflict ?own ?slug)))
    ((!request ?request ?own ?slug origin) (!conclude-unresolved ?request ?slug local-only)))
   (:method (try-own-site ?request ?own ?slug)
    own-request-error
    ((request-error ?own ?slug) (not (availability-conflict ?own ?slug)))
    ((!request ?request ?own ?slug origin) (!abort-resolution ?request ?own ?slug)))

   ;; Preparation for defederation: make the target locally available, hypothetically.
   (:method (prepare-local-target ?slug)
    already-observed-local
    ((origin ?own) (page-available ?own ?slug) (not (availability-conflict ?own ?slug)))
    ())
   (:method (prepare-local-target ?slug)
    already-modeled-local
    ((origin ?own) (modeled-local-page ?own ?slug) (not (page-available ?own ?slug)))
    ())
   (:method (prepare-local-target ?slug)
    fork-planned
    ((origin ?own) (page-unavailable ?own ?slug ?_status) (not (modeled-local-page ?own ?slug))
     (not (availability-conflict ?own ?slug))
     (fork-permitted ?own ?remote ?slug) (not (fork-forbidden ?own ?remote ?slug))
     (fork-source-ok ?remote ?slug ?kind ?source))
    ((!plan-fork ?own ?slug ?remote ?kind ?source)))))

;;; Planning entry point and readings of its result.

(defun plan-link-resolution (state tasks &key (domain 'fedwiki-link-resolution) (name (gensym "LINK-RESOLUTION-")))
  "Search all plans with real SHOP3 and return the existing HYPERDOC-HTN-PLAN-RESULT (:PLAN-ONLY).
The problem is registered only for the search and SHOP3:*PROBLEM* is restored. The pinned SHOP3 (ce53f9b) cannot
build a plan tree for a plan with no step (STRIP-TREE-TAGS: NIL is not of type CONS); for that case the search is
repeated without trees and each tree is (:PLAN-TREE-UNAVAILABLE :SHOP3-EMPTY-PLAN-DEFECT), so the four lists stay parallel."
  (let ((shop3::*problem* shop3::*problem*))
    (shop3:make-problem (list name :domain domain :silently t) (copy-tree state) (copy-tree tasks))
    (unwind-protect
         (multiple-value-bind (raw seconds trees states)
             (handler-case (shop3:find-plans name :which :all :verbose 0 :plan-tree t :collect-state t)
               (type-error (condition)
                 (multiple-value-bind (raw seconds trees states)
                     (shop3:find-plans name :which :all :verbose 0 :plan-tree nil :collect-state t)
                   (declare (ignore trees))
                   (unless (member nil raw) (error condition))
                   (values raw seconds (mapcar (constantly '(:plan-tree-unavailable :shop3-empty-plan-defect)) raw) states))))
           (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                          :problem-name name :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                          :time seconds :plan-trees trees :final-states states :execution-mode :plan-only))
      (shop3:delete-problem name))))

(defun %own-site (state) (second (find 'origin state :key #'first)))

(defun plan-outcomes (result state)
  "One reading per plan: the outcome, the planned requests in order, and the simulated facts it adds.
Outcomes: :LOCAL-OBSERVED, :REMOTE-CONTEXT, :MODELED-LOCAL (hypothetical), :NOT-FOUND, :ABORTED-NETWORK-ERROR,
:FORK-PLANNED, :ALREADY-LOCAL-OBSERVED, :ALREADY-MODELED-LOCAL. No plan at all is reported by DIAGNOSE-NO-PLAN."
  (let ((own (%own-site state)))
    (loop for plan in (dreyeck/shop3:plans-of result)
          for final in (dreyeck/shop3:final-states-of result)
          for atoms = (shop3:state-atoms final)
          collect (let* ((steps (mapcar #'first plan))
                         (open (find '!open-panel plan :key #'first)))
                    (list :outcome (cond ((member '!abort-resolution steps) :aborted-network-error)
                                         ((member '!conclude-unresolved steps) :not-found)
                                         ((member '!use-modeled-page steps) :modeled-local)
                                         (open (if (eq (third open) own) :local-observed :remote-context))
                                         ((member '!plan-fork steps) :fork-planned)
                                         ((find `(page-available ,own) atoms :test (lambda (p a) (equal p (subseq a 0 (min 2 (length a))))))
                                          :already-local-observed)
                                         (t :already-modeled-local))
                          :requests (loop for step in plan when (eq (first step) '!request) collect (list (third step) (fourth step)))
                          :resolved-at (and open (third open))
                          :steps steps
                          :simulated (set-difference atoms state :test #'equal))))))

(defun diagnose-no-plan (state request slug policy)
  "Why no plan exists, read directly from STATE (a diagnosis, not a SHOP3 result): the first site whose availability
for SLUG is unknown, or contradictory, in the order the policy would ask."
  (flet ((evidence (site)
           (let ((kinds (loop for atom in state
                              when (and (member (first atom) '(page-available page-unavailable request-error))
                                        (eq (second atom) site) (eq (third atom) slug))
                                collect (first atom))))
             (cond ((null kinds) :unknown) ((rest kinds) :contradictory) (t (first kinds))))))
    (let ((sites (if (eq policy 'local-only)
                     (list (%own-site state))
                     (loop for atom in state
                           when (and (eq (first atom) 'candidate) (eq (second atom) request))
                             collect (cons (third atom) (fourth atom)) into found
                           finally (return (mapcar #'cdr (sort found #'< :key #'car)))))))
      (loop for site in sites
            for evidence = (evidence site)
            when (member evidence '(:unknown :contradictory))
              return (list :evidence-missing-or-contradictory :site site :evidence evidence)
            when (eq evidence 'request-error) return (list :no-diagnosis :site site)
            when (eq evidence 'page-available) return (list :no-diagnosis :site site)
            finally (return (list :no-diagnosis))))))

;;; Fixtures shared with the Java reference run (tests/fedwiki-java-reference/).

(defun %fixture (name) (asdf:system-relative-pathname "dreyeck/work/fedwiki-link-resolution"
                                                       (format nil "tests/fedwiki-java-reference/~A" name)))
(defun %key (string) (intern (string-upcase string) :keyword))

(defun load-scenarios ()
  (let ((json (with-open-file (in (%fixture "scenarios.json") :external-format :utf-8) (shasht:read-json in))))
    (coerce (gethash "scenarios" json) 'list)))

(defun load-observations ()
  "The recorded Java observations, or NIL when observed.json has not been produced."
  (let ((path (%fixture "observed.json")))
    (when (probe-file path)
      (with-open-file (in path :external-format :utf-8) (shasht:read-json in)))))

(defun %scenario (id) (or (find id (load-scenarios) :key (lambda (s) (gethash "id" s)) :test #'equal)
                          (error "No scenario ~S" id)))

(defun %page (scenario site slug)
  (let ((sites (gethash "sites" scenario)))
    (and sites (let ((pages (gethash site sites))) (and pages (gethash slug pages))))))

(defun %availability (scenario site slug)
  "The observation the fixture supports for SITE/SLUG, or NIL (unknown)."
  (let ((status (let ((s (gethash "status" scenario))) (and s (gethash site s) (gethash slug (gethash site s)))))
        (served (and (gethash "sites" scenario) (nth-value 1 (gethash site (gethash "sites" scenario)))))
        (dead (member site (coerce (or (gethash "dead" scenario) #()) 'list) :test #'equal)))
    (cond (dead `(request-error ,(%key site) ,(%key slug)))
          (status `(page-unavailable ,(%key site) ,(%key slug) ,status))
          ((%page scenario site slug) `(page-available ,(%key site) ,(%key slug)))
          (served `(page-unavailable ,(%key site) ,(%key slug) 404))
          (t nil))))

(defun scenario-link-state (scenario-id link-index &key (request :link))
  "Initial facts for the LINK-INDEX-th link of a fixture scenario: the origin, the Java candidate order as facts, and
for every candidate site the observation the fixture supports. Returns (values STATE SLUG CANDIDATES)."
  (let* ((scenario (%scenario scenario-id))
         (link (elt (gethash "links" scenario) link-index))
         (panel (coerce (gethash "panel" link) 'list))
         (page (%page scenario (first panel) (second panel)))
         (item (elt (gethash "story" page) (gethash "item" link)))
         (slug (gethash "slug" link))
         (candidates (java-link-candidates
                      :origin "origin" :panel-site (first panel) :item-site (gethash "site" item)
                      :journal-sites (map 'list (lambda (action) (gethash "site" action)) (gethash "journal" page))))
         (keyed (mapcar (lambda (c) (cons (%key (car c)) (cdr c))) candidates)))
    (values (append `((origin :origin))
                    (candidate-facts request keyed)
                    (remove-duplicates (remove nil (mapcar (lambda (c) (%availability scenario (car c) slug)) candidates))
                                       :test #'equal))
            (%key slug)
            keyed)))

(defun scenario-plan (scenario-id link-index &key (policy 'collaborative) (request :link) (domain 'fedwiki-link-resolution))
  (multiple-value-bind (state slug) (scenario-link-state scenario-id link-index :request request)
    (values (plan-link-resolution state `((resolve ,request ,slug ,policy)) :domain domain) state slug)))

;;; Inspector handoff: source, observation, rule, counter-probe and evaluation, kept apart.

(defparameter +rule-trace+
  `((:rule candidate-order :java ,(reference-url "L225-L255") :also (,(reference-url "L266-L273") ,(reference-url "L289-L295"))
     :shop3 (java-link-candidates candidate-facts walk-candidates)
     :observed ("context-newest-first" "item-site" "journal-reorder" "panel-site" "origin-in-context" "attribution-site"))
    (:rule local-first :java ,(reference-url "L232-L236") :shop3 (candidate-available) :observed ("local-first"))
    (:rule non-200-is-not-here :java ,(reference-url "L156-L160") :shop3 (candidate-unavailable-next)
     :observed ("context-fallthrough" "status-500" "redirect-302"))
    (:rule network-error-stops :java ,(reference-url "L161-L163") :shop3 (candidate-request-error own-request-error)
     :observed ("network-error"))
    (:rule exhausted-context-fails :java ,(reference-url "L246-L252") :shop3 (candidates-exhausted) :observed ("not-found"))
    (:rule local-only-gate :java nil :shop3 (own-site-only observed-local modeled-local missing-locally own-request-error)
     :observed () :note "Ward's proposal; no Java counterpart. Collaborative and local-only differ only in RESOLVE's methods.")
    (:rule simulated-fork :java nil :shop3 (fork-planned already-modeled-local !plan-fork)
     :observed () :note "Preparation, not resolution. Adds MODELED-LOCAL-PAGE and PLANNED-FORK only.")))

(defun rule-trace () (copy-tree +rule-trace+))

(defun link-resolution-experiment (&optional (scenario-id "context-newest-first") (link-index 0) (policy 'collaborative))
  "Inspectable context: Java source and observation, the facts, the SHOP3 objects, the result and its reading.
EVALUATION compares the planned requests with the Java requests for this link. No engine critique was run."
  (multiple-value-bind (result state slug) (scenario-plan scenario-id link-index :policy policy)
    (let* ((observed (let ((o (load-observations)))
                       (and o (find scenario-id (coerce (gethash "scenarios" o) 'list) :key (lambda (s) (gethash "id" s)) :test #'equal))))
           (outcomes (plan-outcomes result state)))
      (list :scenario scenario-id :link link-index :policy policy :slug slug
            :java-revision +reference-revision+ :java-source (reference-url "L225-L255")
            :java-observed observed
            :initial-state state :tasks `((resolve :link ,slug ,policy))
            :domain (shop3:find-domain 'fedwiki-link-resolution)
            :methods (shop3:domain-methods (shop3:find-domain 'fedwiki-link-resolution))
            :result result :outcomes outcomes
            :diagnosis (unless (dreyeck/shop3:raw-plans-of result) (diagnose-no-plan state :link slug policy))
            :execution :not-executed
            :engine-critiques '() :engine-critiques-note "No Lisp Critic engine rule was run (no source station in this environment)."
            :rule-trace (rule-trace)))))
