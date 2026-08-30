(in-package #:dreyeck/fedwiki-publication/tests)

(defun run-fedwiki-publication-smoke-tests ()
  (let* ((root
           (merge-pathnames
            (format
             nil
             "dreyeck-fedwiki-publication-~A/"
             (gensym "TEST-"))
            (uiop:temporary-directory)))
         (pages-root
           (merge-pathnames
            #P"pages/"
            root))
         (assets-root
           (merge-pathnames
            #P"assets/"
            root)))
    (unwind-protect
         (progn
           (ensure-directories-exist
            (merge-pathnames
             #P".keep"
             pages-root))
           (ensure-directories-exist
            (merge-pathnames
             #P".keep"
             assets-root))

           (uiop:run-program
            (list
             "git"
             "-C"
             (namestring pages-root)
             "init"
             "--quiet")
            :output :string
            :error-output :output)

           (uiop:run-program
            (list
             "git"
             "-C"
             (namestring assets-root)
             "init"
             "--quiet")
            :output :string
            :error-output :output)

           (let* ((wiki
                    (dreyeck/local-fedwiki-page:make-local-fedwiki
                     root
                     "fedwiki:test.invalid"))
                  (pages
                    (dreyeck/fedwiki-publication:make-local-fedwiki-repository-checkout
                     wiki
                     :pages))
                  (assets
                    (dreyeck/fedwiki-publication:make-local-fedwiki-repository-checkout
                     wiki
                     :assets)))

             (unless
                 (equal
                  (truename pages-root)
                  (truename
                   (dreyeck/git:git-repository-root-of
                    pages)))
               (error
                "FedWiki pages checkout root mismatch."))

             (unless
                 (eql
                  :explicit-fedwiki-pages-checkout
                  (dreyeck/git:git-repository-root-source-of
                   pages))
               (error
                "FedWiki pages checkout root source mismatch."))

             (unless
                 (equal
                  (truename assets-root)
                  (truename
                   (dreyeck/git:git-repository-root-of
                    assets)))
               (error
                "FedWiki assets checkout root mismatch."))

             (unless
                 (eql
                  :explicit-fedwiki-assets-checkout
                  (dreyeck/git:git-repository-root-source-of
                   assets))
               (error
                "FedWiki assets checkout root source mismatch."))

             (format
              t
              "FEDWIKI-PUBLICATION-SMOKE-PASSED~%")

             t))
      (when
          (probe-file root)
        (uiop:delete-directory-tree
         root
         :validate t)))))
