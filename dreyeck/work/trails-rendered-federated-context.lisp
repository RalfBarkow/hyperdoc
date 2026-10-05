;;;; One temporal reading of selected, observed Federated Wiki journal events.
(in-package #:dreyeck/work/trails-rendered-reading)

(defclass federated-context ()
  ((data :initarg :data :reader context-data)
   (cursor :initarg :cursor :accessor context-cursor)
   (mode :initform :state :accessor context-mode)
   (event-objects :initform (make-hash-table) :reader context-event-objects)
   ;; These are cached results, not another temporal engine. Only CURSOR selects
   ;; time; every result comes from CONTEXT-DELTA / CONTEXT-STATE-AT.
   (deltas :initform (make-hash-table) :reader context-deltas)
   (page-objects :initform (make-hash-table) :reader context-page-objects)
   (subjects :initform (make-hash-table :test 'equal) :reader context-subjects)
   (workspace :initform nil :accessor context-workspace)
   (layouts :initform (make-hash-table :test 'equal) :reader context-layouts)))

(defclass federated-event ()
  ((record :initarg :record :reader event-record)
   (context :initarg :context :reader event-context)))

;; Native pages retain their native Story/Links behavior. This specialization
;; distinguishes a saved historical reading from a live, reloadable page.
(defclass context-fedwiki-page (hyperbook/fedwiki::fedwiki-page)
  ((evidence :initarg :evidence :reader page-evidence)
   (event :initarg :event :reader page-event)
   (json :initarg :json :reader page-json)))

;; A collaborative wiki-link has one source and selects its first match. A
;; shared subject has several source contexts and must retain all candidates.
(defclass federated-subject ()
  ((title :initarg :title :reader subject-title)
   (context :initarg :context :reader subject-context)
   (event :initarg :event :reader subject-event)
   (links :initarg :links :reader subject-links)
   ;; Only an explicit follow fills this result. The Subject view can present
   ;; candidates and lookup failures without resolving links during rendering.
   (resolution :initform nil :accessor subject-resolution)))

(defun context-events (context)
  (gethash "events" (gethash "temporal" (context-data context))))

(defun context-pages (context)
  (gethash "pages" (gethash "observed" (context-data context))))

(defun context-event-object (context index)
  (or (gethash index (context-event-objects context))
      (setf (gethash index (context-event-objects context))
            (make-instance 'federated-event :record (aref (context-events context) index) :context context))))

(defun context-page (context key)
  (or (find key (context-pages context) :key (lambda (page) (gethash "id" page)) :test #'equal)
      (error "Unknown context page ~S" key)))

(defun context-page-id (page)
  (format nil "~A/~A" (gethash "hyperbook" page) (gethash "slug" page)))

(defun context-page-label (page)
  (let* ((site (gethash "site" page))
         (name (cond ((equal site "jan.voices.ustawi.wiki") "Jan")
                     ((equal site "thompson.voices.ustawi.wiki") "Thompson")
                     ((equal site "ward.voices.ustawi.wiki") "Ward")
                     (t site))))
    (format nil "~A / ~A" name (gethash "title" page))))

(defun native-context-page (page)
  "Use the existing FedWiki HyperBook resolver, preserving site and slug."
  (if (typep page 'hyperbook/fedwiki::fedwiki-page) page
      (hyperbook:find-page (hyperbook:find-hyperbook (gethash "hyperbook" page) :signal-error? t)
                          (gethash "slug" page) :signal-error? t)))

(defun render-context-page-link (page)
  ;; Resolving a live site/page is navigation, not presentation. Keep it behind
  ;; the same native EVAL transport that follows a context sign.
  (html-inspector-views:html
    (:span :class "hyperbook-reference inspector-inspect"
           :id (html-inspector-views:eval-id (html-inspector-views:thunk (native-context-page page)))
           (html-inspector-views:esc (context-page-label page)))))

(defun select-context-event (context index)
  (check-type index integer)
  (setf (context-cursor context) (max 0 (min index (1- (length (context-events context))))))
  t)

(defun context-milliseconds (timestamp)
  (etypecase timestamp
    (integer timestamp)
    (string (let ((time (local-time:parse-timestring timestamp)))
              (+ (* 1000 (local-time:timestamp-to-unix time))
                 (truncate (local-time:nsec-of time) 1000000))))))

(defun context-time-string (milliseconds)
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (+ 2208988800 (floor milliseconds 1000)) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0D.~3,'0DZ"
            year month day hour minute second (mod milliseconds 1000))))

(defun context-table (&rest pairs)
  (alexandria:plist-hash-table pairs :test 'equal))

(defun context-item-attribution (item)
  "Interpret attribution from this page-scoped item, never from an item-ID index."
  (when (and (hash-table-p item) (search "via Thompson" (gethash "text" item "")))
    (context-table "attribution" "via Thompson" "credited-page" "thompson-think")))

(defun context-last-fork (page)
  "The last named fork separates inherited history from this site's actions."
  (position-if (lambda (action) (and (equal "fork" (gethash "type" action))
                                   (gethash "site" action) (gethash "date" action)))
               (gethash "journal" (gethash "raw" page)) :from-end t))

(defun context-local-journal (page)
  (let ((journal (gethash "journal" (gethash "raw" page))))
    (subseq journal (or (context-last-fork page) 0))))

(defun context-page-story-at (page milliseconds)
  "Replay raw create/add/edit/remove actions; a fork already carries its source prefix.
Never execute page code. Return the selected page's actual item values by ID."
  (let ((story (make-hash-table :test 'equal)))
    (loop for action across (gethash "journal" (gethash "raw" page))
          when (and (gethash "date" action) (<= (gethash "date" action) milliseconds))
            do (let ((type (gethash "type" action)) (item (gethash "item" action)))
                 (cond ((equal type "create")
                        (clrhash story)
                        (loop for initial across (gethash "story" item #())
                              do (setf (gethash (gethash "id" initial) story) initial)))
                       ((member type '("add" "edit") :test #'equal)
                        (setf (gethash (gethash "id" action) story) item))
                       ((equal type "remove") (remhash (gethash "id" action) story)))))
    story))

(defun context-page-json-at (page milliseconds)
  "Adapt the existing historical item values to a native page, retaining order.
Only presentation order is replayed here; STATE-AT remains authoritative."
  (let ((items (context-page-story-at page milliseconds)) (order nil)
        (journal (remove-if (lambda (a) (and (gethash "date" a)
                                            (> (gethash "date" a) milliseconds)))
                            (gethash "journal" (gethash "raw" page)))))
    (labels ((insert-after (id after)
               (let ((position (position after order :test #'equal)))
                 (setf order (append (subseq order 0 (if position (1+ position) 0))
                                     (list id) (subseq order (if position (1+ position) 0)))))))
      (loop for action across journal
            when (gethash "date" action)
              do (let ((kind (gethash "type" action)) (id (gethash "id" action)))
                   (cond ((equal kind "create")
                          (setf order (map 'list (lambda (item) (gethash "id" item))
                                           (gethash "story" (gethash "item" action) #()))))
                         ((equal kind "add") (insert-after id (gethash "after" action)))
                         ((equal kind "edit")
                          (unless (member id order :test #'equal) (setf order (append order (list id)))))
                         ((equal kind "remove") (setf order (remove id order :test #'equal)))
                         ((equal kind "move")
                          (let* ((absolute (coerce (gethash "order" action) 'list))
                                 (position (position id absolute :test #'equal)))
                            (setf order (remove id order :test #'equal))
                            (insert-after id (and position (plusp position) (nth (1- position) absolute)))))))))
    ;; Native constructors consume their JSON fields, so never hand them the
    ;; saved evidence or the actual item values used by temporal derivation.
    (dreyeck/work/reading::%copy-json
     (context-table "title" (gethash "title" page)
                    "story" (coerce (loop for id in order for item = (gethash id items)
                                           when item collect item) 'vector)
                    "journal" journal))))

(defun context-native-pages-at (context event)
  "Memoize native historical page objects without I/O or global registration.
The per-time native site catalogs contain only this reading's saved evidence."
  (let ((time (gethash "date" (event-record event))))
    (or (gethash time (context-page-objects context))
        (let ((sites (make-hash-table :test 'equal)) (pages nil))
          (labels ((site (name)
                     (or (gethash name sites)
                         (setf (gethash name sites)
                               (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                                                          :id (format nil "fedwiki:~A" name))))
                                 (setf (hyperbook/fedwiki::status-of wiki) t)
                                 wiki)))))
            (loop for evidence across (context-pages context)
                  when (context-page-present-p evidence time)
                    do (let* ((wiki (site (gethash "site" evidence)))
                              (json (context-page-json-at evidence time))
                              (page (make-instance 'context-fedwiki-page
                                                   :hyperbook wiki :id (gethash "slug" evidence)
                                                   :title (gethash "title" evidence)
                                                   :evidence evidence :event event :json json)))
                         (setf (gethash (hyperbook:id-of page) (hyperbook/fedwiki::pages-of wiki)) page)
                         (push page pages)))
            (dolist (page pages)
              (let* ((json (dreyeck/work/reading::%copy-json (page-json page)))
                     (journal (hyperbook/fedwiki::make-journal (gethash "journal" json))))
                (setf (slot-value page 'hyperbook/fedwiki::story)
                      (hyperbook/fedwiki::make-story (gethash "story" json))
                      (slot-value page 'hyperbook/fedwiki::journal) journal
                      (slot-value page 'hyperbook/fedwiki::context)
                      (hyperbook/fedwiki::resolve-context-site-references
                       (hyperbook/fedwiki::context-site-references journal) #'site)
                      (slot-value page 'hyperbook/fedwiki::links) (hyperbook/fedwiki::extract-links page))))
            (setf (gethash time (context-page-objects context)) (nreverse pages)))))))

(defun context-page-object (context evidence &optional (event (context-event-object context (context-cursor context))))
  (or (find evidence (context-native-pages-at context event) :key #'page-evidence :test #'eq)
      (error "Page ~A is absent at ~A" (gethash "id" evidence) (gethash "at" (event-record event)))))

(defun context-subject-object (context title &optional (event (context-event-object context (context-cursor context))))
  (let ((key (list (gethash "date" (event-record event)) title)))
    (or (gethash key (context-subjects context))
        (setf (gethash key (context-subjects context))
              (make-instance 'federated-subject :title title :context context :event event
                             :links (loop for page in (context-native-pages-at context event)
                                          append (remove-if-not
                                                  (lambda (link) (equal title (hyperbook/fedwiki::target-title-of link)))
                                                  (hyperbook/fedwiki::wiki-links-of (hyperbook:links-of page)))))))))

(defun subject-context-pages (subject)
  "All recorded page identities for this title at the subject's source event."
  (remove-if-not (lambda (page) (equal (subject-title subject) (hyperbook:title-of page)))
                 (context-native-pages-at (subject-context subject) (subject-event subject))))

(defun historical-wiki-link-target (page title)
  "Use native local/context catalogs, preserving an unresolved subject on a miss.
A historical reading must not fall through to a live plugin/page fetch."
  (let ((slug (hyperbook/fedwiki::slug title)))
    (or (gethash slug (hyperbook/fedwiki::pages-of (hyperbook:hyperbook-of page)))
        (loop for wiki in (hyperbook/fedwiki::context-of page)
              thereis (gethash slug (hyperbook/fedwiki::pages-of wiki)))
        (context-subject-object (event-context (page-event page)) title (page-event page)))))

(defun historical-wiki-link (page title)
  (make-instance 'hyperbook/fedwiki::wiki-link
                 :source-hyperbook (hyperbook:id-of (hyperbook:hyperbook-of page))
                 :source-page (hyperbook:id-of page)
                 :target-title title :target-slug (hyperbook/fedwiki::slug title)
                 :thunk (html-inspector-views:thunk (historical-wiki-link-target page title))))

(defmethod hyperbook/fedwiki::extract-links-from-wiki-text (text (page context-fedwiki-page))
  (hyperbook/fedwiki::process-text-and-links
   text page (lambda (chunk source) (declare (ignore chunk source)) nil)
   (lambda (chunk source)
     (if (uiop:string-prefix-p "[[" chunk)
         (historical-wiki-link source (subseq chunk 2 (- (length chunk) 2)))
         (hyperbook/fedwiki::collect-link chunk source)))))

(defmethod hyperbook/fedwiki::render-wiki-text (text (page context-fedwiki-page))
  (hyperbook/fedwiki::process-text-and-links
   text page
   (lambda (chunk source) (declare (ignore source))
     (html-inspector-views:html (html-inspector-views:esc chunk)))
   (lambda (chunk source)
     (if (uiop:string-prefix-p "[[" chunk)
         (let ((title (subseq chunk 2 (- (length chunk) 2))))
           (html-inspector-views:html
             (:span :class "hyperbook-reference"
                    (html-inspector-views:object-ref (historical-wiki-link-target source title) :display title))))
         (hyperbook/fedwiki::render-link chunk source)))))

(defun subject-neighborhood-pages (subject)
  "Existing cached neighborhood candidates. No fetch, fork, or preferred site.
These references are not a claim about their uncaptured historical contents."
  (let ((slug (hyperbook/fedwiki::slug (subject-title subject))) (pages nil))
    (maphash (lambda (site wiki)
               (declare (ignore site))
               (let ((page (gethash slug (hyperbook/fedwiki::pages-of wiki))))
                 (when page (push page pages))))
             hyperbook/fedwiki::*neighborhood*)
    (sort pages #'string< :key (lambda (page) (hyperbook:id-of (hyperbook:hyperbook-of page))))))

(defun subject-page-identity (page)
  "A remote reference and its origin page are the same concrete candidate."
  (list (hyperbook:id-of (hyperbook/fedwiki::origin-of page))
        (hyperbook/fedwiki::origin-id-of page)))

(defun resolve-federated-subject (subject)
  "Follow each existing collaborative link, retaining distinct site candidates.
Historical links retain their saved targets. On a historical miss, ask the
native link resolver in that source page's live context. This is an explicit
navigation operation; projection and Subject rendering never call it."
  (let ((pages (copy-list (subject-context-pages subject))) (failures nil))
    (dolist (link (subject-links subject))
      (let ((target
              (handler-case
                  (let ((historical (html-inspector-views:eval-thunk (hyperbook::thunk-of link))))
                    (if (typep historical 'hyperbook/fedwiki::fedwiki-page) historical
                        (let ((source (hyperbook:find-page
                                       (hyperbook:find-hyperbook (hyperbook::source-hyperbook-of link)
                                                                :signal-error? t)
                                       (hyperbook::source-page-of link) :signal-error? t)))
                          (hyperbook/fedwiki::load-page source)
                          (html-inspector-views:eval-thunk
                           (hyperbook::thunk-of
                            (hyperbook/fedwiki::make-wiki-link
                             source :target-title (subject-title subject)
                                    :target-slug (hyperbook/fedwiki::target-slug-of link)))))))
                (error (condition) condition))))
        (cond ((typep target 'hyperbook/fedwiki::fedwiki-page)
               (setf pages (append pages (list target))))
              ((typep target 'hyperbook/fedwiki::wiki-lookup-failure))
              (t (push (cons link target) failures)))))
    (setf (subject-resolution subject)
          (list :pages (remove-duplicates (append pages (subject-neighborhood-pages subject))
                                         :key #'subject-page-identity :test #'equal :from-end t)
                :failures (nreverse failures)))))

(defun follow-context-object (object)
  "Return wiki working material through the Inspector's native follow transport."
  (etypecase object
    (hyperbook/fedwiki::fedwiki-page object)
    (federated-subject
     (let* ((resolution (resolve-federated-subject object))
            (pages (getf resolution :pages)))
       ;; Operational failures leave the candidate set incomplete. Present the
       ;; Subject chooser in that case, even if one page was found elsewhere.
       (if (and (= 1 (length pages)) (null (getf resolution :failures)))
           (first pages) object)))))

(defun context-followable-object-p (object)
  "The domain already offered by Follow; actual dispatch remains in FOLLOW-CONTEXT-OBJECT."
  (typep object '(or hyperbook/fedwiki::fedwiki-page federated-subject)))

(defparameter *context-topic-follow-bindings*
  (loop for kind in '(:radial-menu :learned-mark)
        collect (dreyeck/gesture-binding-witness::%make-gesture-binding
                 :id (format nil "binding/~(~A~)-follow" kind) :kind kind
                 :sector-center 90.0d0 :sector-half-width 30.0d0
                 :target-type :workspace-action-sign-occurrence :enabled-p t
                 :operation (dreyeck/gesture-binding-witness:follow-operation))))

(defmethod dreyeck/inspector/topicmap:workspace-action-sign-bindings :around ((occurrence t))
  ;; Less specific than Work's existing around method, so both providers compose.
  (let ((bindings (call-next-method)))
    (if (and (typep occurrence 'dreyeck/inspector/topicmap:workspace-action-sign-occurrence)
             (context-followable-object-p
              (dreyeck/inspector/topicmap:occurrence-inspectable-object occurrence)))
        (append bindings *context-topic-follow-bindings*)
        bindings)))

(defmethod dreyeck/inspector/topicmap:operation-inspectable-object
    ((operation (eql (dreyeck/gesture-binding-witness:follow-operation))) target)
  (let* ((topic (dreyeck/inspector/topicmap::%topic-operation-topic operation target))
         (object (dreyeck/topicmap:topicmap-topic-object-of topic)))
    (unless (context-followable-object-p object)
      (error 'dreyeck/inspector/topicmap:operation-not-applicable
             :operation operation :target target
             :reason "the represented object is not supported by federated Follow"))
    (follow-context-object object)))

(defun context-topic-primary-reference (context projection-kind topic)
  (let ((object (dreyeck/topicmap:topicmap-topic-object-of topic)))
    (ecase projection-kind
      (:temporal
       (html-inspector-views:action-id
        (html-inspector-views:thunk
          (select-context-event (event-context object)
                                (position (event-record object) (context-events context) :test #'eq)))))
      (:context
       ;; EVAL opens the operation's result beside the source, without refreshing it.
       ;; Relation endpoints retain ACTION and the movement-only reference.
       (funcall (if (context-followable-object-p object)
                    #'html-inspector-views:eval-id #'html-inspector-views:action-id)
                (context-point-reference (context-current-workspace context) topic))))))

(defun context-wiki-targets (text)
  "Reuse the FedWiki text/link scanner, including its treatment of incomplete links."
  (remove nil
          (hyperbook/fedwiki::process-text-and-links
           (or text "") nil
           (lambda (chunk page) (declare (ignore chunk page)) nil)
           (lambda (chunk page)
             (declare (ignore page))
             (when (uiop:string-prefix-p "[[" chunk) (subseq chunk 2 (- (length chunk) 2)))))))

(defun context-trail-type (page story)
  "Read the literal relation label in the observed public trail builder, without execution."
  (let* ((id (gethash "trail-code-item" page)) (item (and id (gethash id story))))
    (when (and item (equal "code" (gethash "type" item)))
      (multiple-value-bind (match groups)
          (cl-ppcre:scan-to-strings "graph[.]addRel\\(\"([^\"]*)\",\\s*prev,\\s*nid,\\s*\\{\\}\\)"
                                   (gethash "text" item ""))
        (unless match (error "Unrecognized public trail relation literal in ~A" id))
        (aref groups 0)))))

(defun context-page-present-p (page milliseconds)
  (let* ((journal (gethash "journal" (gethash "raw" page)))
         (arrival (aref journal (or (context-last-fork page) 0))))
    (<= (gethash "date" arrival) milliseconds)))

(defun context-concept-names (context)
  ;; Interpretive projection rule: shared title spelling denotes a shared subject;
  ;; it does not establish shared authorship, causal influence, or identical pages.
  (remove-duplicates
   (loop for page across (context-pages context)
         append (loop for item across (gethash "story" (gethash "raw" page))
                      when (find (gethash "id" item)
                                 (append (coerce (gethash "link-items" page) 'list)
                                         (coerce (gethash "trail-items" page #()) 'list)) :test #'equal)
                        append (context-wiki-targets (gethash "text" item))))
   :test #'equal))

(defun context-link-target (context page name milliseconds)
  "Trail subjects remain concepts; other links can refer to a recorded site/page identity."
  (let* ((trail-names (loop for p across (context-pages context)
                            append (loop for id across (gethash "trail-items" p #())
                                         append (context-wiki-targets
                                                 (gethash "text" (gethash id (context-page-story-at p milliseconds)))))))
         (fork (context-last-fork page))
         (source (and fork (gethash "site" (aref (gethash "journal" (gethash "raw" page)) fork))))
         (target (unless (member name trail-names :test #'equal)
                   (loop for site in (list (gethash "site" page) source)
                         thereis (find-if (lambda (candidate)
                                          (and (equal site (gethash "site" candidate))
                                               (equal name (gethash "title" candidate))
                                               (context-page-present-p candidate milliseconds)))
                                        (context-pages context))))))
    (if target (context-page-id target) (format nil "concept:~A" name))))

(defun context-state-at (context timestamp)
  "Derive this experiment's graph from saved raw journals at inclusive TIMESTAMP.
TIMESTAMP is an ISO UTC string or Unix milliseconds. No prepared effect is read."
  (let* ((milliseconds (context-milliseconds timestamp))
         (names (context-concept-names context)) (topics nil) (relations nil))
    (labels ((relation (id kind from to &optional item)
               (pushnew from topics :test #'equal) (pushnew to topics :test #'equal)
               (push (if item (context-table "id" id "kind" kind "from" from "to" to "item" item)
                         (context-table "id" id "kind" kind "from" from "to" to)) relations)))
      (loop for page across (context-pages context)
            when (context-page-present-p page milliseconds)
              do (let* ((page-id (context-page-id page))
                        (story (context-page-story-at page milliseconds))
                        (fork (context-last-fork page)))
                   (pushnew page-id topics :test #'equal)
                   (when (member (gethash "title" page) names :test #'equal)
                     (relation (format nil "~A:subject" page-id) "shared-concept" page-id
                               (format nil "concept:~A" (gethash "title" page))))
                   (when fork
                     (let* ((action (aref (gethash "journal" (gethash "raw" page)) fork))
                            (source (find-if (lambda (p) (and (equal (gethash "site" action) (gethash "site" p))
                                                             (equal (gethash "title" page) (gethash "title" p))))
                                             (context-pages context))))
                       (when source (relation (format nil "fork:~A" page-id) "fork" (context-page-id source) page-id))))
                   (loop for id across (gethash "link-items" page)
                         for item = (gethash id story)
                         do (loop for name in (context-wiki-targets (and item (gethash "text" item)))
                                  for index from 0
                                  do (relation (if (zerop index) (format nil "~A:~A" page-id id)
                                                   (format nil "~A:~A:~D" page-id id index))
                                               "wiki-link" page-id (context-link-target context page name milliseconds) id)))
                   (loop for id across (gethash "trail-items" page #())
                         for nodes = (context-wiki-targets (gethash "text" (gethash id story)))
                         when nodes
                           do (relation (format nil "trail-start:~A" id) "trail-in-page" page-id
                                        (format nil "concept:~A" (first nodes)) id)
                              (loop for (from to) on nodes while to for index from 0
                                    do (relation (format nil "trail:~A:~D" id index) (context-trail-type page story)
                                                 (format nil "concept:~A" from) (format nil "concept:~A" to) id)))))
      (list :topics (sort topics #'string<)
            :relations (sort relations #'string< :key (lambda (r) (gethash "id" r)))))))

(defun context-derived-events (context)
  (let* ((window (gethash "window" (context-data context)))
         (start (context-milliseconds (gethash "start" window)))
         (end (context-milliseconds (gethash "end" window))) (events nil))
    (loop for page across (context-pages context)
          do (loop for action across (context-local-journal page)
                   for date = (gethash "date" action) for type = (gethash "type" action)
                   for id = (gethash "id" action)
                   for item = (gethash "item" action)
                   when (and date (<= start date) (< date end)
                             (or (and (equal type "fork") (gethash "site" action))
                                 (and (find id (gethash "link-items" page) :test #'equal)
                                      (equal "paragraph" (gethash "type" item)))
                                 (and (equal id (gethash "trail-code-item" page))
                                      (not (equal (context-trail-type page (context-page-story-at page (1- date)))
                                                  (context-trail-type page (context-page-story-at page date)))))))
                     do (let* ((before (gethash id (context-page-story-at page (1- date))))
                               (event (context-table "id" (format nil "~A:~D" (context-page-id page) date)
                                                     "page" (gethash "id" page) "date" date "at" (context-time-string date)
                                                     "site" (gethash "site" page) "page-title" (gethash "title" page)
                                                     "hyperbook" (gethash "hyperbook" page) "operation" type "journal" action
                                                     "before" (or before :null) "after" (or item :null))))
                          (when (equal type "fork")
                            (let ((source (find-if (lambda (p) (and (equal (gethash "site" action) (gethash "site" p))
                                                                  (equal (gethash "title" page) (gethash "title" p))))
                                                  (context-pages context))))
                              (unless source (error "Unrecorded fork source ~A" (gethash "site" action)))
                              (setf (gethash "source-page" event) (gethash "id" source)
                                    (gethash "after" event) (context-table "source-site" (gethash "site" action)
                                                                            "history" "inherited"))))
                          (push event events))))
    (coerce (stable-sort events (lambda (a b) (if (= (gethash "date" a) (gethash "date" b))
                                                (string< (gethash "id" a) (gethash "id" b))
                                                (< (gethash "date" a) (gethash "date" b))))) 'vector)))

(defun derive-federated-data (data)
  "Hydrate byte-preserved evidence, validate fork prefixes and derive all semantic readings."
  (let* ((pages (gethash "pages" data))
         (context (make-instance 'federated-context :data data :cursor 0))
         (observed (context-table "pages" pages "scope" (gethash "scope" data))))
    (setf (gethash "observed" data) observed)
    (loop for page across pages when (gethash "raw-file" page)
            do (setf (gethash "raw" page) (read-observation (gethash "raw-file" page)))
               (assert (equal (gethash "title" page) (gethash "title" (gethash "raw" page)))))
    ;; No independent download exists for this source: retain the receiving page's
    ;; actual inherited prefix as evidence, without fabricating a source snapshot.
    (loop for page across pages when (gethash "inherited-from" page)
            do (let* ((receiver (context-page context (gethash "inherited-from" page)))
                      (prefix (subseq (gethash "journal" (gethash "raw" receiver)) 0 (context-last-fork receiver)))
                      (raw (context-table "title" (gethash "title" page) "journal" prefix)))
                 (setf (gethash "raw" page) raw
                       (gethash "story" raw) (coerce (alexandria:hash-table-values
                                                     (context-page-story-at page most-positive-fixnum)) 'vector))))
    (loop for page across pages for fork = (context-last-fork page) when fork
            do (let* ((journal (gethash "journal" (gethash "raw" page))) (action (aref journal fork))
                      (source (find-if (lambda (p) (and (equal (gethash "site" action) (gethash "site" p))
                                                       (equal (gethash "title" page) (gethash "title" p)))) pages)))
                 (when source
                   (assert (dreyeck/work/reading::%json-equal
                            (subseq journal 0 fork)
                            (remove-if (lambda (a) (and (gethash "date" a)
                                                       (>= (gethash "date" a) (gethash "date" action))))
                                       (gethash "journal" (gethash "raw" source))))))))
    (let* ((events (context-derived-events context)) (links nil) (forks nil) (trails nil)
           (end (1- (context-milliseconds (gethash "end" (gethash "window" data)))))
           (change nil))
      (setf (gethash "temporal" data) (context-table "question" (gethash "question" data) "events" events))
      (loop for page across pages
            for story = (context-page-story-at page end)
            do (setf (gethash "items" page)
                     (map 'vector (lambda (id)
                                    (let ((item (gethash id story)))
                                      (if (and (gethash "content-summary" page) (equal "html" (gethash "type" item)))
                                          (let ((edit (find-if (lambda (a) (and (equal id (gethash "id" a))
                                                                               (equal "edit" (gethash "type" a))))
                                                               (gethash "journal" (gethash "raw" page)) :from-end t)))
                                            (context-table "type" "html" "id" id "content-summary" (gethash "content-summary" page)
                                                           "last-text-edit" (context-table "date" (gethash "date" edit)
                                                                                           "at" (context-time-string (gethash "date" edit)))))
                                          item))) (gethash "selected-items" page))
                     (gethash "journal" page)
                     (map 'vector (lambda (e) (let ((a (alexandria:copy-hash-table (gethash "journal" e))))
                                               (setf (gethash "at" a) (gethash "at" e)) a))
                          (remove-if-not (lambda (e) (equal (gethash "id" page) (gethash "page" e))) events)))
               (when (eq :true (gethash "observed-links" page))
                 (loop for id across (gethash "link-items" page)
                       for item = (gethash id story)
                       for attribution = (context-item-attribution item)
                       for action = (find-if (lambda (a) (equal id (gethash "id" a))) (gethash "journal" page) :from-end t)
                       do (loop for name in (context-wiki-targets (gethash "text" item))
                                for link = (context-table "from" (gethash "id" page) "kind" "wiki-link" "target" name "item" id)
                                do (when action (setf (gethash "date" link) (gethash "date" action)
                                                     (gethash "at" link) (gethash "at" action)))
                                   (let* ((target (context-link-target context page name end))
                                          (target-page (find target pages :key #'context-page-id :test #'equal)))
                                     (when target-page (setf (gethash "to" link) (gethash "id" target-page))))
                                   (when attribution
                                     (maphash (lambda (key value) (setf (gethash key link) value)) attribution))
                                   (push link links))))
               (loop for id across (gethash "trail-items" page #())
                     do (push (context-table "page" (gethash "id" page) "item" id
                                             "nodes" (coerce (context-wiki-targets (gethash "text" (gethash id story))) 'vector)
                                             "relation-type" (context-trail-type page story)) trails)))
      (loop for event across events for page = (context-page context (gethash "page" event))
            do (when (and (equal "fork" (gethash "operation" event))
                          (eq :true (gethash "observed-links" (context-page context (gethash "source-page" event)))))
                 (push (context-table "from" (gethash "source-page" event) "to" (gethash "page" event) "kind" "fork"
                                      "source-site" (gethash "site" (gethash "journal" event)) "date" (gethash "date" event) "at" (gethash "at" event)) forks))
               (when (and (gethash "trail-code-item" page)
                          (equal (gethash "id" (gethash "journal" event)) (gethash "trail-code-item" page)))
                 (let* ((before (gethash "text" (gethash "before" event))) (after (gethash "text" (gethash "after" event)))
                        (line (lambda (text) (find-if (lambda (s) (search "graph.addRel" s)) (uiop:split-string text :separator '(#\Newline))))))
                   (setf change (context-table "page" (gethash "page" event) "item" (gethash "trail-code-item" page)
                                               "kind" "relation-type-change" "before-line" (string-trim " " (funcall line before))
                                               "after-line" (string-trim " " (funcall line after))
                                               "before" (context-trail-type page (context-page-story-at page (1- (gethash "date" event))))
                                               "after" (context-trail-type page (context-page-story-at page (gethash "date" event)))
                                               "date" (gethash "date" event) "at" (gethash "at" event))))))
      (setf (gethash "links" observed) (coerce (nreverse links) 'vector)
            (gethash "forks" observed) (coerce (nreverse forks) 'vector)
            (gethash "trails" observed) (coerce (nreverse trails) 'vector)
            (gethash "relation-type-change" observed) change)
      data)))

(defun context-state (context through)
  "Compatibility for the discrete cursor; the authoritative operation is STATE-AT."
  (context-state-at context (if (minusp through)
                               (1- (context-milliseconds (gethash "start" (gethash "window" (context-data context)))))
                               (gethash "date" (aref (context-events context) through)))))

(defun context-delta (context &optional (event (aref (context-events context) (context-cursor context))))
  "Actual projection differences at the cursor, plus the selected content edit."
  (let* ((record (if (typep event 'federated-event) (event-record event) event))
         (before (context-state-at context (1- (gethash "date" record))))
         (after (context-state-at context (gethash "date" record)))
         (old (getf before :relations)) (new (getf after :relations))
         (changed (remove-if (lambda (r) (find r old :test #'dreyeck/work/reading::%json-equal)) new))
         (removed (remove-if (lambda (r) (find (gethash "id" r) new
                                              :key (lambda (r) (gethash "id" r)) :test #'equal)) old)))
    (list :added-topics (set-difference (getf after :topics) (getf before :topics) :test #'equal)
          :removed-topics (set-difference (getf before :topics) (getf after :topics) :test #'equal)
          :changed-relations changed :removed-relations removed
          :relation-changes (mapcar (lambda (r) (list :id (gethash "id" r)
                                                      :before (find (gethash "id" r) old :key (lambda (o) (gethash "id" o)) :test #'equal)
                                                      :after r)) changed)
          :before before :after after
          :event record)))

(defun context-current-delta (context)
  "Retain the actual Lisp result used by both the map and Inspector links."
  (or (gethash (context-cursor context) (context-deltas context))
      (setf (gethash (context-cursor context) (context-deltas context))
            (context-delta context (context-event-object context (context-cursor context))))))

(defun context-current-state (context)
  (getf (context-current-delta context) :after))

(defun context-relation-item (context relation)
  (let ((page (find (gethash "from" relation) (context-pages context)
                    :key #'context-page-id :test #'equal)))
    (when (and page (gethash "item" relation))
      (gethash (gethash "item" relation)
               (context-page-story-at page
                 (gethash "date" (aref (context-events context) (context-cursor context))))))))

(defun context-relation-topic (context relation delta)
  "An existing Relation Contract Topic represents the actual state/change value.
It labels the edge; it does not introduce another node into the domain graph."
  (dreyeck/topicmap:make-topicmap-topic
   :id (format nil "relation:~A" (gethash "id" relation)) :type :relation
   :label (if (equal "" (gethash "kind" relation)) "unnamed" (gethash "kind" relation))
   :object (if (eq :delta (context-mode context))
               (or (find (gethash "id" relation) (getf delta :relation-changes)
                         :key (lambda (change) (getf change :id)) :test #'equal)
                   relation)
               relation)
   :temporal-scope (context-event-object context (context-cursor context))))

(defun context-projection (context)
  (let* ((delta (context-current-delta context))
         (state (context-current-state context))
         (relations (if (eq :delta (context-mode context))
                        (append (getf delta :changed-relations) (getf delta :removed-relations))
                        (getf state :relations)))
         (ids (if (eq :delta (context-mode context))
                  (remove-duplicates
                   (append (getf delta :added-topics) (getf delta :removed-topics)
                           (mapcan (lambda (r) (list (gethash "from" r) (gethash "to" r))) relations))
                   :test #'equal)
                  (getf state :topics))))
    (dreyeck/topicmap:make-topicmap-projection
     :source context
     :topics
     (loop for id in ids
           for page = (find id (context-pages context) :key #'context-page-id :test #'equal)
           collect (dreyeck/topicmap:make-topicmap-topic
                    :id id :type (if page :page :subject)
                    :label (if page (context-page-label page) (subseq id (length "concept:")))
                    :object (if page (context-page-object context page)
                                (context-subject-object context (subseq id (length "concept:"))))
                    :temporal-scope (context-event-object context (context-cursor context))))
     :associations
     (loop for relation in relations
           for item = (context-relation-item context relation)
           collect (dreyeck/topicmap:make-topicmap-association
                    :id (gethash "id" relation)
                    :type (if (equal "" (gethash "kind" relation)) "unnamed" (gethash "kind" relation))
                    :from (gethash "from" relation) :to (gethash "to" relation)
                    :properties
                    (list :context context :evidence relation :item item
                          :relation-contract (context-relation-topic context relation delta)
                          :attribution (context-item-attribution item)
                          :change (find (gethash "id" relation) (getf delta :relation-changes)
                                        :key (lambda (change) (getf change :id)) :test #'equal)
                          :delta (cond ((member relation (getf delta :removed-relations) :test #'eq) :removed)
                                       ((member relation (getf delta :changed-relations) :test #'eq) :changed))))))))

(defun context-temporal-projection (context)
  "Ordered observed event objects. NEXT means order, never causal influence."
  (let ((events (context-events context)))
    (dreyeck/topicmap:make-topicmap-projection
     :source context
     :topics
     (loop for record across events for index from 0
           collect (dreyeck/topicmap:make-topicmap-topic
                    :id (gethash "id" record) :type :event
                    :label (format nil "~A~%~A~%~A"
                                   (subseq (gethash "at" record) 11)
                                   (context-page-label (context-page context (gethash "page" record)))
                                   (gethash "operation" record))
                    :object (context-event-object context index)))
     :associations
     (loop for index from 1 below (length events)
           for from = (gethash "id" (aref events (1- index)))
           for to = (gethash "id" (aref events index))
           collect (dreyeck/topicmap:make-topicmap-association
                    :id (format nil "order:~A" to) :type "next observed event"
                    :from from :to to)))))

(defmethod dreyeck/topicmap:topicmap-projection-of ((context federated-context))
  (context-projection context))

(defun context-rendering (context projection-kind)
  (let ((key (ecase projection-kind
               (:temporal :temporal)
               (:context (list (context-cursor context) (context-mode context))))))
    (or (gethash key (context-layouts context))
        (let ((projection (ecase projection-kind
                            (:temporal (context-temporal-projection context))
                            (:context (context-projection context)))))
          ;; An edit can change words without changing this projected graph.
          ;; TALA emits no SVG for empty input; do not invent a topic for it.
          (when (dreyeck/topicmap:topicmap-projection-topics-of projection)
            (setf (gethash key (context-layouts context))
                  (dreyeck/topicmap/tala:run-tala
                   (dreyeck/topicmap/tala:projection-tala-input projection))))))))

(defun context-rendered-projection (context projection-kind)
  (let ((rendering (context-rendering context projection-kind)))
    (if rendering
        (dreyeck/topicmap/tala:tala-input-projection (dreyeck/topicmap/tala:tala-rendering-input rendering))
        (context-projection context))))

(defun context-current-workspace (context)
  "One editing session; changing time/mode re-projects it without moving Point."
  (let* ((projection (context-rendered-projection context :context))
         (workspace (context-workspace context)))
    (if workspace
        (unless (eq projection (dreyeck/topicmap:topicmap-workspace-projection-of workspace))
          (dreyeck/topicmap:topicmap-workspace-reproject workspace projection))
        ;; Initial creation is explicit and strict. An absent event page is
        ;; not permission to invent a first-Topic Point or an empty session.
        (setf (context-workspace context)
              (dreyeck/topicmap:make-topicmap-workspace
               projection (context-page-id (context-page context
                            (gethash "page" (aref (context-events context) (context-cursor context))))))))
    (context-workspace context)))

(defclass context-point-action (dreyeck/inspector/topicmap::topic-action-reference)
  ((update-view :initform nil :accessor point-action-update-view)
   (operation-target :initform nil :accessor point-action-operation-target))
  (:documentation "An ordinary Workspace action with a callback for its Point
presentation and an optional rendered occurrence target for activation. The
existing Workspace owns Point; this reference owns no Point state."))

(defmethod html-inspector-views:eval-thunk :around ((action context-point-action))
  (let* ((workspace (dreyeck/inspector/topicmap::action-workspace action))
         (before (dreyeck/topicmap:topicmap-workspace-point-of workspace)))
    (call-next-method)
    (when (and (not (equal before (dreyeck/topicmap:topicmap-workspace-point-of workspace)))
               (point-action-update-view action))
      (funcall (point-action-update-view action)))
    (when (point-action-operation-target action)
      (dreyeck/inspector/topicmap:operation-inspectable-object
       (dreyeck/gesture-binding-witness:follow-operation)
       (point-action-operation-target action)))))

(defun context-point-reference (workspace topic)
  "The same non-refreshing Point operation for a sign or a relation endpoint."
  (make-instance 'context-point-action :topic topic
    :projection (dreyeck/topicmap:topicmap-workspace-projection-of workspace) :workspace workspace
    :fn (lambda ()
          (dreyeck/topicmap:topicmap-workspace-go-to workspace (dreyeck/topicmap:topicmap-topic-id-of topic))
          ;; The existing presentation callback updates Point. NIL suppresses
          ;; the ordinary Inspector action handler's full-pane refresh.
          nil)))

(defun context-map-html (context &optional (projection-kind :context))
  "Two TALA projections, coordinated by the context's one Lisp cursor."
  (unless (context-rendering context projection-kind)
    (return-from context-map-html "<p>No topic or relation changes at this event.</p>"))
  (let* ((rendering (context-rendering context projection-kind))
         (projection (context-rendered-projection context projection-kind))
         (workspace (when (eq projection-kind :context) (context-current-workspace context)))
         (delta (context-current-delta context))
         (selected (if workspace (and (dreyeck/topicmap:topicmap-workspace-point-projected-p workspace)
                                     (dreyeck/topicmap:topicmap-workspace-point-of workspace))
                       (gethash "id" (aref (context-events context) (context-cursor context)))))
         (dom (let ((plump:*tag-dispatchers* plump:*xml-tags*))
                (plump:parse
                 (dreyeck/inspector/topicmap/tala::interactive-tala-svg
                  rendering :topic-reference
                  (lambda (topic) (context-topic-primary-reference context projection-kind topic)))))))
    (dolist (group (plump:get-elements-by-tag-name dom "g"))
      (let* ((id (plump:attribute group "data-topic-id"))
             (association-id (plump:attribute group "data-association-id")))
        (when id
          (when (equal id selected)
            (setf (plump:attribute group "data-selected") "true")))
        (when (eq projection-kind :context)
          (when association-id
            (let* ((association (find association-id (dreyeck/topicmap:topicmap-projection-associations-of projection)
                                     :key #'dreyeck/topicmap:topicmap-association-id-of :test #'equal))
                   (status (getf (dreyeck/topicmap:topicmap-association-properties-of association) :delta)))
              (when status (setf (plump:attribute group "data-delta") (string-downcase (symbol-name status))))))
          (when (member id (getf delta :added-topics) :test #'equal)
            (setf (plump:attribute group "data-delta") "changed"))
          (when (member id (getf delta :removed-topics) :test #'equal)
            (setf (plump:attribute group "data-delta") "removed")))))
    ;; Keep TALA's natural dimensions inside a scrollable viewport. Stretching
    ;; the event chain to pane width makes it several screens tall; shrinking
    ;; the context graph to that width makes its page labels unreadable.
    (let* ((outer (first (plump:get-elements-by-tag-name dom "svg")))
           (inner (second (plump:get-elements-by-tag-name dom "svg"))))
      (setf (plump:attribute outer "style")
            (format nil "width:~Apx;height:~Apx;max-width:none"
                    (plump:attribute inner "width") (plump:attribute inner "height"))))
    (plump:serialize dom nil)))

(defun render-context-point (context)
  (let ((workspace (context-current-workspace context)))
    (unless (dreyeck/topicmap:topicmap-workspace-point-projected-p workspace)
      (return-from render-context-point
        (html-inspector-views:html
          (:p "Workspace Point: " (html-inspector-views:esc (dreyeck/topicmap:topicmap-workspace-point-of workspace)))
          (:p "Not present in current projection"))))
    (let* ((topic (dreyeck/topicmap:topicmap-workspace-current-topic workspace))
           (object (dreyeck/topicmap:topicmap-workspace-current-object workspace))
           (projection (dreyeck/topicmap:topicmap-workspace-projection-of workspace)))
      (html-inspector-views:html
        (:p "Workspace Point: " (html-inspector-views:esc (dreyeck/topicmap:topicmap-topic-label-of topic)))
        (:p (html-inspector-views:eval-button "Follow"
              (html-inspector-views:thunk
                (follow-context-object (dreyeck/topicmap:topicmap-workspace-current-object workspace))))
            " · " (html-inspector-views:object-ref object :display "Inspect represented object")
            " · " (html-inspector-views:object-ref topic :display "Inspect Topicmap sign"))
        (:p "Relations at Point:")
        (:table :class "inspector-table"
            (dolist (association (dreyeck/topicmap::topicmap-associations-of-point workspace))
              (let* ((direction (dreyeck/topicmap::topicmap-association-direction-at-point workspace association))
                     (other-id (dreyeck/topicmap::topicmap-association-other-topic-id workspace association))
                     (other (dreyeck/topicmap::topicmap-projection-topic-by-id projection other-id)))
                (html-inspector-views:html
                  (:tr :data-point-relation (dreyeck/topicmap:topicmap-association-id-of association)
                   (:td (html-inspector-views:object-ref association :display
                          (or (dreyeck/topicmap:topicmap-association-relation-label association)
                              (dreyeck/topicmap:topicmap-association-type-of association))))
                   (:td (html-inspector-views:esc (if (eq direction :outgoing) "→" "←")))
                   (:td (html-inspector-views:action-button (dreyeck/topicmap:topicmap-topic-label-of other)
                          (context-point-reference workspace other))))))))))))

(defun context-point-view (context)
  (html-inspector-views:html-view (render-context-point context)))

(defun bind-context-point-actions (view update-view &optional occurrences)
  "Bind local Point updates; EVAL sign activations reuse their existing occurrence target."
  (html-inspector-views:view-html view)
  (dolist (reference (html-inspector-views:view-references view))
    (when (typep (cdr reference) 'context-point-action)
      (setf (point-action-update-view (cdr reference)) update-view)
      (when (uiop:string-prefix-p "eval-" (car reference))
        (let ((occurrence (find (cdr reference) occurrences
                                :key #'dreyeck/inspector/topicmap:occurrence-reference :test #'eq)))
          (when occurrence
            (setf (point-action-operation-target (cdr reference))
                  (list :type :workspace-action-sign-occurrence :occurrence occurrence)))))))
  view)

(defun render-context-inspection (context)
  "Per-sign inspection remains available without moving Workspace Point."
  (let ((projection (context-rendered-projection context :context)))
    (html-inspector-views:html
      (:details
       (:summary "Inspect context signs and represented objects")
       (:table :class "inspector-table"
        (dolist (topic (dreyeck/topicmap:topicmap-projection-topics-of projection))
          (html-inspector-views:html
            (:tr :data-inspection-topic (dreyeck/topicmap:topicmap-topic-id-of topic)
             (:td (html-inspector-views:esc (dreyeck/topicmap:topicmap-topic-label-of topic)))
             (:td (html-inspector-views:object-ref
                   (dreyeck/topicmap:topicmap-topic-object-of topic) :display "Inspect represented object"))
             (:td (html-inspector-views:object-ref topic :display "Inspect Topicmap sign"))))))))))

(defun render-context-changes (context)
  (let ((delta (context-current-delta context)))
    (html-inspector-views:html
      (:p (html-inspector-views:esc
           (format nil "~D topic additions · ~D topic removals · ~D changed relations · ~D removed relations"
                   (length (getf delta :added-topics)) (length (getf delta :removed-topics))
                   (length (getf delta :changed-relations)) (length (getf delta :removed-relations)))))
      (:table :class "inspector-table"
       (dolist (change (getf delta :relation-changes))
         (let ((before (getf change :before)) (after (getf change :after)))
           (html-inspector-views:html
             (:tr :data-relation-change (getf change :id)
              (:td (html-inspector-views:object-ref change :display (getf change :id)))
              (:td (html-inspector-views:esc (gethash "from" after)))
              (:td (html-inspector-views:esc (gethash "to" after)))
              (:td (html-inspector-views:esc
                    (if before (format nil "~S → ~S" (gethash "kind" before) (gethash "kind" after))
                        (format nil "added ~S" (gethash "kind" after)))))))))))))

(html-inspector-views:defview dreyeck/inspector/topicmap::👀topicmap (context federated-context)
  (html-inspector-views:html-view :title "Topicmap" :priority 0
    (let* ((event (aref (context-events context) (context-cursor context)))
           (page (context-page context (gethash "page" event)))
           (item (gethash "after" event)))
      (html-inspector-views:html
        (:style "[data-projection]{overflow:auto;max-height:26rem;border:1px solid #ddd}[data-projection='temporal']{max-height:18rem}[data-projection='context'] [data-delta='changed'] path,[data-projection='context'] [data-delta='changed'] rect{stroke:#b45309!important;stroke-width:3px!important}[data-projection='context'] [data-delta='removed']{opacity:.45}[data-projection] [data-selected='true'] rect{stroke:#2563eb!important;stroke-width:4px!important}")
        (:p "How did this federated context change during October 1?")
        (:p (html-inspector-views:action-button "Previous event" (html-inspector-views:thunk
                                                                 (select-context-event context (1- (context-cursor context)))))
            " " (html-inspector-views:esc (gethash "at" event)) " "
            (html-inspector-views:action-button "Next event" (html-inspector-views:thunk
                                                             (select-context-event context (1+ (context-cursor context)))))
            " · " (html-inspector-views:esc (format nil "Event ~D of ~D" (1+ (context-cursor context))
                                                    (length (context-events context)))))
        (:p (html-inspector-views:esc (format nil "~A / ~A · ~A" (gethash "site" page)
                                             (gethash "title" page) (gethash "operation" event)))
            " · " (html-inspector-views:object-ref (context-event-object context (context-cursor context))
                                                  :display "Inspect selected event evidence"))
        (:h3 "Temporal · 2026-10-01 UTC")
        (:div :id (symbol-name (gensym "temporal-map-")) :data-projection "temporal"
              (html-inspector-views:str (context-map-html context :temporal)))
        (:h3 "Federated context")
        (:p (dolist (mode '(:state :delta))
              (let ((choice mode))
                (html-inspector-views:action-button (string-capitalize (symbol-name choice))
                  (html-inspector-views:thunk (setf (context-mode context) choice) t))
                (html-inspector-views:str " ")))
            " · " (html-inspector-views:esc (symbol-name (context-mode context)))
            " · " (html-inspector-views:object-ref (context-current-state context) :display "Inspect current State")
            " · " (html-inspector-views:object-ref (context-current-delta context) :display "Inspect current Delta"))
        (:p "Select an event to move the cursor. Click a context sign to move Workspace Point and follow its wiki material; a subject with several candidates offers a choice. Relation endpoints move Point along the graph. Secondary Topic gestures invoke operations without moving Point. Point and the table below provide separate object and sign inspection. Orange relations mark the selected event's changes; faded topics are removed.")
        (:div :id (symbol-name (gensym "context-map-")) :data-projection "context"
              (html-inspector-views:str (context-map-html context)))
        ;; Keep the surrounding layout stable as Point's relation count changes.
        ;; Only this bounded panel's contents are replaced during graph navigation.
        (:div :id (symbol-name (gensym "workspace-point-")) :data-workspace-point "true"
              :style "height:16rem;overflow:auto"
              (render-context-point context))
        (render-context-inspection context)
        (when (eq :delta (context-mode context)) (render-context-changes context))
        (let ((attribution (context-item-attribution item)))
          (when attribution
            (html-inspector-views:html
              (:p "Textual attribution: " (html-inspector-views:esc (gethash "text" item)) " · "
                  (html-inspector-views:object-ref item :display "Inspect attribution item")
                  " · credited page: " (render-context-page-link
                                        (context-page context (gethash "credited-page" attribution)))))))
        (:p "Observed: page contents, links, forks, journal times and Ward's trail nodes. Derived: temporal ordering and shared concepts.")
        (:p "Not established: " (html-inspector-views:esc (gethash "not-established" (context-data context))))))))

(defun context-map-scroll-offsets (viewport)
  "Presentation coordinates from TALA's SVG, never event/time semantics."
  (let* ((selected (find "true" (plump:get-elements-by-tag-name viewport "g")
                         :key (lambda (g) (plump:attribute g "data-selected")) :test #'equal))
         (rect (and selected (first (plump:get-elements-by-tag-name selected "rect"))))
         (inner (second (plump:get-elements-by-tag-name viewport "svg"))))
    (when (and rect inner)
      (let ((origin (uiop:split-string (plump:attribute inner "viewBox"))))
        (flet ((coordinate (text) (shasht:read-json text)))
          (values (max 0 (round (- (coordinate (plump:attribute rect "x"))
                                  (coordinate (first origin)) 72)))
                  (max 0 (round (- (coordinate (plump:attribute rect "y"))
                                  (coordinate (second origin)) 72)))))))))

(defun update-context-point-view (pane parent point viewport context workspace)
  "Update Point presentation without rebuilding the pane or either map."
  (clog-moldable-inspector::create-view-element
   pane (clog:attach-as-child parent (plump:attribute point "id"))
   (bind-context-point-actions
    (context-point-view context)
    (lambda () (update-context-point-view pane parent point viewport context workspace))))
  (dolist (sign (plump:get-elements-by-tag-name viewport "g"))
    (when (plump:attribute sign "data-topic-id")
      (setf (clog:attribute (clog:attach-as-child parent (plump:attribute sign "id")) "data-selected")
            (if (equal (plump:attribute sign "data-topic-id")
                       (dreyeck/topicmap:topicmap-workspace-point-of workspace))
                "true" "false")))))

(defmethod clog-moldable-inspector::create-view-element :after
    ((pane clog-moldable-inspector::pane) parent (view html-inspector-views:html-view))
  ;; CLOG retains the two bounded viewports around their selected signs after
  ;; a refresh. No browser cursor, event ordering or graph state is introduced.
  (when (find-if (lambda (ref) (typep (cdr ref) 'federated-event))
                (html-inspector-views:view-references view))
    (let* ((plump:*tag-dispatchers* plump:*xml-tags*)
           (dom (plump:parse (html-inspector-views:view-html view))))
      (dolist (viewport (plump:get-elements-by-tag-name dom "div"))
        (when (plump:attribute viewport "data-projection")
          (multiple-value-bind (x y) (context-map-scroll-offsets viewport)
            (when x
              (let ((element (clog:attach-as-child parent (plump:attribute viewport "id"))))
                (setf (clog:scroll-left element) x (clog:scroll-top element) y))))))
      (let* ((point (find "true" (plump:get-elements-by-tag-name dom "div")
                          :key (lambda (e) (plump:attribute e "data-workspace-point")) :test #'equal))
             (viewport (find "context" (plump:get-elements-by-tag-name dom "div")
                             :key (lambda (e) (plump:attribute e "data-projection")) :test #'equal)))
        (when point
          (let ((context (html-inspector-views:view-object view)))
            (bind-context-point-actions
             view (lambda ()
                    (update-context-point-view pane parent point viewport context
                                               (context-current-workspace context)))
             (dreyeck/inspector/topicmap:open-workspace-action-sign-occurrences))))))))

(html-inspector-views:defview federated-relation-evidence (association dreyeck/topicmap:topicmap-association)
  (let* ((properties (dreyeck/topicmap:topicmap-association-properties-of association))
         (context (getf properties :context)))
    (when (typep context 'federated-context)
      (html-inspector-views:html-view :title "Evidence" :priority 0
        (let ((relation (getf properties :evidence)) (change (getf properties :change))
              (item (getf properties :item)) (attribution (getf properties :attribution)))
          (html-inspector-views:html
            (:p (html-inspector-views:esc (gethash "kind" relation)) " · "
                (html-inspector-views:object-ref relation :display "Inspect selected relation"))
            (:p (html-inspector-views:object-ref
                 (dreyeck/topicmap:topicmap-topic-object-of (getf properties :relation-contract))
                 :display "Inspect represented object"))
            (:p (html-inspector-views:esc (gethash "id" relation)))
            (:p (html-inspector-views:esc (gethash "from" relation)) " → "
                (html-inspector-views:esc (gethash "to" relation)))
            (when change
              (html-inspector-views:html
                (:p (html-inspector-views:object-ref change :display "Inspect relation change"))
                (:p "Before: " (html-inspector-views:object-ref (getf change :before)))
                (:p "After: " (html-inspector-views:object-ref (getf change :after)))))
            (when item
              (html-inspector-views:html
                (:p (html-inspector-views:object-ref item :display "Inspect source item"))
                (:p (html-inspector-views:esc (gethash "text" item "")))))
            (when attribution
              (html-inspector-views:html
                (:p "Textual attribution: " (html-inspector-views:esc (gethash "attribution" attribution))
                    " · " (html-inspector-views:object-ref attribution :display "Inspect observed attribution")
                    " · " (render-context-page-link (context-page context (gethash "credited-page" attribution))))))
            (dolist (id (list (gethash "from" relation) (gethash "to" relation)))
              (let ((page (find id (context-pages context) :key #'context-page-id :test #'equal)))
                (when page (html-inspector-views:html (:p "Wiki page: " (render-context-page-link page))))))))))))

(html-inspector-views:defview federated-event-evidence (event federated-event)
  (html-inspector-views:html-view :title "Evidence" :priority 0
    (let* ((record (event-record event)) (context (event-context event))
           (page (context-page context (gethash "page" record))))
      (html-inspector-views:html
        (:p (html-inspector-views:esc (gethash "at" record)) " · "
            (html-inspector-views:esc (gethash "operation" record)) " · " (render-context-page-link page))
        (when (gethash "source-page" record)
          (html-inspector-views:html (:p "Fork source: " (render-context-page-link
                                                         (context-page context (gethash "source-page" record)))
                                       "; existing source history is inherited at this event, not replayed as edits by the receiving site.")))
        (:p (html-inspector-views:object-ref record :display "Inspect journal identity and before/after evidence"))
        (:p "Before: " (html-inspector-views:object-ref (gethash "before" record)))
        (:p "After: " (html-inspector-views:object-ref (gethash "after" record)))
        (when (gethash "older-content" record)
          (html-inspector-views:html (:p (html-inspector-views:object-ref (gethash "older-content" record)
                                                                       :display "Inspect the older Memex trail discussion"))))))))

(html-inspector-views:defview federated-context-observations (context federated-context)
  (html-inspector-views:html-view :title "Observed / Derived" :priority 1
    (html-inspector-views:html
      (:p (html-inspector-views:object-ref (gethash "observed" (context-data context)) :display "Observed page/link/fork/trail graph"))
      (:p (html-inspector-views:object-ref (gethash "derived" (context-data context)) :display "Derived ordering and shared concepts"))
      (:p (html-inspector-views:esc (gethash "falsifiable-claim" (context-data context))))
      (:p "Falsified by: " (html-inspector-views:esc (gethash "falsified-by" (context-data context)))))))

(defmethod html-inspector-views:title-bar-action-buttons ((page context-fedwiki-page))
  ;; Reloading would silently replace the historical object with a live page.
  nil)

(defmethod hyperbook/fedwiki::👀context ((page context-fedwiki-page))
  ;; Retain the native Context view without fetching live site-owner metadata.
  (html-inspector-views:list-view (hyperbook/fedwiki::context-of page)
                                :title "Context" :priority 4 :display #'hyperbook:id-of))

(html-inspector-views:defview historical-page-evidence (page context-fedwiki-page)
  (html-inspector-views:html-view :title "Source / Time" :priority 3
    (html-inspector-views:html
      (:p (html-inspector-views:esc (context-page-label (page-evidence page))))
      (:p "Source site: " (html-inspector-views:object-ref (hyperbook:hyperbook-of page)))
      (:p "Source slug: " (html-inspector-views:esc (hyperbook:id-of page)))
      (:p "State at: " (html-inspector-views:esc (gethash "at" (event-record (page-event page))))
          " · " (html-inspector-views:object-ref (page-event page) :display "Inspect source event"))
      (:p (html-inspector-views:object-ref (page-json page) :display "Inspect historical page JSON"))
      (:p (html-inspector-views:object-ref (gethash "raw" (page-evidence page)) :display "Inspect saved source evidence"))
      (:p "Native page: " (render-context-page-link (page-evidence page))))))

(defmethod html-inspector-views:text-representation ((subject federated-subject))
  (subject-title subject))

(html-inspector-views:defview federated-subject-resolution (subject federated-subject)
  (html-inspector-views:html-view :title "Subject" :priority 0
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc (subject-title subject)))
      (:p "Context: " (html-inspector-views:object-ref (subject-context subject)))
      (:p "State at: " (html-inspector-views:esc (gethash "at" (event-record (subject-event subject))))
          " · " (html-inspector-views:object-ref (subject-event subject)))
      (when (subject-resolution subject)
        (html-inspector-views:html
          (:h3 "Choose wiki working material")
          (:p "Candidates retain their source sites. Following a candidate leaves the temporal cursor unchanged.")
          (dolist (page (getf (subject-resolution subject) :pages))
            (html-inspector-views:html
              (:p (html-inspector-views:object-ref
                   page :display (format nil "~A / ~A"
                                         (hyperbook:id-of (hyperbook/fedwiki::origin-of page))
                                         (hyperbook:title-of page))))))
          (unless (getf (subject-resolution subject) :pages)
            (html-inspector-views:html (:p "No concrete page candidate was resolved.")))
          (dolist (failure (getf (subject-resolution subject) :failures))
            (html-inspector-views:html
              (:p "Resolution incomplete for "
                  (html-inspector-views:object-ref (car failure)) " · "
                  (html-inspector-views:object-ref (cdr failure)))))))
      (:p "Unresolved collaborative links: "
          (dolist (link (subject-links subject))
            (html-inspector-views:object-ref link :display
              (format nil "~A / ~A" (hyperbook::source-hyperbook-of link) (hyperbook::source-page-of link)))
            (html-inspector-views:str " ")))
      (:p "Recorded page candidates at this event:")
      (let ((pages (subject-context-pages subject)))
        (if pages
            (dolist (page pages)
              (html-inspector-views:html (:p (html-inspector-views:object-ref page :display
                                               (context-page-label (page-evidence page)))
                                            " · " (render-context-page-link (page-evidence page)))))
            (html-inspector-views:html (:p "No concrete page with this title in the saved context evidence."))))
      (:p "Cached neighborhood candidates (historical content not captured):")
      (dolist (page (subject-neighborhood-pages subject))
        (html-inspector-views:html
          (:p (html-inspector-views:object-ref page :display
                (format nil "~A / ~A" (hyperbook:id-of (hyperbook:hyperbook-of page)) (hyperbook:title-of page)))))))))

(hyperdoc:see (hyperdoc:page "Trails Rendered public reproduction"))
(hyperdoc:defexample federated-context
  "One Lisp cursor coordinates ordered events and the State/Delta context Topicmap.
Forks import inherited content at their own time. Temporal selection, wiki
following and explicit sign/object inspection are separate operations."
  (let ((data (read-federated-context)))
    (make-instance 'federated-context :data data
                   :cursor (1- (length (gethash "events" (gethash "temporal" data)))))))
