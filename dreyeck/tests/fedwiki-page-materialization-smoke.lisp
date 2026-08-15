(in-package #:dreyeck/fedwiki-page-materialization/tests)

(defun make-source-page-json ()
  (let ((page
          (make-hash-table :test #'equal))
        (create-entry
          (make-hash-table :test #'equal)))
    (setf
     (gethash "title" page)
     "Materialization Example"

     (gethash "story" page)
     #()

     (gethash "type" create-entry)
     "create"

     (gethash "date" create-entry)
     1000

     (gethash "journal" page)
     (vector create-entry))

    page))

(defun make-test-site-root ()
  (let ((pathname
          (merge-pathnames
           (format nil
                   "dreyeck-fedwiki-page-materialization-~A/"
                   (symbol-name
                    (gensym "RUN-")))
           (uiop:temporary-directory))))
    (ensure-directories-exist pathname)
    (uiop:ensure-directory-pathname pathname)))

(defun run-fedwiki-page-materialization-tests ()
  (let* ((page-json
           (make-source-page-json))
         (source-journal
           (gethash "journal" page-json))
         (source-entry
           (aref source-journal 0))
         (site-root
           (make-test-site-root))
         (plain-slug
           "materialization-example")
         (fork-slug
           "materialization-fork-example")
         (source-site
           "source.example")
         (fork-date
           1786787819051))

    (unwind-protect
         (let* ((plain-target
                  (dreyeck/fedwiki-page-materialization:materialize-fedwiki-page-json
                   page-json
                   site-root
                   plain-slug))
                (plain-persisted
                  (dreyeck/fedwiki-assets:read-local-fedwiki-page
                   site-root
                   plain-slug))
                (plain-journal
                  (gethash "journal" plain-persisted))

                (fork-target
                  (dreyeck/fedwiki-page-materialization:materialize-fedwiki-page-fork
                   page-json
                   site-root
                   fork-slug
                   :source-site source-site
                   :fork-date fork-date))
                (fork-persisted
                  (dreyeck/fedwiki-assets:read-local-fedwiki-page
                   site-root
                   fork-slug))
                (fork-journal
                  (gethash "journal" fork-persisted))
                (fork-entry
                  (aref fork-journal
                        (1- (length fork-journal)))))

           ;; Neither persistence nor fork materialization mutates the source.
           (assert
            (eq source-journal
                (gethash "journal" page-json)))

           (assert
            (= 1
               (length
                (gethash "journal" page-json))))

           (assert
            (string=
             "create"
             (gethash "type" source-entry)))

           (assert
            (= 1000
               (gethash "date" source-entry)))

           ;; Plain materialization creates the canonical local page unchanged.
           (assert
            (probe-file plain-target))

           (assert
            (equal
             (truename plain-target)
             (truename
              (dreyeck/fedwiki-assets:local-fedwiki-page-pathname
               site-root
               plain-slug))))

           (assert
            (= 1
               (length plain-journal)))

           (assert
            (string=
             "create"
             (gethash
              "type"
              (aref plain-journal 0))))

           (assert
            (= 1000
               (gethash
                "date"
                (aref plain-journal 0))))

           (assert
            (string=
             "Materialization Example"
             (gethash "title" plain-persisted)))

           ;; Explicit fork materialization adds exactly one fork relation.
           (assert
            (probe-file fork-target))

           (assert
            (equal
             (truename fork-target)
             (truename
              (dreyeck/fedwiki-assets:local-fedwiki-page-pathname
               site-root
               fork-slug))))

           (assert
            (= 2
               (length fork-journal)))

           (assert
            (string=
             "create"
             (gethash
              "type"
              (aref fork-journal 0))))

           (assert
            (string=
             "fork"
             (gethash "type" fork-entry)))

           (assert
            (string=
             source-site
             (gethash "site" fork-entry)))

           (assert
            (= fork-date
               (gethash "date" fork-entry)))

           ;; Existing targets remain protected unless supersede is explicit.
           (let ((rejected-p nil))
             (handler-case
                 (dreyeck/fedwiki-page-materialization:materialize-fedwiki-page-json
                  page-json
                  site-root
                  plain-slug)
               (error ()
                 (setf rejected-p t)))
             (assert rejected-p))

           t)

      (when
          (uiop:directory-exists-p site-root)
        (uiop:delete-directory-tree
         site-root
         :validate t
         :if-does-not-exist :ignore)))))
