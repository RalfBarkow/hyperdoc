;;;; Contracts for the Lisp Critic genealogy reading.
;;;;
;;;; The reading claims three different kinds of access to three different
;;;; stations. These tests hold it to that: a documented station must stay
;;;; documented, and an executable one must actually execute.

(defpackage #:dreyeck/lisp-critic/reading/tests
  (:use #:cl)
  (:local-nicknames (#:reading #:dreyeck/lisp-critic/reading)
                    (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:views #:html-inspector-views)
                    (#:tm #:dreyeck/topicmap))
  (:export #:run-tests #:run-current-tests #:check-under-catalog-runtime
           #:check-degraded-runtime))

(in-package #:dreyeck/lisp-critic/reading/tests)

(defparameter +pages+
  '("Reading the Lisp Critic Genealogy"
    "The Fischer Critic as an Environment"
    "Reading Riesbeck's Lisp Critic"
    "From Riesbeck Run to HyperDoc Critique"
    "Anatomy of a Critique"))

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

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
      ;; Every addressed example must run. A plist-shaped result must still
      ;; carry its evidence status; a projection or a domain object is a
      ;; legitimate result too and is inspected rather than read as data.
      (dolist (expression (page-expressions page))
        (let ((value (hyperdoc::parse-and-eval expression)))
          (check (not (typep value 'condition))
                 "Page ~S: example ~S produced ~A." title expression value)
          (when (and (consp value) (keywordp (first value)))
            (check (getf value :evidence-status)
                   "Page ~S: example ~S returned a plist without an evidence ~
status." title expression))))))
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
    ;; The relation across the two lines must remain a resemblance.
    (check (eq :conceptual-resemblance (getf riesbeck :relation-to-predecessor))
           "Riesbeck's station claims ~S to its predecessor."
           (getf riesbeck :relation-to-predecessor))
    ;; No station anywhere may claim descent.
    (dolist (station stations)
      (dolist (key '(:relation-to-predecessor :relation-to-successor))
        (check (not (eq :descends-from (getf station key)))
               "Station ~S claims descent, which no local evidence supports."
               (getf station :station))))
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
  "Exercise this book the way the normal Catalog launcher reaches it.

Called from the Catalog startup proof, in its fresh process, so the book
cannot pass on a development image's leftover state."
  (let ((book (hyperbook:find-hyperbook "dreyeck/lisp-critic/reading"
                                        :signal-error? t)))
    (hyperdoc::ensure-pages-loaded book)
    (check (= (length +pages+) (hash-table-count (hyperdoc:pages-of book)))
           "The Catalog sees ~D reading pages instead of ~D."
           (hash-table-count (hyperdoc:pages-of book)) (length +pages+))
    ;; Every page must render, and none may present a load failure as content.
    (dolist (title +pages+)
      (let* ((page (hyperbook:find-page book title :signal-error? t))
             (view (find "Content" (views:all-views page)
                         :key #'views:view-title :test #'string=))
             (html (progn (check view "Page ~S has no Content view." title)
                          (views:view-html view))))
        (check (plusp (length html)) "Page ~S rendered nothing." title)
        (check (not (search "is not loaded" html))
               "Page ~S renders an engine load failure as content." title)
        ;; Structural, not a fixed count: whatever the page addresses, the
        ;; Catalog must be able to evaluate all of it.
        (let ((*package* (page-package page)))
          (dolist (expression (page-expressions page))
            (let ((value (hyperdoc::parse-and-eval expression)))
              (check (not (typep value 'condition))
                     "Catalog runtime: ~S on ~S produced ~A."
                     expression title value)
              (when (and (consp value) (keywordp (first value)))
                (check (getf value :evidence-status)
                       "Catalog runtime: ~S on ~S returned a plist without ~
an evidence status." expression title)))))))
    ;; And the critic must genuinely run: a real CAR-CDR match.
    (let* ((match (reading:critic-match-example))
           (record (getf match :record)))
      (check (getf match :engine-available-p)
             "The Catalog runtime cannot reach the Riesbeck engine.")
      (check (eq :completed (er:evaluation-status-of record))
             "The Catalog runtime failed the CAR-CDR run: ~A"
             (er:evaluation-failure-of record))
      (check (= 1 (length (er:evaluation-result-of record)))
             "The Catalog runtime produced ~D critiques instead of one."
             (length (er:evaluation-result-of record)))
      (check (search "CADR" (critic:critique-explanation-of
                             (first (er:evaluation-result-of record))))
             "The Catalog runtime lost the engine's recommendation.")))
  (check-historical-claim-views)
  (format t "~&CATALOG-LISP-CRITIC-READING-PASS: pages render, examples ~
evaluate, real CAR-CDR match.~%")
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

(defun run-current-tests ()
  (hyperdoc::ensure-pages-loaded reading:*lisp-critic-reading*)
  (check-pages-present)
  (check-navigation)
  (check-genealogy-separation)
  (check-genealogy-projection)
  (check-discourse-projection)
  (check-reading-page-is-readable)
  (check-historical-claims)
  (check-source-passage-navigation)
  (check-historical-claim-views)
  (check-outcomes)
  (check-source-backing)
  (check-transclusions-and-examples)
  (format t "~&LISP-CRITIC-READING-PASS: five pages, two lines kept apart, ~
three outcomes, source-backed transclusion.~%")
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
  t)
