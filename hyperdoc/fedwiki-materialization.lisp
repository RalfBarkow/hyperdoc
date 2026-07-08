;;;; FedWiki materialization from generated/article-slice artifacts
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass fedwiki-materialization-entry ()
  ((kind :initarg :kind :reader fedwiki-materialization-entry-kind-of)
   (slug :initarg :slug :reader fedwiki-materialization-entry-slug-of)
   (title :initarg :title :reader fedwiki-materialization-entry-title-of)
   (source-kind :initarg :source-kind
                :reader fedwiki-materialization-entry-source-kind-of)
   (source-path :initarg :source-path
                :initform nil
                :reader fedwiki-materialization-entry-source-path-of)
   (target-path :initarg :target-path
                :reader fedwiki-materialization-entry-target-path-of)
   (page-data :initarg :page-data
              :reader fedwiki-materialization-entry-page-data-of)
   (action :initarg :action
           :accessor fedwiki-materialization-entry-action-of)
   (existing-p :initarg :existing-p
               :initform nil
               :reader fedwiki-materialization-entry-existing-p)
   (selector :initarg :selector
             :initform nil
             :reader fedwiki-materialization-entry-selector-of)))

(defclass fedwiki-materialization-plan ()
  ((mode :initarg :mode :reader fedwiki-materialization-mode-of)
   (selector :initarg :selector :reader fedwiki-materialization-selector-of)
   (entries :initarg :entries :accessor fedwiki-materialization-entries-of)
   (description :initarg :description
                :initform nil
                :reader fedwiki-materialization-description-of)
   (hyperdoc-repo-root :initarg :hyperdoc-repo-root
                       :reader fedwiki-materialization-hyperdoc-repo-root-of)
   (fedwiki-repo-root :initarg :fedwiki-repo-root
                      :reader fedwiki-materialization-fedwiki-repo-root-of)
   (fedwiki-pages-directory :initarg :fedwiki-pages-directory
                            :reader fedwiki-materialization-fedwiki-pages-directory-of)
   (expected-hyperdoc-branch :initarg :expected-hyperdoc-branch
                             :reader fedwiki-materialization-expected-hyperdoc-branch-of)
   (expected-fedwiki-branch :initarg :expected-fedwiki-branch
                            :reader fedwiki-materialization-expected-fedwiki-branch-of)
   (execution-report :initarg :execution-report
                     :initform nil
                     :accessor fedwiki-materialization-execution-report-of)))

(defmethod print-object ((entry fedwiki-materialization-entry) stream)
  (print-unreadable-object (entry stream :type t)
    (format stream "~A ~A"
            (string-downcase
             (symbol-name (fedwiki-materialization-entry-action-of entry)))
            (fedwiki-materialization-entry-slug-of entry))))

(defmethod print-object ((plan fedwiki-materialization-plan) stream)
  (print-unreadable-object (plan stream :type t)
    (format stream "~A ~A (~D entries)"
            (string-downcase
             (symbol-name (fedwiki-materialization-mode-of plan)))
            (fedwiki-materialization-selector-of plan)
            (length (fedwiki-materialization-entries-of plan)))))

(defun fedwiki-materialization-testdata-root ()
  (merge-pathnames "tools/testdata/article-allegation-slice/"
                   (article-allegation-source-root)))

(defun fedwiki-materialization-read-form (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (read stream nil nil)))

(defun fedwiki-materialization-metadata-paths
    (&key (root (fedwiki-materialization-testdata-root)))
  (directory (merge-pathnames "*/slice-metadata.lisp"
                              (uiop:ensure-directory-pathname root))))

(defun fedwiki-materialization-spec-paths
    (&key (root (fedwiki-materialization-testdata-root)))
  (directory (merge-pathnames "*.lisp"
                              (uiop:ensure-directory-pathname root))))

(defun fedwiki-materialization-bundle-root-from-metadata-path (path)
  (uiop:pathname-directory-pathname path))

(defun fedwiki-materialization-dry-run-bundles
    (&key (root (fedwiki-materialization-testdata-root)))
  (loop for metadata-path in (fedwiki-materialization-metadata-paths :root root)
        collect (list :metadata-path metadata-path
                      :root (fedwiki-materialization-bundle-root-from-metadata-path metadata-path)
                      :metadata (fedwiki-materialization-read-form metadata-path))))

(defun fedwiki-materialization-find-bundle-by-slice-id
    (slice-id &key (root (fedwiki-materialization-testdata-root)))
  (find slice-id
        (fedwiki-materialization-dry-run-bundles :root root)
        :key (lambda (bundle) (getf (getf bundle :metadata) :slice-id))
        :test #'equal))

(defun fedwiki-materialization-find-spec-by-slice-id
    (slice-id &key (root (fedwiki-materialization-testdata-root)))
  (find slice-id
        (fedwiki-materialization-spec-paths :root root)
        :key (lambda (path)
               (ignore-errors
                 (getf (read-article-allegation-slice-input path) :slice-id)))
        :test #'equal))

(defun fedwiki-materialization-bundle-path (bundle relative-path)
  (merge-pathnames relative-path
                   (getf bundle :root)))

(defun fedwiki-materialization-source-page-from-bundle (bundle slug)
  (let ((source-path (fedwiki-materialization-bundle-path
                      bundle
                      (format nil "fedwiki-pages/~A" slug))))
    (when (uiop:file-exists-p source-path)
      (list :source-kind :dry-run-fedwiki-page
            :source-path source-path
            :page-data (article-allegation-read-json-file source-path)))))

(defun fedwiki-materialization-locate-bundle-source-for-slug
    (slug &key (root (fedwiki-materialization-testdata-root)))
  (loop for bundle in (fedwiki-materialization-dry-run-bundles :root root)
        for source = (fedwiki-materialization-source-page-from-bundle bundle slug)
        when source
        do (return (append source
                           (list :bundle-root (getf bundle :root)
                                 :slice-id (getf (getf bundle :metadata) :slice-id))))))

(defun fedwiki-materialization-topic-fedwiki-page (topic &key (start-date 1773393295339))
  (article-allegation-make-page-with-journal
   (title-of topic)
   (article-allegation-page-story-items
    1
    (summary-of topic)
    (mapcar #'article-allegation-fedwiki-reference
            (or (references-of topic) '())))
   :start-date start-date))

(defun fedwiki-materialization-topic-source-for-slug (slug)
  (when-let (topic (find-topic-by-id slug))
    (list :source-kind :topic-fedwiki-page
          :source-path nil
          :page-data (fedwiki-materialization-topic-fedwiki-page topic)
          :topic topic)))

(defun fedwiki-materialization-daily-entry-action (target-path source-page)
  (if (uiop:file-exists-p target-path)
      (let* ((existing-page (article-allegation-read-json-file target-path))
             (item-text (getf (first (getf source-page :story)) :text))
             (existing-item
              (find item-text
                    (getf existing-page :story)
                    :key (lambda (item) (getf item :text))
                    :test #'equal)))
        (if existing-item :already-present :append))
      :create))

(defun fedwiki-materialization-entry-action
    (kind target-path source-page)
  (if (eq kind :daily-anchor)
      (fedwiki-materialization-daily-entry-action target-path source-page)
      (if (uiop:file-exists-p target-path) :already-present :create)))

(defun fedwiki-materialization-entry
    (&key kind slug title source-kind source-path target-path page-data selector)
  (make-instance 'fedwiki-materialization-entry
                 :kind kind
                 :slug slug
                 :title title
                 :source-kind source-kind
                 :source-path source-path
                 :target-path target-path
                 :page-data page-data
                 :selector selector
                 :existing-p (if (uiop:file-exists-p target-path) t nil)
                 :action (fedwiki-materialization-entry-action kind target-path page-data)))

(defun fedwiki-materialization-plan-summary (plan)
  (let ((creates 0)
        (appends 0)
        (existing 0))
    (dolist (entry (fedwiki-materialization-entries-of plan))
      (case (fedwiki-materialization-entry-action-of entry)
        (:create (incf creates))
        (:append (incf appends))
        (:already-present (incf existing))))
    (list :creates creates
          :appends appends
          :already-present existing
          :entries (length (fedwiki-materialization-entries-of plan)))))

(defun fedwiki-materialization-description (mode selector)
  (ecase mode
    (:page
     (format nil "Plan live FedWiki materialization for page slug ~A." selector))
    (:slice
     (format nil "Plan live FedWiki materialization for slice ~A." selector))))

(defun fedwiki-materialization-plan
    (mode selector entries
     &key
       (hyperdoc-repo-root (article-allegation-source-root))
       (fedwiki-repo-root (article-allegation-default-fedwiki-pages-directory))
       (fedwiki-pages-directory (article-allegation-default-fedwiki-pages-directory))
       (expected-hyperdoc-branch "hauptsache")
       (expected-fedwiki-branch "localhost"))
  (make-instance 'fedwiki-materialization-plan
                 :mode mode
                 :selector selector
                 :entries entries
                 :description (fedwiki-materialization-description mode selector)
                 :hyperdoc-repo-root (uiop:ensure-directory-pathname hyperdoc-repo-root)
                 :fedwiki-repo-root (uiop:ensure-directory-pathname fedwiki-repo-root)
                 :fedwiki-pages-directory
                 (uiop:ensure-directory-pathname fedwiki-pages-directory)
                 :expected-hyperdoc-branch expected-hyperdoc-branch
                 :expected-fedwiki-branch expected-fedwiki-branch))

(defun fedwiki-materialization-live-target-path (slug fedwiki-pages-directory)
  (merge-pathnames slug
                   (uiop:ensure-directory-pathname fedwiki-pages-directory)))

(defun fedwiki-materialization-plan-entry-from-bundle-source
    (source slug selector fedwiki-pages-directory)
  (let* ((page (getf source :page-data))
         (title (getf page :title))
         (kind (if (every #'digit-char-p slug) :daily-anchor :page)))
    (fedwiki-materialization-entry
     :kind kind
     :slug slug
     :title title
     :source-kind (getf source :source-kind)
     :source-path (getf source :source-path)
     :target-path (fedwiki-materialization-live-target-path slug fedwiki-pages-directory)
     :page-data page
     :selector selector)))

(defun fedwiki-materialization-plan-entry-from-topic-source
    (source slug selector fedwiki-pages-directory)
  (let* ((topic (getf source :topic))
         (page (getf source :page-data)))
    (fedwiki-materialization-entry
     :kind :page
     :slug slug
     :title (title-of topic)
     :source-kind (getf source :source-kind)
     :source-path nil
     :target-path (fedwiki-materialization-live-target-path slug fedwiki-pages-directory)
     :page-data page
     :selector selector)))

(defun plan-fedwiki-page-materialization
    (slug &key
            (fedwiki-pages-directory (article-allegation-default-fedwiki-pages-directory))
            (fedwiki-repo-root (article-allegation-default-fedwiki-pages-directory))
            (hyperdoc-repo-root (article-allegation-source-root))
            (expected-hyperdoc-branch "hauptsache")
            (expected-fedwiki-branch "localhost"))
  (let* ((slug (article-allegation-non-empty-string slug))
         (bundle-source (fedwiki-materialization-locate-bundle-source-for-slug slug))
         (topic-source (unless bundle-source
                         (fedwiki-materialization-topic-source-for-slug slug)))
         (entry
          (cond
            (bundle-source
             (fedwiki-materialization-plan-entry-from-bundle-source
              bundle-source slug slug fedwiki-pages-directory))
            (topic-source
             (fedwiki-materialization-plan-entry-from-topic-source
              topic-source slug slug fedwiki-pages-directory))
            (t
             (error "No generated slice artifact or topic-driven FedWiki twin for slug ~S"
                    slug)))))
    (fedwiki-materialization-plan
     :page
     slug
     (list entry)
     :hyperdoc-repo-root hyperdoc-repo-root
     :fedwiki-repo-root fedwiki-repo-root
     :fedwiki-pages-directory fedwiki-pages-directory
     :expected-hyperdoc-branch expected-hyperdoc-branch
     :expected-fedwiki-branch expected-fedwiki-branch)))

(defun fedwiki-materialization-entries-from-rendered-bundle
    (bundle selector fedwiki-pages-directory include-daily-anchor-p)
  (append
   (loop for page in (getf bundle :fedwiki-files)
         collect (fedwiki-materialization-entry
                  :kind :page
                  :slug (getf page :slug)
                  :title (getf (getf page :page) :title)
                  :source-kind :rendered-slice-fedwiki-page
                  :source-path nil
                  :target-path (fedwiki-materialization-live-target-path
                                (getf page :slug)
                                fedwiki-pages-directory)
                  :page-data (getf page :page)
                  :selector selector))
   (when (and include-daily-anchor-p
              (getf bundle :daily-page))
     (let ((daily (getf bundle :daily-page)))
       (list (fedwiki-materialization-entry
              :kind :daily-anchor
              :slug (getf daily :title)
              :title (getf daily :title)
              :source-kind :rendered-slice-daily-anchor
              :source-path nil
              :target-path (fedwiki-materialization-live-target-path
                            (getf daily :title)
                            fedwiki-pages-directory)
              :page-data (getf daily :page)
              :selector selector))))))

(defun fedwiki-materialization-entries-from-dry-run-bundle
    (bundle selector fedwiki-pages-directory include-daily-anchor-p)
  (let* ((metadata (getf bundle :metadata))
         (page-slugs
          (append (list (getf metadata :incident-fedwiki-slug))
                  (copy-list (or (getf metadata :concept-fedwiki-slugs) '()))))
         (daily-slug (and include-daily-anchor-p
                          (getf metadata :daily-anchor-target))))
    (append
     (loop for slug in page-slugs
           for source = (fedwiki-materialization-source-page-from-bundle bundle slug)
           when source
           collect (fedwiki-materialization-plan-entry-from-bundle-source
                    source slug selector fedwiki-pages-directory))
     (when daily-slug
       (when-let (source (fedwiki-materialization-source-page-from-bundle bundle daily-slug))
         (list (fedwiki-materialization-plan-entry-from-bundle-source
                source daily-slug selector fedwiki-pages-directory)))))))

(defun plan-fedwiki-slice-materialization
    (slice-id &key
                (include-daily-anchor-p nil)
                (fedwiki-pages-directory (article-allegation-default-fedwiki-pages-directory))
                (fedwiki-repo-root (article-allegation-default-fedwiki-pages-directory))
                (hyperdoc-repo-root (article-allegation-source-root))
                (expected-hyperdoc-branch "hauptsache")
                (expected-fedwiki-branch "localhost"))
  (let* ((slice-id (article-allegation-non-empty-string slice-id))
         (bundle (fedwiki-materialization-find-bundle-by-slice-id slice-id))
         (entries
          (cond
            (bundle
             (fedwiki-materialization-entries-from-dry-run-bundle
              bundle slice-id fedwiki-pages-directory include-daily-anchor-p))
            ((fedwiki-materialization-find-spec-by-slice-id slice-id)
             (fedwiki-materialization-entries-from-rendered-bundle
              (render-article-allegation-slice-bundle
               (fedwiki-materialization-find-spec-by-slice-id slice-id))
              slice-id
              fedwiki-pages-directory
              include-daily-anchor-p))
            (t
             (error "No dry-run bundle or article allegation spec found for slice ~S"
                    slice-id)))))
    (fedwiki-materialization-plan
     :slice
     slice-id
     entries
     :hyperdoc-repo-root hyperdoc-repo-root
     :fedwiki-repo-root fedwiki-repo-root
     :fedwiki-pages-directory fedwiki-pages-directory
     :expected-hyperdoc-branch expected-hyperdoc-branch
     :expected-fedwiki-branch expected-fedwiki-branch)))

(defun print-fedwiki-materialization-plan (plan &key (stream *standard-output*))
  (let ((summary (fedwiki-materialization-plan-summary plan)))
    (format stream "FedWiki materialization plan~%~%")
    (format stream "Mode: ~(~A~)~%" (fedwiki-materialization-mode-of plan))
    (format stream "Selector: ~A~%" (fedwiki-materialization-selector-of plan))
    (format stream "HyperDoc branch: ~A~%" (fedwiki-materialization-expected-hyperdoc-branch-of plan))
    (format stream "FedWiki branch: ~A~%" (fedwiki-materialization-expected-fedwiki-branch-of plan))
    (format stream "Creates: ~D  Appends: ~D  Already present: ~D~%~%"
            (getf summary :creates)
            (getf summary :appends)
            (getf summary :already-present))
    (dolist (entry (fedwiki-materialization-entries-of plan))
      (format stream "~A ~A ~S~%"
              (string-upcase
               (symbol-name (fedwiki-materialization-entry-action-of entry)))
              (fedwiki-materialization-entry-slug-of entry)
              (fedwiki-materialization-entry-title-of entry))
      (format stream "  source-kind=~A~%"
              (fedwiki-materialization-entry-source-kind-of entry))
      (when-let (source-path (fedwiki-materialization-entry-source-path-of entry))
        (format stream "  source=~A~%" source-path))
      (format stream "  target=~A~%"
              (fedwiki-materialization-entry-target-path-of entry))))
  plan)

(defun fedwiki-materialization-assert-live-branches (plan)
  (let ((expected-hyperdoc-branch
         (fedwiki-materialization-expected-hyperdoc-branch-of plan))
        (expected-fedwiki-branch
         (fedwiki-materialization-expected-fedwiki-branch-of plan)))
    (when expected-hyperdoc-branch
      (let ((hyperdoc-branch
             (article-allegation-git-branch
              (fedwiki-materialization-hyperdoc-repo-root-of plan))))
        (unless (string= hyperdoc-branch expected-hyperdoc-branch)
          (error "HyperDoc repo branch mismatch: expected ~S, got ~S"
                 expected-hyperdoc-branch
                 hyperdoc-branch))))
    (when expected-fedwiki-branch
      (let ((fedwiki-branch
             (article-allegation-git-branch
              (fedwiki-materialization-fedwiki-pages-directory-of plan))))
        (unless (string= fedwiki-branch expected-fedwiki-branch)
          (error "FedWiki repo branch mismatch: expected ~S, got ~S"
                 expected-fedwiki-branch
                 fedwiki-branch))))))

(defun fedwiki-materialization-entry-item-text (entry)
  (let ((story (getf (fedwiki-materialization-entry-page-data-of entry) :story)))
    (and story
         (getf (first story) :text))))

(defun fedwiki-materialization-validate-target-path (path)
  (let ((page (article-allegation-read-json-file path)))
    (unless (journalmatic-commit-gate-pass-p page)
      (error "Journal gate failed for written page ~A with findings ~S"
             path
             (journalmatic-commit-gate-findings page)))
    path))

(defun fedwiki-materialization-write-entry! (entry)
  (let ((target-path (fedwiki-materialization-entry-target-path-of entry)))
    (case (fedwiki-materialization-entry-action-of entry)
      (:already-present
       (list :slug (fedwiki-materialization-entry-slug-of entry)
             :action :already-present
             :target-path target-path))
      (:create
       (article-allegation-write-json-file
        target-path
        (fedwiki-materialization-entry-page-data-of entry))
       (fedwiki-materialization-validate-target-path target-path)
       (list :slug (fedwiki-materialization-entry-slug-of entry)
             :action :create
             :target-path target-path))
      (:append
       (let* ((existing-page (article-allegation-read-json-file target-path))
              (item (copy-tree
                     (first (getf (fedwiki-materialization-entry-page-data-of entry) :story))))
              (new-id (format nil "~16,'0x"
                              (journalmatic-next-date-like-wiki-client
                               (getf existing-page :journal)))))
         (setf (getf item :id) new-id)
         (let ((updated (article-allegation-append-item-to-page existing-page item)))
           (article-allegation-write-json-file target-path updated)
           (fedwiki-materialization-validate-target-path target-path)
           (list :slug (fedwiki-materialization-entry-slug-of entry)
                 :action :append
                 :target-path target-path))))
      (otherwise
       (error "Unsupported materialization action ~S"
              (fedwiki-materialization-entry-action-of entry))))))

(defun materialize-fedwiki-materialization-plan (plan)
  (fedwiki-materialization-assert-live-branches plan)
  (let ((report
         (loop for entry in (fedwiki-materialization-entries-of plan)
               collect (fedwiki-materialization-write-entry! entry))))
    (setf (fedwiki-materialization-execution-report-of plan) report)
    plan))

(defexample fedwiki-materialization-page-preview-example
    (:system "hyperdoc")
    "Plan materialization of the missing civilian-casualty-mitigation FedWiki page."
  (let ((plan (plan-fedwiki-page-materialization "civilian-casualty-mitigation")))
    (assert-equal 1 (length (fedwiki-materialization-entries-of plan)))
    plan))

(defexample fedwiki-materialization-slice-preview-example
    (:system "hyperdoc")
    "Plan slice-level materialization for the Minab article-allegation dry-run bundle."
  (let ((plan (plan-fedwiki-slice-materialization
               "minab-school-strike"
               :include-daily-anchor-p t)))
    (assert-equal "minab-school-strike"
                  (fedwiki-materialization-selector-of plan))
    plan))



;;;; Remote FedWiki fork materialization
;;;; Filed out from the live image during Zettel 9124.

(defun fedwiki-materialization-json-slot (json string-key keyword-key)
  "Return JSON slot STRING-KEY / KEYWORD-KEY from a hash-table or plist-like object."
  (cond
    ((hash-table-p json)
     (or (gethash string-key json)
         (gethash keyword-key json)))
    ((listp json)
     (or (getf json keyword-key)
         (getf json (intern (string-upcase string-key) :keyword))))
    (t nil)))

(defun (setf fedwiki-materialization-json-slot)
    (value json string-key keyword-key)
  "Set JSON slot STRING-KEY / KEYWORD-KEY on a hash-table or plist-like object."
  (cond
    ((hash-table-p json)
     (setf (gethash string-key json) value))
    ((listp json)
     (setf (getf json keyword-key) value))
    (t
     (error "Cannot set JSON slot ~S / ~S on ~S"
            string-key keyword-key json))))

(defun fedwiki-materialization-json-sequence-list (sequence)
  "Return SEQUENCE as a list, accepting vectors and lists but not strings."
  (cond
    ((null sequence) nil)
    ((and (vectorp sequence)
          (not (stringp sequence)))
     (loop for item across sequence collect item))
    ((and (listp sequence)
          (not (stringp sequence)))
     sequence)
    (t
     (error "Expected JSON sequence, got ~S" sequence))))

(defun fedwiki-materialization-copy-json (value)
  "Deep-copy the JSON-like structures used by HyperDoc FedWiki pages."
  (cond
    ((hash-table-p value)
     (let ((copy (make-hash-table :test (hash-table-test value))))
       (loop for key being the hash-keys of value
             using (hash-value subvalue)
             do (setf (gethash key copy)
                      (fedwiki-materialization-copy-json subvalue)))
       copy))
    ((and (vectorp value)
          (not (stringp value)))
     (coerce
      (loop for item across value
            collect (fedwiki-materialization-copy-json item))
      'vector))
    ((consp value)
     (copy-tree value))
    (t value)))

(defun fedwiki-materialization-append-json-sequence (sequence item)
  "Append ITEM to SEQUENCE, preserving vector-vs-list representation."
  (let ((items
          (append (fedwiki-materialization-json-sequence-list sequence)
                  (list item))))
    (if (vectorp sequence)
        (coerce items 'vector)
        items)))

(defun fedwiki-materialization-json-object-keys (json)
  "Return JSON object keys for hash-table or plist-like JSON objects."
  (cond
    ((hash-table-p json)
     (loop for key being the hash-keys of json collect key))
    ((listp json)
     (loop for (key value) on json by #'cddr
           collect key))
    (t nil)))

(defun fedwiki-materialization-canonical-fork-action-key-p (key)
  "Return true when KEY is one of the canonical fork journal action keys."
  (member key
          '("type" "site" "date" :type :site :date)
          :test #'equal))

(defun fedwiki-materialization-make-explicit-fork-action
    (&key site date)
  "Return the canonical FedWiki fork journal action."
  (unless (and (stringp site)
               (> (length site) 0))
    (error "Missing source site for fork action: ~S" site))
  (unless (numberp date)
    (error "Missing numeric fork action date: ~S" date))
  (list :type "fork"
        :site site
        :date date))

(defun fedwiki-materialization-canonical-fork-action-p (action)
  "Return true when ACTION is a canonical FedWiki fork action."
  (and (equal (fedwiki-materialization-json-slot action "type" :type)
              "fork")
       (stringp
        (fedwiki-materialization-json-slot action "site" :site))
       (numberp
        (fedwiki-materialization-json-slot action "date" :date))
       (every #'fedwiki-materialization-canonical-fork-action-key-p
              (fedwiki-materialization-json-object-keys action))))

(defun fedwiki-materialization-page-story-item-ids (page)
  "Return the story item ids of PAGE, preserving story order."
  (loop for item in
        (fedwiki-materialization-json-sequence-list
         (fedwiki-materialization-json-slot page "story" :story))
        collect
        (fedwiki-materialization-json-slot item "id" :id)))

(defun fedwiki-materialization-page-with-appended-fork-action
    (remote-page fork-action)
  "Return a local fork candidate copied from REMOTE-PAGE.

The operation preserves the page title, story item ids, story order, and source
journal entries. It appends FORK-ACTION as the final journal action. It does not
write the page, does not normalize plugin items, and does not add HyperDoc-only
provenance to the canonical page JSON."
  (unless remote-page
    (error "Missing remote page JSON."))
  (unless (fedwiki-materialization-canonical-fork-action-p fork-action)
    (error "Not a canonical FedWiki fork action: ~S" fork-action))
  (let* ((copy
           (fedwiki-materialization-copy-json remote-page))
         (journal
           (fedwiki-materialization-json-slot copy "journal" :journal))
         (new-journal
           (fedwiki-materialization-append-json-sequence
            journal
            (fedwiki-materialization-copy-json fork-action))))
    (setf (fedwiki-materialization-json-slot copy "journal" :journal)
          new-journal)
    copy))
