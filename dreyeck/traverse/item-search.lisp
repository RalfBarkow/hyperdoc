;;;; Searching Retained Pages for an Item Id

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "Federated Search Without a Central Index" :hyperbook "dreyeck/traverse/reading"))

;;; Three searches already exist around Federated Wiki: the client's neighborhood search, the Search
;;; plugin, and Ward's search service, which the plugin asks by default. Their sources are retained
;;; below at fixed revisions. Beside them, this file searches the Wiki pages this companion has
;;; retained for one story item id, with the rule Ward's crawler uses (alias, else id), and keeps apart
;;; what the search was asked, where it looked, and which story items it observed. Nothing is fetched:
;;; the search space is exactly the retained pages, chosen explicitly, and it discovers no site.

;;; The retained sources of the three searches

(defclass search-reading ()
  ((manifest :initarg :manifest :reader search-manifest)
   (revisions :initarg :revisions :reader search-revisions)
   (sources :initform nil :accessor search-sources))
  (:documentation "Sources of the neighborhood search, the Search plugin and Ward's search service, at fixed revisions."))

(defun search-path (name) (evidence-path (concatenate 'string "search/" name)))

(defun load-search-reading ()
  (let* ((manifest (read-json "search/sources.json"))
         (revisions (loop for repo being the hash-keys of (gethash "revisions" manifest) using (hash-value entry)
                          collect (cons repo (git:make-git-revision-reference
                                              :authority (gethash "authority" entry) :oid (gethash "oid" entry)
                                              :role (intern (string-upcase repo) :keyword)
                                              :web-url (format nil "~A/commit/~A" (gethash "authority" entry)
                                                               (gethash "oid" entry))))))
         (reading (make-instance 'search-reading :manifest manifest :revisions revisions)))
    (loop for entry across (gethash "files" manifest)
          do (unless (equal (file-digest (search-path (gethash "file" entry))) (gethash "sha256" entry))
               (error "Retained search source differs from its recorded SHA-256: ~A" (gethash "file" entry))))
    (setf (search-sources reading)
          (loop for metadata across (gethash "excerpts" manifest)
                for text = (uiop:read-file-string (search-path (gethash "file" metadata)) :external-format :utf-8)
                for excerpt = (subseq text (gethash "start" metadata) (gethash "end" metadata))
                for revision = (cdr (assoc (gethash "repo" metadata) revisions :test #'equal))
                for file = (git:ensure-git-evidence-file revision (gethash "path" metadata))
                for key = (gethash "key" metadata)
                do (unless (equal (text-digest excerpt) (gethash "sha256" metadata))
                     (error "Definition excerpt differs from its coordinates: ~A" key))
                collect (let ((source (make-instance 'traverse-source
                                                     :reading reading :metadata metadata
                                                     :file (search-path (gethash "file" metadata))
                                                     :text excerpt :definition (subseq key (1+ (position #\: key)))
                                                     :revision revision :revision-file file)))
                          (git:add-git-evidence-location file source)
                          source)))
    reading))

(defvar *search-reading* nil)

(hyperdoc:defexample search-sources-reading
  "The retained sources of the three searches, checked against their SHA-256 on load; nothing is fetched."
  (or *search-reading* (setf *search-reading* (load-search-reading))))

(defun search-source (key)
  (or (find key (search-sources (search-sources-reading)) :key #'source-key :test #'equal)
      (error "No retained search source ~S" key)))

;;; The search space: the retained pages, by site, chosen explicitly

(defclass searched-site ()
  ((domain :initarg :domain :reader site-domain)
   (pages :initarg :pages :reader site-pages)
   (sitemap-slugs :initarg :sitemap-slugs :reader site-sitemap-slugs
                  :documentation "Slugs of the site's retained sitemap, or NIL when no sitemap is retained."))
  (:documentation "One site of the search space, with the retained pages a search reads."))

(defun site-complete-p (site)
  "Every page of the site's retained sitemap is retained, so the space holds the whole site as of that sitemap."
  (and (site-sitemap-slugs site)
       (every (lambda (slug) (find slug (site-pages site) :key #'page-slug :test #'equal))
              (site-sitemap-slugs site))))

(defvar *search-space* nil)

(hyperdoc:defexample retained-search-space
  "The sites whose retained pages make up the search space: discourse.dreyeck.ch, ward.dojo.fed.wiki, found.ward.fed.wiki."
  (or *search-space*
      (setf *search-space*
            (let ((pages (append (snapshot-pages (experiment-snapshot)) (list (curiosity-token-page))))
                  (sitemap (map 'list (lambda (info) (gethash "slug" info)) (read-json "discourse/sitemap.json"))))
              (loop for domain in (remove-duplicates (mapcar #'page-site pages) :test #'equal :from-end t)
                    collect (make-instance 'searched-site
                                           :domain domain
                                           :pages (remove-if-not (lambda (page) (equal domain (page-site page))) pages)
                                           :sitemap-slugs (and (equal domain "discourse.dreyeck.ch") sitemap)))))))

;;; One search: what was asked, where it looked, what it observed

(defclass item-search-query ()
  ((item-id :initarg :item-id :reader query-item-id)
   (space :initarg :space :reader query-space))
  (:documentation "Search for a story item id within an explicitly chosen search space."))

(defclass item-search-execution ()
  ((query :initarg :query :reader execution-query)
   (examined :initarg :examined :reader execution-examined :documentation "(site pages items) per searched site.")
   (occurrences :initarg :occurrences :reader execution-occurrences
                :documentation "(item . :id or :alias) for each story item observed with the id."))
  (:documentation "A local execution over retained bytes: every page of the space read, no request made."))

(defun item-index-key (item)
  "The value Ward's crawler indexes for an item: its alias, else its id."
  (or (gethash "alias" (item-json item)) (item-id item)))

(defun search-item-id (item-id &optional (space (retained-search-space)))
  (let ((query (make-instance 'item-search-query :item-id item-id :space space)))
    (make-instance 'item-search-execution
                   :query query
                   :examined (loop for site in space
                                   collect (list site (length (site-pages site))
                                                 (reduce #'+ (site-pages site) :key (lambda (page) (length (page-items page))))))
                   :occurrences (loop for site in space
                                      append (loop for page in (site-pages site)
                                                   append (loop for item in (page-items page)
                                                                when (equal item-id (item-index-key item))
                                                                  collect (cons item (if (gethash "alias" (item-json item)) :alias :id))))))))

(defun occurrence-sites (execution)
  (remove-duplicates (mapcar (lambda (occurrence) (page-site (item-page (car occurrence)))) (execution-occurrences execution))
                     :test #'equal :from-end t))

(defvar *searches* (make-hash-table :test 'equal))

(defun recorded-search (item-id)
  "The same execution object for the same id in one image, so that topics and examples agree."
  (or (gethash item-id *searches*) (setf (gethash item-id *searches*) (search-item-id item-id))))

(hyperdoc:defexample curiosity-token-search
  "SEARCH ITEMS cf80b0444c62866e, run over the retained pages: one occurrence, on the one retained page of found.ward.fed.wiki."
  (recorded-search "cf80b0444c62866e"))

(hyperdoc:defexample forked-item-search
  "Ward's sentence 31bd93ad173f651c: the same item id on two sites, carried by a fork."
  (recorded-search "31bd93ad173f651c"))

(hyperdoc:defexample template-item-search
  "The Claim Template's fold claim, 29c28902048db774: one item id on many pages of one site."
  (recorded-search "29c28902048db774"))

;;; Discovery: which further sites the retained pages name, by the crawler's own rule

(defun roster-domains (text)
  "Lines of a roster that are a bare domain, as scrape.rb reads them: dotted name, optional port."
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        when (and (find #\. line)
                  (every (lambda (c) (or (alphanumericp c) (member c '(#\. #\- #\:)))) line)
                  (not (search ".." line))
                  (alphanumericp (char line 0)) (alphanumericp (char line (1- (length line)))))
          collect (string-downcase line)))

(defun named-sites (page)
  "Sites PAGE names, by the crawler's 'sites' rule: an item's site, a roster's domains, a journal entry's site."
  (remove-duplicates
   (append (loop for item in (page-items page)
                 for site = (gethash "site" (item-json item))
                 when (stringp site) collect (string-downcase site)
                 when (equal "roster" (item-type item)) append (roster-domains (item-text item)))
           (loop for entry in (page-steps page)
                 for site = (step-site entry)
                 when (stringp site) collect (string-downcase site)))
   :test #'equal :from-end t))

(defun excluded-by-found-p (site)
  "found.rb does not add localhost, .local, localtest.me, a path, 192.168.* or 127.0.*."
  (or (search "localhost" site) (search ".local" site) (search "localtest.me" site) (find #\/ site)
      (eql 0 (search "192.168" site)) (eql 0 (search "127.0" site))))

(defclass discovery-candidate ()
  ((domain :initarg :domain :reader candidate-domain)
   (named-by :initarg :named-by :reader candidate-named-by :documentation "Retained pages that name the site."))
  (:documentation "A site the retained pages name but the search space does not hold."))

(defvar *candidates* nil)

(hyperdoc:defexample discovery-candidates
  "Sites named by the retained pages, outside the search space, that found.rb would add; none is fetched."
  (or *candidates*
      (setf *candidates*
            (let ((space (retained-search-space)) (table (make-hash-table :test 'equal)))
              (dolist (site space)
                (dolist (page (site-pages site))
                  (dolist (named (named-sites page))
                    (unless (or (excluded-by-found-p named) (find named space :key #'site-domain :test #'equal))
                      (pushnew page (gethash named table))))))
              (sort (loop for domain being the hash-keys of table using (hash-value pages)
                          collect (make-instance 'discovery-candidate :domain domain :named-by (reverse pages)))
                    (lambda (a b) (or (> (length (candidate-named-by a)) (length (candidate-named-by b)))
                                      (and (= (length (candidate-named-by a)) (length (candidate-named-by b)))
                                           (string< (candidate-domain a) (candidate-domain b))))))))))

;;; The search as a Topicmap. Page and item topics carry the ids WIKI-PAGE-PROJECTION gives them, so a
;;; Workspace can be reprojected onto the page of an occurrence and keep its Point.

(defparameter +search-origins+ '(:story :query :execution :derived :not-recorded)
  "Where an association of a search projection comes from. :query — what was asked; :execution — what
the local execution did and observed; :story — a page holds an item; :derived — read by this projection,
such as two occurrences sharing an id across sites; :not-recorded — an answer the reading does not have.")

(defvar *index-answers* (make-hash-table :test 'equal))

(defun index-answer (execution)
  (let ((id (query-item-id (execution-query execution))))
    (or (gethash id *index-answers*)
        (setf (gethash id *index-answers*)
              (make-instance 'open-statement
                             :statement (format nil "The answer of query.search.federatedwiki.org to ITEMS ~A." id)
                             :status :not-recorded
                             :basis "The Search plugin would POST this query to the search service's /match. No answer is recorded here, so whether the index knows more or fewer occurrences, or stale ones, is open."
                             :evidence (search-source "plugin:search"))))))

(defun search-topic-ids (execution)
  (let ((id (query-item-id (execution-query execution))))
    (values (format nil "query:items/~A" id) (format nil "execution:items/~A" id) (format nil "index-answer:items/~A" id))))

(defun item-search-projection (execution)
  (multiple-value-bind (query-id execution-id answer-id) (search-topic-ids execution)
    (let* ((query (execution-query execution))
           (occurrences (execution-occurrences execution))
           (pages (remove-duplicates (mapcar (lambda (occurrence) (item-page (car occurrence))) occurrences) :from-end t))
           (site-id (lambda (site) (format nil "site:~A" (site-domain site))))
           (first-by-site (loop for domain in (occurrence-sites execution)
                                collect (car (find domain occurrences :key (lambda (o) (page-site (item-page (car o)))) :test #'equal))))
           (topics
             (append
              (list (list query-id (topic-label "query: ITEMS ~A" (query-item-id query)) query :query)
                    (list execution-id (topic-label "local execution: ~D occurrences" (length occurrences)) execution :execution)
                    (list answer-id "central index answer (not recorded)" (index-answer execution) :not-recorded)
                    (list "src:item-rule" "crawler rule: alias, else id" (search-source "crawler:items") :derived)
                    (list "src:match" "search service /match" (search-source "service:match") :derived))
              (loop for site in (query-space query)
                    collect (list (funcall site-id site) (topic-label "site ~A (~D pages)" (site-domain site) (length (site-pages site)))
                                  site :execution))
              (loop for page in pages
                    collect (list (page-topic-id page) (topic-label "page ~A" (page-title page)) page :story))
              (loop for occurrence in occurrences
                    for item = (car occurrence)
                    collect (list (item-topic-id item)
                                  (topic-label "~A/~A ~A ~A" (page-site (item-page item)) (page-slug (item-page item))
                                               (item-type item) (item-text item))
                                  item :execution))))
           (relations
             (append
              (list (list query-id execution-id "executed as" :execution "run over the retained pages of the space" execution)
                    (list query-id answer-id "would be answered by" :not-recorded "the Search plugin posts to /match by default" (search-source "plugin:search"))
                    (list "src:item-rule" execution-id "matching rule of" :derived "an item matches when its alias, else its id, equals the query" (search-source "crawler:items"))
                    (list "src:match" answer-id "would compute" :derived "pages whose items.txt holds the query" (search-source "service:match")))
              (loop for (site pages-read items-read) in (execution-examined execution)
                    collect (list execution-id (funcall site-id site) "examined" :execution
                                  (format nil "~D retained pages, ~D story items~:[; part of the site~;; the whole site as of its retained sitemap~]"
                                          pages-read items-read (site-complete-p site))
                                  execution))
              (loop for page in pages
                    for site = (find (page-site page) (query-space query) :key #'site-domain :test #'equal)
                    collect (list (funcall site-id site) (page-topic-id page) "holds" :story "a retained page of the site" page))
              (loop for (item . matched-by) in occurrences
                    collect (list (page-topic-id (item-page item)) (item-topic-id item) "contains" :story
                                  (format nil "story item ~D of the page" (1+ (item-index item))) (item-page item))
                    collect (list execution-id (item-topic-id item) "observed" :execution
                                  (format nil "the item's ~(~A~) equals the query, in the retained story" matched-by) execution))
              (loop for (item next) on first-by-site while next
                    collect (list (item-topic-id item) (item-topic-id next) "same item id on another site" :derived
                                  (format nil "both items have the id ~A" (query-item-id query)) execution)))))
      (let ((+statuses+ +search-origins+))
        (projection execution topics relations)))))

(defun item-search-workspace (execution)
  "A Workspace on the search projection, Point on the first occurrence, else on the query."
  (multiple-value-bind (query-id) (search-topic-ids execution)
    (tm:make-topicmap-workspace (item-search-projection execution)
                                (let ((first (car (first (execution-occurrences execution)))))
                                  (if first (item-topic-id first) query-id)))))

(defun reproject-on-page (workspace page)
  "Reproject WORKSPACE onto the projection of PAGE; a Point on one of its items stays where it is."
  (tm:topicmap-workspace-reproject workspace (wiki-page-projection page))
  workspace)

(hyperdoc:defexample item-search-topicmap
  "The search for Ward's sentence as a Topicmap: query, local execution, the two sites, both occurrences."
  (item-search-workspace (forked-item-search)))

;;; Views

(defmethod v:text-representation ((reading search-reading)) "Sources of three Federated Wiki searches")
(defmethod v:text-representation ((site searched-site))
  (format nil "~A: ~D retained pages" (site-domain site) (length (site-pages site))))
(defmethod v:text-representation ((query item-search-query)) (format nil "ITEMS ~A" (query-item-id query)))
(defmethod v:text-representation ((execution item-search-execution))
  (format nil "ITEMS ~A: ~D occurrences on ~D sites" (query-item-id (execution-query execution))
          (length (execution-occurrences execution)) (length (occurrence-sites execution))))
(defmethod v:text-representation ((candidate discovery-candidate))
  (format nil "~A, named by ~D retained pages" (candidate-domain candidate) (length (candidate-named-by candidate))))

(defun search-links ()
  (v:html
    (:p "Reading: "
        (v:object-ref (companion-page "Federated Search Without a Central Index") :select "Content"
                      :display "Federated Search Without a Central Index"))))

(v:defview item-search-execution-view (execution item-search-execution)
  (v:html-view :title "Search" :priority 0
    (let ((query (execution-query execution)))
      (v:html
        (:h3 (cl-who:esc (format nil "ITEMS ~A" (query-item-id query))))
        (:p "Executed here, over retained bytes; no request was made. An item matches when its alias, else its id, equals the query, as "
            (v:object-ref (search-source "crawler:items") :select "Source definition" :display "Ward's crawler indexes it") ".")
        (:h4 "Search space, chosen explicitly")
        (:ul (dolist (examined (execution-examined execution))
               (destructuring-bind (site pages items) examined
                 (v:html (:li (v:object-ref site :select "Searched site" :display (site-domain site))
                              (cl-who:esc (format nil ": ~D pages, ~D story items read; ~:[part of the site~;the whole site as of its retained sitemap~]"
                                                  pages items (site-complete-p site))))))))
        (:h4 "Observed occurrences")
        (:ol (dolist (occurrence (execution-occurrences execution))
               (let ((item (car occurrence)))
                 (v:html (:li (v:object-ref item :select "Story item"
                                            :display (format nil "~A/~A #~A [~A]" (page-site (item-page item)) (page-slug (item-page item))
                                                             (item-id item) (item-type item)))
                              (cl-who:esc (format nil " matched by ~(~A~)" (cdr occurrence))))))))
        (:p "The central index's answer to this query is not recorded: "
            (v:object-ref (index-answer execution) :select "Open statement" :display "open"))
        (search-links)))))

(v:defview searched-site-view (site searched-site)
  (v:html-view :title "Searched site" :priority 0
    (v:html
      (:h3 (cl-who:esc (site-domain site)))
      (:p (cl-who:esc (format nil "~D retained pages. ~:[No sitemap of this site is retained, so the space holds only these pages of it.~;Every page of its retained sitemap is retained.~]"
                              (length (site-pages site)) (site-complete-p site))))
      (:ul (dolist (page (site-pages site))
             (v:html (:li (v:object-ref page :select "Wiki page" :display (page-slug page))))))
      (search-links))))

(v:defview discovery-candidate-view (candidate discovery-candidate)
  (v:html-view :title "Discovery candidate" :priority 0
    (v:html
      (:h3 (cl-who:esc (candidate-domain candidate)))
      (:p "Named by these retained pages, by the rule of "
          (v:object-ref (search-source "crawler:named-sites") :select "Source definition" :display "scrape.rb")
          ". " (v:object-ref (search-source "crawler:found") :select "Source definition" :display "found.rb")
          " would add the site to the crawl; here it is only listed, not fetched.")
      (:ul (dolist (page (candidate-named-by candidate))
             (v:html (:li (v:object-ref page :select "Wiki page" :display (format nil "~A/~A" (page-site page) (page-slug page)))))))
      (search-links))))

(dolist (name '(search-sources-reading retained-search-space curiosity-token-search forked-item-search
                template-item-search discovery-candidates item-search-topicmap))
  (dreyeck/authority-policy:register-operation-contract
   :identity (format nil "traverse/~(~A~)" name)
   :operation (format nil "DREYECK/TRAVERSE::~A" name)
   :applicability :example
   :status :contracted
   :effect-classes '(:observational)
   :effect-extent "Read hash-verified retained pages and sources; allocate search, site and Workspace objects."
   :authority "Wiki pages retained by this companion; search sources at fixed revisions"
   :preconditions "dreyeck/traverse/reading loaded"
   :postconditions "No process, network request, Wiki, search service or server is touched"
   :verification-evidence "dreyeck/traverse/reading/tests"
   :replay-semantics "Fresh Lisp inspection; the search reads retained bytes only"
   :audit-provenance "Federated Search Without a Central Index, 2026-10-24"))
