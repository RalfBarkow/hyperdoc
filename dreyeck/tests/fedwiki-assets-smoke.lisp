(in-package #:dreyeck/fedwiki-assets/tests)

(defun fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/fedwiki-assets/tests"
   "dreyeck/tests/fixtures/fedwiki-assets-site/"))

(defun run-fedwiki-assets-tests ()
  (let* ((site-root
           (fixture-site-root))
         (page-json
           (dreyeck/fedwiki-assets:read-local-fedwiki-page
            site-root
            "example-page"))
         (items
           (dreyeck/fedwiki-assets:assets-story-items
            page-json))
         (item
           (first items))
         (reference
           (dreyeck/fedwiki-assets:assets-reference-of
            item))
         (directory
           (dreyeck/fedwiki-assets:resolve-local-assets
            site-root
            item))
         (asdf-files
           (dreyeck/fedwiki-assets:discover-asdf-files
            directory))
         (observation
           (dreyeck/fedwiki-assets:page-attached-asdf-discovery-observation
            site-root
            "example-page")))

    (assert
     (string=
      "Example Page"
      (gethash "title" page-json)))

    (assert (= 1 (length items)))

    (assert
     (string=
      "pages/example-page"
      reference))

    (assert
     (uiop:directory-exists-p directory))

    (assert (= 1 (length asdf-files)))

    (assert
     (string=
      "example-page.asd"
      (file-namestring
       (first asdf-files))))

    (assert
     (= 1
        (length
         (getf observation :asdf-files))))

    t))
