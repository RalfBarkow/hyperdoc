(in-package #:dreyeck/local-fedwiki-view/tests)

(defparameter *fixture-slug*
  "reading-java-source-as-data")

(defparameter *fixture-wiki-id*
  "fedwiki:dreyeck.ch")

(defparameter *fixture-view-path*
  (format nil "/view/~A" *fixture-slug*))

(defun fixture-site-root ()
  (asdf:system-relative-pathname
   "dreyeck/local-fedwiki-view/tests"
   "dreyeck/tests/fixtures/local-fedwiki-view-site/"))

(defun story-view-html (page)
  (let ((view
          (find
           "Story"
           (html-inspector-views:all-views page)
           :key #'html-inspector-views:view-title
           :test #'string=)))
    (unless view
      (error
       "No Story view found for ~S."
       page))
    (html-inspector-views:view-html
     view)))

(defun url-view-html (page)
  (let ((view
          (find
           "URL"
           (html-inspector-views:all-views page)
           :key #'html-inspector-views:view-title
           :test #'string=)))
    (unless view
      (error
       "No URL view found for ~S."
       page))
    (html-inspector-views:view-html
     view)))

(defun run-local-fedwiki-view-tests ()
  (assert
   (string=
    *fixture-slug*
    (dreyeck/local-fedwiki-view:view-slug-from-pathname
     *fixture-view-path*)))

  (assert
   (null
    (dreyeck/local-fedwiki-view:view-slug-from-pathname
     (format nil "/not-view/~A" *fixture-slug*))))

  ;; The authored HyperDoc page names the same executable contracts that
  ;; this smoke test exercises below.
  (let* ((demo-page
           (asdf:system-relative-pathname
            "dreyeck/local-fedwiki-view/tests"
            "dreyeck/pages/HyperDoc and a Page-attached FedWiki ASDF System.html"))
         (source
           (uiop:read-file-string
            (truename demo-page))))

    (dolist
        (needle
         '("hyperbook=\"fedwiki:dreyeck.ch\""
           "page=\"reading-java-source-as-data\""
           "hyperbook:find-page"
           "view=\"Story\""
           "local-fedwiki-page-asdf-discovery"
           "/view/reading-java-source-as-data"))
      (assert
       (search needle source :test #'char=)
       ()
       "HyperDoc demonstration page must declare ~S."
       needle)))

  (let ((hyperbook:*catalog*
          (make-instance
           'hyperbook:catalog)))

    (let* ((fetch-symbol
             (find-symbol
              "FETCH-PAGE-JSON"
              "HYPERBOOK/FEDWIKI"))
           (original-fetch
             (symbol-function
              fetch-symbol))
           (fetch-called-p nil))

      (unwind-protect
           (progn
             (setf
              (symbol-function fetch-symbol)
              (lambda (&rest arguments)
                (declare
                 (ignore arguments))
                (setf fetch-called-p t)
                (error
                 "Network FedWiki fetch attempted while resolving a local page.")))

             (let* ((wiki
                      (dreyeck/local-fedwiki-page:register-local-fedwiki
                       (fixture-site-root)
                       *fixture-wiki-id*))
                    (page-from-semantic-link-contract
                      (hyperbook:find-page
                       *fixture-wiki-id*
                       *fixture-slug*
                       :signal-error? t))
                    (page-from-view-route
                      (dreyeck/local-fedwiki-view:make-local-fedwiki-view-page
                       (fixture-site-root)
                       *fixture-slug*
                       :wiki-id *fixture-wiki-id*))
                    (discovery
                      (dreyeck/local-fedwiki-page:local-fedwiki-page-asdf-discovery
                       page-from-semantic-link-contract))
                    (html
                      (story-view-html
                       page-from-semantic-link-contract))
                    (url-html
                      (url-view-html
                       page-from-semantic-link-contract)))

               (assert
                (typep
                 wiki
                 'dreyeck/local-fedwiki-page:local-fedwiki))

               (assert
                (equal
                 (truename
                  (fixture-site-root))
                 (dreyeck/local-fedwiki-page:local-fedwiki-site-root-of
                  wiki)))

               (assert
                (typep
                 page-from-semantic-link-contract
                 'dreyeck/local-fedwiki-page:local-fedwiki-page))

               ;; Semantic HyperBook lookup and /view resolve to the same
               ;; cached local page object.
               (assert
                (eq
                 page-from-semantic-link-contract
                 page-from-view-route))

               (assert
                (eq
                 wiki
                 (hyperbook:hyperbook-of
                  page-from-semantic-link-contract)))

               (assert
                (string=
                 "Reading Java Source as Data"
                 (hyperbook:title-of
                  page-from-semantic-link-contract)))

               ;; Missing pages remain local misses. They do not fall through
               ;; to the network-oriented FEDWIKI implementation.
               (assert
                (null
                 (hyperbook:find-page
                  *fixture-wiki-id*
                  "does-not-exist")))

               (assert
                (not fetch-called-p))

               (assert
                (equal
                 '("pages/reading-java-source-as-data")
                 (getf discovery :assets-references)))

               ;; The fixture contains the page JSON and one page-attached ASD.
               ;; Discovery must resolve that relation without loading it.
               (let* ((asdf-files
                        (getf discovery :asdf-files))
                      (expected-asd
                        (asdf:system-relative-pathname
                         "dreyeck/local-fedwiki-view/tests"
                         "dreyeck/tests/fixtures/local-fedwiki-view-site/assets/pages/reading-java-source-as-data/reading-java-source-as-data.asd")))

                 (assert
                  (= 1
                     (length asdf-files)))

                 (assert
                  (equal
                   (truename expected-asd)
                   (truename
                    (first asdf-files)))))


               (assert
                (search
                 "Reading Java Source as Data"
                 html
                 :test #'char-equal))

               (assert
                (search
                 "This page treats Java source as inspectable"
                 html
                 :test #'char-equal))

               (assert
                (search
                 (format nil "pages/~A" *fixture-slug*)
                 html
                 :test #'char-equal))

               (assert
                (search
                 (string-left-trim
                  "/"
                  *fixture-view-path*)
                 url-html
                 :test #'char-equal))))

        (setf
         (symbol-function fetch-symbol)
         original-fetch))))

  t)
