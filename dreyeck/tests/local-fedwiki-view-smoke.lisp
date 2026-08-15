(in-package #:dreyeck/local-fedwiki-view/tests)

(defparameter *fixture-slug*
  "reading-java-source-as-data")

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
               "Network FedWiki fetch attempted while rendering a local page.")))

           (let* ((page
                    (dreyeck/local-fedwiki-view:make-local-fedwiki-view-page
                     (fixture-site-root)
                     *fixture-slug*))
                  (html
                    (story-view-html page))
                  (url-html
                    (url-view-html page)))

             (assert
              (typep
               page
               'dreyeck/local-fedwiki-page:local-fedwiki-page))

             (assert
              (string=
               "Reading Java Source as Data"
               (hyperbook:title-of page)))

             (assert
              (not fetch-called-p))

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
               (string-left-trim "/" *fixture-view-path*)
               url-html
               :test #'char-equal))))

      (setf
       (symbol-function fetch-symbol)
       original-fetch)))

  t)
