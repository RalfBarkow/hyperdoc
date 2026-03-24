;;;; Zotero-backed bibliography source implementation
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass zotero-bibliography-source (bibliography-source)
  ((bridge :reader bibliography-source-bridge-of
           :initarg :bridge)))

(defclass zotero-collection-hit (bibliography-collection-hit) ())

(defclass zotero-collection-query (zotero-query-evidence)
  ((bridge :reader zotero-collection-query-bridge-of :initarg :bridge)
   (query-text :reader zotero-collection-query-text-of :initarg :query-text)
   (matched-collections :reader zotero-collection-query-matched-collections-of
                        :initarg :matched-collections
                        :initform nil)))

(defun zotero-collection-id-of (collection)
  (bibliography-collection-id-of collection))

(defun zotero-collection-key-of (collection)
  (bibliography-collection-key-of collection))

(defun zotero-collection-name-of (collection)
  (bibliography-collection-name-of collection))

(defun zotero-collection-path-of (collection)
  (bibliography-collection-path-of collection))

(defun zotero-collection-path-components-of (collection)
  (bibliography-collection-path-components-of collection))

(defun zotero-collection-parent-id-of (collection)
  (bibliography-collection-parent-id-of collection))

(defun zotero-collection-library-id-of (collection)
  (bibliography-collection-library-id-of collection))

(defun zotero-collection-raw-row-of (collection)
  (bibliography-collection-raw-row-of collection))

(defmethod print-object ((object zotero-bibliography-source) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A"
            (or (pathname-namestring-or-nil
                 (zotero-db-path-of (bibliography-source-bridge-of object)))
                "<no zotero db>"))))

(defun make-zotero-bibliography-source
    (&key (bridge (make-default-zotero-library-bridge))
       (default-collection *bibliography-default-main-page-id*)
       (materialization-root *bibliography-default-materialization-root*))
  (make-instance 'zotero-bibliography-source
                 :source-system :zotero
                 :bridge bridge
                 :default-collection default-collection
                 :materialization-root
                 (uiop:ensure-directory-pathname materialization-root)
                 :description "Read-only Zotero bibliography source for HyperDoc collection import and authoring plans."))

(defun make-default-bibliography-source ()
  (make-zotero-bibliography-source))

(defun zotero-collection-query-sql (query-text)
  (let ((literal (sql-string-literal (lowercase-string query-text))))
    (format nil
            "WITH RECURSIVE collection_paths AS (
               SELECT c.collectionID,
                      c.collectionName,
                      c.parentCollectionID,
                      c.libraryID,
                      c.key AS collectionKey,
                      c.collectionName AS collectionPath
               FROM collections c
               WHERE c.parentCollectionID IS NULL
               UNION ALL
               SELECT c.collectionID,
                      c.collectionName,
                      c.parentCollectionID,
                      c.libraryID,
                      c.key AS collectionKey,
                      cp.collectionPath || ' / ' || c.collectionName AS collectionPath
               FROM collections c
               JOIN collection_paths cp ON cp.collectionID = c.parentCollectionID
             )
             SELECT collectionID,
                    collectionName,
                    parentCollectionID,
                    libraryID,
                    collectionKey,
                    collectionPath
             FROM collection_paths
             WHERE lower(collectionPath) = ~A
                OR lower(collectionName) = ~A
             ORDER BY CASE WHEN lower(collectionPath) = ~A THEN 0 ELSE 1 END,
                      length(collectionPath),
                      collectionID;"
            literal literal literal)))

(defun zotero-collection-items-query-sql (collection-id)
  (format nil
          "WITH item_fields AS (
             SELECT id.itemID,
                    max(CASE WHEN f.fieldName = 'title' THEN v.value END) AS title,
                    max(CASE WHEN f.fieldName = 'date' THEN v.value END) AS dateValue,
                    max(CASE WHEN f.fieldName = 'DOI' THEN v.value END) AS doi,
                    max(CASE WHEN f.fieldName = 'url' THEN v.value END) AS url,
                    max(CASE WHEN f.fieldName = 'abstractNote' THEN v.value END) AS notes,
                    max(CASE WHEN f.fieldName = 'publicationTitle' THEN v.value END) AS publicationTitle,
                    max(CASE WHEN f.fieldName = 'bookTitle' THEN v.value END) AS bookTitle,
                    max(CASE WHEN f.fieldName = 'proceedingsTitle' THEN v.value END) AS proceedingsTitle,
                    max(CASE WHEN f.fieldName = 'websiteTitle' THEN v.value END) AS websiteTitle,
                    max(CASE WHEN f.fieldName = 'blogTitle' THEN v.value END) AS blogTitle,
                    max(CASE WHEN f.fieldName = 'publisher' THEN v.value END) AS publisher
             FROM itemData id
             JOIN itemDataValues v ON v.valueID = id.valueID
             JOIN fields f ON f.fieldID = id.fieldID
             GROUP BY id.itemID
           )
           SELECT i.itemID,
                  i.key AS itemKey,
                  t.typeName,
                  f.title,
                  f.dateValue,
                  f.doi,
                  f.url,
                  f.notes,
                  coalesce(f.publicationTitle,
                           f.bookTitle,
                           f.proceedingsTitle,
                           f.websiteTitle,
                           f.blogTitle,
                           f.publisher) AS venue
           FROM collectionItems ci
           JOIN items i ON i.itemID = ci.itemID
           JOIN itemTypes t ON t.itemTypeID = i.itemTypeID
           LEFT JOIN item_fields f ON f.itemID = i.itemID
           WHERE ci.collectionID = ~D
             AND t.typeName NOT IN ('attachment', 'note')
           ORDER BY lower(coalesce(f.title, '')), i.itemID;"
          collection-id))

(defun zotero-collection-authors-query-sql (collection-id)
  (format nil
          "SELECT ic.itemID,
                  ic.orderIndex,
                  ct.creatorType,
                  c.firstName,
                  c.lastName,
                  c.fieldMode
           FROM collectionItems ci
           JOIN itemCreators ic ON ic.itemID = ci.itemID
           JOIN creators c ON c.creatorID = ic.creatorID
           JOIN creatorTypes ct ON ct.creatorTypeID = ic.creatorTypeID
           WHERE ci.collectionID = ~D
           ORDER BY ic.itemID, ic.orderIndex;"
          collection-id))

(defun zotero-collection-tags-query-sql (collection-id)
  (format nil
          "SELECT it.itemID,
                  tg.name AS tagName
           FROM collectionItems ci
           JOIN itemTags it ON it.itemID = ci.itemID
           JOIN tags tg ON tg.tagID = it.tagID
           WHERE ci.collectionID = ~D
           ORDER BY it.itemID, lower(tg.name);"
          collection-id))

(defun make-zotero-collection-hit (row)
  (let ((path (gethash "collectionPath" row)))
    (make-instance 'zotero-collection-hit
                   :collection-id (gethash "collectionID" row)
                   :collection-key (gethash "collectionKey" row)
                   :collection-name (gethash "collectionName" row)
                   :collection-path path
                   :path-components (uiop:split-string path :separator " / ")
                   :parent-collection-id (gethash "parentCollectionID" row)
                   :library-id (gethash "libraryID" row)
                   :raw-row row)))

(defun lookup-zotero-collection (query-text &key (source (make-default-bibliography-source))
                                            signal-error?)
  (let* ((bridge (bibliography-source-bridge-of source))
         (query (run-zotero-sqlite-query
                 bridge
                 "zotero-collection-lookup"
                 (zotero-collection-query-sql query-text)))
         (selected-attempt
           (normalize-zotero-query-attempt
            query
            :attempted-operation 'zotero-query-attempt-rows-of
            :receiver (zotero-query-selected-attempt-of query)
            :higher-level-intent `(lookup-zotero-collection ,query-text)
            :repair-hint
            "Check the configured Zotero DB path or disable the live Zotero source."))
         (collections
           (mapcar #'make-zotero-collection-hit
                   (zotero-query-protocol-rows-of selected-attempt)))
         (wrapped-query
           (make-instance 'zotero-collection-query
                          :bridge bridge
                          :name "zotero-collection-lookup"
                          :query-text query-text
                          :sql (zotero-query-sql-of query)
                          :attempts (zotero-query-attempts-of query)
                          :selected-attempt (zotero-query-selected-attempt-of query)
                          :matched-collections collections)))
    (cond
      ((typep selected-attempt 'zotero-query-missing-attempt)
       (when signal-error?
         (error "Zotero collection lookup for ~S failed: ~A"
                query-text
                (or (zotero-query-protocol-detail-of selected-attempt)
                    "no query detail")))
       (values nil wrapped-query))
      ((null collections)
       (when signal-error?
         (error "No Zotero bibliography subcollection matched ~S." query-text))
       (values nil wrapped-query))
      ((and (> (length collections) 1)
            (null (find query-text collections
                        :key #'zotero-collection-path-of
                        :test #'string-equal)))
       (when signal-error?
         (error "Ambiguous Zotero bibliography subcollection ~S (~D matches)."
                query-text
                (length collections)))
       (values nil wrapped-query))
      (t
       (values (or (find query-text collections
                         :key #'zotero-collection-path-of
                         :test #'string-equal)
                   (first collections))
               wrapped-query)))))

(defun bibliography-zotero-load-stage-label (stage)
  (case stage
    (:collection-query "collection lookup")
    (:entry-query "entry import")
    (:author-query "author import")
    (:tag-query "tag import")
    (otherwise
     (string-downcase
      (substitute #\Space #\- (symbol-name stage))))))

(defun make-zotero-bibliography-load-failure
    (query-text source stage &key collection-query entry-query author-query tag-query failed-attempt)
  (let* ((failed-query (or (and (zotero-query-failed-p collection-query) collection-query)
                           (and (zotero-query-failed-p entry-query) entry-query)
                           (and (zotero-query-failed-p author-query) author-query)
                           (and (zotero-query-failed-p tag-query) tag-query)))
         (detail (or (and failed-attempt
                          (zotero-query-protocol-detail-of failed-attempt))
                     (and failed-query
                          (zotero-query-failure-detail failed-query))
                     "Zotero query failed without detail."))
         (message (format nil
                          "Bibliography subcollection ~S could not be loaded from Zotero during ~A."
                          query-text
                          (bibliography-zotero-load-stage-label stage))))
    (make-instance 'bibliography-subcollection-load-failure
                   :source source
                   :source-system (bibliography-source-system-of source)
                   :query-text query-text
                   :stage stage
                   :message message
                   :detail detail
                   :failed-attempt failed-attempt
                   :failed-query failed-query
                   :collection-query collection-query
                   :entry-query entry-query
                   :author-query author-query
                   :tag-query tag-query)))

(defun author-name-from-row (row)
  (let ((field-mode (gethash "fieldMode" row))
        (first-name (gethash "firstName" row))
        (last-name (gethash "lastName" row)))
    (if (and field-mode (= field-mode 1))
        (or last-name first-name "")
        (collapse-whitespace
         (format nil "~@[~A ~]~A"
                 first-name
                 (or last-name ""))))))

(defun bibliography-entry-raw-text (item-row author-rows tag-rows collection-hit)
  (with-output-to-string (stream)
    (format stream "source-system: Zotero~%")
    (format stream "collection-path: ~A~%" (zotero-collection-path-of collection-hit))
    (format stream "item-id: ~A~%" (gethash "itemID" item-row))
    (format stream "item-key: ~A~%" (gethash "itemKey" item-row))
    (format stream "title: ~A~%" (or (gethash "title" item-row) ""))
    (format stream "type: ~A~%" (or (gethash "typeName" item-row) ""))
    (format stream "authors: ~{~A~^; ~}~%"
            (mapcar #'author-name-from-row author-rows))
    (format stream "date: ~A~%" (or (gethash "dateValue" item-row) ""))
    (format stream "venue: ~A~%" (or (gethash "venue" item-row) ""))
    (format stream "doi: ~A~%" (or (gethash "doi" item-row) ""))
    (format stream "url: ~A~%" (or (gethash "url" item-row) ""))
    (format stream "notes: ~A~%" (or (gethash "notes" item-row) ""))
    (format stream "tags: ~{~A~^; ~}" (mapcar (lambda (row) (gethash "tagName" row)) tag-rows))))

(defun make-bibliography-entry (item-row author-rows tag-rows collection-hit)
  (make-instance 'bibliography-entry
                 :source-system :zotero
                 :collection-name (zotero-collection-name-of collection-hit)
                 :collection-path (zotero-collection-path-of collection-hit)
                 :collection-key (zotero-collection-key-of collection-hit)
                 :item-id (gethash "itemID" item-row)
                 :item-key (gethash "itemKey" item-row)
                 :title (gethash "title" item-row)
                 :authors (remove-if #'string-blank-p
                                     (mapcar #'author-name-from-row author-rows))
                 :year (parse-year-from-date-string (gethash "dateValue" item-row))
                 :work-type (gethash "typeName" item-row)
                 :venue (maybe-string (gethash "venue" item-row))
                 :doi (maybe-string (gethash "doi" item-row))
                 :url (maybe-string (gethash "url" item-row))
                 :notes (maybe-string (gethash "notes" item-row))
                 :tags (remove-if #'string-blank-p
                                  (mapcar (lambda (row) (gethash "tagName" row))
                                          tag-rows))
                 :raw-source-text (bibliography-entry-raw-text
                                   item-row author-rows tag-rows collection-hit)
                 :raw-row item-row
                 :author-rows author-rows
                 :tag-rows tag-rows))

(defun load-zotero-bibliography-subcollection
    (query-text &key (source (make-default-bibliography-source)) signal-error? output-root)
  (declare (ignore output-root))
  (multiple-value-bind (collection-hit collection-query)
      (lookup-zotero-collection query-text :source source :signal-error? signal-error?)
    (let ((collection-attempt
            (normalize-zotero-query-attempt
             collection-query
             :attempted-operation 'zotero-query-attempt-rows-of
             :receiver (and collection-query
                            (zotero-query-selected-attempt-of collection-query))
             :higher-level-intent `(lookup-zotero-collection ,query-text)
             :repair-hint
             "Check the configured Zotero DB path or disable the live Zotero source.")))
      (cond
      ((typep collection-attempt 'zotero-query-missing-attempt)
       (if signal-error?
           (error "~A ~A"
                  "Bibliography collection lookup failed."
                  (or (zotero-query-protocol-detail-of collection-attempt) ""))
           (make-zotero-bibliography-load-failure
            query-text
            source
            :collection-query
            :collection-query collection-query
            :failed-attempt collection-attempt)))
      ((null collection-hit)
       nil)
      (t
       (let* ((bridge (bibliography-source-bridge-of source))
              (item-query
                (run-zotero-sqlite-query
                 bridge
                 "zotero-bibliography-items"
                 (zotero-collection-items-query-sql
                  (zotero-collection-id-of collection-hit))))
              (author-query
                (run-zotero-sqlite-query
                 bridge
                 "zotero-bibliography-authors"
                 (zotero-collection-authors-query-sql
                  (zotero-collection-id-of collection-hit))))
              (tag-query
                (run-zotero-sqlite-query
                 bridge
                 "zotero-bibliography-tags"
                 (zotero-collection-tags-query-sql
                  (zotero-collection-id-of collection-hit))))
              (item-attempt
                (normalize-zotero-query-attempt
                 item-query
                 :attempted-operation 'zotero-query-attempt-rows-of
                 :receiver (zotero-query-selected-attempt-of item-query)
                 :higher-level-intent `(load-zotero-bibliography-subcollection ,query-text :entries)
                 :repair-hint
                 "Inspect the Zotero query evidence for item import."))
              (author-attempt
                (normalize-zotero-query-attempt
                 author-query
                 :attempted-operation 'zotero-query-attempt-rows-of
                 :receiver (zotero-query-selected-attempt-of author-query)
                 :higher-level-intent `(load-zotero-bibliography-subcollection ,query-text :authors)
                 :repair-hint
                 "Inspect the Zotero query evidence for author import."))
              (tag-attempt
                (normalize-zotero-query-attempt
                 tag-query
                 :attempted-operation 'zotero-query-attempt-rows-of
                 :receiver (zotero-query-selected-attempt-of tag-query)
                 :higher-level-intent `(load-zotero-bibliography-subcollection ,query-text :tags)
                 :repair-hint
                 "Inspect the Zotero query evidence for tag import.")))
         (cond
           ((typep item-attempt 'zotero-query-missing-attempt)
            (if signal-error?
                (error "~A ~A"
                       "Bibliography entry import failed."
                       (or (zotero-query-protocol-detail-of item-attempt) ""))
                (make-zotero-bibliography-load-failure
                 query-text
                 source
                 :entry-query
                 :collection-query collection-query
                 :entry-query item-query
                 :author-query author-query
                 :tag-query tag-query
                 :failed-attempt item-attempt)))
           ((typep author-attempt 'zotero-query-missing-attempt)
            (if signal-error?
                (error "~A ~A"
                       "Bibliography author import failed."
                       (or (zotero-query-protocol-detail-of author-attempt) ""))
                (make-zotero-bibliography-load-failure
                 query-text
                 source
                 :author-query
                 :collection-query collection-query
                 :entry-query item-query
                 :author-query author-query
                 :tag-query tag-query
                 :failed-attempt author-attempt)))
           ((typep tag-attempt 'zotero-query-missing-attempt)
            (if signal-error?
                (error "~A ~A"
                       "Bibliography tag import failed."
                       (or (zotero-query-protocol-detail-of tag-attempt) ""))
                (make-zotero-bibliography-load-failure
                 query-text
                 source
                 :tag-query
                 :collection-query collection-query
                 :entry-query item-query
                 :author-query author-query
                 :tag-query tag-query
                 :failed-attempt tag-attempt)))
           (t
            (let* ((author-rows (zotero-query-protocol-rows-of author-attempt))
                   (tag-rows (zotero-query-protocol-rows-of tag-attempt))
                   (authors-by-item (group-rows-by-key author-rows "itemID"))
                   (tags-by-item (group-rows-by-key tag-rows "itemID"))
                   (entries
                     (loop for row in (zotero-query-protocol-rows-of item-attempt)
                           collect (make-bibliography-entry
                                    row
                                    (gethash (gethash "itemID" row) authors-by-item)
                                    (gethash (gethash "itemID" row) tags-by-item)
                                    collection-hit)))
                   (subcollection
                     (make-instance 'bibliography-subcollection
                                    :hyperbook (ensure-bibliography-subcollections-hyperbook
                                                :source source)
                                    :id query-text
                                    :source source
                                    :source-system :zotero
                                    :query-text query-text
                                    :collection-hit collection-hit
                                    :collection-query collection-query
                                    :entry-query item-query
                                    :author-query author-query
                                    :tag-query tag-query
                                    :entries entries)))
              (setf (bibliography-subcollection-candidate-topics-of subcollection)
                    (ensure-bibliography-subcollection-candidate-topics subcollection))
              subcollection)))))))))

(defmethod load-bibliography-subcollection-using-source
    ((source zotero-bibliography-source) query-text &key signal-error? output-root)
  (load-zotero-bibliography-subcollection
   query-text
   :source source
   :signal-error? signal-error?
   :output-root output-root))
