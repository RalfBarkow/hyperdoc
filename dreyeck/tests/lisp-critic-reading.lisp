;;;; Contracts for the Lisp Critic genealogy reading.
;;;;
;;;; The reading claims three different kinds of access to three different
;;;; stations. These tests hold it to that: a documented station must stay
;;;; documented, and an executable one must actually execute.

(defpackage #:dreyeck/lisp-critic/reading/tests
  (:use #:cl)
  (:local-nicknames (#:reading #:dreyeck/lisp-critic/reading)
                    (#:dreyeck/asdf-source #:dreyeck/asdf-source)
                    (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:views #:html-inspector-views)
                    (#:tm #:dreyeck/topicmap)
                    (#:lp #:dreyeck/local-fedwiki-page))
  (:export #:run-tests #:run-current-tests #:check-under-catalog-runtime
           #:check-degraded-runtime #:check-trusted-examples-review
           #:check-code-rendering-decision
           ;; Tiers that need a source station: see dreyeck/tests/lisp-critic-engine-integration.lisp
           #:check-outcomes #:check-source-backing #:check-policy-in-a-clean-image #:check-workspace-section
           #:check-source-declaration #:check-execution-policy #:check-source-structure-projection
           #:car-cdr-fixture-text #:call-with-absent-station #:call-with-environment #:expect-failure))

(in-package #:dreyeck/lisp-critic/reading/tests)

(defparameter +pages+
  '("Reading the Lisp Critic Genealogy"
    "The Fischer Critic as an Environment"
    "Reading Riesbeck's Lisp Critic"
    "From Riesbeck Run to HyperDoc Critique"
    "Anatomy of a Critique"
    "Where the Source Lives"
    "Reading a Recorded Critique"
    "Lisp Critic on the Federated Context"
    "Reading the Trusted Executable Examples Review"
    "Deciding How Ordinary Code Story Items Are Rendered"
    "Code Rendering and Loaded Systems"
    "Code Rendering and the Inspector Link"))

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

;;
;; The runtime a check runs in.
;;
;; The engine is not part of this repository. It lives in a source station: the assets of a wiki page, on a machine that has it. Which
;; station a runtime finds is a property of that machine (DREYECK_LISP_CRITIC_ROOT, HYPERDOC_FEDWIKI_SITE_ROOT, HOME). The regular
;; checks must not depend on it, so they run with no station at all, and CALL-WITH-ABSENT-STATION makes that true instead of hoping:
;; it names empty places for all three and refuses to go on if the runtime still finds an engine. What needs a station is tested by
;; the integration tiers, which refuse to start without one.
;;

(defun call-with-environment (bindings thunk)
  "Call THUNK with the environment variables in BINDINGS, ((name . value) ...), set, restoring each afterwards. NIL means empty."
  (let ((saved (mapcar (lambda (entry) (cons (car entry) (uiop:getenv (car entry)))) bindings)))
    (unwind-protect
         (progn (dolist (entry bindings) (setf (uiop:getenv (car entry)) (or (cdr entry) "")))
                (funcall thunk))
      (dolist (entry saved) (setf (uiop:getenv (car entry)) (or (cdr entry) ""))))))

(defun call-with-absent-station (thunk)
  "Call THUNK in a runtime that finds no source station: HOME and the Wiki site root are empty directories and no explicit root is set."
  (let* ((base (uiop:ensure-directory-pathname
                (merge-pathnames (format nil "dreyeck-absent-station-~36R/" (random (expt 36 8) (make-random-state t)))
                                 (uiop:temporary-directory))))
         (home (merge-pathnames "home/" base))
         (site (merge-pathnames "site/" base)))
    (ensure-directories-exist home)
    (ensure-directories-exist site)
    (unwind-protect
         (call-with-environment
          (list (cons "HOME" (uiop:native-namestring home))
                (cons "HYPERDOC_FEDWIKI_SITE_ROOT" (uiop:native-namestring site))
                (cons "DREYECK_LISP_CRITIC_ROOT" nil))
          (lambda ()
            (check (not (reading:engine-available-p))
                   "The absent-station runtime could not be established: the engine is still reachable (~S)."
                   (multiple-value-list (reading::resolve-engine-asset-root)))
            (check (null (reading::resolve-engine-asset-root))
                   "The absent-station runtime still resolves an asset root.")
            (funcall thunk)))
      (uiop:delete-directory-tree base :validate t :if-does-not-exist :ignore))))

(defun expect-failure (label thunk &optional fragment)
  "THUNK must signal an error (whose message contains FRAGMENT): a check that cannot fail proves nothing. Returns the message."
  (let ((message (handler-case (progn (funcall thunk) nil) (error (condition) (princ-to-string condition)))))
    (unless message (error "The check did not fail for: ~A" label))
    (when (and fragment (not (search fragment message :test #'char-equal)))
      (error "The check failed for ~A, but by another message: ~A" label message))
    message))

(defun car-cdr-fixture-text ()
  "The recorded run of the CAR-CDR rule on (CAR (CDR ITEMS)): the 2004 engine's own output, written by the engine in a runtime that
could run it (dreyeck/tests/fixtures/lisp-critic/README.md). Read, never produced, by the regular checks."
  (uiop:read-file-string (asdf:system-relative-pathname "dreyeck" "dreyeck/tests/fixtures/lisp-critic/car-cdr-run-snapshot.json")
                         :external-format :utf-8))

(defun page-of (title)
  (hyperbook:find-page reading:*lisp-critic-reading* title :signal-error? t))

(defun page-elements (page tag)
  (plump:get-elements-by-tag-name (hyperdoc::dom-of page) tag))

(defun page-package (page)
  (let* ((tags (plump:get-elements-by-tag-name
                (plump:parse (hyperdoc:file-of page)) "in-package"))
         (name (and (= 1 (length tags))
                    (string-trim '(#\Space #\Tab #\Newline #\Return)
                                 (plump:text (first tags))))))
    (check name "Page ~S does not declare exactly one IN-PACKAGE."
           (hyperbook:id-of page))
    (or (find-package (string-upcase name))
        (error "Page ~S names missing package ~S."
               (hyperbook:id-of page) name))))

(defun element-texts (page tag)
  (mapcar (lambda (element)
            (string-trim '(#\Space #\Tab #\Newline #\Return)
                         (plump:text element)))
          (page-elements page tag)))

(defun page-expressions (page)
  (loop for element in (page-elements page "a")
        for expression = (plump:attribute element "expr")
        when expression collect expression))

(defun page-links (page)
  (loop for element in (page-elements page "a")
        for target = (plump:attribute element "page")
        when target collect target))

;;
;; 2. Every intended page is present in the book
;;

(defun check-pages-present ()
  (check (= (length +pages+)
            (hash-table-count (hyperdoc:pages-of reading:*lisp-critic-reading*)))
         "The reading book holds ~D pages instead of ~D."
         (hash-table-count (hyperdoc:pages-of reading:*lisp-critic-reading*))
         (length +pages+))
  (dolist (title +pages+)
    (check (page-of title) "Reading page ~S is missing." title))
  (check (string= "Reading the Lisp Critic Genealogy"
                  (hyperbook:main-page-id-of reading:*lisp-critic-reading*))
         "Unexpected main page ~S."
         (hyperbook:main-page-id-of reading:*lisp-critic-reading*))
  t)

;;
;; 8. Native navigation: the entry page reaches all the others, and every
;;    other page returns to it.
;;

(defun check-navigation ()
  (let ((entry (page-links (page-of "Reading the Lisp Critic Genealogy"))))
    (dolist (title (rest +pages+))
      (check (member title entry :test #'string=)
             "The entry page does not link to ~S." title)))
  (dolist (title (rest +pages+))
    (check (member "Reading the Lisp Critic Genealogy"
                   (page-links (page-of title)) :test #'string=)
           "Page ~S has no link back to the entry page." title))
  t)

;;
;; 3. + 4. Transclusions resolve, and every addressed example runs
;;

(defun check-example-result (value expression title where)
  "An addressed example must run, and a plist result must say what it rests on.

This rule held in two places once — the page check and the Catalog
runtime check — and a passage added to a page passed the first and failed
the second. Writing it once is the fix; the WHERE argument is all the two
callers actually differed by.

Which field answers depends on the kind. A source passage is not evidence
for anything by itself: what it has to declare is whether its wording was
read here. What no plist may do is declare nothing."
  (check (not (typep value 'condition))
         "~A: ~S on ~S produced ~A." where expression title value)
  (when (and (consp value) (keywordp (first value)))
    (case (getf value :kind)
      (:source-passage
       (check (nth-value 2 (get-properties value '(:passage-observed-p)))
              "~A: ~S on ~S returned a passage that does not say whether ~
it was read here." where expression title)
       (check (getf value :passage-origin)
              "~A: ~S on ~S returned a passage without an origin."
              where expression title))
      ;; A recommendation is not evidence and must not claim to be: what it
      ;; declares is what it addresses and what it predicts.
      (:reduction-proposal
       (check (not (nth-value 2 (get-properties value '(:evidence-status))))
              "~A: ~S on ~S returned a recommendation with an evidence status."
              where expression title)
       (check (and (getf value :addresses) (getf value :predictions))
              "~A: ~S on ~S returned a recommendation without what it addresses and predicts."
              where expression title))
      (t
       (check (getf value :evidence-status)
              "~A: ~S on ~S returned a plist without an evidence status."
              where expression title))))
  t)

(defun check-transclusions-and-examples ()
  (dolist (title +pages+)
    (let* ((page (page-of title))
           (*package* (page-package page)))
      ;; Every <source-of-function> must name something defined.
      (dolist (name (element-texts page "source-of-function"))
        (multiple-value-bind (symbol position) (read-from-string name)
          (check (= position (length name))
                 "Page ~S: source reference ~S has trailing syntax."
                 title name)
          (check (fboundp symbol)
                 "Page ~S transcludes undefined ~S." title symbol)))
      ;; Every <view-transclusion> must evaluate to a renderable view.
      (dolist (expression (element-texts page "view-transclusion"))
        (let ((value (hyperdoc::parse-and-eval expression)))
          (check (not (typep value 'condition))
                 "Page ~S: transclusion ~S produced ~A."
                 title expression value)
          (check (plusp (length (views:view-html value)))
                 "Page ~S: transclusion ~S rendered nothing."
                 title expression)))
      ;; Every addressed example must run and, if it is a plist, say what
      ;; it rests on.
      (dolist (expression (page-expressions page))
        (check-example-result (hyperdoc::parse-and-eval expression)
                              expression title "Page"))))
  t)

;;
;; The genealogy must keep the two lines apart
;;

(defun check-genealogy-separation ()
  (let* ((stations (reading:lisp-critic-genealogy))
         (fischer (reading:lisp-critic-station :fischer-lisp-critic))
         (riesbeck (reading:lisp-critic-station :riesbeck-lisp-critic)))
    (check (eq :documented (getf fischer :evidence-status))
           "Fischer's station claims ~S rather than :DOCUMENTED."
           (getf fischer :evidence-status))
    (check (null (getf fischer :executable-here))
           "Fischer's station claims to be executable here.")
    (check (eq :executable (getf riesbeck :evidence-status))
           "Riesbeck's station claims ~S rather than :EXECUTABLE."
           (getf riesbeck :evidence-status))
    ;; Relations live in the projection and nowhere else. A station plist
    ;; that carries its own predecessor or successor is a second model of
    ;; the same edges, and the two drifted apart once already.
    (dolist (station stations)
      (dolist (key '(:relation-to-predecessor :relation-to-successor))
        (check (not (nth-value 2 (get-properties station (list key))))
               "Station ~S carries ~S; relations belong to the projection."
               (getf station :station) key)))
    ;; The relation across the two lines must remain a comparison, and no
    ;; edge anywhere may claim descent. Asked of the graph itself.
    (let* ((projection (reading:lisp-critic-genealogy-projection))
           (associations (tm:topicmap-projection-associations-of projection))
           (crossing (find "comparison" associations
                           :key #'tm:topicmap-association-id-of
                           :test #'equal)))
      (check crossing "The cross-line association is gone.")
      (check (eq :conceptual-comparison
                 (tm:topicmap-association-type-of crossing))
             "The cross-line association is typed ~S."
             (tm:topicmap-association-type-of crossing))
      (dolist (association associations)
        (check (not (eq :descends-from
                        (tm:topicmap-association-type-of association)))
               "Association ~S claims descent, which no local evidence ~
supports." (tm:topicmap-association-id-of association))))
    ;; The unevidenced claims must stay listed rather than quietly adopted.
    (let ((claims (reading::fischer-claims-without-local-evidence)))
      (check claims "The unevidenced Fischer claims disappeared.")
      (dolist (claim claims)
        (check (eq :none (getf claim :local-evidence))
               "Claim ~S is no longer marked as unevidenced."
               (getf claim :claim)))))
  t)

;;
;; Provenance of historical statements
;;

(defparameter +fischer-subjects+
  '(:fischer-1987 :lisp-critic-version-1 :lisp-critic-version-2
    :lisp-critic-later :lisp-critic-zmacs :critiquing-paradigm)
  "Subjects on the research line. Nothing here is present in this workspace.")

(defun claim-uncarried-p (claim)
  (eq :none-observed (getf claim :observed-evidence-kind)))

(defun topic-ids (projection)
  (mapcar #'tm:topicmap-topic-id-of (tm:topicmap-projection-topics-of projection)))

(defun associations-of-type (projection type)
  (remove-if-not (lambda (a) (eq type (tm:topicmap-association-type-of a)))
                 (tm:topicmap-projection-associations-of projection)))

(defparameter +research-topics+
  '("fischer-lisp-critic" "documented-later-versions" "critiquing-paradigm"))
(defparameter +code-topics+
  '("riesbeck-lisp-critic" "beane-asdf-adaptation"
    "a-critic-for-lisp-station" "dreyeck-lisp-critic"))

(defun check-genealogy-projection ()
  "Two lines, spatially separate, with no lineage edge between them."
  (let* ((projection (reading:lisp-critic-genealogy-projection))
         (topics (tm:topicmap-projection-topics-of projection))
         (ids (topic-ids projection)))
    (dolist (id (append +research-topics+ +code-topics+))
      (check (member id ids :test #'string=)
             "The genealogy is missing topic ~S." id))
    ;; 3. The lines are shown separately: distinct x columns.
    (flet ((column (id)
             (getf (tm:topicmap-topic-view-properties-of
                    (find id topics :key #'tm:topicmap-topic-id-of
                                    :test #'string=))
                   :x)))
      (let ((research (remove-duplicates (mapcar #'column +research-topics+)))
            (code (remove-duplicates (mapcar #'column +code-topics+))))
        (check (= 1 (length research))
               "The research line is not in one column: ~S." research)
        (check (= 1 (length code))
               "The code line is not in one column: ~S." code)
        (check (/= (first research) (first code))
               "Both lines share column ~S." (first research))))
    ;; 4. No edge of any lineage type crosses between the two lines.
    (dolist (association (tm:topicmap-projection-associations-of projection))
      (let ((from (tm:topicmap-association-from-of association))
            (to (tm:topicmap-association-to-of association))
            (type (tm:topicmap-association-type-of association)))
        (when (or (and (member from +research-topics+ :test #'string=)
                       (member to +code-topics+ :test #'string=))
                  (and (member from +code-topics+ :test #'string=)
                       (member to +research-topics+ :test #'string=)))
          (check (eq :conceptual-comparison type)
                 "A ~S edge crosses between the two lines (~A -> ~A). Only a ~
conceptual comparison may cross." type from to))))
    ;; 5. Every visible station carries an object to inspect.
    (dolist (topic topics)
      (check (tm:topicmap-topic-object-of topic)
             "Topic ~S carries no object, so it cannot be inspected."
             (tm:topicmap-topic-id-of topic))))
  t)

(defun check-discourse-projection ()
  "Only explicitly defined questions, claims and support relations."
  (let* ((projection (reading:lisp-critic-genealogy-discourse))
         (topics (tm:topicmap-projection-topics-of projection)))
    (flet ((of-type (type)
             (remove-if-not (lambda (topic)
                              (eq type (tm:topicmap-topic-type-of topic)))
                            topics)))
      (check (= 3 (length (of-type :question)))
             "Expected three questions, found ~D." (length (of-type :question)))
      (check (= 3 (length (of-type :claim)))
             "Expected three claims, found ~D." (length (of-type :claim)))
      (check (= 3 (length (of-type :source)))
             "Expected three sources, found ~D." (length (of-type :source))))
    ;; Every association is one of the two declared discourse relations.
    (dolist (association (tm:topicmap-projection-associations-of projection))
      (check (member (tm:topicmap-association-type-of association)
                     '(:answered-by :supported-by))
             "The discourse holds an undeclared relation ~S."
             (tm:topicmap-association-type-of association)))
    (check (= 3 (length (associations-of-type projection :answered-by)))
           "Every question must be answered exactly once.")
    (check (= 3 (length (associations-of-type projection :supported-by)))
           "Every claim must name its support.")
    ;; Each claim reaches the provenance records behind it.
    (dolist (topic topics)
      (when (eq :claim (tm:topicmap-topic-type-of topic))
        (check (getf (tm:topicmap-topic-object-of topic) :related-claims)
               "Discourse claim ~S reaches no provenance record."
               (tm:topicmap-topic-id-of topic)))))
  t)

(defun check-reading-page-is-readable ()
  "The entry page argues; it does not expose the metamodel."
  (let* ((page (page-of "Reading the Lisp Critic Genealogy"))
         (expressions (page-expressions page))
         (source (uiop:read-file-string (hyperdoc:file-of page))))
    (check (<= (length expressions) 3)
           "The entry page addresses ~D examples; it should offer a few ~
entry points, not a catalogue: ~S" (length expressions) expressions)
    (dolist (expression '("(lisp-critic-genealogy-example)"
                          "(lisp-critic-discourse-example)"
                          "(current-critique-example)"))
      (check (member expression expressions :test #'string=)
             "The entry page does not offer ~A." expression))
    ;; The metamodel moved off this page but stays reachable elsewhere.
    (dolist (moved '("historical-claims-example" "evidence-adequacy-example"
                     "evidence-ladder-example"))
      (check (not (search moved source))
             "The entry page still exposes ~A." moved))
    (check (null (element-texts page "source-of-function"))
           "The entry page still transcludes implementation source."))
  t)

(defun check-genealogy-reads-as-domain-language ()
  "No visible node may explain itself in the projection's own jargon.

STATION is this projection's word for a box in a diagram; UNSPECIFIED is
the absence of an answer. Both were on every node, where the kind of
thing and its status belong. The internal type stays — it is still on
the element's data- attribute — but it is no longer what the reader is
shown."
  (let* ((projection (reading:lisp-critic-genealogy-projection))
         (topics (tm:topicmap-projection-topics-of projection))
         (html (views:view-html
                (find "Topicmap" (views:all-views projection)
                      :key #'views:view-title :test #'equal))))
    (check html "The genealogy renders no Topicmap view.")
    ;; The caption is what a reader sees under the name. What is banned is
    ;; a segment that IS the internal vocabulary, not a segment that
    ;; happens to contain one of those words, while "STATION" on its own
    ;; explains nothing.
    (dolist (topic topics)
      (let* ((caption (dreyeck/inspector/topicmap::topicmap-topic-caption topic))
             (segments (uiop:split-string caption :separator "·")))
        (check (plusp (length caption))
               "Node ~S has no caption." (tm:topicmap-topic-id-of topic))
        (dolist (segment segments)
          (let ((segment (string-trim " " segment)))
            (dolist (word '("STATION" "DOCUMENTED-STAGE" "UNSPECIFIED"))
              (check (not (string-equal word segment))
                     "Node ~S is captioned with the internal type ~S."
                     (tm:topicmap-topic-id-of topic) segment))
            (check (not (search "UNSPECIFIED" segment :test #'char-equal))
                   "Node ~S is captioned ~S." (tm:topicmap-topic-id-of topic)
                   caption)))))
    ;; "Workspace" is a reserved word here: it names a subject with a
    ;; discovery/offer/materialization lifecycle elsewhere in this system.
    ;; A node whose source status borrows it to mean "in the checkout I am
    ;; standing in" spends that distinction. The node already knows
    ;; something sharper, so it must say that instead.
    (dolist (topic topics)
      (let ((caption (dreyeck/inspector/topicmap::topicmap-topic-caption topic)))
        (check (not (search "workspace" caption :test #'char-equal))
               "Node ~S says ~S, but workspace means something else here."
               (tm:topicmap-topic-id-of topic) caption)))
    (dolist (station (reading:lisp-critic-genealogy))
      (let ((status (symbol-name (getf station :source-availability))))
        (check (not (search "WORKSPACE" status))
               "Station ~S records its source as ~A."
               (getf station :station) status)))
    ;; The scope column said the same nothing on every row, so it is not
    ;; shown. The internal values stay on the element's data- attributes,
    ;; which is why this looks at the reader's table and not at the markup
    ;; as a whole.
    (check (not (search "Temporal scope" html))
           "The genealogy still shows an empty Temporal scope column.")
    ;; Case alone may not be what tells the two systems apart.
    (let ((labels (mapcar #'tm:topicmap-topic-label-of topics)))
      (check (= (length labels)
                (length (remove-duplicates labels :test #'string-equal)))
             "Two nodes are distinguished only by case: ~S." labels)
      (check (find-if (lambda (label) (search "Fischer" label)) labels)
             "No node names Fischer.")
      (check (find-if (lambda (label) (search "Riesbeck" label)) labels)
             "No node names Riesbeck.")))
  t)

(defun station-primary-html (key)
  (let* ((station (reading:lisp-critic-station key))
         (view (first (views:all-views station))))
    (values (views:view-html view) station)))

(defun check-asset-root-resolution ()
  "A page's identity must survive a change of machine; a path must not.

The served runtime showed an asset root under a home directory that
does not exist there, and then reported the page unread, the assets
unavailable and the ASDF component missing. Those were symptoms: the
resolution happened before ASDF, against a site name compiled in from
the machine the engine was first read on.

These cases are written against directories this test makes, so that
none of them depends on this machine's home, host name or wiki."
  (let* ((slug reading::+engine-page-slug+)
         (relative (format nil "assets/pages/~A/" slug)))
    (check (stringp slug) "The engine page has no stable slug.")
    ;; 1. A runtime whose configured site holds the page resolves it,
    ;;    and says that is how it resolved.
    (let* ((site (uiop:ensure-directory-pathname
                  (merge-pathnames "dreyeck-asset-resolution-site/"
                                   (uiop:temporary-directory))))
           (assets (merge-pathnames relative site)))
      (unwind-protect
           (progn
             (ensure-directories-exist assets)
             (uiop:with-current-directory ((uiop:getcwd))
               (let ((original (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT")))
                 (unwind-protect
                      (progn
                        (setf (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT")
                              (namestring site))
                        (multiple-value-bind (root source)
                            (reading::resolve-engine-asset-root)
                          (check (equal (truename assets) (truename root))
                                 "A configured site holding the page resolved ~
to ~A instead of ~A." root assets)
                          (check (eq :configured-site-root source)
                                 "It resolved by ~S rather than by the ~
configured site." source)))
                   (setf (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT")
                         (or original ""))))))
        (uiop:delete-directory-tree site :validate t :if-does-not-exist :ignore)))
    ;; 2. The same identity under a different absolute root, with no
    ;;    change to code or data.
    (let* ((other (uiop:ensure-directory-pathname
                   (merge-pathnames "dreyeck-asset-resolution-other/"
                                    (uiop:temporary-directory))))
           (assets (merge-pathnames relative other)))
      (unwind-protect
           (progn
             (ensure-directories-exist assets)
             (let ((original (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT")))
               (unwind-protect
                    (progn
                      (setf (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT")
                            (namestring other))
                      (check (equal (truename assets)
                                    (truename (reading::resolve-engine-asset-root)))
                             "The same page did not resolve under a second root."))
                 (setf (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT")
                       (or original "")))))
        (uiop:delete-directory-tree other :validate t :if-does-not-exist :ignore)))
    ;; 3. An explicit root that does not exist must leave the runtime
    ;;    unresolved rather than quietly using somewhere else, and the
    ;;    view must say so without printing a path as though it held.
    (let ((original (uiop:getenv "DREYECK_LISP_CRITIC_ROOT")))
      (unwind-protect
           (progn
             (setf (uiop:getenv "DREYECK_LISP_CRITIC_ROOT")
                   "/nonexistent/dreyeck-asset-resolution/")
             (multiple-value-bind (root source candidates)
                 (reading::resolve-engine-asset-root)
               (check (null root) "An absent explicit root still resolved to ~A."
                      root)
               (check (null source) "An unresolved runtime named a source.")
               (check (= 1 (length candidates))
                      "An explicit root did not stop the search: ~S."
                      (mapcar #'car candidates)))
             (let* ((station (reading:lisp-critic-station
                              :a-critic-for-lisp-station))
                    (html (views:view-html (first (views:all-views station)))))
               (check (search "Not resolved here" html)
                      "An unresolved runtime does not say so.")
               (check (not (search "Asset root:" html))
                      "An unresolved runtime still prints an asset root.")))
        (setf (uiop:getenv "DREYECK_LISP_CRITIC_ROOT") (or original ""))))
    ;; The identity itself may not contain anyone's home directory.
    (check (not (search "/Users/" relative))
           "The relative asset location is not relative.")
    (check (not (search "/home/" relative))
           "The relative asset location is not relative."))
  t)

(defun with-server-parameters (parameters thunk)
  "Run THUNK as though a server had been started with PARAMETERS.

NIL stands for no server at all.

Binds the variable the server itself writes, in the package the server
itself defines, and loads that system to get at it. An earlier version
made a package of its own when none was found — and so passed while
the policy was reading a package name that does not exist, which meant
it permitted everything everywhere. A test that can invent what it is
testing against proves nothing."
  (asdf:load-system "hyperbook/server")
  (let* ((package (find-package :hyperbook/server))
         (symbol (and package (find-symbol "*SERVER-PARAMETERS*" package))))
    (check package "The server package is absent; the policy reads nothing.")
    (check symbol "The server does not define *SERVER-PARAMETERS*.")
    (let* ((had (boundp symbol))
           (old (and had (symbol-value symbol))))
      (unwind-protect
           (progn (setf (symbol-value symbol) parameters) (funcall thunk))
        (if had (setf (symbol-value symbol) old) (makunbound symbol))))))

(defun scanned-declaration (source)
  "Run the preview's own extraction over SOURCE, without touching disk."
  (multiple-value-bind (nodes issues)
      (dreyeck/asdf-source:scan-asdf-source source)
    (let ((form (find-if #'dreyeck/asdf-source:asdf-defsystem-form-p nodes)))
      (list :form form :issues issues
            :name (and form
                       (dreyeck/asdf-source:simple-asdf-designator-name
                        (second (dreyeck/asdf-source:asdf-source-node-children form))))))))

(defun with-evaluation-snapshot (contents thunk)
  "Run THUNK with a page-attached evaluation snapshot of CONTENTS.

Builds its own site root under the temporary directory and points the
runtime at it, so nothing is written into anyone's wiki. CONTENTS NIL
means the file is absent."
  (let* ((site (uiop:ensure-directory-pathname
                (merge-pathnames "dreyeck-evaluation-snapshot-site/"
                                 (uiop:temporary-directory))))
         (assets (merge-pathnames
                  (format nil "assets/pages/~A/" reading::+engine-page-slug+)
                  site))
         (file (merge-pathnames reading::+engine-evaluation-snapshot+ assets))
         (original (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT")))
    (unwind-protect
         (progn
           (ensure-directories-exist file)
           (if contents
               (with-open-file (out file :direction :output :if-exists :supersede)
                 (write-string contents out))
               (ignore-errors (delete-file file)))
           (setf (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT") (namestring site))
           (funcall thunk))
      (setf (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT") (or original ""))
      (uiop:delete-directory-tree site :validate t :if-does-not-exist :ignore))))

(defun check-critique-from-snapshot ()
  "The reading shows a recorded evaluation, and never produces one.

This example used to run the critic while the page was being drawn,
which loaded the engine out of the page's own assets. It now reads a
record that a runtime allowed to run the critic wrote (the committed
fixture; that the fixture is still what the engine says is the integration
tier's check). There is no
fallback on purpose: a fallback is how an absent result becomes an
execution."
  ;; A recorded evaluation is shown. The record is the engine's own, committed; this check never runs the engine.
  (let ((snapshot (car-cdr-fixture-text)))
    (with-evaluation-snapshot
        snapshot
      (lambda ()
        (let* ((registered (length (asdf:registered-systems)))
               (result (reading:current-critique-example)))
          (check (typep result 'critic:critic-target)
                 "Reading a snapshot produced ~S rather than a target." result)
          (let* ((record (first (critic:target-runs-of result)))
                 (html (views:view-html
                        (first (views:all-views result)))))
            (check record "The reconstituted target carries no run.")
            (check (critic:critiques-of record) "The run carries no critique.")
            (check (search "CAR (CDR ITEMS)" html)
                   "The rendered critique does not show the evaluated input.")
            (dolist (object (list record (critic:rule-of record)
                                  (first (critic:critiques-of record))))
              (check (plusp (length (views:view-html
                                     (first (views:all-views object)))))
                     "A reconstituted object rendered nothing.")))
          (check (= registered (length (asdf:registered-systems)))
                 "Reading a snapshot registered an ASDF system.")))))
  ;; An absent record stays absent.
  (with-evaluation-snapshot
      nil
    (lambda ()
      (let ((result (reading:current-critique-example)))
        (check (eq :evaluation-snapshot-unavailable (getf result :kind))
               "A missing record produced ~S instead of an absence." result)
        (let ((html (views:view-html (first (views:all-views result)))))
          (check (search "No trusted evaluation record is available here" html)
                 "The absence is not stated in the view.")))))
  ;; A record that cannot be read is reported, not worked around.
  (with-evaluation-snapshot
      "{ this is not valid json"
    (lambda ()
      (let ((result (reading:current-critique-example)))
        (check (eq :evaluation-snapshot-unavailable (getf result :kind))
               "A malformed record produced ~S." result)
        (check (search "could not be read" (getf result :why))
               "A malformed record was not reported as unreadable: ~A"
               (getf result :why)))))
  ;; A record from a contract this reading does not know is refused by
  ;; version rather than half-read.
  (with-evaluation-snapshot
      "{\"snapshot-version\": 99, \"evaluation\": {}}"
    (lambda ()
      (let ((result (reading:current-critique-example)))
        (check (eq :evaluation-snapshot-unavailable (getf result :kind))
               "A future snapshot version was accepted.")
        (check (search "version" (getf result :why))
               "A version mismatch was not named as one: ~A"
               (getf result :why)))))
  t)

(defun check-source-declaration ()
  "The definition file is read as text, and only as text.

A file question — what does this .asd say — used to be answered by
registering the system, because FIND-SYSTEM was the nearest thing to
hand. It is now read, and where the source does not spell something
out the preview says so rather than asking a runtime instead."
  (let ((declaration (reading:engine-asdf-source-declaration)))
    (check (getf declaration :read-p)
           "The definition file was not read as text: ~A" (getf declaration :why))
    (check (getf declaration :defsystem-p)
           "No defsystem form was found in the definition file.")
    (check (equal "a-critic-for-lisp" (getf declaration :name))
           "The declared system name reads ~S." (getf declaration :name))
    (check (equal '("uiop") (getf declaration :depends-on))
           "The declared dependencies read ~S." (getf declaration :depends-on))
    ;; The nesting survives: a module keeps its own components.
    (let* ((components (getf declaration :components))
           (module (find "module" components
                         :key (lambda (c) (getf c :kind)) :test #'equal)))
      (check (find "package" components
                   :key (lambda (c) (getf c :name)) :test #'equal)
             "The top-level file component is missing.")
      (check module "The module component is missing.")
      (check (= 2 (length (getf module :components)))
             "The module lost its own components."))
    (check (null (getf declaration :issues))
           "This definition produced scanner issues: ~S"
           (getf declaration :issues)))
  ;; The two witnesses must be shown, and agreement must be a finding
  ;; rather than an assumption.
  (let* ((station (reading:lisp-critic-station :a-critic-for-lisp-station))
         (html (views:view-html (first (views:all-views station)))))
    (check (search "ASDF source declaration" html)
           "The view does not show what the source declares.")
    (check (search "source binding expects" html)
           "The view does not show what the binding expects.")
    (check (search "the two witnesses" html)
           "The view does not compare the two witnesses."))
  ;; What the source does not settle stays unsettled: no runtime fallback.
  (let ((computed (scanned-declaration "(defsystem (compute-name))")))
    (check (getf computed :form) "A computed-name definition was not found.")
    (check (null (getf computed :name))
           "A computed system name was resolved to ~S instead of left unknown."
           (getf computed :name)))
  (check (null (getf (scanned-declaration
                      "(when (probe-file \"x\") (defsystem #:hidden))")
                     :form))
         "A nested definition was reported as top-level.")
  (check (getf (scanned-declaration "(defsystem #:x :depends-on #.(list :uiop))")
               :issues)
         "Read-time evaluation was passed over without an issue.")
  (check (getf (scanned-declaration "#| unterminated") :issues)
         "Malformed source produced no issue.")
  (check (equal "x" (getf (scanned-declaration
                           "(defsystem #:x #+sbcl :depends-on #+sbcl (#:uiop))")
                          :name))
         "A feature conditional prevented reading the name.")
  (check (equal "quoted" (getf (scanned-declaration "(defsystem \"quoted\")") :name))
         "A string system name was not read.")
  t)

(defun check-reading-examples-honour-the-policy ()
  "No reading example may load a page's code on a runtime that refuses to.

The invariant is not that these particular examples happen to stay
inert. It is that under a refusing policy no path through the reading
examples crosses the one boundary where registering and loading the
page-attached system happens — so the test drives the examples that
used to cross it and measures what the attempt added.

Differentially, because the suite around it has already loaded the
engine on purpose. Asserting that the packages are absent would assert
the order of this suite; asserting that the attempt added none of them
is the contract. Under a refusing policy that difference must be empty
even when the engine is already present, since what is forbidden is
bringing it in, not having it.

The recorded evaluation must stay readable throughout. A runtime that
refuses to run the Critic is exactly the runtime the snapshot exists
for, so a refusal that also silenced the recorded finding would have
traded one failure for another."
  (let ((engine-packages '(:lisp-critic :lisp-critic-user
                           :extend-match :a-critic-for-lisp))
        (crossing-examples '(reading:critique-anatomy-example
                             reading:riesbeck-car-cdr-rule-example
                             reading:evidence-ladder-example)))
    (with-server-parameters
        (list "700px" nil)
      (lambda ()
        (check (not (reading:execution-permitted-p))
               "The served runtime without development still permits execution.")
        (dolist (name crossing-examples)
          (let ((systems-before (length (asdf:registered-systems)))
                (packages-before (remove-if-not #'find-package engine-packages)))
            ;; The example may fail; what it may not do is load anything.
            (ignore-errors (funcall name))
            (let ((added (set-difference
                          (remove-if-not #'find-package engine-packages)
                          packages-before)))
              (check (null added)
                     "~S brought in ~S on a runtime that refuses page-attached ~
code." name added))
            (check (= systems-before (length (asdf:registered-systems)))
                   "~S registered ~D system(s) on a runtime that refuses ~
page-attached code." name
                   (- (length (asdf:registered-systems)) systems-before))))
        ;; And the recorded finding is still there to be read.
        (with-evaluation-snapshot
            (car-cdr-fixture-text)
          (lambda ()
            (let ((target (reading:current-critique-example)))
              (check (typep target 'critic:critic-target)
                     "The recorded evaluation is unreadable under a refusing ~
policy; it returned ~S." (and (listp target) (getf target :kind)))
              (let ((record (first (critic:target-runs-of target))))
                (check record "The recorded evaluation carries no run.")
                (check (= 1 (length (critic:critiques-of record)))
                       "The recorded evaluation lost its critique."))))))))
  t)

(defun check-execution-policy ()
  "A runtime that does not run page-attached code must refuse, not just hide.

The reconstruction button is wired by the inspector like any other eval
reference, with no reference to the playground flag, so absence of the
button would have been the only barrier. It is not enough: a caller
reaching the operation another way must meet the same answer. The flag
is the one the playground already answers to, not a second switch."
  (let ((before reading::*engine-workspace-reconstructions*))
    ;; Served, without development: both ways must be closed.
    (with-server-parameters
        (list "700px" nil)
      (lambda ()
        ;; Drawing the node must not evaluate the page's definition.
        ;; Two things did: reading the ASDF definition, and asking
        ;; eligibility — both call FIND-SYSTEM, which runs the .asd.
        ;; Neither was guarded, so opening this node on the served site
        ;; ran the file.
        (let* ((registered (length (asdf:registered-systems)))
               (station (reading:lisp-critic-station :a-critic-for-lisp-station))
               (html (views:view-html (first (views:all-views station)))))
          ;; The delta, not the absolute count: an earlier check in this
          ;; image may already have materialized, and what matters is
          ;; that drawing adds nothing.
          (check (= registered (length (asdf:registered-systems)))
                 "Rendering the node evaluated the page's definition: ~D ~
systems became ~D." registered (length (asdf:registered-systems)))
          ;; And the view must say why it is not showing a definition,
          ;; rather than quietly showing one it read anyway.
          (check (search "does not evaluate code that arrived with a page"
                         html)
                 "The view does not say why the definition is unread.")
          (check (search "would evaluate the page" html)
                 "The view does not say why eligibility is unasked.")
          ;; Declining to read is not the same as having nothing to say.
          (check (search "Expected from the source binding" html)
                 "A runtime that declines shows no preview of what it declined.")
          ;; The inert reading of the file is shown whether or not the
          ;; runtime will evaluate it: it is a fact about a file.
          (check (search "ASDF source declaration" html)
                 "A refusing runtime hides what the file itself declares.")
          (check (search "critic entrypoint" html)
                 "The preview does not name the entrypoint that would be called.")
          (check (search "Not knowable until it runs" html)
                 "The preview does not separate expectation from knowledge."))
        (check (not (reading:execution-permitted-p))
               "A served runtime without development permits execution.")
        (let* ((station (reading:lisp-critic-station :a-critic-for-lisp-station))
               (html (views:view-html (first (views:all-views station)))))
          (check (not (search "Reconstruct the workspace" html))
                 "A runtime that refuses execution still offers the button.")
          (check (search "not offered here" html)
                 "The view does not say why reconstruction is absent."))
        (check (handler-case (progn (reading:reconstruct-engine-workspace) nil)
                 (dreyeck/page-attached-system-projection:execution-not-permitted () t))
               "Calling reconstruction directly was not refused.")
        ;; Refused means nothing changed, not merely nothing returned.
        ;; Asked of a fresh offer: the shared one may already hold a
        ;; workspace from an earlier check, and an offer that already
        ;; has one is answered from the slot without executing anything.
        (let ((fresh (make-instance
                      'dreyeck/page-attached-workspace-offer:page-attached-workspace-offer
                      :id "workspace:a-critic-for-lisp"
                      :title "a-critic-for-lisp")))
          (check (handler-case
                     (progn
                       (dreyeck/page-attached-workspace-offer:materialize-page-attached-workspace
                        fresh)
                       nil)
                   (dreyeck/page-attached-system-projection:execution-not-permitted
                       () t))
                 "A refused runtime materialized a fresh offer.")
          (check (not (slot-boundp
                       fresh
                       'dreyeck/page-attached-workspace-offer::workspace))
                 "A refused materialization still bound the offer."))))
    (check (= before reading::*engine-workspace-reconstructions*)
           "A refused reconstruction still counted as one.")
    ;; Served with development, and no server at all, both allow.
    (with-server-parameters
        (list "700px" t)
      (lambda () (check (reading:execution-permitted-p)
                        "A development server refuses execution.")))
    (with-server-parameters
        nil
      (lambda () (check (reading:execution-permitted-p)
                        "An image with no server refuses execution."))))
  t)

(defun check-workspace-section ()
  "The Workspace section must report this runtime, and build nothing.

It used to answer \"not attempted here; the recorded observation is
that it does not resolve for this system\" — a finding from before the
reconstruction contract was repaired, presented as though it were
current. Two separate mistakes: a stored negative standing in for a
live one, and eligibility and reconstruction answered as one question."
  (let* ((station (reading:lisp-critic-station :a-critic-for-lisp-station))
         (before reading::*engine-workspace-reconstructions*)
         (html (views:view-html (first (views:all-views station))))
         (after reading::*engine-workspace-reconstructions*))
    ;; Drawing must not materialize. Reconstruction registers a system
    ;; with ASDF and mints a new workspace per call.
    (check (= before after)
           "Rendering the view reconstructed ~D workspace(s)." (- after before))
    (check (not (search "does not resolve for this system" html))
           "The view still shows the stale workspace finding.")
    ;; The three questions must be separately visible.
    (dolist (row '("page attachment" "workspace eligibility"
                   "workspace reconstruction"))
      (check (search row html) "The Workspace section lost the ~S row." row))
    (check (search "not run by this view" html)
           "The view no longer says that it does not reconstruct.")
    ;; Eligibility must come from the contract, not from a copy here.
    (let ((eligibility (reading:engine-workspace-eligibility)))
      (if (getf eligibility :eligible-p)
          (progn
            (check (search "eligible" html)
                   "The system is eligible but the view does not say so.")
            ;; An eligible system offers the action; an ineligible one
            ;; must not, since there would be nothing to run.
            (check (search "Reconstruct the workspace" html)
                   "An eligible system offers no way to reconstruct."))
          (check (search "not eligible" html)
                 "The system is ineligible but the view does not say why.")))
    ;; Materializing must be one transition on one object, whichever
    ;; route asks for it. Two routes existed: this action, which built a
    ;; workspace the offer never learned about, and LOOKUP-PATH, which
    ;; stored one. A second press built a second workspace.
    (when (getf (reading:engine-workspace-eligibility) :eligible-p)
      (let* ((offer (reading:engine-workspace-offer))
             (slot 'dreyeck/page-attached-workspace-offer::workspace)
             (before reading::*engine-workspace-reconstructions*)
             (first (reading:reconstruct-engine-workspace)))
        (check first "Materialization produced no workspace.")
        (check (slot-boundp offer slot)
               "Materializing left the offer unmaterialized.")
        (check (eq first
                   (dreyeck/page-attached-workspace-offer:page-attached-workspace-of
                    offer))
               "The returned workspace is not the one the offer holds.")
        (check (= (1+ before) reading::*engine-workspace-reconstructions*)
               "The first materialization was not counted once.")
        ;; A second ask returns the same one and builds nothing.
        (let ((second (reading:reconstruct-engine-workspace)))
          (check (eq first second)
                 "A second materialization produced a different workspace.")
          (check (= (1+ before) reading::*engine-workspace-reconstructions*)
                 "A second materialization reconstructed again."))
        ;; And the path route converges on it rather than making its own.
        (check (eq first (hyperbook:lookup-path offer nil))
               "LOOKUP-PATH and the inspector action disagree.")
        (check (search "a-critic-for-lisp"
                       (dreyeck/topicmap:topicmap-topic-id-of
                        (dreyeck/topicmap:topicmap-workspace-current-topic first)))
               "The workspace does not stand at this page's own definition."))))
  t)

(defun check-source-representations ()
  "No node may report another node's source or another node's runtime.

\"Source status\" asked one question of five objects that do not share
it. Its worst effect was on Riesbeck's node, which showed \"vendored in
source station\" and \"executable here: yes\" — both true of Beane's
adapted distribution, the one artifact actually on disk, and neither
true of a historical authorship node with no tree of its own."
  (let ((riesbeck (station-primary-html :riesbeck-lisp-critic))
        (beane (station-primary-html :beane-asdf-adaptation)))
    ;; The vocabulary this slice removes, wherever a reader could meet it.
    (dolist (key '(:fischer-lisp-critic :riesbeck-lisp-critic
                   :beane-asdf-adaptation :a-critic-for-lisp-station
                   :dreyeck-lisp-critic))
      (let ((html (station-primary-html key)))
        (dolist (phrase '("Source status" "vendored in source station"
                          "VENDORED-IN-SOURCE-STATION"
                          "present in local checkout"))
          (check (not (search phrase html :test #'char-equal))
                 "The view of ~S still shows ~S." key phrase))))
    ;; Riesbeck and Beane must not read the same.
    (check (not (equal riesbeck beane))
           "Riesbeck's node and Beane's node render identically.")
    (check (search "no separate" riesbeck :test #'char-equal)
           "Riesbeck's node does not say that no tree of its own was observed.")
    (check (not (search "vendored" riesbeck :test #'char-equal))
           "Riesbeck's node still calls something of its own vendored.")
    ;; Only the node whose artifact is on disk may claim the adaptation.
    (check (search "require/provide" beane)
           "Beane's node no longer shows what the adaptation changed.")
    (check (not (search "require/provide" riesbeck))
           "Riesbeck's node claims Beane's documented changes."))
  ;; Executability belongs to the artifact that runs, in every runtime.
  (let ((live (reading:genealogy-in-this-runtime)))
    (dolist (station live)
      (when (eq :riesbeck-lisp-critic (getf station :station))
        (check (null (getf station :executable-here))
               "Riesbeck's node reports itself executable; the artifact that ~
runs is Beane's adapted distribution.")))
    ;; And the distinction must not be achieved by calling everything
    ;; unexecutable: where the engine is here, Beane's node says so.
    (when (reading:engine-available-p)
      (let ((beane (find :beane-asdf-adaptation live
                         :key (lambda (s) (getf s :station)))))
        (check (getf beane :executable-here)
               "The engine is reachable but Beane's node reports otherwise."))))
  t)

(defun check-page-attached-system-view ()
  "a-critic-for-lisp must be inspectable as what was observed about it.

The node used to answer with the generic genealogy profile, whose
\"Source status\" said \"present in local checkout\" — wrong, because the
asset tree is outside every worktree, and too coarse, because wrapper
source, page assets and the vendored engine are three different things.

The contract is that the visible values are read from the objects that
hold them, not written into the view. Where the assets are reachable the
test compares the view against ASDF and against page discovery; where
they are not, it only requires the view to render and stay honest."
  (let* ((station (reading:lisp-critic-station :a-critic-for-lisp-station))
         (views (views:all-views station))
         (titles (mapcar #'views:view-title views))
         (primary (first views))
         (observation (reading:a-critic-for-lisp-observation))
         (attachment (getf observation :page-attachment))
         (discovery (getf attachment :discovery))
         (system (getf observation :wrapper-system))
         (html (views:view-html primary)))
    (check (equal "Page-attached ASDF wrapper system" (views:view-title primary))
           "The primary view for a-critic-for-lisp is ~S." (views:view-title primary))
    ;; Secondary views must survive; they are how the node stays a
    ;; genealogy node as well as a system.
    (dolist (title '("Relations" "Genealogy record" "Raw Lisp"))
      (check (member title titles :test #'equal)
             "The ~S view disappeared; titles are ~S." title titles))
    ;; The vocabulary this slice exists to remove.
    (dolist (phrase '("present in local checkout" "source station"
                      "source in the workspace" "vendored through"))
      (check (not (search phrase html :test #'char-equal))
             "The system view still says ~S." phrase))
    ;; Values must come from the observed objects.
    (when (getf attachment :asset-root-present-p)
      (check (search (getf discovery :page-title) html)
             "The view does not show the page title discovery reports.")
      (let ((asd (first (getf discovery :asdf-files))))
        (check asd "Page discovery found no system definition.")
        (check (search (file-namestring asd) html)
               "The view does not show the .asd that discovery found.")
        (check (getf system :read-p)
               "The wrapper system could not be read although its assets ~
are here: ~A" (getf system :why))
        ;; The .asd ASDF used and the .asd discovery found must agree.
        (check (equal (truename asd) (truename (getf system :source-file)))
               "Discovery found ~A but ASDF read ~A."
               asd (getf system :source-file))
        ;; Components must be the loaded system's, not a copy.
        (let ((names (mapcar #'car (getf system :components))))
          (dolist (component names)
            (check (search component html)
                   "Component ~S is missing from the view." component))
          (check (member "package" names :test #'equal)
                 "The observed components ~S do not look like the wrapper's."
                 names))))
    ;; The binding must not present a slot it never binds. Two such slots
    ;; sat on its class from its first version, were bound by no instance
    ;; and read by nothing, and answered an inspector with an
    ;; unbound-slot error while looking like properties of the object.
    (let ((binding (getf observation :binding)))
      (dolist (slot (sb-mop:class-slots (class-of binding)))
        (let ((name (sb-mop:slot-definition-name slot)))
          (check (slot-boundp binding name)
                 "The source binding leaves ~S unbound, which an inspector ~
shows as a property that errors when read." name))))
    ;; Page attachment is not a Workspace.
    (check (search "not itself a Workspace" html)
           "The view no longer separates page attachment from Workspace.")
    ;; The runtime rows must report this image, not a written-in answer.
    ;;
    ;; A page that shows a recorded finding claims the engine was not
    ;; needed to show it. That claim is only worth something if the
    ;; runtime says so about itself where the page is served, so the
    ;; test asks the image the same questions and requires the same
    ;; answers. It deliberately does not require any particular answer:
    ;; this image may well have loaded the engine, and a test that
    ;; demanded "no" would be asserting its own circumstances rather
    ;; than the view's honesty.
    (let ((loading (getf observation :loading)))
      (dolist (probe (list (cons :engine-loaded-here-p
                                 (and (find-package :lisp-critic) t))
                           (cons :engine-user-package-here-p
                                 (and (find-package :lisp-critic-user) t))
                           (cons :matcher-package-here-p
                                 (and (find-package :extend-match) t))
                           (cons :wrapper-package-here-p
                                 (and (find-package
                                       (getf loading :wrapper-package))
                                      t))
                           (cons :wrapper-system-registered-here-p
                                 (and (member (getf loading :wrapper-system)
                                              (asdf:registered-systems)
                                              :test #'string-equal)
                                      t))))
        (check (eq (getf loading (car probe)) (cdr probe))
               "The view reports ~S as ~S while this image says ~S."
               (car probe) (getf loading (car probe)) (cdr probe))))
    (dolist (label '("engine loaded" "engine user package" "matcher package"
                     "wrapper loaded" "wrapper system registered with ASDF"))
      (check (search label html)
             "The runtime row ~S is missing from the view." label)))
  t)

(defun check-node-view-shows-the-graph ()
  "The node detail must show the projection's edges, not its own copy.

Written because the detail view once reconstructed relations from fields
in the station plist. It showed Fischer one conceptual successor where
the graph gave two edges of different kinds, and it omitted the
documented one entirely. So the contract is equality with the
projection, checked edge for edge."
  (let* ((projection (reading:lisp-critic-genealogy-projection))
         (associations (tm:topicmap-projection-associations-of projection))
         (topics (tm:topicmap-projection-topics-of projection)))
    (dolist (topic topics)
      (let* ((id (tm:topicmap-topic-id-of topic))
             (relations (reading:genealogy-node-relations id))
             (expected-out
               (loop for a in associations
                     when (equal id (tm:topicmap-association-from-of a))
                       collect (cons (tm:topicmap-association-type-of a)
                                     (tm:topicmap-association-to-of a))))
             (actual-out
               (loop for edge in (getf relations :outgoing)
                     collect (cons (car edge)
                                   (and (cdr edge)
                                        (tm:topicmap-topic-id-of (cdr edge)))))))
        (check (null (set-exclusive-or expected-out actual-out :test #'equal))
               "Node ~S reports outgoing ~S but the graph has ~S."
               id actual-out expected-out)
        ;; Every neighbour must be resolvable, or the link is dead.
        (dolist (edge (append (getf relations :outgoing)
                              (getf relations :incoming)))
          (check (cdr edge) "Node ~S has a ~S edge to a node that is not in ~
the projection." id (car edge)))))
    ;; Fischer is the case that exposed the defect: two edges, two kinds.
    (let ((outgoing (getf (reading:genealogy-node-relations "fischer-lisp-critic")
                          :outgoing)))
      (check (= 2 (length outgoing))
             "Fischer's node reports ~D outgoing edges instead of 2."
             (length outgoing))
      (dolist (type '(:documented-successor :conceptual-comparison))
        (check (assoc type outgoing)
               "Fischer's node does not report its ~S edge." type))))
  t)

(defun check-station-claim-links ()
  "A station's claims must be declared, not guessed, and must exist.

The station keys and the claim subjects are different vocabularies on
purpose. While nothing joined them, every station rendered \"no claims\"
and looked like a settled epistemic finding instead of a missing link."
  (let ((subjects (mapcar (lambda (claim) (getf claim :subject))
                          (reading:historical-claims))))
    (dolist (station (reading:lisp-critic-genealogy))
      (let ((key (getf station :station)))
        (check (assoc key reading::+claim-subjects-relevant-to-node+)
               "Station ~S declares no claim subjects, not even none." key)
        (dolist (subject (reading:claim-subjects-relevant-to-node key))
          (check (member subject subjects)
                 "Station ~S points at subject ~S, about which there are no ~
claims." key subject)))))
  ;; The station that prompted this must actually reach its claims now.
  (let ((claims (apply #'reading::claims-about-subjects
                       (reading:claim-subjects-relevant-to-node :fischer-lisp-critic))))
    (check claims "Fischer's station still reaches no claims."))
  t)

(defun check-source-passage-navigation ()
  "A claim must reach the wording it rests on, and that wording must be
honest about whether it was read here."
  (let* ((claims (reading:historical-claims))
         (passages (reading:source-passages)))
    (check passages "No supporting passage is recorded at all.")
    (dolist (passage passages)
      ;; Every passage belongs to a claim, and leads back to it.
      (let ((claim (reading:claim-for-source-passage passage)))
        (check claim "Passage from ~S supports no known claim."
               (getf passage :source))
        (check (equal passage (reading:source-passage-for claim))
               "The claim for ~S does not reach this passage."
               (getf passage :source))
        (check (reading:claims-for-source-passage passage)
               "Passage from ~S leads back to no claim." (getf passage :source))
        (dolist (covered (reading:claims-for-source-passage passage))
          (check (equal passage (reading:source-passage-for covered))
                 "Claim ~S/~S is covered by the passage but does not reach it."
                 (getf covered :subject) (getf covered :claim-type)))
        ;; The passage must carry the wording and where to find it.
        (dolist (key '(:source :title :bibliographic :location :supports
                       :passage))
          (check (and (stringp (getf passage key))
                      (plusp (length (getf passage key))))
                 "Passage from ~S has no ~S." (getf passage :source) key))
        ;; A passage not read here may not be presented as verified, and a
        ;; claim whose locator was never read cannot hold a verified one.
        (unless (getf passage :passage-observed-p)
          (check (getf passage :passage-origin)
                 "Passage from ~S is unobserved but does not say where it ~
came from." (getf passage :source)))
        (when (getf passage :passage-observed-p)
          (check (getf claim :locator-observed-p)
                 "Passage from ~S claims to be read here while its claim's ~
locator was never read." (getf passage :source)))))
    ;; The first recorded passage exists to correct its claim, so the claim
    ;; must not have drifted back to the stronger wording.
    (let ((claim (find-if (lambda (c)
                            (and (eq :lisp-critic-version-1 (getf c :subject))
                                 (eq :contribution (getf c :claim-type))))
                          claims)))
      (check claim "The version-1 contribution claim disappeared.")
      (check (search "contributed to version 1" (getf claim :assertion))
             "The version-1 claim no longer follows the source wording: ~S"
             (getf claim :assertion))
      (check (not (search "credited to" (getf claim :assertion)))
             "The version-1 claim reverted to a stronger wording than the ~
passage supports: ~S" (getf claim :assertion))))
  t)

(defun check-historical-claims ()
  "Every displayed claim must be traceable, and none may overstate access."
  (let ((claims (reading:historical-claims)))
    (check claims "The reading shows no historical claims at all.")
    (dolist (claim claims)
      (let ((subject (getf claim :subject)))
        ;; Traceable: a witness and a locator, always.
        (check (getf claim :witness)
               "Claim about ~S carries no witness." subject)
        (check (and (stringp (getf claim :locator))
                    (plusp (length (getf claim :locator))))
               "Claim about ~S carries no locator." subject)
        (check (and (stringp (getf claim :assertion))
                    (plusp (length (getf claim :assertion))))
               "Claim about ~S carries no assertion." subject)
        ;; Either something observed here carries the claim, or the claim
        ;; openly says nothing here carries it yet. What is forbidden is
        ;; evidence that cannot settle this kind of claim at all.
        (check (or (claim-uncarried-p claim) (reading:claim-carried-p claim))
               "Claim about ~S is carried by ~S, which cannot settle a ~S claim."
               subject (getf claim :observed-evidence-kind)
               (getf claim :claim-type))
        ;; Citing a source is not reading it.
        (check (not (and (null (getf claim :locator-observed-p))
                         (eq :primary-paper
                             (getf claim :observed-evidence-kind))))
               "Claim about ~S names a primary paper as observed evidence ~
while its locator was never read here." subject)
        ;; The research-line artifacts are still not here, whatever we may
        ;; have read about them. A paper in the workspace settles what the
        ;; paper says; it does not put the 1987 system on this machine.
        (when (member subject +fischer-subjects+)
          (check (null (getf claim :source-observed-p))
                 "A Fischer-line claim about ~S claims observed source."
                 subject)
          (check (null (reading:resolve-executability claim))
                 "A Fischer-line claim about ~S claims local executability."
                 subject))
        ;; Reading a locator is allowed, but for a source outside the
        ;; workspace it must leave a trace: the passage that was read.
        ;; Otherwise "observed" is an assertion with a nicer name. A
        ;; workspace file needs no passage — the file is its own trace, and
        ;; CHECK-SOURCE-BACKING already proves those files are there.
        (when (and (getf claim :locator-observed-p)
                   (eq :primary-paper (getf claim :cited-source-kind)))
          (check (reading:source-passage-for claim)
                 "Claim about ~S cites a paper, says it was read here, and ~
records no passage from it." subject))))
    ;; An absence of attribution settles no lineage, in either direction.
    (dolist (claim claims)
      (when (eq :absence-of-reference (getf claim :observed-evidence-kind))
        (check (not (member (getf claim :claim-type) '(:descent :non-descent)))
               "An absence of reference is being used to settle a ~S claim ~
about ~S. Finding no attribution is a fact about the search, not about ~
lineage." (getf claim :claim-type) (getf claim :subject))))
    (dolist (kind '(:descent :non-descent))
      (check (not (reading:evidence-adequate-for-p :absence-of-reference kind))
             "The adequacy relation still lets an absence of reference ~
settle ~S." kind))
    ;; No descent claim may cross from the research line to the code line.
    (dolist (claim claims)
      (when (eq :descent (getf claim :claim-type))
        (check (not (member (getf claim :subject) +fischer-subjects+))
               "A descent claim is attached to research-line subject ~S."
               (getf claim :subject))))
    ;; The two access questions must stay independent: there is at least one
    ;; claim whose source is observed while execution is not guaranteed.
    (check (find-if (lambda (claim)
                      (and (getf claim :source-observed-p)
                           (eq :runtime-dependent
                               (getf claim :executable-here-p))))
                    claims)
           "No claim distinguishes observed source from local executability; ~
the two fields have collapsed into one.")
    ;; And the unevidenced assertions stay listed as unevidenced.
    (let ((absent (reading::fischer-claims-without-local-evidence)))
      (check absent "The unevidenced claims disappeared.")
      (check (find :code-lineage-to-riesbeck absent
                   :key (lambda (entry) (getf entry :claim)))
             "The descent claim is no longer listed as unevidenced.")
      (dolist (entry absent)
        (check (eq :none (getf entry :local-evidence))
               "Claim ~S is no longer marked unevidenced."
               (getf entry :claim)))))
  t)

;;
;; 5. 6. 7. The three outcomes, against the real engine
;;

(defun check-outcomes ()
  (let ((match (reading:critic-match-example))
        (non-match (reading:critic-non-match-example))
        (failure (reading:critic-failure-example)))
    ;; 5. A match still yields a Critique.
    (let ((record (getf match :record)))
      (check (eq :completed (er:evaluation-status-of record))
             "The match case failed: ~A" (er:evaluation-failure-of record))
      (check (= 1 (length (er:evaluation-result-of record)))
             "The match case produced ~D critiques instead of one."
             (length (er:evaluation-result-of record)))
      (check (typep (first (er:evaluation-result-of record)) 'critic:critique)
             "The match case produced something other than a Critique.")
      (check (eq :evaluation-record-and-critique
                 (getf (getf match :summary) :outcome))
             "The match case reports outcome ~S."
             (getf (getf match :summary) :outcome)))
    ;; 6. A non-match yields no Critique, but still a record.
    (let ((record (getf non-match :record)))
      (check (eq :completed (er:evaluation-status-of record))
             "The non-match case did not complete.")
      (check (null (er:evaluation-result-of record))
             "The non-match case produced a critique.")
      (check (eq :evaluation-record-only
                 (getf (getf non-match :summary) :outcome))
             "The non-match case reports outcome ~S."
             (getf (getf non-match :summary) :outcome)))
    ;; 7. A failure stays a record and keeps its condition.
    (let ((record (getf failure :record)))
      (check (eq :failed (er:evaluation-status-of record))
             "The failure case did not fail.")
      (check (er:evaluation-failure-of record)
             "The failure case discarded its condition.")
      (check (null (er:evaluation-result-of record))
             "The failure case produced a critique.")
      (check (eq :evaluation-record-with-condition
                 (getf (getf failure :summary) :outcome))
             "The failure case reports outcome ~S."
             (getf (getf failure :summary) :outcome))))
  t)

;;
;; The engine source the reading transcludes must really be the vendored one
;;

(defun check-source-backing ()
  (let* ((anatomy (reading:critique-anatomy-example))
         (pathname (getf (getf anatomy :source-provenance) :pathname)))
    ;; Missing external sources must fail this proof, never skip it.
    (check (probe-file pathname)
           "The rule's recorded source file is absent: ~A" pathname)
    (check (search "lisp-rules" (namestring pathname))
           "The rule does not come from the vendored rule file: ~A" pathname)
    ;; The recommendation must come from the engine, not from the page.
    (check (search "CADR" (getf anatomy :explanation))
           "The explanation no longer carries the engine's recommendation."))
  (let ((station (reading:riesbeck-source-station-example)))
    (check (getf station :present-p) "The local source station is absent.")
    (dolist (file (getf station :vendored-files))
      (check (getf file :present-p)
             "Vendored engine file ~A is absent." (getf file :name))))
  t)

;;
;; The gap the previous slice left open: the book was never exercised under
;; the launcher that actually serves it. Rendering alone is not enough —
;; absence of the error string would also be satisfied by a page that says
;; nothing — so the critic must really run.
;;

(defun check-under-catalog-runtime ()
  "Exercise this book the way the normal Catalog launcher reaches it, where there is no engine.

Called from the Catalog startup proof, in its fresh process, so the book cannot pass on a development image's leftover state. The
engine is a source station that this repository does not carry, so the regular Catalog must work without it, and this check is run
in a runtime that finds none (CALL-WITH-ABSENT-STATION), whatever machine it runs on. What is held to account here:

 * every page renders and every expression the pages address evaluates, and none presents a load failure as content;
 * the book says honestly that the engine is not reachable, and does not call it executable;
 * the recorded critiques, which are the engine's own output written where it could run, are readable without it;
 * the runtime refuses to load code that arrived with a page, while a present station would be loaded where it is allowed.

The real CAR-CDR run is not here. It needs an engine and belongs to the engine integration test, which fails when it has none."
  (call-with-absent-station
   (lambda ()
     (let ((book (hyperbook:find-hyperbook "dreyeck/lisp-critic/reading" :signal-error? t)))
       (hyperdoc::ensure-pages-loaded book)
       (check (= (length +pages+) (hash-table-count (hyperdoc:pages-of book)))
              "The Catalog sees ~D reading pages instead of ~D."
              (hash-table-count (hyperdoc:pages-of book)) (length +pages+))
       ;; Every page must render, and none may present a load failure as content.
       (dolist (title +pages+)
         (let* ((page (hyperbook:find-page book title :signal-error? t))
                (view (find "Content" (views:all-views page) :key #'views:view-title :test #'string=))
                (html (progn (check view "Page ~S has no Content view." title) (views:view-html view))))
           (check (plusp (length html)) "Page ~S rendered nothing." title)
           (check (not (search "is not loaded" html)) "Page ~S renders an engine load failure as content." title)
           ;; Structural, not a fixed count: whatever the page addresses, the Catalog must be able to evaluate all of it.
           (let ((*package* (page-package page)))
             (dolist (expression (page-expressions page))
               (check-example-result (hyperdoc::parse-and-eval expression) expression title "Catalog runtime")))))
       ;; The engine is honestly absent.
       (check-the-absent-engine-is-reported-as-absent)
       ;; The recorded critiques are readable without it, and reading them loads nothing.
       (check-recorded-critiques-are-readable)))
   )
  (check-historical-claim-views)
  (check-policy-boundary-with-a-present-station)
  (format t "~&CATALOG-LISP-CRITIC-READING-PASS: pages render, examples evaluate, the absent engine is reported as absent, recorded critiques read without it, a present station is refused where code may not arrive with a page. The real CAR-CDR run is the engine integration test (it fails when it has no station).~%")
  t)

(defun check-the-absent-engine-is-reported-as-absent ()
  "No engine: the book says so everywhere it speaks about it, and what it cannot run is not presented as run."
  (check (not (reading:engine-available-p)) "An absent station is reported as available.")
  (check (eq :not-available-in-this-runtime (reading::runtime-evidence-status))
         "An absent station has the status ~S." (reading::runtime-evidence-status))
  (let* ((match (reading:critic-match-example))
         (record (getf match :record)))
    (check (null (getf match :engine-available-p)) "The CAR-CDR example claims an engine that is not there.")
    (check (eq :not-available-in-this-runtime (getf match :evidence-status))
           "The CAR-CDR example has the status ~S without an engine." (getf match :evidence-status))
    (check (not (eq :completed (er:evaluation-status-of record)))
           "A run without an engine is recorded as completed.")
    (check (null (er:evaluation-result-of record)) "A run without an engine carries critiques."))
  ;; A station that was announced and not delivered is not an engine either: the directory exists, the engine does not.
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames (format nil "dreyeck-empty-station-~36R/" (random (expt 36 8) (make-random-state t)))
                                                                     (uiop:temporary-directory)))))
    (ensure-directories-exist directory)
    (unwind-protect
         (progn
           (call-with-environment
            (list (cons "DREYECK_LISP_CRITIC_ROOT" (uiop:native-namestring directory)))
            (lambda ()
              (check (equal (truename directory) (truename (reading::resolve-engine-asset-root)))
                     "The explicit station directory was not the one resolved.")
              (check (not (reading:engine-available-p)) "An empty station directory is reported as an available engine.")
              (check (eq :not-available-in-this-runtime (reading::runtime-evidence-status))
                     "An empty station directory has the status ~S." (reading::runtime-evidence-status))
              (check (reading::engine-station-files-missing) "An empty station does not name what it lacks.")))
           ;; The wrapper definition alone, with no engine behind it, is not an engine either.
           (with-open-file (out (merge-pathnames "a-critic-for-lisp.asd" directory) :direction :output :if-exists :supersede)
             (write-string "(asdf:defsystem \"a-critic-for-lisp\")" out))
           (call-with-environment
            (list (cons "DREYECK_LISP_CRITIC_ROOT" (uiop:native-namestring directory)))
            (lambda ()
              (check (not (reading:engine-available-p)) "A wrapper definition without the vendored engine is reported as available.")
              (check (equal (reading::engine-station-files-missing) reading::+engine-runtime-files+)
                     "The vendored files that are missing are not all named: ~S." (reading::engine-station-files-missing)))))
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore)))
  t)

(defun check-recorded-critiques-are-readable ()
  "The engine's recorded output is read here, without the engine, and a record that cannot be read is reported, not worked around.

Three committed recordings: the CAR-CDR run (the reading's own recorded evaluation) and the two example evaluations of
dreyeck/lisp-critic/recorded. Each check is also shown to fail on a damaged copy, so that passing means the record was read."
  (let ((systems (length (asdf:registered-systems)))
        (packages '(:lisp-critic :lisp-critic-user :extend-match :a-critic-for-lisp)))
    ;; 1. CAR-CDR: one critique, the engine's own recommendation, shown in the Inspector.
    (flet ((read-car-cdr (contents)
             (with-evaluation-snapshot
                 contents
               (lambda ()
                 (let* ((target (reading:current-critique-example))
                        (record (and (typep target 'critic:critic-target) (first (critic:target-runs-of target)))))
                   (check record "The recorded CAR-CDR run is unreadable: ~S." (and (listp target) (getf target :why)))
                   (check (equal "COMPLETED" (er:evaluation-status-of record)) "The recorded run is ~A." (er:evaluation-status-of record))
                   (check (= 1 (length (critic:critiques-of record)))
                          "The recorded run has ~D critiques instead of one." (length (critic:critiques-of record)))
                   (check (search "CADR" (critic:critique-explanation-of (first (critic:critiques-of record))))
                          "The recorded critique lost the engine's recommendation CADR.")
                   (let ((html (views:view-html (first (views:all-views target)))))
                     (check (search "CAR (CDR ITEMS)" html) "The Inspector does not show the evaluated input."))
                   ;; The recommendation is on the critique's own Inspector view, not on the target's.
                   (let ((html (views:view-html (first (views:all-views (first (critic:critiques-of record)))))))
                     (check (search "CADR" html) "The Inspector does not show the recommendation."))
                   t)))))
      (check (read-car-cdr (car-cdr-fixture-text)) "The CAR-CDR record was not read.")
      ;; Damaged copies are detected: unreadable, a critique lost, the recommendation lost.
      (expect-failure "an unreadable record" (lambda () (read-car-cdr "{ this is not valid json")) "unreadable")
      (expect-failure "a record that lost its critique"
                      (lambda () (read-car-cdr (let* ((text (car-cdr-fixture-text)) (at (search "\"critiques\"" text)))
                                                 (check at "The fixture has no critiques member.")
                                                 (concatenate 'string (subseq text 0 at) "\"critiques\": []}"))))
                      "critique")
      (expect-failure "a record that lost the recommendation"
                      (lambda () (read-car-cdr (let ((text (car-cdr-fixture-text)))
                                                 (loop for at = (search "CADR" text) while at
                                                       do (setf text (concatenate 'string (subseq text 0 at) "XXXX" (subseq text (+ at 4)))))
                                                 text)))
                      "CADR"))
    ;; 2. The two recorded example evaluations, in an image that never loads the engine.
    (check (every (lambda (name) (null (find-package name))) packages)
           "The engine is already loaded; the recorded evaluations cannot be shown to be read without it.")
    (uiop:symbol-call :dreyeck/lisp-critic/recorded/tests :check-reading-recorded-evaluations)
    (check (every (lambda (name) (null (find-package name))) packages) "Reading the recordings loaded the engine.")
    (check (= systems (length (asdf:registered-systems))) "Reading the recordings registered an ASDF system."))
  t)

(defun canary-station-script ()
  "Run in a clean child image: a station directory that holds a canary definition and the recorded evaluation, and no engine.
The canary is evaluated only by something that loads the page-attached system, so it measures loading itself. Refused: it must not
be evaluated and nothing may be added. Permitted: it must be, or the refusal above would have been measured blind."
  "(let* ((root (uiop:ensure-directory-pathname (uiop:getenv \"CANARY_STATION\")))
         (packages '(:lisp-critic :lisp-critic-user :extend-match :a-critic-for-lisp))
         (parameters (find-symbol \"*SERVER-PARAMETERS*\" :hyperbook/server))
         (examples (list #'dreyeck/lisp-critic/reading:critique-anatomy-example
                         #'dreyeck/lisp-critic/reading:riesbeck-car-cdr-rule-example
                         #'dreyeck/lisp-critic/reading:evidence-ladder-example)))
    (declare (special cl-user::*canary*))
    (assert (null (remove-if-not #'find-package packages)))
    (assert (not (boundp 'cl-user::*canary*)))
    ;; Refusing: the reading examples and the direct run all meet the boundary; none evaluates the page's definition.
    (setf (symbol-value parameters) (list \"700px\" nil))
    (assert (not (dreyeck/lisp-critic/reading:execution-permitted-p)))
    (let ((systems (length (asdf:registered-systems))))
      (dolist (example examples) (ignore-errors (funcall example)))
      (ignore-errors (dreyeck/lisp-critic:car-cdr-critique-example (namestring root)))
      (assert (not (boundp 'cl-user::*canary*)) () \"A refusing runtime evaluated the page's definition.\")
      (assert (null (remove-if-not #'find-package packages)))
      (assert (null (asdf:registered-system \"a-critic-for-lisp\")) () \"A refusing runtime registered the page-attached system.\")
      (assert (= systems (length (asdf:registered-systems)))))
    ;; Permitted: the same call evaluates it.
    (setf (symbol-value parameters) nil)
    (assert (dreyeck/lisp-critic/reading:execution-permitted-p))
    (ignore-errors (dreyeck/lisp-critic:car-cdr-critique-example (namestring root)))
    (assert (and (boundp 'cl-user::*canary*) (symbol-value 'cl-user::*canary*)) ()
            \"A permitting runtime did not evaluate the page's definition: the refusal measured above was blind.\")
    (format t \"~&CANARY-BOUNDARY-PASS: refused evaluates nothing and adds nothing; permitted evaluates the page's definition.~%\"))")

(defun check-policy-boundary-with-a-present-station ()
  "A station is present and a runtime that refuses page-attached code must not evaluate it; one that permits it does.

Differential, in a clean image, with no engine involved: the station is a directory holding a canary definition. This is the refusal
the Catalog needs and the regular tests can measure; the same boundary with the real engine behind it is CHECK-POLICY-IN-A-CLEAN-IMAGE
in the integration tier. A guard removed from the one place that loads the page-attached system fails here."
  (let ((station (uiop:ensure-directory-pathname
                  (merge-pathnames (format nil "dreyeck-canary-station-~36R/" (random (expt 36 8) (make-random-state t)))
                                   (uiop:temporary-directory)))))
    (ensure-directories-exist (merge-pathnames "evaluations/" station))
    (unwind-protect
         (progn
           (with-open-file (out (merge-pathnames "a-critic-for-lisp.asd" station) :direction :output :if-exists :supersede)
             (write-string "(setf cl-user::*canary* t)
(asdf:defsystem \"a-critic-for-lisp\")" out))
           (with-open-file (out (merge-pathnames "evaluations/car-cdr.json" station) :direction :output :if-exists :supersede :external-format :utf-8)
             (write-string (car-cdr-fixture-text) out))
           (let ((output
                   (with-output-to-string (stream)
                     (uiop:run-program
                      (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
                            "--eval" "(require :asdf)"
                            "--eval" (format nil "(asdf:load-asd ~S)" (asdf:system-source-file "dreyeck"))
                            "--eval" "(asdf:load-system \"dreyeck/lisp-critic/reading\")"
                            "--eval" "(asdf:load-system \"hyperbook/server\")"
                            "--eval" (canary-station-script))
                      :environment (cons (format nil "CANARY_STATION=~A" (uiop:native-namestring station))
                                         (cons (format nil "DREYECK_LISP_CRITIC_ROOT=~A" (uiop:native-namestring station))
                                               (remove-if (lambda (entry) (or (uiop:string-prefix-p "CANARY_STATION=" entry)
                                                                              (uiop:string-prefix-p "DREYECK_LISP_CRITIC_ROOT=" entry)))
                                                          (sb-ext:posix-environ))))
                      :output stream :error-output stream))))
             (check (search "CANARY-BOUNDARY-PASS" output) "The canary boundary check did not pass:~%~A" output)))
      (uiop:delete-directory-tree station :validate t :if-does-not-exist :ignore)))
  (format t "~&POLICY-BOUNDARY-WITH-A-PRESENT-STATION-PASS: refused evaluates nothing, permitted does.~%")
  t)

;;
;; The served runtime, where the source station is deliberately absent
;;

(defun report-degraded-runtime ()
  "Render every page and report what this runtime can honestly claim.

Run in the child process of CHECK-DEGRADED-RUNTIME, where the source
station has been pointed at nothing."
  (check-historical-claim-views)
  (let ((book (hyperbook:find-hyperbook "dreyeck/lisp-critic/reading"
                                        :signal-error? t)))
    (hyperdoc::ensure-pages-loaded book)
    (dolist (title +pages+)
      (let* ((page (hyperbook:find-page book title :signal-error? t))
             (view (find "Content" (views:all-views page)
                         :key #'views:view-title :test #'string=))
             (html (views:view-html view)))
        (when (search "is not loaded" html)
          (format t "~&DEGRADED-LEAK: ~A~%" title))))
    (format t "~&DEGRADED-ENGINE-AVAILABLE: ~S~%" (reading:engine-available-p))
    (format t "~&DEGRADED-STATUS: ~S~%"
            (getf (reading:critic-match-example) :evidence-status))
    (finish-output))
  t)

(defun check-degraded-runtime ()
  "Prove the pages stay honest when the engine cannot be reached.

Runs a fresh process with the source station pointed at nothing, which is
the condition a served HyperDoc is in."
  (let ((output
          (with-output-to-string (stream)
            (uiop:run-program
             (list (namestring sb-ext:*runtime-pathname*)
                   "--no-userinit" "--non-interactive"
                   "--eval" "(require :asdf)"
                   "--eval" (format nil "(asdf:load-asd ~S)"
                                    (asdf:system-source-file "dreyeck"))
                   "--eval" "(asdf:load-system \"dreyeck/lisp-critic/reading/tests\")"
                   "--eval" "(dreyeck/lisp-critic/reading/tests::report-degraded-runtime)")
             :environment
             (cons "DREYECK_LISP_CRITIC_ROOT=/nonexistent/dreyeck-no-station/"
                   (remove-if (lambda (entry)
                                (uiop:string-prefix-p
                                 "DREYECK_LISP_CRITIC_ROOT=" entry))
                              (sb-ext:posix-environ)))
             :output stream :error-output stream))))
    (check (not (search "DEGRADED-LEAK" output))
           "A page rendered an engine load failure as content:~%~A" output)
    (check (search "DEGRADED-ENGINE-AVAILABLE: NIL" output)
           "The degraded runtime still reported the engine as available:~%~A"
           output)
    (check (search "DEGRADED-STATUS: :NOT-AVAILABLE-IN-THIS-RUNTIME" output)
           "The degraded runtime did not report an honest status:~%~A" output))
  (format t "~&DEGRADED-RUNTIME-PASS: no failure rendered as content, status ~
is honest.~%")
  t)

(defun check-historical-claim-views ()
  (let* ((data (reading:historical-claims-example))
         (inspection (make-instance 'reading::historical-claims-inspection :data data))
         (before (copy-tree data))
         (all (views:all-views data))
         (overview (first all)))
    (check (equal "Historical claims" (views:view-title overview))
           "Overview is not the primary view.")
    (check (= 14 (length (reading::inspection-claims inspection)))
           "Expected all 14 claims.")
    (views:view-html overview)
    (labels ((raw-check (object original)
               (let* ((all (views:all-views object))
                      (raw (find "Raw Lisp" all :key #'views:view-title :test #'equal)))
                 (check raw "Raw view absent.")
                 (check (find original (views:view-references raw) :key #'cdr :test #'eq)
                        "Raw view lost the original plist.")
                 (check (find-if (lambda (view) (search "Slots" (views:view-title view))) all)
                        "Standard Slots view absent.")
                 (check (views:all-views original) "Cons views absent."))))
      (raw-check inspection data)
      (loop for claim in (getf data :claims)
            for item = (find-if
                        (lambda (candidate)
                          (and (typep candidate 'reading::historical-claim-inspection)
                               (eq claim (reading::inspection-claim candidate))))
                        (mapcar #'cdr (views:view-references overview)))
            do (check (eq claim (reading::inspection-claim item)) "Claim was copied.")
               (check (find item (views:view-references overview) :key #'cdr :test #'eq)
                      "Claim is unreachable from overview.")
               (raw-check item claim)
               (let* ((view (first (views:all-views item)))
                      (html (views:view-html view)))
                 (check (equal "Historical claim" (views:view-title view)) "No primary detail view.")
                 (dolist (heading '("Claim" "Cited Source" "Observed Evidence" "Artifact Status"))
                   (check (search heading html) "Section ~A absent." heading))
                 ;; The 1987 artifact is not in this workspace and cannot
                 ;; run here, whatever we may have read about it. Whether a
                 ;; cited paper has been read is a separate question and
                 ;; may legitimately change, so it is not asserted here.
                 (when (eq :fischer-1987 (getf claim :subject))
                   (dolist (row '("source observed</th><td>no"
                                  "executable</th><td>no"))
                     (check (search row html) "Incorrect Fischer status: ~A" row)))
                 (when (eq :riesbeck-engine (getf claim :subject))
                   (check (search "source observed</th><td>yes" html) "Source not observed.")
                   (check (search "runtime-dependent" html) "Lost runtime dependency.")
                   (check (search (format nil "executable</th><td>~A"
                                          (if (reading:resolve-executability claim) "yes" "no")) html)
                          "Incorrect resolved executability."))
                 (when (eq :none-observed (getf claim :observed-evidence-kind))
                   (check (search "cited, not observed in this workspace" html)
                          "Unobserved citation misrepresented."))
                 (when (eq :fischer-to-riesbeck (getf claim :subject))
                   (check (search "no attribution/reference observed" html) "Attribution status absent.")
                   (check (search "no source-provenance link observed" html) "Provenance status absent.")))))
    (check (equal before data) "Rendering mutated the data."))
  t)

(defun check-source-structure-projection ()
  "Where the source lives must be observed, and observed layer by layer.

Three layers with three different permissions. The repository systems
are ours and loaded, so ASDF may be asked. The page-attached system and
the vendored engine are neither, and asking ASDF about them would run a
definition that arrived with a page — which is the distinction the
projection exists to show, so a projection that discovered them by
loading them would have destroyed it.

The test therefore measures the abstention as well as the result: no
system is registered by building the projection, and the engine's
packages are exactly as present afterwards as they were before.

Unchanged, not absent. Earlier checks in this suite run the engine on
purpose, so by the time this one runs the packages are there — and a
test demanding their absence would be asserting the order of its own
suite rather than anything about the projection. What the projection
owes is that it brings nothing in."
  (let ((before-systems (length (asdf:registered-systems)))
        (engine-packages '(:lisp-critic :lisp-critic-user
                           :extend-match :a-critic-for-lisp))
        (present-before nil))
    (setf present-before
          (remove-if-not (lambda (name) (find-package name)) engine-packages))
    (let* ((layers (reading:lisp-critic-source-layers))
           (by-layer (lambda (key)
                       (find key layers :key (lambda (l) (getf l :layer))))))
      (check (= 3 (length layers))
             "Expected three source layers, found ~D." (length layers))
      ;; Each layer must say how it was observed, because that is the
      ;; difference between them.
      (let ((repository (funcall by-layer :repository-owned))
            (attached (funcall by-layer :page-attached))
            (vendored (funcall by-layer :vendored-historical)))
        (check repository "No repository-owned layer.")
        (check attached "No page-attached layer.")
        (check vendored "No vendored-historical layer.")
        (check (eq :asdf-registry (getf repository :observed-by))
               "The repository layer is no longer read from the registry.")
        (dolist (layer (list attached vendored))
          (check (eq :file-system-and-text (getf layer :observed-by))
                 "Layer ~S is read by ~S; a definition that arrived with a ~
page must be read as text." (getf layer :layer) (getf layer :observed-by)))
        ;; The repository layer must report what ASDF reports, not a copy.
        (dolist (system (getf repository :systems))
          (check (getf system :present-p)
                 "Repository system ~S is not registered." (getf system :name))
          (let ((component (asdf:find-system (getf system :name) nil)))
            (check component "~S vanished from the registry." (getf system :name))
            (check (getf system :files)
                   "~S is reported without source files." (getf system :name))))
        ;; The other two must name the files that are actually there.
        (let ((attached-files (getf (first (getf attached :systems)) :files)))
          (dolist (expected '("a-critic-for-lisp.asd" "package.lisp"
                              "src/loader.lisp" "src/hyperdoc-page.lisp"))
            (check (member expected attached-files :test #'string=)
                   "The page-attached layer does not report ~S; it reports ~S."
                   expected attached-files)))
        (let ((vendored-files (getf (first (getf vendored :systems)) :files)))
          (dolist (expected '("lisp-critic.asd" "lisp-critic.lisp"
                              "lisp-rules.lisp" "extend-match.lisp"
                              "tables.lisp" "write-wrap.lisp"))
            (check (member expected vendored-files :test #'string=)
                   "The vendored layer does not report ~S; it reports ~S."
                   expected vendored-files)))))
    ;; The projection itself, and what it costs to build.
    (let* ((structure (reading:make-lisp-critic-source-structure))
           (projection (tm:topicmap-projection-of structure))
           (topics (tm:topicmap-projection-topics-of projection))
           (associations (tm:topicmap-projection-associations-of projection))
           (input (dreyeck/topicmap/tala:projection-tala-input projection))
           (source (dreyeck/topicmap/tala:tala-input-source input)))
      (check (= 9 (length topics))
             "Expected three layers and six systems, found ~D topics."
             (length topics))
      ;; Files are deliberately not topics; they travel on the system.
      (dolist (topic topics)
        (check (member (tm:topicmap-topic-type-of topic)
                       '(:source-layer :asdf-system))
               "The projection introduced a topic of type ~S."
               (tm:topicmap-topic-type-of topic)))
      ;; The two edges that cross layers come from the source binding.
      (let ((crossings (remove-if-not
                        (lambda (a) (member (tm:topicmap-association-type-of a)
                                            '(:registers :loads)))
                        associations)))
        (check (= 2 (length crossings))
               "Expected one REGISTERS and one LOADS edge, found ~D."
               (length crossings)))
      ;; Readable D2, not encoded identifiers.
      (check (search "asdf_system_a_critic_for_lisp" source)
             "The generated D2 carries no readable key for the wrapper system.")
      (check (search "\"LOADS\"" source)
             "The generated D2 does not show the wrapper loading the engine.")
      ;; And the identity mapping remains walkable, which is what the
      ;; Inspector repair restored.
      (dolist (entry (dreyeck/topicmap/tala:tala-input-topics input))
        (check (string= (getf entry :id)
                        (dreyeck/topicmap/tala:tala-input-topic-id
                         input (getf entry :d2-id)))
               "A D2 key in the source projection does not lead back to its Topic."))
      (check (html-inspector-views:all-views
              (dreyeck/topicmap/tala:tala-input-topics input))
             "The source projection's Topic ID map offers no Inspector view."))
    ;; Code Pages keeps its narrow meaning: this book still carries none.
    (let ((observation (reading:lisp-critic-code-pages-observation-example)))
      (check (zerop (getf observation :code-page-count))
             "This book now reports ~D code pages; Code Pages has been ~
silently redefined." (getf observation :code-page-count)))
    (check (= before-systems (length (asdf:registered-systems)))
           "Reading where the source lives registered ~D system(s)."
           (- (length (asdf:registered-systems)) before-systems))
    (let ((present-after (remove-if-not (lambda (name) (find-package name))
                                        engine-packages)))
      (check (null (set-difference present-after present-before))
             "Reading where the source lives brought in ~S."
             (set-difference present-after present-before))))
  t)

;;
;; The Trusted Executable Examples review: three local Wiki pages and one reading
;;
;; Structure and navigation only. Nothing here judges the criticism the pages
;; carry, and nothing loads the slice they criticise.

(defparameter +review-site+ "dreyeck/pages/lisp-critic/trusted-examples-review-site/"
  "The local site of the review's Wiki pages, relative to the dreyeck system.")

(defparameter +review-wiki-id+ "fedwiki:trusted-examples-review.invalid"
  "A Wiki id whose domain resolves nowhere: the pages are not a served site.")

(defparameter +reviewed-revision+ "9b57bd4bb87d92fbf3061b91a42a6f539e18cdb1"
  "The revision of the reviewed code. Not the revision of the review's own files.")

(defparameter +review-pages+
  '(("should-the-code-method-preserve-the-inspector-rendering"
     "Should the Code Method Preserve the Inspector Rendering?"
     ("question" "claim" "~")
     (("claim" "preserve-the-prior-code-rendering")
      ("claim" "passive-code-rendering-may-be-intended")))
    ("preserve-the-prior-code-rendering"
     "Preserve the Prior Code Rendering"
     ("question" "claim" "support" "oppose" "~")
     (("question" "should-the-code-method-preserve-the-inspector-rendering")))
    ("passive-code-rendering-may-be-intended"
     "Passive Code Rendering May Be Intended"
     ("question" "claim" "support" "oppose" "~")
     (("question" "should-the-code-method-preserve-the-inspector-rendering"))))
  "Each page: its slug, its title, its folds in order, and its Wiki links as
(fold target-slug), in story order.")

(defun review-site-root ()
  (asdf:system-relative-pathname "dreyeck" +review-site+))

(defun %review-title (slug)
  (second (find slug +review-pages+ :key #'first :test #'string=)))

(defun %json-equal (a b)
  "Whether two values read by SHASHT are the same JSON."
  (cond ((and (hash-table-p a) (hash-table-p b))
         (and (= (hash-table-count a) (hash-table-count b))
              (loop for key being the hash-keys of a using (hash-value value)
                    always (multiple-value-bind (other present) (gethash key b)
                             (and present (%json-equal value other))))))
        ((and (vectorp a) (vectorp b) (not (stringp a)) (not (stringp b)))
         (and (= (length a) (length b)) (every #'%json-equal a b)))
        (t (equal a b))))

(defun %story-json (json)
  (coerce (or (gethash "story" json) #()) 'list))

(defun %folds (json)
  (loop for item in (%story-json json)
        when (equal "pagefold" (gethash "type" item))
          collect (gethash "text" item)))

(defun %wiki-link-titles (text)
  (let ((titles '()))
    (cl-ppcre:do-register-groups (title) ("\\[\\[([^\\]]+)\\]\\]" text)
      (push title titles))
    (nreverse titles)))

(defun %links-by-fold (json)
  "Each Wiki link of the story as (fold target-slug): the fold is the last
pagefold before the link, as the Claim Template and EXTRACT read it."
  (let ((fold nil) (links '()))
    (dolist (item (%story-json json) (nreverse links))
      (if (equal "pagefold" (gethash "type" item))
          (setf fold (gethash "text" item))
          (dolist (title (%wiki-link-titles (or (gethash "text" item) "")))
            (push (list fold (hyperbook/fedwiki::slug title)) links))))))

(defun check-review-site-pages ()
  "Each page, read once from its file: its title names its slug; it holds only
paragraphs and pagefolds, in the expected folds; every paragraph is marked as
the review's own; one create entry holds exactly this title and story; and
every link to the repository is pinned to the reviewed revision."
  (dolist (entry +review-pages+)
    (destructuring-bind (slug title folds links) entry
      (let* ((source (lp:observe-local-fedwiki-page-source (review-site-root) slug))
             (json (lp:page-source-json source))
             (story (%story-json json))
             (journal (coerce (or (gethash "journal" json) #()) 'list)))
        (check (= 64 (length (lp:page-source-sha256 source)))
               "~A has no SHA-256 of its bytes." slug)
        (check (equal title (gethash "title" json))
               "~A is titled ~S, not ~S." slug (gethash "title" json) title)
        (check (equal slug (hyperbook/fedwiki::slug title))
               "The title ~S does not name the slug ~A." title slug)
        (check (every (lambda (item)
                        (member (gethash "type" item) '("paragraph" "pagefold") :test #'equal))
                      story)
               "~A holds an item that is neither a paragraph nor a pagefold." slug)
        (check (equal folds (%folds json))
               "~A has the folds ~S, not ~S." slug (%folds json) folds)
        (check (equal links (%links-by-fold json))
               "~A links ~S, not ~S." slug (%links-by-fold json) links)
        (check (= (length story)
                  (length (remove-duplicates (mapcar (lambda (item) (gethash "id" item)) story)
                                             :test #'equal)))
               "~A repeats an item id." slug)
        (check (and story (equal "paragraph" (gethash "type" (first story)))
                    (eql 0 (search "Claude review artefact." (gethash "text" (first story)))))
               "~A does not open with the review's provenance." slug)
        (dolist (item story)
          (when (equal "paragraph" (gethash "type" item))
            (check (eql 0 (search "Claude review" (gethash "text" item)))
                   "A paragraph of ~A is not marked as the review's: ~S"
                   slug (gethash "text" item))))
        (check (= 1 (length journal))
               "~A has ~D journal entries, not one create entry." slug (length journal))
        (let* ((create (first journal))
               (item (gethash "item" create)))
          (check (equal "create" (gethash "type" create))
                 "The journal of ~A starts with ~S." slug (gethash "type" create))
          (check (null (nth-value 1 (gethash "site" create)))
                 "The journal of ~A names a site: it would be read as a fork." slug)
          (check (integerp (gethash "date" create))
                 "The create entry of ~A has no date." slug)
          (check (and (hash-table-p item) (equal title (gethash "title" item)))
                 "The create entry of ~A does not hold its title." slug)
          (check (%json-equal (gethash "story" json) (gethash "story" item))
                 "The create entry of ~A does not hold exactly its story." slug))
        (dolist (item story)
          (cl-ppcre:do-matches-as-strings (url "https://github\\.com/RalfBarkow/hyperdoc/[^ \\]]*"
                                           (or (gethash "text" item) ""))
            (check (search (format nil "/blob/~A/" +reviewed-revision+) url)
                   "~A cites ~A, which is not pinned to the reviewed revision." slug url))))))
  t)

(defun %call-without-plugin-fallback (thunk)
  "Call THUNK with the Wiki's remote plugin-page fallback replaced by a trap.
A link that the local page store does not resolve then fails the check
instead of being fetched over the network."
  (let* ((name 'hyperbook/fedwiki::get-plugin-page)
         (original (symbol-function name))
         (reached '()))
    (unwind-protect
         (progn
           (setf (symbol-function name)
                 (lambda (wiki slug)
                   (declare (ignore wiki))
                   (push slug reached)
                   (error "The plugin-page fallback was reached for ~S." slug)))
           (multiple-value-prog1 (funcall thunk)
             (check (null reached)
                    "The plugin-page fallback was reached for ~S." reached)))
      (setf (symbol-function name) original))))

(defun %fresh-review-page (slug)
  "SLUG opened in a local Wiki of its own that holds nothing else."
  (let ((wiki (lp:make-local-fedwiki (review-site-root) +review-wiki-id+)))
    (values (lp:make-local-fedwiki-page (review-site-root) wiki slug) wiki)))

(defun %check-unloaded-targets (wiki slug targets)
  (dolist (target-slug targets)
    (check (null (gethash target-slug (hyperbook/fedwiki::pages-of wiki)))
           "~A is held by the Wiki before ~A links to it." target-slug slug)))

(defun check-review-site-links ()
  "Every Wiki link of the three pages resolves, through the FedWiki lookup the
Story view uses, to the local page file of the same site, and the Story view
renders each link as a reference rather than a lookup failure.

Each check opens its page in a Wiki of its own that holds nothing else, so a
target can only be reached by reading its file from the local page store. The
remote plugin-page fallback is trapped throughout."
  (let ((root (review-site-root)))
    (%call-without-plugin-fallback
     (lambda ()
       (dolist (entry +review-pages+)
         (destructuring-bind (slug title folds links) entry
           (declare (ignore title folds))
           (let ((targets (mapcar #'second links)))
             ;; The rendering path: the Story view resolves each link itself.
             (multiple-value-bind (page wiki) (%fresh-review-page slug)
               (check (null (hyperbook/fedwiki::context-of page))
                      "~A has a remote context to fall back on." slug)
               (%check-unloaded-targets wiki slug targets)
               (let ((html (views:view-html (hyperbook/fedwiki::👀story page))))
                 (check (not (search "hyperbook-error" html))
                        "The Story of ~A renders a link that did not resolve." slug)
                 (dolist (target-slug targets)
                   (check (search (%review-title target-slug) html)
                          "The Story of ~A does not show the link to ~A." slug target-slug)
                   (check (gethash target-slug (hyperbook/fedwiki::pages-of wiki))
                          "Rendering ~A did not read ~A from the page store." slug target-slug))
                 (check (search (format nil "https://github.com/RalfBarkow/hyperdoc/blob/~A/"
                                        +reviewed-revision+)
                                html)
                        "The Story of ~A shows no evidence link at the reviewed revision." slug)
                 (check (not (search "<script" html :test #'char-equal))
                        "The Story of ~A carries a script." slug)))
             ;; The lookup itself, link by link, again from an empty Wiki.
             (multiple-value-bind (page wiki) (%fresh-review-page slug)
               (%check-unloaded-targets wiki slug targets)
               (check (null (set-exclusive-or
                             targets
                             (mapcar #'hyperbook/fedwiki::target-slug-of
                                     (hyperbook/fedwiki::wiki-links-of (hyperbook:links-of page)))
                             :test #'equal))
                      "The links FedWiki extracts from ~A differ from ~S." slug targets)
               (dolist (target-slug targets)
                 (let ((target (hyperbook/fedwiki::find-target-by-slug target-slug page)))
                   (check (typep target 'lp:local-fedwiki-page)
                          "~A -> ~A resolves to ~S, not a local page." slug target-slug target)
                   (check (eq wiki (hyperbook:hyperbook-of target))
                          "~A -> ~A leaves the review's local Wiki." slug target-slug)
                   (check (equal (lp:local-fedwiki-page-site-root-of page)
                                 (lp:local-fedwiki-page-site-root-of target))
                          "~A -> ~A resolves in another site root." slug target-slug)
                   (check (equal target-slug (hyperbook:id-of target))
                          "~A -> ~A reaches the page ~A." slug target-slug (hyperbook:id-of target))
                   (check (equal (%review-title target-slug) (hyperbook:title-of target))
                          "~A -> ~A reaches a page titled ~S." slug target-slug
                          (hyperbook:title-of target))
                   (check (%json-equal (hyperbook/fedwiki::raw-json-of target)
                                       (lp:page-source-json
                                        (lp:observe-local-fedwiki-page-source root target-slug)))
                          "~A -> ~A does not hold the JSON of its file." slug target-slug))))))))))
  t)

(defun %depends-on-p (system other)
  "Whether the registered SYSTEM depends, directly or not, on OTHER."
  (let ((seen (make-hash-table :test #'equal)))
    (labels ((walk (name)
               (unless (gethash name seen)
                 (setf (gethash name seen) t)
                 (let ((registered (asdf:registered-system name)))
                   (when registered
                     (dolist (dependency (asdf:system-depends-on registered))
                       (typecase dependency
                         (string (walk (string-downcase dependency)))
                         (symbol (walk (string-downcase (symbol-name dependency)))))))))))
      (walk (string-downcase system))
      (and (gethash (string-downcase other) seen) t))))

(defun check-review-reading-page ()
  "The reading opens exactly the three local pages, does not load the slice it
criticises, and says what it is not."
  (let* ((page (page-of "Reading the Trusted Executable Examples Review"))
         (*package* (page-package page))
         (before (find-package "DREYECK/VERIFIED-EXAMPLE"))
         (opened (mapcar #'hyperdoc::parse-and-eval (page-expressions page)))
         (root (truename (uiop:ensure-directory-pathname (review-site-root))))
         (text (uiop:read-file-string (hyperdoc:file-of page))))
    (check (= (length +review-pages+) (length opened))
           "The reading addresses ~D objects, not the ~D review pages."
           (length opened) (length +review-pages+))
    (dolist (object opened)
      (check (typep object 'lp:local-fedwiki-page)
             "The reading addresses ~S, not a local Wiki page." object)
      (check (equal root (lp:local-fedwiki-page-site-root-of object))
             "The reading opens ~A outside the review's site." (hyperbook:id-of object)))
    (check (null (set-exclusive-or (mapcar #'hyperbook:id-of opened)
                                   (mapcar #'first +review-pages+)
                                   :test #'equal))
           "The reading opens ~S." (mapcar #'hyperbook:id-of opened))
    (check (eq before (find-package "DREYECK/VERIFIED-EXAMPLE"))
           "Reading the review changed whether DREYECK/VERIFIED-EXAMPLE exists.")
    (check (not (%depends-on-p "dreyeck/lisp-critic/reading" "dreyeck/verified-example"))
           "The reading's book depends on the slice it criticises.")
    (dolist (phrase '("No critic rule ran"
                      "an Evaluation Record, or a passed"
                      "The probe P1 has since been executed"
                      "This page records no answer, and none is simulated."))
      (check (search phrase (substitute #\Space #\Newline text))
             "The reading no longer says ~S." phrase)))
  t)

(defun check-trusted-examples-review ()
  "Structure and navigation of the Trusted Executable Examples review."
  (hyperdoc::ensure-pages-loaded reading:*lisp-critic-reading*)
  (check-review-site-pages)
  (check-review-site-links)
  (check-review-reading-page)
  (format t "~&TRUSTED-EXAMPLES-REVIEW-PASS: three local pages, links resolved ~
locally, one create entry each, reading opens exactly them.~%")
  t)

;;
;; Deciding how ordinary Code story items are rendered: three reading pages
;;
;; Structure and navigation only. The pages prepare two decisions; nothing here
;; takes one, and nothing loads the slice whose side effect they are about.

(defparameter +decision-pages+
  '("Deciding How Ordinary Code Story Items Are Rendered"
    "Code Rendering and Loaded Systems"
    "Code Rendering and the Inspector Link")
  "The entry page of the two decisions, then one page per decision.")

(defparameter +p1-evidence-commit+ "e91349f6171839a12eea7ee2f24da393b4dd870c"
  "The commit that keeps the files of probe P1.")

(defparameter +decision-pages-commit+ "176e6dfc8129743dd0bfb32d223636cd19f209d8"
  "The commit at which an answer page cites the two decision pages.")

(defun %page-text (title)
  (substitute #\Space #\Newline (uiop:read-file-string (hyperdoc:file-of (page-of title)))))

(defun check-decision-page (title)
  (let* ((page (page-of title))
         (*package* (page-package page))
         (text (%page-text title))
         (links (page-links page))
         (root (truename (uiop:ensure-directory-pathname (review-site-root))))
         (opened (mapcar #'hyperdoc::parse-and-eval (page-expressions page))))
    (check (search "No decision has been taken" text)
           "~S no longer says that no decision has been taken." title)
    (dolist (other +decision-pages+)
      (unless (equal other title)
        (check (member other links :test #'string=)
               "~S does not link to ~S." title other)))
    (check (search +p1-evidence-commit+ text)
           "~S does not cite the P1 evidence commit." title)
    (cl-ppcre:do-matches-as-strings (url "https://github\\.com/RalfBarkow/hyperdoc/[^\"' <]*" text)
      (check (cl-ppcre:scan "^https://github\\.com/RalfBarkow/hyperdoc/(blob/[0-9a-f]{40}/|commit/[0-9a-f]{40}$)" url)
             "~S links ~A, which is not pinned to a commit." title url))
    (check (not (cl-ppcre:scan "\\b(N0|R[1-6])\\b" text))
           "~S uses the review's internal shorthand." title)
    (check (not (cl-ppcre:scan "https?://[^\"' <]*trusted-examples-review\\.invalid" text))
           "~S gives the review's local site an address." title)
    (dolist (object opened)
      (check (typep object 'lp:local-fedwiki-page)
             "~S addresses ~S, not a local Wiki page." title object)
      (check (equal root (lp:local-fedwiki-page-site-root-of object))
             "~S opens ~A outside the review's site." title (hyperbook:id-of object)))
    (check (null (set-exclusive-or (remove-duplicates (mapcar #'hyperbook:id-of opened) :test #'equal)
                                   (mapcar #'first +review-pages+)
                                   :test #'equal))
           "~S opens ~S, not the question and both positions."
           title (mapcar #'hyperbook:id-of opened)))
  t)

(defun check-code-rendering-decision ()
  "The three decision pages link each other and the entry, cite the P1 evidence
commit, open only the review's local Wiki pages, use no internal shorthand and
take no decision; the entry page shows the observed HTML and says where and how
an answer is written."
  (hyperdoc::ensure-pages-loaded reading:*lisp-critic-reading*)
  (let ((before (find-package "DREYECK/VERIFIED-EXAMPLE")))
    (mapc #'check-decision-page +decision-pages+)
    (let ((text (%page-text (first +decision-pages+))))
      (dolist (phrase '("&lt;pre style='background-color: #eee;'&gt;(defun square (x) (* x x))&lt;/pre&gt;"
                        "&lt;pre&gt;(defun square (x) (* x x))&lt;/pre&gt;"
                        "Your answer is yours, on a Federated Wiki site you own."
                        "is deliberately not an address"
                        "<code>question</code>" "<code>claim</code>"
                        "<code>support</code>" "<code>oppose</code>"
                        "A binding project decision"
                        "Write one page for each decision, not one page for both."
                        "It does not by itself make a Wiki relation."
                        "each with a stable Wiki identity"
                        "and none may be invented from them"
                        "These pages have not yet been checked in a running HyperDoc Catalog."
                        "This page records no answer and suggests none."))
        (check (search phrase text)
               "The decision entry page no longer says ~S." phrase))
      ;; Each answer page cites its question at the commit that holds it.
      (dolist (file '("Code%20Rendering%20and%20Loaded%20Systems.html"
                      "Code%20Rendering%20and%20the%20Inspector%20Link.html"))
        (let ((url (concatenate 'string "https://github.com/RalfBarkow/hyperdoc/blob/"
                                +decision-pages-commit+ "/dreyeck/pages/lisp-critic/" file)))
          (check (search url text)
                 "The decision entry page does not cite ~A." url))))
    (check (eq before (find-package "DREYECK/VERIFIED-EXAMPLE"))
           "Reading the decision pages changed whether DREYECK/VERIFIED-EXAMPLE exists."))
  (format t "~&CODE-RENDERING-DECISION-PASS: three pages, linked, pinned to commits, ~
no decision taken.~%")
  t)

(defun run-current-tests ()
  "The regular checks. They need no source station and no engine, and are run in a runtime that finds none, on any machine.

What needs a station is not in this list and is not skipped: the engine integration tier (dreyeck/lisp-critic/engine-integration/tests) and
the page-station layout tier (dreyeck/lisp-critic/page-station/tests) hold it, and each refuses to start without one."
  (hyperdoc::ensure-pages-loaded reading:*lisp-critic-reading*)
  (call-with-absent-station
   (lambda ()
     (check-pages-present)
     (check-navigation)
     (check-genealogy-separation)
     (check-genealogy-projection)
     (check-discourse-projection)
     (check-reading-page-is-readable)
     (check-historical-claims)
     (check-source-passage-navigation)
     (check-node-view-shows-the-graph)
     (check-page-attached-system-view)
     (check-source-representations)
     (check-critique-from-snapshot)
     (check-recorded-critiques-are-readable)
     (check-the-absent-engine-is-reported-as-absent)
     (check-asset-root-resolution)
     (check-genealogy-reads-as-domain-language)
     (check-station-claim-links)
     (check-historical-claim-views)
     (check-transclusions-and-examples)
     (check-reading-examples-honour-the-policy)
     (check-trusted-examples-review)
     (check-code-rendering-decision)))
  (format t "~&LISP-CRITIC-READING-PASS: six pages, two lines kept apart, source-backed transclusion, the absent engine reported as absent, recorded critiques read without it. (No station was needed or used.)~%")
  t)

(defun run-tests ()
  (run-current-tests)
  (check-degraded-runtime)
  (format t "~&CURRENT-IMAGE-READING-PASS~%")
  (uiop:run-program
   (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
         "--eval" "(require :asdf)"
         "--eval" (format nil "(asdf:load-asd ~S)" (asdf:system-source-file "dreyeck"))
         "--eval" "(asdf:load-system \"dreyeck/lisp-critic/reading/tests\")"
         "--eval" "(dreyeck/lisp-critic/reading/tests:run-current-tests)")
   :output *standard-output* :error-output *error-output*)
  (format t "~&FRESH-PROCESS-READING-PASS~%")
  (check-policy-boundary-with-a-present-station)
  (check-the-engine-integration-test-can-fail)
  t)

(defun check-the-engine-integration-test-can-fail ()
  "The integration test that this suite does not run is shown to be able to fail: in fresh images it must fail with no station, with an empty
station, and with an engine that runs and says nothing. Without this, a missing station could be a pass nobody notices."
  (let ((output (with-output-to-string (stream)
                  (uiop:run-program
                   (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
                         "--eval" "(require :asdf)"
                         "--eval" (format nil "(asdf:load-asd ~S)" (asdf:system-source-file "dreyeck"))
                         "--eval" "(asdf:load-system \"dreyeck/lisp-critic/engine-integration/tests\")"
                         "--eval" "(dreyeck/lisp-critic/engine-integration/tests:run-negative-controls)")
                   :output stream :error-output stream))))
    (check (search "ENGINE-INTEGRATION-NEGATIVE-CONTROLS-PASS" output)
           "The engine integration test's negative controls did not pass:~%~A" output))
  (format t "~&ENGINE-INTEGRATION-CAN-FAIL-PASS~%")
  t)

(defun check-policy-in-a-clean-image ()
  "Measure the refusal where the difference can still be seen.

CHECK-READING-EXAMPLES-HONOUR-THE-POLICY runs inside a suite that has
already loaded the engine on purpose, so its difference is empty either
way: nothing can be added that is not already there. That test was
written first and passed with the guard removed, which is the whole
reason this one exists. A differential measurement needs more than a
before and an after — it needs a state in which the two could differ.

So the same questions are asked again in a process that has loaded
nothing, and in both directions. Under a refusing policy the examples
must add no system and no package. Then, in the same image, the policy
is opened and one example is run again: it must load the engine. Without
that second half the first would prove only that the measurement is
blind."
  (uiop:run-program
   (list (namestring sb-ext:*runtime-pathname*) "--no-userinit" "--non-interactive"
         "--eval" "(require :asdf)"
         "--eval" (format nil "(asdf:load-asd ~S)" (asdf:system-source-file "dreyeck"))
         "--eval" "(asdf:load-system \"dreyeck/lisp-critic/reading\")"
         "--eval" "(asdf:load-system \"hyperbook/server\")"
         "--eval"
         "(let* ((packages '(:lisp-critic :lisp-critic-user :extend-match :a-critic-for-lisp))
                 (present (lambda () (remove-if-not #'find-package packages)))
                 (parameters (find-symbol \"*SERVER-PARAMETERS*\" :hyperbook/server))
                 (examples (list #'dreyeck/lisp-critic/reading:critique-anatomy-example
                                 #'dreyeck/lisp-critic/reading:riesbeck-car-cdr-rule-example
                                 #'dreyeck/lisp-critic/reading:evidence-ladder-example)))
            (assert (null (funcall present)))
            ;; Refusing: nothing may arrive.
            (setf (symbol-value parameters) (list \"700px\" nil))
            (assert (not (dreyeck/lisp-critic/reading:execution-permitted-p)))
            (let ((systems (length (asdf:registered-systems))))
              (dolist (example examples) (ignore-errors (funcall example)))
              (assert (null (funcall present)))
              (assert (= systems (length (asdf:registered-systems)))))
            ;; The recorded finding stays readable exactly here.
            (let ((target (dreyeck/lisp-critic/reading:current-critique-example)))
              (assert (typep target 'dreyeck/lisp-critic:critic-target))
              (assert (= 1 (length (dreyeck/lisp-critic:critiques-of
                                    (first (dreyeck/lisp-critic:target-runs-of target)))))))
            ;; Permitted: it must arrive, or the measurement above was blind.
            (setf (symbol-value parameters) nil)
            (assert (dreyeck/lisp-critic/reading:execution-permitted-p))
            (let* ((result (funcall (first examples)))
                   (record (getf result :evaluation-record))
                   (missing (set-difference packages (funcall present))))
              (unless (null missing)
                (error \"Permitted policy did not load ~S; present ~S, run ~A, ~
because: ~A. The refusal measured above would then prove nothing, since this ~
shows the measurement cannot see loading at all.\"
                       missing (funcall present)
                       (and record (dreyeck/lisp-critic:lisp-critic-run-record-status record))
                       (and record (dreyeck/lisp-critic:lisp-critic-run-record-condition-summary-of record)))))
            (format t \"~&POLICY-BOUNDARY-PASS: refused adds nothing, permitted loads the engine, recorded finding readable in both.~%\"))")
   :output *standard-output* :error-output *error-output*)
  t)
