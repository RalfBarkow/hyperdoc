(in-package #:dreyeck/fedwiki-publication)

(defun make-local-fedwiki-repository-checkout
    (wiki role)
  (let* ((site-root
           (dreyeck/local-fedwiki-page:local-fedwiki-site-root-of
            wiki))
         (root
           (ecase role
             (:pages
              (merge-pathnames
               #P"pages/"
               site-root))
             (:assets
              (dreyeck/fedwiki-assets:local-fedwiki-assets-root
               site-root))))
         (root-source
           (ecase role
             (:pages
              :explicit-fedwiki-pages-checkout)
             (:assets
              :explicit-fedwiki-assets-checkout))))
    (unless
        (probe-file root)
      (error
       "No usable FedWiki ~S repository root below ~S: ~S"
       role
       site-root
       root))
    (make-instance
     'dreyeck/git:git-repository-checkout
     :root root
     :root-source root-source)))
