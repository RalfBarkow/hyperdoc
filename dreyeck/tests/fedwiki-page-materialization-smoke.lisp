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
         (slug
           "materialization-example")
         (source-site
           "hyperdoc.dreyeck.ch")
         (fork-date
           1786787819051))

    (unwind-protect
         (let* ((target
                  (dreyeck/fedwiki-page-materialization:materialize-fedwiki-page-json
                   page-json
                   site-root
                   slug
                   :source-site source-site
                   :fork-date fork-date))
                (persisted
                  (dreyeck/fedwiki-assets:read-local-fedwiki-page
                   site-root
                   slug))
                (persisted-journal
                  (gethash "journal" persisted))
                (fork-entry
                  (aref persisted-journal
                        (1- (length persisted-journal)))))

           ;; The source JSON remains untouched.
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

           ;; The page exists at the canonical local page-store path.
           (assert
            (probe-file target))

           (assert
            (equal
             (truename target)
             (truename
              (dreyeck/fedwiki-assets:local-fedwiki-page-pathname
               site-root
               slug))))

           ;; Existing journal history is preserved and one fork is appended.
           (assert
            (= 2
               (length persisted-journal)))

           (assert
            (string=
             "create"
             (gethash
              "type"
              (aref persisted-journal 0))))

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

           ;; Overwriting requires an explicit policy.
           (let ((rejected-p nil))
  (handler-case
      (dreyeck/fedwiki-page-materialization:materialize-fedwiki-page-json
       page-json
       site-root
       slug
       :source-site source-site
       :fork-date fork-date)
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
