;;;; A Wiki Page as Topic Map

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "Curiosity Token as Topic Map" :hyperbook "dreyeck/traverse/reading"))

;;; One retained Wiki page, projected as a Topicmap of the objects it already consists of: the page,
;;; its story items in order, its journal entries, the attributions those entries record, and the
;;; commands of its SEARCH items. Nothing is retold by hand; every topic is an object read from the
;;; retained JSON, and every association says whether the story, the journal, or this projection's
;;; reading of the story's text warrants it.
;;;
;;; An item is identified by its page and its item id, never by its text or its type, which both can
;;; change. Topic ids carry site and slug, so occurrences of the same item id on other pages, once a
;;; search result is recorded, become further topics related by the shared id instead of merging with
;;; this page's item. No search result is recorded yet, and none is invented here.

(defparameter +wiki-origins+ '(:story :journal :derived)
  "Where an association comes from. :story — the page's story: which items it holds and in what order;
:journal — an entry of the page's journal; :derived — read by this projection from the text of a story
item, such as an item id named by a SEARCH item or a paragraph. A :derived association is never a search
result.")

(defclass journal-attribution ()
  ((entry :initarg :entry :reader attribution-entry :documentation "The journal step that records it.")
   (site :initarg :site :reader attribution-site)
   (page-title :initarg :page-title :reader attribution-page-title))
  (:documentation "The attribution an add entry records: the page and site an item was taken from."))

(defclass remote-page ()
  ((site :initarg :site :reader remote-site)
   (title :initarg :title :reader remote-title))
  (:documentation "A Wiki page named by retained evidence but not itself retained: only site and title are known."))

(defclass search-expression ()
  ((item :initarg :item :reader expression-item)
   (verb :initarg :verb :reader expression-verb)
   (argument :initarg :argument :reader expression-argument))
  (:documentation "The command of a SEARCH story item, read from its text. The search is not run."))

(defun retained-page (directory)
  "The one page retained under DIRECTORY of the evidence, checked against its manifest."
  (let* ((manifest (read-json (concatenate 'string directory "manifest.json")))
         (entry (aref (gethash "files" manifest) 0)))
    (unless (equal (file-digest (evidence-path (concatenate 'string directory (gethash "file" entry))))
                   (gethash "sha256" entry))
      (error "Retained page differs from its recorded SHA-256: ~A~A" directory (gethash "file" entry)))
    (make-wiki-page entry directory)))

(defvar *curiosity-token* nil)

(hyperdoc:defexample curiosity-token-page
  "The page found.ward.fed.wiki/curiosity-token as retained on 2026-10-24; nothing is fetched."
  (or *curiosity-token* (setf *curiosity-token* (retained-page "curiosity/"))))

(defun curiosity-token-record ()
  "The manifest entry of the retained JSON: URL, fetch time, status and SHA-256."
  (aref (gethash "files" (read-json "curiosity/manifest.json")) 0))

(defun page-item (page id)
  (or (find id (page-items page) :key #'item-id :test #'equal)
      (error "No item ~A on ~A/~A" id (page-site page) (page-slug page))))

(defun curiosity-item (id) (page-item (curiosity-token-page) id))

;;; What the projection reads from the story and the journal, once per page, so that the same objects
;;; stand behind the topics of every projection of that page.

(defvar *page-readings* (make-hash-table :test 'eq))

(defun search-expression-of (item)
  (when (equal "search" (item-type item))
    (let ((words (remove "" (uiop:split-string (item-text item) :separator '(#\Space #\Tab #\Newline)) :test #'equal)))
      (when (and (second words) (equal "SEARCH" (first words)))
        (make-instance 'search-expression :item item :verb (second words)
                                          :argument (format nil "~{~A~^ ~}" (cddr words)))))))

(defun page-reading (page)
  "Attributions, the pages they name, and SEARCH expressions of PAGE: (:attributions :remotes :searches)."
  (or (gethash page *page-readings*)
      (setf (gethash page *page-readings*)
            (let* ((attributions
                     (loop for entry in (page-steps page)
                           for attribution = (gethash "attribution" (step-json entry))
                           when attribution
                             collect (make-instance 'journal-attribution :entry entry
                                                                         :site (gethash "site" attribution)
                                                                         :page-title (gethash "page" attribution))))
                   (remotes nil))
              (dolist (attribution attributions)
                (unless (find-if (lambda (remote) (and (equal (remote-site remote) (attribution-site attribution))
                                                       (equal (remote-title remote) (attribution-page-title attribution))))
                                 remotes)
                  (push (make-instance 'remote-page :site (attribution-site attribution)
                                                    :title (attribution-page-title attribution))
                        remotes)))
              (list :attributions attributions :remotes (nreverse remotes)
                    :searches (remove nil (mapcar #'search-expression-of (page-items page))))))))

(defun page-attributions (page) (getf (page-reading page) :attributions))
(defun page-searches (page) (getf (page-reading page) :searches))

(defun remote-page-of (page attribution)
  (find-if (lambda (remote) (and (equal (remote-site remote) (attribution-site attribution))
                                 (equal (remote-title remote) (attribution-page-title attribution))))
           (getf (page-reading page) :remotes)))

(defun attributed-item (attribution)
  (let ((entry (attribution-entry attribution)))
    (find (step-id entry) (page-items (step-page entry)) :key #'item-id :test #'equal)))

(defun word-in-text-p (word text)
  "WORD occurs in TEXT as a whole word, ignoring case."
  (loop with length = (length word)
        for start = (search word text :test #'char-equal) then (search word text :test #'char-equal :start2 (1+ start))
        while start
        thereis (and (or (zerop start) (not (alphanumericp (char text (1- start)))))
                     (or (= (+ start length) (length text)) (not (alphanumericp (char text (+ start length))))))))

(defun expression-matches (expression)
  "Items of the expression's own page that it names: by id for ITEMS, by a whole word of their text for WORDS."
  (let ((page (item-page (expression-item expression)))
        (argument (expression-argument expression)))
    (remove (expression-item expression)
            (cond ((member (expression-verb expression) '("ITEMS" "ITEM") :test #'equal)
                   (remove-if-not (lambda (item) (equal argument (item-id item))) (page-items page)))
                  ((member (expression-verb expression) '("WORDS" "WORD") :test #'equal)
                   (remove-if-not (lambda (item) (word-in-text-p argument (item-text item))) (page-items page))))
            :test #'eq)))

(defun named-items (item)
  "Other items of the page whose id the text of ITEM names, outside a SEARCH command."
  (unless (search-expression-of item)
    (remove-if-not (lambda (other) (and (not (eq other item)) (search (item-id other) (item-text item))))
                   (page-items (item-page item)))))

;;; Topic ids: site and slug first, so that an item id never stands for more than one page's item.

(defun page-topic-id (page) (format nil "~A/~A" (page-site page) (page-slug page)))
(defun item-topic-id (item) (format nil "~A#~A" (page-topic-id (item-page item)) (item-id item)))
(defun step-topic-id (entry) (format nil "~A@journal/~D" (page-topic-id (step-page entry)) (step-index entry)))
(defun attribution-topic-id (attribution)
  (format nil "~A@attribution/~D" (page-topic-id (step-page (attribution-entry attribution)))
          (step-index (attribution-entry attribution))))
(defun remote-topic-id (remote) (format nil "~A/~A" (remote-site remote) (as-slug (remote-title remote))))
(defun search-topic-id (expression) (format nil "~A@search" (item-topic-id (expression-item expression))))

(defun topic-label (control &rest arguments)
  "A one-line label. The Topicmap view writes labels into single-quoted attributes, so ' becomes ’."
  (substitute #\RIGHT_SINGLE_QUOTATION_MARK #\' (excerpt (apply #'format nil control arguments) 70)))

(defun wiki-page-projection (page)
  "The Topicmap of one retained Wiki page; every association names its origin: story, journal or derived."
  (let* ((items (page-items page))
         (count (length items))
         (attributions (page-attributions page))
         (searches (page-searches page))
         (by-id (lambda (id) (find id items :key #'item-id :test #'equal)))
         (topics
           (append
            (list (list (page-topic-id page) (topic-label "page ~A" (page-title page)) page :story))
            (loop for item in items for position from 1
                  collect (list (item-topic-id item)
                                (topic-label "~D/~D ~A ~A" position count (item-type item) (item-text item))
                                item :story))
            (loop for entry in (page-steps page)
                  collect (list (step-topic-id entry)
                                (topic-label "journal ~D ~A ~@[~A ~]~A" (step-index entry) (step-action entry)
                                             (step-id entry) (subseq (or (iso-date (step-date entry)) "") 0 10))
                                entry :journal))
            (loop for attribution in attributions
                  collect (list (attribution-topic-id attribution)
                                (topic-label "attribution: ~A @ ~A" (attribution-page-title attribution)
                                             (attribution-site attribution))
                                attribution :journal))
            (loop for remote in (getf (page-reading page) :remotes)
                  collect (list (remote-topic-id remote)
                                (topic-label "~A @ ~A (not retained)" (remote-title remote) (remote-site remote))
                                remote :journal))
            (loop for expression in searches
                  collect (list (search-topic-id expression)
                                (topic-label "SEARCH ~A ~A" (expression-verb expression) (expression-argument expression))
                                expression :derived))))
         (relations
           (append
            (loop for item in items for position from 1
                  collect (list (page-topic-id page) (item-topic-id item) "contains" :story
                                (format nil "story item ~D of ~D" position count) page))
            (loop for (item next) on items while next
                  collect (list (item-topic-id item) (item-topic-id next) "precedes" :story "story order" page))
            (loop for entry in (page-steps page)
                  for item = (and (step-id entry) (funcall by-id (step-id entry)))
                  for after = (let ((json (step-json entry))) (and (gethash "after" json) (funcall by-id (gethash "after" json))))
                  when (equal "create" (step-action entry))
                    collect (list (step-topic-id entry) (page-topic-id page) "creates" :journal
                                  (format nil "journal entry ~D" (step-index entry)) entry)
                  when item
                    collect (list (step-topic-id entry) (item-topic-id item)
                                  (format nil "~A entry for" (step-action entry)) :journal
                                  (format nil "journal entry ~D names item ~A" (step-index entry) (item-id item)) entry)
                  when after
                    collect (list (step-topic-id entry) (item-topic-id after) "placed after" :journal
                                  (format nil "journal entry ~D: after ~A" (step-index entry) (item-id after)) entry))
            (loop for attribution in attributions
                  for entry = (attribution-entry attribution)
                  for item = (attributed-item attribution)
                  collect (list (step-topic-id entry) (attribution-topic-id attribution) "records" :journal
                                (format nil "the attribution field of journal entry ~D" (step-index entry)) entry)
                  collect (list (attribution-topic-id attribution) (remote-topic-id (remote-page-of page attribution))
                                "names the source page" :journal
                                (format nil "page ~S on ~A" (attribution-page-title attribution) (attribution-site attribution))
                                entry)
                  when item
                    collect (list (attribution-topic-id attribution) (item-topic-id item) "attributes" :journal
                                  (format nil "item ~A was added with this attribution" (item-id item)) entry))
            (loop for expression in searches
                  collect (list (item-topic-id (expression-item expression)) (search-topic-id expression) "states" :derived
                                "the SEARCH command read from the item text" (expression-item expression))
                  append (loop for match in (expression-matches expression)
                               collect (list (search-topic-id expression) (item-topic-id match)
                                             (if (member (expression-verb expression) '("ITEMS" "ITEM") :test #'equal)
                                                 "names the item id of"
                                                 "names a word of")
                                             :derived
                                             "matched by this projection on the retained page; the search was not run"
                                             expression)))
            (loop for item in items
                  append (loop for named in (named-items item)
                               collect (list (item-topic-id item) (item-topic-id named) "names the item id of" :derived
                                             (format nil "the text contains ~A" (item-id named)) item))))))
    (let ((+statuses+ +wiki-origins+))
      (projection page topics relations))))

(defun wiki-page-workspace (page item-id)
  "A Workspace on the projection of PAGE with Point on the item ITEM-ID."
  (tm:make-topicmap-workspace (wiki-page-projection page) (item-topic-id (page-item page item-id))))

(hyperdoc:defexample curiosity-token-topicmap
  "Curiosity Token as Topic Map, with Point on the markdown item cf80b0444c62866e."
  (wiki-page-workspace (curiosity-token-page) "cf80b0444c62866e"))

(hyperdoc:defexample curiosity-attribution
  "The attribution the journal records for the Curiosity item: Photo Rotator on photos.ward.dojo.fed.wiki."
  (find "cf80b0444c62866e" (page-attributions (curiosity-token-page))
        :key (lambda (attribution) (step-id (attribution-entry attribution))) :test #'equal))

(hyperdoc:defexample curiosity-search
  "The SEARCH ITEMS item that names the Curiosity item's id, read from its text."
  (find "b241aba9ea8cb289" (page-searches (curiosity-token-page))
        :key (lambda (expression) (item-id (expression-item expression))) :test #'equal))

(hyperdoc:defexample curiosity-word-search
  "The SEARCH WORDS item of the page, read from its text."
  (find "1943a99a6eecb530" (page-searches (curiosity-token-page))
        :key (lambda (expression) (item-id (expression-item expression))) :test #'equal))

;;; Views

(defmethod v:text-representation ((attribution journal-attribution))
  (format nil "attribution: ~A @ ~A" (attribution-page-title attribution) (attribution-site attribution)))

(defmethod v:text-representation ((remote remote-page))
  (format nil "~A @ ~A (not retained)" (remote-title remote) (remote-site remote)))

(defmethod v:text-representation ((expression search-expression))
  (format nil "SEARCH ~A ~A" (expression-verb expression) (expression-argument expression)))

(defun curiosity-links ()
  (v:html
    (:p "Reading: "
        (v:object-ref (companion-page "Curiosity Token as Topic Map") :select "Content" :display "Curiosity Token as Topic Map"))))

(v:defview journal-attribution-view (attribution journal-attribution)
  (v:html-view :title "Attribution" :priority 0
    (let ((entry (attribution-entry attribution))
          (item (attributed-item attribution)))
      (v:html
        (:h3 (cl-who:esc (format nil "~A @ ~A" (attribution-page-title attribution) (attribution-site attribution))))
        (:p "Recorded by " (v:object-ref entry :select "Journal step"
                                         :display (format nil "journal entry ~D, ~A ~A" (step-index entry) (step-action entry)
                                                          (iso-date (step-date entry)))))
        (when item
          (v:html (:p "For the item " (v:object-ref item :select "Story item" :display (format nil "~A ~A" (item-id item) (item-text item))))))
        (:p (v:object-ref (step-json entry) :display "The journal entry as retained"))
        (:p "Documented provenance of the item. It does not show on which other pages the item id occurs today.")
        (curiosity-links)))))

(v:defview remote-page-view (remote remote-page)
  (v:html-view :title "Remote page" :priority 0
    (let ((url (format nil "http://~A/view/~A" (remote-site remote) (as-slug (remote-title remote)))))
      (v:html
        (:h3 (cl-who:esc (remote-title remote)))
        (:p (:strong "Site: ") (:code (cl-who:esc (remote-site remote)))
            " · " (:strong "Slug, as asSlug forms it: ") (:code (cl-who:esc (as-slug (remote-title remote)))))
        (:p "Named by an attribution; the page itself is not retained here.")
        (:p (:a :href url :target "_blank" :rel "noopener" (cl-who:esc (format nil "~A (on its Wiki, not retained)" url))))
        (curiosity-links)))))

(v:defview search-expression-view (expression search-expression)
  (v:html-view :title "Search expression" :priority 0
    (let ((item (expression-item expression)))
      (v:html
        (:h3 (cl-who:esc (format nil "SEARCH ~A ~A" (expression-verb expression) (expression-argument expression))))
        (:p "Read from the text of " (v:object-ref item :select "Story item" :display (format nil "the search item ~A" (item-id item))))
        (:h4 "Items of this page it names (matched by this projection)")
        (:ul (dolist (match (expression-matches expression))
               (v:html (:li (v:object-ref match :select "Story item" :display (format nil "~A ~A" (item-id match) (excerpt (item-text match) 60)))))))
        (:p "When a reader opens the page, the search runs across the sites the reader's Wiki can see. "
            "Its results are not recorded here. Recorded results would add one topic per site, slug and item, "
            "related to this page's item by the shared id; they would not merge with it.")
        (curiosity-links)))))

(dolist (name '(curiosity-token-page curiosity-token-topicmap curiosity-attribution curiosity-search
                curiosity-word-search))
  (dreyeck/authority-policy:register-operation-contract
   :identity (format nil "traverse/~(~A~)" name)
   :operation (format nil "DREYECK/TRAVERSE::~A" name)
   :applicability :example
   :status :contracted
   :effect-classes '(:observational)
   :effect-extent "Read the hash-verified retained page; allocate page, item, journal and Workspace objects."
   :authority "found.ward.fed.wiki/curiosity-token as retained on 2026-10-24"
   :preconditions "dreyeck/traverse/reading loaded"
   :postconditions "No process, network request, Wiki or server is touched; no search is run"
   :verification-evidence "dreyeck/traverse/reading/tests"
   :replay-semantics "Fresh Lisp inspection"
   :audit-provenance "Curiosity Token as Topic Map, 2026-10-24"))
