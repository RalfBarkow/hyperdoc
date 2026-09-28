;;;; HyperDoc Authoring as a Constraint Derivation
(defpackage #:dreyeck/work/authoring-architecture
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:git #:dreyeck/git)
                    (#:evidence #:dreyeck/work/deployment-reading)
                    (#:views #:html-inspector-views))
  (:export #:architecture-page #:architecture-source #:architecture-projection
           #:architecture-view-kinds #:constraint-facets #:topic-commit
           #:derivation-layout #:runtime-layout #:evidence-layout
           #:deployment-observation #:deployment-observation-record
           #:deployment-observation-category #:deployment-observation-related
           #:deployment-observation-provenance #:deployment-projection
           #:observed-deployment-layout #:target-deployment-layout
           #:architecture-workspace #:render-constraint-claims))
(in-package #:dreyeck/work/authoring-architecture)

;;;; One authored source, several selections
;;
;; The text page Deriving HyperDoc Authoring Constraints is the only place
;; the architecture's facts are written: Topics as links with data-topic,
;; data-kind and data-status, Associations as <li data-from data-to
;; data-relation>, exactly as in Work Breakdown. PROJECT-WORK-BREAKDOWN
;; reads it by Work's rules, Relation Contracts included, and each
;; Association keeps its source occurrence. Nothing here repeats a Topic
;; or an Association.
;;
;; A view is a selection of that one projection by Topic kind; an
;; Association is kept when both its endpoints are. No view has positions:
;; TALA derives the layout every time, and the page authors none.
;;
;; A committed milestone's link carries data-commit, the full hash. Its
;; Topic stands for that Git commit instead of the page, so inspecting it
;; reaches the changed source and test files. The hash is provenance, not
;; identity: the Topic ID names the milestone.

(defparameter *page-title* "Deriving HyperDoc Authoring Constraints")

(defparameter *views*
  '((:derivation "requirement" "constraint" "property")
    (:runtime "component" "connector" "data")
    (:evidence "requirement" "constraint" "connector" "milestone"))
  "Each view, with the Topic kinds it selects.")

(defparameter *facets*
  '(("requirement" . :requirement) ("constraint" . :constraint) ("trade-off" . :trade-off))
  "The facets a constraint's entry may carry, as data-facet names.")

(defun architecture-page ()
  (work:work-page *page-title*))

(defun architecture-source ()
  "The page's authored HTML, read once per call."
  (uiop:read-file-string (hyperdoc:file-of (architecture-page)) :external-format :utf-8))

(defun architecture-view-kinds (view)
  (or (rest (assoc view *views*))
      (error "No authoring architecture view ~S." view)))

(defun %topic-anchors (html)
  (let ((dom (let ((plump:*tag-dispatchers* plump:*html-tags*))
               (plump:parse html))))
    (remove-if-not (lambda (node) (plump:attribute node "data-topic"))
                   (plump:get-elements-by-tag-name dom "a"))))

(defun %commit (hash)
  "The Git commit HASH names, made without asking Git, so the page reads
where Git is missing; the commit's own views ask Git when opened. Where
the checkout is not a repository, the condition says so in its place."
  (handler-case (make-instance 'git:git-commit
                               :repository (git:current-git-repository-checkout)
                               :commit-ish hash :hash hash)
    (error (condition) condition)))

(defun %standing-for (topic object)
  "TOPIC, standing for OBJECT."
  (tm:make-topicmap-topic :id (tm:topicmap-topic-id-of topic)
                          :type (tm:topicmap-topic-type-of topic)
                          :label (tm:topicmap-topic-label-of topic)
                          :object object
                          :view-properties (tm:topicmap-topic-view-properties-of topic)))

(defun architecture-projection (&key view (html (architecture-source)))
  "The Topics and Associations authored on the page, or the selection VIEW
names (see *VIEWS*). HTML defaults to the page as it is now."
  (let* ((page (architecture-page))
         (all (work:project-work-breakdown html :source page))
         (commits (loop for node in (%topic-anchors html)
                        when (plump:attribute node "data-commit")
                          collect (cons (plump:attribute node "data-topic")
                                        (plump:attribute node "data-commit"))))
         (kinds (and view (architecture-view-kinds view)))
         (topics (loop for topic in (tm:topicmap-projection-topics-of all)
                       for kind = (getf (tm:topicmap-topic-view-properties-of topic) :kind)
                       for hash = (cdr (assoc (tm:topicmap-topic-id-of topic) commits
                                              :test #'string=))
                       when (or (null view) (member kind kinds :test #'equal))
                         collect (if hash (%standing-for topic (%commit hash)) topic)))
         (ids (mapcar #'tm:topicmap-topic-id-of topics)))
    (tm:make-topicmap-projection
     :source page :topics topics
     :associations (remove-if-not
                    (lambda (association)
                      (and (member (tm:topicmap-association-from-of association) ids
                                   :test #'string=)
                           (member (tm:topicmap-association-to-of association) ids
                                   :test #'string=)))
                    (tm:topicmap-projection-associations-of all)))))

(defun constraint-facets (&key (html (architecture-source)))
  "Each constraint's Topic ID with the facets written beside its link, as
a plist. A facet name outside *FACETS* is refused."
  (loop for node in (%topic-anchors html)
        when (equal "constraint" (plump:attribute node "data-kind"))
          collect (cons (plump:attribute node "data-topic")
                        (loop for span in (plump:get-elements-by-tag-name (plump:parent node) "span")
                              for name = (plump:attribute span "data-facet")
                              when name
                                append (list (or (cdr (assoc name *facets* :test #'string=))
                                                 (error "Unknown constraint facet ~S." name))
                                             (plump:decode-entities (plump:text span)))))))

(defun topic-commit (topic-id)
  "The object the milestone TOPIC-ID stands for: its Git commit."
  (let ((topic (tm:topicmap-projection-topic-by-id
                (architecture-projection :view :evidence) topic-id)))
    (unless topic (error "No milestone ~S on the page." topic-id))
    (tm:topicmap-topic-object-of topic)))

;;;; Layout, by TALA only

(defun %layout (view)
  (%layout-projection (architecture-projection :view view)))

(defun %layout-projection (projection)
  (let ((input (tala:projection-tala-input projection))
        (dependency (tala:tala-dependency-status)))
    (if (eq :available (getf dependency :status))
        (tala:run-tala input)
        (list :status :unavailable :input input :dependency dependency
              :remedy "nix develop .#tala"))))

(hyperdoc:defexample derivation-layout
  "The requirement, the seven constraints and their properties, laid out by TALA."
  (%layout :derivation))

(hyperdoc:defexample runtime-layout
  "Components, connectors and data at run time, laid out by TALA."
  (%layout :runtime))

(hyperdoc:defexample evidence-layout
  "The requirement, constraints, the connector, milestones and their evidential status, laid out by TALA."
  (%layout :evidence))

;;;; Deployment on dreyeck.ch, projected from supplied evidence
;;
;; The observed deployment is not written here. DEPLOYMENT-EVIDENCE, in the
;; deployment reading, is the one record of what was observed on dreyeck.ch,
;; with each fact's epistemic category. This builder draws a selection of it:
;; the records that make up the dreyeck.ch authoring topology, chosen for
;; relevance, not for being observed. The wiki.ralfbarkow.ch witness and the
;; MCP service are observed but are not part of that topology.
;;
;; A node stands for one observed record and keeps, for inspection, the
;; records that describe it, each with its category. An edge is drawn only
;; for an observed nginx route. Derived, inferred and unresolved records are
;; never edges; the inferred source commit of the service in particular
;; stays with the HyperDoc listener as an inference.
;;
;; The target adds what the page authors as intent: the three missing
;; deployment relations, each a Topic of kind deployment with status
;; target, and the existing run-time Topics they would deploy. A deployment
;; Topic's status is its deployment state, current or target; the evidence
;; object carries how it is known; a run-time Topic's status stays its
;; implementation maturity.

(defclass deployment-observation ()
  ((record :initarg :record :reader deployment-observation-record)
   (category :initarg :category :reader deployment-observation-category)
   (related :initarg :related :reader deployment-observation-related)
   (provenance :initarg :provenance :reader deployment-observation-provenance))
  (:documentation "One record of DEPLOYMENT-EVIDENCE as a node stands for it:
the record, its epistemic category, the related records with theirs, and
the evidence's provenance."))

(defmethod print-object ((observation deployment-observation) stream)
  (print-unreadable-object (observation stream :type t)
    (format stream "~(~A~) ~A" (deployment-observation-category observation)
            (getf (deployment-observation-record observation) :id))))

(defparameter *deployment-nodes*
  '(("nginx-listeners" "nginx :80 :443" ("nginx-tls"))
    ("hyperdoc-listener" "HyperDoc 0.0.0.0:8080"
     ("hyperdoc-service" "dreyeck-checkout" "checkout-fast-forward" "hyperdoc-service-start"
      "hyperdoc-started-from-checkout" "nixos-firewall" "external-8080"))
    ("fedwiki-listener" "Node/FedWiki *:3000" ("fedwiki-config" "public-apex-route"))
    ("fedwiki-pages" "/home/rgb/.wiki/dreyeck.ch/pages" ("fedwiki-config" "public-apex-route")))
  "Each evidence record a node may stand for: its id, its label, and the ids
of the records kept with it.")

(defparameter *deployment-routes*
  '(("nginx-exact-host" "nginx-listeners" "hyperdoc-listener")
    ("nginx-wildcard-host" "nginx-listeners" "fedwiki-listener"))
  "Each nginx route record, from the nginx listener to the listener its
upstream port names.")

(defparameter *deployment-views*
  '((:observed :nodes ("nginx-listeners" "hyperdoc-listener" "fedwiki-listener")
               :routes ("nginx-exact-host" "nginx-wildcard-host")
               :page-topics () :attachments ())
    (:target :nodes ("nginx-listeners" "hyperdoc-listener" "fedwiki-listener" "fedwiki-pages")
             :routes ("nginx-exact-host" "nginx-wildcard-host")
             :page-topics ("deployment/authoring-route" "deployment/listener-startup"
                           "deployment/authority-configuration" "http-connector" "fedwiki-m0")
             :attachments (("nginx-listeners" "deployment/authoring-route" "would carry /authoring/v1/")
                           ("fedwiki-m0" "fedwiki-pages" "would edit"))))
  "The two deployment views: which evidence records become nodes, which
route records edges, which of the page's Topics the view adds, and the
edges joining those to the evidence nodes.")

(defun %deployment-record (evidence id)
  "The record ID names in EVIDENCE, and its category."
  (loop for category in '(:observed :derived :inferred :unresolved)
        for record = (find id (getf evidence category)
                           :key (lambda (record) (getf record :id)) :test #'equal)
        when record return (values record category)
        finally (error "No evidence record ~S." id)))

(defun %deployment-topic-id (record-id) (format nil "deployment/~A" record-id))

(defun %deployment-node (evidence id)
  (destructuring-bind (label related) (rest (assoc id *deployment-nodes* :test #'equal))
    (multiple-value-bind (record category) (%deployment-record evidence id)
      (tm:make-topicmap-topic
       :id (%deployment-topic-id id) :type :deployment :label label
       :object (make-instance 'deployment-observation
                              :record record :category category
                              :related (loop for other in related
                                             collect (multiple-value-bind (r c)
                                                         (%deployment-record evidence other)
                                                       (cons c r)))
                              :provenance (getf evidence :provenance))
       :view-properties (list :visible t :kind "deployment" :status "current")))))

(defun %route-label (record)
  (format nil "Host ~A~@[: ~{~A~^ and ~}~]" (getf record :host) (getf record :observed-paths)))

(defun %view-topic-id (spec id)
  "ID as a Topic ID of the view SPEC: one of its page Topics, or the node
standing for that evidence record."
  (if (member id (getf spec :page-topics) :test #'equal) id (%deployment-topic-id id)))

(defun deployment-projection (role &key (evidence (evidence:deployment-evidence)))
  "The deployment view ROLE names, :OBSERVED or :TARGET: nodes standing for
selected observed records of EVIDENCE, edges for its nginx routes, and for
the target the page's authored intent joined to them."
  (let* ((spec (or (rest (assoc role *deployment-views*))
                   (error "No deployment view ~S." role)))
         (page (architecture-projection))
         (page-topics (loop for id in (getf spec :page-topics)
                            collect (or (tm:topicmap-projection-topic-by-id page id)
                                        (error "The page has no Topic ~S." id))))
         (topics (append (loop for id in (getf spec :nodes) collect (%deployment-node evidence id))
                         page-topics))
         (ids (mapcar #'tm:topicmap-topic-id-of topics)))
    (tm:make-topicmap-projection
     :source (architecture-page) :topics topics
     :associations
     (append
      (loop for route in (getf spec :routes)
            for (nil from to) = (assoc route *deployment-routes* :test #'equal)
            for record = (%deployment-record evidence route)
            collect (tm:make-topicmap-association
                     :id (format nil "deployment:~A" route) :type (%route-label record)
                     :from (%deployment-topic-id from) :to (%deployment-topic-id to)
                     :properties (list :evidence record)))
      (loop for association in (tm:topicmap-projection-associations-of page)
            when (and (member (tm:topicmap-association-from-of association) ids :test #'string=)
                      (member (tm:topicmap-association-to-of association) ids :test #'string=))
              collect association)
      (loop for (from to relation) in (getf spec :attachments)
            for from-id = (%view-topic-id spec from)
            for to-id = (%view-topic-id spec to)
            do (dolist (id (list from-id to-id))
                 (unless (member id ids :test #'string=) (error "~S is not in the view." id)))
            collect (tm:make-topicmap-association
                     :id (format nil "deployment:~A:~A" from-id to-id) :type relation
                     :from from-id :to to-id))))))

(hyperdoc:defexample observed-deployment-layout
  "The observed dreyeck.ch deployment, projected from the supplied evidence and laid out by TALA."
  (%layout-projection (deployment-projection :observed)))

(hyperdoc:defexample target-deployment-layout
  "The observed deployment with the authoring relations still missing, laid out by TALA."
  (%layout-projection (deployment-projection :target)))

(hyperdoc:defexample architecture-workspace
  "Every Topic and Association of the page, navigable with native action signs."
  (tm:make-topicmap-workspace (architecture-projection) "bounded-freshness-state"))

;;;; The claims, joined per constraint

(defun %targets (projection from relation)
  (loop for association in (tm:topicmap-projection-associations-of projection)
        when (and (string= from (tm:topicmap-association-from-of association))
                  (equal relation (tm:topicmap-association-type-of association)))
          collect (tm:topicmap-projection-topic-by-id
                   projection (tm:topicmap-association-to-of association))))

(defun %status (topic)
  (getf (tm:topicmap-topic-view-properties-of topic) :status))

(defun %references (topics &key (object #'identity))
  (loop for topic in topics
        for first = t then nil
        do (unless first (views:html (:br)))
           (views:object-ref (funcall object topic)
                             :display (format nil "~A (~A)" (tm:topicmap-topic-label-of topic)
                                              (%status topic)))))

(defun render-constraint-claims ()
  "The claims the page's Associations make about each constraint, as a table
of Inspector references. The page calls this while its view is built."
  (let ((projection (architecture-projection)))
    (views:html
      (:table :class "inspector-table"
        (:tr (:th "Constraint") (:th "Demonstrated") (:th "Intended, not measured")
             (:th "Evidence") (:th "Realized by"))
        (dolist (topic (tm:topicmap-projection-topics-of projection))
          (when (equal "constraint" (getf (tm:topicmap-topic-view-properties-of topic) :kind))
            (let ((id (tm:topicmap-topic-id-of topic)))
              (views:html
                (:tr (:td (%references (list topic)))
                     (:td (%references (%targets projection id "work:relation/induces-demonstrated")))
                     (:td (%references (%targets projection id "work:relation/induces-intended")))
                     (:td (%references (%targets projection id "work:relation/evidenced-by")
                                       :object #'tm:topicmap-topic-object-of))
                     (:td (%references (%targets projection id "work:relation/realized-by"))))))))))))
