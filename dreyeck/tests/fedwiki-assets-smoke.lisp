(in-package #:dreyeck/fedwiki-assets/tests)

(defun fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/fedwiki-assets/tests"
   "dreyeck/tests/fixtures/fedwiki-assets-site/"))

(defparameter *valid-slugs*
  '("example-page" "a" "0" "x-1" "a-critic-for-lisp" "work-breakdown")
  "Slugs that resolve, each where it always did.")

(defparameter *invalid-slugs*
  (list "" "." ".." "../x" "../status/owner.json" "x/y" "x\\y" "/x" "x/" "x/.."
        "Example-Page" "x.json" "x y" "x%2Fy" "*" "x;y"
        (format nil "x~Cy" #\Newline) (string (code-char 228)) nil :example-page 42)
  "Each is refused as it stands; none is normalized into a slug.")

(defun refused-p (thunk)
  "Whether THUNK is refused as an invalid page slug. Any other error, such as
one from opening a file, is not a refusal and propagates."
  (handler-case (progn (funcall thunk) nil)
    (dreyeck/fedwiki-assets:invalid-fedwiki-page-slug () t)))

(defun make-scratch-site-root ()
  "A temporary site root with an empty pages/ directory and, beside it, a
readable JSON file a path escape would reach. Synthetic; it holds nothing."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "dreyeck-fedwiki-slug-~A/" (symbol-name (gensym "RUN-")))
                                (uiop:temporary-directory)))))
    (ensure-directories-exist (merge-pathnames "pages/" root))
    (let ((outside (merge-pathnames "status/outside.json" root)))
      (ensure-directories-exist outside)
      (with-open-file (out outside :direction :output :if-exists :error :external-format :utf-8)
        (write-string "{\"title\":\"Outside pages/\",\"story\":[],\"journal\":[]}" out)))
    root))

(defun check-page-slug-boundary ()
  "A page slug denotes exactly one direct child of the site's pages/ directory.
Anything else is refused by every constructor and reader, before any file is
opened."
  (let ((root (make-scratch-site-root)))
    (unwind-protect
         (let ((pages (merge-pathnames "pages/" root)))
           ;; Valid slugs resolve where they always did.
           (dolist (slug *valid-slugs*)
             (assert (dreyeck/fedwiki-assets:fedwiki-page-slug-p slug))
             (let ((pathname (dreyeck/fedwiki-assets:local-fedwiki-page-pathname root slug)))
               (assert (string= (namestring (merge-pathnames (format nil "pages/~A" slug) root))
                                (namestring pathname)))
               (assert (equal (pathname-directory pages) (pathname-directory pathname)))
               (assert (equal slug (file-namestring pathname))))
             (assert (equal (append (pathname-directory (dreyeck/fedwiki-assets:local-fedwiki-assets-root root))
                                    (list "pages" slug))
                            (pathname-directory (dreyeck/fedwiki-assets:page-assets-directory root slug)))))
           ;; Invalid slugs are refused by the constructors and the reader.
           (dolist (slug *invalid-slugs*)
             (assert (not (dreyeck/fedwiki-assets:fedwiki-page-slug-p slug)))
             (dolist (operation (list #'dreyeck/fedwiki-assets:local-fedwiki-page-pathname
                                      #'dreyeck/fedwiki-assets:page-assets-directory
                                      #'dreyeck/fedwiki-assets:read-local-fedwiki-page))
               (assert (refused-p (lambda () (funcall operation root slug))) ()
                       "~S accepted the slug ~S." operation slug)))
           ;; Refused before any file is opened: the escape target exists and
           ;; reads as JSON, so opening it would have returned a page.
           (assert (hash-table-p (with-open-file (in (merge-pathnames "status/outside.json" root)
                                                     :external-format :utf-8)
                                   (shasht:read-json in))))
           (assert (refused-p (lambda ()
                                (dreyeck/fedwiki-assets:read-local-fedwiki-page
                                 root "../status/outside.json"))))
           ;; A page under a valid slug still reads.
           (with-open-file (out (merge-pathnames "pages/scratch-page" root) :direction :output
                                                                          :external-format :utf-8)
             (write-string "{\"title\":\"Scratch Page\",\"story\":[],\"journal\":[]}" out))
           (assert (equal "Scratch Page"
                          (gethash "title" (dreyeck/fedwiki-assets:read-local-fedwiki-page
                                            root "scratch-page")))))
      (uiop:delete-directory-tree root :validate t))))

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


    (check-page-slug-boundary)

    t))
