;;;; Wiki Pages Retained from the Experiment

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

;;; The snapshot: Wiki pages as served on 2026-10-21, retained byte for byte. It is evidence about that
;;; moment; the live Wiki is reached only by links the reader follows, never by rendering.

(defclass wiki-snapshot ()
  ((manifest :initarg :manifest :reader snapshot-manifest)
   (pages :initform nil :accessor snapshot-pages)
   (sources :initform nil :accessor snapshot-sources))
  (:documentation "Retained Wiki pages, served assets and source excerpts of the Discourse Graph experiment."))

(defclass wiki-page ()
  ((site :initarg :site :reader page-site)
   (slug :initarg :slug :reader page-slug)
   (title :initarg :title :reader page-title)
   (file :initarg :file :reader page-file)
   (url :initarg :url :reader page-url :documentation "The URL the retained bytes were fetched from.")
   (fetched-at :initarg :fetched-at :reader page-fetched-at)
   (sha256 :initarg :sha256 :reader page-sha256)
   (json :initarg :json :reader page-json)
   (items :initform nil :accessor page-items)
   (steps :initform nil :accessor page-steps))
  (:documentation "One Wiki page of the snapshot: site, slug, story items and journal, as fetched."))

(defclass wiki-item ()
  ((page :initarg :page :reader item-page)
   (id :initarg :id :reader item-id)
   (type :initarg :type :reader item-type)
   (text :initarg :text :reader item-text)
   (index :initarg :index :reader item-index)
   (fold :initarg :fold :reader item-fold :documentation "The nearest preceding pagefold item, or NIL.")
   (json :initarg :json :reader item-json))
  (:documentation "One story item, identified by its page and its item id."))

(defclass journal-step ()
  ((page :initarg :page :reader step-page)
   (index :initarg :index :reader step-index)
   (action :initarg :action :reader step-action)
   (id :initarg :id :reader step-id)
   (date :initarg :date :reader step-date :documentation "Milliseconds since 1970, as the journal stores it.")
   (site :initarg :site :reader step-site :documentation "For a fork, the site it was forked from.")
   (json :initarg :json :reader step-json))
  (:documentation "One journal entry: documented history of the page, as the Wiki recorded it."))

(defclass served-source (n:message-source)
  ((url :initarg :url :reader source-url)
   (fetched-at :initarg :fetched-at :reader source-fetched-at))
  (:documentation "A definition excerpt of a file served by a Wiki site as an asset, not taken from Git."))

(defun discourse-path (name) (evidence-path (concatenate 'string "discourse/" name)))

(defun iso-date (milliseconds)
  (when milliseconds
    (multiple-value-bind (s mi h d mo y)
        (decode-universal-time (+ (floor milliseconds 1000) (encode-universal-time 0 0 0 1 1 1970 0)) 0)
      (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ" y mo d h mi s))))

(defun live-url (page)
  "The page on its Wiki now: a link for the reader, not retained evidence."
  (let ((scheme (subseq (page-url page) 0 (search "://" (page-url page)))))
    (format nil "~A://~A/view/~A" scheme (page-site page) (page-slug page))))

(defun make-wiki-page (entry &optional (evidence-directory "discourse/"))
  (let* ((json (read-json (concatenate 'string evidence-directory (gethash "file" entry))))
         (page (make-instance 'wiki-page
                              :site (gethash "site" entry) :slug (gethash "slug" entry)
                              :title (gethash "title" json) :file (gethash "file" entry)
                              :url (gethash "url" entry) :fetched-at (gethash "fetchedAt" entry)
                              :sha256 (gethash "sha256" entry) :json json))
         (fold nil))
    (setf (page-items page)
          (loop for item across (gethash "story" json)
                for index from 0
                for wiki-item = (make-instance 'wiki-item
                                               :page page :id (gethash "id" item) :type (gethash "type" item)
                                               :text (or (gethash "text" item) "") :index index
                                               :fold fold :json item)
                do (when (equal "pagefold" (gethash "type" item)) (setf fold wiki-item))
                collect wiki-item))
    (setf (page-steps page)
          (loop for step across (or (gethash "journal" json) (vector))
                for index from 0
                collect (make-instance 'journal-step
                                       :page page :index index :action (gethash "type" step)
                                       :id (gethash "id" step) :date (gethash "date" step)
                                       :site (gethash "site" step) :json step)))
    page))

(defun load-snapshot ()
  (let* ((manifest (read-json "discourse/snapshot.json"))
         (snapshot (make-instance 'wiki-snapshot :manifest manifest))
         (reading (retained-reading)))
    (loop for entry across (gethash "files" manifest)
          do (unless (equal (file-digest (discourse-path (gethash "file" entry))) (gethash "sha256" entry))
               (error "Retained Wiki file differs from its recorded SHA-256: ~A" (gethash "file" entry))))
    (loop for entry across (gethash "referencedFiles" manifest)
          do (unless (equal (file-digest (evidence-path (gethash "file" entry))) (gethash "sha256" entry))
               (error "Referenced source differs from its recorded SHA-256: ~A" (gethash "file" entry))))
    (let ((replay (gethash "replay" manifest)))
      (unless (and (equal (file-digest (discourse-path (gethash "driver" replay))) (gethash "driverSha256" replay))
                   (equal (file-digest (discourse-path (gethash "output" replay))) (gethash "outputSha256" replay)))
        (error "The retained replay differs from its recorded SHA-256")))
    (setf (snapshot-pages snapshot)
          (loop for entry across (gethash "files" manifest)
                when (equal "page" (gethash "kind" entry)) collect (make-wiki-page entry)))
    (setf (snapshot-sources snapshot)
          (loop for metadata across (gethash "excerpts" manifest)
                collect (make-excerpt snapshot reading metadata)))
    snapshot))

(defun git-file-entry (reading file)
  "The old manifest's entry for a retained Git file, or the referenced-file entry that carries its revision."
  (or (find file (gethash "files" (reading-manifest reading)) :key (lambda (entry) (gethash "file" entry)) :test #'equal)
      (error "No Git provenance for ~A" file)))

(defun make-excerpt (snapshot reading metadata)
  (let* ((file (gethash "file" metadata))
         (text (uiop:read-file-string (evidence-path file) :external-format :utf-8))
         (excerpt (subseq text (gethash "start" metadata) (gethash "end" metadata)))
         (key (gethash "key" metadata))
         (definition (subseq key (1+ (position #\: key)))))
    (unless (equal (text-digest excerpt) (gethash "sha256" metadata))
      (error "Definition excerpt differs from its coordinates: ~A" key))
    (if (eql 0 (search "discourse/" file))
        (let ((entry (find file (gethash "files" (snapshot-manifest snapshot))
                           :key (lambda (entry) (concatenate 'string "discourse/" (gethash "file" entry)))
                           :test #'equal)))
          (make-instance 'served-source
                         :metadata metadata :file (evidence-path file) :text excerpt :definition definition
                         :url (gethash "url" entry) :fetched-at (gethash "fetchedAt" entry)))
        (let* ((entry (if (equal file "upstream/mech.js")
                          (find file (gethash "referencedFiles" (snapshot-manifest snapshot))
                                :key (lambda (entry) (gethash "file" entry)) :test #'equal)
                          (git-file-entry reading file)))
               (revision (find (gethash "revision" entry) (mapcar #'cdr (reading-revisions reading))
                               :key #'git:git-commit-hash-of :test #'equal))
               (git-file (git:ensure-git-evidence-file revision (gethash "path" entry)))
               (described (alexandria:copy-hash-table metadata)))
          (dolist (field '("authority" "path" "revision"))
            (setf (gethash field described) (gethash field entry)))
          (let ((source (make-instance 'traverse-source
                                       :reading reading :metadata described :file (evidence-path file)
                                       :text excerpt :definition definition
                                       :revision revision :revision-file git-file)))
            (git:add-git-evidence-location git-file source)
            source)))))

(defvar *snapshot* nil)

(hyperdoc:defexample experiment-snapshot
  "Read and verify the retained Wiki pages, assets and excerpts once per image; nothing is fetched."
  (or *snapshot* (setf *snapshot* (load-snapshot))))

(defun wiki-page-of (site slug &optional (snapshot (experiment-snapshot)))
  (or (find-if (lambda (page) (and (equal site (page-site page)) (equal slug (page-slug page))))
               (snapshot-pages snapshot))
      (error "No retained page ~A/~A" site slug)))

(defun wiki-item-of (site slug id)
  (or (find id (page-items (wiki-page-of site slug)) :key #'item-id :test #'equal)
      (error "No item ~A on ~A/~A" id site slug)))

(defun dg-item (slug id) (wiki-item-of "discourse.dreyeck.ch" slug id))

(defun discourse-source (key &optional (snapshot (experiment-snapshot)))
  "A definition excerpt of this reading, or else one of the technical reading's."
  (or (find key (snapshot-sources snapshot) :key #'source-key :test #'equal)
      (source-by-key (retained-reading) key)))

(defun item-steps (item)
  (remove-if-not (lambda (step) (equal (item-id item) (step-id step))) (page-steps (item-page item))))

(defun step-text (step)
  (let ((item (gethash "item" (step-json step))))
    (and item (gethash "text" item))))

(defun page-forks (page)
  (remove-if-not (lambda (step) (equal "fork" (step-action step))) (page-steps page)))

;;; The relation rules EXTRACT applies, restated here to locate the story item behind a recorded edge.
;;; EXTRACT records page, role and target, not the item; the tests hold this restatement to every
;;; recorded edge of the replay.

(defun js-space-p (c)
  "JavaScript's \\s: ASCII whitespace, no-break space, the Unicode space separators, line and paragraph separators and BOM."
  (let ((code (char-code c)))
    (or (<= 9 code 13) (= code 32) (= code 160) (= code 5760) (<= 8192 code 8202)
        (member code '(8232 8233 8239 8287 12288 65279)))))

(defun js-word-p (c) (or (char= c #\_) (and (char< c (code-char 128)) (alphanumericp c))))

(defun as-slug (title)
  "asSlug of Ward's mech.js: whitespace to '-', drop all but ASCII letters, digits and '-', downcase."
  (string-downcase
   (remove-if-not (lambda (c) (or (char= c #\-) (and (char< c (code-char 128)) (alphanumericp c))))
                  (substitute-if #\- #'js-space-p title))))

(defun fold-role (fold)
  "normalize_fold, canonicalize_fold and the recognized set of discourse.mjs, applied to a pagefold item."
  (when fold
    (let* ((text (item-text fold))
           (start (or (position-if-not #'js-space-p text) (length text)))
           (end (1+ (or (position-if-not #'js-space-p text :from-end t) -1)))
           (normalized (remove-if-not (lambda (c) (or (js-word-p c) (js-space-p c)))
                                      (string-downcase (subseq text start (max start end)))))
           (canonical (or (cdr (assoc normalized '(("claims" . "claim") ("questions" . "question")
                                                   ("supports" . "support") ("opposes" . "oppose"))
                                      :test #'equal))
                          normalized)))
      (and (member canonical '("question" "claim" "support" "oppose") :test #'equal) canonical))))

(defun item-role (item) (fold-role (item-fold item)))

(defun item-links (item)
  "parse_links of discourse.mjs: (site . slug) for a reference, and for each [[link]] of a paragraph."
  (let ((site (page-site (item-page item)))
        (json (item-json item)))
    (cond ((and (equal "reference" (item-type item)) (gethash "slug" json))
           (list (cons (or (gethash "site" json) site) (gethash "slug" json))))
          ((equal "paragraph" (item-type item))
           (loop with text = (item-text item)
                 for start = (search "[[" text) then (search "[[" text :start2 end)
                 for end = (and start (search "]]" text :start2 (+ start 2)))
                 while (and start end)
                 for raw = (subseq text (+ start 2) (or (position #\| text :start (+ start 2) :end end) end))
                 for target = (let ((from (or (position-if-not #'js-space-p raw) (length raw))))
                                (subseq raw from (max from (1+ (or (position-if-not #'js-space-p raw :from-end t) -1)))))
                 for slash = (position #\/ target)
                 for link = (cond ((or (zerop (length target)) (search "://" target)) nil)
                                  (slash (cons (if (zerop slash) site (subseq target 0 slash))
                                               (as-slug (subseq target (1+ slash) (or (position #\/ target :start (1+ slash)) (length target))))))
                                  (t (cons site (as-slug target))))
                 when (and link (plusp (length (cdr link)))) collect link)))))

(defun edge-origin-items (from-id role to-id)
  "Story items of the from page whose fold gives ROLE and whose links include TO-ID."
  (let* ((plus (position #\+ from-id))
         (page (wiki-page-of (subseq from-id 0 plus) (subseq from-id (1+ plus)))))
    (remove-if-not (lambda (item)
                     (and (equal role (item-role item))
                          (member to-id (item-links item) :test #'equal
                                  :key (lambda (link) (format nil "~A+~A" (car link) (cdr link))))))
                   (page-items page))))

;;; Views

(defmethod v:text-representation ((snapshot wiki-snapshot))
  "Discourse Graph experiment: Wiki pages retained on 2026-10-21")

(defmethod v:text-representation ((page wiki-page))
  (format nil "~A/~A" (page-site page) (page-slug page)))

(defmethod v:text-representation ((item wiki-item))
  (format nil "~A/~A #~A [~A]" (page-site (item-page item)) (page-slug (item-page item)) (item-id item) (item-type item)))

(defmethod v:text-representation ((step journal-step))
  (format nil "~A ~A ~@[~A~] ~A" (page-slug (step-page step)) (step-action step) (step-id step) (iso-date (step-date step))))

(defmethod v:text-representation ((source served-source))
  (format nil "~A — ~A" (n:source-definition source) (source-url source)))

(defun discourse-links ()
  (v:html
    (:p "Experiment: "
        (v:object-ref (companion-page "What Did Ward Propose?") :select "Content" :display "Proposal")
        " · " (v:object-ref (companion-page "How Were Discourse Relations Collected?") :select "Content" :display "Collection")
        " · " (v:object-ref (companion-page "From WALK to TRAVERSE") :select "Content" :display "WALK to TRAVERSE")
        " · " (v:object-ref (companion-page "Reading an Actual Discourse Graph") :select "Content" :display "Actual graph")
        " · " (v:object-ref (companion-page "What Remains to Be Demonstrated?") :select "Content" :display "Open"))))

(defun live-link (page)
  (v:html (:a :href (live-url page) :target "_blank" :rel "noopener"
              (cl-who:esc (format nil "~A (current version on the Wiki, not retained)" (live-url page))))))

(defun excerpt (text &optional (length 160))
  (let ((line (substitute #\Space #\Newline text)))
    (if (> (length line) length) (concatenate 'string (subseq line 0 length) "…") line)))

(v:defview wiki-page-view (page wiki-page)
  (v:html-view :title "Wiki page" :priority 0
    (v:html
      (:h3 (cl-who:esc (page-title page)))
      (:p (:strong "Site: ") (:code (cl-who:esc (page-site page)))
          " · " (:strong "Slug: ") (:code (cl-who:esc (page-slug page))))
      (:p (:strong "Retained: ") (cl-who:esc (page-url page)) " fetched " (cl-who:esc (page-fetched-at page))
          " · SHA-256 " (:code (cl-who:esc (subseq (page-sha256 page) 0 16))) "…")
      (:p (live-link page))
      (:h4 "Story")
      (:ol (dolist (item (page-items page))
             (v:html (:li (v:object-ref item :select "Story item"
                                        :display (format nil "~A [~A] ~A" (item-id item) (item-type item)
                                                         (excerpt (item-text item) 90)))))))
      (:p (v:object-ref (page-steps page) :display (format nil "Journal: ~D entries" (length (page-steps page)))))
      (discourse-links))))

(v:defview wiki-page-journal-view (page wiki-page)
  (v:html-view :title "Journal" :priority 1
    (v:html
      (:p "Documented history as the Wiki recorded it; dates are the journal's own.")
      (:ol (dolist (step (page-steps page))
             (v:html (:li (v:object-ref step :select "Journal step"
                                        :display (format nil "~A ~A ~@[~A~] ~@[from ~A~]" (iso-date (step-date step))
                                                         (step-action step) (step-id step) (step-site step))))))))))

(v:defview wiki-item-view (item wiki-item)
  (v:html-view :title "Story item" :priority 0
    (let ((page (item-page item)))
      (v:html
        (:h3 (cl-who:esc (format nil "~A [~A]" (item-id item) (item-type item))))
        (:p (:strong "Site: ") (:code (cl-who:esc (page-site page)))
            " · " (:strong "Slug: ") (:code (cl-who:esc (page-slug page)))
            " · " (:strong "Item id: ") (:code (cl-who:esc (item-id item)))
            " · " (v:object-ref page :select "Wiki page" :display (page-title page)))
        (:p (:strong "Fold: ")
            (if (item-fold item)
                (v:object-ref (item-fold item) :select "Story item" :display (format nil "\"~A\"" (item-text (item-fold item))))
                (v:html "none"))
            " · " (:strong "Role EXTRACT gives it: ") (cl-who:esc (or (item-role item) "none")))
        (:pre :style "white-space: pre-wrap" (cl-who:esc (item-text item)))
        (when (item-links item)
          (v:html (:h4 "Links in this item")
                  (:ul (dolist (link (item-links item))
                         (let ((target (ignore-errors (wiki-page-of (car link) (cdr link)))))
                           (v:html (:li (cl-who:esc (format nil "~A/~A " (car link) (cdr link)))
                                        (if target
                                            (v:object-ref target :select "Wiki page" :display "retained page")
                                            (v:html "(not in the snapshot)")))))))))
        (when (item-steps item)
          (v:html (:h4 "Journal entries for this item")
                  (:ol (dolist (step (item-steps item))
                         (v:html (:li (v:object-ref step :select "Journal step"
                                                    :display (format nil "~A ~A" (iso-date (step-date step)) (step-action step)))))))))
        (:p (live-link page))
        (discourse-links)))))

(v:defview journal-step-view (step journal-step)
  (v:html-view :title "Journal step" :priority 0
    (let ((current (and (step-id step) (find (step-id step) (page-items (step-page step)) :key #'item-id :test #'equal))))
      (v:html
        (:h3 (cl-who:esc (format nil "~A ~A" (step-action step) (iso-date (step-date step)))))
        (:p (:strong "Page: ") (v:object-ref (step-page step) :select "Wiki page" :display (page-title (step-page step)))
            " · entry " (cl-who:esc (princ-to-string (step-index step))))
        (when (step-site step) (v:html (:p (:strong "Forked from: ") (:code (cl-who:esc (step-site step))))))
        (when (step-id step)
          (v:html (:p (:strong "Item: ") (:code (cl-who:esc (step-id step))) " "
                      (if current (v:object-ref current :select "Story item" :display "as it is now")
                          (v:html "(no longer on the page)")))))
        (when (step-text step) (v:html (:pre :style "white-space: pre-wrap" (cl-who:esc (step-text step)))))
        (discourse-links)))))

(v:defview served-source-view (source served-source)
  (v:html-view :title "Source definition" :priority 0
    (let ((metadata (n:source-metadata source)))
      (v:html
        (:h3 (cl-who:esc (n:source-definition source)))
        (:p "Served asset, not a Git revision: " (cl-who:esc (source-url source))
            " · fetched " (cl-who:esc (source-fetched-at source))
            " · characters " (cl-who:esc (princ-to-string (gethash "start" metadata))) "–"
            (cl-who:esc (princ-to-string (gethash "end" metadata))))
        (:p (v:object-ref metadata :display "Coordinates and digests"))
        (:pre (cl-who:esc (n:source-text source)))
        (discourse-links)))))

(v:defview wiki-snapshot-view (snapshot wiki-snapshot)
  (v:html-view :title "Snapshot" :priority 0
    (let ((manifest (snapshot-manifest snapshot)))
      (v:html
        (:p (cl-who:esc (gethash "method" manifest)) ". " (cl-who:esc (gethash "note" manifest)))
        (:h4 "Pages")
        (:ul (dolist (page (snapshot-pages snapshot))
               (v:html (:li (v:object-ref page :select "Wiki page")
                            " " (cl-who:esc (page-title page))))))
        (:h4 "Source definitions")
        (:ul (dolist (source (snapshot-sources snapshot))
               (v:html (:li (v:object-ref source :select "Source definition" :display (source-key source))))))
        (discourse-links)))))
