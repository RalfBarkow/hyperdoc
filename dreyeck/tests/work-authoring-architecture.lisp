;;;; Deriving HyperDoc Authoring Constraints: the facts, not their layout.
;;;;
;;;; Every check reads the one authored page through the projection the
;;;; page's views use. Nothing asserts a coordinate or an SVG path: TALA
;;;; owns geometry, and a layout is checked only for covering the same
;;;; Topics and Associations.

(defpackage #:dreyeck/work/authoring-architecture/tests
  (:use #:cl)
  (:local-nicknames (#:arch #:dreyeck/work/authoring-architecture)
                    (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:git #:dreyeck/git)
                    (#:m #:dreyeck/inspector/topicmap)
                    (#:views #:html-inspector-views))
  (:export #:run-authoring-architecture-tests #:rest-or-stateless-claims))

(in-package #:dreyeck/work/authoring-architecture/tests)

(defparameter *title* "Deriving HyperDoc Authoring Constraints")

(defparameter *chain*
  '("public-network-authoring" "signed-intent" "authenticated-principal"
    "single-use-freshness" "bounded-freshness-state" "explicit-authoring-rule"
    "scoped-capability" "serialized-verified-effect")
  "The derivation, in the order constraints are added.")

(defparameter *claims*
  '(("signed-intent" "integrity" :demonstrated)
    ("signed-intent" "interaction-visibility" :intended)
    ("authenticated-principal" "principal-bound-requests" :demonstrated)
    ("single-use-freshness" "replay-resistance" :demonstrated)
    ("bounded-freshness-state" "bounded-resource-consumption" :demonstrated)
    ("bounded-freshness-state" "anarchic-scalability" :intended)
    ("explicit-authoring-rule" "bounded-authorization" :demonstrated)
    ("scoped-capability" "least-authority" :demonstrated)
    ("serialized-verified-effect" "consistency" :demonstrated)
    ("serialized-verified-effect" "reliability" :intended))
  "Every property claim the page may make, with its strength.")

(defparameter *runtime*
  '(("signing-client" "component") ("nginx-gateway" "component")
    ("http-connector" "connector") ("envelope-verification" "component")
    ("principal-registry" "component") ("challenge-store" "component")
    ("authoring-rules" "component") ("capability-derivation" "component")
    ("fedwiki-m0" "component") ("signed-envelope" "data") ("exact-body" "data")
    ("expected-item" "data") ("authenticated-principal-value" "data")
    ("page-capability" "data") ("fedwiki-action" "data") ("fedwiki-page-state" "data")))

(defparameter *bounded-challenges* "9a041fdd2a7b14d3fc7ad57672460c1f87827005")

(defparameter *statuses*
  '("production" "scratch-proven" "planned" "demonstrated" "intended" "draft" "target"))

;;;; Helpers

(defun %topic (projection id)
  (or (tm:topicmap-projection-topic-by-id projection id)
      (error "No Topic ~S." id)))

(defun %property (topic name)
  (getf (tm:topicmap-topic-view-properties-of topic) name))

(defun %ids (projection)
  (mapcar #'tm:topicmap-topic-id-of (tm:topicmap-projection-topics-of projection)))

(defun %edges (projection relation)
  "(FROM TO) of each Association of PROJECTION whose relation is RELATION."
  (loop for a in (tm:topicmap-projection-associations-of projection)
        when (equal relation (tm:topicmap-association-type-of a))
          collect (list (tm:topicmap-association-from-of a) (tm:topicmap-association-to-of a))))

(defun %same-set-p (a b)
  (and (= (length a) (length b)) (null (set-exclusive-or a b :test #'equal))))

(defun %page-sources ()
  (mapcar (lambda (file) (cons file (uiop:read-file-string file :external-format :utf-8)))
          (uiop:directory-files (asdf:system-relative-pathname "dreyeck" "dreyeck/pages/work/"))))

(defun %content-view (page)
  (let ((view (find "Content" (views:all-views page) :key #'views:view-title :test #'equal)))
    (assert view)
    (views:view-html view)
    view))

(defun %insert-after (string anchor text)
  "STRING with TEXT inserted after the first </li> following ANCHOR."
  (let* ((at (search anchor string))
         (end (+ (search "</li>" string :start2 at) (length "</li>"))))
    (concatenate 'string (subseq string 0 end) text (subseq string end))))

;;;; The page is in Working on HyperDoc, found as the server finds it

(defun check-catalog-registration ()
  (let* ((book (hyperbook:find-hyperbook "dreyeck/work/reading" :signal-error? t))
         (slug (hyperbook/server::slug book)))
    (assert (string= "Working on HyperDoc" (hyperbook:title-of book)))
    (assert (member book (hyperbook:hyperbooks-of hyperbook:*catalog*)))
    (hyperdoc::ensure-pages-loaded book)
    (let* ((page (hyperbook:find-page book *title* :signal-error? t))
           (route (format nil "/~A/~A" slug (tbnl:url-encode (hyperbook:path-item-of page))))
           ;; As the server's handler turns a request path into a lookup.
           (path (mapcar #'tbnl:url-decode
                         (rest (str:split "/" (subseq route (1+ (length slug))))))))
      (assert (typep page 'hyperdoc::html-page))
      (assert (eq page (hyperbook:lookup-path book path)))
      (assert (eq page (arch:architecture-page)))
      (assert (typep (hyperbook:find-page book "HyperDoc Authoring as a Constraint Derivation"
                                          :signal-error? t)
                     'hyperdoc::code-page))
      ;; It renders: every link and executable widget resolved.
      (let* ((view (%content-view page))
             (objects (mapcar #'cdr (views:view-references view))))
        (assert (notany (lambda (object) (typep object 'condition)) objects))
        (assert (= 6 (count-if (lambda (object) (typep object 'views:view)) objects)))
        ;; The worked example links its evidence: the commit itself.
        (assert (find-if (lambda (object)
                           (and (typep object 'git:git-commit)
                                (string= *bounded-challenges* (git:git-commit-hash-of object))))
                         objects)))
      route)))

;;;; The derivation

(defun check-derivation ()
  (let ((projection (arch:architecture-projection :view :derivation))
        (facets (arch:constraint-facets)))
    (dolist (id *chain*)
      (%topic projection id))
    (assert (equal "requirement" (%property (%topic projection (first *chain*)) :kind)))
    (dolist (id (rest *chain*))
      (let ((topic (%topic projection id)))
        (assert (equal "constraint" (%property topic :kind)))
        (assert (equal "production" (%property topic :status)))
        ;; Requirement, constraint and trade-off are written beside it.
        (let ((entry (cdr (assoc id facets :test #'string=))))
          (dolist (facet '(:requirement :constraint :trade-off))
            (let ((text (getf entry facet)))
              (assert (and (stringp text) (plusp (length (string-trim " " text)))) ()
                      "~A has no ~A." id facet))))))
    (assert (= (length (rest *chain*)) (length facets)))
    ;; The derivation is exactly the chain, in order, as Associations.
    (assert (%same-set-p (loop for (from to) on *chain* while to collect (list from to))
                         (%edges projection "work:relation/adds-constraint")))
    (dolist (a (tm:topicmap-projection-associations-of projection))
      (when (equal "work:relation/adds-constraint" (tm:topicmap-association-type-of a))
        (assert (equal "adds constraint" (tm:topicmap-association-relation-label a)))))
    ;; Each constraint induces a property, is evidenced and is realized.
    (let ((all (arch:architecture-projection)))
      (dolist (id (rest *chain*))
        (dolist (relation '("work:relation/evidenced-by" "work:relation/realized-by"))
          (assert (find id (%edges all relation) :key #'first :test #'string=) ()
                  "~A has no ~A Association." id relation))
        (assert (find id (append (%edges all "work:relation/induces-demonstrated")
                                 (%edges all "work:relation/induces-intended"))
                      :key #'first :test #'string=))))))

;;;; Intended is not demonstrated

(defun check-properties ()
  (let* ((projection (arch:architecture-projection :view :derivation))
         (made (append (mapcar (lambda (e) (append e '(:demonstrated)))
                               (%edges projection "work:relation/induces-demonstrated"))
                       (mapcar (lambda (e) (append e '(:intended)))
                               (%edges projection "work:relation/induces-intended")))))
    (assert (%same-set-p *claims* made))
    (dolist (claim *claims*)
      (destructuring-bind (from to strength) claim
        (declare (ignore from))
        (let ((topic (%topic projection to)))
          (assert (equal "property" (%property topic :kind)))
          ;; A property's status is its claim's strength, and no property
          ;; is claimed both ways.
          (assert (equal (string-downcase strength) (%property topic :status)))
          (assert (= 1 (count to made :key #'second :test #'string=))))))
    (dolist (topic (tm:topicmap-projection-topics-of projection))
      (when (equal "property" (%property topic :kind))
        (assert (member (%property topic :status) '("demonstrated" "intended") :test #'equal))))
    ;; Anarchic scalability is aimed at, not measured.
    (assert (equal "intended" (%property (%topic projection "anarchic-scalability") :status)))
    (assert (not (find "anarchic-scalability" (%edges projection "work:relation/induces-demonstrated")
                       :key #'second :test #'string=)))))

;;;; 9a041fdd is the evidence for bounded challenges

(defun check-bounded-challenge-evidence ()
  (let* ((projection (arch:architecture-projection :view :evidence))
         (milestone (%topic projection "milestone/bounded-challenges"))
         (commit (tm:topicmap-topic-object-of milestone))
         (repository (git:current-git-repository-checkout)))
    (assert (member '("bounded-freshness-state" "milestone/bounded-challenges")
                    (%edges projection "work:relation/evidenced-by") :test #'equal))
    (assert (typep commit 'git:git-commit))
    (assert (string= *bounded-challenges* (git:git-commit-hash-of commit)))
    (assert (string= *bounded-challenges* (git:git-commit-hash-of
                                           (arch:topic-commit "milestone/bounded-challenges"))))
    (assert (git:git-commit-object-present-p repository *bounded-challenges*))
    (assert (string= "feat(hyperdoc): bound authoring challenge state" (git:git-commit-subject commit)))
    ;; From the commit to the source and the tests it changed.
    (let ((changed (git:git-commit-changed-files commit)))
      (dolist (path '("dreyeck/src/authenticated-page-authoring.lisp"
                      "dreyeck/tests/authenticated-page-authoring.lisp"))
        (assert (find path changed :test (lambda (p line) (search p line))))))
    ;; Every committed milestone names a commit in this repository, and
    ;; "precedes" between two of them is what the history says.
    (let ((commits (loop for topic in (tm:topicmap-projection-topics-of projection)
                         for object = (tm:topicmap-topic-object-of topic)
                         when (typep object 'git:git-commit)
                           collect (cons (tm:topicmap-topic-id-of topic) object))))
      (assert (= 8 (length commits)))
      (dolist (entry commits)
        (assert (git:git-commit-object-present-p repository (git:git-commit-hash-of (cdr entry))))
        ;; A hash is provenance, never part of a Topic's identity.
        (dolist (id (%ids (arch:architecture-projection)))
          (assert (not (search (subseq (git:git-commit-hash-of (cdr entry)) 0 7) id)))))
      (loop for (from to) in (%edges projection "precedes")
            for a = (cdr (assoc from commits :test #'string=))
            for b = (cdr (assoc to commits :test #'string=))
            do (assert (and a b))
               (assert (git:git-commit-ancestor-p a b))
               (assert (not (git:git-commit-ancestor-p b a)))))))

;;;; Status: production, scratch-proven, planned

(defun check-statuses ()
  (let ((projection (arch:architecture-projection)))
    (dolist (topic (tm:topicmap-projection-topics-of projection))
      (assert (member (%property topic :status) *statuses* :test #'equal) ()
              "~A has status ~S." (tm:topicmap-topic-id-of topic) (%property topic :status))
      ;; A milestone stands for a commit exactly when it is committed.
      (when (equal "milestone" (%property topic :kind))
        (assert (eq (equal "production" (%property topic :status))
                    (typep (tm:topicmap-topic-object-of topic) 'git:git-commit)))))
    ;; The signed HTTP transport is production: it stands for the commit that
    ;; added the adapter and its tests, after 9a041fdd.
    (let* ((transport (%topic projection "milestone/signed-http-transport"))
           (commit (tm:topicmap-topic-object-of transport)))
      (assert (equal "production" (%property transport :status)))
      (assert (typep commit 'git:git-commit))
      (let ((changed (git:git-commit-changed-files commit)))
        (dolist (path '("dreyeck/src/authoring-http.lisp" "dreyeck/tests/authoring-http.lisp"))
          (assert (find path changed :test (lambda (p line) (search p line))))))
      (assert (member '("milestone/bounded-challenges" "milestone/signed-http-transport")
                      (%edges projection "precedes") :test #'equal)))
    ;; The experiment that prototyped it stays what it was.
    (let ((experiment (%topic projection "milestone/http-transport-experiment")))
      (assert (equal "scratch-proven" (%property experiment :status)))
      (assert (eq (arch:architecture-page) (tm:topicmap-topic-object-of experiment)))
      (assert (member '("milestone/http-transport-experiment" "milestone/signed-http-transport")
                      (%edges projection "prototypes") :test #'equal)))
    ;; The planned adapter is resolved into the production one, not kept beside it.
    (assert (null (tm:topicmap-projection-topic-by-id projection "milestone/production-http-adapter")))
    (assert (equal "production" (%property (%topic projection "http-connector") :status)))
    ;; Production is not deployed: the gateway is still planned, and the page says so.
    (assert (equal "planned" (%property (%topic projection "nginx-gateway") :status)))
    (assert (search "It says nothing about deployment." (arch:architecture-source)))))

;;;; The run-time view: components, connectors, data

(defun check-runtime ()
  (let ((projection (arch:architecture-projection :view :runtime))
        (page (arch:architecture-page)))
    (assert (%same-set-p (mapcar #'first *runtime*) (%ids projection)))
    (loop for (id kind) in *runtime*
          for topic = (%topic projection id)
          do (assert (equal kind (%property topic :kind)))
             ;; Run-time elements, not the files that implement them.
             (assert (eq page (tm:topicmap-topic-object-of topic)))
             (assert (not (search ".lisp" (tm:topicmap-topic-label-of topic)))))
    ;; The four data elements that cross the boundaries.
    (dolist (id '("signed-envelope" "exact-body" "expected-item" "fedwiki-action"))
      (assert (equal "data" (%property (%topic projection id) :kind))))
    ;; nginx forwards to the connector and to nothing else; in particular it
    ;; neither authenticates nor yields the principal.
    (let ((edges (tm:topicmap-projection-associations-of projection)))
      (assert (equal '("http-connector")
                     (loop for a in edges
                           when (equal "nginx-gateway" (tm:topicmap-association-from-of a))
                             collect (tm:topicmap-association-to-of a))))
      (assert (equal '("envelope-verification")
                     (loop for a in edges
                           when (equal "authenticated-principal-value" (tm:topicmap-association-to-of a))
                             collect (tm:topicmap-association-from-of a))))
      (assert (search "does not authenticate"
                      (tm:topicmap-association-type-of
                       (find "nginx-gateway" edges :key #'tm:topicmap-association-from-of
                                                   :test #'equal)))))))

;;;; No authored geometry

(defun check-no-authored-geometry ()
  (let ((dom (let ((plump:*tag-dispatchers* plump:*html-tags*))
               (plump:parse (arch:architecture-source)))))
    (assert (null (plump:get-elements-by-tag-name dom "svg")))
    (plump:traverse dom
                    (lambda (node)
                      (loop for name being the hash-keys of (plump:attributes node)
                            do (assert (not (member name '("x" "y" "cx" "cy" "data-x" "data-y"
                                                           "transform" "style" "width" "height")
                                                    :test #'string-equal))
                                       () "The page authors ~A." name)))
                    :test #'plump:element-p))
  ;; Each view's layout input is Topic declarations and edges, nothing
  ;; else: there is no line on which a position could stand.
  (dolist (view '(:derivation :runtime :evidence))
    (let* ((input (tala:projection-tala-input (arch:architecture-projection :view view)))
           (keys (mapcar (lambda (e) (getf e :d2-id)) (tala:tala-input-topics input)))
           (lines (remove "" (uiop:split-string (tala:tala-input-source input) :separator '(#\Newline))
                          :test #'string=)))
      (assert (= (length lines) (+ (length keys) (length (tala:tala-input-associations input)))))
      (dolist (line lines)
        (assert (some (lambda (key)
                        (or (eql 0 (search (format nil "~A: \"" key) line))
                            (eql 0 (search (format nil "~A -> " key) line))))
                      keys)
                () "Layout input line ~S is neither a Topic nor an edge." line)))))

;;;; TALA lays out each view; native navigation and inspection survive

(defun check-layouts ()
  (dolist (entry (list (cons :derivation #'arch:derivation-layout)
                       (cons :runtime #'arch:runtime-layout)
                       (cons :evidence #'arch:evidence-layout)))
    (let* ((rendering (funcall (cdr entry)))
           (projection (progn (assert (typep rendering 'tala:tala-rendering) ()
                                      "No TALA layout: ~S" rendering)
                              (tala:tala-input-projection (tala:tala-rendering-input rendering))))
           (view (find "TALA (interactive)" (views:all-views rendering)
                       :key #'views:view-title :test #'equal)))
      (assert (%same-set-p (%ids (arch:architecture-projection :view (car entry)))
                           (%ids projection)))
      (views:view-html view)
      ;; Every shape and edge is an Inspector reference to its own object.
      (let ((objects (mapcar #'cdr (views:view-references view))))
        (assert (%same-set-p (append (tm:topicmap-projection-topics-of projection)
                                     (tm:topicmap-projection-associations-of projection))
                             objects))
        (when (eq :evidence (car entry))
          (let ((milestone (find "milestone/bounded-challenges" objects
                                 :key (lambda (o) (and (typep o 'tm:topicmap-topic)
                                                       (tm:topicmap-topic-id-of o)))
                                 :test #'equal)))
            (assert (typep (tm:topicmap-topic-object-of milestone) 'git:git-commit)))))))
  ;; The native Workspace: an action sign moves the Point to its Topic, and
  ;; the Point's object is what that Topic stands for.
  (let* ((workspace (arch:architecture-workspace))
         (view (find "Topicmap" (views:all-views workspace) :key #'views:view-title :test #'equal)))
    (views:view-html view)
    (dolist (id '("milestone/bounded-challenges" "challenge-store" "anarchic-scalability"))
      (let* ((before (tm:topicmap-workspace-point-of workspace))
             (action (find-if (lambda (reference)
                                (and (typep (cdr reference) 'm::topic-action-reference)
                                     (equal id (tm:topicmap-topic-id-of
                                                (m::action-topic (cdr reference))))))
                              (views:view-references view)))
             (topic (views:eval-thunk (cdr action))))
        (assert (equal id (tm:topicmap-topic-id-of topic)))
        (assert (equal id (tm:topicmap-workspace-point-of workspace)))
        (assert (eq (tm:topicmap-topic-object-of topic) (tm:topicmap-workspace-current-object workspace)))
        (assert (equal before (first (tm:topicmap-workspace-history-of workspace))))))
    (assert (typep (tm:topicmap-topic-object-of
                    (%topic (tm:topicmap-projection-of workspace) "milestone/bounded-challenges"))
                   'git:git-commit))))

;;;; The graph changes; nobody draws

(defun check-graph-change ()
  (let* ((html (arch:architecture-source))
         (changed (%insert-after
                   (%insert-after html "data-topic=\"serialized-verified-effect\""
                                  "
<li><a page=\"Deriving HyperDoc Authoring Constraints\" data-topic=\"test-rate-limit\" data-kind=\"constraint\" data-status=\"planned\">Test rate limit</a>.</li>")
                   "data-from=\"scoped-capability\" data-to=\"serialized-verified-effect\""
                   "
<li data-from=\"serialized-verified-effect\" data-to=\"test-rate-limit\" data-relation=\"work:relation/adds-constraint\">Test.</li>"))
         (before (arch:architecture-projection :view :derivation))
         (after (arch:architecture-projection :view :derivation :html changed))
         (input (tala:projection-tala-input after)))
    (assert (= (1+ (length (tm:topicmap-projection-topics-of before)))
               (length (tm:topicmap-projection-topics-of after))))
    (assert (member '("serialized-verified-effect" "test-rate-limit")
                    (%edges after "work:relation/adds-constraint") :test #'equal))
    ;; The same adapter lays the changed graph out; RUN-TALA checks that
    ;; every Topic and Association, the new ones included, came back.
    (let ((rendering (tala:run-tala input)))
      (assert (search (tala:d2-svg-identity-class (tala:tala-input-d2-key input "test-rate-limit"))
                      (tala:tala-rendering-svg rendering))))
    (assert (string= html (arch:architecture-source)))))

;;;; No claim of REST or statelessness

(defun %negated-p (sentence)
  (let ((lower (string-downcase sentence)))
    (some (lambda (marker) (search marker lower))
          '(" not " " not." "n't" " no " "never" "neither" "rather than"))))

(defun %names-rest-or-statelessness-p (sentence)
  (or (search "stateless" sentence :test #'char-equal)
      (loop for at = (search "REST" sentence) then (search "REST" sentence :start2 (1+ at))
            while at
            thereis (and (or (zerop at) (not (alpha-char-p (char sentence (1- at)))))
                         (or (= (+ at 4) (length sentence))
                             (not (upper-case-p (char sentence (+ at 4)))))))))

(defun rest-or-stateless-claims (html)
  "Each sentence of HTML's text that names REST or statelessness without
negating it."
  (let ((dom (let ((plump:*tag-dispatchers* plump:*html-tags*))
               (plump:parse html)))
        (claims nil))
    (dolist (tag '("h1" "h2" "h3" "p" "li" "td" "th"))
      (dolist (node (plump:get-elements-by-tag-name dom tag))
        (dolist (sentence (uiop:split-string
                           (substitute #\Space #\Newline (plump:decode-entities (plump:text node)))
                           :separator '(#\. #\;)))
          (when (and (%names-rest-or-statelessness-p sentence) (not (%negated-p sentence)))
            (push (string-trim " " sentence) claims)))))
    (nreverse claims)))

(defun check-no-rest-claims ()
  (let ((html (arch:architecture-source)))
    (assert (null (rest-or-stateless-claims html)) ()
            "The page claims: ~S" (rest-or-stateless-claims html))
    (assert (search "This page uses Fielding's constraint/property method. It does not claim that HyperDoc Authoring currently conforms to REST."
                    html))
    ;; No Topic says it either.
    (dolist (topic (tm:topicmap-projection-topics-of (arch:architecture-projection)))
      (dolist (text (list (tm:topicmap-topic-id-of topic) (tm:topicmap-topic-label-of topic)))
        (assert (not (%names-rest-or-statelessness-p text)))))
    ;; Positive controls: the check sees a claim, and lets a denial pass.
    (assert (rest-or-stateless-claims "<p>HyperDoc Authoring is REST-compliant.</p>"))
    (assert (rest-or-stateless-claims "<ul><li>Authoring is stateless.</li></ul>"))
    (assert (rest-or-stateless-claims
             (concatenate 'string html "<p>HyperDoc Authoring is RESTful.</p>")))
    (assert (null (rest-or-stateless-claims "<p>It is not stateless.</p>")))))

;;;; The page loads no authoring

(defun %closure (name &optional seen)
  (let ((system (asdf:find-system name nil)))
    (if (or (null system) (member (asdf:component-name system) seen :test #'string=))
        seen
        (let ((seen (cons (asdf:component-name system) seen)))
          (dolist (dependency (asdf:system-depends-on system) seen)
            (when (typep dependency '(or string symbol))
              (setf seen (%closure (string-downcase dependency) seen))))))))

(defun check-no-authoring-runtime ()
  (let ((closure (%closure "dreyeck/work/reading")))
    (assert (member "dreyeck/topicmap/tala" closure :test #'string=))
    (dolist (system '("dreyeck/authoring-envelope" "dreyeck/authenticated-page-authoring"
                      "dreyeck/fedwiki-page-authoring" "dreyeck/workflow/authoring"))
      (assert (not (member system closure :test #'string=))))))

(defun check-connector-evidence ()
  "The HTTP connector is one run-time element with two evidence events: the
commit that made it production and the one that corrected it. A commit that
changed only the authoring tools is evidence for nothing here."
  (let* ((projection (arch:architecture-projection))
         (evidence (sort (loop for (from to) in (%edges projection "work:relation/evidenced-by")
                               when (equal from "http-connector") collect to)
                         #'string<)))
    (assert (equal '("milestone/http-listener-correction" "milestone/signed-http-transport")
                   evidence))
    ;; Each evidence milestone stands for exactly the commit it names: the
    ;; production adapter and its correction, and no tooling commit.
    (assert (equal '("8a019b2f67c32a1bb9f678b7b3e4af90c81c2970" "afb8f0647c56655eccefb04f42d6e7e345beee27")
                   (sort (mapcar (lambda (id) (git:git-commit-hash-of
                                               (tm:topicmap-topic-object-of (%topic projection id))))
                                 evidence)
                         #'string<)))
    (assert (= 1 (count "connector" (tm:topicmap-projection-topics-of projection)
                        :key (lambda (topic) (%property topic :kind)) :test #'equal)))
    (let* ((correction (%topic projection "milestone/http-listener-correction"))
           (commit (tm:topicmap-topic-object-of correction)))
      (assert (equal "production" (%property correction :status)))
      (assert (typep commit 'git:git-commit))
      (let ((changed (git:git-commit-changed-files commit)))
        (dolist (path '("dreyeck/src/authoring-http.lisp" "dreyeck/tests/authoring-http.lisp"))
          (assert (find path changed :test (lambda (p line) (search p line))))))
      (assert (member '("milestone/signed-http-transport" "milestone/http-listener-correction")
                      (%edges projection "precedes") :test #'equal)))
    (dolist (topic (tm:topicmap-projection-topics-of projection))
      (let ((object (tm:topicmap-topic-object-of topic)))
        (when (typep object 'git:git-commit)
          (assert (notevery (lambda (line) (search "/workflow-" line))
                            (git:git-commit-changed-files object))
                  () "~A stands for a commit that changed only the authoring tools."
                  (tm:topicmap-topic-id-of topic)))))
    ;; The evidence view shows the connector with its evidence, and selecting
    ;; the connector kind adds that one Topic and no other.
    (let ((view (arch:architecture-projection :view :evidence)))
      (assert (equal '("http-connector")
                     (loop for topic in (tm:topicmap-projection-topics-of view)
                           unless (member (%property topic :kind) '("requirement" "constraint" "milestone")
                                          :test #'equal)
                             collect (tm:topicmap-topic-id-of topic))))
      (dolist (milestone '("milestone/signed-http-transport" "milestone/http-listener-correction"))
        (assert (member (list "http-connector" milestone)
                        (%edges view "work:relation/evidenced-by") :test #'equal)))))
  t)

(defparameter *current-deployment-nodes*
  '("deployment/nginx-listeners" "deployment/hyperdoc-listener" "deployment/fedwiki-listener")
  "The evidence records the current deployment view draws, as its Topics.")

(defparameter *target-deployment-topics*
  '("deployment/authoring-route" "deployment/listener-startup" "deployment/authority-configuration")
  "The page's authored target: the three missing deployment relations.")

(defun %evidence-record (evidence category id)
  (find id (getf evidence category) :key (lambda (record) (getf record :id)) :test #'equal))

(defun %pairs-of (projection)
  (mapcar (lambda (association)
            (list (tm:topicmap-association-from-of association)
                  (tm:topicmap-association-to-of association)))
          (tm:topicmap-projection-associations-of projection)))

(defun check-deployment-projection ()
  "The current deployment is a projection of the supplied evidence, selected
for relevance; the target adds only authored intent; neither claims more
than the evidence, and the three axes stay apart."
  (let* ((evidence (uiop:symbol-call :dreyeck/work/deployment-reading :deployment-evidence))
         (current (arch:deployment-projection :observed))
         (target (arch:deployment-projection :target))
         (page (arch:architecture-projection)))
    ;; Exactly the relevant records, each standing for its evidence record.
    (assert (%same-set-p *current-deployment-nodes* (%ids current)))
    (dolist (topic (tm:topicmap-projection-topics-of current))
      (let* ((observation (tm:topicmap-topic-object-of topic))
             (id (subseq (tm:topicmap-topic-id-of topic) (length "deployment/"))))
        (assert (typep observation 'arch:deployment-observation))
        (assert (eq :observed (arch:deployment-observation-category observation)))
        (assert (equal (%evidence-record evidence :observed id)
                       (arch:deployment-observation-record observation)))
        (assert (equal (getf evidence :provenance) (arch:deployment-observation-provenance observation)))
        (assert (equal "current" (%property topic :status)))))
    ;; No unrelated evidence: not the wiki.ralfbarkow.ch witness, not MCP.
    (dolist (projection (list current target))
      (dolist (topic (tm:topicmap-projection-topics-of projection))
        (let ((object (tm:topicmap-topic-object-of topic)))
          (when (typep object 'arch:deployment-observation)
            (let ((record (arch:deployment-observation-record object)))
              (assert (equal "dreyeck.ch" (getf record :subject)))
              (assert (not (search "mcp" (string-downcase (princ-to-string (getf record :id)))))))))))
    ;; Edges are the two observed routes, each carrying its route record,
    ;; and each reaching the listener its upstream port names.
    (assert (%same-set-p '(("deployment/nginx-listeners" "deployment/hyperdoc-listener")
                           ("deployment/nginx-listeners" "deployment/fedwiki-listener"))
                         (%pairs-of current)))
    (dolist (association (tm:topicmap-projection-associations-of current))
      (let ((route (getf (tm:topicmap-association-properties-of association) :evidence)))
        (assert (eq :nginx-route (getf route :kind)))
        (assert (%evidence-record evidence :observed (getf route :id)))
        (let* ((listener (arch:deployment-observation-record
                          (tm:topicmap-topic-object-of
                           (%topic current (tm:topicmap-association-to-of association)))))
               (port (lambda (address) (subseq address (1+ (position #\: address :from-end t))))))
          (assert (equal (funcall port (getf route :upstream)) (funcall port (getf listener :address)))))))
    ;; The inferred source commit is kept as an inference, never an edge.
    (let* ((listener (tm:topicmap-topic-object-of (%topic current "deployment/hyperdoc-listener")))
           (inferred (find "hyperdoc-started-from-checkout" (arch:deployment-observation-related listener)
                           :key (lambda (pair) (getf (cdr pair) :id)) :test #'equal)))
      (assert (eq :inferred (car inferred)))
      (dolist (projection (list current target))
        (dolist (association (tm:topicmap-projection-associations-of projection))
          (let ((record (getf (tm:topicmap-association-properties-of association) :evidence)))
            (when record
              (assert (%evidence-record evidence :observed (getf record :id))))))))
    ;; Target-only elements are authored intent, absent from the current view.
    (assert (null (intersection *target-deployment-topics* (%ids current) :test #'equal)))
    (dolist (id *target-deployment-topics*)
      (let ((topic (%topic target id)))
        (assert (equal "deployment" (%property topic :kind)))
        (assert (equal "target" (%property topic :status)))
        (assert (eq (arch:architecture-page) (tm:topicmap-topic-object-of topic)))))
    ;; Exactly: the current nodes, the pages directory, the three target
    ;; relations and the two existing run-time Topics they deploy.
    (assert (%same-set-p (append *current-deployment-nodes* '("deployment/fedwiki-pages")
                                 *target-deployment-topics* '("http-connector" "fedwiki-m0"))
                         (%ids target)))
    ;; The run-time Topics are the page's own subjects, not copies: the same
    ;; Topic IDs standing for the same objects, their maturity unchanged.
    (dolist (id '("http-connector" "fedwiki-m0"))
      (assert (eq (tm:topicmap-topic-object-of (%topic page id))
                  (tm:topicmap-topic-object-of (%topic target id))))
      (assert (equal (tm:topicmap-topic-label-of (%topic page id))
                     (tm:topicmap-topic-label-of (%topic target id)))))
    (assert (equal "production" (%property (%topic target "http-connector") :status)))
    (assert (equal "production" (%property (%topic target "fedwiki-m0") :status)))
    ;; No deployment Topic claims a maturity or an epistemic status.
    (dolist (projection (list current target))
      (dolist (topic (tm:topicmap-projection-topics-of projection))
        (when (equal "deployment" (%property topic :kind))
          (assert (member (%property topic :status) '("current" "target") :test #'equal)))))
    (dolist (topic (tm:topicmap-projection-topics-of page))
      (assert (not (member (%property topic :status) '("current" "deployed" "observed") :test #'equal))))
    ;; The target keeps the ordinary path and adds the authoring chain.
    (dolist (edge '(("deployment/nginx-listeners" "deployment/hyperdoc-listener")
                    ("deployment/nginx-listeners" "deployment/authoring-route")
                    ("deployment/authoring-route" "http-connector")
                    ("deployment/listener-startup" "http-connector")
                    ("http-connector" "deployment/authority-configuration")
                    ("deployment/authority-configuration" "fedwiki-m0")
                    ("fedwiki-m0" "deployment/fedwiki-pages")))
      (assert (member edge (%pairs-of target) :test #'equal) () "The target lacks ~S." edge))
    ;; No invented FedWiki writer.
    (dolist (projection (list current target))
      (assert (notany (lambda (edge) (equal (first edge) "deployment/fedwiki-listener"))
                      (remove '("deployment/nginx-listeners" "deployment/fedwiki-listener")
                              (%pairs-of projection) :test #'equal))))
    ;; TALA lays out both; no geometry is authored; every shape and edge
    ;; is an Inspector reference.
    (dolist (entry (list (cons current #'arch:observed-deployment-layout)
                         (cons target #'arch:target-deployment-layout)))
      (let* ((input (tala:projection-tala-input (car entry)))
             (keys (mapcar (lambda (e) (getf e :d2-id)) (tala:tala-input-topics input)))
             (lines (remove "" (uiop:split-string (tala:tala-input-source input) :separator '(#\Newline))
                            :test #'string=)))
        (assert (= (length lines) (+ (length keys) (length (tala:tala-input-associations input)))))
        (let* ((rendering (funcall (cdr entry)))
               (projection (progn (assert (typep rendering 'tala:tala-rendering) () "No TALA layout: ~S" rendering)
                                  (tala:tala-input-projection (tala:tala-rendering-input rendering))))
               (view (find "TALA (interactive)" (views:all-views rendering)
                           :key #'views:view-title :test #'equal)))
          (assert (%same-set-p (%ids (car entry)) (%ids projection)))
          (views:view-html view)
          (assert (%same-set-p (append (tm:topicmap-projection-topics-of projection)
                                       (tm:topicmap-projection-associations-of projection))
                               (mapcar #'cdr (views:view-references view))))))))
  t)

(defun run-authoring-architecture-tests ()
  (let ((before (%page-sources)))
    (let ((route (check-catalog-registration)))
      (check-derivation)
      (check-properties)
      (check-bounded-challenge-evidence)
      (check-statuses)
      (check-connector-evidence)
      (check-deployment-projection)
      (check-runtime)
      (check-no-authored-geometry)
      (check-layouts)
      (check-graph-change)
      (check-no-rest-claims)
      (check-no-authoring-runtime)
      (assert (equal before (%page-sources)))
      (format t "~&AUTHORING-ARCHITECTURE-PASS: ~S found in Working on HyperDoc at ~A and ~
rendered; the derivation is the seven-constraint chain with requirement, constraint ~
and trade-off each; ten property claims, intended kept apart from demonstrated; ~
9a041fdd is the commit behind bounded challenges, with its source and tests; ~
the HTTP transport is production, prototyped in scratch, not deployed, ~
and the connector's two production commits are its evidence, no tooling commit; ~
the current deployment is drawn from selected supplied evidence, the target adds ~
the three missing relations, and neither claims more than the evidence; the run-time view has its components, ~
connectors and data, and nginx does not authenticate; no geometry is authored; ~
TALA lays out all three views and a changed graph, every shape and edge an ~
Inspector reference; native navigation reaches the commit; no REST or stateless ~
claim; no authoring runtime loaded; no page written.~%"
              *title* route)
      t)))
